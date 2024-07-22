
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

animals = {'DS000','DS001','DS003','DS004','DS005','DS006','AP018','AP019','AP020','AP021','AP022'};

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-5:30];

period_passive=find(t_passive>0&t_passive<0.2);
period_task=find(t_task>0&t_task<0.2);
period_kernels=find(t_kernels>0&t_kernels<0.2);

dot_hml_task=cell(size(animals));
dot_lcr_task=cell(size(animals));
for curr_animal=1:length(animals)

    animal=animals{curr_animal};


    data_task=load([Path '\mat_data\' animal '_task.mat']);
    data_lcr=load([Path '\mat_data\' animal '_lcr_passive.mat']);
    data_hml=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);

    for curr_day=1:length(data_task.workflow_day)
        
        % visual_passive&task
        if data_task.workflow_type(curr_day)==1
          buff_idx=find(strcmp(data_lcr.workflow_day,data_task.workflow_day{curr_day}));
            if ~isempty (buff_idx)& any(data_lcr.all_groups_name{buff_idx}==90)

                wf_px_lcr_buffer=plab.wf.svd2px(U_master, data_lcr.wf_px{buff_idx});
                redata=reshape(wf_px_lcr_buffer,size(wf_px_lcr_buffer,1)*size(wf_px_lcr_buffer,2),size(wf_px_lcr_buffer,3),size(wf_px_lcr_buffer,4));
                roi_data_lcr_mpfc=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);
                dot_lcr_task{curr_animal}(1,curr_day)=max(roi_data_lcr_mpfc(period_passive,(data_lcr.all_groups_name{buff_idx}==90)));

                wf_px_task_buffer=plab.wf.svd2px(U_master, data_task.wf_px_task_kernels{curr_day});
                redata=reshape(wf_px_task_buffer,size(wf_px_task_buffer,1)*size(wf_px_task_buffer,2),size(wf_px_task_buffer,3),size(wf_px_task_buffer,4));
                roi_data_task_mpfc=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);
                dot_lcr_task{curr_animal}(2,curr_day)=max(roi_data_task_mpfc(period_kernels));
            end
        end
        % aduio_passive&task
        if data_task.workflow_type(curr_day)==2

            buff_idx=find(strcmp(data_hml.workflow_day,data_task.workflow_day{curr_day}));
            if ~isempty (buff_idx)& any(data_hml.all_groups_name{buff_idx}==8000)

                wf_px_hml_buffer=plab.wf.svd2px(U_master, data_hml.wf_px{buff_idx});
                redata=reshape(wf_px_hml_buffer,size(wf_px_hml_buffer,1)*size(wf_px_hml_buffer,2),size(wf_px_hml_buffer,3),size(wf_px_hml_buffer,4));
                roi_data_hml_mpfc=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);
                dot_hml_task{curr_animal}(1,curr_day)=max(roi_data_hml_mpfc(period_passive,(data_hml.all_groups_name{buff_idx}==8000)));

                wf_px_task_buffer=plab.wf.svd2px(U_master, data_task.wf_px_task_kernels                               {curr_day});
                redata=reshape(wf_px_task_buffer,size(wf_px_task_buffer,1)*size(wf_px_task_buffer,2),size(wf_px_task_buffer,3),size(wf_px_task_buffer,4));
                roi_data_task_mpfc=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);
                dot_hml_task{curr_animal}(2,curr_day)=max(roi_data_task_mpfc(period_kernels));
            end
        end




    end
end


%% Correlation
% 使用 cellfun 将函数应用到 cell 数组的每个元素
dot_lcr_task_nozero = cellfun(@(x) x(:, any(x ~= 0, 1)), dot_lcr_task, 'UniformOutput', false);

dot_hml_task_nozero = cellfun(@(x) x(:, any(x ~= 0, 1)), dot_hml_task, 'UniformOutput', false);

dot_lcr_task_nozero_line=cat(2,dot_lcr_task_nozero{:})
dot_hml_task_nozero_line=cat(2,dot_hml_task_nozero{:})

[R_a,P_a] = corr(dot_hml_task_nozero_line(1,:)',dot_hml_task_nozero_line(2,:)');
[R_v,P_v] = corr(dot_lcr_task_nozero_line(1,:)',dot_lcr_task_nozero_line(2,:)');

% draw figure
% 颜色生成函数：从HSV色空间中均匀采样
 numColors = length(dot_lcr_task_nozero);
% numColors = 1;

baseColors = hsv(numColors);

% 创建图形窗口
figure('Position',[100 100 1400 600]);
nexttile
hold on; % 保持图形窗口不被覆盖

% 用于存储图例句柄
legendHandles = [];
legendLabels = {};

