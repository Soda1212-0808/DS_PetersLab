
%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';


% surround_window = [-0.5,2];
% surround_samplerate = 35;
% t_task = surround_window(1):1/surround_samplerate:surround_window(2);


surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-5:30];





animals = {'DS006','DS007'};

% animals = {'AP018','AP019'}

%% DS006

for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);
    % training_workflow = {'stim_wheel_right_stage2$|stim_wheel_right_stage2_audio_volume$'};
    % training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$';
    training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2$|stim_wheel_right_stage2_audio_volume$|stim_wheel_right_frequency_stage2_mixed_VA$|stim_wheel_right_stage2_mixed_VA$';

    % training_workflow = 'visual_conditioning*';
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
    if     exist ([Path 'mat_data\task\' animal '_task.mat' ])==2
        load([Path 'mat_data\task\' animal '_task.mat' ])
        load([Path 'mat_data\task\' animal '_task_single_trial.mat' ])

        %查看目前文件的长度以及如果存在没有alignment的情况下要去除
        n_buffer= find(~all(img_size== [450, 426],2), 1);
        if isempty (n_buffer)
            file_length=  length(wf_px_task);
            problem=0;
        else file_length=n_buffer;
            problem=1;
        end
    else
        wf_px_task = cell(size(recordings2));
        wf_px_task_kernels = cell(size(recordings2));
        all_groups_name = cell(size(recordings2))';
        file_length=1;
        problem=0;
        img_size = nan(length(recordings2),2);

                workflow_type=zeros(length(recordings2),1);

        wf_px_task_all_type_id= cell(size(recordings2));
        wf_px_task_all_reward_id= cell(size(recordings2));
        wf_px_task_all= cell(size(recordings2));
        wf_px_task_all_timepoint=cell(size(recordings2));
        tasktype=cell(size(recordings2));

        rxn_med = nan(length(recordings2),1);
        rxn_stat_p = nan(length(recordings2),1);
        stim2move= nan(length(recordings2),1);
    end


    workflow_day={recordings2.day}';

    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_water = nan(length(recordings2),2);
    frac_move_day = nan(length(recordings2),1);
    success = nan(length(recordings2),1);

    frac_move_stimalign = nan(length(recordings2),length(surround_time_points));


    if ~(file_length==length(recordings2)&problem==0)
        for curr_recording =file_length:length(recordings2)

            fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);

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
                    || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type(curr_recording)=3;
            end

            verbose=true;


            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;



            % process behavioral data 

            stim2move(curr_recording)=median(stim_to_move);









            % Get total trials/water
            n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                sum(([trial_events.values.Outcome] == 1)*6)];

            % Get task type
            if workflow_type(curr_recording)==3
                tasktype{curr_recording}=cell2mat({trial_events.values.TaskType});
            else tasktype{curr_recording}=nan;
            end


            % Get median stim-outcome time
            n_trials = length([trial_events.timestamps.Outcome]);
            if length(stimOn_times)<n_trials
                n_trials=length(stimOn_times);
            end
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


















            % Task: align to stim/move/reward
            rewarded_trials = logical([trial_events.values.Outcome]');

            use_trials = rewarded_trials(1:n_trials);
            %     align_times = [ ...
            %         stimOn_times(use_trials); ...
            %         stim_move_time(use_trials); ...
                    % reward_times_task(use_trials)];
            align_times_3 = [ ...
                stimOn_times(use_trials); ...
                stim_move_time(use_trials); ...
                reward_times(1:end-(length(reward_times)-sum(use_trials)))];




            % align_times = [ ...
            %  stimOn_times(use_trials); ...
            %  stim_move_time(use_trials); ...
            %  reward_times];


            %所有trials
            % align_times_3_all= [ ...
            %     stimOn_times(logical(ones(length(use_trials),1))); ...
            %     stim_move_time(logical(ones(length(use_trials),1))); ...
            %     reward_times(1:end-(length(reward_times)-sum(rewarded_trials)))];
            stimOff_times=photodiode_times(photodiode_values==0);
            align_times_3_all= [ ...
                stimOn_times(logical(ones(length(use_trials),1))); ...
                stim_move_time(logical(ones(length(use_trials),1))); ...
                stimOff_times(logical(ones(length(use_trials),1)))];



            % align_category_all = [reshape(ones(n_trials,2).*[1,2],[],1); ones(sum(use_trials),1).*3];
            % baseline_times_all = [repmat(stimOn_times(ones(length(use_trials),1)),2,1); stimOn_times(use_trials)];
            align_category_all = reshape(ones(n_trials,3).*[1,2,3],[],1);
            baseline_times_all = repmat(stimOn_times(ones(length(use_trials),1)),3,1);






            align_category = reshape(ones(sum(use_trials),3).*[1,2,3],[],1);
            baseline_times = repmat(stimOn_times(use_trials),3,1);


            peri_event_t = reshape(align_times_3,[],1) + reshape(t_task,1,[]);

            baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);

            % all trials
            peri_event_t_all = reshape(align_times_3_all,[],1) + reshape(t_task,1,[]);
            baseline_event_t_all = reshape(baseline_times_all,[],1) + reshape(baseline_t,1,[]);


            use_U = wf_U;
            use_V = wf_V;
            use_wf_t = wf_t;

            aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
                length(align_times_3),length(t_task),[]);
            aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
                length(baseline_times),length(baseline_t),[]),2);

            % 减去baseline数据
            aligned_v_baselinesub = aligned_v - aligned_baseline_v;
            align_id = findgroups(reshape(align_category,[],1));
            aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
            % aligned_px_avg = plab.wf.svd2px(use_U,aligned_v_avg);


            % linear regression data  线性回归后的数据

            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            % Create regressors
            stim_regressor = histcounts(stimOn_times,wf_regressor_bins);
            move_regressor = histcounts(stim_move_time,wf_regressor_bins);
            regressors = {stim_regressor;move_regressor};
            % Set time shifts for regressors
            t_shifts = {[-5:30];[-30:30]};
            % Set cross validation (not necessary if just looking at kernels)
            cvfold = 5;
            % Do regression
            [kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
                ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

            wf_px_task_kernels{curr_recording}=permute(kernels{1},[3,2,1]);




            % all trials
            aligned_v_all = reshape(interp1(use_wf_t,use_V',peri_event_t_all,'previous'), ...
                length(align_times_3_all),length(t_task),[]);
            aligned_baseline_v_all = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t_all,'previous'), ...
                length(baseline_times_all),length(baseline_t),[]),2);
            aligned_v_baselinesub_all = aligned_v_all - aligned_baseline_v_all;
            aligned_v_avg_all = permute(aligned_v_baselinesub_all,[3,2,1]);

            wf_px_task_all{curr_recording}=aligned_v_avg_all;
            align_id_all = findgroups(reshape(align_category_all,[],1));

            % reward_or_not_id_all=[use_trials; use_trials; logical(ones(sum(use_trials),1))];
            reward_or_not_id_all=repmat(use_trials,3,1);

            wf_px_task_all_type_id{curr_recording}=align_id_all;
            wf_px_task_all_reward_id{curr_recording}=reward_or_not_id_all;
            wf_px_task_all_timepoint{curr_recording}=align_times_3_all;
            wf_px_task{curr_recording}=aligned_v_avg;
            img_size(curr_recording,:)=size(wf_avg);



            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});
            ap.print_progress_fraction(curr_recording,length(recordings2));


        end

        learned_day = rxn_stat_p < 0.05 & rxn_med < 2;

    end
    save([Path 'mat_data\task\' animal '_task.mat' ],'workflow_type','learned_day','rxn_med','rxn_stat_p','wf_px_task','wf_px_task_kernels','img_size','tasktype','workflow_day','stim2move', '-v7.3')
    save([Path 'mat_data\task\' animal '_task_single_trial.mat' ],'wf_px_task_all','wf_px_task_all_type_id','wf_px_task_all_reward_id','wf_px_task_all_timepoint', '-v7.3')




end

