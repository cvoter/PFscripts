#!/bin/bash
# Carolyn Voter
# runParflow.sh
# Runs and periodically saves output from parflow model

# Usage: sh runParflow.sh
# Requires the following environment variables to be defined in parent script:
# runname - name of modeling run
# HOME - path of working directory on local machine
# GHOME - path to where inputs and outputs are stored
# PARFLOW_DIR - path to where parflow libraries are stored
# totalHr - total number of modeling hours to simulate
# drun - number of model hours per loop, before saving (typically 12hrs)
# nruns - number of loops to run in order to complete simulation.

# ==============================================================================
# 0. DEFINE FUNCTIONS
# ==============================================================================
# ------------------------------------------------------------------------------
# A. UNTAR TO CURRENT DIRECTORY
# ------------------------------------------------------------------------------
#Untar to current directory from GHOME
copyUntarHere () {
    for tarDir in $@; do
	    cp $GHOME/$tarDir.tar.gz .
        tar xzf $tarDir.tar.gz --strip-components=1
        rm -f $tarDir.tar.gz  
    done
}

# ------------------------------------------------------------------------------
# B. TIME COUNTERS FOR SAVING OUTPUT TO GLUSTER
# Save output once per hour or every 12 model hours, whichever is slower.
# ------------------------------------------------------------------------------
updateTimeCounters () { 
    #Current date-time in seconds
    lastGluster=$(date +%s)
    numGlusterSave=$((numGlusterSave+1))
    export prettyGlusterSave=$(printf "%03d" $numGlusterSave)
}
# ------------------------------------------------------------------------------
# C. FIND LOOP START TIME
# Search pressure files for last save, define as ICpressure and use filename to
# get pfStartCount for next loop
# ------------------------------------------------------------------------------
findNextStart () { 
    export ICpressure=$(find . -maxdepth 1 -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
    export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
}

# ==============================================================================
# 1. GET INPUTS TO LOCAL MACHINE
# ==============================================================================
#Create run directory on local machine
mkdir $HOME/$runname
cd $HOME/$runname

#Find and move correct input tarball to local machine
if [ ! -f $GHOME/PFrestart.tar.gz ]; then
    inputTAR=PFin
else
    inputTAR=PFrestart
fi
copyUntarHere $inputTAR

# ==============================================================================
# 2. EXPORT KEY DOMAIN VARIABLES FROM parameters.txt
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

#Upper coordinates
export xU=${10}
export yU=${11}
export zU=${12}

#Number of processors for x,y,z directions
export P=${13}
export Q=${14}
export R=${15}
export np=$((P*Q))

#Pervious surface and subsurface parameters
export Ks_soil=${16}
export mn_grass=${17}
export VGa_soil=${18}
export VGn_soil=${19}
export porosity_soil=${20}
export Ssat_soil=${21}
export Sres_soil=${22}

#Impervious surface and subsurface parameters
export Ks_imperv=${23}
export mn_imperv=${24}
export VGa_imperv=${25}
export VGn_imperv=${26}
export porosity_imperv=${27}
export Ssat_imperv=${28}
export Sres_imperv=${29}

# ==============================================================================
# 3. FIGURE OUT WHERE MODEL LEFT OFF AND TAKE NOTES
# ==============================================================================
#Setup start counters
findNextStart
if [ -z "$pfStartCount" ]; then
  #This is the first timestep (all zeros in pressure file)
  export pfStartCount=0
  export start=1
else
  #This is a later timestep. Calculate loop number based on pfStartCount
  export start=$((pfStartCount/drun+1))
fi

#If model is finished, abort here.
if [[ $totalHr -eq $pfStartCount ]]; then
    sh $SCRIPTS/logComments.sh modelDone
	exit 0
fi

#Initialize master log file by recording runname, date/time, input parameters
sh $SCRIPTS/logComments.sh initialize

#Initialize time counters for saving output to gluster
updateTimeCounters

# ==============================================================================
# 4. LOOP THROUGH RUNS
# ==============================================================================
for ((loop=start;loop<=nruns;loop++)); do
    # --------------------------------------------------------------------------
    # A. SET UP THIS LOOP
    # --------------------------------------------------------------------------
    #Stop time
    if [[ $loop -eq $nruns ]]; then
        export pfStopTime=$((totalHr-pfStartCount))
    else
        export pfStopTime=$((loop*drun-pfStartCount))
    fi

    #CLM start type
    if [[ $loop -gt 1 ]]; then
        cp -f drv_clmin_restart.dat drv_clmin.dat
    else
        cp -f drv_clmin_start.dat drv_clmin.dat
    fi

    #Record start in log
    sh $SCRIPTS/logComments.sh loopStart
  
    # --------------------------------------------------------------------------
    # B. DO PARFLOW STUFF
    # --------------------------------------------------------------------------
    tclsh runParflow.tcl

    # --------------------------------------------------------------------------
    # C. CLEAN UP THIS LOOP
    # --------------------------------------------------------------------------
    #Determine final pressure and timing (aka start info for next loop)
    export startDelete=$((pfStartCount+1))
    findNextStart
    export prettyStart=$(printf "%05d" $pfStartCount)
    if [[ $startDelete -eq $pfStartCount ]]; then
        sh $SCRIPTS/logComments.sh startIsEnd
    fi

    #Record end in log
    sh $SCRIPTS/logComments.sh loopEnd

    #Delete extra files no longer needed
    find . -name "*pfb.dist*" -delete
    for ((i=startDelete;i<pfStartCount;i++)); do
        num=$(printf "%05d" $i)
        rm gp.rst."$num".*
    done

    #Rename kinsol log so it is not overwritten by the next loop
    prettyLoop=$(printf "%04d" $loop)
    mv $runname.out.kinsol.log $runname.out.$prettyLoop.kinsol.log

    # --------------------------------------------------------------------------
    # D. MOVE OUTPUTS FROM LOCAL MACHINE TO GLUSTER
    # --------------------------------------------------------------------------
    timeElapsed="$(($(date +%s)-lastGluster))"
    timeElapsedHrs=$((timeElapsed/3600))
    #Only save if > 1hr since last transfer
    if [ $timeElapsedHrs -ge 1 ]; then
        #Save and update save time counters
        sh $SCRIPTS/saveCurrentOutputs.sh
        updateTimeCounters
        #Repopulate local machine with PFrestart.tar.gz
        mkdir $HOME/$runname
		cd $HOME/$runname
        copyUntarHere PFrestart
    fi
done
 
# ------------------------------------------------------------------------------
# 5. FINISH PARFLOW MODEL
# ------------------------------------------------------------------------------
sh $SCRIPTS/saveCurrentOutputs.sh
exit 0