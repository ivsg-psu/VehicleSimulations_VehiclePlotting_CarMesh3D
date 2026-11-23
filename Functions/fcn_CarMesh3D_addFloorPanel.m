function vehicleMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, options)
% fcn_CarMesh3D_addFloorPanel

% Adds a flat floor panel under a vehicle: one polygon at the ground
% clearance height, the shape of the lower body seen from above, with
% each wheel's footprint cut out. Downloaded models often have no
% underside (the cabin is open from below), so a reduced mesh can be
% seen through from below or through its windows; the panel closes it.
%
% The panel's outline is the top-down outline (fcn_CarMesh3D_makeOutline2D)
% of the faces whose centers are below LowerBodyHeight (so the mirrors
% and roof are left out), shrunk by Inset so the panel stays hidden
% behind the body's sides. Around each wheel a rectangle is cut out: as
% long as the tire's chord at the panel height plus WheelClearance, and
% as wide as the tire plus WheelClearance (front wheels also get room to
% steer). The panel is flat, except a strip along its edges that rises
% to meet the body's lower edge (BlendWidth). It faces down, is labeled
% trim, and is dark gray.
%
% ONLY WHERE NEEDED (OnlyWhereOpen=true, the default): many downloads
% have their own floor or underbody parts (a muffler, a fuel tank, a
% spare-tire well), and a panel over them hides them. So vertical rays are
% cast up from below, on a grid (GridSpacing), and where a ray meets an
% opaque face (not glass, not a wheel) below CoverHeight, the model is
% already closed there. The panel is kept only where the model is open
% from below, grown by Overlap so it tucks under the model's own floor
% edges; closed patches smaller than MinCovered are ignored (a ray that
% finds a thin rail does not cut a hole). A model with no underside gets
% the whole panel, as before; a model closed everywhere gets none.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh,...
%           (Height=meters), (LowerBodyHeight=meters), (Inset=meters),...
%           (WheelClearance=meters), (SteerRoom=meters),...
%           (BlendWidth=meters), (MaxRise=meters), (Color=rgb),...
%           (Symmetric=flag), (OnlyWhereOpen=flag),...
%           (CoverHeight=meters), (GridSpacing=meters), (Overlap=meters),...
%           (MinCovered=squareMeters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a finished CarMesh3D mesh (labeled and fit to its
%      spec, in the vehicle frame: origin on the ground below the rear
%      axle, X forward, Y left, Z up).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Height: meters above the ground for the panel. Default: the
%      spec's GroundClearance (vehicleMesh.VehicleSpec), or the lowest
%      point of the body (not the wheels) if there is none.
%
%      LowerBodyHeight: meters; the outline is traced from the faces
%      whose centers are below this. Default 0.6.
%
%      Inset: meters the outline is shrunk by. Default 0.03.
%
%      WheelClearance: meters added around each wheel's cutout. Default
%      0.05.
%
%      BlendWidth: meters; a strip this wide along the panel's edges
%      rises to meet the body: each edge point (every 5 cm) goes up to the
%      lowest body corner within 6 cm of it (seen from above), up or
%      down (to at most half the panel height), so the panel joins the
%      body's lower edge with no gap seen from the side; the edge heights
%      are then smoothed along the edge (the median within 15 cm each
%      way, then a running mean), so no spikes rise where a point found a
%      door skin above the rocker.
%      Default 0.15; 0 keeps the panel flat.
%
%      Symmetric: 'auto' (default) builds the left half of the panel
%      (Y >= 0) and mirrors it when the mesh is its own mirror image (90%
%      of its faces have a mirror twin), so both sides of the car meet
%      the panel the same way; true always does; false never does.
%
%      MaxRise: meters; the most an edge point rises above the panel.
%      Default 0.30.
%
%      SteerRoom: meters added to the width of the front wheels' cutouts,
%      so a steered tire does not cut through the panel. Default 0.15.
%
%      Color: the panel's color. Default [0.15 0.15 0.15].
%
%      OnlyWhereOpen: true (default) to add the panel only where the model
%      is open from below (see ONLY WHERE NEEDED above); false for the
%      whole outline.
%
%      CoverHeight: meters; an opaque face below this height closes the
%      model from below. Default 0.6.
%
%      GridSpacing: meters between the rays cast up. Default 0.03.
%
%      Overlap: meters the open area is grown by, under the model's own
%      floor edges. Default 0.03.
%
%      MinCovered: square meters; closed patches smaller than this are
%      ignored. Default 0.01.
%
%      FigNum: a figure to plot the panel (and the mesh, faded) from
%      below. If empty or omitted, no plot is made. If set to -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with the panel's faces added at the end
%      (every per-face field extended), its material named
%      'CarMesh3D_floorPanel', and FloorPanel set to a structure with
%      Height, Polygon (the panel's outline with holes, a polyshape),
%      Faces (the indices of the panel's faces), and OpenFraction (the
%      share of the full outline that was open from below, so got the
%      panel; 1 with OnlyWhereOpen=false). With OnlyWhereOpen=true, a
%      model closed everywhere gets no faces: FloorPanel.Faces is empty.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_makeOutline2D, fcn_CarMesh3D_plotVehicle (only if
%      plotting); polyshape, polybuffer, triangulation (MATLAB base)
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
%       load(vehicleFiles.MeshFile, 'vehicleMesh');
%       vehicleMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_addFloorPanel.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addFloorPanel
%   % * First write: downloads with no underside could be seen through
%   %   % from below and through the windows (2010 Toyota Camry)
%   % * BlendWidth, MaxRise: the panel's edges rise to meet the body (a
%   %   % flat panel left a gap below the body's lower edge, seen from the
%   %   % side)
%   % * The edge heights are smoothed along the edge (a running minimum
%   %   % over 15 cm each way, then a running mean): edge points that found
%   %   % a door skin above the rocker made dark spikes along the bottoms
%   %   % of the doors (2010 Toyota Camry)
%   % * The edge follows the body's lowest edge down as well as up, and
%   %   % the running minimum is now a running median: the minimum held the
%   %   % edge below the body where the body's edge rises, and a sill lip
%   %   % hanging below the panel left a slit (2021 Subaru Outback; found by
%   %   % the see-through check of fcn_CarMesh3D_compareToOriginal)
%   % * Points on a mirrored panel's center cut are interpolated from
%   %   % their neighbors (held at the panel height, they made a V notch)
%   % * The wheel cutouts run out past the body's outline, and edge points
%   %   % along them stay at the panel height (a strip outboard of the rear
%   %   % tires rose to the wheel arch and hung in front of the tires, like
%   %   % mud flaps; 2014 CR-V)
%   % * Symmetric: a mirrored car gets a mirrored panel (built as one
%   %   % piece, the panel met the two sills differently, and the inside of
%   %   % one sill showed from below; 2021 Subaru Outback)
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addFloorPanel
%   % * OnlyWhereOpen (default true), CoverHeight, GridSpacing, Overlap,
%   %   % MinCovered: the panel only where the model is open from below
%   %   % (it covered the muffler and the underbody of the 2009 Honda Fit)
%   % * Symmetric: when the open area differs between the sides (a
%   %   % muffler on one side), each half is built by itself, the right
%   %   % half as a mirror image, so the sides still meet the panel the
%   %   % same way where they match

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addFloorPanel
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.Height = []              % meters; [] for the spec's ground clearance
    options.LowerBodyHeight = 0.6    % meters: trace the outline from faces below this
    options.Inset = 0.03             % meters the outline is shrunk by
    options.WheelClearance = 0.05    % meters added around each wheel's cutout
    options.SteerRoom = 0.15         % meters added to the front cutouts' width
    options.BlendWidth = 0.15        % meters: the edge strip that rises to meet the body
    options.MaxRise = 0.30           % meters: the most an edge rises above the panel
    options.Color = [0.15 0.15 0.15] % The panel's color
    options.Symmetric = 'auto'       % Build the left half and mirror it: 'auto', true, false
    options.OnlyWhereOpen = true     % Only where the model is open from below
    options.CoverHeight = 0.6        % meters: opaque faces below this close the model from below
    options.GridSpacing = 0.03       % meters between the rays cast up
    options.Overlap = 0.03           % meters the open area is grown by
    options.MinCovered = 0.01        % square meters: smaller closed patches are ignored
    options.FigNum = []              % Figure to plot into; [] for no plot, -1 for fast mode
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

        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces','PartNames','FacePartIndex','FaceWheelIndex'})))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, PartNames, FacePartIndex, FaceWheelIndex)');
        end
        if ~isempty(options.Height) && ~(isnumeric(options.Height) && isscalar(options.Height) && options.Height >= 0)
            error('Height must be a height of 0 or more, or empty');
        end
        for fieldName = {'LowerBodyHeight','Inset','WheelClearance','SteerRoom','BlendWidth','MaxRise','CoverHeight','Overlap','MinCovered'}
            thisValue = options.(fieldName{1});
            if ~(isnumeric(thisValue) && isscalar(thisValue) && thisValue >= 0)
                error('%s must be a distance of 0 or more', fieldName{1});
            end
        end
        if ~(isnumeric(options.GridSpacing) && isscalar(options.GridSpacing) && options.GridSpacing > 0)
            error('GridSpacing must be a distance above 0');
        end
        if ~((islogical(options.OnlyWhereOpen) || isnumeric(options.OnlyWhereOpen)) && isscalar(options.OnlyWhereOpen))
            error('OnlyWhereOpen must be true or false');
        end
        if ~(isnumeric(options.Color) && numel(options.Color)==3)
            error('Color must be an [r g b] triple');
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

