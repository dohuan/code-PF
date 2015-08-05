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