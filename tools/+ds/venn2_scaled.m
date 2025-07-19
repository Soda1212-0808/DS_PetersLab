function venn2_scaled(onlyA, onlyB, AB, colorA, colorB, alphaA, alphaB, showLabels, showPercentage, labels,scaleFactor)
    % 参数默认值处理
    if nargin < 4 || isempty(colorA), colorA = [1 0 0]; end
    if nargin < 5 || isempty(colorB), colorB = [0 0 1]; end
    if nargin < 6 || isempty(alphaA), alphaA = 0.4; end
    if nargin < 7 || isempty(alphaB), alphaB = 0.4; end
    if nargin < 8, showLabels = true; end
    if nargin < 9, showPercentage = false; end
    if nargin < 10 || isempty(labels)
        labels = {'A only', 'B only', 'A∩B'};
    end
      if nargin < 11, scaleFactor = []; end

    % 半径计算（根据面积）
    if isempty(scaleFactor)
        scale = 1;
    else
        scale = scaleFactor;
    end

    A=onlyA+AB;
    B=onlyB+AB;
    r1 = sqrt(A/pi) * scale;
    r2 = sqrt(B/pi) * scale;

    % % 半径和距离计算
    % r1 = sqrt(A/pi);
    % r2 = sqrt(B/pi);
    d = compute_distance(r1, r2, AB* scale^2);
    c1 = [0, 0];
    c2 = [d, 0];
centerShift = - (c1 + c2)/2;
c1 = c1 + centerShift;
c2 = c2 + centerShift;
    % 绘图
     hold on; axis equal off ;
    draw_circle(c1, r1, colorA, alphaA);
    draw_circle(c2, r2, colorB, alphaB);
    ylim([-1.5 1.5])
    xlim([-2 2])
    % 标签显示
    if showLabels
        % onlyA = A - AB;
        % onlyB = B - AB;
        total = onlyA + onlyB + AB;

        if showPercentage
            fmt = @(x) sprintf('%.1f%%', 100*x/total);
        else
            fmt = @(x) num2str(x);
        end


        % A only 的位置（偏左上）
        angleA = pi * 2/3;
        posA = c1 + r1 * [2*cos(angleA), 0.2*sin(angleA)];
        text(posA(1), posA(2), {fmt(onlyA), labels{1}}, ...
            'HorizontalAlignment', 'center', 'FontSize', 10);

        % B only 的位置（偏右上）
        angleB = pi * 1/3;
        posB = c2 + r2 * [2*cos(angleB), 0.2*sin(angleB)];
        text(posB(1), posB(2), {fmt(onlyB), labels{2}}, ...
            'HorizontalAlignment', 'center', 'FontSize', 10);

        % AB 的位置（交集中偏下）
        posAB = (c1 + c2)/2 ;
        text(posAB(1), posAB(2), {fmt(AB), labels{3}}, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'normal', 'FontSize', 10);
    end
end

% 画圆函数
function draw_circle(center, radius, color, alpha)
    theta = linspace(0, 2*pi, 300);
    x = center(1) + radius * cos(theta);
    y = center(2) + radius * sin(theta);
    fill(x, y, color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
end

% 解距离函数，使交集面积等于 AB
function d = compute_distance(r1, r2, area_overlap)
    % 最大和最小可能交集面积
    max_overlap = pi * min(r1, r2)^2;
    min_overlap = 0;
    tol = 1e-6;

    % 容错判断
    if area_overlap > max_overlap + tol
        warning('交集面积超过理论最大值，已限制为最大可能值');
        area_overlap = max_overlap;
    elseif area_overlap < min_overlap - tol
        warning('交集面积为负或过小，已限制为 0');
        area_overlap = 0;
    end

    % 完全包含
    if abs(area_overlap - max_overlap) < tol
        d = abs(r1 - r2)
        return;
    end

    % 完全不相交
    if abs(area_overlap) < tol
        d = r1 + r2 + tol;  % 稍微多一点，确保不重叠
        return;
    end

    % 正常情况：数值解
    fun = @(d) overlap_area(r1, r2, d) - area_overlap;
    d = fzero(fun, [abs(r1 - r2), r1 + r2]);
end

% 计算两个圆的交集面积
function area = overlap_area(r1, r2, d)
    if d >= r1 + r2
        area = 0; return
    elseif d <= abs(r1 - r2)
        area = pi * min(r1, r2)^2; return
    end
    part1 = r1^2 * acos((d^2 + r1^2 - r2^2) / (2*d*r1));
    part2 = r2^2 * acos((d^2 + r2^2 - r1^2) / (2*d*r2));
    part3 = 0.5 * sqrt((-d + r1 + r2)*(d + r1 - r2)*(d - r1 + r2)*(d + r1 + r2));
    area = part1 + part2 - part3;
end
