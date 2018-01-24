#!/bin/bash
# Carolyn Voter
# inputsConvertSA.sh
# Gathers input *.sa data, calls inputsConvertSA.tcl, and regroups for model run

# Usage: sh inputsConvertSA.sh
# Requires the following environment variables to be defined in parent script:
# runname - name of modeling run
# HOME = path of working directory on local machine
# GHOME - path to where inputs and outputs are stored
# PARFLOW_DIR - path to where parflow libraries are stored
# SCRIPTS - path to where PFscripts are stored

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
#Untar to current directory from GHOME
copyUntarHere () {
    for tarDir in $@; do
	    cp $GHOME/$tarDir.tar.gz $HOME/$runname
        tar xzf $tarDir.tar.gz --strip-components=1
        rm -f $tarDir.tar.gz  
    done
}

#Tar and move to GHOME
tarAndMove () {
    for tarDir in $@; do
	    tar zcf $tarDir.tar.gz $tarDir
		mv -f $tarDir.tar.gz $GHOME/
        rm -rf $tarDir 
    done
}

# ==============================================================================
# GET INPUT FILES
# ==============================================================================
mkdir $HOME/$runname
cd $HOME/$runname
copyUntarHere PFin SAin

# ==============================================================================
# DO PARFLOW STUFF
# ==============================================================================
tclsh inputsConvertSA.tcl

# ==============================================================================
# CLEAN UP
# ==============================================================================
rm -f inputsConvertSA.tcl *.sa

#TAR BACK UP ALL INPUT FILES (will replace old PFin.tar.gz)
mkdir PFin
mv * PFin/
tarAndMove PFin