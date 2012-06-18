% gyro solver 2D

function GH=gyroheading(T, G, scale, offset)
	GH = cumtrapz(T/1000,G/scale-offset); 
	% newer versions of octave apply scalar subtraction across entire matrix
	% if yours doesn't, use offset*ones(length(T),1)
end

% solver function to calculate SSE
%
% X -- vector, [scale, offset]
function sse=phi(X)
	global D;
	%heading consisting of reference and integration of gyro
	%GH = gyroheading(D(:,1),D(:,3),X(1),X(2));
	%ERR = (GH - D(:,2));
	% heading rate consisting of numerical gradient of heading reference and gyro
	ERR=(D(:,3)/X(1)-X(2)) - gradient(D(:,2), D(:,1)/1000);
	sse = sumsq(ERR);
end

% global gyro/time/heading data
% D = [ millis, hdg, gyro ]
global D;

% gyro_solver_2d
%
% Takes true heading, time, and gyro data and solves for offset and scale parameters to minimize error
%
% T -- time in milliseconds
% H -- heading at each time entry
% G -- gyro at each time entry
% X is the parameter vector [ scale, offset ]
function Q=gyro_solver_2d(T,H,G)
	global D;
	D=[ T H G ];
	X0 = [ -14, 0 ];
	[X, obj, info, iter, nf, lambda] = sqp(X0, @phi)
	GH = gyroheading(T,G,X(1),X(2));
	Q = X;
	close all;
	figure;
	plot(T, H, '-', T, GH, '-');
	legend("Ref Heading", "Gyro Integration", "location", "southeast");
	title("Gyro Calibration, Heading","fontsize",20);
	xlabel("Time (ms)", "fontsize", 16);
	ylabel("Heading Rate (deg per sec)", "fontsize", 16);
	figure;
	plot(T, gradient(H, T/1000), '.', T, (G/X(1)-X(2)), '.');
	legend("Ref Heading Rate", "Gyro", "location", "southeast");
	title("Gyro Calibration, Heading Rate","fontsize",20);
	xlabel("Time (ms)", "fontsize", 16);		
	ylabel("Heading (deg)", "fontsize", 16);
end