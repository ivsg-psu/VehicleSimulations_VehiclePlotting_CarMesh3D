function [vehicleMesh, numLifted] = fcn_CarMesh3D_separateOverlays(vehicleMesh, options)
% fcn_CarMesh3D_separateOverlays

% Lifts overlays off the surfaces they lie on. Many downloads paint
% details as separate faces lying exactly on another part's surface (a
% black bumper insert on the painted bumper, a window's black border on
% the glass, a lamp lens on the trim). Two faces at the same depth are
% drawn in whichever order the graphics card picks, so the overlay
% flickers, shows in patches, or vanishes, and the result changes when
% the faces are reordered (as the simplification does).
%
% Each pair of overlapping faces of different parts (one face's center
% within Distance of the other's plane and inside it, both facing the
% same way) is found, and the face of the part drawn on top is moved
% Offset outward along its normal. Parts on top, first to last: light,
% glass, trim, body (a lamp lens over its housing; the glass over the
% black trim behind it, since glass is always the outermost surface of a
% window; a black insert over the paint; the glass over the body skin).
% Wheels are left alone.
%
% FORMAT:
%
%       [vehicleMesh, numLifted] = fcn_CarMesh3D_separateOverlays(vehicleMesh,...
%           (Distance=meters), (Offset=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh (Vertices, Faces,
%      PartNames, FacePartIndex), fit to its spec (in meters).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Distance: how close (meters) a face's center must be to another
%      face's plane to count as lying on it. Default 0.004.
%
%      Offset: how far (meters) the top face is moved outward. Default
%      0.002.
%
%      FigNum: a figure to plot the lifted faces in red. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with the overlays' corners moved outward
%      (corners shared with other faces move too, by the same small
%      amount). FaceNormals, if present, is unchanged (the faces keep
%      their directions).
%
%      numLifted: how many faces were moved.
%
% DEPENDENCIES:
%
%      knnsearch (Statistics and Machine Learning Toolbox)
%
% EXAMPLES:
%
%       [vehicleMesh, numLifted] = fcn_CarMesh3D_separateOverlays(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_separateOverlays.m for
%       a full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_separateOverlays
%   % * First write: the 2005 HiAce's bumpers (black inserts lying on
%   %   % the paint) showed 5% label changes from drawing order alone; 862
%   %   % pairs of coplanar faces of different parts

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_separateOverlays
%   % * Glass is now on top of trim (it was trim over glass): the black
%   %   % trim behind the 2009 Honda Fit's rear quarter windows and rear
%   %   % window was lifted in front of the glass, the worst 8 spots of
%   %   % its comparison. Glass is always the outermost surface

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
    options.Distance = 0.004   % Meters: how close counts as lying on a face
    options.Offset = 0.002     % Meters: how far the top face moves out
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
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces','PartNames','FacePartIndex'}))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, PartNames, FacePartIndex)');
        end
        if ~(isnumeric(options.Distance) && isscalar(options.Distance) && options.Distance > 0)
            error('Distance must be a positive number of meters');
        end
        if ~(isnumeric(options.Offset) && isscalar(options.Offset) && options.Offset >= 0)
            error('Offset must be a number of meters, 0 or more');
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

vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
numFaces = size(faces,1);
facePart = vehicleMesh.FacePartIndex(:);

% Which part is drawn on top: a higher rank wins (wheels: never moved)
partRank = zeros(numel(vehicleMesh.PartNames),1);
rankOrder = {'body',1; 'trim',2; 'glass',3; 'light',4};   % (higher is on top: glass over trim)
for ith_rank = 1:size(rankOrder,1)
    partRank(strcmp(vehicleMesh.PartNames, rankOrder{ith_rank,1})) = rankOrder{ith_rank,2};
end
faceRank = zeros(numFaces,1);
faceRank(facePart > 0) = partRank(facePart(facePart > 0));

corner1 = vertices(faces(:,1),:);
faceNormals = cross(vertices(faces(:,2),:) - corner1, vertices(faces(:,3),:) - corner1, 2);
faceAreas2 = vecnorm(faceNormals,2,2);
faceNormals = faceNormals./max(faceAreas2, eps);
faceCenters = (corner1 + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;

% Overlapping pairs: this face's center lies on a nearby face of another
% part, facing the same way
flagLift = false(numFaces,1);
numNeighbors = min(16, numFaces);
if numFaces > 1
    neighbors = knnsearch(faceCenters, faceCenters, 'K', numNeighbors);
    for ith_neighbor = 2:numNeighbors
        other = neighbors(:,ith_neighbor);
        flagCandidate = faceRank > 0 & faceRank(other) > 0 & faceRank ~= faceRank(other) & ...
            sum(faceNormals.*faceNormals(other,:), 2) > 0.9 & faceAreas2 > 0 & faceAreas2(other) > 0;
        otherCorner1 = vertices(faces(other,1),:);
        edge1 = vertices(faces(other,2),:) - otherCorner1;
        edge2 = vertices(faces(other,3),:) - otherCorner1;
        offset = faceCenters - otherCorner1;
        flagClose = abs(sum(offset.*faceNormals(other,:), 2)) < options.Distance;
        dot11 = sum(edge1.*edge1,2); dot12 = sum(edge1.*edge2,2); dot22 = sum(edge2.*edge2,2);
        dotP1 = sum(offset.*edge1,2); dotP2 = sum(offset.*edge2,2);
        denominator = max(dot11.*dot22 - dot12.^2, eps);
        weight1 = (dot22.*dotP1 - dot12.*dotP2)./denominator;
        weight2 = (dot11.*dotP2 - dot12.*dotP1)./denominator;
        flagInside = weight1 >= -0.01 & weight2 >= -0.01 & weight1 + weight2 <= 1.01;
        flagPair = flagCandidate & flagClose & flagInside;
        % (of the two, the higher-ranked part is lifted)
        thisFaces = find(flagPair);
        otherFaces = other(flagPair);
        flagThisOnTop = faceRank(thisFaces) > faceRank(otherFaces);
        flagLift(thisFaces(flagThisOnTop)) = true;
        flagLift(otherFaces(~flagThisOnTop)) = true;
    end
end

% Move the lifted faces' corners outward (along the mean normal of the
% lifted faces at each corner)
numLifted = sum(flagLift);
if numLifted > 0 && options.Offset > 0
    liftedFaces = faces(flagLift,:);
    liftedNormals = faceNormals(flagLift,:);
    cornerNormals = zeros(size(vertices));
    for ith_corner = 1:3
        cornerNormals = cornerNormals + accumarray([repmat(liftedFaces(:,ith_corner),3,1), kron((1:3)',ones(numLifted,1))], ...
            liftedNormals(:), size(vertices));
    end
    cornerLength = vecnorm(cornerNormals,2,2);
    flagMoved = cornerLength > 0;
    vertices(flagMoved,:) = vertices(flagMoved,:) + options.Offset*cornerNormals(flagMoved,:)./cornerLength(flagMoved);
    vehicleMesh.Vertices = vertices;
end

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
    faceColors = repmat([0.8 0.8 0.8], numFaces, 1);
    faceColors(flagLift,:) = repmat([0.9 0 0], numLifted, 1);
    patch('Vertices',vehicleMesh.Vertices, 'Faces',faces, 'FaceVertexCData',faceColors, ...
        'FaceColor','flat', 'EdgeColor','none', 'FaceLighting','flat');
    axis equal off;
    view(-55,20);
    camlight headlight;
    title(sprintf('%d overlay faces lifted %.1f mm (red)', numLifted, 1000*options.Offset));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
