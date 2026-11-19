% script_CarMesh3D_plotScene.m
% Tests fcn_CarMesh3D_plotScene
% Draws a ground plane, grid, cubes, and a path for vehicles to drive in.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_plotScene
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_plotScene
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

%% DEMO case: Ground, grid, cubes, and a path
figNum = 10001;
titleString = sprintf('DEMO case: Ground, grid, cubes, and a path');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', Radius=12, Duration=20, FigNum=-1);
cubes = [10 8 2 1; -10 -8 2 5; 0 18 1.5 3; 25 0 3 4];
sceneHandles = fcn_CarMesh3D_plotScene(Cubes=cubes, PathXY=trajectory.Pose(:,1:2), FigNum=figNum);
view(-35,30);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(sceneHandles));

% Check variable values
assert(isgraphics(sceneHandles.Ground,'patch'));
assert(isgraphics(sceneHandles.Cubes,'patch'));
assert(isgraphics(sceneHandles.Path,'line'));
assert(size(sceneHandles.Cubes.Faces,1)==6*size(cubes,1)); % 6 sides per cube

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: A vehicle in the scene
figNum = 10002;
titleString = sprintf('DEMO case: A vehicle in the scene');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sceneHandles = fcn_CarMesh3D_plotScene(GroundExtent=[-10 10 -10 10], GridSpacing=2, Cubes=[6 3 1 2], FigNum=figNum);
vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
view(-35,30);
sgtitle(titleString, 'Interpreter','none');
assert(plotHandles.Axes==sceneHandles.Axes);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: No grid, no cubes, no path
figNum = 20001;
titleString = sprintf('TEST case: No grid, no cubes, no path');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sceneHandles = fcn_CarMesh3D_plotScene(GridSpacing=0, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
assert(isempty(sceneHandles.GridLines));
assert(isempty(sceneHandles.Cubes));
assert(isempty(sceneHandles.Path));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic fast mode - FigNum of -1 draws into the current figure
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); clf;
sceneHandles = fcn_CarMesh3D_plotScene(FigNum=-1);
assert(isgraphics(sceneHandles.Ground,'patch'));
assert(isequal(get(gcf,'Number'),figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: Bad ground extent
if 1==0
    sceneHandles = fcn_CarMesh3D_plotScene(GroundExtent=[10 -10 0 5]);
end

%% FAIL case: Cubes with too few columns
if 1==0
    sceneHandles = fcn_CarMesh3D_plotScene(Cubes=[1 2 3]);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
