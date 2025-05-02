

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
colormap(a1,[0.3 1 1; 0.7 1 1; 0.8 0.8 0.8]); % 红、绿、蓝

title('VA')
 legend(labels, 'Location', 'northoutside', 'Orientation', 'vertical','Box','off');
a2=nexttile
h2=pie(data_AV, explode,labels_num_AV);
for k = 1:length(h2)
    h2(k).EdgeColor = 'none';
end
title('AV')
 colormap(a2,[1 0.3 1; 1 0.7 1; 0.8 0.8 0.8]); % 红、绿、蓝

legend( labels, 'Location', 'northoutside', 'Orientation', 'vertical', 'Box', 'off');


 % saveas(gcf,[Path 'figures\summary\figures\figure 1 behavior proportion'], 'jpg');
%% stim2move stage1 and stage2

clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
num_stage1=cell(2,1);

output_data=struct;
output_data.stim2move_med_stage0_1=cell(2,1)
output_data.stim2move_med_stage0=cell(2,1)
output_data.stim2move_med_stage1=cell(2,1)
output_data.stim2move_med_stage2=cell(2,1)
output_data.stim2move_med_null_stage0_1=cell(2,1)
output_data.stim2move_med_null_stage0=cell(2,1)
output_data.stim2move_med_null_stage1=cell(2,1)
output_data.stim2move_med_null_stage2=cell(2,1)

for curr_group=1:2
    if curr_group==1

        animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
        index_group1=[1 1 1 1 1 1 0 1 1 ]';
        index_group2=[1 1 1 1 1 1 0 0 0 ]';
    else
        animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
        index_group1=[0 1 1 1 1 1 1 1 ];
        index_group2=[0 0 0 1 1 1 1 1 ];

    end
        %  animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';index_group=[1 1 1 ];
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';index_group=[1 1 0 1 1 1 ];
% animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';index_group=[1 1 1 1 1 ];
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';index_group=[ 1 1 1  ];

data1=load([Path 'mat_data\summary_data\behavior in ' n1_name '_to_' n2_name '.mat' ]);

num_stage1{curr_group}=cellfun(@(x)  find(x==1,1,'first'),  data1.all_animal_learned_day(find(index_group1==1))  ,'UniformOutput',true);

num_stage2{curr_group}=cellfun(@(x,y)  find((x==1&strcmp(n2_name,y)),1,'first')- find(strcmp(n2_name,y),1,'first')+1,  data1.all_animal_learned_day(find(index_group2==1)), data1.all_animal_workflow_name(find(index_group2==1))  ,'UniformOutput',true);



buffer_name={'','_null'};

