% script_test_fcn_CarMesh3D_makeDetailLevels.m
% Tests fcn_CarMesh3D_makeDetailLevels
% Makes the ladder of detail levels of a vehicle mesh, for animation.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeDetailLevels
%   % * First write of the code (drafted with Claude)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeDetailLevels
%   % * Hollow-level threshold 0.35 -> 0.30 of the box (the remade Transit
%   %   % Connect's 18-face level encloses 0.35)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeDetailLevels
%   % * (fill in items here)


%% Set up the workspace
close all

% The finished 2013 Prius (made by its vehicle script), and the sample car
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
loaded = load(priusFiles.MeshFile, 'vehicleMesh');
priusMesh = loaded.vehicleMesh;
transitFiles = fcn_CarMesh3D_findVehicleFiles('2014_Ford_TransitConnect_XLTCargoLWB');
loaded = load(transitFiles.MeshFile, 'vehicleMesh');
transitMesh = loaded.vehicleMesh;
sampleMesh = fcn_CarMesh3D_simplifyMesh(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1), FigNum=-1);

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

%% DEMO case: The Prius's ladder
figNum = 10001;
titleString = sprintf('DEMO case: The Prius''s ladder');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

detailLevels = fcn_CarMesh3D_makeDetailLevels(priusMesh, FigNum=figNum);
fprintf(1,'   Prius: D = %.2f m, shadow area %.2f m^2, made in %.1f s\n', detailLevels.SizeDiagonal, ...
    detailLevels.ShadowArea, detailLevels.MakeSeconds);
for ith_level = 1:numel(detailLevels.Levels)
    fprintf(1,'   up to %5.1f px: %4d faces\n', detailLevels.Levels(ith_level).MaxScreenSize, detailLevels.Levels(ith_level).Faces);
end

% Check variable types
assert(isstruct(detailLevels) && isstruct(detailLevels.Levels));
assert(isstruct(detailLevels.Levels(1).Mesh));

% Check variable sizes
assert(numel(detailLevels.Levels) >= 5);
assert(isequal(size(detailLevels.BoxCenter),[1 3]) && isequal(size(detailLevels.BoxSize),[1 3]));

% Check variable values: the size standard
boxLow = min(priusMesh.Vertices,[],1);
boxHigh = max(priusMesh.Vertices,[],1);
assert(abs(detailLevels.SizeDiagonal - norm(boxHigh-boxLow)) < 1e-9);
assert(max(abs(detailLevels.BoxCenter - (boxLow+boxHigh)/2)) < 1e-9);
assert(detailLevels.ShadowArea > 4 && detailLevels.ShadowArea < 8);          % a car: a few m^2
assert(detailLevels.SolidFraction > 0.45);                                    % solid, not hollow

% The ladder: sizes fall by Step, faces by about half, the last is a box
sizes = [detailLevels.Levels.MaxScreenSize];
faceCounts = [detailLevels.Levels.Faces];
assert(abs(sizes(1) - 105) < 1e-9 && all(abs(sizes(1:end-1)./sizes(2:end) - sqrt(2)) < 1e-9));
assert(all(diff(faceCounts) < 0) && detailLevels.Levels(end).IsBox && faceCounts(end)==5);
assert(~any([detailLevels.Levels(1:end-1).IsBox]));

% Each mesh level: the face count of the rule (within 5%), closed (no
% edge used by only one face: no gaps; reducing may pinch a thin part to
% an edge shared by four faces, which is allowed), normals out, one piece
for ith_level = 1:numel(detailLevels.Levels)-1
    levelMesh = detailLevels.Levels(ith_level).Mesh;
    ruleFaces = 2*0.2*detailLevels.ShadowArea*(sizes(ith_level)/detailLevels.SizeDiagonal)^2;
    assert(abs(size(levelMesh.Faces,1) - ruleFaces) <= 0.05*ruleFaces + 2);
    edges = sort([levelMesh.Faces(:,[1 2]); levelMesh.Faces(:,[2 3]); levelMesh.Faces(:,[3 1])], 2);
    [~, ~, edgeIndex] = unique(edges, 'rows');
    edgeUses = accumarray(edgeIndex, 1);
    assert(~any(edgeUses==1), 'Level %d has gaps', ith_level);
    assert(sum(edgeUses>2) <= max(3, 0.01*numel(edgeUses)), 'Level %d has many pinched edges', ith_level);
    corner1 = levelMesh.Vertices(levelMesh.Faces(:,1),:);
    corner2 = levelMesh.Vertices(levelMesh.Faces(:,2),:);
    corner3 = levelMesh.Vertices(levelMesh.Faces(:,3),:);
    assert(sum(dot(corner1, cross(corner2, corner3, 2), 2)) > 0);              % outward
    assert(all(levelMesh.FaceWheelIndex==0));
    assert(isequal(sort(fieldnames(levelMesh)), sort(fieldnames(priusMesh))));
    assert(any(levelMesh.LabelFacePart==1));                                    % body
    if size(levelMesh.Faces,1) >= 64
        assert(any(levelMesh.LabelFacePart==3));                                % and wheels, except the smallest
    end
