#!/usr/bin/perl

## Pull estimation data out into separate csv

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

	printf "# Millis,course,estheading,estlat,estlon,lat,lon\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		printf "%d,%.1f,%.1f,%.7f,%.7f,%.7f,%.7f\n", $data{"millis"}, $data{"course"}, 
				$data{"estheading"}, $data{"estlat"}, $data{"estlon"}, $data{"lat"}, $data{"lon"};
	}
	close($fin);

}

