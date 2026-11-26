% script_test_fcn_CarMesh3D_plotSideImage.m
% Tests fcn_CarMesh3D_plotSideImage
% Shows a side-view picture on the vehicle's centerline plane, placed so
% the picture's wheel centers land on the mesh's axles, for checking the
% mesh's outline against the real vehicle.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotSideImage
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotSideImage
%   % * Renamed from script_CarMesh3D_plotSideImage: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotSideImage
%   % * Add a test with a real photo of the 2013 Prius (license permitting)


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

%% DEMO case: A side view of the mesh itself lines up with the mesh
figNum = 10001;
titleString = sprintf('DEMO case: A side view of the mesh itself lines up with the mesh');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% A "photo" made by drawing the fitted mesh from the side, with the
% pixel positions of its wheel centers worked out from the drawing. A
% real photo is used the same way, with its wheel centers clicked.
vehicleMesh = fcn_INTERNAL_fittedSample;
[sideImage, wheelPixels] = fcn_INTERNAL_renderSideView(vehicleMesh);
figure(figNum); clf;
overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, ...
    WheelCentersPixels=wheelPixels, FigNum=figNum);
title(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(overlayHandles));
assert(isgraphics(overlayHandles.Image));
assert(isstruct(overlayHandles.Vehicle));

% Check variable sizes
assert(isequal(size(overlayHandles.Corners),[4 3]));

% Check variable values: the wheel centers land on the axles
tireRadius = vehicleMesh.VehicleSpec.TireDiameter/2;
mappedWheels = overlayHandles.PixelToVehicle(wheelPixels);
assert(max(abs(mappedWheels - [vehicleMesh.AxleX(:) [tireRadius; tireRadius]]),[],'all') < 1e-9);
assert(~overlayHandles.FlippedImage);
assert(abs(overlayHandles.TiltDegrees) < 1);
% The picture plane is on the centerline
assert(all(overlayHandles.Corners(:,2)==0));
% The vehicle is drawn see-through
assert(overlayHandles.Vehicle.Patches{1}.FaceAlpha <= 0.4);

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

%% TEST case: A picture with the vehicle facing left is flipped
figNum = 20001;
titleString = sprintf('TEST case: A picture with the vehicle facing left is flipped');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_fittedSample;
% A plain picture with two dark "wheels": the front wheel is on the LEFT
wheelPixels = [650 220; 150 220]; % [rear; front]
sideImage = fcn_INTERNAL_twoWheelPicture(300, 800, wheelPixels, 60);
overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, ...
    WheelCentersPixels=wheelPixels, FlagShowVehicle=false, FigNum=figNum);
title(titleString, 'Interpreter','none');

% Check variable values
assert(overlayHandles.FlippedImage);
wheelbase = diff(vehicleMesh.AxleX);
assert(abs(overlayHandles.MetersPerPixel - wheelbase/500) < 1e-12);
tireRadius = vehicleMesh.VehicleSpec.TireDiameter/2;
mappedWheels = overlayHandles.PixelToVehicle(wheelPixels);
assert(max(abs(mappedWheels - [vehicleMesh.AxleX(:) [tireRadius; tireRadius]]),[],'all') < 1e-9);
% After flipping, the picture's left edge (top-left corner) is at the rear
assert(overlayHandles.Corners(1,1) < overlayHandles.Corners(2,1));
assert(isempty(overlayHandles.Vehicle));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: A tilted picture is leveled
figNum = 20002;
titleString = sprintf('TEST case: A tilted picture is leveled');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

wheelPixels = [100 200; 600 250]; % The front wheel is 50 pixels lower
sideImage = fcn_INTERNAL_twoWheelPicture(400, 700, wheelPixels, 50);
overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, ...
    WheelCentersPixels=wheelPixels, FlagShowVehicle=false, FigNum=figNum);
title(titleString, 'Interpreter','none');

% Check variable values: rotated by atan(50/500), and both wheels level
assert(abs(overlayHandles.TiltDegrees - atand(50/500)) < 1e-9);
mappedWheels = overlayHandles.PixelToVehicle(wheelPixels);
assert(abs(diff(mappedWheels(:,2))) < 1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Picture plane outside the vehicle, see-through
figNum = 20003;
titleString = sprintf('TEST case: Picture plane outside the vehicle, see-through');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[sideImage, wheelPixels] = fcn_INTERNAL_renderSideView(vehicleMesh);
figure(figNum); clf;
overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, WheelCentersPixels=wheelPixels, ...
    PlaneY=-1.5, ImageAlpha=0.5, VehicleAlpha=1, FigNum=figNum);
title(titleString, 'Interpreter','none');

