function out = classify_striatal_unit(spike_times, sens_times, move_times, T_total, varargin)
% CLASSIFY_STRIATAL_UNIT  (fast & rigorous, Shapley + block-CV)
% 用 Poisson LNP-GLM + 连续折交叉验证 + 双侧置换(早停) 区分
% sensory-driven / movement-driven / mixed / unclassified。
%
% Required:
%   spike_times : [N x 1] double, 秒
%   sens_times  : [Ks x 1] double, 秒
%   move_times  : [Km x 1] double, 秒
%   T_total     : scalar, 记录总时长(秒)
%
% Name-Value（推荐默认适配 RT≈0.15s）:
%   'BinSize'      : 0.02
%   'SensLags'     : [0   0.20]      % 刺激后感觉窗
%   'MoveLags'     : [-0.05 0.20]    % 动作窗（负滞后收紧）
%   'NumBases'     : 6
%   'Alpha'        : 0.5             % elastic-net α（更稀疏，防共线）
%   'Kfold'        : 5               % 连续折
%   'GapBins'      : 2               % 折间缓冲，减少泄漏
%   'NumPerm'      : 200
%   'AlphaSig'     : 0.01            % 显著性阈
%   'TwoSided'     : true            % 置换对 |ΔLL| 双侧
%   'UseParallel'  : true
%   'UseGPUConv'   : false           % 仅卷积用GPU（lassoglm仍CPU）
%   'Seed'         : 42
%
% Output fields:
%   .label   : 'sensory-driven' | 'movement-driven' | 'mixed' | 'unclassified'
%   .dLL_S, .dLL_M  : Shapley 唯一贡献（交叉验证）
%   .p_S,  .p_M     : 双侧置换p值（早停）
%   .beta_S, .beta_M: 全数据+固定λ 拟合的系数（用于可视化核形）
%   .info           : 参数、λ、LL分解、基函数等

% -------- 参数 --------
p = inputParser;
addParameter(p, 'BinSize',   0.02);
addParameter(p, 'SensLags',  [0 0.20]);
addParameter(p, 'MoveLags',  [-0.05 0.20]);
addParameter(p, 'NumBases',  6);
addParameter(p, 'Alpha',     0.5);
addParameter(p, 'Kfold',     5);
addParameter(p, 'GapBins',   2);
addParameter(p, 'NumPerm',   200);
addParameter(p, 'AlphaSig',  0.01);
addParameter(p, 'TwoSided',  true);
addParameter(p, 'UseParallel', true);
addParameter(p, 'UseGPUConv',  false);
addParameter(p, 'Seed',        42);
parse(p, varargin{:});
opt = p.Results;

rng(opt.Seed);

% -------- bin spikes --------
edges = 0:opt.BinSize:T_total;
T = numel(edges)-1;
y = histcounts(spike_times, edges)';  % [T x 1]

% -------- events -> 列车 --------
s_evt = make_event_train(sens_times, edges); % [T x 1]
m_evt = make_event_train(move_times, edges); % [T x 1]

% -------- bases & 卷积（向量化；可GPU） --------
B_S = make_rc_basis(opt.SensLags, opt.BinSize, opt.NumBases); % [L_S x nbS]
B_M = make_rc_basis(opt.MoveLags, opt.BinSize, opt.NumBases); % [L_M x nbM]

X_S = convolve_with_basis_fast(s_evt, B_S, opt.UseGPUConv);   % [T x nbS]
X_M = convolve_with_basis_fast(m_evt, B_M, opt.UseGPUConv);   % [T x nbM]

% -------- 慢漂移（不标准化；每折再zscore） --------
X_C = poly_drift(T, 2);  % [T x 2], 列正交

