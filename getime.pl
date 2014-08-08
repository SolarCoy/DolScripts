#!/bin/perl
use Time::HiRes;
$ts= [Time::HiRes::gettimeofday];
$tp = Time::HiRes::tv_interval($ts, [Time::HiRes::gettimeofday]);
system(ls);
$td = Time::HiRes::tv_interval($ts, [Time::HiRes::gettimeofday]);
$df=($td - $tp);
print "df $df\n";
