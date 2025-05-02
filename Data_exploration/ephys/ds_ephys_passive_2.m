clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}0
animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS006','DS013',...
    'DS000','DS004','DS014','DS015','DS016'};

anterior_idx={[2 4],  [2 4],    2,    [2 4],  [2 4],  [2 4],    2,     2,     [2 4],  [2 4],  [2 4],  [2 4],  [2 4],  [2 4],  [2 4]};
anterior_learned_idx={[2 4],  [2 4],    2,    [2 4],  [2 4],  [   ],    [],    [],    [   ],  [   ],  [2 4],  [  4],  [2 4],  [2 4],  [2 4]};
anterior_learned_idx_VA={[2 4],  [2 4],    2,    [2 4],  [2 4],  [   ],    [],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};
anterior_learned_idx_VA_nA={[   ],  [   ],   [ ],    [   ],  [   ],  [2 4],    [],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};
anterior_learned_idx_VnA_nA={[   ],  [   ],   [],    [   ],  [   ], [  ],   [2],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};

anterior_learned_idx_AV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [   ],  [   ],  [2 4],  [  4],  [2 4],  [2 4],  [2 4]};
anterior_learned_idx_AV_nA={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [   ],  [ 4 ],  [  ],  [  2],  [   ],  [   ],  [  ]};
anterior_learned_idx_AnV_nV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [2 4],  [ 2 ],  [  ],  [   ],  [   ],  [   ],  [  ]};

% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t = [-0.2,0];
response_t = [0,0.2];
psth_use_t = t_centers >= response_t(1) & t_centers <= response_t(2);


titles={'L','M','R','4k','8k','12k','R task','8k task','move'};

%%
animals_all_cell_position_sorted=cell(length(animals),1);
animals_all_cell_sorted=cell(length(animals),1);
animals_all_event_response=cell(length(animals),1);
animals_probe_positions=cell(length(animals),1);
animals_all_event_plot=cell(length(animals),1);
animals_all_event_single_plot=cell(length(animals),1);
% animals_all_event_single_plot_single_trial=cell(length(animals),1);
animals_all_event_single_plot_h1=cell(length(animals),1);
animals_all_event_single_plot_h2=cell(length(animals),1);

