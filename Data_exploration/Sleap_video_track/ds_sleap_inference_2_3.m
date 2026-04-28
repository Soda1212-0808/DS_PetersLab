clear 

% Output root (script will create per-ID subfolders)
OUTPUT_ROOT = 'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil';
MODEL_DIRS = { 'D:\Data process\project_cross_model\face_data\sleap\pupil\251117_190801.centroid.n=625',...
               'D:\Data process\project_cross_model\face_data\sleap\pupil\251117_212458.centered_instance.n=625' };

% OUTPUT_ROOT = 'D:\Data process\project_cross_model\face_data\sleap\track_data\nose_cheek';
% MODEL_DIRS = { 'D:\Data process\project_cross_model\face_data\sleap\nose_cheek\models\260310_142421.centroid.n=376',...
%                'D:\Data process\project_cross_model\face_data\sleap\nose_cheek\models\260310_145117.centered_instance.n=376' };
%


animals =     { 'AP030','AP032','DS030','DS031','DS029'};

training_workflow ='stim_wheel_right_stage2';
passive_workflow = 'lcr_passive';

for curr_animal=1:length(animals)

    animal=animals{curr_animal};

    outDirID = fullfile(OUTPUT_ROOT, animal);
    if ~exist(outDirID, 'dir'), mkdir(outDirID); end


    recordings_passive = plab.find_recordings(animal,[],passive_workflow);
    recordings_training = plab.find_recordings(animal,[],training_workflow);
    red_days=intersect({recordings_passive(find(cellfun(@length ,{recordings_passive.index},'UniformOutput',true)==2)).day },...
        {recordings_training(find(cellfun(@length ,{recordings_training.index},'UniformOutput',true)==2)).day });

    recordings_passive=plab.find_recordings(animal,red_days{1},passive_workflow);
    for curr_recording_passive=1:2
        % Grab pre-load vars
        preload_vars = who;
        rec_day=red_days{1};
        rec_time = recordings_passive.recording{curr_recording_passive};
        workflow=recordings_passive.workflow  {curr_recording_passive};
        mousecam_fn = plab.locations.filename('server',animal,rec_day,rec_time,'mousecam','mousecam.mj2');


        outBase = sprintf('%s_%s_Recording_%s_%s', animal, rec_day, rec_time, 'mousecam');
        outSLP = fullfile(outDirID, [outBase, '.pred.slp']);
        outH5  = fullfile(outDirID, [outBase, '.analysis.h5']);
        if isfile(outSLP)
            fprintf('File exists, skip %s.\n', outSLP);
            continue;   % 跳过本次循环
        end

        fprintf('\n Processing: %s  %s    %s\n', animal, workflow,rec_day);

        ds.sleap_inference(MODEL_DIRS,mousecam_fn,outSLP,outH5)
        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});

    end

    recordings_task=plab.find_recordings(animal,red_days{1},training_workflow);
    for curr_recording_task=1:2
        preload_vars = who;

        rec_day=red_days{1};
        rec_time = recordings_task.recording{curr_recording_task};
        workflow=recordings_task.workflow{curr_recording_task};
        mousecam_fn = plab.locations.filename('server',animal,rec_day,rec_time,'mousecam','mousecam.mj2');

        outBase = sprintf('%s_%s_Recording_%s_%s', animal, rec_day, rec_time, 'mousecam');
        outSLP = fullfile(outDirID, [outBase, '.pred.slp']);
        outH5  = fullfile(outDirID, [outBase, '.analysis.h5']);
        if isfile(outSLP)
            fprintf('File exists, skip %s.\n', outSLP);
            continue;   % 跳过本次循环
        end

        fprintf('\n Processing: %s  %s    %s\n', animal, workflow,rec_day);

        ds.sleap_inference(MODEL_DIRS,mousecam_fn,outSLP,outH5)
        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});


    end

end

