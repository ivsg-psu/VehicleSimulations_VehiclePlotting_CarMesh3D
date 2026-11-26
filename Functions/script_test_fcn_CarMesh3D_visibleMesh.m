% script_test_fcn_CarMesh3D_visibleMesh.m
% Tests fcn_CarMesh3D_visibleMesh
% The vehicle as it is shown: the mesh without its hidden faces.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_visibleMesh
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_visibleMesh
%   % * (fill in items here)


%% Set up the workspace
close all

% The labeled sample, with its tail lights hidden in the set 'tail lamps'
% and the front left wheel in the set 'front left wheel'
sampleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
tailFaces = find(sampleMesh.LabelFaceLamp==find(strcmp(sampleMesh.LabelLampNames,'tailBrakeLamp')));
wheelFaces = find(sampleMesh.FaceWheelIndex==1);
hiddenMesh = fcn_CarMesh3D_editLabels(sampleMesh, Edits={struct('FaceIndices',tailFaces,'Hide','tail lamps'), ...
    struct('FaceIndices',wheelFaces,'Hide','front left wheel')}, FigNum=-1);

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

%% DEMO case: The sample, its hidden faces in red
figNum = 10001;
titleString = sprintf('DEMO case: The sample, its hidden faces in red');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[visibleMesh, flagShown] = fcn_CarMesh3D_visibleMesh(hiddenMesh, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(visibleMesh) && islogical(flagShown));

% Check variable sizes
assert(numel(flagShown) == size(hiddenMesh.Faces,1));
assert(size(visibleMesh.Faces,1) == nnz(flagShown));

% Check variable values
assert(~any(flagShown(tailFaces)) && ~any(flagShown(wheelFaces)));
assert(nnz(~flagShown) == numel(tailFaces) + numel(wheelFaces));

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

%% TEST case: Every per-face field is cut to match; only the vertices used are kept
figNum = 20001;
titleString = sprintf('TEST case: Every per-face field is cut to match; only the vertices used are kept');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[visibleMesh, flagShown] = fcn_CarMesh3D_visibleMesh(hiddenMesh);
numShown = nnz(flagShown);
for name = {'LabelFacePart','LabelFaceLamp','FaceWheelIndex','FaceColors','FaceAlpha','LabelFaceHiddenSet'}
    assert(size(visibleMesh.(name{1}),1) == numShown, name{1});
end
assert(isequal(visibleMesh.LabelFacePart, hiddenMesh.LabelFacePart(flagShown)));
assert(all(visibleMesh.LabelFaceHiddenSet == 0));
assert(isequal(unique(visibleMesh.Faces(:))', 1:size(visibleMesh.Vertices,1)));   % (no unused vertices)
% (the shown faces in the same places)
shownCorners = hiddenMesh.Vertices(hiddenMesh.Faces(flagShown,:)', :);
keptCorners = visibleMesh.Vertices(visibleMesh.Faces', :);
assert(max(abs(shownCorners(:) - keptCorners(:))) == 0);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: ShowSets shows a set by name, or every set
figNum = 20002;
titleString = sprintf('TEST case: ShowSets shows a set by name, or every set');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[~, flagShown] = fcn_CarMesh3D_visibleMesh(hiddenMesh, ShowSets={'tail lamps'});
assert(all(flagShown(tailFaces)) && ~any(flagShown(wheelFaces)));
[allMesh, flagShown] = fcn_CarMesh3D_visibleMesh(hiddenMesh, ShowSets=true);
assert(all(flagShown) && isequal(allMesh, hiddenMesh));
% (a mesh with no hidden faces comes back as it is)
assert(isequal(fcn_CarMesh3D_visibleMesh(sampleMesh), sampleMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);
visibleMesh = fcn_CarMesh3D_visibleMesh(hiddenMesh, FigNum=-1);
assert(size(visibleMesh.Faces,1) == size(hiddenMesh.Faces,1) - numel(tailFaces) - numel(wheelFaces));
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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
    fcn_CarMesh3D_visibleMesh(42);

    %% FAIL case: ShowSets of the wrong kind
    fcn_CarMesh3D_visibleMesh(hiddenMesh, ShowSets=3);
end

fprintf(1,'All tests of fcn_CarMesh3D_visibleMesh passed\n');
