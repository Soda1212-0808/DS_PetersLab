%% package the data 
%% EDF A    reaction time matched kernels
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];
t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);

% variable definition
       
edges = [-Inf 0, 0.2,  0.3, Inf];

animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022'...
    'DS000','DS004','DS014','DS015','DS016'};
group_type={'VA','VA','VA','VA','VA','VA','AV','AV','AV','AV','AV'};

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
    'stim_wheel_right_stage2_audio_frequency$|' ];

workflow_name_map = containers.Map( ...
    {'stim_wheel_right_stage1_audio_volume', ...
    'stim_wheel_right_stage2_audio_volume', ...
    'stim_wheel_right_stage1', ...
    'stim_wheel_right_stage2', ...
    'stim_wheel_right_stage1_size_up', ...
    'stim_wheel_right_stage2_size_up', ...
    'stim_wheel_right_stage1_opacity', ...
    'stim_wheel_right_stage2_opacity',...
    'stim_wheel_right_stage1_audio_frequency',...
    'stim_wheel_right_stage2_audio_frequency',...
    'stim_wheel_right_stage2_mixed_VA',...
    'stim_wheel_right_frequency_stage2_mixed_VA'}, ...
    {'audio volume', 'audio volume', ...
    'visual position', 'visual position', ...
    'visual size up', 'visual size up', ...
    'visual opacity', 'visual opacity',...
    'audio frequency','audio frequency',...
    'mixed VA','mixed VA'} );

wf_stim_kernels_concat=table;
wf_stim_kernels_concat.name=animals';
wf_stim_kernels_concat.group=group_type';

