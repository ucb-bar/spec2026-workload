#!/usr/bin/env bash
# Clean and rebuild the per-benchmark integer test/train FireMarshal workloads.
set -euo pipefail

if [[ $# -gt 1 || ! ${1:-16} =~ ^[1-9][0-9]*$ ]]; then
    echo "Usage: bash $0 [parallel-build-jobs, default: 16]" >&2
    exit 2
fi
build_jobs=${1:-16}
workload_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$workload_dir/../.." && pwd)
marshal_dir="$repo_dir/software/firemarshal"
config_dir="$workload_dir/marshal-configs"

export SPEC_DIR=${SPEC_DIR:-/scratch/spec26-out}
export RISCV=${RISCV:-$repo_dir/.conda-env/riscv-tools}
export PATH="$RISCV/bin:$repo_dir/.conda-env/bin:$PATH"
export SPEC_BUILD_NCPUS="$build_jobs"
export MARSHAL_JLEVEL="$build_jobs"
export THREADS=1
export OMP_NUM_THREADS=1

if [[ ! -x "$SPEC_DIR/bin/runcpu" || ! -f "$SPEC_DIR/shrc" ]]; then
    echo "Set SPEC_DIR to the installed SPEC CPU2026 directory." >&2
    exit 1
fi
if [[ ! -x "$RISCV/bin/riscv64-unknown-linux-gnu-gcc" ]]; then
    echo "Set RISCV to the RISC-V Linux toolchain directory." >&2
    exit 1
fi
for submodule in wlutil/busybox boards/default/linux boards/default/firmware/opensbi \
                 boards/default/distros/br/buildroot boards/firechip/drivers/icenet-driver \
                 boards/firechip/drivers/iceblk-driver; do
    if [[ ! -e "$marshal_dir/$submodule/.git" ]]; then
        echo "Initialize FireMarshal submodules first: (cd '$marshal_dir' && ./init-submodules.sh)" >&2
        exit 1
    fi
done

python3 - "$workload_dir" "$marshal_dir" <<'PY'
import json
from pathlib import Path
import shutil
import subprocess
import sys

workload = Path(sys.argv[1])
marshal = Path(sys.argv[2]) / "marshal"
configs = workload / "marshal-configs"
benchmarks = {
    "intrate": "706.stockfish_r 707.ntest_r 708.sqlite_r 710.omnetpp_r "
               "714.cpython_r 721.gcc_r 723.llvm_r 727.cppcheck_r 729.abc_r "
               "734.vpr_r 735.gem5_r 750.sealcrypto_r 753.ns3_r 777.zstd_r",
    "intspeed": "801.xz_s 807.ntest_s 817.flac_s 821.gcc_s 823.llvm_s "
                "827.cppcheck_s 829.abc_s 834.vpr_s 835.gem5_s 838.diamond_s "
                "846.minizinc_s 853.ns3_s 854.graph500_s",
}

# Validate all inputs before removing existing configs or build artifacts.
targets = {}
for dataset, size in (("test", "8GiB"), ("train", "16GiB")):
    for suite, benchmark_list in benchmarks.items():
        for benchmark in benchmark_list.split():
            command_file = workload / "speckle/commands" / suite / f"{benchmark}.{dataset}.cmd"
            if not command_file.is_file():
                raise SystemExit(f"Missing benchmark commands: {command_file}")
            short_name = benchmark.rsplit("_", 1)[0]
            name = f"spec-{suite}-{dataset}-{short_name}"
            option = "copies" if suite == "intrate" else "threads"
            targets[name] = {
                "name": name,
                "base": "br-base.json",
                "workdir": "..",
                "host-init": f"build-int-single-thread.sh {suite} {dataset}",
                "overlay": f"speckle/build/overlay/{suite}/{dataset}",
                "rootfs-size": size,
                "outputs": ["/output"],
                "jobs": [{
                    "name": benchmark,
                    "command": f"./{suite}.sh {benchmark} --{option} 1",
                    "rootfs-size": size,
                }],
            }
assert len(targets) == 54

old_configs = sorted({
    path
    for prefix in ("spec26-intrate", "spec26-intspeed", "spec-intrate", "spec-intspeed")
    for path in configs.glob(f"{prefix}*.json")
})
if old_configs:
    # FireMarshal clean removes each workload's parent and job images/binaries.
    subprocess.run([str(marshal), "clean", *map(str, old_configs)], cwd=configs, check=True)
    for path in old_configs:
        path.unlink()

# Recreate overlays and embedded commands for the requested single-thread runs.
build_dir = workload / "speckle/build"
if build_dir.exists():
    shutil.rmtree(build_dir)
configs.mkdir(exist_ok=True)
for name, config in targets.items():
    (configs / f"{name}.json").write_text(json.dumps(config, indent=2) + "\n")
print(f"Generated {len(targets)} workloads: test=8GiB, train=16GiB, one thread/copy each.", flush=True)
PY

# Compile with parallel make jobs. Serialize workload packaging because these
# workloads share FireMarshal's base images, build database, and mount directory.
cd -- "$config_dir"
for dataset in test train; do
    for suite in intrate intspeed; do
        for config in spec-"$suite"-"$dataset"-*.json; do
            "$marshal_dir/marshal" -v build "$config"
        done
    done
done
