% script_test_fcn_CarMesh3D_readGLB.m
% Tests fcn_CarMesh3D_readGLB
%
% The tests write small .glb files with known contents (a textured
% square, a node transform, glass) and check what is read back, then
% read a real download (the 2013 Prius, if present) and check it against
% its Blender conversion.

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_readGLB
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

%% DEMO case: a textured square, plotted in its texture colors
figNum = 10001;
titleString = sprintf('DEMO case: a textured square, plotted in its texture colors');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_square.glb'), 'plain');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isstruct(vehicleMesh));
assert(isequal(size(vehicleMesh.Faces),[2 3]));
assert(isequal(size(vehicleMesh.Vertices),[6 3]));
assert(isequal(size(vehicleMesh.FaceTextureColors),[2 3]));
assert(isequal(size(vehicleMesh.FaceTextureAlpha),[2 1]));
assert(islogical(vehicleMesh.SeeThroughReliable));

% Check variable values: the square's left triangle samples the red
% half of the texture, the right one the blue half
assert(max(abs(vehicleMesh.FaceTextureColors(1,:) - [1 0 0])) < 1e-9);
assert(max(abs(vehicleMesh.FaceTextureColors(2,:) - [0 0 1])) < 1e-9);
assert(all(vehicleMesh.FaceTextureAlpha == 1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: glTF's Y-up axes become Blender's Z-up axes
figNum = 20001;
titleString = sprintf('TEST case: glTF''s Y-up axes become Blender''s Z-up axes');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_square.glb'), 'plain');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);

% The square was written at glTF y = 0 to 1 (up), z = 0: in Blender's
% axes that is z = 0 to 1 (up), y = 0
assert(max(abs(vehicleMesh.Vertices(:,2))) < 1e-12);
assert(abs(min(vehicleMesh.Vertices(:,3))) < 1e-12);
assert(abs(max(vehicleMesh.Vertices(:,3)) - 1) < 1e-12);

% Its normals faced glTF +z (toward the viewer), which is Blender -y
normals = cross(vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) - vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:), ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:) - vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:), 2);
assert(all(normals(:,2) < 0));

% Make sure no plot was made
assert(isempty(findobj('Number',figNum)));

%% TEST case: a node's translation, rotation, and mirroring are applied
figNum = 20002;
titleString = sprintf('TEST case: a node''s translation, rotation, and mirroring are applied');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_moved.glb'), 'moved');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);

% Mirrored in glTF x (scale -1), rotated 90 degrees about glTF y, then
% translated by glTF [5 0 0]
rotation = [0 0 1; 0 1 0; -1 0 0];   % 90 degrees about y
corners = [0 0 0; 1 0 0; 1 1 0; 0 1 0];
expected = (rotation*diag([-1 1 1])*corners')' + [5 0 0];
expected = [expected(:,1), -expected(:,3), expected(:,2)];
assert(isequal(unique(round(vehicleMesh.Vertices,6)+0,'rows'), unique(round(expected,6)+0,'rows')));

% Mirroring keeps the faces facing the same way as the turned normal
% (the winding is reversed to make up for the mirror)
normals = cross(vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) - vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:), ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:) - vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:), 2);
% (a normal turns by the inverse transpose of the node's matrix, which
% for a rotation times a mirror is the same rotation times the mirror)
expectedNormal = (rotation*diag([-1 1 1])*[0;0;1])';
expectedNormal = [expectedNormal(1), -expectedNormal(3), expectedNormal(2)];
assert(all(normals*expectedNormal' > 0));

% Make sure no plot was made
assert(isempty(findobj('Number',figNum)));

%% TEST case: glass (transmission) is see-through; all-glass files are not trusted
figNum = 20003;
titleString = sprintf('TEST case: glass (transmission) is see-through; all-glass files are not trusted');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_glass.glb'), 'halfGlass');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);
assert(vehicleMesh.SeeThroughReliable);
assert(sum(vehicleMesh.FaceTextureAlpha < 0.95) == 1);
assert(abs(min(vehicleMesh.FaceTextureAlpha) - 0.3) < 1e-9);   % (1 - transmission 0.7)

glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_allglass.glb'), 'allGlass');
warning('off','CarMesh3D:unreliableSeeThrough');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);
warning('on','CarMesh3D:unreliableSeeThrough');
assert(~vehicleMesh.SeeThroughReliable);
assert(all(vehicleMesh.FaceTextureAlpha == 1));

% Make sure no plot was made
assert(isempty(findobj('Number',figNum)));

%% TEST case: a real download (the 2013 Prius) matches its Blender conversion
figNum = 20004;
titleString = sprintf('TEST case: a real download (the 2013 Prius) matches its Blender conversion');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

repoFolder = fileparts(fileparts(which('fcn_CarMesh3D_readGLB')));   % (the folder above Functions)
priusFolder = fullfile(repoFolder,'Data','BodyStyles','Liftback','2013_Toyota_Prius_Four','model','source');
priusFile = fullfile(priusFolder,'2010 Toyota Prius.glb');
objFile = fullfile(priusFolder,'2010 Toyota Prius_converted.obj');
if isfile(priusFile) && isfile(objFile)
    vehicleMesh = fcn_CarMesh3D_readGLB(priusFile, FigNum=[]);
    objMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=-1);
    assert(size(vehicleMesh.Faces,1) == size(objMesh.Faces,1));
    assert(max(abs([min(vehicleMesh.Vertices) - min(objMesh.Vertices), max(vehicleMesh.Vertices) - max(objMesh.Vertices)])) < 1e-5);
    % (the glass material is see-through, and the paint has texture detail)
    assert(any(vehicleMesh.FaceTextureAlpha < 0.95));
    flagPaint = vehicleMesh.FaceMaterialIndex == find(strcmp(vehicleMesh.MaterialNames,'color'));
    assert(size(unique(round(vehicleMesh.FaceTextureColors(flagPaint,:)*20),'rows'),1) > 5);
