% compass_solver.m
%
% Finds offset and scale values to minimize SSE
% for sqp
%
function sse=phi(X)
	global M;
	S = [ 100/X(4) 0 0; 0 100/X(5) 0; 0 0 100/X(6) ];
	O = [ X(1) X(2) X(3) ];
	new = (M-ones(length(M),1)*O)*S;
	N = norm(new,2,'rows');
	ERR = (N - ones(length(N),1)*100);
	sse = sumsq(ERR);
end
%				
% Magnetometer data
%	
global M;

function Q=compass_solver(file)
	global M;
	M=load(file);
	%
	% initial guess using ellipsoid fit
	%
	source ellipsoid_fit/ellipsoid_fit.m
	[ O R E params ] = ellipsoid_fit(M);
	X0 = [ O(1) O(2) O(3) R(1) R(2) R(3) ];
	%
	% Run the non-linear solver
	%
	[X, obj, info, iter, nf, lambda] = sqp(X0, @phi);
	%
	% Compare O and R guess with solver results
	%
	O
	O2 = [ X(1:3) ]
	R
	R2 = [ X(4:6) ]
	%
	% Let's plot it and see what it looks like
	%
	S2 = diag([100/X(4) 100/X(5) 100/X(6)])
	M2 = (M-ones(length(M),1)*O2')*S2;
	N2 = norm(M2, 2, 'rows');
	Q=[ X(1:3); 100/X(4); 100/X(5); 100/X(6) ];
	close all;
	figure;
	plot3(M2(:,1),M2(:,2),M2(:,3),'.');
	xlabel("X");
	ylabel("Y");
	zlabel("Z");
	axis([-100, 100, -100, 100, -100, 100]);
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
	figure;
	plot(M2(:,3),N2,'.');
	axis([-110 110 80 120]);
	title("Z vs Magnitude", "fontsize", 16);
end