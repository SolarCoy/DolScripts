#!/bin/ksh
################################################################################
#  Utility : ck_standby.ksh
#  Modules : ck_standy.ksh, backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : ck_standby.ksh
#
#  Author: Faying Dong
#
#  Date :  Dec. 05, 2005
#  Description: 
#     The script will loop though all the standby databases in a server, 
#     checking all the tablespaces, if found any tablespace is certain 
#     percentage full, a warning report will be emailed out to DBAs.  
#
################################################################################
PROC_DIR=$(dirname $0)
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
export MSG_FILE="${PROC_DIR}/standby.lst"
export HOST_NAME=$(hostname)
export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov Amerman.Shane@dol.gov Lay.Coy@dol.gov smith.bradford@dol.gov"
#export MAIL_LIST="fdong@console.doleta.gov "
export SKIP_LIST="etadb3"
export PCNTG=85
SUBJECT="STANDBY DATABASE WARNING"
export ARCHD_MDIF=3 
export APPLIED_MDIF=5 
export MAIL_SUBJ_TBLSPS="DB Standby Warning - ${HOST_NAME}"

integer TOTALL_NUM=0

WARNING_HEAD="

                    STANDBY DATABASE WARNING 
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     Warning Msg: Standby Database Warnings  
"

function proc_one_db {
   DB_NAME=$1
   SQL1="
 select dest_id||':'||destination||':'|| archived_seq#||':'||applied_seq#
 from v\$archive_dest_status where dest_id < 3 
 order by 1;
   "
   RET_VAL=""
   dba_handle "$SQL1"
   if (( $? != ${STAT_OK} ))
   then
       print "  Database query failed."
       return ${ST_FAIL}
   fi
   RET_VAL1=$(print "$RET_VAL"|grep -v Conn|grep -v ^$)
   print "${RET_VAL1}"|while read ALL
   do
         print "$ALL" |awk -F: '{print $1, $2,$3, $4}' |read DID DEST ARCHD          APPLIED 
         typeset -i  ARCHD1 ARCHD2 APPLIED1 APPLIED2 
         typeset  DEST1 DEST2 
         if [[ $DID = 1 ]] then
           DEST1=$DEST
           ARCHD1=$ARCHD 
           APPLIED1=$APPLIED
         elif [[ $DID = 2 ]] then
           DEST2=$DEST
           ARCHD2=$ARCHD 
           APPLIED2=$APPLIED
         fi	
   done
   typeset -i ARCHD_DIFF=$(($ARCHD1-$ARCHD2))
   typeset -i APPLIED_DIFF=$(($ARCHD2 - $APPLIED2))
   typeset -i CNT_IN_DB=0
   if [[ ${ARCHD_DIFF} -gt $ARCHD_MDIF ]] then
     let TOTALL_NUM=${TOTALL_NUM}+1
     let CNT_IN_DB=${CNT_IN_DB}+1
     print "Standby database of $DB_NAME shows following warnings:" 
     print "" 
     print "Achived sequence# (max) on primary site: $ARCHD1." 
     print "Achived sequence# (max) on standby site: $ARCHD2." 
     print "There seems a $ARCHD_DIFF archive logs delay, please find the detail."
   fi
   if [[ ${APPLIED_DIFF} -gt $APPLIED_MDIF ]] then
     let TOTALL_NUM=${TOTALL_NUM}+1
     if [[ ${CNT_IN_DB} -eq 0 ]] then
       print "Standby database of $DB_NAME shows following warnings:" 
     fi
     print "Achived sequence#(max) on standby site: $ARCHD2." 
     print "Applied sequence#(max) on standby site: $APPLIED2."
     print "There seems a $APPLIED_DIFF archive logs gap, please check the detail."
   fi
print "" 
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
exec 1>>${MSG_FILE} 2>&1
print "$WARNING_HEAD" 


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
      print "${SID} - in skip list -- Action Skipped." 
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
#print "mail"
fi

exit 2
