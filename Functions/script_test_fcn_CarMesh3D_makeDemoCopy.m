% script_test_fcn_CarMesh3D_makeDemoCopy.m
% Tests fcn_CarMesh3D_makeDemoCopy
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeDemoCopy
%   % * First write of the test script

%% Set up the workspace
close all;
testVehicleID = '2009_Honda_Fit_Sport';
testRoot = tempname;    % (a folder of its own, so the tests touch nothing else)
cleanupTestRoot = onCleanup(@() rmdir(testRoot, 's')); %#ok<NASGU>
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(testVehicleID);

%% Basic case: a copy with the vehicle's files, named by its ID
fig_num = 10001;
demoFiles = fcn_CarMesh3D_makeDemoCopy(testVehicleID, DemoFolder=testRoot, FigNum=fig_num);
assert(strcmp(demoFiles.ID, testVehicleID));
assert(strcmpi(demoFiles.Folder, fullfile(testRoot, testVehicleID)));
assert(strcmpi(demoFiles.SourceFolder, vehicleFiles.Folder));
assert(demoFiles.HasMesh && isfile(demoFiles.MeshFile));
assert(isfile(demoFiles.OutlineFile) == vehicleFiles.HasOutline);
assert(isfolder(fullfile(demoFiles.Folder, 'photos')) == isfolder(fullfile(vehicleFiles.Folder, 'photos')));
assert(~strcmpi(demoFiles.MeshFile, vehicleFiles.MeshFile));

%% The copy's folder is found as a vehicle (by its path)
fig_num = 10002;
copyFiles = fcn_CarMesh3D_findVehicleFiles(demoFiles.Folder, FigNum=fig_num);
assert(strcmp(copyFiles.ID, testVehicleID));
assert(strcmpi(copyFiles.MeshFile, demoFiles.MeshFile));

%% Each call makes a fresh copy: changes made to the old copy are gone
fig_num = 10003;
markerFile = fullfile(demoFiles.Folder, 'changed_in_demo.txt');
writelines("a change made in the demo", markerFile);
vehicleMarker = fullfile(vehicleFiles.Folder, 'changed_in_demo.txt');
assert(~isfile(vehicleMarker), 'The change reached the vehicle''s own folder');
demoFiles = fcn_CarMesh3D_makeDemoCopy(testVehicleID, DemoFolder=testRoot, FigNum=fig_num);
assert(~isfile(markerFile));
assert(isfile(demoFiles.MeshFile));

%% Default folder: the computer's temporary folder
fig_num = 10004;
defaultFiles = fcn_CarMesh3D_makeDemoCopy(testVehicleID, FigNum=fig_num);
assert(strcmpi(defaultFiles.Folder, fullfile(tempdir, 'CarMesh3D_demo', testVehicleID)));

%% Fast mode
fig_num = -1;
demoFiles = fcn_CarMesh3D_makeDemoCopy(testVehicleID, DemoFolder=testRoot, FigNum=fig_num);
assert(isfile(demoFiles.MeshFile));

%% Errors
% A vehicle with no folder
try
    fcn_CarMesh3D_makeDemoCopy('1900_No_Such_Car', DemoFolder=testRoot);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:noVehicle'), ME.message);
end
% A copy that would replace the vehicle's own folder
try
    fcn_CarMesh3D_makeDemoCopy(testVehicleID, DemoFolder=fileparts(vehicleFiles.Folder));
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end
assert(isfile(vehicleFiles.MeshFile), 'The vehicle''s mesh must still be there');

fprintf(1, 'All tests of fcn_CarMesh3D_makeDemoCopy passed.\n');
