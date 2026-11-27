% script_test_fcn_CarMesh3D_loadingWindow.m
% Tests fcn_CarMesh3D_loadingWindow

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadingWindow
%   % * First write (drafted with Claude)

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadingWindow
%   % * (none yet)

%% Set up the workspace
close all;
delete(findall(groot, 'Type', 'figure', 'Tag', 'carMesh3DLoading'));

%% TEST case: shown (built hidden here), with its message and a moving bar; closed
loading = fcn_CarMesh3D_loadingWindow('Opening the label painter', Vehicle='2009_Honda_Fit_Sport', FlagBuildHidden=true);
assert(~isempty(loading.Figure) && isvalid(loading.Figure) && strcmp(loading.Figure.Tag, 'carMesh3DLoading'));
% (built hidden, as a test must: the words only, as the moving bar,
% uiprogressdlg, needs a window that is shown)
assert(strcmp(loading.Figure.UserData, 'Opening the label painter for 2009 Honda Fit Sport ...') && ...
    contains(findall(loading.Figure, 'Tag', 'carMesh3DLoadingText').Text, '2009 Honda Fit Sport'), 'The message, with the vehicle''s name');
assert(strcmp(loading.Figure.HandleVisibility, 'off'), 'Not closed by a plain close all');
assert(strcmp(loading.Figure.WindowStyle, 'alwaysontop'), 'Kept in front of the window being built (T95 BUG)');

%% TEST case: one at a time: a second call gets the first, and its Close leaves it open
inner = fcn_CarMesh3D_loadingWindow('Opening the viewer', FlagBuildHidden=true);
assert(isequal(inner.Figure, loading.Figure), 'The one already shown');
inner.Close();
assert(isvalid(loading.Figure), 'Left to its opener');
figureHandle = loading.Figure;
loading.Close();
assert(~isvalid(figureHandle), 'Closed by its opener');
loading.Close();   % (a second Close: nothing happens)

%% TEST case: nothing shown for a hidden window
loading = fcn_CarMesh3D_loadingWindow('Opening', FlagVisible=false);
assert(isempty(loading.Figure) && isempty(findall(groot, 'Type', 'figure', 'Tag', 'carMesh3DLoading')));
loading.Close();

fprintf(1, 'script_test_fcn_CarMesh3D_loadingWindow: all tests passed\n');
