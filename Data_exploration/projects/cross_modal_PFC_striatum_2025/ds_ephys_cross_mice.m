clear all
% Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\ephys\';
Path = 'D:\Data process\project_cross_model\ephys\';

% animals={'DS010','AP021','DS011','AP022','DS001','AP018','DS003','DS004','DS000','DS006','DS013'}
% animals={'DS007','DS010','DS011','AP021','AP022'}
% animals={'DS007','DS014','DS015','DS016'}
animals= { 'DS007','DS010','AP021','DS011','AP022','DS001','AP018','DS003',...
    'DS006','DS013',...
    'DS000','DS004','DS014','DS015','DS016'};

anterior_idx={[2 4],  [2 4],    2,    [2 4],  [2 4],  [2 4],    2,     2,     [2 4],  [2 4],  [2 4],  [2 4],  [2 4],  [2 4],  [2 4]};
anterior_learned_idx={[2 4],  [2 4],    2,    [2 4],  [2 4],  [   ],    [],    [],    [   ],  [   ],  [2 4],  [  4],  [2 4],  [2 4],  [2 4]};

anterior_learned_idx_VA={[2 4],  [2 4],    2,    [2 4],  [2 4],  [   ],    [],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};
anterior_learned_idx_VA_nA={[   ],  [   ],   [ ],    [   ],  [   ],  [2 4],    [],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};
anterior_learned_idx_VnA_nA={[   ],  [   ],   [],    [   ],  [   ], [  ],   [2],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};

anterior_learned_idx_all_nA={[   ],  [   ],   [],    [   ],  [   ], [ 2 4 ],   [2],    [],    [   ],  [  4 ],  [   ],  [  2 ],  [   ],  [   ],  [   ]};

% anterior_learned_idx_AV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [ ],    [],    [ 2 4  ],  [ 2  ],  [  ],  [   ],  [ ],  [ ],  [ ]};
 anterior_learned_idx_AV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [  ],  [    ],  [2 4 ],  [    ],  [2 4],  [2 4],  [2 4]};

anterior_learned_idx_AV_nA={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [   ],  [ 4 ],  [  ],  [  2],  [   ],  [   ],  [  ]};
anterior_learned_idx_AnV_nV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [2 4],  [ 2 ],  [  ],  [   ],  [   ],  [   ],  [  ]};

posterior_learned_idx_VA={[ 1 3],  [1 3],  [1 ],    [1 3],  [1 3],  [   ],    [],    [],    [   ],  [   ],  [   ],  [   ],  [   ],  [   ],  [   ]};
posterior_learned_idx_AV={[ ],    [   ],    [],    [ ],    [ ],   [   ],    [],    [],    [   ],  [   ],  [1 3 ],  [  3  ],  [1 3],  [1 3],  [1 3]};

% Set times for PSTH
raster_window = [-0.5,1];
psth_bin_size = 0.001;
t_bins = raster_window(1):psth_bin_size:raster_window(2);
t_centers = conv2(t_bins,[1,1]/2,'valid');

baseline_t_stim = [-0.2,0];
response_t_stim = [0,0.2];
psth_use_t_stim = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

baseline_t_move = [-0.3,-0.1];
response_t_move = [-0.1,0.1];
psth_use_t_move = t_bins >= response_t_stim(1) & t_bins <= response_t_stim(2);

titles={'L','M','R passive','4k','8k passive','12k','R task','8k task','R task move','8k task move','move'};
%% trial by trial
image_color={'G','P'};

cell_type={'tan','msn','fsi'}
for curr_cell_type=1:3
    figure('Position',[50 50 400 800]);
    t= tiledlayout(4,2,"TileSpacing","tight",'Padding','tight'); % 创建一个1行2列的布局
    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);
            % temp_data=load([Path 'single_mouse\' animal '_ephys.mat'])
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);
            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        end

        used_idx=vertcat(temp_single_idx{:});
        used_single_plot=vertcat(temp_single_plot{:});
        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});


        used_single_plot_mean=cellfun(@(x,y,z) cellfun(@(a) nanmean(a(:,:,y.(cell_type{curr_cell_type})& z(:,3)>0  ),3),x,'UniformOutput',false),...
            used_single_plot,used_cell_type,used_response,'UniformOutput',false);


        for curr_task_type=1:2
            a1=nexttile(t,curr_task_type+curr_group*4-4)
            switch curr_task_type
                case {1,3}
                    used_idx_type=cellfun(@(x) x(1),used_idx,'UniformOutput',true);
                    react_window=[0.1 0.2];
                case{2,4}
                    used_idx_type=cellfun(@(x) x(2),used_idx,'UniformOutput',true);
                    react_window=[0.05 0.15];

            end
            used_single_plot_mean_type=cellfun(@(x) x(curr_task_type),used_single_plot_mean,'UniformOutput',true);

            used_idx_all=vertcat(used_idx_type{:});
            [used_idx_v_all_sorted,sort_idx]=sort(used_idx_all);

            used_plot_all_selected_1=vertcat(used_single_plot_mean_type{:});
            temp_psth_baseline = nanmean(used_plot_all_selected_1(:,t_bins<0&t_bins>-0.5),"all");

            used_plot_all_selected_1=smoothdata ((used_plot_all_selected_1-temp_psth_baseline)/(temp_psth_baseline+1),2,'gaussian',50);

            used_plot_all_sort=used_plot_all_selected_1(sort_idx,:);

            % imagesc(t_bins,[],used_plot_all_sort)
            imagesc(t_bins,[],smoothdata(used_plot_all_sort,'gaussian',20))

            [max_val,max_idx]=max(used_plot_all_sort(:,psth_use_t_stim),[],2);

          

        tttmp=diff(used_plot_all_sort,1,2);
        [~,idxx]=    max(tttmp(:,psth_use_t_stim),[],2)

        % [~,idxx]=    max(used_plot_all_sort(:,psth_use_t_stim),[],2)

     idd= find(psth_use_t_stim)


% t_bins(idd(idxx))

            % figure
