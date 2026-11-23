function detailLevels = fcn_CarMesh3D_makeDetailLevels(vehicleMesh, options)
% fcn_CarMesh3D_makeDetailLevels

% Makes a "ladder" of lighter versions of a finished vehicle mesh, for
% animations where a vehicle is often far away and small on screen. Each
% level is made for a range of sizes on screen, with about the same
% number of visible faces per pixel as the others, so detail is spent
% only where it can be seen. The animation (AnimateCar3D) works out each
% vehicle's size on screen every frame and draws the coarsest level made
% for at least that size; above the ladder's top it draws the finished
% mesh itself, the only version with wheels that spin and steer, a body
% that rolls, pitches, and heaves, and lights that switch.
%
% THE SIZE-ON-SCREEN STANDARD (shared with AnimateCar3D):
%
%   D, the object's size: the diagonal of its bounding box, from (minX,
%   minY, minZ) to (maxX, maxY, maxZ) of its vertices in its own frame.
%   The distance is measured from the camera to the center of that box.
%
%   size on screen (pixels) = D x (axes' smaller side, pixels)
%                                 / (2 x distance x tan(CameraViewAngle/2))
%
%   (MATLAB's CameraViewAngle spans the smaller side of the axes: checked
%   with axes of several shapes.)
%
% THE DENSITY RULE: about FacesPerPixel (default 0.2) visible faces per
% pixel covered, as for the 2013 Prius mesh seen from 10 m. A vehicle
% covers about A x (S/D)^2 pixels at size S, where A is its mean shadow
% area (m^2, seen from around and above), and about half its faces are
% visible, so a level made for sizes up to S gets
%
%       faces = 2 x FacesPerPixel x A x (S/D)^2
%
% THE LADDER: the top level is made for TopScreenSize (default 105 px);
% each next level for a size Step (default sqrt(2)) times smaller, so it
% has about half the faces. Once the rule gives fewer than MinFaces
% (default 15) faces, the last level is a box (5 faces). A level that
% would need as many faces as the finished mesh is not made (the
% finished mesh is used there).
%
% THE METHOD: a closed hull. Reducing a downloaded mesh directly opens
% gaps (bodies are many separate open panels, and reducing an open panel
% pulls its edges in), so the vehicle is wrapped in one closed surface
% first:
%   1. Points are sampled over every face, at most half a voxel apart
%   2. The voxels they fall in are marked, and the marks grown by
%      GapSize/2 (closing seams, gaps between panels, and openings up to
%      GapSize across, such as a window with no glass in the model, so
%      that the outside cannot flow into the cabin)
%   3. The outside is filled from the edge of the grid; the rest is
%      solid; the solid is shrunk back by the same amount (undoing the
%      growth). Its shadows give A.
%   4. The solid is smoothed and its isosurface taken: one closed surface
%   5. That surface is reduced with reducepatch to each level's faces
%   6. Each new face takes the part, light type, color, and opacity of
%      the outer surface of the finished mesh under it, by a vote of
%      seven points on the face (so a small lamp cannot color a large
%      face)
% Each level is a normal CarMesh3D mesh structure (fcn_CarMesh3D_plotVehicle
% draws it). Its wheels are part of the hull: FaceWheelIndex is 0, so the
% level moves as one piece. Window colors are blotchy close up (a face
% has one color); at the sizes a level is drawn at this cannot be seen
% (see the README, "Detail levels for animation").
%
% FORMAT:
%
%       detailLevels = fcn_CarMesh3D_makeDetailLevels(vehicleMesh,...
%           (TopScreenSize=pixels), (Step=ratio), (FacesPerPixel=density),...
%           (VoxelSize=meters), (GapSize=meters), (MinFaces=count),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a finished CarMesh3D mesh (labeled, fitted, and
%      simplified: with FacePartIndex, FaceColors, FaceAlpha, and
%      FaceNormals), for example from a vehicle's vehicleMesh_<ID>.mat.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TopScreenSize: the size on screen (pixels) the top level is made
%      for. Default 105 (the Prius at about 30 m in an axes 450 pixels on
%      its smaller side, with a 40 degree view angle).
%
%      Step: the ratio between the sizes of two levels. Default sqrt(2).
%
%      FacesPerPixel: visible faces per pixel. Default 0.2.
%
%      VoxelSize: the voxel size of the hull, meters. Default 0.03.
%
%      GapSize: openings up to this size (meters) are closed. Default
%      0.36. (Too small, and the outside flows into a vehicle with an
%      open window: the hull is then a hollow shell with holes where the
%      windows are; the 2014 Transit Connect model needs about 0.3 m.
%      Concave parts narrower than GapSize, such as the gap between a
%      tire and its wheel arch, are filled too, which cannot be seen at
%      the sizes the levels are made for.)
%
%      MinFaces: below this many faces, the level is a box. Default 15.
%
%      FigNum: a figure number to show every level side by side. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      detailLevels: a structure with fields
%           Levels: a structure array, finest first, with fields
%               MaxScreenSize (pixels: the largest size it is made for),
%               Faces, IsBox, and Mesh (a CarMesh3D mesh; [] for the box)
%           SizeDiagonal: D, meters
%           BoxCenter: the bounding box's center, in the vehicle frame
%           BoxSize: the bounding box's [length width height], meters
%           ShadowArea: A, m^2
%           SolidFraction: the hull's volume over its box's (a car or van
%               is about 0.5; much less means the hull is hollow)
%           FacesPerPixel, TopScreenSize, Step, MinFaces, VoxelSize, GapSize
%           FullFaces: the finished mesh's face count
%           Method: 'closedHull'
%           FormatVersion: 1
%           MadeBy: this function and its date; MadeOn: when it was run
%           MakeSeconds: how long it took
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%      reducepatch, isosurface, smooth3 (MATLAB base)
%
% EXAMPLES:
%
%       loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
%       detailLevels = fcn_CarMesh3D_makeDetailLevels(loaded.vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_makeDetailLevels.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDetailLevels
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDetailLevels
%   % * Added GapSize (default 0.36 m): openings up to that size are
%   %   % closed. With only 6 cm gaps closed, the outside flowed into the
%   %   % Transit Connect's cab through its open windows, and its levels
%   %   % were hollow shells with holes where the windows are.
%   % * Added SolidFraction to the output

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDetailLevels
%   % * Measures the vehicle as it is shown: hidden faces (FaceHiddenSet)
%   %   % are left out (fcn_CarMesh3D_visibleMesh; Sean, 04:17)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDetailLevels
%   % * Speed: the sampling and shadow steps could use fewer points for large
%   %   % vehicles (a bus)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.TopScreenSize = 105       % pixels: the size the top level is made for
    options.Step = sqrt(2)            % ratio between the sizes of two levels
    options.FacesPerPixel = 0.2       % visible faces per pixel
    options.VoxelSize = 0.03          % meters
    options.GapSize = 0.36            % meters: openings up to this size are closed
    options.MinFaces = 15             % below this, the level is a box
    options.FigNum = []               % figure to show the levels; -1 for fast mode
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
        requiredFields = {'Vertices','Faces','FacePartIndex','FaceColors','FaceAlpha'};
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, requiredFields))
            error('vehicleMesh must be a finished CarMesh3D mesh, with fields %s', strjoin(requiredFields, ', '));
        end
        if size(vehicleMesh.Faces,2)~=3 || size(vehicleMesh.Vertices,2)~=3
            error('vehicleMesh must have triangular faces and 3D vertices');
        end

        % Check the numeric options
        numericOptions = [options.TopScreenSize, options.FacesPerPixel, options.VoxelSize, options.MinFaces, options.GapSize];
        if ~isnumeric(numericOptions) || numel(numericOptions)~=5 || any(numericOptions<=0)
            error('TopScreenSize, FacesPerPixel, VoxelSize, MinFaces, and GapSize must be positive numbers');
        end
        if ~isnumeric(options.Step) || ~isscalar(options.Step) || options.Step <= 1
            error('Step must be a number greater than 1');
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


% (the vehicle as it is shown: hidden faces never count here;
% fcn_CarMesh3D_visibleMesh)
vehicleMesh = fcn_CarMesh3D_visibleMesh(vehicleMesh, FigNum=-1);

makeTimer = tic;
vertices = double(vehicleMesh.Vertices);
faces = double(vehicleMesh.Faces);
fullFaces = size(faces,1);
voxelSize = options.VoxelSize;

%%%% The size standard: the bounding box in the vehicle's own frame
boxLow = min(vertices,[],1);
boxHigh = max(vertices,[],1);
sizeDiagonal = norm(boxHigh - boxLow);

%%%% 1. Sample the surface (each point remembers its face)
[points, sourceFace] = fcn_INTERNAL_sampleFaces(vertices, faces, voxelSize/2);

%%%% 2. The shell voxels, grown by half the gap size
growthSteps = max(1, ceil(options.GapSize/(2*voxelSize)));
padding = growthSteps + 3;
gridLow = boxLow - padding*voxelSize;
gridSize = ceil((boxHigh + padding*voxelSize - gridLow)/voxelSize) + 1;
pointCell = floor((points - gridLow)/voxelSize) + 1;
pointKey = sub2ind(gridSize, pointCell(:,1), pointCell(:,2), pointCell(:,3));
shell = false(gridSize);
shell(pointKey) = true;
grownShell = shell;
for ith_step = 1:growthSteps
    grownShell = fcn_INTERNAL_grow(grownShell);
end

%%%% 3. Fill the outside; the rest is solid; shrink back
outside = false(gridSize);
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
grownOutside = outside;
for ith_step = 1:growthSteps
    grownOutside = fcn_INTERNAL_grow(grownOutside);
end
solid = ~grownOutside;

% The outer surface of the finished mesh: the sampled points in shell
% voxels next to the outside (hidden inner surfaces are not used to color
% the hull). One point per voxel, for a quick nearest-point search.
nearOutside = fcn_INTERNAL_grow(grownOutside);
flagOuter = nearOutside(pointKey);
[outerKeys, firstPoint] = unique(pointKey(flagOuter), 'first');
outerIndex = find(flagOuter);
outerPoints = points(outerIndex(firstPoint),:);
outerSource = sourceFace(outerIndex(firstPoint));

% The mean shadow area, seen from around and above
shadowArea = fcn_INTERNAL_shadowArea(solid, gridLow, voxelSize);

%%%% 4. The closed surface
xs = gridLow(1) + (0:gridSize(1)-1)*voxelSize;
ys = gridLow(2) + (0:gridSize(2)-1)*voxelSize;
zs = gridLow(3) + (0:gridSize(3)-1)*voxelSize;
[gridX, gridY, gridZ] = meshgrid(xs, ys, zs);
smoothSolid = smooth3(permute(double(solid), [2 1 3]), 'box', 3);
surfaceFV = isosurface(gridX, gridY, gridZ, smoothSolid, 0.5);

%%%% 5 and 6. The ladder
emptyLevel = struct('MaxScreenSize',0, 'Faces',0, 'IsBox',false, 'Mesh',[]);
levels = repmat(emptyLevel, 0, 1);
screenSize = options.TopScreenSize;
while true
    targetFaces = round(2*options.FacesPerPixel*shadowArea*(screenSize/sizeDiagonal)^2);
    if targetFaces < options.MinFaces
        boxLevel = emptyLevel;
        boxLevel.MaxScreenSize = screenSize;
        boxLevel.Faces = 5;
        boxLevel.IsBox = true;
        levels(end+1,1) = boxLevel; %#ok<AGROW>
        break;
    end
    if targetFaces < fullFaces          % (otherwise the finished mesh is used here)
        thisLevel = emptyLevel;
        thisLevel.MaxScreenSize = screenSize;
        thisLevel.Mesh = fcn_INTERNAL_reducedMesh(vehicleMesh, surfaceFV, targetFaces, ...
            outerPoints, outerSource, outerKeys, gridLow, gridSize, voxelSize);
        thisLevel.Faces = size(thisLevel.Mesh.Faces,1);
        levels(end+1,1) = thisLevel; %#ok<AGROW>
    end
    screenSize = screenSize/options.Step;
end

detailLevels = struct;
detailLevels.Levels = levels;
detailLevels.SizeDiagonal = sizeDiagonal;
detailLevels.BoxCenter = (boxLow + boxHigh)/2;
detailLevels.BoxSize = boxHigh - boxLow;
detailLevels.ShadowArea = shadowArea;
detailLevels.FacesPerPixel = options.FacesPerPixel;
detailLevels.TopScreenSize = options.TopScreenSize;
detailLevels.Step = options.Step;
detailLevels.MinFaces = options.MinFaces;
detailLevels.VoxelSize = voxelSize;
detailLevels.GapSize = options.GapSize;
detailLevels.SolidFraction = nnz(solid)*voxelSize^3/prod(boxHigh - boxLow);
detailLevels.FullFaces = fullFaces;
detailLevels.Method = 'closedHull';
detailLevels.FormatVersion = 1;
detailLevels.MadeBy = 'fcn_CarMesh3D_makeDetailLevels (2026_11_19)';
detailLevels.MadeOn = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
detailLevels.MakeSeconds = toc(makeTimer);

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
    axesHandle = axes;
    hold(axesHandle, 'on');
    Nlevels = numel(detailLevels.Levels);
    spacing = 1.25*detailLevels.BoxSize(2);
    labels = cell(Nlevels+1,1);
    labelY = zeros(Nlevels+1,1);
    for ith_level = 0:Nlevels
        offsetY = -ith_level*spacing;
        if ith_level==0
            fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[0 offsetY 0], FigNum=figNum);
            labels{1} = sprintf('Finished\n%d faces', detailLevels.FullFaces);
        else
            thisLevel = detailLevels.Levels(ith_level);
            if thisLevel.IsBox
                boxCorners = detailLevels.BoxCenter - detailLevels.BoxSize/2 + ...
                    [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1].*detailLevels.BoxSize;
                boxCorners(:,2) = boxCorners(:,2) + offsetY;
                patch('Parent',axesHandle, 'Vertices',boxCorners, 'Faces',[1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], ...
                    'FaceColor',[0.05 0.2 0.6], 'EdgeColor',[0.3 0.3 0.3]);
            else
                fcn_CarMesh3D_plotVehicle(thisLevel.Mesh, Pose=[0 offsetY 0], FigNum=figNum);
            end
            labels{ith_level+1} = sprintf('up to %.0f px\n%d faces', thisLevel.MaxScreenSize, thisLevel.Faces);
        end
        labelY(ith_level+1) = offsetY;
    end
    for ith_label = 1:numel(labels)
        text(axesHandle, detailLevels.BoxCenter(1), labelY(ith_label), detailLevels.BoxCenter(3) + 0.75*detailLevels.BoxSize(3), ...
            labels{ith_label}, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize',8);
    end
    axis(axesHandle, 'equal');
    view(axesHandle, -60, 25);
    title(axesHandle, sprintf('Detail levels: D = %.2f m, shadow area %.1f m^2, %.2f faces per pixel', ...
        detailLevels.SizeDiagonal, detailLevels.ShadowArea, detailLevels.FacesPerPixel));
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

%% fcn_INTERNAL_sampleFaces
function [points, sourceFace] = fcn_INTERNAL_sampleFaces(vertices, faces, spacing)
% Points on a triangular grid on each face, at most spacing apart
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

%% fcn_INTERNAL_shadowArea
function shadowArea = fcn_INTERNAL_shadowArea(solid, gridLow, voxelSize)
% The solid's mean shadow area, seen from 12 directions around it at
% each of 3 heights above it (10, 30, and 50 degrees): the voxel centers
% are projected onto the plane facing each direction, and the cells of
% voxel size they cover are counted
[cellX, cellY, cellZ] = ind2sub(size(solid), find(solid));
centers = gridLow + ([cellX cellY cellZ] - 1)*voxelSize;
areas = [];
for elevation = deg2rad([10 30 50])
    for azimuth = deg2rad(0:30:330)
        viewDirection = [cos(elevation)*cos(azimuth), cos(elevation)*sin(azimuth), sin(elevation)];
        across = cross(viewDirection, [0 0 1]);
        across = across/norm(across);
        upward = cross(across, viewDirection);
        projected = floor([centers*across', centers*upward']/voxelSize);
        areas(end+1) = size(unique(projected,'rows'),1)*voxelSize^2; %#ok<AGROW>
    end
end
shadowArea = mean(areas);
end % Ends fcn_INTERNAL_shadowArea

%% fcn_INTERNAL_reducedMesh
function levelMesh = fcn_INTERNAL_reducedMesh(vehicleMesh, surfaceFV, targetFaces, outerPoints, outerSource, outerKeys, gridLow, gridSize, voxelSize)
% Reduce the closed surface to targetFaces faces, point its normals out,
% and give each face the attributes of the outer surface under it
reduced = reducepatch(surfaceFV, targetFaces);
newVertices = reduced.vertices;
newFaces = reduced.faces;
corner1 = newVertices(newFaces(:,1),:);
corner2 = newVertices(newFaces(:,2),:);
corner3 = newVertices(newFaces(:,3),:);
if sum(dot(corner1, cross(corner2, corner3, 2), 2)) < 0       % signed volume: outward
    newFaces = newFaces(:,[1 3 2]);
    [corner2, corner3] = deal(corner3, corner2);
end
faceNormals = cross(corner2-corner1, corner3-corner1, 2);
faceNormals = faceNormals ./ max(vecnorm(faceNormals,2,2), eps);

% The vote: seven points on each face; each takes the part of the
% nearest outer point; the face takes the most common part, and the
% attributes of the first of its points with that part
weights = [1/3 1/3 1/3; 2/3 1/6 1/6; 1/6 2/3 1/6; 1/6 1/6 2/3; 1/2 1/2 0; 0 1/2 1/2; 1/2 0 1/2];
Nfaces = size(newFaces,1);
votes = zeros(Nfaces, size(weights,1));
for ith_weight = 1:size(weights,1)
    samplePoints = weights(ith_weight,1)*corner1 + weights(ith_weight,2)*corner2 + weights(ith_weight,3)*corner3;
    votes(:,ith_weight) = fcn_INTERNAL_nearestSource(samplePoints, outerPoints, outerSource, outerKeys, gridLow, gridSize, voxelSize);
end
voteParts = reshape(vehicleMesh.FacePartIndex(votes), Nfaces, []);
winningPart = mode(voteParts, 2);
[~, firstWinner] = max(voteParts==winningPart, [], 2);
chosenSource = votes(sub2ind(size(votes), (1:Nfaces)', firstWinner));

levelMesh = vehicleMesh;
levelMesh.Vertices = newVertices;
levelMesh.Faces = newFaces;
for fieldName = {'FaceMaterialIndex','FaceGroupIndex','FaceLightType','FacePartIndex','FaceColors','FaceAlpha'}
    if isfield(vehicleMesh, fieldName{1}) && size(vehicleMesh.(fieldName{1}),1)==size(vehicleMesh.Faces,1)
        values = vehicleMesh.(fieldName{1});
        levelMesh.(fieldName{1}) = values(chosenSource,:);
    end
end
levelMesh.FaceWheelIndex = zeros(Nfaces,1);          % the level moves as one piece
levelMesh.FaceNormals = faceNormals;
levelMesh.SimplifyInfo = struct('OriginalFaces',size(vehicleMesh.Faces,1), 'FinalFaces',Nfaces, ...
    'OriginalVertices',size(vehicleMesh.Vertices,1), 'FinalVertices',size(newVertices,1), 'VisibilityFlips',NaN, ...
    'Method','closedHull');
end % Ends fcn_INTERNAL_reducedMesh

%% fcn_INTERNAL_nearestSource
function nearestSource = fcn_INTERNAL_nearestSource(queries, outerPoints, outerSource, outerKeys, gridLow, gridSize, voxelSize)
% The source face of the nearest outer point to each query, searching
% the query's voxel and its 26 neighbors (one outer point per voxel); a
% query with none nearby (rare) is searched against all outer points
queryCell = floor((queries - gridLow)/voxelSize) + 1;
queryCell = min(max(queryCell, 2), gridSize-1);
queryKey = sub2ind(gridSize, queryCell(:,1), queryCell(:,2), queryCell(:,3));
[offsetI, offsetJ, offsetK] = ndgrid(-1:1, -1:1, -1:1);
keyOffsets = offsetI(:) + gridSize(1)*offsetJ(:) + gridSize(1)*gridSize(2)*offsetK(:);
candidateKeys = queryKey + keyOffsets';                          % Nq x 27
[found, location] = ismember(candidateKeys, outerKeys);
accumulated = zeros(size(candidateKeys));
for ith_axis = 1:3
    coordinate = nan(size(candidateKeys));
    coordinate(found) = outerPoints(location(found), ith_axis);
    accumulated = accumulated + (coordinate - queries(:,ith_axis)).^2;
end
accumulated(~found) = inf;
[bestDistance, bestColumn] = min(accumulated, [], 2);
bestLocation = location(sub2ind(size(location), (1:size(queries,1))', bestColumn));
nearestSource = zeros(size(queries,1),1);
flagFound = isfinite(bestDistance);
nearestSource(flagFound) = outerSource(bestLocation(flagFound));
for ith_query = find(~flagFound)'
    [~, nearestPoint] = min(sum((outerPoints - queries(ith_query,:)).^2, 2));
    nearestSource(ith_query) = outerSource(nearestPoint);
end
end % Ends fcn_INTERNAL_nearestSource
