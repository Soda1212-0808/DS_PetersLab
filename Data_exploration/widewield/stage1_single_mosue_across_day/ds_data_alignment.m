%% Create across-day alignments

% Define animal
 animal = 'DS019';
% Create across-day alignments
plab.wf.wf_align([],animal,[],'new_days');
% Get and save VFS maps for animal
plab.wf.retinotopy_vfs_batch(animal);
% Create across-animal alignments

plab.wf.wf_align([],animal,[],'new_animal');

%% mousecam cross-day aligments

animal='AP029'
ds.mc_align([],animal,[],'new_days');
