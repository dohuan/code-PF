function x_ = Sys_indoor(k,x,u,noise,opt)
%% State: x y h
    load ./data/calibmatrix
    Ma=calib(1:2,1:2);
    Mb=calib(3,1:2);
    Mc=calib(1:2,3);
    Mk=calib(3,3);
    
    if (k==1)
        error('k must start from 2\n');
    end
    delta_t = (opt.time(k,1) - opt.time(k-1,1)); % time in seconds
    
    % --- Convert to world coordinate
    x_pre = [x(1);x(2)];
    x_w = (Ma-x_pre*Mb)^(-1)*(x_pre*Mk-Mc);
    x_w = x_w';
    x_w(3) = x(3);
    % --- Update in world coor
    x_w_(1) = x_w(1) + delta_t*u(k-1,1)*cos(x(3)) + noise(1);
    x_w_(2) = x_w(2) + delta_t*u(k-1,1)*sin(x(3)) + noise(2);
    x_w_(3) = x_w(3) + delta_t*u(k-1,2) + noise(3);
    % --- Convert back to frame coor
    x_f_temp = [x_w_(1);x_w_(2);1];
    fTmp = calib*x_f_temp;
    x_(1) = (fTmp(1)/fTmp(3));
    x_(2) = (fTmp(2)/fTmp(3));
    x_(3) = x_w_(3);
end