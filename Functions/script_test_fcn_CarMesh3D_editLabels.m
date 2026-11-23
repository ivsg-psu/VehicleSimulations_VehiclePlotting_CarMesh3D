% script_test_fcn_CarMesh3D_editLabels.m
% Tests fcn_CarMesh3D_editLabels
% Corrects part and light labels, by script or by clicking.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLabels
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLabels
%   % * Renamed from script_CarMesh3D_editLabels: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLabels
%   % * Test: AlsoParts (FaceAlsoParts), faces in more than one part

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLabels
%   % * (fill in items here)


%% Set up the workspace
close all

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

%% DEMO case: Scripted edit - make the sample headlights into turn signals
figNum = 10001;
titleString = sprintf('DEMO case: Scripted edit - make the sample headlights into turn signals');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_labeledSample;
% Front of the car, both sides, only faces that are now lights
edits = {struct('Name','front turn signals', 'Region',[2.2 2.6 0.3 0.9 0.3 0.8], ...
    'BothSides',true, 'CurrentPart','light', 'LightType','turnsignal')};
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(editedMesh));
assert(isstruct(appliedEdits));

% Check variable sizes
assert(isequal(size(appliedEdits),[1 1]));
assert(isequal(size(editedMesh.FaceLightType), size(vehicleMesh.FaceLightType)));

% Check variable values
assert(4==numel(appliedEdits.FaceIndices));
assert(0==fcn_INTERNAL_countLightType(editedMesh,'headlight'));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnsignal'));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'tail')); % Unchanged

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Fix the downloaded Prius lights by region (needs the model and Blender)
figNum = 10002;
titleString = sprintf('DEMO case: Fix the downloaded Prius lights by region');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
functionsFolder = fileparts(which('fcn_CarMesh3D_editLabels'));
rootFolder = fileparts(functionsFolder);
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
modelFile = fullfile(priusFiles.ModelFolder,'source','2010 Toyota Prius.glb');
specFile = priusFiles.ParametersFile;
try
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(specFile, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_importMesh(modelFile, FigNum=-1);
    flagModelReady = true;
catch ME
    fprintf(1,'\tSKIPPING: %s\n', ME.message);
    flagModelReady = false;
end
if flagModelReady
    figure(figNum); clf;
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+z', ForwardAxis='+x', FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules={'17in','wheel'; 'color_notint','trim'}, UseMaterialColors=false, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, WidthReference='mirrors', FigNum=-1);
    edits = fcn_INTERNAL_priusLightEdits;
    [vehicleMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=figNum);
    sgtitle(titleString, 'Interpreter','none');
    for ith_edit = 1:length(appliedEdits)
        fprintf(1,'\t%-26s %3d faces\n', appliedEdits(ith_edit).Name, numel(appliedEdits(ith_edit).FaceIndices));
        assert(~isempty(appliedEdits(ith_edit).FaceIndices));
    end
    % Make sure plot opened up
    assert(isequal(get(gcf,'Number'),figNum));
end

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Pick by material, group, current part, and face list
figNum = 20001;
titleString = sprintf('TEST case: Pick by material, group, current part, and face list');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
% Material: all Rim faces become trim
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Material','^Rim$','Part','trim')});
rimFaces = vehicleMesh.FaceMaterialIndex==find(strcmp(vehicleMesh.MaterialNames,'Rim'));
assert(all(editedMesh.FacePartIndex(rimFaces)==5));
assert(all(editedMesh.FaceWheelIndex(rimFaces)==0));
% Group: one wheel's group only
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Group','Wheel_FL','Part','body')});
assert(0==sum(editedMesh.FaceWheelIndex==1));
assert(128==sum(editedMesh.FaceWheelIndex==2));
% Face list, with a color
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',[1 2 3],'Part','trim','Color',[1 0 0])});
assert(all(all(editedMesh.FaceColors(1:3,:)==[1 0 0])));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: BothSides mirrors the region across the centerline
figNum = 20002;
titleString = sprintf('TEST case: BothSides mirrors the region across the centerline');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
oneSide = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'CurrentPart','light','LightType','running')});
bothSides = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','running')});
assert(2==fcn_INTERNAL_countLightType(oneSide,'running'));
assert(4==fcn_INTERNAL_countLightType(bothSides,'running'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Changing glass to a light makes it opaque, and back again
figNum = 20003;
titleString = sprintf('TEST case: Changing glass to a light makes it opaque, and back again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('CurrentPart','glass','LightType','backup')});
assert(all(editedMesh.FaceAlpha(editedMesh.FacePartIndex==4)==1));
assert(0==sum(editedMesh.FacePartIndex==2));
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('CurrentPart','light','Part','glass')}, GlassAlpha=0.5);
assert(all(editedMesh.FaceAlpha(editedMesh.FacePartIndex==2)==0.5));
assert(all(editedMesh.FaceLightType==0));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: An edit that picks nothing gives a warning
figNum = 20004;
titleString = sprintf('TEST case: An edit that picks nothing gives a warning');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
lastwarn('');
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','nothing here','Region',[50 60 50 60 50 60],'Part','trim')});
[warningMessage,~] = lastwarn;
assert(contains(warningMessage,'did not pick any faces'));
assert(isequal(editedMesh.FacePartIndex, vehicleMesh.FacePartIndex));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Hide keeps the faces, in a named set; Unhide shows them again; old 'delete' edits hide
figNum = 20005;
titleString = sprintf('TEST case: Hide keeps the faces, in a named set; Unhide shows them again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
tailFaces = find(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,'tail')));
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','no tail lights', ...
    'FaceIndices',tailFaces,'Hide','tail lamps')});