%   scatter(used_idx_v_all_sorted,1:length(used_idx_v_all_sorted),1,'.','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0])
% set(gca,'YDir','reverse')
% ylim([1 length(used_idx_v_all_sorted)])
% yticks([[1 length(used_idx_v_all_sorted)]])
% xlim([-0.2  0.5])
% ylabel('trials')
% xlabel('reaction time(s)')
% xline(0)
%   yline(find(used_idx_v_all_sorted<react_window(1),1,'last'))

            yline(find(used_idx_v_all_sorted<react_window(2),1,'last'))
            hold on
            scatter(used_idx_v_all_sorted,1:length(used_idx_v_all_sorted),1,'.','MarkerFaceColor',[0.5 0.5 0.5],'MarkerEdgeColor',[0.5 0.5 0.5])
            % scatter(smoothdata(temp_bins(max_idx),'gaussian',20),1:length(used_idx_v_all_sorted),1,'.','MarkerFaceColor',[1 0.5 0.5],'MarkerEdgeColor',[1 0.5 0.5])
            % scatter(temp_bins(max_idx),1:length(used_idx_v_all_sorted),1,'.','MarkerFaceColor',[1 0.5 0.5],'MarkerEdgeColor',[1 0.5 0.5])

            yline(find(used_idx_v_all_sorted<react_window(1),1,'last'))
            yline(find(used_idx_v_all_sorted<react_window(2),1,'last'))
            xline(0,'LineStyle',':')
            colormap(a1,ap.colormap(['W' image_color{curr_group}]));
            clim_value=[0,3];
            clim(clim_value);
            xlim([-0.1 0.5])
            axis off




            nexttile(t,2+curr_task_type+curr_group*4-4)
            % scatter(used_idx_v_all_sorted,t_bins(idd(idxx)),1,'.')
            % xlim([-0.1 0.5])
            % xlabel('reaction time(s)')
            % ylabel('initiate time(s)')
            % 
            
            hold on

            temp_plot1=used_plot_all_sort(used_idx_v_all_sorted < react_window(1),:);
            temp_move_t1=used_idx_v_all_sorted(used_idx_v_all_sorted < react_window(1),:);
            temp_plot1_cut=  cell2mat( arrayfun(@(idx) [nan(1,sum(~(t_bins>temp_move_t1(idx)))) temp_plot1(idx,t_bins> temp_move_t1(idx))  ] ,...
                1:length(temp_move_t1),'UniformOutput',false)');
            ap.errorfill(t_bins,nanmean(temp_plot1_cut,1),std(temp_plot1_cut,0,1)./ sqrt(size(temp_plot1_cut,1)),[0.5 0.5 0.5], 0.5,0.1)

            temp_plot3=used_plot_all_sort(used_idx_v_all_sorted > react_window(2),:);
            temp_move_t3=used_idx_v_all_sorted(used_idx_v_all_sorted>react_window(2),:);
            temp_plot3_cut=  cell2mat( arrayfun(@(idx) [temp_plot3(idx, t_bins< temp_move_t3(idx))  nan(1,sum(~(t_bins< temp_move_t3(idx))))] ,...
                1:length(temp_move_t3),'UniformOutput',false)');
            ap.errorfill(t_bins,nanmean(temp_plot3_cut,1),std(temp_plot3_cut,0,1)./ sqrt(size(temp_plot3_cut,1)),[0.5 0.5 1], 0.5,0.1)

            temp_plot2=used_plot_all_sort(used_idx_v_all_sorted>react_window(1)&...
                used_idx_v_all_sorted<react_window(2),:);
            temp_move_t2=used_idx_v_all_sorted(used_idx_v_all_sorted>react_window(1)&...
                used_idx_v_all_sorted<react_window(2),:);
            temp_plot2_cut=  cell2mat( arrayfun(@(idx) [temp_plot2(idx, t_bins< temp_move_t2(idx))  nan(1,sum(~(t_bins< temp_move_t2(idx))))] ,...
                1:length(temp_move_t2),'UniformOutput',false)');

            ap.errorfill(t_bins,nanmean(temp_plot2_cut,1),std(temp_plot2_cut,0,1)./ sqrt(size(temp_plot2_cut,1)),[1 0.5 0.5], 0.5,0.1)

            ylim([-1 3])
            xlim([-0.1 0.5])
            xline(0,'LineStyle',':')
            if curr_group==2&curr_task_type==2
                legend({'','lucky trials','','late trials','','good trials'},"Box","off",'Location','bestoutside')
            end
            axis off

        end



    end


    saveas(gcf,[Path 'figures\Figure\ephys trial by trial ' (cell_type{curr_cell_type})], 'jpg');
end


%% trial by trial
image_color={'G','P'};
colors={[84 130 53]./255,[112  48 160]./255};
react_window={[0.1 0.2];[0.05 0.15];[0.1 0.2];[0.05 0.15]};
titles_group={'R task','8k task'};
titles_trial_type={'good tirals','lucky& missing trials'}
cell_type={'tan','msn','fsi'}
for curr_cell_type=1
    figure('Position',[50 50 500 300]);
    t= tiledlayout(3,4,"TileSpacing","tight",'Padding','tight'); % 创建一个1行2列的布局
    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        for curr_animal=1:length(used_animals)
            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);
            % temp_data=load([Path 'single_mouse\' animal '_ephys.mat'])
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);
            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        end

        used_idx=vertcat(temp_single_idx{:});
        used_single_plot=vertcat(temp_single_plot{:});
        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});

        for curr_trial_type=1:2
            switch curr_trial_type
                case 1
                    used_single_plot_mean=cellfun(@(raster,trial_idx,type,response) cellfun(@(raster1,trial_idx_1,window)...
                        permute(nanmean(raster1(trial_idx_1<window(2)&trial_idx_1>window(1),:,type.(cell_type{curr_cell_type})&response(:,7)>0.99),1),[3,2,1]),...
                        raster,[trial_idx;trial_idx],react_window,'UniformOutput',false),...
                        used_single_plot,used_idx,used_cell_type,used_response,'UniformOutput',false);

                    % used_cell_type{1}.(cell_type{curr_cell_type})
                case 2
                    used_single_plot_mean=cellfun(@(raster,trial_idx,type,response) cellfun(@(raster1,trial_idx_1,window)...
                        permute(nanmean(raster1(trial_idx_1>window(2)|trial_idx_1<window(1),:,type.(cell_type{curr_cell_type})&response(:,7)>0.99),1),[3,2,1]),...
                        raster,[trial_idx;trial_idx],react_window,'UniformOutput',false),...
                        used_single_plot,used_idx,used_cell_type,used_response,'UniformOutput',false);
            end


            temp_plot=arrayfun(@(id)cellfun(@(x) x{id}, used_single_plot_mean,'UniformOutput',false   )  ,1:4,'UniformOutput',false );
            used_plot_mean=cellfun(@(x) smoothdata (vertcat(x{:}),2,'gaussian',50),temp_plot,'UniformOutput',false );

            [~,max_idx]=max(used_plot_mean{1}(: ,psth_use_t_stim),[],2);
            [~,sort_idx] = sortrows( max_idx,"ascend");


            for curr_task_type=1:2
                a3=nexttile(t,4*curr_group-4+curr_task_type+2*curr_trial_type-2)
                temp_psth=used_plot_mean{curr_task_type}(sort_idx,:);

                temp_psth_baseline = nanmean(temp_psth(:,t_bins<0&t_bins>-0.2),2);
                used_neruons = (temp_psth - temp_psth_baseline)./(temp_psth_baseline +1);

                imagesc(t_bins,[],used_neruons)
                hold on
                % scatter(used_idx_v_all_sorted,1:length(used_idx_v_all_sorted),1,'.k')
                xline(0)
                colormap(a3,ap.colormap(['W' image_color{curr_group}]));

                switch curr_cell_type
                    case 1
                        clim_value=[0,3];
                    case {2,3}
                        clim_value=[0,5];
                end
                clim(clim_value);
                xlim([-0.1 0.5])
                if curr_group==1
                    title({titles_group{curr_task_type} ;titles_trial_type{curr_trial_type}})
                end
                axis off

                nexttile(t,8+curr_task_type+2*curr_trial_type-2)
                hold on

                ap.errorfill(t_bins,nanmean(used_neruons,1),std(used_neruons,0,1,'omitmissing')./sqrt(size(used_neruons,1)) ,colors{curr_group})
                switch curr_cell_type
                    case 1
                        ylim([-1 3])
                    case {2,3}
                        ylim([-1 5])
                end
                xlim([-0.1 0.5])
                xline(0)
                axis off

            end

        end

    end
    drawnow
end


%%  psth of differnt cell types
colors={[84 130 53]./255,[112  48 160]./255,[112  48 160]./255};
image_color={'G','P','G'};
cell_type={'tan','msn','fsi','all'};

% task or passive
 % states=[3 5]
 states=[3 5 7 8]

p_val=0.95;
for curr_cell_type=1:3
    figure('Position',[50 50 200 500]);
    t= tiledlayout(4,2,"TileSpacing","tight",'Padding','tight'); % 创建一个1行2列的布局

    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            case 3
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA_nA(~cellfun(@isempty, anterior_learned_idx_VA_nA','UniformOutput',true));
        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_cell_type=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);
        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

            temp_cell_type{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);

            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);


        end

        used_single_plot=vertcat(temp_single_plot{:});
        used_response_plot=vertcat(temp_response_plot{:});
        used_cell_type=vertcat(temp_cell_type{:});
        used_response=vertcat(temp_response{:});
        used_single_idx=vertcat(temp_single_idx{:});



        % correlation between reaction time and firing latency
        [~,max_id]=cellfun(@(x)  cellfun(@(a) max(a(: ,psth_use_t_stim,:),[],2),x,'UniformOutput',false  ),used_single_plot,'UniformOutput',false);
        max_id= cellfun(@(x) cellfun(@(a) permute(a,[1 3 2]),x,'UniformOutput',false ),max_id,'UniformOutput',false);

 


        switch  curr_cell_type
            case{1,2,3}
                used_filter_plot_1=cellfun(@(x,y,z)  x(y.(cell_type{curr_cell_type}) ,:,:)  ,...
                    used_response_plot,used_cell_type,used_response,'UniformOutput',false);
                used_filter_response_1=cellfun(@(x,y,z)  z(y.(cell_type{curr_cell_type}) ,:)  ,...
                    used_response_plot,used_cell_type,used_response,'UniformOutput',false);
            case 4
                used_filter_plot_1=used_response_plot;
                used_filter_response_1=used_response;
        end

        used_plot_all_selected_1=vertcat(used_filter_plot_1{:});


        response_per_recording= cellfun(@(x)  [length(find(x(:,1)==1 & x(:,2)==0))...
            length(find(x(:,1)==1 & x(:,2)==1))...
            length(find(x(:,1)==0 & x(:,2)==1))...
            length(find(x(:,1)==0 & x(:,2)==0)) ]...
            , cellfun(@(a) a(:,states)>p_val,used_filter_response_1,'UniformOutput',false),...
            'UniformOutput',false)



        [~,max_idx_v]=max(used_plot_all_selected_1(: ,psth_use_t_stim,states(1)),[],2);
        [~,max_idx_a]=max(used_plot_all_selected_1(: ,psth_use_t_stim,states(2)),[],2);

        used_response_all=vertcat(used_filter_response_1{:});
        temp_response= used_response_all(:,states)>p_val;

        data1 = find(temp_response(:,1)==1 & temp_response(:,2)==0);
        data2 = find(temp_response(:,1)==1 & temp_response(:,2)==1);
        data3 = find(temp_response(:,1)==0 & temp_response(:,2)==1);
        data4 = find(temp_response(:,1)==0 & temp_response(:,2)==0);


        [~,sort_idx_1]=sortrows(max_idx_v(data1),"ascend");
        [~,sort_idx_2]=sortrows(max_idx_a(data2) ,"ascend");
        [~,sort_idx_3]=sortrows(max_idx_a(data3),"ascend");

        % temp_idx_all_1=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];
        temp_idx_all=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];

        % temp_idx_all=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3)];
       % temp_idx_all=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];



        % used_idx=used_response_all(sort_idx,:)

        curr_fig=0;
        for curr_sorting=states
            curr_fig=curr_fig+1;
            a1=nexttile(t,2*curr_group-2+ curr_fig)

            imagesc(t_bins,[],used_plot_all_selected_1(temp_idx_all,:,curr_sorting))
            % imagesc(t_bins,[],movmean(used_plot_all(temp_idx_all,:,curr_stim),10,1))
            colormap(a1,ap.colormap(['KW' image_color{curr_group}]));
            % colormap(a1,ap.colormap(['BWR' ]));
            clim_value=[-5,5];
            clim(clim_value);
            xlim([-0.1 0.5])

            yline(length(data1))
            yline(length([data1; data2]))
            yline(length([data1; data2;data3]))
            xline(0)
            axis off


            if curr_group==1
                title(titles{curr_sorting},'FontWeight','normal')
            end


            nexttile(t,4+curr_fig)
            hold on

     
            temp_mean= nanmean(used_plot_all_selected_1(temp_idx_all_1,:,curr_sorting),1);
            temp_error=std(used_plot_all_selected_1(temp_idx_all_1,:,curr_sorting),0,1,'omitmissing')./sqrt(size(used_plot_all_selected_1(temp_idx_all_1,:,curr_sorting),1));
            ap.errorfill(t_bins,temp_mean,temp_error,colors{curr_group},0.5,0.1);
            ylim([-0.5 1.5])
            xlim([-0.1 0.5])
            xline(0)
            axis off
        end

        temp_group{curr_group}=response_per_recording;
    end
    nexttile(t,7)
   temp_all= cell2mat(cellfun(@(x) sum(cat(3,x{:}),3) ,temp_group,'UniformOutput',false)')
    h=bar(temp_all(:,1:4),'stacked')
    set(gca, 'XTick', 1:2, 'XTickLabel', {'VA', 'AV'},'Box','off');
    ylabel('numbers')
  
    % 设置颜色，每一列一个颜色（即堆叠部分）
colors11 = [ ...
    0.4 0.4 1;   % 蓝色
    1 0.4 1;   % 红色
    1 0.4 0.4;
    0.5 0.5 0.5];  % 绿色

for i = 1:length(h)
    h(i).FaceColor = colors11(i, :);
end

temp_mean0= cellfun(@(x) cellfun(@(a) a/sum(a),x,'UniformOutput',false) ,temp_group,'UniformOutput',false)

temp_mean1=cell2mat(cellfun(@(x) nanmean(cat(3,x{:}),3),temp_mean0,'UniformOutput',false)')
temp_error1=cell2mat(cellfun(@(x)  std(cat(3,x{:}),0,3,'omitmissing')./sqrt(length(x)),temp_mean0,'UniformOutput',false)')
nexttile(t,8)

h1=bar(1:3,temp_mean1(:,1:3),'group')
for i = 1:length(h1)
    h1(i).FaceColor = colors{i};
end
hold on
% 获取分组数和每组的柱数
[nbars,ngroups] = size(temp_mean1(:,1:3));
groupwidth = min(0.8, nbars/(nbars + 1.5));  % 控制每组的宽度

% 添加误差条
for i = 1:nbars
    % 每组柱子的 x 位置计算
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, temp_mean1(i,1:3), temp_error1(i,1:3), ...
        'k', 'linestyle', 'none', 'LineWidth', 1.2, 'CapSize', 2);
end

% 设置标签
set(gca, 'XTick', 1:ngroups, 'XTickLabel', {'only V', 'V&A','only A'},'Box','off');
ylabel('proportion');

% temp_o=cellfun(@(x) cat(1,x{:}),temp_mean0,'UniformOutput',false);
% for curr_i=1:3
%     % p=ranksum( temp_o{1}(:,curr_i) ,temp_o{2}(:,curr_i));
% p=ds.shuffle_test_non_pair( temp_o{1}(:,curr_i) ,temp_o{2}(:,curr_i));
%     y_sig = max([temp_o{1}(:,curr_i) ;temp_o{2}(:,curr_i)],[],'all') + 0.01;
%     if p < 0.05
%         stars = repmat('*',1,sum(p<[0.05 0.01 0.001]));
%         plot([(curr_i-0.1) (curr_i+0.1)], [1 1]*y_sig, 'k-');
%         text(curr_i, y_sig+0.01, stars, 'HorizontalAlignment','center');
%     end
% end



drawnow
% saveas(gcf,[Path 'figures\Figure\ephys cell ' types{curr_cell_type} ' ' titles{used_stim} ], 'jpg');

end



%%
%%  psth of differnt cell types in task and passive conditions
colors={[84 130 53]./255,[112  48 160]./255,[112  48 160]./255};
image_color={'G','P','G'};
cell_type={'tan','msn','fsi','all'};

% task or passive
 % states=[3 5]
 states=[7 3  8 5  ]

p_val=0.95;
for curr_cell_type=1:3
    figure('Position',[50 50 200 500]);
    t= tiledlayout(2,4,"TileSpacing","tight",'Padding','tight'); % 创建一个1行2列的布局


    used_animals=animals(~cellfun(@isempty, anterior_learned_idx','UniformOutput',true));
    used_animals_idx=anterior_learned_idx(~cellfun(@isempty, anterior_learned_idx','UniformOutput',true));


    temp_single_idx=cell(length(used_animals),1);
    temp_single_plot=cell(length(used_animals),1);
    temp_cell_type=cell(length(used_animals),1);
    temp_response=cell(length(used_animals),1);
    temp_response_plot=cell(length(used_animals),1);
    %
    for curr_animal=1:length(used_animals)

        animal=used_animals{curr_animal};
        temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

        temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
        temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

        temp_cell_type{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);

        temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);


    end

    used_single_plot=vertcat(temp_single_plot{:});
    used_response_plot=vertcat(temp_response_plot{:});
    used_cell_type=vertcat(temp_cell_type{:});
    used_response=vertcat(temp_response{:});
    used_single_idx=vertcat(temp_single_idx{:});

    % correlation between reaction time and firing latency
    [~,max_id]=cellfun(@(x)  cellfun(@(a) max(a(: ,psth_use_t_stim,:),[],2),x,'UniformOutput',false  ),used_single_plot,'UniformOutput',false);
    max_id= cellfun(@(x) cellfun(@(a) permute(a,[1 3 2]),x,'UniformOutput',false ),max_id,'UniformOutput',false);


    switch  curr_cell_type
        case{1,2,3}
            used_filter_plot_1=cellfun(@(x,y,z)  x(y.(cell_type{curr_cell_type}) ,:,:)  ,...
                used_response_plot,used_cell_type,used_response,'UniformOutput',false);
            used_filter_response_1=cellfun(@(x,y,z)  z(y.(cell_type{curr_cell_type}) ,:)  ,...
                used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        case 4
            used_filter_plot_1=used_response_plot;
            used_filter_response_1=used_response;
    end

    used_plot_all_selected_1=vertcat(used_filter_plot_1{:});



        [~,max_idx_v]=max(used_plot_all_selected_1(: ,psth_use_t_stim,states(1)),[],2);
        [~,max_idx_a]=max(used_plot_all_selected_1(: ,psth_use_t_stim,states(3)),[],2);

        used_response_all=vertcat(used_filter_response_1{:});
        temp_response= used_response_all(:,states)>p_val;

        data1 = find(temp_response(:,1)==1 & temp_response(:,2)==0);
        data2 = find(temp_response(:,1)==1 & temp_response(:,2)==1);
        data3 = find(temp_response(:,1)==0 & temp_response(:,2)==1);
        data4 = find(temp_response(:,1)==0 & temp_response(:,2)==0);


        [~,sort_idx_1]=sortrows(max_idx_v(data1),"ascend");
        [~,sort_idx_2]=sortrows(max_idx_a(data2) ,"ascend");
        [~,sort_idx_3]=sortrows(max_idx_a(data3),"ascend");

        % temp_idx_all_1=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];
        temp_idx_all=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];



    for curr_state=states
        nexttile
        imagesc(t_bins,[],used_plot_all_selected_1(temp_idx_all,:,curr_state))
        colormap(ap.colormap(['KWR' ]));
        clim_value=[-5,5];
        clim(clim_value);
        xlim([-0.1 0.5])
        hold on

            yline(length(data1))
            yline(length([data1; data2]))
            yline(length([data1; data2;data3]))
        xline(0)
        axis off
    end

      for curr_state=states
        plot_mean=feval(@(a)   nanmean(cat(3,a{:}),3), cellfun(@(x) permute(nanmean(x,1),[2,3,1]),  used_filter_plot_1,'UniformOutput',false));
        plot_error=feval(@(a)   std(cat(3,a{:}),0,3)./ sqrt(length(a)) , cellfun(@(x) permute(nanmean(x,1),[2,3,1]),  used_filter_plot_1,'UniformOutput',false));

        nexttile
        ap.errorfill(t_bins,plot_mean(:,curr_state),plot_error(:,curr_state))
        ylim([-0.5 2])
        xlim([-0.1 0.5])

      end


drawnow

end



%%  visual task resposive neurons across different reaction time
colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
cell_type={'tan','msn','fsi'};

react_windows={[0.1 0.2];[0.05 0.15];[0.1 0.2];[0.05 0.15]};
p_val=0.95;

edges = [-inf,0:0.3:0.3,inf];

for iii=1:length(edges)-1
    for curr_cell_type=2
        figure('Position',[50 50 1400 900]);
        t= tiledlayout(3,6,"TileSpacing","tight",'Padding','tight'); % 创建一个1行2列的布局

        for curr_group=1:2
            switch curr_group
                case 1
                    used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                    used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                case 2
                    used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                    used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            end

            temp_single_idx=cell(length(used_animals),1);
            temp_single_plot=cell(length(used_animals),1);
            temp_probe_position=cell(length(used_animals),1);
            temp_response=cell(length(used_animals),1);
            temp_response_plot=cell(length(used_animals),1);
            %
            for curr_animal=1:length(used_animals)

                animal=used_animals{curr_animal};
                temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

                temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
                temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

                temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
                temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
                temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);


            end

            used_response_plot=vertcat(temp_response_plot{:});
            used_cell_type=vertcat(temp_probe_position{:});
            used_response=vertcat(temp_response{:});

            % trial by trial
            used_single_plot=vertcat(temp_single_plot{:});
            used_single_idx=vertcat(temp_single_idx{:});

            used_plot_bin=cell(length(used_single_idx),1);

            for curr_ii=1:length(used_single_idx)
                for jj=1:2
                    data=used_single_idx{curr_ii}{jj};
                    bin_idx = discretize(data, edges);

                    [unique_bin, ~, bin_idx_fix] = unique(bin_idx);

                    used_plot_bin{curr_ii}{jj}=nan([length(edges)-1,size(used_single_plot{curr_ii}{jj},[2 3] )]);
                    used_plot_bin{curr_ii}{jj}(unique_bin,:,:)=  splitapply(@(x) nanmean(x,1) ,used_single_plot{curr_ii}{jj} ,bin_idx_fix );
                end
            end

            used_filter_plot_bin=cellfun(@(x,y) cellfun(@(a) a(:,:,y.(cell_type{curr_cell_type}) ),x,'UniformOutput',false)  ,...
                used_plot_bin,used_cell_type,'UniformOutput',false);
            used_plot_all_temp=vertcat(used_filter_plot_bin{:});
            used_plot_all_bin=arrayfun(@(id) cat(3,used_plot_all_temp{:,id}),  1:2,'UniformOutput',false );
            used_plot_all_bin_norm_smooth=cellfun(@(x) smoothdata ((x-nanmean(x(:,t_bins<0&t_bins>-0.5,:),"all"))...
                ./(nanmean(x(:,t_bins<0&t_bins>-0.5,:),"all")+1),2,'gaussian',50) ,used_plot_all_bin,'UniformOutput',false   )


            used_filter_plot_1=cellfun(@(x,y,z)  x(y.(cell_type{curr_cell_type}) ,:,:)  ,...
                used_response_plot,used_cell_type,used_response,'UniformOutput',false);
            used_filter_response_1=cellfun(@(x,y,z)  z(y.(cell_type{curr_cell_type}) ,:)  ,...
                used_response_plot,used_cell_type,used_response,'UniformOutput',false);

            used_plot_all_selected_1=vertcat(used_filter_plot_1{:});

            % correlation between reaction time and firing latency
            [~,max_id]=cellfun(@(x)  cellfun(@(a) max(a(: ,psth_use_t_stim,:),[],2),x,'UniformOutput',false  ),used_single_plot,'UniformOutput',false);
            max_id= cellfun(@(x) cellfun(@(a) permute(a,[1 3 2]),x,'UniformOutput',false ),max_id,'UniformOutput',false);

            [tem_r,tem_p]=cellfun(@(x,y) cellfun(@(a,b)  corr(a, b, 'type', 'Spearman') ,  x,[y;y],'UniformOutput',false),...
                max_id,used_single_idx,'UniformOutput',false );

            used_filter_r_v=cellfun(@(x,y,z)  x{1}(y.(cell_type{curr_cell_type})),tem_r,used_cell_type ,used_response,'UniformOutput',false);
            used_filter_r_a=cellfun(@(x,y,z)  x{2}(y.(cell_type{curr_cell_type})),tem_r,used_cell_type ,used_response,'UniformOutput',false);
            used_filter_r_v_all=vertcat(used_filter_r_v{:});
            used_filter_r_a_all=vertcat(used_filter_r_a{:});

            used_filter_p_v=cellfun(@(x,y,z)  x{1}(y.(cell_type{curr_cell_type})),tem_p,used_cell_type ,used_response,'UniformOutput',false);
            used_filter_p_a=cellfun(@(x,y,z)  x{2}(y.(cell_type{curr_cell_type})),tem_p,used_cell_type ,used_response,'UniformOutput',false);
            used_filter_p_v_all=vertcat(used_filter_p_v{:});
            used_filter_p_a_all=vertcat(used_filter_p_a{:});



            [~,max_idx_v]=max(used_plot_all_selected_1(: ,psth_use_t_stim,3),[],2);
            [~,max_idx_a]=max(used_plot_all_selected_1(: ,psth_use_t_stim,5),[],2);

            used_response_all=vertcat(used_filter_response_1{:});
            temp_response= used_response_all(:,[3 5 7 8])>p_val;

            data1 = find(temp_response(:,3)==1 & temp_response(:,4)==0);
            data2 = find(temp_response(:,3)==1 & temp_response(:,4)==1);
            data3 = find(temp_response(:,3)==0 & temp_response(:,4)==1);
            data4 = find(temp_response(:,3)==0 & temp_response(:,4)==0);



            [~,sort_idx_1]=sortrows(max_idx_v(data1),"ascend");
            [~,sort_idx_2]=sortrows(max_idx_a(data2) ,"ascend");
            [~,sort_idx_3]=sortrows( max_idx_a(data3),"ascend");

            temp_idx_all=[data1(sort_idx_1);data2(sort_idx_2);data3(sort_idx_3);data4];


            % ap.imscroll(permute(used_plot_all_bin_norm_smooth{1}(:,:,temp_idx_all),[3 2 1]))
            %
            % colormap(ap.colormap(['W' image_color{curr_stim}]));
            % clim_value=[0,5];
            % clim(clim_value);
            %

            curr_fig=0;
            for curr_sorting=[7 3 8 5]
                curr_fig=curr_fig+1;
                a1=nexttile(t,6*curr_group-6+ curr_fig)

                switch curr_sorting
                    case 7
                        temp_data=permute(used_plot_all_bin_norm_smooth{1}(:,:,temp_idx_all),[3 2 1]);
                        imagesc(t_bins,[],movmean(temp_data(:,:,iii),10,1))
                        % imagesc(t_bins,[],temp_data(:,:,iii))

                    case 8
                        temp_data=permute(used_plot_all_bin_norm_smooth{2}(:,:,temp_idx_all),[3 2 1]);
                        imagesc(t_bins,[],movmean(temp_data(:,:,iii),10,1))
                        % imagesc(t_bins,[],temp_data(:,:,iii))

                    case {3,5}
                        % imagesc(t_bins,[],used_plot_all(temp_idx_all,:,curr_stim))
                        imagesc(t_bins,[],movmean(used_plot_all_selected_1(temp_idx_all,:,curr_sorting),10,1))

                end

                colormap(a1,ap.colormap(['W' image_color{curr_group}]));
                clim_value=[0,5];
                clim(clim_value);
                xlim([0 0.2])

                yline(length(data1))
                yline(length([data1; data2]))
                yline(length([data1; data2;data3]))
                xline(0.1)
                axis off

                switch curr_sorting
                    case{3,5}
                        hold on
                        plot(-0.05*ones(sum(used_response_all(temp_idx_all,curr_sorting)>p_val),1), ...
                            find(used_response_all(temp_idx_all,curr_sorting)>p_val),'.r')
                end

                if curr_group==1
                    title(titles{curr_sorting},'FontWeight','normal')
                end

                nexttile(t,12+curr_fig)
                hold on
                temp_mean=nanmean(used_plot_all_selected_1(:,:,curr_sorting),1);
                temp_error=std(used_plot_all_selected_1(:,:,curr_sorting),0,1,'omitmissing')./sqrt(size(used_plot_all_selected_1(:,:,curr_sorting),1));
                ap.errorfill(t_bins,temp_mean,temp_error,colors{curr_group},0.5,0.1)

                switch curr_cell_type
                    case 1
                        ylim([-1 2])
                    case {2,3}
                        ylim([-1 3])
                end
                xlim([-0.1 0.5])
                axis off

            end


            a1=nexttile(t,6*curr_group-6+ 5)
            hold on
            barh(used_filter_r_v_all(temp_idx_all))
            plot( 0.5*ones(sum(used_filter_p_v_all(temp_idx_all)<0.05),1),find(used_filter_p_v_all(temp_idx_all)<0.05),'.r')
            xline(0.3)
            set(gca, 'YDir', 'reverse');

            a1=nexttile(t,6*curr_group-6+ 6)
            hold on
            barh(used_filter_r_a_all(temp_idx_all))
            plot( 0.5*ones(sum(used_filter_p_a_all(temp_idx_all)<0.05),1),find(used_filter_p_a_all(temp_idx_all)<0.05),'.r')
            xline(0.3)
            set(gca, 'YDir', 'reverse');




        end
        drawnow
        % saveas(gcf,[Path 'figures\Figure\ephys cell ' types{curr_cell_type} ' ' titles{used_stim} ], 'jpg');

    end
    ax = findall(t, 'Type', 'axes');
    linkaxes(ax([10 12 14 16]), 'xy');  % 也可以改成 'xy' 同时联动 x 和 y
    linkaxes(ax([7 8 10 12 14 16]), 'y');  % 也可以改成 'xy' 同时联动 x 和 y
    linkaxes(ax([3 4 5 6 ]), 'xy');  % 也可以改成 'xy' 同时联动 x 和 y
    linkaxes(ax([1 2 3 4 5 6 ]), 'y');  % 也可以改成 'xy' 同时联动 x 和 y


end
%%  visual task resposive neurons across different reaction time
colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
cell_type={'tan','msn','fsi'};

p_val=0.95;

edges = [-inf,0:0.15:0.15,inf];

for curr_stim=1:2
    switch curr_stim
        case 1
            passive_idx=3;
            task_idx=7;
            single_idx=1;
        case 2
            passive_idx=5;
            task_idx=8;
            single_idx=2;

    end
    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);
        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);


        end

        used_response_plot=vertcat(temp_response_plot{:});
        used_response=vertcat(temp_response{:});
      
        task_plot_each_group= cellfun(@(plot,resp) plot(resp(:,task_idx)>p_val,:,task_idx) ,used_response_plot,used_response,'UniformOutput',false )
        task_plot_all=vertcat(task_plot_each_group{:});

        passive_plot_each_group= cellfun(@(plot,resp) plot(resp(:,task_idx)>p_val,:,passive_idx) ,used_response_plot,used_response,'UniformOutput',false )
        passive_plot_all=vertcat(   passive_plot_each_group{:});

        [~,max_idx]=max(task_plot_all(: ,psth_use_t_stim),[],2);
        [~,sort_idx] = sortrows( max_idx,"ascend");

        figure;
        nexttile
        imagesc(t_bins,[],task_plot_all(sort_idx,:))
        colormap(ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);
        xlim([-0.1 0.5])
        nexttile
        imagesc(t_bins,[],passive_plot_all(sort_idx,:))
        colormap(ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);
        xlim([-0.1 0.5])


        % trial by trial
        used_single_plot=vertcat(temp_single_plot{:});
        select_single_plot=cellfun(@(x,resp)  x{single_idx}(:,:,resp(:,task_idx)>p_val) ,used_single_plot,used_response,'UniformOutput',false);

        % feval(@(C) cat(5, C{:}), cellfun(@(x) cat(4, x{:}), data_all, 'UniformOutput', false));
        used_single_idx=vertcat(temp_single_idx{:});
        select_single_idx=   cellfun(@(x)  x{single_idx} ,used_single_idx,'UniformOutput',false);


        used_plot_bin=cell(length(select_single_idx),1);
        for curr_ii=1:length(select_single_idx)
            bin_idx = discretize(select_single_idx{curr_ii}, edges);
            [unique_bin, ~, bin_idx_fix] = unique(bin_idx);
            used_plot_bin{curr_ii}=nan([length(edges)-1,size(select_single_plot{curr_ii},[2 3] )]);
            used_plot_bin{curr_ii}(unique_bin,:,:)=  splitapply(@(x) nanmean(x,1) ,select_single_plot{curr_ii} ,bin_idx_fix );
        end


        used_plot_all_bin= permute(cat(3,used_plot_bin{:}),[3,2,1]);
        used_plot_all_bin_norm_smooth= smoothdata ((used_plot_all_bin-nanmean(used_plot_all_bin(:,t_bins<0&t_bins>-0.5,:),"all"))...
            ./(nanmean(used_plot_all_bin(:,t_bins<0&t_bins>-0.5,:),"all")+1),2,'gaussian',50);

        ap.imscroll(used_plot_all_bin_norm_smooth(sort_idx,:,:))
        colormap(ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);



% %
% figure;
% temp_plot_single=select_single_plot{1};
% temp_idx=select_single_idx{1};
% 
% [~,temp1]=max(temp_plot_single(temp_idx>0.05&temp_idx<0.15,psth_use_t_stim,:),[],2)
% [~,temp2]=max(temp_plot_single(temp_idx>0.15&temp_idx<0.25,psth_use_t_stim,:),[],2)
% 
% p=ds.image_diff(permute(temp1,[3,2,1]),permute(temp2,[3,2,1]),0,1)
% 
% 
% temp_plot1=permute(nanmean(temp_plot_single(temp_idx>0.05&temp_idx<0.15,:,(p'>0.95)),1),[3,2,1]);
% temp_plot1_norm=smoothdata (temp_plot1-nanmean(temp_plot1(:,t_bins<0&t_bins>-0.5),'all')./...
%     (nanmean(temp_plot1(:,t_bins<0&t_bins>-0.5),'all')+1),2,'gaussian',50);
% temp_plot2=permute(nanmean(temp_plot_single(temp_idx>0.15&temp_idx<0.25,:,(p'>0.95)),1),[3,2,1]);
% temp_plot2_norm=smoothdata (temp_plot2-nanmean(temp_plot2(:,t_bins<0&t_bins>-0.5),'all')./...
%     (nanmean(temp_plot2(:,t_bins<0&t_bins>-0.5),'all')+1),2,'gaussian',50);
% 
% figure;
% nexttile
% imagesc(temp_plot1_norm);
% colormap(ap.colormap('WK'))
% nexttile
% imagesc(temp_plot2_norm);
% 
% ap.imscroll (cat(3,temp_plot1_norm,temp_plot2_norm))
% colormap(ap.colormap('WK'))
% 
% figure;
% temp_plot=permute(nanmean(select_single_plot{1}(:,:, (p'>0.95)),1),[3,2,1])


    end
end
   



%%  psth of all cells in passive

colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
p_val=0.95;
% % max_num=500;
sorting_stim=[3 5];
plot_stim=[3 5];
figure('Position',[50 50 400 300]);

for curr_stim=1:2

    curr_sorting=sorting_stim(curr_stim);
    curr_plot=plot_stim(curr_stim);
    switch curr_sorting
        case {3,5}
            max_num=750;
            yscale=[-0.1 1.2];
            bar_scale=[0 0.5];
            clim_value=[0,5];

        case{7,8}
            max_num=1800;
            yscale=[-0.1 2.5];
            bar_scale=[0 1];
            clim_value=[0,5];
    end

    proportion_response=cell(2,1);
    proportion_response_overlay=cell(2,1);

    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));

        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);
        temp_response_plot_2=cell(length(used_animals),1);

        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);
            temp_response_plot_2{curr_animal}=temp_file_name.all_event_response_signle_neuron_h2(used_animals_idx{curr_animal},1);


        end

        % used_single_plot=vertcat(temp_single_plot{:});
        % used_single_idx=vertcat(temp_idx{:});

        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});


        used_response_plot=vertcat(temp_response_plot{:});
        used_filter_plot_1=cellfun(@(x,y,z)  x(z(:,curr_sorting)>p_val ,:,curr_plot)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_filter_response_1=cellfun(@(x,y,z)  z(z(:,curr_sorting)>p_val ,:)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_selected_1=vertcat(used_filter_plot_1{:});


        used_response_plot_2=vertcat(temp_response_plot_2{:});
        used_filter_plot_2=cellfun(@(x,y,z)  x(z(:,curr_sorting)>p_val ,:,curr_plot)  ,...
            used_response_plot_2,used_cell_type,used_response,'UniformOutput',false);
        used_filter_response_2=cellfun(@(x,y,z)  z(z(:,curr_sorting)>p_val ,:)  ,...
            used_response_plot_2,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_selected_2=vertcat(used_filter_plot_2{:});



        used_filter_plot_all=cellfun(@(x,y,z)  x(: ,:,curr_plot)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all=vertcat(used_filter_plot_all{:});


      
        proportion_response{curr_group}= cellfun(@(x) size(x,1) , used_filter_plot_1,'UniformOutput',true)./...
            cellfun(@(x) size(x,1) , used_filter_plot_all,'UniformOutput',true);

        [~,max_idx]=max(used_plot_all_selected_1(: ,psth_use_t_stim),[],2);
        [~,sort_idx] = sortrows( max_idx,"ascend");


        % ax=subplot(6,2,[4*curr_group+curr_stim-4 ,4*curr_group+curr_stim-2])
        ax=subplot(4,3,[curr_group+6*curr_stim-6 ,curr_group+6*curr_stim-3])

        % imagesc(t_bins,[],smoothdata(used_plot_all_selected(sort_idx,:),1,'gaussian',20))
        imagesc(t_bins,[],used_plot_all_selected_1(sort_idx,:))

        % colorbar('southoutside')
        colormap(ax,ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);
        xlim([-0.1 0.5])
        xline(0,'LineStyle',':')
        currentAx = gca; % 获取当前轴
        subplotPosition = currentAx.Position; % 获取位置和大小
        maxh=subplotPosition(4);
        maxb=subplotPosition(2);

        subplotPosition(4)=maxh/max_num*size(used_plot_all_selected_1,1);
        subplotPosition(2)=maxb+maxh-maxh/max_num*size(used_plot_all_selected_1,1);
        ax.Position=subplotPosition;
        axis off

        ax=subplot(4,3,6*curr_stim-6+3)
        hold on
        temp_plot=cell2mat(cellfun(@(x) nanmean(x,1)    ,used_filter_plot_all,'UniformOutput',false));
        temp_mean=nanmean(temp_plot,1);
        temp_error=std(temp_plot,0,1,'omitmissing')./sqrt(size(temp_plot,1));
        ap.errorfill(t_bins,temp_mean,temp_error,colors{curr_group},0.5,0.1)

        ylim(yscale)
        xlim([-0.1 0.5])
        xline(0,'LineStyle',':')

        axis off

    end

 
    means = [nanmean(proportion_response{1}, 1);nanmean(proportion_response{2}, 1)]';
    sems = [std(proportion_response{1}, 0, 1,'omitmissing') ./ sqrt(size(proportion_response{1},1));...
        std(proportion_response{2}, 0, 1,'omitmissing') ./ sqrt(size(proportion_response{2},1))]';
    p =  ranksum(proportion_response{1}, proportion_response{2})

        ax=subplot(4,3,6*curr_stim)
    ax.Color = 'none';    % 设置背景透明

    hold on
    bar_handle = bar(1:2,means, 'grouped');
    bar_handle.FaceColor = 'none';  % 允许每个柱子单独设色
    bar_handle.EdgeColor = 'flat';  % 允许每个柱子单独设色
    bar_handle.CData(1,:) = colors{1} ;  % 第一个柱子的颜色（RGB）
    bar_handle.CData(2,:) = colors{2} ;  % 第二个柱子的颜色（RGB）

    errorbar(1:2, means, sems, 'k.', 'LineWidth', 1);

    % 添加散点
    arrayfun(@(g) scatter(g*ones(length(proportion_response{g}),1) + randn(size(proportion_response{g},1),1)*0.05,...
        proportion_response{g}, ...
        20, 'filled', ...
        'MarkerFaceColor', colors{g}), 1:2);
    if p < 0.05
        stars = repmat('*',1,sum(p<[0.05 0.01 0.001]));
        y_sig = max(vertcat(proportion_response{:})) + 0.05;
        plot(1:2, [1 1]*y_sig, 'k-');
        text(1.5, y_sig+0.02, stars, 'HorizontalAlignment','center');
    end
    xticklabels({})
    ylabel('fraction','FontWeight','normal')
    ylim(bar_scale)
    box off
    drawnow
    saveas(gcf,[Path 'figures\Figure\ephys cell '  titles{curr_sorting} ], 'jpg');
end


%%  psth of all cells in task

colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
p_val=0.95;
% % max_num=500;
sorting_stim=[3 5];
plot_stim=[7 8];
figure('Position',[50 50 200 400]);

for curr_stim=1:2

    curr_sorting=sorting_stim(curr_stim);
    curr_plot=plot_stim(curr_stim);
    switch curr_sorting
        case {3,5}
            max_num=750;
            yscale=[-0.1 1.2];
            bar_scale=[0 0.5];
            clim_value=[0,5];

        case{7,8}
            max_num=1800;
            yscale=[-0.1 2.5];
            bar_scale=[0 1];
            clim_value=[0,5];
    end

    proportion_response=cell(2,1);
    proportion_response_overlay=cell(2,1);

    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));

        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);
        temp_response_plot_2=cell(length(used_animals),1);

        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);
            temp_response_plot_2{curr_animal}=temp_file_name.all_event_response_signle_neuron_h2(used_animals_idx{curr_animal},1);


        end

        % used_single_plot=vertcat(temp_single_plot{:});
        % used_single_idx=vertcat(temp_idx{:});

        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});


        used_response_plot=vertcat(temp_response_plot{:});
        used_filter_plot_1=cellfun(@(x,y,z)  x(z(:,curr_sorting)>p_val ,:,curr_plot)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_filter_response_1=cellfun(@(x,y,z)  z(z(:,curr_sorting)>p_val ,:)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_selected_1=vertcat(used_filter_plot_1{:});


        used_response_plot_2=vertcat(temp_response_plot_2{:});
        used_filter_plot_2=cellfun(@(x,y,z)  x(z(:,curr_sorting)>p_val ,:,curr_plot)  ,...
            used_response_plot_2,used_cell_type,used_response,'UniformOutput',false);
        used_filter_response_2=cellfun(@(x,y,z)  z(z(:,curr_sorting)>p_val ,:)  ,...
            used_response_plot_2,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_selected_2=vertcat(used_filter_plot_2{:});



        used_filter_plot_all=cellfun(@(x,y,z)  x(: ,:,curr_plot)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all=vertcat(used_filter_plot_all{:});


      
        proportion_response{curr_group}= cellfun(@(x) size(x,1) , used_filter_plot_1,'UniformOutput',true)./...
            cellfun(@(x) size(x,1) , used_filter_plot_all,'UniformOutput',true);

        [~,max_idx]=max(used_plot_all_selected_1(: ,psth_use_t_stim),[],2);
        [~,sort_idx] = sortrows( max_idx,"ascend");


        ax=subplot(4,2,[curr_group+4*curr_stim-4 ,curr_group+4*curr_stim-2])

        % imagesc(t_bins,[],smoothdata(used_plot_all_selected(sort_idx,:),1,'gaussian',20))
        imagesc(t_bins,[],used_plot_all_selected_1(sort_idx,:))

        % colorbar('southoutside')
        colormap(ax,ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);
        xlim([-0.1 0.5])
        xline(0,'LineStyle',':')
        currentAx = gca; % 获取当前轴
        subplotPosition = currentAx.Position; % 获取位置和大小
        maxh=subplotPosition(4);
        maxb=subplotPosition(2);

        subplotPosition(4)=maxh/max_num*size(used_plot_all_selected_1,1);
        subplotPosition(2)=maxb+maxh-maxh/max_num*size(used_plot_all_selected_1,1);
        ax.Position=subplotPosition;
        axis off

     

    end

end



%%  psth of all cell all cells

colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
p_val=0.95;
% max_num=500;
figure('Position',[50 50 200 400]);
sorting_stim=[7 8];

for curr_stim=1:2
        curr_sorting=sorting_stim(curr_stim);

    switch curr_sorting
        case {3,5}
            max_num=800;
            yscale=[-0.1 1.2];
            bar_scale=[0 0.5];
            clim_value=[0,5];

        case{7,8}
            max_num=1700;
            yscale=[-0.1 2.5];
            bar_scale=[0 1];
            clim_value=[0,5];


    end

    proportion_response=cell(2,1);
    proportion_response_overlay=cell(2,1);

    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
        end

        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);
        temp_response_plot1=cell(length(used_animals),1);
        temp_response_plot2=cell(length(used_animals),1);

        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);
            temp_response_plot1{curr_animal}=temp_file_name.all_event_response_signle_neuron_h1(used_animals_idx{curr_animal},1);
            temp_response_plot2{curr_animal}=temp_file_name.all_event_response_signle_neuron_h2(used_animals_idx{curr_animal},1);


        end

        used_single_plot=vertcat(temp_single_plot{:});
        used_single_idx=vertcat(temp_single_idx{:});

        used_response_plot=vertcat(temp_response_plot{:});
        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});
        used_response_all=vertcat(used_response{:});
        % used_single_idx=vertcat(temp_idx{:});



        used_filter_plot_1=cellfun(@(x,y,z)  x(z(:,curr_sorting)>p_val ,:,curr_sorting)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_filter_response_1=cellfun(@(x,y,z)  z(z(:,curr_sorting)>p_val ,:)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_selected_1=vertcat(used_filter_plot_1{:});


        used_filter_plot_all=cellfun(@(x,y,z)  x(: ,:,curr_sorting)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all=vertcat(used_filter_plot_all{:});


        used_response_plot1=vertcat(temp_response_plot1{:});
        used_filter_plot_all_1=cellfun(@(x,y,z)  x(: ,:,curr_sorting)  ,...
            used_response_plot1,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_1=vertcat(used_filter_plot_all_1{:});

        used_response_plot2=vertcat(temp_response_plot2{:});
        used_filter_plot_all2=cellfun(@(x,y,z)  x(: ,:,curr_sorting)  ,...
            used_response_plot2,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all_2=vertcat(used_filter_plot_all2{:});



        % used_filter_plot_overlay=cellfun(@(x,y,z)  x(z(:,3)>p_val &z(:,5)>p_val,:,curr_stim_now)  ,...
        %     used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        % 
        % proportion_response_overlay{curr_group}= cellfun(@(x) size(x,1) , used_filter_plot_overlay,'UniformOutput',true)./...
        %     cellfun(@(x) size(x,1) , used_filter_plot_1,'UniformOutput',true);



        proportion_response{curr_group}= cellfun(@(x) size(x,1) , used_filter_plot_1,'UniformOutput',true)./...
            cellfun(@(x) size(x,1) , used_filter_plot_all,'UniformOutput',true);



        [~,max_idx]=max(used_plot_all_1(: ,psth_use_t_stim),[],2);
        temp_data=[used_response_all(:,curr_sorting)>p_val max_idx];
        temp1=find(temp_data(:,1)==1)
        temp0=find(temp_data(:,1)==0)
        [~,sort_idx_1]=sortrows(temp_data(temp1, 2));
        idx1_sorted = temp1(sort_idx_1);
        sort_idx=[idx1_sorted; temp0];


        % a1=nexttile(curr_group)
        ax=subplot(5,2,[4*curr_group+curr_stim-4 ,4*curr_group+curr_stim-2])
        imagesc(t_bins,[],used_plot_all(sort_idx,:))
        % imagesc(t_bins,[],smoothdata(used_plot_all(sort_idx,:),1,'gaussian',20))

        % colorbar('southoutside')
        colormap(ax,ap.colormap(['W' image_color{curr_group}]));
        clim(clim_value);
        xlim([-0.1 0.5])
        xline(0,'LineStyle',':')

        axis off

    

    end


    % proportion_response=proportion_response_overlay;
    % bar plot of resposive proportion
    means = [nanmean(proportion_response{1}, 1);nanmean(proportion_response{2}, 1)]';
    sems = [std(proportion_response{1}, 0, 1,'omitmissing') ./ sqrt(size(proportion_response{1},1));...
        std(proportion_response{2}, 0, 1,'omitmissing') ./ sqrt(size(proportion_response{2},1))]';
    p =  ranksum(proportion_response{1}, proportion_response{2})

    ax=subplot(5,2,8+curr_stim);
    ax.Color = 'none';    % 设置背景透明

    hold on
    bar_handle = bar(1:2,means, 'grouped');
    bar_handle.FaceColor = 'none';  % 允许每个柱子单独设色
    bar_handle.EdgeColor = 'flat';  % 允许每个柱子单独设色
    bar_handle.CData(1,:) = colors{1} ;  % 第一个柱子的颜色（RGB）
    bar_handle.CData(2,:) = colors{2} ;  % 第二个柱子的颜色（RGB）

    errorbar(1:2, means, sems, 'k.', 'LineWidth', 1);

    % 添加散点
    arrayfun(@(g) scatter(g*ones(length(proportion_response{g}),1) + randn(size(proportion_response{g},1),1)*0.05,...
        proportion_response{g}, ...
        20, 'filled', ...
        'MarkerFaceColor', colors{g}), 1:2);

    if p < 0.05
        stars = repmat('*',1,sum(p<[0.05 0.01 0.001]));
        y_sig = max(vertcat(proportion_response{:})) + 0.05;
        plot(1:2, [1 1]*y_sig, 'k-');
        text(1.5, y_sig+0.02, stars, 'HorizontalAlignment','center');
    end


    xticklabels({})
    % ylabel('proportion')
    xlabel('proportion','FontWeight','normal')

    ylim(bar_scale)
    box off


    sgtitle(titles{curr_sorting},'FontWeight','normal')
    drawnow
    % saveas(gcf,[Path 'figures\Figure\ephys cell '  titles{curr_stim} ], 'jpg');

end

%% scatter of visual vs auditory 

colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};
p_val=0.95;
% % max_num=500;
sorting_stim=[3 5];




    max_plot_all=cell(2,1);
    response_id_all=cell(2,1);
    response_id_sep=cell(2,1);
for curr_group=1:2
    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));

    end

    for curr_stim=1:2

        curr_sorting=sorting_stim(curr_stim);

        switch curr_sorting
            case {3,5}
                max_num=750;
                yscale=[-0.1 1.2];
                bar_scale=[0 0.5];
                clim_value=[0,5];

            case{7,8}
                max_num=1800;
                yscale=[-0.1 2.5];
                bar_scale=[0 1];
                clim_value=[0,5];
        end



        temp_single_idx=cell(length(used_animals),1);
        temp_single_plot=cell(length(used_animals),1);
        temp_probe_position=cell(length(used_animals),1);
        temp_response=cell(length(used_animals),1);
        temp_response_plot=cell(length(used_animals),1);

        %
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

            temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
            temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

            temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
            temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
            temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);

        end
            used_response_plot=vertcat(temp_response_plot{:});


        used_cell_type=vertcat(temp_probe_position{:});
        used_response=vertcat(temp_response{:});




        response_id=cellfun(@(x) x(:,curr_sorting)>p_val, used_response,'UniformOutput',false);
        response_id_sep{curr_group}{curr_stim}=response_id;
        response_id_all{curr_group}{curr_stim}=vertcat(response_id{:});

        used_filter_plot_all=cellfun(@(x,y,z)  x(: ,:,curr_sorting)  ,...
            used_response_plot,used_cell_type,used_response,'UniformOutput',false);
        used_plot_all=vertcat(used_filter_plot_all{:});

        max_plot_all{curr_group}{curr_stim}=max(used_plot_all(: ,psth_use_t_stim),[],2);



    end
end


for curr_group=1:2
    index = response_id_all{curr_group}{1}*1 +response_id_all{curr_group}{2}*2;
    % scatter(max_plot_all{1},max_plot_all{2})
    figure;
    used_idx=(index>0&index<3)
    gscatter(max_plot_all{curr_group}{1}(used_idx),max_plot_all{curr_group}{2}(used_idx), index(used_idx), ...
        ['r','b','g'], 'o', 4);  % 颜色和 marker 样式自定义
 
   axis equal
     xlim([-10 40])
     ylim([-10 40])

end


temp_id=cat(2,response_id_sep{1}{:})
temp_id1 = cellfun(@(a, b) [a, b], temp_id(:,1), temp_id(:,2), 'UniformOutput', false);
temp_id2=cellfun(@(x) x(x(:,1)>0|x(:,2)>0,:),temp_id1,'UniformOutput',false   )
temp_id2={cell2mat(temp_id2)}
% temp_id2=temp_id1
figure;

for curr_recording=1
per=sum(sum(temp_id2{curr_recording},2)==2) /sum(temp_id2{curr_recording}(:,1));
n_shuff=1000;
shuff=zeros(n_shuff,1)
for curr_shuf=1:n_shuff
shuff(curr_shuf)= sum(sum(ap.shake(temp_id2{curr_recording},1),2)==2)/sum(temp_id2{curr_recording}(:,1));
end

ranks = tiedrank(vertcat(per,shuff));
p_vals(curr_recording) = ranks( 1) / (n_shuff + 1);
nexttile
histogram(shuff)
 xline(prctile(shuff,95))
  xline(prctile(shuff,5))
xline(per,'r')
end




%% 一维深度  group average
groups={'VA','AV','VA_nA'}
% groups={'VA','VA_nA'}

titles={'L','M','V passive','4k','A passive','12k','V task','A task','iti move'};
p_val=0.95
all_stim=[3 5];
colors={[84 130 53]./255,[112  48 160]./255};
% colors={[0.3 0.3 1],[1 0.3 0.3]};

colors1={[0.1706    0.1275    0.1165],[0.3294    0.5098    0.2078], [0.7451    0.8667    0.6706];...
    [0.2706    0.0353    0.4667],[0.4392    0.1882    0.6275], [0.8196    0.7216    0.9019]};
colors_image={'G','P'}
z_min = 0;
z_max = 250;
bin_size_z = 25; % 单位：μm，根据实际尺度调整

z_edges = [z_min:bin_size_z:z_max,inf];
z_edge_3=[250 375 450 600]

fig2 = figure('Position',[50 50 300 length(all_stim)*150 ]);
tl2 = tiledlayout(length(all_stim),3);

for curr_group=1:2

    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
    end

    temp_single_idx=cell(length(used_animals),1);
    temp_single_plot=cell(length(used_animals),1);
    temp_probe_position=cell(length(used_animals),1);
    temp_response=cell(length(used_animals),1);
    temp_response_plot=cell(length(used_animals),1);
    temp_cell_position=cell(length(used_animals),1);
    for curr_animal=1:length(used_animals)

        animal=used_animals{curr_animal};
        temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

        temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
        temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

        temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
        temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);


        % temp_cell_position{curr_animal}=temp_file_name.all_cell_ccf_position_sorted(used_animals_idx{curr_animal},1);


       temp_cell_position{curr_animal}= cellfun(@(x,y) x-y , temp_file_name.all_cell_ccf_position_sorted(used_animals_idx{curr_animal},1),...
            temp_file_name.striatal_surface_position(used_animals_idx{curr_animal},1),'UniformOutput',false);

    end

  
    single_neuron_each_rec_1=vertcat(temp_response_plot{:});
    single_neuron_all_plot=cat(1,single_neuron_each_rec_1{:});
    response_each_rec=vertcat(temp_response{:});
    response_all=cat(1,response_each_rec{:});
    single_neuron_each_position=vertcat(temp_cell_position{:});
    single_neuron_position_all=cat(1,single_neuron_each_position{:});

    neuron_count_map_all=cell(2,1)
    neuron_count_map=cell(2,1)
    neuron_count_map_overlay=cell(2,1)
    for curr_sorting=1:length(all_stim)



        used_stim=all_stim(curr_sorting);

        neuron_coords_all= cellfun(@(x)   x(:,2) ,single_neuron_each_position,'UniformOutput',false );
        neuron_coords_each= cellfun(@(x,y) x(y(:,used_stim)>p_val,2),single_neuron_each_position,response_each_rec,'UniformOutput',false)


        if used_stim==3|used_stim==5
            temp_single_idx=[3 5]
        else
            temp_single_idx=[7 8]
        end




        firing_rates=cellfun(@(x) x(:,:,used_stim) ,single_neuron_each_rec_1,'UniformOutput',false);

        % === Step 1: 投影到冠状面（y-z） ===
        projected_coords = neuron_coords_each; % 取 y 和 z
        projected_coords_all = neuron_coords_all; % 取 y 和 z


        % 分配每个神经元的 bin 索引
        [neuron_count_map_all{curr_sorting},~,binIdx_all] = cellfun(@(x) histcounts(x, z_edges),projected_coords_all,'UniformOutput',false);
        [neuron_count_map{curr_sorting},~,binIdx]= cellfun(@(x) histcounts(x, z_edges),projected_coords,'UniformOutput',false);



        firing_rates_bins =cellfun(@(x,idx) arrayfun(@(col) ...
            accumarray(idx, x(:,col), [length(z_edges)-1,1], @mean, NaN), ...
            1:size(x,2), 'UniformOutput', false),firing_rates,binIdx_all, 'UniformOutput', false);

        firing_rates_bins1=cellfun(@(x) cat(2,x{:}),firing_rates_bins,'UniformOutput',false);
        firing_rates_bins2=nanmean(cat(3,firing_rates_bins1{:}),3);


        figure(fig2)
        ax2=nexttile(tl2,3*curr_sorting-3+curr_group)
          % ax2=nexttile(tl2,curr_stim_now-3+3*curr_group)

        h2=imagesc(t_bins,z_edges(1:end-1),firing_rates_bins2)
        xlim([-0.1 0.5]);
        xticks([-0.1 0.5]);
        hold on
        xline(0,'LineStyle',':')
        xlabel('time (s)');
        ylim([z_edges(1)-0.5*bin_size_z  z_edges(end-1)+0.5*bin_size_z])

        if used_stim<7
            clim([0 2])
        else
            clim([0 4])
        end
        colormap(ax2,ap.colormap(['W' colors_image{curr_group}]))

        % if curr_stim_now==2
        %     colorbar('southoutside')
        % end

        if curr_group==1
            % title(titles(used_stim),'FontWeight','normal')
            ylabel('depth (\mum)');
            yticks([z_edges(1) z_edges(end-1)]);
        else
            yticks([]);

        end


        % MUA max
        ax1=nexttile(tl2,3*curr_sorting)
         % ax1=nexttile(tl2,3*curr_stim_now)

        firing_rates_max=cellfun(@(x) max(x(:,psth_use_t_stim),[],2),firing_rates_bins1,'UniformOutput',false );
        % firing_rates_max=porportion
        ap.errorfill(z_edges(1:end-1) , smoothdata(nanmean(cat(3,firing_rates_max{:}),3),'gaussian',4),...
            smoothdata( std(cat(3,firing_rates_max{:}),0,3,'omitmissing')./sqrt(size(cat(3,firing_rates_max{:}),3)),'gaussian',4),...
            colors{curr_group},0.1,0.5);

        if used_stim<7
            ylim(ax1,[0 3])
        else
            ylim(ax1,[0 8])
        end
        xlim(ax1,[z_edges(1) z_edges(end-1)])

        % title('activity','FontWeight','normal')
        ylabel('\DeltaFR/FR_0')
        xline(150,'LineStyle',':');
        xline(50,'LineStyle',':')
        xticks([]);
        % set(gca, 'YAxisLocation', 'right')  % 把 x 轴移到上面

        view(ax1,90, 90);


    end


end


%% 一维深度 overlay 分布
groups={'VA','AV'}

titles={'L','M','V passive','4k','A passive','12k','V task','A task','iti move'};
p_val=0.95
all_stim=[ 3 5 ];
 colors={[84 130 53]./255,[112  48 160]./255};

colors1={[0.1706    0.1275    0.1165],[0.3294    0.5098    0.2078], [0.7451    0.8667    0.6706];...
    [0.2706    0.0353    0.4667],[0.4392    0.1882    0.6275], [0.8196    0.7216    0.9019]};

colors_image={'G','P'}
z_min = 0;
z_max = 250;
bin_size_z = 25; % 单位：μm，根据实际尺度调整
z_edges = [z_min:bin_size_z:z_max,inf];

fig2 = figure('Position',[50 50 150 300 ]);
tl2 = tiledlayout(2,1);


for curr_group=1:2

    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
    end

    temp_single_idx=cell(length(used_animals),1);
    temp_single_plot=cell(length(used_animals),1);
    temp_probe_position=cell(length(used_animals),1);
    temp_response=cell(length(used_animals),1);
    temp_response_plot=cell(length(used_animals),1);
    temp_cell_position=cell(length(used_animals),1);
    for curr_animal=1:length(used_animals)

        animal=used_animals{curr_animal};
        temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);

        temp_single_plot{curr_animal}=temp_file_name.plot_single(used_animals_idx{curr_animal},1);
        temp_single_idx{curr_animal}=temp_file_name.plot_idx(used_animals_idx{curr_animal},1);

        temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
        temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        temp_response_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);

       temp_cell_position{curr_animal}= cellfun(@(x,y) x-y , temp_file_name.all_cell_ccf_position_sorted(used_animals_idx{curr_animal},1),...
            temp_file_name.striatal_surface_position(used_animals_idx{curr_animal},1),'UniformOutput',false);

    end

   
    single_neuron_each_rec_1=vertcat(temp_response_plot{:});
    single_neuron_all_plot=cat(1,single_neuron_each_rec_1{:});
    
    response_each_rec=vertcat(temp_response{:});
    response_all=cat(1,response_each_rec{:});

    single_neuron_each_position=vertcat(temp_cell_position{:});
    single_neuron_position_all=cat(1,single_neuron_each_position{:});


    neuron_coords_all= cellfun(@(x)   x(:,2) ,single_neuron_each_position,'UniformOutput',false );

    neuron_coords_each=arrayfun(@(stim) cellfun(@(x,y) x(y(:,stim)>p_val,2),...
        single_neuron_each_position,response_each_rec,'UniformOutput',false),...                              ...
        all_stim,'UniformOutput',false )

    neuron_coords_overlay=cellfun(@(x,y)  x(y(:,all_stim(1))>p_val&y(:,all_stim(2))>p_val,2),....
        single_neuron_each_position,response_each_rec,'UniformOutput',false)                               ...


    [neuron_count_map_all,~,binIdx_all] = cellfun(@(x) histcounts(x, z_edges),neuron_coords_all,'UniformOutput',false);
    [neuron_count_map_v,~,binIdx_v]= cellfun(@(x) histcounts(x, z_edges),neuron_coords_each{1},'UniformOutput',false);
    [neuron_count_map_a,~,binIdx_a]= cellfun(@(x) histcounts(x, z_edges),neuron_coords_each{2},'UniformOutput',false);
    [neuron_count_map_overlay,~,binIdx_overlay]= cellfun(@(x) histcounts(x, z_edges),neuron_coords_overlay,'UniformOutput',false);


 

    idxx=cellfun(@(a,b,c,d)  arrayfun(@(depth)   [ [ones(b(depth),1);zeros(c(depth)-d(depth),1) ]  ...
        [zeros(b(depth)-d(depth),1); ones(c(depth),1) ]],...
        1:11,'UniformOutput',false),...
        neuron_count_map_all, neuron_count_map_v, neuron_count_map_a, neuron_count_map_overlay,'UniformOutput',false )


idx_temp=cellfun(@(x)  cat(1,x{:}),idxx,'UniformOutput',false)

 

     temp_shuff= cellfun(@(x) arrayfun(@(id) ap.shake(x,1),1:n_shuff,'UniformOutput',false),idx_temp,'UniformOutput',false);


temp_real_mean=cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2)),   idx_temp,'UniformOutput',true)


 temp_p=cat(1,temp_shuff{:}) 
temp_p2=arrayfun(@(id)   cat(1,temp_p{:,id})  , 1:size(temp_p,2),'UniformOutput',false)
temp_shuffle= cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2))  , temp_p2,'UniformOutput',true );

