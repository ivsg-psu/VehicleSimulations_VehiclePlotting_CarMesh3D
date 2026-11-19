function vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, options)
% fcn_CarMesh3D_simplifyMesh
% Cleans and simplifies a labeled mesh for fast plotting and animation,
% and makes every face normal point outward. The mesh is split into
% groups that share a part, a wheel number, and a color/alpha, and each
% group is processed separately so that parts, wheels, and colors stay
% intact:
%
%   1. Merge duplicate vertices (many exported files split vertices at
%      texture seams, which breaks connectivity).
%   2. Remove degenerate faces (repeated corners or zero area) and
%      duplicate faces.
%   3. Reduce the face count with MATLAB's reducepatch, so that the whole
%      vehicle has about TargetFaces faces (each group keeps its share).
%      Groups with fewer than 50 faces (windows, lights) are not reduced.
%   4. Make the face winding consistent across each connected surface,
%      then flip each surface, if needed, so its normals point outward:
%      closed surfaces use their signed volume; open surfaces (such as
%      glass panes) point away from the vehicle center. This step looks
%      at each part and wheel as a whole, so a wheel made of separate
%      tire and rim colors is still treated as one closed object.
%   4b. Check what can actually be seen. Downloaded bodies are often
%      made of many separate open panels (hood, doors, roof), and the rule
%      in step 4 can point a whole panel inward, which makes it look
%      darker than the panels around it. So a ray is sent from each face
%      along its normal and opposite to it. If only the opposite ray
%      reaches open space, the face is seen from its back and is flipped.
%      Faces hidden in both directions (inside the body) are left alone.
%      See-through faces (glass) do not block the rays.
%   5. Compute unit face normals.
%
% Keeping groups separate also gives sharp edges between parts, which
% looks better with lighting.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh,...
%           (TargetFaces=numFaces),...
%           (MergeTolerance=tolerance),...
%           (VisibilityCheck=flag), (MaxVisibilityFaces=numFaces),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh structure (from
%      fcn_CarMesh3D_labelParts), usually already fitted to the spec.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TargetFaces: the approximate total number of faces wanted. If the
%      mesh already has fewer faces, it is cleaned but not reduced.
%      Default is 5000 (a good size for animation). Each group keeps at
%      least 4 faces, and groups under 50 faces are not reduced, so the
%      result can be somewhat above the target.
%
%      MergeTolerance: vertices closer than this distance (in mesh units,
%      normally meters) are merged. Default is 1e-4 (0.1 mm).
%
%      VisibilityCheck: true (default) to do step 4b. Its time grows with
%      the square of the face count (about 10 s for 15000 faces), so it is
%      skipped, with a warning, above MaxVisibilityFaces.
%
%      MaxVisibilityFaces: the largest face count for step 4b. Default
%      30000.
%
%      FigNum: a figure number to plot the mesh before and after. If empty
%      or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with new Vertices, Faces, and
%      per-face fields (FacePartIndex, FaceWheelIndex, FaceColors,
%      FaceAlpha, FaceMaterialIndex, FaceGroupIndex), plus:
%           FaceNormals (M x 3): unit outward normal of each face
%           SimplifyInfo: a structure with OriginalFaces, FinalFaces,
%               OriginalVertices, FinalVertices, and VisibilityFlips (the
%               number of faces step 4b turned around; NaN if skipped)
%      FaceMaterialIndex and FaceGroupIndex are set to the values of the
%      first face of each group, since reduced faces no longer map to
%      single original faces.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%      reducepatch, uniquetol (MATLAB base)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_simplifyMesh.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * Light types (FaceLightType) are kept, and groups split by them
%   % * Added the visibility check (step 4b, VisibilityCheck=): panels
%   %   % that were pointed inward looked darker than their neighbors
%   %   % (seen on the 2014 Ford Transit Connect model)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * Allow a different face budget per part (e.g. more faces for the
%   %   % body, fewer for wheels)
%   % * Use an accumulating queue for very large groups (the breadth-first
%   %   % search grows its queue one face at a time)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.TargetFaces = 5000      % Approximate total faces after reduction
    options.MergeTolerance = 1e-4   % Distance for merging vertices
    options.VisibilityCheck = true  % Flip faces that are only seen from behind (step 4b)
    options.MaxVisibilityFaces = 30000  % Skip step 4b above this many faces
    options.FigNum = []             % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the vehicleMesh input
        requiredFields = {'Vertices','Faces','FacePartIndex','FaceWheelIndex','FaceColors','FaceAlpha'};
        if ~isstruct(vehicleMesh)
            error('vehicleMesh must be a CarMesh3D mesh structure');
        end
        for ith_field = 1:length(requiredFields)
            if ~isfield(vehicleMesh,requiredFields{ith_field})
                error('vehicleMesh is missing the field %s. Run fcn_CarMesh3D_labelParts first.',requiredFields{ith_field});
            end
        end

        % Check the TargetFaces input
        if ~isnumeric(options.TargetFaces) || ~isscalar(options.TargetFaces) || options.TargetFaces<4
            error('TargetFaces must be a number of 4 or more');
        end

        % Check the MergeTolerance input
        if ~isnumeric(options.MergeTolerance) || ~isscalar(options.MergeTolerance) || options.MergeTolerance<0
            error('MergeTolerance must be a non-negative number');
        end

        % Check the VisibilityCheck and MaxVisibilityFaces inputs
        if ~(islogical(options.VisibilityCheck) || isnumeric(options.VisibilityCheck)) || ~isscalar(options.VisibilityCheck)
            error('VisibilityCheck must be true or false');
        end
        if ~isnumeric(options.MaxVisibilityFaces) || ~isscalar(options.MaxVisibilityFaces) || options.MaxVisibilityFaces<0
            error('MaxVisibilityFaces must be a non-negative number');
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
originalMesh = vehicleMesh;
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
Nfaces = size(faces,1);

