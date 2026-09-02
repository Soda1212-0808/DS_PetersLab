function cellraster_multi(align_times,align_groups,workflows)
% cellraster_multi(align_times,align_groups)
%
% Multi-task raster viewer for Neuropixels
%
% align_times  - cell array, one element per task
% align_groups - cell array, one element per task
%
% Each task is displayed as one column:
%
%       Task 1       Task 2       Task 3       ...
%     -----------  -----------  ----------- 
% PSTH|           |           |           |
%     -----------  -----------  -----------
% raster          |           |           |
%                 |           |           |
%
% All tasks share:
%   - current unit
%   - multiunit selection
%   - group
%   - peri-event time window
%
% Controls:
%   up/down       switch units
%   pageup/down   switch trial group
%   m             select multiunit by depth
%   u             go to unit number
%   t             change peri-event time window
%
% Required variables in base workspace:
%   templates
%   channel_positions
%   template_tipdist
%   spike_times_timelite
%   spike_templates
%   template_amplitudes

%% ---------------------------------------------------------------
% Input
% ---------------------------------------------------------------

if ~exist('align_times','var')
    error('No align times');
end

% Make align_times a row cell array
if ~iscell(align_times)
    align_times = {align_times};
end

align_times = reshape( ...
    cellfun(@(x) reshape(x,[],1),align_times,'uni',false), ...
    1,[]);

n_tasks = numel(align_times);

% Workflow names
if nargin < 3 || isempty(workflows)
    workflows = arrayfun( ...
        @(x) sprintf('Task %d',x), ...
        1:n_tasks, ...
        'uni',false);
else
    workflows = reshape(workflows,1,[]);

    if numel(workflows) ~= n_tasks
        error('Number of workflows must match number of align_times');
    end
end

%% ---------------------------------------------------------------
% Align groups
% ---------------------------------------------------------------

if nargin < 2 || isempty(align_groups)

    align_groups = cellfun( ...
        @(x) ones(size(x,1),1), ...
        align_times, ...
        'uni',false);

elseif ~iscell(align_groups)

    align_groups = {align_groups};

end

align_groups = reshape(align_groups,1,[]);

% If only one grouping was given, use it for all tasks
if n_tasks > 1 && isscalar(align_groups)

    align_groups = repmat(align_groups,1,n_tasks);

elseif length(align_groups) ~= n_tasks

    error('Number of align_groups must match number of align_times');

end

% Standardize dimensions and make sure number of rows matches trials
for iTask = 1:n_tasks

    this_groups = align_groups{iTask};

    % Force column if vector
    this_groups = reshape(this_groups,[],size(this_groups,2));

    if size(this_groups,1) ~= numel(align_times{iTask})

        if size(this_groups,2) == numel(align_times{iTask})
            this_groups = this_groups';
        else
            error( ...
                'Task %d: number of align_groups does not match align_times', ...
                iTask);
        end
    end

    % Add group=1 as first category if necessary
    if isempty(this_groups)
        this_groups = ones(numel(align_times{iTask}),1);
    elseif ~all(this_groups(:,1) == 1)
        this_groups = [ones(size(this_groups,1),1), this_groups];
    end

    align_groups{iTask} = this_groups;

end

%% ---------------------------------------------------------------
% Load ephys variables
% ---------------------------------------------------------------

try

    templates = evalin('base','templates');
    channel_positions = evalin('base','channel_positions');
    template_tipdist = evalin('base','template_tipdist'); %#ok<NASGU>
    spike_times = evalin('base','multi_spike_timelite');

    if ~iscell(spike_times)
        spike_times = {spike_times};
    end

    spike_times = reshape(spike_times,1,[]);

    if numel(spike_times) ~= n_tasks
        error('Number of spike_times_timelite cells must match number of tasks');
    end


    spike_templates = evalin('base','spike_templates');
    template_amplitudes = evalin('base','template_amplitudes');

catch me

    error( ...
        'Ephys variable missing from base workspace:\n%s', ...
        me.message);

end

spike_templates = double(spike_templates);

%% ---------------------------------------------------------------
% Figure
% ---------------------------------------------------------------

% Layout:
%
%  | unit plot | waveform | Task1 PSTH | Task2 PSTH | ...
%  |           |          | Task1 raster| Task2 raster| ...
%  | amplitude axis spanning whole figure               |
%

n_col = n_tasks + 2;

