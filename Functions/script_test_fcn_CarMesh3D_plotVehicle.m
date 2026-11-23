% script_test_fcn_CarMesh3D_plotVehicle.m
% Tests fcn_CarMesh3D_plotVehicle
% Plots meshes and shows the fast pose-update path for animation.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * Added a 0.05 s pause after each animation frame
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * Renamed from script_CarMesh3D_plotVehicle: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * Tests a scene drawn with hidden handles
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * 'auto' lighting is smooth (gouraud) for every finish, matte too (the
%   %   % function changed on 2026-11-20; this test still expected flat)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
%   % * Test: a light that is also glass (a lamp's clear cover) is drawn
%   %   % as glass while off and opaque while on

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotVehicle
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

% Check variable sizes: opaque body, glass, 4 wheels, head and tail lights
assert(isequal(size(plotHandles.Patches),[8 1]));
assert(isequal(size(plotHandles.WheelTransforms),[4 1]));

% Check variable values
fcn_INTERNAL_checkPlotHandles(plotHandles, figNum);
assert(plotHandles.Patches{1}.FaceAlpha==1);
assert(abs(plotHandles.Patches{2}.FaceAlpha - 0.35)<1e-9);
assert(all(cellfun(@(h) isgraphics(h), plotHandles.WheelTransforms)));
assert(isgraphics(plotHandles.LightPatches.headlight));
assert(isgraphics(plotHandles.LightPatches.tail));
assert(isempty(plotHandles.LightPatches.backup)); % The sample has no backup lights

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
frameDelaySeconds = 0.05; % Pause after each frame so the motion is visible
for ith_frame = 1:numFrames
    angle = 2*pi*ith_frame/numFrames;
    pose = [radius*cos(angle), radius*sin(angle), angle + pi/2]; % [x y yaw]
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=pose, PlotHandles=plotHandles, FigNum=-1);
    drawnow limitrate;
    pause(frameDelaySeconds);
end

% The last pose is stored in the transform
expectedMatrix = makehgtform('translate',[pose(1) pose(2) 0])*makehgtform('zrotate',pose(3));
assert(max(abs(plotHandles.Transform.Matrix(:) - expectedMatrix(:)))<1e-9);

% Only one copy of the vehicle exists in the axes
assert(1==length(findobj(gca,'-depth',1,'Type','hgtransform'))); % Wheel transforms are nested inside

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

assert(2==length(findobj(gca,'-depth',1,'Type','hgtransform')));
assert(plotHandles1.Axes==plotHandles2.Axes);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Finish presets, lighting, and edge settings
figNum = 20005;
titleString = sprintf('TEST case: Finish presets, lighting, and edge settings');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
finishNames = {'matte','satin','glossy','metallic'};
tiledlayout(2,2);
for ith_finish = 1:4
    nexttile;
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish=finishNames{ith_finish}, ...
        ShowEdges=(ith_finish==4), EdgeColor=[1 1 1], FigNum=figNum);
    title(finishNames{ith_finish});
    assert(strcmp(plotHandles.Patches{1}.FaceLighting,'gouraud')); % ('auto' is smooth for every finish since 2026-11-20)
end
sgtitle(titleString, 'Interpreter','none');
% The last plot (metallic) has the strongest highlights
assert(plotHandles.Patches{1}.SpecularStrength==1.00); % metallic
% Edges: shown in the given color on the last plot only
assert(isequal(plotHandles.Patches{1}.EdgeColor,[1 1 1]));

