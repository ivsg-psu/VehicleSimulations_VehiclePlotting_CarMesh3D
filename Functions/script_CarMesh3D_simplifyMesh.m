% script_CarMesh3D_simplifyMesh.m
% Tests fcn_CarMesh3D_simplifyMesh
% Merges, cleans, reduces, and orients meshes so normals point outward.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_simplifyMesh
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_simplifyMesh
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

%% DEMO case: Clean the fitted sample and check that normals point outward
figNum = 10001;
titleString = sprintf('DEMO case: Clean the fitted sample and check that normals point outward');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

fittedMesh = fcn_INTERNAL_fittedSample(16);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleMesh.SimplifyInfo));

% Check variable sizes
Nfaces = size(vehicleMesh.Faces,1);
assert(isequal(size(vehicleMesh.FaceNormals),[Nfaces 3]));
assert(isequal(size(vehicleMesh.FacePartIndex),[Nfaces 1]));
assert(isequal(size(vehicleMesh.FaceColors),[Nfaces 3]));

% Check variable values
assert(vehicleMesh.SimplifyInfo.FinalFaces <= vehicleMesh.SimplifyInfo.OriginalFaces);
% Duplicate body vertices (the body sides and end caps) are merged. (The
% total vertex count can still grow, because each color group keeps its
% own copy of shared vertices, which keeps color edges sharp.)
originalBodyVertices = numel(unique(fittedMesh.Faces(fittedMesh.FacePartIndex==1,:)));
finalBodyVertices = numel(unique(vehicleMesh.Faces(vehicleMesh.FacePartIndex==1,:)));
assert(finalBodyVertices < originalBodyVertices);
assert(max(abs(vecnorm(vehicleMesh.FaceNormals,2,2) - 1))<1e-9);
fcn_INTERNAL_checkOutward(vehicleMesh);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Reduce a detailed mesh to a face budget
figNum = 10002;
titleString = sprintf('DEMO case: Reduce a detailed mesh to a face budget');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

