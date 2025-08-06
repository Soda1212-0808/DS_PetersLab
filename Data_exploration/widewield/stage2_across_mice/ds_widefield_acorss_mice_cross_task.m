clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];

curr_state=1;
task_boundary1=0;
task_boundary2=0.2;
state='stim';
period_kernels=find(t_kernels>task_boundary1&t_kernels<task_boundary2);

data_visual_position=cell(8,1);
data_audio=cell(8,1);
for curr_group=1:8
    if curr_group==1
        animals{curr_group} = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
    elseif curr_group==2
        animals{curr_group} = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
    elseif curr_group==3
        animals{curr_group} = {'AP018','AP020'};n1_name='visual position';n2_name='audio volume';
    elseif curr_group==4
        animals{curr_group} = {'DS006','DS013'};n1_name='audio volume';n2_name='visual position';
    elseif curr_group==5
        animals{curr_group} = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';
    elseif curr_group==6
        animals{curr_group} = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
    elseif curr_group==7
        animals{curr_group} = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
    elseif curr_group==8
        animals{curr_group} = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';

    end

    all_data_video=cell(length(animals{curr_group}),1);
    all_data_workflow_name=cell(length(animals{curr_group}),1);
    all_data_learned_day=cell(length(animals{curr_group}),1);
    matches=cell(length(animals{curr_group}),1);
  
use_period=period_kernels;
        use_t=t_kernels;

    for curr_animal=1:length(animals{curr_group})
        preload_vars = who;

        animal=animals{curr_group}{curr_animal};
        raw_data_task=load([Path  'task\' animal '_task.mat']);
        raw_data_v_passive=load([Path  'lcr_passive\' animal '_lcr_passive.mat']);

        raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

        [~, temp_idx] = ismember( raw_data_task.workflow_day,raw_data_behavior.workflow_day);
        % temp_p=raw_data_behavior.rxn_f_stat_p(temp_idx,:);

        temp_p=nan(length(raw_data_behavior.workflow_day),2);
        idx_single=ismember(raw_data_behavior.workflow_name,...
            {'visual position','visual angle','visual size up','visual opacity',...
            'audio volume','audio frequency'});

        idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');
        temp_p(idx_single,1)= raw_data_behavior.rxn_l_mad_p(idx_single,1);
        temp_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,1)...
            raw_data_behavior.rxn_l_mad_p(idx_m,2)];
        temp_p=temp_p(temp_idx,:);
        raw_data_task.learned_day=temp_p<0.01;



        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels);
        image_all_task(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{curr_state},1)),x{curr_state}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
        
        matches{curr_animal}=unique(raw_data_task.workflow_type_name_merge(idx)  ,'stable');
        all_data_video{curr_animal,1}=image_all_task(idx)';
        all_data_workflow_name{curr_animal}=raw_data_task.workflow_type_name_merge(idx);
        all_data_learned_day{curr_animal}=raw_data_task.learned_day(idx,:);





        
        clearvars('-except',preload_vars{:});

    end

      data_visual_position{curr_group} = cellfun(@(x,y,z,l)...
        x(find(strcmp(y,z(find(cellfun(@(idx) strcmp('visual position', idx),z,'UniformOutput',true))))& l(:,1)==1))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
      % temp_data2=cellfun(@(x) cat(4,x{:}),temp_data,'UniformOutput',false);
      % data_visual_position{curr_group}=cat(4,temp_data2{:});

     data_audio{curr_group} = cellfun(@(x,y,z,l)...
        x(find(ismember(y,z(find(cellfun(@(idx) ismember(idx,{'audio frequency','audio volume'}),z,'UniformOutput',true))))& l(:,1)==1))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);

end


image_max_each=cellfun(@(a) cellfun(@(b) cellfun(@(x) nanmean(max(x(:,:,period_kernels,:),[],3),4),b,'UniformOutput',false),...
    a,'UniformOutput',false),data_visual_position,'UniformOutput',false);
temp_image=cellfun(@(a)cellfun(@(b) nanmean(cat(3,b{:}),3),a,'UniformOutput',false  ),image_max_each,'UniformOutput',false)
image_v_max=cellfun(@(x) nanmean(cat(3,x{:}),3)    ,temp_image,'UniformOutput',false)



temp_trace=cellfun(@(a) cellfun(@(b)  nanmean(cat(4,b{:}),4),...
      a,'UniformOutput',false),data_visual_position,'UniformOutput',false);
temp_trace2=cellfun(@(a) cat(4,a{:}),...
      temp_trace,'UniformOutput',false);

buf1=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),temp_trace2,'UniformOutput',false) ;
trace_roi_mean=cellfun(@(x) arrayfun(@(curr_roi) ...
    permute(nanmean(nanmean(x(roi1(curr_roi).data.mask(:),:,:),1),3),[2,3,1]),...
    1:length(roi1),'UniformOutput',false),buf1,'UniformOutput',false);
