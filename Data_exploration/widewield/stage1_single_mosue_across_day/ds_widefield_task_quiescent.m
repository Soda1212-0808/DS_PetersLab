clear
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
workflow='task';

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];
task_boundary1=0;
            task_boundary2=0.2;
period_task=find(t_task>task_boundary1&t_task<task_boundary2);
 
animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
                    'DS000','DS004','DS014','DS015','DS016',...
                    'AP018','AP020','DS006','DS013',...
                    'AP027','AP028','DS019','DS020','DS021',...
                    'AP027','AP028','AP029',...
                    'HA003','HA004','DS019','DS020','DS021',...
                    'HA000','HA001','HA002','DS005'};

for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

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


    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings = recordings_passive( ...
        cellfun(@any,{recordings_passive.widefield}) & ...
        ~[recordings_passive.ephys] & ...
        ismember({recordings_passive.day},{recordings_training.day}));

    recordings2 = recordings_training( ...
        cellfun(@any,{recordings_training.widefield}) & ...
        ~[recordings_training.ephys] & ...
        ismember({recordings_training.day},{recordings_passive.day}));

    workflow_day={recordings2.day}';

wf_px_qiute=cell(length(recordings2),1);
    for curr_recording =5:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);
  % Grab pre-load vars
            preload_vars = who;

            % Load data
            rec_day = recordings2(curr_recording).day;

            clear time
            if length(recordings2(curr_recording).index)>1
                for mm=1:length(recordings2(curr_recording).index)
                    rec_time = recordings2(curr_recording).recording{mm};
                    % verbose = true;
                    % ap.load_timelite
                    timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                    timelite = load(timelite_fn);
                    time(mm)=length(timelite.timestamps);
                end
                [~,index_real]=max(time);
            else index_real=1;
            end


            rec_time = recordings2(curr_recording).recording{index_real};


            workflow_type_name{curr_recording}=recordings2(curr_recording).workflow{index_real};

        

            if contains( workflow_type_name{curr_recording}, {'audio_volume', 'audio_frequency'})
                workflow_type(curr_recording) = 2;
            elseif contains( workflow_type_name{curr_recording}, {'mixed_VA'})
                workflow_type(curr_recording) = 3;
            elseif contains( workflow_type_name{curr_recording}, {'stage1', 'stage2'}) && ...
                    (contains( workflow_type_name{curr_recording}, {'opacity', 'size_up', 'angle'}) || ...
                    isempty(regexp( workflow_type_name{curr_recording}, 'audio|mixed', 'once')))
                workflow_type(curr_recording) = 1;
            else
                workflow_type(curr_recording) = NaN;  % 未知类型
            end



            if strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')
                workflow_type_name_merge{curr_recording}='audio volume';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2')
                workflow_type_name_merge{curr_recording}='visual position';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_size_up')
                workflow_type_name_merge{curr_recording}='visual size up';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_opacity')
                workflow_type_name_merge{curr_recording}='visual opacity';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')
                workflow_type_name_merge{curr_recording}='audio frequency';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage1_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle_size60')
                workflow_type_name_merge{curr_recording}='visual angle';
            elseif strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                    ||strcmp(recordings2(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type_name_merge{curr_recording}='mixed VA';
            else  workflow_type_name_merge{curr_recording}='none';
            end



            verbose=true;


            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;
            load(master_U_fn);


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
            colorbar;
            axis square;
            title('Data Correlation Matrix');
            yticks([1:1:10])
            yticklabels({roi1.name})
            xticks([1:1:10])
            xticklabels({roi1.name})


            [N, T] = size(tace_matrix);
            maxCorrMat = zeros(N);
            lagMat = zeros(N);
            maxLag=100
            for i = 1:N
                for j = i:N  % only compute upper triangle; symmetric
                    xi = tace_matrix(i, :) - mean(tace_matrix(i, :));
                    xj = tace_matrix(j, :) - mean(tace_matrix(j, :));

                    [xc, lags] = xcorr(xi, xj, maxLag, 'coeff');
                    [maxCorr, idx] = max(abs(xc));  % abs for both pos/neg peak

                    maxCorrMat(i, j) = maxCorr;
                    lagMat(i, j) = lags(idx);

                    % Symmetric assignment
                    maxCorrMat(j, i) = maxCorr;
                    lagMat(j, i) = -lags(idx);  % lag(i,j) = -lag(j,i)
                end
            end


            figure;
            subplot(1,2,1);
            imagesc(maxCorrMat);
            colormap(ap.colormap(('WK')))

            colorbar; axis square;
            title('Max Cross-Correlation');

            subplot(1,2,2);
            imagesc(lagMat);
          colormap(ap.colormap(('BWR')))
            colorbar; axis square;
            title('Lag at Max Correlation');
            yticks([1:1:10])
            yticklabels({roi1.name})
            xticks([1:1:10])
            xticklabels({roi1.name})

clearvars('-except',preload_vars{:});
ap.print_progress_fraction(curr_recording,length(recordings2));
    end

       save([Path 'task\' animal '_task_quiescent.mat' ],'workflow_type','workflow_type_name',...
        'workflow_type_name_merge','wf_px_qiute','workflow_day', '-v7.3')

end
