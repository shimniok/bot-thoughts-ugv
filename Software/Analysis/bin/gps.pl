#!/usr/bin/perl

## Pull out GPS data into separate file for use with Google Earth
##

use Cwd;
use lib "/home/mes/lib";
use DATABUS::FIELDS;

my @COLOR = (	"FF0000", # red
				"009900", # green
				"0000FF", # blue
				"6600CC", # purple
				"FFFF00", # yellow
			   
				"660000", # dark red
				"003300", # dark green
				"000066", # dark blue
				"660099", # dark purple
				"FF9900", # orange
			   
				"FF33CC", # pink
				"33CC99", # teal
				"993300", # brown

				"FFCCFF", # pastel pink
				"CCFFCC", # pastel green
				"CCFFFF", # pastel blue
				"FFFF99", # pastel yellow
				"CC99FF", # pastel purple
		   );

my $color = 0;

if ($#ARGV < 0) {
  printf "usage: plotter.pl infile [infile [...]]\n";
  exit(1);
}

my $filenames = join( ", ", @ARGV );

my $kmlfile = header();
$kmlfile =~ s/___NAME___/$filenames/g;

foreach my $file (@ARGV) {

	my $trackColor = rgb2kmlcolor( $COLOR[$color++] );
	
	open my $fin, "<", "$file" || die "cant open $ARGV[0]\n";
	$file =~ tr/A-Z/a-z/;

	my $coordinates = "";

	while (<$fin>) {
	  s/[\r\n]+//g;
	  my %data = parseFields($_);
	  next if ($data{"millis"} eq "Millis" || $data{"lat"} == 0);
	  $coordinates .= sprintf "%.5f,%.5f ", $data{"lon"}, $data{"lat"};
	}
	close($fin);

	my $placemark .= placemark();
	$placemark =~ s/___COLOR___/$trackColor/g;
	$placemark =~ s/___COORDINATES___/$coordinates/g;
	$placemark =~ s/___NAME___/$file/g;
	
	$kmlfile .= $placemark;
}

$kmlfile .= footer();

print $kmlfile;

exit;

sub header {
	my $h = "<?xml version=\"1.0\" standalone=\"yes\"?>\n" .
"<kml xmlns=\"http://earth.google.com/kml/2.2\">\n" .
"  <Document>\n" .
"    <name><![CDATA[___NAME___]]></name>\n" .
"    <snippet></snippet>\n" .
"    <visibility>1</visibility>\n" .
"    <open>1</open>\n" .
"    <Snippet><![CDATA[created using gps.pl]]></Snippet>\n";
	  
	return $h;
}

sub footer {
	my $f = "  </Document>\n" .
"</kml>\n";

	return $f;
}

sub placemark {
	my $p = "      <Placemark>\n" . 
"        <name><![CDATA[___NAME___]]></name>\n" .
"        <Snippet></Snippet>\n" .
"        <description><![CDATA[&nbsp;]]></description>\n" .
"       <Style>\n" .
"         <LineStyle>\n" .
"           <color>___COLOR___</color>\n" .
"            <width>4</width>\n" .
"          </LineStyle>\n" .
"        </Style>\n" .
"        <MultiGeometry>\n" .
"          <LineString>\n" .
"            <tessellate>1</tessellate>\n" .
"            <altitudeMode>clampToGround</altitudeMode>\n" .
"            <coordinates>___COORDINATES___</coordinates>\n" .
"          </LineString>\n" .
"        </MultiGeometry>\n" .
"      </Placemark>\n";

	return $p;
}

## Converts from web color (easier to deal with and more familiar)
## to KML format.  KML uses a weird hex color format: aabbggrr, where
##   aa is transparency (FF is fully opaque)
##   bb is blue
##   gg is green
##   rr is red
##
sub rgb2kmlcolor {
	my ( $color ) = @_;
	
	return my $newcolor = "FF" . substr($color, 4, 2) . substr($color, 2, 2) . substr($color, 0, 2);
}


## Parses line of csv data and puts into a hash for easy data access
##
sub parseit2 {
	my $x=0;
	my %FIELD;
	my %DATA;
	
	## defines the field order and keys
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
	$FIELD{"mx"}=$x++;
	$FIELD{"my"}=$x++;
	$FIELD{"mz"}=$x++;
	$FIELD{"gheading"}=$x++;
	$FIELD{"cheading"}=$x++;
	$FIELD{"roll"}=$x++;
	$FIELD{"pitch"}=$x++;
	$FIELD{"yaw"}=$x++;
	$FIELD{"lat"}=$x++;
	$FIELD{"lon"}=$x++;
	$FIELD{"course"}=$x++;
	$FIELD{"speed"}=$x++;
	$FIELD{"hdop"}=$x++;
	$FIELD{"lrdist"}=$x++;
	$FIELD{"rrdist"}=$x++;
	$FIELD{"lrspeed"}=$x++;
	$FIELD{"rrspeed"}=$x++;
	$FIELD{"encheading"}=$x++;
	$FIELD{"estheading"}=$x++;
	$FIELD{"estlat"}=$x++;
	$FIELD{"estlon"}=$x++;
	$FIELD{"estnorthing"}=$x++;
	$FIELD{"esteasting"}=$x++;
	$FIELD{"estx"}=$x++;
	$FIELD{"esty"}=$x++;
	$FIELD{"nextwaypoint"}=$x++;
	$FIELD{"bearing"}=$x++;
	$FIELD{"distance"}=$x++;

	## read the line of data
	my @data = split(/\s*,\s*/);
	
	## convert array of data into a hash of data using keys
	foreach $key (keys %FIELD) {
		$DATA{$key} = $data[$FIELD{$key}];
		#print "$key $FIELD{$key}\n";
	}
	  
	return %DATA
}
