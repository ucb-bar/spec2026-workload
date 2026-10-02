#!/bin/bash

set -ex

if [ "$1" != "ref" ] && [ "$1" != "test" ] && [ "$1" != "train" ]; then
    echo "Must specify ref/test/train"
    exit 1
fi

settings_file="$(dirname "$0")/marshal-configs/spec26-settings.sh"
. "$settings_file"

threads="${SPEC26_INTSPEED_THREADS:?SPEC26_INTSPEED_THREADS must be set}"

echo "Building SPEC2026 Intspeed with $1 inputs and $threads generated-command thread(s)"
make spec26-intspeed INPUT=$1 THREADS="$threads"
