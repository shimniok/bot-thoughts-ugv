#!/usr/bin/perl

use Getopt::Std;
use Math::Trig;
push(@INC, '/home/mes/lib/');
require 'fields.pl';

$PI = 3.141592653; # pi

$LCIRC=0.321537;
$RCIRC=0.321405;
$ACIRC=($LCIRC+$RCIRC)/2.0;
$track = 0.280;

$lastLeft = -1;
$lastRight = -1;
$tlast = -1;

while (<>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");
  next if (/^ERR:/ );

  if ($data[$DATE] eq '') {

    if ($data[$MILLIS] == 0) {
      $lastLeft = $data[$LENC];
      $lastRight = $data[$RENC];
      $tlast = $data[$MILLIS];
    }

    $dt = 0.001 * ($data[$MILLIS] - $tlast);

    $leftCount = $data[$LENC] - $lastLeft;
    $rightCount = $data[$RENC] - $lastRight;

    $ldist = ($ACIRC / 32) * $leftCount;
    $rdist = ($ACIRC / 32) * $rightCount;

    $lspeed = ($dt != 0) ? $ldist/$dt : 0;
    $rspeed = ($dt != 0) ? $rdist/$dt : 0;

    printf "%d %.4f %.4f %.4f %.4f NaN\n", $data[$MILLIS], $ldist, $rdist, $lspeed, $rspeed;

    $lastLeft = $data[$LENC];
    $lastRight = $data[$RENC];
    $tlast = $data[$MILLIS];

  } else {
    printf "%d NaN NaN NaN NaN %.4f\n", $data[$MILLIS], $data[$SPEED]; #bug on mbed
  }
  
}
