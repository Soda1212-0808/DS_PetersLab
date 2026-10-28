clc
clear
Path='D:\Data process\project_SNr\data\ephys_data\package';

passive_workflows={'lcr_passive_white_circle_size40','lcr_passive_black_square',...
    'lcr_passive_grating_size40','lcr_passive_checkerboard','lcr_passive_squareHorizontalStripes'};

 animals={'DS036','DS041','DS043'};
rec_days_all={{'2026-08-25','2026-08-28'},...
    {'2026-08-24','2026-08-25','2026-08-28','2026-08-31'},...
    {'2026-08-25'}};

for i = 1:numel(animals)
    animal_rec_days{i} = cellfun(@(day) [animals{i} ' ' day], ...
        rec_days_all{i}, 'UniformOutput', false);
end
animal_rec_days = [animal_rec_days{:}];



position_all={{'l','r'},{'l','l','r','r'},{'l'}};

%
temp_data_task=cell(length(animals),1);
temp_data_passive=cell(length(animals),1);
temp_data_behavior=cell(length(animals),1);
for curr_animal=1:length(animals)
        animal=animals{curr_animal};
        rec_days=rec_days_all{curr_animal};
        data=load(fullfile(Path,[animal '_all_data.mat' ]));

        data_id=find(ismember(data.day,rec_days));

        temp_data_task{curr_animal}=data.ephys_task(data_id);

        temp_data_passive{curr_animal}= arrayfun(@(day) ...
            cellfun(@(x) data.(['ephys_' x] ){day},passive_workflows,'UniformOutput',false),data_id,'UniformOutput',false);
        
        temp_data_behavior{curr_animal}=data.behavior_task(data_id);
end


data_task_all=cat(1,temp_data_task{:});
data_passive_all=cat(1,temp_data_passive{:});
data_behavior_all=cat(1,temp_data_behavior{:});


%%  behavior

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);

data_reaction_time=feval(@(a)  cat(2,a{:}), cellfun(@(x) x.stim2move_f_stats(:,2),...
    data_behavior_all,'UniformOutput',false));
data_reaction_time_group= mat2cell(data_reaction_time, ones(size(data_reaction_time,1),1), size(data_reaction_time,2));


data_wheel_move=feval(@(s) cat(3,s{:}),...
    cellfun(@(x) feval(@(s)  cat(1,s{:}) ,...
    cellfun(@(a)   nanmean(a,1), x.stim_move_aligned_wheel_vel,'UniformOutput',false )),...
    data_behavior_all,'UniformOutput',false));
data_wheel_move_mean=nanmean(data_wheel_move,3);
data_wheel_move_error=nanstd(data_wheel_move,0,3)./sqrt(size(data_wheel_move,3));

data_iti_move_num=feval(@(s) cat(2,s{:}), cellfun(@(x) cellfun(@(a) size(a,1) ,x.iti_move_aligned_wheel_vel,'UniformOutput',true),...
    data_behavior_all,'UniformOutput',false))
data_iti_move_num_group= mat2cell(data_iti_move_num, ones(size(data_iti_move_num,1),1), size(data_iti_move_num,2));

data_iti_move_vel=feval(@(s) cat(2,s{:}), cellfun(@(x) cellfun(@(a) nanmean(a,1) ,...
    x.iti_move_aligned_wheel_vel,'UniformOutput',false),...
    data_behavior_all,'UniformOutput',false));



figure;
colors1=[0,0,1;1,0,0;0,0,0];

colors2=[0,0,1;0.5,0.5,1;1,0,0;1,0.5,0.5;0,0,0;0.5,0.5,0.5];
nexttile
ds.make_bar_plot(data_reaction_time_group,'ColorCell',colors1)
ylabel('reaction time (s)')
xticks([1:3])
xticklabels({'white circle','black square','grating'})
nexttile
ap.errorfill(surround_time_points,data_wheel_move_mean',data_wheel_move_error',colors2)
xlim([-0.2 1])
ylim([-2800 2800])
ylabel('wheel move')
axis off
title ('velocity')

figure;
nexttile
ds.make_bar_plot(data_iti_move_num_group,'ColorCell',colors1(1:2,:))
ylabel('iti move num')

