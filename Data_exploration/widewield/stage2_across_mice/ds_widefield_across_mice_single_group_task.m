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
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];
% t_kernels_move=1/surround_samplerate*[-30:30];

  % animals = {'DS007','DS010','AP019','AP021','DS011'};n1_name='visual position';n2_name='audio volume';
% animals = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
% % animals = {'DS005'} ;transfer_type='a_frequency_to_v_position';
% animals = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
animals = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
% animals = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';
 % animals = {'AP027','AP028','AP029','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';

for curr_state=1
if curr_state==1
    task_boundary1=0;
task_boundary2=0.15;
state='stim'
else
task_boundary1=-0.1;
task_boundary2=0;
state='move'

end

period_task=find(t_task>task_boundary1&t_task<task_boundary2);
period_kernels=find(t_kernels>task_boundary1&t_kernels<task_boundary2);


learn_name={'non-learned','learned'};
% workflow_stage={'naive','visual','auditory','mixed'};
used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};



all_data_peak=cell(length(animals),1);
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
    raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);
    % find learned day
    for curr_d=1:length(raw_data_task.rxn_med)
        if length(raw_data_task.rxn_med{curr_d})==1
            raw_data_task.learned_day{curr_d}=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}<0.05;
        else
            raw_data_task.learned_day{curr_d}=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}(2:3)<0.05;
        end
        % raw_data_task.learned_day= cellfun(@(x,y)  x<2 & y<0.05, raw_data_task.rxn_med,raw_data_task.rxn_stat_p,'UniformOutput',false);
    end

    if used_data==1
        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task);
        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_task.wf_px_task(idx),'UniformOutput',false);
        use_period=period_task;
        use_t=t_task;
    else
        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels);

        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{curr_state},1)),x{curr_state}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
        use_period=period_kernels;
        use_t=t_kernels;

    end
    matches{curr_animal}=unique(raw_data_task.workflow_type_name_merge(idx)  ,'stable');
    

    image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
    buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
    % buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
    buf3_l(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);
    buf3_r(idx)= cellfun(@(z) permute(mean(z(roi1(9).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);

    all_data_peak{curr_animal}=cell2mat(cellfun(@(x) max(x(use_period,1),[],1),buf3_l(idx),'UniformOutput',false)');
    all_data_stiml{curr_animal}=cell2mat(buf3_l(idx))';
    all_data_stimr{curr_animal}=cell2mat(buf3_r(idx))';

    all_data_image{curr_animal}=cellfun(@(x)  x(:,:,1),  image_all_mean(idx),'UniformOutput',false);
    all_data_video{curr_animal}=cellfun(@(x)  x(:,:,:,1),  image_all(idx),'UniformOutput',false);

    all_data_workflow_name{curr_animal}=raw_data_task.workflow_type_name_merge(idx);
    all_data_learned_day{curr_animal}=raw_data_task.learned_day(idx);

    clearvars('-except',preload_vars{:});

end
%%

% mPFC across day across time
stage1_pre_data_l = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first'),:),all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false);
stage1_post_data_l = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last'),:),all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false);
stage2_pre_data_l = cellfun(@(x,y,z,l) x( intersect(find(cell2mat(l)==0),...
    find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first')),:),all_data_stiml,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);

stage2_pre_data_l = cellfun(@(x) ifelse(isempty(x), NaN(1, length(use_t)), x), stage2_pre_data_l, 'UniformOutput', false);
stage2_post_data_l = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last'),:),all_data_stiml,all_data_workflow_name,matches,'UniformOutput',false);

stage1_pre_data_r = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first'),:),all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false);
stage1_post_data_r = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last'),:),all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false);
stage2_pre_data_r = cellfun(@(x,y,z,l) x( intersect(find(cell2mat(l)==0),...
    find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first')),:),all_data_stimr,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
stage2_pre_data_r = cellfun(@(x) ifelse(isempty(x), NaN(1, length(use_t)), x), stage2_pre_data_r, 'UniformOutput', false);

stage2_post_data_r = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last'),:),all_data_stimr,all_data_workflow_name,matches,'UniformOutput',false);


colum=size(stage1_post_data_l{1},2);
max_len_n1 = max(cellfun(@numel, stage1_post_data_l))/colum;
% 2. 使用 NaN 填充较短的向量
stage1_post_filled_pre_l = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), stage1_post_data_l, 'UniformOutput', false);
% n1_filled_post = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'post'), n1_data_l, 'UniformOutput', false);
stage1_post_filled_pre_r = cellfun(@(x) padarray(x', [0 max_len_n1-numel(x)/colum], NaN, 'pre'), stage1_post_data_r, 'UniformOutput', false);

max_len_n2 = max(cellfun(@numel, stage2_post_data_l))/colum;
% 2. 使用 NaN 填充较短的向量
stage2_post_filled_post_l = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), stage2_post_data_l, 'UniformOutput', false);
% n2_filled_pre = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'pre'), n2_data_l, 'UniformOutput', false);
stage2_post_filled_post_r = cellfun(@(x) padarray(x', [0 max_len_n2-numel(x)/colum], NaN, 'post'), stage2_post_data_r, 'UniformOutput', false);

n1_n2_l=cellfun(@(x,y,z,l) [x', y,z',l], ...
    stage1_pre_data_l, stage1_post_filled_pre_l,stage2_pre_data_l,stage2_post_filled_post_l,'UniformOutput',false);

n1_n2_peak_l=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),n1_n2_l,'UniformOutput',false));
n1_n2_merge_l=nanmean(cat(3,n1_n2_l{:}),3);

n1_n2_r=cellfun(@(x,y,z,l) [x', y,z',l], ...
    stage1_pre_data_r, stage1_post_filled_pre_r,stage2_pre_data_r,stage2_post_filled_post_r,'UniformOutput',false);
n1_n2_peak_r=cell2mat(cellfun(@(x) max(x(use_period,:),[],1),n1_n2_r,'UniformOutput',false));
n1_n2_merge_r=nanmean(cat(3,n1_n2_r{:}),3);

stage1_pre_data_image = cellfun(@(x,y,z) mean(cat(3,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first')}),3),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
stage1_post_data_image = cellfun(@(x,y,z) mean(cat(3,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last')}),3),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);
stage2_pre_data_image = cellfun(@(x,y,z,l) nanmean(cat(3,x{intersect(find(cell2mat(l)==0),find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'))}),3),all_data_image,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
stage2_post_data_image = cellfun(@(x,y,z) mean(cat(3,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last')}),3),all_data_image,all_data_workflow_name,matches,'UniformOutput',false);

stage1_pre_data_video = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),2,'first')}),4),all_data_video,all_data_workflow_name,matches,'UniformOutput',false);
stage1_post_data_video= cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_video,all_data_workflow_name,matches,'UniformOutput',false);
stage2_pre_data_video = cellfun(@(x,y,z,l) nanmean(cat(4,x{intersect(find(cell2mat(l)==0),find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),1,'first'))}),4),all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
stage2_post_data_video = cellfun(@(x,y,z) mean(cat(4,x{find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))),5,'last')}),4),all_data_video,all_data_workflow_name,matches,'UniformOutput',false);


%%

curr_video=mean(cat(4,stage1_post_data_video{:}),4);
ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf','black');
clim(0.5*max(curr_video,[],'all').*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
% set(gcf,'name',sprintf('%s %s',animal,raw_data_lcr1.workflow_day{rec_day}));

%%
%
figure('Position',[50 50 1000 450]);

t=tiledlayout(2,4)
scale=0.0002;

nexttile
imagesc(mean(cat(3,stage1_pre_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
 clim(scale*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
title('s1 pre')

nexttile
imagesc(mean(cat(3,stage1_post_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
 clim(scale*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
title('s1 post')

nexttile
imagesc(mean(cat(3,stage2_pre_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
 clim(scale*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;

title('s2 pre')

nexttile
imagesc(mean(cat(3,stage2_post_data_image{:}),3))
axis image off
ap.wf_draw('ccf','black');
 clim(scale*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
colorbar
title('s2 post')


nexttile(t,[1,2])

imagesc(use_t,[ ], n1_n2_merge_l')

yline(2.5)
yline(7.5)
yline(8.5)
colormap( ap.colormap('PWG'));
clim(0.0001 .* [-1, 1]);
title('L-mPFC')
xlabel('time (s)')
xline(task_boundary2,'r');xline(task_boundary1,'r')
colorbar



n1_n2_mean=mean(n1_n2_peak_l,1,"omitnan");
n1_n2_error=  std(n1_n2_peak_l,1,"omitnan")/sqrt(size(n1_n2_peak_l,1));

nexttile
hold on
length_n1=size(stage1_post_filled_pre_l{1},2);
length_n2=size(stage2_post_filled_post_l{1},2);

ap.errorfill(1:2,n1_n2_mean(1:2),  n1_n2_error(1:2),[0 0 0],0.1,0.5);
ap.errorfill(3:7,n1_n2_mean(3:7),  n1_n2_error(3:7),[0 0 0],0.1,0.5);
ap.errorfill(7.5:8.5,[n1_n2_mean(8) n1_n2_mean(8)], [ n1_n2_error(8) n1_n2_error(8)],[0 0 0],0.1,0.5);
ap.errorfill(9:13,n1_n2_mean(9:13),  n1_n2_error(9:13),[0 0 0],0.1,0.5);

ylim(0.0001*[0 2])
 xlim([0.5 13.5])

xticks([1.5 5 7, 11]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f change')
%
nexttile
errorbar( 1:4 ,[mean(n1_n2_mean(1:2)) mean(n1_n2_mean(3:7)) mean(n1_n2_mean(8)) mean(n1_n2_mean(9:13)) ],...
    [mean(n1_n2_error(1:2)) mean(n1_n2_error(3:7)) mean(n1_n2_error(8)) mean(n1_n2_error(9:13)) ],'k.','MarkerSize',20, 'LineWidth', 2,'Color','k');

xlim([0.5 4.5])
ylim(0.0001*[0 2])
xticks([1 2 3 4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f peak')
%     title ('visual passive')

sgtitle({[n1_name ' to ' n2_name];state})

saveas(gcf,[Path 'figures\summary\different_task_passive\mpfc activity in ' n1_name ' to ' n2_name ' in task of ' state] , 'jpg');

% Asymmetry

figure('Position',[50 50 1000 450]);

t=tiledlayout(2,4)

nexttile
imagesc(mean(cat(3,stage1_pre_data_image{:}),3)-fliplr(mean(cat(3,stage1_pre_data_image{:}),3)))
axis image off
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
xlim([0 216])
title('s1 pre')

nexttile
imagesc(mean(cat(3,stage1_post_data_image{:}),3)-fliplr(mean(cat(3,stage1_post_data_image{:}),3)))
axis image off
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
xlim([0 216])
title('s1 post')


nexttile
imagesc(mean(cat(3,stage2_pre_data_image{:}),3)-fliplr(mean(cat(3,stage2_pre_data_image{:}),3)))
axis image off
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
xlim([0 216])

title('s2 pre')

nexttile
imagesc(mean(cat(3,stage2_post_data_image{:}),3)-fliplr(mean(cat(3,stage2_post_data_image{:}),3)))
axis image off
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
xlim([0 216])
colorbar
title('s2 post')



nexttile(t,[1,2])
imagesc(use_t,[ ], (n1_n2_merge_l-n1_n2_merge_r)')
yline(2.5)
yline(7.5)
yline(8.5)

xline(task_boundary2,'Color',[1 0.5 0.5]);
xline(task_boundary1,'Color',[1 0.5 0.5])


colormap( ap.colormap('PWG'));
 clim(0.00005 .* [-1, 1]);
title('L-mPFC')
xlabel('time (s)')
colorbar


n1_n2_mean=mean((n1_n2_peak_l-n1_n2_peak_r),1,"omitnan");
n1_n2_error=  std((n1_n2_peak_l-n1_n2_peak_r),1,"omitnan")/sqrt(size(n1_n2_peak_l,2));

nexttile
hold on
ap.errorfill(1:2,n1_n2_mean(1:2),  n1_n2_error(1:2),[0 0 0],0.1,0.5);
ap.errorfill(3:7,n1_n2_mean(3:7),  n1_n2_error(3:7),[0 0 0],0.1,0.5);
ap.errorfill(7.5:8.5,[n1_n2_mean(8) n1_n2_mean(8)], [ n1_n2_error(8) n1_n2_error(8)],[0 0 0],0.1,0.5);
ap.errorfill(9:13,n1_n2_mean(9:13),  n1_n2_error(9:13),[0 0 0],0.1,0.5);
ylim(0.0001*[0 2])
 xlim([0.5 13.5])

xticks([1.5 5 7, 11]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f change')
%
nexttile
errorbar( 1:4 ,[mean(n1_n2_mean(1:2)) mean(n1_n2_mean(3:7)) mean(n1_n2_mean(8)) mean(n1_n2_mean(9:13)) ],...
    [mean(n1_n2_error(1:2)) mean(n1_n2_error(3:7)) mean(n1_n2_error(8)) mean(n1_n2_error(9:13)) ],'k.','MarkerSize',20, 'LineWidth', 2,'Color','k');

xlim([0.5 4.5])
ylim(0.0001*[0 2])
xticks([1 2 3 4]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
xticklabels({'s1 pre','s1 post','s2 pre','s2 post'}); % 设置对应的标签
ylabel('df/f peak')
%     title ('visual passive')




sgtitle({[n1_name ' to ' n2_name];state})


saveas(gcf,[Path 'figures\summary\different_task_passive\asymmetry mpfc activity in ' n1_name ' to ' n2_name ' in task of ' state] , 'jpg');
end