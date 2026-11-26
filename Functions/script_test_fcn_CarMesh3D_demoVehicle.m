% script_test_fcn_CarMesh3D_demoVehicle
% Tests of fcn_CarMesh3D_demoVehicle: the repo's demo vehicle, a user's
% own choice (saved as a preference and put back at the end), and the GUI
% test vehicle.
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_demoVehicle
%   % * First write of the tests

%% Set up the workspace
close all;

% (this user's own demo vehicle, put back at the end even if a test stops)
flagHadDemoPref = ispref('CarMesh3D', 'DemoVehicle');
demoPrefBefore = '';
if flagHadDemoPref
    demoPrefBefore = getpref('CarMesh3D', 'DemoVehicle');
end
cleanupDemoPref = onCleanup(@() fcn_INTERNAL_restoreDemoPref(flagHadDemoPref, demoPrefBefore));
fcn_CarMesh3D_demoVehicle(FlagReset=true, FigNum=-1);

%% DEMO case: the demo vehicle, printed
fig_num = 10001;
fprintf(1,'Figure %d: DEMO case: the demo vehicle\n', fig_num);
[vehicleID, info] = fcn_CarMesh3D_demoVehicle(FigNum=fig_num);
assert(ischar(vehicleID) && ~isempty(vehicleID));
assert(strcmp(info.Source, 'repo') && strcmp(info.ID, info.RepoDemoID));
assert(info.Files.Found && info.Files.HasMesh, 'The demo vehicle is a finished vehicle');
assert(isempty(findall(0,'Type','figure')), 'No figure is opened');

%% TEST case: the GUI test vehicle
fig_num = 20001;
fprintf(1,'Figure %d: TEST case: the GUI test vehicle\n', fig_num);
[guiID, guiInfo] = fcn_CarMesh3D_demoVehicle(Which='guiTest', FigNum=-1);
assert(strcmp(guiInfo.Source, 'guiTest') && strcmp(guiID, guiInfo.GUITestID));
assert(guiInfo.Files.Found, 'The GUI test vehicle exists');

%% TEST case: a user's own choice, used by demos but not by tests
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: a user''s own choice\n', fig_num);
repoID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);
% (another finished vehicle with photos, if the library has one)
libraryFolder = fullfile(fileparts(fileparts(which('fcn_CarMesh3D_demoVehicle'))), 'Data');
photoFiles = dir(fullfile(libraryFolder, '**', 'photos', 'ViewInDegrees_*'));
otherID = '';
for ith_file = 1:numel(photoFiles)
    vehicleFolder = fileparts(photoFiles(ith_file).folder);
    [~, candidateID] = fileparts(vehicleFolder);
    if ~strcmp(candidateID, repoID) && isfile(fullfile(vehicleFolder, ['vehicleMesh_' candidateID '.mat'])) ...
            && ~isempty(dir(fullfile(vehicleFolder, 'script_CarMesh3D_vehicle_*.m')))
        otherID = candidateID;
        break;
    end
end
if ~isempty(otherID)
    fcn_CarMesh3D_demoVehicle(Set=otherID, FigNum=-1);
    [chosenID, chosenInfo] = fcn_CarMesh3D_demoVehicle(FigNum=-1);
    assert(strcmp(chosenID, otherID) && strcmp(chosenInfo.Source, 'preference'), 'Demos use the user''s choice');
    assert(strcmp(fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1), repoID), 'Tests use the repo''s choice');
    fcn_CarMesh3D_demoVehicle(FlagReset=true, FigNum=-1);
    assert(strcmp(fcn_CarMesh3D_demoVehicle(FigNum=-1), repoID), 'Reset: the repo''s choice again');
else
    fprintf(1, '    (no second finished vehicle with photos in the library: skipped)\n');
end

%% TEST case: a vehicle that cannot be the demo vehicle is refused
fig_num = 20003;
fprintf(1,'Figure %d: TEST case: refused choices\n', fig_num);
try
    fcn_CarMesh3D_demoVehicle(Set='9999_No_Such_Vehicle', FigNum=-1);
    error('A vehicle that does not exist was accepted');
catch caughtError
    assert(strcmp(caughtError.identifier, 'CarMesh3D:demoVehicle'), caughtError.message);
end
assert(~ispref('CarMesh3D', 'DemoVehicle'), 'Nothing saved for a refused vehicle');

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases\n', fig_num);
assert(strcmp(fcn_CarMesh3D_demoVehicle(FigNum=[]), fcn_CarMesh3D_demoVehicle(FigNum=-1)));
Niterations = 50;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=[]);
end
slowTime = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);
end
fastTime = toc;
fprintf(1, 'Average time, normal mode: %.4f s; fast mode: %.4f s\n', slowTime/Niterations, fastTime/Niterations);

clear cleanupDemoPref;   % (this user's own choice put back)
fprintf(1, 'All tests of fcn_CarMesh3D_demoVehicle passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: Which not known
    fcn_CarMesh3D_demoVehicle(Which='mine');

    %% FAIL case: Set not text
    fcn_CarMesh3D_demoVehicle(Set=42);
end

%% Functions follow
function fcn_INTERNAL_restoreDemoPref(flagHadDemoPref, demoPrefBefore)
% Puts back this user's own demo vehicle as it was before the tests
try
    if flagHadDemoPref
        setpref('CarMesh3D', 'DemoVehicle', demoPrefBefore);
    elseif ispref('CarMesh3D', 'DemoVehicle')
        rmpref('CarMesh3D', 'DemoVehicle');
    end
catch
end
end % Ends fcn_INTERNAL_restoreDemoPref
