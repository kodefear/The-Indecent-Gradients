#!/bin/bash
echo ${YEAR:=2017}
for month in `seq -w 1 12`; do 
   unzip $YEAR$month.zip
   mv *ONTIME.csv $YEAR$month.csv
   rm $YEAR$month.zip
done