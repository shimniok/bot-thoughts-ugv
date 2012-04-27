% poshdg.m
%
% Try and plot position estimation given heading and distance
% gyro+odo, compass+odo, gps-course+odo, gps-pos
%
% makes use of move.m for calculating new lat/lon based on heading & directon
%
%          1       2      3    4    5   6   7   8   9  10    11     12
% PH = [ millis, course, lat, lon, mx, my, mz, gx, gy, gz, lrdist, rrdist ]
function RESULT=poshdg(PH)
	% Time
	T = PH(:,1)/1000;
	% Distance
	D = mean(PH(:,11:12),2);
	% GPS position
	LAT=PH(:,3);
	LON=PH(:,4);
	% GPS heading
	Hgps=[];
	Dgps=[];
	Tgps=[];
	tmpd=0;
	for i=1:length(T)
		tmpd += D(i);
		if (LAT(i) != 0 && LON(i) != 0)
			Hgps = [Hgps; PH(i,2)];
			Dgps = [Dgps; tmpd];
			Tgps = [Tgps; T(i)];
			tmpd = 0;
		end
	end
	G0 = Hgps(1);
	P0 = [LAT(1) LON(1)];
	GPS = move([0 0], Hgps, Dgps);
	% Gyro
	Gz = dexpfilt(PH(:,10),0.5);
	scale = -14.49787;
	offset = 0.1;
	Hgy = fmod(cumtrapz(T, Gz/scale - offset)+G0, 360);
	GYRO = move([0 0], Hgy, D);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Complimentary Filter -- Estimate heading with comp filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if (0 == 1) 
	a=0.98;
	He=zeros(length(T),1);
	He = [ Hgps(1) ];
	De = [];
	O=zeros(length(T),4);
	Gzc=zeros(length(T),1);
	P = 0;
	for i=2:length(T)
		dt = T(i)-T(i-1);
		Gzc(i) = Gz(i)/scale - offset + P;
		if (LAT(i) != 0 && LON(i) != 0)
			H1 = Gzc(i)*dt + He(i-1);
			H2 = Hgps(i);
			if (H2-H1 > 180) 
				H2 -= 360;
			elseif (H2-H1 < -180)
				H2 += 360;
			end
			P = -0.1*(H2 - H1);
			offset -= 0.002*(H2 - H1);
			O(i,:) = [T(i) H2-H1 P offset];
			He = [He; fmod(a*H1 + (1-a)*H2, 360) ];
			De = [De; D(i)];
		end
	end
	E = move([0 0], He, D);
	% calculate corrected gyro heading
	Hgc = fmod(cumtrapz(T, Gzc)+G0, 360);
	end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Heading Kalman Filter -- Estimate Heading with Kalman Filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Kalman Filter Setup
	dt = 0.050;
	A = [1 dt; 0 1];			% Transition matrix
	H = [ 1 0; 0 1 ];			% Maps measurement to state vector
	P = [ 1000 0; 0 1000 ];		% Covariance of estimate; how certain is our estimate?
	R = [ .05 0; 0 0.04 ];		% Measurement noise
	Q = [ .5 0; 0 .5 ];			% System noise (bumps in road, etc)
	I = eye(2);					% Identity matrix
	% Initialize x w/ initial state
	% state vector consists of heading and heading-rate
	x = [ PH(1,2); PH(1,10)];
	Hk = zeros(length(T),1);	% kalman filter estimate
	Wk = zeros(length(T),1);	% kalman filter estimate	
	for i=2:length(T)
		A(1,2) = T(i,1) - T(i-1,1); % set dt per sample
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
		if (LAT(i) == 0)
			z = [ PH(i,10); 0 ];			% put measurement into z matrix
			H = [ 0 0; 0 1 ];				% Maps measurement to state vector
		else
			z = [ PH(i,2); PH(i,10) ];	% put measurement into z matrix
			H = [ 1 0; 0 1 ];			% Maps measurement to state vector
		end
		%
		% First, we have to figure out the Kalman Gain which is basically how much we
		% trust the sensor measurement versus our prediction.
		K = P*H'*inv(H*P*H' + R);	% Eq 1.11
		% Then we determine the discrepancy between prediction and measurement with
		% the "Innovation" or Residual: z-H*x, multiply that by the Kalman gain to
		% correct the estimate towards the prediction a little at a time. 
		x = x + K*(z-H*x);			% Eq 1.12
		% We also have to adjust the certainty. With a new measurement, the estimate
		% certainty always increases.
		P = (I-K*H)*P;				% Eq 1.13
		%
		% Populate the heading and heading rate matrices for plotting
		Hk(i) = x(1);
		Wk(i) = x(2);
	end
	KPOS1 = move([0 0], Hk, D);
	%
	% Filter out bogus lat/lon values
	%
	GPSPOS=[];
	for i=1:length(LON)
		if (LAT(i) != 0 && LON(i) != 0)
			GPSPOS=[GPSPOS; LAT(i)-LAT(1) LON(i)-LON(1)];
		end
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% POSITION Kalman Filter -- Estimate Position with Kalman Filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Kalman Filter Setup where x = [ lon; lon'; lat; lat' ]
	dt = 0.050;
	A = [1 dt 0 0; 0 1 0 0; 0 0 1 dt; 0 0 0 1];			% Transition matrix
	H = [ 1 0 0 0; 0 0 1 0;];							% Maps measurement to state vector
	P = 1000 * eye(4);									% Covariance of estimate; how certain is our estimate?
	R = [ 0.05 0; 0 0.05 ];								% Measurement noise
	Q = [ 0.001 0 0 0; 0 0 0 0; 0 0 0.001 0; 0 0 0 0];	% System noise (bumps in road, etc)
	I = eye(4);					% Identity matrix
	% Initialize x w/ initial state
	% state vector consists of heading and heading-rate
	x = [ 0; 0; 0; 0 ]; % <-- initialize with something
	KPOS2 = zeros(length(T),2);	% kalman filter estimate
	for i=2:length(T)
		A(1,2) = T(i,1) - T(i-1,1); % set dt per sample
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
		if (LAT(i) == 0)
			z = [ KPOS1(i,2); KPOS1(i,1) ];		% put estimated position into z matrix
			R = [ 0.05 0; 0 0.05 ];								% Measurement noise
		else
			z = [ PH(i,4)-LON(1); PH(i,3)-LAT(1) ];	% put gps position into z matrix
			R = [ 0.03 0; 0 0.03 ];								% Measurement noise
		end
		%
		% First, we have to figure out the Kalman Gain which is basically how much we
		% trust the sensor measurement versus our prediction.
		K = P*H'*inv(H*P*H' + R);	% Eq 1.11
		% Then we determine the discrepancy between prediction and measurement with
		% the "Innovation" or Residual: z-H*x, multiply that by the Kalman gain to
		% correct the estimate towards the prediction a little at a time. 
		x = x + K*(z-H*x);			% Eq 1.12
		% We also have to adjust the certainty. With a new measurement, the estimate
		% certainty always increases.
		P = (I-K*H)*P;				% Eq 1.13
		%
		% Populate the heading and heading rate matrices for plotting
		KPOS2(i,:) = [ x(3) x(1) ]; % store as lat, lon
	end
	%
	% Results for return
	%
	RESULT = [ move([LAT(1) LON(1)], Hk, D) ];
	%RESULT = [ move([LAT(1) LON(1)], Hgps, Dgps); ];

	%KPOS2
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% DATA PLOTTING
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	close all;
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
	plot(T,Hgy,'.', Tgps,Hgps,'.', T,Hk,'.');%, T,He,'.', T,Hgc,'.');
	title("Heading", "fontsize", 22);
	xlabel("Time (s)", "fontsize", 18);
	ylabel("Heading (deg)", "fontsize", 18);
	legend("Gyro Hdg", "GPS Course", "Filtered", "Kalman");%, "Gyro Corrected");
	grid on;
	% Plot GPS Course + Odo, Gyro Hdg + Odo
	%
	figure;
	plot(GPSPOS(:,2), GPSPOS(:,1), '-x', GYRO(:,2), GYRO(:,1), '--', GPS(:,2), GPS(:,1), '-', KPOS1(:,2), KPOS1(:,1), '-.', KPOS2(:,2), KPOS2(:,1), '-+');
	%, E(:,2), E(:,1), '--'
	title("Position estimates", "fontsize", 22);
	xlabel("Rel Lon", "fontsize", 18);
	ylabel("Rel Lat", "fontsize", 18);
	text(0, 1e-5, "Gyro scale -14.49787");
	text(0, 2e-5, "Gyro offset +0.1");
	legend("GPS", "GyroHdg+Odo", "GPSCourse+Odo", "Kalman+Odo", "Kalman Pos");%, "Comp+Odo"
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


