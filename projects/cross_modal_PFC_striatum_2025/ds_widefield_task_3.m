%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

server_path= [plab.locations.server_path  'Lab\widefield_alignment\animal_alignment'];

surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-5:30];

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

workflow_name_map = containers.Map( ...
    {'stim_wheel_right_stage1_audio_volume', ...
    'stim_wheel_right_stage2_audio_volume', ...
    'stim_wheel_right_stage1', ...
    'stim_wheel_right_stage2', ...
    'stim_wheel_right_stage1_size_up', ...
    'stim_wheel_right_stage2_size_up', ...
    'stim_wheel_right_stage1_opacity', ...
    'stim_wheel_right_stage2_opacity',...
    'stim_wheel_right_stage1_audio_frequency',...
    'stim_wheel_right_stage2_audio_frequency',...
    'stim_wheel_right_stage2_mixed_VA',...
    'stim_wheel_right_frequency_stage2_mixed_VA'}, ...
    {'audio volume', 'audio volume', ...
    'visual position', 'visual position', ...
    'visual size up', 'visual size up', ...
    'visual opacity', 'visual opacity',...
    'audio frequency','audio frequency',...
    'mixed VA','mixed VA'} );


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
    'stim_wheel_right_stage2_audio_volume*$|' ...
    'stim_wheel_right_stage1_audio_frequency$|' ...
    'stim_wheel_right_stage2_audio_frequency$|' ...
    'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
    'stim_wheel_right_stage2_mixed_VA$'];

% animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
%     'DS000','DS004','DS014','DS015','DS016',...
%     'AP018','AP020','DS006','DS013',...
%     'AP027','AP028','DS019','DS020','DS021',...
%     'AP027','AP028','AP029',...
%     'HA003','HA004','DS019','DS020','DS021',...
%     'HA000','HA001','HA002','DS005'};
animals={'DS030','DS031','DS029'}

