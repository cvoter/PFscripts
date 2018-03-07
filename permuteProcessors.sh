#!/bin/bash
# Carolyn Voter
# February 2018
# Copies template input directory, then permutes the number of processors

basename=site2
topDir=/home/cvoter/PFoutputs

copyReplaceProcessors () {
    runname=$(printf "%s_%02dx%02d" $basename $P $Q)
    cp -r $topDir/$basename $topDir/$runname
    sed -i "13s/.*/${P}/" $topDir/$runname/parameters.txt
    sed -i "14s/.*/${Q}/" $topDir/$runname/parameters.txt
}

printStartCommand () {
    np=$((P*Q))
    command=$(printf "sbatch HPCmodelParflow%s.sh %s 12 12 %s" $np $runname $np)
    echo $command >> allStartCommands.txt
}

Q=4
for P in 20 21; do
    copyReplaceProcessors
    printStartCommand
done

Q=6
for P in 12 14 15 20 21; do
    copyReplaceProcessors 
    printStartCommand
done

Q=8
for P in 10 12 14 15 20 21; do
    copyReplaceProcessors 
    printStartCommand
done

Q=9
for P in 7 10 12 14 15 20 21; do
    copyReplaceProcessors 
    printStartCommand
done

Q=12
for P in 6 7 10 12 14 15; do
    copyReplaceProcessors 
    printStartCommand
done

Q=12
for P in 6 7 10 12 14 15; do
    copyReplaceProcessors 
    printStartCommand
done