for curr_i=1:2
output_data.(['stim2move_med' buffer_name{curr_i} '_stage0_1']){curr_group} =cellfun(@(x,y,z,l)  x(find( strcmp(n1_name,l) &z>0,1,"first"): find( strcmp(n1_name,l) &z>0,1,"last") )  ,...
    data1.(['all_animal_stim2move_med' buffer_name{curr_i} ])(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false)

output_data.(['stim2move_med' buffer_name{curr_i} '_stage0']){curr_group} =cellfun(@(x,y,z,l)  x(find(y==0& strcmp(n1_name,l) &z>0,1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"first")-1 )  ,...
    data1.(['all_animal_stim2move_med' buffer_name{curr_i} ])(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false)

output_data.(['stim2move_med' buffer_name{curr_i} '_stage1']){curr_group} =cellfun(@(x,y,z,l)   x( find(y==1& strcmp(n1_name,l) &z>0,1,"first"): find(y==1& strcmp(n1_name,l) &z>0,1,"last"))        ,...
    data1.(['all_animal_stim2move_med' buffer_name{curr_i} ])(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);

output_data.(['stim2move_med' buffer_name{curr_i} '_stage2']){curr_group} =cellfun(@(x,y,z,l)   x( find( strcmp(n2_name,l) &z>0,1,"first"): find( strcmp(n2_name,l) &z>0,1,"last"))        ,...
    data1.(['all_animal_stim2move_med' buffer_name{curr_i} ])(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),...
    data1.all_animal_react_index(find(index_group2==1)),data1.all_animal_workflow_name(find(index_group2==1)) ,'UniformOutput',false);
end


% num{curr_group}=cellfun(@(x)  find(x==1,1,'first')-1,  data1.all_animal_learned_day  ,'UniformOutput',true);

end


output_data.stim2move_med_perform_stage0_1=cellfun(@(x,y) cellfun(@(a,b) (b-a)./(b+a),x,y,'UniformOutput',false ),output_data.stim2move_med_stage0_1,output_data.stim2move_med_null_stage0_1,'UniformOutput',false)
output_data.stim2move_med_perform_stage0=cellfun(@(x,y) cellfun(@(a,b) (b-a)./(b+a),x,y,'UniformOutput',false ),output_data.stim2move_med_stage0,output_data.stim2move_med_null_stage0,'UniformOutput',false)
output_data.stim2move_med_perform_stage1=cellfun(@(x,y) cellfun(@(a,b) (b-a)./(b+a),x,y,'UniformOutput',false ),output_data.stim2move_med_stage1,output_data.stim2move_med_null_stage1,'UniformOutput',false)
output_data.stim2move_med_perform_stage2=cellfun(@(x,y) cellfun(@(a,b) (b-a)./(b+a),x,y,'UniformOutput',false ),output_data.stim2move_med_stage2,output_data.stim2move_med_null_stage2,'UniformOutput',false)


% 找到最长数组的长度 创建 NaN 填充的矩阵，右对齐填充数据
buffer_name={'','_perform','_null'};
buffer_stage={'1','2','0_1','0'};
for curr_i=1:3
    for curr_stage=1:3
output_data.(['aligned_stage' buffer_stage{curr_stage} buffer_name{curr_i} '_mean'])=...
    cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( max(cellfun(@length, x)) - length(v),1) ],...
    x, 'UniformOutput', false)'), 2,'omitmissing'),output_data.(['stim2move_med' buffer_name{curr_i} ...
    '_stage' buffer_stage{curr_stage}]),'UniformOutput',false);
output_data.(['aligned_stage' buffer_stage{curr_stage} buffer_name{curr_i} '_error'])=...
    cellfun(@(x) std( cell2mat(cellfun(@(v) [v;nan( max(cellfun(@length, x)) - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),output_data.(['stim2move_med' buffer_name{curr_i}   '_stage' buffer_stage{curr_stage}]),'UniformOutput',false);
    end
    curr_stage=4;
   output_data.(['aligned_stage' buffer_stage{curr_stage} buffer_name{curr_i} '_mean'])=...
    cellfun(@(x) median( cell2mat(cellfun(@(v) [nan( max(cellfun(@length, x)) - length(v),1) ;v],...
    x, 'UniformOutput', false)'), 2,'omitmissing'),output_data.(['stim2move_med' buffer_name{curr_i} ...
    '_stage' buffer_stage{curr_stage}]),'UniformOutput',false);
output_data.(['aligned_stage' buffer_stage{curr_stage} buffer_name{curr_i} '_error']) =...
    cellfun(@(x) std( cell2mat(cellfun(@(v) [nan( max(cellfun(@length, x)) - length(v),1);v ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/sqrt(length(x)),output_data.(['stim2move_med' buffer_name{curr_i}   '_stage' buffer_stage{curr_stage}]),'UniformOutput',false);
   
end



face_color={'#DAE3F3','#FFB2B2'};
line_color={[0 1 1],[1 0 1]};
group_name={'V-A','A-V'};
legned_name={'VA','AV in A';'AV','VA in V'};

buffer_name={'','_null','_perform'};

for curr_i=[1 3]

 for curr_fig=1:2
         figure('Position',[50 50 200 300]);

ap.errorfill(1:length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig}),...
    output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig},...
    output_data.(['aligned_stage0'  buffer_name{curr_i}  '_error']){curr_fig},line_color{curr_fig},0.1,0.5);

ap.errorfill(length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+1:...
    length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig}),...
    output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig},...
    output_data.(['aligned_stage1'  buffer_name{curr_i}  '_error']){curr_fig},line_color{curr_fig},0.1,0.5);

ap.errorfill(length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig})+1:...
    length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage2'  buffer_name{curr_i}  '_mean']){curr_fig}),...
    output_data.(['aligned_stage2'  buffer_name{curr_i}  '_mean']){curr_fig},...
    output_data.(['aligned_stage2'  buffer_name{curr_i}  '_error']){curr_fig},line_color{curr_fig},0.1,0.5);