nexttile
ap.errorfill(surround_time_points,...
    nanmean(cat(1,data_iti_move_vel{1,:}),1),...
    nanstd(cat(1,data_iti_move_vel{1,:}),0,1)./sqrt(size(cat(1,data_iti_move_vel{1,:}),1)),'b')
ap.errorfill(surround_time_points,...
    nanmean(cat(1,data_iti_move_vel{2,:}),1),...
    nanstd(cat(1,data_iti_move_vel{2,:}),0,1)./sqrt(size(cat(1,data_iti_move_vel{2,:}),1)),'r')
xlim([-0.5 2])
ylim([-1500 1500])
ylabel('iti wheel move')


%%

brain_region='SNr';
idx =cellfun(@(data) find(ismember(data.probe_histology.acronym,brain_region)), data_task_all,'UniformOutput',false);
region_dist=cellfun(@(data,id) arrayfun(@(probe)...
    data.probe_histology.tip_distance(id(data.probe_histology.probe_shank(id)==probe),:),...
    1:4,'UniformOutput',false), data_task_all,idx,'UniformOutput',false);

region_id=cellfun(@(data,dist) find(feval(@(x) sum( cat(2,x{:}),2), arrayfun(@(probe)...
    data.depth>dist{probe}(2) & ...
    data.depth<dist{probe}(1)...
    &  data.shank==probe,find(~cellfun(@isempty, dist)),'UniformOutput',false))),...
    data_task_all,region_dist,'UniformOutput',false);
label_id_unit=cellfun(@(x)  find(~ismember(x.unit_label,'axon')) ,data_task_all,'UniformOutput',false);



temp_position=cat(2,position_all{:});
temp_l_id=ismember(temp_position,'l')
temp_r_id=ismember(temp_position,'r')

[~,label_idx]=cellfun(@(x) ismember...
    ({'stim_0correct','stim_1correct','stim_2correct','stim_0error','stim_1error','stim_2error'},...
    x.labels),data_task_all,'UniformOutput',false);


temp_psth_task=...
    cellfun(@(data,label,id,cell_id)data.psth(intersect(id,cell_id),:,label),...
    data_task_all,label_idx,region_id,label_id_unit,'UniformOutput',false);


psth_task_all=cat(1,temp_psth_task{:});
psth_task_l=cat(1,temp_psth_task{temp_l_id});
psth_task_r=cat(1,temp_psth_task{temp_r_id});

temp_respo_task=...
    cellfun(@(data,label)  cat(2, data.response_p{label}),data_task_all,label_idx,'UniformOutput',false);
temp_respo_task1=...
    cellfun(@(task,id,cell_id)   task(intersect(id,cell_id),:) ,temp_respo_task,region_id,label_id_unit,'UniformOutput',false);




temp_psth_passive=...
    cellfun(@(data,id,cell_id) ...
    feval(@(a)  cat(3,a{:}), cellfun(@(x) x.psth(intersect(id,cell_id),:,2)  ,data,'UniformOutput',false)),...
    data_passive_all,region_id,label_id_unit,'UniformOutput',false);
psth_passive_all=cat(1,temp_psth_passive{:});
psth_passive_l=cat(1,temp_psth_passive{temp_l_id});
psth_passive_r=cat(1,temp_psth_passive{temp_r_id});


temp_respo_passive=...
    cellfun(@(data,id,cell_id) ...
    feval(@(a)  cat(2,a{:}), cellfun(@(x) x.response_p{2}(intersect(id,cell_id))  ,data,'UniformOutput',false)),...
    data_passive_all,region_id,label_id_unit,'UniformOutput',false);


temp_psth_all=cat(3,psth_task_all,psth_passive_all);
temp_psth_l=cat(3,psth_task_l,psth_passive_l);
temp_psth_r=cat(3,psth_task_r,psth_passive_r);


raster_t=data_task_all{1}.raster_t;
temp_peak=permute(nanmean(temp_psth_all(:,raster_t>0&raster_t<0.2,:),2),[1,3,2]);


