#!/bin/bash
# Carolyn Voter
# logComments.sh
# Standard comments to send to master log file, depending on current step of job

# Usage: sh logComments.sh logType
# Requires the following environment variables to be defined in parent script:
# runname - name of modeling run
# start
# pfStartCount
# variables set by parameters.txt


for logType in $@; do 
    if [ "$logType" = "initialize" ]; then
	    #RECORD PARAMETERS INPUTED TO PARFLOW
        printf "====PF START LOOP: %d...PF START TIME: %d====\n" $start $pfStartCount >> $runname.info.txt
        printf "%s\n" $runname >> $runname.info.txt
        date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
        printf "\nPARAMETERS\nUnits: L[=]meters, T[=]hours, M[=]kilograms\nDomain\n" >> $runname.info.txt
        printf "[xL,yL,zL] = [%.2f m, %.2f m, %.2f m]\n" $xL $yL $zL >> $runname.info.txt
        printf "[nx,ny,nz] = [%.0f, %.0f, %.0f]\n" $nx $ny $nz >> $runname.info.txt
        printf "[dx,dy,dz] = [%.2f m, %.2f m, %.2f m]\n" $dx $dy $dz >> $runname.info.txt
        printf "[xU,yU,zU] = [%.2f m, %.2f m, %.2f m]\n" $xU $yU $zU >> $runname.info.txt
        printf "[P,Q,R,np] = [%.0f, %.0f, %.0f, %.0f]\n" $P $Q $R $np >> $runname.info.txt
        printf "Soil\n" >> $runname.info.txt
        printf "[Ksat,mn] = [%.4e m/hr, %.4e h/m^-1/3] note: mn is NOT [s/m^-1/3] in parflow\n" $Ks_soil $mn_grass >> $runname.info.txt
        printf "[VGa,VGn] = [%.2f 1/m, %.2f]\n" $VGa_soil $VGn_soil >> $runname.info.txt
        printf "[porosity,Ssat,Sres] = [%.2f, %.2f, %.3f]\n"  $porosity_soil $Ssat_soil $Sres_soil >> $runname.info.txt
        printf "Impervious\n" >> $runname.info.txt
        printf "[Ksat,mn] = [%.4e m/hr, %.4e h/m^-1/3] note: mn is NOT [s/m^-1/3] in parflow\n" $Ks_imperv $mn_imperv >> $runname.info.txt
        printf "[VGa,VGn] = [%.2f 1/m, %.2f]\n" $VGa_imperv $VGn_imperv >> $runname.info.txt
        printf "[porosity,Ssat,Sres] = [%.3f, %.2f, %.3f]\n\n\n" $porosity_imperv $Ssat_imperv $Sres_imperv >> $runname.info.txt
	elif [ "$logType" = "modelDone" ]; then
	    printf "Model runs are already complete\n\n\n" >> $runname.info.txt 
	elif [ "$logType" = "loopStart" ]; then
	    printf "========PF START HOUR %d========\n" $pfStartCount >> $runname.info.txt
	elif [ "$logType" = "startIsEnd" ]; then
	    printf "\n\n=====START IS SAME AS END, ABORT=======\n\n">> $runname.info.txt
        exit 1
	elif [ "$logType" = "loopEnd" ]; then
        #RECORD CLM, PROCESSOR, ENDING INFO IN LOG
        #CLM starting step
        printf "CLM step: " >> $runname.info.txt
        sed -n '/CLM starting istep/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
		
        #CLM restart or defined start?
        printf "CLM startcode for date (1=restart, 2=defined): " >> $runname.info.txt
        sed -n '/CLM startcode/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
        printf "CLM startcode for IC (1=restart, 2=defined): " >> $runname.info.txt
        sed -n '/CLM IC/{p;q;}' CLM.out.clm.log | rev | cut -d ' ' -f1 | rev >> $runname.info.txt
		
        #CLM starting date
        sed -n '/CLM Start Time/{p;q;}' $runname.out.txt | sed -r 's/^.{1}//' >> $runname.info.txt
		
        #CHTC processor address
        head -$np $runname.out.txt >> $runname.info.txt
		
        #Ending time info
        printf "\n" >> $runname.info.txt
        date +"%H:%M:%S %Y-%m-%d" >> $runname.info.txt
        printf "PF stop hour: %d\n" $pfStartCount >> $runname.info.txt
        Tstartstring=$(sed '3q;d' $runname.info.txt)
        Tstart="$(date --date="$Tstartstring" +%s)"
        T="$(($(date +%s)-Tstart))"
        ((sec=T%60, T/=60, min=T%60, hrs=T/60))
        printf "Running total time: %d:%02d:%02d\n\n\n" $hrs $min $sec >> $runname.info.txt
    fi
done
