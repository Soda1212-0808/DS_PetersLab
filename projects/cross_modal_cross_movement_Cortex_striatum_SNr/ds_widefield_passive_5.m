
%% TESTING BATCH PASSIVE WIDEFIELD
clear all
Path = 'Y:\Data process\project_cross_model_cross_movement\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-5:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
% master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
%     'widefield_alignment','U_master.mat');


animals={'DS025'};


passive_workflow_all={'lcr_passive_checkerboard','lcr_passive_grating_size40','lcr_passive_squareHorizontalStripes','hml_passive_audio_Freq2'}

for curr_passive=1:4

    passive_workflow = passive_workflow_all{curr_passive};


    for curr_animal_idx=1:length(animals)
        main_preload_vars = who;

        animal=animals{curr_animal_idx};
        fprintf('%s\n', ['start  ' animal ]);
        fprintf('%s\n', ['start saving ' passive_workflow ' files...']);


        training_workflow =...
        ['stim_wheel_Vcenter_cross_movement_stage*|stim_wheel_Afreq2_cross_movement_stage*'];


        recordings_passive = plab.find_recordings(animal,[],passive_workflow);


        recordings_training = plab.find_recordings(animal,[],training_workflow);

        % if animals are LAP018,AP019,AP020,AP021,AP022

        % bufferA=~ismember({recordings_passive.day},{recordings_training.day});
        % bufferA = (sum(bufferA) >=3) * [1 1 1, zeros(1, numel(bufferA)-3)] + (sum(bufferA) < 3) * bufferA;
        % recordings_wf_passive =[ recordings_passive( ...
        %     cellfun(@any,{recordings_passive.widefield}) & ...
        %     ~[recordings_passive.ephys] & ...
        %     (ismember({recordings_passive.day},{recordings_training.day})|...
        %     bufferA    ))];

        recordings_wf_passive =[ recordings_passive( ...
            cellfun(@any,{recordings_passive.widefield}) & ...
            ~[recordings_passive.ephys] & ...
            (ismember({recordings_passive.day},{recordings_training.day})    ))];


        recordings_wf_training = recordings_training( ...
            cellfun(@any,{recordings_training.widefield}) & ...
            ~[recordings_training.ephys] & ...
            ismember({recordings_training.day},{recordings_passive.day}));



        %%是否存在保存过之前的数据的文件
        if     exist ([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ])==2
            load([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ])
            % load([Path '\' passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ])

            %查看目前文件的长度以及如果存在没有alignment的情况下要去除
            n_buffer= find(~all(img_size== [450, 426],2), 1);
            if isempty (n_buffer)
                file_length=  length(wf_px);
                problem=0;
            else file_length=n_buffer;
                problem=1;
            end
        else
            wf_px_baseline = cell(1,3);
            wf_px_baseline_kernels = cell(1,3);
            wf_px = cell(size(recordings_wf_passive));
            wf_px_kernels=cell(size(recordings_wf_passive));
            wf_px_kernels_encode=cell(size(recordings_wf_passive));

            wf_px_all=cell(size(recordings_wf_passive));
            trial_state=cell(size(recordings_wf_passive));
            trial_type=cell(size(recordings_wf_passive));
            trial_stim_time=cell(size(recordings_wf_passive));




            all_groups_name = cell(size(recordings_wf_passive))';
            all_groups_name_baseline = cell(1,3)';

            % workflow_type=zeros(length(recordings_wf_passive),1);
            % workflow_type_name=cell(length(recordings_wf_passive),1);
            % workflow_type_name_merge=cell(length(recordings_wf_passive),1);


            file_length=1;
            problem=0;
            img_size = nan(length(recordings_wf_passive),2);
        end

        workflow_day={recordings_wf_passive.day}';
        surround_time = [-5,5];
        surround_sample_rate = 100;
        surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


        if ~(file_length==length(recordings_wf_passive)&problem==0)
            % curr_recording =1: length(recordings)
            for curr_recording =file_length:length(recordings_wf_passive)
             
                % Grab pre-load vars
                preload_vars = who;
                % Load data
                rec_day = recordings_wf_passive(curr_recording).day;
                rec_time = recordings_wf_passive(curr_recording).recording{end};
                if ~recordings_wf_passive(curr_recording).widefield(end)
                    continue
                end

                try
                    load_parts.mousecam = true;
                    load_parts.widefield = true;
                    load_parts.widefield_master = true;
                    ap.load_recording;
                catch me
                    warning('%s %s %s: load error, skipping \n >> %s', ...
                        animal,rec_day,rec_time,me.message)
                    continue
                end


                if contains(passive_workflow,'lcr_passive')
                    align_category_all = vertcat(trial_events.values.TrialStimX);
                elseif contains(passive_workflow,'hml_passive_audio')
                    align_category_all = vertcat(trial_events.values.StimFrequence);
                end


                % Get quiescent trials and stim onsets/ids
                %得到不动的trial
                stimOn_times=stimOn_times(1:length(stimOff_times));

                stim_window1 = [0,0.3];
                quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                    timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
                    1:length(stimOn_times))';

                % % Get quiescent trials, 但是保证任意一个stim的数量大于 5，如果没有大于stim_window的trial，则选择stim2move时间最多的5个trial
                stim2move_time= arrayfun(@(x) timelite.timestamps(find(wheel_move & (timelite.timestamps>= stimOn_times(x)),1))-stimOn_times(x),1:length(stimOn_times),'UniformOutput',false);
                stim2move_time(cellfun(@ isempty,stim2move_time))={1};
                stim2move_time=cell2mat(stim2move_time)';
                trial_stim_time{curr_recording}=stim2move_time;



                align_times = stimOn_times(quiescent_trials);
                align_category = align_category_all(quiescent_trials);

                % Align to stim onset
                surround_window = [-0.5,1];
                surround_samplerate = 35;
                t_passive = surround_window(1):1/surround_samplerate:surround_window(2);
                peri_event_t = reshape(align_times,[],1) + reshape(t_passive,1,[]);

                aligned_v = reshape(interp1(wf_t,wf_V',peri_event_t,'previous'), ...
                    length(align_times),length(t_passive),[]);

                align_id = findgroups(align_category);

                % 确定 align_id 中的唯一值
                unique_values = unique(align_id);
                all_groups_name{curr_recording}=unique(align_category);
                % 初始化一个空的结果数组
                aligned_v_avg1 = zeros( numel(unique_values),size(aligned_v, 2), size(aligned_v, 3));
                % 遍历每个唯一的值，对每个值进行处理
                for i = 1:numel(unique_values)
                    idx = align_id == unique_values(i);
                    % 检查当前组的大小
                    if sum(idx) > 1
                        % 如果当前组的大小大于1，则计算平均值
                        aligned_v_avg1(i,:,:) = nanmean(aligned_v(find(idx),:,:), 1);
                    else
                        % 如果当前组的大小等于1，则将对应位置设置为 NaN
                        aligned_v_avg1(i,:,:) = aligned_v(find(idx),:,:);
                    end
                end

                % 使用 permute 对结果进行重新排列
                aligned_v_avg = permute(aligned_v_avg1, [3, 2, 1]);

                % aligned_v_avg = permute(splitapply(@nanmean,aligned_v,align_id),[3,2,1]);
                aligned_v_avg_baselined = aligned_v_avg - nanmean(aligned_v_avg(:,t_passive < 0,:),2);

                %%all_trials
                peri_event_t_all= reshape(stimOn_times,[],1) + reshape(t_passive,1,[]);
                aligned_v_all = permute((reshape(interp1(wf_t,wf_V',peri_event_t_all,'previous'), length(stimOn_times),length(t_passive),[])), [3, 2, 1]);
                aligned_v_all_baslined = aligned_v_all-nanmean(aligned_v_all(:,t_passive < 0,:),2);

                wf_px_all{curr_recording}=aligned_v_all_baslined;
                trial_state{curr_recording}=quiescent_trials;
                trial_type{curr_recording}=align_category_all;

                % Convert to pixels and package
                % aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
                wf_px{curr_recording} =aligned_v_avg_baselined;
                img_size(curr_recording,:)=size(wf_avg);


                % % passive regressor 线性回归的数据
                wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];

                % old one do not use any more
                % Create regressors in the passive task
                stim_window2 = [0.1,0.8];

                non_quiescent_trials = arrayfun(@(x) any(wheel_move(...
                    timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
                    1:length(stimOn_times))';

                stim_drive_trials = arrayfun(@(x) any(wheel_move(...
                    timelite.timestamps > stimOn_times(x)+stim_window2(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window2(2)))& ...
                    ~any(wheel_move(...
                    timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
                    1:length(stimOn_times));

                if contains(bonsai_workflow,'lcr_passive')
                    align_category_all = vertcat(trial_events.values.TrialStimX);
                    align_category_all=align_category_all(1:length(stimOn_times));
                    stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == -90 ),wf_regressor_bins);
                    stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 0 ),wf_regressor_bins);
                    stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 90),wf_regressor_bins);
                elseif contains(bonsai_workflow,'hml_passive_audio')
                    align_category_all = vertcat(trial_events.values.StimFrequence);
                    align_category_all=align_category_all(1:length(stimOn_times));
                    stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == 4000 ),wf_regressor_bins);
                    stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 8000 ),wf_regressor_bins);
                    stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 12000),wf_regressor_bins);
                end
                move_regressor_random = histcounts(stimOn_times(non_quiescent_trials ),wf_regressor_bins);
                stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times(stim_drive_trials));
                % stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times);
                move_regressor_stim_drive = histcounts(stim_drive_time,wf_regressor_bins);
                regressors={stim_regressor;move_regressor_random;move_regressor_stim_drive};
                t_shifts = {[-10:30];[-10:30];[-10:30]};
                % Set cross validation (not necessary if just looking at kernels)
                cvfold = 5;
                
                % Do encoding regression
                [kernels_encode,predicted_signals,explained_var,predicted_signals_reduced] = ...
                    ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);


                % stim_regressors = cell2mat(arrayfun(@(x) ...
                %     histcounts(stimOn_times(align_category_all == x),wf_regressor_bins), ...
                %     unique(align_category_all),'uni',false));

                stim_regressors = arrayfun(@(x) ...
                    histcounts(stimOn_times(align_category_all == x),wf_regressor_bins), ...
                    unique(align_category_all),'uni',false);

