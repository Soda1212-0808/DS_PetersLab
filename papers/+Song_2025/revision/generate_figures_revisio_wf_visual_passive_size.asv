clear all
Path = 'D:\Data process\project_cross_model\wf_data\';

% Path = 'Y:\Data process\project_cross_model\wf_data\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
% master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
%     'widefield_alignment','U_master.mat');
animals={'AP030','AP032','DS029','DS030','DS031'};
workflow_passive={'lcr_passive','lcr_passive_size60'};

passive_data=table;
passive_data.name=animals';
for curr_animal_idx=1:length(animals)
    main_preload_vars = who;
    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    for curr_passive=1:2
        curr_passive_workflow = workflow_passive{curr_passive};
        fprintf('%s\n', ['start saving ' curr_passive_workflow ' files...']);
        recordings_passive = plab.find_recordings(animal,[],'lcr_passive_size60');
        recordings_task = plab.find_recordings(animal,[],'stim_wheel_right_stage2');
        temp_days=intersect( {recordings_passive.day},{recordings_task.day});
        recordings=plab.find_recordings(animal,[],curr_passive_workflow);
        recordings= recordings(    ismember({recordings.day},temp_days));
        wf_px_kernels=cell(length(recordings),1);
        for curr_recording =1:length(recordings)
            preload_vars = who;
            rec_day = recordings(curr_recording).day;
            rec_time = recordings(curr_recording).recording{end};

            load_parts.mousecam = true;
            load_parts.widefield = true;
            load_parts.widefield_master = true;
            ap.load_recording;


            % % Get quiescent trials and stim onsets/ids
            % %得到不动的trial
            % stimOn_times=stimOn_times(1:length(stimOff_times));
            % stim_window1 = [0,0.3];
            % quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
            %     timelite.timestamps >= stimOn_times(x)+stim_window1(1) & ...
            %     timelite.timestamps <= stimOn_times(x)+stim_window1(2))), ...
            %     1:length(stimOn_times))';

            align_category_all = vertcat(trial_events.values.TrialStimX);

            wf_regressor_bins = [wf_t;wf_t(end)+1/wf_framerate];
            stim_regressors = cell2mat(arrayfun(@(x) ...
                histcounts(stimOn_times(align_category_all == x),wf_regressor_bins), ...
                unique(align_category_all),'uni',false));

            n_components = 400;
            frame_shifts = -10:30;
            lambda = 15;

            success = false; % 标记变量，判断是否成功运行
            while ~success
                try

                    disp(['Running with n_components = ', num2str(n_components)]);
                    [kernels,predicted_signals,explained_var] = ...
                        ap.regresskernel(wf_V(1:n_components,:),stim_regressors,-frame_shifts,lambda);

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
            wf_px_kernels{curr_recording} = kernels;

            % Prep for next loop
            ap.print_progress_fraction(curr_recording,length(recordings));
            clearvars('-except',preload_vars{:});

        end

        passive_data.(workflow_passive{curr_passive})(curr_animal_idx)={cat(4,wf_px_kernels{:})};
    
    end
end




save_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data';
save(fullfile(save_path,'revision','visual_size_passive_compare.mat'),'passive_data','-v7.3');

%%
clear all

save_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data';
load(fullfile(save_path,'revision','visual_size_passive_compare.mat'));
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

U_master = plab.wf.load_master_U;


tem_passive_s_image=cell(2,1);
tem_passive_l_image=cell(2,1);
trace_s_mean=cell(2,1);
trace_l_mean=cell(2,1);
for curr_animal=1:2

tem_passive_s=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),passive_data.lcr_passive(curr_animal),'UniformOutput',false);
tem_passive_l=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),passive_data.lcr_passive_size60(curr_animal),'UniformOutput',false);
tem_passive_s_image{curr_animal}=permute(nanmean(max(tem_passive_s{1}(:,:,period,3,:),[],3),5),[1,2,5,3,4]);
tem_passive_l_image{curr_animal}=permute(nanmean(max(tem_passive_l{1}(:,:,period,3,:),[],3),5),[1,2,5,3,4]);

trace_s=ds.make_each_roi(permute(tem_passive_s{1}(:,:,:,3,:),[1,2,3,5,4]),t_kernels,roi1);
trace_l=ds.make_each_roi(permute(tem_passive_l{1}(:,:,:,3,:),[1,2,3,5,4]),t_kernels,roi1);
trace_s_mean{curr_animal}=nanmean(trace_s,3);
trace_s_error=std(trace_s,0,3,'omitmissing')./sqrt(size(trace_s,3));
trace_l_mean{curr_animal}=nanmean(trace_l,3);
trace_l_error=std(trace_l,0,3,'omitmissing')./sqrt(size(trace_l,3));


figure('Position',[50 50 800 200]);
tiledlayout(1,4)

nexttile
imagesc(tem_passive_s_image{curr_animal})
axis image off
clim( 0.0003*[-1,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap(['PWG']));
nexttile
imagesc(tem_passive_l_image{curr_animal})
axis image off
clim( 0.0003*[-1,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap(['PWG']));

nexttile
hold on
ap.errorfill(t_kernels,trace_s_mean{curr_animal}(7,:),trace_s_error(1,:))
ap.errorfill(t_kernels,trace_l_mean{curr_animal}(7,:),trace_l_error(1,:))
title('V1')
xlim([-0.1 0.5])

nexttile
hold on
ap.errorfill(t_kernels,trace_s_mean{curr_animal}(1,:),trace_s_error(1,:))
ap.errorfill(t_kernels,trace_l_mean{curr_animal}(1,:),trace_l_error(1,:))
title('mPFC')
xlim([-0.1 0.5])


end

trace_s_all_mean=nanmean(cat(3,trace_s_mean{:}),3);
trace_s_all_error=std(cat(3,trace_s_mean{:}),0,3)./sqrt(length(trace_s_mean));
trace_l_all_mean=nanmean(cat(3,trace_l_mean{:}),3);
trace_l_all_error=std(cat(3,trace_l_mean{:}),0,3)./sqrt(length(trace_l_mean));

tem_passive_l_image_all=nanmean(cat(3,tem_passive_l_image{:}),3);
tem_passive_s_image_all=nanmean(cat(3,tem_passive_s_image{:}),3);




figure('Position',[50 50 800 200]);
tiledlayout(1,4)

nexttile
imagesc(tem_passive_s_image_all)
axis image off
clim( 0.0003*[-1,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
title('size 20')

colormap( ap.colormap(['PWG']));
nexttile
imagesc(tem_passive_l_image_all)
axis image off
clim( 0.0003*[-1,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap(['PWG']));
title('size 60')

nexttile
hold on
ap.errorfill(t_kernels,trace_s_all_mean(7,:),trace_s_all_error(7,:))
ap.errorfill(t_kernels,trace_l_all_mean(7,:),trace_l_all_error(7,:))
title('V1')
xlim([-0.1 0.5])

nexttile
hold on
ap.errorfill(t_kernels,trace_s_all_mean(1,:),trace_s_all_error(1,:))
ap.errorfill(t_kernels,trace_l_all_mean(1,:),trace_l_all_error(1,:))
title('mPFC')
xlim([-0.1 0.5])

