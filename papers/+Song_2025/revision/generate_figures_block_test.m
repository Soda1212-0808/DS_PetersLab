%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

server_path= [plab.locations.server_path  'Lab\widefield_alignment\animal_alignment'];

surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];


t_kernels=1/surround_samplerate*[-10:30];

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


training_workflow ='stim_wheel_right_stage2';
passive_workflow = 'lcr_passive';

animals =     { 'AP030','AP032','DS030','DS031','DS029'};

wf_px_kernels_all=table;


% animals={'HA009','HA010','HA011','HA012'};
for curr_animal_idx=1:length(animals)
    animal=animals{curr_animal_idx};
    wf_px_kernels_all.animal(curr_animal_idx)={animal};

    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);


    recordings_passive = plab.find_recordings(animal,[],passive_workflow);
    recordings_training = plab.find_recordings(animal,[],training_workflow);
    red_days=intersect({recordings_passive(find(cellfun(@length ,{recordings_passive.index},'UniformOutput',true)==2)).day },...
        {recordings_training(find(cellfun(@length ,{recordings_training.index},'UniformOutput',true)==2)).day });


    wf_px_kernels=table;

    for curr_day =1
        % for curr_recording =4:length(recordings2)
        fprintf('The number of files is %d This file is: %d\n', length(red_days),curr_day);
        % Load data
        rec_day = red_days{curr_day};
        wf_px_kernels.day(curr_day)={rec_day};

        recordings_task=plab.find_recordings(animal,rec_day,training_workflow);
        for curr_recording_task=1:2
            % Grab pre-load vars
            preload_vars = who;

            rec_time = recordings_task.recording{curr_recording_task};

            verbose=true;
            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;



            % process behavioral data
            stim2move{curr_recording_task}=stim_to_move;
            % Get median stim-outcome time
            if length(stimOn_times)< length([trial_events.timestamps.Outcome])
                n_trials =length(stimOn_times);
            else
                n_trials = length([trial_events.timestamps.Outcome]);
            end




            % linear regression data  线性回归后的数据
            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            % Create regressors
            real_stimOn_times=stimOn_times(1:n_trials);

            stim_regressors = histcounts(real_stimOn_times,wf_regressor_bins);


            decrement = 10;       % 每次失败减少多少
            min_components = 100;
            frame_shifts = -10:30;
            lambda=15;
            n_cur = 200;
            success = false;
            % 可选：记录捕获的错误信息以供调试
            error_messages = {};
            while ~success
                try
                    disp(['Running with n_components = ', num2str(n_cur)]);
                    [stim_kernels, predicted_signals, explained_var] = ...
                        ap.regresskernel(wf_V(1:n_cur, :), stim_regressors, -frame_shifts, lambda);


                    success = true;
                    disp('running_successfully');

                    % 如果你希望后面的任务沿用被降过的 n，更新 start_n
                    start_n = n_cur;

                catch ME
                    % 捕获错误并准备重试（降 n_cur）
                    error_messages{end+1} = ME.message; %#ok<SAGROW>
                    n_cur = n_cur - decrement;

                    if n_cur < min_components
                        % 超过可接受最小值，抛出错误并显示日志
                        disp('Errors encountered during attempts:');
                        for ii = 1:length(error_messages)
                            disp(['  Attempt ', num2str(ii), ': ', error_messages{ii}]);
                        end
                        error('n_components 过小，无法继续运行');
                    end
                    % 否则循环继续，尝试更小的 n_cur
                end

            end




            wf_px_kernels.(['task' num2str(curr_recording_task)])={stim_kernels};




            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});

        end

        recordings_passive=plab.find_recordings(animal,rec_day,passive_workflow);
        for curr_recording_passive=1:2
            % Grab pre-load vars
            preload_vars = who;

            rec_time = recordings_passive.recording{curr_recording_passive};

            verbose=true;
            load_parts = struct;
            load_parts.behavior = true;
            load_parts.widefield_master = true;
            load_parts.widefield = true;
            ap.load_recording;

            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];

            align_category_all = vertcat(trial_events.values.TrialStimX);

            % stimOn_times=stimOn_times(1:length(stimOff_times));
            % align_category_all=align_category_all(1:length(stimOn_times));

            stimOn_times=stimOn_times(1:n_trials*3-3);
            align_category_all=align_category_all(1:n_trials*3-3);


            stim_regressor = repmat({zeros(length(wf_t),1)}, length(unique(align_category_all)), 1);
            stim_regressor= arrayfun(@(a)  histcounts(stimOn_times(align_category_all == a),wf_regressor_bins)',...
                unique(align_category_all),'UniformOutput',false  );

            gap_1=stimOn_times(1:length(stimOn_times))-0.5;
            gap_2=[stimOn_times(2:length(stimOn_times))-0.1 ;stimOff_times(length(stimOn_times))+0.5];

            wf_t_only_passive= repmat({false(length(wf_t),1)}, length(unique(align_category_all)), 1);
            wf_t_only_passive=arrayfun(@(a) interp1([gap_1(align_category_all==a);gap_2(align_category_all==a)],...
                [ones(sum(align_category_all==a),1);....
                zeros(sum(align_category_all==a),1)],...
                wf_t,'previous')==1, unique(align_category_all),'UniformOutput',false);


            n_components = 400;
            frame_shifts = -10:30;
            lambda = 15;
            % [kernels,predicted_signals,explained_var] = ...
            %     ap.regresskernel(wf_V(1:n_components,:),stim_regressors,-frame_shifts,lambda);


            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    % [kernels,predicted_signals,explained_var] = ...
                    %     ap.regresskernel(wf_V(1:n_components,:),stim_regressors,-frame_shifts,lambda);

                    [stim_kernels,predicted_signals,explained_var] = ...
                        cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
                        wf_t_only_passive, stim_regressor ,'UniformOutput',false );



                    success = true; % 如果没有报错，则成功运行
                catch ME
                    disp(['Error: ', ME.message]);
                    n_components = n_components - 1; % 变量 a 递减
                    if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
                        error('n_components 过小，无法继续运行');
                    end
                end
            end

            disp('running successfully');



            wf_px_kernels.(['passive' num2str(curr_recording_passive)])={cat(3,stim_kernels{:})};




            % Clear vars except pre-load for next loop
            clearvars('-except',preload_vars{:});

        end





        ap.print_progress_fraction(curr_recording_task,2);


    end

    wf_px_kernels_all.wf_px_kernels(curr_animal_idx)={wf_px_kernels};

