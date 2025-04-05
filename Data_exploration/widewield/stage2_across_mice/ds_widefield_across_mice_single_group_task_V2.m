clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')


surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];


Color={'B','R'};
n1_name='';n2_name='';
use_period=[];
use_t=[];
animals={};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};
workflow='task';


% used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};
select_group=1:2


all_data_image2=cell(2,1)
for used_data=1:2
for curr_state=1:3

if curr_state==1
    task_boundary1=0;
    task_boundary2=0.2;
    state='stim'
elseif curr_state==2
    task_boundary1=-0.1;
    task_boundary2=0;
    state='move'
else curr_state==3

    task_boundary1=0;
    task_boundary2=0.2;
    state='iti_move'

end
period_task=find(t_task>task_boundary1&t_task<task_boundary2);
period_kernels=find(t_kernels>task_boundary1&t_kernels<task_boundary2);

for curr_group=select_group;



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


% used_id=1:3;

all_data_video=cell(length(animals{curr_group}),1);
all_data_workflow_name=cell(length(animals{curr_group}),1);
all_data_learned_day=cell(length(animals{curr_group}),1);
matches=cell(length(animals{curr_group}),1);
use_t=[];
use_period=[];

for curr_animal=1:length(animals{curr_group})
    preload_vars = who;

    animal=animals{curr_group}{curr_animal};
    raw_data_task=load([Path '\mat_data\' workflow '\' animal '_' workflow '.mat']);

    for curr_d=1:length(raw_data_task.rxn_med)
        if length(raw_data_task.rxn_med{curr_d})==1
            raw_data_task.learned_day(curr_d)=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}<0.05;
        else
            raw_data_task.learned_day(curr_d)= bin2dec(num2str(raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}(2:3)<0.05));
        end
        % raw_data_task.learned_day= cellfun(@(x,y)  x<2 & y<0.05, raw_data_task.rxn_med,raw_data_task.rxn_stat_p,'UniformOutput',false);
    end


    if used_data==1

        idx=cellfun(@(x) ~isempty(x)  ,raw_data_task.wf_px_task);
        if curr_state==1
            image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x(:,:,ifelse(size(x,3)==4  ,1,[1 4]))),raw_data_task.wf_px_task(idx),'UniformOutput',false);
        elseif curr_state==2
            image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x(:,:,ifelse(size(x,3)==4  ,2,[2 5]))),raw_data_task.wf_px_task(idx),'UniformOutput',false);
        elseif curr_state==3
             image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x(:,:,ifelse(size(x,3)==4  ,4,7))),raw_data_task.wf_px_task(idx),'UniformOutput',false);
        end

        use_period=period_task;
        use_t=t_task;
    else
        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels);

        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{curr_state},1)),x{curr_state}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
        use_period=period_kernels;
        use_t=t_kernels;
    end
    matches{curr_animal}=unique(raw_data_task.workflow_type_name_merge(idx)  ,'stable');






    all_data_video{curr_animal}=image_all(idx);
    all_data_workflow_name{curr_animal}=raw_data_task.workflow_type_name_merge(idx);
    all_data_learned_day{curr_animal}=raw_data_task.learned_day(idx);
    clearvars('-except',preload_vars{:});

end

if curr_state==3
    all_data_image=cell(7,1);
else
    all_data_image=cell(8,1);
end



