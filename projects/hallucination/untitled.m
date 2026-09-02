clear all
clc
Path='D:\Data process\project_hallucination';

U_master = plab.wf.load_master_U;

surround_samplerate = 35;
task_boundary1=0;
task_boundary2=0.2;
t_kernels=1/surround_samplerate*[-10:30];
 kernels_period=find(t_kernels>task_boundary1&t_kernels<task_boundary2);


load(fullfile(Path,'iti_kernels.mat'))
% temp_1= iti_move_kernels(cellfun(@(x) ~isempty(x),iti_move_kernels,'UniformOutput',true))
% temp_2=cellfun(@(x)  x(cellfun(@(a) ~isempty(a) ,x,'UniformOutput',true))   ,temp_1,'UniformOutput',false)


temp_2 = cellfun(@(x) cat(3, x{~cellfun('isempty', x)}), ...
    iti_move_kernels(~cellfun('isempty', iti_move_kernels)), 'UniformOutput', false);
temp_3=  cat(3,temp_2{:})  ;
tem_image= plab.wf.svd2px(U_master(:,:,1:size(temp_3,1)),temp_3);


ap.imscroll(nanmean(tem_image,4),t_kernels)
axis image 
clim( 0.0003*[0,1]);
ap.wf_draw('ccf',[0.5 0.5 0.5]);
colormap( ap.colormap('WG' ));