clear all
 Path='C:\Users\dsong\Documents\MATLAB\Da_Song\Data_analysis\ImageDsiplay\';
animals = {'AP017','AP018','AP019','AP021','AP022','AP020'};


for curr_animal_idx = 1:length(animals)

 
animal=animals{curr_animal_idx};

data_image(curr_animal_idx).name=animal;
  

workflow = 'ImageDisplay';
recordings = plab.find_recordings(animal,[],workflow);


 wf_px= 0;
align_id=0;

    % Grab pre-load vars
    preload_vars = who;

    % Load data
    rec_day = recordings(1).day;
  
    recording_date{1}=recordings(1).day;
    rec_time = recordings(1).recording{end};
    if ~recordings(1).widefield(end)
        continue
    end

    try
        load_parts.widefield = true;
        ds.load_recording;
    catch me
        warning('%s %s %s: load error, skipping \n >> %s', ...
            animal,rec_day,rec_time,me.message)
        continue
    end

    % Get quiescent trials and stim onsets/ids
    stim_window = [0,0.5];
    quiescent_trials = arrayfun(@(x) ~any(wheel_move(...
        timelite.timestamps >= stimOn_times(x)+stim_window(1) & ...
        timelite.timestamps <= stimOn_times(x)+stim_window(2))), ...
        1:length(stimOn_times))';

    align_times = stimOn_times(quiescent_trials);
    
 
    align_category_all = vertcat(trial_events.values.PictureID);
   


    align_category = align_category_all(quiescent_trials);

    % Align to stim onset
    surround_window = [-0.5,1];
    surround_samplerate = 35;
    t = surround_window(1):1/surround_samplerate:surround_window(2);
    peri_event_t = reshape(align_times,[],1) + reshape(t,1,[]);

    aligned_v = reshape(interp1(wf_t,wf_V',peri_event_t,'previous'), ...
        length(align_times),length(t),[]);

    align_id = findgroups(align_category);
    aligned_v_avg = permute(aligned_v,[3,2,1]);
    aligned_v_avg_baselined = aligned_v_avg - nanmean(aligned_v_avg(:,t < 0,:),2);

    % Convert to pixels and package
   
    aligned_px_avg = plab.wf.svd2px(wf_U,aligned_v_avg_baselined);
    wf_px= aligned_px_avg;


    % Prep for next loop
    ap.print_progress_fraction(1,length(recordings));
    clearvars('-except',preload_vars{:});


data_image(curr_animal_idx).image=wf_px;
data_image(curr_animal_idx).idx=align_id;


% data_merge(curr_animal_idx).imagedata_passive(curr_stage).data=wf_px;
% data_merge(curr_animal_idx).imagedata_passive(curr_stage).recording_date=recording_date;
% data_merge(curr_animal_idx).imagedata_passive(curr_stage).stage=stage;



% data_merge(curr_animal_idx).learned_day=learned_day;
end



current_time = datestr(now, 'yyyy-mm-dd_HH-MM');

save([Path 'process_data_image' current_time '.mat'], 'data_image', '-v7.3')

data_all=cat(5,data_image(:).image);

 surround_window = [-0.5,1];
    surround_samplerate = 35;
    t = surround_window(1):1/surround_samplerate:surround_window(2);
period=find(t>0&t<=0.1);

ap.imscroll(squeeze(data_all(:,:,:,1,:)),t)
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));



for i =1:size(data_all,5)
   figure('Position', [50, 50, 1800, 900]);
  
    for s=1:size(data_all,4)
        nexttile
        imagesc(mean(data_all(:,:,period,s,i),3))
         axis image off;
  ap.wf_draw('ccf','black');
  scale=max(abs(data_all(:,:,:,:,i)),[],"all");
clim(0.6*scale.*[-1,1]); colormap(ap.colormap('PWG'));
    title(s)
    
    end
sgtitle(data_image(i).name)
saveas(gcf,[Path data_image(i).name '_ImageDsiplay'], 'jpg');

end






ap.imscroll(permute(data_all,[1 2 3 5 4]),t)
axis image;
clim(max(abs(clim)).*[-1,1]); colormap(ap.colormap('PWG'));
