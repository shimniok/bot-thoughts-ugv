#!/usr/bin/perl

use Cwd;
push(@INC, '/home/mes/lib/');
require 'fields.pl';
require 'geopos.pl';

## Need to generate gps files separate from faster rate files
## Then create gnuplot script to generate separate image file plots for each set of data
## Then create HTML files to display all the plots
## Then add to an HTML catalog file showing all the plots based on log data filename (e.g., LOGGER25.CSV -> logger25.html)

if ($#ARGV < 0) {
  printf "usage: plotter.pl infile\n";
  exit(1);
}

$heading = -999;
$tlast = 0;
$heading_calibrate = 0;
$null = 2027;
$drift = 0; # -0.075;
$scale = 4.89; ## scaled to be AVcc independent
## 5.91; ## in mv per degree per millisecond, 6mv/deg/sec

open(FIN, "<$ARGV[0]") || die "cant open $ARGV[0]\n";

$ARGV[0] =~ tr/A-Z/a-z/;

## Filter out the GPS fix data into a csv for GPSVisualizer
##
$gps1file = $ARGV[0];
$gps1file =~ s/[a-z]+([0-9]+.csv)/gps1$1/;
open(GPS1, ">$gps1file") || die "cant open $gps1file\n";
printf GPS1 "%8s, %10s, %10s, %10s\n", 'Time(ms)', 'Latitude', 'Longitude', 'HDOP';

$gps2file = $ARGV[0];
$gps2file =~ s/[a-z]+([0-9]+.csv)/gps2$1/;
open(GPS2, ">$gps2file") || die "cant open $gps2file\n";
printf GPS2 "%8s, %10s, %10s, %10s\n", 'Time(ms)', 'Latitude', 'Longitude', 'HDOP';

## Filter out dead reckoning coordinates into csv for GPSVisualizer
##
$drfile = $ARGV[0];
$drfile =~ s/[a-z]+([0-9]+.csv)/dr$1/;
open(DR, ">$drfile") || die "cant open $drfile\n";
printf DR "%8s, %10s, %10s\n", 'Time(ms)', 'Latitude', 'Longitude';

## Translate the csv into a simple data file for gnuplot
##
$outfile = basename($ARGV[0]) . ".dat";
$outfile =~ s/^[a-z]+([0-9]+.dat)/plot$1/;

open(DAT, ">$outfile") || die "cant open $outfile\n";
printf DAT "# %8s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n", 
       'Time(ms)', 'GyroHdg', 'Gyro', 'Compass', 'Course1', 'Speed1', 'HDOP1',
       'Enc Speed', 'Course2', 'Speed2', 'HDOP2', 'CalcHdgGPS2', 'HdgErr';

## Create a gnuplot script
##
$pltfile = basename($ARGV[0]) . ".plt";

## Generate an HTML file wrapper
##
$htmlfile = basename($ARGV[0]) . ".htm";

printf "Generating GPS and DAT files\n";

$glast = -1;

$past = 0;
$lastlat = 0;
$lastlon = 0;

while (<FIN>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");

  next if (/^ERR:/);

  ## Convert gyro to heading
  ##
  $delta_t = $data[$MILLIS] - $tlast;				## time delta for integration
  $deg_per_sec = ($data[$GYRO] - $null) / $scale;

  ## simple integration of reported gyro signal
  $heading += $delta_t * $deg_per_sec / 1000.0;				## delta_t is in ms

  ## Use onboard, reported gyro heading
  ##
  $heading = $data[$GYROHDG];

  ## trapezoidal rule / 1st order interpolation fctn
  ## data point 0 isn't going to have a last value
  ## which will throw off the integration initially
  ##
  #$glast = $deg_per_sec if ($glast < 1);
  #$heading += ($deg_per_sec+$glast)/2 * $delta_t + $drift;		## delta_t is in ms
  #$glast = $deg_per_msec;

  $heading -= 360.0 if ($heading >= 360.0);
  $heading += 360.0 if ($heading < 0); 
  $tlast = $data[$MILLIS];

  ## Calibrate Gyro to first compass reading
  if ($heading < 0) {
    $heading = $data[$COMPASS];
  }


  if ($data[$DATE] ne '') {
    ## print gps and gyro data

    if ($data[$GPSID] eq 'GPS2') {
      if ($lastlat > 0) {
	($gpscourse, $dist) = brgdist($lastlat, $lastlon, $data[$LAT], $data[$LON]);
	$gpscourse += 360.0 if ($gpscourse < 0);
      } else {
	$gpscourse = $data[$COURSE];
      }
      printf DAT "%10.5f %10s %10s %10s %10s %10s %10s %10s %10.1f %10.1f %10.1f %10.1f\n",
#                 $data[$MILLIS] / 1000.0,
                 $past / 1000.0,
                 'NaN', 'NaN', 'NaN',
                 'NaN', 'NaN', 'NaN',
                 'NaN',
                 $data[$COURSE], $data[$SPEED], $data[$HDOP], $gpscourse;
      printf GPS2 "%8s, %10.6f, %10.6f, %10.1f\n",
	$data[$MILLIS], $data[$LAT], $data[$LON], $data[$HDOP];
    }
    $past = $data[$MILLIS];
    $lastlat = $data[$LAT];
    $lastlon = $data[$LON];

  } else {
    ## print gyro data only
    ## rather than merge two records, just print the gyro + gps record 
    ##
    printf DAT "%10.5f %10.1f %10.2f %10.1f %10s %10s %10s %10.1f %10s %10s %10s\n",
	       $data[$MILLIS] / 1000.0,
               $heading, $data[$GYRO], $data[$COMPASS],
              'NaN', 'NaN', 'NaN',
              $data[$SPEED+1],		## bug in data saving?
              'NaN', 'NaN', 'NaN';
    printf DR "%8s, %10.6f, %10.6f\n", $data[$MILLIS], $data[$LAT], $data[$LON];
  }

}

