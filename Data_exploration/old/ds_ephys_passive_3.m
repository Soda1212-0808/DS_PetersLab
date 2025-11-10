
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

%% run process
animals_all_cell_deepth_sorted=cell(length(animals),1);
animals_all_cell_ccf_position_sorted=cell(length(animals),1);

animals_all_cell_sorted=cell(length(animals),1);
animals_all_event_response=cell(length(animals),1);
animals_probe_positions=cell(length(animals),1);
animals_all_event_plot=cell(length(animals),1);
animals_all_event_single_plot=cell(length(animals),1);
% animals_all_event_single_plot_single_trial=cell(length(animals),1);
animals_all_event_single_plot_h1=cell(length(animals),1);
animals_all_event_single_plot_h2=cell(length(animals),1);
animals_all_celltypes=cell(length(animals),1);
animals_plot_single=cell(length(animals),1);
animals_plot_idx=cell(length(animals),1);
animals_raster=cell(length(animals),1);


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







%% load data
load([Path 'mat_data\ephys_all_data.mat'])
% load([Path 'mat_data\ephys_single_trial.mat'])

%
% fraction of populations
%%
filtered_VA=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true)) ,...
    anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true))','UniformOutput',false);

filtered_AV=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true)) ,...
    anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true))','UniformOutput',false);

filtered_VA_nA=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true)) ,...
    anterior_learned_idx_VA_nA(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true))','UniformOutput',false);

filtered_AV_nA=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_AV_nA','UniformOutput',true)) ,...
    anterior_learned_idx_AV_nA(~cellfun(@isempty, anterior_learned_idx_AV_nA','UniformOutput',true))','UniformOutput',false);

filtered_VnA_nA=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_VnA_nA','UniformOutput',true)) ,...
    anterior_learned_idx_VnA_nA(~cellfun(@isempty, anterior_learned_idx_VnA_nA','UniformOutput',true))','UniformOutput',false);

filtered_AnV_nV=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, anterior_learned_idx_AnV_nV','UniformOutput',true)) ,...
    anterior_learned_idx_AnV_nV(~cellfun(@isempty, anterior_learned_idx_AnV_nV','UniformOutput',true))','UniformOutput',false);



celltypes_VA=cellfun(@(x,y)  x(y),animals_all_celltypes(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true)) ,...
    anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true))','UniformOutput',false);
celltypes_AV=cellfun(@(x,y)  x(y),animals_all_celltypes(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true)) ,...
    anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true))','UniformOutput',false);


proportion_VA_msn= cellfun(@(x) sum(x.msn)/length(x.msn), vertcat(celltypes_VA{:}),'UniformOutput',true);
proportion_VA_fsi= cellfun(@(x)  sum(x.fsi)/length(x.fsi), vertcat(celltypes_VA{:}),'UniformOutput',true);
proportion_VA_tan= cellfun(@(x)  sum(x.tan)/length(x.tan), vertcat(celltypes_VA{:}),'UniformOutput',true);
proportion_celltpe_VA={proportion_VA_msn,proportion_VA_fsi,proportion_VA_tan}

proportion_AV_msn= cellfun(@(x) sum(x.msn)/length(x.msn), vertcat(celltypes_AV{:}),'UniformOutput',true);
proportion_AV_fsi= cellfun(@(x)  sum(x.fsi)/length(x.fsi), vertcat(celltypes_AV{:}),'UniformOutput',true);
proportion_AV_tan= cellfun(@(x)  sum(x.tan)/length(x.tan), vertcat(celltypes_AV{:}),'UniformOutput',true);
proportion_celltpe_AV={proportion_AV_msn,proportion_AV_fsi,proportion_AV_tan}


proportion_VA_msn_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.msn )/sum(x.msn),...
    vertcat(filtered_VA{:}),vertcat(celltypes_VA{:}),'UniformOutput',true),1:9,'UniformOutput',false);
proportion_AV_msn_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.msn )/sum(x.msn),...
    vertcat(filtered_AV{:}),vertcat(celltypes_AV{:}),'UniformOutput',true),1:9,'UniformOutput',false);

proportion_VA_fsi_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.fsi )/sum(x.fsi),...
    vertcat(filtered_VA{:}),vertcat(celltypes_VA{:}),'UniformOutput',true),1:9,'UniformOutput',false);
proportion_AV_fsi_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.fsi )/sum(x.fsi),...
    vertcat(filtered_AV{:}),vertcat(celltypes_AV{:}),'UniformOutput',true),1:9,'UniformOutput',false);

proportion_VA_tan_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.tan )/sum(x.tan),...
    vertcat(filtered_VA{:}),vertcat(celltypes_VA{:}),'UniformOutput',true),1:9,'UniformOutput',false);
proportion_AV_tan_respon=arrayfun(@(i) cellfun(@(y,x) sum(y(:,i)==1&x.tan )/sum(x.tan),...
    vertcat(filtered_AV{:}),vertcat(celltypes_AV{:}),'UniformOutput',true),1:9,'UniformOutput',false);


proportion_VA=arrayfun(@(i)  cellfun(@(y) sum(y(:,i)==1)/size(y,1) ,vertcat(filtered_VA{:}),'UniformOutput',true ),1:9,'UniformOutput',false);
proportion_AV=arrayfun(@(i) cellfun(@(y) sum(y(:,i)==1)/size(y,1) ,vertcat(filtered_AV{:}),'UniformOutput',true ),1:9,'UniformOutput',false);



VA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA_nA,'UniformOutput',false ),1:9,'UniformOutput',false);
AV_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV_nA,'UniformOutput',false ),1:9,'UniformOutput',false);
VnA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VnA_nA,'UniformOutput',false ),1:9,'UniformOutput',false);
AnV_nV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AnV_nV,'UniformOutput',false ),1:9,'UniformOutput',false);

