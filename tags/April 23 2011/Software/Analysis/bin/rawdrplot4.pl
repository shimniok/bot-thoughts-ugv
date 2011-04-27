#!/usr/bin/perl

## In this version, correct DR position by a fraction of total error vs GPS position with fixed offset

use Getopt::Std;
use Math::Trig;
push(@INC, '/home/mes/lib/');
require 'fields.pl';
require 'geopos.pl';

my %Options;
getopts('cb:d:s:', \%Options);


my $lat, $lon, $glat, $glon;

printf "$#ARGV @ARGV\n";

if ($#ARGV < 0) {
  printf STDERR "usage: rawdrplot.pl [-c] [-d declination] [-s scale] [-b gbias] infile [infile [ ... ]]\n";
  printf STDERR "\t-c use compass not gyro\n\t-d compass declination\n\t-s gyro scale factor\n\t-b gyro bias\n";
  exit 1;
}

$PI = 3.141592653; # pi

$LCIRC=0.321537;
$RCIRC=0.321405;

$lastLeft = -1;
$lastRight = -1;
$tlast = -1;

$lat = 999;
$lon = 999;

## GPS offset / bias
##
$off_bearing  = 0;
$off_distance = -999;
$err_bearing = 0;
$err_distance = -999;

$gsum = 0.0;
$gcnt = 0;
$gbias = 2027;
$decl = 0.0;
$use_compass = 0;

$gbias = $Options{'b'} if (exists $Options{'b'});
$decl  = $Options{'d'} if (exists $Options{'d'});
#$scale  = $Options{'s'} if (exists $Options{'s'});
$use_compass = 1 if (exists $Options{'c'});


for ($i = 0; $i <= $#ARGV; $i++) {

$infile = $ARGV[$i];
$outfile = $ARGV[$i];
$outfile =~ s/[a-z]+([0-9]+).csv/rawdr$1/;
if ($use_compass == 0) {
  ## $outfile .= "_".$gbias."_".$decl."_". $scale*1000 .".csv";
  $outfile .= "_".$gbias."_4.csv";
} else {
  $outfile .= "_c_".$decl."_4.csv";
}

printf "IN: $infile OUT: $outfile\n";


open(FIN, "<$infile") || die "cant open $infile";
open(FOUT, ">$outfile") || die "cant open $outfile";

printf FOUT "Millis, Compass, ldist, rdist, lspeed, tspeed, latitude, longitude\n";

while (<FIN>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");

  $glat = $glon = 0;

  ## GPS
  if ($data[$DATE] ne '') {

    next if ($data[$MILLIS] == 0); ## let the dr stuff initialize position info

    $glat = $data[$LAT];
    $glon = $data[$LON];

    $past = $data[$MILLIS] - 2000;

    printf "past: %d\n", $past;

    if ($past >= 0) {
      ## initialize offset
      if ($off_distance < 0) {
        printf "gps: %.7f %.7f\nhist: %.7f %.7f\n", $glat, $glon, $latHist{$past}, $lonHist{$past};
        ($off_bearing, $off_distance) = brgdist($glat, $glon, $latHist{$past}, $lonHist{$past});
      }

      ## compute gps pos with offset 'subtracted'
      $elat = $glat;
      $elon = $glon;
      move($elat, $elon, $off_bearing, $off_distance);

      ## compute dr error wrt gps less offset
      ($err_bearing, $err_distance) = brgdist($lat, $lon, $elat, $elon);

      $err_bearing += 360.0 if ($err_bearing < 0);
      $err_bearing -= 360.0 if ($err_bearing >= 360.0);

      $err_compass = $compass - $data[$COURSE];
      #$err_compass -= 360.0 if ($err_compass > 180.0);
      #$err_compass += 360.0 if ($err_compass < 180.0);

      printf "Compass Err: C:%.3f - G:%.3f = %.3f\n", $compass, $data[$COURSE], $err_compass;
      printf "DR     : %.7f %.7f\n", $lat, $lon;
      printf "GPS    : %.7f %.7f\n", $glat, $glon;
      printf "GPS-off: %.7f %.7f\n", $elat, $elon;
      printf "eBrg:%.3f eDist:%.5f\n", $err_bearing, $err_distance;

      print "\n\n";
    }
  }

  ## DR
  if ($data[$DATE] eq '') {

    if ($data[$MILLIS] == 0) {
      $lastLeft = $data[$LENC];
      $lastRight = $data[$RENC];
      $tlast = $data[$MILLIS];
      $lat = $data[$LAT];
      $lon = $data[$LON];
      $compass = $data[$COMPASS] - $decl;
    }

    $dt = 0.001 * ($data[$MILLIS] - $tlast);

    $leftCount = $data[$LENC] - $lastLeft;
    $rightCount = $data[$RENC] - $lastRight;

    $ldist = ($LCIRC / 32) * $leftCount;
    $rdist = ($RCIRC / 32) * $rightCount;

    $lspeed = $ldist/$dt if ($dt != 0);
    $rspeed = $rdist/$dt if ($dt != 0);

    if ($use_compass) {

      $compass = ($data[$COMPASS] - $decl) % 360.0;

    } else {

      $gyro = $dt * ($data[$GYRO] - $gbias) / 4.89;
      ## printf "gyro: %.3f\n", $gyro;
      $compass += $gyro;
      $compass %= 360.0;

    }

    #while ($compass < 0)   { $compass += 360.0; }
    #while ($compass > 360) { $compass -= 360.0; }

    printf FOUT "%d, %.1f, %.4f, %.4f, %.4f, %.4f, %.8f, %.8f\n",
                $data[$MILLIS], $compass, $ldist, $rdist, $lspeed, $rspeed, $lat, $lon;

    move($lat, $lon, $compass, ($ldist+$rdist)/2.0);

    ## GPS has 2 seconds lag, so we have to compare error to DR value
    ## from the past to correct future DR values
    $latHist{ $data[$MILLIS] } = $lat;
    $lonHist{ $data[$MILLIS] } = $lon;

    if ($err_distance > 0) {
      ## change DR position based on error
      move($lat, $lon, $err_bearing, ($err_distance * 0.97 * 0.05));
      #printf "DR: %.7f %.7f\nGPS: %.7f %.7f\n", $lat, $lon, $glat, $glon;

      #printf "DR: %.7f %.7f\nGPS: %.7f %.7f\n", $lat, $lon, $glat, $glon;
      #print "\n\n";
    }

    $lastLeft = $data[$LENC];
    $lastRight = $data[$RENC];
    $tlast = $data[$MILLIS];

  }
}
close(FIN);
close(FOUT);

}

