ephys_data=struct;
fprintf('Processing ephys data... \n')
preload_vars = who;

% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

% baseline_t_stim = [-0.1,0];
% response_t_stim = [0.05,0.15];

baseline_t_stim = [-0.2,0];
response_t_stim = [0,0.2];

baseline_t_move = [-0.3,-0.1];
response_t_move = [-0.1,0.1];

% psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

% (get quiescent trials)
stim_window = [0,0.3];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    (1:length(stimOn_times))');


if contains(bonsai_workflow,'lcr')
    % (vis passive)
    stim_type = vertcat(trial_events.values.TrialStimX);
    min_idx=min(length(stim_type),length(stimOn_times));
    stimOn_times=stimOn_times(1:min_idx);
    quiescent_trials=quiescent_trials(1:min_idx);
    stim_values = unique(stim_type);

    use_align_0 = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);
    labels=arrayfun(@(x) ['stim_'  num2str(x) ] ,stim_values, 'UniformOutput', false);


    use_align_new = [cellfun(@(x) sort(x(1:floor(numel(x)/2))), ...
        cellfun(@(x)x(randperm(numel(x))), use_align_0, 'uni', 0), 'uni', 0); ...
        cellfun(@(x) sort(x(floor(numel(x)/2)+1:end)), ...
        cellfun(@(x)x(randperm(numel(x))), use_align_0, 'uni', 0), 'uni', 0)];
    % use_align=[use_align_0;use_align_new];
    use_align=use_align_0;
    group_idx=labels;


elseif contains(bonsai_workflow,'hml')
    % (aud passive)
    stim_type = vertcat(trial_events.values.StimFrequence);
    min_idx=min(length(stim_type),length(stimOn_times));
    stimOn_times=stimOn_times(1:min_idx);
    quiescent_trials=quiescent_trials(1:min_idx);
    stim_values = unique(stim_type);
    use_align_0 = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);

    labels=arrayfun(@(x) ['stim_'  num2str(x) ] ,stim_values, 'UniformOutput', false);


    use_align_new = [cellfun(@(x) sort(x(1:floor(numel(x)/2))), ...
        cellfun(@(x)x(randperm(numel(x))), use_align_0, 'uni', 0), 'uni', 0); ...
        cellfun(@(x) sort(x(floor(numel(x)/2)+1:end)), ...
        cellfun(@(x)x(randperm(numel(x))), use_align_0, 'uni', 0), 'uni', 0)];
    % use_align=[use_align_0;use_align_new];
    use_align=use_align_0;

    group_idx=labels;
elseif contains(bonsai_workflow,'stim_wheel')
    % (task)
    success=vertcat(trial_events.values.Outcome);

    if  isfield(trial_events.values,'TaskType')
        curr_tasktype_0=vertcat(trial_events.values.TaskType);
        stim_to_move_idx= curr_tasktype_0(1:n_trials);
        temp_idx=1:length(unique(stim_to_move_idx));
    else
        stim_to_move_idx=ones(n_trials,1);
        temp_idx=1;
    end


    group_idx=feval(@(a) cat(1,a{:}), arrayfun(@(s) arrayfun(@(x) stim_to_move_idx(1:n_trials)==x & success(1:n_trials)==s,...
        unique(stim_to_move_idx), 'UniformOutput', false), [1 0], 'UniformOutput', false));

    ds.load_iti_move
    use_align =   [cellfun(@(x) stimOn_times(x),group_idx,'uni',false );...
        cellfun(@(x) stim_move_time(x),group_idx,'uni',false );iti_move_time];


    labels=[...
        arrayfun(@(x) ['stim_'  num2str(x) 'correct'] ,unique(stim_to_move_idx), 'UniformOutput', false);
        arrayfun(@(x) ['stim_'  num2str(x) 'error'] ,unique(stim_to_move_idx), 'UniformOutput', false);
        arrayfun(@(x) ['move_'  num2str(x) 'correct' ] ,unique(stim_to_move_idx), 'UniformOutput', false);
        arrayfun(@(x) ['move_'  num2str(x) 'error' ] ,unique(stim_to_move_idx), 'UniformOutput', false);
        {'iti_move_l'};{'iti_move_r'}];

end

