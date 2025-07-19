
%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'D:\Data process\wf_data\';


surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-10:30];


surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


animals = {'DS021','DS007','DS013','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020',...
    'DS004','DS014','DS015','DS016', 'DS003','DS006','DS013','DS000',...
    'HA000','HA001','HA002','HA003','HA004','AP027','AP028','AP029','DS019','DS020'};

for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

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
    if     exist ([Path 'task\' animal '_task.mat' ])==2
        load([Path 'task\' animal '_task.mat' ])
        load([Path 'task\' animal '_task_single_trial.mat' ])

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
        iti_move_time= cell(size(recordings2))';
        workflow_type=zeros(length(recordings2),1);
        workflow_type_name=cell(length(recordings2),1);
        workflow_type_name_merge=cell(length(recordings2),1);

        wf_px_task_all_type_id= cell(size(recordings2));
        wf_px_task_all_reward_id= cell(size(recordings2));
        wf_px_task_all= cell(size(recordings2));
        wf_px_task_kernels_all= cell(size(recordings2));

        wf_px_task_all_timepoint=cell(size(recordings2));
        tasktype=cell(size(recordings2));

        rxn = cell(length(recordings2),1);
        rxn_stat_p = cell(length(recordings2),1);
        stim2move= cell(length(recordings2),1);

        rxn_med = cell(length(recordings2),1);
        stim2move_med= cell(length(recordings2),1);
        frac_move_stimalign = nan(length(recordings2),length(surround_time_points));

    end


    workflow_day={recordings2.day}';

    n_trials_water = nan(length(recordings2),2);
    frac_move_day = nan(length(recordings2),1);
    success = nan(length(recordings2),1);

    frac_move_stimalign_V = nan(length(recordings2),length(surround_time_points));
    frac_move_stimalign_A = nan(length(recordings2),length(surround_time_points));


    if ~(file_length==length(recordings2)&problem==0)
        for curr_recording =file_length:length(recordings2)
            % for curr_recording =4:length(recordings2)
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


            workflow_type_name{curr_recording}=recordings2(curr_recording).workflow{index_real};

            if strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')...
                    || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')...
                    || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                    || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')
                workflow_type(curr_recording)=2;
            elseif  strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_opacity')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_size_up')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_angle_size60')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle_size60')

                workflow_type(curr_recording)=1;
            elseif  strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                    || strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type(curr_recording)=3;
            end




            if strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')
                workflow_type_name_merge{curr_recording}='audio volume';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2')
                workflow_type_name_merge{curr_recording}='visual position';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_size_up')
                workflow_type_name_merge{curr_recording}='visual size up';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_opacity')
                workflow_type_name_merge{curr_recording}='visual opacity';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')
                workflow_type_name_merge{curr_recording}='audio frequency';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle_size60')
                workflow_type_name_merge{curr_recording}='visual angle';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type_name_merge{curr_recording}='mixed VA';
            else  workflow_type_name_merge{curr_recording}='none';
            end



            verbose=true;


            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
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

            if length (real_iti_move==1)
                real_iti_move=[real_iti_move ;real_iti_move];
              real_iti_move_time=[real_iti_move_time;real_iti_move_time];

            end

            iti_move_time{curr_recording}=real_iti_move_time;

            % process behavioral data
            stim2move{curr_recording}=stim_to_move;
            % Get median stim-outcome time
            if length(stimOn_times)< length([trial_events.timestamps.Outcome])
                n_trials =length(stimOn_times);
            else
                n_trials = length([trial_events.timestamps.Outcome]);
            end



            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2
                % Get total trials/water
                n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                    sum(([trial_events.values.Outcome] == 1)*6)];
                %get stim to move time
                stim2move_med{curr_recording}=median(stim_to_move);
                rxn_med{curr_recording}  = median(stimOff_times(1:n_trials) - ...
                    stimOn_times(1:n_trials)  );
                rxn{curr_recording} = seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                    cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}))';
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
                rxn_stat_p{curr_recording} = AP_stimwheel_association_pvalue( ...
                    stimOn_times,trial_events,stim_to_move,'mean');

            elseif workflow_type(curr_recording)==3
                % Get total trials/water
                n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                    sum(([trial_events.values.Outcome] == 1)*6)];
                reactivation_time=seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                    cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}));
                % Get task type
                curr_tasktype_0=cell2mat({trial_events.values.TaskType});
                curr_tasktype= curr_tasktype_0(1:n_trials);
                visual_time=reactivation_time(find(curr_tasktype==0));
                audio_time=reactivation_time(find(curr_tasktype==1));
                tasktype{curr_recording}=curr_tasktype;
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
                frac_move_stimalign_V(curr_recording,:)= nanmean(event_aligned_wheel_move(curr_tasktype==0,:),1);
                frac_move_stimalign_A(curr_recording,:)= nanmean(event_aligned_wheel_move(curr_tasktype==1,:),1);
                % Get association stat
                rxn_stat_p{curr_recording} = AP_stimwheel_association_pvalue2( ...
                    stimOn_times,trial_events,stim_to_move,curr_tasktype);
                rxn_med{curr_recording} = [median(visual_time') median(audio_time')];
                rxn{curr_recording} = reactivation_time';
                stim2move_med{curr_recording}=[median(stim_to_move(find(curr_tasktype==0))) median(stim_to_move(find(curr_tasktype==1)))];
            end

            use_V = wf_V;
            use_wf_t = wf_t;

            % Task: align to stim/move/reward
            rewarded_trials = logical([trial_events.values.Outcome]');
            use_trials = rewarded_trials(1:n_trials);
            align_times_4 = [ ...
                stimOn_times(use_trials); ...
                stim_move_time(use_trials); ...
                reward_times(1:end-(length(reward_times)-sum(use_trials)));...
                real_iti_move];

            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2
                % 分类标记，stim 0 move 1 reward 2
                align_category = [reshape(ones(sum(use_trials),3).*[1,2,3],[],1);...
                    ones(length(real_iti_move),1)*4];
            elseif workflow_type(curr_recording)==3
                curr_tasktype=cell2mat({trial_events.values(1:n_trials).TaskType});
                % curr_tasktype= curr_tasktype_0(1:n_trials);
                %分类标记
                rewarded_tasktype=curr_tasktype(use_trials)';
                align_category=[rewarded_tasktype ; rewarded_tasktype+10 ; rewarded_tasktype+20;...
                    ones(length(real_iti_move),1)*4+30];
            end


            baseline_times = [repmat(stimOn_times(use_trials),3,1); real_iti_move];

            peri_event_t = reshape(align_times_4,[],1) + reshape(t_task,1,[]);
            baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);

            aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
                length(align_times_4),length(t_task),[]);
            aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
                length(baseline_times),length(baseline_t),[]),2);

            % 减去baseline数据
            aligned_v_baselinesub = aligned_v - aligned_baseline_v;
            align_id = findgroups(reshape(align_category,[],1));
            aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);

            aligned_v_avg_all = permute(aligned_v_baselinesub,[3,2,1]);




            % linear regression data  线性回归后的数据
            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            % Create regressors
            real_stimOn_times=stimOn_times(1:n_trials);
            real_stim_move_time=stim_move_time(1:n_trials);

            pho_on_times=photodiode_times(photodiode_values==1);
            pho_off_times=photodiode_times(photodiode_values==0)+2;


            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2

                move_regressors = {histcounts(real_stim_move_time,wf_regressor_bins)};
                stim_regressors = {histcounts(real_stimOn_times,wf_regressor_bins)};
             wf_t_only_task= {ones(1,length(wf_t))};

            elseif workflow_type(curr_recording)==3

                stim_regressors = {histcounts(real_stimOn_times(curr_tasktype==0),wf_regressor_bins);histcounts(real_stimOn_times(curr_tasktype==1),wf_regressor_bins)};
                move_regressors = {histcounts(real_stim_move_time(curr_tasktype==0),wf_regressor_bins);histcounts(real_stim_move_time(curr_tasktype==1),wf_regressor_bins)};

                % wf_t_only_v= interp1([pho_on_times(curr_tasktype==1);pho_off_times(curr_tasktype==1)], ...
                %     [zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==1),1);....
                %     ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==0),1)], ...
                %     wf_t,'previous')==1;
                % 
                % wf_t_only_a= interp1([pho_on_times(curr_tasktype==0);pho_off_times(curr_tasktype==0)], ...
                %     [zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==1),1);....
                %     ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==0),1)], ...
                %     wf_t,'previous')==1;
                % 
                % wf_t_only_task={wf_t_only_v;wf_t_only_a};



                temp_pho_off_times=[0; photodiode_off_times]
                wf_t_only_v1=interp1([temp_pho_off_times(curr_tasktype==0);photodiode_on_times(curr_tasktype==0)],...
                    [ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==1),1);....
                    zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==0),1)],...
                    wf_t,'previous')==1;
                wf_t_only_v2=interp1([photodiode_on_times(curr_tasktype==0);photodiode_off_times(curr_tasktype==0)],...
                    [ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==1),1);....
                    zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==0)==0),1)],...
                    wf_t,'previous')==1;

                wf_t_only_a1=interp1([temp_pho_off_times(curr_tasktype==1);photodiode_on_times(curr_tasktype==1)],...
                    [ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==1),1);....
                    zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==0),1)],...
                    wf_t,'previous')==1;
                wf_t_only_a2=interp1([photodiode_on_times(curr_tasktype==1);photodiode_off_times(curr_tasktype==1)],...
                    [ones(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==1),1);....
                    zeros(sum(photodiode_values(repelem(curr_tasktype, 2)'==1)==0),1)],...
                    wf_t,'previous')==1;

                wf_t_only_task={wf_t_only_v1+wf_t_only_v2;wf_t_only_a1+wf_t_only_a2};

            end



% figure;
% hold on
% plot(wf_t,wf_t_only_v1+wf_t_only_v2)
% % xline(pho_on_times(curr_tasktype==1))
% xline(photodiode_off_times(curr_tasktype==0),'r')
% xline(photodiode_on_times(curr_tasktype==0),'g')
% 
% ylim([0 1.5])



            iti_move_regressors=histcounts(real_iti_move,wf_regressor_bins);
            wf_pd_off = interp1(photodiode_times,photodiode_values,wf_t,'previous')==0;
           
            wf_t_only_iti = interp1([pho_on_times;pho_off_times], ...
                [zeros(sum(photodiode_values==1),1);ones(sum(photodiode_values==0),1)], ...
                wf_t,'previous')==1;

        



            % move_regressor = histcounts(stim_move_time,wf_regressor_bins);
            % regressors = {stim_regressors;move_regressors};
            % % Set time shifts for regressors
            % t_shifts = {[-5:30];[-30:30]};
            % % Set cross validation (not necessary if just looking at kernels)
            % cvfold = 5;
            % % Do regression
            % [kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
            %     ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);


            n_components = 200;
            frame_shifts = -10:30;
            lambda = 15;

    
            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    [stim_kernels,predicted_signals,explained_var] = ...
           cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1)),-frame_shifts,lambda),...
               wf_t_only_task, stim_regressors ,'UniformOutput',false );


                    % [stim_kernels1,predicted_signals,explained_var] = ...
                    %     ap.regresskernel(wf_V(1:n_components,:),stim_regressors{1},-frame_shifts,lambda)

                     % [BUF_kernels,BUF_predict,exp]= ap.regresskernel(stim_regressors,wf_V,-frame_shifts,lambda);


                    success = true; % 如果没有报错，则成功运行
                catch ME
                    disp(['Error: ', ME.message]);
                    n_components = n_components - 10; % 变量 a 递减
                    if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
                        error('n_components 过小，无法继续运行');
                    end
                end
            end

            disp('stim_kernels_running_successfully');
           
            