detailedMesh = fcn_INTERNAL_fittedSample(64); % Smooth wheels: many faces
vehicleMesh = fcn_CarMesh3D_simplifyMesh(detailedMesh, TargetFaces=800, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

fprintf(1,'\tFaces: %d -> %d\n', vehicleMesh.SimplifyInfo.OriginalFaces, vehicleMesh.SimplifyInfo.FinalFaces);
assert(vehicleMesh.SimplifyInfo.FinalFaces < 0.6*vehicleMesh.SimplifyInfo.OriginalFaces);
% All five kinds of labels and all four wheels survive
assert(any(vehicleMesh.FacePartIndex==1));
assert(any(vehicleMesh.FacePartIndex==2));
for ith_wheel = 1:4
    assert(any(vehicleMesh.FaceWheelIndex==ith_wheel));
end

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

%% TEST case: Randomly flipped faces are fixed
figNum = 20001;
titleString = sprintf('TEST case: Randomly flipped faces are fixed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fittedMesh = fcn_INTERNAL_fittedSample(16);
rng(1);
flagFlip = rand(size(fittedMesh.Faces,1),1) > 0.5;
fittedMesh.Faces(flagFlip,:) = fittedMesh.Faces(flagFlip,[1 3 2]);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh);
fcn_INTERNAL_checkOutward(vehicleMesh);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Split vertices (one copy per face corner) are merged
figNum = 20002;
titleString = sprintf('TEST case: Split vertices (one copy per face corner) are merged');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fittedMesh = fcn_INTERNAL_fittedSample(16);
Nfaces = size(fittedMesh.Faces,1);
splitMesh = fittedMesh;
splitMesh.Vertices = fittedMesh.Vertices(reshape(fittedMesh.Faces',[],1),:);
splitMesh.Faces = reshape(1:3*Nfaces,3,[])';
vehicleMesh = fcn_CarMesh3D_simplifyMesh(splitMesh);
assert(vehicleMesh.SimplifyInfo.FinalVertices < 0.5*3*Nfaces);
fcn_INTERNAL_checkOutward(vehicleMesh);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A target above the face count only cleans the mesh
figNum = 20003;
titleString = sprintf('TEST case: A target above the face count only cleans the mesh');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fittedMesh = fcn_INTERNAL_fittedSample(16);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, TargetFaces=1e6);
assert(vehicleMesh.SimplifyInfo.FinalFaces >= 0.95*vehicleMesh.SimplifyInfo.OriginalFaces);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A panel seen only from behind is turned around (visibility check)
figNum = 20004;
titleString = sprintf('TEST case: A panel seen only from behind is turned around (visibility check)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% A flat open "roof" panel at z = 1, and a tall thin closed post beside
% it. The post lifts the center of the bounding box above the panel, so
% the open-surface rule (point away from the center) points the panel
% down, although it is seen from above.
panelVertices = [0 -1 1; 4 -1 1; 4 1 1; 0 1 1];
panelFaces = [1 2 3; 1 3 4];
% A closed floor slab below the panel blocks the view from underneath,
% as a vehicle's floor does.
[postVertices, postFaces] = fcn_INTERNAL_box([-1.2 -1.0 -0.1 0.1 0 3]);
[floorVertices, floorFaces] = fcn_INTERNAL_box([-0.5 4.5 -1.5 1.5 0.2 0.4]);
testMesh = struct;
testMesh.Name = 'panel, post, and floor';
testMesh.Vertices = [panelVertices; postVertices; floorVertices];
testMesh.Faces = [panelFaces; postFaces + 4; floorFaces + 12];
Ntest = size(testMesh.Faces,1);
testMesh.FacePartIndex = ones(Ntest,1);
testMesh.FaceWheelIndex = zeros(Ntest,1);
testMesh.FaceColors = repmat([0.05 0.2 0.6], Ntest, 1);
testMesh.FaceAlpha = ones(Ntest,1);
testMesh.FaceMaterialIndex = ones(Ntest,1);
testMesh.FaceGroupIndex = ones(Ntest,1);
testMesh.PartNames = {'body';'glass';'wheel';'light';'trim'};

withoutCheck = fcn_CarMesh3D_simplifyMesh(testMesh, TargetFaces=1e6, VisibilityCheck=false);
withCheck = fcn_CarMesh3D_simplifyMesh(testMesh, TargetFaces=1e6);

% Check variable values: the panel faces (normals along z) point up only
% with the check, and the info says how many were turned
panelWithout = abs(withoutCheck.FaceNormals(:,3)) > 0.99 & mean(reshape(withoutCheck.Vertices(withoutCheck.Faces,3),[],3),2) > 0.99 ...
    & mean(reshape(withoutCheck.Vertices(withoutCheck.Faces,3),[],3),2) < 1.01;
panelWith = abs(withCheck.FaceNormals(:,3)) > 0.99 & mean(reshape(withCheck.Vertices(withCheck.Faces,3),[],3),2) > 0.99 ...
    & mean(reshape(withCheck.Vertices(withCheck.Faces,3),[],3),2) < 1.01;
assert(nnz(panelWith)==2 && nnz(panelWithout)==2);
assert(all(withoutCheck.FaceNormals(panelWithout,3) < 0));
assert(all(withCheck.FaceNormals(panelWith,3) > 0));
assert(isnan(withoutCheck.SimplifyInfo.VisibilityFlips));
assert(withCheck.SimplifyInfo.VisibilityFlips >= 2);
% The closed post and floor still point out (their top faces point up)
postTop = mean(reshape(withCheck.Vertices(withCheck.Faces,3),[],3),2) > 2.99;
assert(all(withCheck.FaceNormals(postTop,3) > 0));

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

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

fittedMesh = fcn_INTERNAL_fittedSample(16);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=[]);
assert(isfield(vehicleMesh,'FaceNormals'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=-1);
assert(isfield(vehicleMesh,'FaceNormals'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

fittedMesh = fcn_INTERNAL_fittedSample(16);

Niterations = 10;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=-1);
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
        vehicleMesh = fcn_CarMesh3D_simplifyMesh(fittedMesh, FigNum=[]);
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
title('fcn_CarMesh3D_simplifyMesh: time per call','Interpreter','none');
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

%% FAIL case: Mesh not labeled
if 1==0
    vehicleMesh = fcn_CarMesh3D_simplifyMesh(fcn_CarMesh3D_fillSampleMesh);
end

%% FAIL case: Target too small
if 1==0
    vehicleMesh = fcn_CarMesh3D_simplifyMesh(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh), TargetFaces=2);
end

%% FAIL case: VisibilityCheck is not true or false
if 1==0
    fcn_CarMesh3D_simplifyMesh(fcn_INTERNAL_fittedSample(16), VisibilityCheck='yes');
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

%% fcn_INTERNAL_fittedSample
function vehicleMesh = fcn_INTERNAL_fittedSample(numWheelSegments)
% A prepared sample, fitted to the compact spec
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(fcn_INTERNAL_preparedSample(numWheelSegments), fcn_INTERNAL_compactSpec, FigNum=-1);
end % Ends fcn_INTERNAL_fittedSample

%% fcn_INTERNAL_checkOutward
function fcn_INTERNAL_checkOutward(vehicleMesh)
% Checks that normals point outward: the body and each wheel enclose a
% positive volume, and every glass face points away from the vehicle
% center
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
assert(fcn_INTERNAL_signedVolume(vertices, faces(vehicleMesh.FacePartIndex==1,:)) > 0);
for ith_wheel = 1:4
    assert(fcn_INTERNAL_signedVolume(vertices, faces(vehicleMesh.FaceWheelIndex==ith_wheel,:)) > 0);
end
vehicleCenter = (min(vertices,[],1) + max(vertices,[],1))/2;
glassFaces = faces(vehicleMesh.FacePartIndex==2,:);
glassCenters = (vertices(glassFaces(:,1),:) + vertices(glassFaces(:,2),:) + vertices(glassFaces(:,3),:))/3;
glassNormals = vehicleMesh.FaceNormals(vehicleMesh.FacePartIndex==2,:);
assert(all(sum(glassNormals.*(glassCenters - vehicleCenter),2) > 0));
end % Ends fcn_INTERNAL_checkOutward

%% fcn_INTERNAL_signedVolume
function signedVolume = fcn_INTERNAL_signedVolume(vertices, faces)
% Signed volume enclosed by triangles (positive if normals point out)
referencePoint = mean(vertices(faces(:),:),1);
v1 = vertices(faces(:,1),:) - referencePoint;
v2 = vertices(faces(:,2),:) - referencePoint;
v3 = vertices(faces(:,3),:) - referencePoint;
signedVolume = sum(dot(v1, cross(v2, v3, 2), 2))/6;
end % Ends fcn_INTERNAL_signedVolume

%% fcn_INTERNAL_box
function [vertices, faces] = fcn_INTERNAL_box(limits)
% A closed box [xmin xmax ymin ymax zmin zmax], 12 outward triangles
x = limits(1:2); y = limits(3:4); z = limits(5:6);
vertices = [x(1) y(1) z(1); x(2) y(1) z(1); x(2) y(2) z(1); x(1) y(2) z(1); ...
            x(1) y(1) z(2); x(2) y(1) z(2); x(2) y(2) z(2); x(1) y(2) z(2)];
faces = [1 3 2; 1 4 3; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];
end % Ends fcn_INTERNAL_box