% animals={'HA009','HA010','HA011','HA012'};
for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};

    load(fullfile(server_path, ['wf_alignment_' animal ]))
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
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

    recordings2=recordings2( 1:find(strcmp({recordings2.day},wf_tform.day(end))));

    %%是否存在保存过之前的数据的文件
    if     exist ([Path 'task\' animal '_task.mat' ])==2
        load([Path 'task\' animal '_task.mat' ])
            file_length=  length(wf_px_task); 
    else

        file_length=0;
        wf_px_task = cell(size(recordings2));
        wf_px_task_kernels = cell(size(recordings2));
        wf_px_task_kernels_encode = cell(size(recordings2));
        all_groups_name = cell(size(recordings2))';
        workflow_type=zeros(length(recordings2),1);
        workflow_type_name=cell(length(recordings2),1);
        workflow_type_name_merge=cell(length(recordings2),1);
        stim2move=cell(length(recordings2),1);
        stim2move_correct=cell(length(recordings2),1);
        wf_px_task_all_type_id= cell(length(recordings2),1);
        wf_px_task_all_reward_id= cell(length(recordings2),1);
        wf_px_task_all= cell(length(recordings2),1);
        wf_px_task_kernels_all= cell(length(recordings2),1);
        wf_px_task_all_itimove=cell(length(recordings2),1);
        tasktype=cell(length(recordings2),1);

    end

    workflow_day={recordings2.day}';


    if ~(file_length==length(recordings2))
        for curr_recording =file_length+1:length(recordings2)
            % for curr_recording =4:length(recordings2)
            fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);

            % Grab pre-load vars
            preload_vars = who;

            % Load data
            rec_day = recordings2(curr_recording).day;

            [~,index_real]=max( cellfun(@(rt) ...
                numel(load( ...
                plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
                'timestamps').timestamps), ...
                recordings2(curr_recording).recording));
            rec_time = recordings2(curr_recording).recording{index_real};


            workflow_type_name{curr_recording}=recordings2(curr_recording).workflow{index_real};
            workflow_type_name_merge{curr_recording}=workflow_name_map(recordings2(curr_recording).workflow{index_real});


            if contains( workflow_type_name{curr_recording}, {'audio_volume', 'audio_frequency'})
                workflow_type(curr_recording) = 2;
            elseif contains( workflow_type_name{curr_recording}, {'mixed_VA'})
                workflow_type(curr_recording) = 3;
            elseif contains( workflow_type_name{curr_recording}, {'stage1', 'stage2'}) && ...
                    (contains( workflow_type_name{curr_recording}, {'opacity', 'size_up', 'angle'}) || ...
                    isempty(regexp( workflow_type_name{curr_recording}, 'audio|mixed', 'once')))
                workflow_type(curr_recording) = 1;
            else
                workflow_type(curr_recording) = NaN;  % 未知类型
            end



            verbose=true;
            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;


            % if WF is not aligned， jump out of the loop
            if ~exist('wf_V','var')
                break   % 直接跳出整个for循环
            end



            ds.load_iti_move
            if length(iti_move_time)==1
                iti_move_time=[iti_move_time ;iti_move_time];
            end


            % process behavioral data
            stim2move{curr_recording}=stim_to_move;
            % Get median stim-outcome time
            if length(stimOn_times)< length([trial_events.timestamps.Outcome])
                n_trials =length(stimOn_times);
            else
                n_trials = length([trial_events.timestamps.Outcome]);
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
                iti_move_time];

            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2
                % 分类标记，stim 0 move 1 reward 2
                align_category = [reshape(ones(sum(use_trials),3).*[1,2,3],[],1);...
                    ones(length(iti_move_time),1)*4];
                curr_tasktype=[];
            elseif workflow_type(curr_recording)==3
                curr_tasktype_0=cell2mat({trial_events.values.TaskType});
                curr_tasktype= curr_tasktype_0(1:n_trials);
                %分类标记
                rewarded_tasktype=curr_tasktype(use_trials)';
                align_category=[rewarded_tasktype ; rewarded_tasktype+10 ; rewarded_tasktype+20;...
                    ones(length(iti_move_time),1)*4+30];
            end


            baseline_times = [repmat(stimOn_times(use_trials),3,1); iti_move_time];
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
            real_reward_times=reward_times(1: sum(rewarded_trials(1:n_trials)==1));
            pho_on_times=photodiode_times(photodiode_values==1);
            pho_off_times=photodiode_times(photodiode_values==0)+2;
            iti_move_regressors=histcounts(iti_move_time,wf_regressor_bins);


            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2
                move_regressors = {histcounts(real_stim_move_time,wf_regressor_bins)};
                stim_regressors = {histcounts(real_stimOn_times,wf_regressor_bins)};
                reward_regressors = {histcounts(real_reward_times,wf_regressor_bins)};

                wf_t_only_task= {ones(1,length(wf_t))};

                all_move_regressor=double(move_regressors{1} | iti_move_regressors);

            elseif workflow_type(curr_recording)==3
                stim_regressors = {histcounts(real_stimOn_times(curr_tasktype==0),wf_regressor_bins);...
                    histcounts(real_stimOn_times(curr_tasktype==1),wf_regressor_bins)};
                move_regressors = {histcounts(real_stim_move_time(curr_tasktype==0),wf_regressor_bins);...
                    histcounts(real_stim_move_time(curr_tasktype==1),wf_regressor_bins)};
                reward_regressors= {histcounts(real_reward_times(curr_tasktype(rewarded_trials(1:n_trials))==0),wf_regressor_bins);...
                    histcounts(real_reward_times(curr_tasktype(rewarded_trials(1:n_trials))==1),wf_regressor_bins)};

                all_move_regressor=double(move_regressors{1} |move_regressors{2} | iti_move_regressors);


                temp_pho_off_times=[0; photodiode_off_times];
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

            wf_pd_off = interp1(photodiode_times,photodiode_values,wf_t,'previous')==0;
            wf_t_only_iti = interp1([pho_on_times;pho_off_times], ...
                [zeros(sum(photodiode_values==1),1);ones(sum(photodiode_values==0),1)], ...
                wf_t,'previous')==1;


            % move_regressor = histcounts(stim_move_time,wf_regressor_bins);
            temp_regressors=[stim_regressors(:);move_regressors(:);{iti_move_regressors};reward_regressors(:)];



            regressors=cat(1,temp_regressors{:});


            t_shifts=[-10:30];
            % Set cross validation (not necessary if just looking at kernels)
            cvfold = 5;
            % Do encoding regression
            [kernels_encode,predicted_signals,explained_var,predicted_signals_reduced] = ...
                ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

            % Do decoding regression
            n_components = 200;
            frame_shifts = -10:30;
            lambda = 15;


            decrement = 10;       % 每次失败减少多少
            min_components = 100;
           
            for task = 1:5
                % 为每个任务设定最小值（可按需调整）
                switch task
                    case 1,  task_name = 'stim_kernels';
                    case 2,  task_name = 'move_kernels';
                    case 3,  task_name = 'iti_move_kernels';
                    case 4,  task_name = 'all_move_kernels';
                    case 5,  task_name = 'reward_kernels';
                end

                % 从当前全局 n_components 开始尝试（局部变量 n_cur）
                n_cur = n_components;
                success = false;
                % 可选：记录捕获的错误信息以供调试
                error_messages = {};
                while ~success
                    try
                        disp(['Running ', task_name, ' with n_components = ', num2str(n_cur)]);
                        switch task
                            case 1 % stim_kernels (cellfun)
                                [stim_kernels, predicted_signals, explained_var] = ...
                                    cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                                    wf_t_only_task, stim_regressors, 'UniformOutput', false );

                            case 2 % move_kernels (cellfun)
                                [move_kernels, predicted_signals, explained_var] = ...
                                    cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                                    wf_t_only_task, move_regressors, 'UniformOutput', false );

                            case 3 % iti_move_kernels (direct call)
                                [iti_move_kernels, predicted_signals, explained_var] = ...
                                    ap.regresskernel(wf_V(1:n_cur, wf_t_only_iti), iti_move_regressors(wf_t_only_iti), -frame_shifts, lambda);

                            case 4 % all_move_kernels (direct call)
                                [all_move_kernels, predicted_signals, explained_var] = ...
                                    ap.regresskernel(wf_V(1:n_cur, :), all_move_regressor, -frame_shifts, lambda);

                            case 5 % reward_kernels (cellfun)
                                [reward_kernels, predicted_signals, explained_var] = ...
                                    cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                                    wf_t_only_task, reward_regressors, 'UniformOutput', false );
                        end

                        success = true;
                        disp([task_name, '_running_successfully']);

                        % 如果你希望后面的任务沿用被降过的 n，更新 start_n
                        start_n = n_cur;

                    catch ME
                        % 捕获错误并准备重试（降 n_cur）
                        disp(['Error in ', task_name, ': ', ME.message]);
                        error_messages{end+1} = ME.message; %#ok<SAGROW>
                        n_cur = n_cur - decrement;

                        if n_cur < min_components
                            % 超过可接受最小值，抛出错误并显示日志
                            disp(['Failed ', task_name, ': n_components (', num2str(n_cur), ') < min (', num2str(min_components), ')']);
                            disp('Errors encountered during attempts:');
                            for ii = 1:length(error_messages)
                                disp(['  Attempt ', num2str(ii), ': ', error_messages{ii}]);
                            end
                            error('n_components 过小，无法继续运行 %s', task_name);
                        end
                        % 否则循环继续，尝试更小的 n_cur
                    end
                end
            end

            % 最终报告（可选）
            disp(['All tasks finished. Final n_components = ', num2str(start_n)]);




            wf_px_task_kernels{curr_recording}={cat(3,stim_kernels{:}),cat(3,move_kernels{:}),iti_move_kernels,...
                all_move_kernels,cat(3,reward_kernels{:})}';

            wf_px_task_kernels_encode{curr_recording}=kernels_encode;


            wf_px_task_all{curr_recording}=aligned_v_avg_all;
            wf_px_task_all_type_id{curr_recording}=align_id;
            wf_px_task_all_reward_id{curr_recording}=repmat(use_trials,3,1);
            wf_px_task_all_itimove{curr_recording}=iti_move_time;

            stim2move_correct{curr_recording}=stim_to_move(use_trials);

            if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2
                wf_px_task_all{curr_recording}= aligned_v_avg_all(:,:,align_id==1);
            elseif workflow_type(curr_recording)==3
                wf_px_task_all{curr_recording}= aligned_v_avg_all(:,:,align_id==1|align_id==2);
            end

            wf_px_task{curr_recording}=aligned_v_avg;
            img_size(curr_recording,:)=size(wf_avg);
            tasktype{curr_recording}=curr_tasktype;


            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});
            ap.print_progress_fraction(curr_recording,length(recordings2));

        end
    end

    save([Path 'task\' animal '_task.mat' ],'workflow_type','workflow_type_name',...
        'workflow_type_name_merge','wf_px_task',...
        'wf_px_task_kernels','wf_px_task_kernels_encode','workflow_day', '-v7.3')

    % save([Path 'task\single_trial\' animal '_task_single_trial.mat' ],'wf_px_task_all',...
    %     'tasktype','stim2move_correct', '-v7.3')

    % save([Path 'task\single_trial\' animal '_task_single_trial.mat' ],'wf_px_task_all',...
    %    'wf_px_task_all_type_id','wf_px_task_all_reward_id','wf_px_task_all_itimove',...
    %    'tasktype','stim2move', '-v7.3')

end

