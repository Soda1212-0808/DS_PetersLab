
%% reaction time , performance, iti move cross modality
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
             % animals = {'HA009','HA010','HA011','HA012'};n1_name='visual position';n2_name='audio volume';

    end

    p_val=cell(length(animals),1);
    reaction_time=cell(length(animals),1);
    reward_time=cell(length(animals),1);
    reaction_time_null=cell(length(animals),1);

    workflow_name=cell(length(animals),1);
    performance=cell(length(animals),1);

    itimove=cell(2,1);
    itimove_all=cell(2,1);


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
        temp_reaction_time_mad(idx_v)= raw_data_behavior.stim2lastmove_mad(idx_v,1);
        temp_reaction_time_mad(idx_a)=raw_data_behavior.stim2lastmove_mad(idx_a,1);
        temp_reaction_time_mad(idx_m,:)= [raw_data_behavior.stim2lastmove_mad(idx_m,2)...
            raw_data_behavior.stim2lastmove_mad(idx_m,3)];

        temp_reaction_time_mad_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad_null(idx_v)= raw_data_behavior.stim2lastmove_mad_null(idx_v,1);
        temp_reaction_time_mad_null(idx_a)=raw_data_behavior.stim2lastmove_mad_null(idx_a,1);
        temp_reaction_time_mad_null(idx_m,:)= [raw_data_behavior.stim2lastmove_mad_null(idx_m,2)...
            raw_data_behavior.stim2lastmove_mad_null(idx_m,3)];

        performance{curr_animal}=(temp_reaction_time_mad_null-temp_reaction_time_mad)./(temp_reaction_time_mad+temp_reaction_time_mad_null);


        reward_time{curr_animal}=cellfun(@mean ,raw_data_behavior.stim_on2off_times,'UniformOutput',true);
        workflow_name{curr_animal}=raw_data_behavior.workflow_name ;
    
     itimove{curr_animal}=cellfun(@(x,y) length(x)/length(y),raw_data_behavior.iti_move,  raw_data_behavior.stim2move_times(:,1),'UniformOutput',true);
        itimove_all{curr_animal}=cellfun(@(x,y) length(x)/length(y),raw_data_behavior.all_iti_move,  raw_data_behavior.stim2move_times(:,1),'UniformOutput',true);

    
    end
    p_all{curr_group}= p_val;
    % task_name=unique(workflow_name{1},'stable');

    max_l1=7

    asso_day_mod1{curr_group}=cellfun(@(p,name) sum(p(strcmp(n1_name,name))>0.05,1)  ,p_val, workflow_name,'UniformOutput',true)
    asso_day_mod2{curr_group}=cellfun(@(p,name) sum(p( strcmp(n2_name,name))>0.05,1)  ,p_val, workflow_name,'UniformOutput',true)

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


    max_l2=7
    rxt_mean_2=cellfun(@(rxt,p,name)  rxt(find( strcmp(n2_name,name)))' ,...
        reaction_time,p_val,workflow_name ,'UniformOutput',false);
    % temp_rxt=cellfun(@(x) x(max(1,end-7):end),rxt_mad_2,'UniformOutput',false);
    temp_rxt2=cellfun(@(x) x(1: min(max_l2,length(x))),rxt_mean_2,'UniformOutput',false);

    % max_l2=max(cellfun(@(x) length(x),rxt_mad_2,'UniformOutput',true));
    rxt_2{curr_group}=cell2mat(cellfun(@(x) [x nan(1,max_l2-length(x))],temp_rxt2,'UniformOutput',false));

    performance_2=cellfun(@(rxt,p,name)  rxt(find( strcmp(n2_name,name) ) )' ,...
        performance,p_val,workflow_name ,'UniformOutput',false);
    % temp_perform=cellfun(@(x) x(max(1,end-7):end),performance_2,'UniformOutput',false);
    temp_perform=cellfun(@(x) x(1: min(max_l2,length(x))),performance_2,'UniformOutput',false);
    perform_2{curr_group}=cell2mat(cellfun(@(x) [x nan(1,max_l2-length(x))],temp_perform,'UniformOutput',false));


    rxt_mean_3 =cellfun(@(rxt,p,name)  {rxt(find( strcmp('mixed VA',name) &p(:,1)<0.01& rxt(:,1)<2 ),1),...
        rxt(find( strcmp('mixed VA',name) &p(:,2)<0.01 & rxt(:,2)<2),2)}  ,...
        reaction_time,p_val,workflow_name ,'UniformOutput',false);


    performance_3 =cellfun(@(rxt,p,name)  {rxt(find( strcmp('mixed VA',name) &p(:,1)<0.01),1),...
        rxt(find( strcmp('mixed VA',name) &p(:,2)<0.01),2)}  ,...
        performance,p_val,workflow_name ,'UniformOutput',false);
    rxt_3{curr_group}=cellfun(@(x)  nanmean(x) , vertcat(rxt_mean_3{:}),'UniformOutput',true);
    perform_3{curr_group}=cellfun(@(x)  nanmean(x) , vertcat(performance_3{:}),'UniformOutput',true);

