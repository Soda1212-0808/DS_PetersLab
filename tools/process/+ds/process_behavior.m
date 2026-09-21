
%% default setting
fprintf('start processing behavior data...\n');
behavior=struct;

% 计算 iti move的时间点
ds.load_iti_move

% tasktype
if contains('TaskType', fieldnames(trial_events.values))
    tasktype=feval(@(x) x(1:n_trials), [trial_events.values.TaskType]);
else
    tasktype= ones(1, n_trials);
end
% move trace time period
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

%% success
outcome=cat(1,trial_events.values.Outcome)';
if contains('TaskType', fieldnames(trial_events.values))

    % 识别 correction trials
    n_outcome = numel(outcome');
    % 1) 识别触发 correction 的位置：res==0 且 前一 trial 为 1（把第1位视作前一位为1以触发）
    prev = [1; outcome(1:end-1)'];             % 将第1位的"前一位"设为1（如果res(1)==0，应该触发）
    triggers = find(outcome'==0 & prev==1);   % 触发索引 i (表示第 i 次错，correction 从 i+1 开始)
    % 2) 计算每个位置向右第一个为1的位置（包含当前位置），用 fillmissing 向右填充索引
    nextOne = nan(n_outcome,1);
    oneIdx = find(outcome'==1);
    nextOne(oneIdx) = oneIdx;            % 在为1的位置放置它的索引
    nextOne = fillmissing(nextOne,'next'); % 向右填充：每个位置得到"该位或右侧第一个1的索引"
    % 3) 对每个 trigger 构造 correction 区间的 start/end（start = trigger+1）
    starts = triggers + 1;
    valid = starts <= n_outcome;                  % 去掉超出范围的触发（trigger==n 的情况）
    starts = starts(valid);
    % end index 是从 start 位置向右第一个1（若没有则到 n）
    ends = nextOne(starts);
    ends(isnan(ends)) = n_outcome;               % 如果没有后续1，则延伸到序列末尾
    % 4) 用差分（prefix-sum trick）把所有区间合并成一个 mask（完全无循环）
    if isempty(starts)
        corrMask = false(n_outcome,1);
    else
        delta = zeros(n_outcome+1,1);
        delta(starts) = delta(starts) + 1;
        delta(ends+1) = delta(ends+1) - 1;   % ends 可以为 n -> index n+1 有意义
        corrMask = cumsum(delta(1:n_outcome)) > 0;
    end

    corrIdx = find(corrMask);
    normalIdx = ~corrMask;

    success=...
        arrayfun(@(id) sum(tasktype(normalIdx(1:n_trials))==id&outcome(normalIdx(1:n_trials))==1)/...
        sum(tasktype(normalIdx(1:n_trials))==id),unique(tasktype),'UniformOutput',true);

else
    success=nanmean(outcome);
end
%% movement dynamic
% Align wheel movement to stim onset
type_sort = arrayfun(@(k) ...
    find (tasktype == floor((k-1)/2) & ...
    outcome == 1-mod(k-1,2)), ...
    (1:2*length(unique(tasktype)))', 'UniformOutput', false);

status = {'correct', 'error'};
labels = arrayfun(@(k) ...
    sprintf('type%d_%s', floor((k-1)/2), ...
    status{mod(k-1,2)+1}), ...
    (1:2*length(unique(tasktype)))', 'UniformOutput', false);

pull_move_times=stim_move_time + surround_time_points;
stim_move_aligned_wheel_vel=interp1(timelite.timestamps, ...
    wheel_velocity,pull_move_times,'previous');

pull_stim_times=stimOn_times(1:n_trials) + surround_time_points;
stim_aligned_wheel_vel=interp1(timelite.timestamps, ...
    wheel_velocity,pull_stim_times,'previous');


stim_move_aligned_wheel_vel_sort=cellfun(@(x) stim_move_aligned_wheel_vel(x,:), type_sort,'UniformOutput',false );

stim_aligned_wheel_vel_sort=cellfun(@(x) stim_aligned_wheel_vel(x,:), type_sort,'UniformOutput',false );




%% performance
stats={'mad','median','mean'};
[rxn_f_p, stim2move_f_stats,stim2move_f_null_stats]=...
    cellfun(@(x)  ds.stimwheel_association_pvalue( ...
    stimOn_times,trial_events,stim_to_move,tasktype,x), stats,'uni',false);
[rxn_l_p, stim2move_l_stats,stim2move_l_null_stats]=...
    cellfun(@(x)  ds.stimwheel_association_pvalue( ...
    stimOn_times,trial_events,stim_to_lastmove,tasktype,x), stats,'uni',false);

mad_idx = strcmp(stats, 'mad');
performance=  [ (stim2move_l_null_stats{mad_idx}-stim2move_l_stats{mad_idx})./...
    (stim2move_l_null_stats{mad_idx}+stim2move_l_stats{mad_idx})]';


%% iti phase behavior
pull_times_iti_move= cellfun(@(x) x + surround_time_points,iti_move_time,'UniformOutput',false) ;
iti_move_aligned_wheel_vel=cellfun(@(x) interp1(timelite.timestamps, ...
    wheel_velocity,x,'previous'),pull_times_iti_move,'uni',false);

%% save in behavior

behavior.stim_move_aligned_wheel_vel=stim_move_aligned_wheel_vel_sort;
behavior.stim_aligned_wheel_vel=stim_aligned_wheel_vel_sort;
behavior.wheel_vel_labels=labels;
behavior.iti_move_aligned_wheel_vel=iti_move_aligned_wheel_vel;
behavior.rxn_f_p=cat(1,rxn_f_p{:})';
behavior.stim2move_f_stats=cat(1,stim2move_f_stats{:})';
behavior.rxn_l_p=cat(1,rxn_l_p{:})';
behavior.stim2move_l_stats=cat(1,stim2move_l_stats{:})';
behavior.perform_stats=stats;
behavior.performance=performance;
behavior.success=success;



