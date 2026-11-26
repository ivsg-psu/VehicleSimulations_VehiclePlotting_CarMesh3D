% script_test_fcn_CarMesh3D_fillBodyStyleMesh.m
% Tests fcn_CarMesh3D_fillBodyStyleMesh
% Makes a vehicle's mesh from its body style's exemplar, refit to its specification.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillBodyStyleMesh
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillBodyStyleMesh
%   % * (fill in items here)


%% Set up the workspace
close all

% A 2020 Toyota Corolla hatchback (published dimensions), as a liftback
corollaSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
corollaSpec.Name = '2020 Toyota Corolla Hatchback';
corollaSpec.OverallLength = 4.370;
corollaSpec.OverallWidth = 1.790;
corollaSpec.WidthWithMirrors = [];
corollaSpec.OverallHeight = 1.435;
corollaSpec.Wheelbase = 2.640;
corollaSpec.TrackFront = 1.531;
corollaSpec.TrackRear = 1.560;
corollaSpec.FrontOverhang = 0.900;
corollaSpec.RearOverhang = 4.370 - 2.640 - 0.900;
corollaSpec.TireSize = '205/55R16';
corollaSpec.TireDiameter = 0.632;
corollaSpec.GroundClearance = 0.135;
corollaSpec.BodyColor = [0.70 0.10 0.10];

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

%% DEMO case: A Corolla hatchback from the liftback exemplar (the Prius)
figNum = 10001;
titleString = sprintf('DEMO case: A Corolla hatchback from the liftback exemplar (the Prius)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', corollaSpec, FigNum=figNum);

% Check variable types
assert(isstruct(vehicleMesh) && isfield(vehicleMesh, 'BodyStyleInfo'));

% Check variable sizes
assert(size(vehicleMesh.Vertices,2)==3 && size(vehicleMesh.FaceColors,1)==size(vehicleMesh.Faces,1));

% Check variable values: the size matches the spec; the labels came along
validation = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleMesh.VehicleSpec, FigNum=-1);
checked = validation(~ismissing(validation.Pass), :);
assert(all(checked.Pass), 'Not every dimension matches: %s', strjoin(cellstr(checked.Quantity(~checked.Pass)), ', '));
assert(strcmp(vehicleMesh.Name, corollaSpec.Name) && contains(vehicleMesh.Source, 'Prius'));
assert(strcmp(vehicleMesh.BodyStyleInfo.WidthReference, 'mirrors') && contains(vehicleMesh.BodyStyleInfo.WidthNote, 'estimated'));
assert(all(ismember({'body','glass','wheel','light'}, vehicleMesh.LabelPartNames)));
bodyFaces = vehicleMesh.LabelFacePart==find(strcmp(vehicleMesh.LabelPartNames, 'body'));
assert(all(abs(vehicleMesh.FaceColors(bodyFaces,:) - [0.70 0.10 0.10]) < 1e-12, 'all'));

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

