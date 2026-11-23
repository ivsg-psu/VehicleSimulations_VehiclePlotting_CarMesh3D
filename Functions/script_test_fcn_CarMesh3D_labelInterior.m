% script_test_fcn_CarMesh3D_labelInterior.m
% Tests fcn_CarMesh3D_labelInterior

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_labelInterior
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_labelInterior
%   % * (none yet)

%% Set up the workspace
close all;

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _____                              ____   __    _____          _
% |  __ \                            / __ \ / _|  / ____|        | |
% | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
% | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
% | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
% |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: The 2009 Honda Fit's interior
figNum = 10001;
titleString = sprintf('DEMO case: The 2009 Honda Fit''s interior');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport', FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;
if any(strcmp(fitMesh.PartNames,'interior'))
    % (a mesh labeled already: its interior faces put back to trim first)
    fitMesh.FacePartIndex(fitMesh.FacePartIndex==find(strcmp(fitMesh.PartNames,'interior'))) = find(strcmp(fitMesh.PartNames,'trim'));
end
[labeledFit, interiorInfo] = fcn_CarMesh3D_labelInterior(fitMesh, FigNum=figNum);
title(sprintf('%s: %d interior faces', titleString, interiorInfo.NumInterior), 'Interpreter','none');

% Check variable values: some interior faces; the steering wheel (the
% highest one-sided piece simplifyMesh kept) is mostly interior
interiorPart = find(strcmp(labeledFit.PartNames,'interior'));
assert(~isempty(interiorPart) && interiorInfo.NumInterior > 0);
assert(nnz(labeledFit.FacePartIndex==interiorPart) == interiorInfo.NumInterior);
if isfield(fitMesh.SimplifyInfo,'OneSidedBoxes') && ~isempty(fitMesh.SimplifyInfo.OneSidedBoxes)
    boxes = fitMesh.SimplifyInfo.OneSidedBoxes;
    [~, highest] = max(boxes(:,6));
    wheelBox = boxes(highest,:);
    centers = (labeledFit.Vertices(labeledFit.Faces(:,1),:) + labeledFit.Vertices(labeledFit.Faces(:,2),:) + labeledFit.Vertices(labeledFit.Faces(:,3),:))/3;
    inBox = all(centers >= wheelBox([1 3 5]) & centers <= wheelBox([2 4 6]), 2) & labeledFit.FaceWheelIndex==0;
    assert(mean(labeledFit.FacePartIndex(inBox)==interiorPart) > 0.5);
end
% (glass, lights, and wheels never change)
glassPart = find(strcmp(fitMesh.PartNames,'glass'));
assert(isequal(labeledFit.FacePartIndex(fitMesh.FacePartIndex==glassPart), fitMesh.FacePartIndex(fitMesh.FacePartIndex==glassPart)));
assert(all(labeledFit.FacePartIndex(fitMesh.FaceWheelIndex>0) == fitMesh.FacePartIndex(fitMesh.FaceWheelIndex>0)));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here. These are very simple, usually trivial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______ ______  _____ _______ _____
% |__   __|  ____|/ ____|__   __/ ____|
%    | |  | |__  | (___    | | | (___
%    | |  |  __|  \___ \   | |  \___ \
%    | |  | |____ ____) |  | |  ____) |
%    |_|  |______|_____/   |_| |_____/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEST case: A box car: the seat behind the glass is interior; the engine under the hood is not
figNum = 20001;
titleString = sprintf('TEST case: A box car: the seat behind the glass is interior; the engine under the hood is not');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[boxCar, faceRole] = fcn_INTERNAL_boxCar([]);
labeled = fcn_CarMesh3D_labelInterior(boxCar, FigNum=[]);
interiorPart = find(strcmp(labeled.PartNames,'interior'));

