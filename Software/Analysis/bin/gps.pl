#!/usr/bin/perl

require 'fields.pl';


## Filter out the lines containing GPS fix information
## to a file that can be sent to GPSVisualizer, etc.
##
while (<>) {
  s/[\r\n]+//g;

  @data = split(/\s*,\s*/);

  print "$_\n"
    if ($data[$LAT] ne '' && $data[$LON] ne '');

}
