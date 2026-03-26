%% Exploratory widefield analysis
clear all
animal='DS029';
% load_parts = struct;
% load_parts.behavior = true;
 % load_parts.widefield_master = true;
%     recordings= plab.find_recordings(animal,[],'stim_wheel_right_stage2_25contrast');

ap.load_recording;


%% Align widefield to event

if contains(bonsai_workflow,'passive')

    % LCR passive: align to quiescent stim onset
    stim_window = [0,0.3];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times))';

    align_times = stimOn_times(quiescent_trials);
    if isfield(trial_events.values,'TrialStimX')
        
        align_category_all = vertcat(trial_events.values.TrialStimX);
    elseif isfield(trial_events.values,'StimFrequence')
        align_category_all = vertcat(trial_events.values.StimFrequence);
    elseif isfield(trial_events.values,'trialID')
        align_category_all = vertcat(trial_events.values.trialID);
    end
    align_category = align_category_all(quiescent_trials);

    baseline_times = stimOn_times(quiescent_trials);

elseif contains(bonsai_workflow,'stim_wheel')

    % Task: align to stim/move/reward
    rewarded_trials = logical([trial_events.values.Outcome]');

    if isfield(trial_events.values,'TaskType')
        use_trials = rewarded_trials(1:n_trials) & ...
            vertcat(trial_events.values(1:n_trials).TaskType) == 1;
    else
        use_trials = true(size(stim_to_move));
        % use_trials = ap.quantile_bin(length(stim_to_move),3) == 3;
    end

    align_times = [ ...
        stimOn_times(use_trials); ...
        stim_move_time(use_trials); ...
        reward_times];
    align_category = vertcat( ...
        1*ones(sum(use_trials),1), ...
        2*ones(sum(use_trials),1), ...
        3*ones(length(reward_times),1));
    baseline_times = vertcat(...
        stimOn_times(use_trials), ...
        stimOn_times(use_trials), ...
        reward_times);

elseif contains(bonsai_workflow,'sparse_noise')

    % (sparse noise)
    px_x = 23;
    px_y = 4;
    align_times = ...
        stim_times(find( ...
        (noise_locations(px_y,px_x,1:end-1) == 128 & ...
        noise_locations(px_y,px_x,2:end) == 255) | ...
        (noise_locations(px_y,px_x,1:end-1) == 128 & ...
        noise_locations(px_y,px_x,2:end) == 0))+1);

    baseline_times = align_times;

elseif contains(bonsai_workflow,'visual')

    % Visual conditioning: stim and reward
    if isfield(trial_events.values,'TrialX')
        stim_x = vertcat(trial_events.values.TrialX);
    else
        stim_x = repmat(90,length(stimOn_times),1);
    end
    align_times = stimOn_times(1:n_trials);
    align_category = stim_x(1:n_trials);
    baseline_times = align_times;

%     % (new: just one stim)
%     align_times = stimOn_times;
%     align_category = ones(size(align_times));
%     baseline_times = stimOn_times;

end

surround_window = [-0.5,1];
baseline_window = [-0.5,-0.1];

surround_samplerate = 35;

t_kernels = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);

peri_event_t = reshape(align_times,[],1) + reshape(t_kernels,1,[]);
baseline_event_t = reshape(baseline_times,[],1) + reshape(baseline_t,1,[]);

use_U = wf_U;
use_V = wf_V;
use_wf_t = wf_t;

aligned_v = reshape(interp1(use_wf_t,use_V',peri_event_t,'previous'), ...
    length(align_times),length(t_kernels),[]);
aligned_baseline_v = nanmean(reshape(interp1(use_wf_t,use_V',baseline_event_t,'previous'), ...
    length(baseline_times),length(baseline_t),[]),2);

aligned_v_baselinesub = aligned_v - aligned_baseline_v;

align_id = findgroups(reshape(align_category,[],1));

aligned_v_avg = permute(splitapply(@nanmean,aligned_v_baselinesub,align_id),[3,2,1]);
aligned_px_avg = plab.wf.svd2px(use_U,aligned_v_avg);

ap.imscroll(aligned_px_avg,t_kernels);
colormap(ap.colormap('PWG'));
% clim(prctile(0.2*abs(aligned_px_avg(:)),100).*[-1,1]);
clim(0.005*[-2 2])

axis image;
set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));

