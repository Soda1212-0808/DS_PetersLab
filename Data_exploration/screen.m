screen_w = 270; 
screen_h = 90;
radius = 10;           % 刺激半径
spatial_freq = 0.1;   % 空间频率（每像素周期数）
x_start = 225;
y_start = 45;

% 预生成灰色背景
gray_bg = 0.5 * ones(screen_h, screen_w);
gray_bg(:, 89:91) = 0;  % 在第300列画黑线
gray_bg(:, 179:181) = 0;  % 在第600列画黑线
% 生成标准 grating 圆（中心在 0,0）
[Xg, Yg] = meshgrid(-radius:radius, -radius:radius);
mask_circle = (Xg.^2 + Yg.^2) <= radius^2;
grating_pattern = 0.5 + 0.5 * sign(sin(2*pi*spatial_freq*Xg)); 
grating_pattern(~mask_circle) = 0.5; % 圆外设为灰色

% figure;
% imagesc(grating_pattern,[0 1])
% axis image off
% colormap('gray')

edges = diff([0; (photodiode_trace > 3)]) == 1;      % 找上升沿
stim_id = cumsum(edges);                % 给刺激段编号
stim_id(~(photodiode_trace > 3)) = 0;                % 非刺激时为0
stim_pos = nan(length(wheel_position),2);                    % 初始化输出
if any(edges)
    base_vals = wheel_position(edges); % 各段起始基准
    mask = stim_id > 0;
    % 直接利用索引赋值，不用额外变量
    stim_pos(mask,1) = x_start + (wheel_position(mask) - base_vals(stim_id(mask))) /500*90;
    % stim_pos(mask,1) =  (wheel_position(mask) - base_vals(stim_id(mask))) ;

    stim_pos(mask,2) = y_start;
end
figure;
plot(stim_pos(:,1))

% figure;
% plot(wheel_position(mask))
%% === 2) 生成 grating 模板（一次生成） ===

% 
% % 采样间隔
% step = 100;
% sample_idx = 1:step:n;
% new_frame=nan(screen_h,screen_w,length(sample_idx));
% for t = sample_idx
%     frame = gray_bg;  % 每次重新生成背景
%     if ~isnan(stim_pos(t,1))
%         cx = round(stim_pos(t,1));
%         cy = round(stim_pos(t,2));
%         x_range = (cx-radius):(cx+radius);
%         y_range = (cy-radius):(cy+radius);
% 
%         valid_x = x_range > 0 & x_range <= screen_w;
%         valid_y = y_range > 0 & y_range <= screen_h;
% 
%         frame(y_range(valid_y), x_range(valid_x)) = ...
%             grating_pattern(valid_y, valid_x);
%     end
% 
%    new_frame(:,:,t)=frame;
% end

