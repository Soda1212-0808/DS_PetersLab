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


%%
raster_window = [-0.2,0.7];
nPlotPerFig = 3;      % 每个figure放20个
for curr_cell=1:length(ephys_data.depth)
    temp_cell=cellfun(@(x)   x(:,:,curr_cell),ephys_data.raster,'UniformOutput',false);
    move_idx=cellfun(@(x)  stim_to_move(x),  ephys_data.event_idx,'UniformOutput',false);
    [temp_s2m,temp_idx]=cellfun(@(x) sort(x,'descend'),move_idx,'UniformOutput',false);
    [raster_y,raster_x] =cellfun(@(x,y) find(x(y,:)),temp_cell([1:4 9:12]),temp_idx([1:4 1:4]),'UniformOutput',false  );
    temp_lengths=temp_cell([1:4 9:12]);
    temp_s2m_1=[temp_s2m(1:4) ;cellfun(@(x) -x,  temp_s2m(1:4),'UniformOutput',false)];
    offset = 0;




    % 每20个新建一个figure
    if mod(curr_cell-1, nPlotPerFig) == 0
        figure('Position',[50 50 1600 900]);
        tiledlayout(1,3);   % 20 = 4×5
    end

    nexttile;
    hold on
    for curr_state =[ 8:-1:1]

        n_trial = size(temp_lengths{curr_state},1);

        % raster
        y1 = raster_y{curr_state} + offset;
        plot(ephys_data.raster_t(raster_x{curr_state}), y1, '.k');

        % % green points
        % y2 = (1:n_trial) + offset;
        % plot(temp_s2m_1{curr_state}, y2, '.g');

        % 横线画在两个state中间
        if curr_state <= 8
            yline(offset + n_trial + 0.5, '-k');
        end

        % 累积offset（不留空行）
        offset = offset + n_trial;
    end
    ylim([0  length(cat(1,temp_s2m_1{1:8}))])
    xlim(raster_window)
    ylabel('Trials')
    xlabel('Time')
    box on
    drawnow
end





    
  
    
