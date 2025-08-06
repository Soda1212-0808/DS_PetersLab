function [p_map] = image_diff(A,B,condition,test)


% 将每组图像展平为 [像素数 × 图数]
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 

switch condition
    case 1
if ~isequal(size(A), size(B))
    error('the sizes of A and B are different.')
    return
end
idx=all(isnan(A_reshape), 1) | all(isnan(B_reshape), 1);

A_reshape(:, idx) = [];
B_reshape(:, idx) = [];


% 合并数据
all_data = permute(cat(3,A_reshape, B_reshape),[2,3,1]);   

% 计算真实的均值差异
diff_real = squeeze(mean(diff(all_data,[],2),1));

% 生成打乱样本
n_shuff = 1000;
diff_shuff = cell2mat(arrayfun(@(shuff) ...
    squeeze(mean(diff(ap.shake(all_data,2),[],2),1)), ...
    1:n_shuff,'uni',false));

  ranks = tiedrank(horzcat(diff_real,diff_shuff)')';


case 0

A_reshape(:, all(isnan(A_reshape), 1) ) = [];
B_reshape(:, all(isnan(B_reshape), 1) ) = [];

all_data = [A_reshape, B_reshape];   
nA = size(A_reshape,2);
nB = size(B_reshape,2);
n_total = size(A_reshape,2) +size(B_reshape,2);
 diff_real = mean(B_reshape,2) - mean(A_reshape,2);  % [120000 x 1]
n_shuff = 1000;
diff_shuff = zeros(size(diff_real,1), n_shuff);

for i = 1:n_shuff
    rand_idx = randperm(n_total);
    group1 = all_data(:,rand_idx(1:nA));
    group2 = all_data(:,rand_idx(nA+1:end));
    diff_shuff(:,i) = mean(group2,2) - mean(group1,2);  % [120000 x 1]
end
% 排序后计算秩
ranks = tiedrank([diff_real, diff_shuff]')';  % 转置->对每一行排序（每个像素点）
end

switch test
    case 1
% 越接近最大值，越显著（两尾）
p_vals =  ranks(:,1) ./ (n_shuff+1);
    case 2
p_vals =  abs(ranks(:,1) - (n_shuff+1)/2) ./ ((n_shuff+1)/2);
end

% 重塑为图像
p_map = reshape(p_vals,size(A,[1 2]));


end
