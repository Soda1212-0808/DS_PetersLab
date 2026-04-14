 
clear all
clc
Path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025';

% Path='D:\Data process\slide\papers';
U_master = plab.wf.load_master_U;
% load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
load(fullfile(Path,'data\General_information\roi.mat'))
    surround_samplerate = 35;
surround_window_task = [-0.2,1];
task_boundary1=0;
task_boundary2=0.2;

t_kernels=1/surround_samplerate*[-10:30];
kernels_period=find(t_kernels>task_boundary1&t_kernels<task_boundary2);

%% 
%% fig 3 context difference
main_preload_vars = who;
load(fullfile(Path,'data','wf_passive_kernels'));
load(fullfile(Path,'data','wf_task_kernels'));
load(fullfile(Path,'data','behavior'));



workflow={'visual position';'audio volume'};

temp_task_roi =cellfun(@(k,w,name) cellfun(@(k1,w1)  cellfun(@(x) ...
    ds.make_each_roi( plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),length(t_kernels),roi1),k1(ismember(w1,name)),'UniformOutput',false)...
    ,k,w.workflow_name,'UniformOutput',false),wf_task_kernel_each_mice,behavior_each_mice,workflow,'UniformOutput',false);
temp_task_peak=cellfun(@(a1) cellfun(@(a2)  cellfun(@(a3)  max(a3([1 3 7 9],kernels_period),[],2),a2,...
    'UniformOutput',false),a1, 'UniformOutput',false),temp_task_roi,'UniformOutput',false);
