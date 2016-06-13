#!/bin/bash
# 2016.01 Carolyn Voter
# runParflow.sh
# Executable to set up environmental variables and run ParFlow *.tcl script

export runname=$1
export totalHr=$2

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
export MPI_PATH=/mnt/gluster/chtc/mpich-3.1
export LD_LIBRARY_PATH=$MPI_PATH/lib:$LD_LIBRARY_PATH
export PATH=$MPI_PATH/bin:$PATH
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname

if [ ! -e $GHOME/runParflow.tcl ]; then
  cp $HOME/runParflow.tcl $GHOME/runParflow.tcl
fi
cd $GHOME

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
# SETUP FOR RESTART OR FIRST START
# -------------------------------------------
firstPress=$(printf "%s.out.press.00001.pfb" "$runname")
if [ -e $firstPress ]; then
  ###### RESTART ######
  if [ -e drv_clmin_restart.dat ]; then
    # FIRST RESTART
    mv -f drv_clmin_restart.dat drv_clmin.dat
  fi
  # EXPORT PRESSURE AND TIMING
  export ICpressure=$(find . -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
  export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')
  export pfStopTime=$((totalHr-pfStartCount))
  # DELETE EXTRA CLM RESTARTS AND DIST PFBS
  for ((i=1;i<pfStartCount;i++)); do
    num=$(printf "%05d" $i)
    find . -name "gp.rst.$num.*" -delete
    find . -name "$runname.out.*.$num.pfb.dist" -delete
  done
  # SAVE PREVIOUS KINSOL LOG
  cat $runname.out.kinsol.log >> $runname.kinsol.log
  printf "\n============================PF START HOUR: %d============================\n" $pfStartCount >> $runname.kinsol.log
  # SAVE CLM AND PROCESSOR INFO
  printf "\nCLM step: " >> $runname.info.txt
  sed -n '/clm.F90/{p;q;}' clm_output.txt.0 | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
  sed -n '/CLM Start Time/{p;q;}' $runname.out.txt | sed -r 's/^.{1}//' >> $runname.info.txt
  head -$np $runname.out.txt >> $runname.info.txt
  # PREPARE FOR NEXT LOOP
  printf "\n========PF START HOUR %d========\n" $pfStartCount >> $runname.info.txt
  date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
else
  ###### FIRST START ######
  export pfStartCount=0
  export pfStopTime=$totalHr
  export ICpressure="ICpressure.pfb"
  # CREATE KINSOL LOG FILE
  printf "============================PF START HOUR: 0============================\n" > $runname.kinsol.log
  # CREATE INFO FILE
  printf "%s\n" $runname > $runname.info.txt
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
  printf "[porosity,Ssat,Sres] = [%.3f, %.2f, %.3f]\n\n" $porosity_imperv $Ssat_imperv $Sres_imperv >> $runname.info.txt
  printf "========PF START HOUR 0========\n" >> $runname.info.txt
  date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt 
fi

# -------------------------------------------
# DO PARFLOW STUFF
# -------------------------------------------
tclsh runParflow.tcl

# -------------------------------------------
# CLEAN UP
# -------------------------------------------
# FINAL PRESSURE AND TIMING
export ICpressure=$(find . -name "$runname.out.press.*.pfb" | sort -n | tail -1 | sed -r 's/^.{2}//')
export pfStartCount=$(echo $ICpressure | tail -c 10 | sed 's/.\{4\}$//' | sed 's/^0*//')

# DELETE EXTRA CLM RESTARTS AND DIST PFBS
for ((i=1;i<=pfStartCount;i++)); do
  num=$(printf "%05d" $i)
  find . -name "gp.rst.$num.*" -delete
  find . -name "$runname.out.*.$num.pfb.dist" -delete
done

# SAVE LAST KINSOL LOG
cat $runname.out.kinsol.log >> $runname.kinsol.log
printf "\n============================PF STOP HOUR: %d============================\n" $pfStartCount >> $runname.kinsol.log
##SAVE LAST CLM AND PROCESSOR INFO
printf "\nCLM step: " >> $runname.info.txt
sed -n '/clm.F90/{p;q;}' clm_output.txt.0 | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
sed -n '/CLM Start Time/{p;q;}' $runname.out.txt | sed -r 's/^.{1}//' >> $runname.info.txt
head -$np $runname.out.txt >> $runname.info.txt

# SAVE LAST TIMING INFO
printf "\n========PF STOP HOUR %d========\n" $pfStartCount >> $runname.info.txt
date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
Tstartstring=$(sed '2q;d' $runname.info.txt)
Tstart="$(date --date="$Tstartstring" +%s)"
T="$(($(date +%s)-Tstart))"
((sec=T%60, T/=60, min=T%60, hrs=T/60))
printf "Total time: %d:%02d:%02d\n" $hrs $min $sec >> $runname.info.txt