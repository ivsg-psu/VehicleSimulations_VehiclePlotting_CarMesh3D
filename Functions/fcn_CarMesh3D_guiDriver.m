function result = fcn_CarMesh3D_guiDriver(figureHandle, command, varargin)
% fcn_CarMesh3D_guiDriver
% Drives a uifigure app the way a user would, for automated GUI tests: it
% reads every control's state, puts controls into a given state through
% the same callbacks a mouse click runs, presses buttons, sends keys, and
% checks the layout (controls off their panel, overlapping, cut-off text,
% panels that cannot scroll to their last rows, controls with no Tag).
% Controls are named by their Tag, so every control a test touches needs
% a unique Tag.
%
% Written for Sean's request (2026-11-24 05:03): "create hooks inside the
% menus such that, for debugging, the code could pass in debugging state
% requests, and the GUI must go to that state ... automate nearly all the
% GUI tests". Each GUI exposes it through its own hooks (State, SetState,
% Press, Key, CheckLayout), which call this function with its window.
%
% FORMAT:
%
%       state    = fcn_CarMesh3D_guiDriver(figureHandle, 'state')
%       stateNow = fcn_CarMesh3D_guiDriver(figureHandle, 'set', stateIn, (Force=flag))
%       stateNow = fcn_CarMesh3D_guiDriver(figureHandle, 'set', tag, value, (Force=flag))
%       stateNow = fcn_CarMesh3D_guiDriver(figureHandle, 'press', tagOrText, (Force=flag))
%       stateNow = fcn_CarMesh3D_guiDriver(figureHandle, 'key', key, (Modifier=mods))
%       problems = fcn_CarMesh3D_guiDriver(figureHandle, 'checkLayout')
%       controls = fcn_CarMesh3D_guiDriver(figureHandle, 'controls')
%
% INPUTS:
%
%      figureHandle: the app's uifigure (or any container in it: only the
%      controls inside are used).
%
%      command: one of
%           'state': every tagged control's state (below)
%           'set': put controls into a state, as clicks would. stateIn is
%               a structure of Tag = value (as 'state' gives in Values; a
%               radio group's value is its selected button's UserData, or
%               its Text if it has no UserData), or give one tag and value.
%               The control's callback runs as a click's would. A control
%               that is disabled or not on screen cannot be clicked: an
%               error says so, unless Force=true.
%           'press': press a button (uibutton or state button), named by
%               its Tag or its Text; runs its callback.
%           'key': a key press sent to the window (its WindowKeyPressFcn,
%               then KeyPressFcn), e.g. 'escape', 'z' with Modifier
%               {'control'}.
%           'checkLayout': a table of layout problems (Severity, Control,
%               Problem); empty if none. Severity 'error' for controls off
%               their container, overlapping, or rows that cannot be
%               reached; 'warning' for text that looks cut off; 'note' for
%               a clickable control with no Tag. A control placed on top
%               of another on purpose (a name on a photo) is left out of
%               the overlap check when marked with
%               setappdata(control, 'guiDriverOverlay', true). Text is
%               checked only in a visible window (a hidden window does not
%               lay out every control).
%           'controls': a table of every control (Tag, Type, Text, Path,
%               Enabled, OnScreen), for writing tests.
%
%     (OPTIONAL INPUTS, as Name=Value pairs after the others)
%
%      Force: true to set or press a control that is disabled or not on
%      screen (default false: an error, since a user could not).
%
%      Modifier: for 'key', a cell array of modifier keys, e.g.
%      {'control'} or {'control','shift'} (default {}).
%
% OUTPUTS:
%
%      result: for 'state', 'set', 'press' and 'key', the state after the
%      command, a structure with
%           Values: Tag = value, for every tagged control that has a value
%               (radio groups, check boxes, sliders, fields, drop-downs,
%               state buttons; labels give their Text; panels give
%               whether they are visible)
%           Enabled: Tag = true/false
%           OnScreen: Tag = true/false (it and every container around it
%               visible)
%           Tags: the controls' Tags (field names are made valid from
%               them: a Tag 'shown_part_glass' stays as is, 'a-b' becomes
%               'a_b')
%      For 'checkLayout' and 'controls', a table (see above).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       [~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false);
%       state = fcn_CarMesh3D_guiDriver(viewer.Figure, 'state');
%       fcn_CarMesh3D_guiDriver(viewer.Figure, 'set', 'overallNight', true);
%       fcn_CarMesh3D_guiDriver(viewer.Figure, 'press', 'Reset view');
%       problems = fcn_CarMesh3D_guiDriver(viewer.Figure, 'checkLayout')
%
%       See the script: script_test_fcn_CarMesh3D_guiDriver.m for a full
%       test suite, and fcn_CarMesh3D_guiRandomWalk for random sequences.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_guiDriver
%   % * First write of the code (Q39, agreed 05:10): state, set, press,
%   %   % key, checkLayout and controls, for automated GUI tests
%   % * Overlay controls (appdata guiDriverOverlay) skip the overlap
%   %   % check; text checked in visible windows only (Agent C, 06:15)

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_guiDriver
%   % * Mouse events on axes (painting) are driven by each GUI's own
%   %   % hooks, not here


