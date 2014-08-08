#!/bin/ksh
################################################################################
#  Module : backup_env.ksh
#
#  Usage : a module of ora_db_backup
#
#  Author : Faying Dong
#  Date : Oct 2004
################################################################################
export EXP_TIMESTAMP=`date +%b%d%H`
export TIMESTAMP=`date +%b%d%y`
export LOG_TIMESTAMP=`date +%b%d%H%M%S`
export STAT_OK=0
export ST_FAIL=1

export TRUE=1
export FALSE=0

export ARCHIVE_MODE=4

export HOT_BACKUP=1
export EXP_BACKUP=2
export MISC_BACKUP=3

export BACKUP_MOD=$FALSE
export ALL_DBS=$FALSE

export REMOTE=$FALSE 
export PROC_NAME=$(basename $0)
export OSNAME=$(/usr/ucb/whoami)
export COMMLOG="/export/home/oracle/common/log"
export LOGFILE=${COMMLOG:=/tmp}/${PROC_NAME}.${LOG_TIMESTAMP}.log
export PIDFILE=${COMMLOG}/${PROC_NAME}.$$.pid
export HOST_NAME=$(hostname) 

#*********************************************************************
# ONLY THIS PART BELLOW MAY BE MODIFIED, IN CASE
#*********************************************************************
export BACKUP_SKIP_LIST="stbdb3 stbdb4 stbpdb"

export DAYS_KEEP_LOGS=5    #(plus 1) days that log files kept on local host 
			   # common/log and admin/sid/log 
export DAYS_KEEP_BACKUPS=2 # days that backup sets kept on remote  
			   #host (prodora08) under backup/monthdayyear
export DAYS_KEEP_EXPS=2    #(plus 1) days that export backups kept on both 
                           # remote and local hosts under exp/ and /u03/exp
export DAYS_KEEP_ARCHS=0   #(plus 1) days that arch logs kept on local host
                           # under log_arch_dest_1 directory  

export ZIP="compress"
export GZIP=$(type gzip|awk '{print $NF}')

export REMOTE_ACCT="orabk@prodora08"
export REMOTE_ACT="ssh ${REMOTE_ACCT}"

export REMOTE_MPT="/orabk02"
export REMOTE_DIR="${REMOTE_MPT}/${HOST_NAME}"

#export SEND_MAIL=$FALSE
export SEND_MAIL=$TRUE
export MAIL_SUBJ_BKUP="DB Backup Report - ${HOST_NAME}"
export MAIL_SUBJ_EXP="DB Export Report - ${HOST_NAME}"
export MAIL_SUBJ_MISC="DB Backup Misc Report - ${HOST_NAME}"
export MAIL_LIST="dong.faying@dol.gov  black.michael@dol.gov Amerman.Shane@dol.gov anderson.robert@dol.gov smith.bradford@dol.gov "
REPORT_HEAD=" 
                    DATABASE BACKUP REPORT  
**************************************************************************

     Server     : ${HOST_NAME}    

     Command    : $0 $* 
     
     Start Time : `date` 

"
