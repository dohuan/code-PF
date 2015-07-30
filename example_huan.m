close all
clear
clc
%%
nt = 50;
nx = 3;
ny = 2;

% --- generate control commands
max_linear = 30;
min_linear = 10;
u = (max_linear-min_linear).*rand(nt-1,1) + min_linear; % linear control

max_heading = pi/5;
min_heading = -pi/5;
v = (max_heading-min_heading).*rand(nt-1,1) + min_heading; % heading control

%% Configuration
% --- Model noise
location_model_noise = 1; % \sigma_w1^2
heading_model_noise  = (1/180*pi)^2; %\sigma_w2^2

% --- Observation (measurement) noise
location_measure_noise = 500; % \sigma_e1^2

opt.Q = [location_model_noise 0 0;...
         0 location_model_noise 0;...
         0 0 heading_model_noise]; % model covariance matrix
opt.R = [location_measure_noise 0;
         0 location_measure_noise]; % measurement covariance 
opt.M = [1 0 0;
         0 1 0];

%% Simulate system
x0 = [0;0;0];
x(:,1) = x0;
noise_obs = mvnrand(zeros(ny,1),opt.R,1);
y(:,1) = Obs(1,x0,noise_obs);

for i=2:nt
    noise_sys = mvnrand(zeros(nx,1),opt.Q,1);
    noise_obs = mvnrand(zeros(ny,1),opt.R,1);
    x(:,i) = Sys(i,x(:,i-1),[u v],noise_sys,opt);
    y(:,i) = Obs(i,x(:,i),opt.M,noise_obs);
end
