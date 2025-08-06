
%% reaction time vs performance cross modality
clear all
Path = 'D:\Data process\wf_data\';
p_thres=0.01;
rxt_1=cell(2,1);
rxt_2=cell(2,1);
perform_1=cell(2,1);
perform_2=cell(2,1);
rxt_3=cell(2,1);
perform_3=cell(2,1);
p_all=cell(2,1);
performance_align=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
    end

    p_val=cell(length(animals),1);
    reaction_time=cell(length(animals),1);
    reward_time=cell(length(animals),1);
    reaction_time_null=cell(length(animals),1);

    workflow_name=cell(length(animals),1);
    performance=cell(length(animals),1);
    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        tem_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
        idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

        tem_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
        tem_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
        tem_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,2)...
            raw_data_behavior.rxn_l_mad_p(idx_m,3)];

        p_val{curr_animal}=tem_p;


        temp_reaction_time=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time(idx_v)= raw_data_behavior.stim2move_med(idx_v,1);
        temp_reaction_time(idx_a)=raw_data_behavior.stim2move_med(idx_a,1);
        temp_reaction_time(idx_m,:)= [raw_data_behavior.stim2move_med(idx_m,2)...
            raw_data_behavior.stim2move_med(idx_m,3)];

        temp_reaction_time_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_null(idx_v)= raw_data_behavior.stim2move_med_null(idx_v,1);
        temp_reaction_time_null(idx_a)=raw_data_behavior.stim2move_med_null(idx_a,1);
        temp_reaction_time_null(idx_m,:)= [raw_data_behavior.stim2move_med_null(idx_m,2)...
            raw_data_behavior.stim2move_med_null(idx_m,3)];


        reaction_time{curr_animal}=temp_reaction_time;
        reaction_time_null{curr_animal}=temp_reaction_time_null;



        temp_reaction_time_mad=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad(idx_v)= raw_data_behavior.stim2move_mad(idx_v,1);
        temp_reaction_time_mad(idx_a)=raw_data_behavior.stim2lastmove_mad(idx_a,1);
        temp_reaction_time_mad(idx_m,:)= [raw_data_behavior.stim2move_mad(idx_m,2)...
            raw_data_behavior.stim2lastmove_mad(idx_m,3)];

        temp_reaction_time_mad_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad_null(idx_v)= raw_data_behavior.stim2move_mad_null(idx_v,1);
        temp_reaction_time_mad_null(idx_a)=raw_data_behavior.stim2lastmove_mad_null(idx_a,1);
        temp_reaction_time_mad_null(idx_m,:)= [raw_data_behavior.stim2move_mad_null(idx_m,2)...
            raw_data_behavior.stim2lastmove_mad_null(idx_m,3)];




        performance{curr_animal}=(temp_reaction_time_mad_null-temp_reaction_time_mad)./(temp_reaction_time_mad+temp_reaction_time_mad_null);


        reward_time{curr_animal}=cellfun(@mean ,raw_data_behavior.stim_on2off_times,'UniformOutput',true);
        workflow_name{curr_animal}=raw_data_behavior.workflow_name ;
    end
    p_all{curr_group}= p_val;
    % task_name=unique(workflow_name{1},'stable');

    max_l1=8

    asso_day_mod1{curr_group}=cellfun(@(p,name) sum(p(strcmp(n1_name,name))>0.01,1)  ,p_val, workflow_name,'UniformOutput',true)
    asso_day_mod2{curr_group}=cellfun(@(p,name) sum(p( strcmp(n2_name,name))>0.01,1)  ,p_val, workflow_name,'UniformOutput',true)

    rxt_mad_1 =cellfun(@(rxt,p,name)  rxt(find( strcmp(n1_name,name) &p>0,1,"first"): find( strcmp(n1_name,name) &p>0,1,"last") )  ,...
        reaction_time,p_val,workflow_name ,'UniformOutput',false);
    temp_rxt=cellfun(@(x) x(max(1,end-max_l1+1):end),rxt_mad_1,'UniformOutput',false);
    % temp_rxt=cellfun(@(x) x(1: min(8,length(x))),rxt_mad_1,'UniformOutput',false);
    rxt_1{curr_group}=cell2mat(cellfun(@(x) [nan(1,max_l1-length(x)) x],temp_rxt,'UniformOutput',false))

    performance_1=cellfun(@(rxt,p,name)  rxt(find( strcmp(n1_name,name) &p>0,1,"first"): find( strcmp(n1_name,name) &p>0,1,"last") )  ,...
        performance,p_val,workflow_name ,'UniformOutput',false);
    temp_perform=cellfun(@(x) x(max(1,end-max_l1+1):end),performance_1,'UniformOutput',false);
    % temp_perform=cellfun(@(x) x(1: min(8,length(x))),performance_1,'UniformOutput',false);
    perform_1{curr_group}=cell2mat(cellfun(@(x) [nan(1,max_l1-length(x)) x],temp_perform,'UniformOutput',false));


    max_l2=8
    rxt_mean_2=cellfun(@(rxt,p,name)  rxt(find( strcmp(n2_name,name)))' ,...
        reaction_time,p_val,workflow_name ,'UniformOutput',false);
    % temp_rxt=cellfun(@(x) x(max(1,end-7):end),rxt_mad_2,'UniformOutput',false);
    temp_rxt=cellfun(@(x) x(1: min(max_l2,length(x))),rxt_mean_2,'UniformOutput',false);

    % max_l2=max(cellfun(@(x) length(x),rxt_mad_2,'UniformOutput',true));
    rxt_2{curr_group}=cell2mat(cellfun(@(x) [x nan(1,max_l2-length(x))],temp_rxt,'UniformOutput',false));

    performance_2=cellfun(@(rxt,p,name)  rxt(find( strcmp(n2_name,name) ) )' ,...
        performance,p_val,workflow_name ,'UniformOutput',false);
    % temp_perform=cellfun(@(x) x(max(1,end-7):end),performance_2,'UniformOutput',false);
    temp_perform=cellfun(@(x) x(1: min(8,length(x))),performance_2,'UniformOutput',false);
    perform_2{curr_group}=cell2mat(cellfun(@(x) [x nan(1,max_l2-length(x))],temp_perform,'UniformOutput',false));


    rxt_mean_3 =cellfun(@(rxt,p,name)  {rxt(find( strcmp('mixed VA',name) &p(:,1)<0.01& rxt(:,1)<2 ),1),...
        rxt(find( strcmp('mixed VA',name) &p(:,2)<0.01 & rxt(:,2)<2),2)}  ,...
        reaction_time,p_val,workflow_name ,'UniformOutput',false);


    performance_3 =cellfun(@(rxt,p,name)  {rxt(find( strcmp('mixed VA',name) &p(:,1)<0.01),1),...
        rxt(find( strcmp('mixed VA',name) &p(:,2)<0.01),2)}  ,...
        performance,p_val,workflow_name ,'UniformOutput',false);
    rxt_3{curr_group}=cellfun(@(x)  nanmean(x) , vertcat(rxt_mean_3{:}),'UniformOutput',true);
    perform_3{curr_group}=cellfun(@(x)  nanmean(x) , vertcat(performance_3{:}),'UniformOutput',true);



