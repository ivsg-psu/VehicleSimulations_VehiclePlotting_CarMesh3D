function menu = fcn_CarMesh3D_makePanelMenu(menuButton, column, options)
% fcn_CarMesh3D_makePanelMenu
% The ☰ Menu that every CarMesh3D GUI uses (rule G1, the pancake design):
% a list of panels opened from a "☰ Menu" button, and the panels it opens
% in a column at the left of the window, beside the main view. Built once
% here, so every GUI's menu works the same way and one set of tests
% serves them all (Sean, 2026-11-24 16:09: "panel reusability, especially
% as helper functions to multiple GUIs, should be a top priority").
%
%   - The menu's list opens under the button; picking a panel opens it
%     and closes the list.
%   - UP TO TWO PANELS are open at once, stacked, each scrolling on its own
%     (Sean, 16:12). A third one picked replaces the lower one. A panel
%     picked again closes. The list marks the open panels with a check.
%   - With no panel open and the list closed, the column takes no room:
%     the main view gets the whole width.
%   - A panel can be greyed in the list (not available now), with a
%     tooltip saying why.
%   - When GUIs are nested, only the top window has a menu: a child GUI
%     adds its panels to its host's menu with AddPanel (Q45 (A), Sean
%     2026-11-24 16:25).
%
% FORMAT:
%
%       menu = fcn_CarMesh3D_makePanelMenu(menuButton, column,...
%           (Resize=function), (Width=width), (OnChange=function),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      menuButton: the host's "☰ Menu" button (a uibutton, in its top
%      bar). Its ButtonPushedFcn is set here.
%
%      column: the container (uipanel, or a uigridlayout's cell) for the
%      left column: the menu's list and the open panels are built into it.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Resize: f(width), called to set the column's width: Width when
%      something is shown in it, 0 when nothing is. Default: none (the
%      host sizes the column itself).
%
%      Width: the column's width when shown, in pixels. Default 320.
%
%      OnChange: f(openNames), called after the open panels change, with
%      their names (top first). Default: none.
%
%      FigNum: not used (nothing is plotted). If set to -1, input checking
%      is skipped (fast mode). Default [].
%
% OUTPUTS:
%
%      menu: a structure of functions:
%           AddPanel(name, color): a new panel (a uipanel, hidden until
%               opened) and its line in the menu's list; returns the panel.
%               Names must be unique.
%           RemovePanel(name): take a panel and its line away (a child
%               GUI closing, such as the painter inside the reviewer)
%           Open(name): open this panel (or close it, if open); '' closes
%               every panel
%           OpenPanels(names): exactly these panels open (at most two,
%               top first); {} for none
%           Close(name): close this panel, if open
%           OpenNames(): the open panels' names, top first
%           ToggleList(): open or close the menu's list
%           ListShown(): true when the list is open
%           Panel(name): the panel's handle
%           Names(): every panel's name, in the list's order
%           SetAvailable(name, flag, why): grey a panel's line in the list
%               (and close the panel) or make it available again
%           Parts(): the list, its buttons and the panels, for tests
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_makePanelMenu.m for a
%       full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makePanelMenu
%   % * First write (the shared-panels design file, section 3): the menu
%   %   % the viewer and the painter each had, moved here; two panels
%   %   % open at once (Sean, 16:12); AddPanel and RemovePanel for nested
%   %   % GUIs (Q45 (A))

% TO-DO:
%
% (none)

arguments
    menuButton
    column
    options.Resize = []     % f(width) to size the column; [] for none
    options.Width = 320     % The column's width when shown
    options.OnChange = []   % f(openNames) after the open panels change
    options.FigNum = []     % Not used; -1 for fast mode
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
    if ~isgraphics(menuButton) || ~strcmp(menuButton.Type, 'uibutton')
        error('CarMesh3D:badInput', 'menuButton must be a uibutton (the host''s ☰ Menu button).');
    end
    if ~isgraphics(column)
        error('CarMesh3D:badInput', 'column must be a container (uipanel or uigridlayout).');
    end
    for functionOption = {'Resize', 'OnChange'}
        if ~isempty(options.(functionOption{1})) && ~isa(options.(functionOption{1}), 'function_handle')
            error('CarMesh3D:badInput', '%s must be a function handle or empty.', functionOption{1});
        end
    end
end

%% Main code
names = {};
panels = gobjects(0);
items = gobjects(0);
available = true(0);
openNames = {};
listRowHeight = 30;

columnGrid = uigridlayout(column, [2 1], 'RowHeight', {0, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 4);
% (the list: hidden while closed, so a test sees it as off the screen, as
% a person does)
listPanel = uipanel(columnGrid, 'BorderType', 'line', 'BackgroundColor', [1 1 1], 'Visible', 'off', 'Tag', 'menuList');
listGrid = uigridlayout(listPanel, [1 1], 'RowHeight', {28}, 'Padding', [4 4 4 4], 'RowSpacing', 2, ...
    'BackgroundColor', [1 1 1], 'Scrollable', 'on');
% (the open panels, stacked: one row, or two)
holderGrid = uigridlayout(columnGrid, [1 1], 'RowHeight', {'1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 6);
holderGrid.Layout.Row = 2;

menuButton.ButtonPushedFcn = @(~,~) toggleList();
if isempty(menuButton.Tooltip)
    menuButton.Tooltip = 'Open a panel at the left (up to two at once; pick an open one again to close it)';
end
% (the column keeps the width the host gave it until a panel or the list
% opens or closes: resizing it while the host is still being built moved
% the host's view, found by the viewer's tests)

menu = struct('AddPanel', @addPanel, 'RemovePanel', @removePanel, 'Open', @openPanel, 'OpenPanels', @openPanels, 'Close', @closePanel, ...
    'OpenNames', @getOpenNames, 'ToggleList', @toggleList, 'ListShown', @listShown, 'Panel', @getPanel, ...
    'Names', @getNames, 'SetAvailable', @setAvailable, 'Parts', @getParts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the menu's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function panelHandle = addPanel(name, color)
        name = char(name);
        if any(strcmp(names, name))
            error('CarMesh3D:badInput', 'The menu already has a panel named ''%s''.', name);
        end
        if nargin < 2 || isempty(color)
            color = [0.94 0.94 0.94];
        end
        names{end+1} = name;
        available(end+1) = true;
        listGrid.RowHeight = repmat({28}, 1, numel(names));
        items(end+1) = uibutton(listGrid, 'Text', ['    ' name], 'HorizontalAlignment', 'left', ...
            'BackgroundColor', color, 'UserData', name, 'Tag', ['menu_' strrep(name, ' ', '')], ...
            'ButtonPushedFcn', @(source,~) openPanel(source.UserData));
        items(end).Layout.Row = numel(names);
        panelHandle = uipanel(holderGrid, 'Title', name, 'FontWeight', 'bold', 'FontSize', 13, ...
            'BackgroundColor', color, 'Scrollable', 'on', 'Visible', 'off', 'Tag', name);
        panelHandle.Layout.Row = 1;
        panelHandle.Layout.Column = 1;
        panels(end+1) = panelHandle;
        if listShown()
            columnGrid.RowHeight{1} = listHeight();
        end
    end

    function removePanel(name)
        name = char(name);
        index = find(strcmp(names, name), 1);
        if isempty(index)
            return;
        end
        openNames = setdiff(openNames, {name}, 'stable');
        if isvalid(panels(index))
            delete(panels(index));
        end
        if isvalid(items(index))
            delete(items(index));
        end
        names(index) = [];
        panels(index) = [];
        items(index) = [];
        available(index) = [];
        listGrid.RowHeight = repmat({28}, 1, max(1, numel(names)));
        for ith_item = 1:numel(items)
            items(ith_item).Layout.Row = ith_item;
        end
        if listShown()
            columnGrid.RowHeight{1} = listHeight();
        end
        layoutPanels();
    end

    function openPanel(name)
        % Open this panel (below the one open; a third replaces the lower
        % one), or close it if it is open; '' closes every panel
        name = char(name);
        if isempty(name)
            openNames = {};
        else
            checkName(name);
            if any(strcmp(openNames, name))
                openNames = setdiff(openNames, {name}, 'stable');
            elseif available(strcmp(names, name))
                if numel(openNames) >= 2
                    openNames = openNames(1);   % (the lower one replaced)
                end
                openNames{end+1} = name;
            end
        end
        showList(false);
        layoutPanels();
    end

    function openPanels(namesIn)
        % Exactly these panels open, top first (at most two)
        namesIn = cellstr(namesIn);
        namesIn = namesIn(~cellfun(@isempty, namesIn));
        if numel(namesIn) > 2
            error('CarMesh3D:badInput', 'At most two panels can be open at once.');
        end
        for ith_name = 1:numel(namesIn)
            checkName(namesIn{ith_name});
        end
        flagOK = cellfun(@(nameIn) available(strcmp(names, nameIn)), namesIn);
        openNames = namesIn(flagOK);
        showList(false);
        layoutPanels();
    end

    function closePanel(name)
        name = char(name);
        if any(strcmp(openNames, name))
            openNames = setdiff(openNames, {name}, 'stable');
            layoutPanels();
        end
    end

    function namesOut = getNames()
        namesOut = names;   % (nested, not anonymous: the names as they are now)
    end

    function namesOut = getOpenNames()
        namesOut = openNames;
    end

    function panelHandle = getPanel(name)
        checkName(name);
        panelHandle = panels(strcmp(names, char(name)));
    end

    function setAvailable(name, flagOn, why)
        % (a panel greyed in the list, never hidden: rule G26)
        checkName(name);
        index = strcmp(names, char(name));
        available(index) = logical(flagOn);
        items(index).Enable = matlab.lang.OnOffSwitchState(flagOn);
        if nargin < 3
            why = '';
        end
        if flagOn
            items(index).Tooltip = '';
        else
            items(index).Tooltip = why;
            closePanel(name);
        end
    end

    function checkName(name)
        if ~any(strcmp(names, char(name)))
            error('CarMesh3D:badInput', 'No panel named ''%s'': the panels are %s.', char(name), strjoin(names, ', '));
        end
    end

    function toggleList()
        showList(~listShown());
    end

    function flagOn = listShown()
        flagOn = strcmp(listPanel.Visible, 'on');
    end

    function height = listHeight()
        height = max(1, numel(names))*listRowHeight + 10;
    end

    function showList(flagOn)
        if ~isvalid(columnGrid)
            return;
        end
        if flagOn
            columnGrid.RowHeight{1} = listHeight();
            listPanel.Visible = 'on';
        else
            columnGrid.RowHeight{1} = 0;
            listPanel.Visible = 'off';
        end
        resizeColumn();
    end

    function layoutPanels()
        % (the open panels stacked, top first, each its own row; the
        % list's check marks; the column's width)
        if ~isvalid(holderGrid)
            return;
        end
        numOpen = numel(openNames);
        holderGrid.RowHeight = repmat({'1x'}, 1, max(1, numOpen));
        for ith_panel = 1:numel(names)
            position = find(strcmp(openNames, names{ith_panel}), 1);
            flagOpen = ~isempty(position);
            if flagOpen
                panels(ith_panel).Layout.Row = position;
            else
                panels(ith_panel).Layout.Row = 1;
            end
            panels(ith_panel).Visible = matlab.lang.OnOffSwitchState(flagOpen);
            mark = '    ';
            if flagOpen
                mark = [char(10003) ' '];
            end
            items(ith_panel).Text = [mark names{ith_panel}];
        end
        resizeColumn();
        if ~isempty(options.OnChange)
            options.OnChange(openNames);
        end
    end

    function resizeColumn()
        if isempty(options.Resize)
            return;
        end
        if isempty(openNames) && ~listShown()
            options.Resize(0);
        else
            options.Resize(options.Width);
        end
    end

    function parts = getParts()
        parts = struct('List', listPanel, 'Items', items, 'Panels', panels, 'Holder', holderGrid, 'Names', {names});
    end

end % Ends main function
