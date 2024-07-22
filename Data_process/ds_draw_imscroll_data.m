clear all

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);

% 指定包含MAT文件的文件夹路径
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\';

% 获取文件夹中所有MAT文件的信息
fileInfo = dir(fullfile(Path, '*.mat'));
% 初始化一个空的结构体
loadedData = struct();
% 遍历每个MAT文件并加载数据
for i = 1:length(fileInfo)
    % 获取MAT文件名
    fileName = fileInfo(i).name;

    % 加载MAT文件中的数据
    data = load(fullfile(Path, fileName));

    % 使用文件名作为结构体字段名，并存储加载的数据
    loadedData.(fileName(1:end-4)) = data; % 去掉文件扩展名(.mat)
end

fields = fieldnames(loadedData);
task_idx = endsWith(fields, 'task');
passive_idx=endsWith(fields,'passive');
all_Values = struct2cell(loadedData);
task_data = [all_Values{task_idx}];
passive_data=[all_Values{passive_idx}];



% data_audio
all_learned_audio =arrayfun(@(idx) cat(2, task_data(idx).data(3).imagedata(task_data(idx).data(3).learned_day)),1:length(task_data),  'UniformOutput', false);
all_nonlearned_audio =arrayfun(@(idx) cat(2, task_data(idx).data(3).imagedata(~task_data(idx).data(3).learned_day)),1:length(task_data),  'UniformOutput', false);
% data_visual
all_learned_visual =arrayfun(@(idx) cat(2, task_data(idx).data(2).imagedata(task_data(idx).data(2).learned_day)),1:length(task_data),  'UniformOutput', false);
all_nonlearned_visual =arrayfun(@(idx) cat(2, task_data(idx).data(2).imagedata(~task_data(idx).data(2).learned_day)),1:length(task_data),  'UniformOutput', false);


wf_px_l_audio = cat(2, all_learned_audio{:});
wf_px_nl_audio = cat(2, all_nonlearned_audio{:});
wf_px_l_visual = cat(2, all_learned_visual{:});
wf_px_nl_visual = cat(2, all_nonlearned_visual{:});

surround_window = [-1,4];
surround_samplerate = 35;
t1 = surround_window(1):1/surround_samplerate:surround_window(2);

b_l_audio = mean(cat(5,wf_px_l_audio{:}),5);
b_nl_audio = mean(cat(5,wf_px_nl_audio{:}),5);

b_l_visual = mean(cat(5,wf_px_l_visual{:}),5);
b_nl_visual = mean(cat(5,wf_px_nl_visual{:}),5);

all_dat=cat(4,b_nl_visual,b_l_visual,b_nl_audio,b_l_audio);

scale0=0.7*max(abs(all_dat(:,:,t1>0&t1<0.1,:)),[],"all");
period1=find(t1>0&t1<0.1);


ap.imscroll(all_dat,t1);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

figure;
for l=1:size(all_dat,4)
    nexttile
    imagesc(max(all_dat(:,:,period1,l),[],3));

    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale0.*[-1,1]); colormap(ap.colormap('PWG'));
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

end

filename = [Path 'visual_audio_task.jpg' ];
saveas(gcf, filename, 'jpg');



%%
% hml_passive_in_audio_task

all_learned_hml_passive =arrayfun(@(idx) cat(2, passive_data(idx).data_passive(4).image(cell2mat(cellfun(@(x) ...
    find(cellfun(@(y) isequal(y, x), passive_data(idx).data_passive(4).recording_date)), ...
    task_data(idx).data(3).recording_date(task_data(idx).data(3).learned_day), 'UniformOutput', false)))), ...
    1:length(passive_data),  'UniformOutput', false);


all_nonlearned_hml_passive =arrayfun(@(idx) cat(2, passive_data(idx).data_passive(4).image(cell2mat(cellfun(@(x) ...
    find(cellfun(@(y) isequal(y, x), passive_data(idx).data_passive(4).recording_date)), ...
    task_data(idx).data(3).recording_date(~task_data(idx).data(3).learned_day), 'UniformOutput', false)))), ...
    1:length(passive_data),  'UniformOutput', false);