pre_learn_data1=cell(length(animals{curr_group}),1);
pre_learn_data1 = cellfun(@(x,y,z,l) ...
    x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==0 ,2,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
pre_learn_data1= cellfun(@(x) ...
    [x repmat({nan(450,426,length(use_t))},1,2-length(x))],pre_learn_data1,'UniformOutput',false);


post_learn1_data1=cell(length(animals{curr_group}),1);
post_learn1_data1 = cellfun(@(x,y,z,l)...
    x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==1 ,2,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
post_learn1_data1= cellfun(@(x)...
    [x  repmat({nan(450,426,length(use_t))},1,2-length(x))],post_learn1_data1,'UniformOutput',false);
post_learn2_data1=cell(length(animals{curr_group}),1);
post_learn2_data1 = cellfun(@(x,y,z,l)...
    x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==1 ,5,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
post_learn2_data1 = cellfun(@(x) x(3:end),post_learn2_data1,'UniformOutput',false);
post_learn2_data1= cellfun(@(x) ...
    [x  repmat({nan(450,426,length(use_t))},1,3-length(x))],post_learn2_data1,'UniformOutput',false);


pre_learn_data2=cell(length(animals{curr_group}),1);
pre_learn_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==0 ,2,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
pre_learn_data2= cellfun(@(x) [x  repmat({nan(450,426,length(use_t))},1,2-length(x))],pre_learn_data2,'UniformOutput',false);
post_learn1_data2=cell(length(animals{curr_group}),1);
post_learn1_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==1 ,2,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
post_learn1_data2= cellfun(@(x) [x repmat({nan(450,426,length(use_t))},1,2-length(x))],post_learn1_data2,'UniformOutput',false);


post_learn2_data2=cell(length(animals{curr_group}),1);
post_learn2_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l'==1 ,5,'first'))...
    ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
post_learn2_data2 = cellfun(@(x) x(3:end),post_learn2_data2,'UniformOutput',false);
post_learn2_data2= cellfun(@(x) [x repmat({single(nan(450,426,length(use_t)))},1,3-length(x))],post_learn2_data2,'UniformOutput',false);

 % x=post_learn2_data2{2}

n3_name='mixed VA';
mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
data3=cell(length(animals{curr_group}),1);
data3(mixed_idx) = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last')),...
    all_data_video(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false);


% itimvoe
if curr_state==3
data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),1)},1,3),...
    (1:length(find(~mixed_idx)))', 'UniformOutput', false);
data3= cellfun(@(x) [x  repmat({nan(450,426,length(use_t),1)},1,3-length(x))],data3,'UniformOutput',false);

 data_all=cellfun(@(a,b,c,d,e,f,g) [a b c d e f g], pre_learn_data1,post_learn1_data1,post_learn2_data1,...
     pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,'UniformOutput',false);
 
 all_data_image{7}=cellfun(@(x) nanmean(cat(5,x{:}),5),data3,'UniformOutput',false);

else
data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),2)},1,3),...
    (1:length(find(~mixed_idx)))', 'UniformOutput', false);
data3= cellfun(@(x) [x  repmat({nan(450,426,length(use_t),2)},1,3-length(x))],data3,'UniformOutput',false);
data3=cellfun(@(x)   cellfun(@(y) {y(:,:,:,1) ,y(:,:,:,2)} ,x,'UniformOutput',false),data3,'UniformOutput',false);
data3= cellfun(@(x)   reshape([x{:}],1,6),data3,'UniformOutput',false);

data_all=cellfun(@(a,b,c,d,e,f,g) [a b c d e f g([1 3 5]) g([2 4 6])], pre_learn_data1,post_learn1_data1,post_learn2_data1,...
    pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,'UniformOutput',false);

all_data_image{7}=cellfun(@(x) nanmean(cat(5,x{[1 3 5]}),5),data3,'UniformOutput',false);
all_data_image{8}=cellfun(@(x) nanmean(cat(5,x{[2 4 6]}),5),data3,'UniformOutput',false);

end

all_data_image{1}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data1,'UniformOutput',false);
all_data_image{2}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data1,'UniformOutput',false);
all_data_image{3}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data1,'UniformOutput',false);
all_data_image{4}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data2,'UniformOutput',false);
all_data_image{5}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data2,'UniformOutput',false);
all_data_image{6}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data2,'UniformOutput',false);



all_data_image1= cellfun(@(x) cat(5,x{:}), all_data_image,'UniformOutput',false);
all_data_image2{curr_group}{used_data,curr_state}=cat(6,all_data_image1{:});

% data_all_video=permute(max(all_data_image2{used_data,curr_state}(:,:,use_period,:,:,:),[],3),[1 2 4 5 6 3]);
end
end
end
    
% save([Path 'mat_data\summary_data\task ' data_type{used_data} state ' in group ' groups{select_group}  '.mat' ],'data_all_video','data_all','-v7.3');

    % save([Path 'mat_data\summary_data\task video in all stage.mat' ], 'all_data_image2' ,'-v7.3');
%% across time 
group=1
group_name={'VA','AV'}; % VA-1,AV-2
type =2
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_task,t_kernels};
     use_t=t_t{type};

align_time=1
align_time_name={'stim','move','iti move'}% stim-1 move-2  itimove-3;
stage=[1 3]
stage_name={'mod1-pre','mod1-post1','mod1-well trained','mod2-pre','mod2-post1','mod2-well trained','mixed-V','mixed-A'};
% stage1-pre:1; stage1-post1:2; stage1-post2:3 ;
% stage2-pre:4 ;stage2-post:5 ;stage2-post:6;
% mixed visual:7 ; mixed auditory :8

