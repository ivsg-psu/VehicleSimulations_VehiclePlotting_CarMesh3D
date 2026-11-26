% script_test_fcn_CarMesh3D_compareToOriginal.m
% Tests fcn_CarMesh3D_compareToOriginal

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_compareToOriginal
%   % * First write
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_compareToOriginal
%   % * Tests the parts table and flips seen in the download too

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_compareToOriginal
%   % * (none yet)

%% Set up the workspace
close all;

% A labeled box "vehicle" (body sides, glass top), 4 m long
boxMesh = struct();
boxMesh.Vertices = [0 -1 0.2; 4 -1 0.2; 4 1 0.2; 0 1 0.2; 0 -1 1.4; 4 -1 1.4; 4 1 1.4; 0 1 1.4];
boxMesh.Faces = [1 3 2; 1 4 3; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];
boxMesh.LabelPartNames = {'body','glass','wheel','light','trim'};
boxMesh.LabelFacePart = [1 1 2 2 1 1 1 1 1 1 1 1]';
boxMesh.FaceWheelIndex = zeros(12,1);
boxMesh.FaceColors = repmat([0.5 0.5 0.5],12,1);
boxMesh.FaceAlpha = ones(12,1);

%% The same mesh: nothing flagged
report = fcn_CarMesh3D_compareToOriginal(boxMesh, boxMesh, FigNum=-1);
assert(height(report.Views)==14);   % (10 views, and the sides, front, and rear from below)
assert(report.Totals.HolePercent==0 && report.Totals.LabelChangePercent==0 && report.Totals.FlippedPercent==0);
assert(report.Totals.SeeThroughPercent==0);   % (a closed box: no gaps)

%% Missing ends, a relabeled top, a flipped side
changedMesh = boxMesh;
changedMesh.LabelFacePart(3:4) = 5;                        % (top: glass to trim)
changedMesh.Faces(9:10,:) = changedMesh.Faces(9:10,[1 3 2]);   % (left side inside out)
keep = true(12,1); keep([7:8 11:12]) = false;             % (front and rear sides missing: see-through)
for fieldName = {'Faces','LabelFacePart','FaceWheelIndex','FaceColors','FaceAlpha'}
    changedMesh.(fieldName{1}) = changedMesh.(fieldName{1})(keep,:);
end
figNum = 10001;
report = fcn_CarMesh3D_compareToOriginal(changedMesh, boxMesh, Title='Test box', FigNum=figNum);
frontRow = strcmp(report.Views.View,'front');
topRow = strcmp(report.Views.View,'top');
leftRow = strcmp(report.Views.View,'left side');
assert(report.Views.HolePercent(frontRow) > 50);
assert(report.Views.LabelChangePercent(topRow) > 50);
assert(report.Views.FlippedPercent(leftRow) > 50);
assert(~isempty(report.Spots));
assert(ishandle(figNum));

% (the parts table: the top's glass is gone, as trim; the body lost the
% front and rear sides, a third of its area)
glassRow = strcmp(report.Parts.Label, 'glass');
assert(report.Parts.OriginalFaces(glassRow)==2 && report.Parts.ReducedFaces(glassRow)==0);
assert(report.Parts.Missing(glassRow) && any(strcmp(report.MissingLabels, 'glass')));
bodyRow = strcmp(report.Parts.Label, 'body');
assert(~report.Parts.Missing(bodyRow) && report.Parts.AreaChangePercent(bodyRow) < -20);

%% A one-sided surface seen from behind in both: not a flip
% (both meshes have their left side inside out, as a download's spokes
% are seen from their back: only flips the reduction made are counted)
insideOut = boxMesh;
insideOut.Faces(9:10,:) = insideOut.Faces(9:10,[1 3 2]);
report = fcn_CarMesh3D_compareToOriginal(insideOut, insideOut, FigNum=-1);
assert(report.Totals.FlippedPercent==0, 'The download faces away there too: not counted');
assert(isempty(report.MissingLabels));

%% FAIL: not labeled meshes
if 1==0
    fcn_CarMesh3D_compareToOriginal(struct('Vertices',[],'Faces',[]), boxMesh, FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_compareToOriginal passed\n');
