function [outwardSign, info] = fcn_CarMesh3D_outwardSides(vehicleMesh, options)
% fcn_CarMesh3D_outwardSides
% Tells, for each face, which of its two sides is seen from outside the
% vehicle, without trusting the direction the face points (its corner
% order or stored FaceNormals). Downloads often have faces pointing the
% wrong way, and the direction fixes come after labeling (Sean,
% 2026-11-27), so the steps between (lamp covers, overlay lifting) use
% this instead.
%
% How: from each face's center, a straight line is followed both ways
% along the face's normal line. A side whose line leaves the vehicle
% without crossing any opaque face (glass is seen through, so it is not
% counted when the mesh is labeled) is seen from outside. Faces crossed
% within NearDistance of the face (an overlay lying on it, or the other
% skin of thin glass) are not counted. When both sides or neither side
% leaves (a face inside the body, or seen from both sides), the geometry
% does not say, and the face keeps its own direction: its stored
% FaceNormals if the mesh has them, else its corner order. (Counting the
% faces crossed, or taking the side away from the middle, agreed with the
% fixed directions of nine built vehicles only about half the time; a
% line that leaves agreed 91 to 97% of the time.)
%
% FORMAT:
%
%       [outwardSign, info] = fcn_CarMesh3D_outwardSides(vehicleMesh,...
%           (FaceList=faces), (NearDistance=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure (Vertices, Faces), in
%      meters; labeled or not.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FaceList: the faces to judge (indices into Faces). Default: all.
%
%      NearDistance: crossings closer than this (meters) are not counted.
%      Default 0.004.
%
%      FigNum: a figure to plot the judged faces, green where their corner
%      order points outward and red where it points inward. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      outwardSign: one per face of FaceList: +1 if the face's corner-order
%      normal (the right-hand rule) points outward, -1 if it points inward.
%
%      info: a structure with, per face of FaceList, the counts behind the
%      decision: EscapesPlus and EscapesMinus (true where the line leaves
%      the vehicle on that side), CrossingsPlus and CrossingsMinus (opaque
%      faces crossed), and Rule (1: one side leaves the vehicle; 2: the
%      face kept its own direction).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       outwardSign = fcn_CarMesh3D_outwardSides(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_outwardSides.m for a
%       full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_outwardSides
%   % * First write (step 1A of the plan of 2026-11-27): lamp covers and
%   %   % overlay lifting no longer trust face directions

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
    options.FaceList = []          % Faces to judge; [] for all
    options.NearDistance = 0.004   % Meters: crossings this close are not counted
    options.FigNum = []            % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces') ...
                || size(vehicleMesh.Vertices,2)~=3 || size(vehicleMesh.Faces,2)~=3
            error('vehicleMesh must be a CarMesh3D mesh structure with N x 3 Vertices and M x 3 Faces');
        end
        if ~isempty(options.FaceList) && (~isnumeric(options.FaceList) || any(options.FaceList(:) < 1) ...
                || any(options.FaceList(:) > size(vehicleMesh.Faces,1)) || any(mod(options.FaceList(:),1) ~= 0))
            error('FaceList must hold face numbers from 1 to %d', size(vehicleMesh.Faces,1));
        end
        if ~(isnumeric(options.NearDistance) && isscalar(options.NearDistance) && options.NearDistance >= 0)
            error('NearDistance must be a number of meters, 0 or more');
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
numFaces = size(faces,1);
faceList = options.FaceList(:);
if isempty(faceList)
    faceList = (1:numFaces)';
end
numJudged = numel(faceList);

% The opaque faces: all but glass (when labeled)
flagOpaque = true(numFaces,1);
if isfield(vehicleMesh,'LabelPartNames') && isfield(vehicleMesh,'LabelFacePart') && numel(vehicleMesh.LabelFacePart)==numFaces
    glassIndex = find(strcmp(vehicleMesh.LabelPartNames,'glass'), 1);
    if ~isempty(glassIndex)
        flagOpaque = vehicleMesh.LabelFacePart(:) ~= glassIndex;
    end
end

corner1 = vertices(faces(:,1),:);
edge1 = vertices(faces(:,2),:) - corner1;
edge2 = vertices(faces(:,3),:) - corner1;
faceNormals = cross(edge1, edge2, 2);
faceNormals = faceNormals./max(vecnorm(faceNormals,2,2), eps);
faceCenters = corner1 + (edge1 + edge2)/3;

starts = faceCenters(faceList,:);
directions = faceNormals(faceList,:);
opaqueFaces = find(flagOpaque);
crossingsPlus = zeros(numJudged,1);
crossingsMinus = zeros(numJudged,1);
if ~isempty(opaqueFaces) && numJudged > 0
    % (in blocks of lines, so the line-by-face arrays stay small)
    blockSize = max(1, floor(1e6/numel(opaqueFaces)));
    for first = 1:blockSize:numJudged
        rows = first:min(numJudged, first+blockSize-1);
        distance = fcn_INTERNAL_lineCrossings(starts(rows,:), directions(rows,:), ...
            corner1(opaqueFaces,:), edge1(opaqueFaces,:), edge2(opaqueFaces,:));
        crossingsPlus(rows) = sum(distance > options.NearDistance, 2);
        crossingsMinus(rows) = sum(distance < -options.NearDistance, 2);
    end
end

% The decision: the side that leaves the vehicle; else the face's own
% direction (stored FaceNormals, else its corner order)
escapesPlus = crossingsPlus == 0;
escapesMinus = crossingsMinus == 0;
outwardSign = ones(numJudged,1);
rule = ones(numJudged,1);
flagEscapeDecides = escapesPlus ~= escapesMinus;
outwardSign(flagEscapeDecides & escapesMinus) = -1;
flagOwn = ~flagEscapeDecides;
rule(flagOwn) = 2;
if any(flagOwn) && isfield(vehicleMesh,'FaceNormals') && isequal(size(vehicleMesh.FaceNormals),[numFaces 3])
    storedDot = sum(vehicleMesh.FaceNormals(faceList(flagOwn),:).*directions(flagOwn,:), 2);
    ownSign = ones(nnz(flagOwn),1);
    ownSign(storedDot < 0) = -1;
    outwardSign(flagOwn) = ownSign;
end

info = struct('EscapesPlus', escapesPlus, 'EscapesMinus', escapesMinus, ...
    'CrossingsPlus', crossingsPlus, 'CrossingsMinus', crossingsMinus, 'Rule', rule);

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
    faceColors = repmat([0.85 0.85 0.85], numFaces, 1);
    faceColors(faceList(outwardSign > 0),:) = repmat([0.2 0.7 0.3], nnz(outwardSign > 0), 1);
    faceColors(faceList(outwardSign < 0),:) = repmat([0.9 0.1 0.1], nnz(outwardSign < 0), 1);
    patch('Vertices',vertices, 'Faces',faces, 'FaceVertexCData',faceColors, ...
        'FaceColor','flat', 'EdgeColor','none', 'FaceLighting','flat');
    axis equal off;
    view(-55,20);
    camlight headlight;
    title(sprintf('%d faces point outward (green), %d inward (red)', nnz(outwardSign > 0), nnz(outwardSign < 0)));
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

%% fcn_INTERNAL_lineCrossings
function distance = fcn_INTERNAL_lineCrossings(starts, directions, corners, edges1, edges2)
% Where each straight line (start + distance*direction, distance of any
% sign) crosses each triangle (the Moller-Trumbore test, every line
% against every triangle at once): the signed distance along the line,
% or NaN where it does not cross. Rows are lines, columns are triangles.
dx = directions(:,1); dy = directions(:,2); dz = directions(:,3);
e1x = edges1(:,1)'; e1y = edges1(:,2)'; e1z = edges1(:,3)';
e2x = edges2(:,1)'; e2y = edges2(:,2)'; e2z = edges2(:,3)';
px = dy.*e2z - dz.*e2y;
py = dz.*e2x - dx.*e2z;
pz = dx.*e2y - dy.*e2x;
determinant = e1x.*px + e1y.*py + e1z.*pz;
inverse = 1./determinant;
tx = starts(:,1) - corners(:,1)';
ty = starts(:,2) - corners(:,2)';
tz = starts(:,3) - corners(:,3)';
u = (tx.*px + ty.*py + tz.*pz).*inverse;
qx = ty.*e1z - tz.*e1y;
qy = tz.*e1x - tx.*e1z;
qz = tx.*e1y - ty.*e1x;
v = (dx.*qx + dy.*qy + dz.*qz).*inverse;
distance = (e2x.*qx + e2y.*qy + e2z.*qz).*inverse;
flagCross = abs(determinant) > 1e-12 & u >= 0 & v >= 0 & (u + v) <= 1;
distance(~flagCross) = NaN;
end % Ends fcn_INTERNAL_lineCrossings
