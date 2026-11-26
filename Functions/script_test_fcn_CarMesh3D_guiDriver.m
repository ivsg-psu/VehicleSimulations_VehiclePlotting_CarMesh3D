% script_test_fcn_CarMesh3D_guiDriver
% Tests of fcn_CarMesh3D_guiDriver and fcn_CarMesh3D_guiRandomWalk on a
% small made-up app built here (a radio group, a check box, a slider, a
% button, a key handler, a panel that opens and closes), with layout
% problems put in on purpose, so the checks are seen to catch them.
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_guiDriver
%   % * First write of the tests

%% Set up the workspace
close all;

%% DEMO case: drive a small app, read its state, check its layout
fig_num = 10001;
fprintf(1,'Figure %d: DEMO case: drive a small app\n', fig_num);
app = fcn_INTERNAL_makeApp();
state = fcn_CarMesh3D_guiDriver(app.Figure, 'state');
assert(isequal(state.Values.mode, 'day') && state.Values.lights == false && state.Values.level == 0);
assert(state.OnScreen.mode && ~state.OnScreen.extraBox, 'The closed panel''s box is not on screen');
controls = fcn_CarMesh3D_guiDriver(app.Figure, 'controls');
assert(istable(controls) && any(strcmp(controls.Tag, 'mode')));

%% TEST case: set as a click would (the callback runs)
fig_num = 20001;
fprintf(1,'Figure %d: TEST case: set and press\n', fig_num);
state = fcn_CarMesh3D_guiDriver(app.Figure, 'set', 'mode', 'night');
assert(isequal(state.Values.mode, 'night') && strcmp(state.Values.status, 'night, lights off, level 0'), 'The radio group''s callback ran');
state = fcn_CarMesh3D_guiDriver(app.Figure, 'set', struct('lights', true, 'level', 40));
assert(strcmp(state.Values.status, 'night, lights on, level 40'), 'The check box''s and slider''s callbacks ran');
fcn_CarMesh3D_guiDriver(app.Figure, 'set', 'lights', false);   % (Reset at night with the lights on is the planted bug: see the random walk below)
state = fcn_CarMesh3D_guiDriver(app.Figure, 'press', 'Reset');   % (by its Text)
assert(strcmp(state.Values.status, 'day, lights off, level 0') && isequal(state.Values.mode, 'day'));
state = fcn_CarMesh3D_guiDriver(app.Figure, 'press', 'openExtra');   % (by its Tag)
assert(state.OnScreen.extraBox, 'The panel opened');
state = fcn_CarMesh3D_guiDriver(app.Figure, 'key', 'escape');
assert(~state.OnScreen.extraBox, 'Esc closed the panel');
state = fcn_CarMesh3D_guiDriver(app.Figure, 'key', 'z', Modifier={'control'});
assert(strcmp(state.Values.lastKey, 'control+z'));

%% TEST case: a user cannot click a disabled or hidden control
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: disabled and hidden controls\n', fig_num);
try
    fcn_CarMesh3D_guiDriver(app.Figure, 'set', 'extraBox', true);
    error('A hidden control was clicked');
catch caughtError
    assert(contains(caughtError.message, 'not on screen'), caughtError.message);
end
app.Lights.Enable = 'off';
try
    fcn_CarMesh3D_guiDriver(app.Figure, 'set', 'lights', true);
    error('A disabled control was clicked');
catch caughtError
    assert(contains(caughtError.message, 'disabled'), caughtError.message);
end
fcn_CarMesh3D_guiDriver(app.Figure, 'set', 'lights', true, FlagForce=true);   % (unless forced)
app.Lights.Enable = 'on';

