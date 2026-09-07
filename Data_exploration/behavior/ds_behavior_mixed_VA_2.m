%% Behavior across days
clear all
Path = 'D:\Data process\wf_data\';

animals = {'DS036','DS038'  ,'DS041' ,'DS042','DS043'};
 % animals = {'DS022','DS023','DS024','DS025'};


for curr_animal_idx = 1:length(animals)
    animal = animals{curr_animal_idx};

    use_workflow = {'stim_wheel*'};

    % % use_workflow =...
    % %     {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*'};
    %
    % use_workflow =...
    %     {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
    %     'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

    recordings = plab.find_recordings(animal,[],use_workflow);
    % only ephys data
    % recordings(find([recordings.widefield])) = [];
    % recordings(find([recordings.ephys])) = [];
    workflow_time= cat(2,recordings.recording);
    workflow_day= feval(@(a) cat(1,a{:}) , cellfun(@(x,y) repmat({x},length(y),1), {recordings.day}, { recordings.index},'UniformOutput',false));
    % workflow_day={recordings.day}';
    n_session=length(workflow_day);
    workflow_name=vertcat(recordings.workflow);



    % % 选择某一个日期后的记录
    % dt = datetime({recordings.day}, 'InputFormat', 'yyyy-MM-dd');
    % idx = find(dt > datetime('2026-07-22', 'InputFormat', 'yyyy-MM-dd'));
    % recordings=recordings(idx);



    surround_time = [-5,5];
    surround_sample_rate = 100;
    surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

    n_trials_water = nan(n_session,2);

    frac_move_day = nan(n_session,1);

    success = nan(n_session,4);
    rxn_med = nan(n_session,4);
    stim2move_mad = nan(n_session,5);

    stim2move_mad_null = nan(n_session,5);

    frac_move_stimalign=cell(4,1);
    for curr_i=1:4
    frac_move_stimalign{curr_i} = nan(n_session,length(surround_time_points));
    end
    % frac_move_stimalign_2 = nan(n_session,length(surround_time_points));
    rxn_stat_p_mean = nan(n_session,3);
    n_trials_types= nan(n_session,2);
    wheel_vel_by_type_mean=cell(n_session,4);
    wheel_vel_by_type_mean(:)={zeros(1, 1001)};
    iti_move_all= nan(n_session,2);

    for curr_recording =1: n_session

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = workflow_day{curr_recording};

        rec_time = workflow_time{curr_recording};

        load_parts = struct;
        load_parts.behavior = true;
        ap.load_recording;
        ds.load_iti_move

        iti_move_all(curr_recording,:)=[length(iti_move_time_l) length(iti_move_time_r)];
        % Get task types
        % [~,~,tasktype]=unique([trial_events.values.TaskType]);
        % tasktype=tasktype';

        tasktype=[trial_events.values.TaskType];

        No_tasktype =unique(tasktype);



        % Get total trials/water
        n_trials_water(curr_recording,:) = [length(trial_events.timestamps), ...
            sum(([trial_events.values.Outcome] == 1)*6)];


        % Get median stim-outcome time
        n_trials = length([trial_events.timestamps.Outcome]);

        % stim_on2off_time=arrayfun(@(type) seconds([trial_events.timestamps(find(tasktype(1:n_trials)==type)).Outcome] - ...
        %     cellfun(@(x) x(1),{trial_events.timestamps(find(tasktype(1:n_trials)==type)).StimOn})),No_tasktype,'UniformOutput',false);


        stim_on2off_time= seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
            cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn}));

        stim_on2off_time_correct=...
            arrayfun(@(type) ...
            stim_on2off_time(tasktype(1:n_trials)==type &[trial_events.values.Outcome]==1),No_tasktype,'UniformOutput',false);



        n_trials_types(curr_recording,unique(tasktype)+1)=cellfun(@length,stim_on2off_time_correct,'UniformOutput',true);

        % rxn_med(curr_recording,unique(tasktype)+1)   = cellfun(@median, stim_on2off_time_correct,'UniformOutput',true);


        rxn_med(curr_recording,unique(tasktype)+1)   = cellfun(@(aa) median(aa(aa>0)),   arrayfun(@(type) ...
            stim_to_lastmove(tasktype(1:n_trials)==type &[trial_events.values.Outcome]==1),No_tasktype,'UniformOutput',false),'UniformOutput',true);


        % Align wheel movement to stim onset
        align_times = stimOn_times;
        pull_times = align_times + surround_time_points;

        outcome=cat(1,trial_events.values.Outcome)';

        % 识别 correction trials
        n_outcome = numel(outcome');
        % 1) 识别触发 correction 的位置：res==0 且 前一 trial 为 1（把第1位视作前一位为1以触发）
        prev = [1; outcome(1:end-1)'];             % 将第1位的"前一位"设为1（如果res(1)==0，应该触发）
        triggers = find(outcome'==0 & prev==1);   % 触发索引 i (表示第 i 次错，correction 从 i+1 开始)
        % 2) 计算每个位置向右第一个为1的位置（包含当前位置），用 fillmissing 向右填充索引
        nextOne = nan(n_outcome,1);
        oneIdx = find(outcome'==1);
        nextOne(oneIdx) = oneIdx;            % 在为1的位置放置它的索引
        nextOne = fillmissing(nextOne,'next'); % 向右填充：每个位置得到"该位或右侧第一个1的索引"
        % note: 对于位于最后一个1之后的位置，nextOne 会保持 NaN
        % 3) 对每个 trigger 构造 correction 区间的 start/end（start = trigger+1）
        starts = triggers + 1;
        valid = starts <= n_outcome;                  % 去掉超出范围的触发（trigger==n 的情况）
        starts = starts(valid);
        % end index 是从 start 位置向右第一个1（若没有则到 n）
        ends = nextOne(starts);
        ends(isnan(ends)) = n_outcome;               % 如果没有后续1，则延伸到序列末尾
        % 4) 用差分（prefix-sum trick）把所有区间合并成一个 mask（完全无循环）
        if isempty(starts)
            corrMask = false(n_outcome,1);
        else
            delta = zeros(n_outcome+1,1);
            delta(starts) = delta(starts) + 1;
            delta(ends+1) = delta(ends+1) - 1;   % ends 可以为 n -> index n+1 有意义
            corrMask = cumsum(delta(1:n_outcome)) > 0;
        end

        corrIdx = find(corrMask);
        normalIdx = ~corrMask;

        success(curr_recording,unique(tasktype)+1)=...
            arrayfun(@(id) sum(tasktype(normalIdx(1:n_trials))==id&outcome(normalIdx(1:n_trials))==1)/...
            sum(tasktype(normalIdx(1:n_trials))==id),unique(tasktype),'UniformOutput',true);


        frac_move_day(curr_recording) = nanmean(wheel_move);


        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);

        event_aligned_wheel_move = interp1(timelite.timestamps, ...
            +wheel_move,pull_times,'previous');


        % frac_move_stimalign{1}(curr_recording,:) = nanmean(event_aligned_wheel_move,1);
        for curr_id=unique(tasktype)
            frac_move_stimalign{curr_id+1}(curr_recording,:)= nanmean(event_aligned_wheel_move(tasktype(1:n_trials)==curr_id,:),1);
        end



        wheel_vel_by_type= feval(@(x)  cat(2,x{:}) ,arrayfun(@(perform) arrayfun(@(type) ...
            event_aligned_wheel_vel(tasktype(1:n_trials)==type & outcome(1:n_trials)==perform,:),...
            No_tasktype,'UniformOutput',false ), [1,0],'UniformOutput',false ));

        % wheel_vel_by_type_mean(curr_recording,1:length(unique(tasktype))*2)=feval(@(x) cat(2,x{:}), ...
        %     arrayfun(@(id) arrayfun(@(success)  ...
        %     mean(event_aligned_wheel_vel(tasktype(1:n_trials)==id & outcome(1:n_trials)==success,:),1),...
        %     0:1,'uni',false),unique(tasktype),'UniformOutput',false));
        wheel_vel_by_type_mean(curr_recording,unique(tasktype)+1)=arrayfun(@(id)  ...
            mean(event_aligned_wheel_vel(tasktype(1:n_trials)==id & outcome(1:n_trials)==1,:),1),...
            unique(tasktype),'UniformOutput',false);


        [rxn_stat_p_mean(curr_recording,[1 :length(unique(tasktype))]),...
            stim2move_mad(curr_recording,[1 :length(unique(tasktype))]),...
            stim2move_mad_null(curr_recording,[1 :length(unique(tasktype))])] = ...
            ds.stimwheel_association_pvalue( ...
            stimOn_times,trial_events,stim_to_lastmove,tasktype,'mad');


        %  % Get association stat


        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,n_session);

    end



    % Define learned day from reaction stat p-value and reaction time
    learned_day = rxn_stat_p_mean(:,1:2) < 0.05 & rxn_med(:,1:2) < 2;
    wheel_vel_mean=arrayfun(@(state)  cat(1,wheel_vel_by_type_mean{:,state} ) ,1:size(wheel_vel_by_type_mean,2) ,'UniformOutput',false  );



    % 转成 datetime
    d = datetime(workflow_day);

    % 每一步至少增加1；
    % 如果日期跨了多天，则按实际跨过的天数增加
    relative_day = zeros(size(d));
    relative_day(1) = 1;

    for i = 2:numel(d)
        day_diff = days(d(i) - d(i-1));

        % 同一天重复也算1天
        relative_day(i) = relative_day(i-1) + max(1, day_diff);
    end

    nonrecorded_day = setdiff(1:n_session,relative_day);



    figure
   sgtitle(animal);

    nexttile;
    hold on;
    plot(relative_day,n_trials_types);
    ylabel('# trials');

    xlabel('Day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end

    idx_left  = contains(workflow_name,'left');
    idx_right = contains(workflow_name,'right');
    idx_mixed_v = ~idx_left & ~idx_right & contains(workflow_name,'Vcenter');

    type=1*double(idx_left)+2*(idx_right)+3*double(idx_mixed_v);
    x = relative_day';
    yl = ylim;
    X = [x-0.5; x+0.5; x+0.5; x-0.5];
    Y = repmat([yl(1); yl(1); yl(2); yl(2)], 1, numel(x));
    colors = [ ...
        0.8 0.9 1.0;   % type 1  淡蓝
        1.0 0.9 0.8;   % type 2  淡橙
        0.9  0.9 1 ];  % type 3  淡绿
    patch(X, Y, permute(colors(type,:),[3 1 2]), ...
        'EdgeColor','none', 'FaceAlpha',0.4)

    
    
    
    uistack(findobj(gca,'Type','patch'),'bottom')

    xlim([relative_day(1) relative_day(end)])



    nexttile;
    react_null_index=(stim2move_mad_null-stim2move_mad)./(stim2move_mad+stim2move_mad_null);
    hold on
    plot(relative_day,react_null_index, 'LineWidth',1)
    plot(relative_day,react_null_index, 'o', 'MarkerSize',2)
    set(gca,'ColorOrder',[0.0000    0    1; 1    0   0; 0.0000    0.4470    0.7410; 0.8500    0.3250    0.0980])
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end

    x = relative_day';
    yl = ylim;
    X = [x-0.5; x+0.5; x+0.5; x-0.5];
    Y = repmat([yl(1); yl(1); yl(2); yl(2)], 1, numel(x));

    patch(X, Y, permute(colors(type,:),[3 1 2]), ...
        'EdgeColor','none', 'FaceAlpha',0.4)
    uistack(findobj(gca,'Type','patch'),'bottom')

    ylabel('perform');
    yline(0);
    xlabel('Day');
    xlim([1,relative_day(end)]);
    clear prestim_max poststim_max
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end

    nexttile; hold on
    plot(relative_day,success);
    plot(relative_day,success, 'o', 'MarkerSize',2)
    set(gca,'ColorOrder',[0.0000    0    1; 1    00    0; 0.0000    0.4470    0.7410; 0.8500    0.3250    0.0980])
    ylim([0 1])
    ylabel('success');
    xlabel('day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end


    x = relative_day';
    yl = ylim;
    X = [x-0.5; x+0.5; x+0.5; x-0.5];
    Y = repmat([yl(1); yl(1); yl(2); yl(2)], 1, numel(x));
    patch(X, Y, permute(colors(type,:),[3 1 2]), ...
        'EdgeColor','none', 'FaceAlpha',0.4)
    uistack(findobj(gca,'Type','patch'),'bottom')
    xlim([1,relative_day(end)]);

    nexttile
    plot(relative_day,(iti_move_all(:,1)-iti_move_all(:,2))./(iti_move_all(:,1)+iti_move_all(:,2)));

    ylabel('iti move');
    xlabel('day');
    if any(nonrecorded_day)
        xline(nonrecorded_day,'--k');
    end
    x = relative_day';
    yl = ylim;
    X = [x-0.5; x+0.5; x+0.5; x-0.5];
    Y = repmat([yl(1); yl(1); yl(2); yl(2)], 1, numel(x));
    patch(X, Y, permute(colors(type,:),[3 1 2]), ...
        'EdgeColor','none', 'FaceAlpha',0.4)
    uistack(findobj(gca,'Type','patch'),'bottom')
    xlim([1,relative_day(end)]);
    yline(0)



    for curr_type=1:length(frac_move_stimalign)
        frac_move_stimalign{curr_type}(isnan(frac_move_stimalign{curr_type})) = 0;
        nexttile
        imagesc(surround_time_points,[],frac_move_stimalign{curr_type}); hold on;
        clim([0,1]);
        colormap(gca,ap.colormap('WK'));
        set(gca,'YTick',1:n_session,'YTickLabel', ...
            cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
            workflow_day',num2cell(1:n_session),'uni',false));
        xlabel('Time from stim');
        title('Type')
        if any(learned_day(:,1))
            plot(0,find(learned_day(:,1)),'.g')
        end
    end

    for curr_type=1:length(frac_move_stimalign)

        nexttile; hold on
        set(gca,'ColorOrder',copper(n_session));

        plot(surround_time_points,frac_move_stimalign{curr_type}(1:end,:)','linewidth',2);

        xline(0,'color','k');
        ylabel('Fraction moving');
        xlabel('Time from stim');
        if any(learned_day)
            ap.errorfill(surround_time_points,frac_move_stimalign{curr_type}(learned_day(:,1),:)', ...
                0.02,[0,1,0],0.1,false);

        end

    end

    drawnow;


    for curr_state=1:length(frac_move_stimalign)
        nexttile;

        wheel_vel_mean = cellfun(@(x) ...
            fillmissing(x,'constant',0), ...
            wheel_vel_mean, 'UniformOutput', false);

        imagesc(surround_time_points,[],wheel_vel_mean{curr_state})
        xline(0,'color','k');
        % clim(max(abs(clim)).*[-1,1])
        clim([-2000 2000])
        colormap(gca,ap.colormap('BWR'));
        set(gca,'YTick',1:n_session,'YTickLabel', ...
            cellfun(@(day,num) sprintf('%d (%s)',num,day(6:end)), ...
            workflow_day',num2cell(1:n_session),'uni',false));
        xlabel('Time from stim');

        % title(titlename{curr_state})

        ax=nexttile;
        plot(surround_time_points,wheel_vel_mean{curr_state}(1:end,:)','linewidth',2);
        xline(0,'color','k');
        ylabel('velocity');
        xlabel('Time from stim');
        set(ax,'ColorOrder',copper(n_session));


    end

    drawnow;
    nexttile;

    % figure;
    plot(relative_day,rxn_med)
    hold on
    % plot(relative_day,rxn_med, 'o', 'MarkerSize',2)

    set(gca, 'YScale', 'log')

end


