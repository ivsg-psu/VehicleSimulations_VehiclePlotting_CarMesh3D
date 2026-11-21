% script_test_fcn_CarMesh3D_fileStamps.m
% Tests fcn_CarMesh3D_fileStamps
% The name, size, and date of files, for the cached steps.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fileStamps
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fileStamps
%   % * (fill in items here)


%% Set up the workspace
close all


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

%% DEMO case: Stamps of a function and a file
figNum = 10001;
titleString = sprintf('DEMO case: Stamps of a function and a file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

testFile = fullfile(tempdir, 'CarMesh3D_stampTest.txt');
fid = fopen(testFile, 'w'); fprintf(fid, 'first'); fclose(fid);
fileStamps = fcn_CarMesh3D_fileStamps({'fcn_CarMesh3D_labelParts.m', testFile}, FigNum=figNum);

% Check variable types
assert(isstruct(fileStamps) && all(isfield(fileStamps, {'Name','Bytes','Date'})));

% Check variable sizes
assert(isequal(size(fileStamps), [2 1]));

% Check variable values
assert(strcmp(fileStamps(1).Name, 'fcn_CarMesh3D_labelParts.m') && fileStamps(1).Bytes > 0);
assert(strcmp(fileStamps(2).Name, 'CarMesh3D_stampTest.txt') && fileStamps(2).Bytes==5);

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

%% TEST case: A changed file changes its stamp; a missing file has Bytes -1
figNum = 20001;
titleString = sprintf('TEST case: A changed file changes its stamp; a missing file has Bytes -1');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

before = fcn_CarMesh3D_fileStamps(testFile);
pause(1.1);
fid = fopen(testFile, 'w'); fprintf(fid, 'second!'); fclose(fid);
after = fcn_CarMesh3D_fileStamps(testFile);
assert(~isequal(before, after) && after.Bytes==7);
missing = fcn_CarMesh3D_fileStamps({fullfile(tempdir,'no_such_CarMesh3D_file.txt')});
assert(missing.Bytes==-1 && missing.Date==0 && isequal(missing, fcn_CarMesh3D_fileStamps({fullfile(tempdir,'no_such_CarMesh3D_file.txt')})));
delete(testFile);

%% Fast Mode Tests




%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
fileStamps = fcn_CarMesh3D_fileStamps('fcn_CarMesh3D_labelParts.m', FigNum=[]);
assert(isstruct(fileStamps));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
fileStamps = fcn_CarMesh3D_fileStamps('fcn_CarMesh3D_labelParts.m', FigNum=-1);
assert(isstruct(fileStamps));

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

%% FAIL case: A list that is not text
if 1==0
    fcn_CarMesh3D_fileStamps({1, 2});
end
