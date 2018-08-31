#!/bin/bash
# Carolyn Voter
# HTCrunParflow.sh
# Interprets arguments, defines environment variables for parflow model run

# Usage: HTCrunParflow.sh <runname> <totalHr> <drun> <nruns> <np>

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname - name of modeling run
# 2 = totalHr
# 3 = drun
# 4 = nruns - total number of modeling loops
# ==============================================================================
export runname=$1
export totalHr=$2
export drun=$3
export nruns=$4

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# ==============================================================================
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export TCL_PATH=$BASE/tcl-8.6.8
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export HOME=$(pwd)
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export SCRIPTS=$HOME/scripts
mkdir $SCRIPTS

# ==============================================================================
# CALL EXECUTABLE SCRIPT
# ==============================================================================
mv saveCurrentOutputs.sh logComments.sh $SCRIPTS/
sh runParflow.sh
