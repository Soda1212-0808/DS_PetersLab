clear all

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

data_path='D:\Data process\project_SNr\data\ephys_data\package';
label_file='D:\Data process\project_SNr\data\ephys_data\neuronal_id_label\animal_labels.xlsx';
recordings = readtable(label_file, ...
    'VariableNamingRule', 'preserve');
recordings.("date").Format = 'yyyy-MM-dd';
brain_region='SNr';
brain_region1='SNr';
data_all=struct;
tempn=0;

for curr_recodring =1:size(recordings,1)
    if contains (recordings.region{curr_recodring},brain_region1)
        animal=recordings.animal{curr_recodring};
        rec_day=char(recordings.date(curr_recodring));
        data_file= matfile(fullfile(data_path,[animal '_all_data.mat']));
        data_idx=find(ismember(data_file.day,rec_day));

        % load beahvior
        behavior=data_file.behavior_task(data_idx,1);
        behavior=behavior{1};
        % load ephys task
        ephys_data_task=data_file.ephys_task(data_idx,1);
        ephys_data_task=ephys_data_task{1};
        % load ephys passive
        ephys_data_passive=data_file.ephys_c_passive_5stim(data_idx,1);
        ephys_data_passive=ephys_data_passive{1};

        if ~isempty(behavior)
            if any (contains (ephys_data_task.probe_histology.acronym,brain_region))
                tempn=tempn+1;
                task_name=data_file.task_name(data_idx,1);          
                task_labels={'white circle','black square','grating'};
           
                figure
                nexttile
                success=behavior.success;
                data_all.success(:,tempn)=success;
                bar(success);
                xticklabels(task_labels);
                ylim([0 1]); yticks([0 1]);
                ylabel('success');
                box off;

                nexttile
                reaction_time=behavior.stim2move_f_stats(:,2);
                data_all.reaction_time(:,tempn)=reaction_time;
                bar(reaction_time);
                xticklabels(task_labels);
                ylim([0 0.2]); yticks([0 0.2]);
                ylabel('reaction time (s)')
                box off

                nexttile
                wheel_vel=behavior.stim_move_aligned_wheel_vel;
                group_labels=behavior.wheel_vel_labels;
                nRows = cellfun(@(x) size(x,1), wheel_vel);
                imagesc(surround_time_points,[],vertcat(wheel_vel{:})/1000);
                colormap(ap.colormap('pwg'));
                clim([-5 5]);
                xlim([-0.2 1]);
                colorbar;
                hold on;
                boundaries = cumsum(nRows);
                for i = 1:length(boundaries)-1
                    yline(boundaries(i)+0.5, 'k-', 'LineWidth', 1);
                end
                centers = cumsum(nRows) - nRows/2;
                yticks(centers);
                yticklabels(group_labels);
                set(gca, 'TickLabelInterpreter', 'none');
                xlabel('Time');
                ylabel('Behavior');
                title('Wheel Velocity', 'Interpreter', 'none');

                nexttile
                wheel_vel_mean=feval(@(a) cat(1,a{:}) , cellfun(@(x) nanmean(x./1000,1) , wheel_vel,'UniformOutput',false));
                wheel_vel_error=feval(@(a) cat(1,a{:}) ,cellfun(@(x) nanstd(x./1000,0,1),wheel_vel,'UniformOutput',false));
                colors2=[0,0,1;0.5,0.5,1;1,0,0;1,0.5,0.5;0,0,0;0.5,0.5,0.5];
                ap.errorfill(surround_time_points,wheel_vel_mean',wheel_vel_error',colors2);
                xline(0);
                xlim([-0.2 1]);
                title ('velocity');

                nexttile
                itimove=behavior.iti_move_aligned_wheel_vel;
                nRows = cellfun(@(x) size(x,1), itimove);
                imagesc(surround_time_points,[],vertcat(itimove{:})/1000);
                clim([-2 2]);
                colormap(ap.colormap('pwg'));
                xlim([-0.2 1]);
                colorbar;
                hold on;
                boundaries = cumsum(nRows);
                for i = 1:length(boundaries)-1
                    yline(boundaries(i)+0.5, 'k-', 'LineWidth', 1);
                end
                centers = cumsum(nRows) - nRows/2;
                % 设置 Y 轴标签
                yticks(centers);
                yticklabels({'left','right'});
                set(gca, 'TickLabelInterpreter', 'none');

                xlabel('Time');
                ylabel('Behavior');
                title('iti move', 'Interpreter', 'none');
                nexttile
                iti_wheel_vel_mean=feval(@(a) cat(1,a{:}) , cellfun(@(x) nanmean(x./1000,1) , itimove,'UniformOutput',false));
                iti_wheel_vel_error=feval(@(a) cat(1,a{:}) ,cellfun(@(x) nanstd(x./1000,0,1),itimove,'UniformOutput',false));
                ap.errorfill(surround_time_points,iti_wheel_vel_mean',iti_wheel_vel_error',[0 0 1;1 0 0]);
                xline(0);
                xlim([-0.2 1]);
                sgtitle ([animal ' ' rec_day ' ' task_name{1}], 'Interpreter', 'none');
                drawnow

                %% ds.process_ephys

                idx = find(ismember(ephys_data_task.probe_histology.acronym,brain_region));
                region_dist= arrayfun(@(probe)...
                    ephys_data_task.probe_histology.tip_distance(idx(ephys_data_task.probe_histology.probe_shank(idx)==probe),:),...
                    ephys_data_task.probe_histology.probe_shank(idx),'UniformOutput',false);

                region_id= feval(@(x) sum( cat(2,x{:}),2), arrayfun(@(probe)...
                    ephys_data_task.depth>region_dist{probe}(2) & ...
                    ephys_data_task.depth<region_dist{probe}(1)...
                    &  ephys_data_task.shank==probe,find(~cellfun(@isempty, region_dist)),'UniformOutput',false));

                unit_id= ~ismember(ephys_data_task.unit_label,'axon') ;
                response_cells=max(cat(2,ephys_data_task.response_p{1:3})>0.95,[],2)>0;

                data_all.unit_id{tempn}=unit_id;
                data_all.region_id{tempn}=region_id;
                data_all.task_response{tempn}=ephys_data_task.response_p;
                data_all.ccf{tempn}= ephys_data_task.ccf;
                data_all.task_psth{tempn}=ephys_data_task.psth;
                data_all.passive_psth{tempn}=ephys_data_passive.psth;
                data_all.passive_response{tempn}=ephys_data_passive.response_p;

                %
                figure;
                tiledlayout(4,6,'TileSpacing','tight');

                [obj.av,~,obj.st] = ap_histology.load_ccf;
                plot_ccf_idx = find(ismember(obj.st.acronym,{brain_region}));
                % Get structure color and volume
                slice_spacing = 5;
                plot_structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_ccf_idx},2,[])')./255;
                plot_ccf_volume = ismember(obj.av(1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),plot_ccf_idx);

                % 2d map
                used_event=[ 1 2 3 13 14]
                for curr_event=1:5
                    ax(used_event(curr_event))=nexttile;
                    if ~isempty(ephys_data_task.response_p{used_event(curr_event)})
                    hold(ax(used_event(curr_event)),'on');
                    for curr_view = 1
                        curr_outline = bwboundaries(squeeze((max(plot_ccf_volume,[],curr_view))));
                        cellfun(@(x) plot(x(:,2)*slice_spacing, ...
                            x(:,1)*slice_spacing,'color',plot_structure_color,'linewidth',2),curr_outline);
                    end
                    set(ax(used_event(curr_event)),'YDir','reverse');
                    axis(ax(used_event(curr_event)),'equal');
                    axis(ax(used_event(curr_event)),'off');
                    hold on
                    scatter(ephys_data_task.ccf(unit_id,3),...
                        ephys_data_task.ccf(unit_id,2),...
                        10,'filled','MarkerFaceColor',[0.8 0.8 0.8]);
                    hold on
                    scatter( ephys_data_task.ccf(find(region_id&unit_id),3),...
                        ephys_data_task.ccf(find(region_id&unit_id),2),10,'k','filled');
                    scatter(ephys_data_task.ccf(find(region_id&unit_id&ephys_data_task.response_p{used_event(curr_event)}>0.95),3),...
                        ephys_data_task.ccf(find(region_id&unit_id&ephys_data_task.response_p{used_event(curr_event)}>0.95),2),10,'r','filled')
                    title(ephys_data_task.labels{used_event(curr_event)}, 'Interpreter', 'none');
                    end
                end
                
                % 3d map
                ax3d = nexttile;
                ap.ccf_outline_3d(ax3d,{brain_region});
                hold on
                scatter3(ephys_data_task.ccf(unit_id,1),...
                    ephys_data_task.ccf(unit_id,3),...
                    ephys_data_task.ccf(unit_id,2),10,'filled','MarkerFaceColor',[0.8 0.8 0.8]);
                
                scatter3(ephys_data_task.ccf(find(region_id&unit_id),1),...
                    ephys_data_task.ccf(find(region_id&unit_id),3),...
                    ephys_data_task.ccf(find(region_id&unit_id),2),10,'k','filled');
                % psth
                for curr_event=1:5
                    nexttile
                    temp_psth=ephys_data_task.psth(find(region_id&unit_id&response_cells),:,used_event(curr_event));
                     data_all.taskpsth{curr_event}{tempn}=temp_psth;
                    imagesc(ephys_data_task.raster_t,[],temp_psth);
                    clim([-5 5]);
                    xlim([-0.5 1]);
                    colormap(ap.colormap('pwg'));
                    % title(ephys_data.labels{curr_event}, 'Interpreter', 'none')
                end

                nexttile
                for curr_event=1:5
                    temp_psth=ephys_data_task.psth(find(region_id&unit_id&response_cells),:,used_event(curr_event));
                    hold on
                    ap.errorfill(ephys_data_task.raster_t,nanmean(temp_psth,1),std(temp_psth,0,1)./sqrt(size(temp_psth,1)));
                    ylim([-2 5]);
                end
                drawnow

                %% ephys data passive

                [obj.av,~,obj.st] = ap_histology.load_ccf;
                plot_ccf_idx = find(ismember(obj.st.acronym,{brain_region}));
                % Get structure color and volume
                slice_spacing = 5;
                plot_structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_ccf_idx},2,[])')./255;
                plot_ccf_volume = ismember(obj.av(1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),plot_ccf_idx);

                % 2d map
                for curr_event=[1 2 3 4 5]
                    ax1(curr_event)=nexttile;
                    hold(ax1(curr_event),'on');
                    for curr_view = 1
                        curr_outline = bwboundaries(squeeze((max(plot_ccf_volume,[],curr_view))));
                        cellfun(@(x) plot(x(:,2)*slice_spacing, ...
                            x(:,1)*slice_spacing,'color',plot_structure_color,'linewidth',2),curr_outline);
                    end
                    set(ax1(curr_event),'YDir','reverse');
                     axis(ax1(curr_event),'equal');
                    axis(ax1(curr_event),'off');

                    hold on
                    scatter(ephys_data_passive.ccf(unit_id,3),...
                        ephys_data_passive.ccf(unit_id,2),...
                        10,'filled','MarkerFaceColor',[0.8 0.8 0.8]);
                    hold on
                    scatter( ephys_data_passive.ccf(find(region_id&unit_id),3),...
                        ephys_data_passive.ccf(find(region_id&unit_id),2),10,'k','filled');
                    scatter(ephys_data_passive.ccf(find(region_id&unit_id&ephys_data_passive.response_p{curr_event}>0.95),3),...
                        ephys_data_passive.ccf(find(region_id&unit_id&ephys_data_passive.response_p{curr_event}>0.95),2),10,'r','filled');
                    title(ephys_data_passive.labels{curr_event}, 'Interpreter', 'none');
                end
                
                % 3d map
                ax3d = nexttile;
          
                % psth
                for curr_event=1:5
                    nexttile
                    temp_psth=ephys_data_passive.psth(find(region_id&unit_id&response_cells),:,curr_event);
                    
                    data_all.passivepsth{curr_event}{tempn}=temp_psth;

                    imagesc(ephys_data_passive.raster_t,[],temp_psth)
                    clim([-5 5])
                    xlim([-0.5 1])
                    colormap(ap.colormap('pwg'))
                end

                nexttile
                for curr_event=1:5
                    temp_psth=ephys_data_passive.psth(find(region_id&unit_id&response_cells),:,curr_event);
                    hold on
                    ap.errorfill(ephys_data_passive.raster_t,nanmean(temp_psth,1),std(temp_psth,0,1)./sqrt(size(temp_psth,1)))
                    ylim([-2 5])

                end
                drawnow
            end
        end
    end
