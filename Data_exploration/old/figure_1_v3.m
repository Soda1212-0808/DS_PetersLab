

%%

clear all
clc

Path = 'D:\Data process\wf_data\';
labels = {'fast','slow','non'}; % 分类标签

VA_immediated=4;
VA_slow_learner=2;
VA_non_learner=2;
data_VA = [VA_immediated, VA_slow_learner, VA_non_learner];
labels_num_VA = compose("%d", data_VA); % 生成数值标签
AV_immediated=0;
AV_slow_learner=5;
AV_non_learner=2;
data_AV = [AV_immediated, AV_slow_learner, AV_non_learner];
% labels_num_AV = compose("%d", data_AV); % 生成数值标签
labels_num_AV = string(arrayfun(@(x) ifelse(x == 0, ' ', sprintf('%d', x)), data_AV, 'UniformOutput', false));

figure('Position',[50 50 400 300])
tiledlayout(1, 2); % 创建一个1行2列的布局

a1=nexttile
explode=[0 0 1];    
h1=pie(data_VA,explode, labels_num_VA);
for k = 1:length(h1)
    h1(k).EdgeColor = 'none';
end
cmap = [ ...
    84 130 53  % #548235
    187 205 174 % #BBCDAE
    192 192 192 % #C0C0C0
] / 255;
colormap(a1,cmap); % 红、绿、蓝

title('VA')
 legend(labels, 'Location', 'northoutside', 'Orientation', 'vertical','Box','off');
a2=nexttile
h2=pie(data_AV, explode,labels_num_AV);
for k = 1:length(h2)
    h2(k).EdgeColor = 'none';
end
title('AV')
cmap = [ ...
    112  48 160  % #7030A0
    198 172 217  % #C6ACD9
    192 192 192  % #C0C0C0
] / 255;
 colormap(a2,cmap); % 红、绿、蓝

legend( labels, 'Location', 'northoutside', 'Orientation', 'vertical', 'Box', 'off');


 % saveas(gcf,[Path 'figures\summary\figures\figure 1 behavior proportion'], 'jpg');
%% stim2move stage1 and stage2

clear all
Path = 'D:\Data process\wf_data\';
num_stage1=cell(2,1);

output_data=struct;
stim2move_med_stage0_1=cell(2,1);
stim2move_med_stage0=cell(2,1);
stim2move_med_stage1=cell(2,1);
stim2move_med_stage2=cell(2,1);
stim2move_med_null_stage0_1=cell(2,1);
stim2move_med_null_stage0=cell(2,1);
stim2move_med_null_stage1=cell(2,1);
stim2move_med_null_stage2=cell(2,1);
stim2move_med_mod1=cell(2,1);
stim2move_med_mod2=cell(2,1);
stim2move_med_null_mod1=cell(2,1);
stim2move_med_null_mod2=cell(2,1);
iti_move2all_trial_stage0=cell(2,1);
iti_move2all_trial_stage1=cell(2,1);
iti_move2all_trial_stage2=cell(2,1);
iti_move2all_trial_mod1=cell(2,1);
iti_move2all_trial_mod2=cell(2,1);
stim2move_time_stage2=cell(2,1);
stim2move_time_stage2_post=cell(2,1);
stim2move_time_stage1_post=cell(2,1);
stim2move_time_stage0=cell(2,1);

stim_on2off_time_stage2=cell(2,1);
stim_on2off_time_stage2_post=cell(2,1);
stim_on2off_time_stage1_post=cell(2,1);
stim_on2off_time_stage0=cell(2,1);

used_animals=cell(2,1);
for curr_group=1:2
    if curr_group==1

        animals{curr_group} = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
        index_group1=[1 1 1 1 1 1 0 1 1 ]';
        index_group2=[1 1 1 1 1 1 0 0 0 ]';
    else
        animals{curr_group} = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
        index_group1=[0 1 1 1 1 1 1 1 ];
        index_group2=[0 0 0 1 1 1 1 1 ];

    end
        %  animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';index_group=[1 1 1 ];
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';index_group=[1 1 0 1 1 1 ];
% animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';index_group=[1 1 1 1 1 ];
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';index_group=[ 1 1 1  ];

data1=load([Path 'summary_data\behavior in ' n1_name '_to_' n2_name '.mat' ]);

