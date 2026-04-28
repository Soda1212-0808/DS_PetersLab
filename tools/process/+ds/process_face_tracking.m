%% sleap_data_path

Sleap_Paths={'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek',...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil'};


surround_window = [-0.5,1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);


face_name=sprintf('%s_%s_Recording_%s_mousecam.analysis.h5',animal,rec_day,rec_time);

temp_mousecam_path=cellfun(@(x) fullfile(x,animal,face_name),Sleap_Paths,'UniformOutput',false);
if any(~cellfun(@isfile, temp_mousecam_path))
    sleap_data=[];
    disp(['File not found: ', temp_mousecam_path{(cellfun(@isfile, temp_mousecam_path)==0)}]);
    return;   % 直接停止当前函数/脚本
end

temp_face_tracks=cell(2,1);
temp_node_names=cell(2,1);
validation=struct;
validate_name={'face','pupil'};
for curr_model=1:2
    mousecam_path=fullfile(Sleap_Paths{curr_model},animal,face_name);

    temp_data = h5read(mousecam_path, '/tracks');
    temp_face_tracks{curr_model}  = cat(1, temp_data, ...
        nan(length(mousecam_frame_timelite_idx)-size(temp_data,1),...
        size(temp_data,2),size(temp_data,3)));
    % temp_face_tracks{curr_model} = h5read(mousecam_path, '/tracks');
    occupancy = h5read(mousecam_path, '/track_occupancy');

    validation.(validate_name{curr_model})= sum(occupancy)/length(occupancy)>0.8

    pointScores = h5read(mousecam_path,'/point_scores')'; % frames x nodes
    instanceScores = h5read(mousecam_path, '/instance_scores')'; % transpose to 1 x frames

    temp_node_names{curr_model} = h5read(mousecam_path, '/node_names');
end

face_tracks.nose=temp_face_tracks{1};
% face_tracks.nose_filt=sgolayfilt(temp_face_tracks{2}, 3, 15,[],1);
temp_trace=fillmissing(reshape(face_tracks.nose, size(face_tracks.nose,1), []), "linear");
temp_trace(~isfinite(temp_trace)) = 0;          % 去 NaN / Inf

face_tracks.nose_filt=reshape(lowpass(temp_trace, 4, 30),...
    size(face_tracks.nose));
face_tracks.nose_filt_sav = ...
    reshape(sgolayfilt(reshape(face_tracks.nose_filt, size(face_tracks.nose_filt,1), []), 3, 15),...
    size(face_tracks.nose_filt));
face_tracks.pupil_trace=temp_face_tracks{2};

node_names=cat(1,temp_node_names{:});
[pupil.radius, pupil.center, pupil.diameterPx, pupil.fitRmse, pupil.diameterZ] =...
    ds.pupil_size(temp_face_tracks{2}(:,:,1)',temp_face_tracks{2}(:,:,2)');
pupil.diameterZ_filt=lowpass(fillmissing(pupil.diameterZ, "linear"), 4, 30);
pupil.diameterZ_filt_sav=sgolayfilt(pupil.diameterZ_filt, 3, 15);

pupil.center_filt=lowpass(fillmissing(pupil.center, "linear"), 4, 30);
pupil.center_filt_sav=sgolayfilt(pupil.center_filt, 3, 15);

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
event_aligned_track_position = structfun(@(x) interp1(mousecam_times, ...
    x,pull_times),face_tracks ,'UniformOutput',false );
event_aligned_track_pupil=structfun(@(x) interp1(mousecam_times, x,pull_times) , pupil,'UniformOutput',false);

stim_type =stim_type(1:length(stimOn_times));
sleap_data.face_data=structfun(@(x) arrayfun(@(type) x(stim_type==type,:,:,:), ...
    unique(stim_type),'UniformOutput',false),event_aligned_track_position,'UniformOutput',false);
sleap_data.pupil_data=structfun(@(x) arrayfun(@(type) x(stim_type==type,:,:), ...
    unique(stim_type),'UniformOutput',false),event_aligned_track_pupil,'UniformOutput',false);
sleap_data.validation=validation;
disp('running face tacking successfully');
