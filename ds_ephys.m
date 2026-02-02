
clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';

animals= { 'DS025'};


% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t_stim = [-0.1,0];
response_t_stim = [0.05,0.15];
psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

baseline_t_move = [-0.1,-0.1];
response_t_move = [-0.1,0.1];
psth_use_t_move = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);




for curr_animal=1 :length(animals)
 animal=animals{curr_animal};
 workflow_task =...
     {'stim_wheel_Vcenter_cross_movement_stage*','stim_wheel_Afreq2_cross_movement_stage*',...
     'stim_wheel_VcenterAfreq2_cross_movement_stage*'};

 workflow_passive={'hml_passive_audio_Freq2',...
     'lcr_passive_checkerboard','lcr_passive_grating_size40','lcr_passive_squareHorizontalStripes'};

 recordings_all= plab.find_recordings(animal,[],workflow_task);
 recordings_ephys=recordings_all([recordings_all.ephys]>0);


 

    for curr_day=1:length(recordings_ephys)
        preload_vars = who;

        % setting parameters
        behavior=struct;
        unit_psth=cell(2,1)
        unit_raster=cell(2,1);
        unit_psth_t=nan;
%%
        for curr_probe=1:recordings_ephys(curr_day).ephys

            rec_day=recordings_ephys(curr_day).day;
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

            % unit_dots = ap.plot_unit_depthrate(spike_templates,template_depths,probe_areas);

            stimOn_times=stimOn_times(1:n_trials);
            align_times= arrayfun(@(a) stimOn_times(behavior.tasktype==a & behavior.outcome==1) ,0:3,'uni',false);

            [unit_psth{curr_probe}{1},unit_raster{curr_probe}{1},unit_psth_t] = ...
                ap.psth(spike_times_timelite,align_times,spike_templates, ...
                'smoothing',100,'norm_window',[-0.5,0],'softnorm',1);

            clearvars('-except',preload_vars_task{:});

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
                clearvars('-except',preload_vars_passive{:});

            end

        end



   

        color_condition={[1 0 0],[0 0 1],[1 0.5 0.5],[0.5 0.5 1]}
        for curr_probe=1:recordings_ephys(curr_day).ephys
            for curr_unit_idx=1:size(unit_psth{curr_probe}{1},1)

                mainfig=figure
                main_tile= tiledlayout(mainfig,1,5,'Padding','tight','TileSpacing','tight');
                sgtitle(['Neuron ' num2str(curr_unit_idx) ' in probe ' num2str(curr_probe) ]);
                ymax=max(cellfun(@(x)    max(smoothdata(x(curr_unit_idx,:,:),2,'gaussian',50),[],"all") ,unit_psth{curr_probe},'UniformOutput',true));
                ymin=min(cellfun(@(x)    min(smoothdata(x(curr_unit_idx,:,:),2,'gaussian',50),[],"all") ,unit_psth{curr_probe},'UniformOutput',true));

                for curr_stage=1:5
                    t_stage = tiledlayout(main_tile,7,1,"TileSpacing","none",'Padding','tight');
                    t_stage.Layout.Tile =  curr_stage;

                    nexttile(t_stage)
                    hold on
                    arrayfun(@(condition) plot(unit_psth_t,smoothdata(unit_psth{curr_probe}{curr_stage}(curr_unit_idx,:,condition),2,'gaussian',50)',...
                        'linewidth',2,'Color',color_condition{condition}),1:size(unit_psth{curr_probe}{curr_stage},3),'UniformOutput',false)
                    xlim([-0.2 0.5])
                    ylim([ymin ymax])
                    xline(0)
                    axis off

                    [raster_y,raster_x] =cellfun(@(x) find(x(:,:,curr_unit_idx)),unit_raster{curr_probe}{curr_stage},'UniformOutput',false  );
                    max_y=max(cellfun(@(x) size(x,1),unit_raster{curr_probe}{curr_stage},'UniformOutput',true));

                    for curr_condition=1:length(raster_x)
                        ax=nexttile(t_stage);
                        plot(ax,unit_psth_t(raster_x{curr_condition}),raster_y{curr_condition},...
                            'LineStyle','none','Marker','.', 'MarkerEdgeColor', color_condition{curr_condition});
                        xlim([-0.2 0.5])
                        ylim([ymin max_y])
                        xline(0)

                        axis off
                    end

                end
                drawnow

            end
            close all
        end

        


            for curr_i=1:length(align_times)
                switch curr_task
                    case {1,2}
                        baseline_bins = align_times{curr_i} + baseline_t_stim;
                        response_bins = align_times{curr_i} + response_t_stim;

                    case 3
                        switch curr_i
                            case {1,2}
                                baseline_bins = align_times{curr_i} + baseline_t_stim;
                                response_bins = align_times{curr_i} + response_t_stim;
                            case {3,4,5}
                                baseline_bins = align_times{curr_i} + baseline_t_move;
                                response_bins = align_times{curr_i} + response_t_move;
                        end
                end


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

                event_response_p{curr_task}{curr_i} =event_response_p_all(template_sort);


            end




        ap.print_progress_fraction(curr_day,length(recordings_ephys));

    end

   

end



