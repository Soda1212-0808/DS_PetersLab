% % Alignment summary
% 
% % Define animal
% animal = 'DS000';
% % Create across-day alignments
% plab.wf.wf_align([],animal,[],'new_days');
% % Get and save VFS maps for animal
% plab.wf.retinotopy_vfs_batch(animal);
% % Create across-animal alignments
% plab.wf.wf_align([],animal,[],'new_animal');
% 

%% 
clear all
 Path='C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\';
animals = {'DS000'};

for curr_animal_idx = 1:length(animals)

   
animal=animals{curr_animal_idx};

%save data
data_merge(curr_animal_idx).animal=animal;

stage=5;

for curr_stage=1:stage

if curr_stage==4
passive_workflow = 'hml_passive_audio';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'stim_wheel_right_stage2_audio_volume';
recordings_training = plab.find_recordings(animal,[],training_workflow);

recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ~[recordings_passive.ephys] & ...
    ismember({recordings_passive.day},{recordings_training.day}));


elseif curr_stage==1
    passive_workflow = 'lcr_passive';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'stim_wheel_right_stage2';
recordings_training = plab.find_recordings(animal,[],training_workflow);

recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ~[recordings_passive.ephys] & ...
    ismember({recordings_passive.day},{recordings_training.day}));

elseif curr_stage==2
    passive_workflow = 'hml_passive_audio';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'stim_wheel_right_stage2';
recordings_training = plab.find_recordings(animal,[],training_workflow);

recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ~[recordings_passive.ephys] & ...
    ismember({recordings_passive.day},{recordings_training.day}));

elseif curr_stage==3
    passive_workflow = 'lcr_passive';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'stim_wheel_right_stage2_audio_volume';
recordings_training = plab.find_recordings(animal,[],training_workflow);

recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ~[recordings_passive.ephys] & ...
    ismember({recordings_passive.day},{recordings_training.day}));

elseif curr_stage==5
    passive_workflow = 'lcr_passive';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'stim_wheel_right_stage*';
recordings_training = plab.find_recordings(animal,[],training_workflow);

recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ~[recordings_passive.ephys] & ...
    ismember({recordings_passive.day},{recordings_training.day}));
end

stage=[passive_workflow ' && ' training_workflow];



% %定义行为学变量，在循环后不会被清空
% rxn_med = nan(length(recordings),1);
% rxn_stat_p = nan(length(recordings),1);

if curr_stage==5
    length_day=3;
    wf_px = cell([1,3]);
    recording_date=cell([1,3]);
else length_day=length(recordings);
    wf_px = cell(size(recordings));
    recording_date=cell(size(recordings));
end

for curr_recording = 1:length_day


    % Grab pre-load vars
    preload_vars = who;

    % Load data
    rec_day = recordings(curr_recording).day;
  
    recording_date{curr_recording}=recordings(curr_recording).day;
    rec_time = recordings(curr_recording).recording{end};
    if ~recordings(curr_recording).widefield(end)
        continue
    end

    try
        load_parts.widefield = true;
        ds.load_recording;
    catch me
        warning('%s %s %s: load error, skipping \n >> %s', ...
            animal,rec_day,rec_time,me.message)
        continue
    end

    % Get quiescent trials and stim onsets/ids
    stim_window = [0,0.5];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times))';

    align_times = stimOn_times(quiescent_trials);
    % 不同的stage对应不同的参数
    if strcmp(passive_workflow,'lcr_passive')
        align_category_all = vertcat(trial_events.values.TrialStimX);
    elseif strcmp(passive_workflow,'hml_passive_audio')
    align_category_all = vertcat(trial_events.values.StimFrequence);
    end
    align_category = align_category_all(quiescent_trials);

    % Align to stim onset
    surround_window = [-0.5,1];
    surround_samplerate = 35;
    t = surround_window(1):1/surround_samplerate:surround_window(2);
    peri_event_t = reshape(align_times,[],1) + reshape(t,1,[]);

[U_master,V_master] = plab.wf.u2master(wf_U,wf_V);



    aligned_v = reshape(interp1(wf_t,V_master',peri_event_t,'previous'), ...
        length(align_times),length(t),[]);

    align_id = findgroups(align_category);
    aligned_v_avg = permute(splitapply(@nanmean,aligned_v,align_id),[3,2,1]);
    aligned_v_avg_baselined = aligned_v_avg - nanmean(aligned_v_avg(:,t < 0,:),2);

    % Convert to pixels and package
   
    % aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
    wf_px{curr_recording} = aligned_v_avg_baselined;





    % Prep for next loop
    ap.print_progress_fraction(curr_recording,length(recordings));
    clearvars('-except',preload_vars{:});

end
data_passive(curr_stage).image=wf_px;
data_passive(curr_stage).recording_date=recording_date;
data_passive(curr_stage).stage=stage;

% data_merge(curr_animal_idx).imagedata_passive(curr_stage).data=wf_px;
% data_merge(curr_animal_idx).imagedata_passive(curr_stage).recording_date=recording_date;
% data_merge(curr_animal_idx).imagedata_passive(curr_stage).stage=stage;

end
 current_time = datestr(now, 'yyyy-mm-dd_HH-MM');
save([Path 'buffer_' animal '_passive_' current_time '.mat'], 'data_passive', '-v7.3')
save([Path 'process_' animal '_passive.mat'], 'data_passive', '-v7.3')

% data_merge(curr_animal_idx).learned_day=learned_day;
end





