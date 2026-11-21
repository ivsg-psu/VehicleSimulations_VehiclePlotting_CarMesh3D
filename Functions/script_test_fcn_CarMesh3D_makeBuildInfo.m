% script_test_fcn_CarMesh3D_makeBuildInfo.m
% Tests fcn_CarMesh3D_makeBuildInfo
% The build information (versions, script, settings, quality score) saved
% with a finished mesh.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeBuildInfo
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeBuildInfo
%   % * (fill in items here)


%% Set up the workspace
close all

% (example inputs: a comparison's totals and a dimension-check table)
compareTotals = struct('HolePercent',0.024, 'LabelChangePercent',0.484, 'FlippedPercent',0.488, 'SeeThroughPercent',0);
validation = table(["OverallLength";"OverallHeight";"Wheelbase"], [true;true;true], 'VariableNames',{'Quantity','Pass'});


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

%% DEMO case: A mesh made from a download, with its comparison and dimension checks
figNum = 10001;
titleString = sprintf('DEMO case: A mesh made from a download, with its comparison and dimension checks');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

settings = struct('VehicleID','2014_Ford_TransitConnect_XLTCargoLWB', 'TargetFaces',36000, 'ReduceWithBlender',true);
buildInfo = fcn_CarMesh3D_makeBuildInfo(Script='C:\some\folder\script_CarMesh3D_vehicle_X.m', Settings=settings, ...
    CompareTotals=compareTotals, Validation=validation, FigNum=figNum);

% Check variable types
assert(isstruct(buildInfo) && isstruct(buildInfo.Quality) && isstruct(buildInfo.Settings));

% Check variable sizes
assert(isscalar(buildInfo.Quality.Score));

% Check variable values: versions, the script's name only, the score
[versionString, ~, meshVersion] = fcn_CarMesh3D_version;
assert(strcmp(buildInfo.CarMesh3DVersion, versionString) && strcmp(buildInfo.MeshVersion, meshVersion));
assert(strcmp(buildInfo.Script, 'script_CarMesh3D_vehicle_X.m'));
assert(strcmp(buildInfo.Quality.Basis, 'comparison'));
expectedScore = round(10*(100 - 4*0.024 - 2*0.484 - 2*0.488 - 4*0))/10;
assert(abs(buildInfo.Quality.Score - expectedScore) < 1e-9);
assert(buildInfo.Quality.DimensionChecks==3 && buildInfo.Quality.DimensionChecksFailed==0);
assert(isempty(buildInfo.ExemplarID));

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

%% TEST case: A body-style vehicle takes its exemplar's comparison terms
figNum = 20001;
titleString = sprintf('TEST case: A body-style vehicle takes its exemplar''s comparison terms');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

exemplarInfo = fcn_CarMesh3D_makeBuildInfo(Settings=struct('VehicleID','2021_Subaru_Outback_LimitedXT'), CompareTotals=compareTotals);
genericInfo = fcn_CarMesh3D_makeBuildInfo(Settings=struct('BodyStyle','stationWagon'), Validation=validation, Exemplar=exemplarInfo);
assert(strcmp(genericInfo.Quality.Basis, 'exemplar') && abs(genericInfo.Quality.Score - exemplarInfo.Quality.Score) < 1e-9);
assert(strcmp(genericInfo.ExemplarID, '2021_Subaru_Outback_LimitedXT') && strcmp(genericInfo.ExemplarMeshVersion, exemplarInfo.MeshVersion));

%% TEST case: Failed dimension checks lower the score; the score stays between 0 and 100
figNum = 20002;
titleString = sprintf('TEST case: Failed dimension checks lower the score; the score stays between 0 and 100');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

failedValidation = validation;
failedValidation.Pass(2) = false;
failedInfo = fcn_CarMesh3D_makeBuildInfo(CompareTotals=compareTotals, Validation=failedValidation);
assert(abs(failedInfo.Quality.Score - (expectedScore - 5)) < 1e-9 && failedInfo.Quality.DimensionChecksFailed==1);
awfulTotals = struct('HolePercent',20, 'LabelChangePercent',30, 'FlippedPercent',10, 'SeeThroughPercent',5);
awfulInfo = fcn_CarMesh3D_makeBuildInfo(CompareTotals=awfulTotals);
assert(awfulInfo.Quality.Score==0);
noneInfo = fcn_CarMesh3D_makeBuildInfo;
assert(noneInfo.Quality.Score==100 && strcmp(noneInfo.Quality.Basis, 'dimensions only') && isnan(noneInfo.Quality.HolePercent));

%% Fast Mode Tests


%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
buildInfo = fcn_CarMesh3D_makeBuildInfo(CompareTotals=compareTotals, FigNum=[]);
assert(isstruct(buildInfo));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
buildInfo = fcn_CarMesh3D_makeBuildInfo(CompareTotals=compareTotals, FigNum=-1);
assert(isstruct(buildInfo));

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

%% FAIL case: Settings that are not a structure
if 1==0
    fcn_CarMesh3D_makeBuildInfo(Settings='targetFaces 24000');
end

%% FAIL case: Totals that are not from compareToOriginal
if 1==0
    fcn_CarMesh3D_makeBuildInfo(CompareTotals=[0.1 0.2 0.3]);
end