animals_all_celltypes=cell(length(animals),1);
for curr_animal=1:length(animals)

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
    %%
    probe_positions=cell(4,1);
    all_cell_position=cell(4,1);
    all_cell_sorted=cell(4,1);
    all_cell_position_sorted=cell(4,1);

    all_event_response_idx=cell(2,1);
    all_event_response_plot=cell(2,1);
    all_event_response_signle_neuron=cell(2,1);
    % all_event_response_signle_neuron_single_trial=cell(2,1);
    all_event_response_signle_neuron_h1=cell(2,1);
    all_event_response_signle_neuron_h2=cell(2,1);

    all_celltypes=cell(4,1);

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

            %% PSTH - units
            idx = find(strcmp(probe_areas{1, 1}  .safe_name, 'Caudoputamen'));
            depth=probe_areas{1}.probe_depth(idx,:);
            % Plot responsive units by depth
            striatal_units=any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2);
            template_sort=find(any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2));

            all_cell_position{curr_day}=template_depths;

            % depth of each neuron
            unit_depths_sorted=template_depths(template_sort);
            all_cell_sorted{curr_day}=template_sort;
            all_cell_position_sorted{curr_day}=unit_depths_sorted;

            %% define cell types

            if curr_task==3
                spike_acg = nan(sum(striatal_units),2001);
                spike_acg = cell2mat(arrayfun(@(x) ...
                    ap.ephys_spike_cg(x),find(striatal_units),'uni',false));

                % Get time to get to 90% steady-state value
                acg_steadystate = nan(sum(striatal_units),1);
                acg_steadystate(~any(isnan(spike_acg),2)) = arrayfun(@(x) ...
                    find(spike_acg(x,ceil(size(spike_acg,2)/2):end) > ...
                    mean(spike_acg(x,end-100:end),2)*0.9,1,'first'),find(~any(isnan(spike_acg),2)));

                % (UNUSED: ACG RATIO)
                acg_early = max(spike_acg(:,1001:1001+300),[],2);
                acg_late = max(spike_acg(:,end-200:end-100),[],2);
                acg_ratio = acg_late./acg_early;

                % Get average firing rate from whole session
                spike_rate = accumarray(spike_templates,1)/diff(prctile(spike_times_timelite,[0,100]));

                % Define cell types
                % (NOTE: Julie uses acg_steadystate of 40, seemed better here for 20)
                striatum_celltypes = struct;

                striatum_celltypes.msn = ... % striatal_single_units & ... % striatal single unit
                    waveform_duration_peaktrough(striatal_units) >= 400 & ... wide waveform
                    acg_steadystate < 20; % fast time to steady state

                striatum_celltypes.fsi = ... % striatal_single_units & ... % striatal single unit
                    waveform_duration_peaktrough(striatal_units) < 400 & ... % narrow waveform
                    acg_steadystate < 20; % slow time to steady state

                % striatum_celltypes.tan = striatal_single_units & ... % striatal single unit
                %     spike_rate >= 4 & spike_rate <= 12 & ... % steady firing rate
                %     waveform_duration_peaktrough >= 400 & ... wide waveform
                %     acg_steadystate >= 20; % slow time to steady state

                % !! NOT USING WAVEFORM DURATION HERE - some clear TANs with short wfs
                striatum_celltypes.tan = ... % striatal_single_units & ... % striatal single unit
                    spike_rate(striatal_units) >= 4 & spike_rate(striatal_units) <= 16 & ... % steady firing rate
                    acg_steadystate >= 20; % slow time to steady state
                all_celltypes{curr_day}=striatum_celltypes;

            end
            %%




            % Get responsive units

            % Set event to get response
            % (get quiescent trials)
            stim_window = [0,0.5];
            quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
                timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
                timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
                (1:length(stimOn_times))');
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



                wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
                wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);

                wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
                wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);


                % 找到 wheel 开始转动的索引
                start_idx = find(diff([0;wheel_move]) == 1);
                % 预分配时间数组 (提高效率)
                time_to_90 = nan(size(start_idx));
                % **优化的计算方式**
                for i = 1:length(start_idx)
                    % 直接找到第一个满足 wheel_position > pos_start + 90 的索引
                    target_idx = find(wheel_position(start_idx(i):length(wheel_position)) < wheel_starts_position(i) - (30/360*1024), 1, 'first');
                    % 计算所需时间 (以 ms 计算)
                    if ~isempty(target_idx)
                        time_to_90(i) = (target_idx - 1) * 1; % 1000Hz 采样率，每点 1ms
                    end
                end
                wheel_move_less_than_200ms= time_to_90<200;

                wheel_move_over_90=wheel_stops_position-wheel_starts_position<-(30/360*1024);


                % (get wheel starts when no stim on screen: not sure this works yet)
                iti_move_idx = interp1(photodiode_times, ...
                    photodiode_values,wheel_starts,'previous') == 0;

                % trial_move_idx = interp1(photodiode_times, ...
                %     photodiode_values,wheel_starts,'previous')==1 ;
                % wheel_move_time=wheel_stops-wheel_starts;
                % trial_move_time=median(wheel_move_time(trial_move_idx))

                use_align{3,1} =  wheel_starts(iti_move_idx & wheel_move_over_90 & wheel_move_less_than_200ms );

            end
            %%
            % all_unit_psth=...
            %     cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates),use_align','UniformOutput',false);
            %
            [all_unit_psth_smooth_norm,raster,t]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align,'UniformOutput',false);


            % 生成所有的索引
            rand_idx_all = cellfun(@(x) randperm(length(x)), use_align, 'UniformOutput', false);
            % 拆分索引
            half_idx = cellfun(@(idx) idx(1:floor(length(idx)/2)), rand_idx_all, 'UniformOutput', false);
            rest_idx = cellfun(@(idx) idx(floor(length(idx)/2)+1:end), rand_idx_all, 'UniformOutput', false);
            % 按索引取值
            use_align_half1 = cellfun(@(x, idx) sort(x(idx)), use_align, half_idx, 'UniformOutput', false);
            use_align_half2 = cellfun(@(x, idx) sort(x(idx)), use_align, rest_idx, 'UniformOutput', false);

            [all_unit_psth_smooth_norm_h1,raster,t]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align_half1,'UniformOutput',false);
            [all_unit_psth_smooth_norm_h2,raster,t]=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align_half2,'UniformOutput',false);


            %%

            unit_psth_smooth_norm{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm,'UniformOutput',false);
            % unit_raster_smooth_norm{curr_task} = cellfun(@(x)    x(:,:,template_sort),raster,'UniformOutput',false);
            unit_psth_smooth_norm_h1{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm_h1,'UniformOutput',false);
            unit_psth_smooth_norm_h2{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm_h2,'UniformOutput',false);

            if curr_task==1||curr_task==2
                for curr_i=1:3
                    baseline_bins = use_align{curr_i} + baseline_t;
                    response_bins = use_align{curr_i} + response_t;

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

                    % responsive_units{curr_task}{i} = find(event_response_p{curr_task}{i} < 0.05 | event_response_p{curr_task}{i} > 0.95);
                    responsive_units{curr_task}{curr_i} = find( event_response_p{curr_task}{curr_i} > 0.95);
                end

            elseif curr_task==3

                for curr_i=1:3

                    baseline_bins = use_align{curr_i} + baseline_t;
                    response_bins = use_align{curr_i} + response_t;
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

                    % responsive_units{curr_task}{i} = find(event_response_p{curr_task}{i} < 0.05 | event_response_p{curr_task}{i} > 0.95);
                    responsive_units{curr_task}{curr_i} = find( event_response_p{curr_task}{curr_i} > 0.95);

                end

            end


        end

        probe_positions{curr_day}=probe_nte.probe_positions_ccf{1};

        unit_dots = ap.plot_unit_depthrate(spike_templates(ismember(spike_templates, template_sort)),template_depths,probe_areas);
        unit_dots.CData = +([0,0,1].*(event_response_p{1}{3} > 0.95)) +...
            ([1, 0,0].*(event_response_p{2}{2} > 0.95));

        saveas(gcf,[Path 'figures\summary\probe of ' animal ' in day ' num2str(curr_day)], 'jpg');
        close
        % package_unit_raster_smooth_norm = [unit_raster_smooth_norm{1}, unit_raster_smooth_norm{2}, unit_raster_smooth_norm{3}'];

        package_unit_psth_smooth_norm = [unit_psth_smooth_norm{1}', unit_psth_smooth_norm{2}', unit_psth_smooth_norm{3}'];

        package_event_response_p=cat(2,event_response_p{:});
        plot_mean=cellfun(@(x,y) nanmean(x( find( y > 0.95),:),1),package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        plot_sem=cellfun(@(x,y) std(x(find( y > 0.95 ),:),0,1)/sqrt(size(x(find( y>0.95 ),:),1)), package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        plot_mean_from_r=cellfun(@(x,y) nanmean(x( find( y > 0.95 & package_event_response_p{3}>0.95),:),1),package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        plot_sem_from_r=cellfun(@(x,y) std(x(find( y > 0.95 & package_event_response_p{3}>0.95),:),0,1)/sqrt(size(x(find( y>0.95 ),:),1)), package_unit_psth_smooth_norm,package_event_response_p,'UniformOutput',false  );
        all_responsive_idx =(cell2mat(cellfun(@(x)   cell2mat(x),event_response_p,'UniformOutput',false))>0.95);
        all_responsive = all_responsive_idx(~all(all_responsive_idx == 0, 2), :);
        all_event_response_idx{curr_day}=all_responsive_idx;
        all_event_response_plot{curr_day}=cat(1,plot_mean{:});
        all_event_response_signle_neuron{curr_day}=cat(3,package_unit_psth_smooth_norm{:});
        % all_event_response_signle_neuron_single_trial{curr_day}=package_unit_raster_smooth_norm;


        package_unit_psth_smooth_norm_h1 = [unit_psth_smooth_norm_h1{1}', unit_psth_smooth_norm_h1{2}', unit_psth_smooth_norm_h1{3}'];
        package_unit_psth_smooth_norm_h2 = [unit_psth_smooth_norm_h2{1}', unit_psth_smooth_norm_h2{2}', unit_psth_smooth_norm_h2{3}'];
        all_event_response_signle_neuron_h1{curr_day}=cat(3,package_unit_psth_smooth_norm_h1{:});
        all_event_response_signle_neuron_h2{curr_day}=cat(3,package_unit_psth_smooth_norm_h2{:});



        figure('Position',[50 50 1200 200])
        for curr_stim=1:9
            nexttile
            reponsive_data=package_unit_psth_smooth_norm{curr_stim}(find(package_event_response_p{curr_stim}>0.95),:);
            [~,sort_idx] = sort(nanmean(reponsive_data(: ,psth_use_t),[2,3]));
            imagesc(t_centers,[],reponsive_data(sort_idx,:));
            colormap(ap.colormap('BWR'));
            clim([-5,5]);
            title(titles{curr_stim})
        end

        for curr_stim=1:9
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

    animals_all_cell_sorted{curr_animal}=all_cell_sorted;
        animals_all_cell_position_sorted{curr_animal}=all_cell_position_sorted;

    animals_probe_positions{curr_animal}=probe_positions;
    animals_all_event_response{curr_animal}=all_event_response_idx;
    animals_all_event_plot{curr_animal}=all_event_response_plot;
    animals_all_event_single_plot{curr_animal}=all_event_response_signle_neuron;
    % animals_all_event_single_plot_single_trial{curr_animal}=all_event_response_signle_neuron_single_trial;
    animals_all_event_single_plot_h1{curr_animal}=all_event_response_signle_neuron_h1;
    animals_all_event_single_plot_h2{curr_animal}=all_event_response_signle_neuron_h2;

    animals_all_celltypes{curr_animal}=all_celltypes;

end



save([Path 'mat_data\ephys_all_data.mat'],'animals',...
    'animals_probe_positions','animals_all_cell_sorted','animals_all_cell_position_sorted','animals_all_event_response',...
    'animals_all_event_plot','animals_all_event_single_plot','animals_all_celltypes',...
    'animals_all_event_single_plot_h1','animals_all_event_single_plot_h2','-v7.3')
%%
load([Path 'mat_data\ephys_all_data.mat'])

%% fraction of populations

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







VA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false ),1:9,'UniformOutput',false);
AV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false ),1:9,'UniformOutput',false);
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




%%
Result(1).name='visual2audio';
Result(1).data={VA_R,VA_8k,VA_8k_R,AV_R,AV_8k,AV_8k_R};
Result(1).label_names={'VA-R', 'VA-8k','VA-R&8k','AV-R', 'AV-8k','AV-R&8k'};

Result(2).name='response VA AV';
Result(2).data=[VA_each,AV_each];
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
for curr_fig=[ 2 5 6 7]
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

VA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y)  max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VA,'UniformOutput',false ),1:6,'UniformOutput',false);
AV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AV,'UniformOutput',false ),1:6,'UniformOutput',false);
VA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AV_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AV_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
VnA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_VnA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AnV_nV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) max(y(i,501:1000)), x,'UniformOutput',true) ,plot_AnV_nV,'UniformOutput',false ),1:6,'UniformOutput',false);


