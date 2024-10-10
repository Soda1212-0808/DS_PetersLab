
clear all
clc
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\';

master_U_fn = fullfile(plab.locations.server_path,'Lab', ...
    'widefield_alignment','U_master.mat');
load(master_U_fn);
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')
 surround_frames = 60;
    surround_t = [-surround_frames:surround_frames]./30;
period_passive_face=find(surround_t>0&surround_t<0.2);


surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_passive = surround_window_passive(1):1/surround_samplerate:surround_window_passive(2);
period_passive=find(t_passive>0&t_passive<0.2);


animals = {'DS003','DS004','DS005','DS006','DS007','DS014','DS015','DS016','AP019'};


for curr_animal=1:length(animals)
    preload_vars = who;
animal=animals{curr_animal};
  fprintf('%s\n', ['start  ' animal ]);
  raw_data_lcr_face=load([Path '\mat_data\' animal '_hml_passive_audio_face.mat']);
camera_all=raw_data_lcr_face.camera_all;
h = figure;imagesc(mean(camera_all{1, 1} ,3));axis image;
roi_mask_face = roipoly;
close(h);
save([Path 'face_data\' animal '_face_roi.mat' ],'roi_mask_face', '-v7.3')
clearvars('-except',preload_vars{:});
 ap.print_progress_fraction(curr_animal,length(animals));

fprintf('\n');

end




plot_data_all=cell(size(animals));

for curr_animal=1:length(animals)
            preload_vars = who;

  animal=animals{curr_animal};
  fprintf('%s\n', ['start  ' animal ]);
  raw_data_lcr=load([Path '\mat_data\' animal '_hml_passive_audio.mat']);
  raw_data_lcr_face=load([Path '\mat_data\' animal '_hml_passive_audio_face.mat']);
    
  
  load([Path '\face_data\' animal '_face_roi.mat']);
 camera_all=raw_data_lcr_face.camera_all;

% h = figure;imagesc(mean(camera_all{1, 1} ,3));axis image;
% roi_mask_face = roipoly;
% close(h);

% figure;
% for i=1:size(camera_all,1)
%     nexttile
%     for j=2
%         hold on
%         plot( surround_t(2:end),(roi_mask_face(:))'*(reshape(camera_all{i, j},[],120))./sum(roi_mask_face,'all'));
%     end
%     title(num2str(i))
%     ylim([0,15])
%     % legend
% end


idx_buff=cell2mat(cellfun(@(x) ~isempty(x), camera_all,'UniformOutput',false));
camera_buffer(idx_buff)=cellfun(@(x) (roi_mask_face(:))'*(reshape(x,[],120))./sum(roi_mask_face,'all'),camera_all(idx_buff),   'UniformOutput',false) ;
camera_buffer2(idx_buff)=cellfun(@(x) mean(x(period_passive_face)),camera_buffer(idx_buff),'UniformOutput',false);
cell_matrix_with_nan = cellfun(@(x) ifelse(isempty(x), NaN, x), camera_buffer2, 'UniformOutput', false);

camera_buffer3=reshape(cell_matrix_with_nan,size(idx_buff));

base_buffer=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_lcr.wf_px_baseline ,'UniformOutput',false)',cellfun( @(idx) find(idx==8000),raw_data_lcr.all_groups_name_baseline  ,'UniformOutput',false),'UniformOutput',false);
base_buffer2=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), base_buffer, 'UniformOutput', false);
base_buffer3=cellfun(@(x) mean( x(roi1(1).data.mask(:),:),1),base_buffer2, 'UniformOutput', false);
base_buffer4=cellfun(@(x) mean(x(period_passive)),base_buffer3,'UniformOutput',false);

passive_buffer=cellfun(@(baseline,idx) baseline(:,:,:,idx),cellfun( @(xxx) plab.wf.svd2px(U_master, xxx),raw_data_lcr.wf_px ,'UniformOutput',false)',cellfun( @(idx) find(idx==8000),raw_data_lcr.all_groups_name  ,'UniformOutput',false),'UniformOutput',false);
passive_buffer2=cellfun(@(x) reshape(x,size(x,1)*size(x,2),size(x,3)), passive_buffer, 'UniformOutput', false);
passive_buffer3=cellfun(@(x) mean( x(roi1(1).data.mask(:),:),1),passive_buffer2, 'UniformOutput', false);
passive_buffer4=cellfun(@(x) mean(x(period_passive)),passive_buffer3,'UniformOutput',false);

 for curr_idx=1:length(raw_data_lcr.workflow_day)
    buff_lcr_face_idx=find(strcmp(raw_data_lcr_face.workflow_day,raw_data_lcr.workflow_day{curr_idx}));
    plot_data(curr_idx,1)=camera_buffer3{buff_lcr_face_idx,3};
    plot_data(curr_idx,2)=passive_buffer4{curr_idx};
 end


plot_data_all{curr_animal}(:,1)=[cell2mat(camera_buffer3(1:3))';plot_data(:,1)];
plot_data_all{curr_animal}(:,2)=[cell2mat(base_buffer4);plot_data(:,2)];


clearvars('-except',preload_vars{:});
 ap.print_progress_fraction(curr_animal,length(animals));

fprintf('\n');

end

 



figure;
for i=1:length(plot_data_all)
    nexttile;
   yyaxis left; plot(plot_data_all{i}(:,1)); ylabel('face movement')
   yyaxis right; plot(plot_data_all{i}(:,2));ylabel('dF/F')

title(animals{i})
end