% (no arguments block: the command decides the inputs)

%% Debugging and Input checks
flag_do_debug = 0;
MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
if ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
    flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
end
if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
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
if isempty(figureHandle) || ~isgraphics(figureHandle)
    error('CarMesh3D:badInput', 'figureHandle must be an open app window (uifigure) or a container in one.');
end
command = char(command);
% (Name=Value options at the end: Force, Modifier)
force = false;
modifier = {};
args = varargin;
ith_arg = 1;
positional = {};
while ith_arg <= numel(args)
    if (ischar(args{ith_arg}) || isstring(args{ith_arg})) && any(strcmpi(char(args{ith_arg}), {'Force','Modifier'})) && ith_arg < numel(args) ...
            && ~(strcmp(command,'set') && isempty(positional))   % (a Tag named Force: not an option)
        switch lower(char(args{ith_arg}))
            case 'force'
                force = logical(args{ith_arg+1});
            case 'modifier'
                modifier = cellstr(args{ith_arg+1});
        end
        ith_arg = ith_arg + 2;
    else
        positional{end+1} = args{ith_arg}; %#ok<AGROW>
        ith_arg = ith_arg + 1;
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
switch command
    case 'state'
        result = fcn_INTERNAL_state(figureHandle);
    case 'set'
        if isempty(positional)
            error('CarMesh3D:badInput', 'set needs a structure of Tag = value, or a Tag and a value.');
        end
        if isstruct(positional{1})
            stateIn = positional{1};
            tags = fieldnames(stateIn);
            for ith_tag = 1:numel(tags)
                fcn_INTERNAL_setOne(figureHandle, tags{ith_tag}, stateIn.(tags{ith_tag}), force);
            end
        else
            if numel(positional) < 2
                error('CarMesh3D:badInput', 'set with a Tag needs a value too.');
            end
            fcn_INTERNAL_setOne(figureHandle, char(positional{1}), positional{2}, force);
        end
        drawnow;
        result = fcn_INTERNAL_state(figureHandle);
    case 'press'
        if isempty(positional)
            error('CarMesh3D:badInput', 'press needs a button''s Tag or Text.');
        end
        fcn_INTERNAL_press(figureHandle, char(positional{1}), force);
        drawnow;
        result = fcn_INTERNAL_state(figureHandle);
    case 'key'
        if isempty(positional)
            error('CarMesh3D:badInput', 'key needs a key name, such as ''escape''.');
        end
        fcn_INTERNAL_key(figureHandle, char(positional{1}), modifier);
        drawnow;
        result = fcn_INTERNAL_state(figureHandle);
    case 'checkLayout'
        result = fcn_INTERNAL_checkLayout(figureHandle);
    case 'controls'
        result = fcn_INTERNAL_controlTable(figureHandle);
    otherwise
        error('CarMesh3D:badInput', 'Unknown command ''%s'': use state, set, press, key, checkLayout or controls.', command);
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_allControls
function controls = fcn_INTERNAL_allControls(containerHandle)
% Every app component inside (controls and containers), not the figure
controls = findall(containerHandle);
keep = false(size(controls));
for ith = 1:numel(controls)
    className = class(controls(ith));
    keep(ith) = startsWith(className, 'matlab.ui.control.') || startsWith(className, 'matlab.ui.container.') ...
        && ~isa(controls(ith), 'matlab.ui.Figure');
