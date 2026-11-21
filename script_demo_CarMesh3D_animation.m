%% Introduction to and Purpose of the Code
% This is the explanation of the code that can be found by running
%       script_demo_CarMesh3D_animation.m
% This script shows how to ANIMATE CarMesh3D vehicles:
%   * wheels that roll with the motion, lock up, or peel out,
%   * front wheels that steer to follow the path,
%   * lights that switch: headlights, turn signals, hazards, brake
%     lights, and backup lights,
%   * cameras: fixed, following, riding on the vehicle, and orbiting,
%   * a night scene, where lit lamps glow and throw pools of light
%     (headlight beams, brake and backup lights) on the ground,
%   * a motion read from a CSV file (as written by a vehicle dynamics
%     simulation), with body roll and pitch and a lifted wheel.
% Every animation can be saved as an animated GIF (for example, for the
% README). Run script_demo_CarMesh3D.m first to learn how meshes are made.
%
% If you have questions or comments, please contact Sean Brennan at
% sbrennan@psu.edu
%
% THE ANIMATION LOOP. Every animation below is the same loop:
%
%   trajectory     = fcn_CarMesh3D_fillTrajectory(...);    % where, when
%   cameraSettings = fcn_CarMesh3D_fillCameraSettings(...); % how to look
%   h = fcn_CarMesh3D_plotVehicle(vehicleMesh, ...);       % draw once
%   for k = 1:numberOfFrames
%       fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=..., WheelSpin=..., ...
%           SteerAngle=..., LightStates=..., PlotHandles=h, FigNum=-1);
%       fcn_CarMesh3D_updateCamera(cameraSettings, pose, Time=t, ...
%           AxesHandle=h.Axes, FigNum=-1);
%       drawnow;
%       fcn_CarMesh3D_saveGifFrame(gcf, gifFile, k);        % optional
%   end
%
% The loop is written once, in fcn_INTERNAL_animate at the end of this
% script, so each example only says what is different.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D_animation
%   % * First write of the code (drafted with Claude)
%   % * Added Step 7, night scenes with light effects
%   % * Added Step 8, animating a motion from a CSV file (body roll, pitch,
%   %   wheel lift); fcn_INTERNAL_animate uses a motion's own body, wheel
%   %   lift, and light states when it has them
%   % * Step 4 camera moved closer; overhead cameras centered over the
%   %   figure eight; driver camera uses the (moved) preset
%   % * Added Step 9, Ackermann steering in a tight turn, from above

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D_animation


%% Make sure we are running out of root directory
st = dbstack;
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);
addpath(fullfile(pwd,'Functions'));
addpath(fullfile(pwd,'Data'));

%% Settings for all of the animations
% Set flag_saveGifs to 0 to just watch the animations without saving.
flag_saveGifs = 1;
gifFolder = fullfile('Images','animations');
if flag_saveGifs && ~exist(gifFolder,'dir')
    mkdir(gifFolder);
end
framesPerSecond = 12;          % Animation frames per second
figureSize = [560 320];        % Figure size in pixels (smaller = smaller GIFs)

%% Step 1: The vehicle, with its lights labeled
% This builds the downloaded 2010 Prius model (see script_demo_CarMesh3D)
% and corrects its light labels with fcn_CarMesh3D_editLabels, so the
% lights can be switched. If the model or Blender is missing, the
% built-in sample car is used.
[vehicleMesh, vehicleSpec] = fcn_INTERNAL_prepareVehicle;
fprintf(1,'Vehicle: %s, %d faces\n', vehicleMesh.Name, size(vehicleMesh.Faces,1));

