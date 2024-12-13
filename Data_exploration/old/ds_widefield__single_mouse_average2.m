
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';


animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS004','DS000','DS006','DS005'};
animals_group=[ 1 1 1 1 1 1 2 2 2 3 3 3 4 3];


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



for curr_animal=1:length(animals)
    % 
    animal=animals{curr_animal};
    fprintf('%s\n', ['start  ' animal ]);

    raw_data_task=load([Path '\mat_data\' animal '_task.mat']);
    raw_data_lcr=load([Path '\mat_data\' animal '_lcr_passive.mat']);
    raw_data_hml=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);
    fprintf('%s\n', ['File loading completed of  ' animal ]);

% bbb= cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_lcr.wf_px_baseline ,'UniformOutput',false);
% base_idx= cellfun( @(idx) find(idx==90),raw_data_lcr.all_groups_name_baseline  ,'UniformOutput',false);

buffer.data_basline_lcr{curr_animal}=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_lcr.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==90),raw_data_lcr.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);
% base_90_mean=cat(4,base_90{:});
% buffer.data_basline_lcr{curr_animal}=mean(base_90_mean,4);

buffer.data_basline_hml{curr_animal}=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_hml.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==8000),raw_data_hml.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);
% base_8k_mean=cat(4,base_8k{:});
% buffer.data_basline_hml{curr_animal}=mean(base_8k_mean,4);


    indx_V= find(raw_data_task.workflow_type==1);
    for curr_idx=1:length(indx_V)
        buffer.data_V_task_rxt{curr_animal,curr_idx}=raw_data_task.rxn_med(indx_V(curr_idx));
        buffer.data_V_task_s2m{curr_animal,curr_idx}=raw_data_task.stim2move(indx_V(curr_idx));
        buffer.data_V_task_learned{curr_animal,curr_idx}=raw_data_task.learned_day(indx_V(curr_idx));

        buffer.data_V_task_kernels{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_V(curr_idx)}(:,:,1));


        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_V(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_V_90{curr_animal:curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end


        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_V(curr_idx)}));
        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_V_8k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
        end
    end

    indx_A= find(raw_data_task.workflow_type==2);
    % buffer.data_A_task_rxt{curr_animal}=raw_data_task.rxn_med(indx_A);
    for curr_idx=1:length(indx_A)
        buffer.data_A_task_rxt{curr_animal,curr_idx}=raw_data_task.rxn_med(indx_A(curr_idx));
        buffer.data_A_task_s2m{curr_animal,curr_idx}=raw_data_task.stim2move(indx_A(curr_idx));
        buffer.data_A_task_learned{curr_animal,curr_idx}=raw_data_task.learned_day(indx_A(curr_idx));

        buffer.data_A_task_kernels{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_A(curr_idx)}(:,:,1));

        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_A(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_A_90{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end

        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_A(curr_idx)}));

        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_A_8k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
        end
    end

    indx_M= find(raw_data_task.workflow_type==3);
    for curr_idx=1:length(indx_M)
        buffer.data_M_task_rxt{curr_animal,curr_idx}=raw_data_task.rxn_med(indx_M(curr_idx));
        buffer.data_M_task_s2m{curr_animal,curr_idx}=raw_data_task.stim2move(indx_M(curr_idx));
        buffer.data_M_task_learned{curr_animal,curr_idx}=raw_data_task.learned_day(indx_M(curr_idx));

        buffer.data_M_task_kernels{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_M(curr_idx)}(:,:,1));

        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_M(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_M_90{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end

        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_M(curr_idx)}));
        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_M_8k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
        end


    end


end


%%
suffixes = {'V_90','V_8k', 'V_task_kernels', 'A_90','A_8k', 'A_task_kernels','M_90','M_8k','M_task_kernels'};