prctile(temp_shuffle,95)
prctile(temp_shuffle,5)


% cellfun(@(x) length(x),neuron_coords_all,'UniformOutput',true)


% idxx=cellfun(@(a,b,c,d)  arrayfun(@(depth)   [ [ones(b(depth),1);zeros(c(depth)-d(depth),1) ]  ...
%     [zeros(b(depth)-d(depth),1); ones(c(depth),1)  ]],...
%     1:11,'UniformOutput',false),...
%     {sum(cell2mat(neuron_count_map_all),1)}, {sum(cell2mat(neuron_count_map_v),1)}, ...
%     {sum(cell2mat(neuron_count_map_a),1)}, {sum(cell2mat(neuron_count_map_overlay),1)},'UniformOutput',false )




figure
% tiledlayout(9,11)


shuff=cell(length(idxx),1);
    per=cell(length(idxx),1);
    temp_shuff=cell(11,1);
for curr_recording=1:length(idxx)
    
    for curr_depth=1:length(idxx{1})
        per{curr_recording}{curr_depth}=sum(sum(idxx{curr_recording}{curr_depth},2)==2)/length(idxx{curr_recording}{curr_depth}(:,2));
        n_shuff=1000;
        shuff{curr_recording}{curr_depth}=zeros(n_shuff,1);
        for curr_shuf=1:n_shuff
            temp_shuff{curr_depth}{curr_recording}{curr_shuf}=ap.shake(idxx{curr_recording}{curr_depth},1);
            % shuff{curr_recording}{curr_depth}(curr_shuf)= ...
            %     sum(sum(ap.shake(idxx{curr_recording}{curr_depth},1),2)==2);
            shuff{curr_recording}{curr_depth}(curr_shuf)= ...
                sum(sum(ap.shake(idxx{curr_recording}{curr_depth},1),2)==2)/length(idxx{curr_recording}{curr_depth}(:,2));
        end

        ranks = tiedrank(vertcat(per{curr_recording}{curr_depth},shuff{curr_recording}{curr_depth} ));
        p_vals(curr_recording) = ranks( 1) / (n_shuff + 1);
        nexttile
        numbers=length(unique(vertcat(shuff{curr_recording}{curr_depth})));
        histogram(vertcat(shuff{curr_recording}{curr_depth}),numbers)
        xline(prctile(vertcat(shuff{curr_recording}{curr_depth}),95),'b')
        xline(prctile(vertcat(shuff{curr_recording}{curr_depth}),5),'b')
        xline(per{curr_recording}{curr_depth},'r')
    end
