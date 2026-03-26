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


%%

groups={'VA','AV'}
colors=[[84 130 53]./255;[112  48 160]./255];

  for curr_group=1:2
        switch curr_group
            case 1
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_VA(~cellfun(@isempty, anterior_learned_idx_VA','UniformOutput',true));
            case 2
                used_animals=animals(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
                used_animals_idx=anterior_learned_idx_AV(~cellfun(@isempty, anterior_learned_idx_AV','UniformOutput',true));
        end

        velocity=cell(length(used_animals),1);
        cell_fraction=cell(length(used_animals),1);
        for curr_animal=1:length(used_animals)

            animal=used_animals{curr_animal};
            load([Path 'single_mouse\' animal '_ephys_behavior.mat']);

            temp_file_name=matfile([Path 'single_mouse\' animal '_ephys.mat']);
            % temp_data=load([Path 'single_mouse\' animal '_ephys.mat'])
            p_val=0.95;

            cell_fraction{curr_animal}=cellfun(@(x) sum(x(:,[3 5])>p_val,1)./size(x,1),...
            temp_file_name.all_event_response_idx(used_animals_idx{curr_animal},1),'uni',false);

            velocity{curr_animal}=frac_velocity_stimalign(used_animals_idx{curr_animal}, 2:3);

        end

        velocity_all=cat(1,velocity{:});
        velocity_all_1= feval(@(a)  arrayfun(@(id)   cat(1,a{:,id}) ,1:2,'uni',false  ) ,  ...
            cellfun(@(x) nanmean(x,1), velocity_all,'UniformOutput',false ))
        velocity_all_min=abs(feval(@(a) cat(2,a{:}) , cellfun(@(x) min(x,[],2),velocity_all_1,'UniformOutput',false)));

        cell_fraction_all=cell2mat(cat(1,cell_fraction{:}));


        figure;
        nexttile
        plot(velocity_all_1{1}')
        legend
        nexttile
        plot(velocity_all_1{2}')

        figure('Position',[50 50 200 200]);
        hold on
        plot(cell_fraction_all(:,1),velocity_all_min(:,1),'Marker','.','Color',[1 0 0],'LineStyle','none','MarkerSize',10)
        plot(cell_fraction_all(:,2),velocity_all_min(:,2),'Marker','.','Color',[0 0 1],'LineStyle','none','MarkerSize',10)
        set(gca, 'YLim', [0 5000],  'YTick', [0 5000],  'YTickLabel', {'0','max'},'Color','none')
        xlabel('Fraction');ylabel('velocity')
        title(groups{curr_group},'Color',colors(curr_group,:))
  end


