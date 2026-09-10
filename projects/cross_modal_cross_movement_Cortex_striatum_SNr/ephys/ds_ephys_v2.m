clc
clear all

animals={'DS036','DS041','DS043'};
workflows={'stim_wheel_Vcenter_X_move_stage2_BW','stim_wheel_Vcenter_X_move_stage2_BWG'};

ephys_data_all=table;
loop_all=0;
for curr_animal=1:length(animals)
    animal=animals{curr_animal};
    recordings=plab.find_recordings(animal,[],'stim_wheel*');
    recordings=recordings([recordings.ephys]~=0);
    for curr_recording =1:length(recordings)
        % load recording
        rec_day=recordings(curr_recording).day;
        rec_time=recordings(curr_recording).recording{1};
        verbose=true;
        load_parts.ephys=true;
        load_parts.ephys_axons=true;
        try
            ap.load_recording
            % process data
            ds.process_ephys
            loop_all=loop_all+1;
            ephys_data_all.animal{loop_all}=animal;
            ephys_data_all.day{loop_all}=rec_day;
            ephys_data_all.data{loop_all}=ephys_data;
        catch ME
            fprintf('出错: %s\n',  ME.message);
            continue
        end
    end
end


filename='D:\Data process\project_SNr\data\ephys_data\ephy_data_all.mat';
save(filename,'ephys_data_all','-v7.3');
fprintf('Ephys data saved successfully to %s\n', filename);

%%
filename='D:\Data process\project_SNr\data\ephys_data\ephy_data_all.mat';

load(filename)

% Display a message indicating the data has been saved successfully

labels={'stim_0correct','stim_1correct','move_0correct','move_1correct'}


figure;

for curr_data=1:size(ephys_data_all,1)
label_id=cellfun(@(x) find(ismember( ephys_data_all.data{curr_data}.labels,x)),labels,'UniformOutput',true);
temp_data=ephys_data_all.data{curr_data}.psth(:,:,label_id);
cell_response=feval(@(x)     sum( x(:,label_id(1:2))>0.95,2)==2  ,cat(2,ephys_data_all.data{curr_data}.response_p{:}));
temp_data_mean=permute(nanmean(temp_data(cell_response,:,:),1),[2,3,1]);
nexttile
colororder([0.9 0.3 0.2;    % 第1条：红色
    0.2 0.5 0.9]); 
plot(temp_data_mean(:,[3 4]))
animal=ephys_data_all{curr_data,1}{1};
day=ephys_data_all{curr_data,2}{1};
title([animal ' ' day ])
end
