% script_test_fcn_CarMesh3D_importReport.m
% Tests fcn_CarMesh3D_importReport
% The report on a downloaded mesh after its first, coarse labels: the gate
% (lamps and glass told apart), where the glass is, and which lamps are
% under glass.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_importReport
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: a box vehicle with a covered headlamp, a bare tail lamp, a window, and stray glass
figNum = 10001;
titleString = sprintf('DEMO case: a box vehicle with a covered headlamp, a bare tail lamp, a window, and stray glass');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[testMesh, faceInfo] = fcn_INTERNAL_boxVehicle();
report = fcn_CarMesh3D_importReport(testMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isstruct(report));
assert(all(isfield(report, {'Gate','GateText','NumGlassFaces','NumLampFaces','NumLampAlsoGlass','GlassWhere', ...
    'NumWindowFaces','NumCoverFaces','NumElsewhereFaces','ElsewherePieces','LampsUnderGlass','LampsNotUnderGlass','Text'})));
assert(isequal(size(report.GlassWhere), [size(testMesh.Faces,1) 1]));
assert(iscell(report.Text));

% Check variable values
assert(report.Gate);
assert(report.NumLampFaces == 4 && report.NumGlassFaces == 6 && report.NumLampAlsoGlass == 0);
assert(all(report.GlassWhere(faceInfo.window) == 1));
assert(all(report.GlassWhere(faceInfo.cover) == 2));
assert(all(report.GlassWhere(faceInfo.stray) == 3));
assert(height(report.ElsewherePieces) == 1 && report.ElsewherePieces.Faces(1) == 2);
assert(abs(report.ElsewherePieces.CenterZ(1) - 0.5) < 1e-9);
assert(isequal(report.LampsUnderGlass, {'headlamp'}));
assert(isequal(report.LampsNotUnderGlass, {'tailBrakeLamp'}));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: the gate stops when there are no lamps
figNum = 20001;
titleString = sprintf('TEST case: the gate stops when there are no lamps');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

testMesh = fcn_INTERNAL_boxVehicle();
testMesh.LabelFaceLamp(:) = 0;
report = fcn_CarMesh3D_importReport(testMesh);
assert(~report.Gate && contains(report.GateText, 'no lamp faces'));
% (with no lamps, no glass is over a lamp: the low stray glass is still found)
assert(report.NumCoverFaces == 0 && report.NumElsewhereFaces == 4);

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: the gate stops when faces are both lamp and glass
figNum = 20002;
titleString = sprintf('TEST case: the gate stops when faces are both lamp and glass');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[testMesh, faceInfo] = fcn_INTERNAL_boxVehicle();
testMesh.LabelFaceAlsoParts = false(size(testMesh.Faces,1), numel(testMesh.LabelPartNames));
testMesh.LabelFaceAlsoParts(faceInfo.headlamp, strcmp(testMesh.LabelPartNames,'glass')) = true;
report = fcn_CarMesh3D_importReport(testMesh);
assert(~report.Gate && contains(report.GateText, 'both lamp and glass'));
assert(report.NumLampAlsoGlass == 2 && report.NumLampFaces == 2);

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: WindowHeight decides what counts as a window
figNum = 20003;
titleString = sprintf('TEST case: WindowHeight decides what counts as a window');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[testMesh, faceInfo] = fcn_INTERNAL_boxVehicle();
report = fcn_CarMesh3D_importReport(testMesh, WindowHeight=0.1);
assert(all(report.GlassWhere(faceInfo.stray) == 1));
assert(all(report.GlassWhere(faceInfo.cover) == 2));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: the report does not depend on the way faces point
figNum = 20004;
titleString = sprintf('TEST case: the report does not depend on the way faces point');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

testMesh = fcn_INTERNAL_boxVehicle();
reportBefore = fcn_CarMesh3D_importReport(testMesh);
testMesh.Faces = testMesh.Faces(:, [1 3 2]);
reportAfter = fcn_CarMesh3D_importReport(testMesh);
assert(isequal(reportBefore.GlassWhere, reportAfter.GlassWhere));
assert(isequal(reportBefore.LampsUnderGlass, reportAfter.LampsUnderGlass));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic fast mode - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
report = fcn_CarMesh3D_importReport(fcn_INTERNAL_boxVehicle(), FigNum=[]);
assert(report.Gate);
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
report = fcn_CarMesh3D_importReport(fcn_INTERNAL_boxVehicle(), FigNum=-1);
assert(report.Gate);
assert(isempty(findobj('Number',figNum)));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 10;
testMesh = fcn_INTERNAL_boxVehicle();