else
    fprintf(1,'   (skipped: the Prius download is not in this copy)\n');
end

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
glbFile = fcn_INTERNAL_writeTestGLB(fullfile(tempdir,'carmesh3d_test_square.glb'), 'plain');
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);
assert(isequal(size(vehicleMesh.Faces),[2 3]));
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=-1);
assert(isequal(size(vehicleMesh.Faces),[2 3]));
assert(isempty(findobj('Number',figNum)));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 20;

tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=[]);
end
slow_method = toc;

tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_readGLB(glbFile, FigNum=-1);
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
    %% A file that is not a .glb
    vehicleMesh = fcn_CarMesh3D_readGLB('model.obj');

    %% A missing file
    vehicleMesh = fcn_CarMesh3D_readGLB('no_such_file.glb');
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_writeTestGLB
function glbFile = fcn_INTERNAL_writeTestGLB(glbFile, caseName)
% Writes a unit square (glTF x, y from 0 to 1 at z = 0, facing +z) as two
% triangles. 'plain' and 'moved': one textured material (left half of the
% texture red, right half blue; the left triangle maps to the red half).
% 'moved' also puts the square in a node translated, turned, and mirrored.
% 'halfGlass': the right triangle is glass (transmission 0.7).
% 'allGlass': both triangles are glass.

