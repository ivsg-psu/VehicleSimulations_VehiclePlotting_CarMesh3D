% script_CarMesh3D_vehicle_2026_CarMesh3D_Generic_Coupe.m
% A GENERIC COUPE: a template vehicle for the 'coupe' body style,
% made from the style's approved exemplar (Data\bodyStyles.csv, Exemplars
% column) refit to typical dimensions: the average of the vehicles filed
% under Data\BodyStyles\Coupe (see vehicleParameters_sources.md).
%
% USE IT for a coupe when no model of the actual vehicle is at hand and
% its exact dimensions do not matter, or as a starting point: for a
% specific vehicle, use Data\script_CarMesh3D_bodyStyle_TEMPLATE.m (a
% few dimensions in, mesh out) or copy Data\script_CarMesh3D_vehicle_TEMPLATE.m
% into the vehicle's own folder with modelFile = '' and bodyStyle = 'coupe'.
%
% Made from Data\script_CarMesh3D_vehicle_TEMPLATE.m (see it for what each
% step does and what files are made).
%
% This script was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Generic_Coupe
%   % * Made from the vehicle template, as the generic coupe

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Generic_Coupe
%   % * (none yet)

%% Vehicle settings (the only part to change for a new vehicle)
vehicleID = '2026_CarMesh3D_Generic_Coupe';   % Must match this folder's name

% The downloaded 3D model, relative to this folder
modelFile = '';   % (no model: the body style's exemplar, refit)

% No model of this vehicle? Set modelFile = '' and give its body style: an
% ID from Data\bodyStyles.csv, such as 'sedan', 'minivan', or
% 'pickupCrewCab' (see fcn_CarMesh3D_loadBodyStyles(FigNum=1) for the
% styles with exemplars). The style's exemplar (a finished vehicle) is refit
% to this vehicle's dimensions, labels and all; the import, label, and
% width settings below are then not used (label edits after the fit still
% are).
bodyStyle = 'coupe';

% Turning the model to X forward, Y left, Z up (check check_00_orientation.png:
% the red X arrow must point at the front bumper). Models converted by
% Blender (FBX, glTF, GLB, .blend) are Z up.
importUpAxis = '+z';
importForwardAxis = '+x';

% Faces to delete right after import: a regular expression on each face's
% '<materialName> <groupName>' text, for stray pieces that would spoil the
% fit (a lone point far above the roof, a ground plane, a stand). '' deletes
% nothing.
removeFaces = '';

% Labels: which parts are which (fcn_CarMesh3D_labelParts). PartRules
% pairs a regular expression on the model's group or material names with a
% part: 'body', 'glass', 'wheel', 'light', or 'trim'.
partRules = {}                   % for example {'Wheel','wheel'; 'Glass','glass'};
useMaterialColors = false;   % false: one color per part (below)
bodyColor = [0.05 0.20 0.60];   % The standard blue for every vehicle: it shows mislabeled trim and glass clearly
glassColor = [0.25 0.25 0.28];
trimColor = [0.05 0.05 0.05];
glassAlpha = 0.6;          % 0 clear to 1 solid

% .glb models only: parts shown in the colors painted in the model's
% textures (lamp lenses, badges, handles, rims), and whether its
% see-through faces become glass (fcn_CarMesh3D_labelParts). The body
% keeps bodyColor, so mislabeled faces still show.
textureColorParts = {'light','trim','wheel'};
seeThroughGlass = true;

% Parts inside each wheel (rim spokes, hub, brake disc) that the labels
% missed become part of that wheel, so they turn with it: true (usual) or false
wheelInnerParts = true;

% Width: 'all' (the whole model to OverallWidth), 'body' (only body faces),
% or 'mirrors' (the whole model to WidthWithMirrors, when the mirrors are
% part of the body)
widthReference = 'all';

% Label fixes AFTER fitting (fcn_CarMesh3D_editLabels): regions are in
% meters, with the origin on the ground below the rear axle, X forward,
% Y left, Z up. Find them with flag_useInteractiveLabelEditor = 1.
% Label fixes that must be made BEFORE fitting (for example, tires that
% are part of the body) go in fcn_INTERNAL_editsBeforeFit at the end of
% this script.
labelEditsAfterFit = {};
% labelEditsAfterFit{end+1} = struct('Name','tail lights', 'Region',[xmin xmax ymin ymax zmin zmax], ...
%     'BothSides',true, 'LightType','tail');

% Face budget for the finished mesh ([] keeps every face)
targetFaces = 8000;

% Reduce the model in Blender (during its conversion to OBJ) instead of
% in MATLAB: Blender's Decimate keeps the outlines of badges, lamps, and
% panel edges far better than MATLAB's reducepatch. The wheels (by the
% 'wheel' rows of partRules, and the usual wheel words) keep their faces,
% and the faces of removeFaces are deleted first. A .glb, .gltf, .fbx,
% .blend, or .obj model; needs Blender (as .glb files do anyway).
reduceWithBlender = true;