end
controls = controls(keep);
controls = controls(~arrayfun(@(c) isa(c, 'matlab.ui.Figure'), controls));
end % Ends fcn_INTERNAL_allControls

%% fcn_INTERNAL_isValued
function flagValued = fcn_INTERNAL_isValued(control)
% Whether a control has a value a user sets
flagValued = isa(control, 'matlab.ui.container.ButtonGroup') || isprop(control, 'Value') ...
    && ~isa(control, 'matlab.ui.control.RadioButton') && ~isa(control, 'matlab.ui.control.ToggleButton');
end % Ends fcn_INTERNAL_isValued

%% fcn_INTERNAL_value
function value = fcn_INTERNAL_value(control)
% A control's value, as 'state' gives it
if isa(control, 'matlab.ui.container.ButtonGroup')
    selected = control.SelectedObject;
    if isempty(selected)
        value = [];
    elseif isprop(selected, 'UserData') && ~isempty(selected.UserData)
        value = selected.UserData;
    else
        value = selected.Text;
    end
elseif isprop(control, 'Value')
    value = control.Value;
elseif isa(control, 'matlab.ui.control.Label')
    value = control.Text;
elseif isa(control, 'matlab.ui.container.Panel') || isa(control, 'matlab.ui.container.Tab')
    value = strcmp(char(control.Visible), 'on');
else
    value = [];
end
end % Ends fcn_INTERNAL_value

%% fcn_INTERNAL_onScreen
function flagOn = fcn_INTERNAL_onScreen(control)
% It and every container around it visible (the figure itself may be
% hidden: tests run with hidden windows)
flagOn = true;
thing = control;
while ~isempty(thing) && ~isa(thing, 'matlab.ui.Figure')
    if isprop(thing, 'Visible') && ~strcmp(char(thing.Visible), 'on')
        flagOn = false;
        return;
    end
    thing = thing.Parent;
end
end % Ends fcn_INTERNAL_onScreen

%% fcn_INTERNAL_enabled
function flagEnabled = fcn_INTERNAL_enabled(control)
% Enabled, and inside no disabled container
flagEnabled = true;
thing = control;
while ~isempty(thing) && ~isa(thing, 'matlab.ui.Figure')
    if isprop(thing, 'Enable') && ~strcmp(char(thing.Enable), 'on')
        flagEnabled = false;
        return;
    end
    thing = thing.Parent;
end
end % Ends fcn_INTERNAL_enabled

%% fcn_INTERNAL_state
function state = fcn_INTERNAL_state(containerHandle)
% Every tagged control's value, enabled and on-screen flags
state = struct('Values', struct(), 'Enabled', struct(), 'OnScreen', struct(), 'Tags', {{}});
controls = fcn_INTERNAL_allControls(containerHandle);
for ith = 1:numel(controls)
    control = controls(ith);
    if ~isprop(control, 'Tag') || isempty(control.Tag)
        continue;
    end
    if ~(fcn_INTERNAL_isValued(control) || isa(control, 'matlab.ui.control.Label') || isa(control, 'matlab.ui.control.Button') ...
            || isa(control, 'matlab.ui.container.Panel') || isa(control, 'matlab.ui.container.Tab'))
        continue;
    end
    name = matlab.lang.makeValidName(control.Tag);
    if isfield(state.Values, name)
        continue;   % (a repeated Tag: the first one; checkLayout reports it)
    end
    state.Values.(name) = fcn_INTERNAL_value(control);
    state.Enabled.(name) = fcn_INTERNAL_enabled(control);
    state.OnScreen.(name) = fcn_INTERNAL_onScreen(control);
    state.Tags{end+1} = control.Tag;
end
end % Ends fcn_INTERNAL_state

