fs = timelite.daq_info(1).rate;
delta90 = (1024/360)/3*90; 

wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);
wheel_move_time=wheel_stops-wheel_starts;

wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);

% 找到 wheel 开始转动的索引
start_idx = find(diff([0;wheel_move]) == 1);

temp_idx_l= arrayfun(@(s, ws) ...
    (find(wheel_position(s:end) < ws - delta90, 1, 'first') - 1)/fs, ...
    start_idx, wheel_starts_position, 'UniformOutput', false);

time_to_90_l = nan(size(start_idx));
time_to_90_l(~cellfun(@isempty   , temp_idx_l, 'UniformOutput', true))=cell2mat(temp_idx_l);
wheel_time_thres_l= time_to_90_l<0.3;
wheel_angle_thres_l=wheel_stops_position-wheel_starts_position<-delta90;

temp_idx_r= arrayfun(@(s, ws) ...
    (find(wheel_position(s:end) < ws + delta90, 1, 'first') - 1)/fs, ...
    start_idx, wheel_starts_position, 'UniformOutput', false);

time_to_90_r = nan(size(start_idx));
time_to_90_r(~cellfun(@isempty   , temp_idx_r, 'UniformOutput', true))=cell2mat(temp_idx_r);
wheel_time_thres_r= time_to_90_r<0.3;
wheel_angle_thres_r=wheel_stops_position-wheel_starts_position>delta90;




wheel_whole_time_thres=wheel_move_time<1;
% (get wheel starts when no stim on screen: not sure this works yet)
iti_move_idx = interp1(photodiode_times, ...
    photodiode_values,wheel_starts,'previous') == 0;

iti_move_time_l=wheel_starts(iti_move_idx & wheel_angle_thres_l & wheel_time_thres_l & wheel_whole_time_thres );
iti_move_time_r=wheel_starts(iti_move_idx & wheel_angle_thres_r & wheel_time_thres_r & wheel_whole_time_thres );
iti_move_time={iti_move_time_l;iti_move_time_r};
all_iti_move_time=wheel_starts(iti_move_idx & wheel_whole_time_thres );





      
