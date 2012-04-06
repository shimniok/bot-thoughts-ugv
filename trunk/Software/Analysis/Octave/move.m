% move.m 
%
% calculate position based on movement and heading matrices
%

% P -- starting position
% H -- heading
% D -- distance
% Pnew -- [lat lon] all positions
function Pnew=move(P, H, D)
	[m n]=size(D);
	Pnew = zeros(m,2);
	Pnew(1,:) = P;
	for i=2:m
		%Pnew(i,:) = Pnew(i-1,:) + D(i)*[cos(H(i)*pi/180) sin(H(i)*pi/180)];
		Pnew(i,:) = moveone(Pnew(i-1,:), H(i), D(i));
	end
end