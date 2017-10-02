#  2016.01 Carolyn Voter
#  Updated 2017.09
#  Based on getWaterBalance.tcl
#
#  Just the parts of the water balance script required for subsurface storage

#--------------------------------------------------------
# Import the ParFlow TCL package and set source
#--------------------------------------------------------
lappend auto_path $env(PARFLOW_DIR)/bin 
package require parflow
namespace import Parflow::*

#---------------------------------------------------------
# Import environment variables
#---------------------------------------------------------
set runname $env(runname)
set totalHr $env(totalHr)
set HOME $env(HOME)

cd $HOME/subsurface_storage

#---------------------------------------------------------
#Get properties and geometry
#---------------------------------------------------------
set specific_storage [pfload $runname.out.specific_storage.pfb]
set porosity         [pfload $runname.out.porosity.pfb]
set mask             [pfload $runname.out.mask.pfb]

#---------------------------------------------------------
#Start Timestep loop
#---------------------------------------------------------
for {set i 0} {$i <= $totalHr} {incr i} {
# Set pfb filenames and paths
    set filename_out [format "%s.out.subsurface_storage.%05d.pfb" $runname $i]

# Load Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set pressure [pfload $filename]

# Load Saturation
    set filename [format "%s.out.satur.%05d.pfb" $runname $i]
    set saturation [pfload $filename]

# Subsurface Storage
    set subsurface_storage [pfsubsurfacestorage $mask $porosity $pressure $saturation $specific_storage]
    pfsave $subsurface_storage -pfb $filename_out 
    
    pfdelete $subsurface_storage
    pfdelete $saturation
    pfdelete $pressure
}