cellraster_gui = figure( ...
    'Color','w', ...
    'Units','normalized', ...
    'Position',[0.01,0.08,0.98,0.82], ...
    'Name','cellraster multi-task', ...
    'NumberTitle','off');

tl = tiledlayout(cellraster_gui,3,n_col, ...
    'TileSpacing','tight', ...
    'Padding','compact');

%% ---------------------------------------------------------------
% Unit depth/rate
% ---------------------------------------------------------------

unit_axes = nexttile(tl,1,[2,1]);

unit_depthrate_handles = ...
    ap.plot_unit_depthrate(unit_axes,false);

unit_depthrate_handles.unit_dots.ButtonDownFcn = @unit_click;

unit_selected = scatter( ...
    unit_axes, ...
    nan,nan, ...
    20, ...
    'r', ...
    'LineWidth',2);

%% ---------------------------------------------------------------
% Waveform
% ---------------------------------------------------------------

waveform_axes = nexttile(tl,2,[2,1]);

set(waveform_axes, ...
    'Visible','off', ...
    'YDir','reverse');

hold(waveform_axes,'on');

ylim(waveform_axes, ...
    [-50,max(channel_positions(:,2))+50]);

waveform_lines = plot( ...
    waveform_axes, ...
    0,0, ...
    'k', ...
    'LineWidth',1);

%% ---------------------------------------------------------------
% Task axes
% ---------------------------------------------------------------

psth_axes = gobjects(n_tasks,1);
raster_axes = gobjects(n_tasks,1);

raster_dots = gobjects(n_tasks,1);
raster_image = gobjects(n_tasks,1);

for iTask = 1:n_tasks

    % Top row
    psth_tile = 2 + iTask;

    psth_axes(iTask) = nexttile(tl,psth_tile);

    hold(psth_axes(iTask),'on');

    set(psth_axes(iTask), ...
        'YAxisLocation','right');

    xlabel(psth_axes(iTask),'Time (s)');
    ylabel(psth_axes(iTask),'Spikes/s/trial');

    title( ...
        psth_axes(iTask), ...
        sprintf('Task %d',iTask), ...
        'FontSize',12, ...
        'FontWeight','bold');

    % Bottom row
    raster_tile = n_col + 2 + iTask;

    raster_axes(iTask) = nexttile(tl,raster_tile);

    set(raster_axes(iTask), ...
        'YDir','reverse', ...
        'YAxisLocation','right');

    hold(raster_axes(iTask),'on');

    raster_dots(iTask) = scatter( ...
        raster_axes(iTask), ...
        NaN,NaN, ...
        5, ...
        'k', ...
        'filled');

    raster_image(iTask) = imagesc( ...
        raster_axes(iTask), ...
        NaN, ...
        'Visible','off');

    colormap( ...
        raster_axes(iTask), ...
        ap.colormap('WK',[],1));

    xlabel(raster_axes(iTask),'Time from event (s)');
    ylabel(raster_axes(iTask),'Trial');

end

%% ---------------------------------------------------------------
% Amplitude plot
% ---------------------------------------------------------------

amplitude_axes = nexttile( ...
    tl, ...
    2*n_col + 1,[1,n_col]);

hold(amplitude_axes,'on');

amplitude_plot = plot( ...
    amplitude_axes, ...
    NaN,NaN, ...
    '.k');

amplitude_lines = xline( ...
    amplitude_axes, ...
    [0,0], ...
    'LineWidth',2, ...
    'Color','r');

xlabel(amplitude_axes,'Experiment time (s)');
ylabel(amplitude_axes,'Template amplitude');

axis(amplitude_axes,'tight');

%% ---------------------------------------------------------------
% Default raster time
% ---------------------------------------------------------------

raster_window = [-0.5,2];

psth_bin_size = 0.001;

t_bins = raster_window(1): ...
    psth_bin_size: ...
    raster_window(2);

t = t_bins(1:end-1) + diff(t_bins)./2;

t_peri_event = cell(1,n_tasks);

for iTask = 1:n_tasks

    use_align = reshape( ...
        align_times{iTask},[],1);

    temp = use_align + t_bins;

    % Keep same behavior as original cellraster
    temp(any(isnan(temp),2),:) = 0;

    t_peri_event{iTask} = temp;

end

%% ---------------------------------------------------------------
% GUI data
% ---------------------------------------------------------------

gui_data = struct;

% plots
gui_data.unit_depthrate_handles = unit_depthrate_handles;
gui_data.unit_selected = unit_selected;
gui_data.waveform_lines = waveform_lines;

