function [contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle, functionName, options)
% fcn_CarMesh3D_addTitleBar
% Puts the standard title bar at the top of a CarMesh3D window: the
% window's title, large, matching the button in the main window that opens
% it ("Select Vehicle", "Face Directions" ...), also used as the window's
% name; and under it the Version line: the function that made the window
% and the date and time its file was last changed (what to name when
% reporting a problem), and an optional subtitle (such as the vehicle's
% name). The rest of the window goes in the panel returned.
%
% THE TITLES are kept here, in one list (fcn_INTERNAL_titles; T99, Sean
% 2026-11-27 21:01: the function's name is already on the Version line).
% A function not in the list is titled by its name.
%
% FORMAT:
%
%       [contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle,...
%           functionName, (Title=text), (Subtitle=text), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      figureHandle: the window (a uifigure), with nothing in it yet.
%
%      functionName: the function that made the window, such as
%      'fcn_CarMesh3D_viewLabels'.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Title: the title, in place of the list's (a window used for more
%      than one step: the painter is "First Labels" or "Full Labels"; it
%      can be changed later with titleBar.SetTitle). Default '': the list's.
%
%      Subtitle: text shown after the date, such as the vehicle's name.
%      Default ''.
%
%      FigNum: not used. If set to -1, input checking is skipped (fast
%      mode).
%
% OUTPUTS:
%
%      contentPanel: a panel filling the window under the title bar, for
%      the rest of the window.
%
%      titleBar: a structure: Grid, NameLabel, VersionLabel, Modified (the
%      file's last change, as text 'yyyy-MM-dd HH:mm'), Title,
%      SetSubtitle(text), SetTitle(text) (the large title and the window's
%      name). The large title's label is tagged 'titleBarTitle'.
%
%      (one more call: fcn_CarMesh3D_addTitleBar([], functionName) returns
%      the function's title from the list, with nothing drawn)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       figureHandle = uifigure('Name', 'fcn_CarMesh3D_viewLabels: 2009 Honda Fit Sport');
%       contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewLabels', ...
%           Subtitle='2009 Honda Fit Sport');
%       uilabel(uigridlayout(contentPanel, [1 1]), 'Text', 'The rest of the window');
%
%       See the script: script_test_fcn_CarMesh3D_addTitleBar.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addTitleBar
%   % * First write of the code: every window's title is the name of its
%   %   % function (Sean, 14:31), with the file's last change under it, as
%   %   % its version for reporting a problem (Sean, 14:40)
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addTitleBar
%   % * The large title and the window's name are the window's title,
%   %   % matching its button in the main window, from one list here;
%   %   % the function's name stays on the Version line (T99, Sean 21:01);
%   %   % Title option and SetTitle

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addTitleBar
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    figureHandle
    functionName
    options.Title = ''        % The title, in place of the list's
    options.Subtitle = ''     % Text after the date, such as the vehicle's name
    options.FigNum = []       % Not used; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
% (the title from the list only: nothing drawn)
if isempty(figureHandle)
    contentPanel = fcn_INTERNAL_titles(char(functionName));
    titleBar = [];
    return;
end

flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above
        if ~(isscalar(figureHandle) && isgraphics(figureHandle, 'figure'))
            error('CarMesh3D:badInput', 'figureHandle must be a window (a uifigure).');
        end
        if ~(ischar(functionName) || (isstring(functionName) && isscalar(functionName))) || isempty(char(functionName))
            error('CarMesh3D:badInput', 'functionName must be the name of a function, as text.');
        end
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

functionName = char(functionName);

% The function's file, and when it was last changed (its version)
functionFile = which(functionName);
modifiedText = '(file not found)';
if ~isempty(functionFile) && isfile(functionFile)
    fileInfo = dir(functionFile);
    modifiedText = char(datetime(fileInfo.datenum, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
end

% The window: the title bar on top, the content panel under it
outerGrid = uigridlayout(figureHandle, [2 1], 'RowHeight', {50, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 0);
titleGrid = uigridlayout(outerGrid, [2 1], 'RowHeight', {28, 16}, 'Padding', [10 3 10 3], 'RowSpacing', 0, ...
    'BackgroundColor', [0.93 0.94 0.96]);
windowTitle = char(options.Title);
if isempty(windowTitle)
    windowTitle = fcn_INTERNAL_titles(functionName);
end
nameLabel = uilabel(titleGrid, 'Text', windowTitle, 'FontSize', 22, 'FontWeight', 'bold', ...
    'FontColor', [0.1 0.15 0.3], 'Tag', 'titleBarTitle');
figureHandle.Name = windowTitle;
versionLabel = uilabel(titleGrid, 'Text', '', 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);
contentPanel = uipanel(outerGrid, 'BorderType', 'none');
contentPanel.Layout.Row = 2;

titleBar = struct('Grid', titleGrid, 'NameLabel', nameLabel, 'VersionLabel', versionLabel, ...
    'Modified', modifiedText, 'Title', windowTitle, 'SetSubtitle', @setSubtitle, 'SetTitle', @setTitle);
setSubtitle(options.Subtitle);

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

    function setTitle(newTitle)
        % The large title and the window's name
        nameLabel.Text = char(newTitle);
        figureHandle.Name = char(newTitle);
    end

    function setSubtitle(subtitle)
        % The version line: the file's last change, then the subtitle
        versionText = sprintf('Version: %s.m, last modified %s', functionName, modifiedText);
        if ~isempty(char(subtitle))
            versionText = sprintf('%s      |      %s', versionText, char(subtitle));
        end
        versionLabel.Text = versionText;
    end

end % Ends main function

%% fcn_INTERNAL_titles
function windowTitle = fcn_INTERNAL_titles(functionName)
% Each window's title, matching its button in the main window (T99, Sean
% 2026-11-27 21:01). EDIT HERE to rename a window.
titles = {
    'fcn_CarMesh3D_main',               'CarMesh3D'
    'fcn_CarMesh3D_browseLibrary',      'Select Vehicle'
    'fcn_CarMesh3D_paintLabels',        'Paint Labels'
    'fcn_CarMesh3D_fixFaceDirections',  'Face Directions'
    'fcn_CarMesh3D_editLampFunctions',  'Lamp Functions'
    'fcn_CarMesh3D_reviewVehicle',      'V&V Review'
    'fcn_CarMesh3D_viewLabels',         'Labels'
    'fcn_CarMesh3D_viewDimensions',     'Dimensions'
    'fcn_CarMesh3D_viewOrientation',    'Orientation'
    'fcn_CarMesh3D_viewDetailLevels',   'Detail Levels'
    'fcn_CarMesh3D_viewOutline',        'Outline'
    'fcn_CarMesh3D_animateChecks',      'Motion Checks'
    'fcn_CarMesh3D_answerQueue',        'Answer Queue'
    };
match = find(strcmp(titles(:, 1), functionName), 1);
if isempty(match)
    windowTitle = functionName;
else
    windowTitle = titles{match, 2};
end
end % Ends fcn_INTERNAL_titles
