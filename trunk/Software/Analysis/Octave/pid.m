% PID simulator for Octave

1;

function X=pid(time, sp, kp, ki, kd)
	v=0; % velocity
	int = 0;
	mass = 2.25; % mass, kg
	% map throttle output to force at the wheel
	% wind drag constant
	kroll = -2; % rolling resistance, kg*m/s^2
	kthrottle = 0.05; % convert throttle to force
	X=[];
	Y1=[];
	Y2=[];
	V=[];
	OP=[];
	OI=[];
	data=[];
	dv=0;
	a = 0;

    fd = fopen("mypid.dat", "wt");
	for t=1:0.1:time
		err = sp - v;
		op = kp * err;
		oi = ki * int;
		od = kd * a;
		a = v*kroll/mass + (op+oi+od)*kthrottle/mass; % calculate a
		v = v + a * 0.1; % update velocity based on last v and current a
		%X = [X; t, v, err, op, oi];
		X = [X; t];
		Y1 = [Y1; v];
		Y2 = [Y2; op, oi, od];
		%fprintf(fd, "%14.6f %14.6f %14.6f %14.6f %14.6f\n", t, v, err, op, oi);
		int = int + err;
	end
    %fclose(fd);
    %figure;
    [ax, h1, h2] = plotyy(X, Y1, X, Y2);
    xlabel('time (s)');
    title("PID Simulation");
    axes(ax(1)); ylabel('speed (m/s)');
   	axes(ax(2)); ylabel('output (us)');
	set(h1,'LineStyle','-');
	set(h2,'LineStyle','--');
	legend([h1; h2(1); h2(2); h2(3)], 'v', 'Pout', 'Iout', 'Dout');
	axes(ax(1));
	grid on;

end

