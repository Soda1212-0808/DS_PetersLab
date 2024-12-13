
animal='DS001'
ds.mc_align([],animal,[],'new_days');

% % plab.find_recordings
% % mc_align(im_unaligned,animal,day,align_type,master_align)


clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
% animals={'DS002','DS003','DS004','DS005','DS006','DS007','DS010','DS011','DS013','DS014','DS015','DS016'};
animals={'DS001','DS007','DS010','DS011','AP018','AP019','AP020','AP021','AP022','DS000','DS003','DS004','DS006','DS013','DS014','DS015','DS016'};
%DS011 'DS013','AP022'
for curr_animal=1:length(animals)
   
    animal=animals{curr_animal};
    fprintf('%s\n', ['start  ' animal ]);

for ss=1:2
    main_preload_vars = who;
    if ss==1
        passive_workflow = 'hml_passive_audio';

    elseif ss==2  passive_workflow = 'lcr_passive';

    end

    fprintf('%s\n', ['start saving ' passive_workflow ' files...']);

    % use_workflow = {'stim_wheel_right_stage2_mixed_VA$|stim_wheel_right_frequency_stage2_mixed_VA$'};
    training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$';

    % training_workflow = {'stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$'};
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);


    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings = recordings_passive( ...
        cellfun(@any,{recordings_passive.widefield}) & ...
        ~[recordings_passive.ephys] );
    workflow_day={recordings.day}';
    % recordings2 = recordings_training( ...
    %     cellfun(@any,{recordings_training.widefield}) & ...
    %     ~[recordings_training.ephys] & ...
    %     ismember({recordings_training.day},{recordings_passive.day}));
    % 
    
    camera_all=cell(size(recordings,2),3);
    camera_roi=cell(size(recordings,2),1);
    camera_image=cell(size(recordings,2),3);
    roi_mask=[];
    surround_t=[];
    surround_t2=[];

    surround_frames2 = 15;
    cam_im1=[];
    %% 对一天的图像进行roi绘制
    preload_vars = who;
    rec_day = recordings(1).day;
    rec_time = recordings(1).recording{end};
    load_parts.mousecam = true;
    load_parts.widefield = false;
    load_parts.widefield_master = false;
    ap.load_recording;

    % % Draw ROI
    vr = VideoReader(mousecam_fn);
    % cam_im1 = ds.mc_align(squeeze(read(vr,1)),animal,rec_day,'day_only');
    % 
    % 
    % h = figure;imagesc(cam_im1);axis image;
    % roi_mask = roipoly;
    % close(h);
    surround_frames = 60;
    surround_t = [-surround_frames:surround_frames]./vr.FrameRate;

   clearvars('-except',preload_vars{:});



    for curr_recording =1: length(recordings)

    fprintf('%s\n', ['start day ' num2str(curr_recording) ',' num2str(recordings(curr_recording).day)]);

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings(curr_recording).day;
        rec_time = recordings(curr_recording).recording{end};
        if ~recordings(curr_recording).widefield(end)
            continue
        end

        try
            load_parts.mousecam = true;
            load_parts.widefield = false;
            load_parts.widefield_master = false;
            ap.load_recording;
        catch me
            warning('%s %s %s: load error, skipping \n >> %s', ...
                animal,rec_day,rec_time,me.message)
            continue
        end



        %%  对camera图像进行ROI处理
        use_cam = mousecam_fn;
        use_t = mousecam_times;

        % (passive)
        stim_window = [0,0.1];
        quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
            timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
            timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
            1:length(stimOn_times))';

        if ss==2
            stim_x = vertcat(trial_events.values.TrialStimX);
            use_align{1} = stimOn_times(stim_x == -90 & quiescent_trials);
            use_align{2} = stimOn_times(stim_x == 0 & quiescent_trials);
            use_align{3} = stimOn_times(stim_x == 90 & quiescent_trials);

        elseif ss==1

            stim_x = vertcat(trial_events.values.StimFrequence);
            use_align{1} = stimOn_times(stim_x == 4000 & quiescent_trials);
            use_align{2} = stimOn_times(stim_x == 8000 & quiescent_trials);
            use_align{3} = stimOn_times(stim_x == 12000 & quiescent_trials);
        end

        % (task)
        % use_align = stimOn_times;

        surround_frames = 60;

        % Initialize video reader, get average and average difference
        try
        vr = VideoReader(use_cam);
        catch ME
        warning(['wrong camera file at ', rec_day,':', ME.message] );
             % camera_all{curr_recording,curr_type}=[];

        continue;
        end



       
         cam_im1 = read(vr,1);
        for curr_type=1:3

            fprintf('%s\n', ['start type: ' num2str(curr_type) ]);

            curr_use_align=use_align{curr_type}(1:end);

            cam_roi_diff_align = nan(length(curr_use_align),surround_frames*2);
            cam_all_diff_align=cell(length(curr_use_align),1);
            % (would probably be way faster and reasonable to just load in the entire
            % movie?)
            for curr_align = 1:length(curr_use_align)

                % Find closest camera frame to timepoint
                curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
                    curr_use_align(curr_align),'nearest');

                % Pull surrounding frames
                curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
                if any(curr_surround_frames < 0) || any(curr_surround_frames > vr.NumFrames)
                    continue
                end

                curr_clip_diff_flat = reshape(abs(diff(double(...
                    squeeze(read(vr,curr_surround_frames))),[],3)),[],surround_frames*2);

                %对齐图像
                curr_clip_diff_flat = reshape(abs(diff(double(...
                    ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')      ...
                    ),[],3)),[],surround_frames*2);

                % cam_roi_diff_align(curr_align,:) = ...
                %     ((roi_mask(:))'*curr_clip_diff_flat)./sum(roi_mask,'all');


                 cam_all_diff_align{curr_align}=abs(diff(double(ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')),[],3));

                ap.print_progress_fraction(curr_align,length(curr_use_align));
            end

             % camera_roi{curr_recording,curr_type}=cam_roi_diff_align;
             camera_all{curr_recording,curr_type}=mean(cat(4,cam_all_diff_align{:}),4);
        end

        
        %  cam_all_diff_align=cell(length(stimOn_times),1);
        % 
        % for curr_align = 1:length(stimOn_times)
        % 
        %         % Find closest camera frame to timepoint
        %         curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
        %             stimOn_times(curr_align),'nearest');
        % 
        %         % Pull surrounding frames
        %         curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
        %         if any(curr_surround_frames < 0) || any(curr_surround_frames > vr.NumFrames)
        %             continue
        %         end
        % 
        %         curr_clip_diff_flat = reshape(abs(diff(double(...
        %             squeeze(read(vr,curr_surround_frames))),[],3)),[],surround_frames*2);
        % 
        %         %对齐图像
        %         curr_clip_diff_flat = reshape(abs(diff(double(...
        %             ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')      ...
        %             ),[],3)),[],surround_frames*2);
        % 
        %         % cam_roi_diff_align(curr_align,:) = ...
        %         %     ((roi_mask(:))'*curr_clip_diff_flat)./sum(roi_mask,'all');
        % 
        % 
        %          cam_all_diff_align{curr_align}=abs(diff(double(ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')),[],3));
        % 
        %         ap.print_progress_fraction(curr_align,length(stimOn_times));
        %     end
        %                   camera_roi{curr_recording}=cam_all_diff_align;

            clearvars('-except',preload_vars{:});


    end

    save([Path 'mat_data\' animal '_' passive_workflow '_face.mat' ],'camera_roi','workflow_day', '-v7.3')


end
        
end
