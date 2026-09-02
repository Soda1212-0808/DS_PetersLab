%% Exploratory behavior analysis
clear all
animal='DS038'

load_parts = struct;
load_parts.behavior = true;
load_parts.mousecam = true;

load_parts.ephys_axons=true;
ap.load_recording;
%%
outcome=[trial_events.values.Outcome];
outcome=outcome(1:n_trials);
No_tasktype=[trial_events.values.TaskType];
No_tasktype=No_tasktype(1:n_trials);
outcome_by_type=arrayfun(@(type) outcome(No_tasktype==type),unique(No_tasktype),'UniformOutput',false);
outcome_by_type_id=arrayfun(@(type) find(No_tasktype==type),unique(No_tasktype),'UniformOutput',false);

figure;
% nexttile
hold on
colors=hsv(length(outcome_by_type_id));
for curr_i=1:length(outcome_by_type_id)
plot(outcome_by_type_id{curr_i},outcome(outcome_by_type_id{curr_i}),'.','MarkerSize',10,'Color',colors(curr_i,:))
% plot(outcome_by_type_id{2},outcome(outcome_by_type_id{2}),'.r','MarkerSize',10)
end
plot(outcome,'Color','k')

legend('Location', 'northeastoutside');
legend boxoff

ylim([-0.5 3])
title ([animal ' ' rec_day])
%% Align wheel to event

align_times = stimOn_times;
% align_times = photodiode_times(1:2:end);
% align_times = stimOn_times(align_category_all == 90);
% align_times = stimOn_times(stim_x == 90);
% align_times = stim_move_time;
% align_times = iti_fastmove_times;

surround_time = [-3,3];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
pull_times = align_times + surround_time_points;

n_trials = length([trial_events.timestamps.Outcome]);

event_aligned_wheel_vel = interp1(timelite.timestamps, ...
    wheel_velocity,pull_times);
event_aligned_wheel_move = interp1(timelite.timestamps, ...
    +wheel_move,pull_times,'previous');

% figure;
% nexttile
% plot(1:n_trials,stim_to_move,'.k')
% % ylim([-0.2 0.2])
% xlim([1 n_trials])
% xlabel('trials')
% ylabel('Reaction time (s)')
% 
% nexttile
% imagesc(surround_time_points,[],event_aligned_wheel_vel)
% colormap(ap.colormap('PWG'))
% clim([-2000 2000])
% xlim([-0.5 1])
% ylabel('trials')
% xlabel('time (s)')
% nexttile
% ap.errorfill(surround_time_points,nanmean(event_aligned_wheel_vel,1),std(event_aligned_wheel_vel,0,1,'omitmissing')./sqrt(size(event_aligned_wheel_vel,1)))
% xlim([-0.5 1])
% xlabel('time (s)')


%

if any(contains(fieldnames(trial_events.values),'TaskType'))
    No_tasktype=unique([trial_events.values.TaskType]);
    tasktype=[trial_events.values.TaskType];
else
    tasktype=ones(n_trials,1)
    No_tasktype=1
end
outcome=[trial_events.values.Outcome];

wheel_vel_by_type=feval(@(x)  cat(2,x{:}) ,arrayfun(@(perform) arrayfun(@(type) ...
    event_aligned_wheel_vel(tasktype(1:n_trials)==type&outcome(1:n_trials)==perform,:),...
    No_tasktype,'UniformOutput',false ), [1,0],'UniformOutput',false ))

stim2move_type=arrayfun(@(type) stim_to_move(tasktype(1:n_trials)==type&outcome(1:n_trials)==1),No_tasktype,'UniformOutput',false  )
stim2outcome_type=arrayfun(@(type) stim_to_outcome(tasktype(1:n_trials)==type&outcome(1:n_trials)==1),No_tasktype,'UniformOutput',false  )

% figure('Position',[50 50 400 300]);
figure
tiledlayout(2,length(No_tasktype)+1)
for curr_type=1:length(No_tasktype)
    nexttile;plot(stim2move_type{curr_type},'.k');box off;ylim([-0.1 0.3]);ylabel('reaction time (s)')
end
nexttile;ds.make_bar_plot(stim2move_type);
ylim([0 0.5])

