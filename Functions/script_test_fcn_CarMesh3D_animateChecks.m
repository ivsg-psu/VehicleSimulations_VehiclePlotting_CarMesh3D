% script_test_fcn_CarMesh3D_animateChecks.m
% Tests fcn_CarMesh3D_animateChecks

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_animateChecks
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_animateChecks
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;
stage3 = load(fullfile(vehicleFiles.Folder, 'cache', 'stage3_checks.mat'), 'cacheOutputs');
testMotion = stage3.cacheOutputs.checkResults.TestMotion;

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

%% DEMO case: The Fit's lights check, from its ID, in its own window (hidden)
fprintf(1,'DEMO case: the Fit''s lights check, from its ID, in its own window (hidden)\n');
animator = fcn_CarMesh3D_animateChecks(vehicleID, 'lights', FlagVisible=false);
assert(isgraphics(animator.Figure));
assert(numel(animator.Axes) == 2 && all(isgraphics(animator.Axes)));
assert(~isempty(animator.Rows) && ~isempty(animator.Steps));
assert(all(startsWith(testMotion.Caption(animator.Rows), 'Lights:')));
assert(animator.Frame() == 1);
animator.Close();
assert(~isvalid(animator.Figure));

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

%% TEST case: Every check, from a mesh and the test motion
fprintf(1,'TEST case: every check, from a mesh and the test motion\n');
checkKeys = {'lights', 'body', 'steering', 'wheels', 'drive'};
for ith_check = 1:numel(checkKeys)
    animator = fcn_CarMesh3D_animateChecks(fitMesh, checkKeys{ith_check}, TestMotion=testMotion, FlagVisible=false);
    assert(~isempty(animator.Rows), 'no rows for %s', checkKeys{ith_check});
    if strcmp(checkKeys{ith_check}, 'drive')
        assert(isempty(animator.Steps));   % (the drive check: the whole animation only)
    else
        assert(~isempty(animator.Steps));
    end
    animator.ShowFrame(numel(animator.Rows));
    assert(animator.Frame() == numel(animator.Rows));
    animator.Close();
end

%% TEST case: A step, the whole animation (OnStep), Play and Stop
fprintf(1,'TEST case: a step, the whole animation (OnStep), Play and Stop\n');
setappdata(0, 'testAnimateSteps', []);
animator = fcn_CarMesh3D_animateChecks(fitMesh, 'body', TestMotion=testMotion, FlagVisible=false, ...
    OnStep=@(stepIndex) setappdata(0, 'testAnimateSteps', [getappdata(0, 'testAnimateSteps') stepIndex]));
animator.ShowStep(2);
assert(animator.Rows(animator.Frame()) == animator.Steps(2).Row);
assert(~animator.IsPlaying());
animator.ShowStep(0);
assert(animator.IsPlaying());
pause(3);
animator.Stop();
assert(~animator.IsPlaying());
stepsSeen = getappdata(0, 'testAnimateSteps');
assert(any(stepsSeen > 0));              % (steps lit up as it played)
assert(stepsSeen(end) == 0);             % (and put back when it stopped)
animator.Play();
assert(animator.IsPlaying());
animator.Stop();
animator.Close();
rmappdata(0, 'testAnimateSteps');

%% TEST case: Inside a parent (no player), and stopped when the parent is cleared
fprintf(1,'TEST case: inside a parent (no player), stopped when the parent is cleared\n');
hostFigure = uifigure('Visible', 'off');
hostPanel = uipanel(hostFigure);
animator = fcn_CarMesh3D_animateChecks(fitMesh, 'steering', TestMotion=testMotion, Parent=hostPanel, ...
    OnHint=@(textIn) assert(ischar(textIn) || isstring(textIn)));
assert(isempty(animator.Figure));
assert(all(isgraphics(animator.Axes)));
animator.ShowStep(0);
assert(animator.IsPlaying());
delete(hostPanel.Children);
assert(~animator.IsPlaying());   % (its timer stopped with its views)
delete(hostFigure);

%% TEST case: The mesh animated is the mesh given (a painted lamp lights)
fprintf(1,'TEST case: the mesh animated is the mesh given (a painted lamp lights)\n');
% (body faces at the rear, painted as tail lights, as the painter would)
centers = (fitMesh.Vertices(fitMesh.Faces(:,1),:) + fitMesh.Vertices(fitMesh.Faces(:,2),:) + fitMesh.Vertices(fitMesh.Faces(:,3),:))/3;
bodyFaces = find(fitMesh.LabelFacePart == find(strcmp(fitMesh.LabelPartNames,'body')));
[~, order] = sort(centers(bodyFaces,1));
rearFaces = bodyFaces(order(1:20));
edit = struct('Name', 'test: painted tail', 'Points', round(centers(rearFaces,:),5), 'PointTolerance', 0.005, 'LightType', 'tailBrakeLamp');
paintedMesh = fcn_CarMesh3D_editLabels(fitMesh, Edits={edit}, FigNum=-1);
before = fcn_CarMesh3D_animateChecks(fitMesh, 'lights', TestMotion=testMotion, FlagVisible=false);
after = fcn_CarMesh3D_animateChecks(paintedMesh, 'lights', TestMotion=testMotion, FlagVisible=false);
countTail = @(handles) sum(arrayfun(@(p) size(p.Faces,1), handles.LabelLampPatches.tailBrakeLamp));
assert(countTail(after.Handles{1}) >= countTail(before.Handles{1}) + 20);
before.Close();
after.Close();

%% Fail conditions
if 1==0
    %% FAIL case: not a check
    fcn_CarMesh3D_animateChecks(vehicleID, 'brakes');

    %% FAIL case: a mesh with no test motion
    fcn_CarMesh3D_animateChecks(fitMesh, 'lights');
end

fprintf(1,'All tests of fcn_CarMesh3D_animateChecks passed\n');
