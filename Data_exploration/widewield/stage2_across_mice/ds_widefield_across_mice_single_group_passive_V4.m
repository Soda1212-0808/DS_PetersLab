clear all
clc
Path = 'D:\Data process\wf_data\';
master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive   (1):1/surround_samplerate:surround_window_passive(2);
t_kernels=1/surround_samplerate*[-10:30];

passive_boundary=0.2;
period_passive=find(t_passive>0&t_passive<passive_boundary); 
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

all_workflow={'lcr_passive','hml_passive_audio','lcr_passive_size60'};
Color={'B','R'};

n1_name='';n2_name='';
use_period=[];
workflow='';
use_t=[];
animals={};
groups={'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};
select_group=1:2

data_all_days=cell(2,1);
% used_data=1;% 1 raw data;2 kernels 
data_type={'raw','kernels'};
for used_data=2
    for  workflow_idx=1:2
        workflow=all_workflow{workflow_idx};
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
            all_data_video=cell(length(animals{curr_group}),1);
            all_data_workflow_name=cell(length(animals{curr_group}),1);
            all_data_learned_day=cell(length(animals{curr_group}),1);
            matches=cell(length(animals{curr_group}),1);
            use_t=[];
            use_period=[];
            for curr_animal=1:length(animals{curr_group})
                preload_vars = who;
                animal=animals{curr_group}{curr_animal};
                raw_data_passive=load([Path  workflow '\' animal '_' workflow '.mat']);
                raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);


                if used_data==1

                    idx_all=cellfun(@(x) ~(isempty(x)|~(size(x,3)==3))  ,raw_data_passive.wf_px);
                    image_all(idx_all,1)=cellfun(@(x)  plab.wf.svd2px(U_master,x),raw_data_passive.wf_px(idx_all),'UniformOutput',false);

                    use_period=period_passive;
                    use_t=t_passive;
                elseif  used_data==2
                    idx_all=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px_kernels);

                    image_all(idx_all,1)=cellfun(@(x)  plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),raw_data_passive.wf_px_kernels(idx_all),'UniformOutput',false);
                    use_period=period_kernels;
                    use_t=t_kernels;

                elseif  used_data==3
                    idx_all=cellfun(@(x) ~isempty(x),raw_data_passive.wf_px_kernels_encode);
                    image_all(idx_all,1)=cellfun(@(x)  plab.wf.svd2px(U_master,permute(x{1},[3,2,1])),raw_data_passive.wf_px_kernels_encode(idx_all),'UniformOutput',false);
                    use_period=period_kernels;
                    use_t=t_kernels;

                end
                matches{curr_animal}=unique(raw_data_passive.workflow_type_name_merge(idx_all)  ,'stable');
                all_data_video{curr_animal}=image_all(idx_all);
                all_data_workflow_name{curr_animal}=raw_data_passive.workflow_type_name_merge(idx_all);


                [~, temp_idx] = ismember( raw_data_passive.workflow_day,raw_data_behavior.workflow_day);

                temp_p=nan(length(raw_data_behavior.workflow_day),2);
                idx_v=ismember(raw_data_behavior.workflow_name,'visual position');
                idx_a=ismember(raw_data_behavior.workflow_name,'audio volume');
                idx_m=ismember(raw_data_behavior.workflow_name,'mixed VA');

                temp_p(idx_v,1)= raw_data_behavior.rxn_l_mad_p(idx_v,1);
                temp_p(idx_a,1)=raw_data_behavior.rxn_l_mad_p(idx_a,1);
                temp_p(idx_m,:)= [raw_data_behavior.rxn_l_mad_p(idx_m,1)...
                    raw_data_behavior.rxn_l_mad_p(idx_m,2)];
                temp_p=temp_p(temp_idx(temp_idx>0),:);


                if workflow_idx==1
                    temp_p1= [nan(sum(temp_idx==0 ),1) ;  temp_p(isnan(temp_p(:,2)),1) ;   temp_p(~isnan(temp_p(:,2)),1)];
                else
                    temp_p1= [nan(sum(temp_idx==0 ),1) ;  temp_p(isnan(temp_p(:,2)),1) ;   temp_p(~isnan(temp_p(:,2)),2)];
                end

                all_data_learned_day{curr_animal}=temp_p1(idx_all)<0.01;

                clearvars('-except',preload_vars{:});

            end

            naive_idx=cellfun(@(x) any(strcmp('naive',x)),matches,'UniformOutput',true );
            naive_data=cell(length(animals{curr_group}),1);
            naive_data(naive_idx) =  cellfun(@(x, y, z)...
                x(find(strcmp(y, z(find(cellfun(@(idx) strcmp('naive', idx), z, 'UniformOutput', true)))), 3, 'first'), :), ...
                all_data_video(naive_idx), all_data_workflow_name(naive_idx), matches(naive_idx), ...
                'UniformOutput', false);
            naive_data(~naive_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),3)},3,1),...
                (1:length(find(~naive_idx)))', 'UniformOutput', false);
            naive_data= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],naive_data,'UniformOutput',false);


            pre_learn_data0=cell(length(animals{curr_group}),1);
            pre_learn_data0 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l==0 ))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            pre_learn_data0 = cellfun(@(x) x(1:end-2),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0 = cellfun(@(x) mean(cat(5,x{:}),5),pre_learn_data0,'UniformOutput',false);
            pre_learn_data0= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},1-length(x),1)],pre_learn_data0,'UniformOutput',false);


            pre_learn_data1=cell(length(animals{curr_group}),1);
            pre_learn_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l==0 ,2,'last'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            pre_learn_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],pre_learn_data1,'UniformOutput',false);


            post_learn1_data1=cell(length(animals{curr_group}),1);
            post_learn1_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l==1 ,2,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn1_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],post_learn1_data1,'UniformOutput',false);


            post_learn2_data1=cell(length(animals{curr_group}),1);
            post_learn2_data1 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n1_name, idx),z,'UniformOutput',true))))& l==1 ,5,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn2_data1 = cellfun(@(x) x(3:end),post_learn2_data1,'UniformOutput',false);
            post_learn2_data1= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],post_learn2_data1,'UniformOutput',false);


            first_5day_data2=cell(length(animals{curr_group}),1);
            first_5day_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true)))) ,5,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            first_5day_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},5-length(x),1)],first_5day_data2,'UniformOutput',false);

            pre_learn_data2=cell(length(animals{curr_group}),1);
            pre_learn_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l==0 ,2,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            pre_learn_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],pre_learn_data2,'UniformOutput',false);

            post_learn1_data2=cell(length(animals{curr_group}),1);
            post_learn1_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l==1 ,2,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn1_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},2-length(x),1)],post_learn1_data2,'UniformOutput',false);

            post_learn2_data2=cell(length(animals{curr_group}),1);
            post_learn2_data2 = cellfun(@(x,y,z,l) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n2_name, idx),z,'UniformOutput',true))))& l==1 ,5,'first'))...
                ,all_data_video,all_data_workflow_name,matches,all_data_learned_day,'UniformOutput',false);
            post_learn2_data2 = cellfun(@(x) x(3:end),post_learn2_data2,'UniformOutput',false);
            post_learn2_data2= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],post_learn2_data2,'UniformOutput',false);

            n3_name='mixed VA';
            mixed_idx=cellfun(@(x) any(strcmp(n3_name, x)),matches ,'UniformOutput',true);
            data3=cell(length(animals{curr_group}),1);
            data3(mixed_idx) = cellfun(@(x,y,z) x(find(strcmp(y,z(find(cellfun(@(idx) strcmp(n3_name, idx),z,'UniformOutput',true)))),3,'last'),:),...
                all_data_video(mixed_idx) ,all_data_workflow_name(mixed_idx) ,matches(mixed_idx) ,'UniformOutput',false);

            data3(~mixed_idx) = arrayfun(@(x) repmat({nan(450,426,length(use_t),3)},3,1),...
                (1:length(find(~mixed_idx)))', 'UniformOutput', false);
            data3= cellfun(@(x) [x; repmat({nan(450,426,length(use_t),3)},3-length(x),1)],data3,'UniformOutput',false);

            all_data_daybyday=cellfun(@(a0,a,b,c,d,e,f,g,h,i) [a0;a;b;c;d;e;f;g;h;i], naive_data,pre_learn_data0,pre_learn_data1,post_learn1_data1,post_learn2_data1,...
                pre_learn_data2,post_learn1_data2,post_learn2_data2,data3,first_5day_data2,'UniformOutput',false);



            data_all_days{curr_group}{used_data}{workflow_idx}=all_data_daybyday;



            % data_first5day_stage2{curr_group}{used_data}{workflow_idx}=first_5day_data2;

            clearvars('-except',main_preload_vars{:});

        end
    end

end


% save([Path 'mat_data\summary_data\passive ' data_type{used_data} ' in group ' groups{select_group}  '.mat' ],'data_all_images','data_all','-v7.3');
%%

temp_data=permute(max(data_all_video{2}{2}{2}(:,:,period_kernels,:,:,5),[],3 ),[1,2,4,5,3] );

figure;
for ii=1:5
    for jj=1:3
        nexttile
        imagesc(temp_data(:,:,jj,ii))

        axis image off
        ap.wf_draw('ccf',[0.5 0.5 0.5]);
        clim(0.0002.*[0,1]);
        colormap(ap.colormap('WR'));
    end
end
figure
for ii=1:3
    nexttile
    imagesc(nanmean(temp_data(:,:,ii,:),4))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.0002.*[0,1]);
    colormap(ap.colormap('WR'));