for i = 1:length(suffixes)
    data_var=evalin('base',['buffer.data_', suffixes{i}]);
    data_var_mean=[ 'data_',suffixes{i},'_mean'];
    redata_var=['redata_', suffixes{i}];
    cross_time_var=['cross_time_', suffixes{i}];
    learned_var=evalin('base',['buffer.data_', suffixes{i}(1),'_task_learned']);
    
    %这一部分是对每只小鼠每种任务后5天mPFC数据的平均

    % 1. 使用 cellfun 来标记非空矩阵
    nonEmptyMask = cellfun(@(x) ~isempty(x), cellfun(@(y) y, data_var, 'UniformOutput', false), 'UniformOutput', false);
    % 2. 提取每一行非空矩阵的索引
    nonEmptyIndices = cellfun(@(row) find(row), num2cell(nonEmptyMask, 2), 'UniformOutput', false);
    % 3. 确保每行提取最后 5 个非空矩阵的索引（或所有非空矩阵如果少于 5 个）
    number=5;
    last5Indices=cell(size(data_var,1),1);
    for ss=1:size(data_var,2)
        buffer_learn=learned_var{ss};
        if all(cellfun(@(x) x == 0, buffer_learn(nonEmptyIndices{ss})), 'all')
            last5Indices{ss} =nonEmptyIndices{ss}(1:min(end,number));
        else
            last5Indices{ss} =nonEmptyIndices{ss}(max(end-number+1,1):end);
            %last5Indices = cellfun(@(indices) indices(max(end-4,1):end), nonEmptyIndices, 'UniformOutput', false);
        end
    end
    % 4. 提取每一行最后 5 个非空矩阵
    last5Matrices = cellfun(@(row, idx) row(idx), num2cell(data_var, 2), last5Indices, 'UniformOutput', false);


    %  aaa=num2cell(data_var, 2)
    % aaa{2}(last5Indices{2})
    % 5. 求和并平均每一行的最后5个非空矩阵
    buffer.(data_var_mean) = cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5Matrices, 'UniformOutput', false);
    buffer.(redata_var)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), buffer.(data_var_mean), 'UniformOutput', false);


    % buf= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),  buffer.(redata_var), 'UniformOutput', false);
    buf_b=cell(length(buffer.(redata_var)),1);
    for s=1:length(buffer.(redata_var))
        if isempty(buffer.(redata_var){s})
            buf_b{s}=single(zeros(1,size(buffer.(redata_var){1},2)));
        else  buf_b{s}= mean( buffer.(redata_var){s}(roi1(1).data.mask(:),:),1);
        end
    end

    buffer.(cross_time_var)=permute(cat(3,buf_b{:}),[2,3,1]);

    %计算 behavior的reaction time的平均
    if strcmp(suffixes{i},'V_90')
        last5rxt_V = cellfun(@(row, idx) row(idx), num2cell(buffer.data_V_task_rxt, 2), last5Indices, 'UniformOutput', false);
        buffer.data_V_task_rxt_mean= cell2mat( cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5rxt_V, 'UniformOutput', false));



    elseif strcmp(suffixes{i},'A_8k')
        last5rxt_A = cellfun(@(row, idx) row(idx), num2cell(buffer.data_A_task_rxt, 2), last5Indices, 'UniformOutput', false);
        buffer.data_A_task_rxt_mean=  cell2mat(cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5rxt_A, 'UniformOutput', false));

    end

end

