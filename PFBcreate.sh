#!/bin/bash
# 2017.09 Carolyn Voter
# PFBcreate.sh
# Creates subsurface_storage.pfb and surface_storage.pfb from other *.pfb output

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname
# 2 = totalHr = total number of model hours for complete simulation
# 3 = flux = which flux is being created (subsurface_storage or surface_storage)
# ==============================================================================

export runname=$1
export totalHr=$2
export flux=$3

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# Paths for libraries, compilers, relavant directories
# On HTCondor setup, parflow + dependent libraries installed in "BASE" directory
# Model output first generated on local machine ("HOME")
# Model output then transferred to gluster fileserver ("GHOME")
# ==============================================================================
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export HOME=$(pwd)
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export HYPRE_PATH=$BASE/hypre-2.9.0b
export TCL_PATH=$BASE/tcl-8.6.5
export HDF5_PATH=$BASE/hdf5-1.8.17
export LD_LIBRARY_PATH=$HDF5_PATH/lib:$LD_LIBRARY_PATH
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

# ==============================================================================
# CLEAN UP AFTER PREVIOUS STEPS
# If make it this far, then regroupParflow.sh must have executed successfully
# Outputs now reside in submit-5 server home directory, so remove from gluster
# Use this job to transfer PFrestart.tar.gz to home directory as well
# ==============================================================================
#OUTPUTS IN GLUSTER, ORGANIZED BY LOOP
for tarball in "$GHOME/PFout.*.tar.gz"; do
  rm $tarball
done

#RESTART INFO (includes *.pfb files with domain info that is not time-dependent)
cp $GHOME/PFrestart.tar.gz $HOME

# ==============================================================================
# MANAGE INPUTS
# Remove satur.tar.gz if working on surface_storage (unneeded)
# Get other required *.pfb files from Gluster (all in PFin.tar.gz)
# Move tarballs into flux directory, untar all there 
# ==============================================================================
#DELETE satur.tar.gz IF UNEEDED
if [ "$flux" = "surface_storage" ]; then
  rm -f satur.tar.gz
fi

#CREATE RUN DIRECTORY
mkdir $flux

#COPY TARBALLS TO RUN DIRECTORY AND EXTRACT
mv *.tar.gz $flux/
cd $HOME/$flux
for tarball in *.tar.gz; do
  tar xzf $tarball --strip-components=1
  if [ "$tarball" != "PFrestart.tar.gz" ]; then
   rm $tarball
  fi
done

#MOVE PFrestart UP A LEVEL (so it's transferred to submit-5 home at end of job)
mv PFrestart.tar.gz $HOME/

# ==============================================================================
# DO PARFLOW STUFF
# Run the *.tcl script to create $flux.pfb
# ==============================================================================
#NOTE STARTING TIME
startT="$(date +%s)"

#RUN *.TCL SCRIPT
tclsh $HOME/$flux.tcl

#CALCUALTE TIME TO CONVERT, PRINT TO OUTPUT
dT="$(($(date +%s)-startT))"
printf "\n\n\nFILE CONVERSION TIME:\n"
printf "\tPFB conversions done in: %dhr %dmin %ds\n\n\n" "$((dT/3600%24))" "$((dT/60%60))" "$((dT%60))"

# ==============================================================================
# CLEAN UP
# Delete input files, tar up new $flux files
# ==============================================================================
#DELETE INPUT *.PFB FLUXES
for deleteFlux in press satur; do
  deletenames=$runname.out.$deleteFlux*
  find . -name "${deletenames}" -delete
done

#DELETE OTHER EXTRA DATA (most to all from PFrestart.tar.gz)
rm -f $runname.out.mannings.pfb $runname.out.mask.pfb $runname.out.perm_x.pfb \
     $runname.out.perm_y.pfb $runname.out.perm_z.pfb $runname.out.porosity.pfb \
     $runname.out.slope_x.pfb $runname.out.slope_y.pfb \
     $runname.out.specific_storage.pfb drv_clmin_start.dat \
     drv_clmin_restart.dat drv_vegm.dat drv_vegp.dat nldas.1hr.clm.txt \
     slopex.pfb slopey.pfb subsurfaceFeature.pfb runParflow.tcl \
     $runname.info.txt gp.rst.*

#TAR REMAINING FILES (should be just the new flux left)
cd $HOME
tar zcf $flux.tar.gz $flux
rm -rf $flux