% iti move

    temp_itimove_mod1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name) ))' ,...
        itimove,workflow_name,p_val,'UniformOutput',false);
    temp_itimove_mod1=cellfun(@(x) x(1: min(max_l1,length(x))),temp_itimove_mod1,'UniformOutput',false);
    itimove_mod1_all{curr_group}=cell2mat(cellfun(@(x) [ nan(1,max_l1-length(x))   x],temp_itimove_mod1,'UniformOutput',false));

    temp_itimove_mod2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name) ))' ,...
        itimove,workflow_name,p_val,'UniformOutput',false);
    temp_itimove_mod2=cellfun(@(x) x(1: min(max_l2,length(x))),temp_itimove_mod2,'UniformOutput',false);
    itimove_mod2_all{curr_group}=cell2mat(cellfun(@(x) [ x  nan(1,max_l2-length(x))],temp_itimove_mod2,'UniformOutput',false));

    n3_name='mixed VA';
    mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),workflow_name ,'UniformOutput',true);
    temp_itimove_mix=cell(length(animals{curr_group}),1);
    temp_itimove_mix(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,1)<0.01,3,"first" )) ,...
        itimove(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);


    temp_itimove_mix(mixed_idx,1)=cellfun(@(x) ...
        [x; nan(3-length(x),1)],temp_itimove_mix(mixed_idx,1),'UniformOutput',false);
    temp_itimove_mix(~mixed_idx) ={nan(3,1)};
    itimove_mix_all{curr_group}=temp_itimove_mix;
    
    
    temp_ddd{1}=cellfun(@(x) [x nan(1,max_l2-length(x))],temp_rxt2,'UniformOutput',false)
    temp_ddd{2}=cellfun(@(x) [x nan(1,max_l2-length(x))],temp_perform,'UniformOutput',false)
    temp_ddd{3}=cellfun(@(x) [ x  nan(1,max_l2-length(x))],temp_itimove_mod2,'UniformOutput',false)


% aligned to learning stages