tic;
for ith_test = 1:Niterations
    report = fcn_CarMesh3D_importReport(testMesh, FigNum=[]);
end
slow_method = toc;

tic;
for ith_test = 1:Niterations
    report = fcn_CarMesh3D_importReport(testMesh, FigNum=-1);
end
fast_method = toc;

assert(isempty(findobj('Number',figNum)));

% Plot results as bar chart
figure(373737);
clf;
hold on;
X = categorical({'Normal mode','Fast mode'});
X = reordercats(X,{'Normal mode','Fast mode'});
Y = [slow_method fast_method ]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')
assert(isequal(get(gcf,'Number'),373737));
close(373737);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% (none yet)

%% Fail conditions
if 1==0
    %% A mesh with no labels
    fcn_CarMesh3D_importReport(struct('Vertices',zeros(3), 'Faces',[1 2 3]));
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_boxVehicle
function [testMesh, faceInfo] = fcn_INTERNAL_boxVehicle()
% A 4 m box "vehicle" (x 0 to 4, y -0.8 to 0.8, z 0.2 to 1.5) with:
% a headlamp on its front under glass 1 cm in front of it; a tail lamp on
% its back with no glass; a side window high on its left; and a stray
% piece of glass low on its right, not over any lamp
[x, y, z] = ndgrid([0 4], [-0.8 0.8], [0.2 1.5]);
boxVertices = [x(:) y(:) z(:)];
boxFaces = [1 3 4; 1 4 2; 5 6 8; 5 8 7; 1 2 6; 1 6 5; 3 7 8; 3 8 4; 1 5 7; 1 7 3; 2 4 8; 2 8 6];
pieces = {boxVertices, boxFaces, 'body', '';
    fcn_INTERNAL_square([4 0.5 0.7], [0 1 0], [0 0 1], 0.2), [1 2 3; 1 3 4], 'light', 'headlamp';
    fcn_INTERNAL_square([4.01 0.5 0.7], [0 1 0], [0 0 1], 0.24), [1 2 3; 1 3 4], 'glass', '';
    fcn_INTERNAL_square([0 0.5 0.7], [0 0 1], [0 1 0], 0.2), [1 2 3; 1 3 4], 'light', 'tailBrakeLamp';
    fcn_INTERNAL_square([2 0.801 1.25], [1 0 0], [0 0 1], 0.4), [1 2 3; 1 3 4], 'glass', '';
    fcn_INTERNAL_square([2 -0.801 0.5], [0 0 1], [1 0 0], 0.2), [1 2 3; 1 3 4], 'glass', ''};
partNames = {'body', 'trim', 'glass', 'light', 'wheel'};
lampNames = {fcn_CarMesh3D_lampTypes(FigNum=-1).Name}';
vertices = zeros(0,3);
faces = zeros(0,3);
facePart = zeros(0,1);
faceLamp = zeros(0,1);
firstFace = zeros(size(pieces,1),1);
for ith_piece = 1:size(pieces,1)
    firstFace(ith_piece) = size(faces,1) + 1;
    faces = [faces; pieces{ith_piece,2} + size(vertices,1)]; %#ok<AGROW>
    vertices = [vertices; pieces{ith_piece,1}]; %#ok<AGROW>
    numPieceFaces = size(pieces{ith_piece,2},1);
    facePart = [facePart; repmat(find(strcmp(partNames, pieces{ith_piece,3})), numPieceFaces, 1)]; %#ok<AGROW>
    lampKind = 0;
    if ~isempty(pieces{ith_piece,4})
        lampKind = find(strcmp(lampNames, pieces{ith_piece,4}));
    end
    faceLamp = [faceLamp; repmat(lampKind, numPieceFaces, 1)]; %#ok<AGROW>
end
testMesh = struct('Vertices', vertices, 'Faces', faces, 'LabelPartNames', {partNames}, 'LabelFacePart', facePart, ...
    'LabelLampNames', {lampNames}, 'LabelFaceLamp', faceLamp);
faceInfo = struct('headlamp', firstFace(2) + (0:1), 'cover', firstFace(3) + (0:1), 'tailLamp', firstFace(4) + (0:1), ...
    'window', firstFace(5) + (0:1), 'stray', firstFace(6) + (0:1));
end % Ends fcn_INTERNAL_boxVehicle

%% fcn_INTERNAL_square
function corners = fcn_INTERNAL_square(center, axis1, axis2, side)
% (the four corners of a square, in order around it)
half = side/2;
corners = center + [-half -half; half -half; half half; -half half]*[axis1; axis2];
end % Ends fcn_INTERNAL_square
