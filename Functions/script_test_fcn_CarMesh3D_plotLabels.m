% script_test_fcn_CarMesh3D_plotLabels.m
% Tests fcn_CarMesh3D_plotLabels

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotLabels
%   % * First write
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In script_test_fcn_CarMesh3D_plotLabels
%   % * The legend output (Sean, T62)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotLabels
%   % * (none yet)

%% Set up the workspace
close all;

% A small labeled test mesh: a body box, a glass panel, and a headlight
% and a tail lamp (two faces each)
testMesh = struct();
testMesh.Name = 'test box';
testMesh.Vertices = [0 -1 0; 4 -1 0; 4 1 0; 0 1 0; 0 -1 1; 4 -1 1; 4 1 1; 0 1 1];
testMesh.Faces = [1 2 3; 1 3 4; 5 7 6; 5 8 7; 1 6 2; 1 5 6; 2 7 3; 2 6 7; 3 8 4; 3 7 8; 4 5 1; 4 8 5];
testMesh.PartNames = {'body','glass','wheel','light','trim'};
testMesh.FacePartIndex = [1 1 2 2 1 1 4 4 1 1 4 4]';
testMesh.FaceWheelIndex = zeros(12,1);
testMesh.LightTypeNames = {'headlamp','turnSignalLamp','runningLamp','tailBrakeLamp','backupLamp'};
testMesh.FaceLightType = [0 0 0 0 0 0 1 1 0 0 4 4]';
testMesh.FaceColors = repmat([0.5 0.5 0.5],12,1);
testMesh.FaceAlpha = ones(12,1);

%% Fast mode (FigNum=-1): the label colors only
labelMesh = fcn_CarMesh3D_plotLabels(testMesh, FigNum=-1);
assert(isequal(size(labelMesh.FaceColors),[12 3]));
assert(isequal(labelMesh.FaceColors(1,:),[0.97 0.97 0.97]));   % body (near-white)
assert(isequal(labelMesh.FaceColors(3,:),[0.55 0.80 1.00]));   % glass
assert(isequal(labelMesh.FaceColors(7,:),[1.00 0.90 0.10]));   % headlight
assert(isequal(labelMesh.FaceColors(11,:),[0.90 0.00 0.00]));  % tail
assert(labelMesh.FaceAlpha(3)==0.6 && labelMesh.FaceAlpha(1)==1);

%% The legend: the label colors this mesh uses, parts then lamp types
[~, legendEntries] = fcn_CarMesh3D_plotLabels(testMesh, FigNum=-1);
assert(isequal({legendEntries.Name}, {'body', 'glass', 'headlamp', 'tail/brake lamp'}), ...
    'Only what the mesh shows: the light part''s faces all show a lamp type');
assert(isequal([legendEntries.Faces], [6 2 2 2]));
assert(isequal(legendEntries(3).Color, [1.00 0.90 0.10]));
untypedMesh = testMesh;
untypedMesh.FaceLightType(7:8) = 0;   % (a lamp with no type)
[~, legendEntries] = fcn_CarMesh3D_plotLabels(untypedMesh, FigNum=-1);
assert(any(strcmp({legendEntries.Name}, 'lamp, no type')));

%% A plot, left open
figNum = 10001;
labelMesh = fcn_CarMesh3D_plotLabels(testMesh, Title='Test box', FigNum=figNum);
assert(ishandle(figNum));
assert(strcmp(get(figure(figNum),'Visible'),'on'));
assert(strcmp(get(figure(figNum),'Name'),'Test box: labels'));
assert(isequal(labelMesh.FaceColors(7,:),[1.00 0.90 0.10]));

%% FAIL: not a labeled mesh
if 1==0
    fcn_CarMesh3D_plotLabels(struct('Vertices',[],'Faces',[]), FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_plotLabels passed\n');
