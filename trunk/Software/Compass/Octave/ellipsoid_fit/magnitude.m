
% Prepare for plotting magnitude of a vector vs x, y, and/or z value
% a : set of 3 x 1 vectors
% result : in the form [ x y z mag] where mag is the magnitude of the
% 3d vector
function [ result ] = magnitude(a)

	x = a(:,1);
	y = a(:,2);
	z = a(:,3);

	[ m n ] = size(a);

  	for i=1:m
		mag(i,1) = norm(a(i,:),2);
  	end

	result = [ x y z mag ];

	figure;
	plot(result(:,1),result(:,4), '-');
	axis([-1.5 1.5 0.5 1.5]);
	grid on;
	title('X vs Magnitude');

	figure;
	plot(result(:,2),result(:,4), '-');
	axis([-1.5 1.5 0.5 1.5]);
	grid on;
	title('Y vs Magnitude');

	figure;
	plot(result(:,3),result(:,4), '-');
	axis([-1.5 1.5 0.5 1.5]);
	grid on;
	title('Z vs Magnitude');

end
