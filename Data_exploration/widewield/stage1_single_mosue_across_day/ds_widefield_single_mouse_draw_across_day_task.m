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
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-5:30];
% t_kernels_move=1/surround_samplerate*[-30:30];


task_boundary=0.1;
period_task=find(t_task>0&t_task<task_boundary);
period_kernels=find(t_kernels>0&t_kernels<task_boundary);

% animals = {'AP027','AP028','AP029'};

animals = {'AP027','AP028','AP029'};
avg_imaging=cell(length(animals),1);
 for curr_animal=1
 animal=animals{curr_animal};

learn_name={'non-learned','learned'};
workflow_stage={'naive','visual','auditory','mixed'};

used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};
raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);
% raw_data_lcr2=load([Path '\mat_data\' wokrflow '\' animal '_lcr_passive_single_trial.mat']);
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

image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x{1}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
use_period=period_kernels;
use_t=t_kernels;

end

image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);

buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);

% buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
 buf3(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);



idx_position=cellfun(@(x) strcmp(x,'stim_wheel_right_stage2'), raw_data_task.workflow_type_name,'UniformOutput',true  )

figure('Position',[50 50 400 300],'Name',['plots of ' animal,' ', data_type{used_data}]);
nexttile
plot_data=cell2mat(buf3)';
imagesc(use_t,[],plot_data)
clim(0.005.*[-1,1]); colormap(ap.colormap('PWG'));
hold on;
plot(0,find(cell2mat(raw_data_task.learned_day)),'.g')
% plot(-0.1,find(idx_position),'.r')

xline(0,'Color',[1 0.5 0.5]);xline(task_boundary,'Color',[1 0.5 0.5]);
xlabel('time (s)')
title([ animal,' ', data_type{used_data}])
colorbar
nexttile
hold on
plot(max(plot_data(:,use_period),[],2))
plot(find(cell2mat(raw_data_task.learned_day)),-0.0015,'.g')
% plot(find(idx_position),-0.001,'.r')
xlabel('day')

saveas(gcf,[Path 'figures\summary\plot_task_' animal], 'jpg');

 


figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}]);
for i=find(idx)
    nexttile
      % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
        imagesc(image_all_mean{i})
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.004 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_task.workflow_day{i}],[workflow_stage{raw_data_task.workflow_type(i)+1} '-' learn_name{raw_data_task.learned_day{i}+1} ])

end
sgtitle([animal,' ', data_type{used_data}])
 saveas(gcf,[Path 'figures\summary\imaging_task_' animal], 'jpg');

figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}]);
for i=find(idx)
    nexttile
      imagesc(image_all_mean{i}-fliplr(image_all_mean{i}))
        % imagesc(image_all_mean{i})
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.004 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_task.workflow_day{i}],[workflow_stage{raw_data_task.workflow_type(i)+1} '-' learn_name{raw_data_task.learned_day{i}+1} ])

end
sgtitle([animal,' ', data_type{used_data}])
% saveas(gcf,[Path 'figures\summary\imaging_passive_' animal], 'jpg');


% idx_position=cellfun(@(x) strcmp(x,'stim_wheel_right_stage2'), raw_data_task.workflow_type_name,'UniformOutput',true  )

% 
% 
% rec_day=27
% curr_imaging=image_all{rec_day};
% ap.imscroll(curr_imaging,use_t)
% axis image off
% ap.wf_draw('ccf','black');
% clim(0.5*max(curr_imaging,[],'all').*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image;
% set(gcf,'name',sprintf('%s %s',animal,raw_data_task.workflow_day{rec_day}));

% if curr_animal==2
%     avg_day=18:27;
% else
%     avg_day=26:27;
% end
% 
% avg_imaging{curr_animal}=mean(cat(5,image_all{avg_day}),5);
% ap.imscroll(avg_imaging{curr_animal},use_t);
% axis image off
% ap.wf_draw('ccf','black');
% clim(0.5*max(avg_imaging{curr_animal},[],'all').*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image;
% set(gcf,'name',sprintf('%s %s',animal,'averaged'));
 end




