clear all
animal='DS004';
recordings_all_training=plab.find_recordings(animal,[],'stim_wheel_right_stage2_mixed_VA');
% recordings_all_passive=plab.find_recordings(animal,[],'lcr_passive');
recordings_all_passive=plab.find_recordings(animal,[],'hml_passive_audio');


recordings_passive = recordings_all_passive( ...
                cellfun(@any,{recordings_all_passive.ephys}) & ...
                ismember({recordings_all_passive.day},{recordings_all_training.day}));
recordings_training = recordings_all_training( ...
                cellfun(@any,{recordings_all_training.ephys}) & ...
                ismember({recordings_all_training.day},{recordings_all_passive.day}));

curr_day=1;
% rec_day=recordings_passive(curr_day).day;
% rec_time=recordings_passive(curr_day).recording{1};
rec_day=recordings_training(curr_day).day;
rec_time=recordings_training(curr_day).recording{1};
verbose = true;
ap.load_recording;

 
% % Using Bonsai events, we get the X (azimuth) stimulus positions:
% stim_x = vertcat(trial_events.values.TrialStimX);
% 
% % Using Timelite, find the stim times when x = +90 (right screen)
% right_stim_times = stimOn_times(stim_x == 90);
% 
% % Create time bins with a certain width around each stim
% % (define bin size in seconds)
% bin_size = 0.001; 
% % (define the start and end of the window, in seconds)
% psth_window = [-0.5,1];
% % (define the relative bins for the PSTH, edges and centers (to plot))
% psth_bins = psth_window(1):bin_size:psth_window(2); 
% psth_bin_centers = psth_bins(1:end-1)+ diff(psth_bins)/2;
% % (get the bins around every stim: stim is on dim 1, bin is on dim 2)
% stim_bins = right_stim_times + psth_bins; 
% 
% % (select a unit, loop through each stimulus, bin the spikes)
% use_unit = 180;
% use_unit_spikes = spike_times_timelite(spike_templates == use_unit);
% 
% unit_psth = nan(length(right_stim_times),length(psth_bins)-1);
% for curr_trial = 1:length(right_stim_times)
%     % (get the binned spikes for this trial, divide by the bin size to get
%     % spike rate)
%     unit_psth(curr_trial,:) = ...
%         histcounts(use_unit_spikes,stim_bins(curr_trial,:))/bin_size;
% end
% 

