% script_test_fcn_CarMesh3D_findLampCovers.m
% Tests fcn_CarMesh3D_findLampCovers
% Finds the clear glass covers lying over a vehicle's lamps, and makes
% each one clear glass that covers that lamp (FaceCoverLamp).

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findLampCovers
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findLampCovers
%   % * (fill in items here)


%% Set up the workspace
close all

% A small labeled mesh (see fcn_INTERNAL_coverMesh at the end): a
% headlight with a glass face 2 cm in front of it, a glass "window" far
% from any lamp, a left and a right turn signal each with a cover marked
% the old way (a light that is also glass), and a body panel
[testMesh, faceInfo] = fcn_INTERNAL_coverMesh;
headType = find(strcmp(testMesh.LightTypeNames,'headlamp'));
turnType = find(strcmp(testMesh.LightTypeNames,'turnSignalLamp'));
glassIndex = find(strcmp(testMesh.PartNames,'glass'));
lightIndex = find(strcmp(testMesh.PartNames,'light'));

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

%% DEMO case: Find the lamp covers of a small test mesh
figNum = 10001;
titleString = sprintf('DEMO case: Find the lamp covers of a small test mesh');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(coveredMesh));
assert(isnumeric(coveredMesh.FaceCoverLamp));

% Check variable sizes
Nfaces = size(testMesh.Faces,1);
assert(isequal(size(coveredMesh.FaceCoverLamp),[Nfaces 1]));
assert(isequal(size(coveredMesh.FacePartIndex),[Nfaces 1]));

% Check variable values
% (the glass 2 cm in front of the headlight covers it, and is clear glass)
assert(all(coveredMesh.FaceCoverLamp(faceInfo.headCover)==headType));
assert(all(coveredMesh.FacePartIndex(faceInfo.headCover)==glassIndex));
assert(all(abs(coveredMesh.FaceAlpha(faceInfo.headCover) - 0.15) < 1e-12));
assert(all(all(abs(coveredMesh.FaceColors(faceInfo.headCover,:) - [0.90 0.90 0.90]) < 1e-12)));
% (the window, far from any lamp, is not a cover, and is not changed)
assert(all(coveredMesh.FaceCoverLamp(faceInfo.window)==0));
assert(isequal(coveredMesh.FaceColors(faceInfo.window,:), testMesh.FaceColors(faceInfo.window,:)));
assert(isequal(coveredMesh.FaceAlpha(faceInfo.window), testMesh.FaceAlpha(faceInfo.window)));
% (the lamps stay lamps)
assert(all(coveredMesh.FaceLightType(faceInfo.headLamp)==headType));
assert(all(coveredMesh.FaceLightType([faceInfo.leftTurnLamp; faceInfo.rightTurnLamp])==turnType));
% (only the covers changed)
assert(nnz(coveredMesh.FaceCoverLamp) == numel(faceInfo.headCover) + numel(faceInfo.leftTurnCover) + numel(faceInfo.rightTurnCover));

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