% performance_align=cell(3,1)
all_dat.reaction_time=reaction_time;
all_dat.performance=performance;
all_dat.itimove=itimove;
names={'reaction_time','performance','itimove'};
for curr_dat=1:3
performance_pre0_temp=cellfun(@(perf,p,name)  perf(find( strcmp(n1_name,name) &p(:,1)>p_thres),1 )  ,...
    all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
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
    all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
performance_post1= cellfun(@(x) ...
    [x ; nan(5-length(x),1)],performance_post1,'UniformOutput',false);

performance_pre2=cell(length(animals),1);
performance_pre2=cellfun(@(perf,p,name)  perf(find( strcmp(n2_name,name) &p(:,1)>p_thres,2,'first'),1 )  ,...
    all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
performance_pre2= cellfun(@(x) ...
    [x ;nan(2-length(x),1)],performance_pre2,'UniformOutput',false);

performance_post2=cell(length(animals),1);
performance_post2=cellfun(@(perf,p,name)  perf(find( strcmp(n2_name,name) &p(:,1)<p_thres,5,'first'),1 )  ,...
    all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
performance_post2= cellfun(@(x) ...
    [x ;nan(5-length(x),1)],performance_post2,'UniformOutput',false);

performance_post3_v=cell(length(animals),1);
performance_post3_v=cellfun(@(perf,p,name)  perf(find( strcmp('mixed VA',name) &p(:,1)<p_thres,3,'first'),1 )  ,...
    all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
performance_post3_v= cellfun(@(x) ...
    [x ;nan(3-length(x),1)],performance_post3_v,'UniformOutput',false);

% performance_post3_a=cell(length(animals),1);
% performance_post3_a=cellfun(@(perf,p,name)  perf(find( strcmp('mixed VA',name) &p(:,1)<p_thres,3,'first'),2 )  ,...
%     all_dat.(names{curr_dat}),p_val,workflow_name ,'UniformOutput',false);
% performance_post3_a= cellfun(@(x) ...
%     [x ;nan(3-length(x),1)],performance_post3_a,'UniformOutput',false);

performance_align{curr_dat}{curr_group}=cellfun(@(a1,a2,a3,a4,a5,a6,a8)  [a1;a2;a3;a4;a5;a6;a8'] ...
    ,performance_pre0,performance_pre1,performance_post1,...
    performance_pre2,performance_post2,performance_post3_v,...
    temp_ddd{curr_dat},'UniformOutput',false);

end


    
end


% save([Path 'summary_data\behavior.mat'],'performance_align','-v7.3')
%
legned_name={'VA';'AV'};

figure('Position', [50 50 200 400]);
t1 = tiledlayout(3,1, 'TileSpacing', 'loose', 'Padding', 'loose');
corlors={[84 130 53]./255,[112  48 160]./255}
barColors = [[   187 205 174]./255;[ 198 172 217]./255]; % 浅蓝、浅红
scatterColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红
nexttile
for curr_group=1:2
hold on
ap.errorfill(1:max_l1, mean(rxt_1{curr_group},1,'omitmissing'),std(rxt_1{curr_group},0,1,'omitmissing')./...
    sqrt(size(rxt_1{curr_group},1)),corlors{curr_group},0.1,0.5)
ap.errorfill(max_l1+1:max_l1+max_l2, mean(rxt_2{curr_group},1,'omitmissing'),std(rxt_2{curr_group},0,1,'omitmissing')./...
    sqrt(size(rxt_2{curr_group},1)),corlors{curr_group},0.1,0.5)
end

xlim([1 max_l1+max_l2+0])
xticks([max_l1/2+0.5 max_l1+max_l2/2+0.5 max_l1+max_l2+1.5  max_l1+max_l2+3.5])
xticklabels({'mod1','mod2','mixed V','mixed A'})
xline(max_l1+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
xline(max_l1+max_l2+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
ylabel('reaction time (s)')
 ylim([-0.05  0.5])
yticks([ 0  0.5])



test_p=cellfun(@(x,y) ds.shuffle_test( nanmean(x(:,6:7),2) ,nanmean(y(:,1:2),2),1,2) ,rxt_2,rxt_2,'UniformOutput',true)
y_base = 0.35;   % 星号基准高度，可以根据数据调节
y_step = 0.05;
offset = 0;  % 用于竖直堆叠
if test_p(1)
    text(7.5, y_base + offset, '*', 'Color',corlors{1}, 'FontSize',14, ...
        'HorizontalAlignment','center');
    offset = offset + y_step;  % 往上移一格
end
if test_p(2)
    text(7.5, y_base + offset, '*', 'Color',corlors{2}, 'FontSize',14, ...
        'HorizontalAlignment','center');
end


set(gca,'Color','none')

nexttile
for curr_group=1:2
    hold on
    ap.errorfill(1:max_l1, mean(perform_1{curr_group},1,'omitmissing'),...
        std(perform_1{curr_group},0,1,'omitmissing')/sqrt(size(perform_1{curr_group},1)),corlors{curr_group},0.1,0.5)
    ap.errorfill(max_l1+1:max_l1+max_l2, mean(perform_2{curr_group},1,'omitmissing'),...
        std(perform_2{curr_group},0,1,'omitmissing')/sqrt(size(perform_2{curr_group},1)),corlors{curr_group},0.1,0.5)
end

% plot(find([p_perform1 p_perform2]),-0.05,'.r');

xline(max_l1+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
xline(max_l1+max_l2+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])

xlim([1 max_l1+max_l2])
xticks([max_l1/2+0.5 max_l1+max_l2/2+0.5 max_l1+max_l2+1.5  max_l1+max_l2+3.5])
xticklabels({'mod1','mod2','mixed V','mixed A'})
ylabel('performance')
% legend({'',legned_name{1},'','','','','',legned_name{2}},'Location','northoutside','Box','off','Orientation','horizontal')
ylim([-0.1 0.8])
yticks([0 0.8])

test_p=cellfun(@(x,y) ds.shuffle_test( nanmean(x(:,5:7),2) ,nanmean(y(:,1:2),2),1,2) ,perform_1,perform_1,'UniformOutput',true)
y_base = 0.5;   % 星号基准高度，可以根据数据调节
y_step = 0.05;
offset = 0;  % 用于竖直堆叠
if test_p(1)
    text(7.5, y_base + offset, '*', 'Color',corlors{1}, 'FontSize',14, ...
        'HorizontalAlignment','center');
    offset = offset + y_step;  % 往上移一格
end
if test_p(2)
    text(7.5, y_base + offset, '*', 'Color',corlors{2}, 'FontSize',14, ...
        'HorizontalAlignment','center');
end


% saveas(gcf,[Path 'figures\summary\figures\behavioral performance' ], 'jpg');
set(gca,'Color','none')





itimove_temp_mix_peak_mean=cellfun(@(x)  nanmean(cellfun(@(a)  nanmean(a) ,x,'UniformOutput',true ) ) ,itimove_mix_all,'UniformOutput',false)
itimove_temp_mix_peak_error=cellfun(@(x)  std(cellfun(@(a)  nanmean(a) ,x,'UniformOutput',true ),'omitmissing')/sqrt(length(x))  ,itimove_mix_all,'UniformOutput',false)
nexttile
for curr_group=1:2

ap.errorfill(1:max_l1,mean(itimove_mod1_all{curr_group},1,'omitmissing'),...
    std(itimove_mod1_all{curr_group},0,1,'omitmissing')/sqrt(size(itimove_mod1_all{curr_group},1)),corlors{curr_group},0.1,0.5)
ap.errorfill(max_l1+1:max_l1+max_l2,mean(itimove_mod2_all{curr_group},1,'omitmissing'),...
    std(itimove_mod2_all{curr_group},0,1,'omitmissing')/sqrt(size(itimove_mod2_all{curr_group},1)),corlors{curr_group},0.1,0.5)

end
xlim([1 max_l1+max_l2])
xticks([max_l1/2+0.5 max_l1+max_l2/2+0.5 max_l1+max_l2+1.5  max_l1+max_l2+3.5])
xticklabels({'mod1','mod2','mixed'})
xline(max_l1+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
xline(max_l1+max_l2+0.5,'LineStyle','--','LineWidth',1,'Color',[0.5 0.5 0.5])
ylim([-0.5 5])
yticks([0 5])
ylabel('relative move')
set(gca,'Color','none')


test_p=cellfun(@(x,y) ds.shuffle_test( nanmean(x(:,6:7),2) ,nanmean(y(:,1:2),2),1,2) ,itimove_mod1_all,itimove_mod2_all,'UniformOutput',true)
y_base = 5;   % 星号基准高度，可以根据数据调节
y_step = 0.5;
offset = 0;  % 用于竖直堆叠
if test_p(1)
    text(7.5, y_base + offset, '*', 'Color',corlors{1}, 'FontSize',14, ...
        'HorizontalAlignment','center');
    offset = offset + y_step;  % 往上移一格
end
if test_p(2)
    text(7.5, y_base + offset, '*', 'Color',corlors{2}, 'FontSize',14, ...
        'HorizontalAlignment','center');
end





figure('Position', [50 50 200 250]);
t1 = tiledlayout(3,1, 'TileSpacing', 'loose', 'Padding', 'loose');
test_p1=cell(3,1)
for curr_dat=1:3
    nexttile
    
    for curr_group=1:2
        temp_mean=nanmean(cat(2,performance_align{curr_dat}{curr_group}{:}),2)
        temp_error=std(cat(3,performance_align{curr_dat}{curr_group}{:}),0,3,'omitmissing')./sqrt(size(performance_align{curr_dat}{curr_group},1))
        hold on
        ap.errorfill(1:8, temp_mean(1:8),temp_error(1:8),corlors{curr_group},0.1,0.5)
        ap.errorfill(9:15, temp_mean(19:25),temp_error(19:25),corlors{curr_group},0.1,0.5)

    end




    xlim([3 14])
    xticks([6 11.5 ])
    xticklabels({'mod1','mod2'})
    xline(8.5,'LineStyle',':','LineWidth',1,'Color',[0.5 0.5 0.5])
    switch curr_dat
        case 1
            ylabel('RT (s)')
            ylim([-0.05  0.5])
            yticks([ 0  0.5])
            y_base = 0.42;   % 星号基准高度，可以根据数据调节
            y_step = 0.02;   % 两个星号之间的竖直间距

        case 2
            ylabel('Perfrom')
            ylim([-0.1 0.8])
            yticks([0 0.8])
            y_base = 0.75;   % 星号基准高度，可以根据数据调节
            y_step = 0.05;   % 两个星号之间的竖直间距

        case 3
            ylim([0 6])
            yticks([0 6.0])
            ylabel('ITI move')
              y_base = 5;   % 星号基准高度，可以根据数据调节
            y_step = 0.05;
    end

    temp_1= cellfun(@(x)   cat(2,x{:}), performance_align{curr_dat},'UniformOutput',false)
     test_p= cellfun(@(x)  ds.shuffle_test (nanmean(x(7:8,:),1),nanmean(x(19:20,:),1),1,2 )>0.95   , temp_1,'UniformOutput',true)
     test_p1{curr_dat}= cellfun(@(x)  1-ds.shuffle_test (nanmean(x(7:8,:),1),nanmean(x(19:20,:),1),1,2 )   , temp_1,'UniformOutput',true)

% 
%     temp{1}= cellfun(@(x)  nanmean(x(4:6,:),1),temp_1,'UniformOutput',false)
%     temp{2}= cellfun(@(x)  nanmean(x(6:8,:),1),temp_1,'UniformOutput',false)
%     temp{3}= cellfun(@(x)  nanmean(x(19:21,:),1),temp_1,'UniformOutput',false)
%      temp{4}= cellfun(@(x)  nanmean(x(22:24,:),1),temp_1,'UniformOutput',false)
% 
%     vals=cellfun(@(x) ds.shuffle_test(x{1},x{2},1,2),temp,'UniformOutput',true)
% 
%     xStart = [4 6 9 12]; xEnd = [6 8 11 14];
% 
% line_thres=[y_base y_base];
% arrayfun(@(a,b) line([a b],line_thres,'Color','k','LineStyle',':') ,xStart(vals>0.95), xEnd(vals>0.95));
% arrayfun(@(i) text(mean([xStart(i) xEnd(i)]), y_base+y_step, '*','Color','r', 'FontSize',12,'HorizontalAlignment','center'), find(vals>0.95));

   
% test_p 是 [val1 val2]
offset = 0;  % 用于竖直堆叠
if test_p(1)
    text(8.5, y_base + offset, '*', 'Color',corlors{1}, 'FontSize',14, ...
        'HorizontalAlignment','center');
    offset = offset + y_step;  % 往上移一格
end
if test_p(2)
    text(8.5, y_base + offset, '*', 'Color',corlors{2}, 'FontSize',14, ...
        'HorizontalAlignment','center');
end


    set(gca,'Color','none')

end


%% mixed task
     figure('Position', [50 50 450 250]);
     t1 = tiledlayout(1,3, 'TileSpacing', 'loose', 'Padding', 'loose');
     nexttile()
     hold on
     for curr_group=1:2
         errorbar([0 2]+curr_group, median(rxt_3{curr_group},1,'omitmissing'), std(rxt_3{curr_group},0,1,'omitmissing')./sqrt(size(rxt_3{curr_group},1)),...
             'o','LineStyle', 'none',...
             'CapSize', 0,...
             'MarkerEdgeColor', scatterColors(curr_group,:), ...
             'MarkerFaceColor', scatterColors(curr_group,:), ...
             'Color', scatterColors(curr_group,:),...
             'LineWidth',1.5,'MarkerSize',4.5)
     end
     xlim([0 5])
     ylabel('reaction time(s)')
     ylim([0 0.5])
     yticks([0 0.5])
     xticks([1.5 3.5])
     xticklabels({'mixed V','mixed A'})
     % set(gca, 'YScale', 'log', 'Color', 'none');
     set(gca, 'Color', 'none');

     nexttile
     hold on
     for curr_group=1:2
         errorbar([0 2]+curr_group, median(perform_3{curr_group},1,'omitmissing'), std(perform_3{curr_group},0,1,'omitmissing')./sqrt(size(rxt_3{curr_group},1)),...
             'o','LineStyle', 'none',...
             'CapSize', 0,...
             'MarkerEdgeColor', scatterColors(curr_group,:), ...
             'MarkerFaceColor', scatterColors(curr_group,:), ...
             'Color', scatterColors(curr_group,:),...
             'LineWidth',1.5,'MarkerSize',4.5)
     end
     ylabel('performance')
     xlim([0 5])
     ylim([0 0.8])
     xticks([1.5 3.5])
     xticklabels({'mixed V','mixed A'})
     yticks([0 0.8])
     set(gca, 'Color', 'none');

     nexttile
     hold on
     for curr_group=1:2
         hold on
         errorbar(curr_group,itimove_temp_mix_peak_mean{curr_group},itimove_temp_mix_peak_error{curr_group},...
             'o','Color',scatterColors(curr_group,:),'LineWidth',1.5,...
             'MarkerFaceColor',scatterColors(curr_group,:),'MarkerSize',4.5,'CapSize',0);
         % scatter(curr_group,itimove_temp_mix_peak_mean{curr_group},'MarkerFaceColor',scatterColors(curr_group,:),'MarkerEdgeColor','none');
     end
     ylabel('iti move')
     xlim([0.5 2.5])
      ylim([0 5])
     xticks([1.5])
     xticklabels({'mixed'})
     set(gca, 'Color', 'none');
 ap.prettyfig
%%
clear all
Path = 'D:\Data process\wf_data\';

asso_day_mod1=cell(2,1);
asso_day_mod2=cell(2,1);
asso_day_mod2_learn=cell(2,1);
reaction_time_mod1=cell(2,1);
viaraility_mod1=cell(2,1);
reaction_time_mod2=cell(2,1);
viaraility_mod2=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016','DS005'};n1_name={'audio volume','audio frequency'};n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
    end

    p_val=cell(length(animals),1);
    reaction_time=cell(length(animals),1);
    viarability=cell(length(animals),1);
    reward_time=cell(length(animals),1);
    reaction_time_null=cell(length(animals),1);

    workflow_name=cell(length(animals),1);
    performance=cell(length(animals),1);
    for curr_animal =1:length(animals)
        animal=animals{curr_animal};
        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        tem_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
        idx_a=ismember(raw_data_behavior.workflow_name,{'audio volume','audio frequency'});
        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

        tem_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
        tem_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
        tem_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,2)...
            raw_data_behavior.rxn_l_mad_p(idx_m,3)];

        p_val{curr_animal}=tem_p;


        temp_reaction_time=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time(idx_v)= raw_data_behavior.stim2lastmove_med(idx_v,1);
        temp_reaction_time(idx_a)=raw_data_behavior.stim2lastmove_med(idx_a,1);
        temp_reaction_time(idx_m,:)= [raw_data_behavior.stim2lastmove_med(idx_m,2)...
            raw_data_behavior.stim2lastmove_med(idx_m,3)];

        temp_reaction_time_null=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_null(idx_v)= raw_data_behavior.stim2lastmove_med_null(idx_v,1);
        temp_reaction_time_null(idx_a)=raw_data_behavior.stim2lastmove_med_null(idx_a,1);
        temp_reaction_time_null(idx_m,:)= [raw_data_behavior.stim2lastmove_med_null(idx_m,2)...
            raw_data_behavior.stim2lastmove_med_null(idx_m,3)];


        reaction_time{curr_animal}=temp_reaction_time;
        reaction_time_null{curr_animal}=temp_reaction_time_null;

        temp_reaction_time_mad=nan(length(raw_data_behavior.workflow_day),2);
        temp_reaction_time_mad(idx_v)= raw_data_behavior.stim2move_mad(idx_v,1);
        temp_reaction_time_mad(idx_a)=raw_data_behavior.stim2lastmove_mad(idx_a,1);
        temp_reaction_time_mad(idx_m,:)= [raw_data_behavior.stim2move_mad(idx_m,2)...
            raw_data_behavior.stim2move_mad(idx_m,3)];

        viarability{curr_animal}=temp_reaction_time_mad

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

    reaction_time_mod1{curr_group}=cellfun(@(rxt,name) rxt(find(ismember(name,n1_name),1,'last'))  ,reaction_time, workflow_name,'UniformOutput',true)
    viaraility_mod1{curr_group}=cellfun(@(rxt,name) rxt(find(ismember(name,n1_name),1,'last'))  ,viarability, workflow_name,'UniformOutput',true)
    asso_day_mod1{curr_group}=cellfun(@(p,name) sum(p(ismember(name,n1_name))>0.01,1) +1 ,p_val, workflow_name,'UniformOutput',true)
   
    asso_day_mod2{curr_group}=cellfun(@(p,name) sum(p( ismember(name,n2_name))>0.01,1)+1  ,p_val, workflow_name,'UniformOutput',true)
    reaction_time_mod2{curr_group}=cellfun(@(rxt,name) rxt(find(ismember(name,n2_name),1,'last'))  ,reaction_time, workflow_name,'UniformOutput',true)
    viaraility_mod2{curr_group}=cellfun(@(rxt,name) rxt(find(ismember(name,n2_name),1,'last'))  ,viarability, workflow_name,'UniformOutput',true)

    % asso_day_mod2_learn{curr_group}=cellfun(@(p,name) sum(p(ismember(name,n1_name))<0.01,1)>3 ,p_val, workflow_name,'UniformOutput',true)


end

%% Bar of first association day in stage1 & 2

% 定义颜色
barColors = [[   187 205 174]./255;[ 198 172 217]./255]; % 浅蓝、浅红
scatterColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红

% barColors = [[0.5 0.5 1];[1 0.5 0.5]]; % 浅蓝、浅红
% scatterColors = [[0 0 1];[1 0 0]]; % 深蓝、深红
yscale={[1 9],[0 0.3 ],[0 0.1]}
% num_stage = {asso_day_mod1,...
%     cellfun(@(x,y) x(y),asso_day_mod2,asso_day_mod2_learn,'UniformOutput',false)};
y_label={'first assocation day','reaction time (s)','variability'}

figure('Position',[50 50 500 200]);

tiledlayout(1,3)
for curr_stage=1:3
    switch  curr_stage
        case 1
            temp_dat=asso_day_mod1;
        case 2
          temp_dat=  reaction_time_mod1;
        case 3
           temp_dat=  viaraility_mod1;
    end


% 计算均值和标准误差
means = cellfun(@mean, temp_dat);
stds = cellfun(@std, temp_dat);
nSamples = cellfun(@length, temp_dat);
sem = stds ./ sqrt(nSamples);  % 计算标准误 SEM
nexttile
% 创建柱状图，并确保 `bar` 只返回一个 `Bar` 对象数组
hold on;
barHandle = bar(1:2, means, 0.5, 'FaceColor', 'flat','EdgeColor','none'); % 'FaceColor' 只能用于单个柱子时指定


for i = 1:2
    barHandle.CData(i,:) = barColors(i,:);

end
% x = barHandle.XData;

% 添加误差条
errorbar(1:2, means, sem, 'k', 'LineStyle', 'none', 'LineWidth', 1.5); % 黑色误差条
jitterRange = 0.3;

for i = 1:2
    yvals = temp_dat{i};
    % 按 Y 值分组，避免相同值重叠
    [uniqueY, ~, idxGroup] = unique(yvals);
    xi = nan(size(yvals));
    for g = 1:numel(uniqueY)
        inds = find(idxGroup == g);
        nG = numel(inds);
        if nG > 1
            % 等间距分布 + 一点随机噪声
            baseJitter = linspace(-jitterRange/2, jitterRange/2, nG);
            noise = (rand(1, nG) - 0.5) * (jitterRange / nG);
            xi(inds) = i + baseJitter + noise;
        else
            xi(inds) = i + (rand - 0.5) * jitterRange;
        end
    end

    scatter(xi, yvals, 30, ...
        'MarkerFaceColor', scatterColors(i, :), ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.7);
end

 ylim(yscale{curr_stage})
 xlim([0 3])
% 美化图像
xticks([1 2]);
xticklabels({'VA', 'AV'});
ylabel(y_label{curr_stage});

yl=ylim
yticks([yl(1) yl(2) ])
y_offset = (yl(2) - yl(1)) * 0.05;  % 横线高度偏移比例
% 横线和星号 y 位置
y_star = max([temp_dat{1}; temp_dat{2}]) + y_offset;
  p=  ranksum(temp_dat{1}, temp_dat{2})
% 判定星号数量
if p < 0.001
    stars = '***';
elseif p < 0.01
    stars = '**';
elseif p < 0.05
    stars = '*';
else
    stars = 'ns';  % 可选
     % stars = num2str(p);  % 可选
end
  % 添加横线和星号
plot([1 2], [y_star y_star], 'k-', 'LineWidth', 1.2);  % 横线
text(1.5, y_star + y_offset * 2, stars, ...
    'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'normal');
grid off;
hold off;
end





% saveas(gcf,[Path 'figures\summary\figures\figure 1 days to learm modality1&2 '  ], 'jpg');

 %%  wheel velocity
 clear all
Path = 'D:\Data process\wf_data\';
barColors = [[84 130 53]./255; [112  48 160 ]./255;[0 1 0]]; % 深蓝、深红

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
vel_mod3_all_v=cell(2,1);

vel_mod3_all_a=cell(2,1);

for curr_group=1:2
    switch curr_group
        case 1
             animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';

            % va_idx=[1 1 1 1 1 1 0 0 0];
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            % va_idx=[0 0 0 1 1 1 1 1];
        case 3
                       animals = {'HA009','HA010','HA011','HA012'};n1_name='visual position';n2_name='audio volume';

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
    temp_vel_mod1=cellfun(@(x) x(max(1,end-max_l1+1):end),temp_vel_mod1,'UniformOutput',false);
    vel_mod1_all{curr_group}=cellfun(@(x) [ nan(max_l1-length(x),1001); cell2mat(x)],temp_vel_mod1,'UniformOutput',false);

    

    temp_vel_mod2=  cellfun(@(x,y,p)  x(find(ismember(y,n2_name) ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_mod2=  cellfun(@(x) cellfun(@(a) nanmean(a,1),x,'UniformOutput',false ) ,...
        temp_vel_mod2,'UniformOutput',false);
    temp_vel_mod2=cellfun(@(x) x(1: min(max_l1,length(x))),temp_vel_mod2,'UniformOutput',false);
    vel_mod2_all{curr_group}=cellfun(@(x) [ cell2mat(x); nan(max_l1-length(x),1001)],temp_vel_mod2,'UniformOutput',false);
    
            n3_name='mixed VA';
    max_l1=6

            mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),workflow_name ,'UniformOutput',true);
            temp_vel_mod3_v=cell(length(animals),1);
            temp_vel_mod3_v(mixed_idx)=  cellfun(@(x,y,p)  x(find(ismember(y,n3_name)&p(:,1)<0.01 ),2) ,...
                velocity(mixed_idx),workflow_name(mixed_idx),p_val(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_v(mixed_idx)=  cellfun(@(x) cellfun(@(a) nanmean(a,1),x,'UniformOutput',false ) ,...
                temp_vel_mod3_v(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_v(mixed_idx)=cellfun(@(x) x(1: min(max_l1,length(x))),temp_vel_mod3_v(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_v(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},max_l1,1),...
                (1:length(find(~mixed_idx)))', 'UniformOutput', false);
            vel_mod3_all_v{curr_group}=cellfun(@(x) [ cell2mat(x); nan(max_l1-length(x),1001)],temp_vel_mod3_v,'UniformOutput',false);

            temp_vel_mod3_a=cell(length(animals),1);
            temp_vel_mod3_a(mixed_idx)=  cellfun(@(x,y,p)  x(find(ismember(y,n3_name)&p(:,1)<0.01 ),3) ,...
                velocity(mixed_idx),workflow_name(mixed_idx),p_val(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_a(mixed_idx)=  cellfun(@(x) cellfun(@(a) nanmean(a,1),x,'UniformOutput',false ) ,...
                temp_vel_mod3_a(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_a(mixed_idx)=cellfun(@(x) x(1: min(max_l1,length(x))),temp_vel_mod3_a(mixed_idx),'UniformOutput',false);
            temp_vel_mod3_a(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},max_l1,1),...
                (1:length(find(~mixed_idx)))', 'UniformOutput', false);

            vel_mod3_all_a{curr_group}=cellfun(@(x) [ cell2mat(x); nan(max_l1-length(x),1001)],temp_vel_mod3_a,'UniformOutput',false);


    temp_vel_pre0=cell(length(animals),1);
    temp_vel_pre0=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)>=0.01 ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_pre0 = cellfun(@(x) x(1:end-2),temp_vel_pre0,'UniformOutput',false);
    temp_vel_pre0 = cellfun(@(x) nanmean(cat(1,x{:}),1),temp_vel_pre0,'UniformOutput',false);
    temp_vel_pre0= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},1-length(x),1)],temp_vel_pre0,'UniformOutput',false);

    temp_vel_pre1=cell(length(animals),1);
    temp_vel_pre1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)>=0.01,2,"last" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_pre1 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_pre1,'UniformOutput',false);
    temp_vel_pre1= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},2-length(x),1)],temp_vel_pre1,'UniformOutput',false);

    temp_vel_post1=cell(length(animals),1);
    temp_vel_post1=  cellfun(@(x,y,p)  x(find(ismember(y,n1_name)&p(:,1)<0.01,5,"first" ),1) ,...
        velocity,workflow_name,p_val,'UniformOutput',false);
    temp_vel_post1 = cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false),temp_vel_post1,'UniformOutput',false);
    temp_vel_post1= cellfun(@(x) ...
        [x; repmat({nan(1,1001)},5-length(x),1)],temp_vel_post1,'UniformOutput',false);

    temp_vel_pre2=cell(length(animals),1);
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

    mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),workflow_name ,'UniformOutput',true);
    temp_vel_mix_v=cell(length(animals),1);
    temp_vel_mix_v(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,1)<0.01,3,"first" ),2) ,...
        velocity(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);
    temp_vel_mix_v(mixed_idx,1) =cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false), temp_vel_mix_v(mixed_idx,1),'UniformOutput',false);

    temp_vel_mix_v(mixed_idx,1)=cellfun(@(x) ...
        [x; repmat({nan(1,1001)},3-length(x),1)],temp_vel_mix_v(mixed_idx,1),'UniformOutput',false);
    temp_vel_mix_v(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},3,1),...
        (1:length(find(~mixed_idx)))', 'UniformOutput', false);

    temp_vel_mix_a=cell(length(animals),1);
    temp_vel_mix_a(mixed_idx,1) = cellfun(@(x,y,z) x(find(ismember(y,n3_name)&z(:,2)<0.01,3,"first" ),3) ,...
        velocity(mixed_idx) ,workflow_name(mixed_idx) ,p_val(mixed_idx) ,'UniformOutput',false);
    temp_vel_mix_a(mixed_idx,1) =cellfun(@(x) cellfun(@(a) nanmean(a,1)  ,x,'UniformOutput',false), temp_vel_mix_a(mixed_idx,1),'UniformOutput',false);
    temp_vel_mix_a(mixed_idx,1)=cellfun(@(x) ...
        [x; repmat({nan(1,1001)},3-length(x),1)],temp_vel_mix_a(mixed_idx,1),'UniformOutput',false);
    temp_vel_mix_a(~mixed_idx) =arrayfun(@(x)  repmat({nan(1,1001)},3,1),...
        (1:length(find(~mixed_idx)))', 'UniformOutput', false);

    vel_all{curr_group}=cellfun(@(a0,a,b,c,d,e,f) cell2mat([a0 ;a; b; c; d; e ;f]),temp_vel_pre0, temp_vel_pre1,temp_vel_post1,temp_vel_pre2,...
        temp_vel_post2,temp_vel_mix_v,temp_vel_mix_a,'UniformOutput',false);


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

figure('Position',[50 50 200 200]);
% t1 = tiledlayout(1,5, 'TileSpacing', 'compact', 'Padding', 'compact');

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
ylabel('velocity')
% title('velocity','FontWeight','normal')
set(gca,'Color','none')


vel_min_mean_1=nanmean(cat(3,vel_mod1_all{curr_group}{:}),3);
vel_min_error_1=std(cat(3,vel_mod1_all{curr_group}{:}),0,3,'omitmissing')./sqrt(size(cat(3,vel_mod1_all{curr_group}{:}),3));
vel_min_mean_2=nanmean(cat(3,vel_mod2_all{curr_group}{:}),3);
vel_min_error_2=std(cat(3,vel_mod2_all{curr_group}{:}),0,3,'omitmissing')./sqrt(size(cat(3,vel_mod2_all{curr_group}{:}),3));

% nexttile(2)
% ap.errorfill(surround_time_points, vel_min_mean_1(8,:), vel_min_error_1(8,:),barColors(curr_group,:),0.1,0.5);
% xlim([-1 2])
% ylim([-3500 100])
% yticks([-3500 0])
% yticklabels({'max','0'})
% xlabel('time (s)')
% title('mod1','FontWeight','normal')
% set(gca,'Color','none')
% 
% nexttile(3)
% ap.errorfill(surround_time_points, vel_min_mean_2(5,:),vel_min_error_2(5,:),barColors(curr_group,:),0.1,0.5);
% xlim([-1 2])
% ylim([-3500 100])
% yticks([-3500 0])
% yticklabels({'max','0'})
% xlabel('time (s)')
% title('mod2','FontWeight','normal')
% set(gca,'Color','none')
% 
% nexttile(4)
% ap.errorfill(surround_time_points, vel_temp_mix_mean{curr_group}{1} ,vel_temp_mix_error{curr_group}{1},barColors(curr_group,:),0.1,0.5);
% xlim([-1 2])
% ylim([-3500 100])
% yticks([-3500 0])
% yticklabels({'max','0'})
% xlabel('time (s)')
% title('mixed V','FontWeight','normal')
% set(gca,'Color','none')
% 
% nexttile(5)
% ap.errorfill(surround_time_points, vel_temp_mix_mean{curr_group}{2} ,vel_temp_mix_error{curr_group}{2},barColors(curr_group,:),0.1,0.5);
% xlim([-1 2])
% ylim([-3500 100])
% yticks([-3500 0])
% yticklabels({'max','0'})
% xlabel('time (s)')
% title('mixed A','FontWeight','normal')
% set(gca,'Color','none')

end


figure('Position',[50 50 200 200]);
for curr_group=1:2
    nexttile(1)
vel_mod1_plot_mean=-nanmean(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),3);
vel_mod1_plot_error=std(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod1_all{curr_group}{:}),[],2),3));