num_stage1{curr_group}=cellfun(@(x)  find(x==1,1,'first'),  data1.all_animal_learned_day(find(index_group1==1))  ,'UniformOutput',true);
num_stage2{curr_group}=cellfun(@(x,y)  find((x==1&strcmp(n2_name,y)),1,'first')- find(strcmp(n2_name,y),1,'first')+1,  data1.all_animal_learned_day(find(index_group2==1)), data1.all_animal_workflow_name(find(index_group2==1))  ,'UniformOutput',true);
used_animals{curr_group}=animals{curr_group}(find(index_group2));


    
   

stim2move_med_stage0{curr_group} =cellfun(@(x,y,l)  x(find(y==0& strcmp(n1_name,l),1,"first"): find(y==1& strcmp(n1_name,l) ,1,"first")-1 )  ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);


stim2move_med_stage1{curr_group} =cellfun(@(x,y,l)   x( find(y==1& strcmp(n1_name,l)))  ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_stage2{curr_group} =cellfun(@(x,y,l)   x( find( strcmp(n2_name,l)))        ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_stage0_1{curr_group} =cellfun(@(x,y,z,l)  x(find( strcmp(n1_name,l) &z>0,1,"first"): find( strcmp(n1_name,l) &z>0,1,"last") )  ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_stage0_1{curr_group} =cellfun(@(x,y,z,l)  x(find( strcmp(n1_name,l) &z>0,1,"first"): find( strcmp(n1_name,l) &z>0,1,"last") )  ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_stage0{curr_group} =cellfun(@(x,y,z,l)  x(find(y==0& strcmp(n1_name,l) ): find(y==1& strcmp(n1_name,l) &z>0,1,"first")-1 )  ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_stage1{curr_group} =cellfun(@(x,y,l)   x( find(y==1& strcmp(n1_name,l)))   ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_stage2{curr_group} =cellfun(@(x,y,l)   x( find( strcmp(n2_name,l)))        ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);



iti_move2all_trial_stage0{curr_group} =cellfun(@(x,y,z,l)  x(find(y==0& strcmp(n1_name,l),1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"first")-1 )  ,...
    data1.all_animal_trials_iti_move2all_trials(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

iti_move2all_trial_stage1{curr_group} =cellfun(@(x,y,z,l)   x( find(y==1& strcmp(n1_name,l) &z>0,1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"last"))        ,...
    data1.all_animal_trials_iti_move2all_trials(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

iti_move2all_trial_stage2{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0,1,"first"): find( strcmp(n2_name,l) &z>0,1,"last"))        ,...
    data1.all_animal_trials_iti_move2all_trials(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);


stim2move_med_mod1{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n1_name,l) ,7,"first") )  ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_mod2{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n2_name,l),7,"first") )  ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_mod1{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n1_name,l) ,7,"first") )  ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_med_null_mod2{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n2_name,l),7,"first") )  ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);



iti_move2all_trial_mod1{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n1_name,l) ,7,"first") )  ,...
    data1.all_animal_trials_iti_move2all_trials(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

iti_move2all_trial_mod2{curr_group} =cellfun(@(x,y,z,l)  x( find( strcmp(n2_name,l),7,"first") )  ,...
    data1.all_animal_trials_iti_move2all_trials(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);


stim2move_time_stage2{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0&y==0)),...
    data1.all_animal_stim2move_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_time_stage2_post{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0&y==1)),...
    data1.all_animal_stim2move_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_time_stage1_post{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n1_name,l) &z>0&y==1)),...
    data1.all_animal_stim2move_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_time_stage0{curr_group} =cellfun(@(x,y,z,l)  x(find(y==0& strcmp(n1_name,l),1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"first")-1 )  ,...
    data1.all_animal_stim2move_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim2move_time_stage2{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0&y==0)),...
    data1.all_animal_stim2move_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);



stim_on2off_time_stage2_post{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0&y==1)),...
    data1.all_animal_stim_on2off_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim_on2off_time_stage1_post{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n1_name,l) &z>0&y==1)),...
    data1.all_animal_stim_on2off_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim_on2off_time_stage0{curr_group} =cellfun(@(x,y,z,l)  x(find(y==0& strcmp(n1_name,l),1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"first")-1 )  ,...
    data1.all_animal_stim_on2off_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

stim_on2off_time_stage2{curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0&y==0)),...
    data1.all_animal_stim_on2off_time(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);


% num{curr_group}=cellfun(@(x)  find(x==1,1,'first')-1,  data1.all_animal_learned_day  ,'UniformOutput',true);
end