% Check variable values
assert(all(labeled.FacePartIndex(strcmp(faceRole,'seat')) == interiorPart));
assert(~any(labeled.FacePartIndex(strcmp(faceRole,'engine')) == interiorPart));    % (sealed under the hood)
% (the outer walls are seen from outside; the wall between the cabin and
% the engine compartment, at x = 3 m, is a firewall: seen only through the
% glass, so interior)
shellCenters = (labeled.Vertices(labeled.Faces(:,1),:) + labeled.Vertices(labeled.Faces(:,2),:) + labeled.Vertices(labeled.Faces(:,3),:))/3;
onFirewall = abs(shellCenters(:,1) - 3) < 1e-9;
assert(~any(labeled.FacePartIndex(strcmp(faceRole,'shell') & ~onFirewall) == interiorPart));
assert(any(labeled.FacePartIndex(strcmp(faceRole,'shell') & onFirewall) == interiorPart));
assert(all(strcmp(labeled.PartNames(labeled.FacePartIndex(strcmp(faceRole,'glass'))), 'glass')));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A small hole in the floor does not make the cabin exterior; a large one does
figNum = 20002;
titleString = sprintf('TEST case: A small hole in the floor does not make the cabin exterior; a large one does');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (a 10 cm hole: smaller than GapSize, closed)
[smallHole, faceRole] = fcn_INTERNAL_boxCar([1.70 1.80 -0.05 0.05]);
labeled = fcn_CarMesh3D_labelInterior(smallHole, FigNum=-1);
interiorPart = find(strcmp(labeled.PartNames,'interior'));
assert(all(labeled.FacePartIndex(strcmp(faceRole,'seat')) == interiorPart));
% (a 50 cm hole under the seat: the outside comes in, so the seat is
% seen from outside, not only through the glass)
[largeHole, faceRole] = fcn_INTERNAL_boxCar([1.50 2.00 -0.25 0.25]);
labeled = fcn_CarMesh3D_labelInterior(largeHole, FigNum=-1);
interiorPart = find(strcmp(labeled.PartNames,'interior'));
assert(~any(labeled.FacePartIndex(strcmp(faceRole,'seat')) == interiorPart));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Parts limits what may be relabeled; 'interior' is added once
figNum = 20003;
titleString = sprintf('TEST case: Parts limits what may be relabeled; ''interior'' is added once');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[boxCar, faceRole] = fcn_INTERNAL_boxCar([]);
labeled = fcn_CarMesh3D_labelInterior(boxCar, Parts={'body'}, FigNum=-1);     % (the seat is trim)
assert(~any(labeled.FacePartIndex(strcmp(faceRole,'seat')) == find(strcmp(labeled.PartNames,'interior'))));
assert(labeled.InteriorInfo.NumFromPart.body == labeled.InteriorInfo.NumInterior);   % (only body faces: the firewall)
labeledTwice = fcn_CarMesh3D_labelInterior(fcn_CarMesh3D_labelInterior(boxCar, FigNum=-1), FigNum=-1);
assert(nnz(strcmp(labeledTwice.PartNames,'interior')) == 1);
once = fcn_CarMesh3D_labelInterior(boxCar, FigNum=-1);
assert(isequal(labeledTwice.FacePartIndex, once.FacePartIndex));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);
[boxCar, faceRole] = fcn_INTERNAL_boxCar([]);
labeled = fcn_CarMesh3D_labelInterior(boxCar, FigNum=[]);
assert(all(labeled.FacePartIndex(strcmp(faceRole,'seat')) == find(strcmp(labeled.PartNames,'interior'))));
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);
labeled = fcn_CarMesh3D_labelInterior(boxCar, FigNum=-1);
assert(all(labeled.FacePartIndex(strcmp(faceRole,'seat')) == find(strcmp(labeled.PartNames,'interior'))));
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fail conditions
if 1==0
    %% FAIL case: not a labeled mesh
    fcn_CarMesh3D_labelInterior(struct('Vertices',[],'Faces',[]), FigNum=1);

    %% FAIL case: a voxel size that is not positive
    fcn_CarMesh3D_labelInterior(fcn_INTERNAL_boxCar([]), VoxelSize=0);
end

fprintf(1,'All tests of fcn_CarMesh3D_labelInterior passed\n');

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

