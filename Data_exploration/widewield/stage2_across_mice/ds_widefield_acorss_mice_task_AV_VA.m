
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
% t_kernels=1/surround_samplerate*[-5:30];
t_kernels_stim=1/surround_samplerate*[-5:30];
t_kernels_move=1/surround_samplerate*[-30:30];

% move_kernels=1/surround_samplerate*[-30:30];

passive_boundary=0.3;
period_passive=find(t_passive>0 & t_passive<passive_boundary);
period_task=find(t_task>0 & t_task<passive_boundary);
period_kernels_stim=find(t_kernels_stim>0 & t_kernels_stim<passive_boundary);
period_kernels_move=find(t_kernels_move>0 & t_kernels_move<passive_boundary);

all_animal_single_day=cell(length(animals),1);
all_animal_single_day_mix=cell(length(animals),1);

% 选择
% use raw data or kernels,
used_data=2;  %  raw data:1; kernels:2;
used_data_name={'raw data','kernels'};

used_timepoint=1;  % stim:1; movement:2
used_timepoint_name={'stim','movement'};

if used_data==1
    use_t=t_task;
elseif used_data==2
    if used_timepoint==1
        use_t=t_kernels_stim;
    elseif used_timepoint==2
        use_t=t_kernels_move;
    end
end



