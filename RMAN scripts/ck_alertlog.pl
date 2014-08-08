#!/usr/local/bin/perl 
################################################################################
#  Utility : ck_alertlog.pl
#
#  Usage : perl ck_alertlog.pl
#      A daemon process to check alert log file
#  Author : Faying Dong
#  Date :   May 2006
################################################################################
#thanks to Randal Schwartz - www.webreference.com - for daemonize
use strict;
use POSIX qw(setsid);
use Time::Local;
use File::Copy;
use Sys::Hostname;

#my $l_sid;
my $hostname = hostname();
my $home=$ENV{'HOME'};
my $logname="$home/common/bin/ck_alertlog.log";
my $admindir;
my @v_cputtime;
my %Hproctimes;
my $pid;
my $loop=0;
my $init=0;
#sleep time between loops
my $naptime = 10;
my @tstamp;
my $lastdow;
my $hour;
#page hours west coast
#my $pagehours=" 00 01 02 03 04 13 14 15 16 17 18 19 20 21 22 23 ";
#page hours east coast
#my $pagehours=" 00 01 02 03 04 05 06 07 16 17 18 19 20 21 22 23 ";
#pageing off
my $pagehours=" 99 ";
my $err_msg;
my $mailit=0;
my @psline;
my $v_pid;
my $v_comm;
my @v_sid;
my %Hstatus;
my $o_sid;
my $o_home;
my $o_flag;
my $alertlog;
#max number of old alert logs to keep
my $maxlogs = 7;
my $ext;
my $upext;
#name of background dump directory under $admindir/$ORACLE_SID
my $bdump = 'bdump';
# ps command w/ options
my $ps = '/bin/ps -ef';
#location of oratab file
my $oratab = '/var/opt/oracle/oratab';
#my $oratab = '/u01/app/oracle/admin/oratab.test';
#string to grep for in process list to see if SID is up
my $dbproc = 'ora_pmon';
#my $dbproc = 'ora_pmon_slddemo';
#string to match at begining of line for Oracle Errors
my $dberrstr = 'ORA-';
my $altdberrstr = 'Instance terminated by PMON';
my $oraerr;
#string to match in last line of alert_log to see if instance is waiting
#for clint processes to complete
#my $hungstr = 'waiting';
#email addresses to send notice to
my @mailtolist = ('dong.faying@dol.gov','black.michael@dol.gov','anderson.robert@dol.gov','smith.bradford@dol.gov');
#my @mailtolist = ('dong.faying@dol.gov');
my $mailto;
my @pagetolist = ('dong.faying@dol.gov');
my $pageto;
my $pageit = 0;
my $pg_msg;
my @lines;
my $line;
my $element;
my $db;
#where sendmail lives
#my $mailprog = '/usr/lib/sendmail';
my $mailprog = '/bin/mailx';

$| = 1;
# daemonize the program
&daemonize;