corners = single([0 0 0; 1 0 0; 1 1 0; 0 1 0]);
% Triangle 1 (corners 1 2 4) maps into the texture's left (red) half,
% triangle 2 (corners 2 3 4) into its right (blue) half, so each has its
% own three vertices (v is measured down from the image's top)
positions = [corners([1 2 4],:); corners([2 3 4],:)];
uv = single([0.05 0.95; 0.45 0.95; 0.05 0.05; 0.55 0.95; 0.95 0.05; 0.55 0.05]);
indices = uint16(0:5);

% A 2 x 2 PNG: left column red, right column blue
pixels = uint8(cat(3, [255 0; 255 0], [0 0; 0 0], [0 255; 0 255]));
pngFile = [tempname '.png'];
imwrite(pixels, pngFile);
fileId = fopen(pngFile,'r'); pngBytes = fread(fileId, Inf, '*uint8')'; fclose(fileId);
delete(pngFile);

% The binary buffer: positions, uv, indices, image (each 4-byte aligned)
pad = @(bytes) [bytes, zeros(1, mod(-numel(bytes),4), 'uint8')];
positionBytes = typecast(reshape(positions',1,[]), 'uint8');
uvBytes = typecast(reshape(uv',1,[]), 'uint8');
indexBytes = pad(typecast(indices, 'uint8'));
imageBytes = pad(pngBytes);
binaryChunk = [positionBytes, uvBytes, indexBytes, imageBytes];
offsets = cumsum([0, numel(positionBytes), numel(uvBytes), numel(indexBytes)]);

gltf = struct();
gltf.asset = struct('version','2.0');
gltf.buffers = {struct('byteLength', numel(binaryChunk))};
gltf.bufferViews = {struct('buffer',0,'byteOffset',offsets(1),'byteLength',numel(positionBytes)), ...
    struct('buffer',0,'byteOffset',offsets(2),'byteLength',numel(uvBytes)), ...
    struct('buffer',0,'byteOffset',offsets(3),'byteLength',numel(indices)*2), ...
    struct('buffer',0,'byteOffset',offsets(4),'byteLength',numel(pngBytes))};
gltf.accessors = {struct('bufferView',0,'componentType',5126,'count',6,'type','VEC3','min',[0 0 0],'max',[1 1 0]), ...
    struct('bufferView',1,'componentType',5126,'count',6,'type','VEC2'), ...
    struct('bufferView',2,'componentType',5123,'count',numel(indices),'type','SCALAR')};
gltf.images = {struct('bufferView',3,'mimeType','image/png')};
gltf.textures = {struct('source',0)};
paint = struct('name','paint', 'pbrMetallicRoughness', struct('baseColorTexture', struct('index',0)));
glass = struct('name','glass', 'alphaMode','BLEND', ...
    'pbrMetallicRoughness', struct('baseColorFactor',[0.2 0.2 0.2 1]), ...
    'extensions', struct('KHR_materials_transmission', struct('transmissionFactor',0.7)));
gltf.materials = {paint, glass};
switch caseName
    case 'halfGlass'
        primitives = {struct('attributes',struct('POSITION',0,'TEXCOORD_0',1),'indices',2,'material',0)};
        % (two primitives over the same accessors would repeat both
        % triangles: write the glass triangle with its own index accessor)
        gltf.bufferViews{end+1} = struct('buffer',0,'byteOffset',offsets(3),'byteLength',6);
        gltf.bufferViews{end+1} = struct('buffer',0,'byteOffset',offsets(3)+6,'byteLength',6);
        gltf.accessors{end+1} = struct('bufferView',4,'componentType',5123,'count',3,'type','SCALAR');
        gltf.accessors{end+1} = struct('bufferView',5,'componentType',5123,'count',3,'type','SCALAR');
        primitives = {struct('attributes',struct('POSITION',0,'TEXCOORD_0',1),'indices',3,'material',0), ...
            struct('attributes',struct('POSITION',0,'TEXCOORD_0',1),'indices',4,'material',1)};
    case 'allGlass'
        primitives = {struct('attributes',struct('POSITION',0,'TEXCOORD_0',1),'indices',2,'material',1)};
    otherwise
        primitives = {struct('attributes',struct('POSITION',0,'TEXCOORD_0',1),'indices',2,'material',0)};
end
gltf.meshes = {struct('name','square','primitives',{primitives})};
if strcmp(caseName,'moved')
    % 90 degrees about y: quaternion [0 sin(45) 0 cos(45)]; mirror in x
    gltf.nodes = {struct('name','mover','translation',[5 0 0],'rotation',[0 sin(pi/4) 0 cos(pi/4)], ...
        'scale',[-1 1 1],'mesh',0)};
else
    gltf.nodes = {struct('name','square','mesh',0)};
end
gltf.scenes = {struct('nodes',{0})};
gltf.scene = 0;

jsonText = jsonencode(gltf);
jsonText = strrep(jsonText, '"nodes":0', '"nodes":[0]');   % (jsonencode writes a 1-item list as a number)
jsonBytes = uint8(jsonText);
jsonBytes = [jsonBytes, repmat(uint8(' '), 1, mod(-numel(jsonBytes),4))];
totalLength = 12 + 8 + numel(jsonBytes) + 8 + numel(binaryChunk);
fileId = fopen(glbFile,'w','l');
fwrite(fileId, uint8('glTF'), 'uint8');
fwrite(fileId, [2 totalLength], 'uint32');
fwrite(fileId, numel(jsonBytes), 'uint32'); fwrite(fileId, uint8('JSON'), 'uint8'); fwrite(fileId, jsonBytes, 'uint8');
fwrite(fileId, numel(binaryChunk), 'uint32'); fwrite(fileId, uint8(['BIN' char(0)]), 'uint8'); fwrite(fileId, binaryChunk, 'uint8');
fclose(fileId);
end % Ends fcn_INTERNAL_writeTestGLB
