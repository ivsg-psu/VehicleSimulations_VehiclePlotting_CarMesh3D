%% Introduction to and Purpose of the Code
% This is the explanation of the code that can be found by running
%       script_demo_CarMesh3D.m
% This is a script to demonstrate the functions within the CarMesh3D code
% library.
%
% If you have questions or comments, please contact Sean Brennan at
% sbrennan@psu.edu
%
% The purpose of the code is to produce 3D meshes of production vehicles
% that look right when plotted and animated in MATLAB. The goal is not
% photorealism: meshes are kept sparse (a few thousand faces) so that
% plots and animations stay fast, while still having
%   * the correct length, width, height, wheelbase, track, and tire size
%     for the vehicle, taken from published data,
%   * outward-pointing surface normals, so lighting looks right,
%   * vehicle-like colors, with see-through glass.
%
% Every mesh, whatever its source, goes through the same steps:
%
%   1. Vehicle spec   fcn_CarMesh3D_loadVehicleSpec or fcn_CarMesh3D_fillVehicleSpec
%   2. Shape source   fcn_CarMesh3D_importMesh (downloaded OBJ/STL/FBX/glTF) or
%                     fcn_CarMesh3D_fillSampleMesh (built-in sample)
%   3. Normalize      fcn_CarMesh3D_normalizeMesh  (X forward, Y left, Z up, meters)
%   4. Label parts    fcn_CarMesh3D_labelParts     (body, glass, wheels, lights, trim)
%   5. Fit to spec    fcn_CarMesh3D_fitMeshToSpec  (exact wheelbase, track, tires)
%   6. Simplify       fcn_CarMesh3D_simplifyMesh   (face budget, outward normals)
%   7. Validate       fcn_CarMesh3D_validateMesh   (table of target vs. measured)
%                     fcn_CarMesh3D_plotSideImage  (outline vs. a side photo)
%   8. Plot / animate fcn_CarMesh3D_plotVehicle    (fast pose updates)

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * First prototype of the library (drafted with Claude)
%   % * Core functions: fillVehicleSpec, loadVehicleSpec, fillSampleMesh,
%   %   % importMesh, normalizeMesh, labelParts, fitMeshToSpec,
%   %   % simplifyMesh, validateMesh, plotVehicle
%   % * Each core function has a matching script_test_fcn_CarMesh3D_<name> test
%   %   % script in the Functions folder
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * Added a 0.05 s pause after each animation frame (first MATLAB run)
%   % * Added FBX, glTF, GLB, and .blend import through Blender
%   %   % (fcn_CarMesh3D_convertToOBJ)
%   % * The starting example is now a downloaded 2010 Prius model (GLB),
%   %   % fitted to the 2013 Prius spec; falls back to the sample car
%   % * Added Steps 10-11: a full-detail variation with custom part colors
%   %   % (blue body, nearly opaque gray glass, black trim), compared side
%   %   % by side with the reduced version
%   % * Steps 11-12 show the Finish (glossy) and ShowEdges/EdgeColor options
%   % * Added Step 13: check the outline against a side-view picture
%   %   % (fcn_CarMesh3D_plotSideImage)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * The Prius model is loaded again (the Acura NSX model had been put
%   %   % in its place while the rest of the steps still used the Prius
%   %   % name, part rules, axes, and spec, so the result looked broken)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * Add blueprint (side/front/top silhouette) extrusion as a shape source
%   % * Add a parametric body template as a fallback shape source
%   % * Decide on DebugTools dependency and the standard IVSG installer


%% Make sure we are running out of root directory
st = dbstack;
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% START OF STANDARD INSTALLER CODE %%%%%%%%%
% This prototype has no external dependencies, so the "installer" only
% adds this project's own folders to the path. It does not download or
% change anything outside this folder.

% Do we need to set up the work space?
if ~exist('flag_CarMesh3D_Folders_Initialized','var') || 0==flag_CarMesh3D_Folders_Initialized
	fcn_INTERNAL_setupWorkspace;
	flag_CarMesh3D_Folders_Initialized = 1;
