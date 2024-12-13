
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';


animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
animals_group=[ 1 1 5 5 1 1 5 2 2 3 3 3 4 4 4 4 4];
% animals_group=[ 1 1 1 1 1 1 5 2 2 3 3 3 4 4 4 4 4];

% animals = {'DS014'};
% animals_group=1;

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
period_kernels=find(t_kernels>0&t_kernels<0.1);



for curr_animal=1:length(animals)
    % length(animals)
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
        buffer.data_V_task_rxt{curr_animal}{curr_idx}=raw_data_task.rxn_med(indx_V(curr_idx));
        buffer.data_V_task_s2m{curr_animal}{curr_idx}=raw_data_task.stim2move(indx_V(curr_idx));
        buffer.data_V_task_learned{curr_animal}{curr_idx}=raw_data_task.learned_day(indx_V(curr_idx));

        buffer.data_V_task_kernels{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_V(curr_idx)}(:,:,1));


        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_V(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_V_90{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end


        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_V(curr_idx)}));
        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_V_8k{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
        end
    end

    indx_A= find(raw_data_task.workflow_type==2);
    % buffer.data_A_task_rxt{curr_animal}=raw_data_task.rxn_med(indx_A);
    for curr_idx=1:length(indx_A)
        buffer.data_A_task_rxt{curr_animal}{curr_idx}=raw_data_task.rxn_med(indx_A(curr_idx));
        buffer.data_A_task_s2m{curr_animal}{curr_idx}=raw_data_task.stim2move(indx_A(curr_idx));
        buffer.data_A_task_learned{curr_animal}{curr_idx}=raw_data_task.learned_day(indx_A(curr_idx));

        buffer.data_A_task_kernels{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_A(curr_idx)}(:,:,1));

        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_A(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_A_90{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end

        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_A(curr_idx)}));

        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_A_8k{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
        end
    end

    indx_M= find(raw_data_task.workflow_type==3);
    for curr_idx=1:length(indx_M)
        buffer.data_M_task_rxt{curr_animal}{curr_idx}=raw_data_task.rxn_med(indx_M(curr_idx));
        buffer.data_M_task_s2m{curr_animal}{curr_idx}=raw_data_task.stim2move(indx_M(curr_idx));
        buffer.data_M_task_learned{curr_animal}{curr_idx}=raw_data_task.learned_day(indx_M(curr_idx));

        buffer.data_M_task_kernels{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx_M(curr_idx)}(:,:,1));

        buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx_M(curr_idx)}));
        if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
            buffer.data_M_90{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
        end

        buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx_M(curr_idx)}));
        if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
            buffer.data_M_8k{curr_animal}{curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
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

    result_p = cellfun(@(x) find(cell2mat(x)==1), learned_var, 'UniformOutput', false);
    result_n = cellfun(@(x) find(cell2mat(x)==0), learned_var, 'UniformOutput', false);

    idx_p=cellfun(@ isempty,result_p,'UniformOutput',true);
    result_n=cellfun(@(x) x(1:min(end,5)), result_n,'UniformOutput',false )  ;

    result_p(idx_p)=result_n(idx_p);
    last_5=cellfun(@(x) x(max(end-4,1):end), result_p,'UniformOutput',false);
    result_sort=cellfun(@(x,y) x(y),data_var,last_5,'UniformOutput',false);

    buf_v=cell(length(result_sort),1);
    for s=1:length(result_sort)
        if isempty(result_sort{s})
            buf_v{s}=[];
        else  buf_v{s}= mean( cat(4,result_sort{s}{:}),4);
        end
    end


    buffer.(data_var_mean)= buf_v;
    buffer.(redata_var)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), buffer.(data_var_mean), 'UniformOutput', false);

    % buf= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),  buffer.(redata_var), 'UniformOutput', false);
    buf_v=cell(length(buffer.(redata_var)),1);
    for s=1:length(buffer.(redata_var))
        if isempty(buffer.(redata_var){s})
            buf_v{s}=single(zeros(1,size(buffer.(redata_var){1},2)));
        else  buf_v{s}= mean( buffer.(redata_var){s}(roi1(1).data.mask(:),:),1);
        end
    end

    buffer.(cross_time_var)=permute(cat(3,buf_v{:}),[2,3,1]);

    %计算 behavior的reaction time的平均
    if strcmp(suffixes{i},'V_90')
        last5rxt_V = cellfun(@(row, idx) row(idx), buffer.data_V_task_rxt, last_5, 'UniformOutput', false);
        last5s2m_V = cellfun(@(row, idx) row(idx), buffer.data_V_task_s2m, last_5, 'UniformOutput', false);

        buffer.data_V_task_rxt_mean= cell2mat( cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5rxt_V, 'UniformOutput', false));
        buffer.data_V_task_s2m_mean= cell2mat( cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5s2m_V, 'UniformOutput', false));



    elseif strcmp(suffixes{i},'A_8k')
        last5rxt_A = cellfun(@(row, idx) row(idx), buffer.data_A_task_rxt, last_5, 'UniformOutput', false);
          last5s2m_A = cellfun(@(row, idx) row(idx), buffer.data_A_task_s2m, last_5, 'UniformOutput', false);

        buffer.data_A_task_rxt_mean=  cell2mat(cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5rxt_A, 'UniformOutput', false));
        buffer.data_A_task_s2m_mean=  cell2mat(cellfun(@(matrices) mean(cat(5, matrices{:}), 5), last5s2m_A, 'UniformOutput', false));

    end

end


