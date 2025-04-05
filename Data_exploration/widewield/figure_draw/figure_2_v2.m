%% load VA and AV group data
clear all
clc

Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/ surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);
                




Color={'B','R'};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};


select_group=1:2
% select_group=3:4



%% load task data
data_part=cell(length(select_group),1);
buf_images_all=cell(length(select_group),1);
for curr_group=select_group

    Path_task=[Path 'mat_data\summary_data\task ' data_type{used_data} ' in group ' groups{curr_group}  '.mat' ];
 buffer_file = matfile(Path_task, 'Writable', false); % 以只读模式打开
 data_part{curr_group} = buffer_file.data_all;

 buf_images_all{curr_group}=permute(nanmean(buffer_file.data_all_video(:,:,:,:,:),4),[1 2 5 3 4]);
end

% apply guassian filter
apply_filter=1

if apply_filter==1
sigma=20
data_part_filter=cellfun(@(x) cellfun(@(y) cellfun(@ (z) arrayfun(@(i) z(:,:,i)- imgaussfilt(z(:,:,i), sigma), 1:size(z,3), 'UniformOutput', false),y,'UniformOutput',false),x,'UniformOutput',false    ),data_part,'UniformOutput',false);
data_part_filter1=cellfun(@(x) cellfun(@(y) cellfun(@ (z) cat(3,z{:}),y,'UniformOutput',false),x,'UniformOutput',false    ),data_part_filter,'UniformOutput',false);
data_part=data_part_filter1;
buf_images_all_filter=cellfun(@(z)  arrayfun(@(i) z(:,:,i)- imgaussfilt(z(:,:,i), sigma), 1:size(z,3), 'UniformOutput', false),buf_images_all,'UniformOutput',false);
buf_images_all_filter1=cellfun(@(x) cat(3,x{:}),buf_images_all_filter,'UniformOutput',false);
buf_images_all=buf_images_all_filter1;
end

clear buf_images_all_filter buf_images_all_filter1 data_part_filter1 data_part_filter

t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];
task_boundary1=0;
task_boundary2=0.2;
period_kernels=find(t_kernels>task_boundary1&t_kernels<task_boundary2);
use_period=period_kernels;
use_t=t_kernels;
title_area={'p-l-mPFC','a-l-mPFC','p-l-mPFC-non learn','a-l-mPFC-non learn'};
title2_task={'VA ','AV ','VA','AV','VA','AV visual','VA visual non leaner','AV visual non learner'};
title1_task={'pre learn1','post learn1-1','post learn1-2','pre learn2','post learn2-1','post learn2-2','mixed V','mixed A'};
scale=0.0003;
title_images={'pre learn','post learn','post learn','pre learn','post learn','post learn','visual in mixed','auditory in mixed'};


%% draw   figure task stage 1

figure('Position', [50 50 1200 400]);
t = tiledlayout(2, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
Color={'B','R','B','R','B','R','B','R','B','R'};
for curr_group=select_group
        preload_vars=who;

    % curr_area=select_group*2-1;
        curr_area=[1 3];

    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
   
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);

% buf3_roi_peak_mean1=permute(nanmean(cat(4,buf3_roi_peak1{:}),4),[2 3 1]);

    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length(data_part{curr_group}));



    for curr_image=[1 3]
        a1=nexttile
        imagesc(buf_images_all{curr_group}(:,:,curr_image))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{curr_group}] ));
        title(title_images{curr_image})
        for i=1:6
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
        if curr_image==1
            text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 0);
        end
    end

    a2=nexttile
    imagesc(buf_images_all{curr_group}(:,:,3)-fliplr(buf_images_all{curr_group}(:,:,3)))
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
    colormap(a2, ap.colormap(['KW' Color{curr_group}] ));
     for i=1:6
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
    title(title_images{curr_image})
    xlim([0 216])
    

    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

    a3=nexttile
    hold on
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,6:7,curr_area(1),:),[2,4]),...
        std(buf3_roi_stim2(:,6:7,curr_area(1),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(1)},0.1,0.5);
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,6:7,curr_area(2),:),[2,4]),...
        std(buf3_roi_stim2(:,6:7,curr_area(2),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(2)},0.1,0.5);
    xlim([0 0.5])
    xlabel('time (s)')
    ylabel('df/f')




    nexttile
    for i=1:6
    ap.errorfill(1:7,buf3_roi_peak_mean(1:7 ,i),buf3_roi_peak_error(1:7,i) ,colors{i},0.1,0.5);
    end
     xlim([0.5 7.5])
    xticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels(title_images); % 设置对应的标签
    ylim([0 1.5*scale])
        xline(2.5);
% legend
          legend({'','pl-mPFC','','pr-mPFC','','al-mPFC','','ar-mPFC','','l-PPC','','r-PPC'},'Location','eastoutside')

            clearvars('-except',preload_vars{:});

end
sgtitle('task kernels in stage 1')

saveas(gcf,[Path 'figures\summary\figures\figure 2_task_stage1 in ' groups{curr_group}], 'jpg');
%% draw   figure task stage 1
task_data=struct;
task_data.images=cell(2,1);
task_data.roi_stim=cell(2,1);
task_data.roi_stim_mean=cell(2,1);
task_data.roi_stim_error=cell(2,1);
 scale=0.0002;

figure('Position', [50 50 1200 400]);
t = tiledlayout(2, 11, 'TileSpacing', 'compact', 'Padding', 'compact');
Color={'B','R','B','R','B','R','B','R','B','R'};

for curr_group=select_group
        preload_vars=who;

    % curr_area=select_group*2-1;
        curr_area=[1 3];

    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
   
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);

% buf3_roi_peak_mean1=permute(nanmean(cat(4,buf3_roi_peak1{:}),4),[2 3 1]);

    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length(data_part{curr_group}));



    for curr_image=3
        a1=nexttile

        task_data.images{curr_group}=buf_images_all{curr_group}(:,:,curr_image);

        imagesc(buf_images_all{curr_group}(:,:,curr_image))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{curr_group}] ));
        title(title_images{curr_image})
        for i=1:6
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
        if curr_image==1
            text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 0);
        end
    end
    
    title_area={'pl-mPFC','pr-mPFC','al-mPFC','ar-mPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
    % figure
    for curr_area=[12 8 5 1 3 ]
    a2=nexttile
    task_data.roi_stim{curr_group}{curr_area}=buf3_roi_stim3_mean(:,1:7,curr_area)';

    imagesc(use_t,[], buf3_roi_stim3_mean(:,1:7,curr_area)')
    colormap(a2, ap.colormap(['KW' Color{curr_group}] ));
    clim(scale .* [-1, 1]);
    yline(2.5)
    yticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    yticklabels(title_images); % 设置对应的标签
    xlabel('time (s)')
    title(title_area{curr_area})
    end

    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5],[ 0 0 0],[0 0 0]}; % 定义颜色


    for curr_area=[12 8 5 1 3]
            nexttile
    task_data.roi_stim_mean{curr_group}{curr_area}=buf3_roi_peak_mean(1:7 ,curr_area);
    task_data.roi_stim_error{curr_group}{curr_area}=buf3_roi_peak_error(1:7 ,curr_area);

    ap.errorfill(1:7,buf3_roi_peak_mean(1:7 ,curr_area),buf3_roi_peak_error(1:7,curr_area) ,colors{i},0.1,0.5);
   
     xlim([0.5 7.5])
    xticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels(title_images); % 设置对应的标签
    ylim([0 1.5*scale])
        xline(2.5);
    end

            clearvars('-except',preload_vars{:});

