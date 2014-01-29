#!/usr/bin/perl

## Pull heading info (gyro, mag, gps) and distance

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

	printf "# millis, course, lat, lon, mx, my, mz, gx, gy, gz, lrdist, rrdist, estlat, estlon, esthdg\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
	    next if ($data{"millis"} =~ /^[a-z]/);
		printf "%d,%.1f,%.7f,%.7f,%d,%d,%d,%d,%d,%d,%.3f,%.3f,%.7f,%.7f,%.2f\n", 
			$data{"millis"},
			$data{"course"},
			$data{"lat"}, $data{"lon"},
			$data{"mx"}, $data{"my"}, $data{"mz"},
			$data{"gx"}, $data{"gy"}, $data{"gz"},
			$data{"lrdist"}, $data{"rrdist"},
			$data{"estlat"}, $data{"estlon"}, $data{"estheading"};
	}
	close($fin);

}