%% TEST case: A lamp that is also glass, over a lamp, becomes clear glass covering it
figNum = 20001;
titleString = sprintf('TEST case: A lamp that is also glass, over a lamp, becomes clear glass covering it');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh);
turnCovers = [faceInfo.leftTurnCover; faceInfo.rightTurnCover];
% (before: lights that are also glass)
assert(all(testMesh.FacePartIndex(turnCovers)==lightIndex) && all(testMesh.FaceAlsoParts(turnCovers,glassIndex)));
% (after: glass only, no longer lamps, covering the turn signals)
assert(all(coveredMesh.FacePartIndex(turnCovers)==glassIndex));
assert(all(coveredMesh.FaceLightType(turnCovers)==0));
assert(~any(coveredMesh.FaceAlsoParts(turnCovers,:),'all'));
assert(all(coveredMesh.FaceCoverLamp(turnCovers)==turnType));
assert(all(abs(coveredMesh.FaceAlpha(turnCovers) - 0.15) < 1e-12));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Distance sets how far behind the glass a lamp is looked for
figNum = 20002;
titleString = sprintf('TEST case: Distance sets how far behind the glass a lamp is looked for');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (the headlight's glass is 2 cm in front of it: not found within 1 cm)
nearMesh = fcn_CarMesh3D_findLampCovers(testMesh, Distance=0.01);
assert(all(nearMesh.FaceCoverLamp(faceInfo.headCover)==0));
assert(all(nearMesh.FacePartIndex(faceInfo.headCover)==glassIndex));
assert(isequal(nearMesh.FaceAlpha(faceInfo.headCover), testMesh.FaceAlpha(faceInfo.headCover)));
% (the window is 1 m from the lamps: not a cover even within 0.5 m)
farMesh = fcn_CarMesh3D_findLampCovers(testMesh, Distance=0.5);
assert(all(farMesh.FaceCoverLamp(faceInfo.window)==0));
% (ClearAlpha and ClearColor set the covers' look)
lookMesh = fcn_CarMesh3D_findLampCovers(testMesh, ClearAlpha=0.2, ClearColor=[1 1 1]);
assert(all(abs(lookMesh.FaceAlpha(faceInfo.headCover) - 0.2) < 1e-12));
assert(all(all(lookMesh.FaceColors(faceInfo.headCover,:)==1)));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Running again gives the same mesh; hidden faces and unlabeled meshes are left alone
figNum = 20003;
titleString = sprintf('TEST case: Running again gives the same mesh; hidden faces and unlabeled meshes are left alone');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh);
againMesh = fcn_CarMesh3D_findLampCovers(coveredMesh);
assert(isequal(againMesh, coveredMesh));
% (a hidden cover stays as it is)
hiddenMesh = testMesh;
hiddenMesh.FaceHiddenSet = zeros(Nfaces,1);
hiddenMesh.FaceHiddenSet(faceInfo.headCover) = 1;
hiddenMesh.HiddenSetNames = {'hidden'};
hiddenCovered = fcn_CarMesh3D_findLampCovers(hiddenMesh);
assert(all(hiddenCovered.FaceCoverLamp(faceInfo.headCover)==0));
assert(all(hiddenCovered.FaceCoverLamp(turnCovers)==turnType));
% (a face that was a cover but is no longer glass is not a cover)
paintedMesh = coveredMesh;
paintedMesh.FacePartIndex(faceInfo.headCover) = find(strcmp(testMesh.PartNames,'trim'));
paintedCovered = fcn_CarMesh3D_findLampCovers(paintedMesh);
assert(all(paintedCovered.FaceCoverLamp(faceInfo.headCover)==0));
% (an unlabeled mesh: all zeros, nothing else changed)
plainMesh = struct('Vertices',testMesh.Vertices,'Faces',testMesh.Faces);
plainCovered = fcn_CarMesh3D_findLampCovers(plainMesh);
assert(isequal(plainCovered.FaceCoverLamp, zeros(Nfaces,1)));
assert(isequal(rmfield(plainCovered,'FaceCoverLamp'), plainMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Outward FaceNormals are used; without them, both sides of the glass are searched
figNum = 20004;
titleString = sprintf('TEST case: Outward FaceNormals are used; without them, both sides are searched');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (the glass faces turned around: their right-hand-rule normals point
% at the lamp; found without FaceNormals...)
flippedMesh = testMesh;
flippedMesh.Faces(faceInfo.headCover,:) = flippedMesh.Faces(faceInfo.headCover,[1 3 2]);
flippedCovered = fcn_CarMesh3D_findLampCovers(flippedMesh);
assert(all(flippedCovered.FaceCoverLamp(faceInfo.headCover)==headType));
% (...and, with outward FaceNormals given, along minus the normal only:
% normals pointing into the car find the lamp; pointing away, they do not)
normalsMesh = testMesh;
normalsMesh.FaceNormals = repmat([1 0 0], Nfaces, 1);
assert(all(fcn_CarMesh3D_findLampCovers(normalsMesh).FaceCoverLamp(faceInfo.headCover)==headType));
normalsMesh.FaceNormals = repmat([-1 0 0], Nfaces, 1);
assert(all(fcn_CarMesh3D_findLampCovers(normalsMesh).FaceCoverLamp(faceInfo.headCover)==0));

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

coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=[]);
assert(all(coveredMesh.FaceCoverLamp(faceInfo.headCover)==headType));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=-1);
assert(all(coveredMesh.FaceCoverLamp(faceInfo.headCover)==headType));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

Niterations = 50;

% Normal mode
tic;
for ith_test = 1:Niterations
    coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=[]);
end
slow_method = toc;

% Fast mode
tic;
for ith_test = 1:Niterations
    coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=-1);
end
fast_method = toc;

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

