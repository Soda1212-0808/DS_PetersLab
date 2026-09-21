%% default setting
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t = [-0.2,0];
response_t = [0,0.2];
psth_use_t = t_centers >= response_t(1) & t_centers <= response_t(2);
Path = 'D:\Data process\project_SNr\data\ephys_data\single_neuron\';


animals={'DS036','DS041','DS043'};
rec_days={{'2026-08-25','2026-08-28'},...
    {'2026-08-24','2026-08-25','2026-08-28','2026-08-31'},...
    {'2026-08-18','2026-08-25','2026-08-27'}};

for curr_animal=1:length(animals)

    animal=animals{curr_animal};
    % recordings_all_training=plab.find_recordings(animal,[]);
    % recordings_all_training=recordings_all_training([recordings_all_training.ephys]>0);

    % for curr_day=1:length(recordings_all_training)
    for curr_day=1:length(rec_days{curr_animal})

        rec_day=rec_days{curr_animal}{curr_day};
        temp_recording= plab.find_recordings(animal,rec_day,'*');

        % workflows=temp_recording.workflow;
        workflows={'stim_wheel_Vcenter_X_move_stage2_BWG',...
            'lcr_passive_white_circle_size40',...
            'lcr_passive_black_square',...
            'lcr_passive_grating_size40',...
            'lcr_passive_checkerboard' ,...
            'lcr_passive_squareHorizontalStripes'};
        for curr_probe=1:temp_recording.ephys
            load_probe=curr_probe;

            neuro_number=[];
            preload_vars = who;
            rec_task = plab.find_recordings(animal,rec_day,'*wheel*');
            rec_time = rec_task.recording{1};
            verbose = true;
            ap.load_recording;
            ds.process_ephys
            brain_region='SNr';
            idx =find(ismember(probe_histology.acronym,brain_region));
            region_dist= arrayfun(@(probe)...
                probe_histology.tip_distance(idx(probe_histology.probe_shank(idx)==probe),:),...
                1:4,'UniformOutput',false)
            neuro_number=find(feval(@(x) sum( cat(2,x{:}),2), arrayfun(@(probe)...
                ephys_data.depth>region_dist{probe}(2) & ...
                ephys_data.depth<region_dist{probe}(1)...
                &  ephys_data.shank==probe,find(~cellfun(@isempty, region_dist)),'UniformOutput',false)));

            % neuro_number=find( sum(feval(@(a) cat(2,a{:}) ,...
            %     arrayfun(@(id) ephys_data.response_p{id}>0.95|ephys_data.response_p{id}<0.05,...
            %     1:3,'UniformOutput',false)),2)>0);

            clearvars('-except',preload_vars{:});

            neuro_number_groups = arrayfun(@(i) neuro_number(i:min(i+19,length(neuro_number))), 1:20:length(neuro_number), ...
                'UniformOutput', false);
            %%
            for curr_group=1:length(neuro_number_groups)
                for curr_neuron=neuro_number_groups{curr_group}

                    plot_units=curr_neuron;
                    % figure('color','w','name',sprintf('Unit %d',neuro_number(curr_neuron)),'Position',[50 50 1600 900]);

                    h = gobjects(length(plot_units),1);
                    for curr_unit = 1:length(plot_units)
                        figure('color','w','name',sprintf('Unit %d',plot_units(curr_unit)),'WindowState','maximized');
                        h(curr_unit) = tiledlayout(length(workflows),3);
                    end

                    % h = tiledlayout(length(workflows),2);

                    for workflow_idx = 1:length(workflows)
                        rec = plab.find_recordings(animal,rec_day,workflows{workflow_idx});
                        rec_time = rec.recording{end};

                        switch workflow_idx
                            case 1
                                type_name='TaskType';
                            case  num2cell(2:length(workflows))
                                type_name='TrialStimX';
                        end

                        verbose = true;
                        ap.load_recording;