%%
suffixes3 = {'basline_lcr','basline_hml'};

for i = 1:length(suffixes3)
    data_var=evalin('base',['buffer.data_', suffixes3{i}]);
    data_var_mean=[ 'data_',suffixes3{i},'_mean'];
    redata_var=['redata_', suffixes3{i}];
    cross_time_var=['cross_time_', suffixes3{i}];
 
    buffer.(data_var_mean)= cellfun(@(x) mean(cat(4,x{:}),4),data_var,'UniformOutput', false);
    buffer.(redata_var)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), buffer.(data_var_mean), 'UniformOutput', false);
    buf= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),  buffer.(redata_var), 'UniformOutput', false);
    buffer.(cross_time_var)=permute(cat(3,buf{:}),[2,3,1]);


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
    % clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
    clim(0.003.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('visual passive')
saveas(gcf,[Path 'figures\image in visual passive of each mice'], 'jpg');

figure('Position',[50 50 1400 500]);
for i=1:length(buffer.data_V_90_mean  )
    nexttile
    basline_mean=mean(cat(4,buffer.data_basline_lcr{i}{:}),4);
    buffer_image_V=mean(basline_mean(:,:,period_passive) ,3);
    imagesc(buffer_image_V)
    axis image off;
    ap.wf_draw('ccf','black');
    % clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
    clim(0.003.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('visual passive')
saveas(gcf,[Path 'figures\image in baseline visual passive of each mice'], 'jpg');

figure('Position',[50 50 1400 500]);
for i=1:length(buffer.data_A_8k_mean  )
    nexttile
    buffer_image_V=mean(buffer.data_A_8k_mean{i}(:,:,period_passive) ,3);
    imagesc(buffer_image_V)
    axis image off;
    ap.wf_draw('ccf','black');
    % clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
    clim(0.002.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('audio passive')
saveas(gcf,[Path 'figures\image in audio passive of each mice'], 'jpg');

figure('Position',[50 50 1400 500]);
for i=1:length(buffer.data_V_90_mean  )
    nexttile
    basline_mean=mean(cat(4,buffer.data_basline_hml{i}{:}),4);
    buffer_image_A=mean(basline_mean(:,:,period_passive) ,3);
    imagesc(buffer_image_A)
    axis image off;
    ap.wf_draw('ccf','black');
    % clim(max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
    clim(0.003.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
end
sgtitle('audio passive baseline')
saveas(gcf,[Path 'figures\image in baseline audio passive of each mice'], 'jpg');

%% wide imaging of whole brain of averaged mice
animals_group=[ 1 1 1 1 1 1 5 2 2 3 3 3 4 4 4 4 4];

selected_group=4;
scale_all=0.003;

figure('Position',[50 50 1500 900]);
a1=nexttile(1)
selected_data_baseline_lcr=buffer.data_basline_lcr (find(animals_group== selected_group));
last_data_lcr=cellfun(@(last1) mean(cat(4,last1{:}),4) ,selected_data_baseline_lcr,'UniformOutput',false );
mean_image_basline_lcr=mean(cat(4,last_data_lcr{:}),4);
buffer_image_basline_lcr=max(mean_image_basline_lcr(:,:,period_passive),[] ,3);
imagesc(buffer_image_basline_lcr);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a1,ap.colormap('WB'));
title ('stage 0 of visual passive stimlus','FontSize',14,'FontWeight','normal')

a2=nexttile(2+(selected_group>=3))
selected_data_V_90=buffer.data_V_90(find(animals_group== selected_group));
data_b=cellfun(@(x) x(max(1,end-4):end),selected_data_V_90,'UniformOutput',false);
data_b1=cellfun(@(x) mean(cat(4,x{:}),4),data_b,'UniformOutput',false);
mean_image_V1=mean(cat(4,data_b1{:}),4);
buffer_image_V=max(mean_image_V1(:,:,period_passive),[] ,3);
imagesc(buffer_image_V);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.3*max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a2,ap.colormap('WB'));
title (['stage ' num2str(1+(selected_group>=3))  ' of visual passive stimlus'],'FontSize',14,'FontWeight','normal')

a3=nexttile(3-(selected_group>=3))
selected_data_A_90=buffer.data_A_90 (find(animals_group== selected_group));
data_b=cellfun(@(x) x(max(1,end-4):end),selected_data_A_90,'UniformOutput',false);
data_b1=cellfun(@(x) mean(cat(4,x{:}),4),data_b,'UniformOutput',false);
mean_image_V2=mean(cat(4,data_b1{:}),4);
buffer_image_V=max(mean_image_V2(:,:,period_passive),[] ,3);
imagesc(buffer_image_V);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.3*max(buffer_image_V,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a3,ap.colormap('WB'));
title (['stage ' num2str(2-(selected_group>=3))  ' of visual passive stimlus'],'FontSize',14,'FontWeight','normal')


a4=nexttile(4)
selected_data_baseline_hml=buffer.data_basline_hml (find(animals_group== selected_group));
last_data_hml=cellfun(@(last1) mean(cat(4,last1{:}),4) ,selected_data_baseline_hml,'UniformOutput',false );
mean_image_basline_hml=mean(cat(4,last_data_hml{:}),4);
buffer_image_basline_hml=max(mean_image_basline_hml(:,:,period_passive),[] ,3);
imagesc(buffer_image_basline_hml);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a4,ap.colormap('WR'));
title ('stage 0 of auditory passive stimlus','FontSize',14,'FontWeight','normal')


a5=nexttile((5+(selected_group>=3)))
selected_data_V_8k=buffer.data_V_8k (find(animals_group== selected_group));
data_b=cellfun(@(x) x(max(1,end-4):end),selected_data_V_8k,'UniformOutput',false);
data_b1=cellfun(@(x) mean(cat(4,x{:}),4),data_b,'UniformOutput',false);
mean_image_A1=mean(cat(4,data_b1{:}),4);
buffer_image_A=max(mean_image_A1(:,:,period_passive),[] ,3);
imagesc(buffer_image_A);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a5,ap.colormap('WR'));
title (['stage ' num2str(1+(selected_group>=3))  ' of audio passive stimlus'],'FontSize',14,'FontWeight','normal')


a6=nexttile(6-(selected_group>=3))
selected_data_A_8k=buffer.data_A_8k (find(animals_group== selected_group));
data_b=cellfun(@(x) x(max(1,end-4):end),selected_data_A_8k,'UniformOutput',false);
data_b1=cellfun(@(x) mean(cat(4,x{:}),4),data_b,'UniformOutput',false);
mean_image_A2=mean(cat(4,data_b1{:}),4);
buffer_image_A=max(mean_image_A2(:,:,period_passive),[] ,3);
imagesc(buffer_image_A);
axis image off;
ap.wf_draw('ccf','black');
% clim(0.7*max(buffer_image_A,[],'all').*[-1,1]); colormap(ap.colormap('PWG'));
clim(scale_all.*[0,1]); colormap(a6,ap.colormap('WR'));
title (['stage ' num2str(2-(selected_group>=3))  ' of audio passive stimlus'],'FontSize',14,'FontWeight','normal')

% cbar1 = colorbar(a6,'Location','southoutside');
% cbar1.Ticks = scale_all.*[0,1]; % 只显示最小值和最大值
% cbar1.FontSize = 12;
% cbar1.Label.String = 'dF/F'; % 设置colorbar的名称

sgtitle(['passive stim in group ' num2str(selected_group) ' (0-200ms)'])
saveas(gcf,[Path 'figures\averaged mice in visual auditory pre post_' num2str(selected_group)], 'jpg');

%% 做视频 小鼠平均
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
   % 标签数组，包含每个阶段的标签
labels = {'visual stage 0', 'visual stage 1', 'visual stage 2', ...
          'auditory stage 0', 'auditory stage 1', 'auditory stage 2'};

% 将视觉和听觉图像拼接成 2 行 3 列的矩阵图像
if selected_group >= 3
   image_data = {mean_image_basline_lcr(:,:,k), mean_image_V2(:,:,k), mean_image_V1(:,:,k), ...
              mean_image_basline_hml(:,:,k), mean_image_A2(:,:,k), mean_image_A1(:,:,k)};
else
    image_data = {mean_image_basline_lcr(:,:,k), mean_image_V1(:,:,k), mean_image_V2(:,:,k), ...
              mean_image_basline_hml(:,:,k), mean_image_A1(:,:,k), mean_image_A2(:,:,k)};
end
% 图像数组，包含所有图像


% 处理图像，插入标签
image_with_labels = cell(1,6);  % 用于存储处理后的带标签的图像
labelHeight = 50;  % 标签区域高度

for i = 1:6
    % 当前图像
    imagesc(image_data{i});
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
    img_with_label = insertText(img_with_label, [imgWidth/2, labelHeight/2], labels{i}, 'FontSize', 18, ...
        'BoxColor', 'white', 'BoxOpacity', 1, 'TextColor', 'black', 'AnchorPoint', 'Center');
    % 保存处理后的图像
    image_with_labels{i} = img_with_label;
end

% 将视觉和听觉图像拼接成 2 行 3 列的矩阵图像

    image_all = [image_with_labels{1}, image_with_labels{2}, image_with_labels{3}; ...
                 image_with_labels{4}, image_with_labels{5}, image_with_labels{6}];

% 添加标题并保存到视频中
[height, width, ~] = size(image_all);
titleHeight = 30;  
newImage = uint8(zeros(height + titleHeight, width, 3));
newImage(titleHeight+1:end, :, :) = image_all;
newImage(1:titleHeight, :, :) = 255;

position = [width/2, titleHeight/2];  
titleText = ['Averaged mice group' num2str(selected_group) ':' num2str(t_passive(k)) 's'];
newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
    'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
    'AnchorPoint', 'Center');

