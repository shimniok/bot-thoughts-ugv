#!/usr/bin/perl

## Pull GPS course, Magnetometer values into separate csv

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

	printf "# Millis,Course,MX,MY,MZ,A,lat,lon\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
	    next if ($data{"millis"} =~ /^[a-z]/);
		next if ($data{"lat"} == 0);
		printf "%d,%.1f,%d,%d,%d,%.2f,%.6f,%.6f\n", 
			$data{"millis"}, 
			$data{"course"}, 
			$data{"mx"}, $data{"my"}, $data{"mz"}, 
			$data{"current"}, 
			$data{"lat"}, $data{"lon"};
	}
	close($fin);

}

