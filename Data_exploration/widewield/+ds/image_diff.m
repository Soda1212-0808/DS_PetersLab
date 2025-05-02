function p_map = image_diff(A,B)

A(A<threshold)=0;
B(B<threshold)=0;

A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 
% 将每组图像展平为 [像素数 × 图数]
A_reshape = reshape(A,[],size(A,3));  
B_reshape = reshape(B,[],size(B,3)); 

% 合并数据
all_data = [A_reshape, B_reshape];   
nA = size(A_reshape,2);
nB = size(B_reshape,2);
n_total = nA + nB;

% 计算真实的均值差异
diff_real = mean(A_reshape,2) - mean(B_reshape,2);  % [120000 x 1]

% 生成打乱样本
n_perm = 1000;
diff_shuff = zeros(size(diff_real,1), n_perm);

for i = 1:n_perm
    rand_idx = randperm(n_total);
    group1 = all_data(:,rand_idx(1:nA));
    group2 = all_data(:,rand_idx(nA+1:end));
    diff_shuff(:,i) = mean(group1,2) - mean(group2,2);  % [120000 x 1]
end

% 拼接真实和打乱结果 -> [120000 x (1+n_perm)]
all_diffs = [diff_real, diff_shuff];

% 排序后计算秩
ranks = tiedrank(all_diffs')';  % 转置->对每一行排序（每个像素点）

% 实际结果的秩在第一列
real_ranks = ranks(:,1);

% 越接近最大值，越显著（两尾）
p_vals =  abs(real_ranks - (n_perm+1)/2) / ((n_perm+1)/2);
 
% 重塑为图像
p_map = reshape(p_vals,size(A,[1 2]));