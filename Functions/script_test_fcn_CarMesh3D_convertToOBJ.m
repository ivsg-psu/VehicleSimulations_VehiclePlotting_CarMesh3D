% script_test_fcn_CarMesh3D_convertToOBJ.m
% Tests fcn_CarMesh3D_convertToOBJ
% Converts FBX, glTF, GLB, and .blend files to OBJ by running Blender in the background.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_convertToOBJ
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_convertToOBJ
%   % * Renamed from script_CarMesh3D_convertToOBJ: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_convertToOBJ
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

%% DEMO case: Round trip of the sample OBJ through Blender
figNum = 10001;
titleString = sprintf('DEMO case: Round trip of the sample OBJ through Blender');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

if fcn_INTERNAL_blenderAvailable
    sourceFile = fcn_INTERNAL_sampleOBJ;
    originalMesh = fcn_CarMesh3D_importMesh(sourceFile);
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile, Overwrite=true, FigNum=figNum);
    sgtitle(titleString, 'Interpreter','none');

    % Check variable types
    assert(ischar(objFile));

    % Check variable values
    assert(exist(objFile,'file')==2);
    convertedMesh = fcn_CarMesh3D_importMesh(objFile);
    assert(size(convertedMesh.Faces,1)==size(originalMesh.Faces,1));
    % Material names survive the trip
    assert(isempty(setdiff(originalMesh.MaterialNames, convertedMesh.MaterialNames)));
    % Same size and position (axes kept as Z up)
    originalExtents = [min(originalMesh.Vertices,[],1); max(originalMesh.Vertices,[],1)];
    convertedExtents = [min(convertedMesh.Vertices,[],1); max(convertedMesh.Vertices,[],1)];
    assert(max(abs(originalExtents(:) - convertedExtents(:)))<1e-3);

    % Make sure plot opened up
    assert(isequal(get(gcf,'Number'),figNum));
end

%% DEMO case: Your own FBX file, all the way to a finished mesh
% Put a downloaded FBX file in the Data folder, set its name and the
% axes, and change 1==0 to 1==1.
if 1==0
    figNum = 10002; %#ok<UNRCH>
    fbxFile = fullfile('Data','myDownloadedCar.fbx');
    vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fullfile('Data','2013_Toyota_Prius_Four','vehicleParameters_2013_Toyota_Prius_Four.mat'));
    vehicleMesh = fcn_CarMesh3D_importMesh(fbxFile, License='(fill in)', FigNum=figNum);
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+z', ForwardAxis='-y', FigNum=figNum+1);
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=figNum+2);
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=figNum+3);
    vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, TargetFaces=3000, FigNum=figNum+4);
    disp(fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=figNum+5));
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

%% TEST case: An up-to-date converted file is reused, not converted again
figNum = 20001;
titleString = sprintf('TEST case: An up-to-date converted file is reused, not converted again');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

if fcn_INTERNAL_blenderAvailable
    sourceFile = fcn_INTERNAL_sampleOBJ;
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile, Overwrite=true);
    firstInfo = dir(objFile);
    pause(1.1); % File times have about 1 second resolution
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile);
    secondInfo = dir(objFile);
    assert(secondInfo.datenum==firstInfo.datenum); % Not rewritten
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: OutputFile option
figNum = 20002;
titleString = sprintf('TEST case: OutputFile option');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

if fcn_INTERNAL_blenderAvailable
    sourceFile = fcn_INTERNAL_sampleOBJ;
    outputFile = fullfile(tempdir,'CarMesh3D_customName.obj');
    if exist(outputFile,'file')
        delete(outputFile);
    end
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile, OutputFile=outputFile);
    assert(strcmp(objFile, outputFile));
    assert(exist(outputFile,'file')==2);
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: importMesh converts an FBX file automatically
figNum = 20003;
titleString = sprintf('TEST case: importMesh converts an FBX file automatically');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% importMesh accepts .fbx, .glb, .gltf, and .blend. To test that path
% without a downloaded file, put any FBX or GLB file in tempdir with the
% name below; otherwise this test is skipped.
testFile = fullfile(tempdir,'CarMesh3D_test.fbx');
if fcn_INTERNAL_blenderAvailable && exist(testFile,'file')
    vehicleMesh = fcn_CarMesh3D_importMesh(testFile);
    assert(~isempty(vehicleMesh.Faces));
    assert(strcmp(vehicleMesh.Source, testFile));
else
    fprintf(1,'\tSKIPPING: no test file at %s\n', testFile);
end

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

if fcn_INTERNAL_blenderAvailable
    sourceFile = fcn_INTERNAL_sampleOBJ;
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile, FigNum=[]);
    assert(exist(objFile,'file')==2);
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

if fcn_INTERNAL_blenderAvailable
    objFile = fcn_CarMesh3D_convertToOBJ(sourceFile, FigNum=-1);
    assert(exist(objFile,'file')==2);
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% (No speed comparison here: the time is almost all spent in Blender.)

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

%% FAIL case: Unsupported file type
if 1==0
    badFile = fullfile(tempdir,'CarMesh3D_test.txt'); fid = fopen(badFile,'w'); fclose(fid); objFile = fcn_CarMesh3D_convertToOBJ(badFile);
end

%% FAIL case: Blender not at the given path
if 1==0
    objFile = fcn_CarMesh3D_convertToOBJ(fcn_INTERNAL_sampleOBJ, BlenderPath='C:\no\such\blender.exe', Overwrite=true);
end

%% FAIL case: Output file not .obj
if 1==0
    objFile = fcn_CarMesh3D_convertToOBJ(fcn_INTERNAL_sampleOBJ, OutputFile='out.stl');
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
fprintf(fid,'# Written by script_test_fcn_CarMesh3D_importMesh\n');
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

%% fcn_INTERNAL_blenderAvailable
function flagAvailable = fcn_INTERNAL_blenderAvailable
% True if Blender can be found. The tests that need Blender are skipped
% (with a message) when it is not installed.
persistent savedFlag
if isempty(savedFlag)
    objFile = fullfile(tempdir,'CarMesh3D_blenderCheck.obj');
    fid = fopen(objFile,'w');
    fprintf(fid,'%s\n','v 0 0 0','v 1 0 0','v 0 1 0','f 1 2 3');
    fclose(fid);
    try
        fcn_CarMesh3D_convertToOBJ(objFile, Overwrite=true);
        savedFlag = true;
    catch ME
        if contains(ME.message,'Blender was not found')
            fprintf(1,'\tSKIPPING: Blender was not found. Install it from https://www.blender.org to run these tests.\n');
            savedFlag = false;
        else
            rethrow(ME);
        end
    end
end
flagAvailable = savedFlag;
end % Ends fcn_INTERNAL_blenderAvailable

%% fcn_INTERNAL_sampleOBJ
function objFile = fcn_INTERNAL_sampleOBJ
% Writes the clean sample mesh to an OBJ file and returns its name
objFile = fullfile(tempdir,'CarMesh3D_convertSample.obj');
fcn_INTERNAL_writeOBJ(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), objFile);
end % Ends fcn_INTERNAL_sampleOBJ