end



temp_111=cellfun(@(x)       cat(1,x{:})           ,temp_shuff,'UniformOutput',false );
temp_2= cellfun(@(x)  arrayfun(@(col) vertcat(x{:,col}), 1:size(x,2), 'UniformOutput', false),temp_111,'UniformOutput',false);
temp_shuffle=cellfun(@(x) cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2))  ,x,'UniformOutput',true    ) ,temp_2,'UniformOutput',false );

shuffle_mean=cellfun(@(x)   (prctile(x,95)+prctile(x,5))/2    ,temp_shuffle,'UniformOutput',true);
shuffle_error=cellfun(@(x)   (prctile(x,95)-prctile(x,5))/2    ,temp_shuffle,'UniformOutput',true);

temp_real1= vertcat(idxx{:});
temp_real_mean=nanmean(cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2)),   temp_real1,'UniformOutput',true),1)
temp_real_error=std(cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2)),   temp_real1,'UniformOutput',true),0,1,'omitmissing')./sqrt(size(temp_real1,1))

% temp_real2=arrayfun(@(depth)     cat(1,temp_real1{:,depth}), 1:11,'UniformOutput',false)
% temp_real3=cellfun(@(y)  sum(sum(y,2)==2)/length(y(:,2)),   temp_real2,'UniformOutput',true)