%% Step 2: Wheels roll and steer (lane change, close-up)
% The trajectory gives the wheel spin (distance / tire radius) and the
% steer angle (from the path's curvature) at each frame. The camera is
% attached to the vehicle (PositionFrame 'vehicle'), ahead and to the
% left, looking back at the front wheel.
trajectory = fcn_CarMesh3D_fillTrajectory(Path='laneChange', LaneOffset=3.5, Speed=4, ...
    Duration=10, SampleTime=1/framesPerSecond, StartPose=[-20 0 0], VehicleSpec=vehicleSpec, FigNum=-1);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', ...
    Position=[5.5 3.5 1.3], Target=[2.2 0 0.35], FieldOfView=40);
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, @(t) struct(), ...
    fullfile(gifFolder,'wheels_rollAndSteer.gif'), flag_saveGifs, figureSize, 1);

%% Step 3: Peel out, cruise, then lock up the wheels (side view)
% WheelSlip sets how fast each wheel turns compared with rolling:
%   0 = rolling, -1 = locked (skidding), 2 = turning 3 times too fast.
% The Prius is front-wheel drive, so only the front wheels peel out.
% Brake lights come on while braking.
dt = 1/framesPerSecond;
timeValues = (0:dt:9)';
speedValues = min(2.5*timeValues, 8);                                  % Launch
speedValues(timeValues>=6) = max(8 - 5*(timeValues(timeValues>=6)-6), 0); % Brake
slip = zeros(length(timeValues),4);
slip(timeValues<2, 1:2) = 2;                 % Peel out: front wheels spin fast
slip(timeValues>=6 & speedValues>0, :) = -1; % Lock up: all wheels stop turning
trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=speedValues, Duration=9, SampleTime=dt, ...
    StartPose=[-25 0 0], WheelSlip=slip, VehicleSpec=vehicleSpec, FigNum=-1);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='side', Position=[1.35 -6 1.0], FieldOfView=45);
brakeLights = @(t) struct('Tail', fcn_INTERNAL_choose(t>=6, 'brake', 'on'));
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, brakeLights, ...
    fullfile(gifFolder,'wheels_peelOutAndLockUp.gif'), flag_saveGifs, figureSize, 2);

%% Step 4: Signals - turn signal, lane change, hazards, then backing up
% LightStates is a structure: Headlights ('off','low','high'), TurnLeft,
% TurnRight, Running (true/false), Tail ('off','on','brake'), Backup.
% Blinking is just switching a light on and off with time:
%       blinkOn = mod(t, 0.8) < 0.4;   % 0.4 s on, 0.4 s off
% Here: signal left (0-3 s), change lanes (3-7 s), stop with hazards
% (7-10 s), then back up (10-14 s).
dt = 1/framesPerSecond;
timeValues = (0:dt:14)';
speedValues = 6*ones(size(timeValues));
speedValues(timeValues>=7 & timeValues<10) = max(6 - 6*(timeValues(timeValues>=7 & timeValues<10)-7), 0);
speedValues(timeValues>=10) = -min(1.5*(timeValues(timeValues>=10)-10), 2);
trajectory = fcn_CarMesh3D_fillTrajectory(Path='laneChange', LaneOffset=3.5, Speed=speedValues, ...
    Duration=14, SampleTime=dt, StartPose=[-25 0 0], VehicleSpec=vehicleSpec, FigNum=-1);
% The camera rides close behind and to the left, so the lamps are large
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', Position=[-5.5 3.2 1.8], Target=[1.5 0 0.6], FieldOfView=40);
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, @fcn_INTERNAL_signalSequence, ...
    fullfile(gifFolder,'lights_signalsHazardsBackup.gif'), flag_saveGifs, figureSize, 3);

%% Step 5: Headlights off, low, high, with running lights (front view)
trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=0.001, Duration=6, ...
    SampleTime=1/framesPerSecond, VehicleSpec=vehicleSpec, FigNum=-1);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', Position=[9 -3 1.4], Target=[2.5 0 0.6], FieldOfView=35);
headlightSequence = @(t) struct('Headlights', fcn_INTERNAL_choose(t<2,'off', fcn_INTERNAL_choose(t<4,'low','high')), ...
    'Running', t>=2, 'TurnLeft', false, 'TurnRight', false);
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, headlightSequence, ...
    fullfile(gifFolder,'lights_headlights.gif'), flag_saveGifs, figureSize, 4);