nonempty_idx=cellfun(@(x)  ~isempty(x),use_align,'UniformOutput',true);

[all_unit_psth,temp_raster,t]=...
    ap.psth(spike_times_timelite,use_align,spike_templates,...
    'smoothing',100);
t_baseline = t >= -0.5 &  t <=0;
% (compute baseline as average across all alignments)
psth_baseline = nanmean(all_unit_psth(:,t_baseline,1:2),[2,3]);
all_unit_psth_smooth_norm = (all_unit_psth - psth_baseline)./(psth_baseline + 1);


% [all_unit_psth_smooth_norm,temp_raster,t]=...
%     cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,...
%     'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align,'UniformOutput',false);

%%
if contains(bonsai_workflow,'lcr')|contains(bonsai_workflow,'hml')

    baseline_t= repmat({baseline_t_stim}, length(use_align), 1);
    response_t= repmat({response_t_stim}, length(use_align), 1);

elseif contains(bonsai_workflow,'stim_wheel')


    movelabel=cellfun(@(x) contains(x,'move'),labels,'UniformOutput',true);
    baseline_t=cell(length(use_align),1);
    baseline_t(movelabel)= repmat({baseline_t_move}, sum(movelabel), 1);
    baseline_t(~movelabel)= repmat({baseline_t_stim}, sum(~movelabel), 1);

    response_t=cell(length(use_align),1);
    response_t(movelabel)= repmat({response_t_move}, sum(movelabel), 1);
    response_t(~movelabel)= repmat({response_t_stim}, sum(~movelabel), 1);
end

baseline_bins =cellfun(@(x,y) x + y,baseline_t,use_align,'UniformOutput',false);
response_bins =cellfun(@(x,y) x + y,response_t,use_align,'UniformOutput',false);
event_bins=cellfun(@(x,y) [x,y], baseline_bins,response_bins,'UniformOutput',false );


spikes_binned_continuous=cell(length(use_align),1);
spikes_binned_continuous(nonempty_idx) = cellfun(@(x) histcounts2(spike_times_timelite,spike_templates, ...
    reshape(x',[],1),1:size(templates,1)+1),event_bins(nonempty_idx),'UniformOutput',false );

event_spikes=cell(length(use_align),1);
event_spikes(nonempty_idx) =cellfun(@(x,y) permute(reshape(x(1:2:end,:),2, ...
    size(y,1),[]),[2,1,3]),spikes_binned_continuous(nonempty_idx),event_bins(nonempty_idx),'UniformOutput',false);

event_response=cell(length(use_align),1);
event_response(nonempty_idx) =cellfun(@(x) squeeze(mean(diff(x,[],2),1)),event_spikes(nonempty_idx),'UniformOutput',false);


n_shuff = 1000;
event_response_shuff(nonempty_idx) = cellfun(@(x) cell2mat(arrayfun(@(shuff) ...
    squeeze(mean(diff(ap.shake(x,2),[],2),1)), ...
    1:n_shuff,'uni',false)),event_spikes(nonempty_idx),'UniformOutput',false);


event_response_rank=cell(length(use_align),1);
event_response_rank(nonempty_idx) =cellfun(@(x,y) tiedrank(horzcat(x,y)')',event_response(nonempty_idx),event_response_shuff(nonempty_idx)','UniformOutput',false);

event_response_p=cell(length(use_align),1);
event_response_p(nonempty_idx)=cellfun(@(x) x(:,1)./(n_shuff+1),event_response_rank(nonempty_idx),'UniformOutput',false);


% unit_dots = ap.plot_unit_depthrate(spike_templates,spike_templates,template_depths,probe_areas);
% unit_dots.CData = +([1,0,0].*(event_response_p{3} > 0.95)) + ([0,0,1].*(event_response_p{3}  < 0.05));
ephys_data.psth=all_unit_psth_smooth_norm;
ephys_data.raster=temp_raster;
ephys_data.response_p=event_response_p;
ephys_data.depth=template_tipdist;
ephys_data.labels=labels;
ephys_data.event_idx=group_idx;
ephys_data.raster_t=t;
ephys_data.shank=template_shanks;
ephys_data.probe_histology=probe_histology;
ephys_data.ccf=template_ccf;

clearvars('-except',preload_vars{:});
