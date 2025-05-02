clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')


data_passive=load([ Path 'summary_data\passive kernels of images crossday corsstime.mat']);
data_task=load([ Path 'summary_data\task kernels of images crossday corsstime.mat']);

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_kernels=1/surround_samplerate*[-10:30];
kernels_period=t_kernels>=-0.1& t_kernels<=0.3
%% stage 1

title_images={'pre learn','post learn'};
title_area={'pl-mPFC','pr-mPFC','al-mPFC','ar-mPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}

figure('Position', [50 50 1500 900]);
t = tiledlayout(6, 7, 'TileSpacing', 'tight', 'Padding', 'tight');
xlabel_all={'L','C','R';'4k','8k','12k'};

for curr_group=1:2
    used_passive=4-curr_group;
    main_preload_vars = who;
    scale=0.0003;
    Color={'B','R'};

    a3=nexttile
    imagesc(data_task.all_buf_data{curr_group}{4})
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [0, 1]);
    colormap(a3, ap.colormap(['W' Color{curr_group}]));

    if curr_group==1
        selected_area=[12 5 1 3];
    else
        selected_area=[8 5 1 3];
    end
    for curr_area=selected_area
        a4=nexttile

        imagesc(t_kernels,[], data_task.all_data{curr_group}(:,1:8,curr_area)')
        yline(3.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a4, ap.colormap(['KW' Color{curr_group}]));
        xlabel('time (s)')
        title(title_area{curr_area})
    end

    cmap = parula(4)
    for curr_day= [1 7]
        a4=nexttile
        hold on
        ii=0
        for curr_area=selected_area
            ii=ii+1;
            ap.errorfill(t_kernels(kernels_period),data_task.all_scross_time_mean{curr_group}(kernels_period,curr_day,curr_area),...
                data_task.all_scross_time_error{curr_group}(kernels_period,curr_day,curr_area)  ,cmap(ii,:),0.1,0.5);
        end
        ylim(scale*[-0.4 1.4])
       ylabel('\Delta F/F')

        xlabel('time (s)')
        xline(0,'LineStyle',':')
    end
     legend({'',title_area{selected_area(1)},'',title_area{selected_area(2)},...
         '',title_area{selected_area(3)},'',title_area{selected_area(4)}},'Box','off','Location','eastoutside')

    a1=nexttile
    
    imagesc(data_passive.all_buf_data{curr_group}{curr_group}{5})
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [0, 1]);
    colormap(a1, ap.colormap(['W' Color{curr_group}]));

    for curr_area=selected_area
        a2=nexttile

        imagesc(t_kernels,[], permute(data_passive.all_data_passive{curr_group}{curr_group}{curr_area}(:,used_passive,4:11),[3,1,2]))
        yline(3.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a2, ap.colormap(['KW' Color{curr_group}]));
        xlabel('time (s)')
        title(title_area{curr_area})
    end
    % passive cross time
    for curr_day= [4 11]
        a6=nexttile
        hold on
        ii=0
        for curr_area=selected_area
            ii=ii+1;
            ap.errorfill(t_kernels(kernels_period),...
                data_passive.buf3_roi_l_mean_crosstime{curr_group}{curr_group}{curr_area}{curr_day}(kernels_period,used_passive),...
                data_passive.buf3_roi_l_error_crosstime{curr_group}{curr_group}{curr_area}{curr_day}(kernels_period,used_passive)  ,cmap(ii,:),0.1,0.5);

        end
        ylim(scale*[-0.4 0.8])
        xlabel('time (s)')
        ylabel('\Delta F/F')
        xline(0,'LineStyle',':')
    end
    % legend('Box','off','Location','eastoutside')

  cb_tile = nexttile();  % tile index 30 是第 5 行第 5 列，跨两列
axis off                         % 不需要坐标轴显示
colormap(cb_tile,ap.colormap(['W' Color{curr_group}] ));
    clim(scale .* [0, 1]);

cb = colorbar(cb_tile, 'north');  % 把 colorbar 放进这个 tile
cb.Label.String = '\DeltaF/F';
cb.Label.Units = 'normalized';   % 使用归一化坐标
% cb.Label.Position = [0.5, -0.8, 0];  % X, Y, Z，Y负数表示往下
% cb.Label.HorizontalAlignment = 'center';
% cb.Label.VerticalAlignment = 'top';


    colors = { [1 0 0],[0 0 0]}; % 定义颜色
    for curr_area=selected_area
        a5=  nexttile
        yyaxis left   % 选择左 y 轴
        ax = gca;     % 获取当前坐标轴
        ax.YColor = 'k';  % 设置左侧 y 轴颜色为黑色
        ylabel('\Delta F/F')

        if curr_area==12
            ylim(scale .* [-0.1, 5]);

        else

            ylim(scale .* [-0.1, 0.6]);
        end
        ap.errorfill(1:8,data_passive.buf3_roi_mean_crossday{curr_group}{curr_group}{curr_area}(used_passive,4:11),...
            data_passive.buf3_roi_error_crossday{curr_group}{curr_group}{curr_area}(used_passive,4:11)  ,colors{2},0.1,0.5);
        yyaxis right  % 选择左 y 轴
        ax = gca;     % 获取当前坐标轴
        ax.YColor = 'r';  % 设置左侧 y 轴颜色为黑色

        ap.errorfill(1:8,data_task.all_peak_mean{curr_group}(1:8,curr_area),...
            data_task.all_peak_error{curr_group}(1:8,curr_area)  ,colors{1},0.1,0.5);

        if curr_area==12
            ylim(scale .* [-0.1, 5]);

        else

            ylim(scale .* [-0.1, 1.2]);
        end
        xlim([0.5 8.5])
        xline(3.5);
        xticks([2 6]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签
                ylabel('\Delta F/F')

    end
   
    ax = nexttile; % 选择第二个子图
     ax.Visible = 'off'; % 隐藏该子图
% axis(ax10, 'off');  % 不显示轴
% legend(ax10, a6); 

    ax = nexttile; % 选择第二个子图
    ax.Visible = 'off'; % 隐藏该子图


    clearvars('-except',main_preload_vars{:});


end

% sgtitle('task vs passive')
saveas(gcf,[Path 'figures\summary\figures\figure 2_task vs passive'], 'jpg');


%% stage2