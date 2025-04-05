load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

figure;
  imagesc(zeros(450,426));
    axis image off;
    ap.wf_draw('ccf', 'black');
 
    colormap(  ap.colormap(['KWG' ]  ));
    hold on
 boundaries1 = bwboundaries(roi1(5).data.mask  );
    plot(boundaries1{1, 1} (:,2),boundaries1{1, 1} (:,1),'Color',[1 0 0])

dat=roipoly;
  % roi1(1).name='asymmetry lmPFC'
 roi1(2).data.mask=fliplr(roi1(1).data.mask);
 
  % roi1(14).name='asymmetry rmPFC'
 roi1(3).data.mask=fliplr(roi1(4).data.mask);

  % roi1(2).name='posterior right mPFC'
 roi1(16).data.mask=dat;
 roi1(16).name='SSp'


save('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat',"roi1")

figure;
imagesc(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)-...
        fliplr(data_imaging_all{workflow_idx}{curr_stage}{img_idx}(:,:,use_stim)));
    axis image off;
    ap.wf_draw('ccf', 'black');

    clim(scale .* [-1, 1]);
    colormap( ap.colormap(['KW' Color{workflow_idx}]));
     axis image;