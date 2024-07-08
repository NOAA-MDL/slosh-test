#!/bin/sh

for file in `ls data/*.env`
do
  val=`bin/envutil $file -S2 | grep Max | awk -F' ' '{printf ("%d", $2)}'`
  if [ $val -gt 359 ]
  then
    root=`echo $file | cut -d'/' -f2 | cut -d'.' -f1`
    cp data/$root.trk badtrk
    echo "$file $val"
  else
    echo "skipping $file"
  fi
done