VA_R=cellfun(@(x) cellfun(@(y) sum(y(:,3)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false );
VA_8k=cellfun(@(x) cellfun(@(y) sum(y(:,5)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false );
VA_8k_R=cellfun(@(x) cellfun(@(y) sum(y(:,3)==1&y(:,5)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false );
VA_all= cellfun(@(x) cellfun(@(y) size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false );


AV_R=cellfun(@(x) cellfun(@(y) sum(y(:,3)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false );
AV_8k=cellfun(@(x) cellfun(@(y) sum(y(:,5)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false );
AV_8k_R=cellfun(@(x) cellfun(@(y) sum(y(:,3)==1&y(:,5)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false );
AV_all= cellfun(@(x) cellfun(@(y) size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false );

VA_8k_audio_select=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1&y(:,5)==1)/sum(y(:,5)==1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false ),4:6,'UniformOutput',false);
AV_8k_audio_select=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1&y(:,5)==1)/sum(y(:,5)==1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false ),4:6,'UniformOutput',false);

VA_8k_visual_select=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1&y(:,3)==1)/sum(y(:,3)==1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false ),1:3,'UniformOutput',false);
AV_8k_visual_select=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1&y(:,3)==1)/sum(y(:,3)==1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false ),1:3,'UniformOutput',false);


%% Bar plot of proportion
figure('Position',[50 50 650 180]);
colors=[[  84 130 53 ]./255;[112  48 160]./255];

titles={'ALL','MSN','FSI','TAN'}
for curr_figure =1:4
    switch curr_figure
        case 1
            group1=cat(2,proportion_VA{[7,8 ,4 ,5]});
            group2=cat(2,proportion_AV{[7 ,8, 4, 5]});
        case 2
            group1=cat(2,proportion_VA_msn_respon{[7,8 ,4 ,5]});
            group2=cat(2,proportion_AV_msn_respon{[7,8 ,4 ,5]});

        case 3
            group1=cat(2,proportion_VA_fsi_respon{[7,8 ,4 ,5]});
            group2=cat(2,proportion_AV_fsi_respon{[7,8 ,4 ,5]});
        case 4
            group1=cat(2,proportion_VA_tan_respon{[7,8 ,4 ,5]});
            group2=cat(2,proportion_AV_tan_respon{[7,8 ,4 ,5]});
    end



    % group1=cat(2,proportion_celltpe_VA{:});
    % group2=cat(2,proportion_celltpe_AV{:});


    data={group1,group2};
    means = [mean(group1, 1);mean(group2, 1)]';
    sems = [std(group1, 0, 1) ./ sqrt(size(group1,1));std(group2, 0, 1) ./ sqrt(size(group2,1))]';
    p = arrayfun(@(num)  ranksum(group1(:,num), group2(:,num)),1:size(group1,2),'UniformOutput',true);
    % 绘图
    nexttile
    hold on;
    bar_handle = bar(means, 'grouped');
    % colors = [0.3 0.6 0.9; 0.9 0.4 0.4];
    for g = 1:2
        bar_handle(g).FaceColor = colors(g,:);
        bar_handle(g).EdgeColor = colors(g,:);

        bar_handle(g).FaceAlpha = 0.5;

    end

    % 添加误差线
    ngroups = size(means,1);
    nbars = size(means,2);
    groupwidth = min(0.8, nbars/(nbars + 1.5));
    x = nan(ngroups, nbars);
    for j = 1:nbars
        x(:,j) = (1:ngroups)' - groupwidth/2 + (2*j-1) * groupwidth / (2*nbars);
        errorbar(x(:,j), means(:,j), sems(:,j), 'k.', 'LineWidth', 1);
    end

    % 添加散点
    arrayfun(@(g) scatter(x(:,g)' + randn(size(data{g},1),1)*0.05, ...
        data{g}, 20, 'filled', ...
        'MarkerFaceColor', colors(g,:)), 1:2);

    % 添加显著性标记
    ymax = squeeze(max(max(group2,[],1),[],3));
    for i = 1:ngroups
        if p(i) < 0.05
            stars = repmat('*',1,sum(p(i)<[0.05 0.01 0.001]));
            y_sig = max(data{1}(:,i)) + 0.2;
            plot(x(i,[1 2]), [1 1]*y_sig, 'k-');
            text(mean(x(i,:)), y_sig+0.05, stars, 'HorizontalAlignment','center');
        end
    end

    % 格式设置
    xticks([1:4]);
    xticklabels({'V task','A task','V passive','A passive'});
    ylabel('proportion(%)');
    % legend({'VA','AV'}, 'Location','best','Box','off');
    box off;
    title(titles{curr_figure})
end
saveas(gcf,[Path 'figures\summary\proportion_responsive neurons VA VS AV ' ], 'jpg');

%%
Result(1).name='visual2audio';
Result(1).data={VA_R,VA_8k,VA_8k_R,AV_R,AV_8k,AV_8k_R};
Result(1).label_names={'VA-R', 'VA-8k','VA-R&8k','AV-R', 'AV-8k','AV-R&8k'};

Result(2).name='response VA AV';
Result(2).data=[proportion_VA,proportion_AV];
Result(2).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k','VA-L-task','VA-8k-task','VA-iti-move','AV-L', 'AV-M','AV-R','AV-4k', 'AV-8k','AV-12k','AV-L-task','AV-8k-task','AV-iti-move'};

Result(3).name='audio selectivity';
Result(3).data=[VA_8k_audio_select,AV_8k_audio_select];
Result(3).label_names={'VA-4k', 'VA-8k','VA-12k','AV-4k', 'AV-8k','AV-12k'};

Result(4).name='visual selectivity';
Result(4).data=[VA_8k_visual_select,AV_8k_visual_select];
Result(4).label_names={'VA-L', 'VA-M','VA-R','AV-L', 'AV-M','AV-R'};

Result(5).name='response VA AV nA';
Result(5).data=[ VA_nA_each,AV_nA_each];
Result(5).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k','AV-L', 'AV-M','AV-R','AV-4k', 'AV-8k','AV-12k'};

Result(6).name='response VnA  nA';
Result(6).data=[ VnA_nA_each];
Result(6).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k'};

Result(7).name='response AnV  nV';
Result(7).data=[ AnV_nV_each];
Result(7).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k'};

%
for curr_fig=1
    Result2=Result(curr_fig).data;
    % 计算均值和标准误差（SEM）
    numGroups = length(Result2);
    means = zeros(numGroups, 1);
    errors = zeros(numGroups, 1);
    all_data = cell(numGroups, 1);

    for curr_i = 1:numGroups
        % 展平当前 cell 内所有子 cell，转为一个数值向量
        flat_data = cell2mat(Result2{curr_i});
        all_data{curr_i} = flat_data;
        means(curr_i) = median(flat_data);
        errors(curr_i) = std(flat_data) / sqrt(length(flat_data)); % 计算标准误差 SEM
    end

    barColors = [0.3 0.6 0.9; 0.9 0.3 0.3];
    % 画柱状图
    figure('Position',[50 50 numGroups*30 400]);
    hold on;
    b=bar(means, 'FaceColor', 'flat', 'EdgeColor', 'k'); % 柱状图
    for curr_i = 1:numGroups
        if curr_i<=numGroups/2
            b.CData(curr_i, :) = barColors(1, :); % 设置每个柱子的颜色
        else
            b.CData(curr_i, :) = barColors(2, :); % 设置每个柱子的颜色
        end
    end

    % 画误差棒
    x = 1:numGroups;
    errorbar(x, means, errors, 'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 10);

    % 生成不同颜色组：
    % numSubCells = max(cellfun(@length, Result2(1:numGroups/2))); % 统计前三个 cell 最大的子 cell 数量
    colors1 = turbo(max(cellfun(@length, Result2(1:numGroups/2)))); % 前三组用 cool 颜色
    colors2 = hsv(max(cellfun(@length, Result2(numGroups/2+1:numGroups))));  % 后三组用 hot 颜色

    % 画散点图
    for curr_i = 1:numGroups
        subCells = Result2{curr_i}; % 取出当前组的子 cell
        numSubCells = length(subCells);

        for j = 1:numSubCells
            data_points = subCells{j}; % 取出子 cell 里的数值
            x_jittered = curr_i + (rand(size(data_points)) - 0.5) * 0.2; % 轻微抖动避免重叠

            % 颜色选择：
            % - 前三个 cell (1~3) 使用 colors1(j, :)
            % - 后三个 cell (4~6) 使用 colors2(j, :)
            % 防止颜色索引超出范围
            if curr_i <= numGroups/2
                color_index = min(j, size(colors1,1));
                scatter(x_jittered, data_points, 60, colors1(color_index, :), ...
                    'filled', 'MarkerFaceAlpha', 0.8); % 画散点，前 3 组用 cool 颜色
            else
                color_index = min(j, size(colors2,1));
                scatter(x_jittered, data_points, 60, colors2(color_index, :), ...
                    'filled', 'MarkerFaceAlpha', 0.8); % 画散点，后 3 组用 hot 颜色
            end
        end
    end

    % 图像美化
    xticks([1:numGroups]);

    xticklabels(Result(curr_fig).label_names);

    ylabel('proportion');
    xlim([0.5, numGroups + 0.5]); % 限制 x 轴范围
    grid off;
    hold off;
    % ylim([0 0.5])
    title(Result(curr_fig).name)
    saveas(gcf,[Path 'figures\summary\all_proportion_anterior striatum ' Result(curr_fig).name], 'jpg');
    savefig (gcf,[Path 'figures\summary\all_proportion_anterior striatum ' Result(curr_fig).name]);

end


%% plot of populations 柱状图

plot_VA=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true)) ,...
    anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true))','UniformOutput',false);

plot_AV=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true)) ,...
    anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true))','UniformOutput',false);

plot_VA_nA=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true)) ,...
    anterior_learned_idx_VA_nA(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true))','UniformOutput',false);

plot_AV_nA=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_AV_nA','UniformOutput',true)) ,...
    anterior_learned_idx_AV_nA(~cellfun(@isempty, anterior_learned_idx_AV_nA','UniformOutput',true))','UniformOutput',false);

plot_VnA_nA=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_VnA_nA','UniformOutput',true)) ,...
    anterior_learned_idx_VnA_nA(~cellfun(@isempty, anterior_learned_idx_VnA_nA','UniformOutput',true))','UniformOutput',false);

plot_AnV_nV=cellfun(@(x,y)  x(y),animals_all_event_plot(~cellfun(@isempty, anterior_learned_idx_AnV_nV','UniformOutput',true)) ,...
    anterior_learned_idx_AnV_nV(~cellfun(@isempty, anterior_learned_idx_AnV_nV','UniformOutput',true))','UniformOutput',false);

proportion_VA=arrayfun(@(i) cellfun(@(x) cellfun(@(y)  max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VA,'UniformOutput',false ),1:6,'UniformOutput',false);
proportion_AV=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AV,'UniformOutput',false ),1:6,'UniformOutput',false);
VA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AV_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AV_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
VnA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VnA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AnV_nV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AnV_nV,'UniformOutput',false ),1:6,'UniformOutput',false);


Result(1).name='response VA AV';
Result(1).data=[proportion_VA,proportion_AV];
Result(1).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k','AV-L', 'AV-M','AV-R','AV-4k', 'AV-8k','AV-12k'};

Result(2).name='response VA AV nA';
Result(2).data=[ VA_nA_each,AV_nA_each];
Result(2).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k','AV-L', 'AV-M','AV-R','AV-4k', 'AV-8k','AV-12k'};

Result(3).name='response VnA  nA';
Result(3).data=[ VnA_nA_each];
Result(3).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k'};

Result(4).name='response AnV  nV';
Result(4).data=[ AnV_nV_each];
Result(4).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k'};

%
for curr_fig=1:4
    Result2=Result(curr_fig).data;
    % 计算均值和标准误差（SEM）
    numGroups = length(Result2);
    means = zeros(numGroups, 1);
    errors = zeros(numGroups, 1);
    all_data = cell(numGroups, 1);

    for curr_i = 1:numGroups
        % 展平当前 cell 内所有子 cell，转为一个数值向量
        flat_data = cell2mat(Result2{curr_i});
        all_data{curr_i} = flat_data;
        means(curr_i) = mean(flat_data,'omitmissing');
        errors(curr_i) = std(flat_data,'omitmissing') / sqrt(length(flat_data)); % 计算标准误差 SEM
    end

    barColors = [0.3 0.6 0.9; 0.9 0.3 0.3];
    % 画柱状图
    figure('Position',[50 50 numGroups*30 400]);
    hold on;
    b=bar(means, 'FaceColor', 'flat', 'EdgeColor', 'k'); % 柱状图
    for curr_i = 1:numGroups
        if curr_i<=numGroups/2
            b.CData(curr_i, :) = barColors(1, :); % 设置每个柱子的颜色
        else
            b.CData(curr_i, :) = barColors(2, :); % 设置每个柱子的颜色
        end
    end

    % 画误差棒
    x = 1:numGroups;
    errorbar(x, means, errors, 'k', 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 10);

    % 生成不同颜色组：
    % numSubCells = max(cellfun(@length, Result2(1:numGroups/2))); % 统计前三个 cell 最大的子 cell 数量
    colors1 = turbo(max(cellfun(@length, Result2(1:numGroups/2)))); % 前三组用 cool 颜色
    colors2 = hsv(max(cellfun(@length, Result2(numGroups/2+1:numGroups))));  % 后三组用 hot 颜色

    % 画散点图
    for curr_i = 1:numGroups
        subCells = Result2{curr_i}; % 取出当前组的子 cell
        numSubCells = length(subCells);

        for j = 1:numSubCells
            data_points = subCells{j}; % 取出子 cell 里的数值
            x_jittered = curr_i + (rand(size(data_points)) - 0.5) * 0.2; % 轻微抖动避免重叠

            % 颜色选择：
            % - 前三个 cell (1~3) 使用 colors1(j, :)
            % - 后三个 cell (4~6) 使用 colors2(j, :)
            % 防止颜色索引超出范围
            if curr_i <= numGroups/2
                color_index = min(j, size(colors1,1));
                scatter(x_jittered, data_points, 60, colors1(color_index, :), ...
                    'filled', 'MarkerFaceAlpha', 0.8); % 画散点，前 3 组用 cool 颜色
            else
                color_index = min(j, size(colors2,1));
                scatter(x_jittered, data_points, 60, colors2(color_index, :), ...
                    'filled', 'MarkerFaceAlpha', 0.8); % 画散点，后 3 组用 hot 颜色
            end
        end
    end

    % 图像美化
    xticks([1:numGroups]);

    xticklabels(Result(curr_fig).label_names);

    ylabel('peak');
    xlim([0.5, numGroups + 0.5]); % 限制 x 轴范围
    grid off;
    hold off;
    ylim([0 5])
    title(['peak of ' Result(curr_fig).name])
    saveas(gcf,[Path 'figures\summary\peak_anterior striatum '  Result(curr_fig).name ], 'jpg');
end


%%  heat map
groups={'VA','AV','VA_nA'}
for curr_group=1

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])


    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_1 = vertcat(single_plot_1{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});

    single_plot_h2=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h2(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_h2 = vertcat(single_plot_h2{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all_h2=cat(1,single_neuron_each_rec_h2{:});


    response_each_rec= vertcat(used_filter_idx{:});
    response_all=cat(1,response_each_rec{:});

    use_idx= any(response_all(:,[3 5 7 8]) == 1, 2)&(~(all(response_all(:,1:6) == 0, 2) & response_all(:,9)==1));

    use_idx_each_rec=cellfun(@(x) any(x(:,[3 5 7 8]) == 1, 2)&(~(all(x(:,1:6) == 0, 2) & x(:,9)==1)) , response_each_rec,'UniformOutput',false );

    clim_value=[-3,3];
    figure('Position',[50 50 1000 1000]);
    used_matrix=[3 5 7 8 9]
    tiledlayout(length(used_matrix),length(used_matrix)); % 创建一个1行2列的布局
    titles={'L','M','R','4k','8k','12k','R task','8k task','R task move','8k task move','iti move'};

    for curr_i=used_matrix
        [~,max_idx]=max(single_neuron_all_1(: ,psth_use_t_stim,curr_i),[],2);
        [~,sort_idx] = sortrows([response_all(:,curr_i), max_idx],[1,2],["descend","ascend"]);

        used_neruons=single_neuron_all_1(sort_idx,:,:);
        used_neruons_sort=used_neruons(use_idx(sort_idx),:,:);
        for curr_idx=used_matrix
            nexttile
            imagesc(t_centers,[],used_neruons_sort(:,:,curr_idx))
            % yline(sum(response_2(:,3)),'Color',[0 1 0],'LineWidth',1)
            colormap(ap.colormap('BWR'));
            clim(clim_value);
            xlabel('time (s)')
            title(titles{curr_idx})
        end

    end
    sgtitle(groups{curr_group})
    saveas(gcf,[Path 'figures\summary\heatmap responsive vs no responsive in '  groups{curr_group}], 'jpg');
    savefig (gcf,[Path 'figures\summary\heatmap responsive vs no responsive in '  groups{curr_group}]);


    figure('Position',[50 50 1000 1000]);
    tiledlayout(length(used_matrix),length(used_matrix)); % 创建一个1行2列的布局

    for curr_i=used_matrix


        selected_neurons_each_rec=cellfun( @(x,y)  x(y,:,:), single_neuron_each_rec_1,use_idx_each_rec,'UniformOutput',false );
        selected_responses_each_rec=cellfun(@(x,y) x(y,curr_i) ,response_each_rec,use_idx_each_rec,'UniformOutput',false  );
        [~, max_idx_each_rec] = cellfun(@(x)   max(x(:, psth_use_t_stim, curr_i), [], 2),selected_neurons_each_rec,'UniformOutput',false);
        % 排序：先按 response 值降序，再按 max_idx 升序
        [~, sort_idx_each_rec] =cellfun(@(x,y) sortrows([x, y], [1,2], ["descend","ascend"]),selected_responses_each_rec,max_idx_each_rec,'UniformOutput',false);
        sorted_neurons_each_rec =cellfun(@(x,y)  x(y, :, :) ,selected_neurons_each_rec,sort_idx_each_rec,'UniformOutput',false  );

        used_neruons_only_mean_each_rec=cellfun(@(x,y,z)  permute(mean(x(1:sum(y(z,curr_i)),:,:),1,'omitmissing'),[2 3 1]),...
            sorted_neurons_each_rec,response_each_rec,use_idx_each_rec,'UniformOutput',false);
        used_neruons_only_error_each_rec= std(cat(3,used_neruons_only_mean_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));

        used_neruons_non_responsive_mean_each_rec=cellfun(@(x,y,z)  permute(mean(x(sum(y(z,curr_i)):end,:,:),1,'omitmissing'),[2 3 1]),...
            sorted_neurons_each_rec,response_each_rec,use_idx_each_rec,'UniformOutput',false);
        used_neruons_non_responsive_error_each_rec=std(cat(3,used_neruons_non_responsive_mean_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_non_responsive_mean_each_rec));



        selected_neurons = single_neuron_all_1(use_idx, :, :);
        selected_responses = response_all(use_idx, curr_i);

        % 计算每个神经元在 psth_use_t 处的最大值索引
        [~, max_idx] = max(selected_neurons(:, psth_use_t_stim, curr_i), [], 2);



        % 排序：先按 response 值降序，再按 max_idx 升序
        [~, sort_idx] = sortrows([selected_responses, max_idx], [1,2], ["descend","ascend"]);
        sorted_neurons = selected_neurons(sort_idx, :, :);

        used_neurons_only_mean=permute(mean(sorted_neurons(1:sum(response_all(use_idx,curr_i)),:,:),1,'omitmissing'),[2 3 1]);
        used_neruons_non_responsive_mean=permute(mean(sorted_neurons(sum(response_all(use_idx,curr_i)):end,:,:),1,'omitmissing'),[2 3 1]);

        for curr_idx=used_matrix
            nexttile
            ap.errorfill(t_bins,used_neurons_only_mean(:,curr_idx),used_neruons_only_error_each_rec(:,curr_idx),[1 0 0],0.1 ,0.5);

            hold on
            ap.errorfill(t_bins,used_neruons_non_responsive_mean(:,curr_idx),used_neruons_non_responsive_error_each_rec(:,curr_idx),[0 0 0],0.1 ,0.5);
            ylim([-0.5 5])
            xlabel('time (s)')
            title(titles{curr_idx})
        end

    end
    sgtitle(groups{curr_group})
    % savefig (gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}]);
    %  saveas(gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}], 'jpg');
