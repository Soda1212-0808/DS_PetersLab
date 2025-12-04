
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);


load_parts.mousecam=false;
ap.load_recording

wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
stim_regressor_90 = histcounts(stimOn_times(align_category_all==90),wf_regressor_bins);
stim_regressor_n90 = histcounts(stimOn_times(align_category_all==-90),wf_regressor_bins);
stim_regressor_0 = histcounts(stimOn_times(align_category_all==0),wf_regressor_bins);

move_regressor = histcounts((timelite.timestamps(find([diff(wheel_move); 0]==1))),wf_regressor_bins);
regressors = {stim_regressor_90;stim_regressor_0;stim_regressor_n90;move_regressor};
% Set time shifts for regressors
t_shifts = {[-5:30];[-5:30];[-5:30];[-30:30]};
% Set cross validation (not necessary if just looking at kernels)
cvfold = 5;
% Do regression
[kernels,predicted_signals,explained_var,predicted_signals_reduced] = ...
    ap.regresskernel(regressors,wf_V,t_shifts,[],[],cvfold);

wf_px_passive_kernels=permute(cat(4,kernels{1:3}),[3,2,4,1]);

load(master_U_fn);
surround_samplerate = 35;
t_kernels=1/surround_samplerate*[-5:30];

wf_px_kernles=plab.wf.svd2px(U_master,wf_px_passive_kernels);
ap.imscroll(wf_px_kernles,t_kernels)
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
