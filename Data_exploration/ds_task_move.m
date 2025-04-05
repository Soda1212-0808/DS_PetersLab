clear all
clc
animal='DS007';
rec_day='2024-07-09';
rec_time='0812';
 surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

load_parts = struct;
load_parts.behavior = true;

ap.load_recording;



% Align wheel movement to stim onset
stim_move_pull_times = stim_move_time + surround_time_points;

event_aligned_wheel_vel = interp1(timelite.timestamps, ...
    wheel_velocity,stim_move_pull_times);

[~,idx_move]=sort(stim_to_move,'ascend')
event_aligned_wheel_vel=event_aligned_wheel_vel(idx_move,:);

event_aligned_wheel_position = interp1(timelite.timestamps, ...
    wheel_position,stim_move_pull_times,'previous');
event_aligned_wheel_position_relative=(event_aligned_wheel_position-event_aligned_wheel_position(:,500))/1024*360;


wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);

wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);


%

% 找到 wheel 开始转动的索引
start_idx = find(diff([0;wheel_move]) == 1);
% 预分配时间数组 (提高效率)
time_to_90 = nan(size(start_idx));
% **优化的计算方式**
for i = 1:length(start_idx)
    % 直接找到第一个满足 wheel_position > pos_start + 90 的索引
    target_idx = find(wheel_position(start_idx(i):length(wheel_position)) < wheel_starts_position(i) - (30/360*1024), 1, 'first');
    % 计算所需时间 (以 ms 计算)
    if ~isempty(target_idx)
        time_to_90(i) = (target_idx - 1) * 1; % 1000Hz 采样率，每点 1ms
    end
end
wheel_move_less_than_200ms= time_to_90<200;

wheel_move_over_90=wheel_stops_position-wheel_starts_position<-(30/360*1024);

% (get wheel starts when no stim on screen: not sure this works yet)
iti_move_idx = interp1(photodiode_times, ...
    photodiode_values,wheel_starts,'previous') == 0;

movement_align = wheel_starts(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );


movement_times = movement_align + surround_time_points;

event_aligned_wheel_velocity_iti = interp1(timelite.timestamps, ...
    wheel_velocity,movement_times,'previous');

%% 
figure
% a0=nexttile
% imagesc(event_aligned_wheel_position_relative)
% clim([-100 100])
%   colormap(a0,ap.colormap('BWR'));
% colorbar

% a1=nexttile
% imagesc(event_aligned_wheel_move)
% clim([0 1])
%   colormap(a1,ap.colormap('WR'));
% colorbar

a2=nexttile
imagesc(event_aligned_wheel_vel)
clim([-2000 2000])
    colormap(a2,ap.colormap('BWR'));
colorbar

a3=nexttile
imagesc(event_aligned_wheel_velocity_iti)
clim([-2000 2000])
  colormap(a3,ap.colormap('BWR'));
colorbar

R=corr(event_aligned_wheel_vel',event_aligned_wheel_velocity_iti')


[max_corr, max_idx] = max(R, [], 2); 

nexttile
plot(nanmean(event_aligned_wheel_vel,1))
hold on
plot(nanmean(event_aligned_wheel_velocity_iti,1))
hold on 
 % plot(event_aligned_wheel_velocity_iti(239,:))