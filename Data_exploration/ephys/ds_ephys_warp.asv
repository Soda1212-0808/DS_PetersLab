
clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';

% animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS006','DS013',...
%     'DS000','DS004','DS014','DS015','DS016'};

animals= { 'DS000','DS004','DS014','DS015','DS016'};

% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t_stim = [-0.1,0];
response_t_stim = [0.05,0.15];
psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

baseline_t_move = [-0.1,-0.1];
response_t_move = [-0.1,0.1];
psth_use_t_move = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);



% run process

for curr_animal=1 :length(animals)

    animal=animals{curr_animal};
    recordings_all_training=plab.find_recordings(animal,[],'stim_wheel_right_stage2_mixed_VA');
    recordings_all_passive_visual=plab.find_recordings(animal,[],'lcr_passive');
    recordings_all_passive_audio=plab.find_recordings(animal,[],'hml_passive_audio');


    recordings_passive_visual = recordings_all_passive_visual( ...
        cellfun(@any,{recordings_all_passive_visual.ephys}) & ...
        ismember({recordings_all_passive_visual.day},{recordings_all_training.day}));

    recordings_passive_audio = recordings_all_passive_audio( ...
        cellfun(@any,{recordings_all_passive_audio.ephys}) & ...
        ismember({recordings_all_passive_audio.day},{recordings_all_training.day}));

    recordings_training = recordings_all_training( ...
        cellfun(@any,{recordings_all_training.ephys}) & ...
        ismember({recordings_all_training.day},{recordings_all_passive_audio.day}));

    RateWarp=cell(4,1);
    Tasktype_idx=cell(4,1);
    trialInfo=cell(4,1);
    axesOut=cell(4,1);
    segIdx=cell(4,1);
    for curr_day=1:4

        day_probe={'post str','ant str','post str','ant str'};
        preload_vars = who;
  if length(recordings_training)<curr_day
            continue
        end
        for curr_task=1:3
            if  curr_task==1
                rec_day=recordings_passive_visual(curr_day).day;
                rec_time=recordings_passive_visual(curr_day).recording{1};
            elseif curr_task==2
                rec_day=recordings_passive_audio(curr_day).day;
                rec_time=recordings_passive_audio(curr_day).recording{1};
            elseif curr_task==3
                rec_day=recordings_training(curr_day).day;
                clear time
                if length(recordings_training(curr_day).index)>1
                    for mm=1:length(recordings_training(curr_day).index)
                        rec_time = recordings_training(curr_day).recording{mm};
                        timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                        timelite = load(timelite_fn);
                        time(mm)=length(timelite.timestamps);
                    end
                    [~,index_real]=max(time);
                else index_real=1;
                end
                rec_time = recordings_training(curr_day).recording{index_real};
            
            end



        verbose = true;
        ap.load_recording;

        idx = find(strcmp(probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.safe_name, 'Caudoputamen'));
        depth=probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(idx,:);
        % Plot responsive units by depth
        template_sort=find(any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2));
        spikes=arrayfun(@(idx) spike_times_timelite(spike_templates==idx),template_sort ,'UniformOutput',false);

        switch curr_task
            case {1,2}
                stim_window = [0,0.5];
                quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
                    (1:length(stimOn_times))');

                if contains(bonsai_workflow,'lcr')
                    % (vis passive)
                    stim_type = vertcat(trial_events.values.TrialStimX);
                elseif contains(bonsai_workflow,'hml')
                    % (aud passive)
                    stim_type = vertcat(trial_events.values.StimFrequence);
                end

                   [stim_values, ~,TaskType_idx] = unique(stim_type(quiescent_trials));

                   [RateWarp{curr_day}{curr_task}, axesOut{curr_day}{curr_task}, segIdx{curr_day}{curr_task}, trialInfo{curr_day}{curr_task}] = warp_spikes_two_anchor( ...
                       spikes, stimOn_times(quiescent_trials), stimOff_times(quiescent_trials),'PreDur',0.5,'MidBins',50);

                   Tasktype_idx{curr_day}{curr_task}=TaskType_idx;
            case 3

                % use_align = stimOn_times(stim_to_move > 0.15);
                TaskType_idx= cell2mat({trial_events.values.TaskType})';


                [RateWarp{curr_day}{curr_task}, axesOut{curr_day}{curr_task}, segIdx{curr_day}{curr_task}, trialInfo{curr_day}{curr_task}] = warp_spikes_two_anchor( ...
                    spikes, stimOn_times(1:n_trials), stim_move_time(1:n_trials),'PreDur',0.5);
                Tasktype_idx{curr_day}{curr_task}=TaskType_idx(1:n_trials);
        end


        end

        clearvars('-except',preload_vars{:});

    end

    save([Path 'single_mouse\' animal '_ephys_warp.mat'],'RateWarp',...
        'trialInfo','Tasktype_idx','axesOut','segIdx','-v7.3')


end



