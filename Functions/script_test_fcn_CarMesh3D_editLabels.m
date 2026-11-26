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
%   % * Test: AlsoParts (LabelFaceAlsoParts), faces in more than one part

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLabels
%   % * Test: lamp covers (LabelFaceCoverLamp) stay valid: a cover given a new
%   %   % label is no longer one; the field is padded, or left missing;
%   %   % lights made also glass over a lamp become its cover

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
    'BothSides',true, 'CurrentPart','light', 'LightType','turnSignalLamp')};
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(editedMesh));
assert(isstruct(appliedEdits));

% Check variable sizes
assert(isequal(size(appliedEdits),[1 1]));
assert(isequal(size(editedMesh.LabelFaceLamp), size(vehicleMesh.LabelFaceLamp)));

% Check variable values
assert(4==numel(appliedEdits.FaceIndices));
assert(0==fcn_INTERNAL_countLightType(editedMesh,'headlamp'));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnSignalLamp'));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'tailBrakeLamp')); % Unchanged

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
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, PartRules={'17in','wheel'; 'color_notint','trim'}, FlagUseMaterialColors=false, FigNum=-1);
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
assert(all(editedMesh.LabelFacePart(rimFaces)==5));
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

%% TEST case: relabeled faces keep this vehicle's colors (Q88 (A), 2026_11_26)
figNum = 20010;
titleString = sprintf('TEST case: relabeled faces keep this vehicle''s colors');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
vehicleMesh = fcn_INTERNAL_labeledSample;
bodyFaces = find(vehicleMesh.LabelFacePart == 1);
vehicleMesh.FaceColors(bodyFaces,:) = repmat([0.05 0.20 0.60], numel(bodyFaces), 1);   % (a blue vehicle)
% Body painted over body: nothing changes (the 2009 Fit turned grey here)
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFaces(1:5),'Part','body')});
assert(isequal(editedMesh.FaceColors, vehicleMesh.FaceColors), 'Painting body over body keeps the colors');
% A trim face made body takes the vehicle's body color, not the default grey
trimFaces = find(vehicleMesh.LabelFacePart == 5);
if ~isempty(trimFaces)
    editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',trimFaces(1),'Part','body')});
    assert(isequal(editedMesh.FaceColors(trimFaces(1),:), [0.05 0.20 0.60]), 'A new body face takes the vehicle''s body color');
end
% A color in the edit still wins
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFaces(1),'Part','body','Color',[1 0 0])});
assert(isequal(editedMesh.FaceColors(bodyFaces(1),:), [1 0 0]));

%% TEST case: BothSides mirrors the region across the centerline
figNum = 20002;
titleString = sprintf('TEST case: BothSides mirrors the region across the centerline');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
oneSide = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'CurrentPart','light','LightType','runningLamp')});
bothSides = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','runningLamp')});
assert(2==fcn_INTERNAL_countLightType(oneSide,'runningLamp'));
assert(4==fcn_INTERNAL_countLightType(bothSides,'runningLamp'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Changing glass to a light makes it opaque, and back again
figNum = 20003;
titleString = sprintf('TEST case: Changing glass to a light makes it opaque, and back again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('CurrentPart','glass','LightType','backupLamp')});
assert(all(editedMesh.FaceAlpha(editedMesh.LabelFacePart==4)==1));
assert(0==sum(editedMesh.LabelFacePart==2));
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('CurrentPart','light','Part','glass')}, GlassAlpha=0.5);
assert(all(editedMesh.FaceAlpha(editedMesh.LabelFacePart==2)==0.5));
assert(all(editedMesh.LabelFaceLamp==0));

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
assert(isequal(editedMesh.LabelFacePart, vehicleMesh.LabelFacePart));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Hide keeps the faces, in a named set; Unhide shows them again; old 'delete' edits hide
figNum = 20005;
titleString = sprintf('TEST case: Hide keeps the faces, in a named set; Unhide shows them again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
tailFaces = find(vehicleMesh.LabelFaceLamp==find(strcmp(vehicleMesh.LabelLampNames,'tailBrakeLamp')));
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','no tail lights', ...
    'FaceIndices',tailFaces,'Hide','tail lamps')});
