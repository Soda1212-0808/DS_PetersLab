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
t_kernels=1/surround_samplerate*[-10:30];
 
passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);



all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
Color={'B','R'};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};

data_imaging_all=cell(2,1);
data_video_all=cell(2,1);

data_all_l=cell(2,1);
data_all_r=cell(2,1);

data_peak_l=cell(2,1);
data_naive_peak_l=cell(2,1);
data_peak_r=cell(2,1);
data_naive_peak_r=cell(2,1);
select_group=1:2
for curr_group=select_group

    for  workflow_idx=1:2;
    wokrflow=all_workflow{workflow_idx};

if curr_group==1
 animals = {'DS007','DS010','AP019','AP021','DS011'};n1_name='visual position';n2_name='audio volume';
elseif curr_group==2
 animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
elseif curr_group==3
 animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
% animals = {'AP027','AP028','AP029'};n1_name='visual position';n2_name='audio frequency';
elseif curr_group==4
 animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
elseif curr_group==5
 animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';
 elseif curr_group==6
 animals = {'DS019','DS020','AP027','AP028','AP029'};n1_name='visual position';n2_name='audio frequency';
 elseif curr_group==7
 animals = {'AP018','AP020'};n1_name='visual position';n2_name='audio volume';
 elseif curr_group==8
 animals = {'DS006','DS013'};n1_name='audio volume';n2_name='visual position';
 elseif curr_group==9
 animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';

end



% if workflow_idx==1|workflow_idx==3
%     used_id=3;
% elseif workflow_idx==2
%     if strcmp(n1_name,'audio volume')||strcmp(n2_name,'audio volume')
%         used_id=2;
%     elseif strcmp(n1_name,'audio frequency')||strcmp(n2_name,'audio frequency')
%         used_id=3;
%     end
% 
% end
 used_id=1:3

all_data_3_peak=cell(length(animals),1);
all_data_stiml=cell(length(animals),1);
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
    raw_data_passive=load([Path '\mat_data\' wokrflow '\' animal '_' wokrflow '.mat']);
    if used_data==1
        % idx=cellfun(@(x) ~(isempty(x)|~(size(x,3)==3))  ,raw_data_passive.wf_px_01s);
        % image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_passive.wf_px_01s(idx),'UniformOutput',false);

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
    for curr_roi= 1:6
    buf3_roi(idx)= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);

    all_data_stiml{curr_animal}{curr_roi} = arrayfun(@(col) cell2mat(cellfun(@(x) x(:, col), buf3_roi, 'UniformOutput', false))', (1:3)', 'UniformOutput', false);
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


