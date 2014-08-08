#!/bin/ksh

################################################################################
#  Module : backup_sid_env.ksh  
#
#  Usage : a module of ora_db_backup process
#
#  Author : Faying Dong
#  Date : Oct 2004
################################################################################
ADMIN_DIR=${ORACLE_BASE}/admin
SID_LOG_DIR=${ADMIN_DIR}/${SID}/log
SID_RMT_TOP_DIR=${REMOTE_DIR}/backup/${SID}/${TIMESTAMP}
SID_LOC_TOP_DIR=${ADMIN_DIR}/${SID}/backup/${TIMESTAMP}
SID_MISC_DIR=${SID_LOG_DIR}/misc
SID_EXP_REMOTE_DIR="${REMOTE_DIR}/exp/${SID}"

# env. parameters for hot backup of individual database (sid)
SID_HOT_LOG_FILE=hot_${SID}_${LOG_TIMESTAMP}.log
SID_TABLESPACES=${SID_LOG_DIR}/hot_tablespaces.lst

#SID_HOT_DB_DEST=${SID_RMT_TOP_DIR}/dbf     # tmporary change for misc
#SID_HOT_ARCH_DEST=${SID_RMT_TOP_DIR}/arch     # tmporary change for misc
SID_HOT_DB_DEST=${SID_LOC_TOP_DIR}/dbf     # tmporary change for misc
SID_HOT_ARCH_DEST=${SID_LOC_TOP_DIR}/arch     # tmporary change for misc

# Env. parameters for full export of individual database (sid)
#SID_EXP_DEST=${LOCAL_BKDIR3}/exp/${SID}
SID_EXP_DEST=${ADMIN_DIR}/${SID}/exp
SID_EXP_RPT_FILE=exp_${SID}_${EXP_TIMESTAMP}.rpt
SID_EXP_LOG_FILE=exp_${SID}_${EXP_TIMESTAMP}.log
SID_RPT_FILE=${SID_LOG_DIR}/${SID_EXP_RPT_FILE}
SID_EXP_LOG_FILE=${SID_LOG_DIR}/${SID_EXP_LOG_FILE}
SID_EXP_FILE_NAME=exp_${SID}_${EXP_TIMESTAMP}.dmp.Z
SID_EXP_BKUP_DMP=${SID_EXP_DEST}/${SID_EXP_FILE_NAME}
PARFILE="${SID_LOG_DIR}/par_${EXP_TIMESTAMP}.lst"
PIPENAME="${SID_LOG_DIR}/exppipe_${EXP_TIMESTAMP}"
