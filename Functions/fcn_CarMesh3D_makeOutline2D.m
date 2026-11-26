function vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh, options)
% fcn_CarMesh3D_makeOutline2D

% Makes a vehicle's top-down (2D) outlines from its finished mesh, for
% plotting and animating vehicles in 2D: XY polygons, not XYZ meshes.
% The outlines are in the vehicle frame (meters; origin on the ground
% below the rear axle, X forward, Y left), so a 2D pose [x y yaw] places
% them exactly as the mesh would be placed.
%
% The outlines are:
%   Body: the whole vehicle seen from above (everything but the wheels,
%       mirrors included): one closed polygon, found slice by slice along
%       X (the widest point of the mesh at each X), then thinned to
%       within Tolerance.
%   Windows: each piece of glass that faces up (windshield, sunroof, rear
%       window; side windows are seen edge-on from above, so they are
%       left out), one polygon each, from front to rear.
%   Wheels: each wheel's footprint seen from above: its center, length
%       (the tire's diameter), and width; a rectangle around the center
%       that the front wheels turn by the steer angle.
%   Lights: each lamp (headlights, turn signals, running, tail, backup;
%       and the unswitched ones as 'other'), by type, side, and lamp:
%       the convex outline of its faces seen from above. A lamp is the
%       faces of one type and side that touch (corners at the same place)
%       or come within LampGap of each other, so a lamp made of many
%       separate pieces (a lens, a reflector, a bulb) is one outline, while
%       a turn signal's front, rear, and mirror lamps stay separate.
%
%   Interior: the interior OBJECTS seen from above, one outline each:
%       the driver's seat, the passenger's seat and the steering wheel
%       (found by fcn_CarMesh3D_findInteriorObjects; stored in the mesh as
%       LabelFaceInterior and LabelInteriorNames, or given with
%       InteriorObjects=). Only these objects are outlined (Sean,
%       2026-11-24 09:20: "update the 2D views accordingly using only the
%       seats and steering wheel as the interior objects"). A mesh with no
%       interior objects but an 'interior' part (the older voxel labeling,
%       fcn_CarMesh3D_labelInterior) gets each connected piece of that
%       part instead, front to rear. Interior outlines are NOT made
%       symmetric: the steering wheel is on one side.
%
% SYMMETRY. Vehicles are (nearly always) mirror images about their
% centerline (the XZ plane), but downloaded models are not always: a
% window piece may be missing a corner, or one lamp may be labeled and
% its twin not. With FlagSymmetric=true (the default) each outline is made
% symmetric by joining it with its mirror image: the body takes the wider
% side at each slice; each window is joined with the mirror image of its
% twin (a centered window, with its own); each lamp is joined with its
% twin of the same type on the other side; and a window or lamp with no
% twin gets a mirrored copy. Window pieces that overlap after this are
% joined into one window (decimated glass is often split into slivers).
% Nothing is ever cut away. How much each
% outline had to change is reported in vehicleOutline.Symmetry, and a
% warning ('CarMesh3D:asymmetricOutline') names any that changed by more
% than SymmetryTolerance: those are worth a look at the labels (often a
% piece labeled on one side only). (The steering wheel, when interior
% outlines are added, will be the one exception.)
%
% FORMAT:
%
%       vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh,...
%           (SliceSpacing=meters), (Tolerance=meters),...
%           (MinWindowArea=squareMeters), (FlagSymmetric=flag),...
%           (SymmetryTolerance=fraction), (LampGap=meters),...
%           (MinInteriorArea=squareMeters), (InteriorObjects=found),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a finished CarMesh3D mesh (labeled and fit to its
%      spec, origin below the rear axle).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SliceSpacing: meters between the slices along X that find the body
%      outline. Default 0.01.
%
%      Tolerance: meters: the most a thinned outline may stray from the
%      full one (Douglas-Peucker). Default 0.01.
%
%      MinWindowArea: square meters: smaller pieces of upward glass are
%      dropped. Default 0.05.
%
%      FlagSymmetric: true (default) to make every outline symmetric about
%      the centerline (see SYMMETRY above); false to keep them as traced.
%
%      SymmetryTolerance: the fraction of an outline's area (for the body,
%      of its width) above which a change made for symmetry is warned
%      about. Default 0.05 (5 percent). The changes are measured either
%      way, so with FlagSymmetric=false the warning still names the outlines
%      that are not symmetric.
%
%      LampGap: meters; pieces of lamps of one type and side closer than
%      this are one lamp. Default 0.02.
%
%      MinInteriorArea: square meters; smaller interior pieces (seen from
%      above) are dropped. Default 0.01.
%
%      InteriorObjects: the interior objects found in this mesh, as
%      fcn_CarMesh3D_findInteriorObjects returns them (DriverSeat,
%      PassengerSeat, SteeringWheel, each with Found and Faces: face
%      numbers of this mesh). Used in place of the mesh's own
%      LabelFaceInterior. Default [] (the mesh's own, if any).
%
%      FigNum: a figure to plot the outlines, in two panels: alone (as a
%      2D plot would draw them) and over the mesh seen from above
%      (faded). If empty or omitted, no plot is made. If set to -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleOutline: a structure with
%           Name, Units ('m'), Frame (the mesh's), Source
%           Body: N x 2 [x y], a closed polygon (first point repeated at
%               the end), counterclockwise
%           Windows: a structure array with Name ('glass 1', ... front to
%               rear) and Polygon (closed, counterclockwise)
%           Wheels: a 4 x 1 structure array with Name ('FL','FR','RL','RR'),
%               Center [x y], Length (diameter), Width, Steers (true for
%               the front wheels), and Rectangle (5 x 2, closed, around
%               [0 0]: add the center after turning it by the steer angle)
%           Interior: a structure array with Name ('driver seat',
%               'passenger seat', 'steering wheel'; or, for a mesh with
%               only an 'interior' part, 'interior 1', ... front to rear)
%               and Polygon (closed, counterclockwise); empty if the mesh
%               has neither
%           Lights: a structure array with Type ('headlamp', 'turnSignalLamp',
%               'runningLamp', 'tailBrakeLamp', 'backupLamp', 'highBeamLamp', or 'other'), Side ('left' or
%               'right'), and Polygon (closed, counterclockwise)
%           Length, Width: the body's extent in X and Y (before thinning)
%           PointCount: the number of points in all the polygons
%           Symmetry: how far the traced outlines were from symmetric:
%               Symmetric (the option used), Body (the largest difference
%               between the left and right half-widths, as a fraction of
%               the width), Windows and Lights (one value per outline, in
%               the same order: the fraction of the symmetric outline's
%               area that its mirror image added; 1 for one with no twin
%               on the other side), Added (the names of
%               windows and lamps that had no twin and were mirrored), and
%               Worst (the largest of them all)
%
% DEPENDENCIES:
%
%      convhull, polyshape (MATLAB base)
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
%       load(vehicleFiles.MeshFile, 'vehicleMesh');
%       vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh, FigNum=1);
%       % Place the body at a 2D pose [x y yaw]:
%       pose = [10 5 pi/6];
%       turned = vehicleOutline.Body*[cos(pose(3)) sin(pose(3)); -sin(pose(3)) cos(pose(3))] + pose(1:2);
%       fill(turned(:,1), turned(:,2), [0.05 0.2 0.6]);
%
%       See the script: script_test_fcn_CarMesh3D_makeOutline2D.m for a
%       full test suite.
%
% This function was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * The plot has two panels: the outlines alone, and over the mesh
%   % * Symmetric (default true) and SymmetryTolerance options: every outline is made symmetric about the centerline by joining it with its mirror image (nothing is cut away); the changes are reported in the new Symmetry field, with a warning (CarMesh3D:asymmetricOutline) for large ones
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * The symmetry warning lists each lamp once per side and type
%   %   % (pieces counted), not every traced piece

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * Lamps are grouped by corner position and by LampGap (default
%   %   % 0.02 m), not by shared corner indices: the 2009 Honda Fit's
%   %   % lamps, whose faces share no corners, came out as 120 to 140
%   %   % outlines each (522 in all), one per few triangles
%   % * Interior: the outline of each piece of the 'interior' part
%   %   % (seats, steering wheel, dash), not made symmetric

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * A color for 'highBeamLamp' lamps in the debug plot (Sean, 03:27)

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * Measures the vehicle as it is shown: hidden faces (LabelFaceHiddenSet)
%   %   % are left out (fcn_CarMesh3D_visibleMesh; Sean, 04:17)
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * The check plot colors the newer lamp types (fcn_CarMesh3D_lampTypes;
%   %   % Sean, task 8)

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * Interior: only the interior objects, one outline each (driver
%   %   % seat, passenger seat, steering wheel), from the mesh's
%   %   % LabelFaceInterior or the new option InteriorObjects (the
%   %   % result of fcn_CarMesh3D_findInteriorObjects); the older
%   %   % 'interior' part pieces only for a mesh without objects (Sean,
%   %   % 2026-11-24 09:20)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeOutline2D
%   % * Side-window outlines (seen from the side, for a 2D side view); door and hood seams; interior outlines (the steering wheel is not mirrored)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.SliceSpacing = 0.01    % meters between slices along X (body outline)
    options.Tolerance = 0.01       % meters: how far a thinned outline may stray
    options.MinWindowArea = 0.05   % square meters: smaller upward glass is dropped
    options.LampGap = 0.02         % meters: lamp pieces closer than this are one lamp
    options.MinInteriorArea = 0.01 % square meters: smaller interior pieces are dropped
    options.InteriorObjects = []   % Found interior objects (fcn_CarMesh3D_findInteriorObjects); [] for the mesh's own
    options.FlagSymmetric = true       % true: make every outline symmetric about the centerline
    options.SymmetryTolerance = 0.05   % fraction: warn about outlines changed more than this
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
        % The number of inputs and the option names are checked by the
        % arguments block above


        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces','LabelPartNames','LabelFacePart','FaceWheelIndex'})))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart, FaceWheelIndex)');
        end
        if ~((islogical(options.FlagSymmetric) || isnumeric(options.FlagSymmetric)) && isscalar(options.FlagSymmetric))
            error('Symmetric must be true or false');
        end
        for fieldName = {'SliceSpacing','Tolerance','MinWindowArea','SymmetryTolerance','LampGap','MinInteriorArea'}
            thisValue = options.(fieldName{1});
            if ~(isnumeric(thisValue) && isscalar(thisValue) && thisValue > 0)
                error('%s must be a positive number', fieldName{1});
            end
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
% (interior objects given as an option become the mesh's per-face labels
% first, so they are kept or dropped with their faces just below)
if ~isempty(options.InteriorObjects)
    vehicleMesh = fcn_INTERNAL_labelInteriorObjects(vehicleMesh, options.InteriorObjects);
end
vehicleMesh = fcn_CarMesh3D_visibleMesh(vehicleMesh, FigNum=-1);

vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
partOf = @(partName) vehicleMesh.LabelFacePart==find(strcmp(vehicleMesh.LabelPartNames, partName), 1);

%%%% Body: the widest point at each slice along X (all but the wheels)
bodyFaces = faces(vehicleMesh.FaceWheelIndex==0, :);
[sliceX, sliceLeft, sliceRight] = fcn_INTERNAL_slices(vertices, bodyFaces, options.SliceSpacing);
bodyLength = max(sliceX) - min(sliceX);
bodyWidth = max(sliceLeft) - min(sliceRight);
symmetryBody = max(abs(sliceLeft + sliceRight))/bodyWidth;      % (left and right half-widths differ by this)
if options.FlagSymmetric
    halfWidth = max(sliceLeft, -sliceRight);                     % (the wider side at each slice)
    sliceLeft = halfWidth;
    sliceRight = -halfWidth;
    bodyWidth = 2*max(halfWidth);
end
if options.FlagSymmetric
    % (the right side thinned, then mirrored, so the thinned body stays
    % exactly symmetric)
    rightSide = fcn_INTERNAL_douglasPeucker([sliceX(1) 0; sliceX, sliceRight; sliceX(end) 0], options.Tolerance);
    bodyPolygon = [rightSide; flipud(rightSide(1:end-1,:).*[1 -1])];
    bodyPolygon = bodyPolygon([true; any(diff(bodyPolygon),2)], :);            % (no repeated points)
    if ~isequal(bodyPolygon(1,:), bodyPolygon(end,:))
        bodyPolygon(end+1,:) = bodyPolygon(1,:);
    end
else
    bodyPolygon = [sliceX, sliceRight; flipud(sliceX), flipud(sliceLeft)];   % (right side forward, left side back: counterclockwise)
    bodyPolygon = fcn_INTERNAL_thin([bodyPolygon; bodyPolygon(1,:)], options.Tolerance);
end

%%%% Windows: upward glass, each connected piece
windows = struct('Name',{}, 'Polygon',{});
if any(strcmp(vehicleMesh.LabelPartNames, 'glass'))
    faceNormals = fcn_INTERNAL_faceNormals(vertices, faces);
    upwardGlass = find(partOf('glass') & faceNormals(:,3) > 0.3);
    pieces = fcn_INTERNAL_connectedPieces(faces(upwardGlass,:));
    pieceShapes = {};
    for ith_piece = 1:max([pieces; 0])
        pieceFaces = faces(upwardGlass(pieces==ith_piece), :);
        pieceShape = fcn_INTERNAL_union(vertices, pieceFaces);
        if area(pieceShape) < options.MinWindowArea
            continue;
        end
        % (the largest region of the piece's outline)
        regionsOfPiece = regions(pieceShape);
        [~, largest] = max(area(regionsOfPiece));
        pieceShapes{end+1} = regionsOfPiece(largest); %#ok<AGROW>
    end
    % (each joined with the mirror image of its twin; twinless ones mirrored)
    [windowShapes, symmetryWindows, addedWindows] = fcn_INTERNAL_symmetricShapes(pieceShapes, options.FlagSymmetric);
    windowPolygons = {};
    windowCenters = [];
    for ith_shape = 1:numel(windowShapes)
        outline = rmholes(windowShapes{ith_shape}).Vertices;           % (the outer edge only: slivers joined can leave slits)
        outline = outline(~any(isnan(outline),2), :);
        if fcn_INTERNAL_signedArea(outline) < 0
            outline = flipud(outline);
        end
        windowPolygons{end+1} = fcn_INTERNAL_thin([outline; outline(1,:)], options.Tolerance); %#ok<AGROW>
        windowCenters(end+1) = mean(outline(:,1)) + 1e-6*mean(outline(:,2)); %#ok<AGROW>
    end
    [~, frontToRear] = sort(windowCenters, 'descend');
    symmetryWindows = symmetryWindows(frontToRear);
    addedWindows = addedWindows(frontToRear);
    for ith_window = 1:numel(frontToRear)
        windows(ith_window) = struct('Name',sprintf('glass %d', ith_window), 'Polygon',windowPolygons{frontToRear(ith_window)});
    end
end
if ~exist('symmetryWindows','var')
    symmetryWindows = zeros(0,1);
    addedWindows = false(0,1);
end

%%%% Wheels: the footprint of each from above (internal order FL FR RL RR)
wheelNames = {'FL','FR','RL','RR'};
wheels = struct('Name',{}, 'Center',{}, 'Length',{}, 'Width',{}, 'Steers',{}, 'Rectangle',{});
for ith_wheel = 1:4
    wheelVertices = vertices(unique(faces(vehicleMesh.FaceWheelIndex==ith_wheel, :)), :);
    if isempty(wheelVertices)
        continue;
    end
    wheelMin = min(wheelVertices(:,1:2), [], 1);
    wheelMax = max(wheelVertices(:,1:2), [], 1);
    wheelLength = wheelMax(1) - wheelMin(1);
    wheelWidth = wheelMax(2) - wheelMin(2);
    wheelRectangle = [-1 -1; 1 -1; 1 1; -1 1; -1 -1].*[wheelLength wheelWidth]/2;
    wheels(end+1) = struct('Name',wheelNames{ith_wheel}, 'Center',(wheelMin + wheelMax)/2, 'Length',wheelLength, ...
        'Width',wheelWidth, 'Steers',ith_wheel <= 2, 'Rectangle',wheelRectangle); %#ok<AGROW>
end

%%%% Lights: by type and side, the convex outline from above
lights = struct('Type',{}, 'Side',{}, 'Polygon',{});
if any(strcmp(vehicleMesh.LabelPartNames, 'light'))
    lightFaces = find(partOf('light'));
    lightTypes = zeros(numel(lightFaces), 1);
    if isfield(vehicleMesh, 'LabelFaceLamp') && ~isempty(vehicleMesh.LabelFaceLamp)
        lightTypes = vehicleMesh.LabelFaceLamp(lightFaces);
    end
    typeNames = {};
    if isfield(vehicleMesh, 'LabelLampNames')
        typeNames = vehicleMesh.LabelLampNames;
    end
    faceCentersY = (vertices(faces(lightFaces,1),2) + vertices(faces(lightFaces,2),2) + vertices(faces(lightFaces,3),2))/3;
    for thisType = unique(lightTypes)'
        if thisType==0 || thisType > numel(typeNames)
            typeName = 'other';
        else
            typeName = typeNames{thisType};
        end
        for sideSign = [1 -1]
            theseFaces = lightFaces(lightTypes==thisType & sign(faceCentersY)==sideSign);
            if isempty(theseFaces)
                continue;
            end
            sideName = 'left';
            if sideSign < 0
                sideName = 'right';
            end
            % (each separate lamp: a turn signal type has front, rear, and
            % mirror lamps; tiny pieces are dropped)
            lampPieces = fcn_INTERNAL_lampGroups(vertices, faces(theseFaces,:), options.LampGap);
            for ith_lamp = 1:max(lampPieces)
                lightPoints = vertices(unique(faces(theseFaces(lampPieces==ith_lamp),:)), 1:2);
                lightPoints = unique(round(lightPoints, 6), 'rows');
                if size(lightPoints,1) < 3 || rank(lightPoints - mean(lightPoints,1)) < 2
                    continue;                               % (seen edge-on from above)
                end
                try
                    [hullIndices, hullArea] = convhull(lightPoints(:,1), lightPoints(:,2));
                catch
                    continue;                               % (nearly in a line: edge-on)
                end
                if hullArea < 1e-4
                    continue;
                end
                lights(end+1) = struct('Type',typeName, 'Side',sideName, 'Polygon',lightPoints(hullIndices,:)); %#ok<AGROW>
            end
        end
    end
end
% (each lamp joined with its twin of the same type on the other side)
[lights, symmetryLights, addedLights] = fcn_INTERNAL_symmetricLights(lights, options.FlagSymmetric);
symmetryWorst = max([symmetryBody; symmetryWindows(:); symmetryLights(:)]);
addedNames = [arrayfun(@(w) w.Name, windows(addedWindows), 'UniformOutput', false), ...
    arrayfun(@(l) sprintf('%s %s', l.Side, l.Type), lights(addedLights), 'UniformOutput', false)];
symmetry = struct('Symmetric',logical(options.FlagSymmetric), 'Body',symmetryBody, 'Windows',symmetryWindows(:), ...
    'Lights',symmetryLights(:), 'Added',{addedNames}, 'Worst',symmetryWorst);
if symmetryWorst > options.SymmetryTolerance || ~isempty(addedNames)
    changed = {};
    if symmetryBody > options.SymmetryTolerance
        changed{end+1} = sprintf('body (half-widths differ by %.0f%% of the width)', 100*symmetryBody);
    end
    for ith_window = find(symmetryWindows(:)' > options.SymmetryTolerance)
        changed{end+1} = sprintf('%s (%.0f%% of its area)', windows(ith_window).Name, 100*symmetryWindows(ith_window)); %#ok<AGROW>
    end
    % (lamps: one entry per side and type, since a lamp is often traced as
    % many pieces, each listed on its own before 2026_11_21)
    changedLights = find(symmetryLights(:)' > options.SymmetryTolerance);
    lampNames = arrayfun(@(l) sprintf('%s %s lamp', l.Side, l.Type), lights(changedLights), 'UniformOutput', false);
    [uniqueLampNames, ~, lampGroup] = unique(lampNames, 'stable');
    for ith_lamp = 1:numel(uniqueLampNames)
        inGroup = changedLights(lampGroup==ith_lamp);
        if numel(inGroup)==1
            changed{end+1} = sprintf('%s (%.0f%% of its area)', uniqueLampNames{ith_lamp}, 100*symmetryLights(inGroup)); %#ok<AGROW>
        else
            changed{end+1} = sprintf('%s (%d pieces, up to %.0f%% of their area)', uniqueLampNames{ith_lamp}, ...
                numel(inGroup), 100*max(symmetryLights(inGroup))); %#ok<AGROW>
        end
    end
    for ith_added = 1:numel(addedNames)
        changed{end+1} = sprintf('%s (no twin: mirrored)', addedNames{ith_added}); %#ok<AGROW>
    end
    verb = 'were made symmetric';
    if ~options.FlagSymmetric
        verb = 'are not symmetric (Symmetric=false: kept as traced)';
    end
    warning('CarMesh3D:asymmetricOutline', 'Outlines of %s that %s: %s. Check the labels on both sides.', ...
        char(string(vehicleMesh.Name)), verb, strjoin(changed, '; '));
end

%%%% Together
meshName = '';
if isfield(vehicleMesh, 'Name')
    meshName = vehicleMesh.Name;
end
meshFrame = '';
if isfield(vehicleMesh, 'Frame')
    meshFrame = vehicleMesh.Frame;
end
%%%% Interior: each piece, seen from above, not mirrored (the steering
% wheel is on one side)
interior = struct('Name',{}, 'Polygon',{});
interiorPart = find(strcmp(vehicleMesh.LabelPartNames, 'interior'), 1);
flagObjects = isfield(vehicleMesh, 'LabelFaceInterior') && isfield(vehicleMesh, 'LabelInteriorNames') ...
    && numel(vehicleMesh.LabelFaceInterior) == size(faces,1) && any(vehicleMesh.LabelFaceInterior(:) > 0);
if flagObjects
    % (the interior objects only, one outline each, in their own order:
    % driver seat, passenger seat, steering wheel; all their pieces seen
    % from above are joined, and holes filled)
    for ith_object = 1:numel(vehicleMesh.LabelInteriorNames)
        objectFaces = find(vehicleMesh.LabelFaceInterior(:) == ith_object);
        if isempty(objectFaces)
            continue;
        end
        objectShape = fcn_INTERNAL_union(vertices, faces(objectFaces,:));
        if objectShape.NumRegions == 0 || area(objectShape) < options.MinInteriorArea
            continue;
        end
        if objectShape.NumRegions > 1
            % (pieces that do not touch seen from above, such as a
            % headrest's posts: one outline around them all)
            objectPoints = objectShape.Vertices(~any(isnan(objectShape.Vertices),2), :);
            hullIndices = convhull(objectPoints(:,1), objectPoints(:,2));
            outline = objectPoints(hullIndices(1:end-1), :);
        else
            outline = rmholes(objectShape).Vertices;
            outline = outline(~any(isnan(outline),2), :);
        end
        if fcn_INTERNAL_signedArea(outline) < 0
            outline = flipud(outline);
        end
        interior(end+1) = struct('Name', vehicleMesh.LabelInteriorNames{ith_object}, ...
            'Polygon', fcn_INTERNAL_thin([outline; outline(1,:)], options.Tolerance)); %#ok<AGROW>
    end
elseif ~isempty(interiorPart) && any(vehicleMesh.LabelFacePart==interiorPart)
    interiorFaces = find(vehicleMesh.LabelFacePart==interiorPart);
    [~, ~, positionIDs] = unique(round(vertices(faces(interiorFaces,:),:)/1e-5), 'rows');
    interiorPieces = fcn_INTERNAL_connectedPieces(reshape(positionIDs, [], 3));
    interiorPolygons = {};
    interiorCenters = [];
    for ith_piece = 1:max(interiorPieces)
        pieceShape = fcn_INTERNAL_union(vertices, faces(interiorFaces(interiorPieces==ith_piece),:));
        if pieceShape.NumRegions == 0 || area(pieceShape) < options.MinInteriorArea
            continue;
        end
        regionsOfPiece = regions(pieceShape);
        [~, largest] = max(area(regionsOfPiece));
        outline = rmholes(regionsOfPiece(largest)).Vertices;
        outline = outline(~any(isnan(outline),2), :);
        if fcn_INTERNAL_signedArea(outline) < 0
            outline = flipud(outline);
        end
        interiorPolygons{end+1} = fcn_INTERNAL_thin([outline; outline(1,:)], options.Tolerance); %#ok<AGROW>
        interiorCenters(end+1) = mean(outline(:,1)); %#ok<AGROW>
    end
    [~, frontToRear] = sort(interiorCenters, 'descend');
    for ith_piece = 1:numel(frontToRear)
        interior(ith_piece) = struct('Name',sprintf('interior %d', ith_piece), 'Polygon',interiorPolygons{frontToRear(ith_piece)});
    end
end

pointCount = size(bodyPolygon,1) + sum(arrayfun(@(w) size(w.Polygon,1), windows)) + 5*numel(wheels) + ...
    sum(arrayfun(@(l) size(l.Polygon,1), lights)) + sum(arrayfun(@(p) size(p.Polygon,1), interior));
vehicleOutline = struct('Name',meshName, 'Units','m', 'Frame',meshFrame, ...
    'Source','Top-down outlines of the finished mesh (fcn_CarMesh3D_makeOutline2D)', ...
    'Body',bodyPolygon, 'Windows',windows, 'Wheels',wheels, 'Lights',lights, 'Interior',interior, ...
    'Length',bodyLength, 'Width',bodyWidth, ...
    'PointCount',pointCount, 'Symmetry',symmetry);

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

    % Two panels, one above the other: the outlines alone (as a 2D plot
    % would draw them), and the same outlines over the mesh seen from
    % above (to check them against it)
    figure(figNum);
    clf;
    layout = tiledlayout(2, 1, 'TileSpacing','compact', 'Padding','compact');
    lightColors = struct('headlamp',[0.85 0.80 0.55], 'turnSignalLamp',[0.95 0.55 0.05], 'runningLamp',[0.85 0.80 0.55], ...
        'tailBrakeLamp',[0.80 0.05 0.05], 'backupLamp',[0.60 0.60 0.60], 'highBeamLamp',[0.85 0.85 0.75], 'other',[0.50 0.50 0.50]);
    for thisType = fcn_CarMesh3D_lampTypes()'   % (the newer lamp types)
        if ~isfield(lightColors, thisType.Name)
            lightColors.(thisType.Name) = thisType.LabelColor;
        end
    end
    panelTitles = {'The outlines alone', 'Over the mesh seen from above (faded)'};
    for ith_panel = 1:2
        nexttile(layout);
        hold on;
        if 2==ith_panel && isfield(vehicleMesh, 'FaceColors')
            patch('Vertices',vertices(:,1:2), 'Faces',faces, 'FaceVertexCData',vehicleMesh.FaceColors, ...
                'FaceColor','flat', 'EdgeColor','none', 'FaceAlpha',0.10);
        end
        % (the wheels first, then the body over them, as a 2D plot would)
        for ith_wheel = 1:numel(vehicleOutline.Wheels)
            thisWheel = vehicleOutline.Wheels(ith_wheel);
            corners = thisWheel.Rectangle + thisWheel.Center;
            if 1==ith_panel
                fill(corners(:,1), corners(:,2), [0.1 0.1 0.1], 'EdgeColor','k');
            else
                plot(corners(:,1), corners(:,2), 'k-', 'LineWidth',1.5);
            end
        end
        if 1==ith_panel
            fill(vehicleOutline.Body(:,1), vehicleOutline.Body(:,2), [0.05 0.20 0.60], 'EdgeColor',[0.02 0.08 0.30], 'LineWidth',1);
        else
            plot(vehicleOutline.Body(:,1), vehicleOutline.Body(:,2), '-', 'Color',[0.05 0.20 0.60], 'LineWidth',2);
        end
        for ith_window = 1:numel(vehicleOutline.Windows)
            thisPolygon = vehicleOutline.Windows(ith_window).Polygon;
            fill(thisPolygon(:,1), thisPolygon(:,2), [0.55 0.65 0.75], 'FaceAlpha',0.8, 'EdgeColor',[0.25 0.30 0.40], 'LineWidth',1);
        end
        for ith_piece = 1:numel(vehicleOutline.Interior)
            thisPolygon = vehicleOutline.Interior(ith_piece).Polygon;
            fill(thisPolygon(:,1), thisPolygon(:,2), [0.85 0.65 0.40], 'FaceAlpha',0.6, 'EdgeColor',[0.45 0.30 0.15], 'LineWidth',0.5);
        end
        for ith_light = 1:numel(vehicleOutline.Lights)
            thisLight = vehicleOutline.Lights(ith_light);
            thisColor = [0.5 0.5 0.5];
            if isfield(lightColors, thisLight.Type)
                thisColor = lightColors.(thisLight.Type);
            end
            fill(thisLight.Polygon(:,1), thisLight.Polygon(:,2), thisColor, 'EdgeColor','k', 'LineWidth',0.5);
        end
        % (the centerline, about which every outline is symmetric)
        xRange = [min(vehicleOutline.Body(:,1)) max(vehicleOutline.Body(:,1))] + [-0.1 0.1];
        plot(xRange, [0 0], '-.', 'Color',[0.45 0.45 0.45], 'LineWidth',0.75);
        axis equal;
        grid on;
        xlabel('X [m] (forward)');
        ylabel('Y [m] (left)');
        title(panelTitles{ith_panel}, 'FontWeight','normal');
    end
    symmetryNote = 'kept as traced';
    if vehicleOutline.Symmetry.Symmetric
        symmetryNote = sprintf('made symmetric; largest change %.0f%%', 100*vehicleOutline.Symmetry.Worst);
    end
    title(layout, sprintf('%s: top-down outlines (%d points; %s)', vehicleOutline.Name, vehicleOutline.PointCount, symmetryNote), ...
        'Interpreter','none', 'FontWeight','bold');
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

%% fcn_INTERNAL_mirror
function mirrored = fcn_INTERNAL_mirror(shape)
% The mirror image of a polyshape across the centerline (y to -y)
mirrored = polyshape(shape.Vertices(:,1), -shape.Vertices(:,2), 'Simplify', false);
mirrored = simplify(mirrored);
end % Ends fcn_INTERNAL_mirror

%% fcn_INTERNAL_symmetricShapes
function [shapes, changeFraction, wasAdded] = fcn_INTERNAL_symmetricShapes(shapes, flagSymmetric)
% Joins each shape with the mirror image of its twin: the shape whose
% mirror image overlaps it the most (a centered shape is its own twin). A shape
% whose mirror image overlaps nothing gets a mirrored copy, added at the
% end. changeFraction: for each shape, the fraction of the joined area
% that the mirror image added. With flagSymmetric false the shapes are
% returned unchanged (the fractions are still measured).
Nshapes = numel(shapes);
mirrored = cellfun(@fcn_INTERNAL_mirror, shapes, 'UniformOutput', false);
joined = shapes;
changeFraction = zeros(Nshapes, 1);
hasTwin = false(Nshapes, 1);
for ith_shape = 1:Nshapes
    % (the twin: the shape whose mirror image overlaps this one the most)
    overlapAreas = cellfun(@(mirroredShape) area(intersect(shapes{ith_shape}, mirroredShape)), mirrored);
    [bestOverlap, bestTwin] = max(overlapAreas);
    if bestOverlap > 0.05*min(area(shapes{ith_shape}), area(shapes{bestTwin}))
        joined{ith_shape} = union(joined{ith_shape}, mirrored{bestTwin});
        hasTwin(ith_shape) = true;
    end
    changeFraction(ith_shape) = 1 - area(shapes{ith_shape})/area(joined{ith_shape});
end
changeFraction(~hasTwin) = 1;                  % (no twin at all: wholly one-sided)
wasAdded = false(Nshapes, 1);
if flagSymmetric
    shapes = joined;
    for ith_shape = find(~hasTwin)'
        shapes{end+1} = mirrored{ith_shape}; %#ok<AGROW>
        changeFraction(end+1) = 1; %#ok<AGROW>
        wasAdded(end+1) = true; %#ok<AGROW>
    end
end
% (shapes that now overlap, or that both cross the centerline and touch,
% are one window: decimated glass is often split into slivers of one pane)
flagMerged = true;
while flagMerged && numel(shapes) > 1
    flagMerged = false;
    for ith_shape = 1:numel(shapes)-1
        for jth_shape = ith_shape+1:numel(shapes)
            overlapArea = area(intersect(shapes{ith_shape}, shapes{jth_shape}));
            % (pieces that both cross the centerline and touch, within 1 cm,
            % are one pane split into slivers, such as a glass roof)
            flagBothCross = all(cellfun(@(shape) min(shape.Vertices(:,2)) < 0 && max(shape.Vertices(:,2)) > 0, shapes([ith_shape jth_shape])));
            flagTouching = flagBothCross && area(intersect(polybuffer(shapes{ith_shape}, 0.01), shapes{jth_shape})) > 0;
            if overlapArea > 0.02*min(area(shapes{ith_shape}), area(shapes{jth_shape})) || flagTouching
                shapes{ith_shape} = union(shapes{ith_shape}, shapes{jth_shape});
                changeFraction(ith_shape) = max(changeFraction(ith_shape), changeFraction(jth_shape));
                wasAdded(ith_shape) = wasAdded(ith_shape) && wasAdded(jth_shape);
                shapes(jth_shape) = [];
                changeFraction(jth_shape) = [];
                wasAdded(jth_shape) = [];
                flagMerged = true;
                break;
            end
        end
        if flagMerged
            break;
        end
    end
end
% (only the largest region of each joined shape is kept)
for ith_shape = 1:numel(shapes)
    shapeRegions = regions(shapes{ith_shape});
    if numel(shapeRegions) > 1
        [~, largest] = max(area(shapeRegions));
        shapes{ith_shape} = shapeRegions(largest);
    end
end
end % Ends fcn_INTERNAL_symmetricShapes

%% fcn_INTERNAL_openShape
function shape = fcn_INTERNAL_openShape(polygon)
% A polyshape from a polygon whose first point may be repeated at the end
if size(polygon,1) > 1 && isequal(polygon(1,:), polygon(end,:))
    polygon = polygon(1:end-1,:);
end
polygon = unique(polygon, 'rows', 'stable');
shape = polyshape(polygon(:,1), polygon(:,2), 'Simplify', false);
end % Ends fcn_INTERNAL_openShape

%% fcn_INTERNAL_symmetricLights
function [lights, changeFraction, wasAdded] = fcn_INTERNAL_symmetricLights(lights, flagSymmetric)
% Joins each lamp's convex outline with the mirror image of its twin (the
% same type, on the other side, overlapping its mirror image); lamps with
% no twin get a mirrored copy
Nlights = numel(lights);
changeFraction = zeros(Nlights, 1);
wasAdded = false(Nlights, 1);
if Nlights==0
    return;
end
shapes = arrayfun(@(l) fcn_INTERNAL_openShape(l.Polygon), lights, 'UniformOutput', false);
newPolygons = {lights.Polygon};
hasTwin = false(Nlights, 1);
for ith_light = 1:Nlights
    points = lights(ith_light).Polygon;
    % (the twin: the lamp of the same type on the other side whose mirror
    % image overlaps this one the most; a lamp may be in several pieces)
    bestOverlap = 0;
    bestTwin = 0;
    for jth_light = 1:Nlights
        if ~strcmp(lights(jth_light).Type, lights(ith_light).Type) || strcmp(lights(jth_light).Side, lights(ith_light).Side)
            continue;
        end
        overlapArea = area(intersect(shapes{ith_light}, fcn_INTERNAL_mirror(shapes{jth_light})));
        if overlapArea > bestOverlap
            bestOverlap = overlapArea;
            bestTwin = jth_light;
        end
    end
    if bestTwin > 0
        points = [points; lights(bestTwin).Polygon.*[1 -1]]; %#ok<AGROW>
        hasTwin(ith_light) = true;
    end
    try
        hullIndices = convhull(points(:,1), points(:,2));
        newPolygons{ith_light} = points(hullIndices,:);
    catch
        newPolygons{ith_light} = lights(ith_light).Polygon;      % (all in a line: kept as it was)
    end
    changeFraction(ith_light) = 1 - area(shapes{ith_light})/max(area(fcn_INTERNAL_openShape(newPolygons{ith_light})), eps);
end
changeFraction(~hasTwin) = 1;                  % (no twin at all: wholly one-sided)
if flagSymmetric
    for ith_light = 1:Nlights
        lights(ith_light).Polygon = newPolygons{ith_light};
    end
    otherSide = struct('left','right', 'right','left');
    for ith_light = find(~hasTwin)'
        twin = lights(ith_light);
        twin.Side = otherSide.(twin.Side);
        twin.Polygon = flipud(twin.Polygon.*[1 -1]);      % (mirrored, still counterclockwise)
        lights(end+1) = twin; %#ok<AGROW>
        changeFraction(end+1) = 1; %#ok<AGROW>
        wasAdded(end+1) = true; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_symmetricLights

%% fcn_INTERNAL_slices
function [sliceX, sliceLeft, sliceRight] = fcn_INTERNAL_slices(vertices, faces, spacing)
% At each slice along X, the largest and smallest Y where any triangle
% crosses it (edges cut by the slice, and vertices on it)
x1 = vertices(faces(:,1),1); x2 = vertices(faces(:,2),1); x3 = vertices(faces(:,3),1);
y1 = vertices(faces(:,1),2); y2 = vertices(faces(:,2),2); y3 = vertices(faces(:,3),2);
xMin = min(vertices(unique(faces(:)),1));
xMax = max(vertices(unique(faces(:)),1));
sliceX = unique([xMin + 1e-9; (xMin:spacing:xMax)'; xMax - 1e-9]);
sliceX = sliceX(sliceX > xMin & sliceX < xMax);
sliceLeft = -Inf(size(sliceX)); sliceRight = Inf(size(sliceX));
edgeStartX = [x1; x2; x3]; edgeEndX = [x2; x3; x1];
edgeStartY = [y1; y2; y3]; edgeEndY = [y2; y3; y1];
edgeLow = min(edgeStartX, edgeEndX); edgeHigh = max(edgeStartX, edgeEndX);
[edgeLow, order] = sort(edgeLow);
edgeHigh = edgeHigh(order); edgeStartX = edgeStartX(order); edgeEndX = edgeEndX(order);
edgeStartY = edgeStartY(order); edgeEndY = edgeEndY(order);
for ith_slice = 1:numel(sliceX)
    thisX = sliceX(ith_slice);
    lastCandidate = find(edgeLow <= thisX, 1, 'last');
    if isempty(lastCandidate)
        continue;
    end
    crossing = find(edgeHigh(1:lastCandidate) >= thisX);
    edgeRun = edgeEndX(crossing) - edgeStartX(crossing);
    fraction = (thisX - edgeStartX(crossing))./edgeRun;
    fraction(edgeRun==0) = 0;
    crossingY = edgeStartY(crossing) + fraction.*(edgeEndY(crossing) - edgeStartY(crossing));
    if ~isempty(crossingY)
        sliceLeft(ith_slice) = max(crossingY);
        sliceRight(ith_slice) = min(crossingY);
    end
end
valid = isfinite(sliceLeft) & isfinite(sliceRight);
sliceX = sliceX(valid); sliceLeft = sliceLeft(valid); sliceRight = sliceRight(valid);
end % Ends fcn_INTERNAL_slices

%% fcn_INTERNAL_thin
function thinned = fcn_INTERNAL_thin(polygon, tolerance)
% Douglas-Peucker thinning of a closed polygon (first point repeated at
% the end): the points kept are within tolerance of the full outline
if size(polygon,1) <= 4
    thinned = polygon;
    return;
end
% (split the loop at its farthest point from the first, thin each half)
[~, farthest] = max(sum((polygon - polygon(1,:)).^2, 2));
firstHalf = fcn_INTERNAL_douglasPeucker(polygon(1:farthest,:), tolerance);
secondHalf = fcn_INTERNAL_douglasPeucker(polygon(farthest:end,:), tolerance);
thinned = [firstHalf; secondHalf(2:end,:)];
end % Ends fcn_INTERNAL_thin

%% fcn_INTERNAL_douglasPeucker
function kept = fcn_INTERNAL_douglasPeucker(points, tolerance)
% The points of an open polyline that keep it within tolerance
Npoints = size(points,1);
keep = false(Npoints,1);
keep([1 end]) = true;
stack = [1 Npoints];
while ~isempty(stack)
    first = stack(end,1); last = stack(end,2);
    stack(end,:) = [];
    if last - first < 2
        continue;
    end
    chord = points(last,:) - points(first,:);
    chordLength = norm(chord);
    offsets = points(first+1:last-1,:) - points(first,:);
    if chordLength < eps
        distances = sqrt(sum(offsets.^2, 2));
    else
        distances = abs(offsets(:,1)*chord(2) - offsets(:,2)*chord(1))/chordLength;
    end
    [largest, where] = max(distances);
    if largest > tolerance
        middle = first + where;
        keep(middle) = true;
        stack = [stack; first middle; middle last]; %#ok<AGROW>
    end
end
kept = points(keep,:);
end % Ends fcn_INTERNAL_douglasPeucker

%% fcn_INTERNAL_faceNormals
function faceNormals = fcn_INTERNAL_faceNormals(vertices, faces)
% Unit normals of the faces (by their vertex order)
crossed = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
faceNormals = crossed./max(sqrt(sum(crossed.^2, 2)), eps);
end % Ends fcn_INTERNAL_faceNormals

%% fcn_INTERNAL_labelInteriorObjects
function vehicleMesh = fcn_INTERNAL_labelInteriorObjects(vehicleMesh, found)
% The interior objects found by fcn_CarMesh3D_findInteriorObjects as the
% mesh's per-face labels: LabelFaceInterior (0 none, else the object's
% number in LabelInteriorNames)
objectFields = {'DriverSeat', 'PassengerSeat', 'SteeringWheel'};
objectNames = {'driver seat', 'passenger seat', 'steering wheel'};
numFaces = size(vehicleMesh.Faces,1);
faceObject = zeros(numFaces,1);
for ith_object = 1:numel(objectFields)
    if isfield(found, objectFields{ith_object})
        thisObject = found.(objectFields{ith_object});
        if isfield(thisObject, 'Found') && thisObject.Found && isfield(thisObject, 'Faces')
            objectFaces = thisObject.Faces(:);
            objectFaces = objectFaces(objectFaces >= 1 & objectFaces <= numFaces);
            faceObject(objectFaces) = ith_object;
        end
    end
end
vehicleMesh.LabelFaceInterior = faceObject;
vehicleMesh.LabelInteriorNames = objectNames;
end % Ends fcn_INTERNAL_labelInteriorObjects

%% fcn_INTERNAL_connectedPieces
function pieceIndex = fcn_INTERNAL_connectedPieces(faces)
% Which connected piece each face is in (faces sharing a vertex join)
Nfaces = size(faces,1);
pieceIndex = zeros(Nfaces,1);
if Nfaces==0
    return;
end
[~, ~, vertexIDs] = unique(faces(:));
vertexIDs = reshape(vertexIDs, size(faces));
faceIDs = repmat((1:Nfaces)', 1, 3);
graphEdges = sparse(faceIDs(:), vertexIDs(:), 1, Nfaces, max(vertexIDs(:)));
adjacency = graphEdges*graphEdges' > 0;
pieceIndex = conncomp(graph(adjacency, 'omitselfloops'))';
end % Ends fcn_INTERNAL_connectedPieces

%% fcn_INTERNAL_lampGroups
function groupIndex = fcn_INTERNAL_lampGroups(vertices, faces, gap)
% Which lamp each face is in: faces join when they share a corner
% position (not only a corner index: split corners are common in
% downloads), and pieces join when their bounding boxes, grown by gap,
% overlap (a lamp is often several separate pieces)
Nfaces = size(faces,1);
groupIndex = zeros(Nfaces,1);
if Nfaces==0
    return;
end
[~, ~, positionIDs] = unique(round(vertices(faces(:),:)/1e-5), 'rows');
positionFaces = reshape(positionIDs, size(faces));
pieceIndex = fcn_INTERNAL_connectedPieces(positionFaces);
Npieces = max(pieceIndex);
% (each piece's box, grown by half the gap on every side)
cornerPoints = vertices(faces(:),:);
cornerPiece = repmat(pieceIndex, 3, 1);
boxMin = zeros(Npieces,3);
boxMax = zeros(Npieces,3);
for ith_axis = 1:3
    boxMin(:,ith_axis) = accumarray(cornerPiece, cornerPoints(:,ith_axis), [Npieces 1], @min) - gap/2;
    boxMax(:,ith_axis) = accumarray(cornerPiece, cornerPoints(:,ith_axis), [Npieces 1], @max) + gap/2;
end
overlapping = all(boxMin <= permute(boxMax,[3 2 1]) & permute(boxMin,[3 2 1]) <= boxMax, 2);
overlapping = reshape(overlapping, Npieces, Npieces);
pieceGroup = conncomp(graph(overlapping, 'omitselfloops'))';
groupIndex = pieceGroup(pieceIndex);
end % Ends fcn_INTERNAL_lampGroups

%% fcn_INTERNAL_union
function shapeUnion = fcn_INTERNAL_union(vertices, faces)
% The triangles seen from above, merged into one shape
warningState = warning('off', 'MATLAB:polyshape:repairedBySimplify');
triangles = repmat(polyshape(), size(faces,1), 1);
for ith_face = 1:size(faces,1)
    corners = vertices(faces(ith_face,:), 1:2);
    if abs(fcn_INTERNAL_signedArea(corners)) > 1e-10
        triangles(ith_face) = polyshape(corners, 'Simplify', false);
    end
end
shapeUnion = union(triangles);
warning(warningState);
end % Ends fcn_INTERNAL_union

%% fcn_INTERNAL_signedArea
function signedArea = fcn_INTERNAL_signedArea(polygon)
% Positive for counterclockwise points (shoelace formula)
x = polygon(:,1); y = polygon(:,2);
signedArea = 0.5*sum(x.*circshift(y,-1) - circshift(x,-1).*y);
end % Ends fcn_INTERNAL_signedArea
