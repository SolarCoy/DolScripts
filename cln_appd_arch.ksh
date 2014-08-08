#!/bin/ksh
################################################################################
#  Utility : ck_tablesps.ksh
#  Modules : ck_tablesps.ksh, backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : ck_tablesps.ksh
#
#  Date :  Dec. 05, 2005
#
#  Author : Faying Dong
#
#  Description: 
#     The script will loop though all the databases in a server, 
#     checking all the tablespaces, if found any tablespace is certain 
#     percentage full, a warning report will be emailed out to DBAs.  
#
################################################################################
PROC_DIR=$(dirname $0)
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
export MSG_FILE="${PROC_DIR}/tblsps_full.lst"
export HOST_NAME=$(hostname)
export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov Amerman.Shane@dol.gov anderson.robert@dol.gov smith.bradford@dol.gov"
#export MAIL_LIST="fdong@console.doleta.gov "
export SKIP_LIST=""
export PCNTG=85
SUBJECT="TABLESPACE SIZE WARNING"
export MAIL_SUBJ_TBLSPS="DB Tablespace Warning - ${HOST_NAME}"

integer TOTALL_NUM=0

WARNING_HEAD="

                    DATABASE TABLESPACE SIZE WARNING 
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     Warning Msg: Tablespaces more than $PCNTG% full

"

function proc_one_db {
   DB_NAME=$1
   SQL1="
   set pagesize 31;
   set head on;
   set feedback on;
   select a.tablespace_name TABLESPACE,
   round((a.bytes / 1024),0) K_AVAIL,
   round((b.bytes / 1024),0) K_USED,
   round(((b.bytes / a.bytes) * 100),0) PCT_USED,
   round((c.bytes / 1024),0) K_FREE
   from sys.sm\$ts_avail a, sys.sm\$ts_used b, sys.sm\$ts_free c
   where a.tablespace_name = b.tablespace_name
   and b.tablespace_name = c.tablespace_name
   and a.tablespace_name = c.tablespace_name
   and (b.bytes / a.bytes) * 100 >$PCNTG 
   order by a.tablespace_name ;
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
	mail_file "${MAIL_SUBJ_TBLSPS}" "${MSG_FILE}" 
       # print "mail "
fi

exit 2
