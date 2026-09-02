clear all

Path = 'D:\Data process\project_cross_model\face_data\sleap\track_data\aligned_data';

Sleap_Paths={'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek',...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil'};

surround_window = [-0.5,1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);


animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
    'DS000','DS004','DS014','DS015','DS016'};
for curr_animal=1:length(animals)
    animal=animals{curr_animal};

    if isfile(fullfile(Path,[ animal '_face.mat' ]))
    continue;
    end
% animal='AP019';
recordings=plab.find_recordings(animal,[],'*');
recordings=recordings(find(cellfun(@(x) any(x == 1), {recordings.widefield})));

workflow_days={recordings.day}';
% workflow_names=cell(length(workflow_days),1);

% workflows={ 'stim_wheel_right_stage*','lcr_passive','hml_passive_audio'};

workflows={ ['stim_wheel_right_stage1$|' ...
    'stim_wheel_right_stage2$|' ...
    'stim_wheel_right_stage1_opacity$|' ...
    'stim_wheel_right_stage2_opacity$|' ...
    'stim_wheel_right_stage1_angle$|' ...
    'stim_wheel_right_stage2_angle$|' ...
    'stim_wheel_right_stage2_angle_size60$|' ...
    'stim_wheel_right_stage1_size_up$|' ...
    'stim_wheel_right_stage2_size_up$|' ...
    'stim_wheel_right_stage1_audio_volume*$|'...
    'stim_wheel_right_stage2_audio_volume*$|' ...
    'stim_wheel_right_stage1_audio_frequency$|' ...
    'stim_wheel_right_stage2_audio_frequency$|' ...
    'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
    'stim_wheel_right_stage2_mixed_VA$'],...
    'lcr_passive','hml_passive_audio'};

face_data=table( 'Size', [length(workflow_days) 5], 'VariableTypes',{'cell','cell','cell','cell','cell'},...
    'VariableNames', {'day','task_name','task', 'lcr_passive','hml_passive_audio'});

for curr_day=1:length(workflow_days)
    rec_day=workflow_days{curr_day};
    face_data.day(curr_day)={rec_day};


    for curr_workflow=1:length(workflows)
        workflow=workflows{curr_workflow};
        temp_recording=plab.find_recordings(animal,rec_day,workflow);

        if isempty(temp_recording)
            continue;
        end


        if curr_workflow==1
            face_data.task_name(curr_day)=temp_recording.workflow(end);
        end


        rec_time=temp_recording.recording{end};



        file_name=sprintf('%s_%s_Recording_%s_mousecam.analysis.h5',animal,rec_day,rec_time);
        temp_mousecam_path=fullfile(Sleap_Paths{1},animal,file_name);
        if ~isfile(temp_mousecam_path)
            continue;
        end

       

        load_parts = struct;
        load_parts.behavior = true;
        load_parts.mousecam = true;
        ap.load_recording;


        temp_face_tracks=cell(2,1);
        temp_node_names=cell(2,1);
        for curr_model=1:2
        mousecam_path=fullfile(Sleap_Paths{curr_model},animal,file_name);

            temp_data = h5read(mousecam_path, '/tracks');
            temp_face_tracks{curr_model}  = cat(1, temp_data, ...
                nan(length(mousecam_frame_timelite_idx)-size(temp_data,1),...
                size(temp_data,2),size(temp_data,3)));
            % temp_face_tracks{curr_model} = h5read(mousecam_path, '/tracks');
            occupancy = h5read(mousecam_path, '/track_occupancy');
            temp_node_names{curr_model} = h5read(mousecam_path, '/node_names');
        end

        face_tracks=cat(2,temp_face_tracks{:});
        node_names=cat(1,temp_node_names{:});



        switch curr_workflow
            case 1
                if contains(bonsai_workflow ,'mixed')
                    stim_type =vertcat(trial_events.values.TaskType);
                    stimOn_times=stimOn_times(1:length([trial_events.values.Outcome]));
                else
                    stim_type=ones(length(stimOn_times),1);
                end
            case 2
                stim_type = vertcat(trial_events.values.TrialStimX);
            case 3
                stim_type = vertcat(trial_events.values.StimFrequence);
        end

        pull_times = stimOn_times + time_period;


        % event_aligned_track_position = interp1(mousecam_exposeOn_times(mousecam_frame_timelite_idx), ...
        %     face_tracks,pull_times);

         event_aligned_track_position = interp1(mousecam_times, ...
            face_tracks,pull_times);

        stim_type =stim_type(1:length(stimOn_times));

        temp_data=arrayfun(@(type) event_aligned_track_position(stim_type==type,:,:,:), ...
            unique(stim_type),'UniformOutput',false);
        switch curr_workflow
            case 1
                face_data.task(curr_day)={temp_data};
            case 2
                face_data.lcr_passive(curr_day)={temp_data};
            case 3
                face_data.hml_passive_audio(curr_day)={temp_data};
        end

    end
