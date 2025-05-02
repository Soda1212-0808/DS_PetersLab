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


Color={'B','R'};
n1_name='';n2_name='';
use_period=[];
use_t=[];
animals={};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};
workflow='task';


%used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};


select_group=1:2


all_data_image2=cell(2,1);
all_data_cross_day=cell(2,1);
for used_data=2
    for curr_state=1

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
                raw_data_task=load([Path  workflow '\old\' animal '_' workflow '.mat']);

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
                all_data_image=cell(8,1);
            else
                all_data_image=cell(9,1);
            end



            pre_learn_data0=cell(length(animals{curr_group}),1);
            pre_learn_data0 = cellfun(@(x,y,z,l) ...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==0 ))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
           
            pre_learn_data0 = cellfun(@(x) x(1:end-2),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0 = cellfun(@(x) mean(cat(4,x{:}),4),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0= cellfun(@(x) ...
                [x repmat({nan(450,426,length(use_t))},1,1-length(x))],pre_learn_data0,'UniformOutput',false);


            pre_learn_data1=cell(length(animals{curr_group}),1);
            pre_learn_data1 = cellfun(@(x,y,z,l) ...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l'==0 ,2,'last'))...
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

                data_all=cellfun(@(a0,a,b,c,d,e,f,g) [a0 a b c d e f g],pre_learn_data0, pre_learn_data1,post_learn1_data1,post_learn2_data1,...
                    pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,'UniformOutput',false);

                all_data_image{8}=cellfun(@(x) nanmean(cat(5,x{:}),5),data3,'UniformOutput',false);

            else
                data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),2)},1,3),...
                    (1:length(find(~mixed_idx)))', 'UniformOutput', false);
                data3= cellfun(@(x) [x  repmat({nan(450,426,length(use_t),2)},1,3-length(x))],data3,'UniformOutput',false);
                data3=cellfun(@(x)   cellfun(@(y) {y(:,:,:,1) ,y(:,:,:,2)} ,x,'UniformOutput',false),data3,'UniformOutput',false);
                data3= cellfun(@(x)   reshape([x{:}],1,6),data3,'UniformOutput',false);

                data_all=cellfun(@(a0,a,b,c,d,e,f,g) [a0 a b c d e f g([1 3 5]) g([2 4 6])],pre_learn_data0, pre_learn_data1,post_learn1_data1,post_learn2_data1,...
                    pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,'UniformOutput',false);

                all_data_image{8}=cellfun(@(x) nanmean(cat(5,x{[1 3 5]}),5),data3,'UniformOutput',false);
                all_data_image{9}=cellfun(@(x) nanmean(cat(5,x{[2 4 6]}),5),data3,'UniformOutput',false);

            end
            all_data_image{1}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data0,'UniformOutput',false);

            all_data_image{2}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data1,'UniformOutput',false);
            all_data_image{3}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data1,'UniformOutput',false);
            all_data_image{4}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data1,'UniformOutput',false);
            all_data_image{5}=cellfun(@(x) nanmean(cat(5,x{:}),5),pre_learn_data2,'UniformOutput',false);
            all_data_image{6}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn1_data2,'UniformOutput',false);
            all_data_image{7}=cellfun(@(x) nanmean(cat(5,x{:}),5),post_learn2_data2,'UniformOutput',false);



            all_data_image1= cellfun(@(x) cat(5,x{:}), all_data_image,'UniformOutput',false);
            all_data_image2{curr_group}{used_data,curr_state}=cat(6,all_data_image1{:});

            % data_all1=cellfun(@(x) cat(4,x{:}),data_all,'UniformOutput',false);
            all_data_cross_day{curr_group}{used_data}{curr_state}=data_all;
            % data_all_video=permute(max(all_data_image2{used_data,curr_state}(:,:,use_period,:,:,:),[],3),[1 2 4 5 6 3]);

            % clearvars('-except',main_preload_vars{:});
            %
        end
    end
end

% save([Path 'mat_data\summary_data\task ' data_type{used_data} state ' in group ' groups{select_group}  '.mat' ],'data_all_video','data_all','-v7.3');