% Check variable values
assert(all(overlayHandles.Corners(:,2)==-1.5));
assert(overlayHandles.Image.FaceAlpha==0.5);

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

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); clf;

wheelPixels = [650 220; 150 220];
sideImage = fcn_INTERNAL_twoWheelPicture(300, 800, wheelPixels, 60);
overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, ...
    WheelCentersPixels=wheelPixels, FlagShowVehicle=false, FigNum=-1);

% Check variable values: same placement as with input checks
assert(overlayHandles.FlippedImage);
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

%% FAIL case: The mesh is not fitted (no axle positions)
if 1==0
    fcn_CarMesh3D_plotSideImage(zeros(10,10,3), fcn_CarMesh3D_fillSampleMesh(FigNum=-1), WheelCentersPixels=[1 1; 5 1]);
end

%% FAIL case: The same pixel for both wheels
if 1==0
    fcn_CarMesh3D_plotSideImage(zeros(10,10,3), fcn_INTERNAL_fittedSample, WheelCentersPixels=[5 5; 5 5]);
end

%% INTERACTIVE case: click the wheel centers (needs a person)
if 1==0
    fcn_CarMesh3D_plotSideImage(fcn_INTERNAL_twoWheelPicture(300, 800, [650 220; 150 220], 60), ...
        fcn_INTERNAL_fittedSample, FigNum=1);
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

%% fcn_INTERNAL_fittedSample
function vehicleMesh = fcn_INTERNAL_fittedSample
% The built-in sample car, prepared and fitted to the sedan preset
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_fittedSample

%% fcn_INTERNAL_renderSideView
function [sideImage, wheelPixels] = fcn_INTERNAL_renderSideView(vehicleMesh)
% Draws the vehicle from the right side, without perspective, filling
% the figure exactly, and captures it as a picture. The wheel-center
% pixels follow from the axis limits.
figureSize = [800 300];
renderFigure = figure('Position',[100 100 figureSize],'Color',[1 1 1]);
renderAxes = axes('Parent',renderFigure,'Position',[0 0 1 1]);
fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish='glossy', FigNum=-1);
view(renderAxes,0,0);
camproj(renderAxes,'orthographic');
axis(renderAxes,'off');
% Limits with the same shape as the figure, so 1 m is the same number of
% pixels across and up
xLimits = [min(vehicleMesh.Vertices(:,1))-0.3, max(vehicleMesh.Vertices(:,1))+0.3];
zSpan = diff(xLimits)*figureSize(2)/figureSize(1);
zLimits = [-0.2, -0.2 + zSpan];
set(renderAxes,'XLim',xLimits,'ZLim',zLimits,'YLim',[-2 2],'DataAspectRatio',[1 1 1]);
drawnow;
frame = getframe(renderFigure);
sideImage = frame.cdata;
close(renderFigure);
% Pixel positions of the wheel centers (the captured size may differ from
% figureSize on high-resolution screens, so use the captured size)
imageHeight = size(sideImage,1);
imageWidth = size(sideImage,2);
tireRadius = vehicleMesh.VehicleSpec.TireDiameter/2;
wheelX = vehicleMesh.AxleX(:);
wheelPixels = [(wheelX - xLimits(1))/diff(xLimits)*imageWidth + 0.5, ...
    (zLimits(2) - tireRadius)/diff(zLimits)*imageHeight + 0.5 + [0; 0]];
end % Ends fcn_INTERNAL_renderSideView

%% fcn_INTERNAL_twoWheelPicture
function sideImage = fcn_INTERNAL_twoWheelPicture(imageHeight, imageWidth, wheelPixels, wheelRadiusPixels)
% A light picture with two dark disks ("wheels") and a blue box ("body")
[colGrid, rowGrid] = meshgrid(1:imageWidth, 1:imageHeight);
sideImage = 0.9*ones(imageHeight, imageWidth, 3);
bodyRows = rowGrid > min(wheelPixels(:,2)) - 2.2*wheelRadiusPixels & rowGrid < max(wheelPixels(:,2));
bodyCols = colGrid > min(wheelPixels(:,1)) - 1.5*wheelRadiusPixels & colGrid < max(wheelPixels(:,1)) + 1.5*wheelRadiusPixels;
flagBody = bodyRows & bodyCols;
blueBody = cat(3, 0.1*flagBody, 0.25*flagBody, 0.7*flagBody);
sideImage = sideImage.*~flagBody + blueBody;
for ith_wheel = 1:2
    flagWheel = (colGrid - wheelPixels(ith_wheel,1)).^2 + (rowGrid - wheelPixels(ith_wheel,2)).^2 < wheelRadiusPixels^2;
    sideImage = sideImage.*~flagWheel + 0.1*flagWheel;
end
end % Ends fcn_INTERNAL_twoWheelPicture
