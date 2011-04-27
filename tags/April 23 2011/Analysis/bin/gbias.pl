#!/usr/bin/perl

use Getopt::Std;
use Math::Trig;
push(@INC, '/home/mes/lib/');
require 'fields.pl';

my %opt;
getopts('l:', \%opt);

$lines = $opt{'l'};

if ( !exists $opt{'l'} || $#ARGV < 0 || $lines <= 0) {
  printf STDERR "usage: gbias.pl -l lines filename\n";
  exit 1;
}


$filename = $ARGV[0];

$count = 0;
$sum = 0;

open(FIN, "<$filename") || die "cant open $filename";
while (<FIN>) {
  next if /^\s*Millis/;

  @data = split("\s*,\s*");

  $sum += $data[$GYRO];

  $count++;

  printf "%d %d %d %d\n", $count, $data[$GYRO], $data[$LENC], $data[$RENC];

  last if ($count >= $lines);
}

die "Zero lines found" if ($count == 0);

printf "%.1f %d %.1f\n", $sum, $count, $sum/$count;

exit 0;
