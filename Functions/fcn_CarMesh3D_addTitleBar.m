function [contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle, functionName, options)
% fcn_CarMesh3D_addTitleBar
% Puts the standard title bar at the top of a CarMesh3D window: the name
% of the function that made the window, large, so that a user knows what
% to call (and what to name when reporting a problem), and under it the
% date and time that function's file was last changed (its version), and
% an optional subtitle (such as the vehicle's name). The rest of the
% window goes in the panel returned.
%
% FORMAT:
%
%       [contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle,...
%           functionName, (Subtitle=text), (FigNum=figNum))
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
%      file's last change, as text 'yyyy-MM-dd HH:mm'), SetSubtitle(text)
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
    options.Subtitle = ''     % Text after the date, such as the vehicle's name
    options.FigNum = []       % Not used; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
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
nameLabel = uilabel(titleGrid, 'Text', functionName, 'FontSize', 22, 'FontWeight', 'bold', ...
    'FontName', 'Courier New', 'FontColor', [0.1 0.15 0.3]);
versionLabel = uilabel(titleGrid, 'Text', '', 'FontSize', 11, 'FontColor', [0.35 0.35 0.35]);
contentPanel = uipanel(outerGrid, 'BorderType', 'none');
contentPanel.Layout.Row = 2;

titleBar = struct('Grid', titleGrid, 'NameLabel', nameLabel, 'VersionLabel', versionLabel, ...
    'Modified', modifiedText, 'SetSubtitle', @setSubtitle);
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

    function setSubtitle(subtitle)
        % The version line: the file's last change, then the subtitle
        versionText = sprintf('Version: %s.m, last modified %s', functionName, modifiedText);
        if ~isempty(char(subtitle))
            versionText = sprintf('%s      |      %s', versionText, char(subtitle));
        end
        versionLabel.Text = versionText;
    end

end % Ends main function
