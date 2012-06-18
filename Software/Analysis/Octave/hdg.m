% Plot heading for GPS, gyro and KF
%        1       2                   3                          4                   5
% H: time(ms), Course, Est Heading (KF lag output), Gyro Heading (KF updated gyro), Gz
function hdg(H)
	delay = 10;
	scale=-14.5;
	[m n] = size(H);
	m -= delay;
	T=zeros(m,1);
	Hgps=zeros(m,1);
	Gz=zeros(m,1);
	Hkf=zeros(m,1);
	Hgy=zeros(m,1);
	Hg=zeros(m,1);
	T(1) = H(1,1)/1000;
	Hgy(1) = H(1,3);
	for i=2:m
		T(i) = H(i,1)/1000;
		dt = T(i) - T(i-1);
		Hgps(i) = H(i+delay,2);
		Hkf(i) = H(i+delay,3);
		Hg(i) = H(i,4);
		Gz(i) = H(i,5);
		Hgy(i) = Hgy(i-1)+dt*Gz(i)/scale;
	end
	figure;
	plot(T,Hgps,'.', T,Hg,'.', T,Hgy,'.', T,Hkf,'.');
	title("Heading", "fontsize",20);
	xlabel("Time(s)", "fontsize", 16);
	ylabel("Heading (deg)", "fontsize", 16);
	legend("GPS", "Gyro Hdg", "Gyro (calc)", "Kalman");
	grid on;
end