end
sgtitle('task kernels in stage 1')


%% draw   figure task stage 2


figure('Position', [50 50 1200 400]);
t = tiledlayout(2, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
Color={'R','B','R','B','R','B','B','B'};
for curr_group=select_group
    preload_vars=who;
    % curr_area=select_group*2-1;
        curr_area=[1 3];

    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);
    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length(data_part{curr_group}));



    for curr_image=[4 6]
        a1=nexttile
        imagesc(buf_images_all{curr_group}(:,:,curr_image))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{curr_group}] ));
        title(title_images{curr_image})
        for i=1:6
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
        if curr_image==4
            text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 0);
        end
    end

    a2=nexttile
    imagesc(buf_images_all{curr_group}(:,:,6)-fliplr(buf_images_all{curr_group}(:,:,6)))
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
    colormap(a2, ap.colormap(['KW' Color{curr_group}] ));
     for i=1:6
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
    title(title_images{curr_image})
    xlim([0 216])
    

    % a3=nexttile
    % imagesc(use_t,[],buf3_roi_stim1_mean(:,1:7,curr_area(1))');
    % colormap(a3, ap.colormap(['KW' Color{select_group}] ));
    % clim(scale .* [-1, 1]);
    % yline(2.5)
    % yticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % yticklabels(title_images); % 设置对应的标签
    % xlabel('time (s)')
    % title(title_area{select_group})
    % colorbar
    % 
    % a4=nexttile
    % imagesc(use_t,[],buf3_roi_stim1_mean(:,1:7,curr_area(2))');
    % colormap(a4, ap.colormap(['KW' Color{select_group}] ));
    % clim(scale .* [-1, 1]);
    % yline(2.5)
    % yticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % yticklabels(title_images); % 设置对应的标签
    % xlabel('time (s)')
    % title(title_area{select_group})
    % colorbar
    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

    a3=nexttile
    hold on
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,13:14,curr_area(1),:),[2,4]),...
        std(buf3_roi_stim2(:,13:14,curr_area(1),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(1)},0.1,0.5);
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,13:14,curr_area(2),:),[2,4]),...
        std(buf3_roi_stim2(:,13:14,curr_area(2),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(2)},0.1,0.5);
    xlim([0 0.5])
    xlabel('time (s)')
    ylabel('df/f')


    % imagesc(use_t,[],buf3_roi_stim1_mean(:,1:7,curr_area(1))');
    % colormap(a3, ap.colormap(['KW' Color{select_group}] ));
    % clim(scale .* [-1, 1]);
    % yline(2.5)
    % yticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % yticklabels(title_images); % 设置对应的标签
    % xlabel('time (s)')
    % title(title_area{select_group})
    % colorbar



    nexttile
    for i=1:6
    ap.errorfill(1:7,buf3_roi_peak_mean(8:14,i),buf3_roi_peak_error(8:14,i) ,colors{i},0.1,0.5);
    end
    xlim([0.5 7.5])
    xline(2.5);
    xticks([2 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels(title_images); % 设置对应的标签
    ylim([0 scale*1.5])
          legend({'','pl-mPFC','','pr-mPFC','','al-mPFC','','ar-mPFC','','l-PPC','','r-PPC'},'Location','eastoutside')
            clearvars('-except',preload_vars{:});


end
sgtitle('task kernels in stage 2')


   saveas(gcf,[Path 'figures\summary\figures\figure 2_task_stage2 in ' groups{curr_group}], 'jpg');


%% draw   figure task stage 3 mixed

figure('Position', [50 50 1200 400]);
t = tiledlayout(2, 7, 'TileSpacing', 'compact', 'Padding', 'compact');
Color={'B','R','B','R','B','R','B','B'};
for curr_group=select_group
    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);
    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length(data_part{curr_group}));



    for curr_image=[7 8]
        a1=nexttile
        imagesc(buf_images_all{curr_group}(:,:,curr_image))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{curr_image-6}] ));
        title(title_images{curr_image})

        for i=1:4
            boundaries1 = bwboundaries(roi1(i).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
        if curr_image==7
            text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 0);
        end

        a2=nexttile
        imagesc(buf_images_all{curr_group}(:,:,curr_image)-fliplr(buf_images_all{curr_group}(:,:,curr_image)))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a2, ap.colormap(['KW' Color{curr_image-6}] ));

        xlim([0 216])
        for i=1:4
            boundaries1 = bwboundaries(roi1(i).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end

        colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

        a3=nexttile

        % ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,3*curr_image-6:3*curr_image-4,curr_area(1),:),[2,4]),...
        %     std(buf3_roi_stim2(:,15:17,curr_area(1),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{1},0.1,0.5);
        % ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,3*curr_image-6:3*curr_image-4,curr_area(2),:),[2,4]),...
        %     std(buf3_roi_stim2(:,15:17,curr_area(2),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{3},0.1,0.5);
        %
        ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,3*curr_image-6:3*curr_image-4,1,:),[2,4]),...
            std(buf3_roi_stim2(:,15:17,3,:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{1},0.1,0.5);
        ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,3*curr_image-6:3*curr_image-4,3,:),[2,4]),...
            std(buf3_roi_stim2(:,15:17,1,:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{3},0.1,0.5);
        xlim([0 0.5])
        xlabel('time (s)')
        ylabel('df/f')
        ylim(scale .* [-0.2, 1]);


    end






    nexttile
    for i=1:6
        ap.errorfill(1:3,buf3_roi_peak_mean(15:17,i),buf3_roi_peak_error(15:17,i) ,colors{i},0.1,0.5);
        % ap.errorfill(4:6,buf3_roi_peak_mean(18:20,i),buf3_roi_peak_error(18:20,i) ,colors{i},0.1,0.5);
    end
    for i=1:6
        % ap.errorfill(1:3,buf3_roi_peak_mean(15:17,i),buf3_roi_peak_error(15:17,i) ,colors{i},0.1,0.5);
        ap.errorfill(4:6,buf3_roi_peak_mean(18:20,i),buf3_roi_peak_error(18:20,i) ,colors{i},0.1,0.5);
    end


    xlim([0.5 6.5])
    xticks([ 2,5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels(title_images(7:8)); % 设置对应的标签
    ylim([0 scale*1.5])
    xlabel('days')
    legend({'','pl-mPFC','','pr-mPFC','','al-mPFC','','ar-mPFC','','l-PPC','','r-PPC'},'Location','eastoutside')
    % legend
end
sgtitle('task kernels in stage 3')

saveas(gcf,[Path 'figures\summary\figures\figure 2_task_stage3 in ' groups{curr_group}], 'jpg');


%% sequenced activity
for curr_stage=1:2

    if curr_stage==1
        image_idx=3; stim_idx=5:7;Color={'B','R'};
             oder=[12 1 3;8 5 3];


    else
        image_idx=6; stim_idx=12:14;Color={'R','B'};
                oder=[8 5 3;12 1 3];

    end

    figure('Position', [50 50 600 400]);
t = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');


for curr_group=1:2
        preload_vars=who;

    % curr_area=select_group*2-1;
        curr_area=[1 3];

    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);

    a1=nexttile
    imagesc(buf_images_all{curr_group}(:,:,image_idx))
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
    colormap(a1, ap.colormap(['KW' Color{curr_group}] ));
    title(title_images{3})
    for i=oder(curr_group,:)
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 1 0])
    end

    buff_mean=normalize(permute(mean( buf3_roi_stim3_mean(:,stim_idx,:),2),[1 3 2]), 'range', [0 1]);
    nexttile
    hold on
    plot(use_t,buff_mean(:,oder(curr_group,1))+2,'Color',[1 0 0],'LineWidth',2)
    plot(use_t,buff_mean(:,oder(curr_group,2))+1,'Color',[0 0 0],'LineWidth',2)
    plot(use_t,buff_mean(:,oder(curr_group,3)),'Color',[0 0 1],'LineWidth',2)
    ylim([-0.5 3])
    xlim([-0.1 0.4])
    % ax = gca; % 获取当前坐标轴
    % ax.YColor = 'none'; % 隐藏 y 轴
    % ax.Box = 'off'; % 取消边框
    axis off

