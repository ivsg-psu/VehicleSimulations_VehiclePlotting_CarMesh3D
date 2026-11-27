function vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, options)
% fcn_CarMesh3D_findLampCovers
% Finds the clear glass covers that lie over a vehicle's lamps, and makes
% each one clear glass that is a "cover" of the lamp behind it.
%
% Many models have a clear plastic or glass cover in front of each lamp,
% with the real bulb or reflector visible under it (the 2009 Honda Fit's
% headlights and tail lights). Such a cover is drawn as clear glass:
% about 15% opaque and untinted, so the lamp shows through it. It no
% longer glows as a lamp itself; instead fcn_CarMesh3D_plotVehicle tints
% it with the lit color of the lamp it covers while that lamp is on (the
% whole glass area over a lit bulb seems to glow; Sean, 15:23).
%
% How a cover is found: from each glass face (and each light face that is
% also glass, LabelFaceAlsoParts, the way fcn_CarMesh3D_labelParts marked
% lamp covers before), the function looks straight in from the face, on
% the side away from the outside, for a lamp face (a light face with a
% light type) within Distance, including a lamp lying right in the
% glass's plane. Which side is outside comes from
% fcn_CarMesh3D_outwardSides, not from the face's direction, which cannot
% be trusted at this step (downloads often have glass facing the wrong
% way, and the direction fixes come after labeling; Sean, 2026-11-27).
% Where the outside could not be told, a face that finds no lamp on the
% side it was given also looks on its other side. Four lines are tried per side
% of a face: from its center, and from halfway between its center and
% each corner. The nearest lamp face hit is the lamp the face covers.
% Then, within each connected piece of glass (faces that share corners):
%       - a light face that is also glass is a cover when any face of its
%         piece found a lamp behind it (the cover's edges often lie over
%         the lamp's housing, not the lamp itself), and
%       - a plain glass face is a cover when at least half of its piece's
%         faces found a lamp behind them.
% Such faces take the lamp of the nearest face of their piece that found
% one. A window is never over a lamp, so windows stay as they are.
%
% Each cover is recorded in a new per-face field, LabelFaceCoverLamp (the
% covered lamp's light type, an index into LabelLampNames; 0 for faces
% that are not covers), and becomes plain glass: LabelFacePart 'glass',
% LabelFaceLamp 0, not also glass in LabelFaceAlsoParts, no light functions
% (LabelFaceAlsoLamps), and the clear look (ClearColor, ClearAlpha).
% The side of a cover (left or right, which matters for turn signals)
% comes from its position, as for the lamps.
%
% Running the function again gives the same result: a face that is
% already a cover stays one (unless it is no longer glass).
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh,...
%           (Distance=distance),...
%           (ClearAlpha=alpha),...
%           (ClearColor=[r g b]),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh structure (from
%      fcn_CarMesh3D_labelParts), in meters. A mesh that is not labeled
%      (no LabelPartNames, LabelFacePart, LabelFaceLamp, or LabelLampNames)
%      gets LabelFaceCoverLamp of all zeros and is not otherwise changed.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Distance: how far behind a glass face to look for a lamp, in
%      meters. Default is 0.05 (5 cm).
%
%      ClearAlpha: the transparency of a cover, from 0 (invisible) to 1
%      (opaque). Default is 0.15.
%
%      ClearColor: the color of a cover, a 1 x 3 RGB vector (values from
%      0 to 1). Default is [0.90 0.90 0.90], an untinted light gray.
%
%      FigNum: a figure number to plot the lamps and their covers. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with the covers made clear glass,
%      and the field
%           LabelFaceCoverLamp (M x 1): for each face, the light type (index
%               into LabelLampNames) of the lamp it covers, or 0 if the
%               face is not a lamp cover
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_outwardSides
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_findLampCovers.m for a
%       full test suite.
%
% This function was written on 2026_11_23 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findLampCovers
%   % * Wrote the code originally (drafted with Claude). Clear lamp covers
%   %   % (Sean, 09:22, option A): a glass cover over a lamp is clear
%   %   % glass, recorded as a cover of that lamp (LabelFaceCoverLamp), and is
%   %   % tinted by fcn_CarMesh3D_plotVehicle while its lamp is lit
%   %   % (Sean, 15:23, option A)

% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findLampCovers
%   % * Works whatever way faces point (step 1A of the plan of
%   %   % 2026-11-27): the lamp is looked for on the inner side of each
%   %   % glass face as fcn_CarMesh3D_outwardSides tells it (both sides
%   %   % where it cannot tell), stored FaceNormals are no longer
%   %   % trusted for this, and glass lying right on its lamp (zero
%   %   % distance) is found. Before, flipped glass, the inner skin of
%   %   % thick glass, and coincident glass were missed
%   %   % (script_test_fcn_CarMesh3D_glassOverLamps)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findLampCovers
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.Distance = 0.05             % How far behind a glass face to look for a lamp [m]
    options.ClearAlpha = 0.15           % Transparency of a cover (0 clear, 1 opaque)
    options.ClearColor = [0.90 0.90 0.90] % Color of a cover (untinted)
    options.FigNum = []                 % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces')
            error('vehicleMesh must be a CarMesh3D mesh structure with Vertices and Faces fields');
        end
        if size(vehicleMesh.Vertices,2)~=3 || size(vehicleMesh.Faces,2)~=3
            error('vehicleMesh.Vertices must be N x 3 and vehicleMesh.Faces must be M x 3');
        end

        % Check the Distance input
        if ~isnumeric(options.Distance) || ~isscalar(options.Distance) || ~isfinite(options.Distance) || options.Distance<=0
            error('Distance must be a positive number, in meters');
        end

        % Check the ClearAlpha input
        if ~isnumeric(options.ClearAlpha) || ~isscalar(options.ClearAlpha) || options.ClearAlpha<0 || options.ClearAlpha>1
            error('ClearAlpha must be a number from 0 to 1');
        end

        % Check the ClearColor input
        if ~isnumeric(options.ClearColor) || ~isequal(size(options.ClearColor),[1 3]) || any(options.ClearColor<0) || any(options.ClearColor>1)
            error('ClearColor must be a 1 x 3 RGB vector with values from 0 to 1');
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
Nfaces = size(vehicleMesh.Faces,1);
labelFaceCoverLamp = zeros(Nfaces,1);

% A mesh that is not labeled has no lamps and no glass: no covers
flagLabeled = isfield(vehicleMesh,'LabelPartNames') && isfield(vehicleMesh,'LabelFacePart') ...
    && isfield(vehicleMesh,'LabelFaceLamp') && isfield(vehicleMesh,'LabelLampNames') ...
    && numel(vehicleMesh.LabelFacePart)==Nfaces && numel(vehicleMesh.LabelFaceLamp)==Nfaces;
glassIndex = [];
lightIndex = [];
if flagLabeled
    glassIndex = find(strcmp(vehicleMesh.LabelPartNames, 'glass'), 1);
    lightIndex = find(strcmp(vehicleMesh.LabelPartNames, 'light'), 1);
end

if ~isempty(glassIndex) && ~isempty(lightIndex) && Nfaces > 0
    facePart = vehicleMesh.LabelFacePart(:);
    labelFaceLamp = double(vehicleMesh.LabelFaceLamp(:));

    % Faces left alone: hidden faces (kept as they are) and wheels
    flagSkip = false(Nfaces,1);
    if isfield(vehicleMesh,'LabelFaceHiddenSet') && numel(vehicleMesh.LabelFaceHiddenSet)==Nfaces
        flagSkip = flagSkip | vehicleMesh.LabelFaceHiddenSet(:) > 0;
    end
    if isfield(vehicleMesh,'FaceWheelIndex') && numel(vehicleMesh.FaceWheelIndex)==Nfaces
        flagSkip = flagSkip | vehicleMesh.FaceWheelIndex(:) > 0;
    end

    % Light faces that are also glass (lamp covers, as marked before this
    % function existed)
    flagAlsoGlass = false(Nfaces,1);
    if isfield(vehicleMesh,'LabelFaceAlsoParts') && size(vehicleMesh.LabelFaceAlsoParts,1)==Nfaces ...
            && glassIndex <= size(vehicleMesh.LabelFaceAlsoParts,2)
        flagAlsoGlass = vehicleMesh.LabelFaceAlsoParts(:,glassIndex) & facePart==lightIndex;
    end

    % The faces that may be covers, and the lamps they may cover
    flagGlass = facePart==glassIndex;
    flagCandidate = (flagGlass | flagAlsoGlass) & ~flagSkip;
    flagLamp = facePart==lightIndex & labelFaceLamp>0 & ~flagAlsoGlass & ~flagSkip;

    % Faces that were already covers (from an earlier call) and are still glass
    oldCover = zeros(Nfaces,1);
    if isfield(vehicleMesh,'LabelFaceCoverLamp') && numel(vehicleMesh.LabelFaceCoverLamp)==Nfaces
        oldCover = double(vehicleMesh.LabelFaceCoverLamp(:));
        oldCover(~flagGlass | flagSkip | oldCover > numel(vehicleMesh.LabelLampNames)) = 0;
    end

    if any(flagCandidate) && any(flagLamp)
        candidateFaces = find(flagCandidate);
        lampFaces = find(flagLamp);

        % Look in from each candidate face (away from the outside) for the
        % nearest lamp face; faces whose outside could not be told, and that
        % find none, also look the other way (the face's direction is not
        % used: step 1A of the plan of 2026-11-27)
        faceNormals = fcn_INTERNAL_faceNormals(vehicleMesh);
        [outwardSign, sidesInfo] = fcn_CarMesh3D_outwardSides(vehicleMesh, FaceList=candidateFaces, FigNum=-1);
        inwardDirections = -faceNormals(candidateFaces,:).*outwardSign;
        hitLamp = fcn_INTERNAL_lampBehind(vehicleMesh, candidateFaces, lampFaces, inwardDirections, ...
            options.Distance);
        flagNone = hitLamp == 0 & sidesInfo.Rule ~= 1;
        if any(flagNone)
            hitLamp(flagNone) = fcn_INTERNAL_lampBehind(vehicleMesh, candidateFaces(flagNone), lampFaces, ...
                -inwardDirections(flagNone,:), options.Distance);
        end
        hitType = zeros(numel(candidateFaces),1);
        hitType(hitLamp>0) = labelFaceLamp(lampFaces(hitLamp(hitLamp>0)));

        % Spread the covers over each connected piece of glass
        newCover = fcn_INTERNAL_spreadOverPieces(vehicleMesh, candidateFaces, hitType, ...
            flagAlsoGlass(candidateFaces), oldCover(candidateFaces));
        labelFaceCoverLamp(candidateFaces) = newCover;
    else
        labelFaceCoverLamp = oldCover;
    end

    % Each cover becomes clear glass, and no longer a lamp
    flagCover = labelFaceCoverLamp > 0;
    if any(flagCover)
        vehicleMesh.LabelFacePart(flagCover) = glassIndex;
        vehicleMesh.LabelFaceLamp(flagCover) = 0;
        if isfield(vehicleMesh,'LabelFaceAlsoParts') && size(vehicleMesh.LabelFaceAlsoParts,1)==Nfaces ...
                && glassIndex <= size(vehicleMesh.LabelFaceAlsoParts,2)
            vehicleMesh.LabelFaceAlsoParts(flagCover, glassIndex) = false;
        end
        if isfield(vehicleMesh,'LabelFaceAlsoLamps') && size(vehicleMesh.LabelFaceAlsoLamps,1)==Nfaces
            vehicleMesh.LabelFaceAlsoLamps(flagCover,:) = false;
        end
        if isfield(vehicleMesh,'FaceColors') && size(vehicleMesh.FaceColors,1)==Nfaces
            vehicleMesh.FaceColors(flagCover,:) = repmat(options.ClearColor, nnz(flagCover), 1);
        end
        if isfield(vehicleMesh,'FaceAlpha') && numel(vehicleMesh.FaceAlpha)==Nfaces
            vehicleMesh.FaceAlpha(flagCover) = options.ClearAlpha;
        end
    end
end

vehicleMesh.LabelFaceCoverLamp = labelFaceCoverLamp;

if flag_do_debug && isfield(vehicleMesh,'LabelLampNames')
    for ith_type = 1:numel(vehicleMesh.LabelLampNames)
        fprintf(1,'\tcovers of %s lamps: %d faces\n', vehicleMesh.LabelLampNames{ith_type}, nnz(labelFaceCoverLamp==ith_type));
    end
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
    tiledlayout(1,2);

    % Left: the vehicle as fcn_CarMesh3D_plotVehicle draws it, low beams on
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Signals=struct('LowBeam',true,'Tail',true), FigNum=figNum);
    title('Drawn, low beams and tail lights on');

    % Right: lamps in yellow, covers in cyan, everything else faint gray
    axesHandle = nexttile;
    hold(axesHandle,'on');
    flagCover = labelFaceCoverLamp > 0;
    flagLampFace = false(Nfaces,1);
    if isfield(vehicleMesh,'LabelFaceLamp')
        flagLampFace = vehicleMesh.LabelFaceLamp(:) > 0;
    end
    flagOther = ~flagCover & ~flagLampFace;
    patch(axesHandle,'Faces',vehicleMesh.Faces(flagOther,:),'Vertices',vehicleMesh.Vertices, ...
        'FaceColor',[0.75 0.75 0.75],'FaceAlpha',0.15,'EdgeColor','none','DisplayName','other faces');
    if any(flagLampFace)
        patch(axesHandle,'Faces',vehicleMesh.Faces(flagLampFace,:),'Vertices',vehicleMesh.Vertices, ...
            'FaceColor',[1.00 0.85 0.10],'EdgeColor','none', ...
            'DisplayName',sprintf('lamps (%d faces)',nnz(flagLampFace)));
    end
    if any(flagCover)
        patch(axesHandle,'Faces',vehicleMesh.Faces(flagCover,:),'Vertices',vehicleMesh.Vertices, ...
            'FaceColor',[0.10 0.80 0.95],'FaceAlpha',0.5,'EdgeColor',[0 0.4 0.5], ...
            'DisplayName',sprintf('lamp covers (%d faces)',nnz(flagCover)));
    end
    axis(axesHandle,'equal');
    grid(axesHandle,'on');
    view(axesHandle,-35,20);
    xlabel(axesHandle,'X [m] (forward)');
    ylabel(axesHandle,'Y [m] (left)');
    zlabel(axesHandle,'Z [m] (up)');
    legend(axesHandle,'Location','southoutside');
    title(axesHandle,'Lamps and their covers');
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

