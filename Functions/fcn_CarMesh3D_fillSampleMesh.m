function vehicleMesh = fcn_CarMesh3D_fillSampleMesh(options)
% fcn_CarMesh3D_fillSampleMesh
% Builds a simple, low-poly sample car mesh directly from a vehicle
% specification. The sample has a body extruded from a side profile with
% wheel arches, glass panes (windshield, rear window, side windows),
% head and tail lights, and four wheels made of tire and rim materials.
% Materials and groups are named the way downloaded models often name
% them, so the sample can be used to test every step of the CarMesh3D
% workflow without downloading anything.
%
% The sample can be returned "clean" (already in the CarMesh3D vehicle
% frame, in meters) or "messy" (in millimeters, Y-up, Z-forward, and
% offset from the origin), which imitates a typical downloaded model and
% is used to test fcn_CarMesh3D_normalizeMesh.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_fillSampleMesh(...
%           (VehicleSpec=vehicleSpec),...
%           (Style=styleString),...
%           (NumWheelSegments=numSegments),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      VehicleSpec: a vehicle specification structure from
%      fcn_CarMesh3D_fillVehicleSpec. It must contain OverallLength,
%      OverallWidth, OverallHeight, and Wheelbase. If empty or omitted,
%      the 'genericSedan' preset is used.
%
%      Style: 'clean' (default) or 'messy'.
%           'clean': CarMesh3D vehicle frame (ISO 8855: X forward, Y left,
%           Z up), meters, origin on the ground at the center of the
%           length and width.
%           'messy': millimeters, Y up, Z forward, X to the left, with an
%           arbitrary offset. Recover the clean frame with
%           fcn_CarMesh3D_normalizeMesh(mesh, UpAxis='+y', ForwardAxis='+z').
%
%      NumWheelSegments: the number of flat segments around each wheel.
%      Default is 16.
%
%      FigNum: a figure number to plot the result. If empty or omitted, no
%      plot is made. If set to -1, input checking is skipped and no plot
%      is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure with the fields
%           Name, Source, License, Units, Frame,
%           Vertices (N x 3), Faces (M x 3, triangles),
%           MaterialNames (K x 1 cell), MaterialColors (K x 3, RGB),
%           MaterialAlpha (K x 1), FaceMaterialIndex (M x 1),
%           GroupNames (G x 1 cell), FaceGroupIndex (M x 1)
%      See README.md for the full description of the mesh structure.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillVehicleSpec
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%      polyshape, triangulation (MATLAB base)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_fillSampleMesh.m for a full
%       test suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillSampleMesh
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillSampleMesh
%   % * Add body styles (hatchback, pickup) via a BodyStyle option
%   % * Add side mirrors so mirror-width handling can be tested



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.VehicleSpec = []        % Spec structure; [] for genericSedan
    options.Style = 'clean'         % 'clean' or 'messy'
    options.NumWheelSegments = 16   % Segments around each wheel
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

        % Check the VehicleSpec input
        if ~isempty(options.VehicleSpec)
            if ~isstruct(options.VehicleSpec)
                error('VehicleSpec must be a structure from fcn_CarMesh3D_fillVehicleSpec');
            end
            requiredFields = {'OverallLength','OverallWidth','OverallHeight','Wheelbase'};
            for ith_field = 1:length(requiredFields)
                if ~isfield(options.VehicleSpec,requiredFields{ith_field}) || isempty(options.VehicleSpec.(requiredFields{ith_field}))
                    error('VehicleSpec must contain a value for %s to build a sample mesh',requiredFields{ith_field});
                end
            end
        end

        % Check the Style input
        if ~any(strcmpi(char(options.Style),{'clean','messy'}))
            error('Style must be ''clean'' or ''messy''. Found: %s',char(options.Style));
        end

        % Check the NumWheelSegments input
        if ~isnumeric(options.NumWheelSegments) || ~isscalar(options.NumWheelSegments) || options.NumWheelSegments<6 || options.NumWheelSegments~=round(options.NumWheelSegments)
            error('NumWheelSegments must be an integer of 6 or more');
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

%%%%
% Get the dimensions to build from
vehicleSpec = options.VehicleSpec;
if isempty(vehicleSpec)
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
end

L  = vehicleSpec.OverallLength;
W  = vehicleSpec.OverallWidth;
H  = vehicleSpec.OverallHeight;
WB = vehicleSpec.Wheelbase;

D = fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'TireDiameter',0.24*H+0.30);
FOH = fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'FrontOverhang',(L-WB)/2);
TF = fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'TrackFront',W-0.25);
TR = fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'TrackRear',TF);
z0 = fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'GroundClearance',0.14);

