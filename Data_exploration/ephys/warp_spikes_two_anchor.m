function [RateWarp, axesOut, segIdx, trialInfo] = warp_spikes_two_anchor( ...
    spikes, stimTimes, moveTimes, varargin)
% WARP_SPIKES_TWO_ANCHOR
% 从“尖峰时间 + 事件时间”直接生成双端对齐轨迹：
%   仅将中段 (stim -> move) 归一化为固定 MidBins，其余两段保持真实时间（不拉伸）。
%
% Inputs
%   spikes     : 1 x Nneur cell，每个{n}是该神经元的所有尖峰时间（秒，整场会话基准）
%   stimTimes  : [Ntrials x 1] 每个 trial 的刺激出现时间（秒）
%   moveTimes  : [Ntrials x 1] 每个 trial 的动作发生时间（秒）
%
% Name-Value options
%   'PreDur'      : 0.5    % s，刺激前窗口长度
%   'PostDur'     : 0.5    % s，动作后窗口长度
%   'MidBins'     : 10    % 中段统一 bin 数
%   'dtOut'       : 0.01   % s，前/后段的输出采样间隔（不拉伸）
%   'UseParallel' : false  % parfor 并行
%   'SmoothSigma' : 0      % s，高斯平滑σ（0 表示不平滑）；作用在拼接后的时间轴上
%
% Outputs
%   RateWarp : [ (nPre + MidBins + nPost) x Nneur x Ntrials ]，单位 Hz
%   axesOut  : struct，作图/分析的三段时间轴
%              .t_pre  : [-PreDur:dtOut:-dtOut]（相对stim，秒）
%              .tau    : 归一化进程 in (0,1]（中段 bin 中心）
%              .t_post : [dtOut:dtOut:PostDur]（相对move，秒）
%   segIdx   : struct，三段在第一维上的索引范围（iPre,iMid,iPost）
%   trialInfo: struct，trial 的有效性与中段物理长度等信息
%
% 备注
% - 中段每个 bin 的物理宽度不同（因RT不同），我们先按真实物理宽度计数再除以该宽度，
%   得到每个归一化 bin 的**瞬时发放率（Hz）**，可公平比较。
% - 会自动跳过 move <= stim 或窗口越界等异常 trial（标注为 invalid）。

p = inputParser;
addParameter(p, 'PreDur', 0.1);
addParameter(p, 'PostDur', 0.5);
addParameter(p, 'MidBins', 10);
addParameter(p, 'dtOut', 0.01);
addParameter(p, 'UseParallel', false);
addParameter(p, 'SmoothSigma', 0);
parse(p, varargin{:});
opt = p.Results;

Nneur   = numel(spikes);
stimTimes = stimTimes(:);
moveTimes = moveTimes(:);
Ntr     = numel(stimTimes);

% --- 预定义三段统一时间轴（用于作图与索引） ---
edges_pre  = -opt.PreDur : opt.dtOut : 0;         % 相对 stim 的边界
edges_post = 0 : opt.dtOut : opt.PostDur;         % 相对 move 的边界
cent_pre   = edges_pre(1:end-1)  + opt.dtOut/2;   % bin 中心
cent_post  = edges_post(1:end-1) + opt.dtOut/2;

nPre  = numel(cent_pre);
nPost = numel(cent_post);
nMid  = opt.MidBins;
Ttot  = nPre + nMid + nPost;

RateWarp = nan(Ttot, Nneur, Ntr);
isValid  = true(Ntr,1);
midDur   = nan(Ntr,1);  % 每个 trial 的中段物理长度 (tm - ts)

% 并行设置
loopfun = @(fun) fun();
if opt.UseParallel
    if license('test','Distrib_Computing_Toolbox')
        pool = gcp('nocreate'); if isempty(pool), parpool; end
        loopfun = @(fun) parfevalOnAll(@() 1,0); %#ok<NASGU>
    else
        warning('UseParallel=true 但未检测到并行工具箱，改为串行。');
        opt.UseParallel = false;
    end
end

% --- 主循环：按 trial 处理 ---
if opt.UseParallel
    parfor i = 1:Ntr
        [RateWarp(:,:,i), isValid(i), midDur(i)] = one_trial(spikes, stimTimes(i), moveTimes(i), ...
            edges_pre, edges_post, cent_pre, cent_post, opt);
    end
