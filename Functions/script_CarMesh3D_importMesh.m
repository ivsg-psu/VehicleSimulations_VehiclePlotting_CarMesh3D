% script_CarMesh3D_importMesh.m
% Tests fcn_CarMesh3D_importMesh
% Reads OBJ and STL files, using files written by this script.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_importMesh
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_importMesh
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

%% DEMO case: Import an OBJ file with materials and groups
figNum = 10001;
titleString = sprintf('DEMO case: Import an OBJ file with materials and groups');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% Write the messy sample mesh to an OBJ file, as if it were downloaded
objFile = fullfile(tempdir,'CarMesh3D_testSample.obj');
originalMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
fcn_INTERNAL_writeOBJ(originalMesh, objFile);

vehicleMesh = fcn_CarMesh3D_importMesh(objFile, License='Generated test file', FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleMesh));
assert(iscell(vehicleMesh.MaterialNames));

% Check variable sizes
assert(isequal(size(vehicleMesh.Vertices), size(originalMesh.Vertices)));
assert(isequal(size(vehicleMesh.Faces), size(originalMesh.Faces)));

% Check variable values: same geometry, and every face keeps its material
% and group NAME (the index order may differ from the original)
assert(max(abs(vehicleMesh.Vertices(:) - originalMesh.Vertices(:)))<1e-6);
assert(isequal(vehicleMesh.Faces, originalMesh.Faces));
importedMaterialNames = vehicleMesh.MaterialNames(vehicleMesh.FaceMaterialIndex);
originalMaterialNames = originalMesh.MaterialNames(originalMesh.FaceMaterialIndex);
assert(isequal(importedMaterialNames(:), originalMaterialNames(:)));
importedGroupNames = vehicleMesh.GroupNames(vehicleMesh.FaceGroupIndex);
originalGroupNames = originalMesh.GroupNames(originalMesh.FaceGroupIndex);
assert(isequal(importedGroupNames(:), originalGroupNames(:)));
% Glass color and alpha came from the .mtl file
glassIndex = find(strcmp(vehicleMesh.MaterialNames,'Glass'));
assert(abs(vehicleMesh.MaterialAlpha(glassIndex) - 0.35)<1e-6);
assert(isequal(vehicleMesh.Units,'unknown'));
assert(isequal(vehicleMesh.Frame,'source'));
assert(isequal(vehicleMesh.License,'Generated test file'));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

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

%% TEST case: OBJ polygons, slash indices, and negative indices
figNum = 20001;
titleString = sprintf('TEST case: OBJ polygons, slash indices, and negative indices');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

objFile = fullfile(tempdir,'CarMesh3D_testPolygons.obj');
objLines = {...
    '# Two squares and one more, written in different OBJ styles';
    'v 0 0 0'; 'v 1 0 0'; 'v 1 1 0'; 'v 0 1 0';
    'v 0 0 1'; 'v 1 0 1'; 'v 1 1 1'; 'v 0 1 1';
    'vt 0 0';
    'vn 0 0 1';
    'usemtl Red';
    'f 1/1/1 2/1/1 3/1/1 4/1/1';
    'f -4//1 -3//1 -2//1 -1//1';
    'g Second';
    'f 1 2 6 5'};
fid = fopen(objFile,'w');
fprintf(fid,'%s\n',objLines{:});
fclose(fid);

vehicleMesh = fcn_CarMesh3D_importMesh(objFile);

