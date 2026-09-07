function h = make_bar_plot(dataCell, varargin)
% make_bar_plot
% 根据每组数据点数量，自动绘制：
%   1) bar + errorbar + scatter
%   2) boxchart
%
% 自动切换规则：
%   minN > SwitchN  --> 箱型图
%   minN <= SwitchN --> bar图
%
% 必需参数：
%   dataCell  : n×1 cell，每个 cell 是数值向量
%
% 可选参数（name-value）：
%   'ColorCell'         []        n×1 cell 或 n×3 数组，每个元素/行是 1×3 RGB
%   'BarAlpha'          0.5       柱子/箱型图透明度 [0,1]
%   'ShowDots'          1         bar模式下：0=不显示散点，1=显示散点
%   'DotSize'           40        散点大小
%   'Jitter'            0.2       水平抖动幅度（单位：x轴）
%   'ErrorColor'        [0 0 0]   误差棒颜色 (RGB)
%   'ErrorLineWidth'    1.5       误差棒线宽
%   'ShowErrorCaps'     1         误差棒横线开关：0=无横线，1=有横线
%   'CentralTendency'   'mean'    柱子高度：'mean' 或 'median'
%   'SwitchN'           []        bar/箱型图分界值
%                                minN > SwitchN  --> 箱型图
%                                minN <= SwitchN --> bar图
%
% 返回：
%   h : 结构体
%       h.mode     = 'bar' 或 'box'
%       h.bars     = bar句柄
%       h.ebar     = errorbar句柄
%       h.scat     = scatter句柄
%       h.box      = boxchart句柄
%       h.sampleN  = 每组有效数据点数量
%       h.minN     = 所有组中最少的数据点数
%       h.switchN  = 实际使用的分界值

    % =========================================================
    % 输入检查
    % =========================================================
    if nargin < 1 || isempty(dataCell)
        error('dataCell is required and must be a non-empty cell array.');
    end

    if ~iscell(dataCell)
        error('dataCell must be a cell array of numeric vectors.');
    end

    dataCell = dataCell(:);

    % =========================================================
    % 默认值
    % =========================================================
    defaultBarAlpha = 0.5;
    defaultShowDots = 1;
    defaultDotSize  = 40;

    % =========================================================
    % inputParser
    % =========================================================
    p = inputParser;
    p.FunctionName = 'make_bar_plot';

    addParameter(p, 'ColorCell', [], ...
        @(x) isempty(x) || isnumeric(x) || iscell(x));

    addParameter(p, 'BarAlpha', defaultBarAlpha, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0 && x <= 1);

    addParameter(p, 'ShowDots', defaultShowDots, ...
        @(x) isnumeric(x) && isscalar(x));

    addParameter(p, 'DotSize', defaultDotSize, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0);

    addParameter(p, 'Jitter', 0.2, ...
        @(x) isnumeric(x) && isscalar(x) && x >= 0);

    addParameter(p, 'ErrorColor', [0 0 0], ...
        @(x) isnumeric(x) && isequal(size(x), [1 3]) ...
        && all(x >= 0 & x <= 1));

    addParameter(p, 'ErrorLineWidth', 1.5, ...
        @(x) isnumeric(x) && isscalar(x) && x > 0);

    addParameter(p, 'ShowErrorCaps', 1, ...
        @(x) isnumeric(x) && isscalar(x));

    addParameter(p, 'CentralTendency', 'mean', ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));

    % 新增：bar / box 分界值
    addParameter(p, 'SwitchN', [], ...
        @(x) isempty(x) || ...
        (isnumeric(x) && isscalar(x) && x >= 0 && isfinite(x)));

    parse(p, varargin{:});
    opt = p.Results;

    % =========================================================
    % 数据清理
    % =========================================================
    n = numel(dataCell);

    cleanDataCell = cell(n,1);
    sampleN = zeros(n,1);

    for i = 1:n

        x = dataCell{i};

        if ~isnumeric(x)
            warning( ...
                'dataCell{%d} is not numeric — treating as empty.', ...
                i);
            x = [];
        end

        % 转为列向量
        x = x(:);

        % 去掉 NaN
        x = x(~isnan(x));

        cleanDataCell{i} = x;
        sampleN(i) = numel(x);

    end

    % =========================================================
    % 最少数据点数量
    % =========================================================
    minN = min(sampleN);

    % =========================================================
    % 确定 SwitchN
    %
    % 如果用户没有指定：
    %   SwitchN = n
    %
    % 这样保持原来的逻辑
    % =========================================================
    if isempty(opt.SwitchN)
        switchN = n;
    else
        switchN = opt.SwitchN;
    end

    % =========================================================
    % 自动选择绘图方式
    %
    % minN > switchN --> box
    % minN <= switchN --> bar
    % =========================================================
    useBoxPlot = minN > switchN;

    % =========================================================
    % 处理 ColorCell
    % =========================================================
    defaultColors = lines(max(1, n));
    colorCell = opt.ColorCell;

    if isempty(colorCell)

        colorCell = num2cell(defaultColors, 2);

    elseif isnumeric(colorCell)

        [r, c] = size(colorCell);

        % 一个颜色，所有组使用
        if isequal(size(colorCell), [1 3])

            colorCell = repmat({colorCell}, n, 1);

        % n×3，每组一个颜色
        elseif c == 3 && r == n

            colorCell = mat2cell( ...
                colorCell, ...
                ones(n,1), ...
                3);

        else

            warning( ...
                'ColorCell numeric size mismatch — using default colors.');

            colorCell = num2cell(defaultColors, 2);

        end

    elseif iscell(colorCell)

        if numel(colorCell) ~= n

            warning( ...
                'ColorCell length mismatch — using default colors.');

            colorCell = num2cell(defaultColors, 2);

        else

            colorCell = colorCell(:);

            for i = 1:n

                cval = colorCell{i};

                if ~(isnumeric(cval) ...
                        && isequal(size(cval), [1 3]) ...
                        && all(cval >= 0 & cval <= 1))

                    warning( ...
                        'ColorCell{%d} invalid — using default color.', ...
                        i);

                    colorCell{i} = defaultColors(i,:);

                end
            end
        end

    else

        warning( ...
            'ColorCell has unsupported type — using default colors.');

        colorCell = num2cell(defaultColors, 2);

    end

    % 再保险一次
    if ~iscell(colorCell) || numel(colorCell) ~= n
        colorCell = num2cell(defaultColors, 2);
    end

    colorCell = colorCell(:);

    % =========================================================
    % 绘图
    % =========================================================
    holdState = ishold;
    hold on

    % 初始化句柄
    bars = gobjects(0);
    ebar = gobjects(0);
    scat = gobjects(0);
    boxH = gobjects(0);

    % =========================================================
    % 模式1：箱型图
    % =========================================================
