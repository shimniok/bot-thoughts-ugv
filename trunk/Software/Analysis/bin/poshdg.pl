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

	printf "# millis, course, lat, lon, mx, my, mz, gx, gy, gz, lrdist, rrdist\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		printf "%d,%.1f,%.5f,%.5f,%d,%d,%d,%d,%d,%d,%.3f,%.3f\n", 
			$data{"millis"},
			$data{"course"},
			$data{"lat"}, $data{"lon"},
			$data{"mx"}, $data{"my"}, $data{"mz"},
			$data{"gx"}, $data{"gy"}, $data{"gz"},
			$data{"lrdist"}, $data{"rrdist"};
	}
	close($fin);

}

