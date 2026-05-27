clear

% Output root (script will create per-ID subfolders)
OUTPUT_ROOT = 'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil';
MODEL_DIRS = { 'D:\Data process\project_cross_model\face_data\sleap\pupil\251117_190801.centroid.n=625',...
    'D:\Data process\project_cross_model\face_data\sleap\pupil\251117_212458.centered_instance.n=625' };

animals =     { 'DS022','DS023','DS024','DS025'};


for curr_animal=1:length(animals)
    animal=animals{curr_animal};
    outDirID = fullfile(OUTPUT_ROOT, animal);
    if ~exist(outDirID, 'dir'), mkdir(outDirID); end
    recordings = plab.find_recordings(animal,[],'*');
    for curr_day =1:length(recordings)

        rec_day = recordings(curr_day).day;

        for curr_recording=1 :length(recordings(curr_day).recording)


            rec_time = recordings(curr_day).recording{curr_recording};
            workflow=recordings(curr_day).workflow{curr_recording};
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
        end
    end
end


