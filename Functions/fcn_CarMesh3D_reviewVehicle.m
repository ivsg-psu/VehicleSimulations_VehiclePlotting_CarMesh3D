function [answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, options)
% fcn_CarMesh3D_reviewVehicle
% The V&V GUI (verification and validation): a host that plays a list of
% ASSESSMENT FUNCTIONS for a vehicle, one question at a time, and records
% each answer. The host holds and passes data; it makes none: each
% question's picture is drawn by its own function
% (fcn_CarMesh3D_assess_<name>), and its wording comes from that function's
% describe mode. The list, and which are on, is fcn_CarMesh3D_reviewChecks.
% (The design: Documentation_CarMesh3D_GUIdesign_VandV.md.)
%
% THE WINDOW (rule G1, the pancake: sparse, one goal):
%   Top bar, two rows, so moving between vehicles and moving between
%   questions never look alike (Sean, 2026-11-25 12:16):
%     the vehicle row: the previous and next vehicle (pictures of a
%             vehicle with a - and a +, greyed when there is none) and
%             "Vehicle 1 of 3: <name>";
%     the question row: Previous and Next (the only words "Previous" and
%             "Next" in the window), Summary (on the Summary page:
%             Questions, back to the first question not answered), and
%             the progress.
%   ☰ Menu (Shared GUI settings; Questions, a list of every question with
%   its answer; and, last, Exit) at the left.
%   Middle:   the assessment's title, and its picture.
%   Bottom:   the question, its answers (radio buttons) and a comment;
%             a status line (the function's note, who answered and
%             when).
%   Last page: the SUMMARY: every answer, and Approve or Reject. The
%             decision records what it rested on (each answer and the
%             data it was given): there is no override flag.
%
% AFTER AN ANSWER the window goes on as Shared GUI settings say (Review):
%   "Stop at the first No?" (default On): a problem answer goes straight
%       to the Summary.
%   "After an answer, go to": Next always; Next unanswered; Next
%       unanswered or No (default); Stay here.
%
% SAFEGUARDS: every call to an assessment function is timed and caught.
% A function that fails shows its error with Retry, Skip and Show error,
% and is recorded as "error"; the rest of the review goes on.
%
% STALE ANSWERS: each answer keeps the fingerprint of the data its
% picture was drawn from (fcn_CarMesh3D_fingerprint). If the mesh changes,
% the fingerprint does too, and the old answer counts as unanswered.
%
% THE RECORD is saved in the vehicle's checks folder, review_<ID>.mat,
% after every change: vvAnswers (one row per question), vvSummary (the
% decision), reviewTable (the same, in the older format the library
% browser reads) and reviewTableOld (answers from the older reviewer,
% kept). review_<ID>.md, a readable report, is written at a decision and
% at Close. A decision is also added to the vehicle's change log
% (fcn_CarMesh3D_meshHistory).
%
% FORMAT:
%
%       [answers, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput,...
%           (Vehicles=IDs), (Reviewer=initials), (Assessments=handles),...
%           (ExamplesFolder=folder), (Start=key), (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID (such as '2009_Honda_Fit_Sport'), a
%      vehicle's folder (such as a demo copy), or a structure from
%      fcn_CarMesh3D_reviewInput. [] with Vehicles: the first of them.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Vehicles: a batch, as a cell array of IDs or folders, reviewed in
%      the order given (the window never chooses vehicles: Q48). "Next
%      vehicle" goes on to the next. Default {} (one vehicle).
%
%      Reviewer: the reviewer's initials. Default: yours, from
%      fcn_CarMesh3D_userInfo (asked once, if none are saved).
%
%      Assessments: a cell array of assessment function handles in place
%      of the list in fcn_CarMesh3D_reviewChecks (a run of one's own, or
%      tests). Default {} (the list).
%
%      ExamplesFolder: where the saved examples are kept, one folder per
%      assessment (an assessment whose describe mode says Examples=true:
%      "Compare with examples" and "Save as an example"). Default: the
%      repo's Data/VandV/Examples (Q91 (A)); tests give a temporary one.
%
%      Start: the question to open at, by its key (such as 'labels' or
%      'normals'), or 'summary'; '' (default) for the first not answered
%      (Q70 (A): test commands go straight to what is judged).
%
%      FlagVisible: true (default) to show the window; false to build it
%      hidden (tests). One shown window per vehicle (Q71 (A)): a second
%      call for a vehicle already open in a shown window brings that
%      window to the front (at Start, if given) and returns it.
%
%      FigNum: not used for plotting (the window is its own). If -1,
%      input checking is skipped.
%
% OUTPUTS:
%
%      answers: the answers when the window opened (one row per
%      question): Assessment, Key, Title, Question, Answer, Problem,
%      Comment, Who, When, Fingerprint, Status, Note, Seconds, Score (NaN
%      when the question asks for none, or none is given). The window
%      keeps them up to date; read them later with
%      figureHandle.UserData.Answers().
%
%      figureHandle: the window (a uifigure). Its UserData holds functions
%      for scripts and tests: Show(page or key), Answer(text, comment),
%      Decide(text, comment), Current(), Answers(), Summary(), Pages(),
%      Retry(), SkipError(), LastError(), NextVehicle(), PreviousVehicle(),
%      ToggleSummary() (the Summary, or back to the questions), ReviewFile(),
%      ReportFile(), Score(value) (the score box), SaveExample() (returns
%      the picture's file), Examples() (the example files offered),
%      ShowExample(file), Menu, Settings.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_reviewChecks, fcn_CarMesh3D_reviewInput,
%      fcn_CarMesh3D_userInfo, fcn_CarMesh3D_addTitleBar,
%      fcn_CarMesh3D_makePanelMenu, fcn_CarMesh3D_makeSettingsPanel,
%      fcn_CarMesh3D_meshHistory, fcn_CarMesh3D_icons, the assessment
%      functions
%
% EXAMPLES:
%
%       fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_reviewVehicle.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 to 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * The Model Reviewer: a window of fixed checks (its history is in
%   %   % the backup of that version, and in git)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * Rewritten as the V&V GUI (Documentation_CarMesh3D_GUIdesign_VandV.md):
%   %   % a host that plays a list of assessment functions; caught and
%   %   % timed calls with Retry, Skip and Show error; answers with the
%   %   % fingerprint of what they rested on (stale when the mesh
%   %   % changes); "Stop at the first No?" and "After an answer, go to"
%   %   % (Sean, 23:18 and 23:21); the Summary with Approve or Reject and
%   %   % no override flag (Sean, 00:53); batches (Q48); the older
%   %   % reviewTable kept for the library browser
%   % * The top bar in two rows (Sean, 12:16): vehicles above (pictures of
%   %   % a vehicle with - and +, greyed when there is none; a previous
%   %   % vehicle added), questions below (Previous, Next, and Summary /
%   %   % Questions to go to the Summary and back at any time)
%   % * The status line no longer shows the drawing time (Q61 (A), Sean
%   %   % 12:42); it stays in the record (Seconds)
%   % * Close became Exit, the ☰ Menu's last line (Q62 (A), Sean 14:31)
%   % * BUG fixed: Previous and Next went only to questions 1 and 2 (their
%   %   % callbacks kept the page they were made with; Sean's T65, 12:16:
%   %   % "I cannot figure out how to advance")
%   % * A second line under each question, smaller and not bold: guidance
%   %   % from the assessment's Detail (Sean, T62; the V&V design file,
%   %   % Plan item 6)
%   % * "Show the commands" beside the second line: prints the commands to
%   %   % open the vehicle in the viewer and the painter (Sean, T74)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * A score with the answer, for an assessment that asks for one (its
%   %   % describe mode's Score, such as [0 10]), kept in vvAnswers.Score and
%   %   % the report (the Normals assessment; Sean, 04:41)
%   % * Examples, for an assessment that keeps them (Examples=true):
%   %   % "Compare with examples" (best first) and "Save as an example": a
%   %   % PNG of the pictures as turned, and a one-line text file, in
%   %   % Data/VandV/Examples/<assessment>/, named with the score and the
%   %   % verdict so an example is re-ranked by renaming it (Q90 (A), Q91
%   %   % (A)); new option ExamplesFolder (drafted with Claude)
%   % * Start=, the question to open at (Q70 (A)); one shown window per
%   %   % vehicle: a second call brings it to the front (Q71 (A))
%   % * The question band grows by the score and examples row when it
%   %   % shows, so Accept and Reject are not cut off (T83 BUG)

% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * A small loading window while this window opens (Q99 (A), rule G43)

% TO-DO:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * Timeouts for computing, and drawing the next picture ahead (the
%   %   % V&V design file, Later)

arguments
    vehicleInput
    options.Vehicles = {}       % A batch: IDs or folders, in order
    options.Reviewer = ''       % Initials; '' for yours (fcn_CarMesh3D_userInfo)
    options.Assessments = {}    % Function handles in place of the list
    options.ExamplesFolder = '' % Saved examples; '' for the repo's Data/VandV/Examples
    options.Start = ''          % The question to open at (its key), or 'summary'
    options.FlagVisible = true      % false: built hidden (tests)
    options.FigNum = []         % Not used; -1 skips input checks
end

%% Debugging and Input checks
flag_check_inputs = 1;
if isequal(options.FigNum, -1)
    flag_check_inputs = 0;
end
if 0~=flag_check_inputs
    if isempty(vehicleInput) && isempty(options.Vehicles)
        error('CarMesh3D:badInput', 'Give a vehicle, or a batch with Vehicles=.');
    end
    if ~isempty(options.Vehicles) && ~(iscellstr(options.Vehicles) || isstring(options.Vehicles))
        error('CarMesh3D:badInput', 'Vehicles must be a cell array of vehicle IDs or folders.');
    end
end

%% Main code
% The batch (the caller's order; one vehicle is a batch of one)
% (a small loading window at once: this window takes a few seconds to
% open; closed when it is ready. Q99 (A), rule G43, Sean 2026-11-27)
loading = fcn_CarMesh3D_loadingWindow('Opening the V&V review', Vehicle=vehicleInput, FlagVisible=options.FlagVisible);
loadingCleanup = onCleanup(@() loading.Close());
vehicleList = cellstr(options.Vehicles);
vehicleIndex = 1;
if ~isempty(vehicleInput)
    if isstruct(vehicleInput)
        vehicleList = [{vehicleInput.ID}, reshape(vehicleList, 1, [])];
    else
        vehicleList = [{char(vehicleInput)}, reshape(vehicleList, 1, [])];
    end
end
vehicleList = reshape(vehicleList, 1, []);

% One shown window per vehicle (Q71 (A)): a vehicle already open in a
% shown window is brought to the front, not opened twice
if options.FlagVisible && isscalar(vehicleList)
    existing = fcn_INTERNAL_openWindow(vehicleList{1});
    if ~isempty(existing)
        figure(existing);
        if ~isempty(options.Start)
            existing.UserData.Show(char(options.Start));
        end
        answers = existing.UserData.Answers();
        figureHandle = existing;
        return;
    end
end

% Who is reviewing
reviewerName = char(options.Reviewer);
if isempty(reviewerName)
    % (asked once, if none are saved; never for a hidden window, such as
    % in a test, where no one could answer)
    user = fcn_CarMesh3D_userInfo(FlagAsk=logical(options.FlagVisible), FigNum=-1);
    reviewerName = user.Initials;
end

% The list of questions (one page each), from the assessment functions
checkList = fcn_CarMesh3D_reviewChecks(Assessments=options.Assessments, FigNum=-1);
pages = fcn_INTERNAL_pages(checkList);
summaryIndex = numel(pages) + 1;   % (the last page)

% The state (shared by the nested functions below)
vehicle = [];
reviewFile = '';
reportFile = '';
answers = [];
summary = [];
keptOld = [];             % (answers from the older reviewer, kept)
currentFingerprints = strings(numel(pages), 1);
currentPage = 1;
lastError = [];
lastSeconds = NaN;
flagShowing = false;      % (the answer buttons being set by the window, not the user)

%% The window
figureHandle = uifigure('Name', 'fcn_CarMesh3D_reviewVehicle', 'Position', [40 40 1400 900], 'Tag', 'vvWindow', ...
    'Visible', 'off', 'Color', [1 1 1], 'CloseRequestFcn', @(~,~) onClose(), 'AutoResizeChildren', 'off');
[contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_reviewVehicle', FigNum=-1);
mainGrid = uigridlayout(contentPanel, [2 1], 'RowHeight', {72, '1x'}, 'Padding', [6 6 6 6], 'RowSpacing', 6, ...
    'BackgroundColor', [1 1 1]);

% Top bar: two rows. The vehicle row (pictures, no words) above the
% question row (Previous, Next, Summary), so "next" on a quick glance
% always means the next question (Sean, 2026-11-25 12:16; rule G41)
topBar = uigridlayout(mainGrid, [2 5], 'ColumnWidth', {90, 112, 112, 130, '1x'}, 'RowHeight', {33, 33}, ...
    'Padding', [0 0 0 0], 'ColumnSpacing', 6, 'RowSpacing', 6, 'BackgroundColor', [1 1 1]);
menuButton = uibutton(topBar, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'Tag', 'vvMenu');
menuButton.Layout.Row = [1 2];
menuButton.Layout.Column = 1;
previousVehicleButton = uibutton(topBar, 'Text', '', 'Tag', 'vvPreviousVehicle', ...
    'Icon', fcn_CarMesh3D_icons('vehiclePrevious', Height=26, FigNum=-1), 'ButtonPushedFcn', @(~,~) previousVehicle(), ...
    'Tooltip', 'The previous vehicle in the list (this vehicle''s answers are saved)');
previousVehicleButton.Layout.Row = 1;
previousVehicleButton.Layout.Column = 2;
nextVehicleButton = uibutton(topBar, 'Text', '', 'Tag', 'vvNextVehicle', ...
    'Icon', fcn_CarMesh3D_icons('vehicleNext', Height=26, FigNum=-1), 'ButtonPushedFcn', @(~,~) nextVehicle(), ...
    'Tooltip', 'The next vehicle in the list (this vehicle''s answers are saved)');
nextVehicleButton.Layout.Row = 1;
nextVehicleButton.Layout.Column = 3;
vehicleLabel = uilabel(topBar, 'Text', '', 'FontWeight', 'bold', 'Tag', 'vvVehicle');
vehicleLabel.Layout.Row = 1;
vehicleLabel.Layout.Column = [4 5];
previousButton = uibutton(topBar, 'Text', 'Previous', 'Tag', 'vvPrevious', ...
    'Icon', fcn_CarMesh3D_icons('questionPrevious', Height=16, FigNum=-1), 'IconAlignment', 'left', ...
    'Tooltip', 'The previous question', 'ButtonPushedFcn', @(~,~) goPrevious());
previousButton.Layout.Row = 2;
previousButton.Layout.Column = 2;
nextButton = uibutton(topBar, 'Text', 'Next', 'Tag', 'vvNext', ...
    'Icon', fcn_CarMesh3D_icons('questionNext', Height=16, FigNum=-1), 'IconAlignment', 'right', ...
    'Tooltip', 'The next question (after the last one: the Summary)', 'ButtonPushedFcn', @(~,~) goNext());
nextButton.Layout.Row = 2;
nextButton.Layout.Column = 3;
summaryButton = uibutton(topBar, 'Text', 'Summary', 'Tag', 'vvSummaryButton', ...
    'Icon', fcn_CarMesh3D_icons('summary', Height=20, FigNum=-1), 'IconAlignment', 'left', ...
    'ButtonPushedFcn', @(~,~) toggleSummary());
summaryButton.Layout.Row = 2;
summaryButton.Layout.Column = 4;
progressLabel = uilabel(topBar, 'Text', '', 'FontColor', [0.3 0.3 0.3], 'Tag', 'vvProgress');
progressLabel.Layout.Row = 2;
progressLabel.Layout.Column = 5;
% (Exit is the ☰ Menu's last line: Q62 (A), Sean 2026-11-25 14:31)

% Body: the ☰ Menu's column (no width until something is open), and the page
bodyGrid = uigridlayout(mainGrid, [1 2], 'ColumnWidth', {0, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6, ...
    'BackgroundColor', [1 1 1]);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
pageGrid = uigridlayout(bodyGrid, [4 1], 'RowHeight', {40, '1x', 140, 22}, 'Padding', [0 0 0 0], 'RowSpacing', 4, ...
    'BackgroundColor', [1 1 1]);
headingLabel = uilabel(pageGrid, 'Text', '', 'FontSize', 22, 'FontWeight', 'bold', 'FontColor', [1 1 1], ...
    'BackgroundColor', [0.15 0.25 0.45], 'Tag', 'vvHeading');
drawPanel = uipanel(pageGrid, 'BorderType', 'none', 'BackgroundColor', [1 1 1], 'Tag', 'vvDrawPanel', ...
    'AutoResizeChildren', 'off');
questionGrid = uigridlayout(pageGrid, [4 2], 'RowHeight', {30, 20, '1x', 0}, 'ColumnWidth', {420, '1x'}, ...
    'Padding', [6 4 6 4], 'BackgroundColor', [0.93 0.96 1]);
questionLabel = uilabel(questionGrid, 'Text', '', 'FontSize', 18, 'FontWeight', 'bold', 'Tag', 'vvQuestion');
questionLabel.Layout.Row = 1;
questionLabel.Layout.Column = [1 2];
% (the second line: guidance, smaller and not bold, from the assessment's
% Detail; Sean, T62: "Do not select Yes if unsure")
detailGrid = uigridlayout(questionGrid, [1 3], 'ColumnWidth', {'fit', 'fit', '1x'}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 8, 'BackgroundColor', questionGrid.BackgroundColor);
detailGrid.Layout.Row = 2;
detailGrid.Layout.Column = [1 2];
detailLabel = uilabel(detailGrid, 'Text', '', 'FontSize', 12, 'FontColor', [0.25 0.25 0.25], 'Tag', 'vvDetail', ...
    'WordWrap', 'off');
% (a link that prints, in the Command Window, the commands to open this
% vehicle in the viewer and the painter: Sean, T74, in place of function
% names in the guidance)
commandsLink = uihyperlink(detailGrid, 'Text', 'Show the commands', 'FontSize', 12, 'Tag', 'vvCommandsLink', ...
    'Tooltip', 'Prints, in the Command Window, the commands to open this vehicle in the viewer (to look) and the painter (to fix)', ...
    'HyperlinkClickedFcn', @(~,~) printCommands());
answerGroup = uibuttongroup(questionGrid, 'BorderType', 'none', 'BackgroundColor', [0.93 0.96 1], 'Tag', 'vvAnswers', ...
    'SelectionChangedFcn', @(~,event) onAnswerPicked(event));
answerGroup.Layout.Row = 3;
answerGroup.Layout.Column = 1;
commentArea = uitextarea(questionGrid, 'Placeholder', 'Comment (optional): what you saw', 'Tag', 'vvComment', ...
    'ValueChangedFcn', @(~,~) onCommentChanged());
commentArea.Layout.Row = 3;
commentArea.Layout.Column = 2;
% (a fourth row, shown only for an assessment that asks for a score or
% keeps examples: the score, "Compare with examples", "Save as an example")
extrasGrid = uigridlayout(questionGrid, [1 5], 'ColumnWidth', {'fit', 90, 30, 330, 'fit'}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 6, 'BackgroundColor', questionGrid.BackgroundColor);
extrasGrid.Layout.Row = 4;
extrasGrid.Layout.Column = [1 2];
scoreLabel = uilabel(extrasGrid, 'Text', 'Score:', 'FontSize', 14, 'Tag', 'vvScoreLabel');
scoreDropdown = uidropdown(extrasGrid, 'Items', {'(none)'}, 'FontSize', 14, 'Tag', 'vvScore', ...
    'ValueChangedFcn', @(~,~) onScoreChanged());
uilabel(extrasGrid, 'Text', '');
examplesDropdown = uidropdown(extrasGrid, 'Items', {'Compare with examples ...'}, 'ItemsData', {''}, 'Tag', 'vvExamples', ...
    'Tooltip', 'Saved examples of this assessment, best first: pick one to see it beside this one', ...
    'ValueChangedFcn', @(source,~) showExample(source.Value));
saveExampleButton = uibutton(extrasGrid, 'Text', 'Save as an example', 'Tag', 'vvSaveExample', ...
    'Tooltip', 'Saves these pictures, as you turned them, with your answer and score, as an example for others to compare with', ...
    'ButtonPushedFcn', @(~,~) saveExample());
examplesRoot = char(options.ExamplesFolder);
if isempty(examplesRoot)
    examplesRoot = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Data', 'VandV', 'Examples');
end
exampleWindow = [];
statusLabel = uilabel(pageGrid, 'Text', '', 'FontColor', [0.35 0.35 0.35], 'Tag', 'vvStatus');

% The ☰ Menu: Shared GUI settings, and the list of questions
reviewMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
    Exit=@() onClose(), ExitTag='vvExit', FigNum=-1);
settingsPanel = reviewMenu.AddPanel('Shared GUI settings', [0.94 0.94 0.94]);
sharedSettings = fcn_CarMesh3D_makeSettingsPanel(settingsPanel, Used={'You', 'Review'}, OnChange=@onSharedSetting, ...
    Assessments=options.Assessments, FigNum=-1);
questionsPanel = reviewMenu.AddPanel('Questions', [0.94 0.97 1]);
questionsList = uilistbox(uigridlayout(questionsPanel, [1 1], 'Padding', [6 6 6 6]), 'Items', {}, 'Tag', 'vvQuestionsList', ...
    'ValueChangedFcn', @(source,~) showPage(source.Value), ...
    'Tooltip', [char(10003) ' answered   ' char(10007) ' a problem   ? not answered   - skipped   ! error']);

loadVehicle(1);
if ~isempty(options.Start)
    startKey = char(options.Start);
    if any(strcmp([{pages.QKey}, {'summary'}], startKey))
        showPage(startKey);
    else
        warning('CarMesh3D:unknownStart', 'Start=''%s'' is not a question of this review: opened at the first not answered.', startKey);
    end
end
figureHandle.UserData = struct('Show', @testShow, 'Answer', @testAnswer, 'Decide', @testDecide, ...
    'Current', @getCurrent, 'Answers', @getAnswers, 'Summary', @getSummary, 'Pages', @() pages, ...
    'Retry', @testRetry, 'SkipError', @skipError, 'LastError', @getLastError, ...
    'NextVehicle', @nextVehicle, 'PreviousVehicle', @previousVehicle, 'ToggleSummary', @toggleSummary, ...
    'ReviewFile', @getReviewFile, 'ReportFile', @getReportFile, ...
    'Score', @testScore, 'SaveExample', @saveExample, 'Examples', @listExamples, 'ShowExample', @showExample, ...
    'Menu', reviewMenu, 'Settings', sharedSettings, 'Commands', @printCommands);
if options.FlagVisible
    figureHandle.Visible = 'on';
end

%% Nested functions (they share the window's state above)

    %% A vehicle
    function loadVehicle(index)
        vehicleIndex = index;
        vehicle = fcn_CarMesh3D_reviewInput(vehicleList{index}, FigNum=-1);
        setappdata(figureHandle, 'vvVehicleFolder', vehicle.Files.Folder);   % (one window per vehicle: Q71 (A))
        figureHandle.Name = sprintf('fcn_CarMesh3D_reviewVehicle: %s', vehicle.Name);
        titleBar.SetSubtitle(vehicle.Name);
        folder = vehicle.Files.ChecksFolder;
        if ~isfolder(folder)
            mkdir(folder);
        end
        reviewFile = fullfile(folder, sprintf('review_%s.mat', vehicle.ID));
        reportFile = fullfile(folder, sprintf('review_%s.md', vehicle.ID));
        [answers, summary, keptOld] = fcn_INTERNAL_startAnswers(pages, checkList, reviewFile);
        % (the fingerprint of what each question would draw now: cheap,
        % with no drawing, so stale answers are known before they are shown)
        for ith_page = 1:numel(pages)
            currentFingerprints(ith_page) = "";
            if ~pages(ith_page).On
                continue;
            end
            try
                result = pages(ith_page).Function(vehicle, Mode='fingerprint', Key=pages(ith_page).QKey, FigNum=-1);
                currentFingerprints(ith_page) = string(result.Fingerprint);
                % (nothing to ask for this vehicle: known now, so it is
                % passed over)
                skipText = fcn_INTERNAL_text(result, 'Skip');
                row = rowOf(ith_page);
                if ~isempty(skipText)
                    answers.Status(row) = "skipped";
                    answers.Note(row) = string(skipText);
                elseif answers.Status(row) == "skipped"
                    answers.Status(row) = "";   % (it can be asked now)
                    answers.Note(row) = "";
                end
            catch
                % (shown, and recorded, when the page is drawn)
            end
        end
        refreshVehicleRow();
        saveAnswers();
        showPage(firstPage());
    end

    function index = firstPage()
        % (the first question with no current answer; else the Summary)
        index = summaryIndex;
        for ith_page = 1:numel(pages)
            if pages(ith_page).On && ~isAnswered(ith_page) && answers.Status(rowOf(ith_page)) ~= "skipped"
                index = ith_page;
                return;
            end
        end
    end

    function nextVehicle()
        if vehicleIndex >= numel(vehicleList)
            return;
        end
        writeReport();
        loadVehicle(vehicleIndex + 1);
    end

    function previousVehicle()
        if vehicleIndex <= 1
            return;
        end
        writeReport();
        loadVehicle(vehicleIndex - 1);
    end

    function refreshVehicleRow()
        % (the vehicle buttons: active, or greyed with a greyed picture,
        % when there is no vehicle that way; one vehicle: both greyed)
        flagPrevious = vehicleIndex > 1;
        flagNext = vehicleIndex < numel(vehicleList);
        previousVehicleButton.Enable = matlab.lang.OnOffSwitchState(flagPrevious);
        previousVehicleButton.Icon = fcn_CarMesh3D_icons('vehiclePrevious', FlagEnabled=flagPrevious, Height=26, FigNum=-1);
        nextVehicleButton.Enable = matlab.lang.OnOffSwitchState(flagNext);
        nextVehicleButton.Icon = fcn_CarMesh3D_icons('vehicleNext', FlagEnabled=flagNext, Height=26, FigNum=-1);
        vehicleLabel.Text = sprintf('Vehicle %d of %d:  %s', vehicleIndex, numel(vehicleList), vehicle.Name);
    end

    % (Previous and Next as nested functions, so they read the page shown
    % now: an anonymous function would keep the page it was made with,
    % and the buttons went only to questions 1 and 2; found 2026-11-25 by
    % pressing the real buttons in the test)
    function goPrevious()
        showPage(max(1, currentPage - 1));
    end

    function goNext()
        showPage(min(summaryIndex, currentPage + 1));
    end

    function toggleSummary()
        % (Summary from any question; from the Summary, back to the first
        % question not answered, or the first question)
        if currentPage == summaryIndex
            index = firstPage();
            if index == summaryIndex
                index = find([pages.On], 1);
                if isempty(index)
                    index = 1;
                end
            end
            showPage(index);
        else
            showPage(summaryIndex);
        end
    end

    %% Showing a page
    function showPage(index)
        if ischar(index) || isstring(index)
            index = find(strcmp([{pages.QKey}, {'summary'}], char(index)), 1);
        end
        currentPage = index;
        lastError = [];
        lastSeconds = NaN;
        delete(drawPanel.Children);
        hideExtras();
        if index == summaryIndex
            showSummary();
        else
            showQuestion(index);
        end
        flagPrevious = index > 1;
        flagNext = index < summaryIndex;
        previousButton.Enable = matlab.lang.OnOffSwitchState(flagPrevious);
        previousButton.Icon = fcn_CarMesh3D_icons('questionPrevious', FlagEnabled=flagPrevious, Height=16, FigNum=-1);
        nextButton.Enable = matlab.lang.OnOffSwitchState(flagNext);
        nextButton.Icon = fcn_CarMesh3D_icons('questionNext', FlagEnabled=flagNext, Height=16, FigNum=-1);
        if index == summaryIndex
            summaryButton.Text = 'Questions';
            summaryButton.Icon = fcn_CarMesh3D_icons('questions', Height=20, FigNum=-1);
            summaryButton.Tooltip = 'Back to the questions: the first one not answered, or the first one';
        else
            summaryButton.Text = 'Summary';
            summaryButton.Icon = fcn_CarMesh3D_icons('summary', Height=20, FigNum=-1);
            summaryButton.Tooltip = 'The Summary: every answer, and Approve or Reject (come back with Questions)';
        end
        refreshProgress();
    end

    function showQuestion(index)
        page = pages(index);
        headingLabel.Text = ['  ' fcn_INTERNAL_heading(page)];
        headingLabel.Tooltip = page.GroupHelp;
        questionLabel.Text = page.Question;
        questionLabel.Tooltip = page.Help;
        detailLabel.Text = page.Detail;
        detailLabel.Tooltip = page.Detail;
        if ~page.On
            setAnswers({}, '', false);
            fcn_INTERNAL_message(drawPanel, sprintf('%s is turned off in Shared GUI settings (Review): recorded as turned off.', page.Title));
            statusLabel.Text = '';
            return;
        end
        % (the assessment draws its picture: caught and timed)
        startTime = tic;
        try
            result = page.Function(vehicle, Mode='draw', Key=page.QKey, Parent=drawPanel, FigNum=-1);
            lastSeconds = toc(startTime);
        catch drawError
            lastSeconds = toc(startTime);
            showError(index, drawError);
            return;
        end
        currentFingerprints(index) = string(result.Fingerprint);
        row = rowOf(index);
        answers.Seconds(row) = lastSeconds;
        answers.Note(row) = string(fcn_INTERNAL_text(result, 'Note'));
        skipText = fcn_INTERNAL_text(result, 'Skip');
        if ~isempty(skipText)
            % (the function has nothing to ask for this vehicle, such as no
            % approved exemplar to compare with)
            delete(drawPanel.Children);
            fcn_INTERNAL_message(drawPanel, sprintf('Skipped: %s', skipText));
            answers.Status(row) = "skipped";
            answers.Note(row) = string(skipText);
            saveAnswers();
            setAnswers({}, '', false);
            refreshStatus(index);
            return;
        end
        if any(answers.Status(row) == ["error", "not asked"])
            answers.Status(row) = "";   % (it draws now, and is asked)
        end
        saveAnswers();
        selected = '';
        if isAnswered(index)
            selected = char(answers.Answer(row));
        end
        setAnswers(page.Answers, selected, true);
        commentArea.Value = char(answers.Comment(row));
        showExtras(index);
        refreshStatus(index);
    end

    %% The score and the examples (an assessment that asks for them)
    function hideExtras()
        questionGrid.RowHeight{4} = 0;
        pageGrid.RowHeight{3} = 140;
        extrasGrid.Visible = 'off';
    end

    function showExtras(index)
        page = pages(index);
        if isempty(page.Score) && ~page.Examples
            return;
        end
        questionGrid.RowHeight{4} = 30;
        % (the question band grows by the extras row, so the answers keep
        % their room: T83 BUG, Accept and Reject were cut off at the bottom)
        pageGrid.RowHeight{3} = 140 + 30 + 10;
        extrasGrid.Visible = 'on';
        flagScore = ~isempty(page.Score);
        scoreLabel.Visible = matlab.lang.OnOffSwitchState(flagScore);
        scoreDropdown.Visible = matlab.lang.OnOffSwitchState(flagScore);
        if flagScore
            scoreLabel.Text = sprintf('Score (%g bad to %g perfect):', page.Score(1), page.Score(2));
            scoreDropdown.Items = [{'(none)'}, arrayfun(@(value) sprintf('%g', value), page.Score(1):page.Score(2), 'UniformOutput', false)];
            value = answers.Score(rowOf(index));
            if isnan(value)
                scoreDropdown.Value = '(none)';
            else
                scoreDropdown.Value = sprintf('%g', value);
            end
        end
        examplesDropdown.Visible = matlab.lang.OnOffSwitchState(page.Examples);
        saveExampleButton.Visible = matlab.lang.OnOffSwitchState(page.Examples);
        if page.Examples
            refreshExamples();
        end
    end

    function onScoreChanged()
        if currentPage == summaryIndex
            return;
        end
        row = rowOf(currentPage);
        answers.Score(row) = str2double(scoreDropdown.Value);   % (NaN for '(none)')
        saveAnswers();
        refreshStatus(currentPage);
    end

    function testScore(value)
        if isnan(value)
            scoreDropdown.Value = '(none)';
        else
            scoreDropdown.Value = sprintf('%g', value);
        end
        onScoreChanged();
    end

    function folder = examplesFolder()
        folder = fullfile(examplesRoot, char(pages(currentPage).FKey));
    end

    function files = listExamples()
        % (the saved examples of this assessment, best score first)
        files = {};
        if currentPage == summaryIndex || ~isfolder(examplesFolder())
            return;
        end
        listing = dir(fullfile(examplesFolder(), '*.png'));
        files = fullfile({listing.folder}, {listing.name});
        scores = cellfun(@(name) fcn_INTERNAL_exampleScore(name), {listing.name});
        [~, order] = sort(scores, 'descend');
        files = files(order);
    end

    function refreshExamples()
        files = listExamples();
        [~, names] = cellfun(@fileparts, files, 'UniformOutput', false);
        examplesDropdown.Items = [{sprintf('Compare with examples (%d) ...', numel(files))}, names];
        examplesDropdown.ItemsData = [{''}, files];
        examplesDropdown.Value = '';
    end

    function showExample(file)
        % (a saved example, in a window of its own beside this one)
        if isempty(file)
            return;
        end
        if ~isempty(exampleWindow) && isvalid(exampleWindow)
            delete(exampleWindow);
        end
        [~, name] = fileparts(file);
        exampleWindow = uifigure('Name', sprintf('Example: %s', name), 'Tag', 'vvExampleWindow', ...
            'Visible', matlab.lang.OnOffSwitchState(options.FlagVisible), 'Position', [80 80 960 560]);
        grid = uigridlayout(exampleWindow, [2 1], 'RowHeight', {'1x', 'fit'});
        uiimage(grid, 'ImageSource', file, 'ScaleMethod', 'fit', 'Tag', 'vvExampleImage');
        textFile = fullfile(fileparts(file), [name '.txt']);
        textLine = name;
        if isfile(textFile)
            textLine = strtrim(fileread(textFile));
        end
        uilabel(grid, 'Text', textLine, 'WordWrap', 'on', 'Tag', 'vvExampleText');
        examplesDropdown.Value = '';
    end

    function file = saveExample()
        % (these pictures, as turned, with the answer and the score: a PNG
        % and a one-line text file, named so renaming re-ranks it; Q90 (A))
        file = '';
        if currentPage == summaryIndex
            return;
        end
        page = pages(currentPage);
        row = rowOf(currentPage);
        score = answers.Score(row);
        if strlength(answers.Answer(row)) == 0 || (~isempty(page.Score) && isnan(score))
            statusLabel.Text = 'To save an example, answer first (and give a score).';
            return;
        end
        folder = examplesFolder();
        if ~isfolder(folder)
            mkdir(folder);
        end
        scoreText = '';
        if ~isnan(score)
            scoreText = sprintf('_s%02d', round(score));
        end
        base = sprintf('%s%s_%s_%s_%s_%s', char(page.FKey), scoreText, lower(char(answers.Answer(row))), vehicle.ID, ...
            reviewerName, char(datetime('now', 'Format', 'yyyy_MM_dd')));
        base = regexprep(base, '[^\w]', '_');
        file = fullfile(folder, [base '.png']);
        count = 1;
        while isfile(file)
            count = count + 1;
            file = fullfile(folder, sprintf('%s_%d.png', base, count));
        end
        try
            exportgraphics(drawPanel, file, 'Resolution', 96);
        catch
            exportapp(figureHandle, file);   % (the whole window, if the panel cannot be exported alone)
        end
        % (the line beside it: vehicle, score, verdict, who, when, the views)
        views = {};
        for thisAxes = reshape(findall(drawPanel, 'Type', 'axes'), 1, [])
            [azimuth, elevation] = view(thisAxes);
            views{end+1} = sprintf('az %.0f el %.0f', azimuth, elevation); %#ok<AGROW>
        end
        textLine = sprintf('vehicle=%s; score=%s; verdict=%s; who=%s; when=%s; views=%s; comment=%s', vehicle.ID, ...
            num2str(score), char(answers.Answer(row)), reviewerName, char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')), ...
            strjoin(views, ' | '), strrep(char(answers.Comment(row)), newline, ' '));
        [~, name] = fileparts(file);
        fileID = fopen(fullfile(folder, [name '.txt']), 'w', 'n', 'UTF-8');
        fprintf(fileID, '%s\n', textLine);
        fclose(fileID);
        statusLabel.Text = sprintf('Saved as an example: %s', name);
        refreshExamples();
    end

    function showError(index, drawError)
        % (a function that failed: its error, with Retry, Skip and Show
        % error; recorded as an error, and the review goes on)
        lastError = drawError;
        row = rowOf(index);
        answers.Status(row) = "error";
        answers.Note(row) = string(drawError.message);
        answers.Seconds(row) = lastSeconds;
        saveAnswers();
        delete(drawPanel.Children);
        grid = uigridlayout(drawPanel, [3 3], 'RowHeight', {'1x', 34, '1x'}, 'ColumnWidth', {'1x', 'fit', '1x'}, ...
            'BackgroundColor', [1 1 1]);
        message = uilabel(grid, 'Text', sprintf('%s could not draw this question:\n%s', func2str(pages(index).Function), ...
            drawError.message), 'WordWrap', 'on', 'FontColor', [0.7 0 0], 'FontSize', 14, 'HorizontalAlignment', 'center', ...
            'Tag', 'vvErrorText');
        message.Layout.Row = 1;
        message.Layout.Column = [1 3];
        buttons = uigridlayout(grid, [1 3], 'ColumnWidth', {110, 110, 110}, 'Padding', [0 0 0 0], 'BackgroundColor', [1 1 1]);
        buttons.Layout.Row = 2;
        buttons.Layout.Column = 2;
        uibutton(buttons, 'Text', 'Retry', 'Tag', 'vvRetry', 'ButtonPushedFcn', @(~,~) showPage(index));
        uibutton(buttons, 'Text', 'Skip', 'Tag', 'vvSkip', 'ButtonPushedFcn', @(~,~) skipError());
        uibutton(buttons, 'Text', 'Show error', 'Tag', 'vvShowError', ...
            'ButtonPushedFcn', @(~,~) showErrorReport(grid, drawError));
        setAnswers({}, '', false);
        statusLabel.Text = sprintf('Error (recorded) after %.2f s. Retry, Skip to go on, or Show error for the details.', lastSeconds);
        refreshProgress();
    end

    function showErrorReport(grid, drawError)
        report = getReport(drawError, 'extended', 'hyperlinks', 'off');
        area = uitextarea(grid, 'Value', splitlines(report), 'Editable', 'off', 'FontName', 'Consolas', 'Tag', 'vvErrorReport');
        area.Layout.Row = 3;
        area.Layout.Column = [1 3];
    end

    function skipError()
        goToNext('next');
    end

    function showSummary()
        headingLabel.Text = '  Summary';
        headingLabel.Tooltip = 'Every answer, and the decision for this mesh';
        questionLabel.Text = 'Approve this mesh?';
        detailLabel.Text = 'Approve only if every answer is Yes (or not a problem) and none is stale; if unsure, Reject and say why.';
        detailLabel.Tooltip = detailLabel.Text;
        questionLabel.Tooltip = ['Your decision records what it rested on: each answer, and the data it was given. ' ...
            'Stale or missing answers are listed in it.'];
        grid = uigridlayout(drawPanel, [2 1], 'RowHeight', {30, '1x'}, 'BackgroundColor', [1 1 1]);
        uilabel(grid, 'Text', fcn_INTERNAL_countsText(currentAnswers()), 'FontSize', 14, 'Tag', 'vvCounts');
        shown = currentAnswers();
        uitable(grid, 'Data', shown(:, {'Title', 'Question', 'Answer', 'Status', 'Note', 'Comment', 'Who', 'When'}), ...
            'Tag', 'vvSummaryTable', 'ColumnWidth', {100, 360, 70, 80, '1x', '1x', 45, 130});
        selected = '';
        if ~isempty(summary) && ~isempty(summary.Decision)
            selected = summary.Decision;
            commentArea.Value = summary.Comment;
        else
            commentArea.Value = '';
        end
        setAnswers({'Approve', 'Reject'}, selected, true);
        if isempty(selected)
            statusLabel.Text = 'No decision yet.';
        else
            statusLabel.Text = sprintf('%s by %s, %s.', selected, summary.Who, summary.When);
        end
    end

    %% Answering
    function setAnswers(texts, selected, flagEnabled)
        % (the answer buttons for this page; a hidden one stands for "no
        % answer yet", since a button group always has one selected)
        flagShowing = true;
        delete(answerGroup.Children);
        blank = uiradiobutton(answerGroup, 'Text', '', 'Visible', 'off', 'Position', [1 1 1 1], 'UserData', '');
        x = 8;
        for ith_answer = 1:numel(texts)
            button = uiradiobutton(answerGroup, 'Text', texts{ith_answer}, 'Position', [x 8 120 26], ...
                'FontSize', 15, 'UserData', texts{ith_answer}, 'Tag', ['vvAnswer_' texts{ith_answer}]);
            if strcmp(texts{ith_answer}, selected)
                answerGroup.SelectedObject = button;
            end
            x = x + 130;
        end
        if isempty(selected)
            answerGroup.SelectedObject = blank;
        end
        answerGroup.Enable = matlab.lang.OnOffSwitchState(flagEnabled);
        commentArea.Enable = matlab.lang.OnOffSwitchState(flagEnabled);
        if ~flagEnabled
            commentArea.Value = '';
        end
        drawnow limitrate;
        flagShowing = false;
    end

    function onAnswerPicked(event)
        if flagShowing || isempty(event.NewValue.UserData)
            return;
        end
        recordAnswer(event.NewValue.UserData);
    end

    function recordAnswer(answerText)
        commentText = strjoin(cellstr(commentArea.Value), newline);
        if currentPage == summaryIndex
            decide(answerText, commentText);
            return;
        end
        index = currentPage;
        row = rowOf(index);
        answers.Answer(row) = string(answerText);
        answers.Problem(row) = any(strcmp(pages(index).ProblemAnswers, answerText));
        answers.Comment(row) = string(commentText);
        answers.Who(row) = string(reviewerName);
        answers.When(row) = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        answers.Fingerprint(row) = currentFingerprints(index);
        answers.Status(row) = "answered";
        saveAnswers();
        % (where to go now: Shared GUI settings, Review)
        if answers.Problem(row) && fcn_INTERNAL_pref('ReviewStopAtNo', true)
            % (the questions after it, not answered yet, are recorded as not
            % asked: the design file, section 6)
            for ith_page = index + 1:numel(pages)
                laterRow = rowOf(ith_page);
                if pages(ith_page).On && ~isAnswered(ith_page) && any(answers.Status(laterRow) == ["", "not asked"])
                    answers.Status(laterRow) = "not asked";
                    answers.Note(laterRow) = string(sprintf('stopped at the first No (%s)', pages(index).Title));
                end
            end
            saveAnswers();
            showPage(summaryIndex);
            statusLabel.Text = sprintf('Stopped at the first No (%s), as set in Shared GUI settings. %s', ...
                pages(index).Title, statusLabel.Text);
            return;
        end
        goToNext(fcn_INTERNAL_pref('ReviewGoTo', 'nextUnansweredOrNo'));
    end

    function goToNext(mode)
        index = currentPage;
        switch mode
            case 'stay'
                refreshStatus(index);
                refreshProgress();
                return;
            case 'next'
                % (the next page that is on; else the Summary)
                target = summaryIndex;
                for ith_page = index + 1:numel(pages)
                    if pages(ith_page).On
                        target = ith_page;
                        break;
                    end
                end
            otherwise
                % (the next page after this one with no current answer,
                % or, for 'nextUnansweredOrNo', with a problem answer,
                % wrapping around once; else the Summary)
                target = summaryIndex;
                order = [index + 1:numel(pages), 1:index - 1];
                for ith_page = order
                    if ~pages(ith_page).On || answers.Status(rowOf(ith_page)) == "skipped"
                        continue;   % (nothing to answer there)
                    end
                    row = rowOf(ith_page);
                    if ~isAnswered(ith_page) || (strcmp(mode, 'nextUnansweredOrNo') && answers.Problem(row))
                        target = ith_page;
                        break;
                    end
                end
        end
        showPage(target);
    end

    function onCommentChanged()
        commentText = strjoin(cellstr(commentArea.Value), newline);
        if currentPage == summaryIndex
            if ~isempty(summary) && ~isempty(summary.Decision)
                summary.Comment = commentText;
                saveAnswers();
            end
            return;
        end
        answers.Comment(rowOf(currentPage)) = string(commentText);
        saveAnswers();
    end

    function decide(decision, commentText)
        % (the decision, and what it rested on: each answer now, with its
        % fingerprint and whether it is stale; no override flag)
        restedOn = currentAnswers();
        summary = struct('Decision', char(decision), 'Comment', char(commentText), 'Who', reviewerName, ...
            'When', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
            'Counts', fcn_INTERNAL_countsText(restedOn), 'RestedOn', restedOn);
        saveAnswers();
        writeReport();
        try
            action = 'reviewed: approved';
            if strcmpi(decision, 'Reject')
                action = 'reviewed: rejected';
            end
            fcn_CarMesh3D_meshHistory(vehicle.Files.Folder, Action=action, Who=reviewerName, ...
                Details=sprintf('%s. %s', summary.Counts, summary.Comment), FigNum=-1);
        catch
            % (a vehicle with no change log yet: the review file holds the decision)
        end
        statusLabel.Text = sprintf('%s by %s, %s. Saved, with the report.', summary.Decision, summary.Who, summary.When);
        refreshProgress();
    end

    %% The record
    function row = rowOf(index)
        row = find(answers.Assessment == pages(index).FKey & answers.Key == pages(index).QKey, 1);
    end

    function flag = isAnswered(index)
        % (answered, and on the data shown now: a changed fingerprint
        % makes the answer stale, so it counts as unanswered)
        row = rowOf(index);
        flag = answers.Status(row) == "answered" && ...
            (currentFingerprints(index) == "" || answers.Fingerprint(row) == currentFingerprints(index));
    end

    function shown = currentAnswers()
        % (the answers, with Status "stale" where the mesh has changed, and
        % "turned off" kept)
        shown = answers;
        for ith_page = 1:numel(pages)
            row = rowOf(ith_page);
            if shown.Status(row) == "answered" && ~isAnswered(ith_page)
                shown.Status(row) = "stale";
            end
        end
    end

    function saveAnswers()
        vvAnswers = answers; %#ok<NASGU>
        vvSummary = summary; %#ok<NASGU>
        reviewTable = fcn_INTERNAL_oldFormat(currentAnswers(), summary); %#ok<NASGU>
        names = {'vvAnswers', 'vvSummary', 'reviewTable'};
        if ~isempty(keptOld)
            reviewTableOld = keptOld; %#ok<NASGU>
            names{end+1} = 'reviewTableOld';
        end
        save(reviewFile, names{:});
    end

    function writeReport()
        fcn_INTERNAL_writeReport(reportFile, vehicle, currentAnswers(), summary);
    end

    %% Showing the state
    function refreshStatus(index)
        row = rowOf(index);
        parts = {};
        if strlength(answers.Note(row)) > 0
            parts{end+1} = char(answers.Note(row));
        end
        % (not the drawing time: it is kept in the record, Seconds; Q61 (A))
        if answers.Status(row) == "answered"
            if isAnswered(index)
                parts{end+1} = sprintf('%s by %s, %s', answers.Answer(row), answers.Who(row), answers.When(row));
            else
                parts{end+1} = sprintf('the mesh changed since %s answered %s (%s): answer again', ...
                    answers.Who(row), answers.Answer(row), answers.When(row));
            end
        end
        statusLabel.Text = strjoin(parts, '   ·   ');
    end

    function refreshProgress()
        shown = currentAnswers();
        progressLabel.Text = sprintf('%s   ·   %s', fcn_INTERNAL_pageName(currentPage, summaryIndex), fcn_INTERNAL_countsText(shown));
        % (the Questions list, with a mark for each answer)
        items = cell(1, summaryIndex);
        for ith_page = 1:numel(pages)
            row = rowOf(ith_page);
            items{ith_page} = sprintf('%s  %s', fcn_INTERNAL_mark(shown(row, :)), pages(ith_page).Title);
        end
        items{summaryIndex} = 'Summary';
        if ~isempty(summary) && ~isempty(summary.Decision)
            items{summaryIndex} = sprintf('Summary: %s', summary.Decision);
        end
        questionsList.Items = items;
        questionsList.ItemsData = 1:summaryIndex;
        questionsList.Value = currentPage;
    end

    function setMenuWidth(width)
        bodyGrid.ColumnWidth{1} = width;
    end

    function onSharedSetting(name, value)
        % (your initials apply at once; the Review settings are read at
        % each answer)
        if strcmp(name, 'Initials')
            reviewerName = char(value);
        end
    end

    function onClose()
        try
            if ~isempty(answers)
                saveAnswers();
                writeReport();
            end
        catch
        end
        delete(figureHandle);
    end

    %% For scripts and tests
    function testShow(index)
        showPage(index);
    end

    function testAnswer(answerText, commentText)
        if nargin >= 2
            commentArea.Value = commentText;
        end
        recordAnswer(char(answerText));
    end

    function testDecide(decision, commentText)
        if currentPage ~= summaryIndex
            showPage(summaryIndex);
        end
        if nargin < 2
            commentText = '';
        end
        commentArea.Value = commentText;
        recordAnswer(char(decision));
    end

    % (nested functions, so they see the values now: an anonymous function
    % would keep the values it was made with)
    function value = getAnswers()
        value = answers;
    end

    function value = getSummary()
        value = summary;
    end

    function value = getLastError()
        value = lastError;
    end

    function value = getReviewFile()
        value = reviewFile;
    end

    function value = getReportFile()
        value = reportFile;
    end

    function testRetry()
        showPage(currentPage);
    end

    function textOut = printCommands()
        % (the commands to open the vehicle under review in the viewer and
        % the painter, printed in the Command Window to copy or run)
        folder = vehicle.Files.Folder;
        textOut = sprintf(['%% %s: look in the viewer, fix in the painter\n' ...
            'vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(''%s'');\n' ...
            'fcn_CarMesh3D_viewLabels(vehicleMesh);\n' ...
            'fcn_CarMesh3D_paintLabels(''%s'');\n'], vehicle.Name, folder, folder);
        fprintf(1, '\n%s\n', textOut);
        statusLabel.Text = 'The commands are printed in the Command Window.';
    end

    function current = getCurrent()
        key = 'summary';
        if currentPage < summaryIndex
            key = pages(currentPage).QKey;
        end
        current = struct('Page', currentPage, 'Key', key, 'Vehicle', vehicle.ID, 'VehicleIndex', vehicleIndex, ...
            'Seconds', lastSeconds, 'Status', statusLabel.Text);
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
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_pages
function pages = fcn_INTERNAL_pages(checkList)
% One page per question: each assessment function's questions, from its
% describe mode, in the list's order
pages = struct('Function', {}, 'FKey', {}, 'QKey', {}, 'Title', {}, 'Question', {}, 'Answers', {}, ...
    'ProblemAnswers', {}, 'Help', {}, 'Detail', {}, 'GroupTitle', {}, 'GroupHelp', {}, 'On', {}, 'Built', {}, ...
    'Score', {}, 'Examples', {});
for ith_row = 1:height(checkList)
    described = checkList.Questions{ith_row};
    functionHandle = checkList.Function{ith_row};
    if isempty(described)
        % (its describe mode failed: one page, which shows the error)
        described = struct('Key', char(checkList.Key(ith_row)), 'Title', char(checkList.Title(ith_row)), ...
            'Question', char(checkList.Description(ith_row)), 'Answers', {{}}, 'ProblemAnswers', {{}}, 'Help', '', ...
            'GroupTitle', char(checkList.Title(ith_row)), 'GroupHelp', char(checkList.Description(ith_row)));
    end
    for ith_question = 1:numel(described)
        question = described(ith_question);
        detail = '';   % (Detail is optional: an assessment without one shows no second line)
        if isfield(question, 'Detail') && ~isempty(question.Detail)
            detail = char(question.Detail);
        end
        scoreRange = [];   % (Score and Examples are optional too)
        if isfield(question, 'Score') && numel(question.Score) == 2
            scoreRange = double(question.Score(:)');
        end
        flagExamples = isfield(question, 'Examples') && isequal(question.Examples, true);
        pages(end+1) = struct('Function', functionHandle, 'FKey', string(checkList.Key(ith_row)), ...
            'QKey', char(question.Key), 'Title', char(question.Title), 'Question', char(question.Question), ...
            'Answers', {cellstr(question.Answers)}, 'ProblemAnswers', {cellstr(question.ProblemAnswers)}, ...
            'Help', char(question.Help), 'Detail', detail, 'GroupTitle', char(question.GroupTitle), 'GroupHelp', char(question.GroupHelp), ...
            'On', checkList.On(ith_row), 'Built', checkList.Built(ith_row), 'Score', scoreRange, ...
            'Examples', flagExamples); %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_pages

%% fcn_INTERNAL_startAnswers
function [answers, summary, keptOld] = fcn_INTERNAL_startAnswers(pages, checkList, reviewFile) %#ok<INUSD>
% One row per question, with the answers saved earlier for the same
% assessment and question; answers from the older reviewer are kept apart
numPages = numel(pages);
blank = strings(numPages, 1);
answers = table([pages.FKey]', string({pages.QKey})', string({pages.Title})', string({pages.Question})', ...
    blank, false(numPages, 1), blank, blank, blank, blank, blank, blank, NaN(numPages, 1), NaN(numPages, 1), ...
    'VariableNames', {'Assessment', 'Key', 'Title', 'Question', 'Answer', 'Problem', 'Comment', 'Who', 'When', ...
    'Fingerprint', 'Status', 'Note', 'Seconds', 'Score'});
summary = [];
keptOld = [];
if isfile(reviewFile)
    saved = load(reviewFile);
    if isfield(saved, 'vvAnswers')
        for ith_row = 1:height(saved.vvAnswers)
            row = find(answers.Assessment == saved.vvAnswers.Assessment(ith_row) & answers.Key == saved.vvAnswers.Key(ith_row), 1);
            if ~isempty(row)
                kept = {'Answer', 'Problem', 'Comment', 'Who', 'When', 'Fingerprint', 'Status', 'Note', 'Seconds'};
                if ismember('Score', saved.vvAnswers.Properties.VariableNames)
                    kept{end+1} = 'Score'; %#ok<AGROW>   (files saved before 2026-11-26 have none)
                end
                answers(row, kept) = saved.vvAnswers(ith_row, kept);
            end
        end
        if isfield(saved, 'vvSummary')
            summary = saved.vvSummary;
        end
        if isfield(saved, 'reviewTableOld')
            keptOld = saved.reviewTableOld;
        end
    elseif isfield(saved, 'reviewTable')
        keptOld = saved.reviewTable;   % (the older reviewer's answers)
    end
end
% (turned off now: recorded as such; on again: asked again)
for ith_page = 1:numPages
    if ~pages(ith_page).On
        answers.Status(ith_page) = "turned off";
        answers.Note(ith_page) = "turned off in Shared GUI settings (Review)";
    elseif answers.Status(ith_page) == "turned off"
        % (an answer from before it was turned off comes back; its
        % fingerprint still says whether it is current)
        answers.Status(ith_page) = "";
        if strlength(answers.Answer(ith_page)) > 0 && strlength(answers.Fingerprint(ith_page)) > 0
            answers.Status(ith_page) = "answered";
        end
        answers.Note(ith_page) = "";
    end
end
end % Ends fcn_INTERNAL_startAnswers

%% fcn_INTERNAL_oldFormat
function reviewTable = fcn_INTERNAL_oldFormat(answers, summary)
% The answers in the older reviewer's format, which the library browser
% reads: Status approved (an answer that is not a problem), rejected (a
% problem answer), skipped, error or '' (not answered, or stale)
numRows = height(answers);
status = strings(numRows, 1);
status(answers.Status == "answered" & ~answers.Problem) = "approved";
status(answers.Status == "answered" & answers.Problem) = "rejected";
status(answers.Status == "skipped" | answers.Status == "turned off") = "skipped";
status(answers.Status == "error") = "error";
% (times as the library browser reads them: to the minute)
times = answers.When;
times(strlength(times) > 16) = extractBefore(times(strlength(times) > 16), 17);
reviewTable = table(answers.Assessment, answers.Key, answers.Question, status, strings(numRows, 1), ...
    strings(numRows, 1), answers.Comment, answers.Who, times, ...
    'VariableNames', {'Check', 'Item', 'Question', 'Status', 'Severity', 'Cause', 'Comment', 'Reviewer', 'Time'});
summaryStatus = "";
summaryRow = {"", "", ""};
if ~isempty(summary) && ~isempty(summary.Decision)
    summaryStatus = "approved";
    if strcmpi(summary.Decision, 'Reject')
        summaryStatus = "rejected";
    end
    summaryRow = {string(summary.Comment), string(summary.Who), string(extractBefore(string(summary.When), 17))};
end
reviewTable = [reviewTable; table("summary", "summary", "Approve this mesh?", summaryStatus, "", "", ...
    summaryRow{:}, 'VariableNames', reviewTable.Properties.VariableNames)];
end % Ends fcn_INTERNAL_oldFormat

%% fcn_INTERNAL_openWindow
function existing = fcn_INTERNAL_openWindow(vehicleInput)
% A shown V&V window already open on this vehicle (its folder), or []
existing = [];
windows = findall(groot, 'Type', 'figure', 'Tag', 'vvWindow', 'Visible', 'on');
if isempty(windows)
    return;
end
try
    if isstruct(vehicleInput)
        folder = vehicleInput.Files.Folder;
    else
        files = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
        folder = files.Folder;
    end
catch
    return;
end
for ith_window = 1:numel(windows)
    if strcmpi(getappdata(windows(ith_window), 'vvVehicleFolder'), folder) && isstruct(windows(ith_window).UserData)
        existing = windows(ith_window);
        return;
    end
end
end % Ends fcn_INTERNAL_openWindow

%% fcn_INTERNAL_answerText
function text = fcn_INTERNAL_answerText(answers, row)
% The answer, with its score when one was given ("Accept (9)")
text = char(answers.Answer(row));
if ismember('Score', answers.Properties.VariableNames) && ~isnan(answers.Score(row)) && ~isempty(text)
    text = sprintf('%s (%g)', text, answers.Score(row));
end
end % Ends fcn_INTERNAL_answerText

%% fcn_INTERNAL_exampleScore
function score = fcn_INTERNAL_exampleScore(fileName)
% An example's score, from its name (..._s09_...), or -1 when it has none
score = -1;
token = regexp(fileName, '_s(\d+)_', 'tokens', 'once');
if ~isempty(token)
    score = str2double(token{1});
end
end % Ends fcn_INTERNAL_exampleScore

%% fcn_INTERNAL_writeReport
function fcn_INTERNAL_writeReport(reportFile, vehicle, answers, summary)
% A readable report of the review, in Markdown
lines = {sprintf('# Review of %s', vehicle.Name), '', sprintf('Vehicle ID: %s', vehicle.ID), ''};
if ~isempty(summary) && ~isempty(summary.Decision)
    lines = [lines, {sprintf('**Decision: %s** by %s, %s', summary.Decision, summary.Who, summary.When), ''}];
    if ~isempty(summary.Comment)
        lines = [lines, {sprintf('Comment: %s', summary.Comment), ''}];
    end
    lines = [lines, {sprintf('It rested on: %s', summary.Counts), ''}];
else
    lines = [lines, {'**No decision yet.**', ''}];
end
lines = [lines, {fcn_INTERNAL_countsText(answers), '', '| Assessment | Question | Answer | Status | Comment | Who | When |', ...
    '|---|---|---|---|---|---|---|'}];
for ith_row = 1:height(answers)
    cells = cellfun(@(value) strrep(strrep(char(value), '|', '/'), newline, ' '), ...
        {answers.Title(ith_row), answers.Question(ith_row), fcn_INTERNAL_answerText(answers, ith_row), answers.Status(ith_row), ...
        answers.Comment(ith_row), answers.Who(ith_row), answers.When(ith_row)}, 'UniformOutput', false);
    lines{end+1} = ['| ' strjoin(cells, ' | ') ' |']; %#ok<AGROW>
end
lines = [lines, {'', sprintf('Written by fcn_CarMesh3D_reviewVehicle, %s', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')))}];
fileID = fopen(reportFile, 'w', 'n', 'UTF-8');
if fileID < 0
    warning('CarMesh3D:reportNotWritten', 'Could not write the report %s.', reportFile);
    return;
end
fprintf(fileID, '%s\n', lines{:});
fclose(fileID);
end % Ends fcn_INTERNAL_writeReport

%% fcn_INTERNAL_countsText
function textOut = fcn_INTERNAL_countsText(answers)
% How many answered (and how many of those are problems), unanswered,
% stale, skipped, errors
status = answers.Status;
numAnswered = sum(status == "answered");
numProblems = sum(status == "answered" & answers.Problem);
numOpen = sum(status == "" | status == "stale" | status == "not asked");
numStale = sum(status == "stale");
numSkipped = sum(status == "skipped" | status == "turned off");
numErrors = sum(status == "error");
numNotAsked = sum(status == "not asked");
textOut = sprintf('%d answered (%d a problem), %d not answered', numAnswered, numProblems, numOpen);
if numStale > 0 || numNotAsked > 0
    parts = {};
    if numStale > 0
        parts{end+1} = sprintf('%d stale', numStale);
    end
    if numNotAsked > 0
        parts{end+1} = sprintf('%d not asked after the first No', numNotAsked);
    end
    textOut = sprintf('%s (%s)', textOut, strjoin(parts, ', '));
end
textOut = sprintf('%s, %d skipped, %d error(s)', textOut, numSkipped, numErrors);
end % Ends fcn_INTERNAL_countsText

%% fcn_INTERNAL_mark
function mark = fcn_INTERNAL_mark(row)
% The mark for a question in the Questions list
switch row.Status
    case "answered"
        mark = char(10003);
        if row.Problem
            mark = char(10007);
        end
    case {"skipped", "turned off"}
        mark = '-';
    case "error"
        mark = '!';
    otherwise
        mark = '?';
end
end % Ends fcn_INTERNAL_mark

%% fcn_INTERNAL_heading
function textOut = fcn_INTERNAL_heading(page)
textOut = page.GroupTitle;
if ~strcmp(page.Title, page.GroupTitle)
    textOut = sprintf('%s: %s', page.GroupTitle, page.Title);
end
end % Ends fcn_INTERNAL_heading

%% fcn_INTERNAL_pageName
function textOut = fcn_INTERNAL_pageName(index, summaryIndex)
if index == summaryIndex
    textOut = 'Summary';
else
    textOut = sprintf('Question %d of %d', index, summaryIndex - 1);
end
end % Ends fcn_INTERNAL_pageName

%% fcn_INTERNAL_message
function fcn_INTERNAL_message(panel, textIn)
% A message in the middle of the picture's panel
grid = uigridlayout(panel, [3 1], 'RowHeight', {'1x', 'fit', '1x'}, 'BackgroundColor', [1 1 1]);
label = uilabel(grid, 'Text', textIn, 'FontSize', 16, 'FontColor', [0.35 0.35 0.35], 'WordWrap', 'on', ...
    'HorizontalAlignment', 'center', 'Tag', 'vvMessage');
label.Layout.Row = 2;
end % Ends fcn_INTERNAL_message

%% fcn_INTERNAL_text
function value = fcn_INTERNAL_text(structure, name)
% A text field of a function's result, or '' when it has none
value = '';
if isfield(structure, name) && ~isempty(structure.(name))
    value = char(structure.(name));
end
end % Ends fcn_INTERNAL_text

%% fcn_INTERNAL_pref
function value = fcn_INTERNAL_pref(name, default)
% A Review setting (Shared GUI settings), or its default
value = default;
if ispref('CarMesh3D', name)
    value = getpref('CarMesh3D', name);
end
end % Ends fcn_INTERNAL_pref
