function [p_map] = image_diff(A, B, condition, test)
% image_diff 对两组图像逐像素执行置换检验，并输出 p 值图
%
% Inputs:
%   A         - 图像数据组A [HxWxN]
%   B         - 图像数据组B [HxWxN]
%   condition - 1: 成对图像（paired），0: 独立图像（unpaired）
%   test      - 1: 原始秩, 2: 距离中心秩
%
% Output:
%   p_map     - 显著性图像 [HxW]

% 展平为 [像素 × 图像数]
A_reshaped = reshape(double(A), [], size(A, 3));
B_reshaped = reshape(double(B), [], size(B, 3));

% 根据条件删除 NaN 列
switch condition
    case 1  % 配对删除（两边都删）
        if ~isequal(size(A), size(B))
            error('Condition 1 requires A and B to be the same size.');
        end
        nan_mask = all(isnan(A_reshaped), 1) | all(isnan(B_reshaped), 1);
        A_reshaped(:, nan_mask) = [];
        B_reshaped(:, nan_mask) = [];
    case 0  % 各自删除自己的 NaN 列
        A_reshaped(:, all(isnan(A_reshaped), 1)) = [];
        B_reshaped(:, all(isnan(B_reshaped), 1)) = [];
    otherwise
        error('Unsupported condition value. Use 0 or 1.');
end

% 初始化
n_shuff = 1000;
n_pixel = size(A_reshaped, 1);

switch condition
    case 1  % 配对检验
        all_data = permute(cat(3, A_reshaped, B_reshaped), [2, 3, 1]);  % [nFrames x 2 x nPixels]
        diff_real = squeeze(mean(diff(all_data, [], 2), 1));

        diff_shuff = cell2mat(arrayfun(@(shuff) ...
            squeeze(mean(diff(ap.shake(all_data,2),[],2),1)), ...
            1:n_shuff,'uni',false));



    case 0  % 非配对检验
        all_data = [A_reshaped, B_reshaped];
        nA = size(A_reshaped, 2);
        n_total = size(all_data, 2);

        diff_real = mean(B_reshaped, 2) - mean(A_reshaped, 2);

        diff_shuff = zeros(n_pixel, n_shuff);
        for i = 1:n_shuff
            idx = randperm(n_total);
            group1 = all_data(:, idx(1:nA));
            group2 = all_data(:, idx(nA+1:end));
            diff_shuff(:, i) = mean(group2, 2) - mean(group1, 2);
        end

end

% 计算秩和 p 值
  ranks = tiedrank(horzcat(diff_real,diff_shuff)')';

switch test
    case 1  % 原始秩（越大越显著）
        p_vals = ranks(:, 1) / (n_shuff + 1);
    case 2  % 中心对称偏移（双尾）
        p_vals = abs(ranks(:, 1) - (n_shuff + 1)/2) / ((n_shuff + 1)/2);
    otherwise
        error('Unsupported test value. Use 1 or 2.');
end

% 还原为图像大小
p_map = reshape(p_vals, size(A, 1), size(A, 2));
end
