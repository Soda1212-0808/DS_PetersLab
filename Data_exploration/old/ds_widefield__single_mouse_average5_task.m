
clear all
clc
% Path = 'D:\Da_Song\Data_analysis\mice\process\processed_data_v2\';
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
% animals={'DS001'}
animals_type=[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2];

animals_group = [1 1 1 1 1 1 1 2 2 3 3 3 4 4 4 4 4];

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
all_animal_period_single_day=cell(length(animals),1);
all_animal_period_kernels_single_day=cell(length(animals),1);

all_animal_sperate_4=cell(length(animals),1);

for curr_animal_idx=1:length(animals)
    main_preload_vars = who;

    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);
    raw_data_task_single=load([Path '\mat_data\task\' animal '_task_single_trial.mat']);

    fprintf('%s\n', ['File loading completed of  ' animal ]);
   
    % find learned day
    for curr_d=1:length(raw_data_task.rxn_med)
        if length(raw_data_task.rxn_med{curr_d})==1
            raw_data_task.learned_day{curr_d}=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}<0.05;
        else
           raw_data_task.learned_day{curr_d}=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}(2:3)<0.05;
        end
    % raw_data_task.learned_day= cellfun(@(x,y)  x<2 & y<0.05, raw_data_task.rxn_med,raw_data_task.rxn_stat_p,'UniformOutput',false);
    end


    % task kernels
    period_length=length(t_kernels)

    idx_task_kernels=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels  ,'UniformOutput',true);
    raw_data_task.imaging_kernels(idx_task_kernels) =cellfun(@(b) cellfun(@(c) plab.wf.svd2px(U_master,c),b,'UniformOutput',false),raw_data_task.wf_px_task_kernels ,'UniformOutput',false)  ;

 % real data
 % period_length=length(t_task);

   aligned_px_0=cellfun(@(x) x,raw_data_task_single.wf_px_task_kernels_all,'UniformOutput',false );
    aligned_px =cellfun(@(x,y) x(:,:,y ==1)  ,aligned_px_0,raw_data_task_single.wf_px_task_all_type_id,'UniformOutput',false);

 % aligned_px =cellfun(@(x,y) x(:,:,y ==1)  ,raw_data_task_single.wf_px_task_all,raw_data_task_single.wf_px_task_all_type_id,'UniformOutput',false);
  aligned_px_mean=cellfun(@(x) plab.wf.svd2px(U_master,nanmean(x,3)),aligned_px,'UniformOutput',false);
  % aligned_px_mean=cellfun(@(x) plab.wf.svd2px(U_master,x(:,:,1)),raw_data_task.wf_px_task,'UniformOutput',false);




