#!/usr/bin/perl

$med[0]=-29.50;
$med[1]=0.50;
$med[2]=-4.00;

while (<>) {

	s/^\s+//;
	next if (/^X/);
	@data = split(/\s+/);

	for ($i = 0; $i < 3; $i++) {

		$data[$i] -= $med[$i];
		printf "%.2f ", $data[$i];

	}
	print "\n";

}