%% TEST case: the layout check catches the problems put in on purpose
fig_num = 20003;
fprintf(1,'Figure %d: TEST case: layout problems\n', fig_num);
problems = fcn_CarMesh3D_guiDriver(app.Figure, 'checkLayout');
disp(problems);
assert(any(contains(problems.Problem, 'overlaps')), 'The overlapping radio buttons');
assert(any(contains(problems.Problem, 'does not scroll')), 'The grid that cannot reach its last rows');
assert(any(strcmp(problems.Severity, 'note') & contains(problems.Problem, 'no Tag')), 'The untagged button');
assert(~any(contains(problems.Problem, 'text may be cut off')), 'Text is checked only in a visible window (hidden windows do not lay out every control)');
delete(app.Figure);

%% TEST case: a random walk; a bug that needs an unusual order is found and replayed
fig_num = 20004;
fprintf(1,'Figure %d: TEST case: random walk\n', fig_num);
app = fcn_INTERNAL_makeApp();
fig = app.Figure;
actions = struct('Name', {'night', 'day', 'lights on', 'lights off', 'level up', 'reset', 'open extra', 'escape'}, ...
    'Do', {@() fcn_CarMesh3D_guiDriver(fig, 'set', 'mode', 'night'), @() fcn_CarMesh3D_guiDriver(fig, 'set', 'mode', 'day'), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'set', 'lights', true), @() fcn_CarMesh3D_guiDriver(fig, 'set', 'lights', false), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'set', 'level', min(100, app.Level.Value + 10)), @() fcn_CarMesh3D_guiDriver(fig, 'press', 'Reset'), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'press', 'openExtra'), @() fcn_CarMesh3D_guiDriver(fig, 'key', 'escape')}, ...
    'Allowed', {[], [], [], [], [], [], [], []});
invariants = struct('Name', {'status matches'}, 'Check', {@() fcn_INTERNAL_statusRule(fig)});
report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Steps=300, Seed=7, Name='demoApp', FigNum=-1);
assert(~report.Passed, 'The planted bug (Reset at night with the lights on leaves the status stale) is found');
fprintf(1, '    found at step %d: %s\n', report.Failures(1).Step, report.Failures(1).Message);
assert(isfile(report.FailureFile));
% (replaying the saved steps on a fresh app fails the same way)
delete(fig);
app = fcn_INTERNAL_makeApp();
fig = app.Figure;
replay = load(report.FailureFile);
actions = struct('Name', {'night', 'day', 'lights on', 'lights off', 'level up', 'reset', 'open extra', 'escape'}, ...
    'Do', {@() fcn_CarMesh3D_guiDriver(fig, 'set', 'mode', 'night'), @() fcn_CarMesh3D_guiDriver(fig, 'set', 'mode', 'day'), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'set', 'lights', true), @() fcn_CarMesh3D_guiDriver(fig, 'set', 'lights', false), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'set', 'level', min(100, app.Level.Value + 10)), @() fcn_CarMesh3D_guiDriver(fig, 'press', 'Reset'), ...
    @() fcn_CarMesh3D_guiDriver(fig, 'press', 'openExtra'), @() fcn_CarMesh3D_guiDriver(fig, 'key', 'escape')});
invariants = struct('Name', {'status matches'}, 'Check', {@() fcn_INTERNAL_statusRule(fig)});
replayReport = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Replay=replay.steps, Name='demoAppReplay', FigNum=-1);
assert(~replayReport.Passed && replayReport.Failures(1).Step == numel(replay.steps), 'The replay fails at the same step');
delete(fig);
delete(report.FailureFile); delete(strrep(report.FailureFile, '.mat', '.txt'));
delete(replayReport.FailureFile); delete(strrep(replayReport.FailureFile, '.mat', '.txt'));

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases\n', fig_num);
app = fcn_INTERNAL_makeApp();
tic;
for ith_test = 1:20
    fcn_CarMesh3D_guiDriver(app.Figure, 'state');
