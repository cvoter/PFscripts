#!/bin/bash
# setupModelSuite.sh
# 2018.04 Carolyn Voter
# Loops through runnames as specified to create dagfiles and spliced dagfiles.
# Usage: sh setupModelSuite.sh

# ==============================================================================
# SET PARAMETERS
# ==============================================================================
np=20
nHr=5160
ndrun=12
nruns=$(((nHr+ndrun-1)/ndrun))
modelsuite=soil_pixels_01

splicefile=/home/cvoter/PFscripts/DAGfiles/modelsplice/$modelsuite.dag
# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
createModelDir () {
    # Copy template
    cd /home/cvoter/PFscripts/DAGfiles
    cp -r modelname $runname

    #Replace modelname w/real runname
    cd $runname
    sed "s/modelname/$runname/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/insertHr/$nHr/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/insertdrun/$ndrun/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/insertnruns/$nruns/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/snp/$np/g" modelname.dag > tmpfile; mv tmpfile $runname.dag

    #Remove modelname
    rm modelname.dag
}

# ==============================================================================
# LOOP OVER MODELS
# ==============================================================================
for percent in 0 0.25 0.5 1 2.5 5 10 25 50 100; do
    #Define runname and dagname
    #runname=LotVacant_dry
    #dagname=DLID
    runname=$(printf "amend_pixels_%s" $percent)
    dagname=$(printf "D%s" $percent)
    echo $runname

    #Create dag and add to spliced dag file
    createModelDir
    printf "SPLICE %s /home/cvoter/PFscripts/DAGfiles/%s/%s.dag\n" $dagname $runname $runname >> $splicefile
done
