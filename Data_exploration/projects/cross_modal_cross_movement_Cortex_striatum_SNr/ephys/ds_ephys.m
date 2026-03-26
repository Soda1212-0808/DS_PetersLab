clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'Y:\Data process\project_cross_model_cross_movement\figures\ephys\single_neurons\';
animals= { 'DS025','DS022','DS023'};

color_condition={{[1 0 0],[0 0 1],[1 0.5 0.5],[0.5 0.5 1]},...
    {[0.5 0.5 0.5],[1 0 0],[0.5 0.5 0.5]},...
    {[0.5 0.5 0.5],[0 0 1],[0.5 0.5 0.5]},...
    {[0.5 0.5 0.5],[0 1 0],[0.5 0.5 0.5]},...
    {[1 0.5 0.5],[0.5 0.5 0.5],[0.5 0.5 1]}};
       
% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t_stim = [-0.1,0];
response_t_stim = [0.05,0.15];
psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

% ephys_data=struct;
ephys_data=table;
count_num=0;


for curr_animal=1 :length(animals)
 animal=animals{curr_animal};
 workflow_task =...
     {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
     'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

 workflow_passive={...
     'lcr_passive_grating_size40','lcr_passive_checkerboard',...
     'lcr_passive_squareHorizontalStripes','hml_passive_audio_Freq2'};
stage_name={'task','circle','checkerboard','stripes','audio'};
 recordings_all= plab.find_recordings(animal,[],workflow_task);
 recordings_ephys=recordings_all([recordings_all.ephys]>0);


 
 

    for curr_day=1:length(recordings_ephys)
        preload_vars = who;

        % setting parameters
        behavior=struct;
        unit_psth=cell(2,1)
        unit_raster=cell(2,1);
        event_response_p=cell(2,1);
        unit_psth_t=nan;

        for curr_probe=1:recordings_ephys(curr_day).ephys
        % for curr_probe=1

            rec_day=recordings_ephys(curr_day).day;

            count_num=count_num+1;
            % ephys_data(count_num).animal=animal;
            % ephys_data(count_num).rec_day=rec_day;
            % ephys_data(count_num).work_flow=recordings_ephys(curr_day).workflow{1};
            % ephys_data(count_num).probe=curr_probe;
            % 
            ephys_data.animal{count_num}=animal;
            ephys_data.rec_day{count_num}=rec_day;
            ephys_data.work_flow{count_num}=recordings_ephys(curr_day).workflow{1};
            ephys_data.probe(count_num)=curr_probe;


           
            % passive stage
            recordings_passive_all = plab.find_recordings(animal,rec_day,workflow_passive);
            for curr_passive=1:length(unique(recordings_passive_all.workflow))
                preload_vars_passive = who;

                recordings_passive = plab.find_recordings(animal,rec_day,workflow_passive{curr_passive});
                rec_time=recordings_passive.recording{1};
                load_probe=curr_probe;
                ap.load_recording;


                % (get quiescent trials)
                stim_window = [0,0.5];
                quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
                    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
                    (1:length(stimOn_times))');


                if contains(bonsai_workflow,'lcr')
                    % (vis passive)
                    stim_type = vertcat(trial_events.values.TrialStimX);
                    stim_values = unique(stim_type);
                    stimOn_times=stimOn_times(1:length(stim_type)-1);
                    quiescent_trials=quiescent_trials(1:length(stim_type)-1);
                    align_times = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);
                elseif contains(bonsai_workflow,'hml')
                    % (aud passive)
                    stim_type = vertcat(trial_events.values.StimFrequence);
                    stim_values = unique(stim_type);
                    align_times = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);

                end

                [unit_psth{curr_probe}{curr_passive+1},unit_raster{curr_probe}{curr_passive+1},unit_psth_t] = ...
                    ap.psth(spike_times_timelite,align_times,spike_templates, ...
                    'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);

                %% responsive
                for curr_i=1:length(align_times)

                    baseline_bins = align_times{curr_i} + baseline_t_stim;
                    response_bins = align_times{curr_i} + response_t_stim;
                    event_bins = [baseline_bins,response_bins];
                    spikes_binned_continuous = histcounts2(spike_times_timelite,spike_templates, ...
                        reshape([baseline_bins,response_bins]',[],1),1:size(templates,1)+1);

                    event_spikes = permute(reshape(spikes_binned_continuous(1:2:end,:),2, ...
                        size(event_bins,1),[]),[2,1,3]);

                    event_response = squeeze(mean(diff(event_spikes,[],2),1));

                    n_shuff = 1000;
                    event_response_shuff = cell2mat(arrayfun(@(shuff) ...
                        squeeze(mean(diff(ap.shake(event_spikes,2),[],2),1)), ...
                        1:n_shuff,'uni',false));

                    event_response_rank = tiedrank(horzcat(event_response,event_response_shuff)')';
                    event_response_p_all=event_response_rank(:,1)./(n_shuff+1);


                    event_response_p{curr_probe}{curr_passive+1}{curr_i} =event_response_p_all;


                end

                clearvars('-except',preload_vars_passive{:});

            end

             % task stage

            preload_vars_task = who;
            clear time
            if length(recordings_ephys(curr_day).index)>1
                for mm=1:length(recordings_ephys(curr_day).index)
                    rec_time = recordings_ephys(curr_day).recording{mm};
                    timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                    timelite = load(timelite_fn);
                    time(mm)=length(timelite.timestamps);
                end
                [~,index_real]=max(time);
            else index_real=1;
                rec_time = recordings_ephys(curr_day).recording{index_real};
            end

            verbose = true;
            load_probe=curr_probe;
            ap.load_recording;

   


            % behavioral performance
            if load_probe==1
                tasktype=[trial_events.values.TaskType]';
                No_tasktype =unique(tasktype);
                n_trials = length([trial_events.timestamps.Outcome]);

                surround_time = [-5,5];
                surround_sample_rate = 100;
                surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
                pull_times = stimOn_times(1:n_trials) + surround_time_points;

                event_aligned_wheel_vel = interp1(timelite.timestamps, ...
                    wheel_velocity,pull_times);

                behavior.stim2move=stim_to_move(1:n_trials);
                behavior.stim2outcome=stim_to_outcome(1:n_trials);
                behavior.velocity=event_aligned_wheel_vel;
                behavior.tasktype=tasktype(1:n_trials);
                outcome=cat(1,trial_events.values.Outcome);
                behavior.outcome=outcome(1:n_trials);
            end

             % unit_dots = ap.plot_unit_depthrate(spike_templates,spike_templates,template_depths,probe_areas);

            stimOn_times=stimOn_times(1:n_trials);
            align_times= arrayfun(@(a) stimOn_times(behavior.tasktype==a & behavior.outcome==1) ,unique(behavior.tasktype),'uni',false);
            align_stim2move=arrayfun(@(a) stim_to_move(behavior.tasktype==a & behavior.outcome==1) ,unique(behavior.tasktype),'uni',false);
      

            [unit_psth{curr_probe}{1},temp_unit_raster,unit_psth_t] = ...
                ap.psth(spike_times_timelite,align_times,spike_templates, ...
                'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);


          [sort_stim2move ,align_sort]=cellfun(@(x)  sort(x, 'descend'),align_stim2move','UniformOutput',false );
          unit_raster{curr_probe}{1}=  cellfun(@(a,b) a(b,:,:) ,temp_unit_raster,align_sort','UniformOutput',false  );

          
          % reponsive
              for curr_i=1:length(align_times)

                    baseline_bins = align_times{curr_i} + baseline_t_stim;
                    response_bins = align_times{curr_i} + response_t_stim;
                    event_bins = [baseline_bins,response_bins];
                    spikes_binned_continuous = histcounts2(spike_times_timelite,spike_templates, ...
                        reshape([baseline_bins,response_bins]',[],1),1:size(templates,1)+1);

                    event_spikes = permute(reshape(spikes_binned_continuous(1:2:end,:),2, ...
                        size(event_bins,1),[]),[2,1,3]);

                    event_response = squeeze(mean(diff(event_spikes,[],2),1));

                    n_shuff = 1000;
                    event_response_shuff = cell2mat(arrayfun(@(shuff) ...
                        squeeze(mean(diff(ap.shake(event_spikes,2),[],2),1)), ...
                        1:n_shuff,'uni',false));

                    event_response_rank = tiedrank(horzcat(event_response,event_response_shuff)')';
                    event_response_p_all=event_response_rank(:,1)./(n_shuff+1);


                    event_response_p{curr_probe}{1}{curr_i} =event_response_p_all;


              end
              % ephys_data(count_num).psth =  unit_psth{curr_probe};
              % ephys_data(count_num).responsive =  event_response_p{curr_probe};
              
              ephys_data.psth{count_num} =  unit_psth{curr_probe};
              ephys_data.responsive{count_num} =  cellfun(@(x) cat(2,x{:}), event_response_p{curr_probe},'uni',false);


                %% draw
                % for draw=1
                %     neuron_id=readtable('Y:\Data process\project_cross_model_cross_movement\ephys_data\neuronal_id_label\neuronal_labels.xlsx');
                %     % load('Y:\Data process\project_cross_model_cross_movement\ephys_data\neuronal_id_label\neuronal_labels.mat')
                %     count_id= find(ismember(neuron_id.animal,'DS025')&...
                %         ismember(neuron_id.probe,load_probe)&...
                %         ismember(neuron_id.rec_day,rec_day));
                %     curr_neurons_id=neuron_id.id_start(count_id):neuron_id.id_end(count_id);
                %     responsive_all= feval(@(c) cat(2, c{:}) ,  cat(2, event_response_p{curr_probe}{:}))
                %     row_idx = intersect(find(any(responsive_all(:,[ 6 9 14 16]) > 0.95 | responsive_all(:,[ 6 9 14 16]) < 0.05, 2)),curr_neurons_id');
                %     row_idx_up = intersect(find(any(responsive_all(:,[ 6 9 14 16]) > 0.95, 2)),curr_neurons_id');
                %     row_idx_down = intersect(find(any(responsive_all(:,[ 6 9 14 16]) <0.05, 2)),curr_neurons_id');
                % 
                %     figure
                %     for curr_passive=2:4
                %         nexttile
                %         imagesc(smoothdata(unit_psth{curr_probe}{curr_passive}(row_idx_down,:,2),2,'gaussian',50))
                %         clim([-2 2])
                %         colormap(ap.colormap('BWR'))
                %         % nexttile
                %         % plot(nanmean(unit_psth{curr_probe}{curr_passive}(row_idx_down,:,2),1))
                %     end
                % 
                %     for curr_passive=1:3
                %         nexttile
                %         imagesc(smoothdata(unit_psth{curr_probe}{5}(row_idx_down,:,curr_passive),2,'gaussian',50))
                %         clim([-2 2])
                %         colormap(ap.colormap('BWR'))
                %         % nexttile
                %         % plot(nanmean(unit_psth{curr_probe}{5}(row_idx_down,:,curr_passive),1))
                %     end
                % 
                % 
                %     psth_all=cat(3,unit_psth{curr_probe}{2:5})
                %     psth_all=psth_all(:,:,[2 5 8 10:12])
                % 
                % 
                %     % draw single neuron
                % 
                %     for curr_unit_idx=row_idx'
                % 
                %         mainfig=figure('Position',[100,100,1600 900])
                %         main_tile= tiledlayout(mainfig,1,6,'Padding','tight','TileSpacing','tight');
                %         sgtitle([animal ' ' num2str(rec_day)  ' probe ' num2str(curr_probe) '-cell '...
                %             num2str(curr_unit_idx) ]);
                %         ymax=max(cellfun(@(x)    max(smoothdata(x(curr_unit_idx,:,:),2,'gaussian',50),[],"all") ,unit_psth{curr_probe},'UniformOutput',true));
                %         ymin=min(cellfun(@(x)    min(smoothdata(x(curr_unit_idx,:,:),2,'gaussian',50),[],"all") ,unit_psth{curr_probe},'UniformOutput',true));
                % 
                % 
                % 
                %         plot_axes=nexttile
                % 
                %         hold(plot_axes,'on');
                % 
                %         % Plot units (depth vs normalized rate) with areas
                %         if exist('probe_areas','var') && ~isempty(probe_areas)
                %             probe_areas_rgb = permute(cell2mat(cellfun(@(x) hex2dec({x(1:2),x(3:4),x(5:6)})'./255, ...
                %                 probe_areas{1}.color_hex_triplet,'uni',false)),[1,3,2]);
                % 
                %             if any(ismember(probe_areas{1}.Properties.VariableNames,'probe_depth'))
                %                 % (old format)
                %                 probe_areas_boundaries = probe_areas{1}.probe_depth;
                %             elseif any(ismember(probe_areas{1}.Properties.VariableNames,'tip_distance'))
                %                 % (new format)
                %                 probe_areas_boundaries = 3840-probe_areas{1}.tip_distance*1000;
                %             end
                %             probe_areas_centers = mean(probe_areas_boundaries,2);
                % 
                %             probe_areas_image_depth = 0:1:max(probe_areas_boundaries,[],'all');
                %             probe_areas_image_idx = interp1(probe_areas_boundaries(:,1), ...
                %                 1:height(probe_areas{1}),probe_areas_image_depth, ...
                %                 'previous','extrap');
                %             probe_areas_image = ones(length(probe_areas_image_idx),1,3);
                %             probe_areas_image(~isnan(probe_areas_image_idx),:,:) = ...
                %                 probe_areas_rgb(probe_areas_image_idx(~isnan(probe_areas_image_idx)),:,:);
                % 
                %             yyaxis left; set(gca,'YDir','reverse');
                %             image(plot_axes,[0.5],probe_areas_image_depth,probe_areas_image);
                %             yline(unique(probe_areas_boundaries(:)),'color','k','linewidth',1);
                %             set(plot_axes,'YTick',probe_areas_centers,'YTickLabels',probe_areas{1}.acronym);
                %         end
                % 
                %         yyaxis right;
                %         set(gca,'YDir','reverse');
                %         spike_rate = (accumarray(findgroups(spike_templates(ismember(spike_templates, curr_unit_idx))),1)+1)/ ...
                %             diff(prctile(spike_templates,[0,100]));
                % 
                %         unit_dots = scatter( ...
                %             spike_rate,template_depths(unique(spike_templates(ismember(spike_templates, curr_unit_idx)))),20,'k','filled');
                %         ylabel('Depth (\mum)')
                %         xlabel('Spike rate')
                %         set(gca,'XScale','log');
                % 
                %         [plot_axes.YAxis.Color] = deal('k');
                % 
                %         yyaxis left;
                %         ylim([0, 3840]);
                % 
                %         yyaxis right;
                %         ylim([0, 3840]);
                % 
                % 
                % 
                %         for curr_stage=1:5
                %             t_stage = tiledlayout(main_tile,5,1,"TileSpacing","none",'Padding','tight');
                %             t_stage.Layout.Tile =  curr_stage+1;
                % 
                %             title(t_stage,stage_name{curr_stage});
                %             nexttile(t_stage)
                %             hold on
                %             arrayfun(@(condition) plot(unit_psth_t,smoothdata(unit_psth{curr_probe}{curr_stage}(curr_unit_idx,:,condition),2,'gaussian',50)',...
                %                 'linewidth',2,'Color',color_condition{curr_stage}{condition}),1:size(unit_psth{curr_probe}{curr_stage},3),'UniformOutput',false)
                %             xlim([-0.2 0.5])
                %             if ~ymin==ymax
                %                 ylim([ymin ymax])
                %             end
                %             xline(0)
                %             axis off
                % 
                % 
                %             [raster_y,raster_x] =cellfun(@(x) find(x(:,:,curr_unit_idx)),unit_raster{curr_probe}{curr_stage},'UniformOutput',false  );
                %             max_y=max(cellfun(@(x) size(x,1),unit_raster{curr_probe}{curr_stage},'UniformOutput',true));
                % 
                %             for curr_condition=1:length(raster_x)
                % 
                %                 ax=nexttile(t_stage);
                % 
                %                 plot(ax,unit_psth_t(raster_x{curr_condition}),raster_y{curr_condition},...
                %                     'LineStyle','none','Marker','.', 'MarkerEdgeColor', color_condition{curr_stage}{curr_condition});
                %                 xlim([-0.2 0.5])
                %                 ylim([0 max_y])
                %                 xline(0)
                %                 if curr_stage==1
                %                     hold on
                %                     plot(ax,sort_stim2move{curr_condition},1:length(sort_stim2move{curr_condition}),'.g')
                % 
                %                 end
                % 
                %                 axis off
                %             end
                % 
                %         end
                %         drawnow
                %         exportgraphics(gcf, ...
                %             [Path animal ' ' num2str(rec_day)  ' probe ' num2str(curr_probe) '_cell '...
                %             num2str(curr_unit_idx)  '.png'])
                % 
                % 
                %         close all
                %     end
                % end

        
          clearvars('-except',preload_vars_task{:});

        end

        ap.print_progress_fraction(curr_day,length(recordings_ephys));

    end

   

end


save('Y:\Data process\project_cross_model_cross_movement\ephys_data\ephys_data.mat','ephys_data','-v7.3')
