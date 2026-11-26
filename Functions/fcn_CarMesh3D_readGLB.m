function vehicleMesh = fcn_CarMesh3D_readGLB(fileName, options)
% fcn_CarMesh3D_readGLB

% Reads a binary glTF file (.glb) directly in MATLAB, with no Blender,
% keeping what the OBJ conversion loses: each material's base color and
% transparency, and the colors of its texture images. Each face gets the
% color of its texture under it (sampled at its center and corners), so
% parts painted into one texture (lamps, trim, and body in one material,
% as in many low-poly downloads) can be told apart by color.
%
% The mesh is returned with Blender's axes (Z up: glTF's Y-up axes are
% turned as Blender's glTF importer turns them, X stays, Y = -Z, Z = Y),
% so a vehicle script's importForwardAxis is the same as for a .glb
% converted by fcn_CarMesh3D_convertToOBJ. Every mesh node is placed by
% its node transforms (meshes used by several nodes are copied).
%
% Not read: Draco- or meshopt-compressed geometry (an error says so: use
% the Blender conversion), sparse accessors, texture transforms, and
% external .gltf buffers (only .glb).
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_readGLB(fileName,...
%           (Name=nameString), (License=licenseString), (FigNum=figNum))
%
% INPUTS:
%
%      fileName: the path to a .glb file.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Name: a name for the mesh. Default is the file name.
%
%      License: the license of the downloaded model. Default 'unknown'.
%
%      FigNum: a figure to plot the mesh in its face colors. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure with the fields of
%      fcn_CarMesh3D_importMesh:
%           Name, Source, License, Units ('unknown'), Frame ('source'),
%           Vertices (N x 3), Faces (M x 3), MaterialNames (K x 1 cell),
%           MaterialColors (K x 3: the base color times the texture's
%           mean color over the material's faces, area-weighted),
%           MaterialAlpha (K x 1), FaceMaterialIndex (M x 1),
%           GroupNames (G x 1 cell: node name / mesh name / primitive),
%           FaceGroupIndex (M x 1)
%      and two more, per face:
%           FaceTextureColors (M x 3): the face's own color (base color
%               times its texture under it; the base color alone where a
%               material has no texture)
%           FaceTextureAlpha (M x 1): its opacity (1 for opaque materials;
%               the base alpha times the texture's alpha for blended
%               ones; 1 - transmissionFactor (at least 0.1) for
%               KHR_materials_transmission glass)
%      and one more:
%           FlagSeeThroughReliable (true/false): false when more than 60% of
%               the surface is marked see-through (an exporter error seen
%               in some downloads); then every face is set opaque and a
%               CarMesh3D:unreliableSeeThrough warning is given
%
% DEPENDENCIES:
%
%      jsondecode, imread, typecast (MATLAB base);
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       vehicleMesh = fcn_CarMesh3D_readGLB('2010_toyota_prius.glb', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_readGLB.m for a full
%       test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_readGLB
%   % * First write: reads .glb geometry, materials, and texture colors
%   %   % (the OBJ conversion loses colors; low-poly downloads paint lamps
%   %   % and trim into one textured material)
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_readGLB
%   % * Skinned meshes are placed by their joints (each joint's world
%   %   % transform times its inverse bind matrix, weighted per vertex), as
%   %   % glTF says, not by their node: the 2008 Shelby GT's wheels

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_readGLB
%   % * KHR_texture_transform; .gltf files with external buffers



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    fileName
    options.Name = []            % Mesh name; [] for the file name
    options.License = 'unknown'  % License of the downloaded model
    options.FigNum = []          % Figure to plot into; [] for no plot, -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        if ~(ischar(fileName) || isstring(fileName)) || ~isfile(fileName)
            error('File not found: %s', char(fileName));
        end
        [~,~,fileExtension] = fileparts(char(fileName));
        if ~strcmpi(fileExtension,'.glb')
            error('fcn_CarMesh3D_readGLB reads .glb files only (got %s)', fileExtension);
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fileName = char(fileName);
[~, fileBaseName, fileExtension] = fileparts(fileName);

% The two chunks of a .glb: JSON, then the binary buffer
fileId = fopen(fileName,'r','l');
if fileId < 0
    error('Unable to open %s', fileName);
end
fileBytes = fread(fileId, Inf, '*uint8');
fclose(fileId);
if numel(fileBytes) < 20 || ~strcmp(char(fileBytes(1:4))', 'glTF')
    error('%s is not a binary glTF (.glb) file', fileName);
end
position = 13;
gltf = [];
binaryChunk = uint8([]);
while position + 7 <= numel(fileBytes)
    chunkLength = double(typecast(fileBytes(position:position+3), 'uint32'));
    chunkType = char(fileBytes(position+4:position+7))';
    chunkData = fileBytes(position+8:position+7+chunkLength);
    if strcmp(chunkType,'JSON')
        gltf = jsondecode(char(chunkData'));
    elseif strcmp(chunkType, ['BIN' char(0)])
        binaryChunk = chunkData;
    end
    position = position + 8 + chunkLength;
end
if isempty(gltf)
    error('%s has no JSON chunk', fileName);
end
if isfield(gltf,'extensionsRequired')
    required = fcn_INTERNAL_asCell(gltf.extensionsRequired);
    compressed = required(contains(required, {'draco','meshopt'}, 'IgnoreCase',true));
    if ~isempty(compressed)
        error('%s uses compressed geometry (%s), which fcn_CarMesh3D_readGLB does not read. Use fcn_CarMesh3D_importMesh (the Blender conversion) instead.', ...
            fileName, strjoin(compressed, ', '));
    end
end

% Materials: names, base colors, alpha, textures
materials = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'materials',{}));
numMaterials = numel(materials);
materialNames = cell(numMaterials+1,1);
materialBase = ones(numMaterials+1,4);
materialTexture = nan(numMaterials+1,2);   % [image index, texture coordinate set]
materialSeeThrough = false(numMaterials+1,1);
for ith_material = 1:numMaterials
    thisMaterial = materials{ith_material};
    materialNames{ith_material} = char(fcn_INTERNAL_field(thisMaterial,'name',sprintf('material_%d',ith_material-1)));
    pbr = fcn_INTERNAL_field(thisMaterial,'pbrMetallicRoughness',struct());
    materialBase(ith_material,:) = reshape(double(fcn_INTERNAL_field(pbr,'baseColorFactor',[1;1;1;1])),1,4);
    colorTexture = fcn_INTERNAL_field(pbr,'baseColorTexture',[]);
    if ~isempty(colorTexture)
        textures = fcn_INTERNAL_asCell(gltf.textures);
        thisTexture = textures{colorTexture.index+1};
        if isfield(thisTexture,'source')
            materialTexture(ith_material,:) = [thisTexture.source, fcn_INTERNAL_field(colorTexture,'texCoord',0)];
        end
    end
    alphaMode = char(fcn_INTERNAL_field(thisMaterial,'alphaMode','OPAQUE'));
    extensions = fcn_INTERNAL_field(thisMaterial,'extensions',struct());
    transmission = fcn_INTERNAL_field(fcn_INTERNAL_field(extensions,'KHR_materials_transmission',struct()),'transmissionFactor',0);
    flagBlend = strcmp(alphaMode,'BLEND');   % (its alpha may come from the texture)
    materialSeeThrough(ith_material) = flagBlend || transmission > 0;
    if ~materialSeeThrough(ith_material)
        materialBase(ith_material,4) = 1;
    elseif transmission > 0
        materialBase(ith_material,4) = min(materialBase(ith_material,4), max(0.1, 1-transmission));
    end
end
materialNames{end} = 'default';

% The scene's nodes, with their world transforms
nodes = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'nodes',{}));
meshes = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'meshes',{}));
sceneIndex = fcn_INTERNAL_field(gltf,'scene',0);
scenes = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'scenes',{}));
if isempty(scenes)
    rootNodes = 0:numel(nodes)-1;