%% fcn_INTERNAL_find
function control = fcn_INTERNAL_find(containerHandle, tagOrText, flagButtonsByText)
% The control with this Tag (or, for buttons, this Text)
controls = fcn_INTERNAL_allControls(containerHandle);
tags = arrayfun(@(c) fcn_INTERNAL_prop(c, 'Tag'), controls, 'UniformOutput', false);
matches = controls(strcmp(tags, tagOrText) | strcmp(cellfun(@matlab.lang.makeValidName, tags, 'UniformOutput', false), tagOrText));
if isempty(matches) && flagButtonsByText
    isButton = arrayfun(@(c) isa(c, 'matlab.ui.control.Button') || isa(c, 'matlab.ui.control.StateButton'), controls);
    texts = arrayfun(@(c) fcn_INTERNAL_prop(c, 'Text'), controls, 'UniformOutput', false);
    matches = controls(isButton & strcmp(texts, tagOrText));
    if numel(matches) > 1
        % (the same text on several buttons: the ones on screen)
        onScreen = arrayfun(@fcn_INTERNAL_onScreen, matches);
        if any(onScreen)
            matches = matches(onScreen);
        end
    end
end
if isempty(matches)
    error('CarMesh3D:guiDriver', 'No control with the Tag (or button Text) ''%s''.', tagOrText);
end
if numel(matches) > 1
    error('CarMesh3D:guiDriver', '%d controls have the Tag or Text ''%s'': give each a unique Tag.', numel(matches), tagOrText);
end
control = matches;
end % Ends fcn_INTERNAL_find

%% fcn_INTERNAL_prop
function value = fcn_INTERNAL_prop(control, name)
% A text property, or '' if the control has none
value = '';
if isprop(control, name)
    value = control.(name);
    if isstring(value)
        value = char(strjoin(value, ' '));
    elseif iscell(value)
        value = strjoin(cellfun(@char, value, 'UniformOutput', false), ' ');
    elseif ~ischar(value)
        value = '';
    end
end
end % Ends fcn_INTERNAL_prop

%% fcn_INTERNAL_checkClickable
function fcn_INTERNAL_checkClickable(control, tagOrText, force)
% A user cannot click a disabled control or one not on screen
if force
    return;
end
if ~fcn_INTERNAL_enabled(control)
    error('CarMesh3D:guiDriver', 'The control ''%s'' is disabled: a user could not click it (use Force=true to anyway).', tagOrText);
end
if ~fcn_INTERNAL_onScreen(control)
    error('CarMesh3D:guiDriver', 'The control ''%s'' is not on screen (its panel is closed or hidden): a user could not click it (use Force=true to anyway).', tagOrText);
end
end % Ends fcn_INTERNAL_checkClickable

%% fcn_INTERNAL_callback
function fcn_INTERNAL_callback(callback, source, eventData)
% Runs a callback as MATLAB would (function handle, cell, or text)
if isempty(callback)
    return;
end
if isa(callback, 'function_handle')
    callback(source, eventData);
elseif iscell(callback)
    callback{1}(source, eventData, callback{2:end});
elseif ischar(callback) || isstring(callback)
    evalin('base', char(callback));
end
end % Ends fcn_INTERNAL_callback

%% fcn_INTERNAL_setOne
function fcn_INTERNAL_setOne(containerHandle, tag, value, force)
% One control set as a click would
control = fcn_INTERNAL_find(containerHandle, tag, false);
fcn_INTERNAL_checkClickable(control, tag, force);
if isa(control, 'matlab.ui.container.ButtonGroup')
    radios = control.Children;
    radios = radios(arrayfun(@(r) isa(r, 'matlab.ui.control.RadioButton') || isa(r, 'matlab.ui.control.ToggleButton'), radios));
    match = arrayfun(@(r) (~isempty(r.UserData) && isequal(r.UserData, value)) || (ischar(value) && strcmp(r.Text, value)), radios);
    if ~any(match)
        error('CarMesh3D:guiDriver', 'The radio group ''%s'' has no button for that value.', tag);
    end
    radio = radios(find(match, 1));
    if ~force && ~strcmp(char(radio.Enable), 'on')
        error('CarMesh3D:guiDriver', 'That button of ''%s'' is disabled: a user could not click it.', tag);
    end
    oldRadio = control.SelectedObject;
    if isequal(oldRadio, radio)
        return;   % (clicking the selected button does nothing)
    end
    control.SelectedObject = radio;
    fcn_INTERNAL_callback(control.SelectionChangedFcn, control, ...
        struct('NewValue', radio, 'OldValue', oldRadio, 'Source', control, 'EventName', 'SelectionChanged'));
