function make_capsule_vertical_sine_area(H, W, areaRatio, period, bgGray, contrast, outFile)
% H         : 画布高度（像素）
% W         : 画布宽度（像素）
% areaRatio : 图形面积 / 画布面积，例如 0.35
% period    : 正弦光栅周期（像素）
% bgGray    : 背景灰度，0~1，例如 0.75
% contrast  : 对比度，0~1，例如 1.0
% outFile   : 输出文件名，例如 'capsule_sine.jpg'

if nargin < 1, H = 400; end
if nargin < 2, W = 700; end
if nargin < 3, areaRatio = 0.35; end
if nargin < 4, period = 18; end
if nargin < 5, bgGray = 0.75; end
if nargin < 6, contrast = 1.0; end
if nargin < 7, outFile = 'capsule_sine.jpg'; end

if areaRatio <= 0 || areaRatio >= 1
    error('areaRatio 必须在 0 和 1 之间。');
end

if period <= 0
    error('period 必须大于 0。');
end

if bgGray < 0 || bgGray > 1
    error('bgGray 必须在 [0,1] 之间。');
end

if contrast < 0 || contrast > 1
    error('contrast 必须在 [0,1] 之间。');
end

canvasArea = H * W;
targetArea = areaRatio * canvasArea;

% 形状高度固定为 H，上下半圆贴住上下边界
% 设半径为 r，则面积：
% A = 2*r*(H - 2*r) + pi*r^2
%   = 2*H*r + (pi - 4)*r^2
a = pi - 4;
b = 2 * H;
c = -targetArea;

disc = b^2 - 4*a*c;
if disc < 0
    error('给定 areaRatio 无法得到实数解。');
end

r1 = (-b + sqrt(disc)) / (2*a);
r2 = (-b - sqrt(disc)) / (2*a);

candidates = [r1, r2];
candidates = candidates(candidates > 0 & candidates < H/2);

if isempty(candidates)
    error('没有找到合法半径，请检查 areaRatio。');
end

r = min(candidates);

if 2*r > W
    error('图形太宽，当前 areaRatio 下得到的图形会超过画布宽度。请减小 areaRatio 或增大 W。');
end

% 坐标网格
[x, y] = meshgrid(1:W, 1:H);
cx = (W + 1) / 2;

% 圆心位置：上下半圆分别贴住顶边和底边
yTopC    = 1 + r;
yBottomC = H - r;

% 形状掩膜：上半圆 + 中间矩形 + 下半圆
maskRect = abs(x - cx) <= r & y >= yTopC & y <= yBottomC;
maskTop  = (x - cx).^2 + (y - yTopC).^2 <= r^2 & y < yTopC;
maskBot  = (x - cx).^2 + (y - yBottomC).^2 <= r^2 & y > yBottomC;
mask = maskRect | maskTop | maskBot;

% 竖向连续正弦光栅：
% 只沿 x 方向变化，并且用 abs(x-cx) 保证左右对称
% grating 范围在 [0,1]
% 通过搜索相位，让形状内部平均亮度尽量接近 bgGray
phases = linspace(0, period, 400);
bestPhase = 0;
bestDiff = inf;

for p = phases
    grating = 0.5 + 0.5 * sin(2*pi*(abs(x - cx) + p) / period);
    meanInside = mean(grating(mask));
    diffNow = abs(meanInside - 0.5);
    if diffNow < bestDiff
        bestDiff = diffNow;
        bestPhase = p;
    end
end

% 最终正弦光栅
grating = 0.5 + 0.5 * sin(2*pi*(abs(x - cx) + bestPhase) / period);

% 映射到亮度范围
innerGray = bgGray + contrast * (grating - 0.5);

% 裁剪到 [0,1]
innerGray = max(0, min(1, innerGray));

% 生成背景图像
img = bgGray * ones(H, W, 3);

for c = 1:3
    channel = img(:,:,c);
    channel(mask) = innerGray(mask);
    img(:,:,c) = channel;
end

% 显示与保存
figure('Color', [bgGray bgGray bgGray], 'Position', [100 100 W H]);
imshow(img, 'Border', 'tight');
axis image off;

imwrite(img, outFile);

fprintf('已保存到: %s\n', outFile);
fprintf('实际半径 r = %.2f px\n', r);
fprintf('实际图形面积比例约为 %.4f\n', nnz(mask)/canvasArea);
fprintf('最佳相位 = %.4f\n', bestPhase);

end