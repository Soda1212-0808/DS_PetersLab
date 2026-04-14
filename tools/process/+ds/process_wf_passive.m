% which workflow
    fprintf('%s...\n', ['start processing widefield data in ' bonsai_workflow ]);


%%


if ~exist('wf_passive_prcoess_parts','var')
    wf_passive_prcoess_parts = struct('averaged_data', true, 'kernels', true);
else
    if ~isfield(wf_passive_prcoess_parts,'averaged_data'),     wf_passive_prcoess_parts.averaged_data = false; end
    if ~isfield(wf_passive_prcoess_parts,'kernels'),     wf_passive_prcoess_parts.kernels = false; end

end




passive_data=struct;

switch bonsai_workflow
    case {'lcr_passive','lcr_passive_size60','r_passive_contrast','lcr_passive_grating_size40','lcr_passive_contrast25','r_passive_contrast_up_to25'}
        align_category_all = vertcat(trial_events.values.TrialStimX);
    case {'hml_passive_audio','hml_passive_audio_mixed',...
            'm_8k_passive_audio_volume','hml_passive_audio_earphone_freq','hml_passive_audio_earphone'}
        align_category_all = vertcat(trial_events.values.StimFrequence);
    case 'r_passive_natural_image'
        align_category_all = vertcat(trial_events.values.PictureID);
    case{ 'hml_passive_audio_earphone_balance','hml_passive_audio_earphone_balance_only'}
        align_category_all = vertcat(trial_events.values.trialID);
end

min_idx=min([length(stimOff_times),length(stimOn_times),length(align_category_all)]);

% 选取可使用数据  choose usable data
stimOn_times=stimOn_times(1:min_idx);
align_category_all=align_category_all(1:min_idx);

% Get quiescent trials and stim onsets/ids
stim_window1 = [0,0.3];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
    1:length(stimOn_times))';

align_times = stimOn_times(quiescent_trials);
align_category = align_category_all(quiescent_trials);


%% wf_V raw data
if wf_passive_prcoess_parts.averaged_data

% Align to stim onset
surround_window = [-0.5,1];
surround_samplerate = 35;
t_passive = surround_window(1):1/surround_samplerate:surround_window(2);
peri_event_t = reshape(align_times,[],1) + reshape(t_passive,1,[]);

aligned_v = reshape(interp1(wf_t,wf_V',peri_event_t,'previous'), ...
    length(align_times),length(t_passive),[]);
align_id = findgroups(align_category);
% 确定 align_id 中的唯一值
unique_values = unique(align_id);
% 初始化一个空的结果数组
aligned_v_avg1 = zeros( numel(unique_values),size(aligned_v, 2), size(aligned_v, 3));
% 遍历每个唯一的值，对每个值进行处理
for i = 1:numel(unique_values)
    idx = align_id == unique_values(i);
    % 检查当前组的大小
    if sum(idx) > 1
        % 如果当前组的大小大于1，则计算平均值
        aligned_v_avg1(i,:,:) = nanmean(aligned_v(find(idx),:,:), 1);
    else
        % 如果当前组的大小等于1，则将对应位置设置为 NaN
        aligned_v_avg1(i,:,:) = aligned_v(find(idx),:,:);
    end
end

% 使用 permute 对结果进行重新排列
aligned_v_avg = permute(aligned_v_avg1, [3, 2, 1]);

% aligned_v_avg = permute(splitapply(@nanmean,aligned_v,align_id),[3,2,1]);
passive_data.wf_aligned_averged = aligned_v_avg - nanmean(aligned_v_avg(:,t_passive < 0,:),2);

%%all_trials
peri_event_t_all= reshape(stimOn_times,[],1) + reshape(t_passive,1,[]);
aligned_v_all = permute((reshape(interp1(wf_t,wf_V',peri_event_t_all,'previous'), length(stimOn_times),length(t_passive),[])), [3, 2, 1]);
passive_data.wf_aligned_all = aligned_v_all-nanmean(aligned_v_all(:,t_passive < 0,:),2);
end



%%  decoding kernels

if wf_passive_prcoess_parts.kernels

    wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];

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

    success = false; % 标记变量，判断是否成功运行
    while ~success
        try
            disp(['Running with n_components = ', num2str(n_components)]);

            % [kernels_decoding,predicted_signals_decoding,explained_var_decoding] = ...
            %     cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
            %     wf_t_only_passive, stim_regressor ,'UniformOutput',false );

            passive_data.kernels_decoding = ...
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


    %% encoding kernels

    wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];

    % old one do not use any more
    % Create regressors in the passive task
    stim_window2 = [0.1,0.8];

    non_quiescent_trials = arrayfun(@(x) any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
        1:length(stimOn_times))';

    stim_drive_trials = arrayfun(@(x) any(wheel_move(...
        timelite.timestamps > stimOn_times(x)+stim_window2(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window2(2)))& ...
        ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
        1:length(stimOn_times));


    move_regressor_random = histcounts(stimOn_times(non_quiescent_trials ),wf_regressor_bins);
    stim_drive_time=arrayfun(@(x) timelite.timestamps(find(wheel_move(find(timelite.timestamps > x, 1):end) == 1, 1) + find(timelite.timestamps > x, 1) - 1),stimOn_times(stim_drive_trials));
    move_regressor_stim_drive = histcounts(stim_drive_time,wf_regressor_bins);

    regressors={permute(cat(2,stim_regressor{:}),[2,1]);move_regressor_random;move_regressor_stim_drive};
    t_shifts = {[-10:30];[-10:30];[-10:30]};
    % Set cross validation (not necessary if just looking at kernels)
    cvfold = 5;
    % Do regression
    passive_data.kernels_encoding = ...
        ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

    % [kernels_encoding,predicted_signals_encoding,explained_var_encoding,predicted_signals_reduced_encoding] = ...
    %     ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);
end

