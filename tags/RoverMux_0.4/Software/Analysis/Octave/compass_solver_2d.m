% compass_solver_2d.m
%
% Finds offset and scale values to minimize SSE
% for sqp
%
function sse=phi(X)
	global M;
	S = [ 100/X(3) 0; 0 100/X(4) ];
	O = [ X(1) X(2) ];
	new = (M-ones(length(M),1)*O)*S;
	N = norm(new, 2, 'rows');
	ERR = (N - ones(length(N),1)*100);
	sse = sumsq(ERR);
end
%				
% Magnetometer data
%	
global M;

function Q=compass_solver_2d(MAG)
	global M;
	M=MAG;
	%
	% initial guess
	%
	R(1) = (max(M(:,1)) - min(M(:,1)))/2;
	R(2) = (max(M(:,2)) - min(M(:,2)))/2;
	O(1) = mean(M(:,1));
	O(2) = mean(M(:,2));
	X0 = [ O(1) O(2) R(1) R(2) ];
	%
	% Run the non-linear solver
	%
	[X, obj, info, iter, nf, lambda] = sqp(X0, @phi);
	%
	% Compare O and R guess with solver results
	%
	O
	O2 = [ X(1:2) ]
	R
	R2 = [ X(3:4) ]
	%
	% Let's plot it and see what it looks like
	%
	S2 = diag([100/X(3) 100/X(4)])
	M2 = (M-ones(length(M),1)*O2')*S2;
	N2 = norm(M2, 2, 'rows');
	Q=[ X(1:2); 100/X(3); 100/X(4); ];
	close all;
	
	figure;
	a=[0:pi/100:2*pi]';
	X=100*sin(a);
	Y=100*cos(a);
	plot(M2(:,1),M2(:,2),'.', X, Y, '-');
	title("Compass locus post-calibration", "fontsize", 22);
	legend("locus", "best-fit circle");
	xlabel("X");
	ylabel("Y");
	axis([-120, 120, -120, 120]);
	axis square;
	grid on;
	
	figure;
	plot(M2(:,1),N2,'.');
	axis([-110 110 80 120]);
	title("X vs Magnitude", "fontsize", 16);
	
	figure;
	plot(M2(:,2),N2,'.');
	axis([-110 110 80 120]);
	title("Y vs Magnitude", "fontsize", 16);
end