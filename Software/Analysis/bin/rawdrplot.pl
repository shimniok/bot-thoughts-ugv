#!/usr/bin/perl

use Getopt::Std;
use Math::Trig;
push(@INC, '/home/mes/lib/');
require 'fields.pl';
require 'geopos.pl';

my %Options;
getopts('ogcb:d:s:t:m:', \%Options);

printf "$#ARGV @ARGV\n";

sub usage() {
  printf STDERR "usage: rawdrplot.pl [-c|-o|-g] [-d declination] [-s scale] [-b gbias] [-t trackwidth] infile [infile [ ... ]]\n";
  printf STDERR "\t-c use compass\n\t-g use gyro\n\t-o use odometry\n\t-d compass declination\n\t-s gyro scale factor\n\t-b gyro bias\n\t-t track width\n";
  exit 1;
}

usage() if ($#ARGV < 0);

$PI = 3.141592653; # pi

$LCIRC=0.321537;
$RCIRC=0.321405;
$ACIRC=($LCIRC+$RCIRC)/2.0;

$lastLeft = -1;
$lastRight = -1;
$tlast = -1;

$lat = 999;
$lon = 999;

$gsum = 0.0;
$gcnt = 0;
$gbias = 2027;
$decl = 0.0;
$scale = 4.89; #0.00591;
$track = 0.280;
$use_compass = 0;
$mult = 1.0;

$gbias = $Options{'b'} if (exists $Options{'b'});
$decl  = $Options{'d'} if (exists $Options{'d'});
$scale = $Options{'s'} if (exists $Options{'s'});
$track = $Options{'t'} if (exists $Options{'t'});
$mult  = $Options{'m'} if (exists $Options{'m'});

if (exists $Options{'c'}) {

  $use_compass  = 1;
  $use_gyro     = 0;
  $use_odometry = 0;

} elsif (exists $Options{'g'}) {

  $use_compass  = 0;
  $use_gyro     = 1;
  $use_odometry = 0;

} elsif (exists $Options{'o'}) {

  $use_compass  = 0;
  $use_gyro     = 0;
  $use_odometry = 1;

} else {
  usage();
  exit(1);
}

for ($i = 0; $i <= $#ARGV; $i++) {

$infile = $ARGV[$i];
$outfile = $ARGV[$i];
$outfile =~ s/[a-z]+([0-9]+).csv/rawdr$1/;
if ($use_gyro == 1) {
  $outfile .= "_".$gbias."_". $scale .".csv";
} elsif ($use_compass == 1 ) {
  $outfile .= "_c_".$decl.".csv";
} elsif ($use_odometry == 1) {
  $outfile .= "_o_".int($track*1000)."_".$decl."_".$mult.".csv";
}

printf STDERR "IN: $infile OUT: $outfile\n";
printf STDERR "gbias: %d\n", $gbias;


open(FIN, "<$infile") || die "cant open $infile";
open(FOUT, ">$outfile") || die "cant open $outfile";

printf FOUT "Millis, Compass, ldist, rdist, lspeed, tspeed, latitude, longitude\n";

$past = 0;

while (<FIN>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");

  if ($data[$DATE] ne '') {

    if ($past > 0) {
      $compass_err = $compass_hist{$past} - $data[$COURSE];
      $compass += $compass_err;
    }
    
    printf "%d %d Course: %.2f Compass: %.2f Error: %.2f\n", $past, $data[$MILLIS], $data[$COURSE], $compass_hist{$past}, $compass_err;

    $past = $data[$MILLIS];

  } else {

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

    $ldist = ($ACIRC / 32) * $leftCount;
    $rdist = ($ACIRC / 32) * $rightCount;

    $lspeed = ($dt != 0) ? $ldist/$dt : 0;
    $rspeed = ($dt != 0) ? $rdist/$dt : 0;

    if ($use_compass) {

      $compass = ($data[$COMPASS] - $decl) % 360.0;

    } elsif ($use_gyro) {

      ##printf STDERR "Speed: %.2f %.2f\n", $lspeed, $rspeed;
      if   ($lspeed > 0.01 && $rspeed > 0.01) {
        $gyro = $dt * ($data[$GYRO] - $gbias) / $scale;
        ## printf "gyro: %.3f\n", $gyro;
        $compass += $gyro;
        $compass += 360.0 if ($compass < 0);
        $compass -= 360.0 if ($compass >= 360.0);
      }
    } elsif ($use_odometry) {
      $ldistsum += $ldist;
      $rdistsum += $rdist;

      $drad = ($ldistsum - $rdistsum) / $track;
      $ddeg = degrees( $drad ) * $mult;
      # sanity check
      if (abs($ddeg) < 8.0) {
	$compass += $ddeg;
	$compass += 360.0 if ($compass < 0);
	$compass -= 360.0 if ($compass >= 360.0);
      }
      #printf "%d left: %.8f right: %.8f compass: %.8f delta: %.8f %.8f\n", $data[$MILLIS], $ldist, $rdist, $compass, $drad, $ddeg;
	
    } else {
       die "wtf is going on here?";
    } 

    $compass_hist{$data[$MILLIS]} = $compass;

    #while ($compass < 0)   { $compass += 360.0; }
    #while ($compass > 360) { $compass -= 360.0; }

    printf FOUT "%d, %.1f, %.4f, %.4f, %.4f, %.4f, %.8f, %.8f\n",
                $data[$MILLIS], $compass, $ldist, $rdist, $lspeed, $rspeed, $lat, $lon;

    move($lat, $lon, $compass, ($ldist+$rdist)/2.0);

    $lastLeft = $data[$LENC];
    $lastRight = $data[$RENC];
    $tlast = $data[$MILLIS];

  }
  
}
close(FIN);
close(FOUT);

}
