% script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GenericSedan.m
% Builds the CarMesh3D mesh of the BUILT-IN SAMPLE CAR (fcn_CarMesh3D_fillSampleMesh,
% at the 'genericSedan' preset's size) as a vehicle folder like any other,
% so that it loads like any other vehicle (mesh, detail levels, outlines),
% and runs the standard checks. It has no downloaded model: Step 2 makes
% the sample instead of importing one.
%
% EVERY VEHICLE IN THE Data FOLDER HAS A SCRIPT LIKE THIS ONE. To add a
% new vehicle:
%   1. Make its folder, Data\YEAR_Make_Model_Trimline (letters and digits
%      in each part, CamelCase for several words, for example
%      Data\2014_Ford_TransitConnect_XLTCargoLWB). See
%      fcn_CarMesh3D_findVehicleFiles for the convention.
%   2. Put its vehicleParameters structure in that folder as
%      vehicleParameters_<ID>.mat, and its downloaded 3D model (with the
%      model's LICENSE.txt) in a "model" subfolder. NO MODEL OF THIS
%      VEHICLE? Set modelFile = '' and bodyStyle to its body style (see
%      Data\bodyStyles.csv): the style's exemplar is refit to this
%      vehicle's dimensions.
%   3. Copy Data\script_CarMesh3D_vehicle_TEMPLATE.m into the folder, renamed to
%      script_CarMesh3D_vehicle_<ID>.m, and change only the "Vehicle settings"
%      section below.
%   4. Run it. Look at every picture and animation in the "checks"
%      subfolder. Fix the settings (most often the label edits) and run
%      it again until every check looks right.
%   5. Set flagAddThisVehicleToReferenceList = 1 and run it once more,
%      to add the vehicle (and its animation) to the reference list in
%      Data\referenceVehicles.csv and in the README.
%
% WHAT IT MAKES, in this vehicle's folder:
%   vehicleMesh_<ID>.mat   the finished mesh (vehicleMesh, vehicleSpec)
%   checks\                the standard check images and GIFs (see
%                          fcn_CarMesh3D_runVehicleChecks), plus
%                          check_00_orientation.png (the model after
%                          turning it to X forward, Y left, Z up) and
%                          check_11_detailLevels.png (the detail levels)
%   vehicleLevels_<ID>.mat the detail levels (lighter versions of the
%                          mesh, for animation; see
%                          fcn_CarMesh3D_makeDetailLevels)
%   vehicleOutline_<ID>.mat the top-down (2D) outlines, for 2D plots (see
%                          fcn_CarMesh3D_makeOutline2D), with
%                          checks\check_12_outline2D.png

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GenericSedan
%   % * First write of the code (drafted with Claude), from the template:
%   %   % the sample car as a vehicle folder (asked for by AnimateCar3D)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_YEAR_Make_Model_Trimline
%   % * Finds the CarMesh3D folder by walking up to the folder holding
%   %   % Functions, so the script works from Data\BodyStyles\<Style>\<ID>
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GenericSedan
%   % * Builds in a copy of its folder (the main GUI's working model,
%   %   % Q111 (A); drafted by Claude); its own steps kept

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_YEAR_Make_Model_Trimline
%   % * (fill in items here)


%% Vehicle settings (the only part to change for a new vehicle)
vehicleID = '2026_CarMesh3D_Sample_GenericSedan';   % Must match this folder's name

% The downloaded 3D model, relative to this folder
modelFile = 'sample';   % (no file: the built-in sample car, made in Step 2)

% No model of this vehicle? Set modelFile = '' and give its body style: an
% ID from Data\bodyStyles.csv, such as 'sedan', 'minivan', or
% 'pickupCrewCab' (see fcn_CarMesh3D_loadBodyStyles(FigNum=1) for the
% styles with exemplars). The style's exemplar (a finished vehicle) is refit
% to this vehicle's dimensions, labels and all; the import, label, and
% width settings below are then not used (label edits after the fit still
% are).
bodyStyle = '';

% Turning the model to X forward, Y left, Z up (check check_00_orientation.png:
% the red X arrow must point at the front bumper). Models converted by
% Blender (FBX, glTF, GLB, .blend) are Z up.
importUpAxis = '+z';
importForwardAxis = '+x';

% Labels: which parts are which (fcn_CarMesh3D_labelParts). PartRules
% pairs a regular expression on the model's group or material names with a
% part: 'body', 'glass', 'wheel', 'light', or 'trim'.
partRules = {}                   % for example {'Wheel','wheel'; 'Glass','glass'};
flagUseMaterialColors = false;   % false: one color per part (below)
bodyColor = [0.05 0.20 0.60];   % The standard blue for every vehicle: it shows mislabeled trim and glass clearly
glassColor = [0.25 0.25 0.28];
trimColor = [0.05 0.05 0.05];
glassAlpha = 0.6;          % 0 clear to 1 solid

% Width: 'all' (the whole model to OverallWidth), 'body' (only body faces),
% or 'mirrors' (the whole model to WidthWithMirrors, when the mirrors are
% part of the body)
widthReference = 'all';

% Label fixes AFTER fitting (fcn_CarMesh3D_editLabels): regions are in
% meters, with the origin on the ground below the rear axle, X forward,
% Y left, Z up. Find them with flagUseInteractiveLabelEditor = 1.
% Label fixes that must be made BEFORE fitting (for example, tires that
% are part of the body) go in fcn_INTERNAL_editsBeforeFit at the end of
% this script.
labelEditsAfterFit = {};
% labelEditsAfterFit{end+1} = struct('Name','tail lights', 'Region',[xmin xmax ymin ymax zmin zmax], ...
%     'BothSides',true, 'LightType','tailBrakeLamp');

% Face budget for the finished mesh ([] keeps every face)
targetFaces = 8000;

% What to run
flagUseInteractiveLabelEditor = 0;       % 1: click to fix labels (prints region edits to paste above)
flagRunChecks = 1;                       % 1: run the standard checks (images and GIFs in checks\)
flagSaveGifs = 0;                        % 1: save the check GIFs (0 is faster, for a first look)
flagAddThisVehicleToReferenceList = 0;   % 1: add to Data\referenceVehicles.csv and the README

%% Set up the workspace
thisFolder = fileparts(mfilename('fullpath'));
% (the CarMesh3D folder: the first folder above this one that holds Functions)
rootFolder = thisFolder;
while ~isfolder(fullfile(rootFolder,'Functions')) && ~strcmp(rootFolder, fileparts(rootFolder))
    rootFolder = fileparts(rootFolder);
end
addpath(fullfile(rootFolder,'Functions'));
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID);
if ~strcmpi(vehicleFiles.Folder, thisFolder)
    % (a copy of this vehicle's folder, named by its ID: the main GUI's
    % working model, CarMesh3D\Working\<ID>\, or a demo copy. It builds in
    % place, into the copy, reading the download from the vehicle's own
    % folder; Q111 (A), 2026-11-27)
    [~, folderName] = fileparts(thisFolder);
    if ~strcmp(folderName, vehicleID)
        error(['vehicleID (%s) does not match this script''s folder (%s). Was the script copied ' ...
            'without changing vehicleID?'], vehicleID, thisFolder);
    end
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(thisFolder);
end
if ~isfolder(vehicleFiles.ChecksFolder)
    mkdir(vehicleFiles.ChecksFolder);
end
fprintf(1,'\n===== %s =====\n', vehicleFiles.Name);

%% Step 1: Vehicle specification
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(vehicleFiles.ParametersFile, BodyColor=bodyColor);

%% Steps 2 to 4 from a body style (no model of this vehicle)
flagFromBodyStyle = isempty(modelFile);
if flagFromBodyStyle
    if isempty(bodyStyle)
        error('Give a modelFile, or set modelFile = '''' and give a bodyStyle (see Data\bodyStyles.csv)');
    end
    vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh(bodyStyle, vehicleSpec, BodyColor=bodyColor, FigNum=1);
    fcn_INTERNAL_savePicture(1, fullfile(vehicleFiles.ChecksFolder,'check_00_orientation.png'));
    fprintf(1,'From the body style ''%s'': %s\n', bodyStyle, vehicleMesh.Source);
end

%% Step 2: Import the model and turn it to X forward, Y left, Z up
if ~flagFromBodyStyle
    licenseFile = fullfile(vehicleFiles.ModelFolder,'LICENSE.txt');
    modelLicense = 'unknown';
    if isfile(licenseFile)
        modelLicense = strtrim(fileread(licenseFile));
    end
    % (the built-in sample car, made in the vehicle frame: nothing to import)
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
    vehicleMesh.Name = vehicleFiles.Name;
    vehicleMesh.License = 'Part of CarMesh3D (made by fcn_CarMesh3D_fillSampleMesh)';
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis=importUpAxis, ForwardAxis=importForwardAxis, FigNum=1);
    fcn_INTERNAL_savePicture(1, fullfile(vehicleFiles.ChecksFolder,'check_00_orientation.png'));
end

%% Step 3: Labels
if ~flagFromBodyStyle
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules=partRules, FlagUseMaterialColors=flagUseMaterialColors, ...
        PartColors={'body',bodyColor; 'glass',glassColor; 'trim',trimColor}, GlassAlpha=glassAlpha);
    editsBeforeFit = fcn_INTERNAL_editsBeforeFit(vehicleMesh);
    if ~isempty(editsBeforeFit)
        vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=editsBeforeFit);
    end
end

%% Step 4: Fit to the specification
if ~flagFromBodyStyle
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference=widthReference);
end
if ~isempty(labelEditsAfterFit)
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=labelEditsAfterFit);
end
if flagUseInteractiveLabelEditor
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, FlagInteractive=true, GlassAlpha=glassAlpha); %#ok<UNRCH>
end

%% Step 5: Simplify
if isempty(targetFaces)
    targetFaces = size(vehicleMesh.Faces,1);
end
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, TargetFaces=targetFaces);
fprintf(1,'Finished mesh: %d faces\n', size(vehicleMesh.Faces,1));

%% Step 6: Save the finished mesh
save(vehicleFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
fprintf(1,'Saved %s\n', vehicleFiles.MeshFile);

%% Step 6b: Make and save the detail levels (lighter versions, for animation)
% A ladder of reduced meshes, each made for a range of sizes on screen
% (see fcn_CarMesh3D_makeDetailLevels); used by AnimateCar3D for vehicles
% that are far away. Its picture is checks\check_11_detailLevels.png.
detailLevels = fcn_CarMesh3D_makeDetailLevels(vehicleMesh, FigNum=2);
save(vehicleFiles.LevelsFile, 'detailLevels');
fprintf(1,'Saved %s: %d levels, %d faces down to %d (a box)\n', vehicleFiles.LevelsFile, ...
    numel(detailLevels.Levels), detailLevels.Levels(1).Faces, detailLevels.Levels(end).Faces);
set(figure(2), 'Position', [50 50 1400 520]);
fcn_INTERNAL_savePicture(2, fullfile(vehicleFiles.ChecksFolder,'check_11_detailLevels.png'));

%% Step 6c: Make and save the top-down (2D) outlines
% XY polygons of the body, the upward glass, the wheels, and the lights,
% for 2D plots (see fcn_CarMesh3D_makeOutline2D); its picture is
% checks\check_12_outline2D.png.
vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh, FigNum=3);
save(vehicleFiles.OutlineFile, 'vehicleOutline');
fprintf(1,'Saved %s: %d points\n', vehicleFiles.OutlineFile, vehicleOutline.PointCount);
fcn_INTERNAL_savePicture(3, fullfile(vehicleFiles.ChecksFolder,'check_12_outline2D.png'));

%% Step 7: The standard checks
if flagRunChecks
    checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, vehicleFiles.ChecksFolder, ...
        FlagSaveGifs=logical(flagSaveGifs), VehicleName=vehicleFiles.Name);
    fprintf(1,'Checks written to %s\n', vehicleFiles.ChecksFolder);
    disp(checkResults.ValidationTable);
end

%% Step 8: Add to the reference vehicle list
if flagAddThisVehicleToReferenceList
    referenceGif = fullfile(vehicleFiles.ChecksFolder,'check_09_drive.gif');
    if ~isfile(referenceGif)
        error('Run the checks with flagSaveGifs = 1 first: %s is needed', referenceGif);
    end
    fcn_CarMesh3D_addReferenceVehicle(vehicleID, vehicleMesh, referenceGif);
    fprintf(1,'Added %s to the reference vehicle list\n', vehicleID);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_editsBeforeFit
function edits = fcn_INTERNAL_editsBeforeFit(vehicleMesh) %#ok<INUSD>
% Label fixes that must be made before fitting, as a cell array of
% fcn_CarMesh3D_editLabels edits. Most vehicles need none. The fit moves
% each wheel as one rigid piece, so anything that must move with a wheel
% (for example, tires stored as part of the body) has to be labeled
% 'wheel' here, before fitting.
edits = {};
end % Ends fcn_INTERNAL_editsBeforeFit

%% fcn_INTERNAL_savePicture
function fcn_INTERNAL_savePicture(figNum, fileName)
% Saves what a figure shows
figureHandle = figure(figNum);
drawnow;
frame = getframe(figureHandle);
imwrite(frame.cdata, fileName);
end % Ends fcn_INTERNAL_savePicture