X = categorical({'Normal mode','Fast mode'});
X = reordercats(X,{'Normal mode','Fast mode'}); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method fast_method ]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));
close(373737);

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
if 1==0
    %% FAIL case: Not a mesh
    fcn_CarMesh3D_findLampCovers(42);

    %% FAIL case: Distance not positive
    fcn_CarMesh3D_findLampCovers(testMesh, Distance=0);

    %% FAIL case: ClearAlpha out of range
    fcn_CarMesh3D_findLampCovers(testMesh, ClearAlpha=2);
end

fprintf(1,'All tests of fcn_CarMesh3D_findLampCovers passed\n');

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

%% fcn_INTERNAL_coverMesh
function [testMesh, faceInfo] = fcn_INTERNAL_coverMesh
% A small labeled mesh, in meters (X forward, Y left, Z up), made of
% flat squares facing forward (+X), two triangles each:
%   a headlight at x = 1.00, and plain glass 2 cm in front of it
%   a glass "window" at x = 0.00, 1 m behind the lamps
%   a left and a right turn signal at x = 1.00, each with a cover 2 cm in
%   front of it marked the old way: a light that is also glass
%   a body panel below the lamps
partNames = {'body';'glass';'wheel';'light';'trim'};
lightTypeNames = {'headlamp';'turnSignalLamp';'runningLamp';'tailBrakeLamp';'backupLamp';'highBeamLamp'};
squares = { ...   % x, [ymin ymax], [zmin zmax], part, light type, also glass, name
    1.00, [ 0.40  0.60], [0.50 0.70], 4, 1, false, 'headLamp';
    1.02, [ 0.38  0.62], [0.48 0.72], 2, 0, false, 'headCover';
    0.00, [-0.50  0.50], [0.90 1.20], 2, 0, false, 'window';
    1.00, [ 0.65  0.75], [0.50 0.60], 4, 2, false, 'leftTurnLamp';
    1.02, [ 0.64  0.76], [0.49 0.61], 4, 2, true,  'leftTurnCover';
    1.00, [-0.75 -0.65], [0.50 0.60], 4, 2, false, 'rightTurnLamp';
    1.02, [-0.76 -0.64], [0.49 0.61], 4, 2, true,  'rightTurnCover';
    1.00, [-0.80  0.80], [0.20 0.45], 1, 0, false, 'body'};
vertices = zeros(0,3);
faces = zeros(0,3);
facePart = zeros(0,1);
faceLightType = zeros(0,1);
faceAlsoGlass = false(0,1);
faceInfo = struct;
for ith_square = 1:size(squares,1)
    [x, yRange, zRange] = squares{ith_square,1:3};
    % (corners in the order that makes the right-hand-rule normal +X)
    corners = [x yRange(1) zRange(1); x yRange(2) zRange(1); x yRange(2) zRange(2); x yRange(1) zRange(2)];
    base = size(vertices,1);
    vertices = [vertices; corners]; %#ok<AGROW>
    faces = [faces; base + [1 2 3; 1 3 4]]; %#ok<AGROW>
    facePart = [facePart; squares{ith_square,4}*[1;1]]; %#ok<AGROW>
    faceLightType = [faceLightType; squares{ith_square,5}*[1;1]]; %#ok<AGROW>
    faceAlsoGlass = [faceAlsoGlass; squares{ith_square,6}&[true;true]]; %#ok<AGROW>
    faceInfo.(squares{ith_square,7}) = size(faces,1) + [-1; 0];
end
Nfaces = size(faces,1);
partColors = [0.60 0.60 0.65; 0.15 0.20 0.25; 0.10 0.10 0.10; 0.95 0.90 0.80; 0.20 0.20 0.20];
faceAlpha = ones(Nfaces,1);
faceAlpha(facePart==2) = 0.35;
faceAlsoParts = false(Nfaces, numel(partNames));
faceAlsoParts(faceAlsoGlass, 2) = true;
testMesh = struct('Name','lamp cover test mesh', 'Units','m', 'Frame','ISO8855', ...
    'Vertices',vertices, 'Faces',faces, 'PartNames',{partNames}, 'FacePartIndex',facePart, ...
    'LightTypeNames',{lightTypeNames}, 'FaceLightType',faceLightType, 'FaceWheelIndex',zeros(Nfaces,1), ...
    'FaceColors',partColors(facePart,:), 'FaceAlpha',faceAlpha, 'FaceAlsoParts',faceAlsoParts);
end % Ends fcn_INTERNAL_coverMesh