curr_video=permute(nanmean(all_data_image2{group}{type,align_time}(:,:,:,1,:,stage),5),[1 2 3 6 4 5]);

ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
% clim(0.9*max(curr_video,[],'all').*[-1,1]);
clim(0.0002.*[-1,1]);
colormap(ap.colormap('KWB'));
axis image;
set(gcf,'name',sprintf('%s',[ group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ' ' stage_name{stage}]));
%%
%
Color={'B','R'};

curr_video1=permute(all_data_image2{group}{type,2}(:,:,:,1,:,stage),[1 2 3 5 4 6]);
curr_video2=permute(all_data_image2{group}{type,3}(:,:,:,1,:,stage),[1 2 3 5 4 6]);

curr_video3=curr_video1-curr_video2;
curr_video=cat(5,curr_video1, curr_video2,curr_video3);

buf1= reshape(curr_video,size(curr_video,1)*size(curr_video,2),size(curr_video,3),size(curr_video,4),size(curr_video,5)) ;
buf3_roi=  permute(mean(buf1(roi1(15).data.mask(:),:,:,:),1),[2,4,3,1]) ;
buf3_roi_error=std(buf3_roi,0,3,"omitmissing")./sqrt(size(buf3_roi,3));
buf3_roi_mean=nanmean(buf3_roi,3);

scale=0.0002;
row_labels = ["stim move", "iti move", "difference"];

figure('Position', [50 50 120*length(find(use_t>=-0.2& use_t<=0.1)) 150*(size(curr_video,5)+1)]);
t1 = tiledlayout(size(curr_video,5)+1, length(find(use_t>=-0.2& use_t<=0.1)), 'TileSpacing', 'none', 'Padding', 'none');

for curr_stage=1:size(curr_video,5)
for curr_time =find(use_t>=-0.2& use_t<0.1)

    a_1=nexttile
    buff_image=nanmean(curr_video(:,:,curr_time,:,curr_stage),4);

    imagesc(buff_image)
    axis image off;
    ap.wf_draw('ccf', 'black');
    clim(scale .* [-1, 1]);
        colormap( a_1, ap.colormap(['KW' Color{group}]  ));
   if curr_stage==1
        title(num2str(t_kernels(curr_time)))
   end
   if curr_time==find(use_t>=-0.2& use_t<0.1,1,'first')
        text(-30, 100, row_labels(curr_stage), 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Rotation', 90);
   end
end

end


cb=colorbar('southoutside'); % 在下方添加 colorbar

    nexttile

    imagesc(zeros(size(curr_video,[1 2])));
    axis image off;
    ap.wf_draw('ccf', 'black');
    boundaries1 = bwboundaries(roi1(15).data.mask  );
    plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])
    colormap(  ap.colormap(['KW' Color{group}]  ));

    ax4=nexttile
    ax4.Visible = 'off'; % 隐藏空白块的坐标轴

    nexttile
    hold on
    ap.errorfill(use_t(find(use_t>=-0.2& use_t<=0)),buf3_roi_mean(find(use_t>=-0.2& use_t<=0),1),...
        buf3_roi_error(find(use_t>=-0.2& use_t<=0),1)  ,[1 0 0],0.1,0.5);
    ap.errorfill(use_t(find(use_t>=-0.2& use_t<=0)),buf3_roi_mean(find(use_t>=-0.2& use_t<=0),2),...
        buf3_roi_error(find(use_t>=-0.2& use_t<=0),2)  ,[0 0 0],0.1,0.5);
    legend({'','stim move','','iti move'},'Location','eastoutside')
    xlabel('time (s)')
    ylabel('\Delta F/F')
    ylim([-0.00005 0.0001])
    % cb.Position(2) = cb.Position(2); % 0.02 是调整量，可根据需要修改
    sgtitle([group_name{group} ' ' stage_name{stage}])

  % saveas(gcf,[Path 'figures\summary\figures\task ' data_type{type} ' across time in ' [group_name{group} ' ' stage_name{stage}] 'aligned to move' ], 'jpg');

%%
group=1
group_name={'VA','AV'}; % VA-1,AV-2
type =1
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_task,t_kernels};
use_t=t_t{type};
align_time=1
align_time_name={'stim','move','iti move'}% stim-1 move-2  itimove-3;
stage=[1 3]
stage_name={'mod1-pre','mod1-post1','mod1-well trained','mod2-pre','mod2-post1','mod2-well trained','mixed-V','mixed-A'};

