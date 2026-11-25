% script_test_fcn_CarMesh3D_reviewChecks.m
% Tests fcn_CarMesh3D_reviewChecks: the one list of the Model Reviewer's
% checks, required or optional. The preference it reads is saved first and
% put back at the end, as it was.

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewChecks
%   % * First write: the list's columns and order, the reviewer's own
%   %   % checks all listed, required checks always on, TurnedOff and the
%   %   % preference

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
fprintf(1,'Figure %.0f: DEMO case: the checks, required and optional\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={}, FigNum=figNum);
assert(istable(checkList) && all(ismember({'Key', 'Title', 'Required', 'On', 'Built', 'Description'}, checkList.Properties.VariableNames)));
assert(checkList.Key(1) == "orientation" && checkList.Key(end) == "summary", 'In the reviewer''s order');
assert(all(checkList.On), 'Nothing turned off: every check on');

%% TEST case: every check the reviewer has is listed, and only those listed as built
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: the reviewer''s checks\n', figNum);
reviewerKeys = ["orientation", "dimensions", "labels", "compare", "lights", "body", "steering", "wheels", "drive", ...
    "levels", "outline", "summary"];
assert(isempty(setxor(checkList.Key(checkList.Built), reviewerKeys)), 'The built checks are the reviewer''s');
assert(all(checkList.Required(ismember(checkList.Key, ["orientation", "dimensions", "labels", "summary"]))), 'The required checks');
assert(numel(unique(checkList.Key)) == height(checkList), 'Each key once');

%% TEST case: turned off: optional checks only, by TurnedOff or by the preference
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: turning checks off\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={'levels', 'labels'});
assert(~checkList.On(checkList.Key == "levels"), 'An optional check off');
assert(checkList.On(checkList.Key == "labels"), 'A required check stays on');
setpref('CarMesh3D', 'ReviewChecksOff', {'outline'});
checkList = fcn_CarMesh3D_reviewChecks();
assert(~checkList.On(checkList.Key == "outline") && sum(~checkList.On) == 1, 'The preference');
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={});
assert(all(checkList.On), 'TurnedOff={} wins over the preference');

%% FAST mode cases
figNum = 30001;
fprintf(1,'Figure %.0f: FAST mode: FigNum=-1\n', figNum);
checkList = fcn_CarMesh3D_reviewChecks(TurnedOff={'drive'}, FigNum=-1);
assert(~checkList.On(checkList.Key == "drive"));

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_reviewChecks(TurnedOff=42);
    error('test:noError', 'TurnedOff=42 was taken');
catch caughtError
    assert(contains(caughtError.message, 'TurnedOff must be'), caughtError.message);
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
