#!/usr/bin/perl
use strict;

if (scalar(@ARGV) < 1) {

print "usage: perl csv2kml.pl <filename_in> <filename_out>\n\n";
print "for example: perl csv2kml.pl test1.csv test1.kml\n";
print "\n\n";
print "column order is expected to be: name,description,timestamp,color,scale_or_line_width,point coordinates,line coordinates,polygon coordinates\n";
print "only supply point OR line OR polygon coordinates\n";
exit 0;
}

my $filename_in = @ARGV[0];
my $filename_out = @ARGV[1];

#csv2kml.ini reads like below
#$field_separator,$comment_string,$coordinate_separator,$folder_name,$folder_desc,$default_timestamp,$default_color,$default_scale,$icon_href,$default_line_width
#,<SEP>#<SEP>\s+<SEP>My Folder Name<SEP>My Folder Description <a href="http://mywebsite">http://mywebsite</a><SEP>2006-11-01T00:00:00<SEP>ffffffff<SEP>1.0<SEP>http://carocoops.org/gearth/images/white_circle_icon.png<SEP>3

open (FILE_INI,"csv2kml.ini") or die "can't find file csv2kml.ini\n";
my ($field_separator,$comment_string,$coordinate_separator,$folder_name,$folder_desc,$default_timestamp,$default_color,$default_scale,$icon_href,$default_line_width);
foreach my $line (<FILE_INI>) {
	if ($line =~ /^#/ || $line =~ /^\s+/) { next; } #ignore comment lines
	($field_separator,$comment_string,$coordinate_separator,$folder_name,$folder_desc,$default_timestamp,$default_color,$default_scale,$icon_href,$default_line_width) = split(/<SEP>/,$line);
}
close (FILE_INI);

=comment
my $field_separator = ',';
my $comment_string = '#';
my $coordinate_separator = '\s+';
my $folder_name = 'My Folder Name';
my $folder_desc = 'My Folder Description <a href="http://mywebsite">http://mywebsite</a>';
my $default_timestamp = '2006-11-01T00:00:00';
my $default_color = '00ffffff';
my $default_scale = 1.0;

my $icon_href = 'http://carocoops.org/gearth/images/white_circle_icon.png';
my $line_width = 3;
=cut

my $kml_content = <<"END_OF_FILE";
<kml xmlns="http://earth.google.com/kml/2.0">
<Folder>
<name>$folder_name</name>
<description><![CDATA[$folder_desc]]></description>
END_OF_FILE

open (FILE_IN, "$filename_in");

foreach my $line (<FILE_IN>) {
if ($line =~ /^$comment_string/ || $line =~ /^\s+/) { next; } #ignore comment lines

my @line_array = split(/$field_separator/, $line);

#choose which fields to map - array elements start at 0 not 1
my $name = @line_array[0];
my $description = @line_array[1];
my $timestamp = @line_array[2];
if (!($timestamp)) { $timestamp = $default_timestamp; }
my $color = @line_array[3];
if (!($color)) { $color = $default_color; }
my $scale = @line_array[4];
my $line_width;
if (!($scale)) { $scale = $default_scale; $line_width = $default_line_width; }
else { $line_width = $scale } #scale also used to determine line width
my $long_lat = @line_array[5];
my $linestring = @line_array[6];
my $polygon = @line_array[7];

my $kml_feature = '';

if ($long_lat) {
	my ($longitude,$latitude,$elev) = split(/\s+/, $long_lat);
	$kml_feature .= "<Style><IconStyle><color>$color</color><scale>$scale</scale><Icon><href>$icon_href</href></Icon></IconStyle></Style>";
	$kml_feature .= "<Point><coordinates>$longitude,$latitude,$elev</coordinates></Point>";
}
elsif ($linestring) {
	$linestring = &comma_list($linestring);
	$kml_feature .= "<Style><LineStyle><color>$color</color><width>$line_width</width></LineStyle></Style>";
	$kml_feature .= "<LineString><coordinates>$linestring</coordinates></LineString>";
}
elsif ($polygon) {
	$polygon = &comma_list($polygon);
	$kml_feature .= "<Style><PolyStyle><color>$color</color></PolyStyle></Style>";
	$kml_feature .= "<MultiGeometry><Polygon><outerBoundaryIs><LinearRing><coordinates>$polygon</coordinates></LinearRing></outerBoundaryIs></Polygon></MultiGeometry>";
}

$kml_content .= <<"END_OF_FILE";
<Placemark>
  <TimeStamp><when>$timestamp</when></TimeStamp>
  <name>$name</name>
  <description><![CDATA[$description]]></description>
  $kml_feature
</Placemark>
END_OF_FILE

}

$kml_content .= <<"END_OF_FILE";
</Folder>
</kml>
END_OF_FILE

open (FILE_KML,">./$filename_out");
print FILE_KML $kml_content;
close (FILE_KML);

close (FILE_IN);

exit 0;

sub comma_list {

my ($input_list) = @_;
#print $input_list;
my @list = split(/$coordinate_separator/, $input_list);
my $temp_string = '';
my $array_count = 0;
foreach my $element (@list) {
	$array_count++;
	if ($array_count % 3) {	$temp_string .= $element."," }
	else { $temp_string .= $element." " }
}
$temp_string = substr($temp_string,0,-1);

#print "temp_string:$temp_string\n";
return $temp_string;
}

