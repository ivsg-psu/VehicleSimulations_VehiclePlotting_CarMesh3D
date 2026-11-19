% script_test_fcn_CarMesh3D_addReferenceVehicle.m
% Tests fcn_CarMesh3D_addReferenceVehicle
% Adds vehicles to the reference vehicle list (a GIF in Images\vehicles,
% a row in Data\referenceVehicles.csv, and the README table). The tests
% use temporary copies, so the real list and README are not changed.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addReferenceVehicle
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addReferenceVehicle
%   % * Renamed from script_CarMesh3D_addReferenceVehicle: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addReferenceVehicle
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

%% DEMO case: Add two vehicles, then update one
figNum = 10001;
titleString = sprintf('DEMO case: Add two vehicles, then update one');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% Temporary list, images folder, and README with the markers
testFolder = fullfile(tempdir,'CarMesh3D_referenceTest');
if isfolder(testFolder)
    rmdir(testFolder,'s');
end
mkdir(testFolder);
listFile = fullfile(testFolder,'referenceVehicles.csv');
imagesFolder = fullfile(testFolder,'vehicles');
readmeFile = fullfile(testFolder,'README.md');
fileID = fopen(readmeFile,'w');
fprintf(fileID,'# Test\n\n<!-- REFERENCE VEHICLES START -->\nold table\n<!-- REFERENCE VEHICLES END -->\n\nMore text.\n');
fclose(fileID);
% A small GIF to use as the reference animation
gifFile = fullfile(testFolder,'drive.gif');
for ith_frame = 1:3
    imwrite(uint8(80*ith_frame*ones(20,30)), gray(256), gifFile, 'gif', 'WriteMode', fcn_INTERNAL_gifMode(ith_frame));
end
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh.AxleX = [0 2.7];

fcn_CarMesh3D_addReferenceVehicle('2013_Toyota_Prius_Four', vehicleMesh, gifFile, ...
    ListFile=listFile, ImagesFolder=imagesFolder, ReadmeFile=readmeFile);
fcn_CarMesh3D_addReferenceVehicle('2014_Ford_TransitConnect_XLTCargoLWB', vehicleMesh, gifFile, ...
    ListFile=listFile, ImagesFolder=imagesFolder, ReadmeFile=readmeFile);
referenceList = fcn_CarMesh3D_addReferenceVehicle('2013_Toyota_Prius_Four', vehicleMesh, gifFile, ...
    ListFile=listFile, ImagesFolder=imagesFolder, ReadmeFile=readmeFile);

% Check variable types
assert(istable(referenceList));

% Check variable sizes: two vehicles (the update did not add a row)
assert(height(referenceList)==2);

% Check variable values
assert(isequal(referenceList.ID', {'2013_Toyota_Prius_Four','2014_Ford_TransitConnect_XLTCargoLWB'}));
assert(isfile(fullfile(imagesFolder,'2013_Toyota_Prius_Four.gif')));
assert(abs(referenceList.Wheelbase_m(1) - 2.7) < 1e-9);
readmeText = fileread(readmeFile);
assert(~contains(readmeText,'old table') && contains(readmeText,'2014 Ford TransitConnect XLTCargoLWB'));
assert(contains(readmeText,'More text.'));
% The list file reads back the same
assert(height(readtable(listFile))==2);

% Make sure plot did NOT open up
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

referenceList = fcn_CarMesh3D_addReferenceVehicle('2013_Toyota_Prius_Four', vehicleMesh, gifFile, ...
    ListFile=listFile, ImagesFolder=imagesFolder, ReadmeFile='', FigNum=-1);
assert(height(referenceList)==2);

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

%% FAIL case: A vehicle ID that breaks the naming convention
if 1==0
    fcn_CarMesh3D_addReferenceVehicle('Prius 2013', vehicleMesh, gifFile);
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

%% fcn_INTERNAL_gifMode
function writeMode = fcn_INTERNAL_gifMode(frameNumber)
% 'overwrite' for the first GIF frame, then 'append'
if frameNumber==1
    writeMode = 'overwrite';
else
    writeMode = 'append';
end
end % Ends fcn_INTERNAL_gifMode
