clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-5:30];

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);


workflow_idx=1;
all_workflow={'lcr_passive','hml_passive_audio'};
wokrflow=all_workflow{workflow_idx};

learn_name={'non-learned','learned'};
workflow_stage={'naive','visual','auditory','mixed'};
legend_name={'-90','0','90';'4k','8k','12k'};
used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};

% animals = {'AP027','AP028','AP029'};
  animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};transfer_type='v_position_to_a_volumne';

% animal='HA003';


all_data_3_peak=cell(length(animals),1);
all_data_stim=cell(length(animals),1);
all_data_image=cell(length(animals),1);
all_data_workflow_name=cell(length(animals),1);
all_data_learned_day=cell(length(animals),1);
matches=cell(length(animals),1);
use_t=[];
for curr_animal=1:length(animals)
            preload_vars = who;

    animal=animals{curr_animal};


raw_data_passive=load([Path '\mat_data\' wokrflow '\New folder\' animal '_' wokrflow '.mat']);

matches{curr_animal}=unique(raw_data_passive.workflow_type_name(1:end)  ,'stable');

if used_data==1
    idx=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px);
    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_passive.wf_px(idx),'UniformOutput',false);
    use_period=period_passive;
    use_t=t_passive;
else
    idx=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px_kernels);

    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x{1}),raw_data_passive.wf_px_kernels(idx),'UniformOutput',false);
    use_period=period_kernels;
    use_t=t_kernels;
end

image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);



all_data_3_peak{curr_animal}=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_mPFC(idx),'UniformOutput',false)');
all_data_stim{curr_animal}=cell2mat(cellfun(@(x) x(:,3),buf3_mPFC,'UniformOutput',false))';
all_data_image{curr_animal}=cellfun(@(x) x(:,:,3),image_all_mean,'UniformOutput',false);
all_data_workflow_name{curr_animal}=raw_data_passive.workflow_type_name;
all_data_learned_day{curr_animal}=raw_data_passive.learned_day;
        clearvars('-except',preload_vars{:});

end

% mPFC across day across time
n1_data = cellfun(@(x,y) x(strcmp(y,matches{1}{3}),:),all_data_stim,all_data_workflow_name,'UniformOutput',false);
n2_data = cellfun(@(x,y) x(strcmp(y,matches{1}{4}),:),all_data_stim,all_data_workflow_name,'UniformOutput',false);

% n1_data = cellfun(@(x,y) x(strcmp(y,matches{1}{3}),3),all_data_3_peak,all_data_workflow_name,'UniformOutput',false);
% n2_data = cellfun(@(x,y) x(strcmp(y,matches{1}{4}),3),all_data_3_peak,all_data_workflow_name,'UniformOutput',false);

colum=size(n1_data{1},2);
max_len_n1 = max(cellfun(@numel, n1_data))/colum;
% 2. 使用 NaN 填充较短的向量
n1_filled_pre = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), n1_data, 'UniformOutput', false);
n1_filled_post = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'post'), n1_data, 'UniformOutput', false);

max_len_n2 = max(cellfun(@numel, n2_data))/colum;
% 2. 使用 NaN 填充较短的向量
n2_filled_post = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), n2_data, 'UniformOutput', false);
n2_filled_pre = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'pre'), n2_data, 'UniformOutput', false);


% n1_n2=cell2mat(cellfun(@(x,y) [x y],  n1_filled_pre,n2_filled_post,'UniformOutput',false))'

n1_n2=cellfun(@(x,y) [x y],  n1_filled_pre,n2_filled_post,'UniformOutput',false)
n1_n2_merge=nanmean(cat(3,n1_n2{:}),3)




n1_data_image = cellfun(@(x,y) mean(cat(3,x{find(strcmp(y,matches{1}{3}),5,'last')}),3),all_data_image,all_data_workflow_name,'UniformOutput',false);
n2_data_image = cellfun(@(x,y) mean(cat(3,x{find(strcmp(y,matches{1}{4}),5,'last')}),3),all_data_image,all_data_workflow_name,'UniformOutput',false);

figure;
t=tiledlayout(2,2)
nexttile
imagesc(mean(cat(3,n1_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
clim(0.004.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;

nexttile
imagesc(mean(cat(3,n2_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
clim(0.004.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;

nexttile(t,[1,2])
imagesc(use_t,[ ], n1_n2_merge')
yline(max_len_n1+0.5)
colormap( ap.colormap('PWG'));
clim(0.003 .* [-1, 1]);
title('L-mPFC')
ylim([max_len_n1-4.5 max_len_n1+5.5] )
xlabel('time (s)')