end

save(fullfile(Path,[ animal '_face.mat' ]),'face_data','node_names','-v7.3')
end
%%


%%

use_workflow='lcr_passive'
rec_day='2024-04-02'
recordings=plab.find_recordings(animal,rec_day,use_workflow);
rec_time=recordings.recording{1}

ap.load_recording



Path='D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek';
file_name=sprintf('%s_%s_Recording_%s_mousecam.analysis.h5',animal,rec_day,rec_time)

mousecam_path=fullfile(Path,animal,file_name);


temp_face_tracks = h5read(mousecam_path, '/tracks');
occupancy = h5read(mousecam_path, '/track_occupancy');
temp_node_names = h5read(mousecam_path, '/node_names');


nose_3_track=permute(temp_face_tracks(:,3,:),[1,3,2]);

% figure
% plot(nose_3_track(:,1),nose_3_track(:,2))
% xlim([0 600])
% ylim([0 400])

% mousecam_times


% arrayfun(@(d) interp1(mousecam_times,nose_3_track(:,d),stimOn_times),1:2,'UniformOutput',false)

% mousecam_times>

track_med=nanmedian(nose_3_track);

dist = sqrt( (nose_3_track(:,1) - track_med(1)).^2 + (nose_3_track(:,2) - track_med(2)).^2 );


surround_window = [-0.5,1];
vr = VideoReader(mousecam_fn);
mousecam_framerate = vr.FrameRate;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);

align_times = stimOn_times;
pull_times = align_times + time_period;


  event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);


surround_frames = round(surround_window*mousecam_framerate);

grab_frames = interp1(mousecam_times,1:length(mousecam_times), ...
    stimOn_times,'previous') + surround_frames;


figure;
temp_data=[]
for curr_trial=1:length(stimOn_times)
     hold on
    % temp_track=nose_3_track(grab_frames(curr_trial,1) :grab_frames(curr_trial,2),:);
    % plot(temp_track(:,1),temp_track(:,2))
temp_data(:,curr_trial)=dist(grab_frames(curr_trial,1) :grab_frames(curr_trial,2))
    % plot(dist(grab_frames(curr_trial,1) :grab_frames(curr_trial,2)))
end

stim_window = [0,0.3];

quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';
align_times = stimOn_times(quiescent_trials);


        align_category_all = vertcat(trial_events.values.TrialStimX);

    align_category = align_category_all(quiescent_trials);

align_time=arrayfun(@(id) align_times(align_category==id),unique(align_category_all) ,'UniformOutput',false)

align_time_grab_frames=arrayfun(@(id) grab_frames(align_category==id,:),unique(align_category_all) ,'UniformOutput',false)

temp_data=cellfun(@(x)  cell2mat(arrayfun(@(i) dist(x(i,1):x(i,2)), 1:length(x), 'UniformOutput', false)),...
    align_time_grab_frames   ,'uni',false)


figure;
colors={[0 0 1],[0 0 0],[1 0 0]}
for curr_pass=1:3
    hold on
ap.errorfill(time_period,nanmean(temp_data{curr_pass},2),std(temp_data{curr_pass},0,2,'omitmissing')./sqrt(size(temp_data{curr_pass},2)),colors{curr_pass} )

% ,'Color',colors{curr_pass});
end