% Tire width from the tire size string, if available
tireWidth = 0.22;
if isfield(vehicleSpec,'TireSize') && ~isempty(vehicleSpec.TireSize)
    tokens = regexp(char(vehicleSpec.TireSize),'(\d{3})\s*/','tokens','once');
    if ~isempty(tokens)
        tireWidth = str2double(tokens{1})/1000;
    end
end

r  = D/2;            % Tire radius
ra = r + 0.03;       % Wheel arch radius
if z0 >= r
    z0 = 0.8*r;      % Arches need the body bottom below the wheel center
end

% Axle locations, with the body centered on X = 0
xFrontBumper = L/2;
xRearBumper  = -L/2;
xFrontAxle   = xFrontBumper - FOH;
xRearAxle    = xFrontAxle - WB;

%%%%
% Build the side profile of the body, in (X, Z), counterclockwise when
% viewed from the left side (from +Y): along the bottom from rear to
% front (with two wheel arches), up the front, back over the roof, and
% down the rear.
p1  = [xRearBumper  + 0.02*L, z0];        % Rear, bottom
p2  = [xFrontBumper - 0.02*L, z0];        % Front, bottom
pFrontBumper = [xFrontBumper,          z0 + 0.18*H];
pHoodFront   = [xFrontBumper - 0.01*L, 0.50*H];
pCowl        = [xFrontBumper - 0.28*L, 0.62*H];
pRoofFront   = [xFrontBumper - 0.45*L, 1.00*H];
pRoofRear    = [xRearBumper  + 0.33*L, 1.00*H];
pDeck        = [xRearBumper  + 0.15*L, 0.66*H];
pTrunkEnd    = [xRearBumper  + 0.01*L, 0.62*H];
pRearBumper  = [xRearBumper,           z0 + 0.18*H];

numArchPoints = 9;
rearArch  = fcn_INTERNAL_archPoints(xRearAxle,  r, ra, z0, numArchPoints);
frontArch = fcn_INTERNAL_archPoints(xFrontAxle, r, ra, z0, numArchPoints);

profileXZ = [p1; rearArch; frontArch; p2; ...
    pFrontBumper; pHoodFront; pCowl; pRoofFront; pRoofRear; pDeck; pTrunkEnd; pRearBumper];

% Make sure the profile is counterclockwise (positive area in X-Z)
signedArea = 0.5*sum(profileXZ(:,1).*circshift(profileXZ(:,2),-1) - circshift(profileXZ(:,1),-1).*profileXZ(:,2));
if signedArea<0
    profileXZ = flipud(profileXZ);
end

%%%%
% Start empty lists, then append each piece
allVertices = zeros(0,3);
allFaces = zeros(0,3);
allMaterial = zeros(0,1);
allGroup = zeros(0,1);

materialNames  = {'CarPaint';'Glass';'HeadLight';'TailLight';'Tire';'Rim'};
paintColor = [0.10 0.25 0.60];
if isfield(vehicleSpec,'BodyColor') && ~isempty(vehicleSpec.BodyColor)
    paintColor = vehicleSpec.BodyColor;
end
materialColors = [...
    paintColor;
    0.15 0.20 0.25;
    0.95 0.95 0.85;
    0.80 0.05 0.05;
    0.08 0.08 0.08;
    0.75 0.75 0.78];
materialAlpha = [1; 0.35; 1; 1; 1; 1];
groupNames = {'Body';'Glass';'Lights';'Wheel_FL';'Wheel_FR';'Wheel_RL';'Wheel_RR'};

%%%%
% Body sides: strips between consecutive profile points, across the width
Nprofile = size(profileXZ,1);
bodyVertices = [profileXZ(:,1),  (W/2)*ones(Nprofile,1), profileXZ(:,2);
                profileXZ(:,1), -(W/2)*ones(Nprofile,1), profileXZ(:,2)];
