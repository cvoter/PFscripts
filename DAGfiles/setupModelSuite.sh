#!/bin/bash
# setupModelSuite.sh
# 2018.04 Carolyn Voter
# Loops through runnames as specified to create dagfiles and spliced dagfiles.
# Usage: sh setupModelSuite.sh

# ==============================================================================
# SET PARAMETERS
# ==============================================================================
P=4
Q=5
np=20
nHr=12
modelsuite=LotVacantDZ

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
    sed "s/sP/$P/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/sQ/$Q/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/snp/$np/g" modelname.dag > tmpfile; mv tmpfile $runname.dag

    #Remove modelname
    rm modelname.dag
}

# ==============================================================================
# LOOP OVER MODELS
# ==============================================================================
#for ((L=2;L<=2;L++)); do
#for Y in ConstDZ VarDZ; do
    #Define runname and dagname
    runname=Lot1111_SiL_2012
    dagname=DLID
    #runname=$(printf "LotVacant_%s" $Y)
    #dagname=$(printf "D%s" $Y)
    echo $runname

    #Create dag and add to spliced dag file
    createModelDir
    printf "SPLICE %s /home/cvoter/PFscripts/DAGfiles/%s/%s.dag\n" $dagname $runname $runname >> $splicefile
#done