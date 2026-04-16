clear all

surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.2);

surround_window = [-0.5,1];
mousecam_framerate = 30;
face_time = surround_window(1):1/mousecam_framerate:surround_window(2);


U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');

Path='D:\Data process\project_cross_model\wf_data\data_package';
  

%%  nose movement
groups_name={'VA','AV'};
modes_name={'Visual','Auditory'};
all_data=struct;

for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};
    end
    for curr_mode=1:2

        temp_data_all=table;
        for curr_animal=1:length(animals)
            preload_vars=who;
            animal=animals{curr_animal};
            data_all=load(fullfile(Path,[animal '_all_data.mat']));
            switch curr_mode
                case 1
                    select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1')|...
                        strcmp([data_all.task_name],'stim_wheel_right_stage2'))&...
                        ~cellfun(@isempty ,data_all.wf_lcr_passive);
                    all_face_passive=[data_all.face_lcr_passive(select_id)];
                case 2
                    select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|...
                        strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume'))&~cellfun(@isempty ,data_all.wf_hml_passive_audio);
                                    all_face_passive=[data_all.face_hml_passive_audio(select_id)];

            end


            temp_pupil=cellfun(@(x)  cat(3,x.pupil_data.diameterZ_filt_sav{:}) ,all_face_passive,'UniformOutput',false)


            tem_nose_passive= cellfun(@(id)  cellfun(@(x)   vecnorm(diff(x(:,:,1:9,:),1,2), 2, 4) ,...
                id.face_data,'UniformOutput',false),all_face_passive,'UniformOutput',false);

            temp_nose_mean=...
                feval(@(b)  cat(4,b{:}), cellfun(@(id) feval(@(a)  cat(3,a{:}) ,cellfun(@(x) permute(nanmean(x,1),[2,3,1]), id,'UniformOutput',false)),...
                tem_nose_passive,'UniformOutput',false));
            temp_face_error= feval(@(b)  cat(4,b{:}), cellfun(@(id) feval(@(a)  cat(3,a{:}) ,cellfun(@(x) permute(std(x,0,1)./sqrt(size(x,1)),[2,3,1]), id,'UniformOutput',false)),...
                tem_nose_passive,'UniformOutput',false));

            temp_p_val=arrayfun(@(id)  data_all.behavior_task{id}.rxn_l_p(1)<0.05, find(select_id),'UniformOutput',true);


            temp_data_all.nose_passive{curr_animal}=temp_nose_mean;
            temp_data_all.rxt{curr_animal}=temp_p_val;
