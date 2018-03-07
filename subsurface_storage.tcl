# 2018.02 Carolyn Voter
# subsurface_storage.tcl
# Calculates subsurface storage from pressure, saturation, etc. At the same
# time, sums total domain subsurface storage and calculates change in storage
# across hourly time steps.

# Usage: tclsh subsurface_storage.tcl
# Assumes the following variables are exported in a parent script:
# runname - name of model run
# totalHr - total number of hours in simulation
# HOME - absolute path for where calculations will take place
# domainArea - model domain surface area (m^2)

# -----------------------------------------------------------------------------
# Import the ParFlow TCL package and set source
# -----------------------------------------------------------------------------
lappend auto_path $env(PARFLOW_DIR)/bin 
package require parflow
namespace import Parflow::*

set tcl_precision 16

# -----------------------------------------------------------------------------
# Import environment variables
# -----------------------------------------------------------------------------
set runname $env(runname)
set totalHr $env(totalHr)
set HOME $env(HOME)
set domainArea $env(domainArea)

cd $HOME/subsurface_storage

# -----------------------------------------------------------------------------
# Set up files for domain total storage and change in storage
# -----------------------------------------------------------------------------
set filename_total [format "subsurface_storage_total.txt"]
set file_total [open $filename_total a]

set filename_delta [format "subsurface_storage_delta.txt"]
set file_delta [open $filename_delta a]

# -----------------------------------------------------------------------------
# Get soil hydraulic properties and geometry
# -----------------------------------------------------------------------------
set specific_storage [pfload $runname.out.specific_storage.pfb]
set porosity         [pfload $runname.out.porosity.pfb]
set mask             [pfload $runname.out.mask.pfb]

# -----------------------------------------------------------------------------
# Calculate initial subsurface storage
# -----------------------------------------------------------------------------
set i 0
# Load Pressure
set filename [format "%s.out.press.%05d.pfb" $runname $i]
set pressure [pfload $filename]

# Load Saturation
set filename [format "%s.out.satur.%05d.pfb" $runname $i]
set saturation [pfload $filename]

# Subsurface Storage - Gridded
set filename_hourly [format "%s.out.subsurface_storage.%05d.pfb" $runname $i]
set storage [pfsubsurfacestorage $mask $porosity $pressure $saturation $specific_storage]
pfsave $storage -pfb $filename_hourly

# Subsurface Storage - Total Domain
set storage_total [expr 1000 * [pfsum $storage] / $domainArea]
puts $file_total [format "%.16e" $storage_total]

pfdelete $storage
pfdelete $saturation
pfdelete $pressure

# -----------------------------------------------------------------------------
# Calculate subsurface storage for all other time steps
# -----------------------------------------------------------------------------
for {set i 1} {$i <= $totalHr} {incr i} {
    # Load Pressure
    set filename [format "%s.out.press.%05d.pfb" $runname $i]
    set pressure [pfload $filename]

    # Load Saturation
    set filename [format "%s.out.satur.%05d.pfb" $runname $i]
    set saturation [pfload $filename]

    # Subsurface Storage - Gridded
    set filename_hourly [format "%s.out.subsurface_storage.%05d.pfb" $runname $i]
    set storage [pfsubsurfacestorage $mask $porosity $pressure $saturation $specific_storage]
    pfsave $storage -pfb $filename_hourly

    # Subsurface Storage - Total Domain
    set storage_total [expr 1000 * [pfsum $storage] / $domainArea]
    puts $file_total [format "%.16e" $storage_total]

    # Subsurface Storage - Change
    set storage_delta [expr $storage_total - $storage_total_prev]
    puts $file_delta [format "%.16e" $storage_delta]
    set storage_total_prev [expr $storage_total]

    pfdelete $storage
    pfdelete $saturation
    pfdelete $pressure
}
close $file_total
close $file_delta