curr_video=permute(all_data_image2{group}{type,align_time}(:,:,:,1,:,stage),[1 2 3 5 6 4]);

% ap.imscroll(curr_video,use_t)
% axis image off
% ap.wf_draw('ccf','black');
% % clim(0.9*max(curr_video,[],'all').*[-1,1]);
% clim(0.0004.*[-1,1]);
% colormap(ap.colormap('KWG'));
% axis image;
% set(gcf,'name',sprintf('%s',[ group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ' ' stage_name{stage}]));

buf1= reshape(curr_video,size(curr_video,1)*size(curr_video,2),size(curr_video,3),size(curr_video,4),size(curr_video,5)) ;
selected_roi=[ 1  3  5];
buf3_roi_error=cell(length(selected_roi),1);
buf3_roi_mean=cell(length(selected_roi),1);


% figure('Position', [50 50 240 150*(length(selected_roi))]);
% t1 = tiledlayout(length(selected_roi), 1, 'TileSpacing', 'tight', 'Padding', 'none');
% scale=0.0002;
% for curr_roi=selected_roi
% nexttile
% buf3_roi=  permute(mean(buf1(roi1(curr_roi).data.mask(:),:,:,:),1),[2,4,3,1]) ;
% buf3_roi_error{curr_roi}=std(buf3_roi,0,3,"omitmissing")./sqrt(size(buf3_roi,3));
% buf3_roi_mean{curr_roi}=nanmean(buf3_roi,3);
%  ap.errorfill(use_t,buf3_roi_mean{curr_roi}(:,1),...
%         buf3_roi_error{curr_roi}(:,1)  ,[0 0 0],0.1,0.5);
%  ap.errorfill(use_t,buf3_roi_mean{curr_roi}(:,2),...
%         buf3_roi_error{curr_roi}(:,2)  ,[1 0 0],0.1,0.5);
%   ylim(scale*[-0.4 1.2])
%   title(roi1(curr_roi).name)
%   xline(0,'LineStyle','--')
%   xline(-0.1,'LineStyle','--')
%   xlim([-0.2 0.2])
%   if ~(curr_roi==selected_roi(find(selected_roi,1,'last')))
%   % axis off
%   set(gca, 'XColor', 'none')
%   end
%   xlabel('time (s)')
%   if curr_roi==selected_roi(1)
%    legend({'',stage_name{stage(1)},'',stage_name{stage(2)}},'Location','north','Box','off')
%   end
% end
% sgtitle({[ group_name{group} ' ' data_type{type} ];[ align_time_name{align_time} ]})
% saveas(gcf,[Path 'figures\summary\figures\task of sequenced activity '  group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ], 'jpg');
scale=0.0005;

figure('Position', [50 50 600 400]);
t1 = tiledlayout(1, 2, 'TileSpacing', 'tight', 'Padding', 'none');
cmap = parula(length(selected_roi))
for curr_stage=1:2
    nexttile
hold on
ii=0
  for curr_roi=selected_roi
ii=ii+1;
buf3_roi=  permute(mean(buf1(roi1(curr_roi).data.mask(:),:,:,:),1),[2,4,3,1]) ;
buf3_roi_error{curr_roi}=std(buf3_roi,0,3,"omitmissing")./sqrt(size(buf3_roi,3));
buf3_roi_mean{curr_roi}=nanmean(buf3_roi,3);
 ap.errorfill(use_t,buf3_roi_mean{curr_roi}(:,curr_stage),...
        buf3_roi_error{curr_roi}(:,curr_stage)  ,cmap(ii,:),0.1,0.5);
  ylim(scale*[-0.4 1.2])
  % title(roi1(curr_roi).name)

  xlim([-0.2 0.2])
  
  xlabel('time (s)')
 
  end
  title(stage_name(stage(curr_stage)))
       xline(0,'LineStyle','--')
  xline(-0.05,'LineStyle','--')

end
sgtitle({[ group_name{group} ' ' data_type{type} ];[ align_time_name{align_time} ]})
     legend({'',roi1(selected_roi(1)).name, '',roi1(selected_roi(2)).name,...
         '',roi1(selected_roi(3)).name },'Location','northeastoutside','Box','off')
 saveas(gcf,[Path 'figures\summary\figures\task of sequenced activity_2 '  group_name{group} ' ' data_type{type} ' ' stage_name{stage(1)} ' ' align_time_name{align_time} ], 'jpg');

