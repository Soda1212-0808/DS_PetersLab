clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
% U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];

boundary=0.2;
period_task=find(t_task>0&t_task<boundary);
period_kernels=find(t_kernels>0&t_kernels<boundary);

animals={'HA000','HA001','HA002'}
 animals={'HA003','HA004','DS019','DS020'}
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
     image_Vpassive(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x)),x),raw_data_Vpassive.wf_px_kernels(idx),'UniformOutput',false);
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
    raw_data_behavior.rxn_f_stat_p(:,1)<0.05,2,'last'));

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
    clim(0.0003 .* [0, 1]);
    % xlim([0 213])

end

end



temp_image1=vertcat(all_image{:});
temp_image2=nanmean(cat(3,temp_image1{:}),3);
figure;
imagesc(temp_image2)
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
colormap( ap.colormap('WB'));
clim(0.0004 .* [0, 1]);







for curr_day=find(idx)
    nexttile(t2,length(image_task_mean)*(curr_stim+1)+curr_day)
        imagesc(image_V_mean{curr_day}(:,:,3))
   
        axis image off;
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        colormap( ap.colormap('WG'));
        clim(0.0003 .* [0, 1]);
 
end




sgtitle(animal)
colorbar










%
% mPFC
figure('Position',[50 50 1000 800],'Name',['plots of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for curr_day=1:length(idx)
    nexttile
    % if(~isempty(buf3_mPFC{i})) & size(buf3_mPFC{i},2)==1
        hold on
        p=plot(use_t,buf3_mPFC{curr_day});
        xline(0);
        xline(0.15)

        ylim(0.0001*[-1,2])
        title(['day' num2str(curr_day) ' ' raw_data_task.workflow_day{curr_day}],[raw_data_task.workflow_type_name_merge{curr_day} '-' learn_name{(raw_data_task.rxn_stat_p{curr_day}<0.05)+1} ])
    % end
end

% legend(legend_name{workflow_idx,:}, 'Location', 'bestoutside')
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])

drawnow
% saveas(gcf,[Path 'figures\summary\plot_passive_' animal], 'jpg');

figure('Position',[50 50 600 200],'Name',[ animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);

nexttile
pp=plot(cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_mPFC(idx),'UniformOutput',false)'))

nexttile
imagesc(use_t,[],cell2mat(cellfun(@(x) x,buf3_mPFC(idx),'UniformOutput',false))')
colormap( ap.colormap('PWG'));
clim(0.0001 .* [-1, 1]);
title('L-mPFC')
sgtitle(animal)
colorbar
% saveas(gcf,[Path 'figures\summary\plot_mpfc_passive_' animal], 'jpg');



figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for curr_day=find(idx)
    nexttile
      % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
      if size(image_task_mean{curr_day},3)==1
        imagesc(image_task_mean{curr_day}(:,:,1))
      end
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.0002 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(curr_day) ' ' raw_data_task.workflow_day{curr_day}],[raw_data_task.workflow_type_name_merge{curr_day} '-' learn_name{(raw_data_task.rxn_stat_p{curr_day}<0.05)+1} ])

end
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])
colorbar
% saveas(gcf,[Path 'figures\summary\imaging_passive_' animal], 'jpg');


% mean_image=mean(cat(4,image_all_mean{15:19}),4);
% figure;
%   imagesc(mean_image(:,:,3))
%      axis image off;
%     ap.wf_draw('ccf', 'black');
%     colormap( ap.colormap('WG'));
%     clim(0.002 .* [0, 1]);
% 
% 
% 
% figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
% for i=find(idx)
%     nexttile
%        imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
%         % imagesc(image_all_mean{i}(:,:,3))
%      axis image off;
%     ap.wf_draw('ccf', 'black');
%     colormap( ap.colormap('WG'));
%     clim(0.004 .* [0, 1]);
%     % xlim([0 213])
% 
%    title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[workflow_stage{raw_data_lcr1.workflow_type(i)+1} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])
% 
% end
% sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])


rec_day=9
curr_imaging=image_task{rec_day};
ap.imscroll(curr_imaging(:,:,:,1),use_t)
axis image off
ap.wf_draw('ccf','black');
clim(0.5*max(curr_imaging,[],'all').*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
set(gcf,'name',sprintf('%s %s',animal,raw_data_task.workflow_day{rec_day}));
colorbar
% if curr_animal==2
%     avg_day=18:27;
% else
     avg_day=6:8;
% end
% % 
buf_image_move=cellfun(@(x) x(:,:,:,2),image_task,'UniformOutput',false);
avg_imaging1=mean(cat(5,buf_image_move{avg_day}),5);
buf_image_itimove=cellfun(@(x) x(:,:,:,4),image_task,'UniformOutput',false);
avg_imaging2=mean(cat(5,buf_image_itimove{avg_day}),5);

avg_imaging=avg_imaging1-avg_imaging2;

ap.imscroll(avg_imaging,use_t);
axis image off
ap.wf_draw('ccf','black');
clim(0.5*max(avg_imaging,[],'all').*[-1,1]);
% clim(0.05.*[-1,1]);

colormap(ap.colormap('PWG'));
axis image;
set(gcf,'name',sprintf('%s %s',animal,'averaged'));





% all_avg_imaging=mean(cat(5,avg_imaging{:}),5);
% ap.imscroll(all_avg_imaging,use_t);
% axis image off
% ap.wf_draw('ccf','black');
% clim(0.7*max(all_avg_imaging,[],'all').*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image;
