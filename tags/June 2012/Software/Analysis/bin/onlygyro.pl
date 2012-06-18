#!/usr/bin/perl

## Pull heading info (gyro, gps) plus position and distance to support
## prototyping use of gyro only for heading, with gps heading as bias correction
## and possibly gps position to help correct as well.

use Cwd;
use lib "/home/mes/lib";
use DATABUS::FIELDS;

if ($#ARGV < 0) {
  printf "usage: $0 infile\n";
  exit(1);
}

foreach my $file (@ARGV) {

	open my $fin, "<", "$file" || die "cant open $file\n";
	$file =~ tr/A-Z/a-z/;

	printf "# millis, course, lat, lon, gx, gy, gz, lrdist, rrdist, estlat, estlon\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		if ($data{"lat"} == 0 || $data{"lon"} == 0) {
			$data{"lat"} = $data{"lon"} = 'nan';
		}
		printf "%d,%.1f,%.7f,%.7f,%d,%d,%d,%.3f,%.3f,%.7f,%.7f\n", 
			$data{"millis"},
			$data{"course"},
			$data{"lat"}, $data{"lon"},
			$data{"gx"}, $data{"gy"}, $data{"gz"},
			$data{"lrdist"}, $data{"rrdist"},
			$data{"estlat"}, $data{"estlon"};
	}
	close($fin);

}