temp_data_all.pupil_size{curr_animal}=temp_pupil;
            clearvars('-except',preload_vars{:});
        end
       
        
        all_data.([groups_name{curr_group} '_' modes_name{curr_mode}])=temp_data_all;

        nose_data_all=cellfun(@(x,y)  cat(4, x(:,:,:,find(y==1,5,'first')),nan(size(x,1), size(x,2),size(x,3),5-length(find(y==1,5,'first'))))...
            ,temp_data_all.nose_passive, temp_data_all.rxt,'UniformOutput',false);

        nose_data_mean=permute(nanmean(cat(5,nose_data_all{:}),5),[1,3,4,2]);
        nose_data_error=permute(nanstd(cat(5,nose_data_all{:}),0,5)./sqrt(length(nose_data_all)),[1,3,4,2]);

        figure('Position',[50 50 600 200]);
        colors=[[0 0 1];[0 0 0];[1 0 0]];
        tiledlayout(1,5)
        for curr_day=1:5
            nexttile
            hold on
            ap.errorfill(face_time(2:end)',nose_data_mean(:,:,curr_day,3),nose_data_error(:,:,curr_day,3),colors)
            ylim([0.5 4])
            xlabel(['Day ' num2str(curr_day) ])
        end
        sgtitle([groups_name{curr_group} '\_' modes_name{curr_mode}])


    end
end

%% wf vs nose movement

groups_name={'VA','AV'};
modes_name={'Visual','Auditory'};
all_data=struct;
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};
    end
    for curr_mode=1:2
        temp_data_all=table;
        for curr_animal=1:length(animals)
            preload_vars=who;

            animal=animals{curr_animal};
            load(fullfile(Path,[animal '_all_data.mat']));

           switch curr_mode
                case 1
                    select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1')|strcmp([data_all.task_name],'stim_wheel_right_stage2'))&...
                        ~cellfun(@isempty ,data_all.wf_lcr_passive);
                    all_face_passive=[data_all.face_lcr_passive(select_id)];
                    all_wf_passive=[data_all.wf_lcr_passive(select_id)];

                case 2
                    select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|...
                        strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume'))&~cellfun(@isempty ,data_all.wf_hml_passive_audio);
                    all_face_passive=[data_all.face_hml_passive_audio(select_id)];
                    all_wf_passive=[data_all.wf_hml_passive_audio(select_id)];


           end

            % nose__passive
            tem_nose_passive= cellfun(@(id)  cellfun(@(x)   vecnorm(diff(x(:,:,1:9,:),1,2), 2, 4) ,...
                id.face_data,'UniformOutput',false),all_face_passive,'UniformOutput',false);

            temp_nose_mean=...
                feval(@(b)  cat(4,b{:}), cellfun(@(id) feval(@(a)  cat(3,a{:}) ,cellfun(@(x) permute(nanmean(x,1),[2,3,1]), id,'UniformOutput',false)),...
                tem_nose_passive,'UniformOutput',false));


            temp_p_val=arrayfun(@(id)  data_all.behavior_task{id}.rxn_l_p(1)<0.05, find(select_id),'UniformOutput',true);


            % wf_visual_passive
           
            all_passive_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(cat(3,x.kernels_decoding{:}),1)),...
                cat(3,x.kernels_decoding{:})),all_wf_passive,'UniformOutput',false);
            temp_wf_passive_plot_tace= ds.make_each_roi(cat(5,all_passive_image{:}), length(t_kernels),roi1);

            
            % colors={[0 0 1],[0 0 0],[ 1 0 0]};
            % figure('Position',[50 50 1200 800]);
            % tiledlayout(5,length(find(select_id)),'TileIndexing','columnmajor')
            % for curr_day=1:length(find(select_id))
            % 
            %     for curr_passive=1:3
            %         nexttile
            %         imagesc(max( all_passive_image{curr_day}(:,:,period,curr_passive),[],3));
            %         axis image off;
            %         ap.wf_draw('ccf', [0.5 0.5 0.5]);
            %         clim(0.0003 .* [ 0, 1]);
            %         colormap( ap.colormap('WG' ));
            %     end
            %     nexttile
            %     set(gca, 'ColorOrder', [0 0 1; 0 0 0; 1 0 0], 'NextPlot', 'replacechildren');
            %     plot(t_kernels,permute(temp_wf_passive_plot_tace(1,:,:,curr_day),[2,3,1,4]));
            %     nexttile
            %     for curr_passive=1:3
            %         ap.errorfill(face_time(1:end-1)',...
            %             temp_nose_mean(:,3,curr_passive,curr_day),temp_feace_error(:,3,curr_passive,curr_day),colors{curr_passive});
            %     end
            %     ylim([0 4])
            %     sgtitle(animal)
            % end
            % 
            % drawnow


            temp_data_all.rxt{curr_animal}=temp_p_val;
            temp_data_all.wf_passive{curr_animal}=temp_wf_passive_plot_tace;
            temp_data_all.nose_passive{curr_animal}=temp_nose_mean;

            clearvars('-except',preload_vars{:});
        end

        all_data.([groups_name{curr_group} '_' modes_name{curr_mode}])=temp_data_all;
    end
end


