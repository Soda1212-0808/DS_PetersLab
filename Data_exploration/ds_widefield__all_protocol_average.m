
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

       animals = {'DS001','AP019','AP021','AP022','AP018','AP020','DS007','DS010','DS011'};first_type=1;
            % animals = {'DS007'};first_type=1;

 % animals = {'AP018','AP020'};first_type=1;

   % animals = {'DS000','DS003','DS004','DS005','DS006'};first_type=2;
   % animals = {'DS000','DS004'};first_type=2;
    % animals = {'DS005'};first_type=1;

   % animals = {'DS006'};first_type=2;

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-5:30];

period_passive=find(t_passive>0&t_passive<0.2);
period_task=find(t_task>0&t_task<0.2);
period_kernels=find(t_kernels>0&t_kernels<0.2);

data_90=cell(size(animals,2),12);
data_n90=cell(size(animals,2),12);
data_0=cell(size(animals,2),12);
data_8k=cell(size(animals,2),12);
data_4k=cell(size(animals,2),12);
data_12k=cell(size(animals,2),12);
data_task=cell(size(animals,2),12);
data_task_kernels=cell(size(animals,2),12);


for curr_animal=1:length(animals)

    animal=animals{curr_animal};
    raw_data_task=load([Path '\mat_data\' animal '_task.mat']);
    raw_data_lcr=load([Path '\mat_data\' animal '_lcr_passive.mat']);
    raw_data_hml=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);

    indx= max(find(raw_data_task.workflow_type==first_type));
    for curr_idx=1:12

         buff_lcr_idx=find(strcmp(raw_data_lcr.workflow_day,raw_data_task.workflow_day{indx-7+curr_idx}));
         buff_hml_idx=find(strcmp(raw_data_hml.workflow_day,raw_data_task.workflow_day{indx-7+curr_idx}));
          
         if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==90)
         data_90{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==90));
         end
          if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==-90)
         data_n90{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==-90));
          end
           if ~isempty (buff_lcr_idx)& any(raw_data_lcr.all_groups_name{buff_lcr_idx}==0)
         data_0{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_lcr.wf_px{buff_lcr_idx}(:,:,raw_data_lcr.all_groups_name{buff_lcr_idx}==0));
         end

         if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==8000)
         data_8k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==8000));
         end
          if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==12000)
         data_12k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==12000));
          end
           if ~isempty (buff_hml_idx)& any(raw_data_hml.all_groups_name{buff_hml_idx}==4000)
         data_4k{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_hml.wf_px{buff_hml_idx}(:,:,raw_data_hml.all_groups_name{buff_hml_idx}==4000));
         end
        data_task{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task{indx-7+curr_idx}(:,:,1));
        data_task_kernels{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{indx-7+curr_idx}(:,:,1));


    end


end

suffixes = {'90', '0', 'n90', '8k', '12k','4k','task','task_kernels'};
all_data=struct;
for i = 1:length(suffixes)  
redata_var=['redata_', suffixes{i}];
cross_time_var=['cross_time_', suffixes{i}];
cross_time_average_var=['cross_time_average_', suffixes{i}];
average_var=['average_', suffixes{i}];
average_mean_var=['average_mean_', suffixes{i}];
average_sem_var=['average_sem_', suffixes{i}];
data_var=evalin('base',['data_', suffixes{i}]);

all_data.(redata_var)=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), data_var, 'UniformOutput', false);
isEmpty = ~cellfun('isempty', all_data.(redata_var));
all_data.(cross_time_var)=cell(size(all_data.(redata_var)));
all_data.(cross_time_var)(isEmpty)=cellfun(@(x) mean(x(roi1(1).data.mask(:),:),1), all_data.(redata_var)(isEmpty), 'UniformOutput', false);
% sumArray = cellfun(@(x) sum(cat(3, x{:}), 3), num2cell(all_data.(lcr_cross_time_var), 1), 'UniformOutput', false);
% countArray = cellfun(@(x) sum(isEmpty(:, x)), num2cell(1:size(all_data.(lcr_cross_time_var), 2)));
avgArray= cellfun(@(sumArr, count) sumArr / count,...
    cellfun(@(x) sum(cat(3, x{:}), 3), num2cell(all_data.(cross_time_var), 1), 'UniformOutput', false),...
    num2cell(cellfun(@(x) sum(isEmpty(:, x)), num2cell(1:size(all_data.(cross_time_var), 2)))), 'UniformOutput', false);
all_data.(cross_time_average_var)=permute(cat(3,avgArray{:}),[2 3 1]);

all_data.(average_var)=cell(size(all_data.(redata_var)));
all_data.(average_var)(isEmpty)=cellfun(@(x) max(mean(x(roi1(1).data.mask(:),period_passive),1)),all_data.(redata_var)(isEmpty), 'UniformOutput',false);
all_data.(average_var)(cellfun(@isempty, all_data.(average_var))) = {NaN};
all_data.(average_var) = cellfun(@(x) double(x), all_data.(average_var), 'UniformOutput', false);
% 对每列进行操作，计算平均值
% resultArray = cellfun(@(col) mean(cat(4, all_data.(lcr_cross_time_var){~isEmpty(:, col), col}), 4), num2cell(1:size(all_data.(lcr_cross_time_var),2)), 'UniformOutput', false);
all_data.(average_mean_var) =cell2mat( cellfun(@(col) mean(cat(3, all_data.(average_var){isEmpty(:, col), col})), num2cell(1:size(all_data.(average_var),2)), 'UniformOutput', false));
all_data.(average_sem_var) = cell2mat(cellfun(@(col) std(cat(3, all_data.(average_var){isEmpty(:, col), col})), num2cell(1:size(all_data.(average_var),2)), 'UniformOutput', false));

end


%%
figure('Position',[100 100 400 800])
hold on
% plot(fillmissing(cell2mat(all_data.average_90), 'linear', 2)','Color',[0.5 0.5 1])
h1=ap.errorfill((1:size(all_data.average_90,2)),all_data.average_mean_90, all_data.average_sem_90,[0,0,1],0.1,0.5);

% plot(fillmissing(cell2mat(all_data.average_8k), 'linear', 2)','Color',[1 0.5 0.5])
h2=ap.errorfill((1:size(all_data.average_8k,2)),all_data.average_mean_8k, all_data.average_sem_8k,[1,0,0],0.1,0.5);

% plot(fillmissing(cell2mat(all_data.average_task_kernels), 'linear', 2)','Color',[0.5 0.5 0.5])
% h3=ap.errorfill((1:size(all_data.average_90,2)),all_data.average_mean_task_kernels, all_data.average_sem_task_kernels,[0,0,0],0.1,0.5);



xlim([1 12])
ylim(0.001*[-1 3])
hold on
xline(7.5)
xline(2.5)
legend([h1 h2 h3],{'visual passive','audio passive','task kernels'},'Location','northeastoutside');
   saveas(gcf,[Path 'figures\plot_passive_90_vs_task_kernels_' strjoin(animals, '_')], 'jpg');

 


