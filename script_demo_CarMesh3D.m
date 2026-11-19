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
%   2. Shape source   fcn_CarMesh3D_importMesh (downloaded OBJ/STL) or
%                     fcn_CarMesh3D_fillSampleMesh (built-in sample)
%   3. Normalize      fcn_CarMesh3D_normalizeMesh  (X forward, Y left, Z up, meters)
%   4. Label parts    fcn_CarMesh3D_labelParts     (body, glass, wheels, lights, trim)
%   5. Fit to spec    fcn_CarMesh3D_fitMeshToSpec  (exact wheelbase, track, tires)
%   6. Simplify       fcn_CarMesh3D_simplifyMesh   (face budget, outward normals)
%   7. Validate       fcn_CarMesh3D_validateMesh   (table of target vs. measured)
%   8. Plot / animate fcn_CarMesh3D_plotVehicle    (fast pose updates)

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * First prototype of the library (drafted with Claude)
%   % * Core functions: fillVehicleSpec, loadVehicleSpec, fillSampleMesh,
%   %   % importMesh, normalizeMesh, labelParts, fitMeshToSpec,
%   %   % simplifyMesh, validateMesh, plotVehicle
%   % * Each core function has a matching script_CarMesh3D_<name> test
%   %   % script in the Functions folder

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_CarMesh3D
%   % * Add glTF/GLB import (most common format on model-sharing sites)
%   % * Add blueprint (side/front/top silhouette) extrusion as a shape source
%   % * Add a parametric body template as a fallback shape source
%   % * Add photo overlay to validation
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
specFile = fullfile('Data','vehicleParameters_2013ToyotaPriusFour.mat');
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
% For a downloaded model (OBJ or STL), use the importer. Set the file name
% and the license, and change 1==0 to 1==1:
%
% Good places to look for free models: Kenney.nl, OpenGameArt.org, and
% itch.io (search "low poly car", filter by CC0), and Sketchfab (filter by
% "Downloadable"; most are CC-BY, which requires attribution).

if 1==0
    figNum = 3;
    downloadedFile = fullfile('Data','myDownloadedCar.obj'); 
    vehicleMesh = fcn_CarMesh3D_importMesh(downloadedFile, License='CC0, author: ...', FigNum=figNum); %#ok<NASGU>
end

%%
% For this demo, use the built-in sample in its "messy" style, which
% imitates a downloaded file: millimeters, Y up, Z forward, offset from
% the origin. (The sample's proportions come from the Prius spec.)

figNum = 3;
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, Style='messy', FigNum=figNum);

%% Step 3: Normalize into the vehicle frame
% Tell the function which file axis points up and which points to the
% front of the car. Check the plot: the red arrow (X) must point to the
% front bumper.

figNum = 4;
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+y', ForwardAxis='+z', FigNum=figNum);

%% Step 4: Label the parts
% Parts are found from material and group names. For a downloaded model
% whose names are unhelpful (e.g. 'Material.012'), add rules such as
%       PartRules={'Material\.012','glass'}

figNum = 5;
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, BodyColor=vehicleSpec.BodyColor, FigNum=figNum);

%% Step 5: Fit to the specification
% The body is scaled to the length, width, and height, then stretched so
% the axles land at the true wheelbase. Wheels are moved as rigid
% objects to the true track and scaled to the true tire diameter.

figNum = 6;
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=figNum);

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
timeValues = linspace(0, 2*pi, numFrames);
xValues = 20*sin(timeValues);
yValues = 10*sin(2*timeValues);
yawValues = atan2(gradient(yValues), gradient(xValues));
for ith_frame = 1:numFrames
    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, ...
        Pose=[xValues(ith_frame) yValues(ith_frame) yawValues(ith_frame)], ...
        PlotHandles=plotHandles, FigNum=-1);
    drawnow limitrate;
	pause(0.05);
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
