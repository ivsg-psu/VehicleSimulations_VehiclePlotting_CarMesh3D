% script_test_fcn_CarMesh3D_outwardSides.m
% Tests fcn_CarMesh3D_outwardSides
% Tells which side of each face is seen from outside the vehicle, without
% trusting the face's direction.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_outwardSides
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

%% DEMO case: a box with some faces flipped
figNum = 10001;
titleString = sprintf('DEMO case: a box with some faces flipped');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

testMesh = fcn_INTERNAL_box();
flipped = [2 5 9];
testMesh.Faces(flipped,:) = testMesh.Faces(flipped,[1 3 2]);
[outwardSign, info] = fcn_CarMesh3D_outwardSides(testMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isequal(size(outwardSign), [12 1]));
assert(isstruct(info) && all(isfield(info, {'EscapesPlus','EscapesMinus','CrossingsPlus','CrossingsMinus','Rule'})));

% Check variable values: the flipped faces point inward, the rest outward,
% all decided by a line leaving the box
expected = ones(12,1);
expected(flipped) = -1;
assert(isequal(outwardSign, expected));
assert(all(info.Rule == 1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: FaceList judges only the faces given
figNum = 20001;
titleString = sprintf('TEST case: FaceList judges only the faces given');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

testMesh = fcn_INTERNAL_box();
testMesh.Faces(3,:) = testMesh.Faces(3,[1 3 2]);
outwardSign = fcn_CarMesh3D_outwardSides(testMesh, FaceList=[3 4]);
assert(isequal(outwardSign, [-1; 1]));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: glass is seen through; a face under glass still sees out
figNum = 20002;
titleString = sprintf('TEST case: glass is seen through');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (a pane 5 cm above the box's top, labeled glass, then labeled body)
testMesh = fcn_INTERNAL_box();
pane = [-0.6 -0.6 0.55; 0.6 -0.6 0.55; 0.6 0.6 0.55; -0.6 0.6 0.55];
testMesh.Faces = [testMesh.Faces; [1 2 3; 1 3 4] + size(testMesh.Vertices,1)];
testMesh.Vertices = [testMesh.Vertices; pane];
testMesh.LabelPartNames = {'body','trim','glass','light','wheel'};
testMesh.LabelFacePart = [ones(12,1); 3; 3];
[~, info] = fcn_CarMesh3D_outwardSides(testMesh, FaceList=[3 4]);   % (the box's top)
assert(all(info.EscapesPlus) && ~any(info.EscapesMinus));
testMesh.LabelFacePart(13:14) = 1;
[~, info] = fcn_CarMesh3D_outwardSides(testMesh, FaceList=[3 4]);
assert(~any(info.EscapesPlus) && ~any(info.EscapesMinus));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: when the geometry does not say, a face keeps its own direction
figNum = 20003;
titleString = sprintf('TEST case: when the geometry does not say, a face keeps its own direction');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (a lone square: both sides leave; its corner order decides, or its
% stored FaceNormals when given)
testMesh = struct('Vertices', [0 0 0; 1 0 0; 1 1 0; 0 1 0], 'Faces', [1 2 3; 1 3 4]);
[outwardSign, info] = fcn_CarMesh3D_outwardSides(testMesh);
assert(isequal(outwardSign, [1; 1]) && all(info.Rule == 2));
testMesh.FaceNormals = [0 0 -1; 0 0 1];
outwardSign = fcn_CarMesh3D_outwardSides(testMesh);
assert(isequal(outwardSign, [-1; 1]));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: faces within NearDistance are not counted
figNum = 20004;
titleString = sprintf('TEST case: faces within NearDistance are not counted');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (a square lying 1 mm outside the box's top: counted with NearDistance
% 0, so the top no longer sees out; not counted with the default 4 mm)
testMesh = fcn_INTERNAL_box();
cover = [-0.2 -0.2 0.501; 0.2 -0.2 0.501; 0.2 0.2 0.501; -0.2 0.2 0.501];
testMesh.Faces = [testMesh.Faces; [1 2 3; 1 3 4] + size(testMesh.Vertices,1)];
testMesh.Vertices = [testMesh.Vertices; cover];
[~, info] = fcn_CarMesh3D_outwardSides(testMesh, FaceList=[3 4], NearDistance=0);
assert(~any(info.EscapesPlus));
outwardSign = fcn_CarMesh3D_outwardSides(testMesh, FaceList=[3 4]);
assert(isequal(outwardSign, [1; 1]));

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
outwardSign = fcn_CarMesh3D_outwardSides(fcn_INTERNAL_box(), FigNum=[]);
assert(all(outwardSign == 1));
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
outwardSign = fcn_CarMesh3D_outwardSides(fcn_INTERNAL_box(), FigNum=-1);
assert(all(outwardSign == 1));
assert(isempty(findobj('Number',figNum)));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 20;
testMesh = fcn_INTERNAL_box();

tic;
for ith_test = 1:Niterations
    outwardSign = fcn_CarMesh3D_outwardSides(testMesh, FigNum=[]);
end
slow_method = toc;

tic;
for ith_test = 1:Niterations
    outwardSign = fcn_CarMesh3D_outwardSides(testMesh, FigNum=-1);
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
    %% A face number past the end
    fcn_CarMesh3D_outwardSides(fcn_INTERNAL_box(), FaceList=13);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_box
function testMesh = fcn_INTERNAL_box()
% A closed 1 m box centered at the origin, 12 triangles facing out (faces 3
% and 4 are its top)
[x, y, z] = ndgrid([-0.5 0.5], [-0.5 0.5], [-0.5 0.5]);
testMesh = struct('Vertices', [x(:) y(:) z(:)], ...
    'Faces', [1 3 4; 1 4 2; 5 6 8; 5 8 7; 1 2 6; 1 6 5; 3 7 8; 3 8 4; 1 5 7; 1 7 3; 2 4 8; 2 8 6]);
end % Ends fcn_INTERNAL_box