% A custom finish vector, with edges hidden
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish=[0.3 0.6 0.8 50 0], FigNum=figNum);
assert(plotHandles.Patches{1}.SpecularExponent==50);
assert(strcmp(plotHandles.Patches{1}.EdgeColor,'none'));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Wheels spin and steer
figNum = 20006;
titleString = sprintf('TEST case: Wheels spin and steer');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, WheelSpin=[0.5 0.5 1.0 1.0], SteerAngle=0.3, ShowEdges=true, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% The front-left wheel: steered 0.3 rad and spun 0.5 rad about its center
center = plotHandles.WheelCenters(1,:);
expectedMatrix = makehgtform('translate',center)*makehgtform('zrotate',0.3)*makehgtform('yrotate',0.5)*makehgtform('translate',-center);
assert(max(abs(plotHandles.WheelTransforms{1}.Matrix(:) - expectedMatrix(:)))<1e-12);
% A rear wheel is spun but not steered
center = plotHandles.WheelCenters(3,:);
expectedMatrix = makehgtform('translate',center)*makehgtform('yrotate',1.0)*makehgtform('translate',-center);
assert(max(abs(plotHandles.WheelTransforms{3}.Matrix(:) - expectedMatrix(:)))<1e-12);
% Forward rolling: a point at the top of a wheel moves forward
topPoint = [plotHandles.WheelCenters(3,1:2) 2*plotHandles.WheelCenters(3,3) 1]';
movedPoint = plotHandles.WheelTransforms{3}.Matrix*topPoint;
assert(movedPoint(1) > topPoint(1));

% Wheel lift: the front-right wheel rises 0.1 m; the others stay down
fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, WheelLift=[0 0.1 0 0], FigNum=-1);
assert(abs(plotHandles.WheelTransforms{2}.Matrix(3,4) - 0.1) < 1e-12);
assert(abs(plotHandles.WheelTransforms{1}.Matrix(3,4)) < 1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Body rolls and pitches while the wheels stay on the ground
figNum = 20010;
titleString = sprintf('TEST case: Body rolls and pitches while the wheels stay on the ground');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
% Roll and pitch would come from a vehicle dynamics model; here they are
% made large so the motion is easy to see
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, BodyRoll=deg2rad(6), BodyPitch=deg2rad(3), ...
    BodyHeave=-0.03, ShowEdges=true, FigNum=figNum);
view(0,0); % Look from the side
sgtitle(titleString, 'Interpreter','none');

% Check variable types: a body transform inside the vehicle transform
assert(isgraphics(plotHandles.BodyTransform));
assert(plotHandles.BodyTransform.Parent==plotHandles.Transform);
% Wheels are NOT inside the body transform (they stay on the ground)
assert(plotHandles.WheelTransforms{1}.Parent==plotHandles.Transform);
% Lights ride with the body
assert(isempty(plotHandles.LightPatches.headlight) || plotHandles.LightPatches.headlight.Parent==plotHandles.BodyTransform);

% Check variable sizes
assert(isequal(size(plotHandles.BodyPivot),[1 3]));

% Check variable values
pivot = plotHandles.BodyPivot;
expectedMatrix = makehgtform('translate',[0 0 -0.03])*makehgtform('translate',pivot)* ...
    makehgtform('yrotate',deg2rad(3))*makehgtform('xrotate',deg2rad(6))*makehgtform('translate',-pivot);
assert(max(abs(plotHandles.BodyTransform.Matrix(:) - expectedMatrix(:)))<1e-12);
% Default pivot: midway between the axles, on the centerline
assert(abs(pivot(1) - mean(plotHandles.WheelCenters(:,1))) < 1e-9 && pivot(2)==0);
% Signs: positive roll lowers the right side, positive pitch lowers the nose
rightPoint = [pivot(1) pivot(2)-1 pivot(3) 1]';
frontPoint = [pivot(1)+1 pivot(2) pivot(3) 1]';
rollOnly = makehgtform('translate',pivot)*makehgtform('xrotate',deg2rad(6))*makehgtform('translate',-pivot);
pitchOnly = makehgtform('translate',pivot)*makehgtform('yrotate',deg2rad(3))*makehgtform('translate',-pivot);
movedRight = rollOnly*rightPoint;
movedFront = pitchOnly*frontPoint;
assert(movedRight(3) < pivot(3));
assert(movedFront(3) < pivot(3));

