
%% TESTING BATCH PASSIVE WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\new\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-5:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');


for x=2
    if x==1
        animals = {'DS001','DS007','DS010','DS011','AP018','AP019','AP020','AP021','AP022'};type_seq=1; %v-a
        % else animals = {'DS000','DS003','DS004','DS006','DS013','DS014','DS015','DS016'};type_seq=2; %a-v
    else animals = {'DS015','DS016'};type_seq=2; %a-v

    end

    for curr_animal_idx=1:length(animals)
        animal=animals{curr_animal_idx};
        fprintf('%s\n', ['start  ' animal ]);

        for ss=1:2
            main_preload_vars = who;
            if ss==1
                passive_workflow = 'hml_passive_audio';
            elseif ss==2  passive_workflow = 'lcr_passive';
            end

            fprintf('%s\n', ['start saving ' passive_workflow ' files...']);
            % use_workflow = {'stim_wheel_right_stage2_mixed_VA$|stim_wheel_right_frequency_stage2_mixed_VA$'};
            training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$';

            % training_workflow = {'stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$'};
            recordings_passive = plab.find_recordings(animal,[],passive_workflow);


            recordings_training = plab.find_recordings(animal,[],training_workflow);

            recordings = recordings_passive( ...
                cellfun(@any,{recordings_passive.widefield}) & ...
                ~[recordings_passive.ephys] & ...
                ismember({recordings_passive.day},{recordings_training.day}));

            recordings2 = recordings_training( ...
                cellfun(@any,{recordings_training.widefield}) & ...
                ~[recordings_training.ephys] & ...
                ismember({recordings_training.day},{recordings_passive.day}));


            %%是否存在保存过之前的数据的文件
            if     exist ([Path  animal '_' passive_workflow '.mat' ])==2
                load([Path  animal '_' passive_workflow '.mat' ])

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
                wf_px = cell(size(recordings));
                wf_px_kernels=cell(size(recordings));

                wf_px_all=cell(size(recordings));
                trial_state=cell(size(recordings));
                trial_type=cell(size(recordings));



                all_groups_name = cell(size(recordings))';
                all_groups_name_baseline = cell(1,3)';

                workflow_type= nan(length(recordings),1);
                file_length=1;
                problem=0;
                img_size = nan(length(recordings),2);
            end
            workflow_day={recordings.day}';

            surround_time = [-5,5];
            surround_sample_rate = 100;
            surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
            n_trials_water = nan(length(recordings),2);
            frac_move_day = nan(length(recordings),1);
            success = nan(length(recordings),1);
            rxn_med = nan(length(recordings),1);
            frac_move_stimalign = nan(length(recordings),length(surround_time_points));
            rxn_stat_p = nan(length(recordings),1);

            %%仅在第一次分析的时候跑该数据
            if ~ (exist ([Path  animal '_' passive_workflow '.mat' ])==2)
                for curr_baseline=1:3

                    % Grab pre-load vars
                    preload_vars = who;
                    % Load data
                    rec_day = recordings_passive(curr_baseline).day;
                    rec_time = recordings_passive(curr_baseline).recording{end};
                    if ~recordings_passive(curr_baseline).widefield(end)
                        continue
                    end

                    try
                        load_parts.mousecam = false;
                        load_parts.widefield = true;
                        load_parts.widefield_master = true;
                        ap.load_recording;
                    catch me
                        warning('%s %s %s: load error, skipping \n >> %s', ...
                            animal,rec_day,rec_time,me.message)
                        continue
                    end
                    % Get quiescent trials and stim onsets/ids
                    stim_window1 = [0,0.1];
                    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                        timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
                        timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
                        1:length(stimOn_times))';

                    align_times = stimOn_times(quiescent_trials);
                    if strcmp(passive_workflow,'lcr_passive')
                        align_category_all = vertcat(trial_events.values.TrialStimX);
                    elseif strcmp(passive_workflow,'hml_passive_audio')
                        align_category_all = vertcat(trial_events.values.StimFrequence);
                    end

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

                    all_groups_name_baseline{curr_baseline}=unique(align_category);

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

                    % Convert to pixels and package
                    % aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
                    wf_px_baseline{curr_baseline} =aligned_v_avg_baselined;

                    wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
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

                    if strcmp(bonsai_workflow,'lcr_passive')
                        align_category_all = vertcat(trial_events.values.TrialStimX);
                        stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == -90 ),wf_regressor_bins);
                        stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 0 ),wf_regressor_bins);
                        stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 90),wf_regressor_bins);
                    elseif strcmp(bonsai_workflow,'hml_passive_audio')
                        align_category_all = vertcat(trial_events.values.StimFrequence);
                        stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == 4000 ),wf_regressor_bins);
                        stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 8000 ),wf_regressor_bins);
                        stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 12000),wf_regressor_bins);
                    end
                    move_regressor_random = histcounts(stimOn_times(non_quiescent_trials ),wf_regressor_bins);
                    stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times(stim_drive_trials));
                    % stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times);
                    move_regressor_stim_drive = histcounts(stim_drive_time,wf_regressor_bins);
                    regressors={stim_regressor;move_regressor_random;move_regressor_stim_drive};
                    t_shifts = {[-5:30];[-30:30];[-30:30]};
                    % Set cross validation (not necessary if just looking at kernels)
                    cvfold = 5;
                    % Do regression
                    [kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
                        ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

                    % % Convert kernels V to pixels
                    wf_px_baseline_kernels{curr_baseline} = cellfun(@(x) permute(x,[3,2,1]),kernels,'uni',false);


                    % Prep for next loop
                    ap.print_progress_fraction(curr_baseline,3);
                    clearvars('-except',preload_vars{:});


                end

            end

            if ~(file_length==length(recordings)&problem==0)
                % curr_recording =1: length(recordings)
                for curr_recording =file_length:length(recordings)


                    % Grab pre-load vars
                    preload_vars = who;
                    % Load data
                    rec_day = recordings(curr_recording).day;
                    rec_time = recordings(curr_recording).recording{end};
                    if ~recordings(curr_recording).widefield(end)
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
                    % Get quiescent trials and stim onsets/ids
                    %得到不动的trial
                    stim_window1 = [0,0.1];
                    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                        timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
                        timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
                        1:length(stimOn_times))';

                    align_times = stimOn_times(quiescent_trials);

                    if strcmp(passive_workflow,'lcr_passive')
                        align_category_all = vertcat(trial_events.values.TrialStimX);
                    elseif strcmp(passive_workflow,'hml_passive_audio')
                        align_category_all = vertcat(trial_events.values.StimFrequence);
                    end

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

                    if strcmp(bonsai_workflow,'lcr_passive')
                        align_category_all = vertcat(trial_events.values.TrialStimX);
                        stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == -90 ),wf_regressor_bins);
                        stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 0 ),wf_regressor_bins);
                        stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 90),wf_regressor_bins);
                    elseif strcmp(bonsai_workflow,'hml_passive_audio')
                        align_category_all = vertcat(trial_events.values.StimFrequence);
                        stim_regressor(1,:) =  histcounts(stimOn_times(align_category_all == 4000 ),wf_regressor_bins);
                        stim_regressor(2,:) =  histcounts(stimOn_times(align_category_all == 8000 ),wf_regressor_bins);
                        stim_regressor(3,:) =  histcounts(stimOn_times(align_category_all == 12000),wf_regressor_bins);
                    end
                    move_regressor_random = histcounts(stimOn_times(non_quiescent_trials ),wf_regressor_bins);
                    stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times(stim_drive_trials));
                    % stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times);
                    move_regressor_stim_drive = histcounts(stim_drive_time,wf_regressor_bins);
                    regressors={stim_regressor;move_regressor_random;move_regressor_stim_drive};
                    t_shifts = {[-5:30];[-30:30];[-30:30]};
                    % Set cross validation (not necessary if just looking at kernels)
                    cvfold = 5;
                    % Do regression
                    [kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
                        ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

                    % % Convert kernels V to pixels
                    wf_px_kernels{curr_recording} = cellfun(@(x) permute(x,[3,2,1]),kernels,'uni',false);



                    % Prep for next loop
                    ap.print_progress_fraction(curr_recording,length(recordings));
                    clearvars('-except',preload_vars{:});




                    % Grab pre-load vars
                    preload_vars = who;
                    % Load data
                    rec_day = recordings2(curr_recording).day;
                    clear time
                    if length(recordings2(curr_recording).index)>1
                        for mm=1:length(recordings2(curr_recording).index)
                            rec_time = recordings2(curr_recording).recording{mm};
                            % verbose = true;
                            % ap.load_timelite

                            timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                            timelite = load(timelite_fn);
                            time(mm)=length(timelite.timestamps);
                        end
                        [~,index_real]=max(time);
                    else index_real=1;
                    end


                    rec_time = recordings2(curr_recording).recording{index_real};

                    if strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')...
                            || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')...
                            || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                            || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')
                        workflow_type(curr_recording)=2;
                    elseif  strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2')...
                            ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1')
                        workflow_type(curr_recording)=1;
                    elseif  strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                            ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                        workflow_type(curr_recording)=3;

                    end


                    load_parts = struct;
                    load_parts.behavior = true;
                    ap.load_recording;
                    if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2

                        % Get total trials/water
                        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                            sum(([trial_events.values.Outcome] == 1)*6)];

                        % Get median stim-outcome time
                        n_trials = length([trial_events.timestamps.Outcome]);
                        rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));

                        % Align wheel movement to stim onset
                        align_times = stimOn_times;
                        pull_times = align_times + surround_time_points;

                        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;
                        frac_move_day(curr_recording) = nanmean(wheel_move);

                        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
                            wheel_velocity,pull_times);
                        event_aligned_wheel_move = interp1(timelite.timestamps, ...
                            +wheel_move,pull_times,'previous');

                        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);

                        % Get association stat
                        rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
                            stimOn_times,trial_events,stim_to_move);


                    elseif workflow_type(curr_recording)==3

                        % Get total trials/water
                        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                            sum(([trial_events.values.Outcome] == 1)*6)];


                        % Get median stim-outcome time
                        n_trials = length([trial_events.timestamps.Outcome]);
                        reactivation_time=seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}));
                        % Get task type
                        tasktype=cell2mat({trial_events.values.TaskType});
                        visual_time=reactivation_time(find(tasktype(1:n_trials)==0));
                        audio_time=reactivation_time(find(tasktype(1:n_trials)==1));

                        n_trials_water_V(curr_recording)=length(visual_time);
                        n_trials_water_A(curr_recording)=length(audio_time);



                        % Align wheel movement to stim onset
                        align_times = stimOn_times;
                        pull_times = align_times + surround_time_points;

                        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;
                        frac_move_day(curr_recording) = nanmean(wheel_move);
                        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
                            wheel_velocity,pull_times);
                        event_aligned_wheel_move = interp1(timelite.timestamps, ...
                            +wheel_move,pull_times,'previous');

                        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);
                        frac_move_stimalign_V(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==0,:),1);
                        frac_move_stimalign_A(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==1,:),1);
                        % Get association stat
                        buffer_p = AP_stimwheel_association_pvalue2( ...
                            stimOn_times,trial_events,stim_to_move,tasktype);

                        if ss==1
                            rxn_stat_p(curr_recording)=buffer_p(3);
                            rxn_med(curr_recording) = median(audio_time);
                        elseif ss==2
                            rxn_stat_p(curr_recording)=buffer_p(2);
                            rxn_med(curr_recording) = median(visual_time);
                        end
                    end

                    % Clear vars except pre-load for next loop
                    clearvars('-except',preload_vars{:});
                    ap.print_progress_fraction(curr_recording,length(recordings2));



                end

                buffer_learn= rxn_stat_p < 0.05 & rxn_med < 2;
                learned_day(file_length:length(recordings)) =buffer_learn(file_length:length(recordings));




            end

            save([Path  animal '_' passive_workflow '.mat' ],'workflow_type','learned_day','wf_px','wf_px_kernels','wf_px_baseline','wf_px_baseline_kernels','all_groups_name_baseline','all_groups_name','img_size','workflow_day','wf_px_all','trial_type','trial_state','-v7.3')

            load(master_U_fn);
            wf_px_pro= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px, 'UniformOutput', false);
            wf_px_baseline_pro= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px_baseline, 'UniformOutput', false);
            wf_px_kernels_pro = cellfun(@(x) plab.wf.svd2px(U_master,x{1}), wf_px_kernels, 'UniformOutput', false);
            wf_px_baseline_kernels_pro = cellfun(@(x) plab.wf.svd2px(U_master,x{1}), wf_px_baseline_kernels, 'UniformOutput', false);



            %% draw picture of averaged date in single mouse:
            if ss==1
                element_type=8000;
            elseif ss==2
                element_type=90;
            end

            indx= find(~cellfun('isempty', (cellfun(@(element) find(element ==element_type), all_groups_name, 'UniformOutput', false))));
            selected_images = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_pro', cellfun(@(element) find(element == element_type), all_groups_name, 'UniformOutput', false), 'UniformOutput', false);
            selected_images=selected_images(indx);

            selected_images_kernels = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_kernels_pro', cellfun(@(element) find(element == element_type), all_groups_name, 'UniformOutput', false), 'UniformOutput', false);
            selected_images_kernels=selected_images_kernels(indx);



            indx_base= find(~cellfun('isempty', (cellfun(@(element) find(element ==element_type), all_groups_name_baseline, 'UniformOutput', false))));
            selected_images_baseline = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_baseline_pro', cellfun(@(element) find(element == element_type), all_groups_name_baseline, 'UniformOutput', false), 'UniformOutput', false);
            selected_images_baseline=selected_images_baseline(indx_base);

            selected_images_baseline_kernels = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_baseline_kernels_pro', cellfun(@(element) find(element == element_type), all_groups_name_baseline, 'UniformOutput', false), 'UniformOutput', false);
            selected_images_baseline_kernels=selected_images_baseline_kernels(indx_base);

            merged_data=[selected_images_baseline_kernels; selected_images_kernels];
            image_Data=cat(4,merged_data{:});
            ap.imscroll(image_Data,[-5 :30]./35)
            axis image;ap.wf_draw('ccf');
            clim(max(abs(clim)).*[-1,1]);
            % clim(0.01.*[-1,1]);
            colormap(ap.colormap('PWG',[],1.5));
            savefig(gcf,[Path 'figures\'   passive_workflow '_widefiled_kernels_movie_' animal]);

            merged_data=[selected_images_baseline; selected_images];
            image_Data=cat(4,merged_data{:});
            ap.imscroll(image_Data,t)
            axis image;ap.wf_draw('ccf');
            clim(max(abs(clim)).*[-1,1]);
            % clim(0.01.*[-1,1]);
            colormap(ap.colormap('PWG',[],1.5));
            savefig(gcf,[Path 'figures\'   passive_workflow '_widefiled_movie_' animal]);



            for curr_trial=1:length(selected_images_kernels)
                redata=reshape(selected_images_kernels{curr_trial},size(selected_images_kernels{curr_trial},1)*size(selected_images_kernels{curr_trial},2),size(selected_images_kernels{curr_trial},3));
                roi_data_peri_av(curr_trial,:)=mean(redata(roi1(1).data.mask(:),:,:),1);


            end

            for curr_trial=1:length(selected_images_baseline)
                redata_baseline=reshape(selected_images_baseline{curr_trial},size(selected_images_baseline{curr_trial},1)*size(selected_images_baseline{curr_trial},2),size(selected_images_baseline{curr_trial},3));
                roi_data_peri_av_baseline(curr_trial,:)=mean(redata_baseline(roi1(1).data.mask(:),:,:),1);
            end


            workflow_type_index=workflow_type(indx);
            learned_day_index=learned_day(indx);


            figure('Position',[50 50 200 600]);
            nexttile
            index_1_2=find(workflow_type_index==1|workflow_type_index==2|workflow_type_index==3);
            imagesc(t_kernels,[], roi_data_peri_av(index_1_2,:));hold on
            clim(0.003*[0,1]);colormap(ap.colormap('WG'));
            xlabel('Time from stim')
            colorbar
            if any(learned_day_index)
                plot(0,find(learned_day_index(index_1_2)),'.g')
            end
            if any(workflow_type_index(index_1_2)==1)
                plot(-0.2,find(workflow_type_index(index_1_2)==1),'|b')
            end
            if any( workflow_type_index(index_1_2)==2)
                plot(-0.2,find(workflow_type_index(index_1_2)==2),'|r')
            end
            if any( workflow_type_index(index_1_2)==3)
                plot(-0.2,find(workflow_type_index(index_1_2)==3),'|black')
            end
            title([animal '_' passive_workflow],'Interpreter','none')

            nexttile;
            plot(max(roi_data_peri_av(index_1_2,period),[],2))
            hold on;
            scale1=min(max(roi_data_peri_av(:,period),[],2));
            plot(find(workflow_type_index(index_1_2)==1),scale1*ones(length(find(workflow_type_index(index_1_2)==1)),1),'r')
            plot(find(workflow_type_index(index_1_2)==2),scale1*ones(length(find(workflow_type_index(index_1_2)==2)),1),'b')
            if any(workflow_type_index(index_1_2)==3)
                plot(find(workflow_type_index(index_1_2)==3),scale1*ones(length(find(workflow_type_index(index_1_2)==3)),1),'black')
            end
            plot(find(learned_day_index(index_1_2)),0.5*scale1*ones(length(find(learned_day_index(index_1_2))),1),'.g')
            % drawnow;
            saveas(gcf,[Path 'figures\mPFC_across_day_'  passive_workflow '_kernels_' animal  ], 'jpg');


            all_basline=cat(4,selected_images_baseline_kernels{:});
            img_basline= mean( max(all_basline(:,:,period,:),[],3),4);

            all_img=cat(4,selected_images_kernels{:});
            img_v_nl= mean( max(all_img(:,:,period,find(workflow_type_index(:)==1 &learned_day_index(:)==0)),[],3),4);
            img_v_l= mean( max(all_img(:,:,period,find(workflow_type_index(:)==1 &learned_day_index(:)==1)),[],3),4);
            img_a_nl = mean( max(all_img(:,:,period,find(workflow_type_index(:)==2 &learned_day_index(:)==0)),[],3),4);
            img_a_l=  mean( max(all_img(:,:,period,find(workflow_type_index(:)==2 &learned_day_index(:)==1)),[],3),4);


            figure;
            subplot(2,3,1)
            imagesc(img_basline)
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.008.*[-1,1]); colormap(ap.colormap('PWG'));
            title('baseline');

            subplot(2,3,(3*type_seq-1))
            imagesc(img_v_nl)
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.008.*[-1,1]); colormap(ap.colormap('PWG'));
            title('visual no learned');

            subplot(2,3,(3*type_seq))
            imagesc(img_v_l)
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.008.*[-1,1]); colormap(ap.colormap('PWG'));
            title('visual learned');

            subplot(2,3,(8-3*type_seq))
            imagesc(img_a_nl)
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.008.*[-1,1]); colormap(ap.colormap('PWG'));
            title('auditory no learned');

            subplot(2,3,(9-3*type_seq))
            imagesc(img_a_l)
            axis image off;
            ap.wf_draw('ccf','black');
            clim(0.008.*[-1,1]); colormap(ap.colormap('PWG'));
            title('auditory learned');
            sgtitle([animal ' ' passive_workflow ' kernels'], 'Interpreter', 'none');
            saveas(gcf,[Path 'figures\'   passive_workflow '_kernels_' animal], 'jpg');
            close all





            clearvars('-except',main_preload_vars{:});


        end

    end

end