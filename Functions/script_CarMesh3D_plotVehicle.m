% script_CarMesh3D_plotVehicle.m
% Tests fcn_CarMesh3D_plotVehicle
% Plots meshes and shows the fast pose-update path for animation.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_plotVehicle
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_plotVehicle
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

%% DEMO case: Plot a labeled vehicle with transparent glass
figNum = 10001;
titleString = sprintf('DEMO case: Plot a labeled vehicle with transparent glass');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(plotHandles));
assert(iscell(plotHandles.Patches));

% Check variable sizes: one opaque patch and one glass patch
assert(isequal(size(plotHandles.Patches),[2 1]));

% Check variable values
fcn_INTERNAL_checkPlotHandles(plotHandles, figNum);
assert(plotHandles.Patches{1}.FaceAlpha==1);
assert(abs(plotHandles.Patches{2}.FaceAlpha - 0.35)<1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Animate the vehicle driving in a circle by updating its pose
figNum = 10002;
titleString = sprintf('DEMO case: Animate the vehicle driving in a circle by updating its pose');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
axis([-15 15 -15 15 0 3]);
sgtitle(titleString, 'Interpreter','none');

radius = 10;
numFrames = 120;
for ith_frame = 1:numFrames
    angle = 2*pi*ith_frame/numFrames;
    pose = [radius*cos(angle), radius*sin(angle), angle + pi/2]; % [x y yaw]
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=pose, PlotHandles=plotHandles, FigNum=-1);
    drawnow limitrate;
end

% The last pose is stored in the transform
expectedMatrix = makehgtform('translate',[pose(1) pose(2) 0])*makehgtform('zrotate',pose(3));
assert(max(abs(plotHandles.Transform.Matrix(:) - expectedMatrix(:)))<1e-9);

% Only one copy of the vehicle exists in the axes
assert(1==length(findobj(gca,'Type','hgtransform')));

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

%% TEST case: Unlabeled mesh plots with its material colors
figNum = 20001;
titleString = sprintf('TEST case: Unlabeled mesh plots with its material colors');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

fcn_INTERNAL_checkPlotHandles(plotHandles, figNum);
% Glass material alpha (0.35) gives a second patch
assert(2==length(plotHandles.Patches));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Call without figure number plots into the current figure
figNum = 20002;
titleString = sprintf('TEST case: Call without figure number plots into the current figure');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh);
sgtitle(titleString, 'Interpreter','none');

fcn_INTERNAL_checkPlotHandles(plotHandles, figNum);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Full 6-value pose and gouraud lighting
figNum = 20003;
titleString = sprintf('TEST case: Full 6-value pose and gouraud lighting');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
pose = [1 2 0.5 0.05 -0.1 pi/6]; % [x y z roll pitch yaw]
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=pose, FaceLighting='gouraud', FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

expectedMatrix = makehgtform('translate',pose(1:3))*makehgtform('zrotate',pose(6))*...
    makehgtform('yrotate',pose(5))*makehgtform('xrotate',pose(4));
assert(max(abs(plotHandles.Transform.Matrix(:) - expectedMatrix(:)))<1e-9);
assert(strcmp(plotHandles.Patches{1}.FaceLighting,'gouraud'));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Two vehicles in one figure
figNum = 20004;
titleString = sprintf('TEST case: Two vehicles in one figure');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles1 = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[0 0 0], FigNum=figNum);
plotHandles2 = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[0 4 pi], FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

assert(2==length(findobj(gca,'Type','hgtransform')));
assert(plotHandles1.Axes==plotHandles2.Axes);

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

%% Basic fast mode - FigNum of -1 skips input checks and plots into the current figure
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=-1);
fcn_INTERNAL_checkPlotHandles(plotHandles, figNum);

% Make sure plot went into the current figure
assert(isequal(get(gcf,'Number'),figNum));

%% Compare speeds: full redraw versus pose update (the animation path)
figNum = 80003;
fprintf(1,'Figure: %.0f: Speed of full redraw versus pose update\n',figNum);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
Niterations = 50;

% Full redraw each time (delete and re-create)
tic;
for ith_test = 1:Niterations
    cla;
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[ith_test*0.1 0 0], FigNum=-1);
    drawnow;
end
redraw_method = toc;

% Pose update only
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=-1);
tic;
for ith_test = 1:Niterations
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[ith_test*0.1 0 0], PlotHandles=plotHandles, FigNum=-1);
    drawnow;
end
update_method = toc;

figure(373737);
clf;
barLabels = {'Full redraw','Pose update (PlotHandles)'};
X = categorical(barLabels);
X = reordercats(X,barLabels);
Y = [redraw_method update_method]*1000/Niterations;
bar(X,Y)
ylabel('Time per frame (Milliseconds)')
title('fcn_CarMesh3D_plotVehicle: time per animation frame','Interpreter','none');
fprintf(1,'Average time per frame (ms): full redraw %.3f, pose update %.3f\n',Y(1),Y(2));

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

%% FAIL case: Not a mesh structure
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(ones(3));
end

%% FAIL case: Pose with the wrong number of values
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh, Pose=[1 2]);
end

%% FAIL case: Unknown lighting
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh, FaceLighting='phong');
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

%% fcn_INTERNAL_labeledSample
function vehicleMesh = fcn_INTERNAL_labeledSample
% Makes a clean, labeled sample mesh for plotting tests
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_labeledSample

%% fcn_INTERNAL_checkPlotHandles
function fcn_INTERNAL_checkPlotHandles(plotHandles, figNumExpected)
% Checks that every returned handle is a valid graphics object, drawn
% into the expected figure
assert(isstruct(plotHandles));
assert(isgraphics(plotHandles.Transform));
assert(isgraphics(plotHandles.Axes));
assert(~isempty(plotHandles.Patches));
for ith_patch = 1:length(plotHandles.Patches)
    thisHandle = plotHandles.Patches{ith_patch};
    assert(isgraphics(thisHandle,'patch'));
    assert(isequal(figNumExpected, get(ancestor(thisHandle,'figure'),'Number')));
end
end % Ends fcn_INTERNAL_checkPlotHandles
