SPEC2026 Workload
=================

Requirements
------------

- SPEC2026 installed and have `SPEC_DIR` env. variable point to installation

Getting Started
---------------

When you first install this repository, you should update all submodules:

    git submodule update --init --recursive spec2026

After that you can use FireMarshal as normal and point to the `json` workload configs:

    # Assuming marshal is on your $PATH
    marshal build ./marshal-configs/spec26-intrate.json

Runtime Parallelism
-------------------

Set `SPEC26_INTRATE_COPIES` (SPECrate) and `SPEC26_INTSPEED_THREADS`
(SPECspeed) in `marshal-configs/spec26-settings.sh`. FireMarshal's normal
`marshal clean`, `marshal build`, and `marshal install` commands read this
file: it controls both the guest benchmark jobs and Speckle's generated command
scripts. For example, set both values to `1` for a single-hart image, then run:

    marshal clean ./marshal-configs/spec26-intrate.json
    marshal build ./marshal-configs/spec26-intrate.json

The SPEC compiler makefiles use all host CPUs by default (`-j$(nproc)`). Set
`SPEC_BUILD_NCPUS` before `marshal build` to limit host-side compiler
parallelism on a shared machine.


See https://firemarshal.readthedocs.io/en/latest/index.html for FireMarshal
documentation.
