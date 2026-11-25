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
%           (Captions=captions), (Dark=flag), (FigNum=figNum))
%
% INPUTS:
%
%      parent: the panel to draw in (a uipanel), or [] for a figure of its
%      own.
%
%      numViews: how many pictures, side by side (1 to 4).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Captions: a caption under each picture (a cell array of text);
%      default none.
%
%      Dark: true for a dark background (night, for lit lamps); default
%      false (white).
%
%      FigNum: the figure to use when parent is [] (cleared first); []
%      (default) for a new figure. -1: fast mode (no input checks), a new
%      figure.
%
% OUTPUTS:
%
%      axesHandles: 1 x numViews axes (uiaxes inside a panel), ready for
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

% TO-DO:
%
% (none)

arguments
    parent              % A uipanel, or [] for a figure of its own
    numViews            % How many pictures (1 to 4)
    options.Captions = {}   % A caption under each picture
    options.Dark = false    % Dark background
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
    if ~isnumeric(numViews) || ~isscalar(numViews) || numViews < 1 || numViews > 4 || numViews ~= round(numViews)
        error('CarMesh3D:badInput', 'numViews must be 1, 2, 3 or 4.');
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

if isempty(parent)
    % (by itself at the prompt: a figure of its own)
    if isempty(options.FigNum) || isequal(options.FigNum, -1)
        figureHandle = figure;
    else
        figureHandle = figure(options.FigNum);
        clf(figureHandle);
    end
    figureHandle.Color = background;
    layout = tiledlayout(figureHandle, 1, numViews, 'TileSpacing', 'compact', 'Padding', 'compact');
    for ith_view = 1:numViews
        axesHandles(ith_view) = nexttile(layout);
    end
else
    delete(parent.Children);
    parent.BackgroundColor = background;
    grid = uigridlayout(parent, [1 numViews], 'Padding', [4 4 4 4], 'ColumnSpacing', 4, 'BackgroundColor', background);
    for ith_view = 1:numViews
        axesHandles(ith_view) = uiaxes(grid);
        axesHandles(ith_view).Layout.Row = 1;
        axesHandles(ith_view).Layout.Column = ith_view;
        disableDefaultInteractivity(axesHandles(ith_view));
    end
end

for ith_view = 1:numViews
    axesHandle = axesHandles(ith_view);
    axesHandle.Color = background;
    axis(axesHandle, 'off');
    hold(axesHandle, 'on');
    if ith_view <= numel(options.Captions)
        title(axesHandle, options.Captions{ith_view}, 'Color', textColor, 'FontWeight', 'normal', 'FontSize', 11);
        axesHandle.Title.Visible = 'on';   % (shown with the axis off)
    end
end

end % Ends main function
