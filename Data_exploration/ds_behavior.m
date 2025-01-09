%% Behavior across days
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

 % animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020'};transfer_type='v_position_to_a_volumne';
 %animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};transfer_type='a_volumne_to_v_position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
 % animals = {'AP027','AP028','AP029'}; transfer_type='v_opacity_to_v_position';
  animals = {'HA003','HA004'};  transfer_type='v_size_up_to_v_position';

reaction_time=2;


% Grab learning day for each mouse
learned_day_all = nan(size(animals));
all_animal_react_index=cell(length(animals),1);
all_animal_react_index2=cell(length(animals),1);

all_animal_learned_day=cell(length(animals),1);
all_animal_workflow_name=cell(length(animals),1);
all_animal_rxn_med=cell(length(animals),1);
all_animal_stim2move_med=cell(length(animals),1);

figure('Position',[50 100 length(animals)*300 900]);
tt = tiledlayout(1,length(animals),'TileSpacing','tight');

for curr_animal_idx = 1:length(animals)

    animal = animals{curr_animal_idx};
     % use_workflow = 'stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2$|stim_wheel_right_stage2_audio_volume$';
   
      % use_workflow = 'stim_wheel_right_stage1_opacity$|stim_wheel_right_stage2_opacity$|stim_wheel_right_stage1_audio_frequency$|stim_wheel_right_stage1_audio_volume$|stim_wheel_right_stage1$|stim_wheel_right_stage2$|stim_wheel_right_stage2_audio_volume$';
 use_workflow =...
                ['stim_wheel_right_stage1$|' ...
                'stim_wheel_right_stage2$|' ...
                'stim_wheel_right_stage1_opacity$|' ...
                'stim_wheel_right_stage2_opacity$|' ...
                'stim_wheel_right_stage1_size_up$|' ...
                'stim_wheel_right_stage2_size_up$|' ...
                'stim_wheel_right_stage1_audio_volume$|'...
                'stim_wheel_right_stage2_audio_volume$|' ...
                'stim_wheel_right_stage1_audio_frequency$|' ...
                'stim_wheel_right_stage2_audio_frequency$|' ...
                'stim_wheel_right_frequency_stage2_mixed_VA$|' ...
                'stim_wheel_right_stage2_mixed_VA$'];
   

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
    stim2move_med = nan(length(recordings),1);

    frac_move_stimalign = nan(length(recordings),length(surround_time_points));
    frac_velocity_stimalign= nan(length(recordings),length(surround_time_points));
    rxn_stat_p = nan(length(recordings),1);
    workflow_name= cell(length(recordings),1);

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

        if strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_volume')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_volume')
            workflow_name{curr_recording}='audio volume';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2')
            workflow_name{curr_recording}='visual position';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_size_up')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_size_up')
            workflow_name{curr_recording}='visual size up';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_opacity')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_opacity')
            workflow_name{curr_recording}='visual opacity';
        elseif strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage1_audio_frequency')...
                ||strcmp(recordings(curr_recording).workflow{index_real},'stim_wheel_right_stage2_audio_frequency')
            workflow_name{curr_recording}='audio volume';
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
        rxn_med(curr_recording) = median(stimOff_times(1:n_trials) - ...
          stimOn_times(1:n_trials)  );

        % rxn_med(curr_recording) = median(seconds([trial_events.timestamps(1:n_trials).Outcome] - ...
        %     cellfun(@(x) x(1),{trial_events.timestamps(1:n_trials).StimOn})));
        % % Get median stim-move time
        stim2move_med(curr_recording)=median(stim_to_move);


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
            stimOn_times,trial_events,stim_to_move,'mean');

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

    different_day= cellfun(@(x) relative_day(find(strcmp(workflow_name,x))),matches,'UniformOutput',false);
    
  
    % Draw in tiled layout nested in master
    t_animal = tiledlayout(tt,7,1);
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

    colorMap = lines(length(different_day)); % 使用 colormap 自动生成不同颜色
  
    % 遍历 relative_day 填充背景
    for curr_day = relative_day
        % 遍历 different_day 中的每一组
        for groupIdx = 1:length(different_day)
            if any(different_day{groupIdx} == curr_day)
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

    for curr_type=1:length(different_day)
        
        plot(-0.5,different_day{curr_type},'Marker', '|', 'MarkerEdgeColor',colorMap(curr_type,:))
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
    for curr_type=1:length(different_day)
        
        plot(-0.5,different_day{curr_type},'Marker', '|', 'MarkerEdgeColor',colorMap(curr_type,:))
    end

    ylim([(range_t1-0.5),(0.5+length(learned_day))])

    all_animal_react_index2{curr_animal_idx}=react_index2;
    all_animal_react_index{curr_animal_idx}=react_index;
    all_animal_learned_day{curr_animal_idx}=learned_day;
    all_animal_workflow_name{curr_animal_idx}=workflow_name;
    all_animal_rxn_med{curr_animal_idx}=rxn_med;
    all_animal_stim2move_med{curr_animal_idx}=stim2move_med;



    drawnow;

