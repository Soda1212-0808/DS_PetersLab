
clear all
clc
% Path = 'D:\Da_Song\Data_analysis\mice\process\processed_data_v2\';
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
% animals={'DS001'}
animals_type=[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2];

animals_group = [1 1 1 1 1 1 2 2 2 3 3 3 4 4 4 4 4];

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

surround_frames=60;
surround_t = [-surround_frames+1:surround_frames]./30;



% move_kernels=1/surround_samplerate*[-30:30];

passive_boundary=0.2;
period_passive=find(t_passive>0 & t_passive<passive_boundary);
period_task=find(t_task>0 & t_task<passive_boundary);
period_kernels_stim=find(t_kernels_stim>0 & t_kernels_stim<passive_boundary);
period_kernels_move=find(t_kernels_move>0 & t_kernels_move<passive_boundary);
period_passive_face=find(surround_t>0&surround_t<passive_boundary);


all_animal_face=repmat({cell(length(animals),1)},2,1);
all_animal_face_iti=repmat({cell(length(animals),1)},2,1);
all_animal_imaging=repmat({cell(length(animals),1)},2,1);
all_animal_imaging_iti=repmat({cell(length(animals),1)},2,1);
all_animal_imaging_plot=repmat({cell(length(animals),1)},2,1);



allmice_ca = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_facial = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_ca_across_time = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_facials_across_time = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充

% 1是mPFC,2是barrel cortex
imaging_activity=1;
if  imaging_activity==1
    cortex_name='mPFC';
else cortex_name='barrel cotex';
end


