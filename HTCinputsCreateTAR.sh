#!/bin/bash
# Carolyn Voter
# HTCinputsCreateTAR.sh
# Interprets arguments, defines environment variables for parflow setup

# Usage: HTCinputsCreateTAR.sh <runname> 

# ==============================================================================
# INTERPRET ARGUMENTS
# 1 = runname - name of modeling run
# ==============================================================================
export runname=$1

# ==============================================================================
# SET ENVIRONMENT VARIABLES
# ==============================================================================
export HOME=$(pwd)
export GHOME=/mnt/gluster/cvoter/ParflowOut/$runname
export SCRIPTS=$HOME

# ==============================================================================
# CALL EXECUTABLE SCRIPT
# ==============================================================================
sh inputsCreateTAR.sh