assert(strcmp(appliedEdits(1).Part,'hide: tail lamps'));
assert(size(editedMesh.Faces,1) == size(vehicleMesh.Faces,1));                  % (nothing deleted)
assert(isequal(editedMesh.LabelFacePart, vehicleMesh.LabelFacePart));            % (labels kept)
assert(isequal(editedMesh.LabelHiddenSetNames, {'tail lamps'}));
assert(all(editedMesh.LabelFaceHiddenSet(tailFaces)==1) && nnz(editedMesh.LabelFaceHiddenSet)==numel(tailFaces));
% (a second set, then the first shown again)
wheelFaces = find(editedMesh.FaceWheelIndex==1);
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',wheelFaces,'Hide','front left wheel'), ...
    struct('FaceIndices',tailFaces,'Unhide',true)});
assert(isequal(editedMesh.LabelHiddenSetNames, {'tail lamps';'front left wheel'}));
assert(all(editedMesh.LabelFaceHiddenSet(tailFaces)==0) && all(editedMesh.LabelFaceHiddenSet(wheelFaces)==2));
% (an older edits file's 'delete' hides, in the set 'hidden')
[oldMesh, oldEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',tailFaces,'Part','delete')});
assert(strcmp(oldEdits(1).Part,'hide: hidden') && size(oldMesh.Faces,1)==size(vehicleMesh.Faces,1));
assert(isequal(oldMesh.LabelHiddenSetNames, {'hidden'}) && all(oldMesh.LabelFaceHiddenSet(tailFaces)==1));
assert(all(oldMesh.LabelFacePart(tailFaces)==vehicleMesh.LabelFacePart(tailFaces)));

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
assert(all(editedMesh.LabelFacePart(pickedFaces)==5));
changed = find(editedMesh.LabelFacePart ~= vehicleMesh.LabelFacePart);
assert(all(ismember(changed, pickedFaces)));
% (a point too far from every face picks nothing)
lastwarn('');
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','too far', ...
    'Points',[100 100 100], 'Part','trim')});
assert(isequal(editedMesh.LabelFacePart, vehicleMesh.LabelFacePart));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: AlsoLightTypes gives light faces more functions
vehicleMesh = fcn_INTERNAL_labeledSample;
tailIndex = find(strcmp(vehicleMesh.LabelLampNames,'tailBrakeLamp'));
turnIndex = find(strcmp(vehicleMesh.LabelLampNames,'turnSignalLamp'));
tailFaces = find(vehicleMesh.LabelFaceLamp==tailIndex);
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','rear turn', ...
    'FaceIndices',tailFaces, 'AlsoLightTypes',{{'turnSignalLamp'}})}, FigNum=-1);
assert(isequal(size(editedMesh.LabelFaceAlsoLamps), [size(editedMesh.Faces,1) numel(editedMesh.LabelLampNames)]));
assert(all(editedMesh.LabelFaceAlsoLamps(tailFaces, tailIndex)) && all(editedMesh.LabelFaceAlsoLamps(tailFaces, turnIndex)));
assert(all(editedMesh.LabelFaceLamp(tailFaces)==tailIndex), 'The primary type is kept');
assert(strcmp(appliedEdits(1).LightType, '+turnSignalLamp'));
% (relabeling the faces replaces their functions)
editedMesh = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',tailFaces(1), 'LightType','backupLamp')}, FigNum=-1);
assert(~editedMesh.LabelFaceAlsoLamps(tailFaces(1), turnIndex) && editedMesh.LabelFaceAlsoLamps(tailFaces(1), editedMesh.LabelFaceLamp(tailFaces(1))));
% (faces that were not lights become lights of the first type)
bodyFace = find(vehicleMesh.LabelFacePart==find(strcmp(vehicleMesh.LabelPartNames,'body')), 1);
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoLightTypes',{{'runningLamp','turnSignalLamp'}})}, FigNum=-1);
assert(editedMesh.LabelFaceLamp(bodyFace)==find(strcmp(editedMesh.LabelLampNames,'runningLamp')));
assert(editedMesh.LabelFaceAlsoLamps(bodyFace, turnIndex));

