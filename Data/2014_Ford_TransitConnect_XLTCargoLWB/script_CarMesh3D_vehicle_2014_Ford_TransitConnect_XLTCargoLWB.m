% script_CarMesh3D_vehicle_2014_Ford_TransitConnect_XLTCargoLWB.m
% Builds the CarMesh3D mesh for a 2014 Ford Transit Connect XLT Cargo Van (long wheelbase), and runs the standard checks.
%
% EVERY VEHICLE IN THE Data FOLDER HAS A SCRIPT LIKE THIS ONE. To add a
% new vehicle:
%   1. Make its folder, Data\YEAR_Make_Model_Trimline (letters and digits
%      in each part, CamelCase for several words, for example
%      Data\2014_Ford_TransitConnect_XLTCargoLWB). See
%      fcn_CarMesh3D_findVehicleFiles for the convention.
%   2. Put its vehicleParameters structure in that folder as
%      vehicleParameters_<ID>.mat, and its downloaded 3D model (with the
%      model's LICENSE.txt) in a "model" subfolder.
%   3. Copy Data\script_CarMesh3D_vehicle_TEMPLATE.m into the folder, renamed to
%      script_CarMesh3D_vehicle_<ID>.m, and change only the "Vehicle settings"
%      section below.
%   4. Run it. Look at every picture and animation in the "checks"
%      subfolder. Fix the settings (most often the label edits) and run
%      it again until every check looks right.
%   5. Set flag_addThisVehicleToReferenceList = 1 and run it once more,
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

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2014_Ford_TransitConnect_XLTCargoLWB
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2014_Ford_TransitConnect_XLTCargoLWB
%   % * Renamed from script_vehicle_...: scripts that demonstrate the code
%   %   % are named script_<Repo>_<name>
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2014_Ford_TransitConnect_XLTCargoLWB
%   % * Makes and saves the detail levels (Step 6b,
%   %   % vehicleLevels_<ID>.mat and check_11_detailLevels.png)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2014_Ford_TransitConnect_XLTCargoLWB
%   % * Check the rear lamp split against photos of a real Transit Connect


%% Vehicle settings (the only part to change for a new vehicle)
vehicleID = '2014_Ford_TransitConnect_XLTCargoLWB';   % Must match this folder's name

% The downloaded 3D model, relative to this folder
modelFile = fullfile('model','source','5230c49a9_FordTransitConnect.glb');

% Turning the model to X forward, Y left, Z up (check check_00_orientation.png:
% the red X arrow must point at the front bumper). Models converted by
% Blender (FBX, glTF, GLB, .blend) are Z up.
importUpAxis = '+z';
importForwardAxis = '+x';

% Labels: which parts are which (fcn_CarMesh3D_labelParts). PartRules
% pairs a regular expression on the model's group or material names with a
% part: 'body', 'glass', 'wheel', 'light', or 'trim'.
partRules = {'Mesh_1','glass'; 'Mesh_2','light'; 'Mesh_3','wheel'; 'Mesh_0','body'}   % This model's groups have no descriptive names;
useMaterialColors = false;   % false: one color per part (below)
bodyColor = [0.05 0.20 0.60];   % The standard blue for every vehicle: it shows mislabeled trim and glass clearly
glassColor = [0.20 0.22 0.25];
trimColor = [0.05 0.05 0.05];
glassAlpha = 0.75;          % 0 clear to 1 solid

% Width: 'all' (the whole model to OverallWidth), 'body' (only body faces),
% or 'mirrors' (the whole model to WidthWithMirrors, when the mirrors are
% part of the body)
widthReference = 'mirrors';

% Label fixes AFTER fitting (fcn_CarMesh3D_editLabels): regions are in
% meters, with the origin on the ground below the rear axle, X forward,
% Y left, Z up. Find them with flag_useInteractiveLabelEditor = 1.
% Label fixes that must be made BEFORE fitting (for example, tires that
% are part of the body) go in fcn_INTERNAL_editsBeforeFit at the end of
% this script.
labelEditsAfterFit = {};
% The lamp regions below were found from the light faces of the fitted
% mesh. The split of each rear lamp (upper tail, middle turn signal, lower
% backup) is an approximation of the real lamp.
labelEditsAfterFit{end+1} = struct('Name','front turn signals (rear corner of each headlamp)', 'Region',[3.10 3.45 0.60 0.85 0.70 1.10], ...
    'BothSides',true, 'CurrentPart','light', 'LightType','turnsignal');
labelEditsAfterFit{end+1} = struct('Name','tail lights (upper part of each rear lamp)', 'Region',[-0.75 -0.50 0.68 0.86 1.17 1.50], ...
    'BothSides',true, 'CurrentPart','light', 'LightType','tail');
labelEditsAfterFit{end+1} = struct('Name','rear turn signals (middle part)', 'Region',[-0.75 -0.50 0.68 0.86 1.00 1.17], ...
    'BothSides',true, 'CurrentPart','light', 'LightType','turnsignal');
labelEditsAfterFit{end+1} = struct('Name','backup lights (lower part)', 'Region',[-0.75 -0.50 0.68 0.86 0.80 1.00], ...
    'BothSides',true, 'CurrentPart','light', 'LightType','backup');

% Face budget for the finished mesh ([] keeps every face)
targetFaces = 15000;

% What to run
flag_useInteractiveLabelEditor = 0;       % 1: click to fix labels (prints region edits to paste above)
flag_runChecks = 1;                       % 1: run the standard checks (images and GIFs in checks\)
flag_saveGifs = 1;                        % 1: save the check GIFs (0 is faster, for a first look)
flag_addThisVehicleToReferenceList = 1;   % 1: add to Data\referenceVehicles.csv and the README

%% Set up the workspace
thisFolder = fileparts(mfilename('fullpath'));
rootFolder = fileparts(fileparts(thisFolder));
addpath(fullfile(rootFolder,'Functions'));
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID);
if ~strcmpi(vehicleFiles.Folder, thisFolder)
    error(['vehicleID (%s) does not match this script''s folder (%s). Was the script copied ' ...
        'without changing vehicleID?'], vehicleID, thisFolder);
