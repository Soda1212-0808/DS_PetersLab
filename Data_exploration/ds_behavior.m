%% Behavior across days
clear all
Path = 'D:\Data process\wf_data\';

% animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
% animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';
% % animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';
% animals = {'DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';

 animals = {'HA013','HA014','HA015'};
 % animals = {'HA012'};


reaction_time=2;
% Grab learning day for each mouse
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

learned_day_all = nan(size(animals));
all_animal_react_index=cell(length(animals),1);
all_animal_react_index2=cell(length(animals),1);
all_animal_react_null_index=cell(length(animals),1);

all_animal_learned_day=cell(length(animals),1);
all_animal_workflow_name=cell(length(animals),1);
all_animal_workflow_name_full=cell(length(animals),1);
all_animal_workflow_day=cell(length(animals),1);
all_animal_stim_on2off_time=cell(length(animals),1);
all_animal_rxn_med=cell(length(animals),1);
all_animal_stim2move_mean=cell(length(animals),1);
all_animal_stim2move_mean_null=cell(length(animals),1);
all_animal_stim2move_mad=cell(length(animals),1);
all_animal_stim2move_mad_null=cell(length(animals),1);
all_animal_stim2move_med=cell(length(animals),1);
all_animal_stim2move_med_null=cell(length(animals),1);
all_animal_workflow_day_frac_move=cell(length(animals),1);
all_animal_trials_iti_move2all_trials=cell(length(animals),1);
all_animal_stim2move_time=cell(length(animals),1);
all_animal_frac_move_trialbytrial=cell(length(animals),1);
all_animal_frac_velocity_trialbytrial=cell(length(animals),1);

figure('Position',[50 100 length(animals)*300 900]);

tt = tiledlayout(1,length(animals),'TileSpacing','tight');

for curr_animal_idx = 1:length(animals)

    animal = animals{curr_animal_idx};


    % use_workflow =...
    %     ['stim_wheel_right_stage1$|' ...
    %     'stim_wheel_right_stage2$|' ...
    %     'stim_wheel_right_stage1_opacity$|' ...
    %     'stim_wheel_right_stage2_opacity$|' ...
    %     'stim_wheel_right_stage1_angle$|' ...
    %     'stim_wheel_right_stage2_angle$|' ...
    %     'stim_wheel_right_stage2_angle_size60$|' ...
    %     'stim_wheel_right_stage1_size_up$|' ...
    %     'stim_wheel_right_stage2_size_up$|' ...
    %     'stim_wheel_right_stage1_audio_volume$|'...
    %     'stim_wheel_right_stage2_audio_volume$|' ...
    %     'stim_wheel_right_stage1_audio_frequency$|' ...
    %     'stim_wheel_right_stage2_audio_frequency$|' ...
    %     'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
    %     'stim_wheel_right_stage2_mixed_VA$'];

    use_workflow =...
        ['stim_wheel_right_stage1$|' ...
        'stim_wheel_right_stage2$|' ...
        'stim_wheel_right_stage1_audio_volume$|'...
        'stim_wheel_right_stage2_audio_volume$|' ...
        'stim_wheel_right_stage1_audio_frequency$|' ...
        'stim_wheel_right_stage2_audio_frequency$|' ...
        'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
        'stim_wheel_right_stage2_mixed_VA$'];

    recordings = plab.find_recordings(animal,[],use_workflow);

    %只保留widefiled的数据
    recordings(find([recordings.ephys])) = [];
    % recordings = recordings(1:8);

    workflow_day={recordings.day}';
    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_water = nan(length(recordings),2);
    frac_move_day = nan(length(recordings),1);
    success = nan(length(recordings),1);
    rxn_med = nan(length(recordings),1);
    stim_on_to_off_times=cell(length(recordings),1);
    stim2move_mean = nan(length(recordings),1);
    stim2move_mean_null = nan(length(recordings),1);
    stim2move_mad_null = nan(length(recordings),1);
    stim2move_med_null = nan(length(recordings),1);
    
    stim2move_time=cell(length(recordings),1);

    stim2move_mad = nan(length(recordings),1);
    stim2move_med = nan(length(recordings),1);

    frac_move_stimalign = nan(length(recordings),length(surround_time_points));
    frac_velocity_stimalign= nan(length(recordings),length(surround_time_points));
   
    frac_move_stimalign_trialbytrial =cell(length(recordings),1);
    frac_velocity_stimalign_trialbytrial=cell(length(recordings),1);
    
    rxn_stat_p = nan(length(recordings),1);
    workflow_name= cell(length(recordings),1);
    workflow_name_full=cell(length(recordings),1);
    trials_success= nan(length(recordings),1);
    trials_iti_move= nan(length(recordings),1);

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



        % Get total trials/water
        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
            sum(([trial_events.values.Outcome] == 1)*6)];

        % Get median stim-outcome time
        n_trials = length([trial_events.timestamps.Outcome])-1;
        stim_on_to_off_times{curr_recording}=stimOff_times(1:n_trials) - ...
            stimOn_times(1:n_trials);
        rxn_med(curr_recording) = median(stimOff_times(1:n_trials) - ...
            stimOn_times(1:n_trials)  );

        n_trials_success=sum(cat(1,trial_events.values.Outcome));
       trials_success(curr_recording)=n_trials_success;

           % 计算 iti move的时间点

            wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
            wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);

            wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
            wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);

            % 找到 wheel 开始转动的索引
            start_idx = find(diff([0;wheel_move]) == 1);
            % 预分配时间数组 (提高效率)
            time_to_90 = nan(size(start_idx));
            % **优化的计算方式**
            for i = 1:length(start_idx)
                % 直接找到第一个满足 wheel_position > pos_start + 90 的索引
                target_idx = find(wheel_position(start_idx(i):length(wheel_position)) < wheel_starts_position(i) - (30/360*1024), 1, 'first');
                % 计算所需时间 (以 ms 计算)
                if ~isempty(target_idx)
                    time_to_90(i) = (target_idx - 1) * 1; % 1000Hz 采样率，每点 1ms
                end
            end
            wheel_move_less_than_200ms= time_to_90<200;

            wheel_move_over_90=wheel_stops_position-wheel_starts_position<-(30/360*1024);

            % (get wheel starts when no stim on screen: not sure this works yet)
            iti_move_idx = interp1(photodiode_times, ...
                photodiode_values,wheel_starts,'previous') == 0;

            real_iti_move = wheel_starts(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );
            n_trial_iti_move=length(real_iti_move);

            trials_iti_move(curr_recording)=n_trial_iti_move;

        % rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
        %     cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));
        % % Get median stim-move time
        % stim2move_med(curr_recording)=median(stim_to_move);


        % Align wheel movement to stim onset
        align_times = stimOn_times;
        pull_times = align_times + surround_time_points;

        success(curr_recording)=sum(cat(1,trial_events.values.Outcome))/n_trials;


        frac_move_day(curr_recording) = nanmean(wheel_move);
        wheel_move_direction=double(wheel_move);
        wheel_move_direction(wheel_move==1&wheel_velocity<0)=-1;

        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');

       
        frac_move_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_move,1);    
        frac_move_stimalign_trialbytrial{curr_recording}=event_aligned_wheel_move;
                
        frac_velocity_stimalign(curr_recording,:) = nanmean(event_aligned_wheel_vel,1);
        frac_velocity_stimalign_trialbytrial{curr_recording} = event_aligned_wheel_vel;
        % % figure
        % nexttile
        % imagesc(event_aligned_wheel_move')
        % hold on
        % scatter(1:length(stim_to_move),(1*stim_to_move+5)*100,5,'fill')
        % % ylim([-0.1 0.5])
        % nexttile;
        % histogram(stim_to_move,[-0.1:0.02:0.3])
        % drawnow
        
        stim2move_time{curr_recording}=stim_to_move;


        % Get association stat
        % rxn_stat_p(curr_recording) = AP_stimwheel_association_pvalue( ...
        %     stimOn_times,trial_events,stim_to_move);
        % Get association stat
        [useless_p, stim2move_mean(curr_recording),stim2move_mean_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_lastmove,'mean');

        [rxn_stat_p(curr_recording), stim2move_mad(curr_recording),stim2move_mad_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_lastmove,'mad');

        [useless_p, stim2move_med(curr_recording),stim2move_med_null(curr_recording)] = AP_stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_lastmove,'median');

        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings));

    end


    % Define learned day from reaction stat p-value and reaction time
    learned_day = rxn_stat_p < 0.05 & rxn_med < reaction_time;
    relative_day = days(datetime({recordings.day}) - datetime({recordings(1).day}))+1;
    nonrecorded_day = setdiff(1:length(recordings),relative_day);

    % workflow_name_2=arrayfun(@(idx) recordings(idx).workflow{1},1:length(recordings),  'UniformOutput', false)';
    matches = unique(workflow_name, 'stable');
    different_day_1= cellfun(@(x) relative_day(find(strcmp(workflow_name,x))),matches,'UniformOutput',false);
    different_day_2= cellfun(@(x) find(strcmp(workflow_name,x)),matches,'UniformOutput',false);

    % Draw in tiled layout nested in master
    t_animal = tiledlayout(tt,8,1);
    t_animal.Layout.Tile = curr_animal_idx;
    title(t_animal,animal);

    %%plot from  3 days before the first association day
    % range_t1= relative_day(find(learned_day == 1, 1, 'first'))-3;
    range_t1=1;

    % figure 1
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


    % figure 2
    nexttile(t_animal);


    hold on;
    yyaxis left
    plot(relative_day, rxn_med, 'LineWidth', 1);
    % plot(relative_day, stim2move_med, 'LineWidth', 1);
    set(gca, 'YScale', 'log');
    ylabel('Med. rxn');
    xlabel('Day');

    ax = gca;
    ylim1 = ax.YLim;
    % 将对数坐标轴范围转换为线性坐标轴范围
    ylim_linear = log10(ylim1);
    ylim_linear = 10 .^ ylim_linear;

    colorMap = lines(length(different_day_1)); % 使用 colormap 自动生成不同颜色

    % 遍历 relative_day 填充背景
    for curr_day = relative_day
        % 遍历 different_day 中的每一组
        for groupIdx = 1:length(different_day_1)
            if any(different_day_1{groupIdx} == curr_day)
                % 获取当前组的颜色
                color = colorMap(groupIdx, :);
                % 填充背景颜色
                fill([curr_day-0.5, curr_day+0.5, curr_day+0.5, curr_day-0.5], ...
                    [ylim_linear(1), ylim_linear(1), ylim_linear(2), ylim_linear(2)], ...
                    color, 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 添加透明度
                break; % 当前 `i` 只属于一个组，跳出内循环
            end
        end
    end


    yyaxis right
    prestim_max = max(frac_move_stimalign(:,surround_time_points < 0),[],2);
    poststim_max = max(frac_move_stimalign(:,surround_time_points > 0),[],2);
    plot(relative_day,(poststim_max-prestim_max)./(poststim_max+prestim_max));
    yline(0);
    ylabel('pre/post move idx');
    xlabel('Day');
    xlim([range_t1,relative_day(end)]);
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    if any(learned_day)
        xline(relative_day(learned_day),'g');
    end
    xlim([range_t1,relative_day(end)])

    react_index2=(poststim_max-prestim_max)./(poststim_max+prestim_max);

    % % 为图例添加虚拟对象，仅显示背景颜色
    % legendHandles = gobjects(length(different_day), 1); % 预分配图例句柄数组
    % for groupIdx = 1:length(different_day)
    %     % 创建不可见的填充对象用于图例
    %     legendHandles(groupIdx) = fill(NaN, NaN, colorMap(groupIdx, :), ...
    %         'EdgeColor', 'none', 'FaceAlpha', 0.3);
    % end
    %
    % % 添加图例，仅显示虚拟对象
    % legend(legendHandles, matches, 'Location', 'northoutside', 'Orientation', 'horizontal');



    % figure3
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

    for curr_type=1:length(different_day_2)

        plot(-0.5,different_day_2{curr_type},'Marker', '|', 'MarkerEdgeColor',colorMap(curr_type,:))
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
    ylabel('reaction index')



    nexttile(t_animal);
    react_null_index=(stim2move_mean_null-stim2move_mean)./(stim2move_mean+stim2move_mean_null);
    plot(react_null_index)
    set(gca,'XTick',1:length(recordings),'XTickLabel', ...
        cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
        {recordings.day},num2cell(1:length(recordings)),'uni',false));
    hold on
    yline(0)
    % ylim([-1, 1])
    ylabel('(rxt-rxt_null)/rxt')


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
    for curr_type=1:length(different_day_1)

        plot(-0.5,different_day_1{curr_type},'Marker', '|', 'MarkerEdgeColor',colorMap(curr_type,:))
    end

    ylim([(range_t1-0.5),(0.5+length(learned_day))])

    all_animal_react_index2{curr_animal_idx}=react_index2;
    all_animal_react_index{curr_animal_idx}=react_index;
    all_animal_react_null_index{curr_animal_idx}=react_null_index;

    all_animal_learned_day{curr_animal_idx}=learned_day;
    all_animal_workflow_name{curr_animal_idx}=workflow_name;
    all_animal_workflow_name_full{curr_animal_idx}=workflow_name_full;

    all_animal_rxn_med{curr_animal_idx}=rxn_med;

    all_animal_stim2move_mean{curr_animal_idx}=stim2move_mean;
    all_animal_stim2move_mad{curr_animal_idx}=stim2move_mad;
    all_animal_stim2move_med{curr_animal_idx}=stim2move_med;

    all_animal_stim2move_med_null{curr_animal_idx}=stim2move_med_null;
    all_animal_stim2move_mad_null{curr_animal_idx}=stim2move_mad_null;
    all_animal_stim2move_mean_null{curr_animal_idx}=stim2move_mean_null;

    all_animal_workflow_day{curr_animal_idx}=workflow_day;
    all_animal_workflow_day_frac_move{curr_animal_idx} =  frac_move_stimalign;
    
    iti_move2all_trials=trials_iti_move./trials_success;
    all_animal_trials_iti_move2all_trials{curr_animal_idx}= iti_move2all_trials;
    all_animal_stim2move_time{curr_animal_idx}=stim2move_time;
    all_animal_stim_on2off_time{curr_animal_idx}=stim_on_to_off_times;

    all_animal_frac_move_trialbytrial{curr_animal_idx}=frac_move_stimalign_trialbytrial;
    all_animal_frac_velocity_trialbytrial{curr_animal_idx}=frac_velocity_stimalign_trialbytrial;

    drawnow;
  
end
% 
% % saveas(gcf,[Path 'figures\summary\behavior\behavior in ' n1_name '_to_' n2_name ], 'jpg');
% % 
%  save([Path 'summary_data\behavior in ' n1_name '_to_' n2_name '.mat' ],...
%      'animals','all_animal_workflow_day','all_animal_learned_day', 'all_animal_workflow_name',...
%      'all_animal_react_index','all_animal_rxn_med','all_animal_stim2move_mean','all_animal_stim2move_mean_null',...
%      'all_animal_stim2move_mad','all_animal_stim2move_mad_null','all_animal_stim2move_med_null',...
%      'all_animal_stim2move_med','all_animal_react_null_index','all_animal_workflow_day_frac_move',...
%      'all_animal_trials_iti_move2all_trials','all_animal_stim2move_time','all_animal_stim_on2off_time','-v7.3');

