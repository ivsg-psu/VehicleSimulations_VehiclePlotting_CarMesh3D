% script_test_fcn_CarMesh3D_loadCache.m
% Tests fcn_CarMesh3D_loadCache
% Reusing a slow step's saved results when nothing it depends on has changed (and fcn_CarMesh3D_saveCache).
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadCache
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadCache
%   % * (fill in items here)


%% Set up the workspace
close all


cacheFile = fullfile(tempdir, 'CarMesh3D_cacheTest', 'stage_test.mat');
if isfile(cacheFile)
    delete(cacheFile);
end
cacheInputs = struct('Settings', struct('TargetFaces',24000, 'PartRules',{{'glass','glass'}}), 'Spec', struct('Height',NaN), ...
    'Files', fcn_CarMesh3D_fileStamps({'fcn_CarMesh3D_labelParts.m'}));
cacheOutputs = struct('vehicleMesh', struct('Vertices',rand(10,3), 'Faces',[1 2 3]));

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Save, then reuse when nothing changed
figNum = 10001;
titleString = sprintf('DEMO case: Save, then reuse when nothing changed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[outputs, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, FigNum=figNum);
assert(isempty(outputs) && ~flagReused && strcmp(reason, 'no cache file'));
fcn_CarMesh3D_saveCache(cacheFile, cacheInputs, cacheOutputs, FigNum=figNum);
[outputs, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, FigNum=figNum);

% Check variable types
assert(isstruct(outputs) && islogical(flagReused) && ischar(reason));

% Check variable sizes
assert(isequal(size(outputs.vehicleMesh.Vertices), [10 3]));

% Check variable values (NaN in an input still counts as unchanged)
assert(flagReused && isequal(outputs, cacheOutputs) && startsWith(reason, 'nothing changed'));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: A changed input is done again, and the reason names it
figNum = 20001;
titleString = sprintf('TEST case: A changed input is done again, and the reason names it');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

changedInputs = cacheInputs;
changedInputs.Settings.TargetFaces = 36000;
[outputs, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, changedInputs, FigNum=figNum);
assert(isempty(outputs) && ~flagReused && strcmp(reason, 'changed: Settings'));
addedInputs = cacheInputs;
addedInputs.MeshVersion = '2026_11_21c';
[~, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, addedInputs);
assert(~flagReused && contains(reason, 'MeshVersion'));

%% TEST case: Enabled=false never reuses; an unreadable file is done again
figNum = 20002;
titleString = sprintf('TEST case: FlagEnabled=false never reuses; an unreadable file is done again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[~, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, FlagEnabled=false);
assert(~flagReused && strcmp(reason, 'cache not used'));
fid = fopen(cacheFile, 'w'); fprintf(fid, 'not a mat file'); fclose(fid);
[~, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs);
assert(~flagReused && strcmp(reason, 'the cache file could not be read'));
rmdir(fileparts(cacheFile), 's');

%% Fast Mode Tests




%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
[~, flagReused] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, FigNum=[]);
assert(~flagReused);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
[~, flagReused] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, FigNum=-1);
assert(~flagReused);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: Inputs that are not a structure
if 1==0
    fcn_CarMesh3D_loadCache(cacheFile, {24000});
end
