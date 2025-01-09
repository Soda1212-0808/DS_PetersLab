clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-5:30];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);

passive_boundary=0.15;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels_passive=find(t_kernels>0&t_kernels<passive_boundary);

task_boundary=0.1;
period_task=find(t_task>0&t_task<task_boundary);
period_kernels_task=find(t_kernels>0&t_kernels<task_boundary);

%%behavior
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);



animals = {'AP018','AP019','AP020','AP021','AP022','DS007','DS010','AP027','AP028','AP029','HA003','HA004'};

% 分组：group 1: visual position; 2: visual opacity; 3: visual size up
group_type=[1 1 1 1 1 1 1 2 2 2 3 3];
group_name={'stim_wheel_right_stage2','stim_wheel_right_stage2_opacity','stim_wheel_right_stage2_size_up'};
nick_name={'visual position','visual opacity','visual size'};

%
plot_matrix_passive=cell(length(animals),1);
plot_matrix_passive_2=cell(length(animals),1);

averaged_imaging_passive=cell(length(animals),1);
use_t_passive=[];
for curr_animal=1:length(animals)

    preload_vars = who;

    animal=animals{curr_animal}
    all_passive_workflow={'lcr_passive','hml_passive_audio'};
    workflow_idx=1;
    passive_wokrflow=all_passive_workflow{workflow_idx};

    learn_name={'non-learned','learned'};
    workflow_stage={'naive','visual','auditory','mixed'};
    legend_name={'-90','0','90';'4k','8k','12k'};

    used_data=1;% 1 raw data;2 kernels
    data_type={'raw','kernels'};
    raw_data_lcr1=load([Path '\mat_data\' passive_wokrflow '\' animal '_' passive_wokrflow '.mat']);
    % raw_data_lcr2=load([Path '\mat_data\' wokrflow '\' animal '_lcr_passive_single_trial.mat']);
    if used_data==1
        idx=cellfun(@(x) ~isempty(x),raw_data_lcr1.wf_px);
        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_lcr1.wf_px(idx),'UniformOutput',false);
        use_period_passive=period_passive;
        use_t_passive=t_passive;
    else
        idx=cellfun(@(x) ~isempty(x),raw_data_lcr1.wf_px_kernels);

        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x{1}),raw_data_lcr1.wf_px_kernels(idx),'UniformOutput',false);
        use_period_passive=period_kernels_passive;
        use_t_passive=t_kernels;

    end


    image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period_passive,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
    buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
    % buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
    buf3(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);


    choosed_learned_day=cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_lcr1.workflow_type_name,'UniformOutput',true) &raw_data_lcr1.learned_day';


    first_learned_day=find((cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_lcr1.workflow_type_name,'UniformOutput',true) ...
        &raw_data_lcr1.learned_day')==1,1);

    plot_matrix_passive{curr_animal}= cell2mat(cellfun(@(x) x(:,3), buf3(first_learned_day-2:first_learned_day+4), 'UniformOutput', false))
    if strcmp( animal, 'AP028')
        last_learned_day=14;
    else
        last_learned_day=find((cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_lcr1.workflow_type_name,'UniformOutput',true) ...
            &raw_data_lcr1.learned_day')==1,1,'last');
    end
    plot_matrix_passive_2{curr_animal}= cell2mat(cellfun(@(x) x(:,3), buf3(last_learned_day-6:last_learned_day), 'UniformOutput', false))

    % averaged_imaging_passive{curr_animal}=mean(cat(4,image_all_mean{choosed_learned_day}),4);

    averaged_imaging_passive{curr_animal}=mean(cat(4,image_all_mean{last_learned_day-4:last_learned_day}),4);

    figure('Name',animal);
    a1=nexttile;
    imagesc(averaged_imaging_passive{curr_animal}(:,:,3))
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap(a1, ap.colormap('WG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.005.*[0,1]);

    colorbar

    a2=nexttile;
    imagesc(use_t_passive,[],plot_matrix_passive{curr_animal}')
    colormap(a2, ap.colormap('PWG'));
    clim(0.8*max(plot_matrix_passive{curr_animal},[],'all').*[-1,1]);
    colorbar
    sgtitle([animal ' in ' nick_name{group_type(curr_animal)} ])
    drawnow
    clearvars('-except',preload_vars{:});
end

%
plot_matrix_task=cell(length(animals),1);
plot_move_task=cell(length(animals),1);
plot_reaction_task=cell(length(animals),1);

plot_matrix_task_2=cell(length(animals),1);
plot_move_task_2=cell(length(animals),1);
plot_reaction_task_2=cell(length(animals),1);


averaged_imaging_task=cell(length(animals),1);
use_t_task=[];
for curr_animal=10:length(animals)

    preload_vars = who;

    animal=animals{curr_animal}

    used_data=2;% 1 raw data;2 kernels
    data_type={'raw','kernels'};
    raw_data_task=load([Path '\mat_data\task\' animal '_task.mat']);

    learned_day=zeros(length(raw_data_task.rxn_med),1);
    for curr_d=1:length(raw_data_task.rxn_med)
        if length(raw_data_task.rxn_med{curr_d})==1
            learned_day(curr_d)=raw_data_task.rxn_med{curr_d}<2& raw_data_task.rxn_stat_p{curr_d}<0.05;
        else

        end
    end

    raw_data_task.learned_day=learned_day';


    if used_data==1
        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task);
        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_task.wf_px_task(idx),'UniformOutput',false);
        use_period_task=period_task;
        use_t_task=t_task;
    else
        idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels);

        image_all(idx)=cellfun(@(x)  plab.wf.svd2px(U_master,x{1}),raw_data_task.wf_px_task_kernels(idx),'UniformOutput',false);
        use_period_task=period_kernels_task;
        use_t_task=t_kernels;

    end


    image_all_mean(idx)=cellfun(@(x) permute(max(x(:,:,use_period_task,:),[],3),[1,2,4,3]),image_all(idx),'UniformOutput',false);
    buf1(idx)=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all(idx), 'UniformOutput', false);
    % buf2= cell2mat(cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,3),1),[2,3,1]) , buf1, 'UniformOutput', false));
    buf3(idx)= cellfun(@(z) permute(mean(z(roi1(1).data.mask(:),:,:),1),[2,3,1]) , buf1(idx), 'UniformOutput', false);



    choosed_learned_day=cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_task.workflow_type_name,'UniformOutput',true) &raw_data_task.learned_day';


    first_learned_day=find((cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_task.workflow_type_name,'UniformOutput',true) ...
        &raw_data_task.learned_day')==1,1);

    plot_matrix_task{curr_animal}= cell2mat( buf3(first_learned_day-2:first_learned_day+4));
    plot_move_task{curr_animal}=raw_data_task.frac_move_stimalign(first_learned_day-2:first_learned_day+4,:)  ;
    plot_reaction_task{curr_animal}=cell2mat(raw_data_task.stim2move_med(first_learned_day-2:first_learned_day+4) );
    if strcmp( animal, 'AP028')
        last_learned_day=14;
    else
        last_learned_day=find((cellfun(@(x) strcmp(x,group_name{group_type(curr_animal)}),raw_data_task.workflow_type_name,'UniformOutput',true) ...
            &raw_data_task.learned_day')==1,1,'last');
    end


    plot_matrix_task_2{curr_animal}= cell2mat( buf3(last_learned_day-6:last_learned_day));
    plot_move_task_2{curr_animal}=raw_data_task.frac_move_stimalign(last_learned_day-6:last_learned_day,:)  ;
    plot_reaction_task_2{curr_animal}=cell2mat(raw_data_task.stim2move_med(last_learned_day-6:last_learned_day) );

    % averaged_imaging_task{curr_animal}=mean(cat(4,image_all_mean{choosed_learned_day}),4);
    averaged_imaging_task{curr_animal}=mean(cat(4,image_all_mean{last_learned_day-4:last_learned_day}),4);


    figure('Name',animal);
    a1=nexttile;
    imagesc(averaged_imaging_task{curr_animal})
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap(a1, ap.colormap('WG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.005.*[0,1]);

    colorbar

    a2=nexttile;
    imagesc(use_t_task,[],plot_matrix_task{curr_animal}')
    colormap(a2, ap.colormap('PWG'));
    clim(0.8*max(plot_matrix_task{curr_animal},[],'all').*[-1,1]);
    colorbar
    sgtitle([animal ' in ' nick_name{group_type(curr_animal)} ])


    a3=nexttile;
    imagesc(surround_time_points,[], plot_move_task{curr_animal})
    colormap(a3, ap.colormap('WK'));

    a4=nexttile;
    plot( surround_time_points,mean(plot_move_task{curr_animal},1))
    a5=nexttile;
    plot( -1:5 , plot_reaction_task{curr_animal})
    ylim([0 0.5])

    drawnow

    clearvars('-except',preload_vars{:});
end



%% used first 5 day
split_group_passive=splitapply(@(x) {x},averaged_imaging_passive,group_type');
split_group_passive2=cellfun(@(x) mean(cat(4,x{:}),4),split_group_passive,'UniformOutput',false );
split_plot_passive=splitapply(@(x) {x},plot_matrix_passive,group_type');
split_plot_passive2=cellfun(@(x) mean(cat(3,x{:}),3),split_plot_passive,'UniformOutput',false );

split_group_task=splitapply(@(x) {x},averaged_imaging_task,group_type');
split_group_task2=cellfun(@(x) mean(cat(3,x{:}),3),split_group_task,'UniformOutput',false );

split_plot_task=splitapply(@(x) {x},plot_matrix_task,group_type');
split_plot_task2=cellfun(@(x) mean(cat(3,x{:}),3),split_plot_task,'UniformOutput',false );


split_plot_move_task=cellfun(@(x) mean(cat(3,x{:}),3),splitapply(@(x) {x},plot_move_task,group_type'),'UniformOutput',false );
split_plot_reaction_task=cellfun(@(x) mean(cat(3,x{:}),3),splitapply(@(x) {x},plot_reaction_task,group_type'),'UniformOutput',false );
%
figure('Position',[50 100 3*200 1200]);
tt = tiledlayout(1,3,'TileSpacing','tight');
% figure('Position',[50 50 800 400]);
for i=1:3

    t_type = tiledlayout(tt,7,1);
    t_type.Layout.Tile = i;
    title(t_type,nick_name{i});

    a1=nexttile(t_type);
    imagesc(split_group_passive2{i}(:,:,3))
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( a1,ap.colormap('PWG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.004.*[-1,1]);
    if i==3
        colorbar
    end
    a2=nexttile(t_type);
    imagesc(use_t_passive,-1:5,split_plot_passive2{i}')
    set(gca, 'YTick', [-0.5, 1,5], 'YTickLabel', {'pre','day 1','day 5'})
    colormap(a2, ap.colormap('PWG'));
    clim(0.006.*[-1,1]);
    yline(0.5);    xline(0.15,'Color','r')

    xlabel('time(s)')
    if i==3
        colorbar
    end

    a3=nexttile(t_type);
    imagesc(split_group_task2{i})
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( a3,ap.colormap('PWG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.004.*[-1,1]);
    if i==3
        colorbar
    end


    a4=nexttile(t_type);
    imagesc(use_t_task,-1:5,split_plot_task2{i}')
    set(gca, 'YTick', [-0.5, 1,5], 'YTickLabel', {'pre','day 1','day 5'})
    colormap(a4, ap.colormap('PWG'));
    clim(0.002.*[-1,1]);
    yline(0.5) ; xline(0.1,'Color','r')
    xlabel('time(s)')
    if i==3
        colorbar
    end


    a5=nexttile(t_type)
    imagesc(surround_time_points,-1:5,split_plot_move_task{i})
    colormap(a5, ap.colormap('WK'));
    yline(0.5)
    xlabel('Time to stim (s)')
    ylabel('Fraction moving')


    a6=nexttile(t_type)
    plot(surround_time_points,mean(split_plot_move_task{i}(3:end,:),1))
    ylim([0 1])
    xlabel('Time to stim (s)')


    a7=nexttile(t_type)
    plot( -1:5 , split_plot_reaction_task{i})
    ylim([0 1])
    ylabel('Reaction time (s)')
    xline(0.5)


end

saveas(gcf,[Path 'figures\summary\compare_3_tasks'], 'jpg');



%% used last 5 day


%
split_group_passive=splitapply(@(x) {x},averaged_imaging_passive,group_type');
split_group_passive2=cellfun(@(x) mean(cat(4,x{:}),4),split_group_passive,'UniformOutput',false );

split_plot_passive=splitapply(@(x) {x},plot_matrix_passive_2,group_type');
split_plot_passive2=cellfun(@(x) mean(cat(3,x{:}),3),split_plot_passive,'UniformOutput',false );

split_group_task=splitapply(@(x) {x},averaged_imaging_task,group_type');
split_group_task2=cellfun(@(x) mean(cat(3,x{:}),3),split_group_task,'UniformOutput',false );

split_plot_task=splitapply(@(x) {x},plot_matrix_task_2,group_type');
split_plot_task2=cellfun(@(x) mean(cat(3,x{:}),3),split_plot_task,'UniformOutput',false );


split_plot_move_task=cellfun(@(x) mean(cat(3,x{:}),3),splitapply(@(x) {x},plot_move_task_2,group_type'),'UniformOutput',false );
split_plot_reaction_task=cellfun(@(x) mean(cat(3,x{:}),3),splitapply(@(x) {x},plot_reaction_task_2,group_type'),'UniformOutput',false );
%
figure('Position',[50 100 3*200 1200]);
tt = tiledlayout(1,3,'TileSpacing','tight');
% figure('Position',[50 50 800 400]);
for i=1:3

    t_type = tiledlayout(tt,7,1);
    t_type.Layout.Tile = i;
    title(t_type,nick_name{i});

    a1=nexttile(t_type);
    imagesc(split_group_passive2{i}(:,:,3))
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( a1,ap.colormap('PWG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.004.*[-1,1]);
    if i==3
        colorbar
    end
    a2=nexttile(t_type);
    imagesc(use_t_passive,-1:5,split_plot_passive2{i}')
    set(gca, 'YTick', [-0.5, 3], 'YTickLabel', {'pre','last 5 days'});ytickangle(90)
    colormap(a2, ap.colormap('PWG'));
    clim(0.002.*[-1,1]);
    yline(0.5);    xline(0.15,'Color','r')
    ylim([0.5,5.5])

    xlabel('time(s)')
    if i==3
        colorbar
    elseif i==1
    ylabel('passive raw (150ms) ')

    end

    a3=nexttile(t_type);
    imagesc(split_group_task2{i})
    axis image off;
    ap.wf_draw('ccf', 'black');
    colormap( a3,ap.colormap('PWG'));
    % clim(0.5*max(averaged_imaging{curr_animal},[],'all').*[0,1]);
    clim(0.004.*[-1,1]);
    if i==3
        colorbar
    end


    a4=nexttile(t_type);
    imagesc(use_t_task,-1:5,split_plot_task2{i}')
    set(gca, 'YTick', [-0.5, 3], 'YTickLabel', {'pre','last 5 days'});ytickangle(90)
    colormap(a4, ap.colormap('PWG'));
    clim(0.004.*[-1,1]);
    yline(0.5) ; xline(0.1,'Color','r')
    xlabel('time(s)')
    if i==3
        colorbar
    elseif i==1
        ylabel('task kernels (100ms) ')
    end
    ylim([0.5,5.5])


    a5=nexttile(t_type)
    imagesc(surround_time_points,-1:5,split_plot_move_task{i})
    colormap(a5, ap.colormap('WK'));
    yline(0.5)
    xlabel('Time to stim (s)')
    ylabel('Fraction moving')
    ylim([0.5,5.5])


    a6=nexttile(t_type)
    plot(surround_time_points,mean(split_plot_move_task{i}(3:end,:),1))
    ylim([0 1])
    xlabel('Time to stim (s)')


    a7=nexttile(t_type)
    plot( -1:5 , split_plot_reaction_task{i})
    ylim([0 1])
        xlim([1 5])

    ylabel('Reaction time (s)')
    xlabel('days')
    xline(0.5)


end
saveas(gcf,[Path 'figures\summary\compare_3_tasks_with_last_5_days'], 'jpg');