% save([Path 'mat_data\summary_data\task video in all stage.mat' ], 'all_data_image2' ,'-v7.3');
%% task raw vs kernels

raw_v=permute(mean(max(all_data_image2{1}{1,1}(:,:,period_task,:,:,4),[],3),5),[1,2,4,3]);
kernels_v=permute(mean(max(all_data_image2{1}{2,1}(:,:,period_kernels,:,:,4),[],3),5),[1,2,4,3]);
raw_a=permute(mean(max(all_data_image2{2}{1,1}(:,:,period_task,:,:,4),[],3),5),[1,2,4,3]);
kernels_a=permute(mean(max(all_data_image2{2}{2,1}(:,:,period_kernels,:,:,4),[],3),5),[1,2,4,3]);
raw_data={raw_v,raw_a};;
kernels_data={kernels_v,kernels_a};
figure('Position',[50,50,266,400])
t2 = tiledlayout(2, 2, 'TileSpacing', 'tight', 'Padding', 'compact','TileIndexing', 'columnmajor');
colors={'B','R'}
titles={'visual','auditory'}
for curr_i=1:2
a1=nexttile
imagesc(raw_data{curr_i})
axis image off
ap.wf_draw('ccf','black');
clim(0.02.*[0,1]);
colormap(a1,ap.colormap(['W' colors{curr_i}]));
axis image;
colorbar('southoutside')
     title(titles{curr_i})

a2=nexttile
imagesc(kernels_data{curr_i})
axis image off
ap.wf_draw('ccf','black');
clim(0.0005.*[0,1]);
colormap(a2,ap.colormap(['W' colors{curr_i}]));
axis image;
colorbar('southoutside')

