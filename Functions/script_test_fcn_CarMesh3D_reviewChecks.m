% script_test_fcn_CarMesh3D_reviewChecks.m
% Tests fcn_CarMesh3D_reviewChecks: the V&V GUI's list of assessment
% functions, with each one's wording from its describe mode.

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewChecks
%   % * First write (drafted with Claude)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewChecks
%   % * The V&V redesign: a list of assessment functions; wording from
%   %   % their describe mode; Assessments= for a list of one's own; a
%   %   % function that cannot describe itself is listed, not built

% TO-DO:
%
% (none)

%% Set up the workspace
close all;
flagHadPref = ispref('CarMesh3D', 'ReviewChecksOff');
prefBefore = {};
if flagHadPref
    prefBefore = getpref('CarMesh3D', 'ReviewChecksOff');
end
cleanupPref = onCleanup(@() fcn_INTERNAL_restorePref(flagHadPref, prefBefore));

%% DEMO case: the list, printed
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: the assessments\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={}, FigNum=figNum);
assert(istable(checkList) && all(ismember({'Key', 'Title', 'Required', 'On', 'Built', 'Description', 'Function', 'Questions'}, ...
    checkList.Properties.VariableNames)));
assert(isequal(cellstr(checkList.Key)', {'overall', 'labels', 'patchyLabels', 'headlights', 'brakeLights', 'realism'}), ...
    'The first round, in order (Sean, 2026-11-25)');
assert(all(checkList.On), 'Nothing turned off: every assessment on');
assert(all(checkList.Built), 'Every assessment describes itself');
assert(~any(checkList.Required), 'Every human assessment is optional (Sean, 00:53)');

%% TEST case: the wording comes from each function (G39: code is the source)
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: wording from describe mode\n', figNum);
for ith_row = 1:height(checkList)
    described = checkList.Function{ith_row}([], Mode='describe');
    assert(strcmp(checkList.Title(ith_row), described(1).GroupTitle), 'The title: %s', checkList.Key(ith_row));
    assert(strcmp(checkList.Description(ith_row), described(1).GroupHelp), 'The tooltip: %s', checkList.Key(ith_row));
    assert(isequal(checkList.Questions{ith_row}, described), 'The questions: %s', checkList.Key(ith_row));
end

%% TEST case: the design file's table matches the code (Q52 (A), rule G39)
% (the code is the source; the V&V design file's section 5 describes it:
% its first-round rows must name the same assessments, in the same order,
% asking the same questions)
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: the design file matches the code\n', figNum);
repoFolder = fileparts(fileparts(which('fcn_CarMesh3D_plotVehicle')));
designFile = fullfile(repoFolder, 'Documents', 'Documentation_CarMesh3D_GUIdesign_VandV.md');
designLines = splitlines(string(fileread(designFile)));
tableRows = designLines(startsWith(designLines, "| ") & contains(designLines, "| first |"));
cells = arrayfun(@(row) strtrim(split(row, "|")), tableRows, 'UniformOutput', false);
designTitles = cellfun(@(c) c(4), cells);
designQuestions = cellfun(@(c) c(5), cells);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={}, FigNum=-1);
assert(isequal(designTitles(:), checkList.Title(:)), ...
    'The design file''s first round (%s) is not the code''s list (%s): update the file, section 5', ...
    strjoin(designTitles, ', '), strjoin(checkList.Title, ', '));
for ith_row = 1:height(checkList)
    question = string(checkList.Questions{ith_row}(1).Question);
    assert(startsWith(designQuestions(ith_row), question), ...
        'The design file asks "%s" for %s, the code "%s": update the file, section 5', ...
        designQuestions(ith_row), checkList.Title(ith_row), question);
end

%% TEST case: turned off, by TurnedOff or by the preference
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: turning assessments off\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={'realism', 'headlights'});
assert(~checkList.On(checkList.Key == "realism") && ~checkList.On(checkList.Key == "headlights") && sum(~checkList.On) == 2);
setpref('CarMesh3D', 'ReviewChecksOff', {'labels'});
checkList = fcn_CarMesh3D_reviewChecks();
assert(~checkList.On(checkList.Key == "labels") && sum(~checkList.On) == 1, 'The preference');
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={});
assert(all(checkList.On), 'TurnedOff={} wins over the preference');

%% TEST case: a list of one's own, and a function that cannot describe itself
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: Assessments=\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(Assessments={@fcn_CarMesh3D_assess_overall, @fcn_INTERNAL_cannotDescribe}, TurnedOff={});
assert(height(checkList) == 2 && checkList.Key(1) == "overall");
assert(checkList.Built(1) && ~checkList.Built(2), 'One that cannot describe itself: listed, not built');
assert(contains(checkList.Description(2), 'could not describe'), 'Its error, as its tooltip');

%% FAST mode cases
figNum = 30001;
fprintf(1,'Figure %.0f: FAST mode: FigNum=-1\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={'realism'}, FigNum=-1);
assert(~checkList.On(checkList.Key == "realism"));

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_reviewChecks(TurnedOff=42);
    error('test:noError', 'TurnedOff=42 was taken');
catch caughtError
    assert(contains(caughtError.message, 'TurnedOff must be'), caughtError.message);
end
try
    fcn_CarMesh3D_reviewChecks(Assessments={'not a function'});
    error('test:noError', 'Assessments of text was taken');
catch caughtError
    assert(contains(caughtError.message, 'Assessments must be'), caughtError.message);
end

clear cleanupPref;   % (the preference put back as it was)
fprintf(1,'All tests of fcn_CarMesh3D_reviewChecks passed\n');

%% Functions follow
function fcn_INTERNAL_restorePref(flagHad, valueBefore)
if flagHad
    setpref('CarMesh3D', 'ReviewChecksOff', valueBefore);
elseif ispref('CarMesh3D', 'ReviewChecksOff')
    rmpref('CarMesh3D', 'ReviewChecksOff');
end
end % Ends fcn_INTERNAL_restorePref

function varargout = fcn_INTERNAL_cannotDescribe(~, varargin)
% A broken assessment function (for the test)
varargout = {};
error('CarMesh3D:test', 'This one cannot describe itself.');
end