%% TEST case: AlsoParts: faces that belong to more than one part
vehicleMesh = fcn_INTERNAL_labeledSample;
lightIndex = find(strcmp(vehicleMesh.LabelPartNames,'light'));
glassIndex = find(strcmp(vehicleMesh.LabelPartNames,'glass'));
headFaces = find(vehicleMesh.LabelFaceLamp==find(strcmp(vehicleMesh.LabelLampNames,'headlamp')));
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('Name','clear covers', ...
    'FaceIndices',headFaces, 'AlsoParts',{{'glass'}})}, FigNum=-1);
assert(isequal(size(editedMesh.LabelFaceAlsoParts,1), size(editedMesh.Faces,1)));
assert(size(editedMesh.LabelFaceAlsoParts,2) >= numel(editedMesh.LabelPartNames));
assert(all(editedMesh.LabelFaceAlsoParts(headFaces, glassIndex)));
assert(all(editedMesh.LabelFacePart(headFaces)==lightIndex), 'Light always wins: the faces stay lights');
assert(nnz(editedMesh.LabelFaceAlsoParts) == numel(headFaces));
assert(strcmp(appliedEdits(1).Part, '+glass'));
% (a face's own part is not marked again)
glassFaces = find(vehicleMesh.LabelFacePart==glassIndex);
editedMesh2 = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',glassFaces(1), 'AlsoParts',{{'glass','trim'}})}, FigNum=-1);
assert(~editedMesh2.LabelFaceAlsoParts(glassFaces(1), glassIndex) && editedMesh2.LabelFaceAlsoParts(glassFaces(1), strcmp(editedMesh2.LabelPartNames,'trim')));
% (a new label clears the faces' other parts)
editedMesh2 = fcn_CarMesh3D_editLabels(editedMesh, Edits={struct('FaceIndices',headFaces(1), 'Part','trim')}, FigNum=-1);
assert(~any(editedMesh2.LabelFaceAlsoParts(headFaces(1),:)));
assert(all(editedMesh2.LabelFaceAlsoParts(headFaces(2:end), glassIndex)));
% (with a label in the same edit: the label first, then the other parts)
bodyFace = find(vehicleMesh.LabelFacePart==find(strcmp(vehicleMesh.LabelPartNames,'body')), 1);
[editedMesh2, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'LightType','tailBrakeLamp', 'AlsoParts',{{'glass'}})}, FigNum=-1);
assert(editedMesh2.LabelFacePart(bodyFace)==lightIndex && editedMesh2.LabelFaceAlsoParts(bodyFace, glassIndex));
assert(strcmp(appliedEdits(1).Part, 'light+glass'));
% (an interior part is added to LabelPartNames, and LabelFaceAlsoParts widened)
editedMesh2 = fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoParts',{{'interior'}})}, FigNum=-1);
interiorIndex = find(strcmp(editedMesh2.LabelPartNames,'interior'));
assert(~isempty(interiorIndex) && size(editedMesh2.LabelFaceAlsoParts,2)==numel(editedMesh2.LabelPartNames) && editedMesh2.LabelFaceAlsoParts(bodyFace, interiorIndex));
% ('light' as an other part is refused: light always wins)
try
    fcn_CarMesh3D_editLabels(vehicleMesh, Edits={struct('FaceIndices',bodyFace, 'AlsoParts',{{'light'}})});
    error('should have failed');
catch ME
    assert(contains(ME.message, 'light always wins'), ME.message);
end

%% TEST case: High beams on a mesh made before the 'highBeamLamp' type
figNum = 20009;
titleString = sprintf('TEST case: High beams on a mesh made before the highbeam type');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

