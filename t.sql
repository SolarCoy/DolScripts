#!/bin/ksh
PROC_DIR=$(dirname $0)
. ${PROC_DIR}/backup_env.ksh
. ${PROC_DIR}/db_lib.ksh
CNT=0
while [[ CNT -eg 5 ]] 
do
SQL1="select count(*) from v$session; 
select count(*) from v$session where username='PERMPDXUSER';"
RET_VAL=""
dba_handle "$SQL1"
sleep 60
CNT=$CNT+1
done
/