temp_raster_task=...
    cellfun(@(data,label,id,cell_id)         cellfun(@(a) a(:,:,intersect(id,cell_id)) ,data.raster(label),'UniformOutput',false),...
    data_task_all,label_idx,region_id,label_id_unit,'UniformOutput',false);



temp_raster_passive=...
    cellfun(@(data,id,cell_id) ...
    cellfun(@(x) x.raster{2}(:,:,intersect(id,cell_id))  ,data,'UniformOutput',false)',...
    data_passive_all,region_id,label_id_unit,'UniformOutput',false);

temp_raster_all=cellfun(@(a,b)  cat(1,a,b), temp_raster_task,temp_raster_passive,'UniformOutput',false  );


temp_psth_stim2move=...
    cellfun(@(data)data.stim2move,...
    data_task_all,'UniformOutput',false);

temp_raster_task_all=cellfun(@(a) cat(1,a{:}),temp_raster_task,'UniformOutput',false  )

% label_id_unit=cellfun(@(x)  find(ismember(x.unit_label,'axon')) ,data_task_all,'UniformOutput',false);

%% recording position
ap.ccf_outline_3d([],{brain_region});
hold on
cellfun(@(x,y)...
    scatter3(x.ccf(y,1),...
    x.ccf(y,3),...
    x.ccf(y,2),10,'k','filled'),...
    data_task_all,region_id,'UniformOutput',false);
%% singLe recording

curr_recording=7

% ap.ccf_outline_3d([],{brain_region});
% hold on
% cellfun(@(x,y)...
%     scatter3(x.ccf(y,1),...
%     x.ccf(y,3),...
%     x.ccf(y,2),10,'k','filled'),...
%     data_task_all(curr_recording),region_id(curr_recording),'UniformOutput',false);


temp_passive_peak_all= cellfun(@(x) permute(sum(x(:,raster_t>0&raster_t<0.2,:),2),[1,3,2]),temp_psth_passive,'uni',false);

ap.ccf_outline_3d([],{brain_region});
hold on
cellfun(@(x,y)...
    scatter3(x.ccf(y,1),...
    x.ccf(y,3),...
    x.ccf(y,2),10,'filled','MarkerFaceColor',[0.8 0.8 0.8]),...
    data_task_all(curr_recording),region_id(curr_recording),'UniformOutput',false);
hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,1)>0.95),1),...
    data.ccf(id(repo(:,1)>0.95),3),...
    data.ccf(id(repo(:,1)>0.95),2),4*sqrt(peak(repo(:,1)>0.95,1)),'b','filled'),...
    data_task_all(curr_recording),region_id(curr_recording),temp_respo_passive(curr_recording),temp_passive_peak_all(curr_recording),'UniformOutput',false);

hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,2)>0.95),1),...
    data.ccf(id(repo(:,2)>0.95),3),...
    data.ccf(id(repo(:,2)>0.95),2),4*sqrt(abs(peak(repo(:,2)>0.95,2))),'r','filled'),...
    data_task_all(curr_recording),region_id(curr_recording),temp_respo_passive(curr_recording),temp_passive_peak_all(curr_recording),'UniformOutput',false);
hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),1),...
    data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),3),...
    data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),2),...
    4*sqrt(abs(max(peak(repo(:,2)>0.95&repo(:,1)>0.95,1:2),[],2))),'g','filled'),...
    data_task_all(curr_recording),region_id(curr_recording),temp_respo_passive(curr_recording),temp_passive_peak_all(curr_recording),'UniformOutput',false);
%%

figure;

temp_raster= cat(1,temp_raster_task{curr_recording});

stim_move=temp_psth_stim2move{curr_recording};

[stim_move_all,temp_sort]=cellfun(@(a) sort(a,'ascend'), stim_move,'UniformOutput',false );
temp_raster_sort=cellfun(@(a,idx)   a(idx,:,:) ,temp_raster,temp_sort,'UniformOutput',false);
temp_raster_sort=cat(1,temp_raster_sort{:});

raster_baseline = repmat(nanmean(temp_raster_sort(:,raster_t>-0.5&raster_t<0,:),2),[1 size(temp_raster_sort,2) 1]);
temp_raster1 = (temp_raster_sort - raster_baseline)./(raster_baseline + 1);

