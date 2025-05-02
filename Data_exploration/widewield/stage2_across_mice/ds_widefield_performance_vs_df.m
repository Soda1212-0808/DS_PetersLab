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
colors={[  84 130 53 ]./255,[112  48 160]./255};
%%
for curr_group=1:2
    if curr_group==1
        animals = {'DS007','DS010','AP019','AP021','DS011','AP022','AP020','DS001','AP018'};
        group_name='VA';
        % order=[1 2]
    else
        animals = {'DS000','DS004','DS014','DS015','DS016','DS003','DS006','DS013'};
        group_name='AV';
        % order=[2 1]
    end
Mod_name={'Mod1','Mod2'}
        roi_name={'plmpFC','','almPFC'}

figure('Position',[50 100 400 400]);

tt = tiledlayout(1,2,'TileSpacing','tight');

    for curr_passive=1:2
        if (curr_passive==1 & curr_group==1)||(curr_passive==2 & curr_group==2)
            passive='lcr_passive';
            n1_name='visual position';
            used_stim=3; used_roi=1;

        elseif (curr_passive==1 & curr_group==2)||(curr_passive==2 & curr_group==1)

            passive='hml_passive_audio';
            n1_name='audio volume';
              used_stim=2;used_roi=3;

        end



        tem_perform_passive=cell(length(animals),1);
        tem_perform_task=cell(length(animals),1);

        tem_mpfc_passive_data=cell(length(animals),1);
        tem_mpfc_task_data=cell(length(animals),1);

        tem_learned_day_passive=cell(length(animals),1);
        tem_learned_day_task=cell(length(animals),1);

        for curr_animal=1:length(animals)
            animal=animals{curr_animal};
            data_behavior=load([Path  '\behavior\' animal '_behavior.mat' ]);
            data_passive_wf=load(fullfile(Path,passive,[animal '_' passive '.mat']));
            data_task_wf=load(fullfile(Path,'task',[animal '_task.mat']));

            wf_passive_kernels=...
                cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),data_passive_wf.wf_px_kernels,'UniformOutput',false);
            wf_task_kernels=...
                cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x{1},1)),x{1}),data_task_wf.wf_px_task_kernels,'UniformOutput',false);


            day_idx_0 = cellfun(@(x,y) find(strcmp(x, data_passive_wf.workflow_day)&strcmp(y, n1_name)),...
                data_behavior.workflow_day,data_behavior.workflow_name, 'UniformOutput', false);

            day_idx_1=cell2mat(day_idx_0(cellfun(@(x) ~isempty(x),day_idx_0,'UniformOutput',true)));


            tem_kernels=wf_passive_kernels(day_idx_1)';

            day_idx_2= cellfun(@(x) ~isempty(x),day_idx_0,'UniformOutput',true);

            wf_learned_day_passive=data_passive_wf.learned_day(day_idx_1)';

            tem_perform_passive{curr_animal}=(data_behavior.stim2move_mean_null(day_idx_2)-data_behavior.stim2move_mean(day_idx_2))./...
                (data_behavior.stim2move_mean_null(day_idx_2)+data_behavior.stim2move_mean(day_idx_2));

            image_all_passive_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),tem_kernels,'UniformOutput',false);
            buf1_passive=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all_passive_mean, 'UniformOutput', false);


            day_idx_task_0 = cellfun(@(x,y) find(strcmp(x, data_task_wf.workflow_day)&strcmp(y, n1_name)),...
                data_behavior.workflow_day,data_behavior.workflow_name, 'UniformOutput', false);
            day_idx_task_1=cell2mat(day_idx_task_0(cellfun(@(x) ~isempty(x),day_idx_task_0,'UniformOutput',true)));
            day_idx_task_2= cellfun(@(x) ~isempty(x),day_idx_task_0,'UniformOutput',true);
            tem_perform_task{curr_animal}=(data_behavior.stim2move_mean_null(day_idx_task_2)-data_behavior.stim2move_mean(day_idx_task_2))./...
                (data_behavior.stim2move_mean_null(day_idx_task_2)+data_behavior.stim2move_mean(day_idx_task_2));

            tem_task_kernels=wf_task_kernels(day_idx_task_1)';

            b_p=cell2mat(data_task_wf.rxn_stat_p(day_idx_task_1));
            wf_learned_day_task=b_p<0.05;

            image_all_task_mean=cellfun(@(x) permute(max(x(:,:,period_kernels,:),[],3),[1,2,4,3]),tem_task_kernels,'UniformOutput',false);
            buf1_task=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)) , image_all_task_mean, 'UniformOutput', false);




            buf3_passive_mPFC=cell(2,1);
            buf3_task_mPFC=cell(2,1);

            for curr_roi=[1 3]
                buf3_passive_mPFC{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1_passive, 'UniformOutput', false);
                buf3_task_mPFC{curr_roi}= cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]) , buf1_task, 'UniformOutput', true);

            end
            tem_mpfc_task_data{curr_animal}=buf3_task_mPFC;

            tem_mpfc_passive_data{curr_animal}=buf3_passive_mPFC;
            tem_learned_day_passive{curr_animal}=wf_learned_day_passive;
            tem_learned_day_task{curr_animal}=wf_learned_day_task;

        end


        data1_passive=cat(2,tem_mpfc_passive_data{:});
        data1_task=cat(2,tem_mpfc_task_data{:});
        % if curr_passive==1
        % elseif curr_passive==2
        % end

        
        for curr_roi=used_roi
             
            t_mod = tiledlayout(tt,2,1);
    t_mod.Layout.Tile = curr_passive;
    title(t_mod,Mod_name{curr_passive});


            data2_passive=data1_passive(curr_roi,:);
            data3_passive=cell2mat(vertcat(data2_passive{:})');
            data2_task=data1_task(curr_roi,:);
            data3_task=cat(1,data2_task{:})';
            performs_passive=cell2mat(tem_perform_passive);
           
              nexttile(t_mod)
            performs_task=cell2mat(tem_perform_task);
            hold on
            scatter(performs_task(cell2mat(tem_learned_day_task)==0),data3_task(cell2mat(tem_learned_day_task)==0)','k')
            scatter(performs_task(cell2mat(tem_learned_day_task)==1),data3_task(cell2mat(tem_learned_day_task)==1)','MarkerEdgeColor',colors{curr_group})
            ylim([0 0.0007])
            xlim([-0.1 0.6])
            title(roi_name{curr_roi})
            xlabel('performance')
            ylabel('\Delta F/F in task')
            axis square
            
            
            nexttile(t_mod)
            hold on
            scatter(performs_passive(cell2mat(tem_learned_day_passive)==0),data3_passive(used_stim,cell2mat(tem_learned_day_passive)==0)','k')
            scatter(performs_passive(cell2mat(tem_learned_day_passive)==1),data3_passive(used_stim,cell2mat(tem_learned_day_passive)==1)','MarkerEdgeColor',colors{curr_group})

            ylim([0 0.0005])
            xlim([-0.1 0.6])
            % title(roi_name{curr_roi})
            xlabel('performance')
            ylabel('\Delta F/F in passive')
            axis square


          
        end
        % sgtitle( Mod_name{curr_group})
        drawnow
    end
     saveas(gcf,[Path 'figures\summary\figures\performace vs df in  ' group_name], 'jpg');

end