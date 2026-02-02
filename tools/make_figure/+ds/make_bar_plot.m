function h = make_bar_plot(dataCell, colorCell, varargin)
% make_bar_plot  绘制 bar + errorbar + (可选) scatter
%
% 必需参数：
%   dataCell  : n×1 cell，每个 cell 是数值向量
%
% 可选参数：
%   colorCell : n×1 cell 或 n×3 数组，每个 cell/row 是 1×3 RGB 颜色。
%               如果为空或未提供，函数会自动生成颜色。
%
% 可选位置参数（保留兼容）：
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

    % -------- 输入检查 --------
    if nargin < 1 || isempty(dataCell)
        error('dataCell is required and must be a non-empty cell array.');
    end
    if ~iscell(dataCell)
        error('dataCell must be a cell array of numeric vectors.');
    end

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
        if ~isnumeric(x)
            warning('dataCell{%d} is not numeric — treating as empty.', i);
            x = [];
        end
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
                    % 使用与 mean 相同的 SEM 近似（可选替代）
                    sems(i)  = std(x)/sqrt(numel(x));
                otherwise
                    error('CentralTendency must be ''mean'' or ''median''.');
            end
        end
    end

    % -------- 处理 colorCell（现在可选） --------
    % 目标：得到 n×1 cell，每个元素为 1×3 RGB 数组
    defaultColors = lines(max(1,n)); % 如果 n==0，也能工作
    % 情况 1：未提供 colorCell 或为空 -> 使用默认
    if nargin < 2 || isempty(colorCell)
        colorCell = num2cell(defaultColors, 2);
    else
        % 如果传入的是 numeric 矩阵 (n x 3) 或单个 1x3 向量
        if isnumeric(colorCell)
            [r,c] = size(colorCell);
            if isequal([1,3], [r,c]) % 1x3 -> replicate
                colorCell = repmat({colorCell}, n, 1);
            elseif c==3 && r==n % 每行一个颜色
                colorCell = mat2cell(colorCell, ones(n,1), 3);
            else
                warning('colorCell numeric size mismatch — falling back to default colors.');
                colorCell = num2cell(defaultColors, 2);
            end
        elseif iscell(colorCell)
            % 如果是 cell，但长度与 n 不一致 -> 尝试补齐或截断
            m = numel(colorCell);
            if m < n
                % 补齐：已有的保留，剩余使用 defaultColors
                newColors = num2cell(defaultColors, 2);
                for i = 1:m
                    % 检查每个元素是否是 1x3 numeric
                    cval = colorCell{i};
                    if isnumeric(cval) && isequal(size(cval),[1 3])
                        newColors{i} = cval;
                    else
                        warning('colorCell{%d} invalid — using default color for this index.', i);
                    end
                end
                colorCell = newColors;
                warning('colorCell length < dataCell length — remaining colors filled with defaults.');
            elseif m > n
                % 截断到前 n 个，但验证类型
                colorCell = colorCell(1:n);
                for i = 1:n
                    cval = colorCell{i};
                    if ~(isnumeric(cval) && isequal(size(cval),[1 3]))
                        warning('colorCell{%d} invalid — using default color for this index.', i);
                        colorCell{i} = defaultColors(i,:);
                    end
                end
                warning('colorCell length > dataCell length — extra colors ignored.');
            else
                % 长度相等，验证每个元素
                for i = 1:n
                    cval = colorCell{i};
                    if ~(isnumeric(cval) && isequal(size(cval),[1 3]))
                        warning('colorCell{%d} invalid — using default color for this index.', i);
                        colorCell{i} = defaultColors(i,:);
                    end
                end
            end
        else
            % 其他类型 -> 使用默认
            warning('colorCell has unsupported type — using default colors.');
            colorCell = num2cell(defaultColors, 2);
        end
    end

    % 确保 colorCell 是 n×1 cell，每个元素为 1x3 numeric
    if ~iscell(colorCell) || numel(colorCell) ~= n
        colorCell = num2cell(defaultColors, 2);
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
            if ~isnumeric(x)
                x = []; % already warned earlier
            end
            if isempty(x)
                % 画一个空的 scatter 句柄以保持长度一致
                scat(i) = gobjects(1);
                continue
            end
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