% The fast path moves the body back to level
fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, FigNum=-1);
assert(max(abs(plotHandles.BodyTransform.Matrix(:) - reshape(eye(4),[],1)))<1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Lights switch on and off, also on the fast path
figNum = 20007;
titleString = sprintf('TEST case: Lights switch on and off, also on the fast path');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
lightStates = struct('Headlights','high','Tail','brake');
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, LightStates=lightStates, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% On: one glowing color, drawn unshaded
assert(all(all(plotHandles.LightPatches.headlight.FaceVertexCData==1)));
assert(strcmp(plotHandles.LightPatches.headlight.FaceLighting,'none'));
assert(all(abs(plotHandles.LightPatches.tail.FaceVertexCData(1,:) - [1.00 0.12 0.08])<1e-12));

% Off again, on the fast path: back to the plain colors, shaded
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Headlights','off'), FigNum=-1);
assert(isequal(plotHandles.LightPatches.headlight.FaceVertexCData, plotHandles.LightOffColors.headlight{1}));   % (one cell per patch of the group)
assert(~strcmp(plotHandles.LightPatches.headlight.FaceLighting,'none'));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: A tail light that is also a turn signal (multi-function lights)
figNum = 20012;
titleString = sprintf('TEST case: A tail light that is also a turn signal');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
tailIndex = find(strcmp(vehicleMesh.LightTypeNames,'tail'));
tailFaces = find(vehicleMesh.FaceLightType==tailIndex);
assert(~isempty(tailFaces), 'The sample has tail lights');
vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','US rear turn signals', ...
    'FaceIndices',tailFaces, 'AlsoLightTypes',{{'turnsignal'}})}, FigNum=-1);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, LightStates=struct('Tail','on'), FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
assert(any(strcmp(plotHandles.LightGroupNames,'turnLeft_tail')) && any(strcmp(plotHandles.LightGroupNames,'turnRight_tail')));
leftCombo = plotHandles.LightPatches.turnLeft_tail;
% (tail on: dim red; left signal on: bright red on the left lamp only; off: plain colors)
assert(all(abs(leftCombo(1).FaceVertexCData(1,:) - [0.70 0.04 0.04])<1e-12));
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Tail','on','TurnLeft',true), FigNum=-1);
assert(all(abs(leftCombo(1).FaceVertexCData(1,:) - [1.00 0.12 0.08])<1e-12));
assert(all(abs(plotHandles.LightPatches.turnRight_tail(1).FaceVertexCData(1,:) - [0.70 0.04 0.04])<1e-12));
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Tail','off','TurnLeft',false), FigNum=-1);
assert(isequal(leftCombo(1).FaceVertexCData, plotHandles.LightOffColors.turnLeft_tail{1}));
% (with the light effects, the combined groups glow too)
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, LightStates=struct('TurnRight',true), LightEffects=true, FigNum=figNum);
assert(strcmp(plotHandles.LightEffects.Glow.turnRight_tail.Visible,'on') && strcmp(plotHandles.LightEffects.Glow.turnLeft_tail.Visible,'off'));

%% TEST case: A headlight that is also glass (a clear cover): glass while off, opaque while on
figNum = 20013;
titleString = sprintf('TEST case: A headlight that is also glass: glass while off, opaque while on');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
headIndex = find(strcmp(vehicleMesh.LightTypeNames,'headlight'));
headFaces = find(vehicleMesh.FaceLightType==headIndex);
glassIndex = find(strcmp(vehicleMesh.PartNames,'glass'));
coverFaces = headFaces(1:2:end);       % (half the headlight faces: a clear cover)
vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','clear covers', ...
    'FaceIndices',coverFaces, 'AlsoParts',{{'glass'}})}, FigNum=-1);
