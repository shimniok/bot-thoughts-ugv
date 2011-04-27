#!/usr/bin/perl

use Getopt::Std;
use Math::Trig;
push(@INC, '/home/mes/lib/');
require 'fields.pl';
require 'geopos.pl';

my %Options;
#getopts('cb:d:s:', \%Options);

$PI = 3.141592653; # pi

$lat1 = $lat2 = $lon1 = $lon2 = 0;

printf "# Millis Compass GyroHdg GPScourse GPScalcHdg\n";

while (<>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");

  if ($data[$DATE] ne '') {

    ## first time thru we won't do this part
    if (exists $last[$LAT]) {

      ( $heading, $distance ) = brgdist( @last[$LAT], @last[$LON], $data[$LAT], $data[$LON] );
      $heading += 360.0 if ($heading < 0);
      $heading -= 360.0 if ($heading >= 360.0);

      $cgerr = $data[$COMPASS] - $data[$COURSE];
      $cgerr -= 360.0 if ($cgerr > 180.0);
      $cgerr += 360.0 if ($cgerr < -180.0);

      printf "%5d %7.2f %7.2f %7.2f %7.2f %4.1f %3.1f\n", $last[$MILLIS], $last[$COMPASS], $last[$GYROHDG], $data[$COURSE], $heading, $data[$SPEED], $cgerr;

    }
    @last = @data;
  

  }


}