facePart  = vehicleMesh.FacePartIndex(:);
faceWheel = vehicleMesh.FaceWheelIndex(:);
faceColors = vehicleMesh.FaceColors;
faceAlpha = vehicleMesh.FaceAlpha(:);
faceMaterial = fcn_INTERNAL_fieldOrZeros(vehicleMesh,'FaceMaterialIndex',Nfaces);
faceGroup    = fcn_INTERNAL_fieldOrZeros(vehicleMesh,'FaceGroupIndex',Nfaces);
faceLightType = fcn_INTERNAL_fieldOrZeros(vehicleMesh,'FaceLightType',Nfaces);

% Group faces by part, wheel, light type, and color/alpha
[~,~,colorIndex] = unique(round([faceColors faceAlpha]*1e4)/1e4, 'rows');
[groupKeys,~,groupOfFace] = unique([facePart faceWheel faceLightType colorIndex], 'rows');
numGroups = size(groupKeys,1);

% Vehicle center, used to point open surfaces outward
minValues = min(vertices,[],1);
maxValues = max(vertices,[],1);
vehicleCenter = (minValues + maxValues)/2;

% Fraction of faces to keep
reductionRatio = min(1, options.TargetFaces/Nfaces);
minFacesToReduce = 50; % Groups with fewer faces are not reduced

