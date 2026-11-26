% script_test_fcn_CarMesh3D_userInfo.m
% Tests fcn_CarMesh3D_userInfo. The preferences it touches (Initials,
% UserName) are saved first and put back as they were at the end.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_userInfo
%   % * First write

% TO-DO:
%
% (none)

%% Set up the workspace
close all;
prefNames = {'Initials', 'UserName'};
prefsBefore = struct();
for ith_pref = 1:numel(prefNames)
    if ispref('CarMesh3D', prefNames{ith_pref})
        prefsBefore.(prefNames{ith_pref}) = getpref('CarMesh3D', prefNames{ith_pref});
    end
end
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(prefNames, prefsBefore));
fcn_INTERNAL_clearPrefs(prefNames);

%% DEMO case: nothing saved, not asked: the default
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: nothing saved\n', figNum);
user = fcn_CarMesh3D_userInfo();
assert(strcmp(user.Initials, 'SBB') && strcmp(user.Source, 'default') && isempty(user.Name));
assert(~ispref('CarMesh3D', 'Initials'), 'Not asking saves nothing');

%% TEST case: asked once, then remembered
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: asked, then remembered\n', figNum);
user = fcn_CarMesh3D_userInfo(FlagAsk=true, Answer={' ab ', 'Ann Bee'});
assert(strcmp(user.Initials, 'AB') && strcmp(user.Name, 'Ann Bee') && strcmp(user.Source, 'asked'));
user = fcn_CarMesh3D_userInfo(FlagAsk=true, Answer={'ZZ', 'Not used'});
assert(strcmp(user.Initials, 'AB') && strcmp(user.Source, 'preference'), 'Asked only once');

%% TEST case: an empty answer (dialog closed): the default, nothing saved
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: an empty answer\n', figNum);
fcn_INTERNAL_clearPrefs(prefNames);
user = fcn_CarMesh3D_userInfo(FlagAsk=true, Answer={'', ''});
assert(strcmp(user.Source, 'default') && ~ispref('CarMesh3D', 'Initials'));

%% TEST case: Set
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: Set\n', figNum);
user = fcn_CarMesh3D_userInfo(Set={'cd', ''});
assert(strcmp(user.Initials, 'CD') && strcmp(user.Source, 'set') && strcmp(getpref('CarMesh3D', 'Initials'), 'CD'));

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode\n', figNum);
user = fcn_CarMesh3D_userInfo(FigNum=-1);
assert(strcmp(user.Initials, 'CD'));

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_userInfo(Set={'only one'});
    error('test:noError', 'Set with one entry was taken');
catch caughtError
    assert(contains(caughtError.message, 'Set must be'), caughtError.message);
end

clear cleanupPrefs;   % (the preferences put back as they were)
fprintf(1,'All tests of fcn_CarMesh3D_userInfo passed\n');

%% Functions follow
function fcn_INTERNAL_clearPrefs(prefNames)
for ith_pref = 1:numel(prefNames)
    if ispref('CarMesh3D', prefNames{ith_pref})
        rmpref('CarMesh3D', prefNames{ith_pref});
    end
end
end % Ends fcn_INTERNAL_clearPrefs

function fcn_INTERNAL_restorePrefs(prefNames, prefsBefore)
for ith_pref = 1:numel(prefNames)
    name = prefNames{ith_pref};
    if isfield(prefsBefore, name)
        setpref('CarMesh3D', name, prefsBefore.(name));
    elseif ispref('CarMesh3D', name)
        rmpref('CarMesh3D', name);
    end
end
end % Ends fcn_INTERNAL_restorePrefs