passive_mode=[1,3];
for curr_group=1:2
     
    for curr_mode=1:2
        nose_data_all=cellfun(@(x,y)  cat(4, x(:,:,:,find(y==1,5,'first')),nan(size(x,1), size(x,2),size(x,3),5-length(find(y==1,5,'first'))))...
            ,all_data.([groups_name{curr_group} '_' modes_name{curr_mode}]).nose_passive, all_data.([groups_name{curr_group} '_' modes_name{curr_mode}]).rxt,'UniformOutput',false);

        nose_data_mean=permute(nanmean(cat(5,nose_data_all{:}),5),[1,3,4,2]);
        nose_data_error=permute(nanstd(cat(5,nose_data_all{:}),0,5)./sqrt(length(nose_data_all)),[1,3,4,2]);

        figure('Position',[50 50 600 200]);
        colors=[[0 0 1];[0 0 0];[1 0 0]];
        tiledlayout(1,5)
        for curr_day=1:5
            nexttile
            hold on
            ap.errorfill(face_time(2:end)',nose_data_mean(:,:,curr_day,3),nose_data_error(:,:,curr_day,3),colors)
            ylim([0.5 4])
            xlabel(['Day ' num2str(curr_day) ])
        end
        sgtitle([groups_name{curr_group} '\_' modes_name{curr_mode}])
        drawnow

        temp_wf_passive_max=   feval(@(a)  permute(max(a(passive_mode(curr_mode),period,:,:),[],2),[4,3,1,2])   ,cat(4, all_data.([groups_name{curr_group} '_' modes_name{curr_mode}]).wf_passive{:}));
        temp_nose_max=feval(@(a)       permute(max(a(face_time>0&face_time<0.3,3,:,:) ,[],1),[4,3,2,1])      ,cat(4, all_data.([groups_name{curr_group} '_' modes_name{curr_mode}]).nose_passive{:}));
        colors={[0 0 1],[0 0 0],[ 1 0 0]};
        temp_rxt_all=cat(1, all_data.([groups_name{curr_group} '_' modes_name{curr_mode}]).rxt{:});

        figure('Position',[50 50 600 300]);
        tiledlayout(1,3)
        for curr_pass=1:3
            nexttile
            hold on
            plot(temp_nose_max(temp_rxt_all==1,curr_pass),temp_wf_passive_max(temp_rxt_all==1,curr_pass),...
                'LineStyle','none','Marker','.','MarkerSize',10,'Color',colors{curr_pass})
            % plot(temp_nose_max(temp_rxt_all==0,curr_pass),temp_wf_passive_max(temp_rxt_all==0,curr_pass),... ...
            %     'LineStyle','none','Marker','.','MarkerSize',10,'Color',[0.5 0.5 0.5])

            [R(curr_pass,1), p(curr_pass,1)] = corr(temp_nose_max(temp_rxt_all==0,curr_pass), temp_wf_passive_max(temp_rxt_all==0,curr_pass));
            [R(curr_pass,2), p(curr_pass,2)] = corr(temp_nose_max(temp_rxt_all==1,curr_pass), temp_wf_passive_max(temp_rxt_all==1,curr_pass));

            xlim([0 5])
            ylim([0 0.0004])
            xlabel('Max nose movement')
            ylabel('max \Delta F/F')
            axis square
        end
        sgtitle([groups_name{curr_group} '\_' modes_name{curr_mode}])
        drawnow

    end
end

%% iti move across time

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);
temp_data_all=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};
    end

temp_data_all{curr_group}=table;
for curr_animal=1:length(animals)
    preload_vars=who;
    animal=animals{curr_animal};
    load(fullfile(Path,[animal '_all_data.mat']));

    switch curr_group
        case 1
            select_id=strcmp([data_all.task_name],'stim_wheel_right_stage1')|strcmp([data_all.task_name],'stim_wheel_right_stage2');
                % ~cellfun(@isempty ,data_all.wf_lcr_passive);
        case 2
            select_id=strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume');         
    end
    % ~cellfun(@isempty ,data_all.wf_lcr_passive)
    temp_p_val=arrayfun(@(id)  data_all.behavior_task{id}.rxn_l_p(1)<0.05, find(select_id),'UniformOutput',true);