ap.errorfill(length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig})+1:...
    length(output_data.(['aligned_stage0'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage1'  buffer_name{curr_i}  '_mean']){curr_fig})+...
    length(output_data.(['aligned_stage0_1'  buffer_name{curr_i}  '_mean']){3-curr_fig}),...
    output_data.(['aligned_stage0_1'  buffer_name{curr_i}  '_mean']){3-curr_fig}, ...
    output_data.(['aligned_stage0_1'  buffer_name{curr_i}  '_error']){3-curr_fig},line_color{3-curr_fig},0.1,0.5);
xticks([(length(output_data.aligned_stage0_mean{curr_fig})+1)/2,  length(output_data.aligned_stage0_mean{curr_fig})+...
    0.5*length(output_data.aligned_stage1_mean{curr_fig}) ,...
  length(output_data.aligned_stage0_mean{curr_fig})+length(output_data.aligned_stage1_mean{curr_fig})+0.5*length(output_data.aligned_stage2_mean{curr_fig})  ] ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'pre learn','mordality 1','mordality 1'}); % 设置对应的标签

if curr_i==1|| curr_i==2
yline(0.1)
legend({'',legned_name{curr_fig,1},'','','','','',legned_name{curr_fig,2}},'Location','northeast','Box','off')

ylabel('stim to move (s)')
ylim([0 0.7])
xlim([1 length(output_data.aligned_stage0_mean{curr_fig})+length(output_data.aligned_stage1_mean{curr_fig})+length(output_data.aligned_stage2_mean{curr_fig})])
% ax = gca;
% ylim1 = ax.YLim;
% bg1 =rectangle('Position', [0, ylim1(1), length(output_data.aligned_stage0_mean{curr_fig})+0.5, diff(ylim1)], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
%  uistack(bg1, 'bottom');
% bg2 =rectangle('Position', [length(output_data.aligned_stage0_mean{curr_fig})+0.5, ylim1(1), 5, diff(ylim1)], 'FaceColor', face_color{curr_fig}, 'EdgeColor', 'none');
% uistack(bg2, 'bottom');
% bg3 =rectangle('Position', [length(output_data.aligned_stage0_mean{curr_fig})+length(output_data.aligned_stage1_mean{curr_fig})+0.5, ylim1(1), length(output_data.aligned_stage2_mean{curr_fig}), diff(ylim1)], 'FaceColor',face_color{3-curr_fig} , 'EdgeColor', 'none');
% uistack(bg3, 'bottom');
 sgtitle(group_name{curr_fig})
else
legend({'',legned_name{curr_fig,1},'','','','','',legned_name{curr_fig,2}},'Location','northeast','Box','off')
ylabel('performance')
ylim([0 0.5])
xlim([1 length(output_data.aligned_stage0_mean{curr_fig})+length(output_data.aligned_stage1_mean{curr_fig})+length(output_data.aligned_stage2_mean{curr_fig})])


end
 % saveas(gcf,[Path 'figures\summary\figures\figure 1 stim2move in ' group_name{curr_fig} ], 'jpg');

 end

end






%% 
% 定义颜色
barColors = [0.6, 1, 1; 1, 0.6, 1]; % 浅蓝、浅红
scatterColors = [0, 1, 1; 1, 0, 1]; % 深蓝、深红
num_stage = {num_stage1, num_stage2};

for curr_stage=1:2

buff_stage=num_stage{curr_stage};
  


% 计算均值和标准误差
means = cellfun(@mean, buff_stage);
stds = cellfun(@std, buff_stage);
nSamples = cellfun(@length, buff_stage);
sem = stds ./ sqrt(nSamples);  % 计算标准误 SEM

% 创建柱状图，并确保 `bar` 只返回一个 `Bar` 对象数组
figure('Position',[50 50 200 300]); hold on;
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

% 美化图像
xticks([1 2]);
xticklabels({'VA', 'AV'});
ylabel(['first association day of stage '  num2str(curr_stage)]);
% title('Bar Chart with Error Bars and Scatter Points');
grid off;
hold off;
saveas(gcf,[Path 'figures\summary\figures\figure 1 first association day of stage ' num2str(curr_stage) ], 'jpg');
end



 %% stim2move in mixed task

clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
num_stage1=cell(2,1);

for curr_group=1:2
    if curr_group==1

        animals = {'DS007','DS010','AP021','DS011','DS001','AP018','AP020'};n1_name='visual position';n2_name='audio volume';
        index_group2=[1  1 1 1 0 0 0  ];
    else
        animals = {'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
        index_group2=[0 0 0 1 1 1 1 1 ];

    end
        %  animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';index_group=[1 1 1 ];
% animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';index_group=[1 1 0 1 1 1 ];
% animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';index_group=[1 1 1 1 1 ];
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';index_group=[ 1 1 1  ];

data1=load([Path 'mat_data\summary_data\behavior in mixed task in ' n1_name '_to_' n2_name '.mat' ]);




stim2move_med_mix_v{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),1)==1),2) ,...
    data1.all_animal_stim2move_med(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);