end

%%
task_psth=cellfun(@(x)  cat(1,x{:}), data_all.taskpsth,'UniformOutput',false);
passive_psth=cellfun(@(x)  cat(1,x{:}), data_all.passivepsth,'UniformOutput',false);
data_psth=[task_psth,passive_psth];

figure;
tiledlayout(5,10,'TileSpacing','tight')
for curr_sort=1:5
    [~, idx]= sort(nanmean(data_psth{curr_sort}(:,(ephys_data_passive.raster_t>0&ephys_data_passive.raster_t<0.2)),2),'descend');

    for curr_event=1:10
        nexttile
        imagesc(ephys_data_passive.raster_t,[],data_psth{curr_event}(idx,:));
        clim([-5 5]);
        xlim([-0.5 1]);
        colormap(ap.colormap('pwg'));
        axis off
    end
end


%%
raster_t=ephys_data_passive.raster_t;

data_ccf=  cat(1,data_all.ccf{:});
data_unit_id=cat(1,data_all.unit_id{:});
data_region_id=cat(1,data_all.region_id{:});
data_task_psth=cat(1,data_all.task_psth{:});
data_passive_psth=cat(1,data_all.passive_psth{:});

data_all.data_psth=cellfun(@(task,passive) cat(3,task,passive) ,...
    data_all.task_psth,data_all.passive_psth,'UniformOutput',false);