%% Step 6: Camera modes
% Each camera is (1) where it sits, (2) what it looks at, (3) how wide it
% sees, and (4) an optional orbit. "World" points stay put; "vehicle"
% points ride along. The vehicle drives a figure eight past colored
% cubes, so the riding cameras have something to see. The figure eight
% from [0 0 0] covers x 0 to 22 m and y -22 to 0 m, so the overhead
% cameras sit above its middle, [11 -11].
trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', Radius=12, Speed=7, Duration=8, ...
    SampleTime=1/framesPerSecond, StartPose=[0 0 0], VehicleSpec=vehicleSpec, FigNum=-1);
cameraList = {
    'wideFixed', {},                                           'World camera, far away: sees the whole area';
    'roadside',  {'Position',[12 -14 1.6]},                    'World camera at the roadside, turning to follow';
    'overhead',  {'Position',[11 -11 70],'Target',[11 -11 0],'FieldOfView',45}, 'World camera straight above, wide';
    'overhead',  {'Position',[11 -11 70],'Target',[11 -11 0],'FieldOfView',20}, 'World camera straight above, zoomed in';
    'chase',     {},                                           'Vehicle camera behind, looking ahead';
    'driver',    {},                                           'Vehicle camera at the driver''s eyes';
    'roof',      {},                                           'Vehicle camera on the roof';
    'side',      {},                                           'Vehicle camera alongside';
    'kite',      {},                                           'Vehicle camera behind and above';
    'orbit',     {'OrbitRate',0.6},                            'Vehicle camera circling the car'};
cameraGifNames = {'camera_wideFixed','camera_roadside','camera_overheadWide','camera_overheadZoom', ...
    'camera_chase','camera_driver','camera_roof','camera_side','camera_kite','camera_orbit'};
cameraLights = @(t) struct('Headlights','low','Tail','on','Running',true);
for ith_camera = 1:size(cameraList,1)
    cameraOverrides = cameraList{ith_camera,2};
    % (The overrides are a list of 'Name',value pairs, so the quoted form is used)
    cameraSettings = fcn_CarMesh3D_fillCameraSettings('Mode', cameraList{ith_camera,1}, cameraOverrides{:});
    fprintf(1,'Camera %s: %s\n', cameraGifNames{ith_camera}, cameraList{ith_camera,3});
    fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, cameraLights, ...
        fullfile(gifFolder,[cameraGifNames{ith_camera} '.gif']), flag_saveGifs, figureSize, 10+ith_camera, ...
        cameraList{ith_camera,3});
end

%% Step 7: At night - headlight beams, then signals, brakes, and backing up
% fcn_CarMesh3D_plotScene(TimeOfDay='night') makes a dark sky and ground
% with dim "moonlight". fcn_CarMesh3D_plotVehicle(LightEffects=true)
% fakes light shining from the lamps: lit lamps get a glowing shell, and
% see-through pools of light are drawn on the ground (headlight beams
% ahead; red tail and brake light and white backup light behind). They
% switch with LightStates, so the animation loop does not change.
% The camera is above and behind, to see the beams on the road ahead.
trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=0.001, Duration=6, ...
    SampleTime=1/framesPerSecond, VehicleSpec=vehicleSpec, FigNum=-1);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite', Position=[-6 -5 4], Target=[9 0 0], FieldOfView=55);
nightHeadlights = @(t) struct('Headlights', fcn_INTERNAL_choose(t<2,'off', fcn_INTERNAL_choose(t<4,'low','high')), ...
    'Running', t>=2, 'Tail', fcn_INTERNAL_choose(t<2,'off','on'));
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, nightHeadlights, ...
    fullfile(gifFolder,'night_headlights.gif'), flag_saveGifs, figureSize, 21, ...
    'Night: headlights off, low, high', 'night');

