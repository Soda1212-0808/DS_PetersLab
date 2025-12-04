

%% Align facecam frames (nose/eye control point)

% Overwrite, or add to existing data
overwrite_flag = false;

% Load facecam sample frames
facecam_processing_path = 'C:\Users\Andrew\OneDrive for Business\Documents\CarandiniHarrisLab\analysis\operant_learning\facecam_processing';
facecam_align_fn = fullfile(facecam_processing_path,'facecam_align.mat');
load(facecam_align_fn);

% Get days without tform to align (or all if overwriting)
if ~overwrite_flag
    im_cat = {facecam_align.im};
    tform_cat = {facecam_align.tform};
    tform_cat_pad = cellfun(@(im,tform) ...
        [tform;cell(length(im)-length(tform),1)],im_cat,tform_cat,'uni',false);
    align_days = find(cellfun(@(im,tform) ~isempty(im) & isempty(tform), ...
        horzcat(im_cat{:}),vertcat(tform_cat_pad{:})'));
else
    align_days = 1:length(length([facecam_align.im]));
end

% Plot images and select control points
im_unaligned = cellfun(@double,[facecam_align.im],'uni',false);

target_im = im_unaligned{1};
target_size = size(target_im);

figure;
target_ax = subplot(1,2,1);
imagesc(target_im);
axis image off; hold on;
source_ax = subplot(1,2,2);
source_h = imagesc([]);
axis image off; hold on;

title(target_ax,'Click: nose end, eye center');
target_ctrl_points = ginput(2);
plot(target_ax,target_ctrl_points(:,1),target_ctrl_points(:,2),'.r','MarkerSize',20);
title(target_ax,'');

im_aligned = nan(target_size(1),target_size(2),length(im_unaligned));
source_ctrl_points = cell(length(im_unaligned),1);
if overwrite_flag
    cam_tform = cell(length(im_unaligned),1);
else
    cam_tform = vertcat(tform_cat_pad{:});
end
for curr_im = align_days
    source_im = im_unaligned{curr_im};
    if isempty(source_im)
        continue
    end

    % Click control points
    title(source_ax,{['Click: nose eye'], ...
        [sprintf('%d/%d',curr_im,length(im_unaligned))]});
    set(source_h,'CData',source_im);
    source_ctrl_points{curr_im} = ginput(2);

    % Store tform
    cam_tform{curr_im} = fitgeotrans(source_ctrl_points{curr_im}, ...
        target_ctrl_points,'nonreflectivesimilarity');
    
    tform_size = imref2d(target_size);
    im_aligned(:,:,curr_im) = ...
        imwarp(source_im,cam_tform{curr_im},'OutputView',tform_size);

end
close(gcf);

% Plot aligned
AP_imscroll(im_aligned); axis image

% Save transform (into original struct)
% (package back into animals)
n_days_animal = cellfun(@length,{facecam_align.day});
cam_tform_animal = mat2cell(cam_tform,n_days_animal);
[facecam_align.tform] = cam_tform_animal{:};

save(facecam_align_fn,'facecam_align');
disp(['Saved: ' facecam_align_fn]);