# 2016.01 Carolyn Voter
# preParflow.tcl
# Converts *.sa input files to *.pfb

#------------------------------------------------------------------------------------------
# Basic Parflow setup
#------------------------------------------------------------------------------------------
lappend auto_path $env(PARFLOW_DIR)/bin
package require parflow
namespace import Parflow::*
pfset FileVersion 4

set runname $env(runname)
#------------------------------------------------------------------------------------------
# Convert to pfb
#------------------------------------------------------------------------------------------
set subsurfaceFeature [pfload subsurfaceFeature.sa]
pfsave $subsurfaceFeature -pfb subsurfaceFeature.pfb

set dem [pfload -sa dem.sa]
pfsetgrid {420 216 1} {0 0 0} {0.5 0.5 1} $dem

set slopex [pfslopex $dem]
pfsave $slopex -pfb slopex.pfb
set slopey [pfslopey $dem]
pfsave $slopey -pfb slopey.pfb

set ICpressure [pfload ICpressure.sa]
pfsave $ICpressure -pfb $runname.out.press.00000.pfb