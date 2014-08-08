#!/bin/ksh
################################################################################
#  Utility : opa_extra.ksh
#  Modules : opa_extra.ksh  backup_env.ksh (shared), db_lib.ksh (shared)
#
#  Usage : opa_extra.ksh
#
#  Author: Faying Dong
#
#  Date :  Feb. 25, 2011
#  Description: 
#     The script will run egrants a set of sql scripts to exact data from 
#     EGRANTS schema, and produce output files for transfering them to 
#     remote OPA sftp side. 
#     report file will be time stamped and be emailed out to DBAs.  
#
################################################################################
PROC_DIR=$(dirname $0)
COMMON_BIN="/export/home/oracle/common/bin"
. ${COMMON_BIN}/backup_env.ksh
. ${COMMON_BIN}/db_lib.ksh
TIMESTAMP=`date +%b%d%H%M`
export HOST_NAME=$(hostname)
#export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov Amerman.Shane@dol.gov anderson.robert@dol.gov smith.bradford@dol.gov"
export MAIL_LIST="fdong@console.doleta.gov "
export MAIL_SUBJ="OPA Extraction Report - ${HOST_NAME}"
export SCRIPTS_LIST="scripts_list"
export ORA_ADMIN_DIR="/oraprod07/u01/app/oracle/admin/etadb3"
export OPA_SCRIPTS="${ORA_ADMIN_DIR}/opa_dir/script"
export OPA_DATA="${ORA_ADMIN_DIR}/opa_dir/data"
export OPA_LOGS="${ORA_ADMIN_DIR}/opa_dir/logs"
export MSG_FILE="${OPA_LOGS}/OPA_EXTR.${TIMESTAMP}.log"
export DAYS_KEEP_LOGS=35
export DAYS_KEEP_DATA=14


RPT_HEAD="

                    OPA DATA EXTRACTION REPORT 
**************************************************************************

     Server     : ${HOST_NAME}

     Command    : $0 $*

     Report Time: `date`

     RPT-Msg: OPA Extraction Status Report   
"

if [[ -f ${MSG_FILE} ]] then
    rm -f ${MSG_FILE}
fi

>${MSG_FILE}
print "$RPT_HEAD" |tee -a ${MSG_FILE}

function proc_one {
   FILE_NAME=$1
   FILE_NM=$(print ${FILE_NAME}|awk -F. '{print $1}')
   TIMESTAMP0=`date +%b%d%H%M`
   SQL1="
     DEFINE file_nm=$FILE_NM
     DEFINE time_stamp=$TIMESTAMP0
     DEFINE file_dir=${OPA_DATA}
     @$FILE_NAME
   "
   RET_VAL=""
   dba_handle "$SQL1"
   if (( $? != ${STAT_OK} ))
   then
       print "  Database query failed." |tee -a ${MSG_FILE}
       return ${ST_FAIL}
   fi
typeset -i rev=$(print ${RET_VAL} |grep -ic ORA-)
if [[ $rev -ne 0 ]]
then
    echo "---  Error returned from DATABASE: ----" |tee -a ${MSG_FILE}
    echo "<== $RET_VAL ==>" |tee -a ${MSG_FILE}
    return ${ST_FAIL}
fi
  print "      Extracted data file ${OPA_DATA}/$FILE_NM.$TIMESTAMP0.csv created." 
}

print "OPA Data Extraction Started at (`date '+%X %x'`)"|tee -a ${MSG_FILE}
cat ${OPA_SCRIPTS}/{SCRIPTS_LIST}|while read script_nm
do 
  START_DT="`date '+%X'`"
  proc_one $script_nm 
  print "   - $script_nm started at $START_DT, ended at `date '+%X'`"|tee -a ${MSG_FILE}
done

print "OPA Data Extraction Ended at (`date '+%X %x'`)"|tee -a ${MSG_FILE}

print "Please see log file ${MSG_FILE} for details."| tee -a ${MSG_FILE}
print "Remove log file ${DAYS_KEEP_LOGS} days older."| tee -a ${MSG_FILE}
rm_old_files ${DAYS_KEEP_LOGS} ${OPA_DATA} "*.log"
print "Remove data files ${DAYS_KEEP_DATA} days older"| tee -a ${MSG_FILE}
rm_old_files ${DAYS_KEEP_DATA} ${OPA_DATA} "*.txt"
mail_file "${MAIL_SUBJ}" "${MSG_FILE}" 

exit 2
