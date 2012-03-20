% For hard and soft iron magnetometer calibration
%
% Get the matrix containing 3x1 vectors representing individual readings from the
% compass that form a locus that falls approximately onto an ellipsoid.  The ellipsoid
% will be offset from the origin by hard iron errors.  Soft-iron errors will generate
% a tilted ellipsoid. To fix this we have to scale (not rotate) the ellipsoid along
% its axes to form a sphere. So in our sensor code what we really want is a 3x3 matrix
% that will fix the scale and offset correctly
%
% Treat the ellipsoid axes we get back as a reference frame; they are 3 orthogonal unit
% vectors. If we want to scale the ellipsoid to a sphere, we have to scale along those
% axes, so we have to take a scale vector in the ellipsoid frame and convert it to the
% origin frame. For that we need a Direction Cosine Matrix
%
% Use ellipsoid_fit to find the best fit ellipsoid and return its axes and radii
% O: 3 x 1 offset of ellipsoid from origin
% R: 3 x 1 radii of ellipsoid
% E: 3 x 1 column vectors representing ellipsoid axes
% params: we don't use these
%
function fix=fixit(old)

	[ m n ] = size(old);
	[ O R E params ] = ellipsoid_fit(old);

	% 3 vectors in columns
	v=eye(3)';
	
	% calculate the direction cosine matrix for conversion between reference frames
	DCM=[ ...
		dot(E(:,1),v(:,1)) dot(E(:,1),v(:,2)) dot(E(:,1),v(:,3)); ... 
		dot(E(:,2),v(:,1)) dot(E(:,2),v(:,2)) dot(E(:,2),v(:,3)); ... 
		dot(E(:,3),v(:,1)) dot(E(:,3),v(:,2)) dot(E(:,3),v(:,3)) ...
	]

	% calculate scale vector in ellipsoid frame and convert to origin frame
	% scale to a normal value of 100
	S = ([ 100/R(1) 0 0; 0 100/R(2) 0; 0 0 100/R(3) ] * DCM)';

	% fix offset and scale
	new=(old-ones(m,1)*O')*S;
	N = norm(new,2,'rows');

	[ O2 R2 E2 params2 ] = ellipsoid_fit(old);
	% For plotting
	axes=[0 0 0; E2(:,1)'; 0 0 0; E2(:,2)'; 0 0 0; E2(:,3)'];
	%origin=[0 0 0; v(:,1)'; 0 0 0; v(:,2)'; 0 0 0; v(:,3)'];

	fix = struct('S', S, 'O', O, 'new', new, 'norm', N);

	close all;

	figure;
	plot(old(:,1),old(:,2),'.',axes(:,1),axes(:,2),'-');
	xlabel("X Axis");
	ylabel("Y Axis");
	axis square;
	title("XY Before");
	grid on;

	figure;
	plot(old(:,1),old(:,3),'.',axes(:,1),axes(:,3),'-');
	xlabel("X Axis");
	ylabel("Z Axis");
	axis square;
	title("XZ Before");
	grid on;

	figure;
	plot(old(:,2),old(:,3),'.',axes(:,2),axes(:,3),'-');
	xlabel("Y Axis");
	ylabel("Z Axis");
	axis square;
	title("YZ Before");
	grid on;

	figure;
	plot(new(:,1),new(:,2),'.',axes(:,1),axes(:,2),'-');
	xlabel("X Axis");
	ylabel("Y Axis");
	axis([-100 100 -100 100]);
	axis square;
	title("XY After");
	grid on;

	figure;
	plot(new(:,1),new(:,3),'.',axes(:,1),axes(:,3),'-');
	xlabel("X Axis");
	ylabel("Z Axis");
	axis([-100 100 -100 100]);
	axis square;
	title("XZ After");
	grid on;

	figure;
	plot(new(:,2),new(:,3),'.',axes(:,2),axes(:,3),'-');
	xlabel("Y Axis");
	ylabel("Z Axis");
	axis([-100 100 -100 100]);
	axis square;
	title("YZ After");
	grid on;

	figure;
        plot(new(:,1),N,'.');
	axis([-110 110 50 150]);
	title("X vs vector magnitude");
	grid on;

	figure;
        plot(new(:,2),N,'.');
	axis([-110 110 50 150]);
	title("Y vs vector magnitude");
	grid on;

	figure;
        plot(new(:,3),N,'.');
	axis([-110 110 50 150]);
	title("Z vs vector magnitude");
	grid on;

end
