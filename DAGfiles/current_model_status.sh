#!/bin/bash
# current_model_status.sh
# Carolyn Voter
# Monitors current model run status for suite of parflow models

# Usage: sh current_model_status.sh
# Requires the following environment variables to be defined in parent script:
# 

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
# Find info file and read last step
readInfoFile () {
    lastTime=''
	runningTime=''
	cd $GHOME/$runname
	if [ -e $runname.info.txt ]; then
	    lastTime=$(grep "PF stop hour:" $runname.info.txt | tail -1 | sed -e 's/PF stop hour: //g')
		runningTime=$(grep "Running total time:" $runname.info.txt | tail -1 | sed -e 's/Running total time: //g')
	else
	    lastTime=0
		runningTime=0
	fi
}

# Find dag info and read last step
readDAGFile () {
    lastSubmit=''
    cd $DAGdir
	lastSubmit=$(grep $dagname $DAGfile | tail -1 | sed -e 's/.*DAG Node.*+//g')
}

# ==============================================================================
# LOOP THROUGH MODELS
# ==============================================================================
outputFile=~/PFscripts/DAGfiles/current_model_status.txt
printf "Runname\tPF Hour\tPF Running Total\tDAG submit\n" > $outputFile

GHOME=/mnt/gluster/cvoter/ParflowOut
DAGdir=~/PFscripts/DAGfiles/modelsplice
DAGfile=soil_pixels_01.dag.nodes.log

for percent in 0 0.25 0.5 1 2.5 5 10 25 50 100; do
    runname=$(printf "amend_pixels_%s" $percent)
    dagname=$(printf "D%s" $percent)
    echo $runname
    readInfoFile
    readDAGFile
    printf "%s\t%s\t%s\t%s\n" $runname $lastTime $runningTime $lastSubmit >> $outputFile
done

DAGfile=soil_pixels_02.dag.nodes.log
count=1
for runname in amend_feature_ds0_fw0_dw0_sw1 amend_feature_ds0_fw0_dw0_sw2 amend_feature_ds0_fw0_dw0_sw4 amend_feature_ds0_fw0_dw1_sw0 amend_feature_ds0_fw0_dw2_sw0 amend_feature_ds0_fw1_dw0_sw0 amend_feature_ds0_fw2_dw0_sw0 amend_feature_ds1_fw0_dw0_sw0 amend_feature_ds1_fw0_dw0_sw4 amend_feature_ds1_fw1_dw1_sw1 amend_feature_ds3_fw0_dw0_sw0 amend_feature_ds3_fw0_dw0_sw4 amend_feature_ds3_fw1_dw1_sw1; do
    echo $runname
    dagname=$(printf "D%02d" $count)
    readInfoFile
    readDAGFile
    printf "%s\t%s\t%s\t%s\n" $runname $lastTime $runningTime $lastSubmit >> $outputFile
    count=$((count+1))
done	