imagesc(raster_t,[],smoothdata(nanmean(temp_raster1,3),2,'gaussian',11))
hold on
plot(cat(1,stim_move_all{:}),1:length(cat(1,stim_move_all{:})), 'r.', 'MarkerSize', 5)
 clim([-10 10])
colormap(ap.colormap('kwg'))
 xlim([-0.2 0.5])
%%  single recording
for curr_recording =1:length(temp_psth_task)
temp_psth_merge=cellfun(@(x,y) cat(3,x,y), temp_psth_task,temp_psth_passive,'UniformOutput',false );
figure('Name', sprintf(['PSTH = ' animal_rec_days{curr_recording}  ] ), 'NumberTitle', 'off');

tiledlayout(3,11)
for curr_row=1:3
    [~ ,temp_order]=sort(nanmean(temp_psth_merge{curr_recording}(:,raster_t>0&raster_t<0.2,curr_row),2),'descend');
    for curr_collum=1:size(temp_psth_merge{curr_recording},3)
        nexttile

        imagesc(raster_t,[],temp_psth_merge{curr_recording}(temp_order,:,curr_collum))
        clim([-2 2])
        colormap(ap.colormap('kwg'))
        xlim([-0.2 0.5])
    end
end
drawnow
% GPFA
dat=struct;
idx = 0;
for curr_row=1:length(temp_raster_all{curr_recording})
    for curr_trial=1:size(temp_raster_all{curr_recording}{curr_row},1)
        idx=idx+1;
        dat(idx).trialId=idx;
        dat(idx).spikes=permute(temp_raster_all{curr_recording}{curr_row}(curr_trial,500: 1500,:)./1000,[3,2,1]);
        dat(idx).label=curr_row;
    end
end

result = neuralTraj(dat,'datFormat', 'spikes', ...
    'method', 'gpfa', 'xDims', 3, 'kernSDList', 30);
[estParams, seqTrain] = postprocess(result, 'kernSD', 30);
% plot3D(seqTrain, 'xorth', 'dimsToPlot', 1:3);

figure('Name', sprintf(['GPFA recoridng = ' animal_rec_days{curr_recording}  ] ), 'NumberTitle', 'off');
colors={[0 0 1],[1 0 0],[0 1 0],[0.4 0.4 1],[1 0.4 0.4],[0.4 1 0.4],[0.8 0.8 1],[1 0.8 0.8],[0.8 1 0.8],[0.5 0.5 0.5],[0.8 0.8 0.8]};
hold on
arrayfun(@(n)  plot3(seqTrain(n).xorth(1,:),seqTrain(n).xorth(2,:),seqTrain(n).xorth(3,:),'Color',colors{dat(n).label} ) ,...
    1:length(seqTrain),'UniformOutput',false)
view(3)


%PCA

temp_psth_all_smooth=smoothdata(temp_psth_merge{curr_recording}(:,501:650,:),2,"gaussian",5);
[nNeurons,nTime,nEvent] = size(temp_psth_all_smooth);

% time × trial × neuron
tmp = permute(temp_psth_all_smooth, [2 3 1]);
% (time*trial) × neuron
X = reshape(tmp, [], nNeurons);
% 所有 trials 共用一个 PCA space
[coeff, score, ~, ~, explained] = pca(X);

% 重新变成 time × trial × PC
scoreTrial = reshape(score, nTime, nEvent, []);
figure('Name', sprintf(['PCA recoridng = ' animal_rec_days{curr_recording}  ] ), 'NumberTitle', 'off');
hold on;
colors={[0 0 1],[1 0 0],[0 1 0],[0.3 0.3 1],[1 0.3 0.3],[0.3 1 0.3],[0.5 0.5 1],[0.9 0.5 0.5],[0.5 1 0.5],[0.5 0.5 0.5],[0.8 0.8 0.8]}
lineWidth=[10 10 10 5 5 5 3 3 3 3 3]
for tr = 1:nEvent
    plot3(scoreTrial(:,tr,1), ...
        scoreTrial(:,tr,2), ...
        scoreTrial(:,tr,3),'Color',colors{tr},'LineWidth',lineWidth(tr));
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
view(3);
legend({'TWC','TBC','TGC','TWE','TBE','TGE','PW','PB','PG'})
end
%%
% respo_passive_all=cat(1,temp_respo_passive{:})
% 
% psth_passive_all(respo_passive_all(:,1)>0.95&respo_passive_all(:,2)>0.95,:,:)
%%  PCA
figure
for curr_row=1:size(temp_psth_all,3)
nexttile
imagesc(temp_psth_all(:,:,curr_row))
clim([-2 2])
        colormap(ap.colormap('kwg'))
