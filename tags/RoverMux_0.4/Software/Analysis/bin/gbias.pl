#!/usr/bin/perl

## Pull gyro bias

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

	printf "# Millis,gbias,errAngle\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
	    next if ($data{"millis"} =~ /^[a-z]/);
		next if ($data{"course"} == 0);
		printf "%d,%.6f,%.6f,%.2f,%.2f\n", 
			$data{"millis"}, 
			$data{"gbias"}, $data{"errangle"},
			$data{"course"}, $data{"gheading"};
	}
	close($fin);

}

