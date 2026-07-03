clear all
Path='D:\Data process\project_SNr\data\ephys_data\single_neuron';
load('D:\Data process\project_SNr\data\ephys_data\neuronal_id_label\neuronal_labels.mat');

use_labels={'stim_0correct','stim_1correct','move_0correct','move_1correct','iti_move_l','iti_move_r','stim_0error','stim_1error','move_0error','move_1error'};
temp_response_all=cell(length(neuron_id),1);
temp_task_psth_all=cell(length(neuron_id),1);
temp_passive_psth_all=cell(length(neuron_id),1);
temp_response_passive_all=cell(length(neuron_id),1);
passive_workflow= {'lcr_passive_grating_size40','lcr_passive_checkerboard','lcr_passive_squareHorizontalStripes'};

for curr_recording=1:length(neuron_id)
    animal=neuron_id(curr_recording).animal;
    rec_day=neuron_id(curr_recording).rec_day;
    load_probe=neuron_id(curr_recording).probe;
    cell_id=neuron_id(curr_recording).id;
    workflow='stim_wheel_Vcenter_cross_movement_stage2_error_repeat';

    recordings =plab.find_recordings(animal,rec_day,'*stim*'); 
    
    rec_time=recordings.recording{1};
    verbose=true;
    try
        ap.load_recording

    catch
        fprintf('Skip curr_recording %d\n', curr_recording);
        continue;
    end
    ds.load_iti_move
    ds.process_ephys
    lable_idx=cellfun(@(x) find(ismember(ephys_data.labels,x)),use_labels,'UniformOutput',true);
    temp_task_psth_all{curr_recording}=ephys_data.psth(cell_id,:,lable_idx);
    temp_response_all{curr_recording}=cellfun(@(x)    x(cell_id) , ephys_data.response_p(lable_idx),'UniformOutput',false);


    % Determine the response for the current recording
    response_cell=temp_response_all{curr_recording}{1}>0.95| temp_response_all{curr_recording}{1}<0.05|...
        temp_response_all{curr_recording}{2}>0.95|temp_response_all{curr_recording}{2}<0.05;

    response_cell_stm=[temp_response_all{curr_recording}{1} temp_response_all{curr_recording}{2}];
    temp_stim=cell(size(response_cell_stm));
    temp_stim(response_cell_stm>0.95)={'H'};
    temp_stim(response_cell_stm<0.05)={'L'};
    temp_stim(response_cell_stm>=0.05&response_cell_stm<=0.95)={'0'};

    temp_task_raster=cellfun(@(x)  x(:,:,cell_id), ephys_data.raster(lable_idx),'UniformOutput',false);
    move_idx=cellfun(@(x)  stim_to_move(x),  ephys_data.event_idx,'UniformOutput',false);
    [temp_s2m,temp_idx]=cellfun(@(x) sort(x,'descend'),move_idx([1:2]),'UniformOutput',false);
    temp_s2m_1=[temp_s2m(1:2) ;cellfun(@(x) -x,  temp_s2m(1:2),'UniformOutput',false)];
    cell_ids=find(response_cell);
    raster_t=ephys_data.raster_t;
    

    recordings_passive =plab.find_recordings(animal,rec_day,'*lcr_passive*');
    temp_passive_raster=cell(3,1);
    temp_passive_psth=cell(3,1);
    temp_response_passive=cell(3,1);
    for curr_passive =1:length(passive_workflow)
        temp_id= find(ismember(recordings_passive.workflow,passive_workflow{curr_passive}),1,'last');
        rec_time=recordings_passive.recording{temp_id};
        verbose=true;
        ap.load_recording
        clear ephys_data
        ds.process_ephys

        temp_passive_raster{curr_passive}=cellfun(@(x)  x(:,:,cell_id) ,ephys_data.raster(1:3),'uni',false);
        temp_passive_psth{curr_passive}= ephys_data.psth(cell_id,:,1:3);
        temp_response_passive{curr_passive}= ephys_data.response_p{2}(cell_id);

    end
    temp_passive_psth_all{curr_recording}=temp_passive_psth;
    temp_response_passive_all{curr_recording}=temp_response_passive;

    % for curr_cell=1:length(cell_ids)
    % 
    %     curr_cell_id=cell_ids(curr_cell);
    %     [raster_y,raster_x] =cellfun(@(x,y) find(x(y,:,curr_cell_id)),temp_task_raster,...
    %         [temp_idx([1:2 1:2]);cellfun(@(x)( 1:length(x))' , iti_move_time,'UniformOutput',false)],'UniformOutput',false  );
    % 
    % 
    %     figure
    %     tiledlayout(4,3)
    %     for curr_stage=1:3
    %         nexttile
    %         hold on
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2-1),[2,3,1]),'r')
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2),[2,3,1]),'b')
    % 
    %         ylim([  min( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")...
    %             max( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")]);
    % 
    %         xlim([-0.3 0.7])
    %         xline(0)
    %         axis off
    %     end
    %     for curr_stage=1:2
    %         nexttile
    %         offset=0;
    %         hold on
    %         colors={'r','b','r','b'};
    %         for curr_state = 2*curr_stage:-1: 2*curr_stage-1
    % 
    %             n_trial = size(temp_task_raster{curr_state},1);
    % 
    %             % raster
    %             y1 = raster_y{curr_state} + offset;
    %             plot(ephys_data.raster_t(raster_x{curr_state}), y1, ['.' colors{curr_state}]);
    % 
    %             % green points
    %             y2 = (1:n_trial) + offset;
    %             plot(temp_s2m_1{curr_state}, y2, '.g');
    % 
    %             yline(offset + n_trial + 0.5, '-k');
    %             % 累积offset（不留空行）
    %             offset = offset + n_trial;
    %         end
    %         ylim([0  length(cat(1,temp_s2m_1{1:2}))])
    %         xlim([-0.3 0.7])
    %         ylabel('Trials')
    %         xlabel('Time')
    %         box off
    %         axis off
    %         drawnow
    % 
    %     end
    % 
    % 
    %     for curr_stage=3
    %         nexttile
    %         offset=0;
    %         hold on
    %         colors={'r','b','r','b','r','b'};
    %         for curr_state = 2*curr_stage:-1: 2*curr_stage-1
    % 
    %             n_trial = size(temp_task_raster{curr_state},1);
    % 
    %             % raster
    %             y1 = raster_y{curr_state} + offset;
    %             plot(ephys_data.raster_t(raster_x{curr_state}), y1, ['.' colors{curr_state}]);
    % 
    % 
    %             yline(offset + n_trial + 0.5, '-k');
    %             % 累积offset（不留空行）
    %             offset = offset + n_trial;
    %         end
    %         ylim([0  length(cat(1,iti_move_time{1:2}))])
    %         xlim([-0.3 0.7])
    %         ylabel('Trials')
    %         xlabel('Time')
    %         box off
    %         axis off
    %         drawnow
    % 
    %     end
    % 
    % 
    %     [raster_y_passive,raster_x_passive] =cellfun(@(a) cellfun(@(x) find(x(:,:,curr_cell_id)),a,'UniformOutput',false),...
    %         temp_passive_raster,'UniformOutput',false  );
    %     colors={{'k','b','k'},{'k','r','k'},{'k','g','k'}};
    %     for curr_stage=1:3
    %         nexttile
    %         hold on
    %         arrayfun(@(id)  plot(  raster_t, permute(temp_passive_psth{curr_stage}(curr_cell_id,:,id),[2,3,1]),colors{curr_stage}{id}),...
    %             1:3,'UniformOutput',false)
    % 
    %         ylim([  min( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")...
    %             max( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")]);
    % 
    %         xlim([-0.3 0.7])
    %         xline(0)
    %         axis off
    %     end
    % 
    %     for curr_passive=1:3
    %         nexttile
    %         offset=0;
    %         hold on
    %         for curr_state = 1:3
    % 
    %             n_trial = size(temp_passive_raster{curr_passive}{curr_state},1);
    % 
    %             % raster
    %             y1 = raster_y_passive{curr_passive}{curr_state} + offset;
    %             plot(raster_t(raster_x_passive{curr_passive}{curr_state}), y1, ['.' colors{curr_passive}{curr_state}]);
    % 
    % 
    %             yline(offset + n_trial + 0.5, '-k');
    %             % 累积offset（不留空行）
    %             offset = offset + n_trial;
    %         end
    %         ylim([0  size(cat(1,temp_passive_raster{curr_passive}{:}),1)])
    %         xlim([-0.3 0.7])
    %         ylabel('Trials')
    %         xlabel('Time')
    %         box off
    %         axis off
    %         drawnow
    % 
    %     end
    % 
    % 
    %     sgtitle([ animal ' ' rec_day  ' cell ' num2str(cell_id(curr_cell_id)) ' state:' cat(2,temp_stim{curr_cell_id,:})])
    % 
    %     saveas(gcf,fullfile(Path ,[animal ' ' rec_day  ' cell ' num2str(cell_id(curr_cell_id)) ' state_' cat(2,temp_stim{curr_cell_id,:}) '.png']))
    % 
    %     exportgraphics(gcf, fullfile(Path ,[animal ' ' rec_day  ' cell ' num2str(cell_id(curr_cell_id)) ' state_' cat(2,temp_stim{curr_cell_id,:}) '.eps']), ...
    %         'ContentType','vector');
    %     savefig(gcf,fullfile(Path ,[animal ' ' rec_day  ' cell ' num2str(cell_id(curr_cell_id)) ' state_' cat(2,temp_stim{curr_cell_id,:}) '.fig']))
    % end


    % for curr_cell=1:length(cell_ids)
    %     curr_cell_id=cell_ids(curr_cell);
    %     [raster_y,raster_x] =cellfun(@(x,y) find(x(y,:,curr_cell_id)),temp_task_raster(1:6),...
    %         [temp_idx([1:2 1:2]);cellfun(@(x)( 1:length(x))' , iti_move_time,'UniformOutput',false)],'UniformOutput',false  );
    % 
    %     color_dots=ap.colormap('BWR');
    %     color_dot={color_dots(1,:),color_dots(end,:)};
    %     color_line={[0.2 0.8 0.2],[0.8 0.8 0.2]}
    %     figure('Position',[50 50 560 420])
    %     tiledlayout(2,2,'TileSpacing','tight')
    %     for curr_stage=1:2
    %         nexttile
    %         hold on
    %         xline(0,'Color',color_line{curr_stage},'LineWidth',2)
    % 
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2-1),[2,3,1]),...
    %             'Color',color_dots(end,:),'LineWidth',1.5)
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2),[2,3,1]),...
    %             'Color',color_dots(1,:),'LineWidth',1.5)
    % 
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2+5),[2,3,1]),...
    %             'Color',color_dots(200,:),'LineWidth',1.5)
    %         plot(  raster_t,  permute(temp_task_psth_all{curr_recording}(curr_cell_id,:,curr_stage*2+6),[2,3,1]),...
    %             'Color',color_dots(50,:),'LineWidth',1.5)
    % 
    % 
    %         ylim([  min( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")...
    %             max( temp_task_psth_all{curr_recording}(curr_cell_id,:,:),[],"all")]);
    % 
    %         xlim([-0.2 0.3])
    %         axis off
    %     end
    %     % temp_scale=ylim;
    %     %  line([-0.2 -0.1],[temp_scale(1) temp_scale(1)],'Color','k')
    %     %  line([-0.2 -0.2],[temp_scale(1) temp_scale(1)+2],'Color','k')
    % 
    %     for curr_stage=1:2
    %         nexttile
    %         offset=0;
    %         hold on
    %         colors={color_dots(end,:),color_dots(1,:),color_dots(end,:),color_dots(1,:)};
    %         for curr_state = 2*curr_stage:-1: 2*curr_stage-1
    % 
    %             n_trial = size(temp_task_raster{curr_state},1);
    % 
    %             % raster
    %             y1 = raster_y{curr_state} + offset;
    %             plot(ephys_data.raster_t(raster_x{curr_state}), y1,...
    %                 'LineStyle','none','Marker','.' ,'Color',colors{curr_state}, 'MarkerSize', 2);
    % 
    %             % green points
    %             y2 = (1:n_trial) + offset;
    %             % plot(temp_s2m_1{curr_state}, y2,'Color',color_line{curr_stage}, 'MarkerSize', 2);
    %             plot(temp_s2m_1{curr_state}, y2,'LineStyle','none','Marker','.','Color',color_line{3-curr_stage}, 'MarkerSize', 4);
    % 
    %             % yline(offset + n_trial + 0.5, '-k');
    %             % 累积offset（不留空行）
    %             offset = offset + n_trial;
    %         end
    %         ylim([0  length(cat(1,temp_s2m_1{1:2}))])
    %         xlim([-0.2 0.3])
    %         ylabel('Trials')
    %         xlabel('Time')
    %         box off
    %         axis off
    %         drawnow
    % 
    %     end
    % end

end

save('D:\Data process\project_SNr\data\ephys_data\temp_data.mat',...
    'temp_response_all','temp_task_psth_all','temp_passive_psth_all','temp_response_passive_all','raster_t','-v7.3')

%%
load('D:\Data process\project_SNr\data\ephys_data\temp_data.mat')
t_period=find(raster_t>0 & raster_t<0.2);

response_all=feval(@(Y)  arrayfun(@(id)    cat(1,Y{id,:})  ,  1:4,'uni',false),...
    feval(@(X)  cat(2,X{:}),  temp_response_all(~cellfun(@(x) isempty(x),temp_response_all ))));

response_all2=cellfun(@(x) 2*(x>0.95)+1*(x<0.05)     ,response_all,'UniformOutput',false);
% response_all3=response_all2{1}&response_all2{2};



psth_all=feval(@(X)  cat(1,X{:}),  temp_task_psth_all(~cellfun(@(x) isempty(x),temp_task_psth_all )));

tem_passive_psth=temp_passive_psth_all(~cellfun(@(x) isempty(x),temp_passive_psth_all ))
psth_all_passive=feval(@(X)  cat(2,X{:}), tem_passive_psth);
psth_all_passive_1=arrayfun(@(id)    cat(1,psth_all_passive{id,:}),1:3,'UniformOutput',false);

response_all_passive=feval(@(Y)  arrayfun(@(id)    cat(1,Y{id,:})  ,  1:3,'uni',false),...
    feval(@(X)  cat(2,X{:}),  temp_response_passive_all(~cellfun(@(x) isempty(x),temp_response_passive_all ))));

response_all_passive2=cellfun(@(x) 2*(x>0.95)+1*(x<0.05)     ,response_all_passive,'UniformOutput',false);

% temp_psth=psth_all(response_all3>0,:,:);

% [a,b]=max(psth_all(response_all3,t_period,:),[],2)

figure
tiledlayout(2,4,'TileIndexing','columnmajor')
for curr_state=1:4
    nexttile
    [a,b]= sort(response_all2{1},'descend');
    imagesc(psth_all(b(find(a>0)),:,curr_state))
    
    % imagesc(temp_psth(b,:,curr_state))
    clim([-3 3])
    colormap(ap.colormap('PWG'))
    nexttile
    plot( permute(nanmean(psth_all(response_all2{curr_state}>0,:,curr_state),1),[2,1,3]) )
end
%%
figure;
nexttile
[a,b]= sort(response_all2{1},'descend');
imagesc(raster_t,[],psth_all(b(find(a>0)),:,1))
clim([-3 3])
colormap(ap.colormap('BWR'))
xlim([-0.2 1])
hold on 
scale_x=ylim

line([-0.2 -0.2],[scale_x(2)-100 scale_x(2)],'LineWidth',2,'Color','k')
line([-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')
axis off

nexttile
temp_mean=permute(nanmean(psth_all(response_all2{1}==2,:,1),1),[2,1,3]);
temp_error=permute(nanstd(psth_all(response_all2{1}==2,:,1),0,1)./sqrt(size(psth_all(response_all2{1}==2,:,1),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error','r')
axis off

hold on
temp_mean=permute(nanmean(psth_all(response_all2{1}==1,:,1),1),[2,1,3]);
temp_error=permute(nanstd(psth_all(response_all2{1}==1,:,1),0,1)./sqrt(size(psth_all(response_all2{1}==1,:,1),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error','b')


ylim([-1 2])
xlim([-0.2 1])
line([-0.2 0],[-1 -1],'LineWidth',2,'Color','k')
line([-0.2 -0.2],[-1 -0.5],'LineWidth',2,'Color','k')

axis off

figure
tiledlayout(2,2,'TileIndexing','columnmajor')
colors={'R','B'}
for curr_state=1:2
a1= nexttile
[a,b]= sort(response_all2{curr_state},'descend');
imagesc(raster_t,[],psth_all(b(find(a>0)),:,curr_state))
clim([-3 3])
colormap(a1,ap.colormap(['KW' colors{curr_state}]))
xlim([-0.2 1])
hold on 
line([-0.2 -0.2],[scale_x(2)-200 scale_x(2)],'LineWidth',2,'Color','k')
scale_x=ylim
line([-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')
ylim([0.5 650])
 axis off
 colorbar('southoutside')

nexttile
temp_mean=permute(nanmean(psth_all(response_all2{curr_state}==2,:,curr_state),1),[2,1,3]);
temp_error=permute(nanstd(psth_all(response_all2{curr_state}==2,:,curr_state),0,1)./sqrt(size(psth_all(response_all2{1}==2,:,1),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error',colors{curr_state})
axis off

hold on
temp_mean=permute(nanmean(psth_all(response_all2{curr_state}==1,:,curr_state),1),[2,1,3]);
temp_error=permute(nanstd(psth_all(response_all2{curr_state}==1,:,curr_state),0,1)./sqrt(size(psth_all(response_all2{curr_state}==1,:,curr_state),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error',colors{curr_state},0.5,0.1)


ylim([-1 2])
xlim([-0.2 1])
line([-0.2 0],[-1 -1],'LineWidth',2,'Color','k')
line([-0.2 -0.2],[-1 -0.5],'LineWidth',2,'Color','k')

axis off
end

%% passive
figure
tiledlayout(2,2,'TileIndexing','columnmajor')
colors={'R','B'}
for curr_state=1:2
nexttile
[a,b]= sort(response_all_passive2{curr_state},'descend');
imagesc(raster_t,[],psth_all_passive_1{curr_state}(b(find(a>0)),:,2))
clim([-3 3])
colormap(ap.colormap('BWR'))
xlim([-0.2 1])
hold on 
scale_x=ylim

line([-0.2 -0.2],[scale_x(2)-100 scale_x(2)],'LineWidth',2,'Color','k')
line([-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')
% axis off


nexttile
temp_mean=permute(nanmean(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==2,:,2),1),[2,1,3]);
temp_error=permute(nanstd(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==2,:,2),0,1)./...
    sqrt(size(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==2,:,2),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error',colors{1})
axis off

hold on
temp_mean=permute(nanmean(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==1,:,2),1),[2,1,3]);
temp_error=permute(nanstd(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==1,:,2),0,1)./...
    sqrt(size(psth_all_passive_1{curr_state}(response_all_passive2{curr_state}==2,:,2),1)),[2,1,3]);
ap.errorfill(raster_t,temp_mean',temp_error',colors{curr_state})
axis off

ylim([-1 2])
xlim([-0.2 1])
line([-0.2 0],[-1 -1],'LineWidth',2,'Color','k')
line([-0.2 -0.2],[-1 -0.5],'LineWidth',2,'Color','k')

axis off
end



%%
colors={'B','R'}
colors_grade=ap.colormap('bwr')

figure('Position',[50 50 200 400])
fig1=tiledlayout(3,2,'TileSpacing','tight')

figure('Position',[50 50 200 400])
fig2=tiledlayout(3,2,'TileSpacing','tight')

for curr_stage=3
    switch curr_stage
        case 1
            response_stim1=response_all_passive2{1}>0&response_all_passive2{2}==0;
            temp_psth=cellfun(@(x)  x(response_stim1,:,2),psth_all_passive_1,'UniformOutput',false);
            temp_A=[response_all_passive2{1}(response_stim1)  max(temp_psth{1}(:,raster_t>0&raster_t<0.2),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(1,:)=arrayfun(@(id) sum(response_all_passive2{1}(response_stim1)==id),1:2,'UniformOutput',true)

        case 2

            response_over=response_all_passive2{1}>0&response_all_passive2{2}>0;
            temp_psth=cellfun(@(x)  x(response_over,:,2),psth_all_passive_1,'UniformOutput',false);
            temp_A=[response_all_passive2{1}(response_over)  max(temp_psth{1}(:,raster_t>0&raster_t<0.2),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(2,:)=arrayfun(@(id) sum(response_all_passive2{1}(response_over)==id),1:2,'UniformOutput',true)

        case 3

            response_stim2=response_all_passive2{1}==0&response_all_passive2{2}>0;
            temp_psth=cellfun(@(x)  x(response_stim2,:,2),psth_all_passive_1,'UniformOutput',false);
            temp_A=[response_all_passive2{2}(response_stim2)  max(temp_psth{1}(:,raster_t>0&raster_t<0.2),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(3,:)=arrayfun(@(id) sum(response_all_passive2{2}(response_stim2)==id),1:2,'UniformOutput',true)
            

    end

temp_mean=cell(2,1);
temp_error=cell(2,1);

for curr_state=1:2
    a1=nexttile(fig1)
    imagesc(raster_t,[],temp_psth{curr_state}(A_sorted,:))
    clim([-2 2])
colormap(a1,ap.colormap(['KW' colors{curr_state}]))
    xlim([-0.2 0.5])
    ylim([0.5 200])
    axis off
    line([0 0],[0 size(temp_psth{curr_state}(A_sorted,:),1)],'color','k')
   line([-0.2 -0.2],[0 response_num(curr_stage,2)],'color','r')
        line([-0.2 -0.2],[response_num(curr_stage,2) sum(response_num(curr_stage,:),2)],'color','k')

    temp_mean{curr_state}=  arrayfun(@(x)    nanmean(temp_psth{curr_state}(temp_A(:,1)==x,:),1),1:2,'UniformOutput',false)
   temp_error{curr_state}= arrayfun(@(x)    std(temp_psth{curr_state}(temp_A(:,1)==1,:),0,1)./sqrt(sum(temp_A(:,1)==x)),1:2,'UniformOutput',false)


end
a2=nexttile(fig2)
hold on
ap.errorfill(raster_t,temp_mean{1}{2},temp_error{1}{2},colors_grade(1,:))
ap.errorfill(raster_t,temp_mean{2}{2},temp_error{2}{2},colors_grade(end,:))
xlim([-0.2 0.5])
ylim([-0.2 1.2])
axis off

a2=nexttile(fig2)
hold on
ap.errorfill(raster_t,temp_mean{1}{1},temp_error{1}{1},colors_grade(1,:))
ap.errorfill(raster_t,temp_mean{2}{1},temp_error{2}{1},colors_grade(end,:))
xlim([-0.2 0.5])
ylim([-0.5 0.9])
axis off

end
scale_x=ylim(a1)
line(a1,[-0.2 -0.2],[scale_x(2)-50 scale_x(2)],'LineWidth',2,'Color','k')
line(a1,[-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')
line(a2,[-0.2 -0.2],[-0.5 0],'LineWidth',2,'Color','k')
line(a2,[-0.2 0],[-0.5 -0.5],'LineWidth',2,'Color','k')

%%
figure
bar(1, sum(response_num,1),'stacked')


%% task 
colors={'B','R'}

figure('Position',[50 50 200 400])
tiledlayout(3,2,'TileSpacing','tight')
for curr_stage=1:3
    switch curr_stage
        case 1

            
            response_stim1=response_all2{1}>0&response_all2{2}==0;
            temp_psth=  psth_all(response_stim1,:,1:2);
            temp_A=[response_all2{1}(response_stim1)  max(temp_psth(:,raster_t>0&raster_t<0.2,1),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(1,:)=arrayfun(@(id) sum(response_all2{1}(response_stim1)==id),1:2,'UniformOutput',true)

        case 2

            response_over=response_all2{1}>0&response_all2{2}>0;
            temp_psth= psth_all(response_over,:,1:2);
            temp_A=[response_all2{1}(response_over)  max(temp_psth(:,raster_t>0&raster_t<0.2,1),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(2,:)=arrayfun(@(id) sum(response_all2{1}(response_over)==id),1:2,'UniformOutput',true)

        case 3

            response_stim2=response_all2{1}==0&response_all2{2}>0;
            temp_psth= psth_all(response_stim2,:,1:2);
            temp_A=[response_all2{2}(response_stim2)  max(temp_psth(:,raster_t>0&raster_t<0.2,2),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(3,:)=arrayfun(@(id) sum(response_all2{2}(response_stim2)==id),1:2,'UniformOutput',true)

    end


for curr_state=1:2
    a1=nexttile
    imagesc(raster_t,[],temp_psth(A_sorted,:,curr_state))
    clim([-2 2])
colormap(a1,ap.colormap(['KW' colors{curr_state}]))
    xlim([-0.2 0.5])
    ylim([0.5 500])
    axis off
    line([0 0],[0 size(temp_psth(A_sorted,:,curr_state),1)],'color','k')

end

end
scale_x=ylim
line([-0.2 -0.2],[scale_x(2)-50 scale_x(2)],'LineWidth',2,'Color','k')
line([-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')


%% iti move


response_all=feval(@(Y)  arrayfun(@(id)    cat(1,Y{id,:})  ,  5:6,'uni',false),...
    feval(@(X)  cat(2,X{:}),  temp_response_all(~cellfun(@(x) isempty(x),temp_response_all ))));

response_all2=cellfun(@(x) 2*(x>0.95)+1*(x<0.05)     ,response_all,'UniformOutput',false);



colors={'B','R'}

figure('Position',[50 50 200 400])
fig1=tiledlayout(3,2,'TileSpacing','tight')

figure('Position',[50 50 200 400])
fig2=tiledlayout(3,2,'TileSpacing','tight')

for curr_stage=3
    switch curr_stage
        case 1


            response_stim1=response_all2{1}>0&response_all2{2}==0;
            temp_psth=  psth_all(response_stim1,:,5:6);
            temp_A=[response_all2{1}(response_stim1)  max(temp_psth(:,raster_t>0&raster_t<0.2,1),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(1,:)=arrayfun(@(id) sum(response_all2{1}(response_stim1)==id),1:2,'UniformOutput',true)

        case 2

            response_over=response_all2{1}>0&response_all2{2}>0;
            temp_psth= psth_all(response_over,:,5:6);
            temp_A=[response_all2{1}(response_over)  max(temp_psth(:,raster_t>0&raster_t<0.2,1),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(2,:)=arrayfun(@(id) sum(response_all2{1}(response_over)==id),1:2,'UniformOutput',true)

        case 3

            response_stim2=response_all2{1}==0&response_all2{2}>0;
            temp_psth= psth_all(response_stim2,:,5:6);
            temp_A=[response_all2{2}(response_stim2)  max(temp_psth(:,raster_t>0&raster_t<0.2,2),[],2)];
            [~, A_sorted] = sortrows(temp_A, [-1 -2]);
            response_num(3,:)=arrayfun(@(id) sum(response_all2{2}(response_stim2)==id),1:2,'UniformOutput',true)

    end

    temp_mean=cell(2,1);
    temp_error=cell(2,1);

    for curr_state=1:2
        a1=nexttile(fig1)
        imagesc(raster_t,[],temp_psth(A_sorted,:,curr_state))
        clim([-2 2])
        colormap(a1,ap.colormap(['KW' colors{curr_state}]))
        xlim([-0.2 0.5])
        ylim([0.5 400])
        axis off
        line([0 0],[0 size(temp_psth(A_sorted,:,curr_state),1)],'color','k')


        line([-0.2 -0.2],[0 response_num(curr_stage,2)],'color','r')
        line([-0.2 -0.2],[response_num(curr_stage,2) sum(response_num(curr_stage,:),2)],'color','k')

        temp_mean{curr_state}=  arrayfun(@(x)    nanmean(temp_psth(temp_A(:,1)==x,:,curr_state),1),1:2,'UniformOutput',false)
        temp_error{curr_state}= arrayfun(@(x)    std(temp_psth(temp_A(:,1)==1,:,curr_state),0,1)./sqrt(sum(temp_A(:,1)==x)),1:2,'UniformOutput',false)

    end

    a2=nexttile(fig2)
    hold on
    ap.errorfill(raster_t,temp_mean{1}{2},temp_error{1}{2},colors_grade(1,:))
    ap.errorfill(raster_t,temp_mean{2}{2},temp_error{2}{2},colors_grade(end,:))
    xlim([-0.2 0.5])
    ylim([-0.2 2])
    axis off

    a2=nexttile(fig2)
    hold on
    ap.errorfill(raster_t,temp_mean{1}{1},temp_error{1}{1},colors_grade(1,:))
    ap.errorfill(raster_t,temp_mean{2}{1},temp_error{2}{1},colors_grade(end,:))
    xlim([-0.2 0.5])
    ylim([-0.5 1.7])
    axis off

end
scale_x=ylim(a1)
line(a1,[-0.2 -0.2],[scale_x(2)-50 scale_x(2)],'LineWidth',2,'Color','k')
line(a1,[-0.2 0],[scale_x(2) scale_x(2)],'LineWidth',2,'Color','k')

line(a2,[-0.2 -0.2],[-0.5 0],'LineWidth',2,'Color','k')
line(a2,[-0.2 0],[-0.5 -0.5],'LineWidth',2,'Color','k')



