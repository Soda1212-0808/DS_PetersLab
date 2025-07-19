
bregma=[520,44,570];
allen_atlas_path = fileparts(which('template_volume_10um.npy'));
obj.av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy'));
obj.st = loadStructureTree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));


structure_name='caudoputamen';
plot_structure = find(strcmpi(obj.st.safe_name,structure_name));
plot_structure_id = obj.st.structure_id_path{plot_structure};
plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
    obj.st.structure_id_path));

% Get structure color and volume
structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_structure},2,[])')./255;
plot_ccf_volume = ismember(obj.av,plot_ccf_idx);

 
%%
dist2bregma=0.4 %% mm
selected_slice=bregma(1)-dist2bregma*100;


figure;
hold on
for curr_view = 1
    % curr_outline_out = bwboundaries(squeeze((max(obj.av,[],curr_view)) > 1));
        curr_outline_out = bwboundaries(squeeze((obj.av(selected_slice,:,:))> 1));

    % (only plot largest outline)
    [~,curr_outline_idx] = max(cellfun(@length,curr_outline_out));
    curr_outline_reduced = reducepoly(curr_outline_out{curr_outline_idx});
    plot( ...
        curr_outline_reduced(:,2), ...
        curr_outline_reduced(:,1),'k','linewidth',2);
    % (draw 1mm scalebar)
    % line([0,0],[0,100],'color','k','linewidth',2);
end
set(gca,'YDir','reverse')
axis(gca,'equal','off')

curr_outline_area = bwboundaries(squeeze(plot_ccf_volume(round(selected_slice),:,:)));
plot( curr_outline_area{1}(:,2), curr_outline_area{1}(:,1), ...
    'Color', structure_color, 'LineWidth', 2);
title([num2str(dist2bregma) ' mm'],'FontWeight','normal')