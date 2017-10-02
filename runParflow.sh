#!/bin/bash
# 2016.01 Carolyn Voter
# Major update: 2017.09
# runParflow.sh
# Executable to set up environmental variables and run ParFlow *.tcl script


# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname
# 2 = totalHr = total number of model hours for complete simulation
# 3 = drun = number of model hours per loop
# 4 = P = number of processors for x-axis
# 5 = Q = number of processors for y-axis
# 6 = np = total number of processors (P*Q)
# nruns = number of loops to execute, based on total hours and hours per loop
# R = number of processors for z-axis, always 1.
# ==============================================================================
export runname=$1
export totalHr=$2
export drun=$3
export P=$4
export Q=$5
export np=$6
export nruns=$(((totalHr+drun-1)/drun))
export R=1

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# Paths for libraries, compilers, relavant directories
# On HTCondor setup, parflow + dependent libraries installed in "BASE" directory
# Model output first generated on local machine ("HOME")
# Model output then transferred to gluster fileserver ("GHOME")
# ==============================================================================
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export HOME=$(pwd)
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export HYPRE_PATH=$BASE/hypre-2.9.0b
export TCL_PATH=$BASE/tcl-8.6.7
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
# ------------------------------------------------------------------------------
# SAVE OUTPUT TO GLUSTER
# ------------------------------------------------------------------------------
glusterSave () { 
    #SET ASIDE FILES NEEDED FOR RESTARTS
    mkdir $HOME/PFrestart
    #Current log
    mv $runname.info.txt $HOME/PFrestart/
    #Restart files (pressure and CLM)
    cp $ICpressure gp.rst."$prettyStart".* $HOME/PFrestart/
    #Other required inputs
    mv drv_clmin_start.dat drv_clmin_restart.dat drv_vegm.dat drv_vegp.dat \
       nldas.1hr.clm.txt slopex.pfb slopey.pfb subsurfaceFeature.pfb \
       runParflow.tcl $HOME/PFrestart/
    #Output that doesn't change with loop, only needs to be saved at very end
    mv $runname.out.mannings.pfb $runname.out.mask.pfb $runname.out.perm_x.pfb \
       $runname.out.perm_y.pfb $runname.out.perm_z.pfb $runname.out.porosity.pfb \
       $runname.out.slope_x.pfb $runname.out.slope_y.pfb \
       $runname.out.specific_storage.pfb $HOME/PFrestart/

    #TEMPORARILY MOVE ALL KINSOL LOGS TO $HOME
    mv $runname.out.*.kinsol.log $HOME/

    #DELETE ALL EXTRA FILES IN OUTPUT DIRECTORY (only keep pfb and gp.rst)
    rm -f *.log *.txt* *.dat* *.pfidb *.pftcl

    #BRING BACK KINSOL LOGS TO OUTPUT DIRECTORY
    mv $HOME/$runname.out.*.kinsol.log ./

    #TAR OUTPUT DIRECTORY, SEND TO GLUSTER
    cd ..
    newdirname=$(printf "PFout.%s" $prettyGlusterSave)
    mv $runname $newdirname
    tar zcf $newdirname.tar.gz $newdirname
    mv $newdirname.tar.gz $GHOME
    rm -rf $newdirname

    #COPY UPDATED PFrestart.tar.gz TO GLUSTER
    tar zcf PFrestart.tar.gz PFrestart
    cp -f PFrestart.tar.gz $GHOME/
    rm -rf PFrestart

    #UPDATE lastGluster TIME AND SAVE COUNTERS
    lastGluster=$(date +%s)
    numGlusterSave=$((numGlusterSave+1))
    prettyGlusterSave=$(printf "%03d" $numGlusterSave)
}

# ==============================================================================
# 1. CREATE RUN DIRECTORY, UNZIP INPUTS
# On local machine
# ==============================================================================
#CREATE RUN DIRECTORY
mkdir $HOME/$runname

#IDENTIFY CORRECT INPUT TARBALL
if [ ! -f $GHOME/PFrestart.tar.gz ]; then
  inputTAR=$GHOME/PFin.tar.gz
else
  inputTAR=$GHOME/PFrestart.tar.gz
fi

#COPY INPUT TARBALL TO RUN DIRECTORY, UNZIP
cp $inputTAR $HOME/$runname/
cd $HOME/$runname
tar xzf $inputTAR --strip-components=1
rm -f $inputTAR

