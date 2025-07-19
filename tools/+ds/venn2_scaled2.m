function venn2_scaled(A, B, AB, colorA, colorB, alphaA, alphaB, showLabels, showPercentage, labels, scaleFactor)
    if nargin < 4 || isempty(colorA), colorA = [1 0 0]; end
    if nargin < 5 || isempty(colorB), colorB = [0 0 1]; end
    if nargin < 6 || isempty(alphaA), alphaA = 0.4; end
    if nargin < 7 || isempty(alphaB), alphaB = 0.4; end
    if nargin < 8, showLabels = true; end
    if nargin < 9, showPercentage = false; end
    if nargin < 10 || isempty(labels), labels = {'A only', 'B only', 'A∩B'}; end
    if nargin < 11, scaleFactor = []; end

    % 半径计算（根据面积）
    if isempty(scaleFactor)
        scale = 1;
    else
        scale = scaleFactor;
    end
    r1 = sqrt(A/pi) * scale;
    r2 = sqrt(B/pi) * scale;

    % 距离解算
    d = compute_distance(r1, r2, AB * scale^2);  % 缩放后面积

    % 圆心
    c1 = [0, 0];
    c2 = [d, 0];

    % 绘图（不建 figure，适用于 nexttile 外部控制）
    hold on; axis equal off;
    draw_circle(c1, r1, colorA, alphaA);
    draw_circle(c2, r2, colorB, alphaB);

    % 标签
    if showLabels
        onlyA = A - AB;
        onlyB = B - AB;
        total = onlyA + onlyB + AB;

        fmt = showPercentage ? ...
              @(x) sprintf('%.1f%%', 100*x/total) : ...
              @(x) num2str(x);

        offset = 0.1 * max(r1, r2);  % 防遮挡

        posA = c1 + r1 * [cos(2*pi/3), sin(2*pi/3)];
        posB = c2 + r2 * [cos(pi/3), sin(pi/3)];
        posAB = (c1 + c2)/2 + [0, -offset];

        text(posA(1), posA(2), {fmt(onlyA), labels{1}}, ...
            'HorizontalAlignment', 'center', 'FontSize', 12);
        text(posB(1), posB(2), {fmt(onlyB), labels{2}}, ...
            'HorizontalAlignment', 'center', 'FontSize', 12);
        text(posAB(1), posAB(2), {fmt(AB), labels{3}}, ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12);
    end
end

function draw_circle(center, radius, color, alpha)
    theta = linspace(0, 2*pi, 300);
    x = center(1) + radius * cos(theta);
    y = center(2) + radius * sin(theta);
    fill(x, y, color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
end

function d = compute_distance(r1, r2, area_overlap)
    fun = @(d) overlap_area(r1, r2, d) - area_overlap;
    d = fzero(fun, [abs(r1 - r2), r1 + r2]);
end

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
