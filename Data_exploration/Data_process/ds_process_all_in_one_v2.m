clear all

Path = 'D:\Data process\project_cross_model\wf_data\data_package\';

Sleap_Paths = { ...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek', ...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil'};

surround_window = [-0.5, 1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);

animals = { ...
    'DS007','DS010','AP019','AP021','DS011','AP022', ...
    'DS000','DS004','DS014','DS015','DS016'};


workflows = { ...
    ['stim_wheel_right_stage1$|' ...
     'stim_wheel_right_stage2$|' ...
     'stim_wheel_right_stage1_opacity$|' ...
     'stim_wheel_right_stage2_opacity$|' ...
     'stim_wheel_right_stage1_angle$|' ...
     'stim_wheel_right_stage2_angle$|' ...
     'stim_wheel_right_stage2_angle_size60$|' ...
     'stim_wheel_right_stage1_size_up$|' ...
     'stim_wheel_right_stage2_size_up$|' ...
     'stim_wheel_right_stage1_audio_volume*$|' ...
     'stim_wheel_right_stage2_audio_volume*$|' ...
     'stim_wheel_right_stage1_audio_frequency$|' ...
     'stim_wheel_right_stage2_audio_frequency$|' ...
     'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
     'stim_wheel_right_stage2_mixed_VA$']; ...
    'lcr_passive'; ...
    'hml_passive_audio'};

% 想跑哪些 workflow   task, lcr_passive, hml_passive_audio
workflow_idx = [1 2 3];
% 例如只跑 1 和 3：
% workflow_idx = [1, 3];

% ====== 每个 workflow 的运行配置 ======
% run_behavior / run_wf_task / run_wf_passive / run_face
% field_* 用于把结果写回 data_all 的对应列
default_cfg = struct( 'run_behavior', false,  'run_wf_task', false, ...
    'run_wf_passive', false,  'run_face', false, 'field_task_name', '', ...
    'field_behavior', '', 'field_wf', '',  'field_face', '' );

cfg1 = default_cfg;
cfg1.run_behavior = 0;
cfg1.run_wf_task = 0;
cfg1.run_face = 1;
cfg1.field_task_name = 'task_name';
cfg1.field_behavior = 'behavior_task';
cfg1.field_wf = 'wf_task';
cfg1.field_face = 'face_task';

cfg2 = default_cfg;
cfg2.run_wf_passive = 0;
cfg2.run_face = 1;
cfg2.field_wf = 'wf_lcr_passive';
cfg2.field_face = 'face_lcr_passive';

cfg3 = default_cfg;
cfg3.run_wf_passive = 0;
cfg3.run_face = 1;
cfg3.field_wf = 'wf_hml_passive_audio';
cfg3.field_face = 'face_hml_passive_audio';

workflow_cfg = {cfg1, cfg2, cfg3};

% which kernels to process in task
 wf_task_prcoess_parts.stim = false;
 wf_task_prcoess_parts.move = false;
 wf_task_prcoess_parts.iti_move = false;
 wf_task_prcoess_parts.reward = false;
 wf_task_prcoess_parts.all_iti_move = false;

% which kernels to process in passive

passive_task_prcoess_parts.averaged_data = false;
passive_task_prcoess_parts.kernels = false;




for curr_animal = 9:length(animals)
    main_preload_vars = who;
    animal = animals{curr_animal};

    recordings = plab.find_recordings(animal, [], '*');
    % unique(cat(1,recordings.workflow))
    recordings = recordings(find(cellfun(@(x) any(x == 1), {recordings.widefield})));
    workflow_days = {recordings.day}';

    data_file = fullfile(Path, [animal '_all_data.mat']);

    if isfile(data_file)
        load(data_file);
        disp('文件已加载');
    else
        disp('文件不存在');

        data_all = table( ...
            'Size', [length(workflow_days) 9], ...
            'VariableTypes', {'cell','cell','cell','cell','cell','cell','cell','cell','cell'}, ...
            'VariableNames', {'day','task_name','behavior_task','wf_task', ...
                              'wf_lcr_passive','wf_hml_passive_audio', ...
                              'face_task','face_lcr_passive','face_hml_passive_audio'});
    end

    for curr_day = 1:length(workflow_days)
        preload_vars = who;
        rec_day = workflow_days{curr_day};
        data_all.day(curr_day) = {rec_day};

        for curr_workflow = workflow_idx
            workflow = workflows{curr_workflow};
            cfg = workflow_cfg{curr_workflow};

            temp_recording = plab.find_recordings(animal, rec_day, workflow);
            if isempty(temp_recording)
                continue;
            end

            [~, index_real] = max(cellfun(@(rt) ...
                numel(load(plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
                'timestamps').timestamps), temp_recording.recording));
            rec_time = temp_recording.recording{index_real};

            verbose = true;
            load_parts = struct;
            if cfg.run_behavior

                load_parts.behavior = true;
            end
            if cfg.run_face
                load_parts.mousecam = true;
            end
            if (cfg.run_wf_passive |cfg.run_wf_task)
                load_parts.widefield_master = true;
                load_parts.widefield = true;
            end
            ap.load_recording;

            % workflow 1 才有 task_name
            if ~isempty(cfg.field_task_name)
                data_all.(cfg.field_task_name){curr_day} = bonsai_workflow;
            end

            % behavior
            if cfg.run_behavior
                ds.process_behavior;
                data_all.(cfg.field_behavior){curr_day} = behavior;
            end

            % task widefield
            if cfg.run_wf_task
                ds.process_wf_task;
                % data_all.(cfg.field_wf){curr_day} = kernels;


                fn = fieldnames(kernels);
                for i = 1:numel(fn)
                    data_all.(cfg.field_wf){curr_day}.(fn{i}) = task_data.(fn{i});
                end


            end

            % passive widefield
            if cfg.run_wf_passive
                ds.process_wf_passive;
                data_all.(cfg.field_wf){curr_day} = passive_data;
            end

            % face tracking
            if cfg.run_face
                ds.process_face_tracking;
                data_all.(cfg.field_face){curr_day} = sleap_data;
            end
        end

        clearvars('-except', preload_vars{:});
    end

    save(data_file, 'data_all', '-v7.3');

    clearvars('-except', main_preload_vars{:});
end