% Process each group, collecting the results in cell arrays
groupVertices = cell(numGroups,1);
groupFaces = cell(numGroups,1);
groupFirstFace = zeros(numGroups,1);
for ith_group = 1:numGroups
    faceIndices = find(groupOfFace==ith_group);
    groupFirstFace(ith_group) = faceIndices(1);

    % Pull out this group's faces with their own vertex list
    theseFaces = faces(faceIndices,:);
    [usedVertices,~,newIndex] = unique(theseFaces(:));
    theseVertices = vertices(usedVertices,:);
    theseFaces = reshape(newIndex, size(theseFaces));

    % 1. Merge duplicate vertices
    if options.MergeTolerance>0
        [~, keepIndex, mapIndex] = uniquetol(theseVertices, options.MergeTolerance, 'ByRows', true, 'DataScale', 1);
        theseVertices = theseVertices(keepIndex,:);
        theseFaces = reshape(mapIndex(theseFaces), size(theseFaces));
    end

    % 2. Remove degenerate and duplicate faces
    theseFaces = fcn_INTERNAL_cleanFaces(theseVertices, theseFaces);
    if isempty(theseFaces)
        continue;
    end

    % 3. Reduce the face count
    % (Small groups, such as a window made of two triangles, are left
    % alone so that they keep their shape.)
    numTarget = max(4, round(reductionRatio*size(theseFaces,1)));
    if reductionRatio<1 && size(theseFaces,1)>max(numTarget, minFacesToReduce)
        [reducedFaces, reducedVertices] = reducepatch(theseFaces, theseVertices, numTarget);
        reducedFaces = fcn_INTERNAL_cleanFaces(reducedVertices, reducedFaces);
        if ~isempty(reducedFaces)
            theseFaces = reducedFaces;
            theseVertices = reducedVertices;
        end
    end

    groupVertices{ith_group} = theseVertices;
    groupFaces{ith_group} = theseFaces;
end

% Assemble the output mesh
newVertices = zeros(0,3);
newFaces = zeros(0,3);
newPart = zeros(0,1);
newWheel = zeros(0,1);
newColors = zeros(0,3);
newAlpha = zeros(0,1);
newMaterial = zeros(0,1);
newGroup = zeros(0,1);
newLightType = zeros(0,1);
for ith_group = 1:numGroups
    theseFaces = groupFaces{ith_group};
    if isempty(theseFaces)
        continue;
    end
    numThese = size(theseFaces,1);
    firstFace = groupFirstFace(ith_group);
    newFaces = [newFaces; theseFaces + size(newVertices,1)]; %#ok<AGROW>
    newVertices = [newVertices; groupVertices{ith_group}]; %#ok<AGROW>
    newPart = [newPart; repmat(facePart(firstFace), numThese, 1)]; %#ok<AGROW>
    newWheel = [newWheel; repmat(faceWheel(firstFace), numThese, 1)]; %#ok<AGROW>
    newColors = [newColors; repmat(faceColors(firstFace,:), numThese, 1)]; %#ok<AGROW>
    newAlpha = [newAlpha; repmat(faceAlpha(firstFace), numThese, 1)]; %#ok<AGROW>
    newMaterial = [newMaterial; repmat(faceMaterial(firstFace), numThese, 1)]; %#ok<AGROW>
    newGroup = [newGroup; repmat(faceGroup(firstFace), numThese, 1)]; %#ok<AGROW>
    newLightType = [newLightType; repmat(faceLightType(firstFace), numThese, 1)]; %#ok<AGROW>
end

% 4. Consistent winding, then outward normals. This is done per part and
% wheel (not per color group), so that a wheel made of tire and rim
% colors is checked as one closed object. Vertices are merged by position
% here only to find which faces touch; the mesh keeps its separate
% vertices so that edges between colors stay sharp.
[orientKeys,~,orientOfFace] = unique([newPart newWheel], 'rows');
for ith_key = 1:size(orientKeys,1)
    faceIndices = find(orientOfFace==ith_key);
    theseFaces = newFaces(faceIndices,:);
    [usedVertices,~,newIndex] = unique(theseFaces(:));
    theseVertices = newVertices(usedVertices,:);
    theseFaces = reshape(newIndex, size(theseFaces));
    if options.MergeTolerance>0
        [~, keepIndex, mapIndex] = uniquetol(theseVertices, options.MergeTolerance, 'ByRows', true, 'DataScale', 1);
        theseVertices = theseVertices(keepIndex,:);
        theseFaces = reshape(mapIndex(theseFaces), size(theseFaces));
    end
    flagFlip = fcn_INTERNAL_orientationFlips(theseVertices, theseFaces, vehicleCenter);
    flipIndices = faceIndices(flagFlip);
    newFaces(flipIndices,:) = newFaces(flipIndices,[1 3 2]);
end

