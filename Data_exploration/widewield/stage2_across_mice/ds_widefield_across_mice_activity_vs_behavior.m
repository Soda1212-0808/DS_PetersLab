clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.5,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);


workflow_idx=1;
all_workflow={'lcr_passive','hml_passive_audio'};
wokrflow=all_workflow{workflow_idx};

learn_name={'non-learned','learned'};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};

% animals = {'AP027','AP028','AP029'};
% animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};transfer_type='v_position_to_a_volumne';Group_type=1;
% 'DS003','DS006','DS013',
% animals = {'DS000','DS004','DS014','DS015','DS016'};transfer_type='a_volumne_to_v_position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'}; transfer_type='v_opacity_to_v_position';Group_type=2;
% animals = {'HA003','HA004','DS019','DS020','DS021'};  transfer_type='v_size_up_to_v_position';Group_type=3;
% animals = {'DS019','DS020','DS021'};  transfer_type='v_size_up_to_v_position';
% animals = {'HA000','HA001','HA002'};  transfer_type='v_angle_to_v_position';Group_type=4;


animals = {'DS007','DS010','AP019','AP021','DS011','AP022','AP018','AP020',...
    'AP027','AP028','AP029',...
    'HA003','HA004','DS019','DS020','DS021',...
    'DS000','DS004','DS014','DS015','DS016',...
    'HA000','HA001','HA002'};
Groups={'vp-av','vp-av','vp-av','vp-av','vp-av','vp-av','vp-av','vp-av',...
    'vo-vp','vo-vp','vo-vp',...
    'vs-vp','vs-vp','vs-vp','vs-vp','vs-vp',...
    'av-vp','av-vp','av-vp','av-vp','av-vp',...
    'va-vp','va-vp','va-vp'};


all_data_3_peak_V1=cell(length(animals),1);
all_data_3_peak=cell(length(animals),1);
all_data_stim=cell(length(animals),1);
all_data_image=cell(length(animals),1);
all_data_workflow_name=cell(length(animals),1);
all_data_learned_day=cell(length(animals),1);
all_data_workflow_day=cell(length(animals),1);
matches=cell(length(animals),1);
use_t=[];

