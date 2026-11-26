% script_test_fcn_CarMesh3D_checkNames.m
% Tests fcn_CarMesh3D_checkNames

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_checkNames
%   % * First write (the naming table, section 8, item 3)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_checkNames
%   % * (none yet)

%% Set up the workspace
close all;

%% TEST case: the project's own code follows the conventions
fprintf(1,'TEST case: the CarMesh3D functions follow the naming conventions\n');
problems = fcn_CarMesh3D_checkNames(FigNum=-1);
if ~isempty(problems)
    fprintf(1, '  %s\n', problems{:});
end
assert(isempty(problems), 'Names that break the conventions: %d (listed above)', numel(problems));

%% TEST case: each kind of problem is found in a file made to break them
fprintf(1,'TEST case: each kind of problem is found\n');
testFolder = tempname;   % (a new folder each run, removed at the end)
mkdir(testFolder);
fileID = fopen(fullfile(testFolder, 'fcn_zz_badNames.m'), 'w');
fprintf(fileID, '%s\n', ...
    'function fcn_zz_badNames(options)', ...
    'arguments', ...
    '    options.ShowStuff = true      % a flag not named Flag...', ...
    '    options.FlagGood = false      % fine', ...
    '    options.Symmetric = false     % allowed below', ...
    'end', ...
    'mesh.FacePartIndex = 1;', ...
    'signals = struct(''Headlights'', ''low'');', ...
    '% a comment may say LightStates', ...
    'flag_find_covers = true;', ...
    'flag_do_debug = 0;', ...
    'end');
fclose(fileID);
problems = fcn_CarMesh3D_checkNames(testFolder, AllowedOptions={'Symmetric'}, FigNum=-1);
assert(numel(problems) == 4, 'Four problems: %d', numel(problems));
assert(any(contains(problems, '''ShowStuff'' is not named FlagShowStuff')));
assert(any(contains(problems, 'retired name ''FacePartIndex''')));
assert(any(contains(problems, 'retired name ''Headlights''')));
assert(any(contains(problems, 'flagFindCovers')));
assert(~any(contains(problems, 'LightStates')), 'Comments are not checked');
assert(~any(contains(problems, 'Symmetric')) && ~any(contains(problems, 'flag_do_debug')), 'Allowed names');

rmdir(testFolder, 's');

fprintf(1,'All tests of fcn_CarMesh3D_checkNames passed\n');
