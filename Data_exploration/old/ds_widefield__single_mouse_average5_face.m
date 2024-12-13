
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

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_task=find(t_task>0&t_task<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

surround_frames=60;
surround_t = [-surround_frames+1:surround_frames]./30;
period_passive_face=find(surround_t>0&surround_t<passive_boundary);


all_animal=cell(length(animals),1);
all_animal_single_day=cell(length(animals),1);
all_animal_face=cell(length(animals),1);
all_animal_face_single_day=cell(length(animals),1);


for curr_animal_idx=1:length(animals)
    main_preload_vars = who;

    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    if animals_type(curr_animal_idx) == 1
        order = [0, 1, 2, 3];
        stage_type={'baseline','visual','auditory','mixed'};
    elseif animals_type(curr_animal_idx) == 2
        order = [0, 2, 1, 3];
        stage_type={'baseline','auditory','visual','mixed'};
    else
        error('Unsupported value for variable. Must be 1 or 2.');
    end


     raw_data_lcr_face=load([Path 'mat_data\passive_vs_face\' animal '_lcr_passive_passive_vs_face.mat' ]);
     raw_data_hml_face=load([Path 'mat_data\passive_vs_face\' animal '_hml_passive_audio_passive_vs_face.mat' ]);


    % raw_data_hml=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);
    fprintf('%s\n', ['File loading completed of  ' animal ]);


    %使用所有trial进行分析
  
    mean_gain = mean(raw_data_lcr_face.camera_task_gain, 'omitnan');
    raw_data_lcr_face.camera_task_gain(isnan(raw_data_lcr_face.camera_task_gain)) = mean_gain;
    nonemptyidx=cellfun(@(x) ~isempty(x), raw_data_lcr_face.camera_plot,'UniformOutput',true);
    raw_data_lcr_face.camera_plot_baslined_normalized(nonemptyidx)= cellfun(@(x,y) (x-mean(x(surround_t<0,:),'all'))/y,raw_data_lcr_face.camera_plot(nonemptyidx),num2cell(raw_data_lcr_face.camera_task_gain(nonemptyidx)),'UniformOutput',false);

     mean_gain = mean(raw_data_hml_face.camera_task_gain, 'omitnan');
    raw_data_hml_face.camera_task_gain(isnan(raw_data_hml_face.camera_task_gain)) = mean_gain;
    nonemptyidx=cellfun(@(x) ~isempty(x), raw_data_hml_face.camera_plot,'UniformOutput',true);
    raw_data_hml_face.camera_plot_baslined_normalized(nonemptyidx)= cellfun(@(x,y) (x-mean(x(surround_t<0,:),'all'))/y,raw_data_hml_face.camera_plot(nonemptyidx),num2cell(raw_data_hml_face.camera_task_gain(nonemptyidx)),'UniformOutput',false);


    

    all_face=cell(2,4);
    all_face_single_day=cell(2,4);

    idxx=0;
    for curr_order=order
        idxx=idxx+1;
        if curr_order==0
            learned=0;
        else learned=1;
        end
        if curr_order==0 |curr_order==3
            numbers=3;
        else numbers=5;
        end
        conditions_lcr = [-90, 0, 90];
        conditions_hml = [4000, 8000, 12000];

        data_facial_lcr0  = cellfun(@(x, tr_type, tr_state)  arrayfun(@(cond)  mean(x(:, tr_type == cond ),2), conditions_lcr, 'UniformOutput', false ), raw_data_lcr_face.camera_plot_baslined_normalized', raw_data_lcr_face.trial_type, raw_data_lcr_face.trial_state, 'UniformOutput', false);
        data_facial_lcr0  = cellfun(@(x) cat(2,x{:}), data_facial_lcr0,  'UniformOutput', false);

        data_facial_hml0  = cellfun(@(x, tr_type, tr_state)  arrayfun(@(cond)  mean(x(:, tr_type == cond ),2), conditions_hml, 'UniformOutput', false ), raw_data_hml_face.camera_plot_baslined_normalized', raw_data_hml_face.trial_type, raw_data_hml_face.trial_state, 'UniformOutput', false);
        data_facial_hml0  = cellfun(@(x) cat(2,x{:}), data_facial_hml0,  'UniformOutput', false);
 

        % data_facial_lcr1  = cellfun(@(x, tr_type, tr_state)  arrayfun(@(cond)  x(:, tr_type == cond ), conditions_lcr, 'UniformOutput', false ), raw_data_lcr_face.camera_plot_baslined_normalized', raw_data_lcr_face.trial_type, raw_data_lcr_face.trial_state, 'UniformOutput', false);
        % data_facial_lcr1  = cellfun(@(x) cat(3,x{:}), data_facial_lcr1,  'UniformOutput', false);
        % data_facial_lcr1  = cellfun(@(x) permute(mean(x(period_passive_face,:,:),1),[2,3,1]), data_facial_lcr1,  'UniformOutput', false);



        if curr_order==0
          
            %face
              facial_data_lcr=data_facial_lcr0(find(raw_data_lcr_face.workflow_type==curr_order&raw_data_lcr_face.learned_day==learned,numbers,"first"))';
             facial_data_hml=data_facial_hml0(find(raw_data_hml_face.workflow_type==curr_order&raw_data_hml_face.learned_day==learned,numbers,"first"))';
           
        
        else


            facial_data_lcr=data_facial_lcr0(find(raw_data_lcr_face.workflow_type==curr_order&raw_data_lcr_face.learned_day==learned,numbers,"last"))';
            if isempty(facial_data_lcr)
                 facial_data_lcr=data_facial_lcr0(find(raw_data_lcr_face.workflow_type==curr_order,numbers,"last"))';
            end

            facial_data_hml=data_facial_hml0(find(raw_data_hml_face.workflow_type==curr_order&raw_data_hml_face.learned_day==learned,numbers,"last"))';
            if isempty(facial_data_hml)
            facial_data_hml=data_facial_hml0(find(raw_data_hml_face.workflow_type==curr_order,numbers,"last"))';
              
           end
     

        end
      facial_data_hml = facial_data_hml(~cellfun('isempty', facial_data_hml));
      facial_data_lcr = facial_data_lcr(~cellfun('isempty', facial_data_lcr));

      

     face_lcr_mean= nanmean(cat(3,facial_data_lcr{:}),3);
       if ~isempty(face_lcr_mean)
            all_face{1,idxx}=face_lcr_mean(:,3);
       else all_face{1,idxx}=zeros(120*1);
        end

      face_hml_mean= mean(cat(3,facial_data_hml{:}),3);
        if ~isempty(face_hml_mean)
            all_face{2,idxx}=face_hml_mean(:,2);
       else all_face{2,idxx}=zeros(120*1);
        end

        all_face_single_day{1,idxx}=facial_data_lcr;
        all_face_single_day{2,idxx}=facial_data_hml;

    end


    %
       all_face_line=reshape(all_face',1,[]);
    all_animal_face{curr_animal_idx}=all_face_line;
    all_animal_face_single_day{curr_animal_idx}=all_face_single_day;

   
    % all_animal_single_day{curr_animal_idx}=cellfun(@(x) [x{:}], num2cell(all_imaging_single_day, 2), 'UniformOutput', false);
    clearvars('-except',main_preload_vars{:});
end
        

%% choose groups
animals_group = [1 1 1 1 1 1 5 2 2 3 3 3 4 4 4 4 4];
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



%% facial 面部图像
allElements_face = vertcat(all_animal_face{animals_group==selected_group}); % 将 17x1 cell 阵列展开为 17x8 cell 矩阵
nonZeroMask_all_face = cellfun(@(x) ~all(x(:)==0),allElements_face,'UniformOutput',true);
avgResults_face = arrayfun(@(col) ...
    mean(cat(4, allElements_face{nonZeroMask_all_face(:, col), col}), 4), ...
    1:size(allElements_face, 2), 'UniformOutput', false);
% all_animals_face_mean=cellfun(@(x) mean(x(period_passive_face)),avgResults,'UniformOutput',true);
all_animals_face_mean=cell2mat(avgResults_face);
figure;
nexttile
imagesc(surround_t,[], all_animals_face_mean(:,1:4)')
yticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); 
clim([-0.3,0.3]); colormap(ap.colormap('PWG'));
title('visual passive')


nexttile
imagesc(surround_t,[], all_animals_face_mean(:,5:8)')
yticks([1, 2,3,4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); 
yticklabels(stage_type); 
clim([-0.3,0.3]); colormap(ap.colormap('PWG'));
title('auditory passive')

%% facial movement figure across day


% 假设 A 是一个 6x1 的 cell 数组，其中每个元素是 2x4 的 cell 矩阵
% 每个 A{i}{j, k} 是一个 50xN 的矩阵;
A=all_animal_face_single_day(animals_group==selected_group);
 example=[3 5 5 3 3 5 5 3]
for curr_order=1:length(A)
    AA=reshape(A{curr_order}',1,[]);
    colSizes =  cellfun(@(y) size(y, 2),  AA, 'UniformOutput', true);
    for s=1:length(AA)
        if length(AA{s})<example(s)
            AA{s}(length(AA{s})+1:example(s))=repmat({nan(120, 3)}, 1, (example(s)-length(AA{s})));
        end
    end
    B{curr_order}=reshape(AA,4,2)'
end

BB_lcr_face=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z(:,3),y,'UniformOutput',false)),x(1,:),'UniformOutput',false)),B,'UniformOutput',false)
BB_hml_face=cellfun(@(x) cell2mat(cellfun(@(y) cell2mat(cellfun(@(z) z(:,2),y,'UniformOutput',false)),x(2,:),'UniformOutput',false)),B,'UniformOutput',false)

 figure('Position',[50 50 1000 500]);
a1=nexttile()
% subplot(2,2,1)
imagesc(surround_t,[],mean(cat(3,BB_lcr_face{:}),3,'omitnan')')
clim([-0.3,0.3]); colormap(a1,ap.colormap('PWG'));
hold on; xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);

ylim([0.5 13.5])
yline(3.5);yline(8.5);yline(13.5);
title('visual passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签

a2=nexttile()
% subplot(2,2,1)
imagesc(surround_t,[],mean(cat(3,BB_hml_face{:}),3,'omitnan')')
clim([-0.3,0.3]); colormap(a2,ap.colormap('PWG'));
ylim([0.5 13.5])
yline(3.5);yline(8.5);yline(13.5);
hold on; xline(0,'Color',[1 0.5 0.5]);xline(passive_boundary,'Color',[1 0.5 0.5]);

title('auditory passive')
xlabel('time(s)')
yticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels(stage_type); % 设置对应的标签
colorbar('eastoutside')
% plot mPFC activity across day
nexttile
% subplot(2,2,3)
lcr_all_face=cell2mat(cellfun(@(x) max(x(period_passive_face,:),[],1),BB_lcr_face,'UniformOutput',false)')
lcr_mean_line_face=mean(lcr_all_face,1,'omitnan');
lcr_sem_line_face=std(lcr_all_face,'omitnan')/sqrt(size(lcr_all_face,1));
hold on
ap.errorfill(1:3,lcr_mean_line_face(1:3), lcr_sem_line_face(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,lcr_mean_line_face(4:8), lcr_sem_line_face(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,lcr_mean_line_face(9:13), lcr_sem_line_face(9:13),curr_color,0.1,0.5);
% ap.errorfill(14:16,lcr_mean_line(14:16), lcr_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.1*[-0.5 3.5])
xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('face movement')

% plot mPFC activity across day
nexttile
% subplot(2,2,3)
hml_all_face=cell2mat(cellfun(@(x) max(x(period_passive_face,:),[],1),BB_hml_face,'UniformOutput',false)')
hml_mean_line_face=mean(hml_all_face,1,'omitnan');
hml_sem_line_face=std(hml_all_face,'omitnan')/sqrt(size(hml_all_face,1));
hold on
ap.errorfill(1:3,hml_mean_line_face(1:3), hml_sem_line_face(1:3),curr_color,0.1,0.5);
ap.errorfill(4:8,hml_mean_line_face(4:8), hml_sem_line_face(4:8),curr_color,0.1,0.5);
ap.errorfill(9:13,hml_mean_line_face(9:13), hml_sem_line_face(9:13),curr_color,0.1,0.5);
% ap.errorfill(14:16,lcr_mean_line(14:16), lcr_sem_line(14:16),curr_color,0.1,0.5);
ylim(0.1*[-0.5 3.5])
xticks([2, 6,11,15]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels(stage_type); % 设置对应的标签
ylabel('face movement')
sgtitle([group_name ' 0-' num2str(passive_boundary) 's'])

saveas(gcf,[Path 'figures\use_all_trials\heatmap and plot face movement across day ' group_name ' 0-' num2str(1000*passive_boundary) 'ms' ], 'jpg');

% figure;
% ss=mean(cat(3,BB_lcr_face{:}),3,'omitnan')
% plot(ss(:,4:8))