% 获取坐标轴范围
xlim_vals = xlim;
ylim_vals = ylim;
scale_lenx = (xlim_vals(2) - xlim_vals(1)) * 0.1; % 标尺长度 10%
scale_leny =0.5; % 标尺长度 10%

% 右下角标尺位置
x0 = xlim_vals(2) - scale_lenx * 1.5; 
y0 = ylim_vals(1) + scale_lenx * 0.5;

% 画标尺
line([x0, x0 + scale_lenx], [y0, y0], 'Color', 'k', 'LineWidth', 2); % X 标尺
line([x0+ scale_lenx, x0+ scale_lenx], [y0, y0 + scale_leny], 'Color', 'k', 'LineWidth', 2); % Y 标尺

% 标注
text(x0 + scale_lenx / 2, y0 - 4*scale_lenx , '100 ms', 'HorizontalAlignment', 'center');
text(x0 + scale_lenx*4 , y0 + scale_leny / 2, '0.5 norm', 'HorizontalAlignment', 'right');

    xlabel('time (s)')
    % xline(0);xline(0.05);xline(0.08)
    name={'V1','p-mPFC','a-mPFC';'Auditory Cortex','PPC','a-mPFC'};
    legend(name(curr_group,:),'Location','eastoutside')



            clearvars('-except',preload_vars{:});

end
 sgtitle(['task kernels in stage ' num2str(curr_stage)])

    saveas(gcf,[Path 'figures\summary\figures\figure 2_sequence task kernels in stage ' num2str(curr_stage)], 'jpg');
end


%%  task raw vs kernels

%load task raw data and kernels

% data_part=cell(2,1);
buf_images_all_kernels=cell(2,1);
buf_images_all_raw=cell(2,1);

for curr_group=select_group

Path_task_kernels=[Path 'mat_data\summary_data\task ' data_type{2} ' in group ' groups{curr_group}  '.mat' ];
 buffer_file_kernels = matfile(Path_task_kernels, 'Writable', false); % 以只读模式打开
 % data_part{curr_group} = buffer_file.data_all;
Path_task_raw=[Path 'mat_data\summary_data\task ' data_type{1} ' in group ' groups{curr_group}  '.mat' ];
 buffer_file_raw = matfile(Path_task_raw, 'Writable', false); % 以只读模式打开


 buf_images_all_kernels{curr_group}=permute(nanmean(buffer_file_kernels.data_all_video(:,:,:,:,:),4),[1 2 5 3 4]);
 buf_images_all_raw{curr_group}=permute(nanmean(buffer_file_raw.data_all_video(:,:,:,:,:),4),[1 2 5 3 4]);

end


figure('Position', [50 50 550 400]);
t = tiledlayout(2, 4, 'TileSpacing', 'tight', 'Padding', 'none');
for workflow_idx=1:2

a1=nexttile
imagesc(buf_images_all_raw{workflow_idx}(:,:,4))
axis image off;
ap.wf_draw('ccf', 'black');
scale=0.020
clim(scale .* [-1, 1]);
colormap(a1, ap.colormap(['KW' Color{workflow_idx}]));
title('raw')
h1=colorbar
h1.Location='southoutside'


a11=nexttile
imagesc(buf_images_all_raw{workflow_idx}(:,:,1)-fliplr(buf_images_all_raw{workflow_idx}(:,:,1)))
axis image off;
ap.wf_draw('ccf', 'black');
clim(scale .* [-1, 1]);
colormap(a11, ap.colormap(['KW' Color{workflow_idx}]));
xlim([0 216])


a2=nexttile
imagesc(buf_images_all_kernels{workflow_idx}(:,:,3))
axis image off;
ap.wf_draw('ccf', 'black');
scale=0.0005
clim(scale .* [-1, 1]);
colormap(a2, ap.colormap(['KW' Color{workflow_idx}]));
title('kernels')
h2=colorbar
h2.Location='southoutside'

a22=nexttile
imagesc(buf_images_all_kernels{workflow_idx}(:,:,1)-fliplr(buf_images_all_kernels{workflow_idx}(:,:,1)))
axis image off;
ap.wf_draw('ccf', 'black');
clim(scale .* [-1, 1]);
colormap(a22, ap.colormap(['KW' Color{workflow_idx}]));
xlim([0 216])

end


  % saveas(gcf,[Path 'figures\summary\figures\figure 2_task_raw_vs_kernels ' groups{curr_group}], 'jpg');


  %% cortical images between naive & well trained mice in the task
figure('Position', [50 50 600 400]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
Color={'B','R','B','R','B','R','B','R','B','R'};
title_images={'naive','post learn','well trained','pre learn','post learn','well trained','visual in mixed','auditory in mixed'};
 scale=0.0002;

for curr_group=select_group
        preload_vars=who;

    % curr_area=select_group*2-1;
        curr_area=[1 3];

    for curr_animal=1:length( data_part{curr_group})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end
  

    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
   
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);

