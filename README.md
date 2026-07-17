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


See https://firemarshal.readthedocs.io/en/latest/index.html for FireMarshal
documentation.