naive_data_l =  arrayfun(@(k) arrayfun(@(roi)  cellfun(@(x, y, z)...
    x{roi}{k}(find(strcmp(y, z(find(cellfun(@(idx) strcmp('naive', idx), z, 'UniformOutput', true)))), 3, 'first'), :), ...
    all_data_stiml(naive_idx), all_data_workflow_name(naive_idx), matches(naive_idx), ...
    'UniformOutput', false),(1:6)', 'UniformOutput', false),(1:3)', 'UniformOutput', false);


naive_data_l = cellfun(@(k) cellfun(@(x) [x; NaN(max(0, 3 - size(x, 1)), size(x, 2))], k, 'UniformOutput', false),...
    naive_data_l, 'UniformOutput', false);


naive_data_r =  arrayfun(@(k) cellfun(@(x, y, z)...
    x{k}(find(strcmp(y, z(find(cellfun(@(idx) strcmp('naive', idx), z, 'UniformOutput', true)))), 3, 'first'), :), ...
    all_data_stimr(naive_idx), all_data_workflow_name(naive_idx), matches(naive_idx), ...
    'UniformOutput', false),(1:3)', 'UniformOutput', false);


naive_data_r= cellfun(@(k) cellfun(@(x) [x; NaN(max(0, 3 - size(x, 1)), size(x, 2))], k, 'UniformOutput', false),...
    naive_data_r, 'UniformOutput', false);




stage1_pre_data_l =arrayfun(@(k)  cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first'),:)...
    ,all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false),...
    (1:3)', 'UniformOutput', false);


stage1_post_data_l = arrayfun(@(k) cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
    all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false),...
    (1:3)', 'UniformOutput', false);

% stage1_post_data_l = cellfun(@(x,y,z,a) x(find((strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))) & (a==1)' ),5,'first'),:),all_data_stiml,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);

stage2_pre_data_l =arrayfun(@(k)  cellfun(@(x,y,z,l) x{k}( intersect(find(l==0),...
    find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first')),:),...
    all_data_stiml,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false),...
        (1:3)', 'UniformOutput', false);

stage2_pre_data_l =cellfun(@(a) cellfun(@(x) ifelse(isempty(x), NaN(1, length(use_t)), x), a,'UniformOutput',false),stage2_pre_data_l, 'UniformOutput', false);



stage2_post_data_l =arrayfun(@(k)  cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
    all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false),...
                (1:3)', 'UniformOutput', false);


stage1_pre_data_r =arrayfun(@(k)  cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first'),:)...
    ,all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false),...
    (1:3)', 'UniformOutput', false);

stage1_post_data_r = arrayfun(@(k) cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
    all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false),...
    (1:3)', 'UniformOutput', false);

% stage1_post_data_l = cellfun(@(x,y,z,a) x(find((strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))) & (a==1)' ),5,'first'),:),all_data_stiml,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);

stage2_pre_data_r =arrayfun(@(k)  cellfun(@(x,y,z,l) x{k}( intersect(find(l==0),...
    find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first')),:),...
    all_data_stimr,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false),...
        (1:3)', 'UniformOutput', false);

stage2_pre_data_r =cellfun(@(a) cellfun(@(x) ifelse(isempty(x), NaN(1, length(use_t)), x), a,'UniformOutput',false),stage2_pre_data_r, 'UniformOutput', false);


stage2_post_data_r =arrayfun(@(k)  cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last'),:),...
    all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false),...
                (1:3)', 'UniformOutput', false);



n3_name='mixed VA';
mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
n3_data_l = arrayfun(@(k) cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last'),:),...
    all_data_stiml(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false),...
                    (1:3)', 'UniformOutput', false);

n3_data_r = arrayfun(@(k) cellfun(@(x,y,z) x{k}(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last'),:),...
    all_data_stimr(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false),...
                    (1:3)', 'UniformOutput', false);




colum=size(stage1_post_data_l{1}{1},2);
max_len_n1 = max(cellfun(@numel, stage1_post_data_l{1}))/colum;

% 2. 使用 NaN 填充较短的向量
stage1_post_filled_pre_l =  cellfun(@(k)  cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), k, 'UniformOutput', false),...
    stage1_post_data_l, 'UniformOutput', false);
% n1_filled_post_l = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'post'), stage1_post_data_l, 'UniformOutput', false);
stage1_post_filled_pre_r =  cellfun(@(k) cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), k, 'UniformOutput', false),...
   stage1_post_data_r, 'UniformOutput', false);


max_len_n2 = max(cellfun(@numel, stage2_post_data_l{1}))/colum;
% 2. 使用 NaN 填充较短的向量
stage2_post_filled_post_l =   cellfun(@(k)  cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), k, 'UniformOutput', false),...
        stage2_post_data_l, 'UniformOutput', false);

% n2_filled_pre_l = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'pre'), stage2_post_data_l, 'UniformOutput', false);
stage2_post_filled_post_r = cellfun(@(k)   cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), k, 'UniformOutput', false),...
        stage2_post_data_r, 'UniformOutput', false);


max_len_n3 = max(cellfun(@numel, n3_data_l{1}))/colum;
n3_filled_post_l=cellfun(@(k) cellfun(@(x) padarray(x', [0 max_len_n3-numel(x)/colum], NaN, 'pre')', k, 'UniformOutput', false),...
        n3_data_l, 'UniformOutput', false);

n3_filled_post_r=cellfun(@(k) cellfun(@(x) padarray(x', [0 max_len_n3-numel(x)/colum], NaN, 'pre')', k, 'UniformOutput', false),...
        n3_data_r, 'UniformOutput', false);




n1_n2_l=cellfun(@(X,Y,Z,L)  cellfun(@(x,y,z,l) [x; y';z;l'], ...
    X,Y,Z,L,'UniformOutput',false),...
    stage1_pre_data_l, stage1_post_filled_pre_l,stage2_pre_data_l,stage2_post_filled_post_l, 'UniformOutput', false);



n1_n2_peak_l=cellfun(@(k)  cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
      n1_n2_l, 'UniformOutput', false);

naive_peak_l=cellfun(@(k) cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
        naive_data_l, 'UniformOutput', false);


n1_n2_merge_l=cellfun(@(a,b,c)  [ nanmean(cat(3,a{:}),3); nanmean(cat(3,b{:}),3) ;nanmean(cat(3,c{:}),3) ],...
           naive_data_l,n1_n2_l,n3_filled_post_l, 'UniformOutput', false);


n1_n2_r=cellfun(@(X,Y,Z,L)  cellfun(@(x,y,z,l) [x; y';z;l'], ...
    X,Y,Z,L,'UniformOutput',false),...
    stage1_pre_data_r, stage1_post_filled_pre_r,stage2_pre_data_r,stage2_post_filled_post_r, 'UniformOutput', false);



n1_n2_peak_r=cellfun(@(k)  cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
      n1_n2_r, 'UniformOutput', false);

naive_peak_r=cellfun(@(k) cell2mat(cellfun(@(x) max(x(:,use_period),[],2),k,'UniformOutput',false)'),...
        naive_data_r, 'UniformOutput', false);


n1_n2_merge_r=cellfun(@(a,b,c)  [ nanmean(cat(3,a{:}),3); nanmean(cat(3,b{:}),3) ;nanmean(cat(3,c{:}),3) ],...
           naive_data_r,n1_n2_r,n3_filled_post_r, 'UniformOutput', false);





naive_data_image=cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('naive', idx),z,'UniformOutput',true)))),3,'first')}),4),all_data_image(naive_idx),all_data_workflow_name(naive_idx),matches(naive_idx),'UniformOutput',false);
stage1_pre_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
stage1_post_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
stage2_pre_data_image = cellfun(@(x,y,z,l) nanmean(cat(4,x{intersect(find(l==0),find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'))}),4),all_data_image,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
stage2_post_data_image = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
stage3_idx=cellfun(@(x) any(strcmp('mixed VA',x)),matches,'UniformOutput',true );
stage3_data_image=cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp('mixed VA', idx),z,'UniformOutput',true)))),3,'first')}),4),all_data_image(stage3_idx),all_data_workflow_name(stage3_idx),matches(stage3_idx),'UniformOutput',false);