assert(strcmp(appliedEdits(1).Part,'hide: tail lamps'));
assert(size(editedMesh.Faces,1) == size(vehicleMesh.Faces,1));                  % (nothing deleted)
assert(isequal(editedMesh.FacePartIndex, vehicleMesh.FacePartIndex));            % (labels kept)
assert(isequal(editedMesh.HiddenSetNames, {'tail lamps'}));
assert(all(editedMesh.FaceHiddenSet(tailFaces)==1) && nnz(editedMesh.FaceHiddenSet)==numel(tailFaces));
% (a second set, then the first shown again)
wheelFaces = find(editedMesh.FaceWheelIndex==1);
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',wheelFaces,'Hide','front left wheel'), ...
    struct('FaceIndices',tailFaces,'Unhide',true)});
assert(isequal(editedMesh.HiddenSetNames, {'tail lamps';'front left wheel'}));
assert(all(editedMesh.FaceHiddenSet(tailFaces)==0) && all(editedMesh.FaceHiddenSet(wheelFaces)==2));
% (an older edits file's 'delete' hides, in the set 'hidden')
[oldMesh, oldEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',tailFaces,'Part','delete')});
assert(strcmp(oldEdits(1).Part,'hide: hidden') && size(oldMesh.Faces,1)==size(vehicleMesh.Faces,1));
assert(isequal(oldMesh.HiddenSetNames, {'hidden'}) && all(oldMesh.FaceHiddenSet(tailFaces)==1));
assert(all(oldMesh.FacePartIndex(tailFaces)==vehicleMesh.FacePartIndex(tailFaces)));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Points picks faces by their centers
figNum = 20006;
titleString = sprintf('TEST case: Points picks faces by their centers');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
centers = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
pickedFaces = [1; 5; 9];
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','by points', ...
    'Points',centers(pickedFaces,:) + 0.001, 'Part','trim')});
assert(all(editedMesh.FacePartIndex(pickedFaces)==5));
changed = find(editedMesh.FacePartIndex ~= vehicleMesh.FacePartIndex);
assert(all(ismember(changed, pickedFaces)));
% (a point too far from every face picks nothing)
lastwarn('');
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','too far', ...
    'Points',[100 100 100], 'Part','trim')});
assert(isequal(editedMesh.FacePartIndex, vehicleMesh.FacePartIndex));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: AlsoLightTypes gives light faces more functions
vehicleMesh = fcn_INTERNAL_labeledSample;
tailIndex = find(strcmp(vehicleMesh.LightTypeNames,'tail'));
turnIndex = find(strcmp(vehicleMesh.LightTypeNames,'turnsignal'));
tailFaces = find(vehicleMesh.FaceLightType==tailIndex);
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','rear turn', ...
    'FaceIndices',tailFaces, 'AlsoLightTypes',{{'turnsignal'}})}, FigNum=-1);
assert(isequal(size(editedMesh.FaceLightFunctions), [size(editedMesh.Faces,1) numel(editedMesh.LightTypeNames)]));
assert(all(editedMesh.FaceLightFunctions(tailFaces, tailIndex)) && all(editedMesh.FaceLightFunctions(tailFaces, turnIndex)));
assert(all(editedMesh.FaceLightType(tailFaces)==tailIndex), 'The primary type is kept');
assert(strcmp(appliedEdits(1).LightType, '+turnsignal'));
% (relabeling the faces replaces their functions)
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',tailFaces(1), 'LightType','backup')}, FigNum=-1);
assert(~editedMesh.FaceLightFunctions(tailFaces(1), turnIndex) && editedMesh.FaceLightFunctions(tailFaces(1), editedMesh.FaceLightType(tailFaces(1))));
% (faces that were not lights become lights of the first type)
bodyFace = find(vehicleMesh.FacePartIndex==find(strcmp(vehicleMesh.PartNames,'body')), 1);
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoLightTypes',{{'running','turnsignal'}})}, FigNum=-1);
assert(editedMesh.FaceLightType(bodyFace)==find(strcmp(editedMesh.LightTypeNames,'running')));
assert(editedMesh.FaceLightFunctions(bodyFace, turnIndex));

