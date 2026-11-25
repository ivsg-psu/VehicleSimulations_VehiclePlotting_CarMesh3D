% script_test_fcn_CarMesh3D_makePanelMenu.m
% Tests fcn_CarMesh3D_makePanelMenu: the ☰ Menu every CarMesh3D GUI uses,
% built here into a hidden window of the test's own. (Rule G33: the shared
% panels' tests live with the helper; each GUI's own test checks only how
% it uses them.)

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makePanelMenu
%   % * First write (the shared-panels design file, section 3): the list,
%   %   % up to two panels at once, a third replacing the lower one, an
%   %   % open one closing, greyed panels, a host's panels added and taken
%   %   % away, the column's width, random sequences against the rules

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% DEMO case: a menu with four panels, in a hidden window of the test's own
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: a menu with four panels (hidden)\n', figNum);
[hostFigure, hostGrid, menuButton, column] = fcn_INTERNAL_host();
fcn_INTERNAL_changes('reset');
menu = fcn_CarMesh3D_makePanelMenu(menuButton, column, Resize=@(width) set(hostGrid, 'ColumnWidth', {width, '1x'}), ...
    OnChange=@(names) fcn_INTERNAL_changes(names));
names = {'Overall Display', 'Labels To Display', 'Modify Labels', 'Shared GUI settings'};
colors = {[0.93 0.95 1], [0.93 0.95 1], [1 0.96 0.85], [0.94 0.94 0.94]};
for ith_name = 1:numel(names)
    panelHandle = menu.AddPanel(names{ith_name}, colors{ith_name});
    assert(isa(panelHandle, 'matlab.ui.container.Panel') && strcmp(panelHandle.Visible, 'off'), 'AddPanel: a hidden panel');
    assert(isequal(panelHandle.BackgroundColor, colors{ith_name}), 'The panel''s color');
end
assert(all(isfield(menu, {'AddPanel', 'RemovePanel', 'Open', 'OpenPanels', 'Close', 'OpenNames', 'ToggleList', 'ListShown', ...
    'Panel', 'Names', 'SetAvailable', 'Parts'})), 'The menu''s functions');
assert(isequal(menu.Names(), names), 'The names, in order');
assert(isempty(menu.OpenNames()) && ~menu.ListShown(), 'Nothing open at first');

%% TEST case: the list opens and closes; picking a panel closes it
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: the list\n', figNum);
menuButton.ButtonPushedFcn(menuButton, []);   % (the ☰ Menu button, as a click)
assert(menu.ListShown() && hostGrid.ColumnWidth{1} == 320, 'The list opens, in a column 320 wide');
parts = menu.Parts();
assert(strcmp(parts.List.Visible, 'on') && numel(parts.Items) == 4, 'The list shows four lines');
parts.Items(1).ButtonPushedFcn(parts.Items(1), []);   % (a line of the list, as a click)
assert(isequal(menu.OpenNames(), {'Overall Display'}) && ~menu.ListShown(), 'A pick opens the panel and closes the list');
assert(startsWith(parts.Items(1).Text, char(10003)) && ~startsWith(parts.Items(2).Text, char(10003)), 'The check mark on the open one');
menu.ToggleList();
menu.ToggleList();
assert(~menu.ListShown() && hostGrid.ColumnWidth{1} == 320, 'The list closed again; the column stays for the open panel');