end
fprintf(1, 'Average time to read the state: %.4f s\n', toc/20);
delete(app.Figure);
assert(isempty(timerfindall), 'No timer left running');
fprintf(1, 'All tests of fcn_CarMesh3D_guiDriver and fcn_CarMesh3D_guiRandomWalk passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: not a window
    fcn_CarMesh3D_guiDriver(42, 'state');

    %% FAIL case: unknown command
    fcn_CarMesh3D_guiDriver(uifigure, 'jump');
end

%% Functions follow
function app = fcn_INTERNAL_makeApp()
% A small hidden app: a radio group (day/night), a check box (lights), a
% slider (level), a status label, Reset, a panel opened by a button and
% closed by Esc; and, on purpose, layout problems and one bug: Reset at
% night with the lights on does not update the status line
figureHandle = uifigure('Visible', 'off', 'Position', [100 100 420 360]);
grid = uigridlayout(figureHandle, [7 2], 'RowHeight', {30, 30, 30, 30, 30, 30, 120}, 'ColumnWidth', {150, '1x'});
group = uibuttongroup(grid, 'Tag', 'mode', 'BorderType', 'none');
uiradiobutton(group, 'Text', 'Day', 'UserData', 'day', 'Position', [2 2 70 22]);
uiradiobutton(group, 'Text', 'Night', 'UserData', 'night', 'Position', [60 2 70 22]);   % (overlaps Day on purpose)
lights = uicheckbox(grid, 'Text', 'Lights', 'Tag', 'lights');
level = uislider(grid, 'Tag', 'level', 'Limits', [0 100]);
status = uilabel(grid, 'Tag', 'status', 'Text', 'day, lights off, level 0');
resetButton = uibutton(grid, 'Text', 'Reset', 'Tag', 'reset');
openButton = uibutton(grid, 'Text', 'Open extra', 'Tag', 'openExtra');
uibutton(grid, 'Text', 'No tag');   % (untagged on purpose)
uilabel(grid, 'Text', 'A label whose text is much too long for its narrow column, on purpose');
lastKey = uilabel(grid, 'Tag', 'lastKey', 'Text', '');
extra = uipanel(grid, 'Tag', 'extraPanel', 'Visible', 'off');
uicheckbox(extra, 'Text', 'Extra', 'Tag', 'extraBox', 'Position', [5 5 80 22]);
app = struct('Figure', figureHandle, 'Mode', group, 'Lights', lights, 'Level', level, 'Status', status);
group.SelectionChangedFcn = @(~,~) update();
lights.ValueChangedFcn = @(~,~) update();
level.ValueChangedFcn = @(~,~) update();
resetButton.ButtonPushedFcn = @(~,~) resetAll();
openButton.ButtonPushedFcn = @(~,~) set(extra, 'Visible', 'on');
figureHandle.WindowKeyPressFcn = @(~,event) onKey(event);
    function update()
        status.Text = fcn_INTERNAL_statusText(group, lights, level);
    end
    function resetAll()
        flagBug = strcmp(group.SelectedObject.UserData, 'night') && lights.Value;
        group.SelectedObject = group.Children(end);   % (Day)
        lights.Value = false;
        level.Value = 0;
        if ~flagBug
            update();
        end
    end
    function onKey(event)
        if strcmp(event.Key, 'escape')
            extra.Visible = 'off';
        end
        lastKey.Text = strjoin([event.Modifier(:)' {event.Key}], '+');
    end
end

function text = fcn_INTERNAL_statusText(group, lights, level)
onOff = 'off';
if lights.Value
    onOff = 'on';
end
text = sprintf('%s, lights %s, level %.0f', group.SelectedObject.UserData, onOff, level.Value);
end

function message = fcn_INTERNAL_statusRule(fig)
% The status line must say what the controls say
group = findobj(fig, 'Tag', 'mode');
lights = findobj(fig, 'Tag', 'lights');
level = findobj(fig, 'Tag', 'level');
status = findobj(fig, 'Tag', 'status');
expected = fcn_INTERNAL_statusText(group, lights, level);
message = '';
if ~strcmp(status.Text, expected)
    message = sprintf('the status says "%s" but the controls say "%s"', status.Text, expected);
end
end
