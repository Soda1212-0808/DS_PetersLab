function each_roi = make_each_roi(temp_dat, tdim,roi1)
% make_temp_wach  Reorder dims if needed, merge first two dims, and average over ROI masks.
%
% INPUT:
%   temp_dat : N-D array (N >= 3)
%   tdim     : 一个整数，对应目标的“时间维度”大小 (原来的 41)
%   roi1     : 结构数组，要求每个元素含 roi1(k).data.mask (逻辑索引)
%
% OUTPUT:
%   make_each_roi: 1×numel(roi1) cell，每个元素为按 ROI 求均值后的数组

    % --- Step 1: 调整维度顺序（如果含 [450 426 tdim] 就排到最前）
    match_size  = [450 426 tdim];
    matrix_size = size(temp_dat);
    [tf, loc]   = ismember(match_size, matrix_size);
    if all(tf)
        perm_order = [loc, setdiff(1:numel(matrix_size), loc, 'stable')];
        temp_dat   = permute(temp_dat, perm_order);
        matrix_size = size(temp_dat); % 更新
    end

    % --- Step 2: 合并前两个维度
    new_size = [prod(matrix_size(1:2)), matrix_size(3:end)];
    buf1     = reshape(temp_dat, new_size);

    % --- Step 3: 对每个 ROI mask 求 nanmean
    nd   = ndims(buf1);
    subs = repmat({':'}, 1, nd-1);   % ':' 重复，用于 2:end 维

    temp_roi = arrayfun(@(curr_roi) ...
        permute( nanmean(buf1(roi1(curr_roi).data.mask(:), subs{:}), 1), ...
                 [2:nd, 1] ), ...
        1:numel(roi1), 'UniformOutput', false);

    % 给每个 5×5×8 的元素加一个前导 1 -> 1×5×5×8
    each_roi_exp = cellfun(@(a) reshape(a, [1, size(a)]), temp_roi, 'UniformOutput', false);
    each_roi = cat(1, each_roi_exp{:});

% each_roi=each_roi(:);
    % 如果不想保留最后的单例维度，可用 squeeze()
end
