function Precomp = mk_precomp_striatum(sens_times, move_times, T_total, varargin)
% MK_PRECOMP_STRIATUM
% 会话级预计算（标量 struct）：edges/T、XS/XM/XC（含 S→M 残差化）、
% block K-fold 折 + 每折 μ/σ、基函数等。可复用给同一天全部神经元。
%
% 推荐与 RT~0.15s 一致的默认窗：
%   SensLags=[0 0.20], MoveLags=[-0.05 0.20]

p = inputParser;
addParameter(p,'BinSize',0.02);
addParameter(p,'SensLags',[0 0.20]);
addParameter(p,'MoveLags',[-0.05 0.20]);
addParameter(p,'NumBases',6);
addParameter(p,'Alpha',0.5);
addParameter(p,'Kfold',5);
addParameter(p,'GapBins',2);
addParameter(p,'UseParallel',true);
addParameter(p,'UseGPUConv',false);
addParameter(p,'UseFFTConv',false);
addParameter(p,'Seed',42);
parse(p,varargin{:});
opt = p.Results; rng(opt.Seed);

% --- 时间边界 ---
edges = 0:opt.BinSize:T_total;
T = numel(edges)-1;

% --- 事件列（显式 BinEdges，避免 histcounts 误判） ---
s_evt = histcounts(double(sens_times(:)), 'BinEdges', double(edges))';  % [T x 1]
m_evt = histcounts(double(move_times(:)), 'BinEdges', double(edges))';

% --- 基函数 ---
B_S = make_rc_basis(opt.SensLags, opt.BinSize, opt.NumBases);
B_M = make_rc_basis(opt.MoveLags, opt.BinSize, opt.NumBases);

% --- 卷积（向量化；可选 GPU/FFT） ---
XS = conv_basis(s_evt, B_S, opt.UseGPUConv, opt.UseFFTConv); % [T x P_S]
XM = conv_basis(m_evt, B_M, opt.UseGPUConv, opt.UseFFTConv); % [T x P_M]
XC = poly_drift(T, 2);                                       % [T x P_C]（列正交）

% --- S 优先：在 XS 子空间上残差化 XM ---
[Q,~] = qr(XS,0);
XM = XM - Q*(Q'*XM);

% --- FULL 设计仅用于求每折 μ/σ ---
Xfull = [XS XM XC];
P_S = size(XS,2); P_M = size(XM,2); P_C = size(XC,2);
grpS = 1:P_S; grpM = P_S+(1:P_M); grpC = P_S+P_M+(1:P_C);

% --- 连续折 + 折间缓冲 ---
folds = make_block_folds(T, opt.Kfold, opt.GapBins);

% --- 每折训练行的 μ/σ（避免信息泄漏） ---
mu = cell(opt.Kfold,1); sd = cell(opt.Kfold,1);
for k=1:opt.Kfold
    tr = folds{k}.train;
    mu{k} = mean(Xfull(tr,:),1);
    sd{k} = std(Xfull(tr,:),0,1); sd{k}(sd{k}==0|isnan(sd{k}))=1;
end

% --- 打包（标量 struct） ---

Precomp = struct('edges',edges,'T',T, ...
                 'XS',XS,'XM',XM,'XC',XC, ...
                 'B_S',B_S,'B_M',B_M, ...
                 'folds',{folds}, ...   % ← 注意花括号
                 'mu',{mu}, ...         % ← 注意花括号
                 'sd',{sd}, ...         % ← 注意花括号
                 'Alpha',opt.Alpha, ...
                 'grpS',grpS,'grpM',grpM,'grpC',grpC, ...
                 'UseParallel',opt.UseParallel, ...
                 'UseGPUConv',opt.UseGPUConv,'UseFFTConv',opt.UseFFTConv);


% --- 强校验：一定要是“标量 struct” ---
assert(isstruct(Precomp) && isscalar(Precomp) && isfield(Precomp,'edges') && isfield(Precomp,'XS'), ...
    'mk_precomp_striatum 返回的必须是标量 struct；当前类型/尺寸异常。');

end

% ===== 辅助函数 =====
function B = make_rc_basis(lag_win, bin, nb)
    L1=lag_win(1); L2=lag_win(2);
    tau=(L1:bin:L2)'; assert(numel(tau)>1,'Lag window too small');
    c=linspace(0,pi,nb); ph=(tau-L1)/max(L2-L1,eps)*pi;
    B=zeros(numel(tau),nb);
    for i=1:nb
        z=max(-pi,min(pi,ph-c(i)));
        B(:,i)=0.5*(1+cos(z));
    end
    [Q,~]=qr(B,0); B=Q;
end

function X=conv_basis(evt,B,useGPU,useFFT)
    K=flipud(B);
    if useGPU && gpu_available()
        X=gather(conv2(gpuArray(evt),gpuArray(K),'same')); return;
    end
    if useFFT && size(B,1)>64
        T=numel(evt); L=size(B,1); N=2^nextpow2(T+L-1);
        E=fft(evt,N); X=zeros(T,size(B,2));
        for i=1:size(B,2)
            Ki=fft(K(:,i),N); yi=real(ifft(E.*Ki));
            s=floor((L-1)/2); yi=yi((1:T)+s);
            X(:,i)=yi;
        end
    else
        X=conv2(evt,K,'same');
    end
end

function tf=gpu_available()
    tf=false; try tf=logical(parallel.gpu.GPUDevice.isAvailable); catch, tf=false; end
end

function C=poly_drift(T,order)
    t=linspace(-1,1,T)'; V=zeros(T,order);
    for k=1:order, V(:,k)=t.^k; end
    [Q,~]=qr(V,0); C=Q;
end

function folds=make_block_folds(T,K,g)
    e=round(linspace(0,T,K+1)); folds=cell(K,1);
    for k=1:K
        te=false(T,1); te(e(k)+1:e(k+1))=true; tr=~te;
        if g>0, tr(max(1,e(k)+1-g):e(k))=false; tr(e(k+1)+1:min(T,e(k+1)+g))=false; end
        folds{k}=struct('train',tr,'test',te);
    end
end
