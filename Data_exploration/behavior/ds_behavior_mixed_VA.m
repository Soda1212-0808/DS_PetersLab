%% Behavior across days
clear all
Path = 'D:\Data process\wf_data\';

 % animals = {'DS007','DS010','AP021','DS011','DS001','AP018','AP022'};n1_name='visual position';n2_name='audio volume'; index_group=[1  1 1 1 0 0 0  ]';
% animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';index_group=[0 0 0 1 1 1 1 1 ];
% animals = {'DS020','DS019','DS021'};n1_name='visual position';n2_name='audio frequency'; index_group=[1  1 1 1 0 0 0  ]';
 animals = {'DS025','DS024','DS023','DS022'};
p_para='mean';


 learned_day_all = nan(size(animals));
 all_animal_react_index=cell(length(animals),1);
 all_animal_learned_day=cell(length(animals),1);
 all_animal_rxn_med=cell(length(animals),1);
 all_animal_stim2move_med=cell(length(animals),1);
 all_animal_stim2move_mad=cell(length(animals),1);
 all_animal_stim2move_mean=cell(length(animals),1);
  all_animal_stim2move_med_null=cell(length(animals),1);
 all_animal_stim2move_mad_null=cell(length(animals),1);
 all_animal_stim2move_mean_null=cell(length(animals),1);
all_animal_frac_move_V=cell(length(animals),1);
all_animal_frac_move_A=cell(length(animals),1);

all_animal_frac_success=cell(length(animals),1);

figure('Position',[50 50 length(animals)*300 900]);
tt = tiledlayout(1,length(animals),'TileSpacing','tight');
for curr_animal_idx = 1:length(animals)
    animal = animals{curr_animal_idx};

    % use_workflow = {'stim_wheel_right_stage2_mixed_VA'};
      use_workflow =...
       [ 'stim_wheel_Vcenter_cross_movement_stage*'];

    recordings = plab.find_recordings(animal,[],use_workflow);
    % only ephys data
     % recordings(find([recordings.widefield])) = [];

     % recordings(find([recordings.ephys])) = [];

    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_water = nan(length(recordings),2);
    n_trials_water_V = nan(length(recordings),1);
    n_trials_water_A = nan(length(recordings),1);
    frac_move_day = nan(length(recordings),1);

    success = nan(length(recordings),2);
    success_V = nan(length(recordings),1);
    success_A = nan(length(recordings),1);
    rxn_med = nan(length(recordings),2);
    stim2move_med = nan(length(recordings),3);
    stim2move_mean = nan(length(recordings),3);
    stim2move_mad = nan(length(recordings),3);

 stim2move_med_null = nan(length(recordings),3);
    stim2move_mean_null = nan(length(recordings),3);
    stim2move_mad_null = nan(length(recordings),3);

    frac_move_stimalign = nan(length(recordings),length(surround_time_points));
    frac_move_stimalign_1 = nan(length(recordings),length(surround_time_points));
    frac_move_stimalign_2 = nan(length(recordings),length(surround_time_points));

    rxn_stat_p_mean = nan(length(recordings),3);
    workflow_name= nan(length(recordings),1);
n_trials_types= nan(length(recordings),2);
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


        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;

        % Get task types
        No_tasktype=unique([trial_events.values.TaskType]);

        tasktype=[trial_events.values.TaskType];


        % Get total trials/water
        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
            sum(([trial_events.values.Outcome] == 1)*6)];


        % Get median stim-outcome time
        n_trials = length([trial_events.timestamps.Outcome]);

        stim_on2off_time=arrayfun(@(type) seconds([trial_events.timestamps(find(tasktype(1:n_trials)==type)).Outcome] - ...
            cellfun(@(x) x(1),{trial_events.timestamps(find(tasktype(1:n_trials)==type)).StimOn})),No_tasktype,'UniformOutput',false);

        n_trials_types(curr_recording,:)=cellfun(@length,stim_on2off_time,'UniformOutput',true);
  
        rxn_med(curr_recording,:)   = cellfun(@median, stim_on2off_time,'UniformOutput',true);


        % Align wheel movement to stim onset
        align_times = stimOn_times;
        pull_times = align_times + surround_time_points;

        % success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;
