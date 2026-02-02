clear all
Path = 'D:\Data process\wf_data\';

animal = 'DS025';

% use_workflow =...
%     {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
%     'stim_wheel_VcenterAfreq2_cross_movement_stage*'};
use_workflow = {'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

recordings = plab.find_recordings(animal,[],use_workflow);
% only ephys data
recordings=recordings(find([recordings.ephys]==1));

psth_all=cell(length(recordings),1);
load_probes=[2,2,2,2,1,1,1];
id_all={[136 213];[67 152];[60 200];[1 68];[1 110];[1 108];[1 28]};

for curr_recording =1:length(recordings)


    load_probe=load_probes(curr_recording);
    rec_day = recordings(curr_recording).day;
    rec_time = recordings(curr_recording).recording{1};
    ap.load_recording
    % PSTH for all conditions

    task_types=[trial_events.values.TaskType];
    task_types=task_types(1:n_trials);
    task_outcome=[trial_events.values.Outcome];
    stimOn_times=stimOn_times(1:n_trials);

    align_times= arrayfun(@(a) stimOn_times(task_types==a & task_outcome==1) ,0:3,'uni',false);

    [psth_all{curr_recording},~,unit_psth_t] = ...
        ap.psth(spike_times_timelite,align_times,spike_templates, ...
        'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);



end

psth_all_select= cellfun(@(a,b)  a(b(1):b(2),:,:),psth_all,id_all,'UniformOutput',false);
unit_psth=cat(1,psth_all_select{:});
unit_psth=unit_psth(:,unit_psth_t>-0.1&unit_psth_t<0.2);


B = reshape(unit_psth, size(unit_psth,1), []);
figure;
imagesc(B)
hold on
clim([-5,5])

[coeff, score, latent, tsquared, explained, mu]=pca(B);
figure;
scatter3(score(:,1),score(:,2),score(:,3))