% animals={'HA009','HA010','HA011','HA012'};
for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings2 = recordings_training( ...
        cellfun(@any,{recordings_training.widefield}) & ...
        ~[recordings_training.ephys] & ...
        ismember({recordings_training.day},{recordings_passive.day}));


    curr_group_type=group_type{curr_animal_idx};
    switch curr_group_type
        case {'VA'}
            recordings2=recordings2(find(~contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
        case {'AV'}
            recordings2=recordings2(find(contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
    end


    %%是否存在保存过之前的数据的文

    wf_V_all=cell(length(recordings2),1);
    wf_t_only_task_all=cell(length(recordings2),1);
    stim_regressors_all=cell(length(recordings2),1);
    stim_to_move_all=cell(length(recordings2),1);
    stim_to_move_idx_all=cell(length(recordings2),1);
    frac_velocity=cell(length(recordings2),1);
    for curr_recording =1:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings2(curr_recording).day;

        [~,index_real]=max( cellfun(@(rt) ...
            numel(load( ...
            plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
            'timestamps').timestamps), ...
            recordings2(curr_recording).recording));

        rec_time = recordings2(curr_recording).recording{index_real};

        verbose=true;
        load_parts = struct;
        load_parts.behavior = true;
        load_parts.widefield_master = true;
        load_parts.widefield = true;
        ap.load_recording;



        if length(stimOn_times)< length([trial_events.timestamps.Outcome])
            n_trials =length(stimOn_times);
        else
            n_trials = length([trial_events.timestamps.Outcome]);
        end

        % process behavioral data
        real_stimOn_times=stimOn_times(1:n_trials);
        real_stim_to_move=stim_to_move(1:n_trials);


        stim_to_move_idx = discretize(real_stim_to_move, edges);
        stim_to_move_all{curr_recording}=real_stim_to_move;
        stim_to_move_idx_all{curr_recording}=stim_to_move_idx;

        % wheel_velocity
        pull_times = real_stimOn_times(1:n_trials) + surround_time_points;
        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        frac_velocity{curr_recording} = event_aligned_wheel_vel;



        % linear regression data  线性回归后的数据
        wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
        % Create regressors

        stim_regressors = repmat({zeros(length(wf_t),1)}, 5, 1);
        stim_regressors(unique(stim_to_move_idx))= arrayfun(@(a)  histcounts(real_stimOn_times(stim_to_move_idx==a),wf_regressor_bins)',...
            unique(stim_to_move_idx),'UniformOutput',false  );


        gap_1=seconds([trial_events.timestamps(1:n_trials).ITIStart ] -trial_events.timestamps(1).StimOn (1))'+photodiode_on_times(1);
        gap_2=stimOn_times(1:n_trials)+stim_to_outcome(1:n_trials);

        wf_t_only_task= repmat({false(length(wf_t),1)}, 5, 1);
        wf_t_only_task(unique(stim_to_move_idx))=arrayfun(@(a) interp1([gap_1(stim_to_move_idx==a);gap_2(stim_to_move_idx==a)],...
            [ones(sum(stim_to_move_idx==a),1);....
            zeros(sum(stim_to_move_idx==a),1)],...
            wf_t,'previous')==1, unique(stim_to_move_idx),'UniformOutput',false);

        wf_V_all{curr_recording}=wf_V;
        wf_t_only_task_all{curr_recording}=wf_t_only_task;
        stim_regressors_all{curr_recording}=stim_regressors;

        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings2));
        fprintf('\n');

    end

    temp_idx=feval(@(c)   cat(2,c{:}),...
        cellfun(@(a) cellfun(@(b)  sum(b),a,'UniformOutput',true ),stim_regressors_all,'UniformOutput',false));

    regressor_concat=cell(length(edges)-1,1);
    wf_t_concat=cell(length(edges)-1,1);
    wf_V_all_concat=cell(length(edges)-1,1);
    stim_to_move_concat=cell(length(edges)-1,1);
    wheel_velocity_concat=cell(length(edges)-1,1);
    for curr_state=1:length(edges)-1
        accum_idx = find(cumsum(temp_idx(curr_state,:)) > 100, 1, 'first');

        if isempty(accum_idx)
            accum_idx=length(stim_regressors_all);
        end
        regressor_concat{curr_state}=feval(@(c)  cat(1,c{:}),cellfun(@(x) x{curr_state} ,stim_regressors_all(1:accum_idx),'uni',false   ) );
        wf_t_concat{curr_state}=  feval(@(c)  cat(1,c{:}),cellfun(@(x) x{curr_state} ,wf_t_only_task_all(1:accum_idx),'uni',false   ) );
        wf_V_all_concat{curr_state}=cat(2,wf_V_all{1:accum_idx});

        stim_to_move_concat{curr_state}=feval(@(a,b)  a(b==curr_state),  ...
            cat(1,stim_to_move_all{1:accum_idx}) ,cat(1,stim_to_move_idx_all{1:accum_idx}) );

        wheel_velocity_concat{curr_state}=feval(@(a,b)  a(b==curr_state,:),  ...
            cat(1,frac_velocity{1:accum_idx}) ,cat(1,stim_to_move_idx_all{1:accum_idx}) );

    end

    n_components = 200;
    frame_shifts = -10:30;
    lambda = 15;

    % [stim_kernels,predicted_signals,explained_var] = ...
    %     cellfun(@(x,y) ap.regresskernel(wf_V_all_concat(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
    %     wf_t_concat, regressor_concat ,'UniformOutput',false );

    stim_kernels=cell(length(wf_t_concat),1);
    for curr_stage=1:length(wf_t_concat)

        stim_kernels{curr_stage}= ap.regresskernel(wf_V_all_concat{curr_stage}(1:n_components,find(wf_t_concat{curr_stage}==1)),...
            regressor_concat{curr_stage}(find(wf_t_concat{curr_stage}==1))',-frame_shifts,lambda);

    end

    wf_stim_kernels_concat.wf_kernels(curr_animal_idx)={stim_kernels};
    wf_stim_kernels_concat.stim_to_move(curr_animal_idx)={stim_to_move_concat};
    wf_stim_kernels_concat.wheel_velocity(curr_animal_idx)={wheel_velocity_concat};



end

for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings2 = recordings_training( ...
        cellfun(@any,{recordings_training.widefield}) & ...
        ~[recordings_training.ephys] & ...
        ismember({recordings_training.day},{recordings_passive.day}));


    curr_group_type=group_type{curr_animal_idx};
    switch curr_group_type
        case {'VA'}
            recordings2=recordings2(find(~contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
        case {'AV'}
            recordings2=recordings2(find(contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
    end


    %%是否存在保存过之前的数据的文


    wf_raw=cell(length(recordings2),1);
    for curr_recording =1:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings2(curr_recording).day;

        [~,index_real]=max( cellfun(@(rt) ...
            numel(load( ...
            plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
            'timestamps').timestamps), ...
            recordings2(curr_recording).recording));

        rec_time = recordings2(curr_recording).recording{index_real};

        verbose=true;
        load_parts = struct;
        load_parts.behavior = true;
        load_parts.widefield_master = true;
        load_parts.widefield = true;
        ap.load_recording;



        if length(stimOn_times)< length([trial_events.timestamps.Outcome])
            n_trials =length(stimOn_times);
        else
            n_trials = length([trial_events.timestamps.Outcome]);
        end

        % process behavioral data
        real_stimOn_times=stimOn_times(1:n_trials);
        real_stim_to_move=stim_to_move(1:n_trials);

        % edges = [-Inf, 0, 0.1, 0.2, 0.3, Inf];

        stim_to_move_idx = discretize(real_stim_to_move, edges);



        align_category = ones(n_trials,1);
        baseline_times = real_stimOn_times;
        peri_event_t = real_stimOn_times+ reshape(t_task,1,[]);
        baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);
        aligned_v = interp1(wf_t,wf_V',peri_event_t,'previous');

        aligned_baseline_v = nanmean(reshape(interp1(wf_t,wf_V',baseline_event_t,'previous'), ...
            length(baseline_times),length(baseline_t),[]),2);
        % 减去baseline数据
        aligned_v_baselinesub = aligned_v - aligned_baseline_v;

        align_id = findgroups(reshape(stim_to_move_idx,[],1));
        % aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
        wf_raw{curr_recording} = repmat({nan(2000,length(t_task),'single')}, 4, 1);
        wf_raw{curr_recording}(unique(stim_to_move_idx))=arrayfun(@(id) permute(aligned_v_baselinesub(stim_to_move_idx==id,:,:),[3,2,1]),...
            unique(stim_to_move_idx),'UniformOutput',false);

        % tem_image_passive=plab.wf.svd2px(U_master(:,:,1:size(aligned_v_avg,1)),aligned_v_avg);
        % tem_image_passive=plab.wf.svd2px(U_master(:,:,1:size(wf_raw,1)),wf_raw);
        %
        % ap.imscroll(tem_image_passive,t_task)
        % axis image off
        % clim( 0.03*[-1,1]);
        % ap.wf_draw('ccf',[0.5 0.5 0.5]);
        % colormap( ap.colormap(['BWR']));
        %
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings2));
        fprintf('\n');

    end

    wf_stim_kernels_concat.wf_raw(curr_animal_idx)={wf_raw};
end

save_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data';
save(fullfile(save_path,'revision','wf_task_decoding_concatnate.mat'),'wf_stim_kernels_concat','-v7.3');


%%  EDF B:  Package encoding/decoding data
% Stim decoding after encoding-regressing out movement

% Load behavior
% (individual animals packaged here:)
% https://github.com/Soda1212-0808/DS_PetersLab/blob/main/Data_exploration/projects/cross_modal_PFC_striatum_2025/ds_behavior_single_mouse.m
% (across-animals packaged here:)
% Song_2025.package.save_beahvior
data_path = fullfile(plab.locations.server_path,'Lab','Papers','Song_2025','data');
load(fullfile(data_path,'behavior.mat'));

% Get animals from behavior structure
animals = cell(2,1);
animals{1} = behavior_aligned{1}.reaction_time.name; % VA
animals{2} = behavior_aligned{2}.reaction_time.name; % AV

% Loop through modalities/animal groups/animals, get kernels
encoding_decoding_kernels = struct;
for curr_animal_group = 1:length(animals)
    for curr_animal_idx = 1:length(animals{curr_animal_group})

        animal = animals{curr_animal_group}{curr_animal_idx};

        % Get corresponding learned days from behavior
        % (copied code from Song_2025.package.save_beahvior to get day match)
        mouse_data_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Users\Da_Song\Data_back_up\project_cross_model\wf_data';
        raw_data_behavior = load(fullfile(mouse_data_path,'behavior',[animal,'_behavior.mat']));
        raw_data_task = load(fullfile(mouse_data_path,'task',[animal,'_task.mat']));
        if strcmp(animal,'AP019')
            use_rec_idx =  (1:15)';
        else
            [~,use_rec_idx] = ismember(raw_data_task.workflow_day,raw_data_behavior.workflow_day);
        end

        rec_days = raw_data_behavior.workflow_day(use_rec_idx);
        rec_days_unimodal_idx = find(~contains(behavior_each_mice{curr_animal_group}.workflow_name{curr_animal_idx},'mixed'));

        % Loop though animals, run encoding/decoding
        for curr_recording = rec_days_unimodal_idx'

            % All in a try/catch loop: skip on errors
            % (at least one day is too long = regression memory error)
            try

            % Get day and recording
            rec_day = rec_days{curr_recording};
            recordings = plab.find_recordings(animal,rec_day,'stim_wheel*');
            % (copied from ds_behavior_single_mouse: use longest rec)
            if length(recordings.index)>1
                for mm=1:length(recordings.index)
                    rec_time = recordings.recording{mm};
                    timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                    timelite = load(timelite_fn);
                    time(mm)=length(timelite.timestamps);
                end
                [~,index_real]=max(time);
            else
                index_real=1;
            end

            rec_time = recordings.recording{index_real};

            preload_vars = who;
            load_parts.widefield = true;
            load_parts.widefield_master = true;
            load_parts.mousecam = true;
            ap.load_recording;

            % Load and prep pupil SLEAP tracking
            pupil_sleap_dir = dir(fullfile(fileparts(mousecam_fn),'**','*.h5'));
            if isempty(pupil_sleap_dir)
                continue
            end
            pupil_sleap_fn = fullfile(pupil_sleap_dir.folder,pupil_sleap_dir.name);

            tracks = h5read(pupil_sleap_fn,'/tracks');       % frames x nodes x 2 (x/y-position)
            % (scores aren't used at the moment - PG didn't need previously)
            % pointScores = h5read(pupil_sleap_fn,'/point_scores')'; % frames x nodes
            % instanceScores = h5read(pupil_sleap_fn, '/instance_scores')'; % transpose to 1 x frames

            % Fit circle (solve for a,b,c in x^2 + y^2 + a*x + b*y + c = 0)
            % (use only non-NaN vertices, remove points with too few vertices)
            circle_fit_fun = @(x,y) [x(~any(isnan([x,y]),2)) y(~any(isnan([x,y]),2)) ...
                ones(sum(~any(isnan([x,y]),2)),1)]\ ...
                -(x(~any(isnan([x,y]),2)).^2+y(~any(isnan([x,y]),2)).^2);

            min_pupil_points = 3;
            pupil_valid_frames = sum(~any(isnan(tracks),3),2) >= min_pupil_points;

            pupil_circle_fit = nan(3,length(mousecam_times));
            pupil_circle_fit(:,pupil_valid_frames) = cell2mat(arrayfun(@(frame) ...
                circle_fit_fun(tracks(frame,:,1)',tracks(frame,:,2)'), ...
                find(pupil_valid_frames)','uni',false));

            pupil = struct( ...
                'x',-pupil_circle_fit(1,:)./2, ...
                'y',-pupil_circle_fit(2,:)./2, ...
                'diameter',2*sqrt(sum(pupil_circle_fit(1:2,:).^2,1)/4-pupil_circle_fit(3,:)));

            % Regression parameters
            time_bins = [wf_t;wf_t(end)+1/wf_framerate];
            n_components = 200;
            frame_shifts = -10:30;
            lamda_encode = 0;
            lambda_decode = 15;
            cv_fold = 5;
            skip_t = 60; % seconds start/end to skip for artifacts
            skip_frames = round(skip_t*wf_framerate);

            % Stim onset regressors
            stim_regressors = histcounts(stimOn_times,time_bins);

            % Move regressors
            % (move onset, wheel velocity, pupil diameter, pupil velocity)
            wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
            move_onset_regressors = histcounts(wheel_starts,time_bins);

            wheel_velocity_resample = interp1(timelite.timestamps,wheel_velocity,wf_t);
            pupil_diameter_resample = interp1(mousecam_times,pupil.diameter,wf_t);
            pupil_velocity_resample = interp1(sqrt(diff(pupil.x).^2+diff(pupil.y).^2),wf_t);

            move_regressors = vertcat( ...
                move_onset_regressors,wheel_velocity_resample', ...
                pupil_diameter_resample',pupil_velocity_resample');

            % Encoding: stim kernel
            kernels_stimmove_encode = ...
                ap.regresskernel( ...
                vertcat(stim_regressors(:,skip_frames:end-skip_frames), ...
                move_regressors(:,skip_frames:end-skip_frames)), ...
                wf_V(1:n_components,skip_frames:end-skip_frames), ...
                frame_shifts,lamda_encode,[],cv_fold);

            % Encoding: stim and move separately (to use residuals)
            [kernels_stim_encode,predicted_signals_stim] = ...
                ap.regresskernel(stim_regressors(:,skip_frames:end-skip_frames), ...
                wf_V(1:n_components,skip_frames:end-skip_frames), ...
                frame_shifts,lamda_encode,[],cv_fold);

            [kernels_move_encode,predicted_signals_move] = ...
                ap.regresskernel(move_regressors(:,skip_frames:end-skip_frames), ...
                wf_V(1:n_components,skip_frames:end-skip_frames), ...
                frame_shifts,lamda_encode,[],cv_fold);

            % Decoding: regress to stim and move (on full and residuals)
            kernels_stim_decode_full = ...
                ap.regresskernel(wf_V(1:n_components,skip_frames:end-skip_frames), ...
                stim_regressors(:,skip_frames:end-skip_frames),-frame_shifts,lambda_decode,[],cv_fold);

            kernels_stim_decode_moveresiduals = ...
                ap.regresskernel(wf_V(1:n_components,skip_frames:end-skip_frames) - ...
                fillmissing(predicted_signals_move,'constant',0), ...
                stim_regressors(:,skip_frames:end-skip_frames),-frame_shifts,lambda_decode,[],cv_fold);

            kernels_stim_decode_stimresiduals = ...
                ap.regresskernel(wf_V(1:n_components,skip_frames:end-skip_frames) - ...
                fillmissing(predicted_signals_stim,'constant',0), ...
                stim_regressors(:,skip_frames:end-skip_frames),-frame_shifts,lambda_decode,[],cv_fold);

            % Store variables
            encoding_decoding_kernels(curr_animal_group).stimmove_encode{curr_animal_idx}{curr_recording} = permute(kernels_stimmove_encode,[3,2,1]);
            encoding_decoding_kernels(curr_animal_group).stim_encode{curr_animal_idx}{curr_recording} = permute(kernels_stim_encode,[3,2,1]);
            encoding_decoding_kernels(curr_animal_group).move_encode{curr_animal_idx}{curr_recording} = permute(kernels_move_encode,[3,2,1]);
            encoding_decoding_kernels(curr_animal_group).stim_decode_full{curr_animal_idx}{curr_recording} = kernels_stim_decode_full;
            encoding_decoding_kernels(curr_animal_group).stim_decode_moveresiduals{curr_animal_idx}{curr_recording} =  kernels_stim_decode_moveresiduals;
            encoding_decoding_kernels(curr_animal_group).stim_decode_stimresiduals{curr_animal_idx}{curr_recording} = kernels_stim_decode_stimresiduals;

            % Clear recording variables and print progress
            clearvars('-except',preload_vars{:});
            fprintf('Finished %s day %d/%d\n',animal,curr_recording,length(rec_days))
            reset(gpuDevice());

            catch me
                fprintf('Error: "%s", skipping: %s day %d/%d\n',me.message,animal,curr_recording,length(rec_days))
                warning(me.message);
                clearvars('-except',preload_vars{:});
                continue
            end
        end
    end
end

save_fn = fullfile(data_path,'encoding_decoding_kernels');
save(save_fn,'encoding_decoding_kernels');
fprintf('\n---\nSaved %s\n---\n',save_fn)


%%  EDF C  no package data

%% EDF D  no package data

%% EDF E

clear all
clc
U_master = plab.wf.load_master_U;
load(fullfile('\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data\General_information\roi.mat'))

Path = 'D:\Data process\project_cross_model\wf_data\';

title_names={'opacity','static','size up','angle','angle size 60'};
behavior_data=table;

for curr_group=1:5
    switch curr_group
        case 1
            animals={'AP027','AP028','AP029'};
            workflows={'stim_wheel_right_stage1_opacity','stim_wheel_right_stage2_opacity'};

        case 2
            animals={'AP019_nochange'};
            workflows={'stim_wheel_right_stage1_no_change','stim_wheel_right_stage2_no_change'};
        case 3
            animals={'HA003','HA004','DS019','DS020','DS021'};
            workflows={'stim_wheel_right_stage1_size_up','stim_wheel_right_stage2_size_up'};
        case 4
            animals={'HA000','HA001','HA002'};
            workflows={'stim_wheel_right_stage1_angle','stim_wheel_right_stage2_angle'};

        case 5
            animals={'HA000','HA001','HA002'};
            workflows={'stim_wheel_right_stage1_angle_size60','stim_wheel_right_stage2_angle_size60'};
    end


    title_name=title_names{curr_group};

    behavior_data.worflow(curr_group)={title_name};

    performance=cell(size(animals,1),1);
    RT=cell(size(animals,1),1);
    p_val=cell(size(animals,1),1);
    task_kernels=cell(size(animals,1),1);
    passive_kernels=cell(size(animals,1),1);

    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);
        raw_data_task_kernels=load([Path   'task\' animal '_task'  '.mat']);
        switch curr_group
            case {1,2,3,4}
                raw_data_passive_kernels=load([Path   'lcr_passive\' animal '_lcr_passive'  '.mat']);
            case 5
                raw_data_passive_kernels=load([Path   'lcr_passive_size60\' animal '_lcr_passive_size60'  '.mat']);
        end
        workflow_idx=ismember(raw_data_behavior.workflow_name_full,workflows);
        temp_x=raw_data_behavior.rxn_l_mad_p(workflow_idx,1)<0.05;
        p_val{curr_animal}=(sum(temp_x)>1) & (cumsum(temp_x)>0);

        s2m_mad=  raw_data_behavior.stim2lastmove_mad(workflow_idx,1);
        s2m_mad_null=  raw_data_behavior.stim2lastmove_mad_null(workflow_idx,1);
        performance{curr_animal}= (s2m_mad_null-s2m_mad)./(s2m_mad_null+s2m_mad);
        RT{curr_animal}=raw_data_behavior.stim2move_mean(workflow_idx,1);
        task_kernels{curr_animal}=cellfun(@(x) x{1},raw_data_task_kernels.wf_px_task_kernels(workflow_idx),'UniformOutput',false)';

        workflow_passive_idx=ismember(raw_data_passive_kernels.workflow_day,raw_data_task_kernels.workflow_day(workflow_idx));
        passive_kernels{curr_animal}=raw_data_passive_kernels.wf_px_kernels(workflow_passive_idx)';

    end
    behavior_data.performance(curr_group)={performance};
    behavior_data.reaction_time(curr_group)={RT};
    behavior_data.p_val(curr_group)={p_val};
    behavior_data.task_kernels(curr_group)={task_kernels};
    behavior_data.passive_kernels(curr_group)={passive_kernels};

end

save(fullfile('\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data\revision',...
    'different_task_behavior.mat'),'behavior_data','-v7.3')


%% EDF F  variable task contrast volume
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
animals={'DS029','DS030','DS031'};

for curr_task=1:2
    switch curr_task
        case 1
            workflow_task='stim_wheel_right_stage2_variable_contrast';
        case 2
            workflow_task='stim_wheel_right_stage2_audio_variable_volume_earphone';
    end


kernels_data=table;
kernels_data.name=animals';
for curr_animal_idx=1:length(animals)
    main_preload_vars = who;
    animal=animals{curr_animal_idx};
    
    fprintf('%s\n', ['start  ' animal ]);
    recordings = plab.find_recordings(animal,[],workflow_task);
    wf_px_kernels=cell(length(recordings),1);
    performance=cell(length(recordings),1);
    react_time=cell(length(recordings),1);
    p_val=cell(length(recordings),1);
    for curr_recording =1:length(recordings)
        preload_vars = who;
        rec_day = recordings(curr_recording).day;
        rec_time = recordings(curr_recording).recording{end};

        load_parts.mousecam = true;
        load_parts.widefield = true;
        load_parts.widefield_master = true;
        ap.load_recording;

        ds.process_wf_task;
        ds.process_behavior;

        wf_px_kernels{curr_recording} = cat(3,wf_task_data.stim_kernels{:});
        performance{curr_recording}=behavior.performance;
        react_time{curr_recording}=behavior.stim2move_l_stats(:,3);

        p_val{curr_recording}=behavior.rxn_l_p(:,1);
        % Prep for next loop
        ap.print_progress_fraction(curr_recording,length(recordings));
        clearvars('-except',preload_vars{:});

    end
kernels_data.kernels{curr_animal_idx}=cat(4, wf_px_kernels{:});
kernels_data.performance{curr_animal_idx}=cat(2, performance{:});
kernels_data.react_time{curr_animal_idx}=cat(2, react_time{:});
kernels_data.p_val{curr_animal_idx}=cat(2, p_val{:});

        clearvars('-except',main_preload_vars{:});

end
 
switch curr_task
    case 1
        save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\visual_task_variable') ,'kernels_data','-v7.3')
    case 2
        save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\audio_task_variable') ,'kernels_data','-v7.3')
end

end

%%  EDF G   size 20 vs 60

clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

% Path = 'Y:\Data process\project_cross_model\wf_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

animals={'AP030','AP032','DS029','DS030','DS031'};
workflow_passive={'lcr_passive','lcr_passive_size60'};

passive_data=table;
passive_data.name=animals';
for curr_animal_idx=1:length(animals)
    main_preload_vars = who;
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    for curr_passive=1:2
        curr_passive_workflow = workflow_passive{curr_passive};
        fprintf('%s\n', ['start saving ' curr_passive_workflow ' files...']);
        recordings_passive = plab.find_recordings(animal,[],'lcr_passive_size60');
        recordings_task = plab.find_recordings(animal,[],'stim_wheel_right_stage2');
        temp_days=intersect( {recordings_passive.day},{recordings_task.day});
        recordings=plab.find_recordings(animal,[],curr_passive_workflow);
        recordings= recordings(    ismember({recordings.day},temp_days));
        wf_px_kernels=cell(length(recordings),1);
        for curr_recording =1:length(recordings)
            preload_vars = who;
            rec_day = recordings(curr_recording).day;
            rec_time = recordings(curr_recording).recording{end};

            load_parts.mousecam = true;
            load_parts.widefield = true;
            load_parts.widefield_master = true;
            ap.load_recording;

            align_category_all = vertcat(trial_events.values.TrialStimX);

            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            stim_regressors = cell2mat(arrayfun(@(x) ...
                histcounts(stimOn_times(align_category_all == x),wf_regressor_bins), ...
                unique(align_category_all),'uni',false));

            n_components = 400;
            frame_shifts = -10:30;
            lambda = 15;

            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    [kernels,predicted_signals,explained_var] = ...
                        ap.regresskernel(wf_V(1:n_components,:),stim_regressors,-frame_shifts,lambda);

                    success = true; % 如果没有报错，则成功运行
                catch ME
                    disp(['Error: ', ME.message]);
                    n_components = n_components - 1; % 变量 a 递减
                    if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
                        error('n_components 过小，无法继续运行');
                    end
                end
            end

            disp('running successfully');
            wf_px_kernels{curr_recording} = kernels;

            % Prep for next loop
            ap.print_progress_fraction(curr_recording,length(recordings));
            clearvars('-except',preload_vars{:});

        end

        passive_data.(workflow_passive{curr_passive})(curr_animal_idx)={cat(4,wf_px_kernels{:})};

    end
end


save(fullfile('\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data\revision','visual_size_passive_compare.mat'),'passive_data','-v7.3');


%% EDF H block test
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

% server_path= [plab.locations.server_path  'Lab\widefield_alignment\animal_alignment'];

surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];
t_kernels=1/surround_samplerate*[-10:30];
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
training_workflow ='stim_wheel_right_stage2';
passive_workflow = 'lcr_passive';
animals =     { 'AP030','AP032','DS030','DS031','DS029'};

wf_px_kernels_all=table;

for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    wf_px_kernels_all.animal(curr_animal_idx)={animal};

    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);


    recordings_passive = plab.find_recordings(animal,[],passive_workflow);
    recordings_training = plab.find_recordings(animal,[],training_workflow);
    red_days=intersect({recordings_passive(find(cellfun(@length ,{recordings_passive.index},'UniformOutput',true)==2)).day },...
        {recordings_training(find(cellfun(@length ,{recordings_training.index},'UniformOutput',true)==2)).day });

    wf_px_kernels=table;

    for curr_day =1
        % for curr_recording =4:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(red_days),curr_day);
        % Load data
        rec_day = red_days{curr_day};
        wf_px_kernels.day(curr_day)={rec_day};
        task_rec_times= recordings_training( ismember({recordings_training.day},rec_day)).recording;
        for curr_recording=1:2
            rec_time=task_rec_times{curr_recording};
              load_parts.widefield_master = true;
                load_parts.widefield = true;
            ap.load_recording
            wf_task_process_parts = struct( ...
                'stim', 1,  'move', 0, 'iti_move', 0, ...
                'reward', 0,  'all_iti_move', 0);
            ds.process_wf_task
            wf_px_kernels.(['task' num2str(curr_recording)])(curr_day)=  wf_task_data.stim_kernels;
            ap.print_progress_fraction(curr_recording,2);
        end
        passive_rec_times= recordings_passive( ismember({recordings_passive.day},rec_day)).recording;

        for curr_recording=1:2
            rec_time=passive_rec_times{curr_recording};
              load_parts.widefield_master = true;
                load_parts.widefield = true;
            ap.load_recording
            wf_passive_process_parts = struct( ...
                'averaged_data', 0, ...
                'kernels', 1);
            ds.process_wf_passive
            wf_px_kernels.(['passive' num2str(curr_recording)])(curr_day)=  {cat(3,wf_passive_data.kernels_decoding{:})};
            ap.print_progress_fraction(curr_recording,2);
        end
    end

    red_days_signle=intersect({recordings_passive(find(cellfun(@length ,{recordings_passive.index},'UniformOutput',true)==1)).day },...
        {recordings_training(find(cellfun(@length ,{recordings_training.index},'UniformOutput',true)==1)).day });
    for curr_day =length(red_days_signle)
        % for curr_recording =4:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(red_days),curr_day);
        % Load data
        rec_day = red_days_signle{curr_day};
        wf_px_kernels.day(curr_day)={rec_day};

        task_rec_times= recordings_training( ismember({recordings_training.day},rec_day)).recording;

        rec_time=task_rec_times{1};
          load_parts.widefield_master = true;
                load_parts.widefield = true;
        ap.load_recording
        wf_task_process_parts = struct( ...
            'stim', 1,  'move', 0, 'iti_move', 0, ...
            'reward', 0,  'all_iti_move', 0);
        ds.process_wf_task
        wf_px_kernels.task_signle(curr_day)=  wf_task_data.stim_kernels;
        passive_rec_times= recordings_passive( ismember({recordings_passive.day},rec_day)).recording;
        rec_time=passive_rec_times{1};
          load_parts.widefield_master = true;
                load_parts.widefield = true;
        ap.load_recording
        wf_passive_process_parts = struct( ...
            'averaged_data', 0, ...
            'kernels', 1);
        ds.process_wf_passive
        wf_px_kernels.passive_signle(curr_day)=  {cat(3,wf_passive_data.kernels_decoding{:})};
    end

    wf_px_kernels_all.wf_px_kernels(curr_animal_idx)={wf_px_kernels};

end
 save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\wf_block_test.mat') ,'wf_px_kernels_all','-v7.3')



 %% EDF I  pupil nose 
clear all
groups_name={'VA','AV'};
modes_name={'Visual','Auditory'};
U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');
Path='D:\Data process\project_cross_model\wf_data\data_package';

surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
surround_window = [-0.5,1];
mousecam_framerate = 30;
face_time = surround_window(1):1/mousecam_framerate:surround_window(2);

all_data=struct;

for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS015','DS016'};
    end
    for curr_mode=1:2

        temp_data_all=table;
        for curr_animal=1:length(animals)
            preload_vars=who;
            animal=animals{curr_animal};
            data_all=matfile(fullfile(Path,[animal '_all_data.mat']));


            select_id_3{curr_group}=(strcmp([data_all.task_name],'stim_wheel_right_stage1')|...
                strcmp([data_all.task_name],'stim_wheel_right_stage2'))&...
                ~cellfun(@isempty ,data_all.wf_lcr_passive)&...
                ~cellfun(@isempty ,data_all.wf_hml_passive_audio)&...
            ~cellfun(@isempty ,data_all.face_hml_passive_audio)&...
                ~cellfun(@isempty ,data_all.face_lcr_passive);

            select_id_3{3-curr_group}=(strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|...
                strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume'))&...
                ~cellfun(@isempty ,data_all.wf_hml_passive_audio)&...
                ~cellfun(@isempty ,data_all.wf_lcr_passive) &...
            ~cellfun(@isempty ,data_all.face_hml_passive_audio)&...
                ~cellfun(@isempty ,data_all.face_lcr_passive);

         
            switch curr_mode
                case 1
                    temp_face_passive=data_all.face_lcr_passive;
                    temp_wf_passive_0=data_all.wf_lcr_passive;
                case 2
                    temp_face_passive=data_all.face_hml_passive_audio;
                    temp_wf_passive_0=data_all.wf_hml_passive_audio;
            end

            % pupil

            % temp_idd=find(~cellfun(@isempty,temp_face_passive,'UniformOutput',true));
            % pupil_idx=ismember(1:numel(temp_face_passive),temp_idd(cellfun(@(x)  x.validation.pupil, ...
            %     temp_face_passive(temp_idd),'UniformOutput',true)))';


            temp_behavior=data_all.behavior_task;
            temp_p_val=cellfun(@(x) ...
                arrayfun(@(id)  temp_behavior{id}.rxn_l_p(1)<0.05, find(x),'UniformOutput',true),...
                select_id_3,'UniformOutput',false);


          
            temp_pupil_size=cellfun(@(aa)  feval(@(a) cat(4,a{:}), cellfun(@(xx)  feval(@(d) cat(3,d{:}), ...
                cellfun(@(c) nanmean(c,1), xx.pupil_data.diameterZ_filt_sav,'uni',false)),...
                aa,'UniformOutput',false)) ,...
                cellfun( @(x) temp_face_passive(x ),select_id_3,'UniformOutput',false),'UniformOutput',false);



            pupil_data=cat(4,nan(size(temp_pupil_size{1},1), size(temp_pupil_size{1},2),size(temp_pupil_size{1},3),...
                5-length(find(temp_p_val{1}==1,5))),...
                temp_pupil_size{1}(:,:,:,find(temp_p_val{1}==1,5,'last')),...
                temp_pupil_size{2}(:,:,:,1:min(5,end)));

            pupil_3stage={temp_pupil_size{1}(:,:,:, temp_p_val{1}==0),...
                temp_pupil_size{1}(:,:,:, find(temp_p_val{1}==1,2,'last')),...
                temp_pupil_size{2}(:,:,:, find(temp_p_val{2}==1,2,'last'))};


            %pupil center

            temp_pupil_center=cellfun(@(aa)  feval(@(a) cat(5,a{:}), cellfun(@(xx)  feval(@(d) cat(4,d{:}), ...
                cellfun(@(c) nanmean(c,1), xx.pupil_data.center_filt_sav,'uni',false)),...
                aa,'UniformOutput',false)) ,...
                cellfun( @(x) temp_face_passive(x),select_id_3,'UniformOutput',false),'UniformOutput',false);
            


            pupil_center_data=cat(5,nan(size(temp_pupil_center{1},1), size(temp_pupil_center{1},2),...
                size(temp_pupil_center{1},3),size(temp_pupil_center{1},4),...
                5-length(find(temp_p_val{1}==1,5))),...
                temp_pupil_center{1}(:,:,:,:,find(temp_p_val{1}==1,5,'last')),...
                temp_pupil_center{2}(:,:,:,:,1:min(5,end)));


            pupil_center_3stage={temp_pupil_center{1}(:,:,:,:,temp_p_val{1}==0),...
                temp_pupil_center{1}(:,:,:,:, find(temp_p_val{1}==1,2,'last')),...
                temp_pupil_center{2}(:,:,:,:,find(temp_p_val{2}==1,2,'last'))};


          
            % nose
            temp_nose_passive=cellfun(@(aa)  feval(@(a) cat(4,a{:}), cellfun(@(xx) ...
                permute( nanmean(...
                feval(@(d) cat(5,d{:}), cellfun(@(c) nanmean(c(:,:,3,:),1), xx.face_data.nose_filt_sav,'uni',false)) ,1),[2,5,4,1,3]) ,...
                aa,'UniformOutput',false)) ,...
                cellfun( @(x) temp_face_passive(x),select_id_3,'UniformOutput',false),'UniformOutput',false);

            nose_data=cat(4,nan(size(temp_nose_passive{1},1), size(temp_nose_passive{1},2),size(temp_nose_passive{1},3),...
                5-length(find(temp_p_val{1}==1,5))),...
                temp_nose_passive{1}(:,:,:,find(temp_p_val{1}==1,5,'last')),...
                temp_nose_passive{2}(:,:,:,1:5));

            nose_3stage={temp_nose_passive{1}(:,:,:,temp_p_val{1}==0),...
                temp_nose_passive{1}(:,:,:, find(temp_p_val{1}==1,2,'last')),...
                temp_nose_passive{2}(:,:,:,find(temp_p_val{2}==1,2,'last'))};



            % wf_passive
            temp_wf_passive=cellfun(@(aa)  feval(@(a) cat(4,a{:}), cellfun(@(xx) cat(3,xx.kernels_decoding{:}),...
                aa,'UniformOutput',false)) ,...
                cellfun( @(x) temp_wf_passive_0(x),select_id_3,'UniformOutput',false),'UniformOutput',false);

            wf_passive_3stage={temp_wf_passive{1}(:,:,:, temp_p_val{1}==0),...
                temp_wf_passive{1}(:,:,:, find(temp_p_val{1}==1,2,'last')),...
                temp_wf_passive{2}(:,:,:, find(temp_p_val{2}==1,2,'last'))};


            wf_passive_data=cat(4,nan(size(temp_wf_passive{1},1), size(temp_wf_passive{1},2),size(temp_wf_passive{1},3),...
                5-length(find(temp_p_val{1}==1,5))),...
                temp_wf_passive{1}(:,:,:,find(temp_p_val{1}==1,5,'last')),...
                temp_wf_passive{2}(:,:,:,1:5));



 
            temp_data_all.nose_passive{curr_animal}=nose_data;
            temp_data_all.pupil_size{curr_animal}=pupil_data;
            temp_data_all.pupil_size_single{curr_animal}=pupil_3stage;
            temp_data_all.pupil_all_trace{curr_animal}=temp_pupil_size;

            temp_data_all.wf_passive{curr_animal}=wf_passive_data;
            temp_data_all.wf_passive_single{curr_animal}=wf_passive_3stage;
            temp_data_all.wf_passive_all_trace{curr_animal}=temp_wf_passive;

            temp_data_all.pupil_center{curr_animal}=pupil_center_data;
            temp_data_all.pupil_center_single{curr_animal}=pupil_center_3stage;
            temp_data_all.pupil_center_all_trace{curr_animal}=temp_pupil_center;

            temp_data_all.nose{curr_animal}=nose_data;
            temp_data_all.nose_single{curr_animal}=nose_3stage;
            temp_data_all.nose_all_trace{curr_animal}=temp_nose_passive;


            clearvars('-except',preload_vars{:});
        end

        all_data.([groups_name{curr_group} '_' modes_name{curr_mode}])=temp_data_all;

       

    end

end

 save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\sleap_data.mat') ,'all_data','-v7.3')

%% EDF J no package data