Nfaces = size(vehicleMesh.Faces,1);
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
faceCenters = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
flagWheel = vehicleMesh.FaceWheelIndex(:) > 0;

% The panel's height
panelHeight = options.Height;
if isempty(panelHeight)
    if isfield(vehicleMesh,'VehicleSpec') && isfield(vehicleMesh.VehicleSpec,'GroundClearance') && ~isempty(vehicleMesh.VehicleSpec.GroundClearance)
        panelHeight = vehicleMesh.VehicleSpec.GroundClearance;
    else
        bodyCorners = unique(faces(~flagWheel,:));
        panelHeight = min(vertices(bodyCorners,3));
    end
end

% The lower body's outline seen from above (with the wheels, for their
% footprints): the faces below LowerBodyHeight, and all wheel faces
flagLower = faceCenters(:,3) < options.LowerBodyHeight | flagWheel;
lowerMesh = vehicleMesh;
for fieldName = reshape(fieldnames(vehicleMesh),1,[])
    thisValue = vehicleMesh.(fieldName{1});
    if ~strcmp(fieldName{1},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==Nfaces
        lowerMesh.(fieldName{1}) = thisValue(flagLower,:);
    end
end
outlineWarning = warning('off','CarMesh3D:asymmetricOutline');   % (only the body and wheels are used here)
lowerOutline = fcn_CarMesh3D_makeOutline2D(lowerMesh, FigNum=-1);
warning(outlineWarning);

% The panel: the body outline shrunk by Inset, less each wheel's cutout
warningState = warning('off','MATLAB:polyshape:repairedBySimplify');   % (a traced outline can touch itself)
panelShape = polyshape(lowerOutline.Body(1:end-1,:), 'Simplify', true);
warning(warningState);
if options.Inset > 0
    panelShape = polybuffer(panelShape, -options.Inset, 'JointType','miter');
end
wheelCutouts = polyshape();   % (all the cutouts, for the edge heights below)
for ith_wheel = 1:numel(lowerOutline.Wheels)
    thisWheel = lowerOutline.Wheels(ith_wheel);
    tireRadius = thisWheel.Length/2;
    % (the tire's chord at the panel height, or its whole diameter if
    % the panel is above the axle)
    if panelHeight < tireRadius
        cutLength = 2*sqrt(max(tireRadius^2 - (tireRadius - panelHeight)^2, 0));
    else
        cutLength = 2*tireRadius;
    end
    cutLength = cutLength + 2*options.WheelClearance;
    cutWidth = thisWheel.Width + 2*options.WheelClearance;
    if thisWheel.Steers
        cutLength = max(cutLength, 2*tireRadius + 2*options.WheelClearance);   % (a steered tire swings)
        cutWidth = cutWidth + 2*options.SteerRoom;
    end
    cutX = thisWheel.Center(1) + [-1 1 1 -1]*cutLength/2;
    cutY = thisWheel.Center(2) + [-1 -1 1 1]*cutWidth/2;
    % (the cutout runs out past the body's outline on the wheel's side:
    % a strip of panel left outboard of the tire rose to the wheel arch and
    % hung in front of the tire, like a mud flap; 2014 CR-V's rear wheels)
    if thisWheel.Center(2) >= 0
        cutY(3:4) = max(cutY(3:4), thisWheel.Center(2) + 5);
    else
        cutY(1:2) = min(cutY(1:2), thisWheel.Center(2) - 5);
    end
    panelShape = subtract(panelShape, polyshape(cutX, cutY));
    wheelCutouts = union(wheelCutouts, polyshape(cutX, cutY));
end
% Only where the model is open from below: rays cast up find where the
% model has its own floor (or underbody parts), and the panel is cut away
% there
openFraction = 1;
if options.OnlyWhereOpen && panelShape.NumRegions > 0
    fullArea = area(panelShape);
    if isfield(vehicleMesh,'FaceAlpha')
        flagOpaque = vehicleMesh.FaceAlpha(:) >= 0.99;
    else
        flagOpaque = true(Nfaces,1);
    end
    openShape = fcn_INTERNAL_openFromBelow(vertices, faces(flagOpaque & ~flagWheel,:), panelShape, ...
        options.CoverHeight, options.GridSpacing, options.Overlap, options.MinCovered);
    panelShape = intersect(panelShape, openShape);
    panelShape = fcn_INTERNAL_dropSmall(panelShape, options.MinCovered);
    openFraction = area(panelShape)/max(fullArea, eps);
end
% (a mirrored car: the left half, mirrored after it is built)
fullShape = panelShape;
flagSymmetric = false;
if islogical(options.Symmetric) || isnumeric(options.Symmetric)
    flagSymmetric = logical(options.Symmetric);
elseif strcmpi(options.Symmetric,'auto')
    [~, twinDistance] = knnsearch(faceCenters, faceCenters.*[1 -1 1]);
    flagSymmetric = mean(twinDistance < 1e-4) >= 0.9;
end
if fullShape.NumRegions == 0
    if options.OnlyWhereOpen
        % (closed everywhere from below: the model has its own floor)
        vehicleMesh.FloorPanel = struct('Height',panelHeight, 'Polygon',fullShape, 'Faces',zeros(0,1), 'OpenFraction',0);
    else
        warning('CarMesh3D:noFloorPanel', 'No floor panel was added: the outline was empty after the inset and the wheel cutouts.');
    end
    return;
end

% The body's lower corners, which the panel's edges rise to meet
bodyCorners = unique(faces(~flagWheel & faceCenters(:,3) < options.LowerBodyHeight,:));
bodyPoints = vertices(bodyCorners,:);
if flagSymmetric
    % The left half, built and then mirrored; if the right half's open
    % area is not the left's mirror image (a muffler on one side), the
    % right half is built by itself, as a mirror image, and mirrored back
    [shapeX, shapeY] = boundingbox(fullShape);
    leftBox = polyshape(shapeX([1 2 2 1]) + [-1 1 1 -1], [0 0 max(shapeY(2),0)+1 max(shapeY(2),0)+1]);
    mirroredFull = fcn_INTERNAL_mirror(fullShape);
    leftShape = intersect(fullShape, leftBox);
    rightShape = intersect(mirroredFull, leftBox);   % (the right half, mirrored onto the left)
    [leftVertices, leftFaces] = fcn_INTERNAL_buildPanel(leftShape, fullShape, true, bodyPoints, wheelCutouts, panelHeight, options);
    differenceArea = area(xor(leftShape, rightShape));
    if differenceArea < 1e-4
        rightVertices = leftVertices;
        rightFaces = leftFaces;
    else
        [rightVertices, rightFaces] = fcn_INTERNAL_buildPanel(rightShape, mirroredFull, true, bodyPoints.*[1 -1 1], ...
            fcn_INTERNAL_mirror(wheelCutouts), panelHeight, options);
    end
    % (the right half: mirrored, corner order reversed so it still faces down)
    panelVertices = [leftVertices; rightVertices.*[1 -1 1]];
    panelFaces = [leftFaces; rightFaces(:,[1 3 2]) + size(leftVertices,1)];
else
    [panelVertices, panelFaces] = fcn_INTERNAL_buildPanel(fullShape, fullShape, false, bodyPoints, wheelCutouts, panelHeight, options);
end
Npanel = size(panelFaces,1);
if Npanel == 0
    % (the open area was too thin to triangulate)
    vehicleMesh.FloorPanel = struct('Height',panelHeight, 'Polygon',polyshape(), 'Faces',zeros(0,1), 'OpenFraction',0);
    return;
end

% Add it: every per-face field gets rows (zeros, then set below)
newIndices = (Nfaces+1:Nfaces+Npanel)';
for fieldName = reshape(fieldnames(vehicleMesh),1,[])
    thisValue = vehicleMesh.(fieldName{1});
    if any(strcmp(fieldName{1},{'Vertices','Faces'})) || ~(isnumeric(thisValue) || islogical(thisValue)) || size(thisValue,1)~=Nfaces
        continue;
    end
    vehicleMesh.(fieldName{1}) = [thisValue; zeros(Npanel, size(thisValue,2), 'like', thisValue)];
end
vehicleMesh.Faces = [faces; panelFaces + size(vertices,1)];
vehicleMesh.Vertices = [vertices; panelVertices];

trimIndex = find(strcmp(vehicleMesh.PartNames,'trim'), 1);
if isempty(trimIndex)
    vehicleMesh.PartNames{end+1} = 'trim';
    trimIndex = numel(vehicleMesh.PartNames);
end
vehicleMesh.FacePartIndex(newIndices) = trimIndex;
if isfield(vehicleMesh,'FaceColors')
    vehicleMesh.FaceColors(newIndices,:) = repmat(options.Color(:)', Npanel, 1);
end
if isfield(vehicleMesh,'FaceAlpha')
    vehicleMesh.FaceAlpha(newIndices) = 1;
end
if isfield(vehicleMesh,'FaceNormals')
    panelNormals = cross(panelVertices(panelFaces(:,2),:) - panelVertices(panelFaces(:,1),:), ...
        panelVertices(panelFaces(:,3),:) - panelVertices(panelFaces(:,1),:), 2);
    vehicleMesh.FaceNormals(newIndices,:) = panelNormals./max(vecnorm(panelNormals,2,2), eps);
end
if isfield(vehicleMesh,'MaterialNames') && isfield(vehicleMesh,'FaceMaterialIndex')
    vehicleMesh.MaterialNames{end+1} = 'CarMesh3D_floorPanel';
    vehicleMesh.FaceMaterialIndex(newIndices) = numel(vehicleMesh.MaterialNames);
    if isfield(vehicleMesh,'MaterialColors') && size(vehicleMesh.MaterialColors,1)==numel(vehicleMesh.MaterialNames)-1
        vehicleMesh.MaterialColors(end+1,:) = options.Color(:)';
    end
    if isfield(vehicleMesh,'MaterialAlpha') && numel(vehicleMesh.MaterialAlpha)==numel(vehicleMesh.MaterialNames)-1
        vehicleMesh.MaterialAlpha(end+1) = 1;
    end
end
vehicleMesh.FloorPanel = struct('Height',panelHeight, 'Polygon',fullShape, 'Faces',newIndices, 'OpenFraction',openFraction);

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
    patch('Vertices',vertices, 'Faces',faces, 'FaceColor',[0.75 0.75 0.75], 'EdgeColor','none', 'FaceAlpha',0.15);
    patch('Vertices',panelVertices, 'Faces',panelFaces, 'FaceColor',options.Color, 'EdgeColor',[0.5 0.5 0.5]);
    axis equal;
    grid on;
    view(0,-90);   % (from below)
    xlabel('X [m] (forward)');
    ylabel('Y [m] (left)');
    zlabel('Z [m]');
    title(sprintf('Floor panel at %.3f m (%d faces), seen from below', panelHeight, Npanel));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% fcn_INTERNAL_buildPanel
function [panelVertices, panelFaces] = fcn_INTERNAL_buildPanel(panelShape, fullShape, flagSymmetric, bodyPoints, wheelCutouts, panelHeight, options)
% The panel over one shape (a mirrored car: the left half, Y >= 0, with
% its cut along Y = 0, fullShape being both halves), facing down
panelVertices = zeros(0,3);
panelFaces = zeros(0,3);
if panelShape.NumRegions == 0
    return;
end
% Triangulate it. The panel is flat at the panel height, except a strip
% BlendWidth wide along its edges, which rises to meet the body: each
% edge point (every 5 cm) goes up to the lowest body corner within 6 cm
% of it (seen from above), at most MaxRise above the panel
outerPoints = zeros(0,2);
outerLoops = {};
for ith_boundary = 1:panelShape.NumRegions + panelShape.NumHoles
    [loopX, loopY] = boundary(panelShape, ith_boundary);
    loopPoints = fcn_INTERNAL_densify([loopX loopY], 0.05);
    outerLoops{end+1} = size(outerPoints,1) + (1:size(loopPoints,1))'; %#ok<AGROW>
    outerPoints = [outerPoints; loopPoints]; %#ok<AGROW>
end
innerShape = polybuffer(panelShape, -options.BlendWidth, 'JointType','miter');
innerPoints = zeros(0,2);
innerLoops = {};
if options.BlendWidth > 0 && innerShape.NumRegions > 0
    for ith_boundary = 1:innerShape.NumRegions + innerShape.NumHoles
        [loopX, loopY] = boundary(innerShape, ith_boundary);
        loopPoints = fcn_INTERNAL_densify([loopX loopY], 0.10);
        innerLoops{end+1} = size(outerPoints,1) + size(innerPoints,1) + (1:size(loopPoints,1))'; %#ok<AGROW>
        innerPoints = [innerPoints; loopPoints]; %#ok<AGROW>
    end
end
allPoints = [outerPoints; innerPoints];
constraintEdges = zeros(0,2);
for thisLoop = [outerLoops innerLoops]
    loopIndices = thisLoop{1};
    constraintEdges = [constraintEdges; loopIndices, circshift(loopIndices,-1)]; %#ok<AGROW>
end
[allPoints, ~, pointMap] = unique(round(allPoints*1e6)/1e6, 'rows', 'stable');
constraintEdges = pointMap(constraintEdges);
constraintEdges = constraintEdges(constraintEdges(:,1)~=constraintEdges(:,2),:);
warningState = warning('off','MATLAB:delaunayTriangulation:ConsConsSplitWarnId');
panelTriangles = delaunayTriangulation(allPoints, constraintEdges);
warning(warningState);
panelFaces = panelTriangles.ConnectivityList;
trianglePoints = panelTriangles.Points;
if size(panelFaces,2) ~= 3 || isempty(panelFaces)
    panelFaces = zeros(0,3);
    return;
end
triangleCenters = (trianglePoints(panelFaces(:,1),:) + trianglePoints(panelFaces(:,2),:) + trianglePoints(panelFaces(:,3),:))/3;
panelFaces = panelFaces(isinterior(panelShape, triangleCenters(:,1), triangleCenters(:,2)),:);

% Heights: the panel height, and the edge points raised to the body
pointHeights = repmat(panelHeight, size(trianglePoints,1), 1);
% (a mirrored car's cut along Y = 0, which is not an edge: its points away
% from the panel's front and rear tips)
flagCut = false(size(trianglePoints,1),1);
if flagSymmetric
    flagCut = abs(trianglePoints(:,2)) < 1e-6 & ...
        isinterior(fullShape, trianglePoints(:,1) - 0.02, trianglePoints(:,2)) & ...
        isinterior(fullShape, trianglePoints(:,1) + 0.02, trianglePoints(:,2));
end
flagEdgePoint = ismember(round(trianglePoints*1e6)/1e6, round(outerPoints*1e6)/1e6, 'rows');
edgeIndices = find(flagEdgePoint);
if options.BlendWidth > 0 && ~isempty(bodyPoints) && ~isempty(edgeIndices)
    for ith_point = reshape(edgeIndices,1,[])
        flagNear = vecnorm(bodyPoints(:,1:2) - trianglePoints(ith_point,:), 2, 2) <= 0.06;
        if any(flagNear)
            lowestBody = min(bodyPoints(flagNear,3));
            % (up or down to the body's lowest edge: a sill lip that hangs
            % below the panel height is met too, so no slit shows under it;
            % never below half the panel height)
            pointHeights(ith_point) = min(max(lowestBody, 0.5*panelHeight), panelHeight + options.MaxRise);
        end
    end
    % (along each edge loop: the median height within 15 cm each way, then
    % a running mean, so the edge follows the body's lower line without
    % spikes where a point found a door skin above the rocker; a running
    % minimum here kept the edge below the body where the body's edge
    % rises, leaving a slit)
    for thisLoop = outerLoops
        loopPoints = outerPoints(thisLoop{1},:);
        [~, loopIndex] = ismember(round(loopPoints*1e6)/1e6, round(trianglePoints*1e6)/1e6, 'rows');
        loopIndex = loopIndex(loopIndex>0);
        if numel(loopIndex) < 5
            continue;
        end
        loopIndex = loopIndex(:);
        cutInLoop = flagCut(loopIndex);
        if any(cutInLoop) && ~all(cutInLoop)
            % (a mirrored car: the edge is an open chain from tip to tip,
            % padded at each end with its own mirror image, which is what
            % the other half continues as; the cut itself is not an edge)
            firstAfterCut = find(~cutInLoop & circshift(cutInLoop,1), 1);
            loopIndex = circshift(loopIndex, -(firstAfterCut-1));
            cutInLoop = circshift(cutInLoop, -(firstAfterCut-1));
            chainIndex = loopIndex(~cutInLoop);
            numPad = min(6, numel(chainIndex)-1);
            chainHeights = pointHeights(chainIndex);
            paddedHeights = [flipud(chainHeights(2:numPad+1)); chainHeights; flipud(chainHeights(end-numPad:end-1))];
            paddedHeights = fcn_INTERNAL_circularFilter(paddedHeights, 3, 'median');
            paddedHeights = fcn_INTERNAL_circularFilter(paddedHeights, 2, 'mean');
            pointHeights(chainIndex) = paddedHeights(numPad+1:end-numPad);
            continue;
        end
        loopHeights = pointHeights(loopIndex);
        loopHeights = fcn_INTERNAL_circularFilter(loopHeights, 3, 'median');
        loopHeights = fcn_INTERNAL_circularFilter(loopHeights, 2, 'mean');
        pointHeights(loopIndex) = loopHeights;
    end
    % (a mirrored car's cut along Y = 0 is not an edge: its points take
    % the heights between their neighbors and the neighbors' mirror
    % images, as a panel built in one piece would have; held at the panel
    % height, they left a V-shaped notch at the center of each blend strip)
    if flagSymmetric && any(flagCut) && sum(~flagCut) >= 3
        knownPoints = trianglePoints(~flagCut,:);
        knownHeights = pointHeights(~flagCut);
        flagOffAxis = abs(knownPoints(:,2)) > 1e-6;   % (points on Y = 0 are not mirrored: they would repeat)
        heightInterpolant = scatteredInterpolant([knownPoints; knownPoints(flagOffAxis,:).*[1 -1]], ...
            [knownHeights; knownHeights(flagOffAxis)], 'linear', 'nearest');
        pointHeights(flagCut) = heightInterpolant(trianglePoints(flagCut,1), trianglePoints(flagCut,2));
    end
    % (edge points along a wheel cutout stay at the panel height: the
    % nearest body there is the wheel arch above the tire, and an edge
    % raised to it hung in front of the tire, like a skirt; 2014 CR-V)
    if wheelCutouts.NumRegions > 0
        nearCutout = isinterior(polybuffer(wheelCutouts, 0.03, 'JointType','miter'), trianglePoints(:,1), trianglePoints(:,2));
        pointHeights(flagEdgePoint & nearCutout) = panelHeight;
    end
end
panelVertices = [trianglePoints, pointHeights];

% Facing down
upNormals = cross(panelVertices(panelFaces(:,2),:) - panelVertices(panelFaces(:,1),:), ...
    panelVertices(panelFaces(:,3),:) - panelVertices(panelFaces(:,1),:), 2);
flagUp = upNormals(:,3) > 0;
panelFaces(flagUp,:) = panelFaces(flagUp,[1 3 2]);
panelVertices = [trianglePoints, pointHeights];

% Facing down
upNormals = cross(panelVertices(panelFaces(:,2),:) - panelVertices(panelFaces(:,1),:), ...
    panelVertices(panelFaces(:,3),:) - panelVertices(panelFaces(:,1),:), 2);
flagUp = upNormals(:,3) > 0;
panelFaces(flagUp,:) = panelFaces(flagUp,[1 3 2]);
end % Ends fcn_INTERNAL_buildPanel

%% fcn_INTERNAL_openFromBelow
function openShape = fcn_INTERNAL_openFromBelow(vertices, faces, panelShape, coverHeight, spacing, overlap, minCovered)
% Where the model is open from below: a grid of vertical rays under the
% panel's outline; a ray is blocked if it meets one of the faces (opaque,
% not wheels) below coverHeight. The open cells, traced into a polyshape,
% grown by overlap, with closed patches smaller than minCovered filled in
[boxX, boxY] = boundingbox(panelShape);
% (three steps of margin: the grid's border is marked open, so every
% traced loop closes, and the margin keeps that open border, grown by the
% overlap, outside the outline)
gridX = (boxX(1) - 3*spacing):spacing:(boxX(2) + 3*spacing);
gridY = (boxY(1) - 3*spacing):spacing:(boxY(2) + 3*spacing);
numX = numel(gridX);
numY = numel(gridY);
closed = false(numX, numY);
% (only faces that reach below coverHeight)
cornerZ = reshape(vertices(faces(:),3), [], 3);
faces = faces(min(cornerZ,[],2) < coverHeight,:);
if ~isempty(faces)
    cornerX = reshape(vertices(faces(:),1), [], 3);
    cornerY = reshape(vertices(faces(:),2), [], 3);
    cornerZ = reshape(vertices(faces(:),3), [], 3);
    % (each face's grid points: the cells its top-down bounding box covers)
    firstX = max(1, ceil((min(cornerX,[],2) - gridX(1))/spacing) + 1);
    lastX  = min(numX, floor((max(cornerX,[],2) - gridX(1))/spacing) + 1);
    firstY = max(1, ceil((min(cornerY,[],2) - gridY(1))/spacing) + 1);
    lastY  = min(numY, floor((max(cornerY,[],2) - gridY(1))/spacing) + 1);
    countX = max(lastX - firstX + 1, 0);
    countY = max(lastY - firstY + 1, 0);
    numPairs = countX.*countY;
    keep = numPairs > 0;
    blockSize = 2e6;   % (pairs per block, to bound the memory)
    faceList = find(keep);
    pairsBefore = cumsum(numPairs(faceList)) - numPairs(faceList);
    blockOfFace = floor(pairsBefore/blockSize);
    for thisBlock = reshape(unique(blockOfFace),1,[])
        theseFaces = faceList(blockOfFace==thisBlock);
        pairFace = repelem(theseFaces, numPairs(theseFaces));
        pairOffset = (1:numel(pairFace))' - repelem(cumsum([0; numPairs(theseFaces(1:end-1))]), numPairs(theseFaces));
        pairOffset = pairOffset - 1;
        pairIX = firstX(pairFace) + mod(pairOffset, countX(pairFace));
        pairIY = firstY(pairFace) + floor(pairOffset./countX(pairFace));
        pointX = gridX(pairIX)';
        pointY = gridY(pairIY)';
        ax = cornerX(pairFace,1); ay = cornerY(pairFace,1);
        bx = cornerX(pairFace,2); by = cornerY(pairFace,2);
        cx = cornerX(pairFace,3); cy = cornerY(pairFace,3);
        twiceArea = (bx - ax).*(cy - ay) - (cx - ax).*(by - ay);
        weightA = ((bx - pointX).*(cy - pointY) - (cx - pointX).*(by - pointY))./twiceArea;
        weightB = ((cx - pointX).*(ay - pointY) - (ax - pointX).*(cy - pointY))./twiceArea;
        weightC = 1 - weightA - weightB;
        inside = abs(twiceArea) > 1e-12 & weightA >= -1e-9 & weightB >= -1e-9 & weightC >= -1e-9;
        hitZ = weightA.*cornerZ(pairFace,1) + weightB.*cornerZ(pairFace,2) + weightC.*cornerZ(pairFace,3);
        blocked = inside & hitZ < coverHeight;
        closed(sub2ind([numX numY], pairIX(blocked), pairIY(blocked))) = true;
    end
end
% The open cells, traced (a border of open cells all around, so every
% loop closes)
openGrid = double(~closed);
openGrid([1 end],:) = 1;
openGrid(:,[1 end]) = 1;
contourMatrix = contourc(gridX, gridY, openGrid', [0.5 0.5]);
loopsX = {};
loopsY = {};
column = 1;
while column < size(contourMatrix,2)
    numPoints = contourMatrix(2,column);
    loopsX{end+1} = contourMatrix(1, column+1:column+numPoints); %#ok<AGROW>
    loopsY{end+1} = contourMatrix(2, column+1:column+numPoints); %#ok<AGROW>
    column = column + numPoints + 1;
end
warningState = warning('off','MATLAB:polyshape:repairedBySimplify');
outerBox = polyshape(gridX([1 end end 1]), gridY([1 1 end end]));
if isempty(loopsX)
    closedShape = polyshape();
else
    closedShape = polyshape(loopsX, loopsY, 'Simplify', true);   % (the closed patches)
end
warning(warningState);
% (closed patches too small to matter are dropped; the rest shrink by
% overlap, so the open area grows under the model's own floor edges)
closedShape = fcn_INTERNAL_dropSmall(closedShape, minCovered);
if closedShape.NumRegions > 0 && overlap > 0
    closedShape = polybuffer(closedShape, -overlap, 'JointType','miter');
end
openShape = subtract(outerBox, closedShape);
end % Ends fcn_INTERNAL_openFromBelow

%% fcn_INTERNAL_mirror
function mirrored = fcn_INTERNAL_mirror(shape)
% The shape's mirror image across Y = 0 (each region's outline and holes
% mirrored one at a time, so holes stay holes)
mirrored = polyshape();
if shape.NumRegions == 0
    return;
end
warningState = warning('off','MATLAB:polyshape:repairedBySimplify');
for thisRegion = reshape(regions(shape),1,[])
    outline = rmholes(thisRegion);
    regionShape = polyshape(outline.Vertices(:,1), -outline.Vertices(:,2));
    for thisHole = reshape(holes(thisRegion),1,[])
        regionShape = subtract(regionShape, polyshape(thisHole.Vertices(:,1), -thisHole.Vertices(:,2)));
    end
    mirrored = union(mirrored, regionShape);
end
warning(warningState);
end % Ends fcn_INTERNAL_mirror

%% fcn_INTERNAL_dropSmall
function shape = fcn_INTERNAL_dropSmall(shape, minArea)
% The shape without its regions smaller than minArea
if shape.NumRegions == 0
    return;
end
pieces = regions(shape);
keep = arrayfun(@area, pieces) >= minArea;
if ~any(keep)
    shape = polyshape();
elseif ~all(keep)
    shape = union(pieces(keep));
end
end % Ends fcn_INTERNAL_dropSmall

%% fcn_INTERNAL_densify
function points = fcn_INTERNAL_densify(points, spacing)
% A closed loop of points with extra points added so no edge is longer
% than spacing (the loop is not repeated at its end)
points = points(all(isfinite(points),2),:);
nextPoints = circshift(points,-1,1);
edgeLength = vecnorm(nextPoints - points, 2, 2);
numSteps = max(1, ceil(edgeLength/spacing));
allPoints = cell(size(points,1),1);
for ith_edge = 1:size(points,1)
    steps = (0:numSteps(ith_edge)-1)'/numSteps(ith_edge);
    allPoints{ith_edge} = points(ith_edge,:) + steps.*(nextPoints(ith_edge,:) - points(ith_edge,:));
end
points = vertcat(allPoints{:});
end % Ends fcn_INTERNAL_densify

%% fcn_INTERNAL_circularFilter
function values = fcn_INTERNAL_circularFilter(values, halfWidth, kind)
% A running minimum, median, or mean over a closed loop (halfWidth points
% each way)
values = values(:);
numValues = numel(values);
shifted = zeros(numValues, 2*halfWidth+1);
for ith_shift = -halfWidth:halfWidth
    shifted(:, ith_shift+halfWidth+1) = circshift(values, ith_shift);
end
if strcmp(kind,'min')
    values = min(shifted, [], 2);
elseif strcmp(kind,'median')
    values = median(shifted, 2);
else
    values = mean(shifted, 2);
end
end % Ends fcn_INTERNAL_circularFilter
