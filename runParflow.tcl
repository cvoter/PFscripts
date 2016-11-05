#  2016.06 Carolyn Voter
#  runParflow.tcl
#  Modified from HPC version for HTC

#  length units in meters
#  time units in hrs
#  mass units in kg

#  Headers indicate section where detailed input info may be found in 2014 PF User Manual

#------------------------------------------------------------------------------------------
# Import the ParFlow TCL package
#------------------------------------------------------------------------------------------
lappend auto_path $env(PARFLOW_DIR)/bin
package require parflow
namespace import Parflow::*

#------------------------------------------------------------------------------------------
# Set file version (6.1.1)
#------------------------------------------------------------------------------------------
pfset FileVersion 4

#------------------------------------------------------------------------------------------
# Import environment variables to set model parameters
#------------------------------------------------------------------------------------------
set HOME		[pwd]
set runname		$env(runname)
set pfStartCount	$env(pfStartCount)
set pfStopTime	$env(pfStopTime)
set ICpressure	$env(ICpressure)

set xL $env(xL)
set yL $env(yL)
set zL $env(zL)

set nx $env(nx)
set ny $env(ny)
set nz $env(nz)

set dx $env(dx)
set dy $env(dy)
set dz $env(dz)

set xU $env(xU)
set yU $env(yU)
set zU $env(zU)

set ptP $env(P)
set ptQ $env(Q)
set ptR $env(R)
set np $env(np)

set Ks_soil $env(Ks_soil)
set mn_grass $env(mn_grass)
set VGa_soil $env(VGa_soil)
set VGn_soil $env(VGn_soil)
set porosity_soil $env(porosity_soil)
set Ssat_soil $env(Ssat_soil)
set Sres_soil $env(Sres_soil)

set Ks_imperv $env(Ks_imperv)
set mn_imperv $env(mn_imperv)
set VGa_imperv $env(VGa_imperv)
set VGn_imperv $env(VGn_imperv)
set porosity_imperv $env(porosity_imperv)
set Ssat_imperv $env(Ssat_imperv)
set Sres_imperv $env(Sres_imperv)

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
pfset ComputationalGrid.NZ					$nz

#------------------------------------------------------------------------------------------
# Geometry: Geometry Input (6.1.4)
#------------------------------------------------------------------------------------------
pfset GeomInput.Names					"domain_input indicator_input"

pfset GeomInput.domain_input.InputType			Box
pfset GeomInput.domain_input.GeomName			domain

pfset GeomInput.indicator_input.InputType			IndicatorField
pfset GeomInput.indicator_input.GeomNames			"pervious impervious"
pfset Geom.indicator_input.FileName			"subsurfaceFeature.pfb"
pfset GeomInput.pervious.Value				1
pfset GeomInput.impervious.Value				2

pfdist subsurfaceFeature.pfb
#------------------------------------------------------------------------------------------
# Geometry: Geometry (6.1.4)
#------------------------------------------------------------------------------------------
pfset Geom.domain.Lower.X					$xL
pfset Geom.domain.Lower.Y					$yL
pfset Geom.domain.Lower.Z					$zL

pfset Geom.domain.Upper.X					$xU
pfset Geom.domain.Upper.Y					$yU
pfset Geom.domain.Upper.Z					$zU

pfset Geom.domain.Patches 					"left right front back bottom top"

#------------------------------------------------------------------------------------------
# Geometry: Domain (6.1.7)
#------------------------------------------------------------------------------------------
pfset Domain.GeomName					domain

#------------------------------------------------------------------------------------------
# Basics: Water and Gravity (6.1.8 and 6.1.9)
# by setting these to unity, pressure is in terms of pressure head [L]
# and intrinsic permeability is equivalent to hydraulic conductivity [L/T]
#------------------------------------------------------------------------------------------
pfset Phase.Names						"water"

pfset Phase.water.Density.Type				Constant
pfset Phase.water.Density.Value				1.0

pfset Phase.water.Viscosity.Type				Constant
pfset Phase.water.Viscosity.Value				1.0

pfset Gravity							1.0

#------------------------------------------------------------------------------------------
# Geology: Specific Storage (6.1.13)
# only choice available (2014) is Constant
#------------------------------------------------------------------------------------------
pfset SpecificStorage.GeomNames				"domain"
pfset SpecificStorage.Type					Constant
pfset Geom.domain.SpecificStorage.Value			1.0e-4

#------------------------------------------------------------------------------------------
# Geology: Permeability (6.1.11)
#------------------------------------------------------------------------------------------
pfset Geom.Perm.Names					"pervious impervious"

pfset Geom.pervious.Perm.Type				Constant
pfset Geom.pervious.Perm.Value				$Ks_soil

pfset Geom.impervious.Perm.Type				Constant
pfset Geom.impervious.Perm.Value				$Ks_imperv

pfset Perm.TensorType					TensorByGeom
pfset Geom.Perm.TensorByGeom.Names				"domain"
pfset Geom.domain.Perm.TensorValX				1.0
pfset Geom.domain.Perm.TensorValY				1.0
pfset Geom.domain.Perm.TensorValZ				1.0

