
clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}0
animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS006','DS013',...
    'DS000','DS004','DS014','DS015','DS016'};


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


titles={'L','M','R','4k','8k','12k','R task','8k task','R task move','8k task move','move'};

% run process

for curr_animal=1 :length(animals)

    animal=animals{curr_animal};
    recordings_all_training=plab.find_recordings(animal,[],'stim_wheel_right_stage2_mixed_VA');
    recordings_all_passive_visual=plab.find_recordings(animal,[],'lcr_passive');
    recordings_all_passive_audio=plab.find_recordings(animal,[],'hml_passive_audio');


    recordings_passive_visual = recordings_all_passive_visual( ...
        cellfun(@any,{recordings_all_passive_visual.ephys}) & ...
        ismember({recordings_all_passive_visual.day},{recordings_all_training.day}));

    recordings_passive_audio = recordings_all_passive_audio( ...
        cellfun(@any,{recordings_all_passive_audio.ephys}) & ...
        ismember({recordings_all_passive_audio.day},{recordings_all_training.day}));

    recordings_training = recordings_all_training( ...
        cellfun(@any,{recordings_all_training.ephys}) & ...
        ismember({recordings_all_training.day},{recordings_all_passive_audio.day}));
    %
    probe_positions=cell(4,1);
    all_cell_deepth=cell(4,1);
    all_cell_sorted=cell(4,1);
    all_cell_deepth_sorted=cell(4,1);
    striatal_surface_position=cell(4,1);
    all_cell_ccf_position_sorted=cell(4,1);
    all_event_response_idx=cell(2,1);
    event_response_p=cell(2,1);
    all_event_response_plot=cell(2,1);
    all_event_response_signle_neuron=cell(2,1);
    % all_event_response_signle_neuron_single_trial=cell(2,1);
    all_event_response_signle_neuron_h1=cell(2,1);
    all_event_response_signle_neuron_h2=cell(2,1);
    all_celltypes=cell(4,1);
    plot_single=cell(4,1);
    plot_idx=cell(4,1);
    raster=cell(4,1);
    for curr_day=1:4

        day_probe={'post str','ant str','post str','ant str'};
        preload_vars = who;

        if length(recordings_training)<curr_day
            continue
        end
        unit_psth_smooth_norm=cell(3,1);
        unit_psth_smooth_norm_h1=cell(3,1);
        unit_psth_smooth_norm_h2=cell(3,1);

        for curr_task=1:3
            if  curr_task==1
                rec_day=recordings_passive_visual(curr_day).day;
                rec_time=recordings_passive_visual(curr_day).recording{1};
            elseif curr_task==2
                rec_day=recordings_passive_audio(curr_day).day;
                rec_time=recordings_passive_audio(curr_day).recording{1};
            elseif curr_task==3
                rec_day=recordings_training(curr_day).day;
                clear time
                if length(recordings_training(curr_day).index)>1
                    for mm=1:length(recordings_training(curr_day).index)
                        rec_time = recordings_training(curr_day).recording{mm};
                        timelite_fn = plab.locations.filename('server',animal,rec_day,rec_time,'timelite.mat');
                        timelite = load(timelite_fn);
                        time(mm)=length(timelite.timestamps);
                    end
                    [~,index_real]=max(time);
                else index_real=1;
                end
                rec_time = recordings_training(curr_day).recording{index_real};
            end

            verbose = true;
            ap.load_recording;




            % PSTH - units
            % idx = find(strcmp(probe_areas{1, 1}.safe_name, 'Caudoputamen'));
            % depth0=probe_areas{1}.probe_depth(idx,:);

            idx = find(strcmp(probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.safe_name, 'Caudoputamen'));
            depth=probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(idx,:);

            % Plot responsive units by depth
            striatal_units=any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2);
            template_sort=find(any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2));

            all_cell_deepth{curr_day}=template_depths;

            % depth of each neuron
            unit_depths_sorted=template_depths(template_sort);
            all_cell_sorted{curr_day}=template_sort;
            % all_cell_deepth_sorted{curr_day}=unit_depths_sorted;
            all_cell_deepth_sorted{curr_day}=unit_depths_sorted;

            striatal_surface_position{curr_day}= interp1( ...
                [probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(1,1), ...
                probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(end,2)], ...
                probe_histology.probe_ccf(probe_histology_day_idx).trajectory_coords, ...
                depth(1,1));


            all_cell_ccf_position_sorted{curr_day}=interp1( ...
                [probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(1,1), ...
                probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas.probe_depth(end,2)], ...
                probe_histology.probe_ccf(probe_histology_day_idx).trajectory_coords, ...
                unit_depths_sorted);


            % probe_positions{curr_day}=probe_nte.probe_positions_ccf{1};
            probe_positions{curr_day}=probe_histology.probe_ccf(probe_histology_day_idx).trajectory_coords';

            % define cell types

            if curr_task==3
                %  %  old version
                % spike_acg = nan(sum(striatal_units),2001);
                % spike_acg = cell2mat(arrayfun(@(x) ...
                %     ap.ephys_spike_cg(x),find(striatal_units),'uni',false));
                %
                % % Get time to get to 90% steady-state value
                % acg_steadystate = nan(sum(striatal_units),1);
                % acg_steadystate(~any(isnan(spike_acg),2)) = arrayfun(@(x) ...
                %     find(spike_acg(x,ceil(size(spike_acg,2)/2):end) > ...
                %     mean(spike_acg(x,end-100:end),2)*0.9,1,'first'),find(~any(isnan(spike_acg),2)));
                %
                % % (UNUSED: ACG RATIO)
                % acg_early = max(spike_acg(:,1001:1001+300),[],2);
                % acg_late = max(spike_acg(:,end-200:end-100),[],2);
                % acg_ratio = acg_late./acg_early;
                %
                % % Get average firing rate from whole session
                % spike_rate = accumarray(spike_templates,1)/diff(prctile(spike_times_timelite,[0,100]));
                %
                % % Define cell types
                % % (NOTE: Julie uses acg_steadystate of 40, seemed better here for 20)
                % striatum_celltypes = struct;
                %
                % striatum_celltypes.msn = ... % striatal_single_units & ... % striatal single unit
                %     waveform_duration_peaktrough(striatal_units) >= 400 & ... wide waveform
                %     acg_steadystate < 20; % fast time to steady state
                %
                % striatum_celltypes.fsi = ... % striatal_single_units & ... % striatal single unit
                %     waveform_duration_peaktrough(striatal_units) < 400 & ... % narrow waveform
                %     acg_steadystate < 20; % slow time to steady state
                %
                % % !! NOT USING WAVEFORM DURATION HERE - some clear TANs with short wfs
                % striatum_celltypes.tan = ... % striatal_single_units & ... % striatal single unit
                %     spike_rate(striatal_units) >= 4 & spike_rate(striatal_units) <= 16 & ... % steady firing rate
                %     acg_steadystate >= 20; % slow time to steady state

                ephysProperties = bc.ep.runAllEphysProperties(convertStringsToChars(kilosort_path), convertStringsToChars(qMetrics_path), false,[]);
                ephysProperties = ephysProperties(good_templates,:);

                striatum_celltypes = struct;

                % Set cutoffs
                spike_param_wide_narrow_wavelength = 400; % wide/narrow
                spike_param_post_spike_suppression = 40; % bursty/regular

                % MSN: long waveform, bursty spiking
                temp_msn= striatal_units & ...
                    ephysProperties.waveformDuration_peakTrough_us > spike_param_wide_narrow_wavelength &...
                    ephysProperties.postSpikeSuppression_ms < spike_param_post_spike_suppression;
                striatum_celltypes.msn=temp_msn(striatal_units);

                % FSI: short waveform, bursty spiking, 1 peak (2-peak is likely axon)
                temp_fsi = striatal_units & ...
                    ephysProperties.waveformDuration_peakTrough_us <= spike_param_wide_narrow_wavelength &...
                    ephysProperties.postSpikeSuppression_ms < spike_param_post_spike_suppression & ...
                    ephysProperties.nPeaks == 1;
                striatum_celltypes.fsi =temp_fsi(striatal_units);

                % TAN: regular spiking
                temp_tan = striatal_units & ...
                    ephysProperties.postSpikeSuppression_ms >= spike_param_post_spike_suppression;

                striatum_celltypes.tan=temp_tan(striatal_units);

                all_celltypes{curr_day}=striatum_celltypes;


            end


            % Get responsive units

            % Set event to get response
            % (get quiescent trials)
            stim_window = [0,0.5];
            quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
                timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
                (1:length(stimOn_times))');


            % surround_time = [-0.5,0.5];
            % surround_sample_rate = 1000;
            % surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
            % align_times = stimOn_times(quiescent_trials);
            % pull_times = align_times + surround_time_points;
            % event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            %     double( wheel_move),pull_times,'previous');
            %
            % figure;plot(surround_time_points,mean(event_aligned_wheel_vel,1))

            clear use_align
            if contains(bonsai_workflow,'lcr')
                % (vis passive)
                stim_type = vertcat(trial_events.values.TrialStimX);
                stim_values = unique(stim_type);
                use_align = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);
            elseif contains(bonsai_workflow,'hml')
                % (aud passive)
                stim_type = vertcat(trial_events.values.StimFrequence);
                stim_values = unique(stim_type);
                use_align = arrayfun(@(x) stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials), stim_values, 'UniformOutput', false);

            elseif contains(bonsai_workflow,'stim_wheel')
                % (task)
                % use_align = stimOn_times(stim_to_move > 0.15);
                TaskType_idx= cell2mat({trial_events.values.TaskType})';
                use_align{1,1} = stimOn_times(TaskType_idx(1:n_trials)==0 );
                use_align{2,1} = stimOn_times(TaskType_idx(1:n_trials)==1 );

                use_align{3,1} = stim_move_time(TaskType_idx(1:n_trials)==0 );
                use_align{4,1} = stim_move_time(TaskType_idx(1:n_trials)==1 );

                ds.load_iti_move
                use_align{5,1} =  iti_move_time;

            end


            [all_unit_psth_smooth_norm,temp_raster,t]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,...
                'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align,'UniformOutput',false);
            raster{curr_day}{curr_task} = cellfun(@(x)    x(:,:,template_sort),temp_raster,'UniformOutput',false);


            if curr_task==3
                plot_single{curr_day}= cellfun(@(x) x(:,:,template_sort),temp_raster(1:4),...
                    'UniformOutput',false);
                plot_idx{curr_day}= {stim_to_move(TaskType_idx(1:n_trials)==0);...
                    stim_to_move(TaskType_idx(1:n_trials)==1)};
            end

            % 生成所有的索引
            rand_idx_all = cellfun(@(x) randperm(length(x)), use_align, 'UniformOutput', false);
            % 拆分索引
            half_idx = cellfun(@(idx) idx(1:floor(length(idx)/2)), rand_idx_all, 'UniformOutput', false);
            rest_idx = cellfun(@(idx) idx(floor(length(idx)/2)+1:end), rand_idx_all, 'UniformOutput', false);
            % 按索引取值
            use_align_half1 = cellfun(@(x, idx) sort(x(idx)), use_align, half_idx, 'UniformOutput', false);
            use_align_half2 = cellfun(@(x, idx) sort(x(idx)), use_align, rest_idx, 'UniformOutput', false);

            [all_unit_psth_smooth_norm_h1,~,~]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align_half1,'UniformOutput',false);
            [all_unit_psth_smooth_norm_h2,~,~]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align_half2,'UniformOutput',false);


            unit_psth_smooth_norm{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm,'UniformOutput',false);
            % unit_raster_smooth_norm{curr_task} = cellfun(@(x)    x(:,:,template_sort),raster,'UniformOutput',false);
            unit_psth_smooth_norm_h1{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm_h1,'UniformOutput',false);
            unit_psth_smooth_norm_h2{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm_h2,'UniformOutput',false);



            for curr_i=1:length(use_align)
                switch curr_task
                    case {1,2}
                        baseline_bins = use_align{curr_i} + baseline_t_stim;
                        response_bins = use_align{curr_i} + response_t_stim;

                    case 3
                        switch curr_i
                            case {1,2}
                                baseline_bins = use_align{curr_i} + baseline_t_stim;
                                response_bins = use_align{curr_i} + response_t_stim;
                            case {3,4,5}
                                baseline_bins = use_align{curr_i} + baseline_t_move;
                                response_bins = use_align{curr_i} + response_t_move;
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




        end


        % % draw cell position in probe track
        %   unit_dots = ap.plot_unit_depthrate(spike_templates(ismember(spike_templates, template_sort)),template_depths,probe_areas);
        % %
        % unit_dots = ap.plot_unit_depthrate(spike_templates(ismember(spike_templates, template_sort)),...
        %     template_depths,probe_histology.probe_ccf(probe_histology_day_idx).trajectory_areas);
        %
        % % spike_times=spike_templates(ismember(spike_templates, template_sort));
        %
        %
        % unit_dots.CData = +([0,0,1].*(event_response_p{1}{3} > 0.95)) ...
        %     +([0,0,1].*(event_response_p{3}{1} > 0.95)) ...
        %     + ([1, 0,0].*(event_response_p{2}{2} > 0.95))...
        %     + ([1, 0,0].*(event_response_p{3}{2} > 0.95))    ;
        % title([ animal '-day ' num2str(curr_day) ])
        % saveas(gcf,[Path 'figures\summary\probe of ' animal ' in day ' num2str(curr_day)], 'jpg');
        % close

        %
        obj=ap.ccf_draw
        obj.draw_name('caudoputamen')
        obj.draw_name('caudoputamen')

        obj.ccf_fig.Position=[50 50 200 600]

        probe_line=probe_positions{curr_day}';
        % Draw probes on coronal + saggital
        line(obj.ccf_axes(1),probe_line(:,3),probe_line(:,2),'linewidth',2,'color',[0 0 0]);
        line(obj.ccf_axes(2),probe_line(:,3),probe_line(:,1),'linewidth',2,'color',[0 0 0]);
        line(obj.ccf_axes(3),probe_line(:,2),probe_line(:,1),'linewidth',2,'color',[0 0 0]);
        line(obj.ccf_axes(4),probe_line(:,1),probe_line(:,3),probe_line(:,2), ...
            'linewidth',2,'color',[0 0 0])
        sgtitle([ animal '-day ' num2str(curr_day) ])
        saveas(gcf,[Path 'figures\summary\probe of ' animal ' in day ' num2str(curr_day) ' in 3d position '], 'jpg');
        close









        % package_unit_raster_smooth_norm = [unit_raster_smooth_norm{1}, unit_raster_smooth_norm{2}, unit_raster_smooth_norm{3}'];

        package_unit_psth_smooth_norm = [unit_psth_smooth_norm{1}', unit_psth_smooth_norm{2}', unit_psth_smooth_norm{3}'];

        package_event_response_p=cat(2,event_response_p{:});
        plot_mean=cellfun(@(x,y) nanmean(x( find( y > 0.95),:),1),package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );

        plot_sem=cellfun(@(x,y) std(x(find( y > 0.95 ),:),0,1)/sqrt(size(x(find( y>0.95 ),:),1)), package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        plot_mean_from_r=cellfun(@(x,y) nanmean(x( find( y > 0.95),:),1),package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        plot_sem_from_r=cellfun(@(x,y) std(x(find( y > 0.95),:),0,1)/sqrt(size(x(find( y>0.95 ),:),1)), package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        all_responsive_idx =cell2mat(cellfun(@(x)   cell2mat(x),event_response_p','UniformOutput',false));
        % all_responsive = all_responsive_idx(~all(all_responsive_idx == 0, 2), :);
        all_event_response_idx{curr_day}=all_responsive_idx;
        all_event_response_plot{curr_day}=cat(1,plot_mean{:});
        all_event_response_signle_neuron{curr_day}=cat(3,package_unit_psth_smooth_norm{:});
        % all_event_response_signle_neuron_single_trial{curr_day}=package_unit_raster_smooth_norm;


        package_unit_psth_smooth_norm_h1 = [unit_psth_smooth_norm_h1{1}', unit_psth_smooth_norm_h1{2}', unit_psth_smooth_norm_h1{3}'];
        package_unit_psth_smooth_norm_h2 = [unit_psth_smooth_norm_h2{1}', unit_psth_smooth_norm_h2{2}', unit_psth_smooth_norm_h2{3}'];
        all_event_response_signle_neuron_h1{curr_day}=cat(3,package_unit_psth_smooth_norm_h1{:});
        all_event_response_signle_neuron_h2{curr_day}=cat(3,package_unit_psth_smooth_norm_h2{:});



        figure('Position',[50 50 1200 200])
        for curr_stim=1:11
            nexttile
            reponsive_data=package_unit_psth_smooth_norm{curr_stim}(find(package_event_response_p{curr_stim}>0.95),:);
            [~,sort_idx] = sort(nanmean(reponsive_data(: ,psth_use_t_stim),[2,3]));
            imagesc(t_centers,[],reponsive_data(sort_idx,:));
            colormap(ap.colormap('BWR'));
            clim([-5,5]);
            title(titles{curr_stim})
        end

        for curr_stim=1:11
            nexttile
            ap.errorfill([t_centers 1],plot_mean{curr_stim},plot_sem{curr_stim},[1 0 0],0.1,0.5);
            hold on
            ap.errorfill([t_centers 1],plot_mean_from_r{curr_stim},plot_sem_from_r{curr_stim},[0 0 0],0.1,0.5);
            ylim([-1 7])
            % ylabel('z-score')
            xlabel('time (s)')
        end
        sgtitle([animal ' day' num2str(curr_day) ])
        saveas(gcf,[Path 'figures\summary\plot and heatmap of ' animal ' in day ' num2str(curr_day)], 'jpg');
        close
        ap.print_progress_fraction(curr_day,length(recordings_training));
        clearvars('-except',preload_vars{:});

    end

    save([Path 'single_mouse\' animal '_ephys.mat'],'all_cell_sorted',...
        'all_cell_deepth_sorted','probe_positions','all_event_response_idx','all_event_response_plot',...
        'all_event_response_signle_neuron','all_event_response_signle_neuron_h1',...
        'all_event_response_signle_neuron_h2','all_celltypes','all_cell_ccf_position_sorted','striatal_surface_position',...
        'plot_single','plot_idx','-v7.3')


end



