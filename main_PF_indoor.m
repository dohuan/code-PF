close all
clear
clc
set(0,'defaultFigureColor',[1 1 1])
%%
isMovie = 0;
isMC = 0;
nx = 3; % Number of states
ny = 2; % Number of observation

[~, ~, raw] = xlsread('.\data\FeaturesAndLocations.xls','Sheet1','A2:AL464');
data = reshape([raw{:}],size(raw));
dataSize = 400;
scaleRatio = 1;
input = downSampling([data(1:dataSize,1) data(1:dataSize,2)],scaleRatio);
opt.time = downSampling(data(1:dataSize,5),scaleRatio);

opt.mean_loc = mean(data(1:dataSize,3:4));
opt.std_loc = std(data(1:dataSize,3:4));
u = input(:,1);
v = input(:,2);


snap_shot = 50;

% --- Load observation data
data1 = load('./data/alien_0213.mat');
[IC,IX] = sort(data1.index(data1.validateIndex+1:data1.testIndex));
obs_num = IC;
obs_index = zeros(dataSize,1);
obs_tmp = data1.y_guess_test(IX',:);
y = zeros(2,dataSize);
count = 1;
for i=1:dataSize
    if (isempty(find(obs_num==i, 1))==1)
        y(:,i) = [NaN;NaN];
        obs_index(i) = 0;
    else
        y(:,i) = obs_tmp(count,:);
        count = count + 1;
        obs_index(i) = 1;
    end
end

location = data1.y;
heading_angle = LineAngleEstimator(location,1);
x_true = [(location)'; heading_angle];

%x_true = [(data1.y_test)'; data.heading_angle'];
%y = (data1.y_test_est)';

nt = size(x_true,2);
%% Configuration
% --- Model noise
location_model_noise = (0.05)^2; % \sigma_w1^2
heading_model_noise  = (0.5/180*pi)^2; %\sigma_w2^2

% --- Observation (measurement) noise
location_measure_noise = (0.9)^2; % \sigma_e1^2 0.6 0.7

opt.Q = [location_model_noise 0 0;...
    0 location_model_noise 0;...
    0 0 heading_model_noise]; % model covariance matrix
opt.R = [location_measure_noise 0;
    0 location_measure_noise]; % measurement covariance
opt.M = [1 0 0;
    0 1 0];
%opt.time = data.time;
%opt.wheelbase = 2.57048;


%% Separate memory
x0 = x_true(:,1);
xh = zeros(nx, nt); xh(:,1) = x0;
yh = zeros(ny, nt); yh(:,1) = y(:,1);

opt.x0 = x0;

pf.Ns              = 800;                 % number of particles
pf.w               = zeros(pf.Ns, nt);    % weights
pf.particles       = zeros(nx, pf.Ns, nt);% initialize particles

%% Estimate state
if (isMC==0)
    for k = 2:nt
        fprintf('Iteration = %d/%d\n',k,nt);
        % --- Use PF for Missing Observation
        [xh(:,k), pf] = PF_mo(k,y(:,k),[u v],pf, 'systematic_resampling',opt,0);
        % --- filtered observation
        yh(:,k) = Obs(xh(:,k),opt.M, 0);
    end
    
    if (isMovie==1)
        filename='./results/PF_evolution_indoor.avi';
        vid = VideoWriter(filename);
        vid.Quality = 100;
        vid.FrameRate = 20;
        open(vid)
        frameRate = .2; % seconds between frames
        
        h = figure('name','PF evolution');
        hold on
        tic
        for i=2:nt
            plot([xh(1,i-1) xh(1,i)],[xh(2,i-1) xh(2,i)],'b--','LineWidth',2);
            plot([x_true(1,i-1) x_true(1,i)],[x_true(2,i-1) x_true(2,i)],'r','LineWidth',2);
            if obs_index(i)==1
                plot(y(1,i),y(2,i),'gs');
            end
            if (i==snap_shot)
                h2 = figure('name','snapshot');
                hold on
                plot(xh(1,1:i),xh(2,1:i),'b--','LineWidth',2);
                plot(x_true(1,1:i), x_true(2,1:i),'r','LineWidth',2);
                %plot(y(1,1:i),y(2,1:i),'gs');
                
                col_min = min(pf.w(:,i));
                col_max = max(pf.w(:,i));
                if (col_min~=col_max)
                    col_ix = (col_max - pf.w(:,i))./(col_max - col_min);
                else
                    col_ix = pf.w(:,i);
                end
                for j=1:pf.Ns
                    plot(pf.particles(1,j,i),pf.particles(2,j,i),'.',...
                        'Color',[col_ix(j) col_ix(j) col_ix(j)]);
                end
                %ylim([-60 60]);
                %xlim([-50 100]);
                colormap(flipud(gray));
                colh = colorbar;
                %set(colh,'YDir','reverse');
                if (col_min<col_max)
                    set(gca, 'CLim', [col_min, col_max]);
                end
                xlabel('(meters)','FontSize',14);
                ylabel('(meters)','FontSize',14);
                set(gca,'FontSize',16);
                box on;
                legend('grpLASSO+PF','truth','grpLASSO');
                saveas(h2,'./results/snap_shot.eps','epsc');
                hold off
                close(h2);
            end
            
            plot(pf.particles(1,:,i),pf.particles(2,:,i),'.',...
                    'Color',[0.5 0.5 0.5]);
            
            %ylim([-60 120]);
            %xlim([-100 100]);
            box on
            
            writeVideo(vid,getframe(gcf));
            
            child = get(gca,'children');
            delete(child(1));
        end
        stopWatch = toc;
        fprintf('Ellapsed time: %f',stopWatch/60);
        hold off
        
        close(vid);
    end
    figure(3)
    plot(xh(1,:),xh(2,:),'LineWidth',2);
    hold on
    plot(y(1,:),y(2,:),'ks');
    plot(x_true(1,:),x_true(2,:),'r','LineWidth',2);
    
    %fprintf('RMSE of open-loop: %f\n',sqrt(mseCal(data.y_open_loop,...
    %    data1.y_test)));
    fprintf('RMSE of LASSO: %f\n',sqrt(mseCal(data1.y_guess_test,...
        data1.y_test)));
    fprintf('RMSE of LASSO+PF: %f\n',sqrt(mseCal(data1.y,xh(1:2,:)')));
else
    MC_run = 800;
    for i=1:MC_run
        fprintf('MC progress... %.2f%%\n',round(i/MC_run*100));
        pf_temp = pf;
        for k = 2:nt
            [xh_temp(:,k), pf_temp] = PF_mo(k,y(:,k),[u v],pf_temp, 'systematic_resampling',opt,0);
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