performance_stage_0=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), stim2move_med_stage0,stim2move_med_null_stage0 ,'UniformOutput',false);
performance_stage_0_1=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), stim2move_med_stage0_1,stim2move_med_null_stage0_1 ,'UniformOutput',false);


pad_and_stack = @(x) cell2mat(cellfun(@(v) ...
    [v; nan(max(cellfun(@length,x)) - length(v), 1)], ...
    x, 'UniformOutput', false)');

get_median_sem = @(x) deal( ...
    median(pad_and_stack(x), 2, 'omitnan'), ...
    std(pad_and_stack(x), 0, 2, 'omitnan') ./ sqrt(length(x)) );

get_performance_sem = @(x, y) deal( ...
    median(pad_and_stack(cellfun(@(v, w) (w-v)./(w+v), x, y, 'UniformOutput', false)), 2, 'omitnan'), ...
    std(pad_and_stack(cellfun(@(v, w) (w-v)./(w+v), x, y, 'UniformOutput', false)), 0, 2, 'omitnan') ./ sqrt(length(x)) );
[aligned_stage0_mean, aligned_stage0_error] = cellfun(get_median_sem, stim2move_med_stage0, 'UniformOutput', false);
[aligned_stage1_mean, aligned_stage1_error] = cellfun(get_median_sem, stim2move_med_stage1, 'UniformOutput', false);
[aligned_stage2_mean, aligned_stage2_error] = cellfun(get_median_sem, stim2move_med_stage2, 'UniformOutput', false);
[aligned_stage0_1_mean, aligned_stage0_1_error] = cellfun(get_median_sem, stim2move_med_stage0_1, 'UniformOutput', false);

[aligned_stage0_perform, aligned_stage0_perform_error] = cellfun(get_performance_sem, stim2move_med_stage0, stim2move_med_null_stage0, 'UniformOutput', false);
[aligned_stage1_perform, aligned_stage1_perform_error] = cellfun(get_performance_sem, stim2move_med_stage1, stim2move_med_null_stage1, 'UniformOutput', false);
[aligned_stage2_perform, aligned_stage2_perform_error] = cellfun(get_performance_sem, stim2move_med_stage2, stim2move_med_null_stage2, 'UniformOutput', false);
[aligned_stage0_1_perform, aligned_stage0_1_perform_error] = cellfun(get_performance_sem, stim2move_med_stage0_1, stim2move_med_null_stage0_1, 'UniformOutput', false);

[aligned_iti_move_stage0_mean, aligned_iti_move_stage0_error] = cellfun(get_median_sem, iti_move2all_trial_stage0, 'UniformOutput', false);
[aligned_iti_move_stage1_mean, aligned_iti_move_stage1_error] = cellfun(get_median_sem, iti_move2all_trial_stage1, 'UniformOutput', false);
[aligned_iti_move_stage2_mean, aligned_iti_move_stage2_error] = cellfun(get_median_sem, iti_move2all_trial_stage2, 'UniformOutput', false);



%% stim2move in mixed task


num_stage1=cell(2,1);
stim2move_med_mix_v=cell(2,1)
stim2move_med_mix_a=cell(2,1)
stim2move_med_mix_v_null=cell(2,1)
stim2move_med_mix_a_null=cell(2,1)
for curr_group=1:2
    if curr_group==1

        animals = {'DS007','DS010','AP021','DS011','DS001','AP018','AP022'};n1_name='visual position';n2_name='audio volume'; index_group=[1  1 1 1 0 0 0  ]';
        index_group2=[1 0 1 1 1 1 0 0  ];
    else
        animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';index_group=[0 0 0 1 1 1 1 1 ];
        index_group2=[1 0 1 1 1 1 1 1 ];

    end
        %  animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';index_group=[1 1 1 ];
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';index_group=[1 1 0 1 1 1 ];
% animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';index_group=[1 1 1 1 1 ];
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';index_group=[ 1 1 1  ];

data1=load([Path 'summary_data\behavior in mixed task in ' n1_name '_to_' n2_name '.mat' ]);




stim2move_med_mix_v{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),1)==1),2) ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_a{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),2)==1),3)     ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_v_null{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),1)==1),2) ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_a_null{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),2)==1),3)     ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

end


aligned_mix_v_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_v,'UniformOutput',false);
aligned_mix_v_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mix_v,'UniformOutput',false);

