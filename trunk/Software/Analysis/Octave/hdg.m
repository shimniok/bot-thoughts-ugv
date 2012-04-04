% Plot heading for GPS and Mag

D=load("hdg023.csv");
CH=180 * atan2(D(:,3), D(:,4)) / pi; % 2D heading calc

figure;
plot(D(:,1), D(:,2), '-', D(:,1), CH, '-');
title("Heading");
xlabel("Time (ms)");
ylabel("Heading (deg)");
legend("Course", "Compass");

figure;
plot(D(:,1), D(:,2)-CH, '-');
title("Heading Error");
xlabel("Time (ms)");
ylabel("Heading Error (deg)");
legend("Course - Compass");