% The same drive as Step 4 (signal, lane change, hazards, back up), at night
dt = 1/framesPerSecond;
timeValues = (0:dt:14)';
speedValues = 6*ones(size(timeValues));
speedValues(timeValues>=7 & timeValues<10) = max(6 - 6*(timeValues(timeValues>=7 & timeValues<10)-7), 0);
speedValues(timeValues>=10) = -min(1.5*(timeValues(timeValues>=10)-10), 2);
trajectory = fcn_CarMesh3D_fillTrajectory(Path='laneChange', LaneOffset=3.5, Speed=speedValues, ...
    Duration=14, SampleTime=dt, StartPose=[-25 0 0], VehicleSpec=vehicleSpec, FigNum=-1);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite', Position=[-8 5 4], Target=[3 0 0], FieldOfView=50);
fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, @fcn_INTERNAL_signalSequence, ...
    fullfile(gifFolder,'night_signalsHazardsBackup.gif'), flag_saveGifs, figureSize, 22, ...
    'Night: signal, change lanes, hazards and brake, back up', 'night');

%% Step 8: A motion from a CSV file, with body roll and pitch and a lifted wheel
% Vehicle dynamics simulations usually write their results as a table:
% one row per time step, one column per variable. CarMesh3D reads such a
% file with fcn_CarMesh3D_loadMotionCSV (see the column list in its help,
% or in the README). Here, the file is first WRITTEN with
% fcn_CarMesh3D_saveMotionCSV, using made-up body motion in place of a
% real dynamics model, so this example runs on its own:
%   * roll grows with lateral acceleration (right side down in a left turn),
%   * pitch follows longitudinal acceleration (nose up when speeding up),
%   * the inside front wheel lifts off the ground in the tightest part.
% The amounts are exaggerated so they are easy to see.
% fcn_CarMesh3D_checkGroundContact then checks whether the body reaches
% the road at any time (a warning, and an N x 1 flag).
dt = 1/framesPerSecond;
trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Radius=12, Speed=@(t) min(4 + 2*t, 12), ...
    Duration=8, SampleTime=dt, StartPose=[0 -12 0], VehicleSpec=vehicleSpec, FigNum=-1);
K = length(trajectory.Time);
lateralAcceleration = trajectory.Speed.^2 .* trajectory.Curvature;            % m/s^2, + to the left
longitudinalAcceleration = gradient(trajectory.Speed, trajectory.Time);       % m/s^2
bodyRoll = deg2rad(0.6)*lateralAcceleration;                                  % + right side down
bodyPitch = -deg2rad(1.0)*longitudinalAcceleration;                           % + nose down
wheelLift = zeros(K,4);                                                       % [FL FR RL RR]
wheelLift(:,1) = 0.10*min(max((lateralAcceleration - 9)/3, 0), 1);            % inside front (left)
csvFile = fullfile(tempdir,'CarMesh3D_exampleMotion.csv');
fcn_CarMesh3D_saveMotionCSV(csvFile, trajectory, BodyRoll=bodyRoll, BodyPitch=bodyPitch, ...
    WheelLift=wheelLift, Lights=struct('headlights',1, 'indicator',double(trajectory.Time<2)));

% Read it back, exactly as a file from a dynamics model would be read
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, VehicleSpec=vehicleSpec, FigNum=8);
% Does the body reach the road anywhere (possible body damage)?
flagContact = fcn_CarMesh3D_checkGroundContact(vehicleMesh, motion.BodyRoll, motion.BodyPitch, ...
    motion.BodyHeave, Time=motion.Time, FigNum=9);
fprintf(1,'Body touches the road in %d of %d samples\n', sum(flagContact), length(flagContact));

