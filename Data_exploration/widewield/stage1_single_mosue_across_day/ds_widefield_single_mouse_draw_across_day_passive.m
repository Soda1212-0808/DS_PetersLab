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
t_kernels=1/surround_samplerate*[-5:30];

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

% animals = {'AP027','AP028','AP029'};
% animals = {'DS005'};

animal='HA003';
% animal='AP027'
workflow_idx=1;
all_workflow={'lcr_passive','hml_passive_audio'};
wokrflow=all_workflow{workflow_idx};

learn_name={'non-learned','learned'};
workflow_stage={'naive','visual','auditory','mixed'};
legend_name={'-90','0','90';'4k','8k','12k'};

used_data=1;% 1 raw data;2 kernels
data_type={'raw','kernels'};
raw_data_lcr1=load([Path '\mat_data\' wokrflow '\' animal '_' wokrflow '.mat']);

matches=unique(raw_data_lcr1.workflow_type_name(4:end)  ,'stable');

if used_data==1
    idx=cellfun(@(x) ~isempty(x),raw_data_lcr1.wf_px);
    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_lcr1.wf_px(idx),'UniformOutput',false);
    use_period=period_passive;
    use_t=t_passive;
else
    idx=cellfun(@(x) ~isempty(x),raw_data_lcr1.wf_px_kernels);

    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x{1}),raw_data_lcr1.wf_px_kernels(idx),'UniformOutput',false);
    use_period=period_kernels;
    use_t=t_kernels;
end

image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
% buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);



% mPFC
figure('Position',[50 50 1000 800],'Name',['plots of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=find(idx)
    nexttile
    if(~isempty(buf3_mPFC{i})) & size(buf3_mPFC{i},2)==3
        hold on
        p=plot(use_t,buf3_mPFC{i});
        colors = {'b', 'k', 'r'}; % 定义颜色
        xline(0);
        xline(0.15)
        set(p, {'Color'}, colors(:)); % 一次性设置线条颜色

        ylim(0.002*[-1,2])
        title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[workflow_stage{raw_data_lcr1.workflow_type(i)+1} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])
    end
end
legend(legend_name{workflow_idx,:}, 'Location', 'bestoutside')
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])

drawnow
saveas(gcf,[Path 'figures\summary\plot_passive_' animal], 'jpg');

figure('Position',[50 50 600 200],'Name',[ animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
nexttile
pp=plot(cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_mPFC(idx),'UniformOutput',false)'))
colors = {'b', 'k', 'r'}; % 定义颜色
set(pp, {'Color'}, colors(:)); % 一次性设置线条颜色

nexttile
imagesc(use_t,[],cell2mat(cellfun(@(x) x(:,3),buf3_mPFC,'UniformOutput',false))')
colormap( ap.colormap('PWG'));
clim(0.004 .* [-1, 1]);
title('L-mPFC')

% 
% % V1
%  buf3_V1(idx)= cellfun(@(z) permute(mean(z(roi1(4).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);
% 
% figure('Position',[50 50 1000 800],'Name',['plots of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
% for i=find(idx)
%     nexttile
%     if(~isempty(buf3_V1{i})) & size(buf3_V1{i},2)==3
%         hold on
% p=plot(use_t,buf3_V1{i});
% colors = {'b', 'k', 'r'}; % 定义颜色
% xline(0);
% xline(0.15)
% set(p, {'Color'}, colors(:)); % 一次性设置线条颜色
% 
% ylim(0.002*[-1,2])
%    title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[workflow_stage{raw_data_lcr1.workflow_type(i)+1} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])
%     end
% end
% legend(legend_name{workflow_idx,:}, 'Location', 'bestoutside')
% sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])
% 
% drawnow
% % saveas(gcf,[Path 'figures\summary\plot_passive_' animal], 'jpg');
% 
% nexttile
% pp=plot(cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_V1(idx),'UniformOutput',false)'))
% colors = {'b', 'k', 'r'}; % 定义颜色
% 
% set(pp, {'Color'}, colors(:)); % 一次性设置线条颜色

%
figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=find(idx)
    nexttile
      % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
        imagesc(image_all_mean{i}(:,:,3))
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.004 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[workflow_stage{raw_data_lcr1.workflow_type(i)+1} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])

end
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])
saveas(gcf,[Path 'figures\summary\imaging_passive_' animal], 'jpg');


mean_image=mean(cat(4,image_all_mean{15:19}),4);
figure;
  imagesc(mean_image(:,:,3))
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.002 .* [0, 1]);



figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=find(idx)
    nexttile
       imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
        % imagesc(image_all_mean{i}(:,:,3))
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(0.004 .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[workflow_stage{raw_data_lcr1.workflow_type(i)+1} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])

end
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])


rec_day=20
curr_imaging=image_all{rec_day};
ap.imscroll(curr_imaging,use_t)
axis image off
ap.wf_draw('ccf','black');
clim(0.5*max(curr_imaging,[],'all').*[-1,1]);
colormap(ap.colormap('PWG'));
axis image;
set(gcf,'name',sprintf('%s %s',animal,raw_data_lcr1.workflow_day{rec_day}));

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
 




% all_avg_imaging=mean(cat(5,avg_imaging{:}),5);
% ap.imscroll(all_avg_imaging,use_t);
% axis image off
% ap.wf_draw('ccf','black');
% clim(0.7*max(all_avg_imaging,[],'all').*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image;