wf_px_l_hml_p = cat(2, all_learned_hml_passive{:});
wf_px_nl_hml_p = cat(2, all_nonlearned_hml_passive{:});


wf_px_l_hml_p_re= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px_l_hml_p, 'UniformOutput', false);
wf_px_nl_hml_p_re= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px_nl_hml_p, 'UniformOutput', false);


b_l_hml_p = mean(cat(5,wf_px_l_hml_p_re{find(cellfun(@(x) x(4) == 3, cellfun(@size, wf_px_l_hml_p_re, 'UniformOutput', false)))}),5);
b_nl_hml_p = mean(cat(5,wf_px_nl_hml_p_re{find(cellfun(@(x) x(4) == 3, cellfun(@size, wf_px_nl_hml_p_re, 'UniformOutput', false)))}),5);

all_dat_hml_p_in_audio_task=cat(4,b_nl_hml_p,b_l_hml_p);


%% hml_passive_in visual_task




% lcr_passive_in_visual_task
all_learned_lcr_passive =arrayfun(@(idx) cat(2, passive_data(idx).data_passive(1).image(cell2mat(cellfun(@(x) find(cellfun(@(y) isequal(y, x), passive_data(idx).data_passive(1).recording_date)), task_data(idx).data(2).recording_date(task_data(idx).data(2).learned_day), 'UniformOutput', false)))),1:length(passive_data),  'UniformOutput', false);

all_nonlearned_lcr_passive =arrayfun(@(idx) cat(2, passive_data(idx).data_passive(5).image),1:length(passive_data),  'UniformOutput', false);


wf_px_l_lcr_p = cat(2, all_learned_lcr_passive{:});
wf_px_nl_lcr_p = cat(2, all_nonlearned_lcr_passive{:});


wf_px_l_lcr_p_re= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px_l_lcr_p, 'UniformOutput', false);
wf_px_nl_lcr_p_re= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px_nl_lcr_p, 'UniformOutput', false);



all_dat_lcr_p_in_visual_task=cat(4,mean(cat(5,wf_px_nl_lcr_p_re{:}),5),mean(cat(5,wf_px_l_lcr_p_re{:}),5));


surround_window = [-0.5,1];
surround_samplerate = 35;
t2 = surround_window(1):1/surround_samplerate:surround_window(2);
period=find(t2>0&t2<0.2);
scale=0.6*max(abs(cat(4,all_dat_hml_p_in_audio_task,all_dat_lcr_p_in_visual_task)),[],"all");




% draw audio passive figure
ap.imscroll(all_dat_hml_p_in_audio_task,t2);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

%%  绘制在audio task阶段，non-learner和learner的 hml passive的图像
name_hml={'non-leanred-4k Hz','non-leanred-8k Hz','non-leanred-12k Hz','leanred-4k Hz','leanred-8k Hz','leanred-12k Hz',};
figure;
for l=1:size(all_dat_hml_p_in_audio_task,4)
    nexttile
    imagesc(max(all_dat_hml_p_in_audio_task(:,:,period,l),[],3));

    axis image off;
    ap.wf_draw('ccf','black');
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    title(name_hml{l})
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

end
sgtitle('all-hml-passive in audio task')
filename = [Path 'hml_passive_in_audio_task.jpg' ];
saveas(gcf, filename, 'jpg');


% draw visual passive figure
ap.imscroll(all_dat_lcr_p_in_visual_task,t2);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

%% 绘制在visual task阶段，non-learner和learner的 lcr passive的图像

name_lcr={'non-leanred-L','non-leanred-C','non-leanred-R','leanred-L','leanred-C','leanred-R',};
figure;
for l=1:size(all_dat_lcr_p_in_visual_task,4)
    nexttile
    lcr_passive_img=max(squeeze(all_dat_lcr_p_in_visual_task(:,:,period,l)),[],3);
    % lcr_passive_R=mat2gray(lcr_passive_img);
    imagesc(lcr_passive_img);
    axis image off;
    ap.wf_draw('ccf','black');
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    title(name_lcr{l})
end
sgtitle('all-lcr-passive in visual task')

