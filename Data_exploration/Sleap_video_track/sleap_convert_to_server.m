% 本地数据根目录（按实际修改）
local_root = 'D:\Data process\project_cross_model\face_data\sleap\track_data\pupil';

% server根目录
server_root = plab.locations.server_data_path;

% 获取所有小鼠文件夹（如 AP019）
mouse_dirs = dir(local_root);
mouse_dirs = mouse_dirs([mouse_dirs.isdir]);

% 去掉 . 和 ..
mouse_dirs = mouse_dirs(~ismember({mouse_dirs.name}, {'.', '..'}));

for curr_animal = 1:length(mouse_dirs)
    mouse_name = mouse_dirs(curr_animal).name;
    mouse_path = fullfile(local_root, mouse_name);

    % 找到所有 h5 和 slp 文件
    files_h5 = dir(fullfile(mouse_path, '**', '*.h5'));
    files_slp = dir(fullfile(mouse_path, '**', '*.slp'));

    files = [files_h5; files_slp];

    for j = 1:length(files)
        file_name = files(j).name;
        src_path = fullfile(files(j).folder, file_name);

        % -------------------------
        % 解析文件名
        % 示例：
        % AP019_2024-05-07_Recording_1705_mousecam.analysis.h5
        % -------------------------
        tokens = regexp(file_name, ...
            '([A-Za-z]+\d+)_(\d{4}-\d{2}-\d{2})_Recording_(\d+)', ...
            'tokens');

        if isempty(tokens)
            fprintf('跳过无法解析的文件: %s\n', file_name);
            continue;
        end

        mouse_id = tokens{1}{1};
        date_str = tokens{1}{2};
        rec_time = tokens{1}{3};

        recording_folder = ['Recording_' rec_time];

        % -------------------------
        % 构建 server 目标路径
        % Z:\Data\AP019\2024-05-07\Recording_1705\mousecam\sleap\pupil_v1
        % -------------------------
        dest_path = fullfile(server_root, ...
            mouse_id, ...
            date_str, ...
            recording_folder, ...
            'mousecam', ...
            'sleap', ...
            'pupil_v1');

        % 创建目录（如果不存在）
        if ~exist(dest_path, 'dir')
            mkdir(dest_path);
        end

        % 目标文件路径
        dest_file = fullfile(dest_path, file_name);


         % 如果服务器上已经存在该文件，就跳过
        if exist(dest_file, 'file')
            fprintf('已存在，跳过: %s\n', dest_file);
            continue;
        end

        % 复制文件
        copyfile(src_path, dest_file);

        fprintf('已复制: %s -> %s\n', file_name, dest_path);
    end
end

disp('全部完成！');