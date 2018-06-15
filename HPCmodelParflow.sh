#!/bin/bash
# Carolyn Voter
# HPCmodelParflow.sh
# Establishes HPC environment variables before calling runParflow executable.

# Usage: sbatch HPCmodelParflow.sh runname totalHr drun np

# ==============================================================================
# SLURM REQUESTS
# ==============================================================================
#SBATCH --partition=loheide3
#SBATCH --time=7-00:00:00
#SBATCH --ntasks=20
#SBATCH --nodes=1
#SBATCH --error=/home/cvoter/Jobs/%J.err
#SBATCH --output=/home/cvoter/Jobs/%J.out

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname
# 2 = totalHr = total number of model hours for complete simulation
# 3 = drun = number of model hours per loop
# nruns = number of loops to execute, based on total hours and hours per loop
# ==============================================================================
export runname=$1
export totalHr=$2
export drun=$3
export np=$4
export nruns=$(((totalHr+drun-1)/drun))

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# Paths for required libraries and relevant directories
# ==============================================================================
module load mpi/gcc/mpich-3.1
export BASE=/home/cvoter/ParFlow
export PARFLOW_DIR=$BASE/parflow
export TCL_PATH=$BASE/tcl-8.6.8
export LD_LIBRARY_PATH=$TCL_PATH/lib:$LD_LIBRARY_PATH
export HOME=/scratch/local/cvoter
export GHOME=/home/cvoter/PFoutputs/$runname
export SCRIPTS=/home/cvoter/PFscripts

# ==============================================================================
# 1. TAR INPUT FILES
# ==============================================================================
date +"%H:%M:%S %Y-%m-%d"
printf "Tarring input files....\n"
sh $SCRIPTS/inputsCreateTAR.sh

# ==============================================================================
# 2. CONVERT SA INPUTS TO PFB INPUTS
# ==============================================================================
printf "\n\n"
date +"%H:%M:%S %Y-%m-%d"
printf "Converting *.sa input files....\n"
sh $SCRIPTS/inputsConvertSA.sh

# ==============================================================================
# 3. RUN PARFLOW MODEL
# ==============================================================================
export HOME=/home/cvoter/PFworking/working.$runname
mkdir $HOME

printf "\n\n"
date +"%H:%M:%S %Y-%m-%d"
printf "Running parflow model files....\n"
sh $SCRIPTS/runParflow.sh

rm -rf $HOME
export HOME=/scratch/local/cvoter

# ==============================================================================
# 4. REARRANGE OUTPUTS
# ==============================================================================
printf "\n\n"
date +"%H:%M:%S %Y-%m-%d"
printf "Rearranging output files....\n"
sh $SCRIPTS/outputsRearrangeTAR.sh

# ==============================================================================
# 5. DONE
# ==============================================================================
printf "\n\n"
date +"%H:%M:%S %Y-%m-%d"
printf "All done!"