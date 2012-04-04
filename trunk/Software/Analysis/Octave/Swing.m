function S=swing(file)
	E=load(file);
	plot(E(:,2), mod(E(:,2)-E(:,3),180), '.');
	xlabel("Heading", "fontsize", 16);
	ylabel("Error", "fontsize", 16);
	title("Compass Err vs Heading", "fontsize", 20);
	grid on;
end
