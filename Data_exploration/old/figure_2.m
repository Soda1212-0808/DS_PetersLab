

%% load VA and AV group data
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
t_passive = surround_window_passive(1):1/ surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);


all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
Color={'B','R'};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};

data_imaging_all=cell(2,1);
data_video_all=cell(2,1);

data_all=cell(2,1);

data_associated1=cell(2,1);
data_associated2=cell(2,1);

data_peak=cell(2,1);
data_naive_peak=cell(2,1);
select_group=1:2
n1_name='';n2_name='';
use_period=[];
workflow='';
use_t=[];

for  workflow_idx=1:2
    workflow=all_workflow{workflow_idx};

    for curr_stage=select_group

        main_preload_vars = who;


        if curr_stage==1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
        elseif curr_stage==2
            animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            % % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
        elseif curr_stage==3
            animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
            % animals = {'AP027','AP028','AP029'};n1_name='visual position';n2_name='audio frequency';
        elseif curr_stage==4
            animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
        elseif curr_stage==5
            animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';
        elseif curr_stage==6
            animals = {'DS019','DS020','AP027','AP028','AP029'};n1_name='visual position';n2_name='audio frequency';
        elseif curr_stage==7
            animals = {'AP018','AP020'};n1_name='visual position';n2_name='audio volume';
        elseif curr_stage==8
            animals = {'DS006','DS013'};n1_name='audio volume';n2_name='visual position';
        elseif curr_stage==9
            animals = {'AP027','AP028','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';

        end


        used_id=1:3;

        all_data_3_peak=cell(length(animals),1);
        all_data_stim=cell(length(animals),1);
        all_data_stimr=cell(length(animals),1);
        all_data_image=cell(length(animals),1);
        all_data_video=cell(length(animals),1);

        all_data_workflow_name=cell(length(animals),1);
        all_data_learned_day=cell(length(animals),1);
        matches=cell(length(animals),1);
        use_t=[];
        use_period=[];
        for curr_animal=1:length(animals)
            preload_vars = who;

            animal=animals{curr_animal};
            raw_data_passive=load([Path '\mat_data\' workflow '\' animal '_' workflow '.mat']);
            if used_data==1

                idx=cellfun(@(x) ~(isempty(x)|~(size(x,3)==3))  ,raw_data_passive.wf_px);
                image_all(idx,1)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_passive.wf_px(idx),'UniformOutput',false);

                use_period=period_passive;
                use_t=t_passive;
            else
                idx=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px_kernels);

                image_all(idx,1)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),raw_data_passive.wf_px_kernels(idx),'UniformOutput',false);
                use_period=period_kernels;
                use_t=t_kernels;
            end
            matches{curr_animal}=unique(raw_data_passive.workflow_type_name_merge(idx)  ,'stable');




            image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
            buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
            for curr_roi= 1:length(roi1)
                buf3_roi(idx)= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);

                all_data_stim{curr_animal}{curr_roi} = arrayfun(@(col) cell2mat(cellfun(@(x) x(:, col), buf3_roi, 'UniformOutput', false))', (1:3)', 'UniformOutput', false);
            end

            % buf3_rmPFC(idx)= cellfun(@(z) permute(mean(z(roi1(9).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);
            % all_data_stimr{curr_animal} = arrayfun(@(col) cell2mat(cellfun(@(x) x(:, col), buf3_rmPFC, 'UniformOutput', false))', (1:3)', 'UniformOutput', false);


            all_data_video{curr_animal}=image_all(idx);
            all_data_image{curr_animal}=cellfun(@(x) x(:,:,used_id),image_all_mean(idx),'UniformOutput',false);
            all_data_workflow_name{curr_animal}=raw_data_passive.workflow_type_name_merge(idx);
            all_data_learned_day{curr_animal}=raw_data_passive.learned_day(idx);
            clearvars('-except',preload_vars{:});

        end



        %
        % mPFC across day across time

        % use last 5 day
        naive_idx=cellfun(@(x) any(strcmp('naive',x)),matches,'UniformOutput',true );


        naive_data =  arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x, y, z)...
            x{roi}{k}(find(strcmp(y, z(find(cellfun(@(idx) strcmp('naive', idx), z, 'UniformOutput', true)))), 3, 'first'), :), ...
            all_data_stim(naive_idx), all_data_workflow_name(naive_idx), matches(naive_idx), ...
            'UniformOutput', false),(1:length(roi1))', 'UniformOutput', false),(1:3)', 'UniformOutput', false);


        naive_data = cellfun(@(k) cellfun(@(x) cellfun(@(y) [y; NaN(max(0, 3 - size(y, 1)), size(y, 2))], x, 'UniformOutput', false),k,'UniformOutput',false),...
            naive_data, 'UniformOutput', false);

        stage1_pre_data =arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x,y,z) x{roi}{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first'),:)...
            ,all_data_stim,all_data_workflow_name,matches,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false),(1:3)', 'UniformOutput', false);

        stage1_post_data = arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x,y,z) x{roi}{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
            all_data_stim,all_data_workflow_name,matches,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false), (1:3)', 'UniformOutput', false);


        stage2_pre_data =arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x,y,z,l) x{roi}{k}( intersect(find(l==0),...
            find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first')),:),...
            all_data_stim,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false),  (1:3)', 'UniformOutput', false);

        stage2_pre_data =cellfun(@(a) cellfun(@(roi) cellfun(@(x) ifelse(isempty(x), NaN(1, length(use_t)), x), roi,'UniformOutput',false),...
            a,'UniformOutput',false),stage2_pre_data, 'UniformOutput', false);

        stage2_post_data_l =arrayfun(@(k) arrayfun(@(roi)   cellfun(@(x,y,z) x{roi}{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
            all_data_stim,all_data_workflow_name,matches,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false),  (1:3)', 'UniformOutput', false);



        % associated1_day =cellfun(@(x, y,z)  [x'  strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))],...
        %     all_data_learned_day ,all_data_workflow_name,matches,'UniformOutput',false)

        associated1_day =cellfun(@(x, y,z)  find(x' & strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),1,'first'),...
            all_data_learned_day ,all_data_workflow_name,matches,'UniformOutput',false);

        %

        stage1_associate_data= arrayfun(@(k) arrayfun(@(roi) cellfun(@(x,y)  [nan(max(3-y,0),size(x{roi}{k},2));...
            x{roi}{k}(max(1,y-2):min(y+4,size( x{roi}{k},1)),:); nan(max(y+4-size( x{roi}{k},1),0),size(x{roi}{k},2)) ],...
            all_data_stim,associated1_day,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false),(1:3)', 'UniformOutput', false);

        associated2_day =cellfun(@(x, y,z)  find(x' & strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'),...
            all_data_learned_day ,all_data_workflow_name,matches,'UniformOutput',false);


        stage2_associate_data= arrayfun(@(k) arrayfun(@(roi) cellfun(@(x,y)  [nan(max(3-y,0),size(x{roi}{k},2));...
            x{roi}{k}(max(1,y-2):min(y+4,size( x{roi}{k},1)),:); nan(max(y+4-size( x{roi}{k},1),0),size(x{roi}{k},2)) ],...
            all_data_stim,associated2_day,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false),(1:3)', 'UniformOutput', false);


        n3_name='mixed VA';
        mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
        n3_data = arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x,y,z) x{roi}{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last'),:),...
            all_data_stim(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false),...
            (1:length(roi1))', 'UniformOutput', false), (1:3)', 'UniformOutput', false);



        colum=size(stage1_post_data{1}{1}{1},2);
        max_len_n1 = max(cellfun(@numel, stage1_post_data{1}{1}))/colum;

        % 2. 使用 NaN 填充较短的向量
        stage1_post_filled_pre =  cellfun(@(k) cellfun(@(roi) cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), roi, 'UniformOutput', false),...
            k, 'UniformOutput', false),stage1_post_data, 'UniformOutput', false);
        % n1_filled_post_l = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'post'), stage1_post_data_l, 'UniformOutput', false);

        max_len_n2 = max(cellfun(@numel, stage2_post_data_l{1}{1}))/colum;
        % 2. 使用 NaN 填充较短的向量
        stage2_post_filled_post =   cellfun(@(k)  cellfun(@(roi) cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), roi, 'UniformOutput', false),...
            k, 'UniformOutput', false), stage2_post_data_l, 'UniformOutput', false);

        % n2_filled_pre_l = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'pre'), stage2_post_data_l, 'UniformOutput', false);

        max_len_n3 = max(cellfun(@numel, n3_data{1}{1}))/colum;
        n3_filled_post_l=cellfun(@(k) cellfun(@(roi) cellfun(@(x) padarray(x', [0 max_len_n3-numel(x)/colum], NaN, 'pre')', roi, 'UniformOutput', false),...
            k, 'UniformOutput', false), n3_data, 'UniformOutput', false);



        n1_n2=cellfun(@(X1,Y1,Z1,L1) cellfun(@(X,Y,Z,L)  cellfun(@(x,y,z,l) [x; y';z;l'], ...
            X,Y,Z,L,'UniformOutput',false),X1,Y1,Z1,L1,'UniformOutput',false),...
            stage1_pre_data, stage1_post_filled_pre,stage2_pre_data,stage2_post_filled_post, 'UniformOutput', false);

        n1_n2_peak=cellfun(@(q) cellfun(@(k)  cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
            q,'UniformOutput',false), n1_n2, 'UniformOutput', false);

        naive_peak=cellfun(@(q) cellfun(@(k) cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
            q,'UniformOutput',false), naive_data, 'UniformOutput', false);

        n1_n2_merge=cellfun(@(A,B,C) cellfun(@(a,b,c)  [ nanmean(cat(3,a{:}),3); nanmean(cat(3,b{:}),3) ;nanmean(cat(3,c{:}),3) ],...
            A,B,C,'UniformOutput', false),...
            naive_data,n1_n2,n3_filled_post_l, 'UniformOutput', false);



        naive_data_image=cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('naive', idx),z,'UniformOutput',true)))),3,'first')}),4),all_data_image(naive_idx),all_data_workflow_name(naive_idx),matches(naive_idx),'UniformOutput',false);
        stage1_pre_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
        stage1_post_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
        stage2_pre_data_image = cellfun(@(x,y,z,l) nanmean(cat(4,x{intersect(find(l==0),find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'))}),4),all_data_image,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
        stage2_post_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
        stage3_idx=cellfun(@(x) any(strcmp('mixed VA',x)),matches,'UniformOutput',true );
        stage3_data_image=cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('mixed VA', idx),z,'UniformOutput',true)))),3,'first')}),4),all_data_image(stage3_idx),all_data_workflow_name(stage3_idx),matches(stage3_idx),'UniformOutput',false);

        data_imaging_all{workflow_idx}{curr_stage}={mean(cat(4,naive_data_image{:}),4),mean(cat(4,stage1_pre_data_image{:}),4),...
            mean(cat(4,stage1_post_data_image{:}),4),mean(cat(4,stage2_pre_data_image{:}),4),mean(cat(4,stage2_post_data_image{:}),4)...
            ,mean(cat(4,stage3_data_image{:}),4)};



        naive_data_video=cellfun(@(x,y,z) mean(cat(5,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('naive', idx),z,'UniformOutput',true)))),3,'first')}),5),...
            all_data_video(naive_idx),all_data_workflow_name(naive_idx),matches(naive_idx),'UniformOutput',false);
        stage1_pre_data_video = cellfun(@(x,y,z) mean(cat(5,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first')}),5),...
            all_data_video,all_data_workflow_name,matches,'UniformOutput',false);
        stage1_post_data_video = cellfun(@(x,y,z) mean(cat(5,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last')}),5),...
            all_data_video,all_data_workflow_name,matches,'UniformOutput',false);
        stage2_pre_data_video = cellfun(@(x,y,z,l) nanmean(cat(5,x{intersect(find(l==0),find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'))}),5),...
            all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
        stage2_post_data_video = cellfun(@(x,y,z) mean(cat(5,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last')}),5),...
            all_data_video,all_data_workflow_name,matches,'UniformOutput',false);
        stage3_idx=cellfun(@(x) any(strcmp('mixed VA',x)),matches,'UniformOutput',true );
        stage3_data_video=cellfun(@(x,y,z) mean(cat(5,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('mixed VA', idx),z,'UniformOutput',true)))),3,'first')}),5),...
            all_data_video(stage3_idx),all_data_workflow_name(stage3_idx),matches(stage3_idx),'UniformOutput',false);

        data_video_all{workflow_idx}{curr_stage}={mean(cat(5,naive_data_video{:}),5),mean(cat(5,stage1_pre_data_video{:}),5),...
            mean(cat(5,stage1_post_data_video{:}),5),mean(cat(5,stage2_pre_data_video{:}),5),mean(cat(5,stage2_post_data_video{:}),5)...
            ,mean(cat(5,stage3_data_video{:}),5)};



        data_associated1{workflow_idx}{curr_stage}=stage1_associate_data;
        data_associated2{workflow_idx}{curr_stage}=stage2_associate_data;

        data_all{workflow_idx}{curr_stage}=n1_n2_merge;

        data_peak{workflow_idx}{curr_stage}=n1_n2_peak;

        data_naive_peak{workflow_idx}{curr_stage}=naive_peak;

        clearvars('-except',main_preload_vars{:});

    end


end

%%
%
  data_associated1_across_time=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) cellfun(@(z1) z1,...
      z,'UniformOutput',false) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_associated1,'UniformOutput',false);
  
 data_associated1_across_time=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(3,z{:}),3) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated1_across_time,'UniformOutput',false);
 
   
  data_associated1_avg=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) cellfun(@(z1)  max(z1(:,use_period),[],2),...
      z,'UniformOutput',false) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_associated1,'UniformOutput',false);
   data_associated1_avg2=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(2,z{:}),2) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated1_avg,'UniformOutput',false);
    
   data_associated1_avg3=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(2,z{:}),"all") ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated1_avg,'UniformOutput',false);

  data_associated1_std2=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) std(cat(2,z{:}),0,2,"omitmissing")/sqrt(size(cat(2,z{:}),2)) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated1_avg,'UniformOutput',false);