if useBoxPlot

    boxH = gobjects(n,1);

    for i = 1:n

        x = cleanDataCell{i};

        if isempty(x)
            continue
        end

        groupX = repmat(i, numel(x), 1);

        boxH(i) = boxchart( ...
            groupX, ...
            x, ...
            'BoxFaceColor', colorCell{i}, ...
            'BoxFaceAlpha', opt.BarAlpha, ...
            'LineWidth', 1.2,...
            'MarkerStyle', 'o', ...
            'MarkerColor', colorCell{i}, ...
             'MarkerSize', sqrt(opt.DotSize));

    end

    xlim([0.5, n + 0.5]);

    modeStr = 'box';

    % =========================================================
    % 模式2：bar + errorbar + scatter
    % =========================================================
    else

        % -----------------------------------------------------
        % 计算均值/中位数和 SEM
        % -----------------------------------------------------
        means = NaN(n,1);
        sems = NaN(n,1);

        for i = 1:n

            x = cleanDataCell{i};

            if isempty(x)
                continue
            end

            switch lower(string(opt.CentralTendency))

                case "mean"

                    means(i) = mean(x);
                    sems(i) = std(x) / sqrt(numel(x));

                case "median"

                    means(i) = median(x);

                    % 保持原来的 SEM 定义
                    sems(i) = std(x) / sqrt(numel(x));

                otherwise

                    error( ...
                        'CentralTendency must be ''mean'' or ''median''.');

            end
        end

        % -----------------------------------------------------
        % 柱子
        % -----------------------------------------------------
        bars = gobjects(n,1);

        for i = 1:n

            bars(i) = bar( ...
                i, ...
                means(i), ...
                'FaceColor', colorCell{i}, ...
                'FaceAlpha', opt.BarAlpha, ...
                'EdgeColor', 'none');

        end

        % -----------------------------------------------------
        % 误差棒
        % -----------------------------------------------------
        ebar = errorbar( ...
            1:n, ...
            means, ...
            sems, ...
            'Color', opt.ErrorColor, ...
            'LineStyle', 'none', ...
            'LineWidth', opt.ErrorLineWidth, ...
            'CapSize', 10 * logical(opt.ShowErrorCaps));

        % -----------------------------------------------------
        % 散点
        % -----------------------------------------------------
        if opt.ShowDots

            scat = gobjects(n,1);

            for i = 1:n

                x = cleanDataCell{i};

                if isempty(x)
                    continue
                end

                jitterX = ...
                    (rand(size(x)) - 0.5) * opt.Jitter;

                scat(i) = scatter( ...
                    i + jitterX, ...
                    x, ...
                    opt.DotSize, ...
                    'filled', ...
                    'MarkerFaceColor', colorCell{i}, ...
                    'MarkerEdgeColor', 'none');

            end
        end

        xlim([0.5, n + 0.5]);

        modeStr = 'bar';

    end

    % =========================================================
    % 恢复 hold 状态
    % =========================================================
    if ~holdState
        hold off
    end

    % =========================================================
    % 输出
    % =========================================================
    if nargout > 0

        h = struct( ...
            'mode', modeStr, ...
            'bars', bars, ...
            'ebar', ebar, ...
            'scat', scat, ...
            'box', boxH, ...
            'sampleN', sampleN, ...
            'minN', minN, ...
            'switchN', switchN);

    end

end