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

export REMOTE=1

PROC_NAME=$(basename $0)
export OSNAME=$(/usr/ucb/whoami)
export HOST_NAME=$(hostname) 

#*********************************************************************
# ONLY THIS PART BELLOW MAY BE MODIFIED, IN CASE
#*********************************************************************
export BACKUP_SKIP_LIST
export COMMLOG="/export/home/oracle/common/log"
export LOGFILE=${COMMLOG:=/tmp}/${PROC_NAME}.${LOG_TIMESTAMP}.log
export PIDFILE=${COMMLOG}/${PROC_NAME}.$$.pid

export LOCAL_BKDIR2="/u02"
#export LOCAL_BKDIR3="/u03"
export LOCAL_BKDIR3="/export/home/oracle"
export DAYS_KEEP_LOGS=5
export DAYS_KEEP_BACKUPS=2 
export DAYS_KEEP_EXPS=1 
export DAYS_KEEP_ARCHS=2 

export ZIP="compress"
export GZIP=$(type gzip|awk '{print $NF}')

export REMOTE_ACCT="orabk@prodora08"
export REMOTE_ACT="ssh ${REMOTE_ACCT}"

export REMOTE_MPT="/orabk01"
export REMOTE_DIR="${REMOTE_MPT}/${HOST_NAME}"
#export REMOTE_MPT="/orabk02"
#export REMOTE_DIR="${REMOTE_MPT}/${HOST_NAME}"

export SEND_MAIL=$TRUE
#export SEND_MAIL=$FALSE
export MAIL_SUBJ_EXP="DB Export Report - ${HOST_NAME}"
export MAIL_SUBJ_BKUP="DB Backup Report - ${HOST_NAME}"
export MAIL_SUBJ_MISC="DB Backup Misc Report - ${HOST_NAME}"
export MAIL_LIST="dong.faying@dol.gov black.michael@dol.gov Amerman.Shane@dol.gov Lay.Coy@dol.gov smith.bradford@dol.gov"

REPORT_HEAD=" 
                    DATABASE BACKUP REPORT  
**************************************************************************

     Server     : ${HOST_NAME}    

     Command    : $0 $* 
     
     Start Time : `date` 

"