%% behavior
iti_vel=arrayfun(@(id) nanmean(data_all.behavior_task{id}.iti_move_aligned_wheel_vel{1},1) , find(select_id),'UniformOutput',false);
iti_vel12=[nanmean(cat(1,iti_vel{find(temp_p_val==0,1,'first')}),1) ;nanmean(cat(1,iti_vel{find(temp_p_val==1,2,'last')}),1)];

temp_data_all{curr_group}.iti_vel{curr_animal}=iti_vel12;


%% wf_task


all_wf_task=[data_all.wf_task(select_id)];
all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.iti_move_kernels{1}),all_wf_task,'UniformOutput',false);
% all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.stim_kernels{1}),all_wf_task,'UniformOutput',false);
% all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.all_iti_move_kernels{1}),all_wf_task,'UniformOutput',false);

temp_data_all{curr_group}.task_image{curr_animal}= cat(4,nanmean(cat(4,all_task_image{find(temp_p_val==0,1,'first')}),4) ,nanmean(cat(4,all_task_image{find(temp_p_val==1,2,'last')}),4) ) ;

    clearvars('-except',preload_vars{:});
end

end


image_mean=cellfun(@(x) nanmean(cat(5,x.task_image{:}),5),temp_data_all,'uni',false);

vel_mean=cellfun(@(x) nanmean(cat(3,x.iti_vel{:}),3),temp_data_all,'uni',false);
vel_error=cellfun(@(x) std(cat(3,x.iti_vel{:}),0,3,'omitmissing')./sqrt(length(x.iti_vel)),temp_data_all,'uni',false);

scale_image=0.0002;
Color={'B','R'};
figure('Position', [50 50 900 400] )
mainfig=tiledlayout(4,1,'TileSpacing','none')
for curr_group=1:2

    for curr_stage=1:2
            subfig=tiledlayout(mainfig,1,sum(t_kernels>-0.1& t_kernels<0.2),'TileSpacing','none')

    subfig.Layout.Tile=2*curr_group+curr_stage-2;
    for curr_frame=find(t_kernels>-0.1& t_kernels<0.2)
        ax=nexttile(subfig);
        imagesc(image_mean{curr_group}(:,:,curr_frame,curr_stage));
        axis image off;
        clim(scale_image .* [0, 1]);
        colormap(ax, ap.colormap(['W' Color{curr_group}] ));
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        if curr_group==1& curr_stage==1
            title( num2str(t_kernels(curr_frame),'%.2f'),'FontWeight','normal')
        end

    end
        % ax=nexttile(subfig)
        % ap.errorfill(surround_time_points,vel_mean{curr_group}(curr_stage,:),vel_error{curr_group}(curr_stage,:))
        % xlim([-0.1 0.8])
        % ylim([-2500 500])
        %  axis off

    end
end


% vel_mean=cellfun(@(x) nanmean(cat(3,x.iti_vel{:}),3),temp_data_all,'uni',false);
% vel_error=cellfun(@(x) std(cat(3,x.iti_vel{:}),0,3,'omitmissing')./sqrt(length(x.iti_vel)),temp_data_all,'uni',false);
colors={[0 0 1],[1 0 0]};
figure('Position',[50 50 100 400]);
tiledlayout(4,1)
for curr_group=1:2
    for curr_d=1:2
        nexttile
        ap.errorfill(surround_time_points,vel_mean{curr_group}(curr_d,:),vel_error{curr_group}(curr_d,:),colors{curr_group})
        xlim([-0.1 0.6])
        ylim([-2500 500])
        % axis off
        set(gca, 'Color', 'none');   % figure 背景透明

    end
end

%%  correlation between task vs passive kernels
temp_data_all=cell(2,1);

for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};
    end

