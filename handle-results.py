#!/usr/bin/env python3
import pathlib
import sys
import pandas as pd
import argparse

# All time measurements are in seconds

# SPEC CPU 2026 reference-machine times, taken from the SPEC installation:
# benchspec/CPU/*/data/ref{rate,speed}/reftime (speed-only benchmarks share
# their rate twin's data directory via Spec/origin).
specRateReference = pd.DataFrame.from_dict({
    "706.stockfish_r" : 1260,
    "707.ntest_r" : 592,
    "708.sqlite_r" : 528,
    "710.omnetpp_r" : 486,
    "714.cpython_r" : 479,
    "721.gcc_r" : 686,
    "723.llvm_r" : 507,
    "727.cppcheck_r" : 359,
    "729.abc_r" : 459,
    "734.vpr_r" : 461,
    "735.gem5_r" : 487,
    "750.sealcrypto_r" : 536,
    "753.ns3_r" : 613,
    "777.zstd_r" : 644
    }, orient='index', columns=['RealTime'])

# https://www.spec.org/cpu2026/results/res2026q2/cpu2026-20260210-00004.txt
specSpeedReference = pd.DataFrame.from_dict({
    "801.xz_s" : 591,
    "807.ntest_s" : 1140,
    "817.flac_s" : 1737,
    "821.gcc_s" : 2070,
    "823.llvm_s" : 1411,
    "827.cppcheck_s" : 1119,
    "829.abc_s" : 831,
    "834.vpr_s" : 954,
    "835.gem5_s" : 1139,
    "838.diamond_s" : 1001,
    "846.minizinc_s" : 670,
    "853.ns3_s" : 1153,
    "854.graph500_s" : 611
    }, orient='index', columns=['RealTime'])

# From benchspec/CPU/*/data/test/reftime. Test-size scores are only a sanity
# check; test times are tiny and not meaningful for performance comparison.
specSpeedTest = pd.DataFrame.from_dict({
    "801.xz_s" : 13,
    "807.ntest_s" : 2,
    "817.flac_s" : 4,
    "821.gcc_s" : 2,
    "823.llvm_s" : 2,
    "827.cppcheck_s" : 49,
    "829.abc_s" : 3,
    "834.vpr_s" : 56,
    "835.gem5_s" : 5,
    "838.diamond_s" : 2,
    "846.minizinc_s" : 2,
    "853.ns3_s" : 10,
    "854.graph500_s" : 2
    }, orient='index', columns=['RealTime'])

def handleSpeed(outDir, dataset):
    if dataset == 'test':
        baseline = specSpeedTest
    elif dataset == 'ref':
        baseline = specSpeedReference
    else:
        baselinePath = pathlib.Path(dataset)
        if not baselinePath.exists():
            raise RuntimeError("Baseline csv doesn't exist: ", dataset)
        baseline = pd.read_csv(baselinePath, index_col=0)

    frames = [pd.read_csv(f, index_col=0) for f in outDir.glob("*/output/*.csv")]
    if not frames:
        raise RuntimeError("No result csvs found under: " + str(outDir))
    resDF = pd.concat(frames)

    resDF['score'] = baseline['RealTime'] / resDF['RealTime']
    resDF.sort_index(inplace=True)
    return resDF


def handleRate(outDir):
    frames = [pd.read_csv(f) for f in outDir.glob("*/output/*.csv")]
    if not frames:
        raise RuntimeError("No result csvs found under: " + str(outDir))
    resDF = pd.concat(frames)

    nameGroups = resDF.groupby(['name'])

    resDF = resDF[nameGroups['RealTime'].transform(max) == resDF['RealTime']].copy()
    resDF.drop('copy', axis=1, inplace=True)
    resDF.set_index('name', inplace=True)
    resDF = pd.concat([resDF, nameGroups['copy'].count().rename("ncopy")], axis=1)

    resDF['score'] = (specRateReference['RealTime'] / resDF['RealTime']) * resDF['ncopy']

    return resDF


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Aggregate results from a run of a SPEC suite")
    parser.add_argument('-s', '--suite', required=True, choices=['intspeed', 'intrate'], help="Which suite was run.")
    parser.add_argument('-d', '--dataset', required=True, help="Which dataset was used, either test or ref. You can also specify a path to a previous output of this script to use as a baseline.")
    parser.add_argument('outputPath', type=pathlib.Path, help="Output directory to process")

    args = parser.parse_args()

    if args.suite == "intspeed":
        resDF = handleSpeed(args.outputPath, dataset=args.dataset)
    elif args.suite == "intrate":
        resDF = handleRate(args.outputPath)

    with open(args.outputPath / "results.csv", "w") as f:
        f.write(resDF.to_csv())

    plot = resDF['score'].plot(kind="bar", title="SPEC Score")
    plot.get_figure().savefig(args.outputPath / "results.pdf", bbox_inches = "tight")
    print("Output available in: ", args.outputPath)
