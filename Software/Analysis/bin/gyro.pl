#!/usr/bin/perl

## Pull gyro data into separate csv

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

	printf "# Millis,GX,GY,GZ,GTemp\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis");
		printf "%d,%d,%d,%d,%d\n", $data{"millis"}, $data{"gx"}, $data{"gy"}, $data{"gz"}, $data{"gtemp"};
	}
	close($fin);

}

