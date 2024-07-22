
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

      % animals = {'DS001','AP019','AP021','AP022','AP018','AP020'};first_type=1;
            animals = {'DS007'};first_type=1;

 % animals = {'AP018','AP020'};first_type=1;

   % animals = {'DS000','DS003','DS004','DS005','DS006'};first_type=2;
  % animals = {'DS000','DS003','DS004'};first_type=2;
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
    for curr_idx=1:11

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
        data_task{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task{curr_idx}(:,:,1));
        data_task_kernels{curr_animal,curr_idx}=plab.wf.svd2px(U_master,raw_data_task.wf_px_task_kernels{curr_idx}(:,:,1));


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
figure

plot(fillmissing(cell2mat(all_data.average_90), 'linear', 2)','Color',[0.5 0.5 0.5])
hold on
h1=ap.errorfill((1:size(all_data.average_90,2)),all_data.average_mean_90, all_data.average_sem_90,[0,0,0],0.1,0.5);
legend([h1 ]);
plot(fillmissing(cell2mat(all_data.average_task_kernels), 'linear', 2)','Color',[0.5 0.5 1])
h2=ap.errorfill((1:size(all_data.average_90,2)),all_data.average_mean_task_kernels, all_data.average_sem_task_kernels,[0,0,1],0.1,0.5);

xlim([1 13])
ylim(0.001*[-1 3])
hold on
xline(7.5)
xline(2.5)
legend([h1 h2],{'visual passive','task kernels'});
   saveas(gcf,[Path 'figures\plot_lcr_passive_90_vs_task_kernels_' strjoin(animals, '_')], 'jpg');

   %
   figure
plot(fillmissing(cell2mat(all_data.average_8k), 'linear', 2)','Color',[0.5 0.5 0.5])
hold on
h1=ap.errorfill((1:size(all_data.average_8k,2)),all_data.average_mean_8k, all_data.average_sem_8k,[0,0,0],0.1,0.5);
legend([h1 ]);
plot(fillmissing(cell2mat(all_data.average_task_kernels), 'linear', 2)','Color',[0.5 0.5 1])
h2=ap.errorfill((1:size(all_data.average_8k,2)),all_data.average_task_kernels, all_data.average_task_kernels,[0,0,1],0.1,0.5);

xlim([1 13])
ylim(0.001*[-1 3])
hold on
xline(7.5)
xline(2.5)
legend([h1 h2],{'audio passive','task kernels'});
   saveas(gcf,[Path 'figures\plot_hml_passive_8k_vs_task_kernels_' strjoin(animals, '_')], 'jpg');

%% 画stimOn mPFC活动性，bar是每只小鼠的

image_90_1=cat(4,data_90{:,3:7});
image_90_2=cat(4,data_90{:,8:13});
image_8k_1=cat(4,data_8k{:,3:7});
image_8k_2=cat(4,data_8k{:,8:13});

row_avg_lcr_90 = cellfun(@(row) mean(cat(3, row{~cellfun('isempty', row)}), 3), num2cell(all_data.cross_time_90(:, 3:7), 2), 'UniformOutput', false);
plot_data_lcr_90=permute(cat(3,row_avg_lcr_90{:}), [2,3,1]);

row_avg_lcr_90_2 = cellfun(@(row) mean(cat(3, row{~cellfun('isempty', row)}), 3), num2cell(all_data.cross_time_90(:, 8:13), 2), 'UniformOutput', false);
plot_data_lcr_90_2=permute(cat(3,row_avg_lcr_90_2{:}), [2,3,1]);


row_avg_hml_8k = cellfun(@(row) mean(cat(3, row{~cellfun('isempty', row)}), 3), num2cell(all_data.cross_time_8k(:, 3:7), 2), 'UniformOutput', false);
plot_data_hml_8k=permute(cat(3,row_avg_hml_8k{:}), [2,3,1]);

row_avg_hml_8k_2 = cellfun(@(row) mean(cat(3, row{~cellfun('isempty', row)}), 3), num2cell(all_data.cross_time_8k(:, 8:13), 2), 'UniformOutput', false);
plot_data_hml_8k_2=permute(cat(3,row_avg_hml_8k_2{:}), [2,3,1]);


figure('Position',[50 50 1200 600]);
ax1=nexttile;
imagesc(mean(max(image_90_1(:,:,period_passive,:),[],3),4))
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

nexttile;
plot(t_passive,plot_data_lcr_90,'Color',[0.5 0.5 1]); hold on
h2=ap.errorfill(t_passive,mean(plot_data_lcr_90,2), std(plot_data_lcr_90'),[0,0,1],0.1,0.5);
ylim(0.001*[-2 3])
title('lcr passive R satge 1')

ax2=nexttile;
imagesc(mean(max(image_90_2(:,:,period_passive,:),[],3),4))
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax2,ap.colormap('PWG'));

nexttile;
plot(t_passive,plot_data_lcr_90_2,'Color',[0.5 0.5 1]); hold on
h2=ap.errorfill(t_passive,mean(plot_data_lcr_90_2,2), std(plot_data_lcr_90_2'),[0,0,1],0.1,0.5);
ylim(0.001*[-2 3])
title('lcr passive R stage 2')

ax3=nexttile;
imagesc(mean(max(image_8k_1(:,:,period_passive,:),[],3),4))
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax3,ap.colormap('PWG'));

nexttile;
plot(t_passive,plot_data_hml_8k,'Color',[1 0.5 0.5]); hold on
h2=ap.errorfill(t_passive,mean(plot_data_hml_8k,2), std(plot_data_hml_8k'),[1,0,0],0.1,0.5);
ylim(0.001*[-2 3])
title('hml passive 8k stage 1')

ax4=nexttile;
imagesc(mean(max(image_8k_2(:,:,period_passive,:),[],3),4))
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax4,ap.colormap('PWG'));


nexttile;
plot(t_passive,plot_data_hml_8k_2,'Color',[1 0.5 0.5]); hold on
h2=ap.errorfill(t_passive,mean(plot_data_hml_8k_2,2), std(plot_data_hml_8k_2'),[1,0,0],0.1,0.5);
ylim(0.001*[-2 3])
title('hml passive 8k stage 2')

sgtitle(strjoin(animals, '; '))
   saveas(gcf,[Path 'figures\plot_stimOn_average_' strjoin(animals, '_')], 'jpg');

%%
lcr_type1_90=data_90(:,2:6);
lcr_type2_90=data_90(:,7:12);
data_lcr_type1_90=cat(4,lcr_type1_90{:});
data_lcr_type2_90=cat(4,lcr_type2_90{:});

lcr_type1_n90=data_n90(:,2:6);
lcr_type2_n90=data_n90(:,7:12);
data_lcr_type1_n90=cat(4,lcr_type1_n90{:});
data_lcr_type2_n90=cat(4,lcr_type2_n90{:});

lcr_type1_0=data_0(:,2:6);
lcr_type2_0=data_0(:,7:12);
data_lcr_type1_0=cat(4,lcr_type1_0{:});
data_lcr_type2_0=cat(4,lcr_type2_0{:});



hml_type1_8k=data_8k(:,2:6);
hml_type2_8k=data_8k(:,7:12);
data_hml_type1_8k=cat(4,hml_type1_8k{:});
data_hml_type2_8k=cat(4,hml_type2_8k{:});

hml_type1_4k=data_4k(:,2:6);
hml_type2_4k=data_4k(:,7:12);
data_hml_type1_4k=cat(4,hml_type1_4k{:});
data_hml_type2_4k=cat(4,hml_type2_4k{:});


hml_type1_12k=data_12k(:,2:6);
hml_type2_12k=data_12k(:,7:12);
data_hml_type1_12k=cat(4,hml_type1_12k{:});
data_hml_type2_12k=cat(4,hml_type2_12k{:});



task_type1=data_task(:,2:6);
task_type2=data_task(:,7:12);
data_task_type1=cat(4,task_type1{:});
data_task_type2=cat(4,task_type2{:});

task_kernels_type1=data_task_kernels(:,2:6);
task_kernels_type2=data_task_kernels(:,7:12);
data_task_kernels_type1=cat(4,task_kernels_type1{:});
data_task_kernels_type2=cat(4,task_kernels_type2{:});



 %% draw figure

 figure('Position',[0 50 600 1200]);
 t = tiledlayout(8, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(strjoin(animals, ' ; '))
 t_type= tiledlayout(t,1,4);
    t_type.Layout.Tile = 1;


ax1=nexttile(t_type);
imagesc(mean(max(data_task_type1(:,:,period_task,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.018.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
if first_type==1
    title('visual task days')
else title('audio task days')
end
    text(-100, 200, sprintf('task'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);

ax1=nexttile(t_type);
imagesc(mean(max(data_task_type2(:,:,period_task,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.018.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
if first_type==1
    title('audio task days')
else title('visual task days')
end


ax1=nexttile(t_type);
imagesc(t_task,[],all_data.cross_time_average_task');
clim(0.005*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),all_data.average_task, all_data.average_sem_task,[0,0,0],0.1,0.5);
xline(6)




 t_type= tiledlayout(t,1,4);
    t_type.Layout.Tile = 2;

ax1=nexttile(t_type);
imagesc(mean(max(data_task_kernels_type1(:,:,period_kernels,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

    text(-100, 200, sprintf('task_kernels'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);

ax1=nexttile(t_type);
imagesc(mean(max(data_task_kernels_type2(:,:,period_kernels,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
if first_type==1
    title('audio task days')
else title('visual task days')
end


ax1=nexttile(t_type);
imagesc(t_kernels,[],all_data.cross_time_average_task_kernels');
clim(0.005*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),task_kernels_average, task_kernels_sem,[0,0,0],0.1,0.5);
xline(6)



t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 3;

%lcr passive
ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type1_90(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive 90'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);


ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type2_90(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],lcr_cross_time_90);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),lcr_average_90, lcr_sem_90,[0,0,0],0.1,0.5);
xline(6)


t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 4;


ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type1_n90(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive -90'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);


ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type2_n90(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],lcr_cross_time_n90);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),lcr_average_n90, lcr_sem_n90,[0,0,0],0.1,0.5);
xline(6)


t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 5;


ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type1_0(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive 0'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);


ax1=nexttile(t_type);
imagesc(mean(max(data_lcr_type2_0(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],lcr_cross_time_0);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),lcr_average_0, lcr_sem_0,[0,0,0],0.1,0.5);
xline(6)




%hml passive

t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 6;


ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type1_8k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive 8k'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);

ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type2_8k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],hml_cross_time_8k);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),hml_average_8k, hml_sem_8k,[0,0,0],0.1,0.5);hold on
xline(6)


t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 7;



ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type1_12k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive 12k'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);

ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type2_12k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],hml_cross_time_12k);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type)
ap.errorfill((1:12),hml_average_12k, hml_sem_12k,[0,0,0],0.1,0.5);hold on
xline(6)


t_type= tiledlayout(t,1,4);
t_type.Layout.Tile = 8;


ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type1_4k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));
    text(-100, 200, sprintf('passive 4k'), 'Rotation', 90, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontSize', 12);

ax1=nexttile(t_type);
imagesc(mean(max(data_hml_type2_4k(:,:,period_passive,:),[],3),4));
axis image off;
ap.wf_draw('ccf','black');
clim(0.008.*[-1,1]);
colormap(ax1,ap.colormap('PWG'));

ax1=nexttile(t_type);
imagesc(t_passive,[],hml_cross_time_4k);
clim(0.002*[0,1])
colorbar
colormap(ax1,ap.colormap('WG'));
yline(6.5)

ax1=nexttile(t_type);
ap.errorfill((1:12),hml_average_4k, hml_sem_4k,[0,0,0],0.1,0.5);hold on
xline(6)



   saveas(gcf,[Path 'figures\all averaged images _' strjoin(animals, '_')], 'jpg');


