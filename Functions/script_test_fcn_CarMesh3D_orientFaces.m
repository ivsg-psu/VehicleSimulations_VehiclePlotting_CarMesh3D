% script_test_fcn_CarMesh3D_orientFaces.m
% Tests fcn_CarMesh3D_orientFaces
% Turns each face of a mesh to point the same way as its neighbors.
%
% The test meshes are made here: a flat grid (every face pointing up),
% with chosen faces turned over. Figures are made hidden and closed by
% their handles.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_orientFaces
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_orientFaces
%   % * (fill in items here)


%% Set up the workspace
% A flat grid of 20 x 20 squares (800 triangles), every face pointing up
% (+z), as a stand-in for a panel of a car
[gridX, gridY] = meshgrid(0:20, 0:20);
gridVertices = [gridX(:) gridY(:) zeros(numel(gridX),1)]*0.05;   % (5 cm squares: a 1 m panel)
gridFaces = zeros(0,3);
for ith_row = 1:20
    for ith_column = 1:20
        corner = (ith_column - 1)*21 + ith_row;   % (the lower-left corner's index)
        gridFaces(end+1,:) = [corner, corner + 21, corner + 22]; %#ok<SAGROW>
        gridFaces(end+1,:) = [corner, corner + 22, corner + 1]; %#ok<SAGROW>
    end
end
gridMesh = struct('Vertices', gridVertices, 'Faces', gridFaces);
gridNormals = cross(gridVertices(gridFaces(:,2),:) - gridVertices(gridFaces(:,1),:), ...
    gridVertices(gridFaces(:,3),:) - gridVertices(gridFaces(:,1),:), 2);
assert(all(gridNormals(:,3) > 0), 'The test grid points up');

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

fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: a small patch turned over in the middle of the panel
figNum = 10001;
titleString = sprintf('DEMO case: a small patch turned over in the middle of the panel');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
testMesh = gridMesh;
flagMiddle = fcn_INTERNAL_facesIn(testMesh, [0.40 0.60], [0.40 0.60]);   % (a 20 x 20 cm patch: 32 faces)
testMesh.Faces(flagMiddle,:) = testMesh.Faces(flagMiddle,[1 3 2]);
[fixedMesh, info] = fcn_CarMesh3D_orientFaces(testMesh, FigNum=figNum);
assert(isequal(fixedMesh.Faces, gridMesh.Faces), 'The patch is turned back');
assert(info.NumFlipped == nnz(flagMiddle));
assert(isequal(sort(info.FlippedFaces), find(flagMiddle)));
close(figureHandle);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _______        _
%  |__   __|      | |
%     | | ___  ___| |_ ___
%     | |/ _ \/ __| __/ __|
%     | |  __/\__ \ |_\__ \
%     |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% TEST case: a mesh with nothing wrong is left alone
figNum = 20001;
titleString = sprintf('TEST case: a mesh with nothing wrong is left alone');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
[fixedMesh, info] = fcn_CarMesh3D_orientFaces(gridMesh);
assert(isequal(fixedMesh.Faces, gridMesh.Faces) && info.NumFlipped == 0);
assert(info.NumPatches == 1);

%% TEST case: one face turned over (the sweep alone would find it too)
figNum = 20002;
titleString = sprintf('TEST case: one face turned over');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
testMesh = gridMesh;
testMesh.Faces(200,:) = testMesh.Faces(200,[1 3 2]);
[fixedMesh, info] = fcn_CarMesh3D_orientFaces(testMesh);
assert(isequal(fixedMesh.Faces, gridMesh.Faces) && info.NumFlipped == 1 && info.FlippedFaces == 200);

%% TEST case: a large turned-over region is not flipped (too large a patch)
figNum = 20003;
titleString = sprintf('TEST case: a large turned-over region is not flipped by the patch rule');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
testMesh = gridMesh;
flagHalf = fcn_INTERNAL_facesIn(testMesh, [0 0.5], [0 1]);   % (half the panel: 400 faces)
testMesh.Faces(flagHalf,:) = testMesh.Faces(flagHalf,[1 3 2]);
[~, info] = fcn_CarMesh3D_orientFaces(testMesh, NumSweeps=0);
assert(info.NumFlipped == 0, 'Two patches of equal size: neither is flipped');

%% TEST case: the sweep cleans a backward patch the patch rule leaves (too large)
figNum = 20004;
titleString = sprintf('TEST case: the sweep turns the border of a large backward patch');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
testMesh = gridMesh;
flagBig = fcn_INTERNAL_facesIn(testMesh, [0.25 0.75], [0.25 0.75]);   % (200 faces: over MaxPatchFaces)
testMesh.Faces(flagBig,:) = testMesh.Faces(flagBig,[1 3 2]);
[~, infoPatchOnly] = fcn_CarMesh3D_orientFaces(testMesh, NumSweeps=0);
assert(infoPatchOnly.NumFlipped == 0, 'Too large for the patch rule');
% (on a flat grid a border face has one neighbor across the border and
% two that agree: mean dot -1/3, above the default cutoff -0.5, so the
% default sweep leaves a clean square border alone; a cutoff of -0.3
% takes the border faces on both sides of it)
[~, infoSweep] = fcn_CarMesh3D_orientFaces(testMesh, NumSweeps=1);
assert(infoSweep.NumFlipped == 0, 'At -0.5 the sweep leaves a clean border alone');
[~, infoSweep] = fcn_CarMesh3D_orientFaces(testMesh, NumSweeps=1, SweepCutoff=-0.3);
assert(infoSweep.NumSweepFlipped > 0, 'At -0.3 the sweep flips border faces');
[fixedMesh, ~] = fcn_CarMesh3D_orientFaces(testMesh, MaxPatchFaces=500);
assert(isequal(fixedMesh.Faces, gridMesh.Faces), 'With a larger MaxPatchFaces the patch rule takes it all');

%% TEST case: FaceNormals are turned with the faces
figNum = 20005;
titleString = sprintf('TEST case: FaceNormals are turned with the faces');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
testMesh = gridMesh;
testMesh.FaceNormals = repmat([0 0 1], size(gridFaces,1), 1);
testMesh.Faces(200,:) = testMesh.Faces(200,[1 3 2]);
testMesh.FaceNormals(200,:) = [0 0 -1];
fixedMesh = fcn_CarMesh3D_orientFaces(testMesh);
assert(isequal(fixedMesh.FaceNormals(200,:), [0 0 1]));

%% TEST case: every other field is left as it was (labels, colors)
figNum = 20006;
titleString = sprintf('TEST case: every other field is left as it was');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
testMesh = gridMesh;
testMesh.FacePartIndex = ones(size(gridFaces,1),1);
testMesh.FaceColors = rand(size(gridFaces,1),3);
testMesh.Faces(200,:) = testMesh.Faces(200,[1 3 2]);
fixedMesh = fcn_CarMesh3D_orientFaces(testMesh);
assert(isequal(fixedMesh.FacePartIndex, testMesh.FacePartIndex) && isequal(fixedMesh.FaceColors, testMesh.FaceColors) ...
    && isequal(fixedMesh.Vertices, testMesh.Vertices));
assert(isequal(sort(fieldnames(fixedMesh)), sort(fieldnames(testMesh))), 'No fields added or removed');

%% TEST case: the 2009 Fit's driver door handle (the 28 faces Sean found, 02:20)
figNum = 20007;
titleString = sprintf('TEST case: the 2009 Fit''s driver door handle');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
fitMesh = fcn_CarMesh3D_meshWithLabelEdits('2009_Honda_Fit_Sport', OrientFaces=false, FigNum=-1);   % (the faces as saved)
fitCenters = (fitMesh.Vertices(fitMesh.Faces(:,1),:) + fitMesh.Vertices(fitMesh.Faces(:,2),:) + fitMesh.Vertices(fitMesh.Faces(:,3),:))/3;
fitNormals = cross(fitMesh.Vertices(fitMesh.Faces(:,2),:) - fitMesh.Vertices(fitMesh.Faces(:,1),:), ...
    fitMesh.Vertices(fitMesh.Faces(:,3),:) - fitMesh.Vertices(fitMesh.Faces(:,1),:), 2);
flagHandle = fitCenters(:,1) > 0.85 & fitCenters(:,1) < 1.3 & fitCenters(:,2) > 0.7 & fitCenters(:,3) > 0.78 & fitCenters(:,3) < 0.95;
flagInward = flagHandle & fitNormals(:,2) < -0.3*vecnorm(fitNormals,2,2);
if nnz(flagInward) > 0   % (none once the Fit's mesh carries the fix)
    % (22 of the 28 are flipped; the other 6 are tiny faces, about 10 mm^2
    % each, at the lock cylinder (x 1.13 m), which Sean's look at 03:12
    % passed: what remains are seams and such thin details)
    [~, info] = fcn_CarMesh3D_orientFaces(fitMesh);
    numCaught = nnz(ismember(find(flagInward), info.FlippedFaces));
    assert(numCaught >= 0.75*nnz(flagInward), 'Most inward handle faces are flipped: %d of %d', numCaught, nnz(flagInward));
end

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ______        _     __  __           _        _______        _
%  |  ____|      | |   |  \/  |         | |      |__   __|      | |
%  | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
%  |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
%  | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
%  |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty fig_num\n',figNum);
figuresBefore = findall(groot, 'Type', 'figure');
fixedMesh = fcn_CarMesh3D_orientFaces(gridMesh, FigNum=[]);
assert(isequal(fixedMesh.Faces, gridMesh.Faces));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, fig_num=-1\n',figNum);
fixedMesh = fcn_CarMesh3D_orientFaces(gridMesh, FigNum=-1);
assert(isequal(fixedMesh.Faces, gridMesh.Faces));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 20;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_orientFaces(gridMesh, FigNum=[]);
end
slowMethod = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_orientFaces(gridMesh, FigNum=-1);
end
fastMethod = toc;
fprintf(1,'Fast mode, %.0f calls: slow %.4f s, fast %.4f s\n', Niterations, slowMethod, fastMethod);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% (none yet)

%% Fail conditions
if 1==0
    %% Not a mesh
    fcn_CarMesh3D_orientFaces(42);
    %% Not triangles
    fcn_CarMesh3D_orientFaces(struct('Vertices', rand(4,3), 'Faces', [1 2 3 4]));
    %% A cutoff outside -1..1
    fcn_CarMesh3D_orientFaces(gridMesh, SweepCutoff=2);
end


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_facesIn
function flagFaces = fcn_INTERNAL_facesIn(mesh, xRange, yRange)
% The faces whose centers lie inside a box in x and y
centers = (mesh.Vertices(mesh.Faces(:,1),:) + mesh.Vertices(mesh.Faces(:,2),:) + mesh.Vertices(mesh.Faces(:,3),:))/3;
flagFaces = centers(:,1) > xRange(1) & centers(:,1) < xRange(2) & centers(:,2) > yRange(1) & centers(:,2) < yRange(2);
end % Ends fcn_INTERNAL_facesIn