aligned_mix_a_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_a,'UniformOutput',false);
aligned_mix_a_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mix_a,'UniformOutput',false);
performance_mixed_v=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), ...
    stim2move_med_mix_v,stim2move_med_mix_v_null ,'UniformOutput',false);
performance_mixed_a=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), ...
    stim2move_med_mix_a,stim2move_med_mix_a_null ,'UniformOutput',false);
performance_mix_v_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),performance_mixed_v,'UniformOutput',false);
performance_mix_v_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),performance_mixed_v,'UniformOutput',false);

performance_mix_a_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),performance_mixed_a,'UniformOutput',false);
performance_mix_a_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),performance_mixed_a,'UniformOutput',false);

%% example mouse

figure('Position', [50 50 550 350]);
t1 = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
% figure;
% t = tiledlayout(3,3);  % 两行一列
ccolors={'b','r'}
for curr_i=1:2
    if curr_i==1
% animal=animals{1}{1};
animal='Visual';

naive=stim2move_time_stage0{1}{2}{1};
well_trained=stim2move_time_stage1_post{1}{2}{end};
    else
        % animal=animals{2}{2};
        animal='Auditory';

naive=stim2move_time_stage0{2}{4}{1};
well_trained=stim2move_time_stage1_post{2}{4}{end};
    end
% 
% naive=stim2move_time_stage0{1}{1}{1};
% well_trained=stim2move_time_stage1_post{1}{1}{end};

nexttile(curr_i*3-2)
scatter(1:length(naive),naive,5,'filled','MarkerFaceColor','k')
hold on
scatter(length(naive)+10:length(well_trained)+length(naive)+9,well_trained,5,'filled','MarkerFaceColor',ccolors{curr_i})
xline(length(naive)+5,'LineStyle',':','LineWidth',2)
xticks([length(naive)/2 length(naive)+10+length(well_trained)/2])
xticklabels({'naive','well trained'})
ylim([-0.3 2])
xlim([0 length(well_trained)+length(naive)+9])
title(animal)
ylabel('reaction time (s)')
xlabel('trials')

nexttile(curr_i*3-1)
histogram(naive,-0.3:0.01:0.4 ,"LineStyle","none" ,'FaceColor','k')
box off
hold on
histogram(well_trained,-0.2:0.01:0.4,"LineStyle","none",'FaceColor',ccolors{curr_i})
% legend('Location','northoutside','Box','off')
ylabel('distribution')
xlabel('reaction time (s)')
end
well_trained_v_all= cellfun(@(x) cat(1,x{end})  , stim2move_time_stage1_post{1},'UniformOutput',false);
visual=cat(1,well_trained_v_all{:});
well_trained_a_all= cellfun(@(x) cat(1,x{end})  , stim2move_time_stage1_post{2},'UniformOutput',false);
auditory=cat(1,well_trained_a_all{:});

nexttile(3)
histogram(visual,-0.2:0.01:0.4 ,"LineStyle","none" ,'FaceColor','b')
hold on
histogram(auditory,-0.2:0.01:0.4,"LineStyle","none",'FaceColor','r')
box off

% legend('Location','eastoutside','Box','off')
ylabel('distribution')
xlabel('reaction time (s)')
title ('visual vs auditory')
  saveas(gcf,[Path 'figures\summary\figures\figure 1 reacton distribution'  ], 'jpg');
%% single mice distribution stim2move
for curr_para=1:2
    para={'reaction time','reward time'};
use_scale1={[-0.3 2], [0 3]};

use_scale2={[-0.3:0.02: 1], [0 :0.02:2]};

figure('Position', [50 50 550 850]);

mainLayout = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact'); % 两大列
sgtitle(para{curr_para})

for curr_type=1:2

     subLayout = tiledlayout(mainLayout, 6, 2, ...
        'TileSpacing', 'compact', 'Padding', 'compact');
     subLayout.Layout.Tile = curr_type;
for curr_mice=1:length(stim2move_time_stage0{curr_type})
    if curr_para==1
naive=stim2move_time_stage0{curr_type}{curr_mice}{1};
well_trained=stim2move_time_stage1_post{curr_type}{curr_mice}{end};
    else
naive=stim_on2off_time_stage0{curr_type}{curr_mice}{1};
well_trained=stim_on2off_time_stage1_post{curr_type}{curr_mice}{end};
    end