% % 
%   a0=plab.wf.svd2px(U_master(:,:,1:200),stim_kernels{1});
%   a1=plab.wf.svd2px(U_master(:,:,1:200),stim_kernels1);
% 
%   % ap.imscroll(a0-a1)
%  figure;
%  imagesc(max(a0(:,:,t_kernels>0&t_kernels<0.2),[],3))
%    clim([0 0.0004])
%  axis image off;
% ap.wf_draw('ccf', 'black');
% colormap( ap.colormap(['WG']  ));
% 
%  figure;
%  imagesc(max(a1(:,:,t_kernels>0&t_kernels<0.2),[],3))
%    clim([0 0.0004])
%  axis image off;
% ap.wf_draw('ccf', 'black');
% colormap( ap.colormap(['WG']  ));



            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    % [move_kernels,predicted_signals,explained_var] = ...
                    % ap.regresskernel(wf_V(1:n_components,:),move_regressors,-frame_shifts,lambda);


                    [move_kernels,predicted_signals,explained_var] = ...
                        cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1)),-frame_shifts,lambda),...
                        wf_t_only_task, move_regressors ,'UniformOutput',false );

                    success = true; % 如果没有报错，则成功运行
                catch ME
                    disp(['Error: ', ME.message]);
                    n_components = n_components - 10; % 变量 a 递减
                    if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
                        error('n_components 过小，无法继续运行');
                    end
                end
            end

            disp('move_kernels_running_successfully');


            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    [iti_move_kernels,predicted_signals,explained_var] = ...
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


            wf_px_task_kernels{curr_recording}={cat(3,stim_kernels{:}),cat(3,move_kernels{:}),iti_move_kernels}';

            % for curr_kernels=1:2
            %     wf_V_stim_reduced_kernels=predicted_signals_reduced(:,:,curr_kernels);
            %
            %     aligned_v_all_kernels = reshape(interp1(use_wf_t,wf_V_stim_reduced_kernels',peri_event_t_all,'previous'), ...
            %         length(align_times_3_all),length(t_task),[]);
            %     aligned_baseline_v_all_kernels = nanmean(reshape(interp1(use_wf_t,wf_V_stim_reduced_kernels',baseline_event_t_all,'previous'), ...
            %         length(baseline_times_all),length(baseline_t),[]),2);
            %
            %     aligned_v_baselinesub_all_kernels = aligned_v_all_kernels - aligned_baseline_v_all_kernels;
            %     aligned_v_avg_all_kernels = permute(aligned_v_baselinesub_all_kernels,[3,2,1]);
            %
            %
            %     wf_px_task_kernels_all{curr_recording}{curr_kernels}=aligned_v_avg_all_kernels;
            % end


            wf_px_task_all{curr_recording}=aligned_v_avg_all;
            % reward_or_not_id_all=[use_trials; use_trials; logical(ones(sum(use_trials),1))];
            reward_or_not_id_all=repmat(use_trials,3,1);
            wf_px_task_all_type_id{curr_recording}=align_id;
            wf_px_task_all_reward_id{curr_recording}=reward_or_not_id_all;
            wf_px_task_all_timepoint{curr_recording}=align_times_4;
            wf_px_task{curr_recording}=aligned_v_avg;
            img_size(curr_recording,:)=size(wf_avg);



            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});
            ap.print_progress_fraction(curr_recording,length(recordings2));


        end

        % learned_day = rxn_stat_p < 0.05 & rxn_med < 2;

        % pre_time=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
        % post_time=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
        % react_index=(post_time-pre_time)./(post_time+pre_time);
        % 
        % pre_time_V=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
        % post_time_V=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
        % 
        % pre_time_A=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
        % post_time_A=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
        % react_index_VA={(post_time_V-pre_time_V)./(post_time_V+pre_time_V), (post_time_A-pre_time_A)./(post_time_A+pre_time_A)};


    end
     save([Path 'task\' animal '_task.mat' ],'workflow_type','workflow_type_name',...
        'workflow_type_name_merge','wf_px_task',...
        'wf_px_task_kernels','img_size','workflow_day', '-v7.3')

    % save([Path 'task\' animal '_task.mat' ],'workflow_type','workflow_type_name',...
    %     'workflow_type_name_merge','frac_move_stimalign','wf_px_task',...
    %     'wf_px_task_kernels','img_size','workflow_day','react_index',...
    %     'react_index_VA','rxn_stat_p','rxn_med','stim2move_med', '-v7.3')
    % 
    % save([Path 'task\' animal '_task_single_trial.mat' ],'wf_px_task_all',...
    %     'wf_px_task_all_type_id','wf_px_task_all_reward_id','wf_px_task_all_timepoint',...
    %     'tasktype','rxn','stim2move','iti_move_time', '-v7.3')

end