end


saveas(gcf,[Path 'figures\summary\behavior in ' transfer_type], 'jpg');

save([Path 'mat_data\summary_data\behavior in ' transfer_type '.mat' ],'animals','all_animal_learned_day', 'all_animal_workflow_name','all_animal_react_index','all_animal_rxn_med','all_animal_stim2move_med','-v7.3');



%%
data1=load([Path 'mat_data\summary_data\behavior in ' transfer_type '.mat' ]);
matches=unique(data1.all_animal_workflow_name{1}, 'stable')

% index_group=[0 0 0 1 1 1 1 1];
index_group=[1 1 ];

n1_data = cellfun(@(x,y) x(strcmp(y,matches{1})),data1.all_animal_stim2move_med,data1.all_animal_workflow_name,'UniformOutput',false);
n1_reindx=cellfun(@(x,y) x(strcmp(y,matches{1})),data1.all_animal_react_index,data1.all_animal_workflow_name,'UniformOutput',false);
n2_data = cellfun(@(x,y) x(strcmp(y,matches{2})),data1.all_animal_stim2move_med,data1.all_animal_workflow_name,'UniformOutput',false);
n2_reindx=cellfun(@(x,y) x(strcmp(y,matches{2})),data1.all_animal_react_index,data1.all_animal_workflow_name,'UniformOutput',false);

% 对n1操作
n1_reindx1=cellfun(@(x) ones(1, length(x)), n1_reindx,'UniformOutput',false);
n1_reindx1_indx=cellfun(@(x) ~isempty(find(x < 0, 1, 'last')),n1_reindx,'UniformOutput',true);
n1_reindx1(n1_reindx1_indx)=cellfun(@(x) [zeros(1,find(x < 0, 1, 'last')) ones(1, length(x)-find(x < 0, 1, 'last'))], n1_reindx(n1_reindx1_indx), 'UniformOutput', false);
n1_data= cellfun(@(x,y) x(y==1),n1_data,n1_reindx1,'UniformOutput',false);
% 1. 获取最长向量的长度
max_len_n1 = max(cellfun(@numel, n1_data));
% 2. 使用 NaN 填充较短的向量
n1_filled_pre = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)], NaN, 'pre'), n1_data, 'UniformOutput', false);
n1_filled_post = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)], NaN, 'post'), n1_data, 'UniformOutput', false);


% 对n2操作
n2_reindx=  cellfun(@(A) [zeros(1, find( A > 0, 1)-1), ones(1, numel(A) - find( A > 0, 1) + 1)],n2_reindx, 'UniformOutput', false);
n2_data= cellfun(@(x,y) x(y==1),n2_data,n2_reindx,'UniformOutput',false);
% 1. 获取最长向量的长度

n1_n2=[cell2mat(n1_filled_pre)  cell2mat(n2_filled_post)]';