writeVideo(video, newImageWithText);
close all

end

% 关闭 VideoWriter 对象
close(video);
disp('视频保存完成。');



%% wide imaging of whole brain of averaged mice in task kernels 

selected_group=1;
scale_all=0.005;

suffixes_kernels = {'data_V_task_kernels','data_A_task_kernels'};
titles={'stage 1 fisrt 3 days','stage 1 last 3 days','stage 2 first 3 days','stage 2 last 3 days'};
tt=0;
figure('Position',[50 50 1500 400]);
for ii=1:2
    data_var=evalin('base',['buffer.', suffixes_kernels{ii}]);
    selected_data=data_var (find(animals_group== selected_group));
    for iii=1:2
        tt=tt+1;
        if iii==1
            data_b=cellfun(@(x) x(1:3),selected_data,'UniformOutput',false);
        elseif iii==2
            data_b=cellfun(@(x) x(max(1,end-2):end),selected_data,'UniformOutput',false);
        end
    

nexttile

data_b1=cellfun(@(x) mean(cat(4,x{:}),4),data_b,'UniformOutput',false);
mean_image=mean(cat(4,data_b1{:}),4);
buffer_image=max(mean_image(:,:,period_kernels),[] ,3);
imagesc(buffer_image);
axis image off;
ap.wf_draw('ccf','black');
clim(scale_all.*[0,1]); colormap(ap.colormap('WG'));
title (titles{tt},'FontSize',14,'FontWeight','normal')

    end