% aligned to learning stages

performance_pre0_temp=cellfun(@(perf,p,name)  perf(find( strcmp(n1_name,name) &p(:,1)>p_thres),1 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
idx_only1=cellfun(@(x) length(x)<2,performance_pre0_temp,'UniformOutput',true)

performance_pre0=cell(length(animals),1);
performance_pre0(~idx_only1,1) = cellfun(@(x) x(1:end-2),performance_pre0_temp(~idx_only1,1),'UniformOutput',false);
performance_pre0 = cellfun(@(x) nanmean(x),performance_pre0,'UniformOutput',false);


performance_pre1=cell(length(animals),1);
performance_pre1(~idx_only1)=cellfun(@(x)  x(end-1:end), performance_pre0_temp(~idx_only1),'UniformOutput',false  )
performance_pre1= cellfun(@(x) ...
    [x ;nan(2-length(x),1)],performance_pre1,'UniformOutput',false);

performance_post1=cell(length(animals),1);
performance_post1=cellfun(@(perf,p,name)  perf(find( strcmp(n1_name,name) &p(:,1)<p_thres,5,'first'),1 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
performance_post1= cellfun(@(x) ...
    [x ; nan(5-length(x),1)],performance_post1,'UniformOutput',false);

performance_pre2=cell(length(animals),1);
performance_pre2=cellfun(@(perf,p,name)  perf(find( strcmp(n2_name,name) &p(:,1)>p_thres,2,'first'),1 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
performance_pre2= cellfun(@(x) ...
    [x ;nan(2-length(x),1)],performance_pre2,'UniformOutput',false);

performance_post2=cell(length(animals),1);
performance_post2=cellfun(@(perf,p,name)  perf(find( strcmp(n2_name,name) &p(:,1)<p_thres,5,'first'),1 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
performance_post2= cellfun(@(x) ...
    [x ;nan(5-length(x),1)],performance_post2,'UniformOutput',false);

performance_post3_v=cell(length(animals),1);
performance_post3_v=cellfun(@(perf,p,name)  perf(find( strcmp('mixed VA',name) &p(:,1)<p_thres,3,'first'),1 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
performance_post3_v= cellfun(@(x) ...
    [x ;nan(3-length(x),1)],performance_post3_v,'UniformOutput',false);

performance_post3_a=cell(length(animals),1);
performance_post3_a=cellfun(@(perf,p,name)  perf(find( strcmp('mixed VA',name) &p(:,1)<p_thres,3,'first'),2 )  ,...
    performance,p_val,workflow_name ,'UniformOutput',false);
performance_post3_a= cellfun(@(x) ...
    [x ;nan(3-length(x),1)],performance_post3_a,'UniformOutput',false);

performance_align{curr_group}=cellfun(@(a1,a2,a3,a4,a5,a6,a7,a8)  [a1;a2;a3;a4;a5;a6;a7;a8(1:5)'] ...
    ,performance_pre0,performance_pre1,performance_post1,...
    performance_pre2,performance_post2,performance_post3_v,...
    performance_post3_a,performance_2,'UniformOutput',false);

end
save([Path 'summary_data\behavior.mat'],'performance_align','-v7.3')
%
legned_name={'VA';'AV'};

figure('Position', [50 50 400 200]);
t1 = tiledlayout(1,2, 'TileSpacing', 'loose', 'Padding', 'loose');
corlors={[84 130 53]./255,[112  48 160]./255}
barColors = [[   187 205 174]./255;[ 198 172 217]./255]; % 浅蓝、浅红
scatterColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红
nexttile
for curr_group=1:2
hold on
ap.errorfill(1:max_l1, median(rxt_1{curr_group},1,'omitmissing'),std(rxt_1{curr_group},0,1,'omitmissing')./...
    sqrt(size(rxt_1{curr_group},1)),corlors{curr_group},0.1,0.5)
ap.errorfill(max_l1+1:max_l1+max_l2, median(rxt_2{curr_group},1,'omitmissing'),std(rxt_2{curr_group},0,1,'omitmissing')./...
    sqrt(size(rxt_2{curr_group},1)),corlors{curr_group},0.1,0.5)
end

xlim([2.5 max_l1+max_l2+0])
xticks([max_l1/2+0.5 max_l1+max_l2/2+0.5 max_l1+max_l2+1.5  max_l1+max_l2+3.5])
xticklabels({'mod1','mod2','mixed V','mixed A'})
xline(max_l1+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
xline(max_l1+max_l2+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
ylabel('reaction time(s)')
 ylim([0  0.5])
yticks([ 0  0.5])
 % set(gca, 'YScale', 'log');

nexttile
for curr_group=1:2
    hold on
    ap.errorfill(1:max_l1, median(perform_1{curr_group},1,'omitmissing'),...
        std(perform_1{curr_group},0,1,'omitmissing')/sqrt(size(perform_1{curr_group},1)),corlors{curr_group},0.1,0.5)
    ap.errorfill(max_l1+1:max_l1+max_l2, median(perform_2{curr_group},1,'omitmissing'),...
        std(perform_2{curr_group},0,1,'omitmissing')/sqrt(size(perform_2{curr_group},1)),corlors{curr_group},0.1,0.5)
end

xline(max_l1+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
xline(max_l1+max_l2+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])

xlim([1 max_l1+max_l2])
xticks([max_l1/2+0.5 max_l1+max_l2/2+0.5 max_l1+max_l2+1.5  max_l1+max_l2+3.5])
xticklabels({'mod1','mod2','mixed V','mixed A'})
ylabel('performance')
% legend({'',legned_name{1},'','','','','',legned_name{2}},'Location','northoutside','Box','off','Orientation','horizontal')
ylim([0 0.8])
yticks([0 0.8])
     % saveas(gcf,[Path 'figures\summary\figures\behavioral performance' ], 'jpg');



     figure
for curr_group=1:2

    temp_mean=nanmean(cat(3,performance_align{curr_group}{:}),3)
    temp_error=std(cat(3,performance_align{curr_group}{:}),0,3,'omitmissing')./sqrt(size(performance_align{curr_group},1))

hold on
ap.errorfill(1:8, temp_mean(1:8),temp_error(1:8),corlors{curr_group},0.1,0.5)
ap.errorfill(9:13, temp_mean(22:26),temp_error(22:26),corlors{curr_group},0.1,0.5)

end




%%
     figure('Position', [50 50 350 200]);
     t1 = tiledlayout(1,2, 'TileSpacing', 'loose', 'Padding', 'loose');
     nexttile()
     hold on
     for curr_group=1:2
         errorbar([0 2]+curr_group, median(rxt_3{curr_group},1,'omitmissing'), std(rxt_3{curr_group},0,1,'omitmissing')./sqrt(size(rxt_3{curr_group},1)),...
             'o','LineStyle', 'none',...
             'CapSize', 5,...
             'MarkerEdgeColor', scatterColors(curr_group,:), ...
             'MarkerFaceColor', scatterColors(curr_group,:), ...
             'Color', scatterColors(curr_group,:),...
             'LineWidth',2,'MarkerSize',5)
     end
     xlim([0 5])
     ylabel('reaction time(s)')
     ylim([0.05  10])
     xticks([1.5 3.5])
     xticklabels({'mixed V','mixed A'})
     set(gca, 'YScale', 'log', 'Color', 'none');

     nexttile
     hold on
     for curr_group=1:2
         errorbar([0 2]+curr_group, median(perform_3{curr_group},1,'omitmissing'), std(perform_3{curr_group},0,1,'omitmissing')./sqrt(size(rxt_3{curr_group},1)),...
             'o','LineStyle', 'none',...
             'CapSize', 5,...
             'MarkerEdgeColor', scatterColors(curr_group,:), ...
             'MarkerFaceColor', scatterColors(curr_group,:), ...
             'Color', scatterColors(curr_group,:),...
             'LineWidth',2,'MarkerSize',5)
     end

ylabel('performance')
     xlim([0 5])

ylim([0 0.8])
xticks([1.5 3.5])
xticklabels({'mixed V','mixed A'})
     set(gca, 'Color', 'none');



%%

clear all
Path = 'D:\Data process\wf_data\';

asso_day_mod1=cell(2,1);
asso_day_mod2=cell(2,1);
asso_day_mod2_learn=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016','DS013','DS006'};n1_name='audio volume';n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
    end

    p_val=cell(length(animals),1);
    reaction_time=cell(length(animals),1);
    reward_time=cell(length(animals),1);
    reaction_time_null=cell(length(animals),1);

    workflow_name=cell(length(animals),1);
    performance=cell(length(animals),1);
    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        tem_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
        idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

        tem_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
        tem_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
        tem_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,2)...
            raw_data_behavior.rxn_l_mad_p(idx_m,3)];

        p_val{curr_animal}=tem_p;


        temp_reaction_time=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time(idx_v)= raw_data_behavior.stim2move_med(idx_v,1);
        temp_reaction_time(idx_a)=raw_data_behavior.stim2move_med(idx_a,1);
        temp_reaction_time(idx_m,:)= [raw_data_behavior.stim2move_med(idx_m,2)...
            raw_data_behavior.stim2move_med(idx_m,3)];

        temp_reaction_time_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_null(idx_v)= raw_data_behavior.stim2move_med_null(idx_v,1);
        temp_reaction_time_null(idx_a)=raw_data_behavior.stim2move_med_null(idx_a,1);
        temp_reaction_time_null(idx_m,:)= [raw_data_behavior.stim2move_med_null(idx_m,2)...
            raw_data_behavior.stim2move_med_null(idx_m,3)];


        reaction_time{curr_animal}=temp_reaction_time;
        reaction_time_null{curr_animal}=temp_reaction_time_null;



        temp_reaction_time_mad=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad(idx_v)= raw_data_behavior.stim2move_mad(idx_v,1);
        temp_reaction_time_mad(idx_a)=raw_data_behavior.stim2lastmove_mad(idx_a,1);
        temp_reaction_time_mad(idx_m,:)= [raw_data_behavior.stim2move_mad(idx_m,2)...
            raw_data_behavior.stim2move_mad(idx_m,3)];

        temp_reaction_time_mad_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad_null(idx_v)= raw_data_behavior.stim2move_mad_null(idx_v,1);
        temp_reaction_time_mad_null(idx_a)=raw_data_behavior.stim2lastmove_mad_null(idx_a,1);
        temp_reaction_time_mad_null(idx_m,:)= [raw_data_behavior.stim2move_mad_null(idx_m,2)...
            raw_data_behavior.stim2move_mad_null(idx_m,3)];




        performance{curr_animal}=(temp_reaction_time_mad_null-temp_reaction_time_mad)./(temp_reaction_time_mad+temp_reaction_time_mad_null);


        reward_time{curr_animal}=cellfun(@mean ,raw_data_behavior.stim_on2off_times,'UniformOutput',true);
        workflow_name{curr_animal}=raw_data_behavior.workflow_name ;
    end
    p_all{curr_group}= p_val;
    % task_name=unique(workflow_name{1},'stable');

    max_l1=8

   asso_day_mod1{curr_group}=cellfun(@(p,name) sum(p(strcmp(n1_name,name))>0.01,1)  ,p_val, workflow_name,'UniformOutput',true)
   asso_day_mod2{curr_group}=cellfun(@(p,name) sum(p( strcmp(n2_name,name))>0.01,1)  ,p_val, workflow_name,'UniformOutput',true)

   asso_day_mod2_learn{curr_group}=cellfun(@(p,name) sum(p( strcmp(n2_name,name))<0.01,1)>3 ,p_val, workflow_name,'UniformOutput',true)




end
%% Bar of first association day in stage1 & 2

% 定义颜色
barColors = [[   187 205 174]./255;[ 198 172 217]./255]; % 浅蓝、浅红
scatterColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红
% cellfun(@(x,y) x(y),asso_day_mod1,asso_day_mod2_learn,'UniformOutput',false)
num_stage = {asso_day_mod1,...
    cellfun(@(x,y) x(y),asso_day_mod2,asso_day_mod2_learn,'UniformOutput',false)};
figure('Position',[50 50 300 200]);
t1 = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact');

for curr_stage=1:2
buff_stage=num_stage{curr_stage};
  
% 计算均值和标准误差
means = cellfun(@mean, buff_stage);
stds = cellfun(@std, buff_stage);
nSamples = cellfun(@length, buff_stage);
sem = stds ./ sqrt(nSamples);  % 计算标准误 SEM
nexttile
% 创建柱状图，并确保 `bar` 只返回一个 `Bar` 对象数组
 hold on;
barHandle = bar(1:2, means, 0.5, 'FaceColor', 'flat'); % 'FaceColor' 只能用于单个柱子时指定
% 逐个设置柱子的颜色
if length(barHandle) == 1  % 仅有一个 bar 对象时
    barHandle.FaceColor = 'flat'; % 确保它接受颜色
    barHandle.CData = barColors; % 为不同组设置不同颜色
else
    for i = 1:2
        barHandle(i).FaceColor = barColors(i, :);
    end
end
% 添加误差条
errorbar(1:2, means, sem, 'k', 'LineStyle', 'none', 'LineWidth', 1.5); % 黑色误差条
% 设置横向抖动强度
jitterAmount = 0.1;
% 绘制散点并防止重叠
for i = 1:2
    yData = buff_stage{i}'; % 获取当前组数据
    xData = i * ones(size(yData)); % 初始 x 轴位置
    
    % 计算重复的 y 值，并添加横向抖动
    uniqueValues = unique(yData);
    for j = 1:length(uniqueValues)
        idx = (yData == uniqueValues(j)); % 找到所有相同的值
        numDuplicates = sum(idx);
        
        % 生成横向抖动
        xData(idx) = xData(idx) + linspace(-jitterAmount, jitterAmount, numDuplicates);
    end
    
    scatter(xData, yData, 50, scatterColors(i, :), 'filled'); % 绘制散点
end
ylim([0 8])
% 美化图像
xticks([1 2]);
xticklabels({'VA', 'AV'});
ylabel(['days to learn mod '  num2str(curr_stage)]);
% title('Bar Chart with Error Bars and Scatter Points');
grid off;
hold off;
end

% saveas(gcf,[Path 'figures\summary\figures\figure 1 days to learm modality1&2 '  ], 'jpg');

 %%  wheel velocity
 clear all
Path = 'D:\Data process\wf_data\';
barColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


rxt_1=cell(2,1);
rxt_2=cell(2,1);
perform_1=cell(2,1);
perform_2=cell(2,1);
rxt_3=cell(2,1);
perform_3=cell(2,1);
p_all=cell(2,1);
vel_all_mod1=cell(2,1);
vel_all_mod2=cell(2,1);
vel_all_mix=cell(2,1);
vel_all=cell(2,1);

vel_mod1_all=cell(2,1);
vel_mod2_all=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
    end

    p_val=cell(length(animals),1);
    reaction_time=cell(length(animals),1);
    reward_time=cell(length(animals),1);
    reaction_time_null=cell(length(animals),1);

    velocity=cell(2,1);
    workflow_name=cell(length(animals),1);
    performance=cell(length(animals),1);
    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        tem_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
        idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

        tem_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
        tem_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
        tem_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,2)...
            raw_data_behavior.rxn_l_mad_p(idx_m,3)];

        p_val{curr_animal}=tem_p;
        velocity{curr_animal}=raw_data_behavior.frac_velocity_stimalign;
        workflow_name{curr_animal}=raw_data_behavior.workflow_name ;


    end
    
    
    max_l1=8
    temp_vel_mod1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name) ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_mod1=  cellfun(@(x) cellfun(@(a) nanmean(a,1),x,'UniformOutput',false ) ,...
        temp_vel_mod1,'UniformOutput',false);

    temp_vel_mod1=cellfun(@(x) x(1: min(max_l1,length(x))),temp_vel_mod1,'UniformOutput',false);
    vel_mod1_all{curr_group}=cellfun(@(x) [ nan(max_l1-length(x),1001); cell2mat(x)],temp_vel_mod1,'UniformOutput',false);

    

    temp_vel_mod2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name) ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_mod2=  cellfun(@(x) cellfun(@(a) nanmean(a,1),x,'UniformOutput',false ) ,...
        temp_vel_mod2,'UniformOutput',false);
    temp_vel_mod2=cellfun(@(x) x(1: min(max_l1,length(x))),temp_vel_mod2,'UniformOutput',false);
    vel_mod2_all{curr_group}=cellfun(@(x) [ cell2mat(x); nan(max_l1-length(x),1001)],temp_vel_mod2,'UniformOutput',false);


    temp_vel_pre0=cell(length(animals{curr_group}),1);
    temp_vel_pre0=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)>=0.01 ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_pre0 = cellfun(@(x) x(1:end-2),temp_vel_pre0,'UniformOutput',false);
    temp_vel_pre0 = cellfun(@(x) nanmean(cat(1,x{:}),1),temp_vel_pre0,'UniformOutput',false);
    temp_vel_pre0= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},1-length(x),1)],temp_vel_pre0,'UniformOutput',false);

    temp_vel_pre1=cell(length(animals{curr_group}),1);
    temp_vel_pre1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)>=0.01,2,"last" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_pre1 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_pre1,'UniformOutput',false);
    temp_vel_pre1= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},2-length(x),1)],temp_vel_pre1,'UniformOutput',false);

    temp_vel_post1=cell(length(animals{curr_group}),1);
    temp_vel_post1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)<0.01,5,"first" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_post1 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_post1,'UniformOutput',false);
    temp_vel_post1= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},5-length(x),1)],temp_vel_post1,'UniformOutput',false);

    temp_vel_pre2=cell(length(animals{curr_group}),1);
    temp_vel_pre2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name)&p(:,1)>=0.01,2,"first" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_pre2 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_pre2,'UniformOutput',false);
    temp_vel_pre2= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},2-length(x),1)],temp_vel_pre2,'UniformOutput',false);

    temp_vel_post2=cell(length(animals{curr_group}),1);
    temp_vel_post2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name)&p(:,1)<0.01,5,"first" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_post2 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_post2,'UniformOutput',false);
    temp_vel_post2= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},5-length(x),1)],temp_vel_post2,'UniformOutput',false);

    n3_name='mixed VA';
    mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),workflow_name ,'UniformOutput',true);
    temp_itimove_mix=cell(length(animals{curr_group}),1);
    temp_itimove_mix(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,1)<0.01,3,"first" ),2) ,...
        velocity(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);
    temp_itimove_mix(mixed_idx,1) =cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false), temp_itimove_mix(mixed_idx,1),'UniformOutput',false);

    temp_itimove_mix(mixed_idx,1)=cellfun(@(x) ...
        [x; repmat({nan(1,1001)},3-length(x),1)],temp_itimove_mix(mixed_idx,1),'UniformOutput',false);
    temp_itimove_mix(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},3,1),...
        (1:length(find(~mixed_idx)))', 'UniformOutput', false);

    temp_vel_mix_a=cell(length(animals{curr_group}),1);
    temp_vel_mix_a(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,2)<0.01,3,"first" ),3) ,...
        velocity(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);
    temp_vel_mix_a(mixed_idx,1) =cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false), temp_vel_mix_a(mixed_idx,1),'UniformOutput',false);
    temp_vel_mix_a(mixed_idx,1)=cellfun(@(x) ...
        [x; repmat({nan(1,1001)},3-length(x),1)],temp_vel_mix_a(mixed_idx,1),'UniformOutput',false);
    temp_vel_mix_a(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},3,1),...
        (1:length(find(~mixed_idx)))', 'UniformOutput', false);

    vel_all{curr_group}=cellfun(@(a0,a,b,c,d,e,f) cell2mat([a0 ;a; b; c; d; e ;f]),temp_vel_pre0, temp_vel_pre1,temp_vel_post1,temp_vel_pre2,...
        temp_vel_post2,temp_itimove_mix,temp_vel_mix_a,'UniformOutput',false);


