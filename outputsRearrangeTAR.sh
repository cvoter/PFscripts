#!/bin/bash
# Carolyn Voter
# outputsRearrangeTar.sh
# Takes periodically saved output from parflow model and rearranges it by flux

# Usage: sh outputsRearrangeTar.sh
# Requires the following environment variables to be defined in parent script:
# HOME - path of working directory on local machine
# GHOME - path to where inputs and outputs are stored
# SCRIPTS - path to where PFscripts are stored
# runname - name of modeling run
# totalHr - total number of modeling hours to simulate
# drun - number of model hours per loop, before saving (typically 12hrs)
# nruns - number of loops to run in order to complete simulation.
# np - number of processors the job used to run

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
# ------------------------------------------------------------------------------
# CREATE TARBALL OF SPECIFIED FLUX(ES)
# ------------------------------------------------------------------------------
tarFlux () { 
    for flux in $@; do
      cd $HOME/$runname
      #CHECK NUMBER OF FILES
      if [ "$flux" = "clm_restart" ]; then
        thisfiletype=gp.rst.*
      elif [ "$flux" = "kinsol" ]; then
        thisfiletype=*.kinsol.log
      else
        thisfiletype=$runname.out.$flux.*.pfb
      fi
      nfiles=$(find . -name "${thisfiletype}" | wc -l)
      if [ $nfiles -ne $nExpected ]; then
        printf "Unexpected number of files for %s. Have %d, but expected %d" $flux $nfiles $nExpected
        exit 1
      fi
    
      #MOVE FLUX OUTPUT TO NEW DIRECTORY
      mkdir $HOME/$flux
      mv $thisfiletype $HOME/$flux/
    
      #TAR AND REMOVE DIRECTORY
      cd $HOME
      tar zcf $flux.tar.gz $flux
      rm -rf $flux 
    
      #RESET VARIABLES
      thisfiletype=''
      nfiles=''
    done
}

# ==============================================================================
# COPY ORIGINAL TARBALLS TO LOCAL MACHINE AND EXTRACT
# ==============================================================================
mkdir $HOME/$runname
cp -r $GHOME/. $HOME/$runname
cd $HOME/$runname
for tarball in *.tar.gz; do
  tar xzf $tarball --strip-components=1
  rm $tarball
done

# ==============================================================================
# TAR BY FLUX
# ==============================================================================
# ------------------------------------------------------------------------------
# FLUXES WITHOUT A "ZERO" HOUR FILE
# canopy water (can_out)
# evaptranssum (evaptranssum)
# ground evaporation (qflx_evap_grnd)
# vegetation evaporation (qflx_evap_veg)
# snow water equivalent (swe_out)
# overland flow (overlandsum)
# transpiration (qflx_tran_veg)
# ------------------------------------------------------------------------------
nExpected=$totalHr
tarFlux can_out evaptranssum qflx_evap_grnd qflx_evap_veg swe_out overlandsum \
        qflx_tran_veg

# ------------------------------------------------------------------------------
# FLUXES WITH A "ZERO" HOUR FILE
# pressure (press)
# saturation (satur)
# ------------------------------------------------------------------------------
nExpected=$((totalHr+1))
tarFlux press satur

# ------------------------------------------------------------------------------
# FLUXES SPORATICALLY SAVED
# clm restart files gp.rst (clm_restart)
# ------------------------------------------------------------------------------
nExpected=$((nruns*np))
tarFlux clm_restart

# ------------------------------------------------------------------------------
# LOG FILES
# kinsol log files (kinsol)
# ------------------------------------------------------------------------------
nExpected=$nruns
tarFlux kinsol

# ==============================================================================
# MOVE NEW TARBALLS TO GLUSTER, DELETE OLD TARBALLS
# ==============================================================================
cd $HOME
for tarball in *.tar.gz; do
  mv $tarball $GHOME/
done

for tarball in "$GHOME/PFout.*.tar.gz"; do
  rm $tarball
done
