%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\';


animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};

% animals = {'HA000','HA001','HA002'};

use_workflow=2
workflow={'lcr_passive','hml_passive_audio'}
trial_type=[-90 0 90;4000 8000 12000];

% passive_workflow='lcr_passive';
passive_workflow=workflow{use_workflow};
type_workflow=trial_type(use_workflow,:)
% passive_workflow='task';

for curr_animal_idx=1:length(animals)
    preload_vars_main = who;

    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving ' passive_workflow ' files...']);

    data_load=load([Path '\' passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ]);
    quiescent_time=1;

    % 定义所有条件逻辑
conditions = {
    @(b, c, d) (b == type_workflow(1)) & (c == 1) & (d > quiescent_time);
    @(b, c, d) (b ==  type_workflow(2)) & (c == 1) & (d > quiescent_time);
    @(b, c, d) (b ==  type_workflow(3)) & (c == 1) & (d > quiescent_time)
};

% 计算每个条件的均值并拼接结果
wf_px_01s = cellfun(@(a, b, c, d) ...
    cat(3, ...
        mean(a(:, :, conditions{1}(b, c, d)), 3), ...
        mean(a(:, :, conditions{2}(b, c, d)), 3), ...
        mean(a(:, :, conditions{3}(b, c, d)), 3)), ...
    data_load.wf_px_all, data_load.trial_type, data_load.trial_state, data_load.trial_stim_time, ...
    'UniformOutput', false);

   
    save([Path passive_workflow '\' animal '_' passive_workflow '.mat' ],'wf_px_01s','-append')

    clearvars('-except',preload_vars_main{:});
end
