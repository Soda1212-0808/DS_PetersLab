function [p_val] = shuffle_test(A, B, paired, test)
% shuffle_test: permutation shuffle test
% paired = 0 → unpaired test (default)
% paired = 1 → paired test
% test   = 1 → 原始秩
% test   = 2 → 距离中心秩

    % 默认参数
    if nargin < 3 || isempty(paired)
        paired = 0;
    end
    if nargin < 4 || isempty(test)
        test = 1;
    end

    A = A(:);
    B = B(:);
    A = A(~isnan(A));
    B = B(~isnan(B));

    n_shuff = 1000;

    if paired == 0
        % ------- Unpaired test -------
        all_data = [A; B];
        diff_real = nanmean(B) - nanmean(A);

        diff_shuff = zeros(n_shuff,1);
        for i = 1:n_shuff
            idx = randperm(length(all_data));
            group1 = all_data(idx(1:length(A)));
            group2 = all_data(idx(length(A)+1:end));
            diff_shuff(i) = mean(group2) - mean(group1);
        end

    else
        % ------- Paired test -------
        n = min(length(A), length(B));  % 保证配对长度一致
        A = A(1:n);
        B = B(1:n);
        diff_real = nanmean(B - A);

        diff_shuff = zeros(n_shuff,1);
        for i = 1:n_shuff
            % 随机翻转符号
            signs = randi([0 1], n, 1)*2 - 1; % ±1
            diff_shuff(i) = mean((B - A) .* signs);
        end
    end

    % -------- p 值计算 --------
    ranks = tiedrank(horzcat(diff_real, diff_shuff'));

    if test == 1
        % 原始秩
        p_val = ranks(1) / (n_shuff + 1);
    elseif test == 2
        % 距离中心秩
        p_val = abs(ranks(:,1) - (n_shuff + 1)/2) / ((n_shuff + 1)/2);
    else
        error('test 参数只能是 1 或 2');
    end

end
