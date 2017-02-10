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

#------------------------------------------------------------------------------------------
# Convert to pfb
#------------------------------------------------------------------------------------------
set subsurfaceFeature [pfload subsurfaceFeature.sa]
pfsave $subsurfaceFeature -pfb subsurfaceFeature.pfb

set slopex [pfload slopex.sa]
pfsave $slopex -pfb slopex.pfb
set slopey [pfload slopey.sa]
pfsave $slopey -pfb slopey.pfb

set ICpressure [pfload ICpressure.sa]
pfsave $ICpressure -pfb $env(runname).out.press.00000.pfb