ds.load_iti_move
                        stim_vals=  unique( feval(@(a) cat(1,a{:}) ,{trial_events.values.(type_name)}));
                        use_align = [arrayfun(@(x) stimOn_times(feval(@(s) s(1:n_trials) ,feval(@(a) cat(1,a{:}) ,{trial_events.values.(type_name)})) == x), ...
                            stim_vals, 'UniformOutput', false)' iti_move_time'];

                        if workflow_idx==1
                            stim2move_time=arrayfun(@(id) stim_to_move([trial_events.values(1:n_trials).TaskType] == id),stim_vals,'uni',false);
                        end


                        [psth_stim,raster_stim,raster_t_stim] =cellfun(@(x) ap.psth(spike_times_timelite, ...
                            x,spike_templates),use_align,'UniformOutput',false);

                        for curr_unit_idx = 1:length(plot_units)
                            % Plot PSTH
                            if ismember(workflow_idx,1)
                                nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),1,1)); hold on;
                                plot(raster_t_stim{1},smoothdata(psth_stim{1}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color','b')
                                plot(raster_t_stim{1},smoothdata(psth_stim{2}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color','r')
                                plot(raster_t_stim{1},smoothdata(psth_stim{3}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color','g')
                                
                                nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),1,3)); hold on;
                                plot(raster_t_stim{1},smoothdata(psth_stim{4}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color','b')
                                plot(raster_t_stim{1},smoothdata(psth_stim{5}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color','r')

                             
                            elseif  ismember(workflow_idx,[2 3 4 5 6])
                                nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),1,2)); hold on;

                                colorss={[0.5 0.5 1],[1 0.5 0.5],[0.5 1 0.5],[0.5 0.5 0.5],[0.8 0.8 0.8]}
                                % plot(raster_t_stim{1},smoothdata(psth_stim{1}(curr_neuron,:),2,'gaussian',50)','linewidth',2,'Color',[1 0.5 0.5])
                                plot(raster_t_stim{1},smoothdata(psth_stim{2}(plot_units(curr_unit_idx),:),2,'gaussian',50)','linewidth',2,'Color',colorss{workflow_idx-1})
                                % plot(raster_t_stim{1},smoothdata(psth_stim{3}(curr_neuron,:),2,'gaussian',50)','linewidth',2,'Color',[0.8 0.8 0.8])


                            end


                            
                            axis off
                            xline(0,'r');
                            % ylim([0 20])


                            switch workflow_idx
                                case 1
                                    [temp_s2m,temp_idx]=arrayfun(@(id) sort(stim2move_time{id},'descend'),1:length(stim2move_time),'UniformOutput',false);

                                    [raster_y,raster_x] =cellfun(@(x,y) find(x(y,:,plot_units(curr_unit_idx))),raster_stim(1:3),temp_idx,'UniformOutput',false  );
                                    [raster_y_iti,raster_x_iti]=cellfun(@(x) find(x(:,:,plot_units(curr_unit_idx))),raster_stim(4:5),'UniformOutput',false  );

                                    for curr_stage=1:3
                                        ax=nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),curr_stage+1,1)); hold on;
                                        plot(raster_t_stim{curr_stage}(raster_x{curr_stage}),raster_y{curr_stage},'.k');
                                        plot(temp_s2m{curr_stage},1:length(stim2move_time{curr_stage}),'.g')
                                        line([0, 0],[0 ,max(raster_y{curr_stage})],'Color','r');
                                        ylim(ax,[0 max(cellfun(@(x) length(x), stim2move_time,'UniformOutput',true))])
                                        % ylim(ax,[0 50])
                                        xlim(raster_window)
                                         axis off
                                    end
                                    for curr_stage=1:2
                                        ax=nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),curr_stage+1,3)); hold on;
                                        plot(raster_t_stim{curr_stage+3}(raster_x_iti{curr_stage}),raster_y_iti{curr_stage},'.k');
                                        line([0, 0],[0 ,max(raster_y{curr_stage})],'Color','r');
                                        ylim(ax,[0 max(cellfun(@(x) size(x,1), raster_stim(4:5),'UniformOutput',true))])
                                        % ylim(ax,[0 50])
                                        xlim(raster_window)
                                        axis off
                                    end

                                case {2,3,4,5,6}
                                    [raster_y,raster_x] =cellfun(@(x) find(x(:,:,plot_units(curr_unit_idx))),raster_stim,'UniformOutput',false  );

                                   ax= nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),workflow_idx,2)); hold on;
                                    plot(ax,raster_t_stim{1}(raster_x{2}),raster_y{2},'.k');
                                    xlim(raster_window)
                                    % ylim([0 50.5])
                                     axis off
                                    line([0, 0],[0 ,max(raster_y{2})],'Color','r');


                            end

                            drawnow;
                        end

                    end

                    % save_filename = fullfile(Path, sprintf('%s_%s_probe%d_unit%d.png', ...
                    %     animal, rec_day, curr_probe,curr_neuron));
                    % 
                    % exportgraphics(h, save_filename, 'Resolution', 300);
                    % 
                    % close all
                end
                for i = 1:numel(h)

                    save_filename = fullfile(Path, sprintf( ...
                        '%s_%s_probe%d_unit%d.png', ...
                        animal, rec_day, curr_probe, curr_neuron(i)));

                    exportgraphics(h(i), save_filename, 'Resolution', 300);

                end
                close all



            end
        end

    end

end