passive_workflow_all={'lcr_passive','hml_passive_audio'};
for curr_workflow=1:2
    passive_workflow=passive_workflow_all{curr_workflow};

    if strcmp(passive_workflow,'lcr_passive')
        conditions = [-90, 0, 90];
    elseif strcmp(passive_workflow,'hml_passive_audio')
        conditions = [4000, 8000, 12000];
    end

    for curr_animal_idx=1:length(animals)
        main_preload_vars = who;
        animal=animals{curr_animal_idx};
        fprintf('%s\n', ['start  ' animal ]);
        fprintf('%s\n', ['start saving files in ' passive_workflow]);

        raw_data_face=load([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ]);
        raw_data_passive=load([Path 'mat_data\' passive_workflow '\' animal '_' passive_workflow '.mat' ]);

        fprintf('%s\n', ['File loading completed of  ' animal ]);

        if animals_type(curr_animal_idx) == 1
            order = [0 ,1, 2, 3];
            stage_type={'baseline','visual','auditory','mixed'};
        elseif animals_type(curr_animal_idx) == 2
            order = [0, 2, 1, 3];
            stage_type={'baseline','auditory','visual','mixed'};
        else
            error('Unsupported value for variable. Must be 1 or 2.');
        end
        mean_gain = mean(raw_data_face.camera_task_gain, 'omitnan');
        raw_data_face.camera_task_gain(isnan(raw_data_face.camera_task_gain)) = mean_gain;
        raw_data_face.camera_task_gain(raw_data_face.camera_task_gain==0) = mean_gain;

        nonemptyidx=cellfun(@(x) ~isempty(x), raw_data_face.camera_plot,'UniformOutput',true);
        % raw_data_face.camera_plot_normalized(nonemptyidx,:)= cellfun(@(x,y) (x-mean(x(surround_t<0,:),'all'))/y,raw_data_face.camera_plot(nonemptyidx),num2cell(raw_data_face.camera_task_gain(nonemptyidx)),'UniformOutput',false);
        % raw_data_face.camera_plot_iti_normalized(nonemptyidx,:)= cellfun(@(x,y,z) cellfun(@(a) (a-mean(z(surround_t<0,:),'all'))/y,x,'UniformOutput',false),raw_data_face.camera_plot_iti(nonemptyidx),num2cell(raw_data_face.camera_task_gain(nonemptyidx)),raw_data_face.camera_plot(nonemptyidx),'UniformOutput',false);

        raw_data_face.camera_plot_normalized(nonemptyidx,:)= cellfun(@(x,y) (x),raw_data_face.camera_plot(nonemptyidx),num2cell(raw_data_face.camera_task_gain(nonemptyidx)),'UniformOutput',false);
        raw_data_face.camera_plot_iti_normalized(nonemptyidx,:)= cellfun(@(x,y,z) cellfun(@(a) (a),x,'UniformOutput',false),raw_data_face.camera_plot_iti(nonemptyidx),num2cell(raw_data_face.camera_task_gain(nonemptyidx)),raw_data_face.camera_plot(nonemptyidx),'UniformOutput',false);



        % mPFC activity- barrel cotical activity
        % raw_data_face.image_plot_reduced(nonemptyidx,1)=cellfun(@(x,y) x-y, raw_data_face.image_plot(nonemptyidx),raw_data_face.image_plot_barrel(nonemptyidx),'UniformOutput',false);
        % raw_data_face.image_plot_iti_reduced(nonemptyidx,1)=cellfun(@(x,y) cellfun(@(a,b) a-b,x,y,'UniformOutput',false ), raw_data_face.image_plot_iti(nonemptyidx),raw_data_face.image_plot_barrel_iti(nonemptyidx),'UniformOutput',false);
        
        % mPFC activity
        if imaging_activity==1
         
        raw_data_face.image_plot_reduced(nonemptyidx,1)=cellfun(@(x,y) x, raw_data_face.image_plot(nonemptyidx),raw_data_face.image_plot_barrel(nonemptyidx),'UniformOutput',false);
        raw_data_face.image_plot_iti_reduced(nonemptyidx,1)=cellfun(@(x,y) cellfun(@(a,b) a,x,y,'UniformOutput',false ), raw_data_face.image_plot_iti(nonemptyidx),raw_data_face.image_plot_barrel_iti(nonemptyidx),'UniformOutput',false);
        else
             raw_data_face.image_plot_reduced(nonemptyidx,1)=cellfun(@(x,y) y, raw_data_face.image_plot(nonemptyidx),raw_data_face.image_plot_barrel(nonemptyidx),'UniformOutput',false);
        raw_data_face.image_plot_iti_reduced(nonemptyidx,1)=cellfun(@(x,y) cellfun(@(a,b) b,x,y,'UniformOutput',false ), raw_data_face.image_plot_iti(nonemptyidx),raw_data_face.image_plot_barrel_iti(nonemptyidx),'UniformOutput',false);
        end


        % 处理两类分析，第一类是task kernels的分析
        idxx=0;
        figure;
        for curr_order=order


            idxx=idxx+1;
            non_idx=cellfun(@(x) ~isempty(x),raw_data_face.trial_type,'UniformOutput',true);

            % 设置初始参数
            if curr_order == 0
                numbers = 3;learned = 0;
            elseif curr_order == 1 || curr_order == 2
                numbers = 5;learned = 1;
            elseif curr_order == 3
                numbers = 3;learned = 1;
            end

            % 查找索引
            all_idx = find(raw_data_passive.workflow_type == curr_order & (raw_data_passive.learned_day == learned)'&non_idx, numbers, "last");
            % 若找不到符合 learned 条件的索引，则仅根据 workflow_type 查找
            if isempty(all_idx)
                all_idx = find(raw_data_passive.workflow_type == curr_order&non_idx, numbers, "last");
            end




            index_type=raw_data_face.trial_type(all_idx);
            if ~isempty(index_type)
                facial_stim=raw_data_face.camera_plot_normalized(all_idx);
                facial_stim_sp3  =  arrayfun(@(cond) cellfun(@(x, tr_type) x(:, tr_type == cond ), facial_stim, index_type, 'UniformOutput', false), conditions, 'UniformOutput', false);
               
                idx_0=cellfun(@(data) cellfun(@(x) find(any(x~=0)), data, 'UniformOutput', false) ,facial_stim_sp3,'UniformOutput',false);
                % 删除全0数据
                facial_stim_sp3= cellfun(@(data,idx) cellfun(@(x,y) x(:,y),data,idx,'UniformOutput',false ),facial_stim_sp3,idx_0,'UniformOutput',false);
                % 删除全空数据
                facial_stim_sp3 = cellfun(@(x) x(~cellfun('isempty', x)), facial_stim_sp3, 'UniformOutput', false);
                facial_stim_sp3_all=cellfun(@(x) cat(2,x{:}),facial_stim_sp3,'UniformOutput',false);
                facial_stim_sp3_all_mean= cellfun(@(y) mean(y(period_passive_face ,:),1), facial_stim_sp3_all,'UniformOutput',false);
                facial_group_mean_4group = cellfun(@(x) arrayfun(@(g) mean(x(discretize(x, [-Inf, quantile(x, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4),facial_stim_sp3_all_mean,'UniformOutput',false);

                  allmice_facial{curr_animal_idx,curr_workflow}(idxx,:)=facial_stim_sp3_all_mean;
                 allmice_facials_across_time{curr_animal_idx,curr_workflow}(idxx,:)= facial_stim_sp3_all;

              
                    
                image_stim=raw_data_face.image_plot_reduced(all_idx);
                image_stim_sp3  =  arrayfun(@(cond) cellfun(@(x, tr_type) x(:, tr_type == cond ), image_stim, index_type, 'UniformOutput', false), conditions, 'UniformOutput', false);
                
                image_stim_sp3= cellfun(@(data,idx) cellfun(@(x,y) x(:,y),data,idx,'UniformOutput',false ),image_stim_sp3,idx_0,'UniformOutput',false);
                image_stim_sp3 = cellfun(@(x) x(~cellfun('isempty', x)), image_stim_sp3, 'UniformOutput', false);

                image_stim_sp3_all=cellfun(@(x) cat(2,x{:}),image_stim_sp3,'UniformOutput',false);
                image_stim_sp3_all_mean= cellfun(@(y) mean(y(period_passive ,:),1), image_stim_sp3_all,'UniformOutput',false);
                % image_stim_sp3_all_mean= cellfun(@(y) max(y(period_passive ,:),[],1), image_stim_sp3_all,'UniformOutput',false);
                image_stim_sp3_all_mean_4group= cellfun(@(x,y) arrayfun(@(g) mean(x(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),'omitnan'), 1:4)  ,image_stim_sp3_all_mean, facial_stim_sp3_all_mean,'UniformOutput',false);
                image_stim_sp3_all_plot_mean_4group= cellfun(@(x,y) arrayfun(@(g) mean(x(:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),2,'omitnan'), 1:4,'UniformOutput',false)  ,image_stim_sp3_all, facial_stim_sp3_all_mean,'UniformOutput',false);

                allmice_ca{curr_animal_idx,curr_workflow}(idxx,:)=image_stim_sp3_all_mean;
                allmice_ca_across_time{curr_animal_idx,curr_workflow}(idxx,:)=image_stim_sp3_all;





                % 计算iti的 facial and imaging data
                facial_iti=raw_data_face.camera_plot_iti_normalized(all_idx);
                image_iti=raw_data_face.image_plot_iti_reduced(all_idx);
                facial_iti_split =cellfun(@(a)  cellfun(@(b) arrayfun(@(i) mean(b((i-1)*length(period_passive_face)+1 : i*length(period_passive_face))), 1:floor(length(b) / length(period_passive_face))),a,'UniformOutput',false),facial_iti,'UniformOutput',false);
                non_nantrial= cellfun(@(x) cellfun(@(y) ~(isempty(y)| sum(isnan(y))),x,'UniformOutput',true   ),facial_iti,'UniformOutput',false);

                image_iti_split =cellfun(@(a,a1) ( cellfun(@(b) arrayfun(@(i) mean(b((i-1)*length(period_passive)+1 : i*length(period_passive))), 1:floor(length(b) / length(period_passive))),a(a1),'UniformOutput',false))',image_iti,non_nantrial,'UniformOutput',false);
                % image_iti_split =cellfun(@(a,a1) ( cellfun(@(b) arrayfun(@(i) max(b((i-1)*length(period_passive)+1 : i*length(period_passive))), 1:floor(length(b) / length(period_passive))),a(a1),'UniformOutput',false))',image_iti,non_nantrial,'UniformOutput',false);

                facial_iti_split=cellfun(@(a,a1,a2)  cellfun(@(b,b1)  b(1:length(b1)),a(a2),a1,'UniformOutput',false  ) ,facial_iti_split,image_iti_split,non_nantrial,'UniformOutput',false);

                facial_iti_split_mean=cell2mat(cellfun(@(x) cell2mat(x'),facial_iti_split,'UniformOutput',false)');
                image_iti_split_mean=cell2mat(cellfun(@(x) cell2mat(x'),image_iti_split,'UniformOutput',false)');
                facial_iti_split_mean_4group=  cellfun(@(x,y) arrayfun(@(g) mean(x(discretize(x, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),'omitnan'), 1:4)  ,repmat({facial_iti_split_mean},1,3), facial_stim_sp3_all_mean,'UniformOutput',false);
                image_iti_split_mean_4group=  cellfun(@(x,y,z) arrayfun(@(g) mean(x(discretize(y, [-Inf, quantile(z, [0.25, 0.5, 0.75]), Inf]) == g),'omitnan'), 1:4)  ,repmat({image_iti_split_mean},1,3),repmat({facial_iti_split_mean},1,3), facial_stim_sp3_all_mean,'UniformOutput',false);
            else
                facial_group_mean_4group=repmat({nan(1,4)},1,3);
                facial_iti_split_mean_4group=repmat({nan(1,4)},1,3);
                image_stim_sp3_all_mean_4group=repmat({nan(1,4)},1,3);
                
                image_iti_split_mean_4group=repmat({nan(1,4)},1,3);

                image_stim_sp3_all_plot_mean_4group=arrayfun(@(x) cellfun(@(y) single(nan(53, 1)), cell(1, 4), 'UniformOutput', false), cell(1, 3), 'UniformOutput', false);
            end

               


            all_animal_face{curr_workflow}{curr_animal_idx,idxx}=facial_group_mean_4group;
            all_animal_face_iti{curr_workflow}{curr_animal_idx,idxx}=facial_iti_split_mean_4group;
            all_animal_imaging{curr_workflow}{curr_animal_idx,idxx}=image_stim_sp3_all_mean_4group;
            all_animal_imaging_iti{curr_workflow}{curr_animal_idx,idxx}=image_iti_split_mean_4group;
            all_animal_imaging_plot{curr_workflow}{curr_animal_idx,idxx}=image_stim_sp3_all_plot_mean_4group;

            nexttile
            hold on
            cellfun(@(x,y) plot(x,y,"LineWidth",2),facial_group_mean_4group,image_stim_sp3_all_mean_4group,'UniformOutput',false)
            cellfun(@(x,y) plot(x,y,"LineWidth",2),facial_iti_split_mean_4group,image_iti_split_mean_4group,'UniformOutput',false)
            ylim([-0.001 0.005])
            set(gca, 'ColorOrder', [0.2 0.2 1; 0.2 0.2 0.2; 1 0.2 0.2;0.8 0.8 1; 0.8 0.8 0.8; 1 0.8 0.8]); % 蓝、黑、红
            ylabel('df/f')
            xlabel('face movement')
            title(stage_type{idxx})
            sgtitle([animal '' passive_workflow])


        end




        drawnow

        clearvars('-except',main_preload_vars{:});

    end
end


%% select group
animals_group = [1 1 1 1 1 5 5 2 2 3 3 3 4 4 4 4 4];
selected_group=1;
group_names={'V-A','A-V'};
colors={[0 0 1],[1 0 0]};
if selected_group == 1
    stage_type={'naive', 'visual','auditory','mixed'};
    group_name=group_names{1};
    curr_color=colors{1};
elseif selected_group == 4
    stage_type={'naive' ,'auditory','visual','mixed'};
    group_name=group_names{2};
    curr_color=colors{2};

else
    error('Unsupported value for variable. Must be 1 or 2.');
end



%%
figure('Position',[420 420 800 300]);
for curr_workflow=1:2
    selected_face=all_animal_face{curr_workflow}((animals_group==selected_group),:);
    selected_image=cellfun(@(y) cellfun(@(x) single(x),y,'UniformOutput',false),all_animal_imaging{curr_workflow}((animals_group==selected_group),:),'UniformOutput',false);
    selected_face_iti=all_animal_face_iti{curr_workflow}((animals_group==selected_group),:);
    selected_image_iti=cellfun(@(y) cellfun(@(x) single(x),y,'UniformOutput',false),all_animal_imaging_iti{curr_workflow}((animals_group==selected_group),:),'UniformOutput',false);


    % 使用 cellfun 计算每一列的平均值，忽略空单元格
    selected_face_mean  = cellfun(@(col) cellfun(@(pos) mean(cell2mat(cellfun(@(x) x{pos}, col, 'UniformOutput', false)), 1, 'omitnan'), ...
        num2cell(1:3), 'UniformOutput', false), ...
        num2cell(selected_face, 1), 'UniformOutput', false);

    selected_image_mean  = cellfun(@(col) cellfun(@(pos) mean(cell2mat(cellfun(@(x) x{pos}, col, 'UniformOutput', false)), 1, 'omitnan'), ...
        num2cell(1:3), 'UniformOutput', false), ...
        num2cell(selected_image, 1), 'UniformOutput', false);

    % 使用 cellfun 计算每一列的平均值，忽略空单元格
    selected_face_iti_mean  = cellfun(@(col) cellfun(@(pos) mean(cell2mat(cellfun(@(x) x{pos}, col, 'UniformOutput', false)), 1, 'omitnan'), ...
        num2cell(1:3), 'UniformOutput', false), ...
        num2cell(selected_face_iti, 1), 'UniformOutput', false);

    selected_image_iti_mean  = cellfun(@(col) cellfun(@(pos) mean(cell2mat(cellfun(@(x) x{pos}, col, 'UniformOutput', false)), 1, 'omitnan'), ...
        num2cell(1:3), 'UniformOutput', false), ...
        num2cell(selected_image_iti, 1), 'UniformOutput', false);


    for curr_satge=1:4
        nexttile;hold on
        cellfun(@(x,y) plot(x,y,"LineWidth",2),selected_face_mean{curr_satge},selected_image_mean{curr_satge},'UniformOutput',false)
        cellfun(@(x,y) plot(x,y,"LineWidth",2),selected_face_iti_mean{curr_satge},selected_image_iti_mean{curr_satge},'UniformOutput',false)

        ylim([-0.001 0.003])
        set(gca, 'ColorOrder', [0.2 0.2 1; 0.2 0.2 0.2; 1 0.2 0.2;0.8 0.8 1; 0.8 0.8 0.8; 1 0.8 0.8]); % 蓝、黑、红
        ylabel('df/f')
        xlabel('face movement')
        title(stage_type{curr_satge})

    end

end
sgtitle( [cortex_name ' in ' group_name])

 saveas(gcf,[Path 'figures\summary\' cortex_name  ' vs face movement in ' group_name ], 'jpg');

%% 平均的image
figure('Position',[420 420 800 300]);
for curr_workflow=1:2
    selected_face=all_animal_face{curr_workflow}((animals_group==selected_group),:);
     % selected_image_plot=cellfun(@(y) cellfun(@(x) single(x),y,'UniformOutput',false),all_animal_imaging_plot{curr_workflow}((animals_group==selected_group),:),'UniformOutput',false);

    selected_image_plot=all_animal_imaging_plot{curr_workflow}((animals_group==selected_group),:);
    
    % 使用 cellfun 计算每一列的平均值，忽略空单元格
    selected_face_mean  = cellfun(@(col) arrayfun(@(pos) mean(cell2mat(cellfun(@(x) x{pos}, col, 'UniformOutput', false)), 1, 'omitnan'), ...
        1:3, 'UniformOutput', false), ...
        num2cell(selected_face, 1), 'UniformOutput', false);

       selected_image_plo_mean  = cellfun(@(col) arrayfun(@(pos) arrayfun(@(idx) nanmean(cell2mat(cellfun(@(xx) xx{idx}, cellfun(@(x) x{pos}, col, 'UniformOutput', false), 'UniformOutput', false)'), 2), 1:4, 'UniformOutput', false), ...
        1:3, 'UniformOutput', false), ...
        num2cell(selected_image_plot, 1), 'UniformOutput', false);


    for curr_satge=1:4
        
        
        nexttile;hold on
        cellfun(@(x,y) plot(t_passive,x,"LineWidth",2),selected_image_plo_mean{curr_satge}{4-curr_workflow},'UniformOutput',false)
            color_scale=[0, 0, 0;0.3, 0.2, 0.1;0.6, 0.4, 0.2;0.9, 0.75, 0.43];
xline(0),xline(0.15)
        ylim([-0.001 0.005])
        set(gca, 'ColorOrder', color_scale); % 蓝、黑、红
        ylabel('df/f')
        xlabel('time(s)')
        title(stage_type{curr_satge})

    end

end
sgtitle(group_name)
