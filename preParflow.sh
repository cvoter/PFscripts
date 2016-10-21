#!/bin/bash
# 2016.01 Carolyn Voter
# preParflow.sh
# Executable to setup environment variables and call preParflow.tcl

export runname=$1

# -------------------------------------------
# SET ENVIRONMENT VARIABLES
# -------------------------------------------
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export HOME=$(pwd)
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export SILO_PATH=$BASE/silo-4.9.1-bsd
export HYPRE_PATH=$BASE/hypre-2.9.0b
export TCL_PATH=$BASE/tcl-8.6.5
export HDF5_PATH=$BASE/hdf5-1.8.17
export LD_LIBRARY_PATH=$HDF5_PATH/lib:$LD_LIBRARY_PATH
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

cp $HOME/preParflow.tcl $GHOME/preParflow.tcl
cd $GHOME

# -------------------------------------------
# DO PARFLOW STUFF
# -------------------------------------------
tclsh preParflow.tcl
rm -f preParflow1D.tcl

MATdir=/mnt/gluster/cvoter/MatlabOut/$runname
if [ ! -e $MATdir ]; then
  mkdir $MATdir
fi
cp $GHOME/domainInfo.mat $MATdir/
cp $GHOME/precip.mat $MATdir/