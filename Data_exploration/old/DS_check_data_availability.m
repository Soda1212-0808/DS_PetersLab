clear all


animals = {'AP018','AP019','AP020','AP021','AP022','AP027','AP028','AP029','DS000','DS001','DS003','DS004',...
    'DS005','DS006','DS007','DS010','DS011','DS013','DS014','DS015','DS016','HA003','HA004'};
passive_workflow = 'lcr_passive';
    training_workflow = {'stim_wheel_right_stage1*$|stim_wheel_right_stage2*$|stim_wheel_right_frequency_stage2_mixed_VA$'};

all_valid=struct;


for curr_animal=1:length(animals)

    animal=animals{curr_animal};
    all_valid(curr_animal).name=animal;

    fprintf('%s\n', ['start  ' animal ]);


    recordings_passive = plab.find_recordings(animal,[],passive_workflow);
    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings2 =[recordings_passive(1:3) recordings_passive( ...
        cellfun(@any,{recordings_passive.widefield}) & ...
        ~[recordings_passive.ephys] & ...
        ismember({recordings_passive.day},{recordings_training.day}))];

    recordings = recordings_training( ...
        cellfun(@any,{recordings_training.widefield}) & ...
        ~[recordings_training.ephys] & ...
        ismember({recordings_training.day},{recordings_passive.day}));

    valid_idx=nan(length(recordings),1);
    valid_day=cell(length(recordings),1);
    for curr_recording =1:length(recordings)
        % for curr_recording =1:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(recordings),curr_recording);

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings(curr_recording).day;
        clear time
        if length(recordings(curr_recording).index)>1
            for mm=1:length(recordings(curr_recording).index)
                rec_time = recordings(curr_recording).recording{mm};
                % verbose = true;
                % ap.load_timelite

                timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                timelite = load(timelite_fn);
                time(mm)=length(timelite.timestamps);
            end
            [~,index_real]=max(time);
        else index_real=1;
        end

        rec_time = recordings(curr_recording).recording{index_real};

        valid_day{curr_recording}=rec_day;
        try
            verbose=true;
            load_parts = struct;
            load_parts.behavior = true;
            load_parts.mousecam = true;
            load_parts.widefield = true;
            load_parts.widefield_master = true;
            ap.load_recording;
            valid_idx(curr_recording)=1;
        catch me
            warning('%s %s %s: load error, skipping \n >> %s', ...
                animal,rec_day,rec_time,me.message)
            continue
        end

        ap.print_progress_fraction(curr_recording,length(recordings));
        clearvars('-except',preload_vars{:});


    end

    all_valid(curr_animal).idx=valid_idx;
        all_valid(curr_animal).date=valid_day;

end

