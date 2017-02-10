#!/bin/bash
# 2015.06 Carolyn Voter

printf "THESE FILES ARE FROM: %s\n" "$1"
startT="$(date +%s)"

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
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH

# -------------------------------------------
# DO PARFLOW STUFF
# -------------------------------------------
parflowT="$(date +%s)"

export runname=$1
export t0=$2
export tf=$3
export flux=$4
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
tclsh $HOME/$flux.HPC.tcl

wbT="$(($(date +%s)-parflowT))"
printf "\n\n\nFILE CONVERSION TIME:\n"
printf "\tPFB conversions done in: %dhr %dmin %ds\n\n\n" "$((wbT/3600%24))" "$((wbT/60%60))" "$((wbT%60))"

# -------------------------------------------
# MOVE PFB DIRECTORIES TO GLUSTER
# -------------------------------------------
dirname=`find -type d -name '*pfb*'`
if [[ $dirname ]]; then
  tar zcf $dirname.$t0.tar.gz $dirname
  cp $dirname.$t0.tar.gz $GHOME
  cd $GHOME
  tar xzf $dirname.$t0.tar.gz --strip-components 2
  rm -f $dirname.$t0.tar.gz
  cd $HOME
  rm -rf $dirname
  rm -f $dirname.$t0.tar.gz
fi