glassFaces = vehicleMesh.FacePartIndex==glassIndex;
glassAlpha = median(vehicleMesh.FaceAlpha(glassFaces));
glassColor = median(vehicleMesh.FaceColors(glassFaces,:), 1);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
headPatches = plotHandles.LightPatches.headlight;
onAlpha = plotHandles.LightOnAlpha.headlight;
flagCover = ~cellfun(@isempty, onAlpha);
assert(numel(headPatches) == numel(onAlpha) && any(flagCover) && any(~flagCover));
coverPatch = headPatches(find(flagCover,1));
lampPatch = headPatches(find(~flagCover,1));
assert(size(coverPatch.Faces,1) + size(lampPatch.Faces,1) == numel(headFaces));
% (off: the cover drawn as the vehicle's glass)
assert(abs(coverPatch.FaceAlpha - glassAlpha) < 1e-9);
assert(all(abs(coverPatch.FaceVertexCData(1,:) - glassColor) < 1e-9));
% (on: glowing and opaque; the plain lamp keeps its own transparency)
lampAlpha = lampPatch.FaceAlpha;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Headlights','high'), FigNum=-1);
assert(coverPatch.FaceAlpha == 1 && all(coverPatch.FaceVertexCData(:)==1));
assert(lampPatch.FaceAlpha == lampAlpha);
% (off again: glass again)
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Headlights','off'), FigNum=-1); %#ok<NASGU>
assert(abs(coverPatch.FaceAlpha - glassAlpha) < 1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Night light effects (glows and ground pools) follow the lights
figNum = 20011;
titleString = sprintf('TEST case: Night light effects (glows and ground pools) follow the lights');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
fcn_CarMesh3D_plotScene(GroundExtent=[-15 30 -12 12], TimeOfDay='night', FigNum=figNum);
lightStates = struct('Headlights','high','Tail','brake','TurnLeft',true);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, LightStates=lightStates, LightEffects=true, FigNum=figNum);
view(-60,25);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(plotHandles.LightEffects));
assert(isfield(plotHandles.LightEffects,'Glow') && isfield(plotHandles.LightEffects,'Pools'));

% Check variable values
pools = plotHandles.LightEffects.Pools;
% High beams show both the low and the high beam pools
assert(strcmp(pools.lowBeam.Visible,'on') && strcmp(pools.highBeam.Visible,'on'));
% Braking shows the brake pool, not the dimmer tail pool; no backup
assert(strcmp(pools.brake.Visible,'on') && strcmp(pools.tail.Visible,'off') && strcmp(pools.backup.Visible,'off'));
% Pools ride with the ground frame; glows ride with the body
assert(pools.lowBeam.Parent==plotHandles.Transform);
glowHeadlight = plotHandles.LightEffects.Glow.headlight;
assert(glowHeadlight.Parent==plotHandles.BodyTransform && strcmp(glowHeadlight.Visible,'on'));
% The low beam is ahead of the vehicle, the brake pool behind it
assert(min(pools.lowBeam.Vertices(:,1)) > 0.5*max(vehicleMesh.Vertices(:,1)));
assert(max(pools.brake.Vertices(:,1)) < 0.5*max(vehicleMesh.Vertices(:,1)));
% Turn-signal pools: on for the turn signal that is on (left), off for
% the other; left ones on the left (+y)
assert(strcmp(pools.turnLeftFront.Visible,'on') && strcmp(pools.turnRightRear.Visible,'off'));
assert(mean(pools.turnLeftFront.Vertices(:,2)) > 0 && mean(pools.turnRightRear.Vertices(:,2)) < 0);
assert(min(pools.turnLeftFront.Vertices(:,1)) > 0.5*max(vehicleMesh.Vertices(:,1)));
assert(max(pools.turnLeftRear.Vertices(:,1)) < 0.5*max(vehicleMesh.Vertices(:,1)));
fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('TurnRight',true), FigNum=-1);
assert(strcmp(pools.turnRightFront.Visible,'on') && strcmp(pools.turnRightRear.Visible,'on'));
assert(strcmp(pools.turnLeftFront.Visible,'off') && strcmp(pools.turnLeftRear.Visible,'off'));
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, ...
    LightStates=lightStates, FigNum=-1);
% Pools fade out at the far end
assert(max(pools.lowBeam.FaceVertexAlphaData) <= 0.5 && min(pools.lowBeam.FaceVertexAlphaData) == 0);
% The night scene darkened the axes and added its own lights
assert(isequal(get(gca,'AmbientLightColor'),[0.35 0.38 0.55]));
assert(2==length(findobj(gca,'Type','light')));

% Fast path: low beams, backing up, no brake
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, ...
    LightStates=struct('Headlights','low','Tail','on','Backup',true), FigNum=-1);
