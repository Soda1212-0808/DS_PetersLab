%% TESTING BATCH PASSIVE WIDEFIELD
clear all
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);

surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-5:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
% master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
%     'widefield_alignment','U_master.mat');

% animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
% animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016','HA000','HA001','HA002','HA003','HA004','AP027','AP028','AP029','DS019','DS020','DS021'};

    % animals = {'DS016','DS015','DS014','DS013','DS006','DS004','DS003','DS000'};
    % animals={'AP018','AP019','AP020','AP021','AP022','DS007','DS010','DS011','DS001'};
    % animals={'DS019','DS020','DS021'};
    % animals={'DS005'};

    animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
        'DS000','DS004','DS014','DS015','DS016',...
        'AP018','AP020','DS006','DS013',...
        'AP027','AP028','DS019','DS020','DS021',...
        'AP027','AP028','AP029',...
        'HA003','HA004','DS019','DS020','DS021',...
        'HA000','HA001','HA002'};

        % animals={'HA009','HA010','HA010','HA011'};

    for curr_passive=2
        if curr_passive==1
            passive_workflow = 'hml_passive_audio';
        elseif curr_passive==2
            passive_workflow = 'lcr_passive';
        elseif curr_passive==3
            passive_workflow = 'lcr_passive_size60';
        end

        for curr_animal_idx=1:length(animals)
            main_preload_vars = who;

            animal=animals{curr_animal_idx};
            fprintf('%s\n', ['start  ' animal ]);
            fprintf('%s\n', ['start saving ' passive_workflow ' files...']);

            training_workflow =...
                ['stim_wheel_right_stage1$|' ...
                'stim_wheel_right_stage2$|' ...
                'stim_wheel_right_stage1_opacity$|' ...
                'stim_wheel_right_stage2_opacity$|' ...
                'stim_wheel_right_stage1_angle$|' ...
                'stim_wheel_right_stage2_angle$|' ...
                'stim_wheel_right_stage2_angle_size60$|' ...
                'stim_wheel_right_stage1_size_up$|' ...
                'stim_wheel_right_stage2_size_up$|' ...
                'stim_wheel_right_stage1_audio_volume$|'...
                'stim_wheel_right_stage2_audio_volume$|' ...
                'stim_wheel_right_stage1_audio_frequency$|' ...
                'stim_wheel_right_stage2_audio_frequency$|' ...
                'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
                'stim_wheel_right_stage2_mixed_VA$'];

            recordings_passive = plab.find_recordings(animal,[],passive_workflow);


            recordings_training = plab.find_recordings(animal,[],training_workflow);

            
            bufferA=~ismember({recordings_passive.day},{recordings_training.day});
            bufferA = (sum(bufferA) >=3) * [1 1 1, zeros(1, numel(bufferA)-3)] + (sum(bufferA) < 3) * bufferA;
            recordings_wf_passive =[ recordings_passive( ...
                cellfun(@any,{recordings_passive.widefield}) & ...
                ~[recordings_passive.ephys] & ...
                (ismember({recordings_passive.day},{recordings_training.day})|...
                bufferA    ))];

         

            recordings_wf_training = recordings_training( ...
                cellfun(@any,{recordings_training.widefield}) & ...
                ~[recordings_training.ephys] & ...
                ismember({recordings_training.day},{recordings_passive.day}));


                wf_px_qiute = cell(1,3);
            



            workflow_day={recordings_wf_passive.day}';
        
                 for curr_recording =1:length(recordings_wf_passive)


                    % Grab pre-load vars
                    preload_vars = who;
                    % Load data
                    rec_day = recordings_wf_passive(curr_recording).day;
                    rec_time = recordings_wf_passive(curr_recording).recording{end};
                    % if ~recordings_wf_passive(curr_recording).widefield(end)
                    %     continue
                    % end

                    % try
                        load_parts.mousecam = true;
                        load_parts.widefield = true;
                        load_parts.widefield_master = true;
                        ap.load_recording;
                    % catch me
                    %     warning('%s %s %s: load error, skipping \n >> %s', ...
                    %         animal,rec_day,rec_time,me.message)
                    %     continue
                    % end


                    if strcmp(passive_workflow,'lcr_passive')||strcmp(passive_workflow,'lcr_passive_size60')
                        align_category_all = vertcat(trial_events.values.TrialStimX);
                    elseif strcmp(passive_workflow,'hml_passive_audio')
                        align_category_all = vertcat(trial_events.values.StimFrequence);
                    end


            wf_pd_off = interp1(photodiode_times,photodiode_values,wf_t,'previous')==0;
            wf_wheel_off  =   interp1(timelite.timestamps  ,double(wheel_move),wf_t)==0;
            aligned_V= wf_V(:,wf_pd_off&wf_wheel_off);




            temp_images= plab.wf.svd2px(U_master,aligned_V);
            buf1=reshape(temp_images,size(temp_images,1)*size(temp_images,2),size(temp_images,3)) ;

            trace=cell(length(roi1),1);
            for curr_roi= 1:length(roi1)
                trace{curr_roi}=nanmean(buf1(roi1(curr_roi).data.mask(:),:),1);
            end

            tace_matrix=cat(1,trace{1:10});
            correlation_matrix = corr(tace_matrix');  % 注意转置：每行是一个数据
            figure;
            imagesc(correlation_matrix);
            % colormap(ap.colormap(('WK')))
            colorbar;
            axis square;
            title('Data Correlation Matrix');
            yticks([1:1:10])
            yticklabels({roi1.name})
            xticks([1:1:10])
            xticklabels({roi1.name})






                save([Path passive_workflow '\' animal '_' passive_workflow '_quiescent.mat' ],'wf_px_qiute','workflow_day','-v7.3')
            
            end


            clearvars('-except',main_preload_vars{:});
        end
    end