% seperate in 4 group
aligned_px_4=cellfun(@(x,y) arrayfun(@(g) mean(x(:,:,discretize( y,[-Inf, 0.1,0.2,0.3, Inf] ) == g), 3,'omitnan'), ...
    1:4,'UniformOutput',false),aligned_px',raw_data_task_single.stim2move,'UniformOutput',false);


aligned_px_4_all= cellfun(@(x) cat(3,x{:}),aligned_px_4,'UniformOutput',false);



    if animals_type(curr_animal_idx) == 1
        order = [ 1, 2, 3];
        stage_type={'visual','auditory','mixed'};
    elseif animals_type(curr_animal_idx) == 2
        order = [2, 1, 3];
        stage_type={'auditory','visual','mixed'};
    else
        error('Unsupported value for variable. Must be 1 or 2.');
    end

    task_all_imaging_single_day=cell(1,3);
    task_all_mean_imaging_single_day=cell(1,3);
        task_all_mean_imaging_single_day_kernels=cell(1,3);

    task_all_imaging=repmat({[]}, 1, 3);
    
    task_all_seperate_4=repmat({[]}, 1, 3);

    % 处理两类分析，第一类是task kernels的分析
    idxx=0;
    for curr_order=order

        idxx=idxx+1;
        learned=1;

        % %使用 task kernels
        % imaging_task_kernels_0=raw_data_task.imaging_kernels(find(raw_data_task.workflow_type==curr_order));

        % 使用 real_data
        imaging_task_kernels_0=aligned_px_mean(find(raw_data_task.workflow_type==curr_order));

        learned_mva=cell2mat( raw_data_task.learned_day(find(raw_data_task.workflow_type==curr_order ) ));

    % stim2move period

           

        %如果是visual or auditory task
        if curr_order==1|curr_order==2
            numbers=5;
            % kernels
            if ~isempty(imaging_task_kernels_0)
                
                if ~isempty(find(learned_mva(:,1)==learned)) % if mice learned the task
                    imaging_task_kernels=imaging_task_kernels_0(find(learned_mva(:,1)==learned,numbers,"last"));
                else
                    imaging_task_kernels=imaging_task_kernels_0(max(1,end-numbers+1):end);
                end

                task_all_imaging{1,idxx}=mean(cat(4,imaging_task_kernels{:}),4);
                task_all_imaging_single_day{1,idxx}=imaging_task_kernels;

            else
                task_all_imaging{1,idxx}=single(zeros(450,426,period_length));
                task_all_imaging_single_day{1,idxx}=repmat({single(zeros(450,426,period_length))}, 1, numbers);
            end


        % stim2move period

         
            %  imaging_task_mean =px_max(find(raw_data_task.workflow_type==curr_order ));
            % imaging_task_all_sort= cellfun(@(x) cellfun(@(y) max(plab.wf.svd2px(U_master,y),[],3),x,'UniformOutput',false),imaging_task_mean(find(learned_mva(:,1)==learned,numbers,"last")) ,'UniformOutput',false);
            % imaging_task_mean_sort=cellfun(@(x) mean(cat(3,x{:}),3),imaging_task_all_sort,'UniformOutput',false );
            % task_all_mean_imaging_single_day{1,idxx}=imaging_task_mean_sort;
            % 
            % %predicted kernels
            %  imaging_task_mean_kernels =px_max_kernels(find(raw_data_task.workflow_type==curr_order ));
            % imaging_task_all_sort_kernels= cellfun(@(x) cellfun(@(y) max(plab.wf.svd2px(U_master,y),[],3),x,'UniformOutput',false),imaging_task_mean_kernels(find(learned_mva(:,1)==learned,numbers,"last")) ,'UniformOutput',false);
            % imaging_task_mean_sort_kernels=cellfun(@(x) mean(cat(3,x{:}),3),imaging_task_all_sort_kernels,'UniformOutput',false );
            % task_all_mean_imaging_single_day_kernels{1,idxx}=imaging_task_mean_sort;
            % 
        
        % seperate 4 group:
           aligned_px_4_all_1=     aligned_px_4_all(find(raw_data_task.workflow_type==curr_order ));
           aligned_px_4_all_sort= cellfun(@(x)  plab.wf.svd2px(U_master,x),aligned_px_4_all_1(find(learned_mva(:,1)==learned,numbers,"last")) ,'UniformOutput',false);

        task_all_seperate_4{1,idxx}=aligned_px_4_all_sort;

        elseif curr_order==3
            numbers=3;

              % kernels
            if ~isempty(imaging_task_kernels_0)
                
                if ~isempty(find(learned_mva(:,1)==learned)) % if mice learned the task
                    imaging_task_kernels=imaging_task_kernels_0(find(learned_mva(:,1)==learned,numbers,"last"));
                else
                    imaging_task_kernels=imaging_task_kernels_0(end-numbers:end);
                end

                task_all_imaging{1,idxx}=mean(cat(4,imaging_task_kernels{:}),4);
                task_all_imaging_single_day{1,idxx}=imaging_task_kernels;

            else
                task_all_imaging{1,idxx}=zeros(450,426,period_length);
                task_all_imaging_single_day{1,idxx}=repmat({single(zeros(450,426,period_length))}, 1, numbers);
            end

        % stim2move period

            % if ~isempty(raw_data_task_single.tasktype(raw_data_task.workflow_type==curr_order))
            %     px_max_v=cellfun(@(x,y)   x(y(1:end-1)==0), px_max(find(raw_data_task.workflow_type==curr_order )) , raw_data_task_single.tasktype(raw_data_task.workflow_type==curr_order) ,'UniformOutput',false);
            %     px_max_a=cellfun(@(x,y)   x(y(1:end-1)==1), px_max(find(raw_data_task.workflow_type==curr_order )) , raw_data_task_single.tasktype(raw_data_task.workflow_type==curr_order) ,'UniformOutput',false);
            %     learned_mva=cell2mat( raw_data_task.learned_day(find(raw_data_task.workflow_type==curr_order ) ));
            %     imaging_task_all_sort_v= cellfun(@(x) cellfun(@(y) max(plab.wf.svd2px(U_master,y),[],3),x,'UniformOutput',false),px_max_v(find(learned_mva(:,2)==learned,numbers,"last")) ,'UniformOutput',false);
            %     imaging_task_all_sort_a= cellfun(@(x) cellfun(@(y) max(plab.wf.svd2px(U_master,y),[],3),x,'UniformOutput',false),px_max_a(find(learned_mva(:,3)==learned,numbers,"last")) ,'UniformOutput',false);
            %     imaging_task_mean_sort_v=cellfun(@(x) mean(cat(3,x{:}),3),imaging_task_all_sort_v,'UniformOutput',false );
            %     imaging_task_mean_sort_a=cellfun(@(x) mean(cat(3,x{:}),3),imaging_task_all_sort_a,'UniformOutput',false );
            % 
            %     imaging_task_all_sort={imaging_task_mean_sort_v,imaging_task_mean_sort_a};
            %     task_all_mean_imaging_single_day{1,idxx}=imaging_task_all_sort;
            % else
            % 
            %     task_all_mean_imaging_single_day{1,idxx}=repmat({[]}, 1, numbers);
            % end


        end




    end

    all_animal_period_single_day{curr_animal_idx}=task_all_mean_imaging_single_day;

    all_animal{curr_animal_idx}=task_all_imaging;
    all_animal_single_day{curr_animal_idx}=task_all_imaging_single_day;

all_animal_sperate_4{curr_animal_idx}=  task_all_seperate_4;


     % all_animal_single_day{curr_animal_idx}=cellfun(@(x) [x{:}], num2cell(task_all_imaging_single_day, 2), 'UniformOutput', false);

    %% 绘制四个阶段 imaging in 4 stages from single mouse

    % 
    % % 做视频 每只小鼠
    % close all
    % % 创建一个 VideoWriter 对象，指定文件名和格式
    % videoFilename = ['figures\use_all_trials\all_trials_visual_auditory_task_' animal '.avi'];
    % 
    % % fullfile(Path,videoFilename)
    % video = VideoWriter(fullfile(Path,videoFilename), 'Uncompressed AVI');  % 可以根据需要选择不同的格式
    % video.FrameRate = 10;  % 设置帧率
    % % 打开 VideoWriter 对象以进行写入
    % open(video);
    % % 读取图像序列并写入视频
    % for curr_frame = 1:size(t_kernels,2)
    %     % 标签数组，包含每个阶段的标签
    %     labels = {'stage 1', 'stage 2'};
    % 
    % 
    %     % 处理图像，插入标签
    %     image_with_labels = cell(1,8);  % 用于存储处理后的带标签的图像
    %     labelHeight = 50;  % 标签区域高度
    % 
    %     for i = 1:2
    %         % 当前图像
    %         imagesc(task_all_imaging{i}(:,:,curr_frame));
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
    %     image_all = [image_with_labels{1}, image_with_labels{2}];
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
    % 


    clearvars('-except',main_preload_vars{:});

end




%% select group
animals_group = [1 1 1 1 1 1 2 2 2 3 3 3 4 4 4 4 4];
selected_group=1;
group_names={'V-A','A-V'};
colors={[0 0 1],[1 0 0]};
if selected_group == 1
    stage_type={'visual','auditory','mixed'};
    group_name=group_names{1};
    curr_color=colors{1};
elseif selected_group == 4
    stage_type={'auditory','visual','mixed'};
    group_name=group_names{2};
    curr_color=colors{2};

else
    error('Unsupported value for variable. Must be 1 or 2.');
end


%% 平均的image
% imaging figure
figure('Position',[50 50 1200 300]);
scale_all=[0.01 0.003];
% title_all={'task','task: left-right'};
title_all={'task kernels','task kernels: left-right'}

for curr_state=2
allElements = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),allElements,'UniformOutput',true);
avgResults = arrayfun(@(col) ...
    mean(cat(4, allElements{nonZeroMask_all(:, col), col}), 4), ...
    1:size(allElements, 2), 'UniformOutput', false);
