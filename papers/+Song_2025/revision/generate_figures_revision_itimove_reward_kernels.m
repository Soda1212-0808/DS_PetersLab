%% Generate figures for Song et al 2025
clear all
clc
Path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025';

% Path='D:\Data process\slide\papers';
U_master = plab.wf.load_master_U;
% load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
load(fullfile(Path,'data\General_information\roi.mat'))
surround_samplerate = 35;
surround_window_task = [-0.2,1];
task_boundary1=0;
task_boundary2=0.2;

t_kernels=1/surround_samplerate*[-10:30];
kernels_period=find(t_kernels>task_boundary1&t_kernels<task_boundary2);

t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);



%%  movement and reward decoding kernels

main_preload_vars = who;

load_dataset='wf_task_kernels';
load(fullfile(Path,'data','revision/',load_dataset));

tem_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  wf_task_kernels_move_iti_across_day,'UniformOutput',false);
% tem_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  wf_task_kernels_reward_across_day,'UniformOutput',false);

tem_image_video=cellfun(@(x)   cat(4,nanmean(x(:,:,:,[1:3],:),[4,5]), nanmean(x(:,:,:,[4:8],:),[4,5])),   tem_image, 'UniformOutput',false )


scale_image=0.0002;
Color={'B','R'};
figure('Position', [50 50 900 400] )
mainfig=tiledlayout(4,1,'TileSpacing','none')
for curr_group=1:2

    for curr_stage=1:2
            subfig=tiledlayout(mainfig,1,sum(t_kernels>-0.1& t_kernels<0.2),'TileSpacing','none')

    subfig.Layout.Tile=2*curr_group+curr_stage-2;
    for curr_frame=find(t_kernels>-0.1& t_kernels<0.2)
        ax=nexttile(subfig)
        imagesc(tem_image_video{curr_group}(:,:,curr_frame,curr_stage))
        axis image off;
        clim(scale_image .* [0, 1]);
        colormap(ax, ap.colormap(['W' Color{curr_group}] ));
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        if curr_group==1& curr_stage==1
            title( num2str(t_kernels(curr_frame),'%.2f'),'FontWeight','normal')
        end

    end
    end
end


% 
% ap.imscroll(tem_image_video{2},t_kernels)
% axis image off
% clim( 0.0003*[-1,1]);
% ap.wf_draw('ccf',[0.5 0.5 0.5]);
% colormap( ap.colormap(['BWR']));
% % set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));
% 
% 
% 
% image_max_eachmice=cellfun(@(x) cat(3,  nanmean(max(x(:,:,kernels_period,[2 3]  ,:),[],3),[4 5]),...
%     nanmean(max(x(:,:,kernels_period,[7 8],:),[],3),[4 5])),tem_image,'UniformOutput',false  );
% 
% % drawnow
% figure('Position',[50 50 700 600])
% imagelayout = tiledlayout(2,2,'TileSpacing','tight','Padding','tight');
% colors = {'B','R'};
% titles = {'pre learned','well trained'};
% 
% axs = gobjects(2,2);                 % 存轴句柄
% for curr_group=1:2
%     for curr_stage=1:2
%         ax = nexttile(imagelayout);
%         axs(curr_group,curr_stage) = ax;
%         imagesc(ax, image_max_eachmice{curr_group}(:,:,curr_stage))
%         axis(ax,'image','off')
%         clim(ax, 0.0003*[0,1]);
%         ap.wf_draw('ccf',[0.5 0.5 0.5]);
%         colormap(ax, ap.colormap(['W' colors{curr_group}]));
%         if curr_group==1
%             title(ax, titles{curr_stage},'FontSize',10,'FontWeight','normal')
%         end
%     end
% end
% 
% % —— 每一行右侧放一个 colorbar（图像外面），高度=子图高度的1/3 ——
% drawnow;                             % 先让布局稳定
% gap = 0.01;                          % 与子图的水平间距
% cbw = 0.02;                          % colorbar 的宽度（归一化坐标）
% shrink = 1/3;                        % 高度比例
% 
% for r = 1:2
%     ax = axs(r,2);                   % 每行最后一个（右侧）子图
%     p = ax.Position;                 % [x y w h] 归一化
%     cb = colorbar(ax);               % 关联该轴（继承其 CLim 和 colormap）
%     cb.Units = 'normalized';
%     h = p(4)*shrink;                 % colorbar 高度=子图高度的1/3
%     x = p(1) + p(3) + gap-0.01;           % 放在子图右侧，留一点间隙
%     y = p(2) ;           % 垂直居中（也可改为 y=p(2) 贴底）
%     cb.Position = [x, y, cbw, h];
% end
% drawnow;

%%

load(fullfile(Path,'data','behavior'));






%%

tem_image_kernels=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  wf_px_task_kernels,'UniformOutput',false);
temp_each_roi_kernels=cellfun(@(x) ds.make_each_roi(x, length(t_kernels),roi1),tem_image_kernels,'UniformOutput',false);


tem_image_raw=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  wf_px_task_raw,'UniformOutput',false);
temp_each_roi_raw=cellfun(@(x) ds.make_each_roi(x, length(t_task),roi1),tem_image_raw,'UniformOutput',false);

% tem_image_raw=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:200),x(1:200,:,:)),  wf_px_task_all,'UniformOutput',false);

figure;
nexttile
yyaxis left
plot(t_kernels,permute(temp_each_roi_kernels{3}(1,:,:),[2,3,1]))
xlim([-0.1 0.5])
nexttile
yyaxis right
plot(t_task,permute(temp_each_roi_raw{3}(1,:,:),[2,3,1]))
xlim([-0.1 0.5])

ap.imscroll(tem_image_kernels{16})
axis image off
clim( 0.0003*[0,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap(['WR']));


tem_data=permute(temp_each_roi_raw{4}(3,:,:),[3,2,1]);
[temp_plot,idx]=sort(stim2move_correct{4});
figure;
imagesc(t_task,[],tem_data(idx,:));
hold on
plot(temp_plot,1:length(temp_plot))
colormap( ap.colormap(['KWR']));
clim( 0.02*[-1,1]);


