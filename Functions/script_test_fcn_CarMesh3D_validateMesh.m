% script_test_fcn_CarMesh3D_validateMesh.m
% Tests fcn_CarMesh3D_validateMesh
% Compares a finished mesh against its vehicle specification.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_validateMesh
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_validateMesh
%   % * Renamed from script_CarMesh3D_validateMesh: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_validateMesh
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

%% DEMO case: Validate a finished mesh against its spec
figNum = 10001;
titleString = sprintf('DEMO case: Validate a finished mesh against its spec');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');
disp(validationTable);

% Check variable types
assert(istable(validationTable));

% Check variable sizes
assert(12==height(validationTable));
assert(isequal(validationTable.Properties.VariableNames, {'Quantity','Target_m','Measured_m','Error_m','PercentError','Pass'}));

% Check variable values
assert(all(validationTable.Pass));
wheelbaseRow = validationTable.Quantity=="Wheelbase";
assert(abs(validationTable.Measured_m(wheelbaseRow) - 2.70)<1e-6);

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

%% TEST case: A mesh that is too long fails the length check
figNum = 20001;
titleString = sprintf('TEST case: A mesh that is too long fails the length check');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;
vehicleMesh.Vertices(:,1) = 1.10*vehicleMesh.Vertices(:,1); % 10% too long
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec);
lengthRow = validationTable.Quantity=="OverallLength";
assert(~validationTable.Pass(lengthRow));
assert(abs(validationTable.PercentError(lengthRow) - 10)<1e-6);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: An unlabeled mesh has no wheel measurements, which do not fail
figNum = 20002;
titleString = sprintf('TEST case: An unlabeled mesh has no wheel measurements, which do not fail');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
unlabeledMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
unlabeledMesh = fcn_CarMesh3D_fitMeshToSpec(unlabeledMesh, vehicleSpec, FigNum=-1);
validationTable = fcn_CarMesh3D_validateMesh(unlabeledMesh, vehicleSpec);
wheelbaseRow = validationTable.Quantity=="Wheelbase";
assert(isnan(validationTable.Measured_m(wheelbaseRow)));
assert(validationTable.Pass(wheelbaseRow));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A looser tolerance lets a small error pass
figNum = 20003;
titleString = sprintf('TEST case: A looser tolerance lets a small error pass');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;
vehicleMesh.Vertices(:,3) = 1.03*vehicleMesh.Vertices(:,3); % 3% too tall
tableStrict = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec);
tableLoose = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, Tolerance=5);
heightRow = tableStrict.Quantity=="OverallHeight";
assert(~tableStrict.Pass(heightRow));
assert(tableLoose.Pass(heightRow));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A tire reduced to a polygon fails the roundness rows
figNum = 20009;
titleString = sprintf('TEST case: A tire reduced to a polygon fails the roundness rows');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;
roundTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec);
roundRows = ismember(roundTable.Quantity, ["TireRoundMin","TireRoundMax"]);
assert(sum(roundRows)==2 && all(roundTable.Pass(roundRows)));
% (the front-left wheel replaced by a hexagonal prism of the same size)
wheelFaces = vehicleMesh.FaceWheelIndex==1;
wheelVertices = vehicleMesh.Vertices(unique(vehicleMesh.Faces(wheelFaces,:)),:);
center = (min(wheelVertices) + max(wheelVertices))/2;
radius = (max(wheelVertices(:,3)) - min(wheelVertices(:,3)))/2;
angles = (0:5)'*pi/3;
ring = [center(1) + radius*cos(angles), center(3) + radius*sin(angles)];
hexVertices = [ring(:,1), repmat(min(wheelVertices(:,2)),6,1), ring(:,2); ring(:,1), repmat(max(wheelVertices(:,2)),6,1), ring(:,2)];
hexFaces = [];
for k = 1:6
    kNext = mod(k,6) + 1;
    hexFaces = [hexFaces; k kNext 6+kNext; k 6+kNext 6+k]; %#ok<AGROW>
end
hexFaces = [hexFaces; 1 2 3; 1 3 4; 1 4 5; 1 5 6; 7 9 8; 7 10 9; 7 11 10; 7 12 11];
polygonMesh = vehicleMesh;
keep = ~wheelFaces;
polygonMesh.Faces = [vehicleMesh.Faces(keep,:); hexFaces + size(vehicleMesh.Vertices,1)];
polygonMesh.Vertices = [vehicleMesh.Vertices; hexVertices];
for fieldName = {'FacePartIndex','FaceWheelIndex','FaceLightType'}
    if isfield(polygonMesh, fieldName{1})
        values = vehicleMesh.(fieldName{1})(keep,:);
        newValue = values(1,:)*0;
        if strcmp(fieldName{1},'FacePartIndex'), newValue = find(strcmp(vehicleMesh.PartNames,'wheel')); end
        if strcmp(fieldName{1},'FaceWheelIndex'), newValue = 1; end
        polygonMesh.(fieldName{1}) = [values; repmat(newValue, size(hexFaces,1), 1)];
    end
end
polygonTable = fcn_CarMesh3D_validateMesh(polygonMesh, vehicleSpec);
assert(~polygonTable.Pass(polygonTable.Quantity=="TireRoundMin"));

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

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;
validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=[]);
assert(istable(validationTable));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=-1);
assert(istable(validationTable));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_INTERNAL_finishedSample;

Niterations = 100;

% Normal mode
tic;
for ith_test = 1:Niterations
    validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=-1);
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
        validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=[]);
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
title('fcn_CarMesh3D_validateMesh: time per call','Interpreter','none');
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

%% FAIL case: Mesh not normalized
if 1==0
    validationTable = fcn_CarMesh3D_validateMesh(fcn_CarMesh3D_fillSampleMesh(Style='messy'), fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan'));
end

%% FAIL case: Negative tolerance
if 1==0
    validationTable = fcn_CarMesh3D_validateMesh(fcn_CarMesh3D_fillSampleMesh, fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan'), Tolerance=-1);
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

%% fcn_INTERNAL_preparedSample
function vehicleMesh = fcn_INTERNAL_preparedSample(numWheelSegments)
% Makes a normalized, labeled sample mesh from the sedan preset
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(NumWheelSegments=numWheelSegments, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_preparedSample

%% fcn_INTERNAL_compactSpec
function vehicleSpec = fcn_INTERNAL_compactSpec
% A spec that differs from the sample's sedan preset, so fitting has
% real work to do. Example values only.
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(...
    Name='Example compact car',...
    OverallLength=4.55, OverallWidth=1.80, OverallHeight=1.42,...
    Wheelbase=2.70, TrackFront=1.55, TrackRear=1.56,...
    TireSize='205/55R16', FrontOverhang=0.88, GroundClearance=0.14,...
    FigNum=-1);
end % Ends fcn_INTERNAL_compactSpec

%% fcn_INTERNAL_wheelCenter
function wheelCenter = fcn_INTERNAL_wheelCenter(vehicleMesh, wheelNumber)
% Bounding-box center of one numbered wheel
wheelFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==wheelNumber,:);
wheelVertices = vehicleMesh.Vertices(unique(wheelFaces(:)),:);
wheelCenter = (min(wheelVertices,[],1) + max(wheelVertices,[],1))/2;
end % Ends fcn_INTERNAL_wheelCenter

%% fcn_INTERNAL_finishedSample
function vehicleMesh = fcn_INTERNAL_finishedSample
% A prepared sample, fitted to the compact spec and simplified
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_INTERNAL_preparedSample(16), fcn_INTERNAL_compactSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_finishedSample