temp_data_all{curr_group}=table;
for curr_animal=1:length(animals)
    preload_vars=who;
    animal=animals{curr_animal};
    load(fullfile(Path,[animal '_all_data.mat']));

    switch curr_group
        case 1
            select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1')|strcmp([data_all.task_name],'stim_wheel_right_stage2'))&...
                ~cellfun(@isempty ,data_all.wf_lcr_passive);
        case 2
            select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume'))&...         
        ~cellfun(@isempty ,data_all.wf_hml_passive_audio);

    
    end
    temp_p_val=arrayfun(@(id)  data_all.behavior_task{id}.rxn_l_p(1)<0.05, find(select_id),'UniformOutput',true);


%% wf_task

all_wf_task=[data_all.wf_task(select_id)];
% all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.iti_move_kernels{1}),all_wf_task,'UniformOutput',false);
all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.stim_kernels{1}),all_wf_task,'UniformOutput',false);
% all_task_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.stim_kernels{1},1)),x.all_iti_move_kernels{1}),all_wf_task,'UniformOutput',false);

temp_data_all{curr_group}.task_image{curr_animal}=cat(4,all_task_image{find(temp_p_val==1,2,'last')});
%% wf_passive
switch curr_group
    case 1
        all_wf_passive=[data_all.wf_lcr_passive(select_id)];
        used_passive=3;
    case 2
        all_wf_passive=[data_all.wf_hml_passive_audio(select_id)];
         used_passive=2;
end
all_passive_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x.kernels_decoding{used_passive},1)),x.kernels_decoding{used_passive}),all_wf_passive,'UniformOutput',false);

temp_data_all{curr_group}.passive_image{curr_animal}=cat(4,all_passive_image{find(temp_p_val==1,2,'last')})

    clearvars('-except',preload_vars{:});
end

end

pairs={[1 1 ],[2 2],[1 2],[2 1]}
pairs_names={'Visual task vs Visual passive','Auditory task vs Auditory passive',...
    'Visual task vs Auditory passive','Auditory task vs Visual passive'}
figure
for curr_pair=1:length(pairs)


 task_images_max=feval(@(a)  cat(3,a{:}), ...
     cellfun(@(x)  permute(max(x(:,:,period,:),[],3),[1,2,4,3])   ,temp_data_all{pairs{curr_pair}(1)}.task_image,'UniformOutput',false));
 task_length=size(task_images_max,3);

 passive_images_max=feval(@(a)  cat(3,a{:}), ...
     cellfun(@(x)  permute(max(x(:,:,period,:),[],3),[1,2,4,3])   ,temp_data_all{pairs{curr_pair}(2)}.passive_image,'UniformOutput',false));
 passive_length=size(passive_images_max,3);

X=cat(3,task_images_max,passive_images_max);


% ap.imscroll(X)
% axis image off;
% ap.wf_draw('ccf', [0.5 0.5 0.5]);
% clim(0.0003 .* [ 0, 1]);
% colormap( ap.colormap('WB' ));


X = double(X);   % n*m*10

K = size(X, 3);  % 这里应该是 10
C = zeros(K, K);

for i = 1:K
    vi = X(:,:,i);
    vi = vi(:);

    for j = 1:K
        vj = X(:,:,j);
        vj = vj(:);

        % 去掉常数向量导致的 NaN
        if std(vi) == 0 || std(vj) == 0
            C(i,j) = NaN;
        else
            C(i,j) = corr(vi, vj);
        end
    end
end

K = size(C,1);

% 创建mask：保留对角线 + 上三角
mask = triu(true(K));

% 其余设为 NaN（不显示）
C_plot = nan(K);
C_plot(mask) = C(mask);


nexttile
imagesc(C_plot);
colormap( ap.colormap('WB' ));
set(gca, 'XAxisLocation', 'top');
set(gca, 'YAxisLocation', 'right');
axis image;
box off
colorbar;
caxis([0 1]);   % correlation 范围

