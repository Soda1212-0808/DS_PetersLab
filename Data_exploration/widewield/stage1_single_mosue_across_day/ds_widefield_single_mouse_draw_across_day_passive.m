clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
% master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
%     'widefield_alignment','U_master.mat');
% load(master_U_fn);
U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

% animals = {'AP027','AP028','AP029'};
% animals = {'DS005'};
% animal='DS003';
% animal='DS001'
 % animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016','HA000','HA001','HA002','HA003','HA004','AP027','AP028','AP029','DS019','DS020','DS021'};
 % animals = {'HA001','HA002','HA003','HA004','AP027','AP028','AP029','DS019','DS020','DS021'};
            % animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';

 animals={'DS004'}
for curr_animal=1:length(animals)
animal=animals{curr_animal}
all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
% workflow_idx=1;
for workflow_idx=2;
wokrflow=all_workflow{workflow_idx};

learn_name={'non-learned','learned'};
legend_name={'-90','0','90';'4k','8k','12k';'-90','0','90';};

used_data=2;% 1 raw data;2 kernels
data_type={'raw','kernels'};
raw_data_lcr1=load([Path '\mat_data\' wokrflow '\' animal '_' wokrflow '.mat']);

if workflow_idx==1|workflow_idx==3
    used_id=3;used_roi=1;
elseif workflow_idx==2
    if ismember('audio volume',raw_data_lcr1.workflow_type_name_merge)

        used_id=2;used_roi=3;
    elseif ismember('audio frequency',raw_data_lcr1.workflow_type_name_merge)

        used_id=3;used_roi=3;
    end
    
end
% matches=unique(raw_data_lcr1.workflow_type_name(4:end)  ,'stable');

if used_data==1
    idx=cellfun(@(x) ~(isempty(x)|| ~(size(x,3)==3)),raw_data_lcr1.wf_px);
    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_lcr1.wf_px(idx),'UniformOutput',false);
        % image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_lcr1.wf_px_01s(idx),'UniformOutput',false);

    use_period=period_passive;
    use_t=t_passive;
else
    idx=cellfun(@(x) ~(isempty(x)|| ~(size(x,3)==3)),raw_data_lcr1.wf_px_kernels);

    image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),raw_data_lcr1.wf_px_kernels(idx),'UniformOutput',false);
    use_period=period_kernels;
    use_t=t_kernels;
end

image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
% buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
buf3_mPFC(idx)= cellfun(@(z) permute(mean(z(roi1(used_roi).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);

%
scale=[0.004 0.0001];
% mPFC
figure('Position',[50 50 1000 800],'Name',['plots of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=find(idx)
    nexttile
    if(~isempty(buf3_mPFC{i})) & size(buf3_mPFC{i},2)==3
        hold on
        p=plot(use_t,buf3_mPFC{i});
        colors = {'b', 'k', 'r'}; % 定义颜色
        xline(0);
        xline(0.2)
        set(p, {'Color'}, colors(:)); % 一次性设置线条颜色

        ylim(scale(used_data)*[-1,2])
        title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[raw_data_lcr1.workflow_type_name_merge{i} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])
    end
end
legend(legend_name{workflow_idx,:}, 'Location', 'bestoutside')
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])

drawnow
saveas(gcf,[Path 'figures\summary\plot_passive_' animal], 'jpg');
% 
figure('Position',[50 50 600 200],'Name',[ animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);

nexttile
pp=plot(cell2mat(cellfun(@(x) max(x(use_period,:),[],1),buf3_mPFC(idx),'UniformOutput',false)'))
colors = {'b', 'k', 'r'}; % 定义颜色
set(pp, {'Color'}, colors(:)); % 一次性设置线条颜色

nexttile
imagesc(use_t,[],cell2mat(cellfun(@(x) x(:,used_id),buf3_mPFC(idx),'UniformOutput',false))')
colormap( ap.colormap('PWG'));
clim(scale(used_data) .* [-1, 1]);
title('L-mPFC')
sgtitle(animal)
saveas(gcf,[Path 'figures\summary\plot_mpfc_passive_' animal], 'jpg');



figure('Position',[50 50 1000 800],'Name',['images of ' animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')]);
for i=find(idx)
    nexttile
      % imagesc(image_all_mean{i}(:,:,3)-fliplr(image_all_mean{i}(:,:,3)))
      if size(image_all_mean{i},3)==3
        imagesc(image_all_mean{i}(:,:,used_id))
      end
     axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( ap.colormap('WG'));
    clim(scale(used_data) .* [0, 1]);
    % xlim([0 213])

   title(['day' num2str(i) ' ' raw_data_lcr1.workflow_day{i}],[raw_data_lcr1.workflow_type_name_merge{i} '-' learn_name{raw_data_lcr1.learned_day(i)+1} ])

end
sgtitle([animal,' ', data_type{used_data}, ' ' strrep(wokrflow,'_','-')])
saveas(gcf,[Path 'figures\summary\imaging_passive_' animal], 'jpg');


% rec_day=20
% curr_imaging=image_all{rec_day};
% ap.imscroll(curr_imaging,use_t)
% axis image off
% ap.wf_draw('ccf','black');
% clim(0.1*max(curr_imaging,[],'all').*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image;
% set(gcf,'name',sprintf('%s %s',animal,raw_data_lcr1.workflow_day{rec_day}));

end
end