filename = [Path 'lcr_passive_in_visual_task.jpg' ];
saveas(gcf, filename, 'jpg');




%% save processed data
save([Path 'processed_data.mat'],'all_dat','all_dat_lcr_p_in_visual_task','all_dat_hml_p_in_audio_task','t1','t2','roi1','-v7.3')


%% draw hml+lcr passive merged
vv=max(squeeze(all_dat_lcr_p_in_visual_task(:,:,period,6)),[],3);
vis_passive=mat2gray(vv,[0 1*double(max(vv,[],'all'))]);



red=cat(3,ones(size(vis_passive)),1-vis_passive,1-vis_passive);
% figure;imshow(red)

aa=max(squeeze(all_dat_hml_p_in_audio_task(:,:,period,5)),[],3);
aud_passive=mat2gray(aa,[0 1*double(max(aa,[],'all'))]);





green=cat(3,1-aud_passive,ones(size(aud_passive)),1-aud_passive);
figure;imshow(mean(cat(4,green,red),4))
ap.wf_draw('ccf','black');
saveas(gcf,[Path 'merge_vis&audio'], 'jpg');


figure;imagesc(vv)
axis image off;
clim(max(abs(clim)).*[0,1]); colormap(ap.colormap('WR'));
frame1 = getframe(gcf);


figure;imagesc(aa)
axis image off;
clim(max(abs(clim)).*[0,1]); colormap(ap.colormap('WG'));
frame2 = getframe(gcf); % 获取当前图形窗口的帧

figure;imshow(mean(cat(4,frame1.cdata,frame2.cdata),4)./255)
saveas(gcf,[Path 'merge_vis&audio'], 'jpg');

%% draw ROI
ap.imscroll(all_dat_hml_p_in_audio_task,t2);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));



ap.imscroll(all_dat_lcr_p_in_visual_task,t2);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

% all_roi.lcr_mpfc=roi;
% all_roi.hml_mpfc=roi;
% all_roi.hml_V1=roi;
% all_roi.hml_PPC=roi;

% roi1(1).name='hml mPFC'
% roi1(1).data=all_roi.hml_mpfc;
%
% roi1(2).name='lcr mPFC'
% roi1(2).data=all_roi.lcr_mpfc;
%
% roi1(3).name='lcr_V1'
% roi1(3).data=all_roi.hml_V1;
%
% roi1(4).name='hml PPC'
% roi1(4).data=all_roi.hml_PPC;


for ss=1:length(roi1)

    re_data_visual=reshape(all_dat_lcr_p_in_visual_task,size(all_dat_lcr_p_in_visual_task,1)*size(all_dat_lcr_p_in_visual_task,2),size(all_dat_lcr_p_in_visual_task,3),size(all_dat_lcr_p_in_visual_task,4));
    roi_data_visual=permute(mean(re_data_visual(roi1(ss).data.mask(:),:,:),1),[2,3,1]);
    re_data_audio=reshape(all_dat_hml_p_in_audio_task,size(all_dat_hml_p_in_audio_task,1)*size(all_dat_hml_p_in_audio_task,2),size(all_dat_hml_p_in_audio_task,3),size(all_dat_hml_p_in_audio_task,4));
    roi_data_audio=permute(mean(re_data_audio(roi1(ss).data.mask(:),:,:),1),[2,3,1]);



    all_roi_data=cat(2,roi_data_visual,roi_data_audio);

    scale3=max(abs(cat(2,roi_data_visual,roi_data_audio)),[],"all");

    figure;
    for i=1:6
        nexttile
        plot(t2,roi_data_audio(:,i))
        ylim(scale3.*[-1,1]);
        title('aud')
    end
    for i=1:6
        nexttile
        plot(t2,roi_data_visual(:,i))
        ylim(scale3.*[-1,1]);
        title('vis')
    end
    sgtitle(roi1(ss).name)
end
%% 绘制visual和audio中 hml_audio_passive每一个只小鼠在【0，200ms】的成像图

%先画roi

ap.imscroll(merge_hml,t2)
ap.wf_draw('ccf','black');
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));



