#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;

$xml = new XML::Simple;
#print "reading $ARGV[0] ...\n";
$data = $xml->XMLin($ARGV[0]);

%ENTRY = %{$data->{Document}->{Folder}->{Placemark}};

#print %ENTRY,"\n\n";

foreach $key (sort keys %ENTRY)
{
  $val = $ENTRY{$key};
  ($lon, $lat) = split(/\s*,\s*/, $val->{Point}{coordinates}); 
  printf "wpt,%.8f,%.8f,0,0, %s\n", $lat, $lon, $key;
}

exit;
