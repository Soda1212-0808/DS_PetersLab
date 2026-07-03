[obj.av,~,obj.st] = ap_histology.load_ccf;
slice_id=500
% curr_outline = bwboundaries(squeeze((max(obj.av(slice_id,:,:),[],1)) > 1));
curr_outline = bwboundaries(squeeze((max(obj.av(:,:,:),[],3)) > 1));

[~,curr_outline_idx] = max(cellfun(@length,curr_outline));
curr_outline_reduced = reducepoly(curr_outline{curr_outline_idx});


figure;
hold on
plot(curr_outline_reduced(:,1), ...
    curr_outline_reduced(:,2),'k','linewidth',2);
axis equal off
set(gca,'YDir','reverse')
% set(gca,'XDir','reverse')

names={'Caudoputamen','Ventral medial nucleus of the thalamus','"Substantia nigra reticular part"'}
% names={'Caudoputamen'}

plot_structure_all=cellfun(@(x) find(strcmp(x,obj.st.name)),names,'UniformOutput',true  );
for curr_structure=1:length(plot_structure_all)
    plot_structure=plot_structure_all(curr_structure);
    plot_structure_id = obj.st.structure_id_path{plot_structure};
    plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
        obj.st.structure_id_path));

    % Get structure color and volume
    slice_spacing = 5;
    plot_structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_structure},2,[])')./255;
    plot_ccf_volume = ismember(obj.av,plot_ccf_idx);

    curr_outline = bwboundaries(squeeze((max(plot_ccf_volume(:,:,:),[],3))));

    cellfun(@(x) plot(x(:,1), ...
        x(:,2),'color',plot_structure_color,'linewidth',2),curr_outline)

end