stimMedial_times_1=[wf_t(1);(stimOff_times(1:end-1)+stimOn_times(2:end))/2]-0.001;
stimMedial_times_2=[(stimOff_times(1:end-1)+stimOn_times(2:end))/2;stimOff_times(end)+0.5]+0.001;

wf_t_sep=arrayfun(@(id) interp1([stimMedial_times_1(align_category_all == id);stimMedial_times_2(align_category_all ==id)],...
    [ones(sum((align_category_all == id)),1); zeros(sum((align_category_all ==id)),1)],...
    wf_t,'previous')==1,  unique(align_category_all),'UniformOutput',false);


                n_components = 400;
                frame_shifts = -10:30;
                lambda = 15;
          
                success = false; % 标记变量，判断是否成功运行
                while ~success
                    try

                        disp(['Running with n_components = ', num2str(n_components)]);

                        [kernels,predicted_signals,explained_var] = ...
                         cellfun(@(x,y)   ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1)),-frame_shifts,lambda),...
                         wf_t_sep, stim_regressors ,'UniformOutput',false );
                          kernels=cat(3,kernels{:});

                        success = true; % 如果没有报错，则成功运行
                    catch ME
                        disp(['Error: ', ME.message]);
                        n_components = n_components - 1; % 变量 a 递减
                        if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
                            error('n_components 过小，无法继续运行');
                        end
                    end
                end

                disp('running successfully');



                % % Convert kernels V to pixels
                % wf_px_kernels{curr_recording} = cellfun(@(x) permute(x,[3,2,1]),kernels,'uni',false);
                wf_px_kernels{curr_recording} = kernels;
                wf_px_kernels_encode{curr_recording} = kernels_encode;



                % Prep for next loop
                ap.print_progress_fraction(curr_recording,length(recordings_wf_passive));
                clearvars('-except',preload_vars{:});


            end

            task_name=(arrayfun(@(n) recordings_wf_training(n).workflow{end},1:length(recordings_wf_training),'UniformOutput',false))';

            save([Path passive_workflow '\' animal '_' passive_workflow '.mat' ],'wf_px','wf_px_kernels','wf_px_kernels_encode','all_groups_name','img_size','workflow_day','task_name','-v7.3')
            % save([Path passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ],'wf_px_all','trial_type','trial_state','-v7.3')

        end
        % task_name=(arrayfun(@(n) recordings_wf_training(n).workflow{end},1:length(recordings_wf_training),'UniformOutput',false))';
        % 
        %     save([Path passive_workflow '\' animal '_' passive_workflow '.mat' ],'wf_px','wf_px_kernels','wf_px_kernels_encode','all_groups_name','img_size','workflow_day','task_name','-v7.3')


        clearvars('-except',main_preload_vars{:});


    end

end