% buf3_roi_peak_mean1=permute(nanmean(cat(4,buf3_roi_peak1{:}),4),[2 3 1]);

    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length(data_part{curr_group}));



    for curr_image=[1 3]
        a1=nexttile
        imagesc(buf_images_all{curr_group}(:,:,curr_image))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{curr_group}] ));
        title(title_images{curr_image})
        for i=[1 3]
        boundaries1 = bwboundaries(roi1(i).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
        end
       
    end

   
    
    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

    a3=nexttile
    hold on
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,6:7,curr_area(1),:),[2,4]),...
        std(buf3_roi_stim2(:,6:7,curr_area(1),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(1)},0.1,0.5);
    ap.errorfill(use_t,nanmean(buf3_roi_stim2(:,6:7,curr_area(2),:),[2,4]),...
        std(buf3_roi_stim2(:,6:7,curr_area(2),:),0,[2,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),colors{curr_area(2)},0.1,0.5);
    xlim([0 0.5])
    xlabel('time (s)')
    ylabel('df/f')
    lgd=legend({'','p-l-mPFC','','a-l-mPFC'},'Box','off','Location','northeast')
        % 获取 legend 的位置
        legendPos = lgd.Position;

        % 检查是否与数据线重叠，如果重叠，则调整位置
        if legendPos(1) > 0.7  % 如果 legend 的 x 位置靠近图形边缘
            lgd.Position = [legendPos(1) + 0.02, legendPos(2), legendPos(3), legendPos(4)]; % 向右移动 legend
        end

            clearvars('-except',preload_vars{:});

end
  saveas(gcf,[Path 'figures\summary\figures\figure 2_task_kernels naive vs well trained' ], 'jpg');


%% images across time
 scale=0.00015;
 image_task_time_2=cell(2,2);
for curr_group=select_group
    preload_vars=who;
    image_time=vertcat(data_part{curr_group}{:});
    image_time_1=arrayfun(@(i) nanmean(cat(4,image_time{:,i}),4) ,1:size(image_time,2),'UniformOutput',false );
    for curr_stage=1:2

        if curr_stage==1
            image_task_time_2{curr_group,curr_stage}=nanmean(cat(4,image_time_1{5:7}),4);
        else
            image_task_time_2{curr_group,curr_stage}=nanmean(cat(4,image_time_1{12:14}),4);
        end

        figure('Position', [50 50 1000 200]);
        t1 = tiledlayout(1, length(find(t_kernels>=0& t_kernels<0.25)), 'TileSpacing', 'none', 'Padding', 'none');

        for curr_time =find(t_kernels>=0& t_kernels<0.25)
            nexttile
            buff_image=image_task_time_2{curr_group,curr_stage}(:,:,curr_time);
            imagesc(buff_image)
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap( ap.colormap(['KW' Color{curr_group}] ));
            title(num2str(t_kernels(curr_time)))
        end
        sgtitle(groups{curr_group})

        saveas(gcf,[Path 'figures\summary\figures\figure 2_task_kernels_across_time ' groups{curr_group} 'stage ' num2str(curr_stage) ], 'jpg');


    end
    clearvars('-except',preload_vars{:});
end


% figure;
% bbb=image_task_time_2{2,2}-image_task_time_2{1,1};
%   figure('Position', [50 50 1000 200]);
%         t1 = tiledlayout(1, length(find(t_kernels>=0& t_kernels<0.25)), 'TileSpacing', 'none', 'Padding', 'none');
%
%         for curr_time =find(t_kernels>=0& t_kernels<0.25)
%     nexttile
%     imagesc(bbb(:,:,curr_time))
%     axis image off;
%     ap.wf_draw('ccf', 'black');
%     clim(scale .* [-1, 1]);
%     colormap( ap.colormap(['KW' Color{curr_group}] ));
%     title(num2str(t_kernels(curr_time)))
% end
%% load passive
all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];
 
passive_boundary=0.2;
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);
use_period=period_kernels;
 use_t=t_kernels;
title_area={'p-l-mPFC','a-l-mPFC'};


data_part=cell(2,1);
buf_images_all=cell(2,1);
buf_images_all_raw=cell(2,1);

for curr_group=1:2

Path_task=[Path 'mat_data\summary_data\passive ' data_type{used_data} ' in group ' groups{curr_group}  '.mat' ];
 buffer_file = matfile(Path_task, 'Writable', false); % 以只读模式打开
 data_part{curr_group} = buffer_file.data_all;

     

 buf_images_all{curr_group}=buffer_file.data_all_video;

 buf_images_all_raw{curr_group}=buffer_file.data_all_video;

end



% apply guassian filter
apply_filter=1
if apply_filter==1
sigma=20;
data_part_filter=cell(2,1);
for i=1:length(data_part)
    for j=1:length(data_part{i}.lcr_passive)
        for s=1:length(data_part{i}.lcr_passive{j})
            for a=1:size(data_part{i}.lcr_passive{j}{s},3)
                 for b=1:size(data_part{i}.lcr_passive{j}{s},4)
       data_part_filter{i}.lcr_passive{j,1}{s,1}(:,:,a,b)= data_part{i}.lcr_passive{j}{s}(:,:,a,b)...
           - imgaussfilt( data_part{i}.lcr_passive{j}{s}(:,:,a,b), sigma);
        data_part_filter{i}.hml_passive_audio{j,1}{s,1}(:,:,a,b)= data_part{i}.hml_passive_audio{j}{s}(:,:,a,b)...
           - imgaussfilt( data_part{i}.hml_passive_audio{j}{s}(:,:,a,b), sigma);
                 end
            end
        end
    end
end

buf_images_all_filter=cell(2,1);
for i=1:length(buf_images_all)
    for j=1:size(buf_images_all{i}.lcr_passive,3  )
        for q=1:size(buf_images_all{i}.lcr_passive,4  )
            for w=1:size(buf_images_all{i}.lcr_passive,5  )
                buf_images_all_filter{i}.lcr_passive(:,:,j,q,w) = buf_images_all{i}.lcr_passive(:,:,j,q,w)-...
                     imgaussfilt( buf_images_all{i}.lcr_passive(:,:,j,q,w), sigma);
                buf_images_all_filter{i}.hml_passive_audio(:,:,j,q,w) = buf_images_all{i}.hml_passive_audio(:,:,j,q,w)-...
                     imgaussfilt( buf_images_all{i}.hml_passive_audio(:,:,j,q,w), sigma);
            end
        end
    end
end

end




title_images={'pre learn','post learn'};

%% draw  figure  passive stage 1

