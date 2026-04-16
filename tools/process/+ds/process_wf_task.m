    fprintf('%s...\n', ['start processing widefield data in ' bonsai_workflow ]);

%% Define what to process

if ~exist('wf_task_process_parts','var')
    wf_task_process_parts = struct('stim', true, 'move', true, 'iti_move', true, 'reward', true, 'all_iti_move', true);
else
    if ~isfield(wf_task_process_parts,'stim'),     wf_task_process_parts.stim = false; end
    if ~isfield(wf_task_process_parts,'move'),     wf_task_process_parts.move = false; end
    if ~isfield(wf_task_process_parts,'iti_move'), wf_task_process_parts.iti_move = false; end
    if ~isfield(wf_task_process_parts,'reward'), wf_task_process_parts.reward = false; end
    if ~isfield(wf_task_process_parts,'all_iti_move'), wf_task_process_parts.all_iti_move = false; end

end

% 任务配置
task_names = {'stim_kernels','move_kernels','iti_move_kernels','reward_kernels','all_iti_move_kernels'};
task_flags = [wf_task_process_parts.stim, wf_task_process_parts.move, ...
    wf_task_process_parts.iti_move, wf_task_process_parts.reward,...
     wf_task_process_parts.all_iti_move];

% 只处理被选中的任务
selected_tasks = find(task_flags);

%%


wf_task_data=struct;
ds.load_iti_move
if length(iti_move_time)==1
    iti_move_time=[iti_move_time ;iti_move_time];
end


if length(stimOn_times)< length([trial_events.timestamps.Outcome])
    n_trials =length(stimOn_times);
else
    n_trials = length([trial_events.timestamps.Outcome]);
end


% Task: align to stim/move/reward
rewarded_trials = logical([trial_events.values.Outcome]');
use_trials = rewarded_trials(1:n_trials);
align_times_4 = [ ...
    stimOn_times(use_trials); ...
    stim_move_time(use_trials); ...
    reward_times(1:end-(length(reward_times)-sum(use_trials)));...
    iti_move_time];



%% 

% linear regression data  线性回归后的数据
wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
% Create regressors
real_stimOn_times=stimOn_times(1:n_trials);
real_stim_move_time=stim_move_time(1:n_trials);
real_reward_times=reward_times(1: sum(rewarded_trials(1:n_trials)==1));
pho_on_times=photodiode_times(photodiode_values==1);
pho_off_times=photodiode_times(photodiode_values==0)+2;
iti_move_regressors=histcounts(iti_move_time,wf_regressor_bins);
all_iti_move_regressors=histcounts(all_iti_move_time,wf_regressor_bins);


if ~isfield(trial_events.values,'TaskType')

    move_regressors = {histcounts(real_stim_move_time,wf_regressor_bins)};
    stim_regressors = {histcounts(real_stimOn_times,wf_regressor_bins)};
    reward_regressors = {histcounts(real_reward_times,wf_regressor_bins)};
    wf_t_only_task= {ones(1,length(wf_t))};
    % all_move_regressor=double(move_regressors{1} | iti_move_regressors);

elseif  isfield(trial_events.values,'TaskType')
    curr_tasktype_0=vertcat(trial_events.values.TaskType);
    stim_to_move_idx= curr_tasktype_0(1:n_trials);
    temp_idx=1:length(unique(stim_to_move_idx));

    stim_regressors = repmat({zeros(1,length(wf_t))}, 2, 1);
    stim_regressors(temp_idx)= arrayfun(@(a)  histcounts(real_stimOn_times(stim_to_move_idx==a),wf_regressor_bins),...
        unique(stim_to_move_idx),'UniformOutput',false  );

    move_regressors = repmat({zeros(1,length(wf_t))}, 2, 1);
    move_regressors(temp_idx)= arrayfun(@(a)  histcounts(real_stim_move_time(stim_to_move_idx==a),wf_regressor_bins),...
        unique(stim_to_move_idx),'UniformOutput',false  );
      
    reward_regressors = repmat({zeros(1,length(wf_t))}, 2, 1);
    reward_regressors(temp_idx)= arrayfun(@(a)  histcounts(real_reward_times(stim_to_move_idx(rewarded_trials(1:n_trials))==a),wf_regressor_bins),...
        unique(stim_to_move_idx),'UniformOutput',false  );


    gap_1=seconds([trial_events.timestamps(1:n_trials).ITIStart ] -trial_events.timestamps(1).StimOn (1))'+photodiode_on_times(1);
    gap_2=stimOn_times(1:n_trials)+stim_to_outcome(1:n_trials);

    wf_t_only_task= repmat({false(1,length(wf_t))}, 2, 1);
    wf_t_only_task(temp_idx)=arrayfun(@(a) (interp1([gap_1(stim_to_move_idx==a);gap_2(stim_to_move_idx==a)],...
        [ones(sum(stim_to_move_idx==a),1);....
        zeros(sum(stim_to_move_idx==a),1)],...
        wf_t,'previous')==1)', unique(stim_to_move_idx),'UniformOutput',false);
end


wf_t_only_iti = interp1([pho_on_times;pho_off_times], ...
    [zeros(sum(photodiode_values==1),1);ones(sum(photodiode_values==0),1)], ...
    wf_t,'previous')==1;

  % Do decoding regression
  n_components = 200;
  frame_shifts = -10:30;
  lambda = 15;

  decrement = 10;       % 每次失败减少多少
  min_components = 100;

  for task = selected_tasks
      % 为每个任务设定最小值（可按需调整）

      switch task
          case 1,  task_name = task_names{1};
          case 2,  task_name = task_names{2};
          case 3,  task_name = task_names{3};
          case 4,  task_name = task_names{4};
          case 5,  task_name = task_names{5};


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
                      task_data.stim_kernels = ...
                          cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                          wf_t_only_task, stim_regressors, 'UniformOutput', false );

                  case 2 % move_kernels (cellfun)
                      task_data.move_kernels = ...
                          cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                          wf_t_only_task, move_regressors, 'UniformOutput', false );

                  case 3 % iti_move_kernels (direct call)
                      task_data.iti_move_kernels = ...
                          {ap.regresskernel(wf_V(1:n_cur, wf_t_only_iti), iti_move_regressors(wf_t_only_iti), -frame_shifts, lambda)};
                  case 4 % iti_move_kernels (direct call)
                       task_data.reward_kernels = ...
                          cellfun(@(x,y) ap.regresskernel(wf_V(1:n_cur, find(x==1)), y(find(x==1)), -frame_shifts, lambda), ...
                          wf_t_only_task, reward_regressors, 'UniformOutput', false );
                  case 5 % iti_move_kernels (direct call)
                      task_data.all_iti_move_kernels = ...
                          {ap.regresskernel(wf_V(1:n_cur, wf_t_only_iti), all_iti_move_regressors(wf_t_only_iti), -frame_shifts, lambda)};

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