while (1) {
@tstamp = split /\s/,scalar localtime;
$hour=(split /:/,$tstamp[3])[0];
$err_msg="@tstamp\n";
$pg_msg="@tstamp\n";

if (open PROCS, "$ps 2>&1`|") {
	while (<PROCS>) {
	chomp;
	next if ! /$dbproc/;
	@psline=split;
	$v_pid=$psline[1];
	$v_comm=$psline[$#psline];
	@v_sid = split /_/, $v_comm;
	$Hstatus{$v_sid[2]}[0]  = $v_pid;
	}
close PROCS;
}
if (open FH, "$oratab") {
	while (<FH>) {
	chomp;
	next if /(\#|\*)/;
	($o_sid,$o_home,$o_flag)=split /:/;
            if (! $Hstatus{$o_sid}[0])  {
		if ($o_flag =~ /(Y|y)/)  {
		$Hstatus{$o_sid}[0]  = -1;
		} else {
		 $Hstatus{$o_sid}[0]  = 0;
		} 
	    } 
	}
close FH;
}
foreach $db (sort keys %Hstatus) {
#location of ORACLE_SID admin dirs
#print "db home $home/.profile_$db\n";
my $obase=`grep ORACLE_BASE= $home/.profile_$db`;
$obase=(split /=/,$obase)[1];
$obase=(split /;/,$obase)[0];
#print "$obase\n";
$admindir = "$obase/admin";
ck_log($db);
}

if ($mailit) {
send_it();
$mailit=0;
}

if ($pagehours =~ /\s$hour\s/) {
	if ($pageit) {
		send_pg();
		$pageit=0;
	}
}

$lastdow=$tstamp[0];
sleep($naptime);
$init=1;
}
################# subs #################
sub ck_log ($) {
my $l_sid = shift;
$#lines=0;
if (opendir BDUMP,"$admindir/$l_sid/$bdump") {
my $alertlog = "$admindir/$l_sid/$bdump/alert_$l_sid.log";
print "$l_sid, $alertlog\n";
	if ($Hstatus{$l_sid}[0] != 0) {
		if (open(LOG, $alertlog)) {
		@lines = <LOG>;
		if ($init) {
			$Hstatus{$l_sid}[1] = $Hstatus{$l_sid}[2]; 
		} else {
			$Hstatus{$l_sid}[1] = $#lines;
		}
		$Hstatus{$l_sid}[2] = $#lines;
		close (LOG);
		}
	}
closedir BDUMP;
}
print " $Hstatus{$l_sid}[2], $Hstatus{$l_sid}[1]), $Hstatus{$l_sid}[0], $init !\n";
if (($Hstatus{$l_sid}[2] > $Hstatus{$l_sid}[1]) && ($Hstatus{$l_sid}[0] != 0) && $init) {
print " $Hstatus{$l_sid}[2], $Hstatus{$l_sid}[1]), $Hstatus{$l_sid}[0], $init !\n";
	$element = $Hstatus{$l_sid}[1];
	while ($element < $#lines) {
		if (($lines[$element] =~ /^$dberrstr/)||($lines[$element] =~ /^$altdberrstr/)) {
			$mailit=1;
			$pageit=1;
		 	$oraerr = (split /\s/,$lines[$element])[0];
			if  ((!$pg_msg)||(!($pg_msg =~ /$oraerr/))) {	
			if ($lines[$element-2] =~ /^[A-Z][a-z][a-z]\s[A-Z][a-z][a-z]\s\d\d\s\d\d:\d\d:\d\d\s\d\d\d\d/) {
			 $err_msg .= "$l_sid - $lines[$element-1]";
			}
			if (($lines[$element-1] =~ /^[A-Z][a-z][a-z]\s[A-Z][a-z][a-z]\s\d\d\s\d\d:\d\d:\d\d\s\d\d\d\d/) || ($lines[$element-1] =~ /^Errors\sin\sfile/)) {
			 $err_msg .= "$l_sid - $lines[$element-1]";
			}
			 $err_msg .= "$l_sid - $lines[$element]";
			 $pg_msg .= "$l_sid - $oraerr\n";
			}
		}	
	$element++;
	}
	if ($lines[$#lines] =~ /^SHUTDOWN:\swaiting/) {
		$err_msg .= "$l_sid - possibly hung\n";
		$err_msg .= "$l_sid - $lines[$#lines]";
		kill_hung($l_sid);
		$mailit=1;
	}
}
}

sub daemonize {
if (!-f $logname) {
    system("touch $logname");
}

    chdir '/'                 or die "Can't chdir to /: $!";
    open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    open STDOUT, '>>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>>/dev/null' or die "Can't write to /dev/null: $!";
#    open STDIN, '/tmp/ck_alertlog.log'   or die "Can't read $logname: $!";
#    open STDOUT, '>>/tmp/ck_alertlog.log' or die "Can't write to $logname: $!";
#    open STDERR, '>>/tmp/ck_alertlog.log' or die "Can't write to $logname: $!";
    defined(my $pid = fork)   or die "Can't fork: $!";
    exit if $pid;
    setsid                    or die "Can't start a new session: $!";
    umask 0;
   # umask 22;
}

sub send_it () {
print "here ?";
    if (open(MAIL,"|$mailprog -s $hostname' - Alert Log Information!' -t")) {
    print  MAIL 'To: ';
	foreach $mailto (@mailtolist) {
		if ($mailto =~ /$mailtolist[$#mailtolist]/) {
    		print  MAIL "$mailto\n";
		} else {
    		print  MAIL "$mailto,";
		}
	}
    print MAIL "\n";
    print MAIL "$err_msg\n";
    close MAIL;
    }
}

sub send_pg () {
    if (open(MAIL,"|$mailprog -s $hostname' - Alert Log Information!' -t")) {
    print  MAIL 'To: ';
        foreach $pageto (@pagetolist) {
                if ($pageto =~ /$pagetolist[$#pagetolist]/) {
                print  MAIL "$pageto\n";
                } else {
                print  MAIL "$pageto,";
                }
        }
    print MAIL "\n";
    print MAIL "$pg_msg\n";
    close MAIL;
    }
}


sub kill_hung () {
my $l_sid = shift;
print "$l_sid\n";
if (open PROCS, "$ps 2>&1`|") {
        while (<PROCS>) {
        chomp;
        next if ! /oracle$l_sid\s\(LOCAL=NO\)/;
        my @psline=split;
        my @v_cputime= split /:/,$psline[$#psline-2];
	$Hproctimes{$psline[1]} = $v_cputime[0]*60+$v_cputime[1];
        }
close PROCS;
}

foreach $pid (sort keys %Hproctimes) {
	if (kill 0 => $pid) {
		kill 9 => $pid;
	$err_msg .= "Process $pid killed! - cpu time $Hproctimes{$pid}\n";
	}
}

}