for curr_type=1:length(No_tasktype)

    nexttile;plot(stim2outcome_type{curr_type},'.k');box off;ylim([0 5]);ylabel('stim2outcome (s)')
end
nexttile;ds.make_bar_plot(stim2outcome_type);
% cellfun(@(x) nanmedian(x), stim2outcome_type,'UniformOutput',false )
ylim([0 3])
 % sgtitle(animal)



% figure('Position',[50 50 800 300]);
figure
tiledlayout(2,length(wheel_vel_by_type),'TileIndexing','columnmajor')
for curr_image=1:length(wheel_vel_by_type)
nexttile
imagesc(surround_time_points,[],wheel_vel_by_type{curr_image})
xline(0,'color','r');
% clim(max(abs(clim)).*[-1,1])
clim([-2000 2000])
colormap(gca,ap.colormap('BWR'));
% title(titlename{curr_image})
nexttile
plot(surround_time_points,nanmean(wheel_vel_by_type{curr_image},1));
ylim([-2000 2000])
xlim([-0.5 1])
xline(0,'color','r');
end


% colors={[1 0 0],[1 0.4 0.4],[0 0 1],[0.4 0.4 1]}
% figure;
% for curr_state=1:4
%     hold on
%     ap.errorfill(surround_time_points,nanmean(wheel_vel_by_type{curr_state},1),...
%         nanstd(wheel_vel_by_type{curr_state},0,1)./sqrt(size(wheel_vel_by_type{curr_state},1)),...
%         colors{curr_state});
% xlim([-0.1 1])
% axis off
% 
% end
% xline(0,'color','k','LineStyle',':');
% 


figure;
nexttile
imagesc(surround_time_points,[],event_aligned_wheel_vel)
xline(0,'color','r');
clim(max(abs(clim)).*[-1,1])
colormap(gca,ap.colormap('BWR'));

nexttile
plot(surround_time_points,nanmean(event_aligned_wheel_vel,1));
xline(0,'color','r');

nexttile
imagesc(surround_time_points,[],event_aligned_wheel_move)
xline(0,'color','r');
ylabel('Velocity');
xlabel('Time from event');

nexttile
plot(surround_time_points,nanmean(event_aligned_wheel_move,1));
xline(0,'color','r');
ylabel('Move prob.');
xlabel('Time from event');


%% 

   [rxn_stat_p_mean([1 unique(tasktype)+2]),...
            stim2move_mad([1 unique(tasktype)+2]),...
            stim2move_mad_null([1 unique(tasktype)+2])] = ...
            ds.stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_lastmove,tasktype,'mad');



%%
n_outcome = numel(outcome);

% 1) 识别触发 correction 的位置：res==0 且 前一 trial 为 1（把第1位视作前一位为1以触发）
prev = [1  outcome(1:end-1)];             % 将第1位的"前一位"设为1（如果res(1)==0，应该触发）
triggers = find(outcome==0 & prev==1);   % 触发索引 i (表示第 i 次错，correction 从 i+1 开始)

% 2) 计算每个位置向右第一个为1的位置（包含当前位置），用 fillmissing 向右填充索引
nextOne = nan(n_outcome,1);
oneIdx = find(outcome==1);
nextOne(oneIdx) = oneIdx;            % 在为1的位置放置它的索引
nextOne = fillmissing(nextOne,'next'); % 向右填充：每个位置得到"该位或右侧第一个1的索引"
% note: 对于位于最后一个1之后的位置，nextOne 会保持 NaN

% 3) 对每个 trigger 构造 correction 区间的 start/end（start = trigger+1）
starts = triggers + 1;
valid = starts <= n_outcome;                  % 去掉超出范围的触发（trigger==n 的情况）
starts = starts(valid);
% end index 是从 start 位置向右第一个1（若没有则到 n）
ends = nextOne(starts);
ends(isnan(ends)) = n_outcome;               % 如果没有后续1，则延伸到序列末尾

% 4) 用差分（prefix-sum trick）把所有区间合并成一个 mask（完全无循环）
if isempty(starts)
    corrMask = false(n_outcome,1);
else
    delta = zeros(n_outcome+1,1);
    delta(starts) = delta(starts) + 1;
    delta(ends+1) = delta(ends+1) - 1;   % ends 可以为 n -> index n+1 有意义
    corrMask = cumsum(delta(1:n_outcome)) > 0;
