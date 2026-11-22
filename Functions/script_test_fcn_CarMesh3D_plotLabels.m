% script_test_fcn_CarMesh3D_plotLabels.m
% Tests fcn_CarMesh3D_plotLabels

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_plotLabels
%   % * First write

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
testMesh.LightTypeNames = {'headlight','turnsignal','running','tail','backup'};
testMesh.FaceLightType = [0 0 0 0 0 0 1 1 0 0 4 4]';
testMesh.FaceColors = repmat([0.5 0.5 0.5],12,1);
testMesh.FaceAlpha = ones(12,1);

%% Fast mode (FigNum=-1): the label colors only
labelMesh = fcn_CarMesh3D_plotLabels(testMesh, FigNum=-1);
assert(isequal(size(labelMesh.FaceColors),[12 3]));
assert(isequal(labelMesh.FaceColors(1,:),[0.80 0.80 0.80]));   % body
assert(isequal(labelMesh.FaceColors(3,:),[0.55 0.80 1.00]));   % glass
assert(isequal(labelMesh.FaceColors(7,:),[1.00 0.90 0.10]));   % headlight
assert(isequal(labelMesh.FaceColors(11,:),[0.90 0.00 0.00]));  % tail
assert(labelMesh.FaceAlpha(3)==0.6 && labelMesh.FaceAlpha(1)==1);

%% A plot, left open
figNum = 10001;
labelMesh = fcn_CarMesh3D_plotLabels(testMesh, Title='Test box', FigNum=figNum);
assert(ishandle(figNum));
assert(strcmp(get(figure(figNum),'Visible'),'on'));
assert(strcmp(get(figure(figNum),'Name'),'Test box: labels'));
assert(isequal(labelMesh.FaceColors(7,:),[1.00 0.90 0.10]));

%% By material: one color per material, with a legend
testMesh.MaterialNames = {'paint','window','lamps'};
testMesh.FaceMaterialIndex = [1 1 2 2 1 1 3 3 1 1 3 3]';
materialMesh = fcn_CarMesh3D_plotLabels(testMesh, ColorBy='material', FigNum=-1);
assert(isequal(materialMesh.FaceColors(1,:), materialMesh.FaceColors(5,:)));        % (same material, same color)
assert(~isequal(materialMesh.FaceColors(1,:), materialMesh.FaceColors(3,:)) && ~isequal(materialMesh.FaceColors(3,:), materialMesh.FaceColors(7,:)));
assert(materialMesh.FaceAlpha(3)==0.6);                                             % (glass still see-through)
figNum = 10002;
fcn_CarMesh3D_plotLabels(testMesh, ColorBy='material', FigNum=figNum);
legendHandle = findobj(figure(figNum), 'Type','legend');
assert(numel(legendHandle)==1 && numel(legendHandle.String)==3 && startsWith(legendHandle.String{1}, 'paint'));

%% FAIL: not a labeled mesh
if 1==0
    fcn_CarMesh3D_plotLabels(struct('Vertices',[],'Faces',[]), FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_plotLabels passed\n');
