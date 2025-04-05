
clear all
clc
% Path = 'D:\Da_Song\Data_analysis\mice\process\processed_data_v2\';
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
 % animals={'DS028'}
animals_type=[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2];

% animals_group = [1 1 1 1 1 1 1 2 2 3 3 3 4 4 4 4 4];

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

passive_boundary=0.3;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_task=find(t_task>0&t_task<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);


all_animal=cell(length(animals),1);
all_animal_single_day=cell(length(animals),1);

all_animal_react=cell(length(animals),1);
all_animal_react_single_day=cell(length(animals),1);
all_animal_zero_if=cell(length(animals),1);

% 选择
% use raw data or kernels,
used_data=1;  %  raw data:1; kernels:2;
used_data_name={'raw data','kernels'};


if used_data==1 
use_t=t_passive;
elseif used_data==2
 use_t= t_kernels;
end

%%

for curr_animal_idx=1:length(animals)
    main_preload_vars = who;

    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);
    raw_data_lcr1=load([Path '\mat_data\lcr_passive\' animal '_lcr_passive.mat']);
    raw_data_lcr2=load([Path '\mat_data\lcr_passive\' animal '_lcr_passive_single_trial.mat']);
    raw_data_hml1=load([Path '\mat_data\hml_passive_audio\' animal '_hml_passive_audio.mat']);
    raw_data_hml2=load([Path '\mat_data\hml_passive_audio\' animal '_hml_passive_audio_single_trial.mat']);

use_period=find(use_t>0&use_t<passive_boundary);

    % raw_data_hml=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);
    fprintf('%s\n', ['File loading completed of  ' animal ]);

    
    %使用所有trial进行分析
    if used_data==1
        idx_lcr= cellfun(@(x) ~isempty(x),raw_data_lcr2.wf_px_all,'UniformOutput',true);
        raw_data_lcr2.imaging_all_trial(idx_lcr) = cellfun(@(a,b) permute(splitapply(@(x) nanmean(x,1),permute(a,[3,1,2]),findgroups(b)),[2,3,1]),raw_data_lcr2.wf_px_all(idx_lcr),raw_data_lcr2.trial_type(idx_lcr),'UniformOutput',false);

        idx_hml= cellfun(@(x) ~isempty(x),raw_data_hml2.wf_px_all,'UniformOutput',true);
        raw_data_hml2.imaging_all_trial(idx_hml) =  cellfun(@(a,b) permute(splitapply(@(x) nanmean(x,1),permute(a,[3,1,2]),findgroups(b)),[2,3,1]),raw_data_hml2.wf_px_all(idx_hml),raw_data_hml2.trial_type(idx_hml),'UniformOutput',false) ;
    elseif  used_data==2
                idx_lcr= cellfun(@(x) ~isempty(x),raw_data_lcr1.wf_px_kernels,'UniformOutput',true);

        raw_data_lcr2.imaging_all_trial(idx_lcr) = cellfun(@(x)  x{1},raw_data_lcr1.wf_px_kernels(idx_lcr),'UniformOutput',false);
                idx_hml= cellfun(@(x) ~isempty(x),raw_data_hml1.wf_px_kernels,'UniformOutput',true);

        raw_data_hml2.imaging_all_trial(idx_hml) = cellfun(@(x)  x{1},raw_data_hml1.wf_px_kernels(idx_hml),'UniformOutput',false);
    end

   learned_buff= cellfun(@(x,y)   y<0.05, num2cell(raw_data_task.rxn_med),raw_data_task.rxn_stat_p,'UniformOutput',false);
 raw_data_task.learned_day=cellfun(@(x) x(1)  ,learned_buff,'UniformOutput',true);

    if animals_type(curr_animal_idx) == 1
        order = [0, 1, 2, 3];
        stage_type={'baseline','visual','auditory','mixed'};
    elseif animals_type(curr_animal_idx) == 2
        order = [0, 2, 1, 3];
        stage_type={'baseline','auditory','visual','mixed'};
    else
        error('Unsupported value for variable. Must be 1 or 2.');
    end

    all_imaging=cell(2,4);
    all_imaging_single_day=cell(2,4);

    all_react=cell(2,4);
    all_react_single_day=cell(2,4);
    zero_if=cell(2,4);
    idxx=0;
    for curr_ord=order
        idxx=idxx+1;


        if curr_ord==0
            learned=0;
        else learned=1;
        end
        if curr_ord==0 |curr_ord==3
            numbers=3;
        else numbers=5;
        end

        if curr_ord==0
            imagings_lcr= raw_data_lcr2.imaging_all_trial(find(raw_data_lcr1.workflow_type==curr_ord,numbers,"first"));
            imagings_hml= raw_data_hml2.imaging_all_trial(find(raw_data_hml1.workflow_type==curr_ord,numbers,'first'));
            task_s2m=nan;
            task_s2r=nan;
        else

            task_s2m=raw_data_task.stim2move_med(find(raw_data_task.workflow_type==curr_ord&raw_data_task.learned_day==learned,numbers,"last"));
            if isempty(task_s2m)
            task_s2m=raw_data_task.stim2move_med(find(raw_data_task.workflow_type==curr_ord,numbers,"last"));
            end

            task_s2r=raw_data_task.rxn_med(find(raw_data_task.workflow_type==curr_ord&raw_data_task.learned_day==learned,numbers,"last"));
            if isempty(task_s2r)
            task_s2r=raw_data_task.rxn_med(find(raw_data_task.workflow_type==curr_ord,numbers,"last"));
            end

            imagings_lcr= raw_data_lcr2.imaging_all_trial(find(raw_data_lcr1.workflow_type==curr_ord&raw_data_lcr1.learned_day'==learned,numbers,"last"));
            if isempty(imagings_lcr)
                imagings_lcr = raw_data_lcr2.imaging_all_trial(find(raw_data_lcr1.workflow_type == curr_ord, numbers,'last'));
            end

            imagings_hml= raw_data_hml2.imaging_all_trial(find(raw_data_hml1.workflow_type==curr_ord&raw_data_hml1.learned_day'==learned,numbers,'last'));
            if isempty(imagings_hml)
                imagings_hml = raw_data_hml2.imaging_all_trial(find(raw_data_hml1.workflow_type == curr_ord, numbers,'last'));
            end
        end

        
        all_react_single_day{1,idxx}=cell2mat(task_s2m);
        all_react_single_day{2,idxx}=cell2mat(task_s2r);

        task_s2m_mean=nanmean(cell2mat(task_s2m));
        task_s2r_mean=nanmean(cell2mat(task_s2r));
        all_react{1,idxx}=task_s2m_mean;
        all_react{2,idxx}=task_s2r_mean;



        all_imaging_single_day{1,idxx}= cellfun(@(x) x(:,:,3),imagings_lcr,'UniformOutput',false);

        imagings_lcr_mean=mean(cat(4,imagings_lcr{:}),4);

        if ~isempty(imagings_lcr_mean)
            all_imaging{1,idxx}=imagings_lcr_mean(:,:,3);
        else all_imaging{1,idxx}=zeros(2000,53);
            zero_if{1,idxx}=1;
        end



        all_imaging_single_day{2,idxx}= cellfun(@(x) x(:,:,2), imagings_hml,'UniformOutput',false);

        imagings_hml_mean=mean(cat(4,imagings_hml{:}),4);
        if ~isempty(imagings_hml_mean)
            all_imaging{2,idxx}=imagings_hml_mean(:,:,2);
        else all_imaging{2,idxx}=zeros(2000,53);
            zero_if{2,idxx}=1;
        end


    end
    
    all_animal_zero_if{curr_animal_idx}=zero_if;
    all_animal_react{curr_animal_idx}=all_react;
    all_animal_react_single_day{curr_animal_idx}=all_react_single_day;

    all_imaging_line=reshape(all_imaging',1,[]);
    all_animal{curr_animal_idx}=all_imaging_line;

    all_animal_single_day{curr_animal_idx}=all_imaging_single_day;
    % all_animal_single_day{curr_animal_idx}=cellfun(@(x) [x{:}], num2cell(all_imaging_single_day, 2), 'UniformOutput', false);

    %% imaging in 4 stages from single mouse
    all_imaging_mean=cellfun(@(x) max(x(:,:,use_period),[],3), cellfun(@(c) plab.wf.svd2px(U_master,c), all_imaging_line,'UniformOutput',false),'UniformOutput',false);

    figure('Position',[50 50 800 400]);
    scale_all=0.005;
    % cellfun(@(x) imagesc(x),all_imaging_mean,'UniformOutput',false);
    for ss=1:8
        nexttile

        imagesc(all_imaging_mean{ss})
        if ss<5
            title(stage_type{ss})
        end
        axis image off;
        ap.wf_draw('ccf', 'black');
        colormap( ap.colormap('WG'));
        clim(scale_all .* [0, 1]);
    end
    sgtitle(animal)
    saveas(gcf,[Path 'figures\use_all_trials\single mouse\image from 4 stages in visual and auditory from ' animal], 'jpg');


    %
    %
    % % 做视频 每只小鼠
    % close all
    % % 创建一个 VideoWriter 对象，指定文件名和格式
    % videoFilename = ['figures\use_all_trials\all_trials_visual_auditory_passive_' animal '.avi'];
    %
    % % fullfile(Path,videoFilename)
    % video = VideoWriter(fullfile(Path,videoFilename), 'Uncompressed AVI');  % 可以根据需要选择不同的格式
    % video.FrameRate = 10;  % 设置帧率
    % % 打开 VideoWriter 对象以进行写入
    % open(video);
    % % 读取图像序列并写入视频
    % for curr_frame = 1:size(t_passive,2)
    %     % 标签数组，包含每个阶段的标签
    %     labels = {'visual stage 0', 'visual stage 1', 'visual stage 2','visual stage 3', ...
    %         'auditory stage 0', 'auditory stage 1', 'auditory stage 2', 'auditory stage 4'};
    %
    %
    %     % 处理图像，插入标签
    %     image_with_labels = cell(1,8);  % 用于存储处理后的带标签的图像
    %     labelHeight = 50;  % 标签区域高度
    %
    %     for i = 1:8
    %         % 当前图像
    %         imagesc(all_imaging_line{i}(:,:,curr_frame));
    %         axis image off;
    %         ap.wf_draw('ccf','black');
    %         clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    %
    %         % 获取当前帧的图像数据
    %         frame = getframe(gca);
    %         img = frame.cdata;
    %
    %         % 获取图像尺寸
    %         [imgHeight, imgWidth, ~] = size(img);
    %
    %         % 创建一个新的图像，在上方留出空间放置标签
    %         img_with_label = uint8(255 * ones(imgHeight + labelHeight, imgWidth, 3));  % 白色背景
    %         img_with_label(labelHeight+1:end, :, :) = img;  % 将原图像放置在下方
    %
    %         % 在空白区域插入相应的标签
    %         img_with_label = insertText(img_with_label, [imgWidth/2, labelHeight/2], labels{i}, 'FontSize', 18, ...
    %             'BoxColor', 'white', 'BoxOpacity', 1, 'TextColor', 'black', 'AnchorPoint', 'Center');
    %         % 保存处理后的图像
    %         image_with_labels{i} = img_with_label;
    %     end
    %
    %     % 将视觉和听觉图像拼接成 2 行 3 列的矩阵图像
    %
    %     image_all = [image_with_labels{1}, image_with_labels{2}, image_with_labels{3}, image_with_labels{4}; ...
    %         image_with_labels{5}, image_with_labels{6}, image_with_labels{7}, image_with_labels{8}];
    %
    %     % 添加标题并保存到视频中
    %     [height, width, ~] = size(image_all);
    %     titleHeight = 30;
    %     newImage = uint8(zeros(height + titleHeight, width, 3));
    %     newImage(titleHeight+1:end, :, :) = image_all;
    %     newImage(1:titleHeight, :, :) = 255;
    %
    %     position = [width/2, titleHeight/2];
    %     titleText = ['Averaged mice group' num2str(animals_group(curr_animal_idx)) ':' num2str(t_passive(curr_frame)) 's'];
    %     newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
    %         'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
    %         'AnchorPoint', 'Center');
    %
    %     writeVideo(video, newImageWithText);
    %     close all
    %
    % end
    %
    % % 关闭 VideoWriter 对象
    % close(video);
    % disp('视频保存完成。');



    clearvars('-except',main_preload_vars{:});

end


%% Draw figures of imaging and mPFC across day

% choose groups
animals_group = [1 1 1 1 1 5 5 2 2 3 3 3 4 4 4 4 4];
for curr_group=1:2
if curr_group==1
selected_group=1;
else selected_group=4;
end

group_names={'V-A','A-V'};
colors={[0 0 1],[1 0 0]};
if selected_group == 1
    stage_type={'naive','visual','auditory','mixed'};
    group_name=group_names{1};
    curr_color=colors{1};
elseif selected_group == 4
    stage_type={'naive','auditory','visual','mixed'};
    group_name=group_names{2};
    curr_color=colors{2};

else
    error('Unsupported value for variable. Must be 1 or 2.');
end

passive_boundary=0.15;

use_period=find(use_t>0&use_t<passive_boundary);



allElements = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),allElements,'UniformOutput',true);
avgResults = arrayfun(@(col) ...
    mean(cat(4, allElements{nonZeroMask_all(:, col), col}), 4), ...
    1:size(allElements, 2), 'UniformOutput', false);
avgResults_svd=cellfun(@(c) plab.wf.svd2px(U_master,c),avgResults,'UniformOutput',false);
all_animals_mean=cellfun(@(x) max(x(:,:,use_period),[],3),avgResults_svd,'UniformOutput',false);

figure('Position',[50 50 800 1200]);
t = tiledlayout(4,4);

scale_all=0.004;
for ss=1:8
    nexttile([1 1])
    imagesc(all_animals_mean{ss});
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(scale_all .* [0, 1]);
    hold on

     if ss<5
        title(stage_type{ss})
    end


    if ss==1
        text(-50, 220, 'visual passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');
    elseif ss==5
        text(-50, 220, 'auditory passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');
    end

end

% boundaries = bwboundaries(roi1(10).data.mask  );
%     plot(boundaries{1, 1}(:, 2), boundaries{1, 1}(:, 1));
% boundaries2 = bwboundaries(roi1(3).data.mask  );
%     plot(boundaries2{1, 1}(:, 2), boundaries2{1, 1}(:, 1));

sgtitle([group_name ' 0-' num2str(passive_boundary) 's'])
h = colorbar;
h.Orientation = 'vertical';
h.Position = [0.92, 0.62, 0.015, 0.2];  % 调整 colorbar 位置



% ROI across day
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

all_animal_single_day_svd=cellfun(@(x) cellfun(@(y) cellfun(@(c) plab.wf.svd2px(U_master,c),y,'UniformOutput',false),x,'UniformOutput',false),all_animal_single_day(animals_group==selected_group),'UniformOutput',false);
buf1= cellfun(@(x) cellfun(@(y) cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)),y,'UniformOutput',false),x,'UniformOutput',false) , all_animal_single_day_svd, 'UniformOutput', false);
buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);

% 假设 A 是一个 6x1 的 cell 数组，其中每个元素是 2x4 的 cell 矩阵
% 每个 A{i}{j, k} 是一个 50xN 的矩阵;
A=buf2; example=[3 5 5 3 3 5 5 3]
for curr_ord=1:length(A)
    AA=reshape(A{curr_ord}',1,[]);
    colSizes =  cellfun(@(y) size(y, 2),  AA, 'UniformOutput', true);
    for s=1:length(AA)
        if length(AA{s})<example(s)
            AA{s}(length(AA{s})+1:example(s))=repmat({single(nan(length(use_t), 1))}, 1, (example(s)-length(AA{s})));
        end
    end
    B{curr_ord}=reshape(AA,4,2)';
end

BB_lcr=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x(1,:),'UniformOutput',false)),B,'UniformOutput',false);
BB_hml=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x(2,:),'UniformOutput',false)),B,'UniformOutput',false);