else
    rootNodes = reshape(fcn_INTERNAL_field(scenes{sceneIndex+1},'nodes',[]),1,[]);
end
stack = num2cell(rootNodes);
stackTransforms = repmat({eye(4)}, 1, numel(stack));
meshInstances = {};   % {mesh index, world transform, node name, skin index (-1: none)}
nodeWorld = cell(numel(nodes),1);   % (every node's world transform: the joints of skins)
while ~isempty(stack)
    nodeIndex = stack{end};
    parentTransform = stackTransforms{end};
    stack(end) = [];
    stackTransforms(end) = [];
    thisNode = nodes{nodeIndex+1};
    worldTransform = parentTransform*fcn_INTERNAL_nodeTransform(thisNode);
    nodeWorld{nodeIndex+1} = worldTransform;
    if isfield(thisNode,'mesh')
        meshInstances(end+1,:) = {thisNode.mesh, worldTransform, char(fcn_INTERNAL_field(thisNode,'name',sprintf('node_%d',nodeIndex))), ...
            fcn_INTERNAL_field(thisNode,'skin',-1)}; %#ok<AGROW>
    end
    children = reshape(fcn_INTERNAL_field(thisNode,'children',[]),1,[]);
    for ith_child = children
        stack{end+1} = ith_child; %#ok<AGROW>
        stackTransforms{end+1} = worldTransform; %#ok<AGROW>
    end
end

% The skins' joint matrices: each joint's world transform times its
% inverse bind matrix (a skinned mesh is placed by its joints, not by its
% node: the 2008 Shelby GT's wheels were off their axles)
skins = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'skins',{}));
skinJointMatrices = cell(numel(skins),1);
for ith_skin = 1:numel(skins)
    thisSkin = skins{ith_skin};
    joints = reshape(double(thisSkin.joints),1,[]);
    if isfield(thisSkin,'inverseBindMatrices')
        inverseBind = double(fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisSkin.inverseBindMatrices));
    else
        inverseBind = repmat(reshape(eye(4),1,16), numel(joints), 1);
    end
    jointMatrices = cell(numel(joints),1);
    for ith_joint = 1:numel(joints)
        jointWorld = nodeWorld{joints(ith_joint)+1};
        if isempty(jointWorld)
            jointWorld = eye(4);   % (a joint outside the scene: left where it is bound)
        end
        jointMatrices{ith_joint} = jointWorld*reshape(inverseBind(ith_joint,:),4,4);
    end
    skinJointMatrices{ith_skin} = jointMatrices;