vel_mod2_plot_mean=-nanmean(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),3);
vel_mod2_plot_error=std(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod2_all{curr_group}{:}),[],2),3));

vel_mod3_v_plot_mean=-nanmean(min(cat(3,vel_mod3_all_v{curr_group}{:}),[],2),3);
vel_mod3_v_plot_error=std(min(cat(3,vel_mod3_all_v{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod3_all_v{curr_group}{:}),[],2),3));

vel_mod3_a_plot_mean=-nanmean(min(cat(3,vel_mod3_all_a{curr_group}{:}),[],2),3);
vel_mod3_a_plot_error=std(min(cat(3,vel_mod3_all_a{curr_group}{:}),[],2),0,3,'omitmissing')./sqrt(size(min(cat(3,vel_mod3_all_a{curr_group}{:}),[],2),3));


ap.errorfill(1:8,vel_mod1_plot_mean,vel_mod1_plot_error,barColors(curr_group,:),0.1,0.5)
ap.errorfill(9:13,vel_mod2_plot_mean(1:5),vel_mod2_plot_error(1:5),barColors(curr_group,:),0.1,0.5)

ap.errorfill(14:19,vel_mod3_v_plot_mean,vel_mod3_v_plot_error,barColors(curr_group,:),0.1,0.5)
ap.errorfill(20:25,vel_mod3_a_plot_mean,vel_mod3_a_plot_error,barColors(curr_group,:),0.1,0.5)