data_all.data_response=feval(@(a)  cat(2,a{:}), cellfun(@(task,passive) [task;passive] ,...
    data_all.task_response,data_all.passive_response,'UniformOutput',false));



data_ccf=cellfun(@(ccf,unit,region)   ccf(unit&region,:),...
    data_all.ccf,data_all.unit_id,data_all.region_id,'uni',false);

data_psth=cellfun(@(psth,unit,region)   psth(unit&region,:,:),...
    data_all.data_psth,data_all.unit_id,data_all.region_id,'uni',false);
data_peak=cellfun(@(x)    permute(max(x(:,raster_t>0&raster_t<0.2,:),[],2),[1 3 2]), data_psth,'UniformOutput',false      )
data_response=arrayfun(@(a) cellfun(@(response,unit,region)  response(unit&region),...
    data_all.data_response(a,:),data_all.unit_id,data_all.region_id,'uni',false),[1:3 15:19],'uni',false);
%%
task_psth_all=cellfun(@(x)  x(:,:,[1:3 15:19]) ,data_psth,'UniformOutput',false);
temp_psth=cat(1,task_psth_all{:});

temp_response=cellfun(@(x) cat(1,x{:}),data_response,'UniformOutput',false);
figure;
tiledlayout(3,3)
nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}<0.05&temp_response{2}>0.5,:,1))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}<0.05&temp_response{2}>0.5,:,2))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
 for curr_event=1:2
