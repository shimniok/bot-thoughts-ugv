#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;

$xml = new XML::Simple;
print "reading $ARGV[0] ...\n";
$data = $xml->XMLin($ARGV[0]);

while (my ($key, $val) = each %{$data->{Document}->{Folder}->{Placemark}})
{
  ($lon, $lat) = split(/\s*,\s*/, $val->{Point}{coordinates}); 
  printf "W,%s,%s, %s\n", $lat, $lon, $key;
}

exit;
