#!/usr/bin/perl


$PI = 3.14159265358979323;

printf "%s\t%s\t%s\t%s\n", "Sec", "MagX", "MagY", "MagZ", "2D Hdg";
$sec = 0.0;
while (<>) {

  ( $magx, $magy, $magz ) = split( /,/ );
  printf "%f\t%f\t%f\t%f\t%f\n", $sec, $magx, $magy, $magz, 180 * atan2($magy,$magx) / $PI;

  $sec += 0.10;

}