% Three views of the same motion, each riding with the vehicle:
%   front:  looking back at the vehicle; the body's roll shows against the ground
%   inside: low, beside the inside (left) of the turn; the lifted front wheel shows
%   rear:   low, behind and to the left; the lifted wheel shows under the body
csvViews = {
    'csv_bodyRollAndWheelLift',        [9 1.5 0.9],   [1.35 0 0.55], 30, 'From a CSV file: body roll and pitch (front view)';
    'csv_bodyRollAndWheelLift_inside', [2.7 6.5 0.35], [2.4 0 0.3],  32, 'From a CSV file: the inside front wheel lifts (side view)';
    'csv_bodyRollAndWheelLift_rear',   [-6 3.5 0.6],   [2.2 0.6 0.3], 32, 'From a CSV file: roll, pitch, and wheel lift (rear view)'};
for ith_view = 1:size(csvViews,1)
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', Position=csvViews{ith_view,2}, ...
        Target=csvViews{ith_view,3}, FieldOfView=csvViews{ith_view,4});
    fcn_INTERNAL_animate(vehicleMesh, motion, cameraSettings, [], ...
        fullfile(gifFolder,[csvViews{ith_view,1} '.gif']), flag_saveGifs, figureSize, 22+ith_view, ...
        csvViews{ith_view,5});
end

%% Step 9: Ackermann steering in a tight turn, seen from above
% In a turn, every wheel rolls around the same turn center, so each tire
% points at right angles to the line from the turn center to that tire.
% The inside front tire is closer to the center and steers more than the
% outside one (see fcn_CarMesh3D_calcAckermannSteering). The dashed lines
% go from the turn center to each wheel; the caption gives both angles.
trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Radius=5, Speed=1.5, Duration=8, ...
    SampleTime=1/framesPerSecond, StartPose=[0 0 0], VehicleSpec=vehicleSpec, FigNum=-1);
yaw0 = trajectory.Pose(1,3);
turnCenter = trajectory.Pose(1,1:2) + [-sin(yaw0) cos(yaw0)]/trajectory.Curvature(1);
figNum = 30;
figureHandle = figure(figNum);
clf;
set(figureHandle,'Color',[0.78 0.86 0.95],'Position',[100 100 figureSize]);
axesHandle = axes('Parent',figureHandle,'Position',[0 0 1 1]);
groundExtent = [turnCenter(1)+[-25 25] turnCenter(2)+[-25 25]];
fcn_CarMesh3D_plotScene(GroundExtent=groundExtent, GridSpacing=1, FigNum=figNum);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish='glossy', FigNum=figNum);
axis(axesHandle,'off');
axis(axesHandle,[groundExtent -1 25]);
hold(axesHandle,'on');
plot3(axesHandle, turnCenter(1), turnCenter(2), 0.05, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 6);
radiusLines = gobjects(4,1);
lineColors = [0 0 1; 1 0 0; 0.2 0.2 0.2; 0.2 0.2 0.2]; % FL blue, FR red, rear gray
for ith_wheel = 1:4
    radiusLines(ith_wheel) = plot3(axesHandle, nan(1,2), nan(1,2), [0.05 0.05], '--', ...
        'Color', lineColors(ith_wheel,:), 'LineWidth', 1.5);
end
captionHandle = annotation(figureHandle,'textbox',[0.01 0.90 0.9 0.08],'String','', ...
    'FitBoxToText','on','FontWeight','bold','BackgroundColor',[1 1 1],'FaceAlpha',0.6, ...
    'EdgeColor','none','Interpreter','none');
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='overhead', Position=[turnCenter 26], ...
    Target=[turnCenter 0], FieldOfView=32);
