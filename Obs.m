function y = Obs(k,x,M,noise)
%% M: observation matrix
    y = M*x(:,k) + noise;
end