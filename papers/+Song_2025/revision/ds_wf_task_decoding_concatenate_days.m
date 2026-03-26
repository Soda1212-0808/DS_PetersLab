%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);





% variable definition


animals =     { 'DS007','DS010','AP019','AP021','DS011','AP022'...
    'DS000','DS004','DS014','DS015','DS016'};
group_type={'VA','VA','VA','VA','VA','VA','AV','AV','AV','AV','AV'};

training_workflow =...
    ['stim_wheel_right_stage1$|' ...
    'stim_wheel_right_stage2$|' ...
    'stim_wheel_right_stage1_opacity$|' ...
    'stim_wheel_right_stage2_opacity$|' ...
    'stim_wheel_right_stage1_angle$|' ...
    'stim_wheel_right_stage2_angle$|' ...
    'stim_wheel_right_stage2_angle_size60$|' ...
    'stim_wheel_right_stage1_size_up$|' ...
    'stim_wheel_right_stage2_size_up$|' ...
    'stim_wheel_right_stage1_audio_volume$|'...
    'stim_wheel_right_stage2_audio_volume$|' ...
    'stim_wheel_right_stage1_audio_frequency$|' ...
    'stim_wheel_right_stage2_audio_frequency$|' ];

workflow_name_map = containers.Map( ...
    {'stim_wheel_right_stage1_audio_volume', ...
    'stim_wheel_right_stage2_audio_volume', ...
    'stim_wheel_right_stage1', ...
    'stim_wheel_right_stage2', ...
    'stim_wheel_right_stage1_size_up', ...
    'stim_wheel_right_stage2_size_up', ...
    'stim_wheel_right_stage1_opacity', ...
    'stim_wheel_right_stage2_opacity',...
    'stim_wheel_right_stage1_audio_frequency',...
    'stim_wheel_right_stage2_audio_frequency',...
    'stim_wheel_right_stage2_mixed_VA',...
    'stim_wheel_right_frequency_stage2_mixed_VA'}, ...
    {'audio volume', 'audio volume', ...
    'visual position', 'visual position', ...
    'visual size up', 'visual size up', ...
    'visual opacity', 'visual opacity',...
    'audio frequency','audio frequency',...
    'mixed VA','mixed VA'} );




wf_stim_kernels_concat=table;
wf_stim_kernels_concat.name=animals';
wf_stim_kernels_concat.group=group_type';

