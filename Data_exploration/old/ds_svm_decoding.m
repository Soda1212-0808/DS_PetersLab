clear all
clc
% Load master U's
U_master = plab.wf.load_master_U;
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

animals{1} = {'DS007','DS010','AP019','AP021','DS011','AP022'};
animals{2} = {'DS000','DS004','DS014','DS015','DS016'};
all_data=cell(2,1);

for curr_group=1:2
    for curr_animal=1:length(animals{curr_group})
        animal=animals{curr_group}{curr_animal}
        data_load=load([Path 'mat_data\task\' animal '_task.mat ']);
        learned_days= find(cellfun(@(x,y) x(1)<0.05 & strcmp('audio volume',y),...
            data_load.rxn_stat_p,data_load.workflow_type_name_merge,'UniformOutput',true));

        Path_task=[Path 'mat_data\task\' animal '_task_single_trial.mat'];
        buffer_file = matfile(Path_task, 'Writable', false); % 以只读模式打开
        data_part = buffer_file.wf_px_task_all;
        buff1= cellfun(@(x) x(:,:,1:size(x,3)/3), data_part(learned_days),'UniformOutput',false);
        all_data{curr_group}{curr_animal}=cat(3,buff1{:});
    end
end


[H, W, D] = size(U_master); % H=高度, W=宽度, D=深度

[idx_row, idx_col] = find(roi1(2).data.mask == 1); % 找到所有 B==1 的索引
num_points = numel(idx_row); % 计算满足条件的点数

% 将二维索引转换为线性索引，并扩展到所有 40 层
linear_idx = sub2ind([H, W], idx_row, idx_col); % 计算 2D 线性索引
linear_idx = repmat(linear_idx, 1, D) + repmat((0:D-1) * H * W, num_points, 1);

% 直接提取数据
values =permute( U_master(linear_idx),[3, 1 ,2]); % 得到 num_points × 40 的矩阵

data_selected=cellfun(@(x) permute(plab.wf.svd2px(values,cat(3,x{:})),[2,3,4,1]),all_data,'UniformOutput',false);


labels = [repmat({'VA'}, 1, size(data_selected{1},3)), repmat({'AV'}, 1, size(data_selected{2},3))];

binned_labels.group_ID=repmat({labels}, 1, size(data_selected{1},1));

data_meged=permute(cat(3,data_selected{:}),[3,2,1]);

% 获取矩阵的大小
[H1, W1, D1] = size(data_meged);

% 使用 mat2cell 拆分
binned_data = permute(mat2cell(data_meged, H1, W1, ones(1, D1)),[1,3,2]);

binned_site_info=struct;

 save([Path 'mat_data\decoding_data\binned_data.mat' ],'binned_data','binned_labels','binned_site_info','-v7.3')

%%

% we will use object identity labels to decode which object was shown (disregarding the position of the object)
specific_binned_labels_names = 'group_ID';
% use 20 cross-validation splits (which means that 19 examples of each object are used for training and 1 example of each object is used for testing)
num_cv_splits = 20; 
binned_data_file_name='binned_data.mat';
full_path=fullfile('C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\decoding_data',binned_data_file_name);
% create the basic datasource object
ds = basic_DS(full_path, specific_binned_labels_names,  num_cv_splits);

 the_feature_preprocessors{1} = zscore_normalize_FP;  
the_classifier = libsvm_CL;

the_cross_validator = standard_resample_CV(ds, the_classifier, the_feature_preprocessors);  
the_cross_validator.num_resample_runs = 10;  % usually more than 2 resample runs are used to get more accurate results, but to save time we are using a small number here

DECODING_RESULTS = the_cross_validator.run_cv_decoding; 

save_file_name = 'Zhang_Desimone_basic_7object_results';
save(save_file_name, 'DECODING_RESULTS'); 

% which results should be plotted (only have one result to plot here)
result_names{1} = save_file_name;

% create an object to plot the results
plot_obj = plot_standard_results_object(result_names);

% put a line at the time when the stimulus was shown
plot_obj.significant_event_times = 0;   


% optional argument, can plot different types of results
%plot_obj.result_type_to_plot = 2;  % for example, setting this to 2 plots the normalized rank results


plot_obj.plot_results;   % actually plot the results