elseif isprop(control, 'Value')
    oldValue = control.Value;
    control.Value = value;
    if isprop(control, 'ValueChangedFcn')
        fcn_INTERNAL_callback(control.ValueChangedFcn, control, ...
            struct('Value', control.Value, 'PreviousValue', oldValue, 'Source', control, 'EventName', 'ValueChanged'));
    end
else
    error('CarMesh3D:guiDriver', 'The control ''%s'' (%s) has no value to set.', tag, class(control));
end
end % Ends fcn_INTERNAL_setOne

%% fcn_INTERNAL_press
function fcn_INTERNAL_press(containerHandle, tagOrText, force)
% A button pressed
control = fcn_INTERNAL_find(containerHandle, tagOrText, true);
fcn_INTERNAL_checkClickable(control, tagOrText, force);
if isa(control, 'matlab.ui.control.StateButton')
    oldValue = control.Value;
    control.Value = ~oldValue;
    fcn_INTERNAL_callback(control.ValueChangedFcn, control, ...
        struct('Value', control.Value, 'PreviousValue', oldValue, 'Source', control, 'EventName', 'ValueChanged'));
elseif isprop(control, 'ButtonPushedFcn')
    fcn_INTERNAL_callback(control.ButtonPushedFcn, control, struct('Source', control, 'EventName', 'ButtonPushed'));
else
    error('CarMesh3D:guiDriver', 'The control ''%s'' (%s) is not a button.', tagOrText, class(control));
end
end % Ends fcn_INTERNAL_press

%% fcn_INTERNAL_key
function fcn_INTERNAL_key(containerHandle, key, modifier)
% A key press sent to the window
figureHandle = ancestor(containerHandle, 'figure');
character = '';
if isscalar(key)
    character = key;
elseif strcmp(key, 'escape')
    character = char(27);
end
eventData = struct('Key', key, 'Character', character, 'Modifier', {modifier}, 'Source', figureHandle, 'EventName', 'WindowKeyPress');
if ~isempty(figureHandle.WindowKeyPressFcn)
    fcn_INTERNAL_callback(figureHandle.WindowKeyPressFcn, figureHandle, eventData);
elseif ~isempty(figureHandle.KeyPressFcn)
    eventData.EventName = 'KeyPress';
    fcn_INTERNAL_callback(figureHandle.KeyPressFcn, figureHandle, eventData);
end
end % Ends fcn_INTERNAL_key

%% fcn_INTERNAL_controlTable
function controlTable = fcn_INTERNAL_controlTable(containerHandle)
% Every component, for writing tests
controls = fcn_INTERNAL_allControls(containerHandle);
numControls = numel(controls);
Tag = cell(numControls,1); Type = cell(numControls,1); Text = cell(numControls,1); Path = cell(numControls,1);
Enabled = false(numControls,1); OnScreen = false(numControls,1);
for ith = 1:numControls
    Tag{ith} = fcn_INTERNAL_prop(controls(ith), 'Tag');
    typeParts = strsplit(class(controls(ith)), '.');
    Type{ith} = typeParts{end};
    Text{ith} = fcn_INTERNAL_prop(controls(ith), 'Text');
    if isempty(Text{ith})
        Text{ith} = fcn_INTERNAL_prop(controls(ith), 'Title');
    end
    Path{ith} = fcn_INTERNAL_path(controls(ith));
    Enabled(ith) = fcn_INTERNAL_enabled(controls(ith));
    OnScreen(ith) = fcn_INTERNAL_onScreen(controls(ith));
end
controlTable = table(Tag, Type, Text, Path, Enabled, OnScreen);
end % Ends fcn_INTERNAL_controlTable