end

vel_mean=cellfun(@(x)  nanmean(cat(3,x{:}),3)    ,vel_all,'UniformOutput',false);
vel_error=cellfun(@(x)  std(cat(3,x{:}),0,3,'omitmissing')./sqrt(size(cat(3,x{:}),3))    ,vel_all,'UniformOutput',false);

vel_plot_mean=cellfun(@(x)  -nanmean(min(cat(3,x{:}),[],2) ,3)   ,vel_all,'UniformOutput',false)
vel_plot_error=cellfun(@(x)  std(min(cat(3,x{:}),[],2) ,0,3,'omitmissing')/sqrt(size(x,1))   ,vel_all,'UniformOutput',false)



vel_temp_0 =cellfun(@(x) cat(3,x{:}) ,vel_all,'UniformOutput',false );

vel_temp_mix=cellfun(@(x) {permute( nanmean(x(16:18,:,:),1) ,[2,3,1]) ; permute( nanmean(x(19:21,:,:),1) ,[2,3,1]) } ,vel_temp_0,'UniformOutput',false);
vel_temp_mix_mean=cellfun(@(x) cellfun(@(a) nanmean(a,2)  ,x,'UniformOutput',false), vel_temp_mix,'UniformOutput',false );
vel_temp_mix_error=cellfun(@(x) cellfun(@(a) std(a,0,2,'omitmissing')./sqrt(size(a,2))  ,x,'UniformOutput',false), vel_temp_mix,'UniformOutput',false );

