function loading = fcn_CarMesh3D_loadingWindow(messageText, options)
% fcn_CarMesh3D_loadingWindow

% A small window, shown at once, that says a CarMesh3D window is being
% opened, with a moving bar, so a window that takes a few seconds to open
% does not look broken (Sean, 2026-11-26 23:28: "If there's a known delay
% there, we have to put up a loading screen for the user"; Q99 (A), and
% GUI rule G43). The window that is opening closes it when it is ready.
%
% Only one is shown at a time: a window opened by another (the viewer
% inside the lamp editor, say) gets the one already shown, and its Close
% leaves it to the first.
%
% FORMAT:
%
%       loading = fcn_CarMesh3D_loadingWindow(messageText,...
%           (FlagVisible=flagVisible), (FigNum=figNum))
%
% INPUTS:
%
%      messageText: what is being opened, in plain words ('Opening the
%      label painter for 2009 Honda Fit Sport').
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagVisible: false to show nothing (a window built hidden, for the
%      tests, or inside another window). Default true.
%
%      Vehicle: the vehicle being opened, as given to the window (an ID
%      or a folder); its name is added to the message. A mesh or nothing:
%      no name. Default [].
%
%      FlagBuildHidden: true to make the window but keep it hidden (for
%      the tests, which must not put windows on the screen). Default false.
%
%      FigNum: not used; -1 for fast mode.
%
% OUTPUTS:
%
%      loading: a structure with Figure (the small window, or [] when
%      nothing is shown) and Close (a function: closes the window, if this
%      call opened it; safe to call more than once).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       loading = fcn_CarMesh3D_loadingWindow('Opening the label painter');
%       loadingCleanup = onCleanup(@() loading.Close());
%       % ... build the window ...
%       loading.Close();
%
%       See the script: script_test_fcn_CarMesh3D_loadingWindow.m
%       for a full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadingWindow
%   % * First write (Q99 (A))
%   % * Kept in front (WindowStyle alwaysontop): the window being built
%   %   % covered it and it could not be read (T95 BUG, Sean 02:02)

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadingWindow
%   % * (none yet)

arguments
    messageText {mustBeTextScalar}   % What is being opened
    options.FlagVisible = true       % false: nothing shown
    options.FlagBuildHidden = false  % true: made, but hidden (tests)
    options.Vehicle = []             % The vehicle (an ID or a folder), named in the message
    options.FigNum = []              % Not used; -1 for fast mode
end

%% Main code starts here

loading = struct('Figure', [], 'Close', @() []);
if ~logical(options.FlagVisible)
    return;
end
shown = findall(groot, 'Type', 'figure', 'Tag', 'carMesh3DLoading');
if ~isempty(shown)
    loading.Figure = shown(1);   % (one is shown already: its opener closes it)
    return;
end

if (ischar(options.Vehicle) || isstring(options.Vehicle)) && strlength(options.Vehicle) > 0
    [~, vehicleName] = fileparts(char(options.Vehicle));
    messageText = sprintf('%s for %s', char(messageText), strrep(vehicleName, '_', ' '));
end
screenSize = get(groot, 'ScreenSize');
windowSize = [460 130];
figureHandle = uifigure('Name', 'CarMesh3D', 'Tag', 'carMesh3DLoading', 'Resize', 'off', ...
    'Position', [round((screenSize(3:4) - windowSize)/2), windowSize], 'HandleVisibility', 'off', ...
    'WindowStyle', 'alwaysontop', ...   % (stays in front of the window being built: T95 BUG, Sean 2026-11-27 02:02)
    'Visible', matlab.lang.OnOffSwitchState(~options.FlagBuildHidden));
figureHandle.UserData = [char(messageText) ' ...'];
if ~options.FlagBuildHidden
    % (a moving bar over the window; uiprogressdlg needs a window that is
    % shown, so a window built hidden, for the tests, gets the words only)
    uiprogressdlg(figureHandle, 'Title', 'Loading', 'Message', figureHandle.UserData, 'Indeterminate', 'on');
else
    uilabel(figureHandle, 'Text', figureHandle.UserData, 'Position', [20 50 420 30], 'Tag', 'carMesh3DLoadingText');
end
drawnow;
loading.Figure = figureHandle;
loading.Close = @() fcn_INTERNAL_close(figureHandle);

end % Ends main function

%% fcn_INTERNAL_close
function fcn_INTERNAL_close(figureHandle)
if ~isempty(figureHandle) && isvalid(figureHandle)
    delete(figureHandle);
end
end % Ends fcn_INTERNAL_close