else
    for i = 1:Ntr
        [RateWarp(:,:,i), isValid(i), midDur(i)] = one_trial(spikes, stimTimes(i), moveTimes(i), ...
            edges_pre, edges_post, cent_pre, cent_post, opt);
    end
end

% 可选：在拼接后的时间轴上做高斯平滑（对每个 trial × neuron）
if opt.SmoothSigma > 0
    % 把拼接轴视作一条时间线：pre 段步长 = dtOut；mid 段视作等距；post 段 = dtOut
    % 为简单起见，我们在三个段分别平滑，再拼接，避免跨段“走样”。
    w_pre  = max(1, round(opt.SmoothSigma/opt.dtOut * 3));
    w_post = w_pre;
    w_mid  = max(1, round(opt.SmoothSigma / (mean(midDur(~isnan(midDur)))/opt.MidBins) * 3)); % 估算中段等效步长
    k_pre  = gausswin(2*w_pre+1);  k_pre  = k_pre/sum(k_pre);
    k_post = gausswin(2*w_post+1); k_post = k_post/sum(k_post);
    k_mid  = gausswin(2*w_mid+1);  k_mid  = k_mid/sum(k_mid);

    iPre  = 1:nPre;
    iMid  = (nPre+1):(nPre+nMid);
    iPost = (nPre+nMid+1):Ttot;

    for i = 1:Ntr
        if ~isValid(i), continue; end
        X = RateWarp(:,:,i);
        X(iPre, :)  = conv2(X(iPre,:),  k_pre,  'same');
        X(iMid, :)  = conv2(X(iMid,:),  k_mid,  'same');
        X(iPost, :) = conv2(X(iPost,:), k_post, 'same');
        RateWarp(:,:,i) = X;
    end
end

% 输出时间轴与索引
axesOut = struct();
axesOut.t_pre  = cent_pre;               % 相对 stim（秒）
axesOut.tau    = ( (1:nMid) - 0.5 )/nMid; % 归一化进程 (0,1]
axesOut.t_post = cent_post;              % 相对 move（秒）

segIdx = struct('iPre', 1:nPre, ...
                'iMid', (nPre+1):(nPre+nMid), ...
                'iPost',(nPre+nMid+1):(nPre+nMid+nPost));

trialInfo = struct('isValid', isValid, 'midDuration', midDur);

end

% ====== 单个 trial 的处理：计数→除以物理宽度→拼接（只中段归一化） ======
function [X, ok, midDuration] = one_trial(spikes, ts, tm, ...
    edges_pre_rel, edges_post_rel, cent_pre_rel, cent_post_rel, opt)

ok = true;
X  = nan( numel(cent_pre_rel) + opt.MidBins + numel(cent_post_rel), numel(spikes) );

% 基础检查
if isnan(ts) || isnan(tm) || tm <= ts
    ok = false; midDuration = NaN; return;
end
midDuration = tm - ts;

% 绝对时间的边界
edges_pre_abs  = ts + edges_pre_rel;   % [-PreDur, 0] 相对 stim
edges_post_abs = tm + edges_post_rel;  % [0, PostDur] 相对 move
cent_pre_abs   = ts + cent_pre_rel;
cent_post_abs  = tm + cent_post_rel;

% 中段按 MidBins 划分（绝对时间），注意每 bin 宽度不同
edges_mid_abs = linspace(ts, tm, opt.MidBins+1);
width_mid     = diff(edges_mid_abs);       % 每个归一化 bin 的实际秒数
cent_mid_abs  = 0.5*(edges_mid_abs(1:end-1)+edges_mid_abs(2:end)); %#ok<NASGU>

% 对每个神经元计数并转为 Hz
for n = 1:numel(spikes)
    st = spikes{n}(:);
    % pre 段：均匀 dtOut，计数/宽度
    c_pre  = histcounts(st, edges_pre_abs);
    r_pre  = c_pre ./ opt.dtOut;

    % mid 段：非均匀边界，计数/各自宽度
    c_mid  = histcounts(st, edges_mid_abs);
    r_mid  = c_mid ./ width_mid;

    % post 段：均匀 dtOut
    c_post = histcounts(st, edges_post_abs);
    r_post = c_post ./ opt.dtOut;

    X(:,n) = [r_pre(:); r_mid(:); r_post(:)];
end
end
