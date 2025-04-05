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

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);



all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
Color={'B','R'};


% data_all=struct;
% data_all.(all_workflow{1})=[];
% data_all.(all_workflow{2})=[];

% data_all_images=struct;
% data_all_images.(all_workflow{1})=[];
% data_all_images.(all_workflow{2})=[];

n1_name='';n2_name='';
use_period=[];
workflow='';
use_t=[];
animals={};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};
select_group=[1 2]

data_all_video=cell(2,1)
data_all=cell(2,1)
% used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};
for used_data=2
for  workflow_idx=1:2
    workflow=all_workflow{workflow_idx};
    for curr_group=select_group;
    main_preload_vars = who;
    if curr_group==1
        animals{curr_group} = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
    elseif curr_group==2
        animals{curr_group} = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
    elseif curr_group==3
        animals{curr_group} = {'AP018','AP020'};n1_name='visual position';n2_name='audio volume';
    elseif curr_group==4
        animals{curr_group} = {'DS006','DS013'};n1_name='audio volume';n2_name='visual position';
    elseif curr_group==5
        animals{curr_group} = {'AP027','AP028','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';
    elseif curr_group==6
        animals{curr_group} = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
    elseif curr_group==7
        animals{curr_group} = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
    elseif curr_group==8
        animals{curr_group} = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';

    end

    used_id=1:3;
    all_data_video=cell(length(animals{curr_group}),1);
    all_data_workflow_name=cell(length(animals{curr_group}),1);
    all_data_learned_day=cell(length(animals{curr_group}),1);
    matches=cell(length(animals{curr_group}),1);
    use_t=[];
    use_period=[];
    for curr_animal=1:length(animals{curr_group})
        preload_vars = who;
        animal=animals{curr_group}{curr_animal};
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






        all_data_video{curr_animal}=image_all(idx);
        all_data_workflow_name{curr_animal}=raw_data_passive.workflow_type_name_merge(idx);
        all_data_learned_day{curr_animal}=raw_data_passive.learned_day(idx);
        clearvars('-except',preload_vars{:});

    end

    naive_idx=cellfun(@(x) any(strcmp('naive',x)),matches,'UniformOutput',true );
    naive_data=cell(length(animals{curr_group}),1);
    naive_data(naive_idx) =  cellfun(@(x, y, z)...
        x(find(strcmp(y, z(find(cellfun(@(idx) strcmp('naive', idx), z, 'UniformOutput', true)))), 3, 'first'), :), ...
        all_data_video(naive_idx), all_data_workflow_name(naive_idx), matches(naive_idx), ...
        'UniformOutput', false);
    naive_data(~naive_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),3)},3,1),...
        (1:length(find(~naive_idx)))', 'UniformOutput', false);
    naive_data= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],naive_data,'UniformOutput',false);

    pre_learn_data1=cell(length(animals{curr_group}),1);
    pre_learn_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==0 ,2,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    pre_learn_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],pre_learn_data1,'UniformOutput',false);

    post_learn1_data1=cell(length(animals{curr_group}),1);
    post_learn1_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==1 ,2,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    post_learn1_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],post_learn1_data1,'UniformOutput',false);


    post_learn2_data1=cell(length(animals{curr_group}),1);
    post_learn2_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==1 ,5,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    post_learn2_data1 = cellfun(@(x) x(3:end),post_learn2_data1,'UniformOutput',false);
    post_learn2_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],post_learn2_data1,'UniformOutput',false);

    pre_learn_data2=cell(length(animals{curr_group}),1);
    pre_learn_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==0 ,2,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    pre_learn_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],pre_learn_data2,'UniformOutput',false);

    post_learn1_data2=cell(length(animals{curr_group}),1);
    post_learn1_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==1 ,2,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    post_learn1_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],post_learn1_data2,'UniformOutput',false);

    post_learn2_data2=cell(length(animals{curr_group}),1);
    post_learn2_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==1 ,5,'first'))...
        ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
    post_learn2_data2 = cellfun(@(x) x(3:end),post_learn2_data2,'UniformOutput',false);
    post_learn2_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],post_learn2_data2,'UniformOutput',false);

    n3_name='mixed VA';
    mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
    data3=cell(length(animals{curr_group}),1);
    data3(mixed_idx) = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last'),:),...
        all_data_video(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false);

    data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),3)},3,1),...
        (1:length(find(~mixed_idx)))', 'UniformOutput', false);
    data3= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],data3,'UniformOutput',false);

    all_data=cellfun(@(a,b,c,d,e,f,g,h) [a;b;c;d;e;f;g;h], naive_data,pre_learn_data1,post_learn1_data1,post_learn2_data1,...
        pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,'UniformOutput',false);

    all_data_image{1}=cellfun(@(x) nanmean(cat(5,x{:}),5),naive_data,'UniformOutput',false);
    all_data_image{2}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data1,'UniformOutput',false);
    all_data_image{3}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data1,'UniformOutput',false);
    all_data_image{4}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data1,'UniformOutput',false);
    all_data_image{5}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data2,'UniformOutput',false);
    all_data_image{6}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data2,'UniformOutput',false);
    all_data_image{7}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data2,'UniformOutput',false);
    all_data_image{8}=cellfun(@(x) nanmean(cat(5,x{:}),5),data3,'UniformOutput',false);


    all_data_image1= cellfun(@(x) cat(5,x{:}), all_data_image,'UniformOutput',false);
    all_data_image2=cat(6,all_data_image1{:});
    % data_all_video{workflow_idx}=permute(max(all_data_image2(:,:,use_period,:,:,:),[],3),[1 2 4 5 6 3]);


    data_all{curr_group}{used_data}{workflow_idx}=all_data;

    % data_all_images.(all_workflow{workflow_idx})=permute(max(all_data_image2(:,:,use_period,:,:,:),[],3),[1 2 4 5 6 3]);

    data_all_video{curr_group}{used_data}{workflow_idx}=all_data_image2;



    clearvars('-except',main_preload_vars{:});

    end