%%
save([Path 'mat_data\'  'all_mice_data.mat' ],'buffer','-v7.3')
%%
 load([Path 'mat_data\'  'all_mice_data.mat' ])
%% wide imaging of whole brain of single mouse
figure('Position',[50 50 1400 500]);
for i=1:length(buffer.data_V_90_mean  )
    nexttile
    buffer_image_V=mean(buffer.data_V_90_mean{i}(:,:,period_passive) ,3);
    imagesc(buffer_image_V)
    axis image off;
    ap.wf_draw('ccf','black');
    clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('visual passive')
saveas(gcf,[Path 'figures\image in visual passive of each mice'], 'jpg');

figure('Position',[50 50 1400 500]);
for i=1:length(buffer.data_A_8k_mean  )
    nexttile
    buffer_image_V=mean(buffer.data_A_8k_mean{i}(:,:,period_passive) ,3);
    imagesc(buffer_image_V)
    axis image off;
    ap.wf_draw('ccf','black');
    clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('audio passive')
saveas(gcf,[Path 'figures\image in audio passive of each mice'], 'jpg');

%% wide imaging of whole brain of averaged mice
selected_group=1;
scale_all=0.006;

figure('Position',[50 50 1400 900]);
a1=nexttile
selected_data_baseline_lcr=buffer.data_basline_lcr (find(animals_group== selected_group));

last_data_lcr=cellfun(@(last1) last1{end} ,selected_data_baseline_lcr,'UniformOutput',false );

mean_image_basline_lcr=mean(cat(4,last_data_lcr {:}),4);
buffer_image_basline_lcr=max(mean_image_basline_lcr(:,:,period_passive),[] ,3);
imagesc(buffer_image_basline_lcr);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a1,ap.colormap('PWB'));
title ('pre learning of visual stimlus','FontSize',14,'FontWeight','normal')

a2=nexttile
selected_data_V_90=buffer.data_V_90_mean (find(animals_group== selected_group));
mean_image_V=mean(cat(4,selected_data_V_90 {:}),4);
buffer_image_V=max(mean_image_V(:,:,period_passive),[] ,3);
imagesc(buffer_image_V);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.3*max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a2,ap.colormap('PWB'));
title ('post learning of visual stimlus','FontSize',14,'FontWeight','normal')
% cbar1 = colorbar(a2,'Location','southoutside');
% cbar1.Ticks = scale_all.*[0,1]; % 只显示最小值和最大值
% cbar1.FontSize = 12;
% cbar1.Label.String = 'dF/F'; % 设置colorbar的名称
a6=nexttile
imagesc(buffer_image_V-buffer_image_basline_lcr);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a6,ap.colormap('PWB'));


% selected_group=1;
a3=nexttile
selected_data_baseline_hml=buffer.data_basline_hml (find(animals_group== selected_group));
last_data_hml=cellfun(@(last1) last1{end} ,selected_data_baseline_hml,'UniformOutput',false );
mean_image_basline_hml=mean(cat(4,last_data_hml {:}),4);
buffer_image_basline_hml=max(mean_image_basline_hml(:,:,period_passive),[] ,3);
imagesc(buffer_image_basline_hml);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a3,ap.colormap('PWR'));
title ('pre learning of auditory stimlus','FontSize',14,'FontWeight','normal')

a4=nexttile
selected_data_A_8k=buffer.data_A_8k_mean (find(animals_group==selected_group));
mean_image_A=mean(cat(4,selected_data_A_8k {:}),4);
buffer_image_A=max(mean_image_A(:,:,period_passive),[] ,3);
imagesc(buffer_image_A);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a4,ap.colormap('PWR'));
title ('post learning of auditory stimlus','FontSize',14,'FontWeight','normal')
% cbar1 = colorbar(a4,'Location','southoutside');
% cbar1.Ticks = scale_all.*[0,1]; % 只显示最小值和最大值
% cbar1.FontSize = 12;
% cbar1.Label.String = 'dF/F'; % 设置colorbar的名称

a5=nexttile
imagesc(buffer_image_A-buffer_image_basline_hml);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(a5,ap.colormap('PWR'));


 saveas(gcf,[Path 'figures\averaged mice in visual auditory pre post_' num2str(selected_group)], 'jpg');
%%
figure('Position',[50 50 1600 900]);
for i=1:length(buffer.data_basline_lcr )
    nexttile
    sizes = cellfun(@size, buffer.data_basline_hml{i}, 'UniformOutput', false);
nonZeroElements = cellfun(@(s) all(s ~= 0), sizes);
lastNonZeroIndex = find(nonZeroElements, 1, 'last');

    lasstdata=buffer.data_basline_hml{i}{lastNonZeroIndex};
imagesc(max(lasstdata(:,:,period_passive),[] ,3))
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
title(animals{i},'pre')

 nexttile
imagesc(max(buffer.data_A_8k_mean{i}(:,:,period_passive),[] ,3));
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
title(animals{i},'post');
end
sgtitle('Auditory passive')

saveas(gcf,[Path 'figures\each mice in auditory  post-pre'], 'jpg');
%%
figure('Position',[50 50 1600 900]);
for i=1:length(buffer.data_basline_lcr )
%     nexttile
% imagesc(max(buffer.data_basline_lcr{i}(:,:,period_passive),[] ,3))
% axis image off;
% ap.wf_draw('ccf','black');
% % clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
% clim(scale_all.*[0,1]); colormap(ap.colormap('WG'));
% title(animals{i},'pre')

 nexttile