#INITIALIZE lastGluster TIME AND SAVE COUNTERS
#Current date-time in seconds
lastGluster=$(date +%s)
numGlusterSave=1
prettyGlusterSave=$(printf "%03d" $numGlusterSave)

# ==============================================================================
# 2. EXPORT KEY DOMAIN VARIABLES
# All stored in parameters.txt
# ==============================================================================
set -- $(<parameters.txt)
export xL=$1
export yL=$2
export zL=$3

export nx=$4
export ny=$5
export nz=$6

export dx=$7
export dy=$8
export dz=$9

export xU=${10}
export yU=${11}
export zU=${12}

export Ks_soil=${16}
export mn_grass=${17}
export VGa_soil=${18}
export VGn_soil=${19}
export porosity_soil=${20}
export Ssat_soil=${21}
export Sres_soil=${22}

export Ks_imperv=${23}
export mn_imperv=${24}
export VGa_imperv=${25}
export VGn_imperv=${26}
export porosity_imperv=${27}
export Ssat_imperv=${28}
export Sres_imperv=${29}

# ==============================================================================
# 3. DETERMINE STARTING TIMESTEP AND STARTING LOOP
# Searches for pressure files to determine what last saved timestep was.
# From this info, sets starting hour (for parflow) and starting loop number.
# ==============================================================================
export ICpressure=$(find . -maxdepth 1 -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
if [ -z "$pfStartCount" ]; then
  #This is the first timestep (all zeros in pressure file)
  export pfStartCount=0
  export start=1
else
  #This is a later timestep. Calculate loop number based on pfStartCount
  export start=$((pfStartCount/drun+1))
fi

# ==============================================================================
# 4. INITIALIZE LOG
# Track key input paramters and timing information in a customized log file.
# Allows me to condense key information from the myriad logs parflow generates.
# Initialize log with runname, date/time, parameter values with units
# ==============================================================================
printf "====PF START LOOP: %d...PF START TIME: %d====\n" $start $pfStartCount >> $runname.info.txt
printf "%s\n" $runname >> $runname.info.txt
date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
printf "\nPARAMETERS\nUnits: L[=]meters, T[=]hours, M[=]kilograms\nDomain\n" >> $runname.info.txt
printf "[xL,yL,zL] = [%.2f, %.2f, %.2f] meters\n" $xL $yL $zL >> $runname.info.txt
printf "[nx,ny,nz] = [%.0f, %.0f, %.0f]\n" $nx $ny $nz >> $runname.info.txt
printf "[dx,dy,dz] = [%.2f, %.2f, %.2f] meters\n" $dx $dy $dz >> $runname.info.txt
printf "[xU,yU,zU] = [%.2f, %.2f, %.2f] meters\n" $xU $yU $zU >> $runname.info.txt
printf "[P,Q,R,np] = [%.0f, %.0f, %.0f, %.0f]\n" $ptP $ptQ $ptR $np >> $runname.info.txt
printf "Soil\n" >> $runname.info.txt
printf "[Ksat,mn] = [%.4e, %.4e]\n" $Ks_soil $mn_grass >> $runname.info.txt
printf "[VGa,VGn] = [%.2f, %.2f]\n" $VGa_soil $VGn_soil >> $runname.info.txt
printf "[porosity,Ssat,Sres] = [%.2f, %.2f, %.3f]\n" $porosity_soil $Ssat_soil $Sres_soil >> $runname.info.txt
printf "Impervious\n" >> $runname.info.txt
printf "[Ksat,mn] = [%.4e, %.4e]\n" $Ks_imperv $mn_imperv >> $runname.info.txt
printf "[VGa,VGn] = [%.2f, %.2f]\n" $VGa_imperv $VGn_imperv >> $runname.info.txt
printf "[porosity,Ssat,Sres] = [%.3f, %.2f, %.3f]\n\n\n" $porosity_imperv $Ssat_imperv $Sres_imperv >> $runname.info.txt

# ==============================================================================
# 5. LOOP THROUGH RUNS
# I execute the entire simulation via many small loops (e.g., 12 hrs at a time).
# Allows me to send output to Gluster fileserver at regular intervals, which
# minimizes output lost if model does not finish in 72hrs (HTCondor time limit).
# ==============================================================================
for ((loop=start;loop<=nruns;loop++)); do
  # ----------------------------------------------------------------------------
  # SET UP
  # ----------------------------------------------------------------------------
  #PRETTY FORMAT OF LOOP NUMBER (used later in renaming kinsol logs)
  prettyLoop=$(printf "%04d" $loop)

  #STOP TIME FOR THIS LOOP
  if [ $loop -eq $nruns ]; then
    export pfStopTime=$((totalHr-pfStartCount))
  else
    export pfStopTime=$((loop*drun-pfStartCount))
  fi

  #CLM START TYPE FOR THIS LOOP
  if [ $loop -gt 1 ]; then
    cp -f drv_clmin_restart.dat drv_clmin.dat
  else
    cp -f drv_clmin_start.dat drv_clmin.dat
  fi

  #RECORD START INFO IN LOG
  printf "========PF START HOUR %d========\n" $pfStartCount >> $runname.info.txt
  
  # ----------------------------------------------------------------------------
  # DO PARFLOW STUFF
  # ----------------------------------------------------------------------------
  tclsh runParflow.tcl

  # ----------------------------------------------------------------------------
  # CLEAN UP
  # ----------------------------------------------------------------------------
  #FINAL PRESSURE AND TIMING (aka start info for next loop)
  export startDelete=$((pfStartCount+1))
  export ICpressure=$(find . -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
  export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
  export prettyStart=$(printf "%05d" $pfStartCount)
  if [ $startDelete -eq $pfStartCount ]; then
    printf "\n\n=====START IS SAME AS END, ABORT=======\n\n">> $runname.info.txt
    exit 1
  fi

  #RECORD CLM, PROCESSOR, ENDING INFO IN LOG
  #CLM starting step
  printf "CLM step: " >> $runname.info.txt
  sed -n '/CLM starting istep/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
  #CLM restart or defined start?
  printf "CLM startcode for date (1=restart, 2=defined): " >> $runname.info.txt
  sed -n '/CLM startcode/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
  printf "CLM startcode for IC (1=restart, 2=defined): " >> $runname.info.txt
  sed -n '/CLM IC/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
  #CLM starting date
  sed -n '/CLM Start Time/{p;q;}' $runname.out.txt | sed -r 's/^.{1}//' >> $runname.info.txt
  #CHTC processor address
  head -$np $runname.out.txt >> $runname.info.txt
  #Ending time info
  printf "\n" >> $runname.info.txt
  date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
  printf "PF stop hour: %d\n" $pfStartCount >> $runname.info.txt
  Tstartstring=$(sed '3q;d' $runname.info.txt)
  Tstart="$(date --date="$Tstartstring" +%s)"
  T="$(($(date +%s)-Tstart))"
  ((sec=T%60, T/=60, min=T%60, hrs=T/60))
  printf "Running total time: %d:%02d:%02d\n\n\n" $hrs $min $sec >> $runname.info.txt

  #DELETE DISTRIBUTED PFBS AND EXTRA CLM RESTARTS (extra files no longer needed)
  find . -name "*pfb.dist*" -delete
  for ((i=startDelete;i<pfStartCount;i++)); do
    num=$(printf "%05d" $i)
    rm gp.rst."$num".*
  done

  # RENAME KINSOL LOG
  mv $runname.out.kinsol.log $runname.out.$prettyLoop.kinsol.log

  # ----------------------------------------------------------------------------
  # TRANSFER TO GLUSTER 
  # Only if > 1hr since last transfer
  # ----------------------------------------------------------------------------
  timeElapsed="$(($(date +%s)-lastGluster))"
  timeElapsedHrs=$((timeElapsed/3600))
  if [ $timeElapsedHrs -ge 1 ]; then
    glusterSave
    
    #RECREATE ACTIVE MODEL DIRECTORY, REPOPULATE WITH UPDATED PFrestart.tar.gz
    mkdir $runname
    mv PFrestart.tar.gz $runname
    cd $runname
    tar xzf PFrestart.tar.gz --strip-components=1
    rm -f PFrestart.tar.gz
  fi
done

# ==============================================================================
# 6. EXIT
# If succeeded, remove remaining model files before exiting
# ==============================================================================
cd $HOME
rm -f PFrestart.tar.gz
exit 0