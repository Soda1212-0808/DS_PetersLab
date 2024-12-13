
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
%DS000 

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

        % use_workflow = {'stim_wheel_right_stage2_mixed_VA$|stim_wheel_right_frequency_stage2_mixed_VA$'};
        % training_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$';
        training_workflow = ['stim_wheel_right_stage1$|stim_wheel_right_stage2$|' ...
                'stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage2_audio_volume$|' ...
                'stim_wheel_right_stage2_mixed_VA$'];

        % training_workflow = {'stim_wheel_right_stage1$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$'};
        recordings_passive = plab.find_recordings(animal,[],passive_workflow);
        recordings_training = plab.find_recordings(animal,[],training_workflow);
        
        recordings =[recordings_passive(1:3) recordings_passive( ...
                cellfun(@any,{recordings_passive.widefield}) & ...
                ~[recordings_passive.ephys] & ...
                ismember({recordings_passive.day},{recordings_training.day}))];


        recordings2 = recordings_training( ...
            cellfun(@any,{recordings_training.widefield}) & ...
            ~[recordings_training.ephys] & ...
            ismember({recordings_training.day},{recordings_passive.day}));

            % if     exist ([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ])==2
            %     continue
            % end


        workflow_day={recordings.day}';
        camera_plot=cell(size(recordings,2),1);
        image_plot=cell(size(recordings,2),1);
        image_plot_nose=cell(size(recordings,2),1);

        image_plot_barrel=cell(size(recordings,2),1);
        trial_state_05=cell(size(recordings,2),1);

        trial_state=cell(size(recordings,2),1);
        trial_type=cell(size(recordings,2),1);
        workflow_type= zeros(length(recordings),1);
        n_trials_water = nan(length(recordings),2);
        frac_move_day = nan(length(recordings),1);
        success = nan(length(recordings),1);
        rxn_med = nan(length(recordings),1);
        frac_move_stimalign = nan(length(recordings),length(surround_time_points));
        rxn_stat_p = nan(length(recordings),1);


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
        load_parts.widefield = true;
        load_parts.widefield_master =true;
        ap.load_recording;

        % % Draw ROI
        vr = VideoReader(mousecam_fn);
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
                load_parts.widefield = true;
                load_parts.widefield_master = true;
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


            % Initialize video reader, get average and average difference
            try
                vr = VideoReader(use_cam);
            catch ME
                warning(['wrong camera file at ', rec_day,':', ME.message] );
                % camera_all{curr_recording,curr_type}=[];

                continue;
            end

            %% facial图像分析
            cam_all_diff_align=cell(length(stimOn_times),1);
            for curr_align = 1:length(stimOn_times)

                % Find closest camera frame to timepoint
                curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
                    stimOn_times(curr_align),'nearest');

                %%debug 可能需要删掉
                if curr_frame==60
                    curr_frame=61;
                end

                % Pull surrounding frames
                curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
                if any(curr_surround_frames < 0) || any(curr_surround_frames > vr.NumFrames)||any(isnan(curr_surround_frames))
                    continue
                end

                %对齐图像
                cam_all_diff_align{curr_align} = (roi_mask_face(:))'* reshape(abs(diff(double(...
                    ds.mc_align(squeeze(read(vr,curr_surround_frames)),animal,rec_day,'day_only')      ...
                    ),[],3)),[],surround_frames*2)./sum(roi_mask_face,'all');

               
                ap.print_progress_fraction(curr_align,length(stimOn_times));
            end

            cell_matrix_with_nan = cellfun(@(x) ifelse(isempty(x), zeros(1,120), x), cam_all_diff_align, 'UniformOutput', false);
            % camera_buffer3=reshape(cell_matrix_with_nan,size(idx_buff));
            camera_buffer4= permute(cat(3,cell_matrix_with_nan{:}),[2,3,1]);
            % camera_buffer4= cellfun(@(x) mean(x(period_passive_face)),camera_buffer3,'UniformOutput',true);
            
            camera_plot{curr_recording}=camera_buffer4;
            %% 对widefield imaging进行分析
            % align_times = stimOn_times(quiescent_trials);
            if strcmp(passive_workflow,'lcr_passive')
                align_category_all = vertcat(trial_events.values.TrialStimX);
            elseif strcmp(passive_workflow,'hml_passive_audio')
                align_category_all = vertcat(trial_events.values.StimFrequence);
            end

            % align_category = align_category_all(quiescent_trials);
            %%all_trials
            peri_event_t_all= reshape(stimOn_times,[],1) + reshape(t_passive,1,[]);
            aligned_v_all = permute((reshape(interp1(wf_t,wf_V',peri_event_t_all,'previous'), length(stimOn_times),length(t_passive),[])), [3, 2, 1]);
            aligned_v_all_baslined = aligned_v_all-nanmean(aligned_v_all(:,t_passive < 0,:),2);

            load(master_U_fn);
            wf_px_all=  plab.wf.svd2px(U_master,aligned_v_all_baslined);
            redata=reshape(wf_px_all,size(wf_px_all,1)*size(wf_px_all,2),size(wf_px_all,3),size(wf_px_all,4));
              
            roi_data_peri_av=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);
           
            image_plot{curr_recording}=roi_data_peri_av;

            roi_data_peri_av_nose=permute(mean(redata(roi1(7).data.mask(:),:,:),1),[2,3,1]);
            image_plot_nose{curr_recording}=roi_data_peri_av_nose;

            roi_data_peri_av_barrel=permute(mean(redata(roi1(7).data.mask(:),:,:),1),[2,3,1]);
            image_plot_barrel{curr_recording}=roi_data_peri_av_nose;

            trial_state{curr_recording}=quiescent_trials;
            trial_type{curr_recording}=align_category_all;

            
            trial_state_05{curr_recording}=quiescent_trials;

            clearvars('-except',preload_vars{:});



            %% 分析行为学
            preload_vars_behavior=who;

            task_day_index = find(strcmp({recordings2.day}, recordings(curr_recording).day));
            if isempty(task_day_index)
                continue
            end
            rec_day=recordings(curr_recording).day;
            clear time
            if length(recordings2(task_day_index).index)>1
                for mm=1:length(recordings2(task_day_index).index)
                    rec_time = recordings2(task_day_index).recording{mm};
                    % verbose = true;
                    % ap.load_timelite

                    timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                    timelite = load(timelite_fn);
                    time(mm)=length(timelite.timestamps);
                end
                [~,index_real]=max(time);
            else index_real=1;
            end
            rec_time=recordings2(task_day_index).recording{index_real};

            if strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_audio_volume')...
                    || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')...
                    || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                    || strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1_audio_volume')
                workflow_type(curr_recording)=2;
            elseif  strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2')...
                    ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage1')
                workflow_type(curr_recording)=1;
            elseif  strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                    ||strcmp(recordings2(task_day_index).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type(curr_recording)=3;

            end


                    load_parts = struct;
                    load_parts.behavior = true;
                    ap.load_recording;

                    if workflow_type(curr_recording)==1|workflow_type(curr_recording)==2

                        % Get total trials/water
                        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                            sum(([trial_events.values.Outcome] == 1)*6)];

                        % Get median stim-outcome time
                        n_trials = length([trial_events.timestamps.Outcome]);
                        rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));

                        % Align wheel movement to stim onset
                        align_times = stimOn_times;
                        pull_times = align_times + surround_time_points;

                        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;
                        frac_move_day(curr_recording) = nanmean(wheel_move);

                        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
                            wheel_velocity,pull_times);
                        event_aligned_wheel_move = interp1(timelite.timestamps, ...
                            +wheel_move,pull_times,'previous');

                        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);

                        % Get association stat
                        rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
                            stimOn_times,trial_events,stim_to_move);


                    elseif workflow_type(curr_recording)==3

                        % Get total trials/water
                        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
                            sum(([trial_events.values.Outcome] == 1)*6)];


                        % Get median stim-outcome time
                        n_trials = length([trial_events.timestamps.Outcome]);
                        reactivation_time=seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
                            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}));
                        % Get task type
                        tasktype=cell2mat({trial_events.values.TaskType});
                        visual_time=reactivation_time(find(tasktype(1:n_trials)==0));
                        audio_time=reactivation_time(find(tasktype(1:n_trials)==1));

                        n_trials_water_V(curr_recording)=length(visual_time);
                        n_trials_water_A(curr_recording)=length(audio_time);



                        % Align wheel movement to stim onset
                        align_times = stimOn_times;
                        pull_times = align_times + surround_time_points;

                        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;
                        frac_move_day(curr_recording) = nanmean(wheel_move);
                        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
                            wheel_velocity,pull_times);
                        event_aligned_wheel_move = interp1(timelite.timestamps, ...
                            +wheel_move,pull_times,'previous');

                        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);
                        frac_move_stimalign_V(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==0,:),1);
                        frac_move_stimalign_A(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==1,:),1);
                        % Get association stat
                        buffer_p = AP_stimwheel_association_pvalue2( ...
                            stimOn_times,trial_events,stim_to_move,tasktype);

                        if ss==1
                            rxn_stat_p(curr_recording)=buffer_p(3);
                            rxn_med(curr_recording) = median(audio_time);
                        elseif ss==2
                            rxn_stat_p(curr_recording)=buffer_p(2);
                            rxn_med(curr_recording) = median(visual_time);
                        end
                    end

                    % Clear vars except pre-load for next loop
                    clearvars('-except',preload_vars_behavior{:});
                    ap.print_progress_fraction(curr_recording,length(recordings2));


        end
         
         learned_day= rxn_stat_p < 0.05 & rxn_med < 2;
         save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'camera_plot','image_plot','image_plot_nose','image_plot_barrel','trial_type','trial_state','trial_state_05','workflow_day','learned_day','workflow_type', '-v7.3')
         % save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'trial_state_05','-append', '-v7.3')

        clearvars('-except',main_preload_vars{:});

    end



end
