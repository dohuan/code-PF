load ./results/run_MC.mat

min_rmse = 1000;
for i=1:size(MC,2)
	%err(i) = mseCal(x_true(1:2,:)',(MC(i).xh(1:2,:))');
	if (min_rmse>err_MC(i,1))
		min_rmse = err_MC(i,1);
		min_ix = i;
	end
end
plot(MC(min_ix).xh(1,2:end),MC(min_ix).xh(2,2:end));
hold on
plot(x_true(1,:),x_true(2,:),'r');


figure(2)
plot(pf.particles(1,:,1),pf.particles(2,:,1),'r.')
hold on
plot(pf.particles(1,:,2),pf.particles(2,:,2),'b.')



% --------- Plot particles

plot(xh(1,:),xh(2,:),'LineWidth',2);
hold on
plot(y(1,:),y(2,:),'ks');
plot(x_true(1,:),x_true(2,:),'r','LineWidth',2);


% ============ Test Sys_indoor.m ================
clear
clc
[~, ~, raw] = xlsread('.\data\FeaturesAndLocations.xls','Sheet1','A2:AL464');
data = reshape([raw{:}],size(raw));
dataSize = 400;
scaleRatio = 1;
input = downSampling([data(1:dataSize,1) data(1:dataSize,2)],scaleRatio);
opt.time = downSampling(data(1:dataSize,5),scaleRatio);

%u = input(:,1);
%v = input(:,2);

data1 = load('./data/alien_0213.mat');
[IC,IX] = sort(data1.index(data1.validateIndex+1:data1.testIndex));
y_test = data1.y_test(IX',:);
y = data1.y_guess_test(IX',:); y = y';
heading_angle = LineAngleEstimator(y_test,1);
x_true = [(y_test)'; heading_angle];

x0 = x_true(:,1);
x_sys(:,1) = x0;
nt = size(x_true,2);

for i=2:nt
	x_sys(:,i) = Sys_indoor(i,x_sys(:,i-1),input,[0 0 0],opt);
end
hold on
plot(x_true(1,:),x_true(2,:),'r');
plot(x_sys(1,:),x_sys(2,:),'b--');
hold off
% ================================================