% 4b. Visibility: flip faces that can only be seen from behind
visibilityFlips = NaN;
if options.VisibilityCheck
    if size(newFaces,1) <= options.MaxVisibilityFaces
        [escapeFront, escapeBack] = fcn_INTERNAL_rayEscapes(newVertices, newFaces, newAlpha < 0.999);
        flagSeenFromBehind = escapeBack & ~escapeFront;
        newFaces(flagSeenFromBehind,:) = newFaces(flagSeenFromBehind,[1 3 2]);
        visibilityFlips = sum(flagSeenFromBehind);
    else
        warning('fcn_CarMesh3D_simplifyMesh:visibilitySkipped', ...
            'The visibility check was skipped: %d faces is more than MaxVisibilityFaces (%d). Lower TargetFaces, or raise MaxVisibilityFaces (slower).', ...
            size(newFaces,1), options.MaxVisibilityFaces);
    end
end

% 5. Unit face normals
faceNormals = cross(...
    newVertices(newFaces(:,2),:) - newVertices(newFaces(:,1),:), ...
    newVertices(newFaces(:,3),:) - newVertices(newFaces(:,1),:), 2);
faceNormals = faceNormals ./ max(vecnorm(faceNormals,2,2), eps);

vehicleMesh.Vertices = newVertices;
vehicleMesh.Faces = newFaces;
vehicleMesh.FacePartIndex = newPart;
vehicleMesh.FaceWheelIndex = newWheel;
vehicleMesh.FaceColors = newColors;
vehicleMesh.FaceAlpha = newAlpha;
vehicleMesh.FaceMaterialIndex = newMaterial;
vehicleMesh.FaceGroupIndex = newGroup;
if isfield(vehicleMesh,'FaceLightType')
    vehicleMesh.FaceLightType = newLightType;
end
vehicleMesh.FaceNormals = faceNormals;
vehicleMesh.SimplifyInfo = struct(...
    'OriginalFaces', Nfaces,...
    'FinalFaces', size(newFaces,1),...
    'OriginalVertices', size(vertices,1),...
    'FinalVertices', size(newVertices,1),...
    'VisibilityFlips', visibilityFlips);

if flag_do_debug
    fprintf(1,'Simplified: %d -> %d faces, %d -> %d vertices, in %d groups\n',...
        Nfaces, size(newFaces,1), size(vertices,1), size(newVertices,1), numGroups);
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
    tiledlayout(1,3);

    nexttile;
    fcn_CarMesh3D_plotVehicle(originalMesh, ShowEdges=true, FigNum=figNum);
    title(sprintf('Before: %d faces', Nfaces));

    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
    title(sprintf('After: %d faces', size(newFaces,1)));

    % Normals check: short lines from each face center along its normal
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    hold on;
    faceCenters = (newVertices(newFaces(:,1),:) + newVertices(newFaces(:,2),:) + newVertices(newFaces(:,3),:))/3;
    normalLength = 0.1;
    quiver3(faceCenters(:,1),faceCenters(:,2),faceCenters(:,3),...
        normalLength*faceNormals(:,1),normalLength*faceNormals(:,2),normalLength*faceNormals(:,3),0,...
        'Color',[0.85 0.1 0.1],'DisplayName','Face normals');
    title('Face normals (should all point outward)');

    sgtitle(sprintf('Simplified: %s',vehicleMesh.Name),'Interpreter','none');
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

%% fcn_INTERNAL_fieldOrZeros
function values = fcn_INTERNAL_fieldOrZeros(thisStruct, fieldName, numRows)
% Returns the field as a column, or zeros if it is missing or empty
if isfield(thisStruct, fieldName) && ~isempty(thisStruct.(fieldName))
    values = thisStruct.(fieldName)(:);
else
    values = zeros(numRows,1);
end
end % Ends fcn_INTERNAL_fieldOrZeros

%% fcn_INTERNAL_cleanFaces
function faces = fcn_INTERNAL_cleanFaces(vertices, faces)
% Removes faces with repeated corners, faces with (nearly) zero area, and
% duplicate faces (the same three corners in any order)
if isempty(faces)
    return;