%% fcn_INTERNAL_path
function pathText = fcn_INTERNAL_path(control)
% Where a control is: its containers' Tags or titles, outermost first
parts = {};
thing = control.Parent;
while ~isempty(thing) && ~isa(thing, 'matlab.ui.Figure')
    name = fcn_INTERNAL_prop(thing, 'Tag');
    if isempty(name)
        name = fcn_INTERNAL_prop(thing, 'Title');
    end
    if ~isempty(name)
        parts{end+1} = name; %#ok<AGROW>
    end
    thing = thing.Parent;
end
pathText = strjoin(fliplr(parts), ' > ');
end % Ends fcn_INTERNAL_path

%% fcn_INTERNAL_name
function name = fcn_INTERNAL_name(control)
% A control's name in a report: its Tag, else its type, text and path
name = fcn_INTERNAL_prop(control, 'Tag');
if isempty(name)
    typeParts = strsplit(class(control), '.');
    text = fcn_INTERNAL_prop(control, 'Text');
    if isempty(text)
        text = fcn_INTERNAL_prop(control, 'Title');
    end
    name = sprintf('%s "%s" in %s', typeParts{end}, text, fcn_INTERNAL_path(control));
end
end % Ends fcn_INTERNAL_name

%% fcn_INTERNAL_checkLayout
function problems = fcn_INTERNAL_checkLayout(containerHandle)
% Layout problems of the controls now on screen
Severity = {}; Control = {}; Problem = {};
    function add(severity, control, problem)
        Severity{end+1,1} = severity;
        Control{end+1,1} = fcn_INTERNAL_name(control);
        Problem{end+1,1} = problem;
    end
controls = fcn_INTERNAL_allControls(containerHandle);
drawnow;
flagVisibleWindow = strcmp(char(ancestor(containerHandle, 'figure').Visible), 'on');