oldMesh = fcn_INTERNAL_labeledSample;
oldMesh.LabelLampNames = {'headlamp';'turnSignalLamp';'runningLamp';'tailBrakeLamp';'backupLamp'};   % (as made before 2026_11_23)
oldMesh.LabelFaceLamp(oldMesh.LabelFaceLamp==6) = 1;
oldMesh.LabelFaceAlsoLamps = false(size(oldMesh.Faces,1), 5);
headFaces = find(oldMesh.LabelFaceLamp==1);
editedMesh = fcn_CarMesh3D_editLabels(oldMesh, Edits={struct('FaceIndices',headFaces(1),'LightType','highBeamLamp')});
assert(isequal(editedMesh.LabelLampNames(1:5), oldMesh.LabelLampNames) && strcmp(editedMesh.LabelLampNames{6}, 'highBeamLamp'));
assert(editedMesh.LabelFaceLamp(headFaces(1))==6 && all(editedMesh.LabelFaceLamp(headFaces(2:end))==1));
assert(size(editedMesh.LabelFaceAlsoLamps,2)==numel(editedMesh.LabelLampNames) && editedMesh.LabelFaceAlsoLamps(headFaces(1),6));   % (one column per type: older meshes get every type of fcn_CarMesh3D_lampTypes added, task 8)

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Lamp covers (LabelFaceCoverLamp) stay valid when labels are edited
figNum = 20010;
titleString = sprintf('TEST case: Lamp covers (LabelFaceCoverLamp) stay valid when labels are edited');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (a small mesh with a headlight cover and a left and a right turn
% signal cover, found by fcn_CarMesh3D_findLampCovers)
[coverMesh, faceInfo] = fcn_INTERNAL_coverMesh;
coveredMesh = fcn_CarMesh3D_findLampCovers(coverMesh, FigNum=-1);
Nfaces = size(coveredMesh.Faces,1);
headType = find(strcmp(coveredMesh.LabelLampNames,'headlamp'));
turnType = find(strcmp(coveredMesh.LabelLampNames,'turnSignalLamp'));
glassIndex = find(strcmp(coveredMesh.LabelPartNames,'glass'));
turnCovers = [faceInfo.leftTurnCover; faceInfo.rightTurnCover];
assert(all(coveredMesh.LabelFaceCoverLamp(faceInfo.headCover)==headType) && all(coveredMesh.LabelFaceCoverLamp(turnCovers)==turnType));
% (a cover painted as something else, or as a lamp, is no longer a cover;
% the other covers stay)
editedMesh = fcn_CarMesh3D_editLabels(coveredMesh, Edits={struct('FaceIndices',faceInfo.headCover,'Part','trim')}, FigNum=-1);
assert(all(editedMesh.LabelFaceCoverLamp(faceInfo.headCover)==0) && all(editedMesh.LabelFaceCoverLamp(turnCovers)==turnType));
editedMesh = fcn_CarMesh3D_editLabels(coveredMesh, Edits={struct('FaceIndices',faceInfo.leftTurnCover,'LightType','tailBrakeLamp')}, FigNum=-1);
assert(all(editedMesh.LabelFaceCoverLamp(faceInfo.leftTurnCover)==0) && all(editedMesh.LabelFaceCoverLamp(faceInfo.rightTurnCover)==turnType));
% (painted as plain glass: tinted glass, not a cover...)
glassMesh = fcn_CarMesh3D_editLabels(coveredMesh, Edits={struct('FaceIndices',faceInfo.headCover,'Part','glass')}, FigNum=-1);
assert(all(glassMesh.LabelFaceCoverLamp(faceInfo.headCover)==0) && all(glassMesh.LabelFacePart(faceInfo.headCover)==glassIndex));
assert(all(abs(glassMesh.FaceAlpha(faceInfo.headCover) - 0.35) < 1e-12));
% (...and painted as a headlight that is also glass, it lies over the
% headlight, so it is the headlight's clear cover again)
againMesh = fcn_CarMesh3D_editLabels(glassMesh, Edits={struct('FaceIndices',faceInfo.headCover, ...
    'LightType','headlamp','AlsoParts',{{'glass'}})}, FigNum=-1);
assert(all(againMesh.LabelFaceCoverLamp(faceInfo.headCover)==headType) && all(againMesh.LabelFacePart(faceInfo.headCover)==glassIndex));
assert(all(abs(againMesh.FaceAlpha(faceInfo.headCover) - 0.15) < 1e-12) && all(againMesh.LabelFaceLamp(faceInfo.headCover)==0));
% (a LabelFaceCoverLamp that is short, as after faces were added, is padded
% with zeros: one row per face)
shortMesh = coveredMesh;
shortMesh.LabelFaceCoverLamp = shortMesh.LabelFaceCoverLamp(1:end-2);
editedMesh = fcn_CarMesh3D_editLabels(shortMesh, Edits={struct('FaceIndices',faceInfo.body,'Part','trim')}, FigNum=-1);
assert(isequal(size(editedMesh.LabelFaceCoverLamp),[Nfaces 1]) && all(editedMesh.LabelFaceCoverLamp(end-1:end)==0));
assert(isequal(editedMesh.LabelFaceCoverLamp(1:end-2), shortMesh.LabelFaceCoverLamp));
% (a mesh made before LabelFaceCoverLamp is left without it, so
% fcn_CarMesh3D_plotVehicle still finds its covers when it is drawn)
editedMesh = fcn_CarMesh3D_editLabels(coverMesh, Edits={struct('FaceIndices',faceInfo.body,'Part','trim')}, FigNum=-1);
assert(~isfield(editedMesh,'LabelFaceCoverLamp'));
% (a mesh made before the 'highBeamLamp' type: the covers' light types stay)
oldTypesMesh = coveredMesh;
oldTypesMesh.LabelLampNames = oldTypesMesh.LabelLampNames(1:5);
editedMesh = fcn_CarMesh3D_editLabels(oldTypesMesh, Edits={struct('FaceIndices',faceInfo.headLamp,'LightType','highBeamLamp')}, FigNum=-1);
assert(strcmp(editedMesh.LabelLampNames{6},'highBeamLamp') && isequal(editedMesh.LabelFaceCoverLamp, coveredMesh.LabelFaceCoverLamp));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Interactive editor, driven from code
figNum = 20007;
titleString = sprintf('TEST case: Interactive editor, driven from code');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
tailFaces = find(vehicleMesh.LabelFaceLamp==find(strcmp(vehicleMesh.LabelLampNames,'tailBrakeLamp')));
editorTimer = timer('StartDelay',2,'TimerFcn',@(~,~) fcn_INTERNAL_driveEditor(tailFaces,'light: backupLamp'));
start(editorTimer);
[editedMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, FlagInteractive=true);
delete(editorTimer);
assert(1==length(appliedEdits));
assert(strcmp(appliedEdits(1).LightType,'backupLamp'));
assert(isequal(sort(appliedEdits(1).FaceIndices(:)), sort(tailFaces(:))));
assert(4==fcn_INTERNAL_countLightType(editedMesh,'backupLamp'));
assert(0==fcn_INTERNAL_countLightType(editedMesh,'tailBrakeLamp'));
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
edits = {struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','turnSignalLamp')};
editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=[]);
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnSignalLamp'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

editedMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);
assert(4==fcn_INTERNAL_countLightType(editedMesh,'turnSignalLamp'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

vehicleMesh = fcn_INTERNAL_labeledSample;
edits = {struct('Region',[2.2 2.6 0.3 0.9 0.3 0.8],'BothSides',true,'CurrentPart','light','LightType','turnSignalLamp')};

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
close(373737);   % (leave no figures behind)

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

%% fcn_INTERNAL_coverMesh
function [testMesh, faceInfo] = fcn_INTERNAL_coverMesh
% A small labeled mesh, in meters (X forward, Y left, Z up), made of
% flat squares facing forward (+X), two triangles each (the same mesh as
% in script_test_fcn_CarMesh3D_findLampCovers):
%   a headlight at x = 1.00, and plain glass 2 cm in front of it
%   a glass "window" at x = 0.00, 1 m behind the lamps
%   a left and a right turn signal at x = 1.00, each with a cover 2 cm in
%   front of it marked the old way: a light that is also glass
%   a body panel below the lamps
labelPartNames = {'body';'glass';'wheel';'light';'trim'};
labelLampNames = {'headlamp';'turnSignalLamp';'runningLamp';'tailBrakeLamp';'backupLamp';'highBeamLamp'};
squares = { ...   % x, [ymin ymax], [zmin zmax], part, light type, also glass, name
    1.00, [ 0.40  0.60], [0.50 0.70], 4, 1, false, 'headLamp';
    1.02, [ 0.38  0.62], [0.48 0.72], 2, 0, false, 'headCover';
    0.00, [-0.50  0.50], [0.90 1.20], 2, 0, false, 'window';
    1.00, [ 0.65  0.75], [0.50 0.60], 4, 2, false, 'leftTurnLamp';
    1.02, [ 0.64  0.76], [0.49 0.61], 4, 2, true,  'leftTurnCover';
    1.00, [-0.75 -0.65], [0.50 0.60], 4, 2, false, 'rightTurnLamp';
    1.02, [-0.76 -0.64], [0.49 0.61], 4, 2, true,  'rightTurnCover';
    1.00, [-0.80  0.80], [0.20 0.45], 1, 0, false, 'body'};
vertices = zeros(0,3);
faces = zeros(0,3);
facePart = zeros(0,1);
labelFaceLamp = zeros(0,1);
faceAlsoGlass = false(0,1);
faceInfo = struct;
for ith_square = 1:size(squares,1)
    [x, yRange, zRange] = squares{ith_square,1:3};
    % (corners in the order that makes the right-hand-rule normal +X)
    corners = [x yRange(1) zRange(1); x yRange(2) zRange(1); x yRange(2) zRange(2); x yRange(1) zRange(2)];
    base = size(vertices,1);
    vertices = [vertices; corners]; %#ok<AGROW>
    faces = [faces; base + [1 2 3; 1 3 4]]; %#ok<AGROW>
    facePart = [facePart; squares{ith_square,4}*[1;1]]; %#ok<AGROW>
    labelFaceLamp = [labelFaceLamp; squares{ith_square,5}*[1;1]]; %#ok<AGROW>
    faceAlsoGlass = [faceAlsoGlass; squares{ith_square,6}&[true;true]]; %#ok<AGROW>
    faceInfo.(squares{ith_square,7}) = size(faces,1) + [-1; 0];
end
Nfaces = size(faces,1);
partColors = [0.60 0.60 0.65; 0.15 0.20 0.25; 0.10 0.10 0.10; 0.95 0.90 0.80; 0.20 0.20 0.20];
faceAlpha = ones(Nfaces,1);
faceAlpha(facePart==2) = 0.35;
labelFaceAlsoParts = false(Nfaces, numel(labelPartNames));
labelFaceAlsoParts(faceAlsoGlass, 2) = true;
testMesh = struct('Name','lamp cover test mesh', 'Units','m', 'Frame','ISO8855', ...
    'Vertices',vertices, 'Faces',faces, 'LabelPartNames',{labelPartNames}, 'LabelFacePart',facePart, ...
    'LabelLampNames',{labelLampNames}, 'LabelFaceLamp',labelFaceLamp, 'FaceWheelIndex',zeros(Nfaces,1), ...
    'FaceColors',partColors(facePart,:), 'FaceAlpha',faceAlpha, 'LabelFaceAlsoParts',labelFaceAlsoParts);
end % Ends fcn_INTERNAL_coverMesh

%% fcn_INTERNAL_countLightType
function count = fcn_INTERNAL_countLightType(vehicleMesh, typeName)
count = sum(vehicleMesh.LabelFaceLamp==find(strcmp(vehicleMesh.LabelLampNames,typeName)));
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
    'BothSides',true, 'Material','color_notint|glass_ex', 'LightType','headlamp');
edits{end+1} = struct('Name','front turn signals', 'Region',[3.30 3.50 0.65 0.80 0.25 0.47], ...
    'BothSides',true, 'Material','color_notint', 'LightType','turnSignalLamp');
edits{end+1} = struct('Name','tail lights (upper part)', 'Region',[-0.80 -0.45 0.55 0.80 0.95 1.12], ...
    'BothSides',true, 'Material','color_notint', 'LightType','tailBrakeLamp');
edits{end+1} = struct('Name','rear turn signals (middle)', 'Region',[-0.80 -0.45 0.55 0.80 0.82 0.95], ...
    'BothSides',true, 'Material','color_notint', 'LightType','turnSignalLamp');
edits{end+1} = struct('Name','backup lights (lower part)', 'Region',[-0.80 -0.45 0.55 0.80 0.65 0.82], ...
    'BothSides',true, 'Material','color_notint', 'LightType','backupLamp');
end % Ends fcn_INTERNAL_priusLightEdits
