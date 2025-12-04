% 创建一个 VideoWriter 对象，指定文件名和格式
video_data=[v_a_avg_l a_a_avg_l];
videoFilename = ['visual_auditory_passive_' strjoin(animals, '_') '.avi'];
video = VideoWriter([Path videoFilename], 'Uncompressed AVI');  % 可以根据需要选择不同的格式
video.FrameRate = 10;  % 设置帧率
% 打开 VideoWriter 对象以进行写入
open(video);
% 读取图像序列并写入视频
for k = 1:size(video_data,3)
    
    ap.imscroll(video_data(:,:,k),t(k));
    axis image off;
    % ap.wf_draw('ccf','black');
    clim(scale.*[-1,1]); colormap(ap.colormap('PWG'));
    % 获取当前图像帧
    frame = getframe(gca);
    % 提取图像数据
    image = frame.cdata;


    [height, width, ~] = size(image);
    titleHeight = 30;  % 标题区域的高度
    newImage = uint8(zeros(height + titleHeight, width, 3));
    % 将原始图像复制到新图像中
    newImage(titleHeight+1:end, :, :) = image;
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