if curr_state==1
all_animals_mean=cellfun(@(x) max(x(:,:,period_kernels),[],3),avgResults,'UniformOutput',false);
else
   all_animals_mean=cellfun(@(x) max(x(:,:,period_kernels)-fliplr(x(:,:,period_kernels)),[],3),avgResults,'UniformOutput',false);
end 

for ss=1:2
      a=nexttile;
     % subplot(1, 2, ss);
  
        h=imagesc(all_animals_mean{ss});

        % imagesc(all_animals_mean{ss}-all_animals_mean{1});


        title(stage_type{ss})
  

    axis image off;
    ap.wf_draw('ccf', 'black');

    colormap(a, ap.colormap('PWG'));
     xlim([0 213])
    clim(scale_all(curr_state) .* [-1, 1]);
    if ss==2
    colorbar('eastoutside')
    end
end

sgtitle([group_name ' 0-' num2str(passive_boundary) 's'])
% h = colorbar;
% h.Orientation = 'horizontal';
% h.Position = [0.225, 0.15, 0.15, 0.03];  % 调整 colorbar 位置


% saveas(gcf,[Path 'figures\use_all_trials\image from 4 stages in visual and auditory from ' group_name '-naive stage'], 'jpg');
% saveas(gcf,[Path 'figures\use_all_trials\image from 3 stages in task from ' group_name ' 0-' num2str(1000*passive_boundary) 'ms' ], 'jpg');

