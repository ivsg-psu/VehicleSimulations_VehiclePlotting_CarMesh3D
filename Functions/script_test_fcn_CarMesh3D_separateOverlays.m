% script_test_fcn_CarMesh3D_separateOverlays.m
% Tests fcn_CarMesh3D_separateOverlays

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_separateOverlays
%   % * First write

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

%% DEMO case: a trim square lying on a body square is lifted
figNum = 10001;
titleString = sprintf('DEMO case: a trim square lying on a body square is lifted');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

testMesh = fcn_INTERNAL_twoSquares('trim', 0);
[liftedMesh, numLifted] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isstruct(liftedMesh));
assert(isequal(size(liftedMesh.Vertices), size(testMesh.Vertices)));
assert(isnumeric(numLifted) && isscalar(numLifted));

% Check variable values: the trim square's two faces moved 2 mm up (+z,
% its normal); the body square did not move
assert(numLifted == 2);
assert(max(abs(liftedMesh.Vertices(5:8,3) - 0.002)) < 1e-12);
assert(isequal(liftedMesh.Vertices(1:4,:), testMesh.Vertices(1:4,:)));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: the higher-ranked part is lifted, whichever comes first
figNum = 20001;
titleString = sprintf('TEST case: the higher-ranked part is lifted, whichever comes first');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (the body square second in the list: still the trim is lifted)
testMesh = fcn_INTERNAL_twoSquares('trim', 0);
testMesh.FacePartIndex = testMesh.FacePartIndex([3 4 1 2]);
testMesh.Faces = testMesh.Faces([3 4 1 2],:);
[liftedMesh, numLifted] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=[]);
assert(numLifted == 2);
assert(max(abs(liftedMesh.Vertices(5:8,3) - 0.002)) < 1e-12);
assert(isequal(liftedMesh.Vertices(1:4,:), testMesh.Vertices(1:4,:)));

% Make sure no plot was made
assert(isempty(findobj('Number',figNum)));

%% TEST case: wheels, same parts, and faces apart are left alone
figNum = 20002;
titleString = sprintf('TEST case: wheels, same parts, and faces apart are left alone');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[~, numLifted] = fcn_CarMesh3D_separateOverlays(fcn_INTERNAL_twoSquares('wheel', 0), FigNum=[]);
assert(numLifted == 0);
[~, numLifted] = fcn_CarMesh3D_separateOverlays(fcn_INTERNAL_twoSquares('body', 0), FigNum=[]);
assert(numLifted == 0);
[~, numLifted] = fcn_CarMesh3D_separateOverlays(fcn_INTERNAL_twoSquares('trim', 0.01), FigNum=[]);   % (1 cm apart)
assert(numLifted == 0);

% Make sure no plot was made
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
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic fast mode - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
[~, numLifted] = fcn_CarMesh3D_separateOverlays(fcn_INTERNAL_twoSquares('trim', 0), FigNum=[]);
assert(numLifted == 2);
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
[~, numLifted] = fcn_CarMesh3D_separateOverlays(fcn_INTERNAL_twoSquares('trim', 0), FigNum=-1);
assert(numLifted == 2);
assert(isempty(findobj('Number',figNum)));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 20;
testMesh = fcn_INTERNAL_twoSquares('trim', 0);

tic;
for ith_test = 1:Niterations
    [~, numLifted] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=[]);
end
slow_method = toc;

tic;
for ith_test = 1:Niterations
    [~, numLifted] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=-1);
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
    fcn_CarMesh3D_separateOverlays(struct('Vertices',zeros(3), 'Faces',[1 2 3]));
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

%% fcn_INTERNAL_twoSquares
function testMesh = fcn_INTERNAL_twoSquares(topPart, gap)
% A 1 m body square at z = 0 and a 0.4 m square of topPart above its
% middle at z = gap, both facing +z, as two triangles each
partNames = {'body';'glass';'wheel';'light';'trim'};
big = [0 0 0; 1 0 0; 1 1 0; 0 1 0];
small = [0.3 0.3 gap; 0.7 0.3 gap; 0.7 0.7 gap; 0.3 0.7 gap];
testMesh = struct();
testMesh.Vertices = [big; small];
testMesh.Faces = [1 2 3; 1 3 4; 5 6 7; 5 7 8];
testMesh.PartNames = partNames;
testMesh.FacePartIndex = [1; 1; find(strcmp(partNames, topPart)); find(strcmp(partNames, topPart))];
end % Ends fcn_INTERNAL_twoSquares
