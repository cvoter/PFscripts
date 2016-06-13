#  2016.01 Carolyn Voter
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
set GHOME $env(GHOME)
set HOME $env(HOME)
set t0 $env(t0)
set tf $env(tf)

#---------------------------------------------------------
#Setup Total Flux files
#---------------------------------------------------------
file mkdir "pfb_Sss"

#---------------------------------------------------------
#Get properties and geometry
#---------------------------------------------------------
cd $GHOME
set specific_storage [pfload $runname.out.specific_storage.pfb]
set porosity         [pfload $runname.out.porosity.pfb]
set mask             [pfload $runname.out.mask.pfb]
cd $HOME

#---------------------------------------------------------
#Start Timestep loop
#---------------------------------------------------------
for {set i $t0} {$i <= $tf} {incr i} {
# Set pfb filenames and paths
    set pfb_Sss [format "pfb_Sss/%s.out.Sss.%05d.pfb" $runname $i]
    cd $GHOME

# Load Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set pressure [pfload $filename]

# Saturation
    set filename [format "%s.out.satur.%05d.pfb" $runname $i]
    set sat [pfload $filename]
    cd $HOME

# Subsurface Storage
    set Sss [pfsubsurfacestorage $mask $porosity $pressure $sat $specific_storage]
    pfsave $Sss -pfb $pfb_Sss 
    
    pfdelete $Sss
    pfdelete $sat
    pfdelete $pressure
}
