clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')


data_passive=load([ Path 'summary_data\passive kernels of images crossday.mat']);
data_task=load([ Path 'summary_data\task kernels of images crossday.mat']);
data_behavior=load([ Path 'summary_data\behavior.mat']);
surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_kernels=1/surround_samplerate*[-10:30];
kernels_period=t_kernels>=-0.1& t_kernels<=0.3;
%% stage 1
figure('Position',[50 50 1000 400])
used_area=[1 2 3 4]

t1 = tiledlayout(length(used_area), 6, 'TileSpacing', 'tight', 'Padding', 'tight');

title_images={'pre learn','post learn'};
title_area={'l-mPFC','r-mPFC','l-aPFC','r-aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
scale1=0.0004;

Color={'B','R'};
colors{1} = { [0 0 1],[1 0 0]}; % 定义颜色
colors{2} = { [0.5 0.5 1],[1 0.5 0.5]}; % 定义颜色
color_roi={[1 0.5 1],[ 0.5 1 0.5]}
for curr_roi=1:length(used_area)
    for curr_group=1:2
        performance=data_behavior.performance_align{curr_group};
        temp_image=permute(nanmean(cat(3,data_task.buf3_roi{curr_group}{used_area(curr_roi)}{:}),2),[1,3,2]);
        a1=nexttile(6*curr_roi-6+3*curr_group-3+1)
        imagesc(t_kernels,[], temp_image')
        ylim([0.5 8.5])
        % ylim([0.5 26.5])
        xlim([-0.2 0.5])
        yline(3.5);
        yline(8.5);
        yline(10.5);
        yline(15.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a1, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        if curr_group==1
            yticks([2  6 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
            yticklabels(title_images); % 设置对应的标签
        else
            yticks([])
        end
        if curr_roi==1
            title('task','FontWeight','normal')
        end



        a3=nexttile(6*curr_roi-6+3*curr_group-3+2)
        temp_image_p=permute(nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{used_area(curr_roi)}{:}),3),[1,4,2,3]);
        imagesc(t_kernels,[], temp_image_p(:,:,4-curr_group)');
        ylim([3.5 11.5])
        xlim([-0.2 0.5])
        yline(6.5);
        clim(scale1 .* [0, 1]);
        colormap(a3, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        yticks([ ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        if curr_roi==1
            title('passive','FontWeight','normal')
        end



        a4= nexttile(6*curr_roi-6+3*curr_group-3+3)
        hold on
        % yyaxis left



        temp_mean=nanmean(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1);
        temp_error=std(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},0,1,'omitmissing')/sqrt(size(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1));
        % hold on
        ap.errorfill(1:8,temp_mean(1:8),temp_error(1:8),colors{1}{curr_group},0.1,0.5)

        temp_mean=permute(nanmean(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),2),[3,2,1]);
        temp_error=permute(std(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),0,2,'omitmissing'),[3,2,1])./...
            sqrt(size(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),2));
        yyaxis left
        % 激活左 y 轴
        ap.errorfill(1:8,temp_mean(4:11),temp_error(4:11),colors{2}{curr_group},0.1,0.5)



        xlim([1 8])
        ylim(scale1 .* [0, 1]);
        xticks([2 6]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签
        ylabel('\Delta F/F')
        xline(3.5);

        yyaxis right
        set(gca, 'YColor', [0.5 0.5 0.5])
        temp_mean=nanmean(cat(3,performance{:}),3);
        temp_error=std(cat(3,performance{:}),0,3,'omitmissing')./sqrt(size(performance,1));
        ap.errorfill(1:8,temp_mean(1:8),temp_error(1:8),[0.8 0.8 0.8],0.1,0.5)
        % ylim([0.2 0.8])
        ylabel('performance')
        yticks(ylim); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        if curr_roi==1
            legend(a4,{'','task','','passive'},'Location','northeast','Box','off')
        end

        temp_task0=data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)};

        temp_passive0=permute(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),[2,3,1]);
        temp_result=(temp_task0(:,1:8)-temp_passive0(:,4:11))./(temp_task0(:,1:8)+temp_passive0(:,4:11));
        % .* ( ((temp_task0(:,1:8)+temp_passive0(:,4:11))).^1.1);
        temp_diff_mean=nanmean(temp_result,1);
        temp_diff_error=std(temp_result,0,1,'omitmissing')./sqrt(size(temp_result,1));


        % % a4= nexttile(8*curr_roi-8+4*curr_group-4+4)
        % a4= nexttile(4*curr_group-4+4)
        % ap.errorfill(1:8,temp_diff_mean,temp_diff_error,color_roi{curr_roi},0.1,0.5)
        % % ylim([-0.2 1.5]*0.0001)
        %         ylim([-0.2 1])
        % 
        % xlim([1 8])
        % xticks([2 6]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        % xticklabels(title_images); % 设置对应的标签
        % xline(3.5);
        % ylabel('context difference')



    end
end
% nexttile();axis off
% nexttile();axis off
%%  stage 2
figure('Position',[50 50 1000 400])
t1 = tiledlayout(2, 6, 'TileSpacing', 'tight', 'Padding', 'tight');

title_images={'pre learn','post learn'};
title_area={'l-mPFC','r-mPFC','l-aPFC','r-aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
scale1=0.0004;

Color={'R','B'};
colors{1} = { [1 0 0],[0 0 1]}; % 定义颜色
colors{2} = { [1 0.5 0.5],[0.5 0.5 1]}; % 定义颜色

used_area=[1 3]
for curr_roi=1:2
    for curr_group=1:2
        temp_image=permute(nanmean(cat(3,data_task.buf3_roi{curr_group}{used_area(curr_roi)}{:}),2),[1,3,2]);
        a1=nexttile(6*curr_roi-6+3*curr_group-3+1)
        imagesc(t_kernels,[], temp_image')
        % ylim([8.5 15.5])
        ylim([21.5 26.5])

        % ylim([0.5 26.5])
        xlim([-0.2 0.5])
        yline(3.5);
        yline(8.5);
        yline(10.5);
        yline(15.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a1, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        if curr_group==1
            yticks([2  6 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
            yticklabels(title_images); % 设置对应的标签
        else
            yticks([])
        end
        if curr_roi==1
            title('task','FontWeight','normal')
        end



        a3=nexttile(6*curr_roi-6+3*curr_group-3+2)
        temp_image_p=permute(nanmean(cat(4,data_passive.buf3_roi{curr_group}{3-curr_group}{used_area(curr_roi)}{:}),3),[1,4,2,3]);
        imagesc(t_kernels,[], temp_image_p(:,:,1+curr_group)');
        ylim([21.5 26.5])

        % ylim([11.5 18.5])
        xlim([-0.2 0.5])

        yline(3.5);
        yline(6.5);
        yline(11.5);
        yline(13.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a3, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        yticks([ ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        if curr_roi==1
            title('passive','FontWeight','normal')
        end



        a4= nexttile(6*curr_roi-6+3*curr_group-3+3)
        temp_mean=permute(nanmean(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(1+curr_group,:,:),2),[3,2,1]);
        temp_error=permute(std(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(1+curr_group,:,:),0,2,'omitmissing'),[3,2,1])./...
            sqrt(size(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(4-(3-curr_group),:,:),2));
        hold on
        ap.errorfill(1:5,temp_mean(22:26),temp_error(22:26),colors{2}{curr_group},0.1,0.5)



        a2= nexttile(6*curr_roi-6+3*curr_group-3+3)
        temp_mean=nanmean(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1);
        temp_error=std(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},0,1,'omitmissing')/sqrt(size(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1));
        hold on
        ap.errorfill(1:5,temp_mean(22:26),temp_error(22:26),colors{1}{curr_group},0.1,0.5)
        xlim([1 5])
        ylim(scale1 .* [0, 1]);
        xticks([1 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        % xticklabels(title_images); % 设置对应的标签
        ylabel('\Delta F/F')


        if curr_roi==1
            legend(a2,{'','task','','passive'},'Location','northeast','Box','off')
        end

    end
end
% nexttile();axis off
% nexttile();axis off
%%

figure('Position',[50 50 800 200])
t1 = tiledlayout(1, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
colors{2}={[0 0 1],[0.5 0.5 1];[1 0 0],[1 0.5 0.5 ]}
colors{1}={[0 0 0  ],[0.5 0.5 0.5];[0 0 0],[0.5 0.5 0.5 ]}
title_area={'mPFC','mPFC','aPFC','aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
context_diff=cell(2,1)
for curr_roi=[1 3]
    for curr_group=1:2
        switch curr_group
            case 1
                used_stim=3
            case 2
                used_stim=2
        end
        % nexttile()
        temp_passive_peak=cell(4,1);
        temp_task_peak=cell(4,1);

        for curr_stage=1:2
            switch curr_stage
                case 1
                    used_task=[1: 3]
                    used_passive=[4 :6]

                case 2
                    used_task=[7: 8]
                    used_passive=[10 :11]

            end
            temp_passive=nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{curr_roi}{used_passive}),4);
            temp_passive_peak{curr_stage}=permute(max(temp_passive(kernels_period,used_stim,:),[],1),[3 2 1]);

            temp_passive_temp=nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{curr_roi+1}{used_passive}),4);
            temp_passive_peak{curr_stage+2}=permute(max(temp_passive_temp(kernels_period,used_stim,:),[],1),[3 2 1]);

            temp_pass_mean=nanmean(temp_passive(:,used_stim,:),3);
            temp_pass_error=std(temp_passive(:,used_stim,:),0,3,'omitmissing')/sqrt(size(temp_passive,3));

            temp_task=nanmean(cat(3,data_task.buf3_roi{curr_group}{curr_roi}{used_task}),3);
            temp_task_peak{curr_stage}=permute(max(temp_task(kernels_period,:),[],1),[ 2 1]);
            temp_task_mean=nanmean(temp_task,2);
            temp_task_error=std(temp_task,0,2,'omitmissing')/sqrt(size(temp_task,2));

            temp_task_temp=nanmean(cat(3,data_task.buf3_roi{curr_group}{curr_roi+1}{used_task}),3);
            temp_task_peak{curr_stage+2}=permute(max(temp_task_temp(kernels_period,:),[],1),[ 2 1]);


        end

        scale=0.0003
        % ylim(scale*[-0.4 1])
        % xlim([-0.3 0.8])
        % ylabel('\Delta F/F')
        % title(title_area{curr_roi},'FontWeight','normal')
        % % legend({'','pre passive','','pre task','','post passive','','post task'},'Box','off','Location','northeast')
        nexttile
        tem_peak=vertcat(temp_task_peak,temp_passive_peak)
        % [~, p, ~, stats] = ttest(tem_peak{2}, tem_peak{4});

        context_diff{curr_roi}{curr_group}=cellfun(@(task,pass)  (task-pass)./(task+pass),temp_task_peak,temp_passive_peak,'UniformOutput',false   )
        % context_diff{curr_roi}{curr_group}=cellfun(@(task,pass)  (task-pass),temp_task_peak,temp_passive_peak,'UniformOutput',false   )

        tem_peak_mean=cellfun(@nanmean,tem_peak);
        tem_peak_error=cellfun(@(x) std(x,'omitmissing')./sqrt(length(x)),tem_peak);

        hold on
        barColors{1} = [[ 0 0 1];[0.5 0.5 1];[ 0 0 0];[0.5 0.5 0.5]]; % 浅蓝、浅红
        barColors{2} = [[ 1 0 0];[1 0.5 0.5];[ 0 0 0];[0.5 0.5 0.5]]; % 浅蓝、浅红
        % barColors{1} = [[ 0 0 1];[0.5 0.5 1];[ 0 0 0];[0.5 0.5 0.5];[ 0 0 1];[0.5 0.5 1];[ 0 0 0];[0.5 0.5 0.5]]; % 浅蓝、浅红
        % barColors{2} = [[ 1 0 0];[1 0.5 0.5];[ 0 0 0];[0.5 0.5 0.5];[ 1 0 0];[1 0.5 0.5];[ 0 0 0];[0.5 0.5 0.5]]; % 浅蓝、浅红

        hold on;
        barHandle = bar(1:4, tem_peak_mean([2 6  4 8 ]), 0.5, 'FaceColor', 'flat'); % 'FaceColor' 只能用于单个柱子时指定
        % barHandle = bar(1:8, tem_peak_mean([2 6 1 5 4 8 3 7]), 0.5, 'FaceColor', 'flat'); % 'FaceColor' 只能用于单个柱子时指定

        % 逐个设置柱子的颜色
        if length(barHandle) == 1  % 仅有一个 bar 对象时
            barHandle.FaceColor = 'flat'; % 确保它接受颜色
            barHandle.CData = barColors{curr_group}; % 为不同组设置不同颜色
        else
            for i = 1:2
                barHandle(i).FaceColor = barColors{curr_group}(i, :);
            end
        end
        % 添加误差条
        errorbar(1:4,tem_peak_mean([2 6  4 8 ]),tem_peak_error([2 6  4 8 ]), 'k', 'LineStyle', 'none', 'LineWidth', 1.5); % 黑色误差条
        % errorbar(1:8,tem_peak_mean([2 6 1 5 4 8 3 7]),tem_peak_error([2 6 1 5 4 8 3 7]), 'k', 'LineStyle', 'none', 'LineWidth', 1.5); % 黑色误差条

        xticks([1:4])
        % xticklabels({'L post task','L post passive','L pre task','L pre passive','R post task','R post passive','R pre task','R pre passive'})
        xticklabels({'L post task','L post passive','R post task','R post passive'})
        ylim(scale*[0 1.5])
        xline(2.5,'LineStyle',':')
        title(title_area{curr_roi},'FontWeight','normal')

    end
end




%%
% saveas(gcf,[Path 'figures\summary\figures\fig2 kernels task vs passive' ], 'jpg');
colors2=[ 0.5 0.5 1;1 0.5 0.5;0.5 0.5 1;1 0.5 0.5];
colors1=[ 0 0 1;1 0 0;0 0 1;1 0 0];

mean_1=[nanmean(context_diff{1}{1}{2}) nanmean(context_diff{1}{2}{2}) nanmean(context_diff{3}{1}{2}) nanmean(context_diff{3}{2}{2})]
error_1=[std(context_diff{1}{1}{2}) nanmean(context_diff{1}{2}{2}) nanmean(context_diff{3}{1}{2}) nanmean(context_diff{3}{2}{2})]

temp_data=cellfun(@(x) cellfun(@(a)  a{2},x,'UniformOutput',false ),context_diff([1 3]),'UniformOutput',false)
temp_data_1=cat(2,temp_data{:});

mean_1= cellfun(@(x)  nanmean(x) ,cat(2,temp_data{:}),'UniformOutput',true)
error_1=  cellfun(@(x)  std(x,'omitmissing')/sqrt(length(x)) ,cat(2,temp_data{:}),'UniformOutput',true)

fig = figure('Position',[50 50 150 250]);  % 图窗背景透明
ax = axes('Parent', fig);
hold on
barHandle= bar(1:4,mean_1, 0.5, 'FaceColor', 'flat','EdgeColor','none');
barHandle.CData = colors2; % 为不同组设置不同颜色
errorbar(1:4,mean_1,error_1, 'k', 'LineStyle', 'none', 'LineWidth', 1.5)

% arrayfun(@(g) scatter(g*ones(length(temp_data_1{g}),1) + randn(size(temp_data_1{g},1),1)*0.05,...
%          temp_data_1{g}, ...
%          20, 'filled', ...
%          'MarkerFaceColor', colors1(g,:)), 1:4);
xline(2.5,'LineStyle',':')

xticks([1:4])
xticklabels({'V-l-mPFC','A-l-mPFC','V-l-aPFC','A-l-aPFC'})
ylabel('context difference')
set(ax, 'Color', 'none');        % 坐标轴背景透明



% 添加 ranksum 检验及星号
y_max = max(cellfun(@max, temp_data_1)) + 0.2; % 初始 y 值
h_offset = 0.15; % 每组比较向上偏移的高度
star_count = 0; % 当前比较编号，用于偏移高度


for i = 1:length(temp_data_1)-1
    for j = i+1:length(temp_data_1)
        p = ranksum(temp_data_1{i}, temp_data_1{j});

        % 判断显著性等级
        if p < 0.05
            if p < 0.001
                stars = '***';
            elseif p < 0.01
                stars = '**';
            else
                stars = '*';

            end
            % else
            %     stars=num2str(p)
            % end


            % 星号y位置，逐层向上叠加
            star_count = star_count + 1;
            y = y_max + (star_count - 1) * h_offset;

            % 连线
            plot([i j], [y y], 'k-', 'LineWidth', 1);

            % 星号文本
            text(mean([i j]), y + 0.02, stars, ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'FontWeight', 'bold');

        end
    end
end