end

%%
temp_data=nanmean(max(data_all_video{2}{ 2}{2} (:,:,period_kernels,2,:,5),[],3) ,5)

tempp=cat(2,data_all_days{2}{2}{2}{:});
tempp2=cat(5,tempp{10:11,:});
temp_data2=nanmean(max(tempp2(:,:,period_kernels,2,:),[],3),5)

figure;
nexttile
imagesc(temp_data);
clim([0 0.0002])
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
colormap( ap.colormap(['WG']));
nexttile
imagesc(temp_data2); axis off;
clim([0 0.0002])
axis image off;
ap.wf_draw('ccf', [0.5 0.5 0.5]);
colormap( ap.colormap(['WG']));

%%  visual passive averaged raw vs kernels

raw_v=permute(mean(max(data_all_video{1}{1}{1}(:,:,period_passive,:,:,5),[],3),5),[1,2,4,3]);
kernels_v=permute(mean(max(data_all_video{1}{2}{1}(:,:,period_kernels,:,:,5),[],3),5),[1,2,4,3]);
kernels_encode_v=permute(mean(max(data_all_video{1}{3}{1}(:,:,period_kernels,:,:,5),[],3),5),[1,2,4,3]);

figure('Position',[50,50,430,600])
t2 = tiledlayout(3, 3, 'TileSpacing', 'tight', 'Padding', 'tight');
titles={'Left','Center','Right'}