end

% The triangles of every primitive of every placed mesh
allVertices = cell(0,1);
allFaces = cell(0,1);
allUV = cell(0,1);
faceMaterialParts = cell(0,1);
faceGroupParts = cell(0,1);
groupNames = cell(0,1);
vertexCount = 0;
for ith_instance = 1:size(meshInstances,1)
    thisMesh = meshes{meshInstances{ith_instance,1}+1};
    worldTransform = meshInstances{ith_instance,2};
    primitives = fcn_INTERNAL_asCell(thisMesh.primitives);
    for ith_primitive = 1:numel(primitives)
        thisPrimitive = primitives{ith_primitive};
        if fcn_INTERNAL_field(thisPrimitive,'mode',4) ~= 4
            continue;   % (triangles only)
        end
        positions = fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisPrimitive.attributes.POSITION);
        numVertices = size(positions,1);
        if isfield(thisPrimitive,'indices')
            indices = fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisPrimitive.indices);
            triangles = reshape(double(indices)+1, 3, [])';
        else
            triangles = reshape(1:numVertices, 3, [])';
        end
        materialIndex = fcn_INTERNAL_field(thisPrimitive,'material',numMaterials) + 1;
        uv = nan(numVertices,2);
        textureSet = materialTexture(materialIndex,2);
        if ~isnan(textureSet) && isfield(thisPrimitive.attributes, sprintf('TEXCOORD_%d',textureSet))
            uv = double(fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisPrimitive.attributes.(sprintf('TEXCOORD_%d',textureSet))));
        end
        % (world positions; a mirroring transform reverses the winding)
        skinIndex = meshInstances{ith_instance,4};
        if skinIndex >= 0 && isfield(thisPrimitive.attributes,'JOINTS_0') && isfield(thisPrimitive.attributes,'WEIGHTS_0')
            [worldPositions, placingTransform] = fcn_INTERNAL_skinPositions(double(positions), ...
                double(fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisPrimitive.attributes.JOINTS_0)), ...
                double(fcn_INTERNAL_readAccessor(gltf, binaryChunk, thisPrimitive.attributes.WEIGHTS_0)), ...
                skinJointMatrices{skinIndex+1});
        else
            worldPositions = [double(positions) ones(numVertices,1)]*worldTransform';
            placingTransform = worldTransform;
        end
        if det(placingTransform(1:3,1:3)) < 0
            triangles = triangles(:,[1 3 2]);
        end
        allVertices{end+1,1} = worldPositions(:,1:3); %#ok<AGROW>
        allFaces{end+1,1} = triangles + vertexCount; %#ok<AGROW>
        allUV{end+1,1} = uv; %#ok<AGROW>
        vertexCount = vertexCount + numVertices;
        groupNames{end+1,1} = sprintf('%s / %s / %d', meshInstances{ith_instance,3}, char(fcn_INTERNAL_field(thisMesh,'name','mesh')), ith_primitive-1); %#ok<AGROW>
        faceMaterialParts{end+1,1} = repmat(materialIndex, size(triangles,1), 1); %#ok<AGROW>
        faceGroupParts{end+1,1} = repmat(numel(groupNames), size(triangles,1), 1); %#ok<AGROW>
    end