figure;
tiledlayout(1,size(aligned_px_avg,4))
for curr_image=1:size(aligned_px_avg,4)
    nexttile
imagesc(max(aligned_px_avg(:,:,t_kernels>0 & t_kernels<0.2,curr_image),[],3))
clim(0.005*[-2 2])
axis image off;

colormap(ap.colormap('PWG'));
end


% % (to do median)
% aligned_px_median = ap.groupfun(@median, ...
%     plab.wf.svd2px(use_U,permute(aligned_v_baselinesub,[3,2,1])), ...
%     [],[],[],align_id);
% 
% ap.imscroll(aligned_px_median,t);
% colormap(ap.colormap('PWG'));
% clim(prctile(abs(aligned_px_median(:)),100).*[-1,1]);
% axis image;
% set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));


%% Align ROI to event

[roi_trace,roi_mask] = ap.wf_roi(wf_U,wf_V,wf_avg);

% LCR passive: align to quiescent stim onset
stim_window = [0,0.5];
quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
    timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
    timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
    1:length(stimOn_times))';

align_times = stimOn_times(quiescent_trials);
if isfield(trial_events.values,'TrialStimX')
    align_category_all = vertcat(trial_events.values.TrialStimX);
elseif isfield(trial_events.values,'StimFrequence')
    align_category_all = vertcat(trial_events.values.StimFrequence);
end
align_category = align_category_all(quiescent_trials);
baseline_times = stimOn_times(quiescent_trials);

% % (task)
% align_times = stimOn_times(1:n_trials);
% baseline_times = stimOn_times(1:n_trials);
% align_category = ones(size(align_times));

% Align ROI trace to align times
surround_window = [-1,2];
baseline_window = [-0.5,-0.1];

surround_samplerate = 35;

t_kernels = surround_window(1):1/surround_samplerate:surround_window(2);
peri_event_t = reshape(align_times,[],1) + reshape(t_kernels,1,[]);