vel_temp_mix_peak=cellfun(@(x) [permute( min(nanmean(x(16:18,:,:),1),[],2) ,[3,2,1])  permute( min(nanmean(x(19:21,:,:),1),[],2) ,[3,2,1]) ]  ,vel_temp_0,'UniformOutput',false)
vel_temp_mix_peak_mean=cellfun(@(x)  -nanmean(x,1),vel_temp_mix_peak,'UniformOutput',false);
vel_temp_mix_peak_error=cellfun(@(x)  std(x,0,1,'omitmissing')./sqrt(size(x,1)),vel_temp_mix_peak,'UniformOutput',false);

figure('Position',[50 50 1000 200]);
t1 = tiledlayout(1,5, 'TileSpacing', 'compact', 'Padding', 'compact');

for curr_group=1:2
    nexttile(1)
vel_mod1_plot_mean=-nanmean(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),3);
vel_mod1_plot_error=std(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),3));

vel_mod2_plot_mean=-nanmean(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),3);
vel_mod2_plot_error=std(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),3));

ap.errorfill(1:8,vel_mod1_plot_mean,vel_mod1_plot_error,barColors(curr_group,:),0.1,0.5)
ap.errorfill(9:13,vel_mod2_plot_mean(1:5),vel_mod2_plot_error(1:5),barColors(curr_group,:),0.1,0.5)

