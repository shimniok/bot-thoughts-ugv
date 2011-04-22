#!/usr/bin/perl

$PI = 3.141529;

use Math::Trig;

sub radians {
  my $d = $_[0];
  return $d*$PI/180.0;
}

sub degrees {
  my $r = $_[0];
  return $r*180.0/$PI;
}

sub move {
  my ($latitude, $longitude, $course, $distance ) = @_;

  my $_R = 6371000.0;   # earth's radius

  my $d = $distance / $_R;
  my $c = radians($course);
  my $rlat1 = radians($latitude);
  my $rlon1 = radians($longitude);

  my $rlat2 = asin(sin($rlat1)*cos($d) + cos($rlat1)*sin($d)*cos($c));
  my $rlon2 = $rlon1 + atan2(sin($c)*sin($d)*cos($rlat1), cos($d)-sin($rlat1)*sin($rlat2));

  $_[0] = degrees($rlat2); ## latitude
  $_[1] = degrees($rlon2); ## longitude

  ## bring back within the range -180 to +180
  while ($longitude < -180.0) { $longitude += 360.0; }
  while ($longitude > 180.0)  { $longitude -= 360.0; }
}


sub brgdist {
  my ($dlat1, $dlon1, $dlat2, $dlon2) = @_;

  my $_R = 6371000.0;   # earth's radius

  ## bearing

  $lat1 = radians($dlat1);
  $lon1 = radians($dlon1);
  $lat2 = radians($dlat2);
  $lon2 = radians($dlon2);
  $dLon = $lon2 - $lon1;
  $dLat = $lat2 - $lat1;
  
  $y = sin($dLon) * cos($lat2);
  $x = cos($lat1) * sin($lat2) -
       sin($lat1) * cos($lat2) * cos($dLon);

  $result[0] = degrees( atan2($y, $x) );

  ## distance
  $a = sin($dLat/2.0) * sin($dLat/2.0) +
          cos($rlat1) * cos($rlat2) *
          sin($dLon/2.0) * sin($dLon/2);
  $c = 2.0 * atan2(sqrt($a), sqrt(1-$a));

  $result[1] = $_R * $c;

  return @result;
}

1;