end
sgtitle(['task kernels in group ' num2str(selected_group) ' (0-100ms)'])
saveas(gcf,[Path 'figures\averaged mice in task kernels pre post_' num2str(selected_group)], 'jpg');


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





%% 做视频 单个小鼠
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

    imagesc(mean_image_V1(:,:,k));
    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image_v1 = frame.cdata;

    % ap.imscroll(mean_image_A(:,:,k),t_passive(k));
    imagesc(mean_image_A1(:,:,k));

    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image_a1 = frame.cdata;

    %  ap.imscroll((v_v_avg_l(:,:,k)-a_a_avg_l(:,:,k)),t(k));
    % axis image off;
    %  ap.wf_draw('ccf','black');
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % % 获取当前图像帧
    % frame = getframe(gca);
    % % 提取图像数据
    % image3 = frame.cdata;



    image_all=[image_v1 image_a1 ];



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
imagesc(max(mean_image_V1(:,:,period_passive),[],3));
ap.wf_draw('ccf','black');
axis image off;
% clim(0.3*max(buffer_image_V,[],'all').*[0,1]); colormap(ap.colormap('WR'));
clim(scale_all.*[0,1]); colormap(ap.colormap('WR'));
% colorbar
saveas(gcf,[Path 'figures\merged_image_audio' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');
frame1 = getframe(gcf);
img_data1 =im2double( frame1.cdata);

figure;
imagesc(max(mean_image_A1(:,:,period_passive),[],3));
axis image off;
% clim(0.7*max(buffer_image_A,[],'all').*[0,1]); colormap(ap.colormap('WG'));
clim(scale_all.*[0,1]); colormap(ap.colormap('WG'));
% colorbar
saveas(gcf,[Path 'figures\merged_image_visual' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');
frame2 = getframe(gcf);
img_data2 =im2double( frame2.cdata);


result_p = min(img_data1, img_data2);
imshow(result_p);
saveas(gcf,[Path 'figures\merged_image_V_A' strjoin(animals(find(animals_group==selected_group)), '_')], 'jpg');


figure;
a1=subplot(1,2,1)
imagesc(max(mean_image_V1(:,:,period_passive),[],3));
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
imagesc(max(mean_image_A1(:,:,period_passive),[],3));
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
data_audio=max(mean_image_A1(:,:,period_passive),[],3);
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

data_visual=max(mean_image_V1(:,:,period_passive),[],3);
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
for i=1:length(suffixes3)
    cross_time_var=['cross_time_', suffixes3{i}];
    nexttile(i+length(suffixes))
    imagesc( buffer.(cross_time_var)')
    set(gca, 'YTick', 1:length(animals), 'YTickLabel', animals);
    clim(0.002*[0,1]);
    title(strrep(suffixes3{i},'_','-'))
    colormap( nexttile(i+length(suffixes)),ap.colormap('WG'))
end
sgtitle('mPFC activity')
saveas(gcf,[Path 'figures\averaged acitvity of mPFC of single mouse'], 'jpg');




%% single trial
figure('Position',[50 50 1200 1200]);
colors = zeros(length(animals_group), 3); % 初始化颜色数组为全黑
colors(animals_group == 1, :) = repmat([1 0 0], sum(animals_group == 1), 1); % 将C为1的位置设置为红色
colors(animals_group == 2, :) = repmat([1 0.8 0.8], sum(animals_group == 2), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 3, :) = repmat([0.8 0.8 1], sum(animals_group == 3), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 4, :) = repmat([0 0 1], sum(animals_group == 4), 1); % 将C为0的位置设置为蓝色

suffixes2 = {'V_90','A_90','V_8k','A_8k'};
for ii=1:4
    data_var=evalin('base',['buffer.data_', suffixes2{ii}]);
    data_rxt=evalin('base',['buffer.data_', suffixes2{ii}(1:end-2) 'task_rxt']);

    computeRow=@(x)  reshape(x,size(x,1)*size(x,2),size(x,3));
redata_V_90 = cellfun(@(cellArray) cellfun(computeRow, cellArray, 'UniformOutput', false), data_var, 'UniformOutput', false);
isEmpty = cellfun(@(cellArray) ~cellfun('isempty', cellArray), data_var, 'UniformOutput', false);
cross_time_V_90 =cellfun(@(X,Y) cellfun(@(x)  mean(x(roi1(1).data.mask(:),:),1)  ,X(Y) , 'UniformOutput', false)           ,redata_V_90,isEmpty, 'UniformOutput', false);
max_cross_time_V_90=  cellfun(@(cellArray) cellfun(@(x) max(x(:,period_passive),[],2), cellArray), cross_time_V_90, 'UniformOutput', false);
rxt_V_90 =cellfun(@(X,Y) cell2mat(X(Y))  ,data_rxt,isEmpty, 'UniformOutput', false);

  
 
    nexttile
    % 5. 使用 scatter 绘图
    hold on;
    for i = 1:length(animals)
        scatter(1./rxt_V_90{i}, max_cross_time_V_90{i}, [], colors(i, :), 'filled');
        % plot(1./rxt_V_90(rowIndices == i), max_cross_time_V_90(rowIndices == i), 'o-', 'Color', colors(i, :), 'MarkerFaceColor', colors(i, :));

    end
    xlabel('1 / reaction time(s)')
    ylabel('dF/F in mPFC')
    title(['mPFC activity in ' strrep(suffixes2{ii},'_','-') ' vs behavioral reaction time'])
    hold off;
end
legend(animals, 'Location', 'best');

saveas(gcf,[Path 'figures\acitvity of mPFC vs behaviorsin single trial'], 'jpg');


% scatter(buffer.data_V_task_rxt_mean ,max(all_data.cross_time_V_90(period_passive,:) ,[],1) )


%%
figure('Position',[50 50 1200 500]);
% animals_group=[ 1 1 1 1 1 1 2 2 2 3 3 3 4 3];
colors = zeros(length(animals_group), 3); % 初始化颜色数组为全黑
colors(animals_group == 1, :) = repmat([1 0 0], sum(animals_group == 1), 1); % 将C为1的位置设置为红色
colors(animals_group == 2, :) = repmat([1 0.8 0.8], sum(animals_group == 2), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 3, :) = repmat([0.8 0.8 1], sum(animals_group == 3), 1); % 将C为0的位置设置为蓝色
colors(animals_group == 4, :) = repmat([0 0 1], sum(animals_group == 4), 1); % 将C为0的位置设置为蓝色

% find(animals_group~=3)

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
xlim([0 4])
ylim([0 4])
xline(0.5)
yline(0.5)
hold on
x=0:4
y=x;
plot(x,y)
saveas(gcf,[Path 'figures\behavior V vs behavior A'], 'jpg');

figure;
scatter(max(buffer.cross_time_V_90(period_passive,:) ,[],1) ,max(buffer.cross_time_A_8k(period_passive,:) ,[],1),[], colors, 'filled' )
text(max(buffer.cross_time_V_90(period_passive,:) ,[],1), max(buffer.cross_time_A_8k(period_passive,:) ,[],1), animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
xlabel('mPFC in visual passive');ylabel('mPFC in auditory passive');
xlim([-0.0005 0.003])
ylim([-0.0005 0.003])
hold on
x=-1:3
y=x;
plot(x,y)
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


% %% 行为学比较  V-A & only A
% 
% figure('Position',[50 50 450 250]);
% 
% % 创建一个示例的4x5的cell矩阵A
% for u=1
%     if u==1
%         V_data = buffer.data_V_task_s2m;
%         A_data = buffer.data_A_task_s2m;
%     else
%         V_data = buffer.data_V_task_rxt;
%         A_data = buffer.data_A_task_rxt;
%     end
%     % 对矩阵进行操作
%     V_data = cellfun(@(row) [row(cellfun('isempty', row)), row(~cellfun('isempty', row))], ...
%         num2cell(V_data, 2), 'UniformOutput', false);
%     % 把结果从 cell 数组转换回矩阵
%     V_data = vertcat(V_data{:});
%     V_filled_pre = cellfun(@(x) ifelse(isempty(x), NaN, x), V_data, 'UniformOutput', false);
%     % 将 cell 矩阵转换为数值矩阵
%     V_numeric = cell2mat(V_filled_pre);
% 
%     % 创建一个示例的4x5的cell矩阵A
%     A_filled_post = cellfun(@(x) ifelse(isempty(x), NaN, x), A_data, 'UniformOutput', false);
%     % 将 cell 矩阵转换为数值矩阵
%     A_numeric =[nan(14,10) cell2mat(A_filled_post)];
% 
%     V_A=[V_numeric cell2mat(A_filled_post)];
%     %
%     % 显示调整后的矩阵
% 
%     nexttile
%     hold on
%     plot(V_numeric(1:7,:)','Color', [0.8  1 0.8])
%     plot(10:11,[V_numeric(1:7,10)' ;A_numeric(1:7,11)'],'Color', [0.8  1 0.8], 'LineStyle', '--')
%     plot(A_numeric(1:7,:)','Color', [0.8  1 0.8])
% 
%     plot(nanmean(V_numeric(1:7,:)',2),'Color', [0 0.5 0],'LineWidth',2)
%     plot(10:11,mean([V_numeric(1:7,10)' ;A_numeric(1:7,11)'],2),'Color', [0.2 0.5 0.2], 'LineStyle', '--','LineWidth',2)
%     h1=plot(nanmean(A_numeric(1:7,:)',2),'Color', [0 0.5 0],'LineWidth',2);
% 
% 
%     plot(A_numeric(10:14,:)','Color', [0.8 0.8 0.8])
%     h2=plot(nanmean(A_numeric(10:14,:)',2),'Color', [0.4 0.4 0.4],'LineWidth',2);
%     % xline(11,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
%     legend([h1, h2],{'V-A, n=7','only A, n=5'})
% 
%     if u==1
%         ylabel('stim to move (s)')
%         ylabel('reaction time (s)')
% 
%     else
%         ylabel('stim to reward (s)')
%     end
%     xlabel('training days ')
%     xlim([0 28])
% 
%     ax = gca;
%     ylim1 = ax.YLim;
%     bg1 =rectangle('Position', [0, ylim1(1), 10.5, diff(ylim1)], 'FaceColor', '#DAE3F3', 'EdgeColor', 'none');
%     uistack(bg1, 'bottom');
%     bg2 =rectangle('Position', [10.5, ylim1(1), 17.5, diff(ylim1)], 'FaceColor','#FFB2B2' , 'EdgeColor', 'none');
%     uistack(bg2, 'bottom');
%     uistack(ax, 'top');
%     ax.Layer = 'top';
% 
% 
% end
% 
% saveas(gcf,[Path 'figures\behaviors_plot_reaction time_VA'], 'jpg');

%% 行为学比较  A-V & only V


figure('Position',[50 50 800 1400]);
% 创建一个示例的4x5的cell矩阵A
for u=1:2
    if u==1
        V_data = buffer.data_V_task_s2m;
        A_data = buffer.data_A_task_s2m;
    else
        V_data = buffer.data_V_task_rxt;
        A_data = buffer.data_A_task_rxt;
    end
    % 创建一个示例的4x5的cell矩阵A
    % 对矩阵进行操作
    V_data = cellfun(@(x) cell2mat(x), V_data, 'UniformOutput', false);
    % 1. 获取最长向量的长度
    max_len_V = max(cellfun(@numel, V_data));
    % 2. 使用 NaN 填充较短的向量
    V_filled_pre = cellfun(@(x) padarray(x, [0 max_len_V-numel(x)], NaN, 'pre'), V_data, 'UniformOutput', false);
    V_filled_post = cellfun(@(x) padarray(x, [0 max_len_V-numel(x)], NaN, 'post'), V_data, 'UniformOutput', false);


  % 对矩阵进行操作
    A_data = cellfun(@(x) cell2mat(x), A_data, 'UniformOutput', false);
    % 1. 获取最长向量的长度
    max_len_A = max(cellfun(@numel, A_data));
    % 2. 使用 NaN 填充较短的向量
    A_filled_post = cellfun(@(x) padarray(x, [0 max_len_A-numel(x)], NaN, 'post'), A_data, 'UniformOutput', false);
    A_filled_pre = cellfun(@(x) padarray(x, [0 max_len_A-numel(x)], NaN, 'pre'), A_data, 'UniformOutput', false);

    % 3. 将 cell 数组转换为二维矩阵
    
    A_only=[nan(length(V_data),max_len_V) cell2mat(A_filled_post')]';
    V_only=[nan(length(A_data),max_len_A) cell2mat(V_filled_post')]';

    V_A=[cell2mat(V_filled_pre') cell2mat(A_filled_post')]';
    A_V=[ cell2mat(A_filled_pre') cell2mat(V_filled_post')]';
    %
    % 显示调整后的矩阵
     nexttile;
     VA_plot=V_A(:,find(animals_group==1));
     VA_plot_p = VA_plot(find(any(~isnan(VA_plot), 2), 1):end, :);
    A_only_plot=A_only(:,find(animals_group==4));
    A_only_plot_p = A_only_plot(find(any(~isnan(VA_plot), 2), 1):find(any(~isnan(A_only_plot), 2), 1, 'last'), :);

    xlim([1 size(A_only_plot_p,1)])


    hold on
    plot(VA_plot_p,'Color', [0.8 0.8 1]);
   h1= plot(nanmean(VA_plot_p,2),'Color', [0 0 1],'LineWidth',2);
    plot(A_only_plot_p,'Color', [1 0.8 0.8]);
   h2= plot(nanmean(A_only_plot_p,2),'Color', [1 0 0],'LineWidth',2);

    % xline(max_len_V,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
    legend([h1, h2],{['V-A, n=' num2str(sum(animals_group==1)) ],['only A, n=' num2str(sum(animals_group==4)) ]});
    if u==1
        ylabel('stim to move (s)')

    else
        ylabel('stim to reward (s)')
    end
    xlabel('training days ')

    
    ax = gca;
    ylim1 = ax.YLim;
    bg1 =rectangle('Position', [0, ylim1(1), find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)+0.5, diff(ylim1)], 'FaceColor', '#FFB2B2', 'EdgeColor', 'none');
    uistack(bg1, 'bottom');
    bg2 =rectangle('Position', [find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)+0.5, ylim1(1), find(any(~isnan(A_only_plot), 2), 1, 'last')-find(any(~isnan(A_only_plot), 2), 1)+1, diff(ylim1)], 'FaceColor','#DAE3F3' , 'EdgeColor', 'none');
    uistack(bg2, 'bottom');

% find(isnan(A_only(:,find(animals_group==4))))


  nexttile;
      AV_plot=A_V(:,find(animals_group==4));
     AV_plot_p = AV_plot(find(any(~isnan(AV_plot), 2), 1):end, :);

    V_only_plot=V_only(:,find(animals_group==1));
    V_only_plot_p = V_only_plot(find(any(~isnan(AV_plot), 2), 1):find(any(~isnan(V_only_plot), 2), 1, 'last'), :);

    xlim([1 size(V_only_plot_p,1)])


    hold on
     plot(AV_plot_p,'Color', [0.8 0.8 1]);
    h1= plot(nanmean(AV_plot_p,2),'Color', [0 0 1],'LineWidth',2);
    plot(V_only_plot_p,'Color', [1 0.8 0.8]);
   h2= plot(nanmean(V_only_plot_p,2),'Color', [1 0 0],'LineWidth',2);

    % xline(max_len_V,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
    legend([h1, h2],{['A-V, n=' num2str(sum(animals_group==4)) ],['only V, n=' num2str(sum(animals_group==1)) ]});
    if u==1
        ylabel('stim to move (s)')

    else
        ylabel('stim to reward (s)')
    end
    xlabel('training days ')


    ax = gca;
    ylim1 = ax.YLim;
    bg1 =rectangle('Position', [0, ylim1(1), find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)+0.5, diff(ylim1)], 'FaceColor', '#FFB2B2', 'EdgeColor', 'none');
    uistack(bg1, 'bottom');
    bg2 =rectangle('Position', [find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)+0.5, ylim1(1), find(any(~isnan(V_only_plot), 2), 1, 'last')-find(any(~isnan(V_only_plot), 2), 1)+1, diff(ylim1)], 'FaceColor','#DAE3F3' , 'EdgeColor', 'none');
    uistack(bg2, 'bottom');






end

saveas(gcf,[Path 'figures\behaviors_plot_reaction time_VA_AV'], 'jpg');


%% peak mPFC in lcr passive plot across day.
scale_all=0.003;
figure;
for i=1:length(animals)
    zero_matrix = zeros(450, 426, 53, 'single');
    % 使用 cellfun 遍历数组并填充空元素
    buf_lcr_V_90 = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_V_90{i}, 'UniformOutput', false);
    buf_lcr_A_90 = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_A_90{i}, 'UniformOutput', false);

    buf_base=cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_basline_lcr{i}, 'UniformOutput', false);

    redata_lcr=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base;buf_lcr_V_90(max(1,end-4):end)'], 'UniformOutput', false);
    buf_v= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_lcr, 'UniformOutput', false);
    peak_v=cell2mat(cellfun(@(x) max(x(period_passive)),buf_v, 'UniformOutput', false));
    nexttile
    buf_v_mat=permute(cat(3,buf_v{:}),[3 2 1]);
    imagesc(buf_v_mat)
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
    plt{i}=peak_v;
    aver_buf_b_v{i}=buf_v_mat;
end

nexttile
for i=1:length(animals)
    hold on
    plot(plt{i})
end


%% peak mPFC in hml passive plot across day.
scale_all=0.002;

figure;
for i=1:length(animals)
    zero_matrix = zeros(450, 426, 53, 'single');
    % 使用 cellfun 遍历数组并填充空元素
    buf_hml = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_A_8k{i}, 'UniformOutput', false);
    buf_base=cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_basline_hml{i}, 'UniformOutput', false);
    redata_lcr=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base;buf_hml(max(1,end-4):end)'], 'UniformOutput', false);
    buf_v= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_lcr, 'UniformOutput', false);
    peak_v=cell2mat(cellfun(@(x) max(x(period_passive)),buf_v, 'UniformOutput', false));
    nexttile
    buf_v_mat=permute(cat(3,buf_v{:}),[3 2 1]);

    imagesc(buf_v_mat)
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));

    title(animals{i})
    plt_hml{i}=peak_v;
    aver_buf_b_a{i}=buf_v_mat;

end
nexttile
for i=1:length(animals)
    hold on
    plot(plt_hml{i})
end


%% 平均 小鼠mPFC在cross day中 mPFC 的 meatmap和plot
 
animals_group=[ 1 1 1 1 1 1 1 2 2 4 3 3 4 4 4 4 4];
selected_group=1;
figure;
for i=1:length(animals)
    zero_matrix = zeros(450, 426, 53, 'single');
    % 使用 cellfun 遍历数组并填充空元素
    buf_lcr_V_90 = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_V_90{i}, 'UniformOutput', false);

    buf_lcr_A_90 = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_A_90{i}, 'UniformOutput', false);
    buf_lcr_V_8k = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_V_8k{i}, 'UniformOutput', false);
    buf_lcr_A_8k = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_A_8k{i}, 'UniformOutput', false);
    buf_base_lcr=cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_basline_lcr{i}, 'UniformOutput', false);
    buf_base_hml=cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_basline_hml{i}, 'UniformOutput', false);

    buf_lcr_V_task_kernels = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_V_task_kernels{i}, 'UniformOutput', false);
    buf_lcr_A_task_kernels = cellfun(@(x) ifelse(isempty(x), zero_matrix, x), buffer.data_A_task_kernels{i}, 'UniformOutput', false);

if animals_group(i)<=2  
    redata_lcr=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base_lcr;buf_lcr_V_90(max(1,end-4):end)';buf_lcr_A_90(1:5)'], 'UniformOutput', false);
    redata_hml=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base_hml;buf_lcr_V_8k(max(1,end-4):end)';buf_lcr_A_8k(1:5)'], 'UniformOutput', false);
    redata_task_kernels=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_lcr_V_task_kernels(max(1,end-4):end)';buf_lcr_A_task_kernels(1:5)'], 'UniformOutput', false);