for k = 1:length(trajectory.Time)
    pose = trajectory.Pose(k,:);
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=pose, WheelSpin=trajectory.WheelSpin(k,:), ...
        SteerAngle=trajectory.SteerAngle(k,:), PlotHandles=plotHandles, FigNum=-1);
    fcn_CarMesh3D_updateCamera(cameraSettings, pose, AxesHandle=axesHandle, FigNum=-1);
    % Wheel centers in the world: rotate by the heading, then move to the pose
    rotation = [cos(pose(3)) -sin(pose(3)); sin(pose(3)) cos(pose(3))];
    wheelXY = (rotation*plotHandles.WheelCenters(:,1:2)')' + pose(1:2);
    for ith_wheel = 1:4
        set(radiusLines(ith_wheel), 'XData', [turnCenter(1) wheelXY(ith_wheel,1)], ...
            'YData', [turnCenter(2) wheelXY(ith_wheel,2)]);
    end
    set(captionHandle, 'String', sprintf('Ackermann steering: inside (left) %.1f%s, outside (right) %.1f%s', ...
        rad2deg(trajectory.SteerAngle(k,1)), char(176), rad2deg(trajectory.SteerAngle(k,2)), char(176)));
    drawnow;
    if flag_saveGifs
        fcn_CarMesh3D_saveGifFrame(figureHandle, fullfile(gifFolder,'wheels_ackermannTightTurn.gif'), k, ...
            DelayTime=mean(diff(trajectory.Time)), FigNum=-1);
    end
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

%% fcn_INTERNAL_animate
function fcn_INTERNAL_animate(vehicleMesh, trajectory, cameraSettings, lightFunction, gifFile, flag_saveGif, figureSize, figNum, titleString, timeOfDay)
% The animation loop used by every example: draw the scene and vehicle
% once, then for each frame move the vehicle (pose, wheels, lights),
% point the camera, draw, and optionally save a GIF frame.
%   lightFunction: a function of time that returns the LightStates, or
%       [] to use the motion's own LightStates (one per time step)
%   The motion may also carry BodyRoll, BodyPitch, BodyHeave, and
%   WheelLift (for example, from fcn_CarMesh3D_loadMotionCSV); they are
%   used when present.
%   timeOfDay: 'day' (default) or 'night' (dark scene, light effects on)
if nargin<9
    titleString = '';
end
if nargin<10
    timeOfDay = 'day';
end
flagNight = strcmpi(timeOfDay,'night');

% Scene: ground, grid, and cubes around the area the vehicle drives.
% Cubes are kept at least 7 m from the path and from a fixed camera, so
% the vehicle never drives through one and no camera sits inside one.
pathXY = trajectory.Pose(:,1:2);
margin = 45;
groundExtent = [min(pathXY(:,1))-margin max(pathXY(:,1))+margin min(pathXY(:,2))-margin max(pathXY(:,2))+margin];
keepAwayXY = [pathXY; fcn_INTERNAL_cameraPathXY(cameraSettings, trajectory)];
cubes = fcn_INTERNAL_placeCubes(groundExtent, keepAwayXY, 7);

figureHandle = figure(figNum);
clf;
set(figureHandle,'Color',[0.78 0.86 0.95],'Position',[100 100 figureSize]);
axesHandle = axes('Parent',figureHandle,'Position',[0 0 1 1]);
fcn_CarMesh3D_plotScene(GroundExtent=groundExtent, GridSpacing=4, Cubes=cubes, TimeOfDay=timeOfDay, FigNum=figNum);
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish='glossy', LightEffects=flagNight, FigNum=figNum);
axis(axesHandle,'off');
% Fixed axis limits: the camera moves, the axes do not rescale
axis(axesHandle,[groundExtent -1 25]);
if ~isempty(titleString)
    % A figure-level text box, so the 3D scene can never hide it
    annotation(figureHandle,'textbox',[0.01 0.90 0.9 0.08],'String',titleString, ...
        'FitBoxToText','on','FontWeight','bold','BackgroundColor',[1 1 1],'FaceAlpha',0.6, ...
        'EdgeColor','none','Interpreter','none');
end