for curr_day=1:3
    nexttile

    imagesc(raw_v(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.003.*[0,1]);
    colormap(ap.colormap('WB'));
    axis image;
    title(titles{curr_day},'FontWeight','normal')
    switch curr_day
        case 3
            colorbar('southoutside')
        case 1
            text(-50, 150,  'raw', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
    end
end


for curr_day=1:3
    nexttile

    imagesc(kernels_encode_v(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.003.*[0,1]);
    colormap(ap.colormap('WB'));
    axis image;

    switch curr_day
        case 1
            text(-50, 150,  'encoding', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        case 3
            colorbar('southoutside')
    end
end

for curr_day=1:3
    nexttile

    imagesc(kernels_v(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.0002.*[0,1]);
    colormap(ap.colormap('WB'));
    axis image;

    switch curr_day
        case 1
            text(-50, 150,  'decoding', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        case 3
            colorbar('southoutside')
    end
end

 saveas(gcf,[Path 'figures\summary\figures\visual passive vs kernels' ], 'jpg');
%%  auditory passive averaged raw vs kernels

raw_a=permute(mean(max(data_all_video{2}{1}{2}(:,:,period_passive,:,:,5),[],3),5),[1,2,4,3]);
kernels_a=permute(mean(max(data_all_video{2}{2}{2}(:,:,period_kernels,:,:,5),[],3),5),[1,2,4,3]);
kernels_encode_a=permute(mean(max(data_all_video{2}{3}{2}(:,:,period_kernels,:,:,5),[],3),5),[1,2,4,3]);

figure('Position',[50,50,430,600])
t2 = tiledlayout(3, 3, 'TileSpacing', 'tight', 'Padding', 'tight');
titles={'4K','8K','12K'}
for curr_day=1:3
    nexttile

    imagesc(raw_a(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.003.*[0,1]);
    colormap(ap.colormap('WR'));
    axis image;
    title(titles{curr_day},'FontWeight','normal')
    switch curr_day
        case 3
            colorbar('southoutside')
        case 1
            text(-50, 150,  'raw', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
    end
end


for curr_day=1:3
    nexttile

    imagesc(kernels_encode_a(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.003.*[0,1]);
    colormap(ap.colormap('WR'));
    axis image;

    switch curr_day
        case 1
            text(-50, 150,  'decoding', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        case 3
            colorbar('southoutside')
    end
end

for curr_day=1:3
    nexttile

    imagesc(kernels_a(:,:,curr_day))

    axis image off
    ap.wf_draw('ccf',[0.5 0.5 0.5]);
    clim(0.0002.*[0,1]);
    colormap(ap.colormap('WR'));
    axis image;

    switch curr_day
        case 1
            text(-50, 150,  'kernels', 'FontSize', 10, 'FontWeight', 'normal', ...
                'HorizontalAlignment', 'right', 'Rotation', 90);
        case 3
            colorbar('southoutside')
    end
end


saveas(gcf,[Path 'figures\summary\figures\auditory passive vs kernels' ], 'jpg');

%%  cortical images of well trianed mice with selectivity and lateralization in the first task.
scale=0.0003;
xlabel_all={'left','center','right';'4k Hz','8k Hz','12k Hz'}
line_colors={[0.5 0.5 0.5],[0.5 0.5 0.5],[0 0 1];[0.5 0.5 0.5],[1 0 0],[0.5 0.5 0.5]}
buf3_roi_peak_mean=cell(2,1);
buf3_roi_peak_error=cell(2,1);
buf3_roi_stim1_mean=cell(2,1);
buf3_roi_stim1_error=cell(2,1);
figure('Position',[50 50 350 400])
mainLayout = tiledlayout(3, 1, 'TileSpacing', 'none', 'Padding', 'none');
oder={[3 1 2],[2 1 3]};
for curr_group=1:2
    for   workflow_idx =curr_group;

        main_preload_vars = who;
        imageLayout = tiledlayout(mainLayout, 1, 3, ...
            'TileSpacing', 'tight', 'Padding', 'tight');
        imageLayout.Layout.Tile = curr_group;  % 明确放在主 layout 的第 1 个 tile
        used_area=workflow_idx*2-1;
        used_stim=4-workflow_idx;
        scale=0.0003;
        Color={'B','R'};
        % darw iamge
        temp_image=cat(2,data_all_days{curr_group}{2}{workflow_idx}{:});
        temp_image2= cat(5, temp_image{10:11,:});
        buf_images_all1= permute(nanmean(max(temp_image2(:,:,use_period,:,:),[],3),5),[1,2,4,3,5]);

        for curr_day=oder{curr_group}
            a1=nexttile(imageLayout)
            imagesc(buf_images_all1(:,:,curr_day))
            axis image off;
            ap.wf_draw('ccf', [0.5 0.5 0.5]);
            clim(scale .* [ 0, 1]);
            colormap(a1, ap.colormap(['W' Color{workflow_idx}]));
            title(xlabel_all{workflow_idx,curr_day},'FontWeight','normal','FontSize',10)

        end

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4)),...
            temp_image(10:11,:), 'UniformOutput', false);

        for curr_roi= 1:length(roi1)
            buf3_roi{curr_roi}=cellfun(@(x) permute(nanmean(x(roi1(curr_roi).data.mask(:),:,:),1),[2,3,1]),buf1,'UniformOutput',false);
            % buf3_roi_peak{curr_animal}{curr_roi}=max(buf3_roi{curr_roi}(use_period,:),[],1) ;
            % buf3_roi_stim{curr_animal}{curr_roi}= double(buf3_roi{curr_roi}(:,curr_day))';
        end

        buf3_roi_peak1= cellfun(@(x) cellfun(@(y) max(y(use_period,:),[],1),x,'UniformOutput',false) ,buf3_roi,'UniformOutput',false);
        buf3_roi_peak_mean{curr_group}= cellfun(@(x)  nanmean(cat(3,x{:}),3), buf3_roi_peak1,'UniformOutput',false);
        buf3_roi_peak_error{curr_group}=cellfun(@(x)   std(cat(3,x{:}),0,3,'omitmissing')./sqrt(size(x,2))  , buf3_roi_peak1,'UniformOutput',false);
        buf3_roi_stim1_mean{curr_group}= cellfun(@(x) nanmean(cat(3,x{:}),3),buf3_roi,'UniformOutput',false   )
        buf3_roi_stim1_error{curr_group}= cellfun(@(x) std(cat(3,x{:}),0,3,'omitmissing')./sqrt(size(x,2)),buf3_roi,'UniformOutput',false   )
        clearvars('-except',main_preload_vars{:});


    end

end





% figure('Position',[50 50 350 200])
plot_layout=tiledlayout(mainLayout,3,4, 'TileIndexing','columnmajor','TileSpacing','tight','Padding','tight')
plot_layout.Layout.Tile = 3;  % 明确放在主 layout 的第 1 个 tile
% plot_layout.Layout.TileSpan=[2 1]
use_area=[1 3];
colors={[0 0 1],[1 0 0]}
for area_idx = 1:2  % 对应 curr_area = [1 3]
    curr_area = use_area(area_idx);  % 显式编号
    col_idx = area_idx;  % 当前是在第几列放置（因为 columnmajor）
       tt=nexttile(plot_layout)
       imagesc(roi1(curr_area).data.mask )
       ap.wf_draw('ccf', [0.5 0.5 0.5]);
               axis image off

       ylim([0 200])
       xlim([20 220])
       clim( [ 0, 1]);
       colormap( tt,ap.colormap('WK'));
       title(roi1(curr_area).name,'FontWeight','normal')

    for curr_group=1:2
        
        used_stim=4-curr_group;
        nexttile(plot_layout)
        hold on
        for curr_day=1:3
            ap.errorfill(use_t,buf3_roi_stim1_mean{curr_group}{curr_area}(:,curr_day),...
                buf3_roi_stim1_error{curr_group}{curr_area}(:,curr_day),line_colors{curr_group,curr_day},0.1,1,1)
            xlim([-0.1 0.5])
            ylim(0.0001*[-0.5 2])
        end
        % if curr_group==1
        % text(0.95, 0.9, roi1(curr_area).name, ...
        %     'Units','normalized', ...       % 使用归一化坐标，确保每个 tile 相对位置一致
        %     'HorizontalAlignment','right', ...
        %     'FontSize', 8, ...
        %     'Color', [0.3 0.3 0.3]);
        %     set(gca,'Color','none')
        % end
        axis off
    end

    nexttile(plot_layout,area_idx*6-2,[3 1]);  % 在第2块区域的后面画一整栏（例如列3、列4）
    hold on
    for curr_group=1:2
        switch curr_group
            case 1
                errorbar( 1:3 ,buf3_roi_peak_mean{curr_group}{curr_area},buf3_roi_peak_error{curr_group}{curr_area}...
                    ,'-o','MarkerSize',5, 'LineWidth', 2,'Color',colors{curr_group},'MarkerFaceColor',colors{curr_group},'CapSize',0)
            case 2
                errorbar( 1:3 ,buf3_roi_peak_mean{curr_group}{curr_area}([1 3 2]),...
                    buf3_roi_peak_error{curr_group}{curr_area}([1 3 2]),'-o','MarkerSize',5,...
                    'LineWidth', 2,'Color',colors{curr_group},'MarkerFaceColor',colors{curr_group},'CapSize',0)
        end
    end
    xticks([1:3]); % 设置 y 轴的刻度位置（2代表naive stage中间位置，8代表stage1中间位置）
    xticklabels({'L/4K','C/12K','R/8K'}); % 设置对应的标签
    xlim([0.5 3.5])
    scale=0.00025;

    ylim(scale .* [-0, 1 ]);
    % title(roi1(curr_area).name,'FontWeight','normal','FontSize',10)
    ylabel('ΔF/F')
    % xlabel('stim types')
    box off
    set(gca,'Color','none')


end



%%



saveas(gcf,[Path 'figures\summary\figures\fig1 passive images V&A pre&well trianed compare' ], 'jpg');


%

kernels_v_each_day=permute(max(data_all_video{1}{2}{1}(:,:,period_kernels,3,:,5),[],3),[1,2,5,6,4,3]);
kernels_a_each_day=permute(max(data_all_video{2}{2}{2}(:,:,period_kernels,2,:,5),[],3),[1,2,5,6,4,3]);

kernels_a_each_day_2=permute(max(data_all_video{1}{2}{2}(:,:,period_kernels,2,:,8),[],3),[1,2,5,6,4,3]);
kernels_v_each_day_2=permute(max(data_all_video{2}{2}{1}(:,:,period_kernels,3,:,8),[],3),[1,2,5,6,4,3]);


kernels_v_each_day_baseline=permute(max(data_all_video{1}{2}{1}(:,:,find(use_t<-0.1&use_t>-0.3),3,:,5),[],3),[1,2,5,6,4,3]);
kernels_a_each_day_baseline=permute(max(data_all_video{2}{2}{2}(:,:,find(use_t<-0.1&use_t>-0.3),2,:,5),[],3),[1,2,5,6,4,3]);


threshold=0.00006;
temp_A=kernels_v_each_day_baseline;
temp_B=kernels_v_each_day;
temp_A(temp_A<threshold)=0;
temp_B(temp_B<threshold)=0;
p_map_v=ds.image_diff(temp_A,temp_B,1,1);


temp_A=kernels_a_each_day_baseline;
temp_B=kernels_a_each_day;
temp_A(temp_A<threshold)=0;
temp_B(temp_B<threshold)=0;
p_map_a=ds.image_diff(temp_A,temp_B,1,1);
%
temp_A1=kernels_v_each_day;
temp_B1=kernels_a_each_day;
% temp_A= kernels_v_each_day;
% temp_B=kernels_a_each_day;
temp_A1(temp_A1<threshold)=0;
temp_B1(temp_B1<threshold)=0;
p_map_av1=ds.image_diff(temp_A1,temp_B1,0,1);

temp_A2=kernels_v_each_day_2;
temp_B2=kernels_a_each_day_2;
% temp_A= kernels_v_each_day;
% temp_B=kernels_a_each_day;
temp_A2(temp_A2<threshold)=0;
temp_B2(temp_B2<threshold)=0;
p_map_av2=ds.image_diff(temp_A2,temp_B2,0,1);

temp_A=cat(3, kernels_v_each_day,kernels_v_each_day_2);
temp_B=cat(3, kernels_a_each_day,kernels_a_each_day_2);
% temp_A= kernels_v_each_day;
% temp_B=kernels_a_each_day;
temp_A(temp_A<threshold)=0;
temp_B(temp_B<threshold)=0;
p_map_av=ds.image_diff(temp_A,temp_B,1,1);

%

figure('Position',[50 50 300 600])
t = tiledlayout(3, 2, 'TileSpacing', 'tight', 'Padding', 'compact');

a3=nexttile
imagesc(p_map_av );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([0 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title('stage 1&2')

empty_area=zeros(450,426);
empty_area(p_map_av>0.95)=1;
empty_area(p_map_av<0.05)=-1;

a3=nexttile
imagesc(empty_area );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([-1 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title('stage 1&2')


a3=nexttile
imagesc(p_map_av1 );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([0 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title('stage 1')


empty_area=zeros(450,426);
empty_area(p_map_av1>0.95)=1;
empty_area(p_map_av1<0.05)=-1;

a3=nexttile
imagesc(empty_area );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([-1 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);


a3=nexttile
imagesc(p_map_av2 );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([0 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);
title('stage 2')

empty_area=zeros(450,426);
empty_area(p_map_av2>0.95)=1;
empty_area(p_map_av2<0.05)=-1;

a3=nexttile
imagesc(empty_area );  axis image off
colormap(a3,ap.colormap('BWR') );
clim([-1 1])
ap.wf_draw('ccf', [0.5 0.5 0.5]);

saveas(gcf,[Path 'figures\summary\figures\passive kernels permutation test' ], 'jpg');

%% images across day aligned to stim
buf3_roi=cell(2,1);
buf3_roi_peak=cell(2,1);
for curr_group=1:2
    for curr_passive=1:2
        temp_data=cat(2,data_all_days{curr_group}{2}{curr_passive}{:});
        temp_data2=arrayfun(@(x) cat(5,temp_data{x,:}), 1:size(temp_data,1),'UniformOutput',false );

        buf1=cellfun(@(z) reshape(z,size(z,1)*size(z,2),size(z,3),size(z,4),size(z,5)) ,...
            temp_data2, 'UniformOutput', false);
        for curr_roi= 1:5
            buf3_roi{curr_group}{curr_passive}{curr_roi}=...
                cellfun(@(z) permute(nanmean(z(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),...
                buf1, 'UniformOutput', false);

            % buf3_roi1{curr_group}{curr_passive}{curr_roi}= ...
            %     cellfun(@(z) permute(mean(z(roi1(curr_roi).data.mask(:),:,4-curr_passive,:),1,'omitnan'),[2,4,3,1]),...
            %     buf1, 'UniformOutput', false);
tem_data3=cellfun(@(x) permute(max(x(use_period,:,:),[],1),[2,3,1]),...
    buf3_roi{curr_group}{curr_passive}{curr_roi},'UniformOutput',false);

buf3_roi_peak{curr_group}{curr_passive}{curr_roi}=cat(3,tem_data3{:});

        end
    end
end
save([Path 'summary_data\passive kernels of images crossday.mat'],'buf3_roi','buf3_roi_peak',...
    '-v7.3')

temp_data=cellfun(@(a) cellfun(@(b)  cellfun (@(c)    permute(mean(cat(4,c{:}),3,'omitnan'),[1 4 2 3]),...
    b,'UniformOutput',false),a,'UniformOutput',false),buf3_roi,'UniformOutput',false);

temp_data1=cellfun(@(a) cellfun(@(b)  cellfun(@(c)   cat(4,c{:})  ,b,'UniformOutput',false), ...
    a,'UniformOutput',false),buf3_roi,'UniformOutput',false);

temp_data_peak_mean=cellfun(@(a) cellfun(@(b)  cellfun(@(c)...
    permute( mean( max(c(use_period,:,:,:),[],1),3,'omitnan'),[4,2,3,1])  ,b,'UniformOutput',false),...
    a,'UniformOutput',false),temp_data1,'UniformOutput',false);

temp_data_peak_error=cellfun(@(a) cellfun(@(b)  cellfun(@(c)...
    permute( std( max(c(use_period,:,:,:),[],1),0,3,'omitmissing')./sqrt(size(c,2)),[4,2,3,1]),...
    b,'UniformOutput',false),a,'UniformOutput',false),temp_data1,'UniformOutput',false);

Color={'B','R'};
title_name={'l-mPFC','r-mPFC','l-aPFC','r-aPFC','l-PPC','r-PPC'}
passive={'V','A'}
figure('Position',[50 50 800 200])
colors = { [0 0 1],[1 0 0]}; % 定义颜色

tiledlayout(1,6, 'TileSpacing', 'tight', 'Padding', 'tight');
for curr_roi=[1 3]
    for curr_group=1:2
        curr_passive=curr_group

        a1=nexttile
        imagesc(use_t,[],temp_data{curr_group}{curr_passive}{curr_roi}(:,:,4-curr_passive)')
        clim(0.0004*[0 1 ])
        c=colorbar('southoutside')
        c.Ticks = [c.Limits(1), c.Limits(2)];

        colormap(a1,ap.colormap(['W' Color{curr_group}]))
        title([passive{curr_passive} ':' title_name{curr_roi}],'FontWeight','normal')
        ylim([4.5 11.5])

        yline(3.5);
        yline(6.5);
        yline(11.5);
        yline(13.5);
        yline(18.5);
        xlim([-0.2,0.5])
        xticks([[-0.2,0,0.5]])

        xlabel('time (s)')
        if curr_group==1& curr_roi==1
            yticks([5.5  9])
            yticklabels({'pre learn','post learn'})
        else
            yticks([5.5  9])
            yticklabels({})
        end

    end
    a1=nexttile
    hold on
    for curr_group=1:2
        curr_passive=curr_group
        hold on

        ap.errorfill(1:26, temp_data_peak_mean{curr_group}{curr_passive}{curr_roi}(:,4-curr_passive),...
            temp_data_peak_error{curr_group}{curr_passive}{curr_roi}(:,4-curr_passive),colors{curr_group},0.1,0.5)



        colormap(a1,ap.colormap(['W' Color{curr_group}]))
        % title([passive{curr_passive} ':' title_name{curr_roi}],'FontWeight','normal')
        xlim([4.5 11])
        xline(3.5);
        xline(6.5);
        xline(11.5);
        xline(13.5);
        xline(18.5);
        xticks([5.5  9])
        ylim(0.0004*[0 1 ])
        xticklabels({'pre learn','post learn'})
        ylabel('\DeltaF/F')
    end


end

% saveas(gcf,[Path 'figures\summary\figures\fig2 passive kernels across day' ], 'jpg');

%%


tempp= cellfun(@(x) cat(5,x{:}) ,data_all_days{1, 1}{1, 2}{1, 1},'UniformOutput',false )
tempp1= cat(6,tempp{:});
tempp2= permute(mean( max(tempp1(:,:,use_period,3,:,:),[],3),6,'omitnan'),[1 2 5 3 4])
ap.imscroll(tempp2)
% ap.imscroll(permute(nanmean(max(data_all_video{1}{2}{1}(:,:,use_period,3,:,:),[],3),5),[1 2 6 5 4 3]))
clim(0.0002*[0 1 ])
axis image off
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap(ap.colormap(['WR']))



%% images across time aligned to stim
Color={'B','R'};
group_name={'visual','auditory'}

scale=0.0002;
time_period=[-0.05 0.3];
row_labels={'Left','Middle','Right';'4K','8K','12K'}
for curr_group=2
    figure('Position', [50 50 110*length(find(use_t>=time_period(1)& use_t<=time_period(2))) 140*3]);
    t1 = tiledlayout(3, length(find(use_t>=time_period(1)& use_t<=time_period(2))),...
        'TileSpacing', 'none', 'Padding', 'none');
curr_passie=curr_group
    for curr_stage=[9]
        curr_video= nanmean(data_all_video{curr_group}{2}{curr_passie}(:,:,:,:,:,curr_stage),5);

        for curr_day=1:size(curr_video,4)
            for curr_time =find(use_t>=time_period(1)& use_t<time_period(2))

                a_1=nexttile
                buff_image=curr_video(:,:,curr_time,curr_day);

                imagesc(buff_image)
                axis image off;
                ap.wf_draw('ccf',[0.5 0.5 0.5]);
                clim(scale .* [0,1]);
                colormap( a_1, ap.colormap(['W' Color{curr_group}]  ));
                if curr_day==1 &curr_stage==50
                    title(num2str(t_kernels(curr_time)))
                end
                if curr_time==find(use_t>=time_period(1)& use_t<time_period(2),1,'first')
                    text(-30, 100, row_labels(curr_group,curr_day), 'FontSize', 12, 'FontWeight', 'normal', ...
                        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Rotation', 90);
                end
                if curr_time==find(use_t>=time_period(1)& use_t<time_period(2),1,'last')&...
                        curr_day==size(curr_video,4) &...
                        curr_stage==5
                    cb = colorbar( 'southoutside');

                end
            end
        end
    end
    % saveas(gcf,[Path 'figures\summary\figures\' group_name{curr_group}  ' passive kernels images across time ' ], 'jpg');


end
%% across time
group=2
group_name={'VA','AV'}; % VA-1,AV-2
stim_type=1
stim_name={'V passive','A passive'}
stim_cue={3,2};

type =2
data_type={'raw','kernels'}; % raw-1 kernels-2
t_t={t_passive,t_kernels};
use_t=t_t{type};

stage=1:8
stage_name={'naive','mod1-pre','mod1-post1','mod1-well trained','mod2-pre','mod2-post1','mod2-well trained','mixed'};
% stage1-pre:1; stage1-post1:2; stage1-post2:3 ;
% stage2-pre:4 ;stage2-post:5 ;stage2-post:6;
% mixed visual:7 ; mixed auditory :8

curr_video0=permute(mean(data_all_video{1}{type}{1}(:,:,:,stim_cue{stim_type},:,1),5,'omitnan'),[1 2 3 6 4 5]);
curr_video1=permute(nanmean(data_all_video{1}{type}{1}(:,:,:,stim_cue{stim_type},:,7),5),[1 2 3 6 4 5]);
curr_video2=permute(nanmean(data_all_video{2}{type}{1}(:,:,:,stim_cue{stim_type},:,4),5),[1 2 3 6 4 5]);
curr_video=cat(4,curr_video0,curr_video1,curr_video2);

ap.imscroll(curr_video,use_t)
axis image off
ap.wf_draw('ccf',[0.5 0.5 0.5]);
% clim(0.9*max(curr_video,[],'all').*[-1,1]);
clim(0.0002.*[-1,1]);
colormap(ap.colormap('KWB'));
axis image;
% set(gcf,'name',sprintf('%s',[ group_name{group} ' ' data_type{type} ' ' align_time_name{align_time} ' ' stage_name{stage}]));
%
%
scale=0.0002;

figure('Position', [50 50 120*length(find(use_t>=0& use_t<=0.3)) 150*(size(curr_video,4)+1)]);
t1 = tiledlayout(size(curr_video,4)+1, length(find(use_t>=0& use_t<=0.3)), 'TileSpacing', 'none', 'Padding', 'none');
Color={'G','P','P','P','P','P','P'};

for curr_day=1:size(curr_video,4)
    for curr_time =find(use_t>=0& use_t<0.3)

        a_1=nexttile
        buff_image=curr_video(:,:,curr_time,curr_day);

        imagesc(buff_image)
        % imagesc(buff_image-fliplr(buff_image))
        axis image off;
        ap.wf_draw('ccf', [0.5 0.5 0.5]);
        clim(scale .* [-1, 1]);
        colormap( a_1, ap.colormap(['KW' Color{group}]  ));
        if curr_day==1
            title(num2str(t_kernels(curr_time)))
        end
        if curr_time==find(use_t>=0& use_t<0.3,1,'first')
            text(-30, 100, stage_name(stage(curr_day)), 'FontSize', 12, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle','Rotation', 90);
        end
    end

end
cb=colorbar('southoutside'); % 在下方添加 colorbar

% saveas(gcf,[Path 'figures\summary\figures\' stim_name{stim_type} '' data_type{type} ' across time in ' group_name{group}   ], 'jpg');






%% passive cross modality of 2 stage images and selectivity without naive stage


colors{1}={  [  84 130 53 ]./255,[0.5 1 0.5];...
       [112  48 160]./255,[0.5 0.5 0.5]}

colors{2}={  [  84 130 53 ]./255 ,[0.5 0.5 0.5];...
     [112  48 160]./255,[0.5 0.5 0.5]   }
scale=0.0002;
type=2;

Color={'G','P','P','P','P','P','P'};
titles{1}='naive'; titles{7}='first day in mod1'; titles{11}='mod1'; titles{26}='mod2'; titles{22}='first day in mod2';

all_buf_data=cell(2,1);
img_data1=cell(2,1)
buf3_roi_error_crossday=cell(2,1);
buf3_roi_mean_crossday=cell(2,1);
buf3_roi_l_acrosstime=cell(2,1);
buf3_roi_l_mean_crosstime=cell(2,1);
buf3_roi_l_error_crosstime=cell(2,1);
buf3_roi_peak1=cell(2,1);
all_data_passive=cell(2,1);
all_buf_data_each=cell(2,1);
legend_labels={{'L','C','R'},...
    {'4K','8K','12K'}};

figure('Position', [50 50 400 200]);
t = tiledlayout(2, 4, 'TileSpacing', 'tight', 'Padding', 'none');
    for curr_passive=1:2
        for curr_group=1:2

        if curr_passive==1
            use_stim=3;
        else
            use_stim=2;
        end

        if (curr_group==1 & curr_passive==1) | (curr_group==2 & curr_passive==2)
            use_day=11;
        elseif (curr_group==1 & curr_passive==2) | (curr_group==2 & curr_passive==1)
            use_day=26;
        end

        for curr_day=use_day
            a1=nexttile(t,curr_passive*4-4+curr_group)

            temp_data=arrayfun(@(idx) max(data_all_days{curr_group}{type}{curr_passive}{idx}{curr_day}(:,:,use_period,use_stim),[],3),...
                1:length(data_all_days{curr_group}{type}{curr_passive}),'UniformOutput',false);
            temp_image=nanmean(cat(3,temp_data{:}),3);

            imagesc(temp_image)
            axis image off;
            colormap(a1,ap.colormap(['W' Color{curr_group}] ));
            ap.wf_draw('ccf', [0.5 0.5 0.5]);
            clim(scale .* [0, 1]);

        end

        curr_data=cat(2 ,data_all_days{curr_group}{type}{curr_passive}{:});
        buf1= cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),curr_data,'UniformOutput',false) ;
        for curr_roi=1:length(roi1)
            buf3_roi_l_acrosstime=  cellfun(@(x) permute(nanmean(x(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),buf1,'UniformOutput', false);
            buf3_roi_peak=cellfun(@(x) double(max(x(use_period,:),[],1) )',buf3_roi_l_acrosstime, 'UniformOutput', false);

            buf3_roi_peak_0= arrayfun(@(a) cellfun(@(x) x(a) ,buf3_roi_peak,'UniformOutput',true),1:3,'UniformOutput',false);

            buf3_roi_error_crossday{curr_group}{curr_passive}{curr_roi}=...
                {
                std(buf3_roi_peak_0{use_stim},0,2,'omitmissing')./...
                sqrt(size(buf3_roi_peak_0{1},2)),...
                std(nanmean( cat(3,buf3_roi_peak_0{[1 5-use_stim]}),3),0,2,'omitmissing')./...
                sqrt(size(buf3_roi_peak_0{use_stim},2))};

            buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}= ...
                {nanmean(buf3_roi_peak_0{use_stim},2),...
                nanmean( cat(3,buf3_roi_peak_0{[1 5-use_stim]}),[2,3])};



        end

        if (curr_group==1 & curr_passive==1)
            use_roi=1;  use_days=[7 :11]; stage=1;
        elseif (curr_group==2 & curr_passive==2)
            use_roi=3;use_days=[7: 11];stage=1;
        elseif (curr_group==1 & curr_passive==2)
            use_roi=3;  use_days=[22: 26];stage=2;
        elseif (curr_group==2 & curr_passive==1)
            use_roi=1;  use_days=[22 :26];stage=2;
        end


        nexttile(t,curr_passive*4-4+3)
        hold on
        for curr_passivestim=1:2
            curr_value = buf3_roi_mean_crossday{curr_group}{curr_passive}{use_roi}{curr_passivestim};
            curr_error = buf3_roi_error_crossday{curr_group}{curr_passive}{use_roi}{curr_passivestim};
            color = colors{curr_passive}{curr_group, curr_passivestim};
            % ap.errorfill(1:5,curr_value(7:11),curr_error(7:11),color,0.1 )
            % ap.errorfill(6:10,curr_value(22:26),curr_error(22:26),color,0.1 )
            ap.errorfill(1:5,curr_value(use_days),curr_error(use_days),color,0.1 )

        end
        ylim(scale*[0 1])
        xlim([1 5])
        xticks([3 8])
        xticklabels({'mod 1','mod 2'})

    end
end



%%


overlays{1}={[1 1 5],[2 1 8]};
overlays{2}={[1 2 8],[2 2 5]};
overlays{3}={[1 1 5],[1 2 8]};
overlays{4}={[2 2 5],[2 1 8]};

overlays{5}={[1 1 9],[2 1 9]};
overlays{6}={[1 2 9],[2 2 9]};
overlays{7}={[1 1 9],[1 2 9]};
overlays{8}={[2 2 9],[2 1 9]};
threshold=0.0001;

p_map=cell(8,1);
p_vals=cell(8,1);
for curr_overlay=1:8


    temp_A=all_buf_data_each{overlays{curr_overlay}{1}(1)}{overlays{curr_overlay}{1}(2)}{overlays{curr_overlay}{1}(3)};
    temp_B=all_buf_data_each{overlays{curr_overlay}{2}(1)}{overlays{curr_overlay}{2}(2)}{overlays{curr_overlay}{2}(3)};
    
    ap.imscroll(temp_B)
    colormap(ap.colormap(['W' Color{1}] ));
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
    clim(scale .* [0, 2]);
            axis image off;

    temp_A(temp_A<threshold)=0;
    temp_B(temp_B<threshold)=0;
    switch curr_overlay
        case  {1,2,5,6}
            p_map{curr_overlay}=ds.image_diff(temp_A,temp_B,0,1);
        case {3,4,7,8}
            p_map{curr_overlay}=ds.image_diff(temp_A,temp_B,1,1);
    end
    p_vals{curr_overlay}=reshape(p_map{curr_overlay},[],size(p_map{curr_overlay},3));
end

colors1 = [...
   0.3 0.3 0.9;   % Group 1: 蓝色
    0.9 0.4 0.4;   % Group 2: 绿色
    [84 130 53]./255;
     [112  48 160]./255
      0.3 0.3 0.9;   % Group 1: 蓝色
    0.9 0.4 0.4;   % Group 2: 绿色
    [84 130 53]./255;
     [112  48 160]./255];  % Group 3: 红色

legend_names={'V', 'A', 'VA','AV','V', 'A', 'VA','AV'}
% test_scale=1:4; % mod1-mod2
test_scale=5:8; % mixed stage

figure('Position',[50 50 400 500])
t2 = tiledlayout(3, 2, 'TileSpacing', 'none', 'Padding', 'none');

for curr_overlay=test_scale
    aa=nexttile(t2)
   
    imagesc(-1*(p_map{curr_overlay}<0.05)+(p_map{curr_overlay}>0.95));  axis image off
    switch curr_overlay
        case {1,5}
            colormap(aa, ap.colormap(['GWP'] ));
        case {2,6}
            colormap(aa, ap.colormap(['GWP'] ));
        case{3,7}
            colormap(aa, ap.colormap(['BWR'] ));
        case{4,8}
            colormap(aa, ap.colormap(['RWB'] ));
    end
    clim([-2 2])
    ap.wf_draw('ccf', [0.5 0.5 0.5]);

    title(legend_names{curr_overlay},'Color',colors1(curr_overlay,:))

end


% differen roi
 curr_roi=[1 2 3 4 5 6 8 12];
 p_thres_1=cellfun(@(x) x>0.95,p_vals,'UniformOutput',false);
 p_thres_roi_mean_1= cellfun(@(x) arrayfun(@(roi) mean(x(roi1(roi).data.mask(:),:,:),1,'omitnan'),...
    curr_roi,'UniformOutput',true),p_thres_1,'UniformOutput',false);
 p_thres_2=cellfun(@(x) x<0.05,p_vals,'UniformOutput',false);
 p_thres_roi_mean_2= cellfun(@(x) arrayfun(@(roi) mean(x(roi1(roi).data.mask(:),:,:),1,'omitnan'),...
    curr_roi,'UniformOutput',true),p_thres_2,'UniformOutput',false);
data = cell2mat(p_thres_roi_mean_1(test_scale))'+ cell2mat(p_thres_roi_mean_2(test_scale))';

nexttile(t2,[1,2])
hBar = bar(data, 'grouped'); hold on;
box off
for i = 1:length(hBar)
    hBar(i).FaceColor = colors1(i, :);
    hBar(i).EdgeColor = 'none';       % 无边框线
end

set(gca, 'XTick', 1:8, 'XTickLabel', {'pl-mPFC', 'pr-mPFC', 'al-mPFC', 'ar-mPFC', 'l-PPC', 'r-PPC', 'auditory area', 'visual area'});
 legend({'V', 'A', 'VA','AV'}, 'Location', 'northeastoutside','Box','off');
ylabel('proportion of difference ');

saveas(gcf,[Path 'figures\summary\figures\passive of 3 stage images and selectivity 1'], 'jpg');


%% passive cross modality of 2 stage images and selectivity 


colors{1}={  [  84 130 53 ]./255,   [0.5 0.5 0.5]  ;...
       [112  48 160]./255 ,[0.5 0.5 0.5]}

colors{2}={  [  84 130 53 ]./255  ,[0.5 0.5 0.5]         ;...
     [112  48 160]./255,  [0.5 0.5 0.5]}
scale=0.0002;
type=2;
figure('Position', [50 50 700 600]);
t = tiledlayout(4, 5, 'TileSpacing', 'tight', 'Padding', 'none');
Color={'G','P','P','P','P','P','P'};
titles{1}='naive'; titles{5}='mod1'; titles{8}='mod2'; titles{9}='mixed';

all_buf_data=cell(2,1);
img_data1=cell(2,1)
buf3_roi_error_crossday=cell(2,1);
buf3_roi_mean_crossday=cell(2,1);
buf3_roi_l_acrosstime=cell(2,1);
buf3_roi_l_mean_crosstime=cell(2,1);
buf3_roi_l_error_crosstime=cell(2,1);
buf3_roi_peak1=cell(2,1);
all_data_passive=cell(2,1);
all_buf_data_each=cell(2,1);

buf3_roi_selectivity_crossday=cell(2,1);
buf3_roi_selectivity_error_crossday=cell(2,1);
legend_labels={{'L','C','R'},...
    {'4K','8K','12K'}};
for curr_group=1:2
    for curr_passive=1:2
        if curr_passive==1
            use_stim=3;
        else
            use_stim=2;
        end

        for curr_day=[ 1  5 8 ]
            a1=nexttile

         temp_image=cat(2,data_all_days{curr_group}{2}{curr_passive}{:});
        temp_image2= cat(5, temp_image{curr_day,:});
        buf_images_all1= permute(nanmean(max(temp_image2(:,:,use_period,:,:),[],3),5),[1,2,4,3,5]);


            all_buf_data_each{curr_group}{curr_passive}{curr_day}=...
                permute(max(data_all_video{curr_group}{type}{curr_passive}...
                (:,:,period_kernels,use_stim,:,curr_day),[],3),[1 2 5 3 4]);
            temp_data=nanmean(data_all_video{curr_group}{type}{curr_passive}(:,:,:,use_stim,:,curr_day),5);
            temp_image=max(temp_data(:,:,period_kernels),[],3);
            all_buf_data{curr_group}{curr_passive}{curr_day}=temp_image;

            imagesc(temp_image)
            axis image off;
            colormap(a1,ap.colormap(['W' Color{curr_group}] ));
            clim(scale .* [0.3, 0.7]);

            frame1 = getframe(gca);
            img_data1{curr_group}{curr_passive}{curr_day} =im2double( imresize(frame1.cdata, size(temp_image)));
            ap.wf_draw('ccf', [0.5 0.5 0.5]);
            clim(scale .* [0, 1]);

            if curr_group==1& curr_passive==1
                title(titles{curr_day}, 'FontWeight', 'normal', 'FontSize', 12)
            end

            if curr_passive==1&curr_day==2
                text(-50, 50,  'V passive', 'FontSize', 12, 'FontWeight', 'normal', ...
                    'HorizontalAlignment', 'right', 'Rotation', 90);
            elseif curr_passive==2&curr_day==2
                text(-50, 50,  'A passive', 'FontSize', 12, 'FontWeight', 'normal', ...
                    'HorizontalAlignment', 'right', 'Rotation', 90);
            end
        end

      curr_data=cat(2 ,data_all_days{curr_group}{type}{curr_passive}{:});
        % curr_data=data_all_video{curr_group}{type}{curr_passive};
        buf1= cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),curr_data,'UniformOutput',false) ;
        for curr_roi=1:length(roi1)
            buf3_roi_l_acrosstime=  cellfun(@(x) permute(nanmean(x(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),buf1,'UniformOutput', false);
            buf3_roi_peak=cellfun(@(x) double(max(x(use_period,:),[],1) )',buf3_roi_l_acrosstime, 'UniformOutput', false);
            
            buf3_roi_peak_0= arrayfun(@(a) cellfun(@(x) x(a) ,buf3_roi_peak,'UniformOutput',true),1:3,'UniformOutput',false)
            buf3_roi_peak1= arrayfun(@(idx)...
                [nanmean(buf3_roi_peak_0{idx}(1:3,:),1);...
                nanmean(buf3_roi_peak_0{idx}(4,:),1);...
                nanmean(buf3_roi_peak_0{idx}(5:6,:),1);...
                nanmean(buf3_roi_peak_0{idx}(7:9,:),1);...
                nanmean(buf3_roi_peak_0{idx}(10:11,:),1);...
                nanmean(buf3_roi_peak_0{idx}(12:13,:),1);...
                nanmean(buf3_roi_peak_0{idx}(14:15,:),1);...
                nanmean(buf3_roi_peak_0{idx}(17:18,:),1);...
                nanmean(buf3_roi_peak_0{idx}(19:21,:),1)],1:3,'UniformOutput',false)

       

            buf3_roi_error_crossday{curr_group}{curr_passive}{curr_roi}=...
                {
                std(buf3_roi_peak1{use_stim},0,2,'omitmissing')./...
                sqrt(size(buf3_roi_peak1{use_stim},2)),...
                std(nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3),0,2,'omitmissing')./...
                sqrt(size(buf3_roi_peak1{1},2))};

            buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}= ...
                {
                nanmean(buf3_roi_peak1{use_stim},2),
                nanmean(nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3),2)...
                };


         

               buf3_roi_selectivity_crossday{curr_group}{curr_passive}{curr_roi}= ...
            nanmean(   ( buf3_roi_peak1{use_stim}-nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3))./...
               ( buf3_roi_peak1{use_stim}+nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3)),2);

             buf3_roi_selectivity_error_crossday{curr_group}{curr_passive}{curr_roi}= ...
            std(   ( buf3_roi_peak1{use_stim}-nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3))./...
               ( buf3_roi_peak1{use_stim}+nanmean(cat(3,buf3_roi_peak1{[1 5-use_stim]}),3)),0,2,'omitmissing')./...
               sqrt(size(buf3_roi_peak1{1},2));

         
        end

        for curr_roi = [1  3  ]
            switch curr_roi
                case 1
                    nexttile(t,10*curr_group+5*curr_passive-11)
                    hold on
                case 2
                    nexttile(t,12*curr_group+6*curr_passive-18)
                    hold on
                case 3
                    nexttile(t,10*curr_group+5*curr_passive-10)
                    hold on
                case 4
                    nexttile(t,12*curr_group+6*curr_passive-16)
                    hold on
            end

            curr_day = 4-curr_passive

            for curr_day=1:2
            value_columns = [1 5 8 ];
            curr_value = buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}{curr_day}(value_columns);
            curr_error = buf3_roi_error_crossday{curr_group}{curr_passive}{curr_roi}{curr_day}( value_columns);
            color = colors{curr_passive}{curr_group, curr_day};
            errorbar(1:3, curr_value, curr_error, 'Color', color, 'CapSize', 6, 'LineStyle', '-','LineWidth',2);
            end
            ylim(scale*[0 1.2])

            
            % curr_value = buf3_roi_selectivity_crossday{curr_group}{curr_passive}{curr_roi}(value_columns);
            % curr_error = buf3_roi_selectivity_error_crossday{curr_group}{curr_passive}{curr_roi}( value_columns);
            % color = colors{curr_passive}{curr_group, 2};
            % errorbar(1:3, curr_value, curr_error, 'Color', color, 'CapSize', 6, 'LineStyle', '-','LineWidth',2);
            % % ylim([-0.5 1])
            % ylim(scale*[0 1.2])



            xlim([0.5 3.5])
            xticks([1 2 3 ])
            set(gca,'color','none')
            xticklabels({'naive','mod 1','mod 2'}); % 设置对应的标签
            if curr_group==1& curr_passive==1
                title(roi1(curr_roi).name, 'FontWeight', 'normal', 'FontSize', 10)
                
            end
            if curr_roi==3 & curr_passive==1
                legend({'task cue','other cues'},"Box","off")
            end
            ylabel('\Delta F/F_0')
            
        end
    
    
    end
end



%% passive cross modality of mixed stage images and selectivity
colors{1}={[0 0 0],    [0 0 0],            [  84 130 53 ]./255;...
    [0 0 0], [0 0 0],    [112  48 160]./255}
colors{2}={[0 0 0],  [  84 130 53 ]./255  ,  [0 0 0]          ;...
    [0 0 0], [112  48 160]./255    ,[0 0 0]}
scale=0.0002;
type=2;
figure('Position', [50 50 470 250]);
t1 = tiledlayout(2, 4, 'TileSpacing', 'tight', 'Padding', 'tight');
Color={'G','P','P','P','P','P','P'};
titles{1}='naive'; titles{5}='Mod1'; titles{8}='Mod2'; titles{9}='mixed';

all_buf_data=cell(2,1);
img_data1=cell(2,1)
buf3_roi_error_crossday=cell(2,1);
buf3_roi_mean_crossday=cell(2,1);
buf3_roi_l_mean_crosstime=cell(2,1);
buf3_roi_l_error_crosstime=cell(2,1);
buf3_roi_peak1=cell(2,1);
all_data_passive=cell(2,1);
all_buf_data_each=cell(2,1);
for curr_group=1:2
    for curr_passive=1:2
        if curr_passive==1
            use_stim=3;
        else
            use_stim=2;
        end

        for curr_day=[ 9 ]
            a1=nexttile(t1,curr_passive+4*curr_group-4)
            all_buf_data_each{curr_group}{curr_passive}{curr_day}=...
                permute( max(data_all_video{curr_group}{type}{curr_passive}(:,:,:,use_stim,:,curr_day),[],3),[1 2 5 3 4])
            temp_data=nanmean(data_all_video{curr_group}{type}{curr_passive}(:,:,:,use_stim,:,curr_day),5);
            temp_image=max(temp_data(:,:,period_kernels),[],3);
            all_buf_data{curr_group}{curr_passive}{curr_day}=temp_image;

            imagesc(temp_image)
            axis image off;
            colormap(a1,ap.colormap(['W' Color{curr_group}] ));
           
            ap.wf_draw('ccf', [0.5 0.5 0.5]);
            clim(scale .* [0, 1]);

            if curr_group==1& curr_passive==1
                title(titles{curr_day},'FontWeight','normal')
            end

            if curr_passive==1&&curr_day==1
                text(-50, 50,  'V passive', 'FontSize', 10, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'right', 'Rotation', 90);
            elseif curr_passive==2&curr_day==1
                text(-50, 50,  'A passive', 'FontSize', 10, 'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'right', 'Rotation', 90);
            end

            % if curr_passive==2
            %     colorbar('southoutside')
            % end
        end


        curr_data=cat(2 ,data_all_days{curr_group}{type}{curr_passive}{:});
        buf1= cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3),size(x,4)),curr_data,'UniformOutput',false) ;
        selected_roi=2*curr_passive-1;
        % selected_roi=[1 ]
        a2=nexttile(t1,4*curr_group+curr_passive-2)
        hold on
        for curr_roi=1:length(roi1)

            buf3_roi_l_acrosstime=  cellfun(@(x) permute(nanmean(x(roi1(curr_roi).data.mask(:),:,:,:),1),[2,3,4,1]),buf1,'UniformOutput', false);
            buf3_roi_l_mean_crosstime{curr_group}{curr_passive}{curr_roi}= arrayfun(@(day) nanmean(cat(3,buf3_roi_l_acrosstime{day,:}),3),1:size(buf3_roi_l_acrosstime,1),'UniformOutput',false );
            buf3_roi_l_error_crosstime{curr_group}{curr_passive}{curr_roi}= arrayfun(@(day) std(cat(3,buf3_roi_l_acrosstime{day,:}),0,3,'omitmissing')./sqrt(size(cat(3,buf3_roi_l_acrosstime{day,:}),3)),1:size(buf3_roi_l_acrosstime,1),'UniformOutput',false );
            buf3_roi_l_mean= arrayfun(@(day) nanmean(cat(3,buf3_roi_l_acrosstime{day,:}),3),1:size(buf3_roi_l_acrosstime,1),'UniformOutput',false );

            all_data_passive{curr_group}{curr_passive}{curr_roi}=cat(3,buf3_roi_l_mean{:});
            buf3_roi_peak=cellfun(@(x) double(max(x(use_period,:),[],1) )',buf3_roi_l_acrosstime, 'UniformOutput', false);
            buf3_roi_peak1{curr_group}{curr_passive}{curr_roi}=reshape(cat(2,buf3_roi_peak{:}), [length(buf3_roi_peak{1}) size(buf3_roi_peak)]);
            buf3_roi_error_crossday{curr_group}{curr_passive}{curr_roi}=...
                std(nanmean(buf3_roi_peak1{curr_group}{curr_passive}{curr_roi}(:,19:21,:),2),0,3,"omitmissing")./sqrt(size(buf3_roi_peak1{curr_group}{curr_passive}{curr_roi},3));
            buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}=...
                nanmean(buf3_roi_peak1{curr_group}{curr_passive}{curr_roi}(:,19:21,:),[2,3]);
        end

        for curr_roi=selected_roi

            for curr_day=1:3
                errorbar(curr_day,buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}(curr_day),...
                    buf3_roi_error_crossday{curr_group}{curr_passive}{curr_roi}(curr_day),...
                    'Color', colors{curr_passive}{curr_group,curr_day},...
                    'CapSize', 6, 'LineStyle', 'none','LineWidth',2)
                scatter(curr_day, buf3_roi_mean_crossday{curr_group}{curr_passive}{curr_roi}(curr_day),50,...
                    colors{curr_passive}{curr_group,curr_day}, 'filled');

            end
            xlim([0.5 3.5])
            % ylim(scale*[-0.4 1.2])
            ylim(scale*[0 1])

            title(roi1(curr_roi).name,'FontWeight','normal')
            xticks([2])
            xticklabels({'mixed'}); % 设置对应的标签
            ylabel('\Delta F/F')
        end



        

    end
end


