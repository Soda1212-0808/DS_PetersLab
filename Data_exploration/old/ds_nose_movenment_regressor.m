clear all
animal='DS001';
ap.load_recording


%% Align mousecam to event

% (passive)
stim_window = [0,0.2];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';

stim_x = vertcat(trial_events.values.StimFrequence);
use_align = stimOn_times(stim_x == 8000 & quiescent_trials );

% stim_x = vertcat(trial_events.values.TrialStimX);
% use_align = stimOn_times(stim_x == 90 & quiescent_trials);

% stim_x = vertcat(trial_events.values.StimFrequence);
% use_align = stimOn_times(stim_x == 8000 );

% stim_x = vertcat(trial_events.values.TrialStimX);
% use_align = stimOn_times(stim_x == 90 );



% % stim_x = vertcat(trial_events.values.PictureID);
% % use_align = stimOn_times(stim_x == 2 & quiescent_trials);

% (task)
% use_align = stimOn_times;

% Initialize video reader, get average and average difference
vr = VideoReader(mousecam_fn);
cam_im1 = read(vr,1);

surround_frames = 15;
grab_frames = interp1(mousecam_times,1:length(mousecam_times), ...
    use_align,'previous') + [-1,1].*surround_frames;

cam_align_avg = zeros(size(cam_im1,1),size(cam_im1,2), ...
    surround_frames*2+1);
for curr_align = 2:length(use_align)
    curr_clip = double(squeeze(read(vr,grab_frames(curr_align,:))));
    cam_align_avg = cam_align_avg + curr_clip./length(use_align);
    ap.print_progress_fraction(curr_align,length(use_align));
end

surround_t = (-surround_frames:surround_frames)./vr.FrameRate;
ap.imscroll(cam_align_avg,surround_t)
axis image;

surround_t_diff = surround_t(2:end) + diff(surround_t)/2;
ap.imscroll(abs(diff(cam_align_avg,[],3)),surround_t_diff)
axis image;

%% 画roi 面部
use_cam = mousecam_fn;
use_t = mousecam_times;

% (passive)
%  stim_type = vertcat(trial_events.values.TrialStimX);
% use_align = stimOn_times(stim_type == 90);
% 
% stim_type = vertcat(trial_events.values.StimFrequence);
% use_align = stimOn_times(stim_type == 8000);

% (task)
% use_align = stimOn_times;

surround_frames = 60;

% Initialize video reader, get average and average difference
vr = VideoReader(use_cam);
cam_im1 = read(vr,1);

% Draw ROI
h = figure;imagesc(cam_im1);axis image; 
roi_mask = roipoly;
close(h);
cam_roi_diff_align = nan(length(use_align),surround_frames*2);

% (would probably be way faster and reasonable to just load in the entire
% movie?)
for curr_align = 1:length(use_align)

    % Find closest camera frame to timepoint
    curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
        use_align(curr_align),'nearest');

    % Pull surrounding frames
    curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
    if any(curr_surround_frames < 0) || any(curr_surround_frames > vr.NumFrames)
        continue
    end

    curr_clip_diff_flat = reshape(abs(diff(double(squeeze( ...
        read(vr,curr_surround_frames))),[],3)),[],surround_frames*2);

    cam_roi_diff_align(curr_align,:) = ...
        ((roi_mask(:))'*curr_clip_diff_flat)./sum(roi_mask,'all');

    ap.print_progress_fraction(curr_align,length(use_align));
end


surround_t = [-surround_frames:surround_frames]./vr.FrameRate;

figure;imagesc(surround_t(2:end),[],cam_roi_diff_align);
figure; hold on;
plot(surround_t(2:end),nanmean(cam_roi_diff_align,1));
plot(surround_t(2:end),nanmedian(cam_roi_diff_align,1));



%% regressor


curr_frame=nan(1,length(wf_t));
frame_roi=zeros(1,length(wf_t));

for curr_t=1:length(wf_t)
 curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
        wf_t(curr_t),'nearest');
 if ~isnan(curr_frame)
    curr_clip= reshape(double(squeeze(read(vr,curr_frame))),[],1);
  frame_roi(curr_t)= sum(curr_clip(roi_mask(:)))/sum(roi_mask,'all');
       
 end
end

% Set bins for regressors corresponding to each widefield frame
wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];

regressors={frame_roi};
 t_shifts = {[-5:30]};

% Set cross validation (not necessary if just looking at kernels)
cvfold = 5;

% Do regression
[kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
    ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

% Convert kernels V to pixels
kernels_px = cellfun(@(x) plab.wf.svd2px(wf_U,permute(x,[3,2,1])),{kernels},'uni',false);





% Plot kernels
plot_kernel = 1;
ap.imscroll(kernels_px{plot_kernel},t_shifts{plot_kernel}./35);
axis image;ap.wf_draw('ccf');
 % clim(max(abs(clim)).*[-1,1]);
  colormap(ap.colormap('PWG',[],1.5));



predict_signal_nomove = wf_V-predicted_signals ;

%%
if contains(bonsai_workflow,'passive')

    % LCR passive: align to quiescent stim onset
    stim_window = [0,0.1];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times))';

    align_times = stimOn_times(quiescent_trials);

    
    if isfield(trial_events.values,'TrialStimX')
        align_category_all = vertcat(trial_events.values.TrialStimX);
    elseif isfield(trial_events.values,'StimFrequence')
        align_category_all = vertcat(trial_events.values.StimFrequence);
    end
    align_category = align_category_all(quiescent_trials);

    baseline_times = stimOn_times(quiescent_trials);

end

surround_window = [-1,4];
baseline_window = [-0.5,-0.1];

surround_samplerate = 35;

t = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);

peri_event_t = reshape(align_times,[],1) + reshape(t,1,[]);
baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);

use_U = wf_U;
use_V = predict_signal_nomove;
% use_V = wf_V;

use_wf_t = wf_t;

aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
    length(align_times),length(t),[]);
aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
    length(baseline_times),length(baseline_t),[]),2);

aligned_v_baselinesub = aligned_v - aligned_baseline_v;

align_id = findgroups(reshape(align_category,[],1));

aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
aligned_px_avg = plab.wf.svd2px(use_U,aligned_v_avg);

ap.imscroll(aligned_px_avg,t);
colormap(ap.colormap('PWG'));
clim(prctile(abs(aligned_px_avg(:)),100).*[-1,1]);
clim(0.009.*[-1,1]);

axis image;
set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));