ax = nexttile(subLayout, (curr_mice-1)*2 + 1);

scatter(1:length(naive),naive,5,'filled','MarkerFaceColor','k')
hold on
scatter(length(naive)+10:length(well_trained)+length(naive)+9,well_trained,5,'filled','MarkerFaceColor',ccolors{curr_type})
xline(length(naive)+5,'LineStyle',':','LineWidth',2)
xticks([length(naive)/2 length(naive)+10+length(well_trained)/2])
xticklabels({'naive','well trained'})
ylim(use_scale1{curr_para})
xlim([0 length(well_trained)+length(naive)+9])
title(used_animals{curr_type}{curr_mice})
ylabel('reaction time (s)')
% xlabel('trials')

ax = nexttile(subLayout, (curr_mice-1)*2 + 2);
histogram(naive,use_scale2{curr_para} ,"LineStyle","none" ,'FaceColor','k')
box off
hold on
histogram(well_trained,use_scale2{curr_para},"LineStyle","none",'FaceColor',ccolors{curr_type})
% legend('Location','northoutside','Box','off')
ylabel('distribution')
xlabel('reaction time (s)')

end
end

  saveas(gcf,[Path 'figures\summary\figures\figure 1 distribution each mouse of ' para{curr_para}  ], 'jpg');
end
%%
line_color={[84 130 53]./255,[ 112  48 160]./255};
group_name={'V-A','A-V'};
legned_name={'VA';'AV'};

figure('Position',[50 50 500 250]);
t1 = tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'loose');

nexttile
 for curr_fig=1:2
ap.errorfill(1:5,aligned_stage0_mean{curr_fig}(1:5), aligned_stage0_error{curr_fig}(1:5),line_color{curr_fig},0.1,0.5);
% ap.errorfill(6:5+length(aligned_stage1_mean{curr_fig}),...
%     aligned_stage1_mean{curr_fig}, aligned_stage1_error{curr_fig},line_color{curr_fig},0.1,0.5);
% ap.errorfill(6+length(aligned_stage1_mean{curr_fig}):...
%     5+length(aligned_stage1_mean{curr_fig})+length(aligned_stage2_mean{curr_fig}),...
%     aligned_stage2_mean{curr_fig}, aligned_stage2_error{curr_fig},line_color{curr_fig},0.1,0.5);

ap.errorfill(6:10,...
    aligned_stage1_mean{curr_fig}, aligned_stage1_error{curr_fig},line_color{curr_fig},0.1,0.5);
ap.errorfill(11:19,...
    aligned_stage2_mean{curr_fig}(1:9), aligned_stage2_error{curr_fig}(1:9),line_color{curr_fig},0.1,0.5);

scatter(20,mean(aligned_mix_v_mean{curr_fig}))
% ap.errorfill(19.5:20.5,...
%     [mean(aligned_mix_v_mean{curr_fig}) mean(aligned_mix_v_mean{curr_fig})],...
%     [mean(aligned_mix_v_error{curr_fig}) mean(aligned_mix_v_error{curr_fig})],line_color{curr_fig},0.1,0.5);


ap.errorfill(20.7:21.3,mean(aligned_mix_a_mean{curr_fig}), mean(aligned_mix_a_error{curr_fig}),...
    line_color{curr_fig},0.1,0.5);



xticks([3,  8 ,15 ,20 21  ] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'pre','Mod 1','Mod 2','mixed V','mixed A'}); % 设置对应的标签
hold on
yline(0.1)
xline(5.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])
xline(10.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])
xline(19.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])
xline(22.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])

 set(gca, 'YScale', 'log');

ylabel('stim to move (s)')
ylim([0.05 5])
xlim([1 23])


 end
 % legend({'',legned_name{1},'','','','','','','','',legned_name{2}},'Location','northoutside','Box','off', 'Orientation', 'horizontal')

nexttile
 for curr_fig=1:2
ap.errorfill(1:5,aligned_stage0_perform{curr_fig}(1:5), aligned_stage0_perform_error{curr_fig}(1:5),line_color{curr_fig},0.1,0.5);
ap.errorfill(6:10,...
    aligned_stage1_perform{curr_fig}, aligned_stage1_perform_error{curr_fig},line_color{curr_fig},0.1,0.5);
ap.errorfill(11:19,...
    aligned_stage2_perform{curr_fig}(1:9), aligned_stage2_perform_error{curr_fig}(1:9),line_color{curr_fig},0.1,0.5);