end
%
for curr_group=1:2

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}]);

    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_1 = vertcat(single_plot_1{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});

    response_each_rec= vertcat(used_filter_idx{:});
    response_all=cat(1,response_each_rec{:});


    [response_all_sorted,sort_idx] = sortrows(response_all,[9,8,5],"descend");
    figure;
    imagesc(response_all_sorted)
    colormap(ap.colormap('WK'));
    title(groups{curr_group})
    xticks([1:9]);
    xticklabels(titles);
end


%%
neuron_type={'tan','fsi','msn'}
curr_type=2
groups={'VA','AV','VA_nA'}

figure('Position',[50 50 1200 900]);
tt= tiledlayout(1,2); % 创建一个1行2列的布局
sgtitle(neuron_type{curr_type})

for curr_group=1:2

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])


    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_1 = vertcat(single_plot_1{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});



    no_empty_idx=~cellfun(@isempty, used_idx','UniformOutput',true);
    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(no_empty_idx) ,...
        used_idx(no_empty_idx)','UniformOutput',false);


    strcut_idx=cellfun(@(x) cellfun(@(y) strcmp('struct', class(y))  ,x,'UniformOutput',true) ,animals_all_celltypes,'UniformOutput',false) ;

    neurons_type=cellfun(@(x,y,z,h) cellfun(@(s,q) find(s.(neuron_type{curr_type})==1&sum(q(:,[3 5 7 8]), 2) > 0) ,...
        x(intersect(find(z),h)),y(intersect(find(z),h)),'UniformOutput',false) ,...
        animals_all_celltypes(no_empty_idx),animals_all_event_response(no_empty_idx),strcut_idx(no_empty_idx),...
        used_idx(no_empty_idx)','UniformOutput',false)  ;

    selected_neurons=cellfun(@(x,y) cellfun(@(a1,a2)  a1(a2,:,:)  ,x,y,'UniformOutput',false)  ,single_plot_1,neurons_type,'UniformOutput',false)
    selected_neurons_0 = vertcat(selected_neurons{:});
    selected_neurons_1=cat(1,selected_neurons_0{:});


    responsive_neurons=cellfun(@(x,y) cellfun(@(a1,a2)  a1(a2,:)  ,x,y,'UniformOutput',false)  ,used_filter_idx,neurons_type,'UniformOutput',false)
    responsive_neurons_0= vertcat(responsive_neurons{:});
    responsive_neurons_1=cat(1,responsive_neurons_0{:});

    clim_value=[-3,3];

    t_group = tiledlayout(tt,length(used_matrix)*2,length(used_matrix));
    t_group.Layout.Tile = curr_group;
    title(t_group,groups{curr_group});



    used_matrix=[7 3 8 5]
    titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};
    for curr_i=used_matrix
        [~,max_idx]=max(selected_neurons_1(: ,psth_use_t_stim,curr_i),[],2);
        [~,sort_idx] = sortrows([responsive_neurons_1(:,curr_i), max_idx],[1,2],["descend","ascend"]);

        used_neruons=selected_neurons_1(sort_idx,:,:);
        for curr_idx=used_matrix
            nexttile(t_group)
            imagesc(t_centers,[],used_neruons(:,:,curr_idx))
            yline(sum(responsive_neurons_1(:,curr_i)),'Color',[0 1 0],'LineWidth',1)
            colormap(ap.colormap('KWR'));
            clim(clim_value);
            xlabel('time (s)')
            title(titles{curr_idx})
        end

    end
    sgtitle(groups{curr_group})
    % saveas(gcf,[Path 'figures\summary\heatmap responsive vs no responsive in '  groups{curr_group}], 'jpg');
    % savefig (gcf,[Path 'figures\summary\heatmap responsive vs no responsive in '  groups{curr_group}]);






    % figure('Position',[50 50 1000 1000]);
    % used_matrix=[7 3 8 5]
    % tiledlayout(length(used_matrix),length(used_matrix)); % 创建一个1行2列的布局
    % titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};
    for curr_i=used_matrix


        responsive_neruons=selected_neurons_1(responsive_neurons_1(:, curr_i)==1,:,:);
        non_responsive_neruons=selected_neurons_1(responsive_neurons_1(:, curr_i)==0,:,:);

        responsive_neuron_mean=permute(nanmean(responsive_neruons,1),[2,3,1]);
        responsive_neuron_error=permute(std(responsive_neruons,0,1,'omitmissing'),[2,3,1])./sqrt(size(responsive_neruons,1));

        non_responsive_neuron_mean=permute(nanmean(non_responsive_neruons,1),[2,3,1]);
        non_responsive_neuron_error=permute(std(non_responsive_neruons,0,1,'omitmissing'),[2,3,1])./sqrt(size(non_responsive_neruons,1));

        for curr_idx=used_matrix
            nexttile(t_group)
            ap.errorfill(t_bins,responsive_neuron_mean(:,curr_idx),responsive_neuron_error(:,curr_idx),[1 0 0],0.1 ,0.5);
            hold on
            ap.errorfill(t_bins,non_responsive_neuron_mean(:,curr_idx),non_responsive_neuron_error(:,curr_idx),[0 0 0],0.1 ,0.5);
            ylim([-0.5 3])

            xlabel('time (s)')
            title(titles{curr_idx})
        end

    end
    sgtitle(groups{curr_group})

    % savefig (gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}]);
    %  saveas(gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}], 'jpg');