end




%% example behavior trace

    animal ='DS019'
    rec_day='2025-01-23'
    rec = plab.find_recordings(animal,rec_day,'*wheel*');
    rec_time = rec.recording{end};
    load_parts = struct;
    load_parts.behavior = true;
    load_parts.widefield = false;
    ap.load_recording;

%
    time_period=[  min(find(timelite.timestamps-(photodiode_on_times(20)-0.2)>0)),...
        min(find(timelite.timestamps-(photodiode_off_times(20)+0.5)>0))];

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
    figure('Position',[50 50 200 150]);
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


    % 
    % figure('Position',[50 50 100 50]);
    % t1 = tiledlayout(4, 1, 'TileSpacing', 'none', 'Padding', 'none');
    % nexttile
    % plot( photodiode_trace(time_period(1)-1000:time_period(2))>3,'LineWidth',line_width,'Color','k')
    %     ylim([0 1.3])
    % 
    % axis off
    % nexttile
    %     plot(wheel_move(time_period(1)-1000:time_period(2)),'LineWidth',line_width,'Color','k')
    %     ylim([0 1.3])
    % 
    % axis off
    % nexttile
    % plot(lick_thresh(time_period(1)-1000:time_period(2)),'LineWidth',line_width,'Color','k')
    % axis off
    % ylim([0 1.3])

   % saveas(gcf,[Path 'figures\summary\figures\figure 1 example behavioral trace' ], 'jpg');