Result(1).name='response VA AV';
Result(1).data=[VA_each,AV_each];
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


    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec = vertcat(single_plot{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all=cat(1,single_neuron_each_rec{:});

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
    titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};

    for curr_i=used_matrix
        [~,max_idx]=max(single_neuron_all(: ,psth_use_t,curr_i),[],2);
        [~,sort_idx] = sortrows([response_all(:,curr_i), max_idx],[1,2],["descend","ascend"]);

        used_neruons=single_neuron_all(sort_idx,:,:);
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


        selected_neurons_each_rec=cellfun( @(x,y)  x(y,:,:), single_neuron_each_rec,use_idx_each_rec,'UniformOutput',false );
        selected_responses_each_rec=cellfun(@(x,y) x(y,curr_i) ,response_each_rec,use_idx_each_rec,'UniformOutput',false  );
        [~, max_idx_each_rec] = cellfun(@(x)   max(x(:, psth_use_t, curr_i), [], 2),selected_neurons_each_rec,'UniformOutput',false);
        % 排序：先按 response 值降序，再按 max_idx 升序
        [~, sort_idx_each_rec] =cellfun(@(x,y) sortrows([x, y], [1,2], ["descend","ascend"]),selected_responses_each_rec,max_idx_each_rec,'UniformOutput',false);
        sorted_neurons_each_rec =cellfun(@(x,y)  x(y, :, :) ,selected_neurons_each_rec,sort_idx_each_rec,'UniformOutput',false  );

        used_neruons_only_mean_each_rec=cellfun(@(x,y,z)  permute(mean(x(1:sum(y(z,curr_i)),:,:),1,'omitmissing'),[2 3 1]),...
            sorted_neurons_each_rec,response_each_rec,use_idx_each_rec,'UniformOutput',false);
        used_neruons_only_error_each_rec= std(cat(3,used_neruons_only_mean_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_only_mean_each_rec));

        used_neruons_non_responsive_mean_each_rec=cellfun(@(x,y,z)  permute(mean(x(sum(y(z,curr_i)):end,:,:),1,'omitmissing'),[2 3 1]),...
            sorted_neurons_each_rec,response_each_rec,use_idx_each_rec,'UniformOutput',false);
        used_neruons_non_responsive_error_each_rec=std(cat(3,used_neruons_non_responsive_mean_each_rec{:}),0,3,'omitmissing')/sqrt(length(used_neruons_non_responsive_mean_each_rec));



        selected_neurons = single_neuron_all(use_idx, :, :);
        selected_responses = response_all(use_idx, curr_i);

        % 计算每个神经元在 psth_use_t 处的最大值索引
        [~, max_idx] = max(selected_neurons(:, psth_use_t, curr_i), [], 2);

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

    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec = vertcat(single_plot{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all=cat(1,single_neuron_each_rec{:});

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


    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec = vertcat(single_plot{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all=cat(1,single_neuron_each_rec{:});



    no_empty_idx=~cellfun(@isempty, used_idx','UniformOutput',true);
    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(no_empty_idx) ,...
        used_idx(no_empty_idx)','UniformOutput',false);


    strcut_idx=cellfun(@(x) cellfun(@(y) strcmp('struct', class(y))  ,x,'UniformOutput',true) ,animals_all_celltypes,'UniformOutput',false) ;

    neurons_type=cellfun(@(x,y,z,h) cellfun(@(s,q) find(s.(neuron_type{curr_type})==1&sum(q(:,[3 5 7 8]), 2) > 0) ,...
        x(intersect(find(z),h)),y(intersect(find(z),h)),'UniformOutput',false) ,...
        animals_all_celltypes(no_empty_idx),animals_all_event_response(no_empty_idx),strcut_idx(no_empty_idx),...
        used_idx(no_empty_idx)','UniformOutput',false)  ;

    selected_neurons=cellfun(@(x,y) cellfun(@(a1,a2)  a1(a2,:,:)  ,x,y,'UniformOutput',false)  ,single_plot,neurons_type,'UniformOutput',false)
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
        [~,max_idx]=max(selected_neurons_1(: ,psth_use_t,curr_i),[],2);
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
figure('Position',[50 50 400 800]);
cmap = [ ...
    84 130 53  % #548235
    127 175 174 % #BBCDAE
    192 192 80 % #C0C0C0
    ] / 255;
used_stim=3
titles={'L','M','R','4k','8k','12k','R task','8k task','iti move'};
max_num=700
for curr_group=1:2

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])
    used_celltypes=eval('base',['celltypes_'  groups{curr_group}])

    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec = vertcat(single_plot{:});
    single_neuron_all=cat(1,single_neuron_each_rec{:});

    single_plot_h1=cellfun(@(x,y)  x(y),animals_all_event_single_plot_h1(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec_h1 = vertcat(single_plot_h1{:});
    single_neuron_all_h1=cat(1,single_neuron_each_rec_h1{:});

    response_each_rec= vertcat(used_filter_idx{:});
    response_all=cat(1,response_each_rec{:});

    celltypes_each_rec= vertcat(used_celltypes{:});
    celltypes_msn= cellfun(@(x)  x.msn, celltypes_each_rec,'UniformOutput',false);
    celltypes_fsi= cellfun(@(x)  x.fsi, celltypes_each_rec,'UniformOutput',false);
    celltypes_tan= cellfun(@(x)  x.tan, celltypes_each_rec,'UniformOutput',false);

    celltypes_msn_all=cat(1,celltypes_msn{:});
    celltypes_fsi_all=cat(1,celltypes_fsi{:});
    celltypes_tan_all=cat(1,celltypes_tan{:});

    use_idx= response_all(:,used_stim) == 1
    number_neuron=sum(use_idx)

    clim_value=[0,6];

    [~,max_idx]=max(single_neuron_all(: ,psth_use_t,used_stim),[],2);
    [~,sort_idx] = sortrows([response_all(:,used_stim), max_idx],[1,2],["descend","ascend"]);

    used_neruons=single_neuron_all(sort_idx,:,:);
    used_neruons_sort=used_neruons(use_idx(sort_idx),:,:);

    ax=subplot(4,2,[curr_group,2+curr_group])
    imagesc(t_centers,[],used_neruons_sort(:,:,used_stim))

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

    selected_neurons_each_rec_msn=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec,use_idx_each_rec,celltypes_msn,'UniformOutput',false );
    selected_neurons_each_rec_fsi=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec,use_idx_each_rec,celltypes_fsi,'UniformOutput',false );
    selected_neurons_each_rec_tan=cellfun( @(x,y,z)  x((y&z),:,:), single_neuron_each_rec,use_idx_each_rec,celltypes_tan,'UniformOutput',false );
    selected_neurons_each_rec=cellfun( @(x,y)  x(y,:,:), single_neuron_each_rec,use_idx_each_rec,'UniformOutput',false );

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


    subplot(4,2,curr_group+4)
    ap.errorfill(t_bins,used_neurons_only_mean(:,used_stim),used_neruons_only_error_each_rec(:,used_stim),[1 0 0],0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_msn(:,used_stim),used_neruons_only_error_msn_each_rec(:,used_stim),cmap(1,:),0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_fsi(:,used_stim),used_neruons_only_error_fsi_each_rec(:,used_stim),cmap(2,:),0.1 ,0.5);
    ap.errorfill(t_bins,used_neruons_only_mean_tan(:,used_stim),used_neruons_only_error_tan_each_rec(:,used_stim),cmap(3,:),0.1 ,0.5);

    ylim([-0.5 5])
    xlabel('time (s)')

    names=  ['a' num2str(curr_group)];
    figures.(names)=subplot(4,2,curr_group+6)

    types_numbers=[size(cat(1,selected_neurons_each_rec_msn{:}),1),size(cat(1,selected_neurons_each_rec_fsi{:}),1)...
        size(cat(1,selected_neurons_each_rec_tan{:}),1)]

    pie(types_numbers)

    % set(figures.(names), 'Colormap', cmap); % 红、绿、蓝

    legend({'MSN','FSI','TAN'}, 'Location', 'northoutside', 'Orientation', 'vertical','Box','off');

end
sgtitle(titles{used_stim})
set(figures.a1, 'Colormap', cmap); % 红、绿、蓝
set(figures.a2, 'Colormap', cmap); % 红、绿、蓝

saveas(gcf,[Path 'figures\Figure\ephys pesth of single neurons in passive '  titles{used_stim} groups{curr_group} ], 'jpg');


%%

group_name={'VA','AV'};
neuron_type={'tan','fsi','msn','all'}

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



V_task_all=sum(responsive_neuron_1(:,7));
V_passive_all=sum(responsive_neuron_1(:,3));
V_task_passive=sum(responsive_neuron_1(:,7) & responsive_neuron_1(:,3));
V_only= sum(~responsive_neuron_1(:,8) & ~responsive_neuron_1(:,5) & ...
    (responsive_neuron_1(:,7) | responsive_neuron_1(:,3)));

A_task_all=sum(responsive_neuron_1(:,8));
A_passive_all=sum(responsive_neuron_1(:,5));
A_task_passive=sum(responsive_neuron_1(:,8) & responsive_neuron_1(:,5));
A_only=sum(~responsive_neuron_1(:,7) & ~responsive_neuron_1(:,3) & ...
    (responsive_neuron_1(:,8) | responsive_neuron_1(:,5)));

V_A_task=sum(responsive_neuron_1(:,8) &  ...
    responsive_neuron_1(:,7) );
V_A_passive=sum(responsive_neuron_1(:,5) &  ...
    responsive_neuron_1(:,3) );
V_A_task_passive=sum(responsive_neuron_1(:,8) & responsive_neuron_1(:,5) & ...
    responsive_neuron_1(:,7) & responsive_neuron_1(:,3));


plot_V_task_all=responsive_neuron_plot_1(responsive_neuron_1(:,7),:,:);
plot_V_passive_all=responsive_neuron_plot_1(responsive_neuron_1(:,3),:,:);
plot_V_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,7) & responsive_neuron_1(:,3),:,:);

plot_V_only= responsive_neuron_plot_1(~responsive_neuron_1(:,8) & ~responsive_neuron_1(:,5) & ...
    (responsive_neuron_1(:,7) | responsive_neuron_1(:,3)),:,:);

plot_A_task_all=responsive_neuron_plot_1(responsive_neuron_1(:,8),:,:);
plot_A_passive_all=responsive_neuron_plot_1(responsive_neuron_1(:,5),:,:);
plot_A_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,8) & responsive_neuron_1(:,5),:,:);
plot_A_only=responsive_neuron_plot_1(~responsive_neuron_1(:,7) & ~responsive_neuron_1(:,3) & ...
    (responsive_neuron_1(:,8) | responsive_neuron_1(:,5)),:,:);

plot_V_A_task_passive=responsive_neuron_plot_1(responsive_neuron_1(:,8) & responsive_neuron_1(:,5) & ...
    responsive_neuron_1(:,7) & responsive_neuron_1(:,3),:,:);
plot_V_A_task=responsive_neuron_plot_1(responsive_neuron_1(:,8) & ...
    responsive_neuron_1(:,7),:,:);
plot_V_A_passive=responsive_neuron_plot_1(responsive_neuron_1(:,3) & ...
    responsive_neuron_1(:,5),:,:);


%韦恩图不准确

% 
% % 安装 venn 函数后
% % https://www.mathworks.com/matlabcentral/fileexchange/10652-venn
% 
% % 设置集合交集数量
% areas = [onlyA, onlyB, onlyC];
% intersections = [AB, AC, BC, ABC];
% figure
% [H,S] = venn(areas, intersections, ...
%     'FaceColor', {[1 0.6 0.6], [0.6 1 0.6], [0.6 0.6 1]}, ... % 红绿蓝
%     'FaceAlpha', 0.5, ...
%     'EdgeColor', 'black', ...
%     'ErrMinMode', 'none');  % 禁用误差容忍机制（重要！）
% 
% % 添加数字标注
% % 找到每个交集的中心坐标，然后加标签
% labels = { ...
%     num2str(onlyA), num2str(onlyB), num2str(onlyC), ...
%     num2str(AB), num2str(AC), num2str(BC), num2str(ABC)};
% 
% positions = S.ZoneCentroid;  % 每个区域中心位置
% hold on;
% for i = 1:length(labels)
%     text(positions(i,1), positions(i,2), labels{i}, ...
%         'HorizontalAlignment', 'center', ...
%         'FontSize', 12, 'FontWeight', 'bold');
% end
% 
% legend({'A', 'B', 'C'}, 'Location', 'bestoutside');
% title('Venn diagram of neuron responses');

plot_new{curr_group}{curr_type}={plot_V_task_all,plot_V_passive_all,plot_V_task_passive,plot_V_only,...
   plot_A_task_all,plot_A_passive_all,plot_A_task_passive ,plot_A_only...
  ,plot_V_A_task,plot_V_A_passive,plot_V_A_task_passive };

 counts_new{curr_group}{curr_type}=...
     [V_task_all,V_passive_all,V_task_passive, V_only,...
     A_task_all,A_passive_all,A_task_passive,A_only,...
     V_A_task,V_A_passive,V_A_task_passive]./size(responsive_neuron_1,1);


% colors = [1 0.6 0.6; 0.6 1 0.6; 0.6 0.6 1; 1 1 0.6; 1 0.6 1; 0.6 1 1; 0.85 0.85 0.85];
% figure('Position',[50 50 1500 900])
% 
% tiledlayout(1, 6, 'Padding', 'compact', 'TileSpacing', 'compact');
% 
% for curr_figure=1:6
%     switch  curr_figure
%         case 1
%         counts = [onlyl, onlym, onlyr, lm, lr, mr, lmr];
%         labels = {'L only','M only','R only','L&M','L&R','M&R','L&M&R'};
% 
%         case 2
%         counts = [only4k, only8k, only12k, k4k8, k4k12, k8k12, k4k8k12];
%         labels = {'4K only','8K only','12K only','4K&8K','4K&12K','8K&12K','4K&8K&12K'};
%         case 3
%             counts = [olnyr_r_8k, olny8k_r_8k, r_k8];
%         labels = {'R only','8K only','R&8K'};
%         case 4
%             counts = [olnyr_r_v, olnyv_r_v, r_v];
%         labels = {'V passive only','V task only','V passive&task'};
%         case 5
%             counts = [olny8K_8k_a, olnya_8k_a, k8_a];
%         labels = {'A passive only','A task only','A passive&task'};
%         case 6
%             counts = [olnyv_v_a, olnya_v_a, v_a];
%         labels = {'V task','A task','V&A task'};
% 
%     end
% % === 2. 绘制 ===
% % fractions = counts / sum(counts);  % 归一化用于面积比例
% fractions = counts / size(responsive_neuron_1,1);  % 归一化用于面积比例
% 
% % clf; 
% nexttile;
% hold on; axis off;
% 
% x0 = 0; y = 0; w = 1;
% [~, order] = sort(fractions, 'ascend');
% 
% y_step=0.05
% % total_height = sum(fractions) * 10 + (length(fractions) - 1) * y_step;
% % % 计算顶部对齐的起始 y 坐标
% % y_top = total_height;
% for i = 1:length(order)
%     k = order(i); h = fractions(k) * 10;
%     rectangle('Position', [x0, y, w, h], ...
%               'FaceColor', colors(k,:), 'EdgeColor', 'k');
% 
%     % 去掉连线，文字紧贴右边
%     text(x0 + w + 0.1, y + h/2, ...
%         sprintf('%s: %d (%.1f%%)', labels{k}, counts(k), 100*fractions(k)), ...
%         'FontSize', 10, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
% 
%     y = y + h + y_step;
% end
% 
% xlim([0, 3]);
% end
% sgtitle([neuron_type{curr_type}  ' in ' group_name{curr_group}])
% saveas(gcf,[Path 'figures\Figure\ephys classification '  neuron_type{curr_type}  ' in ' group_name{curr_group} ], 'jpg');

end
end
%% proportion of responsive neurons in different types
figure('Position',[50 50 900 300]);
t = tiledlayout(1, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
neuron_type={'TANs','FSIs','MSNs','All'}

for curr_type=[4 1 2 3]
nexttile
hBar=bar([counts_new{1}{curr_type};counts_new{2}{curr_type}]','group')
box off
% 设置每组的颜色
   % #548235
     % #7030A0
colors1=[84 130 53; 112  48 160]./255;
for i = 1:length(hBar)
    hBar(i).FaceColor = colors1(i, :);
         hBar(i).EdgeColor = 'none';       % 无边框线

end
xline(4.5,'LineStyle',':')
xline(8.5,'LineStyle',':')

% 设置 x 轴标签
labels={'V task',  'V passive', 'V task&passive','V only',...
    'A task', 'A passive', 'A task&passive','A only', ...
    'V&A task','V&A passive','V&A task&passive'};
set(gca, 'XTick', 1:11, 'XTickLabel',labels );
ylim([0 1])
ylabel('proportion')
title(neuron_type{curr_type})
end
saveas(gcf,[Path 'figures\Figure\ephys proportion of responsive neurons '   ], 'jpg');



plotmean=cellfun(@(x) cellfun(@(y) cellfun(@(q) permute( nanmean(q(:,:,[3,5,7,8]),1),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);

plot_error=cellfun(@(x) cellfun(@(y) cellfun(@(q) permute( std(q(:,:,[3,5,7,8]),0,1,'omitmissing')/sqrt(size(q,1)),[2,3,1]),y,'UniformOutput',false),...
    x,'UniformOutput',false),...
    plot_new,'UniformOutput',false);
%%
colors={[0.5, 0.5,1],[1,0.5,0.5],[0,0,1],[1,0,0]}
for curr_type=1:4
figure('Position',[50 50 1600 500]);

t = tiledlayout(2, 11, 'TileSpacing', 'loose', 'Padding', 'loose');

for curr_group=1:2
    for curr_event=1:11
        nexttile
arrayfun(@(n) ap.errorfill(t_bins,plotmean{curr_group}{curr_type}{curr_event}(:,n),...
    plot_error{curr_group}{curr_type}{curr_event}(:,n),colors{n},0.5,0.1),1:4);
xlim([-0.2 0.5])
ylim([-1 5])
    title(labels{curr_event})

    end
end
sgtitle(neuron_type{curr_type})
saveas(gcf,[Path 'figures\Figure\ephys plot of responsive neurons in ' neuron_type{curr_type}  ], 'jpg');
end
%%


%% Load atlas
groups={'VA','AV','VA_nA'}
curr_group=1
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
        cells_position{curr_probe} = animals_probe_positions{curr_animal}{curr_probe}(:,1)' + animals_all_cell_position_sorted{curr_animal}{curr_probe}/3840 * (animals_probe_positions{curr_animal}{curr_probe}(:,2) - animals_probe_positions{curr_animal}{curr_probe}(:,1))';




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

        % s= scatter3(x_jitter,y_jitter,...
        %     cells_position{curr_probe}(responsive_neurons,2),10,colorMap,'filled')

        plot3(animals_probe_positions{curr_animal}{curr_probe}(1,:),...
            animals_probe_positions{curr_animal}{curr_probe}(3,:),animals_probe_positions{curr_animal}{curr_probe}(2,:))
        hold on

        clearvars('-except',preload_vars{:});

    end

end

%%
groups={'VA','AV','VA_nA'}
    % cmap = jet(length(animals));

for curr_group=1:2
used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}]);

obj=ap.ccf_draw
obj.draw_name('caudoputamen')
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