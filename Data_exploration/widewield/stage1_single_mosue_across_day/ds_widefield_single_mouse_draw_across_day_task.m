clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
% U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
% {'DS007','DS010','AP019','AP021','DS011','AP022'}
surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];

boundary=0.2;
period_task=find(t_task>0&t_task<boundary);
period_kernels=find(t_kernels>0&t_kernels<boundary);

animals={'DS010'}
 % animals={'HA003','HA004','DS019','DS020'}
 % animals={'AP027','AP028','AP029','DS019','DS020','DS021'}
 % animals={'AP029'}
for curr_animal=1:length(animals)
    animal=animals{curr_animal};
% animal='DS019';
wokrflow='task';
learn_name={'non-learned','learned'};
workflow_stage={'naive','visual','auditory','mixed'};
legend_name={'-90','0','90';'4k','8k','12k';'-90','0','90';};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};
raw_data_task=load([Path   'task\' animal '_task.mat']);
 raw_data_Vpassive=load([Path   'lcr_passive\' animal '_lcr_passive.mat']);
 % raw_data_Apassive=load([Path   'hml_passive_audio\' animal '_hml_passive_audio.mat']);
raw_data_behavior=load([Path   'behavior\' animal '_behavior.mat']);

if used_data==1
    idx=cellfun(@(x) ~(isempty(x)),raw_data_task.wf_px_task);
    image_task(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_task.wf_px_task(idx),'UniformOutput',false);
    use_period=period_task;
    use_t=t_task;
else
    idx=cellfun(@(x) ~(isempty(x)|| ~(size(x,3)==1)),raw_data_task.wf_px_task_kernels);
    image_task(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{1})),x{1}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
    temp_v=raw_data_Vpassive.wf_px_kernels(4:end);
    image_Vpassive(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x)),x),temp_v(idx),'UniformOutput',false);
    % image_Apassive(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x)),x),raw_data_Apassive.wf_px_kernels(idx),'UniformOutput',false);

    use_period=period_kernels;
    use_t=t_kernels;
end
clear image_task_mean
image_task_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_task(idx),'UniformOutput',false);
buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_task(idx), 'UniformOutput', false);
% buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);                               

 image_V_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_Vpassive(idx),'UniformOutput',false);
% image_A_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_Apassive(idx),'UniformOutput',false);

all_image{curr_animal}=...
image_task_mean(find(ismember(raw_data_behavior.workflow_name,'visual size up')&...
    raw_data_behavior.rxn_l_mad_p(:,1)<0.05,2,'last'));

figure('Position',[50 50 1400 300],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
t2 = tiledlayout(5,length(image_task_mean), 'TileSpacing', 'none', 'Padding', 'none');
for curr_day=find(idx)
     nexttile(t2,curr_day)
    % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
    if size(image_task_mean{curr_day},3)==1
        imagesc(image_task_mean{curr_day})
        title([raw_data_task.workflow_day{curr_day}],[raw_data_task.workflow_type_name_merge{curr_day}  ])

    else
        imagesc(image_task_mean{curr_day}(:,:,1))
        title([raw_data_task.workflow_day{curr_day}],[raw_data_task.workflow_type_name_merge{curr_day}  ])

        axis image off;
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        colormap( ap.colormap('WG'));
        clim(0.0003 .* [0, 1]);
        nexttile(t2,length(image_task_mean)+curr_day)
        imagesc(image_task_mean{curr_day}(:,:,2))

    end
    axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    colormap( ap.colormap('WG'));
    clim(0.0005 .* [0, 1]);
    % xlim([0 213])

end



for curr_day=find(idx)
    nexttile(t2,length(image_task_mean)*2+curr_day)
        imagesc(image_V_mean{curr_day}(:,:,3))
   
        axis image off;
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        colormap( ap.colormap('WG'));
        clim(0.0003 .* [0, 1]);
end

end





