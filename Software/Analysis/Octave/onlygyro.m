% onlygyro.m
%
% Prototype use of gyro for position estimation, with GPS heading for bias correction
%
% OG: [ millis, course, lat, lon, gx, gy, gz, lrdist, rrdist, estlat, estlon ]
%
function onlygyro(OG)

% Initialize position
% TODO: TEMPORARILY FORCE INIT UNTIL I GET A RUN WITH CORRECT WAYPOINT DATA
LAT0 = OG(1,10);
LON0 = OG(1,11);
LAT0=39.59760321956102; % home
LON0=-104.9328846135643;
LAT0=39.60190828304393; % lois lenski
LON0=-104.9300340108308
G0 = 73;

% Time
T = OG(:,1)/1000;

% Distance
D = mean( OG(:,8:9), 2 );

% GPS Position
Pgps = [ OG(:,3) OG(:,4) ];
% GPS Heading
Hgps = zeros(length(OG),1);
Hgps(1) = G0;
last = 1;
for i=2:length(OG)-10
	if (OG(i,3) > 0) % GPS data avail
		Hgps(i) = OG(i+10,2); % time shift by 1 sec (10 x 100ms)
		last = i;
	else
		Hgps(i) = OG(last+10, 2);
	end
end
% GPS position based on heading+odo
Phgps = move([LAT0 LON0], Hgps, D);

% Gyro Heading
% TODO: get initial heading from data file
Ki = 0.00002; % integral error gain
offset = -0.6;
scale = -14.49787;
Gz = OG(:,7);
clear Offset Rgyro Hgyro;
Offset = zeros(length(OG),1);
Rgyro = zeros(length(OG),1);
Hgyro = zeros(length(OG),1);
Hgyro(1) = G0;
for i=1:length(OG)-1
	dt = T(i+1) - T(i);
	Rgyro(i) = dt*(Gz(i)/scale - offset);
	Hgyro(i+1) = Hgyro(i) + Rgyro(i);
	Offset(i) = offset;
	if (OG(i,3) > 0) % GPS data avail
		if (i > 10)
			%if (Rgyro(i) < 1 && Rgyro(i) > -1)
				offset += Ki*(fmod(Hgyro(i-10) - OG(i,2),180))
			%end
		end
	end
end

%Gz = dexpfilt( OG(:,7),0.5);  %% TODO: what's the impact of this filtering on reality? not doing this onboard...
scale = -14.49787;
offset = +0.2;
clear Rgyro Hgyro;
Rgyro = Gz/scale - offset;
Hgyro = fmod(cumtrapz(T, Rgyro)+G0, 360);
Rgyro *= 0.100; % multiply by dt to get dps

% Odometry
TRACK = 0.280;
offset_odo = -0.0009;
% dither and filter Rodo
clear Rodo RFodo rodo;
Rodo = (180/pi) * (OG(:,8) - OG(:,9) - offset_odo) / TRACK;
% filter
a = .9;
rodo = Rodo + normrnd(0, 0.2, length(OG), 1);
RFodo(1) = rodo(1);
for i=1:length(Rodo)-1
	RFodo(i+1) = a*rodo(i) + (1-a)*rodo(i+1);
end
Hodo = zeros(length(T),1);
Hodo(1) = G0;
for k=1:length(T)-1
	Hodo(k+1) = Hodo(k) + Rodo(k);
end
Podo = move([LAT0 LON0], Hodo, D);

% Gyro Position
Pgyro = move([LAT0 LON0], Hgyro, D);


% save matrices for KML conversion

save "pgps.mat" Pgps;
save "phgps.mat" Phgps;
save "pgyro.mat" Pgyro;
save "podo.mat" Podo;

close all;
figure;
plot(T, Hgps, '.', T, Hgyro, '-', T, Hodo, '-');
legend("gps", "gyro", "odo");
title("Heading", "fontsize", 22);
xlabel("Time (s)", "fontsize", 18);
ylabel("Heading (deg)", "fontsize", 18);
grid on;

figure;
plot(T, Rgyro, '-', T, RFodo, '-');
legend("gyro", "odo");
title("Heading Rate", "fontsize", 22);
xlabel("Time (s)", "fontsize", 18);
ylabel("Heading Rate (deg/sec)", "fontsize", 18);
grid on;

figure;
plot(T, Offset);
title("Gyro offset, corrected");
xlabel("Time (s)", "fontsize", 18);
ylabel("Gyro offset", "fontsize", 18);
grid on;

end