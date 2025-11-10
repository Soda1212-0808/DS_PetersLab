function h = make_bar_plot(dataCell, colorCell, varargin)
% make_bar_plot  绘制 bar + errorbar + (可选) scatter
%
% 必需参数：
%   dataCell  : n×1 cell，每个 cell 是数值向量
%   colorCell : n×1 cell，每个 cell 是 1×3 RGB 颜色
%
% 可选参数（位置参数，保留兼容）：
%   (3) barAlpha ∈ [0,1]，默认 0.5
%   (4) showDots ∈ {0,1}，默认 1
%   (5) dotSize  > 0，  默认 40
%
% 可选参数（name–value）：
%   'BarAlpha'         (0.5)   柱子透明度 [0,1]
%   'ShowDots'         (1)     0=不显示散点，1=显示散点
%   'DotSize'          (40)    散点大小
%   'Jitter'           (0.2)   水平抖动幅度（单位：x 轴）
%   'ErrorColor'       ([0 0 0]) 误差棒颜色 (RGB)
%   'ErrorLineWidth'   (1.5)   误差棒线宽
%   'ShowErrorCaps'    (1)     误差棒横线（caps）开关：0=无横线，1=有横线
%   'CentralTendency'  ('mean') 柱子高度：'mean' 或 'median'
%
% 返回：
%   h : 结构体，包含 bars / ebar / scat 句柄（scat 可能为空）

    % -------- 默认值 --------
    barAlpha = 0.5;
    showDots = 1;
    dotSize  = 40;

    % -------- 位置参数兼容处理 --------
    v = varargin;
    isNameValue = @(x) (ischar(x) || isStringScalar(x) || (isstring(x) && numel(x)>0));
    if ~isempty(v) && ~isNameValue(v{1})
        barAlpha = v{1}; v(1) = [];
        if ~isempty(v) && ~isNameValue(v{1})
            showDots = v{1}; v(1) = [];
        end
        if ~isempty(v) && ~isNameValue(v{1})
            dotSize = v{1}; v(1) = [];
        end
    end

    % -------- inputParser（name–value）--------
    p = inputParser;
    p.FunctionName = 'make_bar_plot';

    addParameter(p, 'BarAlpha',       barAlpha, @(x)isnumeric(x)&&isscalar(x)&&x>=0&&x<=1);
    addParameter(p, 'ShowDots',       showDots, @(x)isnumeric(x)&&isscalar(x));
    addParameter(p, 'DotSize',        dotSize,  @(x)isnumeric(x)&&isscalar(x)&&x>0);
    addParameter(p, 'Jitter',         0.2,      @(x)isnumeric(x)&&isscalar(x)&&x>=0);
    addParameter(p, 'ErrorColor',     [0 0 0],  @(x)isnumeric(x)&&isequal(size(x),[1 3])&&all(x>=0 & x<=1));
    addParameter(p, 'ErrorLineWidth', 1.5,      @(x)isnumeric(x)&&isscalar(x)&&x>0);
    addParameter(p, 'ShowErrorCaps',  1,        @(x)isnumeric(x)&&isscalar(x));   % ← 新增
    addParameter(p, 'CentralTendency','mean',   @(x)ischar(x) || isstring(x));

    parse(p, v{:});
    opt = p.Results;

    % -------- 统计量 --------
    n = numel(dataCell);
    means = zeros(n,1);
    sems  = zeros(n,1);

    for i = 1:n
        x = dataCell{i};
        x = x(~isnan(x)); % 去掉 NaN
        if isempty(x)
            means(i) = NaN;
            sems(i)  = NaN;
        else
            switch lower(opt.CentralTendency)
                case 'mean'
                    means(i) = mean(x);
                    sems(i)  = std(x)/sqrt(numel(x)); % SEM
                case 'median'
                    means(i) = median(x);
                    % 近似的标准误差估计（MAD 转换常用系数近似）
                    sems(i)  =  std(x)/sqrt(numel(x));
                    % sems(i)  = 1.253 * std(x)/sqrt(numel(x));

                otherwise
                    error('CentralTendency must be ''mean'' or ''median''.');
            end
        end
    end

    % -------- 绘图 --------
    hold on

    % 柱子
    bars = gobjects(n,1);
    for i = 1:n
        bars(i) = bar(i, means(i), ...
            'FaceColor', colorCell{i}, ...
            'FaceAlpha', opt.BarAlpha, ...
            'EdgeColor', 'none');
    end

    % 误差棒
    ebar = errorbar(1:n, means, sems, ...
        'Color', opt.ErrorColor, ...
        'LineStyle', 'none', ...
        'LineWidth', opt.ErrorLineWidth, ...
        'CapSize', 10 * logical(opt.ShowErrorCaps));  % ← 新增：0=无横线，1=有横线

    % 散点（可选）
    scat = gobjects(0);
    if opt.ShowDots
        scat = gobjects(n,1);
        for i = 1:n
            x = dataCell{i};
            jitterX = (rand(size(x))-0.5) * opt.Jitter;
            scat(i) = scatter(i + jitterX, x, opt.DotSize, ...
                'filled', ...
                'MarkerFaceColor', colorCell{i}, ...
                'MarkerEdgeColor', 'none', ...
                'MarkerFaceAlpha', 1);
        end
    end

    hold off
    xlim([0.5, n+0.5])
    % set(gca,'XTick',1:n)

    if nargout>0
        h = struct('bars',bars,'ebar',ebar,'scat',scat);
    end
end
