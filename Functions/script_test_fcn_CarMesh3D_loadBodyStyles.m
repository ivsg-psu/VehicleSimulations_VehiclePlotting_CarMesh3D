% script_test_fcn_CarMesh3D_loadBodyStyles.m
% Tests fcn_CarMesh3D_loadBodyStyles
% Lists the vehicle body styles and each one's exemplar vehicle.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadBodyStyles
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadBodyStyles
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

%% DEMO case: The body styles, with every exemplar shown
figNum = 10001;
titleString = sprintf('DEMO case: The body styles, with every exemplar shown');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=figNum);

% Check variable types
assert(isstruct(bodyStyles) && ischar(bodyStyles(1).BodyStyle) && islogical(bodyStyles(1).HasExemplar));

% Check variable sizes
assert(numel(bodyStyles) >= 22);
assert(sum([bodyStyles.Core]) == 13);

% Check variable values: the liftback's and compact cargo van's exemplars,
% and the sedans filed so far
styleIDs = {bodyStyles.BodyStyle};
assert(isequal(numel(unique(styleIDs)), numel(styleIDs)));                    % (no repeats)
liftback = bodyStyles(strcmp(styleIDs, 'liftback'));
assert(any(strcmp(liftback.ExemplarIDs, '2013_Toyota_Prius_Four')) && liftback.HasExemplar);
assert(endsWith(liftback.Folder, fullfile('BodyStyles','Liftback')));
van = bodyStyles(strcmp(styleIDs, 'compactCargoVan'));
assert(any(strcmp(van.ExemplarIDs, '2014_Ford_TransitConnect_XLTCargoLWB')) && van.HasExemplar);
sedan = bodyStyles(strcmp(styleIDs, 'sedan'));
assert(contains(sedan.SuggestedVehicles, 'Camry') && sedan.Core);
assert(all(ismember(sedan.ExemplarIDs, sedan.VehicleIDs)));
semi = bodyStyles(strcmp(styleIDs, 'semiTractor'));
assert(~semi.Core);
% (only approved exemplars: the Outback, not the other wagons filed there)
wagon = bodyStyles(strcmp(styleIDs, 'stationWagon'));
assert(isequal(wagon.ExemplarIDs, {'2021_Subaru_Outback_LimitedXT'}));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

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

%% TEST case: A Data folder with vehicles filed by style, one finished
figNum = 20001;
titleString = sprintf('TEST case: A Data folder with vehicles filed by style, one finished');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

testData = fullfile(tempdir, 'CarMesh3D_bodyStylesTest');
if isfolder(testData)
    rmdir(testData, 's');
end
mkdir(testData);
% (the list without its Exemplars column: every finished vehicle is an
% exemplar, the rule for lists without that column)
styleList = readtable(fullfile(fileparts(which('fcn_CarMesh3D_loadBodyStyles')), '..', 'Data', 'bodyStyles.csv'), ...
    'TextType','char', 'Delimiter',',', 'VariableNamingRule','preserve');
styleList.Exemplars = [];
writetable(styleList, fullfile(testData, 'bodyStyles.csv'));
mkdir(fullfile(testData, 'BodyStyles', 'Sedan', '2020_Test_SedanA_Base'));
mkdir(fullfile(testData, 'BodyStyles', 'Sedan', '2021_Test_SedanB_Base'));
vehicleMesh = struct('Vertices', zeros(0,3)); %#ok<NASGU>
save(fullfile(testData, 'BodyStyles', 'Sedan', '2021_Test_SedanB_Base', 'vehicleMesh_2021_Test_SedanB_Base.mat'), 'vehicleMesh');
mkdir(fullfile(testData, 'Samples', '2026_Test_Sample_Car'));
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=testData);
sedan = bodyStyles(strcmp({bodyStyles.BodyStyle}, 'sedan'));
assert(isequal(sort(sedan.VehicleIDs), {'2020_Test_SedanA_Base'; '2021_Test_SedanB_Base'}));
assert(isequal(sedan.ExemplarIDs, {'2021_Test_SedanB_Base'}) && sedan.HasExemplar);
assert(sum([bodyStyles.HasExemplar]) == 1);                                   % (the sample is not a style)

%% TEST case: An Exemplars column: only the approved vehicles, with a warning for an unfinished one
styleList.Exemplars = repmat({''}, height(styleList), 1);
styleList.Exemplars{strcmp(styleList.BodyStyle, 'sedan')} = '2021_Test_SedanB_Base; 2020_Test_SedanA_Base';
writetable(styleList, fullfile(testData, 'bodyStyles.csv'));
lastwarn('');
warning('off', 'CarMesh3D:exemplarNotFinished');
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=testData);
warning('on', 'CarMesh3D:exemplarNotFinished');
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:exemplarNotFinished'));                   % (SedanA has no mesh)
sedan = bodyStyles(strcmp({bodyStyles.BodyStyle}, 'sedan'));
assert(isequal(sedan.ExemplarIDs, {'2021_Test_SedanB_Base'}) && sedan.HasExemplar);
% (a finished vehicle that is not named is not an exemplar)
styleList.Exemplars{strcmp(styleList.BodyStyle, 'sedan')} = '';
writetable(styleList, fullfile(testData, 'bodyStyles.csv'));
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=testData);
sedan = bodyStyles(strcmp({bodyStyles.BodyStyle}, 'sedan'));
assert(isempty(sedan.ExemplarIDs) && ~sedan.HasExemplar);

%% TEST case: A style folder that is not in the list
mkdir(fullfile(testData, 'BodyStyles', 'Limousine'));
lastwarn('');
warning('off', 'CarMesh3D:unlistedStyle');
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=testData);
warning('on', 'CarMesh3D:unlistedStyle');
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:unlistedStyle'));
assert(strcmp(bodyStyles(end).BodyStyle, 'limousine') && strcmp(bodyStyles(end).Name, 'Limousine'));
rmdir(testData, 's');

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=[]);
assert(numel(bodyStyles) >= 22);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=-1);
assert(numel(bodyStyles) >= 22);

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
    fcn_CarMesh3D_loadBodyStyles(DataFolder='C:\no\such\folder');
end
