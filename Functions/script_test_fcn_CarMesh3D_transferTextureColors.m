% script_test_fcn_CarMesh3D_transferTextureColors.m
% Tests fcn_CarMesh3D_transferTextureColors

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_transferTextureColors
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

%% DEMO case: a coarse square takes the colors of a fine, two-colored one
figNum = 10001;
titleString = sprintf('DEMO case: a coarse square takes the colors of a fine, two-colored one');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

textureMesh = fcn_INTERNAL_fineSquare();
coarseMesh = struct('Vertices',[0 0 0; 1 0 0; 1 1 0; 0 1 0], 'Faces',[1 2 4; 2 3 4]);
coloredMesh = fcn_CarMesh3D_transferTextureColors(coarseMesh, textureMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isstruct(coloredMesh));
assert(isequal(size(coloredMesh.FaceTextureColors),[2 3]));
assert(isequal(size(coloredMesh.FaceTextureAlpha),[2 1]));
assert(islogical(coloredMesh.SeeThroughReliable));

% Check variable values: the lower-left triangle's center (x < 0.5) lies
% on the red half, the upper-right one's (x > 0.5) on the blue half
assert(isequal(coloredMesh.FaceTextureColors(1,:), [1 0 0]));
assert(isequal(coloredMesh.FaceTextureColors(2,:), [0 0 1]));
assert(all(coloredMesh.FaceTextureAlpha == 1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: a face takes the color of a face facing the same way
figNum = 20001;
titleString = sprintf('TEST case: a face takes the color of a face facing the same way');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (a two-sided panel: green facing up, yellow facing down, 1 mm apart; a
% face facing down takes yellow, though green is as near)
textureMesh = struct('Vertices',[0 0 0; 1 0 0; 0 1 0; 0 0 -0.001; 0 1 -0.001; 1 0 -0.001], ...
    'Faces',[1 2 3; 4 5 6], 'FaceTextureColors',[0 1 0; 1 1 0], 'FaceTextureAlpha',[1; 1], 'SeeThroughReliable',true);
downMesh = struct('Vertices',[0 0 -0.0005; 0 1 -0.0005; 1 0 -0.0005], 'Faces',[1 2 3]);
coloredMesh = fcn_CarMesh3D_transferTextureColors(downMesh, textureMesh, FigNum=[]);
assert(isequal(coloredMesh.FaceTextureColors, [1 1 0]));

% Make sure no plot was made
assert(isempty(findobj('Number',figNum)));

%% TEST case: faces far from the download are gray
figNum = 20002;
titleString = sprintf('TEST case: faces far from the download are gray');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

farMesh = struct('Vertices',[5 5 0; 6 5 0; 5 6 0], 'Faces',[1 2 3]);
coloredMesh = fcn_CarMesh3D_transferTextureColors(farMesh, fcn_INTERNAL_fineSquare(), MaxDistance=0.5, FigNum=[]);
assert(isequal(coloredMesh.FaceTextureColors, [0.5 0.5 0.5]));
assert(coloredMesh.FaceTextureAlpha == 1);

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
coloredMesh = fcn_CarMesh3D_transferTextureColors(coarseMesh, fcn_INTERNAL_fineSquare(), FigNum=[]);
assert(isequal(size(coloredMesh.FaceTextureColors),[2 3]));
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
coloredMesh = fcn_CarMesh3D_transferTextureColors(coarseMesh, fcn_INTERNAL_fineSquare(), FigNum=-1);
assert(isequal(size(coloredMesh.FaceTextureColors),[2 3]));
assert(isempty(findobj('Number',figNum)));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 20;
textureMesh = fcn_INTERNAL_fineSquare();

tic;
for ith_test = 1:Niterations
    coloredMesh = fcn_CarMesh3D_transferTextureColors(coarseMesh, textureMesh, FigNum=[]);
end
slow_method = toc;

tic;
for ith_test = 1:Niterations
    coloredMesh = fcn_CarMesh3D_transferTextureColors(coarseMesh, textureMesh, FigNum=-1);
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
    %% A texture mesh not read by fcn_CarMesh3D_readGLB
    fcn_CarMesh3D_transferTextureColors(coarseMesh, coarseMesh);
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

%% fcn_INTERNAL_fineSquare
function textureMesh = fcn_INTERNAL_fineSquare()
% A unit square at z = 0 facing +z, in a 10 x 10 grid of squares (two
% triangles each), red where x < 0.5 and blue elsewhere, as
% fcn_CarMesh3D_readGLB would give it
[gridX, gridY] = meshgrid(0:0.1:1);
vertices = [gridX(:) gridY(:) zeros(numel(gridX),1)];
faces = zeros(0,3);
for ith_row = 1:10
    for ith_col = 1:10
        corner = (ith_col-1)*11 + ith_row;   % (meshgrid's column-major order: x changes by column)
        faces = [faces; corner, corner+11, corner+1; corner+11, corner+12, corner+1]; %#ok<AGROW>
    end
end
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
colors = repmat([0 0 1], size(faces,1), 1);
colors(centers(:,1) < 0.5,:) = repmat([1 0 0], sum(centers(:,1) < 0.5), 1);
% (each face facing +z)
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
faces(normals(:,3) < 0,:) = faces(normals(:,3) < 0,[1 3 2]);
textureMesh = struct('Vertices',vertices, 'Faces',faces, 'FaceTextureColors',colors, ...
    'FaceTextureAlpha',ones(size(faces,1),1), 'SeeThroughReliable',true);
end % Ends fcn_INTERNAL_fineSquare