%% TEST case: AlsoParts: faces that belong to more than one part
vehicleMesh = fcn_INTERNAL_labeledSample;
lightIndex = find(strcmp(vehicleMesh.PartNames,'light'));
glassIndex = find(strcmp(vehicleMesh.PartNames,'glass'));
headFaces = find(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,'headlight')));
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','clear covers', ...
    'FaceIndices',headFaces, 'AlsoParts',{{'glass'}})}, FigNum=-1);
assert(isequal(size(editedMesh.FaceAlsoParts,1), size(editedMesh.Faces,1)));
assert(size(editedMesh.FaceAlsoParts,2) >= numel(editedMesh.PartNames));
assert(all(editedMesh.FaceAlsoParts(headFaces, glassIndex)));
assert(all(editedMesh.FacePartIndex(headFaces)==lightIndex), 'Light always wins: the faces stay lights');
assert(nnz(editedMesh.FaceAlsoParts) == numel(headFaces));
assert(strcmp(appliedEdits(1).Part, '+glass'));
% (a face's own part is not marked again)
glassFaces = find(vehicleMesh.FacePartIndex==glassIndex);
editedMesh2 = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',glassFaces(1), 'AlsoParts',{{'glass','trim'}})}, FigNum=-1);
assert(~editedMesh2.FaceAlsoParts(glassFaces(1), glassIndex) && editedMesh2.FaceAlsoParts(glassFaces(1), strcmp(editedMesh2.PartNames,'trim')));
% (a new label clears the faces' other parts)
editedMesh2 = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',headFaces(1), 'Part','trim')}, FigNum=-1);
assert(~any(editedMesh2.FaceAlsoParts(headFaces(1),:)));
assert(all(editedMesh2.FaceAlsoParts(headFaces(2:end), glassIndex)));
% (with a label in the same edit: the label first, then the other parts)
bodyFace = find(vehicleMesh.FacePartIndex==find(strcmp(vehicleMesh.PartNames,'body')), 1);
[editedMesh2, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'LightType','tail', 'AlsoParts',{{'glass'}})}, FigNum=-1);
assert(editedMesh2.FacePartIndex(bodyFace)==lightIndex && editedMesh2.FaceAlsoParts(bodyFace, glassIndex));
assert(strcmp(appliedEdits(1).Part, 'light+glass'));
% (an interior part is added to PartNames, and FaceAlsoParts widened)
editedMesh2 = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoParts',{{'interior'}})}, FigNum=-1);
interiorIndex = find(strcmp(editedMesh2.PartNames,'interior'));
assert(~isempty(interiorIndex) && size(editedMesh2.FaceAlsoParts,2)==numel(editedMesh2.PartNames) && editedMesh2.FaceAlsoParts(bodyFace, interiorIndex));
% ('light' as an other part is refused: light always wins)
try
    fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoParts',{{'light'}})});
    error('should have failed');
catch ME
    assert(contains(ME.message, 'light always wins'), ME.message);
end

%% TEST case: High beams on a mesh made before the 'highbeam' type
figNum = 20009;
titleString = sprintf('TEST case: High beams on a mesh made before the highbeam type');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

oldMesh = fcn_INTERNAL_labeledSample;
oldMesh.LightTypeNames = {'headlight';'turnsignal';'running';'tail';'backup'};   % (as made before 2026_11_23)
oldMesh.FaceLightType(oldMesh.FaceLightType==6) = 1;
oldMesh.FaceLightFunctions = false(size(oldMesh.Faces,1), 5);
headFaces = find(oldMesh.FaceLightType==1);
editedMesh = fcn_CarMesh3D_editLabels(oldMesh, Edits={struct('FaceIndices',headFaces(1),'LightType','highbeam')});
assert(isequal(editedMesh.LightTypeNames(1:5), oldMesh.LightTypeNames) && strcmp(editedMesh.LightTypeNames{6}, 'highbeam'));
assert(editedMesh.FaceLightType(headFaces(1))==6 && all(editedMesh.FaceLightType(headFaces(2:end))==1));
assert(size(editedMesh.FaceLightFunctions,2)==6 && editedMesh.FaceLightFunctions(headFaces(1),6));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Interactive editor, driven from code
figNum = 20007;
titleString = sprintf('TEST case: Interactive editor, driven from code');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
tailFaces = find(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,'tail')));
editorTimer = timer('StartDelay',2,'TimerFcn',@(~,~) fcn_INTERNAL_driveEditor(tailFaces,'light: backup'));
start(editorTimer);
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Interactive=true);
delete(editorTimer);
assert(1==length(appliedEdits));
assert(strcmp(appliedEdits(1).LightType,'backup'));
assert(isequal(sort(appliedEdits(1).FaceIndices(:)), sort(tailFaces(:))));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'backup'));
assert(0==fcn_INTERNAL_countLightType(editedMesh,'tail'));
% The editor window is closed
assert(isempty(findobj(groot,'Type','figure','Name','CarMesh3D label editor')));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
edits = {struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','turnsignal')};
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=[]);
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnsignal'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnsignal'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
edits = {struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','turnsignal')};

Niterations = 100;

% Normal mode
tic;
for ith_test = 1:Niterations
    editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);