Ntimes = length(trajectory.Time);
bodyRoll = fcn_INTERNAL_fieldOrZeros(trajectory, 'BodyRoll', Ntimes, 1);
bodyPitch = fcn_INTERNAL_fieldOrZeros(trajectory, 'BodyPitch', Ntimes, 1);
bodyHeave = fcn_INTERNAL_fieldOrZeros(trajectory, 'BodyHeave', Ntimes, 1);
wheelLift = fcn_INTERNAL_fieldOrZeros(trajectory, 'WheelLift', Ntimes, 4);
for k = 1:Ntimes
    t = trajectory.Time(k);
    if isempty(lightFunction)
        lightStates = trajectory.LightStates(k);
    else
        lightStates = lightFunction(t);
    end
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=trajectory.Pose(k,:), ...
        WheelSpin=trajectory.WheelSpin(k,:), SteerAngle=trajectory.SteerAngle(k,:), ...
        WheelLift=wheelLift(k,:), BodyRoll=bodyRoll(k), BodyPitch=bodyPitch(k), BodyHeave=bodyHeave(k), ...
        LightStates=lightStates, PlotHandles=plotHandles, FigNum=-1);
    fcn_CarMesh3D_updateCamera(cameraSettings, trajectory.Pose(k,:), Time=t, ...
        AxesHandle=axesHandle, FigNum=-1);
    drawnow;
    if flag_saveGif
        fcn_CarMesh3D_saveGifFrame(figureHandle, gifFile, k, ...
            DelayTime=mean(diff(trajectory.Time)), FigNum=-1);
    end
end
end % Ends fcn_INTERNAL_animate

%% fcn_INTERNAL_fieldOrZeros
function values = fcn_INTERNAL_fieldOrZeros(motion, fieldName, Nrows, Ncolumns)
% A field of the motion, or zeros if it does not have one
if isfield(motion, fieldName) && ~isempty(motion.(fieldName))
    values = motion.(fieldName);
else
    values = zeros(Nrows, Ncolumns);
end
end % Ends fcn_INTERNAL_fieldOrZeros

%% fcn_INTERNAL_cameraPathXY
function cameraXY = fcn_INTERNAL_cameraPathXY(cameraSettings, trajectory)
% Where the camera goes on the ground (x, y) during the animation, using
% the same math as fcn_CarMesh3D_updateCamera
if strcmp(cameraSettings.PositionFrame,'world')
    cameraXY = cameraSettings.Position(1:2);
    return;
end
numFrames = length(trajectory.Time);
cameraXY = zeros(numFrames,2);
for ith_frame = 1:numFrames
    position = cameraSettings.Position(:);
    orbitAngle = cameraSettings.OrbitRate*trajectory.Time(ith_frame);
    if orbitAngle~=0
        pivot = cameraSettings.Target(:);
        position = pivot + [cos(orbitAngle) -sin(orbitAngle) 0; sin(orbitAngle) cos(orbitAngle) 0; 0 0 1]*(position - pivot);
    end
    yaw = trajectory.Pose(ith_frame,end); % [x y yaw] or [x y z roll pitch yaw]
    cameraXY(ith_frame,:) = trajectory.Pose(ith_frame,1:2) + ([cos(yaw) -sin(yaw); sin(yaw) cos(yaw)]*position(1:2))';
end
end % Ends fcn_INTERNAL_cameraPathXY

