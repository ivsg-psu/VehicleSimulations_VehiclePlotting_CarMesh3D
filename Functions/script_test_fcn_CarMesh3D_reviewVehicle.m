% script_test_fcn_CarMesh3D_reviewVehicle.m
% Tests: fcn_CarMesh3D_reviewVehicle (the V&V GUI)
%
% The V&V GUI is a host: it plays assessment functions. These tests give
% it test assessments (local functions at the end of this script) that
% draw, fail, are slow, or skip, so the host itself is tested apart from
% any real assessment. The window is built hidden (Visible=false) and
% worked through its own functions (figureHandle.UserData). Every test
% runs on temporary demo copies of vehicles, and the Review settings are
% put back as they were at the end.

% REVISION HISTORY:
%
% 2026_11_21 to 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * Tests of the Model Reviewer (in git, and the backup of it)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * Rewritten for the V&V GUI (drafted with Claude): test
%   %   % assessments that draw, fail, are slow and skip; answering and
%   %   % where the window goes next ("Stop at the first No?" and "After
%   %   % an answer, go to"); errors with Retry and Skip; the Summary's
%   %   % decision and what it rested on; stale answers when the data
%   %   % change; assessments turned off; the older reviewer's answers
%   %   % kept; the format the library browser reads; batches
%   % * The two-row top bar (Sean, 12:16): vehicle buttons as pictures,
%   %   % greyed when there is none; Previous vehicle; Summary and back
%   % * The second line under the question: the assessment's Detail
%   %   % (Sean, T62)

% TO-DO:
%
% (none)

%% Set up the workspace
close all

% (temporary demo copies: the tests write answers, reports and change
% log rows, and must never change a vehicle itself)
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);
demoFolder = tempname;
vehicleFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=demoFolder, FigNum=-1);
vehicleInput = vehicleFiles.Folder;
reviewFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.mat', vehicleID));
reportFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.md', vehicleID));
cleanupDemo = onCleanup(@() fcn_INTERNAL_removeFolder(demoFolder));

% (the Review settings: set for each test, and put back at the end)
settingNames = {'ReviewChecksOff', 'ReviewStopAtNo', 'ReviewGoTo'};
settingsBefore = fcn_INTERNAL_readPrefs(settingNames);
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(settingsBefore));
setpref('CarMesh3D', 'ReviewChecksOff', {});
setpref('CarMesh3D', 'ReviewStopAtNo', true);
setpref('CarMesh3D', 'ReviewGoTo', 'nextUnansweredOrNo');

% (the test assessments: what their data is, so a change can be made)
setappdata(groot, 'zzVVTestVersion', 1);
cleanupAppdata = onCleanup(@() fcn_INTERNAL_removeAppdata());
testAssessments = {@fcn_CarMesh3D_assess_zzDraws, @fcn_CarMesh3D_assess_zzFails, ...
    @fcn_CarMesh3D_assess_zzSlow, @fcn_CarMesh3D_assess_zzSkips};

%% Basic case: the window, its pages and its record
fprintf(1, 'Basic case: the V&V GUI with test assessments\n');
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
hooks = figureHandle.UserData;

% Check variable types
assert(istable(answers));
assert(isa(figureHandle, 'matlab.ui.Figure'));

% Check variable sizes and contents
assert(all(ismember({'Assessment', 'Key', 'Title', 'Question', 'Answer', 'Problem', 'Comment', 'Who', 'When', ...
    'Fingerprint', 'Status', 'Note', 'Seconds'}, answers.Properties.VariableNames)));
