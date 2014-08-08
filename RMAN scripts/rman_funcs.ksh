(etadb5)prodora05:/usr/oracle/common/bin> cat rman_funcs.ksh
#!/bin/ksh

function do_rman_sid {
   SID=$1; export SID

   typeset SID_LOG_FILE=${SID_LOG_DIR}/${SID_RMAN_LOG_FILE}
   print "${SID}:STARTED:`date`" >> ${PIDFILE}

   typeset DB_NAME=""
   get_db_name
   typeset -l db_name=${DB_NAME}

   exec 1>>${SID_LOG_FILE} 2>&1
   print "DATABASE ${db_name} RMAN BACKUP STARTS AT (`date '+%X %x'`):  .." \
        |tee -a ${LOGFILE}
   print "  Logging details to -- ${SID_LOG_FILE}" |tee -a ${LOGFILE}

   typeset -i WK_DAY=`date +%w`
   typeset -i CNT=`expr ${WK_DAY} + 2`
   typeset -i INC_BKUP_LVL=100
   if ([[ ${DEFLT_RMAN_CNFG} = $TRUE ]] && [[ -z ${INPT_INC_LVL} ]])
   then
      DEL_OBSOLT=$TRUE
      if [[ ! -f ${CNFG_FILE} ]] then
        print "  Config file ${CNFG_FILE} does not exist." |tee -a $LOGFILE
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
      else
         print "  Using default configration file ${PROC_DIR}/${PROC_NAME}.cfg."          |tee -a ${LOGFILE}
         cat ${CNFG_FILE} |grep ${db_name}|grep -v \#| read line
         if [[ -z $line ]] then
            print "  Database ${db_name} has not been configued."|tee -a $LOGFILE
            exec 1>>${LOGFILE} 2>&1
            return ${ST_FAIL}
         else
           INC_BKUP_LVL=$(print  "$line" |cut -d: -f${CNT})
           print "  Today is \"`date +%a`\".  \
                Configued incremental backup level is ${INC_BKUP_LVL}."
         fi
      fi
   else
        DEL_OBSOLT=$FALSE
        INC_BKUP_LVL=${INPT_INC_LVL}
        print "  Inputed incremental backup level is: ${INC_BKUP_LVL}." \
           |tee -a ${LOGFILE}
   fi

    #export SID_RMAN_BKUP_DIR="/data01/u03/rman/${db_name}"
    export SID_RMAN_BKUP_DIR="/${BKUP_DIR}/rman/${db_name}"

 # Get achive log destination
   RVAL=""
   get_arch_dest "1"
   if (( $? != ${STAT_OK} ))
   then
        print "  Get log_archive_dest returned an error."|tee -a $LOG
        return ${ST_FAIL}
   fi
   export SRC_ARCH_DIR=${RVAL}
   print "  log_archive_dest directory is ${SRC_ARCH_DIR}"

   print "  Uncompress archive logs ${SRC_ARCH_DIR}."
   gunzip ${SRC_ARCH_DIR}/*.gz >/dev/null 2>&1

   RMN_SCRPT="  run {
    backup incremental level ${INC_BKUP_LVL}
    format '${SID_RMAN_BKUP_DIR}/%d_dbf_%T_s%s_p%p'
    database PLUS ARCHIVELOG
    format '${SID_RMAN_BKUP_DIR}/%d_log_%T_s%s_p%p'
#    DELETE ARCHIVELOG ALL COMPLETED AFTER 'SYSDATE-1';
    delete input;
  }
"
   print "  Backup datafiles plus archive logs. Executing RMAN script....." \
        |tee -a ${LOGFILE}
   print "  ${RMN_SCRPT}"

   rman_handle "${RMN_SCRPT}"
   RET_CD=$?
   cat ${RMAN_TMP_LOG} >>${SID_LOG_FILE}
   if (( ${RET_CD} != ${STAT_OK} ))
   then
     print "  Backup with RMAN returned error." |tee -a ${LOGFILE}
     exec 1>>${LOGFILE} 2>&1
     return ${ST_FAIL}
   fi

  if [[ ${DEL_OBSOLT} -eq $TRUE ]]
  then
     RMN_SCRPT=""
     RMN_SCRPT="  run {
      delete noprompt obsolete;
     }
    "
     print "  Delete obsolete backups. Executing RMAN script...." \
        |tee -a ${LOGFILE}
     print "  ${RMN_SCRPT}"

   rman_handle "${RMN_SCRPT}"
   RET_CD=$?
   cat ${RMAN_TMP_LOG}>>${SID_LOG_FILE}
   if (( ${RET_CD} != ${STAT_OK} ))
   then
     print "  RMAN command return error." |tee -a ${LOGFILE}
     exec 1>>${LOGFILE} 2>&1
   fi

  fi


  chmod 644 ${SID_ADMIN_DIR}/rman/* >/dev/null  2>&1
  print "${db_name}:COMPLETE:`date`" >> ${PIDFILE}
  print "DATABASE ${db_name} RMAN HOT BACKUP DONE AT (`date '+%X %x'`)!" \
     |tee -a ${LOGFILE}
  exec 1>>${LOGFILE} 2>&1
  return ${STAT_OK}
}

#*************************************************************
# Function do_help: Explain usage of the program
#*************************************************************
function do_help {

    print "

    SYNTAX for ora_db_rman:

    ora_db_rman [<none|-l|?>] [<instance>,<instance>...]

    Here:
            none  Default configuration file used
            -l )  Choose incremental level
            -? )  Help

    Multiple instances may be specified when choose default.
    Must specify the instance name (only one) when choose -l.
    All arguments should be space delimited.

    Examples:
      ora_db_rman                (Backup all running databases)
      ora_db_rman  dev           (Backup dev)
      ora_db_rman  test test1    (Backup test and test1)
      ora_db_rman  -l 2 test     (Backup test using incremental level 2)
      ora_db_rman  -?            (Get this help)
    "
    exit 2
}

#*************************************************************
# Function rm_rmt_old_dir: Remove backup dir of a sid on remote
# side that is n days older
#*************************************************************
function rm_rmt_old_dir {
   typeset SID=$1
   set -A DIR_ARR
   typeset -i CNT=0
   typeset DIR0=""
   ${REMOTE_ACT} find ${REMOTE_DIR}/backup/${SID} -type d -mtime \
      +${DAYS_KEEP_BACKUPS}|grep -v exp|while read FILE
   do
      typeset    DIR1=$(print $FILE|awk -F/ '{print $6 }')
      if [[ $DIR1 != $DIR0 ]];
        then
           DIR_ARR[$CNT]=$DIR1
           CNT=$CNT+1
      fi
      DIR0=$DIR1
   done

   let CNT=0
   while [[ ${CNT} -lt ${#DIR_ARR[*]} ]]
   do
       print "${REMOTE_ACT} rm -r ${REMOTE_DIR}/backup/${SID}/${DIR_ARR[$CNT]} "
       ${REMOTE_ACT} rm -r ${REMOTE_DIR}/backup/${SID}/${DIR_ARR[$CNT]}
       CNT=$CNT+1
       sleep 10
   done
}

#***********************************************************************
# Function rman_handle: connect as sysdba and process a rman commands
# and return status of database. Produce a log file /tmp/rman.log
# example: dba_handle "$RMN_CMD"
#***********************************************************************
function rman_handle {
typeset -r RMN_SCRPT=$1
rm -f ${RMAN_TMP_LOG} >/dev/null 2>&1

rman catalog rman/rman@dev log ${RMAN_TMP_LOG} target / <<EOF
${RMN_SCRPT}
EOF
if (( $? != ${STAT_OK} ))
then
     print "  rman_handle returned an error."
     return ${ST_FAIL}
fi

    typeset -i ERRS=$(cat ${RMAN_TMP_LOG} |grep -v grep | \
        grep -icw "ERROR MESSAGE STACK FOLLOWS")
    if [[ ${ERRS} -ne 0 ]]
    then
      print "RMAN command returns error."
      return ${ST_FAIL}
    fi

    let ERRS=$(cat ${RMAN_TMP_LOG} |grep -v grep |grep -cw "failed")
    if [[ ${ERRS} -ne 0 ]]
    then
      print "RMAN command returns fail."
      return ${ST_FAIL}
    fi
    return ${STAT_OK}
