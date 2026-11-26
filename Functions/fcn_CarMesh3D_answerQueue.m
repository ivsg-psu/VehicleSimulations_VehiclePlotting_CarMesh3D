function [answers, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, options)
% fcn_CarMesh3D_answerQueue
% The answer queue: a small window for answering, quickly, the open
% questions and the tests that need a person, one at a time, by clicking.
% Claude (or anyone running a review) writes the items; the person answers
% them here; the answers are kept in a file of their own, which Claude reads
% and merges into the design files. So the two never write the same file,
% and nobody has to ask "is that file closed?" (Sean, 2026-11-25 14:36: the
% V&V GUI's pattern, for the back-and-forth itself).
%
% THE TWO FILES, in queueFolder:
%   openItems.json   the items to answer (written by Claude; read here)
%   answers.jsonl    the answers, one line each, added at every click
%                    (written here; never rewritten, only added to)
%
% openItems.json holds "Items", a list; each item has:
%   ID        "Q66" or "T73" (the running numbers of the design files)
%   Kind      "question" or "test"
%   Title     a few words
%   Text      the question, or what to look at and judge
%   Context   (optional) why it is asked: where it came up, what it affects
%   File      (optional) the design file it belongs to, and Section
%   Options   the lettered answers: Key ("A"), Text, and Recommended (true
%             for one); a test's options are its expected outcomes
%   Commands  (tests) the MATLAB commands to run first
%   CodeTests (optional) test scripts to run, by name (such as
%             "reviewVehicle" for script_test_fcn_CarMesh3D_reviewVehicle)
%
% Each line of answers.jsonl holds: ID, Choice (an option's key, or
% "BUG", "???" or "Later"), Comment, Who, When, and ItemsWritten (which
% items file it answered). The last line for an ID is its answer.
%
% THE WINDOW (G1, the pancake; P4: each decision a few seconds):
%   Top bar:  ☰ Menu (Shared GUI settings; Exit), Previous, Next, the
%             progress; "Done: copy the answers" (a short summary on the
%             clipboard, to paste into the chat); and NOW, red, for an
%             answer that must change what Claude is doing at once, or
%             for when something breaks (Sean, 16:49: "the big red button").
%   Left:     every item, with its mark (✓ answered, ✗ BUG, ? open, …
%             Later, ?? unsure); click one to go there.
%   Middle:   the item: its title, text and context; for a test, its
%             commands, "Run the commands" and "Run the code tests", and
%             what they printed.
%   Bottom:   the answers as buttons (BUG, ??? and Later besides the
%             lettered ones), a comment, and who answered and when.
%
% Run the commands: the commands run in the base workspace, as typed at
% the prompt. Two of the usual first commands are changed so they cannot
% close or break this window: "close all force" closes every other figure,
% and "clear functions" is left out (Sean's test lists begin with
% "close all force; clear functions; clc").
%
% FORMAT:
%
%       [answers, figureHandle] = fcn_CarMesh3D_answerQueue((queueFolder),...
%           (Who=initials), (FlagClipboard=flag), (FlagVisible=flag), (Watch=flag),...
%           (FlagRemember=flag), (FigNum=figNum))
%
% INPUTS:
%
%      queueFolder: the folder with openItems.json. Default: the one used
%      last (a preference), else the folder answerQueue in Claude's working
%      folder, if it exists.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Who: the initials recorded with each answer. Default: yours
%      (fcn_CarMesh3D_userInfo).
%
%      FlagClipboard: true (default) to put Done's and NOW's text on the
%      clipboard; false for tests (they read it from the hooks).
%
%      FlagVisible: true (default); false builds the window hidden (tests).
%
%      Watch: true to check openItems.json every 3 s and load new items
%      while the window stays open, keeping the item shown (Sean, 23:17:
%      "can I just leave it open?"). Default: on when Visible.
%
%      FlagRemember: true (default) to remember the folder for next time (a
%      MATLAB preference, shared by every MATLAB on the computer); tests
%      pass false, so they never change it.
%
%      FigNum: not used (a window); -1 skips input checks.
%
% OUTPUTS:
%
%      answers: the answers when the window opened (the last per item), as
%      a table: ID, Choice, Comment, Who, When.
%
%      figureHandle: the window. Its UserData holds functions for scripts
%      and tests: Show(id), Answer(choice, comment), Done(), Now(), Run(),
%      RunCodeTests(), Items(), Answers(), Current(), Reload(), Menu.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_addTitleBar, fcn_CarMesh3D_makePanelMenu,
%      fcn_CarMesh3D_makeSettingsPanel, fcn_CarMesh3D_icons,
%      fcn_CarMesh3D_userInfo
%
% EXAMPLES:
%
%       fcn_CarMesh3D_answerQueue('C:\Users\me\Desktop\Claude\Project_CarMesh3D\answerQueue');
%
%       See the script: script_test_fcn_CarMesh3D_answerQueue.m for a full
%       test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_answerQueue
%   % * First write (Sean, 14:36 to 16:49; Q64 (A), Q65 (B)): the items
%   %   % and answers files; answers as buttons; Run the commands and the
%   %   % code tests; Done and NOW to the clipboard
%   % * BUG fix (T73, Sean 17:03): Run closed every other figure, so a
%   %   % test of the queue, run from the queue, closed the person's own
%   %   % queue window; now no answer-queue window is closed, and the
%   %   % status is not written to a window that has gone
%   % * The recommended answer marked right after its letter, in bold, and
%   %   % the answers across the full width (Sean, 17:10: the mark at the
%   %   % end was cut off)
%   % * Done remembers its time in the queue folder (lastDone.txt), so a
%   %   % new window's Done copies only what is new (Sean, 17:10: an old
%   %   % answer came again)
%   % * The answers laid out again whenever their area changes size, so
%   %   % they use its full width (Sean, 22:57: cut off, with space to spare;
%   %   % the width was read before the window was laid out)
%   % * Done copies comments whole (they were cut at 160 characters)
%   % * Watch: new items in openItems.json load while the window stays
%   %   % open (Sean, 23:17)
%   % * Other, always among the answers, with the comment saying what
%   %   % (Sean, 23:40)
%   % * FlagRemember=: tests never change the folder preference (BUG, 23:44:
%   %   % Sean's window opened a test's temporary folder)
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_answerQueue
%   % * Paste picture (Q93 (A), Sean 10:45): the picture on the clipboard
%   %   % (Win+Shift+S) saved as pictures\<ID>_<time>.png in the queue
%   %   % folder, named in the answer (its new field Pictures) and in Done's
%   %   % text, so Claude opens it directly; the last one shown small, with
%   %   % a count and Remove (moved to pictures\removed, never deleted). New
%   %   % hooks PastePicture (a picture may be given, for the tests),
%   %   % RemovePicture, Pictures; Answers has a Pictures column
%   %   % (drafted with Claude)
%   % * Done with nothing new since the last Done copies that Done's text
%   %   % again (kept in lastDoneText.txt), so a double press never loses
%   %   % the answers (Sean's 13:02 Done said 0 over five answers)


% TO-DO:
%
% (none)

arguments
    queueFolder = ''          % The folder with openItems.json
    options.Who = ''          % Initials; '' for yours
    options.FlagClipboard = true  % false: Done and NOW only return their text (tests)
    options.FlagVisible = true    % false: built hidden (tests)
    options.Watch = []        % Check openItems.json for new items every few seconds; [] = when Visible
    options.FlagRemember = true   % Remember the folder (a preference); false for tests
    options.FigNum = []       % Not used; -1 skips input checks
end

%% Debugging and Input checks
flag_check_inputs = ~isequal(options.FigNum, -1);
queueFolder = char(queueFolder);
if isempty(queueFolder)
    queueFolder = fcn_INTERNAL_defaultFolder();
end
if flag_check_inputs
    if isempty(queueFolder) || ~isfolder(queueFolder)
        error('CarMesh3D:badInput', 'No queue folder: give the folder that holds openItems.json.');
    end
    if ~isfile(fullfile(queueFolder, 'openItems.json'))
        error('CarMesh3D:badInput', 'The folder %s has no openItems.json.', queueFolder);
    end
end
if options.FlagRemember
    % (a preference: shared by every MATLAB on the computer, so tests pass
    % FlagRemember=false: a test that set it briefly sent Sean's window to its
    % temporary folder, 2026-11-25 23:41)
    setpref('CarMesh3D', 'AnswerQueueFolder', queueFolder);
end

%% Main code
itemsFile = fullfile(queueFolder, 'openItems.json');
answersFile = fullfile(queueFolder, 'answers.jsonl');
who = char(options.Who);
if isempty(who)
    user = fcn_CarMesh3D_userInfo(FlagAsk=logical(options.FlagVisible), FigNum=-1);
    who = user.Initials;
end

items = [];
itemsWritten = '';
latest = [];             % (the last answer per item)
currentIndex = 1;
flagShowing = false;
lastError = '';
lastOutput = '';
doneFile = fullfile(queueFolder, 'lastDone.txt');   % (when Done was last pressed, in any window: Sean, 17:10)
answerButtons = gobjects(0);   % (the answers shown, in order: placeAnswers lays them out)
itemsStamp = 0;                % (openItems.json's time when loaded: Watch reloads when it changes)
watchTimer = [];
lastDoneTime = '';
if isfile(doneFile)
    lastDoneTime = strtrim(fileread(doneFile));
end

%% The window
% (HandleVisibility off: "close all", at the top of most test scripts, then
% leaves this window open while it runs them)
figureHandle = uifigure('Name', 'fcn_CarMesh3D_answerQueue', 'Position', [60 60 1300 820], 'Visible', 'off', ...
    'Color', [1 1 1], 'AutoResizeChildren', 'off', 'HandleVisibility', 'off', 'Tag', 'answerQueue');
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_answerQueue', FigNum=-1);
mainGrid = uigridlayout(contentPanel, [2 1], 'RowHeight', {40, '1x'}, 'Padding', [6 6 6 6], 'RowSpacing', 6, ...
    'BackgroundColor', [1 1 1]);
topBar = uigridlayout(mainGrid, [1 6], 'ColumnWidth', {90, 112, 112, '1x', 190, 120}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 6, 'BackgroundColor', [1 1 1]);
menuButton = uibutton(topBar, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'Tag', 'aqMenu');
previousButton = uibutton(topBar, 'Text', 'Previous', 'Tag', 'aqPrevious', 'Tooltip', 'The previous item', ...
    'Icon', fcn_CarMesh3D_icons('questionPrevious', Height=16, FigNum=-1), 'ButtonPushedFcn', @(~,~) goPrevious());
nextButton = uibutton(topBar, 'Text', 'Next', 'Tag', 'aqNext', 'Tooltip', 'The next item', 'IconAlignment', 'right', ...
    'Icon', fcn_CarMesh3D_icons('questionNext', Height=16, FigNum=-1), 'ButtonPushedFcn', @(~,~) goNext());
progressLabel = uilabel(topBar, 'Text', '', 'FontColor', [0.3 0.3 0.3], 'Tag', 'aqProgress');
doneButton = uibutton(topBar, 'Text', 'Done: copy the answers', 'Tag', 'aqDone', 'FontWeight', 'bold', ...
    'BackgroundColor', [0.85 0.95 0.85], 'Icon', fcn_CarMesh3D_icons('summary', Height=20, FigNum=-1), ...
    'Tooltip', 'Puts a short list of your new answers on the clipboard: paste it into the chat', ...
    'ButtonPushedFcn', @(~,~) doDone());
nowButton = uibutton(topBar, 'Text', 'NOW', 'Tag', 'aqNow', 'FontWeight', 'bold', 'FontSize', 15, ...
    'FontColor', [1 1 1], 'BackgroundColor', [0.80 0.10 0.10], ...
    'Tooltip', ['An answer that must change what Claude is doing at once, or something broke: puts a NOW message ' ...
    'on the clipboard (this item, your answer and comment, and the last error), to paste into the chat'], ...
    'ButtonPushedFcn', @(~,~) doNow());

bodyGrid = uigridlayout(mainGrid, [1 3], 'ColumnWidth', {0, 250, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6, ...
    'BackgroundColor', [1 1 1]);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
itemList = uilistbox(bodyGrid, 'Items', {}, 'Tag', 'aqItemList', 'FontSize', 13, ...
    'ValueChangedFcn', @(source,~) showItem(source.Value), ...
    'Tooltip', [char(10003) ' answered   ' char(10007) ' BUG   ? open   ?? unsure   ' char(8230) ' later']);
pageGrid = uigridlayout(bodyGrid, [6 1], 'RowHeight', {34, '1x', 150, 32, 100, 22}, 'Padding', [0 0 0 0], 'RowSpacing', 5, ...
    'BackgroundColor', [1 1 1]);
headingLabel = uilabel(pageGrid, 'Text', '', 'FontSize', 20, 'FontWeight', 'bold', 'FontColor', [1 1 1], ...
    'BackgroundColor', [0.15 0.25 0.45], 'Tag', 'aqHeading');
textArea = uitextarea(pageGrid, 'Editable', 'off', 'FontSize', 14, 'Tag', 'aqText', 'WordWrap', 'on');
commandsGrid = uigridlayout(pageGrid, [1 2], 'ColumnWidth', {'1x', '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', [1 1 1]);
commandsArea = uitextarea(commandsGrid, 'Editable', 'off', 'FontName', 'Consolas', 'Tag', 'aqCommands');
outputArea = uitextarea(commandsGrid, 'Editable', 'off', 'FontName', 'Consolas', 'Tag', 'aqOutput', ...
    'Placeholder', 'What the commands and the code tests print');
runGrid = uigridlayout(pageGrid, [1 3], 'ColumnWidth', {190, 190, '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', [1 1 1]);
runButton = uibutton(runGrid, 'Text', 'Run the commands', 'Tag', 'aqRun', 'ButtonPushedFcn', @(~,~) doRun(), ...
    'Tooltip', 'Runs the commands above, as typed at the prompt (closes other figures first; keeps this window)');
codeTestsButton = uibutton(runGrid, 'Text', 'Run the code tests', 'Tag', 'aqRunCodeTests', ...
    'ButtonPushedFcn', @(~,~) doRunCodeTests(), 'Tooltip', 'Runs the test scripts this item names, and says PASS or FAIL');
runStatus = uilabel(runGrid, 'Text', '', 'Tag', 'aqRunStatus');
answerGrid = uigridlayout(pageGrid, [1 3], 'ColumnWidth', {'2x', '1x', 150}, 'Padding', [6 4 6 4], 'BackgroundColor', [0.93 0.96 1]);
answerGroup = uibuttongroup(answerGrid, 'BorderType', 'none', 'BackgroundColor', [0.93 0.96 1], 'Tag', 'aqAnswers', ...
    'SelectionChangedFcn', @(~,event) onPicked(event), 'AutoResizeChildren', 'off', 'Scrollable', 'on', ...
    'SizeChangedFcn', @(~,~) placeAnswers());
commentArea = uitextarea(answerGrid, 'Placeholder', 'Comment (optional)', 'Tag', 'aqComment', ...
    'ValueChangedFcn', @(~,~) onComment());
% (pictures with an answer: snip with Win+Shift+S, then Paste picture; each
% is saved in the queue folder's pictures folder and named in the answer,
% so Claude opens it directly; Q93 (A), Sean 2026-11-26 10:45)
pictureGrid = uigridlayout(answerGrid, [3 2], 'RowHeight', {24, '1x', 18}, 'ColumnWidth', {'1x', 'fit'}, ...
    'Padding', [0 0 0 0], 'RowSpacing', 2, 'ColumnSpacing', 4, 'BackgroundColor', [0.93 0.96 1]);
pasteButton = uibutton(pictureGrid, 'Text', 'Paste picture', 'Tag', 'aqPastePicture', ...
    'Tooltip', 'Adds the picture on the clipboard to this answer (snip one first with Win+Shift+S)', ...
    'ButtonPushedFcn', @(~,~) pastePicture());
pasteButton.Layout.Column = [1 2];
pictureImage = uiimage(pictureGrid, 'Tag', 'aqPictureThumb', 'ScaleMethod', 'fit', 'Visible', 'off', ...
    'Tooltip', 'The last picture added to this answer');
pictureImage.Layout.Row = 2;
pictureImage.Layout.Column = [1 2];
pictureCount = uilabel(pictureGrid, 'Text', '', 'FontSize', 11, 'Tag', 'aqPictureCount');
pictureCount.Layout.Row = 3;
pictureCount.Layout.Column = 1;
removePictureButton = uibutton(pictureGrid, 'Text', 'Remove', 'FontSize', 10, 'Tag', 'aqRemovePicture', 'Visible', 'off', ...
    'Tooltip', 'Takes the last picture off this answer (the file is moved to pictures\removed, not deleted)', ...
    'ButtonPushedFcn', @(~,~) removePicture());
removePictureButton.Layout.Row = 3;
removePictureButton.Layout.Column = 2;
pictureFolder = fullfile(queueFolder, 'pictures');
statusLabel = uilabel(pageGrid, 'Text', '', 'FontColor', [0.35 0.35 0.35], 'Tag', 'aqStatus');

answerMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
    Exit=@() delete(figureHandle), ExitTag='aqExit', FigNum=-1);
settingsPanel = answerMenu.AddPanel('Shared GUI settings', [0.94 0.94 0.94]);
fcn_CarMesh3D_makeSettingsPanel(settingsPanel, Used={'You'}, OnChange=@onSharedSetting, FigNum=-1);

loadItems();
answers = latestTable();
figureHandle.UserData = struct('Show', @showItem, 'Answer', @testAnswer, 'Done', @doDone, 'Now', @doNow, ...
    'Run', @doRun, 'RunCodeTests', @doRunCodeTests, 'Items', @getItems, 'Answers', @latestTable, ...
    'Current', @getCurrent, 'Reload', @loadItems, 'Menu', answerMenu, 'CheckItems', @checkItems, ...
    'PastePicture', @pastePicture, 'RemovePicture', @removePicture, 'Pictures', @currentPictures);
flagWatch = options.FlagVisible;
if ~isempty(options.Watch)
    flagWatch = logical(options.Watch);
end
if flagWatch
    watchTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 3, 'BusyMode', 'drop', ...
        'TimerFcn', @(~,~) checkItems(), 'Name', 'answerQueueWatch', 'Tag', 'answerQueueWatch');
    figureHandle.DeleteFcn = @(~,~) stopWatch();
    start(watchTimer);
end
if options.FlagVisible
    figureHandle.Visible = 'on';
end

%% Nested functions (they share the window's state above)

    function loadItems(keepID)
        loaded = jsondecode(fileread(itemsFile));
        itemsStamp = java.io.File(itemsFile).lastModified();
        items = fcn_INTERNAL_items(loaded);
        itemsWritten = '';
        if isfield(loaded, 'Written')
            itemsWritten = char(loaded.Written);
        end
        latest = fcn_INTERNAL_readAnswers(answersFile);
        currentIndex = 1;
        for ith_item = 1:numel(items)
            % (the first item with no answer, or answered Later)
            choice = latestChoice(items(ith_item).ID);
            if isempty(choice) || strcmp(choice, 'Later')
                currentIndex = ith_item;
                break;
            end
        end
        if nargin >= 1 && ~isempty(items) && any(strcmp({items.ID}, keepID))
            currentIndex = find(strcmp({items.ID}, keepID), 1);   % (a reload keeps the item shown)
        end
        if ~isempty(items)
            showItem(currentIndex);
        else
            headingLabel.Text = '  Nothing to answer';
            textArea.Value = {'openItems.json lists no items.'};
            refreshList();
        end
    end

    function showItem(index)
        if ischar(index) || isstring(index)
            index = find(strcmp({items.ID}, char(index)), 1);
        end
        currentIndex = index;
        item = items(index);
        headingLabel.Text = sprintf('  %s.  %s', item.ID, item.Title);
        lines = {item.Text};
        if ~isempty(item.Context)
            lines = [lines, {'', ['Context: ' item.Context]}];
        end
        if ~isempty(item.File)
            where = item.File;
            if ~isempty(item.Section)
                where = sprintf('%s, %s', where, item.Section);
            end
            lines = [lines, {'', ['In: ' where]}];
        end
        textArea.Value = lines;
        flagTest = strcmp(item.Kind, 'test');
        commandsArea.Value = splitlines(item.Commands);
        outputArea.Value = {''};
        runStatus.Text = '';
        runButton.Enable = matlab.lang.OnOffSwitchState(~isempty(strtrim(item.Commands)));
        codeTestsButton.Enable = matlab.lang.OnOffSwitchState(~isempty(item.CodeTests));
        if flagTest || ~isempty(strtrim(item.Commands))
            pageGrid.RowHeight{3} = 150;
            pageGrid.RowHeight{4} = 32;
        else
            pageGrid.RowHeight{3} = 0;
            pageGrid.RowHeight{4} = 0;
        end
        % (the answers: the lettered ones, then BUG and ??? for a test, and
        % Later, for when it needs more thought)
        keys = {item.Options.Key};
        labels = cellfun(@(key, text) sprintf('(%s) %s', key, text), keys, {item.Options.Text}, 'UniformOutput', false);
        recommended = [item.Options.Recommended];
        if flagTest
            keys = [keys, {'BUG', '???'}];
            labels = [labels, {'BUG', '??? (unsure, or unexpected)'}];
            recommended = [recommended, false, false];
        end
        keys = [keys, {'Other', 'Later'}];   % (Other always: Sean, 23:40)
        labels = [labels, {'Other (say in the comment)', 'Later (needs thought)'}];
        recommended = [recommended, false, false];
        record = latestRecord(item.ID);
        selected = '';
        commentArea.Value = '';
        if ~isempty(record)
            selected = record.Choice;
            commentArea.Value = record.Comment;
        end
        setAnswers(keys, labels, recommended, selected);
        refreshPictures();
        refreshStatus();
        refreshList();
        previousButton.Enable = matlab.lang.OnOffSwitchState(currentIndex > 1);
        nextButton.Enable = matlab.lang.OnOffSwitchState(currentIndex < numel(items));
    end

    function setAnswers(keys, labels, recommended, selected)
        flagShowing = true;
        delete(answerGroup.Children);
        blank = uiradiobutton(answerGroup, 'Text', '', 'Visible', 'off', 'Position', [1 1 1 1], 'UserData', '');
        % (laid out by placeAnswers; the recommended answer says so right
        % after its letter, in bold: Sean, 17:10)
        answerButtons = gobjects(1, numel(keys));
        for ith_key = 1:numel(keys)
            text = labels{ith_key};
            if recommended(ith_key)
                text = regexprep(text, '^\((\w+)\)', '($1, recommended)', 'once');
            end
            button = uiradiobutton(answerGroup, 'Text', text, 'UserData', keys{ith_key}, 'FontSize', 13, ...
                'Position', [6, 2, 200, 20], 'Tag', ['aqAnswer_' keys{ith_key}], 'Tooltip', text);
            answerButtons(ith_key) = button;
            if recommended(ith_key)
                button.FontWeight = 'bold';
            end
            if strcmp(keys{ith_key}, 'BUG')
                button.FontColor = [0.75 0 0];
            end
            if strcmp(keys{ith_key}, selected)
                answerGroup.SelectedObject = button;
            end
        end
        if isempty(selected)
            answerGroup.SelectedObject = blank;
        end
        placeAnswers();
        drawnow limitrate;
        flagShowing = false;
    end

    function placeAnswers()
        % (each lettered answer on its own row across the area's full width,
        % its text wrapped to as many lines as it needs, so no answer is cut
        % off; BUG, ???, Other and Later share the last row. The answer row
        % of the page grows to fit, up to a limit, and scrolls past it. Run
        % again whenever the area changes size, since its width is not known
        % until the window is laid out: Sean, 22:57 and 02:18)
        answerButtons = answerButtons(isvalid(answerButtons));
        numKeys = numel(answerButtons);
        if numKeys == 0
            return;
        end
        groupWidth = answerGroup.InnerPosition(3);
        if groupWidth < 100
            groupWidth = 680;   % (not laid out yet: placed again when it is)
        end
        fixedKeys = {'BUG', '???', 'Other', 'Later'};
        isFixed = arrayfun(@(button) any(strcmp(button.UserData, fixedKeys)), answerButtons);
        lineHeight = 18;
        textWidth = groupWidth - 40;   % (less the round button and margins)
        heights = zeros(1, numKeys);
        for ith_key = find(~isFixed)
            button = answerButtons(ith_key);
            charWidth = 7.2 + 0.6*strcmp(button.FontWeight, 'bold');   % (13-point text, roughly)
            numLines = max(1, ceil(numel(button.Text)*charWidth/textWidth));
            heights(ith_key) = lineHeight*numLines + 4;
        end
        rowGap = 3;
        totalHeight = sum(heights(~isFixed)) + rowGap*nnz(~isFixed) + (lineHeight + 4)*any(isFixed) + 6;
        % (the page grid's answer row fits the answers, between 70 and 260 pixels)
        wantedRow = min(260, max(70, totalHeight + 10));
        if ~isequal(pageGrid.RowHeight{5}, wantedRow)
            pageGrid.RowHeight{5} = wantedRow;
        end
        groupHeight = max(answerGroup.InnerPosition(4), totalHeight);
        top = groupHeight - 3;
        for ith_key = find(~isFixed)
            top = top - heights(ith_key);
            answerButtons(ith_key).WordWrap = 'on';
            answerButtons(ith_key).Position = [6, top, groupWidth - 12, heights(ith_key)];
            top = top - rowGap;
        end
        fixedIndices = find(isFixed);
        if ~isempty(fixedIndices)
            top = top - (lineHeight + 4);
            fixedWidth = (groupWidth - 8)/numel(fixedIndices);
            for ith_fixed = 1:numel(fixedIndices)
                answerButtons(fixedIndices(ith_fixed)).Position = [6 + fixedWidth*(ith_fixed - 1), top, fixedWidth - 5, lineHeight + 4];
            end
        end
    end

    function onPicked(event)
        if flagShowing || isempty(event.NewValue.UserData)
            return;
        end
        addAnswer(event.NewValue.UserData);
    end

    function onComment()
        current = latestRecord(items(currentIndex).ID);
        choice = '';
        if ~isempty(current)
            choice = current.Choice;
        end
        addAnswer(choice);   % (a comment alone is kept too)
    end

    function addAnswer(choice)
        % (one more line in answers.jsonl: never rewritten, only added to)
        item = items(currentIndex);
        entry = struct('ID', item.ID, 'Choice', char(choice), ...
            'Comment', strjoin(cellstr(commentArea.Value), newline), 'Who', who, ...
            'When', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), 'ItemsWritten', itemsWritten, ...
            'Pictures', {currentPictures()});
        fileID = fopen(answersFile, 'a', 'n', 'UTF-8');
        if fileID < 0
            error('CarMesh3D:answersNotWritten', 'Could not write %s.', answersFile);
        end
        fprintf(fileID, '%s\n', jsonencode(entry));
        fclose(fileID);
        latest = fcn_INTERNAL_readAnswers(answersFile);
        refreshStatus();
        refreshList();
    end

    function checkItems()
        % (Watch: when openItems.json has changed, load it, keeping the item
        % shown and its comment as typed)
        if ~isvalid(figureHandle) || ~isfile(itemsFile)
            return;
        end
        if java.io.File(itemsFile).lastModified() == itemsStamp
            return;
        end
        try
            keepID = '';
            typedComment = commentArea.Value;
            if ~isempty(items)
                keepID = items(currentIndex).ID;
            end
            loadItems(keepID);
            if ~isempty(items) && strcmp(items(currentIndex).ID, keepID)
                commentArea.Value = typedComment;   % (a comment being typed is kept)
            end
            statusLabel.Text = sprintf('New items loaded (%s): %d items.', ...
                char(datetime('now', 'Format', 'HH:mm')), numel(items));
        catch loadError
            statusLabel.Text = ['openItems.json could not be read (it may be being written): ' loadError.message];
        end
    end

    function stopWatch()
        if ~isempty(watchTimer) && isvalid(watchTimer)
            stop(watchTimer);
            delete(watchTimer);
        end
    end

    function goPrevious()
        showItem(max(1, currentIndex - 1));
    end

    function goNext()
        showItem(min(numel(items), currentIndex + 1));
    end

    %% Running
    function outputText = doRun()
        % (the commands, as typed at the prompt; "close all force" closes
        % the other figures, never this one, and "clear functions" is left out)
        item = items(currentIndex);
        commands = item.Commands;
        commands = regexprep(commands, 'clear\s+functions\s*;?', '');
        commands = regexprep(commands, 'close\s+all\s+force\s*;?', '');
        commands = regexprep(commands, 'close\s+all\s*;?', '');
        closeOthers();
        runStatus.Text = 'Running...';
        drawnow;
        try
            outputText = evalin('base', sprintf('evalc(%s)', fcn_INTERNAL_quote(commands)));
            statusText = 'Ran without an error.';
            statusColor = [0 0.45 0];
        catch runError
            outputText = getReport(runError, 'extended', 'hyperlinks', 'off');
            lastError = sprintf('%s: %s', item.ID, runError.message);
            statusText = ['Error: ' runError.message];
            statusColor = [0.75 0 0];
        end
        lastOutput = outputText;
        if ~isvalid(figureHandle)
            return;   % (the commands closed this window)
        end
        runStatus.Text = statusText;
        runStatus.FontColor = statusColor;
        outputArea.Value = splitlines(string(outputText));
        figure(figureHandle);   % (back in front of what the commands opened)
    end

    function results = doRunCodeTests()
        % (each named test script, run as at the prompt; PASS or FAIL)
        item = items(currentIndex);
        results = strings(numel(item.CodeTests), 1);
        for ith_test = 1:numel(item.CodeTests)
            name = char(item.CodeTests{ith_test});
            if isvalid(figureHandle)
                runStatus.Text = sprintf('Running %s (%d of %d)...', name, ith_test, numel(item.CodeTests));
                drawnow;
            end
            testFile = which(sprintf('script_test_fcn_CarMesh3D_%s.m', name));
            startTime = tic;
            try
                if isempty(testFile)
                    error('CarMesh3D:noTest', 'No test script for %s.', name);
                end
                evalin('base', sprintf('evalc(''run(''''%s'''')'');', testFile));
                results(ith_test) = sprintf('%s: PASS (%.0f s)', name, toc(startTime));
            catch testError
                results(ith_test) = sprintf('%s: FAIL: %s', name, testError.message);
                lastError = sprintf('%s: %s', item.ID, results(ith_test));
            end
            closeOthers();
        end
        lastOutput = strjoin(results, newline);
        if ~isvalid(figureHandle)
            return;   % (a test closed this window)
        end
        flagFailed = any(contains(results, 'FAIL'));
        runStatus.Text = sprintf('%d of %d passed.', sum(~contains(results, 'FAIL')), numel(results));
        runStatus.FontColor = [0 0.45 0] + flagFailed*[0.75 -0.45 0];
        outputArea.Value = cellstr(results);
    end

    function closeOthers()
        % (every figure but the answer queues: this one, and any other, such
        % as the one a person has open while a test of the queue runs in a
        % second, hidden one: found by T73, Sean 17:03)
        figures = findall(groot, 'Type', 'figure');
        delete(figures(~strcmp(get(figures, {'Tag'}), 'answerQueue')));
    end

    %% The clipboard: Done and NOW
    function textOut = doDone()
        % (the answers since the last Done, in this window or an earlier
        % one, one line each, ready to paste into the chat)
        answered = latestTable();
        if ~isempty(lastDoneTime)
            answered = answered(answered.When > string(lastDoneTime), :);
        end
        % (nothing new since the last Done, as after a second press: the
        % last Done's text again, so a double press never loses it; Sean's
        % Done of 2026-11-26 13:02 copied "0" over five answers)
        doneTextFile = fullfile(queueFolder, 'lastDoneText.txt');
        if height(answered) == 0 && isfile(doneTextFile)
            textOut = sprintf('(Nothing new since the last Done, %s; this is that Done again.)\n%s', ...
                lastDoneTime, fileread(doneTextFile));
            copyText(textOut);
            statusLabel.Text = 'Nothing new since the last Done: its answers copied again.';
            return;
        end
        lines = {sprintf('ANSWERS (fcn_CarMesh3D_answerQueue, %s), %d:', answersFile, height(answered))};
        for ith_row = 1:height(answered)
            line = sprintf('%s %s', answered.ID(ith_row), fcn_INTERNAL_choiceText(answered.Choice(ith_row)));
            if strlength(answered.Comment(ith_row)) > 0
                line = sprintf('%s: %s', line, fcn_INTERNAL_short(answered.Comment(ith_row), 4000));
            end
            if strlength(answered.Pictures(ith_row)) > 0
                line = sprintf('%s [pictures in %s: %s]', line, pictureFolder, answered.Pictures(ith_row));
            end
            lines{end+1} = line; %#ok<AGROW>
        end
        textOut = strjoin(lines, newline);
        lastDoneTime = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        fileID = fopen(doneTextFile, 'w', 'n', 'UTF-8');
        if fileID >= 0
            fprintf(fileID, '%s', textOut);
            fclose(fileID);
        end
        fileID = fopen(doneFile, 'w');
        if fileID >= 0
            fprintf(fileID, '%s', lastDoneTime);
            fclose(fileID);
        end
        copyText(textOut);
        statusLabel.Text = sprintf('Copied %d answers to the clipboard: paste them into the chat.', height(answered));
    end

    function textOut = doNow()
        % (the item, the answer and comment, and the last error: for an
        % answer that must change Claude's work at once, or a break)
        item = items(currentIndex);
        current = latestRecord(item.ID);
        comment = strjoin(cellstr(commentArea.Value), ' ');
        textOut = sprintf('NOW: %s (%s)', item.ID, item.Title);
        if ~isempty(current) && ~isempty(current.Choice)
            textOut = sprintf('%s: %s', textOut, fcn_INTERNAL_choiceText(current.Choice));
        end
        if ~isempty(strtrim(comment))
            textOut = sprintf('%s: %s', textOut, comment);
        end
        if ~isempty(lastError)
            textOut = sprintf('%s\nLast error: %s', textOut, fcn_INTERNAL_short(lastError, 400));
        end
        copyText(textOut);
        statusLabel.Text = 'NOW message copied: paste it into the chat.';
    end

    function copyText(textIn)
        if options.FlagClipboard
            clipboard('copy', textIn);
        end
    end

    %% Pictures with an answer (Q93 (A))
    function names = currentPictures()
        % (the pictures of the item shown: <ID>_<time>.png in the pictures
        % folder, oldest first)
        names = {};
        if isempty(items) || ~isfolder(pictureFolder)
            return;
        end
        listing = dir(fullfile(pictureFolder, sprintf('%s_*.png', items(currentIndex).ID)));
        names = sort({listing.name});
    end

    function fileName = pastePicture(imageIn)
        % The picture on the clipboard (or one given, for the tests) saved
        % with this item's answer. MATLAB's clipboard reads text only, so
        % the picture is read through Java's (tested 2026-11-26 10:05)
        fileName = '';
        if nargin < 1
            imageIn = [];
            try
                clip = java.awt.Toolkit.getDefaultToolkit().getSystemClipboard();
                flavor = java.awt.datatransfer.DataFlavor.imageFlavor;
                if clip.isDataFlavorAvailable(flavor)
                    imageIn = clip.getData(flavor);
                end
            catch
            end
            if isempty(imageIn)
                statusLabel.Text = 'No picture on the clipboard: snip one first (Win+Shift+S), then press Paste picture.';
                return;
            end
        end
        if ~isfolder(pictureFolder)
            mkdir(pictureFolder);
        end
        stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        fileName = sprintf('%s_%s.png', items(currentIndex).ID, stamp);
        suffix = 1;
        while isfile(fullfile(pictureFolder, fileName))
            suffix = suffix + 1;
            fileName = sprintf('%s_%s_%d.png', items(currentIndex).ID, stamp, suffix);
        end
        if isnumeric(imageIn) || islogical(imageIn)
            imwrite(imageIn, fullfile(pictureFolder, fileName));
        else
            javax.imageio.ImageIO.write(imageIn, 'png', java.io.File(fullfile(pictureFolder, fileName)));
        end
        addAnswer(latestChoice(items(currentIndex).ID));   % (the answer now names the picture)
        refreshPictures();
        statusLabel.Text = sprintf('Picture added: %s', fileName);
    end

    function removePicture()
        % (the last picture taken off this answer: moved to pictures\removed,
        % never deleted)
        names = currentPictures();
        if isempty(names)
            return;
        end
        removedFolder = fullfile(pictureFolder, 'removed');
        if ~isfolder(removedFolder)
            mkdir(removedFolder);
        end
        movefile(fullfile(pictureFolder, names{end}), fullfile(removedFolder, names{end}));
        addAnswer(latestChoice(items(currentIndex).ID));
        refreshPictures();
        statusLabel.Text = sprintf('Picture taken off: %s (moved to pictures\\removed)', names{end});
    end

    function refreshPictures()
        names = currentPictures();
        flagAny = ~isempty(names);
        pictureImage.Visible = matlab.lang.OnOffSwitchState(flagAny);
        removePictureButton.Visible = matlab.lang.OnOffSwitchState(flagAny);
        if flagAny
            pictureImage.ImageSource = fullfile(pictureFolder, names{end});
            pictureCount.Text = sprintf('%d picture%s', numel(names), repmat('s', 1, numel(names) > 1));
        else
            pictureCount.Text = '';
        end
    end

    %% The record
    function found = latestRecord(id)
        found = [];
        if ~isempty(latest) && isKey(latest, id)
            found = latest(id);
        end
    end

    function choice = latestChoice(id)
        choice = '';
        record = latestRecord(id);
        if ~isempty(record)
            choice = record.Choice;
        end
    end

    function answerTable = latestTable()
        ids = {items.ID};
        rows = cell(0, 6);
        for ith_item = 1:numel(ids)
            record = latestRecord(ids{ith_item});
            if ~isempty(record)
                rows(end+1, :) = {string(record.ID), string(record.Choice), string(record.Comment), ...
                    string(record.Who), string(record.When), string(strjoin(cellstr(record.Pictures), ', '))}; %#ok<AGROW>
            end
        end
        if isempty(rows)
            answerTable = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
                'VariableNames', {'ID', 'Choice', 'Comment', 'Who', 'When', 'Pictures'});
        else
            answerTable = cell2table(rows, 'VariableNames', {'ID', 'Choice', 'Comment', 'Who', 'When', 'Pictures'});
        end
    end

    function refreshStatus()
        item = items(currentIndex);
        record = latestRecord(item.ID);
        if isempty(record) || isempty(record.Choice)
            statusLabel.Text = 'Not answered yet.';
        else
            statusLabel.Text = sprintf('%s by %s, %s.', fcn_INTERNAL_choiceText(record.Choice), record.Who, record.When);
        end
        numAnswered = sum(arrayfun(@(entry) ~isempty(latestChoice(entry.ID)) && ~strcmp(latestChoice(entry.ID), 'Later'), items));
        progressLabel.Text = sprintf('Item %d of %d   ·   %d answered', currentIndex, numel(items), numAnswered);
    end

    function refreshList()
        labels = cell(1, numel(items));
        for ith_item = 1:numel(items)
            labels{ith_item} = sprintf('%s  %s  %s', fcn_INTERNAL_mark(latestChoice(items(ith_item).ID)), ...
                items(ith_item).ID, items(ith_item).Title);
        end
        itemList.Items = labels;
        itemList.ItemsData = 1:numel(items);
        if ~isempty(items)
            itemList.Value = currentIndex;
        end
    end

    function setMenuWidth(width)
        bodyGrid.ColumnWidth{1} = width;
    end

    function onSharedSetting(name, value)
        if strcmp(name, 'Initials')
            who = char(value);
        end
    end

    %% For scripts and tests
    function testAnswer(choice, comment)
        if nargin >= 2
            commentArea.Value = comment;
        end
        addAnswer(choice);
    end

    function value = getItems()
        value = items;
    end

    function current = getCurrent()
        current = struct('Index', currentIndex, 'ID', items(currentIndex).ID, 'Status', statusLabel.Text, ...
            'RunStatus', runStatus.Text, 'Output', lastOutput, 'LastError', lastError);
    end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_defaultFolder
function folder = fcn_INTERNAL_defaultFolder()
% The folder used last, else Claude's working folder's answerQueue
folder = '';
if ispref('CarMesh3D', 'AnswerQueueFolder') && isfolder(getpref('CarMesh3D', 'AnswerQueueFolder'))
    folder = getpref('CarMesh3D', 'AnswerQueueFolder');
    return;
end
guess = fullfile(char(java.lang.System.getProperty('user.home')), 'Desktop', 'Claude', 'Project_CarMesh3D', 'answerQueue');
if isfolder(guess)
    folder = guess;
end
end % Ends fcn_INTERNAL_defaultFolder

%% fcn_INTERNAL_items
function items = fcn_INTERNAL_items(loaded)
% The items, each with every field (blank when not given)
items = struct('ID', {}, 'Kind', {}, 'Title', {}, 'Text', {}, 'Context', {}, 'File', {}, 'Section', {}, ...
    'Options', {}, 'Commands', {}, 'CodeTests', {});
if ~isfield(loaded, 'Items') || isempty(loaded.Items)
    return;
end
raw = loaded.Items;
if isstruct(raw)
    raw = num2cell(raw);
end
for ith_item = 1:numel(raw)
    source = raw{ith_item};
    item = struct();
    for name = {'ID', 'Kind', 'Title', 'Text', 'Context', 'File', 'Section', 'Commands'}
        value = '';
        if isfield(source, name{1}) && ~isempty(source.(name{1}))
            value = source.(name{1});
            if iscell(value) || (isstring(value) && numel(value) > 1)
                value = strjoin(cellstr(value), newline);   % (a list of lines)
            end
        end
        item.(name{1}) = char(value);
    end
    if isempty(item.Kind)
        item.Kind = 'question';
        if startsWith(item.ID, 'T')
            item.Kind = 'test';
        end
    end
    % (the options: Key, Text, Recommended)
    optionList = struct('Key', {}, 'Text', {}, 'Recommended', {});
    if isfield(source, 'Options') && ~isempty(source.Options)
        rawOptions = source.Options;
        if isstruct(rawOptions)
            rawOptions = num2cell(rawOptions);
        end
        for ith_option = 1:numel(rawOptions)
            option = rawOptions{ith_option};
            recommended = isfield(option, 'Recommended') && ~isempty(option.Recommended) && logical(option.Recommended);
            optionList(end+1) = struct('Key', char(option.Key), 'Text', char(option.Text), 'Recommended', recommended); %#ok<AGROW>
        end
    end
    if isempty(optionList)
        optionList = struct('Key', {'Yes', 'No'}, 'Text', {'yes', 'no'}, 'Recommended', {false, false});
    end
    item.Options = optionList;
    codeTests = {};
    if isfield(source, 'CodeTests') && ~isempty(source.CodeTests)
        codeTests = cellstr(source.CodeTests);
    end
    item.CodeTests = reshape(codeTests, 1, []);
    items(end+1) = item; %#ok<AGROW>
end
end % Ends fcn_INTERNAL_items

%% fcn_INTERNAL_readAnswers
function latest = fcn_INTERNAL_readAnswers(answersFile)
% The last answer for each item (a map from ID to its record)
latest = containers.Map('KeyType', 'char', 'ValueType', 'any');
if ~isfile(answersFile)
    return;
end
lines = splitlines(string(fileread(answersFile)));
for ith_line = 1:numel(lines)
    if strlength(strtrim(lines(ith_line))) == 0
        continue;
    end
    try
        record = jsondecode(lines(ith_line));
    catch
        continue;   % (a broken line is passed over, never fatal)
    end
    for name = {'ID', 'Choice', 'Comment', 'Who', 'When'}
        if ~isfield(record, name{1}) || isempty(record.(name{1}))
            record.(name{1}) = '';
        end
        record.(name{1}) = char(record.(name{1}));
    end
    if ~isfield(record, 'Pictures') || isempty(record.Pictures)
        record.Pictures = {};
    end
    record.Pictures = cellstr(record.Pictures);
    latest(record.ID) = record;
end
end % Ends fcn_INTERNAL_readAnswers

%% fcn_INTERNAL_mark
function mark = fcn_INTERNAL_mark(choice)
switch choice
    case ''
        mark = '?';
    case 'BUG'
        mark = char(10007);
    case '???'
        mark = '??';
    case 'Later'
        mark = char(8230);
    otherwise
        mark = char(10003);
end
end % Ends fcn_INTERNAL_mark

%% fcn_INTERNAL_choiceText
function textOut = fcn_INTERNAL_choiceText(choice)
% "(A)" for a lettered answer; BUG, ??? and Later as they are
choice = char(choice);
if any(strcmp(choice, {'BUG', '???', 'Later', 'Other', ''}))
    textOut = choice;
else
    textOut = sprintf('(%s)', choice);
end
end % Ends fcn_INTERNAL_choiceText

%% fcn_INTERNAL_short
function textOut = fcn_INTERNAL_short(textIn, maxLength)
textOut = regexprep(char(textIn), '\s+', ' ');
if numel(textOut) > maxLength
    textOut = [textOut(1:maxLength - 3) '...'];
end
end % Ends fcn_INTERNAL_short

%% fcn_INTERNAL_quote
function quoted = fcn_INTERNAL_quote(textIn)
% Text as a MATLAB char literal
quoted = ['''' strrep(strrep(char(textIn), '''', ''''''), newline, ''' newline ''') ''''];
quoted = ['[' quoted ']'];
end % Ends fcn_INTERNAL_quote