%
  data_associated2_across_time=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) cellfun(@(z1) z1,...
      z,'UniformOutput',false) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_associated2,'UniformOutput',false);
  
 data_associated2_across_time=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(3,z{:}),3) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated2_across_time,'UniformOutput',false);
 
   
  data_associated2_avg=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) cellfun(@(z1)  max(z1(:,use_period),[],2),...
      z,'UniformOutput',false) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_associated2,'UniformOutput',false);
   data_associated2_avg2=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(2,z{:}),2) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated2_avg,'UniformOutput',false);
    
   data_associated2_avg3=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(cat(2,z{:}),"all") ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated2_avg,'UniformOutput',false);

  data_associated2_std2=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) std(cat(2,z{:}),0,2,"omitmissing")/sqrt(size(cat(2,z{:}),2)) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a,'UniformOutput',false),data_associated2_avg,'UniformOutput',false);
  %


 n1_n2_mean_naive_across_time=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) z(1:3,:) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_all,'UniformOutput',false);
 
    n1_n2_mean_naive=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) nanmean(z,2) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_naive_peak,'UniformOutput',false);

  n1_n2_error_naive=cellfun(@(a) cellfun(@(x) cellfun(@(y) cellfun(@(z) std(z,0,2,"omitmissing")/sqrt(size(z,2)) ,y,'UniformOutput',false),...
      x,'UniformOutput',false),a(select_group),'UniformOutput',false),data_naive_peak,'UniformOutput',false);
 
