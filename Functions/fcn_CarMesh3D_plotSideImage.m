function overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, options)
% fcn_CarMesh3D_plotSideImage
% Shows a side-view photo (or drawing) of the real vehicle on a vertical
% plane through the vehicle's centerline, scaled and placed so its wheel
% centers land on the mesh's wheel centers. Looking from the side, the
% outline of the mesh can then be checked against the real vehicle: the
% roof line, hood, bumpers, windows, and wheel arches.
%
% HOW THE PHOTO IS PLACED. You give the pixel positions of the rear and
% front wheel centers in the photo (or click them). Those two points must
% land on the two axles of the mesh, at wheel-center height:
%
%       rear wheel center  ->  (x = rear axle,  z = tire radius)
%       front wheel center ->  (x = front axle, z = tire radius)
%
% Two points fix the scale (meters per pixel = wheelbase / pixel distance
% between the wheel centers), a small rotation (if the photo is tilted),
% and the position. If the vehicle faces LEFT in the photo, the photo is
% flipped left-to-right first, so the vehicle's front always points to +X.
%
% WHY ONE PLANE IS ENOUGH FOR BOTH SIDES. Seen from the other side, a
% picture on a plane appears mirrored, just as a vehicle's left side is
% (nearly) the mirror image of its right side. So the photo lines up from
% both sides. Only lettering and badges read backwards from the far side.
%
% The plane sits inside the vehicle, so the vehicle is drawn partly see-
% through (VehicleAlpha). Alternatively, move the plane outside the
% vehicle (PlaneY), and make the photo see-through (ImageAlpha).
%
% FORMAT:
%
%       overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh,...
%           (WheelCentersPixels=[colRear rowRear; colFront rowFront]),...
%           (PlaneY=y), (ImageAlpha=alpha), (VehicleAlpha=alpha),...
%           (ShowVehicle=flag), (SetView=flag), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      sideImage: the side-view picture, as an image file name (any
%      format imread reads, such as .jpg or .png) or an image array (H x
%      W x 3 color, H x W gray).
%
%      vehicleMesh: a mesh fitted with fcn_CarMesh3D_fitMeshToSpec, which
%      gives the axle positions (AxleX) and the tire diameter
%      (VehicleSpec.TireDiameter).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      WheelCentersPixels: [colRear rowRear; colFront rowFront], the pixel
%      positions (column, row; row 1 is the top of the image) of the rear
%      and front wheel centers in the picture. Default [] opens the
%      picture so you can click the two wheel centers (rear first); the
%      values are then printed so you can paste them into your script.
%
%      PlaneY: where the picture plane is, along Y (left), in meters.
%      Default 0, the vehicle centerline. Use a value outside the
%      vehicle, such as -1.2 (beyond the right side), to put the picture
%      in front of the mesh when looking from that side.
%
%      ImageAlpha: how solid the picture is, from 0 (clear) to 1 (solid,
%      the default).
%
%      VehicleAlpha: how solid the vehicle is drawn, from 0 to 1. Default
%      0.4, so the picture shows through.
%
%      ShowVehicle: true (default) to also draw the vehicle with
%      fcn_CarMesh3D_plotVehicle; false to draw only the picture (for
%      example, into an axes where the vehicle is already drawn).
%
%      SetView: true (default) to look from the vehicle's right side
%      (-Y), with no perspective (orthographic), so the outlines can be
%      compared exactly. Rotate the view to see the other side.
%
%      FigNum: a figure number to draw into. If empty or omitted, draws
%      into the current figure. If set to -1, input checking is skipped
%      (WheelCentersPixels must then be given).
%
% OUTPUTS:
%
%      overlayHandles: a structure with fields
%           Image: the surface showing the picture
%           Vehicle: the plot handles from fcn_CarMesh3D_plotVehicle (or [])
%           Corners: 4 x 3 corners of the picture in the vehicle frame
%               (top-left, top-right, bottom-left, bottom-right)
%           MetersPerPixel: the scale of the picture
%           TiltDegrees: how much the picture was rotated to level it
%           FlippedImage: true if the picture was flipped left-to-right
%               (the vehicle faced left in it)
%           WheelCentersPixels: the wheel centers used
%           PixelToVehicle: a function that maps [col row] pixel points
%               (N x 2, in the original picture) to [x z] in meters
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (if ShowVehicle is true)
%
% EXAMPLES:
%
%       overlayHandles = fcn_CarMesh3D_plotSideImage('myPriusSide.jpg', vehicleMesh, ...
%           WheelCentersPixels=[1210 655; 395 652], FigNum=1);
%
%       See the script: script_CarMesh3D_plotSideImage.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotSideImage
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotSideImage
%   % * The rear wheel center uses the rear tires' radius
%   %   % (VehicleSpec.TireDiameterRear), for different front and rear tires

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotSideImage
%   % * Front and top views (overlay on the other two planes)
%   % * Make the background of the picture see-through (by color)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    sideImage
    vehicleMesh
    options.WheelCentersPixels = []  % [colRear rowRear; colFront rowFront]; [] to click
    options.PlaneY = 0               % Y of the picture plane [m]; 0 is the centerline
    options.ImageAlpha = 1           % 0 clear to 1 solid
    options.VehicleAlpha = 0.4       % 0 clear to 1 solid
    options.ShowVehicle = true       % Also draw the vehicle?
    options.SetView = true           % Look from the right side, orthographic?
    options.FigNum = []              % Figure to draw into; [] for current figure, -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the sideImage input
        if ischar(sideImage) || isstring(sideImage)
            if ~isfile(sideImage)
                error('Image file not found: %s', char(sideImage));
            end
        elseif ~(isnumeric(sideImage) || islogical(sideImage)) || ~any(ndims(sideImage)==[2 3])
            error('sideImage must be an image file name or an image array');
        end

        % Check the vehicleMesh input: it must be fitted
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'AxleX') || any(~isfinite(vehicleMesh.AxleX)) || ...
                ~isfield(vehicleMesh,'VehicleSpec') || ~isfield(vehicleMesh.VehicleSpec,'TireDiameter') || isempty(vehicleMesh.VehicleSpec.TireDiameter)
            error('vehicleMesh must be fitted with fcn_CarMesh3D_fitMeshToSpec (it needs AxleX and VehicleSpec.TireDiameter)');
        end

        % Check the WheelCentersPixels input
        if ~isempty(options.WheelCentersPixels)
            if ~isnumeric(options.WheelCentersPixels) || ~isequal(size(options.WheelCentersPixels),[2 2]) || any(~isfinite(options.WheelCentersPixels(:)))
                error('WheelCentersPixels must be [colRear rowRear; colFront rowFront]');
            end
            if norm(diff(options.WheelCentersPixels)) < 1
                error('The two wheel centers in WheelCentersPixels must be different points');
            end
        end

        % Check the numeric options
        if ~isnumeric(options.PlaneY) || ~isscalar(options.PlaneY) || ~isfinite(options.PlaneY)
            error('PlaneY must be a number of meters');
        end
        alphaNames = {'ImageAlpha','VehicleAlpha'};
        for ith_name = 1:2
            thisValue = options.(alphaNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<0 || thisValue>1
                error('%s must be a number from 0 to 1', alphaNames{ith_name});
            end
        end
    end
end

% Which figure to draw into? Drawing is the purpose of this function, so
% it always draws: into the given figure, or else into the current figure.
figNum = []; % Default is to use the current figure
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%
% Read the picture as an H x W x 3 color image
if ischar(sideImage) || isstring(sideImage)
    [imageData, colorMap] = imread(char(sideImage));
    if ~isempty(colorMap)
        imageData = ind2rgb(imageData, colorMap);
    end
else
    imageData = sideImage;
end
if size(imageData,3)==1
    imageData = repmat(imageData,1,1,3);
end
imageData = imageData(:,:,1:3); % Drop any alpha channel
imageHeight = size(imageData,1);
imageWidth = size(imageData,2);

%%%%
% Wheel centers in the picture (click them if not given)
wheelPixels = options.WheelCentersPixels;
if isempty(wheelPixels)
    wheelPixels = fcn_INTERNAL_clickWheelCenters(imageData);
end

%%%%
% If the vehicle faces left in the picture, flip the picture left-to-right
% so its front points to +X. Columns c become (W + 1 - c).
flagFlipped = wheelPixels(2,1) < wheelPixels(1,1);
workingPixels = wheelPixels;
if flagFlipped
    imageData = flip(imageData, 2);
    workingPixels(:,1) = imageWidth + 1 - wheelPixels(:,1);
end

%%%%
% Two-point fit: picture points [col -row] (so "up" is positive) to
% vehicle points [x z]. A scale and a rotation (a similarity transform):
%       [x z] = scale * R(angle) * ([col -row] - rearPoint) + rearTarget
tireRadius = vehicleMesh.VehicleSpec.TireDiameter/2;
tireRadiusRear = tireRadius;                                      % (different front and rear tires?)
if isfield(vehicleMesh.VehicleSpec,'TireDiameterRear') && ~isempty(vehicleMesh.VehicleSpec.TireDiameterRear)
    tireRadiusRear = vehicleMesh.VehicleSpec.TireDiameterRear/2;
end
rearTarget = [vehicleMesh.AxleX(1) tireRadiusRear];
frontTarget = [vehicleMesh.AxleX(2) tireRadius];
rearPoint = [workingPixels(1,1) -workingPixels(1,2)];
frontPoint = [workingPixels(2,1) -workingPixels(2,2)];
pictureDirection = frontPoint - rearPoint;
targetDirection = frontTarget - rearTarget;
metersPerPixel = norm(targetDirection)/norm(pictureDirection);
rotationAngle = atan2(targetDirection(2),targetDirection(1)) - atan2(pictureDirection(2),pictureDirection(1));
rotationMatrix = [cos(rotationAngle) -sin(rotationAngle); sin(rotationAngle) cos(rotationAngle)];
workingToVehicle = @(colRow) (metersPerPixel*(rotationMatrix*([colRow(:,1) -colRow(:,2)] - rearPoint)'))' + rearTarget;

% The same mapping, for pixels of the ORIGINAL (unflipped) picture
if flagFlipped
    pixelToVehicle = @(colRow) workingToVehicle([imageWidth + 1 - colRow(:,1), colRow(:,2)]);
else
    pixelToVehicle = workingToVehicle;
end

%%%%
% The picture's corners (pixel edges are half a pixel outside the
% centers) in the vehicle frame: top-left, top-right, bottom-left,
% bottom-right
cornerPixels = [0.5 0.5; imageWidth+0.5 0.5; 0.5 imageHeight+0.5; imageWidth+0.5 imageHeight+0.5];
cornerXZ = workingToVehicle(cornerPixels);
corners = [cornerXZ(:,1), options.PlaneY*ones(4,1), cornerXZ(:,2)];

%%%%
% Select the figure and axes, without clearing them
if isempty(figNum)
    figureHandle = gcf;
else
    figureHandle = figure(figNum);
end
axesHandle = get(figureHandle,'CurrentAxes');
if isempty(axesHandle)
    axesHandle = axes('Parent',figureHandle);
end
hold(axesHandle,'on');

%%%%
% The vehicle, drawn partly see-through
vehicleHandles = [];
if options.ShowVehicle
    vehicleHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=-1);
    for ith_patch = 1:length(vehicleHandles.Patches)
        thisPatch = vehicleHandles.Patches{ith_patch};
        if isnumeric(thisPatch.FaceAlpha)
            thisPatch.FaceAlpha = options.VehicleAlpha*thisPatch.FaceAlpha;
        end
    end
end

%%%%
% The picture, as a flat surface with the picture "painted" on it
% (texture mapping). Row 1 of the picture goes along the top edge.
imageSurface = surface(axesHandle, ...
    [corners(1,1) corners(2,1); corners(3,1) corners(4,1)], ...
    [corners(1,2) corners(2,2); corners(3,2) corners(4,2)], ...
    [corners(1,3) corners(2,3); corners(3,3) corners(4,3)], ...
    'CData',imageData,'FaceColor','texturemap','EdgeColor','none', ...
    'FaceLighting','none','FaceAlpha',options.ImageAlpha, ...
    'DisplayName','Side-view picture','HandleVisibility','off');

%%%%
% Look from the right side (-Y), without perspective
if options.SetView
    view(axesHandle,0,0);
    camproj(axesHandle,'orthographic');
    axis(axesHandle,'equal');
    xlabel(axesHandle,'X [m] (forward)');
    zlabel(axesHandle,'Z [m] (up)');
end

overlayHandles = struct;
overlayHandles.Image = imageSurface;
overlayHandles.Vehicle = vehicleHandles;
overlayHandles.Corners = corners;
overlayHandles.MetersPerPixel = metersPerPixel;
overlayHandles.TiltDegrees = rad2deg(rotationAngle);
overlayHandles.FlippedImage = flagFlipped;
overlayHandles.WheelCentersPixels = wheelPixels;
overlayHandles.PixelToVehicle = pixelToVehicle;

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (Drawing is the purpose of this function, so there is no extra plot)

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_clickWheelCenters
function wheelPixels = fcn_INTERNAL_clickWheelCenters(imageData)
% Shows the picture and asks for two clicks: the rear wheel center, then
% the front wheel center. Prints the result for pasting into a script.
clickFigure = figure('Name','Click the wheel centers','NumberTitle','off');
image(imageData);
axis image;
hold on;
title({'Click the center of the REAR wheel, then the center of the FRONT wheel', ...
    '(zoom in first with the toolbar if needed; press Enter when zoomed)'});
wheelPixels = zeros(2,2);
labels = {'rear','front'};
for ith_click = 1:2
    [clickCol, clickRow] = ginput(1);
    wheelPixels(ith_click,:) = [clickCol clickRow];
    plot(clickCol, clickRow, 'r+', 'MarkerSize', 20, 'LineWidth', 2);
    text(clickCol, clickRow, ['  ' labels{ith_click}], 'Color', 'r', 'FontWeight', 'bold');
end
drawnow;
fprintf(1,'Wheel centers clicked. To repeat this without clicking, use:\n');
fprintf(1,'    WheelCentersPixels=[%.1f %.1f; %.1f %.1f]\n', wheelPixels');
pause(0.5);
close(clickFigure);
end % Ends fcn_INTERNAL_clickWheelCenters