data_imaging_all{workflow_idx}{curr_group}={mean(cat(4,naive_data_image{:}),4),mean(cat(4,stage1_pre_data_image{:}),4),...
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

data_video_all{workflow_idx}{curr_group}={mean(cat(5,naive_data_video{:}),5),mean(cat(5,stage1_pre_data_video{:}),5),...
    mean(cat(5,stage1_post_data_video{:}),5),mean(cat(5,stage2_pre_data_video{:}),5),mean(cat(5,stage2_post_data_video{:}),5)...
    ,mean(cat(5,stage3_data_video{:}),5)};



    
data_all_l{workflow_idx}{curr_group}=n1_n2_merge_l;
data_all_r{workflow_idx}{curr_group}=n1_n2_merge_r;

data_peak_l{workflow_idx}{curr_group}=n1_n2_peak_l;
data_peak_r{workflow_idx}{curr_group}=n1_n2_peak_r;

data_naive_peak_r{workflow_idx}{curr_group}=naive_peak_r;
data_naive_peak_l{workflow_idx}{curr_group}=naive_peak_l;
    end


end

%%
curr_video=data_video_all{2}{1}{5};
ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
clim(0.5*max(curr_video,[],'all').*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
% set(gcf,'name',sprintf('%s %s',animal,raw_data_lcr1.workflow_day{rec_day}));

%%
% figure imaging
figure('Position', [50 50 500 1500]);
t = tiledlayout(12, 5, 'TileSpacing', 'none', 'Padding', 'none');  
scale = 0.00015;
titles = {'naive', 's1 pre', 's1 post', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示

for curr_group = select_group
    for workflow_idx = 1:2
        for use_stim=1:3
        for img_idx = 1:5
            ax = nexttile;
            if ~isempty(data_imaging_all{workflow_idx}{curr_group}{img_idx})
            imagesc(data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim));
            else imagesc(zeros(450,426))
            end
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
            axis image;
            
            % 仅在第一行显示标题
            if curr_group == 1 && workflow_idx == 1&& use_stim == 1
                title(titles{img_idx});
            end
            
            % 仅在后两行（curr_group == 2）的最后一列加 colorbar
            if curr_group == 2 && img_idx == 5&& use_stim == 3
                colorbar;
            end
        end
        end
    end
end
  saveas(gcf,[Path 'figures\summary\different_task_passive\ ' n1_name ' to ' n2_name ' imaging mpfc' strrep(wokrflow,'_',' ') ], 'jpg');
  % saveas(gcf,[Path 'figures\summary\different_task_passive\ ' n1_name ' to ' n2_name ' non learner imaging mpfc' strrep(wokrflow,'_',' ') ], 'jpg');

%% plot

figure('Position', [50 50 1800 800]);
t = tiledlayout(4, 12, 'TileSpacing', 'tight', 'Padding', 'compact');  
for curr_group = select_group

    for workflow_idx = 1:2
            for use_stim=1:3

 a1=nexttile(t,[1,2])
% nexttile
imagesc(use_t,[ ], data_all_l{workflow_idx}{curr_group}{use_stim})
yline(3.5)
yline(5.5)
yline(5+max_len_n1+0.5)
yline(6+max_len_n1+0.5)
yline(6+max_len_n1+max_len_n2+0.5)
xline(passive_boundary,'Color',[1 0.5 0.5]);
xline(0,'Color',[1 0.5 0.5])

colormap( a1, ap.colormap(['KW' Color{workflow_idx}]));
clim(0.0001 .* [-1, 1]);
title('L-mPFC')
xlabel('time (s)')
colorbar
ylim([0.5 16.5])
yticks([2 4.5 8, 11 ,14 18]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post','mix'}); % 设置对应的标签

% 
n1_n2_mean_naive= mean(data_naive_peak_l{workflow_idx}{curr_group}{use_stim},2,"omitnan") ;
n1_n2_mean=mean(data_peak_l{workflow_idx}{curr_group}{use_stim},2,"omitnan");

n1_n2_error_naive= std(data_naive_peak_l{workflow_idx}{curr_group}{use_stim}',1,"omitnan")/sqrt(size(data_naive_peak_l{workflow_idx}{curr_group}{use_stim},2)) ;
n1_n2_error= std(data_peak_l{workflow_idx}{curr_group}{use_stim}',1,"omitnan")/sqrt(size(data_peak_l{workflow_idx}{curr_group}{use_stim},2));

nexttile
hold on
length_naive=sum(~isnan(n1_n2_mean_naive));
if length_naive==1
    ap.errorfill(0.5:1.5,[n1_n2_mean_naive(~isnan(n1_n2_mean_naive)) n1_n2_mean_naive(~isnan(n1_n2_mean_naive))], [n1_n2_error_naive n1_n2_error_naive] ,[0 0 0],0.1,0.5);

else
ap.errorfill(1:length_naive,n1_n2_mean_naive(1:length_naive),  n1_n2_error_naive(1:length_naive),[0 0 0],0.1,0.5);
end

ap.errorfill(4:5,n1_n2_mean(1:2),  n1_n2_error(1:2),[0 0 0],0.1,0.5);
ap.errorfill(6:10,n1_n2_mean(3:7),  n1_n2_error(3:7),[0 0 0],0.1,0.5);
ap.errorfill(10.5:11.5,[n1_n2_mean(8) n1_n2_mean(8)], [ n1_n2_error(8) n1_n2_error(8)],[0 0 0],0.1,0.5);
ap.errorfill(12:16,n1_n2_mean(9:13),  n1_n2_error(9:13),[0 0 0],0.1,0.5);
ylim(0.00015*[0 1])
xticks([2 4.5 8, 11 ,14]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f change')
%
nexttile
errorbar( 1:5 ,[ mean(n1_n2_mean_naive) mean(n1_n2_mean(1:2)) mean(n1_n2_mean(3:7)) mean(n1_n2_mean(8)) mean(n1_n2_mean(9:13)) ],...
    [mean(n1_n2_error_naive) mean(n1_n2_error(1:2)) mean(n1_n2_error(3:7)) mean(n1_n2_error(8)) mean(n1_n2_error(9:13)) ],'k.','MarkerSize',20, 'LineWidth', 2,'Color','k');
 xlim([0.5 5.5])
ylim(0.00015*[0 1])
xticks([1 2 3 4 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f peak')
%     title ('visual passive')
box off
% sgtitle({[n1_name ' to ' n2_name];['in ' strrep(wokrflow,'_',' ')]})
    end
end
end
 saveas(gcf,[Path 'figures\summary\different_task_passive\ ' n1_name ' to ' n2_name ' plot mpfc' strrep(wokrflow,'_',' ') ], 'jpg');
  % saveas(gcf,[Path 'figures\summary\different_task_passive\ ' n1_name ' to ' n2_name ' non learner plot mpfc' strrep(wokrflow,'_',' ') ], 'jpg');


%%
% asymmetry
figure('Position', [50 50 300 1500]);
t = tiledlayout(12, 5, 'TileSpacing', 'none', 'Padding', 'none');  

scale = 0.0001;
titles = {'naive', 's1 pre', 's1 post', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示

for curr_group = select_group
    for workflow_idx = 1:2
                for use_stim=1:3

        for img_idx = 1:5
            ax = nexttile;
            if ~isempty(data_imaging_all{workflow_idx}{curr_group}{img_idx})
            imagesc(data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim)-fliplr(data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim)));
            else imagesc(zeros(450,426));
            end
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
            axis image;
            xlim([0 216])

            % 仅在第一行显示标题
            if curr_group == 1 && workflow_idx == 1&& use_stim == 1
                title(titles{img_idx});
            end
            
            % 仅在后两行（curr_group == 2）的最后一列加 colorbar
            if curr_group == 2 && img_idx == 5&& use_stim == 3
                colorbar;
            end
        end
                end
    end
end
saveas(gcf,[Path 'figures\summary\different_task_passive\asymmtery imaging mpfc activity in ' n1_name ' to ' n2_name 'in ' strrep(wokrflow,'_',' ') ], 'jpg');

% saveas(gcf,[Path 'figures\summary\different_task_passive\non learner asymmtery imaging mpfc activity in ' n1_name ' to ' n2_name 'in ' strrep(wokrflow,'_',' ') ], 'jpg');



%%
figure('Position', [50 50 1800 800]);
t = tiledlayout(4, 12, 'TileSpacing', 'tight', 'Padding', 'compact'); 

for curr_group = select_group
    for workflow_idx = 1:2
                for use_stim=1:3

 a1=nexttile(t,[1,2])
% nexttile
imagesc(use_t,[ ], data_all_l{workflow_idx}{curr_group}{use_stim}-data_all_r{workflow_idx}{curr_group}{use_stim})
yline(3.5)
yline(5.5)
yline(5+max_len_n1+0.5)
yline(6+max_len_n1+0.5)
yline(6+max_len_n1+max_len_n2+0.5)
xline(passive_boundary,'Color',[1 0.5 0.5]);
xline(0,'Color',[1 0.5 0.5])

colormap( a1, ap.colormap(['KW' Color{workflow_idx}]));
clim(0.0001 .* [-1, 1]);
title('L-mPFC')
xlabel('time (s)')
colorbar
ylim([0.5 16.5])
yticks([2 4.5 8, 11 ,14 18]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
yticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post','mix'}); % 设置对应的标签




n1_n2_mean_naive= mean(data_naive_peak_l{workflow_idx}{curr_group}{use_stim}-data_naive_peak_r{workflow_idx}{curr_group}{use_stim},2,"omitnan") ;
n1_n2_mean=mean(data_peak_l{workflow_idx}{curr_group}{use_stim}-data_peak_r{workflow_idx}{curr_group}{use_stim},2,"omitnan");

n1_n2_error_naive= std(data_naive_peak_l{workflow_idx}{curr_group}{use_stim}'-data_naive_peak_r{workflow_idx}{curr_group}{use_stim}',1,"omitnan")/...
    sqrt(size(data_naive_peak_l{workflow_idx}{curr_group}{use_stim},2)) ;
n1_n2_error= std(data_peak_l{workflow_idx}{curr_group}{use_stim}'-data_peak_r{workflow_idx}{curr_group}{use_stim}',1,"omitnan")/sqrt(size(data_peak_l{workflow_idx}{curr_group}{use_stim},2));

nexttile
hold on
length_naive=sum(~isnan(n1_n2_mean_naive));
if length_naive==1
    ap.errorfill(0.5:1.5,[n1_n2_mean_naive(~isnan(n1_n2_mean_naive)) n1_n2_mean_naive(~isnan(n1_n2_mean_naive))], [n1_n2_error_naive n1_n2_error_naive] ,[0 0 0],0.1,0.5);

else
ap.errorfill(1:length_naive,n1_n2_mean_naive(1:length_naive),  n1_n2_error_naive(1:length_naive),[0 0 0],0.1,0.5);
end

ap.errorfill(4:5,n1_n2_mean(1:2),  n1_n2_error(1:2),[0 0 0],0.1,0.5);
ap.errorfill(6:10,n1_n2_mean(3:7),  n1_n2_error(3:7),[0 0 0],0.1,0.5);
ap.errorfill(10.5:11.5,[n1_n2_mean(8) n1_n2_mean(8)], [ n1_n2_error(8) n1_n2_error(8)],[0 0 0],0.1,0.5);
ap.errorfill(12:16,n1_n2_mean(9:13),  n1_n2_error(9:13),[0 0 0],0.1,0.5);


ylim(0.0001*[-0.05 1])
xticks([2 4.5 8, 11 ,14]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f change')
%
%
nexttile
errorbar( 1:5 ,[ mean(n1_n2_mean_naive) mean(n1_n2_mean(1:2)) mean(n1_n2_mean(3:7)) mean(n1_n2_mean(8)) mean(n1_n2_mean(9:13)) ],...
    [mean(n1_n2_error_naive) mean(n1_n2_error(1:2)) mean(n1_n2_error(3:7)) mean(n1_n2_error(8)) mean(n1_n2_error(9:13)) ],'k.','MarkerSize',20, 'LineWidth', 2,'Color','k');
 xlim([0.5 5.5])
ylim(0.00015*[0 1])
xticks([1 2 3 4 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'naive' ,'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f peak')
%     title ('visual passive')
box off

sgtitle({[n1_name ' to ' n2_name];['in ' strrep(wokrflow,'_',' ')]})
    end
end
end
saveas(gcf,[Path 'figures\summary\different_task_passive\asymmetry plot mpfc activity in ' n1_name ' to ' n2_name 'in ' strrep(wokrflow,'_',' ') ], 'jpg');
% saveas(gcf,[Path 'figures\summary\different_task_passive\non learner asymmetry plot mpfc activity in ' n1_name ' to ' n2_name 'in ' strrep(wokrflow,'_',' ') ], 'jpg');

%% 
% mixed task

figure('Position', [50 50 700 850]);
t = tiledlayout(5, 2, 'TileSpacing', 'tight', 'Padding', 'none');  


scale = 0.00015;
titles = {'naive', 's1 pre', 's1 post', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示
for use_stim=1:3

    for curr_group = select_group

        for workflow_idx = 1:2

            for img_idx = 6

                ax = nexttile;
                imagesc(data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim));
                axis image off;
                ap.wf_draw('ccf', 'black');
                clim(scale .* [-1, 1]);
                colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
                axis image;

                % 仅在第一行显示标题
                % if curr_group == 1 && workflow_idx == 1
                %     title(titles{img_idx});
                % end

                % 仅在后两行（curr_group == 2）的最后一列加 colorbar
                if curr_group == 2 && img_idx == 6
                    colorbar;
                end
            end
        end
    end
end

for curr_group = select_group
    
 for workflow_idx = 1:2

 nexttile(t)
% nexttile
buffer_plot=data_all_l{workflow_idx}{curr_group};
plot_mean=cellfun(@(x) mean(x(17:19,:),1),buffer_plot,'UniformOutput',false);
plot_error= cellfun(@(x) std(x(17:19,:))/sqrt(3),buffer_plot,'UniformOutput',false);
plot_peak_mean{(curr_group-min(select_group))*2+workflow_idx}=cellfun(@(x) mean(max(x(17:19,use_period),[],2),1),buffer_plot,'UniformOutput',true);
plot_peak_error{(curr_group-min(select_group))*2+workflow_idx}=cellfun(@(x) std(max(x(17:19,use_period),[],2),1)/sqrt(3),buffer_plot,'UniformOutput',true)';

cellfun(@(x,y) ap.errorfill(use_t,x,  y,Color{workflow_idx},0.1,0.5),plot_mean,plot_error,'UniformOutput',false);

xline(passive_boundary,'Color',[0.5 0.5 0.5]);
xline(0,'Color',[0.5 0.5 0.5])
ylim(0.0002 .* [-0.5, 1]);
% title('L-mPFC')
xlabel('time (s)')

ylabel('df/f')


    end
end

x_labels={'VA-V' ,'VA-A','AV-V','AV-A'}; % 设置对应的标签
colors={'b','r','b','r'}
for ii=1:4
nexttile
  errorbar( 1:3 ,plot_peak_mean{ii},plot_peak_error{ii},'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{ii})
  ylabel('df/f peak')
   xlim([0.5 3.5])
ylim(0.0002*[-0.05 1])
box off

xlabel(x_labels{ii})
end


% xticks([1 2 3 4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
%     title ('visual passive')
sgtitle({[n1_name ' to ' n2_name];['in ' strrep(wokrflow,'_',' ')]})
 saveas(gcf,[Path 'figures\summary\different_task_passive\ plot mpfc activity in ' n1_name ' to ' n2_name 'in mxied of' strrep(wokrflow,'_',' ') ], 'jpg');
 % saveas(gcf,[Path 'figures\summary\different_task_passive\ non learner plot mpfc activity in ' n1_name ' to ' n2_name 'in mxied of' strrep(wokrflow,'_',' ') ], 'jpg');

%%
% asymmetry

% mixed task

figure('Position', [50 50 700 850]);
t = tiledlayout(5, 2, 'TileSpacing', 'tight', 'Padding', 'none');  

% t = tiledlayout(4, 5, 'TileSpacing', 'compact', 'Padding', 'compact');  
% 'TileSpacing' 控制网格间距，'compact' 使行与行之间的空隙变小
% 'Padding' 控制整个figure内边距，'compact' 使边距缩小

scale = 0.00015;
titles = {'naive', 's1 pre', 's1 post', 's2 pre', 's2 post','mixed'}; % 仅在第一行显示
for use_stim=1:3

    for curr_group = select_group

        for workflow_idx = 1:2

            for img_idx = 6

                ax = nexttile;
                imagesc(data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim)-fliplr( data_imaging_all{workflow_idx}{curr_group}{img_idx}(:,:,use_stim)));
                axis image off;
                ap.wf_draw('ccf', 'black');
                clim(scale .* [-1, 1]);
                colormap(ax, ap.colormap(['KW' Color{workflow_idx}]));
                axis image;
                xlim([0 216])

                % 仅在第一行显示标题
                % if curr_group == 1 && workflow_idx == 1
                %     title(titles{img_idx});
                % end

                % 仅在后两行（curr_group == 2）的最后一列加 colorbar
                if curr_group == 2 && img_idx == 6
                    colorbar;
                end
            end
        end
    end
end
 
for curr_group = select_group
    for workflow_idx = 1:2

 nexttile(t)
% nexttile
buffer_plot=cellfun(@(x,y) x-y,data_all_l{workflow_idx}{curr_group},data_all_r{workflow_idx}{curr_group},'UniformOutput',false);
plot_mean=cellfun(@(x) mean(x(17:19,:),1),buffer_plot,'UniformOutput',false);
plot_error= cellfun(@(x) std(x(17:19,:))/sqrt(3),buffer_plot,'UniformOutput',false);
plot_peak_mean{(curr_group-1)*2+workflow_idx}=cellfun(@(x) mean(max(x(17:19,use_period),[],2),1),buffer_plot,'UniformOutput',true);
plot_peak_error{(curr_group-1)*2+workflow_idx}=cellfun(@(x) std(max(x(17:19,use_period),[],2),1)/sqrt(3),buffer_plot,'UniformOutput',true)';

cellfun(@(x,y) ap.errorfill(use_t,x,  y,Color{workflow_idx},0.1,0.5),plot_mean,plot_error,'UniformOutput',false);

xline(passive_boundary,'Color',[0.5 0.5 0.5]);
xline(0,'Color',[0.5 0.5 0.5])
ylim(0.0002 .* [-0.5, 1]);
% title('L-mPFC')
xlabel('time (s)')

ylabel('df/f')


    end
end

x_labels={'VA-V' ,'VA-A','AV-V','AV-A'}; % 设置对应的标签
colors={'b','r','b','r'}
for ii=1:4
nexttile
  errorbar( 1:3 ,plot_peak_mean{ii},plot_peak_error{ii},'k.','MarkerSize',20, 'LineWidth', 2,'Color',colors{ii})
  ylabel('df/f peak')
   xlim([0.5 3.5])
ylim(0.0002*[-0.05 1])
box off

xlabel(x_labels{ii})
end


% xticks([1 2 3 4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
%     title ('visual passive')
sgtitle({[n1_name ' to ' n2_name];['in ' strrep(wokrflow,'_',' ')]})



% saveas(gcf,[Path 'figures\summary\different_task_passive\asymmetry plot mpfc activity in ' n1_name ' to ' n2_name 'in mxied of' strrep(wokrflow,'_',' ') ], 'jpg');

saveas(gcf,[Path 'figures\summary\different_task_passive\non learner asymmetry plot mpfc activity in ' n1_name ' to ' n2_name 'in mxied of' strrep(wokrflow,'_',' ') ], 'jpg');

