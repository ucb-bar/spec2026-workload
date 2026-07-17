#!/usr/bin/env python3
import pandas as pd
import argparse
import pathlib
import matplotlib
from matplotlib import pyplot as plt

# Color style similar to ppt color scheme
plt.style.use('seaborn-colorblind')

#Latex Default Font
plt.rc('font', family='serif') 
plt.rc('font', serif='Latin Modern Roman')
matplotlib.rcParams.update({'font.size': 18})

speedBenches= [
    "801.xz_s",
    "807.ntest_s",
    "817.flac_s",
    "821.gcc_s",
    "823.llvm_s",
    "827.cppcheck_s",
    "829.abc_s",
    "834.vpr_s",
    "835.gem5_s",
    "838.diamond_s",
    "846.minizinc_s",
    "853.ns3_s",
    "854.graph500_s"
]

speedCleanName = {
        "801.xz_s" : "xz",
        "807.ntest_s" : "ntest",
        "817.flac_s" : "flac",
        "821.gcc_s" : "gcc",
        "823.llvm_s" : "llvm",
        "827.cppcheck_s" : "cppcheck",
        "829.abc_s" : "abc",
        "834.vpr_s" : "vpr",
        "835.gem5_s" : "gem5",
        "838.diamond_s" : "diamond",
        "846.minizinc_s" : "minizinc",
        "853.ns3_s" : "ns3",
        "854.graph500_s" : "graph500"
}

def loadFiles(files):
    frames = []
    for name, path in files.items():
        newDF = pd.read_csv(path, index_col=0)
        newDF.index.rename("Benchmark", inplace=True)
        newDF = newDF.assign(Experiment=name).set_index('Experiment',append=True).swaplevel(0,1)
        frames.append(newDF)

    fullDF = pd.concat(frames)
    fullDF.rename(index=speedCleanName, inplace=True)
    return fullDF

def make_hatches(ax, df):
    hatches = [h*len(df.index) for h in [['//'], ['--'], ['x'], ['\\'], ['||'], ['+'], ['o'], ['.']]]
    hatches = sum(hatches, [])

    if len(hatches) < len(ax.patches):
        print("Not enough hatches defined")
        
    for i,bar in enumerate(ax.patches):
        bar.set_hatch(hatches[i])
    ax.legend()

def plotRes(res):
    scores = resDF.loc[pd.IndexSlice[:,:], "score"].unstack(level=0)

    plot = scores.plot(kind="bar")
    make_hatches(plot, scores)
    plot.set_ylabel("SPEC Score")
    plot.set_xticklabels(scores.index, rotation=45, ha='right')

    plot.get_figure().savefig("result.pdf", bbox_inches = "tight", format="pdf")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compare results from multiple runs of the spec workload")
    parser.add_argument('-s', '--suite', required=True, choices=['intspeed', 'intrate'], help="Which suite was run.")
    parser.add_argument('-d', '--dataset', required=True, help="Which dataset was used, either test or ref. You can also specify a path to a previous output of this script to use as a baseline.")
    parser.add_argument("-n", "--names", nargs='?', default=None, type=lambda s: [item for item in s.split(',')], help="list of names to display of results. If omitted, the parent directory name will be used.")
    parser.add_argument('resultPaths', nargs="+", type=pathlib.Path, help="Paths to results csvs to compare (csvs should be in the format produced by handle-results.py")

    args = parser.parse_args()

    if args.names is None:
        args.names = [ p.parent.name for p in args.resultPaths ]

    datasets = { name : path for (name, path) in zip(args.names, args.resultPaths) }

    resDF = loadFiles(datasets)
    plotRes(resDF)