#------------------------------------------------------------------------------------------
# Geology: Porosity (6.1.12)
#------------------------------------------------------------------------------------------
pfset Geom.Porosity.GeomNames				"pervious impervious"

pfset Geom.pervious.Porosity.Type				Constant
pfset Geom.pervious.Porosity.Value				$porosity_soil

pfset Geom.impervious.Porosity.Type			Constant
pfset Geom.impervious.Porosity.Value			$porosity_imperv

#------------------------------------------------------------------------------------------
# Richards: Relative Permeability (6.1.19)
#------------------------------------------------------------------------------------------
pfset Phase.RelPerm.Type					VanGenuchten
pfset Phase.RelPerm.GeomNames				"pervious impervious"

pfset Geom.pervious.RelPerm.Alpha				$VGa_soil
pfset Geom.pervious.RelPerm.N				$VGn_soil

pfset Geom.impervious.RelPerm.Alpha			$VGa_imperv
pfset Geom.impervious.RelPerm.N				$VGn_imperv

#------------------------------------------------------------------------------------------
# Richards: Saturation (6.1.22)
#------------------------------------------------------------------------------------------
pfset Phase.Saturation.Type					VanGenuchten
pfset Phase.Saturation.GeomNames				"pervious impervious"

pfset Geom.pervious.Saturation.Alpha			$VGa_soil
pfset Geom.pervious.Saturation.N				$VGn_soil
pfset Geom.pervious.Saturation.SRes			$Sres_soil
pfset Geom.pervious.Saturation.SSat			$Ssat_soil

pfset Geom.impervious.Saturation.Alpha			$VGa_imperv
pfset Geom.impervious.Saturation.N				$VGn_imperv
pfset Geom.impervious.Saturation.SRes			$Sres_imperv
pfset Geom.impervious.Saturation.SSat			$Ssat_imperv

#------------------------------------------------------------------------------------------
# Surface: Topo slopes in x- and y-directions (6.1.16)
#------------------------------------------------------------------------------------------
pfset TopoSlopesX.GeomNames					"domain"
pfset TopoSlopesX.Type					PFBFile
pfset TopoSlopesX.FileName					slopex.pfb

pfset TopoSlopesY.GeomNames					"domain"
pfset TopoSlopesY.Type					PFBFile
pfset TopoSlopesY.FileName					slopey.pfb

pfset ComputationalGrid.NZ					1
pfdist slopex.pfb
pfdist slopey.pfb
pfset ComputationalGrid.NZ					$nz

#------------------------------------------------------------------------------------------
# Surface: Mannings coefficient (6.1.15)
#------------------------------------------------------------------------------------------
pfset Mannings.GeomNames					"pervious impervious"
pfset Mannings.Type						Constant

pfset Mannings.Geom.pervious.Value				$mn_grass
pfset Mannings.Geom.impervious.Value			$mn_imperv

#------------------------------------------------------------------------------------------
# Other: necessary, but unused by me (6.1.8, 6.1.17, and 6.1.30)
#------------------------------------------------------------------------------------------
pfset Contaminants.Names					""
pfset Geom.Retardation.GeomNames				""
pfset Wells.Names						""

#------------------------------------------------------------------------------------------
# Timing Information (6.1.5)
#------------------------------------------------------------------------------------------
pfset TimingInfo.BaseUnit					1
pfset TimingInfo.StartCount					$pfStartCount
pfset TimingInfo.StartTime					0
pfset TimingInfo.StopTime					$pfStopTime
pfset TimingInfo.DumpInterval				1
pfset TimeStep.Type						Constant
pfset TimeStep.Value						1

set CLMstart [expr $pfStartCount + 1 ]

#------------------------------------------------------------------------------------------
# Time Cycles (6.1.6)
#------------------------------------------------------------------------------------------
pfset Cycle.Names						"constant"
pfset Cycle.constant.Names					"alltime"
pfset Cycle.constant.alltime.Length			1
pfset Cycle.constant.Repeat					-1

#------------------------------------------------------------------------------------------
# Initial Conditions: Pressure (6.1.27)
#------------------------------------------------------------------------------------------
pfset ICPressure.Type					PFBFile
pfset ICPressure.GeomNames					domain
pfset Geom.domain.ICPressure.FileName			$ICpressure

pfdist $ICpressure

#------------------------------------------------------------------------------------------
# Boundary Conditions: Pressure (6.1.24)
#------------------------------------------------------------------------------------------
pfset BCPressure.PatchNames					"left right front back bottom top"

pfset Patch.left.BCPressure.Type				FluxConst
pfset Patch.left.BCPressure.Cycle				constant
pfset Patch.left.BCPressure.alltime.Value			0.0

pfset Patch.right.BCPressure.Type				FluxConst
pfset Patch.right.BCPressure.Cycle				constant
pfset Patch.right.BCPressure.alltime.Value		0.0

pfset Patch.front.BCPressure.Type				FluxConst
pfset Patch.front.BCPressure.Cycle				constant
pfset Patch.front.BCPressure.alltime.Value		0.0

