%% sleap_data_path

Sleap_Paths={'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek',...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil'};


surround_window = [-0.5,1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);


face_name=sprintf('%s_%s_Recording_%s_mousecam.analysis.h5',animal,rec_day,rec_time);

temp_mousecam_path=fullfile(Sleap_Paths{1},animal,face_name);
if ~isfile(temp_mousecam_path)
    sleap_data=[];
    disp(['File not found: ', temp_mousecam_path]);
    return;   % 直接停止当前函数/脚本
end

temp_face_tracks=cell(2,1);
temp_node_names=cell(2,1);
for curr_model=1:2
    mousecam_path=fullfile(Sleap_Paths{curr_model},animal,face_name);

    temp_data = h5read(mousecam_path, '/tracks');
    temp_face_tracks{curr_model}  = cat(1, temp_data, ...
        nan(length(mousecam_frame_timelite_idx)-size(temp_data,1),...
        size(temp_data,2),size(temp_data,3)));
    % temp_face_tracks{curr_model} = h5read(mousecam_path, '/tracks');
    occupancy = h5read(mousecam_path, '/track_occupancy');
    
    pointScores = h5read(mousecam_path,'/point_scores')'; % frames x nodes
  instanceScores = h5read(mousecam_path, '/instance_scores')'; % transpose to 1 x frames

    temp_node_names{curr_model} = h5read(mousecam_path, '/node_names');
end


% temp_face_tracks{2}
% figure;
% for curr_node=1:8
%     hold on
% plot(temp_face_tracks{2}(:,curr_node,1),temp_face_tracks{2}(:,curr_node,2))
% 
% end

% X=temp_face_tracks{2}(:,:,1)';
% Y=temp_face_tracks{2}(:,:,2)';
% figure;
% plot(Y')

face_tracks=cat(2,temp_face_tracks{:});
node_names=cat(1,temp_node_names{:});
[pupil.radius, pupil.center, pupil.diameterPx, pupil.fitRmse, pupil.diameterZ] =...
    ds.pupil_size(temp_face_tracks{2}(:,:,1)',temp_face_tracks{2}(:,:,2)');
pupil.diameterZ_filt=lowpass(fillmissing(pupil.diameterZ, "linear"), 4, 30);
pupil.diameterZ_filt_sav=sgolayfilt(pupil.diameterZ_filt, 3, 15);

if contains(bonsai_workflow, 'stim_wheel_right')
    if contains(bonsai_workflow, 'mixed')
        stim_type =vertcat(trial_events.values.TaskType);
        stimOn_times=stimOn_times(1:length([trial_events.values.Outcome]));
    else
        stim_type=ones(length(stimOn_times),1);
    end
elseif contains(bonsai_workflow, 'lcr_passive')
    stim_type = vertcat(trial_events.values.TrialStimX);
elseif contains(bonsai_workflow, 'hml_passive_audio')
    stim_type = vertcat(trial_events.values.StimFrequence);
end


pull_times = stimOn_times + time_period;


% event_aligned_track_position = interp1(mousecam_exposeOn_times(mousecam_frame_timelite_idx), ...
%     face_tracks,pull_times);

event_aligned_track_position = interp1(mousecam_times, ...
    face_tracks,pull_times);
% event_aligned_track_diameter = interp1(mousecam_times, ...
%     pupil.diameterZ,pull_times);

event_aligned_track_pupil=structfun(@(x) interp1(mousecam_times, x,pull_times)    , pupil,'UniformOutput',false);

stim_type =stim_type(1:length(stimOn_times));


sleap_data.face_data=arrayfun(@(type) event_aligned_track_position(stim_type==type,:,:,:), ...
    unique(stim_type),'UniformOutput',false);
sleap_data.pupil_data=structfun(@(x) arrayfun(@(type) x(stim_type==type,:,:), ...
    unique(stim_type),'UniformOutput',false),event_aligned_track_pupil,'UniformOutput',false);



disp('running face tacking successfully');
