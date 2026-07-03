function make_diamond_sine_grating_area(H, W, areaRatio, period, bgGray, contrast, outFile)
% make_diamond_sine_grating_area
% H          画布高度
% W          画布宽度
% areaRatio  菱形面积占画布面积比例 (0~0.5)
% period     正弦光栅周期（像素）
% bgGray     背景灰度 (0~1)
% contrast   对比度 (0~1)
% outFile    输出文件名

if nargin < 1, H = 400; end
if nargin < 2, W = 700; end
if nargin < 3, areaRatio = 0.4; end
if nargin < 4, period = 20; end
if nargin < 5, bgGray = 0.75; end
if nargin < 6, contrast = 1.0; end
if nargin < 7, outFile = 'diamond_sine.jpg'; end

if areaRatio <= 0 || areaRatio > 0.5
    error('areaRatio 必须在 (0, 0.5] 之间。');
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

% 菱形中心
cx = (W + 1) / 2;
cy = (H + 1) / 2;

% 由面积比例反推半宽 a
% 菱形面积 = H * a
% 面积比例 = a / W
a = areaRatio * W;

if a > W/2
    error('areaRatio 过大，菱形会超出画布，请减小 areaRatio。');
end

% 上下半高固定为 H/2，使上下顶点贴住画布上下边界
b = H / 2;

[x, y] = meshgrid(1:W, 1:H);

% 菱形掩膜
mask = abs(x - cx) / a + abs(y - cy) / b <= 1;

% 为了让光栅关于水平中心线上下对称，使用 abs(y-cy)
% 正弦光栅亮度范围：
%   bgGray - contrast/2  到  bgGray + contrast/2
% 先找一个相位，使菱形内部平均亮度尽量接近 bgGray
phases = linspace(0, period, 400);
bestPhase = 0;
bestDiff = inf;

for p = phases
    grating = 0.5 + 0.5 * sin(2*pi*(abs(y - cy) + p) / period);
    val = mean(grating(mask), 'all');
    diffNow = abs(val - 0.5);
    if diffNow < bestDiff
        bestDiff = diffNow;
        bestPhase = p;
    end
end

% 最终正弦光栅，范围 0~1
grating = 0.5 + 0.5 * sin(2*pi*(abs(y - cy) + bestPhase) / period);

% 映射到目标亮度范围
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

% 显示
figure('Color', [bgGray bgGray bgGray], ...
       'Position', [100 100 W H]);
imshow(img, 'Border', 'tight');
axis image off

% 保存
imwrite(img, outFile);

fprintf('保存至 %s\n', outFile);
fprintf('目标面积比例 %.4f\n', areaRatio);
fprintf('实际面积比例 %.4f\n', nnz(mask)/(H*W));
fprintf('最佳相位 %.4f\n', bestPhase);
end