end
if ~isfolder(vehicleFiles.ChecksFolder)
    mkdir(vehicleFiles.ChecksFolder);
end
fprintf(1,'\n===== %s =====\n', vehicleFiles.Name);

%% Step 1: Vehicle specification
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(vehicleFiles.ParametersFile, BodyColor=bodyColor);

%% Step 2: Import the model and turn it to X forward, Y left, Z up
licenseFile = fullfile(vehicleFiles.ModelFolder,'LICENSE.txt');
modelLicense = 'unknown';
if isfile(licenseFile)
    modelLicense = strtrim(fileread(licenseFile));
end
vehicleMesh = fcn_CarMesh3D_importMesh(fullfile(thisFolder, modelFile), Name=vehicleFiles.Name, License=modelLicense);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis=importUpAxis, ForwardAxis=importForwardAxis, FigNum=1);
fcn_INTERNAL_savePicture(1, fullfile(vehicleFiles.ChecksFolder,'check_00_orientation.png'));

%% Step 3: Labels
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules=partRules, UseMaterialColors=useMaterialColors, ...
    PartColors={'body',bodyColor; 'glass',glassColor; 'trim',trimColor}, GlassAlpha=glassAlpha);
editsBeforeFit = fcn_INTERNAL_editsBeforeFit(vehicleMesh);
if ~isempty(editsBeforeFit)
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=editsBeforeFit);
end

%% Step 4: Fit to the specification
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference=widthReference);
if ~isempty(labelEditsAfterFit)
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=labelEditsAfterFit);
end
if flag_useInteractiveLabelEditor
    vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Interactive=true, GlassAlpha=glassAlpha); %#ok<UNRCH>
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

%% Step 7: The standard checks
if flag_runChecks
    checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, vehicleFiles.ChecksFolder, ...
        SaveGifs=logical(flag_saveGifs), VehicleName=vehicleFiles.Name);
    fprintf(1,'Checks written to %s\n', vehicleFiles.ChecksFolder);
    disp(checkResults.ValidationTable);
end

%% Step 8: Add to the reference vehicle list
if flag_addThisVehicleToReferenceList
    referenceGif = fullfile(vehicleFiles.ChecksFolder,'check_09_drive.gif');
    if ~isfile(referenceGif)
        error('Run the checks with flag_saveGifs = 1 first: %s is needed', referenceGif);
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

% In this model the wheel group holds only the rims; the tires are part
% of the body. Every body face near each rim, within the tire's radius
% and width, is relabeled as wheel so the tire moves (and spins) with
% its rim.
tireRadius = 0.34;       % Just over the model's tire radius [m]
tireHalfWidth = 0.25;    % From the rim's face to past the tire's inner sidewall [m]
faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
bodyIndex = find(strcmp(vehicleMesh.PartNames,'body'));
tireFaces = [];
for ith_wheel = 1:4
    rimFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==ith_wheel,:);
    if isempty(rimFaces)
        continue;
    end
    rimVertices = vehicleMesh.Vertices(unique(rimFaces(:)),:);
    wheelCenter = (min(rimVertices,[],1) + max(rimVertices,[],1))/2;
    % Distance from the axle (in the X-Z plane) and across (Y)
    radialDistance = sqrt((faceCenters(:,1) - wheelCenter(1)).^2 + (faceCenters(:,3) - wheelCenter(3)).^2);
    acrossDistance = abs(faceCenters(:,2) - wheelCenter(2));
    flagTire = vehicleMesh.FacePartIndex==bodyIndex & radialDistance < tireRadius & acrossDistance < tireHalfWidth;
    tireFaces = [tireFaces; find(flagTire)]; %#ok<AGROW>
end
if ~isempty(tireFaces)
    edits{end+1} = struct('Name','tires (stored as body in this model)', 'FaceIndices',tireFaces, 'Part','wheel');
end
end % Ends fcn_INTERNAL_editsBeforeFit

%% fcn_INTERNAL_savePicture
function fcn_INTERNAL_savePicture(figNum, fileName)
% Saves what a figure shows
figureHandle = figure(figNum);
drawnow;
frame = getframe(figureHandle);
imwrite(frame.cdata, fileName);
end % Ends fcn_INTERNAL_savePicture
