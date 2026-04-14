%
 fprintf('start processing behavior data...\n');

behavior=struct;
% 计算 iti move的时间点
ds.load_iti_move


% Get median stim-outcome time
% n_trials = length([trial_events.values.Outcome]);
% multi-task-type
if contains('TaskType', fieldnames(trial_events.values))
    tasktype=feval(@(x) x(1:n_trials), [trial_events.values.TaskType]);
else
    tasktype= ones(1, n_trials);
end


surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

% Align wheel movement to stim onset
pull_times = arrayfun(@(type) stim_move_time(tasktype==type) + surround_time_points , unique(tasktype)','UniformOutput',false) ;
stim_move_aligned_wheel_vel = cellfun(@(x) interp1(timelite.timestamps, ...
    wheel_velocity,x,'previous'),pull_times,'uni',false);


event_aligned_wheel_move = cellfun(@(x) interp1(timelite.timestamps, ...
    +wheel_move,x,'previous'),pull_times,'uni',false);

pull_times_iti_move= iti_move_time + surround_time_points ;
iti_move_aligned_wheel_vel=cellfun(@(x) interp1(timelite.timestamps, ...
    wheel_velocity,x,'previous'),{pull_times_iti_move},'uni',false);


stats={'mad','median','mean'};
[rxn_f_p, stim2move_f_stats,stim2move_f_null_stats]=...
  cellfun(@(x)  ds.stimwheel_association_pvalue( ...
    stimOn_times,trial_events,stim_to_move,tasktype,x), stats,'uni',false);
[rxn_l_p, stim2move_l_stats,stim2move_l_null_stats]=...
  cellfun(@(x)  ds.stimwheel_association_pvalue( ...
    stimOn_times,trial_events,stim_to_lastmove,tasktype,x), stats,'uni',false);

mad_idx = strcmp(stats, 'mad');

behavior.stim_move_aligned_wheel_vel=stim_move_aligned_wheel_vel;
behavior.iti_move_aligned_wheel_vel=iti_move_aligned_wheel_vel;

behavior.event_aligned_wheel_move=event_aligned_wheel_move;
behavior.rxn_f_p=cat(1,rxn_f_p{:})';
behavior.stim2move_f_stats=cat(1,stim2move_f_stats{:})';
behavior.rxn_l_p=cat(1,rxn_l_p{:})';
behavior.stim2move_l_stats=cat(1,stim2move_l_stats{:})';
behavior.stats=stats;
behavior.performance=...
   [ (stim2move_l_null_stats{mad_idx}-stim2move_l_stats{mad_idx})./...
    (stim2move_l_null_stats{mad_idx}+stim2move_l_stats{mad_idx})]';