aligned_trace = reshape(interp1(wf_t,roi_trace',peri_event_t,'previous'), ...
    length(align_times),length(t_kernels),[]);
 
aligned_trace_baselinesub = aligned_trace - ...
    mean(aligned_trace(:,t_kernels >= baseline_window(1) & t_kernels <= baseline_window(2)),2);

align_id = findgroups(reshape(align_category,[],1));

figure;
h = tiledlayout(1,max(align_id));
for curr_id = 1:max(align_id)

    curr_trials = find(align_id == curr_id);

    sort_idx = 1:length(curr_trials);
    % [~,sort_idx] = sort(stim_to_move(curr_trials));

    nexttile;
    imagesc(t_kernels,[],aligned_trace_baselinesub(curr_trials(sort_idx),:))
    clim(0.8*max(max(aligned_trace_baselinesub,[],'all')).*[-1,1]);
    xline(0);
end
colormap(AP_colormap('PWG'));



%% Passive kernel

switch bonsai_workflow
    case {'lcr_passive','lcr_passive_size60','r_passive_contrast'}
        stim_type = vertcat(trial_events.values.TrialStimX);
    case {'hml_passive_audio','hml_passive_audio_mixed','m_8k_passive_audio_volume'}
        stim_type = vertcat(trial_events.values.StimFrequence);
    case 'r_passive_natural_image'
        stim_type = vertcat(trial_events.values.PictureID);
    case 'hml_passive_audio_earphone_balance'
        stim_type = vertcat(trial_events.values.trialID);
end

time_bins = [wf_t;wf_t(end)+1/wf_framerate];
        stim_type=        stim_type(1:length(stimOn_times));
stim_regressors = cell2mat(arrayfun(@(x) ...
    histcounts(stimOn_times(stim_type == x),time_bins), ...
    unique(stim_type),'uni',false));

n_components = 200;

frame_shifts = 0:20;
lambda = 20;
cv = 3;

skip_t = 10; % seconds start/end to skip for artifacts
skip_frames = round(skip_t*wf_framerate);
[kernels,predicted_signals,explained_var] = ...
    ap.regresskernel(wf_V(1:n_components,skip_frames:end-skip_frames), ...
    stim_regressors(:,skip_frames:end-skip_frames),-frame_shifts,lambda,[],cv);

kernels_px = plab.wf.svd2px(wf_U(:,:,1:size(kernels,1)),kernels);
ap.imscroll(kernels_px,frame_shifts);
% clim(0.6*max(abs(clim)).*[-1,1]);
 clim(0.0003.*[-1,1]);

colormap(ap.colormap('PWG'));
axis image

   % figure;plot(roi.trace')

% hold on;plot(roi.trace')

% trying SVM/SVR
% mdl = fitcsvm(wf_V',stim_regressors(1,:)');
% cvmodel = crossval(mdl);
% classLoss = kfoldLoss(cvmodel);
% 
% r = mdl.predict(wf_V');

t_kernels = frame_shifts/wf_framerate;
cs_minus_color = ap.colormap('WB');
cs_plus_color = ap.colormap('PWG');

stim_t = t_kernels > 0 & t_kernels < 0.2;
kernels_px_max = squeeze(max(kernels_px(:,:,stim_t,:),[],3));

col_lim = [-3e-4,3e-4];

figure;
name_id=unique(stim_type);
h = tiledlayout(1,size(kernels_px_max,3),'TileSpacing','none');

for curr_passive=1:size(kernels_px_max,3)

nexttile; 
imagesc(kernels_px_max(:,:,curr_passive)); 
clim(col_lim); axis image off;
colormap(gca,cs_plus_color);
title(name_id(curr_passive))
ap.wf_draw('ccf','k');
end

%% Passive kernel separated types

switch bonsai_workflow
    case {'lcr_passive','lcr_passive_size60','r_passive_contrast','lcr_passive_grating_size40','lcr_passive_contrast25','r_passive_contrast_up_to25'}
        stim_type = vertcat(trial_events.values.TrialStimX);
    case {'hml_passive_audio','hml_passive_audio_mixed',...
            'm_8k_passive_audio_volume','hml_passive_audio_earphone_freq','hml_passive_audio_earphone'}
        stim_type = vertcat(trial_events.values.StimFrequence);
    case 'r_passive_natural_image'
        stim_type = vertcat(trial_events.values.PictureID);
    case{ 'hml_passive_audio_earphone_balance'  , 'hml_passive_audio_earphone_balance_only'}     
        stim_type = vertcat(trial_events.values.trialID);
end

stimOn_times=stimOn_times(1:min(length(stimOff_times),length(stimOn_times)));

wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
stim_type= stim_type(1:length(stimOn_times));

stim_regressors = repmat({zeros(length(wf_t),1)}, length(unique(stim_type)), 1);
stim_regressors= arrayfun(@(a)  histcounts(stimOn_times(stim_type == a),wf_regressor_bins)',...
    unique(stim_type),'UniformOutput',false  );


gap_1=stimOn_times(1:length(stimOn_times))-0.5;
gap_2=[stimOn_times(2:length(stimOn_times))-0.1 ;stimOff_times(length(stimOn_times))+0.5];

wf_t_only_task= repmat({false(length(wf_t),1)}, length(unique(stim_type)), 1);
wf_t_only_task=arrayfun(@(a) interp1([gap_1(stim_type==a);gap_2(stim_type==a)],...
    [ones(sum(stim_type==a),1);....
    zeros(sum(stim_type==a),1)],...
    wf_t,'previous')==1, unique(stim_type),'UniformOutput',false);

n_components = 200;
frame_shifts = -10:30;
lambda = 20;
t_kernels = frame_shifts/wf_framerate;


   [stim_kernels,predicted_signals,explained_var] = ...
            cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
            wf_t_only_task, stim_regressors ,'UniformOutput',false );



kernels_px = cellfun(@(kernels) plab.wf.svd2px(wf_U(:,:,1:size(kernels,1)),kernels),stim_kernels,'UniformOutput',false);
kernels_px=cat(4,kernels_px{:});
ap.imscroll(kernels_px,t_kernels)
clim(0.0003.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image
set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));


stim_t = t_kernels > 0 & t_kernels < 0.2;
kernels_px_max = squeeze(max(kernels_px(:,:,stim_t,:),[],3));

col_lim = [-3e-4,3e-4];

figure;
name_id=unique(stim_type);
h = tiledlayout(1,size(kernels_px,4),'TileSpacing','none');

for curr_passive=1:size(kernels_px,4)
nexttile; 
imagesc(kernels_px_max(:,:,curr_passive)); 
clim(col_lim); axis image off;
colormap(gca,ap.colormap('PWG'));
title(name_id(curr_passive))
 ap.wf_draw('ccf','k');
end

load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
temp_each_roi= ds.make_each_roi(kernels_px, length(t_kernels),roi1);
figure;
nexttile
plot(t_kernels,permute(temp_each_roi(1,:,:),[2,3,1]))
nexttile
plot(t_kernels,permute(temp_each_roi(7,:,:),[2,3,1]))
nexttile
hold on
plot(permute(max(temp_each_roi(1,t_kernels<0.2&t_kernels>0,:),[],2),[3,2,1]))
plot(permute(max(temp_each_roi(7,t_kernels<0.2&t_kernels>0,:),[],2),[3,2,1]))

%% Task kernel

time_bins = [wf_t;wf_t(end)+1/wf_framerate];
stim_regressors = histcounts(stimOn_times,time_bins);
% stim_regressors = histcounts(audio_onsets,time_bins);

n_components = 200;
frame_shifts = -10:20;
lambda = 15;
cv_fold = 5;

[kernels,predicted_signals,explained_var] = ...
    ap.regresskernel(wf_V(1:n_components,:), ...
    stim_regressors,-frame_shifts,lambda,[],cv_fold);
surround_samplerate = 35;

t_kernels=1/surround_samplerate*[-10:20];

kernels_px = plab.wf.svd2px(wf_U(:,:,1:size(kernels,1)),kernels);
ap.imscroll(kernels_px,t_kernels);
% clim(0.5*max(abs(clim)).*[-1,1]);
clim(0.0003.*[-1,1]);
colormap(ap.colormap('PWG'));
 ap.wf_draw('ccf','k');

axis image
set(gcf,'name',sprintf('%s %s %s',animal,rec_day,bonsai_workflow));

figure;
imagesc(max(kernels_px(:,:,t_kernels<0.2&t_kernels>0),[],3))
% clim(0.5*max(abs(clim)).*[-1,1]);
clim(0.0003.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image off
 ap.wf_draw('ccf','k');

%% Task kernel separate timelite



wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
real_stimOn_times=stimOn_times(1:n_trials);
curr_tasktype_0=vertcat(trial_events.values.TaskType);
stim_to_move_idx= curr_tasktype_0(1:n_trials);


stim_regressors = repmat({zeros(length(wf_t),1)}, 2, 1);
stim_regressors(unique(stim_to_move_idx))= arrayfun(@(a)  histcounts(real_stimOn_times(stim_to_move_idx==a),wf_regressor_bins)',...
    unique(stim_to_move_idx),'UniformOutput',false  );


gap_1=seconds([trial_events.timestamps(1:n_trials).ITIStart ] -trial_events.timestamps(1).StimOn (1))'+photodiode_on_times(1);
gap_2=stimOn_times(1:n_trials)+stim_to_outcome(1:n_trials);

wf_t_only_task= repmat({false(length(wf_t),1)}, 2, 1);
wf_t_only_task(unique(stim_to_move_idx))=arrayfun(@(a) interp1([gap_1(stim_to_move_idx==a);gap_2(stim_to_move_idx==a)],...
    [ones(sum(stim_to_move_idx==a),1);....
    zeros(sum(stim_to_move_idx==a),1)],...
    wf_t,'previous')==1, unique(stim_to_move_idx),'UniformOutput',false);



%  linear regression:

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
            cellfun(@(x,y) ap.regresskernel(wf_V(1:n_components,find(x==1)),y(find(x==1))',-frame_shifts,lambda),...
            wf_t_only_task, stim_regressors ,'UniformOutput',false );

        success = true; % 如果没有报错，则成功运行
    catch ME
        disp(['Error: ', ME.message]);
        n_components = n_components - 10; % 变量 a 递减
        if n_components < 100 % 避免无限循环（你可以根据实际情况调整）
            error('n_components 过小，无法继续运行');
        end
    end
end



disp('stim_kernels_running_successfully');
kernels_px = cellfun(@(kernels) plab.wf.svd2px(wf_U(:,:,1:size(kernels,1)),kernels),stim_kernels,'UniformOutput',false);


ap.imscroll(cat(4,kernels_px{:}),t_kernels);
% clim(max(abs(clim)).*[-1,1]);
clim(0.0003.*[-1,1]);
colormap(ap.colormap('PWG'));
axis image



kernels_px_all=cat(4,kernels_px{:});

kernels_px_all_max=permute(max(kernels_px_all(:,:,t_kernels<0.2&t_kernels>0,:),[],3),[1,2,4,3]);


figure;
% name_id=unique(stim_type);
h = tiledlayout(1,size(kernels_px_all,4),'TileSpacing','none');
for curr_passive=1:size(kernels_px_all,4)
nexttile; 
imagesc(kernels_px_all_max(:,:,curr_passive)); 
clim(0.0002*[-1 1]); axis image off;
colormap(gca,ap.colormap('PWG'));
% title(name_id(curr_passive))
ap.wf_draw('ccf','k');
end


load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
temp_each_roi= ds.make_each_roi(kernels_px_all, length(t_kernels),roi1);
figure;
nexttile
plot(t_kernels,permute(temp_each_roi(1,:,:),[2,3,1]))

nexttile
plot(t_kernels,permute(temp_each_roi(7,:,:),[2,3,1]))
nexttile
hold on
plot(permute(max(temp_each_roi(1,t_kernels<0.2&t_kernels>0,:),[],2),[3,2,1]))
plot(permute(max(temp_each_roi(7,t_kernels<0.2&t_kernels>0,:),[],2),[3,2,1]))



%  [stim_kernels2,predicted_signals,explained_var] = ...
%            ap.regresskernel(wf_V(1:n_components,:),cat(1,stim_regressors{:}),-frame_shifts,lambda),...
%  kernels_px2 =plab.wf.svd2px(wf_U(:,:,1:size(stim_kernels2,1)),stim_kernels2);
% 
% ap.imscroll(kernels_px2,frame_shifts);
% clim(max(abs(clim)).*[-1,1]);
% colormap(ap.colormap('PWG'));
% axis image

%%  movement kernels iti move
U_master = plab.wf.load_master_U;
surround_samplerate = 35;
t_kernels=1/surround_samplerate*[-10:30];

ds.load_iti_move
pho_on_times=photodiode_times(photodiode_values==1);
pho_off_times=photodiode_times(photodiode_values==0)+2;
wf_t_only_iti = interp1([pho_on_times;pho_off_times], ...
    [zeros(sum(photodiode_values==1),1);ones(sum(photodiode_values==0),1)], ...
    wf_t,'previous')==1;

wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
iti_move_regressors=histcounts(iti_move_time,wf_regressor_bins);


n_components = 200;
frame_shifts = -10:30;
lambda = 15;

success = false; % 标记变量，判断是否成功运行
while ~success
    try

        disp(['Running with n_components = ', num2str(n_components)]);
        [iti_move_kernels,predicted_signals,explained_var] = ...
            ap.regresskernel(wf_V(1:n_components,wf_t_only_iti),iti_move_regressors(wf_t_only_iti),-frame_shifts,lambda);

        success = true; % 如果没有报错，则成功运行
    catch ME
        disp(['Error: ', ME.message]);
        n_components = n_components - 10; % 变量 a 递减
        if n_components < 50 % 避免无限循环（你可以根据实际情况调整）
            error('n_components 过小，无法继续运行');
        end
    end
end

disp('iti_move_kernels_running_successfully');
tem_image= plab.wf.svd2px(U_master(:,:,1:size(iti_move_kernels,1)),iti_move_kernels);
ap.imscroll(tem_image,t_kernels)
axis image off
 clim( 0.0003*[-1,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap(['PWG']));




%% Sparse noise retinotopy (single day)

% Load data
animal = 'AP026';
workflow = 'sparse_noise';

% % Specific day
% rec_day = '2023-12-06';
% rec_time = plab.find_recordings(animal,rec_day,workflow).recording{end};

% Relative day
recordings = plab.find_recordings(animal,[],workflow);
use_day = 1;
% use_day = length(recordings);
rec_day = recordings(use_day).day;
rec_time = recordings(use_day).recording{end};

load_parts.widefield = true;

verbose = true;
ap.load_recording;

% Get retinotopy
ap.wf_retinotopy


%% ~~~~~~~~ ALIGN WIDEFIELD

%% Create alignments

animal = 'AP005';

% Get and save VFS maps for animal
plab.wf.retinotopy_vfs_batch(animal);

% Create across-day alignments
plab.wf.wf_align([],animal,[],'new_days');

% Create across-animal alignments
plab.wf.wf_align([],animal,[],'new_animal');


%% View aligned days

animal = 'HA009';

recordings = plab.find_recordings(animal);
wf_days_idx = cellfun(@(x) any(x),{recordings.widefield});
wf_recordings = recordings(wf_days_idx);

avg_im_aligned = cell(size(wf_recordings));
for curr_day = 1:length(wf_recordings)
    day = wf_recordings(curr_day).day;

    img_path = plab.locations.filename('server', ...
        animal,day,[],'widefield');

    avg_im_n = readNPY([img_path filesep 'meanImage_blue.npy']);
    avg_im_h = readNPY([img_path filesep 'meanImage_violet.npy']);

%         % (to concatenate)
%         avg_im_aligned{curr_day} = [plab.wf.wf_align(avg_im_n,animal,day), ...
%             plab.wf.wf_align(avg_im_h,animal,day)];

    % (blue only)
    avg_im_aligned{curr_day} = plab.wf.wf_align(avg_im_n,animal,day);
end

% Plot average
c = prctile(reshape([avg_im_aligned{:}],[],1),[0,99.9]);
AP_imscroll(cat(3,avg_im_aligned{:}),{wf_recordings.day});
caxis(c);
axis image;
set(gcf,'Name',animal);

%% Regression task > widefield

% Parameters for regression
regression_params.use_svs = 1:100;
regression_params.skip_seconds = 20;
regression_params.upsample_factor = 1;
regression_params.kernel_t = [-0.1,0.1];
regression_params.zs = [false,false];
regression_params.cvfold = 5;
regression_params.use_constant = true;

% Get time points to bin
time_bin_centers = wf_t;
time_bins = [wf_t;wf_t(end)+1/wf_framerate];

% Regressors
stim_regressors = histcounts(stimOn_times,time_bins);
reward_regressors = histcounts(reward_times,time_bins);

stim_move_regressors = histcounts(stim_move_time,time_bins);
nonstim_move_times = ...
    setdiff(timelite.timestamps(find(diff(wheel_move) == 1)+1), ...
    stim_move_regressors);
nonstim_move_regressors = histcounts(nonstim_move_times,time_bins);

% Concatenate selected regressors, set parameters
task_regressors = {stim_regressors;reward_regressors;stim_move_regressors;nonstim_move_regressors};
task_regressor_labels = {'Stim','Reward','Stim move','Nonstim move'};

task_t_shifts = { ...
    [-0.2,2]; ... % stim
    [-0.2,2];  ... % outcome
    [-0.2,2];  ... % nonstim move
    [-0.2,2]};    % stim move

% task_regressors = {stim_regressors;reward_regressors};
% task_regressor_labels = {'Stim','Reward'};
% 
% task_t_shifts = { ...
%     [-0.2,2]; ... % stim
%     [-0.2,2]};    % reward

task_regressor_sample_shifts = cellfun(@(x) round(x(1)*(wf_framerate)): ...
    round(x(2)*(wf_framerate)),task_t_shifts,'uni',false);
lambda = 0;
zs = [false,false];
cvfold = 5;
use_constant = true;
return_constant = false;
use_svs = 100;

[fluor_taskpred_k,fluor_taskpred_long,fluor_taskpred_expl_var,fluor_taskpred_reduced_long] = ...
    AP_regresskernel(task_regressors,wf_V(1:use_svs,:),task_regressor_sample_shifts, ...
    lambda,zs,cvfold,return_constant,use_constant);
% 
% fluor_taskpred = ...
%     interp1(time_bin_centers,fluor_taskpred_long',t_peri_event);
% 
% fluor_taskpred_reduced = cell2mat(arrayfun(@(x) ...
%     interp1(time_bin_centers,fluor_taskpred_reduced_long(:,:,x)', ...
%     t_peri_event),permute(1:length(task_regressors),[1,3,4,2]),'uni',false));



a = cellfun(@(x) plab.wf.svd2px(wf_U(:,:,1:use_svs), ...
    permute(x,[3,2,1])),fluor_taskpred_k,'uni',false);

AP_imscroll(cat(4,a{:}));
axis image;
clim(max(abs(clim)).*[-1,1]); 
colormap(AP_colormap('PWG'));


%% ~~~~~~~~ BATCH


%% TESTING BATCH PASSIVE WIDEFIELD

animal = 'HA002';
passive_workflow = 'lcr_passive';
% passive_workflow = 'hml_passive_audio';
recordings_passive = plab.find_recordings(animal,[],passive_workflow);

% training_workflow = 'stim_wheel*';
training_workflow = 'visual*';
% training_workflow = '*audio_volume*';
recordings_training = plab.find_recordings(animal,[],training_workflow);

% (use recordings on training days)
recordings = recordings_passive( ...
    cellfun(@any,{recordings_passive.widefield}) & ...
    ismember({recordings_passive.day},{recordings_training.day}));

% % (use recordings on or before last training day)
% recordings = recordings_passive( ...
%     cellfun(@any,{recordings_passive.widefield}) & ...
%     ~[recordings_passive.ephys] & ...
%     days(datetime({recordings_passive.day}) - datetime(recordings_training(end).day)) <= 0);

% (use all passive recordings)
% recordings = recordings_passive( ...
%     cellfun(@any,{recordings_passive.widefield}) & ...
%     ~[recordings_passive.ephys]);

wf_px = cell(size(recordings));

for curr_recording = 1:length(recordings)

    % Grab pre-load vars
    preload_vars = who;

    % Load data
    rec_day = recordings(curr_recording).day;
    rec_time = recordings(curr_recording).recording{end};
    if ~recordings(curr_recording).widefield(end)
        continue
    end

    try
    load_parts.widefield = true;
    ap.load_recording;
    catch me
        warning('%s %s %s: load error, skipping \n >> %s', ...
            animal,rec_day,rec_time,me.message)
        continue
    end

    % Get quiescent trials and stim onsets/ids
    stim_window = [0,0.5];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times))';

    align_times = stimOn_times(quiescent_trials);
    align_category_all = vertcat(trial_events.values.TrialStimX);
%     align_category_all = vertcat(trial_events.values.StimFrequence);
    align_category = align_category_all(quiescent_trials);

    % Align to stim onset
    surround_window = [-0.5,1];
    surround_samplerate = 35;
    t_kernels = surround_window(1):1/surround_samplerate:surround_window(2);
    peri_event_t = reshape(align_times,[],1) + reshape(t_kernels,1,[]);

    aligned_v = reshape(interp1(wf_t,wf_V',peri_event_t,'previous'), ...
        length(align_times),length(t_kernels),[]);

    align_id = findgroups(align_category);
    aligned_v_avg = permute(splitapply(@nanmean,aligned_v,align_id),[3,2,1]);
    aligned_v_avg_baselined = aligned_v_avg - nanmean(aligned_v_avg(:,t_kernels < 0,:),2);

    % Convert to pixels and package
    aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
    wf_px{curr_recording} = aligned_px_avg;

    % Prep for next loop
    AP_print_progress_fraction(curr_recording,length(recordings));
    clearvars('-except',preload_vars{:});

end

surround_window = [-0.5,1];
surround_samplerate = 35;
t_kernels = surround_window(1):1/surround_samplerate:surround_window(2);
a = cellfun(@(x) max(x(:,:,t_kernels > 0 & t_kernels < 0.2,3),[],3), ...
    wf_px(cellfun(@(x) ~isempty(x),wf_px)),'uni',false);
c = (max(cellfun(@(x) max(x(:)),a)).*[-1,1])/2;

figure('Name',animal');
tiledlayout('flow','TileSpacing','none')
for i = 1:length(a)
    nexttile;imagesc(a{i}); axis image off;
    clim(c); colormap(AP_colormap('PWG'));
end
ap.imscroll(cat(3,a{:}));
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(AP_colormap('PWG'));

a = cat(5,wf_px{:});
b = squeeze(a(:,:,:,3,:));
ap.imscroll(b);
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(AP_colormap('PWG'));

% % (reflect widefield - taken out for now)
% a = cellfun(@(x) x-ap.wf_reflect(x),wf_px,'uni',false);
% b = cellfun(@(x) mean(x(:,:,t > 0.05 & t < 0.15,3),3),a,'uni',false);
% c = (max(cellfun(@(x) max(x(:)),a)).*[-1,1])/2;
% figure('Name',animal');
% tiledlayout('flow')
% for i = 1:length(a)
%     nexttile; imagesc(b{i}); axis image off;
% end
% AP_imscroll(cat(3,b{:}));
% axis image;
% clim(c); colormap(AP_colormap('PWG'));

a = cat(5,wf_px{:});
b = squeeze(a(:,:,:,3,:));
b2 = squeeze(mean(b(:,:,t_kernels > 0 & t_kernels < 0.2,:),3));


%%






