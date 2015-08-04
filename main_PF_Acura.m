close all
clear
clc
set(0,'defaultFigureColor',[1 1 1])
%%
isMovie = 1;
isMC = 1;
nx = 3;
ny = 2;

data = load('./data/est_input');
u = data.u_l;
v = data.phi;

% --- Load observation data
data1 = load('./data/hpcc_run_0403(2)_OP_SURF');
x_true = [(data1.y_test)'; data.heading_angle'];
y = (data1.y_test_est)';
nt = size(x_true,2);
%% Configuration
% --- Model noise
location_model_noise = (3.5)^2; % \sigma_w1^2
heading_model_noise  = (2/180*pi)^2; %\sigma_w2^2

% --- Observation (measurement) noise
location_measure_noise = (225)^2; % \sigma_e1^2

opt.Q = [location_model_noise 0 0;...
    0 location_model_noise 0;...
    0 0 heading_model_noise]; % model covariance matrix
opt.R = [location_measure_noise 0;
    0 location_measure_noise]; % measurement covariance
opt.M = [1 0 0;
    0 1 0];
opt.time = data.time;
opt.wheelbase = 2.57048;


%% Separate memory
x0 = x_true(:,1);
xh = zeros(nx, nt); xh(:,1) = x0;
yh = zeros(ny, nt); yh(:,1) = y(:,1);

opt.x0 = x0;

pf.Ns              = 800;                 % number of particles
pf.w               = zeros(pf.Ns, nt);    % weights
pf.particles       = zeros(nx, pf.Ns, nt);% particles

%% Estimate state
if (isMC==0)
    for k = 2:nt
        fprintf('Iteration = %d/%d\n',k,nt);
        [xh(:,k), pf] = PF(k,y(:,k),[u v],pf, 'systematic_resampling',opt);
        % --- filtered observation
        yh(:,k) = Obs(xh(:,k),opt.M, 0);
    end
    
    if (isMovie==1)
        filename='./results/PF_evolution.avi';
        vid = VideoWriter(filename);
        vid.Quality = 100;
        vid.FrameRate = 20;
        open(vid)
        frameRate = .05; % seconds between frames
        
        h = figure('name','PF evolution');
        hold on
        for i=2:nt
            plot([xh(1,i-1) xh(1,i)],[xh(2,i-1) xh(2,i)],'b','LineWidth',2);
            plot([x_true(1,i-1) x_true(1,i)],[x_true(2,i-1) x_true(2,i)],'r','LineWidth',2);
            plot(y(1,i),y(2,i),'gs');
            plot(pf.particles(1,:,i),pf.particles(2,:,i),'k.');
            
            writeVideo(vid,getframe(gcf));
            
            child = get(gca,'children');
            delete(child(1));
        end
        hold off
        close(vid);
    end
    plot(xh(1,:),xh(2,:),'LineWidth',2);
    hold on
    plot(y(1,:),y(2,:),'ks');
    plot(x_true(1,:),x_true(2,:),'r','LineWidth',2);
    
    fprintf('RMSE of open-loop: %f\n',sqrt(mseCal(data.y_open_loop,...
        data1.y_test)));
    fprintf('RMSE of LASSO: %f\n',sqrt(mseCal(data1.y_test_est,...
        data1.y_test)));
    fprintf('RMSE of LASSO+PF: %f\n',sqrt(mseCal(data1.y_test,xh(1:2,:)')));
else
    MC_run = 800;
    for i=1:MC_run
        fprintf('MC progress... %.2f%%\n',round(i/MC_run*100));
        pf_temp = pf;
        for k = 2:nt
            [xh_temp(:,k), pf_temp] = PF(k,y(:,k),[u v],pf_temp, 'systematic_resampling',opt);
            % --- filtered observation
            %yh(:,k) = Obs(xh(:,k),opt.M, 0);
        end
        MC(i).xh = xh_temp;
        MC(i).pf = pf_temp;
        err_MC(i,1) = sqrt(mseCal(data1.y_test,MC(i).xh(1:2,:)'));
    end
    fprintf('Mean of RMSE: %.2f\n',mean(err_MC));
    fprintf('Std of RMSE: %.2f\n',sqrt(var(err_MC)));
end