%% figure

title2_task={'VA ','AV ','VAn','AVn','Vp-Af','VoVp','Vs-Vp','Va-Vp'};
title1_task={'pre learn1','post learn1-1','post learn1-2','pre learn2','post learn2-1','post learn2-2','mixed V','mixed A'};

curr_group = select_group
    curr_area=1;
    % curr_area=1;
    for curr_animal=1:length( data_all)

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , data_all{curr_animal}, 'UniformOutput', false);
        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_roi},'UniformOutput',false ));
        end
    end

    if used_data==2
        scale=0.0003;
    else
        scale=0.03;
    end

    Color={'B','R'};
    %
    figure('Name',[ title2_task{curr_group} '  separate images'])
    set(gcf, 'Position', get(0, 'ScreenSize')); % 设置为全屏
    tiledlayout(length( data_all), 6, 'TileSpacing', 'compact', 'Padding', 'compact');
    for curr_animal=1:length( data_all)
        for curr_phase=1:6
            % buf_images=data_all_video(:,:,1,curr_animal,curr_phase)-fliplr(data_all_video(:,:,1,curr_animal,curr_phase));
            buf_images=data_all_video(:,:,1,curr_animal,curr_phase);
            nexttile
            imagesc(buf_images)
            axis image off;
            ap.wf_draw('ccf', 'black');
            clim(scale .* [-1, 1]);
            colormap( ap.colormap(['KWG' ]));
            axis image;
            if curr_animal==1
                title(title1_task{curr_phase})
            end
            if curr_phase==1
                text(-2, 5, animals{curr_group}{curr_animal}, 'FontSize', 10, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'right', 'Rotation', 0);
            end
        end
        % sgtitle(animals{curr_stage}{curr_animal})
    end

    sgtitle(title2_task{curr_group});

    % saveas(gcf,[Path 'figures\summary\different_task_passive\task '  title2_task{curr_group}  ' separated images in ' data_type{used_data} ], 'jpg');