end
% plab.locations.server_path
 save(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\wf_block_test') ,'wf_px_kernels_all','-v7.3')


%%

 load(fullfile(plab.locations.server_path,'Lab\Papers\Song_2025\data\revision\wf_block_test.mat') )

U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');


temp_image_max=cell(length(animals),1);
temp_plot_tace=cell(length(animals),1);
for curr_animal=1:length(animals)

    temp_image{1}= feval(@(v) v{1} ,cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),...
        feval(@(c) c{1}.task1,wf_px_kernels_all.wf_px_kernels(curr_animal)),'UniformOutput',false));
    temp_image{3}= feval(@(v) v{1} ,cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),...
        feval(@(c) c{1}.task2,wf_px_kernels_all.wf_px_kernels(curr_animal)),'UniformOutput',false));
    temp_image{2}= feval(@(v) v{1} ,cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x(:,:,3)),...
        feval(@(c) c{1}.passive1,wf_px_kernels_all.wf_px_kernels(curr_animal)),'UniformOutput',false));
    temp_image{4}= feval(@(v) v{1} ,cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x(:,:,3)),...
        feval(@(c) c{1}.passive2,wf_px_kernels_all.wf_px_kernels(curr_animal)),'UniformOutput',false));

    temp_image_max{curr_animal}= feval(@(x)permute(max(x(:,:,t_kernels>0 & t_kernels<0.2,:),[],3),[1,2,4,3]),cat(4,temp_image{:}));
    temp_plot_tace{curr_animal}= ds.make_each_roi(cat(4,temp_image{:}), length(t_kernels),roi1);

 
end

figure;
for curr_image=1:4
    nexttile
    imagesc( feval(@(c) c(:,:,curr_image),  nanmean(cat(4,temp_image_max{:}),4) ));
    axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(0.0003 .* [ 0, 1]);
    colormap( ap.colormap('WG' ));


end
plot_trace_mean = feval(@(c) nanmean(c,4 ),cat(4,temp_plot_tace{:}));
plot_trace_error = feval(@(c) std(c,0,4,'omitmissing' )./ sqrt(size(c,4)),cat(4,temp_plot_tace{:}));

plot_max_mean=feval(@(c) permute(nanmean(max(c(:,t_kernels>0 & t_kernels<0.2,:,:),[],2),4),[1,3,2]),cat(4,temp_plot_tace{:}))
plot_max_error=feval(@(c) permute(std(max(c(:,t_kernels>0 & t_kernels<0.2,:,:),[],2),0,4,'omitmissing')./ sqrt(size(c,4)),[1,3,2]),cat(4,temp_plot_tace{:}))

colors={[1 0 0],[0 0 0],[1 0.5 0.5],[0.5 0.5 0.5]}

for curr_roi=[1 7]
nexttile
hold on
arrayfun(@(idx) ap.errorfill(t_kernels,plot_trace_mean(curr_roi,:,idx),plot_trace_error(curr_roi,:,idx),colors{idx}),1:4,'UniformOutput',false)
ylim(0.0004*[-0.2 1])
xlim([-0.1 0.5])
end

nexttile
hold on
for curr_roi=[1 7]
ap.errorfill(1:4,plot_max_mean(curr_roi,:),plot_max_error(curr_roi,:))

end
ylim(0.0004*[-0.2 1])
xlim([1 4])



    % save([Path 'task\' animal '_task.mat' ],'workflow_type','workflow_type_name',...
    %     'workflow_type_name_merge','wf_px_task',...
    %     'wf_px_task_kernels','wf_px_task_kernels_encode','workflow_day', '-v7.3')
