function settings = fcn_CarMesh3D_makeSettingsPanel(container, options)
% fcn_CarMesh3D_makeSettingsPanel
% The SHARED GUI SETTINGS panel: one panel, the same in every CarMesh3D
% GUI, holding the settings the GUIs share (Sean, 2026-11-24 16:09: "a
% 'Shared GUI settings' panel... we could grey out areas irrelevant to a
% particular parent GUI. That way the exact same UI is used throughout,
% with very few test cases needed once it is working"). Its sections:
%
%   You           your initials (default SBB): the reviewer's answers, the
%                 painter's change log
%   View          the starting view (and Reset view's): the dial angle and
%                 how far the camera looks down
%   Demo vehicle  the demo vehicle now, and "Back to the repo's demo"
%   Editing       a timestamped copy at each save?, and the folder for them
%   Review        the V&V GUI: "Stop at the first No?", "After an answer,
%                 go to", and one row per assessment: required ones On
%                 (greyed), optional ones Off or On
%                 (fcn_CarMesh3D_reviewChecks)
%
% A section the host GUI does not use is GREYED OUT, NEVER HIDDEN, with a
% tooltip naming the GUIs that use it (rule G26). Each section has its own
% Reset button; "Reset all to defaults" is at the bottom.
%
% The settings are the user's MATLAB preferences, in the group CarMesh3D,
% shared by every GUI (rule G22). A change applies to windows opened from
% now on (Q46 (A), Sean 2026-11-24 16:25); the host's own window may follow
% it at once through OnChange. The photo options and the ground are NOT
% here: they are in Overall Display, and remembered there (one place for
% each setting).
%
% FORMAT:
%
%       settings = fcn_CarMesh3D_makeSettingsPanel(container,...
%           (Used=sections), (Band=[r g b]), (OnChange=function),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      container: the panel (uipanel) to build into, such as the one the
%      ☰ Menu's AddPanel gives (fcn_CarMesh3D_makePanelMenu).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Used: the sections the host GUI uses, as a cell array of section
%      names ('You', 'View', 'Demo vehicle', 'Editing', 'Review'); the rest
%      are greyed out. Default: every section.
%
%      Band: the panel's background color. Default [0.94 0.94 0.94] (gray:
%      settings).
%
%      OnChange: f(name, value), called after a setting changes, with its
%      name ('Initials', 'StartViewDial', 'StartViewDown', 'VersionsAtSave',
%      'VersionFolder', 'ReviewChecksOff', 'ReviewStopAtNo', 'ReviewGoTo',
%      'DemoVehicle') and its new value.
%
%      Assessments: the host's assessment functions, when it plays a list
%      of its own (fcn_CarMesh3D_reviewVehicle's Assessments=), so the
%      Review rows match what it asks. Default {} (fcn_CarMesh3D_reviewChecks's list).
%      Default: none.
%
%      FigNum: not used (nothing is plotted). If set to -1, input checking
%      is skipped (fast mode). Default [].
%
% OUTPUTS:
%
%      settings: a structure of functions:
%           Value(name): a setting's value now (the preference, or its
%               default)
%           Set(name, value): change a setting, as the panel does
%           Reset(section): one section back to its defaults
%           ResetAll(): every section back to its defaults
%           Mark(): the panel showing the settings now
%           Used(): the sections in use
%           Controls(): the panel's controls, by name, for tests
%           Defaults(): the defaults, by name
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_reviewChecks, fcn_CarMesh3D_demoVehicle
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_makeSettingsPanel.m for
%       a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeSettingsPanel
%   % * First write (the shared-panels design file, sections 4 and 5):
%   %   % the viewer's GUI settings and the painter's Settings made one
%   %   % shared panel, with the sections a GUI does not use greyed out;
%   %   % the Review section's required and optional checks
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeSettingsPanel
%   % * Review, for the V&V GUI: "Stop at the first No?" (default On,
%   %   % Sean 23:18) and "After an answer, go to" (Next always, Next
%   %   % unanswered, Next unanswered or No (default), Stay here: Sean
%   %   % 23:18 and 23:21); the rows are the assessment functions, with
%   %   % titles and tooltips from their describe mode

% TO-DO:
%
% (the design file's section 4 also lists, not built yet: timestamped
% copies at each Apply and every 10 minutes, the recovery file, the day
% and night background colors)

arguments
    container
    options.Used = {'You', 'View', 'Demo vehicle', 'Editing', 'Review'}   % The sections the host uses
    options.Band = [0.94 0.94 0.94]   % Background color (gray: settings)
    options.OnChange = []             % f(name, value) after a change; [] for none
    options.Assessments = {}          % The host's assessment functions, if not the list (tests)
    options.FigNum = []               % Not used; -1 for fast mode
end

%% Debugging and Input checks
allSections = {'You', 'View', 'Demo vehicle', 'Editing', 'Review'};
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
    if ~isgraphics(container)
        error('CarMesh3D:badInput', 'container must be a panel (uipanel).');
    end
    used = cellstr(options.Used);
    if ~all(ismember(used, allSections))
        error('CarMesh3D:badInput', 'Used must name sections from: %s.', strjoin(allSections, ', '));
    end
    if ~isempty(options.OnChange) && ~isa(options.OnChange, 'function_handle')
        error('CarMesh3D:badInput', 'OnChange must be a function handle or empty.');
    end
end

%% Main code
used = cellstr(options.Used);
band = options.Band;
defaults = struct('Initials', 'SBB', 'StartViewDial', 60, 'StartViewDown', 20, 'VersionsAtSave', true, ...
    'VersionFolder', '', 'ReviewChecksOff', {{}}, 'ReviewStopAtNo', true, 'ReviewGoTo', 'nextUnansweredOrNo');
sectionNames = struct('You', {{'Initials'}}, 'View', {{'StartViewDial', 'StartViewDown'}}, ...
    'DemoVehicle', {{'DemoVehicle'}}, 'Editing', {{'VersionsAtSave', 'VersionFolder'}}, 'Review', {{'ReviewChecksOff', 'ReviewStopAtNo', 'ReviewGoTo'}});
usedBy = struct('You', 'the painter and the reviewer', 'View', 'the viewer, the painter and the reviewer', ...
    'DemoVehicle', 'every GUI', 'Editing', 'the painter (and the reviewer, which holds it)', 'Review', 'the V&V GUI (fcn_CarMesh3D_reviewVehicle)');
controls = struct();
sectionControls = struct();
sectionStack = {''};   % (the section being built)
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={}, Assessments=options.Assessments, FigNum=-1);

% The rows: built in order, each section's heights noted
rowHeights = {};
delete(container.Children);
grid = uigridlayout(container, [40 2], 'ColumnWidth', {150, '1x'}, 'Padding', [8 8 8 8], 'RowSpacing', 6, ...
    'BackgroundColor', band, 'Scrollable', 'on');

% (You)
startSection('You', 'You', 'Your initials: saved with your review answers and in the painter''s change log');
addText('Your initials', 'Saved with each review answer, and as "Who" in the painter''s change log (default SBB)');
controls.Initials = uieditfield(grid, 'text', 'Tag', 'settingsInitials', 'ValueChangedFcn', @(source,~) setValue('Initials', source.Value));
placeRight(controls.Initials, 24);
endSection();

% (View)
startSection('View', 'View', 'Where the camera starts (and where Reset view goes)');
addText('Start: dial angle?', 'Where the camera starts, as the photo dial reads it: 0 is the front, 90 the left side (default 60)');
controls.StartViewDial = uieditfield(grid, 'numeric', 'Limits', [-360 360], 'Tag', 'startViewDial', ...
    'ValueChangedFcn', @(source,~) setValue('StartViewDial', source.Value));
placeRight(controls.StartViewDial, 24);
addText('Start: looking down?', 'How far above the vehicle the camera starts, in degrees (default 20)');
controls.StartViewDown = uieditfield(grid, 'numeric', 'Limits', [-89 89], 'Tag', 'startViewDown', ...
    'ValueChangedFcn', @(source,~) setValue('StartViewDown', source.Value));
placeRight(controls.StartViewDown, 24);
addNote('Show ground? and the photo options are in Overall Display, and remembered there.');
endSection();

% (Demo vehicle)
startSection('DemoVehicle', 'Demo vehicle', 'The vehicle the demos and tools use when none is named (pick one in the library browser)');
controls.DemoText = uilabel(grid, 'Text', '', 'WordWrap', 'on', 'FontColor', [0.3 0.3 0.3], 'Tag', 'settingsDemoText');
controls.DemoText.Layout.Row = numel(rowHeights) + 1;
controls.DemoText.Layout.Column = [1 2];
rowHeights{end+1} = 36;
noteSection(controls.DemoText);
controls.RepoDemo = uibutton(grid, 'Text', 'Back to the repo''s demo', 'Tag', 'settingsRepoDemo', ...
    'ButtonPushedFcn', @(~,~) resetSection('Demo vehicle'), ...
    'Tooltip', 'Forget your own demo vehicle: the repo''s choice is used again');
placeRight(controls.RepoDemo, 26);
controls.RepoDemo.Layout.Column = [1 2];   % (its whole text: in one column it was cut off, seen 2026-11-24)
endSection();

% (Editing)
startSection('Editing', 'Editing', 'Timestamped copies of the painter''s edits');
addText('Copy at each save?', ['Each save also keeps a timestamped copy of the edits and the edited mesh ' ...
    '(<mesh name>_YYYYMMDDHHMMSS.mat), in the folder below (default On)']);
controls.VersionsAtSave = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
    @(value) setValue('VersionsAtSave', value), 'settingsVersionsAtSave');
placeRight(controls.VersionsAtSave, 24);
addText('Copies go in', 'The folder for the timestamped copies: made if it does not exist; empty for the default (beside the edits file)');
controls.VersionBrowse = uibutton(grid, 'Text', 'Browse...', 'Tag', 'settingsVersionBrowse', 'ButtonPushedFcn', @(~,~) browseVersionFolder());
placeRight(controls.VersionBrowse, 24);
controls.VersionFolder = uieditfield(grid, 'text', 'Tag', 'settingsVersionFolder', 'Placeholder', '(default: beside the edits file)', ...
    'ValueChangedFcn', @(source,~) setValue('VersionFolder', source.Value));
controls.VersionFolder.Layout.Row = numel(rowHeights) + 1;
controls.VersionFolder.Layout.Column = [1 2];
rowHeights{end+1} = 24;
noteSection(controls.VersionFolder);
endSection();

% (Review: one row per check, from the one list)
startSection('Review', 'Review', ['The V&V GUI: where it goes after an answer, and its assessments. Required: always asked. ' ...
    'Optional: turn off to skip it for every vehicle (recorded as turned off in each review)']);
addText('Stop at the first No?', ['On: an answer that means a problem goes straight to the Summary, since the ' ...
    'list puts basic assessments first. Off: the review goes on (default On)']);
controls.ReviewStopAtNo = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
    @(value) setValue('ReviewStopAtNo', value), 'settingsReviewStopAtNo');
