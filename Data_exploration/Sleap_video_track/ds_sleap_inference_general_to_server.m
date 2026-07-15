clear
sleap_versions={'nose_v1','pupil_v1'};

for curr_verion=1:length(sleap_versions)
    sleap_version=sleap_versions{curr_verion};

    parentDir = fullfile(plab.locations.server_path, 'Lab', 'sleap_models', sleap_version);
    temp_d = dir(parentDir);
    MODEL_DIRS = fullfile(parentDir, {temp_d([temp_d.isdir] & ~ismember({temp_d.name}, {'.','..'})).name});

    today = char(datetime('today','Format','yyyy-MM-dd'));

    folderNames= {dir(plab.locations.server_data_path).name};
    animals=folderNames(~ismember(folderNames,{'.','..'}));

    for curr_animal=1:length(animals)
        animal=animals{curr_animal};
        % if ~exist(outDirID, 'dir'), mkdir(outDirID); end
        recordings = plab.find_recordings(animal,today,'*');
        rec_day = today;

        if ~isempty(recordings)
            for curr_recording=1 :length(recordings.recording)

                rec_time = recordings.recording{curr_recording};
                workflow=recordings.workflow{curr_recording};
                mousecam_fn = plab.locations.filename('server',animal,rec_day,rec_time,'mousecam','mousecam.mj2');
                if isfile(mousecam_fn)

                    outBase = sprintf('%s_%s_Recording_%s_%s', animal, rec_day, rec_time, 'mousecam');
                    outDirID = plab.locations.filename('server',animal,rec_day,rec_time,'mousecam',sleap_version);

                    if ~exist(outDirID, 'dir'), mkdir(outDirID); end

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
    end

end