% Reduce the left half and mirror it, so the mesh is exactly symmetric and
% each side gets the whole budget's detail (see fcn_CarMesh3D_simplifyMesh)
symmetricMesh = true;

% Shares of the face budget by part, after the wheels: {} for every part in
% proportion to its faces; give the painted body more when a download has
% a dense hidden interior (labeled trim), for example {'body',0.6; 'trim',0.15}
partShares = {};

% Add a flat floor panel under the body (at the ground clearance, wheel
% footprints cut out): many downloads have no underside, so the reduced
% mesh can be seen through from below and through its windows
addFloorPanel = true;

% What to run
flag_firstLook = 0;                       % 1: a fast first look: only the labels picture (no saved files, no visibility pass)
flag_compareToOriginal = 1;               % 1: compare the reduced mesh with the download (flagged spots; adds about a minute)
firstLookNote = '';                       % A note added to the labels figure's title (for example, whether the .glb reader would help)
flag_useInteractiveLabelEditor = 0;       % 1: click to fix labels (prints region edits to paste above)
flag_runChecks = 1;                       % 1: run the standard checks (images and GIFs in checks\)
checksToRun = 'all';                      % 'all', or a list such as {'labels'} for a first look (fast)
flag_saveGifs = 1;                        % 1: save the check GIFs (0 is faster, for a first look)
flag_addThisVehicleToReferenceList = 0;   % 1: add to Data\referenceVehicles.csv and the README

flag_useCache = 1;                        % 1: reuse each stage (mesh, comparison, checks) when nothing it depends on changed; 0: do every step again

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
    error(['vehicleID (%s) does not match this script''s folder (%s). Was the script copied ' ...
        'without changing vehicleID?'], vehicleID, thisFolder);
end
if ~isfolder(vehicleFiles.ChecksFolder)
    mkdir(vehicleFiles.ChecksFolder);
end
fprintf(1,'\n===== %s =====\n', vehicleFiles.Name);

%% Step 1: Vehicle specification
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(vehicleFiles.ParametersFile, BodyColor=bodyColor);