%% TEST case: A Ram ProMaster City from the compact cargo van exemplar (the Transit Connect)
figNum = 20001;
titleString = sprintf('TEST case: A Ram ProMaster City from the compact cargo van exemplar (the Transit Connect)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vanSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
vanSpec.Name = '2019 Ram ProMaster City Cargo';
vanSpec.OverallLength = 4.737; vanSpec.OverallWidth = 1.830; vanSpec.WidthWithMirrors = 2.085;
vanSpec.OverallHeight = 1.882; vanSpec.Wheelbase = 3.105;
vanSpec.TrackFront = 1.524; vanSpec.TrackRear = 1.530;
vanSpec.FrontOverhang = 0.870; vanSpec.RearOverhang = 4.737 - 3.105 - 0.870;
vanSpec.TireSize = '195/65R16'; vanSpec.TireDiameter = 0.660; vanSpec.GroundClearance = 0.180;
% (the same tires at the rear: the preset's own rear tire would otherwise
% stay, making the spec staggered by mistake)
vanSpec.TireSizeRear = vanSpec.TireSize; vanSpec.TireDiameterRear = vanSpec.TireDiameter;
vanMesh = fcn_CarMesh3D_fillBodyStyleMesh('compactCargoVan', vanSpec, FigNum=figNum);
validation = fcn_CarMesh3D_validateMesh(vanMesh, vanMesh.VehicleSpec, FigNum=-1);
checked = validation(~ismissing(validation.Pass), :);
assert(all(checked.Pass));
assert(contains(vanMesh.BodyStyleInfo.WidthNote, 'with mirrors (as the exemplar)'));
assert(abs(vanMesh.AxleX(2) - vanMesh.AxleX(1) - 3.105) < 0.01);

%% TEST case: A style with no exemplar: the sample car, with a warning; or an error
figNum = 20002;
titleString = sprintf('TEST case: A style with no exemplar: the sample car, with a warning; or an error');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

lastwarn('');
warningState = warning('off','CarMesh3D:noExemplar');
sedanMesh = fcn_CarMesh3D_fillBodyStyleMesh('semiTractor', corollaSpec);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:noExemplar') && isempty(sedanMesh.BodyStyleInfo.ExemplarID));
flagFailed = false;
try
    fcn_CarMesh3D_fillBodyStyleMesh('semiTractor', corollaSpec, Fallback='error');
catch
    flagFailed = true;
end
assert(flagFailed);

%% TEST case: Two exemplars: the one closest in size, or the one asked for
figNum = 20004;
titleString = sprintf('TEST case: Two exemplars: the one closest in size, or the one asked for');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (a test Data folder: the Prius, and a copy of it 25 percent larger)
testData = fullfile(tempdir, 'CarMesh3D_closestTest');
if isfolder(testData)
    rmdir(testData, 's');
end
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
mkdir(testData);
% (the body-style list, with both liftbacks approved as exemplars)
styleList = readtable(fullfile(fileparts(fileparts(which('fcn_CarMesh3D_fillBodyStyleMesh'))), 'Data', 'bodyStyles.csv'), ...
    'TextType','char', 'Delimiter',',', 'VariableNamingRule','preserve');
styleList.Exemplars{strcmp(styleList.BodyStyle, 'liftback')} = '2013_Toyota_Prius_Four; 2030_Test_BigPrius_Base';
writetable(styleList, fullfile(testData, 'bodyStyles.csv'));
smallFolder = fullfile(testData, 'BodyStyles', 'Liftback', '2013_Toyota_Prius_Four');
largeFolder = fullfile(testData, 'BodyStyles', 'Liftback', '2030_Test_BigPrius_Base');
mkdir(smallFolder);
mkdir(largeFolder);
copyfile(priusFiles.MeshFile, smallFolder);
loaded = load(priusFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
vehicleMesh = loaded.vehicleMesh; %#ok<NASGU>
vehicleSpec = loaded.vehicleSpec;
for sizeField = {'OverallLength','OverallWidth','OverallHeight','Wheelbase'}
    vehicleSpec.(sizeField{1}) = 1.25*vehicleSpec.(sizeField{1});
end
vehicleSpec.Name = '2030 Test BigPrius Base';
save(fullfile(largeFolder, 'vehicleMesh_2030_Test_BigPrius_Base.mat'), 'vehicleMesh', 'vehicleSpec');

closestMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', corollaSpec, DataFolder=testData);
assert(strcmp(closestMesh.BodyStyleInfo.ExemplarID, '2013_Toyota_Prius_Four'));
assert(numel(closestMesh.BodyStyleInfo.CandidateIDs)==2 && numel(closestMesh.BodyStyleInfo.SizeDifference)==2);
bigSpec = corollaSpec;
for sizeField = {'OverallLength','OverallWidth','OverallHeight','Wheelbase'}
    bigSpec.(sizeField{1}) = 1.3*corollaSpec.(sizeField{1});
end
bigSpec.RearOverhang = bigSpec.OverallLength - bigSpec.Wheelbase - bigSpec.FrontOverhang;
bigMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', bigSpec, DataFolder=testData);
assert(strcmp(bigMesh.BodyStyleInfo.ExemplarID, '2030_Test_BigPrius_Base'));
askedMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', bigSpec, ExemplarID='2013_Toyota_Prius_Four', DataFolder=testData);
assert(strcmp(askedMesh.BodyStyleInfo.ExemplarID, '2013_Toyota_Prius_Four'));
rmdir(testData, 's');

%% TEST case: Case is ignored; BodyColor overrides the spec's
figNum = 20003;
titleString = sprintf('TEST case: Case is ignored; BodyColor overrides the spec''s');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

greenMesh = fcn_CarMesh3D_fillBodyStyleMesh('LiftBack', corollaSpec, BodyColor=[0.1 0.5 0.2]);
bodyFaces = greenMesh.LabelFacePart==find(strcmp(greenMesh.LabelPartNames, 'body'));
assert(all(abs(greenMesh.FaceColors(bodyFaces,:) - [0.1 0.5 0.2]) < 1e-12, 'all'));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', corollaSpec, FigNum=[]);
assert(isfield(vehicleMesh, 'BodyStyleInfo'));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', corollaSpec, FigNum=-1);
assert(isfield(vehicleMesh, 'BodyStyleInfo'));

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

%% FAIL case: An ExemplarID that is not one of the style's exemplars
if 1==0
    fcn_CarMesh3D_fillBodyStyleMesh('liftback', corollaSpec, ExemplarID='2014_Ford_TransitConnect_XLTCargoLWB');
end

%% FAIL case: An unknown body style
if 1==0
    fcn_CarMesh3D_fillBodyStyleMesh('hovercraft', corollaSpec);
end

%% FAIL case: A spec without a wheelbase
if 1==0
    fcn_CarMesh3D_fillBodyStyleMesh('liftback', struct('OverallLength',4, 'OverallWidth',1.8, 'OverallHeight',1.4));
end