figure
hold on
plot(n1_n2(:,find(index_group)),'Color', [0.8 0.8 1]);
h1= plot(nanmean(n1_n2(:,find(index_group)),2),'Color', [0 0 1],'LineWidth',2);
yline(0.1)
% xline(max_len_V,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
% legend([h1, h2],{['V-A, n=' num2str(sum(animals_group==1)) ],['only A, n=' num2str(sum(animals_group==4)) ]});
ylabel('stim to move (s)')
xlabel('training days ')
ylim([0 0.7])
xlim([0 size(n1_n2,1)])
length(n1_filled_pre{1})
ax = gca;
ylim1 = ax.YLim;
bg1 =rectangle('Position', [0, ylim1(1), length(n1_filled_pre{1})-4.5, diff(ylim1)], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
uistack(bg1, 'bottom');
bg2 =rectangle('Position', [length(n1_filled_pre{1})-4.5, ylim1(1), 5, diff(ylim1)], 'FaceColor', '#DAE3F3', 'EdgeColor', 'none');
uistack(bg2, 'bottom');
bg3 =rectangle('Position', [length(n1_filled_pre{1})+0.5, ylim1(1), length(n2_filled_pre{1})-0.5, diff(ylim1)], 'FaceColor','#FFB2B2' , 'EdgeColor', 'none');
uistack(bg3, 'bottom');
title([matches{1} ' to ' matches{2}])
saveas(gcf,[Path 'figures\summary\reaction time in ' transfer_type], 'jpg');

%% 行为学比较  A-V & only V
animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};

data1=load([Path 'mat_data\summary_data\behavior in V or A task.mat' ]);

data2=load([Path 'mat_data\summary_data\behavior in mixed task.mat' ]);

animals_group=[ 1 1 1 1 1 1 5 2 2 3 3 3 4 4 4 4 4];
% animals_group=[ 1 1 1 1 1 1 1 2 2 3 3 3 4 4 4 4 4];

figure('Position',[50 50 800 400]);

V_data = cellfun(@(x,y) x(y==1),data1.all_animal_stim2move_med,all_animal_workflow_name,'UniformOutput',false);
V_reindx=cellfun(@(x,y) x(y==1),data1.all_animal_react_index,all_animal_workflow_name,'UniformOutput',false);
A_data = cellfun(@(x,y) x(y==2),data1.all_animal_stim2move_med,all_animal_workflow_name,'UniformOutput',false);
A_reindx=cellfun(@(x,y) x(y==2),data1.all_animal_react_index,all_animal_workflow_name,'UniformOutput',false);

V_data=V_data([1:14,16,17])
V_reindx=V_reindx([1:14,16,17])
A_data=A_data([1:14,16,17])
A_reindx=A_reindx([1:14,16,17])


% 创建一个示例的4x5的cell矩阵A
% 对矩阵进行操作
V_reindx1=cellfun(@(x) ones(1, length(x)), V_reindx,'UniformOutput',false);
V_reindx1_indx=cellfun(@(x) ~isempty(find(x < 0, 1, 'last')),V_reindx,'UniformOutput',true);
V_reindx1(V_reindx1_indx)=cellfun(@(x) [zeros(1,find(x < 0, 1, 'last')) ones(1, length(x)-find(x < 0, 1, 'last'))], V_reindx(V_reindx1_indx), 'UniformOutput', false);
V_data= cellfun(@(x,y) x(y==1),V_data,V_reindx1,'UniformOutput',false);

% 1. 获取最长向量的长度
max_len_V = max(cellfun(@numel, V_data));
% 2. 使用 NaN 填充较短的向量
V_filled_pre = cellfun(@(x) padarray(x', [0 max_len_V-numel(x)], NaN, 'pre'), V_data, 'UniformOutput', false);
V_filled_post = cellfun(@(x) padarray(x', [0 max_len_V-numel(x)], NaN, 'post'), V_data, 'UniformOutput', false);



% 对矩阵进行操作
A_reindx=  cellfun(@(A) [zeros(1, find( A > 0, 1)-1), ones(1, numel(A) - find( A > 0, 1) + 1)],A_reindx, 'UniformOutput', false);
A_data= cellfun(@(x,y) x(y==1),A_data,A_reindx,'UniformOutput',false);

% 1. 获取最长向量的长度
max_len_A = max(cellfun(@numel, A_data));
% 2. 使用 NaN 填充较短的向量
A_filled_post = cellfun(@(x) padarray(x', [0 max_len_A-numel(x)], NaN, 'post'), A_data, 'UniformOutput', false);
A_filled_pre = cellfun(@(x) padarray(x', [0 max_len_A-numel(x)], NaN, 'pre'), A_data, 'UniformOutput', false);

% 3. 将 cell 数组转换为二维矩阵

A_only=[nan(length(V_data),max_len_V) cell2mat(A_filled_post)]';
V_only=[nan(length(A_data),max_len_A) cell2mat(V_filled_post)]';
V_A=[cell2mat(V_filled_pre)  cell2mat(A_filled_post)]';
A_V=[ cell2mat(A_filled_pre)  cell2mat(V_filled_post)]';
%



% 显示调整后的矩阵
nexttile;
VA_plot=V_A(:,find(animals_group==1));
VA_plot_p = VA_plot(find(any(~isnan(VA_plot), 2), 1):end, :);
A_only_plot=A_only(:,find(animals_group==4));
A_only_plot_p = A_only_plot(find(any(~isnan(VA_plot), 2), 1):find(any(~isnan(A_only_plot), 2), 1, 'last'), :);
xlim([1 size(A_only_plot_p,1)])

hold on
plot(VA_plot_p,'Color', [0.8 0.8 1]);
h1= plot(nanmean(VA_plot_p,2),'Color', [0 0 1],'LineWidth',2);
plot(A_only_plot_p,'Color', [1 0.8 0.8]);
h2= plot(nanmean(A_only_plot_p,2),'Color', [1 0 0],'LineWidth',2);
yline(0.1)
% xline(max_len_V,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
legend([h1, h2],{['V-A, n=' num2str(sum(animals_group==1)) ],['only A, n=' num2str(sum(animals_group==4)) ]});
ylabel('stim to move (s)')
xlabel('training days ')
ylim([0 0.7])

ax = gca;
ylim1 = ax.YLim;
bg1 =rectangle('Position', [0, ylim1(1), find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)-4.5, diff(ylim1)], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
uistack(bg1, 'bottom');
bg2 =rectangle('Position', [find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)-4.5, ylim1(1), find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)-3, diff(ylim1)], 'FaceColor', '#DAE3F3', 'EdgeColor', 'none');
uistack(bg2, 'bottom');
bg3 =rectangle('Position', [find(any(~isnan(A_only_plot), 2), 1)-find(any(~isnan(VA_plot), 2), 1)-3, ylim1(1), find(any(~isnan(A_only_plot), 2), 1, 'last')-find(any(~isnan(A_only_plot), 2), 1)+4, diff(ylim1)], 'FaceColor','#FFB2B2' , 'EdgeColor', 'none');
uistack(bg3, 'bottom');


animals_group_mixed=[ 1 1 1 1 1 5 2 3 3 3 4 4 4 4 4];
select_group=1

s2m_v=cellfun(@(x,y) x(y(:,1)==1,1),data2.all_animal_stim2move_med(animals_group_mixed==select_group),data2.all_animal_learned_day(animals_group_mixed==select_group),'UniformOutput',false )
s2m_a=cellfun(@(x,y) x(y(:,2)==1,2),data2.all_animal_stim2move_med(animals_group_mixed==select_group),data2.all_animal_learned_day(animals_group_mixed==select_group),'UniformOutput',false )
s2m_v1=cellfun(@(x) x(1:5),s2m_v,'UniformOutput',false)
s2m_a1=cellfun(@(x) x(1:5),s2m_a,'UniformOutput',false)


mean_s2m_v=mean(cat(2,s2m_v1{:}),2)
sem_s2m_v=std(cat(2,s2m_v1{:}),0,2)/sqrt(length(all_animal_stim2move_med(animals_group_mixed==1)))

mean_s2m_a=mean(cat(2,s2m_a1{:}),2)
sem_s2m_a=std(cat(2,s2m_a1{:}),0,2)/sqrt(length(all_animal_stim2move_med(animals_group_mixed==1)))

nexttile
ap.errorfill(1:5,mean_s2m_v, sem_s2m_v,[0 0 1],0.1,0.5);
ap.errorfill(1:5,mean_s2m_a, sem_s2m_a,[1 0 0],0.1,0.5);
ylim([0 0.7])
xlabel('training days')
ylabel('stim to move (s)')



nexttile;
AV_plot=A_V(:,find(animals_group==4));
AV_plot_p = AV_plot(find(any(~isnan(AV_plot), 2), 1):end, :);
V_only_plot=V_only(:,find(animals_group==1));
V_only_plot_p = V_only_plot(find(any(~isnan(AV_plot), 2), 1):find(any(~isnan(V_only_plot), 2), 1, 'last'), :);
xlim([1 size(V_only_plot_p,1)])

hold on
plot(AV_plot_p,'Color', [1 0.8 0.8]);
h1= plot(nanmean(AV_plot_p,2),'Color', [1 0 0],'LineWidth',2);
plot(V_only_plot_p,'Color', [0.8 0.8 1]);
h2= plot(nanmean(V_only_plot_p,2),'Color', [0 0 1],'LineWidth',2);
% xline(max_len_V,'LineWidth',1,'Color', [0.5 0.5 0.5], 'LineStyle', '--')
yline(0.1)

legend([h1, h2],{['A-V, n=' num2str(sum(animals_group==4)) ],['only V, n=' num2str(sum(animals_group==1)) ]});
ylabel('stim to move (s)')
xlabel('training days ')
ylim([0 0.7])
ax = gca;
ylim1 = ax.YLim;
bg1 =rectangle('Position', [0, ylim1(1), find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)-4.5, diff(ylim1)], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
uistack(bg1, 'bottom');
bg2 =rectangle('Position', [find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)-4.5, ylim1(1), find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)-5, diff(ylim1)], 'FaceColor', '#FFB2B2', 'EdgeColor', 'none');
uistack(bg2, 'bottom');
bg3 =rectangle('Position', [find(any(~isnan(V_only_plot), 2), 1)-find(any(~isnan(AV_plot), 2), 1)-0.5, ylim1(1), find(any(~isnan(V_only_plot), 2), 1, 'last')-find(any(~isnan(V_only_plot), 2), 1)+1.5, diff(ylim1)], 'FaceColor','#DAE3F3' , 'EdgeColor', 'none');
uistack(bg3, 'bottom');


animals_group_mixed=[ 1 1 1 1 1 5 2 3 3 3 4 4 4 4 4];
select_group=4

s2m_v=cellfun(@(x,y) x(y(:,1)==1,1),data2.all_animal_stim2move_med(animals_group_mixed==select_group),data2.all_animal_learned_day(animals_group_mixed==select_group),'UniformOutput',false )
s2m_a=cellfun(@(x,y) x(y(:,2)==1,2),data2.all_animal_stim2move_med(animals_group_mixed==select_group),data2.all_animal_learned_day(animals_group_mixed==select_group),'UniformOutput',false )
s2m_v1=cellfun(@(x) x(1:5),s2m_v,'UniformOutput',false)
s2m_a1=cellfun(@(x) x(1:5),s2m_a,'UniformOutput',false)


mean_s2m_v=mean(cat(2,s2m_v1{:}),2)
sem_s2m_v=std(cat(2,s2m_v1{:}),0,2)/sqrt(length(all_animal_stim2move_med(animals_group_mixed==1)))

mean_s2m_a=mean(cat(2,s2m_a1{:}),2)
sem_s2m_a=std(cat(2,s2m_a1{:}),0,2)/sqrt(length(all_animal_stim2move_med(animals_group_mixed==1)))

nexttile
ap.errorfill(1:5,mean_s2m_v, sem_s2m_v,[0 0 1],0.1,0.5);
ap.errorfill(1:5,mean_s2m_a, sem_s2m_a,[1 0 0],0.1,0.5);
ylim([0 0.7])
xlabel('training days')
ylabel('stim to move (s)')


saveas(gcf,[Path 'figures\summary\behavior of s2m in V or A task across day'], 'jpg');

