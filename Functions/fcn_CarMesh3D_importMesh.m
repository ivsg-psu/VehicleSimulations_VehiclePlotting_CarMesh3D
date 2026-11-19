function vehicleMesh = fcn_CarMesh3D_importMesh(fileName, options)
% fcn_CarMesh3D_importMesh
% Reads a 3D model file into a CarMesh3D mesh structure. Supported formats:
%
%   .obj  Wavefront OBJ (the most common free-download format). Polygons
%         are split into triangles. Material names (usemtl) and group or
%         object names (g, o) are kept for each face, and material colors
%         and transparency are read from the .mtl file(s) named by
%         mtllib, when found next to the .obj file.
%   .stl  STL (ASCII or binary), read with MATLAB's stlread. STL files
%         have no materials or colors, so every face gets one 'default'
%         material.
%   .fbx, .glb, .gltf, .blend
%         Converted to OBJ first by fcn_CarMesh3D_convertToOBJ, which runs
%         the free program Blender in the background, then read as OBJ.
%         The converted file is saved next to the original and reused on
%         later calls. Converted files use Blender's axes (Z up).
%
% The mesh is returned exactly as stored in the file (its own units and
% axis directions). Use fcn_CarMesh3D_normalizeMesh next to put it into
% the CarMesh3D vehicle frame.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_importMesh(fileName,...
%           (Name=nameString),...
%           (License=licenseString),...
%           (BlenderPath=blenderExecutable),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      fileName: the full or relative path to a .obj, .stl, .fbx, .glb,
%      .gltf, or .blend file.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Name: a name for the mesh. Default is the file name.
%
%      License: the license of the downloaded model, for example
%      'CC0' or 'CC-BY 4.0, author: ...'. Default is 'unknown'. Recording
%      this is strongly recommended for any model that will be shared.
%
%      BlenderPath: the full path to the Blender program, used only for
%      .fbx, .glb, .gltf, and .blend files. Default is '' (search for it;
%      see fcn_CarMesh3D_convertToOBJ).
%
%      FigNum: a figure number to plot the imported mesh. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure with the fields
%           Name, Source, License, Units ('unknown'), Frame ('source'),
%           Vertices (N x 3), Faces (M x 3),
%           MaterialNames (K x 1 cell), MaterialColors (K x 3, NaN if
%           unknown), MaterialAlpha (K x 1), FaceMaterialIndex (M x 1),
%           GroupNames (G x 1 cell), FaceGroupIndex (M x 1)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_convertToOBJ (only for .fbx, .glb, .gltf, .blend)
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%      stlread (MATLAB base, R2018b or newer)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_importMesh.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_importMesh
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_importMesh
%   % * Added FBX, glTF, GLB, and .blend files, converted through Blender

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_importMesh
%   % * Read per-vertex colors (v x y z r g b) when present
%   % * Speed up OBJ parsing for very large files (over ~1 million lines)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    fileName
    options.Name = []          % Mesh name; [] for the file name
    options.License = 'unknown' % License of the downloaded model
    options.BlenderPath = ''   % Blender program, for FBX/glTF; '' to search
    options.FigNum = []        % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the fileName input
        if ~(ischar(fileName) || isstring(fileName))
            error('fileName must be a character string');
        end
        if ~exist(fileName,'file')
            error('File not found: %s',char(fileName));
        end
        [~,~,tempExtension] = fileparts(char(fileName));
        if ~any(strcmpi(tempExtension,{'.obj','.stl','.fbx','.glb','.gltf','.blend'}))
            error('Unsupported file type: %s. Supported types are .obj, .stl, .fbx, .glb, .gltf, and .blend.',tempExtension);
        end

        % Check the string options
        if ~isempty(options.Name) && ~(ischar(options.Name) || isstring(options.Name))
            error('Name must be a character string');
        end
        if ~(ischar(options.License) || isstring(options.License))
            error('License must be a character string');
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

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fileName = char(fileName);
[filePath, fileBaseName, fileExtension] = fileparts(fileName);

switch lower(fileExtension)
    case '.obj'
        vehicleMesh = fcn_INTERNAL_readOBJ(fileName, filePath);
    case {'.fbx','.glb','.gltf','.blend'}
        % Convert with Blender, then read the OBJ (and its .mtl)
        if flag_max_speed
            convertFigNum = -1;
        else
            convertFigNum = [];
        end
        objFile = fcn_CarMesh3D_convertToOBJ(fileName, BlenderPath=options.BlenderPath, FigNum=convertFigNum);
        [objPath, ~, ~] = fileparts(objFile);
        vehicleMesh = fcn_INTERNAL_readOBJ(objFile, objPath);
    case '.stl'
        vehicleMesh = fcn_INTERNAL_readSTL(fileName);
    otherwise
        error('Unsupported file type: %s',fileExtension);
end

% Fill in the descriptive fields
if isempty(options.Name)
    vehicleMesh.Name = [fileBaseName fileExtension];
else
    vehicleMesh.Name = char(options.Name);
end
vehicleMesh.Source = fileName;
vehicleMesh.License = char(options.License);
vehicleMesh.Units = 'unknown';
vehicleMesh.Frame = 'source';

% Keep a consistent field order
vehicleMesh = orderfields(vehicleMesh, {'Name','Source','License','Units','Frame',...
    'Vertices','Faces','MaterialNames','MaterialColors','MaterialAlpha',...
    'FaceMaterialIndex','GroupNames','FaceGroupIndex'});

if flag_do_debug
    fprintf(1,'Imported %s: %d vertices, %d triangles, %d materials, %d groups\n',...
        vehicleMesh.Name, size(vehicleMesh.Vertices,1), size(vehicleMesh.Faces,1),...
        length(vehicleMesh.MaterialNames), length(vehicleMesh.GroupNames));
end

%% Any debugging?
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
    fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
    title(sprintf('Imported: %s (%d faces, frame and units as stored in file)',...
        vehicleMesh.Name, size(vehicleMesh.Faces,1)),'Interpreter','none');
    xlabel('X (file units)'); ylabel('Y (file units)'); zlabel('Z (file units)');
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

%% fcn_INTERNAL_readOBJ
function vehicleMesh = fcn_INTERNAL_readOBJ(fileName, filePath)
% Reads a Wavefront OBJ file: vertices, polygon faces (split into
% triangles as fans), materials, and groups.

fileText = fileread(fileName);
fileLines = strtrim(splitlines(fileText));

% Classify each line by its leading keyword
flagVertex  = startsWith(fileLines, {'v ', sprintf('v\t')});
flagFace    = startsWith(fileLines, {'f ', sprintf('f\t')});
flagUseMtl  = startsWith(fileLines, 'usemtl');
flagMtlLib  = startsWith(fileLines, 'mtllib');
flagGroup   = startsWith(fileLines, {'g ', sprintf('g\t'), 'o ', sprintf('o\t')}) | strcmp(fileLines,'g') | strcmp(fileLines,'o');

% Read all vertices (only the first 3 numbers; some files add colors)
vertexLines = fileLines(flagVertex);
vertexValues = cellfun(@(s) sscanf(s(2:end),'%f')', vertexLines, 'UniformOutput', false);
numValues = cellfun(@numel, vertexValues);
if any(numValues<3)
    error('Found a vertex line with fewer than 3 numbers in file: %s',fileName);
end
vertices = cell2mat(cellfun(@(x) x(1:3), vertexValues, 'UniformOutput', false));
if isempty(vertices)
    error('No vertices found in OBJ file: %s',fileName);
end

% Count vertices seen before each line, for negative (relative) indices
verticesBeforeLine = cumsum(flagVertex);

% Walk through face, material, and group lines in file order
eventLines = find(flagFace | flagUseMtl | flagGroup | flagMtlLib);
materialNames = {};
groupNames = {};
mtlLibraries = {};
currentMaterial = 0;
currentGroup = 0;

faces = zeros(2*sum(flagFace), 3);
faceMaterial = zeros(2*sum(flagFace), 1);
faceGroup = zeros(2*sum(flagFace), 1);
numFaces = 0;

for ith_event = 1:length(eventLines)
    lineIndex = eventLines(ith_event);
    thisLine = fileLines{lineIndex};

    if flagFace(lineIndex)
        % Take the first number of each token: v, v/vt, v//vn, v/vt/vn
        tokens = regexp(thisLine(2:end), '(?:^|\s)(-?\d+)', 'tokens');
        polygonIndices = str2double([tokens{:}]);
        % Negative indices count back from the latest vertex
        flagNegative = polygonIndices<0;
        polygonIndices(flagNegative) = verticesBeforeLine(lineIndex) + polygonIndices(flagNegative) + 1;

        numCorners = length(polygonIndices);
        if numCorners<3
            continue; % Skip degenerate lines
        end
        newFaces = [repmat(polygonIndices(1), numCorners-2, 1), polygonIndices(2:end-1)', polygonIndices(3:end)'];
        numNew = size(newFaces,1);

        % Grow the storage if needed
        if numFaces + numNew > size(faces,1)
            extraRows = max(numNew, size(faces,1));
            faces = [faces; zeros(extraRows,3)]; %#ok<AGROW>
            faceMaterial = [faceMaterial; zeros(extraRows,1)]; %#ok<AGROW>
            faceGroup = [faceGroup; zeros(extraRows,1)]; %#ok<AGROW>
        end
        faces(numFaces+1:numFaces+numNew,:) = newFaces;
        faceMaterial(numFaces+1:numFaces+numNew) = currentMaterial;
        faceGroup(numFaces+1:numFaces+numNew) = currentGroup;
        numFaces = numFaces + numNew;

    elseif flagUseMtl(lineIndex)
        thisName = strtrim(thisLine(7:end));
        if isempty(thisName)
            thisName = 'default';
        end
        matchIndex = find(strcmp(materialNames, thisName), 1);
        if isempty(matchIndex)
            materialNames{end+1,1} = thisName; %#ok<AGROW>
            matchIndex = length(materialNames);
        end
        currentMaterial = matchIndex;

    elseif flagGroup(lineIndex)
        thisName = strtrim(thisLine(2:end));
        if isempty(thisName)
            thisName = 'default';
        end
        matchIndex = find(strcmp(groupNames, thisName), 1);
        if isempty(matchIndex)
            groupNames{end+1,1} = thisName; %#ok<AGROW>
            matchIndex = length(groupNames);
        end
        currentGroup = matchIndex;

    elseif flagMtlLib(lineIndex)
        mtlLibraries{end+1,1} = strtrim(thisLine(7:end)); %#ok<AGROW>
    end
end

faces = faces(1:numFaces,:);
faceMaterial = faceMaterial(1:numFaces);
faceGroup = faceGroup(1:numFaces);

% Check that faces were found, and their index range
if 0==numFaces
    error('No faces found in OBJ file: %s',fileName);
end
if any(faces(:)<1) || any(faces(:)>size(vertices,1))
    error('OBJ file %s has face indices outside the vertex list',fileName);
end

% Faces that came before any usemtl get a 'default' material
if any(faceMaterial==0)
    materialNames{end+1,1} = 'default';
    faceMaterial(faceMaterial==0) = length(materialNames);
end
if any(faceGroup==0)
    groupNames{end+1,1} = 'default';
    faceGroup(faceGroup==0) = length(groupNames);
end

% Read material colors from the .mtl file(s), if they can be found
numMaterials = length(materialNames);
materialColors = nan(numMaterials,3);
materialAlpha = ones(numMaterials,1);
for ith_lib = 1:length(mtlLibraries)
    mtlFile = fullfile(filePath, mtlLibraries{ith_lib});
    if exist(mtlFile,'file')
        [mtlNames, mtlColors, mtlAlpha] = fcn_INTERNAL_readMTL(mtlFile);
        for ith_material = 1:numMaterials
            matchIndex = find(strcmp(mtlNames, materialNames{ith_material}), 1);
            if ~isempty(matchIndex)
                materialColors(ith_material,:) = mtlColors(matchIndex,:);
                materialAlpha(ith_material) = mtlAlpha(matchIndex);
            end
        end
    else
        warning('on','backtrace');
        warning('Material library not found: %s. Colors will be assigned later by part.',mtlFile);
    end
end

vehicleMesh = struct;
vehicleMesh.Vertices = vertices;
vehicleMesh.Faces = faces;
vehicleMesh.MaterialNames = materialNames;
vehicleMesh.MaterialColors = materialColors;
vehicleMesh.MaterialAlpha = materialAlpha;
vehicleMesh.FaceMaterialIndex = faceMaterial;
vehicleMesh.GroupNames = groupNames;
vehicleMesh.FaceGroupIndex = faceGroup;
end % Ends fcn_INTERNAL_readOBJ

%% fcn_INTERNAL_readMTL
function [mtlNames, mtlColors, mtlAlpha] = fcn_INTERNAL_readMTL(mtlFile)
% Reads material names, diffuse colors (Kd), and transparency (d or Tr)
% from a Wavefront .mtl file
mtlLines = strtrim(splitlines(fileread(mtlFile)));
mtlNames = {};
mtlColors = zeros(0,3);
mtlAlpha = zeros(0,1);
for ith_line = 1:length(mtlLines)
    thisLine = mtlLines{ith_line};
    if startsWith(thisLine,'newmtl')
        mtlNames{end+1,1} = strtrim(thisLine(7:end)); %#ok<AGROW>
        mtlColors(end+1,:) = nan(1,3); %#ok<AGROW>
        mtlAlpha(end+1,1) = 1; %#ok<AGROW>
    elseif isempty(mtlNames)
        continue; % Ignore lines before the first material
    elseif startsWith(thisLine,'Kd ')
        values = sscanf(thisLine(3:end),'%f');
        if numel(values)>=3
            mtlColors(end,:) = values(1:3)';
        end
    elseif startsWith(thisLine,'d ')
        values = sscanf(thisLine(2:end),'%f');
        if ~isempty(values)
            mtlAlpha(end) = values(1);
        end
    elseif startsWith(thisLine,'Tr ')
        values = sscanf(thisLine(3:end),'%f');
        if ~isempty(values)
            mtlAlpha(end) = 1 - values(1);
        end
    end
end
end % Ends fcn_INTERNAL_readMTL

%% fcn_INTERNAL_readSTL
function vehicleMesh = fcn_INTERNAL_readSTL(fileName)
% Reads an STL file using MATLAB's stlread. STL has no materials.
stlTriangulation = stlread(fileName);
vehicleMesh = struct;
vehicleMesh.Vertices = stlTriangulation.Points;
vehicleMesh.Faces = stlTriangulation.ConnectivityList;
vehicleMesh.MaterialNames = {'default'};
vehicleMesh.MaterialColors = nan(1,3);
vehicleMesh.MaterialAlpha = 1;
vehicleMesh.FaceMaterialIndex = ones(size(vehicleMesh.Faces,1),1);
vehicleMesh.GroupNames = {'default'};
vehicleMesh.FaceGroupIndex = ones(size(vehicleMesh.Faces,1),1);
end % Ends fcn_INTERNAL_readSTL