labels={'task','passive'}
set(gca, 'XTick', [task_length/2 task_length+passive_length/2], 'YTick', [task_length/2 task_length+passive_length/2]);
 set(gca, 'XTickLabel', labels, 'YTickLabel', labels);
% set(gca, 'TickLabelInterpreter', 'none');

line([task_length+0.5 (task_length+passive_length)+0.5 ], [task_length+0.5 task_length+0.5 ],'Color',[1 0 0]);
 line([ task_length+0.5 task_length+0.5],[0.5 task_length+0.5 ],'Color',[1 0 0]);
 title(pairs_names{curr_pair})
end

% correlation trace

for curr_group=1:2

task_images=cat(4,temp_data_all{curr_group}.task_image{:});
passive_images=cat(4,temp_data_all{curr_group}.passive_image{:});

image_corr=cell(size(task_images,4),1);
for curr_image=1:size(task_images,4)

used_task=reshape(task_images(:,:,:,curr_image),[],size(task_images,3))';
used_passive=reshape(passive_images(:,:,:,curr_image),[],size(passive_images,3))';
Cmat=zeros(size(used_task,2),1);
for curr_pixel=1:size(used_task,2)
Cmat(curr_pixel) = corr(used_task(:,curr_pixel),used_passive(:,curr_pixel));   % 注意转置！
end
image_corr{curr_image} = reshape(Cmat, size(task_images,1), size(task_images,2));
end


figure;
nexttile
plot_image=nanmean(cat(3,image_corr{:}),3);
% plot_image(plot_image<0.3)=0;
imagesc(plot_image)
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
 clim([ 0, 1]);
colormap( ap.colormap('WB' ));
nexttile
plot_image(plot_image<0.3)=0;
imagesc(plot_image)
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
 clim([ 0, 1]);
colormap( ap.colormap('WB' ));

end



%% audio balance to visual 

animals = {'DS029','DS030','DS031'};

temp_data_all=table;
for curr_animal=1:length(animals)
    preload_vars=who;

    animal=animals{curr_animal};
    load(fullfile(Path,[animal '_all_data.mat']));

    select_id=find((strcmp([data_all.task_name],'stim_wheel_right_stage1')|strcmp([data_all.task_name],'stim_wheel_right_stage2'))...
       &~cellfun(@isempty ,data_all.wf_lcr_passive),2,'last');
 