hold on
errorbar([13 15]+curr_group,vel_temp_mix_peak_mean{curr_group},vel_temp_mix_peak_error{curr_group},...
    'LineStyle','none','Color',barColors(curr_group,:),'LineWidth',1.5);
scatter([13 15]+curr_group,vel_temp_mix_peak_mean{curr_group},'MarkerFaceColor',barColors(curr_group,:),'MarkerEdgeColor','none');

xlim([ 1  17])
xticks([6 11 13.5 15.5])
xticklabels({'mod1','mod2','mixed V','mixed A'})
xline(8.5,'LineStyle',':')
ylim([0 3500])
yticks([0 3500])
yticklabels({'0','max'})
title('velocity','FontWeight','normal')
set(gca,'Color','none')


vel_min_mean_1=nanmean(cat(3,vel_mod1_all{curr_group}{:}),3);
vel_min_error_1=std(cat(3,vel_mod1_all{curr_group}{:}),0,3,'omitmissing')./sqrt(size(cat(3,vel_mod1_all{curr_group}{:}),3));
vel_min_mean_2=nanmean(cat(3,vel_mod2_all{curr_group}{:}),3);
vel_min_error_2=std(cat(3,vel_mod2_all{curr_group}{:}),0,3,'omitmissing')./sqrt(size(cat(3,vel_mod2_all{curr_group}{:}),3));