imagesc(max(buffer.data_V_90_mean{i}(:,:,period_passive),[] ,3)-max(buffer.data_basline_lcr{i}(:,:,period_passive),[] ,3))
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(ap.colormap('WG'));
title(animals{i},'post-pre')
end
sgtitle('Visual passive')
saveas(gcf,[Path 'figures\each mice in visual  post-pre'], 'jpg');

%% 做视频
close all
% 创建一个 VideoWriter 对象，指定文件名和格式
videoFilename = ['figures\visual_auditory_passive_' strjoin(animals(find(animals_group==selected_group)), '_') '.avi'];

% fullfile(Path,videoFilename)
video = VideoWriter(fullfile(Path,videoFilename), 'Uncompressed AVI');  % 可以根据需要选择不同的格式
video.FrameRate = 10;  % 设置帧率
% 打开 VideoWriter 对象以进行写入
open(video);
% 读取图像序列并写入视频
for k = 1:size(t_passive,2)
    % ap.imscroll(mean_image_V(:,:,k),t_passive(k));

    imagesc(mean_image_V(:,:,k));
    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image1 = frame.cdata;

    % ap.imscroll(mean_image_A(:,:,k),t_passive(k));
    imagesc(mean_image_A(:,:,k));

    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image2 = frame.cdata;

    %  ap.imscroll((v_v_avg_l(:,:,k)-a_a_avg_l(:,:,k)),t(k));
    % axis image off;
    %  ap.wf_draw('ccf','black');
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % % 获取当前图像帧
    % frame = getframe(gca);
    % % 提取图像数据
    % image3 = frame.cdata;



    image_all=[image1 image2 ];



    [height, width, ~] = size(image_all);
    titleHeight = 30;  % 标题区域的高度
    newImage = uint8(zeros(height + titleHeight, width, 3));
    % 将原始图像复制到新图像中
    newImage(titleHeight+1:end, :, :) = image_all;
    % 在新图像的标题区域填充背景色（例如，黑色）
    newImage(1:titleHeight, :, :) = 255;
    % 在新图像上添加标题
    position = [width/2, titleHeight/2];  % 标题位置
    % titleText=[strjoin(animals, '_') ' ' num2str(t_passive(k))];
    titleText=[ 'Averaged mice ' num2str(t_passive(k))];
    newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
        'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
        'AnchorPoint', 'Center');
    % 将图像写入视频文件
    writeVideo(video, newImageWithText);
    close all
end
% 关闭 VideoWriter 对象
close(video);
disp('视频保存完成。');


%% merged figures
figure;

nexttile
imagesc(max(mean_image_V(:,:,period_passive),[],3));
ap.wf_draw('ccf','black');

axis image off;
% clim(0.3*max(buffer_image_V,[],'all').*[0,1]); colormap(ap.colormap('WR'));
clim(scale_all.*[0,1]); colormap(ap.colormap('WR'));

 colorbar
