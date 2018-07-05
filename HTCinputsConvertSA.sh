#!/bin/bash
# Carolyn Voter
# HTCinputsConvertSA.sh
# Interprets arguments, defines environment variables for parflow setup

# Usage: HTCinputsConvertSA.sh <runname> <nruns>

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname - name of modeling run
# 2 = nruns - total number of modeling loops
# ==============================================================================
export runname=$1
export nruns=$2

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# ==============================================================================
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export TCL_PATH=$BASE/tcl-8.6.8
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export PATH=$MPI_PATH/bin:$PATH
export HOME=$(pwd)
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export SCRIPTS=$HOME

# ==============================================================================
# CALL EXECUTABLE SCRIPT
# ==============================================================================
sh inputsConvertSA.sh