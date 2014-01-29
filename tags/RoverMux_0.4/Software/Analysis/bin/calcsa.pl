#!/usr/bin/perl

## Pull position, bearing, distance into separate csv

use Cwd;
use lib "/home/mes/lib";
use DATABUS::FIELDS;
use Math::Trig;

if ($#ARGV < 0) {
  printf "usage: $0 infile\n";
  exit(1);
}

sub calcsa {
	( $theta ) = @_;
	
	$wheelbase = 0.290;
	$track = 0.280;  
	
	$neg = ($theta < 0);
	$theta *= -1.0 if ($neg == 1);    
	$theta = 90.0 if ($theta > 90.0);
	$radius = 3.0/(2*sin( $theta * 3.141529 / 180.0 ));
	$SA = (180.0 / 3.141529) * asin($wheelbase / ($radius - $track/2));
	$SA *= -1.0 if ($neg == 1);
	
	return $SA;
}


foreach my $file (@ARGV) {

	open my $fin, "<", "$file" || die "cant open $file\n";
	$file =~ tr/A-Z/a-z/;

	printf "# Millis,estlat,estlon,nextwaypoint,bearing,distance,heading\n";
	while (<$fin>) {
		s/[\r\n]+//g;
		my %data = parseFields($_);
		next if ($data{"millis"} eq "Millis" or $data{"estlat"} == 0);
		printf "%d, %.3f, %.3f, %.3f\n", 
			$data{"millis"}, $data{"estheading"}, $data{"estheading"} - $data{"bearing"}, calcsa( $data{"estheading"} - $data{"bearing"} );
	}
	close($fin);

}

