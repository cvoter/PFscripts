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
DAGfile=Cities.dag.nodes.log
for ((location=1;location<=51;location++)); do
    for type in baseline low_impact; do
        runname=$(printf "loc%02d_%s" $location $type)
        dagname=$(printf "D%02d_%s" $location $type)
		
		readInfoFile
		readDAGFile
		
		printf "%s\t%s\t%s\t%s\n" $runname $lastTime $runningTime $lastSubmit >> $outputFile

	done
done	