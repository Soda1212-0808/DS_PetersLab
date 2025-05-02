clear all; clc;

%% ---------- 基础设置 ----------
Path = 'D:\Data process\wf_data\';
load(fullfile(plab.locations.server_path, 'Lab', 'widefield_alignment', 'U_master.mat'));
load('C:\Users\dsong\Documents\MATLAB\Da_Song\DS_scripts_ptereslab\General_information\roi.mat')

% 时间窗口设置
surround_samplerate = 35;
t_passive = -0.5:1/surround_samplerate:1;
t_kernels = (1/surround_samplerate)*(-10:30);

% 对应时间段索引
period_passive = find(t_passive > 0 & t_passive < 0.2);
period_kernels = find(t_kernels > 0 & t_kernels < 0.2);

% workflow 名称和颜色设定
all_workflow = {'lcr_passive','hml_passive_audio','lcr_passive_size60'};
Color = {'B','R'};

% 选择使用的组（例：1-Vp-Av, 2-Av-Vp）
select_group = [1 2];
groups = {'Vp-Av','Av-Vp','Vp-Av-n','Av-Vp-n','Vp-Af','Vo-n-Vp','Vs-Vp','Va-Vp'};

% 初始化变量
data_all_video = cell(2,1);
data_all = cell(2,1);
data_type = {'raw','kernels'};

%% ---------- 主循环 ----------
for used_data = 1:2 % raw vs kernel
    for workflow_idx = 1:2
        workflow = all_workflow{workflow_idx};
        
        for curr_group = select_group
            % 动物分组 & 刺激名定义
            switch curr_group
                case 1
                    animals = {'DS007','DS010','AP019','AP021','DS011','AP022'};
                    n1_name = 'visual position'; n2_name = 'audio volume';
                case 2
                    animals = {'DS000','DS004','DS014','DS015','DS016'};
                    n1_name = 'audio volume'; n2_name = 'visual position';
                % 可继续添加更多分组
            end

            n_animals = length(animals);
            if used_data == 1
                use_t = t_passive;
                use_period = period_passive;
            else
                use_t = t_kernels;
                use_period = period_kernels;
            end
            % 初始化数据容器
            all_data_video = cell(n_animals,1);
            matches = cell(n_animals,1);
            all_data_workflow_name = cell(n_animals,1);
            all_data_learned_day = cell(n_animals,1);

            %% ---------- 加载每只动物的数据 ----------
            for curr_animal = 1:n_animals
                animal = animals{curr_animal};
                data_fn = fullfile(Path, workflow, [animal '_' workflow '.mat']);
                raw_data = load(data_fn);

                if used_data == 1
                    idx = cellfun(@(x) ~isempty(x) && size(x,3)==3, raw_data.wf_px);
                    image_all = cellfun(@(x) plab.wf.svd2px(U_master, x), ...
                                        raw_data.wf_px(idx), 'UniformOutput', false);
                else
                    idx = cellfun(@(x) ~isempty(x), raw_data.wf_px_kernels);
                    image_all = cellfun(@(x) plab.wf.svd2px(U_master(:,:,1:size(x,1)), x), ...
                                        raw_data.wf_px_kernels(idx), 'UniformOutput', false);
                end

                % 保存匹配信息
                all_data_video{curr_animal} = image_all;
                all_data_workflow_name{curr_animal} = raw_data.workflow_type_name_merge(idx);
                all_data_learned_day{curr_animal} = raw_data.learned_day(idx);
                matches{curr_animal} = unique(raw_data.workflow_type_name_merge(idx), 'stable');
            end

            %% ---------- 数据分类（naive、pre/post-learn 等） ----------
            % 统一构造一个函数用于提取指定类型数据
            extract_trials = @(match_name, is_learned, n_trial, mode) ...
                cellfun(@(x,y,z,l) ...
                    get_trials(x, y, z, l, match_name, is_learned, n_trial, mode), ...
                    all_data_video, all_data_workflow_name, matches, all_data_learned_day, ...
                    'UniformOutput', false);

            naive_data = extract_naive_trials(all_data_video, all_data_workflow_name, matches, use_t);
            pre_learn_data0 = extract_trials(n1_name, 0, Inf, 'avg-exclude-last-2');
            pre_learn_data1 = extract_trials(n1_name, 0, 2, 'last');
            post_learn1_data1 = extract_trials(n1_name, 1, 2, 'first');
            post_learn2_data1 = extract_trials(n1_name, 1, 3, 'after-first-2');
            pre_learn_data2 = extract_trials(n2_name, 0, 2, 'first');
            post_learn1_data2 = extract_trials(n2_name, 1, 2, 'first');
            post_learn2_data2 = extract_trials(n2_name, 1, 3, 'after-first-2');
            data3 = extract_trials('mixed VA', NaN, 3, 'last');

            %% ---------- 汇总 ----------
            all_data = cellfun(@(a0,a,b,c,d,e,f,g,h) ...
                [a0;a;b;c;d;e;f;g;h], ...
                naive_data, pre_learn_data0, pre_learn_data1, post_learn1_data1, ...
                post_learn2_data1, pre_learn_data2, post_learn1_data2, ...
                post_learn2_data2, data3, 'UniformOutput', false);

            all_data_image = cellfun(@(x) nanmean(cat(5,x{:}),5), ...
                {naive_data, pre_learn_data0, pre_learn_data1, post_learn1_data1, ...
                post_learn2_data1, pre_learn_data2, post_learn1_data2, ...
                post_learn2_data2, data3}, 'UniformOutput', false);
            
            all_data_image1 = cellfun(@(x) cat(5,x{:}), all_data_image, 'UniformOutput', false);
            all_data_image2 = cat(6, all_data_image1{:});
            
            % 保存
            data_all{curr_group}{used_data}{workflow_idx} = all_data;
            data_all_video{curr_group}{used_data}{workflow_idx} = all_data_image2;
        end
    end
end

function result = get_trials(data, names, match_list, learned, match_name, learn_flag, n, mode)
    idx = find(cellfun(@(x) strcmp(x, match_name), match_list, 'UniformOutput', true));
    match_idx = find(strcmp(names, match_list(idx)));
    valid_idx = match_idx(learned(match_idx) == learn_flag);
    
    switch mode
        case 'avg-exclude-last-2'
            result = mean(cat(4, data{valid_idx(1:end-2)}), 4);
            result = {result};
        case 'first'
            result = data(valid_idx(1:min(n,end)));
        case 'last'
            result = data(valid_idx(max(end-n+1,1):end));
        case 'after-first-2'
            result = data(valid_idx(3:end));
        otherwise
            result = data(valid_idx(1:min(n,end)));
    end
    
    % 补齐
    if isempty(result)
        result = repmat({nan(450,426,length(learned),3)}, n, 1);
    elseif length(result) < n
        result = [result; repmat({nan(450,426,length(learned),3)}, n - length(result), 1)];
    end
end

function naive = extract_naive_trials(data_video, names, matches, use_t)
    n = length(data_video);
    naive = cell(n,1);
    for i = 1:n
        if any(strcmp('naive', matches{i}))
            idx = find(strcmp(names{i}, 'naive'), 3, 'first');
            naive{i} = data_video{i}(idx);
        else
            naive{i} = repmat({nan(450,426,length(use_t),3)}, 3, 1);
        end
        if length(naive{i}) < 3
            naive{i} = [naive{i}; repmat({nan(450,426,length(use_t),3)}, 3-length(naive{i}), 1)];
        end
    end
end