end
  task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)>0.95|repo(:,2)>0.95|repo(:,3)>0.95),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));


temp_psth_all_smooth=smoothdata(temp_psth_all(:,501:650,:),2,"gaussian",5);
[nNeurons,nTime,nEvent] = size(temp_psth_all_smooth);

% time × trial × neuron
tmp = permute(temp_psth_all_smooth, [2 3 1]);
% (time*trial) × neuron
X = reshape(tmp, [], nNeurons);
% 所有 trials 共用一个 PCA space
[coeff, score, ~, ~, explained] = pca(X);

% 重新变成 time × trial × PC
scoreTrial = reshape(score, nTime, nEvent, []);
figure;
hold on;
colors={[0 0 1],[1 0 0],[0 1 0],[0.3 0.3 1],[1 0.3 0.3],[0.3 1 0.3],[0.5 0.5 1],[0.9 0.5 0.5],[0.5 1 0.5],[0.5 0.5 0.5],[0.8 0.8 0.8]}
lineWidth=[10 10 10 5 5 5 3 3 3 3 3]
for tr = 1:nEvent
    plot3(scoreTrial(:,tr,1), ...
        scoreTrial(:,tr,2), ...
        scoreTrial(:,tr,3),'Color',colors{tr},'LineWidth',lineWidth(tr));
end

xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
view(3);

%%  cell_position

temp_passive_peak_all= cellfun(@(x) permute(sum(x(:,raster_t>0&raster_t<0.2,:),2),[1,3,2]),temp_psth_passive,'uni',false);


ap.ccf_outline_3d([],{brain_region});
hold on
cellfun(@(x,y)...
    scatter3(x.ccf(y,1),...
    x.ccf(y,3),...
    x.ccf(y,2),10,'filled','MarkerFaceColor',[0.8 0.8 0.8]),...
    data_task_all,region_id,'UniformOutput',false);
hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,1)>0.95),1),...
    data.ccf(id(repo(:,1)>0.95),3),...
    data.ccf(id(repo(:,1)>0.95),2),4*sqrt(peak(repo(:,1)>0.95,1)),'b','filled'),...
    data_task_all,region_id,temp_respo_passive,temp_passive_peak_all,'UniformOutput',false);

hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,2)>0.95),1),...
    data.ccf(id(repo(:,2)>0.95),3),...
    data.ccf(id(repo(:,2)>0.95),2),4*sqrt(abs(peak(repo(:,2)>0.95,2))),'r','filled'),...
    data_task_all,region_id,temp_respo_passive,temp_passive_peak_all,'UniformOutput',false);
hold on
cellfun(@(data,id,repo,peak)...
    scatter3(data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),1),...
    data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),3),...
    data.ccf(id(repo(:,2)>0.95&repo(:,1)>0.95),2),...
    4*sqrt(abs(max(peak(repo(:,2)>0.95&repo(:,1)>0.95,1:2),[],2))),'g','filled'),...
    data_task_all,region_id,temp_respo_passive,temp_passive_peak_all,'UniformOutput',false);

%% cell proportion


repo_proportion=arrayfun(@(passive) cellfun(@(x) nanmean(x(:,passive)>0.95)  ,temp_respo_passive,'UniformOutput',true ),1:5,'uni',false)
repo_tri=cellfun(@(x) sum(x(:,1)>0.95&x(:,2)>0.95&x(:,3)>0.95)./sum(x(:,1)>0.95&x(:,2)>0.95&x(:,3)>0.95)  ,temp_respo_passive,'UniformOutput',true )
figure;
ds.make_bar_plot(repo_proportion)
xticks(1:numel(repo_proportion)); xticklabels(passive_workflows);
ylabel('proportion')
title('passive resposive cell')

