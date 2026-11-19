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

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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
