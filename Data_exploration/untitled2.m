buffer=wf_px(19:23);
data1=mean(cat(5,buffer{:}),5);
buffer=wf_px(10:18);
data2=mean(cat(5,buffer{:}),5);

surround_window = [-0.5,1];
surround_samplerate = 35;
t2 = surround_window(1):1/surround_samplerate:surround_window(2);


figure;
nexttile
imagesc(max(data2(:,:,t2<0.2&t2>0,2),[],3))
ap.wf_draw('ccf','black');
axis image off;
clim(0.002.*[-1,1]); colormap(ap.colormap('PWG'));
title('Auditory task')
nexttile
imagesc(max(data1(:,:,t2<0.2&t2>0,2),[],3))
ap.wf_draw('ccf','black');
axis image off;
clim(0.002.*[-1,1]); colormap(ap.colormap('PWG'));
title('Mixed task')



ap.imscroll(data1,t2)
ap.wf_draw('ccf','black');
axis image;
clim(0.5*max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));



ap.imscroll(data2,t2)
ap.wf_draw('ccf','black');
axis image;
clim(0.5*max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));