%% The cache: each slow stage is reused when nothing it depends on changed
% Stage 1 is the finished mesh (Steps 2 to 5), stage 2 the comparison
% with the download, stage 3 the detail levels, outline, and checks. Each
% is saved in this vehicle's cache folder with everything it depends on:
% this script's settings, the vehicle specification, the files it reads
% (the download, the parameters file, a body style's exemplars), the
% functions it runs (by file size and date), and the mesh version. When
% all of these are unchanged, the stage is loaded instead of done again
% (fcn_CarMesh3D_loadCache), so a rerun after a change to the checks
% skips the mesh, and a rerun with nothing changed takes seconds. The
% Blender step keeps its own reduced OBJ next to the download (see
% fcn_CarMesh3D_convertToOBJ), so Blender is not needed to redo the
% later steps. Set flag_useCache = 0 to do every step again.
cacheFolder = fullfile(vehicleFiles.Folder, 'cache');
[~, ~, meshVersion] = fcn_CarMesh3D_version(FigNum=-1);
flag_fromBodyStyle = isempty(modelFile);
stage1Files = {vehicleFiles.ParametersFile};
if flag_fromBodyStyle
    % (a body style: the style list and its exemplars' meshes)
    styleInfo = fcn_CarMesh3D_loadBodyStyles(FigNum=-1);
    styleInfo = styleInfo(strcmp({styleInfo.BodyStyle}, bodyStyle));
    stage1Files{end+1} = fullfile(rootFolder, 'Data', 'bodyStyles.csv');
    for ith_exemplar = 1:numel(styleInfo)
        for exemplarID = reshape(styleInfo(ith_exemplar).ExemplarIDs, 1, [])
            exemplarFiles = fcn_CarMesh3D_findVehicleFiles(exemplarID{1}, FigNum=-1);
            stage1Files{end+1} = exemplarFiles.MeshFile; %#ok<SAGROW>
        end
    end
else
    stage1Files{end+1} = fullfile(thisFolder, modelFile);
end
stage1Functions = {'fcn_CarMesh3D_loadVehicleSpec.m', 'fcn_CarMesh3D_fillBodyStyleMesh.m', 'fcn_CarMesh3D_loadBodyStyles.m', ...
    'fcn_CarMesh3D_fillSampleMesh.m', 'fcn_CarMesh3D_readGLB.m', 'fcn_CarMesh3D_convertToOBJ.m', 'fcn_CarMesh3D_importMesh.m', ...
    'fcn_CarMesh3D_transferTextureColors.m', 'fcn_CarMesh3D_normalizeMesh.m', 'fcn_CarMesh3D_labelParts.m', ...
    'fcn_CarMesh3D_editLabels.m', 'fcn_CarMesh3D_fitMeshToSpec.m', 'fcn_CarMesh3D_simplifyMesh.m', ...
    'fcn_CarMesh3D_fixFlippedFaces.m', 'fcn_CarMesh3D_separateOverlays.m', 'fcn_CarMesh3D_addFloorPanel.m', ...
    'fcn_CarMesh3D_restoreGroundClearance.m'};
stage1Inputs = struct('MeshVersion',meshVersion, 'Script',fcn_INTERNAL_scriptForCache([mfilename('fullpath') '.m']), ...
    'FirstLook',logical(flag_firstLook), 'Compare',logical(flag_compareToOriginal), 'VehicleSpec',vehicleSpec, ...
    'Files',fcn_CarMesh3D_fileStamps(stage1Files, FigNum=-1), 'Functions',fcn_CarMesh3D_fileStamps(stage1Functions, FigNum=-1));
stage1File = fullfile(cacheFolder, 'stage1_mesh.mat');
[stage1Outputs, flag_stage1Reused] = fcn_CarMesh3D_loadCache(stage1File, stage1Inputs, ...
    Enabled=logical(flag_useCache) && ~flag_useInteractiveLabelEditor, FigNum=1);
if flag_stage1Reused
    vehicleMesh = stage1Outputs.vehicleMesh;
    originalMesh = stage1Outputs.originalMesh;
else

    %% Steps 2 to 4 from a body style (no model of this vehicle)
    if flag_fromBodyStyle
        if isempty(bodyStyle)
            error('Give a modelFile, or set modelFile = '''' and give a bodyStyle (see Data\bodyStyles.csv)');
        end
        vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh(bodyStyle, vehicleSpec, BodyColor=bodyColor, FigNum=1);
        fcn_INTERNAL_savePicture(1, fullfile(vehicleFiles.ChecksFolder,'check_00_orientation.png'));
        fprintf(1,'From the body style ''%s'': %s\n', bodyStyle, vehicleMesh.Source);
    end

    %% Step 2: Import the model and turn it to X forward, Y left, Z up
    textureMesh = [];
    if ~flag_fromBodyStyle
        licenseFile = fullfile(vehicleFiles.ModelFolder,'LICENSE.txt');
        modelLicense = 'unknown';
        if isfile(licenseFile)
            modelLicense = strtrim(fileread(licenseFile));
        end
        modelPath = fullfile(thisFolder, modelFile);
        % (a .glb: its texture colors and see-through marks, read directly)
        [~,~,modelExtension] = fileparts(modelPath);
        if strcmpi(modelExtension,'.glb')
            textureMesh = fcn_CarMesh3D_readGLB(modelPath, Name=vehicleFiles.Name, License=modelLicense, FigNum=-1);
        end
        if reduceWithBlender && ~isempty(targetFaces)
            % (the wheel rows of partRules, and the usual wheel words)
            wheelPattern = 'tire|tyre|wheel|(^|[^a-z])rim|hub|brake';
            if ~isempty(partRules)
                wheelRows = strcmp(partRules(:,2),'wheel');
                wheelPattern = strjoin([partRules(wheelRows,1); {wheelPattern}], '|');
            end
            modelPath = fcn_CarMesh3D_convertToOBJ(modelPath, TargetFaces=targetFaces, WheelPattern=wheelPattern, RemovePattern=removeFaces);
        end
        vehicleMesh = fcn_CarMesh3D_importMesh(modelPath, Name=vehicleFiles.Name, License=modelLicense);
        if ~isempty(textureMesh)
            vehicleMesh = fcn_CarMesh3D_transferTextureColors(vehicleMesh, textureMesh, FigNum=-1);
        end
        vehicleMesh = fcn_INTERNAL_removeFaces(vehicleMesh, removeFaces);
        vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis=importUpAxis, ForwardAxis=importForwardAxis, FigNum=1);
        fcn_INTERNAL_savePicture(1, fullfile(vehicleFiles.ChecksFolder,'check_00_orientation.png'));
    end

    %% Step 3: Labels
    if ~flag_fromBodyStyle
        vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules=partRules, UseMaterialColors=useMaterialColors, ...
            PartColors={'body',bodyColor; 'glass',glassColor; 'trim',trimColor}, GlassAlpha=glassAlpha, ...
            SeeThroughGlass=seeThroughGlass, TextureColorParts=textureColorParts);
        editsBeforeFit = fcn_INTERNAL_editsBeforeFit(vehicleMesh);
        if ~isempty(editsBeforeFit)
            vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=editsBeforeFit);
        end
        if wheelInnerParts
            vehicleMesh = fcn_INTERNAL_wheelInnerParts(vehicleMesh);
        end
    end

    %% Step 4: Fit to the specification
    if ~flag_fromBodyStyle
        vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference=widthReference, Symmetric=symmetricMesh);
    end
    if ~isempty(labelEditsAfterFit)
        vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=labelEditsAfterFit);
    end
    if flag_useInteractiveLabelEditor
        vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Interactive=true, GlassAlpha=glassAlpha); %#ok<UNRCH>
    end

    %% Step 4b: The download itself (not reduced), labeled and fit the same way, for the comparison
    originalMesh = [];
    if flag_compareToOriginal && ~flag_fromBodyStyle
        if reduceWithBlender && ~isempty(targetFaces)
            if ~isempty(textureMesh)
                originalMesh = textureMesh;   % (the .glb, read directly)
            else
                originalMesh = fcn_CarMesh3D_importMesh(fullfile(thisFolder, modelFile), Name=vehicleFiles.Name, License=modelLicense);
            end
            originalMesh = fcn_INTERNAL_removeFaces(originalMesh, removeFaces);
            originalMesh = fcn_CarMesh3D_normalizeMesh(originalMesh, UpAxis=importUpAxis, ForwardAxis=importForwardAxis, FigNum=-1);
            originalMesh = fcn_CarMesh3D_labelParts(originalMesh, PartRules=partRules, UseMaterialColors=useMaterialColors, ...
                PartColors={'body',bodyColor; 'glass',glassColor; 'trim',trimColor}, GlassAlpha=glassAlpha, ...
                SeeThroughGlass=seeThroughGlass, TextureColorParts=textureColorParts);
            originalEdits = fcn_INTERNAL_editsBeforeFit(originalMesh);
            if ~isempty(originalEdits)
                originalMesh = fcn_CarMesh3D_editLabels(originalMesh, Edits=originalEdits);
            end
            if wheelInnerParts
                originalMesh = fcn_INTERNAL_wheelInnerParts(originalMesh);
            end
            originalMesh = fcn_CarMesh3D_fitMeshToSpec(originalMesh, vehicleSpec, WidthReference=widthReference, Symmetric=symmetricMesh);
            if ~isempty(labelEditsAfterFit)
                originalMesh = fcn_CarMesh3D_editLabels(originalMesh, Edits=labelEditsAfterFit);
            end
        else
            originalMesh = vehicleMesh;   % (reduced below, in MATLAB)
        end
    end

    %% Step 5: Simplify
    % (the texture colors are now in FaceColors: the raw per-face texture
    % fields are dropped, since the simplification makes new faces)
    vehicleMesh = fcn_INTERNAL_dropTextureFields(vehicleMesh);
    originalMesh = fcn_INTERNAL_dropTextureFields(originalMesh);
    if flag_fromBodyStyle
        % (a finished exemplar, refit: it was reduced, repaired, made
        % symmetric, given its floor panel, and had its overlays lifted when it
        % was made, so none of that is done again (a second pass would reduce
        % it further, reshape thin parts, lift its overlays another 2 mm, and
        % add a second floor panel); only the normals, which the refit
        % cleared, are made again, with the wheels cleared of body faces)
        vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, 'StitchTolerance',0, 'EdgeSmoothing',0, ...
            TargetFaces=size(vehicleMesh.Faces,1), Symmetric=false, PartShares={}, VisibilityCheck=false);
    else
        simplifyShares = partShares;
        if isempty(targetFaces) || (reduceWithBlender && ~flag_fromBodyStyle)
            % (no reduction here: all faces kept, or already reduced in Blender;
            % the other steps still run: symmetry, stitching, wheels, normals. The
            % part shares are not used: with them, a part given a small share was
            % still cut down, as the 2021 Outback's grille and bumper insets were)
            simplifyTarget = size(vehicleMesh.Faces,1);
            simplifyShares = {};
        else
            simplifyTarget = targetFaces;
        end
        % (not reduced at all, as a low-poly download often is: the stitch and
        % edge-smoothing steps, which repair reduction damage, are skipped, since
        % they only reshape thin parts such as window pillars)
        repairSettings = {};
        % (95%: Blender's import welds duplicate corners and drops degenerate
        % faces, 2.5% of the Prius's faces, even when it reduces nothing)
        if ~isempty(textureMesh) && size(vehicleMesh.Faces,1) >= 0.95*size(textureMesh.Faces,1)
            repairSettings = {'StitchTolerance',0, 'EdgeSmoothing',0};
            fprintf(1,'Not reduced (%d of %d faces kept): no stitching or edge smoothing\n', size(vehicleMesh.Faces,1), size(textureMesh.Faces,1));
        end
        vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, repairSettings{:}, TargetFaces=simplifyTarget, Symmetric=symmetricMesh, ...
            PartShares=simplifyShares, VisibilityCheck=~flag_firstLook);
        % (the ground clearance put back where the fit put it: a reduction can
        % raise the thin bottom edge of the rocker panels, as Blender's did
        % on the 2025 Camry by 5 mm; the wheels are not moved, and a mesh
        % that was not changed is left as it is)
        if isfield(vehicleSpec,'GroundClearance') && ~isempty(vehicleSpec.GroundClearance)
            vehicleMesh = fcn_CarMesh3D_restoreGroundClearance(vehicleMesh, vehicleSpec.GroundClearance, FigNum=1);
        end
        % (inside-out panels, found from face-number pictures from 14 directions:
        % a few seconds, so first looks show the panels the right way out)
        [vehicleMesh, numFlipped, numRemoved] = fcn_CarMesh3D_fixFlippedFaces(vehicleMesh, FigNum=-1);
        fprintf(1,'Flipped %d faces that were seen mostly from behind; removed %d inner-skin faces of double layers\n', numFlipped, numRemoved);
        % (overlays lying on another part's surface, such as a black bumper insert
        % on the paint, are lifted 2 mm, so they do not flicker or vanish; the
        % download used in the comparison gets the same treatment)
        [vehicleMesh, numLifted] = fcn_CarMesh3D_separateOverlays(vehicleMesh, FigNum=-1);
        if ~isempty(originalMesh)
            originalMesh = fcn_CarMesh3D_separateOverlays(originalMesh, FigNum=-1);
        end
        fprintf(1,'Lifted %d overlay faces off the surfaces they lie on\n', numLifted);
        if addFloorPanel
            vehicleMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, FigNum=-1);
        end
    end
    fcn_CarMesh3D_saveCache(stage1File, stage1Inputs, struct('vehicleMesh',vehicleMesh, 'originalMesh',originalMesh), FigNum=-1);
end
fprintf(1,'Finished mesh: %d faces\n', size(vehicleMesh.Faces,1));

%% Step 6: Save the finished mesh
if flag_firstLook
    % (a first look: only the labels picture, nothing saved)
    fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, vehicleFiles.ChecksFolder, ...
        Checks={'labels'}, SaveGifs=false, VehicleName=vehicleFiles.Name);
    fprintf(1,'First look: %s\n', fullfile(vehicleFiles.ChecksFolder,'check_03_labels.png'));
    % (and the labels in a figure left open, one per vehicle: drag to
    % rotate, scroll to zoom)
    labelsFigure = findobj(groot, 'Type','figure', '-regexp','Name',['^' regexptranslate('escape',vehicleFiles.Name) '.*: labels$']);
    if isempty(labelsFigure)
        labelsFigure = figure('Visible','on');
    end
    labelsTitle = vehicleFiles.Name;
    if ~isempty(firstLookNote)
        labelsTitle = sprintf('%s (%s)', vehicleFiles.Name, firstLookNote);
    end
    fcn_CarMesh3D_plotLabels(vehicleMesh, Title=labelsTitle, FigNum=labelsFigure(1).Number);
    % (and the comparison with the download: flagged spots, in two figures
    % left open and saved as checks\check_04_compare_views.png and _spots.png)
    if ~isempty(originalMesh)
        compareFigure = findobj(groot, 'Type','figure', '-regexp','Name',['^' regexptranslate('escape',vehicleFiles.Name) '.*: compared with the download$']);
        if isempty(compareFigure)
            compareFigure = figure('Visible','on');
        end
        compareFigure = compareFigure(1);
        compareReport = fcn_CarMesh3D_compareToOriginal(vehicleMesh, originalMesh, Title=labelsTitle, ...
            OutputFile=fullfile(vehicleFiles.ChecksFolder,'check_04_compare'), ...
            OriginalCache=fullfile(cacheFolder,'stage2_originalRenders.mat'), FigNum=compareFigure.Number);
        fprintf(1,'Compared with the download: holes %.2f%%, label changes %.2f%%, flipped faces %.2f%%, see-through gaps %.2f%% of the car''s pixels\n', ...
            compareReport.Totals.HolePercent, compareReport.Totals.LabelChangePercent, compareReport.Totals.FlippedPercent, compareReport.Totals.SeeThroughPercent);
    end
    return;
end
% (the build information saved with the mesh: the CarMesh3D and mesh
% versions it was made with, so it can be found and made again after a
% change (fcn_CarMesh3D_listVehicles), and its quality score, from the
% comparison with the download (also saved as checks\check_04_compare_*)
% and the dimension checks; a vehicle from a body style takes its
% exemplar's comparison)
compareTotals = [];
flag_stage2Reused = true;
if flag_compareToOriginal && ~isempty(originalMesh)
    % (stage 2 of the cache: the comparison, reused when the mesh's inputs
    % and the comparison function are unchanged and its pictures exist)
    stage2Inputs = struct('Stage1',stage1Inputs, 'Functions',fcn_CarMesh3D_fileStamps({'fcn_CarMesh3D_compareToOriginal.m'}, FigNum=-1));
    stage2File = fullfile(cacheFolder, 'stage2_compare.mat');
    comparePictures = fullfile(vehicleFiles.ChecksFolder, {'check_04_compare_views.png','check_04_compare_spots.png'});
    [stage2Outputs, flag_stage2Reused] = fcn_CarMesh3D_loadCache(stage2File, stage2Inputs, ...
        Enabled=logical(flag_useCache) && all(isfile(comparePictures)), FigNum=1);
    if flag_stage2Reused
        compareTotals = stage2Outputs.compareTotals;
    else
        compareFigure = figure('Visible','off');
        compareReport = fcn_CarMesh3D_compareToOriginal(vehicleMesh, originalMesh, Title=vehicleFiles.Name, ...
            OutputFile=fullfile(vehicleFiles.ChecksFolder,'check_04_compare'), ...
            OriginalCache=fullfile(cacheFolder,'stage2_originalRenders.mat'), FigNum=compareFigure.Number);
        close(compareFigure);
        compareTotals = compareReport.Totals;
        fcn_CarMesh3D_saveCache(stage2File, stage2Inputs, struct('compareTotals',compareTotals), FigNum=-1);
    end
end
exemplarBuildInfo = [];
buildSettings = struct('VehicleID',vehicleID, 'ModelFile',char(modelFile), 'BodyStyle',char(bodyStyle), ...
    'TargetFaces',targetFaces, 'ReduceWithBlender',reduceWithBlender, 'Symmetric',symmetricMesh, ...
    'WidthReference',char(widthReference), 'AddFloorPanel',addFloorPanel);
if flag_fromBodyStyle
    buildSettings.ExemplarID = vehicleMesh.BodyStyleInfo.ExemplarID;
    exemplarFiles = fcn_CarMesh3D_findVehicleFiles(vehicleMesh.BodyStyleInfo.ExemplarID, FigNum=-1);
    exemplarLoaded = load(exemplarFiles.MeshFile, 'vehicleMesh');
    if isfield(exemplarLoaded.vehicleMesh, 'BuildInfo')
        exemplarBuildInfo = exemplarLoaded.vehicleMesh.BuildInfo;
    end
end
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=-1);
% (the saved mesh is kept as it is, with its date, when nothing changed:
% vehicles made from it as an exemplar then stay up to date)
flag_saveMesh = true;
if flag_stage1Reused && flag_stage2Reused && isfile(vehicleFiles.MeshFile)
    savedMesh = load(vehicleFiles.MeshFile, 'vehicleMesh');
    if isfield(savedMesh.vehicleMesh, 'BuildInfo') && strcmp(savedMesh.vehicleMesh.BuildInfo.MeshVersion, meshVersion)
        flag_saveMesh = false;
        vehicleMesh.BuildInfo = savedMesh.vehicleMesh.BuildInfo;
        fprintf(1,'Kept %s: nothing changed (quality score %.1f)\n', vehicleFiles.MeshFile, vehicleMesh.BuildInfo.Quality.Score);
    end
end
if flag_saveMesh
    vehicleMesh.BuildInfo = fcn_CarMesh3D_makeBuildInfo(Script=[mfilename '.m'], Settings=buildSettings, ...
        CompareTotals=compareTotals, Validation=validationTable, Exemplar=exemplarBuildInfo, FigNum=1);
    save(vehicleFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
    fprintf(1,'Saved %s\n', vehicleFiles.MeshFile);
end

%% Stage 3 of the cache: the detail levels, the outline, and the checks
% (reused when the mesh's inputs, these steps' functions, and the check
% settings are unchanged, and their files exist)
stage3Functions = {'fcn_CarMesh3D_makeDetailLevels.m', 'fcn_CarMesh3D_makeOutline2D.m', 'fcn_CarMesh3D_runVehicleChecks.m', ...
    'fcn_CarMesh3D_plotVehicle.m', 'fcn_CarMesh3D_plotLabels.m', 'fcn_CarMesh3D_validateMesh.m', 'fcn_CarMesh3D_fillTestMotion.m', ...
    'fcn_CarMesh3D_plotScene.m', 'fcn_CarMesh3D_saveGifFrame.m', 'fcn_CarMesh3D_checkGroundContact.m', ...
    'fcn_CarMesh3D_fillCameraSettings.m', 'fcn_CarMesh3D_updateCamera.m'};
stage3Inputs = struct('Stage1',stage1Inputs, 'Functions',fcn_CarMesh3D_fileStamps(stage3Functions, FigNum=-1), ...
    'RunChecks',logical(flag_runChecks), 'ChecksToRun',{checksToRun}, 'SaveGifs',logical(flag_saveGifs));
stage3File = fullfile(cacheFolder, 'stage3_checks.mat');
stage3Products = {vehicleFiles.LevelsFile, vehicleFiles.OutlineFile};
if flag_runChecks
    stage3Products{end+1} = fullfile(vehicleFiles.ChecksFolder, 'check_summary.txt');
end
if flag_runChecks && flag_saveGifs
    stage3Products{end+1} = fullfile(vehicleFiles.ChecksFolder, 'check_09_drive.gif');
end
[stage3Outputs, flag_stage3Reused] = fcn_CarMesh3D_loadCache(stage3File, stage3Inputs, ...
    Enabled=logical(flag_useCache) && all(isfile(stage3Products)), FigNum=1);
if flag_stage3Reused
    if isfield(stage3Outputs, 'checkResults')
        checkResults = stage3Outputs.checkResults;
        disp(checkResults.ValidationTable);
    end
else
    checkResults = [];

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
    if flag_runChecks
        checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, vehicleFiles.ChecksFolder, ...
            Checks=checksToRun, SaveGifs=logical(flag_saveGifs), VehicleName=vehicleFiles.Name);
        fprintf(1,'Checks written to %s\n', vehicleFiles.ChecksFolder);
        disp(checkResults.ValidationTable);
    end
    fcn_CarMesh3D_saveCache(stage3File, stage3Inputs, struct('checkResults',checkResults), FigNum=-1);
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
end % Ends fcn_INTERNAL_editsBeforeFit

%% fcn_INTERNAL_wheelInnerParts
function vehicleMesh = fcn_INTERNAL_wheelInnerParts(vehicleMesh)
% Faces that lie wholly inside a wheel (within its tire's radius and
% width, seen from the side) but were not labeled as wheel (rim spokes,
% hubs, brake discs named like body or trim parts) are made part of that
% wheel, so they turn with it, and get a light alloy gray
wheelPart = find(strcmp(vehicleMesh.PartNames, 'wheel'), 1);
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
Nadded = 0;
for ith_wheel = 1:4
    wheelVertices = vertices(unique(faces(vehicleMesh.FaceWheelIndex==ith_wheel,:)),:);
    if isempty(wheelVertices)
        continue;
    end
    center = (min(wheelVertices) + max(wheelVertices))/2;
    radius = (max(wheelVertices(:,3)) - min(wheelVertices(:,3)))/2;
    yRange = [min(wheelVertices(:,2)) max(wheelVertices(:,2))] + [-0.05 0.05]*radius;
    cornerX = reshape(vertices(faces(:),1), [], 3);
    cornerY = reshape(vertices(faces(:),2), [], 3);
    cornerZ = reshape(vertices(faces(:),3), [], 3);
    inside = all(sqrt((cornerX - center(1)).^2 + (cornerZ - center(3)).^2) <= 0.97*radius, 2) & ...
        all(cornerY >= yRange(1) & cornerY <= yRange(2), 2) & vehicleMesh.FaceWheelIndex==0;
    vehicleMesh.FacePartIndex(inside) = wheelPart;
    vehicleMesh.FaceWheelIndex(inside) = ith_wheel;
    vehicleMesh.FaceColors(inside,:) = repmat([0.60 0.60 0.62], sum(inside), 1);
    if isfield(vehicleMesh,'FaceLightType')
        vehicleMesh.FaceLightType(inside) = 0;
    end
    Nadded = Nadded + sum(inside);
end
fprintf(1,'Wheel inner parts: %d faces added to the wheels\n', Nadded);
end % Ends fcn_INTERNAL_wheelInnerParts

%% fcn_INTERNAL_removeFaces
function vehicleMesh = fcn_INTERNAL_removeFaces(vehicleMesh, pattern)
% Deletes the faces whose '<materialName> <groupName>' text matches the
% regular expression (case ignored), and any vertices left unused
if isempty(pattern)
    return;
end
Nfaces = size(vehicleMesh.Faces,1);
materialText = repmat({''}, Nfaces, 1);
groupText = repmat({''}, Nfaces, 1);
if isfield(vehicleMesh,'FaceMaterialIndex') && isfield(vehicleMesh,'MaterialNames')
    hasMaterial = vehicleMesh.FaceMaterialIndex > 0;
    materialText(hasMaterial) = vehicleMesh.MaterialNames(vehicleMesh.FaceMaterialIndex(hasMaterial));
end
if isfield(vehicleMesh,'FaceGroupIndex') && isfield(vehicleMesh,'GroupNames')
    hasGroup = vehicleMesh.FaceGroupIndex > 0;
    groupText(hasGroup) = vehicleMesh.GroupNames(vehicleMesh.FaceGroupIndex(hasGroup));
end
faceText = strcat(materialText, {' '}, groupText);
keepFaces = cellfun(@isempty, regexpi(faceText, pattern, 'once'));
fprintf(1,'Deleted %d faces matching ''%s''\n', sum(~keepFaces), pattern);
% (every per-face field: Faces, FaceMaterialIndex, FaceTextureColors, ...)
faceFields = fieldnames(vehicleMesh);
for ith_field = 1:numel(faceFields)
    thisValue = vehicleMesh.(faceFields{ith_field});
    if ~strcmp(faceFields{ith_field},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==Nfaces
        vehicleMesh.(faceFields{ith_field}) = thisValue(keepFaces,:);
    end
end
[usedVertices, ~, newIndex] = unique(vehicleMesh.Faces(:));
vehicleMesh.Vertices = vehicleMesh.Vertices(usedVertices,:);
vehicleMesh.Faces = reshape(newIndex, size(vehicleMesh.Faces));
end % Ends fcn_INTERNAL_removeFaces

%% fcn_INTERNAL_scriptForCache
function scriptText = fcn_INTERNAL_scriptForCache(scriptFile)
% This script's text, as an input of the cached stages: every setting and
% step, but not the run flags (first look, checks, GIFs, cache) or the
% title note, which do not change the finished mesh (the first-look and
% comparison flags are inputs on their own)
scriptLines = splitlines(fileread(scriptFile));
scriptLines = scriptLines(~startsWith(strtrim(scriptLines), {'flag_','firstLookNote','checksToRun'}));
scriptText = strjoin(scriptLines, newline);
end % Ends fcn_INTERNAL_scriptForCache

%% fcn_INTERNAL_dropTextureFields
function vehicleMesh = fcn_INTERNAL_dropTextureFields(vehicleMesh)
% Removes the per-face texture fields of a .glb (their colors are already
% in FaceColors)
textureFields = {'FaceTextureColors','FaceTextureAlpha'};
if isstruct(vehicleMesh)
    vehicleMesh = rmfield(vehicleMesh, textureFields(isfield(vehicleMesh, textureFields)));
end
end % Ends fcn_INTERNAL_dropTextureFields

%% fcn_INTERNAL_savePicture
function fcn_INTERNAL_savePicture(figNum, fileName)
% Saves what a figure shows
figureHandle = figure(figNum);
drawnow;
frame = getframe(figureHandle);
imwrite(frame.cdata, fileName);
end % Ends fcn_INTERNAL_savePicture
