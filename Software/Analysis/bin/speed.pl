#!/usr/bin/perl

## Pull speed data into separate csv

use Cwd;
use lib "/home/mes/lib";
use DATABUS::FIELDS;

if ($#ARGV < 0) {
  printf "usage: $0 infile\n";
  exit(1);
}

$lastSpeed = 0;
foreach my $file (@ARGV) {

	open my $fin, "<", "$file" || die "cant open $file\n";
	$file =~ tr/A-Z/a-z/;

	printf "# Millis,GPSspeed,lrspeed,rrspeed\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		if ($data{"lat"} == 0) {
			$data{"speed"} = $lastSpeed;
		} else {
			$lastSpeed = $data{"speed"};
		}
		printf "%d,%.2f,%.2f,%.2f\n", $data{"millis"}, $data{"speed"}, $data{"lrspeed"}, $data{"rrspeed"};
	}
	close($fin);

}

