
animal='DS010';
rec_day='2024-07-19';
workflows={'stim_wheel_right_stage2','lcr_passive'};
stim_regressors=cell(2,1);
wf_t_only_task=cell(2,1);
wf_V_temp=cell(2,1);
for curr_workflow=1:2
    recording=plab.find_recordings(animal,rec_day,workflows{curr_workflow});
    rec_time=recording.recording{1};
    verbose=true;
    ap.load_recording
        wf_V_temp{curr_workflow}=wf_V;

    switch curr_workflow
        case 1
            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            stim_regressors{curr_workflow}=  histcounts(stim_move_time,wf_regressor_bins)
            temp_1= {trial_events.timestamps(1:n_trials).QuiescenceReset} ;
            temp_2=[trial_events.timestamps(1:n_trials).QuiescenceStart] ;
            temp_2(~cellfun(@isempty,temp_1))=cellfun(@(x)  x(end),  temp_1(~cellfun(@isempty,temp_1)),'UniformOutput',true);
            gap_1=seconds(temp_2-trial_events.timestamps(1).StimOn (1))'+photodiode_on_times(1);
            gap_2=stimOn_times(1:n_trials)+stim_to_outcome(1:n_trials);
            wf_t_only_task{curr_workflow}=interp1([gap_1;gap_2],...
                [ones(n_trials,1);....
                zeros(n_trials,1)],...
                wf_t,'previous')==1;
            wheel_move_time=interp1(timelite.timestamps,single(wheel_move),wf_t,'previous');
            wf_t_only_task{curr_workflow}(wf_t_only_task{curr_workflow}==0)= wheel_move_time(wf_t_only_task{curr_workflow}==0)==0
        case 2
            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            stim_regressors{curr_workflow}=  histcounts([],wf_regressor_bins);
            wheel_move_time=interp1(timelite.timestamps,single(wheel_move),wf_t,'previous');
            wf_t_only_task{curr_workflow}=~wheel_move_time;
    end
end



wf_t_all=cat(1,wf_t_only_task{:});
stim_regressors_all=cat(2,stim_regressors{:});
wf_V_all=cat(2,wf_V_temp{:});

n_components = 200;
frame_shifts = -10:30;
lambda = 15;

surround_samplerate = 35;
t_kernels=1/surround_samplerate*[-10:30];

success = false; % 标记变量，判断是否成功运行
while ~success
    try

        disp(['Running with n_components = ', num2str(n_components)]);
        [stim_kernels,predicted_signals,explained_var] = ...
             ap.regresskernel(wf_V_all(1:n_components,find(wf_t_all==1)),...
             stim_regressors_all(find(wf_t_all==1)),-frame_shifts,lambda)

        success = true; % 如果没有报错，则成功运行
    catch ME
        disp(['Error: ', ME.message]);
        n_components = n_components - 10; % 变量 a 递减
        if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
            error('n_components 过小，无法继续运行');
        end
    end
end


kernels_px = cellfun(@(kernels) plab.wf.svd2px(wf_U(:,:,1:size(kernels,1)),kernels),{stim_kernels},'UniformOutput',false);


ap.imscroll(kernels_px{1},t_kernels);
% clim(max(abs(clim)).*[-1,1]);
clim(0.0003.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image
 ap.wf_draw('ccf','k');