trace_roi_error=cellfun(@(x) arrayfun(@(curr_roi) ...
    std(permute(mean(x(roi1(curr_roi).data.mask(:),:,:,:),1,'omitnan'),[2,3,1]),0,2,'omitmissing')...
    ./sqrt(size(buf1{1},3)), 1:length(roi1),'UniformOutput',false),buf1,'UniformOutput',false);




use_idx=[1 2  6 7 8]
used_name={'VpAv','AvVp','VoVp','VsVp','VaVp'}
figure
main_figure=tiledlayout(1,5);
for curr_group=1:5
    curr_layout = tiledlayout(main_figure, 4, 1, ...
        'TileSpacing', 'tight', 'Padding', 'tight');
    curr_layout.Layout.Tile = curr_group;  % 明确放在主 layout 的第 1 个 tile

    a1=nexttile(curr_layout)
    imagesc(image_v_max{use_idx(curr_group)})
    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.0003.*[0,1]);
    colormap(a1,ap.colormap('WB' ));
    title(used_name{curr_group})
    temp_roi=0;
for curr_roi=[7 1 6]
    temp_roi=temp_roi+1;
    a1=nexttile(curr_layout)
    ap.errorfill(t_kernels,trace_roi_mean{use_idx(curr_group)}{curr_roi},trace_roi_error{use_idx(curr_group)}{curr_roi})
    ylim(0.0001.*[-1 3])
end
end

%% auditory task
image_max_each=cellfun(@(a) cellfun(@(b) cellfun(@(x) nanmean(max(x(:,:,period_kernels,:),[],3),4),b,'UniformOutput',false),...
    a,'UniformOutput',false),data_audio,'UniformOutput',false);
temp_image=cellfun(@(a)cellfun(@(b) nanmean(cat(3,b{:}),3),a,'UniformOutput',false  ),image_max_each,'UniformOutput',false)
image_a_max=cellfun(@(x) nanmean(cat(3,x{:}),3)    ,temp_image,'UniformOutput',false)


temp_trace=cellfun(@(a) cellfun(@(b)  nanmean(cat(4,b{:}),4),...
      a,'UniformOutput',false),data_audio,'UniformOutput',false);
temp_trace2=cellfun(@(a) cat(4,a{:}),...
      temp_trace,'UniformOutput',false);

idx=cellfun(@(x) ~isempty(x),temp_trace2,'UniformOutput',true);
buf1=cell(length(temp_trace2),1);
buf1=cell(length(temp_trace2),1);
buf1=cell(length(temp_trace2),1);

buf1(idx)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),temp_trace2(idx),'UniformOutput',false) ;
trace_roi_mean(idx)=cellfun(@(x) arrayfun(@(curr_roi) ...
    permute(nanmean(nanmean(x(roi1(curr_roi).data.mask(:),:,:),1),3),[2,3,1]),...
    1:length(roi1),'UniformOutput',false),buf1(idx),'UniformOutput',false);
trace_roi_error(idx)=cellfun(@(x) arrayfun(@(curr_roi) ...
    std(permute(mean(x(roi1(curr_roi).data.mask(:),:,:,:),1,'omitnan'),[2,3,1]),0,2,'omitmissing')...
    ./sqrt(size(buf1{1},3)), 1:length(roi1),'UniformOutput',false),buf1(idx),'UniformOutput',false);




figure
used_name={'VpAv','AvVp','','AvVp','VpAf'}
use_idx=[1 2   5]

for curr_group=use_idx
  
    a1=nexttile()
    imagesc(image_a_max{curr_group})
    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.0005.*[0,1]);
    colormap(a1,ap.colormap('WR' ));
     title(used_name{curr_group})
 

end

