#!/bin/bash
# 2016.01 Carolyn Voter
# swapPFB.sh

export runname=$1
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export MHOME=/mnt/gluster/cvoter/MatlabOut/$runname

#RENAME PFB FILES
old=can_out
new=can
rename $old $new $GHOME/*.pfb

old=evaptranssum
new=etS
rename $old $new $GHOME/*.pfb

old=qflx_evap_soi
new=evS
rename $old $new $GHOME/*.pfb

old=qflx_evap_veg
new=evV
rename $old $new $GHOME/*.pfb

old=qflx_infl
new=infl
rename $old $new $GHOME/*.pfb

old=press
new=p
rename $old $new $GHOME/*.pfb

old=satur
new=sat
rename $old $new $GHOME/*.pfb

old=swe_out
new=sno
rename $old $new $GHOME/*.pfb

old=overlandsum
new=sr
rename $old $new $GHOME/*.pfb

old=qflx_tran_veg
new=tr
rename $old $new $GHOME/*.pfb

#COPY DISK AND MEM INFO
printf "========PF RESOURCE USAGE========\n" >> $GHOME/$runname.info.txt
startStr=$(sed -n -e '0,/Job executing/{s/.*) //p}' $runname.runPF.log | sed -n 's/ Job executing.*//p')
endStr=$(sed -n -e '/Job terminated/ s/.*) //; s/ Job terminated.*//p' $runname.runPF.log)
start=$(date --date="$startStr" +%s)
end=$(date --date="$endStr" +%s)
T=$((end-start))
((sec=T%60, T/=60, min=T%60, hrs=T/60))
printf "Time : %02d:%02d:%02d\n" $hrs $min $sec >> $GHOME/$runname.info.txt
sed -n '/Disk (KB)/s/ \+/ /gp' $runname.runPF.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $GHOME/$runname.info.txt
sed -n '/Memory (MB)/s/ \+/ /gp' $runname.runPF.log | cut -d $'\t' -f2 | cut -d ' ' -f2-5 >> $GHOME/$runname.info.txt
cp $GHOME/$runname.info.txt $MHOME