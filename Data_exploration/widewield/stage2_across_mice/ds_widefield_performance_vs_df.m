clear all
Path = 'D:\Data process\wf_data\';
% Load master U's
U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary);
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);
% colors={[  84 130 53 ]./255,[112  48 160]./255};

%%
% for curr_group=1:2
%     if curr_group==1
%         animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
%         group_name='VA';
%         % order=[1 2]
%     else
%         animals = {'DS000','DS004','DS014','DS015','DS016'};
%         group_name='AV';
%         % order=[2 1]
%     end
%     Mod_name={'Mod1','Mod2'}
%     roi_name={'l-mPFC','l-aPFC'}
% 
%     figure('Position',[2000 200 400 400]);
%     tt = tiledlayout(1,2,'TileSpacing','tight');
% 
%     for curr_passive=1:2
%         if (curr_passive==1 & curr_group==1)||(curr_passive==2 & curr_group==2)
%             passive='lcr_passive';
%             n1_name='visual position';
%             used_stim=[1 2 3]; used_roi=1;
% 
%         elseif (curr_passive==1 & curr_group==2)||(curr_passive==2 & curr_group==1)
% 
%             passive='hml_passive_audio';
%             n1_name='audio volume';
%             used_stim=[1 3 2];used_roi=2;
% 
%         end
% 
% 
% 
%         tem_perform_passive=cell(length(animals),1);
%         tem_perform_task=cell(length(animals),1);
% 
%         tem_mpfc_passive_data=cell(length(animals),1);
%         tem_mpfc_task_data=cell(length(animals),1);
% 
%         tem_learned_day_passive=cell(length(animals),1);
%         tem_learned_day_task=cell(length(animals),1);
% 
%         for curr_animal=1:length(animals)
%             animal=animals{curr_animal};
%             data_behavior=load([Path  '\behavior\' animal '_behavior.mat' ]);
%             data_passive_wf=load(fullfile(Path,passive,[animal '_' passive '.mat']));
%             data_task_wf=load(fullfile(Path,'task',[animal '_task.mat']));
% 
%             wf_passive_kernels=...
%                 cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),data_passive_wf.wf_px_kernels,'UniformOutput',false);
%             image_all_passive_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),wf_passive_kernels,'UniformOutput',false);
%             temp_passive=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)) , image_all_passive_mean, 'UniformOutput', false);
%             passive_mPFC=arrayfun(@(id) cellfun(@(z) mean(z(roi1(id).data.mask(:),:),1),...
%                 temp_passive, 'UniformOutput', false),[1 3], 'UniformOutput', false);
% 
% 
%             wf_task_kernels=...
%                 cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{1},1)),x{1}),data_task_wf.wf_px_task_kernels,'UniformOutput',false);
% 
%             image_all_task_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),wf_task_kernels,'UniformOutput',false);
%             temp_task=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3)) , image_all_task_mean, 'UniformOutput', false);
%             task_mPFC=arrayfun(@(id) cellfun(@(z) mean(z(roi1(id).data.mask(:),1),1),...
%                 temp_task, 'UniformOutput', true),[1 3], 'UniformOutput', false);
% 
% 
% 
% 
% 
%             idx_0= cellfun(@(y) strcmp( y,n1_name),...
%                 data_behavior.workflow_name, 'UniformOutput', true);
%             day_behavior = data_behavior.workflow_day(idx_0);
%             performance=(data_behavior.stim2move_mad_null(idx_0)-data_behavior.stim2move_mad(idx_0))./...
%                 (data_behavior.stim2move_mad_null(idx_0)+data_behavior.stim2move_mad(idx_0));
%             day_learned=data_behavior.rxn_f_stat_p(idx_0)<0.01;
% 
% 
%             day_idx_passive = data_passive_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
%                 data_passive_wf.workflow_type_name_merge, 'UniformOutput', true));
%             wf_passive=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
%                 data_passive_wf.workflow_type_name_merge, 'UniformOutput', true))',passive_mPFC, 'UniformOutput', false);
% 
% 
%             [~, temp_idx_passive] = ismember( day_idx_passive,day_behavior);
%             performance_passive=performance(temp_idx_passive);
%             day_learned_passive=day_learned(temp_idx_passive);
% 
% 
% 
% 
%             day_idx_task = data_task_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
%                 data_task_wf.workflow_type_name_merge, 'UniformOutput', true));
%             wf_task=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
%                 data_task_wf.workflow_type_name_merge, 'UniformOutput', true))',task_mPFC, 'UniformOutput', false);
% 
% 
%             [~, temp_idx_task] = ismember( day_idx_task,day_behavior);
%             performance_task=performance(temp_idx_task);
%             day_learned_task=day_learned(temp_idx_task);
% 
% 
% 
%             tem_mpfc_task_data{curr_animal}=wf_task;
%             tem_mpfc_passive_data{curr_animal}=cellfun(@(x) cat(1,x{:})  ,wf_passive,'UniformOutput',false);
% 
%             tem_perform_task{curr_animal}=performance_task;
%             tem_perform_passive{curr_animal}=performance_passive;
% 
%             tem_learned_day_passive{curr_animal}=day_learned_passive;
%             tem_learned_day_task{curr_animal}=day_learned_task;
% 
%         end
% 
%         tem_mpfc_passive_data1=   cellfun(@(x) x(used_roi),tem_mpfc_passive_data,'UniformOutput',true);
%         tem_mpfc_task_data1=   cellfun(@(x) x(used_roi),tem_mpfc_task_data,'UniformOutput',true);
%         data1_passive=cat(1,tem_mpfc_passive_data1{:});
%         data1_task=cat(1,tem_mpfc_task_data1{:});
% 
% 
%         t_mod = tiledlayout(tt,2,1);
%         t_mod.Layout.Tile = curr_passive;
%         title(t_mod,Mod_name{curr_passive});
% 
% 
%         performs_passive=cell2mat(tem_perform_passive);
%         performs_task=cell2mat(tem_perform_task);
% 
%         nexttile(t_mod)
%         hold on
% 
%         scatter(performs_task(cell2mat(tem_learned_day_task)==0),data1_task(cell2mat(tem_learned_day_task)==0)','k')
%         scatter(performs_task(cell2mat(tem_learned_day_task)==1),data1_task(cell2mat(tem_learned_day_task)==1)',...
%             'MarkerEdgeColor',colors{curr_group}{1}{4-curr_group})
% 
%         ylim([0 0.0007])
%         xlim([-0.1 1])
%          title(roi_name{used_roi})
%         xlabel('performance')
%         ylabel('\Delta F/F in task')
%         axis square
% 
% 
%         nexttile(t_mod)
%         hold on
%         for curr_stim =1:3
%             scatter(performs_passive(cell2mat(tem_learned_day_passive)==0),...
%                 data1_passive(cell2mat(tem_learned_day_passive)==0,curr_stim)','k')
%             scatter(performs_passive(cell2mat(tem_learned_day_passive)==1),...
%                 data1_passive(cell2mat(tem_learned_day_passive)==1,curr_stim)',...
%                 'MarkerEdgeColor',colors{curr_group}{curr_passive}{curr_stim})
%         end
%         ylim([0 0.0004])
%         xlim([-0.1 1])
%         title(roi_name{used_roi})
%         xlabel('performance')
%         ylabel('\Delta F/F in passive')
%         axis square
% 
% 
% 
%          % sgtitle( Mod_name{curr_group})
%         drawnow
%     end
% 
% 
%      saveas(gcf,[Path 'figures\summary\figures\performace vs df in  ' group_name], 'jpg');
% 
% end

%%

colors{1}=[[0 0 1];[0.5 0.5 1]];
colors{2}=[[1 0 0];[1 0.5 0.5]];
    
for curr_mod =1
 figure('Position',[2000 200 600 200]);
t1 = tiledlayout(1, 4,'TileSpacing', 'tight', 'Padding', 'tight');
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
           
            temp_vel=data_behavior_single.frac_velocity_stimalign(idx_0,1)
            temp_vel1= cellfun(@(x) corr(x(:,500:600)') ,temp_vel,'UniformOutput',false )
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

      
        for curr_roi=1:2
            tem_mpfc_passive_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_passive_data,'UniformOutput',true);
            tem_mpfc_task_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_task_data,'UniformOutput',true);
            data1_passive=cat(1,tem_mpfc_passive_data1{:});
            data1_task=cat(1,tem_mpfc_task_data1{:});

            performs_passive=cell2mat(tem_perform_passive);
            performs_task=cell2mat(tem_perform_task);

            corr_passive=cell2mat(tem_corr_passive);
            corr_task=cell2mat(tem_corr_task);


            if curr_roi==1
                nexttile(curr_group)
            else
                nexttile(2+curr_group)
            end
            hold on

            % p_task = polyfit(performs_task(cell2mat(tem_learned_day_task)==1), data1_task(cell2mat(tem_learned_day_task)==1)', 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
            % x_fit_task = linspace(0, 1, 100);
            % y_fit_task = polyval(p_task, x_fit_task);
            % plot(x_fit_task, y_fit_task, '-', 'LineWidth', 2,'Color',colors{curr_group}(1,:));
            % 
            % p_passive = polyfit(performs_passive(cell2mat(tem_learned_day_passive)==1),  data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim)', 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
            % x_fit_passive = linspace(0, 1, 100);
            % y_fit_passive = polyval(p_passive, x_fit_passive);
            % plot(x_fit_passive, y_fit_passive, '-', 'LineWidth', 2,'Color',colors{curr_group}(2,:));

            [R_task,P_task] = corr(performs_task(cell2mat(tem_learned_day_task)==1), data1_task(cell2mat(tem_learned_day_task)==1));
            text(0.15, 0.00055, sprintf('R_t=%.2f;P_t=%.2f', R_task,P_task), ...
                'FontSize', 8, 'Color', colors{curr_group}(1,:), 'FontWeight', 'normal');
            [R_passive,P_passive] = corr(performs_passive(cell2mat(tem_learned_day_passive)==1),  data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim));
            text(0.15, 0.0005, sprintf('R_p=%.2f;P_p=%.2f', R_passive,P_passive), ...
                'FontSize', 8, 'Color', colors{curr_group}(2,:), 'FontWeight', 'normal');


            scatter(performs_task(cell2mat(tem_learned_day_task)==0),data1_task(cell2mat(tem_learned_day_task)==0)',...
                'MarkerEdgeColor',[0.2 0.2 0.2],'LineWidth',1)
            scatter(performs_task(cell2mat(tem_learned_day_task)==1),data1_task(cell2mat(tem_learned_day_task)==1)',...
                'MarkerEdgeColor',colors{curr_group}(1,:),'LineWidth',1)

            scatter(performs_passive(cell2mat(tem_learned_day_passive)==0),...
                data1_passive(cell2mat(tem_learned_day_passive)==0,used_stim)','MarkerEdgeColor',[0.5 0.5 0.5])
            scatter(performs_passive(cell2mat(tem_learned_day_passive)==1),...
                data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim)',...
                'MarkerEdgeColor',colors{curr_group}(2,:))


                   

            ylim([0 0.0005])
            xlim([-0.1 1])
            % title(roi_name{curr_roi} ,'FontWeight','normal')
            ylabel('\Delta F/F')

            xlabel('performance')
            axis square
        end
    

end
  
sgtitle(['mod ' num2str(curr_mod)])  
   % saveas(gcf,[Path 'figures\summary\figures\performace vs df mod ' num2str(curr_mod)], 'jpg');

end
     % saveas(gcf,[Path 'figures\summary\figures\performace vs df '], 'jpg');

%%

colors{1}=[[0 0 1];[0.5 0.5 1]];
colors{2}=[[1 0 0];[1 0.5 0.5]];
    
for curr_mod =1
 figure('Position',[2000 200 600 200]);
t1 = tiledlayout(1, 4,'TileSpacing', 'tight', 'Padding', 'tight');
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

        for curr_animal=1:length(animals)
            animal=animals{curr_animal};
            data_behavior_single=load([Path  '\behavior\' animal '_behavior.mat' ]);
            data_passive_wf=load(fullfile(Path,passive,[animal '_' passive '.mat']));
            data_task_wf=load(fullfile(Path,'task',[animal '_task.mat']));

idx_passive=ismember(data_passive_wf.workflow_day,data_task_wf.workflow_day)
idx_task=ismember(data_task_wf.workflow_day,data_passive_wf.workflow_day)

data_behavior_single = structfun(@(x) x(idx_task, :), data_behavior_single, 'UniformOutput', false);
data_passive_wf= structfun(@(x) x(idx_passive), data_passive_wf, 'UniformOutput', false);
data_task_wf= structfun(@(x) x(idx_task), data_task_wf, 'UniformOutput', false);

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
            performance=(data_behavior_single.stim2move_mad_null(idx_0)-data_behavior_single.stim2move_mad(idx_0))./...
                (data_behavior_single.stim2move_mad_null(idx_0)+data_behavior_single.stim2move_mad(idx_0));
            day_learned=data_behavior_single.rxn_f_stat_p(idx_0)<0.01;


            day_idx_passive = data_passive_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
                data_passive_wf.workflow_type_name_merge, 'UniformOutput', true));
            wf_passive=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
                data_passive_wf.workflow_type_name_merge, 'UniformOutput', true))',passive_mPFC, 'UniformOutput', false);


            [~, temp_idx_passive] = ismember( day_idx_passive,day_behavior);
            performance_passive=performance(temp_idx_passive);
            day_learned_passive=day_learned(temp_idx_passive);




            day_idx_task = data_task_wf.workflow_day( cellfun(@(y) strcmp( y,n1_name),...
                data_task_wf.workflow_type_name_merge, 'UniformOutput', true));
            wf_task=cellfun(@(x) x( cellfun(@(y) strcmp( y,n1_name),...
                data_task_wf.workflow_type_name_merge, 'UniformOutput', true))',task_mPFC, 'UniformOutput', false);


            [~, temp_idx_task] = ismember( day_idx_task,day_behavior);
            performance_task=performance(temp_idx_task);
            day_learned_task=day_learned(temp_idx_task);



            tem_mpfc_task_data{curr_animal}=wf_task;
            tem_mpfc_passive_data{curr_animal}=cellfun(@(x) cat(1,x{:})  ,wf_passive,'UniformOutput',false);

            tem_perform_task{curr_animal}=performance_task;
            tem_perform_passive{curr_animal}=performance_passive;

            tem_learned_day_passive{curr_animal}=day_learned_passive;
            tem_learned_day_task{curr_animal}=day_learned_task;

        end

      
        for curr_roi=1:2
            tem_mpfc_passive_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_passive_data,'UniformOutput',true);
            tem_mpfc_task_data1=   cellfun(@(x) x(curr_roi),tem_mpfc_task_data,'UniformOutput',true);
            data1_passive=cat(1,tem_mpfc_passive_data1{:});
            data1_task=cat(1,tem_mpfc_task_data1{:});

            performs_passive=cell2mat(tem_perform_passive);
            performs_task=cell2mat(tem_perform_task);
            if curr_roi==1
                nexttile(curr_group)
            else
                nexttile(2+curr_group)
            end
            hold on

            temp_passive_plot=data1_passive(cell2mat(tem_learned_day_passive)==1,used_stim)
            temp_task_plot=data1_task(cell2mat(tem_learned_day_task)==1)
            temp_perform_plot=performs_task(cell2mat(tem_learned_day_task)==1)

            p_task = polyfit(temp_passive_plot, temp_task_plot, 1);       % 一阶多项式拟合：y = p(1)*x + p(2)
            x_fit_task = linspace(0, 1, 100);
            y_fit_task = polyval(p_task, x_fit_task);
            plot(x_fit_task, y_fit_task, '-', 'LineWidth', 2,'Color',colors{curr_group}(1,:));
  
            [R_task,P_task] = corr(temp_passive_plot, temp_task_plot);
            text(0, 0.00075, sprintf('R_t=%.2f;P_t=%.2f', R_task,P_task), ...
                'FontSize', 8, 'Color', colors{curr_group}(1,:), 'FontWeight', 'normal');
         


             scatter(data1_passive(cell2mat(tem_learned_day_passive)==0,used_stim)',data1_task(cell2mat(tem_learned_day_task)==0)',...
                'MarkerEdgeColor',[0.2 0.2 0.2],'LineWidth',1)
            scatter( temp_passive_plot,temp_task_plot,...
                'MarkerEdgeColor',colors{curr_group}(1,:),'LineWidth',1)
          
            ylim([0 0.0008])
            xlim([0 0.0008])
            plot(xlim,xlim,':k')

            % title(roi_name{curr_roi} ,'FontWeight','normal')
            ylabel('\Delta F/F in task')

            xlabel('\Delta F/F in passive')
            axis square
            set(gca,'Color','none')
        end
    

end
  sgtitle(['mod ' num2str(curr_mod)])  
   % saveas(gcf,[Path 'figures\summary\figures\performace vs df mod ' num2str(curr_mod)], 'jpg');

end
     % saveas(gcf,[Path 'figures\summary\figures\performace vs df '], 'jpg');


