% script_test_fcn_CarMesh3D_reviewInput.m
% Tests fcn_CarMesh3D_reviewInput. Reads only (no file is written, except
% a temporary demo copy that is deleted).

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewInput
%   % * First write

% TO-DO:
%
% (none)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);

%% DEMO case: the demo vehicle
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: %s\n', figNum, vehicleID);
vehicle = fcn_CarMesh3D_reviewInput(vehicleID);
assert(strcmp(vehicle.ID, vehicleID) && ~isempty(vehicle.Name));
assert(isfield(vehicle.Mesh, 'Vertices') && isfield(vehicle.Mesh, 'Faces') && isfield(vehicle.Mesh, 'FaceAlpha'));
assert(~isempty(vehicle.BodyStyle), 'The body style');

%% TEST case: a structure given is returned as it is
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: a structure\n', figNum);
assert(isequaln(fcn_CarMesh3D_reviewInput(vehicle), vehicle));   % (isequaln: a mesh may hold NaN)

%% TEST case: a copy kept outside the repo takes the repo vehicle's body style
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: a demo copy\n', figNum);
copyRoot = tempname;
copyFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=copyRoot, FigNum=-1);
cleanupCopy = onCleanup(@() rmdir(copyRoot, 's'));
copyVehicle = fcn_CarMesh3D_reviewInput(copyFiles.Folder);
assert(strcmp(copyVehicle.BodyStyle, vehicle.BodyStyle), 'The repo vehicle''s style');
assert(startsWith(copyVehicle.Files.Folder, copyRoot), 'The copy''s own files');
clear cleanupCopy;

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode\n', figNum);
vehicleFast = fcn_CarMesh3D_reviewInput(vehicleID, FigNum=-1);
assert(strcmp(vehicleFast.ID, vehicleID));

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_reviewInput('1999_No_Such_Vehicle');
    error('test:noError', 'A vehicle that does not exist was taken');
catch caughtError
    assert(contains(caughtError.message, 'No finished mesh'), caughtError.message);
end
try
    fcn_CarMesh3D_reviewInput(struct('a', 1));
    error('test:noError', 'A wrong structure was taken');
catch caughtError
    assert(contains(caughtError.message, 'must come from'), caughtError.message);
end

fprintf(1,'All tests of fcn_CarMesh3D_reviewInput passed\n');
