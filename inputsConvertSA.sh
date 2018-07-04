#!/bin/bash
# Carolyn Voter
# inputsConvertSA.sh
# Gathers input *.sa data, calls inputsConvertSA.tcl, and regroups for model run

# Usage: sh inputsConvertSA.sh
# Requires the following environment variables to be defined in parent script:
# runname - name of modeling run
# nruns - total number of modeling loops
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
# GET DOMAIN PARAMETERS FOR DISTRIBUTING NLDAS FILES
# ==============================================================================
set -- $(<parameters.txt)
#Lower coordinates
export xL=$1
export yL=$2
export zL=$3

#Number of elements
export nx=$4
export ny=$5
export nz=$6

#Spacing of elements
export dx=$7
export dy=$8
export dz=$9

#Number of processors for x,y,z directions
export P=${13}
export Q=${14}
export R=${15}

export PFnruns=$((nruns-1))

# ==============================================================================
# CHECK FOR 3D MET (.sa) OR 1D MET (.txt)
# ==============================================================================
if ls NLDAS/*.sa 1> /dev/null 2>&1; then
    export convertNLDAS=1
else
    export convertNLDAS=0
fi

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