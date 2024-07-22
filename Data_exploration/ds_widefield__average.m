
%%
clear all
 animals = {'DS003','DS004','DS000'};
 % animals = {'AP018','AP019','AP020','AP021','AP022','DS001'};
 % animals = {'AP019','AP021','AP022','DS001'};
 % animals = {'AP019','AP021'};
  % animals = {'DS000'};

 % animals = {'AP022'};

Path='C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
period=find(t>0&t<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);

visual_audio_passive_img_l = cell(size(animals));
audio_audio_passive_img_l = cell(size(animals));

visual_audio_passive_img_nl = cell(size(animals));
audio_audio_passive_img_nl = cell(size(animals));
audio_audio_passive_img = cell(size(animals));

visual_visual_passive_img_l = cell(size(animals));
audio_visual_passive_img_l = cell(size(animals));
visual_visual_passive_img_nl = cell(size(animals));
audio_visual_passive_img_nl = cell(size(animals));
audio_visual_passive_img = cell(size(animals));
Mixed_audio_passive_img_l= cell(size(animals));
Mixed_visual_passive_img_l= cell(size(animals));
Mixed_audio_passive_img_nl= cell(size(animals));
Mixed_visual_passive_img_nl= cell(size(animals));


for i=1:length(animals)


    % Grab pre-load vars
    preload_vars = who;

    load([Path  animals{i} '_hml_passive_audio']);
    wf_px_pro= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px, 'UniformOutput', false);

    % % 创建一个匿名函数来寻找每个元素中值为 1 的索引
    % find_8000 = @(element) find(element == 8000);
    % % 使用 cellfun 处理每个元素
    % indx_8000 =cellfun(find_8000, all_groups_name, 'UniformOutput', false);
    % % 创建一个函数来根据 B 中的值选择索引
    % select_index = @(element_A, index_B) element_A(:,:,:,index_B);
    % % 使用 cellfun 处理每个元素
    % selected_images = cellfun(select_index, wf_px_pro', indx_8000, 'UniformOutput', false);

    % %缩减成一句话
    % selected_images = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px', cellfun(@(element) find(element == 8000), all_groups_name, 'UniformOutput', false), 'UniformOutput', false);

    %去除8kHz passive时没有still trial的数据
    indx= find(~cellfun('isempty', (cellfun(@(element) find(element ==8000), all_groups_name, 'UniformOutput', false))));
    selected_images = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_pro', cellfun(@(element) find(element == 8000), all_groups_name, 'UniformOutput', false), 'UniformOutput', false);
    selected_images=selected_images(indx);
    workflow_type_index=workflow_type(indx);
    learned_day_index=learned_day(indx);



    visual_audio_passive_img_l{i} =selected_images(learned_day_index(:)==1 & workflow_type_index(:)==1);
    audio_audio_passive_img_l{i}=selected_images(learned_day_index(:)==1 & workflow_type_index(:)==2);

    visual_audio_passive_img_nl{i} =selected_images(learned_day_index(:)==0 & workflow_type_index(:)==1);
    audio_audio_passive_img_nl{i}=selected_images(learned_day_index(:)==0 &workflow_type_index(:)==2);

        audio_audio_passive_img{i}=selected_images( workflow_type_index(:)==2);

    Mixed_audio_passive_img_l{i}=selected_images( workflow_type_index(:)==3 &learned_day_index(:)==1 );
    Mixed_audio_passive_img_nl{i}=selected_images( workflow_type_index(:)==3 &learned_day_index(:)==0 );

    ap.print_progress_fraction(i,length(animals));
    clearvars('-except',preload_vars{:});


    preload_vars = who;
    load([Path   animals{i} '_lcr_passive']);
    wf_px_pro= cellfun(@(x) plab.wf.svd2px(U_master,x), wf_px, 'UniformOutput', false);

    %去除Right visual passive时没有still trial的数据
    indx= find(~cellfun('isempty', (cellfun(@(element) find(element ==90), all_groups_name, 'UniformOutput', false))));
    selected_images = cellfun( @(element_A, index_B) element_A(:,:,:,index_B), wf_px_pro', cellfun(@(element) find(element == 90), all_groups_name, 'UniformOutput', false), 'UniformOutput', false);
    selected_images=selected_images(indx);
    workflow_type_index=workflow_type(indx);
    learned_day_index=learned_day(indx);

    visual_visual_passive_img_l{i}=selected_images(learned_day_index(:)==1 & workflow_type_index(:)==1);
    audio_visual_passive_img_l{i}=selected_images(learned_day_index(:)==1 & workflow_type_index(:)==2);

    visual_visual_passive_img_nl{i}=selected_images(learned_day_index(:)==0 & workflow_type_index(:)==1);
    audio_visual_passive_img_nl{i}=selected_images(learned_day_index(:)==0 & workflow_type_index(:)==2);
    audio_visual_passive_img{i}=selected_images( workflow_type_index(:)==2);

    Mixed_visual_passive_img_l{i}=selected_images( workflow_type_index(:)==3&learned_day_index(:)==1);
    Mixed_visual_passive_img_nl{i}=selected_images( workflow_type_index(:)==3&learned_day_index(:)==0);


    ap.print_progress_fraction(i,length(animals));
    clearvars('-except',preload_vars{:});
end


%% 平均所有 learned 或者 non-learned day 的images


buffer =vertcat(audio_audio_passive_img_nl{:});
a_a_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
a_a_avg_nl=mean(cat(5,a_a_nl{:}),5);

buffer =vertcat(audio_audio_passive_img_l{:});
a_a_l = buffer(cellfun(@(c) ~isempty(c), buffer));
a_a_avg_l=mean(cat(5,a_a_l{:}),5);


buffer =vertcat(visual_visual_passive_img_nl{:});
v_v_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
v_v_avg_nl=mean(cat(5,v_v_nl{:}),5);

buffer =vertcat(visual_visual_passive_img_l{:});
v_v_l = buffer(cellfun(@(c) ~isempty(c), buffer));
v_v_avg_l=mean(cat(5,v_v_l{:}),5);



buffer =vertcat(audio_visual_passive_img_nl{:});
a_v_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
a_v_avg_nl=mean(cat(5,a_v_nl{:}),5);

buffer =vertcat(audio_visual_passive_img_l{:});
a_v_l = buffer(cellfun(@(c) ~isempty(c), buffer));
a_v_avg_l=mean(cat(5,a_v_l{:}),5);


buffer =vertcat(visual_audio_passive_img_nl{:});
v_a_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
v_a_avg_nl=mean(cat(5,v_a_nl{:}),5);

buffer =vertcat(visual_audio_passive_img_l{:});
v_a_l = buffer(cellfun(@(c) ~isempty(c), buffer));
v_a_avg_l=mean(cat(5,v_a_l{:}),5);


%% 做视频

% 创建一个 VideoWriter 对象，指定文件名和格式
scale=0.003;
videoFilename = ['\visual_auditory_passive_' strjoin(animals, '_') '.avi'];
video = VideoWriter([Path videoFilename], 'Uncompressed AVI');  % 可以根据需要选择不同的格式
video.FrameRate = 10;  % 设置帧率
% 打开 VideoWriter 对象以进行写入
open(video);
% 读取图像序列并写入视频
for k = 1:size(v_v_avg_l,3)
    
    ap.imscroll(v_v_avg_l(:,:,k),t(k));
    axis image off;
     ap.wf_draw('ccf','black');
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image1 = frame.cdata;

   ap.imscroll(a_a_avg_l(:,:,k),t(k));
    axis image off;
     ap.wf_draw('ccf','black');
    clim(0.2*scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image2 = frame.cdata;

    %  ap.imscroll((v_v_avg_l(:,:,k)-a_a_avg_l(:,:,k)),t(k));
    % axis image off;
    %  ap.wf_draw('ccf','black');
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % % 获取当前图像帧
    % frame = getframe(gca);
    % % 提取图像数据
    % image3 = frame.cdata;


    
    image_all=[image1 image2 ];



    [height, width, ~] = size(image_all);
    titleHeight = 30;  % 标题区域的高度
    newImage = uint8(zeros(height + titleHeight, width, 3));
    % 将原始图像复制到新图像中
    newImage(titleHeight+1:end, :, :) = image_all;
    % 在新图像的标题区域填充背景色（例如，黑色）
    newImage(1:titleHeight, :, :) = 255;
    % 在新图像上添加标题
    position = [width/2, titleHeight/2];  % 标题位置
    titleText=[strjoin(animals, '_') ' ' num2str(t(k))];
    newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
        'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
        'AnchorPoint', 'Center');
    % 将图像写入视频文件
    writeVideo(video, newImageWithText);
    close all
end
% 关闭 VideoWriter 对象
close(video);
disp('视频保存完成。');



%% 作图 全部平均的图
scale=0.004;
figure('Position',[50 50 1000 500]) ;
subplot(2,4,1)
% nexttile;
imagesc(max(v_v_avg_nl(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('V V non-learned')

subplot(2,4,2)
% nexttile;
imagesc(max(v_v_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('V V learned')

% nexttile;
subplot(2,4,3)
if ~isempty(a_v_avg_nl)
imagesc(max(a_v_avg_nl(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWR'));title ('A V non-learned')
end
% nexttile;
subplot(2,4,4)
if ~isempty(a_v_avg_l)
imagesc(max(a_v_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG')); title ('A V learned')
end
% nexttile;
subplot(2,4,5)
if ~isempty(v_a_avg_nl)
imagesc(max(v_a_avg_nl(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('V A non-learned')
end
% nexttile;
subplot(2,4,6)
imagesc(max(v_a_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('V A learned')

% nexttile;
subplot(2,4,7)
if ~isempty(a_a_avg_nl)
imagesc(max(a_a_avg_nl(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));    title ('A A non-learned')
end
% nexttile;
subplot(2,4,8)
if ~isempty(a_a_avg_l)
imagesc(max(a_a_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('A A learned')
end
sgtitle(strjoin(animals, ' ; '))
saveas(gcf,[Path 'all_averaged images_' strjoin(animals, '_')], 'jpg');


ap.imscroll(a_a_avg_l,t)
axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('A A learned')

ap.imscroll(v_v_avg_l,t)
axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('A A learned')




%% mPFC activity across days in visual passive task

buffer = cellfun(@(x) x(:,:,:,1:7) , cellfun(@(x) cat(4, x{:}), audio_visual_passive_img, 'UniformOutput', false), 'UniformOutput', false);
a_v_5=cat(5,buffer{:});

% data_b=squeeze(mean(a_v_5(:,:,period,:),3));
buffer = cellfun(@(x) x(:,:,:,1:4) , cellfun(@(x) cat(4, x{:}), visual_visual_passive_img_l, 'UniformOutput', false), 'UniformOutput', false);
v_v_l_5=cat(5,buffer{:});

redata=reshape(a_v_5,size(a_v_5,1)*size(a_v_5,2),size(a_v_5,3),size(a_v_5,4),size(a_v_5,5));
roi_data_peri_av=squeeze(mean(redata(roi1(1).data.mask(:),:,:,:),1));

redata=reshape(v_v_l_5,size(v_v_l_5,1)*size(v_v_l_5,2),size(v_v_l_5,3),size(v_v_l_5,4),size(v_v_l_5,5));
roi_data_peri_vvl=squeeze(mean(redata(roi1(1).data.mask(:),:,:,:),1));

figure;
nexttile;
imagesc(t,[],mean(roi_data_peri_vvl,3)')
clim(0.002*[0,1]);colormap(ap.colormap('WG'));
title('visual task learned day 1-5')
xlabel('Time from stim')
nexttile;
imagesc(t,[],mean(roi_data_peri_av,3)')
clim(0.002*[0,1]);colormap(ap.colormap('WG'));
title('auditory task day 1-5')
xlabel('Time from stim')
colorbar
nexttile;
merge_Data=[roi_data_peri_vvl roi_data_peri_av];
plot_Data=squeeze(max(merge_Data(period,:,:),[],1))';
avg = mean(plot_Data, 1); % 计算每行的平均值
std_err = std(plot_Data, 0, 1) / sqrt(size(plot_Data, 1)); % 计算每行的标准误差
x=size(avg,2);
errorbar( 1:x,avg, std_err, '-');
xlim([1 10])
xlabel('days')
sgtitle(strjoin(animals, ' ; '))
saveas(gcf,[Path 'mPFC activity from visual to auditory tasks during visual passive tasks' strjoin(animals, '_')], 'jpg');


%% merged figures
figure;
scale1=0.004;
imagesc(max(a_a_avg_l(:,:,period),[],3));
axis image off;
clim(scale1.*[0,1]); colormap(ap.colormap('WR'));
% colorbar
saveas(gcf,[Path 'processed_data_v2\figures\merged_image_audio'], 'jpg');
frame1 = getframe(gcf);
img_data1 =im2double( frame1.cdata);
figure;
scale2=0.006;
h=imagesc(max(v_v_avg_l(:,:,period),[],3));
axis image off;
clim(scale2.*[0,1]); colormap(ap.colormap('WG'));
% colorbar
saveas(gcf,[Path 'merged_image_visual'], 'jpg');
frame2 = getframe(gcf);
img_data2 =im2double( frame2.cdata);
result = min(img_data1, img_data2);

imshow(result);
saveas(gcf,[Path 'merged_image_V_A'], 'jpg');




%% 寻找mPFC的hot spot
data_audio=max(a_a_avg_l(:,:,period),[],3);
data_audioB=data_audio;

data_audioB(data_audioB>mean(data_audioB(find(roi1(5).data.mask==1)))&roi1(5).data.mask==1)=1;
data_audioB(data_audioB<1)=0;
figure;
imagesc(data_audioB)
axis image off;
ap.wf_draw('ccf','black');
clim(max(abs(clim)).*[0,1]);colormap(ap.colormap('WR'));
saveas(gcf,[Path 'hotspot in mPFC during auditory task'], 'jpg');

data_visual=max(v_v_avg_l(:,:,period),[],3);
data_visualB=data_visual;
data_visualB(data_visualB>mean(data_visualB(find(roi1(5).data.mask==1)))&roi1(5).data.mask  ==1)=1;
data_visualB(data_visualB<1)=0;
figure;
imagesc(data_visualB)
axis image off;
ap.wf_draw('ccf','black');
clim(0.0001*max(abs(clim)).*[0,1]);colormap(ap.colormap('WG'));
saveas(gcf,[Path 'hotspot in mPFC during visual task'], 'jpg');






%%

figure('Position', [50, 50, 1800, 900]);
tiledlayout(2,5);
scale=0.008;

for ss=1:5

    % 使用 cellfun 计算每个矩阵中第 n 个元素的平均值
    average_matrix = cellfun(@(matrix) matrix{ss},audio_visual_passive_img_l, 'UniformOutput', false);

    % 计算平均值
    average_matrix = mean( cat(4, average_matrix{:}), 4);

    nexttile;
    imagesc(max(average_matrix(:,:,period),[],3));
    axis image off;

    ap.wf_draw('ccf','black');
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    % colorbar
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    title(['Auditory day ' num2str(ss)])
    redata=reshape(average_matrix,size(average_matrix,1)*size(average_matrix,2),size(average_matrix,3));
    roi_data_peri_av(ss,:)=mean(redata(roi1(1).data.mask(:),:,:),1);

    % ap.imscroll(average_matrix,t)
    % ap.wf_draw('ccf','black');
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
end
for ss=1:5

    % 使用 cellfun 计算每个矩阵中第 n 个元素的平均值
    average_matrix = cellfun(@(matrix) matrix{ss}, visual_visual_passive_img_l, 'UniformOutput', false);

    % 计算平均值
    average_matrix = mean( cat(4, average_matrix{:}), 4);

    nexttile;
    imagesc(max(average_matrix(:,:,period),[],3));
    axis image off;

    ap.wf_draw('ccf','black');
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    % colorbar
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    title(['Visual day ' num2str(ss)])


    redata=reshape(average_matrix,size(average_matrix,1)*size(average_matrix,2),size(average_matrix,3));
    roi_data_peri_vv(ss,:)=mean(redata(roi1(1).data.mask(:),:,:),1);

    %         clim(0.2*scale.*[0,1]);colormap(ap.colormap('WG'));
    %         colorbar
    % ap.imscroll(average_matrix,t)
    % ap.wf_draw('ccf','black');
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
end

sgtitle(strjoin(animals, ' ; '))

saveas(gcf,[Path 'imaging_of_visual_passive_task_across_days_from_visual_to_audio_' strjoin(animals, ' ; ')], 'jpg');



figure('Position', [50, 50, 400, 500]);
nexttile
imagesc(t,[], roi_data_peri_av);
title('mPFC in visual passive during auditory task day')
xlabel('Time from stim')
clim(0.2*scale.*[0,1]);colormap(ap.colormap('WG'));
xlabel('Time from stim')
colorbar
nexttile
imagesc(t,[],roi_data_peri_vv);
clim(0.2*scale.*[0,1]);colormap(ap.colormap('WG'));
title('mPFC in visual passive during visual task day')
xlabel('Time from stim')
colorbar


saveas(gcf,[Path 'mPFC_activity_of_visual_passive_task_across_days_from_visual_to_audio_' strjoin(animals, ' ; ')], 'jpg');







figure('Position', [50, 50, 1800, 900]);
tiledlayout(2,5);
for ss=1:5

    % 使用 cellfun 计算每个矩阵中第 n 个元素的平均值
    average_matrix = cellfun(@(matrix) matrix{ss}, audio_audio_passive_img_l, 'UniformOutput', false);

    % 计算平均值
    average_matrix = mean( cat(4, average_matrix{:}), 4);

    nexttile;
    imagesc(max(average_matrix(:,:,period),[],3));
    axis image off;

    ap.wf_draw('ccf','black');
    title(['Auditory day ' num2str(ss)])
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    % colorbar
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    redata=reshape(average_matrix,size(average_matrix,1)*size(average_matrix,2),size(average_matrix,3));
    roi_data_peri_aa(ss,:)=mean(redata(roi1(1).data.mask(:),:,:),1);

    % ap.imscroll(average_matrix,t)
    % ap.wf_draw('ccf','black');
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
end

for ss=1:5

    % 使用 cellfun 计算每个矩阵中第 n 个元素的平均值
    average_matrix = cellfun(@(matrix) matrix{ss}, visual_audio_passive_img_l, 'UniformOutput', false);

    % 计算平均值
    average_matrix = mean( cat(4, average_matrix{:}), 4);

    nexttile;
    imagesc(max(average_matrix(:,:,period),[],3));
    axis image off;

    ap.wf_draw('ccf','black');
    title(['Visual day ' num2str(ss)])
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
    % colorbar
    % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    redata=reshape(average_matrix,size(average_matrix,1)*size(average_matrix,2),size(average_matrix,3));
    roi_data_peri_va(ss,:)=mean(redata(roi1(1).data.mask(:),:,:),1);

    % ap.imscroll(average_matrix,t)
    % ap.wf_draw('ccf','black');
    % axis image;
    % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
end


sgtitle(strjoin(animals, ' ; '))

saveas(gcf,[Path 'imaging_of_auditory_passive_task_across_days_from_visual_to_audio_' strjoin(animals, ' ; ')], 'jpg');


figure('Position', [50, 50, 400, 500]);
nexttile
imagesc(t,[],roi_data_peri_aa); hold on
clim(0.2*scale.*[0,1]);colormap(ap.colormap('WG'));
title('mPFC in auditory passive task during auditory task day')
xlabel('Time from stim')
colorbar

nexttile
imagesc(t,[],roi_data_peri_va); hold on
clim(0.2*scale.*[0,1]);colormap(ap.colormap('WG'));
title('mPFC in auditory passive task during auditory task day')
xlabel('Time from stim')
colorbar

saveas(gcf,[Path 'mPFC_activity_of_auditory_passive_task_across_days_from_visual_to_audio_' strjoin(animals, ' ; ')], 'jpg');


%% mixed task


buffer =vertcat(Mixed_audio_passive_img_l{:});
m_a_l = buffer(cellfun(@(c) ~isempty(c), buffer));
m_a_avg_l=mean(cat(5,m_a_l{:}),5);

buffer =vertcat(Mixed_audio_passive_img_nl{:});
m_a_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
m_a_avg_nl=mean(cat(5,m_a_nl{:}),5);


buffer =vertcat(Mixed_visual_passive_img_l{:});
m_v_l = buffer(cellfun(@(c) ~isempty(c), buffer));
m_v_avg_l=mean(cat(5,m_v_l{:}),5);

buffer =vertcat(Mixed_visual_passive_img_nl{:});
m_v_nl = buffer(cellfun(@(c) ~isempty(c), buffer));
m_v_avg_nl=mean(cat(5,m_v_nl{:}),5);

figure;
scale=0.005;
nexttile
imagesc(max(m_a_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('Mixed A learned')

nexttile
if ~isempty(m_a_avg_nl)
imagesc(max(m_a_avg_nl(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('Mixed A non-learned')
end
nexttile
imagesc(max(m_v_avg_l(:,:,period),[],3));axis image off;
ap.wf_draw('ccf','black');
clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('Mixed V learned')


if ~isempty(m_v_avg_nl)
    nexttile
    imagesc(max(m_v_avg_nl(:,:,period),[],3));axis image off;
    ap.wf_draw('ccf','black');
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));title ('Mixed V non-learned')
end
sgtitle(strjoin(animals, ' ; '))
saveas(gcf,[Path 'passive_images_in_mixed_tasks' strjoin(animals, '_')], 'jpg');


%
% for ss=1:5
%
%     % 使用 cellfun 计算每个矩阵中第 n 个元素的平均值
%     average_matrix = cellfun(@(matrix) matrix{ss}, visual_audio_passive_img, 'UniformOutput', false);
%
%     % 计算平均值
%     average_matrix = mean( cat(4, average_matrix{:}), 4);
%
%     nexttile;
%     imagesc(max(average_matrix(:,:,period),[],3));
%     axis image off;
%
%     ap.wf_draw('ccf','black');
%     % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
%     % colorbar
%     % clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
%     clim(0.005.*[-1,1]); colormap(ap.colormap('PWG'));
%
%     % ap.imscroll(average_matrix,t)
%     % ap.wf_draw('ccf','black');
%     % axis image;
%     % clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
% end
%

% visual_visual_passive_img{:}
