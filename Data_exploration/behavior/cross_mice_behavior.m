clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_task = [-0.2,1];
t_task = surround_window_task(1):1/surround_samplerate:surround_window_task(2);
t_kernels=1/surround_samplerate*[-10:30];

Color={'B','R'};
n1_name='';n2_name='';
use_period=[];
use_t=[];
animals={};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};
workflow='task';

data_type={'raw','kernels'};
%used_data=1;  1 raw data; 2 kernels；3 kernels encode

select_group=1:2

all_data_image2=cell(2,1);
all_data_cross_day=cell(2,1);

 

        for curr_group=select_group;

            main_preload_vars = who;

            if curr_group==1
                animals{curr_group} = {'DS007','DS010','AP019','AP021','DS011','AP022'};n1_name='visual position';n2_name='audio volume';
            elseif curr_group==2
                animals{curr_group} = {'DS000','DS004','DS014','DS015','DS016'};n1_name='audio volume';n2_name='visual position';
            elseif curr_group==3
                animals{curr_group} = {'AP018','AP020'};n1_name='visual position';n2_name='audio volume';
            elseif curr_group==4
                animals{curr_group} = {'DS006','DS013'};n1_name='audio volume';n2_name='visual position';
            elseif curr_group==5
                animals{curr_group} = {'AP027','AP028','DS019','DS020','DS021'};n1_name='visual position';n2_name='audio frequency';
            elseif curr_group==6
                animals{curr_group} = {'AP027','AP028','AP029'};n1_name='visual opacity';n2_name='visual position';
            elseif curr_group==7
                animals{curr_group} = {'HA003','HA004','DS019','DS020','DS021'};n1_name='visual size up';n2_name='visual position';
            elseif curr_group==8
                animals{curr_group} = {'HA000','HA001','HA002'};n1_name='visual angle';n2_name='visual position';

            end


            % used_id=1:3;

            all_data_s2m=cell(length(animals{curr_group}),1);
            all_data_workflow_name=cell(length(animals{curr_group}),1);
            all_data_learned_day=cell(length(animals{curr_group}),1);
            matches=cell(length(animals{curr_group}),1);
            use_t=[];
            use_period=[];

            for curr_animal=1:length(animals{curr_group})
                preload_vars = who;

                animal=animals{curr_group}{curr_animal};
                raw_data_task=load([Path  workflow '\' animal '_' workflow '.mat']);
                raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

                [~, temp_idx] = ismember( raw_data_task.workflow_day,raw_data_behavior.workflow_day);
                % temp_p=raw_data_behavior.rxn_f_stat_p(temp_idx,:);


                temp_p=nan(length(raw_data_behavior.workflow_day),2);
                idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
                idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
                idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

                temp_p(idx_v,1)= raw_data_behavior.rxn_f_mean_p(idx_v,1);
                temp_p(idx_a,1)=raw_data_behavior.rxn_f_mean_p(idx_a,1);
                temp_p(idx_m,:)= [raw_data_behavior.rxn_f_mean_p(idx_m,1)...
                    raw_data_behavior.rxn_f_mean_p(idx_m,2)];
                temp_p=temp_p(temp_idx,:);

                raw_data_task.learned_day=temp_p<0.01;


                temp_rxn_med=cellfun(@(x) mean(x,'omitnan'), raw_data_behavior.stim_on2off_times(temp_idx,:),'UniformOutput',true);


                idx=cellfun(@(x) ~isempty(x),raw_data_task.wf_px_task_kernels);

                matches{curr_animal}=unique(raw_data_task.workflow_type_name_merge(idx)  ,'stable');

                all_data_s2m{curr_animal}=raw_data_behavior.stim2move_med(idx,:);
                all_data_workflow_name{curr_animal}=raw_data_task.workflow_type_name_merge(idx);
                all_data_learned_day{curr_animal}=raw_data_task.learned_day(idx,:);
                clearvars('-except',preload_vars{:});

            end

          
                all_data_image=cell(9,1);



            pre_learn_data0=cell(length(animals{curr_group}),1);
            pre_learn_data0 = cellfun(@(x,y,z,l) ...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l(:,1)==0 ),1)...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);

            pre_learn_data0 = cellfun(@(x) x(1:end-2),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0 = cellfun(@(x) nanmean(cat(4,x{:}),4),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0= cellfun(@(x) ...
                [x repmat({nan(450,426,length(use_t))},1,1-length(x))],pre_learn_data0,'UniformOutput',false);


            pre_learn_data1=cell(length(animals{curr_group}),1);
            pre_learn_data1 = cellfun(@(x,y,z,l) ...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l(:,1)==0 ,2,'last'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            pre_learn_data1= cellfun(@(x) ...
                [x repmat({nan(450,426,length(use_t))},1,2-length(x))],pre_learn_data1,'UniformOutput',false);


            post_learn1_data1=cell(length(animals{curr_group}),1);
            post_learn1_data1 = cellfun(@(x,y,z,l)...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l(:,1)==1 ,2,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn1_data1= cellfun(@(x)...
                [x  repmat({nan(450,426,length(use_t))},1,2-length(x))],post_learn1_data1,'UniformOutput',false);

            post_learn2_data1=cell(length(animals{curr_group}),1);
            post_learn2_data1 = cellfun(@(x,y,z,l)...
                x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l(:,1)==1 ,5,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn2_data1 = cellfun(@(x) x(3:end),post_learn2_data1,'UniformOutput',false);
            post_learn2_data1= cellfun(@(x) ...
                [x  repmat({nan(450,426,length(use_t))},1,3-length(x))],post_learn2_data1,'UniformOutput',false);


            pre_learn_data2=cell(length(animals{curr_group}),1);
            pre_learn_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l(:,1)==0 ,2,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            pre_learn_data2= cellfun(@(x) [x  repmat({nan(450,426,length(use_t))},1,2-length(x))],pre_learn_data2,'UniformOutput',false);
            
            post_learn1_data2=cell(length(animals{curr_group}),1);
            post_learn1_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l(:,1)==1 ,2,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn1_data2= cellfun(@(x) [x repmat({nan(450,426,length(use_t))},1,2-length(x))],post_learn1_data2,'UniformOutput',false);


            post_learn2_data2=cell(length(animals{curr_group}),1);
            post_learn2_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l(:,1)==1 ,5,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn2_data2 = cellfun(@(x) x(3:end),post_learn2_data2,'UniformOutput',false);
            post_learn2_data2= cellfun(@(x) [x repmat({single(nan(450,426,length(use_t)))},1,3-length(x))],post_learn2_data2,'UniformOutput',false);

            first5day_data2=cell(length(animals{curr_group}),1);
            first5day_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))) ,5,'first'))...
                ,all_data_s2m,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            first5day_data2= cellfun(@(x) [x repmat({single(nan(450,426,length(use_t)))},1,5-length(x))],first5day_data2,'UniformOutput',false);



            n3_name='mixed VA';
            mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
            data3=cell(length(animals{curr_group}),1);
            data3(mixed_idx) = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last')),...
                all_data_s2m(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false);


            % itimvoe
            if curr_state==3
                data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),1)},1,3),...
                    (1:length(find(~mixed_idx)))', 'UniformOutput', false);
                data3= cellfun(@(x) [x  repmat({nan(450,426,length(use_t),1)},1,3-length(x))],data3,'UniformOutput',false);

                data_all=cellfun(@(a0,a,b,c,d,e,f,g,h) [a0 a b c d e f g h],pre_learn_data0, pre_learn_data1,post_learn1_data1,post_learn2_data1,...
                    pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,first5day_data2,'UniformOutput',false);

                all_data_image{8}=cellfun(@(x) mean(cat(5,x{:}),5),data3,'UniformOutput',false);

            else
                data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),2)},1,3),...
                    (1:length(find(~mixed_idx)))', 'UniformOutput', false);
                data3= cellfun(@(x) [x  repmat({nan(450,426,length(use_t),2)},1,3-length(x))],data3,'UniformOutput',false);
                data3=cellfun(@(x)   cellfun(@(y) {y(:,:,:,1) ,y(:,:,:,2)} ,x,'UniformOutput',false),data3,'UniformOutput',false);
                data3= cellfun(@(x)   reshape([x{:}],1,6),data3,'UniformOutput',false);

                data_all=cellfun(@(a0,a,b,c,d,e,f,g,h) [a0 a b c d e f g([1 3 5]) g([2 4 6]) h],pre_learn_data0, pre_learn_data1,post_learn1_data1,post_learn2_data1,...
                    pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,first5day_data2,'UniformOutput',false);

                all_data_image{8}=cellfun(@(x) mean(cat(5,x{[1 3 5]}),5,'omitnan'),data3,'UniformOutput',false);
                all_data_image{9}=cellfun(@(x) mean(cat(5,x{[2 4 6]}),5,'omitnan'),data3,'UniformOutput',false);

            end
            all_data_image{1}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),pre_learn_data0,'UniformOutput',false);

            all_data_image{2}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),pre_learn_data1,'UniformOutput',false);
            all_data_image{3}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),post_learn1_data1,'UniformOutput',false);
            all_data_image{4}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),post_learn2_data1,'UniformOutput',false);
            all_data_image{5}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),pre_learn_data2,'UniformOutput',false);
            all_data_image{6}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),post_learn1_data2,'UniformOutput',false);
            all_data_image{7}=cellfun(@(x) mean(cat(5,x{:}),5,'omitnan'),post_learn2_data2,'UniformOutput',false);



            all_data_image1= cellfun(@(x) cat(5,x{:}), all_data_image,'UniformOutput',false);
            all_data_image2{curr_group}{used_data,curr_state}=cat(6,all_data_image1{:});

            % data_all1=cellfun(@(x) cat(4,x{:}),data_all,'UniformOutput',false);
            all_data_cross_day{curr_group}{used_data}{curr_state}=data_all;
            % data_all_video=permute(max(all_data_image2{used_data,curr_state}(:,:,use_period,:,:,:),[],3),[1 2 4 5 6 3]);

            % clearvars('-except',main_preload_vars{:});
            %
        end

