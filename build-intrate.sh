#!/bin/bash

set -ex

if [ "$1" != "ref" ] && [ "$1" != "test" ] && [ "$1" != "train" ]; then
    echo "Must specify ref/test/train"
    exit 1
fi

settings_file="$(dirname "$0")/marshal-configs/spec26-settings.sh"
. "$settings_file"

threads="${SPEC26_INTRATE_COPIES:?SPEC26_INTRATE_COPIES must be set}"

echo "Building SPEC2026 Intrate with $1 inputs and $threads generated-command thread(s)"
make spec26-intrate INPUT=$1 THREADS="$threads"