thisIndex = (1:Nprofile)';
nextIndex = [(2:Nprofile)'; 1];
bodyFaces = [thisIndex, Nprofile+nextIndex, Nprofile+thisIndex;
             thisIndex, nextIndex,          Nprofile+nextIndex];
% Outward direction is to the right of each edge in a CCW profile
edgeVectors = profileXZ(nextIndex,:) - profileXZ(thisIndex,:);
edgeOutward = [edgeVectors(:,2), zeros(Nprofile,1), -edgeVectors(:,1)];
bodyFaces = fcn_INTERNAL_flipToward(bodyVertices, bodyFaces, [edgeOutward; edgeOutward]);
[allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
    allVertices, allFaces, allMaterial, allGroup, bodyVertices, bodyFaces, 1, 1);

% Body end caps: triangulate the (non-convex) profile polygon
profileShape = polyshape(profileXZ(:,1), profileXZ(:,2), 'KeepCollinearPoints', true);
profileTriangulation = triangulation(profileShape);
capPoints = profileTriangulation.Points;
capFaces  = profileTriangulation.ConnectivityList;
Ncap = size(capPoints,1);
for ith_side = [1 -1]
    capVertices = [capPoints(:,1), ith_side*(W/2)*ones(Ncap,1), capPoints(:,2)];
    theseFaces = fcn_INTERNAL_flipToward(capVertices, capFaces, [0 ith_side 0]);
    [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
        allVertices, allFaces, allMaterial, allGroup, capVertices, theseFaces, 1, 1);
end

%%%%
% Glass: windshield and rear window lie just outside the profile edges
glassOffset = 0.008;
[pieceVertices, pieceFaces] = fcn_INTERNAL_stripOnEdge(pCowl, pRoofFront, 0.06, 0.94, -0.42*W, 0.42*W, glassOffset);
[allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
    allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, 2, 2);
[pieceVertices, pieceFaces] = fcn_INTERNAL_stripOnEdge(pRoofRear, pDeck, 0.08, 0.92, -0.42*W, 0.42*W, glassOffset);
[allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
    allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, 2, 2);

% Side windows: one quad on each side, just outside the body side
sideWindowXZ = [...
    pCowl(1) - 0.03*L,  0.65*H;
    pRoofFront(1),      0.95*H;
    pRoofRear(1),       0.95*H;
    pDeck(1) + 0.03*L,  0.68*H];
for ith_side = [1 -1]
    pieceVertices = [sideWindowXZ(:,1), ith_side*(W/2 + glassOffset)*ones(4,1), sideWindowXZ(:,2)];
    pieceFaces = fcn_INTERNAL_flipToward(pieceVertices, [1 2 3; 1 3 4], [0 ith_side 0]);
    [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
        allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, 2, 2);
end

%%%%
% Lights: head lights on the front face, tail lights on the rear face
lightOffset = 0.005;
for ith_side = [1 -1]
    yRange = sort(ith_side*[0.22*W 0.42*W]);
    [pieceVertices, pieceFaces] = fcn_INTERNAL_stripOnEdge(pFrontBumper, pHoodFront, 0.45, 0.90, yRange(1), yRange(2), lightOffset);
    [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
        allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, 3, 3);
    [pieceVertices, pieceFaces] = fcn_INTERNAL_stripOnEdge(pTrunkEnd, pRearBumper, 0.10, 0.50, yRange(1), yRange(2), lightOffset);
    [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
        allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, 4, 3);
end

%%%%
% Wheels: front-left, front-right, rear-left, rear-right (Y is left)
wheelCentersXY = [...
    xFrontAxle,  TF/2;
    xFrontAxle, -TF/2;
    xRearAxle,   TR/2;
    xRearAxle,  -TR/2];
for ith_wheel = 1:4
    [pieceVertices, tireFaces, rimFaces] = fcn_INTERNAL_wheel(...
        wheelCentersXY(ith_wheel,1), wheelCentersXY(ith_wheel,2), r, tireWidth, options.NumWheelSegments);
    groupIndex = 3 + ith_wheel;
    % Append the vertices once with the tire faces, then add the rim
    % faces using the same vertex offset
    vertexOffset = size(allVertices,1);
    [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
        allVertices, allFaces, allMaterial, allGroup, pieceVertices, tireFaces, 5, groupIndex);
    allFaces = [allFaces; rimFaces + vertexOffset]; %#ok<AGROW>
    allMaterial = [allMaterial; 6*ones(size(rimFaces,1),1)]; %#ok<AGROW>
    allGroup = [allGroup; groupIndex*ones(size(rimFaces,1),1)]; %#ok<AGROW>
end

%%%%
% Messy style: convert to millimeters, Y up, Z forward, X left, offset
if strcmpi(char(options.Style),'messy')
    % [x y z]_messy = [y z x]_clean is a proper rotation (no mirroring)
    allVertices = 1000*[allVertices(:,2), allVertices(:,3), allVertices(:,1)];
    allVertices = allVertices + [120 -35 2500];
    unitsString = 'mm';
    frameString = 'source';
else
    unitsString = 'm';
    frameString = 'ISO8855';
end

%%%%
% Fill the output structure
vehicleMesh = struct;
vehicleMesh.Name = sprintf('%s (sample mesh)', fcn_INTERNAL_getFieldOrDefault(vehicleSpec,'Name','Vehicle'));
vehicleMesh.Source = 'fcn_CarMesh3D_fillSampleMesh';
vehicleMesh.License = 'Generated by CarMesh3D';
vehicleMesh.Units = unitsString;
vehicleMesh.Frame = frameString;
vehicleMesh.Vertices = allVertices;
vehicleMesh.Faces = allFaces;
vehicleMesh.MaterialNames = materialNames;
vehicleMesh.MaterialColors = materialColors;
vehicleMesh.MaterialAlpha = materialAlpha;
vehicleMesh.FaceMaterialIndex = allMaterial;
vehicleMesh.GroupNames = groupNames;
vehicleMesh.FaceGroupIndex = allGroup;

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
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FlagShowEdges=true, FigNum=figNum);
    title(sprintf('%s: %d faces, style ''%s''',vehicleMesh.Name, size(vehicleMesh.Faces,1), char(options.Style)),'Interpreter','none');
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