outcome=cat(1,trial_events.values.Outcome);
success(curr_recording,:)=[sum(outcome(tasktype(1:n_trials)==0))/length(outcome(tasktype(1:n_trials)==0));...
sum(outcome(tasktype(1:n_trials)==1))/length(outcome(tasktype(1:n_trials)==1))];

        frac_move_day(curr_recording) = nanmean(wheel_move);

        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');

        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);
        frac_move_stimalign_1(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==0,:),1);
        frac_move_stimalign_2(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==1,:),1);
        % Get association stat
        % rxn_stat_p_mean(curr_recording,:) = AP_stimwheel_association_pvalue2( ...
        %     stimOn_times,trial_events,stim_to_move,tasktype,p_para);
        %
        [useless_p, stim2move_mean(curr_recording,:),stim2move_mean_null(curr_recording,:)]=...
            AP_stimwheel_association_pvalue2( ...
            stimOn_times,trial_events,stim_to_move,tasktype,'mean');

        [rxn_stat_p_mean(curr_recording,:), stim2move_mad(curr_recording,:),stim2move_mad_null(curr_recording,:)] = ...
            AP_stimwheel_association_pvalue2( ...
            stimOn_times,trial_events,stim_to_lastmove,tasktype,'mad');

        [useless_p, stim2move_med(curr_recording,:),stim2move_med_null(curr_recording,:)] = ...
            AP_stimwheel_association_pvalue2( ...
            stimOn_times,trial_events,stim_to_move,tasktype,'median');


        %  % Get association stat
        % rxn_stat_p(curr_recording,:) = AP_stimwheel_association_pvalue( ...
        %     stimOn_times,trial_events,stim_to_move);


        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings));

    end

    % Define learned day from reaction stat p-value and reaction time
    learned_day = rxn_stat_p_mean(:,2:3) < 0.05 & rxn_med < 2;


    relative_day = days(datetime({recordings.day}) - datetime({recordings(1).day}))+1;
    nonrecorded_day = setdiff(1:length(recordings),relative_day);


    % Draw in tiled layout nested in master
    t_animal = tiledlayout(tt,7,1);
    t_animal.Layout.Tile =  curr_animal_idx;
    title(t_animal,animal);

    %%plot from  3 days before the first association day
    % range_t1= relative_day(find(learned_day == 1, 1, 'first'))-3;
    range_t1=1;

    nexttile(t_animal);
    yyaxis left;
    hold on; 
    plot(relative_day,n_trials_types);
    ylabel('# trials');
    yyaxis right; plot(relative_day,frac_move_day);
    ylabel('Fraction time moving');
    xlabel('Day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    % if any(learned_day)
    %     xline(relative_day(learned_day(:,1)),'g');
    %     xline(relative_day(learned_day(:,2)),'b');
    %     xline(relative_day(learned_day(:,2)&learned_day(:,1)),'r');
    % end

    % xlim([range_t1,relative_day(end)])



    nexttile(t_animal);

    yyaxis left
    % plot(relative_day,rxn_med,'LineWidth',1)
        plot(relative_day,stim2move_med,'LineWidth',1)

    set(gca,'YScale','log');
    ylabel('Med. rxn');
    xlabel('Day');

    yyaxis right
    prestim_max(:,1) = max(frac_move_stimalign_1(:,surround_time_points < 0),[],2);
    poststim_max(:,1) = max(frac_move_stimalign_1(:,surround_time_points > 0),[],2);
    prestim_max(:,2) = max(frac_move_stimalign_2(:,surround_time_points < 0),[],2);
    poststim_max(:,2) = max(frac_move_stimalign_2(:,surround_time_points > 0),[],2);
    plot(relative_day,(poststim_max-prestim_max)./(poststim_max+prestim_max));
    
    
    pre_time=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
    post_time=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
    react_index=(post_time-pre_time)./(post_time+pre_time);

    yline(0);
    ylabel('pre/post move idx');
    xlabel('Day');
    xlim([range_t1,relative_day(end)]);
    clear prestim_max poststim_max
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day(:,1)),'g');
        xline(relative_day(learned_day(:,2)),'b');
        if sum(learned_day(:,2)&learned_day(:,1))>0
        xline(relative_day(learned_day(:,2)&learned_day(:,1)),'r');
        end
    end



    nexttile(t_animal);
    imagesc(surround_time_points,[],frac_move_stimalign_1); hold on;
    clim([0,1]);
    colormap(gca,ap.colormap('WK'));
    set(gca,'YTick',1:length(recordings),'YTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    xlabel('Time from stim');
    title('Type 1')
    if any(learned_day(:,1))
        plot(0,find(learned_day(:,1)),'.g')
    end


    nexttile(t_animal);
    imagesc(surround_time_points,[],frac_move_stimalign_2); hold on;
    clim([0,1]);
    colormap(gca,ap.colormap('WK'));
    set(gca,'YTick',1:length(recordings),'YTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    xlabel('Time from stim');
    title('Type 2')
    if any(learned_day(:,2))
        plot(0,find(learned_day(:,2)),'.g')
    end




    nexttile(t_animal); hold on
    set(gca,'ColorOrder',copper(length(recordings)));

    %plot(surround_time_points,frac_move_stimalign','linewidth',2);
    plot(surround_time_points,frac_move_stimalign_1(1:end,:)','linewidth',2);

    xline(0,'color','k');
    ylabel('Fraction moving');
    xlabel('Time from stim');
    if any(learned_day)
        ap.errorfill(surround_time_points,frac_move_stimalign_1(learned_day(:,1),:)', ...
            0.02,[0,1,0],0.1,false);

        % % Store learned day across animals
        % learned_day_all(curr_animal_idx) = find(learned_day,1);
    end

    nexttile(t_animal); hold on
    set(gca,'ColorOrder',copper(length(recordings)));

    %plot(surround_time_points,frac_move_stimalign','linewidth',2);
    plot(surround_time_points,frac_move_stimalign_2(1:end,:)','linewidth',2);

    xline(0,'color','k');
    ylabel('Fraction moving');
    xlabel('Time from stim');
    if any(learned_day)
        ap.errorfill(surround_time_points,frac_move_stimalign_2(learned_day(:,2),:)', ...
            0.02,[0,1,0],0.1,false);
        % % Store learned day across animals
        % learned_day_all(curr_animal_idx) = find(learned_day,1);
    end

  nexttile(t_animal); hold on
   plot(relative_day,success);
    xlabel('day');
   if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
        drawnow;

 
 all_animal_react_index{curr_animal_idx}=react_index;
 all_animal_learned_day{curr_animal_idx}=learned_day;
 all_animal_rxn_med{curr_animal_idx}=rxn_med;
 all_animal_stim2move_med{curr_animal_idx}=stim2move_med;
 all_animal_stim2move_mean{curr_animal_idx}=stim2move_mean;
 all_animal_stim2move_mad{curr_animal_idx}=stim2move_mad;
 all_animal_stim2move_med_null{curr_animal_idx}=stim2move_med_null;
 all_animal_stim2move_mean_null{curr_animal_idx}=stim2move_mean_null;
 all_animal_stim2move_mad_null{curr_animal_idx}=stim2move_mad_null;
 all_animal_frac_move_V{curr_animal_idx}=frac_move_stimalign_1;
 all_animal_frac_move_A{curr_animal_idx}=frac_move_stimalign_2;
all_animal_frac_success{curr_animal_idx}=success;
end

 % saveas(gcf,[Path 'figures\summary\behavior\ephys_mixed_behavior_' strjoin(animals, '_')], 'jpg');
 % saveas(gcf,[Path 'mixed_behavior_' strjoin(animals, '_') '.eps' ], 'epsc');
% save ([Path 'summary_data\behavior in mixed task in ' n1_name '_to_' n2_name '.mat' ],...
%     'animals','all_animal_learned_day', 'all_animal_react_index','all_animal_rxn_med','all_animal_stim2move_med',...
%     'all_animal_stim2move_mean','all_animal_stim2move_mad','all_animal_frac_move_V','all_animal_frac_move_A',...
%     'all_animal_stim2move_med_null','all_animal_stim2move_mean_null','all_animal_stim2move_mad_null','-v7.3');