nexttile(2)
ap.errorfill(surround_time_points, vel_min_mean_1(8,:), vel_min_error_1(8,:),barColors(curr_group,:),0.1,0.5);
xlim([-1 2])
ylim([-3500 100])
yticks([-3500 0])
yticklabels({'max','0'})
xlabel('time (s)')
title('mod1','FontWeight','normal')
set(gca,'Color','none')

nexttile(3)
ap.errorfill(surround_time_points, vel_min_mean_2(5,:),vel_min_error_2(5,:),barColors(curr_group,:),0.1,0.5);
xlim([-1 2])
ylim([-3500 100])
yticks([-3500 0])
yticklabels({'max','0'})
xlabel('time (s)')
title('mod2','FontWeight','normal')
set(gca,'Color','none')

nexttile(4)
ap.errorfill(surround_time_points, vel_temp_mix_mean{curr_group}{1} ,vel_temp_mix_error{curr_group}{1},barColors(curr_group,:),0.1,0.5);
xlim([-1 2])
ylim([-3500 100])
yticks([-3500 0])
yticklabels({'max','0'})
xlabel('time (s)')
title('mixed V','FontWeight','normal')
set(gca,'Color','none')

nexttile(5)
ap.errorfill(surround_time_points, vel_temp_mix_mean{curr_group}{2} ,vel_temp_mix_error{curr_group}{2},barColors(curr_group,:),0.1,0.5);
xlim([-1 2])
ylim([-3500 100])
yticks([-3500 0])
yticklabels({'max','0'})
xlabel('time (s)')
title('mixed A','FontWeight','normal')
set(gca,'Color','none')

end


 %%  iti move
 clear all
Path = 'D:\Data process\wf_data\';
barColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


itimove_mod1_all=cell(2,1);
itimove_mod2_all=cell(2,1);
itimove_mix_all=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
    end

    p_val=cell(length(animals),1);
    itimove=cell(2,1);
        itimove_all=cell(2,1);

    workflow_name=cell(length(animals),1);

    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        tem_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
        idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

        tem_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
        tem_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
        tem_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,2)...
            raw_data_behavior.rxn_l_mad_p(idx_m,3)];

        p_val{curr_animal}=tem_p;
         itimove{curr_animal}=cellfun(@(x,y) length(x)/length(y),raw_data_behavior.iti_move,  raw_data_behavior.stim2move_times(:,1),'UniformOutput',true);
        itimove_all{curr_animal}=cellfun(@(x,y) length(x)/length(y),raw_data_behavior.all_iti_move,  raw_data_behavior.stim2move_times(:,1),'UniformOutput',true);

        workflow_name{curr_animal}=raw_data_behavior.workflow_name;
    end
    
    
    max_l1=8
    temp_itimove_mod1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name) )) ,...
        itimove,workflow_name,p_val,'UniformOutput',false);
    temp_itimove_mod1=cellfun(@(x) x(1: min(max_l1,length(x))),temp_itimove_mod1,'UniformOutput',false);
    itimove_mod1_all{curr_group}=cellfun(@(x) [ nan(max_l1-length(x),1);  x],temp_itimove_mod1,'UniformOutput',false);


    temp_itimove_mod2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name) )) ,...
        itimove,workflow_name,p_val,'UniformOutput',false);
 
    temp_itimove_mod2=cellfun(@(x) x(1: min(max_l1,length(x))),temp_itimove_mod2,'UniformOutput',false);
    itimove_mod2_all{curr_group}=cellfun(@(x) [ x ;nan(max_l1-length(x),1)],temp_itimove_mod2,'UniformOutput',false);

    n3_name='mixed VA';
    mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),workflow_name ,'UniformOutput',true);
    temp_itimove_mix=cell(length(animals{curr_group}),1);
    temp_itimove_mix(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,1)<0.01,3,"first" )) ,...
        itimove(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);



    temp_itimove_mix(mixed_idx,1)=cellfun(@(x) ...
        [x; nan(3-length(x),1)],temp_itimove_mix(mixed_idx,1),'UniformOutput',false);
    temp_itimove_mix(~mixed_idx) ={nan(3,1)};
    itimove_mix_all{curr_group}=temp_itimove_mix;

end


% t1 = tiledlayout(1,5, 'TileSpacing', 'compact', 'Padding', 'compact');
itimove_temp_mix_peak_mean=cellfun(@(x)  nanmean(cellfun(@(a)  nanmean(a) ,x,'UniformOutput',true ) ) ,itimove_mix_all,'UniformOutput',false)
itimove_temp_mix_peak_error=cellfun(@(x)  std(cellfun(@(a)  nanmean(a) ,x,'UniformOutput',true ),'omitmissing')/sqrt(length(x))  ,itimove_mix_all,'UniformOutput',false)
 figure('Position',[50 50 200 200]);
for curr_group=1:2
    nexttile(1)
vel_mod1_plot_mean=nanmean(cat(2,itimove_mod1_all{curr_group}{:}),2);
vel_mod1_plot_error=std(cat(2,itimove_mod1_all{curr_group}{:}),0,2,'omitmissing')./sqrt(size(cat(2,itimove_mod1_all{curr_group}{:}),2));

vel_mod2_plot_mean=nanmean(cat(2,itimove_mod2_all{curr_group}{:}),2);
vel_mod2_plot_error=std(cat(2,itimove_mod2_all{curr_group}{:}),0,2,'omitmissing')./sqrt(size(cat(2,itimove_mod2_all{curr_group}{:}),2));

ap.errorfill(1:8,vel_mod1_plot_mean,vel_mod1_plot_error,barColors(curr_group,:),0.1,0.5)
ap.errorfill(9:16,vel_mod2_plot_mean,vel_mod2_plot_error,barColors(curr_group,:),0.1,0.5)

hold on
errorbar(16 +curr_group,itimove_temp_mix_peak_mean{curr_group},itimove_temp_mix_peak_error{curr_group},...
    'LineStyle','none','Color',barColors(curr_group,:),'LineWidth',1.5);
scatter(16 +curr_group,itimove_temp_mix_peak_mean{curr_group},'MarkerFaceColor',barColors(curr_group,:),'MarkerEdgeColor','none');

xlim([ 1  18])
xticks([4.5 12.5 17.5])
xticklabels({'mod1','mod2','mixed'})
xline(8.5,'LineStyle',':')
ylim([0 5])
yticks([0 5])
ylabel('relative move')
title('iti move','FontWeight','normal')

