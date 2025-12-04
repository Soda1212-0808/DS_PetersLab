
%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'D:\Data process\wf_data\';

surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-5:30];

animals = {'DS007','DS013','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020',...
    'DS004','DS014','DS015','DS016', 'DS003','DS006','DS013','DS000',...
    'HA000','HA001','HA002','HA003','HA004','AP027','AP028','AP029','DS019','DS020','DS021'};

curr_workflow='task';

for curr_animal_idx=5:14
    preload_vars_main = who;
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);
    data_load=load([Path   curr_workflow '\' animal '_' curr_workflow '.mat' ]);

    training_workflow =...
        ['stim_wheel_right_stage1$|' ...
        'stim_wheel_right_stage2$|' ...
        'stim_wheel_right_stage1_opacity$|' ...
        'stim_wheel_right_stage2_opacity$|' ...
        'stim_wheel_right_stage1_angle$|' ...
        'stim_wheel_right_stage2_angle$|' ...
        'stim_wheel_right_stage2_angle_size60$|' ...
        'stim_wheel_right_stage1_size_up$|' ...
        'stim_wheel_right_stage2_size_up$|' ...
        'stim_wheel_right_stage1_audio_volume$|'...
        'stim_wheel_right_stage2_audio_volume$|' ...
        'stim_wheel_right_stage1_audio_frequency$|' ...
        'stim_wheel_right_stage2_audio_frequency$|' ...
        'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
        'stim_wheel_right_stage2_mixed_VA$'];

    % wf_px_task_all=cell(size(data_load.workflow_day));
    iti_move_time=cell(size(data_load.workflow_day));
    for curr_recording =1:length(data_load.workflow_day)

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


            % 计算 iti move的时间点
            wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
            wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);
            wheel_move_time=wheel_stops-wheel_starts;

            wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
            wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);
            % 找到 wheel 开始转动的索引
            start_idx = find(diff([0;wheel_move]) == 1);
            % 预分配时间数组 (提高效率)
            time_to_90 = nan(size(start_idx));
            % **优化的计算方式**
            for i = 1:length(start_idx)
                % 直接找到第一个满足 wheel_position > pos_start + 90 的索引
                target_idx = find(wheel_position(start_idx(i):length(wheel_position)) < wheel_starts_position(i) - (30/360*1024), 1, 'first');
                % 计算所需时间 (以 ms 计算)
                if ~isempty(target_idx)
                    time_to_90(i) = (target_idx - 1) * 1; % 1000Hz 采样率，每点 1ms
                end
            end
            wheel_move_less_than_200ms= time_to_90<200;
            wheel_move_over_90=wheel_stops_position-wheel_starts_position<-(30/360*1024);
            % (get wheel starts when no stim on screen: not sure this works yet)
            iti_move_idx = interp1(photodiode_times, ...
                photodiode_values,wheel_starts,'previous') == 0;
            real_iti_move = wheel_starts(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );
                        real_iti_move_time=wheel_move_time(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );

            if length (real_iti_move==1)
                real_iti_move=[real_iti_move ;real_iti_move];
                real_iti_move_time=[real_iti_move_time;real_iti_move_time];

            end

            iti_move_time{curr_recording}=real_iti_move_time;

            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});
            ap.print_progress_fraction(curr_recording,length(data_load.workflow_day));


        end


    end

    save([Path   curr_workflow '\' animal '_' curr_workflow '_single_trial.mat' ],'iti_move_time','-append')


    clearvars('-except',preload_vars_main{:});
end