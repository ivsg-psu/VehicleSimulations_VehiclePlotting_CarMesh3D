function [vehicleMesh, info] = fcn_CarMesh3D_orientFaces(vehicleMesh, options)
% fcn_CarMesh3D_orientFaces

% Turns each face of a mesh to point the same way as its neighbors: a face
% whose normal points opposite to the faces around it (into the car where
% they point out) is flipped, by reversing the order of its corners. Only
% the faces' direction changes: every face keeps its place, its corners,
% its labels and its colors, so saved label edits (matched by face
% position) still apply.
%
% Why: a face pointing the wrong way is lit as if seen from behind, so it
% shows as a bright or dark sliver among its neighbors (the 2009 Fit's
% driver door handle: 28 such faces drawn as white slivers; Sean,
% 2026_11_26 02:20, Q86 (A)).
%
% How: faces are neighbors when they share an edge (corners within
% Tolerance of each other are taken as one). Two neighbors agree when they
% run along their shared edge in opposite directions. The faces are
% grouped into patches, each a connected set of faces that all agree.
% A patch is flipped when all of these hold:
%   - it is small (at most MaxPatchFaces faces);
%   - a neighboring patch it disagrees with is at least NeighborRatio
%     times its area;
%   - at least SmoothFraction of its disagreeing border becomes smooth
%     once flipped (the two faces' normals, before the flip, point nearly
%     opposite ways: their dot product is below SmoothDot).
% The defaults were chosen by Sean by eye on the 2009 Fit (2026_11_26
% 02:40 to 02:44), from linked views of the mesh colored by its normals:
% larger patches or looser size ratios changed nothing visible; loosening
% the smoothness test to SmoothDot -0.5 and SmoothFraction 0.3 removed
% more of the small errors, and looser still changed nothing; a Tolerance
% of 1 mm (instead of 0.01 mm) joined corners that are not shared and
% made it much worse.
%
% Then one sweep: each face's mean dot product with its edge neighbors'
% normals is found again, and the faces still below SweepCutoff are
% flipped (the border faces of backward patches the patch rule left).
% Sean chose this by eye on the 2009 Fit (03:12), with a 2x2 window of the
% mesh colored by normal and gray by mean dot product: after the patch
% rule, a cutoff of -0.5 caught almost everything, in one sweep. What
% remains are seams between panels, where meshes join at very thin
% curvature (ill-conditioned; they barely show in renders).
%
% Large patches are never flipped: whether a whole piece points into or
% out of the car is not decided here.
%
% FORMAT:
%
%       [vehicleMesh, info] = fcn_CarMesh3D_orientFaces(vehicleMesh,...
%           (Tolerance=distance), (MaxPatchFaces=count),...
%           (NeighborRatio=ratio), (SmoothDot=value),...
%           (SmoothFraction=fraction), (SweepCutoff=value),...
%           (NumSweeps=count), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh (Vertices, Faces; FaceNormals, if
%      present, are updated too).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tolerance: corners closer than this (in the mesh's units) are taken
%      as one place. Default 1e-5 (0.01 mm in meters).
%
%      MaxPatchFaces: the largest patch that may be flipped. Default 60.
%
%      NeighborRatio: how many times larger (in area) a disagreeing
%      neighbor patch must be. Default 2.
%
%      SmoothDot, SmoothFraction: a disagreeing border edge counts as
%      smooth once flipped when the two faces' normals have a dot product
%      below SmoothDot (default -0.5); at least SmoothFraction (default
%      0.3) of the patch's disagreeing border must be smooth.
%
%      SweepCutoff: after the patch rule, a face whose mean dot product
%      with its edge neighbors' normals is below this is flipped. Default
%      -0.5.
%
%      NumSweeps: how many such sweeps (each finds the mean dot products
%      again). Default 1; 0 for the patch rule alone.
%
%      FigNum: a figure to plot the mesh in, each face colored by its unit
%      normal (RGB = (n+1)/2), with the flipped faces outlined in black. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with the faces turned to agree.
%
%      info: a structure with
%           NumFlipped: the number of faces flipped
%           FlippedFaces: their indices
%           NumPatchesFlipped: the number of patches flipped
%           NumSweepFlipped: the faces the sweeps flipped (net)
%           NumPatches: the number of patches (sets of faces that agree)
%           NumOpenEdges: edges with one face only (holes and outlines)
%           NumCrowdedEdges: edges shared by three or more faces (not
%               used to compare faces)

% DEPENDENCIES:
%
%      fcn_CarMesh3D_addCadMouse (plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_orientFaces.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_orientFaces
%   % * First write (Q86 (A), Sean 02:25): the 2009 Fit's white slivers at
%   %   % the driver door handle were faces pointing opposite to their
%   %   % neighbors
%   %   % Then one sweep at mean dot -0.5 (Sean, 03:12)

% TO-DO:
%
% (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.Tolerance = 1e-5    % Corners closer than this are one place
    options.MaxPatchFaces = 60  % The largest patch that may be flipped
    options.NeighborRatio = 2   % A disagreeing neighbor patch at least this many times larger
    options.SmoothDot = -0.5    % A border edge is smooth once flipped when the normals' dot is below this
    options.SmoothFraction = 0.3 % ... on at least this fraction of the patch's disagreeing border
    options.SweepCutoff = -0.5  % Then flip faces whose mean dot with their neighbors is below this
    options.NumSweeps = 1       % ... this many times (0: the patch rule alone)
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
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
        % Check the vehicleMesh input
        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces'})))
            error('vehicleMesh must be a CarMesh3D mesh (Vertices, Faces)');
        end
        if size(vehicleMesh.Faces,2) ~= 3
            error('vehicleMesh.Faces must have three corners per face (triangles)');
        end
        % Check the Tolerance input
        for optionName = {'Tolerance', 'MaxPatchFaces', 'NeighborRatio', 'SmoothFraction'}
            value = options.(optionName{1});
            if ~isnumeric(value) || ~isscalar(value) || value <= 0
                error('%s must be a positive number', optionName{1});
            end
        end
        for optionName = {'SmoothDot', 'SweepCutoff'}
            value = options.(optionName{1});
            if ~isnumeric(value) || ~isscalar(value) || abs(value) > 1
                error('%s must be a number from -1 to 1', optionName{1});
            end
        end
        if ~isnumeric(options.NumSweeps) || ~isscalar(options.NumSweeps) || options.NumSweeps < 0 || options.NumSweeps ~= round(options.NumSweeps)
            error('NumSweeps must be a whole number, 0 or more');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed) && ~isempty(options.FigNum)
    figNum = options.FigNum;
    flag_do_plots = 1;
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

faces = double(vehicleMesh.Faces);
vertices = double(vehicleMesh.Vertices);
numFaces = size(faces,1);

% Corners at the same place are one corner (meshes often repeat a corner
% where two materials meet)
[~, ~, placeID] = unique(round(vertices/options.Tolerance), 'rows');
weldedFaces = placeID(faces);
if size(weldedFaces,2) ~= 3   % (a mesh of one face)
    weldedFaces = reshape(weldedFaces, [], 3);
end

% Each face's three edges, each as (from, to) in the face's own order
edgeFrom = [weldedFaces(:,1); weldedFaces(:,2); weldedFaces(:,3)];
edgeTo   = [weldedFaces(:,2); weldedFaces(:,3); weldedFaces(:,1)];
edgeFace = repmat((1:numFaces)', 3, 1);
flagDegenerate = edgeFrom == edgeTo;   % (a face squeezed to a line)
edgeFrom = edgeFrom(~flagDegenerate);
edgeTo = edgeTo(~flagDegenerate);
edgeFace = edgeFace(~flagDegenerate);

% Edges shared by exactly two faces join them. The pair agrees when the
% two faces run along the edge in opposite directions.
[~, ~, edgeID] = unique(sort([edgeFrom edgeTo], 2), 'rows');
edgeCount = accumarray(edgeID, 1);
flagPair = edgeCount(edgeID) == 2;
pairRows = find(flagPair);
[~, order] = sort(edgeID(pairRows));
pairRows = pairRows(order);
faceA = edgeFace(pairRows(1:2:end));
faceB = edgeFace(pairRows(2:2:end));
flagDisagree = edgeFrom(pairRows(1:2:end)) == edgeFrom(pairRows(2:2:end));   % (both run a->b)
flagSelf = faceA == faceB;
faceA = faceA(~flagSelf);
faceB = faceB(~flagSelf);
flagDisagree = flagDisagree(~flagSelf);

% Patches: faces joined by edges they agree on
patchOf = conncomp(graph(faceA(~flagDisagree), faceB(~flagDisagree), [], numFaces))';
numPatches = max([patchOf; 0]);

% Each face's area and normal
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
faceArea = vecnorm(normals, 2, 2)/2;
normals = normals./max(2*faceArea, eps);
patchArea = accumarray(patchOf, faceArea, [numPatches 1]);
patchSize = accumarray(patchOf, 1, [numPatches 1]);

% The borders between patches (the edges whose faces disagree)
borderA = faceA(flagDisagree);
borderB = faceB(flagDisagree);
patchA = patchOf(borderA);
patchB = patchOf(borderB);
flagSmooth = sum(normals(borderA,:).*normals(borderB,:), 2) < options.SmoothDot;
borderLength = accumarray([patchA; patchB], 1, [numPatches 1]);
smoothLength = accumarray([patchA; patchB], double([flagSmooth; flagSmooth]), [numPatches 1]);

% The largest neighbor patch across a smooth border
largestNeighbor = zeros(numPatches, 1);
smoothRows = find(flagSmooth);
largestNeighbor = max(largestNeighbor, accumarray(patchA(smoothRows), patchArea(patchB(smoothRows)), [numPatches 1], @max, 0));
largestNeighbor = max(largestNeighbor, accumarray(patchB(smoothRows), patchArea(patchA(smoothRows)), [numPatches 1], @max, 0));

flagFlipPatch = patchSize <= options.MaxPatchFaces ...
    & largestNeighbor > options.NeighborRatio*patchArea ...
    & smoothLength >= options.SmoothFraction*borderLength & borderLength > 0;
flagPatchFlip = flagFlipPatch(patchOf);
newFaces = faces;
newFaces(flagPatchFlip,:) = newFaces(flagPatchFlip,[1 3 2]);

% The sweeps: faces whose mean dot product with their neighbors (every
% face sharing an edge, three or more included) is below the cutoff
[sortedEdge, edgeOrder] = sort(edgeID);
sortedFace = edgeFace(edgeOrder);
flagSameEdge = sortedEdge(1:end-1) == sortedEdge(2:end);
neighborA = sortedFace([flagSameEdge; false]);
neighborB = sortedFace([false; flagSameEdge]);
flagSelfPair = neighborA == neighborB;
neighborA = neighborA(~flagSelfPair);
neighborB = neighborB(~flagSelfPair);
numNeighbors = accumarray([neighborA; neighborB], 1, [numFaces 1]);
for ith_sweep = 1:options.NumSweeps
    sweepNormals = cross(vertices(newFaces(:,2),:) - vertices(newFaces(:,1),:), ...
        vertices(newFaces(:,3),:) - vertices(newFaces(:,1),:), 2);
    sweepNormals = sweepNormals./max(vecnorm(sweepNormals, 2, 2), eps);
    pairDots = sum(sweepNormals(neighborA,:).*sweepNormals(neighborB,:), 2);
    meanDot = accumarray([neighborA; neighborB], [pairDots; pairDots], [numFaces 1])./max(numNeighbors, 1);
    flagSweep = numNeighbors > 0 & meanDot < options.SweepCutoff;
    if ~any(flagSweep)
        break;
    end
    newFaces(flagSweep,:) = newFaces(flagSweep,[1 3 2]);
end
flagFlip = any(newFaces ~= faces, 2);   % (net: flipped an odd number of times)
numSweepFlipped = nnz(xor(flagFlip, flagPatchFlip));

vehicleMesh.Faces(flagFlip,:) = vehicleMesh.Faces(flagFlip,[1 3 2]);
if isfield(vehicleMesh, 'FaceNormals') && size(vehicleMesh.FaceNormals,1) == numFaces
    vehicleMesh.FaceNormals(flagFlip,:) = -vehicleMesh.FaceNormals(flagFlip,:);
end

info = struct('NumFlipped', nnz(flagFlip), 'FlippedFaces', find(flagFlip), ...
    'NumPatchesFlipped', nnz(flagFlipPatch), 'NumSweepFlipped', numSweepFlipped, 'NumPatches', numPatches, ...
    'NumOpenEdges', nnz(edgeCount == 1), 'NumCrowdedEdges', nnz(edgeCount > 2));

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    newFaces = vehicleMesh.Faces;
    normals(flagFlip,:) = -normals(flagFlip,:);
    figure(figNum);
    clf;
    axesHandle = gca;
    patch(axesHandle, 'Faces', newFaces, 'Vertices', vertices, 'FaceVertexCData', (normals + 1)/2, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'none');
    if any(flagFlip)
        patch(axesHandle, 'Faces', newFaces(flagFlip,:), 'Vertices', vertices, 'FaceColor', 'none', ...
            'EdgeColor', 'k', 'LineWidth', 1);
    end
    axis(axesHandle, 'equal', 'off');
    view(axesHandle, 150, 20);
    fcn_CarMesh3D_addCadMouse(axesHandle);   % (left-drag turns, right-drag pans, the wheel zooms)
    title(axesHandle, {sprintf('Faces colored by their normal, RGB = (n+1)/2: %d face(s) flipped (outlined)', nnz(flagFlip)), ...
        'red = forward, green = left, blue = up'});
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