stim2move_med_mix_a{curr_group} =cellfun(@(x,y)  x(find(y(1:min(3,size(y,1)),2)==1),3)     ,...
    data1.all_animal_stim2move_med(find(index_group2==1)),data1.all_animal_learned_day(find(index_group2==1)),'UniformOutput',false);


end

aligned_mix_v_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_v,'UniformOutput',false);
aligned_mix_v_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/length(x),stim2move_med_mix_v,'UniformOutput',false);

aligned_mix_a_mean =cellfun(@(x) median( cell2mat(cellfun(@(v) [v;nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 2,'omitmissing'),stim2move_med_mix_a,'UniformOutput',false);
aligned_mix_a_error =cellfun(@(x) std( cell2mat(cellfun(@(v) [v; nan( 3 - length(v),1) ], x, 'UniformOutput', false)'), 0,2,'omitmissing')/length(x),stim2move_med_mix_a,'UniformOutput',false);

face_color={'#DAE3F3','#FFB2B2'};
line_color={[0.5 0.5 1],[1 0.5 0.5]};
group_name={'V-A','A-V'};
legned_name={'visual task','auditory task'};
%%
for curr_fig=1:2
figure('Position',[50 50 200 300]);
ap.errorfill(1:3,aligned_mix_v_mean{curr_fig}, aligned_mix_v_error{curr_fig},line_color{1},0.1,0.5);
ap.errorfill(1:3,aligned_mix_a_mean{curr_fig}, aligned_mix_a_error{curr_fig},line_color{2},0.1,0.5);


xticks(2 ); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'mixed task'}); % 设置对应的标签
xtickangle(30);

legend({'',legned_name{1},'',legned_name{2}},'Location','northeastoutside','Box','off')
ylabel('stim to move (s)')
ylim([0 0.7])

 sgtitle(group_name{curr_fig})
  saveas(gcf,[Path 'figures\summary\figures\figure 1 stim2move of mixed task in ' group_name{curr_fig} ], 'jpg');

end

