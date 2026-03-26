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



main_preload_vars = who;
load(fullfile(Path,'data','wf_task_kernels'));
tem_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x(:,:,[7 8],:)),  wf_task_kernels_across_day,'UniformOutput',false);
image_acorss_time=cellfun(@(x)    nanmean(x,[4 5]),tem_image,'UniformOutput',false  );
scale_image=0.0003;
Color={'B','R'};

for curr_group=1:2
   figure('Position',[50 50 1800 250])
   tiledlayout (1,length(find(t_kernels>-0.05& t_kernels<0.25)),'TileSpacing','none')
    for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
        ax=nexttile
        imagesc(image_acorss_time{curr_group}(:,:,curr_frame))
        axis image off;
        clim(scale_image .* [0, 1]);
        colormap(ax, ap.colormap(['W' Color{curr_group}] ));
        ap.wf_draw('ccf', [0.5 0.5 0.5]);     
    end

    frame1 = getframe(gcf);
    img_data1{curr_group} =im2double( frame1.cdata);
end
result = min(img_data1{1}, img_data1{2});

figure
imshow(result);






for curr_group=1:2
    figure('Position',[50 50 1800 250])
   tiledlayout (1,length(find(t_kernels>-0.05& t_kernels<0.25)),'TileSpacing','none')

    for curr_stim=4-curr_group
        for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
        ax=nexttile
            imagesc(image_pass_acorss_time{curr_group}(:,:,curr_frame,curr_stim))
            axis image off;
            clim(scale_image .* [0, 1]);
            colormap(ax, ap.colormap(['W' Color{3-curr_group}] ));
            clim(scale_image .* [0, 1]);
            ap.wf_draw('ccf', [0.5 0.5 0.5]);
           
        end
    end
     frame1 = getframe(gcf);
    img_data2{curr_group} =im2double( frame1.cdata);
end

result = min(img_data2{1}, img_data2{2});

figure
imshow(result);

result = min(img_data2{1}, img_data1{1});
figure
imshow(result);