end
vertices = vertcat(allVertices{:});
faces = vertcat(allFaces{:});
vertexUV = vertcat(allUV{:});
faceMaterial = vertcat(faceMaterialParts{:});
faceGroup = vertcat(faceGroupParts{:});
if isempty(faces)
    error('%s has no triangle meshes', fileName);
end

% Each face's color: base color times the texture under it (sampled at
% its center and halfway to each corner, averaged)
numFaces = size(faces,1);
faceColors = materialBase(faceMaterial,1:3);
faceAlpha = materialBase(faceMaterial,4);
images = fcn_INTERNAL_asCell(fcn_INTERNAL_field(gltf,'images',{}));
imageCache = cell(numel(images),1);
for ith_material = reshape(find(~isnan(materialTexture(:,1))),1,[])
    flagFaces = faceMaterial==ith_material;
    if ~any(flagFaces)
        continue;
    end
    imageIndex = materialTexture(ith_material,1) + 1;
    if isempty(imageCache{imageIndex})
        imageCache{imageIndex} = fcn_INTERNAL_readImage(gltf, binaryChunk, images{imageIndex});
    end
    thisImage = imageCache{imageIndex};
    if isempty(thisImage.Color)
        continue;
    end
    theseFaces = faces(flagFaces,:);
    cornerUV = cat(3, vertexUV(theseFaces(:,1),:), vertexUV(theseFaces(:,2),:), vertexUV(theseFaces(:,3),:));
    centerUV = mean(cornerUV,3);
    samplePoints = {centerUV, (centerUV+cornerUV(:,:,1))/2, (centerUV+cornerUV(:,:,2))/2, (centerUV+cornerUV(:,:,3))/2};
    sampledColor = zeros(sum(flagFaces),3);
    sampledAlpha = zeros(sum(flagFaces),1);
    for ith_point = 1:numel(samplePoints)
        [thisColor, thisAlpha] = fcn_INTERNAL_sample(thisImage, samplePoints{ith_point});
        sampledColor = sampledColor + thisColor/numel(samplePoints);
        sampledAlpha = sampledAlpha + thisAlpha/numel(samplePoints);
    end
    flagValid = all(isfinite(sampledColor),2);
    theseIndices = find(flagFaces);
    faceColors(theseIndices(flagValid),:) = sampledColor(flagValid,:).*materialBase(ith_material,1:3);
    if materialSeeThrough(ith_material)
        faceAlpha(theseIndices(flagValid)) = materialBase(ith_material,4).*sampledAlpha(flagValid);
    end