ap.errorfill(20:22,...
    performance_mix_v_mean{curr_fig}, performance_mix_v_error{curr_fig},line_color{curr_fig},0.1,0.5);


ap.errorfill(23:25,performance_mix_a_mean{curr_fig}, performance_mix_a_error{curr_fig},line_color{curr_fig},0.1,0.5);



xticks([3,  8 ,15 ,21 24  ] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'pre','Mod 1','Mod 2','mixed V','mixed A'}); % 设置对应的标签

yline(0)
xline(5.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])
xline(10.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])


ylabel('performace')
ylim([-0.1 0.5])
xlim([1 25.5])


 end
   saveas(gcf,[Path 'figures\summary\figures\figure 1 performance'  ], 'jpg');



   
figure
for curr_fig=1:2
ap.errorfill(1:5,aligned_iti_move_stage0_mean{curr_fig}(1:5), aligned_iti_move_stage0_error{curr_fig}(1:5),line_color{curr_fig},0.1,0.5);
ap.errorfill(6:5+length(aligned_iti_move_stage1_mean{curr_fig}),...
    aligned_iti_move_stage1_mean{curr_fig}, aligned_iti_move_stage1_error{curr_fig},line_color{curr_fig},0.1,0.5);
ap.errorfill(6+length(aligned_iti_move_stage1_mean{curr_fig}):...
   5+length(aligned_iti_move_stage1_mean{curr_fig})+length(aligned_iti_move_stage2_mean{curr_fig}),...
    aligned_iti_move_stage2_mean{curr_fig}, aligned_iti_move_stage2_error{curr_fig},line_color{curr_fig},0.1,0.5);


xticks([3,  5+0.5*length(aligned_stage1_perform{curr_fig}) ,...
  length(aligned_stage0_perform{curr_fig})+length(aligned_stage1_perform{curr_fig})+0.5*length(aligned_stage2_perform{curr_fig})  ] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'pre','Mod 1','Mod 2'}); % 设置对应的标签

yline(0)
xline(5.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])
xline(10.5,'LineWidth',1.5,'LineStyle','--','Color',[0.5 0.5 0.5])


ylabel('relative iti move')
ylim([0 5])
xlim([1 length(aligned_stage0_mean{curr_fig})+length(aligned_stage1_mean{curr_fig})+length(aligned_stage2_mean{curr_fig})])


 end
 legend({'',legned_name{1},'','','','','','','','',legned_name{2}},'Location','northoutside','Box','off', 'Orientation', 'horizontal')

 



  

%%
performance_mod1=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), stim2move_med_mod1,stim2move_med_null_mod1 ,'UniformOutput',false)
performance_mod2=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), stim2move_med_mod2,stim2move_med_null_mod2 ,'UniformOutput',false)

stim2move_med_mod1_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),stim2move_med_mod1,'UniformOutput',false);
stim2move_med_mod1_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mod1,'UniformOutput',false);

stim2move_med_mod2_1=cellfun(@(x) cellfun(@(a)  [a; nan(7-length(a),1)] ,x,'UniformOutput',false ),stim2move_med_mod2,'UniformOutput',false );
stim2move_med_mod2_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),stim2move_med_mod2_1,'UniformOutput',false);
stim2move_med_mod2_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mod2_1,'UniformOutput',false);

perfromance_med_mod1_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),performance_mod1,'UniformOutput',false);
perfromance_med_mod1_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),performance_mod1,'UniformOutput',false);

performance_mod2_1=cellfun(@(x) cellfun(@(a)  [a; nan(7-length(a),1)] ,x,'UniformOutput',false ),performance_mod2,'UniformOutput',false );
perfromance_med_mod2_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),performance_mod2_1,'UniformOutput',false);
perfromance_med_mod2_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),performance_mod2_1,'UniformOutput',false);


iti_move_med_mod1_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),iti_move2all_trial_mod1,'UniformOutput',false);
iti_move_med_mod1_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),iti_move2all_trial_mod1,'UniformOutput',false);

iti_move_med_mod2_1=cellfun(@(x) cellfun(@(a)  [a; nan(7-length(a),1)] ,x,'UniformOutput',false ),iti_move2all_trial_mod2,'UniformOutput',false );
iti_move_med_mod2_mean=cellfun(@(x) median(cat(2,x{:}),2,'omitmissing'),iti_move_med_mod2_1,'UniformOutput',false);
iti_move_med_mod2_error=cellfun(@(x) std(cat(2,x{:}),0,2,'omitmissing')/sqrt(length(x)),iti_move_med_mod2_1,'UniformOutput',false);


