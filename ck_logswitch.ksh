#!/bin/ksh
################################################################################
#  Utility : ck_logswitch.ksh
#  Modules : ck_logswitch.ksh, backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : ck_logswitch.ksh 
#
#  Author : Faying Dong
#
#  Date :  May. 05, 2010
#  Description: 
#            get log sequence number  
################################################################################
PROC_DIR=$(dirname $0)
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
export MSG_FILE="${PROC_DIR}/tblsps_full.lst"
export HOST_NAME=$(hostname)
export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov Amerman.Shane@dol.gov Lay.Coy@dol.gov smith.bradford@dol.gov"
#export MAIL_LIST="fdong@console.doleta.gov "
export SKIP_LIST=""
#export PCNTG=85
export PCNTG=${1:-85};
export CRITICAL=90

SUBJECT="TABLESPACE SIZE WARNING"
export MAIL_SUBJ_TBLSPS_WAN="DB Log Swictch - ${HOST_NAME}"

integer TOTALL_NUM=0

WARNING_HEAD="

                    DATABASE TABLESPACE SIZE WARNING 
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     Warning Msg: Get log sequence number 

"

function proc_one_db {
   DB_NAME=$1
   SQL1="
   set pagesize 31;
   set head on;
   set feedback on;
   select group#, thread#, sequence#, status from v\$log
      where status='CURRENT'
   or status='ACTIVE'
   "
   RET_VAL=""
   dba_handle "$SQL1"
   if (( $? != ${STAT_OK} ))
   then
       print "  Database query failed."
       return ${ST_FAIL}
   fi
   typeset -i RET_ROWS=0
   typeset RET_ROWS1=$(print "$RET_VAL"|grep  row|awk '{print $1}')
   if [[ ${RET_ROWS1} != "no" ]] then
       RET_ROWS=${RET_ROWS1}
   fi

   if [[ ${RET_ROWS} -ne 0 ]] then
     let TOTALL_NUM=${TOTALL_NUM}+${RET_ROWS}
     print "Tablespaces in database (${DB_NAME}) that more than $PCNTG% full."|tee -a ${MSG_FILE}
     print "$RET_VAL"|grep -v Connect |grep -v row|tee -a ${MSG_FILE}
     print ""
   fi
}

# make list of instances to operate on
set -A SIDNAME
set -A SIDHOME
integer CNT=0
BRK=$FALSE

for OSID in $(ps -ef|grep -v grep|grep ora_pmon|awk '{print $NF}'|awk -F_ '{print $3}')
do
   SIDNAME[$CNT]=$OSID
   if [[ -f $HOME/.profile_${OSID} ]] then
      . $HOME/.profile_${OSID} #to get HOME
      SIDHOME[$CNT]=${ORACLE_HOME}
      let CNT=$CNT+1
   else
      print " $HOME/.profile_${OSID} does not exists. "
   fi
done

if [[ -f ${MSG_FILE} ]] then
    rm -f ${MSG_FILE}
fi

>${MSG_FILE}
print "$WARNING_HEAD" |tee -a ${MSG_FILE}


#Loop through all instances
integer NUM=0
while [[ ${NUM} -lt ${#SIDNAME[*]} ]]
do
   SID=${SIDNAME[$NUM]}
   ORA_HOME=${SIDHOME[$NUM]}
   # Some database like standby database may not need backup
   for skip_sid in ${SKIP_LIST}
   do
     if [[ ${skip_sid} = $SID ]]
     then
        let BRK=$TRUE
        break
     fi
   done

   if [[ $BRK = $TRUE ]]
   then
      print "${SID} - in skip list -- Action Skipped." |tee -a ${MSG_FILE}
      let BRK=$FALSE
      NUM=$NUM+1
      continue
   fi
   . $HOME/.profile_${SID} # to set environment
   proc_one_db "$SID"
   let NUM=${NUM}+1
done

if [[ ${TOTALL_NUM} -ne 0 ]] then
   if [[ ${PCNTG} -ge ${CRITICAL} ]] then 
	mail_file "${MAIL_SUBJ_TBLSPS_CRT}" "${MSG_FILE}" 
   else
	mail_file "${MAIL_SUBJ_TBLSPS_WAN}" "${MSG_FILE}" 
   fi
fi

exit 2