assert(height(answers) == 5);   % (zzDraws asks two questions)
assert(isequal(cellstr(answers.Key)', {'drawsA', 'drawsB', 'fails', 'slow', 'skips'}));
assert(isequal(cellstr(answers.Assessment)', {'zzDraws', 'zzDraws', 'zzFails', 'zzSlow', 'zzSkips'}));
assert(numel(hooks.Pages()) == 5);
current = hooks.Current();
assert(strcmp(current.Key, 'drawsA'));   % (the first unanswered question)
drawPanel = findall(figureHandle, 'Tag', 'vvDrawPanel');
assert(~isempty(findall(drawPanel, 'Type', 'axes')));   % (the assessment drew in the host's panel)
assert(strcmp(findall(figureHandle, 'Tag', 'vvQuestion').Text, 'Is the first test picture right?'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvDetail').Text, 'A test detail line'), ...
    'The second line: the assessment''s Detail (Sean, T62)');
allPages = hooks.Pages();   % (zzFails gives no Detail: its page has no second line)
assert(isempty(allPages(3).Detail) && strcmp(allPages(3).QKey, 'fails'), 'An assessment without a Detail');
assert(isfile(reviewFile));   % (saved at once)
% (the top bar's two rows: one vehicle, so both vehicle buttons greyed,
% with greyed pictures; the question row's Previous greyed on the first)
assert(contains(findall(figureHandle, 'Tag', 'vvVehicle').Text, 'Vehicle 1 of 1'));
previousVehicleButton = findall(figureHandle, 'Tag', 'vvPreviousVehicle');
nextVehicleButton = findall(figureHandle, 'Tag', 'vvNextVehicle');
assert(strcmp(previousVehicleButton.Enable, 'off') && strcmp(nextVehicleButton.Enable, 'off'));
assert(isequal(nextVehicleButton.Icon, fcn_CarMesh3D_icons('vehicleNext', Enabled=false, Height=26)));
assert(isempty(previousVehicleButton.Text) && isempty(nextVehicleButton.Text));   % (pictures only: "Next" means questions)
assert(strcmp(findall(figureHandle, 'Tag', 'vvPrevious').Enable, 'off') && strcmp(findall(figureHandle, 'Tag', 'vvNext').Enable, 'on'));

%% The Summary and back, at any time (Sean, 2026-11-25 12:16)
fprintf(1, 'The Summary and back\n');
summaryButton = findall(figureHandle, 'Tag', 'vvSummaryButton');
assert(strcmp(summaryButton.Text, 'Summary'));
hooks.ToggleSummary();
assert(strcmp(hooks.Current().Key, 'summary') && strcmp(summaryButton.Text, 'Questions'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvNext').Enable, 'off'));
hooks.ToggleSummary();
assert(strcmp(hooks.Current().Key, 'drawsA') && strcmp(summaryButton.Text, 'Summary'));   % (the first not answered)
% (Previous and Next: one question at a time, through every question;
% Next after the last is the Summary, Previous from the Summary the last)
nextButton = findall(figureHandle, 'Tag', 'vvNext');
previousButton = findall(figureHandle, 'Tag', 'vvPrevious');
keysSeen = {hooks.Current().Key};
for ith_press = 1:10   % (a bound, so a fault cannot loop for ever)
    if ~strcmp(char(nextButton.Enable), 'on')
        break;
    end
    nextButton.ButtonPushedFcn(nextButton, []);
    keysSeen{end+1} = hooks.Current().Key; %#ok<SAGROW>
end
assert(isequal(keysSeen, {'drawsA', 'drawsB', 'fails', 'slow', 'skips', 'summary'}), ...
    'Next: every question in order, then the Summary (got %s)', strjoin(keysSeen, ', '));
assert(strcmp(summaryButton.Text, 'Questions'));
previousButton.ButtonPushedFcn(previousButton, []);
assert(strcmp(hooks.Current().Key, 'skips'), 'Previous from the Summary: the last question');
for ith_press = 1:10
    if ~strcmp(char(previousButton.Enable), 'on')
        break;
    end
    previousButton.ButtonPushedFcn(previousButton, []);
end
assert(strcmp(hooks.Current().Key, 'drawsA'), 'Previous: back to the first question');
% (the buttons themselves: the Summary button goes there and back)
summaryButton.ButtonPushedFcn(summaryButton, []);
assert(strcmp(hooks.Current().Key, 'summary'));
summaryButton.ButtonPushedFcn(summaryButton, []);
assert(strcmp(hooks.Current().Key, 'drawsA'));

%% Answering: an answer is recorded, and the window goes on
fprintf(1, 'Answering\n');
hooks.Answer('Yes', 'looks right');
answers = hooks.Answers();
assert(answers.Answer(1) == "Yes" && answers.Status(1) == "answered" && ~answers.Problem(1));
assert(answers.Comment(1) == "looks right" && answers.Who(1) == "ZZT" && strlength(answers.When(1)) > 0);
% (the status line, back on that question: who answered and when, and no
% drawing time: Q61 (A))
hooks.Show('drawsA');
statusText = hooks.Current().Status;
assert(contains(statusText, 'Yes by ZZT') && contains(statusText, char(answers.When(1))) && ~contains(statusText, 'drawn in'));
hooks.Show('drawsB');
assert(strlength(answers.Fingerprint(1)) == 64);   % (SHA-256, as hexadecimal)
assert(strcmp(hooks.Current().Key, 'drawsB'));
hooks.Answer('Yes');
assert(strcmp(hooks.Current().Key, 'fails'));   % (the next unanswered)

%% A function that fails: its error, recorded; Retry; Skip goes on
fprintf(1, 'A function that fails\n');
answers = hooks.Answers();
assert(answers.Status(3) == "error");
assert(contains(answers.Note(3), 'test failure on purpose'));
assert(~isempty(hooks.LastError()));
assert(~isempty(findall(figureHandle, 'Tag', 'vvRetry')));
assert(~isempty(findall(figureHandle, 'Tag', 'vvSkip')));
assert(contains(findall(figureHandle, 'Tag', 'vvErrorText').Text, 'test failure on purpose'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvAnswers').Enable, 'off'));   % (nothing to answer)
hooks.Retry();
assert(strcmp(hooks.Current().Key, 'fails') && ~isempty(hooks.LastError()));
hooks.SkipError();
assert(strcmp(hooks.Current().Key, 'slow'));

%% A slow function: timed
fprintf(1, 'A slow function\n');
current = hooks.Current();
assert(current.Seconds >= 1.0);
assert(~contains(current.Status, 'drawn in'));   % (the time is in the record, not the status line: Q61 (A))
hooks.Answer('Equal');
answers = hooks.Answers();
assert(answers.Seconds(4) >= 1.0 && answers.Answer(4) == "Equal" && ~answers.Problem(4));

%% A function with nothing to ask: skipped, with its reason, and passed over
fprintf(1, 'A function that skips\n');
% (skips has nothing to ask, known when the window opened, so it is passed
% over; wrapping around, the next with no answer is the one that failed)
assert(strcmp(hooks.Current().Key, 'fails'));
hooks.Show('skips');
assert(contains(findall(figureHandle, 'Tag', 'vvMessage').Text, 'Skipped: no exemplar'));
answers = hooks.Answers();
assert(answers.Status(5) == "skipped" && contains(answers.Note(5), 'no exemplar'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvAnswers').Enable, 'off'));

%% The Summary: the decision, what it rested on, the files
fprintf(1, 'The Summary\n');
hooks.Decide('Approve', 'good enough');
summary = hooks.Summary();
assert(strcmp(summary.Decision, 'Approve') && strcmp(summary.Who, 'ZZT') && strcmp(summary.Comment, 'good enough'));
assert(height(summary.RestedOn) == 5 && summary.RestedOn.Status(3) == "error");
assert(contains(summary.Counts, '3 answered (0 a problem)') && contains(summary.Counts, '1 error'));
saved = load(reviewFile);
assert(all(isfield(saved, {'vvAnswers', 'vvSummary', 'reviewTable'})));
% (the older format, read by the library browser)
assert(isequal(cellstr(saved.reviewTable.Status)', {'approved', 'approved', 'error', 'approved', 'skipped', 'approved'}));
assert(saved.reviewTable.Check(end) == "summary");
% (times to the minute, as the library browser reads them)
times = saved.reviewTable.Time(strlength(saved.reviewTable.Time) > 0);
assert(~isempty(times) && ~any(isnat(datetime(times, 'InputFormat', 'yyyy-MM-dd HH:mm'))));
assert(isfile(reportFile));
reportText = fileread(reportFile);
assert(contains(reportText, 'Decision: Approve') && contains(reportText, 'good enough'));

%% Stop at the first No
fprintf(1, 'Stop at the first No\n');
hooks.Show('drawsA');
hooks.Answer('No', 'a wheel is missing');
assert(strcmp(hooks.Current().Key, 'summary'));
assert(contains(hooks.Current().Status, 'Stopped at the first No'));
answers = hooks.Answers();
assert(answers.Problem(1));
% (off: the window goes on)
setpref('CarMesh3D', 'ReviewStopAtNo', false);
hooks.Show('drawsA');
hooks.Answer('No');
assert(strcmp(hooks.Current().Key, 'fails'));   % (the next unanswered or No: the error counts as unanswered)

%% After an answer, go to: Stay here; Next always; Next unanswered
fprintf(1, 'After an answer, go to\n');
setpref('CarMesh3D', 'ReviewGoTo', 'stay');
hooks.Show('drawsB');
hooks.Answer('Yes');
assert(strcmp(hooks.Current().Key, 'drawsB'));
setpref('CarMesh3D', 'ReviewGoTo', 'next');
hooks.Show('drawsA');
hooks.Answer('Yes');
assert(strcmp(hooks.Current().Key, 'drawsB'));   % (answered, but next always)
setpref('CarMesh3D', 'ReviewGoTo', 'nextUnanswered');
hooks.Show('drawsA');
hooks.Answer('No');
assert(strcmp(hooks.Current().Key, 'fails'));
setpref('CarMesh3D', 'ReviewGoTo', 'nextUnansweredOrNo');
hooks.Show('drawsA');
hooks.Answer('Yes');
delete(figureHandle);

%% Earlier answers are kept; a change to the data makes them stale
fprintf(1, 'Earlier answers kept, and stale ones\n');
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
hooks = figureHandle.UserData;
assert(answers.Answer(4) == "Equal");   % (kept)
assert(answers.Status(5) == "skipped");   % (known from its fingerprint call, before it is shown)
assert(strcmp(hooks.Current().Key, 'fails'));   % (the first with no current answer)
delete(figureHandle);
setappdata(groot, 'zzVVTestVersion', 2);   % (the data the test pictures are drawn from changes)
[~, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
hooks = figureHandle.UserData;
assert(strcmp(hooks.Current().Key, 'drawsA'));   % (stale: counts as unanswered)
assert(contains(hooks.Current().Status, 'the mesh changed since'));
hooks.Show('summary');
assert(contains(findall(figureHandle, 'Tag', 'vvCounts').Text, 'stale'));
saved = load(reviewFile);
assert(saved.reviewTable.Status(1) == "");   % (a stale answer is not an approval)
delete(figureHandle);

%% An assessment turned off in Shared GUI settings
fprintf(1, 'An assessment turned off\n');
setpref('CarMesh3D', 'ReviewChecksOff', {'zzSlow'});
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
hooks = figureHandle.UserData;
assert(answers.Status(4) == "turned off");
hooks.Show('slow');
assert(contains(findall(figureHandle, 'Tag', 'vvMessage').Text, 'turned off'));
saved = load(reviewFile);
assert(saved.reviewTable.Status(4) == "skipped");
delete(figureHandle);
setpref('CarMesh3D', 'ReviewChecksOff', {});
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
assert(answers.Status(4) == "answered" && answers.Answer(4) == "Equal");   % (on again: its earlier answer is back)
delete(figureHandle);

%% Shared GUI settings in the window's ☰ Menu: the Review settings
fprintf(1, 'Shared GUI settings\n');
[~, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
hooks = figureHandle.UserData;
assert(any(strcmp(hooks.Menu.Names(), 'Shared GUI settings')) && any(strcmp(hooks.Menu.Names(), 'Questions')));
hooks.Settings.Set('ReviewGoTo', 'stay');
assert(strcmp(getpref('CarMesh3D', 'ReviewGoTo'), 'stay'));
controls = hooks.Settings.Controls();
assert(strcmp(controls.ReviewGoTo.Value, 'stay'));
assert(isfield(controls.Review, 'zzDraws') && isfield(controls.Review, 'zzSkips'));
hooks.Show('drawsB');
hooks.Answer('Yes');
assert(strcmp(hooks.Current().Key, 'drawsB'));   % (applied at the next answer)
hooks.Settings.Set('ReviewGoTo', 'nextUnansweredOrNo');
% (the Questions list: one line per question, and the Summary)
questionsList = findall(figureHandle, 'Tag', 'vvQuestionsList');
assert(numel(questionsList.Items) == 6 && startsWith(questionsList.Items{6}, 'Summary'));
delete(figureHandle);

%% The older reviewer's answers are kept
fprintf(1, 'The older reviewer''s answers kept\n');
reviewTable = table("orientation", "orientation", "Does the red arrow point to the front?", "approved", "", "", "", ...
    "SBB", "2026-11-24 10:00", 'VariableNames', {'Check', 'Item', 'Question', 'Status', 'Severity', 'Cause', ...
    'Comment', 'Reviewer', 'Time'});
save(reviewFile, 'reviewTable');
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
assert(all(answers.Status(1:4) == ""));   % (a fresh start)
saved = load(reviewFile);
assert(isfield(saved, 'reviewTableOld') && saved.reviewTableOld.Check(1) == "orientation");
figureHandle.UserData.Answer('Yes');
saved = load(reviewFile);
assert(isfield(saved, 'reviewTableOld'));   % (still kept)
delete(figureHandle);

%% A batch: the caller's vehicles, in order
fprintf(1, 'A batch\n');
secondFiles = fcn_CarMesh3D_makeDemoCopy('2026_CarMesh3D_Generic_Sedan', DemoFolder=fullfile(demoFolder, 'second'), FigNum=-1);
[~, figureHandle] = fcn_CarMesh3D_reviewVehicle([], Vehicles={vehicleInput, secondFiles.Folder}, Visible=false, ...
    Reviewer='ZZT', Assessments=testAssessments);
hooks = figureHandle.UserData;
assert(hooks.Current().VehicleIndex == 1);
assert(contains(findall(figureHandle, 'Tag', 'vvVehicle').Text, 'Vehicle 1 of 2'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvPreviousVehicle').Enable, 'off') && strcmp(findall(figureHandle, 'Tag', 'vvNextVehicle').Enable, 'on'));
assert(isequal(findall(figureHandle, 'Tag', 'vvNextVehicle').Icon, fcn_CarMesh3D_icons('vehicleNext', Height=26)));
hooks.NextVehicle();
current = hooks.Current();
assert(current.VehicleIndex == 2 && strcmp(current.Vehicle, '2026_CarMesh3D_Generic_Sedan'));
% (Stop at the first No, on a fresh vehicle: the questions after it are
% recorded as not asked, and asked again when shown)
setpref('CarMesh3D', 'ReviewStopAtNo', true);
assert(strcmp(current.Key, 'drawsA'));
hooks.Answer('No');
answers = hooks.Answers();
assert(answers.Status(2) == "not asked" && contains(answers.Note(2), 'stopped at the first No'));
assert(answers.Status(4) == "not asked");
assert(contains(findall(figureHandle, 'Tag', 'vvCounts').Text, 'not asked after the first No'));
hooks.Show('drawsB');
assert(hooks.Answers().Status(2) == "");
% (after an answer, the next unanswered wraps around: from the last
% question back to the first unanswered one)
setpref('CarMesh3D', 'ReviewStopAtNo', false);
hooks.Show('slow');
hooks.Answer('Equal');
hooks.Show('drawsA');
hooks.Answer('Yes');
assert(strcmp(hooks.Current().Key, 'drawsB'));
hooks.Show('slow');
hooks.Answer('Higher');   % (skips has nothing to answer, drawsA is answered: drawsB, after wrapping)
assert(strcmp(hooks.Current().Key, 'drawsB'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvNextVehicle').Enable, 'off'));   % (the last)
assert(isfile(fullfile(secondFiles.ChecksFolder, 'review_2026_CarMesh3D_Generic_Sedan.mat')));
assert(strcmp(findall(figureHandle, 'Tag', 'vvPreviousVehicle').Enable, 'on'));
% (and back to the first vehicle)
hooks.PreviousVehicle();
assert(hooks.Current().VehicleIndex == 1 && contains(findall(figureHandle, 'Tag', 'vvVehicle').Text, 'Vehicle 1 of 2'));
assert(strcmp(findall(figureHandle, 'Tag', 'vvPreviousVehicle').Enable, 'off') && strcmp(findall(figureHandle, 'Tag', 'vvNextVehicle').Enable, 'on'));
assert(hooks.Answers().Answer(1) == "Yes", 'Back on the first vehicle: its answers are kept');
% (the picture buttons themselves)
nextVehicleButton = findall(figureHandle, 'Tag', 'vvNextVehicle');
nextVehicleButton.ButtonPushedFcn(nextVehicleButton, []);
assert(hooks.Current().VehicleIndex == 2);
delete(figureHandle);

%% Close (the window's X) and Exit (the ☰ Menu's last line) save the
%% answers and write the report
fprintf(1, 'Close and Exit\n');
delete(reportFile);
[~, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
close(figureHandle);
assert(~isvalid(figureHandle));
assert(isfile(reportFile));
delete(reportFile);
[~, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments);
assert(isempty(findall(figureHandle, 'Tag', 'vvClose')), 'No Close button in the top bar (Q62 (A))');
exitItem = findall(figureHandle, 'Tag', 'vvExit');
assert(isscalar(exitItem) && contains(exitItem.Text, 'Exit'));
exitItem.ButtonPushedFcn(exitItem, []);
assert(~isvalid(figureHandle), 'Exit closes the window');
assert(isfile(reportFile));

%% Fast mode
fprintf(1, 'Fast mode\n');
[answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='ZZT', ...
    Assessments=testAssessments, FigNum=-1);
assert(istable(answers));
delete(figureHandle);

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_reviewVehicle([], Visible=false, Reviewer='ZZT');
    error('should have failed');
catch inputError
    assert(strcmp(inputError.identifier, 'CarMesh3D:badInput'));
end
try
    fcn_CarMesh3D_reviewVehicle([], Vehicles=5, Visible=false, Reviewer='ZZT');
    error('should have failed');
catch inputError
    assert(strcmp(inputError.identifier, 'CarMesh3D:badInput'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_reviewVehicle passed.\n');

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

%% The test assessments (the same interface as fcn_CarMesh3D_assess_*)
function result = fcn_CarMesh3D_assess_zzDraws(vehicleInput, options)
% Two questions, each drawing a simple picture
arguments
    vehicleInput
    options.Mode = 'draw'
    options.Key = ''
    options.Parent = []
    options.FigNum = []
end
described = struct('Key', {'drawsA', 'drawsB'}, 'Title', {'First picture', 'Second picture'}, ...
    'Question', {'Is the first test picture right?', 'Is the second test picture right?'}, ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, 'Help', 'A test question', ...
    'Detail', 'A test detail line', ...
    'GroupKey', 'zzDraws', 'GroupTitle', 'Test pictures', 'GroupHelp', 'Test assessment: draws');
result = fcn_INTERNAL_testResult(described, vehicleInput, options);
if strcmpi(options.Mode, 'draw')
    axesHandle = fcn_CarMesh3D_assessAxes(options.Parent, 1, Captions={options.Key}, FigNum=-1);
    plot(axesHandle, 1:10, (1:10).^2);
end
end

function result = fcn_CarMesh3D_assess_zzFails(vehicleInput, options)
% Fails when it draws
arguments
    vehicleInput
    options.Mode = 'draw'
    options.Key = ''
    options.Parent = []
    options.FigNum = []
end
described = struct('Key', 'fails', 'Title', 'Fails', 'Question', 'Never asked?', 'Answers', {{'Yes', 'No'}}, ...
    'ProblemAnswers', {{'No'}}, 'Help', '', 'GroupKey', 'zzFails', 'GroupTitle', 'Fails', 'GroupHelp', 'Test assessment: fails');
result = fcn_INTERNAL_testResult(described, vehicleInput, options);
if strcmpi(options.Mode, 'draw')
    error('CarMesh3D:testFailure', 'A test failure on purpose.');
end
end

function result = fcn_CarMesh3D_assess_zzSlow(vehicleInput, options)
% Slow to draw
arguments
    vehicleInput
    options.Mode = 'draw'
    options.Key = ''
    options.Parent = []
    options.FigNum = []
end
described = struct('Key', 'slow', 'Title', 'Slow', 'Question', 'Is it as good as the exemplar?', ...
    'Answers', {{'Higher', 'Equal', 'Lower'}}, 'ProblemAnswers', {{'Lower'}}, 'Help', '', ...
    'GroupKey', 'zzSlow', 'GroupTitle', 'Slow', 'GroupHelp', 'Test assessment: slow');
result = fcn_INTERNAL_testResult(described, vehicleInput, options);
if strcmpi(options.Mode, 'draw')
    pause(1.2);
    fcn_CarMesh3D_assessAxes(options.Parent, 2, FigNum=-1);
end
end

function result = fcn_CarMesh3D_assess_zzSkips(vehicleInput, options)
% Nothing to ask for this vehicle
arguments
    vehicleInput
    options.Mode = 'draw'
    options.Key = ''
    options.Parent = []
    options.FigNum = []
end
described = struct('Key', 'skips', 'Title', 'Skips', 'Question', 'Never asked?', 'Answers', {{'Yes', 'No'}}, ...
    'ProblemAnswers', {{'No'}}, 'Help', '', 'GroupKey', 'zzSkips', 'GroupTitle', 'Skips', 'GroupHelp', 'Test assessment: skips');
result = fcn_INTERNAL_testResult(described, vehicleInput, options);
if ~strcmpi(options.Mode, 'describe')
    result.Skip = 'no exemplar for this body style (a test)';
end
end

function result = fcn_INTERNAL_testResult(described, vehicleInput, options)
% The describe structure, or the question's, with its fingerprint (the
% test data's version) and a note
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end
result = described(1);
if ~isempty(options.Key)
    result = described(strcmp({described.Key}, options.Key));
end
assert(isstruct(vehicleInput) && isfield(vehicleInput, 'Mesh'));   % (the host passes the loaded vehicle)
result.Fingerprint = fcn_CarMesh3D_fingerprint(getappdata(groot, 'zzVVTestVersion'), result.Key);
result.Skip = '';
result.Note = sprintf('test %s', result.Key);
end

%% Putting things back
function values = fcn_INTERNAL_readPrefs(names)
values = struct('Name', names, 'Had', false, 'Value', []);
for ith_name = 1:numel(names)
    if ispref('CarMesh3D', names{ith_name})
        values(ith_name).Had = true;
        values(ith_name).Value = getpref('CarMesh3D', names{ith_name});
    end
end
end

function fcn_INTERNAL_restorePrefs(values)
for ith_name = 1:numel(values)
    if values(ith_name).Had
        setpref('CarMesh3D', values(ith_name).Name, values(ith_name).Value);
    elseif ispref('CarMesh3D', values(ith_name).Name)
        rmpref('CarMesh3D', values(ith_name).Name);
    end
end
end

function fcn_INTERNAL_removeAppdata()
if isappdata(groot, 'zzVVTestVersion')
    rmappdata(groot, 'zzVVTestVersion');
end
end

function fcn_INTERNAL_removeFolder(folder)
if isfolder(folder)
    try
        rmdir(folder, 's');
    catch
    end
end
end