close(DAT);
close(GPS1);
close(GPS2);
close(DR);
close(FIN);


## Do the GNUPLOT stuff
##
##
printf "Generating gnuplot scripts\n";
open(PLT, ">$pltfile") || die "cant open pipe\n";
printf PLT "set autoscale\n";
printf PLT "set terminal png size 800,600\n";

## Plot Heading Data
$hdgimg = basename($ARGV[0]) . '_hdg.png';
printf "Generating $hdgimg\n";
printf PLT "set output \"$hdgimg\"\n";
print PLT "set title 'Heading Data'\n";
printf PLT "plot \"$outfile\" using 1:5 title 'GPS1 Course' with lines, \"\" using 1:9 title 'GPS2 Course' with lines, \"\" using 1:4 title 'Compass' with lines, \"\" using 1:2 title 'Gyro Hdg' with lines\n";

## Plot HDOP
$hdopimg = basename($ARGV[0]) . '_hdop.png';
printf "Generating $hdopimg\n";
printf PLT "set output \"$hdopimg\"\n";
print PLT "set title 'GPS1 HDOP'\n";
printf PLT "plot \"$outfile\" using 1:7 title 'HDOP1' with lines, \"\" using 1:11 title 'HDOP2' with lines\n";

## Plot Speed
$speedimg = basename($ARGV[0]) . '_spd.png';
printf "Generating $speedimg\n";
print PLT "set output \"$speedimg\"\n";
print PLT "set title 'Vehicle Speed'\n";
print PLT "plot \"$outfile\" using 1:6 title 'GPS1 Speed (mph)' with lines, \"\" using 1:10 title 'GPS2 Speed (mph)' with lines, \"\" using 1:8 title 'Enc Speed (m/s)' with lines axes x1y2\n";
close(PLT);

printf "Generating HTML wrapper\n";

## Now make an HTML with all this stuff in it
##
open(HTML, ">$htmlfile") || die "cant open $htmlfile\n";
printf HTML "<html><head><title>".basename($ARGV[0])."</title></head>\n";
printf HTML "<body><h1>".basename($ARGV[0])."</h1>\n";
printf HTML "<h2>Data Files</h2>\n";
printf HTML "<a href=\"$outfile\">$outfile</a> | ";
printf HTML "<a href=\"$gps1file\">$gps1file</a> | ";
printf HTML "<a href=\"$pltfile\">$pltfile</a>\n";
printf HTML "<h2>Heading</h2>\n";
printf HTML "<img src=\"$hdgimg\"/>\n";
printf HTML "<h2>Speed</h2>\n";
printf HTML "<img src=\"$speedimg\"/>\n";
printf HTML "<h2>HDOP</h2>\n";
printf HTML "<img src=\"$hdopimg\"/>\n";
printf HTML "</body></html>\n";
close(HTML);

printf "Generating PNG files with gnuplot and launching Google Chrome...\n";

open(BAT, ">tmp.bat") || die "cant open batch file";
#printf BAT "\"C:\\Program Files\\gnuplot\\bin\\wgnuplot.exe\" %CD%\\$pltfile\r\n";
#print "\"C:\\Program Files\\gnuplot\\bin\\wgnuplot.exe\" %CD%\\$pltfile\r\n";
printf BAT "\"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe\" \"file://%CD%/$htmlfile\"\r\n";
print "\"C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe\" \"file://%CD%/$htmlfile\"\r\n";
close(BAT);

my $pid = fork();
if ($pid) {

  # parent
  waitpid($pid,0);
  system("cmd /c tmp.bat");
  printf "Done.\n";
  exit 0;

} elsif ($pid == 0) {

  # child
  print getcwd,"\n";
  exec("/cygdrive/c/Program\ Files/gnuplot/bin/wgnuplot", "$pltfile");
  exit 0;

} else {
  die "couldnt fork: $!\n";
}



## Get the basename of a filename, ie, strip the extension
##
sub basename($) {
  my $file = shift;
  $file =~ s!^(?:.*/)?(.+?)(?:\.[^.]*)?$!$1!;
  return $file;
}