%% fcn_INTERNAL_faceNormals
function faceNormals = fcn_INTERNAL_faceNormals(vehicleMesh)
% A unit normal of each face, from its corners (the right-hand rule); which
% way is in comes from fcn_CarMesh3D_outwardSides
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
faceNormals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
faceNormals = faceNormals ./ max(vecnorm(faceNormals,2,2), eps);
end % Ends fcn_INTERNAL_faceNormals

%% fcn_INTERNAL_lampBehind
function hitLamp = fcn_INTERNAL_lampBehind(vehicleMesh, candidateFaces, lampFaces, lookDirections, maxDistance)
% For each candidate face, the lamp face (an index into lampFaces) nearest
% to it along its look direction (one unit vector per candidate face),
% within maxDistance (0 included: a lamp in the glass's own plane); 0 for
% none. Four straight lines ("rays") are cast per face: from its center,
% and from halfway between its center and each corner.
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
Ncandidates = numel(candidateFaces);

% The rays: start points and directions (inward: minus the normal)
corner1 = vertices(faces(candidateFaces,1),:);
corner2 = vertices(faces(candidateFaces,2),:);
corner3 = vertices(faces(candidateFaces,3),:);
centers = (corner1 + corner2 + corner3)/3;
rayStarts = [centers; (centers + corner1)/2; (centers + corner2)/2; (centers + corner3)/2];
rayDirections = repmat(lookDirections, 4, 1);
rayOwner = repmat((1:Ncandidates)', 4, 1);

% The lamp triangles: a corner and two edges each, and a box around each
lampCorner = vertices(faces(lampFaces,1),:);
lampEdge1 = vertices(faces(lampFaces,2),:) - lampCorner;
lampEdge2 = vertices(faces(lampFaces,3),:) - lampCorner;
lampLow = min(min(lampCorner, lampCorner + lampEdge1), lampCorner + lampEdge2);
lampHigh = max(max(lampCorner, lampCorner + lampEdge1), lampCorner + lampEdge2);

% Rays in blocks of nearby rays (sorted by a coarse grid), each tested
% only against the lamps whose boxes are near the block's box
cellSize = 0.25;
[~, order] = sortrows(floor(rayStarts/cellSize));
bestDistance = inf(size(rayStarts,1),1);
bestLamp = zeros(size(rayStarts,1),1);
blockSize = 256;
for first = 1:blockSize:numel(order)
    rows = order(first:min(numel(order), first+blockSize-1));
    blockLow = min(rayStarts(rows,:),[],1) - maxDistance;
    blockHigh = max(rayStarts(rows,:),[],1) + maxDistance;
    nearLamps = find(all(lampHigh >= blockLow, 2) & all(lampLow <= blockHigh, 2));
    if isempty(nearLamps)
        continue;
    end
    [blockDistance, blockLamp] = fcn_INTERNAL_rayHits(rayStarts(rows,:), rayDirections(rows,:), ...
        lampCorner(nearLamps,:), lampEdge1(nearLamps,:), lampEdge2(nearLamps,:), maxDistance);
    flagHit = blockLamp > 0;
    bestDistance(rows(flagHit)) = blockDistance(flagHit);
    bestLamp(rows(flagHit)) = nearLamps(blockLamp(flagHit));
end

% The nearest hit of each face's rays
hitLamp = zeros(Ncandidates,1);
flagHit = bestLamp > 0;
if any(flagHit)
    hitRows = find(flagHit);
    [~, sortIndex] = sort(bestDistance(hitRows), 'descend');  % (the nearest is written last)
    hitRows = hitRows(sortIndex);
    hitLamp(rayOwner(hitRows)) = bestLamp(hitRows);
end
end % Ends fcn_INTERNAL_lampBehind

%% fcn_INTERNAL_rayHits
function [hitDistance, hitTriangle] = fcn_INTERNAL_rayHits(rayStarts, rayDirections, corners, edges1, edges2, maxDistance)
% Where each ray first crosses any of the triangles (the Moller-Trumbore
% test, for every ray and triangle at once): the distance along the ray,
% and the triangle's number (0 if no triangle is crossed within
% maxDistance). A triangle the ray starts on counts, at distance 0 (glass
% lying right on its lamp). Rows are rays, columns are triangles.
dx = rayDirections(:,1); dy = rayDirections(:,2); dz = rayDirections(:,3);
e1x = edges1(:,1)'; e1y = edges1(:,2)'; e1z = edges1(:,3)';
e2x = edges2(:,1)'; e2y = edges2(:,2)'; e2z = edges2(:,3)';
% (p = direction x edge2; det = edge1 . p)
px = dy.*e2z - dz.*e2y;
py = dz.*e2x - dx.*e2z;
pz = dx.*e2y - dy.*e2x;
determinant = e1x.*px + e1y.*py + e1z.*pz;
flagParallel = abs(determinant) < 1e-12;
inverse = 1./determinant;
% (t = start - corner; u = (t . p)/det)
tx = rayStarts(:,1) - corners(:,1)';
ty = rayStarts(:,2) - corners(:,2)';
tz = rayStarts(:,3) - corners(:,3)';
u = (tx.*px + ty.*py + tz.*pz).*inverse;
% (q = t x edge1; v = (direction . q)/det; distance = (edge2 . q)/det)
qx = ty.*e1z - tz.*e1y;
qy = tz.*e1x - tx.*e1z;
qz = tx.*e1y - ty.*e1x;
v = (dx.*qx + dy.*qy + dz.*qz).*inverse;
distance = (e2x.*qx + e2y.*qy + e2z.*qz).*inverse;
tolerance = 1e-9;
flagHit = ~flagParallel & u >= -tolerance & v >= -tolerance & (u + v) <= 1 + tolerance ...
    & distance > -1e-7 & distance <= maxDistance;
distance = max(distance, 0);
distance(~flagHit) = inf;
[hitDistance, hitTriangle] = min(distance, [], 2);
hitTriangle(~isfinite(hitDistance)) = 0;
end % Ends fcn_INTERNAL_rayHits

%% fcn_INTERNAL_spreadOverPieces
function newCover = fcn_INTERNAL_spreadOverPieces(vehicleMesh, candidateFaces, hitType, flagAlsoGlass, oldCover)
% The covered lamp type of each candidate face. A face that found a lamp
% behind it covers that lamp; else a face that was a cover before stays
% one. Then, in each connected piece of candidate faces (sharing a
% corner): a light face that is also glass is a cover when any face of
% its piece found a lamp, and a plain glass face is a cover when at least
% half of its piece found one; it covers the lamp of the nearest face of
% its piece that found one.
newCover = hitType;
newCover(newCover==0) = oldCover(newCover==0);
pieceOfFace = fcn_INTERNAL_pieces(vehicleMesh, candidateFaces);
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces(candidateFaces,:);
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
flagFound = newCover > 0;
for thisPiece = unique(pieceOfFace(flagFound))'
    flagPiece = pieceOfFace==thisPiece;
    foundShare = mean(flagFound(flagPiece));
    flagJoin = flagPiece & ~flagFound & (flagAlsoGlass | foundShare >= 0.5);
    if ~any(flagJoin)
        continue;
    end
    sources = find(flagPiece & flagFound);
    targets = find(flagJoin);
    nearest = fcn_INTERNAL_nearestPoint(centers(sources,:), centers(targets,:));
    newCover(targets) = newCover(sources(nearest));
end
end % Ends fcn_INTERNAL_spreadOverPieces

%% fcn_INTERNAL_pieces
function pieceOfFace = fcn_INTERNAL_pieces(vehicleMesh, theseFaces)
% Numbers the connected pieces of the given faces: faces that share a
% corner (at the same position, to a micrometer) are in the same piece
Nthese = numel(theseFaces);
corners = vehicleMesh.Faces(theseFaces,:);
[~, ~, cornerId] = unique(round(vehicleMesh.Vertices(corners(:),:)*1e6), 'rows');
rows = sortrows([cornerId(:), repmat((1:Nthese)',3,1)]);
flagSameAsNext = rows(1:end-1,1)==rows(2:end,1);
faceGraph = graph(rows([flagSameAsNext; false],2), rows([false; flagSameAsNext],2), [], Nthese);
pieceOfFace = conncomp(faceGraph)';
end % Ends fcn_INTERNAL_pieces

%% fcn_INTERNAL_nearestPoint
function nearest = fcn_INTERNAL_nearestPoint(fromPoints, toPoints)
% The index of the nearest of fromPoints for each of toPoints (in blocks;
% no toolbox needed)
nearest = zeros(size(toPoints,1),1);
blockSize = 400;
for first = 1:blockSize:size(toPoints,1)
    rows = first:min(size(toPoints,1), first+blockSize-1);
    squaredDistance = sum(toPoints(rows,:).^2,2) + sum(fromPoints.^2,2)' - 2*toPoints(rows,:)*fromPoints';
    [~, nearest(rows)] = min(squaredDistance, [], 2);
end
end % Ends fcn_INTERNAL_nearestPoint
