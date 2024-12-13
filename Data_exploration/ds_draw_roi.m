load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

figure;
imagesc(zeros(450,426))
axis image off;
ap.wf_draw('ccf','black');
dat=roipoly;
 roi1(10).name='RSC'
 roi1(10).data.mask=dat;
save('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat',"roi1")