figure('Position', [50 50 1200 800]);
t = tiledlayout(4, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
xlabel_all={'L','C','R';'4k','8k','12k'};

for curr_group=1:2
  for   workflow_idx =1:2;

          % clear   buf1 buf3_roi buf3_roi_peak buf3_roi_stim buf3_roi_stim1 buf3_roi_stim1_mean buf3_roi_peak1 buf3_roi_peak_mean buf3_roi_peak_error

       main_preload_vars = who;


        used_area=workflow_idx*2-1;
       curr_stim=4-workflow_idx;

        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end


        scale=0.0002;
        Color={'B','R'};
        %

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
        
        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
        buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

        buf_images_all1=permute(nanmean(buf_images_all_filter{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,[2 4]),4),[1 2 5 3 4]);

        for curr_phase=1:2
            a1=nexttile
            % imagesc(buf_images_all1(:,:,curr_phase)-imgaussfilt(buf_images_all1(:,:,curr_phase),sigma))
             imagesc(buf_images_all1(:,:,curr_phase))

            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(a1, ap.colormap(['KW' Color{workflow_idx}]));
            title(title_images{curr_phase})
            for curr_area=1:4
            boundaries1 = bwboundaries(roi1(curr_area).data.mask  );
     plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
            end

     if curr_phase==1
         text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'right', 'Rotation', 0);
     end
        end


        a3=nexttile
        imagesc( buf_images_all1(:,:,curr_phase)-fliplr(buf_images_all1(:,:,curr_phase)))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a3, ap.colormap(['KW' Color{workflow_idx}]));
        xlim([0 216])
        boundaries1 = bwboundaries(roi1(used_area).data.mask  );
     plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])


       a4=nexttile
        imagesc(use_t,[],buf3_roi_stim1_mean(4:10,:,used_area))
        yline(2.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a4, ap.colormap(['KW' Color{workflow_idx}]));
        xlabel('time (s)')
      title(title_area{curr_group})

      a5=  nexttile
        ylim(scale .* [-0.2, 1]);
        xlim([0.5 7.5])
        colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0],[0.5 0.5 0.5 ]}; % 定义颜色
        for curr_area=1:6
        ap.errorfill(1:7,buf3_roi_peak_mean(4:10,curr_stim,curr_area),buf3_roi_peak_error(4:10,curr_stim,curr_area) ,colors{curr_area},0.1,0.5);
        end
        % ap.errorfill(1:7,buf3_roi_peak_mean(4:10,curr_stim,curr_area+1),buf3_roi_peak_error(4:10,curr_stim,curr_area+1) ,colors{workflow_idx,2},0.1,0.5);
        xline(2.5);
        xticks([1.5 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签

        % selectivity
        a6=nexttile
        % plot_peak_mean= mean(buf3_roi_peak_mean(9:10,:,curr_area),1)- mean(buf3_roi_peak_mean(1:3,:,curr_area),1);
        % plot_peak_error=mean(buf3_roi_peak_error(9:10,:,curr_area),1)- mean(buf3_roi_peak_error(1:3,:,curr_area),1);
        % 
        
        plot_peak_mean= mean(buf3_roi_peak_mean(9:10,:,used_area),1);
        plot_peak_error=mean(buf3_roi_peak_error(9:10,:,used_area),1);

      
        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx*2-1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [-0.2, 1 ]);
        ylabel('df/f')
        xlabel('stim types')
        % 
        % figure;
        % 
        % for i=1:4
        %     buffer_mean= buf3_roi_peak_mean(:,:,i);
        %     nexttile
        %     plot(buffer_mean)
        % end




       clearvars('-except',main_preload_vars{:});

    
end
end
sgtitle('passive kernels in stage 1')

 saveas(gcf,[Path 'figures\summary\figures\figure 2_passive_stage1'], 'jpg');
%% draw  figure  passive stage 1
    title_area={'pl-mPFC','pr-mPFC','al-mPFC','ar-mPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'};
passive_data=struct;
passive_data.images=cell(2,1);
passive_data.roi_stim=cell(2,1);
passive_data.roi_stim_mean=cell(2,1);
passive_data.roi_stim_error=cell(2,1);


figure('Position', [50 50 1200 400]);
t = tiledlayout(2, 7, 'TileSpacing', 'compact', 'Padding', 'compact');
xlabel_all={'L','C','R';'4k','8k','12k'};

for curr_group=1:2
  for   workflow_idx =curr_group


       main_preload_vars = who;


        used_area=workflow_idx*2-1;
       curr_stim=4-workflow_idx;

        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part_filter{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end


        x=buf3_roi{curr_roi}{1}

        scale=0.0002;
        Color={'B','R'};
        %

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
        
        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
        buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

        buf_images_all1=permute(nanmean(buf_images_all_filter{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,4),4),[1 2 5 3 4]);

      
            a1=nexttile
            passive_data.images{curr_group}=buf_images_all1;
            imagesc(buf_images_all1)
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(a1, ap.colormap(['KW' Color{workflow_idx}]));
            for curr_area=1:4
            boundaries1 = bwboundaries(roi1(curr_area).data.mask  );
     plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
            end


       


for curr_area=[12 8 5 1 3]
       a4=nexttile
       passive_data.roi_stim{curr_group}{curr_area}=buf3_roi_stim1_mean(4:10,:,curr_area);

        imagesc(use_t,[],buf3_roi_stim1_mean(4:10,:,curr_area))
        yline(2.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a4, ap.colormap(['KW' Color{workflow_idx}]));
        xlabel('time (s)')
      title(title_area{curr_area})
  end

      a5=  nexttile
        ylim(scale .* [-0.2, 1]);
        xlim([0.5 7.5])
        colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0],[0.5 0.5 0.5 ],[0 0 0],[0 0 0]}; % 定义颜色
        for curr_area=[12 8 5 1 3]
passive_data.roi_stim_mean{curr_group}{curr_area}=buf3_roi_peak_mean(4:10,curr_stim,curr_area);
passive_data.roi_stim_error{curr_group}{curr_area}  =buf3_roi_peak_error(4:10,curr_stim,curr_area)


        ap.errorfill(1:7,buf3_roi_peak_mean(4:10,curr_stim,curr_area),buf3_roi_peak_error(4:10,curr_stim,curr_area) ,colors{1},0.1,0.5);
        end
        % ap.errorfill(1:7,buf3_roi_peak_mean(4:10,curr_stim,curr_area+1),buf3_roi_peak_error(4:10,curr_stim,curr_area+1) ,colors{workflow_idx,2},0.1,0.5);
        xline(2.5);
        xticks([1.5 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签

     

       clearvars('-except',main_preload_vars{:});

    
end
end
sgtitle('passive kernels in stage 1')


%% sequenced activity
passive_name={'visual','auditory'};
color_line={[1 0 0], [ 0 0 0],[0 0 1],[1 0 1]};
oder=[12 5 1 3;8 5 1 3];
Color={'R','B'};
for curr_stage=1:3
    if curr_stage==1
        image_idx=4; stim_idx=8:10;

    elseif curr_stage==2
        image_idx=7; stim_idx=15:17;
    else

        image_idx=8; stim_idx=18:20;

    end

    figure('Position', [50 50 600 800]);
    t = tiledlayout(4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');


    for curr_group=1:2


        for workflow_idx =1:2
            preload_vars=who;

            curr_area=workflow_idx*2-1;
            curr_stim=4-workflow_idx;

            for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

                buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
                for curr_roi= 1:length(roi1)
                    buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                    buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                    buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
                end
            end


            scale=0.0002;
            Color={'B','R'};
            %

            buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
            buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);

            buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
            buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
            buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

            buf_images_all1=permute(nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,image_idx),4),[1 2 5 3 4]);

            a1=nexttile
            imagesc(buf_images_all1)
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(a1, ap.colormap(['KW' Color{workflow_idx}] ));
            title(passive_name{workflow_idx})
            curr_line=0;
            for i=oder(workflow_idx,:)
                boundaries1 = bwboundaries(roi1(i).data.mask  );
                            curr_line= curr_line+1;
                plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',color_line{curr_line})
            end

         text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'right', 'Rotation', 0);

            % buff_mean=normalize(permute(mean( buf3_roi_stim1_mean(6:8,:,:),1),[2 3 1]), 'range', [0 1]);
            buff_mean=permute(mean( buf3_roi_stim1_mean(stim_idx,:,:),1),[2 3 1]);

            nexttile
            hold on
            for ii=1:length(oder)
            plot(use_t,buff_mean(:,oder(workflow_idx,ii)),'Color',color_line{ii},'LineWidth',2)
            end
            % ylim([-0.5 3])
                 ylim(scale*[-0.7 2])

            xlim([-0.1 0.4])

            axis off
            %
            % % 获取坐标轴范围
            % xlim_vals = xlim;
            % ylim_vals = ylim;
            % scale_lenx = (xlim_vals(2) - xlim_vals(1)) * 0.1; % 标尺长度 10%
            % scale_leny =0.5; % 标尺长度 10%
            %
            % % 右下角标尺位置
            % x0 = xlim_vals(2) - scale_lenx * 1.5;
            % y0 = ylim_vals(1) + scale_lenx * 0.5;
            %
            % % 画标尺
            % line([x0, x0 + scale_lenx], [y0, y0], 'Color', 'k', 'LineWidth', 2); % X 标尺
            % line([x0+ scale_lenx, x0+ scale_lenx], [y0, y0 + scale_leny], 'Color', 'k', 'LineWidth', 2); % Y 标尺
            %
            % % 标注
            % text(x0 + scale_lenx / 2, y0 - 4*scale_lenx , '100 ms', 'HorizontalAlignment', 'center');
            % text(x0 + scale_lenx*4 , y0 + scale_leny / 2, '0.5 norm', 'HorizontalAlignment', 'right');
            %
            %     xlabel('time (s)')
            %     % xline(0);xline(0.05);xline(0.08)
            %     name={'V1','p-mPFC','a-mPFC';'Auditory Cortex','PPC','a-mPFC'};
            %     legend(name(curr_group,:),'Location','eastoutside')
            %


            clearvars('-except',preload_vars{:});

        end


    end



    sgtitle(['passive kernels in stage ' num2str(curr_stage)])

    saveas(gcf,[Path 'figures\summary\figures\figure 2_sequence passive kernels in stage ' num2str(curr_stage)], 'jpg');
