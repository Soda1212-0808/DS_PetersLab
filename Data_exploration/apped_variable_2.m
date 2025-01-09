
%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';



surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-5:30];

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020',...
    'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016','AP027','AP028','AP029','HA003','HA004'};

passive_workflow='lcr_passive';
passive_workflow='hml_passive_aduio';
% passive_workflow='task';


for curr_animal_idx=1:length(animals)
    preload_vars_main = who;


    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);


    data_load=load([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ]);

    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

    training_workflow =...
        ['stim_wheel_right_stage1$|' ...
        'stim_wheel_right_stage2$|' ...
        'stim_wheel_right_stage1_opacity$|' ...
        'stim_wheel_right_stage2_opacity$|' ...
        'stim_wheel_right_stage1_size_up$|' ...
        'stim_wheel_right_stage2_size_up$|' ...
        'stim_wheel_right_stage1_audio_volume$|'...
        'stim_wheel_right_stage2_audio_volume$|' ...
        'stim_wheel_right_stage1_audio_frequency$|' ...
        'stim_wheel_right_stage2_audio_frequency$|' ...
        'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
        'stim_wheel_right_stage2_mixed_VA$'];

    recordings_training = plab.find_recordings(animal,[],training_workflow);

    % recordings = recordings_passive( ...
    %     cellfun(@any,{recordings_passive.widefield}) & ...
    %     ~[recordings_passive.ephys] & ...
    %     ismember({recordings_passive.day},{recordings_training.day}));
    %
    % recordings2 = recordings_training( ...
    %     cellfun(@any,{recordings_training.widefield}) & ...
    %     ~[recordings_training.ephys] & ...
    %     ismember({recordings_training.day},{recordings_passive.day}));


    frac_move_stimalign = nan(length(data_load.workflow_day),length(surround_time_points));
    rxn_med=cell(length(data_load.workflow_day),1);
    rxn_stat_p = nan(length(data_load.workflow_day),1);
    workflow_type_name=cell(length(data_load.workflow_day),1);

    for curr_recording =4:length(data_load.workflow_day)

        fprintf('The number of files is %d This file is: %d\n', length(data_load.workflow_day),curr_recording);

        % Grab pre-load vars
        preload_vars = who;

        % Load data
        rec_day = data_load.workflow_day{curr_recording};

        recordings_training = plab.find_recordings(animal,rec_day,training_workflow);
        if ~isempty(recordings_training)


            clear time
            if length(recordings_training.index)>1
                for mm=1:length(recordings_training.index)
                    rec_time = recordings_training.recording{mm};

                    timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                    timelite = load(timelite_fn);
                    time(mm)=length(timelite.timestamps);
                end
                [~,index_real]=max(time);
            else index_real=1;
            end



            rec_time = recordings_training.recording{index_real};

            verbose=true;

            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = false;

            load_parts.widefield = false;
            ap.load_recording;

            n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                sum(([trial_events.values.Outcome] == 1)*6)];

            % Get median stim-outcome time
            n_trials = length([trial_events.timestamps.Outcome]);
            % rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
            %     cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));
            %
            rxn_med{curr_recording}  = median(stimOff_times(1:n_trials) - ...
                stimOn_times(1:n_trials)  );

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
            rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_move);


            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});
            ap.print_progress_fraction(curr_recording,length(recordings2));


        end

        pre_time=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
        post_time=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
        react_index=(post_time-pre_time)./(post_time+pre_time);

        buffer_learn= rxn_stat_p < 0.05 & cell2mat(rxn_med) < 2;
        learned_day=buffer_learn';


        % load([Path 'mat_data\' animal '_task.mat' ])
        save([Path 'mat_data\task\' animal '_task.mat' ],'frac_move_stimalign','-append')
        % save([Path 'mat_data\lcr_passive\' animal '_lcr_passive.mat' ],'rxn_med','-append')

        clearvars('-except',preload_vars_main{:});



    end

