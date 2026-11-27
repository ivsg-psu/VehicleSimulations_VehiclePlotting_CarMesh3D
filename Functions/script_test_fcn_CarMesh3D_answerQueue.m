% script_test_fcn_CarMesh3D_answerQueue.m
% Tests: fcn_CarMesh3D_answerQueue (the answer queue)
%
% Every test works in a temporary queue folder with its own openItems.json,
% builds the window hidden (Visible=false), with the clipboard left alone
% (Clipboard=false), and presses the window's real buttons (their
% ButtonPushedFcn) wherever a person would. The folder preference is put
% back at the end.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_answerQueue
%   % * First write (drafted with Claude): the items and the answers
%   %   % file; Previous, Next and the list; answering by the buttons and
%   %   % the comment; the last answer wins; Done and NOW; Run the
%   %   % commands (kept from closing the window) and the code tests
%   % * BUG case (T73, Sean 17:03): Run keeps every queue window open
%   % * The answers across the full width (Sean, 22:57); Watch (23:17);
%   %   % Other (23:40)

% TO-DO:
%
% (none)

%% Set up the workspace
queueFolder = tempname;
mkdir(queueFolder);
cleanupFolder = onCleanup(@() rmdir(queueFolder, 's'));
folderBefore = [];
if ispref('CarMesh3D', 'AnswerQueueFolder')
    folderBefore = getpref('CarMesh3D', 'AnswerQueueFolder');
end
cleanupPref = onCleanup(@() fcn_INTERNAL_restorePref(folderBefore));
answersFile = fullfile(queueFolder, 'answers.jsonl');

% (a passing test script, on the path for "Run the code tests")
testFolder = fullfile(queueFolder, 'tests');
mkdir(testFolder);
fileID = fopen(fullfile(testFolder, 'script_test_fcn_CarMesh3D_zzAQpass.m'), 'w');
fprintf(fileID, 'zzAQ_ran = 1;\nassert(zzAQ_ran == 1);\n');
fclose(fileID);
addpath(testFolder);
cleanupPath = onCleanup(@() rmpath(testFolder));

% (three items: two questions and a test)
items = struct('ID', {'Q90', 'Q91', 'T90'}, 'Kind', {'question', 'question', 'test'}, ...
    'Title', {'First question', 'Second question', 'A test'}, ...
    'Text', {'Which is better?', 'Keep it?', 'Does the window look right?'}, ...
    'Context', {'Came up in the test', '', ''}, 'File', {'Documentation_X.md', '', ''}, ...
    'Section', {'3. Plan', '', ''}, ...
    'Options', {struct('Key', {'A', 'B'}, 'Text', {'this one', 'that one'}, 'Recommended', {true, false}), ...
    struct('Key', {'A', 'B', 'C'}, 'Text', {'keep', 'drop', 'change'}, 'Recommended', {true, false, false}), ...
    struct('Key', {'Pass', 'Fail'}, 'Text', {'looks right', 'looks wrong'}, 'Recommended', {false, false})}, ...
    'Commands', {'', '', sprintf('close all force; clear functions; clc\nzzAQ_value = 41 + 1;\ndisp(zzAQ_value)')}, ...
    'CodeTests', {{}, {}, {'zzAQpass', 'zzAQnoSuchTest'}});
fcn_INTERNAL_writeItems(queueFolder, items);