end




%% draw  figure  passive stage 2


figure('Position', [50 50 1200 800]);
t = tiledlayout(4, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
xlabel_all={'L','C','R';'4k','8k','12k'}

for curr_group=1:2
  for   workflow_idx = 1:2;

          % clear   buf1 buf3_roi buf3_roi_peak buf3_roi_stim buf3_roi_stim1 buf3_roi_stim1_mean buf3_roi_peak1 buf3_roi_peak_mean buf3_roi_peak_error

       main_preload_vars = who;


        used_area=workflow_idx*2-1;
       curr_stim=4-workflow_idx;
% curr_stim=1:3
        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end


        scale=0.0002;
        Color={'B','R'};
        %

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
        
        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
        buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

        buf_images_all1=permute(nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,[5 7]),4),[1 2 5 3 4]);

        for curr_phase=1:2
            a1=nexttile

            imagesc(buf_images_all1(:,:,curr_phase))
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(a1, ap.colormap(['KW' Color{workflow_idx}]));
            title(title_images{curr_phase})
            boundaries1 = bwboundaries(roi1(used_area).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])

            if curr_phase==1
                text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'right', 'Rotation', 0);
            end
        end


        a3=nexttile


        % hold on
        % imagesc( buf_images_all1(:,:,curr_phase))

        imagesc( buf_images_all1(:,:,curr_phase)-fliplr(buf_images_all1(:,:,curr_phase)))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a3, ap.colormap(['KW' Color{workflow_idx}]));
        xlim([0 216])
        % curr_area=13
        boundaries1 = bwboundaries(roi1(used_area).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])


       a4=nexttile
        imagesc(use_t,[],buf3_roi_stim1_mean(11:17,:,used_area))
        yline(2.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a4, ap.colormap(['KW' Color{workflow_idx}]));
        xlabel('time (s)')
      title(title_area{curr_group})

      a5=  nexttile
        ylim(scale .* [-0.2, 1]);
        xlim([0.5 7.5])
     
       colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5]}; % 定义颜色
        for curr_area=1:4
        ap.errorfill(1:7,buf3_roi_peak_mean(11:17,curr_stim,curr_area),buf3_roi_peak_error(4:10,curr_stim,curr_area) ,colors{curr_area},0.1,0.5);
        end
        xline(2.5);
        xticks([1.5 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签




        a6=nexttile
        % plot_peak_mean= mean(buf3_roi_peak_mean(16:17,:,curr_area),1)- mean(buf3_roi_peak_mean(1:3,:,curr_area),1);
        % plot_peak_error=mean(buf3_roi_peak_error(16:17,:,curr_area),1)- mean(buf3_roi_peak_error(1:3,:,curr_area),1);
        % 
        plot_peak_mean= mean(buf3_roi_peak_mean(16:17,:,used_area),1);
        plot_peak_error=mean(buf3_roi_peak_error(16:17,:,used_area),1);

      
        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx*2-1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [-0.2, 1 ]);
        ylabel('df/f')
        xlabel('stim types')


        
       


       clearvars('-except',main_preload_vars{:});

    
end
end
sgtitle('passive kernels in stage 2')
   saveas(gcf,[Path 'figures\summary\figures\figure 2_passive_stage2'], 'jpg');

%% selectivity across days

for curr_group=1:2
  for   workflow_idx = 1:2;

          % clear   buf1 buf3_roi buf3_roi_peak buf3_roi_stim buf3_roi_stim1 buf3_roi_stim1_mean buf3_roi_peak1 buf3_roi_peak_mean buf3_roi_peak_error

       main_preload_vars = who;


        used_area=workflow_idx*2-1;
       curr_stim=4-workflow_idx;
% curr_stim=1:3
        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end


        Color={'B','R'};
        %

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
        
        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
        buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

        buf_images_all1=permute(nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,[5 7]),4),[1 2 5 3 4]);


        figure
        colors={[0 0 1],[0 0 0],[1 0 0] }
        buffer_mean= buf3_roi_peak_mean(:,:,used_area);
        buffer_error= buf3_roi_peak_error(:,:,used_area);
        nexttile
        hold on
        for used_stim=1:3
            ap.errorfill(1:20,buffer_mean(:,used_stim),buffer_error(:,used_stim) ,colors{used_stim},0.1,0.5);
        end
        xticks([2 4.5 7 11.5 15 19 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xline(3.5)
        xline(5.5)
        xline(10.5)
        xline(12.5)
        xline(17.5)
        xticklabels({'naive','pre-1','post-1','pre-2','post-2','mix'}); % 设置对应的标签
        title(groups{curr_group})
        if workflow_idx==1
                    legend({'','left','','middle','','right'})
        else
        legend({'','4k','','8k','','12k'})
        end
        ylim([0 0.0002])
           savefig(gcf,[Path 'figures\summary\figures\selectivity in ' groups{curr_group} num2str(workflow_idx) '.fig']);

  end
end


  %% draw  figure  passive stage 3


figure('Position', [50 50 800 800]);
t = tiledlayout(4, 5, 'TileSpacing', 'compact', 'Padding', 'compact');
xlabel_all={'L','C','R';'4k','8k','12k'}

for curr_group=1:2
     for workflow_idx = 1:2;

          % clear   buf1 buf3_roi buf3_roi_peak buf3_roi_stim buf3_roi_stim1 buf3_roi_stim1_mean buf3_roi_peak1 buf3_roi_peak_mean buf3_roi_peak_error

       main_preload_vars = who;


        curr_area=workflow_idx*2-1;
       curr_stim=4-workflow_idx;

        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,curr_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end


        scale=0.0002;
        Color={'B','R'};
        %

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
        
        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak_mean=nanmean(cat(4,buf3_roi_peak1{:}),4);
        buf3_roi_peak_error=std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./length( data_part{curr_group}.(all_workflow{workflow_idx}));

        buf_images_all1=permute(nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,8),4),[1 2 5 3 4]);



        a1=nexttile
        imagesc(buf_images_all1)
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a1, ap.colormap(['KW' Color{workflow_idx}]));
        title('mixed')
        boundaries1 = bwboundaries(roi1(curr_area).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])

        text(-50, 150,  groups{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'right', 'Rotation', 0);


     a4=nexttile
    ap.errorfill(use_t,mean(buf3_roi_stim1_mean(18:20,:,curr_area),1),std(buf3_roi_stim1_mean(18:20,:,curr_area),0,1) ,colors{workflow_idx,1},0.1,0.5);
      xlim([use_t(1) use_t(end) ])
    xlabel('time (s)')
    ylabel('df/f')
    ylim(scale .* [-0.2, 1]);


        a3=nexttile
        imagesc( buf_images_all1-fliplr(buf_images_all1))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(a3, ap.colormap(['KW' Color{workflow_idx}]));
        xlim([0 216])
        % curr_area=13
        boundaries1 = bwboundaries(roi1(curr_area).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])


  
        a5=nexttile
    ap.errorfill(use_t,mean(buf3_roi_stim1_mean(18:20,:,curr_area)-buf3_roi_stim1_mean(18:20,:,curr_area+1),1),...
        std(buf3_roi_stim1_mean(18:20,:,curr_area)-buf3_roi_stim1_mean(18:20,:,curr_area+1),0,1) ,colors{workflow_idx,1},0.1,0.5);
        xlim([use_t(1) use_t(end) ])
    xlabel('time (s)')
    ylabel('df/f')
    ylim(scale .* [-0.2, 1]);


   

        a6=nexttile
      
        plot_peak_mean= mean(buf3_roi_peak_mean(18:20,:,curr_area),1);
        plot_peak_error=mean(buf3_roi_peak_error(18:20,:,curr_area),1);

      
        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx,1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [-0.2, 1 ]);
        ylabel('df/f')
        xlabel('stim types')

       clearvars('-except',main_preload_vars{:});

    
     end