figure
for curr_depth=1:11
    nexttile
    numbers=length(unique(temp_shuffle{curr_depth}));
    histogram(temp_shuffle{curr_depth},numbers);
    xline(prctile(temp_shuffle{curr_depth},95),'b');
    xline(prctile(temp_shuffle{curr_depth},5),'b');
    % xline(temp_real3(curr_depth),'r')
    xline(temp_real_mean(curr_depth)+temp_real_error(curr_depth),'g');
    xline(temp_real_mean(curr_depth),'r');

end

% figure('Position',[50 50 100 200 ]);
ax2=nexttile(tl2)
hold on 
ap.errorfill(z_edges(1:end-1),temp_real_mean,temp_real_error ,colors{curr_group},0.1);
ap.errorfill(z_edges(1:end-1),shuffle_mean,shuffle_error,[0.8 0.8 0.8],1 );
xlim([z_edges(1) z_edges(end-1)+1])
ylabel('fraction of overlay in A')
xline(150,'LineStyle',':');
xline(50,'LineStyle',':')
 xticks([z_edges(1) z_edges(end-1)]);
 yticks([0 0.5])
view(gca,90, 90);
set(gca,'Color','none')
drawnow

end


%% overlay 
groups={'VA','AV','VA_nA'}

all_stim=[ 7 8 3 5 ];
colors=[[84 130 53]./255;[112  48 160]./255];
titles={'L','M','V passive','4k','A passive','12k','V task','A task','iti move'};
p_val=0.95

