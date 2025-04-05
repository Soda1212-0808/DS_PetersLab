
%% TESTING BATCH TASK WIDEFIELD
clear all
Path = 'C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\mice\process\processed_data_v2\mat_data\';



surround_samplerate = 35;
surround_window = [-0.2,1];
baseline_window = [-0.5,-0.1];

t_task = surround_window(1):1/surround_samplerate:surround_window(2);
baseline_t = baseline_window(1):1/surround_samplerate:baseline_window(2);
t_kernels=1/surround_samplerate*[-5:30];

surround_time = [-5,5];
surround_sample_rate = 100;
surround_time_points = surround_time(1):1/surround_sample_rate:surround_time(2);


animals = {'DS007','DS010','AP019','AP021','DS011','AP022','DS001','AP018','AP020',...
    'DS003','DS006','DS013','DS000','DS004','DS014','DS015','DS016','AP027','AP028','AP029','HA003','HA004','HA000','HA001','HA002'};
animals={'DS019','DS020','DS021'}

% passive_workflow='lcr_passive';
% passive_workflow='hml_passive_audio';
passive_workflow='task';
% animals={'DS007'}
%
for curr_animal_idx=1:length(animals)
    preload_vars_main = who;


    animal=animals{curr_animal_idx};
    fprintf('%s\n', ['start  ' animal ]);
    fprintf('%s\n', ['start saving tasks files...']);


    data_load=load([Path '\' passive_workflow '\' animal '_' passive_workflow '.mat' ]);

workflow_type_name_merge=cell(length(data_load.workflow_type_name),1);

for curr_recording=1:length(data_load.workflow_type_name)
        preload_vars = who;


            if strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1_audio_volume')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_audio_volume')
                workflow_type_name_merge{curr_recording}='audio volume';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2')
                workflow_type_name_merge{curr_recording}='visual position';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1_size_up')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_size_up')
                workflow_type_name_merge{curr_recording}='visual size up';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1_opacity')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_opacity')
                workflow_type_name_merge{curr_recording}='visual opacity';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1_audio_frequency')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_audio_frequency')
                workflow_type_name_merge{curr_recording}='audio frequency';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage1_angle')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_angle')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_angle_size60')
                workflow_type_name_merge{curr_recording}='visual angle';
            elseif strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_stage2_mixed_VA')...
                    ||strcmp(data_load.workflow_type_name{curr_recording},'stim_wheel_right_frequency_stage2_mixed_VA')
                workflow_type_name_merge{curr_recording}='mixed VA';
            else  workflow_type_name_merge{curr_recording}='none';
            end





    % Clear vars except pre-load for next loop
    clearvars('-except',preload_vars{:});
    ap.print_progress_fraction(curr_recording,length(data_load.workflow_day));


end


% load([Path passive_workflow '\' animal '_task.mat' ])

 save([Path passive_workflow '\' animal '_' passive_workflow '.mat' ],'workflow_type_name_merge','-append')

clearvars('-except',preload_vars_main{:});
end