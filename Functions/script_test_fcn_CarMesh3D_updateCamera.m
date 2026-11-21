% script_test_fcn_CarMesh3D_updateCamera.m
% Tests fcn_CarMesh3D_updateCamera
% Points an axes camera each animation frame from camera settings and the vehicle pose.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_updateCamera
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_updateCamera
%   % * Renamed from script_CarMesh3D_updateCamera: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_updateCamera
%   % * Tests FollowHeight and FollowPitch

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_updateCamera
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

%% DEMO case: Chase camera following a vehicle around a circle
figNum = 10001;
titleString = sprintf('DEMO case: Chase camera following a vehicle around a circle');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1), FigNum=-1);
trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Radius=15, Speed=8, Duration=6, FigNum=-1);
fcn_CarMesh3D_plotScene(GroundExtent=[-30 30 -10 50], Cubes=[0 30 2 1; 15 15 2 4; -15 15 2 5], FigNum=figNum);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
axis off;
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase');
for k = 1:length(trajectory.Time)
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=trajectory.Pose(k,:), WheelSpin=trajectory.WheelSpin(k,:), ...
        SteerAngle=trajectory.SteerAngle(k,:), PlotHandles=plotHandles, FigNum=-1);
    [cameraPosition, cameraTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, trajectory.Pose(k,:), ...
        Time=trajectory.Time(k), AxesHandle=plotHandles.Axes, FigNum=-1);
    drawnow limitrate;
end

% Check variable values: the camera is 7 m behind and 2.5 m above the
% rear axle, along the vehicle's heading
pose = trajectory.Pose(end,:);
expectedPosition = [pose(1:2) 0] + [cos(pose(3)) sin(pose(3)) 0]*(-7) + [0 0 2.5];
assert(max(abs(cameraPosition - expectedPosition)) < 1e-9);
assert(max(abs(get(plotHandles.Axes,'CameraPosition') - expectedPosition)) < 1e-9);
assert(strcmp(get(plotHandles.Axes,'Projection'),'perspective'));

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

%% TEST case: World cameras stay put; orbit cameras go around
figNum = 20001;
titleString = sprintf('TEST case: World cameras stay put; orbit cameras go around');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

axesHandle = axes;
plot3(axesHandle,0,0,0,'o');
pose = [10 5 pi/3];
% World position stays put; a vehicle-frame target follows the vehicle
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='roadside');
[cameraPosition, cameraTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, pose, AxesHandle=axesHandle);
assert(isequal(cameraPosition,[0 -8 1.5]));
assert(max(abs(cameraTarget - ([10 5 0] + [1.35*cos(pi/3) 1.35*sin(pi/3) 0.7]))) < 1e-9);
% Orbit: after a quarter turn, a camera that started behind is to the right
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='orbit', Position=[-9 0 4], Target=[0 0 0], OrbitRate=pi/2);
cameraPosition = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 0], Time=1, AxesHandle=axesHandle);
assert(max(abs(cameraPosition - [0 -9 4])) < 1e-9);
sgtitle(titleString, 'Interpreter','none');

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: On a hill: following the vehicle's height, and its pitch
figNum = 20002;
titleString = sprintf('TEST case: On a hill: following the vehicle''s height, and its pitch');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

axesHandle = axes;
plot3(axesHandle,0,0,0,'o');
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', Position=[-8 0 3], Target=[4 0 1]);
% (a six-value pose 12 m up a hill: the camera rides 12 m higher)
[levelPosition, levelTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 0 0 0 0], AxesHandle=axesHandle);
[hillPosition, hillTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 12 0 0 0], AxesHandle=axesHandle);
assert(max(abs(hillPosition - levelPosition - [0 0 12])) < 1e-9 && max(abs(hillTarget - levelTarget - [0 0 12])) < 1e-9);
% (the old behavior: z = 0)
oldPosition = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 12 0 0 0], FollowHeight=false, AxesHandle=axesHandle);
assert(max(abs(oldPosition - levelPosition)) < 1e-9);
% (pitched nose up by 0.1 rad: the target rises, the camera drops, the up vector tilts back)
[pitchPosition, pitchTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 0 0 -0.1 0], FollowPitch=true, AxesHandle=axesHandle);
assert(pitchTarget(3) > levelTarget(3) && pitchPosition(3) < levelPosition(3));
upVector = get(axesHandle, 'CameraUpVector');
assert(upVector(1) < 0 && abs(norm(upVector) - 1) < 1e-9);
% (without FollowPitch, the pitch is not used)
[~, flatTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 0 0 -0.1 0], AxesHandle=axesHandle);
assert(max(abs(flatTarget - levelTarget)) < 1e-9);
sgtitle(titleString, 'Interpreter','none');

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

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); clf;
axesHandle = axes;
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite');
cameraPosition = fcn_CarMesh3D_updateCamera(cameraSettings, [0 0 0], AxesHandle=axesHandle, FigNum=-1);
assert(isequal(cameraPosition,[-14 0 10]));

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

%% FAIL case: Settings not from fillCameraSettings
if 1==0
    fcn_CarMesh3D_updateCamera(struct('Position',[1 2 3]), [0 0 0]);
end

%% FAIL case: Bad pose
if 1==0
    fcn_CarMesh3D_updateCamera(fcn_CarMesh3D_fillCameraSettings, [0 0]);
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
