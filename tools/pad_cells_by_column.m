function Cpad = pad_cells_by_column(C)
% C: m×n 的 cell 表；每个 C{i,j} 要么是 []，要么是 k×1 的 cell，
%    其中每个元素是同维度的 4D 数组（数值类）。
% 返回：每列按该列最大长度补齐后的 Cpad；[] 会被补成 k_max×1 的全 NaN 4D 数组。

[m,n] = size(C);
Cpad = C;

for j = 1:n
    %——先扫描这一列，确定最长长度和 NaN 模板尺寸——%
    maxlen = 0;
    templ_size = [];
    for i = 1:m
        val = C{i,j};
        if isempty(val)
            continue
        elseif iscell(val)
            % 这一格是 k×1 cell，找长度
            maxlen = max(maxlen, numel(val));
            % 找到其中第一个非空 4D 数组来确定模板尺寸
            idx = find(~cellfun(@isempty, val), 1, 'first');
            if ~isempty(idx) && isempty(templ_size)
                templ_size = size(val{idx});
            end
        else
            % 这一格就是一个 4D 数组（等价于 1×1 cell 的情况）
            maxlen = max(maxlen, 1);
            if isempty(templ_size)
                templ_size = size(val);
            end
        end
    end

    % 如果整列都是空，跳过（或按需自定义默认尺寸）
    if isempty(templ_size) || maxlen == 0
        continue
    end

    nanBlock = nan(templ_size);  % 全 NaN 的 4D 数组模板

    %——按列补齐到 maxlen——%
    for i = 1:m
        val = C{i,j};
        if isempty(val)
            % 空：直接补成 maxlen×1 的 NaN
            Cpad{i,j} = repmat({nanBlock}, maxlen, 1);
        elseif iscell(val)
            % 规范为列向量
            vec = val(:);
            % 把空元素也处理成 NaN（如果有的话）
            empty_idx = cellfun(@isempty, vec);
            vec(empty_idx) = {nanBlock};
            % 不足的补 NaN
            if numel(vec) < maxlen
                vec(end+1:maxlen, 1) = {nanBlock};
            end
            Cpad{i,j} = vec;
        else
            % 单个 4D 数组：转成 maxlen×1，其中第一项是原数组，剩余 NaN
            vec = repmat({nanBlock}, maxlen, 1);
            vec{1} = val;
            Cpad{i,j} = vec;
        end
    end
end
end
