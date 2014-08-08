#!/bin/ksh
################################################################################
#  Utility : ck_filesps.ksh
#  Modules : ck_filesys.ksh, backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : ck_filesys.ksh
#
#  Date :  Jan. 21, 2005
#  Description: The script will  
#  The script will loop though all mount points in a server, if found 
#  any filesystem is certain percentage full, a warning report will be 
#  emailed out.
#
###############################################################################
PROC_DIR=$(dirname $0)
export MAX_PCNTG=85
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
export MSG_FILE="${PROC_DIR}/filesystem_full.lst"
export HOST_NAME=$(hostname)
export MAIL_LIST="fdong@console.doleta.gov Amerman.Shane@tmo.blackberry.net"
#export MAIL_LIST="fdong@console.doleta.gov "
export MAIL_SUBJ_TBLSPS="File System Full Warning - ${HOST_NAME}"
TIME_OUT=10 #in seconds
integer CNT=0

WARNING_HEAD="

                    FILE SYSTEM FULL WARNING
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     Warning Msg: File system is $MAX_PCNTG% full

"
if [[ -f ${MSG_FILE} ]] then
    rm -f ${MSG_FILE}
fi

>${MSG_FILE}
print "$WARNING_HEAD" |tee -a ${MSG_FILE}
#`df -k &`
#sleep $TIME_OUT 
#
#PROC_ID=$$
#ps  -ef |grep "df -k" |grep -v grep |awk '{print $2}'|while read PRID
#do
#      if [[ $PRID -gt $PROC_ID ]]
#      then
#          print "System seems to be haning when executing \"df -k\" "
#          kill -9 $PRID
#          let CNT=$CNT+1
#          brek
#      fi
#done

print "  File systems that are more than ${MAX_PCNTG}% full:" |tee -a ${MSG_FILE}
print ""

df -k|awk '{print $5, $6'}|while read PCT MNTPT
do
   print "$PCT, $MNTPT"
   typeset -i PCTNUM=$(print $PCT|awk -F% '{print $1}'|grep -v capacity)
#   typeset -i NOCDROM=$(print "$MNTPT"|grep -v cdrom)
typeset -i NOM=$(print "$MNTPT"|grep -v cdrom|grep -vi mounted)
print $NOM
   if [[ ( $PCTNUM -gt $MAX_PCNTG ) && ( $NOCDROM -ne 0 ) ]] then
      print "  File system $MNTPT is $PCTNUM% full."|tee -a ${MSG_FILE}
      let CNT=$CNT+1 
   fi
done

df -k |while read ALL 
do
    let ERRS=$(print $ALL} |grep -v grep |grep -cw "error")
    if [[ ${ERRS} -ne 0 ]]
    then
      print "  File system error: $ALL."
    fi
    let CNT=$CNT+1 
done

if [[ ${CNT} -ne 0 ]] then
#        mail_file "${MAIL_SUBJ_TBLSPS}" "${MSG_FILE}"
        print "mail "
fi

exit 2
