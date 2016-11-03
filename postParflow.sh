#!/bin/bash
# 2016.01 Carolyn Voter
# postParflow.sh
# Executable to cleanup after Parflow stuff

export runname=$1
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export MHOME=/mnt/gluster/cvoter/MatlabOut/$runname

#PFB SWAP - TIME, DISK, MEM
printf "\n\n========PFB SWAP RESOURCE USAGE========\n" >> $MHOME/$runname.info.txt
startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.swapPFB.log | sed -n 's/ Job executing.*//p')
endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.swapPFB.log)
start=$(date --date="$startStr" +%s)
end=$(date --date="$endStr" +%s)
T=$((end-start))
((sec=T%60, T/=60, min=T%60, hrs=T/60))
printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $MHOME/$runname.info.txt
sed -n '/Disk (KB)/s/ \+/ /gp' $runname.swapPFB.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
sed -n '/Memory (MB)/s/ \+/ /gp' $runname.swapPFB.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt

#PFB CREATE - TIME, DISK, MEM
printf "\n\n========PFB CREATE RESOURCE USAGE========\n" >> $MHOME/$runname.info.txt
for flux in Ss Sss; do
  printf "%s\n" $flux >> $MHOME/$runname.info.txt
  startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.$flux.A.log | sed -n 's/ Job executing.*//p')
  endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.$flux.A.log)
  start=$(date --date="$startStr" +%s)
  end=$(date --date="$endStr" +%s)
  T=$((end-start))
  ((sec=T%60, T/=60, min=T%60, hrs=T/60))
  printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $MHOME/$runname.info.txt
  sed -n '/Disk (KB)/s/ \+/ /gp' $runname.$flux.A.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  sed -n '/Memory (MB)/s/ \+/ /gp' $runname.$flux.A.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  printf "\n" >> $MHOME/$runname.info.txt
done

#MAT CREATE - TIME, DISK, MEM
printf "\n\n========MAT CREATE RESOURCE USAGE========\n" >> $MHOME/$runname.info.txt
for flux in can etS evS evV infl p sat sno sr Sss Ss tr; do
  printf "%s\n" $flux >> $MHOME/$runname.info.txt
  startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.$flux.log | sed -n 's/ Job executing.*//p')
  endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.$flux.log)
  start=$(date --date="$startStr" +%s)
  end=$(date --date="$endStr" +%s)
  T=$((end-start))
  ((sec=T%60, T/=60, min=T%60, hrs=T/60))
  printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $MHOME/$runname.info.txt
  sed -n '/Disk (KB)/s/ \+/ /gp' $runname.$flux.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  sed -n '/Memory (MB)/s/ \+/ /gp' $runname.$flux.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  printf "\n" >> $MHOME/$runname.info.txt
done

#MAT CALC - TIME, DISK, MEM
printf "\n\n========MAT CALCS RESOURCE USAGE========\n" >> $MHOME/$runname.info.txt
for flux in tr3D evL SssRZ fed dd ev re; do
  printf "%s\n" $flux >> $MHOME/$runname.info.txt
  startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.$flux.log | sed -n 's/ Job executing.*//p')
  endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.$flux.log)
  start=$(date --date="$startStr" +%s)
  end=$(date --date="$endStr" +%s)
  T=$((end-start))
  ((sec=T%60, T/=60, min=T%60, hrs=T/60))
  printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $MHOME/$runname.info.txt
  sed -n '/Disk (KB)/s/ \+/ /gp' $runname.$flux.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  sed -n '/Memory (MB)/s/ \+/ /gp' $runname.$flux.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
  printf "\n" >> $MHOME/$runname.info.txt
done

#WB - TIME, DISK, MEM
printf "\n\n========WB RESOURCE USAGE========\n" >> $MHOME/$runname.info.txt
startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.WB.log | sed -n 's/ Job executing.*//p')
endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.WB.log)
start=$(date --date="$startStr" +%s)
end=$(date --date="$endStr" +%s)
T=$((end-start))
((sec=T%60, T/=60, min=T%60, hrs=T/60))
printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $MHOME/$runname.info.txt
sed -n '/Disk (KB)/s/ \+/ /gp' $runname.WB.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt
sed -n '/Memory (MB)/s/ \+/ /gp' $runname.WB.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $MHOME/$runname.info.txt

#TAR AND DELETE PARFLOWOUT DIR
cd $GHOME
cd ..
tar zcf $GHOME.02.tar.gz $runname
rm -rf $GHOME