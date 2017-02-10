#!/bin/bash
# 2016.01 Carolyn Voter
# swapPFB.sh

export runname=$1
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export MHOME=/mnt/gluster/cvoter/MatlabOut/$runname

cd $GHOME
for ((loop=1;loop<=730;loop++)); do
  prettyloop=$(printf "%04d" $loop)
  dirname=$(printf "%s_%s" $runname $prettyloop)
  tar xzf $dirname.tar.gz --strip-components=1
  rm -f $dirname.tar.gz
done

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
cp $GHOME/$runname.info.txt $MHOME