clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')


data_passive=load([ Path 'summary_data\passive kernels of images crossday.mat']);
data_task=load([ Path 'summary_data\task kernels of images crossday.mat']);
data_behavior=load([ Path 'summary_data\behavior.mat']);
surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_kernels=1/surround_samplerate*[-10:30];
kernels_period=t_kernels>=-0.1& t_kernels<=0.3;


surround_window_passive = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

%% stage 1
figure('Position',[50 50 1000 400])
used_area=[1  3 ]

t1 = tiledlayout(length(used_area), 6, 'TileSpacing', 'tight', 'Padding', 'tight');

title_images={'pre learn','post learn'};
title_area={'l-mPFC','r-mPFC','l-aPFC','r-aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
scale1=0.0004;

Color={'B','R'};
colors{1} = { [0 0 1],[1 0 0]}; % 定义颜色
colors{2} = { [0.5 0.5 1],[1 0.5 0.5]}; % 定义颜色
color_roi={[1 0.5 1],[ 0.5 1 0.5]}
for curr_roi=1:length(used_area)
    for curr_group=1:2
        performance=data_behavior.performance_align{curr_group};
        temp_image=permute(nanmean(cat(3,data_task.buf3_roi{curr_group}{used_area(curr_roi)}{:}),2),[1,3,2]);
        a1=nexttile(6*curr_roi-6+3*curr_group-3+1)
        imagesc(t_kernels,[], temp_image')
        ylim([0.5 8.5])
        % ylim([0.5 26.5])
        xlim([-0.2 0.5])
        yline(3.5);
        yline(8.5);
        yline(10.5);
        yline(15.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a1, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        if curr_group==1
            yticks([2  6 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
            yticklabels(title_images); % 设置对应的标签
        else
            yticks([])
        end
        if curr_roi==1
            title('task','FontWeight','normal')
        end



        a3=nexttile(6*curr_roi-6+3*curr_group-3+2)
        temp_image_p=permute(nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{used_area(curr_roi)}{:}),3),[1,4,2,3]);
        imagesc(t_kernels,[], temp_image_p(:,:,4-curr_group)');
        ylim([3.5 11.5])
        xlim([-0.2 0.5])
        yline(6.5);
        clim(scale1 .* [0, 1]);
        colormap(a3, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        yticks([ ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        if curr_roi==1
            title('passive','FontWeight','normal')
        end


        % 
        % a4= nexttile(6*curr_roi-6+3*curr_group-3+3)
        % 
        % hold on
        % temp_mean=nanmean(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1);
        % temp_error=std(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},0,1,'omitmissing')/sqrt(size(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1));
        % % hold on
        % ap.errorfill(1:8,temp_mean(1:8),temp_error(1:8),colors{1}{curr_group},0.1,0.5)
        % 
        % temp_mean=permute(nanmean(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),2),[3,2,1]);
        % temp_error=permute(std(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),0,2,'omitmissing'),[3,2,1])./...
        %     sqrt(size(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),2));
        % yyaxis left
        % % 激活左 y 轴
        % ap.errorfill(1:8,temp_mean(4:11),temp_error(4:11),colors{2}{curr_group},0.1,0.5)
        % 
        % xlim([1 8])
        % ylim(scale1 .* [0, 1]);
        % xticks([2 6]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        % xticklabels(title_images); % 设置对应的标签
        % ylabel('\Delta F/F')
        % xline(3.5);
        % 
        % yyaxis right
        % set(gca, 'YColor', [0.5 0.5 0.5])
        % temp_mean=nanmean(cat(3,performance{:}),3);
        % temp_error=std(cat(3,performance{:}),0,3,'omitmissing')./sqrt(size(performance,1));
        % ap.errorfill(1:8,temp_mean(1:8),temp_error(1:8),[0.8 0.8 0.8],0.1,0.5)
        % ylabel('performance')
        % yticks(ylim); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        % if curr_roi==1
        %     legend(a4,{'','task','','passive'},'Location','northeast','Box','off')
        % end
        % 
        % temp_task0=data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)};
        % 
        % temp_passive0=permute(data_passive.buf3_roi_peak{curr_group}{curr_group}{used_area(curr_roi)}(4-curr_group,:,:),[2,3,1]);
        % temp_result=(temp_task0(:,1:8)-temp_passive0(:,4:11))./(temp_task0(:,1:8)+temp_passive0(:,4:11));
        % temp_diff_mean=nanmean(temp_result,1);
        % temp_diff_error=std(temp_result,0,1,'omitmissing')./sqrt(size(temp_result,1));



    end




end

    drawnow


colors_1{1}=[[0 0 1];[0.5 0.5 1]];
colors_1{2}=[[1 0 0];[1 0.5 0.5]];
    
curr_mod=1;
slope_pass=cell(2,1)
slope_task=cell(2,1)
for curr_group=1:2
    if curr_group==1
        animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        group_name='VA';
        % order=[1 2]
    else
        animals = {'DS000','DS004','DS014','DS015','DS016'};
        group_name='AV';
        % order=[2 1]
    end
    Mod_name={'Mod1','Mod2'}
    roi_name={'l-mPFC','l-aPFC'}

  

    if  (curr_group==1 & curr_mod==1) | (curr_group==2 & curr_mod==2) 
        passive='lcr_passive';
        n1_name='visual position';
        used_stim=3; 

    elseif (curr_group==2 & curr_mod==1) | (curr_group==1 & curr_mod==2) 

        passive='hml_passive_audio';
        n1_name='audio volume';
        used_stim=2;

    end



        tem_perform_passive=cell(length(animals),1);
        tem_perform_task=cell(length(animals),1);

        tem_mpfc_passive_data=cell(length(animals),1);
        tem_mpfc_task_data=cell(length(animals),1);

        tem_learned_day_passive=cell(length(animals),1);
        tem_learned_day_task=cell(length(animals),1);
        
        tem_corr_task=cell(length(animals),1);
        tem_corr_passive=cell(length(animals),1);


        for curr_animal=1:length(animals)
            animal=animals{curr_animal};
            data_behavior_single=load([Path  '\behavior\' animal '_behavior.mat' ]);
            data_passive_wf=load(fullfile(Path,passive,[animal '_' passive '.mat']));
            data_task_wf=load(fullfile(Path,'task',[animal '_task.mat']));

            wf_passive_kernels=...
                cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),data_passive_wf.wf_px_kernels,'UniformOutput',false);
            image_all_passive_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),wf_passive_kernels,'UniformOutput',false);
            temp_passive=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)) , image_all_passive_mean, 'UniformOutput', false);
            passive_mPFC=arrayfun(@(id) cellfun(@(z) mean(z(roi1(id).data.mask(:),:),1),...
                temp_passive, 'UniformOutput', false),[1 3], 'UniformOutput', false);


            wf_task_kernels=...
                cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{1},1)),x{1}),data_task_wf.wf_px_task_kernels,'UniformOutput',false);

            image_all_task_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),wf_task_kernels,'UniformOutput',false);
            temp_task=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)) , image_all_task_mean, 'UniformOutput', false);
            task_mPFC=arrayfun(@(id) cellfun(@(z) mean(z(roi1(id).data.mask(:),1),1),...
                temp_task, 'UniformOutput', true),[1 3], 'UniformOutput', false);





            idx_0= cellfun(@(y) strcmp( y,n1_name),...
                data_behavior_single.workflow_name, 'UniformOutput', true);
            day_behavior = data_behavior_single.workflow_day(idx_0);
            performance=(data_behavior_single.stim2lastmove_mad_null(idx_0)-data_behavior_single.stim2lastmove_mad(idx_0))./...
                (data_behavior_single.stim2lastmove_mad_null(idx_0)+data_behavior_single.stim2lastmove_mad(idx_0));
            day_learned=data_behavior_single.rxn_l_mad_p(idx_0)<0.01;
           
            temp_vel=data_behavior_single.frac_velocity_stimalign(idx_0,1);
            temp_vel1= cellfun(@(x) corr(x(:,500:600)') ,temp_vel,'UniformOutput',false );
            temp_corr =cellfun(@(x) nanmean(x(~eye(size(x)))) ,temp_vel1,'UniformOutput',true);


            day_idx_passive = data_passive_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
                data_passive_wf.workflow_type_name_merge, 'UniformOutput', true));
            wf_passive=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
                data_passive_wf.workflow_type_name_merge, 'UniformOutput', true))',passive_mPFC, 'UniformOutput', false);


            [~, temp_idx_passive] = ismember( day_idx_passive,day_behavior);
            performance_passive=performance(temp_idx_passive);
            day_learned_passive=day_learned(temp_idx_passive);

            corr_passive=temp_corr(temp_idx_passive);



            day_idx_task = data_task_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
                data_task_wf.workflow_type_name_merge, 'UniformOutput', true));
            wf_task=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
                data_task_wf.workflow_type_name_merge, 'UniformOutput', true))',task_mPFC, 'UniformOutput', false);


            [~, temp_idx_task] = ismember( day_idx_task,day_behavior);
            performance_task=performance(temp_idx_task);
            day_learned_task=day_learned(temp_idx_task);

            corr_task=temp_corr(temp_idx_task);


            tem_mpfc_task_data{curr_animal}=wf_task;
            tem_mpfc_passive_data{curr_animal}=cellfun(@(x) cat(1,x{:})  ,wf_passive,'UniformOutput',false);

            tem_perform_task{curr_animal}=performance_task;
            tem_perform_passive{curr_animal}=performance_passive;

            tem_learned_day_passive{curr_animal}=day_learned_passive;
            tem_learned_day_task{curr_animal}=day_learned_task;

            tem_corr_task{curr_animal}=corr_task;
            tem_corr_passive{curr_animal}=corr_passive;


        end

      
        for curr_roi=1
            tem_mpfc_passive_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_passive_data,'UniformOutput',true);
            tem_mpfc_task_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_task_data,'UniformOutput',true);
            data1_passive=cat(1,tem_mpfc_passive_data1{:});
            data1_task=cat(1,tem_mpfc_task_data1{:});

            performs_passive=cell2mat(tem_perform_passive);
            performs_task=cell2mat(tem_perform_task);

            corr_passive=cell2mat(tem_corr_passive);
            corr_task=cell2mat(tem_corr_task);


            % if curr_roi==1
            %     nexttile(curr_group)
            % else
            %     nexttile(2+curr_group)
            % end

            nexttile(6*curr_roi-6+3*curr_group-3+3)
            hold on
            % p_task = polyfit(performs_task(cell2mat(tem_learned_day_task)==1), data1_task(cell2mat(tem_learned_day_task)==1)', 1);       % 一阶多项式拟合：y = p(1)*x + p(2)

            p_task = polyfit(performs_task, data1_task, 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
            x_fit_task = linspace(0, 1, 2);
            y_fit_task = polyval(p_task, x_fit_task);
            plot(x_fit_task, y_fit_task, '-', 'LineWidth', 2,'Color',colors_1{curr_group}(1,:));

            % p_passive = polyfit(performs_passive(cell2mat(tem_learned_day_passive)==1),  data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim)', 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
            p_passive = polyfit(performs_passive,  data1_passive(:,used_stim), 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
           
            x_fit_passive = linspace(0, 1, 2);
            y_fit_passive = polyval(p_passive, x_fit_passive);
            plot(x_fit_passive, y_fit_passive, '-', 'LineWidth', 2,'Color',colors_1{curr_group}(2,:));



            slope_pass{curr_group}{curr_roi}= cellfun(@(perform,peak,learned) diff(polyval( polyfit( perform, peak(:,used_stim),1), linspace(0, 1, 2))),...
                tem_perform_passive,tem_mpfc_passive_data1,tem_learned_day_passive,'UniformOutput',true);

            slope_task{curr_group}{curr_roi}= cellfun(@(perform,peak,learned) diff(polyval( polyfit( perform, peak,1), linspace(0, 1, 2))),...
                tem_perform_passive,tem_mpfc_task_data1,tem_learned_day_task,'UniformOutput',true);



            [R_task,P_task] = corr(performs_task(cell2mat(tem_learned_day_task)==1), data1_task(cell2mat(tem_learned_day_task)==1));
            text(0.15, 0.00055, sprintf('R_t=%.2f;P_t=%.2f', R_task,P_task), ...
                'FontSize', 8, 'Color', colors_1{curr_group}(1,:), 'FontWeight', 'normal');
            [R_passive,P_passive] = corr(performs_passive(cell2mat(tem_learned_day_passive)==1),  data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim));
            text(0.15, 0.0005, sprintf('R_p=%.2f;P_p=%.2f', R_passive,P_passive), ...
                'FontSize', 8, 'Color', colors_1{curr_group}(2,:), 'FontWeight', 'normal');


            scatter(performs_task(cell2mat(tem_learned_day_task)==0),data1_task(cell2mat(tem_learned_day_task)==0)',20,'filled',...
                'MarkerFaceColor',[0.2 0.2 0.2],'LineWidth',1)
            scatter(performs_task(cell2mat(tem_learned_day_task)==1),data1_task(cell2mat(tem_learned_day_task)==1)',20,'filled',...
                'MarkerFaceColor',colors_1{curr_group}(1,:),'LineWidth',1)

            scatter(performs_passive(cell2mat(tem_learned_day_passive)==0),...
                data1_passive(cell2mat(tem_learned_day_passive)==0,used_stim)',20,'filled','MarkerFaceColor',[0.5 0.5 0.5])
            
            
            scatter(performs_passive(cell2mat(tem_learned_day_passive)==1),...
                data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim)',20,'filled',...
                'MarkerFaceColor',colors_1{curr_group}(2,:))


                   

            ylim([0 0.0005])
            xlim([-0.1 1])
            % title(roi_name{curr_roi} ,'FontWeight','normal')
            ylabel('\Delta F/F')

            xlabel('performance')
            axis square
        end
    

end
  

%%

figure;


for curr_roi=1:2
    nexttile

 % ds.shuffle_test(slope_task{1}{curr_roi}, slope_pass{1}{curr_roi},0,1)
 % ds.shuffle_test(slope_task{2}{curr_roi}, slope_pass{2}{curr_roi},0,1)


 mean_1=  [cellfun(@(x)  median(x{curr_roi})  , slope_task,'UniformOutput',true );...
     cellfun(@(x)  median(x{curr_roi})  , slope_pass,'UniformOutput',true )];
 
 error_1=  [cellfun(@(x)  std(x{curr_roi})/sqrt(length(x{curr_roi}))  , slope_task,'UniformOutput',true );...
     cellfun(@(x)  std(x{curr_roi})/sqrt(length(x{curr_roi}))  , slope_pass,'UniformOutput',true )];


hold on
barHandle= bar(1:4,mean_1([1 3 2 4]), 0.7, 'FaceColor', 'flat','EdgeColor','none');
barHandle.CData = colors1; % 为不同组设置不同颜色
errorbar(1:4,mean_1([1 3 2 4]),error_1([1 3 2 4]), 'k', 'LineStyle', 'none', 'LineWidth', 1.5,'CapSize',0)

xline(2.5,'LineStyle',':')

xticks([1:4])
xticklabels({'V-task','V-passive','A-task','A-passive'})
 ylim([0 0.0005])
 % yticks([0 1])
ylabel('slope')
set(gca, 'Color', 'none');        % 坐标轴背景透明


end


%%  stage 2
figure('Position',[50 50 1000 400])
t1 = tiledlayout(2, 6, 'TileSpacing', 'tight', 'Padding', 'tight');

title_images={'pre learn','post learn'};
title_area={'l-mPFC','r-mPFC','l-aPFC','r-aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
scale1=0.0004;

Color={'R','B'};
colors{1} = { [1 0 0],[0 0 1]}; % 定义颜色
colors{2} = { [1 0.5 0.5],[0.5 0.5 1]}; % 定义颜色

used_area=[1 3]
for curr_roi=1:2
    for curr_group=1:2
        temp_image=permute(nanmean(cat(3,data_task.buf3_roi{curr_group}{used_area(curr_roi)}{:}),2),[1,3,2]);
        a1=nexttile(6*curr_roi-6+3*curr_group-3+1)
        imagesc(t_kernels,[], temp_image')
        % ylim([8.5 15.5])
        ylim([21.5 26.5])

        % ylim([0.5 26.5])
        xlim([-0.2 0.5])
        yline(3.5);
        yline(8.5);
        yline(10.5);
        yline(15.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a1, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        if curr_group==1
            yticks([2  6 ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
            yticklabels(title_images); % 设置对应的标签
        else
            yticks([])
        end
        if curr_roi==1
            title('task','FontWeight','normal')
        end



        a3=nexttile(6*curr_roi-6+3*curr_group-3+2)
        temp_image_p=permute(nanmean(cat(4,data_passive.buf3_roi{curr_group}{3-curr_group}{used_area(curr_roi)}{:}),3),[1,4,2,3]);
        imagesc(t_kernels,[], temp_image_p(:,:,1+curr_group)');
        ylim([21.5 26.5])

        % ylim([11.5 18.5])
        xlim([-0.2 0.5])

        yline(3.5);
        yline(6.5);
        yline(11.5);
        yline(13.5);
        yline(18.5);
        yline(21.5);

        clim(scale1 .* [0, 1]);
        colormap(a3, ap.colormap(['W' Color{curr_group}]));
        xlabel('time (s)')
        yticks([ ]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        if curr_roi==1
            title('passive','FontWeight','normal')
        end



        a4= nexttile(6*curr_roi-6+3*curr_group-3+3)
        temp_mean=permute(nanmean(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(1+curr_group,:,:),2),[3,2,1]);
        temp_error=permute(std(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(1+curr_group,:,:),0,2,'omitmissing'),[3,2,1])./...
            sqrt(size(data_passive.buf3_roi_peak{curr_group}{3-curr_group}{used_area(curr_roi)}(4-(3-curr_group),:,:),2));
        hold on
        ap.errorfill(1:5,temp_mean(22:26),temp_error(22:26),colors{2}{curr_group},0.1,0.5)



        a2= nexttile(6*curr_roi-6+3*curr_group-3+3)
        temp_mean=nanmean(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1);
        temp_error=std(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},0,1,'omitmissing')/sqrt(size(data_task.buf3_roi_peak{curr_group}{used_area(curr_roi)},1));
        hold on
        ap.errorfill(1:5,temp_mean(22:26),temp_error(22:26),colors{1}{curr_group},0.1,0.5)
        xlim([1 5])
        ylim(scale1 .* [0, 1]);
        xticks([1 5]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
        % xticklabels(title_images); % 设置对应的标签
        ylabel('\Delta F/F')


        if curr_roi==1
            legend(a2,{'','task','','passive'},'Location','northeast','Box','off')
        end

    end
end
% nexttile();axis off
% nexttile();axis off
%%

        scale=0.0003

colors{2}={[0 0 1],[0.5 0.5 1];[1 0 0],[1 0.5 0.5 ]}
colors{1}={[0 0 0  ],[0.5 0.5 0.5];[0 0 0],[0.5 0.5 0.5 ]}
title_area={'mPFC','mPFC','aPFC','aPFC','l-PPC','r-PPC','all-PFC','auditory area','','','','V1'}
context_diff=cell(2,1);

figure('Position',[50 50 350 200])
t1 = tiledlayout(2, 4, 'TileSpacing', 'tight', 'Padding', 'tight','TileIndexing','columnmajor');
for curr_roi=[1 3]
     tt=nexttile
        imagesc(roi1(curr_roi).data.mask )
       ap.wf_draw('ccf', [0.5 0.5 0.5]);
               axis image off

       ylim([0 200])
       xlim([20 220])
       clim( [ 0, 1]);
       colormap( tt,ap.colormap('WK'));
end

 for curr_group=1:2
       
        switch curr_group
            case 1
                used_stim=3
            case 2
                used_stim=2
        end
        for curr_roi=[1 3]

        % nexttile()
        temp_passive_peak=cell(2,1);
        temp_task_peak=cell(2,1);
        temp_task_mean=cell(2,1);
        temp_task_error=cell(2,1);
        temp_pass_mean=cell(2,1);
        temp_pass_error=cell(2,1);
        for curr_stage=1:2
            switch curr_stage
                case 1
                    used_task=[1: 3]
                    used_passive=[4 :6]

                case 2
                    used_task=[7: 8]
                    used_passive=[10 :11]

            end
            temp_passive=nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{curr_roi}{used_passive}),4);
            temp_passive_peak{curr_stage}=permute(max(temp_passive(kernels_period,used_stim,:),[],1),[3 2 1]);

            % temp_passive_temp=nanmean(cat(4,data_passive.buf3_roi{curr_group}{curr_group}{curr_roi+1}{used_passive}),4);
            % temp_passive_peak{curr_stage+2}=permute(max(temp_passive_temp(kernels_period,used_stim,:),[],1),[3 2 1]);

            temp_pass_mean{curr_stage}=nanmean(temp_passive(:,used_stim,:),3);
            temp_pass_error{curr_stage}=std(temp_passive(:,used_stim,:),0,3,'omitmissing')/sqrt(size(temp_passive,3));

            temp_task=nanmean(cat(3,data_task.buf3_roi{curr_group}{curr_roi}{used_task}),3);
            temp_task_peak{curr_stage}=permute(max(temp_task(kernels_period,:),[],1),[ 2 1]);
            temp_task_mean{curr_stage}=nanmean(temp_task,2);
            temp_task_error{curr_stage}=std(temp_task,0,2,'omitmissing')/sqrt(size(temp_task,2));

            % temp_task_temp=nanmean(cat(3,data_task.buf3_roi{curr_group}{curr_roi+1}{used_task}),3);
            % temp_task_peak{curr_stage+2}=permute(max(temp_task_temp(kernels_period,:),[],1),[ 2 1]);


        end

        lineColors{1} = [[ 0 0 0];[0.5 0.5 0.5];[ 0 0 1];[0.5 0.5 1]]; % 浅蓝、浅红
        lineColors{2} = [[ 0 0 0];[0.5 0.5 0.5];[ 1 0 0];[1 0.5 0.5]]; % 浅蓝、浅红
      
      nexttile
        for curr_stage=1:2
            hold on
            ap.errorfill(t_kernels,temp_task_mean{curr_stage},temp_task_error{curr_stage},lineColors{curr_group}(curr_stage*2-1,:),0.1,1,1.5)
            ap.errorfill(t_kernels,temp_pass_mean{curr_stage},temp_pass_error{curr_stage},lineColors{curr_group}(curr_stage*2,:),0.1,1,1.5)
        end
            ylim(scale*[-0.4 1.4])
            xlim([-0.2 0.5])
            xline(0,'LineStyle',':')
        axis off
      
    
        context_diff{curr_roi}{curr_group}=cellfun(@(task,pass)  (task-pass)./(task+pass),temp_task_peak,temp_passive_peak,'UniformOutput',false   )
        % context_diff{curr_roi}{curr_group}=cellfun(@(task,pass)  (task-pass),temp_task_peak,temp_passive_peak,'UniformOutput',false   )
    end
end




% saveas(gcf,[Path 'figures\summary\figures\fig2 kernels task vs passive' ], 'jpg');
% colors2=[ 0.5 0.5 1;1 0.5 0.5;0.5 0.5 1;1 0.5 0.5];
colors1=[ 0 0 1;0 0 1;1 0 0;1 0 0];

% mean_1=[nanmean(context_diff{1}{1}{2}) nanmean(context_diff{3}{1}{2}) nanmean(context_diff{1}{2}{2}) nanmean(context_diff{3}{2}{2})]
% error_1=[std(context_diff{1}{1}{2}) nanmean(context_diff{3}{1}{2}) nanmean(context_diff{1}{2}{2}) nanmean(context_diff{3}{2}{2})]

temp_data=cellfun(@(x) cellfun(@(a)  a{2},x,'UniformOutput',false ),context_diff([1 3]),'UniformOutput',false)
temp_data_1=cat(2,temp_data{:});
temp_data_1=temp_data_1([1 3 2 4])
mean_1= cellfun(@(x)  nanmean(x) ,cat(2,temp_data{:}),'UniformOutput',true)
error_1=  cellfun(@(x)  std(x,'omitmissing')/sqrt(length(x)) ,cat(2,temp_data{:}),'UniformOutput',true)

% fig = figure('Position',[50 50 150 250]);  % 图窗背景透明
 nexttile(t1,[2 1])
 % ax = axes('Parent', fig);

hold on
barHandle= bar(1:4,mean_1([1 3 2 4]), 0.7, 'FaceColor', 'flat','EdgeColor','none');
barHandle.CData = colors1; % 为不同组设置不同颜色
errorbar(1:4,mean_1([1 3 2 4]),error_1([1 3 2 4]), 'k', 'LineStyle', 'none', 'LineWidth', 1.5,'CapSize',0)

xline(2.5,'LineStyle',':')

xticks([1:4])
xticklabels({'V-l-mPFC','V-l-aPFC','A-l-mPFC','A-l-aPFC'})
ylim([0 1.5])
 yticks([0 1])
ylabel('context difference')
set(gca, 'Color', 'none');        % 坐标轴背景透明



% 添加 ranksum 检验及星号
y_max = max(cellfun(@max, temp_data_1)) -0; % 初始 y 值
h_offset = 0.15; % 每组比较向上偏移的高度
star_count = 0; % 当前比较编号，用于偏移高度

p_all=nan(length(temp_data_1)-1,length(temp_data_1))
for i = 1:length(temp_data_1)-1
    for j = i+1:length(temp_data_1)
        p = ranksum(temp_data_1{i}, temp_data_1{j});
        p_all(i,j)=p;

        % 判断显著性等级
        if p < 0.05
            if p < 0.001
                stars = '***';
            elseif p < 0.01
                stars = '**';
            else
                stars = '*';

            end
            % else
            %     stars=num2str(p)
            % end


            % 星号y位置，逐层向上叠加
            star_count = star_count + 1;
            y = y_max + (star_count - 1) * h_offset;

            % 连线
            plot([i j], [y y], 'k-', 'LineWidth', 1);

            % 星号文本
            text(mean([i j]), y + 0.02, stars, ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 14, 'FontWeight', 'bold');

        end
    end
end