else
	fprintf(1,'Skipping installs as it appears this was completed previously in this session.\n');
end

%%%% END OF STANDARD INSTALLER CODE %%%%%%%%%

%% Start of Demo Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____ _             _            __   _____                          _____          _
%  / ____| |           | |          / _| |  __ \                        / ____|        | |
% | (___ | |_ __ _ _ __| |_    ___ | |_  | |  | | ___ _ __ ___   ___   | |     ___   __| | ___
%  \___ \| __/ _` | '__| __|  / _ \|  _| | |  | |/ _ \ '_ ` _ \ / _ \  | |    / _ \ / _` |/ _ \
%  ____) | || (_| | |  | |_  | (_) | |   | |__| |  __/ | | | | | (_) | | |___| (_) | (_| |  __/
% |_____/ \__\__,_|_|   \__|  \___/|_|   |_____/ \___|_| |_| |_|\___/   \_____\___/ \__,_|\___|
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Start%20of%20Demo%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Welcome to the demo code for the CarMesh3D library!')

%% Step 1: The vehicle specification
% Every mesh is scaled to agree with published data for the vehicle. The
% data can come from an IVSG vehicleParameters .mat file:

figNum = 1;
% (fcn_CarMesh3D_findVehicleFiles finds a vehicle's folder by its ID,
% wherever it is filed under Data\BodyStyles)
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
specFile = priusFiles.ParametersFile;
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(specFile, BodyColor=[0.75 0.76 0.78], FigNum=figNum);
disp(vehicleSpec);

%%
% or be typed in directly (values here are examples only):

figNum = 2;
exampleSpec = fcn_CarMesh3D_fillVehicleSpec(...
    Name='Example compact car',...
    OverallLength=4.55, OverallWidth=1.80, OverallHeight=1.42,...
    Wheelbase=2.70, TrackFront=1.55, TireSize='205/55R16',...
    FrontOverhang=0.88, Source='Example values',...
    FigNum=figNum); 

%% Step 2: A shape source
% The starting example is a free low-poly 2010 Toyota Prius model (a .glb
% file) in Data\BodyStyles\Liftback\2013_Toyota_Prius_Four\model. It is close in shape to the 2013 Prius
% spec loaded above. GLB and FBX files are converted to OBJ by Blender
% (free, blender.org) the first time, then the converted file is reused.
%
% Good places to look for other models: Sketchfab (filter by
% "Downloadable"; check each license), Kenney.nl, OpenGameArt.org, and
% itch.io (search "low poly car").
%
% If the model or Blender is not available, the built-in sample car is
% used instead, so the rest of the demo still runs.

figNum = 3;
modelFile = fullfile(priusFiles.ModelFolder,'source','2010 Toyota Prius.glb');


flag_useDownloadedModel = exist(modelFile,'file')==2;
if flag_useDownloadedModel
    try
        vehicleMesh = fcn_CarMesh3D_importMesh(modelFile, ...
            License='(fill in from the model''s download page)', FigNum=figNum);
        vehicleMesh.Name = '2010 Toyota Prius (downloaded model)';
    catch ME
        fprintf(1,'Could not import %s:\n  %s\nUsing the built-in sample car instead.\n', modelFile, ME.message);
        flag_useDownloadedModel = false;
    end
end
if ~flag_useDownloadedModel
    % The sample's "messy" style imitates a downloaded file: millimeters,
    % Y up, Z forward, offset from the origin
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, Style='messy', FigNum=figNum);
end

%% Step 3: Normalize into the vehicle frame
% Tell the function which file axis points up and which points to the
% front of the car. ALWAYS check the plot: the red arrow (X) must point
% to the front bumper (headlights). Part names in downloaded files can be
% misleading, so trust the picture.

figNum = 4;
if flag_useDownloadedModel
    % Blender writes Z up. For this Prius model, the front is toward +X.
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+z', ForwardAxis='+x', FigNum=figNum);
else
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+y', ForwardAxis='+z', FigNum=figNum);
end

%% Step 4: Label the parts
% Parts are found from material and group names. When the names are not
% recognized, add rules: in this model the wheels are named '17in' and
% the unpainted parts (bumper trim, mirrors' caps) use 'color_notint'.
% This model's colors come from texture images, which CarMesh3D does not
% read, so use one color per part (UseMaterialColors=false) with the
% spec's body color.

figNum = 5;
if flag_useDownloadedModel
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, ...
        PartRules={'17in','wheel'; 'color_notint','trim'}, ...
        BodyColor=vehicleSpec.BodyColor, UseMaterialColors=false, FigNum=figNum);
else
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, BodyColor=vehicleSpec.BodyColor, FigNum=figNum);
end

%% Step 5: Fit to the specification
% The body is scaled to the length, width, and height, then stretched so
% the axles land at the true wheelbase and the body bottom at the true
% ground clearance. Wheels are moved as rigid objects to the true track
% and scaled to the true tire size.
%
% Width: published widths usually EXCLUDE the mirrors. This model's
% mirrors are part of the body, so its full width is fitted to the spec's
% width WITH mirrors (WidthReference='mirrors').

figNum = 6;
if flag_useDownloadedModel
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference='mirrors', FigNum=figNum);
else
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=figNum);
end

%% Step 6: Simplify and fix normals
% Choose a face budget. About 2000 to 5000 faces animates smoothly.

figNum = 7;
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, TargetFaces=3000, FigNum=figNum);

%% Step 7: Validate against the specification
% This table is a good thing to include in a report.

figNum = 8;
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=figNum);
disp(validationTable);

%% Step 8: Save to the vehicle library
% One .mat file per vehicle, holding the finished mesh (which also keeps
% a copy of its spec in vehicleMesh.VehicleSpec).

flag_saveToLibrary = 0; % Set to 1 to save
if flag_saveToLibrary
    libraryFile = fullfile('Data', ['CarMesh3D_' regexprep(vehicleSpec.Name,'\W','') '.mat']); %#ok<UNRCH>
    save(libraryFile,'vehicleMesh');
    fprintf(1,'Saved: %s\n', libraryFile);
end

%% Step 9: Plot and animate
% Plot once, then move the vehicle by updating only its pose. This is
% much faster than redrawing the mesh each frame.

figNum = 9;
figure(figNum); clf;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
axis([-25 25 -25 25 0 4]);
title(sprintf('%s driving a figure eight', vehicleSpec.Name), 'Interpreter','none');

numFrames = 300;
frameDelaySeconds = 0.05; % Pause after each frame so the motion is visible (0 for maximum speed)
timeValues = linspace(0, 2*pi, numFrames);
xValues = 20*sin(timeValues);
yValues = 10*sin(2*timeValues);
yawValues = atan2(gradient(yValues), gradient(xValues));
for ith_frame = 1:numFrames
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, ...
        Pose=[xValues(ith_frame) yValues(ith_frame) yawValues(ith_frame)], ...
        PlotHandles=plotHandles, FigNum=-1);
    drawnow limitrate;
    pause(frameDelaySeconds);
end

%% Step 10: A variation - full detail and a custom color scheme
% The same steps again, starting from the downloaded file, but this time:
%   * keeping every face of the model (no reduction), and
%   * choosing the colors: blue body, nearly opaque gray glass, black trim.
% PartColors sets any part's color: 'body', 'glass', 'wheel', 'light', or
% 'trim'. GlassAlpha sets how see-through the glass is (0 = invisible,
% 1 = solid).

bodyBlue  = [0.05 0.20 0.60];
glassGray = [0.30 0.30 0.32];
trimBlack = [0.02 0.02 0.02];
variantColors = {'body',bodyBlue; 'glass',glassGray; 'trim',trimBlack};

figNum = 10;
if flag_useDownloadedModel
    variantMesh = fcn_CarMesh3D_importMesh(modelFile, ...
        License='(fill in from the model''s download page)', FigNum=-1); % Reuses the converted file
    variantMesh.Name = '2010 Toyota Prius (full detail, blue)';
    variantMesh = fcn_CarMesh3D_normalizeMesh(variantMesh, UpAxis='+z', ForwardAxis='+x', FigNum=-1);
    variantMesh = fcn_CarMesh3D_labelParts(variantMesh, ...
        PartRules={'17in','wheel'; 'color_notint','trim'}, ...
        UseMaterialColors=false, PartColors=variantColors, GlassAlpha=0.85, FigNum=figNum);
    variantMesh = fcn_CarMesh3D_fitMeshToSpec(variantMesh, vehicleSpec, WidthReference='mirrors', FigNum=-1);
else
    variantMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
    variantMesh.Name = 'Sample car (full detail, blue)';
    variantMesh = fcn_CarMesh3D_labelParts(variantMesh, ...
        UseMaterialColors=false, PartColors=variantColors, GlassAlpha=0.85, FigNum=figNum);
    variantMesh = fcn_CarMesh3D_fitMeshToSpec(variantMesh, vehicleSpec, FigNum=-1);
end

% Keep all faces: a target equal to the current face count means the mesh
% is only cleaned (duplicate vertices merged, normals pointed outward),
% not reduced. For this model, the count still drops from 6818 to 6648:
% its glass is "double-sided", with a reversed copy of each of 170 glass
% triangles. MATLAB already draws both sides of every face, and the
% copies would make see-through glass look twice as dark, so cleaning
% removes them. Every other face is kept.
numFacesOriginal = size(variantMesh.Faces,1);
variantMesh = fcn_CarMesh3D_simplifyMesh(variantMesh, TargetFaces=numFacesOriginal, FigNum=figNum+1);
fprintf(1,'Full-detail variation: %d faces in, %d faces out\n', numFacesOriginal, size(variantMesh.Faces,1));

validationTable = fcn_CarMesh3D_validateMesh(variantMesh, vehicleSpec, FigNum=figNum+2);
disp(validationTable);

%% Step 11: Compare the two versions side by side, with a glossy finish
% Finish sets how shiny the surface looks: 'matte' (the default),
% 'satin', 'glossy', or 'metallic'. Shiny finishes automatically use
% smooth (gouraud) shading so the highlights blend across faces.

figNum = 13;
figure(figNum); clf;
fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[0  1.4 0], FigNum=figNum);                  % matte
fcn_CarMesh3D_plotVehicle(variantMesh, Pose=[0 -1.4 0], Finish='glossy', FigNum=figNum); % glossy
view(-30,25);
title(sprintf('Left: %d faces, default colors, matte.  Right: %d faces, custom colors, glossy.', ...
    size(vehicleMesh.Faces,1), size(variantMesh.Faces,1)), 'Interpreter','none');

%% Step 12: Show the mesh edges
% ShowEdges turns the face edges on or off, and EdgeColor sets their
% color. Edges help when checking a mesh; leave them off for animation.

figNum = 14;
figure(figNum); clf;
tiledlayout(1,2);
nexttile;
fcn_CarMesh3D_plotVehicle(variantMesh, Finish='glossy', ShowEdges=true, EdgeColor=[0 0 0], FigNum=figNum);
title('Black edges');
nexttile;
fcn_CarMesh3D_plotVehicle(variantMesh, Finish='glossy', ShowEdges=true, EdgeColor=[0.85 0.85 0.85], FigNum=figNum);
title('Light gray edges');

%% Step 13: Check the outline against a side-view picture
% fcn_CarMesh3D_plotSideImage puts a side-view picture of the real vehicle
% on a plane through the vehicle's centerline. The picture is scaled and
% placed so that its two wheel centers land on the mesh's two axles, so
% any difference in the roof line, hood, trunk, or bumpers shows up.
%
% To use a real photo: save a side view of the vehicle (taken from far
% away, so it is nearly free of perspective, and level with the wheels)
% as the file below. The first time, leave out WheelCentersPixels and
% click the rear, then the front, wheel center; the values are printed so
% they can be pasted in here. Without a photo, a side view drawn from the
% mesh itself is used, so the outlines agree exactly.

figNum = 15;
figure(figNum); clf;
sideImageFile = fullfile('Data','sideView_2013ToyotaPriusFour.jpg');
if isfile(sideImageFile)
    overlayHandles = fcn_CarMesh3D_plotSideImage(sideImageFile, vehicleMesh, FigNum=figNum);
else
    fprintf(1,'No side photo found (%s); using a side view drawn from the mesh\n', sideImageFile);
    [sideImage, wheelPixels] = fcn_INTERNAL_renderSideView(vehicleMesh);
    overlayHandles = fcn_CarMesh3D_plotSideImage(sideImage, vehicleMesh, ...
        WheelCentersPixels=wheelPixels, FigNum=figNum);
end
title(sprintf('Side picture on the centerline: %.2f mm per pixel', 1000*overlayHandles.MetersPerPixel));

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

%% fcn_INTERNAL_renderSideView
function [sideImage, wheelPixels] = fcn_INTERNAL_renderSideView(vehicleMesh)
% Draws the vehicle from the right side, without perspective, filling a
% figure exactly, and captures it as a picture. The wheel-center pixels
% follow from the axis limits. (A stand-in for a real side photo.)
figureSize = [800 300];
renderFigure = figure('Position',[100 100 figureSize],'Color',[1 1 1]);
renderAxes = axes('Parent',renderFigure,'Position',[0 0 1 1]);
fcn_CarMesh3D_plotVehicle(vehicleMesh, Finish='glossy', FigNum=-1);
view(renderAxes,0,0);
camproj(renderAxes,'orthographic');
axis(renderAxes,'off');
xLimits = [min(vehicleMesh.Vertices(:,1))-0.3, max(vehicleMesh.Vertices(:,1))+0.3];
zLimits = [-0.2, -0.2 + diff(xLimits)*figureSize(2)/figureSize(1)];
set(renderAxes,'XLim',xLimits,'ZLim',zLimits,'YLim',[-2 2],'DataAspectRatio',[1 1 1]);
drawnow;
frame = getframe(renderFigure);
sideImage = frame.cdata;
close(renderFigure);
tireRadius = vehicleMesh.VehicleSpec.TireDiameter/2;
wheelPixels = [(vehicleMesh.AxleX(:) - xLimits(1))/diff(xLimits)*size(sideImage,2) + 0.5, ...
    (zLimits(2) - tireRadius)/diff(zLimits)*size(sideImage,1) + 0.5 + [0; 0]];
end % Ends fcn_INTERNAL_renderSideView

%% fcn_INTERNAL_setupWorkspace
function fcn_INTERNAL_setupWorkspace

%% Add this project's folders to the path
this_project_folders = {'Functions','Data'};
fprintf(1,'\tAdding this project folders to the path: \n');
for ith_folder = 1:length(this_project_folders)
	thisFolder = fullfile(pwd, this_project_folders{ith_folder});
	fprintf(1,'\t\tAdding subfolder: %s\n',this_project_folders{ith_folder});
	addpath(thisFolder);
end

%% Set environment flags for input checking in CarMesh3D library
% These are values to set if we want to check inputs or do debugging
setenv('MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS','1');
setenv('MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG','0');

%% Set up warnings
thisVersion = version('-release');
thisVersionYear = str2double(thisVersion(1:4));

% Name=Value calling syntax needs MATLAB R2021a or newer
if thisVersionYear<2021
	error('CarMesh3D needs MATLAB R2021a or newer (for Name=Value inputs). Found release %s.',thisVersion);
elseif thisVersionYear<2025
	saved = warning("query","backtrace");
	warning("off","backtrace");
	warning('CarMesh3D was written for MATLAB 2025a or 2025b, but found release %s. It should work, but please report any problems.',thisVersion);
	warning(saved);
end

thisPath = pwd;

% Confirm that path contains no minus signs
if contains(thisPath,'-')
	warning('A minus character was found in the working path: %s. Minus signs in file names and paths can cause evaluation errors.',thisPath);
end

end % Ends fcn_INTERNAL_setupWorkspace