%% TEST case: two panels at once; a third replaces the lower one; an open one picked again closes
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: two panels at once\n', figNum);
menu.Open('Modify Labels');
assert(isequal(menu.OpenNames(), {'Overall Display', 'Modify Labels'}), 'The second under the first');
assert(menu.Panel('Overall Display').Layout.Row == 1 && menu.Panel('Modify Labels').Layout.Row == 2, 'Stacked, top first');
assert(strcmp(menu.Panel('Modify Labels').Visible, 'on') && strcmp(menu.Panel('Labels To Display').Visible, 'off'));
menu.Open('Shared GUI settings');
assert(isequal(menu.OpenNames(), {'Overall Display', 'Shared GUI settings'}), 'A third replaces the lower one');
assert(strcmp(menu.Panel('Modify Labels').Visible, 'off'));
menu.Open('Overall Display');
assert(isequal(menu.OpenNames(), {'Shared GUI settings'}), 'The top one picked again closes; the lower moves up');
assert(menu.Panel('Shared GUI settings').Layout.Row == 1);
menu.Open('Shared GUI settings');
assert(isempty(menu.OpenNames()) && hostGrid.ColumnWidth{1} == 0, 'Nothing open: the column takes no room');
menu.OpenPanels({'Labels To Display', 'Modify Labels'});
assert(isequal(menu.OpenNames(), {'Labels To Display', 'Modify Labels'}) && hostGrid.ColumnWidth{1} == 320, 'OpenPanels: exactly these');
menu.Close('Labels To Display');
assert(isequal(menu.OpenNames(), {'Modify Labels'}), 'Close');
menu.Open('');
assert(isempty(menu.OpenNames()), 'Open('''') closes them all');
changes = fcn_INTERNAL_changes();
assert(~isempty(changes) && isempty(changes{end}), 'OnChange called with the open names');

%% TEST case: a panel greyed in the list (not available), never hidden
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: greyed panels\n', figNum);
menu.OpenPanels({'Modify Labels'});
menu.SetAvailable('Modify Labels', false, 'Only on the Labels check');
parts = menu.Parts();
assert(strcmp(parts.Items(3).Enable, 'off') && strcmp(parts.Items(3).Tooltip, 'Only on the Labels check'), 'Greyed, with why');
assert(strcmp(parts.Items(3).Visible, 'on'), 'Greyed, never hidden');
assert(isempty(menu.OpenNames()), 'A greyed panel closes');
menu.Open('Modify Labels');
assert(isempty(menu.OpenNames()), 'A greyed panel does not open');
menu.SetAvailable('Modify Labels', true);
menu.Open('Modify Labels');
assert(isequal(menu.OpenNames(), {'Modify Labels'}), 'Available again');
menu.Open('');

%% TEST case: a child GUI's panels added to the host's menu, and taken away (Q45 (A))
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: panels added and taken away\n', figNum);
childPanel = menu.AddPanel('Lamps To Display', [0.93 0.95 1]);
menu.OpenPanels({'Shared GUI settings', 'Lamps To Display'});
menu.RemovePanel('Lamps To Display');
assert(~isvalid(childPanel), 'The panel is deleted');
assert(isequal(menu.Names(), names) && isequal(menu.OpenNames(), {'Shared GUI settings'}), 'Its line and its place are gone');
parts = menu.Parts();
assert(isequal(arrayfun(@(item) item.Layout.Row, parts.Items), 1:4), 'The list''s lines close up');
menu.RemovePanel('No Such Panel');   % (nothing to take away: no error)
menu.Open('');

%% TEST case: random sequences of picks, the rules after each
figNum = 20005;
fprintf(1,'Figure %.0f: TEST case: random sequences\n', figNum);
randomStream = RandStream('mt19937ar', 'Seed', 24);
for ith_step = 1:200
    switch randi(randomStream, 4)
        case 1
            menu.ToggleList();
        case 2
            menu.Open(names{randi(randomStream, numel(names))});
        case 3
            menu.Close(names{randi(randomStream, numel(names))});
        case 4
            picked = names(randperm(randomStream, numel(names), randi(randomStream, 3) - 1));
            menu.OpenPanels(picked);
    end
    message = fcn_INTERNAL_rules(menu, hostGrid);
    assert(isempty(message), 'Step %d: %s', ith_step, message);
end
delete(hostFigure);

%% FAST mode cases
figNum = 30001;
fprintf(1,'Figure %.0f: FAST mode: FigNum=-1\n', figNum);
[hostFigure, ~, menuButton, column] = fcn_INTERNAL_host();
menu = fcn_CarMesh3D_makePanelMenu(menuButton, column, FigNum=-1);
menu.AddPanel('One', []);
menu.Open('One');
assert(isequal(menu.OpenNames(), {'One'}));
delete(hostFigure);

%% BUG cases
% (none yet)

%% Fail conditions
[hostFigure, ~, menuButton, column] = fcn_INTERNAL_host();
menu = fcn_CarMesh3D_makePanelMenu(menuButton, column);
menu.AddPanel('One', []);
fcn_INTERNAL_expectError(@() menu.AddPanel('One', []), 'already has a panel');
fcn_INTERNAL_expectError(@() menu.Open('Two'), 'No panel named');
fcn_INTERNAL_expectError(@() menu.OpenPanels({'One', 'One', 'One'}), 'At most two');
fcn_INTERNAL_expectError(@() fcn_CarMesh3D_makePanelMenu(42, column), 'menuButton must be');
fcn_INTERNAL_expectError(@() fcn_CarMesh3D_makePanelMenu(menuButton, column, Resize=3), 'Resize must be');
delete(hostFigure);

fprintf(1,'All tests of fcn_CarMesh3D_makePanelMenu passed\n');

%% Functions follow
function [hostFigure, hostGrid, menuButton, column] = fcn_INTERNAL_host()
% A hidden window with a ☰ Menu button and a column for the menu
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 900 700]);
hostGrid = uigridlayout(hostFigure, [2 2], 'RowHeight', {36, '1x'}, 'ColumnWidth', {0, '1x'});
menuButton = uibutton(hostGrid, 'Text', [char(9776) ' Menu']);
menuButton.Layout.Row = 1;
menuButton.Layout.Column = 2;
column = uipanel(hostGrid, 'BorderType', 'none');
column.Layout.Row = 2;
column.Layout.Column = 1;
end % Ends fcn_INTERNAL_host

function changesOut = fcn_INTERNAL_changes(names)
% OnChange's calls, kept: with names, one more; 'reset' to start again;
% with nothing, the list so far
persistent changes
if nargin > 0
    if ischar(names) && strcmp(names, 'reset')
        changes = {};
    else
        changes{end+1} = names;
    end
end
changesOut = changes;
end % Ends fcn_INTERNAL_changes

function message = fcn_INTERNAL_rules(menu, hostGrid)
% The menu's rules: at most two open; the open ones shown, stacked top
% first, the rest hidden; the check marks; the list hidden or shown as
% said; the column's width
message = '';
openNames = menu.OpenNames();
parts = menu.Parts();
if numel(openNames) > 2
    message = sprintf('%d panels open', numel(openNames));
    return;
end
for ith_name = 1:numel(parts.Names)
    position = find(strcmp(openNames, parts.Names{ith_name}), 1);
    flagShown = strcmp(parts.Panels(ith_name).Visible, 'on');
    if flagShown ~= ~isempty(position)
        message = sprintf('%s shown: %d, open: %d', parts.Names{ith_name}, flagShown, ~isempty(position));
        return;
    end
    if ~isempty(position) && parts.Panels(ith_name).Layout.Row ~= position
        message = sprintf('%s in row %d, not %d', parts.Names{ith_name}, parts.Panels(ith_name).Layout.Row, position);
        return;
    end
    if startsWith(parts.Items(ith_name).Text, char(10003)) ~= ~isempty(position)
        message = sprintf('the check mark on %s is wrong', parts.Names{ith_name});
        return;
    end
end
if strcmp(parts.List.Visible, 'on') ~= menu.ListShown()
    message = 'the list shown differs from ListShown()';
elseif (isempty(openNames) && ~menu.ListShown()) ~= (hostGrid.ColumnWidth{1} == 0)
    message = sprintf('the column is %g wide with %d open and the list shown: %d', hostGrid.ColumnWidth{1}, numel(openNames), menu.ListShown());
end
end % Ends fcn_INTERNAL_rules

function fcn_INTERNAL_expectError(callIt, expected)
% The call must fail, with this in its message
try
    callIt();
catch caughtError
    assert(contains(caughtError.message, expected), 'Expected "%s", got: %s', expected, caughtError.message);
    return;
end
error('test:noError', 'Expected an error with "%s"', expected);
end % Ends fcn_INTERNAL_expectError
