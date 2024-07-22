function plotWithSEM(data, plotColor)
% PLOTWITHSEM 绘制二维矩阵沿 X 轴的 plot 和 SEM 阴影区域

% 参数默认值处理
if nargin < 2
    plotColor = 'b';  % 默认使用蓝色
end

% 计算每列的均值和标准误差（SEM）
mean_data = mean(data);  % 每列的均值
sem_data = std(data) / sqrt(size(data, 1));  % 每列的SEM

% 绘制 plot 和 SEM 阴影区域
figure;
hold on;

% 绘制均值的 plot
plot(mean_data, [plotColor 'o-'], 'LineWidth', 1.5);

% 计算阴影区域的上下界
upper_bound = mean_data + sem_data;
lower_bound = mean_data - sem_data;

% 使用 fill 函数填充 SEM 的阴影区域
x_fill = [1:numel(mean_data), fliplr(1:numel(mean_data))];
y_fill = [upper_bound, fliplr(lower_bound)];
fill(x_fill, y_fill, plotColor, 'FaceAlpha', 0.7, 'EdgeColor', 'none');

% 添加标题和标签
title('Plot with SEM Error Shadow (Across X-axis)');
xlabel('X-axis');
ylabel('Mean Value');

% 添加图例
legend('Mean', 'SEM');

hold off;

end
