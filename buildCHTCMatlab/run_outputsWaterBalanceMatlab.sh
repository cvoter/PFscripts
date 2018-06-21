#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MATLAB Runtime environment for the current $ARCH and executes 
# the specified command.

# Add these lines to run_foo.sh
tar xzf r2015b.tar.gz
mkdir cache
export MCR_CACHE_ROOT=`pwd`/cache

# Rest of script follows
exe_name=$0
exe_dir=`dirname "$0"`
echo "------------------------------------------"
if [ "x$1" = "x" ]; then
  echo Usage:
  echo    $0 \<deployedMCRroot\> args
else
  echo Setting up environment variables
  MCRROOT="$1"
  echo ---
  LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
  export LD_LIBRARY_PATH;
  echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
  shift 1
  args=
  while [ $# -gt 0 ]; do
      token=$1
      args="${args} \"${token}\"" 
      shift
  done
# Unique to WBcalcs
  set -- $args
  export runname=`echo $1 | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
  GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
  cp $GHOME/MATin.tar.gz .
  tar xzf MATin.tar.gz --strip-components=1
  rm MATin.tar.gz
  cp $GHOME/*.total.step.mat .
  eval "\"${exe_dir}/outputsWaterBalanceMatlab\""
  mv WB*.mat $GHOME/
  rm $GHOME/MATin.tar.gz
  rm $GHOME/qflx_evap_grnd.*.mat
  rm $GHOME/qflx_evap_veg.*.mat
  rm $GHOME/qflx_evap_leaf.*.mat
  rm -f *.mat
fi
exit