end
%

saveas(gcf,[Path 'figures\summary\heatmap and plot of '  neuron_type{curr_type}], 'jpg');



%% draw stim responive firing map
groups={'VA','AV','VA_nA'}
figure('Position',[2000 50 400 800]);
cmap = [ ...
    84 130 53  % #548235
    127 175 174 % #BBCDAE
    192 192 80 % #C0C0C0
    ] / 255;

all_stim=[7 3 8 5 9 10 11]
curr_stim=3

used_stim=all_stim(curr_stim)


clear figures figures1
titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};
max_num=2000
for curr_group=1:2

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])
    used_celltypes=eval('base',['celltypes_'  groups{curr_group}])

    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_1 = vertcat(single_plot_1{:});


    single_plot_2=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h2(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_2 = vertcat(single_plot_2{:});



    % single_plot_trial=cellfun(@(x,y)  x(y),animals_plot_single(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
    %     used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    % single_neuron_trial = vertcat(single_plot_trial{:});
    %
    %
    % single_plot_trial_idx=cellfun(@(x,y)  x(y),animals_plot_idx(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
    %     used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    % single_neuron_trial_idx = vertcat(single_plot_trial_idx{:});
    %
    % nomove_plot=cellfun(@(x,y) cellfun(@(a,b)  permute(nanmean(a1(b1>0.1,:,:),1),[2,3,1])  , ...
    %    x,y,'UniformOutput',false    ),single_neuron_trial,single_neuron_trial_idx,'UniformOutput',false)
    %


    response_each_rec= vertcat(used_filter_idx{:});

    celltypes_each_rec= vertcat(used_celltypes{:});
    celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
    celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
    celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);


    % 不区分group
    single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});
    single_neuron_all_2=cat(1,single_neuron_each_rec_2{:});
    response_all=cat(1,response_each_rec{:});
    celltypes_msn_all=cat(1,celltypes_msn{:});
    celltypes_fsi_all=cat(1,celltypes_fsi{:});
    celltypes_tan_all=cat(1,celltypes_tan{:});

    % response_all=response_all(celltypes_msn_all,:);
    % single_neuron_all_1=single_neuron_all_1(celltypes_msn_all,:,:);
    % single_neuron_all_2=single_neuron_all_2(celltypes_msn_all,:,:);

    % response_all=response_all(celltypes_fsi_all,:);
    %    single_neuron_all_1=single_neuron_all_1(celltypes_fsi_all,:,:);
    %    single_neuron_all_2=single_neuron_all_2(celltypes_fsi_all,:,:);

    %  response_all=response_all(celltypes_tan_all,:);
    % single_neuron_all_1=single_neuron_all_1(celltypes_tan_all,:,:);
    % single_neuron_all_2=single_neuron_all_2(celltypes_tan_all,:,:);



    use_idx= response_all(:,used_stim)> 0.99 ;
    % use_idx= response_all(:,used_stim) == 1 &response_all(:,9) == 0;
    number_neuron=sum(use_idx);
    number_all=length(use_idx);

    clim_value=[0,1];

    [~,max_idx]=max(single_neuron_all_1(: ,psth_use_t_stim,used_stim),[],2);
    [~,sort_idx] = sortrows( max_idx,"ascend");

    used_neruons=single_neuron_all_2(sort_idx,:,:);
    used_neruons_sort=used_neruons(use_idx(sort_idx),:,used_stim);

    % temp_dd=[single_neuron_all_1(: ,psth_use_t,used_stim) response_all(:,used_stim)]


    ax=subplot(5,2,[curr_group,2+curr_group])

    plot_norm = (used_neruons_sort - min(used_neruons_sort, [], 2)) ./ (max(used_neruons_sort, [], 2) - min(used_neruons_sort, [], 2));

    imagesc(t_centers,[],plot_norm)
    % imagesc(t_centers,[],used_neruons_sort)

    colormap(ap.colormap('WK'));
    clim(clim_value);
    xlabel('time (s)')
    xline(0)
    currentAx = gca; % 获取当前轴
    subplotPosition = currentAx.Position; % 获取位置和大小
    maxh=subplotPosition(4);
    maxb=subplotPosition(2);

    subplotPosition(4)=maxh/max_num*size(used_neruons_sort,1);
    subplotPosition(2)=maxb+maxh-maxh/max_num*size(used_neruons_sort,1);
    ax.Position=subplotPosition;
    title(groups{curr_group})

    use_idx_each_rec=cellfun(@(x) x(:,used_stim) == 1 , response_each_rec,'UniformOutput',false );
    % use_idx_each_rec=cellfun(@(x) x(:,used_stim) == 1& x(:,9) == 0 , response_each_rec,'UniformOutput',false );

    selected_neurons_each_rec_msn=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec_1,use_idx_each_rec,celltypes_msn,'UniformOutput',false );
    selected_neurons_each_rec_fsi=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec_1,use_idx_each_rec,celltypes_fsi,'UniformOutput',false );
    selected_neurons_each_rec_tan=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec_1,use_idx_each_rec,celltypes_tan,'UniformOutput',false );
    selected_neurons_each_rec=cellfun( @(x,y)  x(y,:,:), single_neuron_each_rec_1,use_idx_each_rec,'UniformOutput',false );

    % buf_max=max(cat(1,selected_neurons_each_rec_msn{:}),[],2);
    % buf_min=min(cat(1,selected_neurons_each_rec_msn{:}),[],2);
    %     buf_msn=cat(1,selected_neurons_each_rec_msn{:});
    %     used_neruons_only_mean_msn= permute(nanmean( (buf_msn-buf_min)./(buf_min+buf_max) ,1),[2,3,1]) ;

    used_neurons_only_mean=permute(nanmean(cat(1,selected_neurons_each_rec{:}),1),[2 3 1]);
    used_neruons_only_mean_each_rec=cellfun(@(x) permute(mean(x,1),[2 3 1])  ,selected_neurons_each_rec,'UniformOutput',false);
    used_neruons_only_error_each_rec= std(cat(3,used_neruons_only_mean_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));

    used_neruons_only_mean_msn=permute(nanmean(cat(1,selected_neurons_each_rec_msn{:}),1),[2 3 1]);
    used_neruons_only_mean_msn_each_rec=cellfun(@(x) permute(mean(x,1),[2 3 1])  ,selected_neurons_each_rec_msn,'UniformOutput',false);
    used_neruons_only_error_msn_each_rec= std(cat(3,used_neruons_only_mean_msn_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));

    used_neruons_only_mean_fsi=permute(nanmean(cat(1,selected_neurons_each_rec_fsi{:}),1),[2 3 1]);
    used_neruons_only_mean_fsi_each_rec=cellfun(@(x) permute(mean(x,1),[2 3 1])  ,selected_neurons_each_rec_fsi,'UniformOutput',false);
    used_neruons_only_error_fsi_each_rec= std(cat(3,used_neruons_only_mean_fsi_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));

    used_neruons_only_mean_tan=permute(nanmean(cat(1,selected_neurons_each_rec_tan{:}),1),[2 3 1]);
    used_neruons_only_mean_tan_each_rec=cellfun(@(x) permute(mean(x,1),[2 3 1])  ,selected_neurons_each_rec_tan,'UniformOutput',false);
    used_neruons_only_error_tan_each_rec= std(cat(3,used_neruons_only_mean_tan_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));



    names=  ['a' num2str(curr_group)];
    figures.(names)=subplot(5,2,curr_group+4)
    types_numbers=[size(cat(1,selected_neurons_each_rec_msn{:}),1),size(cat(1,selected_neurons_each_rec_fsi{:}),1)...
        size(cat(1,selected_neurons_each_rec_tan{:}),1)];
    pie(types_numbers)
    % set(figures.(names), 'Colormap', cmap); % 红、绿、蓝
    legend({'MSN','FSI','TAN'}, 'Location', 'northoutside', 'Orientation', 'vertical','Box','off');

    subplot(5,2,curr_group+6)
    % ap.errorfill(t_bins,used_neurons_only_mean(:,used_stim),used_neruons_only_error_each_rec(:,used_stim),[1 0 0],0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_msn(:,used_stim),used_neruons_only_error_msn_each_rec(:,used_stim),cmap(1,:),0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_fsi(:,used_stim),used_neruons_only_error_fsi_each_rec(:,used_stim),cmap(2,:),0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_tan(:,used_stim),used_neruons_only_error_tan_each_rec(:,used_stim),cmap(3,:),0.1 ,0.5);

    ylim([-0.5 5])
    xlabel('time (s)')
    ylabel('\Delta FR/FR_0')

    [peak_value,peak_position]= max(used_neruons_sort(:,t_bins>0&t_bins<0.3),[],2);
    cut_t=t_bins(t_bins>0&t_bins<0.3);
    subplot(5,2,curr_group+8)
    % scatter(cut_t(peak_position),peak_value,'Marker','.')
    histogram(cut_t(peak_position))
    % ylim([0 50])

    xlim([0 0.3])
end
sgtitle(titles{used_stim})
set(figures.a1, 'Colormap', cmap); % 红、绿、蓝
set(figures.a2, 'Colormap', cmap); % 红、绿、蓝

% saveas(gcf,[Path 'figures\Figure\ephys pesth of single neurons in passive '  titles{used_stim} groups{curr_group} ], 'jpg');
%%
titles={'L','M','R','4k','8k','12k','R task','8k task','R task move','8k task move','move'};

groups={'VA','AV','VA_nA'}
figure('Position',[50 50 1600 900])
tt= tiledlayout(4,6); % 创建一个1行2列的布局

