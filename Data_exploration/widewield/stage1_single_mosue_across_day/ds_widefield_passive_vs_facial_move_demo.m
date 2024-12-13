
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
surround_window = [-0.5,1];
surround_samplerate = 35;
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
animals = {'DS001'};
%DS000

for ss=1
    if ss==1
        passive_workflow = 'hml_passive_audio';
    elseif ss==2  passive_workflow = 'lcr_passive';
    end
    fprintf('%s\n', ['start saving ' passive_workflow ' files...']);

    for curr_animal=1:length(animals)

        main_preload_vars = who;
        animal=animals{curr_animal};
        fprintf('%s\n', ['start  ' animal ]);

        if  exist ([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ])==2
            continue;
        end

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

         % recordings =[ recordings_passive( ...
         %        cellfun(@any,{recordings_passive.widefield}) & ...
         %        ~[recordings_passive.ephys] & ...
         %        ismember({recordings_passive.day},{recordings_training.day}))];


        recordings2 = recordings_training( ...
            cellfun(@any,{recordings_training.widefield}) & ...
            ~[recordings_training.ephys] & ...
            ismember({recordings_training.day},{recordings_passive.day}));

        % if     exist ([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ])==2
        %     continue
        % end


        workflow_day={recordings.day}';
        camera_plot=cell(size(recordings,2),1);
        camera_plot_iti=cell(size(recordings,2),1);

        image_plot=cell(size(recordings,2),1);
        image_plot_nose=cell(size(recordings,2),1);

        image_plot_barrel=cell(size(recordings,2),1);

        image_plot_iti=cell(size(recordings,2),1);
        image_plot_nose_iti=cell(size(recordings,2),1);
        image_plot_barrel_iti=cell(size(recordings,2),1);



        trial_state_05=cell(size(recordings,2),1);

        trial_state_01=cell(size(recordings,2),1);
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


        for curr_recording =3: length(recordings)

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
            quiescent_trials_1 = arrayfun(@(x) ~any(wheel_move(...
                timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
                timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
                1:length(stimOn_times))';

            stim_window = [0,0.5];
            quiescent_trials_2 = arrayfun(@(x) ~any(wheel_move(...
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

            %% stimOn facial图像分析
            % cam_all_diff_align=repmat({[]},  length(stimOn_times),1);
            cam_all_diff_align=cell( length(stimOff_times),1);

            for curr_align = 1:length(stimOff_times)

                % Find closest camera frame to timepoint
                curr_frame = interp1(mousecam_times,1:length(mousecam_times), ...
                    stimOn_times(curr_align),'nearest');


                % Pull surrounding frames
                curr_surround_frames = curr_frame + [-surround_frames,surround_frames];
                if any(curr_surround_frames <= 0) || any(curr_surround_frames > vr.NumFrames)||any(isnan(curr_surround_frames))
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


            % ITI  facial图像分析
            cam_all_diff_align_iti=repmat({NaN},  length(stimOff_times)-1,1);

            iti_frame=  [ arrayfun(@(x) interp1(mousecam_times,1:length(mousecam_times),stimOff_times(x),'nearest'), 1:length(stimOn_times)-1);...
                arrayfun(@(x) interp1(mousecam_times,1:length(mousecam_times),stimOn_times(x),'nearest'), 2:length(stimOn_times))];

            for curr_align = 1:length(stimOff_times)-1

                % curr_frame1 = interp1(mousecam_times,1:length(mousecam_times), ...
                %     stimOn_times(curr_align+1),'nearest');
                % curr_frame2 = interp1(mousecam_times,1:length(mousecam_times), ...
                %     stimOff_times(curr_align),'nearest');
                if isnan(iti_frame(1,curr_align))||isnan(iti_frame(2,curr_align))
                    continue
                end
                cam_all_diff_align_iti{curr_align} = (roi_mask_face(:))'* reshape(abs(diff(double(...
                    ds.mc_align(squeeze(read(vr,iti_frame(:,curr_align))),animal,rec_day,'day_only')      ...
                    ),[],3)),[],(iti_frame(2,curr_align)-iti_frame(1,curr_align)))./sum(roi_mask_face,'all');
                ap.print_progress_fraction(curr_align,length(stimOff_times)-1);

            end
            camera_plot_iti{curr_recording}=cam_all_diff_align_iti;


            %% 对widefield imaging进行分析
            % align_times = stimOn_times(quiescent_trials);
            if strcmp(passive_workflow,'lcr_passive')
                align_category_all = vertcat(trial_events.values.TrialStimX);
            elseif strcmp(passive_workflow,'hml_passive_audio')
                align_category_all = vertcat(trial_events.values.StimFrequence);
            end

            trial_type{curr_recording}=align_category_all;
            trial_state_01{curr_recording}=quiescent_trials_1;
            trial_state_05{curr_recording}=quiescent_trials_2;


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

            roi_data_peri_av_barrel=permute(mean(redata(roi1(8).data.mask(:),:,:),1),[2,3,1]);
            image_plot_barrel{curr_recording}=roi_data_peri_av_barrel;




            %% 对iti的 widefield imaging进行分析

            iti_time=[stimOff_times(1:end-1) stimOn_times(2:length(stimOff_times))];



            dd=arrayfun(@(x) (iti_time(x,1):  1/surround_samplerate : iti_time(x,2)),1:length(stimOff_times)-1,'UniformOutput',false);


            aligned_v_all_iti = cellfun(@(x) permute(interp1(wf_t,wf_V',x,'previous'),[2,1]),dd,'UniformOutput',false);
            if length(stimOff_times)==length(stimOn_times)
                baseline_iti=permute(num2cell(nanmean(aligned_v_all(:,t_passive < 0,1:end-1),2),[1,2]),[2,3,1]);
            elseif length(stimOff_times)<length(stimOn_times)

                baseline_iti=permute(num2cell(nanmean(aligned_v_all(:,t_passive < 0,1:end-2),2),[1,2]),[2,3,1]);

            end
            aligned_v_all_iti_baslined=cellfun(@(x,y) x-y,aligned_v_all_iti,baseline_iti,'UniformOutput',false);




            load(master_U_fn);
            wf_px_all_iti=  cellfun(@(x) plab.wf.svd2px(U_master,x),aligned_v_all_iti_baslined,'UniformOutput',false);
            redata_iti=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)),wf_px_all_iti,'UniformOutput',false);

            roi_data_peri_av_iti=cellfun(@(x) permute(mean(x(roi1(1).data.mask(:),:,:),1),[2,3,1]),redata_iti,'UniformOutput',false);
            image_plot_iti{curr_recording}=roi_data_peri_av_iti;

            roi_data_peri_av_nose_iti=cellfun(@(x) permute(mean(x(roi1(7).data.mask(:),:,:),1),[2,3,1]),redata_iti,'UniformOutput',false);
            image_plot_nose_iti{curr_recording}=roi_data_peri_av_nose_iti;

            roi_data_peri_av_barrel_iti=cellfun(@(x) permute(mean(x(roi1(8).data.mask(:),:,:),1),[2,3,1]),redata_iti,'UniformOutput',false);
            image_plot_barrel_iti{curr_recording}=roi_data_peri_av_barrel_iti;



            clearvars('-except',preload_vars{:});





        end

        save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'camera_plot','camera_plot_iti','image_plot','image_plot_iti','image_plot_nose','image_plot_nose_iti','image_plot_barrel','image_plot_barrel_iti','trial_type','trial_state_01','trial_state_05','workflow_day', '-v7.3')
        % save([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ],'trial_state_05','-append', '-v7.3')

        clearvars('-except',main_preload_vars{:});

    end



end
