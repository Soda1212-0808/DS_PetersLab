function tform = image_navigation()
    % 读取并显示图像
  img = imread('C:\Users\dsong\Desktop\buffer.png');  % 请替换为你自己的图像文件   
    hFig = figure;
    hAx = axes('Parent', hFig);
    hImg = imshow(img, 'Parent', hAx);
    
    % 获取图像大小
    [imgHeight, imgWidth, ~] = size(img);
    
    % 初始图像平移和旋转参数
    translation = [0, 0];  % [x, y]
    angle = 0;  % 旋转角度
    
    % 图像中心点
    centerX = imgWidth / 2;
    centerY = imgHeight / 2;
    
    % 设置按键响应函数
    set(hFig, 'KeyPressFcn', @keyPressHandler);
    
    function keyPressHandler(~, event)
        % 获取按下的键
        key = event.Key;
        
        % 根据按键调整平移或旋转
        switch key
            case 'uparrow'
                translation(2) = translation(2) - 10;  % 上移
            case 'downarrow'
                translation(2) = translation(2) + 10;  % 下移
            case 'leftarrow'
                translation(1) = translation(1) - 10;  % 左移
            case 'rightarrow'
                translation(1) = translation(1) + 10;  % 右移
            case 'w'
                angle = angle + 10;  % 顺时针旋转
            case 'q'
                angle = angle - 10;  % 逆时针旋转
            case 'return'  % 回车键
                % 在按下回车键时保存最终的变换矩阵并退出
                % 构造仿射变换矩阵
                tformTranslateToCenter = affine2d([1 0 0; 0 1 0; -centerX -centerY 1]);
                tformRotate = affine2d([cosd(angle) -sind(angle) 0; ...
                                        sind(angle)  cosd(angle) 0; ...
                                        0 0 1]);
                tformTranslateBack = affine2d([1 0 0; 0 1 0; centerX+translation(1) centerY+translation(2) 1]);

                tform = affine2d(tformTranslateToCenter.T * tformRotate.T * tformTranslateBack.T);
                
                % 将 tform 保存到工作空间并关闭窗口
                assignin('base', 'tform', tform);
                close(hFig);
                return;
        end
        
        % 构造仿射变换矩阵
        tformTranslateToCenter = affine2d([1 0 0; 0 1 0; -centerX -centerY 1]);
        tformRotate = affine2d([cosd(angle) -sind(angle) 0; ...
                                sind(angle)  cosd(angle) 0; ...
                                0 0 1]);
        tformTranslateBack = affine2d([1 0 0; 0 1 0; centerX+translation(1) centerY+translation(2) 1]);

        tform = affine2d(tformTranslateToCenter.T * tformRotate.T * tformTranslateBack.T);
        
        % 应用变换
        transformedImg = imwarp(img, tform, 'OutputView', imref2d(size(img)));
        
        % 更新图像显示
        set(hImg, 'CData', transformedImg);
    end
end