placeRight(controls.ReviewStopAtNo, 24);
addText('After an answer, go to', ['Next always: the next question, answered or not. Next unanswered: the next ' ...
    'question with no answer (or a stale one). Next unanswered or No: the same, and also questions answered No, ' ...
    'to look again (default). Stay here: stay on this question']);
controls.ReviewGoTo = uidropdown(grid, 'Items', {'Next always', 'Next unanswered', 'Next unanswered or No', 'Stay here'}, ...
    'ItemsData', {'next', 'nextUnanswered', 'nextUnansweredOrNo', 'stay'}, 'Tag', 'settingsReviewGoTo', ...
    'ValueChangedFcn', @(source,~) setValue('ReviewGoTo', source.Value));
placeRight(controls.ReviewGoTo, 24);
controls.Review = struct();
for ith_check = 1:height(checkList)
    key = char(checkList.Key(ith_check));
    titleText = char(checkList.Title(ith_check));
    tip = char(checkList.Description(ith_check));
    if checkList.Required(ith_check)
        % (a required check: plain text, since it cannot be turned off; a
        % greyed radio pair drew as nothing at all, seen 2026-11-24)
        addText(titleText, [tip ' (required: always asked)']);
        group = uilabel(grid, 'Text', 'On (required)', 'FontColor', [0.45 0.45 0.45], 'Tag', ['review_' key], ...
            'Tooltip', 'Required: always asked');
    else
        label = addText(titleText, [tip ' (optional)']);
        group = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, @(value) setCheck(key, value), ['review_' key]);
        if ~checkList.Built(ith_check)
            set([group; group.Children], 'Enable', 'off');
            group.Tooltip = sprintf('Not available: %s', tip);
            set(label, 'FontColor', [0.55 0.55 0.55], 'FontAngle', 'italic');
        end
    end
    group.UserData = struct('Key', key, 'Required', checkList.Required(ith_check), 'Built', checkList.Built(ith_check));
    placeRight(group, 24);
    controls.Review.(key) = group;