hold on
ap.errorfill( raster_t,  nanmean(temp_psth(temp_response{1}<0.05&temp_response{2}>0.5,:,curr_event),1),...
     nanstd(temp_psth(temp_response{1}<0.05&temp_response{2}>0.5,:,curr_event),0,1)./...
     sqrt(size(temp_psth(temp_response{1}<0.05&temp_response{2}>0.5,:,curr_event),1)));
 end

nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}<0.05&temp_response{2}<0.05,:,1))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}<0.05&temp_response{2}<0.05,:,2))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
for curr_event=1:2
    hold on
    ap.errorfill( raster_t,  nanmean(temp_psth(temp_response{1}<0.05&temp_response{2}<0.05,:,curr_event),1),...
        nanstd(temp_psth(temp_response{1}<0.05&temp_response{2}<0.05,:,curr_event),0,1)./...
        sqrt(size(temp_psth(temp_response{1}<0.05&temp_response{2}<0.05,:,curr_event),1)));
end


nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}>0.5&temp_response{2}<0.05,:,1))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
imagesc(raster_t,[],temp_psth(temp_response{1}>0.5&temp_response{2}<0.05,:,2))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
nexttile
for curr_event=1:2
    hold on
    ap.errorfill( raster_t,  nanmean(temp_psth(temp_response{1}>0.5&temp_response{2}<0.05,:,curr_event),1),...
        nanstd(temp_psth(temp_response{1}>0.5&temp_response{2}<0.05,:,curr_event),0,1)./...
        sqrt(size(temp_psth(temp_response{1}>0.5&temp_response{2}<0.05,:,curr_event),1)));
end











%%

