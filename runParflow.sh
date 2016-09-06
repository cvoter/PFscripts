#!/bin/bash
# 2016.01 Carolyn Voter
# runParflow.sh
# Executable to set up environmental variables and run ParFlow *.tcl script

export runname=$1
export totalHr=$2
export drun=$3
export nruns=$(((totalHr+drun-1)/drun))

# -------------------------------------------
# SET ENVIRONMENT VARIABLES
# -------------------------------------------
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran
export HOME=$(pwd)
export BASE=/mnt/gluster/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export SILO_PATH=$BASE/silo-4.9.1-bsd
export HYPRE_PATH=$BASE/hypre-2.9.0b
export TCL_PATH=$BASE/tcl-8.6.5
export HDF5_PATH=$BASE/hdf5-1.8.17
export LD_LIBRARY_PATH=$HDF5_PATH/lib:$LD_LIBRARY_PATH
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

# -------------------------------------------
# CREATE RUN DIRECTORY AND GRAB ESSENTIAL FILES FROM GLUSTER
# -------------------------------------------
mkdir $HOME/$runname
cp runParflow.tcl $HOME/$runname/
cp $GHOME/{drv_clmin.dat,drv_clmin_restart.dat,drv_vegm.dat,drv_vegp.dat,slopex.pfb,slopey.pfb,subsurfaceFeature.pfb,nldas.1hr.clm.txt,parameters.txt} $HOME/$runname/
cd $HOME/$runname

# -------------------------------------------
# EXPORT KEY DOMAIN VARIABLES
# -------------------------------------------
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

export P=${13}
export Q=${14}
export R=${15}
export np=$((P*Q*R))

export Ks_soil=${18}
export mn_grass=${19}
export VGa_soil=${20}
export VGn_soil=${21}
export porosity_soil=${22}
export Ssat_soil=${23}
export Sres_soil=${24}

export Ks_imperv=${25}
export mn_imperv=${26}
export VGa_imperv=${27}
export VGn_imperv=${28}
export porosity_imperv=${29}
export Ssat_imperv=${30}
export Sres_imperv=${31}

# -------------------------------------------
# CHECK APPROPRIATE ICs AND STARTING LOOP
# -------------------------------------------
cd $GHOME
export ICpressure=$(find . -maxdepth 1 -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
if [ -z "$ICpressure" ]; then
  #Nothing exists, this is the first one
  export ICpressure="ICpressure.pfb"
  export pfStartCount=0
  export start=1
else
  #Use last saved pressure file
  cp $runname.info.txt $HOME/$runname/$runname.info.txt
  cp $runname.kinsol.log $HOME/$runname/$runname.kinsol.log
  export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
  export start=$((pfStartCount/drun+1))
  export prettyStart==$(printf "%05d" $pfStartCount)
  cp gp.rst."$prettyStart".* $HOME/$runname/
fi
cp $ICpressure $HOME/$runname/
cd $HOME/$runname

# -------------------------------------------
# INITIALIZE LOGS
# -------------------------------------------
# CREATE KINSOL LOG FILE
printf "\n\n\n============================PF START LOOP: %d...PF START TIME: %d============================\n" $start $pfStartCount >> $runname.kinsol.log

# CREATE INFO FILE
printf "============================PF START LOOP: %d...PF START TIME: %d============================\n" $start $pfStartCount >> $runname.info.txt
printf "%s\n" $runname >> $runname.info.txt
date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
printf "\nPARAMETERS\nUnits: L[=]meters, T[=]seconds, M[=]kilograms\nDomain\n" >> $runname.info.txt
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

# -------------------------------------------
# LOOP THROUGH RUNS
# -------------------------------------------
for ((loop=start;loop<=nruns;loop++)); do
  prettyloop=$(printf "%02d" $loop)
  #Calculate stop time
  if [ $loop -eq $nruns ]; then
    export pfStopTime=$((totalHr-pfStartCount))
  else
    export pfStopTime=$((loop*drun-pfStartCount))
  fi
  #Make sure use restart, if needed
  if [ $loop -gt 1 ]; then
    if [ -e drv_clmin_restart.dat ]; then
      mv -f drv_clmin_restart.dat drv_clmin.dat
    fi
  fi
  #Record start time in logs
  printf "\n============================PF START HOUR: %d============================\n" $pfStartCount >> $runname.kinsol.log
  printf "========PF START HOUR %d========\n" $pfStartCount >> $runname.info.txt
  
  # -------------------------------------------
  # DO PARFLOW STUFF
  # -------------------------------------------
  tclsh runParflow.tcl

  # -------------------------------------------
  # CLEAN UP
  # -------------------------------------------
  # FINAL PRESSURE AND TIMING
  export startDelete=$pfStartCount
  export ICpressure=$(find . -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
  export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
  export prettyStart=$(printf "%05d" $pfStartCount)
  
  # WHAT CLM RESTART FILES EXIST HERE?
  pwd >> $runname.info.txt
  ls >> $runname.info.txt 

  # DELETE DIST PFBS AND EXTRA CLM RESTARTS
  find . -name "*pfb.dist*" -delete
  for ((i=startDelete;i<pfStartCount;i++)); do
    num=$(printf "%05d" $i)
    rm gp.rst."$num".*
  done

  # SAVE PREVIOUS KINSOL LOG
  cat $runname.out.kinsol.log >> $runname.kinsol.log

  # SAVE CLM, PROCESSOR, ENDING INFO
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

  # TAR AND MOVE TO GLUSTER
  #Logs first
  rm -f $GHOME/$runname.info.txt
  cp $runname.info.txt $GHOME/$runname.info.txt
  rm -f $GHOME/$runname.kinsol.log
  cp $runname.kinsol.log $GHOME/$runname.kinsol.log
  #Restart files second
  cp $ICpressure $GHOME/
  cp gp.rst."$prettyStart".* $GHOME/
  cd ..
  newdirname=$(printf "%s_%s" $runname $prettyloop)
  tar zcf $newdirname.tar.gz $runname
  cp $newdirname.tar.gz $GHOME
  rm -f $newdirname.tar.gz
  cd $runname

  # REMOVE FILES THAT JUST TRANSFERED, RESET ICPRESSURE
  mkdir $HOME/savethese
  mv drv_vegm.dat drv_vegp.dat nldas.1hr.clm.txt slopex.pfb slopey.pfb subsurfaceFeature.pfb runParflow.tcl $runname.info.txt $runname.kinsol.log gp.rst."$prettyStart".* $ICpressure $HOME/savethese/
  if [ -e drv_clmin_restart.dat ]; then
    mv drv_clmin_restart.dat $HOME/savethese/drv_clmin.dat
  else mv drv_clmin.dat $HOME/savethese/drv_clmin.dat
  fi 
  cd ../
  rm -rf $runname
  mv savethese $runname
  cd $runname
done

# -------------------------------------------
# UNTAR ALL BACK IN GHOME
# -------------------------------------------
exit 0