end
sgtitle('passive kernels in stage 3')
    saveas(gcf,[Path 'figures\summary\figures\figure 2_passive_stage3'], 'jpg');
%%  cortical images of well trianed mice with selectivity and lateralization in the first task.
 scale=0.0002;

figure('Position', [50 50 800 400]);

t = tiledlayout(2, 6, 'TileSpacing', 'tight', 'Padding', 'compact');
% title_images={'naive','well trained'}
xlabel_all={'left','center','right';'4k Hz','8k Hz','12k Hz'}
title_area={'p-l-mPFC','a-l-mPFC'};

for curr_group=1:2
  for   workflow_idx =curr_group;
       main_preload_vars = who;
        used_area=workflow_idx*2-1;
       used_stim=4-workflow_idx;
        scale=0.0002;
        Color={'B','R'};
     
        % buf_images_all1=permute(nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,curr_stim,:,[1 4]),4),[1 2 5 3 4]);
        buf_images_all1=nanmean(buf_images_all{curr_group}.(all_workflow{workflow_idx})(:,:,:,:,4),4);
 
        
        for curr_animal=1:length( data_part{curr_group}.(all_workflow{workflow_idx}))

            buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_part{curr_group}.(all_workflow{workflow_idx}){curr_animal}, 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
                buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
                buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x(:,used_stim))', buf3_roi{curr_roi},'UniformOutput',false ));
            end
        end

        buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
        buf3_roi_stim2=cat(4,buf3_roi_stim1{:});

        buf3_roi_stim1_mean=permute(nanmean(buf3_roi_stim2([9:10],:,:,:),[1,4]),[2 3 1]);
        buf3_roi_stim1_error=permute(std(buf3_roi_stim2([9:10],:,:,:),0,[1,4],'omitmissing')/sqrt(size(buf3_roi_stim2,4)),[2 3 1]);


        buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
        buf3_roi_peak2=cat(4,buf3_roi_peak1{:});
        buf3_roi_peak_mean=permute(nanmean(buf3_roi_peak2(9:10,:,:,:),[1,4]),[2 3 1]);

        buf3_roi_peak_error=permute(std(buf3_roi_peak2(9:10,:,:,:),0,[1,4],'omitmissing')./sqrt(size(buf3_roi_peak2,4)),[2 3 1]);


        for curr_stim=1:3
            a1=nexttile
            imagesc(buf_images_all1(:,:,curr_stim))
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [ 0, 1]);
            colormap(a1, ap.colormap(['W' Color{workflow_idx}]));
             title(xlabel_all{workflow_idx,curr_stim})
            
            for curr_area=used_area
                boundaries1 = bwboundaries(roi1(curr_area).data.mask  );
                plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
            end

            if curr_stim==3
             cb = colorbar(a1,'southoutside'); % 在下方添加 colorbar
            end
        end 
        nexttile
        plot_peak_mean= buf3_roi_peak_mean(:,used_area);
        plot_peak_error=buf3_roi_peak_error(:,used_area);

              colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0],[0.5 0.5 0.5 ]}; % 定义颜色

        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx*2-1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [-0, 1.2 ]);
        title(title_area{curr_group})
        ylabel('ΔF/F')
        xlabel('stim types')
        box off

        
        a3=nexttile
        
        imagesc( buf_images_all1(:,:,used_stim)-fliplr(buf_images_all1(:,:,used_stim)))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [0, 1]);
        colormap(a3, ap.colormap(['WK']));
        xlim([0 216])
        title('asymmetry ')
        boundaries1 = bwboundaries(roi1(used_area).data.mask  );
        plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[0 0 0])
              colorbar('southoutside'); % 在下方添加 colorbar

     
     
     nexttile
     for curr_area=1:4
       
        ap.errorfill(use_t,buf3_roi_stim1_mean(:,curr_area), buf3_roi_stim1_error(:,curr_area) ,colors{curr_area},0.1,0.5);
     end
        xlim([use_t(1) use_t(end) ])
        xlabel('time (s)')
        ylabel('ΔF/F')
        ylim(scale .* [-0.2, 1]);
        lgd=legend({'','pl-mPFC','','pr-mPFC','','al-mPFC','','ar-mPFC'},'Location','northeastoutside','Box','off')
        % 获取 legend 的位置
        legendPos = lgd.Position;

        % 检查是否与数据线重叠，如果重叠，则调整位置
        if legendPos(1) > 0.7  % 如果 legend 的 x 位置靠近图形边缘
            lgd.Position = [legendPos(1) + 0.02, legendPos(2), legendPos(3), legendPos(4)]; % 向右移动 legend
        end

        clearvars('-except',main_preload_vars{:});


  end
end

 saveas(gcf,[Path 'figures\summary\figures\figure 2_cortical images of selectivity in trianed mice in passive'], 'jpg');

%% images across time
 scale=0.0001;
