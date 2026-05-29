clear all
animal='DS025';
load_probe=1;
ap.load_recording



%%
% ds.process_behavior
ds.process_ephys
ap.imscroll(ephys_data.psth)
clim([-5 5])
colormap(ap.colormap('kwg'))



raster_window = [-0.2,0.7];
nPlotPerFig = 6;      % 每个figure放20个

for curr_cell=1:length(ephys_data.depth)
    temp_cell=cellfun(@(x)   x(:,:,curr_cell),ephys_data.raster,'UniformOutput',false);
    move_idx=cellfun(@(x)  stim_to_move(x),  ephys_data.event_idx,'UniformOutput',false);
    [temp_s2m,temp_idx]=cellfun(@(x) sort(x,'descend'),move_idx,'UniformOutput',false);
    [raster_y,raster_x] =cellfun(@(x,y) find(x(y,:)),temp_cell(1:4),temp_idx,'UniformOutput',false  );


    offset = 0;




    % 每20个新建一个figure
    if mod(curr_cell-1, nPlotPerFig) == 0
        figure('Position',[50 50 1600 900]);
        tiledlayout(2,3);   % 20 = 4×5
    end

    nexttile;
    hold on
    for curr_state = 4:-1:1

        n_trial = length(temp_idx{curr_state});

        % raster
        y1 = raster_y{curr_state} + offset;
        plot(ephys_data.raster_t(raster_x{curr_state}), y1, '.k');

        % green points
        y2 = (1:n_trial) + offset;
        plot(temp_s2m{curr_state}, y2, '.g');

        % 横线画在两个state中间
        if curr_state < 8
            yline(offset + n_trial + 0.5, '-k');
        end

        % 累积offset（不留空行）
        offset = offset + n_trial;
    end
    ylim([0  length(cat(1,move_idx{1:4}))])
    xlim(raster_window)
    ylabel('Trials')
    xlabel('Time')
    box on
    drawnow
end





    
  
    
