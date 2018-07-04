#!/bin/bash
# Carolyn Voter
# saveCurrentOutputs.sh
# Standard comments to send to master log file, depending on current step of job

# Usage: sh saveCurrentOutputs.sh
# Requires the following environment variables to be defined in parent script:
# HOME - path of working directory on local machine
# GHOME - path to where inputs and outputs are stored
# runname - name of modeling run
# ICpressure - pressure file for next restart
# prettyStart - formatted starting hour for the next restart
# start
# pfStartCount
# prettyGlusterSave

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
#Tar and move to GHOME
tarAndMove () {
    for tarDir in $@; do
        tar zcf $tarDir.tar.gz $tarDir
        mv -f $tarDir.tar.gz $GHOME/
        rm -rf $tarDir 
    done
}

# ==============================================================================
# SAVE PFrestart FILES
# ==============================================================================
cd $HOME/$runname
mkdir $HOME/PFrestart

#Current log
cp -f $runname.info.txt $GHOME/
mv $runname.info.txt $HOME/PFrestart/

#Restart files (pressure and CLM)
cp $ICpressure gp.rst."$prettyStart".* $HOME/PFrestart/

#NLDAS Met forcings directory (if 1D, nldas.1hr.clm.txt should be in here)
mkdir $HOME/PFrestart/NLDAS
mv NLDAS/* $HOME/PFrestart/NLDAS/

#Other required inputs
mv drv_clmin_start.dat drv_clmin_restart.dat drv_vegm.dat drv_vegp.dat \
slopex.pfb slopey.pfb subsurfaceFeature.pfb dz_mult.pfb \
runParflow.tcl $HOME/PFrestart/

#Output that doesn't change with loop, only needs to be saved at very end
mv $runname.out.mannings.pfb $runname.out.mask.pfb $runname.out.perm_x.pfb \
$runname.out.perm_y.pfb $runname.out.perm_z.pfb $runname.out.porosity.pfb \
$runname.out.slope_x.pfb $runname.out.slope_y.pfb $runname.out.dz_mult.pfb \
$runname.out.specific_storage.pfb $HOME/PFrestart/

# ==============================================================================
# SAVE kinsol LOGS
# ==============================================================================
mv $runname.out.*.kinsol.log $HOME/

# ==============================================================================
# CLEAN UP AND SAVE
# ==============================================================================
#Remove unneeded files
rm -f *.log *.txt* *.dat* *.pfidb *.pftcl *.sh

#Bring kinsol logs back for PFout tarball
mv $HOME/$runname.out.*.kinsol.log $HOME/$runname/

#Tar PFout and PFrestart, move them to GHOME
cd $HOME
newdirname=$(printf "PFout.%s" $prettyGlusterSave)
mv $runname $newdirname
tarAndMove $newdirname PFrestart