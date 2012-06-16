% poshdg.m
%
% Try and plot position estimation given heading and distance
% gyro+odo, compass+odo, gps-course+odo, gps-pos
%
% makes use of move.m for calculating new lat/lon based on heading & directon
%
%          1       2      3    4    5   6   7   8   9  10    11     12       13      14      15
% PH = [ millis, course, lat, lon, mx, my, mz, gx, gy, gz, lrdist, rrdist, estlat, estlon, esthdg ];
function RESULT=gpsgyro2(PH)
	% delay
	delay = 10;
	% Gyro Config
	scale = -14.49787;
	offset = 0;%-0.35;
	% Distance
	D = mean(PH(:,11:12),2);
	% GPS position
	%LAT=PH(:,3);
	%LON=PH(:,4);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% GPS heading
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Lat=[];
	Lon=[];
	Pos=[0 0];
	P0=[PH(delay+1,3) PH(delay+1,4)]
	Hgps=[];
	Dgps=[];
	Dgy=[];
	Tgps=[];
	Gz=[];
	tmpd=0;
	p = [0 0];
	% Time Shift GPS data versus distance and gyro
	for i=1:length(PH)-delay
%		if (LAT(i+delay) != 0 && LON(i+delay) != 0)
			tmpd += D(i);
			Lat = [Lat; PH(i+delay,3)];
			Lon = [Lon; PH(i+delay,4)];
			if (Lat(i) == 0)
				Dgps = [Dgps; 0];
				Hgps = [Hgps; Hgps(i-1)];
			else
				p = [PH(i+delay,3) PH(i+delay,4)]-P0;
				Dgps = [Dgps; tmpd];
				tmpd = 0;
				Hgps = [Hgps; PH(i+delay,2)];
			end
			Pos = [Pos; p];
			Dgy= [Dgy; D(i)];
			Tgps = [Tgps; PH(i,1)/1000];
			Gz = [Gz; PH(i,10)];
