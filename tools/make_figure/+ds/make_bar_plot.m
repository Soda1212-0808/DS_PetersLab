function h = make_bar_plot(dataCell, varargin)
% make_bar_plot  绘制 bar + errorbar + (可选) scatter
%
% 必需参数：
%   dataCell  : n×1 cell，每个 cell 是数值向量
%
% 可选参数（name-value）：
%   'ColorCell'         []        n×1 cell 或 n×3 数组，每个元素/行是 1×3 RGB
%   'BarAlpha'          0.5       柱子透明度 [0,1]
%   'ShowDots'          1         0=不显示散点，1=显示散点
%   'DotSize'           40        散点大小
%   'Jitter'            0.2       水平抖动幅度（单位：x 轴）
%   'ErrorColor'        [0 0 0]   误差棒颜色 (RGB)
%   'ErrorLineWidth'    1.5       误差棒线宽
%   'ShowErrorCaps'     1         误差棒横线开关：0=无横线，1=有横线
%   'CentralTendency'   'mean'    柱子高度：'mean' 或 'median'
%
% 返回：
%   h : 结构体，包含 bars / ebar / scat 句柄（scat 可能为空）

    % -------- 输入检查 --------
    if nargin < 1 || isempty(dataCell)
        error('dataCell is required and must be a non-empty cell array.');
    end
    if ~iscell(dataCell)
        error('dataCell must be a cell array of numeric vectors.');
    end

    % -------- 默认值 --------
    defaultBarAlpha = 0.5;
    defaultShowDots  = 1;
    defaultDotSize   = 40;

    % -------- inputParser --------
    p = inputParser;
    p.FunctionName = 'make_bar_plot';

    addParameter(p, 'ColorCell', [], @(x) isempty(x) || isnumeric(x) || iscell(x));
    addParameter(p, 'BarAlpha',       defaultBarAlpha, @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);
    addParameter(p, 'ShowDots',        defaultShowDots, @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'DotSize',         defaultDotSize,  @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'Jitter',          0.2,            @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'ErrorColor',      [0 0 0],        @(x) isnumeric(x) && isequal(size(x), [1 3]) && all(x >= 0 & x <= 1));
    addParameter(p, 'ErrorLineWidth',   1.5,           @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'ShowErrorCaps',    1,             @(x) isnumeric(x) && isscalar(x));
    addParameter(p, 'CentralTendency',  'mean',        @(x) ischar(x) || (isstring(x) && isscalar(x)));

    parse(p, varargin{:});
    opt = p.Results;

    % -------- 统计量 --------
    n = numel(dataCell);
    means = zeros(n,1);
    sems  = zeros(n,1);

    for i = 1:n
        x = dataCell{i};
        if ~isnumeric(x)
            warning('dataCell{%d} is not numeric — treating as empty.', i);
            x = [];
        end

        x = x(~isnan(x)); % 去掉 NaN

        if isempty(x)
            means(i) = NaN;
            sems(i)  = NaN;
        else
            switch lower(string(opt.CentralTendency))
                case "mean"
                    means(i) = mean(x);
                    sems(i)  = std(x) / sqrt(numel(x));
                case "median"
                    means(i) = median(x);
                    sems(i)  = std(x) / sqrt(numel(x)); % 仍用 SEM 近似
                otherwise
                    error('CentralTendency must be ''mean'' or ''median''.');
            end
        end
    end

    % -------- 处理 ColorCell --------
    defaultColors = lines(max(1, n));
    colorCell = opt.ColorCell;

    if isempty(colorCell)
        colorCell = num2cell(defaultColors, 2);

    elseif isnumeric(colorCell)
        [r, c] = size(colorCell);

        if isequal(size(colorCell), [1 3])
            colorCell = repmat({colorCell}, n, 1);

        elseif c == 3 && r == n
            colorCell = mat2cell(colorCell, ones(n,1), 3);

        else
            warning('ColorCell numeric size mismatch — using default colors.');
            colorCell = num2cell(defaultColors, 2);
        end

    elseif iscell(colorCell)
        if numel(colorCell) ~= n
            warning('ColorCell length mismatch — using default colors.');
            colorCell = num2cell(defaultColors, 2);
        else
            for i = 1:n
                cval = colorCell{i};
                if ~(isnumeric(cval) && isequal(size(cval), [1 3]))
                    warning('ColorCell{%d} invalid — using default color for this index.', i);
                    colorCell{i} = defaultColors(i,:);
                end
            end
        end

    else
        warning('ColorCell has unsupported type — using default colors.');
        colorCell = num2cell(defaultColors, 2);
    end

    % 再保险一次：确保长度正确
    if ~iscell(colorCell) || numel(colorCell) ~= n
        colorCell = num2cell(defaultColors, 2);
    end

    % -------- 绘图 --------
    holdState = ishold;
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
        'CapSize', 10 * logical(opt.ShowErrorCaps));

    % 散点（可选）
    scat = gobjects(0);
    if opt.ShowDots
        scat = gobjects(n,1);
        for i = 1:n
            x = dataCell{i};
            if ~isnumeric(x)
                x = [];
            end
            if isempty(x)
                continue
            end
            jitterX = (rand(size(x)) - 0.5) * opt.Jitter;
            scat(i) = scatter(i + jitterX, x, opt.DotSize, ...
                'filled', ...
                'MarkerFaceColor', colorCell{i}, ...
                'MarkerEdgeColor', 'none');
        end
    end

    if ~holdState
        hold off
    end

    xlim([0.5, n + 0.5])

    % -------- 输出 --------
    if nargout > 0
        h = struct('bars', bars, 'ebar', ebar, 'scat', scat);
    end
end