end

corrIdx = find(corrMask);
normalIdx = ~corrMask;


success=arrayfun(@(type) sum(tasktype(normalIdx(1:n_trials))==type&outcome(normalIdx(1:n_trials))==1)/sum(tasktype(normalIdx(1:n_trials))==type),No_tasktype,'UniformOutput',true  )







%% face
ds.process_face_tracking


temp_center=sleap_data.pupil_data.center_filt_sav

temp_trace=cellfun(@(x)   vecnorm(diff(nanmean(x,1),1,2),2,3),temp_center,'UniformOutput',false )

figure;
hold on
cellfun(@(x) plot(x)   ,temp_trace,'UniformOutput',false)
legend


figure;
tiledlayout(5,1)
nexttile
plot(timelite.timestamps  ,photodiode_trace)
xlim([1000 1400])
axis off
nexttile
plot(timelite.timestamps  ,photodiode_trace)
xlim([1050 1450])
axis off

nexttile
plot(mousecam_times,pupil.center_filt_sav(:,1))
xlim([1000 1400])
axis off

nexttile
plot(mousecam_times,pupil.diameterZ_filt_sav(:,1))
xlim([1000 1400])
axis off

nexttile
plot(timelite.timestamps  ,wheel_velocity)
xlim([1050 1450])
axis off



%% Align mousecam to event

% (passive)
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';

% stim_x = vertcat(trial_events.values.StimFrequence);
% use_align = stimOn_times(stim_x == 8000  & quiescent_trials);

% stim_x = vertcat(trial_events.values.TrialStimX);
% use_align = stimOn_times(quiescent_trials & stim_x == 90);

% stim_x = vertcat(trial_events.values.TrialX);
% use_align = stimOn_times(stim_x(1:n_trials) == 90);

modality = vertcat(trial_events.values(1:n_trials).TaskType);
use_align = stimOn_times(modality == 1);

% use_align = reward_times;

 % use_align = stimOn_times;

% use_align = stimOff_times(trial_opacity == 1);

% stim_x = vertcat(trial_events.values.PictureID);
% use_align = stimOn_times(stim_x == 2 & quiescent_trials);

% use_align = stim_center_times(stim_x==90);

% % (task)
% use_align = stimOn_times;
% use_align = stim_move_time;

% Initialize video reader, get average and average difference
vr = VideoReader(mousecam_fn);
cam_im1 = read(vr,1);

surround_times = [-0.2,1];

mousecam_framerate = vr.FrameRate;
surround_frames = round(surround_times*mousecam_framerate);
grab_frames = interp1(mousecam_times,1:length(mousecam_times), ...
    use_align,'previous') + surround_frames;

grab_frames_use = find(~any(isnan(grab_frames),2) & all(grab_frames>0,2));

cam_align_avg = zeros(size(cam_im1,1),size(cam_im1,2), ...
    diff(surround_frames)+1);
for curr_align = grab_frames_use'
    curr_clip = double(squeeze(read(vr,grab_frames(curr_align,:))));
    cam_align_avg = cam_align_avg + curr_clip./length(grab_frames_use);
    ap.print_progress_fraction(curr_align,length(use_align));
end

surround_t = (surround_frames(1):surround_frames(2))./vr.FrameRate;
ap.imscroll(cam_align_avg,surround_t)
axis image;

surround_t_diff = surround_t(2:end) + diff(surround_t)/2;
ap.imscroll(abs(diff(cam_align_avg,[],3)),surround_t_diff)
axis image;



%% Align mousecam ROI to event

use_cam = mousecam_fn;
use_t = mousecam_times;

% (passive)
% stim_type = vertcat(trial_events.values.TrialStimX);
stim_type = vertcat(trial_events.values.StimFrequence);
use_align = stimOn_times(stim_type == 8000);

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

    AP_print_progress_fraction(curr_align,length(use_align));
end


surround_t = [-surround_frames:surround_frames]./vr.FrameRate;

figure;imagesc(surround_t(2:end),[],cam_roi_diff_align);
figure; hold on;
plot(surround_t(2:end),nanmean(cam_roi_diff_align,1));
plot(surround_t(2:end),nanmedian(cam_roi_diff_align,1));


















