


%% 一维深度
groups={'VA','AV','VA_nA'}

fig1 = figure;
tl1 = tiledlayout(2,4);  % 2 行 3 列
title(tl1, 'numbers of responsive neurons');

fig3 = figure;
tl3 = tiledlayout(2,4);  % 2 行 3 列
title(tl3, 'numbers of all neurons');

fig4 = figure;
tl4 = tiledlayout(2,4);  % 2 行 3 列
title(tl4, 'proportion');

fig2 = figure;
tl2 = tiledlayout(2,4);
title(tl2, 'firing rates');

for curr_group=1:2

for used_stim=[3 5 7 8]

used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);
used_filter_idx=eval('base',['filtered_'  groups{curr_group}]);
used_celltypes=eval('base',['celltypes_'  groups{curr_group}]);

single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
    used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
single_neuron_each_rec = vertcat(single_plot{:});
single_neuron_all=cat(1,single_neuron_each_rec{:});

single_neuron_deep=cellfun(@(x,y)  x(y),animals_all_cell_position_sorted(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
    used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
single_probe_position=cellfun(@(x,y)  x(y),animals_probe_positions(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
    used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
single_neuron_position=cellfun(@(x,y)  cellfun(@(a,b) b(:,1)' + a/3840 * (b(:,2) - b(:,1))'  ,x,y,'Unif',false),...
    single_neuron_deep,single_probe_position,'UniformOutput',false   )
single_neuron_each_position = vertcat(single_neuron_position{:});
single_neuron_position_all=cat(1,single_neuron_each_position{:});


response_each_rec= vertcat(used_filter_idx{:});
response_all=cat(1,response_each_rec{:});


celltypes_each_rec= vertcat(used_celltypes{:});
celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);

celltypes_msn_all=cat(1,celltypes_msn{:});
celltypes_fsi_all=cat(1,celltypes_fsi{:});
celltypes_tan_all=cat(1,celltypes_tan{:});





% === 用户输入 ===



neuron_coords_all= single_neuron_position_all;

neuron_coords= single_neuron_position_all(response_all(:,used_stim),:);
firing_rates=single_neuron_all(response_all(:,used_stim),:,used_stim);


bin_size_z = 20; % 单位：μm，根据实际尺度调整

% 假设你已加载 neuron_coords (N x 3) 和 firing_rates (N x T)
% 例如：load('neuron_data.mat'); 包含 neuron_coords 和 firing_rates

% === Step 1: 投影到冠状面（y-z） ===
projected_coords = neuron_coords(:, 2); % 取 y 和 z
projected_coords_all = neuron_coords_all(:, 2); % 取 y 和 z

% === Step 2: 创建 bin 网格 ===

z_min = min(projected_coords_all)-10;
z_max = max(projected_coords_all)+10;

z_edges = z_min:bin_size_z:z_max;

% 分配每个神经元的 bin 索引
neuron_count_map_all = histcounts(projected_coords_all, z_edges);
[neuron_count_map,~,binIdx]= histcounts(projected_coords, z_edges);
porportion=neuron_count_map./neuron_count_map_all;


% 可视化神经元比例热图
figure(fig1)
ax1=nexttile(tl1)
bar(z_edges(1:end-1), neuron_count_map', 'histc');
ylim([0 50])

figure(fig3)
ax1=nexttile(tl3)
 bar(z_edges(1:end-1), neuron_count_map_all', 'histc');
ylim([0 100])

figure(fig4)
ax1=nexttile(tl4)
bar(z_edges(1:end-1), porportion', 'histc');
ylim([0 1])

firing_rates_bins = arrayfun(@(col) ...
    accumarray(binIdx, firing_rates(:,col), [length(z_edges)-1,1], @mean, NaN), ...
    1:size(firing_rates,2), 'UniformOutput', false);

firing_rates_bins1=cat(2,firing_rates_bins{:});




figure(fig2)

ax2=nexttile(tl2)
h2=imagesc(t_bins,z_edges(1:end-1),firing_rates_bins1)
xlim([0 0.3])
clim([0 10])
colormap(ax2,ap.colormap('WR'))

 if curr_group==1
title(titles(used_stim))
 end


end
end