elseif animals_group(i)==3|animals_group(i)==4
     redata_lcr=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base_lcr;buf_lcr_A_90(max(1,end-4):end)';buf_lcr_V_90(1:5)'], 'UniformOutput', false);
    redata_hml=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_base_hml;buf_lcr_A_8k(max(1,end-4):end)';buf_lcr_V_8k(1:5)'], 'UniformOutput', false);
    redata_task_kernels=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), [buf_lcr_A_task_kernels(max(1,end-4):end)';buf_lcr_V_task_kernels(1:5)'], 'UniformOutput', false);

end

    buf_v= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_lcr, 'UniformOutput', false);
    peak_v=cell2mat(cellfun(@(x) max(x(period_passive)),buf_v, 'UniformOutput', false));
    buf_v_mat=permute(cat(3,buf_v{:}),[3 2 1]);
    plt_v{i}=peak_v;
    aver_buf_b_v{i}=buf_v_mat;

    buf_a= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_hml, 'UniformOutput', false);
    peak_a=cell2mat(cellfun(@(x) max(x(period_passive)),buf_a, 'UniformOutput', false));
    buf_a_mat=permute(cat(3,buf_a{:}),[3 2 1]);
    plt_a{i}=peak_a;
    aver_buf_b_a{i}=buf_a_mat;

    buf_task= cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1),redata_task_kernels, 'UniformOutput', false);
    peak_task=cell2mat(cellfun(@(x) max(x(period_kernels)),buf_task, 'UniformOutput', false));
    buf_task_mat=permute(cat(3,buf_task{:}),[3 2 1]);
    plt_task{i}=peak_task;
    aver_buf_b_task{i}=buf_task_mat;

    nexttile
    imagesc(buf_v_mat)
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    title(animals{i})
    nexttile
    imagesc(buf_a_mat)
    clim(scale_all.*[-1,1]); colormap(ap.colormap('PWG'));
    title(animals{i})

    
