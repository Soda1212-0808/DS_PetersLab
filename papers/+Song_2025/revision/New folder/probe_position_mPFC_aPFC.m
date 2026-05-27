
clear 
Path='D:\Data process\project_cross_model\wf_data\data_package';
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');
U_master = plab.wf.load_master_U;

surround_samplerate = 35;
surround_window_task = [-0.2,1];
task_boundary1=0;
task_boundary2=0.2;

t_kernels=1/surround_samplerate*[-10:30];
kernels_period=find(t_kernels>task_boundary1&t_kernels<task_boundary2);


animals={'DS029','DS030','DS031'};

mPFC_idx={[1 ],[3],[2]};
% mPFC_idx={[2,4],[2,4,5],[3,4,5]}


for curr_animal=1:length(animals)
animal=animals{curr_animal};
temp_path=matfile(fullfile(Path,[animal '_all_data.mat']));
data_idx= temp_path.data_all_index

  day_idx=find(cellfun(@(x) strcmp('stim_wheel_right_stage2_mixed_VA_earphone' ,x), {data_idx.task_name})&...
    ~cellfun(@isempty  ,{data_idx.wf_task}))
% day_idx=22
wf_task=temp_path.wf_task(day_idx,1);


tem_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  wf_task{1}.stim_kernels,'UniformOutput',false);

ap.imscroll(tem_image{1})

tem_image_max=cellfun(@(x)  max(x(:,:,kernels_period),[],3),tem_image,'UniformOutput',false )


figure;
imagesc(tem_image_max{1})
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);



images=ds.colormap_overlay(tem_image{1}(:,:,16),tem_image{2}(:,:,16),'B','R');
figure;
image(images)
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);


temp_audio_passive=temp_path.ehpys_hml_passive_audio_earphone;
temp_visual_passive=temp_path.ehpys_lcr_passive;
temp_task=temp_path.ehpys_task;
temp_behavior=temp_path.behavior_task;
ephys_idx=~cellfun(@isempty ,temp_visual_passive );

ephys_audio=temp_audio_passive(ephys_idx);
ephys_visual=temp_visual_passive(ephys_idx);
ephys_task=temp_task(ephys_idx);
behavior=temp_behavior(ephys_idx);




for curr_day=1:length(mPFC_idx{curr_animal})
      temp_day=mPFC_idx{curr_animal}(curr_day);


response_idx=ephys_visual{temp_day}.response_p{3}>0.95|ephys_audio{temp_day}.response_p{2}>0.95;
depth_idx=ephys_task{temp_day}.depth<2000;
responsive_idx{curr_animal}{curr_day}=response_idx(find(depth_idx));
responsive_visual{curr_animal}{curr_day}=feval(@(a) a((find(depth_idx))), ephys_visual{temp_day}.response_p{3}>0.95);
responsive_audio{curr_animal}{curr_day}=feval(@(a) a((find(depth_idx))), ephys_audio{temp_day}.response_p{2}>0.95);

visual_task{curr_animal}{curr_day}= ephys_task{temp_day}.psth{1}(depth_idx,:);
audio_task{curr_animal}{curr_day}= ephys_task{temp_day}.psth{2}(depth_idx,:);
visual_passive{curr_animal}{curr_day}=ephys_visual{temp_day}.psth{3}(depth_idx,:);
audio_passive{curr_animal}{curr_day}=ephys_audio{temp_day}.psth{2}(depth_idx,:);


end