%% fcn_INTERNAL_placeCubes
function cubes = fcn_INTERNAL_placeCubes(groundExtent, keepAwayXY, clearance)
% Cubes on a 12 m grid over the ground, skipping any spot within
% clearance meters of the given points (the path and fixed cameras).
% Sizes and colors vary so the cubes are easy to tell apart.
spacing = 12;
[gridX, gridY] = meshgrid(groundExtent(1)+6:spacing:groundExtent(2)-6, groundExtent(3)+6:spacing:groundExtent(4)-6);
candidates = [gridX(:) gridY(:)];
% Shift every other row, so cubes do not line up in rows
candidates(:,1) = candidates(:,1) + 4*mod(round((candidates(:,2)-groundExtent(3))/spacing),2);
distances = min(sqrt((candidates(:,1) - keepAwayXY(:,1)').^2 + (candidates(:,2) - keepAwayXY(:,2)').^2), [], 2);
candidates = candidates(distances > clearance, :);
numCubes = size(candidates,1);
sizes = 1.5 + mod((1:numCubes)',3)*0.75;
colors = mod((1:numCubes)'-1, 6) + 1;
cubes = [candidates sizes colors];
end % Ends fcn_INTERNAL_placeCubes

%% fcn_INTERNAL_signalSequence
function lightStates = fcn_INTERNAL_signalSequence(t)
% Left signal, lane change, hazards while stopped, then backing up
blinkOn = mod(t, 0.8) < 0.4;
lightStates = struct('Headlights','low','Tail','on','Running',true, ...
    'TurnLeft',false,'TurnRight',false,'Backup',false);
if t < 7
    lightStates.TurnLeft = blinkOn;                 % Signal, then change lanes
elseif t < 10
    lightStates.TurnLeft = blinkOn;                 % Hazards: both sides
    lightStates.TurnRight = blinkOn;
    lightStates.Tail = 'brake';
else
    lightStates.Backup = true;                      % Backing up
end
end % Ends fcn_INTERNAL_signalSequence

%% fcn_INTERNAL_choose
function value = fcn_INTERNAL_choose(condition, valueIfTrue, valueIfFalse)
% A one-line "if" for building light states
if condition
    value = valueIfTrue;
else
    value = valueIfFalse;
end
end % Ends fcn_INTERNAL_choose

%% fcn_INTERNAL_prepareVehicle
function [vehicleMesh, vehicleSpec] = fcn_INTERNAL_prepareVehicle
% Builds the downloaded 2010 Prius with corrected light labels, or the
% sample car if the model (or Blender) is not available
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(priusFiles.ParametersFile, ...
    BodyColor=[0.05 0.20 0.60], FigNum=-1);
modelFile = fullfile(priusFiles.ModelFolder,'source','2010 Toyota Prius.glb');
try
    vehicleMesh = fcn_CarMesh3D_importMesh(modelFile, FigNum=-1);
    vehicleMesh.Name = '2010 Toyota Prius';
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+z', ForwardAxis='+x', FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules={'17in','wheel'; 'color_notint','trim'}, ...
        UseMaterialColors=false, PartColors={'body',vehicleSpec.BodyColor; 'glass',[0.30 0.30 0.32]; 'trim',[0.02 0.02 0.02]}, ...
        GlassAlpha=0.6, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference='mirrors', FigNum=-1);

    % Light labels for this model (found with the interactive editor,
    % then written as regions so they are repeatable). Regions are in
    % meters, origin on the ground below the rear axle; BothSides
    % mirrors each region to the other side of the car.
    edits = {};
    edits{end+1} = struct('Name','headlight housings and lenses', 'Region',[2.90 3.45 0.45 0.82 0.55 0.82], ...
        'BothSides',true, 'Material','color_notint|glass_ex', 'LightType','headlight');
    edits{end+1} = struct('Name','front turn signals', 'Region',[3.30 3.50 0.65 0.80 0.25 0.47], ...
        'BothSides',true, 'Material','color_notint', 'LightType','turnsignal');
    edits{end+1} = struct('Name','tail lights (upper part)', 'Region',[-0.80 -0.45 0.55 0.80 0.95 1.12], ...
        'BothSides',true, 'Material','color_notint', 'LightType','tail');
    edits{end+1} = struct('Name','rear turn signals (middle)', 'Region',[-0.80 -0.45 0.55 0.80 0.82 0.95], ...
        'BothSides',true, 'Material','color_notint', 'LightType','turnsignal');
    edits{end+1} = struct('Name','backup lights (lower part)', 'Region',[-0.80 -0.45 0.55 0.80 0.65 0.82], ...
        'BothSides',true, 'Material','color_notint', 'LightType','backup');
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);
catch ME
    fprintf(1,'Could not build the Prius model (%s).\nUsing the built-in sample car instead.\n', ME.message);
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, BodyColor=vehicleSpec.BodyColor, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
end
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, TargetFaces=size(vehicleMesh.Faces,1), FigNum=-1);
end % Ends fcn_INTERNAL_prepareVehicle
