
clear all

np = py.importlib.import_module('numpy');
data = np.load('C:/Users/dsong/Downloads/spont2_data.npz');

% 把 keys 转成 MATLAB cell of char
files_cell = cell(data.files);
keys = cellfun(@char, files_cell, 'UniformOutput', false);
disp('keys:'); disp(keys);


% 提取并转换为 MATLAB 数组（按需要改 single/double）
for i = 1: numel(files_cell)
    k = keys{i};
    try
        pyArr = data.get(k);       % 返回 numpy.ndarray
        % 若你希望 spks 为 single，xpos,ypos 为 double，可按名字判断
        if strcmp(k, 'spks')
            matArr = single(pyArr);    % spks -> single
        else
            matArr = double(pyArr);    % xpos/ypos -> double
        end
        % 将数组放到 base workspace（可选）
        assignin('base', k, matArr);
        fprintf('loaded %s -> size %s, class %s\n', k, mat2str(size(matArr)), class(matArr));
    catch ME
        warning('Failed to extract %s: %s', k, ME.message);
    end
end


% 提取并转换为 MATLAB 数组（按需要改 single/double）
for i = 1:numel(files_cell)
    k = keys{i};
    try
        pyArr = data.get(k);       % 返回 numpy.ndarray 或其他 Python 对象

        % 首选：尝试直接转换（快速路径）
        try
            if strcmp(k, 'spks')
                matArr = single(pyArr);    % spks -> single
            else
                matArr = double(pyArr);    % xpos/ypos -> double
            end
            % 如果成功，确保 1D 向量为列向量
            if isnumeric(matArr) && isvector(matArr)
                matArr = matArr(:);
            end

            assignin('base', k, matArr);
            fprintf('fast loaded %s -> size %s, class %s\n', k, mat2str(size(matArr)), class(matArr));
            continue; % 下一个键
        catch fastErr
            % 直接转换失败：进入回退路径（慢路径）
            warning('fast conversion failed for %s: %s. Trying fallback...', k, fastErr.message);
        end

        % 回退：优先尝试 ndarray.tolist()（适用于大多数数值 ndarrays）
        try
            pyList = pyArr.tolist();   % 可能抛出异常（若非 ndarray 或含 object dtype）
            % 把 python list 转为 MATLAB cell
            matlabCell = cell(pyList);

            % 尝试把 matlabCell 当作一维数值向量
            try
                vec = cellfun(@(c) double(c), matlabCell, 'UniformOutput', true);
                matArr = vec(:);    % column vector
                % 若需要 spks 为 single
                if strcmp(k, 'spks')
                    matArr = single(matArr);
                end
                assignin('base', k, matArr);
                fprintf('fallback (tolist->1D) loaded %s -> size %s, class %s\n', k, mat2str(size(matArr)), class(matArr));
                continue;
            catch vecErr
                % 不是 1D 数值向量，尝试规则的二维数组（list of lists）
                % matlabCell 应该是 cell array of row-lists
                isRect = true;
                rows = numel(matlabCell);
                rowMats = cell(rows,1);
                rowLen = -1;
                for r = 1:rows
                    try
                        sub = cell(matlabCell{r});                  % elements of this row
                        subnum = cellfun(@(c) double(c), sub, 'UniformOutput', true);
                        rowMats{r} = subnum(:).';                   % ensure row
                        if rowLen == -1
                            rowLen = numel(subnum);
                        elseif rowLen ~= numel(subnum)
                            isRect = false;
                            break;
                        end
                    catch
                        isRect = false;
                        break;
                    end
                end

                if isRect && rows>0 && rowLen>0
                    matArr = vertcat(rowMats{:});  % rows x rowLen
                    if strcmp(k,'spks')
                        matArr = single(matArr);
                    else
                        matArr = double(matArr);
                    end
                    assignin('base', k, matArr);
                    fprintf('fallback (tolist->2D) loaded %s -> size %s, class %s\n', k, mat2str(size(matArr)), class(matArr));
                    continue;
                else
                    % 无法构成矩阵：退回 cell（尝试把每个元素转成 char / 基本类型）
                    try
                        % 尝试把每个元素转 char（若为字符串）
                        maybeChars = cellfun(@(c) char(c), matlabCell, 'UniformOutput', false);
                        matArr = maybeChars;
                        assignin('base', k, matArr);
                        fprintf('fallback returned cell of chars for %s\n', k);
                        continue;
                    catch
                        % 最后退回原始 cell
                        matArr = matlabCell;
                        assignin('base', k, matArr);
                        fprintf('fallback returned raw cell for %s\n', k);
                        continue;
                    end
                end
            end
        catch listErr
            % pyArr.tolist() 也失败（例如 pyArr 是非 ndarray 的复杂对象）
            warning('pyArr.tolist() failed for %s: %s. Trying repr->char fallback...', k, listErr.message);
            try
                reprStr = char(py.str(py.repr(pyArr)));
                assignin('base', k, reprStr);
                fprintf('repr fallback for %s stored as char\n', k);
                continue;
            catch reprErr
                warning('repr fallback failed for %s: %s', k, reprErr.message);
                % 最后仍未成功，保存一个空占位
                assignin('base', k, []);
                continue;
            end
        end

    catch ME
        warning('Failed to extract %s completely: %s', k, ME.message);
        % 不中断，继续下一个键
    end
end




