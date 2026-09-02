%% Exploratory ephys analysis
% close all
clear all
animal='DS025';
% rec_day='2025-12-17';
rec_day='2026-01-06';

%% correlation across 2 probes
use_workflow =...
    {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
    'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

recordings = plab.find_recordings(animal,rec_day,use_workflow);
rec_time=recordings.recording{1};

binned_spikes_depth_all=cell(2,1);
for curr_probe=1:2
    load_probe=curr_probe;


    ap.load_recording

    % Get correlation of MUA in sliding windows
    depth_corr_window = 50; % MUA window in microns
    depth_corr_window_spacing = 20; % MUA window spacing in microns

    max_depths = 3840; % (hardcode, sometimes kilosort drops channels)

    depth_corr_bins = [0:depth_corr_window_spacing:(max_depths-depth_corr_window); ...
        (0:depth_corr_window_spacing:(max_depths-depth_corr_window))+depth_corr_window];
    depth_corr_bin_centers = depth_corr_bins(1,:) + diff(depth_corr_bins,[],1)/2;

    spike_binning_t = 0.005; % seconds
    spike_binning_t_edges = nanmin(spike_times_timelite):spike_binning_t:nanmax(spike_times_timelite);
    spike_binning_t_edges=spike_binning_t_edges(1:10000);
    binned_spikes_depth = zeros(size(depth_corr_bins,2),length(spike_binning_t_edges)-1);
    for curr_depth = 1:size(depth_corr_bins,2)
        curr_depth_templates_idx = ...
            find(template_depths >= depth_corr_bins(1,curr_depth) & ...
            template_depths < depth_corr_bins(2,curr_depth));

        binned_spikes_depth(curr_depth,:) = histcounts(spike_times_timelite( ...
            ismember(spike_templates,curr_depth_templates_idx)),spike_binning_t_edges);
    end
    binned_spikes_depth_all{curr_probe}=binned_spikes_depth;
end


min_l=min(cellfun(@(x) size(x,2) ,binned_spikes_depth_all,'UniformOutput',true  ))
binned_spikes_depth_all= cellfun(@(x) x(:,1:min_l),binned_spikes_depth_all,'UniformOutput',false )

lag_length=100;
lag_bin=1;

lag_t=spike_binning_t*(-lag_length:lag_bin:lag_length);

temp_data1= arrayfun(@(id) binned_spikes_depth_all{1}(:,200+id:end-200),-lag_length:lag_bin:lag_length,'uni',false);
temp_data2=arrayfun(@(id)  binned_spikes_depth_all{2}(:,200:end-200-id),-lag_length:lag_bin:lag_length,'uni',false);

mua_corr1=cellfun(@(a,b) corrcoef([a;b]'),temp_data1,temp_data2,'uni',false);

ap.imscroll(cat(3,mua_corr1{:}), lag_t)
axis image;
clim([-1,1].*0.2);
colormap(ap.colormap('BWR'))



% figure;
% imagesc(mua_corr1);
% axis image;
% clim([-1,1].*0.5);
% colormap(ap.colormap('BWR'))
figure;
plot(lag_t,roi.trace)
hold on
xline(0)

%%  Rastermap
use_workflow =...
    {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
    'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

recordings = plab.find_recordings(animal,rec_day,use_workflow);
rec_time=recordings.recording{1};

binned_spikes_all=cell(2,1);
template_depths_all=cell(2,1);
probe_id_all=cell(2,1);
for curr_probe=1:2
    load_probe=curr_probe;

    ap.load_recording
    % Get correlation of MUA in sliding windows
    depth_corr_window = 50; % MUA window in microns
    depth_corr_window_spacing = 20; % MUA window spacing in microns

    max_depths = 3840; % (hardcode, sometimes kilosort drops channels)

    depth_corr_bins = [0:depth_corr_window_spacing:(max_depths-depth_corr_window); ...
        (0:depth_corr_window_spacing:(max_depths-depth_corr_window))+depth_corr_window];
    depth_corr_bin_centers = depth_corr_bins(1,:) + diff(depth_corr_bins,[],1)/2;

    spike_binning_t = 0.05; % seconds
    spike_binning_t_edges = nanmin(spike_times_timelite):spike_binning_t:nanmax(spike_times_timelite);
    cell_id=unique(spike_templates);

    binned_spikes =feval(@(a) cat(1,a{:})  , arrayfun(@(id)histcounts(spike_times_timelite( ...
        ismember(spike_templates,id)),spike_binning_t_edges),cell_id,'UniformOutput',false));

    binned_spikes_all{curr_probe}=binned_spikes;
    template_depths_all{curr_probe}=template_depths;
    probe_id_all{curr_probe}=curr_probe*ones(length(template_depths),1);
end
min_length=min(cellfun(@(a) size(a,2), binned_spikes_all,'UniformOutput',true ));
binned_spikes_all=cellfun(@(x)   x(:,1:min_length),binned_spikes_all,'UniformOutput',false);
% spks=double(binned_spikes);
spks=double(cat(1,binned_spikes_all{:}));
% xpos=-double(cat(1,template_depths_all{:}));
% ypos=double([ones(length(template_depths_all{1}),1) ;2*ones(length(template_depths_all{2}),1)]);

% spks = single(spks);
% xpos = double(xpos(:));   % 强制列向量 (N,1)
% ypos = double(ypos(:));

probe_id= double(cat(1,probe_id_all{:}));



% x = np.array(xpos).reshape(py.int(-1));
% y = np.array(ypos).reshape(py.int(-1));

% np.savez_compressed( ...
%     'C:/Users/dsong/Documents/GitHub/data2.npz', ...
%     spks = spks, ...
%     xpos = x, ...
%     ypos = y ...
%     );

np = py.importlib.import_module('numpy');
dataNdArray = py.numpy.array(spks);
pyrun("from rastermap import Rastermap") %load interpreter, import main function
rmModel = pyrun("model = Rastermap(locality=0, time_lag_window=0).fit(spks)", "model", spks=dataNdArray);
sortIdx = int16(py.memoryview(rmModel.isort.data)) + 1; %back to MATLAB array, 1-indexing



%%   task
use_workflow =...
    {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
    'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

recordings = plab.find_recordings(animal,rec_day,use_workflow);
rec_time=recordings.recording{1};

psth_all=cell(2,1);
for curr_probe=1:2

    load_probe=curr_probe;
    ap.load_recording

    task_types=[trial_events.values.TaskType];
    task_types=task_types(1:n_trials);
    task_outcome=[trial_events.values.Outcome];
    stimOn_times=stimOn_times(1:n_trials);

    % align_times=arrayfun(@(b) arrayfun(@(a) stimOn_times(task_types==a & task_outcome==b) ,0:3,'uni',false),0:1,'uni',false)
    %  align_times=cat(2,align_times{:});
    align_times= arrayfun(@(a) stimOn_times(task_types==a & task_outcome==1) ,0:3,'uni',false)

    [psth_all{curr_probe},~,unit_psth_t] = ...
        ap.psth(spike_times_timelite,align_times,spike_templates, ...
        'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);

end

psth_all=cat(1,psth_all{:});
figure
tiledlayout(1,17)
nexttile 

imagesc(probe_id(sortIdx))
task_name={'VL','VR','AL','AR'}
for curr_state=1:4

    nexttile
    imagesc(unit_psth_t,[],psth_all(sortIdx',:,curr_state))
    clim([0 5])
    xlim([-0.1 0.5])
    colormap(ap.colormap(['WK']));
    title(task_name{curr_state})

end

% passive
psth_passive=cell(4,1);
for curr_passive=1:4
    passive_workflow={'lcr_passive_grating_size40','lcr_passive_checkerboard','lcr_passive_squareHorizontalStripes','hml_passive_audio_Freq2'};
    recordings = plab.find_recordings(animal,rec_day,passive_workflow{curr_passive});
    rec_time=recordings.recording{1};

    for curr_probe=1:2

        load_probe=curr_probe;
        ap.load_recording

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

        end

        [psth_passive{curr_passive}{curr_probe},~,unit_psth_t] = ...
            ap.psth(spike_times_timelite,align_times,spike_templates, ...
            'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);

    end
end

psth_passive=cellfun(@(x)  cat(1,x{:}),psth_passive,'UniformOutput',false);
passive_name={'circle L','circle M','circle R';...
    'square L','square M','square R';...
    'striape L','striape M','striape R';...
    '4k','8k','12k'};


for curr_passive=1:4
    for curr_stim=1:3
        nexttile

        imagesc(unit_psth_t,[],psth_passive{curr_passive}(sortIdx',:,curr_stim))
        clim([0 1])
        xlim([-0.1 0.5])
        colormap(ap.colormap(['WK']));
        title(passive_name{curr_passive,curr_stim})
    end
end
sgtitle([animal ' ' rec_day])