figure;
temp_psth=cat(1,task_psth_all{:});
for curr_event=1:size(temp_psth,3)
nexttile
imagesc(raster_t,[], temp_psth(:,:,curr_event))
clim([-5 5]);
xlim([-0.5 1]);
colormap(ap.colormap('pwg'));
axis off
end
nexttile
for curr_event=1:size(temp_psth,3)
hold on
temp_mean=nanmean(temp_psth(:,:,curr_event),1);
temp_error=std(temp_psth(:,:,curr_event),0,1)./sqrt(size(temp_psth,1));
ap.errorfill(raster_t,temp_mean,temp_error);
ylim([-0.2 2])
end




%%

[obj.av,~,obj.st] = ap_histology.load_ccf;
plot_ccf_idx = find(ismember(obj.st.acronym,{brain_region}));
% Get structure color and volume
slice_spacing = 5;
plot_structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_ccf_idx},2,[])')./255;
plot_ccf_volume = ismember(obj.av(1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),plot_ccf_idx);


figure
nexttile
hold on
for curr_view = 1
    curr_outline = bwboundaries(squeeze((max(plot_ccf_volume,[],curr_view))));
    cellfun(@(x) plot(x(:,2)*slice_spacing, ...
        x(:,1)*slice_spacing,'color',plot_structure_color,'linewidth',2),curr_outline);
end
set(gca,'YDir','reverse');
axis(gca,'equal');
axis(gca,'off');

hold on
cellfun(@(x)scatter(x(:,3),...
    x(:,2),...
    10,'filled','MarkerFaceColor',[0.8 0.8 0.8]),data_ccf,'UniformOutput',false)


%%
peak=feval(@(a) cat(1,a{:}), cellfun(@(x)  x(:,2) ,data_peak,'UniformOutput',false ))

x = double(ccf(:,3));
y = double(ccf(:,2));
peak = double(peak(:));
nx = 200;
ny = 200;
x_grid = linspace(min(x), max(x), nx);
y_grid = linspace(min(y), max(y), ny);

[X, Y] = meshgrid(x_grid, y_grid);


sigma = 4;  % 平滑宽度，单位与 x、y 相同

heat_sum = zeros(size(X));
weight_sum = zeros(size(X));

for i = 1:length(peak)

    dist2 = (X-x(i)).^2 + (Y-y(i)).^2;

    weight = exp(-dist2/(2*sigma^2));

    heat_sum = heat_sum + peak(i)*weight;
    weight_sum = weight_sum + weight;

end

% 局部平均最大放电值
heatmap_data = heat_sum ./ max(weight_sum, eps);


mask = weight_sum > 0.05 * max(weight_sum(:));
heatmap_data(~mask) = NaN;


figure

h = imagesc(x_grid, y_grid, heatmap_data);
clim([0 6])
set(gca, 'YDir', 'reverse');
axis image;
hold on

%% 7. 绘制所有脑区边界
cellfun(@(b) plot(b(:,2)*slice_spacing, ...
    b(:,1)*slice_spacing, ...
    'Color', plot_structure_color, ...
    'LineWidth', 2), curr_outline);


axis image;
set(gca, 'YDir', 'reverse');

xlabel('CCF coordinate');
ylabel('CCF coordinate');
title('Peak firing rate distribution');

hold off;







%%
ax3d = nexttile;
ap.ccf_outline_3d(ax3d,{brain_region});
hold on
cellfun(@(x) scatter3(x(:,1),...
    x(:,3),...
   x(:,2),10,'filled','MarkerFaceColor',[0.8 0.8 0.8]),data_ccf,'UniformOutput',false)


%%
% file_idx= contains (recordings.region,brain_region1);
% animals=unique(recordings.animal(file_idx));
% behavior_task = cell(numel(animals),1);
% passive_ephys= cell(numel(animals),1);
% task_ephys= cell(numel(animals),1);
% for curr_animal=1:length(animals)
%     animal=animals{curr_animal};
%     dates= recordings.date( contains (recordings.region,brain_region1)&contains (recordings.animal,animal));
% 
%     data_file= matfile(fullfile(data_path,[animal '_all_data.mat']));
%     data_idx=find(ismember(data_file.day,dates));
% 
% 
%     for k = 1:numel(data_idx)
%         behavior_task{curr_animal}{k} = data_file.behavior_task(data_idx(k),1);
%         passive_ephys{curr_animal}{k}=data_file.ephys_c_passive_5stim(data_idx(k),1);
%         task_ephys{curr_animal}{k}=data_file.ephys_task(data_idx(k),1);
%     end
% end