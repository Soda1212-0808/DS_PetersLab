
clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\ephys\';

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}
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


load([Path 'mat_data\ephys_all_data.mat'])

strcut_idx=cellfun(@(x) cellfun(@(y) strcmp('struct', class(y))  ,x,'UniformOutput',true) ,animals_all_celltypes,'UniformOutput',false)  

neuron_type={'tan','fsi','msn'}
for curr_type=1:3
animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS006','DS013',...
    'DS000','DS004','DS014','DS015','DS016'};

neurons_tan0=cellfun(@(x,y,z) cellfun(@(s,q) find(s.(neuron_type{curr_type})==1&sum(q(:,[3 5 7 8]), 2) > 0) ,x(z),y(z),'UniformOutput',false) ,...
    animals_all_celltypes,animals_all_event_response,strcut_idx,'UniformOutput',false)  ;

neurons_tan=cellfun(@(x,y,z) cellfun(@(a1,a2)  a1(a2) ,x(y),z,'UniformOutput',false),...
    animals_all_cell_sorted,strcut_idx,neurons_tan0,'UniformOutput',false);


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

    groups={'VA','AV'};
for curr_group=1:2
    if curr_group==1
    which_days=anterior_learned_idx_VA{curr_animal};
    else
      which_days=anterior_learned_idx_AV{curr_animal};
    end

    for curr_day=which_days
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

        for curr_neuron=neurons_tan{curr_animal}{curr_day}
        
            plot_units=[curr_neuron];

        % Set raster time bins
        raster_window = [-0.2,0.7];
        psth_bin_size = 0.001;
        raster_t_bins = raster_window(1):psth_bin_size:raster_window(2);
        raster_t = raster_t_bins(1:end-1) + diff(raster_t_bins)./2;

        h = gobjects(length(plot_units),1);
        for curr_unit = 1:length(plot_units)
            figure('color','w','name',sprintf('Unit %d',plot_units(curr_unit)),'Position',[50 50 400 550]);
            h(curr_unit) = tiledlayout(5,2);
        end

        for workflow_idx = 1:3

            switch workflow_idx
                case 1
                    rec = plab.find_recordings(animal,rec_day,'*wheel*');
                    rec_time = rec.recording{end};
                case 2
                    rec = plab.find_recordings(animal,rec_day,'*lcr*');
                    rec_time = rec.recording{end};
                case 3
                    rec = plab.find_recordings(animal,rec_day,'*hml*');
                    rec_time = rec.recording{end};
            end
            verbose = true;
            ap.load_recording;

            for curr_modality = 1:2

                % Get alignment times to use
                use_align = [];
                if contains(bonsai_workflow,'lcr') && curr_modality == 1
                    % use_align{1} = stimOn_times([trial_events.values(1:n_trials).TrialStimX] == 90);
                    % use_align{2} = stimOn_times([trial_events.values(1:n_trials).TrialStimX] == -90);
                    % use_align{3} = stimOn_times([trial_events.values(1:n_trials).TrialStimX] == 0);
                stim_vals = [90, -90, 0];
                    use_align = arrayfun(@(x) stimOn_times([trial_events.values(1:n_trials).TrialStimX] == x), ...
                     stim_vals, 'UniformOutput', false);

                elseif contains(bonsai_workflow,'hml') && curr_modality == 2
                    % use_align = stimOn_times([trial_events.values(1:n_trials).StimFrequence] == 8000);
                     stim_vals = [8000, 4000, 12000];
                    use_align = arrayfun(@(x) stimOn_times([trial_events.values(1:n_trials).StimFrequence] == x), ...
                     stim_vals, 'UniformOutput', false);
                elseif contains(bonsai_workflow,'wheel')
                    use_align = {stimOn_times([trial_events.values(1:n_trials).TaskType] == curr_modality-1)};
                end

                % If alignment times empty (e.g. not this modality), skip
                if isempty(use_align)
                    continue
                end

                % Get psth/raster of spikes to plot
                [use_spikes,spike_groups] = ismember(spike_templates,plot_units);
                [psth,raster,raster_t] =cellfun(@(x) ap.psth(spike_times_timelite(use_spikes), ...
                    x,spike_groups(use_spikes)),use_align,'UniformOutput',false);

                % Plot PSTHs and rasters
                for curr_unit_idx = 1:length(plot_units)

                    % Plot PSTH
                    nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),1,curr_modality)); hold on;
                    switch workflow_idx
                        case 1
                            plot(raster_t{1},smoothdata(psth{1}(curr_unit_idx,:),2,'gaussian',50)','linewidth',2,'Color','r')

                        case{2,3}
                            plot(raster_t{1},smoothdata(psth{1}(curr_unit_idx,:),2,'gaussian',50)','linewidth',2,'Color',[1 0.5 0.5])
                            plot(raster_t{1},smoothdata(psth{2}(curr_unit_idx,:),2,'gaussian',50)','linewidth',2,'Color',[0.5 0.5 0.5])
                            plot(raster_t{1},smoothdata(psth{3}(curr_unit_idx,:),2,'gaussian',50)','linewidth',2,'Color',[0.8 0.8 0.8])
                    end

                    xlim(raster_window)
                      axis off
                    xline(0,'r');
                    % ylim([0 20])

                    % Plot raster
                    [raster_y,raster_x] =cellfun(@(x) find(x(:,:,curr_unit_idx)),raster,'UniformOutput',false  );
                  
                    switch workflow_idx
                        case 1
                            nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),min(workflow_idx+1,3),curr_modality)); hold on;
                            plot(raster_t{1}(raster_x{1}),raster_y{1},'.k');
                            xlim(raster_window)
                            axis off
                            line([0, 0],[0 ,max(raster_y{1})],'Color','r');
                        case {2,3}
                            nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),min(workflow_idx+1,3),curr_modality)); hold on;
                            plot(raster_t{1}(raster_x{1}),raster_y{1},'.k');
                            xlim(raster_window)
                            axis off
                            line([0, 0],[0 ,max(raster_y{1})],'Color','r');
                            nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),min(workflow_idx+1,3)+1,curr_modality)); hold on;
                            plot(raster_t{2}(raster_x{2}),raster_y{2},'.k');
                            xlim(raster_window)
                            axis off
                            line([0, 0],[0 ,max(raster_y{2})],'Color','r');
                            nexttile(h(curr_unit_idx),tilenum(h(curr_unit_idx),min(workflow_idx+1,3)+2,curr_modality)); hold on;
                            plot(raster_t{3}(raster_x{3}),raster_y{3},'.k');
                            xlim(raster_window)
                            axis off
                            line([0, 0],[0 ,max(raster_y{3})],'Color','r');
                    end


                    drawnow;

                end
            end
        end

        % Label panels and link axes
        for curr_unit = 1:length(plot_units)
            curr_h = h(curr_unit);
            title(curr_h,sprintf('%s %s %d',animal,rec_day,plot_units(curr_unit)));
            title(nexttile(curr_h,tilenum(curr_h,1,1)),'Visual');
            title(nexttile(curr_h,tilenum(curr_h,1,2)),'Auditory');
            title(nexttile(curr_h,tilenum(curr_h,2,1)),'Task');
            title(nexttile(curr_h,tilenum(curr_h,3,1)),'Passive 1+');
             title(nexttile(curr_h,tilenum(curr_h,4,1)),'Passive _');
            title(nexttile(curr_h,tilenum(curr_h,2,2)),'Task');
            title(nexttile(curr_h,tilenum(curr_h,3,2)),'Passive 1+');
             title(nexttile(curr_h,tilenum(curr_h,4,1)),'Passive -');
             title(nexttile(curr_h,tilenum(curr_h,4,2)),'Passive -');

             legend(nexttile(curr_h,tilenum(curr_h,1,1)),{'Task','','Passive 1+'},"Box","off",'Location','northoutside', 'NumColumns', 2);
             legend(nexttile(curr_h,tilenum(curr_h,1,2)),{'','','','Passive 2-','Passive 3-'},"Box","off",'Location','northoutside', 'NumColumns', 2);

              linkaxes(curr_h.Children([3:9,11 ]));
               linkaxes(curr_h.Children([10 12]));
             % ========== 保存图像 ==========
             save_folder = fullfile(Path, 'figures','unit_figures', groups{curr_group},neuron_type{curr_type});
             if ~exist(save_folder, 'dir')
                 mkdir(save_folder);
             end

             save_filename = fullfile(save_folder, sprintf('%s_%s_unit%d.png', ...
                 animal, rec_day, plot_units(curr_unit)));

             exportgraphics(curr_h, save_filename, 'Resolution', 300);
        end

        close all
        end
    end
end
end
end