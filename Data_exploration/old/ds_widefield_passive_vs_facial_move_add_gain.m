
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_passive = surround_window(1):1/surround_samplerate:surround_window(2);

t_kernels=[-5:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);

surround_frames=60;
surround_t = [-surround_frames:surround_frames]./30;
period_passive_face=find(surround_t>0&surround_t<0.2);

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');

% animals={'DS002','DS003','DS004','DS005','DS006','DS007','DS010','DS011','DS013','DS014','DS015','DS016'};
animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
%AP021
training_workflow = ['stim_wheel_right_stage1$|stim_wheel_right_stage2$|' ...
    'stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage2_audio_volume$|' ...
    'stim_wheel_right_stage2_mixed_VA$'];


for ss=1:2
    if ss==1
        passive_workflow = 'hml_passive_audio';
    elseif ss==2  passive_workflow = 'lcr_passive';
    end
    fprintf('%s\n', ['start saving ' passive_workflow ' files...']);

    for curr_animal=1:length(animals)

        main_preload_vars = who;
        animal=animals{curr_animal};
        fprintf('%s\n', ['start  ' animal ]);
        load([Path '\face_data\' animal '_face_roi.mat']);
        data=load([Path '\mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat']);

        camera_task_gain=nan(length(data.workflow_day),1);

        for curr_recording =1: length(data.workflow_day)

            fprintf('%s\n', ['start day ' num2str(curr_recording) ',' data.workflow_day{curr_recording}]);

            recordings= plab.find_recordings(animal,data.workflow_day{curr_recording},training_workflow);

            if isempty(recordings)
                continue
            end

            % Grab pre-load vars
            preload_vars = who;
            % Load data
            rec_day = recordings.day;
            rec_time = recordings.recording{end};

            try
                load_parts.mousecam = true;
                load_parts.widefield = false;
                load_parts.widefield_master =false;
                ap.load_recording;
            catch me
                warning('%s %s %s: load error, skipping \n >> %s', ...
                    animal,rec_day,rec_time,me.message)
                continue
            end


           
            %%  对camera图像进行ROI处理
            use_cam = mousecam_fn;
            use_t = mousecam_times;


            % Initialize video reader, get average and average difference
            try
                vr = VideoReader(use_cam);
            catch ME
                warning(['wrong camera file at ', rec_day,':', ME.message] );
                % camera_all{curr_recording,curr_type}=[];

                continue;
            end

            use_align = reward_times;


            %% facial图像分析
            cam_roi_diff_align = nan(length(use_align),surround_frames*2);
            for curr_align = 2:length(use_align)

                % Find closest camera frame to timepoint
                curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
                    use_align(curr_align),'nearest');


                % Pull surrounding frames
                curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
                if any(curr_surround_frames < 0) || any(curr_surround_frames > vr.NumFrames)||any(isnan(curr_surround_frames))
                    continue
                end

                % curr_clip_diff_flat = reshape(abs(diff(double(...
                %     squeeze(read(vr,curr_surround_frames))),[],3)),[],surround_frames*2);

                %对齐图像
                curr_clip_diff_flat = reshape(abs(diff(double(...
                    ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')      ...
                    ),[],3)),[],surround_frames*2);

                % cam_roi_diff_align(curr_align,:) = ...
                %     ((roi_mask(:))'*curr_clip_diff_flat)./sum(roi_mask,'all');

                cam_roi_diff_align(curr_align,:) = ...
                    ((roi_mask_face(:))'*curr_clip_diff_flat)./sum(roi_mask_face,'all');

                % cam_all_diff_align{curr_align}=abs(diff(double(ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')),[],3));

                ap.print_progress_fraction(curr_align,length(use_align));
            end


            camera_task_gain(curr_recording)=mean(cam_roi_diff_align(:,61:75),'all','omitnan')-mean(cam_roi_diff_align(:,31:40),'all','omitnan');


            clearvars('-except',preload_vars{:});


        end


        % save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'camera_plot','image_plot','image_plot_nose','image_plot_barrel','trial_type','trial_state','trial_state_05','workflow_day','learned_day','workflow_type', '-v7.3')
        save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'camera_task_gain','-append')

        clearvars('-except',main_preload_vars{:});

    end

end