end
flagRepeated = faces(:,1)==faces(:,2) | faces(:,2)==faces(:,3) | faces(:,1)==faces(:,3);
faces = faces(~flagRepeated,:);
if isempty(faces)
    return;
end
crossProducts = cross(...
    vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
twiceArea = vecnorm(crossProducts,2,2);
faces = faces(twiceArea > 1e-12,:);
if isempty(faces)
    return;
end
[~, keepRows] = unique(sort(faces,2), 'rows', 'stable');
faces = faces(sort(keepRows),:);
end % Ends fcn_INTERNAL_cleanFaces

%% fcn_INTERNAL_rayEscapes
function [escapeFront, escapeBack] = fcn_INTERNAL_rayEscapes(vertices, faces, flagSeeThrough)
% For each face, whether a ray from its center along its normal
% (escapeFront) and against it (escapeBack) leaves the mesh without
% hitting another face. See-through faces do not block rays.
% Moller-Trumbore ray/triangle tests, one ray against all faces at a time.
Nfaces = size(faces,1);
vertex1 = vertices(faces(:,1),:);
edge1 = vertices(faces(:,2),:) - vertex1;
edge2 = vertices(faces(:,3),:) - vertex1;
normals = cross(edge1, edge2, 2);
normals = normals ./ max(vecnorm(normals,2,2), eps);
centers = vertex1 + (edge1 + edge2)/3;
blockers = find(~flagSeeThrough);
blockVertex1 = vertex1(blockers,:);
blockEdge1 = edge1(blockers,:);
blockEdge2 = edge2(blockers,:);
offset = 1e-4;   % Start each ray just off its own face
escapeFront = false(Nfaces,1);
escapeBack = false(Nfaces,1);
for ith_face = 1:Nfaces
    for direction = [1 -1]
        rayDirection = direction*normals(ith_face,:);
        rayOrigin = centers(ith_face,:) + offset*rayDirection;
        crossDirection = [rayDirection(2)*blockEdge2(:,3) - rayDirection(3)*blockEdge2(:,2), ...
                          rayDirection(3)*blockEdge2(:,1) - rayDirection(1)*blockEdge2(:,3), ...
                          rayDirection(1)*blockEdge2(:,2) - rayDirection(2)*blockEdge2(:,1)];
        determinant = sum(blockEdge1.*crossDirection, 2);
        inverse = 1./determinant;
        toOrigin = rayOrigin - blockVertex1;
        u = sum(toOrigin.*crossDirection, 2).*inverse;
        crossEdge = cross(toOrigin, blockEdge1, 2);
        v = (crossEdge*rayDirection').*inverse;
        distance = sum(blockEdge2.*crossEdge, 2).*inverse;
        flagHit = abs(determinant) > 1e-12 & u >= 0 & v >= 0 & (u + v) <= 1 & distance > 1e-6;
        flagHit(blockers==ith_face) = false;
        if direction==1
            escapeFront(ith_face) = ~any(flagHit);
        else
            escapeBack(ith_face) = ~any(flagHit);
        end
    end
end
end % Ends fcn_INTERNAL_rayEscapes

%% fcn_INTERNAL_orientationFlips
function flagFlipTotal = fcn_INTERNAL_orientationFlips(vertices, faces, vehicleCenter)
% Finds which faces to flip so that the winding is consistent across each
% connected surface (two faces that share an edge should traverse it in
% opposite directions), and so that each whole surface has its normals
% pointing outward. Returns a logical M x 1 vector (true = flip).
Nfaces = size(faces,1);

% Directed edges: rows 1..N are edge 1-2, N+1..2N are 2-3, 2N+1..3N are 3-1
directedEdges = [faces(:,[1 2]); faces(:,[2 3]); faces(:,[3 1])];
faceOfEdge = [(1:Nfaces)'; (1:Nfaces)'; (1:Nfaces)'];
[~,~,edgeId] = unique(sort(directedEdges,2), 'rows');
edgeCounts = accumarray(edgeId, 1);

% Pairs of faces that share a manifold edge (exactly two faces)
manifoldRows = find(edgeCounts(edgeId)==2);
[~, sortOrder] = sort(edgeId(manifoldRows));
pairedRows = manifoldRows(sortOrder);
rowsA = pairedRows(1:2:end);
rowsB = pairedRows(2:2:end);
faceA = faceOfEdge(rowsA);
faceB = faceOfEdge(rowsB);
% If both faces traverse the shared edge in the same direction, one of
% them must be flipped relative to the other
flagSameDirection = directedEdges(rowsA,1)==directedEdges(rowsB,1);
flagKeep = faceA~=faceB;
faceA = faceA(flagKeep);
faceB = faceB(flagKeep);
relationValue = double(flagSameDirection(flagKeep)) + 1; % 1 = consistent, 2 = flip
[uniquePairs, firstIndex] = unique([faceA faceB], 'rows');
relationValue = relationValue(firstIndex);
adjacency = sparse([uniquePairs(:,1); uniquePairs(:,2)], [uniquePairs(:,2); uniquePairs(:,1)], ...
    [relationValue; relationValue], Nfaces, Nfaces);

% Breadth-first search over faces, deciding a flip for each face
flagFlip = false(Nfaces,1);
flagVisited = false(Nfaces,1);
componentOfFace = zeros(Nfaces,1);
numComponents = 0;
for ith_seed = 1:Nfaces
    if flagVisited(ith_seed)
        continue;
    end
    numComponents = numComponents + 1;
    queue = zeros(Nfaces,1);
    queue(1) = ith_seed;
    queueEnd = 1;
    queueHead = 1;
    flagVisited(ith_seed) = true;
    componentOfFace(ith_seed) = numComponents;
    while queueHead <= queueEnd
        thisFace = queue(queueHead);
        queueHead = queueHead + 1;
        [neighborFaces, ~, neighborRelation] = find(adjacency(:,thisFace));
        for ith_neighbor = 1:length(neighborFaces)
            nextFace = neighborFaces(ith_neighbor);
            if ~flagVisited(nextFace)
                flagVisited(nextFace) = true;
                componentOfFace(nextFace) = numComponents;
                flagFlip(nextFace) = xor(flagFlip(thisFace), neighborRelation(ith_neighbor)==2);
                queueEnd = queueEnd + 1;
                queue(queueEnd) = nextFace;
            end
        end
    end
end
faces(flagFlip,:) = faces(flagFlip,[1 3 2]);
flagFlipTotal = flagFlip;

% Faces touching an edge that is not shared by exactly two faces are on
% a boundary (or a non-manifold edge): their surface is not closed
boundaryEdgeRows = edgeCounts(edgeId)~=2;
flagBoundaryFace = accumarray(faceOfEdge(boundaryEdgeRows), 1, [Nfaces 1]) > 0;

% Decide outward for each connected surface
vertex1 = vertices(faces(:,1),:);
vertex2 = vertices(faces(:,2),:);
vertex3 = vertices(faces(:,3),:);
faceNormals = cross(vertex2 - vertex1, vertex3 - vertex1, 2); % Length is twice the area
faceCenters = (vertex1 + vertex2 + vertex3)/3;
for ith_component = 1:numComponents
    flagThis = componentOfFace==ith_component;
    if ~any(flagBoundaryFace(flagThis))
        % Closed surface: positive signed volume means outward normals
        referencePoint = mean(faceCenters(flagThis,:),1);
        signedVolume = sum(dot(vertex1(flagThis,:) - referencePoint, ...
            cross(vertex2(flagThis,:) - referencePoint, vertex3(flagThis,:) - referencePoint, 2), 2))/6;
        flagOutward = signedVolume >= 0;
    else
        % Open surface: normals should point away from the vehicle center
        outwardScore = sum(dot(faceNormals(flagThis,:), faceCenters(flagThis,:) - vehicleCenter, 2));
        flagOutward = outwardScore >= 0;
    end
    if ~flagOutward
        flagFlipTotal(flagThis) = ~flagFlipTotal(flagThis);
    end
end
end % Ends fcn_INTERNAL_orientationFlips
