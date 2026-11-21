% script_test_fcn_CarMesh3D_version.m
% Tests fcn_CarMesh3D_version
% The version of this copy of CarMesh3D.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_version
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_version
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

%% DEMO case: This copy's version
figNum = 10001;
titleString = sprintf('DEMO case: This copy''s version');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[versionString, flagAtLeast] = fcn_CarMesh3D_version(FigNum=figNum);

% Check variable types
assert(ischar(versionString) && islogical(flagAtLeast));

% Check variable sizes
assert(numel(versionString)==10);

% Check variable values
assert(~isempty(regexp(versionString, '^\d{4}_\d{2}_\d{2}$', 'once')) && flagAtLeast);

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

%% TEST case: Comparing versions
figNum = 20001;
titleString = sprintf('TEST case: Comparing versions');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

versionString = fcn_CarMesh3D_version;
[~, flagOlder] = fcn_CarMesh3D_version(AtLeast='2026_01_01');
[~, flagSame] = fcn_CarMesh3D_version(AtLeast=versionString);
[~, flagNewer] = fcn_CarMesh3D_version(AtLeast='2099_12_31');
assert(flagOlder && flagSame && ~flagNewer);

%% TEST case: The mesh version
figNum = 20002;
titleString = sprintf('TEST case: The mesh version');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[versionString, ~, meshVersion] = fcn_CarMesh3D_version;
assert(ischar(meshVersion) && ~isempty(regexp(meshVersion, '^\d{4}_\d{2}_\d{2}[a-z]?$', 'once')));
% (the mesh version is never older than the release)
assert(string(meshVersion) >= string(versionString));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
versionString = fcn_CarMesh3D_version(FigNum=[]);
assert(ischar(versionString));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
versionString = fcn_CarMesh3D_version(FigNum=-1);
assert(ischar(versionString));

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

%% FAIL case: A version written another way
if 1==0
    fcn_CarMesh3D_version(AtLeast='Nov 20, 2026');
end
