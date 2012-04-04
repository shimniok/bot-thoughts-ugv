% n multiplies by the normal distribution
function mat=noisysphere3d(noisemag, m)

  % create spherical coordinates of points on spherical surface
  % s=[ theta phi ], radius=1 plus noise within +/- noisemag
  s=unifrnd(-2*pi, 2*pi, [m 2]);
  r=ones([m 1]) + noisemag*stdnormal_rnd([m 1]);
  
  % convert to cartesian
  for i=1:m
	  mat(i,1) = r(i)*sin(s(i,1))*cos(s(i,2));
	  mat(i,2) = r(i)*sin(s(i,1))*sin(s(i,2));
	  mat(i,3) = r(i)*cos(s(i,1));
  end

  figure;
  plot3(mat(:,1), mat(:,2), mat(:,3), '.');
  axis square;
  grid on;
  title('Noisy 3D Sphere ');

end

