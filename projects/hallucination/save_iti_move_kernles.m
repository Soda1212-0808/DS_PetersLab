clear all
Path = 'D:\Data process\project_hallucination\';

file_name=dir(plab.locations.server_data_path);
folderNames = {file_name.name};
folderNames = folderNames(~ismember(folderNames,{'.','..','test'}));
animals=folderNames';


iti_move_kernels=cell(length(animals),1);
numbers=cell(length(animals),1);
for curr_animal=42:length(animals)
    animal=animals{curr_animal}
    recordings = plab.find_recordings(animal,[],'stim_wheel_right_stage2');
    recordings=recordings(find( cellfun(@(x) any(x == 1), {recordings.widefield}))) ;
    if isempty(recordings)
        continue
    end
    numbers{curr_animal}=0;
    for curr_recording =1: length(recordings)

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings(curr_recording).day;
        clear time

        if length(recordings(curr_recording).index)>1
            for mm=1:length(recordings(curr_recording).index)
                rec_time = recordings(curr_recording).recording{mm};
                % verbose = true;
                % ap.load_timelite
                timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                timelite = load(timelite_fn);
                time(mm)=length(timelite.timestamps);
            end
            [~,index_real]=max(time);
        else index_real=1;
        end

        rec_time = recordings(curr_recording).recording{index_real};
        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;

        temp_p_mad = AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_move,'mad');

        if median(stim_to_move)<3&temp_p_mad<0.01


            load_parts.widefield=true;
            load_parts.widefield_master = true;

            ap.load_recording;


            % 计算 iti move的时间点
            wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
            wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);
            wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
            wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);
            wheel_move_time=wheel_stops-wheel_starts;

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

            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];


            pho_on_times=photodiode_times(photodiode_values==1);
            pho_off_times=photodiode_times(photodiode_values==0)+2;
            iti_move_regressors=histcounts(real_iti_move,wf_regressor_bins);

            wf_t_only_iti = interp1([pho_on_times;pho_off_times], ...
                [zeros(sum(photodiode_values==1),1);ones(sum(photodiode_values==0),1)], ...
                wf_t,'previous')==1;

            n_components = 200;
            frame_shifts = -10:30;
            lambda = 15;

            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    [iti_move_kernels{curr_animal}{curr_recording},predicted_signals,explained_var] = ...
                        ap.regresskernel(wf_V(1:n_components,wf_t_only_iti),iti_move_regressors(wf_t_only_iti),-frame_shifts,lambda);

                    success = true; % 如果没有报错，则成功运行
                catch ME
                    disp(['Error: ', ME.message]);
                    n_components = n_components - 10; % 变量 a 递减
                    if n_components < 50 % 避免无限循环（你可以根据实际情况调整）
                        error('n_components 过小，无法继续运行');
                    end
                end
            end

            disp('iti_move_kernels_running_successfully');

            numbers{curr_animal}= numbers{curr_animal}+1;
        end
    end

    save(fullfile(Path,'iti_kernels.mat' ),'iti_move_kernels','-v7.3');

end

