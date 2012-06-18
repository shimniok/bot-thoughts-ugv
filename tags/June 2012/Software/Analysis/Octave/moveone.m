% moveone.m
%
% calculates new position based on old position, distance, and heading
%
% P -- position
% H -- heading
% D -- distance
% Pnew -- position
%
%   double d = distance / _R;
%   double c = radians(course);
%   double rlat1 = radians(_latitude);
%   double rlon1 = radians(_longitude);
%
%   double rlat2 = asin(sin(rlat1)*cos(d) + cos(rlat1)*sin(d)*cos(c));
%   double rlon2 = rlon1 + atan2(sin(c)*sin(d)*cos(rlat1), cos(d)-sin(rlat1)*sin(rlat2));
%
%   _latitude  = degrees(rlat2);
%   _longitude = degrees(rlon2);
%
%   // bring back within the range -180 to +180
%   while (_longitude < -180.0) _longitude += 360.0;
%   while (_longitude > 180.0) _longitude -= 360.0;
%
function P1=moveone(P, H, D)
	% lat2 = asin(sin(lat1)*cos(d/R) + cos(lat1)*sin(d/R)*cos(?))
 	% lon2 = lon1 + atan2(sin(?)*sin(d/R)*cos(lat1), cos(d/R)-sin(lat1)*sin(lat2))
 	% ? is the bearing (in radians, clockwise from north);
	% d/R is the angular distance (in radians), where d is the distance travelled and R is the earth’s radius
	% JavaScript:	
	% var lat2 = Math.asin( Math.sin(lat1)*Math.cos(d/R) + 
    %          Math.cos(lat1)*Math.sin(d/R)*Math.cos(brng) );
	% var lon2 = lon1 + Math.atan2(Math.sin(brng)*Math.sin(d/R)*Math.cos(lat1), 
    %          Math.cos(d/R)-Math.sin(lat1)*Math.sin(lat2));
	EarthMeanRadius = 6378137 + 1582; % meters including altitude (@ boulder = 5190' = 1582m)
    d = D / EarthMeanRadius;
    c = H * pi/180;	 % convert heading to radians
    rlat1 = P(1)*pi/180;
    rlon1 = P(2)*pi/180;
    rlat2 = asin(sin(rlat1)*cos(d) + cos(rlat1)*sin(d)*cos(c));
    rlon2 = rlon1 + atan2(sin(c)*sin(d)*cos(rlat1), cos(d)-sin(rlat1)*sin(rlat2));
	P1 = [ rlat2 rlon2 ] * 180/pi;
	%P1 = P + D*[cos(c) sin(c)];
end