#!/usr/bin/perl

# 0     1        2      3        4                5                6             7        8       9
# TIME	YAW	PITCH	ROLL	YAW_RATE	PITCH_RATE	ROLL_RATE	MAG_X	MAG_Y	MAG_Z

print "# MAG_X MAG_Y MAX_Z\n";

while (<>)
{

	@data = split(/\s+/);
	printf "%5d %5d %5d\n", $data[7], $data[8], $data[9];

}


