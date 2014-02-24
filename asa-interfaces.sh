#!/bin/bash


# divide all the collected file into single interfaces
###################################

## 1

for i in *.txt; do
  d="${i}.d"
  rm -rf "$d"
  mkdir $d
  cp $i $d/
  cd $d
  chmod a+rw $i

  csplit.exe -k $i '%2014%' '/./' '%Interface%' '/Interface GigabitEthernet/' '{*}'
  csplit.exe -b aa%02d -k xx04 '/Interface Management/' '{*}'
  cd ..
done

## 2

# analyze the data and generate stats based on a single line from
# the interface
######################################################################

for k in xx01  xx02 xx03 xxaa00  xxaa01  xx05  xx06  xx07; do
  head -1 1.txt.d/$k ;

  for i in *.d; do
     grep overrun $i/$k | tr -d '\n'
     echo -n ' '
     cat $i/xx00
  done;

done

for k in xx01  xx02 xx03 xxaa00  xxaa01  xx05  xx06  xx07; do
  head -1 1.txt.d/$k ;

  for i in *.d; do
     grep underruns $i/$k | tr -d '\n'
     echo -n ' '
     cat $i/xx00
  done;

done