end

end

% save([Path 'mat_data\summary_data\passive ' data_type{used_data} ' in group ' groups{select_group}  '.mat' ],'data_all_images','data_all','-v7.3');

%%
%% across time 
group=1
group_name={'VA','AV'}; % VA-1,AV-2
stim_type=1
stim_name={'V passive','A passive'}
stim_cue={3,2};

type =2
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_passive,t_kernels};
     use_t=t_t{type};

stage=1:8
stage_name={'naive','mod1-pre','mod1-post1','mod1-well trained','mod2-pre','mod2-post1','mod2-well trained','mixed'};
% stage1-pre:1; stage1-post1:2; stage1-post2:3 ;
% stage2-pre:4 ;stage2-post:5 ;stage2-post:6;
% mixed visual:7 ; mixed auditory :8

curr_video=permute(nanmean(data_all_video{group}{type}{stim_type}(:,:,:,stim_cue{stim_type},:,stage),5),[1 2 3 6 4 5]);


ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
% clim(0.9*max(curr_video,[],'all').*[-1,1]);
clim(0.0002.*[-1,1]);
colormap(ap.colormap('KWB'));
axis image;
% set(gcf,'name',sprintf('%s',[ group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ' ' stage_name{stage}]));
%

scale=0.0002;

figure('Position', [50 50 120*length(find(use_t>=0& use_t<=0.3)) 150*(size(curr_video,4)+1)]);
t1 = tiledlayout(size(curr_video,4)+1, length(find(use_t>=0& use_t<=0.3)), 'TileSpacing', 'none', 'Padding', 'none');
Color={'G','P','P','P','P','P','P'};