for curr_group=1:2
    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])
    used_celltypes=eval('base',['celltypes_'  groups{curr_group}])


    single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_1 = vertcat(single_plot_1{:});
    single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});

    response_each_rec= vertcat(used_filter_idx{:});
    response_all=cat(1,response_each_rec{:});



    celltypes_each_rec= vertcat(used_celltypes{:});
    celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
    celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
    celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);

    celltypes_msn_all=cat(1,celltypes_msn{:});
    celltypes_fsi_all=cat(1,celltypes_fsi{:});
    celltypes_tan_all=cat(1,celltypes_tan{:});


    % response_all_type=response_all(celltypes_msn_all & response_all(:,7)> 0.99,:);
    % single_neuron_all_1_type=single_neuron_all_1(celltypes_msn_all & response_all(:,7)> 0.99,:,:);

    % response_all_type=response_all(celltypes_fsi_all & response_all(:,7)> 0.99,:);
    % single_neuron_all_1_type=single_neuron_all_1(celltypes_fsi_all & response_all(:,7)> 0.99,:,:);

    condition1=response_all(:,5)>0.9;
    % condition2=permute(max(single_neuron_all_1(:,psth_use_t,10),[],2),[1 3 2])<permute(max(single_neuron_all_1(:,psth_use_t,8),[],2),[1 3 2]);


    response_all_type=response_all(celltypes_tan_all & response_all(:,7)> 0.99 & condition1,:);
    single_neuron_all_1_type=single_neuron_all_1(celltypes_tan_all & response_all(:,7)> 0.99& condition1,:,:);

    [~,max_idx]=max(single_neuron_all_1_type(: ,psth_use_t_stim,7),[],2);
    [~,sort_idx] = sortrows( max_idx,"ascend");

    used_neruons=single_neuron_all_1_type(sort_idx,:,:);
    used_idx=response_all_type(sort_idx,:)
    % used_neruons_sort=used_neruons(use_idx(sort_idx),:,8);
    clim_value=[-3,3];

    for curr_stim=[7 9 3 8 10 5]
        nexttile
        % figure
        imagesc(t_bins,[],used_neruons(:,:,curr_stim))

        colormap(ap.colormap('PWG'));
        clim(clim_value);
        xlabel('time (s)')
        xline(0)
        xlim([-0.2 0.4])
        hold on
        idxx=used_idx(:,curr_stim)>0.99
        plot(-0.1*ones(sum(response_all_type(:,curr_stim)>0.99),1),find(idxx),'.r','LineWidth',0.5)

        title(titles{curr_stim})
    end
    for curr_stim=[7 9 3 8 10 5]
        nexttile
        ap.errorfill(t_bins,nanmean(used_neruons(:,:,curr_stim),1),std(used_neruons(:,:,curr_stim),0,1,'omitmissing')/sqrt(size(used_neruons(:,:,curr_stim),1)),[1 0 0],0.5,0.1)
        % plot(t_bins,nanmean(used_neruons(use_idx(sort_idx),:,curr_stim),1))
        % colormap(ap.colormap('WK'));
        ylim([-0.5 3]);
        xlabel('time (s)')
        xline(0)
        xlim([-0.2 0.4])
    end

end

% saveas(gcf,[Path 'figures\Figure\V responsive neurons'   ], 'jpg');

%%

group_name={'VA','AV'};
neuron_type={'tan','fsi','msn','all'}

counts_proportion_new=cell(2,1);
counts_new=cell(2,1);
plot_new=cell(2,1);
for curr_group=1:2

    switch curr_group
        case 1
            used_idx=eval('anterior_learned_idx_VA');

        case 2
            used_idx=eval('anterior_learned_idx_AV');
    end

    for curr_type=1:4
        switch curr_type
            case 4
                filter_neuron=cellfun(@(x,y)  x(y),animals_all_event_response(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
                    used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
                responsive_neuron=vertcat(filter_neuron{:});

                neurons_type_activity=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
                    used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
                responsive_neuron_plot=vertcat(neurons_type_activity{:});


            case {1,2,3}
                no_empty_idx=~cellfun(@isempty, used_idx','UniformOutput',true);

                strcut_idx=cellfun(@(x) cellfun(@(y) strcmp('struct', class(y))  ,x,'UniformOutput',true) ,animals_all_celltypes,'UniformOutput',false) ;
                neurons_type=cellfun(@(x,y,z,h) cellfun(@(s,q) q(find(s.(neuron_type{curr_type})==1),:) ,...
                    x(intersect(find(z),h)),y(intersect(find(z),h)),'UniformOutput',false) ,...
                    animals_all_celltypes(no_empty_idx),animals_all_event_response(no_empty_idx),strcut_idx(no_empty_idx),...
                    used_idx(no_empty_idx)','UniformOutput',false)  ;


                % neurons_type=cellfun(@(x,y,z,h) cellfun(@(s,q) q(find(s.(neuron_type{curr_type})==1&sum(q(:,[3 5 7 8]), 2) > 0),:) ,...
                %  x(intersect(find(z),h)),y(intersect(find(z),h)),'UniformOutput',false) ,...
                %  animals_all_celltypes(no_empty_idx),animals_all_event_response(no_empty_idx),strcut_idx(no_empty_idx),...
                %  used_idx(no_empty_idx)','UniformOutput',false)  ;

                responsive_neuron=vertcat(neurons_type{:});

                neurons_type_activity=cellfun(@(cell_type,response,id0,idx,cell_plot) cellfun(@(type1,plot1) plot1(find(type1.(neuron_type{curr_type})==1),:,:) ,...
                    cell_type(intersect(find(id0),idx)),...
                    cell_plot(intersect(find(id0),idx)),'UniformOutput',false) ,...
                    animals_all_celltypes(no_empty_idx),animals_all_event_response(no_empty_idx),strcut_idx(no_empty_idx),...
                    used_idx(no_empty_idx)',animals_all_event_single_plot(no_empty_idx),'UniformOutput',false)  ;
                responsive_neuron_plot=vertcat(neurons_type_activity{:});
        end

        responsive_neuron_1=vertcat(responsive_neuron{:});
        responsive_neuron_plot_1=vertcat(responsive_neuron_plot{:});

        % sum(arrayfun(@(x) isequal(responsive_VA_1(x,1:6),[1 0 0 0 0 0] ),1:size(responsive_VA_1,1),'UniformOutput',true))
        onlyl     = sum( responsive_neuron_1(:,1) & ~responsive_neuron_1(:,2) & ~responsive_neuron_1(:,3) );
        onlym     = sum(~responsive_neuron_1(:,1) &  responsive_neuron_1(:,2) & ~responsive_neuron_1(:,3) );
        onlyr     = sum(~responsive_neuron_1(:,1) & ~responsive_neuron_1(:,2) &  responsive_neuron_1(:,3));
        lm        = sum( responsive_neuron_1(:,1) &  responsive_neuron_1(:,2) & ~responsive_neuron_1(:,3) );
        lr        = sum( responsive_neuron_1(:,1) & ~responsive_neuron_1(:,2) &  responsive_neuron_1(:,3) );
        mr        = sum(~responsive_neuron_1(:,1) &  responsive_neuron_1(:,2) &  responsive_neuron_1(:,3) );
        lmr       = sum( responsive_neuron_1(:,1) &  responsive_neuron_1(:,2) &  responsive_neuron_1(:,3) );


        only4k     = sum( responsive_neuron_1(:,4) & ~responsive_neuron_1(:,5) & ~responsive_neuron_1(:,6) );
        only8k     = sum(~responsive_neuron_1(:,4) &  responsive_neuron_1(:,5) & ~responsive_neuron_1(:,6) );
        only12k     = sum(~responsive_neuron_1(:,4) & ~responsive_neuron_1(:,5) &  responsive_neuron_1(:,6));
        k4k8        = sum( responsive_neuron_1(:,4) &  responsive_neuron_1(:,5) & ~responsive_neuron_1(:,6) );
        k4k12       = sum( responsive_neuron_1(:,4) & ~responsive_neuron_1(:,5) &  responsive_neuron_1(:,6) );
        k8k12      = sum(~responsive_neuron_1(:,4) &  responsive_neuron_1(:,5) &  responsive_neuron_1(:,6) );
        k4k8k12      = sum( responsive_neuron_1(:,4) &  responsive_neuron_1(:,5) &  responsive_neuron_1(:,6) );

        %
        olnyr_r_8k= sum( responsive_neuron_1(:,3)&~ responsive_neuron_1(:,5));
        olny8k_r_8k= sum( ~responsive_neuron_1(:,3)& responsive_neuron_1(:,5));
        r_k8=sum(responsive_neuron_1(:,3)&  responsive_neuron_1(:,5) );

        olnyr_r_v= sum( responsive_neuron_1(:,3)&~ responsive_neuron_1(:,7));
        olnyv_r_v= sum( ~responsive_neuron_1(:,3)& responsive_neuron_1(:,7));
        r_v=sum(responsive_neuron_1(:,3)&  responsive_neuron_1(:,7) );

        olny8K_8k_a= sum( responsive_neuron_1(:,5)&~ responsive_neuron_1(:,8));
        olnya_8k_a= sum( ~responsive_neuron_1(:,5)& responsive_neuron_1(:,8));
        k8_a=sum(responsive_neuron_1(:,5)&  responsive_neuron_1(:,8) );

        olnyv_v_a= sum( responsive_neuron_1(:,7)& ~responsive_neuron_1(:,8));
        olnya_v_a= sum( ~responsive_neuron_1(:,7)& responsive_neuron_1(:,8));
        v_a= sum( responsive_neuron_1(:,7)& responsive_neuron_1(:,8));


        V_all=sum(responsive_neuron_1(:,7)|responsive_neuron_1(:,3));
        V_task_all=sum(responsive_neuron_1(:,7)&~responsive_neuron_1(:,3));
        V_passive_all=sum(responsive_neuron_1(:,3)&~responsive_neuron_1(:,7));
        V_task_passive=sum(responsive_neuron_1(:,7) & responsive_neuron_1(:,3));
        V_only= sum(~responsive_neuron_1(:,8) & ~responsive_neuron_1(:,5) & ...
            (responsive_neuron_1(:,7) | responsive_neuron_1(:,3)));

        A_all=sum(responsive_neuron_1(:,8)|responsive_neuron_1(:,2));
        A_task_all=sum(responsive_neuron_1(:,8)&~responsive_neuron_1(:,5));
        A_passive_all=sum(responsive_neuron_1(:,5)&~responsive_neuron_1(:,8));
        A_task_passive=sum(responsive_neuron_1(:,8) & responsive_neuron_1(:,5));
        A_only=sum(~responsive_neuron_1(:,7) & ~responsive_neuron_1(:,3) & ...
            (responsive_neuron_1(:,8) | responsive_neuron_1(:,5)));

        V_A=sum((responsive_neuron_1(:,7)|responsive_neuron_1(:,3))&  ...
            (responsive_neuron_1(:,8)|responsive_neuron_1(:,2)) );
        V_A_task=sum(responsive_neuron_1(:,8) &  ...
            responsive_neuron_1(:,7) );
        V_A_passive=sum(responsive_neuron_1(:,5) &  ...
            responsive_neuron_1(:,3) );
        V_A_task_passive=sum(responsive_neuron_1(:,8) & responsive_neuron_1(:,5) & ...
            responsive_neuron_1(:,7) & responsive_neuron_1(:,3));

        sum(responsive_neuron_1(:,7)|responsive_neuron_1(:,3))


        plot_V_all=responsive_neuron_plot_1(responsive_neuron_1(:,7)|responsive_neuron_1(:,3),:,:);
        plot_V_task_all=responsive_neuron_plot_1(responsive_neuron_1(:,7)&~responsive_neuron_1(:,3),:,:);
        plot_V_passive_all=responsive_neuron_plot_1(responsive_neuron_1(:,3)&~responsive_neuron_1(:,7),:,:);
        plot_V_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,7) & responsive_neuron_1(:,3),:,:);
        plot_V_only= responsive_neuron_plot_1(~responsive_neuron_1(:,8) & ~responsive_neuron_1(:,5) & ...
            (responsive_neuron_1(:,7) | responsive_neuron_1(:,3)),:,:);

        plot_A_all=responsive_neuron_plot_1(responsive_neuron_1(:,8)|responsive_neuron_1(:,2),:,:);
        plot_A_task_all=responsive_neuron_plot_1(responsive_neuron_1(:,8)&~responsive_neuron_1(:,5),:,:);
        plot_A_passive_all=responsive_neuron_plot_1(responsive_neuron_1(:,5)&~responsive_neuron_1(:,8),:,:);
        plot_A_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,8) & responsive_neuron_1(:,5),:,:);
        plot_A_only=responsive_neuron_plot_1(~responsive_neuron_1(:,7) & ~responsive_neuron_1(:,3) & ...
            (responsive_neuron_1(:,8) | responsive_neuron_1(:,5)),:,:);

        plot_V_A=responsive_neuron_plot_1((responsive_neuron_1(:,7)|responsive_neuron_1(:,3))&  ...
            (responsive_neuron_1(:,8)|responsive_neuron_1(:,2)),:,:);
        plot_V_A_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,8) & responsive_neuron_1(:,5) & ...
            responsive_neuron_1(:,7) & responsive_neuron_1(:,3),:,:);
        plot_V_A_task=responsive_neuron_plot_1(responsive_neuron_1(:,8) & ...
            responsive_neuron_1(:,7),:,:);
        plot_V_A_passive=responsive_neuron_plot_1(responsive_neuron_1(:,3) & ...
            responsive_neuron_1(:,5),:,:);



        plot_new{curr_group}{curr_type}=...
            {plot_V_all,plot_V_task_all,plot_V_passive_all,plot_V_task_passive,plot_V_only,...
            plot_A_all,plot_A_task_all,plot_A_passive_all,plot_A_task_passive ,plot_A_only,...
            plot_V_A,plot_V_A_task,plot_V_A_passive,plot_V_A_task_passive };

        counts_proportion_new{curr_group}{curr_type}=...
            [V_all,V_task_all,V_passive_all,V_task_passive, V_only,...
            A_all, A_task_all,A_passive_all,A_task_passive,A_only,...
            V_A,V_A_task,V_A_passive,V_A_task_passive]./size(responsive_neuron_1,1);

        counts_new{curr_group}{curr_type}=...
            [V_all,V_task_all,V_passive_all,V_task_passive, V_only,...
            A_all, A_task_all,A_passive_all,A_task_passive,A_only,...
            V_A,V_A_task,V_A_passive,V_A_task_passive];


    end
