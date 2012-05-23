#!/usr/bin/perl

## Pull heading-related variables out: GPS course, Magnetometer, gyro, estimated heading

use Cwd;
use lib "/home/mes/lib";
use DATABUS::FIELDS;

if ($#ARGV < 0) {
  printf "usage: $0 infile\n";
  exit(1);
}

$lastCourse = 0;
foreach my $file (@ARGV) {

	open my $fin, "<", "$file" || die "cant open $file\n";
	$file =~ tr/A-Z/a-z/;

	printf "# Millis,course,mx,my,mz,estheading\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		if ($data{"lat"} == 0 || $data{"lon"} == 0) {
			$data{"course"} = $lastCourse;
		} else {
			$lastCourse = $data{"course"};
		}

		printf "%d,%.1f,%d,%d,%d,%d,%.2f\n", $data{"millis"}, $data{"course"}, $data{"mx"}, $data{"my"}, $data{"mz"}, $data{"gz"}, $data{"estheading"};
	}
	close($fin);

}

