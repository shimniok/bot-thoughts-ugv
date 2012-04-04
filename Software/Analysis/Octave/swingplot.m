
function swingplot(file)
	SW = load(file);
	figure;
	dev=SW(:,6)-mean(SW(:,6));
	plot(SW(:,2), dev,'.')
	xlabel("True heading", "fontsize", 14);
	ylabel("err - mean", "fontsize", 14);
	axis([0, 360, 2*min(dev), 2*max(dev)])
	grid on;
	title(strcat("Err Deviation vs Heading :", file), "fontsize", 20);
end
