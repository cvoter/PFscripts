#  2016.01 Carolyn Voter
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
set GHOME $env(GHOME)
set HOME $env(HOME)
set t0 $env(t0)
set tf $env(tf)

#---------------------------------------------------------
#Setup Total Flux files
#---------------------------------------------------------
file mkdir "pfb_Ss"

#---------------------------------------------------------
#Get geometry 
#---------------------------------------------------------
cd $GHOME
set mask             [pfload $runname.out.mask.pfb]
set top              [pfcomputetop $mask]
cd $HOME

#---------------------------------------------------------
#Start Timestep loop
#---------------------------------------------------------
for {set i $t0} {$i <= $tf} {incr i} {
# Set pfb filenames and paths
    set pfb_Ss [format "pfb_Ss/%s.out.Ss.%05d.pfb" $runname $i]
    cd $GHOME

# Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set p [pfload $filename]
    cd $HOME

# Surface Storage
    set Ss [pfsurfacestorage $top $p]
    pfsave $Ss -pfb $pfb_Ss  
    
    pfdelete $Ss
    pfdelete $p
}
