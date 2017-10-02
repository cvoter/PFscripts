#  2016.01 Carolyn Voter
#  Updated 2017.09
#  Based on getWaterBalance.tcl
#
#  Just the parts of the water balance script required for surface storage

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

cd $HOME/surface_storage

#---------------------------------------------------------
#Get geometry 
#---------------------------------------------------------
set mask             [pfload $runname.out.mask.pfb]
set top              [pfcomputetop $mask]

#---------------------------------------------------------
#Start Timestep loop
#---------------------------------------------------------
for {set i 0} {$i <= $totalHr} {incr i} {
# Set pfb filenames and paths
    set filename_out [format "%s.out.surface_storage.%05d.pfb" $runname $i]

# Load Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set pressure [pfload $filename]

# Surface Storage
    set surface_storage [pfsurfacestorage $top $pressure]
    pfsave $surface_storage -pfb $filename_out  
    
    pfdelete $surface_storage
    pfdelete $pressure
}