figure('Position', [50 50 600 200]);
t1 = tiledlayout(1,3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile
ap.errorfill( 1:7,stim2move_med_mod1_mean{1}, stim2move_med_mod1_error{1},[84 130 53 ]./255,0.2,0.5);
ap.errorfill( 1:7,stim2move_med_mod1_mean{2}, stim2move_med_mod1_error{2},[112 48 160]./255,0.2,0.5);
ap.errorfill(8:14,stim2move_med_mod2_mean{1}, stim2move_med_mod2_error{1},[84 130 53 ]./255,0.2,0.5);
ap.errorfill(8:14,stim2move_med_mod2_mean{2}, stim2move_med_mod2_error{2},[112 48 160]./255,0.2,0.5);

xlim([1 14])
ylim([0 3])
set(gca, 'YScale', 'log');

ylabel('reaction time (s)')
xticks([4 7.5 10] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'Mod 1','','Mod 2'}); % 设置对应的标签
xline(7.5,'LineWidth',2,'LineStyle','--','Color',[0.5 0.5 0.5])
% legend({'','V-A','','A-V'},"Box","off",'Location','northoutside','Orientation','horizontal')

nexttile
ap.errorfill(1:7,perfromance_med_mod1_mean{1}, perfromance_med_mod1_error{1},[84 130 53]./255 ,0.2,0.5);
ap.errorfill(1:7,perfromance_med_mod1_mean{2}, perfromance_med_mod1_error{2},[112  48 160]./255,0.2,0.5);
ap.errorfill(8:14,perfromance_med_mod2_mean{1}, perfromance_med_mod2_error{1},[84 130 53]./255,0.2,0.5);
ap.errorfill(8:14,perfromance_med_mod2_mean{2}, perfromance_med_mod2_error{2},[112 48 160]./255,0.2,0.5);
xlim([1 14])
ylim([-0.1 0.4])
ylabel('performance')
xticks([4 7.5 11] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'Mod 1','','Mod 2'}); % 设置对应的标签
xline(7.5,'LineWidth',2,'LineStyle','--','Color',[0.5 0.5 0.5])


nexttile
ap.errorfill( 1:7,iti_move_med_mod1_mean{1}, iti_move_med_mod1_error{1},[84 130 53 ]./255,0.2,0.5);
ap.errorfill( 1:7,iti_move_med_mod1_mean{2}, iti_move_med_mod1_error{2},[112 48 160]./255,0.2,0.5);
ap.errorfill(8:14,iti_move_med_mod2_mean{1}, iti_move_med_mod2_error{1},[84 130 53 ]./255,0.2,0.5);
ap.errorfill(8:14,iti_move_med_mod2_mean{2}, iti_move_med_mod2_error{2},[112 48 160]./255,0.2,0.5);

xlim([1 14])
ylim([0 5])
ylabel('relative iti move')
xticks([4 7.5 10] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'Mod 1','','Mod 2'}); % 设置对应的标签
xline(7.5,'LineWidth',2,'LineStyle','--','Color',[0.5 0.5 0.5])

lgd=legend({'','V-A','','A-V'},"Box","off",'Location','northoutside','Orientation','horizontal')
% legendPos = lgd.Position;
% 
% % 检查是否与数据线重叠，如果重叠，则调整位置
% if legendPos(1) > 0.7  % 如果 legend 的 x 位置靠近图形边缘
%     lgd.Position = [legendPos(1) , legendPos(2), legendPos(3), legendPos(4)]; % 向右移动 legend
% end

saveas(gcf,[Path 'figures\summary\figures\figure 1 reaction time & performance & relative iti move' ], 'jpg');






% legend({'','V-A','','A-V'},"Box","off",'Location','northoutside','Orientation','horizontal')

%% bar First association day in stage1 % 2


% 定义颜色
barColors = [[   187 205 174]./255;[ 198 172 217]./255]; % 浅蓝、浅红
scatterColors = [[84 130 53]./255; [112  48 160 ]./255]; % 深蓝、深红
num_stage = {num_stage1, num_stage2};
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
saveas(gcf,[Path 'figures\summary\figures\figure 1 days to learm modality1&2 '  ], 'jpg');

 %% stim2move in mixed task


