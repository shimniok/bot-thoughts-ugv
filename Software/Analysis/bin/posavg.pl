#!/usr/bin/perl

push(@INC, '/home/mes/lib/');

require 'geopos.pl';

$PI=3.141592653589793238;

$GPSWT = 0.25;

if ($#ARGV < 1) {
  printf STDERR "Usage: posavg.pl gpsfile drfile\n";
  exit 1;
}

open(GPS, "<$ARGV[0]") || die "cant open gps file";
open(DR,  "<$ARGV[1]") || die "cant open dr file";

print "Time(ms), Latitude, Longitude\n";

while (<GPS>) {

  s/^\s+//;
  ($gmillis, $lat1, $lon1, $hdop, $junk) = split(/\s*,\s*/);

  while (<DR>) {
    @data = split(/\s*,\s*/);
    $millis = $data[0];
    $lat2 = $data[6];
    $lon2 = $data[7];

    ## Weight GPS according to HDOP, primarily
    ##
    ## Anything over 2.0 is nearly worthless
    ##

    ## 0.2 = 1/5 because there are 5 dr samples per gps sample, want to divide the error
    ## over next 5 dr samples so movement is less jerky

    #move($lat2, $lon2, $err_bearing * $GPSWT * 0.2, $err_distance * $GPSWT * 0.2);
    #printf "%d, %.7f, %.7f\n", $millis, $lat3, $lon3;
    #printf "%d, %.7f, %.7f, %.1f\n";

    last if ($millis == $gmillis);
  }

  ## Compute new error bearing and distance
  ##
  #if ($hdop < 2.0) {
    ($err_bearing, $err_distance) = brgdist($lat1, $lon1, $lat2, $lon2);
    printf "Err brg: %.2f  Err dist: %.5f\n", $err_bearing, $err_distance;
  #}

}

close(GPS);
close(DR);

#  if ($hdop > 2.0) {
#    $GPSWT = 0.05;
#  } elsif ($hdop < 1.0) {
#    $GPSWT = 0.75;
#  } else {
#    $GPSWT = 0.75 / $hdop;
#  }