% ROI across day
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
flip_roi=fliplr(roi1(1).data.mask)
buf1= cellfun(@(x) cellfun(@(y) cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)),y,'UniformOutput',false),x,'UniformOutput',false) , all_animal_single_day(animals_group==selected_group), 'UniformOutput', false);

if curr_state==1
    buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);

else
        buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1])- permute(mean(z(flip_roi(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);

end

% buf2= cellfun(@(x) cellfun(@(y) cell2mat(cellfun(@(z) size(z,1)==191700 ,y,'UniformOutput',false)),x,'UniformOutput',false) , buf1, 'UniformOutput', false);

% 假设 A 是一个 6x1 的 cell 数组，其中每个元素是 2x4 的 cell 矩阵
% 每个 A{i}{j, k} 是一个 50xN 的矩阵;
A=buf2; example=[ 5 5 3]
for curr_order=1:length(A)
    AA=A{curr_order};
    colSizes =  cellfun(@(y) size(y, 2),  AA, 'UniformOutput', true);
    for s=1:length(AA)
        if length(AA{s})<example(s)
            AA{s}(length(AA{s})+1:example(s))=repmat({single(nan(period_length, 1))}, 1, (example(s)-length(AA{s})));
        end
    end
    B{curr_order}=AA;
end

BB_task_kernls=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x,'UniformOutput',false)),B,'UniformOutput',false)

% figure('Position',[50 50 600 200]);
a3=nexttile;
% subplot(2,2,1)
task_across_time=mean(cat(3,BB_task_kernls{:}),3,'omitnan')';

imagesc(t_kernels,[],task_across_time(1:10,:))
clim(scale_all(curr_state).*[-1,1]); colormap(a3,ap.colormap('PWG'));
hold on;
xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
yline(5.5);yline(10.5)
% title('task kernels')
title(title_all{curr_state})

xlabel('time(s)')
yticks([3, 8,12]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签
colorbar('eastoutside')

% nexttile
% plot(t_kernels,task_across_time(1:5,:),'Color',[0 0 1])
% hold on; xline(0); xline(0.1)
% ylim(0.001*[-1 8])
% 
% hold on
% plot(t_kernels,task_across_time(6:10,:),'Color',[1 0 0])
% hold on; xline(0); xline(0.1)
% ylim(0.001*[-1 8])

% plot mPFC activity across day
nexttile
% subplot(2,2,3)
task_all=cell2mat(cellfun(@(x) max(x(period_kernels,:),[],1),BB_task_kernls,'UniformOutput',false)');
task_mean_line=mean(task_all,1,'omitnan');
task_sem_line=std(task_all,'omitnan')/sqrt(size(task_all,1));
hold on
ap.errorfill(1:5,task_mean_line(1:5), task_sem_line(1:5),curr_color,0.1,0.5);
ap.errorfill(6:10,task_mean_line(6:10), task_sem_line(6:10),curr_color,0.1,0.5);
% ap.errorfill(11:13,task_mean_line(11:13), task_sem_line(11:13),curr_color,0.1,0.5);

ylim(scale_all(curr_state)*[-0.1 1])
xticks([3, 8,12]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('df/f')

sgtitle([group_name ' 0-' num2str(passive_boundary) 's'])
end

 % saveas(gcf,[Path 'figures\summary\heatmap and plot mPFC activity in task across day ' group_name ], 'jpg');
   % saveas(gcf,[Path 'figures\summary\hemispheric asymmetry of heatmap and plot mPFC kernels activity in task across day ' group_name ], 'jpg');


%%

buffer_4=avgResults{6};

buffer_1=avgResults{7};


ap.imscroll(buffer_1,t_passive)
axis image off;
ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WG'));
clim(scale_all .* [0, 1]);

ap.imscroll(buffer_4,t_passive)
axis image off;
ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WG'));
clim(scale_all .* [0, 1]);

%% 平均小鼠做video


% % 做视频 每只小鼠
% close all
% % 创建一个 VideoWriter 对象，指定文件名和格式
% videoFilename = ['figures\use_all_trials\all_trials_visual_auditory_passive_' strjoin(animals(find(animals_group==4)), '_') '.avi'];
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
%     for curr_order = 1:8
%         % 当前图像
%         imagesc(avgResults{curr_order}(:,:,curr_frame));
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
%         img_with_label = insertText(img_with_label, [imgWidth/2, labelHeight/2], labels{curr_order}, 'FontSize', 18, ...
%             'BoxColor', 'white', 'BoxOpacity', 1, 'TextColor', 'black', 'AnchorPoint', 'Center');
%         % 保存处理后的图像
%         image_with_labels{curr_order} = img_with_label;
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
% 
% 


%% seperate 4 group
allElements_seperate_4 = vertcat(all_animal_sperate_4{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
allElements_seperate_4=allElements_seperate_4(:,1:2);
allElements_seperate_4_mean=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),allElements_seperate_4,'UniformOutput',false);
result_seperate_4_mean = arrayfun(@(col) mean(cat(5, allElements_seperate_4_mean{:, col}), 5,'omitnan'), 1:2, 'UniformOutput', false);

buf1=  cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)),result_seperate_4_mean,'UniformOutput',false);

