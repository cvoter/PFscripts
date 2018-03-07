# 2018.02 Carolyn Voter
# surface_storage.tcl
# Calculates surface storage from pressure, etc. At the same time, sums total 
# domain surface storage and calculates change in storage across hourly time 
# steps.

# Usage: tclsh surface_storage.tcl
# Assumes the following variables are exported in a parent script:
# runname - name of model run
# totalHr - total number of hours in simulation
# HOME - absolute path for where calculations will take place
# domainArea - model domain surface area (m^2)

#--------------------------------------------------------
# Import the ParFlow TCL package and set source
#--------------------------------------------------------
lappend auto_path $env(PARFLOW_DIR)/bin 
package require parflow
namespace import Parflow::*

set tcl_precision 16

#---------------------------------------------------------
# Import environment variables
#---------------------------------------------------------
set runname $env(runname)
set totalHr $env(totalHr)
set HOME $env(HOME)
set domainArea $env(domainArea)

cd $HOME/surface_storage

# -----------------------------------------------------------------------------
# Set up files for domain total storage and change in storage
# -----------------------------------------------------------------------------
set filename_total [format "surface_storage_total.txt"]
set file_total [open $filename_total a]

set filename_delta [format "surface_storage_delta.txt"]
set file_delta [open $filename_delta a]

#---------------------------------------------------------
#Get geometry 
#---------------------------------------------------------
set mask             [pfload $runname.out.mask.pfb]
set top              [pfcomputetop $mask]

# -----------------------------------------------------------------------------
# Calculate initial surface storage
# -----------------------------------------------------------------------------
# Load Pressure
set filename [format "%s.out.press.00000.pfb" $runname]
set pressure [pfload $filename]

# Surface Storage - Gridded
set filename_hourly [format "%s.out.surface_storage.00000.pfb" $runname]
set storage [pfsurfacestorage $top $pressure]
pfsave $storage -pfb $filename_hourly

# Surface Storage - Total Domain
set storage_total_prev [expr 1000 * [pfsum $storage] / $domainArea]
puts $file_total [format "%.16e" $storage_total_prev]

pfdelete $storage
pfdelete $pressure

#---------------------------------------------------------
#Start Timestep loop
#---------------------------------------------------------
for {set i 1} {$i <= $totalHr} {incr i} {
    # Load Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set pressure [pfload $filename]

    # Surface Storage - Gridded
    set storage [pfsurfacestorage $top $pressure]
    pfsave $storage -pfb $filename_hourly 
    
    # Surface Storage - Total Domain
    set storage_total [expr 1000 * [pfsum $storage] / $domainArea]
    puts $file_total [format "%.16e" $storage_total]

    # Surface Storage - Change
    set storage_delta [expr $storage_total - $storage_total_prev]
    puts $file_delta [format "%.16e" $storage_delta]
    set storage_total_prev [expr $storage_total]

    pfdelete $storage
    pfdelete $pressure
}
close $file_total
close $file_delta