#!/usr/bin/perl

## Pull position, bearing, distance into separate csv

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

	printf "# Millis,estlat,estlon,nextwaypoint,bearing,distance,heading\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis" or $data{"estlat"} == 0);
		printf "%d,%.7f,%.7f,%d,%.2f,%.3f,%.3f\n", 
			$data{"millis"}, 
			$data{"estlat"}, $data{"estlon"},
			$data{"nextwaypoint"}, $data{"bearing"}, $data{"distance"},
			$data{"estheading"};
	}
	close($fin);

}