%%
    figure('Name',[ title2_task{curr_group} ' 3 stim separate'])
    for curr_animal=1:length( data_all)

        nexttile;
        hold on

        ylim(scale .* [-0.2, 1]);
        colorMap = lines(2); % 使用 colormap 自动生成不同颜色
        ax = gca;
        ylim1 = ax.YLim;
        % 填充背景颜色
        fill([0.5, 7.5, 7.5, 0.5,], ...
            [ylim1(1), ylim1(1), ylim1(2), ylim1(2)], ...
            colorMap(1, :), 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 添加透明度
        fill([7.5, 14.5, 14.5, 7.5,], ...
            [ylim1(1), ylim1(1), ylim1(2), ylim1(2)], ...
            colorMap(2, :), 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 添加透明度


        pp=plot(permute(cat(3,buf3_roi_peak{curr_animal}{12}),[2 3 1]));
        colors = {[1 0 0], [1 0.5 0.5], [0 0 1],[0.5 0.5 1]}; % 定义颜色
        % set(pp, {'Color'}, colors(:)); % 一次性设置线条颜色
        xlim([0.5 20.5])
        xline(2.5);xline(4.5);xline(7.5);xline(9.5);xline(11.5);xline(14.5);xline(17.5);
        xticks([ 1.5 3.5 6 8.5  10.5  13 16 19]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        xticklabels(title1_task); % 设置对应的标签
        title(animals{curr_group}{curr_animal})


    end
    sgtitle(title2_task{curr_group});
    % saveas(gcf,[Path 'figures\summary\different_task_passive\task ' title2_task{curr_group} ' separated peak in ' data_type{used_data}  ], 'jpg');


    
    if used_data==2
        scale=0.0002;
    else
        scale=0.02;
    end

    figure('Name',[ title2_task{curr_group} ' lateralized separate across time'])
    for curr_animal=1:length( data_all)

        nexttile;
        imagesc(use_t,[], buf3_roi_stim{curr_animal}{14}')

        yline(2.5);yline(4.5);yline(7.5);yline(9.5);yline(11.5);yline(14.5);yline(17.5);
        yticks([ 1.5 3.5 6 8.5  10.5  13 16 19]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title1_task); % 设置对应的标签

        title(animals{curr_group}{curr_animal})
        clim(scale .* [-1, 1]);
        colormap(ap.colormap('KWG'));


    end
    sgtitle(title2_task{curr_group});

    % saveas(gcf,[Path 'figures\summary\different_task_passive\task ' title2_task{curr_group} ' separated stim in ' data_type{used_data} ], 'jpg');




    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim1_mean=nanmean(cat(4,buf3_roi_stim1{:}),4);
    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
    buf3_roi_peak2=nanmean(cat(4,buf3_roi_peak1{:}),4);
    buf3_roi_peak_mean=permute(buf3_roi_peak2,[2 3 1]);
    buf3_roi_peak_error=permute(std(cat(4,buf3_roi_peak1{:}),0,4,'omitmissing')./sqrt(length(animals{curr_group})),[2 3 1]);

    buf_images_all=permute(nanmean(data_all_video(:,:,1,:,:),4),[1 2 5 3 4]);

    figure('Position',[50 50 1600 200],'Name',[ title2_task{curr_group} ' images merged'])
    for curr_phase=1:8
        nexttile
        imagesc(buf_images_all(:,:,curr_phase))
        axis image off;
        ap.wf_draw('ccf', 'black');
        clim(scale .* [-1, 1]);
        colormap( ap.colormap('KWG' ));
        title(title1_task{curr_phase})
    end
    sgtitle(title2_task{curr_group})
    % saveas(gcf,[Path 'figures\summary\different_task_passive\task ' title2_task{curr_group} ' merged images in ' data_type{used_data} ], 'jpg');

    figure('Name',[ title2_task{curr_group} ' across time  merged'])

    for i=1:4
        nexttile
        imagesc(use_t,[], buf3_roi_stim1_mean(:,:,i)')

        yline(3.5);yline(5.5);yline(7.5);yline(10.5);yline(12.5);yline(14.5);yline(17.5);
        yticks([2 4.5 6.5 9 11.5  13.5  16 19]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        yticklabels(title1_task); % 设置对应的标签
        title(roi1(i).name)
        xlabel('time (s)')
        clim(scale .* [-1, 1]);
        colormap(ap.colormap('KWG'));
    end
    sgtitle([title2_task{curr_group} 'task'])

    % saveas(gcf,[Path 'figures\summary\different_task_passive\task ' title2_task{curr_group} ' merged stim in ' data_type{used_data} ], 'jpg');



      if used_data==2
        scale=0.0003;
    else
        scale=0.03;
    end

    figure('Name',[ title2_task{curr_group} ' 3 stim  merged'])
    hold on
    ylim(scale .* [-0.2, 1]);
    colorMap = lines(2); % 使用 colormap 自动生成不同颜色
    ax = gca;
    ylim1 = ax.YLim;
    % 填充背景颜色
    % 填充背景颜色
    fill([0.5, 7.5, 7.5, 0.5,], ...
        [ylim1(1), ylim1(1), ylim1(2), ylim1(2)], ...
        colorMap(1, :), 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 添加透明度
    fill([7.5, 14.5, 14.5, 7.5,], ...
        [ylim1(1), ylim1(1), ylim1(2), ylim1(2)], ...
        colorMap(2, :), 'EdgeColor', 'none', 'FaceAlpha', 0.3); % 添加透明度

    colors = {[1 0 0], [1 0.5 0.5], [0 0 1],[0.5 0.5 1], [0 0 0],[0.5 0.5 0.5]}; % 定义颜色
    ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,1),buf3_roi_peak_error(:,12) ,colors{1},0.1,0.5);
    ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,2),buf3_roi_peak_error(:,2) ,colors{2},0.1,0.5);
    ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,3),buf3_roi_peak_error(:,3) ,colors{3},0.1,0.5);
    ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,4),buf3_roi_peak_error(:,4) ,colors{4},0.1,0.5);
     ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,5),buf3_roi_peak_error(:,5) ,colors{5},0.1,0.5);
    ap.errorfill(1:size(buf3_roi_peak_mean,1),buf3_roi_peak_mean(:,6),buf3_roi_peak_error(:,6) ,colors{6},0.1,0.5);
    xlim([0.5 20.5])
    xline(2.5);xline(4.5);xline(7.5);xline(9.5);xline(11.5);xline(14.5);xline(17.5);
    xticks([ 1.5 3.5 6 8.5  10.5  13 16 19]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels(title1_task); % 设置对应的标签
    title(title2_task{curr_group})
    % saveas(gcf,[Path 'figures\summary\different_task_passive\task ' title2_task{curr_group} ' merged peak in ' data_type{used_data} ], 'jpg');









