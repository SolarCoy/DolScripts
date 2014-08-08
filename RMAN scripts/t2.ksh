df -k|awk '{print $5, $6'}|while read PCT MNTPT
do
typeset -i PCTNUM=$(print $PCT|awk -F% '{print $1}'|grep -v capacity)
   print "$PCT, $MNTPT"
done
