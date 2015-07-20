#!/bin/bash

file=vmstatnew.out

if [ $# == 2 ] ; then
  minutes=$2
  (( seconds = minutes \* 60 ))
  cat $file | head -$seconds > /tmp/data
  file=/tmp/data
fi

gnuplot -persist <<EOF
set title "vmstat output test"
set style data fsteps
set grid
set xlabel "Date / Time"
set ylabel "CPU Utilization"
#set xrange ["01/12":"06/12"]
#set xtics "01/12", 172800, "05/12"
#set xtics (6, 12, 18, 23)
#set xtics format "%H %M %S"
#set xtics "20110105", 1209600, "20110430"
#set xtics add 6
set xdata time
set timefmt "%H:%M:%S"
set xrange ["00:00:30":"00:00:00"]
#set format x '%R'
#set terminal png size 640,480
#set yrange [ 0 : ]
#set xrange [ "1/6/93":"1/11/93" ]
#set ylabel "Concentration\nmg/l"
#set grid
#set key left
plot "$file" using 1:2 with lines lw 1 lt 3 title "%user", \
"$file" using 1:3 with lines lw 1 lt 7 title "%sys"
EOF
