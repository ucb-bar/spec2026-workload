#!/bin/bash

set -ex

if [ "$1" != "ref" ] && [ "$1" != "test" ] && [ "$1" != "train" ]; then
    echo "Must specify ref/test/train"
    exit 1
fi

echo "Building SPEC2026 Intrate with $1 inputs"
make spec26-intrate INPUT=$1
