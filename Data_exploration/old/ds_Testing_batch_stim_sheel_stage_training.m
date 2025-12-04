clear all
Path='C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\';

% ranimal = 'AP021';
animals = {'AP019','AP021','AP022','AP020'};
workflows = {'stim_wheel_right_stage*';'stim_wheel_right_stage2';'stim_wheel_right_stage2_audio_volume'};
% workflow = 'stim_wheel_right*';

for curr_animal_idx = 1:length(animals)


    animal=animals{curr_animal_idx};
    %save data
    % data_merge(curr_animal_idx).animal=animal;
    % data_merge(curr_animal_idx).workflow(curr_workflow)=workflow;


    for curr_workflow_idx=1:length(workflows)
        workflow=workflows{curr_workflow_idx};

        data(curr_workflow_idx).workflow=workflow;

        recordings= plab.find_recordings(animal,[],workflow);

        %%定义变量

        %定义行为学变量，在循环后不会被清空

        if curr_workflow_idx==1
            length_buff=3;
            recording_date=cell([1 3]);
            wf_px = cell([1 3]);
            rxn_med = nan(3,1);
            rxn_stat_p = nan(3,1);


        else length_buff=length(recordings);
            recording_date=cell(size(recordings));
            wf_px = cell(size(recordings));
            rxn_med = nan(length(recordings),1);
            rxn_stat_p = nan(length(recordings),1);

        end

        for curr_recording =   1 :length_buff
            % for curr_recording = 9
            % Grab pre-load vars
            preload_vars = who;
            % Load data
            rec_day = recordings(curr_recording).day;
            recording_date{curr_recording}=recordings(curr_recording).day;
            rec_time = recordings(curr_recording).recording{end};

            if ~recordings(curr_recording).widefield(end)
                continue
            end

            try

                load_parts.widefield = true;
                ap.load_recording;

            catch me
                warning('%s %s %s: load error, skipping \n >> %s', ...
                    animal,rec_day,rec_time,me.message)
                continue
            end

            % Task: align to stim/move/reward
            rewarded_trials = logical([trial_events.values.Outcome]');

            use_trials = rewarded_trials(1:n_trials);
            %     align_times = [ ...
            %         stimOn_times(use_trials); ...
            %         stim_move_time(use_trials); ...
            %         reward_times_task(use_trials)];
            align_times = [ ...
                stimOn_times(use_trials); ...
                stim_move_time(use_trials); ...
                reward_times(1:end-(length(reward_times)-sum(rewarded_trials)))];
            % align_times = [ ...
            %  stimOn_times(use_trials); ...
            %  stim_move_time(use_trials); ...
            %  reward_times];


            align_category = reshape(ones(sum(use_trials),3).*[1,2,3],[],1);
            baseline_times = repmat(stimOn_times(use_trials),3,1);





            surround_window = [-1,4];
            baseline_window = [-0.5,-0.1];

            surround_samplerate = 35;

            t = surround_window(1):1/surround_samplerate:surround_window(2);
            baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);

            peri_event_t = reshape(align_times,[],1) + reshape(t,1,[]);
            baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);


     
            use_U = wf_U;
            use_V = wf_V;
            use_wf_t = wf_t;

            aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
                length(align_times),length(t),[]);
            aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
                length(baseline_times),length(baseline_t),[]),2);

            %% 减去baseline数据
            aligned_v_baselinesub = aligned_v - aligned_baseline_v;

            align_id = findgroups(reshape(align_category,[],1));

            % aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
             aligned_px_avg = plab.wf.svd2px(use_U,aligned_v_avg);


            wf_px{curr_recording} = aligned_v_avg;

            %行为学分析 behavioral analysis of learned days

            % Get median stim-outcome time
            n_trials = length([trial_events.timestamps.Outcome]);


reactivation_time=seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
           cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}));
tasktype=cell2mat({trial_events.values.TaskType});
visual_time=reactivation_time(find(tasktype(1:n_trials)==0));
audio_time=reactivation_time(find(tasktype(1:n_trials)==1));

        rxn_med(curr_recording,1) = median(visual_time);
        rxn_med(curr_recording,2) = median(audio_time);




            rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));

            % Get association stat
            rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_move);

            % Prep for next loop
            ap.print_progress_fraction(curr_recording,length(recordings));
            clearvars('-except',preload_vars{:});

        end
        learned_day = rxn_stat_p < 0.05 & rxn_med < 2;

        data(curr_workflow_idx).workflow=workflow;
        data(curr_workflow_idx).imagedata=wf_px;
        data(curr_workflow_idx).recording_date=recording_date;
        data(curr_workflow_idx).learned_day=learned_day;
    end
current_time = datestr(now, 'yyyy-mm-dd_HH-MM');
    save([Path 'process\process_' animal '_task.mat'], 'data', '-v7.3')
save([Path 'buffer\buffer_' animal '_task_' current_time '.mat'], 'data', '-v7.3')
    % data_merge(curr_animal_idx).imagedata=wf_px;
    % data_merge(curr_animal_idx).learned_day=learned_day;
    % data_merge(curr_animal_idx).recording_date=recording_date;
    % data_merge(curr_animal_idx).workflow=workflow;
end



