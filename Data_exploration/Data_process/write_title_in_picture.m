% 创建示例彩色图像数据
data = rand(100, 100, 3);  % 创建一个 100x100x3 的随机矩阵
data = uint8(data * 255);  % 将数据缩放到 0-255 范围并转换为 uint8 类型

% 显示彩色图像
figure;
imshow(data);

% 获取图像的大小
[height, width, ~] = size(data);

% 定义标题文本
titleText = 'This is a title';

% 创建一个新的图像，包含原始图像和标题区域
titleHeight = 30;  % 标题区域的高度
newImage = uint8(zeros(height + titleHeight, width, 3));

% 将原始图像复制到新图像中
newImage(titleHeight+1:end, :, :) = data;

% 在新图像的标题区域填充背景色（例如，黑色）
newImage(1:titleHeight, :, :) = 255;

% 显示新图像
figure;
imshow(newImage);

% 在新图像上添加标题
position = [width/2, titleHeight/2];  % 标题位置
newImageWithText = insertText(newImage, position, titleText, 'FontSize', 18, ...
                              'BoxColor', 'black', 'BoxOpacity', 0, 'TextColor', 'black', ...
                              'AnchorPoint', 'Center');

% 显示包含标题的最终图像
figure;
imshow(newImageWithText);

% 保存包含标题的图像
imwrite(newImageWithText, 'image_with_embedded_title.png');
