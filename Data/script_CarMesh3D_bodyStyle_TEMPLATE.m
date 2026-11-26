%% script_CarMesh3D_bodyStyle_TEMPLATE
% Makes a vehicle's 3D mesh from its BODY STYLE and its dimensions, when
% no 3D model of the vehicle itself is at hand: the style's exemplar (a
% finished, checked vehicle, such as the 2021 Subaru Outback for station
% wagons) is refit to this vehicle's length, width, height, wheelbase,
% tracks, overhangs, ground clearance, and tires, labels and all
% (fcn_CarMesh3D_fillBodyStyleMesh). A few minutes of work: look up the
% dimensions, fill them in below, and run.
%
% HOW TO USE:
%   1. Copy this script anywhere and rename it for your vehicle.
%   2. Pick the body style (see the list printed by Step 0, or
%      Data\bodyStyles.csv; only styles with an exemplar give a real shape).
%   3. Fill in the dimensions (meters) from the maker's published
%      specifications (Wikipedia, the maker's site, edmunds.com, ...), or
%      point parametersFile at a vehicleParameters .mat file.
%   4. Run. The mesh is shown in 3D (by part) and as a 2D outline, its
%      dimensions are checked against yours, and it is saved in
%      outputFolder.
%
% For a vehicle that will be kept in the repository, with its own folder,
% checks, and detail levels, use Data\script_CarMesh3D_vehicle_TEMPLATE.m
% instead (set modelFile = '' and bodyStyle there).
%
% This script was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_bodyStyle_TEMPLATE
%   % * Wrote the script originally (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_bodyStyle_TEMPLATE
%   % * (none yet)

%% Vehicle settings (the only part to change)

% The body style: 'sedan', 'liftback', 'stationWagon', 'coupe',
% 'crossover', 'pickupCrewCab', 'compactCargoVan', 'fullSizeCargoVan', ...
bodyStyle = 'stationWagon';

% Either a vehicleParameters file (leave '' to use the numbers below) ...
parametersFile = '';

% ... or the dimensions, in meters (the numbers here are only an example,
% roughly a 2018 Volvo V90: replace them with your vehicle's published
% figures)
vehicleName      = '2018 Volvo V90 T5';
overallLength    = 4.936;
overallWidth     = 1.879;     % without mirrors
widthWithMirrors = [];        % [] if not published (estimated from the exemplar)
overallHeight    = 1.475;
wheelbase        = 2.941;
trackFront       = 1.652;
trackRear        = 1.643;
frontOverhang    = [];        % [] if not published
groundClearance  = 0.152;
tireSize         = '245/45R18';
bodyColor        = [0.45 0.47 0.50];   % RGB, 0 to 1

% Where to save the finished mesh ('' for the current folder)
outputFolder = '';

%% Step 0: The body styles, and which have exemplars
thisFolder = fileparts(mfilename('fullpath'));
if isempty(which('fcn_CarMesh3D_fillBodyStyleMesh'))
    % (the CarMesh3D folder: the first folder above this one that holds
    % Functions; or add CarMesh3D\Functions to the path yourself)
    rootFolder = thisFolder;
    while ~isfolder(fullfile(rootFolder,'Functions')) && ~strcmp(rootFolder, fileparts(rootFolder))
        rootFolder = fileparts(rootFolder);
    end
    addpath(fullfile(rootFolder,'Functions'));
end
bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=-1);
fprintf(1,'Body styles with exemplars:\n');
for ith_style = find([bodyStyles.HasExemplar])
    fprintf(1,'   %-18s %s\n', bodyStyles(ith_style).BodyStyle, strjoin(strrep(bodyStyles(ith_style).ExemplarIDs,'_',' '), '; '));
end

%% Step 1: The vehicle's specification
if ~isempty(parametersFile)
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(parametersFile, BodyColor=bodyColor);
else
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Name=vehicleName, ...
        OverallLength=overallLength, OverallWidth=overallWidth, OverallHeight=overallHeight, ...
        Wheelbase=wheelbase, TrackFront=trackFront, TrackRear=trackRear, ...
        GroundClearance=groundClearance, TireSize=tireSize, BodyColor=bodyColor, FigNum=-1);
    if ~isempty(widthWithMirrors)
        vehicleSpec.WidthWithMirrors = widthWithMirrors;
    end
    if ~isempty(frontOverhang)
        vehicleSpec.FrontOverhang = frontOverhang;
    end
end

%% Step 2: The mesh, from the body style's exemplar
vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh(bodyStyle, vehicleSpec, FigNum=-1);
fprintf(1,'%s\n   width: %s\n', vehicleMesh.Source, vehicleMesh.BodyStyleInfo.WidthNote);
% (the refit clears the normals; this remakes them, and nothing else: the
% exemplar was already reduced and repaired)
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, 'StitchTolerance',0, 'EdgeSmoothing',0, ...
    TargetFaces=size(vehicleMesh.Faces,1), FlagSymmetric=false, PartShares={}, FlagVisibilityCheck=false);
fprintf(1,'Finished mesh: %d faces\n', size(vehicleMesh.Faces,1));

%% Step 3: Check the dimensions against yours
validation = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleMesh.VehicleSpec, FigNum=-1);
disp(validation);
checked = validation(~ismissing(validation.Pass), :);
if all(checked.Pass)
    fprintf(1,'All dimensions match.\n');
else
    warning('Dimensions that do not match: %s', strjoin(cellstr(checked.Quantity(~checked.Pass)), ', '));
end

%% Step 4: Look at it: 3D (by part, and in color) and the 2D outline
fcn_CarMesh3D_plotLabels(vehicleMesh, Title=sprintf('%s (from the %s exemplar)', vehicleSpec.Name, bodyStyle), FigNum=1);
figure(2); clf;
fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=2);
title(vehicleSpec.Name, 'Interpreter','none');
vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh, FigNum=3);

%% Step 5: Save it
if isempty(outputFolder)
    outputFolder = pwd;
end
fileStem = regexprep(vehicleSpec.Name, '[^A-Za-z0-9]+', '_');
meshFile = fullfile(outputFolder, sprintf('vehicleMesh_%s.mat', fileStem));
save(meshFile, 'vehicleMesh', 'vehicleSpec', 'vehicleOutline');
fprintf(1,'Saved %s\n', meshFile);