end

% Each material's color: the area-weighted mean of its faces' colors
faceAreas = vecnorm(cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2), 2, 2)/2;
materialColors = nan(numMaterials+1,3);
materialAlpha = ones(numMaterials+1,1);
for ith_material = 1:numMaterials+1
    flagFaces = faceMaterial==ith_material;
    if any(flagFaces)
        weights = faceAreas(flagFaces) + eps;
        materialColors(ith_material,:) = sum(faceColors(flagFaces,:).*weights,1)/sum(weights);
        materialAlpha(ith_material) = sum(faceAlpha(flagFaces).*weights)/sum(weights);
    end
end

% The see-through flags are trusted only if 60% or less of the surface is
% see-through (some exporters mark every material, paint and tires
% included, as transmissive)
seeThroughShare = sum(faceAreas(faceAlpha<0.95))/max(sum(faceAreas),eps);
flagSeeThroughReliable = seeThroughShare <= 0.6;
if ~flagSeeThroughReliable
    warning('CarMesh3D:unreliableSeeThrough', ...
        '%s marks %.0f%% of its surface as see-through: its transparency flags are not used (all faces set opaque).', ...
        [fileBaseName fileExtension], 100*seeThroughShare);
    faceAlpha(:) = 1;
    materialAlpha(:) = 1;
end

% Blender's axes (Z up): glTF [x y z] -> [x -z y]
vertices = [vertices(:,1), -vertices(:,3), vertices(:,2)];

% Drop the 'default' material if no face uses it
usedMaterials = unique(faceMaterial);
[~, faceMaterial] = ismember(faceMaterial, usedMaterials);

vehicleMesh = struct();
if isempty(options.Name)
    vehicleMesh.Name = [fileBaseName fileExtension];
else
    vehicleMesh.Name = char(options.Name);
end
vehicleMesh.Source = fileName;
vehicleMesh.License = char(options.License);
vehicleMesh.Units = 'unknown';
vehicleMesh.Frame = 'source';
vehicleMesh.Vertices = vertices;
vehicleMesh.Faces = faces;
vehicleMesh.MaterialNames = materialNames(usedMaterials);
vehicleMesh.MaterialColors = materialColors(usedMaterials,:);
vehicleMesh.MaterialAlpha = materialAlpha(usedMaterials);
vehicleMesh.FaceMaterialIndex = faceMaterial;
vehicleMesh.GroupNames = groupNames;
vehicleMesh.FaceGroupIndex = faceGroup;
vehicleMesh.FaceTextureColors = min(max(faceColors,0),1);
vehicleMesh.FaceTextureAlpha = min(max(faceAlpha,0),1);
vehicleMesh.FlagSeeThroughReliable = flagSeeThroughReliable;

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    figure(figNum);
    clf;
    patch('Vertices',vehicleMesh.Vertices, 'Faces',vehicleMesh.Faces, ...
        'FaceVertexCData',vehicleMesh.FaceTextureColors, 'FaceColor','flat', ...
        'FaceVertexAlphaData',vehicleMesh.FaceTextureAlpha, 'FaceAlpha','flat', ...
        'EdgeColor','none', 'FaceLighting','flat', 'AmbientStrength',0.6);
    axis equal;
    view(-55,20);
    camlight headlight;
    xlabel('X'); ylabel('Y'); zlabel('Z (up)');
    title(sprintf('%s: %d faces in their texture colors', vehicleMesh.Name, numFaces), 'Interpreter','none');
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_asCell
function items = fcn_INTERNAL_asCell(items)
% jsondecode gives a struct array (same fields) or a cell array (mixed
% fields) for a JSON list: this always gives a cell array
if isstruct(items)
    items = num2cell(items);
elseif ~iscell(items)
    items = num2cell(items);
