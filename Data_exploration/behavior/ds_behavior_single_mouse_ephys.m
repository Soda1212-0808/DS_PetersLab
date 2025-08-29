clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}0
animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS006','DS013',...
    'DS000','DS004','DS014','DS015','DS016'};

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

    frac_velocity_stimalign=cell(4,3);
    for curr_day=1:4

        day_probe={'post str','ant str','post str','ant str'};
        preload_vars = who;

        if length(recordings_training)<curr_day
            continue
        end


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


        % verbose = true;
        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;

        pull_times = stim_move_time + surround_time_points;
        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        frac_velocity_stimalign{curr_day,1} = event_aligned_wheel_vel;

        tasktype=[trial_events.values.TaskType];
        frac_velocity_stimalign{curr_day,2} = event_aligned_wheel_vel(find(tasktype(1:n_trials)==0),:);
        frac_velocity_stimalign{curr_day,3} = event_aligned_wheel_vel(find(tasktype(1:n_trials)==1),:);



    end


    save([Path 'single_mouse\' animal '_ephys_behavior.mat'],'frac_velocity_stimalign','-v7.3')


end