period=find(t2>0&t2<0.2);
title_name={'passive 4k Hz in visual','passive 8k Hz in visual','passive 12k Hz in visualz','passive 4k Hz in audio','passive 8k Hz in audio','passive 12k Hz in audio'};
names=fields(passive_idx);
for i=1:size(passive_data,2)
    pre_hml=cat(4,passive_data(i).data_passive(2).image{find(cellfun(@(x) x(3) == 3, cellfun(@size, passive_data(i).data_passive(2).image, 'UniformOutput', false)))});
    post_hml=cat(4,passive_data(i).data_passive(4).image{find(cellfun(@(x) x(3) == 3, cellfun(@size, passive_data(i).data_passive(4).image, 'UniformOutput', false)))});
    merge_hml=cat(3,mean(pre_hml,4),mean(post_hml,4));
    merge_hml_re=plab.wf.svd2px(U_master,merge_hml);
    % ap.imscroll(cat(4,pre_hml,post_hml),t2)
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    scale=0.9*max(abs(merge_hml_re),[],"all");

    figure('Position', [100, 0, 800, 1000]);
    for l=1:size(merge_hml_re,4)
        nexttile

        hml_passive_img=max(merge_hml_re(:,:,period,l),[],3);
        % lcr_passive_R=mat2gray(lcr_passive_img);
        imagesc(hml_passive_img);
        axis image off;
        title(title_name{l})
        ap.wf_draw('ccf','black');
        % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
        clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    end



    for ss=1:3
        nexttile;
        pre_post_hml=plab.wf.svd2px(U_master,cat(4,pre_hml,post_hml));
        line1=size(pre_hml,3)+0.5;

        for cur_roi=2:4
            data_2=squeeze(pre_post_hml(:,:,:,ss,:));
            redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
            roi_data=permute(mean(redata(roi1(cur_roi).data.mask(:),period,:),[1,2]),[3,2,1]);

            y_normalized = (roi_data - min(roi_data)) / (max(roi_data) - min(roi_data));
            plot(y_normalized);hold on

        end



        xline(line1);
        legend('mPFC','V1','PPC','Location', 'eastoutside')
        xlabel('Day');
        ylabel('normalized \DeltaF/F');
        % ylim(1*scale.*[-0.2,1])
        ylim([-1 2])
        % title ('mPFC')



    end

    for ss=1:3
        nexttile;
        pre_post_hml=plab.wf.svd2px(U_master,cat(4,pre_hml,post_hml));
        line1=size(pre_hml,4)+0.5;
        data_2=squeeze(pre_post_hml(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.5*scale.*[-1,1]);
        colorbar
        title('mPFC')
        plot(-0.4,1:size(pre_hml,4),'|r')

        xlabel('time from stim(s)');
        ylabel('Day');

    end

    for ss=1:3
        nexttile;
        pre_post_hml=plab.wf.svd2px(U_master,cat(4,pre_hml,post_hml));
        line1=size(pre_hml,4)+0.5;
        data_2=squeeze(pre_post_hml(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(1).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.9*scale.*[-1,1]);
        colorbar
        title('V1')
        plot(-0.4,1:size(pre_hml,4),'|r')

        xlabel('time from stim(s)');
        ylabel('Day');

    end

    for ss=1:3
        nexttile;
        pre_post_hml=plab.wf.svd2px(U_master,cat(4,pre_hml,post_hml));
        line1=size(pre_hml,4)+0.5;
        data_2=squeeze(pre_post_hml(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(4).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.5*scale.*[-1,1]);
        colorbar

        plot(-0.4,1:size(pre_hml,4),'|r')
        title('PPC')
        xlabel('time from stim(s)');
        ylabel('Day');

    end

    sgtitle([names{i}(9:end-8) ' hml passive in visual & audio task'])
    % saveas(gcf,[Path names{i} '_hml_passive'], 'jpg');

end



%% 绘制visual和audio中 lcr_passive每一个只小鼠在【0，200ms】的成像图

ap.wf_draw('ccf','black');
ap.imscroll(data_2,t2)
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));




period=find(t2>0&t2<0.2);
title_name={'passive L in visual','passive C in visual','passive R in visual','passive L in audio','passive C in audio','passive R in audio'};
names=fields(passive_idx);
for i=1:size(passive_data,2)
    pre_lcr=cat(4,passive_data(i).data_passive(1).image{find(cellfun(@(x) x(3) == 3, cellfun(@size, passive_data(i).data_passive(1).image, 'UniformOutput', false)))});
    post_lcr=cat(4,passive_data(i).data_passive(3).image{find(cellfun(@(x) x(3) == 3, cellfun(@size, passive_data(i).data_passive(3).image, 'UniformOutput', false)))});
    merge_lcr=cat(3,mean(pre_lcr,4),mean(post_lcr,4));
merge_lcr_re=plab.wf.svd2px(U_master,merge_lcr);
    % ap.imscroll(merge,t2)
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));


    scale=0.9*max(abs(merge_lcr_re),[],"all");

    figure('Position', [100, 0, 800, 1000]);

    % 在这里添加你的绘图代码
    for l=1:size(merge_lcr_re,4)
        nexttile

        lcr_passive_img=max(merge_lcr_re(:,:,period,l),[],3);
        % lcr_passive_R=mat2gray(lcr_passive_img);
        imagesc(lcr_passive_img);
        axis image off;
        title(title_name{l})
        ap.wf_draw('ccf','black');
        % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
        clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));

    end




    for ss=1:3
        nexttile;
        pre_post_lcr=plab.wf.svd2px(U_master,cat(4,pre_lcr,post_lcr));
        line1=size(pre_lcr,3)+0.5;
        for cur_roi=2:4
            data_2=squeeze(pre_post_lcr(:,:,:,ss,:));
            redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
            roi_data=permute(mean(redata(roi1(cur_roi).data.mask(:),period,:),[1,2]),[3,2,1]);
            y_normalized = (roi_data - min(roi_data)) / (max(roi_data) - min(roi_data));
            plot(y_normalized);hold on

        end
        xline(line1);
        legend('mPFC','V1','PPC','Location', 'eastoutside')


        xlabel('Day');
        ylabel('normalized \DeltaF/F');
        % ylim(1*scale.*[-0.2,1])
        ylim([-1 2])
        % title ('mPFC')
    end

    for ss=1:3
        nexttile;
        pre_post_lcr=plab.wf.svd2px(U_master,cat(4,pre_lcr,post_lcr));
        line1=size(pre_lcr,4)+0.5;
        data_2=squeeze(pre_post_lcr(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(2).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.5*scale.*[-1,1]);
        colorbar

        plot(-0.4,1:size(pre_lcr,4),'|r')
        title('mPFC')
        xlabel('time from stim(s)');
        ylabel('Day');

    end
    for ss=1:3
        nexttile;
        pre_post_lcr=plab.wf.svd2px(U_master,cat(4,pre_lcr,post_lcr));
        line1=size(pre_lcr,4)+0.5;
        data_2=squeeze(pre_post_lcr(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(3).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.9*scale.*[-1,1]);
        colorbar

        plot(-0.4,1:size(pre_lcr,4),'|r')
        title('V1')
        xlabel('time from stim(s)');
        ylabel('Day');

    end

    for ss=1:3
        nexttile;
        pre_post_lcr=plab.wf.svd2px(U_master,cat(4,pre_lcr,post_lcr));
        line1=size(pre_lcr,4)+0.5;
        data_2=squeeze(pre_post_lcr(:,:,:,ss,:));
        redata=reshape(data_2,size(data_2,1)*size(data_2,2),size(data_2,3),size(data_2,4));
        roi_data_peri=permute(mean(redata(roi1(4).data.mask(:),:,:),1),[2,3,1]);

        imagesc(t2,[],roi_data_peri'); hold on
        clim(0.5*scale.*[-1,1]);
        colorbar

        plot(-0.4,1:size(pre_lcr,4),'|r')
        title('PPC')
        xlabel('time from stim(s)');
        ylabel('Day');

    end

    sgtitle([names{i}(9:end-8) ' lcr passive in visual & audio task'])
    % saveas(gcf,[Path names{i} '_lcr_passive'], 'jpg');

end




