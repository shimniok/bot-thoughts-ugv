#!/usr/bin/perl

use Cwd;
require 'fields.pl';

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
$null = 2028;
$drift = 0; # -0.075;
$scale = 5.91; ## in mv per degree per millisecond, 6mv/deg/sec

open(FIN, "<$ARGV[0]") || die "cant open $ARGV[0]\n";

$ARGV[0] =~ tr/A-Z/a-z/;

## Filter out the GPS fix data into a csv for GPSVisualizer
##
$gpsfile = $ARGV[0];
$gpsfile =~ s/[a-z]+([0-9]+.csv)/gps$1/;

open(GPS, ">$gpsfile") || die "cant open $gpsfile\n";
printf GPS "%8s, %10s, %10s, %10s\n", 'Time(ms)', 'Latitude', 'Longitude', 'HDOP';

## Translate the csv into a simple data file for gnuplot
##
$outfile = basename($ARGV[0]) . ".dat";
$outfile =~ s/^[a-z]+([0-9]+.dat)/plot$1/;

open(DAT, ">$outfile") || die "cant open $outfile\n";
printf DAT "# %8s %10s %10s %10s %10s %10s %10s\n", 'Time(ms)', 'GyroHeading', 'Gyro', 'Compass', 'Course', 'Speed', 'HDOP';

## Create a gnuplot script
##
$pltfile = basename($ARGV[0]) . ".plt";

## Generate an HTML file wrapper
##
$htmlfile = basename($ARGV[0]) . ".htm";

printf "Generating GPS and DAT files\n";

$glast = -1;

while (<FIN>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  next if ($data[$MILLIS] eq "Millis");


  ## Convert gyro to heading
  ##
  $delta_t = $data[$MILLIS] - $tlast;				## time delta for integration
  $volts = ($data[$GYRO] - $null) * 5.0 / 4096.0;			## convert to volts based on 5V range, 12-bit ADC

  $deg_per_msec = $volts / $scale;

  ## trapezoidal rule / 1st order interpolation fctn
  ## data point 0 isn't going to have a last value
  ## which will throw off the integration initially
  ##
  $glast = $deg_per_msec if ($glast < 1);
  $heading += ($deg_per_msec+$glast)/2 * $delta_t + $drift;		## delta_t is in ms
  $glast = $deg_per_msec;

  $heading -= 360.0 if ($heading >= 360.0);
  $heading += 360.0 if ($heading < 0); 
  $tlast = $data[$MILLIS];

  ## Calibrate Gyro to first compass reading
  if ($heading < 0) {
    $heading = $data[$COMPASS];
  }

  ## print gyro data only
  printf DAT "%10.5f %10d %10.2f %10.1f %10s %10s %10s\n", $data[$MILLIS] / 1000.0, $heading, $data[$GYRO], $data[$COMPASS], 'NaN', 'NaN', 'NaN';

  if ($data[$LAT] ne '') {
    ## print gps and gyro data
    printf DAT "%10.5f %10s %10s %10s %10d %10.1f %10.1f\n", $data[$MILLIS] / 1000.0, 'NaN', 'NaN', 'NaN', $data[$COURSE], $data[$SPEED], $data[$HDOP];
    printf GPS "%8s, %10.6f, %10.6f, %10.1f\n", $data[$MILLIS], $data[$LAT], $data[$LON], $data[$HDOP];
  }

}

close(DAT);
close(GPS);
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
printf PLT "plot \"$outfile\" using 1:4 title 'Compass' with lines, \"\" using 1:5 title 'GPS Course' with lines, \"\" using 1:2 title 'Gyro Hdg' with lines\n";

## Plot HDOP
$hdopimg = basename($ARGV[0]) . '_hdop.png';
printf "Generating $hdopimg\n";
printf PLT "set output \"$hdopimg\"\n";
printf PLT "plot \"$outfile\" using 1:7 title 'HDOP' with lines\n";

## Plot Speed
$speedimg = basename($ARGV[0]) . '_spd.png';
printf "Generating $speedimg\n";
print PLT "set output \"$speedimg\"\n";
print PLT "plot \"$outfile\" using 1:6 title 'GPS Speed' with lines\n";
close(PLT);

printf "Generating HTML wrapper\n";

## Now make an HTML with all this stuff in it
##
open(HTML, ">$htmlfile") || die "cant open $htmlfile\n";
printf HTML "<html><head><title>".basename($ARGV[0])."</title></head>\n";
printf HTML "<body><h1>".basename($ARGV[0])."</h1>\n";
printf HTML "<h2>Data Files</h2>\n";
printf HTML "<a href=\"$outfile\">$outfile</a> | ";
printf HTML "<a href=\"$gpsfile\">$gpsfile</a> | ";
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