% animals={'HA009','HA010','HA011','HA012'};
for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);

    passive_workflow = 'lcr_passive';
    recordings_passive = plab.find_recordings(animal,[],passive_workflow);

    recordings_training = plab.find_recordings(animal,[],training_workflow);

    recordings2 = recordings_training( ...
        cellfun(@any,{recordings_training.widefield}) & ...
        ~[recordings_training.ephys] & ...
        ismember({recordings_training.day},{recordings_passive.day}));


    curr_group_type=group_type{curr_animal_idx};
    switch curr_group_type
        case {'VA'}
            recordings2=recordings2(find(~contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
        case {'AV'}
            recordings2=recordings2(find(contains(cellfun(@(c) c{1}, {recordings2.workflow}, 'UniformOutput', false),'audio'),5,'last'));
    end


    %%是否存在保存过之前的数据的文

    wf_V_all=cell(length(recordings2),1);
    wf_t_only_task_all=cell(length(recordings2),1);
    stim_regressors_all=cell(length(recordings2),1);
    stim_to_move_all=cell(length(recordings2),1);
    stim_to_move_idx_all=cell(length(recordings2),1);
    frac_velocity=cell(length(recordings2),1);
    for curr_recording =1:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(recordings2),curr_recording);

        % Grab pre-load vars
        preload_vars = who;
        % Load data
        rec_day = recordings2(curr_recording).day;

        [~,index_real]=max( cellfun(@(rt) ...
            numel(load( ...
            plab.locations.filename('server', animal, rec_day, rt, 'timelite.mat'), ...
            'timestamps').timestamps), ...
            recordings2(curr_recording).recording));

        rec_time = recordings2(curr_recording).recording{index_real};

        verbose=true;
        load_parts = struct;
        load_parts.behavior = true;
        load_parts.widefield_master = true;
        load_parts.widefield = true;
        ap.load_recording;



        if length(stimOn_times)< length([trial_events.timestamps.Outcome])
            n_trials =length(stimOn_times);
        else
            n_trials = length([trial_events.timestamps.Outcome]);
        end

        % process behavioral data
        real_stimOn_times=stimOn_times(1:n_trials);
        real_stim_to_move=stim_to_move(1:n_trials);
        edges = [-Inf, 0, 0.1, 0.2, 0.3, Inf];
        stim_to_move_idx = discretize(real_stim_to_move, edges);
        stim_to_move_all{curr_recording}=real_stim_to_move;
        stim_to_move_idx_all{curr_recording}=stim_to_move_idx;

        % wheel_velocity
        pull_times = real_stimOn_times(1:n_trials) + surround_time_points;
        event_aligned_wheel_vel = interp1(timelite.timestamps, ...
            wheel_velocity,pull_times);
        frac_velocity{curr_recording} = event_aligned_wheel_vel;



        % linear regression data  线性回归后的数据
        wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
        % Create regressors

        stim_regressors = repmat({zeros(length(wf_t),1)}, 5, 1);
        stim_regressors(unique(stim_to_move_idx))= arrayfun(@(a)  histcounts(real_stimOn_times(stim_to_move_idx==a),wf_regressor_bins)',...
            unique(stim_to_move_idx),'UniformOutput',false  );


        gap_1=seconds([trial_events.timestamps(1:n_trials).ITIStart ] -trial_events.timestamps(1).StimOn (1))'+photodiode_on_times(1);
        gap_2=stimOn_times(1:n_trials)+stim_to_outcome(1:n_trials);

        wf_t_only_task= repmat({false(length(wf_t),1)}, 5, 1);
        wf_t_only_task(unique(stim_to_move_idx))=arrayfun(@(a) interp1([gap_1(stim_to_move_idx==a);gap_2(stim_to_move_idx==a)],...
            [ones(sum(stim_to_move_idx==a),1);....
            zeros(sum(stim_to_move_idx==a),1)],...
            wf_t,'previous')==1, unique(stim_to_move_idx),'UniformOutput',false);

        wf_V_all{curr_recording}=wf_V;
        wf_t_only_task_all{curr_recording}=wf_t_only_task;
        stim_regressors_all{curr_recording}=stim_regressors;

        % Clear vars except pre-load for next loop
        clearvars('-except',preload_vars{:});
        ap.print_progress_fraction(curr_recording,length(recordings2));
        fprintf('\n');

    end

    temp_idx=feval(@(c)   cat(2,c{:}),...
        cellfun(@(a) cellfun(@(b)  sum(b),a,'UniformOutput',true ),stim_regressors_all,'UniformOutput',false));

    regressor_concat=cell(5,1);
    wf_t_concat=cell(5,1);
    wf_V_all_concat=cell(5,1);
    stim_to_move_concat=cell(5,1);
    wheel_velocity_concat=cell(5,1);
    for curr_state=1:5
        accum_idx = find(cumsum(temp_idx(curr_state,:)) > 100, 1, 'first');

        if isempty(accum_idx)
            accum_idx=length(stim_regressors_all);
        end
        regressor_concat{curr_state}=feval(@(c)  cat(1,c{:}),cellfun(@(x) x{curr_state} ,stim_regressors_all(1:accum_idx),'uni',false   ) );
        wf_t_concat{curr_state}=  feval(@(c)  cat(1,c{:}),cellfun(@(x) x{curr_state} ,wf_t_only_task_all(1:accum_idx),'uni',false   ) );
        wf_V_all_concat{curr_state}=cat(2,wf_V_all{1:accum_idx});

        stim_to_move_concat{curr_state}=feval(@(a,b)  a(b==curr_state),  ...
            cat(1,stim_to_move_all{1:accum_idx}) ,cat(1,stim_to_move_idx_all{1:accum_idx}) );

        wheel_velocity_concat{curr_state}=feval(@(a,b)  a(b==curr_state,:),  ...
            cat(1,frac_velocity{1:accum_idx}) ,cat(1,stim_to_move_idx_all{1:accum_idx}) );

    end

    n_components = 200;
    frame_shifts = -10:30;
    lambda = 15;

    % [stim_kernels,predicted_signals,explained_var] = ...
    %     cellfun(@(x,y) ap.regresskernel(wf_V_all_concat(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
    %     wf_t_concat, regressor_concat ,'UniformOutput',false );

    stim_kernels=cell(length(wf_t_concat),1);
    for curr_stage=1:length(wf_t_concat)

        stim_kernels{curr_stage}= ap.regresskernel(wf_V_all_concat{curr_stage}(1:n_components,find(wf_t_concat{curr_stage}==1)),...
            regressor_concat{curr_stage}(find(wf_t_concat{curr_stage}==1))',-frame_shifts,lambda);

    end

    wf_stim_kernels_concat.wf_kernels(curr_animal_idx)={stim_kernels};
    wf_stim_kernels_concat.stim_to_move(curr_animal_idx)={stim_to_move_concat};
    wf_stim_kernels_concat.wheel_velocity(curr_animal_idx)={wheel_velocity_concat};



end


%     tem_image_passive=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),stim_kernels,'UniformOutput',false);
% 
% ap.imscroll(cat(4, tem_image_passive{:}))
% axis image off
% clim( 0.0003*[-1,1]);
% ap.wf_draw('ccf',[0.5 0.5 0.5]);
% colormap( ap.colormap(['BWR']));
% 

save_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data';
save(fullfile(save_path,'revision','wf_task_decoding_concatnate.mat'),'wf_stim_kernels_concat','-v7.3');

%%
clear all

Path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025';
load(fullfile(Path,'data','revision','wf_task_decoding_concatnate.mat'));
load(fullfile(Path,'data\General_information\roi.mat'))

U_master = plab.wf.load_master_U;


local_data_path= 'D:\Data process\project_cross_model\wf_data\';

surround_samplerate = 35;
t_kernels=1/surround_samplerate*[-10:30];

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

colors = [
    0.23 0.30 0.75
    0.40 0.50 0.85
    0.60 0.70 0.90
    0.80 0.85 0.95
    0.90 0.93 0.98
    ];




groups={'VA','AV'};
passive_workflows={'lcr_passive','hml_passive_audio'};
passive_id={3,2};
for curr_group=1
    animals_in_groups=wf_stim_kernels_concat.name(ismember(wf_stim_kernels_concat.group,groups{curr_group}))

    for curr_animal=1:length(animals_in_groups)
        animal=animals_in_groups{curr_animal};
        temp_passive_data=load(fullfile (local_data_path,passive_workflows{curr_group},[animal '_' passive_workflows{curr_group},'.mat']));

        temp_passive_wf= nanmean(cat(4,temp_passive_data.wf_px_kernels{find(temp_passive_data.workflow_type==curr_group,5,'last')}),4);

        wf_stim_kernels_concat.wf_passive_kernels(find(contains(wf_stim_kernels_concat.name,animal)))={temp_passive_wf};
    end

    temp_wf_passive=wf_stim_kernels_concat.wf_passive_kernels(ismember(wf_stim_kernels_concat.group,groups{curr_group}));
    tem_image_passive=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),temp_wf_passive,'UniformOutput',false);
    tem_trace_passive=cellfun(@(x)   ds.make_each_roi(x,t_kernels,roi1),tem_image_passive,'UniformOutput',false);
    tem_trace_passive_mean=nanmean(cat(4,tem_trace_passive{:}),4);
    tem_trace_passive_error=std(cat(4,tem_trace_passive{:}),0,4,'omitmissing')./sqrt(length(tem_trace_passive));
    temp_wf=wf_stim_kernels_concat.wf_kernels(ismember(wf_stim_kernels_concat.group,groups{curr_group}));
    tem_image= feval(@(c) cat(2,c{:}),  cellfun(@(a)   cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),a,'UniformOutput',false)...
        ,temp_wf,'UniformOutput',false));
    temp_stim2move=feval(@(c) cat(2,c{:}), wf_stim_kernels_concat.stim_to_move(ismember(wf_stim_kernels_concat.group,groups{curr_group})));
    temp_stim2move_mean= nanmean(cellfun(@mean,temp_stim2move,'UniformOutput',true),2);
    temp_stim2move_error= std(cellfun(@mean,temp_stim2move,'UniformOutput',true),0,2)./sqrt(size(temp_stim2move,2));
    temp_vel=feval(@(c) cat(2,c{:}), wf_stim_kernels_concat.wheel_velocity(ismember(wf_stim_kernels_concat.group,groups{curr_group})));
    temp_vel2= feval(@(c)  arrayfun(@(id)  cat(2,c{id,:}) ,1:5,'uni',false),cellfun(@(x)  median(x,1,'omitmissing')',temp_vel,'UniformOutput',false));
    temp_vel_mean=cellfun(@(x)  median(x,2,'omitmissing'),temp_vel2,'UniformOutput',false  );
    temp_vel_error=cellfun(@(x)  std(x,0,2)./sqrt(size(x,2)),temp_vel2,'UniformOutput',false  );

    % % tem_image_nanmean=feval(@(c) cat(4,c{:}), arrayfun(@(id)  nanmean(cat(4,tem_image{id,:}),4)         ,1:5,'UniformOutput',false));
    % ap.imscroll(tem_image{1,1},t_kernels)
    % axis image off
    % clim( 0.0003*[-1,1]);
    % ap.wf_draw('ccf',[0.5 0.5 0.5]);
    % colormap( ap.colormap(['BWR']));

    tem_trace=cellfun(@(x)   ds.make_each_roi(x,t_kernels,roi1),tem_image,'UniformOutput',false);
    tem_trace_mean=arrayfun(@(id)    median(cat(3,tem_trace{id,:}),3,'omitmissing')  ,1:5,'UniformOutput',false);
    tem_trace_error=arrayfun(@(id)    std(cat(3,tem_trace{id,:}),0,3)./sqrt(size(tem_trace,2))  ,1:5,'UniformOutput',false);
    tem_trace_peak=arrayfun(@(id)   permute(max(cat(3,tem_trace{id,:}),[],2),[3,1,2])  ,1:5,'UniformOutput',false);
    tem_trace_peak_error=arrayfun(@(id)    std(max(cat(3,tem_trace{id,:}),[],2),0,3)./sqrt(size(tem_trace,2))  ,1:5,'UniformOutput',false);

    figure;
    tiledlayout(11,1,'Padding','tight','TileSpacing','none','TileIndexing','columnmajor')
    for curr_state=1:5
        nexttile
        % ap.errorfill(t_kernels,tem_trace_mean{curr_state}(1,:),tem_trace_error{curr_state}(1,:),colors(curr_state,:),0.5)
        ap.errorfill(t_kernels,tem_trace_mean{curr_state}(1,:),tem_trace_error{curr_state}(1,:),[ 0.75 0.25 0.23],0.5)

        xlim([-0.1 1])
        ylim([-0.7 4]*0.0001)
        xline(0,'.k')
        xline(temp_stim2move_mean(curr_state),'.r')
        axis off

        nexttile
        % ap.errorfill(surround_time_points,temp_vel_mean{curr_state},temp_vel_error{curr_state},colors(curr_state,:),0.5)
        ap.errorfill(surround_time_points,temp_vel_mean{curr_state},temp_vel_error{curr_state},[ 0.25 0.25 0.73],0.5)

        ylim([-5000 2000])
        xlim([-0.1 1])
        xline(temp_stim2move_mean(curr_state),'.r')

        xline(0,'.k')
        axis off



    end

    nexttile

    ap.errorfill(t_kernels,tem_trace_passive_mean(1,:,passive_id{curr_group}),tem_trace_passive_error(1,:,passive_id{curr_group}),[0.5 0.5 0.5],0.5)
    xlim([-0.1 1])
    ylim([-0.7 4]*0.0001)
    xline(0)
    axis off



    temp_passive_peak=permute(max(cat(4,tem_trace_passive{:}),[],2),[4,1,3,2]);
    tem_trace_peak_mpfc= [cellfun(@(x) x(:,1) , tem_trace_peak,'uni',false) {temp_passive_peak(:,1,passive_id{curr_group})}];



    % figure
    % ds.make_bar_plot(tem_trace_peak_mpfc)

    kernels_plot_mean=nanmean(cat(2,tem_trace_peak_mpfc{:}),1)
    kernels_plor_error=std(cat(2,tem_trace_peak_mpfc{:}),0,1,'omitmissing')./sqrt(length(tem_trace_peak_mpfc{1}));




    vel_plot=cellfun(@(x) abs(min(x,[],1)), temp_vel2,'UniformOutput',false     );
    vel_plot_mean=cellfun(@(x)  nanmean(x),vel_plot,'UniformOutput',true)
    vel_plor_error=cellfun(@(x)  std(x)./sqrt(length(x)),vel_plot,'UniformOutput',true)

    figure;
    nexttile
    ap.errorfill(1:6,kernels_plot_mean,kernels_plor_error,[0.5 0.5 0.5],0.5)
    ylim([0 0.0003])
    xlim([1 6])

    nexttile
    ap.errorfill(1:5,vel_plot_mean,vel_plor_error,[0.5 0.5 0.5],0.5)
    xlim([1 6])




end

% colors = [
%     0.75 0.25 0.23
%     0.85 0.45 0.40
%     0.90 0.65 0.60
%     0.95 0.80 0.78
%     0.98 0.90 0.88
% ];