%		end
	end
	
	%[ length(Hgps) length(Dgps) length(Tgps) length(Gz) ]
	
	G0 = Hgps(1);
	P0 = [Lat(1) Lon(1)];
	GPS = move([0 0], Hgps, Dgps);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Complimentary filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Hc = zeros(length(Tgps),1);
	C = 0.9955;
	Hc(1) = G0;
	for i=2:length(Tgps)
		dt = Tgps(i,1) - Tgps(i-1,1);
		Hc(i) = C * (Hc(i-1) + dt * Gz(i)/scale) + (1-C) * Hgps(i);
	end
	COMP = move([0 0], Hc, Dgps);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Gyro Heading
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Heading Kalman Filter -- Estimate Heading with Kalman Filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Kalman Filter Setup
	dt = 0.050;
	A = [1 dt 0; 0 1 -1; 0 0 1 ];			% Transition matrix
	H = [ 1 0 0; 0 1 0 ];					% Maps measurement to state vector
	P = [ 1000 0 0; 0 1000 0; 0 0 10 ];	% Covariance of estimate; how certain is our estimate?
	R = [ 0.01 0; 0 25 ];				% Measurement noise
	Q = [ 0.25 0 0; 0 0.25 0; 0 0 0.0001 ];	% System noise (bumps in road, etc)
	I = eye(3);					% Identity matrix
	F = 0.9;
	% Initialize x w/ initial state
	% state vector consists of heading and heading-rate
	GSz = zeros(length(Tgps),1);
	GSz(1) = 0;
	Hgy = zeros(length(Tgps),1);
	Hgy(1) = Hgps(1);
	x = [ Hgps(1); 0; 0 ];
	Hk = zeros(length(Tgps),1);	% kalman filter estimate
	Wk = zeros(length(Tgps),1);	% kalman filter estimate	\
	Bk = zeros(length(Tgps),1);	% kalman filter estimate
	for i=2:length(Tgps)
		A(1,2) = Tgps(i,1) - Tgps(i-1,1); % set dt per sample
		GSz(i) = F*GSz(i-1) + (1-F)*Gz(i); % exponential filtering
		%
		% Predict
		% In this step we "move" our state estimate according to the equation:
		x = A*x;					% Eq 1.9
		% We also have to "move" our uncertainty and add noise. Whenever we move,
		% we lose certainty because of system noise
		P = A*P*A' + Q;				% Eq 1.10
		%
		% Measurement aka Correct
		%
		if (Lat(i) == 0)
			z = [ 0; GSz(i)/scale ];			% put measurement into z matrix
			H = [ 0 0 0; 0 1 0];			% Maps measurement to state vector
		else
			z = [ Hgps(i); GSz(i)/scale ];	% put measurement into z matrix
			H = [ 1 0 0; 0 1 0];			% Maps measurement to state vector
		end
		%
		% First, we have to figure out the Kalman Gain which is basically how much we
		% trust the sensor measurement versus our prediction.
		K = P*H'*inv(H*P*H' + R);	% Eq 1.11
		% Then we determine the discrepancy between prediction and measurement with
		% the "Innovation" or Residual: z-H*x, multiply that by the Kalman gain to
		% correct the estimate towards the prediction a little at a time. 
		zHx = z-H*x;
		if (zHx(1) > 180)
			zHx -= 360;
		elseif (zHx(1) <= -180)
			zHx += 360;
		end
		x = x + K*zHx;			% Eq 1.12
		% We also have to adjust the certainty. With a new measurement, the estimate
		% certainty always increases.
		P = (I-K*H)*P;				% Eq 1.13
		%
		% Populate the heading and heading rate matrices for plotting
		if ( x(1) >= 360 )
			x(1) -= 360;
		elseif (x(1) < 0)
			x(1) += 360;
		end
		Hk(i) = x(1);
		Wk(i) = x(2);
		Bk(i) = x(3);
		Hgy(i) = Hgy(i-1) + A(1,2) * (Gz(i)/scale - x(3));
	end

	GYRO = move([0 0], Hgy, Dgy);

	%[length(Tgps) length(Hgy) length(Hgps) length(Hk) length(Dgps)]

	%
	% Position based on KF heading and distance
	%
	KPOS1 = move([0 0], Hk, Dgy);
	
	% Calculate delta x, delta y for each
	dgy = zeros(length(GYRO)-1,2);
	dk  = zeros(length(KPOS1)-1,2);
	dg  = zeros(length(Pos)-2,2);
	dc  = zeros(length(dg),2);
	Pc  = zeros(length(dg),2);
	Pc(1,:) = [ 0 0 ];
	for i=2:length(GYRO)-1
		Td(i) = Tgps(i);
		dgy(i,:) = [ GYRO(i,:) - GYRO(i-1,:) ];
		dk(i,:)  = [ KPOS1(i,:) - KPOS1(i-1,:) ];
		dg(i,:) = [ Pos(i,:) - Pos(i-1,:) ];
		if (dg(i,1) == 0 || dg(i,2) == 0)
			dc(i,:) = [ 0.8 * dgy(i,:) + 0.2 * dk(i,:) ];
		else
			dc(i,:) = [ 0.3*dg(i,:) + 0.7*(0.6 * dgy(i,:) + 0.4 * dk(i,:)) ];
		end
		Pc(i,:) = Pc(i-1,:) + dc(i,:);
		%[ Pos(i,:) Pos(i-1,:) ]% Pos(i,:) - Pos(i-1,:) ]
	end

	%
	% Results for return
	%
	RESULT = GPS;
	%RESULT = [ move([LAT(1) LON(1)], Hk, Dgps) ];
	%RESULT = [ move([PH(1,14) PH(1,13)], Hgps, Dgps) ];
	
	%KPOS2
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% DATA PLOTTING
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	% Delta Position 
	%
	figure;
	plot(Td,dgy(:,1),'--', Td,dk(:,1),'--', Td,dg(:,1),'o', Td,dc(:,1),'--');
	title("delta lat", "fontsize", 22);
	legend("Gyro", "Kalmaan", "GPS", "Comp");
	grid on;
	figure;
	plot(Td,dgy(:,2),'--', Td,dk(:,2),'--', Td,dg(:,2),'o', Td,dc(:,2),'--');
	title("delta lon", "fontsize", 22);
	legend("Gyro", "Kalmaan", "GPS", "Comp");
	grid on;
	%
	% Heading rate
	%
	figure;
	plot(Tgps,Gz/scale,'-', Tgps,GSz/scale,'-', Tgps,Wk,'-');
	title("Heading Rate", "fontsize", 22);
	xlabel("Time (s)", "fontsize", 18);
	ylabel("Heading Rate (deg/s)", "fontsize", 18);
	legend("Gyro Hdg", "Gyro Filtered", "Kalman");
	grid on;
	%
	% offset / error
	%
	%figure;
	%plot(O(:,1),O(:,2), '.', O(:,1),O(:,3), '.', O(:,1),O(:,4),'.');
	%title("PI Error correction", "fontsize", 22);
	%legend("Error", "P", "offset");
	%
	% Plot GPS course and gyro course
	%
	figure;
	plot(Tgps,Hgy,'.', Tgps,Hgps,'.', Tgps,Hk,'.', Tgps,Hc,'.');%, T,He,'-');%, T,He,'.', T,Hgc,'.');
	title("Heading", "fontsize", 22);
	xlabel("Time (s)", "fontsize", 18);
	ylabel("Heading (deg)", "fontsize", 18);
	legend("Gyro Hdg", "GPS Course", "Kalman", "Compl'y");%, "Gyro Corrected");
	grid on;
	% Plot GPS Course + Odo, Gyro Hdg + Odo
	%
	figure;
	plot(Pos(:,2),Pos(:,1), 'x', GYRO(:,2), GYRO(:,1), '--', GPS(:,2), GPS(:,1), '-', KPOS1(:,2), KPOS1(:,1), '.-', Pc(:,2),Pc(:,1),'x');
	%, E(:,2), E(:,1), '--'
	title("Position estimates", "fontsize", 22);
	xlabel("Rel Lon", "fontsize", 18);
	ylabel("Rel Lat", "fontsize", 18);
	text(0, 1e-5, "Gyro scale -14.49787");
	text(0, 2e-5, "Gyro offset +0.1");
	legend("GPS Pos", "GyroHdg+Odo", "GPSCourse+Odo", "Kalman+Odo", "PosComp");
	grid on;
	%
	% Plot gyro bias
	%
	figure;
	plot(Tgps,Bk,'--');
	title("Kalman Bias Est", "fontsize", 22);
	grid on;
	%
	% Plot GPS reported position
	%
	%figure;
	%plot(LON, LAT, '.', GPS(:,2)+LON(1), GPS(:,1)+LAT(1), '--', GYRO(:,2)+LON(1), GYRO(:,1)+LAT(1), '-.');
	%title("Lat/Lon Plots", "fontsize", 22);
	%legend("GPS", "GPS Hdg+Odo", "Gyro Hdg+Odo");
	%xlabel("Lon", "fontsize", 18);
	%ylabel("Lat", "fontsize", 18);
	%grid on;
end

% clamps degrees to  -180 to +180
% 
function cd=clamp(d)
	if (d < -180)
		cd = d + 360;
	elseif (d > 180)
		cd = d - 360;
	else
		cd = d;
	end
end


