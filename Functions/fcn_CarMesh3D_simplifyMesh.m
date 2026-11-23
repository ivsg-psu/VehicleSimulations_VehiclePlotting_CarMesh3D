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
%      Each wheel keeps at least WheelFaces faces (or all it has), so its
%      tire stays round; the rest of the budget is shared by the others.
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
% SYMMETRIC (Symmetric=true): vehicles are mirror images about their
% centerline (Y = 0 in the vehicle frame), but reducing a dense mesh
% treats the two sides differently, so they come out lopsided. With
% Symmetric=true only the left half is reduced: the faces with any corner
% at Y >= -0.15 m (15 cm past the centerline, since a reduction pulls in
% a piece's cut edge), to about half the face budget. It is then trimmed
% at the centerline (faces with any corner at Y > 0 kept, their corners
% at Y < 0 moved onto Y = 0, so no face crosses the centerline and
% overlaps its own mirror image), and it is to half the face budget, and then mirrored to make the right
% half: the result is exactly symmetric, and each side gets the whole
% budget's worth of detail. Wheels 1 (FL) and 3 (RL) are mirrored into 2
% (FR) and 4 (RR). Steps 4 and 4b then run on the whole vehicle.
%
% ONE-SIDED PIECES (KeepOneSided=true, the default, with Symmetric=true):
% a piece that is on one side only (the steering wheel, a fuel door, an
% offset exhaust tip or antenna) would come out on both sides, or, on the
% right, be lost. So before the half is cut, each connected piece that is
% off the centerline, has no wheel faces, and is under 1 m across is
% mirrored, and its corners are looked for on the other side: a corner
% has a match if some corner or face center of the mesh is within about
% 2 to 5 cm of it. A piece with fewer than half its corners matched is
% one-sided: it is taken out of the half, reduced by itself (its share of
% the budget), and added back where it is, not mirrored.
%
% Keeping groups separate also gives sharp edges between parts, which
% looks better with lighting.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh,...
%           (TargetFaces=numFaces), (WheelFaces=numFaces),...
%           (Symmetric=flag), (KeepOneSided=flag), (PartShares=shares),...
%           (MergeTolerance=tolerance), (ClearWheels=flag),...
%           (RestoreTolerance=meters), (EdgeSmoothing=passes),...
%           (StitchTolerance=meters),...
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
%      WheelFaces: the fewest faces each wheel keeps (tire and rim
%      together), so the tires stay round when a dense download is
%      reduced a lot; a wheel with fewer faces keeps all of them. Default
%      2000. Taken from TargetFaces before the other parts get their share;
%      the four wheels together take at most half of TargetFaces.
%
%      RestoreTolerance: meters. Each group (part and color) is reduced
%      on its own, and a reduced piece's open edges pull inward, leaving
%      gaps between pieces that touched, and holes where several meet
%      (wheel wells, bumpers, where the roof meets the door frames).
%      After the reduction each open-edge corner moves back onto the
%      nearest open edge its group had before the reduction, if within
%      this distance. Default 0 (off): on a door's edge, which wraps into
%      a flange, it can pull corners onto the flange. The count of corners
%      moved is SimplifyInfo.RestoreMoves.
%
%      EdgeSmoothing: passes of smoothing along each reduced piece's open
%      edges: a reduction leaves zigzag edges (a door's edge at the seam
%      between doors); each pass moves each open-edge corner halfway
%      toward the middle of its two neighbors along the edge. Corners
%      where the edge turns by more than 45 degrees stay put. Default 3;
%      0 turns it off.
%
%      StitchTolerance: meters. Then each open-edge corner of a piece (a
%      connected surface) moves onto the nearest open edge of a larger
%      piece within this distance (larger pieces stay put), closing what
%      gap is left. Wheels are left out of both steps. Default 0.02; 0
%      turns it off. The count of corners moved is
%      SimplifyInfo.StitchMoves.
%
%      ClearWheels: true (default) to delete faces of other parts that
%      pass through a tire. A heavy reduction can turn a wheel-arch liner
%      into a few large triangles that cut through the tire; such faces
%      are hidden behind the tire when the mesh is right, so deleting them
%      leaves no visible hole. Each tire is taken as a cylinder about the
%      Y axis (the vehicle frame: run this after the fit), from its
%      wheel's faces. The count is in SimplifyInfo.WheelClearFaces.
%
%      PartShares: an N x 2 cell array of {partName, fraction}: the
%      fraction of the budget (after the wheels) that a part gets, for
%      example {'body',0.6; 'trim',0.15} to give the painted body most of
%      the faces when a download has a dense hidden interior (labeled
%      trim). Parts not listed share what is left, in proportion to their
%      faces. Default {} (every part in proportion to its faces).
%
%      Symmetric: true to reduce the left half and mirror it (see
%      SYMMETRIC above); the mesh must be in the vehicle frame
%      (centerline at Y = 0, as after fcn_CarMesh3D_fitMeshToSpec).
%      Default false.
%
%      KeepOneSided: with Symmetric=true, true (default) to keep pieces
%      that are on one side only (see ONE-SIDED PIECES above) where they
%      are, instead of mirroring the left half's copy. Ignored when
%      Symmetric is false.
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
%               With Symmetric=true, also Symmetric (true),
%               OneSidedPieces and OneSidedFaces (the pieces kept on one
%               side, and their faces before the reduction), and
%               OneSidedBoxes (one row per piece: [xmin xmax ymin ymax
%               zmin zmax], to see which pieces they were).
%      FaceMaterialIndex and FaceGroupIndex are set to the values of the
%      first face of each group, since reduced faces no longer map to
%      single original faces.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%      reducepatch, uniquetol (MATLAB base); knnsearch (Statistics and
%      Machine Learning Toolbox) if installed, else dsearchn (base)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_simplifyMesh.m for a full test
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
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * WheelFaces (default 2000): each wheel keeps at least this many faces,
%   %   % so tires stay round when a dense download is reduced a lot
%   % * Symmetric (default false): reduce the left half, mirror it
%   % * PartShares: set fractions of the face budget by part
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * Symmetric: faces that crossed the centerline were kept and then
%   %   % mirrored, so each overlapped its mirror image (a dark strip
%   %   % down the roof of the 2010 Toyota Camry). Corners at Y < 0 of the
%   %   % kept half are now moved to Y = 0 (before and after the
%   %   % reduction), and faces lying in the Y = 0 plane are not mirrored a
%   %   % second time
%   % * RestoreTolerance (default 0, off): open edges of each reduced
%   %   % group can go back out to where they were before the reduction
%   % * EdgeSmoothing (default 3 passes): zigzag open edges left by the
%   %   % reduction are straightened along their line (the seam between
%   %   % the doors of the 2010 Toyota Camry)
%   % * StitchTolerance (default 0.02 m): open edges of each reduced
%   %   % piece close onto larger pieces nearby (gaps between panels and
%   %   % holes in wheel wells and bumpers, seen on the 2010 Toyota Camry,
%   %   % 2023 Honda Civic, and 2025 Volkswagen Golf)
%   % * Open surfaces are pointed outward by a vote of a few rays (step
%   %   % 4a2), not only by the vehicle center: a trunk lid with an inner
%   %   % skin was pointed inward on the 2017 Honda Accord. The count of
%   %   % surfaces flipped is SimplifyInfo.VoteFlips
%   % * ClearWheels (default true): faces of other parts that pass through
%   %   % a tire are deleted (large liner triangles cut through the tires
%   %   % of the 2025 Toyota Camry and 2017 Honda Accord)
%   % * Symmetric: the half is cut 15 cm past the centerline, reduced, and
%   %   % then trimmed at the centerline (a notch at the bottom center of
%   %   % the windshield of the 2010 Toyota Camry, from its cut edge)
%   % * Symmetric: open-edge corners within 2 cm of the centerline go onto
%   %   % it, so the two halves meet (a seam down the 2023 Honda Civic)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * Faces are grouped by material too, so each face keeps its own
%   %   % material name (they took their group's first face's material)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_simplifyMesh
%   % * KeepOneSided (default true): with Symmetric=true, pieces on one
%   %   % side only are kept where they are, not mirrored (the steering
%   %   % wheel of the 2009 Honda Fit came out on both sides; a piece on
%   %   % the right only was lost)

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
    options.WheelFaces = 2000       % Fewest faces each wheel keeps (round tires)
    options.Symmetric = false       % true: reduce the left half and mirror it
    options.KeepOneSided = true     % Symmetric: keep one-sided pieces where they are
    options.PartShares = {}         % {part, fraction; ...}: set shares of the budget
    options.MergeTolerance = 1e-4   % Distance for merging vertices
    options.ClearWheels = true      % Delete other faces that pass through a tire
    options.RestoreTolerance = 0    % meters: move reduced open edges back out this far, at most (0: off)
    options.EdgeSmoothing = 3       % passes smoothing reduced open edges along their line (0: off)
    options.StitchTolerance = 0.02  % meters: close gaps between pieces up to this wide (0: off)
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

        % Check the PartShares input
        if ~(iscell(options.PartShares) && (isempty(options.PartShares) || size(options.PartShares,2)==2))
            error('PartShares must be a cell array of {partName, fraction} rows');
        end

        % Check the Symmetric input
        if ~(islogical(options.Symmetric) || isnumeric(options.Symmetric)) || ~isscalar(options.Symmetric)
            error('Symmetric must be true or false');
        end

        % Check the KeepOneSided input
        if ~(islogical(options.KeepOneSided) || isnumeric(options.KeepOneSided)) || ~isscalar(options.KeepOneSided)
            error('KeepOneSided must be true or false');
        end

        % Check the RestoreTolerance input
        if ~isnumeric(options.RestoreTolerance) || ~isscalar(options.RestoreTolerance) || options.RestoreTolerance<0
            error('RestoreTolerance must be a distance of 0 or more');
        end

        % Check the EdgeSmoothing input
        if ~isnumeric(options.EdgeSmoothing) || ~isscalar(options.EdgeSmoothing) || options.EdgeSmoothing<0 || options.EdgeSmoothing~=round(options.EdgeSmoothing)
            error('EdgeSmoothing must be a whole number of passes, 0 or more');
        end

        % Check the StitchTolerance input
        if ~isnumeric(options.StitchTolerance) || ~isscalar(options.StitchTolerance) || options.StitchTolerance<0
            error('StitchTolerance must be a distance of 0 or more');
        end

        % Check the ClearWheels input
        if ~(islogical(options.ClearWheels) || isnumeric(options.ClearWheels)) || ~isscalar(options.ClearWheels)
            error('ClearWheels must be true or false');
        end

        % Check the WheelFaces input
        if ~isnumeric(options.WheelFaces) || ~isscalar(options.WheelFaces) || options.WheelFaces<0
            error('WheelFaces must be a number of 0 or more');
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
if options.Symmetric
    % Reduce the left half, mirror it, then finish the whole vehicle
    % (orientation, visibility, normals) with a second pass that does not
    % reduce
    vehicleMesh = fcn_INTERNAL_symmetric(vehicleMesh, options);
    if flag_do_plots
        figure(figNum);
        clf;
        fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
        title(sprintf('Symmetric: %d faces', size(vehicleMesh.Faces,1)));
    end
    return;
end
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

% Group faces by part, wheel, light type, color/alpha, and material (each
% rebuilt face takes its group's first face's values, so a group must not
% mix materials: without the material, the 2005 HiAce's grille, glass2,
% and chrome faces were renamed to the first material of their group)
[~,~,colorIndex] = unique(round([faceColors faceAlpha]*1e4)/1e4, 'rows');
[groupKeys,~,groupOfFace] = unique([facePart faceWheel faceLightType colorIndex faceMaterial], 'rows');
numGroups = size(groupKeys,1);

% Vehicle center, used to point open surfaces outward
minValues = min(vertices,[],1);
maxValues = max(vertices,[],1);
vehicleCenter = (minValues + maxValues)/2;

% Fraction of faces to keep: each wheel keeps at least WheelFaces; the
% other parts share the rest of the budget
wheelFaceCounts = accumarray(reshape(faceWheel(faceWheel>0),[],1), 1, [4 1]);
wheelFloor = min(options.WheelFaces, options.TargetFaces/8);                % (the four wheels take at most half the budget)
wheelRatio = min(1, max(options.TargetFaces/Nfaces, wheelFloor./max(wheelFaceCounts,1)));
wheelKept = sum(wheelRatio.*wheelFaceCounts);
otherFaces = sum(faceWheel==0);
otherBudget = max(options.TargetFaces - wheelKept, 0.2*options.TargetFaces);
reductionRatio = min(1, otherBudget/max(otherFaces,1));
% (PartShares: some parts get a set fraction of the rest of the budget;
% the parts not listed share what is left, in proportion to their faces)
partRatio = repmat(reductionRatio, max(facePart), 1);
if ~isempty(options.PartShares)
    partNames = vehicleMesh.PartNames;
    partCounts = accumarray(facePart(faceWheel==0), 1, [numel(partNames) 1]);
    listed = false(numel(partNames),1);
    usedBudget = 0;
    for ith_share = 1:size(options.PartShares,1)
        partIndex = find(strcmp(partNames, options.PartShares{ith_share,1}), 1);
        if isempty(partIndex) || partCounts(partIndex)==0
            continue;
        end
        partBudget = min(partCounts(partIndex), options.PartShares{ith_share,2}*otherBudget);
        partRatio(partIndex) = min(1, partBudget/partCounts(partIndex));
        listed(partIndex) = true;
        usedBudget = usedBudget + partBudget;
    end
    unlistedFaces = sum(partCounts(~listed));
    partRatio(~listed) = min(1, max(otherBudget - usedBudget, 0.05*otherBudget)/max(unlistedFaces,1));
end
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
    groupRatio = partRatio(groupKeys(ith_group,1));
    if groupKeys(ith_group,2) > 0
        groupRatio = wheelRatio(groupKeys(ith_group,2));             % (a wheel's own share)
    end
    numTarget = max(4, round(groupRatio*size(theseFaces,1)));
    if groupRatio<1 && size(theseFaces,1)>max(numTarget, minFacesToReduce)
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
newGroupOfFace = zeros(0,1);   % (which reduced group each face came from)
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
    newGroupOfFace = [newGroupOfFace; repmat(ith_group, numThese, 1)]; %#ok<AGROW>
end

% 3a. Restore and stitch: each group was reduced on its own, and a reduced
% piece's open edges pull inward, leaving gaps between pieces that touched
% (and holes where several meet). First each open-edge corner moves back
% onto the nearest open edge of its own group before the reduction
% (within RestoreTolerance). Then each open-edge corner of a piece moves onto
% the nearest open edge of a larger piece, when that edge is within
% StitchTolerance. Larger pieces stay put, smaller ones close onto them.
% Wheels are left out (a liner must not close onto a tire).
stitchMoves = 0;
restoreMoves = 0;
if options.RestoreTolerance > 0 && ~isempty(newFaces)
    % (first, each piece's open edges go back out to where that group's
    % open edges were before the reduction)
    [newVertices, restoreMoves] = fcn_INTERNAL_restoreEdges(newVertices, newFaces, newGroupOfFace, newWheel>0, ...
        vertices, faces, groupOfFace, options.RestoreTolerance);
end
if options.EdgeSmoothing > 0 && ~isempty(newFaces)
    % (zigzag open edges, left by the reduction, straightened along their
    % line; corners sharper than 45 degrees are kept)
    newVertices = fcn_INTERNAL_smoothEdges(newVertices, newFaces, newWheel>0, options.EdgeSmoothing);
end
if options.StitchTolerance > 0 && ~isempty(newFaces)
    [newVertices, stitchMoves] = fcn_INTERNAL_stitch(newVertices, newFaces, newGroupOfFace, newWheel>0, options.StitchTolerance);
end

% 3b. Faces of other parts that pass through a tire (large triangles left
% by a heavy reduction, cutting through it) are deleted. Each tire is a
% cylinder about Y, from its wheel's faces; a face is inside when any of
% ten points on it (corners, edge midpoints, center, and three more) is
% within 95% of the radius and 90% of the half-width
wheelClearFaces = 0;
if options.ClearWheels && any(newWheel>0)
    corner1 = newVertices(newFaces(:,1),:);
    corner2 = newVertices(newFaces(:,2),:);
    corner3 = newVertices(newFaces(:,3),:);
    samplePoints = [1 0 0; 0 1 0; 0 0 1; 0.5 0.5 0; 0 0.5 0.5; 0.5 0 0.5; ...
        1/3 1/3 1/3; 0.6 0.2 0.2; 0.2 0.6 0.2; 0.2 0.2 0.6];
    flagThroughTire = false(size(newFaces,1),1);
    for ith_wheel = reshape(unique(newWheel(newWheel>0)),1,[])
        wheelPoints = newVertices(unique(newFaces(newWheel==ith_wheel,:)),:);
        wheelLow = min(wheelPoints,[],1);
        wheelHigh = max(wheelPoints,[],1);
        wheelCenter = (wheelLow + wheelHigh)/2;
        wheelRadius = (wheelHigh(3) - wheelLow(3))/2;
        wheelHalfWidth = (wheelHigh(2) - wheelLow(2))/2;
        for ith_point = 1:size(samplePoints,1)
            thesePoints = samplePoints(ith_point,1)*corner1 + samplePoints(ith_point,2)*corner2 + samplePoints(ith_point,3)*corner3;
            flagThroughTire = flagThroughTire | ...
                (hypot(thesePoints(:,1)-wheelCenter(1), thesePoints(:,3)-wheelCenter(3)) < 0.95*wheelRadius & ...
                abs(thesePoints(:,2)-wheelCenter(2)) < 0.90*wheelHalfWidth);
        end
    end
    flagThroughTire = flagThroughTire & newWheel==0;
    wheelClearFaces = sum(flagThroughTire);
    if wheelClearFaces > 0
        keepRows = ~flagThroughTire;
        newFaces = newFaces(keepRows,:);
        newPart = newPart(keepRows);
        newWheel = newWheel(keepRows);
        newColors = newColors(keepRows,:);
        newAlpha = newAlpha(keepRows);
        newMaterial = newMaterial(keepRows);
        newGroup = newGroup(keepRows);
        newLightType = newLightType(keepRows);
        newGroupOfFace = newGroupOfFace(keepRows); %#ok<NASGU>
    end
end

% 4. Consistent winding, then outward normals. This is done per part and
% wheel (not per color group), so that a wheel made of tire and rim
% colors is checked as one closed object. Vertices are merged by position
% here only to find which faces touch; the mesh keeps its separate
% vertices so that edges between colors stay sharp.
[orientKeys,~,orientOfFace] = unique([newPart newWheel], 'rows');
surfaceOfFace = zeros(size(newFaces,1),1);   % (connected surface of each face, over all keys)
openSurfaces = false(0,1);                   % (true for a surface with an open edge)
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
    [flagFlip, componentOfFace, flagOpenComponent] = fcn_INTERNAL_orientationFlips(theseVertices, theseFaces, vehicleCenter);
    flipIndices = faceIndices(flagFlip);
    newFaces(flipIndices,:) = newFaces(flipIndices,[1 3 2]);
    surfaceOfFace(faceIndices) = componentOfFace + numel(openSurfaces);
    openSurfaces = [openSurfaces; flagOpenComponent(:)]; %#ok<AGROW>
end

% 4a2. Outward for open surfaces, by a vote of a few rays. An open surface
% (a panel with edges) was pointed away from the vehicle center above,
% which fails for a panel with an inner skin (a trunk lid: its two skins
% cancel). For each open surface of at least 0.002 square meters (20
% square centimeters: a door-pillar molding counts), its largest faces
% (3, plus one per 0.02 square meters, up to 32) cast a ray each way: a face seen from its front
% only votes outward, from its back only votes inward. The surface is
% flipped when the inward votes win. (Much faster than step 4b, which
% casts two rays from every face.)
voteFlips = 0;
if any(openSurfaces)
    corner1 = newVertices(newFaces(:,1),:);
    faceAreas = vecnorm(cross(newVertices(newFaces(:,2),:) - corner1, newVertices(newFaces(:,3),:) - corner1, 2), 2, 2)/2;
    surfaceAreas = accumarray(surfaceOfFace, faceAreas, [numel(openSurfaces) 1]);
    voteSurfaces = find(openSurfaces & surfaceAreas >= 0.002);
    numSamples = min(32, 3 + floor(surfaceAreas(voteSurfaces)/0.02));   % (3, plus one per 0.02 square meters, up to 32)
    sampleFaces = cell(numel(voteSurfaces),1);
    for ith_surface = 1:numel(voteSurfaces)
        theseFaces = find(surfaceOfFace==voteSurfaces(ith_surface));
        [~, sizeOrder] = sort(faceAreas(theseFaces), 'descend');
        sampleFaces{ith_surface} = theseFaces(sizeOrder(1:min(numSamples(ith_surface),numel(sizeOrder))));
    end
    allSamples = vertcat(sampleFaces{:});
    if ~isempty(allSamples)
        [escapeFront, escapeBack] = fcn_INTERNAL_rayEscapes(newVertices, newFaces, newAlpha < 0.999, allSamples);
        faceVote = zeros(size(newFaces,1),1);
        faceVote(allSamples) = double(escapeFront & ~escapeBack) - double(escapeBack & ~escapeFront);
        for ith_surface = 1:numel(voteSurfaces)
            if sum(faceVote(sampleFaces{ith_surface})) < 0
                flipRows = surfaceOfFace==voteSurfaces(ith_surface);
                newFaces(flipRows,:) = newFaces(flipRows,[1 3 2]);
                voteFlips = voteFlips + 1;
            end
        end
    end
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
    'VisibilityFlips', visibilityFlips,...
    'WheelClearFaces', wheelClearFaces,...
    'VoteFlips', voteFlips,...
    'RestoreMoves', restoreMoves,...
    'StitchMoves', stitchMoves);

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
function [escapeFront, escapeBack] = fcn_INTERNAL_rayEscapes(vertices, faces, flagSeeThrough, rayFaces)
% For each face (or only the faces listed in rayFaces), whether a ray
% from its center along its normal (escapeFront) and against it
% (escapeBack) leaves the mesh without hitting another face. See-through
% faces do not block rays. The outputs have one row per ray face.
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
if nargin < 4
    rayFaces = (1:Nfaces)';
end
escapeFront = false(numel(rayFaces),1);
escapeBack = false(numel(rayFaces),1);
for ith_ray = 1:numel(rayFaces)
    ith_face = rayFaces(ith_ray);
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
            escapeFront(ith_ray) = ~any(flagHit);
        else
            escapeBack(ith_ray) = ~any(flagHit);
        end
    end
end
end % Ends fcn_INTERNAL_rayEscapes

%% fcn_INTERNAL_orientationFlips
function [flagFlipTotal, componentOfFace, flagOpenComponent] = fcn_INTERNAL_orientationFlips(vertices, faces, vehicleCenter)
% Finds which faces to flip so that the winding is consistent across each
% connected surface (two faces that share an edge should traverse it in
% opposite directions), and so that each whole surface has its normals
% pointing outward. Returns a logical M x 1 vector (true = flip), the
% connected surface of each face, and which surfaces are open (have an
% edge not shared by two faces).
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
flagOpenComponent = false(numComponents,1);
for ith_component = 1:numComponents
    flagThis = componentOfFace==ith_component;
    flagOpenComponent(ith_component) = any(flagBoundaryFace(flagThis));
    if ~flagOpenComponent(ith_component)
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

%% fcn_INTERNAL_restoreEdges
function [newVertices, numMoved] = fcn_INTERNAL_restoreEdges(newVertices, newFaces, newGroupOfFace, flagWheelFace, ...
    vertices, faces, groupOfFace, tolerance)
% Moves each open-edge corner of the reduced mesh onto the nearest open
% edge that its group had before the reduction, within tolerance. The
% original open edges are found with corners merged by position (to
% 0.1 mm), so a download whose faces share no corners still has only its
% real edges open. Wheels are left out.
numMoved = 0;

% Open edges of each group before the reduction
[~,~,mergedIndex] = unique(round(vertices*1e4), 'rows');
mergedFaces = mergedIndex(faces);
mergedVertices = zeros(max(mergedIndex),3);
mergedVertices(mergedIndex,:) = vertices;
originalOpen = fcn_INTERNAL_openEdges(mergedFaces, groupOfFace);   % [corner1 corner2 group]

% Open edges and corners of each group after the reduction
reducedOpen = fcn_INTERNAL_openEdges(newFaces(~flagWheelFace,:), newGroupOfFace(~flagWheelFace));
if isempty(originalOpen) || isempty(reducedOpen)
    return;
end
cornerList = unique([reducedOpen(:,[1 3]); reducedOpen(:,[2 3])], 'rows');   % [corner group]

% The original open edges, sampled every tolerance/8
edgeStart = mergedVertices(originalOpen(:,1),:);
edgeVector = mergedVertices(originalOpen(:,2),:) - edgeStart;
edgeLength = vecnorm(edgeVector, 2, 2);
numSamples = max(2, ceil(edgeLength/(tolerance/8)) + 1);
sampleEdge = repelem((1:size(originalOpen,1))', numSamples);
sampleStep = cell2mat(arrayfun(@(n) linspace(0,1,n)', numSamples, 'UniformOutput', false));
samplePoints = edgeStart(sampleEdge,:) + sampleStep.*edgeVector(sampleEdge,:);
sampleGroup = originalOpen(sampleEdge,3);

newPositions = newVertices;
flagMoved = false(size(newVertices,1),1);
for ith_group = reshape(unique(cornerList(:,2)),1,[])
    theseCorners = cornerList(cornerList(:,2)==ith_group,1);
    targetIndex = find(sampleGroup==ith_group);
    if isempty(targetIndex)
        continue;
    end
    if exist('knnsearch','file')==2
        nearest = knnsearch(samplePoints(targetIndex,:), newVertices(theseCorners,:));
    else
        nearest = dsearchn(samplePoints(targetIndex,:), newVertices(theseCorners,:));
    end
    thisEdge = sampleEdge(targetIndex(nearest));
    along = sum((newVertices(theseCorners,:) - edgeStart(thisEdge,:)).*edgeVector(thisEdge,:), 2)./max(edgeLength(thisEdge).^2, eps);
    closestPoints = edgeStart(thisEdge,:) + min(max(along,0),1).*edgeVector(thisEdge,:);
    gapSize = vecnorm(closestPoints - newVertices(theseCorners,:), 2, 2);
    flagMove = gapSize <= tolerance & gapSize > 0;
    newPositions(theseCorners(flagMove),:) = closestPoints(flagMove,:);
    flagMoved(theseCorners(flagMove)) = true;
end
newVertices = newPositions;
numMoved = sum(flagMoved);
end % Ends fcn_INTERNAL_restoreEdges

%% fcn_INTERNAL_smoothEdges
function vertices = fcn_INTERNAL_smoothEdges(vertices, faces, flagWheelFace, numPasses)
% Straightens zigzag open edges: each pass moves each open-edge corner
% that has exactly two open-edge neighbors halfway toward their middle,
% unless the edge turns there by more than 45 degrees (a real corner).
% Wheels are left out.
theseFaces = faces(~flagWheelFace,:);
if isempty(theseFaces)
    return;
end
edgeRows = sort([theseFaces(:,[1 2]); theseFaces(:,[2 3]); theseFaces(:,[3 1])], 2);
[uniqueEdges, ~, edgeOfRow] = unique(edgeRows, 'rows');
openEdges = uniqueEdges(accumarray(edgeOfRow,1)==1, :);
openEdges = openEdges(openEdges(:,1)~=openEdges(:,2), :);
if isempty(openEdges)
    return;
end
% (each corner's open-edge neighbors; only corners with exactly two)
allEnds = [openEdges; openEdges(:,[2 1])];
allEnds = sortrows(allEnds);
[cornerIds, firstRow, cornerOfRow] = unique(allEnds(:,1));
neighborCount = accumarray(cornerOfRow, 1);
flagChain = neighborCount==2;
chainCorners = cornerIds(flagChain);
neighborA = allEnds(firstRow(flagChain), 2);
neighborB = allEnds(firstRow(flagChain)+1, 2);
for ith_pass = 1:numPasses
    here = vertices(chainCorners,:);
    toA = vertices(neighborA,:) - here;
    toB = vertices(neighborB,:) - here;
    % (the turn: 180 degrees between the two edges is straight)
    cosTurn = -sum(toA.*toB,2)./max(vecnorm(toA,2,2).*vecnorm(toB,2,2), eps);
    flagSmooth = cosTurn > cosd(45);
    middle = (vertices(neighborA,:) + vertices(neighborB,:))/2;
    vertices(chainCorners(flagSmooth),:) = here(flagSmooth,:) + 0.5*(middle(flagSmooth,:) - here(flagSmooth,:));
end
end % Ends fcn_INTERNAL_smoothEdges

%% fcn_INTERNAL_openEdges
function openEdges = fcn_INTERNAL_openEdges(faces, groupOfFace)
% The edges used by only one face of their group: [corner1 corner2 group]
edgeRows = [faces(:,[1 2]); faces(:,[2 3]); faces(:,[3 1])];
edgeGroups = [groupOfFace(:); groupOfFace(:); groupOfFace(:)];
[uniqueKeys, ~, keyOfRow] = unique([sort(edgeRows,2) edgeGroups], 'rows');
openEdges = uniqueKeys(accumarray(keyOfRow,1)==1, :);
openEdges = openEdges(openEdges(:,1)~=openEdges(:,2), :);
end % Ends fcn_INTERNAL_openEdges

%% fcn_INTERNAL_stitch
function [vertices, numMoved] = fcn_INTERNAL_stitch(vertices, faces, ~, flagWheelFace, tolerance)
% Moves each open-edge corner of a piece onto the nearest open edge of a
% larger piece within tolerance. A piece is a connected surface within a
% group (a hood and a fender of the same paint are two pieces); wheel
% faces neither move nor attract. Pieces are ranked by area. The open
% edges of the larger pieces are sampled every tolerance/4; a corner
% goes to the nearest sample's edge (the closest point on it).
numMoved = 0;
keepFaces = ~flagWheelFace;
theseFaces = faces(keepFaces,:);
if isempty(theseFaces)
    return;
end
% (pieces: connected surfaces, by shared corners; each group has its own
% corners, so a piece never spans two groups)
vertexGraph = graph([theseFaces(:,1); theseFaces(:,2); theseFaces(:,3)], ...
    [theseFaces(:,2); theseFaces(:,3); theseFaces(:,1)], [], size(vertices,1));
vertexPiece = conncomp(vertexGraph)';
thesePieces = vertexPiece(theseFaces(:,1));
corner1 = vertices(theseFaces(:,1),:);
faceAreas = vecnorm(cross(vertices(theseFaces(:,2),:) - corner1, vertices(theseFaces(:,3),:) - corner1, 2), 2, 2)/2;
pieceArea = accumarray(thesePieces, faceAreas, [max(vertexPiece) 1]);
[~, sizeOrder] = sort(pieceArea, 'descend');
pieceRank = zeros(size(pieceArea));
pieceRank(sizeOrder) = 1:numel(sizeOrder);

% Open edges of each piece (an edge used by one face of that piece)
edgeRows = [theseFaces(:,[1 2]); theseFaces(:,[2 3]); theseFaces(:,[3 1])];
edgePieces = [thesePieces; thesePieces; thesePieces];
edgeKeys = [sort(edgeRows,2) edgePieces];
[uniqueKeys, ~, keyOfRow] = unique(edgeKeys, 'rows');
openEdges = uniqueKeys(accumarray(keyOfRow,1)==1, :);   % [corner1 corner2 piece]
if isempty(openEdges)
    return;
end

% Samples along each open edge
edgeStart = vertices(openEdges(:,1),:);
edgeVector = vertices(openEdges(:,2),:) - edgeStart;
edgeLength = vecnorm(edgeVector, 2, 2);
numSamples = max(2, ceil(edgeLength/(tolerance/4)) + 1);
sampleEdge = repelem((1:size(openEdges,1))', numSamples);
sampleStep = cell2mat(arrayfun(@(n) linspace(0,1,n)', numSamples, 'UniformOutput', false));
samplePoints = edgeStart(sampleEdge,:) + sampleStep.*edgeVector(sampleEdge,:);
sampleRank = pieceRank(openEdges(sampleEdge,3));

% Each open corner, with its piece (a corner is in one piece only)
cornerList = [openEdges(:,[1 3]); openEdges(:,[2 3])];
cornerList = unique(cornerList, 'rows');
cornerRank = pieceRank(cornerList(:,2));
% The nearest sample on an open edge of a larger piece, for each corner
if exist('knnsearch','file')==2
    % (one search for all corners: the 40 nearest samples, then the
    % first that belongs to a larger piece)
    [neighborIndex, neighborDistance] = knnsearch(samplePoints, vertices(cornerList(:,1),:), 'K', min(40,size(samplePoints,1)));
    flagLarger = sampleRank(neighborIndex) < cornerRank & neighborDistance <= 1.5*tolerance;
    [flagFound, firstColumn] = max(flagLarger, [], 2);
    nearestSample = neighborIndex(sub2ind(size(neighborIndex), (1:size(neighborIndex,1))', firstColumn));
else
    % (without that toolbox: piece by piece, larger pieces first)
    flagFound = false(size(cornerList,1),1);
    nearestSample = ones(size(cornerList,1),1);
    for ith_rank = 2:max(cornerRank)
        flagThese = cornerRank==ith_rank;
        targetIndex = find(sampleRank < ith_rank);
        if ~any(flagThese) || isempty(targetIndex)
            continue;
        end
        nearestSample(flagThese) = targetIndex(dsearchn(samplePoints(targetIndex,:), vertices(cornerList(flagThese,1),:)));
        flagFound(flagThese) = true;
    end
end

% Each corner moves to the closest point on that sample's edge, if close
theseCorners = cornerList(:,1);
thisEdge = sampleEdge(nearestSample);
along = sum((vertices(theseCorners,:) - edgeStart(thisEdge,:)).*edgeVector(thisEdge,:), 2)./max(edgeLength(thisEdge).^2, eps);
closestPoints = edgeStart(thisEdge,:) + min(max(along,0),1).*edgeVector(thisEdge,:);
gapSize = vecnorm(closestPoints - vertices(theseCorners,:), 2, 2);
flagMove = flagFound & gapSize <= tolerance & gapSize > 0;
[~, firstOfCorner] = unique(theseCorners(flagMove), 'stable');   % (a corner moves once)
moveRows = find(flagMove);
moveRows = moveRows(firstOfCorner);
newPositions = vertices;
newPositions(theseCorners(moveRows),:) = closestPoints(moveRows,:);
flagMoved = false(size(vertices,1),1);
flagMoved(theseCorners(moveRows)) = true;
vertices = newPositions;
numMoved = sum(flagMoved);
end % Ends fcn_INTERNAL_stitch

%% fcn_INTERNAL_symmetric
function vehicleMesh = fcn_INTERNAL_symmetric(vehicleMesh, options)
% Reduces the left half (cut 15 cm past the centerline) to about half the
% budget, trims it at the centerline (corners at Y < 0, and open-edge
% corners within 2 cm of the centerline, go onto Y = 0), mirrors it
% across Y = 0, and finishes the whole mesh
Nfaces = size(vehicleMesh.Faces,1);
% Pieces on one side only (the steering wheel) are not mirrored: they are
% set aside, reduced by themselves, and added back where they are
if options.KeepOneSided
    [flagOneSided, numOneSided, oneSidedBoxes] = fcn_INTERNAL_oneSidedFaces(vehicleMesh);
else
    flagOneSided = false(Nfaces,1);
    numOneSided = 0;
    oneSidedBoxes = zeros(0,6);
end
sideTarget = 0;
if any(flagOneSided)
    sideTarget = min(nnz(flagOneSided), max(4*numOneSided, round(options.TargetFaces*nnz(flagOneSided)/Nfaces)));
end
% The half is cut 15 cm past the centerline, and reduced: a reduction
% pulls in a piece's cut edge (a windshield would get a notch at the
% centerline), so the cut is made where that does no harm
cutMargin = 0.15;
cornerY = reshape(vehicleMesh.Vertices(vehicleMesh.Faces(:),2), [], 3);
keepFaces = any(cornerY >= -cutMargin, 2) & ~flagOneSided;
halfMesh = fcn_INTERNAL_selectFaces(vehicleMesh, keepFaces, Nfaces);
halfMesh = fcn_CarMesh3D_simplifyMesh(halfMesh, TargetFaces=max(4,round((options.TargetFaces - sideTarget)/2*(1 + cutMargin))), ...
    WheelFaces=options.WheelFaces, PartShares=options.PartShares, MergeTolerance=options.MergeTolerance, ClearWheels=options.ClearWheels, RestoreTolerance=options.RestoreTolerance, EdgeSmoothing=options.EdgeSmoothing, StitchTolerance=options.StitchTolerance, VisibilityCheck=false, FigNum=-1);
halfInfo = halfMesh.SimplifyInfo;
% ...then trimmed at the centerline: faces with any corner at Y >= 0 are
% kept, and their corners at Y < 0 go onto Y = 0 (so the reduced surface
% is cut cleanly, with no holes, and no face crosses the centerline and
% overlaps its own mirror image)
cornerY = reshape(halfMesh.Vertices(halfMesh.Faces(:),2), [], 3);
keepHalf = any(cornerY > 0, 2);
halfMesh = fcn_INTERNAL_selectFaces(halfMesh, keepHalf, size(halfMesh.Faces,1));
halfMesh.Vertices(:,2) = max(halfMesh.Vertices(:,2), 0);
% The reduction can pull the cut's edge off the centerline, leaving a seam
% between the two halves: open-edge corners within 2 cm of it go onto it
halfEdges = sort([halfMesh.Faces(:,[1 2]); halfMesh.Faces(:,[2 3]); halfMesh.Faces(:,[3 1])], 2);
[uniqueEdges,~,edgeOfRow] = unique(halfEdges, 'rows');
openEdges = uniqueEdges(accumarray(edgeOfRow,1)==1,:);
openCorners = unique(openEdges(:));
snapCorners = openCorners(halfMesh.Vertices(openCorners,2) < 0.02);
halfMesh.Vertices(snapCorners,2) = 0;
halfFaces = size(halfMesh.Faces,1);

% The mirror image: Y negated, the corner order reversed (so normals
% still point outward), left wheels become right wheels
mirrored = halfMesh;
mirrored.Vertices = halfMesh.Vertices.*[1 -1 1];
mirrored.Faces = halfMesh.Faces(:,[1 3 2]);
if isfield(mirrored,'FaceWheelIndex')
    wheelSwap = [0 2 1 4 3];
    mirrored.FaceWheelIndex = reshape(wheelSwap(halfMesh.FaceWheelIndex(:) + 1), size(halfMesh.FaceWheelIndex));
end
% Faces lying in the Y = 0 plane are already whole: they are not mirrored
mirrorY = reshape(halfMesh.Vertices(halfMesh.Faces(:),2), [], 3);
keepMirror = any(mirrorY > 0, 2);
wholeMesh = halfMesh;
wholeMesh.Vertices = [halfMesh.Vertices; mirrored.Vertices];
wholeMesh.Faces = [halfMesh.Faces; mirrored.Faces(keepMirror,:) + size(halfMesh.Vertices,1)];
fieldNames = fieldnames(halfMesh);
for ith_field = 1:numel(fieldNames)
    thisField = fieldNames{ith_field};
    if any(strcmp(thisField, {'Vertices','Faces'})) || ~(isnumeric(halfMesh.(thisField)) || islogical(halfMesh.(thisField)))
        continue;
    end
    if size(halfMesh.(thisField),1)==halfFaces
        wholeMesh.(thisField) = [halfMesh.(thisField); mirrored.(thisField)(keepMirror,:)];
    end
end
% The one-sided pieces, reduced by themselves, go back where they were
if any(flagOneSided)
    sideMesh = fcn_INTERNAL_selectFaces(vehicleMesh, flagOneSided, Nfaces);
    sideMesh = fcn_CarMesh3D_simplifyMesh(sideMesh, TargetFaces=max(4,sideTarget), ...
        WheelFaces=0, MergeTolerance=options.MergeTolerance, ClearWheels=false, RestoreTolerance=options.RestoreTolerance, EdgeSmoothing=options.EdgeSmoothing, StitchTolerance=0, VisibilityCheck=false, FigNum=-1);
    wholeFaces = size(wholeMesh.Faces,1);
    sideFaces = size(sideMesh.Faces,1);
    fieldNames = fieldnames(wholeMesh);
    for ith_field = 1:numel(fieldNames)
        thisField = fieldNames{ith_field};
        if any(strcmp(thisField, {'Vertices','Faces'})) || ~(isnumeric(wholeMesh.(thisField)) || islogical(wholeMesh.(thisField))) ...
                || size(wholeMesh.(thisField),1)~=wholeFaces
            continue;
        end
        if isfield(sideMesh,thisField) && size(sideMesh.(thisField),1)==sideFaces && size(sideMesh.(thisField),2)==size(wholeMesh.(thisField),2)
            wholeMesh.(thisField) = [wholeMesh.(thisField); sideMesh.(thisField)];
        else
            padRows = wholeMesh.(thisField)(ones(sideFaces,1),:);
            padRows(:) = 0;
            wholeMesh.(thisField) = [wholeMesh.(thisField); padRows];
        end
    end
    wholeMesh.Faces = [wholeMesh.Faces; sideMesh.Faces + size(wholeMesh.Vertices,1)];
    wholeMesh.Vertices = [wholeMesh.Vertices; sideMesh.Vertices];
end
if isfield(wholeMesh,'SimplifyInfo')
    wholeMesh = rmfield(wholeMesh,'SimplifyInfo');
end

% (no reduction: orientation, visibility, and normals of the whole)
vehicleMesh = fcn_CarMesh3D_simplifyMesh(wholeMesh, TargetFaces=size(wholeMesh.Faces,1)+1, ...
    WheelFaces=0, MergeTolerance=options.MergeTolerance, ClearWheels=options.ClearWheels, RestoreTolerance=0, EdgeSmoothing=0, StitchTolerance=options.StitchTolerance, VisibilityCheck=options.VisibilityCheck, ...
    MaxVisibilityFaces=options.MaxVisibilityFaces, FigNum=-1);
vehicleMesh.SimplifyInfo.OriginalFaces = Nfaces;
vehicleMesh.SimplifyInfo.Symmetric = true;
vehicleMesh.SimplifyInfo.OneSidedPieces = numOneSided;
vehicleMesh.SimplifyInfo.OneSidedFaces = nnz(flagOneSided);
vehicleMesh.SimplifyInfo.OneSidedBoxes = oneSidedBoxes;
% (the counts of the half's steps, for both halves)
vehicleMesh.SimplifyInfo.WheelClearFaces = vehicleMesh.SimplifyInfo.WheelClearFaces + 2*halfInfo.WheelClearFaces;
vehicleMesh.SimplifyInfo.RestoreMoves = 2*halfInfo.RestoreMoves;
vehicleMesh.SimplifyInfo.StitchMoves = vehicleMesh.SimplifyInfo.StitchMoves + 2*halfInfo.StitchMoves;
end % Ends fcn_INTERNAL_symmetric

%% fcn_INTERNAL_oneSidedFaces
function [flagOneSided, numOneSided, oneSidedBoxes] = fcn_INTERNAL_oneSidedFaces(vehicleMesh)
% Faces of pieces that are on one side only: connected pieces (corners at
% the same place count as shared) that are off the centerline, have no
% wheel faces, and are under maxSize across, whose mirrored corners
% mostly find no corner or face center of the mesh nearby
cellSize = 0.015;      % m: a match is within 1 to 3.5 cells (about 2 to 5 cm)
maxSize = 1.0;         % m: larger pieces are body panels, assumed paired
matchFraction = 0.5;   % pieces with fewer corners matched are one-sided
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
Nfaces = size(faces,1);
flagOneSided = false(Nfaces,1);
numOneSided = 0;
oneSidedBoxes = zeros(0,6);
if Nfaces==0
    return;
end
% Pieces, by corners at the same place
[~, firstVertex, vertexKey] = unique(round(vertices/1e-5), 'rows');
vertexKey = vertexKey(:);
keyFaces = vertexKey(faces);
if size(keyFaces,2)~=3
    keyFaces = reshape(keyFaces, [], 3);
end
Nkeys = numel(firstVertex);
pieceGraph = graph([keyFaces(:,1); keyFaces(:,2); keyFaces(:,3)], ...
    [keyFaces(:,2); keyFaces(:,3); keyFaces(:,1)], [], Nkeys);
keyPiece = conncomp(pieceGraph)';
facePiece = keyPiece(keyFaces(:,1));
Npieces = max(keyPiece);
keyPoints = vertices(firstVertex,:);
% Candidates: off the centerline, no wheel faces, small
pieceMin = zeros(Npieces,3); pieceMax = zeros(Npieces,3);
for ith_axis = 1:3
    pieceMin(:,ith_axis) = accumarray(keyPiece, keyPoints(:,ith_axis), [Npieces 1], @min);
    pieceMax(:,ith_axis) = accumarray(keyPiece, keyPoints(:,ith_axis), [Npieces 1], @max);
end
if isfield(vehicleMesh,'FaceWheelIndex')
    pieceWheel = accumarray(facePiece, double(vehicleMesh.FaceWheelIndex(:)>0), [Npieces 1], @max);
else
    pieceWheel = zeros(Npieces,1);
end
offCenter = pieceMin(:,2) > cellSize | pieceMax(:,2) < -cellSize;
pieceSize = vecnorm(pieceMax - pieceMin, 2, 2);
candidate = offCenter & pieceWheel==0 & pieceSize < maxSize;
if ~any(candidate)
    return;
end
% Every corner and face center of the mesh, by grid cell
faceCenters = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
targetCells = floor([keyPoints; faceCenters]/cellSize);
queryKeys = find(candidate(keyPiece));
queryCells = floor((keyPoints(queryKeys,:).*[1 -1 1])/cellSize);
cellLow = min([targetCells; queryCells],[],1) - 1;
cellSpan = max([targetCells; queryCells],[],1) - cellLow + 2;
cellCode = @(c) ((c(:,1) - cellLow(1))*cellSpan(2) + (c(:,2) - cellLow(2)))*cellSpan(3) + (c(:,3) - cellLow(3));
targetCodes = unique(cellCode(targetCells));
matched = false(numel(queryKeys),1);
[dx, dy, dz] = ndgrid(-1:1, -1:1, -1:1);
offsets = [dx(:) dy(:) dz(:)];
for ith_offset = 1:size(offsets,1)
    unmatched = ~matched;
    matched(unmatched) = ismember(cellCode(queryCells(unmatched,:) + offsets(ith_offset,:)), targetCodes);
end
% Pieces with too few corners matched are one-sided
queryPiece = keyPiece(queryKeys);
pieceMatched = accumarray(queryPiece, double(matched), [Npieces 1]);
pieceCorners = accumarray(queryPiece, 1, [Npieces 1]);
oneSided = candidate & pieceMatched < matchFraction*max(pieceCorners,1);
numOneSided = nnz(oneSided);
flagOneSided = oneSided(facePiece);
oneSidedBoxes = [pieceMin(oneSided,1) pieceMax(oneSided,1) pieceMin(oneSided,2) pieceMax(oneSided,2) pieceMin(oneSided,3) pieceMax(oneSided,3)];
end % Ends fcn_INTERNAL_oneSidedFaces

%% fcn_INTERNAL_selectFaces
function subMesh = fcn_INTERNAL_selectFaces(vehicleMesh, keepFaces, Nfaces)
% The mesh with only some faces (every per-face field cut the same way)
subMesh = vehicleMesh;
fieldNames = fieldnames(vehicleMesh);
for ith_field = 1:numel(fieldNames)
    thisValue = vehicleMesh.(fieldNames{ith_field});
    if ~strcmp(fieldNames{ith_field},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==Nfaces
        subMesh.(fieldNames{ith_field}) = thisValue(keepFaces,:);
    end
end
end % Ends fcn_INTERNAL_selectFaces
