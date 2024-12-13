clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';

animals={'DS010','DS007','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013','DS014','DS015','DS016'}
for curr_animal=1:length(animals)

animal=animals{curr_animal};
recordings_all_training=plab.find_recordings(animal,[],'stim_wheel_right_stage2_mixed_VA');
recordings_all_passive_visual=plab.find_recordings(animal,[],'lcr_passive');
recordings_all_passive_audio=plab.find_recordings(animal,[],'hml_passive_audio');


recordings_passive_visual = recordings_all_passive_visual( ...
                cellfun(@any,{recordings_all_passive_visual.ephys}) & ...
                ismember({recordings_all_passive_visual.day},{recordings_all_training.day}));

recordings_passive_audio = recordings_all_passive_audio( ...
                cellfun(@any,{recordings_all_passive_audio.ephys}) & ...
                ismember({recordings_all_passive_audio.day},{recordings_all_training.day}));

recordings_training = recordings_all_training( ...
                cellfun(@any,{recordings_all_training.ephys}) & ...
                ismember({recordings_all_training.day},{recordings_all_passive_audio.day}));

probe_positions=cell(4,1);
for curr_day=1:4
    day_probe={'post str','ant str','post str','ant str'};

    if length(recordings_training)<curr_day
        continue
    end

for curr_task=1:2
    if  curr_task==1
        rec_day=recordings_passive_visual(curr_day).day;
        rec_time=recordings_passive_visual(curr_day).recording{1};
    else
        rec_day=recordings_passive_audio(curr_day).day;
        rec_time=recordings_passive_audio(curr_day).recording{1};
    end

verbose = true;
ap.load_recording;

%% PSTH - units
idx = find(strcmp(probe_areas{1, 1}  .safe_name, 'Caudoputamen'));
depth=probe_areas{1}.probe_depth(idx,:);
% Plot responsive units by depth
template_sort=find(any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2));





 
% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t = [-0.2,0];
response_t = [0,0.2];
psth_use_t = t_centers >= response_t(1) & t_centers <= response_t(2);

% Get responsive units

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
    use_align = stimOn_times(stim_type(1:length(stimOn_times)) == 8000 & quiescent_trials);
elseif contains(bonsai_workflow,'stim_wheel')
    % (task)
    % use_align = stimOn_times(stim_to_move > 0.15);
    use_align{1} = stimOn_times(TaskType_idx==0 & stim_to_move > 0.15);
    use_align{2} = stimOn_times(TaskType_idx==1 & stim_to_move > 0.15);

end

all_unit_psth_smooth_norm=...
    ap.ephys_psth(spike_times_timelite,use_align,spike_templates, ...
    'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);

unit_psth_smooth_norm{curr_task} = all_unit_psth_smooth_norm(template_sort,:);



baseline_bins = use_align + baseline_t;
response_bins = use_align + response_t;

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
all_event_response_p=event_response_rank(:,1)./(n_shuff+1);

event_response_p{curr_task} = all_event_response_p(template_sort);

responsive_units{curr_task} = find(event_response_p{curr_task} < 0.05 | event_response_p{curr_task} > 0.95);

end

probe_positions{curr_day}=probe_nte.probe_positions_ccf{1};

unit_dots = ap.plot_unit_depthrate(spike_templates(ismember(spike_templates, template_sort)),template_depths,probe_areas);
  % unit_dots = ap.plot_unit_depthrate(spike_templates,template_depths,probe_areas);

unit_dots.CData = +([0,0,1].*(event_response_p{1} > 0.95)) + ([0.5,0.5,1].*(event_response_p{1} < 0.05))...
     +([1,0,0].*(event_response_p{2} > 0.95))+([1,0.5,0.5].*(event_response_p{2} <0.05))...
      +([0,1,0].*((event_response_p{2} > 0.95)& (event_response_p{1} > 0.95)))+([0.5,1,0.5].*((event_response_p{1} <0.05)&(event_response_p{2} <0.05)));


saveas(gcf,[Path 'figures\summary\probe of ' animal ' in day ' num2str(curr_day)], 'jpg');

% % (sort by max time in single alignment)
% sort_align = 1;
% [~,max_t] = max(unit_psth_smooth_norm(responsive_units,:,sort_align),[],2);
% [~,sort_idx] = sort(max_t);
figure('Position',[50 50 600 800])
titles={'visual passive','auditory passive'}
for i=1:2
    nexttile
    [~,sort_idx] = sort(nanmean(unit_psth_smooth_norm{i}(responsive_units{i},psth_use_t),[2,3]));

imagesc(t_centers,[],unit_psth_smooth_norm{i}(responsive_units{i}(sort_idx),:));
colormap(ap.colormap('BWR'));
clim([-2,2]);
title(titles{i})


end



plot_mean_visual_up=nanmean(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & ~(event_response_p{2} > 0.95)),:),1);
plot_sem_visual_up=std(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & ~(event_response_p{2} > 0.95)),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & ~(event_response_p{2} > 0.95)),:),1));
plot_mean_visual_co_up=nanmean(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & event_response_p{2} > 0.95),:),1);
plot_sem_visual_co_up=std(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & event_response_p{2} > 0.95),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{1} > 0.95 & event_response_p{2} > 0.95),:),1));