end

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

%% TEST case: A van with open windows: the hull is solid, not a hollow shell
figNum = 20003;
titleString = sprintf('TEST case: A van with open windows: the hull is solid, not a hollow shell');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% The Transit Connect model has openings about 0.2 to 0.3 m across; with
% gaps closed only up to 0.06 m, the outside flows into the cab
transitLevels = fcn_CarMesh3D_makeDetailLevels(transitMesh);
leakyLevels = fcn_CarMesh3D_makeDetailLevels(transitMesh, GapSize=0.06);
fprintf(1,'   Transit Connect: solid fraction %.2f (GapSize 0.36 m), %.2f (GapSize 0.06 m)\n', ...
    transitLevels.SolidFraction, leakyLevels.SolidFraction);
assert(transitLevels.SolidFraction > 0.45 && leakyLevels.SolidFraction < 0.3);
for ith_level = 1:numel(transitLevels.Levels)-1
    levelMesh = transitLevels.Levels(ith_level).Mesh;
    corner1 = levelMesh.Vertices(levelMesh.Faces(:,1),:);
    corner2 = levelMesh.Vertices(levelMesh.Faces(:,2),:);
    corner3 = levelMesh.Vertices(levelMesh.Faces(:,3),:);
    enclosedVolume = sum(dot(corner1, cross(corner2, corner3, 2), 2))/6;
    % (a hollow shell encloses well under 0.3 of its box, as the leaky
    % levels above do; the coarsest solid level, 18 faces, encloses about
    % 0.35 since the Transit Connect was remade on 2026_11_21)
    assert(enclosedVolume > 0.30*prod(transitLevels.BoxSize), 'Level %d of the Transit Connect is hollow', ith_level);
end

%% TEST case: Fewer, larger steps; a smaller top
figNum = 20001;
titleString = sprintf('TEST case: Fewer, larger steps; a smaller top');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

detailLevels = fcn_CarMesh3D_makeDetailLevels(priusMesh, TopScreenSize=60, Step=2, MinFaces=30);
sizes = [detailLevels.Levels.MaxScreenSize];
assert(abs(sizes(1)-60) < 1e-9 && all(abs(sizes(1:end-1)./sizes(2:end) - 2) < 1e-9));
assert(all([detailLevels.Levels(1:end-1).Faces] >= 30*0.95));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A light mesh: levels that would need its full face count are not made
figNum = 20002;
titleString = sprintf('TEST case: A light mesh: levels that would need its full face count are not made');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

detailLevels = fcn_CarMesh3D_makeDetailLevels(sampleMesh, TopScreenSize=400);
assert(all([detailLevels.Levels.Faces] < size(sampleMesh.Faces,1)));
assert(detailLevels.Levels(1).MaxScreenSize < 400);       % the top sizes were skipped
assert(detailLevels.Levels(end).IsBox);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
detailLevels = fcn_CarMesh3D_makeDetailLevels(sampleMesh, FigNum=[]);
assert(detailLevels.Levels(end).IsBox);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
detailLevels = fcn_CarMesh3D_makeDetailLevels(sampleMesh, FigNum=-1);
assert(detailLevels.Levels(end).IsBox);

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

%% FAIL case: A mesh that is not labeled
if 1==0
    fcn_CarMesh3D_makeDetailLevels(struct('Vertices',rand(4,3), 'Faces',[1 2 3; 1 3 4]));
end
