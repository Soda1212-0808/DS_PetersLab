% close all
clear all
animal='DS041';
load_probe=1;
rec_day='2026-08-25';

load_parts.ephys=true;
load_parts.ephys_axons=true;


workflows={'lcr_passive_black_square','lcr_passive_white_circle_size40','lcr_passive_grating_size40','lcr_passive_checkerboard','lcr_passive_squareHorizontalStripes'};


multi_align_times=cell(length(workflows),1);
multi_align_groups=cell(length(workflows),1);
multi_spike_timelite=cell(length(workflows),1);
for curr_workflow=1:length(workflows)

    workflow=workflows{curr_workflow};
    temp_recording=plab.find_recordings(animal,rec_day,workflow);
    rec_time=temp_recording.recording{1};
    ap.load_recording


   if contains(bonsai_workflow,{'passive','Image'})
    % (L/C/R passive)
    if isfield(trial_events.values,'TrialStimX')
        align_category_all = vertcat (trial_events.values.TrialStimX);
    elseif isfield(trial_events.values,'StimFrequence')
        align_category_all = vertcat(trial_events.values.StimFrequence);
    elseif isfield(trial_events.values,'PictureID')
        align_category_all = vertcat(trial_events.values.PictureID);
    elseif isfield(trial_events.values,'StimX')
        align_category_all = vertcat(trial_events.values.StimX);

    end
    minlength=min (length(stimOn_times),length(align_category_all));
    stimOn_times=stimOn_times(1:minlength);
    align_times_all = stimOn_times;

    % (get only quiescent trials)
    stim_window = [0,0.5];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times));
    align_times = align_times_all(quiescent_trials);
    align_category = align_category_all(quiescent_trials);
   end
    multi_align_times{curr_workflow}=align_times;
    multi_align_groups{curr_workflow}= align_category;
multi_spike_timelite{curr_workflow}= spike_times_timelite;
end

ds.cellraster_multi(multi_align_times,multi_align_groups,workflows)