for curr_stage=1:size(curr_video,4)
for curr_time =find(use_t>=0& use_t<0.3)

    a_1=nexttile
    buff_image=curr_video(:,:,curr_time,curr_stage);
    
    imagesc(buff_image)
    % imagesc(buff_image-fliplr(buff_image))
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
        colormap( a_1, ap.colormap(['KW' Color{group}]  ));
   if curr_stage==1
        title(num2str(t_kernels(curr_time)))
   end
   if curr_time==find(use_t>=0& use_t<0.3,1,'first')
        text(-30, 100, stage_name(stage(curr_stage)), 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Rotation', 90);
   end
end

end
cb=colorbar('southoutside'); % 在下方添加 colorbar
 
% saveas(gcf,[Path 'figures\summary\figures\' stim_name{stim_type} '' data_type{type} ' across time in ' group_name{group}   ], 'jpg');

%% sequenced activity PPC vs amPFC vs pmPFC

curr_video=permute(data_all_video{group}{type}{stim_type}(:,:,:,stim_cue{stim_type},:,stage),[1 2 3 6 5 4]);

buf1= reshape(curr_video,size(curr_video,1)*size(curr_video,2),size(curr_video,3),size(curr_video,4),size(curr_video,5)) ;
selected_roi=[ 1 3 5];
buf3_roi_error=cell(length(selected_roi),1);
buf3_roi_mean=cell(length(selected_roi),1);

scale=0.0003
figure('Position', [50 50 600 400]);
t1 = tiledlayout(1, 2, 'TileSpacing', 'tight', 'Padding', 'none');
cmap = parula(length(selected_roi))
for curr_stage=1:2
    nexttile
hold on
ii=0;
  for curr_roi=selected_roi
ii=ii+1;
buf3_roi=  permute(mean(buf1(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]) ;
buf3_roi_error{curr_roi}=std(buf3_roi,0,3,"omitmissing")./sqrt(size(buf3_roi,3));
buf3_roi_mean{curr_roi}=nanmean(buf3_roi,3);
 ap.errorfill(use_t,buf3_roi_mean{curr_roi}(:,curr_stage),...
        buf3_roi_error{curr_roi}(:,curr_stage)  ,cmap(ii,:),0.1,0.5);
  ylim(scale*[-0.4 1.2])
  % title(roi1(curr_roi).name)

  xlim([-0.2 0.3])
  
  xlabel('time (s)')
 
  end
  title(stage_name(stage(curr_stage)))
       xline(0,'LineStyle','--')
  xline(-0.05,'LineStyle','--')

end


sgtitle({[ group_name{group} ' ' data_type{type} ]})
     legend({'',roi1(selected_roi(1)).name, '',roi1(selected_roi(2)).name,...
         '',roi1(selected_roi(3)).name },'Location','northeastoutside','Box','off')

     
saveas(gcf,[Path 'figures\summary\figures\passive of sequenced activity_2 '  group_name{group} ' ' data_type{type} ' ' stage_name{stage(1)}  ], 'jpg');



%%
% 
group=1
group_name={'VA','AV'}; % VA-1,AV-2
stim_type=1
stim_name={'V passive','A passive'}
stim_cue={3,2};

type =2
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_passive,t_kernels};
     use_t=t_t{type};

colors{1}={[0 0 0],    [0 0 0],            [  84 130 53 ]./255;...
        [0 0 0], [0 0 0],    [112  48 160]./255}
colors{2}={[0 0 0],  [  84 130 53 ]./255  ,  [0 0 0]          ;...
        [0 0 0], [112  48 160]./255    ,[0 0 0]}
scale=0.0002


figure('Position', [50 50 310 300]);

t1 = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for curr_type=1:2
    for curr_group=1:2
curr_data=cat(2 ,data_all{curr_group}{type}{curr_type}{:});
buf1= cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),curr_data,'UniformOutput',false) ;

selected_roi=2*curr_type-1;

  for curr_roi=selected_roi

buf3_roi=  cellfun(@(x) permute(mean(x(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),buf1,'UniformOutput', false);
buf3_roi_peak=cellfun(@(x) double(max(x(use_period,:),[],1) )',buf3_roi, 'UniformOutput', false);
buf3_roi_peak1=reshape(cat(2,buf3_roi_peak{:}), [length(buf3_roi_peak{1}) size(buf3_roi_peak)]);
buf3_roi_error=std(buf3_roi_peak1,0,3,"omitmissing")./sqrt(size(buf3_roi_peak1,3));
buf3_roi_mean=nanmean(buf3_roi_peak1,3);
nexttile
for curr_stim=1:3
ap.errorfill(1:3,buf3_roi_mean(curr_stim,1:3),buf3_roi_error(curr_stim,1:3) ,colors{curr_type}{curr_group,curr_stim},0.1,0.5);
ap.errorfill(4:10,buf3_roi_mean(curr_stim,4:10),buf3_roi_error(curr_stim,4:10) ,colors{curr_type}{curr_group,curr_stim},0.1,0.5);
ap.errorfill(11:15,buf3_roi_mean(curr_stim,13:17),buf3_roi_error(curr_stim,13:17) ,colors{curr_type}{curr_group,curr_stim},0.1,0.5);

end
  % ylim(scale*[-0.4 1.2])
   title(roi1(curr_roi).name)
xlim([1 15])
    ylim(scale*[0 1])
   xticks([2 7 13]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels({'naive','Mod 1','Mod 2'}); % 设置对应的标签
ylabel('\Delta F/F') 

  end
end
end

saveas(gcf,[Path 'figures\summary\figures\passive of selectivity 1 '   ], 'jpg');

colors={[  84 130 53 ]./255,[112  48 160]./255}

figure('Position', [50 50 310 300]);

t1 = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for curr_type=1:2
    for curr_group=1:2
curr_data=cat(2 ,data_all{curr_group}{type}{curr_type}{:});
buf1= cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),curr_data,'UniformOutput',false) ;

selected_roi=2*curr_type-1;

  for curr_roi=selected_roi

buf3_roi=  cellfun(@(x) permute(mean(x(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),buf1,'UniformOutput', false);
buf3_roi_peak=cellfun(@(x) double(max(x(use_period,:),[],1) )',buf3_roi, 'UniformOutput', false);
buf3_roi_peak1=reshape(cat(2,buf3_roi_peak{:}), [length(buf3_roi_peak{1}) size(buf3_roi_peak)]);
if curr_type==1
buf3_roi_peak2=buf3_roi_peak1(3,:,:)-max(buf3_roi_peak1(1,:,:),buf3_roi_peak1(2,:,:))
else
buf3_roi_peak2=buf3_roi_peak1(2,:,:)-max(buf3_roi_peak1(1,:,:),buf3_roi_peak1(3,:,:))
end
buf3_roi_error=std(buf3_roi_peak2,0,3,"omitmissing")./sqrt(size(buf3_roi_peak2,3));
buf3_roi_mean=nanmean(buf3_roi_peak2,3);
nexttile

ap.errorfill(1:3,buf3_roi_mean(1:3),buf3_roi_error(1:3) ,colors{curr_group},0.1,0.5);
ap.errorfill(4:10,buf3_roi_mean(4:10),buf3_roi_error(4:10) ,colors{curr_group},0.1,0.5);
ap.errorfill(11:15,buf3_roi_mean(13:17),buf3_roi_error(13:17) ,colors{curr_group},0.1,0.5);


  % ylim(scale*[-0.4 1.2])
   title(roi1(curr_roi).name)
xlim([1 15])
    ylim(scale*[-0.5 1])
    yline(0)
   xticks([2 7 13]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels({'naive','Mod 1','Mod 2'}); % 设置对应的标签
ylabel('selectivity') 

  end
end
end

saveas(gcf,[Path 'figures\summary\figures\passive of selectivity 2 '   ], 'jpg');



