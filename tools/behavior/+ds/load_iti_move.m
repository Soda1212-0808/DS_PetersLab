
wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);

wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);

% 找到 wheel 开始转动的索引
start_idx = find(diff([0;wheel_move]) == 1);

% % old version
% time_to_90 = nan(size(start_idx));
% 
% % **优化的计算方式**
% for i = 1:length(start_idx)
%     % 直接找到第一个满足 wheel_position > pos_start + 90 的索引
%     target_idx = find(wheel_position(start_idx(i):length(wheel_position)) < wheel_starts_position(i) - (30/360*1024), 1, 'first');
%     % 计算所需时间 (以 ms 计算)
%     if ~isempty(target_idx)
%         time_to_90(i) = (target_idx - 1) * 1; % 1000Hz 采样率，每点 1ms
%     end
% end

temp_idx= arrayfun(@(s, ws) ...
    (find(wheel_position(s:end) < ws - (30/360*1024), 1, 'first') - 1), ...
    start_idx, wheel_starts_position, 'UniformOutput', false);
time_to_90 = nan(size(start_idx));
time_to_90(~cellfun(@isempty   , temp_idx, 'UniformOutput', true))=cell2mat(temp_idx);


wheel_move_less_than_200ms= time_to_90<200;
wheel_move_over_90=wheel_stops_position-wheel_starts_position<-(30/360*1024);

% (get wheel starts when no stim on screen: not sure this works yet)
iti_move_idx = interp1(photodiode_times, ...
    photodiode_values,wheel_starts,'previous') == 0;
iti_move_time=wheel_starts(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );






      
