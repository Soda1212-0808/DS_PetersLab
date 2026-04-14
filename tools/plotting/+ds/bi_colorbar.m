function bi_colorbar(colA, colB, max_val, gamma)
% bivariate_colorbar('P','G', max_val, gamma)
%
% colA, colB : 'P','G','R','B'
% max_val    : 强度上限（必须和主图一致）
% gamma      : 非线性（默认=1）

if nargin < 4 || isempty(gamma)
    gamma = 1;
end

if nargin < 3 || isempty(max_val)
    error('You must specify max_val');
end

colA = upper(colA);
colB = upper(colB);

%% ---------- colormap ----------
cmapA = ap.colormap(['W' colA], 256);
cmapB = ap.colormap(['W' colB], 256);

P = cmapA(end,:);
G = cmapB(end,:);
W = [1 1 1];

M = 0.5 * (P + G);

%% ---------- 构造网格 ----------
n = 200;
[a, b] = meshgrid(linspace(0, max_val, n));

a_n = (a / max_val).^gamma;
b_n = (b / max_val).^gamma;

%% ---------- 混色 ----------
RGB = zeros(n,n,3);
for k = 1:3
    RGB(:,:,k) = ...
        W(k)*(1-a_n).*(1-b_n) + ...
        P(k)*a_n.*(1-b_n)    + ...
        G(k)*(1-a_n).*b_n    + ...
        M(k)*a_n.*b_n;
end

RGB = min(max(RGB,0),1);

%% ---------- 画图 ----------
image(linspace(0,max_val,n), linspace(0,max_val,n), RGB);
axis xy;
axis square;

% xlabel(['A (' colA ')']);
% ylabel(['B (' colB ')']);

xticks([0 max_val]);
yticks([0 max_val]);

% title('Bivariate colorbar');