% -------- S优先：在XS子空间上残差化XM --------
[Q,~] = qr(X_S, 0);
X_M = X_M - Q*(Q'*X_M);

% -------- 设计矩阵 & 分组索引 --------
X_full = [X_S, X_M, X_C];       % [T x P]
P_S = size(X_S,2);
P_M = size(X_M,2);
grp.S = 1:P_S;
grp.M = P_S + (1:P_M);
grp.C = P_S + P_M + (1:size(X_C,2));

% -------- 连续折 + 间隔 --------
folds = make_block_folds(T, opt.Kfold, opt.GapBins);

% -------- 选 λ（一次），并固定复用 --------
[Xz_all, mu_all, sd_all] = standardize_cols(X_full, true(T,1)); %#ok<ASGLU>
opts = statset('UseParallel', logical(opt.UseParallel));
[~, FitCV] = lassoglm(Xz_all, y, 'poisson', 'Alpha', opt.Alpha, ...
    'CV', 5, 'Standardize', false, 'Link', 'log', 'Options', opts);
lambda_full = FitCV.Lambda(FitCV.IndexMinDeviance);

% -------- CV-LL：Shapley 分解 --------
LL_C  = cv_poiss_lasso_fast(X_C,        y, folds, opt.Alpha, lambda_full, opt.UseParallel);
LL_S  = cv_poiss_lasso_fast([X_S,X_C],  y, folds, opt.Alpha, lambda_full, opt.UseParallel);
LL_M  = cv_poiss_lasso_fast([X_M,X_C],  y, folds, opt.Alpha, lambda_full, opt.UseParallel);
LL_SM = cv_poiss_lasso_fast([X_S,X_M,X_C], y, folds, opt.Alpha, lambda_full, opt.UseParallel);

dLL_S = 0.5*((LL_S-LL_C) + (LL_SM-LL_M));
dLL_M = 0.5*((LL_M-LL_C) + (LL_SM-LL_S));

% -------- 置换（双侧+早停；与上面同流程&同S优先残差化） --------
funS = @(s_evt_perm) cv_dLL_shapley_given_events(y, s_evt_perm, m_evt, X_C, B_S, B_M, ...
    folds, opt.Alpha, lambda_full, true,  opt.UseParallel, opt.UseGPUConv);
funM = @(m_evt_perm) cv_dLL_shapley_given_events(y, s_evt, m_evt_perm, X_C, B_S, B_M, ...
    folds, opt.Alpha, lambda_full, false, opt.UseParallel, opt.UseGPUConv);

p_S = perm_test_shift_early(funS, s_evt, opt.NumPerm, opt.AlphaSig, opt.TwoSided);
p_M = perm_test_shift_early(funM, m_evt, opt.NumPerm, opt.AlphaSig, opt.TwoSided);

% -------- 标签 --------
alpha = opt.AlphaSig;
if (p_S<alpha) && (dLL_S>dLL_M)
    label = 'sensory-driven';
elseif (p_M<alpha) && (dLL_M>dLL_S)
    label = 'movement-driven';
elseif (p_S<alpha) && (p_M<alpha) && (abs(dLL_S - dLL_M) <= 0.1*(dLL_S + dLL_M + eps))
    label = 'mixed';
else
    label = 'unclassified';
end

% -------- 全数据拟合（固定λ；仅为可视化核形） --------
[Ball, FitAll] = lassoglm(Xz_all, y, 'poisson', 'Alpha', opt.Alpha, ...
    'Lambda', lambda_full, 'Standardize', false, 'Link', 'log', 'Options', opts);
beta_all = [FitAll.Intercept; Ball]; % 标准化空间下的系数
beta_S = beta_all(1+grp.S);
beta_M = beta_all(1+grp.M);

% -------- 输出 --------
out = struct();
out.label = label;
out.dLL_S = dLL_S;
out.dLL_M = dLL_M;
out.p_S   = p_S;
out.p_M   = p_M;
out.beta_S = beta_S;
out.beta_M = beta_M;
out.info = struct('BinSize', opt.BinSize, 'SensLags', opt.SensLags, 'MoveLags', opt.MoveLags, ...
    'NumBases', opt.NumBases, 'Alpha', opt.Alpha, 'Kfold', opt.Kfold, 'GapBins', opt.GapBins, ...
    'NumPerm', opt.NumPerm, 'AlphaSig', opt.AlphaSig, 'TwoSided', opt.TwoSided, ...
    'lambda', lambda_full, 'basis_S', B_S, 'basis_M', B_M, ...
    'LL_parts', struct('LL_C',LL_C,'LL_S',LL_S,'LL_M',LL_M,'LL_SM',LL_SM) );
end

% ======================= 子函数 =======================

function x = make_event_train(evt_times, edges)
    evt_times = evt_times(:);
    x = histcounts(evt_times, edges)';  % [T x 1]
end

function B = make_rc_basis(lag_win, bin, nb)
% Raised-cosine basis on [L1, L2], then orthonormalize.
    L1 = lag_win(1); L2 = lag_win(2);
    tau = (L1:bin:L2)'; L = numel(tau);
    if L<=1, error('Lag window too small'); end
    centers = linspace(0, pi, nb);
    ph = (tau - L1) / max(L2 - L1, eps) * pi;
    B = zeros(L, nb);
    for i = 1:nb
        z = ph - centers(i);
        z = max(-pi, min(pi, z));
        B(:,i) = 0.5*(1 + cos(z));
    end
    [Q,~] = qr(B,0);   % 列正交
    B = Q;
end

function X = convolve_with_basis_fast(evt, B, useGPU)
% Vectorized convolution across bases using conv2; optional GPU.
    K = flipud(B); % time reverse
    if useGPU && gpu_available()
        X = gather(conv2(gpuArray(evt), gpuArray(K), 'same')); % [T x nb]
    else
        X = conv2(evt, K, 'same'); % [T x nb]
    end
end

function tf = gpu_available()
    tf = false;
    try
        d = parallel.gpu.GPUDevice.isAvailable;
        tf = logical(d);
    catch
        tf = false;
    end
end

function D = poly_drift(T, order)
% 多项式慢漂移；返回列正交基（不做zscore，避免泄漏）
    t = linspace(-1,1,T)';                 % [T x 1]
    V = zeros(T, order);
    for k=1:order
        V(:,k) = t.^k;
    end
    [Q,~] = qr(V,0);
    D = Q;
end

function folds = make_block_folds(T, K, gapBins)
% 连续K折，测试段两侧留出gapBins不参与训练
    edges = round(linspace(0, T, K+1));
    folds = cell(K,1);
    for k=1:K
        te = false(T,1);
        te(edges(k)+1 : edges(k+1)) = true;
        tr = ~te;
        if gapBins>0
            g1 = max(1, edges(k)+1-gapBins) : edges(k);
            g2 = edges(k+1)+1 : min(T, edges(k+1)+gapBins);
            tr(g1) = false; tr(g2) = false;
        end
        folds{k} = struct('train', tr, 'test', te);
    end
end

function [Xz, mu, sd] = standardize_cols(X, train_mask)
% 用训练行统计量做列zscore，并应用到所有行
    mu = mean(X(train_mask,:), 1);
    sd = std(X(train_mask,:), 0, 1);
    sd(sd==0 | isnan(sd)) = 1;
    Xz = (X - mu) ./ sd;
end

function LL = cv_poiss_lasso_fast(X, y, folds, alpha, lambda_fixed, usePar)
% 固定λ的交叉验证；每折用训练集统计量标准化
    K = numel(folds);
    LLs = zeros(K,1);
    if usePar && license('test','Distrib_Computing_Toolbox')
        parfor k = 1:K
            LLs(k) = fold_LL_once(X, y, folds{k}, alpha, lambda_fixed);
        end
    else
        for k = 1:K
            LLs(k) = fold_LL_once(X, y, folds{k}, alpha, lambda_fixed);
        end
    end
    LL = sum(LLs);
end

function LLk = fold_LL_once(X, y, fold, alpha, lambda_fixed)
    tr = fold.train; te = fold.test;
    [Xz, mu, sd] = standardize_cols(X, tr);
    Xtr = Xz(tr,:);  Xte = Xz(te,:);
    ytr = y(tr);     yte = y(te);
    % 固定lambda拟合
    [B,Fit] = lassoglm(Xtr, ytr, 'poisson', 'Alpha', alpha, ...
        'Lambda', lambda_fixed, 'Standardize', false, 'Link', 'log');
    beta0 = Fit.Intercept; beta = B;
    mu_hat = exp(beta0 + Xte*beta);
    LLk = sum( yte.*log(mu_hat+eps) - mu_hat - gammaln(yte+1) );
end

function dLL = cv_dLL_shapley_given_events(y, s_evt, m_evt, X_C, B_S, B_M, ...
    folds, alpha, lambda_ref, isS, usePar, useGPU)
% 给定（可能置换后的）事件列，按“同流程+同残差化”重建设计并算 Shapley ΔLL
    X_S = convolve_with_basis_fast(s_evt, B_S, useGPU);
    X_M = convolve_with_basis_fast(m_evt, B_M, useGPU);
    % S优先残差化
    [Q,~] = qr(X_S,0);
    X_M = X_M - Q*(Q'*X_M);

    LL_C  = cv_poiss_lasso_fast(X_C,        y, folds, alpha, lambda_ref, usePar);
    LL_S  = cv_poiss_lasso_fast([X_S,X_C],  y, folds, alpha, lambda_ref, usePar);
    LL_M  = cv_poiss_lasso_fast([X_M,X_C],  y, folds, alpha, lambda_ref, usePar);
    LL_SM = cv_poiss_lasso_fast([X_S,X_M,X_C], y, folds, alpha, lambda_ref, usePar);

    dS = 0.5*((LL_S-LL_C) + (LL_SM-LL_M));
    dM = 0.5*((LL_M-LL_C) + (LL_SM-LL_S));
    dLL = dS; if ~isS, dLL = dM; end
end

function p = perm_test_shift_early(fun_dLL, evt, B, alpha, twoSided)
% 循环移位置换，双侧/单侧 + 早停（显著/无望）
    T = numel(evt);
    real_dLL = fun_dLL(evt);
    s = 0; % 计数“更极端”的次数
    for b = 1:B
        sh = randi(T)-1;
        evt_perm = evt([ (sh+1):T, 1:sh ]);
        d = fun_dLL(evt_perm);
        if twoSided
            if abs(d) >= abs(real_dLL), s = s + 1; end
        else
            if d >= real_dLL, s = s + 1; end
        end

        % 早停：最乐观/最悲观界
        p_min_possible = (s + 1) / (B + 1);             % 剩余全不极端
        p_max_possible = (s + (B - b) + 1) / (B + 1);   % 剩余全极端
        if p_min_possible > alpha || p_max_possible <= alpha
            p = (s + 1) / (b + 1);  % 保守估计当前p
            return;
        end
    end
    p = (s + 1) / (B + 1);
end
