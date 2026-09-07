nMove_r = histcounts(iti_move_time_r, [0 ;stimOn_times]);
nMove_l = histcounts(iti_move_time_l, [0 ;stimOn_times]);
task_types=[trial_events.values.TaskType];

sum(nMove_l(task_types==1))/length(nMove_l(task_types==1))
sum(nMove_l(task_types~=1))/length(nMove_l(task_types~=1))
