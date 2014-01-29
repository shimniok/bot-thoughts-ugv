% compass_autocal.m
% 
% simulate compass offset automatic calibration
%

function compass_autocal(M)
	H=zeros(length(M),6);
	xo=yo=zo=0;
	Kp=0.001;
	Ki=0;
	for i=1:length(M)
		x = M(i,1);
		y = M(i,2);
		z = M(i,3);
		mag = sqrt((x-xo)^2+(y-yo)^2+(z-zo)^2);
		magxy = sqrt((x-xo)^2+(y-yo)^2);
		theta = atan2(y, x);
		phi = atan2(z, magxy);
		err = 100.0 - mag;
		xo += Kp * err * cos(phi)*sin(theta);
		yo += Kp * err * cos(phi)*cos(theta);
		zo += Kp * err * sin(phi);
		H(i,:) = [ i, mag, err, xo, yo, zo ];
	end
	figure;
	plot(H(:,1), H(:,3), '-', H(:,1), H(:,4), '-', H(:,1), H(:,5), '-');
	legend("Error", "Xoff", "Yoff");
end