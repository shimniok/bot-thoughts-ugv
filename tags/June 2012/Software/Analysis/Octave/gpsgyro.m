% poshdg.m
%
% Try and plot position estimation given heading and distance
% gyro+odo, compass+odo, gps-course+odo, gps-pos
%
% makes use of move.m for calculating new lat/lon based on heading & directon
%
%          1       2      3    4    5   6   7   8   9  10    11     12       13      14      15
% PH = [ millis, course, lat, lon, mx, my, mz, gx, gy, gz, lrdist, rrdist, estlat, estlon, esthdg ];
function RESULT=gpsgyro(PH)
	% Time
	T = PH(:,1)/1000;
	% Distance
	D = mean(PH(:,11:12),2);
	% GPS position
	LAT=PH(:,3);
	LON=PH(:,4);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% GPS heading
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Hgps=[];
	Dgps=[];
	Tgps=[];
	tmpd=0;
	for i=1:length(T)-10
		tmpd += D(i);
		if (LAT(i+10) != 0 && LON(i+10) != 0)
			Hgps = [Hgps; PH(i+10,2)];
			Dgps = [Dgps; tmpd];
			Tgps = [Tgps; T(i)];
			tmpd = 0;
		end
	end
	G0 = PH(1,15);
	P0 = [LAT(1) LON(1)];
	GPS = move([0 0], Hgps, Dgps);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Gyro Heading
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Gz = expfilt(PH(:,10),0.5);
	scale = -14.49787;
	offset = -0.35;
	Hgy = fmod(cumtrapz(T, Gz/scale - offset)+G0, 360);
	GYRO = move([0 0], Hgy, D);
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Estimated Heading
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	He= PH(:,15);
	EST = move([0 0], He, D);
	%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Heading Kalman Filter -- Estimate Heading with Kalman Filter
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Kalman Filter Setup
	dt = 0.050;
	A = [1 dt; 0 1];			% Transition matrix
	H = [ 1 0; 0 1 ];			% Maps measurement to state vector
	P = [ 1000 0; 0 1000 ];		% Covariance of estimate; how certain is our estimate?
	R = [ 3 0; 0 0.03 ];		% Measurement noise
	Q = [ 0.01 0; 0 0.01 ];	    % System noise (bumps in road, etc)
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
			% am I just sticking raw gyro reading in here?? That's dumb
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
	% Results for return
	%
	RESULT = [ move([LAT(1) LON(1)], Hk, D) ];
	%RESULT = [ move([LAT(1) LON(1)], Hgps, Dgps); ];

	%KPOS2
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% DATA PLOTTING
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
	plot(T,Hgy,'.', Tgps,Hgps,'.', T,He,'.');%, T,Hk,'-');%, T,He,'.', T,Hgc,'.');
	title("Heading", "fontsize", 22);
	xlabel("Time (s)", "fontsize", 18);
	ylabel("Heading (deg)", "fontsize", 18);
	legend("Gyro Hdg", "GPS Course", "Est Hdg");%, "Gyro Corrected");
	grid on;
	% Plot GPS Course + Odo, Gyro Hdg + Odo
	%
	figure;
	plot(GYRO(:,2), GYRO(:,1), '--', GPS(:,2), GPS(:,1), '-', EST(:,2), EST(:,1), '.-');%, KPOS1(:,2), KPOS1(:,1), '-.', KPOS2(:,2), KPOS2(:,1), '-+');
	%, E(:,2), E(:,1), '--'
	title("Position estimates", "fontsize", 22);
	xlabel("Rel Lon", "fontsize", 18);
	ylabel("Rel Lat", "fontsize", 18);
	text(0, 1e-5, "Gyro scale -14.49787");
	text(0, 2e-5, "Gyro offset +0.1");
	legend("GyroHdg+Odo", "GPSCourse+Odo", "EstHdg+Odo");%, "Kalman+Odo", "Kalman Pos");%, "Comp+Odo"
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