end
set(gca,'Color','none')

%% example behavior trace

    animal ='DS019'
    rec_day='2025-01-18'
    rec = plab.find_recordings(animal,rec_day,'*wheel*');
    rec_time = rec.recording{end};
    load_parts = struct;
    load_parts.behavior = true;
    load_parts.widefield = false;
    ap.load_recording;

%
    time_period=[  min(find(timelite.timestamps-(photodiode_on_times(16)-0.2)>0)),...
        min(find(timelite.timestamps-(photodiode_off_times(16)+0.5)>0))]

    reward_timeline =reward_thresh(time_period(1):time_period(2));  % 示例数据
    % 找出所有为 1 的索引
    idx_ones = find(reward_timeline == 1);
    % 计算相邻 1 之间的间隔
    gap_lengths = diff(idx_ones) - 1;
    % 找出 gap < 20 的区间索引
    valid = find(gap_lengths < 20 & gap_lengths > 0);
    % 创建逻辑掩码
    mask = false(size(reward_timeline));
    % 用 arrayfun 给 mask 中对应位置赋值为 true
    idx_ranges = arrayfun(@(i) idx_ones(i)+1:idx_ones(i+1)-1, valid, 'UniformOutput', false);
    mask(cell2mat(idx_ranges')) = true;
    % 应用掩码修改 vec
    reward_timeline(mask) = 1;

    %
    line_width=1;
    font_size=8;
    figure('Position',[50 50 300 150]);
    t1 = tiledlayout(4, 1, 'TileSpacing', 'loose', 'Padding', 'loose');

    hold on
    plot( photodiode_trace(time_period(1):time_period(2))>3,'LineWidth',line_width,'Color','k')
  

    plot( reward_timeline-1.1,'LineWidth',line_width,'Color','k')
   
    plot(wheel_move(time_period(1):time_period(2))-2.2,'LineWidth',line_width,'Color','k')
    % ylim([-0.1 1.1])
    hold on
    wheel_vel=wheel_velocity(time_period(1):time_period(2));
    wheel_vel_norm = (wheel_vel - min(wheel_vel)) / (max(wheel_vel) - min(wheel_vel));

    plot(wheel_vel_norm-3.3,'LineWidth',line_width,'Color','k')

 ylim([-4.5 1.5])
 axis off
 plot(lick_thresh(time_period(1):time_period(2))-4.4,'LineWidth',line_width,'Color','k')

 xline(find(photodiode_trace(time_period(1):time_period(2))>3,1,'first'),...
     'LineStyle','--','LineWidth',1, 'Color',[0.5 0.5 0.5])
 xline(find(reward_timeline==1,1,'first'),'LineStyle','--','LineWidth',1, 'Color',[0.5 0.5 0.5])
 xline(find(wheel_move(time_period(1):time_period(2))==1,1,'first'),...
     'LineStyle','--','LineWidth',1, 'Color',[0.5 0.5 0.5])

 line([find(photodiode_trace(time_period(1):time_period(2))>3,1,'first'),...
     find(wheel_move(time_period(1):time_period(2))==1,1,'first')],...
     [1.45,1.45], 'Color',[0.2 0.8 0.2],'LineWidth',1.5,'LineStyle','-')

 line([find(photodiode_trace(time_period(1):time_period(2))>3,1,'first'),...
     find(reward_timeline==1,1,'first')],[1.25,1.25],...
     'Color',[0.5 0.5 0.5],'LineWidth',1.5,'LineStyle','-')


 labels = {'stim', 'reward', 'wheel move', 'wheel velocity', 'lick'};
 y_positions = [0.3, -0.7, -1.7, -2.7, -3.9];

 cellfun(@(label, y) text(160, y, label, ...
     'FontSize', font_size, 'FontWeight', 'normal', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle'), ...
            labels, num2cell(y_positions));
xlim([-190 length(reward_timeline)])

 text(250, 1.8, 'reaction time', ...
     'FontSize', font_size, 'FontWeight', 'normal', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Color',[0.2 0.8 0.2]), ...
   
 text(1000, 1.6, 'reward time', ...
     'FontSize', font_size, 'FontWeight', 'normal', ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Color',[0.5 0.5 0.5]), ...         

    % legend({'stim','reward','wheel move','wheel velocity','lick'},'Location','eastoutside','Box','off')

    
   saveas(gcf,[Path 'figures\summary\figures\figure 1 example behavioral trace' ], 'jpg');
%% single mice behavior
clear all
Path = 'D:\Data process\wf_data\';
colors_group=[0 0 1];

% animals = {'DS000','DS004','DS014','DS015','DS016'};
% animals = {  'DS007','DS010','AP019','AP021','DS011','AP022'}
% animals={'DS010'}

% animals={'HA000','HA001','HA002','HA003','HA004','DS019','DS020','DS021','AP027','AP028','AP029'}
 % animals={'HA003','HA004','DS019','DS020'}
 % animals={'AP027','AP028','AP029','DS019','DS020','DS021'}
animals = {  'HA011','HA012','HA009','HA010'}

for curr_animal =1:length(animals)
    animal=animals{curr_animal};
    raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);
    stage=[1  2 ]
    matches=unique(raw_data_behavior.workflow_name,'stable')
    learned_days=raw_data_behavior.rxn_l_mad_p(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1)<0.01;


    % figure('Position',[50 50 200 350])
    figure('Position',[50 50 400 750])

    tiledlayout(6,1)
    sgtitle(animal,'FontWeight','normal')
    for curr_state=1:4
        switch curr_state
            case 1
                temp_data=raw_data_behavior.stim2move_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1);
                ylabel_name='reaction time(s)';
            case 2
                temp_data=raw_data_behavior.stim2lastmove_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1);
                ylabel_name='reaction time(s)';
            case 3
                temp_data=raw_data_behavior.stim_on2off_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1);
                ylabel_name='reward time(s)';
            case 4
                temp_data= cellfun(@(x) x', raw_data_behavior.iti_counts_all(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1),'UniformOutput',false);
               ylabel_name='iti move time(s)';

        end

        mergedVector = vertcat(temp_data{:});
        indexCells = cellfun(@(x, i) repmat(i, size(x)), temp_data, ...
            num2cell(1:numel(temp_data))', ...
            'UniformOutput', false);
        temp_idx=vertcat(indexCells{:});
        [~, firstIdx] = unique(temp_idx, 'stable');
        numCells = numel(temp_data);

        [unique_vals, ~, groupID] = unique(temp_idx, 'stable');
        mid_indices = splitapply(@(x) x(ceil(numel(x)/2)), (1:numel(temp_idx))', groupID);


        colors=zeros(numCells,3);
        colors(learned_days == 0, :) = repmat([0 0 0], sum(learned_days == 0), 1);
        colors(learned_days == 1, :) = repmat(colors_group, sum(learned_days == 1), 1);


        nexttile
        hold on
        for i = 1:numCells
            idx = (temp_idx == i);
            scatter(find(idx), mergedVector(idx), 10, colors(i,:), 'filled')
        end
        xline(firstIdx-0.5,':k')
        xlim([0 length(mergedVector)])
        ylim([0.05 20])
        ylabel(ylabel_name)
        % xticks(mid_indices)
        % xticklabels(1:length(mid_indices))
        xticks([])
        xlabel('days')
        if curr_state<4
            set(gca, 'YScale', 'log');
            yticks([1e-2 1e-1 1 10])
        else
            ylim([0 10])
            yticks([0 10])

        end

        drawnow

    end
    nexttile
    hold on
    yyaxis left
    set(gca, 'YColor', [0 0 0])
    ylabel('mad')
    temp_data=raw_data_behavior.stim2lastmove_mad(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1);
    temp_data_null=raw_data_behavior.stim2lastmove_mad_null(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1);
    plot(1:length(temp_data),temp_data,'LineStyle','-','Color',[0 0 0])
    plot(1:length(temp_data),temp_data_null,'LineStyle','--','Color',[0 0 0])
    set(gca, 'YScale', 'log');
  
   
    yyaxis right
    set(gca, 'YColor', colors_group)
    perform=(temp_data_null-temp_data)./(temp_data_null+temp_data)
    plot(1:length(perform),perform,'Color',colors_group)
    xlim([1 length(temp_data)])
    ylabel('perform')
if sum(learned_days)>0
    xline(find(learned_days==1,1)-0.5,'LineStyle','--')
end
    nexttile

    temp_vel= raw_data_behavior.frac_velocity_stimalign(ismember(raw_data_behavior.workflow_name,{matches{stage}}),1)
    temp_vel1= cellfun(@(x) corr(x(:,500:600)') ,temp_vel,'UniformOutput',false )

    temp_corr =cellfun(@(x) nanmean(x(~eye(size(x)))) ,temp_vel1,'UniformOutput',true);
    plot(temp_corr)
        xlim([1 length(temp_corr)])
ylim([0 0.8])
ylabel('movement correlation')

end

%%
for curr_animal =1:length(animals)
    animal=animals{curr_animal};
    raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);
    stage=3;
    matches=unique(raw_data_behavior.workflow_name,'stable')
   
    if length(matches)==2
continue
    end

    learned_days=raw_data_behavior.rxn_l_mad_p(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3])<0.01;


    % figure('Position',[50 50 200 350])
    figure('Position',[50 50 400 750])

    tiledlayout(4,2)
    sgtitle(animal,'FontWeight','normal')
    for curr_state=1:3
        switch curr_state
            case 1
                temp_data=raw_data_behavior.stim2move_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3]);
                ylabel_name='reaction time(s)';
            case 2
                temp_data=raw_data_behavior.stim2lastmove_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3]);
                ylabel_name='reaction time(s)';
            case 3
                temp_data=raw_data_behavior.stim_on2off_times(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3]);
                ylabel_name='reward time(s)';


        end

        for curr_mod=1:2
            mergedVector = vertcat(temp_data{:,curr_mod});
            indexCells = cellfun(@(x, i) repmat(i, size(x)), temp_data(:,curr_mod), ...
                num2cell(1:numel(temp_data(:,curr_mod)))', ...
                'UniformOutput', false);
            temp_idx=vertcat(indexCells{:});
            [~, firstIdx] = unique(temp_idx, 'stable');
            numCells = numel(temp_data(:,curr_mod));

            [unique_vals, ~, groupID] = unique(temp_idx, 'stable');
            mid_indices = splitapply(@(x) x(ceil(numel(x)/2)), (1:numel(temp_idx))', groupID);


            colors=zeros(numCells,3);
            colors(learned_days(:,curr_mod) == 0, :) = repmat([0 0 0], sum(learned_days(:,curr_mod) == 0), 1);
            colors(learned_days(:,curr_mod) == 1, :) = repmat(colors_group, sum(learned_days(:,curr_mod) == 1), 1);


        nexttile
        hold on
        for i = 1:numCells
            idx = (temp_idx == i);
            scatter(find(idx), mergedVector(idx), 10, colors(i,:), 'filled')
        end
        xline(firstIdx-0.5,':k')
        xlim([0 length(mergedVector)])
        ylim([0.05 20])
        ylabel(ylabel_name)
        % xticks(mid_indices)
        % xticklabels(1:length(mid_indices))
        xticks([])
        xlabel('days')
        set(gca, 'YScale', 'log');
        yticks([1e-2 1e-1 1 10])

        drawnow
        end


    end

for curr_mod=1:2
    nexttile
    hold on
    yyaxis left
    set(gca, 'YColor', [0 0 0])
    ylabel('mad')
    temp_data=raw_data_behavior.stim2lastmove_mad(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3]);
    temp_data_null=raw_data_behavior.stim2lastmove_mad_null(ismember(raw_data_behavior.workflow_name,{matches{stage}}),[2,3]);
    plot(1:length(temp_data(:,curr_mod)),temp_data(:,curr_mod),'LineStyle','-','Color',[0 0 0])
    plot(1:length(temp_data(:,curr_mod)),temp_data_null(:,curr_mod),'LineStyle','--','Color',[0 0 0])
    set(gca, 'YScale', 'log');
    ylim([0.01 20])
    yyaxis right
    set(gca, 'YColor', colors_group)
    perform=(temp_data_null(:,curr_mod)-temp_data(:,curr_mod))./(temp_data_null(:,curr_mod)+temp_data(:,curr_mod))
    plot(1:length(perform),perform,'Color',colors_group)
    xlim([1 length(temp_data)])
    ylabel('perform')

    xline(find(learned_days==1,1)-0.5,'LineStyle','--')
end

end