temp_task_peak2=cellfun(@(a1) cellfun(@(a2)  cat(2,a2{:})'  ,a1, 'UniformOutput',false),temp_task_peak,'UniformOutput',false);




temp_passive_roi =cellfun(@(k,w,name,id) cellfun(@(k1,w1)  cellfun(@(x) ...
    ds.make_each_roi( plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),length(t_kernels),roi1),k1(find(ismember(w1,name))+3),'UniformOutput',false)...
    ,k{id},w.workflow_name,'UniformOutput',false),wf_passive_kernel_each_mice,behavior_each_mice,workflow,{1;2},'UniformOutput',false);


temp_passive_peak=cellfun(@(a1,stim) cellfun(@(a2)  cellfun(@(a3)  max(a3([1 3 7 9],kernels_period,stim),[],2),a2,...
    'UniformOutput',false),a1, 'UniformOutput',false),temp_passive_roi,{3;2},'UniformOutput',false);


temp_passive_peak2=cellfun(@(a1) cellfun(@(a2)  cat(2,a2{:})'  ,a1, 'UniformOutput',false),temp_passive_peak,'UniformOutput',false);
temp_passive_peak3=cellfun(@(a1)   cat(1,a1{:}) ,temp_passive_peak2,'UniformOutput',false);


temp_learn =cellfun(@(w,name) cellfun(@(p1,w1) p1(ismember(w1,name),1),...
    w.learned ,w.workflow_name,'UniformOutput',false),behavior_each_mice,workflow,'UniformOutput',false);



%%


colors_1{1}=[[0 0 1];[0.5 0.5 1]];
colors_1{2}=[[1 0 0];[1 0.5 0.5]];
slope_task=cell(2,1);
slope_pass=cell(2,1);
a1=cell(2,2)
sensory_id=[3 4]
sensory_name={'visual','auditory'}
figure
for curr_group=1:2
    % a1{curr_roi,curr_group}=nexttile(t1,curr_roi*8-8+curr_group*3+1)
    a1=nexttile
    hold on
    % h1 = scatter(NaN,NaN,20,'filled','MarkerFaceColor',[0.2 0.2 0.2],'LineWidth',1);
    % cellfun(@(t2,l2)   scatter(t2(l2==0,sensory_id(curr_group)),t2(l2==0,1),20,'filled',...
    %     'MarkerFaceColor',[0.2 0.2 0.2],'LineWidth',1),...
    %     temp_task_peak2{curr_group},temp_learn{curr_group},'UniformOutput',false )
    % 

    h2 = scatter(NaN,NaN,20,'filled','MarkerFaceColor',colors_1{curr_group}(1,:),'LineWidth',1);


    cellfun(@(t2,l2)   scatter(t2(l2==1,sensory_id(curr_group)),t2(l2==1,1),20,'filled',...
        'MarkerFaceColor',colors_1{curr_group}(1,:),'LineWidth',1),...
        temp_task_peak2{curr_group},temp_learn{curr_group},'UniformOutput',false )




    % h3 = scatter(NaN,NaN,20,'filled','MarkerFaceColor',[0.5 0.5 0.5],'LineWidth',1);
    % cellfun(@(t2,l2)   scatter(t2(l2==0,sensory_id(curr_group)),t2(l2==0,1),20,'filled',...
    %     'MarkerFaceColor',[0.5 0.5 0.5],'LineWidth',1),...
    %    temp_passive_peak2{curr_group},temp_learn{curr_group},'UniformOutput',false )


    h4 = scatter(NaN,NaN,20,'filled','MarkerFaceColor',colors_1{curr_group}(2,:),'LineWidth',1);
    cellfun(@(t2,l2)   scatter(t2(l2==1,sensory_id(curr_group)),t2(l2==1,1),20,'filled',...
        'MarkerFaceColor',colors_1{curr_group}(2,:),'LineWidth',1),...
       temp_passive_peak2{curr_group},temp_learn{curr_group},'UniformOutput',false )


    %
    % learn_3=logical(cat(1,temp_learn{curr_group}{:}));
    %
    % task_peak3=cat(1,temp_task_peak2{curr_group}{:});
    % perform3=cat(1,temp_perform{curr_group}{:});
    %
    % p_task = polyfit(perform3(learn_3), task_peak3(learn_3,curr_roi), 1);
    % x_fit_task = linspace(0, 1, 2);
    % y_fit_task = polyval(p_task, x_fit_task);
    % plot(x_fit_task, y_fit_task, '-', 'LineWidth', 2,'Color',colors_1{curr_group}(1,:));
    %
    %
    % passive_peak3=cat(1,temp_passive_peak2{curr_group}{:});
    %
    %
    % p_passive = polyfit(perform3(learn_3), passive_peak3(learn_3,curr_roi), 1);
    % x_fit_passive = linspace(0, 1, 2);
    % y_fit_passive = polyval(p_passive, x_fit_passive);
    % plot(x_fit_passive, y_fit_passive, '-', 'LineWidth', 2,'Color',colors_1{curr_group}(2,:));
    %
    %
    % [R_task,P_task] = corr(perform3(learn_3), task_peak3(learn_3,curr_roi));
    %
    % [R_passive,P_passive] = corr(perform3(learn_3),  passive_peak3(learn_3,curr_roi));
    %
    %
    % slope_task{curr_group}{curr_roi}= cellfun(@(perform,peak,learned) diff(polyval( polyfit( perform, peak(:,curr_roi),1), linspace(0, 1, 2))),...
    %     temp_perform{curr_group},temp_task_peak2{curr_group},temp_learn{curr_group},'UniformOutput',true);
    %
    % slope_pass{curr_group}{curr_roi}= cellfun(@(perform,peak,learned) diff(polyval( polyfit( perform, peak(:,curr_roi),1), linspace(0, 1, 2))),...
    %     temp_perform{curr_group},temp_passive_peak2{curr_group},temp_learn{curr_group},'UniformOutput',true);
    %
    %

    x1max=feval(@(a) max(a(cat(1,temp_learn{curr_group}{:})==1,sensory_id(curr_group))),   cat(1,temp_task_peak2{curr_group}{:}))
    y1max=feval(@(a) max(a(cat(1,temp_learn{curr_group}{:})==1,1)),   cat(1,temp_task_peak2{curr_group}{:}))

    xlim([0 x1max])
    xticks([0 x1max ])
    xticklabels({'0','max'})
    ylim([0 y1max])
   yticks([0 y1max ])
    yticklabels({'0','max'})
    % % title(roi_name{curr_roi} ,'FontWeight','normal')

    xlabel([sensory_name{curr_group} ' Norm \Delta F/F_{0}'])
    ylabel('mPFC Norm \Delta F/F_{0}')
    axis square

    a1.FontSize = 12;
        legend([h2  h4], ...
            {'task','passive'},'NumColumns',2, ...
            'Location','northoutside','Box','off');
    
    set(gca, 'Color', 'none');        % 坐标轴背景透明

end