% (repeated Tags)
tags = arrayfun(@(c) fcn_INTERNAL_prop(c, 'Tag'), controls, 'UniformOutput', false);
[uniqueTags, ~, tagIndex] = unique(tags(~cellfun(@isempty, tags)));
tagCounts = accumarray(tagIndex(:), 1);
for ith = find(tagCounts(:)' > 1)
    Severity{end+1,1} = 'error'; %#ok<AGROW>
    Control{end+1,1} = uniqueTags{ith}; %#ok<AGROW>
    Problem{end+1,1} = sprintf('%d controls share this Tag', tagCounts(ith)); %#ok<AGROW>
end

for ith = 1:numel(controls)
    control = controls(ith);
    if ~fcn_INTERNAL_onScreen(control)
        continue;
    end
    % (a clickable control with no Tag: tests cannot name it)
    isClickable = isa(control, 'matlab.ui.control.Button') || isa(control, 'matlab.ui.container.ButtonGroup') ...
        || (isprop(control, 'ValueChangedFcn') && ~isa(control, 'matlab.ui.control.Label'));
    if isClickable && isempty(fcn_INTERNAL_prop(control, 'Tag'))
        add('note', control, 'a clickable control with no Tag (tests cannot name it)');
    end
    % (a grid's rows: can the last rows be reached?)
    if isa(control, 'matlab.ui.container.GridLayout')
        fcn_INTERNAL_checkGrid(control);
    end
    % (children placed by Position: inside their container, not overlapping)
    if isprop(control, 'Children') && ~isa(control, 'matlab.ui.container.GridLayout') && ~isempty(control.Children) ...
            && (isa(control, 'matlab.ui.container.ButtonGroup') || isa(control, 'matlab.ui.container.Panel'))
        fcn_INTERNAL_checkPlaced(control);
    end
    % (text that looks cut off: an estimate from the font size; only in a
    % visible window, since hidden windows do not lay out every control:
    % labels in scrolling panels keep the default 31 px width there)
    if flagVisibleWindow && (isa(control, 'matlab.ui.control.Label') || isa(control, 'matlab.ui.control.Button') ...
            || isa(control, 'matlab.ui.control.RadioButton') || isa(control, 'matlab.ui.control.CheckBox')) ...
            && ~(isprop(control, 'WordWrap') && strcmp(char(control.WordWrap), 'on'))
        text = control.Text;
        if iscell(text) || isstring(text)
            lines = cellstr(text);
        else
            lines = {char(text)};
        end
        if ~isempty(lines) && ~isempty([lines{:}]) && ~(isprop(control, 'Interpreter') && ~strcmp(char(control.Interpreter), 'none'))
            longest = max(cellfun(@numel, lines));
            neededWidth = 0.55*control.FontSize*longest;
            if isa(control, 'matlab.ui.control.RadioButton') || isa(control, 'matlab.ui.control.CheckBox')
                neededWidth = neededWidth + 20;   % (the round or square box)
            elseif isa(control, 'matlab.ui.control.Button')
                neededWidth = neededWidth + 12;
            end
            width = control.Position(3);
            if width > 5 && neededWidth > 1.15*width
                add('warning', control, sprintf('its text may be cut off (about %.0f px needed, %.0f px wide)', neededWidth, width));
            end
        end
    end
end
problems = table(Severity, Control, Problem);

    function fcn_INTERNAL_checkGrid(grid)
        % Rows of fixed height that add up to more than the grid's height
        % are cut off unless the grid scrolls; a '1x' row in a grid whose
        % fixed rows already fill it is squeezed to nothing
        heights = grid.RowHeight;
        if ~iscell(heights)
            heights = num2cell(heights);
        end
        fixed = cellfun(@(h) isnumeric(h), heights);
        if ~any(fixed)
            return;
        end
        neededHeight = sum([heights{fixed}]) + grid.RowSpacing*(numel(heights)-1) + grid.Padding(2) + grid.Padding(4);
        haveHeight = grid.Position(4);
        if haveHeight < 10
            return;   % (not laid out)
        end
        if neededHeight > haveHeight + 1
            if ~strcmp(char(grid.Scrollable), 'on')
                add('error', grid, sprintf('its rows need %.0f px but it is %.0f px tall and does not scroll: the last rows are cut off', neededHeight, haveHeight));
            elseif any(cellfun(@(h) ischar(h) && endsWith(h, 'x'), heights))
                add('error', grid, sprintf('its fixed rows need %.0f px of %.0f px, so its ''1x'' rows get no height (use ''fit'' or a number)', neededHeight, haveHeight));
            end
        end
    end

    function fcn_INTERNAL_checkPlaced(container)
        % Children placed by Position: inside the container and apart
        kids = container.Children;
        kids = kids(arrayfun(@(k) isprop(k, 'Position') && fcn_INTERNAL_onScreen(k) && ~isa(k, 'matlab.ui.container.GridLayout'), kids));
        if isempty(kids)
            return;
        end
        if isprop(container, 'InnerPosition')
            box = container.InnerPosition;
        else
            box = container.Position;
        end
        if box(3) < 10 || box(4) < 10
            return;   % (not laid out)
        end
        positions = cell2mat(arrayfun(@(k) k.Position(:)', kids, 'UniformOutput', false));
        for ith_kid = 1:numel(kids)
            p = positions(ith_kid,:);
            if p(1) < -1 || p(2) < -1 || p(1)+p(3) > box(3)+1 || p(2)+p(4) > box(4)+1
                if ~(isprop(container, 'Scrollable') && strcmp(char(container.Scrollable), 'on'))
                    add('error', kids(ith_kid), sprintf('it is placed partly outside its container (%s), which does not scroll', fcn_INTERNAL_name(container)));
                end
            end
            for jth_kid = ith_kid+1:numel(kids)
                if isappdata(kids(ith_kid), 'guiDriverOverlay') || isappdata(kids(jth_kid), 'guiDriverOverlay')
                    continue;   % (a control placed on top of another on purpose, such as a name on a photo)
                end
                q = positions(jth_kid,:);
                overlapWidth = min(p(1)+p(3), q(1)+q(3)) - max(p(1), q(1));
                overlapHeight = min(p(2)+p(4), q(2)+q(4)) - max(p(2), q(2));
                if overlapWidth > 2 && overlapHeight > 2
                    add('error', kids(ith_kid), sprintf('it overlaps %s', fcn_INTERNAL_name(kids(jth_kid))));
                end
            end
        end
    end
end % Ends fcn_INTERNAL_checkLayout