image_passive_time_2=cell(2,2);
for curr_group=select_group
    preload_vars=who;
    image_time_V=cat(2,data_part_filter{curr_group}.lcr_passive{:})';
    image_time_V_1=arrayfun(@(i) nanmean(cat(5,image_time_V{:,i}),5) ,1:size(image_time_V,2),'UniformOutput',false );
    image_time_A=cat(2,data_part_filter{curr_group}.hml_passive_audio{:})';
    image_time_A_1=arrayfun(@(i) nanmean(cat(5,image_time_A{:,i}),5) ,1:size(image_time_A,2),'UniformOutput',false );
    image_time_all=cellfun(@(x,y) cat(4,x,y), image_time_V_1,image_time_A_1,'UniformOutput',false );
    for curr_stage=1:2

        if curr_stage==1
            image_passive_time_2{curr_group,curr_stage}=nanmean(cat(5,image_time_all{8:10}),5);
        else
            image_passive_time_2{curr_group,curr_stage}=nanmean(cat(5,image_time_all{15:17}),5);
        end

        figure('Position', [50 50 800 800]);
        t1 = tiledlayout(6, length(find(t_kernels>=0& t_kernels<0.3)), 'TileSpacing', 'none', 'Padding', 'none');
        for curr_stim=1:6
            for curr_time =find(t_kernels>=0& t_kernels<0.3)
                
                a_1=nexttile
                buff_image=image_passive_time_2{curr_group,curr_stage}(:,:,curr_time,curr_stim);
          
                imagesc(buff_image)
                axis image off;
                ap.wf_draw('ccf', 'black');
                clim(scale .* [-1, 1]);
                if curr_stim<=3
                colormap( a_1, ap.colormap('KWB'  ));
                else
                 colormap( a_1, ap.colormap('KWR'  ));

                end
                if curr_stim==1
                title(num2str(t_kernels(curr_time)))
                end
            end
        end
              colorbar('southoutside'); % 在下方添加 colorbar
        sgtitle([groups{curr_group} ' stage ' num2str(curr_stage) ])

         saveas(gcf,[Path 'figures\summary\figures\figure 2_passive_kernels_across_time ' groups{curr_group} 'stage ' num2str(curr_stage) ], 'jpg');


    end
    
    clearvars('-except',preload_vars{:});


end


%%  task vs passive
 scale=0.0002;
 for curr_stage=1:2

for curr_group=select_group

figure('Position', [50 50 800 400]);
t1 = tiledlayout(3, length(find(t_kernels>=0& t_kernels<0.3)), 'TileSpacing', 'none', 'Padding', 'none');

for curr_time =find(t_kernels>=0& t_kernels<0.3)


    % imagesc(image_task_time_2{curr_group,curr_stage}(:,:,curr_time)-image_passive_time_2{curr_group,curr_stage}(:,:,curr_time,curr_stim))
        a_1=nexttile
      imagesc(image_task_time_2{curr_group,curr_stage}(:,:,curr_time))
     %        a_1=nexttile
     % imagesc(image_passive_time_2{curr_group,curr_stage}(:,:,curr_time,curr_stim))

    axis image off;

    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);

    if curr_group==1
        colormap( a_1, ap.colormap('KWB'  ));
        
    else
        colormap( a_1, ap.colormap('KWR'  ));

    end


    title(num2str(t_kernels(curr_time)))

end

for curr_time =find(t_kernels>=0& t_kernels<0.3)
   if curr_stage==1
    curr_stim=2*curr_group+1;
else
        curr_stim=7-2*curr_group;
end
       
            a_1=nexttile
     imagesc(image_passive_time_2{curr_group,curr_stage}(:,:,curr_time,curr_stim))

    axis image off;

    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);

    if curr_group==1
        colormap( a_1, ap.colormap('KWB'  ));
        
    else
        colormap( a_1, ap.colormap('KWR'  ));

    end


    title(num2str(t_kernels(curr_time)))

end

for curr_time =find(t_kernels>=0& t_kernels<0.3)
    a_1=nexttile
    if curr_stage==1
    curr_stim=2*curr_group+1;
else
        curr_stim=7-2*curr_group;
end
    imagesc(image_task_time_2{curr_group,curr_stage}(:,:,curr_time)-image_passive_time_2{curr_group,curr_stage}(:,:,curr_time,curr_stim))
  
    axis image off;

    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);

    if curr_group==1
        colormap( a_1, ap.colormap('KWB'  ));
        
    else
        colormap( a_1, ap.colormap('KWR'  ));

    end


    title(num2str(t_kernels(curr_time)))

end

sgtitle([groups{curr_group} ' stage ' num2str(curr_stage) ])
saveas(gcf,[Path 'figures\summary\figures\figure 2_passive_vs_task_across_time ' groups{curr_group} 'stage ' num2str(curr_stage) ], 'jpg');

end
 end

%%

figure('Position', [50 50 1200 1000]);
t = tiledlayout(6, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
xlabel_all={'L','C','R';'4k','8k','12k'};

for curr_group=1:2
    main_preload_vars = who;
    scale=0.00012;
    Color={'B','R'};

   
    a3=nexttile
    imagesc(task_data.images{curr_group})
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
    colormap(a3, ap.colormap(['KW' Color{curr_group}]));
     
    
    for curr_area=[12 8 5 1 3]
        a4=nexttile

        imagesc(use_t,[], task_data.roi_stim{curr_group}{curr_area})
        yline(2.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a4, ap.colormap(['KW' Color{curr_group}]));
        xlabel('time (s)')
        title(title_area{curr_area})
    end



 a1=nexttile
    imagesc(passive_data.images{curr_group})
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
    colormap(a1, ap.colormap(['KW' Color{curr_group}]));

    for curr_area=[12 8 5 1 3]
        a2=nexttile

        imagesc(use_t,[], passive_data.roi_stim{curr_group}{curr_area})
        yline(2.5);
        yticks([1.5  5 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title_images); % 设置对应的标签
        clim(scale .* [-1, 1]);
        colormap(a2, ap.colormap(['KW' Color{workflow_idx}]));
        xlabel('time (s)')
        title(title_area{curr_area})
    end


ax = nexttile; % 选择第二个子图
ax.Visible = 'off'; % 隐藏该子图

        colors = { [1 0 0],[0 0 0]}; % 定义颜色
        for curr_area=[12 8 5 1 3]
          a5=  nexttile
          yyaxis left   % 选择左 y 轴
          if curr_area==12
              ylim(scale .* [-0.1, 5]);

          else

              ylim(scale .* [-0.1, 1]);
          end
        ap.errorfill(1:7,passive_data.roi_stim_mean{curr_group}{curr_area},...
            passive_data.roi_stim_error{curr_group}{curr_area}  ,colors{2},0.1,0.5);
        yyaxis right  % 选择左 y 轴

        ap.errorfill(1:7,task_data.roi_stim_mean{curr_group}{curr_area},...
           task_data.roi_stim_error{curr_group}{curr_area}  ,colors{1},0.1,0.5);

                if curr_area==12
                    ylim(scale .* [-0.1, 5]);

                else

                    ylim(scale .* [-0.1, 2]);
                end
        xlim([0.5 7.5])

        % ap.errorfill(1:7,buf3_roi_peak_mean(4:10,curr_stim,curr_area+1),buf3_roi_peak_error(4:10,curr_stim,curr_area+1) ,colors{workflow_idx,2},0.1,0.5);
        xline(2.5);
        xticks([1.5 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title_images); % 设置对应的标签
        end
     

       clearvars('-except',main_preload_vars{:});

    
end

sgtitle('task vs passive')
 saveas(gcf,[Path 'figures\summary\figures\figure 2_task vs passive'], 'jpg');


