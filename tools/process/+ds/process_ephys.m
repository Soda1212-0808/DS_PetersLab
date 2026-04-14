
% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t_stim = [-0.1,0];
response_t_stim = [0.05,0.15];
psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);


% (get quiescent trials)
stim_window = [0,0.3];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    (1:length(stimOn_times))');

if contains(bonsai_workflow,'lcr')
        stim_type = vertcat(trial_events.values.TrialStimX);

    min_idx=min(length(stim_type),length(stimOn_times));
    stimOn_times=stimOn_times(1:min_idx);
    quiescent_trials=quiescent_trials(1:min_idx);
    % (vis passive)
    stim_values = unique(stim_type);
    use_align = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);
elseif contains(bonsai_workflow,'hml')
    % (aud passive)
        stim_type = vertcat(trial_events.values.StimFrequence);

    min_idx=min(length(stim_type),length(stimOn_times));
    stimOn_times=stimOn_times(1:min_idx);
    quiescent_trials=quiescent_trials(1:min_idx);
    stim_values = unique(stim_type);
    use_align = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);

elseif contains(bonsai_workflow,'stim_wheel')
    % (task)

    if  isfield(trial_events.values,'TaskType')
        curr_tasktype_0=vertcat(trial_events.values.TaskType);
        stim_to_move_idx= curr_tasktype_0(1:n_trials);
        temp_idx=1:length(unique(stim_to_move_idx));
    else
        stim_to_move_idx=ones(n_trials,1);
        temp_idx=1;
    end

    use_align = arrayfun(@(x) stimOn_times(stim_to_move_idx(1:n_trials) == x ), unique(stim_to_move_idx), 'UniformOutput', false);


end


[all_unit_psth_smooth_norm,temp_raster,t]=...
    cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,...
    'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align,'UniformOutput',false);

%%

baseline_bins =cellfun(@(x) x + baseline_t_stim,use_align,'UniformOutput',false);
response_bins =cellfun(@(x) x + response_t_stim,use_align,'UniformOutput',false);
event_bins=cellfun(@(x,y) [x,y], baseline_bins,response_bins,'UniformOutput',false );

spikes_binned_continuous = cellfun(@(x) histcounts2(spike_times_timelite,spike_templates, ...
    reshape(x',[],1),1:size(templates,1)+1),event_bins,'UniformOutput',false );

event_spikes =cellfun(@(x,y) permute(reshape(x(1:2:end,:),2, ...
                    size(y,1),[]),[2,1,3]),spikes_binned_continuous,event_bins,'UniformOutput',false);

event_response =cellfun(@(x) squeeze(mean(diff(x,[],2),1)),event_spikes,'UniformOutput',false);


n_shuff = 1000;
event_response_shuff = cellfun(@(x) cell2mat(arrayfun(@(shuff) ...
    squeeze(mean(diff(ap.shake(x,2),[],2),1)), ...
    1:n_shuff,'uni',false)),event_spikes,'UniformOutput',false);

event_response_rank =cellfun(@(x,y) tiedrank(horzcat(x,y)')',event_response,event_response_shuff,'UniformOutput',false);
event_response_p=cellfun(@(x) x(:,1)./(n_shuff+1),event_response_rank,'UniformOutput',false);


% unit_dots = ap.plot_unit_depthrate(spike_templates,spike_templates,template_depths,probe_areas);
% unit_dots.CData = +([1,0,0].*(event_response_p{3} > 0.95)) + ([0,0,1].*(event_response_p{3}  < 0.05));
ephys_data.psth=all_unit_psth_smooth_norm;
ephys_data.raster=temp_raster;
ephys_data.response_p=event_response_p;


