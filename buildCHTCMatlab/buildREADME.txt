# 2015.06 Carolyn Voter
# Last updated: 2016.05.16
# Based on instructions at: 
#    http://chtc.cs.wisc.edu/matlab-jobs.shtml

#===============================================================================
# PART 1: COMPILE CODE
#===============================================================================
# Step 1: Edit interactiveBuild.sub
#   Only need to change names of main matlab script & required function scripts
#   More info at: http://chtc.cs.wisc.edu/inter-submit.shtml

# Step 2: Get on an interactive node (will take a few min to get matched up)
#   condor_submit -i interactiveBuild.sub

# Step 3: Compile Code
#   tar -xzf foo.tar.gz (**if necessary**)
#   /usr/local/MATLAB/R2015b/bin/mcc -m -R -singleCompThread -R -nodisplay -R -nojvm outputsCalculateMatlabDZ.m
#   exit
# Returns the binary "foo" and the executable "run_foo.sh", among other files
# Should automatically include whatever scripts foo.m requires, if sent them along in Step 1

# Step 4: Modify the executable ("run_foo.sh") as follows:
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

#===============================================================================
# PART 2: SUBMIT JOB FOR EACH MODEL
#===============================================================================
# Step 1: Make job submit file
# Include these lines (note "v90" changes w/Matlab version, but MUST BE FIRST):
#   transfer_input_files = http://proxy.chtc.wisc.edu/SQUID/r2015b.tar.gz,foo,input_files
#   executable = run_foo.sh
#   arguments = v90 <any input arguments to foo>

#===============================================================================
# OTHER NOTES
#===============================================================================
# Copying the job submit files and executables is best done via putty.
# If copying is performed using a PC as an intermediary, the permissions tend to get messed up.
# If that happens, just be sure to change them to make the executable script actually executable.