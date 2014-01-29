#!/usr/bin/perl

## Pull out GPS data from Octave matrix file and put into KML file for use with Google Earth
##
## Michael Shimniok http://www.bot-thoughts.com/
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
  printf "usage: $0 [-e] infile [infile [...]]\n";
  exit(1);
}

# -e is the estimate flag, generates KML file for
# estimated position
if ($ARGV[0] eq '-e') {
	shift @ARGV;
	$mylat = "estlat";
	$mylon = "estlon";
	$est = "est ";
} else {
	$mylat = "lat";
	$mylon = "lon";
	$est = "";
}

my $filenames = join( ", ", @ARGV );

my $kmlfile = header();
$kmlfile =~ s/___NAME___/$filenames/g;

foreach my $file (@ARGV) {

	my $trackColor = rgb2kmlcolor( $COLOR[$color++] );
	
	open my $fin, "<", "$file" || die "cant open $file\n";
	$file =~ tr/A-Z/a-z/;

	my $coordinates = "";

	while (<$fin>) {
	  s/[\r\n]+//g;
	  my %data = parseFields($_);
	  next if ($data{"millis"} =~ /^[a-z]/);
	  #next if ($mylat eq "lat" && $data{"lat"} == 0);
	  $coordinates .= sprintf "%.7f,%.7f ", $data{$mylon}, $data{$mylat};
	}
	close($fin);

	my $placemark .= placemark();
	$placemark =~ s/___COLOR___/$trackColor/g;
	$placemark =~ s/___COORDINATES___/$coordinates/g;
	$placemark =~ s/___NAME___/$est$file/g;
	
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
