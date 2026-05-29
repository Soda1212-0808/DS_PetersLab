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

% images_max=cellfun(@(x)   nanmean(max(x(:,:,kernels_period,:,:),[],3),[4 5]   ),tem_image,'UniformOutput',false  );
images_max=cellfun(@(x)  max(x(:,:,kernels_period),[],3),image_acorss_time,'UniformOutput',false  );


scale_image=0.0003;
Color={'B','R'};

figure('Position',[50 50 900 300])
tiledlayout (3,length(find(t_kernels>-0.05& t_kernels<0.25)),'TileSpacing','none')

for curr_group=1:2

    for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
        ax=nexttile
        imagesc(image_acorss_time{curr_group}(:,:,curr_frame))
        axis image off;
        clim(scale_image .* [0, 1]);
        colormap(ax, ap.colormap(['W' Color{curr_group}] ));
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        if curr_group==1
            title( num2str(t_kernels(curr_frame),'%.2f'),'FontWeight','normal')
        end

    end
end

for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
    ax=nexttile

    image(ds.colormap_overlay(image_acorss_time{1}(:,:,curr_frame),...
        image_acorss_time{2}(:,:,curr_frame),...
        'B','R',[],scale_image))

    axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
end

exportgraphics(gcf, fullfile(Path,'submission_3_NatureCommunications\revisions\revision_figures\eps\Fig EDF3_a.eps'), ...
    'ContentType','vector');    

figure('Position', [50 50 200 200] );
image(ds.colormap_overlay(images_max{1},...
    images_max{2},...
    'B','R',[],scale_image))
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
exportgraphics(gcf, fullfile(Path,'submission_3_NatureCommunications\revisions\revision_figures\eps\Fig EDF3_b.eps'), ...
    'ContentType','vector');    

load(fullfile(Path,'data','wf_passive_kernels'));

tem_image_pass=cellfun(@(x,id) plab.wf.svd2px(U_master(:,:,1:size(x{id},1)),x{id}(:,:,:,[10 11],:)), ...
    wf_passive_kernels_across_day,{1;2},'UniformOutput',false);

image_pass_acorss_time=cellfun(@(x)    nanmean(x,[5 6]),tem_image_pass,'UniformOutput',false  );
% iamges_passive_max=cellfun(@(x)    nanmean(max(x(:,:,kernels_period,:,:,:),[],[3,4]),[5 6]),tem_image_pass,'UniformOutput',false  );
iamges_passive_max=cellfun(@(x)    max(x(:,:,kernels_period,:),[],[3,4]),image_pass_acorss_time,'UniformOutput',false  );

figure('Position', [50 50 900 700] )
mainfig=tiledlayout(7,1,'TileSpacing','none')
for curr_group=1:2
    subfig=tiledlayout(mainfig,3,sum(t_kernels>-0.05& t_kernels<0.25),'TileSpacing','none');
    subfig.Layout.Tile=3*curr_group-2;
    subfig.Layout.TileSpan = [3 1];      % 跨 2 行 × 1 列

    for curr_stim=1:3
        for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
            ax=nexttile(subfig);
            imagesc(image_pass_acorss_time{curr_group}(:,:,curr_frame,curr_stim));
            axis image off;
            clim(scale_image .* [0, 1]);
            colormap(ax, ap.colormap(['W' Color{curr_group}] ));
            clim(scale_image .* [0, 1]);
            ap.wf_draw('ccf', [0.5 0.5 0.5]);

        end
    end
end
subfig=tiledlayout(mainfig,1,sum(t_kernels>-0.05& t_kernels<0.25),'TileSpacing','none');
subfig.Layout.Tile=7;

for curr_frame=find(t_kernels>-0.05& t_kernels<0.25)
    ax=nexttile(subfig);

    image(ds.colormap_overlay(image_pass_acorss_time{1}(:,:,curr_frame,3),...
        image_pass_acorss_time{2}(:,:,curr_frame,2),...
        'B','R',[],scale_image))

    axis image off;

    ap.wf_draw('ccf', [0.5 0.5 0.5]);

end

exportgraphics(gcf, fullfile(Path,'submission_3_NatureCommunications\revisions\revision_figures\eps\Fig EDF3_c.eps'), ...
    'ContentType','vector');    

figure('Position', [50 50 200 200] );
image(ds.colormap_overlay(iamges_passive_max{1},...
    iamges_passive_max{2},...
    'B','R',[],scale_image))
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);

exportgraphics(gcf, fullfile(Path,'submission_3_NatureCommunications\revisions\revision_figures\eps\Fig EDF3_d.eps'), ...
    'ContentType','vector'); 

figure('Position', [50 50 80 80] );
ds.bi_colorbar('B','R',scale_image)
exportgraphics(gcf, fullfile(Path,'submission_3_NatureCommunications\revisions\revision_figures\eps\Fig EDF3_e.eps'), ...
    'ContentType','vector'); 

