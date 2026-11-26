function axesHandles = fcn_CarMesh3D_assessAxes(parent, numViews, options)
% fcn_CarMesh3D_assessAxes
% The pictures of a V&V assessment, side by side: numViews axes in a row,
% each with its caption, in the panel the V&V GUI gives (Parent), or, when
% an assessment is run by itself at the prompt (no Parent), in a figure of
% its own. A common helper of the assessment functions
% (fcn_CarMesh3D_assess_*), so every assessment's pictures look alike
% (rule G9 and P1: GUIs alike).
%
% FORMAT:
%
%       axesHandles = fcn_CarMesh3D_assessAxes(parent, numViews,...
%           (Captions=captions), (Dark=flag), (Legend=entries),...
%           (Rows=numRows), (RowLabels=labels), (FigNum=figNum))
%
% INPUTS:
%
%      parent: the panel to draw in (a uipanel), or [] for a figure of its
%      own.
%
%      numViews: how many pictures (1 to 4 in a row; up to 8 in two rows).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Captions: a caption under each picture (a cell array of text);
%      default none.
%
%      Dark: true for a dark background (night, for lit lamps); default
%      false (white).
%
%      Legend: color swatches with names, in one line under the pictures:
%      a structure array with Name and Color (such as the second output
%      of fcn_CarMesh3D_plotLabels); default none (Sean, T62: a simple
%      legend of the label colors).
%
%      Rows: 1 (default) or 2: the pictures in two rows, filled row by
%      row (the lamp pictures: far views on top, close-ups below; Sean,
%      T76 (B)).
%
%      RowLabels: a label for each row, shown above it (such as {'Far
%      view', 'Close-up of left headlight'}); default none. In a figure of
%      its own, each picture's caption starts with its row's label.
%
%      FigNum: the figure to use when parent is [] (cleared first); []
%      (default) for a new figure. -1: fast mode (no input checks), a new
%      figure.
%
% OUTPUTS:
%
%      axesHandles: 1 x numViews axes, row by row (uiaxes inside a panel), ready for
%      fcn_CarMesh3D_plotVehicle(..., AxesHandle=axesHandles(k)).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       axesHandles = fcn_CarMesh3D_assessAxes([], 2, Captions={'front', 'rear'}, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assessAxes.m for a full
%       test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assessAxes
%   % * First write (the V&V design file, section 3)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_assessAxes
%   % * Legend=: a line of label-color swatches under the pictures (Sean,
%   %   % T62)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assessAxes
%   % * Rows and RowLabels: two rows of pictures with a label above each
%   %   % (the lamp pictures' far views and close-ups; Sean, T76 (B))
%   %   % (drafted with Claude)

% TO-DO:
%
% (none)

arguments
    parent              % A uipanel, or [] for a figure of its own
    numViews            % How many pictures (1 to 4)
    options.Captions = {}   % A caption under each picture
    options.Dark = false    % Dark background
    options.Legend = []     % Swatches under the pictures: struct array with Name, Color
    options.Rows = 1        % 1 or 2 rows of pictures
    options.RowLabels = {}  % A label above each row
    options.FigNum = []     % The figure when parent is []; -1 fast mode
end

%% Debugging and Input checks
flag_max_speed = 0;
if isequal(options.FigNum,-1)
    flag_check_inputs = 0;
    flag_max_speed = 1;
else
    flag_check_inputs = 1;
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS)
        flag_check_inputs = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

if 0==flag_max_speed && flag_check_inputs
    if ~isempty(parent) && ~isgraphics(parent)
        error('CarMesh3D:badInput', 'parent must be a panel, or [].');
    end
    if ~isnumeric(numViews) || ~isscalar(numViews) || numViews < 1 || numViews > 4*options.Rows || numViews ~= round(numViews)
        error('CarMesh3D:badInput', 'numViews must be 1 to 4 per row.');
    end
    if ~any(isequal(options.Rows, 1) | isequal(options.Rows, 2))
        error('CarMesh3D:badInput', 'Rows must be 1 or 2.');
    end
    if ~isempty(options.Legend) && ~(isstruct(options.Legend) && all(isfield(options.Legend, {'Name', 'Color'})))
        error('CarMesh3D:badInput', 'Legend must be a structure array with Name and Color.');
    end
end

%% Main code
background = [1 1 1];
textColor = [0.15 0.15 0.15];
if options.Dark
    background = [0.08 0.08 0.12];
    textColor = [0.9 0.9 0.9];
end
axesHandles = gobjects(1, numViews);
flagLegend = ~isempty(options.Legend);
numRows = options.Rows;
numColumns = ceil(numViews/numRows);
rowLabels = cellstr(options.RowLabels);
flagRowLabels = ~isempty(options.RowLabels);
captions = options.Captions;
rowOf = @(index) ceil(index/numColumns);
columnOf = @(index) index - (rowOf(index) - 1)*numColumns;

if isempty(parent)
    % (by itself at the prompt: a figure of its own)
    if isempty(options.FigNum) || isequal(options.FigNum, -1)
        figureHandle = figure;
    else
        figureHandle = figure(options.FigNum);
        clf(figureHandle);
    end
    figureHandle.Color = background;
    layout = tiledlayout(figureHandle, numRows, numColumns, 'TileSpacing', 'compact', 'Padding', 'compact');
    for ith_view = 1:numViews
        axesHandles(ith_view) = nexttile(layout, ith_view);
    end
    if flagRowLabels
        % (no room for a label above a row of tiles: each caption starts
        % with its row's label)
        for ith_view = 1:numViews
            thisRow = rowOf(ith_view);
            if thisRow <= numel(rowLabels) && ith_view <= numel(captions)
                captions{ith_view} = sprintf('%s: %s', rowLabels{thisRow}, captions{ith_view});
            end
        end
    end
    if flagLegend
        % (TeX: a colored square and the name for each)
        layout.XLabel.String = fcn_INTERNAL_texLegend(options.Legend, textColor);
        layout.XLabel.Interpreter = 'tex';
        layout.XLabel.FontSize = 11;
        layout.XLabel.Color = textColor;
    end
else
    delete(parent.Children);
    parent.BackgroundColor = background;
    % (rows: for each row of pictures, its label above it if any; then
    % the legend)
    rowHeights = {};
    axesRow = zeros(1, numRows);
    for ith_row = 1:numRows
        if flagRowLabels
            rowHeights{end+1} = 20; %#ok<AGROW>
        end
        rowHeights{end+1} = '1x'; %#ok<AGROW>
        axesRow(ith_row) = numel(rowHeights);
    end
    if flagLegend
        rowHeights{end+1} = 22;
    end
    grid = uigridlayout(parent, [numel(rowHeights), numColumns], 'Padding', [4 4 4 4], 'ColumnSpacing', 4, ...
        'RowSpacing', 2, 'BackgroundColor', background, 'RowHeight', rowHeights);
    if flagRowLabels
        for ith_row = 1:min(numRows, numel(rowLabels))
            rowLabel = uilabel(grid, 'Text', rowLabels{ith_row}, 'FontWeight', 'bold', 'FontSize', 12, ...
                'FontColor', textColor, 'Tag', 'assessRowLabel');
            rowLabel.Layout.Row = axesRow(ith_row) - 1;
            rowLabel.Layout.Column = [1 numColumns];
        end
    end
    if flagLegend
        legendGrid = fcn_INTERNAL_legendRow(grid, options.Legend, background, textColor);
        legendGrid.Layout.Row = numel(rowHeights);
        legendGrid.Layout.Column = [1 numColumns];
    end
    for ith_view = 1:numViews
        axesHandles(ith_view) = uiaxes(grid);
        axesHandles(ith_view).Layout.Row = axesRow(rowOf(ith_view));
        axesHandles(ith_view).Layout.Column = columnOf(ith_view);
        disableDefaultInteractivity(axesHandles(ith_view));
    end
end

for ith_view = 1:numViews
    axesHandle = axesHandles(ith_view);
    axesHandle.Color = background;
    axis(axesHandle, 'off');
    hold(axesHandle, 'on');
    if ith_view <= numel(captions)
        title(axesHandle, captions{ith_view}, 'Color', textColor, 'FontWeight', 'normal', 'FontSize', 11);
        axesHandle.Title.Visible = 'on';   % (shown with the axis off)
    end
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_legendRow
function legendGrid = fcn_INTERNAL_legendRow(parent, entries, background, textColor)
% One centered row: a small bordered square in each color, then its name
% (bordered so the near-white body shows on white). Real panels, not HTML:
% a uilabel's HTML draws no background colors (found 2026-11-25)
numEntries = numel(entries);
widths = [{'1x'}, repmat({14, 'fit'}, 1, numEntries), {'1x'}];
legendGrid = uigridlayout(parent, [1 numel(widths)], 'ColumnWidth', widths, 'RowHeight', {14}, ...
    'Padding', [0 4 0 4], 'ColumnSpacing', 5, 'BackgroundColor', background, 'Tag', 'assessLegend');
for ith_entry = 1:numEntries
    swatch = uipanel(legendGrid, 'BorderType', 'line', 'BackgroundColor', entries(ith_entry).Color, ...
        'HighlightColor', [0.45 0.45 0.45], 'Tag', 'assessLegendSwatch', 'UserData', entries(ith_entry).Name);
    swatch.Layout.Column = 2*ith_entry;
    nameLabel = uilabel(legendGrid, 'Text', [entries(ith_entry).Name '  '], 'FontSize', 12, 'FontColor', textColor, ...
        'Tag', 'assessLegendName');
    nameLabel.Layout.Column = 2*ith_entry + 1;
end
end % Ends fcn_INTERNAL_legendRow

%% fcn_INTERNAL_texLegend
function tex = fcn_INTERNAL_texLegend(entries, textColor)
% The same for a figure of its own (TeX: a colored square, then the name)
parts = cell(1, numel(entries));
for ith_entry = 1:numel(entries)
    parts{ith_entry} = sprintf('\\color[rgb]{%.2f %.2f %.2f}%s\\color[rgb]{%.2f %.2f %.2f} %s', ...
        entries(ith_entry).Color, char(9632), textColor, entries(ith_entry).Name);
end
tex = strjoin(parts, '    ');
end % Ends fcn_INTERNAL_texLegend

