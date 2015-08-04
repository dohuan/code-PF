function y = Obs(x,M,noise)
%% M: observation matrix
    y = M*x + noise;
end