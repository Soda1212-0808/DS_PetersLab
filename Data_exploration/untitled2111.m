
allen_atlas_path = fileparts(which('template_volume_10um.npy'));
obj.av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy'));
obj.st = loadStructureTree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));

figure('Position',[50 50 200 200]);
hold on
for curr_view = 1
    curr_outline = bwboundaries(squeeze((max(obj.av,[],curr_view)) > 1));
    % (only plot largest outline)
    [~,curr_outline_idx] = max(cellfun(@length,curr_outline));
    curr_outline_reduced = reducepoly(curr_outline{curr_outline_idx});
    plot(  curr_outline_reduced(:,2), ...
        curr_outline_reduced(:,1),'k','linewidth',2);
    set(gca,'YDir','reverse')
    axis(gca,'equal','off')

end

structure_name={'substantia nigra reticular part','Ventral medial nucleus of the thalamus'};
plot_structure_color = {[0.5 0.5 1],[1 0.5 0.5],[0 0 0]};
for curr_area=2
    plot_structure = find(strcmpi(obj.st.safe_name,structure_name{curr_area}));
    plot_structure_id = obj.st.structure_id_path{plot_structure};
    plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
        obj.st.structure_id_path));

    % Get structure color and volume
    slice_spacing = 5;
    plot_ccf_volume = ismember(obj.av(1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),plot_ccf_idx);
    % Plot 2D structure
    for curr_view = 1
        curr_outline = bwboundaries(squeeze((max(plot_ccf_volume,[],curr_view))));
        cellfun(@(x) plot(x(:,2)*slice_spacing, ...
            x(:,1)*slice_spacing,'color',plot_structure_color{curr_area},'linewidth',2),curr_outline(1))

        cellfun(@(x) fill(x(:,2)*slice_spacing, ...
            x(:,1)*slice_spacing, ...
            plot_structure_color{curr_area}, ...  % 填充颜色
            'FaceAlpha',0.5, ...                 % 透明度 (0=全透明,1=不透明)
            'EdgeColor',plot_structure_color{curr_area}, ...
            'LineWidth',2), ...
            curr_outline(1));

    end
end

