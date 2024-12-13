%% TESTING BATCH PASSIVE WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\';

%% Create across-day alignments

% Define animal
 animal = 'AP029';
% Create across-day alignments
plab.wf.wf_align([],animal,[],'new_days');
% Get and save VFS maps for animal
plab.wf.retinotopy_vfs_batch(animal);
% Create across-animal alignments

plab.wf.wf_align([],animal,[],'new_animal');

%%
ap.load_recording;
%%
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';

align_times_3 = stimOn_times(quiescent_trials);
if strcmp(bonsai_workflow,'lcr_passive')
    align_category_all = vertcat(trial_events.values.TrialStimX);
elseif strcmp(bonsai_workflow,'hml_passive_audio')
    align_category_all = vertcat(trial_events.values.StimFrequence);
end

align_category = align_category_all(quiescent_trials);

% Align to stim onset
surround_window = [-0.5,1];
surround_samplerate = 35;
t_task = surround_window(1):1/surround_samplerate:surround_window(2);
peri_event_t = reshape(align_times_3,[],1) + reshape(t_task,1,[]);

aligned_v = reshape(interp1(wf_t,wf_V',peri_event_t,'previous'), ...
    length(align_times_3),length(t_task),[]);

align_id = findgroups(align_category);

% 确定 align_id 中的唯一值
unique_values = unique(align_id);

% 初始化一个空的结果数组
aligned_v_avg1 = zeros( numel(unique_values),size(aligned_v, 2), size(aligned_v, 3));

% 遍历每个唯一的值，对每个值进行处理
for i = 1:numel(unique_values)
    idx = align_id == unique_values(i);
    % 检查当前组的大小
    if sum(idx) > 1
        % 如果当前组的大小大于1，则计算平均值
        aligned_v_avg1(i,:,:) = nanmean(aligned_v(find(idx),:,:), 1);
    else
        % 如果当前组的大小等于1，则将对应位置设置为 NaN
        aligned_v_avg1(i,:,:) = aligned_v(find(idx),:,:);
    end
end

% 使用 permute 对结果进行重新排列
aligned_v_avg = permute(aligned_v_avg1, [3, 2, 1]);

% aligned_v_avg = permute(splitapply(@nanmean,aligned_v,align_id),[3,2,1]);

aligned_v_avg_baselined = aligned_v_avg - nanmean(aligned_v_avg(:,t_task < 0,:),2);

% Convert to pixels and package
aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
wf_px = aligned_px_avg;
surround_window = [-0.5,1];
surround_samplerate = 35;
t_task = surround_window(1):1/surround_samplerate:surround_window(2);

ap.imscroll(wf_px,t_task)
ap.wf_draw('ccf','black');
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));


min(wf_px,[],'all')

%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\';
animal='DS007'
ap.load_recording;

 
% Task: align to stim/move/reward
rewarded_trials = logical([trial_events.values.Outcome]');

use_trials = rewarded_trials(1:n_trials);
%     align_times = [ ...
%         stimOn_times(use_trials); ...
%         stim_move_time(use_trials); ...
%         reward_times_task(use_trials)];
align_times_3 = [ ...
    stimOn_times(use_trials); ...
    stim_move_time(use_trials); ...
    reward_times(1:end-(length(reward_times)-sum(rewarded_trials)))];
% align_times = [ ...
%  stimOn_times(use_trials); ...
%  stim_move_time(use_trials); ...
%  reward_times];


align_category = reshape(ones(sum(use_trials),3).*[1,2,3],[],1);
baseline_times = repmat(stimOn_times(use_trials),3,1);



surround_window = [-1,4];
baseline_window = [-0.5,-0.1];

surround_samplerate = 35;

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);

peri_event_t = reshape(align_times_3,[],1) + reshape(t_task,1,[]);
baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);



use_U = wf_U;
use_V = wf_V;
use_wf_t = wf_t;

aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
    length(align_times_3),length(t_task),[]);
aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
    length(baseline_times),length(baseline_t),[]),2);

% 减去baseline数据
aligned_v_baselinesub = aligned_v - aligned_baseline_v;




if ~strcmp(bonsai_workflow,'stim_wheel_right_stage2_mixed_VA')
     
    align_id = findgroups(reshape(align_category,[],1));
            aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
          
aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg);


ap.imscroll(aligned_px_avg,t_task)
ap.wf_draw('ccf','black');
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));


else
     tasktype=cell2mat({trial_events.values.TaskType});
    trials_visual=tasktype(1:n_trials)'==0;
    trials_audio=tasktype(1:n_trials)'==1;


aligned_px_avg_visual =plab.wf.svd2px(use_U, permute(splitapply(@nanmean,aligned_v_baselinesub(repmat(trials_visual(use_trials),3,1),:,:),reshape(ones(sum(trials_visual(use_trials)),3).*[1,2,3],[],1)),[3,2,1]));
aligned_px_avg_audio = plab.wf.svd2px(use_U,permute(splitapply(@nanmean,aligned_v_baselinesub(repmat(trials_audio(use_trials),3,1),:,:),reshape(ones(sum(trials_audio(use_trials)),3).*[1,2,3],[],1)),[3,2,1]));

ap.imscroll(aligned_px_avg_visual,t_task)
ap.wf_draw('ccf','black');
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

ap.imscroll(aligned_px_avg_audio,t_task)
ap.wf_draw('ccf','black');
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
end