end
items = items(:);
end % Ends fcn_INTERNAL_asCell

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(thisStruct, fieldName, defaultValue)
% A field's value, or the default when the field is missing
if isstruct(thisStruct) && isfield(thisStruct, fieldName)
    value = thisStruct.(fieldName);
else
    value = defaultValue;
end
end % Ends fcn_INTERNAL_field

%% fcn_INTERNAL_nodeTransform
function transform = fcn_INTERNAL_nodeTransform(thisNode)
% A node's local 4 x 4 transform (matrix, or translation-rotation-scale)
if isfield(thisNode,'matrix')
    transform = reshape(double(thisNode.matrix), 4, 4);   % (column-major)
    return;
end
translation = reshape(double(fcn_INTERNAL_field(thisNode,'translation',[0 0 0])),3,1);
rotation = reshape(double(fcn_INTERNAL_field(thisNode,'rotation',[0 0 0 1])),1,4);   % [x y z w]
scale = reshape(double(fcn_INTERNAL_field(thisNode,'scale',[1 1 1])),1,3);
qx = rotation(1); qy = rotation(2); qz = rotation(3); qw = rotation(4);
rotationMatrix = [1-2*(qy^2+qz^2), 2*(qx*qy-qz*qw), 2*(qx*qz+qy*qw);
                  2*(qx*qy+qz*qw), 1-2*(qx^2+qz^2), 2*(qy*qz-qx*qw);
                  2*(qx*qz-qy*qw), 2*(qy*qz+qx*qw), 1-2*(qx^2+qy^2)];
transform = eye(4);
transform(1:3,1:3) = rotationMatrix*diag(scale);
transform(1:3,4) = translation;
end % Ends fcn_INTERNAL_nodeTransform

%% fcn_INTERNAL_readAccessor
function [worldPositions, mainTransform] = fcn_INTERNAL_skinPositions(positions, joints, weights, jointMatrices)
% Skinned positions: each vertex moved by its joints' matrices, weighted
% (glTF linear blend skinning). mainTransform is the joint matrix with the
% most weight, for the winding.
numVertices = size(positions,1);
homogeneous = [positions ones(numVertices,1)];
worldPositions = zeros(numVertices,4);
weightSums = sum(weights,2);
weightSums(weightSums==0) = 1;
weights = weights./weightSums;
jointWeight = zeros(numel(jointMatrices),1);
for ith_influence = 1:size(joints,2)
    theseJoints = joints(:,ith_influence) + 1;
    theseWeights = weights(:,ith_influence);
    for thisJoint = unique(theseJoints(theseWeights>0))'
        rows = theseJoints==thisJoint & theseWeights>0;
        worldPositions(rows,:) = worldPositions(rows,:) + theseWeights(rows).*(homogeneous(rows,:)*jointMatrices{thisJoint}');
        jointWeight(thisJoint) = jointWeight(thisJoint) + sum(theseWeights(rows));
    end
end
[~, mainJoint] = max(jointWeight);
mainTransform = jointMatrices{mainJoint};
end % Ends fcn_INTERNAL_skinPositions

function data = fcn_INTERNAL_readAccessor(gltf, binaryChunk, accessorIndex)
% An accessor's data as a count x components array (normalized integers
% become 0 to 1)
accessors = fcn_INTERNAL_asCell(gltf.accessors);
accessor = accessors{accessorIndex+1};
componentCounts = struct('SCALAR',1, 'VEC2',2, 'VEC3',3, 'VEC4',4, 'MAT2',4, 'MAT3',9, 'MAT4',16);
numComponents = componentCounts.(accessor.type);
switch accessor.componentType
    case 5120, className = 'int8';   componentBytes = 1;
    case 5121, className = 'uint8';  componentBytes = 1;
    case 5122, className = 'int16';  componentBytes = 2;
    case 5123, className = 'uint16'; componentBytes = 2;
    case 5125, className = 'uint32'; componentBytes = 4;
    case 5126, className = 'single'; componentBytes = 4;
    otherwise, error('Unknown glTF component type %d', accessor.componentType);
