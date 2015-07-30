function x_ = Sys(k,x,u,noise,opt)
%% State: x y h
    if (k==1)
        error('k must start from 2\n');
    end
    delta_t = (opt.time(k,1) - opt.time(k-1,1))/1e6; % time in seconds
    x_(1) = x(1) + delta_t*u(k-1,1)*cos(x(3)) + noise(1);
    x_(2) = x(2) + delta_t*u(k-1,1)*sin(x(3)) + noise(2);
    x_(3) = x(3) + delta_t*tan(u(k-1,2))/opt.wheelbase*u(k-1,1) + noise(3);
end