for curr_animal_idx=1:length(animals)
    main_preload_vars = who;

    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);

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



    if animals_type(curr_animal_idx) == 1
        order = [ 1, 2, 3];
        stage_type={'visual','auditory','mixed'};
    elseif animals_type(curr_animal_idx) == 2
        order = [2, 1, 3];
        stage_type={'auditory','visual','mixed'};
    else
        error('Unsupported value for variable. Must be 1 or 2.');
    end

    task_all_imaging_single_day=cell(1,2);
    task_all_imaging_single_day_mix=cell(1,1);


    % 处理两类分析，第一类是task kernels的分析
    idxx=0;
    for curr_order=order

        idxx=idxx+1;
        learned=1;

        %使用哪个data
        if used_data==1
            % 使用 realdata
            if curr_order==1|curr_order==2
                use_imaging_0=cellfun(@(x) x(:,:,used_timepoint),raw_data_task.wf_px_task(find(raw_data_task.workflow_type==curr_order)),'UniformOutput',false);
            elseif curr_order==3
                use_imaging_0=cellfun(@(x) x(:,:,2*used_timepoint-1:2*used_timepoint),raw_data_task.wf_px_task(find(raw_data_task.workflow_type==curr_order)),'UniformOutput',false);
            end
        elseif used_data==2
            % 使用 task kernels
            if curr_order==3 & used_timepoint==2
                use_imaging_0=cellfun(@(x) repmat(x{used_timepoint},1,1,2),raw_data_task.wf_px_task_kernels(find(raw_data_task.workflow_type==curr_order)),'UniformOutput',false);
            else  use_imaging_0=cellfun(@(x) x{used_timepoint},raw_data_task.wf_px_task_kernels(find(raw_data_task.workflow_type==curr_order)),'UniformOutput',false);
            end
        end




        learned_mva=cell2mat( raw_data_task.learned_day(find(raw_data_task.workflow_type==curr_order ) )');


        %如果是visual or auditory task
        if curr_order==1|curr_order==2
            numbers=5;
            % kernels

            if ~isempty(find(learned_mva==learned)) % if mice learned the task
                use_imaging=use_imaging_0(find(learned_mva==learned,numbers,"last"));
            else
                use_imaging=use_imaging_0(max(1,end-numbers+1):end);
            end


            task_all_imaging_single_day{1,idxx}=use_imaging;






        elseif curr_order==3
            %  imaging_task_kernels_visual=repmat({[]}, 1, 3);
            % imaging_task_kernels_audio=repmat({[]}, 1, 3);


            numbers=3;

            if ~isempty(learned_mva)
                if ~isempty(find(learned_mva(:,1)==learned)) % if mice learned the task
                    imaging_task_kernels_visual=cellfun(@(x) x(:,:,1),use_imaging_0(find(learned_mva(:,1)==learned,numbers,"last")),'UniformOutput',false);
                    imaging_task_kernels_audio=cellfun(@(x) x(:,:,2),use_imaging_0(find(learned_mva(:,2)==learned,numbers,"last")),'UniformOutput',false);
                    if isempty(imaging_task_kernels_audio)
                        imaging_task_kernels_audio=repmat({single([])}, 1, 3);
                    end
                else
                    imaging_task_kernels_visual=cellfun(@(x) x(:,:,1),use_imaging_0(end-numbers:end),'UniformOutput',false);
                    imaging_task_kernels_audio=cellfun(@(x) x(:,:,2),use_imaging_0(end-numbers:end),'UniformOutput',false);

                end

                use_imaging={imaging_task_kernels_visual,imaging_task_kernels_audio};

                task_all_imaging_single_day_mix=use_imaging;

            else
                task_all_imaging_single_day_mix=repmat({repmat({single([])}, 1, 3)}, 1, 2);


            end
        end




    end


    all_animal_single_day{curr_animal_idx}=task_all_imaging_single_day;
    all_animal_single_day_mix{curr_animal_idx}=task_all_imaging_single_day_mix;




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
% animals_group = [1 1 ];

for curr_group=1:2
    if curr_group==1
        selected_group=1;
    else selected_group=4;
    end

    group_names={'V-A','A-V'};
    colors={[0 0 1],[1 0 0]};
    if selected_group == 1
        stage_type={'visual','auditory','mixed visual','mixed auditory'};
        group_name=group_names{1};
        curr_color=colors{1};
    elseif selected_group == 4
        stage_type={'auditory','visual','mixed auditory','mixed visual'};
        group_name=group_names{2};
        curr_color=colors{2};

    else
        error('Unsupported value for variable. Must be 1 or 2.');
    end


    % 平均的image
    % imaging figure
    scale_all=[0.01 0.003];
    % title_all={'task','task: left-right'};
    title_all={'Left mPFC','lmPFC-rmPFC'};

    for curr_state=1:2

        figure('Position',[50 50 600 600]);

        if curr_state==1
            passive_boundary=0.1;
        else      passive_boundary=0.3;
        end

        use_period=find(use_t>0&use_t<passive_boundary);


        % visual auditory day
        all_animas_mean_images_VA= cellfun(@(bb) cellfun(@(x) mean(cat(3,x{:}),3),bb,'UniformOutput',false), all_animal_single_day(animals_group==selected_group),'UniformOutput',false);
        all_animas_mean_images_VA_2 = vertcat(all_animas_mean_images_VA{:}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
        nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),all_animas_mean_images_VA_2,'UniformOutput',true);
        all_animas_mean_images_VA_3 = arrayfun(@(col) ...
            mean(cat(4, all_animas_mean_images_VA_2{nonZeroMask_all(:, col), col}), 4), ...
            1:size(all_animas_mean_images_VA_2, 2), 'UniformOutput', false);
        indx_n=cellfun(@(x) ~isempty(x),all_animas_mean_images_VA_3)
        all_animas_mean_images_VA_4=cellfun(@(x) plab.wf.svd2px(U_master,x),all_animas_mean_images_VA_3(indx_n),'UniformOutput',false);

        % mixed task day
        nonNan_idx=cellfun(@(bb) cellfun(@(x) ~isempty(x), bb,'UniformOutput',false),all_animal_single_day_mix(animals_group==selected_group),'UniformOutput',false);

        all_animas_mean_images_mix= cellfun(@(aa,bb) cellfun(@(x) mean(cat(3,x{:}),3),aa(cell2mat(bb)),'UniformOutput',false), all_animal_single_day_mix(animals_group==selected_group),nonNan_idx,'UniformOutput',false);
        all_animas_mean_images_mix_2 = vertcat(all_animas_mean_images_mix{:}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
        nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),all_animas_mean_images_mix_2,'UniformOutput',true);
        all_animas_mean_images_mix_3 = arrayfun(@(col) ...
            mean(cat(4, all_animas_mean_images_mix_2{nonZeroMask_all(:, col), col}), 4), ...
            1:size(all_animas_mean_images_mix_2, 2), 'UniformOutput', false);
        all_animas_mean_images_mix_4=cellfun(@(x) plab.wf.svd2px(U_master,x),all_animas_mean_images_mix_3,'UniformOutput',false);

        if selected_group==4
            all_animas_mean_images_mix_4=flip(all_animas_mean_images_mix_4, 2);
        end

        if curr_state==1
            all_animals_mean=cellfun(@(x) max(x(:,:,use_period),[],3),all_animas_mean_images_VA_4,'UniformOutput',false);
            all_animals_mean_mix=cellfun(@(x) max(x(:,:,use_period),[],3),all_animas_mean_images_mix_4,'UniformOutput',false);

        else
            all_animals_mean=cellfun(@(x) max(x(:,:,use_period)-fliplr(x(:,:,use_period)),[],3),all_animas_mean_images_VA_4,'UniformOutput',false);
            all_animals_mean_mix=cellfun(@(x) max(x(:,:,use_period)-fliplr(x(:,:,use_period)),[],3),all_animas_mean_images_mix_4,'UniformOutput',false);
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
            if curr_state==2
                xlim([0 213])
            end
            clim(scale_all(curr_state) .* [-1, 1]);
            % if ss==2
            %     colorbar('eastoutside')
            % end
        end
        for ss=1:2
            a=nexttile;
            % subplot(1, 2, ss);

            h=imagesc(all_animals_mean_mix{ss});

            % imagesc(all_animals_mean{ss}-all_animals_mean{1});


            title(stage_type{ss+2})


            axis image off;
            ap.wf_draw('ccf', 'black');

            colormap(a, ap.colormap('PWG'));
            if curr_state==2
                xlim([0 213])
            end
            clim(scale_all(curr_state) .* [-1, 1]);
            if ss==2
                colorbar('eastoutside')
            end
        end

        sgtitle([group_name ' 0-' num2str(passive_boundary) 's'])



        % ROI across day
        load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
        flip_roi=fliplr(roi1(1).data.mask);

        buf0= cellfun(@(x) cellfun(@(y) cellfun(@(z)  plab.wf.svd2px(U_master,z),y,'UniformOutput',false),x,'UniformOutput',false) , all_animal_single_day(animals_group==selected_group), 'UniformOutput', false);
        buf1= cellfun(@(x) cellfun(@(y) cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)),y,'UniformOutput',false),x,'UniformOutput',false) , buf0, 'UniformOutput', false);

        idx_nan=cellfun(@(x) cellfun(@(y) cellfun(@(z) ~isempty(z),y,'UniformOutput',false),x,'UniformOutput',false) , all_animal_single_day_mix(animals_group==selected_group), 'UniformOutput', false);
        buf_mix0= cellfun(@(x,x1) cellfun(@(y,y1) cellfun(@(z)  plab.wf.svd2px(U_master,z),y(cell2mat(y1)),'UniformOutput',false),x,x1,'UniformOutput',false) , all_animal_single_day_mix(animals_group==selected_group),idx_nan, 'UniformOutput', false);

        if selected_group==4
            buf_mix0=cellfun(@(x) flip(x, 2), buf_mix0, 'UniformOutput', false);
        end

        buf_mix1= cellfun(@(x) cellfun(@(y) cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)),y,'UniformOutput',false),x,'UniformOutput',false) , buf_mix0, 'UniformOutput', false);


        if curr_state==1
            buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);
            buf_mix2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf_mix1, 'UniformOutput', false);

        else
            buf2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1])- permute(mean(z(flip_roi(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf1, 'UniformOutput', false);
            buf_mix2= cellfun(@(x) cellfun(@(y) cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1])- permute(mean(z(flip_roi(:),:,:),1),[2,3,1]),y,'UniformOutput',false),x,'UniformOutput',false) , buf_mix1, 'UniformOutput', false);

        end

        % buf2= cellfun(@(x) cellfun(@(y) cell2mat(cellfun(@(z) size(z,1)==191700 ,y,'UniformOutput',false)),x,'UniformOutput',false) , buf1, 'UniformOutput', false);

        % 假设 A 是一个 6x1 的 cell 数组，其中每个元素是 2x4 的 cell 矩阵
        % 每个 A{i}{j, k} 是一个 50xN 的矩阵;
        A=buf2; example=[ 5 5];
        B=cell(1,length(A));
        for curr_order=1:length(A)
            AA=A{curr_order};
            colSizes =  cellfun(@(y) size(y, 2),  AA, 'UniformOutput', true);
            for s=1:length(AA)
                if length(AA{s})<example(s)
                    AA{s}(length(AA{s})+1:example(s))=repmat({single(nan(length(use_t), 1))}, 1, (example(s)-length(AA{s})));
                end
            end
            B{curr_order}=AA;
        end

        BB_task_kernels=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x,'UniformOutput',false)),B,'UniformOutput',false);


        A_mix=buf_mix2 ; example=[ 3 3];
        B_mix=cell(1,length(A_mix));
        for curr_order=1:length(A_mix)
            AA_mix=A_mix{curr_order};
            colSizes =  cellfun(@(y) size(y, 2),  AA_mix, 'UniformOutput', true);
            for s=1:length(AA_mix)
                if length(AA_mix{s})<example(s)
                    AA_mix{s}(length(AA_mix{s})+1:example(s))=repmat({single(nan(length(use_t), 1))}, 1, (example(s)-length(AA_mix{s})));
                end
            end
            B_mix{curr_order}=AA_mix;
        end
        BB_task_mix_kernels=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z,y,'UniformOutput',false)),x,'UniformOutput',false)),B_mix,'UniformOutput',false);


        % figure('Position',[50 50 600 200]);
        a3=nexttile;
        % subplot(2,2,1)
        task_across_time=mean(cat(3,BB_task_kernels{:}),3,'omitnan')';
        task_across_time_mix=mean(cat(3,BB_task_mix_kernels{:}),3,'omitnan')';

        imagesc(use_t,[],[task_across_time; task_across_time_mix])
        clim(scale_all(curr_state).*[-1,1]); colormap(a3,ap.colormap('PWG'));
        hold on;
        xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);
        yline(5.5);yline(10.5); yline(13.5);
        % title('task kernels')
        title(title_all{curr_state})

        xlabel('time(s)')
        yticks([3, 8,12, 15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
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
        task_all=[cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_task_kernels,'UniformOutput',false)')...
            cell2mat(cellfun(@(x) max(x(use_period,:),[],1),BB_task_mix_kernels,'UniformOutput',false)')];

        task_average{curr_group}{curr_state}=task_all;

        task_mean_line=mean(task_all,1,'omitnan');
        task_sem_line=std(task_all,'omitnan')/sqrt(size(task_all,1));
        hold on
        ap.errorfill(1:5,task_mean_line(1:5), task_sem_line(1:5),curr_color,0.1,0.5);
        ap.errorfill(6:10,task_mean_line(6:10), task_sem_line(6:10),curr_color,0.1,0.5);
        ap.errorfill(11:13,task_mean_line(11:13), task_sem_line(11:13),curr_color,0.1,0.5);
        ap.errorfill(14:16,task_mean_line(14:16), task_sem_line(14:16),curr_color,0.1,0.5);

        ylim(scale_all(curr_state)*[-0.1 1])
        xticks([3, 8,12,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(stage_type); % 设置对应的标签
        ylabel('df/f')





        sgtitle([used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint} ' in 0-' num2str(passive_boundary) 's time windows'])

        if used_data==1& curr_state==1
            saveas(gcf,[Path 'figures\summary\task_raw\heatmap and plot lmPFC activity in task ' used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint}  ], 'jpg');
        elseif used_data==1& curr_state==2
            saveas(gcf,[Path 'figures\summary\task_raw\hemispheric asymmetry of heatmap and plot mPFC activity in task ' used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint}  ], 'jpg');
        elseif used_data==2& curr_state==1
            saveas(gcf,[Path 'figures\summary\task_kernels\heatmap and plot lmPFC activity in task ' used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint}  ], 'jpg');
        elseif used_data==2& curr_state==2
            saveas(gcf,[Path 'figures\summary\task_kernels\hemispheric asymmetry of heatmap and plot mPFC activity in task ' used_data_name{used_data} ' of group ' group_name ' aligned to ' used_timepoint_name{used_timepoint}  ], 'jpg');

        end

    end

end
% saveas(gcf,[Path 'figures\summary\heatmap and plot mPFC activity in task across day ' group_name ], 'jpg');
% saveas(gcf,[Path 'figures\summary\hemispheric asymmetry of heatmap and plot mPFC kernels activity in task across day ' group_name ], 'jpg');


%%

task_mean=cellfun(@(x) cellfun(@(y) mean(y,1,'omitnan'),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )
task_std=cellfun(@(x) cellfun(@(y) std(y,'omitnan')/sqrt(size(y,1)),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )

figure('Position',[200 200 700 300])
nexttile
hold on
ap.errorfill(1:5, task_mean{1}{1}(1:5),  task_std{1}{1}(1:5),colors{1},0.1,0.5);
ap.errorfill(6:10, task_mean{1}{1}(6:10),  task_std{1}{1}(6:10),colors{1},0.1,0.5);
ap.errorfill(11:13, task_mean{1}{1}(11:13),  task_std{1}{1}(11:13),colors{1},0.1,0.5);
ap.errorfill(14:16, task_mean{1}{1}(14:16),  task_std{1}{1}(14:16),colors{1},0.1,0.5);

ap.errorfill(6:10, task_mean{2}{1}(1:5),  task_std{2}{1}(1:5),colors{2},0.1,0.5);
ap.errorfill(1:5, task_mean{2}{1}(6:10),  task_std{2}{1}(6:10),colors{2},0.1,0.5);
ap.errorfill(14:16, task_mean{2}{1}(11:13),  task_std{2}{1}(11:13),colors{2},0.1,0.5);
ap.errorfill(11:13, task_mean{2}{1}(14:16),  task_std{2}{1}(14:16),colors{2},0.1,0.5);
ylim(scale_all(curr_state)*[-0.1 2.5])
xticks([3, 8,12,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
ylabel('df/f')
title ('lmPFC')
nexttile
hold on
% plot(1:5, task_mean{1}{2}(1:5),'Color',[0 0 1])
%    plot(1:5, task_mean{2}{2}(1:5),'Color',[1 0 0])

ap.errorfill(1:5, task_mean{1}{2}(1:5),  task_std{1}{2}(1:5),colors{1},0.1,0.5);
ap.errorfill(6:10, task_mean{2}{2}(1:5),  task_std{2}{2}(1:5),colors{2},0.1,0.5);

ap.errorfill(6:10, task_mean{1}{2}(6:10),  task_std{1}{2}(6:10),colors{1},0.1,0.5);
ap.errorfill(11:13, task_mean{1}{2}(11:13),  task_std{1}{2}(11:13),colors{1},0.1,0.5);
ap.errorfill(14:16, task_mean{1}{2}(14:16),  task_std{1}{2}(14:16),colors{1},0.1,0.5);

% ap.errorfill(6:10, task_mean{2}{2}(1:5),  task_std{2}{2}(1:5),colors{2},0.1,0.5);
ap.errorfill(1:5, task_mean{2}{2}(6:10),  task_std{2}{2}(6:10),colors{2},0.1,0.5);
ap.errorfill(14:16, task_mean{2}{2}(11:13),  task_std{2}{2}(11:13),colors{2},0.1,0.5);
ap.errorfill(11:13, task_mean{2}{2}(14:16),  task_std{2}{2}(14:16),colors{2},0.1,0.5);
ylim(scale_all(curr_state)*[-0.1 1.5])
xticks([3, 8,12,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
ylabel('df/f')
title ('lmPFC-rmPFC')
sgtitle(used_data_name{used_data})
legend('','V-A group','','A-V group','Location','northeastoutside','Box','off');
if used_data==1
    saveas(gcf,[Path 'figures\summary\task_raw\VA_AV_compare via ' used_data_name{used_data}  ], 'jpg');
elseif used_data==2
    saveas(gcf,[Path 'figures\summary\task_kernels\VA_AV_compare via ' used_data_name{used_data}  ], 'jpg');

end

%%

task_mean=cellfun(@(x) cellfun(@(y) mean(y,1,'omitnan'),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )
task_std=cellfun(@(x) cellfun(@(y) std(y,'omitnan')/sqrt(size(y,1)),x,'UniformOutput',false  ),task_average,'UniformOutput',false  )

figure('Position',[200 200 700 300])
nexttile
hold on
mean1=[mean(task_mean{1}{1}(1:5)) mean(task_mean{1}{1}(6:10)) mean(task_mean{1}{1}(11:13)) mean(task_mean{1}{1}(14:16))];
error1=[ mean(task_std{1}{1}(1:5)) mean(task_std{1}{1}(6:10))  mean(task_std{1}{1}(11:13)) mean(task_std{1}{1}(14:16))];
mean2=[ mean(task_mean{2}{1}(6:10)) mean(task_mean{2}{1}(1:5))  mean(task_mean{2}{1}(14:16)) mean(task_mean{2}{1}(11:13))];
error2=[  mean(task_std{2}{1}(6:10)) mean(task_std{2}{1}(1:5))   mean(task_std{2}{1}(14:16)) mean(task_std{2}{1}(11:13))];

errorbar(1:4, mean1, error1,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean2, error2,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])

ylim(scale_all(curr_state)*[-0.1 2.5])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
ylabel('df/f')
title ('lmPFC')
nexttile
hold on
mean3=[mean(task_mean{1}{2}(1:5)) mean(task_mean{1}{2}(6:10)) mean(task_mean{1}{2}(11:13)) mean(task_mean{1}{2}(14:16))];
error3=[ mean(task_std{1}{2}(1:5)) mean(task_std{1}{2}(6:10))  mean(task_std{1}{2}(11:13)) mean(task_std{1}{2}(14:16))];
mean4=[ mean(task_mean{2}{2}(6:10)) mean(task_mean{2}{2}(1:5))  mean(task_mean{2}{2}(14:16)) mean(task_mean{2}{2}(11:13))];
error4=[  mean(task_std{2}{2}(6:10)) mean(task_std{2}{2}(1:5))   mean(task_std{2}{2}(14:16)) mean(task_std{2}{2}(11:13))];
errorbar(1:4, mean3, error3,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{1});
errorbar(1.1:1:4.1, mean4, error4,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{2});
xlim([0.5 4.5])


ylim(scale_all(curr_state)*[-0.1 1.5])
xticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'visual','auditory','mixed visual','mixed auditory'}); % 设置对应的标签
ylabel('df/f')
title ('lmPFC-rmPFC')
sgtitle(used_data_name{used_data})
legend('V-A group','A-V group','Location','northeastoutside','Box','off');

if used_data==1
    saveas(gcf,[Path 'figures\summary\task_raw\Bar VA_AV_compare via ' used_data_name{used_data}  ], 'jpg');
elseif used_data==2
    saveas(gcf,[Path 'figures\summary\task_kernels\Bar VA_AV_compare via ' used_data_name{used_data}  ], 'jpg');

end

%%
buffer_4=all_animas_mean_images_VA_3{6};

buffer_1=all_animas_mean_images_VA_3{7};


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

% saveas(gcf,[Path 'figures\summary\heatmap and plot mPFC activity- predicted movement activity in 4 seperated group ' group_name ], 'jpg');

%% draw video

all_animas_mean_images_VA_2 = vertcat(all_animal{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all = cellfun(@(x) ~all(x(:)==0),all_animas_mean_images_VA_2,'UniformOutput',true);
all_animas_mean_images_VA_3 = arrayfun(@(col) ...
    mean(cat(4, all_animas_mean_images_VA_2{nonZeroMask_all(:, col), col}), 4), ...
    1:size(all_animas_mean_images_VA_2, 2), 'UniformOutput', false);

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
for curr_frame = 1:size(t_kernels_stim,2)
    % 标签数组，包含每个阶段的标签
    labels = {'stage 1', 'stage 2'};


    % 处理图像，插入标签
    image_with_labels = cell(1,8);  % 用于存储处理后的带标签的图像
    labelHeight = 50;  % 标签区域高度

    for i = 1:2
        % 当前图像
        imagesc(all_animas_mean_images_VA_3{i}(:,:,curr_frame));
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
    titleText = ['Averaged mice group' num2str(animals_group(curr_animal_idx)) ':' num2str(t_kernels_stim(curr_frame)) 's'];
    newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
        'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
        'AnchorPoint', 'Center');

    writeVideo(video, newImageWithText);
    close all

end

% 关闭 VideoWriter 对象
close(video);
disp('视频保存完成。');

