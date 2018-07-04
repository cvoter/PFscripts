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
set nruns $env(PFnruns)
set convertNLDAS $env(convertNLDAS)
set xL $env(xL)
set yL $env(yL)
set zL $env(zL)

set nx $env(nx)
set ny $env(ny)
set nz $env(nz)

set dx $env(dx)
set dy $env(dy)
set dz $env(dz)

set ptP $env(P)
set ptQ $env(Q)
set ptR $env(R)

#------------------------------------------------------------------------------------------
# Processor topology (6.1.2)
#------------------------------------------------------------------------------------------
pfset Process.Topology.P 					$ptP
pfset Process.Topology.Q 					$ptQ
pfset Process.Topology.R 					$ptR

#------------------------------------------------------------------------------------------
# Computational Grid (6.1.3)
#------------------------------------------------------------------------------------------
pfset ComputationalGrid.Lower.X				$xL
pfset ComputationalGrid.Lower.Y				$yL
pfset ComputationalGrid.Lower.Z				$zL

pfset ComputationalGrid.DX					$dx
pfset ComputationalGrid.DY					$dy
pfset ComputationalGrid.DZ					$dz

pfset ComputationalGrid.NX					$nx
pfset ComputationalGrid.NY					$ny
pfset ComputationalGrid.NZ					12

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
pfsave $ICpressure -pfb $runname.out.press.00000.pfb

set dz_mult [pfload dz_mult.sa]
pfsave $dz_mult -pfb dz_mult.pfb

#------------------------------------------------------------------------------------------
# Distribute NLDAS files
#------------------------------------------------------------------------------------------
if {$convertNLDAS == 1} {
    set name NLDAS
    set var [list "DLWR" "DSWR" "APCP" "Temp" "UGRD" "VGRD" "Press" "SPFH"]
    for {set i 0} {$i <= $nruns} {incr i} {
        foreach v $var {
            set t1 [expr $i * 12 + 1]
            set t2 [ expr $t1 + 11]
            set filename_sa [format "NLDAS/NLDAS.%s.%06d_to_%06d.sa" $v $t1 $t2]
            puts $filename_sa
            set NLDASdata [pfload $filename_sa]
            set filename_pfb [format "NLDAS/NLDAS.%s.%06d_to_%06d.pfb" $v $t1 $t2]
            pfsave $NLDASdata -pfb $filename_pfb
            pfdist $filename_pfb
        }
    }
}