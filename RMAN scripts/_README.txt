Readme.txt for DOL Scripts that run under Solaris 9
(etadb5)prodora05:/usr/oracle> crontab -
#30 1 * * * /usr/oracle/common/bin/ora_db_rman  > /dev/null 2>&1
0 23 * * * /usr/oracle/common/bin/ora_db_backup -e  > /dev/null 2>&1
10 0 * * * /usr/oracle/common/bin/ora_db_backup -h  > /dev/null 2>&1
0 * * * * /usr/oracle/common/bin/ck_db_server.ksh > /dev/null 2>&1
0 6 * * * /usr/oracle/common/bin/ck_filesys.ksh  > /dev/null 2>&1
#0 9 * * 0 /usr/oracle/common/bin/rotate_log.sh >/dev/null 2>&1

ora_db_rman
does rman incremental backups of intances on host
removes archive logs older than a given number of days
generates log and mail

db_lib.ksh
creates sql functions to call from ora_db_rman

rman_funcs.ksh
# Function rman_handle: connect as sysdba and process a rman commands
# and return status of database. Produce a log file /tmp/rman.log
# example: dba_handle "$RMN_CMD"

ora_db_backup
does export or hot backup of databases on host
removes archive logs older than a given number of days
generates log and mail
           -h )  hot backup
           -e )  logical backup (export)
           -? )  help

ck_db_server.ksh
#     The script will loop though all the databases listed in
#     DATABASES_ON_SERVER parameter of backup_env.ksh to check if they
#     are up and running
Modules : ck_tablesps.ksh, backup_env.ksh (shared), db_lib.ksh (shared)

ck_filesys.ksh
#  The script will loop though all mount points in a server, if found
#  any filesystem is certain percentage full, a warning report will be
#  emailed out.

