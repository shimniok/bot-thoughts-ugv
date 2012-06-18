#!/usr/bin/perl

## Pull speed data into separate csv

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

	printf "# Millis,lat,lon,course,speed,hdop,sats\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis" || $data{"lat"} == 0);
		printf "%d,%.7f,%.7f,%.1f,%.1f,%.1f,%d\n", $data{"millis"}, $data{"lat"}, $data{"lon"}, $data{"course"}, $data{"speed"}, $data{"hdop"}, $data{"sats"};
	}
	close($fin);

}