% 遍历cell矩阵中的每一个元素
for i = 1:length(dot_lcr_task_nozero)
    matrix = dot_lcr_task_nozero{i};  % 获取当前cell中的矩阵
    
    if isempty(matrix)
        continue; % 跳过空的cell
    end
    
    x = matrix(1, :);  % 取第一列作为x轴数据
    y = matrix(2, :);  % 取第二列作为y轴数据
    n = size(matrix, 2); % 获取点的数量
    
    % 生成从浅到深的颜色，避免白色
    lightColor = baseColors(i, :) + (1 - baseColors(i, :)) * 0.7; % 较浅颜色
    colors = [linspace(lightColor(1), baseColors(i, 1), n)', ...
              linspace(lightColor(2), baseColors(i, 2), n)', ...
              linspace(lightColor(3), baseColors(i, 3), n)'];
    % nexttile
    % 绘制每个cell元素的所有点，并设置颜色
    scatterHandle = scatter(x, y, 36, colors(end,:,:), 'filled'); % 36是点的大小
    % 保存句柄用于图例
    legendHandles = [legendHandles, scatterHandle];
    legendLabels = [legendLabels, {sprintf('Cell %d', i)}];
end

% % 添加图例和标签
% if ~isempty(legendHandles)
%     legend(legendHandles, animals, 'Location','eastoutside');
% end
xlabel('mPFC activity in visual passive');
ylabel('mPFC kernels in visual task');
% title('Scatter Plot of Cell Array Elements with Gradient Colors');

% coefficients = polyfit(dot_lcr_task_nozero_line(1,:),dot_lcr_task_nozero_line(2,:),1);
% fittedX = linspace(min(dot_lcr_task_nozero_line(1,:)), max(dot_lcr_task_nozero_line(1,:)), 200);
% fittedY = polyval(coefficients, fittedX);
% 
% % 绘制回归直线
% plot(fittedX, fittedY, '-r', 'LineWidth', 2);
% 

ax = gca;
% 计算注释框的位置
xRange = ax.XLim;
yRange = ax.YLim;
xPos = xRange(2) - 0.1 * (xRange(2) - xRange(1));  % 靠右
yPos = yRange(2) - 0.1 * (yRange(2) - yRange(1));  % 靠上

% 添加相关性系数和 p 值注释
text(xPos, yPos, ...
     sprintf('Pearson r = %.2f\np-value = %.2g', R_v, P_v), ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
     'FontSize', 12, 'BackgroundColor', 'white');

hold off; % 释放图形窗口

nexttile
hold on; % 保持图形窗口不被覆盖

% 用于存储图例句柄
legendHandles = [];
legendLabels = {};

% 遍历cell矩阵中的每一个元素
for i = 1:length(dot_hml_task_nozero)
    matrix = dot_hml_task_nozero{i};  % 获取当前cell中的矩阵
    
    if isempty(matrix)
        continue; % 跳过空的cell
    end
    
    x = matrix(1, :);  % 取第一列作为x轴数据
    y = matrix(2, :);  % 取第二列作为y轴数据
    n = size(matrix, 2); % 获取点的数量
    
    % 生成从浅到深的颜色，避免白色
    lightColor = baseColors(i, :) + (1 - baseColors(i, :)) * 0.7; % 较浅颜色
    colors = [linspace(lightColor(1), baseColors(i, 1), n)', ...
              linspace(lightColor(2), baseColors(i, 2), n)', ...
              linspace(lightColor(3), baseColors(i, 3), n)'];
    % nexttile
    % 绘制每个cell元素的所有点，并设置颜色
    scatterHandle = scatter(x, y, 36, colors(end,:,:), 'filled'); % 36是点的大小
    % 保存句柄用于图例
    legendHandles = [legendHandles, scatterHandle];
    legendLabels = [legendLabels, {sprintf('Cell %d', i)}];
end

% 添加图例和标签
if ~isempty(legendHandles)
    legend(legendHandles, animals, 'Location','eastoutside');
end
xlabel('mPFC activity in audio passive');
ylabel('mPFC kernels in audio task');
% title('Scatter Plot of Cell Array Elements with Gradient Colors');

ax = gca;

% 计算注释框的位置
xRange = ax.XLim;
yRange = ax.YLim;
xPos = xRange(2) - 0.1 * (xRange(2) - xRange(1));  % 靠右
yPos = yRange(2) - 0.1 * (yRange(2) - yRange(1));  % 靠上

% 添加相关性系数和 p 值注释
text(xPos, yPos, ...
     sprintf('Pearson r = %.2f\np-value = %.2g', R_a, P_a), ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
     'FontSize', 12, 'BackgroundColor', 'white');

hold off; % 释放图形窗


 saveas(gcf,[Path 'figures\'  'task_kernels_passive_correlation' ], 'jpg');