for curr_animal=22:length(animals)
    preload_vars = who;

    animal=animals{curr_animal};
    raw_data_passive=load([Path '\mat_data\' wokrflow '\' animal '_' wokrflow '.mat']);
    % raw_data_behavior=load([Path '\mat_data\behavior\' animal '_behavior.mat']);

    if used_data==1
        idx=cellfun(@(x) ~(isempty(x)|~(size(x,3)==3))  ,raw_data_passive.wf_px);
        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_passive.wf_px(idx),'UniformOutput',false);
        use_period=period_passive;
        use_t=t_passive;
    else
        idx=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px_kernels);
        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),raw_data_passive.wf_px_kernels(idx),'UniformOutput',false);
        use_period=period_kernels;
        use_t=t_kernels;
    end
    matches{curr_animal}=unique(raw_data_passive.workflow_type_name_merge(idx)  ,'stable');

    image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
    buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
    buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);
        buf3_V1(idx)= cellfun(@(z) permute(mean(z(roi1(3).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);

    all_data_3_peak_V1{curr_animal}=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_V1(idx),'UniformOutput',false)');
    all_data_3_peak{curr_animal}=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_mPFC(idx),'UniformOutput',false)');
    all_data_stim{curr_animal}=cell2mat(cellfun(@(x) x(:,3),buf3_mPFC(idx),'UniformOutput',false))';
    all_data_image{curr_animal}=cellfun(@(x) x(:,:,3),image_all_mean(idx),'UniformOutput',false);
    all_data_workflow_name{curr_animal}=raw_data_passive.workflow_type_name_merge(idx);
    all_data_learned_day{curr_animal}=raw_data_passive.learned_day(idx);
    all_data_workflow_day{curr_animal}=raw_data_passive.workflow_day(idx);

    clearvars('-except',preload_vars{:});
end

type_name={'visual position','visual size up','visual opacity','visual angle'};


n1_day=cellfun(@(n) cellfun(@(x,y,z) x(strcmp(y,n),:),all_data_workflow_day,all_data_workflow_name,'UniformOutput',false),type_name,'UniformOutput',false);



% behavioral data processs

all_data_stim2move_med=cell(length(type_name),1);
all_data_learned_day=cell(length(type_name),1);
all_data_image_group=cell(length(type_name),1);
all_data_peak_group_mPFC=cell(length(type_name),1);
all_data_peak_group_V1=cell(length(type_name),1);

for curr_animal=1:length(animals)
    animal=animals{curr_animal};
    raw_data_behavior=load([Path '\mat_data\behavior\' animal '_behavior.mat']);
    for curr_type=1:length(type_name)
      preload_vars = who;

    % [~, idx] = ismember(n1_day{curr_animal},raw_data_behavior.workflow_day); 
    % all_data_stim2move_med{curr_animal}= raw_data_behavior.stim2move_med(idx);
    % all_data_learned_day{curr_animal}= raw_data_behavior.learned_day(idx);

    [~, idx] = ismember(n1_day{curr_type}{curr_animal},raw_data_behavior.workflow_day);

    all_data_stim2move_med{curr_type}{curr_animal,1}= mean(raw_data_behavior.stim2move_med(idx(max(end-4,1):end)));
    all_data_learned_day{curr_type}{curr_animal,1}= mean(raw_data_behavior.learned_day(idx(max(end-4,1):end)));

    [~, idx2] = ismember(n1_day{curr_type}{curr_animal},all_data_workflow_day{curr_animal});

    all_data_image_group{curr_type}{curr_animal,1}=mean(cat(3,all_data_image{curr_animal}{idx2(max(end-4,1):end)}),3);
    all_data_peak_group_mPFC{curr_type}{curr_animal,1}=mean(all_data_3_peak{curr_animal}(idx2(max(end-4,1):end),3));

    all_data_peak_group_V1{curr_type}{curr_animal,1}=mean(all_data_3_peak_V1{curr_animal}(idx2(max(end-4,1):end),3));


    clearvars('-except',preload_vars{:});
end

end




%%
figure('Position',[50 50 1400 400]);
colors = {[1 0 0;0 1 0;0 0 1;0 0 0;1 1 0],...
    [1 0.7 0.7;0.7 1 0.7;0.7 0.7 1;0.7 0.7 0.7;0.7 0.7 0],...
    [1 0.7 0.7;0.7 1 0.7;0.7 0.7 1;0.7 0.7 0.7;0.7 0.7 0],...
    [1 0.7 0.7;0.7 1 0.7;0.7 0.7 1;0.7 0.7 0.7;0.7 0.7 0]};
xdata=cellfun(@(x) -log(cell2mat(x)),all_data_stim2move_med,'UniformOutput',false)

nexttile
ydata=cellfun(@(x) cell2mat(x),all_data_peak_group_mPFC,'UniformOutput',false)

hold on 
gscatter(x1data{2},ydata{2},Groups',colors{2})
text(x1data{2}, ydata{2}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(x1data{3},ydata{3},Groups',colors{3})
text(x1data{3}, ydata{3}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(x1data{4},ydata{4},Groups',colors{4})
text(x1data{4}, ydata{4}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(x1data{1},ydata{1},Groups',colors{1})
text(x1data{1}, ydata{1}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
ylabel('mPFC activity(df/f)');
xlabel('-log(reaction time）');
title('mPFC vs behavior in passive raw')



nexttile
ydata=cellfun(@(x) cell2mat(x),all_data_peak_group_V1,'UniformOutput',false)
hold on 
gscatter(xdata{2},ydata{2},Groups',colors{2})
text(xdata{2}, ydata{2}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(xdata{3},ydata{3},Groups',colors{3})
text(xdata{3}, ydata{3}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(xdata{1},ydata{1},Groups',colors{1})
text(xdata{1}, ydata{1}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
ylabel('V1 activity(df/f)');
xlabel('-log(reaction time）');
title('V1 vs behavior in passive raw')

nexttile
ydata=cellfun(@(x,y) cell2mat(x)./cell2mat(y),all_data_peak_group_mPFC,all_data_peak_group_V1,'UniformOutput',false)
hold on 
gscatter(xdata{2},ydata{2},Groups',colors{2})
text(xdata{2}, ydata{2}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(xdata{3},ydata{3},Groups',colors{3})
text(xdata{3}, ydata{3}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
gscatter(xdata{1},ydata{1},Groups',colors{1})
text(xdata{1}, ydata{1}, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
ylabel('mPFC/V1 activity(df/f)');
xlabel('-log(reaction time）');
title('mPFC/V1 vs behavior in passive raw')
 % saveas(gcf,[Path 'figures\summary\different_task_passive\correlation between reaction time vs mPFC in passive'], 'jpg');

%%


match_name={'visual position','visual opacity','visual angle','visual size up'};
all_n1_data_image=cell(length(match_name),1);
for curr_name=1:length(match_name)
 n1_data_image=cell(length(all_data_image),1);
curr_match= cellfun(@(x)   find(strcmp(x,match_name{curr_name})),matches,'UniformOutput',false);
idx_0=cellfun(@(x) isempty(x),curr_match,'UniformOutput',true);
curr_match(idx_0)=cellfun(@(x) 0,curr_match(idx_0),'UniformOutput',false);
n1_data_image(~idx_0) = cellfun(@(x,y,z,m) mean(cat(3,x{find(strcmp(y,z{m}),5,'last')}),3),all_data_image(~idx_0),all_data_workflow_name(~idx_0),matches(~idx_0),curr_match(~idx_0),'UniformOutput',false);
all_n1_data_image{curr_name}=n1_data_image;
end



%%
match_indx={1,1,1,1,1,1,1,1,...
    1,1,1,...
    1,1,1,1,1,...
    1,1,1,...
    2,2,2,2}';
n1_data_image = cellfun(@(x,y,z,m) mean(cat(3,x{find(strcmp(y,z{m+1}),5,'last')}),3),all_data_image,all_data_workflow_name,matches,match_indx,'UniformOutput',false);
n1_stim2move_med=cellfun(@(x)  mean(x(max(1,end-4):end))  ,  all_data_stim2move_med,'UniformOutput',true);



categories = unique(Groups'); % 获取分类
categories = {'position','opacity','size up','angle','a-position'}; % 获取分类




buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , n1_data_image, 'UniformOutput', false);
buf_mPFC= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', true);
buf_V1= cellfun(@(z) permute(mean(z(roi1(3).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', true);

xdata=-log(n1_stim2move_med);
figure('Position',[50 50 500 900]);
nexttile
% ydata=buf_mPFC./buf_V1;
 ydata=buf_mPFC;

% scatter(xdata,buf_mPFC,20,Groups','filled')
hold on
colors = lines(length(categories)); % 为每种分类分配颜色

scatter_handles = arrayfun(@(i) ...
    scatter(xdata(Groups == i), ydata(Groups == i), 50, ...
    'filled', 'MarkerFaceColor', colors(i, :), 'DisplayName', categories{i}), ...
    1:length(categories));
legend(categories, 'Location', 'northeastoutside');

% xlim([-1 2]);ylim([0 0.004])
ylabel('mPFC activity(df/f)');
xlabel('-log(reaction time）');
text(xdata, ydata, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');


nexttile
hold on
scatter_handles = arrayfun(@(i) ...
    scatter(xdata(Groups == i), buf_V1(Groups == i), 50, ...
    'filled', 'MarkerFaceColor', colors(i, :), 'DisplayName', categories{i}), ...
    1:length(categories));
legend(categories, 'Location', 'northeastoutside');

xlim([-1 2]);ylim([0 0.01])
ylabel('V1 activity(df/f)');
xlabel('-log(reaction time）');
text(xdata, buf_V1, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

nexttile
ydata=buf_mPFC./buf_V1;
 % ydata=buf_mPFC;

% scatter(xdata,buf_mPFC,20,Groups','filled')
hold on
colors = lines(length(categories)); % 为每种分类分配颜色

scatter_handles = arrayfun(@(i) ...
    scatter(xdata(Groups == i), ydata(Groups == i), 50, ...
    'filled', 'MarkerFaceColor', colors(i, :), 'DisplayName', categories{i}), ...
    1:length(categories));
legend(categories, 'Location', 'northeastoutside');

% xlim([-1 2]);ylim([0 0.004])
ylabel('mPFC/V1');
xlabel('-log(reaction time）');
text(xdata, ydata, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');


saveas(gcf,[Path 'figures\summary\correlation between reaction time vs mPFC'], 'jpg');


% mPFC across day across time
% n1_data_image = cellfun(@(x,y) x(strcmp(y,matches{1}{2}))',all_data_image,all_data_workflow_name,'UniformOutput',false);


%%
data_image_from_first_day = cellfun(@(x,y,z,m) cat(3,x{find(strcmp(y,z{m+1}),5,'first')}),all_data_image,all_data_workflow_name,matches,match_indx,'UniformOutput',false);




data_image_from_first_day = cellfun(@(x,y,z,m) {x{find(strcmp(y,z{m+1}),5,'first')}},all_data_image,all_data_workflow_name,matches,match_indx,'UniformOutput',false);


%%
figure;

for curr_line=1:length(animals)
nexttile;
plot(all_data_stim2move_med{curr_line},'Color',colors(Groups(curr_line),:))
ylim([0 3]);xlim([0 14])
title(animals(curr_line))
end


% plot(cell2mat(cellfun(@(x) x(1:4)' , all_data_stim2move_med,'UniformOutput',false))')