% select_id=(strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume_earphone_balance')|...
%         strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume_earphone_balance'))&...
%         ~cellfun(@isempty ,data_all.wf_hml_passive_audio_earphone_balance_only);

   all_visual_task=cellfun(@(x) x.stim_kernels,data_all.wf_task(select_id),'UniformOutput',false);

   all_lcr_passive=cellfun(@(x) cat(3,x.kernels_decoding{:}),data_all.wf_lcr_passive(select_id),'UniformOutput',false);
   % all_task=cellfun(@(x) cat(3,x.kernels_decoding{:}),data_all.wf_lcr_passive(select_id),'UniformOutput',false);


   select_id=find((strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume_earphone_balance')|...
           strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume_earphone_balance'))&...
           ~cellfun(@isempty ,data_all.wf_hml_passive_audio_earphone_balance_only),2,'last');

   all_hml_passive=cellfun(@(x) cat(3,x.kernels_decoding{:}),data_all.wf_hml_passive_audio_earphone_balance_only(select_id),'UniformOutput',false);
   all_audio_task=cellfun(@(x) x.stim_kernels,data_all.wf_task(select_id),'UniformOutput',false);



    temp_data_all.all_hml_passive{curr_animal}=all_hml_passive;
    temp_data_all.all_lcr_passive{curr_animal}=all_lcr_passive;
    temp_data_all.all_visual_task{curr_animal}=all_visual_task;
    temp_data_all.all_audio_task{curr_animal}=all_audio_task;
    clearvars('-except',preload_vars{:});
end


temp_hml_passive= feval(@(a) cat(4,a{:}) ,cellfun(@(x) nanmean(cat(4,x{:}),4),temp_data_all.all_hml_passive,'UniformOutput',false  ));
all_passive_image= plab.wf.svd2px(U_master(:,:,1:size(cat(3,temp_hml_passive),1)),temp_hml_passive);
all_audio_passive_image_max=permute(max(nanmean(all_passive_image(:,:,period,:,:),5),[],3),[1,2,4,3]);
 temp_wf_passive_plot_tace= ds.make_each_roi(all_passive_image, length(t_kernels),roi1);

temp_lcr_passive= feval(@(a) cat(4,a{:}) ,cellfun(@(x) nanmean(cat(4,x{:}),4),temp_data_all.all_lcr_passive,'UniformOutput',false  ));
all_visual_passive_image= plab.wf.svd2px(U_master(:,:,1:size(cat(3,temp_lcr_passive),1)),temp_lcr_passive);
all_visual_passive_image_max=permute(max(nanmean(all_visual_passive_image(:,:,period,:),5),[],3),[1,2,4,3]);
 temp_visual_passive_plot_tace= ds.make_each_roi(all_visual_passive_image, length(t_kernels),roi1);

temp_visual=feval(@(b)   cat(3,b{:})  ,feval(@(a)  cat(1,a{:}) , cat(1,temp_data_all.all_visual_task{:})));
all_visual_task_image= plab.wf.svd2px(U_master(:,:,1:size(temp_visual,1)),temp_visual);
all_visual_task_image_max=max(nanmean(all_visual_task_image(:,:,period,:),4),[],3);

temp_audio=feval(@(b)   cat(3,b{:})  ,feval(@(a)  cat(1,a{:}) , cat(1,temp_data_all.all_audio_task{:})));
all_audio_task_image= plab.wf.svd2px(U_master(:,:,1:size(temp_audio,1)),temp_audio);
all_audio_task_image_max=max(nanmean(all_audio_task_image(:,:,period,:),4),[],3);


figure('Position',[50 50 800 300]);
tiledlayout(2,5)
colors=[[0 0 1];[0 0 0];[ 1 0 0]];
for curr_stage=1:2
    switch curr_stage
        case 1
            tem_image=all_audio_passive_image_max;
            tem_trace_mean=permute(nanmean(temp_wf_passive_plot_tace(3,:,:,:),4),[2,3,1]);
            tem_trace_error=permute(nanstd(temp_wf_passive_plot_tace(3,:,:,:),0,4)./sqrt(size(temp_wf_passive_plot_tace,4)),[2,3,1]);
            temp_task=all_audio_task_image_max;

        case 2
            tem_image=all_visual_passive_image_max;
            tem_trace_mean=permute(nanmean(temp_visual_passive_plot_tace(1,:,:,:),4),[2,3,1]);
            tem_trace_error=permute(nanstd(temp_visual_passive_plot_tace(1,:,:,:),0,4)./sqrt(size(temp_visual_passive_plot_tace,4)),[2,3,1]);

            temp_task=all_visual_task_image_max;


    end
    nexttile
    imagesc(temp_task);
     axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(0.0003 .* [ 0, 1]);
    colormap( ap.colormap('WP' ));
 
 for curr_passive=1:3
     nexttile
     imagesc(tem_image(:,:,curr_passive));
     axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(0.0003 .* [ 0, 1]);
    colormap( ap.colormap('WP' ));
 end
 nexttile
 ap.errorfill(t_kernels,tem_trace_mean,tem_trace_error,colors)
xlim([-0.2 0.5])
xlabel('time (s)')
 ylabel('\Delta F/F')

end

aaa=tem_image(:,:,curr_passive)
figure;
 imagesc(aaa);
     axis image off;
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(0.0003 .* [ -1, 1]);

        colormap([1 1 1; ap.colormap('GkP' )]);
%%
animals={'DS029','DS030','DS031','AP032'}
for curr_animal=1:length(animals)
animal=animals{curr_animal}
    load(fullfile(Path,[animal '_all_data.mat']));




