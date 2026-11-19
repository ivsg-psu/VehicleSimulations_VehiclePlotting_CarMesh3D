% script_test_fcn_CarMesh3D_runVehicleChecks.m
% Tests fcn_CarMesh3D_runVehicleChecks
% The standard checks for a vehicle: the standard test motion in the
% standard scene, saved as images and GIFs.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_runVehicleChecks
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_runVehicleChecks
%   % * Renamed from script_CarMesh3D_runVehicleChecks: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_runVehicleChecks
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

%% DEMO case: The still-picture checks for the sample car
figNum = 10001;
titleString = sprintf('DEMO case: The still-picture checks for the sample car');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
outputFolder = fullfile(tempdir,'CarMesh3D_runVehicleChecks_test');
if isfolder(outputFolder)
    rmdir(outputFolder,'s');
end
checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, ...
    Checks={'inputs','dimensions','labels','lightStates','groundContact'}, VehicleName='sample car', FigNum=figNum);

% Check variable types
assert(isstruct(checkResults));
assert(iscell(checkResults.Files));
assert(istable(checkResults.ValidationTable));
assert(islogical(checkResults.ContactFlags) || isnumeric(checkResults.ContactFlags));

% Check variable sizes
assert(length(checkResults.ContactFlags)==length(checkResults.TestMotion.Time));

% Check variable values: every listed file exists, and the expected ones
% are there
assert(all(cellfun(@isfile, checkResults.Files)));
expectedFiles = {'testMotion.csv','check_01_inputs.png','check_02_dimensions.png','check_02_dimensions.txt', ...
    'check_03_labels.png','check_04_lightStates.png','check_10_groundContact.png','check_summary.txt'};
for ith_file = 1:length(expectedFiles)
    assert(isfile(fullfile(outputFolder, expectedFiles{ith_file})), 'Missing %s', expectedFiles{ith_file});
end
% No GIFs were asked for
assert(isempty(dir(fullfile(outputFolder,'*.gif'))));
% The light-states picture is a 3 x 3 montage of the standard panel size
lightStatesPicture = imread(fullfile(outputFolder,'check_04_lightStates.png'));
assert(size(lightStatesPicture,2) == 3*480);

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

%% TEST case: One animation check, saved as a GIF of two side-by-side views
figNum = 20001;
titleString = sprintf('TEST case: One animation check, saved as a GIF of two side-by-side views');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, ...
    Checks={'body'}, PanelSize=[240 150], FigNum=figNum);

% Check variable values: the GIF has both views (2 panels wide) and every
% frame of the body segment
gifFile = fullfile(outputFolder,'check_06_body.gif');
assert(any(strcmp(checkResults.Files, gifFile)));
gifInfo = imfinfo(gifFile);
assert(gifInfo(1).Width == 2*240 && gifInfo(1).Height == 150);
bodySegment = checkResults.TestMotion.Segments(strcmp({checkResults.TestMotion.Segments.Name},'body'));
bodyRows = checkResults.TestMotion.Time >= bodySegment.StartTime & checkResults.TestMotion.Time <= bodySegment.EndTime;
assert(numel(gifInfo) == sum(bodyRows));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Playing an animation without saving it (SaveGifs=false)
figNum = 20002;
titleString = sprintf('TEST case: Playing an animation without saving it (SaveGifs=false)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

delete(fullfile(outputFolder,'*.gif'));
checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, ...
    Checks={'wheels'}, SaveGifs=false, PanelSize=[240 150], FigNum=figNum);

% Check variable values: nothing saved
assert(isempty(dir(fullfile(outputFolder,'*.gif'))));
assert(~any(endsWith(checkResults.Files,'.gif')));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, Checks={'dimensions'}, FigNum=[]);
assert(istable(checkResults.ValidationTable));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, Checks={'dimensions'}, FigNum=-1);
assert(istable(checkResults.ValidationTable));

% Clean up
close all force;
rmdir(outputFolder,'s');

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

%% FAIL case: An unknown check name
if 1==0
    fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, tempdir, Checks={'paint'});
end

%% FAIL case: A panel too small to see
if 1==0
    fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, tempdir, PanelSize=[50 50]);
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

