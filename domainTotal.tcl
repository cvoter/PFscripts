# 2018.02 Carolyn Voter
# domainTotal.tcl
# Calculates domain total flux at each time step. Also calculates change in
# storage if a storage flux.

# Usage: tclsh domainTotal.tcl
# Assumes the following variables are exported in a parent script:
# runname - name of model run
# totalHr - total number of hours in simulation
# HOME - absolute path for where calculations will take place
# domainArea - model domain surface area (m^2)
# flux - current flux to calculate

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
set flux $env(flux)
set storageCheck $env(storageCheck)
set domainArea $env(domainArea)

# -----------------------------------------------------------------------------
# Set up files for domain total storage and change in storage
# -----------------------------------------------------------------------------
set filename_total [format "%s_total.txt" $flux]
set file_total [open $filename_total a]

# If this flux is a storage term, set up file and previous total for delta storage
if {$storageCheck == 1} {
    set filename_delta [format "%s_delta.txt" $flux]
    set file_delta [open $filename_delta a]
    set flux_total_prev [expr 0.0]
}

# -----------------------------------------------------------------------------
# Loop through all hourly fluxes
# -----------------------------------------------------------------------------
for {set i 1} {$i <= $totalHr} {incr i} {
    set filename [format "%s.out.%s.%05d.pfb" $runname $flux $i]
    set flux_grid [pfload $filename]
    set flux_total [expr 1000 * [pfsum $flux_grid] / $domainArea]
    puts $file_total [format "%.16e" $flux_total]

    if {$storageCheck == 1} {
        set flux_delta [expr $flux_total - $flux_total_prev]
        puts $file_delta [format "%.16e" $flux_delta]
        set flux_total_prev [expr $flux_total]
    }

    pfdelete $flux_grid
}
close $file_total
if {$storageCheck == 1} {
    close $file_delta
}