%% fcn_INTERNAL_boxCar
function [vehicleMesh, faceRole] = fcn_INTERNAL_boxCar(floorHole)
% A box "car": a cabin [1 3] x [-0.8 0.8] x [0.2 1.3] with a glass roof
% and body walls and floor, a sealed engine compartment [3 4] (all body,
% hood included) holding an "engine" block (trim), and a "seat" block
% (trim) inside the cabin. The cabin floor is made of 10 cm squares;
% floorHole = [xmin xmax ymin ymax] leaves those squares out ([] for
% none). faceRole names each face: 'shell', 'glass', 'seat', 'engine'.
vertices = zeros(0,3);
faces = zeros(0,3);
faceRole = {};
partOfFace = zeros(0,1);
    function addPanel(cornerA, stepU, stepV, numU, numV, role, part, skip)
        for iu = 0:numU-1
            for iv = 0:numV-1
                p = cornerA + iu*stepU + iv*stepV;
                q = [p; p + stepU; p + stepU + stepV; p + stepV];
                center = mean(q,1);
                if ~isempty(skip) && center(1) > skip(1) && center(1) < skip(2) && center(2) > skip(3) && center(2) < skip(4)
                    continue;
                end
                base = size(vertices,1);
                vertices = [vertices; q]; %#ok<AGROW>
                faces = [faces; base + [1 2 3; 1 3 4]]; %#ok<AGROW>
                faceRole = [faceRole; {role; role}]; %#ok<AGROW>
                partOfFace = [partOfFace; part; part]; %#ok<AGROW>
            end
        end
    end
    function addBox(limits, role, part, floorSkip)
        x = limits(1:2); y = limits(3:4); z = limits(5:6);
        s = 0.1;
        nx = round(diff(x)/s); ny = round(diff(y)/s); nz = round(diff(z)/s);
        addPanel([x(1) y(1) z(1)], [s 0 0], [0 s 0], nx, ny, role, part, floorSkip);       % floor
        addPanel([x(1) y(1) z(1)], [s 0 0], [0 0 s], nx, nz, role, part, []);              % right wall
        addPanel([x(1) y(2) z(1)], [s 0 0], [0 0 s], nx, nz, role, part, []);              % left wall
        addPanel([x(1) y(1) z(1)], [0 s 0], [0 0 s], ny, nz, role, part, []);              % rear wall
        addPanel([x(2) y(1) z(1)], [0 s 0], [0 0 s], ny, nz, role, part, []);              % front wall
    end
% (the cabin: body floor and walls, glass roof)
addBox([1 3 -0.8 0.8 0.2 1.3], 'shell', 1, floorHole);
addPanel([1 -0.8 1.3], [0.1 0 0], [0 0.1 0], 20, 16, 'glass', 2, []);
% (the engine compartment: body, closed by a body hood)
addBox([3 4 -0.8 0.8 0.2 1.0], 'shell', 1, []);
addPanel([3 -0.8 1.0], [0.1 0 0], [0 0.1 0], 10, 16, 'shell', 1, []);
% (the seat and the engine: trim blocks, closed boxes)
addBox([1.5 2.0 -0.3 0.3 0.4 0.8], 'seat', 5, []);
addPanel([1.5 -0.3 0.8], [0.1 0 0], [0 0.1 0], 5, 6, 'seat', 5, []);
addBox([3.3 3.7 -0.3 0.3 0.4 0.7], 'engine', 5, []);
addPanel([3.3 -0.3 0.7], [0.1 0 0], [0 0.1 0], 4, 6, 'engine', 5, []);
numFaces = size(faces,1);
vehicleMesh = struct();
vehicleMesh.Name = 'box car';
vehicleMesh.Vertices = vertices;
vehicleMesh.Faces = faces;
vehicleMesh.PartNames = {'body';'glass';'wheel';'light';'trim'};
vehicleMesh.FacePartIndex = partOfFace;
vehicleMesh.FaceWheelIndex = zeros(numFaces,1);
vehicleMesh.FaceColors = repmat([0.5 0.5 0.5], numFaces, 1);
vehicleMesh.FaceAlpha = ones(numFaces,1);
end % Ends fcn_INTERNAL_boxCar
