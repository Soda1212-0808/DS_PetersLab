function RGB = colormap_overlay(A, B, colA, colB, gamma, max_val)
% RGB = colormap_overlay(A, B, 'P', 'G', gamma, max_val)
%
% A, B     : 两个矩阵（最小值=0）
% colA/B   : 'P','G','R','B'
% gamma    : 非线性（默认=1）
% max_val  : 可选，自定义最大值
%
% 规则：
% - 若不输入 max_val → 自动用 max([A(:);B(:)])
% - 若输入 → 使用固定上限

if nargin < 5 || isempty(gamma)
    gamma = 1;
end

if nargin < 6 || isempty(max_val)
    max_val = max([A(:); B(:)]);
end

if max_val == 0
    max_val = 1;
end

% 强制大写
colA = upper(colA);
colB = upper(colB);

%% ---------- 拼 colormap ----------
cmapA_type = ['W' colA];
cmapB_type = ['W' colB];

%% ---------- 取颜色 ----------
cmapA = ap.colormap(cmapA_type, 256);
cmapB = ap.colormap(cmapB_type, 256);

P = cmapA(end, :);
G = cmapB(end, :);
W = [1 1 1];

M = 0.5 * (P + G);

%% ---------- 映射 ----------
a = A / max_val;
b = B / max_val;

a = max(min(a,1),0);
b = max(min(b,1),0);

a = a.^gamma;
b = b.^gamma;

%% ---------- 混色 ----------
RGB = zeros([size(A),3]);

for k = 1:3
    RGB(:,:,k) = ...
        W(k)*(1-a).*(1-b) + ...
        P(k)*a.*(1-b)    + ...
        G(k)*(1-a).*b    + ...
        M(k)*a.*b;
end

RGB = min(max(RGB,0),1);

end