porportion_overlay=cell(2,4);
proportion_all=cell(2,4);
single_neuron_all_plot_select=cell(2,4);
neuron_all_plot_select=cell(2,4);

for curr_group=1:2
    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
    end
    temp_single_plot=cell(length(used_animals),1);
    temp_probe_position=cell(length(used_animals),1);
    temp_response=cell(length(used_animals),1);
    temp_plot=cell(length(used_animals),1);
    for curr_animal=1:length(used_animals)

        animal=used_animals{curr_animal};
        temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);
        temp_probe_position{curr_animal}=temp_file_name.all_celltypes(used_animals_idx{curr_animal},1);
        temp_response{curr_animal}=temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1);
        temp_plot{curr_animal}=temp_file_name.all_event_response_signle_neuron(used_animals_idx{curr_animal},1);
    end

    single_neuron_each_rec_1=vertcat(temp_plot{:});
    single_neuron_all_plot=cat(1,single_neuron_each_rec_1{:});

    response_each_rec=vertcat(temp_response{:});
    response_all=cat(1,response_each_rec{:});


    for curr_sorting=1:length(all_stim)

        used_stim=all_stim(curr_sorting);


        if used_stim==3|used_stim==5
            temp_single_idx=[3 5];
        else
            temp_single_idx=[7 8];
        end
        neuron_single=cellfun(@(y) sum(y(:,used_stim)>p_val),response_each_rec,'UniformOutput',true);
        neuron_overlay= cellfun(@(y) sum(y(:,temp_single_idx(1))>p_val&y(:,temp_single_idx(2))>p_val),response_each_rec,'UniformOutput',true);
        porportion_overlay{curr_group,curr_sorting}=neuron_overlay./neuron_single;
        proportion_all{curr_group,curr_sorting}=[sum(neuron_single)-sum(neuron_overlay),sum(neuron_overlay)];

        single_neuron_all_plot_select{curr_group,curr_sorting}=single_neuron_all_plot(response_all(:,used_stim)>p_val,:,:);
        temp_plot1=cellfun(@(x,y)...
            permute(nanmean(x(y(:,used_stim)>p_val,:,:),1),[2,3,1]) ,...
            single_neuron_each_rec_1 ,response_each_rec,'UniformOutput',false );
