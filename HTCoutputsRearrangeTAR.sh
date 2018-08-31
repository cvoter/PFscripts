#!/bin/bash
# Carolyn Voter
# HTCoutputsRearrangeTAR.sh
# Interprets arguments, defines environment variables for parflow setup

# Usage: HTCoutputsRearrangeTAR.sh <runname> <totalHr> <drun> <nruns> <np>

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname - name of modeling run
# 2 = totalHr
# 3 = drun
# 4 = nruns - total number of modeling loops
# 5 = np - number of processors used to run parflow model
# ==============================================================================
export runname=$1
export totalHr=$2
export drun=$3
export nruns=$4
export np=$5

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# ==============================================================================
export HOME=$(pwd)
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

# ==============================================================================
# CALL EXECUTABLE SCRIPT
# ==============================================================================
sh outputsRearrangeTAR.sh