end




V_3D=cat(3,aver_buf_b_v{(find(animals_group== selected_group))});
A_3D = cat(3,aver_buf_b_a{(find(animals_group== selected_group))});
merged_3D=cat(1,V_3D,A_3D);
valid_rows_3D = any(merged_3D ~= 0, 2); % 大小为 8x1x10
% 将有效的行按列进行累加，同时计算有效行的数量
valid_rows_3D_expanded = repmat(valid_rows_3D, 1, size(aver_buf_b_v{1},2));  % 扩展到8x50x10
sum_matrix = sum(merged_3D .* valid_rows_3D_expanded, 3);    % 按第三维度累加
count_matrix = sum(valid_rows_3D_expanded, 3);          % 统计有效行的数量
% 防止除以 0 的情况，将无效的地方置为 1，避免 NaN
count_matrix(count_matrix == 0) = 1;
% 计算平均值
result = sum_matrix ./ count_matrix;

figure('Position',[50 50 1200 500]);

nexttile
imagesc(t_passive,1:13,result(1:13,:))';
hold on;yline(3.5);yline(8.5)
ylabel('days')
xlabel('time (s)')
clim(0.002*[-1,1]);
title('visual passive')
colormap( ap.colormap('PWG'))
nexttile
imagesc(t_passive,[],result(14:end,:))';
hold on;yline(3.5);yline(8.5)

