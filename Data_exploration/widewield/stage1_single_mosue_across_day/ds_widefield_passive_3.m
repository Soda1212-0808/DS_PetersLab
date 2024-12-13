
%% TESTING BATCH PASSIVE WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-5:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');


for x=1
    if x==1
        animals = {'HA001'};type_seq=1; %v-a
    else animals = {'DS005'};type_seq=2; %a-v
    end

    for curr_passive=2
        if curr_passive==1
            passive_workflow = 'hml_passive_audio';
        elseif curr_passive==2
            passive_workflow = 'lcr_passive';
        end

        for curr_animal_idx=1:length(animals)
            main_preload_vars = who;

            animal=animals{curr_animal_idx};
            fprintf('%s\n', ['start  ' animal ]);



            fprintf('%s\n', ['start saving ' passive_workflow ' files...']);
            % use_workflow = {'stim_wheel_right_stage2_mixed_VA$|stim_wheel_right_frequency_stage2_mixed_VA$'};
            % training_workflow = ['stim_wheel_right_stage1_opacity$|stim_wheel_right_stage2_opacity$|'...
            %     'stim_wheel_right_stage1$|stim_wheel_right_stage2$|' ...
            %     'stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage2_audio_volume$|' ...
            %      'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage2_audio_frequency$|stim_wheel_right_frequency_stage2_mixed_VA$|' ...
            %     'stim_wheel_right_stage2_mixed_VA$'];

            % training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_stage2_audio_volume$|stim_wheel_right_frequency_stage2_mixed_VA$';

            % training_workflow = {'stim_wheel_right_stage1*$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$'};
            training_workflow = {'stim_lick_right_stage1*$|stim_lick_right_stage2*$|'};


            recordings_passive = plab.find_recordings(animal,[],passive_workflow);


            recordings_training = plab.find_recordings(animal,[],training_workflow);

            % recordings =[ recordings_passive( ...
            %     cellfun(@any,{recordings_passive.widefield}) & ...
            %     ~[recordings_passive.ephys] & ...
            %     ismember({recordings_passive.day},{recordings_training.day}))];

             recordings =[recordings_passive(1:3) recordings_passive( ...
                cellfun(@any,{recordings_passive.widefield}) & ...
                ~[recordings_passive.ephys] & ...
                ismember({recordings_passive.day},{recordings_training.day}))];

            recordings2 = recordings_training( ...
                cellfun(@any,{recordings_training.widefield}) & ...
                ~[recordings_training.ephys] & ...
                ismember({recordings_training.day},{recordings_passive.day}));


            %%是否存在保存过之前的数据的文件
            if     exist ([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ])==2
                load([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ])
                 load([Path '\' passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ])

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

                workflow_type=zeros(length(recordings),1);
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



                    %% 分析行为学

                    % Grab pre-load vars
                    preload_vars = who;

                    task_day_index = find(strcmp({recordings2.day}, recordings(curr_recording).day));
                    if isempty(task_day_index)
                        continue
                    end
                    rec_day=recordings(curr_recording).day;

                    % Load data
                    clear time
                    if length(recordings2(task_day_index).index)>1
                        for mm=1:length(recordings2(task_day_index).index)
                            rec_time = recordings2(task_day_index).recording{mm};
                            % verbose = true;
                            % ap.load_timelite

                            timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                            timelite = load(timelite_fn);
                            time(mm)=length(timelite.timestamps);
                        end
                        [~,index_real]=max(time);
                    else index_real=1;
                    end

                    rec_time=recordings2(task_day_index).recording{index_real};


                    if strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_audio_volume')...
                            || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')...
                            || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                            || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_audio_volume')
                        workflow_type(curr_recording)=2;
                    elseif  strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2')...
                            ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1')...
                         ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                          ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_opacity')...
                          ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                          ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_size_up')...
                                    ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_lick_right_stage1')...
                          ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_lick_right_stage2')

                        workflow_type(curr_recording)=1;
                    elseif  strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                            ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
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
                        curr_tasktype=cell2mat({trial_events.values.TaskType});
                        visual_time=reactivation_time(find(curr_tasktype(1:n_trials)==0));
                        audio_time=reactivation_time(find(curr_tasktype(1:n_trials)==1));

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
                        frac_move_stimalign_V(curr_recording,:)= nanmean(event_aligned_wheel_move(curr_tasktype(1:n_trials)==0,:),1);
                        frac_move_stimalign_A(curr_recording,:)= nanmean(event_aligned_wheel_move(curr_tasktype(1:n_trials)==1,:),1);
                        % Get association stat
                        buffer_p = AP_stimwheel_association_pvalue2( ...
                            stimOn_times,trial_events,stim_to_move,curr_tasktype);

                        if curr_passive==1
                            rxn_stat_p(curr_recording)=buffer_p(3);
                            rxn_med(curr_recording) = median(audio_time);
                        elseif curr_passive==2
                            rxn_stat_p(curr_recording)=buffer_p(2);
                            rxn_med(curr_recording) = median(visual_time);
                        end
                    end

                    % Clear vars except pre-load for next loop
                    clearvars('-except',preload_vars{:});
                    ap.print_progress_fraction(curr_recording,length(recordings));



                end

                buffer_learn= rxn_stat_p < 0.05 & rxn_med < 2;
                learned_day(file_length:length(recordings)) =buffer_learn(file_length:length(recordings));

            

            save([Path passive_workflow '\' animal '_' passive_workflow '.mat' ],'workflow_type','learned_day','wf_px','wf_px_kernels','all_groups_name','img_size','workflow_day','-v7.3')
            save([Path passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ],'wf_px_all','trial_type','trial_state','-v7.3')
            end


            clearvars('-except',main_preload_vars{:});


        end

    end

end