%% fcn_INTERNAL_getFieldOrDefault
function value = fcn_INTERNAL_getFieldOrDefault(thisStruct, fieldName, defaultValue)
% Returns thisStruct.(fieldName) if it exists and is not empty, otherwise
% returns defaultValue
if isfield(thisStruct, fieldName) && ~isempty(thisStruct.(fieldName))
    value = thisStruct.(fieldName);
else
    value = defaultValue;
end
end % Ends fcn_INTERNAL_getFieldOrDefault

%% fcn_INTERNAL_archPoints
function archXZ = fcn_INTERNAL_archPoints(xCenter, r, ra, z0, numPoints)
% Returns points along a wheel arch, from where the arch leaves the body
% bottom (at height z0) behind the wheel, over the top, to where it meets
% the body bottom ahead of the wheel. Points are ordered with increasing X.
alpha = asin((z0 - r)/ra); % Negative angle where the arch meets z0
theta = linspace(pi - alpha, alpha, numPoints)';
archXZ = [xCenter + ra*cos(theta), r + ra*sin(theta)];
end % Ends fcn_INTERNAL_archPoints

%% fcn_INTERNAL_stripOnEdge
function [pieceVertices, pieceFaces] = fcn_INTERNAL_stripOnEdge(pointA, pointB, fractionStart, fractionEnd, yLow, yHigh, offsetDistance)
% Makes a flat rectangle (two triangles) lying along the profile edge from
% pointA to pointB (both [X Z]), between the given fractions of the edge
% length and between yLow and yHigh across the car. The rectangle is moved
% outward from the body by offsetDistance so it is drawn on top of it.
edgeVector = pointB - pointA;
outward = [edgeVector(2), -edgeVector(1)]/norm(edgeVector); % Right of edge in a CCW profile
startXZ = pointA + fractionStart*edgeVector + offsetDistance*outward;
endXZ   = pointA + fractionEnd*edgeVector   + offsetDistance*outward;
pieceVertices = [...
    startXZ(1), yHigh, startXZ(2);
    endXZ(1),   yHigh, endXZ(2);
    startXZ(1), yLow,  startXZ(2);
    endXZ(1),   yLow,  endXZ(2)];
pieceFaces = [1 4 3; 1 2 4];
pieceFaces = fcn_INTERNAL_flipToward(pieceVertices, pieceFaces, [outward(1) 0 outward(2)]);
end % Ends fcn_INTERNAL_stripOnEdge