gui_data.psth_axes = psth_axes;
gui_data.raster_axes = raster_axes;

gui_data.raster_dots = raster_dots;
gui_data.raster_image = raster_image;

gui_data.amplitude_axes = amplitude_axes;
gui_data.amplitude_plot = amplitude_plot;
gui_data.amplitude_lines = amplitude_lines;

% raster timing
gui_data.t = t;
gui_data.t_bins = t_bins;
gui_data.t_peri_event = t_peri_event;

% task data
gui_data.align_times = align_times;
gui_data.align_groups = align_groups;
gui_data.n_tasks = n_tasks;
gui_data.workflows = workflows;

% spike data
gui_data.templates = templates;
gui_data.channel_positions = channel_positions;
gui_data.spike_times = spike_times;
gui_data.spike_templates = spike_templates;
gui_data.template_amplitudes = template_amplitudes;

% current state
gui_data.curr_unit = double(spike_templates(1));
gui_data.curr_group = 1;

% Figure key callback
set(cellraster_gui, ...
    'KeyReleaseFcn',@key_press);

guidata(cellraster_gui,gui_data);

%% ---------------------------------------------------------------
% Initial plot
% ---------------------------------------------------------------

update_plot(cellraster_gui);

end


%% =================================================================
% UPDATE PLOT
% =================================================================

function update_plot(cellraster_gui,~)

gui_data = guidata(cellraster_gui);

%% ---------------------------------------------------------------
% Unit selection indicator
% ---------------------------------------------------------------

curr_unit_unique_idx = ...
    ismember( ...
        unique(gui_data.spike_templates), ...
        gui_data.curr_unit);

set( ...
    gui_data.unit_selected, ...
    'XData', ...
    gui_data.unit_depthrate_handles.unit_dots.XData(curr_unit_unique_idx), ...
    'YData', ...
    gui_data.unit_depthrate_handles.unit_dots.YData(curr_unit_unique_idx));

%% ---------------------------------------------------------------
% Waveform
% ---------------------------------------------------------------

template_xscale = 3;
template_yscale = 0.01;
plot_frac_max = 0.1;

max_amp = max( ...
    abs(gui_data.templates(gui_data.curr_unit,:,:)), ...
    [],2);

template_plot_channels = find( ...
    any( ...
        max_amp > max(max_amp*plot_frac_max,[],'all'), ...
        1));

if isempty(template_plot_channels)

    set(gui_data.waveform_lines, ...
        'XData',NaN, ...
        'YData',NaN);

else

    template_y = permute( ...
        -gui_data.templates( ...
            gui_data.curr_unit,:,template_plot_channels) ...
        * template_yscale ...
        + permute( ...
            gui_data.channel_positions(template_plot_channels,2), ...
            [3,2,1]), ...
        [2,3,1]);

    template_x = repmat( ...
        (1:size(gui_data.templates,2))' ...
        + gui_data.channel_positions( ...
            template_plot_channels,1)' ...
        * template_xscale, ...
        [1,1,length(gui_data.curr_unit)]);

    set(gui_data.waveform_lines, ...
        'XData', ...
        reshape( ...
            padarray(template_x,[1,0],NaN,'post'), ...
            [],1), ...
        'YData', ...
        reshape( ...
            padarray(template_y,[1,0],NaN,'post'), ...
            [],1));

end

axis(gui_data.waveform_lines(1).Parent,'tight');

%% ---------------------------------------------------------------
% Plot all tasks
% ---------------------------------------------------------------

all_psth = cell(gui_data.n_tasks,1);

% First calculate and plot each task
for iTask = 1:gui_data.n_tasks

    [all_psth{iTask}, group_colors] = ...
        plot_task(gui_data,iTask);

end

% ---------------------------------------------------------------
% Use one common Y-axis for all PSTHs
% ---------------------------------------------------------------

all_psth_values = [];

for iTask = 1:gui_data.n_tasks

    if ~isempty(all_psth{iTask})
        all_psth_values = ...
            [all_psth_values; all_psth{iTask}(:)]; %#ok<AGROW>
    end

end

