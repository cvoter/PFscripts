#!/bin/bash
# Carolyn Voter
# outputsDomainTotals.sh
# Takes gridded hourly output and calculates hourly domain totals for specified
# fluxes.

# Usage: sh outputsDomainTotals.sh
# Requires the following environment variables to be defined in parent script:
# runname - name of model run
# HOME - absolute path to location where calculations will be performed
# GHOME - permanent home for output file for runname
# SCRIPTS - location of domainTotal.tcl

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

# Calculate hourly domain totals for fluxes
totalDomain () { 
    for flux in $@; do
	     # Make flux and storage status known to *.tcl script
	     export flux=$flux
            if [ "$flux" = "can_out" ]; then
                export storageCheck=1
            elif [ "$flux" = "swe_out" ]; then
                export storageCheck=1
            else
                export storageCheck=0
            fi

            # Get hourly *.pfb files
            cp $GHOME/$flux.tar.gz .
            tar xzf $flux.tar.gz --strip-components=1
            rm -f $flux.tar.gz

            # Do parflow stuff
            tclsh $SCRIPTS/domainTotal.tcl

            # Send output *.txt files to GHOME
            mv ${flux}_*.txt $GHOME/water_balance/
            rm -f *		
    done
}

# ==============================================================================
# EXPORT KEY DOMAIN VARIABLES FROM parameters.txt
# ==============================================================================
cd $HOME
copyUntarHere PFin
set -- $(<parameters.txt)
export xU=${10}
export yU=${11}
export domainArea=$(bc <<< "$xU * $yU")

# ==============================================================================
# CALCULATE HOURLY DOMAIN TOTAL (mm) FOR ALL FLUXES
# ==============================================================================
# ------------------------------------------------------------------------------
# canopy water (can_out)
# evaptranssum (evaptranssum)
# ground evaporation (qflx_evap_grnd)
# vegetation evaporation (qflx_evap_veg)
# snow water equivalent (swe_out)
# overland flow (overlandsum)
# transpiration (qflx_tran_veg)
# ------------------------------------------------------------------------------
totalDomain can_out evaptranssum qflx_evap_grnd qflx_evap_veg swe_out overlandsum \
            qflx_tran_veg
