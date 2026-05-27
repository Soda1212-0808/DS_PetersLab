clear all

surround_window = [-0.5,1];
surround_samplerate = 35;
t = surround_window(1):1/surround_samplerate:surround_window(2);
t_kernels=[-10:30]/surround_samplerate;
period=find(t_kernels>0&t_kernels<0.3);

surround_window = [-0.5,1];
mousecam_framerate = 30;
face_time = surround_window(1):1/mousecam_framerate:surround_window(2);

U_master = plab.wf.load_master_U;
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat');

Path='D:\Data process\project_cross_model\wf_data\data_package';
  %%  wf
groups_name={'VA','AV'};
modes_name={'Visual','Auditory'};
all_data=struct;
all_data.group_names=groups_name;


for curr_group=1:2
    switch curr_group
        case 1
            animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
        case 2
            animals = {'DS000','DS004','DS014','DS015','DS016'};
    end

    temp_data_all=table;
    temp_data_all.animals=animals';
    for curr_animal=1:length(animals)
        preload_vars=who;
        animal=animals{curr_animal};
        data_all=matfile(fullfile(Path,[animal '_all_data.mat']));

        temp_data=struct;
        task_idx=cell(2,1);
        task_idx{curr_group}=find((strcmp([data_all.task_name],'stim_wheel_right_stage1')|...
            strcmp([data_all.task_name],'stim_wheel_right_stage2'))&...
            ~cellfun(@isempty ,data_all.wf_task));
        task_idx{3-curr_group}=find((strcmp([data_all.task_name],'stim_wheel_right_stage1_audio_volume')|...
            strcmp([data_all.task_name],'stim_wheel_right_stage2_audio_volume'))&...
            ~cellfun(@isempty ,data_all.wf_task));
        temp_data.day=cellfun(@(a)data_all.day(a,1),task_idx,'uni',false);
        temp_data.behav=cellfun(@(a) cellfun(@(x) x.rxn_l_p(1)<0.05 , data_all.behavior_task(a,1),'uni',true),task_idx,'uni',false);
        temp_data.performance=cellfun(@(a) cellfun(@(x) x.performance , data_all.behavior_task(a,1),'uni',true),task_idx,'uni',false);
   
        temp_data.wf_task=cellfun(@(a)data_all.wf_task(a,1),task_idx,'uni',false);
        temp_data.wf_passive_audio=cellfun(@(a)data_all.wf_hml_passive_audio(a,1),task_idx,'uni',false);
        temp_data.wf_passive_visual=cellfun(@(a)data_all.wf_lcr_passive(a,1),task_idx,'uni',false);
            temp_data_all.data(curr_animal)=temp_data;
    end

all_data.wf_data{curr_group}=temp_data_all;
end



figure
Color={'B','R'};
scale_image=0.0003;
for curr_group=1:2
for curr_stage=1:2
    switch curr_stage
        case 1
            temp_wf=cellfun(@(x,y)  feval(@(b) cat(3,b{:}), cellfun(@(a) a.stim_kernels{1}, x{1}(find(y{1}==0,2)),...
                'UniformOutput',false)),{all_data.wf_data{curr_group}.data.wf_task},...
                {all_data.wf_data{curr_group}.data.behav},'UniformOutput',false  );
        case 2
            temp_wf=cellfun(@(x,y)  feval(@(b) nanmean(cat(3,b{:}),3), cellfun(@(a) a.stim_kernels{1}, x{1}(find(y{1}==1,2,'last')),...
                'UniformOutput',false)),{all_data.wf_data{curr_group}.data.wf_task},...
                {all_data.wf_data{curr_group}.data.behav},'UniformOutput',false  );
    end

    tem_image=cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)),x),  temp_wf,'UniformOutput',false);
    temp_image_max=feval(@(a) nanmean(max(a(:,:,period,:),[],3),4) ,cat(4,tem_image{:}));

    ax=nexttile
    imagesc(temp_image_max)
    axis image off;
    clim(scale_image .* [0, 1]);
    colormap(ax, ap.colormap(['W' Color{curr_group}] ));
    ap.wf_draw('ccf', [0.5 0.5 0.5]);
end
end


