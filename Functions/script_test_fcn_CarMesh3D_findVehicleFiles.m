% script_test_fcn_CarMesh3D_findVehicleFiles.m
% Tests fcn_CarMesh3D_findVehicleFiles
% The standard file and folder names for vehicles in the Data folder
% (YEAR_Make_Model_Trimline).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findVehicleFiles
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findVehicleFiles
%   % * Renamed from script_CarMesh3D_findVehicleFiles: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findVehicleFiles
%   % * Tests for vehicles filed by body style (Data\BodyStyles\<Style>\<ID>)
%   %   % and samples (Data\Samples\<ID>), model files left in the
%   %   % vehicle's folder, a new vehicle's BodyStyle, and a repeated ID
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findVehicleFiles
%   % * A someday vehicle (DataSomeday) is found by its ID, not listed

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findVehicleFiles
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

%% DEMO case: The files for the 2013 Prius, and a list of all vehicles
figNum = 10001;
titleString = sprintf('DEMO case: The files for the 2013 Prius, and a list of all vehicles');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
allVehicles = fcn_CarMesh3D_findVehicleFiles('', FigNum=figNum);

% Check variable types
assert(isstruct(priusFiles));
assert(isstruct(allVehicles));

% Check variable sizes
assert(isscalar(priusFiles));
assert(length(allVehicles) >= 2);

% Check variable values
assert(strcmp(priusFiles.Name,'2013 Toyota Prius Four') && priusFiles.Year==2013);
assert(endsWith(priusFiles.ParametersFile, fullfile('2013_Toyota_Prius_Four','vehicleParameters_2013_Toyota_Prius_Four.mat')));
assert(priusFiles.HasParameters);
assert(any(strcmp({allVehicles.ID},'2014_Ford_TransitConnect_XLTCargoLWB')));
assert(strcmp(priusFiles.BodyStyle,'liftback') && strcmp(priusFiles.BodyStyleFolder,'Liftback'));
assert(endsWith(priusFiles.Folder, fullfile('BodyStyles','Liftback','2013_Toyota_Prius_Four')));
assert(priusFiles.Found && ~priusFiles.IsSample && ~isempty(priusFiles.ModelFiles));
sampleFiles = allVehicles(strcmp({allVehicles.ID},'2026_CarMesh3D_Sample_GenericSedan'));
assert(isscalar(sampleFiles) && sampleFiles.IsSample && isempty(sampleFiles.BodyStyle));

% Make sure plot did NOT open up (the list is printed, not plotted)
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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

%% TEST case: A new vehicle gets its standard names before any file exists
figNum = 20001;
titleString = sprintf('TEST case: A new vehicle gets its standard names before any file exists');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

newFiles = fcn_CarMesh3D_findVehicleFiles('2019_Toyota_RAV4_XLE');

% Check variable values
assert(strcmp(newFiles.Make,'Toyota') && strcmp(newFiles.Model,'RAV4') && strcmp(newFiles.Trim,'XLE'));
assert(endsWith(newFiles.ScriptFile, 'script_CarMesh3D_vehicle_2019_Toyota_RAV4_XLE.m'));
assert(endsWith(newFiles.MeshFile, 'vehicleMesh_2019_Toyota_RAV4_XLE.mat'));
assert(~newFiles.HasParameters && ~newFiles.HasMesh);
assert(endsWith(newFiles.LevelsFile, 'vehicleLevels_2019_Toyota_RAV4_XLE.mat') && ~newFiles.HasLevels);
assert(~newFiles.Found && isempty(newFiles.BodyStyle));

% (with its body style, its paths are under Data\BodyStyles)
newFiles = fcn_CarMesh3D_findVehicleFiles('2019_Toyota_RAV4_XLE', BodyStyle='crossover');
assert(endsWith(newFiles.Folder, fullfile('BodyStyles','Crossover','2019_Toyota_RAV4_XLE')));
assert(strcmp(newFiles.BodyStyle,'crossover') && ~newFiles.Found);

%% TEST case: A test Data folder: a download left in the vehicle's folder, and a repeated ID
figNum = 20002;
titleString = sprintf('TEST case: A test Data folder: a download left in the vehicle''s folder, and a repeated ID');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

testData = fullfile(tempdir, 'CarMesh3D_findTest');
if isfolder(testData)
    rmdir(testData, 's');