plot_mean_audio_up=nanmean(unit_psth_smooth_norm{2}( find( event_response_p{2} > 0.95 & ~(event_response_p{1} > 0.95)),:),1);
plot_sem_audio_up=std(unit_psth_smooth_norm{2}( find( event_response_p{2} > 0.95 & ~(event_response_p{1} > 0.95)),:),1)/sqrt(size(unit_psth_smooth_norm{2}( find( event_response_p{2} > 0.95 & ~(event_response_p{1} > 0.95)),:),1));
plot_mean_audio_co_up=nanmean(unit_psth_smooth_norm{2}( find( event_response_p{2} > 0.95 & event_response_p{1} > 0.95),:),1);
plot_sem_audio_co_up=std(unit_psth_smooth_norm{2}( find( event_response_p{2} > 0.95 & event_response_p{1} > 0.95),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{2} > 0.95 & event_response_p{1} > 0.95),:),1));

plot_mean_visual_down=nanmean(unit_psth_smooth_norm{1}( find( event_response_p{1} <0.05 & ~(event_response_p{2} <0.05)),:),1);
plot_sem_visual_down=std(unit_psth_smooth_norm{1}( find( event_response_p{1} <0.05 & ~(event_response_p{2} <0.05)),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{1} <0.05 & ~(event_response_p{2}  <0.05)),:),1));
plot_mean_visual_co_down=nanmean(unit_psth_smooth_norm{1}( find( event_response_p{1}<0.05 & event_response_p{2} <0.05),:),1);
plot_sem_visual_co_down=std(unit_psth_smooth_norm{1}( find( event_response_p{1}  <0.05 & event_response_p{2} <0.05),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{1} <0.05 & event_response_p{2} <0.05),:),1));

plot_mean_audio_down=nanmean(unit_psth_smooth_norm{2}( find( event_response_p{2}  <0.05 & ~(event_response_p{1} <0.05)),:),1);
plot_sem_audio_down=std(unit_psth_smooth_norm{2}( find( event_response_p{2} <0.05 & ~(event_response_p{1} <0.05)),:),1)/sqrt(size(unit_psth_smooth_norm{2}( find( event_response_p{2} <0.05 & ~(event_response_p{1} <0.05)),:),1));
plot_mean_audio_co_down=nanmean(unit_psth_smooth_norm{2}( find( event_response_p{2} <0.05 & event_response_p{1} <0.05),:),1);
plot_sem_audio_co_down=std(unit_psth_smooth_norm{2}( find( event_response_p{2} <0.05 & event_response_p{1} <0.05),:),1)/sqrt(size(unit_psth_smooth_norm{1}( find( event_response_p{2}<0.05 & event_response_p{1} <0.05),:),1));



max_scale_up=max([plot_mean_visual_up plot_mean_visual_co_up plot_mean_audio_up plot_mean_audio_co_up]);
min_scale_up=min([plot_mean_visual_up plot_mean_visual_co_up plot_mean_audio_up plot_mean_audio_co_up]);
max_scale_down=max([plot_mean_visual_down plot_mean_visual_co_down plot_mean_audio_down plot_mean_audio_co_down]);
min_scale_down=min([plot_mean_visual_down plot_mean_visual_co_down plot_mean_audio_down plot_mean_audio_co_down]);