end


%% proportion of responsive neurons in different types
figure('Position',[50 50 900 300]);
t = tiledlayout(1, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
neuron_type={'TANs','FSIs','MSNs','All'}

for curr_type=[4 1 2 3]
    nexttile
    hBar=bar([counts_proportion_new{1}{curr_type};counts_proportion_new{2}{curr_type}]','group')
    box off
    % 设置每组的颜色
    % #548235
    % #7030A0
    colors1=[84 130 53; 112  48 160]./255;
    for i = 1:length(hBar)
        hBar(i).FaceColor = colors1(i, :);
        hBar(i).EdgeColor = 'none';       % 无边框线

    end
    xline(5.5,'LineStyle',':')
    xline(10.5,'LineStyle',':')

    % 设置 x 轴标签
    labels={'V all', 'V task',  'V passive', 'V task&passive','V only',...
        'A all','A task', 'A passive', 'A task&passive','A only', ...
        'V&A','V&A task','V&A passive','V&A task&passive'};
    set(gca, 'XTick', 1:14, 'XTickLabel',labels );
    ylim([0 1])
    ylabel('proportion')
    title(neuron_type{curr_type})
end
% saveas(gcf,[Path 'figures\Figure\ephys proportion of responsive neurons '   ], 'jpg');


%% plot of firng rate
neuron_type={'TANs','FSIs','MSNs','All'}

plot_mean=cellfun(@(x) cellfun(@(y) cellfun(@(q) permute( nanmean(q(:,:,[3,7,5,8]),1),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);

plot_error=cellfun(@(x) cellfun(@(y) cellfun(@(q) permute( std(q(:,:,[3,7,5,8]),0,1,'omitmissing')/sqrt(size(q,1)),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);




plot_peak_mean=cellfun(@(x) cellfun(@(y) cellfun(@(q) ...
    permute( mean(max(q(:,(t_bins>0.1&t_bins<0.2),[3,7,5,8]),[],2),1),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);

plot_peak_error=cellfun(@(x) cellfun(@(y) cellfun(@(q) ...
    permute( std(max(q(:,(t_bins>0.1&t_bins<0.2),[3,7,5,8]),[],2),0,1,'omitmissing')/sqrt(size(q,1)),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);

colors={[0.5, 0.5,1],[0,0,1],[1,0.5,0.5],[1,0,0]}
for curr_type=1:3
    figure('Position',[50 50 1600 500]);

    t = tiledlayout(2, 14, 'TileSpacing', 'loose', 'Padding', 'loose');

    for curr_group=1:2
        for curr_event=1:14
            nexttile
            arrayfun(@(n) ap.errorfill(t_bins,plot_mean{curr_group}{curr_type}{curr_event}(:,n),...
                plot_error{curr_group}{curr_type}{curr_event}(:,n),colors{n},0.5,0.1),1:4);
            xlim([-0.2 0.5])
            ylim([-1 8])
            title(labels{curr_event})

        end
    end
    sgtitle(neuron_type{curr_type})
    saveas(gcf,[Path 'figures\Figure\ephys plot of responsive neurons in ' neuron_type{curr_type}  ], 'jpg');
end



%%
colors={[84 130 53]./255,[112  48 160]./255};
figure('Position',[50 50 1600 500]);
tt = tiledlayout(3, 1, 'TileSpacing', 'loose', 'Padding', 'loose');
for curr_type=1:3

    t_type = tiledlayout(tt,1,14);
    t_type.Layout.Tile = curr_type;
    title(t_type,neuron_type{curr_type});


    for curr_event=1:14
        nexttile(t_type)

        for curr_group=1:2

            hold on
            errorbar(1:4,plot_peak_mean{curr_group}{curr_type}{curr_event}, ...
                plot_peak_error{curr_group}{curr_type}{curr_event},'Color',colors{curr_group},'LineWidth',2,'Marker','.','MarkerSize',20,'LineStyle','none')

            xticks([1:4])
            xticklabels({'v passive','v task','a passive','a task'})
            xlim([0.5 4.5])
            ylim([0 10])
            ylabel('peak \Delta FR/FR_0')
            title(labels{curr_event},'FontWeight','normal')
        end
    end
    % sgtitle(neuron_type{curr_type})
    % saveas(gcf,[Path 'figures\Figure\ephys plot of responsive neurons in ' neuron_type{curr_type}  ], 'jpg');
end


%% proportion
colors={[84 130 53]./255,[112  48 160]./255};

neuron_type={'TANs','FSIs','MSNs','All'}

idx={[5 10 11],[2 3 4],[7 8 9]}
curr_idx=3
for curr_type=1:3
    figure('Position',[50 50 500 800]);
    t = tiledlayout(4, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    dataAll=[counts_new{1}{curr_type}(idx{curr_idx}(1)), ...
        counts_new{1}{curr_type}(idx{curr_idx}(2)), ...
        counts_new{1}{curr_type}(idx{curr_idx}(3));...
        counts_new{2}{curr_type}(idx{curr_idx}(1)), ...
        counts_new{2}{curr_type}(idx{curr_idx}(2)), ...
        counts_new{2}{curr_type}(idx{curr_idx}(3))];
    scaleFactor = 1 / sqrt(max(dataAll, [], 'all') / pi);
    nexttile
    ds.venn2_scaled(dataAll(1,1),dataAll(1,2),dataAll(1,3), [0.5 0.5 1], [1 0.5 0.5], 0.5, 0.5, 1, 0,...
        labels(idx{curr_idx}),scaleFactor);   % 显示绝对值
    title('VA','FontWeight','normal')
    nexttile
    ds.venn2_scaled(dataAll(2,1),dataAll(2,2),dataAll(2,3), [0.5 0.5 1], [1 0.5 0.5], 0.5, 0.5, 1, 0,...
        labels(idx{curr_idx}),scaleFactor);   % 显示绝对值
    title('AV','FontWeight','normal')




    for curr_event=idx{curr_idx}
        nexttile
        for curr_group=1:2

            hold on
            errorbar(1:4,plot_peak_mean{curr_group}{curr_type}{curr_event}, ...
                plot_peak_error{curr_group}{curr_type}{curr_event},'Color',colors{curr_group})

        end
        xticks([1:4])
        xticklabels({'v passive','v task','a passive','a task'})
        xlim([0.5 4.5])
        ylim([0 3])
        ylabel('peak \Delta FR/FR_0')
        title(labels{curr_event},'FontWeight','normal')
    end
    sgtitle(neuron_type{curr_type})
    % saveas(gcf,[Path 'figures\Figure\ephys plot of responsive neurons in ' neuron_type{curr_type} '_' num2str(curr_idx) ], 'jpg');
end



%% Load atlas  3-D
groups={'VA','AV','VA_nA'}
curr_group=2
used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);


allen_atlas_path = fileparts(which('template_volume_10um.npy'));
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']); % the number at each pixel labels the area, see note below

% Set up axes, plot brain outline
% figure('Color','w','name',animal);
figure('Color','w','Name',groups{curr_group});

% Set up 3D axes
ccf_3d_axes = axes;
set(ccf_3d_axes,'ZDir','reverse');
hold(ccf_3d_axes,'on');
axis(ccf_3d_axes,'vis3d','equal','off','manual');
view([-30,25]);
axis tight;
h = rotate3d(ccf_3d_axes);
h.Enable = 'on';

slice_spacing = 5;
brain_volume = ...
    bwmorph3(bwmorph3(av(1:slice_spacing:end, ...
    1:slice_spacing:end,1:slice_spacing:end)>1,'majority'),'majority');
brain_outline_patchdata = isosurface(permute(brain_volume,[3,1,2]),0.5);
brain_outline = patch( ...
    'Vertices',brain_outline_patchdata.vertices*slice_spacing, ...
    'Faces',brain_outline_patchdata.faces, ...
    'FaceColor',[0.7,0.7,0.7],'EdgeColor','none','FaceAlpha',0.1);

for curr_animal=1:length(animals)


    for curr_probe=used_idx{curr_animal}
        preload_vars = who;

        if isempty(curr_probe)
            continue
        end
        cells_position{curr_probe} = animals_probe_positions{curr_animal}{curr_probe}(:,1)' + animals_all_cell_deepth_sorted{curr_animal}{curr_probe}/3840 * (animals_probe_positions{curr_animal}{curr_probe}(:,2) - animals_probe_positions{curr_animal}{curr_probe}(:,1))';




        % 每行对应一种颜色
        responsive_neurons=...
            animals_all_event_response{curr_animal}{curr_probe}(:,3)|...
            animals_all_event_response{curr_animal}{curr_probe}(:,5);

        % 计算 jitter（偏移量）
        jitter_amount = 20; % 根据需要调整偏移大小
        x_jitter = cells_position{curr_probe}(responsive_neurons,1) + jitter_amount * (rand(size(cells_position{curr_probe}(responsive_neurons,1))) - 0.5);
        y_jitter = cells_position{curr_probe}(responsive_neurons,3) + jitter_amount * (rand(size(cells_position{curr_probe}(responsive_neurons,3))) - 0.5);

        colorMap =[1,0,0].*(animals_all_event_response{curr_animal}{curr_probe}(responsive_neurons,3))+...
            [0,0,1].*(animals_all_event_response{curr_animal}{curr_probe}(responsive_neurons,5));

        s= scatter3(x_jitter,y_jitter,...
            cells_position{curr_probe}(responsive_neurons,2),10,colorMap,'filled')

        % plot3(animals_probe_positions{curr_animal}{curr_probe}(1,:),...
        %     animals_probe_positions{curr_animal}{curr_probe}(3,:),animals_probe_positions{curr_animal}{curr_probe}(2,:))
        % hold on

        clearvars('-except',preload_vars{:});

    end

end


%% 冠状平面
p_val=0.95
colors11={'G','P'}
% Load atlas


allen_atlas_path = fileparts(which('template_volume_10um.npy'));
obj.av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy'));
obj.st = loadStructureTree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));

structure_name='caudoputamen';

plot_structure = find(strcmpi(obj.st.safe_name,structure_name));
plot_structure_id = obj.st.structure_id_path{plot_structure};
plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
    obj.st.structure_id_path));

% Get structure color and volume
slice_spacing = 5;
structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_structure},2,[])')./255;
plot_ccf_volume = ismember(obj.av(1:slice_spacing:end,1:slice_spacing:end,1:slice_spacing:end),plot_ccf_idx);

curr_outline = bwboundaries(squeeze((max(plot_ccf_volume,[],1))));

outline=curr_outline{1};

groups={'VA','AV','VA_nA'}

fig1 = figure;
tl1 = tiledlayout(2,2);  % 2 行 3 列
title(tl1, 'proportion of responsive neurons');

fig2 = figure;
tl2 = tiledlayout(2,2);
title(tl2, 'firing rates');

for curr_group=1:2

    for used_stim=[3 5]

        used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);
        used_filter_idx=eval('base',['filtered_'  groups{curr_group}]);
        used_celltypes=eval('base',['celltypes_'  groups{curr_group}]);

        single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
            used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
        single_neuron_each_rec_1 = vertcat(single_plot_1{:});
        single_neuron_all_1=cat(1,single_neuron_each_rec_1{:});

        single_neuron_position=cellfun(@(x,y)  x(y),animals_all_cell_ccf_position_sorted(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
            used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
        single_probe_position=cellfun(@(x,y)  x(y),animals_probe_positions(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
            used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
        % single_neuron_position=cellfun(@(x,y)  cellfun(@(a,b) b(:,1)' + a/3840 * (b(:,2) - b(:,1))'  ,x,y,'Unif',false),...
        %     single_neuron_position,single_probe_position,'UniformOutput',false   )

        single_neuron_each_position = vertcat(single_neuron_position{:});
        single_neuron_position_all=cat(1,single_neuron_each_position{:});


        response_each_rec= vertcat(used_filter_idx{:});
        response_all=cat(1,response_each_rec{:});


        celltypes_each_rec= vertcat(used_celltypes{:});
        celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
        celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
        celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);

        celltypes_msn_all=cat(1,celltypes_msn{:});
        celltypes_fsi_all=cat(1,celltypes_fsi{:});
        celltypes_tan_all=cat(1,celltypes_tan{:});





        % === 用户输入 ===

        jitter_amount = 5; % 根据需要调整偏移大小
        z_jitter = single_neuron_position_all(:,3) + jitter_amount * (rand(size(single_neuron_position_all,1),1) - 0.5);
        single_neuron_position_all(:,3)=z_jitter;

        neuron_coords_all= single_neuron_position_all;

        neuron_coords= single_neuron_position_all(response_all(:,used_stim)>p_val,:);
        firing_rates=single_neuron_all_1(response_all(:,used_stim)>p_val,:,used_stim);

        % neuron_coords= single_neuron_position_all(response_all(:,3)&response_all(:,5),:);
        % firing_rates=single_neuron_all(response_all(:,3)&response_all(:,5),:,used_stim);

        bin_size_y = 10; % 单位：μm，根据实际尺度调整
        bin_size_z = 10; % 单位：μm，根据实际尺度调整

        % 假设你已加载 neuron_coords (N x 3) 和 firing_rates (N x T)
        % 例如：load('neuron_data.mat'); 包含 neuron_coords 和 firing_rates

        % === Step 1: 投影到冠状面（y-z） ===
        projected_coords = neuron_coords(:, 2:3); % 取 y 和 z
        projected_coords_all = neuron_coords_all(:, 2:3); % 取 y 和 z

        % === Step 2: 创建 bin 网格 ===
        y_min = min(projected_coords_all(:,2))-10;
        y_max = max(projected_coords_all(:,2))+10;
        z_min = min(projected_coords_all(:,1))-10;
        z_max = max(projected_coords_all(:,1))+10;

        y_edges = y_min:bin_size_y:y_max;
        z_edges = z_min:bin_size_z:z_max;

        % 分配每个神经元的 bin 索引
        [~, y_bin_all] = histc(projected_coords_all(:,2), y_edges);
        [~, z_bin_all] = histc(projected_coords_all(:,1), z_edges);

        [~, y_bin] = histc(projected_coords(:,2), y_edges);
        [~, z_bin] = histc(projected_coords(:,1), z_edges);



        %
        % % 过滤边界外的点
        % valid_idx = y_bin > 0 & z_bin > 0;
        % y_bin = y_bin(valid_idx);
        % z_bin = z_bin(valid_idx);
        % firing_rates = firing_rates(valid_idx, :);

        % 更新神经元数
        n_y_bins = length(y_edges) - 1;
        n_z_bins = length(z_edges) - 1;

        % === Step 3: 计算每个 bin 中的神经元数量 ===
        neuron_count_map_all = zeros(n_y_bins, n_z_bins);
        neuron_count_map = zeros(n_y_bins, n_z_bins);

        for i = 1:length(y_bin_all)
            neuron_count_map_all(y_bin_all(i), z_bin_all(i)) = neuron_count_map_all(y_bin_all(i), z_bin_all(i)) + 1;
        end
        for i = 1:length(y_bin)
            neuron_count_map(y_bin(i), z_bin(i)) = neuron_count_map(y_bin(i), z_bin(i)) + 1;
        end




        % 可视化神经元数量热图
        % map1=neuron_count_map;
        map1=(neuron_count_map./neuron_count_map_all)';
        figure(fig1)
        ax1=nexttile(tl1)

        hold(ax1, 'on');
        set(ax1,'YDir','reverse');
        axis(ax1,'equal','off');

        % --- Plot outline (scaled back) ---
        plot(ax1, outline(:,2)*slice_spacing, outline(:,1)*slice_spacing, ...
            'Color', structure_color, 'LineWidth', 2);
        smoothed = smoothdata(map1, 1, 'gaussian', 4);   % 先沿行方向平滑
        smoothed = smoothdata(smoothed, 2, 'gaussian', 4);  % 再沿列方向平滑
        h = imagesc(ax1,y_edges(1:end-1), z_edges(1:end-1),smoothed );  % 热图（注意转置）
        set(h, 'AlphaData', ~isnan(map1) * 1);  % 设置透明度（非 NaN 区域可见）
        % set(h, 'AlphaData', ~(map1==0) * 1);  % 设置透明度（非 NaN 区域可见）
        if curr_group==1
            title(titles(used_stim))
        end
        clim([0 0.5])
        colormap(ax1, ap.colormap(['W' colors11{curr_group}]));  % 设置热图 colormap
        % colorbar;
        xlabel('Y (μm)'); ylabel('Z (μm)');
        axis image;

        %

        % === Step 4: 构建三维时间-空间平均放电频率图 ===
        T = size(firing_rates, 2); % 时间点数

        mean_firing_map = nan(n_z_bins, n_y_bins, T);
        count_map = zeros(n_z_bins, n_y_bins);

        for i = 1:length(y_bin)
            y = y_bin(i);
            z = z_bin(i);
            if isnan(mean_firing_map(z, y, 1))
                mean_firing_map(z, y, :) = 0;
            end
            mean_firing_map(z, y, :) = mean_firing_map(z, y, :) + reshape(firing_rates(i, :), [1 1 T]);
            count_map(z, y) = count_map(z, y) + 1;
        end

        % 求平均放电率
        for y = 1:n_y_bins
            for z = 1:n_z_bins
                if count_map(z, y) > 0
                    mean_firing_map(z, y, :) = mean_firing_map(z, y, :) / count_map(z, y);
                else
                    mean_firing_map(z, y, :) = nan;
                end
            end
        end

        ap.imscroll(mean_firing_map(:,:,t_bins>0&t_bins<0.3),t_bins(t_bins>0&t_bins<0.3))
        clim([0 20])
        axis equal
        set(gcf, 'Name', [groups{curr_group} '-' titles{used_stim}], 'NumberTitle', 'off');





        figure(fig2)

        ax2=nexttile(tl2)

        hold(ax2, 'on');
        set(ax2,'YDir','reverse');
        axis(ax2,'equal','off');

        % --- Plot outline (scaled back) ---
        plot(ax2, outline(:,2)*slice_spacing, outline(:,1)*slice_spacing, ...
            'Color', structure_color, 'LineWidth', 2);

        max_map=max(mean_firing_map(:,:,t_bins>0&t_bins<0.2),[],3);
        % figure('Position',[50 200 200 800])
        h2=imagesc(ax2,y_edges(1:end-1), z_edges(1:end-1),max_map)
        set(h2, 'AlphaData', ~isnan(max_map) * 1);  % 设置透明度（非 NaN 区域可见）
        if curr_group==1
            title(titles(used_stim))
        end
        clim([0 10])
        colormap(ax2,ap.colormap(['W' colors11{curr_group}]))
        axis image;

    end
end


% saveas(fig1,[Path 'figures\Figure\numbers of responsive neurons ' ], 'jpg');
% saveas(fig2,[Path 'figures\Figure\FR of responsive neurons ' ], 'jpg');



%% 一维深度  group average
groups={'VA','AV','VA_nA'}
titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};
p_val=0.99
all_stim=[3 5 7 8];
colors={[84 130 53]./255,[112  48 160]./255};
colors1=parula(3)



z_min = 250;
z_max = 600;
bin_size_z = 20; % 单位：μm，根据实际尺度调整
z_edges = z_min:bin_size_z:z_max;
z_edge_3=[250 350 450 600]


fig2 = figure('Position',[50 50 length(all_stim)*200 800]);
tl2 = tiledlayout(6,length(all_stim));
title(tl2, 'firing rates');

% fig5 = figure('Position',[50 50 length(all_stim)*100 200]);
% tl5 = tiledlayout(1,length(all_stim));  % 2 行 3 列
% title(tl5, 'proportion based on numbers');
% colors=[84 130 53; 112  48 160]./255;

for curr_group=1

    for curr_stim=1:length(all_stim)

        used_stim=all_stim(curr_stim);

        used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);
        used_filter_idx=eval('base',['filtered_'  groups{curr_group}]);
        used_celltypes=eval('base',['celltypes_'  groups{curr_group}]);

        single_plot_1=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
            used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
        single_neuron_each_rec_1 = vertcat(single_plot_1{:});
        single_neuron_all_plot=cat(1,single_neuron_each_rec_1{:});


        single_neuron_position=cellfun(@(x,y)  x(y),animals_all_cell_ccf_position_sorted(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
            used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
        single_neuron_each_position = vertcat(single_neuron_position{:});
        single_neuron_position_all=cat(1,single_neuron_each_position{:});


        response_each_rec= vertcat(used_filter_idx{:});
        response_all=cat(1,response_each_rec{:});


        % celltypes_each_rec= vertcat(used_celltypes{:});
        % celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
        % celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
        % celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);
        %
        % celltypes_msn_all=cat(1,celltypes_msn{:});
        % celltypes_fsi_all=cat(1,celltypes_fsi{:});
        % celltypes_tan_all=cat(1,celltypes_tan{:});



        neuron_coords_all= cellfun(@(x)   x(:,2) ,single_neuron_each_position,'UniformOutput',false );
        neuron_coords= cellfun(@(x,y) x(y(:,used_stim)>p_val,2),single_neuron_each_position,response_each_rec,'UniformOutput',false)


        firing_rates=cellfun(@(x) x(:,:,used_stim) ,single_neuron_each_rec_1,'UniformOutput',false);



        % === Step 1: 投影到冠状面（y-z） ===
        projected_coords = neuron_coords; % 取 y 和 z
        projected_coords_all = neuron_coords_all; % 取 y 和 z


        % 分配每个神经元的 bin 索引
        [neuron_count_map_all,~,binIdx_all] = cellfun(@(x) histcounts(x, z_edges),projected_coords_all,'UniformOutput',false);

        [neuron_count_map,~,binIdx]= cellfun(@(x) histcounts(x, z_edges),projected_coords,'UniformOutput',false);
        porportion=cellfun(@(x,y) x./y, neuron_count_map,neuron_count_map_all,'UniformOutput',false);



        figure(fig2)
        ax1=nexttile(tl2,8+curr_stim)
        hold on
        temp_data_mean=nanmean(cat(1,porportion{:}),1)
        temp_data_error=std(cat(1,porportion{:}),0,1,'omitmissing')/sqrt(size(porportion,1));
        ap.errorfill(z_edges(1:end-1),temp_data_mean,temp_data_error,colors{curr_group},0.1,0.5);
        if used_stim<7
            ylim(ax1,[0 0.5])
        else
            ylim(ax1,[0 1])
        end
        xlim(ax1,[250 600])

        title('proportion')
        xlabel('depth (\mum)')



        firing_rates_bins =cellfun(@(x,idx) arrayfun(@(col) ...
            accumarray(idx, x(:,col), [length(z_edges)-1,1], @mean, NaN), ...
            1:size(x,2), 'UniformOutput', false),firing_rates,binIdx_all, 'UniformOutput', false);


        firing_rates_bins1=cellfun(@(x) cat(2,x{:}),firing_rates_bins,'UniformOutput',false);
        firing_rates_bins2=nanmean(cat(3,firing_rates_bins1{:}),3);


        % plots in 3 groups
        firing_rates_all=cat(1,firing_rates{:});
        [~,~,binIdx_3] = histcounts(cat(1,projected_coords_all{:}), z_edge_3)
        firing_rates_bins_mean_3= arrayfun(@(col) ...
            accumarray(binIdx_3, firing_rates_all(:,col), [length(z_edge_3)-1,1], @mean, NaN), ...
            1:size(firing_rates_all,2), 'UniformOutput', false)
        sem_func = @(x) std(x,'omitmissing') / sqrt(numel(x));  % 定义计算SEM的函数
        firing_rates_bins_error_3= arrayfun(@(col) ...
            accumarray(binIdx_3, firing_rates_all(:,col), [length(z_edge_3)-1,1], sem_func), ...
            1:size(firing_rates_all,2), 'UniformOutput', false)
        max_funx=@(x) max

        figure(fig2)
        ax1=nexttile(tl2,12+curr_group*4+curr_stim)
        ap.errorfill(t_bins,cat(2,firing_rates_bins_mean_3{:})',...
            cat(2,firing_rates_bins_error_3{:})',parula(3),0.1,0.5)
        xlim([0 0.3])
        if used_stim<7
            ylim([0 2])
        else
            ylim([0 4])
        end


        % MUA max
        ax1=nexttile(tl2,12+curr_stim)
        firing_rates_max=cellfun(@(x) max(x(:,psth_use_t_stim),[],2),firing_rates_bins1,'UniformOutput',false );
        ap.errorfill(z_edges(1:end-1), nanmean(cat(2,firing_rates_max{:}),2),...
            std(cat(2,firing_rates_max{:}),0,2,'omitmissing')./sqrt(size(cat(2,firing_rates_max{:}),2)),colors{curr_group},0.1,0.5)

        if used_stim<7
            ylim(ax1,[0 4])
        else
            ylim(ax1,[0 10])
        end
        xlim(ax1,[250 600])

        title('activity')
        xlabel('depth (\mum)')

        figure(fig2)
        ax2=nexttile(tl2)
        h2=imagesc(t_bins,z_edges(1:end-1),firing_rates_bins2)
        xlim([-0.1 0.5])
        xlabel('time (s)')
        ylabel('depth (\mum)')
        ylim([z_edges(2)+0.5*bin_size_z  z_edges(end)-1.5*bin_size_z])
        if used_stim<7
            clim([0 2])
        else
            clim([0 5])
        end
        colormap(ax2,ap.colormap('WK'))
        colorbar
        if curr_group==1
            title(titles(used_stim))
        end


    end
end
% saveas(fig1,[Path 'figures\Figure\numbers of responsive neurons'  ], 'jpg');
% saveas(fig2,[Path 'figures\Figure\firing rates'  ], 'jpg');
% saveas(fig3,[Path 'figures\Figure\numbers of all neurons'  ], 'jpg');
% saveas(fig4,[Path 'figures\Figure\proportion_based_on_deepth'  ], 'jpg');
% saveas(fig5,[Path 'figures\Figure\proportion_based_on_numbers'  ], 'jpg');

%% probe position
groups={'VA','AV','VA_nA'}
% cmap = jet(length(animals));

for curr_group=1:2
    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);

    obj=ap.ccf_draw
    obj.draw_name('caudoputamen')
        % obj.draw_name('hippocampal region')

    obj.ccf_fig.Position=[50 50 800 200]
    used_position=animals_probe_positions(~cellfun(@isempty ,used_idx,'UniformOutput',true));
    on_empty_idx=used_idx(~cellfun(@isempty ,used_idx,'UniformOutput',true));
    for curr_animal=1:length(animals(~cellfun(@isempty ,used_idx,'UniformOutput',true)))
        cmap = jet(sum(~cellfun(@isempty ,used_idx,'UniformOutput',true)));

        for curr_probe=on_empty_idx{curr_animal}
            preload_vars = who;

            if isempty(curr_probe)

                continue
            end

            probe_line=used_position{curr_animal}{curr_probe}';

            % Draw probes on coronal + saggital
            line(obj.ccf_axes(1),probe_line(:,3),probe_line(:,2),'linewidth',2,'color',cmap(curr_animal,:));
            line(obj.ccf_axes(2),probe_line(:,3),probe_line(:,1),'linewidth',2,'color',cmap(curr_animal,:));
            line(obj.ccf_axes(3),probe_line(:,2),probe_line(:,1),'linewidth',2,'color',cmap(curr_animal,:));
            line(obj.ccf_axes(4),probe_line(:,1),probe_line(:,3),probe_line(:,2), ...
                'linewidth',2,'color',cmap(curr_animal,:))
        end
    end


    colormap(cmap);          % 设置 colormap
    cb=colorbar('Ticks', linspace(0, 1, 5), ...
        'TickLabels', animals(~cellfun(@isempty ,used_idx,'UniformOutput',true)));  % 可自定义标签
    % 获取当前 colorbar 的位置
    pos = cb.Position;     % pos = [x y width height]
    % 缩小宽度为原来的 50%
    pos(3) = pos(3) * 0.5;
    pos(4) = pos(4) * 0.5;
    cb.Position = pos;
    sgtitle(groups{curr_group})
    saveas(gcf,[Path 'figures\Figure\ephys probe trajectory' groups{curr_group}  ], 'jpg');
end