%% single mice behavior
clear all
Path = 'D:\Data process\wf_data\';
colors_group=[0 0 1];

% animals = {'DS000','DS004','DS014','DS015','DS016'};
% animals = {  'DS007','DS010','AP019','AP021','DS011','AP022'}
animals={'DS015'}

% animals={'HA000','HA001','HA002','HA003','HA004','DS019','DS020','DS021','AP027','AP028','AP029'}
 % animals={'HA003','HA004','DS019','DS020'}
 % animals={'AP027','AP028','AP029','DS019','DS020','DS021'}
% animals = {  'HA011','HA012','HA009','HA010'}

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


%% test



task_type=[trial_events.values.TaskType]

pairs={[0 0 0 1],[1],[0],[0 1]}
vel_all=cell(length(pairs),1)
for curr_pair_idx=1:length(pairs)
    curr_pair=pairs{curr_pair_idx};
    v=cell(length(curr_pair),1)
    for curr_i=1:length(curr_pair)
    v{curr_i} = task_type(curr_i:end-length(curr_pair)+curr_i);
    end
    % idx = find(v1==curr_pair(1) & v2==curr_pair(2)&v3==curr_pair(3) & v4==curr_pair(4)) + 1;

 temp=  cell2mat( cellfun(@(x,y)  x==y   ,  v, num2cell(curr_pair)','UniformOutput',false ));
    idx = find(all(temp == 1, 1));  % 找每列是否全为0

    idx_last = idx + length(curr_pair) - 1;

curr_time=stim_move_time(idx_last);


    pull_times = curr_time + surround_time_points;
    event_aligned_wheel_vel = interp1(timelite.timestamps, ...
        wheel_velocity,pull_times);
    vel_all{curr_pair_idx}=event_aligned_wheel_vel;
end

C_str = cellfun(@(x) sprintf('%d', x), pairs, 'UniformOutput', false);




figure;
hold on
cellfun(@(x) plot(nanmean(x,1)) , vel_all,'UniformOutput',false)
legend(C_str)