end
addNote('Required assessments cannot be turned off. Gray: its function could not describe itself (see its tooltip).');
endSection();

% (Reset all, and when changes apply)
resetAllButton = uibutton(grid, 'Text', 'Reset all to defaults', 'Tag', 'resetAllSettings', 'ButtonPushedFcn', @(~,~) resetAll(), ...
    'Tooltip', 'Every section in use here back to its defaults');
resetAllButton.Layout.Row = numel(rowHeights) + 1;
resetAllButton.Layout.Column = [1 2];
rowHeights{end+1} = 28;
controls.ResetAll = resetAllButton;
applyNote = uilabel(grid, 'Text', 'Changes apply to windows opened from now on.', 'FontColor', [0.4 0.4 0.4], ...
    'FontSize', 11, 'WordWrap', 'on', 'Tag', 'settingsApplyNote');
applyNote.Layout.Row = numel(rowHeights) + 1;
applyNote.Layout.Column = [1 2];
rowHeights{end+1} = 'fit';
grid.RowHeight = rowHeights;

markAll();

settings = struct('Value', @getValue, 'Set', @setValue, 'Reset', @resetSection, 'ResetAll', @resetAll, ...
    'Mark', @markAll, 'Used', @() used, 'Controls', @() controls, 'Defaults', @() defaults);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the panel's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Building
    function startSection(field, title, tip)
        % (a section's heading, with its Reset button at the right)
        heading = uilabel(grid, 'Text', title, 'FontWeight', 'bold', 'FontColor', [0.25 0.25 0.25], 'Tooltip', tip);
        heading.Layout.Row = numel(rowHeights) + 1;
        heading.Layout.Column = 1;
        resetButton = uibutton(grid, 'Text', 'Reset', 'Tag', ['settingsReset' field], 'ButtonPushedFcn', @(~,~) resetSection(title), ...
            'Tooltip', sprintf('%s back to its defaults', title));
        resetButton.Layout.Row = numel(rowHeights) + 1;
        resetButton.Layout.Column = 2;
        rowHeights{end+1} = 24;
        sectionControls.(field) = struct('Title', title, 'Heading', heading, 'Reset', resetButton, 'Items', gobjects(0));
        controls.(['Reset' field]) = resetButton;
        sectionStack{1} = field;
    end

    function noteSection(component)
        field = sectionStack{1};
        sectionControls.(field).Items(end+1) = component;
    end

    function label = addText(textIn, tip)
        label = uilabel(grid, 'Text', textIn, 'Tooltip', tip, 'WordWrap', 'on');
        label.Layout.Row = numel(rowHeights) + 1;
        label.Layout.Column = 1;
        noteSection(label);
    end

    function placeRight(component, height)
        component.Layout.Row = numel(rowHeights) + 1;
        component.Layout.Column = 2;
        rowHeights{end+1} = height;
        noteSection(component);
    end

    function addNote(textIn)
        note = uilabel(grid, 'Text', textIn, 'FontColor', [0.45 0.45 0.45], 'FontSize', 11, 'WordWrap', 'on');
        note.Layout.Row = numel(rowHeights) + 1;
        note.Layout.Column = [1 2];
        rowHeights{end+1} = 'fit';
        noteSection(note);
    end

    function endSection()
        % (a section the host does not use: greyed, never hidden, with a
        % tooltip naming the GUIs that use it: rule G26)
        field = sectionStack{1};
        section = sectionControls.(field);
        if ~any(strcmp(used, section.Title))
            why = sprintf('Used by %s (not this window)', usedBy.(field));
            items = [section.Items(:); section.Reset];
            for ith_item = 1:numel(items)
                fcn_INTERNAL_disable(items(ith_item), why);
            end
            set(section.Heading, 'FontColor', [0.6 0.6 0.6], 'Tooltip', why);
        end
        spacer = uilabel(grid, 'Text', '');
        spacer.Layout.Row = numel(rowHeights) + 1;
        spacer.Layout.Column = [1 2];
        rowHeights{end+1} = 4;
    end

    %% The settings
    function value = getValue(name)
        name = char(name);
        if strcmp(name, 'DemoVehicle')
            value = fcn_CarMesh3D_demoVehicle(FigNum=-1);
            return;
        end
        if ~isfield(defaults, name)
            error('CarMesh3D:badInput', 'No setting named ''%s''.', name);
        end
        value = defaults.(name);
        if ispref('CarMesh3D', name)
            value = getpref('CarMesh3D', name);
        end
    end

    function setValue(name, value)
        name = char(name);
        if isnumeric(value) && isscalar(value) && isnan(value)
            return;
        end
        switch name
            case 'Initials'
                value = upper(strtrim(char(value)));
                if isempty(value)
                    value = defaults.Initials;
                end
            case {'StartViewDial', 'StartViewDown'}
                value = double(value);
            case 'VersionsAtSave'
                value = logical(value);
            case 'VersionFolder'
                value = strtrim(char(value));
            case 'ReviewStopAtNo'
                value = logical(value);
            case 'ReviewGoTo'
                value = char(value);
                goToValues = {'next', 'nextUnanswered', 'nextUnansweredOrNo', 'stay'};
                if ~any(strcmp(goToValues, value))
                    error('CarMesh3D:badInput', 'ReviewGoTo must be one of: %s.', strjoin(goToValues, ', '));
                end
            case 'ReviewChecksOff'
                value = cellstr(value);
                optionalKeys = cellstr(checkList.Key(~checkList.Required));
                value = reshape(intersect(value, optionalKeys, 'stable'), 1, []);   % (a row, always)
            otherwise
                error('CarMesh3D:badInput', 'No setting named ''%s''.', name);
        end
        if strcmp(name, 'VersionFolder') && isempty(value)
            if ispref('CarMesh3D', name)
                rmpref('CarMesh3D', name);
            end
        else
            setpref('CarMesh3D', name, value);
        end
        markAll();
        if ~isempty(options.OnChange)
            options.OnChange(name, value);
        end
    end

    function setCheck(key, flagOn)
        if isnumeric(flagOn) && isnan(flagOn)
            return;
        end
        turnedOff = getValue('ReviewChecksOff');
        if flagOn
            turnedOff = setdiff(turnedOff, {key}, 'stable');
        else
            turnedOff = union(turnedOff, {key}, 'stable');
        end
        setValue('ReviewChecksOff', turnedOff);
    end

    function browseVersionFolder()
        start = getValue('VersionFolder');
        if isempty(start) || ~isfolder(start)
            start = pwd;
        end
        picked = uigetdir(start, 'Folder for the timestamped copies');
        if ischar(picked)
            setValue('VersionFolder', picked);
        end
    end

    function resetSection(title)
        % (one section's settings back to their defaults: the preferences
        % removed, so the defaults are used)
        title = char(title);
        fields = fieldnames(sectionNames);
        field = fields(strcmpi(fields, strrep(title, ' ', '')));   % ('Demo vehicle' is the field DemoVehicle)
        if isempty(field)
            error('CarMesh3D:badInput', 'No section named ''%s'': the sections are %s.', title, strjoin(allSections, ', '));
        end
        field = field{1};
        for name = sectionNames.(field)
            if strcmp(name{1}, 'DemoVehicle')
                fcn_CarMesh3D_demoVehicle(Reset=true, FigNum=-1);
                value = fcn_CarMesh3D_demoVehicle(FigNum=-1);
            else
                if ispref('CarMesh3D', name{1})
                    rmpref('CarMesh3D', name{1});
                end
                value = defaults.(name{1});
            end
            if ~isempty(options.OnChange)
                options.OnChange(name{1}, value);
            end
        end
        markAll();
    end

    function resetAll()
        % (the sections in use here; a greyed section is left as it is)
        for ith_section = 1:numel(used)
            resetSection(used{ith_section});
        end
    end

    function markAll()
        % (the panel showing the settings now)
        if ~isfield(controls, 'Initials') || ~isvalid(controls.Initials)
            return;
        end
        controls.Initials.Value = getValue('Initials');
        controls.StartViewDial.Value = getValue('StartViewDial');
        controls.StartViewDown.Value = getValue('StartViewDown');
        [demoID, demoInfo] = fcn_CarMesh3D_demoVehicle(FigNum=-1);
        if strcmp(demoInfo.Source, 'preference')
            controls.DemoText.Text = sprintf('Yours: %s (the repo''s: %s)', demoID, demoInfo.RepoDemoID);
            flagRepoButton = any(strcmp(used, 'Demo vehicle'));
        else
            controls.DemoText.Text = sprintf('The repo''s: %s', demoID);
            flagRepoButton = false;
        end
        if any(strcmp(used, 'Demo vehicle'))
            controls.RepoDemo.Enable = matlab.lang.OnOffSwitchState(flagRepoButton);
        end
        fcn_INTERNAL_selectRadio(controls.VersionsAtSave, logical(getValue('VersionsAtSave')));
        controls.VersionFolder.Value = getValue('VersionFolder');
        fcn_INTERNAL_selectRadio(controls.ReviewStopAtNo, logical(getValue('ReviewStopAtNo')));
        controls.ReviewGoTo.Value = getValue('ReviewGoTo');
        turnedOff = getValue('ReviewChecksOff');
        for ith_row = 1:height(checkList)
            key = char(checkList.Key(ith_row));
            if ~checkList.Required(ith_row)
                fcn_INTERNAL_selectRadio(controls.Review.(key), ~any(strcmp(turnedOff, key)));
            end
        end
    end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_disable
function fcn_INTERNAL_disable(component, why)
% Grey a control out (and its buttons, for a button group), with a
% tooltip saying why
if isprop(component, 'Enable')
    component.Enable = 'off';
end
if strcmp(component.Type, 'uibuttongroup')
    set(component.Children, 'Enable', 'off');
end
if isprop(component, 'FontColor') && strcmp(component.Type, 'uilabel')
    component.FontColor = [0.6 0.6 0.6];
end
if isprop(component, 'Tooltip')
    component.Tooltip = why;
end
end % Ends fcn_INTERNAL_disable

%% fcn_INTERNAL_radioRow
function group = fcn_INTERNAL_radioRow(parent, texts, values, width, callback, tag)
% One row of side-by-side radio buttons (a button group), Off first. The
% callback gets the picked button's value.
group = uibuttongroup(parent, 'BorderType', 'none', 'BackgroundColor', parent.BackgroundColor, 'Tag', tag, ...
    'SelectionChangedFcn', @(~,event) callback(event.NewValue.UserData));
x = 2;
for ith_button = 1:numel(texts)
    uiradiobutton(group, 'Text', texts{ith_button}, 'Position', [x 1 width 22], 'UserData', values{ith_button});
    x = x + width;
end
end % Ends fcn_INTERNAL_radioRow

%% fcn_INTERNAL_selectRadio
function fcn_INTERNAL_selectRadio(group, value)
% Select the button of this value
if isempty(group) || ~isvalid(group)
    return;
end
radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton');
for ith_radio = 1:numel(radios)
    if isequal(class(radios(ith_radio).UserData), class(value)) && isequal(radios(ith_radio).UserData, value)
        if ~isequal(group.SelectedObject, radios(ith_radio))
            group.SelectedObject = radios(ith_radio);
        end
        return;
    end
end
end % Ends fcn_INTERNAL_selectRadio
