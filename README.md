# PFscripts
Scripts for running parflow models. Common scripts are updated in 'master' branch, 'HPC' and 'HTC' branches include additional scripts required to run on UW-Madison High Performance Cluster (HPC) or the UW-Madison Center for High Throughput Computing (HTC).

Scripts are run in the following order:

1. **inputsCreateTAR.sh:** Packages individual inputs files into tarballs
2. **inputsConvertSA.sh:** Calls **inputsConvertSA.tcl** and converts **.sa** inputs into **.pfb** inputs
3. **runParflow.sh:** Calls **runParflow.tcl** as well as **logComments.sh** and **saveCurrentOutputs.sh**. Executes model run, logs comments at regular intervals, and saves outputs periodically for model resarts.
4. **outputsRearrangeTAR.sh:** Rearranges outputs saved at regular intervals during model run into one tarball per hydrologic flux (or filetype).
5. **outputs_matlab/outputsCreateMatlab.m:** Calls **pfbTOmatrix.m** and is called by **outputsCreateMatlab.sub** and **run_outputsCreateMatlab.sh** in HTC branch. Converts **.pfb** output files to **.mat** data files.
6. **outputs_matlab/outputsCalculateMatlab.m:** Calculates additional hydrologic fluxes (e.g., deep drainage, recharge, subsurface storage) from **.mat** equivalents of **.pfb** output files.
7. **outputs_matlab/outputsWaterBalanceMatlab.m:** Calculates hourly water balance for the domain and estimates model error.

HPC branch requires the following additional scripts:

1. **HPCmodelParflow.sh:** Submits job to HPC resources, wrapper script for first 4 steps.

HTC branch requires the following additional scripts:

1. **.sub:** Submit scripts for all steps
2. **outputs_matlab/build\*.sub:** Submit scripts for packaging Matlab with .m scripts on CHTC.
3. **outputs_matlab/run_\*.sh:** Run files for packaging Matlab with CHTC Matlab jobs. Include additional code added by me to manipulate *.tar.gz files on CHTC resources.
4. **DAGfiles/modelname/modelname.dag:** Template for DAGMan file that schedules steps of parflow jobs on CHTC resources.
5. **DAGfiles/setupModelSuite.sh:** Sets up **.dag** files for specific model runs based on **modelname.dag** template.
