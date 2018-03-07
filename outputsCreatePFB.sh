#!/bin/bash
# Carolyn Voter
# outputsCreatePFB.sh
# Creates subsurface_storage.pfb and surface_storage.pfb from other *.pfb output

# Usage: sh outputsCreatePFB.sh flux
# Requires the following environment variables to be defined in parent script:
# HOME - path of working directory on local machine
# GHOME - path to where inputs and outputs are stored
# PARFLOW_DIR - path to where parflow libraries are stored
# runname - name of modeling run
# totalHr - total number of modeling hours to simulate
# flux - which storage flux is being calculated here

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
#Untar to current directory from GHOME
copyUntarHere () {
    for tarDir in $@; do
	    cp $GHOME/$tarDir.tar.gz .
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
# COPY TARBALLS TO LOCAL MACHINE AND EXTRACT
# ==============================================================================
mkdir $HOME/$flux
cd $HOME/$flux

if [ "$flux" = "subsurface_storage" ]; then
    copyUntarHere press satur PFin PFrestart
else
    copyUntarHere press PFin PFrestart
fi

# ==============================================================================
# EXPORT KEY DOMAIN VARIABLES FROM parameters.txt
# ==============================================================================
set -- $(<parameters.txt)
export xU=${10}
export yU=${11}
export domainArea=$(bc <<< "$xU * $yU")

# ==============================================================================
# DO PARFLOW STUFF
# ==============================================================================
tclsh $SCRIPTS/$flux.tcl

# ==============================================================================
# CLEAN UP
# ==============================================================================
#Move summary *.txt files to GHOME
if [ ! -d $GHOME/water_balance ]; then
    mkdir $GHOME/water_balance
fi
mv *storage_*.txt $GHOME/water_balance

#Delete everything except new flux *.pfbs
keepnames=$runname.out.$flux*
find . ! -name "${keepnames}" -delete

#Tar remaining files and move to GHOME (should be just the new flux left)
cd $HOME
tarAndMove $flux