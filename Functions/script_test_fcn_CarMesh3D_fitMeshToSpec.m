% script_test_fcn_CarMesh3D_fitMeshToSpec.m
% Tests fcn_CarMesh3D_fitMeshToSpec
% Scales meshes to published dimensions, moving the wheels to the true wheelbase and track.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fitMeshToSpec
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fitMeshToSpec
%   % * Renamed from script_CarMesh3D_fitMeshToSpec: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fitMeshToSpec
%   % * Tests different front and rear tires

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fitMeshToSpec
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

%% DEMO case: Fit the sample to a different spec using the wheels
figNum = 10001;
titleString = sprintf('DEMO case: Fit the sample to a different spec using the wheels');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_INTERNAL_compactSpec;
preparedMesh = fcn_INTERNAL_preparedSample(16);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleMesh.FitInfo));

% Check variable sizes
assert(isequal(size(vehicleMesh.Vertices), size(preparedMesh.Vertices)));
assert(isequal(size(vehicleMesh.AxleX),[1 2]));

% Check variable values
assert(isequal(vehicleMesh.FitInfo.Method,'wheels'));
assert(max(abs(vehicleMesh.AxleX - [0 2.70]))<1e-9); % Origin at the rear axle
extents = max(vehicleMesh.Vertices,[],1) - min(vehicleMesh.Vertices,[],1);
assert(max(abs(extents - [4.55 1.80 1.42]))<1e-6);
% Front overhang is exact
assert(abs(max(vehicleMesh.Vertices(:,1)) - 2.70 - 0.88)<1e-6);
% Wheels sit exactly at their corners, touching the ground
D = vehicleSpec.TireDiameter;
assert(max(abs(fcn_INTERNAL_wheelCenter(vehicleMesh,1) - [2.70  1.55/2 D/2]))<1e-9);
assert(max(abs(fcn_INTERNAL_wheelCenter(vehicleMesh,2) - [2.70 -1.55/2 D/2]))<1e-9);
assert(max(abs(fcn_INTERNAL_wheelCenter(vehicleMesh,3) - [0     1.56/2 D/2]))<1e-9);
assert(max(abs(fcn_INTERNAL_wheelCenter(vehicleMesh,4) - [0    -1.56/2 D/2]))<1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Box fitting matches only the overall size
figNum = 10002;
titleString = sprintf('DEMO case: Box fitting matches only the overall size');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_INTERNAL_compactSpec;
preparedMesh = fcn_INTERNAL_preparedSample(16);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FitMethod='box', FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

assert(isequal(vehicleMesh.FitInfo.Method,'box'));
extents = max(vehicleMesh.Vertices,[],1) - min(vehicleMesh.Vertices,[],1);
assert(max(abs(extents - [4.55 1.80 1.42]))<1e-9);
assert(all(isnan(vehicleMesh.FitInfo.WheelScale)));

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

%% TEST case: Origin at the center
figNum = 20001;
titleString = sprintf('TEST case: Origin at the center');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_INTERNAL_preparedSample(16), fcn_INTERNAL_compactSpec, Origin='center');
assert(abs(max(vehicleMesh.Vertices(:,1)) + min(vehicleMesh.Vertices(:,1)))<1e-9);
assert(abs(vehicleMesh.AxleX(2) - vehicleMesh.AxleX(1) - 2.70)<1e-9);
assert(isequal(vehicleMesh.FitInfo.Origin,'center'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: An unlabeled mesh uses box fitting automatically
figNum = 20002;
titleString = sprintf('TEST case: An unlabeled mesh uses box fitting automatically');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

unlabeledMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(unlabeledMesh, fcn_INTERNAL_compactSpec);
assert(isequal(vehicleMesh.FitInfo.Method,'box'));
% Axles are estimated from the front overhang and wheelbase
assert(max(abs(vehicleMesh.AxleX - [0 2.70]))<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Asking for wheels on an unlabeled mesh warns and uses box
figNum = 20003;
titleString = sprintf('TEST case: Asking for wheels on an unlabeled mesh warns and uses box');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

unlabeledMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
lastwarn('');
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(unlabeledMesh, fcn_INTERNAL_compactSpec, FitMethod='wheels');
[warningMessage,~] = lastwarn;
assert(contains(warningMessage,'box'));
assert(isequal(vehicleMesh.FitInfo.Method,'box'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Without a front overhang, the wheelbase is still exact
figNum = 20004;
titleString = sprintf('TEST case: Without a front overhang, the wheelbase is still exact');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleSpec.FrontOverhang = [];
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_INTERNAL_preparedSample(16), vehicleSpec);
frontCenter = fcn_INTERNAL_wheelCenter(vehicleMesh,1);
rearCenter = fcn_INTERNAL_wheelCenter(vehicleMesh,3);
assert(abs(frontCenter(1) - rearCenter(1) - 2.70)<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Different front and rear tires: each axle's wheels to its own size
figNum = 20005;
titleString = sprintf('TEST case: Different front and rear tires: each axle''s wheels to its own size');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

staggeredSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', TireSize='225/40R18', TireSizeRear='275/35R19');
sampleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
staggeredMesh = fcn_CarMesh3D_fitMeshToSpec(sampleMesh, staggeredSpec, FigNum=figNum);
validation = fcn_CarMesh3D_validateMesh(staggeredMesh, staggeredSpec);
assert(any(validation.Quantity=="TireDiameterRear"));
checked = validation(~ismissing(validation.Pass), :);
assert(all(checked.Pass));
frontHeight = max(staggeredMesh.Vertices(unique(staggeredMesh.Faces(staggeredMesh.FaceWheelIndex==1,:)),3));
rearHeight = max(staggeredMesh.Vertices(unique(staggeredMesh.Faces(staggeredMesh.FaceWheelIndex==3,:)),3));
assert(abs(frontHeight - staggeredSpec.TireDiameter) < 1e-6 && abs(rearHeight - staggeredSpec.TireDiameterRear) < 1e-6);

%% TEST case: Symmetric: a one-sided spike on the right does not set the height
figNum = 20006;
titleString = sprintf('TEST case: Symmetric: a one-sided spike on the right does not set the height');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (a right-side body vertex raised 0.1 m above the roof, like a mast
% antenna on the right A-pillar)
vehicleSpec = fcn_INTERNAL_compactSpec;
spikedMesh = fcn_INTERNAL_preparedSample(16);
bodyVertexIndices = unique(spikedMesh.Faces(spikedMesh.LabelFacePart==1,:));
rightBody = bodyVertexIndices(spikedMesh.Vertices(bodyVertexIndices,2) < -0.2);
[~,highest] = max(spikedMesh.Vertices(rightBody,3));
roofTop = max(spikedMesh.Vertices(:,3));
spikedMesh.Vertices(rightBody(highest),3) = roofTop + 0.1;

% Not symmetric (the default): the spike's tip is at the overall height
plainMesh = fcn_CarMesh3D_fitMeshToSpec(spikedMesh, vehicleSpec);
assert(abs(max(plainMesh.Vertices(:,3)) - vehicleSpec.OverallHeight) < 1e-9);

% Symmetric: the left half's roof is at the overall height (the spike
% stands above it, and the mirroring later removes it)
symmetricMesh = fcn_CarMesh3D_fitMeshToSpec(spikedMesh, vehicleSpec, FlagSymmetric=true, FigNum=figNum);
leftHalf = symmetricMesh.Vertices(:,2) >= 0;
assert(abs(max(symmetricMesh.Vertices(leftHalf,3)) - vehicleSpec.OverallHeight) < 1e-9);
assert(max(symmetricMesh.Vertices(:,3)) > vehicleSpec.OverallHeight);
assert(abs(symmetricMesh.AxleX(2) - symmetricMesh.AxleX(1) - vehicleSpec.Wheelbase) < 1e-9);

% A bump just right of the center (within the 15 cm the mirroring keeps,
% like the 1999 F-150's bumper trim) does set the length
bumpedMesh = fcn_INTERNAL_preparedSample(16);
% (a vertex 5 cm right of the center, 5 cm ahead of the bumper: the fit
% measures vertices)
sourceCenterY = (min(bumpedMesh.Vertices(:,2)) + max(bumpedMesh.Vertices(:,2)))/2;
bumpedMesh.Vertices(end+1,:) = [max(bumpedMesh.Vertices(:,1)) + 0.05, sourceCenterY - 0.05, mean(bumpedMesh.Vertices(:,3))];
bumpedFit = fcn_CarMesh3D_fitMeshToSpec(bumpedMesh, vehicleSpec, FlagSymmetric=true);
assert(abs(max(bumpedFit.Vertices(:,1)) - min(bumpedFit.Vertices(:,1)) - vehicleSpec.OverallLength) < 1e-9);

% A low body point on the right (an exhaust tip, say) does not set the
% ground clearance of the half that is kept
loweredMesh = fcn_INTERNAL_preparedSample(16);
bodyVertexIndices = unique(loweredMesh.Faces(loweredMesh.LabelFacePart==1,:));
rightBody = bodyVertexIndices(loweredMesh.Vertices(bodyVertexIndices,2) < -0.3);
[~,lowest] = min(loweredMesh.Vertices(rightBody,3));
loweredMesh.Vertices(rightBody(lowest),3) = loweredMesh.Vertices(rightBody(lowest),3) - 0.05;
loweredFit = fcn_CarMesh3D_fitMeshToSpec(loweredMesh, vehicleSpec, FlagSymmetric=true);
keptBody = bodyVertexIndices(loweredFit.Vertices(bodyVertexIndices,2) >= -0.15);
assert(abs(min(loweredFit.Vertices(keptBody,3)) - vehicleSpec.GroundClearance) < 1e-9);

% Without a spike, Symmetric changes nothing (the sample is symmetric)
cleanMesh = fcn_INTERNAL_preparedSample(16);
assert(max(max(abs(fcn_CarMesh3D_fitMeshToSpec(cleanMesh, vehicleSpec, FlagSymmetric=true).Vertices - ...
    fcn_CarMesh3D_fitMeshToSpec(cleanMesh, vehicleSpec).Vertices))) < 1e-9);

% Check that the figure is open
figHandles = get(groot, 'Children');
assert(any(figHandles==figNum));

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

preparedMesh = fcn_INTERNAL_preparedSample(16);
vehicleSpec = fcn_INTERNAL_compactSpec;
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=[]);
assert(isequal(vehicleMesh.FitInfo.Method,'wheels'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=-1);
assert(isequal(vehicleMesh.FitInfo.Method,'wheels'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

preparedMesh = fcn_INTERNAL_preparedSample(16);
vehicleSpec = fcn_INTERNAL_compactSpec;

Niterations = 100;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=-1);
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
        vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(preparedMesh, vehicleSpec, FigNum=[]);
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
title('fcn_CarMesh3D_fitMeshToSpec: time per call','Interpreter','none');
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
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_CarMesh3D_fillSampleMesh(Style='messy'), fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan'));
end

%% FAIL case: Spec missing the overall length
if 1==0
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_CarMesh3D_fillSampleMesh, fcn_CarMesh3D_fillVehicleSpec(Wheelbase=2.7));
end

%% FAIL case: Unknown fit method
if 1==0
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_CarMesh3D_fillSampleMesh, fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan'), FitMethod='stretch');
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