cellfun(@(x) sum(x(:,1)>0.95&x(:,2)>0.95)./sum(x(:,1)>0.95|x(:,2)>0.95)  ,temp_respo_passive,'UniformOutput',true )

%% passive psth
figure;
titles={'task_white_sircle','task_black_square','task_grating_circle'} 
tiledlayout(6,6)

for curr_row=1:6
    switch curr_row
        case 1
            passive_only= feval(@(A)  cat(1,A{:}),...
                cellfun(@(passive,repo) passive((repo(:,1)>0.95&repo(:,2)<0.95),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));

        case 2
            passive_only= feval(@(A)  cat(1,A{:}),...
                cellfun(@(passive,repo) passive((repo(:,1)>0.95&repo(:,2)>0.95),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));
        case 3
            passive_only= feval(@(A)  cat(1,A{:}),...
                cellfun(@(passive,repo) passive((repo(:,2)>0.95&repo(:,1)<0.95),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));
        case 4
            passive_only= feval(@(A)  cat(1,A{:}),...
                  cellfun(@(passive,repo) passive((repo(:,1)<0.05&repo(:,2)>0.05),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));
        case 5
            passive_only= feval(@(A)  cat(1,A{:}),...
                cellfun(@(passive,repo) passive((repo(:,1)<0.05&repo(:,2)<0.05),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));
        case 6
            passive_only= feval(@(A)  cat(1,A{:}),...
                cellfun(@(passive,repo) passive((repo(:,1)>0.05&repo(:,2)<0.05),:,:) ,...
                temp_psth_passive,temp_respo_passive,'UniformOutput',false ));
      
    end
   [ temp_peak,peak_idx]=sort(nanmean(passive_only(:,raster_t>0&raster_t<0.2,1),2),'descend');


    psth_mean=permute(nanmean(passive_only,1),[2,3,1]);
    psth_error=permute(nanstd(passive_only,0,1)./sqrt(size(passive_only,1)),[2,3,1]);
    for curr_passive=1:5
        nexttile
        imagesc(raster_t,[],passive_only(peak_idx,:,curr_passive))
        clim([-2 2])
        colormap(ap.colormap('kwg'))
        if curr_row==1
            title(passive_workflows{curr_passive})
        end
        xlim([-0.2 0.5])
        ylim([.5 80.5])
        xline(0,'LineStyle',':')
        axis off


    end
    nexttile
    colors=[0 0 1; 1 0 0 ;0 0 0;0.5 0.5 0.5; 0.8 0.8 0.8]
    ap.errorfill(raster_t,psth_mean(:,1:3),psth_error(:,1:3),colors)
    xlim([-0.2 0.5])
    axis off

    legend({'','white circle','','black square','','grating circle','','checkerboard','','stripe'},'box','off','Location','eastoutside')
end


%% task psth
titles={'task_white_sircle','task_black_square','task_grating_circle','task_white_sircle','task_black_square','task_grating_circle'} 

figure;
tiledlayout(6,6)
for curr_row=1:6
    switch curr_row
        case 1
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)>0.95&repo(:,2)<0.5),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));
        case 2
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)>0.95&repo(:,1)>0.95),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));
        case 3
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)<0.5&repo(:,2)>0.95),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false))

        case 4
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)<0.05&repo(:,2)>0.5),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));
        case 5
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)<0.05&repo(:,1)<0.05),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));
        case 6
            task1olny= feval(@(A)  cat(1,A{:}),...
                cellfun(@(task,repo) task((repo(:,1)>0.5&repo(:,2)<0.05),:,:) ,...
                temp_psth_task,temp_respo_task1,'UniformOutput',false));
     
         
    end

    [ temp_peak,peak_idx]=sort(nanmean(task1olny(:,raster_t>0&raster_t<0.2,1),2),'descend');


    psth_mean=permute(nanmean(task1olny,1),[2,3,1]);
    psth_error=permute(nanstd(task1olny,0,1)./sqrt(size(task1olny,1)),[2,3,1]);
    for curr_task=1:6
        nexttile
        imagesc(raster_t,[],task1olny(peak_idx,:,curr_task))
        clim([-2 2])
        colormap(ap.colormap('kwg'))
        ylim([0 320])
        xlim([-0.2 0.5])

        axis off
        if curr_row==1
            title(titles{curr_task})

        end

     
     end
    % nexttile
    % colors=[0 0 1; 1 0 0 ;0 0 0;0 0 1; 1 0 0 ;0 0 0];
    % ap.errorfill(raster_t,psth_mean,psth_error,colors)
    % xlim([-0.2 0.5])
    % 
    % legend({'','white circle','','black square','','grating circle'},'box','off','Location','eastoutside')

