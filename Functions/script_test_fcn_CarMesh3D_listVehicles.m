% script_test_fcn_CarMesh3D_listVehicles.m
% Tests fcn_CarMesh3D_listVehicles
% The finished vehicles, with their quality scores and whether each mesh
% is up to date.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_listVehicles
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_listVehicles
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

%% DEMO case: The finished vehicles in the Data folder
figNum = 10001;
titleString = sprintf('DEMO case: The finished vehicles in the Data folder');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

vehicleTable = fcn_CarMesh3D_listVehicles(FigNum=figNum);

% Check variable types
assert(istable(vehicleTable) && isstring(vehicleTable.ID) && isnumeric(vehicleTable.Score));

% Check variable sizes
assert(height(vehicleTable) >= 1);

% Check variable values: every listed vehicle is finished; the exemplars
% are marked; every status is one of the five
assert(all(vehicleTable.Faces > 0));
assert(any(vehicleTable.IsExemplar & vehicleTable.ID=="2021_Subaru_Outback_LimitedXT"));
assert(all(ismember(vehicleTable.Status, ["up to date","out of date","exemplar changed","no stamp","no mesh"])));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Up to date, out of date, no stamp, and an exemplar made again since
figNum = 20001;
titleString = sprintf('TEST case: Up to date, out of date, no stamp, and an exemplar made again since');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (a test Data folder: four tiny "vehicles" with made-up meshes)
testData = fullfile(tempdir, 'CarMesh3D_listTest');
if isfolder(testData)
    rmdir(testData, 's');
end
mkdir(testData);
styleList = readtable(fullfile(fileparts(fileparts(which('fcn_CarMesh3D_listVehicles'))), 'Data', 'bodyStyles.csv'), ...
    'TextType','char', 'Delimiter',',', 'VariableNamingRule','preserve');
styleList.Exemplars = repmat({''}, height(styleList), 1);
styleList.Exemplars{strcmp(styleList.BodyStyle, 'sedan')} = '2020_Test_SedanA_Base';
writetable(styleList, fullfile(testData, 'bodyStyles.csv'));
[~, ~, currentMeshVersion] = fcn_CarMesh3D_version;
tinyMesh = struct('Vertices', [0 0 0; 1 0 0; 0 1 0], 'Faces', [1 2 3]);
tinySpec = struct('OverallLength', 4.5, 'OverallWidth', 1.8, 'OverallHeight', 1.4);
exemplarInfo = fcn_CarMesh3D_makeBuildInfo(Settings=struct('VehicleID','2020_Test_SedanA_Base'));
oldInfo = exemplarInfo;
oldInfo.MeshVersion = '2026_01_01';
genericInfo = fcn_CarMesh3D_makeBuildInfo(Settings=struct('BodyStyle','sedan'), Exemplar=exemplarInfo);
genericInfo.Date = '2020-01-01 00:00';                     % (made before the exemplar)
tinyGeneric = tinyMesh;
tinyGeneric.BodyStyleInfo = struct('ExemplarID','2020_Test_SedanA_Base');
fcn_INTERNAL_saveVehicle(testData, 'Sedan', '2020_Test_SedanA_Base', tinyMesh, tinySpec, exemplarInfo);
fcn_INTERNAL_saveVehicle(testData, 'Sedan', '2021_Test_SedanB_Base', tinyMesh, tinySpec, oldInfo);
fcn_INTERNAL_saveVehicle(testData, 'Sedan', '2022_Test_SedanC_Base', tinyMesh, tinySpec, []);
fcn_INTERNAL_saveVehicle(testData, 'Sedan', '2023_Test_SedanD_Base', tinyGeneric, tinySpec, genericInfo);
mkdir(fullfile(testData, 'BodyStyles', 'Sedan', '2024_Test_SedanE_Base'));    % (no mesh)

vehicleTable = fcn_CarMesh3D_listVehicles(DataFolder=testData, FigNum=figNum);
assert(height(vehicleTable)==4);                                               % (the unfinished one is left out)
statusOf = @(vehicleID) vehicleTable.Status(vehicleTable.ID==vehicleID);
assert(statusOf("2020_Test_SedanA_Base")=="up to date" && vehicleTable.IsExemplar(vehicleTable.ID=="2020_Test_SedanA_Base"));
assert(statusOf("2021_Test_SedanB_Base")=="out of date");
assert(statusOf("2022_Test_SedanC_Base")=="no stamp" && isnan(vehicleTable.Score(vehicleTable.ID=="2022_Test_SedanC_Base")));
assert(statusOf("2023_Test_SedanD_Base")=="exemplar changed" && vehicleTable.FromBodyStyle(vehicleTable.ID=="2023_Test_SedanD_Base"));
assert(all(vehicleTable.MeshVersion(vehicleTable.ID=="2020_Test_SedanA_Base")==currentMeshVersion));
allTable = fcn_CarMesh3D_listVehicles(DataFolder=testData, IncludeUnfinished=true);
assert(height(allTable)==5 && allTable.Status(allTable.ID=="2024_Test_SedanE_Base")=="no mesh");
rmdir(testData, 's');

%% Fast Mode Tests



%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
vehicleTable = fcn_CarMesh3D_listVehicles(FigNum=[]);
assert(istable(vehicleTable));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleTable = fcn_CarMesh3D_listVehicles(FigNum=-1);
assert(istable(vehicleTable));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: A Data folder that does not exist
if 1==0
    fcn_CarMesh3D_listVehicles(DataFolder='C:\no\such\folder');
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

%% fcn_INTERNAL_saveVehicle
function fcn_INTERNAL_saveVehicle(dataFolder, styleFolder, vehicleID, vehicleMesh, vehicleSpec, buildInfo)
% Saves a made-up finished vehicle in a test Data folder
vehicleFolder = fullfile(dataFolder, 'BodyStyles', styleFolder, vehicleID);
mkdir(vehicleFolder);
if ~isempty(buildInfo)
    vehicleMesh.BuildInfo = buildInfo;
end
save(fullfile(vehicleFolder, sprintf('vehicleMesh_%s.mat', vehicleID)), 'vehicleMesh', 'vehicleSpec');
end % Ends fcn_INTERNAL_saveVehicle
