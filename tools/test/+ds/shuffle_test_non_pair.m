function [p_val] = shuffle_test_non_pair(A, B)

A=A(:);
B=B(:);
A=A(~isnan(A));
B=B(~isnan(B));

n_shuff = 1000;
all_data = [A; B];
diff_real = nanmean(B) - nanmean(A);

diff_shuff = zeros(n_shuff,1);
for i = 1:n_shuff
    idx = randperm(length(all_data));
    group1 = all_data(idx(1:length(A)));
    group2 = all_data(idx(length(A)+1:end));
    diff_shuff(i) = mean(group2) - mean(group1);
end
ranks = tiedrank(horzcat(diff_real,diff_shuff'));
 p_val = ranks(1) / (n_shuff + 1);


end