neuron_all_plot_select{curr_group,curr_sorting} =cat(3,temp_plot1{:});
    end
end

titles={'overlay in V','overlay in A'}
figure('Position',[50 50 200 100])
tiledlayout(1,2,'TileSpacing','loose','Padding','tight')
for curr_fig=1:2
nexttile
temp1=porportion_overlay(1:2,curr_fig+2)    
means = [nanmean(temp1{1}, 1);nanmean(temp1{2}, 1)]';
sems = [std(temp1{1}, 0, 1,'omitmissing') ./ sqrt(size(temp1{1},1));...
    std(temp1{2}, 0, 1,'omitmissing') ./ sqrt(size(temp1{2},1))]';
p =  ranksum(temp1{1}, temp1{2})

hold on
bar_handle = bar(1:2,means, 'grouped');
bar_handle.FaceColor = 'none';  % 允许每个柱子单独设色
bar_handle.EdgeColor = 'flat';  % 允许每个柱子单独设色
bar_handle.CData(1,:) = colors(1,:) ;  % 第一个柱子的颜色（RGB）
bar_handle.CData(2,:) = colors(2,:) ;  % 第二个柱子的颜色（RGB）
errorbar(1:2, means, sems, 'k.', 'LineWidth', 1);
% 添加散点
arrayfun(@(g) scatter(g*ones(length(temp1{g}),1) + randn(size(temp1{g},1),1)*0.05,...
    temp1{g}, ...
    20, 'filled', ...
    'MarkerFaceColor', colors(g,:)), 1:2);
if p < 0.05
    stars = repmat('*',1,sum(p<[0.05 0.01 0.001]));
    y_sig = max(vertcat(proportion_response{:})) + 0.05;
    plot(1:2, [1 1]*y_sig, 'k-');
    text(1.5, y_sig+0.02, stars, 'HorizontalAlignment','center');
end
xticklabels({})
ylabel('fraction','FontWeight','normal')
ylim([0 0.8])
yticks([0 0.8])
set(gca,'Color','none')
title(titles{curr_fig},'FontWeight','normal')
box off
drawnow
end





%%





figure;

nexttile
hold on
for curr_i=1:2
temp_mean=nanmean(neuron_all_plot_select{curr_i,4}(:,5,:),3);
temp_error=std(neuron_all_plot_select{curr_i,4}(:,5,:),0,3,'omitmissing')./sqrt(size(neuron_all_plot_select{curr_i,4},3));
ap.errorfill(t_bins,temp_mean,temp_error,colors(curr_i,:),0.5,0.1)
end
ylim([-0.5 5])
xlim([-0.1 0.5])
nexttile
hold on
for curr_i=1:2
temp_mean=nanmean(neuron_all_plot_select{curr_i,4}(:,3,:),3);
temp_error=std(neuron_all_plot_select{curr_i,4}(:,3,:),0,3,'omitmissing')./sqrt(size(neuron_all_plot_select{curr_i,4},3));
ap.errorfill(t_bins,temp_mean,temp_error,colors(curr_i,:),0.5,0.1)
end
ylim([-0.5 5])
xlim([-0.1 0.5])





figure;
t= tiledlayout(2,2,'TileSpacing','tight'); % 创建一个1行2列的布局
for curr_i=1:2
    nexttile

p1=pie([proportion_all{curr_i,4}(1) proportion_all{curr_i,4}(2)])
    set(p1(1), 'FaceColor', colors(curr_i,:),'FaceAlpha',0.5,'EdgeColor','none');
    set(p1(3), 'FaceColor', colors(curr_i,:),'EdgeColor','none');
    legend({'A only','A&V'},'Box','off','Location','northoutside')
    title(groups{curr_i},'FontWeight','normal')
end

nexttile
hold on
for curr_i=1:2
    temp_mean=nanmean(single_neuron_all_plot_select{curr_i,4}(:,:,5),1);
    temp_error=std(single_neuron_all_plot_select{curr_i,4}(:,:,5),0,1,'omitmissing')./sqrt(size(single_neuron_all_plot_select{curr_i,4},1));
    ap.errorfill(t_bins,temp_mean,temp_error,colors(curr_i,:),0.5,0.1)