% figure('Position',[50 50 1000 500]);
a1=nexttile([1 2])

imagesc(use_t,[],mean(cat(3,BB_lcr{:}),3,'omitnan')')
ylim([0.5 16.5])
clim(0.003.*[-1,1]); colormap(a1,ap.colormap('PWG'));
hold on; 
xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
yline(3.5);yline(8.5);yline(13.5);
title('visual passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签



a2=nexttile([1 2])
% subplot(2,2,2)
imagesc(use_t,[],mean(cat(3,BB_hml{:}),3,'omitnan')')
ylim([0.5 16.5])
clim(0.003.*[-1,1]); colormap(a2,ap.colormap('PWG'));
hold on; xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
yline(3.5);yline(8.5);yline(13.5);
title('auditory passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签
box off
colorbar('eastoutside')




% plot mPFC activity across day
nexttile([1 2])
% subplot(2,2,3)
lcr_all=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_lcr,'UniformOutput',false)')
lcr_mean_line=mean(lcr_all,1,'omitnan');
lcr_sem_line=std(lcr_all,'omitnan')/sqrt(size(lcr_all,1));
hold on
ap.errorfill(1:3,lcr_mean_line(1:3), lcr_sem_line(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,lcr_mean_line(4:8), lcr_sem_line(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,lcr_mean_line(9:13), lcr_sem_line(9:13),curr_color,0.1,0.5);
 ap.errorfill(14:16,lcr_mean_line(14:16), lcr_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.001*[-0.5 3.5])
xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('df/f')


% plot mPFC activity across day
nexttile([1 2])
% subplot(2,2,4)
hml_all=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_hml,'UniformOutput',false)');
hml_mean_line=mean(hml_all,1,'omitnan');
hml_sem_line=std(hml_all,'omitnan')/sqrt(size(hml_all,1));
hold on
ap.errorfill(1:3,hml_mean_line(1:3), hml_sem_line(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,hml_mean_line(4:8), hml_sem_line(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,hml_mean_line(9:13), hml_sem_line(9:13),curr_color,0.1,0.5);
 ap.errorfill(14:16,hml_mean_line(14:16), hml_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.001*[-0.5 3.5])

xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('df/f')

task_average{curr_group}{1}=lcr_all;
    task_average{curr_group}{2}=hml_all;

if used_data==1 
saveas(gcf,[Path 'figures\summary\passive_raw\heatmap and plot mPFC activity in passive ' group_name ' 0-' num2str(1000*passive_boundary) 'ms in' used_data_name{used_data} ], 'jpg');
elseif used_data==2
saveas(gcf,[Path 'figures\summary\passive_kernels\heatmap and plot mPFC activity in passive ' group_name ' 0-' num2str(1000*passive_boundary) 'ms in' used_data_name{used_data} ], 'jpg');
end
% saveas(gcf,[Path 'figures\summary\heatmap and plot lmPFC activity in passive ' used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint}  ], 'jpg');

end

%% draw summary figure of mPFC activity
task_mean=cellfun(@(x) cellfun(@(y) mean(y,1,'omitnan'),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )
task_std=cellfun(@(x) cellfun(@(y) std(y,'omitnan')/sqrt(size(y,1)),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )

figure('Position',[200 200 700 300])
nexttile
   hold on
   ap.errorfill(1:3, task_mean{1}{1}(1:3),  task_std{1}{1}(1:3),colors{1},0.1,0.5);
   ap.errorfill(4:8, task_mean{1}{1}(4:8),  task_std{1}{1}(4:8),colors{1},0.1,0.5);
   ap.errorfill(9:13, task_mean{1}{1}(9:13),  task_std{1}{1}(9:13),colors{1},0.1,0.5);
   ap.errorfill(14:16, task_mean{1}{1}(14:16),  task_std{1}{1}(14:16),colors{1},0.1,0.5);

   ap.errorfill(1:3, task_mean{2}{1}(1:3),  task_std{2}{1}(1:3),colors{2},0.1,0.5);
   ap.errorfill(4:8, task_mean{2}{1}(9:13),  task_std{2}{1}(9:13),colors{2},0.1,0.5);
   ap.errorfill(9:13, task_mean{2}{1}(4:8),  task_std{2}{1}(4:8),colors{2},0.1,0.5);
   ap.errorfill(14:16, task_mean{2}{1}(14:16),  task_std{2}{1}(14:16),colors{2},0.1,0.5);

    ylim(0.001*[-0.1 4])
    xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels({'naive','visual','auditory','mixed'}); % 设置对应的标签
    ylabel('df/f change')
    title ('visual passive')

  
nexttile
   hold on
   ap.errorfill(1:3, task_mean{1}{2}(1:3),  task_std{1}{2}(1:3),colors{1},0.1,0.5);
   ap.errorfill(1:3, task_mean{2}{2}(1:3),  task_std{2}{2}(1:3),colors{2},0.1,0.5);

   ap.errorfill(4:8, task_mean{1}{2}(4:8),  task_std{1}{2}(4:8),colors{1},0.1,0.5);
   ap.errorfill(9:13, task_mean{1}{2}(9:13),  task_std{1}{2}(9:13),colors{1},0.1,0.5);
   ap.errorfill(14:16, task_mean{1}{2}(14:16),  task_std{1}{2}(14:16),colors{1},0.1,0.5);

   ap.errorfill(4:8, task_mean{2}{2}(9:13),  task_std{2}{2}(9:13),colors{2},0.1,0.5);
   ap.errorfill(9:13, task_mean{2}{2}(4:8),  task_std{2}{2}(4:8),colors{2},0.1,0.5);
   ap.errorfill(14:16, task_mean{2}{2}(14:16),  task_std{2}{2}(14:16),colors{2},0.1,0.5);

   ylim(0.001*[-0.1 4])
    xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签

    ylabel('df/f change')

    title ('auditory passive')
legend('','V-A group','','A-V group','Location','northeastoutside','Box','off'); 
sgtitle(['mPFC activity in passive task of ' used_data_name{used_data}])



% if used_data==1
%     saveas(gcf,[Path 'figures\summary\passive_raw\summary of mPFC in passive task in' used_data_name{used_data} ], 'jpg');
% elseif used_data==2
%     saveas(gcf,[Path 'figures\summary\passive_kernels\summary of mPFC in passive task in' used_data_name{used_data} ], 'jpg');
% end


%%
figure('Position',[200 200 700 300])
nexttile
hold on
mean1=[mean(task_mean{1}{1}(1:3)) mean(task_mean{1}{1}(4:8)) mean(task_mean{1}{1}(9:13)) mean(task_mean{1}{1}(14:16))];
error1=[ mean(task_std{1}{1}(1:3)) mean(task_std{1}{1}(4:8))  mean(task_std{1}{1}(9:13)) mean(task_std{1}{1}(14:16))];

mean2=[ mean(task_mean{2}{1}(1:3)) mean(task_mean{2}{1}(9:13))  mean(task_mean{2}{1}(4:8)) mean(task_mean{2}{1}(14:16))];
error2=[  mean(task_std{2}{1}(1:3)) mean(task_std{2}{1}(9:13))   mean(task_std{2}{1}(4:8)) mean(task_std{2}{1}(14:16))];

errorbar(1:4, mean1, error1,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean2, error2,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])

ylim(0.001*[-0.1 3])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签
ylabel('df/f change')
    title ('visual passive')


nexttile
hold on
mean3=[mean(task_mean{1}{2}(1:3)) mean(task_mean{1}{2}(4:8)) mean(task_mean{1}{2}(9:13)) mean(task_mean{1}{2}(14:16))];
error3=[ mean(task_std{1}{2}(1:3)) mean(task_std{1}{2}(4:8))  mean(task_std{1}{2}(9:13)) mean(task_std{1}{2}(14:16))];

mean4=[ mean(task_mean{2}{2}(1:3)) mean(task_mean{2}{2}(9:13))  mean(task_mean{2}{2}(4:8)) mean(task_mean{2}{2}(14:16))];
error4=[  mean(task_std{2}{2}(1:3)) mean(task_std{2}{2}(9:13))   mean(task_std{2}{2}(4:8)) mean(task_std{2}{2}(14:16))];
errorbar(1:4, mean3, error3,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean4, error4,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])

ylim(0.001*[-0.1 4])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签
ylabel('df/f change')

    title ('auditory passive')
legend('V-A group','A-V group','Location','northeastoutside','Box','off');
sgtitle(['mPFC activity in passive task of ' used_data_name{used_data}])

saveas(gcf,[Path 'figures\summary\summary of Bar mPFC  in passive task in' used_data_name{used_data}], 'jpg');


if used_data==1
saveas(gcf,[Path 'figures\summary\passive_raw\summary of Bar mPFC  in passive task in' used_data_name{used_data}], 'jpg');
elseif used_data==2
saveas(gcf,[Path 'figures\summary\passive_kernels\summary of Bar mPFC  in passive task in' used_data_name{used_data}], 'jpg');
end


%% Draw figures of hemisphere imaging and mPFC across day
% choose groups
animals_group = [1 1 1 1 1 5 5 2 2 3 3 3 4 4 4 4 4];
for curr_group=1:2
if curr_group==1
selected_group=1;
else selected_group=4;
end
group_names={'V-A','A-V'};
colors={[0 0 1],[1 0 0]};
if selected_group == 1
    stage_type={'naive','visual','auditory','mixed'};
    group_name=group_names{1};
    curr_color=colors{1};
elseif selected_group == 4
    stage_type={'naive','auditory','visual','mixed'};
    group_name=group_names{2};
    curr_color=colors{2};

else
    error('Unsupported value for variable. Must be 1 or 2.');
end
% Draw figures of hemisphere imaging and mPFC across day

passive_boundary=0.3;
use_period=find(use_t>0&use_t<passive_boundary);


allElements = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),allElements,'UniformOutput',true);
avgResults = arrayfun(@(col) ...
    mean(cat(4, allElements{nonZeroMask_all(:, col), col}), 4), ...
    1:size(allElements, 2), 'UniformOutput', false);
avgResults_svd=cellfun(@(c) plab.wf.svd2px(U_master,c),avgResults,'UniformOutput',false);
all_animals_mean=cellfun(@(x) max(x(:,:,use_period),[],3),avgResults_svd,'UniformOutput',false);

figure('Position',[50 50 800 1200]);
t = tiledlayout(4,4);

scale_all=0.002;
for ss=1:8
      nexttile([1 1])
  
         imagesc(all_animals_mean{ss}-fliplr(all_animals_mean{ss}));
      
  
    if ss<5
        title(stage_type{ss})
    end

    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(scale_all .* [0, 1]);
    xlim([0 216])

    if ss==1
        text(-50, 220, 'visual passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');
    elseif ss==5
        text(-50, 220, 'auditory passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');

    end

end

% for i = 4:6
%     subplot(2, 3, i);
%     pos = get(gca, 'Position');
%     pos(2) = pos(2) + 0.1;  % 向上平移，调整此数值以控制移动距离
%     set(gca, 'Position', pos);
% end

sgtitle(['hemispheric asymmetry in' group_name ' 0-' num2str(passive_boundary) 's'])
h = colorbar;
h.Orientation = 'vertical';
h.Position = [0.92, 0.62, 0.015, 0.2];  % 调整 colorbar 位置


% ROI across day
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

all_animal_single_day_svd=cellfun(@(x) cellfun(@(y) cellfun(@(c) plab.wf.svd2px(U_master,c),y,'UniformOutput',false),x,'UniformOutput',false),all_animal_single_day(animals_group==selected_group),'UniformOutput',false);

buf1= cellfun(@(x) cellfun(@(y) cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)),y,'UniformOutput',false),x,'UniformOutput',false) , all_animal_single_day_svd, 'UniformOutput', false);

buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);
buf2_flip= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(9).data.mask(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);
buf3=cellfun(@(x1,x2) cellfun(@(y1,y2) cellfun(@(z1,z2) z1-z2, y1,y2,'UniformOutput',false  ),x1,x2,'UniformOutput',false),buf2,buf2_flip,'UniformOutput',false);


% 假设 A 是一个 6x1 的 cell 数组，其中每个元素是 2x4 的 cell 矩阵
% 每个 A{i}{j, k} 是一个 50xN 的矩阵;
A=buf3; example=[3 5 5 3 3 5 5 3]
for curr_ord=1:length(A)
    AA=reshape(A{curr_ord}',1,[]);
    colSizes =  cellfun(@(y) size(y, 2),  AA, 'UniformOutput', true);
    for s=1:length(AA)
        if length(AA{s})<example(s)
            AA{s}(length(AA{s})+1:example(s))=repmat({single(nan(length(use_t), 1))}, 1, (example(s)-length(AA{s})));
        end
    end
    B{curr_ord}=reshape(AA,4,2)';
end

BB_lcr=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x(1,:),'UniformOutput',false)),B,'UniformOutput',false)
BB_hml=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x(2,:),'UniformOutput',false)),B,'UniformOutput',false)


a1=nexttile([1 2])
imagesc(use_t,[],mean(cat(3,BB_lcr{:}),3,'omitnan')')
ylim([0.5 16.5])
clim(0.001.*[-1,1]); colormap(a1,ap.colormap('PWG'));
hold on; 
xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
yline(3.5);yline(8.5);yline(13.5);
title('visual passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签



a2=nexttile([1 2])
imagesc(use_t,[],mean(cat(3,BB_hml{:}),3,'omitnan')')
ylim([0.5 16.5])
clim(0.001.*[-1,1]); colormap(a2,ap.colormap('PWG'));
hold on; xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
yline(3.5);yline(8.5);yline(13.5);
title('auditory passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签
box off
colorbar('eastoutside')


% plot mPFC activity across day
nexttile([1 2])
lcr_all=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_lcr,'UniformOutput',false)')
lcr_mean_line=mean(lcr_all,1,'omitnan');
lcr_sem_line=std(lcr_all,'omitnan')/sqrt(size(lcr_all,1));
hold on
ap.errorfill(1:3,lcr_mean_line(1:3), lcr_sem_line(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,lcr_mean_line(4:8), lcr_sem_line(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,lcr_mean_line(9:13), lcr_sem_line(9:13),curr_color,0.1,0.5);
 ap.errorfill(14:16,lcr_mean_line(14:16), lcr_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.001*[-0.5 1])
xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('df/f')


% plot mPFC activity across day
nexttile([1 2])
hml_all=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_hml,'UniformOutput',false)')
hml_mean_line=mean(hml_all,1,'omitnan');
hml_sem_line=std(hml_all,'omitnan')/sqrt(size(hml_all,1));
hold on
ap.errorfill(1:3,hml_mean_line(1:3), hml_sem_line(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,hml_mean_line(4:8), hml_sem_line(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,hml_mean_line(9:13), hml_sem_line(9:13),curr_color,0.1,0.5);
 ap.errorfill(14:16,hml_mean_line(14:16), hml_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.001*[-0.5 1])

xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('df/f')
   
task_average{curr_group}{1}=lcr_all;
task_average{curr_group}{2}=hml_all;

 saveas(gcf,[Path 'figures\summary\hemispheric asymmetry of heatmap and plot mPFC activity across day ' group_name ' 0-' num2str(1000*passive_boundary) 'ms in ' used_data_name{used_data}], 'jpg');


% if used_data==1 
%  saveas(gcf,[Path 'figures\summary\passive_raw\hemispheric asymmetry of heatmap and plot mPFC activity across day ' group_name ' 0-' num2str(1000*passive_boundary) 'ms in ' used_data_name{used_data}], 'jpg');
% elseif used_data==2
%  saveas(gcf,[Path 'figures\summary\passive_kernels\hemispheric asymmetry of heatmap and plot mPFC activity across day ' group_name ' 0-' num2str(1000*passive_boundary) 'ms in ' used_data_name{used_data}], 'jpg');
% end


end


%% draw summary figure of mPFC activity hemisphere

task_mean=cellfun(@(x) cellfun(@(y) mean(y,1,'omitnan'),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )
task_std=cellfun(@(x) cellfun(@(y) std(y,'omitnan')/sqrt(size(y,1)),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )

figure('Position',[200 200 700 300])
nexttile
   hold on
   ap.errorfill(1:3, task_mean{1}{1}(1:3),  task_std{1}{1}(1:3),colors{1},0.1,0.5);
   ap.errorfill(4:8, task_mean{1}{1}(4:8),  task_std{1}{1}(4:8),colors{1},0.1,0.5);
   ap.errorfill(9:13, task_mean{1}{1}(9:13),  task_std{1}{1}(9:13),colors{1},0.1,0.5);
   ap.errorfill(14:16, task_mean{1}{1}(14:16),  task_std{1}{1}(14:16),colors{1},0.1,0.5);

   ap.errorfill(1:3, task_mean{2}{1}(1:3),  task_std{2}{1}(1:3),colors{2},0.1,0.5);
   ap.errorfill(4:8, task_mean{2}{1}(9:13),  task_std{2}{1}(9:13),colors{2},0.1,0.5);
   ap.errorfill(9:13, task_mean{2}{1}(4:8),  task_std{2}{1}(4:8),colors{2},0.1,0.5);
   ap.errorfill(14:16, task_mean{2}{1}(14:16),  task_std{2}{1}(14:16),colors{2},0.1,0.5);

    ylim(0.001*[-0.1 1.5])
    xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels({'naive','visual','auditory','mixed'}); % 设置对应的标签
    ylabel('df/f change')
    title ('visual passive')

  
nexttile
   hold on
    ap.errorfill(1:3, task_mean{1}{2}(1:3),  task_std{1}{2}(1:3),colors{1},0.1,0.5);
       ap.errorfill(1:3, task_mean{2}{2}(1:3),  task_std{2}{2}(1:3),colors{2},0.1,0.5);

   ap.errorfill(4:8, task_mean{1}{2}(4:8),  task_std{1}{2}(4:8),colors{1},0.1,0.5);
   ap.errorfill(9:13, task_mean{1}{2}(9:13),  task_std{1}{2}(9:13),colors{1},0.1,0.5);
   ap.errorfill(14:16, task_mean{1}{2}(14:16),  task_std{1}{2}(14:16),colors{1},0.1,0.5);

   ap.errorfill(4:8, task_mean{2}{2}(9:13),  task_std{2}{2}(9:13),colors{2},0.1,0.5);
   ap.errorfill(9:13, task_mean{2}{2}(4:8),  task_std{2}{2}(4:8),colors{2},0.1,0.5);
   ap.errorfill(14:16, task_mean{2}{2}(14:16),  task_std{2}{2}(14:16),colors{2},0.1,0.5);

   ylim(0.001*[-0.1 1])
    xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签

    ylabel('df/f change')

    title ('auditory passive')
legend('','V-A group','','A-V group','Location','northeastoutside','Box','off'); 
sgtitle(['mPFC asymetry in passive task of ' used_data_name{used_data}])

if used_data==1
saveas(gcf,[Path 'figures\summary\passive_raw\mPFC asymetry in passive task in' used_data_name{used_data} ], 'jpg');
elseif used_data==2
saveas(gcf,[Path 'figures\summary\passive_kernels\mPFC asymetry in passive task in' used_data_name{used_data} ], 'jpg');


end
%%
figure('Position',[200 200 700 300])
nexttile
hold on
mean1=[mean(task_mean{1}{1}(1:3)) mean(task_mean{1}{1}(4:8)) mean(task_mean{1}{1}(9:13)) mean(task_mean{1}{1}(14:16))];
error1=[ mean(task_std{1}{1}(1:3)) mean(task_std{1}{1}(4:8))  mean(task_std{1}{1}(9:13)) mean(task_std{1}{1}(14:16))];

mean2=[ mean(task_mean{2}{1}(1:3)) mean(task_mean{2}{1}(9:13))  mean(task_mean{2}{1}(4:8)) mean(task_mean{2}{1}(14:16))];
error2=[  mean(task_std{2}{1}(1:3)) mean(task_std{2}{1}(9:13))   mean(task_std{2}{1}(4:8)) mean(task_std{2}{1}(14:16))];

errorbar(1:4, mean1, error1,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean2, error2,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])

ylim(0.001*[-0.1 1.5])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签
ylabel('df/f change')
    title ('visual passive')


nexttile
hold on
mean3=[mean(task_mean{1}{2}(1:5)) mean(task_mean{1}{2}(6:10)) mean(task_mean{1}{2}(11:13)) mean(task_mean{1}{2}(14:16))];
error3=[ mean(task_std{1}{2}(1:5)) mean(task_std{1}{2}(6:10))  mean(task_std{1}{2}(11:13)) mean(task_std{1}{2}(14:16))];
mean4=[ mean(task_mean{2}{2}(6:10)) mean(task_mean{2}{2}(1:5))  mean(task_mean{2}{2}(14:16)) mean(task_mean{2}{2}(11:13))];
error4=[  mean(task_std{2}{2}(6:10)) mean(task_std{2}{2}(1:5))   mean(task_std{2}{2}(14:16)) mean(task_std{2}{2}(11:13))];
errorbar(1:4, mean3, error3,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean4, error4,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])

ylim(0.001*[-0.1 1])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
         xticklabels({'naive','visual','          auditory','      mix'}); % 设置对应的标签
ylabel('df/f change')

    title ('auditory passive')
legend('V-A group','A-V group','Location','northeastoutside','Box','off');
sgtitle(['mPFC asymetry in passive task of ' used_data_name{used_data}])

if used_data==1
saveas(gcf,[Path 'figures\summary\passive_raw\Bar mPFC asymetry in passive task in' used_data_name{used_data}], 'jpg');
elseif used_data==2
saveas(gcf,[Path 'figures\summary\passive_kernels\Bar mPFC asymetry in passive task in' used_data_name{used_data}], 'jpg');

end
%%
figure('Position',[200 200 800 400])

nexttile
   hold on
   ap.errorfill(1:3, task_mean{1}{1}(14:16),  task_std{1}{1}(14:16),colors{1}*0.2,0.1,0.5);
   ap.errorfill(1:3, task_mean{1}{2}(14:16),  task_std{1}{2}(14:16),colors{1},0.1,0.5);
   legend('','visual','','auditory','Location','northeastoutside','Box','off'); 

   % ap.errorfill(11:13, task_mean{1}{1}(11:13),  task_std{1}{1}(11:13),colors{1},0.1,0.5);
   % ap.errorfill(14:16, task_mean{1}{1}(14:16),  task_std{1}{1}(14:16),colors{1},0.1,0.5);
 
   ylim(0.001*[-0.1 1.2])
     xticks([1,2,3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
    ylabel('df/f change')
        xlabel('day')

title ('V-A goup')
nexttile
 hold on
   ap.errorfill(1:3, task_mean{2}{1}(14:16),  task_std{1}{1}(14:16),colors{2}*0.2,0.1,0.5);
   ap.errorfill(1:3, task_mean{2}{2}(14:16),  task_std{2}{2}(14:16),colors{2},0.1,0.5);
      legend('','visual','','auditory','Location','northeastoutside','Box','off'); 

   ylim(0.001*[-0.1 1.2])
     xticks([1, 2,3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    % xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
    ylabel('df/f change')
    xlabel('day')
title ('A-V goup')
sgtitle('mPFC asymetry in passive task during the mixed task days    ')

saveas(gcf,[Path 'figures\summary\mPFC asymetry in mixed passive task ' ], 'jpg');

%%
%% hot spot
if selected_group == 1
    buffer_1=all_animals_mean{2};
    buffer_2=all_animals_mean{7};
elseif selected_group == 4
    buffer_1=all_animals_mean{3};
    buffer_2=all_animals_mean{6};
end


figure('Position',[50 50 500 500]);
imagesc(buffer_1);
axis image off;
% ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WG'));
clim(scale_all .* [0, 1]);
frame1 = getframe(gca);
img_data1 =im2double( imresize(frame1.cdata, size(buffer_1)));
% saveas(gcf,[Path 'figures\use_all_trials\merged_image_visual11' ], 'jpg');


figure('Position',[50 50 500 500]);
imagesc(buffer_2);
axis image off;
% ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WR'));
clim(scale_all .* [0, 1]);
frame2 = getframe(gca);
img_data2 =im2double( imresize(frame2.cdata, size(buffer_1)));
% saveas(gcf,[Path 'figures\use_all_trials\merged_image_audio11' ], 'jpg');


result_p = min(img_data1, img_data2);

figure('Position',[50 50 1300 1000]);
a1=nexttile
imagesc(buffer_1);
axis image off;
ap.wf_draw('ccf', 'black');
colormap( a1,ap.colormap('WG'));
clim(scale_all .* [0, 1]);
colorbar('southoutside')
title('visual passive')

a2=nexttile
imagesc(buffer_2);
axis image off;
ap.wf_draw('ccf', 'black');
colormap( a2,ap.colormap('WR'));
clim(scale_all .* [0, 1]);
colorbar('southoutside')
title('auditory passive')

nexttile
imshow([result_p]);
ap.wf_draw('ccf', 'black');
title('merged passive')
sgtitle([ group_name ' 0-' num2str(passive_boundary) 's'])
% imwrite(result_p, [Path 'figures\use_all_trials\merged_image_audio_visual'   group_name ' 0-' num2str(1000*passive_boundary) 'ms'  '.jpg' ]); % 保存图像为 JPG 文件


boundaries = bwboundaries(roi1(5).data.mask  );

a4=nexttile
data_audioB=buffer_1;
mean_scale=0.7*max(data_audioB(roi1(5).data.mask==1))
 % data_audioB(data_audioB>mean(data_audioB(find(roi1(5).data.mask==1)))&roi1(5).data.mask==1)=1;
 data_audioB(data_audioB>mean_scale&roi1(5).data.mask==1)=1;
data_audioB(data_audioB<1)=0;
imagesc(data_audioB)
axis image off;
ap.wf_draw('ccf','black');
clim(max(abs(clim)).*[0,1]);colormap(a4,ap.colormap('WG'));
hold on;plot(boundaries{1, 1} (:,2),boundaries{1, 1} (:,1))



a5=nexttile
data_visualB=buffer_2;
mean_scale=0.7*max(data_visualB(roi1(5).data.mask==1))
 % data_visualB(data_visualB>mean(data_visualB(find(roi1(5).data.mask==1)))&roi1(5).data.mask  ==1)=1;
 data_visualB(data_visualB>mean_scale&roi1(5).data.mask  ==1)=1;
data_visualB(data_visualB<1)=0;
imagesc(data_visualB)
axis image off;
ap.wf_draw('ccf','black');
clim(0.0001*max(abs(clim)).*[0,1]);colormap(a5,ap.colormap('WR'));
hold on;plot(boundaries{1, 1} (:,2),boundaries{1, 1} (:,1))

a6=nexttile
imagesc((data_audioB*-1+data_visualB*2))
axis image off;
ap.wf_draw('ccf','black');
clim([-2,2]);colormap(a6,ap.colormap('GWR'));
hold on;plot(boundaries{1, 1} (:,2),boundaries{1, 1} (:,1))

 saveas(gca,[Path 'figures\summary\ merged_image_audio_visual'   group_name ' 0-' num2str(1000*passive_boundary) 'ms'   ], 'jpg');


% 将所有边界坐标转换为一个单一的二维数组



%% Gif figures
% 1. 设置GIF文件名和帧延迟时间
outputFile = [Path 'figures\use_all_trials\heatmap and plot mPFC activity across day live ' group_name ' 0-' num2str(1000*passive_boundary) 'ms.gif' ];
delayTime = 0.1; % 每帧的延迟时间

avgResults_svd=cellfun(@(c) plab.wf.svd2px(U_master,c),avgResults,'UniformOutput',false);

% 2. 绘制图像并保存为GIF
for curr_ord = 1:size(avgResults_svd{2},3) % N 为帧的数量
    % 使用 imagesc 显示图像数据
    figure('Position',[50 50 1200 800]);

    for ss=1:8
        nexttile
      % nexttile([2 2])
    % subplot(2, 3, ss);
 
        imagesc(avgResults_svd{ss}(:,:,curr_ord));

    

   
    if ss<=4
        title(stage_type{ss})
    end

    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(scale_all .* [0, 1]);

    if ss==1
        text(-50, 220, 'visual passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');
    elseif ss==5
        text(-50, 220, 'auditory passive', 'Rotation', 90, 'FontSize', 12, 'HorizontalAlignment', 'center');

    end

end
    sgtitle([group_name ' 0-' num2str(passive_boundary) 's'  ',time:' num2str(t_passive(curr_ord)) 's' ])

  
    % 捕获当前图像帧
    frame = getframe(gcf); % 从当前窗口获取帧
    img = frame2im(frame); % 将帧转换为图像
    [indImg, cmap] = rgb2ind(img, 256);

    % 写入GIF
    if curr_ord == 1
        % 如果是第一帧，创建GIF文件
        imwrite(indImg, cmap, outputFile, 'gif', 'LoopCount', Inf, 'DelayTime', delayTime);
    else
        % 如果是后续帧，追加到GIF文件
        imwrite(indImg, cmap, outputFile, 'gif', 'WriteMode', 'append', 'DelayTime', delayTime);
    end
    close all
end

%%
animals_group = [1 1 1 1 1 5 5 2 2 3 3 3 4 4 4 4 4];

selected_group=1;

group_names={'V-A','A-V'};
colors={[0 0 1],[1 0 0]};
if selected_group == 1
    stage_type={'naive','visual','auditory','mixed'};
    group_name=group_names{1};
    curr_color=colors{1};
elseif selected_group == 4
    stage_type={'naive','auditory','visual','mixed'};
    group_name=group_names{2};
    curr_color=colors{2};

else
    error('Unsupported value for variable. Must be 1 or 2.');
end
% Draw figures of hemisphere imaging and mPFC across day

allElements = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),allElements,'UniformOutput',true);
avgResults = arrayfun(@(col) ...
    mean(cat(4, allElements{nonZeroMask_all(:, col), col}), 4), ...
    1:size(allElements, 2), 'UniformOutput', false);
avgResults_svd=cellfun(@(c) plab.wf.svd2px(U_master,c),avgResults,'UniformOutput',false);

% ap.imscroll(avgResults_svd{2})
% axis image off
% ap.wf_draw('ccf','black');
% clim(max(avgResults_svd{2},[],'all').*[-1,1]);colormap(ap.colormap('PWG'));



T1=0;
T2=0.3;

used_frame=find(use_t>T1&use_t<T2);
boundaries = bwboundaries(roi1(5).data.mask  );

colors = [
    linspace(1, 0, length(used_frame))' ... % 红色通道（由浅到深）
    linspace(0, 0, length(used_frame))' ... % 绿色通道（由浅到深）
    linspace(0, 0, length(used_frame))' ... % 蓝色通道（由浅到深）
];

   % 设置画布大小和布局
figure('Position', [50, 50, 1200, 600]);
% tiledlayout('flow'); % 使用自动布局管理器
% 提前计算所需的参数，避免循环中重复计算
num_images = length(avgResults_svd);
% 遍历图像并绘制
for curr_image_idx = 1:num_images
    curr_image = avgResults_svd{curr_image_idx};

    cc1=reshape(curr_image,[],length(use_t));
    max_range=max(cc1(reshape((roi1(5).data.mask==1),1,[]),:),[],'all');
    nexttile; % 切换到下一个绘图区域
    hold on;
    % 遍历帧
    for i =length(used_frame):-1:1
        curr_frame = used_frame(i);
        curr_data = curr_image(:, :, curr_frame);
        % 阈值筛选并二值化
        mean_scale=max(0.9*max(curr_data(roi1(5).data.mask==1)),0.6*max_range);
        curr_data(curr_data>mean_scale&roi1(5).data.mask==1)=1;
        curr_data(curr_data<1)=0;
        % 获取符合条件的坐标并绘制散点
        [row, col] = find(curr_data == 1);
        scatter(col, row, 5+5*i, 'filled', 'MarkerFaceColor', colors(i, :),'MarkerFaceAlpha',0.1);
                % scatter(col, row, 5+1*i, 'MarkerEdgeColor', colors(i, :),'MarkerEdgeAlpha',0.1);

    end
    % 反转 y 轴，使其从上到下，并设置固定轴范围
    set(gca, 'YDir', 'reverse', 'XLim', [0, 450], 'YLim', [0, 426]);
    axis image off;
    % 绘制其他辅助图形或边界
    plot(boundaries{1, 1}(:, 2), boundaries{1, 1}(:, 1));
    ap.wf_draw('ccf', 'black'); % 自定义绘制方法
    % 添加标题或标签
    if curr_image_idx <= 4
        title(stage_type{curr_image_idx});
    end
    if curr_image_idx == 1
        text(-50, 220, 'visual passive', 'Rotation', 90, ...
            'FontSize', 12, 'HorizontalAlignment', 'center');
    elseif curr_image_idx == 5
        text(-50, 220, 'auditory passive', 'Rotation', 90, ...
            'FontSize', 12, 'HorizontalAlignment', 'center');
    end
end

sgtitle([group_name ' from ' num2str(T1) ' to ' num2str(T2) ' s'])
if used_data==1
 saveas(gca,[Path 'figures\summary\passive_raw\ hot spot changes across time in '   group_name  ], 'jpg');
elseif used_data==2
     saveas(gca,[Path 'figures\summary\passive_kernels\ hot spot changes across time in '   group_name  ], 'jpg');

end

%% video of averaged mice data


% 做视频 每只小鼠
close all
% 创建一个 VideoWriter 对象，指定文件名和格式
videoFilename = ['figures\use_all_trials\all_trials_visual_auditory_passive_' strjoin(animals(find(animals_group==4)), '_') '.avi'];

% fullfile(Path,videoFilename)
video = VideoWriter(fullfile(Path,videoFilename), 'Uncompressed AVI');  % 可以根据需要选择不同的格式
video.FrameRate = 10;  % 设置帧率
% 打开 VideoWriter 对象以进行写入
open(video);
% 读取图像序列并写入视频
for curr_frame = 1:size(t_passive,2)
    % 标签数组，包含每个阶段的标签
    labels = {'visual stage 0', 'visual stage 1', 'visual stage 2','visual stage 3', ...
        'auditory stage 0', 'auditory stage 1', 'auditory stage 2', 'auditory stage 4'};


    % 处理图像，插入标签
    image_with_labels = cell(1,8);  % 用于存储处理后的带标签的图像
    labelHeight = 50;  % 标签区域高度

    for curr_ord = 1:8
        % 当前图像
        imagesc(avgResults{curr_ord}(:,:,curr_frame));
        axis image off;
        ap.wf_draw('ccf','black');
        clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));

        % 获取当前帧的图像数据
        frame = getframe(gca);
        img = frame.cdata;

        % 获取图像尺寸
        [imgHeight, imgWidth, ~] = size(img);

        % 创建一个新的图像，在上方留出空间放置标签
        img_with_label = uint8(255 * ones(imgHeight + labelHeight, imgWidth, 3));  % 白色背景
        img_with_label(labelHeight+1:end, :, :) = img;  % 将原图像放置在下方

        % 在空白区域插入相应的标签
        img_with_label = insertText(img_with_label, [imgWidth/2, labelHeight/2], labels{curr_ord}, 'FontSize', 18, ...
            'BoxColor', 'white', 'BoxOpacity', 1, 'TextColor', 'black', 'AnchorPoint', 'Center');
        % 保存处理后的图像
        image_with_labels{curr_ord} = img_with_label;
    end

    % 将视觉和听觉图像拼接成 2 行 3 列的矩阵图像

    image_all = [image_with_labels{1}, image_with_labels{2}, image_with_labels{3}, image_with_labels{4}; ...
        image_with_labels{5}, image_with_labels{6}, image_with_labels{7}, image_with_labels{8}];

    % 添加标题并保存到视频中
    [height, width, ~] = size(image_all);
    titleHeight = 30;
    newImage = uint8(zeros(height + titleHeight, width, 3));
    newImage(titleHeight+1:end, :, :) = image_all;
    newImage(1:titleHeight, :, :) = 255;

    position = [width/2, titleHeight/2];
    titleText = ['Averaged mice group' num2str(animals_group(curr_animal_idx)) ':' num2str(t_passive(curr_frame)) 's'];
    newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
        'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
        'AnchorPoint', 'Center');

    writeVideo(video, newImageWithText);
    close all

end

% 关闭 VideoWriter 对象
close(video);
disp('视频保存完成。');




%% behavioral vs mPFC
selected_group=[1 4];
colors={'b','r'};
figure;
for curr_ord=1:2

all_animal_react1=cellfun(@(x) x(1,:), all_animal_react,'UniformOutput',false);
allElements = vertcat(all_animal_react1{animals_group==selected_group(curr_ord)});
allElements1=cell2mat(allElements(:,2:3));
hold on
scatter(-log(allElements1(:,curr_ord)),-log(allElements1(:,3-curr_ord)),colors{curr_ord}, 'filled')
text(-log(allElements1(:,curr_ord)), -log(allElements1(:,3-curr_ord)), animals(animals_group==selected_group(curr_ord)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

end
axis equal
xlim([1 3]);ylim([1 3])
 % xlim([0 16]);ylim([0 16])

legend('V-A','A-V')
xlabel('-log reaction time in visual task')
ylabel('-log reaction time in auditory task')

saveas(gca,[Path 'figures\use_all_trials\ stim2move reaction time visual vs auditory ' ], 'jpg');
