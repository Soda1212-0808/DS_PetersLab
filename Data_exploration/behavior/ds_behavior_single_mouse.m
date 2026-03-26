%% Behavior across days
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

% animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
% animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';
% % animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';
% animals = {'DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
% animals =     {
%              
% 
% .
% 'AP027','AP028','DS019','DS020','DS021',...
%                     'AP027','AP028','AP029',...
%                     'HA003','HA004','DS019','DS020','DS021',...
%                     'HA000','HA001','HA002'};
% 
% animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022',...
%     'DS000','DS004','DS014','DS015','DS016',...
%     'AP018','AP020','DS006','DS013',...
%     'AP027','AP028','DS019','DS020','DS021',...
%     'AP027','AP028','AP029',...
%     'HA003','HA004','DS019','DS020','DS021',...
%     'HA000','HA001','HA002','DS005'};
 animals={'AP019'}
% reaction_time=2;
% Grab learning day for each mouse
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);



for curr_animal_idx = 1:length(animals)

    animal = animals{curr_animal_idx};


    use_workflow =...
        ['stim_wheel_right_stage1$|' ...
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
        'stim_wheel_right_stage2_mixed_VA$'];

    % use_workflow=['stim_wheel_right_stage1_no_change$|' 'stim_wheel_right_stage2_no_change$|'];
    % use_workflow =...
    %     ['stim_wheel_right_stage1$|' ...
    %     'stim_wheel_right_stage2$|' ...
    %     'stim_wheel_right_stage1_audio_volume$|'...
    %     'stim_wheel_right_stage2_audio_volume$|' ...
    %     'stim_wheel_right_stage1_audio_frequency$|' ...
    %     'stim_wheel_right_stage2_audio_frequency$|' ...
    %     'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
    %     'stim_wheel_right_stage2_mixed_VA$'];

    recordings = plab.find_recordings(animal,[],use_workflow);
    %只保留widefiled的数据
     recordings(find([recordings.ephys])) = [];


    workflow_day={recordings.day}';


     % n_trials_water = nan(length(recordings),2);
    % frac_move_day = nan(length(recordings),1);
    % success = nan(length(recordings),1);
    % rxn_med = nan(length(recordings),1);
    stim_on2off_times=cell(length(recordings),3);

    stim2move_times=cell(length(recordings),3);
    stim2lastmove_times=cell(length(recordings),3);

    stim2move_mean = nan(length(recordings),3);
    stim2lastmove_mad = nan(length(recordings),3);
    stim2move_med = nan(length(recordings),3);
    stim2move_mean_null = nan(length(recordings),3);
    stim2lastmove_mad_null = nan(length(recordings),3);
    stim2move_med_null = nan(length(recordings),3);

    stim2move_mad= nan(length(recordings),3);
    stim2move_mad_null = nan(length(recordings),3);

    stim2lastmove_mean = nan(length(recordings),3);
    stim2lastmove_mean_null = nan(length(recordings),3);

    stim2lastmove_med = nan(length(recordings),3);
    stim2lastmove_med_null = nan(length(recordings),3);

    frac_move_stimalign =cell(length(recordings),1);
    frac_velocity_stimalign=cell(length(recordings),1);

    % frac_move_stimalign_trialbytrial =cell(length(recordings),1);
    % frac_velocity_stimalign_trialbytrial=cell(length(recordings),1);
    rxn_f_mean_p = nan(length(recordings),3);
    rxn_f_med_p = nan(length(recordings),3);
    rxn_f_mad_p = nan(length(recordings),3);

    rxn_l_mean_p = nan(length(recordings),3);
    rxn_l_med_p = nan(length(recordings),3);
    rxn_l_mad_p = nan(length(recordings),3);

    workflow_name= cell(length(recordings),1);
    workflow_name_full=cell(length(recordings),1);
    trials_success= nan(length(recordings),1);
    iti_move= cell(length(recordings),1);
    all_iti_move= cell(length(recordings),1);
