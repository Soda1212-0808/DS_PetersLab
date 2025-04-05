clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
% U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_task=find(t_task>0&t_task<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);


animal='DS010';
wokrflow='task';

learn_name={'non-learned','learned'};
workflow_stage={'naive','visual','auditory','mixed'};
legend_name={'-90','0','90';'4k','8k','12k';'-90','0','90';};

used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};
raw_data_task=load([Path '\mat_data\' wokrflow '\' animal '_' wokrflow '.mat']);


if used_data==1
    idx=cellfun(@(x) ~(isempty(x)),raw_data_task.wf_px_task);
    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_task.wf_px_task(idx),'UniformOutput',false);

    use_period=period_task;
    use_t=t_task;
else
    idx=cellfun(@(x) ~(isempty(x)|| ~(size(x,3)==1)),raw_data_task.wf_px_task_kernels);

    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{3})),x{3}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
    use_period=period_kernels;
    use_t=t_kernels;
end

image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
% buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(3).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);


%
% mPFC
figure('Position',[50 50 1000 800],'Name',['plots of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=1:length(idx)
    nexttile
    % if(~isempty(buf3_mPFC{i})) & size(buf3_mPFC{i},2)==1
        hold on
        p=plot(use_t,buf3_mPFC{i});
        xline(0);
        xline(0.15)

        ylim(0.0001*[-1,2])
        title(['day' num2str(i) ' ' raw_data_task.workflow_day{i}],[raw_data_task.workflow_type_name_merge{i} '-' learn_name{(raw_data_task.rxn_stat_p{i}<0.05)+1} ])
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
for i=find(idx)
    nexttile
      % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
      if size(image_all_mean{i},3)==1
        imagesc(image_all_mean{i}(:,:,1))
      end
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.05 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_task.workflow_day{i}],[raw_data_task.workflow_type_name_merge{i} '-' learn_name{(raw_data_task.rxn_stat_p{i}<0.05)+1} ])

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
curr_imaging=image_all{rec_day};
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
buf_image_move=cellfun(@(x) x(:,:,:,2),image_all,'UniformOutput',false);
avg_imaging1=mean(cat(5,buf_image_move{avg_day}),5);
buf_image_itimove=cellfun(@(x) x(:,:,:,4),image_all,'UniformOutput',false);
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
