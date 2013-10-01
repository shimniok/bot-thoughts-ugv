#!/usr/bin/perl

## Module for parsing DataBus logfiles
##
package DATABUS::FIELDS;
require Exporter;
@ISA               = qw(Exporter);
@EXPORT            = qw(parseFields);

sub parseFields {
	my $x=0;
	my %FIELD;
	my %DATA;
	
	$FIELD{"millis"}=$x++;
	$FIELD{"current"}=$x++;
	$FIELD{"voltage"}=$x++;
	$FIELD{"gx"}=$x++;
	$FIELD{"gy"}=$x++;
	$FIELD{"gz"}=$x++;
	$FIELD{"gtemp"}=$x++;
	$FIELD{"ax"}=$x++;
	$FIELD{"ay"}=$x++;
	$FIELD{"az"}=$x++;
	#$FIELD{"mx"}=$x++;
	#$FIELD{"my"}=$x++;
	#$FIELD{"mz"}=$x++;
	$FIELD{"gheading"}=$x++;
	#$FIELD{"cheading"}=$x++;
	#$FIELD{"roll"}=$x++;
	#$FIELD{"pitch"}=$x++;
	#$FIELD{"yaw"}=$x++;
	$FIELD{"lat"}=$x++;
	$FIELD{"lon"}=$x++;
	$FIELD{"course"}=$x++;
	$FIELD{"speed"}=$x++;
	$FIELD{"hdop"}=$x++;
	$FIELD{"sats"}=$x++;
	$FIELD{"lrdist"}=$x++;
	$FIELD{"rrdist"}=$x++;
	$FIELD{"lrspeed"}=$x++;
	$FIELD{"rrspeed"}=$x++;
	$FIELD{"encheading"}=$x++;
	$FIELD{"estheading"}=$x++;
	$FIELD{"estlagheading"}=$x++;
	$FIELD{"estlat"}=$x++;
	$FIELD{"estlon"}=$x++;
	$FIELD{"estx"}=$x++;
	$FIELD{"esty"}=$x++;
	$FIELD{"nextwaypoint"}=$x++;
	$FIELD{"bearing"}=$x++;
	$FIELD{"distance"}=$x++;
	$FIELD{"steerangle"}=$x++;
	#$FIELD{"gbias"}=$x++;
	#$FIELD{"errangle"}=$x++;
	#$FIELD{"lranger"}=$x++;
	#$FIELD{"rranger"}=$x++;
	#$FIELD{"cranger"}=$x++;

	my @data = split(/\s*,\s*/);
	
	foreach $key (keys %FIELD) {
		$DATA{$key} = $data[$FIELD{$key}];
		#print "$key $FIELD{$key}\n";
	}
	  
	return %DATA
}

1;
