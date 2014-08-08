#!/bin/ksh

################################################################################
#  Module : backup_funcs.ksh
#
#  Usage : a module of ora_db_backup process
#
#  Author : Faying Dong
#  Date : Oct 2004
################################################################################
#***********************************************************************
# Function do_hot_bkup_sid: drive of hot backup process 
# ----------------------------------------------------------------------
# 1. Remove log files that are n days older
# 2. Get tablespaces dynamically from database
# 3. Do all tablespaces backup
# 4. Backup all old archive logs 
# 5. Backup pwd file, pfile, spfile
# 6. Backup binary and text control files
#***********************************************************************
function  do_hot_bkup_sid { 
  SID=$1; export SID

  typeset SID_LOG_FILE=${SID_LOG_DIR}/${SID_HOT_LOG_FILE}

  print "${SID}:STARTED:`date`" >> ${PIDFILE}

  exec 1>>${SID_LOG_FILE} 2>&1
  print "DATABASE $SID HOT BACKUP STARTS AT (`date '+%X %x'`):  .." \
	|tee -a ${LOGFILE}
  print "  Logging details to -- ${SID_LOG_FILE}" |tee -a ${LOGFILE} 

  #Cleanup logs 
  print "  Remove log file ${DAYS_KEEP_LOGS} days older. " |tee -a ${LOGFILE}
  rm_old_files ${DAYS_KEEP_LOGS} ${SID_LOG_DIR} "hot*.log"

  print "  Get tablespace datafiles dynamically from database." \
     |tee -a ${LOGFILE}
  get_tablespaces_datafiles 
  if (( $? != ${STAT_OK} ))
   then
       print "  get_tablespaces_datafiles failed." |tee -a ${LOGFILE}
       exec 1>>${LOGFILE} 2>&1
       return ${ST_FAIL}
   fi

  print "  Log switch." |tee -a ${LOGFILE} 
  log_switch
  if (( $? != ${STAT_OK} ))
   then
        print "  Switch logfile failed." |tee -a ${LOGFILE}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
   fi

  print "  Do backup for all tablespaces."|tee -a ${LOGFILE}
  do_tablespace_bkup
  if (( $? != ${STAT_OK} ))
   then
        print "  do_tablesapce_bkup failed." |tee -a ${LOGFILE}
        rm -f ${SID_TABLESPACES}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
  fi
  
  # backup binary and ASCII(script) control files to a temp directory
  if [[ $REMOTE = $TRUE ]] then
  print "  Backup control files to remote site ${SID_RMT_TOP_DIR}/misc."|tee -a ${LOGFILE}
  else 
  print "  Backup control files to ${SID_LOC_TOP_DIR}/misc."|tee -a ${LOGFILE}
  fi
  if [[ -d ${SID_MISC_DIR} ]] then
   	rm -r ${SID_MISC_DIR} 
  fi 

  mkdir -p  ${SID_MISC_DIR} 

  do_controlfile_bkup; #if fail rm directory
  if (( $? != ${STAT_OK} ))
   then
        print "  do_controlfile_bkup failed." |tee -a ${LOGFILE}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
  fi
  rm -r $SID_MISC_DIR

  print "  Log switch." |tee -a ${LOGFILE} 
  log_switch
  if (( $? != ${STAT_OK} ))
  then
        print "  Switch logfile failed." |tee -a ${LOGFILE}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
  fi 
  sleep 30

  if [[ $REMOTE = $TRUE ]] then
     print "  Compress and backup archive logs to remote site ${SID_RMT_TOP_DIR}/arch." |tee -a ${LOGFILE} 
  else 
     print "  Compress and backup archive logs to ${SID_LOC_TOP_DIR}/arch." |tee -a ${LOGFILE} 
  fi

  do_arch_logs $SID 
  if (( $? != ${STAT_OK} ))
  then
      print "  Compress and backup archive logs for $SID failed." \
	|tee -a ${LOGFILE}
      exec 1>>${LOGFILE} 2>&1
      return ${ST_FAIL}
  fi

  # backup pwd file, pfile, spfile
  print " "
  print "  Copy pfile(spfile) and pwd file to misc." |tee -a ${LOGFILE}
  do_pwd_spfile_bkup
  if (( $? != ${STAT_OK} ))
  then
      print "  do_pwd_spfile_bkup failed." |tee -a ${LOGFILE}
      exec 1>>${LOGFILE} 2>&1
      return ${ST_FAIL}
  fi

  chmod 644 ${SID_LOC_TOP_DIR}/dbf/* >/dev/null 2>&1
  chmod 644 ${SID_LOC_TOP_DIR}/misc/* >/dev/null 2>&1
  chmod 644 ${SID_LOC_TOP_DIR}/arch/* >/dev/null 2>&1
   
  print "${SID}:COMPLETE:`date`" >> ${PIDFILE}
  print "DATABASE $SID HOT BACKUP DONE AT (`date '+%X %x'`)!" \
     |tee -a ${LOGFILE}
  exec 1>>${LOGFILE} 2>&1
  return ${STAT_OK}
}

#***********************************************************************
# Function do_misc_bkup_sid:  
#***********************************************************************
function  do_misc_bkup_sid { 
  SID=$1; export SID

  typeset SID_LOG_FILE=${SID_LOG_DIR}/${SID_HOT_LOG_FILE}

  print "${SID}:STARTED:`date`" >> ${PIDFILE}

  exec 1>>${SID_LOG_FILE} 2>&1
  print "DATABASE $SID MICS BACKUP STARTS AT (`date '+%X %x'`):  .." \
	|tee -a ${LOGFILE}
  print "  Logging details to -- ${SID_LOG_FILE}" |tee -a ${LOGFILE} 

  #Cleanup logs 
  print "  Remove log file ${DAYS_KEEP_LOGS} days older. " |tee -a ${LOGFILE}
  rm_old_files ${DAYS_KEEP_LOGS} ${SID_LOG_DIR} "hot*.log"

  print "  Log switch." |tee -a ${LOGFILE} 
  log_switch
  if (( $? != ${STAT_OK} ))
  then
        print "  Switch logfile failed." |tee -a ${LOGFILE}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
  fi 
  sleep 30
  # backup binary and ASCII(script) control files to a temp directory
  print "  Backup control files to remote site ${SID_RMT_TOP_DIR}/misc."|tee -a ${LOGFILE}
  if [[ -d ${SID_MISC_DIR} ]] then
   	rm -r ${SID_MISC_DIR} 
  fi 

  mkdir -p  ${SID_MISC_DIR} 

  do_controlfile_bkup; #if fail rm directory
  if (( $? != ${STAT_OK} ))
   then
        print "  do_controlfile_bkup failed." |tee -a ${LOGFILE}
        exec 1>>${LOGFILE} 2>&1
        return ${ST_FAIL}
  fi
  rm -r $SID_MISC_DIR

  # backup pwd file, pfile, spfile
  print " "
  print "  Copy pfile(spfile) and pwd file misc."  |tee -a ${LOGFILE}
  do_pwd_spfile_bkup
  if (( $? != ${STAT_OK} ))
  then
      print "  do_pwd_spfile_bkup failed." |tee -a ${LOGFILE}
      exec 1>>${LOGFILE} 2>&1
      return ${ST_FAIL}
  fi

  chmod 644 ${SID_LOC_TOP_DIR}/dbf/* >/dev/null 2>&1
  chmod 644 ${SID_LOC_TOP_DIR}/misc/* >/dev/null 2>&1
  chmod 644 ${SID_LOC_TOP_DIR}/arch/* >/dev/null 2>&1

  print "${SID}:COMPLETE:`date`" >> ${PIDFILE}
  print "DATABASE $SID MISC BACKUP DONE AT (`date '+%X %x'`)!" \
     |tee -a ${LOGFILE}
  exec 1>>${LOGFILE} 2>&1
  return ${STAT_OK}
}

#***********************************************************************
# Function get_tablespaces_datafiles: get the list 
# dynamically from dataabse 
#***********************************************************************
function get_tablespaces_datafiles {
 SQL1="col tablespace_name format a18
       col file_name format a60
       set linesize 100
       spool ${SID_TABLESPACES};
       select d.tablespace_name, d.file_name, t.status \
       from dba_data_files d , dba_tablespaces t \
       where d.tablespace_name=t.tablespace_name \
       order by tablespace_name;
       spool off"

   
   if [[ -f ${SID_TABLESPACES} ]] then
         rm -f ${SID_TABLESPACES} 2>/dev/null 
   fi

   dba_handle "$SQL1"
   Rtn_Cd=$?
   if [[ ! -f ${SID_TABLESPACES} ]]
   then
        print "  ${SID_TABLESPACES} file not created, exit program."
        return ${ST_FAIL} 
   fi
  if (( ${Rtn_Cd} != ${STAT_OK} ))
   then
        return ${ST_FAIL}
  fi

return $STAT_OK
}

#**********************************************************************
# Function do_tablespace_backup: Backup datafiles via backup tablespaces 
#**********************************************************************
function do_tablespace_bkup {
   print "Backup tablespaces starts ..."
   SED="sed -e '/selected/d' -e '/^$/d' ${SID_TABLESPACES}"

   typeset PREV_TABLESPACE="NON_EXIST_TBLSPS"
   typeset PREV_STATUS="NON_EXIST_STATUS"
   eval $SED|while read TABLESPACE DATA_FILE STATUS
   do
   print "$TABLESPACE $DATA_FILE $STATUS ... "
   if [[ $TABLESPACE != ${PREV_TABLESPACE} ]]
   then  
        if [[ ${PREV_TABLESPACE} != "NON_EXIST_TBLSPS" ]] 
        then
            print "End backup $PREV_TABLESPACE (`date '+%X %x'`)"
            SQL3="alter tablespace ${PREV_TABLESPACE} end backup;"
            print ""
         if [[ ${PREV_STATUS} != "OFFLINE" ]] then
            dba_handle $SQL3
            if (( $? != ${STAT_OK} ))
            then
                print "Backup (end) $PREV_TABLESPACE failed"
		return ${ST_FAIL}
            fi
          fi
        fi

        print "Begin backup $TABLESPACE (`date '+%X %x'`)"
        SQL2="alter tablespace $TABLESPACE begin backup;"
        if [[ ${STATUS} != "OFFLINE" ]] then
          dba_handle $SQL2
          if (( $? != ${STAT_OK} ))
          then
            print "Backup (begin) $TABLESPACE failed."
	    return ${ST_FAIL}
          fi
        fi
        ${ZIP}< ${DATA_FILE}>${DATA_FILE}.Z  2>/dev/null
        if [[ $REMOTE = $TRUE ]] then
          scp -p ${DATA_FILE}.Z ${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/dbf
        else
          #cp -p ${DATA_FILE}.Z ${SID_LOC_TOP_DIR}/dbf
          mv  ${DATA_FILE}.Z ${SID_LOC_TOP_DIR}/dbf
        fi
        if (( $? != ${STAT_OK} ))
        then
               print "  Copy ${DATA_FILE}.Z failed."
               return ${ST_FAIL}
        fi
   else
        ${ZIP}< ${DATA_FILE}>${DATA_FILE}.Z 2>/dev/null
        if [[ $REMOTE = $TRUE ]] then
           scp -p ${DATA_FILE}.Z ${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/dbf
        else
           cp -p ${DATA_FILE}.Z ${SID_LOC_TOP_DIR}/dbf
        fi
        if (( $? != ${STAT_OK} ))
        then
             print "  Copy ${DATA_FILE}.Z failed."
             return ${ST_FAIL}
        fi
   fi 
        PREV_TABLESPACE=$TABLESPACE
        PREV_STATUS=$STATUS
   done
   print "End backup ${PREV_TABLESPACE}(last): (`date '+%X %x'`)."
   print " "
   SQL3="alter tablespace ${PREV_TABLESPACE} end backup;"
   if [[ ${PREV_STATUS} != "OFFLINE" ]] then
     dba_handle $SQL3
     if (( $? != ${STAT_OK} ))
     then
     print "Backup $PREV_TABLESPACE failed."
       return ${ST_FAIL}
     fi
   fi
   rm -f ${SID_TABLESPACES}
   return $STAT_OK
}

#***********************************************************************
# Function do_controlfile_copy: backup a ASCII controlfile
# and a binary controlfiles 
#***********************************************************************

function do_controlfile_bkup {
print "  Backup ASCII and binary contorlfile to trace."

RET_VAL=""
get_dest_dir "user_dump"
if (( $? != ${STAT_OK} ))
then
    print "  Get user_dump_dest returned an error."
    return ${ST_FAIL}
fi
typeset USER_DUMP_DEST=$(print ${RET_VAL}|grep ${ORACLE_SID}|awk '{print $NF}')
print "  user_dump_dest is ${USER_DUMP_DEST}."

typeset SQL="alter system set user_dump_dest='${SID_MISC_DIR}';
       alter database backup controlfile to trace; 
       alter system set user_dump_dest='${SID_ADMIN_DIR}/udump';
       alter database backup controlfile to '${SID_MISC_DIR}/control01.ctl';" 
rm -f ${SID_MISC_DIR}/* 2>/dev/null

dba_handle "$SQL"
if (( $? != ${STAT_OK} ))
then
    print "  dba_handle backup ascii and binary control file failed ."
    return ${ST_FAIL}
fi
sleep 10
print "  Get a list of all data, redo, control files. "
SQL2="spool  ${SID_MISC_DIR}/all_files.lst;
         select file_name from dba_data_files
         union all
         select member from v\$logfile
         union all
         select file_name from dba_temp_files
         union all
         select name from v\$controlfile;
         spool off "

  dba_handle "$SQL2"
  if (( $? != ${STAT_OK} ))
  then
        print "  Get a list of all files faild."
  fi

ls ${SID_MISC_DIR} |while read FILE
do
  print "  Backup file $FILE. "

  if [[ $REMOTE = $TRUE ]] then
     scp -p  ${SID_MISC_DIR}/${FILE} ${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/misc
  else
     cp -p  ${SID_MISC_DIR}/${FILE} ${SID_LOC_TOP_DIR}/misc
  fi
  if (( $? != ${STAT_OK} ))
  then
         print "  Copy ${FILE} failed."
         return ${ST_FAIL}
  fi
done
return $STAT_OK
}

#***********************************************************************
# Function do_pwd_spfile_bkup: backup a password file and a pfile 
# to a target tar file 
#***********************************************************************
function do_pwd_spfile_bkup {
  SQL="create pfile='${ORACLE_HOME}/dbs/init${ORACLE_SID}.bk' from spfile;"
  dba_handle "$SQL"
  # Copy init file
  if [[ $REMOTE = $TRUE ]] then
     scp -p  ${ORACLE_HOME}/dbs/init${ORACLE_SID}.bk \
   	${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/misc
     if (( $? != ${STAT_OK} ))
     then
            print "  Remote copy init${ORACLE_SID}.bk failed." |tee -a $LOGILFE
   #         return ${ST_FAIL}
     fi
   
   #Copy spfile
     scp -p  ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora \
   	${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/misc
     if (( $? != ${STAT_OK} ))
     then
          print "  Copy spfile${ORACLE_SID}.ora failed." |tee -a $LOGILFE
   #         return ${ST_FAIL}
     fi
   # Copy orapwd file
     scp -p  ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
   	${REMOTE_ACCT}:${SID_RMT_TOP_DIR}/misc
     if (( $? != ${STAT_OK} ))
     then
            print "  Remote copy orapwd${ORACLE_SID} failed." |tee -a $LOGILFE
   #         return ${ST_FAIL}
     fi
 else
     cp -p  ${ORACLE_HOME}/dbs/init${ORACLE_SID}.bk \
	${SID_LOC_TOP_DIR}/misc
     if (( $? != ${STAT_OK} ))
     then
         print "  Copy init${ORACLE_SID}.bk failed." |tee -a $LOGILFE
#         return ${ST_FAIL}
     fi

     cp -p  ${ORACLE_HOME}/dbs/spfile${ORACLE_SID}.ora \
	${SID_LOC_TOP_DIR}/misc
     if (( $? != ${STAT_OK} ))
     then
         print "  Copy spfile${ORACLE_SID}.ora failed." |tee -a $LOGILFE
#         return ${ST_FAIL}
     fi
     cp -p  ${ORACLE_HOME}/dbs/orapw${ORACLE_SID} \
	${SID_LOC_TOP_DIR}/misc
    if (( $? != ${STAT_OK} ))
    then
         print "  Copy orapwd${ORACLE_SID} failed." |tee -a $LOGILFE
#             return ${ST_FAIL}
    fi
  fi
  return $STAT_OK
}

#***********************************************************************
# Function do_arch_logs:
# 1. Get archive log destination
# 2. Remote archive logs n days older
# 
#***********************************************************************
function do_arch_logs  {
   SID=$1

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

   print "  Remove compressed archive logs that ${DAYS_KEEP_ARCHS}" 
   print "  days older under ${SRC_ARCH_DIR} directory. "
   rm_old_files ${DAYS_KEEP_ARCHS} ${SRC_ARCH_DIR} "*arc.gz"
   rm_old_files ${DAYS_KEEP_ARCHS} ${SRC_ARCH_DIR} "*arc.Z"

   print "  Compress and copy archive logs of $SID  "

   compress_copy_arch_logs $SID 
   if (( $? != ${STAT_OK} ))
   then
        print "  Compress and copy archive logs failed."|tee -a $LOG
        return ${ST_FAIL}
   fi
  print "*******************************************************"|tee -a $LOG
  print "Start arch log seq#: $START_SEQ; End seq#: $END_SEQ"|tee -a $LOG
  print "*******************************************************"|tee -a $LOG
  return ${STAT_OK}
 } 


#********************************************************************
# Function do_export_sid:
#-------------------------------------------------------------------
# 1. Remove log file and backups those are n days older;
# 2. Check if database is up 
#    Set NLS_LANG environment which dynamically got from database.
# 3. Create a user account on fly with random password 
# 4. Create a parfile and a named pipe
# 5. Process export  
# 6. Drop the temporary user account
#********************************************************************
function do_export_sid {
  SID=$1
  typeset RetVal=${STAT_OK}

  print "DATABASE $SID FULL EXPORT STARTS AT (`date '+%X %x'`).." 
  print "  Logging details to -- ${SID_EXP_LOG_FILE}" 

  print "  Remove log file ${DAYS_KEEP_LOGS} days older."
  rm_old_files ${DAYS_KEEP_LOGS} ${SID_LOG_DIR} "exp*.log"
  rm_old_files ${DAYS_KEEP_LOGS} ${SID_LOG_DIR} "exp*.rpt"

  print "  Remove export dumps under ${SID_EXP_DEST} ${DAYS_KEEP_EXPS} days older. "
  rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_DEST} "exp*.gz"  
  rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_DEST} "exp*.Z"  

  # if the database is not up then force it up
  typeset -i PMON_PROCS=$(ps -ef|grep -v grep|grep -cw ora_pmon_${SID})
  if [[ ${PMON_PROCS} -eq 0 ]] 
  then
    print "  Database $SID is not up. Start it up force."
    SQL="startup force;"
    dba_handle "$SQL"
    if (( $? != ${STAT_OK} ))
    then
          print "  Startup Force $SID failed."
          return ${ST_FAIL}
    fi 
  fi

  print "  Get NLS_LANG of $SID info from database."
  
  NLSSQL="select (select value from nls_database_parameters where PARAMETER = 'NLS_LANGUAGE')||'_'|| (select value from nls_database_parameters where PARAMETER = 'NLS_TERRITORY')||'.'|| (select value from nls_database_parameters where PARAMETER = 'NLS_CHARACTERSET') from dual;"
  
  RET_VAL=""
  dba_handle "$NLSSQL"
  if (( $? != ${STAT_OK} ))
  then
      print "  Get NSL_LANG of $SID from database failed."
      return ${ST_FAIL}
  fi
  
  NLS_LANG_STR=$(print ${RET_VAL}|awk '{print $NF}')
  NLS_LANG=${NLS_LANG_STR};export NLS_LANG
  
  #create a random password
  EXP_PW="e${RANDOM}${RANDOM}"
  
  print "  Create the exporter user w/ random password & grant as necessary."
  QUERY="grant create session,exp_full_database to exporter identified by ${EXP_PW};
         grant execute on DBMS_RLS to exporter;
         grant exempt access policy to exporter;"

  dba_handle "$QUERY"
  if (( $? != ${STAT_OK} ))
  then
       print "Create user exporter failed."
       return ${ST_FAIL}
  fi
  print "  Export user exporter created for $SID." 
  
  #create pipe to shove export thru
  /usr/sbin/mknod ${PIPENAME} p 
  #start compress
  ${ZIP} < ${PIPENAME} >${SID_EXP_BKUP_DMP} &
  
  rm -f ${SID_ADMIN_DIR}/exp/par_*.lst >/dev/null 2>&1
  >${PARFILE}
  chmod 600 ${PARFILE}
  print "  Build a parfile $PARFILE." 
  print "USERID=exporter/$EXP_PW" >>$PARFILE
  print "FULL=y" >>$PARFILE
  print "FILE=${PIPENAME}" >>$PARFILE
  print "DIRECT=Y" >>$PARFILE
  print "CONSISTENT=Y" >>$PARFILE
  print "BUFFER=2048576" >>$PARFILE
  
  #do the export
#  print "  ${ORACLE_HOME}/bin/exp parfile=${PARFILE}" 
  exec 1>>${SID_EXP_LOG_FILE} 2>&1 
  ${ORACLE_HOME}/bin/exp parfile=${PARFILE} 
  if (( $? != ${STAT_OK} )) 
  then
      print "  Export Failed for $SID." |tee ${LOGFILE} 
      print "  See ${SID_EXP_LOG_FILE} for details. "
      RetVal=${ST_FAIL} #should not return right now
  fi
  exec 1>>${LOGFILE} 2>&1
  #clean up files
  rm ${PARFILE}
  rm ${PIPENAME}
  
  # drop the exporter user
  print "  Drop the exporter user of $SID." 
  SQL="drop user exporter cascade;"
  dba_handle $SQL
  if (( $? != ${STAT_OK} ))
  then
       print "  Drop user exporter failed." 
       return ${ST_FAIL}
  fi

  if [[ $RetVal = ${STAT_OK} ]] then
    print "========================================================"
    print "Check Error Messages (if any):"
    print ""
    if [[ -f ${SID_EXP_LOG_FILE} ]] then
    	cat ${SID_EXP_LOG_FILE}|grep EXP- >>${LOGFILE}
    	print ""
    	cat ${SID_EXP_LOG_FILE}|tail -3  >>${LOGFILE}
    print "========================================================"
    else
    	 print "${LOGFILE} does not exist."
    fi
  
    if [[ $REMOTE = $TRUE ]] then
      print "Remove dump files ${DAYS_KEEP_EXPS} day(s) older from Remote Site."
      rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_REMOTE_DIR} "exp*.Z" $REMOTE 
      rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_REMOTE_DIR} "exp*.gz" $REMOTE 
  
      print "Copy dump file to remote site ${SID_EXP_REMOTE_DIR}" 
      scp -p ${SID_EXP_BKUP_DMP} ${REMOTE_ACCT}:${SID_EXP_REMOTE_DIR}/${SID_EXP_FILE_NAME}
      if (( $? != ${STAT_OK} ))
      then
        print "Remote copy ${SID_EXP_FILE_NAME} failed."
      fi
    else 
      print "Remove dump files ${DAYS_KEEP_EXPS} day(s) older."
      rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_DEST} "exp*.Z" 
      rm_old_files ${DAYS_KEEP_EXPS} ${SID_EXP_DEST} "exp*.gz"
  
     # print "Copy dump file to ${SID_EXP_DEST}"  they are in same directory.
     # cp -p ${SID_EXP_BKUP_DMP} ${SID_EXP_DEST}/${SID_EXP_FILE_NAME}
    fi
  fi
  print "DATABASE $SID FULL EXPORT ENDS AT (`date '+%X %x'`)." 
  return ${RetVal}
}
#*************************************************************
# Function do_help: Explain usage of the program 
#*************************************************************
function do_help {

    print ""
    print "
    SYNTAX for $0:
    
    $0 [-h|-e|?] [<instance>,<instance>...]
    
     Here:
            -h )  hot backup
            -e )  logical backup (export)
            -? )  help
    
    Multiple instances may be specified.
    
    Order of arguments is not significant
    
    All arguments should be space delimited.
    
    Examples:  
      ora_db_backup -h            (Hot backup all running databases)
      ora_db_backup -h test 	  (Hot backup test) 
      ora_db_backup -h test test1 (Hot backup test and test1)
      ora_db_backup -?            (Get this help)   
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

#*************************************************************
# Function rm_loc_old_dir: Remove backup dir of a sid on local 
# side that is n days older 
#*************************************************************
function rm_loc_old_dir {
   typeset SID=$1
   set -A DIR_ARR
   typeset -i CNT=0
   typeset DIR0=""
   find ${SID_ADMIN_DIR}/backup/* -type d -mtime \
      +${DAYS_KEEP_BACKUPS}|grep -v exp|while read FILE
   do
      typeset    DIR1=$(print $FILE|awk -F/ '{print $8 }')
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
       print "rm -r ${SID_ADMIN_DIR}/backup/${DIR_ARR[$CNT]} "
       rm -r ${SID_ADMIN_DIR}/backup/${DIR_ARR[$CNT]} 
       CNT=$CNT+1
       sleep 10
   done
}