if ~isempty(all_psth_values)

    y_min = min(all_psth_values);
    y_max = max(all_psth_values);

    % Avoid zero-height axis
    if y_min == y_max
        y_max = y_min + 1;
    end

    % Optional: leave a little headroom
    y_range = y_max - y_min;
    y_lim = [ ...
        y_min - 0.05*y_range, ...
        y_max + 0.05*y_range];

    for iTask = 1:gui_data.n_tasks

        ylim( ...
            gui_data.psth_axes(iTask), ...
            y_lim);

    end

end

%% ---------------------------------------------------------------
% Amplitude over entire experiment
% ---------------------------------------------------------------

curr_spikes_idx = ...
    ismember( ...
        gui_data.spike_templates, ...
        gui_data.curr_unit);

if isscalar(gui_data.curr_unit)

    set( ...
        gui_data.amplitude_plot, ...
        'XData', ...
        gui_data.spike_times{end}(curr_spikes_idx), ...
        'YData', ...
        gui_data.template_amplitudes(curr_spikes_idx), ...
        'LineStyle','none');

else

    long_bin_size = 60;

    long_bins = ...
        gui_data.spike_times{end}(1): ...
        long_bin_size: ...
        gui_data.spike_times{end}(end);

    if numel(long_bins) < 2

        set(gui_data.amplitude_plot, ...
            'XData',NaN, ...
            'YData',NaN);

    else

        long_bins_t = ...
            long_bins(1:end-1) + ...
            diff(long_bins)/2;

        long_spikes_binned = ...
            discretize(gui_data.spike_times{end},long_bins);

        valid_amp_idx = ...
            curr_spikes_idx & ...
            ~isnan(long_spikes_binned);

        amplitude_binned = accumarray( ...
            long_spikes_binned(valid_amp_idx), ...
            gui_data.template_amplitudes(valid_amp_idx), ...
            size(long_bins_t'), ...
            @nansum, ...
            NaN);

        set( ...
            gui_data.amplitude_plot, ...
            'XData',long_bins_t, ...
            'YData',amplitude_binned, ...
            'LineStyle','-');

    end

end

%% ---------------------------------------------------------------
% Alignment markers
% ---------------------------------------------------------------

for iTask = 1:gui_data.n_tasks

    gui_data.amplitude_lines(1).Value = ...
        min(cellfun(@(x) min(x(:)),gui_data.t_peri_event));

    gui_data.amplitude_lines(2).Value = ...
        max(cellfun(@(x) max(x(:)),gui_data.t_peri_event));

end

drawnow;

end


%% =================================================================
% PLOT ONE TASK
% =================================================================

function [curr_smoothed_psth,group_colors] = plot_task(gui_data,iTask)

%% ---------------------------------------------------------------
% Get current task data
% ---------------------------------------------------------------

curr_group_all = ...
    gui_data.align_groups{iTask};

% Current group
if gui_data.curr_group > size(curr_group_all,2)
    curr_group_idx = 1;
else
    curr_group_idx = gui_data.curr_group;
end

curr_group = ...
    curr_group_all(:,curr_group_idx);

t_peri_event = ...
    gui_data.t_peri_event{iTask};

%% ---------------------------------------------------------------
% Current spike times
% ---------------------------------------------------------------

curr_spikes_idx = ...
    ismember( ...
        gui_data.spike_templates, ...
        gui_data.curr_unit);

curr_raster_spike_times = ...
    gui_data.spike_times{iTask}(curr_spikes_idx);

% Only use spikes in current task's window
min_time = min(t_peri_event(:));
max_time = max(t_peri_event(:));

curr_raster_spike_times( ...
    curr_raster_spike_times < min_time | ...
    curr_raster_spike_times > max_time) = [];

%% ---------------------------------------------------------------
% Raster binning
% ---------------------------------------------------------------

n_trials = size(t_peri_event,1);

curr_raster = zeros( ...
    n_trials, ...
    length(gui_data.t_bins)-1);

for iTrial = 1:n_trials

    if all(isnan(gui_data.align_times{iTask}(iTrial)))

        continue;

    end

    % histcounts expects edges
    curr_raster(iTrial,:) = ...
        histcounts( ...
            curr_raster_spike_times, ...
            t_peri_event(iTrial,:));

end

%% ---------------------------------------------------------------
% Group colors
% ---------------------------------------------------------------

[group_colors,curr_group_for_plot,trial_sort] = ...
    get_group_colors(curr_group);

%% ---------------------------------------------------------------
% PSTH
% ---------------------------------------------------------------

bin_t = mean(diff(gui_data.t));

unique_groups = unique(curr_group_for_plot,'sorted');

curr_psth = zeros( ...
    length(unique_groups), ...
    size(curr_raster,2));

for iGroup = 1:length(unique_groups)

    idx = curr_group_for_plot == unique_groups(iGroup);

    if any(idx)

        curr_psth(iGroup,:) = ...
            mean(curr_raster(idx,:),1) ./ bin_t;

    end

end

% smooth
smooth_size = 100;

curr_smoothed_psth = ...
    smoothdata( ...
        curr_psth, ...
        2, ...
        'gaussian', ...
        [smooth_size,0]);

cla(gui_data.psth_axes(iTask));

hold(gui_data.psth_axes(iTask),'on');

set(gui_data.psth_axes(iTask), ...
    'ColorOrder',group_colors);

plot( ...
    gui_data.psth_axes(iTask), ...
    gui_data.t, ...
    curr_smoothed_psth', ...
    'LineWidth',2);

if ~isempty(curr_smoothed_psth)

    ymin = min(curr_smoothed_psth(:));
    ymax = max(curr_smoothed_psth(:));

    if ymin == ymax
        ymax = ymin + 1;
    end

    ylim( ...
        gui_data.psth_axes(iTask), ...
        [ymin,max(ymax,ymin+1)]);

end

if isscalar(gui_data.curr_unit)

  title( ...
    gui_data.psth_axes(iTask), ...
    sprintf( ...
    '%s | Unit %d | Group %d', ...
    gui_data.workflows{iTask}, ...
    gui_data.curr_unit, ...
    curr_group_idx), ...
    'FontSize',11);

else

     title( ...
        gui_data.psth_axes(iTask), ...
        sprintf( ...
        '%s | Multiunit', ...
        gui_data.workflows{iTask}), ...
        'FontSize',11);

end

%% ---------------------------------------------------------------
% Raster
% ---------------------------------------------------------------

curr_raster_sorted = ...
    curr_raster(trial_sort,:);

if all(trial_sort(:)' == 1:length(trial_sort))

    ylabel( ...
        gui_data.raster_axes(iTask), ...
        'Trial');

else

    ylabel( ...
        gui_data.raster_axes(iTask), ...
        'Sorted trial');

end

if isscalar(gui_data.curr_unit)

    % -----------------------------------
    % Single unit raster
    % -----------------------------------

    set( ...
        gui_data.raster_dots(iTask), ...
        'Visible','on');

    set( ...
        gui_data.raster_image(iTask), ...
        'Visible','off');

    [raster_y,raster_x] = ...
        find(curr_raster_sorted);

    set( ...
        gui_data.raster_dots(iTask), ...
        'XData', ...
        gui_data.t(raster_x), ...
        'YData', ...
        raster_y);

    xlim( ...
        gui_data.raster_axes(iTask), ...
        [gui_data.t_bins(1),gui_data.t_bins(end)]);

    ylim( ...
        gui_data.raster_axes(iTask), ...
        [0,size(t_peri_event,1)]);

    [~,~,row_group] = ...
        unique(curr_group_for_plot(trial_sort),'sorted');

    if ~isempty(raster_y)

        raster_dot_color = ...
            group_colors(row_group(raster_y),:);

        set( ...
            gui_data.raster_dots(iTask), ...
            'CData', ...
            raster_dot_color);

    end

else

    % -----------------------------------
    % Multiunit
    % -----------------------------------

    set( ...
        gui_data.raster_dots(iTask), ...
        'Visible','off');

    set( ...
        gui_data.raster_image(iTask), ...
        'Visible','on');

    raster_heatmap = ...
        smoothdata( ...
            curr_raster_sorted, ...
            2, ...
            'gaussian', ...
            smooth_size);

    set( ...
        gui_data.raster_image(iTask), ...
        'XData',gui_data.t, ...
        'YData',1:size(t_peri_event,1), ...
        'CData',raster_heatmap);

    axis( ...
        gui_data.raster_image(iTask).Parent, ...
        'tight');

    if any(raster_heatmap(:))

        clim( ...
            gui_data.raster_axes(iTask), ...
            prctile( ...
                raster_heatmap, ...
                [0,99.9], ...
                'all'));

    end

end

end


%% =================================================================
% GROUP COLOR
% =================================================================

function [group_colors,curr_group,trial_sort] = ...
    get_group_colors(curr_group)

u_group = unique(curr_group);

% ---------------------------------
% One group
% ---------------------------------

if isscalar(u_group)

    group_colors = [0,0,0];

    trial_sort = ...
        (1:length(curr_group))';

    curr_group = ...
        ones(size(curr_group));

% ---------------------------------
% Every trial is unique
% ---------------------------------

elseif length(u_group) == length(curr_group)

    group_colors = [0,0,0];

    [~,trial_sort] = sort(curr_group);

    curr_group = ...
        ones(size(curr_group));

% ---------------------------------
% All groups positive
% ---------------------------------

elseif isscalar(unique(sign(curr_group(curr_group ~= 0))))

    n_groups = length(u_group);

    group_colors = lines(n_groups);

    [~,trial_sort] = sort(curr_group);

% ---------------------------------
% Negative / zero / positive
% ---------------------------------

elseif length( ...
        unique(sign(curr_group(curr_group ~= 0)))) == 2

    n_groups_pos = ...
        length(unique(curr_group(curr_group > 0)));

    group_colors_pos = ...
        [linspace(0.3,1,n_groups_pos)', ...
         zeros(n_groups_pos,1), ...
         zeros(n_groups_pos,1)];

    n_groups_neg = ...
        length(unique(curr_group(curr_group < 0)));

    group_colors_neg = ...
        [zeros(n_groups_neg,1), ...
         zeros(n_groups_neg,1), ...
         linspace(0.3,1,n_groups_neg)'];

    n_groups_zero = ...
        length(unique(curr_group(curr_group == 0)));

    group_colors_zero = ...
        [zeros(n_groups_zero,1), ...
         zeros(n_groups_zero,1), ...
         zeros(n_groups_zero,1)];

    group_colors = ...
        [flipud(group_colors_neg); ...
         group_colors_zero; ...
         group_colors_pos];

    [~,trial_sort] = sort(curr_group);

% ---------------------------------
% Fallback
% ---------------------------------

else

    n_groups = length(u_group);

    group_colors = lines(n_groups);

    [~,trial_sort] = sort(curr_group);

end

end


%% =================================================================
% KEYBOARD CONTROL
% =================================================================

function key_press(cellraster_gui,eventdata)

gui_data = guidata(cellraster_gui);

switch eventdata.Key

    %% -----------------------------------------------------------
    % Down: next unit
    % -----------------------------------------------------------

    case 'downarrow'

        template_tipdist = ...
            get( ...
                gui_data.unit_depthrate_handles.unit_dots, ...
                'YData');

        template_id = ...
            1:length(template_tipdist);

        template_shanks = ...
            gui_data.unit_depthrate_handles.unit_dots.UserData.shank;

        % Current unit might be a multiunit
        curr_unit_for_shank = ...
            gui_data.curr_unit(1);

        curr_shank = ...
            unique(template_shanks(curr_unit_for_shank));

        use_templates = ...
            ismember(template_shanks,curr_shank);

        depth_sort = ...
            sortrows( ...
                [template_tipdist(use_templates)', ...
                 template_id(use_templates)'], ...
                1);

        current_idx = ...
            find( ...
                ismember( ...
                    depth_sort(:,2), ...
                    gui_data.curr_unit(1)), ...
                1);

        if isempty(current_idx)
            current_idx = 1;
        end

        new_idx = current_idx + 1;

        if new_idx > size(depth_sort,1)
            new_idx = 1;
        end

        gui_data.curr_unit = ...
            depth_sort(new_idx,2);

    %% -----------------------------------------------------------
    % Up: previous unit
    % -----------------------------------------------------------

    case 'uparrow'

        template_tipdist = ...
            get( ...
                gui_data.unit_depthrate_handles.unit_dots, ...
                'YData');

        template_id = ...
            1:length(template_tipdist);

        template_shanks = ...
            gui_data.unit_depthrate_handles.unit_dots.UserData.shank;

        curr_unit_for_shank = ...
            gui_data.curr_unit(1);

        curr_shank = ...
            unique(template_shanks(curr_unit_for_shank));

        use_templates = ...
            ismember(template_shanks,curr_shank);

        depth_sort = ...
            sortrows( ...
                [template_tipdist(use_templates)', ...
                 template_id(use_templates)'], ...
                1);

        current_idx = ...
            find( ...
                ismember( ...
                    depth_sort(:,2), ...
                    gui_data.curr_unit(1)), ...
                1);

        if isempty(current_idx)
            current_idx = 1;
        end

        new_idx = current_idx - 1;

        if new_idx < 1
            new_idx = size(depth_sort,1);
        end

        gui_data.curr_unit = ...
            depth_sort(new_idx,2);

    %% -----------------------------------------------------------
    % Next group
    % -----------------------------------------------------------

    case {'pagedown','space'}

        % Use the maximum number of groups across tasks
        n_groups = max( ...
            cellfun( ...
                @(x) size(x,2), ...
                gui_data.align_groups));

        next_group = ...
            gui_data.curr_group + 1;

        if next_group > n_groups
            next_group = 1;
        end

        gui_data.curr_group = next_group;

    %% -----------------------------------------------------------
    % Previous group
    % -----------------------------------------------------------

    case 'pageup'

        n_groups = max( ...
            cellfun( ...
                @(x) size(x,2), ...
                gui_data.align_groups));

        next_group = ...
            gui_data.curr_group - 1;

        if next_group < 1
            next_group = n_groups;
        end

        gui_data.curr_group = next_group;

    %% -----------------------------------------------------------
    % Multiunit
    % -----------------------------------------------------------

    case 'm'

        unit_roi = ...
            drawrectangle( ...
                gui_data.unit_depthrate_handles.unit_dots.Parent);

        unit_bounds = ...
            unit_roi.Position(1:2) + ...
            [0,0;unit_roi.Position(3:4)];

        selected_units = ...
            isbetween( ...
                gui_data.unit_depthrate_handles.unit_dots.XData, ...
                unit_bounds(1,1), ...
                unit_bounds(2,1)) & ...
            isbetween( ...
                gui_data.unit_depthrate_handles.unit_dots.YData, ...
                unit_bounds(1,2), ...
                unit_bounds(2,2));

        delete(unit_roi);

        gui_data.curr_unit = ...
            find(selected_units);

        if isempty(gui_data.curr_unit)

            warning('No units selected');

            return;

        end

    %% -----------------------------------------------------------
    % Go to unit
    % -----------------------------------------------------------

    case 'u'

        answer = ...
            inputdlg('Go to unit:');

        if isempty(answer)
            return;
        end

        new_unit = str2double(answer{1});

        if ~ismember( ...
                new_unit, ...
                unique(gui_data.spike_templates))

            error( ...
                'Unit %d not present', ...
                new_unit);

        else

            gui_data.curr_unit = new_unit;

        end

    %% -----------------------------------------------------------
    % Change time window
    % -----------------------------------------------------------

    case 't'

        answer = ...
            inputdlg( ...
                'Peri-event times:', ...
                'Change raster window', ...
                1, ...
                {'[-0.5 2]'});

        if isempty(answer)
            return;
        end

        raster_window = ...
            str2num(answer{1}); %#ok<ST2NM>

        if numel(raster_window) ~= 2 || ...
                raster_window(1) >= raster_window(2)

            error( ...
                'Time window must be [start end]');

        end

        psth_bin_size = 0.001;

        t_bins = ...
            raster_window(1): ...
            psth_bin_size: ...
            raster_window(2);

        t = ...
            t_bins(1:end-1) + ...
            diff(t_bins)./2;

        t_peri_event = ...
            cell(1,gui_data.n_tasks);

        for iTask = 1:gui_data.n_tasks

            use_align = ...
                reshape( ...
                    gui_data.align_times{iTask}, ...
                    [],1);

            temp = ...
                use_align + t_bins;

            temp(any(isnan(temp),2),:) = 0;

            t_peri_event{iTask} = temp;

        end

        gui_data.t = t;
        gui_data.t_bins = t_bins;
        gui_data.t_peri_event = t_peri_event;

end

guidata(cellraster_gui,gui_data);

update_plot(cellraster_gui);

end


%% =================================================================
% UNIT CLICK
% =================================================================

function unit_click(~,eventdata)

% eventdata contains clicked location.
fig = ancestor(eventdata.Source,'figure');

gui_data = guidata(fig);

unit_x = ...
    get( ...
        gui_data.unit_depthrate_handles.unit_dots, ...
        'XData');

unit_y = ...
    get( ...
        gui_data.unit_depthrate_handles.unit_dots, ...
        'YData');

[~,clicked_unit] = ...
    min( ...
        sqrt( ...
            sum( ...
                ([unit_x;unit_y] - ...
                eventdata.IntersectionPoint(1:2)').^2, ...
                1)));

gui_data.curr_unit = clicked_unit;

guidata(fig,gui_data);

update_plot(fig);

end