end



task1olny= feval(@(A)  cat(1,A{:}),...
    cellfun(@(task,repo) task((repo(:,1)>0.95&repo(:,1)>0.95),:,:) ,...
    temp_psth_task,temp_respo_task1,'UniformOutput',false));
psth_mean=permute(nanmean(task1olny,1),[2,3,1]);
psth_error=permute(nanstd(task1olny,0,1)./sqrt(size(task1olny,1)),[2,3,1]);
colors=[0 0 1; 1 0 0 ;0 0 0;0.5 0.5 1; 1 0.5 0.5 ;0.5 0.5 0.5];
figure;
nexttile
ap.errorfill(raster_t,psth_mean,psth_error,colors)
xlim([-0.2 0.5])



temp_wheel_vel=...
    feval(@(w)  cat(3,w{:}),...
    cellfun(@(behav)...
    feval(@(s) cat(1,s{:}),cellfun(@(a) nanmean(a,1) , behav.stim_aligned_wheel_vel,'UniformOutput',false )) ,...
    data_behavior_all,'UniformOutput',false));
% nexttile
wheel_vel_mean=nanmean(temp_wheel_vel,3);
wheel_vel_error=nanstd(temp_wheel_vel,0,3)./sqrt(size(temp_wheel_vel,3));
colors2=[0,0,1;0.5,0.5,1;1,0,0;1,0.5,0.5;0,0,0;0.5,0.5,0.5];

nexttile
ap.errorfill(surround_time_points,abs(wheel_vel_mean)',wheel_vel_error',colors2)
xlim([-0.2 0.5])

%%
figure;
tiledlayout(8,8)
task_titles=[{'task_white_sircle','task_black_square','task_grating_circle'} passive_workflows]
for curr_peak=1:size(temp_psth_all,3)
    [~,peak_id]=sort(temp_peak(:,curr_peak),'descend');

for curr_psth=1:size(temp_psth_all,3)
    nexttile
imagesc(raster_t,[],  temp_psth_all(peak_id,:,curr_psth))
clim([-2 2])
colormap(ap.colormap('pwg'))
if curr_peak==1
% title(task_titles{curr_psth})
end
end
end

%%
temp_psth_plot_mean=squeeze(nanmean(temp_psth_all,1));
temp_psth_plot_error=squeeze(nanstd(temp_psth_all,0,1)./sqrt(size(temp_psth_all,1)));

temp_psth_l_plot_mean=squeeze(nanmean(temp_psth_l,1));
temp_psth_l_plot_error=squeeze(nanstd(temp_psth_l,0,1)./sqrt(size(temp_psth_l,1)));

temp_psth_r_plot_mean=squeeze(nanmean(temp_psth_r,1));
temp_psth_r_plot_error=squeeze(nanstd(temp_psth_r,0,1)./sqrt(size(temp_psth_r,1)));
colors=[0 0 1; 1 0 0; 0.5 0.5 1; 1 0.5 0.5 ; 0.5 1 0.5;0 0 0;0 0 0]

figure
nexttile
ap.errorfill(raster_t,temp_psth_plot_mean,temp_psth_plot_error,colors)
title('all-SNr')

nexttile
ap.errorfill(raster_t,temp_psth_l_plot_mean,temp_psth_l_plot_error,colors)
title('L-SNr')
nexttile
ap.errorfill(raster_t,temp_psth_r_plot_mean,temp_psth_r_plot_error,colors)
title('R-SNr')