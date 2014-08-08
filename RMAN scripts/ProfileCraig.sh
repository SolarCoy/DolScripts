EDITOR=/bin/vi
VISUAL=/bin/vi
GNUBIN=/opt/gnu/bin
MODETPE=normal
OPENWIN=/usr/openwin
PRINTER=
LPDEST=
TERMINFO=/usr/share/lib/terminfo
TMPDIR=/tmp
JAVA_HOME=/usr/j2se
ANT_HOME=/opt/ant
export HOSTNAME
export HISTSIZE
export ENV
export MAIL
export PATH
export MANPATH
export EDITOR
export VISUAL
export GNUBIN
export MODETPE
export OPENWIN
export PRINTER
export LPDEST
export TABSET
export TERMINFO
export TMPDIR
export JAVA_HOME
export ANT_HOME

umask 027

set -o vi

# set the look of the prompt
export WHO=`id | awk -F"(" '{print $2}' | awk -F")" '{print $1}'`

if [ $WHO != "root" ]
then
        export PS1='$HOSTNAME $WHO-$PWD $ '
else
        export PS1='$HOSTNAME $WHO-$PWD # '
fi

#    The following set for Harvest on devcm
ORACLE_HOSTNAME=devcm.doleta.gov
ORACLE_BASE=/u01/app/oracle/product/10.2.0
ORACLE_HOME=/u01/app/oracle/product/10.2.0/db_1
ORACLE_SID=harvest
tk2DEV=vt100
CA_SCM_HOME=/opt/CA/scm
PATH=$PATH:/usr/local/bin
PATH=$PATH:$ORACLE_HOME/bin:$CA_SCM_HOME/bin:/opt/CA/pec
LD_LIBRARY_PATH=$CA_SCM_HOME/lib:/usr/lib:/usr/dt/lib:/usr/openwin/lib:/opt/ICS/Motif/usr/lib:/usr/local/lib:/usr/sfw/lib
LM_LICENSE_FILE=$CA_SCM_HOME/license/license.dat
export  ORACLE_HOSTNAME
export  ORACLE_BASE
export  ORACLE_HOME
export  ORACLE_SID
export  tk2DEV
export  PATH
export  LD_LIBRARY_PATH
export  LM_LICENSE_FILE