pfset Patch.back.BCPressure.Type				FluxConst
pfset Patch.back.BCPressure.Cycle				constant
pfset Patch.back.BCPressure.alltime.Value			0.0

pfset Patch.bottom.BCPressure.Type				DirEquilRefPatch
pfset Patch.bottom.BCPressure.Cycle			constant
pfset Patch.bottom.BCPressure.RefGeom			domain
pfset Patch.bottom.BCPressure.RefPatch			bottom
pfset Patch.bottom.BCPressure.alltime.Value		0.0

pfset Patch.top.BCPressure.Type				OverlandFlow
pfset Patch.top.BCPressure.Cycle				constant
pfset Patch.top.BCPressure.alltime.Value			0.0

#------------------------------------------------------------------------------------------
# Boundary Conditions: Sources (6.1.20)
#------------------------------------------------------------------------------------------
pfset PhaseSources.water.Type				Constant
pfset PhaseSources.water.GeomNames				domain
pfset PhaseSources.water.Geom.domain.Value		0.0

#------------------------------------------------------------------------------------------
# Exact solution specification for error calculations (6.1.29)
#------------------------------------------------------------------------------------------
pfset KnownSolution						NoKnownSolution

#------------------------------------------------------------------------------------------
# Set solver parameters (6.1.31, 6.1.32, 6.1.33, and 6.1.35)
#------------------------------------------------------------------------------------------
pfset Solver							Richards
pfset Solver.MaxIter						20000000
pfset Solver.MaxConvergenceFailures			20
pfset Solver.Drop						1E-20
pfset Solver.AbsTol						1E-12

pfset Solver.Nonlinear.MaxIter				200
pfset Solver.Nonlinear.ResidualTol				1E-7
pfset Solver.Nonlinear.Globalization			LineSearch
pfset Solver.Nonlinear.StepTol				1E-30

pfset Solver.Linear.KrylovDimension			200
pfset Solver.Linear.MaxRestart				2
pfset Solver.Nonlinear.UseJacobian				True
pfset Solver.Linear.Preconditioner				PFMG
#pfset Solver.Linear.Preconditioner.SymmetricMat		Nonsymmetric
#pfset Solver.Linear.Preconditioner.PCMatrixType		FullJacobian

# $CLMstart is defined in TimingInfo section
pfset Solver.LSM						CLM
pfset Solver.CLM.ReuseCount					1
pfset Solver.CLM.DailyRST					False
pfset Solver.CLM.MetForcing					1D
pfset Solver.CLM.MetFileName				nldas.1hr.clm.txt
pfset Solver.CLM.MetFilePath				"$HOME"
pfset Solver.CLM.CLMFileDir					"$HOME"
pfset Solver.CLM.IstepStart					$CLMstart
pfset Solver.CLM.CLMDumpInterval				1
pfset Solver.CLM.ResSat					$Sres_soil
pfset Solver.CLM.VegWaterStress				Pressure
pfset Solver.CLM.WiltingPoint				-80
pfset Solver.CLM.FieldCapacity				-3.3

for {set i 0} { $i <= ( $np - 1 ) } {incr i} {
	file delete drv_clmin.dat.$i
	file copy drv_clmin.dat drv_clmin.dat.$i
}

#------------------------------------------------------------------------------------------
# Set which files get printed (6.1.31 and 6.1.35)
#------------------------------------------------------------------------------------------
# TRUE for *.silo output
pfset Solver.WriteSiloMask					False
pfset Solver.WriteSiloPressure				False
pfset Solver.WriteSiloSaturation				False
pfset Solver.WriteSiloSubsurfData				False
pfset Solver.WriteSiloSlopes				False
pfset Solver.WriteSiloMannings				False
pfset Solver.WriteSiloOverlandSum				False
pfset Solver.WriteSiloEvapTransSum				False
pfset Solver.WriteSiloCLM					False
#pfset SILO.Filetype						HDF5
#pfset SILO.CompressionOptions				"METHOD=GZIP"

# TRUE for *.pfb output
pfset Solver.PrintMask					True
pfset Solver.PrintPressure					True
pfset Solver.PrintSaturation				True
pfset Solver.PrintSubsurf					True
pfset Solver.PrintSlopes					True
pfset Solver.PrintMannings					True
pfset Solver.PrintOverlandSum				True
pfset Solver.PrintEvapTransSum				True
pfset Solver.PrintCLM					True

# FALSE Always
pfset Solver.BinaryOutDir					False
pfset Solver.WriteCLMBinary					False
pfset Solver.CLM.Print1dOut					False
pfset Solver.WriteSiloEvapTrans				False
pfset Solver.WriteSiloOverlandBCFlux			False
pfset Solver.WriteSiloVelocities				False
pfset Solver.PrintConcentration				False
pfset Solver.PrintVelocities				False
pfset Solver.PrintWells					False
#------------------------------------------------------------------------------------------
# Run and Unload the ParFlow output files
#------------------------------------------------------------------------------------------
puts [format "About to start run..."]
pfrun $runname
puts [format "Ok! Undistributing now..."]
pfundist $runname
