#!/bin/bash
# 2016.01 Carolyn Voter
# Major update: 2017.09
# runParflow.sh
# Executable to set up environmental variables and run ParFlow *.tcl script


# ===================================================================================
# INTERPRET ARGUMENTS
# 1 = runname
# 2 = totalHr = total number of model hours for complete simulation
# 3 = drun = number of model hours per loop
# 4 = P = number of processors for x-axis
# 5 = Q = number of processors for y-axis
# 6 = np = total number of processors (P*Q)
# nruns = number of loops to execute, based on total hours and hours per loop
# R = number of processors for z-axis, always 1.
# ===================================================================================
export runname=$1
export totalHr=$2
export drun=$3
export P=$4
export Q=$5
export np=$6
export nruns=$(((totalHr+drun-1)/drun))
export R=1

# ===================================================================================
# SET ENVIRONMENT VARIABLES
# Paths for libraries, compilers, relavant directories
# On HTCondor setup, parflow (and dependent libraries) are installed at "BASE" directory
# Model output is generated on local machine ("HOME"), then transferred to Gluster fileserver ("GHOME")
# ===================================================================================
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export HOME=$(pwd)
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export HYPRE_PATH=$BASE/hypre-2.9.0b
export TCL_PATH=$BASE/tcl-8.6.5
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

# ===================================================================================
# CREATE RUN DIRECTORY, UNZIP INPUTS
# On local machine
# ===================================================================================
mkdir $HOME/$runname
cp $GHOME/PFin.tar.gz $HOME/$runname/
cd $HOME/$runname
tar xzf PFin.tar.gz --strip-components=1
rm -f PFin.tar.gz

# ===================================================================================
# EXPORT KEY DOMAIN VARIABLES
# All stored in parameters.txt
# ===================================================================================
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

# ===================================================================================
# DETERMINE STARTING TIMESTEP AND STARTING LOOP
# Searches for pressure files to determine what last saved timestep was.
# From this info, sets starting hour (for parflow) and starting loop number.
# ===================================================================================
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

# ===================================================================================
# INITIALIZE LOG
# I keep track of key input paramters and timing information in a customized log file.
# This allows me to condense key information from the myriad logs parflow generates.
# Initialize log with runname, date and time, parameter values with units (from parameters.txt)
# ===================================================================================
printf "============================PF START LOOP: %d...PF START TIME: %d============================\n" $start $pfStartCount >> $runname.info.txt
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

# ===================================================================================
# LOOP THROUGH RUNS
# I execute the entire simulation via many small loops (e.g., 12 hrs at a time).
# This allows me to send output back to Gluster fileserver at regular intervals,
# which minimizes the output I lose if model is unable to finish in 72hrs (HTCondor time limit).
# ===================================================================================
for ((loop=start;loop<=nruns;loop++)); do
  # -------------------------------------------
  # SET UP
  # -------------------------------------------
  #PRETTY FORMAT OF LOOP NUMBER. USED LATER WHEN RENAME KINSOL LOG AND OUTPUT DIRECTORY.
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
    cp -f drv_climin_start.dat drv_clmin.dat
  fi

  #RECORD START INFO IN LOG
  printf "========PF START HOUR %d========\n" $pfStartCount >> $runname.info.txt
  
  # -------------------------------------------
  # DO PARFLOW STUFF
  # -------------------------------------------
  tclsh runParflow.tcl

  # -------------------------------------------
  # CLEAN UP
  # -------------------------------------------
  #FINAL PRESSURE AND TIMING (aka start info for next loop)
  export startDelete=$pfStartCount
  export ICpressure=$(find . -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
  export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
  export prettyStart=$(printf "%05d" $pfStartCount)
  if [ $startDelete -eq $pfStartCount ]; then
    flag=1
    loop=nruns
    printf "\n\n=====START IS SAME AS END, ABORT=======\n\n">> $runname.info.txt
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

  #DELETE DISTRIBUTED PFBS AND EXTRA CLM RESTARTS (extra files, not needed for post-processing)
  find . -name "*pfb.dist*" -delete
  for ((i=startDelete;i<pfStartCount;i++)); do
    num=$(printf "%05d" $i)
    rm gp.rst."$num".*
  done

  #SET ASIDE UPDATED PFin FILES
  mkdir $HOME/PFin
  #Current log
  mv $runname.info.txt $HOME/PFin/
  #Restart files (pressure and CLM)
  mv $ICpressure gp.rst."$prettyStart".* $HOME/PFin/
  #Other required inputs
  mv drv_clmin_start.dat drv_clmin_restart.dat drv_vegm.dat drv_vegp.dat nldas.1hr.clm.txt \
     slopex.pfb slopey.pfb subsurfaceFeature.pfb runParflow.tcl $HOME/PFin/
  #Output that doesn't change with loop, only needs to be saved at very end
  mv $runname.out.mannings.pfb $runname.out.mask.pfb $runname.out.perm_x.pfb \
     $runname.out.perm_y.pfb $runname.out.perm_z.pfb $runname.out.porosity.pfb \
     $runname.out.slope_x.pfb $runname.out.slope_y.pfb $runname.out.specific_storage.pfb $HOME/PFin/

  #RENAME KINSOL LOG, TEMPORARILY MOVE TO $HOME
  mv $runname.out.kinsol.log $HOME/$runname.out.$prettyLoop.kinsol.log

  #DELETE ALL NON-PFB FILES IN OUTPUT DIRECTORY
  rm -f *.log *.txt* *.dat* *.pfidb

  #BRING BACK KINSOL LOG TO OUTPUT DIRECTORY
  $HOME/$runname.out.$prettyLoop.kinsol.log .

  #TAR OUTPUT DIRECTORY, SEND TO GLUSTER
  cd ..
  newdirname=$(printf "PFout.%s" $prettyLoop)
  mv $runname $newdirname
  tar zcf $newdirname.tar.gz $newdirname
  mv $newdirname.tar.gz $GHOME
  rm -rf $newdirname

  #COPY UPDATED PFin.tar.gz TO GLUSTER
  tar zcf PFin.tar.gz PFin
  cp -f PFin.tar.gz $GHOME/
  rm -rf PFin

  #RECREATE ACTIVE MODEL DIRECTORY, REPOPULATE WITH UPDATED PFin.tar.gz
  mkdir $runname
  mv PFin.tar.gz $runname
  cd $runname
  tar xzf PFin.tar.gz --strip-components=1
  rm -f PFin.tar.gz
done

# ===================================================================================
# EXIT
# Exit with error if a timestep failed (triggered $flag)
# If succeeded, remove model directory before exiting
# ===================================================================================
if [ $flag -eq 1 ]; then
  exit 1
else
  cd $HOME
  rm -rf $runname
  exit 0
fi