% 
% figure('Position',[50 50 1400 800])
% tiledlayout(length(ephys_audio),10)
% for curr_day=mPFC_idx{curr_animal}
% 
%     nexttile
%     hold on
%    plot(1:2, behavior{curr_day}.rxn_l_p(:,1)<0.05,'or')
%     bar(1:2 , behavior{curr_day}.performance)
%     nexttile
%     hold on
%     cellfun(@(x) ap.errorfill(1:1001, nanmean(x,1),nanstd(x,0,1)./sqrt(size(x,1))),...
%         behavior{curr_day}.stim_move_aligned_wheel_vel);
% response_idx=ephys_visual{curr_day}.response_p{3}>0.95|ephys_audio{curr_day}.response_p{2}>0.95;
% depth_idx=ephys_task{curr_day}.depth<2000;
% 
%     for curr_passive=1:2
%         nexttile
%         imagesc(ephys_task{curr_day}.psth{curr_passive}(depth_idx,:) )
%         clim([-2 2])
%         colormap(ap.colormap(['PWG']))
%     end
%     for curr_passive=1:3
%         nexttile
%         imagesc(ephys_visual{curr_day}.psth{curr_passive}(depth_idx,:) )
%         clim([-2 2])
%         colormap(ap.colormap(['PWG']))
%     end
% 
%     for curr_passive=1:3
%         nexttile
%         imagesc(ephys_audio{curr_day}.psth{curr_passive}(depth_idx,:) )
%         clim([-2 2])
%         colormap(ap.colormap(['PWG']))
%     end
%     sgtitle(animal)
% end
% drawnow

end

temp_or_idx=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,responsive_idx,'UniformOutput',false ));

temp_v_idx=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,responsive_visual,'UniformOutput',false ));
temp_a_idx=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,responsive_audio,'UniformOutput',false ));

idx_A_only = temp_v_idx & ~temp_a_idx;   % 只属于A
idx_AB     = temp_v_idx & temp_a_idx;    % 同时属于A和B
idx_B_only = ~temp_v_idx & temp_a_idx;   % 只属于B
idx_order = [find(idx_A_only); find(idx_AB); find(idx_B_only)];


temp_v_p=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,visual_passive,'UniformOutput',false ));
temp_a_p=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,audio_passive,'UniformOutput',false ));
temp_v_t=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,visual_task,'UniformOutput',false ));
temp_a_t=feval(@(x)  cat(1,x{:}),cellfun(@(a) cat(1,a{:}) ,audio_task,'UniformOutput',false ));

figure;
tiledlayout(1,2)
A1=nexttile
imagesc(t_bins,[],temp_v_p(idx_order,:) )
clim([0 3])
xlim([-0.2 0.5])
colormap(A1,ap.colormap(['WB']))
yline(size(find(idx_A_only),1),'LineWidth',1,'Color',[0 0 0])
yline(size([find(idx_A_only); find(idx_AB)],1),'LineWidth',1,'Color',[0 0 0])
xline(0)

axis off
A2=nexttile
imagesc(t_bins,[],temp_a_p(idx_order,:) )
clim([0 3])
xlim([-0.2 0.5])
colormap(A2,ap.colormap(['WR']))
yline(size(find(idx_A_only),1),'LineWidth',1,'Color',[0 0 0])
yline(size([find(idx_A_only); find(idx_AB)],1),'LineWidth',1,'Color',[0 0 0])
xline(0)
axis off


temp_v_t_mean=feval(@(x)  cat(1,x{:}),cellfun(@(a) nanmean(cat(1,a{:}),1)  ,visual_task,'UniformOutput',false ));
temp_a_t_mean=feval(@(x)  cat(1,x{:}),cellfun(@(a) nanmean(cat(1,a{:}),1)  ,audio_task,'UniformOutput',false ));



temp_v_p_mean=feval(@(a) cat(1,a{:}), cellfun(@(x) nanmean(x,1),cat(2,visual_passive{:}),'UniformOutput',false));
temp_a_p_mean=feval(@(a) cat(1,a{:}), cellfun(@(x) nanmean(x,1),cat(2,audio_passive{:}),'UniformOutput',false))
figure
hold on
ap.errorfill(t_bins,nanmean(temp_v_p_mean,1),nanstd(temp_v_p_mean,0,1)./sqrt(size(temp_v_t_mean,1)),[0 0 1])
ap.errorfill(t_bins,nanmean(temp_a_p_mean,1),nanstd(temp_a_p_mean,0,1)./sqrt(size(temp_v_t_mean,1)),[1 0 0])
ylim([-0.2 1])
xlim([-0.2 0.5])


