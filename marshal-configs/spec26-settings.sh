#!/bin/sh
#
# SPEC CPU2026 parallelism used by the FireMarshal workloads. Keep these
# values at or below the number of harts in the target simulation.
#
# SPECrate launches this many independent benchmark copies. SPECspeed uses
# this many OpenMP threads and generates command scripts for the same count.
SPEC26_INTRATE_COPIES=1
SPEC26_INTSPEED_THREADS=1
