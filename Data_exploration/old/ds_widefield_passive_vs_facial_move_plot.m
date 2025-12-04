clear all
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);

Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';
surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_passive = surround_window(1):1/surround_samplerate:surround_window(2);
period=find(t_passive>0&t_passive<0.2);

surround_frames=60;
surround_t = [-surround_frames+1:surround_frames]./30;
period_passive_face=find(surround_t>0&surround_t<0.2);

animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
passive_workflow_all={'lcr_passive','hml_passive_audio'};
% passive_workflow_all={'hml_passive_audio'};

% allmice_facial=cell(length(animals),2);
% allmice_ca=cell(length(animals),2);
allmice_ca = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_facial = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_ca_across_time = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充
allmice_facials_across_time = repmat({cell(4, 3)}, length(animals), 2); % 创建指定大小的cell数组并填充



for curr_workflow=1:length(passive_workflow_all)

    passive_workflow=passive_workflow_all{curr_workflow};
    if strcmp(passive_workflow,'lcr_passive')
        conditions = [-90, 0, 90];
    elseif strcmp(passive_workflow,'hml_passive_audio')
        conditions = [4000, 8000, 12000];
    end


    for curr_animal=1:length(animals)
        main_preload_vars = who;

        animal=animals{curr_animal};


        if ~isempty(dir(fullfile([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ])))
            data_face=load([Path 'mat_data\passive_vs_face\' animal '_' passive_workflow '_passive_vs_face.mat' ]);
            data_passive_single=load([Path 'mat_data\' passive_workflow '\' animal '_' passive_workflow '_single_trial.mat' ]);
            data_passive=load([Path 'mat_data\' passive_workflow '\' animal '_' passive_workflow '.mat' ]);

  

            figure('Position',[50 50 1200 900]);
            stage_type={'baseline','visual','auditory','mixed'};
            scale=0.005;
            for curr_oder=0:3
                if curr_oder==0
                    learned=0;
                else learned=1;
                end

                if curr_oder==0|| curr_oder==3
                    numbers=3;
                else numbers=5;
                end
                %% gain
                mean_gain = mean(data_face.camera_task_gain, 'omitnan');
                 data_face.camera_task_gain(isnan(data_face.camera_task_gain)) = mean_gain;
                nonemptyidx=cellfun(@(x) ~isempty(x), data_face.camera_plot,'UniformOutput',true);
                % data.camera_plot_baslined_normalized(nonemptyidx)= cellfun(@(x,y) (x-mean(x(surround_t<0,:),'all'))/y,data.camera_plot(nonemptyidx),num2cell(data.camera_task_gain(nonemptyidx)),'UniformOutput',false);
                % data.camera_plot_baslined_normalized(nonemptyidx)= cellfun(@(x) (x-mean(x(surround_t<0,:),'all')),data.camera_plot(nonemptyidx),'UniformOutput',false);

                data_face.camera_plot_baslined_normalized(nonemptyidx)= cellfun(@(x) (x),data_face.camera_plot(nonemptyidx),'UniformOutput',false);

                all_idx=find(data_passive.workflow_type==curr_oder&data_passive.learned_day'==learned, numbers, "last");
                index_type=data_face.trial_type(all_idx);
                index_state=data_passive_single.trial_state(all_idx);

                if isempty(index_type)
                    disp(['跳出' stage_type{curr_oder+1}]);
                    continue
                end

                    %%对face movement的数据进行处理

                    %在该stage下，所有符合条件的日子的数据：
                    facial_data=data_face.camera_plot_baslined_normalized(all_idx);
                    % facial_data=data.camera_plot(data.workflow_type==i&data.learned_day==learned);
                    % 将每一天的数据根据不同stim condition分成三类
                    % data_facial  =  arrayfun(@(cond) cellfun(@(x, tr_type, tr_state) x(:, tr_type == cond & tr_state == 1), facial_data, index_type, index_state, 'UniformOutput', false), conditions, 'UniformOutput', false);

                    data_facial  =  arrayfun(@(cond) cellfun(@(x, tr_type, tr_state) x(:, tr_type == cond ), facial_data, index_type', index_state, 'UniformOutput', false), conditions, 'UniformOutput', false);
                    % 每个数据非0的索引
                    idx_0=cellfun(@(data) cellfun(@(x) find(any(x~=0)), data, 'UniformOutput', false) ,data_facial,'UniformOutput',false);
                    % 删除全0数据
                    data_facial= cellfun(@(data,idx) cellfun(@(x,y) x(:,y),data,idx,'UniformOutput',false ),data_facial,idx_0,'UniformOutput',false);
                    % 删除全空数据
                    data_facial = cellfun(@(x) x(~cellfun('isempty', x)), data_facial, 'UniformOutput', false);
                    % 把不同天的相同condition的数据整合
                    data_facial_all=cellfun(@(x) cat(2,x{:}),data_facial,'UniformOutput',false);

                    % 对face movement across time 进行平均得到每个trial中face movement在给定time window 下的平均值
                    data_facial_all2= cellfun(@(y) mean(y(period_passive_face ,:),1), data_facial_all,'UniformOutput',false);
                    % 对face movement across time 所有trial进行平均，得到3个condition下的随时间变化的值
                    data_facial_mean=cellfun(@(x) mean(x,2) , data_facial_all,'UniformOutput',false);

                    allmice_facial{curr_animal,curr_workflow}(curr_oder+1,:)=data_facial_all2;
                    allmice_facials_across_time{curr_animal,curr_workflow}(curr_oder+1,:)=data_facial_all;

                    %% 对 roi后的成像数据进行处理
                     imagings=cellfun(@(x,y) y, data_face.image_plot(all_idx),data_face.image_plot_barrel(all_idx),'UniformOutput',false);
                     % imagings=data.image_plot(data.workflow_type==i&data.learned_day==learned);

                    % data_ca2 =  arrayfun(@(cond) cellfun(@(x, tr_type, tr_state) x(:, tr_type == cond & tr_state == 1), imagings, index_type, index_state, 'UniformOutput', false), conditions, 'UniformOutput', false);
                    data_ca2 =  arrayfun(@(cond) cellfun(@(x, tr_type, tr_state) x(:, tr_type == cond ), imagings, index_type, index_state', 'UniformOutput', false), conditions, 'UniformOutput', false);
                    
                    data_ca2= cellfun(@(data,idx) cellfun(@(x,y) x(:,y),data,idx','UniformOutput',false ),data_ca2,idx_0,'UniformOutput',false);
                    data_ca2 = cellfun(@(x) x(~cellfun('isempty', x)), data_ca2, 'UniformOutput', false);

                    data_ca2_all=cellfun(@(x) cat(2,x{:}),data_ca2,'UniformOutput',false);
                    data_ca2_all2=cellfun(@(y) mean(y(period ,:),1) , data_ca2_all,'UniformOutput',false);
                    data_ca2_mean=cellfun(@(y) mean(y,2) , data_ca2_all,'UniformOutput',false);

                    allmice_ca{curr_animal,curr_workflow}(curr_oder+1,:)=data_ca2_all2;
                    allmice_ca_across_time{curr_animal,curr_workflow}(curr_oder+1,:)=data_ca2_all;

                    % 
                    % % 整个图像的数据进行处理
                    % 
                    % whole_image=cellfun(@(x) x, data_passive_single.wf_px_all (all_idx),'UniformOutput',false);
                    % data_whole_image=arrayfun(@(cond) cellfun(@(x, a1) x(:,:, a1 == cond ), whole_image', index_type, 'UniformOutput', false), conditions, 'UniformOutput', false);
                    % 
                    % data_whole_image= cellfun(@(data,idx) cellfun(@(x,y) x(:,:,y),data,idx','UniformOutput',false ),data_whole_image,idx_0,'UniformOutput',false);
                    % data_whole_image = cellfun(@(x) x(~cellfun('isempty', x)), data_whole_image, 'UniformOutput', false);
                    % 
                    % data_whole_image_all=cellfun(@(x) cat(3,x{:}),data_whole_image,'UniformOutput',false);
                    % 
                    % data_whole_image_means = cellfun(@(x,y) arrayfun(@(g) mean(x(:,:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g), 3,'omitnan'), 1:4,'UniformOutput',false)  ,data_whole_image_all, data_facial_all2,'UniformOutput',false);
                    % data_whole_image_means2=cellfun(@(x) cat(3,x{:}),data_whole_image_means,'UniformOutput',false);
                    % wf_px = cellfun(@(x) plab.wf.svd2px(U_master,x), data_whole_image_means2, 'UniformOutput', false);
                    % % ap.imscroll(wf_px{2},t_passive)
                    % % axis image;ap.wf_draw('ccf');
                    % % clim(scale.*[-1,1]);
                    % % colormap(ap.colormap('PWG',[],1.5));
                    % % set(gcf,'name',sprintf('%s %s %s',animal,stage_type{i+1},passive_workflow));


                     if ~isempty(data_ca2_all2{1})
                        group_means = cellfun(@(x) arrayfun(@(g) mean(x(discretize(x, [-Inf, quantile(x, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4),data_facial_all2,'UniformOutput',false);
                        imaging_means = cellfun(@(x,y) arrayfun(@(g) mean(x(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4)  ,data_ca2_all2, data_facial_all2,'UniformOutput',false);

                        nexttile;hold on
                        cellfun(@(x,y) plot(x,y,"LineWidth",2),group_means,imaging_means,'UniformOutput',false)
                        set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
                        ylabel('df/f')
                        xlabel('face movement')
                        ylim(0.001.*[-1 5])
                        title(stage_type{curr_oder+1})


                        % nexttile;hold on
                        % cellfun(@(x,y) scatter(x,y),data_facial_all2,data_all2,'UniformOutput',false)
                        % set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红


                        nexttile;hold on
                        cellfun(@(x) plot(t_passive,x,"LineWidth",2),data_ca2_mean,'UniformOutput',false)
                        ylim(0.001*[-1 5])
                        ylabel('df/f');xlabel('time(s)')
                        set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红

                        nexttile; hold on

                        cellfun(@(x) plot(surround_t,x,"LineWidth",2),data_facial_mean,'UniformOutput',false)

                        % ylim([-1 3])

                        ylabel('face movement');xlabel('time(s)')

                        set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
                    else
                        nexttile
                        % nexttile
                        nexttile
                        nexttile
                    end
               
                end

                sgtitle([animal strrep(passive_workflow,'_','\_')]);
                drawnow
                % saveas(gcf,[Path 'figures\face vs mpfc\facial_vs_mpfc_plot_'   passive_workflow  animal], 'jpg');

                clearvars('-except',main_preload_vars{:});
            end

        end
    
end
    
     
    close all
 %%
    animals_group=[ 1 1 1 1 1 5 5 2 2 3 3 3 4 4 4 4 4];
    % cellfun(@data)   cellfun(@(x) x    , data, 'UniformOutput',false )   ,allmice_ca(animals_group==1),'UniformOutput',false)

   
    select_group=1;

    for curr_workflow=1:2
        passive_workflow=passive_workflow_all{curr_workflow};

        if strcmp(passive_workflow,'lcr_passive')
            conditions = [-90, 0, 90];
        else
            conditions = [4000, 8000, 12000];
        end

        %%mean
        allmice_ca11=allmice_ca(animals_group==select_group,curr_workflow);
        allmice_facial11=allmice_facial(animals_group==select_group,curr_workflow);
        image_group=cell(4,3);
        facial_group=cell(4,3);
        image_group = cellfun(@(varargin) [varargin{:}], image_group, allmice_ca11{:}, 'UniformOutput', false);
        facial_group = cellfun(@(varargin) [varargin{:}], facial_group, allmice_facial11{:}, 'UniformOutput', false);

        group_means = cellfun(@(x) arrayfun(@(g) mean(x(discretize(x, [-Inf, quantile(x, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4),facial_group,'UniformOutput',false);
         % group_means_single = cellfun(@(x) arrayfun(@(g) x(discretize(x, [-Inf, quantile(x, [0.25, 0.5, 0.75]), Inf]) == g), 1:4,'UniformOutput',false),facial_group,'UniformOutput',false);

        imaging_means = cellfun(@(x,y) arrayfun(@(g) mean(x(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4)  ,image_group, facial_group,'UniformOutput',false);
        imaging_sem = cellfun(@(x,y) arrayfun(@(g) std(x(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g), 'omitnan'), 1:4)./arrayfun(@(g) sqrt(length(y(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g))), 1:4)  ,image_group, facial_group,'UniformOutput',false);

        %%across time
        allmice_ca11_across_time=allmice_ca_across_time(animals_group==select_group,curr_workflow);
        allmice_facial11_across_time=allmice_facials_across_time(animals_group==select_group,curr_workflow);
        image_group_across_time=cell(4,3);
        facial_group_across_time=cell(4,3);
        image_group_across_time = cellfun(@(varargin) [varargin{:}], image_group_across_time, allmice_ca11_across_time{:}, 'UniformOutput', false);
        facial_group_across_time = cellfun(@(varargin) [varargin{:}], facial_group_across_time, allmice_facial11_across_time{:}, 'UniformOutput', false);

        facial_means_across_time = cellfun(@(x,y) arrayfun(@(g) mean(x(:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),2,'omitnan'), 1:4, 'UniformOutput', false)  ,facial_group_across_time, facial_group,'UniformOutput',false);
        facial_sem_across_time = cellfun(@(x,y)   cellfun(@(q,w) q/w, arrayfun(@(g) std(x(:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),0,2,'omitnan'), 1:4, 'UniformOutput', false) ,arrayfun(@(g) sqrt(length(y(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g))), 1:4, 'UniformOutput', false) , 'UniformOutput', false),facial_group_across_time, facial_group,'UniformOutput',false);

        imaging_means_across_time = cellfun(@(x,y) arrayfun(@(g) mean(x(:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),2,'omitnan'), 1:4, 'UniformOutput', false)  ,image_group_across_time, facial_group,'UniformOutput',false);
        imaging_sem_across_time = cellfun(@(x,y)   cellfun(@(q,w) q/w, arrayfun(@(g) std(x(:,discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g),0,2,'omitnan'), 1:4, 'UniformOutput', false) ,arrayfun(@(g) sqrt(length(y(discretize(y, [-Inf, quantile(y, [0.25, 0.5, 0.75]), Inf]) == g))), 1:4, 'UniformOutput', false) , 'UniformOutput', false),image_group_across_time, facial_group,'UniformOutput',false);





        stage_type={'baseline','visual','auditory','mixed'};
        figure('Position',[50 50 1200 900])
        for curr_oder=1:4
            nexttile;hold on
            % cellfun(@(x,y) plot(x,y,"LineWidth",2),group_means(i,:),imaging_means(i,:),'UniformOutput',false)
            cellfun(@(x,y,z) errorbar(x,y,z,"LineWidth",2),group_means(curr_oder,:),imaging_means(curr_oder,:),imaging_sem(curr_oder,:),'UniformOutput',false)

            set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
            ylabel('df/f')
            xlabel('face movement')
            ylim(0.001.*[-1 3])
            title(stage_type{curr_oder})



            % figure;hold on
            nexttile;hold on
            plot_mean=imaging_means_across_time(curr_oder,:);
            plot_sem=imaging_sem_across_time(curr_oder,:);
            color_scale={[0, 0, 0],[0.3, 0.2, 0.1],[0.6, 0.4, 0.2],[0.9, 0.75, 0.43]};
            cellfun(@(x,y,z) ap.errorfill(t_passive,x,y,z,0.1,0.5),plot_mean{find(conditions==8000|conditions==90)},plot_sem{find(conditions==8000|conditions==90)},color_scale,'UniformOutput',false);
            ylim(0.001.*[-1 6])
            ylabel('df/f')
            xlabel('time(s)')
            xline(0)
            xline(0.1)

            % figure;hold on
            nexttile;hold on
            plot_facial_mean=facial_means_across_time(curr_oder,:);
            plot_facial_sem=facial_sem_across_time(curr_oder,:);
            color_scale={[0, 0, 0],[0.3, 0.2, 0.1],[0.6, 0.4, 0.2],[0.9, 0.75, 0.43]};
            cellfun(@(x,y,z) ap.errorfill(surround_t,x,y,z,0.1,0.5),plot_facial_mean{find(conditions==8000|conditions==90)},plot_facial_sem{find(conditions==8000|conditions==90)},color_scale,'UniformOutput',false);

            ylim([-2 2])
            ylabel('face movement')
            xlabel('time(s)')


        end

        if select_group==1
            sgtitle(['V-A ' strrep(passive_workflow_all{curr_workflow},'_','\_')  ])
            saveas(gcf, fullfile(Path, 'figures', ['V-A ' passive_workflow_all{curr_workflow} ]), 'jpg');
        elseif select_group==4
            sgtitle(['A-V ' strrep(passive_workflow_all{curr_workflow},'_','\_')  ])
            saveas(gcf, fullfile(Path, 'figures\', ['A-V ' passive_workflow_all{curr_workflow} ]), 'jpg');
        end
    end

%%
 for curr_workflow=1
        passive_workflow=passive_workflow_all{curr_workflow};

        if strcmp(passive_workflow,'lcr_passive')
            conditions = [-90, 0, 90];
        elseif strcmp(passive_workflow,'hml_passive_audio')
            conditions = [4000, 8000, 12000];
        end

figure('Position',[50 50 1500 500]); 

for curr_oder=1:3
allmice_ca11=allmice_ca(:,curr_workflow);
qq_image= cellfun(@(x) mean(double(x{1,curr_oder}),'omitnan'),allmice_ca11,'UniformOutput',true);
allmice_facial11=allmice_facial(:,curr_workflow);
qq_face=cellfun(@(x) mean(x{1,curr_oder},'omitnan'),allmice_facial11,'UniformOutput',true);


nexttile
hold on
scatter(qq_face,qq_image)
% title('mPFC activities vs behavior in audio task')
 xlabel('face movement');ylabel('dF/F');
 xlim([-0.5 1]); ylim(0.0001*[-2 20])
text(qq_face, qq_image, animals, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
[R(curr_oder), P(curr_oder)] = corr(qq_face, qq_image, 'Rows', 'complete');
title(num2str(conditions(curr_oder)));
text(-0.5, 0.002, sprintf('R = %.2f, p = %.4f', R(curr_oder), P(curr_oder)), ...
    'FontSize', 12, 'Color', 'red', 'VerticalAlignment', 'top');
end


sgtitle([strrep(passive_workflow,'_','\_') ' in naive stage of single mouse'])
saveas(gcf,[Path 'figures\face vs mpfc\scatter of face move vs mPFC in naive stage  in ' passive_workflow ' of single mouse'], 'jpg');

 end