nexttile
hold on
ap.errorfill([t_centers 1],plot_mean_visual_up,plot_sem_visual_up,[0 0 1],0.1,0.5);
ap.errorfill([t_centers 1],plot_mean_visual_co_up,plot_sem_visual_co_up,[0 0 0],0.1,0.5);
ylim([min_scale_up max_scale_up])
% ylabel('z-score')
xlabel('time (s)')

nexttile    
hold on
ap.errorfill([t_centers 1],plot_mean_audio_up,plot_sem_audio_up,[1 0 0],0.1,0.5);
ap.errorfill([t_centers 1],plot_mean_audio_co_up,plot_sem_audio_co_up,[0 0 0],0.1,0.5);
ylim([min_scale_up max_scale_up])
% ylabel('z-score')
xlabel('time (s)')


nexttile
hold on
ap.errorfill([t_centers 1],plot_mean_visual_down,plot_sem_visual_down,[0 0 1],0.1,0.5);
ap.errorfill([t_centers 1],plot_mean_visual_co_down,plot_sem_visual_co_down,[0 0 0],0.1,0.5);
if ~isnan(min_scale_down)
ylim([min_scale_down max_scale_down])
end
% ylabel('z-score')
xlabel('time (s)')

nexttile    
hold on
ap.errorfill([t_centers 1],plot_mean_audio_down,plot_sem_audio_down,[1 0 0],0.1,0.5);
ap.errorfill([t_centers 1],plot_mean_audio_co_down,plot_sem_audio_co_down,[0 0 0],0.1,0.5);
if ~isnan(min_scale_down)
ylim([min_scale_down max_scale_down])
end
% ylabel('z-score')
xlabel('time (s)')




% 绘制venn图
% 定义集合独占的大小
titles2={'inhibited','activated'};

for ii=1:2
    if ii==1
A_only =length( find( event_response_p{1} <0.05 & ~(event_response_p{2} <0.05)));
B_only = length( find( ~(event_response_p{1} <0.05) & event_response_p{2}<0.05));
AB=length(find( event_response_p{1} <0.05 & event_response_p{2}<0.05));
    else
        A_only =length( find( event_response_p{1} > 0.95 & ~(event_response_p{2} > 0.95)));
B_only = length( find( ~(event_response_p{1} > 0.95) & event_response_p{2}> 0.95));
AB=length(find( event_response_p{1} > 0.95 & event_response_p{2}> 0.95));
    end
% 使用biovenn函数绘制韦恩图
nexttile
[H, S] = venn([A_only+AB, B_only+AB], AB, 'FaceAlpha', 0.5);
axis image off
title(titles2{ii})
% 设置颜色
set(H(1), 'FaceColor', 'b');
set(H(2), 'FaceColor', 'r');

% 添加标签
text(S.ZoneCentroid(1,1), S.ZoneCentroid(1,2), sprintf('%d', A_only), 'HorizontalAlignment', 'center');
text(S.ZoneCentroid(2,1), S.ZoneCentroid(2,2), sprintf('%d', B_only), 'HorizontalAlignment', 'center');
text(S.ZoneCentroid(3,1), S.ZoneCentroid(3,2), sprintf('%d', AB), 'HorizontalAlignment', 'center');
end

sgtitle([animal ' in day ' num2str(curr_day) ' of ' day_probe{curr_day}])

saveas(gcf,[Path 'figures\summary\psth of ' animal ' in ' num2str(curr_day)], 'jpg');

% close all
end



% 创建三维散点图
figure;  % 创建新图形窗口
for i=1:length(probe_positions)
    plot3(probe_positions{i}(1, :), probe_positions{i}(2, :),probe_positions{i}(3, :))
     hold on

end
% cellfun( @(x) plot3(x(1, :), x(2, :),x(3, :)),probe_positions,'UniformOutput',false); % 'o' 表示绘制点
grid on;  % 打开网格
xlabel('X');
ylabel('Y');
zlabel('Z');
title('3D Points from 3x2 Matrix');
axis equal
xlim([0 1000])
ylim([0 1000])
zlim([0 1000])
end