end
ylim([-0.5 5])
xlim([-0.1 0.5])
title ('A passive','FontWeight','normal')
axis off
nexttile
hold on
for curr_i=1:2
    temp_mean=nanmean(single_neuron_all_plot_select{curr_i,4}(:,:,3),1);
    temp_error=std(single_neuron_all_plot_select{curr_i,4}(:,:,3),0,1,'omitmissing')./sqrt(size(single_neuron_all_plot_select{curr_i,4},1));
    ap.errorfill(t_bins,temp_mean,temp_error,colors(curr_i,:),0.5,0.1)
end
ylim([-0.5 5])
xlim([-0.1 0.5])
axis off
title ('V passive','FontWeight','normal')

%%  probes_corornal slices
bregma=[520,44,570];

groups={'VA','AV','VA_nA'}

all_stim=[ 7 8 3 5 ];
colors=[[84 130 53]./255;[112  48 160]./255];
titles={'L','M','V passive','4k','A passive','12k','V task','A task','iti move'};
p_val=0.95


probe_position_all=cell(2,1);

for curr_group=1:2
    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
    end
    temp_probe_position=cell(length(used_animals),1);
 
    for curr_animal=1:length(used_animals)

        animal=used_animals{curr_animal};
        temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);
        temp_probe_position{curr_animal}=temp_file_name.probe_positions(used_animals_idx{curr_animal},1);
      
    end
probe_position_all{curr_group}=vertcat(temp_probe_position{:});

end

% porbes_range in AP 
temp_pos=cell2mat(cellfun(@(x)  x(1,:), vertcat(probe_position_all{:}),'UniformOutput',false))
 temp_mid=nanmean([min(temp_pos,[],'all') max(temp_pos,[],'all')]);
 position_slices=[temp_mid-30 temp_mid+30];



allen_atlas_path = fileparts(which('template_volume_10um.npy'));
obj.av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy'));
obj.st = loadStructureTree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));


structure_name='caudoputamen';
plot_structure = find(strcmpi(obj.st.safe_name,structure_name));
plot_structure_id = obj.st.structure_id_path{plot_structure};
plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
    obj.st.structure_id_path));

% Get structure color and volume
% structure_color = hex2dec(reshape(obj.st.color_hex_triplet{plot_structure},2,[])')./255;
structure_color=[0.5 0.5 0.5]
plot_ccf_volume = ismember(obj.av,plot_ccf_idx);



dist2bregma=(bregma(1)-nanmean(position_slices))./100 %% mm

figure('Position',[50 50 200 200]);
hold on
for curr_view = 1
      curr_outline_out = bwboundaries(squeeze((max(obj.av(position_slices(1):position_slices(2),:,1:end/2),[],curr_view)) > 1));
         % curr_outline_out = bwboundaries(squeeze((obj.av(nanmean(position_slices),:,1:end/2))> 1));

    % (only plot largest outline)
    [~,curr_outline_idx] = max(cellfun(@length,curr_outline_out));
    curr_outline_reduced = reducepoly(curr_outline_out{curr_outline_idx});
    plot( ...
        curr_outline_reduced(:,2), ...
        curr_outline_reduced(:,1),'k','linewidth',2);
    % (draw 1mm scalebar)
    % line([0,0],[0,100],'color','k','linewidth',2);
end
set(gca,'YDir','reverse')
axis(gca,'equal','off')

curr_outline_area = bwboundaries(squeeze(max(plot_ccf_volume(position_slices(1):position_slices(2),:,:),[],curr_view)));

% % curr_outline_area = bwboundaries(squeeze(plot_ccf_volume(nanmean(position_slices),:,:)));

plot( curr_outline_area{1}(:,2), curr_outline_area{1}(:,1), ...
    'Color', structure_color, 'LineWidth', 2);
title(['AP: ' num2str(dist2bregma, '%.2f') ' mm'],'FontWeight','normal')

for curr_group=1:2
cellfun(@(x)  line(x(3,:),x(2,:),'linewidth',2,'color',colors(curr_group,:)) ,   probe_position_all{curr_group},'UniformOutput',false)
end





%%  velocity

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};

figure('Position',[50 50 200 400]);


    for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));

        end

      
     temp_vel_v=cell(length(used_animals),1);
     temp_vel_a=cell(length(used_animals),1);

        for curr_animal=1:length(used_animals)
            animal=used_animals{curr_animal};
            temp_file=load([Path 'single_mouse\' animal '_ephys_behavior.mat']);
            temp_vel_v{curr_animal}=temp_file.frac_velocity_stimalign(used_animals_idx{curr_animal},2);
            temp_vel_a{curr_animal}=temp_file.frac_velocity_stimalign(used_animals_idx{curr_animal},3);

        end


       temp_vel_v_all= vertcat(temp_vel_v{:});
       vel_v_mean=nanmean(cell2mat(cellfun(@(x) nanmean(x,1),temp_vel_v_all,'UniformOutput',false)),1);
       vel_v_error=std(cell2mat(cellfun(@(x) nanmean(x,1),temp_vel_v_all,'UniformOutput',false)),0,1,'omitmissing')/sqrt(length(temp_vel_v_all));

 
       temp_vel_a_all= vertcat(temp_vel_a{:});
       vel_a_mean=nanmean(cell2mat(cellfun(@(x) nanmean(x,1),temp_vel_a_all,'UniformOutput',false)),1);
       vel_a_error=std(cell2mat(cellfun(@(x) nanmean(x,1),temp_vel_a_all,'UniformOutput',false)),0,1,'omitmissing')/sqrt(length(temp_vel_a_all));

 
       nexttile
       hold on
       ap.errorfill(surround_time_points,vel_v_mean,vel_v_error,[1 0 0])
       ap.errorfill(surround_time_points,vel_a_mean,vel_a_error,[0 0 1])

    end


%%
surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


colors={[84 130 53]./255,[112  48 160]./255};
image_color={'G','P'};

figure('Position',[50 50 200 400]);

for curr_group=1:2
    switch curr_group
        case 1
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
        case 2
            used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
            used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));

    end


    RateWarp=cell(length(used_animals),1);
    Tasktype_idx=cell(length(used_animals),1);
    trialInfo=cell(length(used_animals),1);
    % temp_celltypes=cell(length(used_animals),1);

    for curr_animal=1:length(used_animals)
        animal=used_animals{curr_animal};
        temp_file=load([Path 'single_mouse\' animal '_ephys_warp.mat']);
        %       temp_file_rec=matfile([Path 'single_mouse\' animal '_ephys.mat']);
        % temp_celltypes{curr_animal}=temp_file_rec.all_cell_sorted(used_animals_idx{curr_animal},1);
        %
        RateWarp{curr_animal}=temp_file.RateWarp(used_animals_idx{curr_animal});
        Tasktype_idx{curr_animal}=temp_file.Tasktype_idx(used_animals_idx{curr_animal});
        trialInfo{curr_animal}=temp_file.trialInfo(used_animals_idx{curr_animal});

    end


    RateWarp_all= vertcat(RateWarp{:});
    Tasktype_all=vertcat(Tasktype_idx{:});
    trialInfo_all=cellfun(@(x) cellfun(@(a) a.isValid,x,'UniformOutput',false)  , vertcat(trialInfo{:}),'UniformOutput',false);

    RateWarp_all_valid=cellfun(@(x,y) cellfun(@(a,b) a(:,:,b) ,x,y,'UniformOutput',false)  ,...
        RateWarp_all,trialInfo_all,'UniformOutput',false );
    modality=cellfun(@(x,y)  cellfun(@(a,b)  a(b), x,y,'UniformOutput',false)   ,Tasktype_all,trialInfo_all,'UniformOutput',false );


    % ax=axesOut{curr_day};
    % seg=segIdx{curr_day};
    RateWarp_norm=cellfun(@(x) cellfun(@(a)...
        reshape(zscore(reshape(permute(a, [1 3 2]), [], size(a,2)),0,1),[size(permute(a, [1 3 2]))]),x,'UniformOutput',false) ,...
        RateWarp_all_valid,'UniformOutput',false   );
    RateWarp_sort=cellfun(@(x,y) cellfun(@(a,b) ...
        arrayfun(@(id)  permute(nanmean(a(:,b==id,:),2),[1 3 2]),unique(b),'UniformOutput',false ),x,y,'UniformOutput',false),...
        RateWarp_norm,modality,'UniformOutput',false   );


    temp_data=cellfun(@(x) cat(1,x{:}),RateWarp_sort,'UniformOutput',false);
    numbers= cellfun(@(x)  size(x,1), temp_data{1},'UniformOutput',true);
    temp_data2=cellfun(@(x)  cat(1,x{:})  ,temp_data,'UniformOutput',false);

    RateWarp_all1=cat(2,temp_data2{:});
    [w,vale]=pca(RateWarp_all1);

% figure;
% plot(mean(RateWarp_all1(1+sum(numbers(1:6)):sum(numbers(1:7)),:)',1))
% 
% imagesc(RateWarp_all1(1+sum(numbers(1:6)):sum(numbers(1:7)),:)')
% colormap(ap.colormap('wk'))
% clim([0 1])

    value_l=vale(1:numbers(1),:);
    value_c=vale(1+numbers(1):sum(numbers(1:2)),:);
    value_r=vale(1+sum(numbers(1:2)):sum(numbers(1:3)),:);
    value_4=vale(1+sum(numbers(1:3)):sum(numbers(1:4)),:);
    value_8=vale(1+sum(numbers(1:4)):sum(numbers(1:5)),:);
    value_12=vale(1+sum(numbers(1:5)):sum(numbers(1:6)),:);
    value_v=vale(1+sum(numbers(1:6)):sum(numbers(1:7)),:);
    value_a=vale(1+sum(numbers(1:7)):sum(numbers(1:8)),:);
    nexttile; hold on;view(3);
    % 轨迹（画平均线；如要阴影可用patch或fill）
    % plot3(value_l(:,1), value_l(:,2), value_l(:,3), 'LineWidth', 2,'color',[0.5 0.5 0.5]);  % Visual
    % plot3(value_c(:,1), value_c(:,2), value_c(:,3), 'LineWidth', 2,'color',[0.5 0.5 0.5]);  % Auditory
    plot3(value_r(:,1), value_r(:,2), value_r(:,3), 'LineWidth', 2,'color',[0.5 0.5 1]);  % Visual
    % % plot3(value_4(:,1), value_4(:,2), value_4(:,3), 'LineWidth', 2,'color',[0.5 0.5 0.5]);  % Auditory
    plot3(value_8(:,1), value_8(:,2), value_8(:,3), 'LineWidth', 2,'color',[1 0.5 0.5]);  % Visual
    % % plot3(value_12(:,1), value_12(:,2), value_12(:,3), 'LineWidth', 2,'color',[0.5 0.5 0.5]);  % Auditory
    plot3(value_v(:,1), value_v(:,2), value_v(:,3), 'LineWidth', 2,'color',[0 0 1]);  % Visual
    plot3(value_a(:,1), value_a(:,2), value_a(:,3), 'LineWidth', 2,'color',[1 0 0]);  % Auditory

    % 
    % plot3(value_8(51,1), value_8(51,2), value_8(51,3), 'ko','MarkerFaceColor','k');  % Visual
    % plot3(value_8(101,1), value_8(101,2), value_8(101,3), 'ko','MarkerFaceColor','k');  % Visual
    % plot3(value_r(101,1), value_r(101,2), value_r(101,3), 'ko','MarkerFaceColor','k');  % Visual
    % plot3(value_r(51,1), value_r(51,2), value_r(51,3), 'ko','MarkerFaceColor','k');  % Visual
    plot3(value_v(51,1), value_v(51,2), value_v(51,3), 'ko','MarkerFaceColor','k'); % stim处
    plot3(value_v(61,1), value_v(61,2), value_v(61,3), 'ks','MarkerFaceColor','k'); % move处
    plot3(value_a(51,1), value_a(51,2), value_a(51,3), 'ko','MarkerFaceColor','k'); % stim处
    plot3(value_a(61,1), value_a(61,2), value_a(61,3), 'ks','MarkerFaceColor','k'); % move处
    % % axis image

end

