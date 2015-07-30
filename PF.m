function [xh,pf] = PF(k,Sys,yk,u,pf,resampling_strategy,opt)
%% Generic Particle Filter
%                           Modified: Huan Do
% Inputs:
% sys  = function handle to process equation
% y    = observation vector at time k (column vector)
% pf   = structure with the following fields
%   .k                = iteration number
%   .Ns               = number of particles
%   .w                = weights   (Ns x T)
%   .particles        = particles (nx x Ns x T)
%   .gen_x0           = function handle of a procedure that samples from the initial pdf p_x0
%   .p_yk_given_xk    = function handle of the observation likelihood PDF p(y[k] | x[k])
%   .gen_sys_noise    = function handle of a procedure that generates system noise
% resampling_strategy = resampling strategy. Set it either to
%                       'multinomial_resampling' or 'systematic_resampling'
%
% Outputs:
% xh   = estimated state
% pf    = the same structure as in the input but updated at iteration k

if k == 1
    error('error: k must be an integer greater or equal than 2');
end
Ns = pf.Ns;                              % number of particles
nx = size(pf.particles,1);               % number of states
wkm1 = pf.w(:, k-1);                     % weights of last iteration

if k == 2
    for i = 1:Ns                          % simulate initial particles
        temp = mvnrnd(zeros(3,1),opt.Q,1);    % generate multi-variate normal dist noise
        pf.particles(:,i,1) = temp'; % at time k=1
    end
    wkm1 = repmat(1/Ns, Ns, 1);           % all particles have the same weight
end

xkm1 = pf.particles(:,:,k-1); % extract particles from last iteration;
xk   = zeros(size(xkm1));     % = zeros(nx,Ns);
wk   = zeros(size(wkm1));     % = zeros(Ns,1);

for i=1:Ns
    noise_sys = mvnrnd(zeros(nx,1),opt.Q,1);
    xk(:,i) = Sys(k,xkm1,u,noise_sys,opt);
    wk(i) = wkm1(i)*p_y_given_x(k, yk, xk(:,i));
end
% --- Normalize weight vector
wk = wk./sum(wk);
% --- Calculate effective sample size: eq 51, Ref 1
Neff = 1/sum(wk.^2);

%% Resampling
resample_percentaje = 0.50;
Nt = resample_percentaje*Ns;
if Neff < Nt
    disp('Resampling ...')
    [xk, wk] = resample(xk, wk, resampling_strategy);
    % {xk, wk} is an approximate discrete representation of p(x_k | y_{1:k})
end

%% Compute estimated state
xh = zeros(nx,1);
for i = 1:Ns;
    xh = xh + wk(i)*xk(:,i);
end

%% Store new weights and particles
pf.w(:,k) = wk;
pf.particles(:,:,k) = xk;

end

function out = p_y_given_x(k,y,x,opt)
ny = length(y);
noise_obs = mvnrnd(zeros(ny,1),opt.R,1);
out = mvnpdf(y - Obs(k,x,opt.M,noise_obs),[0 0],opt.R);
end

function [xk, wk, idx] = resample(xk, wk, resampling_strategy)
Ns = length(wk);  % Ns = number of particles
switch resampling_strategy
    case 'multinomial_resampling'
        with_replacement = true;
        idx = randsample(1:Ns, Ns, with_replacement, wk);
    case 'systematic_resampling'
        % this is performing latin hypercube sampling on wk
        edges = min([0 cumsum(wk)'],1); % protect against accumulated round-off
        edges(end) = 1;                 % get the upper edge exact
        u1 = rand/Ns;
        % this works like the inverse of the empirical distribution and returns
        % the interval where the sample is to be found
        [~, idx] = histc(u1:1/Ns:1, edges);
    otherwise
        error('Resampling strategy not implemented')
end;
xk = xk(:,idx);                    % extract new particles
wk = repmat(1/Ns, 1, Ns);          % now all particles have the same weight
end