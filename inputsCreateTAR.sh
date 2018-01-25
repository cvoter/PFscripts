#!/bin/bash
# Carolyn Voter
# tarInputs.sh
# Takes parflow input files and combines in appropriate tar files

# Usage: sh tarInputs.sh
# Requires the following environment variables to be defined in parent script:
# runname - name of modeling run
# GHOME - path to where inputs and outputs are stored for $runname
# SCRIPTS - path to where PFscripts are stored

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
# ------------------------------------------------------------------------------
# CREATE TARBALL OF SPECIFIED INPUTS
# ------------------------------------------------------------------------------
tarInput () { 
    for inputDir in $@; do
	    #Create directory
	    mkdir $inputDir
	
	    #Move appropriate inputs to directory
	    if [ "$inputDir" = "SAin" ]; then
            mv *.sa $inputDir/
            cp $SCRIPTS/inputsConvertSA.tcl $inputDir/
        elif [ "$inputDir" = "PFin" ]; then
            mv drv_clmin_start.dat drv_clmin_restart.dat drv_vegm.dat drv_vegp.dat nldas.1hr.clm.txt parameters.txt $inputDir/
            cp $SCRIPTS/runParflow.tcl $inputDir/
        else
            mv domainInfo.mat precip.mat $inputDir/
        fi
	  
	    #Tar directory, remove untarred version
	    tar zcf $inputDir.tar.gz $inputDir
        rm -rf $inputDir
    done
}
	
# ==============================================================================
# CREATE SAin
# Tarred file of *.sa inputs
# ==============================================================================
cd $GHOME
tarInput SAin PFin MATin
rm *.fig