switch curr_i
case 1
      text(a1,-50, 150,  'raw', 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
       text(a2,-50, 150,  'kernels', 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
    
end

end

saveas(gcf,[Path 'figures\summary\figures\  task raw vs kernels ' ], 'jpg');




%% across time
group=2
group_name={'VA','AV'}; % VA-1,AV-2
type =2
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_task,t_kernels};
use_t=t_t{type};

align_time=1
align_time_name={'stim','move','iti move'}% stim-1 move-2  itimove-3;
stage=1
stage_name={'mod1-pre','mod1-post1','mod1-well trained','mod2-pre','mod2-post1','mod2-well trained','mixed-V','mixed-A'};
% stage1-pre:1; stage1-post1:2; stage1-post2:3 ;
% stage2-pre:4 ;stage2-post:5 ;stage2-post:6;
% mixed visual:7 ; mixed auditory :8

curr_video=permute(nanmean(all_data_image2{group}{type,align_time}(:,:,:,1,:,:),5),[1 2 3 6 4 5]);
% curr_video=pre_learn_data1{5}{2};
% curr_video=data_all{5}{1};
% curr_video=all_data_cross_day{2}{2,1}(:,:,:,:,5);
% curr_video=nanmean(all_data_cross_day{1}{2,1},5);

% curr_video=image_all{1, 1} ;
ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
% clim(0.9*max(curr_video,[],'all').*[-1,1]);
clim(0.0002.*[-1,1]);
colormap(ap.colormap('KWB'));
axis image;
set(gcf,'name',sprintf('%s',[ group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ' ' stage_name{stage}]));

%%

Color={'B','R'};

curr_video=permute(mean(all_data_image2{group}{2}(:,:,:,1,:,:),5),[1,2,3,6,5,4]);

scale=0.0002;

figure('Position', [50 50 120*length(find(use_t>=-0.2& use_t<=0.1)) 150*(size(curr_video,5)+1)]);
t1 = tiledlayout(size(curr_video,5)+1, length(find(use_t>=-0.2& use_t<=0.1)), 'TileSpacing', 'none', 'Padding', 'none');

for curr_stage=1:size(curr_video,5)
    for curr_time =find(use_t>=-0.2& use_t<0.1)

        a_1=nexttile
        buff_image=curr_video(:,:,curr_time,curr_stage);

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


%%
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

curr_video1=mean(permute(all_data_image2{1}{type,align_time}(:,:,:,1,:,3),[1 2 3 5 6 4]),4);
curr_video2=mean(permute(all_data_image2{2}{type,align_time}(:,:,:,1,:,6),[1 2 3 5 6 4]),4);
curr_video=cat(4,curr_video1,curr_video2);

ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
% clim(0.9*max(curr_video,[],'all').*[-1,1]);
clim(0.0003.*[-1,1]);
colormap(ap.colormap('KWG'));
axis image;


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
%   axis off
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




%% Task cross modality stage 1 & 2

figure('Position', [50 50 600 700]);
t = tiledlayout(3, 4, 'TileSpacing', 'tight', 'Padding', 'none');
Color={'G','P','G','P','G','P','G','P','G'};
titles{4}='Mod1';
titles{7}='Mod2';

overlays={[4,7];[7,4];[4,4];[7,7]}

group_name={'VA','AV'}; % VA-1,AV-2
all_buf_data_each=cell(2,1);
all_buf_data=cell(2,1);
img_data1=cell(2,1);
all_peak_mean=cell(2,1);
all_peak_error=cell(2,1);
all_scross_time_mean=cell(2,1);
all_scross_time_error=cell(2,1);
all_data=cell(2,1);
for curr_group=select_group
    preload_vars=who;
    % curr_area=select_group*2-1;
    curr_area=[1 3];
    buf3_roi=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    buf3_roi_peak=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    buf3_roi_stim=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    for curr_animal=1:length( all_data_cross_day{curr_group}{1}{1})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) ,...
            all_data_cross_day{curr_group}{2}{1}{curr_animal}, 'UniformOutput', false);

        for curr_roi= 1:length(roi1)
            buf3_roi{curr_animal}{curr_roi}= cellfun(@(z) permute(nanmean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_animal}{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_animal}{curr_roi},'UniformOutput',false ));
        end
    end
    temp_data1= cellfun(@(x) cellfun(@(y) cat(2,y{:}),x,'UniformOutput',false),  buf3_roi,'UniformOutput',false);
    temp_data2=cellfun(@(x) cat(3,x{:}),temp_data1,'UniformOutput',false)
    all_data{curr_group}=nanmean(cat(4, temp_data2{:}),4);
    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_stim3_error=std(buf3_roi_stim2,0,4,'omitmissing')./sqrt(size(buf3_roi_stim2,4));
 
    all_scross_time_mean{curr_group}=buf3_roi_stim3_mean;
    all_scross_time_error{curr_group}=buf3_roi_stim3_error;

    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean=nanmean(buf3_roi_peak2,3);
    % buf3_roi_peak_mean1=permute(nanmean(cat(4,buf3_roi_peak1{:}),4),[2 3 1]);
    buf3_roi_peak_error=std(buf3_roi_peak2,0,3,'omitmissing')./sqrt(length( all_data_cross_day{curr_group}{2}{1}));
    all_peak_mean{curr_group}=buf3_roi_peak_mean;
    all_peak_error{curr_group}=buf3_roi_peak_error;


    scale=0.0004
    for curr_image=[4 7 ]
        a1=nexttile

          all_buf_data_each{curr_group}{curr_image}=permute(max(all_data_image2{curr_group}{2,1}(:,:,period_kernels,1,:,curr_image),[],3),[1 2 5 3 4]);

        all_buf_data{curr_group}{curr_image}=nanmean(max(all_data_image2{curr_group}{2,1}(:,:,period_kernels,1,:,curr_image),[],3),5);
       % buf_data2=buf_data>0.25* max(buf_data,[],'all')
        imagesc(all_buf_data{curr_group}{curr_image})
        axis image off;
        clim(scale .* [0.25, 0.75]);
        colormap(a1, ap.colormap(['W' Color{curr_group}] ));
        frame1 = getframe(gca);
        img_data1{curr_group}{curr_image} =im2double( imresize(frame1.cdata, size(all_buf_data{curr_group}{curr_image})));
                clim(scale .* [0, 1]);

        ap.wf_draw('ccf', 'black');
            title(titles{curr_image})
            if curr_image==7
       colorbar('southoutside')
            end
            
        if curr_image==3
            text(-50, 150,  group_name{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        end
    end

    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

    nexttile([1 2])
    for i=[1  3  ]
        
        ap.errorfill(1:8,buf3_roi_peak_mean(1:8 ,i),buf3_roi_peak_error(1:8,i) ,colors{i},0.1,0.5);
        if curr_group==1

            ap.errorfill(9:15,buf3_roi_peak_mean(9:15 ,i),buf3_roi_peak_error(9:15,i) ,colors{i},0.1,0.5);
            % ap.errorfill(16:18,buf3_roi_peak_mean(16:18 ,i),buf3_roi_peak_error(16:18,i) ,colors{i},0.1,0.5);
            % ap.errorfill(19:21,buf3_roi_peak_mean(19:21 ,i),buf3_roi_peak_error(19:21,i) ,colors{i},0.1,0.5);
     xlim([0.5 15.5])
         xticks([4.5 12.5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）


        else
            ap.errorfill(9:14,buf3_roi_peak_mean(9:14 ,i),buf3_roi_peak_error(9:14,i) ,colors{i},0.1,0.5);
             % ap.errorfill(15:17,buf3_roi_peak_mean(16:18 ,i),buf3_roi_peak_error(16:18,i) ,colors{i},0.1,0.5);
            % ap.errorfill(18:20,buf3_roi_peak_mean(19:21 ,i),buf3_roi_peak_error(19:21,i) ,colors{i},0.1,0.5);
     xlim([0.5 14.5])
         xticks([4.5 12]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）

        end
    end
    
    xticklabels({'Mod1','Mod2'}); % 设置对应的标签
    ylim([0 1.2*scale])
    ylabel('\Delta F/F')
     % legend
    legend({'','pl-mPFC','','','','al-mPFC'},'Location','northwest','Box','off')
    % legend({'','pl-mPFC','','','','pr-mPFC','','','','al-mPFC','','','','ar-mPFC'},'Location','eastoutside','Box','off')

    clearvars('-except',preload_vars{:});

end
% sgtitle('task kernels mod1-mod2')
overlay_title={'V-overlay','A-overlay'}
for curr_overlay=1:2
nexttile
result_p = min(img_data1{1}{overlays{curr_overlay}(1)}, img_data1{2}{overlays{curr_overlay}(2)});
imshow([result_p]);
ap.wf_draw('ccf', 'black');
title(overlay_title{curr_overlay})

end


save([Path 'summary_data\task kernels of images crossday corsstime.mat'],'all_buf_data',...
    'all_peak_mean','all_peak_error','all_scross_time_mean','all_scross_time_error','all_data','-v7.3')

% permutation test
    
threshold=0.0001
data_above_threshold=cellfun(@(x) cellfun(@(y) y>threshold,x,'UniformOutput',false ),all_buf_data_each,'UniformOutput',false);
p_vals_roi_mean=cell(4,1);
p_thres_roi_mean=cell(4,1);

p_vals_roi_error=cell(4,1);
p_vals=cell(4,1);
p_thres=cell(4,1);
for curr_overlay=1:4
A=data_above_threshold{1}{overlays{curr_overlay}(1)};
B=data_above_threshold{2}{overlays{curr_overlay}(2)};
% A=all_buf_data_each{1}{4};
% B=all_buf_data_each{2}{7};
% A(A<threshold)=0;
% B(B<threshold)=0;
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 
% 将每组图像展平为 [像素数 × 图数]
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 

% 合并数据
all_data = [A_reshape, B_reshape];   
nA = size(A_reshape,2);
nB = size(B_reshape,2);
n_total = nA + nB;

% 计算真实的均值差异
diff_real = mean(A_reshape,2) - mean(B_reshape,2);  % [120000 x 1]

% 生成打乱样本
n_perm = 1000;
diff_shuff = zeros(size(diff_real,1), n_perm);

for i = 1:n_perm
    rand_idx = randperm(n_total);
    group1 = all_data(:,rand_idx(1:nA));
    group2 = all_data(:,rand_idx(nA+1:end));
    diff_shuff(:,i) = mean(group1,2) - mean(group2,2);  % [120000 x 1]
end

% 拼接真实和打乱结果 -> [120000 x (1+n_perm)]
all_diffs = [diff_real, diff_shuff];

% 排序后计算秩
ranks = tiedrank(all_diffs')';  % 转置->对每一行排序（每个像素点）

% 实际结果的秩在第一列
real_ranks = ranks(:,1);

% 越接近最大值，越显著（两尾）
p_vals{curr_overlay} =  abs(real_ranks - (n_perm+1)/2) / ((n_perm+1)/2);
  p_thres{curr_overlay}=p_vals{curr_overlay}>0.95;
 curr_roi=[1 2 3 4 5 6 8 12]
 p_thres_roi_mean{curr_overlay}= arrayfun(@(roi) nanmean(p_thres{curr_overlay}(roi1(roi).data.mask(:),:,:),1),...
    curr_roi,'UniformOutput',true);
p_vals_roi_mean{curr_overlay}= arrayfun(@(roi) nanmean(p_vals{curr_overlay}(roi1(roi).data.mask(:),:,:),1),...
    curr_roi,'UniformOutput',true);
p_vals_roi_error{curr_overlay}= arrayfun(@(roi) std(p_vals{curr_overlay}(roi1(roi).data.mask(:)),0,1,'omitmissing')/...
    sqrt(sum((roi1(roi).data.mask(:)))) ,curr_roi,'UniformOutput',true);

% 重塑为图像
p_map = reshape(p_vals{curr_overlay},size(A,[1 2]));
% figure
% imagesc(p_map>0.95 );  axis image;
%  colormap( ap.colormap(['WK'] ));     
% ap.wf_draw('ccf', 'black');

end

% figure('Position', [50 50 600 600]);
% t = tiledlayout(3, 4, 'TileSpacing', 'tight', 'Padding', 'none');

t2 = tiledlayout(t,2, 2, 'TileSpacing', 'none', 'Padding', 'none');
t2.Layout.Tile = 11;
for curr_i=1:4
 % 重塑为图像
 p_map = reshape(p_vals{curr_i},size(A,[1 2]));
 aa=nexttile(t2)
p_map = reshape(p_vals{curr_i},size(A,[1 2]));
imagesc(p_map>0.95 );  axis image off
 colormap(aa, ap.colormap(['WK'] ));     
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title(legend_name{curr_i},'Color',colors1(curr_i,:))
end


% 数据（5个类别 × 3组）
% data = cell2mat(p_vals_roi_mean)'
data = cell2mat(p_thres_roi_mean)';

% % 对应的标准误差（可换成你自己的）
% errors =cell2mat(p_vals_roi_error)'
% 
% 绘制分组柱状图
nexttile(t,12)
colors1 = [...
   0.3 0.3 0.9;   % Group 1: 蓝色
    0.9 0.4 0.4;   % Group 2: 绿色
    0.5 0.5 0.5;
     0.5 0.5 0.5];  % Group 3: 红色
hBar = bar(data, 'grouped'); hold on;
box off
% 设置每组的颜色
for i = 1:length(hBar)
    hBar(i).FaceColor = colors1(i, :);
         hBar(i).EdgeColor = 'none';       % 无边框线

end


% 设置 x 轴标签
set(gca, 'XTick', 1:8, 'XTickLabel', {'pl-mPFC', 'pr-mPFC', 'al-mPFC', 'ar-mPFC', 'l-PPC', 'r-PPC', 'auditory area', 'visual area'});

% 图例和轴标签
% legend({'V', 'A', 'VA','AV'}, 'Location', 'northeastoutside','Box','off');
% xlabel('Category');
ylabel('proportion of difference ');






 saveas(gcf,[Path 'figures\summary\figures\task kernels mod1-mod2'], 'jpg');



%%  Task corss modality in mixed task
figure('Position', [50 50 600 600]);
t = tiledlayout(3, 3, 'TileSpacing', 'tight', 'Padding', 'none');
Color={'G','P','G','P','G','P','G','P','G'};

titles{8}='mixed V';
titles{9}='mixed A';
overlays={[8,8];[9,9];[8,9];[8,9]}


group_name={'VA','AV'}; % VA-1,AV-2
all_buf_data_each=cell(2,1);
all_buf_data=cell(2,1);
img_data1=cell(2,1);
all_peak_mean=cell(2,1);
all_peak_error=cell(2,1);
all_scross_time_mean=cell(2,1);
all_scross_time_error=cell(2,1);
all_data=cell(2,1);
for curr_group=select_group
    preload_vars=who;
    % curr_area=select_group*2-1;
    curr_area=[1 3];
    buf3_roi=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    buf3_roi_peak=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    buf3_roi_stim=cell(length( all_data_cross_day{curr_group}{1}{1}),1);
    for curr_animal=1:length( all_data_cross_day{curr_group}{1}{1})

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) ,...
            all_data_cross_day{curr_group}{2}{1}{curr_animal}, 'UniformOutput', false);

        for curr_roi= 1:length(roi1)
            buf3_roi{curr_animal}{curr_roi}= cellfun(@(z) permute(nanmean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1, 'UniformOutput', false);
            buf3_roi_peak{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(max(x(use_period,:),[],1) ),buf3_roi{curr_animal}{curr_roi}, 'UniformOutput', false));
            buf3_roi_stim{curr_animal}{curr_roi}=cell2mat(cellfun(@(x) double(x), buf3_roi{curr_animal}{curr_roi},'UniformOutput',false ));
        end
    end
    temp_data1= cellfun(@(x) cellfun(@(y) cat(2,y{:}),x,'UniformOutput',false),  buf3_roi,'UniformOutput',false);
    temp_data2=cellfun(@(x) cat(3,x{:}),temp_data1,'UniformOutput',false)
    all_data{curr_group}=nanmean(cat(4, temp_data2{:}),4);
    buf3_roi_stim1= cellfun(@(x) cat(3,x{:}), buf3_roi_stim,'UniformOutput',false);
    buf3_roi_stim2=cat(4,buf3_roi_stim1{:});
    buf3_roi_stim3_mean=nanmean(buf3_roi_stim2,4);
    buf3_roi_stim3_error=std(buf3_roi_stim2,0,4,'omitmissing')./sqrt(size(buf3_roi_stim2,4));

    all_scross_time_mean{curr_group}=buf3_roi_stim3_mean;
    all_scross_time_error{curr_group}=buf3_roi_stim3_error;

    buf3_roi_peak1= cellfun(@(x) cat(3,x{:}), buf3_roi_peak,'UniformOutput',false);
    buf3_roi_peak2=permute(cat(4,buf3_roi_peak1{:}),[2 3 4 1]);
    buf3_roi_peak_mean_0=vertcat(nanmean(buf3_roi_peak2(16:18,:,:),1),nanmean(buf3_roi_peak2(19:21,:,:),1));
    buf3_roi_peak_mean=nanmean(buf3_roi_peak_mean_0,3);
    % buf3_roi_peak_mean1=permute(nanmean(cat(4,buf3_roi_peak1{:}),4),[2 3 1]);
    buf3_roi_peak_error=std(buf3_roi_peak_mean_0,0,3,'omitmissing')./sqrt(size(buf3_roi_peak_mean_0,3));
    all_peak_mean{curr_group}=buf3_roi_peak_mean;
    all_peak_error{curr_group}=buf3_roi_peak_error;


    scale=0.0004
    for curr_image=[ 8 9]
        a1=nexttile

          all_buf_data_each{curr_group}{curr_image}=permute(max(all_data_image2{curr_group}{2,1}(:,:,period_kernels,1,:,curr_image),[],3),[1 2 5 3 4]);

        all_buf_data{curr_group}{curr_image}=nanmean(max(all_data_image2{curr_group}{2,1}(:,:,period_kernels,1,:,curr_image),[],3),5);
       % buf_data2=buf_data>0.25* max(buf_data,[],'all')
        imagesc(all_buf_data{curr_group}{curr_image})
        axis image off;
        clim(scale .* [0.25, 0.75]);
        colormap(a1, ap.colormap(['W' Color{curr_group}] ));
        frame1 = getframe(gca);
        img_data1{curr_group}{curr_image} =im2double( imresize(frame1.cdata, size(all_buf_data{curr_group}{curr_image})));
                clim(scale .* [0, 1]);

        ap.wf_draw('ccf', 'black');
            title(titles{curr_image})
            if curr_image==9
       colorbar('southoutside')
            end
            
        if curr_image==3
            text(-50, 150,  group_name{curr_group}, 'FontSize', 10, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        end
    end

    colors = { [0 0 1],[0.5 0.5 1],[1 0 0], [1 0.5 0.5],[0 0 0], [0.5 0.5 0.5]}; % 定义颜色

nexttile
data = buf3_roi_peak_mean(:,[1 3]);
errors=buf3_roi_peak_error(:,[1 3]);
categories={'mixed V','mixed A'};
x = 1:numel(categories);
nGroups = size(data, 2);  % 3 组
% 偏移量让不同组的数据点错开
groupWidth = 0.6;  % 控制点的分散程度
offsets = linspace(-groupWidth/2, groupWidth/2, nGroups);
% 绘图
hold on;
colors1 = [...
    0 0 0.9;
    0.9 0 0];
for i = 1:nGroups
    % 对每组数据加一点横向偏移
    x_offset = x + offsets(i);
    errorbar(x_offset, data(:, i), errors(:, i), ...
        'o', 'LineWidth', 1.5, ...
        'MarkerSize', 6, ...
        'Color', colors1(i, :), ...
        'MarkerFaceColor', colors1(i, :), ...
        'LineStyle', 'none');  % 不连接线
end
% 设置 x 轴
set(gca, 'XTick', x, 'XTickLabel', categories);
xlim([0.5, length(categories) + 0.5]);
ylim([0 1.2*scale])
% 图例和标签
legend({'pl-mPFC', 'al-mPFC'}, 'Location', 'northwest','Box','off');
ylabel('\Delta F/F')
box off
clearvars('-except',preload_vars{:});
end

title_mixed{8}='mixed V-overlay';
title_mixed{9}='mixed A-overlay';

for curr_i=8:9
nexttile
result_p = min(img_data1{1}{curr_i}, img_data1{2}{curr_i});
imshow([result_p]);
ap.wf_draw('ccf', 'black');
title(title_mixed{curr_i})
end

% permutation test
threshold=0.0001
data_above_threshold=cellfun(@(x) cellfun(@(y) y>threshold,x,'UniformOutput',false ),all_buf_data_each,'UniformOutput',false);
p_vals_roi_mean=cell(4,1);
p_thres_roi_mean=cell(4,1);

p_vals_roi_error=cell(4,1);
p_vals=cell(4,1);
p_thres=cell(4,1);
for curr_overlay=1:4
A=data_above_threshold{1}{overlays{curr_overlay}(1)};
B=data_above_threshold{2}{overlays{curr_overlay}(2)};
% A=all_buf_data_each{1}{4};
% B=all_buf_data_each{2}{7};
% A(A<threshold)=0;
% B(B<threshold)=0;
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 
% 将每组图像展平为 [像素数 × 图数]
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 

% 合并数据
all_data = [A_reshape, B_reshape];   
nA = size(A_reshape,2);
nB = size(B_reshape,2);
n_total = nA + nB;

% 计算真实的均值差异
diff_real = mean(A_reshape,2) - mean(B_reshape,2);  % [120000 x 1]

% 生成打乱样本
n_perm = 1000;
diff_shuff = zeros(size(diff_real,1), n_perm);

for i = 1:n_perm
    rand_idx = randperm(n_total);
    group1 = all_data(:,rand_idx(1:nA));
    group2 = all_data(:,rand_idx(nA+1:end));
    diff_shuff(:,i) = mean(group1,2) - mean(group2,2);  % [120000 x 1]
end

% 拼接真实和打乱结果 -> [120000 x (1+n_perm)]
all_diffs = [diff_real, diff_shuff];

% 排序后计算秩
ranks = tiedrank(all_diffs')';  % 转置->对每一行排序（每个像素点）

% 实际结果的秩在第一列
real_ranks = ranks(:,1);

% 越接近最大值，越显著（两尾）
p_vals{curr_overlay} =  abs(real_ranks - (n_perm+1)/2) / ((n_perm+1)/2);
  p_thres{curr_overlay}=p_vals{curr_overlay}>0.95;
 curr_roi=[1 2 3 4 5 6 8 12];
 p_thres_roi_mean{curr_overlay}= arrayfun(@(roi) nanmean(p_thres{curr_overlay}(roi1(roi).data.mask(:),:,:),1),...
    curr_roi,'UniformOutput',true);
p_vals_roi_mean{curr_overlay}= arrayfun(@(roi) nanmean(p_vals{curr_overlay}(roi1(roi).data.mask(:),:,:),1),...
    curr_roi,'UniformOutput',true);
p_vals_roi_error{curr_overlay}= arrayfun(@(roi) std(p_vals{curr_overlay}(roi1(roi).data.mask(:)),0,1,'omitmissing')/...
    sqrt(sum((roi1(roi).data.mask(:)))) ,curr_roi,'UniformOutput',true);

% % 重塑为图像
% p_map = reshape(p_vals{curr_overlay},size(A,[1 2]));
% figure
% imagesc(p_map>0.95 );  axis image;
%  colormap( ap.colormap(['WK'] ));     
% ap.wf_draw('ccf', 'black');

end

% figure
% t = tiledlayout(3, 3, 'TileSpacing', 'tight', 'Padding', 'none');
colors1 = [...
   0.3 0.3 0.9;   % Group 1: 蓝色
    0.9 0.4 0.4;   % Group 2: 绿色
    0.5 0.5 0.5;
     0.5 0.5 0.5];  % Group 3: 红色
t2 = tiledlayout(t,2, 4, 'TileSpacing', 'none', 'Padding', 'none');
 t2.Layout.Tile = 9;

for curr_i=1:4
 % 重塑为图像
 aa=nexttile(t2)
p_map = reshape(p_vals{curr_i},size(A,[1 2]));
imagesc(p_map>0.95 );  axis image off
 colormap(aa, ap.colormap(['WK'] ));     
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title(legend_name{curr_i},'Color',colors1(curr_i,:))
% if curr_i==2
%     nexttile
%     axis off
% end
end

 % saveas(gcf,[Path 'figures\summary\figures\task kernels in mixed tasks_p_valus_map'], 'jpg');

data = cell2mat(p_thres_roi_mean)';

% % 对应的标准误差（可换成你自己的）
% errors =cell2mat(p_vals_roi_error)'
% 
% 绘制分组柱状图
nexttile(t2,[1 4])

hBar = bar(data, 'grouped'); hold on;
box off
% 设置每组的颜色
for i = 1:length(hBar)
    hBar(i).FaceColor = colors1(i, :);
         hBar(i).EdgeColor = 'none';       % 无边框线

end
% 
% % 获取柱子的 x 坐标
% ngroups = size(data, 1);
% nbars = size(data, 2);
% groupwidth = min(0.8, nbars/(nbars + 1.5));  % 控制组宽度
% 
% for i = 1:nbars
%     % 计算每组中每个柱子的中心 x 位置
%     x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
%     errorbar(x, data(:, i), errors(:, i), 'k', 'linestyle', 'none', 'LineWidth', 1);
% end

% 设置 x 轴标签
set(gca, 'XTick', 1:8, 'XTickLabel', {'pl-mPFC', 'pr-mPFC', 'al-mPFC', 'ar-mPFC', 'l-PPC', 'r-PPC', 'auditory area', 'visual area'});

% 图例和轴标签
legend_name={'V', 'A', 'VA','AV'}
% legend(legend_name, 'Location', 'northeastoutside','Box','off');
% xlabel('Category');
ylabel('proportion of difference ');
saveas(gcf,[Path 'figures\summary\figures\task kernels in mixed tasks'], 'jpg');

 