end
mkdir(fullfile(testData, 'BodyStyles', 'Sedan', '2020_Test_Sedan_Base'));
fileID = fopen(fullfile(testData, 'BodyStyles', 'Sedan', '2020_Test_Sedan_Base', 'test_sedan.glb'), 'w');
fclose(fileID);
testFiles = fcn_CarMesh3D_findVehicleFiles('2020_Test_Sedan_Base', DataFolder=testData);
assert(strcmp(testFiles.ModelFolder, testFiles.Folder) && isscalar(testFiles.ModelFiles));
assert(endsWith(testFiles.ModelFiles{1}, 'test_sedan.glb') && strcmp(testFiles.BodyStyle, 'sedan'));

% (the same ID filed twice)
mkdir(fullfile(testData, 'BodyStyles', 'Coupe', '2020_Test_Sedan_Base'));
flagFailed = false;
try
    fcn_CarMesh3D_findVehicleFiles('2020_Test_Sedan_Base', DataFolder=testData);
catch
    flagFailed = true;
end
assert(flagFailed);
warningState = warning('off', 'CarMesh3D:repeatedID');
lastwarn('');
fcn_CarMesh3D_findVehicleFiles('', DataFolder=testData);
[~, warningID] = lastwarn;
warning(warningState);
assert(strcmp(warningID, 'CarMesh3D:repeatedID'));
rmdir(testData, 's');

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A someday vehicle (in DataSomeday, beside Data) is found by its ID but not listed
% (the 2020 Supra, moved to DataSomeday on 2026_11_24 for its missing
% steering wheel; if it is ever moved back, use another someday vehicle)
fig_num = 20004;
somedayID = '2020_Toyota_Supra_30';
somedayFiles = fcn_CarMesh3D_findVehicleFiles(somedayID, FigNum=-1);
assert(somedayFiles.Found && somedayFiles.IsSomeday && somedayFiles.HasScript, 'A someday vehicle is found by its ID');
assert(contains(somedayFiles.Folder, fullfile('DataSomeday','BodyStyles','SportsCar',somedayID)));
assert(strcmp(somedayFiles.BodyStyle, 'sportsCar'), 'Its body style is read from DataSomeday\BodyStyles');
listedNow = fcn_CarMesh3D_findVehicleFiles('', FigNum=-1);
assert(~any(strcmp({listedNow.ID}, somedayID)) && ~any([listedNow.IsSomeday]), 'Listing all vehicles lists Data only');
priusAgain = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
assert(~priusAgain.IsSomeday);
% (with a DataFolder given, DataSomeday is not searched)
noSomeday = fcn_CarMesh3D_findVehicleFiles(somedayID, DataFolder=fileparts(priusAgain.Folder), FigNum=-1);
assert(~noSomeday.Found);

%% TEST case: A copy kept elsewhere reads the repo's download from LargeData
% (since 2026_11_24 the downloads live in LargeData; a demo copy has no
% model folder of its own. Skipped when LargeData is not on this computer.)
fig_num = 20005;
fitFiles = fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport', FigNum=-1);
if contains(fitFiles.ModelFolder, 'LargeData')
    copyRoot = tempname;
    copyFiles = fcn_CarMesh3D_makeDemoCopy('2009_Honda_Fit_Sport', DemoFolder=copyRoot, FigNum=-1);
    copyFound = fcn_CarMesh3D_findVehicleFiles(copyFiles.Folder, FigNum=-1);
    assert(strcmp(copyFound.ModelFolder, fitFiles.ModelFolder), 'The copy reads the repo''s download');
    assert(strcmp(copyFound.DownloadRoot, fitFiles.DownloadRoot), 'And its modelFile is relative to the same folder');
    assert(startsWith(copyFound.Folder, copyRoot), 'Everything else is the copy''s own');
    rmdir(copyRoot, 's');
else
    fprintf(1, 'TEST 20005 skipped: no LargeData download for the Fit on this computer\n');
end

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

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

fastFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
assert(isequal(fastFiles, priusFiles));

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

%% FAIL case: Spaces and a dash in the name
if 1==0
    fcn_CarMesh3D_findVehicleFiles('2014_Ford_Transit Connect_XLT-LWB');
end

%% FAIL case: Only three parts
if 1==0
    fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius');
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
