
function  sleap_inference(MODEL_DIRS,mousecam_fn,outSLP,outH5)

tStart = tic;
PYTHON_EXE = 'C:\Users\dsong\AppData\Roaming\uv\tools\sleap\Scripts\python.exe';
% Test whether sleap-convert exists in PATH (system 'where' -- Windows)
venvScripts = 'C:\Users\dsong\AppData\Roaming\uv\tools\sleap\Scripts';
sleapConvertExe = fullfile(venvScripts,'sleap-convert.exe');
if exist(sleapConvertExe,'file') == 2
    have_sleap_convert = true;
    fprintf('Found sleap-convert at: %s\n', sleapConvertExe);
else
    have_sleap_convert = false;
    fprintf('sleap-convert not found in venv Scripts (%s). \n', venvScripts);
end

MODEL_command=[ ' --model_paths "' MODEL_DIRS{1} '"'  ' --model_paths "' MODEL_DIRS{2} '"'  ];

% GPU device to use
GPU_DEVICE = 'cuda:0';

% Batch size and tracking options for inference
BATCH_SIZE = 10; % Default in SLEAP is 4
DO_TRACKING = true;

trackFlag = '';
if DO_TRACKING
    trackFlag = ' --tracking';
end

cmdTrack = sprintf('"%s" -m sleap_nn.cli track --data_path "%s" %s --output_path "%s" --device %s --batch_size %d %s --max_instances 1 --ensure_grayscale --robust_best_instance 1 --tracking_window_size 3 --max_tracks 1 --track_matching_method hungarian --post_connect_single_breaks' , ...
    PYTHON_EXE, mousecam_fn, MODEL_command, outSLP, GPU_DEVICE, BATCH_SIZE, trackFlag);

% Clear environment variables that might force CPU
% (This affects only the spawned process)
% Windows: use 'set VAR=' before the command in one line; easier: call via system after clearing in MATLAB environment
setenv('CUDA_VISIBLE_DEVICES','');
setenv('SLEAP_DEVICE','');

fprintf('Running inference command:\n%s\n', cmdTrack);
[st, cmdOut] = system([cmdTrack ' 2>&1']); % capture stderr and stdout
elapsed = toc(tStart);

if st ~= 0
    % Failure
    fprintf('Inference failed for %s\nOutput:\n%s\n', vidPath, cmdOut); 
else
    fprintf('Inference completed. Time: %.1f s\n', elapsed);
end

% Convert SLP -> analysis.h5
convStart = tic;
if have_sleap_convert
    convCmd = sprintf('"%s" --format analysis --output "%s" "%s"', sleapConvertExe, outH5, outSLP);
    [cst, cout] = system([convCmd ' 2>&1']);
else
    fprintf('sleap-convert not found in venv. Unable to convert to HDF5 file. \n');
end
convElapsed = toc(convStart);

if cst ~= 0
    fprintf('Conversion failed for %s\nOutput:\n%s\n', outSLP, cout);
   
else
    fprintf('Conversion succeeded (%.1fs). Output: %s\n', convElapsed, outH5);   
end
