% script_CarMesh3D_loadVehicleSpec.m
% Tests fcn_CarMesh3D_loadVehicleSpec
% Loads vehicle data from IVSG vehicleParameters .mat files (or saved CarMesh3D specs).

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_loadVehicleSpec
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_loadVehicleSpec
%   % * (fill in items here)


%% Set up the workspace
close all

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Load the 2013 Toyota Prius Four vehicleParameters file
figNum = 10001;
titleString = sprintf('DEMO case: Load the 2013 Toyota Prius Four vehicleParameters file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fcn_INTERNAL_priusFile, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');
disp(vehicleSpec);

% Check variable types
assert(isstruct(vehicleSpec));
assert(ischar(vehicleSpec.Name));

% Check variable values (from the file)
assert(isequal(vehicleSpec.Name,'2013 Toyota Prius Four'));
assert(abs(vehicleSpec.OverallLength - 4.48)<1e-9);
assert(abs(vehicleSpec.OverallWidth - 1.745)<1e-9);
assert(abs(vehicleSpec.WidthWithMirrors - 2.02)<1e-9);
assert(abs(vehicleSpec.OverallHeight - 1.49)<1e-9);
assert(abs(vehicleSpec.Wheelbase - 2.70)<1e-9);
assert(abs(vehicleSpec.TrackFront - 1.524)<1e-9);
assert(abs(vehicleSpec.TrackRear - 1.519)<1e-9);
assert(abs(vehicleSpec.FrontOverhang - 0.924)<1e-9);
assert(abs(vehicleSpec.RearOverhang - 0.856)<1e-9);
% P195/65R15: 2*195*0.65 mm + 15 in = 253.5 mm + 381 mm = 634.5 mm
assert(abs(vehicleSpec.TireDiameter - 0.6345)<1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: A saved CarMesh3D spec loads back the same
figNum = 20001;
titleString = sprintf('TEST case: A saved CarMesh3D spec loads back the same');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

originalSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan');
savedFile = fullfile(tempdir,'CarMesh3D_testSavedSpec.mat');
save(savedFile,'originalSpec');
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(savedFile);
assert(abs(vehicleSpec.OverallLength - originalSpec.OverallLength)<1e-12);
assert(abs(vehicleSpec.TireDiameter - originalSpec.TireDiameter)<1e-12);
assert(isequal(vehicleSpec.Source, savedFile));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Units in mm are converted to meters
figNum = 20002;
titleString = sprintf('TEST case: Units in mm are converted to meters');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

loaded = load(fcn_INTERNAL_priusFile);
vehicleParameters = loaded.vehicleParameters;
vehicleParameters.DistancesLength = 4480;
vehicleParameters.DistancesLength_Units = 'mm';
mmFile = fullfile(tempdir,'CarMesh3D_testMM.mat');
save(mmFile,'vehicleParameters');
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(mmFile);
assert(abs(vehicleSpec.OverallLength - 4.48)<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A body color can be added
figNum = 20003;
titleString = sprintf('TEST case: A body color can be added');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fcn_INTERNAL_priusFile, BodyColor=[0.7 0.7 0.72]);
assert(isequal(vehicleSpec.BodyColor,[0.7 0.7 0.72]));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Inconsistent overhangs give a warning
figNum = 20004;
titleString = sprintf('TEST case: Inconsistent overhangs give a warning');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

loaded = load(fcn_INTERNAL_priusFile);
vehicleParameters = loaded.vehicleParameters;
vehicleParameters.DistancesRearOverhang = 0.5; % Should be 0.856
badFile = fullfile(tempdir,'CarMesh3D_testBadOverhang.mat');
save(badFile,'vehicleParameters');
lastwarn('');
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(badFile); %#ok<NASGU>
[warningMessage,~] = lastwarn;
assert(contains(warningMessage,'Rear overhang'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: The Prius spec drives the whole workflow
figNum = 20005;
titleString = sprintf('TEST case: The Prius spec drives the whole workflow');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fcn_INTERNAL_priusFile, BodyColor=[0.75 0.75 0.78]);
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
disp(validationTable);
assert(all(validationTable.Pass));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fcn_INTERNAL_priusFile, FigNum=[]);
assert(isstruct(vehicleSpec));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fcn_INTERNAL_priusFile, FigNum=-1);
assert(isstruct(vehicleSpec));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

dataFile = fcn_INTERNAL_priusFile;

Niterations = 50;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(dataFile, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(dataFile, FigNum=-1);
end
fast_method = toc;

% Input checks turned off by environment variable. The code reads these
% variables only when both are set. Save the user's settings and restore
% them afterward, even if a call errors.
old_check_inputs = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
old_do_debug     = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS","0");
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG","0");
try
    tic;
    for ith_test = 1:Niterations
        vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(dataFile, FigNum=[]);
    end
    env_method = toc;
catch ME
    setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
    setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);
    rethrow(ME);
end
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

barLabels = {'Normal mode','Checks off (environment variable)','Fast mode (FigNum=-1)'};
X = categorical(barLabels);
X = reordercats(X,barLabels); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method env_method fast_method]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')
title('fcn_CarMesh3D_loadVehicleSpec: time per call','Interpreter','none');
fprintf(1,'Average time per call (ms): normal %.3f, checks off by environment variable %.3f, fast mode %.3f\n',Y(1),Y(2),Y(3));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: File does not exist
if 1==0
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec('no_such_file.mat');
end

%% FAIL case: Not a .mat file
if 1==0
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec('fcn_CarMesh3D_loadVehicleSpec.m');
end

%% FAIL case: A .mat file with no structure
if 1==0
    x = 3; noStructFile = fullfile(tempdir,'CarMesh3D_noStruct.mat'); save(noStructFile,'x'); vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(noStructFile);
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

%% fcn_INTERNAL_priusFile
function dataFile = fcn_INTERNAL_priusFile
% Full path to the example vehicleParameters file in the Data folder
functionsFolder = fileparts(which('fcn_CarMesh3D_loadVehicleSpec'));
dataFile = fullfile(fileparts(functionsFolder),'Data','vehicleParameters_2013ToyotaPriusFour.mat');
assert(exist(dataFile,'file')==2, 'Example data file not found: %s', dataFile);
end % Ends fcn_INTERNAL_priusFile
