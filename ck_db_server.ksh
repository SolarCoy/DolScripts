#!/bin/ksh
################################################################################
#  Utility : ck_db_server.ksh
#  Modules : ck_tablesps.ksh, backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : ck_db_server.ksh
#
#  Author : Faying Dong
#  Date :  Dec. 05, 2004
#  Description: 
#     The script will loop though all the databases listed in 
#     DATABASES_ON_SERVER parameter of backup_env.ksh to check if they 
#     are up and running 
#
################################################################################
PROC_DIR=$(dirname $0)
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
export MSG_FILE="${PROC_DIR}/ck_db_server.lst"
export HOST_NAME=$(hostname)
export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov anderson.robert@dol.gov smith.bradford@dol.gov Lay.Coy@dol.gov"
export MAIL_SUBJ_TBLSPS="Database Instance Down - ${HOST_NAME}"
export DATABASES_ON_SERVER="etadb3 etadb4"

integer TOTALL_NUM=0

WARNING_HEAD="

                    Database Instance Down Alert
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     Warning Msg: Database Instance Down 

"

if [[ -f ${MSG_FILE} ]] then
    rm -f ${MSG_FILE}
fi

>${MSG_FILE}
print "$WARNING_HEAD" |tee -a ${MSG_FILE}


#Loop through all instances

for SID in ${DATABASES_ON_SERVER}
do
   typeset -i PMON_PROCS=$(ps -ef|grep -v grep|grep -cw ora_pmon_${SID})
   if [[ ${PMON_PROCS} -eq 0 ]] 2>/dev/null
   then
       print "***************************************************" >>${MSG_FILE}
       print "Database Instance ${SID} - is NOT Running !!! " >>${MSG_FILE}
       print "***************************************************" >>${MSG_FILE}
       print "">>${MSG_FILE}
       print "">>${MSG_FILE}
     let TOTALL_NUM=${TOTALL_NUM}+1
   fi

done

if [[ ${TOTALL_NUM} -ne 0 ]] then
	mail_file "${MAIL_SUBJ_TBLSPS}" "${MSG_FILE}" 
fi

exit 2
