clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

% Path = 'Y:\Data process\project_cross_model\wf_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
% master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
%     'widefield_alignment','U_master.mat');
% animals={'AP032','DS029','DS030','DS031'};
animals={'DS029','DS030','DS031'};

% workflow_task='stim_wheel_right_stage2_variable_contrast';
workflow_task='stim_wheel_right_stage2_audio_variable_volume_earphone';

kernels_data=table;
kernels_data.name=animals';
for curr_animal_idx=1:length(animals)
    main_preload_vars = who;
    animal=animals{curr_animal_idx};
    
    fprintf('%s\n', ['start  ' animal ]);
    recordings = plab.find_recordings(animal,[],workflow_task);
    wf_px_kernels=cell(length(recordings),1);
    performance=cell(length(recordings),1);
    react_time=cell(length(recordings),1);
    for curr_recording =1:length(recordings)
        preload_vars = who;
        rec_day = recordings(curr_recording).day;
        rec_time = recordings(curr_recording).recording{end};

        load_parts.mousecam = true;
        load_parts.widefield = true;
        load_parts.widefield_master = true;
        ap.load_recording;

        ds.process_wf_task;
        ds.process_behavior;

        wf_px_kernels{curr_recording} = cat(3,kernels.stim_kernels{:});
        performance{curr_recording}=behavior.performance;
        react_time{curr_recording}=behavior.stim2move_l_stats(:,3);
        % Prep for next loop
        ap.print_progress_fraction(curr_recording,length(recordings));
        clearvars('-except',preload_vars{:});

    end
kernels_data.kernels{curr_animal_idx}=cat(4, wf_px_kernels{:});
kernels_data.performance{curr_animal_idx}=cat(2, performance{:});
kernels_data.react_time{curr_animal_idx}=cat(2, react_time{:});
        clearvars('-except',main_preload_vars{:});

end
 % save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\visual_task_variable') ,'kernels_data','-v7.3')
 save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\audio_task_variable') ,'kernels_data','-v7.3')



%%

tempdata{1}= load(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\visual_task_variable.mat'))
tempdata{2}=load(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\audio_task_variable.mat'))

surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);


temp_perform=cellfun(@(s) feval(@(a)  cat(2,a{:}) ,cellfun(@(x) ...
    nanmean(x,2), s.kernels_data.performance,'UniformOutput',false)),tempdata,'uni',false     )

temp_perform_mean=cellfun(@(x) mean(x,2),temp_perform,'UniformOutput',false);
temp_perform_error=cellfun(@(x) std(x,0,2)./sqrt(size(x,2)),temp_perform,'UniformOutput',false);


% temp_rxt=feval(@(a)  cat(2,a{:}) ,cellfun(@(x)     nanmean(x,2), kernels_data.react_time,'UniformOutput',false)     )
% temp_rxt_mean=mean(temp_rxt,2);
% temp_rxt_error=std(temp_rxt,0,2)./sqrt(size(temp_rxt,2));
figure('Position',[50 50 200 200])
hold on
ap.errorfill(1:6,temp_perform_mean{1},temp_perform_error{1},[0 0 1]);
ap.errorfill(1:6,temp_perform_mean{2},temp_perform_error{2},[1 0 0]);
xticks([1 6]);
xticklabels({'min','max'}); % 先清掉默认标签

xlabel('Contrast/Volume')
xlim([1 6])
ylim([0 1])
ylabel('Performance');



nexttile
ap.errorfill(1:6,temp_rxt_mean,temp_rxt_error,[0 0 1]);
ylabel('Reaction time (s)');



U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');
temp_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),kernels_data.kernels,'UniformOutput',false);
temp_image_max= feval(@(x)...
    permute(nanmean(max(x(:,:,t_kernels>0 & t_kernels<0.2,:,:),[],3),5),[1,2,4,3]),cat(5,temp_image{:}));
   
% temp_plot_tace= ds.make_each_roi(cat(6,temp_image{:}), length(t_kernels),roi1);
temp_plot_tace=feval(@(a) cat(4,a{:}), cellfun(@(x)  ds.make_each_roi( nanmean(x,5), length(t_kernels),roi1)  , temp_image,'UniformOutput',false  ));

temp_plot_tace_mean= permute(nanmean(temp_plot_tace,4),[2,3,1]);
temp_plot_tace_error=permute(std(temp_plot_tace,0,4,"omitmissing")./sqrt(size(temp_plot_tace,4)),[2,3,1]);


temp_plot_tace_max=permute(max(temp_plot_tace(:,period,:,:),[],2),[3,1,4,2])
temp_plot_tace_max_mean=nanmean(temp_plot_tace_max,3);
temp_plot_tace_max_error=std(temp_plot_tace_max,0,3)./sqrt(size(temp_plot_tace_max,3));


figure('Position',[50 50 1000 200]);
tiledlayout(1,6,'TileSpacing','none')
for curr_image=1:6
    nexttile
    imagesc( temp_image_max(:,:,curr_image));
    axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(0.00015 .* [ 0, 1]);
    colormap( ap.colormap('WB' ));
end

color_reds = [linspace(1,0.6,6)', linspace(0.8,0,6)', linspace(0.8,0,6)'];
color_blues = [linspace(0.8,0,6)', linspace(0.9,0,6)', linspace(1,0.6,6)'];

figure;
tiledlayout(2,3,'TileIndexing','columnmajor')
for curr_roi=[1 3 7]
    nexttile
ap.errorfill(t_kernels,temp_plot_tace_mean(:,:,curr_roi),temp_plot_tace_error(:,:,curr_roi),color_blues);
xlim([-0.1 0.5])
title(roi1(curr_roi).name)
nexttile
ap.errorfill(1:6,temp_plot_tace_max_mean(:,curr_roi),temp_plot_tace_max_error(:,curr_roi),[0 0 1])
xlim([1 6])
end

