%% Exploratory behavior analysis
clear all
animal='AM011'

load_parts = struct;
load_parts.behavior = true;
load_parts.mousecam = true;

ap.load_recording;

%% Align mousecam to event

% (passive)
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';

% stim_x = vertcat(trial_events.values.StimFrequence);
% use_align = stimOn_times(stim_x == 8000  & quiescent_trials);

stim_x = vertcat(trial_events.values.TrialStimX);
use_align = stimOn_times(quiescent_trials & stim_x == 90);

% stim_x = vertcat(trial_events.values.TrialX);
% use_align = stimOn_times(stim_x(1:n_trials) == 90);

% modality = vertcat(trial_events.values(1:n_trials).TaskType);
% use_align = stimOn_times(modality == 1);

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


%% Align wheel to event

align_times = stimOn_times;
% align_times = photodiode_times(1:2:end);
% align_times = stimOn_times(align_category_all == 90);
% align_times = stimOn_times(stim_x == 90);
 % align_times = stim_move_time;
% align_times = iti_fastmove_times;

surround_time = [-10,10];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
pull_times = align_times + surround_time_points;

n_trials = length([trial_events.timestamps.Outcome]);

event_aligned_wheel_vel = interp1(timelite.timestamps, ...
    wheel_velocity,pull_times);
event_aligned_wheel_move = interp1(timelite.timestamps, ...
    +wheel_move,pull_times,'previous');

figure;
nexttile
plot(1:n_trials,stim_to_move,'.k')
% ylim([-0.2 0.2])
xlim([1 n_trials])
xlabel('trials')
ylabel('Reaction time (s)')

nexttile
imagesc(surround_time_points,[],event_aligned_wheel_vel)
colormap(ap.colormap('PWG'))
clim([-2000 2000])
xlim([-0.5 1])
ylabel('trials')
xlabel('time (s)')
nexttile
ap.errorfill(surround_time_points,nanmean(event_aligned_wheel_vel,1),std(event_aligned_wheel_vel,0,1,'omitmissing')./sqrt(size(event_aligned_wheel_vel,1)))
xlim([-0.5 1])
xlabel('time (s)')


%%

if any(contains(fieldnames(trial_events.values),'TaskType'))
    No_tasktype=unique([trial_events.values.TaskType]);
    tasktype=[trial_events.values.TaskType];
else
    tasktype=ones(n_trials,1)
    No_tasktype=1
end
outcome=[trial_events.values.Outcome]

wheel_vel_by_type=feval(@(x)  cat(2,x{:}) ,arrayfun(@(perform) arrayfun(@(type) ...
    event_aligned_wheel_vel(tasktype(1:n_trials)==type&outcome(1:n_trials)==perform,:),...
    No_tasktype,'UniformOutput',false ), [1,0],'UniformOutput',false ))

stim2move_type=arrayfun(@(type) stim_to_move(tasktype(1:n_trials)==type&outcome(1:n_trials)==1),No_tasktype,'UniformOutput',false  )
stim2outcome_type=arrayfun(@(type) stim_to_outcome(tasktype(1:n_trials)==type&outcome(1:n_trials)==1),No_tasktype,'UniformOutput',false  )

figure('Position',[50 50 400 300]);
tiledlayout(2,3)
nexttile;plot(stim2move_type{1},'.k');box off;ylim([-0.1 0.3]);
nexttile;plot(stim2move_type{2},'.k');box off;ylim([-0.1 0.3]);;title('reaction time (s)')
nexttile;ds.make_bar_plot(stim2move_type);

nexttile;plot(stim2outcome_type{1},'.k');box off;ylim([0 5])
nexttile;plot(stim2outcome_type{2},'.k');box off;ylim([0 5]);;title('stim2outcome (s)')
nexttile;ds.make_bar_plot(stim2outcome_type);
% sgtitle(animal)



titlename={'Type1\_correct','Type2\_correct','Type1\_error','Type2\_error'};
figure('Position',[50 50 800 300]);
tiledlayout(2,length(wheel_vel_by_type),'TileIndexing','columnmajor')
for curr_image=1:length(wheel_vel_by_type)
nexttile
imagesc(surround_time_points,[],wheel_vel_by_type{curr_image})
xline(0,'color','r');
% clim(max(abs(clim)).*[-1,1])
clim([-2000 2000])
colormap(gca,ap.colormap('BWR'));
title(titlename{curr_image})
nexttile
plot(surround_time_points,nanmean(wheel_vel_by_type{curr_image},1));
ylim([-2000 2000])
xline(0,'color','r');
end



figure;
subplot(2,2,1);
imagesc(surround_time_points,[],event_aligned_wheel_vel)
xline(0,'color','r');
clim(max(abs(clim)).*[-1,1])
colormap(gca,ap.colormap('BWR'));

subplot(2,2,3);
plot(surround_time_points,nanmean(event_aligned_wheel_vel,1));
xline(0,'color','r');

subplot(2,2,2);
imagesc(surround_time_points,[],event_aligned_wheel_move)
xline(0,'color','r');
ylabel('Velocity');
xlabel('Time from event');

subplot(2,2,4);
plot(surround_time_points,nanmean(event_aligned_wheel_move,1));
xline(0,'color','r');
ylabel('Move prob.');
xlabel('Time from event');



%%
n_outcome = numel(outcome);

% 1) 识别触发 correction 的位置：res==0 且 前一 trial 为 1（把第1位视作前一位为1以触发）
prev = [1; outcome(1:end-1)];             % 将第1位的“前一位”设为1（如果res(1)==0，应该触发）
triggers = find(outcome==0 & prev==1);   % 触发索引 i (表示第 i 次错，correction 从 i+1 开始)