iti_counts=cell(length(recordings),1);
iti_counts_all=cell(length(recordings),1);
    workflow_type=zeros(length(recordings),1);

    % figure
    for curr_recording =1: length(recordings)

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
        workflow_name_full{curr_recording}=recordings(curr_recording).workflow{index_real};

        if strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')
            workflow_name{curr_recording}='audio volume';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2')
            workflow_name{curr_recording}='visual position';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_angle')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_angle_size60')
            workflow_name{curr_recording}='visual angle';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_size_up')
            workflow_name{curr_recording}='visual size up';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_opacity')
            workflow_name{curr_recording}='visual opacity';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')
            workflow_name{curr_recording}='audio frequency';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
            workflow_name{curr_recording}='mixed VA';
        else  workflow_name{curr_recording}='none';
        end

        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;


        if  strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_mixed_VA')...
                || strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_frequency_stage2_mixed_VA')
            workflow_type(curr_recording)=2;
        else
            workflow_type(curr_recording)=1;
        end



        %% how many successful trials
        n_trials_success=sum(cat(1,trial_events.values.Outcome));
        trials_success(curr_recording)=n_trials_success;
        % success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;



        % 计算 iti move的时间点
       ds.load_iti_move

        iti_move{curr_recording}=iti_move_time;

        all_iti_move{curr_recording}=wheel_starts(iti_move_idx);

        iti_counts{curr_recording} = histcounts(iti_move_time, [0; stimOn_times]);
        iti_counts_all{curr_recording}= histcounts(wheel_starts(iti_move_idx), [0; stimOn_times]);

      

        % Get median stim-outcome time
        n_trials = length([trial_events.values.Outcome]);

        stim2move_times{curr_recording}=stim_to_move;
        stim2lastmove_times{curr_recording}=stim_to_lastmove;


        % frac_move_day(curr_recording) = nanmean(wheel_move);
        % wheel_move_direction=double(wheel_move);
        % wheel_move_direction(wheel_move==1&wheel_velocity<0)=-1;

        % Align wheel movement to stim onset
        pull_times = stim_move_time + surround_time_points;
        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');

        frac_move_stimalign{curr_recording,1}=event_aligned_wheel_move;
        frac_velocity_stimalign{curr_recording,1} = event_aligned_wheel_vel;



        stim_on2off_times{curr_recording,1}=stimOff_times(1:n_trials) - ...
            stimOn_times(1:n_trials);


        if workflow_type(curr_recording)==2
            % Get task type
            tasktype=[trial_events.values.TaskType];

            stim_on2off_times{curr_recording,2}=stim_on2off_times{curr_recording}(find(tasktype(1:n_trials)==0));
            stim_on2off_times{curr_recording,3}=stim_on2off_times{curr_recording}(find(tasktype(1:n_trials)==1));

            stim2move_times{curr_recording,2}=stim_to_move(find(tasktype(1:n_trials)==0));
            stim2move_times{curr_recording,3}=stim_to_move(find(tasktype(1:n_trials)==1));

            stim2lastmove_times{curr_recording,2}=stim_to_lastmove(find(tasktype(1:n_trials)==0));
            stim2lastmove_times{curr_recording,3}=stim_to_lastmove(find(tasktype(1:n_trials)==1));

            frac_move_stimalign{curr_recording,2}=event_aligned_wheel_move(find(tasktype(1:n_trials)==0),:);
            frac_velocity_stimalign{curr_recording,2} = event_aligned_wheel_vel(find(tasktype(1:n_trials)==0),:);
            frac_move_stimalign{curr_recording,3}=event_aligned_wheel_move(find(tasktype(1:n_trials)==1),:);
            frac_velocity_stimalign{curr_recording,3} = event_aligned_wheel_vel(find(tasktype(1:n_trials)==1),:);




            [rxn_f_mean_p(curr_recording,:), stim2move_mean(curr_recording,:),stim2move_mean_null(curr_recording,:)]=...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_move,tasktype,'mean');

            [rxn_f_med_p(curr_recording,:), stim2move_med(curr_recording,:),stim2move_med_null(curr_recording,:)] = ...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_move,tasktype,'median');

            [rxn_f_mad_p(curr_recording,:), stim2move_mad(curr_recording,:),stim2move_mad_null(curr_recording,:)] = ...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_move,tasktype,'mad');


            [rxn_l_mean_p(curr_recording,:), stim2lastmove_mean(curr_recording,:),stim2lastmove_mean_null(curr_recording,:)] = ...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_lastmove,tasktype,'mean');

            [rxn_l_med_p(curr_recording,:), stim2lastmove_med(curr_recording,:),stim2lastmove_med_null(curr_recording,:)] = ...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_lastmove,tasktype,'median');

            [rxn_l_mad_p(curr_recording,:), stim2lastmove_mad(curr_recording,:),stim2lastmove_mad_null(curr_recording,:)] = ...
                AP_stimwheel_association_pvalue2( ...
                stimOn_times,trial_events,stim_to_lastmove,tasktype,'mad');

        

        else

            % Get association stat
            % rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
            %     stimOn_times,trial_events,stim_to_move);
            % Get association stat
            [rxn_f_mean_p(curr_recording), stim2move_mean(curr_recording),stim2move_mean_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_move,'mean');

            [rxn_f_med_p(curr_recording), stim2move_med(curr_recording),stim2move_med_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_move,'median');

            [rxn_f_mad_p(curr_recording), stim2move_mad(curr_recording),stim2move_mad_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_move,'mad');

            [rxn_l_mean_p(curr_recording), stim2lastmove_mean(curr_recording),stim2lastmove_mean_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_lastmove,'mean');

            [rxn_l_med_p(curr_recording), stim2lastmove_med(curr_recording),stim2lastmove_med_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_lastmove,'median');

            [rxn_l_mad_p(curr_recording), stim2lastmove_mad(curr_recording),stim2lastmove_mad_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
                stimOn_times,trial_events,stim_to_lastmove,'mad');

        end


        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings));

    end


    save([Path 'behavior\' animal '_behavior.mat' ],'workflow_day','workflow_name',...
        'rxn_l_mean_p','rxn_f_mean_p','rxn_l_med_p','rxn_f_med_p','rxn_l_mad_p','rxn_f_mad_p',...
        'workflow_name_full','stim2lastmove_mean','stim2lastmove_mean_null','stim2lastmove_med','stim2lastmove_med_null',...
        'stim2move_med','stim2lastmove_mad','stim2move_mean','stim2move_mean_null','stim2move_med_null',...
        'stim2lastmove_mad_null','frac_move_stimalign','frac_velocity_stimalign',...
        'iti_move','all_iti_move','iti_counts','iti_counts_all',...
        'stim2move_times','stim2lastmove_times','stim_on2off_times','stim2move_mad','stim2move_mad_null','trials_success','-v7.3');

end