% Each 4-sided polygon becomes 2 triangles
assert(isequal(size(vehicleMesh.Faces),[6 3]));
assert(isequal(vehicleMesh.Faces(1,:),[1 2 3]));
assert(isequal(vehicleMesh.Faces(3,:),[5 6 7])); % Negative indices counted back
% No mtllib, so colors are unknown (NaN)
assert(all(isnan(vehicleMesh.MaterialColors(:))));
% The last face is in group 'Second'
assert(strcmp(vehicleMesh.GroupNames{vehicleMesh.FaceGroupIndex(end)},'Second'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: STL file import
figNum = 20002;
titleString = sprintf('TEST case: STL file import');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

stlFile = fullfile(tempdir,'CarMesh3D_testSample.stl');
originalMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
stlwrite(triangulation(originalMesh.Faces, originalMesh.Vertices), stlFile);

vehicleMesh = fcn_CarMesh3D_importMesh(stlFile, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

assert(isequal(size(vehicleMesh.Faces,1), size(originalMesh.Faces,1)));
assert(isequal(vehicleMesh.MaterialNames,{'default'}));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Missing material library gives a warning, not an error
figNum = 20003;
titleString = sprintf('TEST case: Missing material library gives a warning, not an error');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

objFile = fullfile(tempdir,'CarMesh3D_testMissingMtl.obj');
fid = fopen(objFile,'w');
fprintf(fid,'%s\n','mtllib this_file_does_not_exist.mtl','v 0 0 0','v 1 0 0','v 0 1 0','usemtl Paint','f 1 2 3');
fclose(fid);

lastwarn('');
vehicleMesh = fcn_CarMesh3D_importMesh(objFile);
[warningMessage,~] = lastwarn;
assert(contains(warningMessage,'Material library not found'));
assert(all(isnan(vehicleMesh.MaterialColors(:))));

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

objFile = fullfile(tempdir,'CarMesh3D_testSample.obj');
fcn_INTERNAL_writeOBJ(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), objFile);
vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=[]);
assert(isstruct(vehicleMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=-1);
assert(isstruct(vehicleMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

objFile = fullfile(tempdir,'CarMesh3D_testSample.obj');
fcn_INTERNAL_writeOBJ(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), objFile);

Niterations = 10;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=-1);
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
        vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=[]);
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
title('fcn_CarMesh3D_importMesh: time per call','Interpreter','none');
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

%% FAIL case: File does not exist
if 1==0
    vehicleMesh = fcn_CarMesh3D_importMesh('no_such_file.obj');
end

%% FAIL case: Unsupported file type
if 1==0
    badFile = fullfile(tempdir,'CarMesh3D_test.txt'); fid = fopen(badFile,'w'); fclose(fid); vehicleMesh = fcn_CarMesh3D_importMesh(badFile);
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

%% fcn_INTERNAL_writeOBJ
function fcn_INTERNAL_writeOBJ(vehicleMesh, objFile)
% Writes a CarMesh3D mesh to an OBJ file with a matching .mtl file, so the
% importer can be tested on a file with known contents
[filePath, fileBaseName] = fileparts(objFile);
mtlName = [fileBaseName '.mtl'];

% Material library
fid = fopen(fullfile(filePath, mtlName),'w');
for ith_material = 1:length(vehicleMesh.MaterialNames)
    fprintf(fid,'newmtl %s\n', vehicleMesh.MaterialNames{ith_material});
    fprintf(fid,'Kd %.6f %.6f %.6f\n', vehicleMesh.MaterialColors(ith_material,:));
    fprintf(fid,'d %.6f\n\n', vehicleMesh.MaterialAlpha(ith_material));
end
fclose(fid);

% Geometry
fid = fopen(objFile,'w');
fprintf(fid,'# Written by script_CarMesh3D_importMesh\n');
fprintf(fid,'mtllib %s\n', mtlName);
fprintf(fid,'v %.15g %.15g %.15g\n', vehicleMesh.Vertices');
currentGroup = 0;
currentMaterial = 0;
for ith_face = 1:size(vehicleMesh.Faces,1)
    if vehicleMesh.FaceGroupIndex(ith_face)~=currentGroup
        currentGroup = vehicleMesh.FaceGroupIndex(ith_face);
        fprintf(fid,'g %s\n', vehicleMesh.GroupNames{currentGroup});
    end
    if vehicleMesh.FaceMaterialIndex(ith_face)~=currentMaterial
        currentMaterial = vehicleMesh.FaceMaterialIndex(ith_face);
        fprintf(fid,'usemtl %s\n', vehicleMesh.MaterialNames{currentMaterial});
    end
    fprintf(fid,'f %d %d %d\n', vehicleMesh.Faces(ith_face,:));
end
fclose(fid);
end % Ends fcn_INTERNAL_writeOBJ