% 2) 计算每个位置向右第一个为1的位置（包含当前位置），用 fillmissing 向右填充索引
nextOne = nan(n_outcome,1);
oneIdx = find(outcome==1);
nextOne(oneIdx) = oneIdx;            % 在为1的位置放置它的索引
nextOne = fillmissing(nextOne,'next'); % 向右填充：每个位置得到“该位或右侧第一个1的索引”
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


%% Behavior across days

% animals = { ...
%     'AM011','AM012','AM014','AM015','AM016','AM017', ...
%     'AM018','AM019','AM021','AM022','AM026','AM029', ...
%     'AP023','AP025'};

animals = {'DS000','DS004','DS014','DS015','DS016'};
animals = {'DS014'};
% Set reaction statistic to use
use_stat = 'mean';
learn_p = 0.05;

% Create master tiled layout
figure('name',sprintf('%s, p < %.2g',use_stat,learn_p));
t = tiledlayout(1,length(animals),'TileSpacing','tight');

% Grab learning day for each mouse
bhv = struct;

for curr_animal_idx = 1:length(animals)

    animal = animals{curr_animal_idx};

    % use_workflow = 'stim_wheel*';
    % use_workflow = 'stim_wheel_right_stage\d';
    use_workflow = 'stim_wheel_right_stage\d_audio_volume';
    % use_workflow = '*audio_volume*';
%     use_workflow = '*audio_frequency*';
%     use_workflow = '*no_change*';
%     use_workflow = '*size*';
%     use_workflow = '*opacity*';
%     use_workflow = '*angle';
%     use_workflow = '*angle_size60';

    recordings = plab.find_recordings(animal,[],use_workflow);

    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_success = nan(length(recordings),2);
    frac_move_day = nan(length(recordings),1);
    frac_move_stimalign = nan(length(recordings),length(surround_time_points));

    rxn_stat_p = nan(length(recordings),1);
    rxn_stat = nan(length(recordings),1);
    rxn_null_stat = nan(length(recordings),1);

    for curr_recording = 1:length(recordings)

        % Grab pre-load vars
        preload_vars = who;

        % Load data
        rec_day = recordings(curr_recording).day;
        rec_time = recordings(curr_recording).recording{end};
        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;

        % Get total trials/water
        n_trials_success(curr_recording,:) = ...
            [length([trial_events.values.Outcome]), ...
            sum([trial_events.values.Outcome])];

        % Align wheel movement to stim onset
        align_times = stimOn_times;
        pull_times = align_times + surround_time_points;

        frac_move_day(curr_recording) = nanmean(wheel_move);

        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');

        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);

        % Get association stat
        % (skip if only a few trials)
        if n_trials < 10
            continue
        end
       
        [rxn_stat_p(curr_recording), ...
            rxn_stat(curr_recording),rxn_null_stat(curr_recording)] = ...
            AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_move,use_stat);

        %%%% CAN SUBSTITUTE: 
        % stim_to_move OR stim_to_lastmove
        %%%%

        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings));

    end

    % Define learned day from reaction stat p-value and reaction time
    learned_day = rxn_stat_p < learn_p;

    relative_day = days(datetime({recordings.day}) - datetime({recordings(1).day}))+1;
    nonrecorded_day = setdiff(1:length(recordings),relative_day);

    % Draw in tiled layout nested in master
    t_animal = tiledlayout(t,4,1);
    t_animal.Layout.Tile = curr_animal_idx;
    title(t_animal,animal);

    nexttile(t_animal);
    yyaxis left; plot(relative_day,n_trials_success);
    ylabel('# trials');
    yyaxis right; plot(relative_day,frac_move_day);
    ylabel('Fraction time moving');
    xlabel('Day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day),'g');
    end

    nexttile(t_animal);
    yyaxis left
    plot(relative_day,rxn_stat)
    set(gca,'YScale','log');
    ylabel(sprintf('Rxn stat: %s',use_stat));
    xlabel('Day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day),'g');
    end

%     yyaxis right
%     prestim_max = max(frac_move_stimalign(:,surround_time_points < 0),[],2);
%     poststim_max = max(frac_move_stimalign(:,surround_time_points > 0),[],2);
%     stim_move_frac_ratio = (poststim_max-prestim_max)./(poststim_max+prestim_max);
%     plot(relative_day,stim_move_frac_ratio);
%     yline(0);
%     ylabel('pre/post move idx');
%     xlabel('Day');

    yyaxis right
    plot(relative_day,(rxn_stat-rxn_null_stat)./(rxn_stat+rxn_null_stat));
    yline(0);
    ylabel(sprintf('Rxn stat idx: %s',use_stat));
    xlabel('Day');

    nexttile(t_animal);
    imagesc(surround_time_points,[],frac_move_stimalign); hold on;
    clim([0,1]);
    colormap(gca,AP_colormap('WK'));
    set(gca,'YTick',1:length(recordings),'YTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    xlabel('Time from stim');
    if any(learned_day)
        plot(0,find(learned_day),'.g')
    end

    nexttile(t_animal); hold on
    set(gca,'ColorOrder',copper(length(recordings)));
    plot(surround_time_points,frac_move_stimalign','linewidth',2);
    xline(0,'color','k');
    ylabel('Fraction moving');
    xlabel('Time from stim');
    if any(learned_day)
        AP_errorfill(surround_time_points,frac_move_stimalign(learned_day,:)', ...
            0.02,[0,1,0],0.1,false); 
    end

    drawnow;

    % Store behavior across animals
    bhv(curr_animal_idx).rxn_stat = rxn_stat;
    bhv(curr_animal_idx).rxn_stat = rxn_null_stat;
    bhv(curr_animal_idx).learned_day = learned_day;

end



















