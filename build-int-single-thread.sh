#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || ! $1 =~ ^(intrate|intspeed)$ || ! $2 =~ ^(test|train)$ ]]; then
    echo "Usage: $0 {intrate|intspeed} {test|train}" >&2
    exit 2
fi

suite=$1
dataset=$2
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

overlay="speckle/build/overlay/$suite/$dataset"
stamp="speckle/build/$suite-$dataset-threads-1.stamp"
if [[ ! -d $overlay || ! -f $stamp ]]; then
    # Commands contain thread counts as well as OMP_NUM_THREADS. Generate them
    # before compilation copies them into the overlay.
    rm -rf -- "$overlay"
    (
        cd speckle
        ./gen_binaries.sh --genCommands --suite "$suite" --input "$dataset" --threads 1
    )
    make "spec26-$suite" INPUT="$dataset" THREADS=1
    touch -- "$stamp"
fi