num_stage1=cell(2,1);
stim2move_med_mix_v=cell(2,1)
stim2move_med_mix_a=cell(2,1)
stim2move_med_mix_v_null=cell(2,1)
stim2move_med_mix_a_null=cell(2,1)
for curr_group=1:2
    if curr_group==1

        animals = {'DS007','DS010','AP021','DS011','DS001','AP018','AP022'};n1_name='visual position';n2_name='audio volume'; index_group=[1  1 1 1 0 0 0  ]';
        index_group2=[1 1 1 1 1 1 1 0  ];
    else
        animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';index_group=[0 0 0 1 1 1 1 1 ];
        index_group2=[1 0 1 1 1 1 1 1 ];

    end
        %  animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';index_group=[1 1 1 ];
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';index_group=[1 1 0 1 1 1 ];
% animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';index_group=[1 1 1 1 1 ];
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';index_group=[ 1 1 1  ];

data1=load([Path 'summary_data\behavior in mixed task in ' n1_name '_to_' n2_name '.mat' ]);




stim2move_med_mix_v{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),1)==1),2) ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_a{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),2)==1),3)     ,...
    data1.all_animal_stim2move_mean(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_v_null{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),1)==1),2) ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_a_null{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),2)==1),3)     ,...
    data1.all_animal_stim2move_mean_null(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

end


aligned_mix_v_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_v,'UniformOutput',false);
aligned_mix_v_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mix_v,'UniformOutput',false);

aligned_mix_a_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_a,'UniformOutput',false);
aligned_mix_a_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),stim2move_med_mix_a,'UniformOutput',false);
performance_mixed_v=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), ...
    stim2move_med_mix_v,stim2move_med_mix_v_null ,'UniformOutput',false);
performance_mixed_a=cellfun(@(x,y)  cellfun(@(v,w) (w-v)./(w+v) ,x,y,'UniformOutput',false), ...
    stim2move_med_mix_a,stim2move_med_mix_a_null ,'UniformOutput',false);
performance_mix_v_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),performance_mixed_v,'UniformOutput',false);
performance_mix_v_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),performance_mixed_v,'UniformOutput',false);

performance_mix_a_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),performance_mixed_a,'UniformOutput',false);
performance_mix_a_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),performance_mixed_a,'UniformOutput',false);


face_color={'#DAE3F3','#FFB2B2'};
line_color={[0.5 0.5 1],[1 0.5 0.5];[0.1 0.1 1],[1 0.1 0.1]};
group_name={'V-A','A-V'};
legned_name={'visual task','auditory task'};
%
% 
 figure('Position',[50 50 200 300]);

for curr_fig=1:2
hold on
ap.errorfill(1:3,aligned_mix_v_mean{curr_fig}, aligned_mix_v_error{curr_fig},line_color{curr_fig,1},0.1,0.5);
ap.errorfill(4:6,aligned_mix_a_mean{curr_fig}, aligned_mix_a_error{curr_fig},line_color{curr_fig,2},0.1,0.5);


xticks([2 4] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'mixed V','mixed A'}); % 设置对应的标签
xtickangle(30);

legend({'',legned_name{1},'',legned_name{2}},'Location','northeastoutside','Box','off')
ylabel('stim to move (s)')
ylim([0 0.7])

 sgtitle(group_name{curr_fig})
  saveas(gcf,[Path 'figures\summary\figures\figure 1 stim2move of mixed task in ' group_name{curr_fig} ], 'jpg');

end
 figure('Position',[50 50 200 300]);

for curr_fig=1:2
hold on
ap.errorfill(1:3,performance_mix_v_mean{curr_fig}, performance_mix_v_error{curr_fig},line_color{1},0.1,0.5);
ap.errorfill(4:6,performance_mix_a_mean{curr_fig}, performance_mix_a_error{curr_fig},line_color{2},0.1,0.5);


xticks([2 4] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'mixed V','mixed A'}); % 设置对应的标签
xtickangle(30);

legend({'',legned_name{1},'',legned_name{2}},'Location','northeastoutside','Box','off')
ylabel('stim to move (s)')
ylim([0 0.7])

 sgtitle(group_name{curr_fig})
  saveas(gcf,[Path 'figures\summary\figures\figure 1 stim2move of mixed task in ' group_name{curr_fig} ], 'jpg');

end

