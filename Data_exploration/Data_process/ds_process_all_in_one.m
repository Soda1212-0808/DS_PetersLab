clear all

Path = 'D:\Data process\project_cross_model\wf_data\data_package\';

Sleap_Paths={'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek',...
    'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil'};

surround_window = [-0.5,1];
mousecam_framerate = 30;
time_period = surround_window(1):1/mousecam_framerate:surround_window(2);

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
    'stim_wheel_right_stage2_mixed_VA$'];...
    'lcr_passive';'hml_passive_audio'};

% ====== workflow 选择 ======
workflow_idx = [1, 2, 3];   % 想跑哪些 workflow，就保留哪些编号

% ====== 每个 workflow 需要运行哪些 process ======
% 顺序固定为：
% 1 = ds.process_behavior
% 2 = ds.process_wf_task / ds.process_wf_passive
% 3 = ds.process_face_tracking
proc_cfg = {
    struct('behavior', true,  'wf_task', true,  'wf_passive', false, 'face', true),  ... % workflow 1
    struct('behavior', false, 'wf_task', false, 'wf_passive', true,  'face', true),  ... % workflow 2
    struct('behavior', false, 'wf_task', false, 'wf_passive', true,  'face', true)       % workflow 3
};



animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
    'DS000','DS004','DS014','DS015','DS016'};


for curr_animal=1:length(animals)
    main_preload_vars = who;
    animal=animals{curr_animal};
    recordings=plab.find_recordings(animal,[],'*');
    recordings=recordings(find(cellfun(@(x) any(x == 1), {recordings.widefield})));
    workflow_days={recordings.day}';

    if isfile(fullfile(Path,[animal '_all_data.mat']))
        load(fullfile(Path,[animal '_all_data.mat']));
        disp('文件已加载');
    else
        disp('文件不存在');

    data_all=table( 'Size', [length(workflow_days) 9], 'VariableTypes',{'cell','cell','cell','cell','cell','cell','cell','cell','cell'},...
        'VariableNames', {'day','task_name','behavior_task','wf_task', ...
        'wf_lcr_passive','wf_hml_passive_audio','face_task', 'face_lcr_passive','face_hml_passive_audio'});
    end

    for curr_day=1:length(workflow_days)
        preload_vars = who;

        rec_day=workflow_days{curr_day};
        data_all.day(curr_day)={rec_day};
        for curr_workflow=workflow_idx
            workflow=workflows{curr_workflow};
            temp_recording=plab.find_recordings(animal,rec_day,workflow);
            if isempty(temp_recording)
                continue;
            end

            [~,index_real]=max( cellfun(@(rt) ...
                numel(load( ...
                plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
                'timestamps').timestamps), ...
                temp_recording.recording));
            rec_time = temp_recording.recording{index_real};

            verbose=true;
            load_parts = struct;
            load_parts.behavior = true;
            load_parts.mousecam = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;

            switch curr_workflow
                case 1
                    data_all.task_name{curr_day}=bonsai_workflow;
                    ds.process_behavior
                    data_all.behavior_task{curr_day}=behavior;

                    wf_task_prcoess_parts.stim=true;
                    ds.process_wf_task;
                    data_all.wf_task{curr_day}=kernels;

                    ds.process_face_tracking;
                    data_all.face_task{curr_day}=face_data;

                case 2
                    ds.process_wf_passive
                    data_all.wf_lcr_passive{curr_day}=kernels;

                    ds.process_face_tracking
                    data_all.face_lcr_passive{curr_day}=face_data;
                case 3
                    ds.process_wf_passive
                    data_all.wf_hml_passive_audio{curr_day}=kernels;

                    ds.process_face_tracking
                    data_all.face_hml_passive_audio{curr_day}=face_data;
            end
        end
        clearvars('-except',preload_vars{:});

    end


    save(fullfile(Path,[animal '_all_data.mat']),'data_all','-v7.3')

    clearvars('-except',main_preload_vars{:});

end