end
fast_method = toc;

% Input checks turned off by environment variable. The code reads these
% variables only when both are set. Save the user's settings and restore
% them afterward, even if a call errors.
old_check_inputs = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
old_do_debug     = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS","0");
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG","0");
try
    tic;
    for ith_test = 1:Niterations
        editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=[]);
    end
    env_method = toc;
catch ME
    setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
    setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);
    rethrow(ME);
end
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

barLabels = {'Normal mode','Checks off (environment variable)','Fast mode (FigNum=-1)'};
X = categorical(barLabels);
X = reordercats(X,barLabels); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method env_method fast_method]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')
title('fcn_CarMesh3D_editLabels: time per call','Interpreter','none');
fprintf(1,'Average time per call (ms): normal %.3f, checks off by environment variable %.3f, fast mode %.3f\n',Y(1),Y(2),Y(3));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: Unknown part name
if 1==0
    editedMesh = fcn_CarMesh3D_editLabels(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh), Edits={struct('Region',[0 1 0 1 0 1],'Part','roof')});
end

%% FAIL case: Unknown field (misspelled)
if 1==0
    editedMesh = fcn_CarMesh3D_editLabels(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh), Edits={struct('Regoin',[0 1 0 1 0 1],'Part','trim')});
end

%% FAIL case: Edit that does not say what to label
if 1==0
    editedMesh = fcn_CarMesh3D_editLabels(fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh), Edits={struct('Region',[0 1 0 1 0 1])});
end

%% FAIL case: Mesh not labeled
if 1==0
    editedMesh = fcn_CarMesh3D_editLabels(fcn_CarMesh3D_fillSampleMesh, Edits={struct('Part','trim')});
end

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

%% fcn_INTERNAL_labeledSample
function vehicleMesh = fcn_INTERNAL_labeledSample
% A clean, labeled sample mesh (4 headlight faces and 4 tail light faces)
vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
end % Ends fcn_INTERNAL_labeledSample

%% fcn_INTERNAL_countLightType
function count = fcn_INTERNAL_countLightType(vehicleMesh, typeName)
count = sum(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,typeName)));
end % Ends fcn_INTERNAL_countLightType

%% fcn_INTERNAL_driveEditor
function fcn_INTERNAL_driveEditor(faceIndices, targetName)
% Acts like a user in the interactive editor: select, label, finish
editorFigure = findobj(groot,'Type','figure','Name','CarMesh3D label editor');
editor = editorFigure(1).UserData;
editor.select(faceIndices);
editor.setTarget(targetName);
editor.apply();
editor.done();
end % Ends fcn_INTERNAL_driveEditor

%% fcn_INTERNAL_priusLightEdits
function edits = fcn_INTERNAL_priusLightEdits
% Light edits for the downloaded 2010 Prius model, after fitting to the
% 2013 Prius spec (meters, origin on the ground below the rear axle)
edits = {};
edits{end+1} = struct('Name','headlight housings and lenses', 'Region',[2.90 3.45 0.45 0.82 0.55 0.82], ...
    'BothSides',true, 'Material','color_notint|glass_ex', 'LightType','headlight');
edits{end+1} = struct('Name','front turn signals', 'Region',[3.30 3.50 0.65 0.80 0.25 0.47], ...
    'BothSides',true, 'Material','color_notint', 'LightType','turnsignal');
edits{end+1} = struct('Name','tail lights (upper part)', 'Region',[-0.80 -0.45 0.55 0.80 0.95 1.12], ...
    'BothSides',true, 'Material','color_notint', 'LightType','tail');
edits{end+1} = struct('Name','rear turn signals (middle)', 'Region',[-0.80 -0.45 0.55 0.80 0.82 0.95], ...
    'BothSides',true, 'Material','color_notint', 'LightType','turnsignal');
edits{end+1} = struct('Name','backup lights (lower part)', 'Region',[-0.80 -0.45 0.55 0.80 0.65 0.82], ...
    'BothSides',true, 'Material','color_notint', 'LightType','backup');
end % Ends fcn_INTERNAL_priusLightEdits
