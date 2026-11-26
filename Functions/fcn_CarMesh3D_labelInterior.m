function [vehicleMesh, interiorInfo] = fcn_CarMesh3D_labelInterior(vehicleMesh, options)
% fcn_CarMesh3D_labelInterior

% Labels a vehicle's interior (seats, steering wheel, dash, door
% panels): the faces of the body and trim parts that can be seen from
% outside only through the glass. Downloads rarely name their interior
% materials, so the interior is found from the shape, with voxels:
%
%   1. Points are sampled over every face except the wheels, at most half
%      a voxel apart, and the voxels they fall in are marked: the shell.
%   2. The shell is grown by GapSize/2, so that seams, gaps between
%      panels, and holes up to GapSize across (a hole in a download's
%      floor) are closed and cannot let the outside in.
%   3. The outside air is filled from the edge of the grid, twice:
%        A. with the glass in the shell: the air around the closed car;
%        B. without the glass: the air also flows in through the window
%           openings, into the cabin.
%      Each fill is grown back by GapSize/2 (undoing step 2's growth).
%   4. A face is interior when the air of fill B reaches it but the air of
%      fill A does not: it is seen only through the glass. Faces under the
%      hood or inside a panel (reached by neither) and faces seen
%      directly (reached by A) keep their labels.
%
% Only faces of the parts in Parts (body and trim) are relabeled: glass,
% lights, and wheels never are. The new part 'interior' is added to
% LabelPartNames if it is not there; the faces keep their colors. Painted
% fixes (fcn_CarMesh3D_editLabels) can still change any face afterward.
%
% FORMAT:
%
%       [vehicleMesh, interiorInfo] = fcn_CarMesh3D_labelInterior(vehicleMesh,...
%           (VoxelSize=meters), (GapSize=meters), (Parts=names),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames,
%      LabelFacePart, FaceWheelIndex), fit to its spec (in meters). Run
%      it after the floor panel is added (fcn_CarMesh3D_addFloorPanel), so
%      a download with no floor is closed from below.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      VoxelSize: meters. Default 0.02.
%
%      GapSize: meters; holes and gaps up to this size are closed (steps
%      2 and 3). Default 0.12. Window openings must be larger than this,
%      or fill B cannot enter the cabin; a hole larger than this in a
%      download lets the outside in, and the faces it shows are not
%      labeled interior.
%
%      Parts: the parts whose faces may become interior. Default
%      {'body','trim'}.
%
%      FigNum: a figure to plot the mesh with its interior faces in
%      orange (the rest faded). If empty or omitted, no plot is made. If
%      set to -1, input checking is skipped and no plot is made (fast
%      mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with its interior faces' LabelFacePart set to
%      the 'interior' part (added to LabelPartNames if needed), and
%      InteriorInfo set to interiorInfo.
%
%      interiorInfo: a structure with VoxelSize, GapSize, NumInterior
%      (faces relabeled), NumFromPart (a table-like structure: how many
%      came from each part), and GridSize.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport');
%       load(vehicleFiles.MeshFile, 'vehicleMesh');
%       vehicleMesh = fcn_CarMesh3D_labelInterior(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_labelInterior.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelInterior
%   % * First write: the interior by voxel fills (Sean's suggestion, from
%   %   % the closed hull of fcn_CarMesh3D_makeDetailLevels), seen only
%   %   % through the glass; robust to small holes in a download's floor
%   %   % (a ray test would call everything a hole shows "exterior")

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelInterior
%   % * Interior types (steering wheel, seats, dash), for the 2D outline



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.VoxelSize = 0.02          % meters
    options.GapSize = 0.12            % meters: holes up to this size are closed
    options.Parts = {'body','trim'}   % parts whose faces may become interior
    options.FigNum = []               % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces','LabelPartNames','LabelFacePart','FaceWheelIndex'}))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart, FaceWheelIndex)');
        end
        if ~(isnumeric(options.VoxelSize) && isscalar(options.VoxelSize) && options.VoxelSize > 0)
            error('VoxelSize must be a positive number of meters');
        end
        if ~(isnumeric(options.GapSize) && isscalar(options.GapSize) && options.GapSize > 0)
            error('GapSize must be a positive number of meters');
        end
        if ~(iscellstr(options.Parts) || isstring(options.Parts))
            error('Parts must be a list of part names, such as {''body'',''trim''}');
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
facePart = vehicleMesh.LabelFacePart(:);
flagWheel = vehicleMesh.FaceWheelIndex(:) > 0;
glassIndex = find(strcmp(vehicleMesh.LabelPartNames, 'glass'));
flagGlass = ismember(facePart, glassIndex);
voxelSize = options.VoxelSize;

%%%% 1. The shell: sampled points of every face but the wheels
shellFaces = find(~flagWheel);
[points, sourceFace] = fcn_INTERNAL_sampleFaces(vertices, faces(shellFaces,:), voxelSize/2);
sourceFace = shellFaces(sourceFace);
growthSteps = max(1, ceil(options.GapSize/(2*voxelSize)));
padding = growthSteps + 3;
boxLow = min(vertices(unique(faces(shellFaces,:)),:), [], 1);
boxHigh = max(vertices(unique(faces(shellFaces,:)),:), [], 1);
gridLow = boxLow - padding*voxelSize;
gridSize = ceil((boxHigh + padding*voxelSize - gridLow)/voxelSize) + 1;
pointCell = floor((points - gridLow)/voxelSize) + 1;
pointKey = sub2ind(gridSize, pointCell(:,1), pointCell(:,2), pointCell(:,3));
pointIsGlass = flagGlass(sourceFace);

%%%% 2 and 3. The two fills (A: glass in the shell; B: glass left out)
shellA = false(gridSize);
shellA(pointKey) = true;
shellB = false(gridSize);
shellB(pointKey(~pointIsGlass)) = true;
nearA = fcn_INTERNAL_nearOutside(shellA, growthSteps);
nearB = fcn_INTERNAL_nearOutside(shellB, growthSteps);

%%%% 4. Interior: reached by B's air, not by A's
pointNearA = nearA(pointKey);
pointNearB = nearB(pointKey);
reachedA = accumarray(sourceFace, double(pointNearA), [numFaces 1]) > 0;
reachedB = accumarray(sourceFace, double(pointNearB), [numFaces 1]) > 0;
allowedParts = find(ismember(vehicleMesh.LabelPartNames, cellstr(options.Parts)));
flagInterior = reachedB & ~reachedA & ismember(facePart, allowedParts) & ~flagWheel;

% The 'interior' part (added if needed); the faces keep their colors
interiorIndex = find(strcmp(vehicleMesh.LabelPartNames, 'interior'), 1);
if isempty(interiorIndex)
    vehicleMesh.LabelPartNames{end+1} = 'interior';
    interiorIndex = numel(vehicleMesh.LabelPartNames);
end
fromPart = facePart(flagInterior);
vehicleMesh.LabelFacePart(flagInterior) = interiorIndex;

numFromPart = struct();
for thisPart = reshape(allowedParts,1,[])
    numFromPart.(matlab.lang.makeValidName(vehicleMesh.LabelPartNames{thisPart})) = nnz(fromPart==thisPart);
end
interiorInfo = struct('VoxelSize',voxelSize, 'GapSize',options.GapSize, 'NumInterior',nnz(flagInterior), ...
    'NumFromPart',numFromPart, 'GridSize',gridSize);
vehicleMesh.InteriorInfo = interiorInfo;

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
    hold on;
    patch('Vertices',vertices, 'Faces',faces(~flagInterior,:), 'FaceColor',[0.7 0.7 0.75], 'EdgeColor','none', 'FaceAlpha',0.12);
    patch('Vertices',vertices, 'Faces',faces(flagInterior,:), 'FaceColor',[1 0.55 0.1], 'EdgeColor',[0.4 0.2 0]);
    axis equal;
    grid on;
    view(-35, 30);
    camlight headlight;
    lighting gouraud;
    xlabel('X [m] (forward)');
    ylabel('Y [m] (left)');
    zlabel('Z [m] (up)');
    title(sprintf('Interior faces (orange): %d', nnz(flagInterior)));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

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

%% fcn_INTERNAL_nearOutside
function nearOutside = fcn_INTERNAL_nearOutside(shell, growthSteps)
% The voxels next to the outside air: the shell grown by growthSteps (to
% close gaps), the outside filled from the grid's edge, the fill grown
% back by growthSteps (undoing the growth), then by one more voxel (to
% reach the shell voxels themselves)
grownShell = shell;
for ith_step = 1:growthSteps
    grownShell = fcn_INTERNAL_grow(grownShell);
end
outside = false(size(shell));
outside([1 end],:,:) = true;
outside(:,[1 end],:) = true;
outside(:,:,[1 end]) = true;
outside = outside & ~grownShell;
while true
    grown = fcn_INTERNAL_grow(outside) & ~grownShell;
    if isequal(grown, outside)
        break;
    end
    outside = grown;
end
for ith_step = 1:growthSteps + 1
    outside = fcn_INTERNAL_grow(outside);
end
nearOutside = outside;
end % Ends fcn_INTERNAL_nearOutside

%% fcn_INTERNAL_sampleFaces
function [points, sourceFace] = fcn_INTERNAL_sampleFaces(vertices, faces, spacing)
% Points on a triangular grid on each face, at most spacing apart (as in
% fcn_CarMesh3D_makeDetailLevels)
corner1 = vertices(faces(:,1),:);
corner2 = vertices(faces(:,2),:);
corner3 = vertices(faces(:,3),:);
longestEdge = max([vecnorm(corner2-corner1,2,2), vecnorm(corner3-corner2,2,2), vecnorm(corner1-corner3,2,2)], [], 2);
divisions = max(1, ceil(longestEdge/spacing));
pointCells = {};
sourceCells = {};
for thisDivision = unique(divisions)'
    rows = find(divisions==thisDivision);
    [stepI, stepJ] = meshgrid(0:thisDivision, 0:thisDivision);
    keep = stepI + stepJ <= thisDivision;
    weightA = stepI(keep)/thisDivision;
    weightB = stepJ(keep)/thisDivision;
    weightC = 1 - weightA - weightB;
    coordinates = zeros(numel(rows), numel(weightA), 3);
    for ith_axis = 1:3
        coordinates(:,:,ith_axis) = corner1(rows,ith_axis)*weightA' + corner2(rows,ith_axis)*weightB' + corner3(rows,ith_axis)*weightC';
    end
    pointCells{end+1} = reshape(coordinates, [], 3); %#ok<AGROW>
    sourceCells{end+1} = repmat(rows, numel(weightA), 1); %#ok<AGROW>
end
points = vertcat(pointCells{:});
sourceFace = vertcat(sourceCells{:});
end % Ends fcn_INTERNAL_sampleFaces

%% fcn_INTERNAL_grow
function grown = fcn_INTERNAL_grow(mask)
% Grow a 3D logical mask by one voxel (6 neighbors)
grown = mask;
grown(2:end,:,:) = grown(2:end,:,:) | mask(1:end-1,:,:);
grown(1:end-1,:,:) = grown(1:end-1,:,:) | mask(2:end,:,:);
grown(:,2:end,:) = grown(:,2:end,:) | mask(:,1:end-1,:);
grown(:,1:end-1,:) = grown(:,1:end-1,:) | mask(:,2:end,:);
grown(:,:,2:end) = grown(:,:,2:end) | mask(:,:,1:end-1);
grown(:,:,1:end-1) = grown(:,:,1:end-1) | mask(:,:,2:end);
end % Ends fcn_INTERNAL_grow
