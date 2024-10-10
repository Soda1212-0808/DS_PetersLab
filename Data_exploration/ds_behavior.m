%% Behavior across days
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\figures\';

   animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001'};
  % animals = { 'DS003','DS004','DS000','DS006','DS005'};

   % animals = {'DS016'};
  % animals = {'DS001','DS003'};
    % animals = {'AP016'};

reaction_time=2;
% animals = {'DS000'};
% animals = {'DS001'};
% Create master tiled layout

figure('Position',[50 100 length(animals)*300 900]);
tt = tiledlayout(1,length(animals),'TileSpacing','tight');

% Grab learning day for each mouse
learned_day_all = nan(size(animals));

for curr_animal_idx = 1:length(animals)

    animal = animals{curr_animal_idx};

     use_workflow = {'stim_wheel_right_stage1$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage2$|stim_wheel_right_stage2_audio_volume$|stim_wheel_right_stage2_audio_frequency$'};
     % use_workflow = {'stim_wheel_right_stage*'};

    recordings = plab.find_recordings(animal,[],use_workflow);

    %只保留widefiled的数据
    recordings(find([recordings.ephys])) = [];


    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_water = nan(length(recordings),2);
    frac_move_day = nan(length(recordings),1);
    success = nan(length(recordings),1);
    rxn_med = nan(length(recordings),1);
    frac_move_stimalign = nan(length(recordings),length(surround_time_points));
    frac_velocity_stimalign= nan(length(recordings),length(surround_time_points));
    rxn_stat_p = nan(length(recordings),1);
    workflow_name= nan(length(recordings),1);

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

        if strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')
            workflow_name(curr_recording)=2;
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2')
            workflow_name(curr_recording)=1;
        else  workflow_name(curr_recording)=0;
        end

        load_parts = struct;
        load_parts.behavior = true;

        ap.load_recording;

        % Get total trials/water
        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
            sum(([trial_events.values.Outcome] == 1)*6)];

        % Get median stim-outcome time
        n_trials = length([trial_events.timestamps.Outcome]);
        rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));


        % Align wheel movement to stim onset
        align_times = stimOn_times;
        pull_times = align_times + surround_time_points;

        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;


        frac_move_day(curr_recording) = nanmean(wheel_move);

        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');

        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);
                
        frac_velocity_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_vel,1);

        % Get association stat
        rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_move);

        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings));

    end

    % Define learned day from reaction stat p-value and reaction time
    learned_day = rxn_stat_p < 0.05 & rxn_med < reaction_time;

    relative_day = days(datetime({recordings.day}) - datetime({recordings(1).day}))+1;
    nonrecorded_day = setdiff(1:length(recordings),relative_day);


    day_worflow=arrayfun(@(idx) recordings(idx).workflow{1},1:length(recordings),  'UniformOutput', false)';
    visual_day=relative_day(find(strcmp(day_worflow,'stim_wheel_right_stage2')));
    audio_day=relative_day(find(strcmp(day_worflow,'stim_wheel_right_stage2_audio_volume')|strcmp(day_worflow,'stim_wheel_right_stage2_audio_frequency')));





    % Draw in tiled layout nested in master
    t_animal = tiledlayout(tt,7,1);
    t_animal.Layout.Tile = curr_animal_idx;
    title(t_animal,animal);

    %%plot from  3 days before the first association day
    % range_t1= relative_day(find(learned_day == 1, 1, 'first'))-3;
    range_t1=1;

    nexttile(t_animal);
    yyaxis left; plot(relative_day,n_trials_water(:,1));
    ylabel('# trials');
    yyaxis right; plot(relative_day,frac_move_day);
    ylabel('Fraction time moving');
    xlabel('Day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day),'g');
    end
    xlim([range_t1,relative_day(end)])



    nexttile(t_animal);
    yyaxis left
    plot(relative_day,rxn_med,'LineWidth',1)
    set(gca,'YScale','log');
    ylabel('Med. rxn');
    xlabel('Day');
    %
    ax = gca;
    ylim1 = ax.YLim;
    % 将对数坐标轴范围转换为线性坐标轴范围
    ylim_linear = log10(ylim1);
    ylim_linear = 10 .^ ylim_linear;
    if ~visual_day==0
        bg1 =rectangle('Position', [visual_day(1)-0.5, ylim_linear(1), visual_day(end)-visual_day(1)+1, diff(ylim_linear)], 'FaceColor', '#DAE3F3', 'EdgeColor', 'none');
        uistack(bg1, 'bottom');
    end
    if~ audio_day==0
        bg2 =rectangle('Position', [audio_day(1)-0.5, ylim_linear(1), audio_day(end)-audio_day(1)+1, diff(ylim_linear)], 'FaceColor', '#FFB2B2', 'EdgeColor', 'none');
        uistack(bg2, 'bottom');
    end
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day),'g');
    end

    yyaxis right
    prestim_max = max(frac_move_stimalign(:,surround_time_points < 0),[],2);
    poststim_max = max(frac_move_stimalign(:,surround_time_points > 0),[],2);
    plot(relative_day,(poststim_max-prestim_max)./(poststim_max+prestim_max));
    yline(0);
    ylabel('pre/post move idx');
    xlabel('Day');
    xlim([range_t1,relative_day(end)]);



    nexttile(t_animal);
    plot(relative_day,success)
    ylabel('success');
    xlabel('Day');
    xlim([range_t1,relative_day(end)]);
    ylim([0 1])


    nexttile(t_animal);
    imagesc(surround_time_points,[],frac_move_stimalign); hold on;
    clim([0,1]);
    colormap(gca,ap.colormap('WK'));
    set(gca,'YTick',1:length(recordings),'YTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    xlabel('Time from stim');
    if any(learned_day)
        plot(0,find(learned_day),'.g')
    end
    if any(workflow_name==2)
        plot(-0.5,find(workflow_name==2),'|r')
    end
     if any(workflow_name==1)
       plot(-0.5,find(workflow_name==1),'|b')

        
     end
    ylim([(range_t1-0.5),(0.5+length(learned_day))])



    nexttile(t_animal); hold on
    set(gca,'ColorOrder',copper(length(recordings)));
    %plot(surround_time_points,frac_move_stimalign','linewidth',2);
    plot(surround_time_points,frac_move_stimalign(range_t1:end,:)','linewidth',2);
    xline(0,'color','k');
    ylabel('Fraction moving');
    xlabel('Time from stim');
    if any(learned_day)
        ap.errorfill(surround_time_points,frac_move_stimalign(learned_day,:)', ...
            0.02,[0,1,0],0.1,false);

        % Store learned day across animals
        learned_day_all(curr_animal_idx) = find(learned_day,1);
    end



    pre_time=max(frac_move_stimalign(:,surround_time_points>-2&surround_time_points<-1),[],2);
    post_time=max(frac_move_stimalign(:,surround_time_points>0&surround_time_points<1),[],2);
    react_index=(post_time-pre_time)./(post_time+pre_time);

    nexttile(t_animal);
    plot(react_index)
    set(gca,'XTick',1:length(recordings),'XTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    hold on 
    yline(0)
    ylim([-1, 1])

    
    nexttile(t_animal);
    imagesc(surround_time_points,[],frac_velocity_stimalign); hold on;
    clim([-500,500]);
    colormap(gca,ap.colormap('PWG'));
    set(gca,'YTick',1:length(recordings),'YTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    xlabel('Time from stim');
    if any(learned_day)
        plot(-0.2,find(learned_day),'.g')
    end
    if any(workflow_name==2)
        plot(-0.5,find(workflow_name==2),'|r')
    end
     if any(workflow_name==1)
       plot(-0.5,find(workflow_name==1),'|b')

        
    end

    ylim([(range_t1-0.5),(0.5+length(learned_day))])



    

    drawnow;

end


 saveas(gcf,[Path 'behavior_' strjoin(animals, '_')], 'jpg');