assert(strcmp(pools.lowBeam.Visible,'on') && strcmp(pools.highBeam.Visible,'off'));
assert(strcmp(pools.tail.Visible,'on') && strcmp(pools.brake.Visible,'off') && strcmp(pools.backup.Visible,'on'));
if ~isempty(plotHandles.LightEffects.Glow.turnLeft)
    assert(strcmp(plotHandles.LightEffects.Glow.turnLeft.Visible,'off'));
end

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: High beams as lamps of their own: each beam switched alone
figNum = 20014;
titleString = sprintf('TEST case: High beams as lamps of their own: each beam switched alone');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), AutoHighBeams=false, FigNum=-1);
headFaces = find(vehicleMesh.FaceLightType == find(strcmp(vehicleMesh.LightTypeNames,'headlight')));
assert(numel(headFaces) >= 2);
vehicleMesh.FaceLightType(headFaces(1:2:end)) = find(strcmp(vehicleMesh.LightTypeNames,'highbeam'));
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, LightEffects=true, ...
    LightStates=struct('LowBeam',true,'HighBeam',false), FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
assert(~isempty(plotHandles.LightPatches.highBeam));
lowColor = plotHandles.LightPatches.headlight(1).FaceVertexCData(1,:);
highColors = plotHandles.LightPatches.highBeam(1).FaceVertexCData;
assert(all(abs(lowColor - [1.00 0.96 0.78]) < 1e-12), 'Low beams lit');
assert(~all(all(highColors == 1)), 'High beams off');
pools = plotHandles.LightEffects.Pools;
assert(strcmp(pools.lowBeam.Visible,'on') && strcmp(pools.highBeam.Visible,'off'));
% High beams alone
fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('LowBeam',false,'HighBeam',true), FigNum=-1);
assert(all(all(plotHandles.LightPatches.highBeam(1).FaceVertexCData == 1)), 'High beams lit white');
assert(~all(abs(plotHandles.LightPatches.headlight(1).FaceVertexCData(1,:) - [1.00 0.96 0.78]) < 1e-12), 'Low beams off');
assert(strcmp(pools.lowBeam.Visible,'off') && strcmp(pools.highBeam.Visible,'on'));
% 'high' in Headlights is still both beams
fcn_CarMesh3D_plotVehicle(vehicleMesh, PlotHandles=plotHandles, LightStates=struct('Headlights','high'), FigNum=-1);
assert(strcmp(pools.lowBeam.Visible,'on') && strcmp(pools.highBeam.Visible,'on'));
assert(all(abs(plotHandles.LightPatches.headlight(1).FaceVertexCData(1,:) - [1.00 0.96 0.78]) < 1e-12));

%% TEST case: A scene drawn with hidden handles is kept as it is
figNum = 20099;
titleString = sprintf('TEST case: A scene drawn with hidden handles is kept as it is');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sceneAxes = axes;
patch(sceneAxes, [-20 20 20 -20], [-20 -20 20 20], [0 0 0 0], [0.3 0.5 0.3], 'HandleVisibility','off');
light('Parent',sceneAxes, 'Style','infinite', 'Position',[0 0 1], 'HandleVisibility','off');
view(sceneAxes, 37, 25);
xlim(sceneAxes, [-20 20]);
viewBefore = get(sceneAxes, 'View');
limitsBefore = get(sceneAxes, 'XLim');
fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=figNum);
assert(isequal(get(sceneAxes, 'View'), viewBefore) && isequal(get(sceneAxes, 'XLim'), limitsBefore));   % (not reformatted)
assert(numel(findall(sceneAxes, 'Type','light'))==1);                                                  % (no lights added)

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

%% FAIL case: Unknown light state field
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh), LightStates=struct('FogLights','on'));
end

%% FAIL case: Wheel spin with the wrong number of values
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh, WheelSpin=[1 2 3]);
end

%% FAIL case: Unknown finish
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh, Finish='shiny');
end

%% FAIL case: Edge color out of range
if 1==0
    plotHandles = fcn_CarMesh3D_plotVehicle(fcn_CarMesh3D_fillSampleMesh, ShowEdges=true, EdgeColor=[255 255 255]);
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
