clear all
clc
Path = 'D:\Data process\project_cross_model\wf_data\';
save_path = '\\qnap-ap001.dpag.ox.ac.uk\APlab\Lab\Papers\Song_2025\data';

surround_samplerate = 35;
surround_window_passive = [-0.5,1];
surround_window_task = [-0.2,1];
t_kernels=1/surround_samplerate*[-10:30];
passive_boundary=0.2;
period_kernels=find(t_kernels>0&t_kernels<passive_boundary);

workflow='lcr_passive';
animals={'AP027','AP028','AP029'};

wf_passive_kernel=cell(length(animals),1);

for curr_animal=1:length(animals)
    preload_vars = who;
    animal=animals{curr_animal};
    raw_data_passive=load([Path  workflow '\' animal '_' workflow '.mat']);
    % raw_data_behavior=load([Path   'behavior\' animal '_behavior'  '.mat']);

  
    vp_first= find(ismember(raw_data_passive.workflow_type_name_merge,'visual position'),1);
    opa_idx= find(ismember(raw_data_passive.workflow_type_name_merge,'visual opacity'));
    opa_idx=opa_idx(opa_idx<vp_first);
    wf_passive_kernel{curr_animal}=raw_data_passive.wf_px_kernels(opa_idx) 


end

save(fullfile(save_path, 'wf_passive_kernels_opacity.mat' ),'wf_passive_kernel','-v7.3')