%%
% figure imaging
figure('Position', [50 50 1300 400]);
t = tiledlayout(2, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
scale = 0.00015;
titles = {'naive', 's1 pre', 'post learn', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示
  title1={'p-l-mPFC','a-l-mPFC','PPC'}
colors={[ 0 0 1],[ 0.7 0.7 1];[ 1 0 0],[ 1 0.7 0.7]};
xlabel_all={'L','C','R';'4k','8k','12k'}
for curr_stage = select_group
    if curr_stage==1
        workflow_idx=1; use_stim=3;used_area=1
    elseif curr_stage==2
        workflow_idx=2; use_stim=2;used_area=3
    end

    for img_idx =[1 3]
        ax = nexttile;
        if ~isempty(data_imaging_all{workflow_idx}{curr_stage}{img_idx})
            imagesc(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim));
        else imagesc(zeros(450,426))
        end
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
        axis image;
        hold on;
        if workflow_idx==1 && img_idx==3
            boundaries1 = bwboundaries(roi1(1).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])
        elseif workflow_idx==2 && img_idx==3
            boundaries1 = bwboundaries(roi1(3).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])

        end

         title(titles{img_idx});
    end

    ax = nexttile;
    imagesc(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)-...
        fliplr(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)));
    axis image off;
    ap.wf_draw('ccf', 'black');

    clim(scale .* [-1, 1]);
    colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
     axis image;
         xlim([0 216]);  



    a2=nexttile
    % n1_n2_mean_naive
     imagesc(use_t,[],[n1_n2_mean_naive_across_time{workflow_idx}{curr_stage}{use_stim}{used_area}; ...
         data_associated1_across_time{workflow_idx}{curr_stage}{use_stim}{used_area}]);
                          colormap(a2, ap.colormap(['KW' Color{workflow_idx}]));
                          yline(3.5);yline(5.5)
        clim(scale .* [-1, 1]);
         yticks([2 4.5 8]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels({'naive','pre learn','post learn'}); % 设置对应的标签
      
        xlabel('time (s)')
        % ylabel('days')
        title(title1{workflow_idx})

        nexttile
        ap.errorfill(1:10 ,[n1_n2_mean_naive{workflow_idx}{curr_stage}{use_stim}{used_area};...
            data_associated1_avg2{workflow_idx}{curr_stage}{use_stim}{used_area}],...
            [n1_n2_error_naive{workflow_idx}{curr_stage}{use_stim}{used_area};...
            data_associated1_std2{workflow_idx}{curr_stage}{use_stim}{used_area}]...
            ,colors{workflow_idx,1},0.1,0.5);
        hold on 
        ap.errorfill(1:10 ,[n1_n2_mean_naive{workflow_idx}{curr_stage}{use_stim}{used_area+1};...
            data_associated1_avg2{workflow_idx}{curr_stage}{use_stim}{used_area+1}],...
            [n1_n2_error_naive{workflow_idx}{curr_stage}{use_stim}{used_area+1};...
            data_associated1_std2{workflow_idx}{curr_stage}{use_stim}{used_area+1}]...
            ,colors{workflow_idx,2},0.1,0.5);

        xlim([1 10]);
        xline(3.5);xline(5.5);
        ylim(scale .* [0, 1.5]);
        ylabel('df/f')
        % xlabel('days')
  xticks([2 4.5 8]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels({'naive','pre learn','post learn'}); % 设置对应的标签
      
        nexttile
        plot_peak_mean=arrayfun(@(x) mean( data_associated1_avg2{workflow_idx}{curr_stage}{x}{used_area}(end-2:end))-...
            mean(n1_n2_mean_naive{workflow_idx}{curr_stage}{x}{used_area}),1:3, 'UniformOutput', true);

        plot_peak_error=arrayfun(@(x) mean( data_associated1_std2{workflow_idx}{curr_stage}{x}{used_area}(end-2:end))-...
            mean(n1_n2_error_naive{workflow_idx}{curr_stage}{x}{used_area}),1:3, 'UniformOutput', true);

      
        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx,1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [0, 1.5 ]);
        ylabel('df/f change')
        xlabel('stim types')




end

saveas(gcf,[Path 'figures\summary\figures\figure 2'], 'jpg');

%%

% figure imaging
figure('Position', [50 50 1300 400]);
t = tiledlayout(2, 6, 'TileSpacing', 'compact', 'Padding', 'compact');
scale = 0.00015;
titles = {'naive', 's1 pre', 'post learn', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示
  title1={'p-l-mPFC','a-l-mPFC','PPC'}
colors={[ 0 0 1],[ 0.7 0.7 1];[ 1 0 0],[ 1 0.7 0.7]};
xlabel_all={'L','C','R';'4k','8k','12k'}
for curr_stage = 2
    if curr_stage==1
        workflow_idx=2; use_stim=2;used_area=3
    elseif curr_stage==2
        workflow_idx=1; use_stim=3;used_area=3
    end

    for img_idx =[1 3]
        ax = nexttile;
        if ~isempty(data_imaging_all{workflow_idx}{curr_stage}{img_idx})
            imagesc(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim));
        else imagesc(zeros(450,426))
        end
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
        axis image;
        hold on;
        if workflow_idx==1 && img_idx==3
            boundaries1 = bwboundaries(roi1(used_area).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])
        elseif workflow_idx==2 && img_idx==3
            boundaries1 = bwboundaries(roi1(used_area).data.mask  );
            plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])

        end

         title(titles{img_idx});
    end

    ax = nexttile;
    imagesc(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)-...
        fliplr(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)));
    axis image off;
    ap.wf_draw('ccf', 'black');

    clim(scale .* [-1, 1]);
    colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
     axis image;
         xlim([0 216]);  



    a2=nexttile
    % n1_n2_mean_naive
     imagesc(use_t,[],[n1_n2_mean_naive_across_time{workflow_idx}{curr_stage}{use_stim}{used_area}; ...
         data_associated2_across_time{workflow_idx}{curr_stage}{use_stim}{used_area}]);
                          colormap(a2, ap.colormap(['KW' Color{workflow_idx}]));
                          yline(3.5);yline(5.5)
        clim(scale .* [-1, 1]);
         yticks([2 4.5 8]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels({'naive','pre learn','post learn'}); % 设置对应的标签
      
        xlabel('time (s)')
        % ylabel('days')
        title(title1{workflow_idx})

        nexttile
        ap.errorfill(1:10 ,[n1_n2_mean_naive{workflow_idx}{curr_stage}{use_stim}{used_area};...
            data_associated2_avg2{workflow_idx}{curr_stage}{use_stim}{used_area}],...
            [n1_n2_error_naive{workflow_idx}{curr_stage}{use_stim}{used_area};...
            data_associated2_std2{workflow_idx}{curr_stage}{use_stim}{used_area}]...
            ,colors{workflow_idx,1},0.1,0.5);
        hold on 
        ap.errorfill(1:10 ,[n1_n2_mean_naive{workflow_idx}{curr_stage}{use_stim}{used_area+1};...
            data_associated2_avg2{workflow_idx}{curr_stage}{use_stim}{used_area+1}],...
            [n1_n2_error_naive{workflow_idx}{curr_stage}{use_stim}{used_area+1};...
            data_associated2_std2{workflow_idx}{curr_stage}{use_stim}{used_area+1}]...
            ,colors{workflow_idx,2},0.1,0.5);

        xlim([1 10]);
        xline(3.5);xline(5.5);
        ylim(scale .* [0, 1.5]);
        ylabel('df/f')
        % xlabel('days')
  xticks([2 4.5 8]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels({'naive','pre learn','post learn'}); % 设置对应的标签
      
        nexttile
        plot_peak_mean=arrayfun(@(x) mean( data_associated2_avg2{workflow_idx}{curr_stage}{x}{used_area}(end-2:end))-...
            mean(n1_n2_mean_naive{workflow_idx}{curr_stage}{x}{used_area}),1:3, 'UniformOutput', true);

        plot_peak_error=arrayfun(@(x) mean( data_associated2_std2{workflow_idx}{curr_stage}{x}{used_area}(end-2:end))-...
            mean(n1_n2_error_naive{workflow_idx}{curr_stage}{x}{used_area}),1:3, 'UniformOutput', true);

      
        errorbar( 1:3 ,plot_peak_mean,plot_peak_error,'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{workflow_idx,1})
        xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(xlabel_all(workflow_idx,:)); % 设置对应的标签
        xlim([0.5 3.5])
        ylim(scale .* [0, 1.5 ]);
        ylabel('df/f change')
        xlabel('stim types')




end









%% hot spot
buffer_1=data_imaging_all{1}{1}{3}(:,:,3);
buffer_2=data_imaging_all{2}{2}{3}(:,:,2);


figure('Position',[50 50 500 500]);
imagesc(buffer_1);
axis image off;
% ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WG'));
clim(scale .* [0, 1]);
frame1 = getframe(gca);
img_data1 =im2double( imresize(frame1.cdata, size(buffer_1)));
% saveas(gcf,[Path 'figures\use_all_trials\merged_image_visual11' ], 'jpg');


figure('Position',[50 50 500 500]);
imagesc(buffer_2);
axis image off;
% ap.wf_draw('ccf', 'black');
colormap( ap.colormap('WR'));
clim(scale .* [0, 1]);
frame2 = getframe(gca);
img_data2 =im2double( imresize(frame2.cdata, size(buffer_1)));
% saveas(gcf,[Path 'figures\use_all_trials\merged_image_audio11' ], 'jpg');


result_p = min(img_data1, img_data2);

figure('Position',[50 50 1300 1000]);
a1=nexttile
imagesc(buffer_1);
axis image off;
ap.wf_draw('ccf', 'black');
colormap( a1,ap.colormap('WG'));
clim(scale .* [0, 1]);
colorbar('southoutside')
title('visual passive')

a2=nexttile
imagesc(buffer_2);
axis image off;
ap.wf_draw('ccf', 'black');
colormap( a2,ap.colormap('WR'));
clim(scale .* [0, 1]);
colorbar('southoutside')
title('auditory passive')

nexttile
imshow([result_p]);
ap.wf_draw('ccf', 'black');
title('merged passive')
% sgtitle([ group_name ' 0-' num2str(passive_boundary) 's'])
% imwrite(result_p, [Path 'figures\use_all_trials\merged_image_audio_visual'   group_name ' 0-' num2str(1000*passive_boundary) 'ms'  '.jpg' ]); % 保存图像为 JPG 文件
%%

boundaries1 = bwboundaries(roi1(1).data.mask  );

a4=nexttile
data_audioB=buffer_1;
mean_scale=0.7*max(data_audioB(roi1(1).data.mask==1))
% data_audioB(data_audioB>mean(data_audioB(find(roi1(5).data.mask==1)))&roi1(5).data.mask==1)=1;
data_audioB(data_audioB>mean_scale&roi1(1).data.mask==1)=1;
data_audioB(data_audioB<1)=0;
imagesc(data_audioB)
axis image off;
ap.wf_draw('ccf','black');
clim(max(abs(clim)).*[0,1]);colormap(a4,ap.colormap('WG'));
hold on;plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1))


boundaries2 = bwboundaries(roi1(3).data.mask  );

a5=nexttile
data_visualB=buffer_2;
mean_scale=0.7*max(data_visualB(roi1(3).data.mask==1))
% data_visualB(data_visualB>mean(data_visualB(find(roi1(5).data.mask==1)))&roi1(5).data.mask  ==1)=1;
data_visualB(data_visualB>mean_scale&roi1(3).data.mask  ==1)=1;
data_visualB(data_visualB<1)=0;
imagesc(data_visualB)
axis image off;
ap.wf_draw('ccf','black');
clim(0.0001*max(abs(clim)).*[0,1]);colormap(a5,ap.colormap('WR'));
hold on;plot(boundaries2{1, 1} (:,2),boundaries2{1, 1} (:,1))

a6=nexttile
imagesc((data_audioB*-1+data_visualB*2))
axis image off;
ap.wf_draw('ccf','black');
clim([-2,2]);colormap(a6,ap.colormap('GWR'));
hold on;plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1))
hold on;plot(boundaries2{1, 1} (:,2),boundaries2{1, 1} (:,1))



% 将所有边界坐标转换为一个单一的二维数组
