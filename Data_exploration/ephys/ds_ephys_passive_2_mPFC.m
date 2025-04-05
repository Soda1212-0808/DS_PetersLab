clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}
animals= { 'DS007','DS004','DS014'};

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



animals_all_cell_position_sorted=cell(length(animals),1);
animals_all_event_response=cell(length(animals),1);
animals_probe_positions=cell(length(animals),1);
animals_all_event_plot=cell(length(animals),1);
animals_all_event_single_plot=cell(length(animals),1);
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

    probe_positions=cell(4,1);
    all_cell_position=cell(4,1);
    all_cell_position_sorted=cell(4,1);
    all_event_response_idx=cell(2,1);
    all_event_response_plot=cell(2,1);
    all_event_response_signle_neuron=cell(2,1);
    %%
    for curr_day=5:6

        day_probe={'mPFC','mPFC'};
        preload_vars = who;

        if length(recordings_training)<curr_day
            continue
        end

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
            idx = find(ismember(probe_areas{1, 1}.safe_name, {'Secondary motor area layer 5', ...
                                                  'Anterior cingulate area dorsal part layer 5', ...
                                                  'Secondary motor area layer 6a'}));
            depth=probe_areas{1}.probe_depth(:,:);
                        % depth=probe_areas{1}.probe_depth(idx,:);

            % Plot responsive units by depth
            template_sort=find(any(template_depths>depth(:,1)'&template_depths<depth(:,2)',2));

            all_cell_position{curr_day}=template_depths;

            % depth of each neuron
            unit_depths_sorted=template_depths(template_sort);
            all_cell_position_sorted{curr_day}=unit_depths_sorted;


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
                use_align = arrayfun(@(x) {stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials)}, stim_values, 'UniformOutput', false);
            elseif contains(bonsai_workflow,'hml')
                % (aud passive)
                stim_type = vertcat(trial_events.values.StimFrequence);
                stim_values = unique(stim_type);
                use_align = arrayfun(@(x) {stimOn_times(stim_type(1:length(stimOn_times)) == x & quiescent_trials)}, stim_values, 'UniformOutput', false);

            elseif contains(bonsai_workflow,'stim_wheel')
                % (task)
                % use_align = stimOn_times(stim_to_move > 0.15);
                TaskType_idx= cell2mat({trial_events.values.TaskType})';
                use_align{1} = stimOn_times(TaskType_idx(1:n_trials)==0 );
                use_align{2} = stimOn_times(TaskType_idx(1:n_trials)==1 );

                wheel_starts = timelite.timestamps(diff([0;wheel_move]) == 1);
                wheel_stops = timelite.timestamps(diff([0;wheel_move]) == -1);
   
              wheel_starts_position=  wheel_position(diff([0;wheel_move]) == 1);
              wheel_stops_position=  wheel_position(diff([0;wheel_move]) == -1);
                            wheel_move_over_90=wheel_stops_position-wheel_starts_position<-90;

                % (get wheel starts when no stim on screen: not sure this works yet)
                iti_move_idx = interp1(photodiode_times, ...
                    photodiode_values,wheel_starts,'previous') == 0;

                % trial_move_idx = interp1(photodiode_times, ...
                %     photodiode_values,wheel_starts,'previous')==1 ;
                % wheel_move_time=wheel_stops-wheel_starts;
                % trial_move_time=median(wheel_move_time(trial_move_idx))

                use_align{3} = wheel_starts(iti_move_idx&(wheel_move_over_90));

            end
            %%
            all_unit_psth_smooth_norm=...
                cellfun(@(x) ap.psth(spike_times_timelite,x,spike_templates,'smoothing',100,'norm_window',[-0.5,0],'softnorm',1),use_align','UniformOutput',false);
            % [A,B,C]=ap.psth(spike_times_timelite,use_align,spike_templates,'smoothing',100);

            % figure;
            % for i=1:3
            % nexttile
            %  imagesc(all_unit_psth_smooth_norm{i})
            % end

            %%
            unit_psth_smooth_norm{curr_task} = cellfun(@(x)    x(template_sort,:),all_unit_psth_smooth_norm,'UniformOutput',false);

            if curr_task==1||curr_task==2
                for curr_i=1:3
                    baseline_bins = use_align{curr_i}{1} + baseline_t;
                    response_bins = use_align{curr_i}{1} + response_t;

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
         % unit_dots = ap.plot_unit_depthrate(spike_templates,template_depths,probe_areas);
        unit_dots.CData = +([0,0,1].*(event_response_p{1}{3} > 0.95)) +...
            ([1, 0,0].*(event_response_p{2}{2} > 0.95));
           
        % unit_dots.CData = +([0,0,1].*(event_response_p{1} > 0.95)) + ...
        %      +([1,0,0].*(event_response_p{2} > 0.95))+...
        %       +([0,1,0].*((event_response_p{2} > 0.95)& (event_response_p{1} > 0.95)));
         saveas(gcf,[Path 'figures\summary\probe of ' animal ' in day ' num2str(curr_day)], 'jpg');

        % % (sort by max time in single alignment)
        % sort_align = 1;
        % [~,max_t] = max(unit_psth_smooth_norm(responsive_units,:,sort_align),[],2);
        % [~,sort_idx] = sort(max_t);
        % figure('Position',[50 50 600 800],'Name',[animal ' in day ' num2str(curr_day) ' of ' day_probe{curr_day}])
        % t = tiledlayout(5, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
        % titles={'left','middle','right','4kHz','8kHz','12kHz'}


        package_unit_psth_smooth_norm = [unit_psth_smooth_norm{1}, unit_psth_smooth_norm{2}, unit_psth_smooth_norm{3}'];
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

            ylim([-1 4])
            % ylabel('z-score')
            xlabel('time (s)')


        end
        sgtitle([animal ' day' num2str(curr_day) ])

         saveas(gcf,[Path 'figures\summary\plot and heatmap of ' animal ' in day ' num2str(curr_day)], 'jpg');

        ap.print_progress_fraction(curr_day,length(recordings_training));
        clearvars('-except',preload_vars{:});


    end

    animals_all_cell_position_sorted{curr_animal}=all_cell_position_sorted;
    animals_probe_positions{curr_animal}=probe_positions;

    animals_all_event_response{curr_animal}=all_event_response_idx;
    animals_all_event_plot{curr_animal}=all_event_response_plot;
    animals_all_event_single_plot{curr_animal}=all_event_response_signle_neuron;


end


% %
%  save('C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\mat_data\all_data.mat','animals',...
%      'animals_probe_positions','animals_all_cell_position_sorted','animals_all_event_response','animals_all_event_plot','animals_all_event_single_plot','-v7.3')
% %%
%  load('C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\mat_data\all_data.mat')

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

VA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA,'UniformOutput',false ),1:6,'UniformOutput',false);
AV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV,'UniformOutput',false ),1:6,'UniformOutput',false);
VA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AV_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AV_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
VnA_nA_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_VnA_nA,'UniformOutput',false ),1:6,'UniformOutput',false);
AnV_nV_each=arrayfun(@(i) cellfun(@(x) cellfun(@(y) sum(y(:,i)==1)/size(y,1), x,'UniformOutput',true) ,filtered_AnV_nV,'UniformOutput',false ),1:6,'UniformOutput',false);

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
Result(2).label_names={'VA-L', 'VA-M','VA-R','VA-4k', 'VA-8k','VA-12k','AV-L', 'AV-M','AV-R','AV-4k', 'AV-8k','AV-12k'};

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
for curr_fig=[2 5 6 7]
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
for curr_group=1:2

    used_idx=eval('base',['anterior_learned_idx_'  groups{curr_group}])
    used_filter_idx=eval('base',['filtered_'  groups{curr_group}])


    single_plot=cellfun(@(x,y)  x(y),animals_all_event_single_plot(~cellfun(@isempty, used_idx','UniformOutput',true)) ,...
        used_idx(~cellfun(@isempty, used_idx','UniformOutput',true))','UniformOutput',false);
    single_neuron_each_rec = vertcat(single_plot{:});
    % cellfun(@(x) cat(1,x{:}),single_plot,'UniformOutput',false  );
    single_neuron_all=cat(1,single_neuron_each_rec{:});

    response_each_rec= vertcat(used_filter_idx{:});
    response_all=cat(1,response_each_rec{:});

    use_idx= any(response_all(:,[3 5 7 8]) == 1, 2)&(~(all(response_all(:,1:6) == 0, 2) & response_all(:,9)==1));

    use_idx_each_rec=cellfun(@(x) any(x(:,[3 5 7 8]) == 1, 2)&(~(all(x(:,1:6) == 0, 2) & x(:,9)==1)) , response_each_rec,'UniformOutput',false );

    clim_value=[-3,3];
    figure('Position',[50 50 1000 1000]);
    used_matrix=[3 5 7 8 9]
    tiledlayout(length(used_matrix),length(used_matrix)); % 创建一个1行2列的布局
    titles={'L','M','R','4k','8k','12k','R task','8k task','move'};

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

        used_neruons_only_mean=permute(mean(sorted_neurons(1:sum(response_all(use_idx,curr_i)),:,:),1,'omitmissing'),[2 3 1]);
        used_neruons_non_responsive_mean=permute(mean(sorted_neurons(sum(response_all(use_idx,curr_i)):end,:,:),1,'omitmissing'),[2 3 1]);

        for curr_idx=used_matrix
            nexttile
            ap.errorfill(t_bins,used_neruons_only_mean(:,curr_idx),used_neruons_only_error_each_rec(:,curr_idx),[1 0 0],0.1 ,0.5);

            hold on
            ap.errorfill(t_bins,used_neruons_non_responsive_mean(:,curr_idx),used_neruons_non_responsive_error_each_rec(:,curr_idx),[0 0 0],0.1 ,0.5);
                ylim([-0.5 5])
            xlabel('time (s)')
            title(titles{curr_idx})
        end

    end
    sgtitle(groups{curr_group})
savefig (gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}]);
 saveas(gcf,[Path 'figures\summary\plot responsive vs no responsive in '  groups{curr_group}], 'jpg');


end

%%


[~,max_idx_3]=max(single_neuron_all(: ,psth_use_t,3),[],2)
[~,max_idx_5]=max(single_neuron_all(: ,psth_use_t,5),[],2)

[~,sort_idx_3] = sortrows([response_all(:,3), max_idx_3],[1,2],["descend","ascend"]);
[~,sort_idx_5] = sortrows([response_all(:,5), max_idx_5],[1,2],["descend","ascend"]);

% [~,VA_sort_idx_3] = sortrows([VA_response_2(:,3), nanmean(VA_single_neuron_2(: ,psth_use_t,3),2)],[1,2],'descend');
% [~,VA_sort_idx_5] = sortrows([VA_response_2(:,5), nanmean(VA_single_neuron_2(: ,psth_use_t,5),2)],[1,2],'descend');

% use_idx= response_2(:,3)==1|response_2(:,5)==1;


% [~,VA_sort_idx_3] = sort(nanmean(VA_single_neuron_2(: ,psth_use_t,3),2),'descend');
% [~,VA_sort_idx_5] = sort(nanmean(VA_single_neuron_2(: ,psth_use_t,5),2),'descend');

clim_value=[-3,3];
figure('Position',[50 50 1400 400]);
tiledlayout(2, 9); % 创建一个1行2列的布局
titles={'L','M','R','4k','8k','12k','M task','8k task'};

used_neruons_3=single_neuron_all(sort_idx_3,:,:);
used_neruons_3_sort=used_neruons_3(use_idx(sort_idx_3),:,:);

for curr_idx=1:8
    nexttile
    imagesc(t_centers,[],used_neruons_3_sort(:,:,curr_idx))
    yline(sum(response_all(:,3)),'Color',[0 1 0],'LineWidth',1)
    colormap(ap.colormap('BWR'));
    clim(clim_value);
    xlabel('time (s)')
    title(titles{curr_idx})
end
used_neruons_only_mean=permute(mean(used_neruons_3_sort(1:sum(response_all(:,3)),:,:),1,'omitmissing'),[2 3 1]);
used_neruons_3_only_error=permute(std(used_neruons_3_sort(1:sum(response_all(:,3)),:,:),0,1,'omitmissing')/sqrt(sum(response_all(:,3))),[2 3 1]);

nexttile
hold on
ap.errorfill(t_bins,used_neruons_only_mean(:,3),used_neruons_3_only_error(:,3),[0 0 1],0.1 ,0.5)
ap.errorfill(t_bins,used_neruons_only_mean(:,5),used_neruons_3_only_error(:,5),[1 0 0],0.1 ,0.5)


used_neruons_5=single_neuron_all(sort_idx_5,:,:);
used_neruons_5_sort=used_neruons_5(use_idx(sort_idx_5),:,:);
for curr_idx=1:8
    nexttile
    imagesc(t_centers,[],used_neruons_5_sort(:,:,curr_idx))

    colormap(ap.colormap('BWR'));
    clim(clim_value);
    xlabel('time (s)')
    yline(sum(response_all(:,5)),'Color',[0 1 0],'LineWidth',1)
end

used_neruons_5_only_mean=permute(mean(used_neruons_5_sort(1:sum(response_all(:,5)),:,:),1,'omitmissing'),[2 3 1]);
used_neruons_5_only_error=permute(std(used_neruons_5_sort(1:sum(response_all(:,5)),:,:),0,1,'omitmissing')/sqrt(sum(response_all(:,5))),[2 3 1]);
nexttile
hold on
ap.errorfill(t_bins,used_neruons_5_only_mean(:,3),used_neruons_5_only_error(:,3),[0 0 1],0.1 ,0.5)
ap.errorfill(t_bins,used_neruons_5_only_mean(:,5),used_neruons_5_only_error(:,5),[1 0 0],0.1 ,0.5)
ylim([-0.5 5])
sgtitle(title_name)
savefig (gcf,[Path 'figures\summary\responsive neurons in ' title_name]);



%% Load atlas
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

        s= scatter3(x_jitter,y_jitter,...
            cells_position{curr_probe}(responsive_neurons,2),10,colorMap,'filled')
        % s.MarkerFaceAlpha = 'flat';  % 允许每个点有不同透明度
        % s.AlphaData = 0*responsive_neurons;  % 透明度数组


        hold on

                clearvars('-except',preload_vars{:});

    end

end

%%