saveas(gcf,[Path 'figures\merged_image_audio' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');
frame1 = getframe(gcf);
img_data1 =im2double( frame1.cdata);
figure;
imagesc(max(mean_image_A(:,:,period_passive),[],3));
axis image off;
% clim(0.7*max(buffer_image_A,[],'all').*[0,1]); colormap(ap.colormap('WG'));
clim(scale_all.*[0,1]); colormap(ap.colormap('WG'));

% colorbar
saveas(gcf,[Path 'figures\merged_image_visual' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');
frame2 = getframe(gcf);
img_data2 =im2double( frame2.cdata);
result = min(img_data1, img_data2);

imshow(result);

saveas(gcf,[Path 'figures\merged_image_V_A' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');


figure;
a1=subplot(1,2,1)
imagesc(max(mean_image_V(:,:,period_passive),[],3));
axis image off;
ap.wf_draw('ccf','black');
clim(scale_all.*[0,1]); colormap(a1,ap.colormap('WR'));
title('Visual stimulus','FontSize',12)
cbar1 = colorbar(a1,'Location','southoutside');
cbar1.Ticks = scale_all.*[0,1]; % 只显示最小值和最大值
cbar1.FontSize = 12;
cbar1.Label.String = 'dF/F'; % 设置colorbar的名称
% cbar1.Position = cbar1.Position + [0, -0.1, 0, 0]; % 下移colorbar

a2=subplot(1,2,2)
imagesc(max(mean_image_A(:,:,period_passive),[],3));
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[0,1]); colormap(ap.colormap('WG'));
clim(scale_all.*[0,1]); colormap(a2,ap.colormap('WG'));
title('Auditory stimulus','FontSize',12)
cbar2 = colorbar(a2,'Location','southoutside');
cbar2.Ticks = scale_all.*[0,1]; % 只显示最小值和最大值
cbar2.FontSize = 12;
cbar2.Label.String = 'dF/F'; % 设置colorbar的名称
saveas(gcf,[Path 'figures\image_V_A in 2 color' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');



%% 寻找mPFC的hot spot
mean_scale=0.0008;
data_audio=max(mean_image_A(:,:,period_passive),[],3);
data_audioB=data_audio;

% data_audioB(data_audioB>mean(data_audioB(find(roi1(5).data.mask==1)))&roi1(5).data.mask==1)=1;
data_audioB(data_audioB>mean_scale&roi1(5).data.mask==1)=1;

data_audioB(data_audioB<1)=0;
figure;
imagesc(data_audioB)
axis image off;
ap.wf_draw('ccf','black');
clim(max(abs(clim)).*[0,1]);colormap(ap.colormap('WG'));
saveas(gcf,[Path 'figures\hotspot in mPFC during auditory task' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');

data_visual=max(mean_image_V(:,:,period_passive),[],3);
data_visualB=data_visual;
% data_visualB(data_visualB>mean(data_visualB(find(roi1(5).data.mask==1)))&roi1(5).data.mask  ==1)=1;
data_visualB(data_visualB>mean_scale&roi1(5).data.mask  ==1)=1;


data_visualB(data_visualB<1)=0;
figure;
imagesc(data_visualB)
axis image off;
ap.wf_draw('ccf','black');
clim(0.0001*max(abs(clim)).*[0,1]);colormap(ap.colormap('WR'));
saveas(gcf,[Path 'figures\hotspot in mPFC during visual task' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');

figure;
imagesc((data_audioB*-1+data_visualB*2))
axis image off;
ap.wf_draw('ccf','black');
clim([-2,2]);colormap(ap.colormap('GWR'));
saveas(gcf,[Path 'figures\hotspot merged in mPFC ' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');




%% 每只小鼠mPFC在visual/ audio /mixed task 的神经元活动性
figure('Position',[50 50 800 800]);
for i=1:length(suffixes)
    cross_time_var=['cross_time_', suffixes{i}];
    nexttile(i)
    imagesc( buffer.(cross_time_var)')
    set(gca, 'YTick', 1:length(animals), 'YTickLabel', animals);
    clim(0.002*[0,1]);
    title(strrep(suffixes{i},'_','-'))
    colormap( nexttile(i),ap.colormap('WG'))
end
sgtitle('mPFC activity')


saveas(gcf,[Path 'figures\averaged acitvity of mPFC of single mouse'], 'jpg');




%% single trial
figure('Position',[50 50 1200 1200]);
suffixes2 = {'V_90','A_90','V_8k','A_8k'};
for ii=1:4
    data_var=evalin('base',['buffer.data_', suffixes2{ii}]);
    data_rxt=evalin('base',['buffer.data_', suffixes2{ii}(1:end-2) 'task_rxt']);

    computeRow=@(x)  reshape(x,size(x,1)*size(x,2),size(x,3));
    redata_V_90 = cellfun(computeRow, data_var, 'UniformOutput', false);
    isEmpty = ~cellfun('isempty', redata_V_90);
    cross_time_V_90=cell2mat(cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1), redata_V_90(isEmpty), 'UniformOutput', false));
    rxt_V_90=cell2mat(data_rxt(isEmpty));
    max_cross_time_V_90=max(cross_time_V_90(:,period_passive),[],2);

    % 3. 提取非空位置的值并记录行索引
    [rowIndices, colIndices] = find(isEmpty);
    % 4. 创建颜色映射
    % colors = turbo(length(animals));
    nexttile
    % 5. 使用 scatter 绘图
    hold on;
    for i = 1:length(animals)
        scatter(1./rxt_V_90(rowIndices == i), max_cross_time_V_90(rowIndices == i), [], colors(i, :), 'filled');
        % plot(1./rxt_V_90(rowIndices == i), max_cross_time_V_90(rowIndices == i), 'o-', 'Color', colors(i, :), 'MarkerFaceColor', colors(i, :));

    end
    xlabel('1 / reaction time(s)')
    ylabel('dF/F in mPFC')
    title(['mPFC activity in ' strrep(suffixes2{ii},'_','-') ' vs behavioral reaction time'])
    hold off;
end
legend(animals, 'Location', 'best');

saveas(gcf,[Path 'figures\averaged acitvity of mPFC vs behaviors'], 'jpg');


% scatter(buffer.data_V_task_rxt_mean ,max(all_data.cross_time_V_90(period_passive,:) ,[],1) )
%%
figure('Position',[50 50 1200 500]);
animals_group=[ 1 1 1 1 1 1 2 2 2 3 3 3 4 3];
colors = zeros(length(animals_group), 3); % 初始化颜色数组为全黑
colors(animals_group == 1, :) = repmat([1 0 0], sum(animals_group == 1), 1); % 将C为1的位置设置为红色
colors(animals_group == 2, :) = repmat([1 0.8 0.8], sum(animals_group == 2), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 3, :) = repmat([0 0 1], sum(animals_group == 3), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 4, :) = repmat([0.8 0.8 1], sum(animals_group == 4), 1); % 将C为0的位置设置为蓝色

nexttile;
scatter(1./buffer.data_V_task_rxt_mean ,max(buffer.cross_time_V_90(period_passive,:) ,[],1),[], colors, 'filled' )
% legend(animals{:})
text(1./buffer.data_V_task_rxt_mean, max(buffer.cross_time_V_90(period_passive,:) ,[],1), animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
xlabel('1/reaction time(s)');ylabel('dF/F');
title('mPFC activities vs behavior in visual task')
nexttile;
scatter(1./buffer.data_A_task_rxt_mean ,max(buffer.cross_time_A_8k(period_passive,:) ,[],1),[], colors, 'filled' )
% legend(animals{:})
title('mPFC activities vs behavior in audio task')
xlabel('1/reaction time(s)');ylabel('dF/F');
text(1./buffer.data_A_task_rxt_mean, max(buffer.cross_time_A_8k(period_passive,:) ,[],1), animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

saveas(gcf,[Path 'figures\averaged acitvity of mPFC vs behavior'], 'jpg');


figure;
scatter(1./buffer.data_V_task_rxt_mean ,1./buffer.data_A_task_rxt_mean ,[], colors, 'filled' )
text(1./buffer.data_V_task_rxt_mean, 1./buffer.data_A_task_rxt_mean, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
xlabel('1/reaction time(s) in visual task');ylabel('1/reaction time(s) in auditory task');
xlim([0 3])
ylim([0 3])
xline(0.5)
yline(0.5)
hold on
x=0:3
y=x;
plot(x,y)

figure;
scatter(max(buffer.cross_time_V_90(period_passive,:) ,[],1) ,max(buffer.cross_time_A_8k(period_passive,:) ,[],1),[], colors, 'filled' )
text(max(buffer.cross_time_V_90(period_passive,:) ,[],1), max(buffer.cross_time_A_8k(period_passive,:) ,[],1), animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
xlabel('mPFC in visual passive');ylabel('mPFC in auditory passive');
xlim([0 0.003])
ylim([0 0.003])
% xline(1)

%% behavior analysis

% 生成示例数据
data_2{1} =buffer.data_V_task_s2m'  ;
data_2{2} =buffer.data_A_task_s2m'  ;

titlename={'visual task','audio task'};
figure('Position',[50 50  1400 400]);
for curr_fig=1:2
    data=data_2{curr_fig};
    % 获取数据维度
    [numRows, numCols] = size(data);
    % 将 cell 矩阵转换为数值矩阵，空值转换为 NaN
    dataNumeric = cellfun(@(x) ifelse(isempty(x), NaN, x), data);
    % 创建图形窗口
    nexttile
    hold on;
    % 创建一个列向量，用于生成散点图的 x 坐标
    x = repmat(1:numCols, numRows, 1);

    % 绘制所有数据点为蓝色
    scatter(x(:), dataNumeric(:), 'b');
    % 标记每行的最后5个非 NaN 值为红色
    % 创建一个逻辑索引矩阵，用于标记每行的最后5个非 NaN 值
    isLastFive = false(numRows, numCols);
    for i = 1:numCols
        nonNanIdx = find(~isnan(dataNumeric(:, i)));
        if length(nonNanIdx) >= 5
            isLastFive( nonNanIdx(end-4  :end),i) = true;
        end
    end

    % 提取最后5个非 NaN 值的 x 和 y 坐标
    xLastFive = x(isLastFive);
    yLastFive = dataNumeric(isLastFive);

    % 绘制最后5个非 NaN 值为红色
    scatter(xLastFive, yLastFive, 'r');

    hold off;
    set(gca, 'XTick', 1:length(animals), 'XTickLabel', animals);
    xtickangle(45);
    ylabel('reaction time(s)')
    ylim([0 1])
    title(titlename{curr_fig})
end

saveas(gcf,[Path 'figures\behavior reaction time of single mice'], 'jpg');


%% 行为学比较  V-A & only A

figure('Position',[50 50 450 250]);

% 创建一个示例的4x5的cell矩阵A
for u=1
    if u==1
        V_data = buffer.data_V_task_s2m;
        A_data = buffer.data_A_task_s2m;
    else
        V_data = buffer.data_V_task_rxt;
        A_data = buffer.data_A_task_rxt;
    end
    % 对矩阵进行操作
    V_data = cellfun(@(row) [row(cellfun('isempty', row)), row(~cellfun('isempty', row))], ...
        num2cell(V_data, 2), 'UniformOutput', false);
    % 把结果从 cell 数组转换回矩阵
    V_data = vertcat(V_data{:});
    V_filled = cellfun(@(x) ifelse(isempty(x), NaN, x), V_data, 'UniformOutput', false);
    % 将 cell 矩阵转换为数值矩阵
    V_numeric = cell2mat(V_filled);

    % 创建一个示例的4x5的cell矩阵A
    A_filled = cellfun(@(x) ifelse(isempty(x), NaN, x), A_data, 'UniformOutput', false);
    % 将 cell 矩阵转换为数值矩阵
    A_numeric =[nan(14,10) cell2mat(A_filled)];

    V_A=[V_numeric cell2mat(A_filled)];
    %
    % 显示调整后的矩阵

    nexttile
    hold on
    plot(V_numeric(1:7,:)','Color', [0.8  1 0.8])
    plot(10:11,[V_numeric(1:7,10)' ;A_numeric(1:7,11)'],'Color', [0.8  1 0.8], 'LineStyle', '--')
    plot(A_numeric(1:7,:)','Color', [0.8  1 0.8])

    plot(nanmean(V_numeric(1:7,:)',2),'Color', [0 0.5 0],'LineWidth',2)
    plot(10:11,mean([V_numeric(1:7,10)' ;A_numeric(1:7,11)'],2),'Color', [0.2 0.5 0.2], 'LineStyle', '--','LineWidth',2)
    h1=plot(nanmean(A_numeric(1:7,:)',2),'Color', [0 0.5 0],'LineWidth',2);


    plot(A_numeric(10:14,:)','Color', [0.8 0.8 0.8])
    h2=plot(nanmean(A_numeric(10:14,:)',2),'Color', [0.4 0.4 0.4],'LineWidth',2);
    % xline(11,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
    legend([h1, h2],{'V-A, n=7','only A, n=5'})
 
    if u==1
        ylabel('stim to move (s)')
        ylabel('reaction time (s)')

    else
        ylabel('stim to reward (s)')
    end
    xlabel('training days ')
xlim([0 28])

    ax = gca;
    ylim1 = ax.YLim;
    bg1 =rectangle('Position', [0, ylim1(1), 10.5, diff(ylim1)], 'FaceColor', '#DAE3F3', 'EdgeColor', 'none');
    uistack(bg1, 'bottom');
    bg2 =rectangle('Position', [10.5, ylim1(1), 17.5, diff(ylim1)], 'FaceColor','#FFB2B2' , 'EdgeColor', 'none');
    uistack(bg2, 'bottom');
uistack(ax, 'top');
ax.Layer = 'top';


end

saveas(gcf,[Path 'figures\behaviors_plot_reaction time_VA'], 'jpg');

%% 行为学比较  A-V & only V


figure('Position',[50 50 400 1400]);
% 创建一个示例的4x5的cell矩阵A
for u=1:2
    if u==1
        V_data = buffer.data_A_task_s2m;
        A_data = buffer.data_V_task_s2m;
    else
        V_data = buffer.data_A_task_rxt;
        A_data = buffer.data_V_task_rxt;
    end
    % 创建一个示例的4x5的cell矩阵A
    % 对矩阵进行操作
    V_data = cellfun(@(row) [row(cellfun('isempty', row)), row(~cellfun('isempty', row))], ...
        num2cell(V_data, 2), 'UniformOutput', false);
    % 把结果从 cell 数组转换回矩阵
    V_data = vertcat(V_data{:});
    V_filled = cellfun(@(x) ifelse(isempty(x), NaN, x), V_data, 'UniformOutput', false);
    % 将 cell 矩阵转换为数值矩阵
    V_numeric = cell2mat(V_filled);

    % 创建一个示例的4x5的cell矩阵A
    A_filled = cellfun(@(x) ifelse(isempty(x), NaN, x), A_data, 'UniformOutput', false);
    % 将 cell 矩阵转换为数值矩阵
    A_numeric =[nan(14,18) cell2mat(A_filled)];

    V_A=[V_numeric cell2mat(A_filled)];
    %
    % 显示调整后的矩阵
    nexttile;
    hold on
    plot(V_numeric(10:14,:)','Color', [0.8 0.8 1])
    plot(18:19,[V_numeric(10:14,18)' ;A_numeric(10:14,19)'],'Color', [0.8 0.8 1], 'LineStyle', '--')
    plot(A_numeric(10:14,:)','Color', [0.8 0.8 1])

    plot(nanmean(V_numeric(10:14,:)',2),'Color', [0 0 1],'LineWidth',2)
    plot(18:19,mean([V_numeric(10:14,18)' ;A_numeric(10:14,19)'],2),'Color', [0.5 0.5 1], 'LineStyle', '--','LineWidth',2)

    plot(A_numeric(1:9,:)','Color', [1 0.8 0.8])
    h1=plot(nanmean(A_numeric(10:14,:)',2),'Color', [0 0 1],'LineWidth',2);

    h2=plot(nanmean(A_numeric(1:9,:)',2),'Color', [1 0 0],'LineWidth',2);


    xline(19,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
    legend([h1, h2],{'A-V','only V'})
    if u==1
        ylabel('stim to move (s)')

    else
        ylabel('stim to reward (s)')
    end
    xlabel('training days ')


    ax = gca;
    ylim1 = ax.YLim;
    bg1 =rectangle('Position', [0, ylim1(1), 18.5, diff(ylim1)], 'FaceColor', '#FFB2B2', 'EdgeColor', 'none');
    uistack(bg1, 'bottom');
    bg2 =rectangle('Position', [18.5, ylim1(1), 9.5, diff(ylim1)], 'FaceColor','#DAE3F3' , 'EdgeColor', 'none');
    uistack(bg2, 'bottom');









end


saveas(gcf,[Path 'figures\behaviors_plot_reaction time_AV'], 'jpg');


%%
figure;
hold on
for i=1:length(animals)
    redata_b=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), buffer.data_basline_lcr{i}, 'UniformOutput', false);
   buf_b= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_b, 'UniformOutput', false);
   peak_b=cell2mat(cellfun(@(x) max(x(period_passive)),buf_b, 'UniformOutput', false));

   redata_l=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), buffer.data_V_90{i}, 'UniformOutput', false);
   buf_l= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_l, 'UniformOutput', false);
   peak_l=cell2mat(cellfun(@(x) max(x(period_passive)),buf_l, 'UniformOutput', false))';

   plot([peak_b; peak_l])
end
