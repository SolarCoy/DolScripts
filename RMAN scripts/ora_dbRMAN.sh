(etadb5)prodora05:/usr/oracle/common/bin> cat ora_db_rman
#!/bin/ksh
################################################################################
#  Utility : ora_db_rman
#  Modules:  ora_db_rman (drive)
#            rman_env.ksh, rman_sid_env.ksh
#            db_lib.ksh, rman_funcs.ksh
#            ora_db_rman.cfg (configuration file)
#  Usage :
#
#    SYNTAX for ora_db_rman:
#
#    ora_db_rman [<none|-l|?>] [<instance>,<instance>...]
#
#     Here:
#            none  Default configuration file used
#            -l )  Choose incremental level
#            -? )  Help
#
#    Multiple instances may be specified when choose default.
#    Must specify the instance name (only one) when choose -l.
#    All arguments should be space delimited.
#
#    Examples:
#      ora_db_rman                (Backup all running databases)
#      ora_db_rman  dev           (Backup dev)
#      ora_db_rman  test test1    (Backup test and test1)
#      ora_db_rman  -l 2 test     (Backup test using incremental level 2)
#      ora_db_rman  -?            (Get this help)
#
#  Date :  Nov, 2004
#
################################################################################

PROC_DIR=$(dirname $0)
. ${PROC_DIR}/rman_env.ksh
. ${PROC_DIR}/db_lib.ksh
. ${PROC_DIR}/rman_funcs.ksh

#***************************************************************************
# RMAN BACKUP PROCESSE STARTS HERE
#***************************************************************************

>${LOGFILE}
print "${REPORT_HEAD}">>${LOGFILE}

while getopts ":l:" opt; do
case $opt in
   l ) export DEFLT_RMAN_CNFG=$FALSE
       export INPT_INC_LVL=$OPTARG
       if ([[ ${INPT_INC_LVL} -eq 0 ]] || [[ ${INPT_INC_LVL} -eq 1 ]] || \
          [[ ${INPT_INC_LVL} -eq 2 ]] )
       then
          echo "Input RMAN incremental level is ${INPT_INC_LVL}. "
       else
          do_help
          print "Please choose incremental level 0, 1 or 2."
          exit
       fi;;
   ? ) do_help
       return 1
esac
done;

if [[ ${OSNAME} != "oracle" ]]
then
     print "You must be oracle to run this script.">> ${LOGFILE}
     exit 1
fi

print $$ >${PIDFILE}

shift $(($OPTIND - 1))
typeset -l ALLARGS=$@
if [[ ${DEFLT_RMAN_CNFG} = $TRUE ]] then
#   echo "Default configration file ${PROC_DIR}/${PROC_NAME}.cfg used. "
   if [[ $# -eq 0 ]]
   then
      integer ALL_DBS=$TRUE
      export ALL_DBS
   fi
else
   if [[ $# -eq 0 ]]
   then
        integer ALL_DBS=$FALSE
        export ALL_DBS
        print "Please specify database name being backup."
        do_help
        exit
   fi
fi

# make list of instances to operate on
set -A SIDNAME
set -A SIDHOME
integer CNT=0

exec 1>>${LOGFILE} 2>&1
#populate SIDNAME and SIDHOME arrays
if [[ ${ALL_DBS} = $TRUE ]]
then
   let CNT=0
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
else
   let CNT=0
   for ARG in $ALLARGS
   do
      if [[ -f $HOME/.profile_${ARG} ]] then
        . $HOME/.profile_${ARG} #to get SID and HOME
        SIDNAME[$CNT]=${ORACLE_SID}
        SIDHOME[$CNT]=${ORACLE_HOME}
        let CNT=$CNT+1
      else
           print " $HOME/.profile_${ARG} does not exists. "
      fi
   done
fi

#Loop through all instances
integer NUM=0
while [[ ${NUM} -lt ${#SIDNAME[*]} ]]
do
   print "***************************************************" >>${LOGFILE}
   print "*** Process ${SIDNAME[$NUM]} - ${SIDHOME[$NUM]} *** " >>${LOGFILE}
   print "***************************************************" >>${LOGFILE}
   SID=${SIDNAME[$NUM]}
   ORA_HOME=${SIDHOME[$NUM]}

   typeset -i PMON_PROCS=$(ps -ef|grep -v grep|grep -cw ora_pmon_${SID})
   if [[ ${PMON_PROCS} -eq 0 ]] 2>/dev/null
   then
        print "***************************************************" >>${LOGFILE}
        print "${SID} - Not Running - Backup Skipped." >>${LOGFILE}
        print "***************************************************" >>${LOGFILE}
        NUM=$NUM+1
        continue
   fi

   # Some database like standby database may not need backup
   for skip_sid in ${BACKUP_SKIP_LIST}
   do
     if [[ ${skip_sid} = $SID ]]
     then
        let BRK=$TRUE
        break
     fi
   done
   if [[ $BRK = $TRUE ]]
   then
        print "***************************************************" >>${LOGFILE}
        print "${SID} - in skip list -- Backup Skipped." >>${LOGFILE}
        print "***************************************************" >>${LOGFILE}
        let BRK=$FALSE
        NUM=$NUM+1
        continue
   fi

   . $HOME/.profile_${SID} # to set environment

   # Set environments that specific to the SID
   SED="sed  -e '/^$/d' ${PROC_DIR}/rman_sid_env.ksh"
   eval $SED|grep -v \#|awk -F= '{print $1, $2}'|while read VARNAME VALUE
   do
       eval  $VARNAME=${VALUE}
   done

   #******************************************************************
   # Start Main Process
   #******************************************************************

   check_arch_mode
   if (( $? != ${ARCHIVE_MODE} ))
   then
       print "  $ORACLE_SID - NOT ARCHIVE MODE backup skipped. "
       NUM=$NUM+1
       continue
   fi

   do_rman_sid $SID
   if (( $? != ${STAT_OK} ))
   then
   #   ${REMOTE_ACT}  rm -rf ${SID_RMAN_REMOTE_DIR}  2>/dev/null
       print "  **** Hot backup for $SID failed.**** "
       print " "
       NUM=$NUM+1
       continue
    fi
    print " "
    let NUM=${NUM}+1
done #finished main loop

rm -f ${PIDFILE}
rm_old_files ${DAYS_KEEP_LOGS} $COMMLOG "ora_db_rman*.log"
print " "
print "BACKUP FOR ALL DATABASES ARE DONE - $(date)." >>${LOGFILE}

#mail_file "${MAIL_SUBJ_RMAN}" ${LOGFILE}

#***************************************************************************
# Program ora_db_rman ends here.
#***************************************************************************
(etadb5)prodora05:/usr/oracle/common/bin>