buf2=  cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]),buf1,'UniformOutput',false);

% 
time_window={'0-100 ms','100-200 ms','200-300 ms','300+ ms'};
figure('Position',[50 50 800 300]);
for curr_fig=1:length(result_seperate_4_mean)
%     for curr_frame=1:4
%    nexttile
%    imagesc(max(result_seperate_4_mean{curr_fig}(:,:,period_task,curr_frame),[],3))
%    axis image off;
% ap.wf_draw('ccf', 'black');
% colormap( ap.colormap('WG'));
% clim(0.01 .* [0, 1]);
% title([time_window{curr_frame} 'ms'])
%     end
%     colorbar('eastoutside')
% 
    nexttile
     colors = [linspace(0.8, 0, 4)', linspace(0.8, 0, 4)', linspace(0.8, 0, 4)'];
set(gca, 'ColorOrder', colors, 'NextPlot', 'replacechildren'); % 设置颜色顺序

   plot(t_task,buf2{curr_fig},'LineWidth',2)
   % xlim([min(t_task) max(t_task)])
   % xlim([0 1])
colormap( ap.colormap('WG'));
clim(0.01 .* [0, 1]);
% title('mPFC activity with different reaction time')
ylabel('df/f')
xlabel('time(s)')
ylim(0.001*[-1 6])
end
legend(time_window,'Location','eastoutside')

sgtitle({group_name,'mPFC activity-predicted movement acitivity with different reaction time'})

  saveas(gcf,[Path 'figures\summary\heatmap and plot mPFC activity- predicted movement activity in 4 seperated group ' group_name ], 'jpg');

%% draw video

allElements = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),allElements,'UniformOutput',true);
avgResults = arrayfun(@(col) ...
    mean(cat(4, allElements{nonZeroMask_all(:, col), col}), 4), ...
    1:size(allElements, 2), 'UniformOutput', false);

    % 做视频 每只小鼠
    close all
    % 创建一个 VideoWriter 对象，指定文件名和格式
    videoFilename = ['figures\summary\task_video_' group_name '.avi'];

    % fullfile(Path,videoFilename)
    video = VideoWriter(fullfile(Path,videoFilename), 'Uncompressed AVI');  % 可以根据需要选择不同的格式
    video.FrameRate = 10;  % 设置帧率
    % 打开 VideoWriter 对象以进行写入
    open(video);
    % 读取图像序列并写入视频
    for curr_frame = 1:size(t_kernels,2)
        % 标签数组，包含每个阶段的标签
        labels = {'stage 1', 'stage 2'};


        % 处理图像，插入标签
        image_with_labels = cell(1,8);  % 用于存储处理后的带标签的图像
        labelHeight = 50;  % 标签区域高度

        for i = 1:2
            % 当前图像
            imagesc(avgResults{i}(:,:,curr_frame));
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.007.*[-1,1]); colormap(ap.colormap('PWG'));

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

        image_all = [image_with_labels{1}, image_with_labels{2}];

        % 添加标题并保存到视频中
        [height, width, ~] = size(image_all);
        titleHeight = 30;
        newImage = uint8(zeros(height + titleHeight, width, 3));
        newImage(titleHeight+1:end, :, :) = image_all;
        newImage(1:titleHeight, :, :) = 255;

        position = [width/2, titleHeight/2];
        titleText = ['Averaged mice group' num2str(animals_group(curr_animal_idx)) ':' num2str(t_kernels(curr_frame)) 's'];
        newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
            'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
            'AnchorPoint', 'Center');

        writeVideo(video, newImageWithText);
        close all

    end

    % 关闭 VideoWriter 对象
    close(video);
    disp('视频保存完成。');

