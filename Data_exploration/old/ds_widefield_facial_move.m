
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
surround_frames = 60;
surround_t = [-surround_frames:surround_frames]./30;
period_passive_face=find(surround_t>0&surround_t<0.2);


surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
period_passive=find(t_passive>0&t_passive<0.2);

%% 绘制面部识别区域

% animals = {'DS003','DS004','DS005','DS006','DS007','DS014','DS015','DS016','AP019','DS013','DS001','DS000','DS006','AP020','AP022'};
% animals={'DS010','DS011','AP018','AP021'};
% for curr_animal=1:length(animals)
%     preload_vars = who;
% animal=animals{curr_animal};
%   fprintf('%s\n', ['start  ' animal ]);
%   raw_data_passive_face=load([Path '\mat_data\' animal '_hml_passive_audio_face.mat']);
% camera_all=raw_data_passive_face.camera_all;
%
% ap.imscroll(camera_all{1,2},surround_t(2:end))
%
%
% h = figure;imagesc(mean(camera_all{1, 1} ,3));axis image;
% roi_mask_face = roipoly;
% close(h);
% save([Path 'face_data\' animal '_face_roi.mat' ],'roi_mask_face', '-v7.3')
% clearvars('-except',preload_vars{:});
%  ap.print_progress_fraction(curr_animal,length(animals));
%
% fprintf('\n');
%
% end

%%
animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};
% animals={'DS001'}
animals_group=[ 1 1 1 1 1 1 1 2 2 3 3 3 4 4 4 4 4];

% plot_data_all=cell(2,size(animals,2));
face_naive_all = cell(2, length(animals));  % 创建一个2x1的cell数组
face_naive_all(:) = {cell([])};  % 将每个元素设置为空的cell
ca_naive_all = cell(2, length(animals));  % 创建一个2x1的cell数组
ca_naive_all(:) = {cell([])};  % 将每个元素设置为空的cell

face_trained_all = cell(2, length(animals));  % 创建一个2x1的cell数组
face_trained_all(:) = {cell([])};  % 将每个元素设置为空的cell
ca_trained_all = cell(2, length(animals));  % 创建一个2x1的cell数组
ca_trained_all(:) = {cell([])};  % 将每个元素设置为空的cell



for curr_workflow=1:2
    workflow={'visual passive','auditory passive'};
    preload_vars = who;
    %
    % figure('Position',[50 100 length(animals)*300 900]);
    % tt = tiledlayout(1,length(animals),'TileSpacing','tight');

    for curr_animal=1:length(animals)
        %
        animal=animals{curr_animal};
        fprintf('%s\n', ['start  ' animal ]);
        load([Path '\face_data\' animal '_face_roi.mat']);


        preload_vars1 = who;
        if curr_workflow==1
            raw_data_passive=load([Path '\mat_data\' animal '_lcr_passive.mat']);
            raw_data_passive_face=load([Path '\mat_data\' animal '_lcr_passive_face.mat']);
            stim_idx_b1=[-90; 0 ;90];
        elseif curr_workflow==2
            raw_data_passive=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);
            raw_data_passive_face=load([Path '\mat_data\' animal '_hml_passive_audio_face.mat']);
            stim_idx_b1=[4000 ;8000; 12000];




        end

        camera_all=raw_data_passive_face.camera_all;
        % ap.imscroll(camera_all{1,ss+1},surround_t(2:end))



        idx_buff=cell2mat(cellfun(@(x) ~isempty(x), camera_all,'UniformOutput',false));
        camera_buffer(idx_buff)=cellfun(@(x) (roi_mask_face(:))'*(reshape(x,[],120))./sum(roi_mask_face,'all'),camera_all(idx_buff),   'UniformOutput',false) ;
        % camera_buffer2(idx_buff)=cellfun(@(x) mean(x(period_passive_face)),camera_buffer(idx_buff),'UniformOutput',false);

        cell_matrix_with_nan = cellfun(@(x) ifelse(isempty(x), zeros(1,120), x), camera_buffer, 'UniformOutput', false);
        camera_buffer3=reshape(cell_matrix_with_nan,size(idx_buff));



        base_buffer=repmat({single(zeros(1,53))}, 3, 3);
        base_buffer2=repmat({single(zeros(1,53))}, 3, 3);
        base_buffer3=repmat({single(zeros(1,53))}, 3, 3);
        % base_buffer4=repmat({single(zeros(1,53))}, 3, 1);


        base_buffer(:,1)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(1)),raw_data_passive.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);
        base_buffer(:,2)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(2)),raw_data_passive.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);
        base_buffer(:,3)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(3)),raw_data_passive.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);

        % % 合并后的代码，处理多列数据
        % base_buffer = cellfun(@(baseline, idx_list) ...
        %     cellfun(@(col) baseline(:,:,:,idx_list{col}), num2cell(1:3), 'UniformOutput', false), ...
        %     cellfun(@(xxx) plab.wf.svd2px(U_master, xxx), raw_data_passive.wf_px_baseline, 'UniformOutput', false)', ...
        %     cellfun(@(idx) arrayfun(@(n) find(idx == stim_idx_b1(n)), 1:3, 'UniformOutput', false), raw_data_passive.all_groups_name_baseline, 'UniformOutput', false), ...
        %     'UniformOutput', false);




        idx_buff_wf_base=cell2mat(cellfun(@(x) ~isempty(x), base_buffer,'UniformOutput',false));
        base_buffer2(idx_buff_wf_base)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), base_buffer(idx_buff_wf_base), 'UniformOutput', false);
        base_buffer3(idx_buff_wf_base)=cellfun(@(x) mean( x(roi1(1).data.mask(:),:),1),base_buffer2(idx_buff_wf_base), 'UniformOutput', false);
        % base_buffer4(idx_buff_wf_base)=cellfun(@(x) mean(x(period_passive)),base_buffer3(idx_buff_wf_base),'UniformOutput',false);

        % passive_buffer=repmat(nan, size(raw_data_passive.wf_px,2),1 );
        % passive_buffer2=repmat(nan,  size(raw_data_passive.wf_px,2), 1);
        % passive_buffer3=repmat(nan,  size(raw_data_passive.wf_px,2), 1);
        % passive_buffer4=repmat(nan,  size(raw_data_passive.wf_px,2), 1);

        passive_buffer=repmat({single(zeros(450,420,53))}, size(raw_data_passive.wf_px,2),3 );
        passive_buffer2=repmat({single(zeros(1,53))},  size(raw_data_passive.wf_px,2), 3);
        passive_buffer3=repmat({single(zeros(1,53))},  size(raw_data_passive.wf_px,2), 3);
        % passive_buffer4=repmat({single(0)},  size(raw_data_passive.wf_px,2), 1);


        passive_buffer(:,1)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(1)),raw_data_passive.all_groups_name  ,'UniformOutput',false),'UniformOutput',false);
        passive_buffer(:,2)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(2)),raw_data_passive.all_groups_name  ,'UniformOutput',false),'UniformOutput',false);
        passive_buffer(:,3)=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_passive.wf_px ,'UniformOutput',false)',cellfun( @(idx) find(idx==stim_idx_b1(3)),raw_data_passive.all_groups_name  ,'UniformOutput',false),'UniformOutput',false);

        idx_buff_wf=cell2mat(cellfun(@(x) ~isempty(x), passive_buffer,'UniformOutput',false));

        passive_buffer2(idx_buff_wf)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), passive_buffer(idx_buff_wf), 'UniformOutput', false);
        passive_buffer3(idx_buff_wf)=cellfun(@(x) mean( x(roi1(1).data.mask(:),:),1),passive_buffer2(idx_buff_wf), 'UniformOutput', false);
        % passive_buffer4(idx_buff_wf)=cellfun(@(x) mean(x(period_passive)),passive_buffer3(idx_buff_wf),'UniformOutput',false);

        for curr_idx=1:length(raw_data_passive.workflow_day)
            buff_passive_face_idx=find(strcmp(raw_data_passive_face.workflow_day,raw_data_passive.workflow_day{curr_idx}));
            plot_camera(curr_idx,:)=camera_buffer3(buff_passive_face_idx,:);
        end



        % t_animal = tiledlayout(tt,6,1);
        % t_animal.Layout.Tile = curr_animal;
        % title(t_animal,animal);

        figure('Position',[50 50 260 900]);

        ax0=nexttile;
        % ax0=nexttile(t_animal);
        imagesc(max(camera_all{1,1}(:,:,period_passive_face),[],3))
        colormap(ax0,ap.colormap('Wk'));
        axis image;
        [B, L] = bwboundaries(roi_mask_face, 'noholes');
        % 显示边界
        hold on;
        plot(B{1}(:,2), B{1}(:,1), 'r', 'LineWidth', 1);



        % ax12= nexttile(t_animal)
        ax12= nexttile
        plot_naive=cell2mat(reshape(camera_buffer3(1:3,:),[],1));
        for i = 1:3
            % 提取子矩阵并排除全零行
            filteredMatrix_n = plot_naive((i-1)*3+1:i*3, :);
            filteredMatrix_n = filteredMatrix_n(any(filteredMatrix_n, 2), :);
            % 计算列平均值并存储结果
            result_naive(i, :) = mean(filteredMatrix_n, 1, 'omitnan'); % 忽略NaN值
        end
        set(ax12, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
        plot(surround_t(2:end), result_naive')
        title('naive')
        ylabel('face movement')
        xlabel('time(s)')
        % legend(num2str(stim_idx_b1),'Location', 'eastoutside')


        ax11= nexttile
        % ax11= nexttile(t_animal)

        trained_idx=find(raw_data_passive.workflow_type==1& (raw_data_passive.learned_day==1)'  )
        if isempty(trained_idx)
        trained_idx=find(raw_data_passive.workflow_type==1 )

        end
        plot_trained=cell2mat(reshape(plot_camera(trained_idx,:),[],1));
        for i = 1:3
            % 提取子矩阵并排除全零行
            filteredMatrix_t = plot_trained((i-1)*(size(plot_trained,1)/3)+1:i*(size(plot_trained,1)/3), :);
            filteredMatrix_t = filteredMatrix_t(any(filteredMatrix_t, 2), :);
            % 计算列平均值并存储结果
            result_trained(i, :) = mean(filteredMatrix_t, 1, 'omitnan'); % 忽略NaN值
        end
        plot(surround_t(2:end), result_trained')
        set(ax11, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
        ylabel('face movement')
        xlabel('time(s)')

        % legend(num2str(stim_idx_b1),'Location', 'eastoutside')
        title('trained')




        % ax22= nexttile(t_animal)
        ax22= nexttile
        plot_naive_ca=cell2mat(reshape(base_buffer3,[],1));
        for i = 1:3
            % 提取子矩阵并排除全零行
            filteredMatrix_n = plot_naive_ca((i-1)*3+1:i*3, :);
            filteredMatrix_n = filteredMatrix_n(any(filteredMatrix_n, 2), :);
            % 计算列平均值并存储结果
            result_naive_ca(i, :) = mean(filteredMatrix_n, 1, 'omitnan'); % 忽略NaN值
        end
        % set(ax22, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
        plot(t_passive,result_naive_ca')
        set(ax22, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
        ylim(0.002.*[-0.5,1]);
        title('naive')
        % legend(num2str(stim_idx_b1),'Location', 'eastoutside')
        xlabel('time(s)')
        ylabel('df/f')

        % ax21= nexttile(t_animal)
        ax21= nexttile
        % trained_idx=find(raw_data_passive.workflow_type==1& (raw_data_passive.learned_day==1)'  );
        plot_trained_ca=cell2mat(reshape(passive_buffer3(trained_idx,:),[],1));
        for i = 1:3
            % 提取子矩阵并排除全零行
            filteredMatrix_t = plot_trained_ca((i-1)*(size(plot_trained_ca,1)/3)+1:i*(size(plot_trained_ca,1)/3), :);
            filteredMatrix_t = filteredMatrix_t(any(filteredMatrix_t, 2), :);
            % 计算列平均值并存储结果
            result_trained_ca(i, :) = mean(filteredMatrix_t, 1, 'omitnan'); % 忽略NaN值
        end
        plot(t_passive,result_trained_ca')
        set(ax21, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
        ylim(0.002.*[-0.5,1]);

        % legend(num2str(stim_idx_b1),'Location', 'eastoutside')
        title('trained')
        xlabel('time(s)')
        ylabel('df/f')



        % nexttile(t_animal)
        nexttile
        camera_image=cell2mat(reshape([camera_buffer3(1:3,:);plot_camera],[],1));

        yyaxis left;
        plot_face_days=reshape(mean(camera_image(:,period_passive_face),2),[],3);
        plot(plot_face_days([1:3 3+find(raw_data_passive.workflow_type==curr_workflow)'],:)) ;ylabel('face movement');
        set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
        ca_image=cell2mat(reshape([base_buffer3; passive_buffer3],[],1));
        yyaxis right;
        plot_ca_days=reshape(mean(ca_image(:,period_passive),2),[],3);
        plot(plot_ca_days([1:3 3+find(raw_data_passive.workflow_type==curr_workflow)'],:),'LineWidth',2);ylabel('dF/F')
        set(gca, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0]); % 蓝、黑、红
        xlabel('days')


        % hold on
        % auto_y=ylim;
        % if any(raw_data_passive.workflow_type==1)
        %     plot(3+find(raw_data_passive.workflow_type==1),(auto_y(1)+0.1)*ones(length(find(raw_data_passive.workflow_type==1)),1),'-b')
        % end
        % if any(raw_data_passive.workflow_type==2)
        %     plot(3+find(raw_data_passive.workflow_type==2),(auto_y(1)+0.1)*ones(length(find(raw_data_passive.workflow_type==2)),1),'-r')
        % end
        % plot([1:3],(auto_y(1)+0.1)*ones(3,1),'-k')
        % yyaxis right;plot(mean(ca_image(:,period_passive),2));ylabel('dF/F')

        sgtitle([animal ' ' workflow{curr_workflow}])

        saveas(gcf,[Path 'figures\' workflow{curr_workflow} '_face_move_vs_mPFC_' animal], 'jpg');
        close all
       
           
        face_naive_all{curr_workflow,curr_animal}= result_naive;
        ca_naive_all{curr_workflow,curr_animal}=result_naive_ca;
        face_trained_all{curr_workflow,curr_animal}= result_trained;
        ca_trained_all{curr_workflow,curr_animal}=result_trained_ca;

        % saveas(gcf,[Path 'figures\mpfc vs facial move_' animal '_' workflow{ss} ], 'jpg');

        clearvars('-except',preload_vars1{:});
        ap.print_progress_fraction(curr_animal,length(animals));

        fprintf('\n');

    end

    % saveas(gcf,[Path 'figures\' workflow{curr_workflow} '_face_move_vs_mPFC_' strjoin(animals, '_')], 'jpg');

    clearvars('-except',preload_vars{:});

end

save([Path 'mat_data\'  'all_mice_data_face_vs_imaging.mat' ],'face_naive_all','ca_naive_all','face_trained_all','ca_trained_all','-v7.3')
%%
load([Path 'mat_data\'  'all_mice_data_face_vs_imaging.mat' ])

animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020', 'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016'};

animals_group=[ 1 1 5 5 1 1 5 2 2 3 3 3 9 4 4 9 4];
% animals_group=[ 1 1 1 1 1 1 1 2 2 3 3 3 4 4 4 4 4];

lcr_face1=face_trained_all(1,animals_group==9);
lcr_face4=face_trained_all(1,animals_group==4);
hml_face1=face_trained_all(2,animals_group==9);
hml_face4=face_trained_all(2,animals_group==4);

lcr_naive_face1=face_naive_all(1,animals_group==9);
lcr_naive_face4=face_naive_all(1,animals_group==4);
hml_naive_face1=face_naive_all(2,animals_group==9);
hml_naive_face4=face_naive_all(2,animals_group==4);

figure;

nexttile
plot(surround_t(2:end),mean(cat(3,lcr_naive_face1{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('V-A-naive-visual')
ylim([6 12])

nexttile
plot(surround_t(2:end),mean(cat(3,lcr_naive_face4{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('A-V-naive-visual')
ylim([6 12])

nexttile
plot(surround_t(2:end),mean(cat(3,lcr_face1{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('V-A-trained-visual')
ylim([6 12])

nexttile
plot(surround_t(2:end),mean(cat(3,lcr_face4{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('A-V-trained-visual')
ylim([6 12])


nexttile
plot(surround_t(2:end),mean(cat(3,hml_naive_face1{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('V-A-naive-auditory')
ylim([6 12])

nexttile
plot(surround_t(2:end),mean(cat(3,hml_naive_face4{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('A-V-naive-auditory')
ylim([6 12])


nexttile
plot(surround_t(2:end),mean(cat(3,hml_face1{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('V-A-trained-auditory')
ylim([6 12])

nexttile
plot(surround_t(2:end),mean(cat(3,hml_face4{:}),3)')
set(gca, 'ColorOrder', [0.5 0.5 1; 0.5 0.5 0.5; 1 0.5 0.5]); % 蓝、黑、红
title('A-V-trained-auditory')
ylim([6 12])