ylabel('days')
xlabel('time (s)')
title('auditory passive')
clim(0.002*[-1,1]);
colormap( ap.colormap('PWG'))


task_3D=mean(cat(3,aver_buf_b_task{(find(animals_group== selected_group))}),3);
nexttile
imagesc(t_kernels,[],task_3D)';
hold on;yline(5.5)
ylabel('days')
xlabel('time (s)')
title('task kernels')
clim(0.002*[-1,1]);
colormap( ap.colormap('PWG'))

nexttile
plot_v=plt_v(find(animals_group== selected_group));
plot_v = cellfun(@(x) subsasgn(x, struct('type', '()', 'subs', {{x == 0}}), nan), plot_v, 'UniformOutput', false);
for i=1:length(plot_v)
    hold on
plot(plot_v{i},'Color',[0.5 0.5 1],'LineWidth',0.5)
end
mean_v=nanmean(permute(cat(3,plot_v{:}),[1 ,3 ,2]),2);
sem_v=nanstd(permute(cat(3,plot_v{:}),[1 ,3 ,2])');
h1=ap.errorfill((1:length(mean_v)),mean_v, sem_v,[0,0,1],0.1,0.5);
xline(3.5);xline(8.5);
xlim([1 13])
ylim([0 0.004])
xlabel('days')
ylabel('df/f')


nexttile
plot_a=plt_a(find(animals_group== selected_group));
plot_a = cellfun(@(x) subsasgn(x, struct('type', '()', 'subs', {{x == 0}}), nan), plot_a, 'UniformOutput', false);
for i=1:length(plot_a)
    hold on
plot(plot_a{i},'Color',[1 0.5 0.5],'LineWidth',0.5)
end
mean_a=nanmean(permute(cat(3,plot_a{:}),[1 ,3 ,2]),2);
sem_a=nanstd(permute(cat(3,plot_a{:}),[1 ,3 ,2])');
h1=ap.errorfill((1:length(mean_a)),mean_a, sem_a,[1,0,0],0.1,0.5);
xline(3.5);xline(8.5);
xlim([1 13])
ylim([0 0.004])
xlabel('days')
ylabel('df/f')
sgtitle(['mPFC across days in group ' num2str(selected_group)])
saveas(gcf,[Path 'figures\averaged mPFC across in group' num2str(selected_group)], 'jpg');

nexttile
plot_a=plt_task(find(animals_group== selected_group));
plot_a = cellfun(@(x) subsasgn(x, struct('type', '()', 'subs', {{x == 0}}), nan), plot_a, 'UniformOutput', false);
for i=1:length(plot_a)
    hold on
plot(plot_a{i},'Color',[0.5 0.5 0.5],'LineWidth',0.5)
end
mean_a=nanmean(permute(cat(3,plot_a{:}),[1 ,3 ,2]),2);
sem_a=nanstd(permute(cat(3,plot_a{:}),[1 ,3 ,2])');
h1=ap.errorfill((1:length(mean_a)),mean_a, sem_a,[0,0,0],0.1,0.5);
xlim([1 10])
ylim([-0.001 0.006])
xline(5.5)
xlabel('days')
ylabel('df/f')
sgtitle(['mPFC across days in group ' num2str(selected_group)])
saveas(gcf,[Path 'figures\averaged mPFC across in group' num2str(selected_group)], 'jpg');