end
count = accessor.count;
if ~isfield(accessor,'bufferView')
    data = zeros(count, numComponents);   % (all zeros, per the glTF rules)
    return;
end
bufferViews = fcn_INTERNAL_asCell(gltf.bufferViews);
bufferView = bufferViews{accessor.bufferView+1};
if fcn_INTERNAL_field(bufferView,'buffer',0) ~= 0
    error('Only the .glb file''s own buffer is read');
end
startByte = fcn_INTERNAL_field(bufferView,'byteOffset',0) + fcn_INTERNAL_field(accessor,'byteOffset',0);
elementBytes = numComponents*componentBytes;
stride = fcn_INTERNAL_field(bufferView,'byteStride',elementBytes);
if stride == elementBytes
    rawBytes = binaryChunk(startByte+1 : startByte+count*elementBytes);
else
    byteIndex = (0:count-1)'*stride + startByte + (1:elementBytes);
    rawBytes = reshape(binaryChunk(byteIndex)', [], 1);
end
data = reshape(typecast(rawBytes(:)', className), numComponents, count)';
if fcn_INTERNAL_field(accessor,'normalized',false)
    data = double(data)/double(intmax(className));
end
end % Ends fcn_INTERNAL_readAccessor

%% fcn_INTERNAL_readImage
function thisImage = fcn_INTERNAL_readImage(gltf, binaryChunk, imageInfo)
% An embedded image (PNG or JPEG) as doubles 0 to 1, with its alpha
thisImage = struct('Color',[], 'Alpha',[]);
if ~isfield(imageInfo,'bufferView')
    return;   % (an external image file: not read)
end
bufferViews = fcn_INTERNAL_asCell(gltf.bufferViews);
bufferView = bufferViews{imageInfo.bufferView+1};
startByte = fcn_INTERNAL_field(bufferView,'byteOffset',0);
imageBytes = binaryChunk(startByte+1 : startByte+bufferView.byteLength);
mimeType = char(fcn_INTERNAL_field(imageInfo,'mimeType','image/png'));
extension = '.png';
if contains(mimeType,'jpeg') || contains(mimeType,'jpg')
    extension = '.jpg';
elseif contains(mimeType,'webp')
    return;   % (WebP: not read by imread)
end
tempFile = [tempname extension];
fileId = fopen(tempFile,'w');
fwrite(fileId, imageBytes, 'uint8');
fclose(fileId);
cleanupFile = onCleanup(@() delete(tempFile));
try
    [pixels, colorMap, alpha] = imread(tempFile);
catch
    return;
end
if ~isempty(colorMap)
    pixels = ind2rgb(pixels, colorMap);
else
    pixels = im2double(pixels);
end
if size(pixels,3)==1
    pixels = repmat(pixels, 1, 1, 3);
end
thisImage.Color = pixels(:,:,1:3);
if ~isempty(alpha)
    thisImage.Alpha = im2double(alpha);
end
clear cleanupFile
end % Ends fcn_INTERNAL_readImage

%% fcn_INTERNAL_sample
function [colors, alpha] = fcn_INTERNAL_sample(thisImage, uv)
% The texture's color (nearest pixel) at each [u v] (wrapped into 0 to
% 1; v measured down from the image's top, as in glTF)
[numRows, numCols, ~] = size(thisImage.Color);
u = mod(uv(:,1), 1);
v = mod(uv(:,2), 1);
cols = min(numCols, max(1, floor(u*numCols)+1));
rows = min(numRows, max(1, floor(v*numRows)+1));
flagValid = all(isfinite(uv),2);
pixelIndex = sub2ind([numRows numCols], rows(flagValid), cols(flagValid));
colors = nan(size(uv,1),3);
for ith_channel = 1:3
    channel = thisImage.Color(:,:,ith_channel);
    colors(flagValid,ith_channel) = channel(pixelIndex);
end
alpha = ones(size(uv,1),1);
if ~isempty(thisImage.Alpha)
    alpha(flagValid) = thisImage.Alpha(pixelIndex);
end
end % Ends fcn_INTERNAL_sample