%% fcn_INTERNAL_wheel
function [wheelVertices, tireFaces, rimFaces] = fcn_INTERNAL_wheel(xCenter, yCenter, r, tireWidth, numSegments)
% Makes a closed cylinder for one wheel, axis along Y, touching the
% ground (Z = 0). Tire faces are the tread and the outer ring of each
% side; rim faces are the inner disk of each side.
phi = (0:numSegments-1)'*2*pi/numSegments;
rimRatio = 0.62;
yPlus  = yCenter + tireWidth/2;
yMinus = yCenter - tireWidth/2;
outerPlus  = [xCenter + r*cos(phi),          yPlus*ones(numSegments,1),  r + r*sin(phi)];
outerMinus = [xCenter + r*cos(phi),          yMinus*ones(numSegments,1), r + r*sin(phi)];
innerPlus  = [xCenter + rimRatio*r*cos(phi), yPlus*ones(numSegments,1),  r + rimRatio*r*sin(phi)];
innerMinus = [xCenter + rimRatio*r*cos(phi), yMinus*ones(numSegments,1), r + rimRatio*r*sin(phi)];
wheelVertices = [outerPlus; outerMinus; innerPlus; innerMinus; xCenter yPlus r; xCenter yMinus r];

n = numSegments;
thisIndex = (1:n)';
nextIndex = [(2:n)'; 1];
iOP = thisIndex;   jOP = nextIndex;       % outer ring, +Y side
iOM = n+thisIndex; jOM = n+nextIndex;     % outer ring, -Y side
iIP = 2*n+thisIndex; jIP = 2*n+nextIndex; % inner ring, +Y side
iIM = 3*n+thisIndex; jIM = 3*n+nextIndex; % inner ring, -Y side
centerPlus = 4*n+1;
centerMinus = 4*n+2;

% Tread: outward is radial from the axle
treadFaces = [iOP, jOM, iOM; iOP, jOP, jOM];
midPhi = phi + pi/numSegments;
radialOut = [cos(midPhi), zeros(n,1), sin(midPhi)];
treadFaces = fcn_INTERNAL_flipToward(wheelVertices, treadFaces, [radialOut; radialOut]);

% Outer rings of the side walls
ringPlus  = fcn_INTERNAL_flipToward(wheelVertices, [iOP, iIP, jIP; iOP, jIP, jOP], [0  1 0]);
ringMinus = fcn_INTERNAL_flipToward(wheelVertices, [iOM, iIM, jIM; iOM, jIM, jOM], [0 -1 0]);

% Rim disks
rimPlus  = fcn_INTERNAL_flipToward(wheelVertices, [centerPlus*ones(n,1),  iIP, jIP], [0  1 0]);
rimMinus = fcn_INTERNAL_flipToward(wheelVertices, [centerMinus*ones(n,1), iIM, jIM], [0 -1 0]);

tireFaces = [treadFaces; ringPlus; ringMinus];
rimFaces  = [rimPlus; rimMinus];
end % Ends fcn_INTERNAL_wheel

%% fcn_INTERNAL_flipToward
function faces = fcn_INTERNAL_flipToward(vertices, faces, desiredDirection)
% Flips the vertex order of any triangle whose normal points away from
% the desired direction. desiredDirection is 1 x 3 (same for all faces)
% or M x 3 (one per face).
faceNormals = cross(...
    vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
if size(desiredDirection,1)==1
    desiredDirection = repmat(desiredDirection, size(faces,1), 1);
end
flagFlip = sum(faceNormals.*desiredDirection, 2) < 0;
faces(flagFlip,:) = faces(flagFlip,[1 3 2]);
end % Ends fcn_INTERNAL_flipToward

%% fcn_INTERNAL_appendPiece
function [allVertices, allFaces, allMaterial, allGroup] = fcn_INTERNAL_appendPiece(...
    allVertices, allFaces, allMaterial, allGroup, pieceVertices, pieceFaces, materialIndex, groupIndex)
% Appends one piece (its own vertices and faces) to the growing mesh
vertexOffset = size(allVertices,1);
allVertices = [allVertices; pieceVertices];
allFaces = [allFaces; pieceFaces + vertexOffset];
allMaterial = [allMaterial; materialIndex*ones(size(pieceFaces,1),1)];
allGroup = [allGroup; groupIndex*ones(size(pieceFaces,1),1)];
end % Ends fcn_INTERNAL_appendPiece