% all_counts = cell2mat(arrayfun(@(x) histcounts(use_unit_spikes, stim_bins(x,:)), (1:length(right_stim_times))', 'UniformOutput', false));

%% PSTH - units

% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

% PSTH for all conditions
% (get quiescent trials)
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    (1:length(stimOn_times))');

if contains(bonsai_workflow,'lcr')
    % (vis passive)
    stim_x = vertcat(trial_events.values.TrialStimX);
    align_times = cellfun(@(x) stimOn_times(stim_x(1:length(stimOn_times)) == x & quiescent_trials),num2cell(unique(stim_x)),'uni',false);
elseif contains(bonsai_workflow,'hml')
    % (aud passive)
    stim_x = vertcat(trial_events.values.StimFrequence);
    align_times = cellfun(@(x) stimOn_times(stim_x == x & quiescent_trials),num2cell(unique(stim_x)),'uni',false);
elseif contains(bonsai_workflow,'stim_wheel')
    % (task)
    if contains(bonsai_workflow,'mixed_VA')

        n_trials = length([trial_events.timestamps.Outcome]);
        TaskType= {trial_events.values.TaskType};
        TaskType_idx=  vertcat(TaskType{1:n_trials});
        Outcome= {trial_events.values.Outcome};
        Outcome_idx=  vertcat(Outcome{1:n_trials});

        align_times= {stimOn_times(TaskType_idx==0),stimOn_times(TaskType_idx==1),...
            stim_move_time(TaskType_idx==0),stim_move_time(TaskType_idx==1),...
            reward_times(TaskType_idx(Outcome_idx==1)==0), reward_times(TaskType_idx(Outcome_idx==1)==1)};
        align_times_V= {stimOn_times(TaskType_idx==0),...
            stim_move_time(TaskType_idx==0),...
            reward_times(TaskType_idx(Outcome_idx==1)==0)};
        align_times_A= {stimOn_times(TaskType_idx==1),...
            stim_move_time(TaskType_idx==1),...
            reward_times(TaskType_idx(Outcome_idx==1)==1)};

    else
        align_times = {stimOn_times,stim_move_time,reward_times};
    end
end

  % align_times=align_times_A;

%%%% 2D histogram: do all together, much faster (needs monotonic bins)
n_units = size(templates,1);
unit_psth = nan(n_units,length(t_bins)-1,length(align_times));
for curr_align = 1:length(align_times)
    t_peri_event = align_times{curr_align} + t_bins;

    use_spikes = spike_times_timelite >= min(t_peri_event,[],'all') & ...
        spike_times_timelite <= max(t_peri_event,[],'all');

    spikes_binned_continuous = histcounts2(spike_times_timelite(use_spikes),spike_templates(use_spikes), ...
        reshape(t_peri_event',[],1),1:size(templates,1)+1)./psth_bin_size;

    use_continuous_bins = reshape(padarray(true(size(t_peri_event(:,1:end-1)')),[1,0],false,'post'),[],1);
    spikes_binned = spikes_binned_continuous(use_continuous_bins,:);

    unit_psth(:,:,curr_align) = ...
        nanmean(permute(reshape(spikes_binned, ...
        size(t_peri_event,2)-1,[],size(templates,1)),[3,1,2]),3);
end


smooth_size = 100;
unit_psth_smooth = smoothdata(unit_psth,2,'gaussian',smooth_size);

% Normalize to baseline (t<0 in first alignment)
softnorm = 1;
unit_baseline = nanmean(unit_psth(:,t_bins(2:end) < 0,1),2);
unit_psth_smooth_norm = (unit_psth_smooth-unit_baseline)./(unit_baseline+softnorm);

% Plot depth-sorted
[~,unit_depth_sort_idx] = sort(template_depths);
ap.imscroll(unit_psth_smooth_norm(unit_depth_sort_idx,:,:));
clim([-2,2]);
colormap(ap.colormap('BWR'));

%% Get responsive units

% Set event to get response
% (get quiescent trials)
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    (1:length(stimOn_times))');

if contains(bonsai_workflow,'lcr')
    % (vis passive)
    stim_type = vertcat(trial_events.values.TrialStimX);
    use_align = stimOn_times(stim_type(1:length(stimOn_times)) == 90 & quiescent_trials);
elseif contains(bonsai_workflow,'hml')
    % (aud passive)
    stim_type = vertcat(trial_events.values.StimFrequence);
    use_align = stimOn_times(stim_type == 8000 & quiescent_trials);
elseif contains(bonsai_workflow,'stim_wheel')
    % (task)
    % use_align = stimOn_times(stim_to_move > 0.15);
    use_align{1} = stimOn_times(TaskType_idx==0 & stim_to_move > 0.15);
    use_align{2} = stimOn_times(TaskType_idx==1 & stim_to_move > 0.15);

end

for i=1:2

baseline_t = [-0.2,0];
response_t = [0,0.2];

baseline_bins = use_align{i} + baseline_t;
response_bins = use_align{i} + response_t;

event_bins = [baseline_bins,response_bins];
spikes_binned_continuous = histcounts2(spike_times_timelite,spike_templates, ...
    reshape([baseline_bins,response_bins]',[],1),1:size(templates,1)+1);

event_spikes = permute(reshape(spikes_binned_continuous(1:2:end,:),2, ...
    size(event_bins,1),[]),[2,1,3]);

event_response = squeeze(mean(diff(event_spikes,[],2),1));

n_shuff = 1000;
event_response_shuff = cell2mat(arrayfun(@(shuff) ...
    squeeze(mean(diff(ap.shake(event_spikes,2),[],2),1)), ...
    1:n_shuff,'uni',false));

event_response_rank = tiedrank(horzcat(event_response,event_response_shuff)')';
event_response_p{i} = event_response_rank(:,1)./(n_shuff+1);
end

buffer_event_response_p= cat(2,event_response_p{:})>0.95;
% all(buffer_event_response_p == 1, 2);

unit_dots = ap.plot_unit_depthrate(spike_templates,spike_templates,template_depths,probe_areas);

% Plot responsive units by depth
% unit_dots = ap.plot_unit_depthrate(spike_templates,template_depths,probe_areas);
% unit_dots.CData = +([1,0,0].*(event_response_p > 0.95)) + ([0,0,1].*(event_response_p < 0.05));
unit_dots.CData = +([1,1,0].*(  buffer_event_response_p(:, 1) == 1 & buffer_event_response_p(:, 2) == 1      )) ...
    +([1,0,0].*(buffer_event_response_p(:, 1) == 1 & buffer_event_response_p(:, 2) == 0))...
     +([0,0,1].*(buffer_event_response_p(:, 1) == 0 & buffer_event_response_p(:, 2) == 1));


% Plot rasters of responsive units (from above - if done)
psth_use_t = t_centers >= response_t(1) & t_centers <= response_t(2);
responsive_units{1}=find( buffer_event_response_p(:, 1) == 1 & buffer_event_response_p(:, 2) == 0);
responsive_units{2}=find( buffer_event_response_p(:, 1) == 0 & buffer_event_response_p(:, 2) == 1);
responsive_units{3}=find( buffer_event_response_p(:, 1) == 1 & buffer_event_response_p(:, 2) == 1);
%% 绘制venn图

% 定义集合独占的大小
A_only =length( responsive_units{1});
B_only = length( responsive_units{2});
AB=length(responsive_units{3});
% 使用biovenn函数绘制韦恩图
figure;
[H, S] = venn([A_only+AB, B_only+AB], AB, 'FaceAlpha', 0.5);

% 设置颜色
set(H(1), 'FaceColor', 'b');
set(H(2), 'FaceColor', 'r');

% 添加标签
text(S.ZoneCentroid(1,1), S.ZoneCentroid(1,2), sprintf('%d', A_only), 'HorizontalAlignment', 'center');
text(S.ZoneCentroid(2,1), S.ZoneCentroid(2,2), sprintf('%d', B_only), 'HorizontalAlignment', 'center');
text(S.ZoneCentroid(3,1), S.ZoneCentroid(3,2), sprintf('%d', AB), 'HorizontalAlignment', 'center');

%%
for i=1:3
% responsive_units = find( buffer_event_response_p(:, 1) == 1 & buffer_event_response_p(:, 2) == 1);
% (sort by max amplitude from avg across alignments)
[~,sort_idx] = sort(nanmean(unit_psth_smooth_norm(responsive_units{i},psth_use_t,:),[2,3]));

% % (sort by max time in single alignment)
% sort_align = 2;
% [~,max_t] = max(unit_psth_smooth_norm(responsive_units,:,sort_align),[],2);
% [~,sort_idx] = sort(max_t);

ap.imscroll(unit_psth_smooth_norm(responsive_units{i}(sort_idx),:,:));
colormap(ap.colormap('BWR'));
clim([-2,2]);
end