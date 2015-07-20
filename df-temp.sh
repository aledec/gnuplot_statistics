#!/bin/bash
## Notes:
## If there's not ended due to a reboot in df file script will fault, please correct it. This is due to not and ended parameter.
## If there's nfs issue script will fault

INPUTFILEDF="df-kl.out"
STARTEDFILEDF="$0.df.out.started.tmp"
ENDEDDFFILE="$0.df.out.ended.tmp"
PRSDFFILE="$0.df.out.prs.tmp"

# Filter with a specific parameter
#FILTER="SAP"
FILTER="$1"


cat $INPUTFILEDF | grep started > $STARTEDFILEDF
cat $INPUTFILEDF | grep ended > $ENDEDDFFILE

while read line
do
#add an index to be used in bellow operations
  ((g++))
  # Do the started sed and assign to a tmp variable with a line index
  STARTED=$(sed -n $(echo $g)p $STARTEDFILEDF)
  # Do the ended sed and assign to a tmp variable
  ENDED=$(sed -n $(echo $g)p $ENDEDDFFILE)
  # Do the grep of specific lines(between each started/ended)
  sed -n "/$STARTED/,/$ENDED/p" $INPUTFILEDF | egrep -v 'started|ended|Filesystem' | egrep -v '/proc|/etc/mnttab|/dev/fd|/var/run|/tmp' > $PRSDFFILE
  # Do whatever operation you like!
  
  # Filter used column in file
  USED=$(cat $PRSDFFILE | egrep -i $FILTER | awk '{sum +=$2} END { print sum }')
  # Filter free columns in file
  FREE=$(cat $PRSDFFILE | egrep  -i $FILTER | awk '{sum +=$3} END { print sum }')
  # Print in file status at each interval
  echo "$(echo $STARTED | awk '{print $4}') $FILTER $USED $FREE"

done < $STARTEDFILEDF # only used started file, if it does not ended due to a reboot please check. Posible break if there're NFS ISSUES

# Calculate average - check options and correct
AVERAGE_2=$(cat df-kl.out.prs.tmp|egrep  -i $FILTER | awk '{sum += $2} END { print sum/NR }')
AVERAGE_3=$(cat df-kl.out.prs.tmp|egrep  -i $FILTER | awk '{sum += $3} END { print sum/NR }')
#echo "Average  $AVERAGE_2  $AVERAGE_3"