%% Basic case: the window and its items
fprintf(1, 'Basic case: the answer queue\n');
[answers, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
hooks = figureHandle.UserData;
assert(istable(answers) && height(answers) == 0);
assert(isa(figureHandle, 'matlab.ui.Figure') && strcmp(figureHandle.HandleVisibility, 'off'));
assert(numel(hooks.Items()) == 3);
assert(strcmp(hooks.Current().ID, 'Q90'), 'The first item not answered');
assert(contains(findall(figureHandle, 'Tag', 'aqHeading').Text, 'Q90.  First question'));
textShown = strjoin(findall(figureHandle, 'Tag', 'aqText').Value, ' ');
assert(contains(textShown, 'Which is better?') && contains(textShown, 'Context: Came up in the test') && ...
    contains(textShown, 'In: Documentation_X.md, 3. Plan'));
assert(contains(findall(figureHandle, 'Tag', 'aqProgress').Text, 'Item 1 of 3'));
% (each list entry: its mark, then when it was posted: Sean, 15:50)
listItems = findall(figureHandle, 'Tag', 'aqItemList').Items;
assert(startsWith(listItems{1}, '?  (posted on: 2026_11_25, 17:00:00)  Q90'), 'The list shows when each item was posted');
% (the divider between the list and the page: the list widened and narrowed)
hooks.SetListWidth(400);
assert(hooks.ListWidth() == 400, 'The list widened');
hooks.SetListWidth(10);
assert(hooks.ListWidth() == 150, 'The list no narrower than 150 px');
assert(isscalar(findall(figureHandle, 'Tag', 'aqDivider')), 'A divider to drag');
prefNow = [];
if ispref('CarMesh3D', 'AnswerQueueFolder')
    prefNow = getpref('CarMesh3D', 'AnswerQueueFolder');
end
assert(isequal(prefNow, folderBefore), 'FlagRemember=false: the shared folder preference is never changed by a test');

% (the answers: lettered, recommended marked, and Later; no BUG for a question)
answerA = findall(figureHandle, 'Tag', 'aqAnswer_A');
assert(startsWith(answerA.Text, '(A, recommended) this one') && strcmp(answerA.FontWeight, 'bold'), ...
    'The mark right after the letter, where it is never cut off (Sean, 17:10)');
answerB = findall(figureHandle, 'Tag', 'aqAnswer_B');
assert(startsWith(answerB.Text, '(B) that one') && strcmp(answerB.FontWeight, 'normal'));
assert(~isempty(findall(figureHandle, 'Tag', 'aqAnswer_Later')) && isempty(findall(figureHandle, 'Tag', 'aqAnswer_BUG')));
assert(~isempty(findall(figureHandle, 'Tag', 'aqAnswer_Other')), 'Other, always (Sean, 23:40)');

%% Previous and Next: the real buttons
fprintf(1, 'Previous and Next\n');
previousButton = findall(figureHandle, 'Tag', 'aqPrevious');
nextButton = findall(figureHandle, 'Tag', 'aqNext');
assert(strcmp(previousButton.Enable, 'off') && strcmp(nextButton.Enable, 'on'));
nextButton.ButtonPushedFcn(nextButton, []);
assert(strcmp(hooks.Current().ID, 'Q91'));
nextButton.ButtonPushedFcn(nextButton, []);
assert(strcmp(hooks.Current().ID, 'T90') && strcmp(nextButton.Enable, 'off'));
% (a test: BUG and ??? besides its options; its commands shown)
assert(~isempty(findall(figureHandle, 'Tag', 'aqAnswer_BUG')) && ~isempty(findall(figureHandle, 'Tag', 'aqAnswer_???')));
assert(any(contains(findall(figureHandle, 'Tag', 'aqCommands').Value, 'zzAQ_value = 41 + 1;')));
previousButton.ButtonPushedFcn(previousButton, []);
previousButton.ButtonPushedFcn(previousButton, []);
assert(strcmp(hooks.Current().ID, 'Q90') && strcmp(previousButton.Enable, 'off'));
% (the list: click an item to go there)
itemList = findall(figureHandle, 'Tag', 'aqItemList');
itemList.Value = 2;
itemList.ValueChangedFcn(itemList, []);
assert(strcmp(hooks.Current().ID, 'Q91'));
hooks.Show('Q90');

%% Answering: a click is kept at once, with the comment
fprintf(1, 'Answering\n');
answerGroup = findall(figureHandle, 'Tag', 'aqAnswers');
fcn_INTERNAL_pick(figureHandle, 'B');
assert(isfile(answersFile), 'Kept at the first click');
recorded = hooks.Answers();
assert(height(recorded) == 1 && recorded.Choice(1) == "B" && recorded.Who(1) == "ZZT");
assert(contains(findall(figureHandle, 'Tag', 'aqStatus').Text, '(B) by ZZT'));
commentArea = findall(figureHandle, 'Tag', 'aqComment');
commentArea.Value = 'that one, because';
commentArea.ValueChangedFcn(commentArea, []);
recorded = hooks.Answers();
assert(recorded.Choice(1) == "B" && recorded.Comment(1) == "that one, because", 'A comment keeps the answer');
% (changed: the last answer wins; the file is only added to)
fcn_INTERNAL_pick(figureHandle, 'A');
recorded = hooks.Answers();
assert(height(recorded) == 1 && recorded.Choice(1) == "A");
assert(numel(splitlines(strtrim(fileread(answersFile)))) == 3, 'Three lines: B, the comment, then A');
assert(startsWith(itemList.Items{1}, char(10003)), 'The list marks it answered');
assert(startsWith(itemList.Items{2}, '?'), 'Not answered yet');
assert(contains(findall(figureHandle, 'Tag', 'aqProgress').Text, '1 answered'));
% (showing an answered item selects its answer, and adds no line)
hooks.Show('Q91');
hooks.Show('Q90');
assert(strcmp(answerGroup.SelectedObject.UserData, 'A'));
assert(numel(splitlines(strtrim(fileread(answersFile)))) == 3);
% (Later is not counted as answered)
hooks.Show('Q91');
fcn_INTERNAL_pick(figureHandle, 'Later');
assert(startsWith(itemList.Items{2}, char(8230)));
assert(contains(findall(figureHandle, 'Tag', 'aqProgress').Text, '1 answered'));

%% Done: the new answers, ready to paste
fprintf(1, 'Done\n');
doneButton = findall(figureHandle, 'Tag', 'aqDone');
doneButton.ButtonPushedFcn(doneButton, []);
assert(contains(findall(figureHandle, 'Tag', 'aqStatus').Text, 'Copied 2 answers'));
doneText = hooks.Done();   % (a second Done: nothing new since: the last Done's text again)
assert(contains(doneText, 'Nothing new since the last Done') && contains(doneText, 'ANSWERS') && ~contains(doneText, ', 0:'), ...
    'A second Done copies the last Done again, never an empty list');
pause(1.1);   % (When is to the second)
hooks.Show('Q91');
fcn_INTERNAL_pick(figureHandle, 'C');
doneText = hooks.Done();
assert(contains(doneText, 'Q91 (C)') && ~contains(doneText, 'Q90'), 'Only what is new since the last Done');

%% Paste picture: saved with the answer, named in Done (Q93 (A))
fprintf(1, 'Paste picture\n');
pause(1.1);   % (When is to the second: after the last Done)
hooks.Show('Q91');
pictureName = hooks.PastePicture(uint8(repmat(reshape([200 30 30], 1, 1, 3), 40, 60)));   % (a picture given: the tests cannot fill the clipboard)
assert(startsWith(pictureName, 'Q91_') && isfile(fullfile(queueFolder, 'pictures', pictureName)), 'Saved in the pictures folder');
assert(isequal(hooks.Pictures(), {pictureName}), 'Listed with the item');
assert(strcmp(findall(figureHandle, 'Tag', 'aqPictureThumb').Visible, 'on') && ...
    strcmp(findall(figureHandle, 'Tag', 'aqPictureCount').Text, '1 picture'), 'Shown small, with a count');
recorded = hooks.Answers();
assert(contains(recorded.Pictures(recorded.ID == "Q91"), pictureName), 'The answer names it');
doneText = hooks.Done();
assert(contains(doneText, pictureName) && contains(doneText, 'Q91 (C)'), 'Done names it, with the answer kept');
hooks.Show('Q90');
assert(isempty(hooks.Pictures()) && strcmp(findall(figureHandle, 'Tag', 'aqPictureThumb').Visible, 'off'), 'Another item: none');
hooks.Show('Q91');
hooks.RemovePicture();
assert(isempty(hooks.Pictures()) && isfile(fullfile(queueFolder, 'pictures', 'removed', pictureName)), 'Remove moves it aside');

%% NOW: the item, the answer and comment, and the last error
fprintf(1, 'NOW\n');
hooks.Show('Q90');
nowButton = findall(figureHandle, 'Tag', 'aqNow');
nowButton.ButtonPushedFcn(nowButton, []);
assert(contains(findall(figureHandle, 'Tag', 'aqStatus').Text, 'NOW message copied'));
nowText = hooks.Now();
assert(startsWith(nowText, 'NOW: Q90 (First question): (A): that one, because'));
assert(~contains(nowText, 'Last error'));

%% Run the commands: in the base workspace; this window stays open
fprintf(1, 'Run the commands\n');
hooks.Show('T90');
otherFigure = figure('Visible', 'off');
runButton = findall(figureHandle, 'Tag', 'aqRun');
assert(strcmp(runButton.Enable, 'on'));
runButton.ButtonPushedFcn(runButton, []);
% (the button runs the commands just after its own callback, by a timer:
% T88 BUG, 2026-11-26 23:27; wait for it)
fcn_INTERNAL_waitRun(figureHandle);
assert(isvalid(figureHandle), '"close all force" must not close this window');
assert(~isvalid(otherFigure), 'Other figures are closed');
assert(evalin('base', 'zzAQ_value') == 42);
evalin('base', 'clear zzAQ_value');
% (the button keeps what the commands print with diary, which sees nothing
% when the test itself runs inside evalc, as the quiet test runner does:
% so the printing is checked through the Run hook, which uses evalc)
assert(contains(findall(figureHandle, 'Tag', 'aqRunStatus').Text, 'without an error'));
hooks.Run();
assert(contains(hooks.Current().Output, '42'), 'What the commands print is shown');
evalin('base', 'clear zzAQ_value');
% (an error: shown, and kept for NOW)
items(3).Commands = 'error(''zzAQ:test'', ''a test error'')';
fcn_INTERNAL_writeItems(queueFolder, items);
hooks.Reload();
hooks.Show('T90');
runButton.ButtonPushedFcn(runButton, []);
fcn_INTERNAL_waitRun(figureHandle);
assert(contains(findall(figureHandle, 'Tag', 'aqRunStatus').Text, 'a test error'));
assert(strcmp(runButton.Enable, 'on'), 'Run is on again after a run');
assert(contains(hooks.Now(), 'Last error: T90: a test error'));
% (no commands: Run is greyed)
hooks.Show('Q90');
assert(strcmp(runButton.Enable, 'off'));

%% Run the code tests: PASS and FAIL
fprintf(1, 'Run the code tests\n');
hooks.Show('T90');
codeTestsButton = findall(figureHandle, 'Tag', 'aqRunCodeTests');
codeTestsButton.ButtonPushedFcn(codeTestsButton, []);
output = hooks.Current().Output;
assert(contains(output, 'zzAQpass: PASS') && contains(output, 'zzAQnoSuchTest: FAIL'));
assert(contains(findall(figureHandle, 'Tag', 'aqRunStatus').Text, '1 of 2 passed'));
assert(isvalid(figureHandle));
evalin('base', 'clear zzAQ_ran');

%% A test answered BUG
fcn_INTERNAL_pick(figureHandle, 'BUG');
assert(startsWith(itemList.Items{3}, char(10007)));

%% Reopened: the answers are read back
fprintf(1, 'Reopened\n');
delete(figureHandle);
[answers, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
hooks = figureHandle.UserData;
assert(height(answers) == 3);
assert(isequal(cellstr(answers.Choice)', {'A', 'C', 'BUG'}));
doneText = hooks.Done();
assert(~contains(doneText, 'Q90') && contains(doneText, 'T90 BUG'), 'Done: only what is new since the last Done in any window');
assert(strcmp(hooks.Current().ID, 'Q90'), 'Every item answered: it opens at the first');
% (a broken line in the file is passed over)
fileID = fopen(answersFile, 'a');
fprintf(fileID, '{"ID": "Q90", broken\n');
fclose(fileID);
hooks.Reload();
assert(height(hooks.Answers()) == 3);
delete(figureHandle);

%% A new item: the window opens there
items(2).ID = 'Q92';   % (Q92 has no answer)
fcn_INTERNAL_writeItems(queueFolder, items);
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
assert(strcmp(figureHandle.UserData.Current().ID, 'Q92'), 'The first item not answered');
delete(figureHandle);

%% The answers use the area's full width, wrapped (Sean, 22:57 and 02:18)
fprintf(1, 'The answers across the full width, wrapped\n');
items(1).Options(1).Text = repmat('a long answer that has to wrap onto more lines ', 1, 8);
fcn_INTERNAL_writeItems(queueFolder, items);
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false, FlagWatch=false);
figureHandle.UserData.Show(items(1).ID);
drawnow;
answerGroup = findall(figureHandle, 'Tag', 'aqAnswers');
groupWidth = answerGroup.InnerPosition(3);
answerA = findall(figureHandle, 'Tag', 'aqAnswer_A');
answerB = findall(figureHandle, 'Tag', 'aqAnswer_B');
answerLater = findall(figureHandle, 'Tag', 'aqAnswer_Later');
assert(strcmp(answerA.WordWrap, 'on'), 'The lettered answers wrap');
assert(answerA.Position(3) > groupWidth - 20, 'A lettered answer takes the full width: %.0f of %.0f', answerA.Position(3), groupWidth);
assert(answerA.Position(4) > answerB.Position(4), 'A long answer gets more lines');
assert(answerA.Position(2) > answerB.Position(2) && answerB.Position(2) > answerLater.Position(2), 'In order, top to bottom');
assert(answerLater.Position(3) < groupWidth/2, 'Other and Later share the last row');
figureHandle.Position(3) = figureHandle.Position(3) + 300;   % (wider: the answers follow)
drawnow;
answerGroup.SizeChangedFcn(answerGroup, []);
assert(answerA.Position(3) > answerGroup.InnerPosition(3) - 20);
delete(figureHandle);

%% Watch: new items load while the window stays open (Sean, 23:17)
fprintf(1, 'Watch\n');
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false, FlagWatch=true);
assert(~isempty(timerfindall('Tag', 'answerQueueWatch')), 'Watching');
figureHandle.UserData.Show('T90');
commentArea = findall(figureHandle, 'Tag', 'aqComment');
commentArea.Value = 'being typed';
figureHandle.UserData.CheckItems();   % (nothing changed: nothing happens)
assert(strcmp(figureHandle.UserData.Current().ID, 'T90'));
pause(1.1);   % (the file's time, to the second on some disks)
newItems = items;
newItems(end+1) = newItems(1);
newItems(end).ID = 'Q93';
newItems(end).Title = 'A new question';
fcn_INTERNAL_writeItems(queueFolder, newItems);
figureHandle.UserData.CheckItems();
assert(numel(figureHandle.UserData.Items()) == numel(items) + 1, 'The new item loaded');
assert(strcmp(figureHandle.UserData.Current().ID, 'T90'), 'The item shown is kept');
assert(strcmp(strjoin(cellstr(commentArea.Value), ''), 'being typed'), 'A comment being typed is kept');
assert(contains(findall(figureHandle, 'Tag', 'aqStatus').Text, 'New items loaded'));
delete(figureHandle);
assert(isempty(timerfindall('Tag', 'answerQueueWatch')), 'The watch stops with the window');
fcn_INTERNAL_writeItems(queueFolder, items);

%% Exit: the menu's last line
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
figureHandle.UserData.Menu.Exit();
assert(~isvalid(figureHandle));

%% FAST mode cases
fprintf(1, 'FAST mode\n');
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false, FigNum=-1);
assert(isvalid(figureHandle));
delete(figureHandle);

%% BUG cases
% (T73, Sean 17:03: Run in one queue window closed another, the person's
% own, while the queue's test ran from it)
fprintf(1, 'BUG case: Run keeps every queue window open\n');
[~, personalWindow] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
[~, figureHandle] = fcn_CarMesh3D_answerQueue(queueFolder, Who='ZZT', FlagClipboard=false, FlagVisible=false, FlagRemember=false);
otherFigure = figure('Visible', 'off');
figureHandle.UserData.Show('T90');
runButton = findall(figureHandle, 'Tag', 'aqRun');
runButton.ButtonPushedFcn(runButton, []);
fcn_INTERNAL_waitRun(figureHandle);
assert(isvalid(personalWindow), 'The other queue window was closed');
assert(~isvalid(otherFigure));
codeTestsButton = findall(figureHandle, 'Tag', 'aqRunCodeTests');
codeTestsButton.ButtonPushedFcn(codeTestsButton, []);
assert(isvalid(personalWindow) && isvalid(figureHandle));
evalin('base', 'clear zzAQ_ran');
delete(figureHandle);
delete(personalWindow);

%% Fail conditions
try
    fcn_CarMesh3D_answerQueue(fullfile(queueFolder, 'noSuchFolder'), FlagVisible=false, FlagRemember=false);
    error('test:noError', 'A folder that does not exist was taken');
catch caughtError
    assert(strcmp(caughtError.identifier, 'CarMesh3D:badInput'), caughtError.message);
end
try
    fcn_CarMesh3D_answerQueue(testFolder, FlagVisible=false, FlagRemember=false);
    error('test:noError', 'A folder with no openItems.json was taken');
catch caughtError
    assert(contains(caughtError.message, 'no openItems.json'), caughtError.message);
end

fprintf(1, 'All answerQueue tests passed.\n');
clear cleanupPath cleanupPref cleanupFolder   % (in this order: the path, the preference, then the folder)

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fcn_INTERNAL_writeItems(queueFolder, items)
fileID = fopen(fullfile(queueFolder, 'openItems.json'), 'w', 'n', 'UTF-8');
fprintf(fileID, '%s', jsonencode(struct('Written', '2026-11-25 17:00', 'Items', items), PrettyPrint=true));
fclose(fileID);
end

function fcn_INTERNAL_pick(figureHandle, key)
% Click an answer, as a person would: the group's SelectionChangedFcn
group = findall(figureHandle, 'Tag', 'aqAnswers');
button = findall(figureHandle, 'Tag', ['aqAnswer_' key]);
oldButton = group.SelectedObject;
group.SelectedObject = button;
group.SelectionChangedFcn(group, struct('NewValue', button, 'OldValue', oldButton));
end

function fcn_INTERNAL_restorePref(folderBefore)
if isempty(folderBefore)
    if ispref('CarMesh3D', 'AnswerQueueFolder')
        rmpref('CarMesh3D', 'AnswerQueueFolder');
    end
else
    setpref('CarMesh3D', 'AnswerQueueFolder', folderBefore);
end
end

%% fcn_INTERNAL_waitRun
function fcn_INTERNAL_waitRun(figureHandle)
% (waits, up to 30 s, until the Run button's timer has run the commands)
statusLabel = findall(figureHandle, 'Tag', 'aqRunStatus');
startTime = tic;
while toc(startTime) < 30 && (strcmp(statusLabel.Text, 'Running...') || ~isempty(timerfindall('Tag', 'answerQueueRun')))
    pause(0.1);
end
assert(~strcmp(statusLabel.Text, 'Running...'), 'The commands ran within 30 s');
end % Ends fcn_INTERNAL_waitRun

