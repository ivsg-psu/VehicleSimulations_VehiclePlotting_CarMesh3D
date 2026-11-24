function [result, vehicleMesh] = fcn_CarMesh3D_findInteriorObjects(vehicleMesh, options)
% fcn_CarMesh3D_findInteriorObjects
% Finds the driver's seat, the front passenger's seat and the steering
% wheel inside a vehicle's 3D mesh, by fitting simple templates to points
% spread evenly over the mesh's surface: a seat is a cushion box and a
% reclined backrest box; a steering wheel is a ring of known diameter.
% These are the interior objects: they replace the older voxel guess of
% "the interior" (fcn_CarMesh3D_labelInterior, off since 2026-11-24, Q37),
% and they are what the 2D outline draws inside the body
% (fcn_CarMesh3D_makeOutline2D) and what a steering animation turns.
%
% The idea, in plain words:
%   1. Spread points evenly over every triangle (the number of points in
%      proportion to the triangle's area), so "number of points" measures
%      surface area, not how finely a part was modeled.
%   2. Place a seat template where a seat can be (behind the front axle,
%      to one side, at hip height). Its score is the surface area inside
%      its boxes, MINUS a heavy penalty for anything in the space where a
%      person sits (it must be empty), for the body's outer skin or glass
%      inside the boxes, and for corners outside the vehicle.
%   3. Score thousands of random poses quickly (RANSAC style), then polish
%      the best few with fminsearch on a smooth version of the score (each
%      point weighted by how deep inside it is, so the search has a slope
%      to follow).
%   4. Search the steering wheel the same way, ahead of and above each
%      seat, with a ring of the known diameter. The side whose wheel scores
%      best is the driver's side (left- or right-hand drive is read from
%      the mesh).
%   5. Search the passenger seat on the other side, also starting from the
%      mirror image of the driver's seat (and the other way around).
%   6. The faces of each object are those whose points lie inside the
%      tight template; a connected piece of the mesh lying mostly inside
%      is taken whole (downloads often model each seat as its own piece).
%
% Method from Sean (2026-11-24 05:48: critical dimensions, an enclosing
% template with a safety margin, evenly resampled points, a simplex search
% over position and orientation with penalties, random starts against
% local minima); built and tested by Agent A for Claude, 2026-11-24 (its
% report, with the dimensions found and their sources:
% Desktop\Claude\Project_CarMesh3D\agents\A\REPORT_findInteriorObjects.md).
%
% FORMAT:
%
%       [result, vehicleMesh] = fcn_CarMesh3D_findInteriorObjects(vehicleMesh,...
%           (Seats=flag), (SteeringWheel=flag), (Templates=templates),...
%           (DriveSide=side), (PointSpacing=meters), (SearchSpacing=meters),...
%           (NumHypotheses=n), (NumRefine=n), (RandomSeed=seed),...
%           (Verbose=flag), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D vehicle mesh (Vertices in meters: x
%      forward, y to the LEFT, z up, ground at z = 0; Faces). Used if
%      present: FacePartIndex and PartNames (glass, wheel and light faces
%      are never part of a seat or the wheel), AxleX, VehicleSpec
%      (OverallWidth, OverallHeight, Wheelbase).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Seats: true (default) to find the two front seats.
%
%      SteeringWheel: true (default) to find the steering wheel.
%
%      Templates: a structure overriding any template value, such as
%      Templates.Seat.Width = 0.48 or Templates.SteeringWheel.Diameter =
%      0.368 (the 2009 to 2013 Fit's); see fcn_INTERNAL_defaultTemplates
%      for every field. Default: none (the generic templates).
%
%      DriveSide: 'auto' (default: decided from the mesh), 'left' (the
%      driver at +y, as in the US) or 'right'.
%
%      PointSpacing: meters between sample points, for the wheel and for
%      picking faces. Default 0.012.
%
%      SearchSpacing: meters between the coarser points of the seat
%      search. Default 0.025.
%
%      NumHypotheses: random poses tried in each search. Default 3000.
%
%      NumRefine: best distinct poses polished with fminsearch. Default 4.
%
%      RandomSeed: so a run can be repeated exactly. Default 1.
%
%      Verbose: true to print progress. Default false.
%
%      FigNum: a figure to draw the mesh with the objects found and their
%      templates in. If empty or omitted, no plot is made. If -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      result: a structure with
%           DriverSeat, PassengerSeat: Found (true or false), Score (m^2 of
%               surface inside the template, after penalties), AreaInside
%               (m^2, no penalties), Origin (the middle of the cushion
%               top's back edge, where the backrest meets it),
%               HipPointEstimate (estimated), Axes (3 x 3: the seat's
%               forward, left and up), YawDeg, RollDeg, CushionPitchDeg,
%               BackAngleDeg (from vertical), Scale, Dims, Boxes (cushion
%               and backrest: Center, Axes, HalfSize, Corners), Center (of
%               the faces found), Faces (face numbers of vehicleMesh), Side
%               (+1 left, -1 right)
%           SteeringWheel: Found, Score, Center, Normal (toward the
%               driver), Radius (of the rim's center line), OuterDiameter,
%               TiltDeg (from vertical), YawDeg, Faces
%           DriveSide: 'left' or 'right'; DriveSideSource: 'mesh',
%               'option' or 'default'
%           Info: the templates used, point counts, each side's scores,
%               the time taken
%
%      vehicleMesh: the mesh given, with the objects stored in it (as a
%      vehicle's build saves them):
%           FaceInteriorObject: one number per face, 0 for none, else the
%               object's place in InteriorObjectNames
%           InteriorObjectNames: {'driver seat', 'passenger seat',
%               'steering wheel'}
%           InteriorObjects: the result above without Info (each object's
%               pose and faces), for the 2D outline
%               (fcn_CarMesh3D_makeOutline2D) and the steering animation
%               (fcn_CarMesh3D_turnSteeringWheel)
%
% DEPENDENCIES:
%
%      Base MATLAB only (convhulln, fminsearch, graph and conncomp,
%      accumarray). A build step: viewing and animating a finished mesh
%      does not run it (Q42 A).
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport');
%       loaded = load(vehicleFiles.MeshFile);
%       templates.SteeringWheel.Diameter = 0.368;   % the Fit's, 14.5 in
%       [result, meshWithObjects] = fcn_CarMesh3D_findInteriorObjects(loaded.vehicleMesh, Templates=templates, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_findInteriorObjects.m for
%       a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude; prototype by Agent A)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findInteriorObjects
%   % * First write of the code (Agent A's prototype, v7, put in the
%   %   % repository's form): seats and steering wheel by template fits
%   %   % with random starts and fminsearch; drive side from the mesh;
%   %   % a second output, the mesh with the objects stored in it; a seat
%   %   % "found" from 1.5 m^2 (the whole library run: real seats 1.83 to
%   %   % 3.16, a cabin without seats about 1.0)

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findInteriorObjects
%   % * Backrest angles stop at their 10 degree limit on some trucks:
%   %   % allow 5 degrees and penalize skin near the backrest
%   % * Floor and console faces taken with the seats on detailed
%   %   % interiors (Expedition, Golf): drop flat faces at the template's
%   %   % bottom
%   % * Right-hand drive: the 2006 Frontier's wheel was found on the
%   %   % right (its download may be a right-hand-drive model, or
%   %   % mirrored); no other check yet; rear seats not searched


% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.Seats = true            % Find the two front seats
    options.SteeringWheel = true    % Find the steering wheel
    options.Templates = struct()    % Template values to override
    options.DriveSide = 'auto'      % 'auto', 'left' or 'right'
    options.PointSpacing = 0.012    % meters between sample points
    options.SearchSpacing = 0.025   % meters between the seat search's points
    options.NumHypotheses = 3000    % random poses per search
    options.NumRefine = 4           % best poses polished with fminsearch
    options.RandomSeed = 1          % random seed, so a run repeats exactly
    options.Verbose = false         % print progress
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
        % The option names are checked by the arguments block above
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces'})) || size(vehicleMesh.Vertices,2) ~= 3
            error('CarMesh3D:badInput', 'vehicleMesh must be a CarMesh3D mesh (a structure with Vertices, N x 3, and Faces).');
        end
        if ~any(strcmpi(char(options.DriveSide), {'auto','left','right'}))
            error('CarMesh3D:badInput', 'DriveSide must be ''auto'', ''left'' or ''right''.');
        end
        if ~isstruct(options.Templates)
            error('CarMesh3D:badInput', 'Templates must be a structure (fields as in fcn_INTERNAL_defaultTemplates).');
        end
    end
end

% Make the plot?
flag_do_plots = 0; % Default is to NOT plot
if (0==flag_max_speed) && ~isempty(options.FigNum)
    flag_do_plots = 1;
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

timeStart = tic;
oldRng = rng;                    % restore the caller's random state at the end
rng(options.RandomSeed, 'twister');
say = @(varargin) fcn_INTERNAL_say(options.Verbose, varargin{:});

V = double(vehicleMesh.Vertices);
F = double(vehicleMesh.Faces);

%% 1. Vehicle size and the templates
geo = fcn_INTERNAL_vehicleGeometry(vehicleMesh);
T   = fcn_INTERNAL_mergeStruct(fcn_INTERNAL_defaultTemplates(geo), options.Templates);

%% 2. Evenly spaced points on the surface (plus one point per face centroid)
[P, pointFace, faceArea, faceNormal] = fcn_INTERNAL_samplePoints(V, F, options.PointSpacing);
h2 = sum(faceArea)/(size(P,1) - size(F,1));   % area that one sample point stands for (m^2)
say('%d sample points (spacing %.3f m), mesh area %.1f m^2', size(P,1), options.PointSpacing, sum(faceArea));

% Faces that can never be part of a seat or the steering wheel
faceBlocked = false(size(F,1),1);
if isfield(vehicleMesh,'FacePartIndex') && isfield(vehicleMesh,'PartNames')
    blockedParts = find(ismember(lower(vehicleMesh.PartNames), {'glass','wheel','light'}));
    faceBlocked = ismember(vehicleMesh.FacePartIndex, blockedParts);
end

%% 3. The vehicle's convex hull: "outside the body" test and the outer skin
hull = fcn_INTERNAL_bodyHull(V, geo);
pointHullDist = fcn_INTERNAL_hullSignedDist(hull, P);   % < 0 inside the hull
pointBlocked = faceBlocked(pointFace) | pointHullDist > -T.SkinThickness;

% A coarser random subset (each point then stands for more area) makes
% the seat search several times faster without changing its answer much.
keepCoarse = rand(size(P,1),1) < (options.PointSpacing/options.SearchSpacing)^2;
keepCoarse(end-size(F,1)+1:end) = false;    % drop the centroid points here
Pc = P(keepCoarse,:); Bc = pointBlocked(keepCoarse);
Nc = faceNormal(pointFace(keepCoarse),:);    % surface normal at each coarse point
h2c = sum(faceArea)/max(nnz(keepCoarse),1);  % area per coarse point (m^2)

%% 4. Seats on both sides, then a steering wheel in front of each
sidesToSearch = [+1 -1];                 % +1 = left (+y), -1 = right (-y)
seatSide  = cell(1,2);
wheelSide = cell(1,2);
for k = 1:2
    side = sidesToSearch(k);
    tk = tic;
    seatSide{k} = fcn_INTERNAL_searchSeat(Pc, Bc, Nc, h2c, geo, T, hull, side, [], options);
    say('seat side %+d: score %.3f m^2 at [%.2f %.2f %.2f] (%.1f s)', side, seatSide{k}.Score, seatSide{k}.Origin, toc(tk));
    if options.SteeringWheel
        tk = tic;
        wheelSide{k} = fcn_INTERNAL_searchWheel(P, pointBlocked, h2, T, seatSide{k}, options);
        say('wheel side %+d: score %.4f m^2, R=%.3f m (%.1f s)', side, wheelSide{k}.Score, wheelSide{k}.Radius, toc(tk));
    end
end

%% 5. Which side is the driver's?
switch lower(options.DriveSide)
    case 'left'
        driverK = 1; sideSource = 'option';
    case 'right'
        driverK = 2; sideSource = 'option';
    otherwise
        driverK = 1; sideSource = 'default';
        if options.SteeringWheel
            wScores = [wheelSide{1}.Score, wheelSide{2}.Score];
            % trust the mesh only if one side's wheel is clearly better
            if max(wScores) >= T.SteeringWheel.FoundScore && max(wScores) >= 2*min(wScores)
                [~, driverK] = max(wScores);
                sideSource = 'mesh';
            end
        end
end
passK = 3 - driverK;
driveSideNames = {'left','right'};

driverSeat = seatSide{driverK};
passSeat   = seatSide{passK};

% Passenger: also try starting from the mirror image of the driver seat
if options.Seats
    mirrorStart = driverSeat.Params .* [1 -1 1 -1 -1 1 1 1];
    passMirror = fcn_INTERNAL_searchSeat(Pc, Bc, Nc, h2c, geo, T, hull, sidesToSearch(passK), mirrorStart, options);
    if passMirror.Score > passSeat.Score
        passSeat = passMirror;
        say('passenger seat: mirrored start was better (%.3f m^2)', passSeat.Score);
    end
    % ... and the driver seat from the mirror image of the passenger seat
    driverMirror = fcn_INTERNAL_searchSeat(Pc, Bc, Nc, h2c, geo, T, hull, sidesToSearch(driverK), ...
        passSeat.Params .* [1 -1 1 -1 -1 1 1 1], options);
    if driverMirror.Score > driverSeat.Score
        driverSeat = driverMirror;
        say('driver seat: mirrored start was better (%.3f m^2)', driverSeat.Score);
    end
end

%% 6. Faces belonging to each object
comp = fcn_INTERNAL_meshPieces(V, F, faceArea);
result = struct();
if options.Seats
    driverSeat = fcn_INTERNAL_seatFaces(driverSeat, P, pointFace, F, V, faceArea, faceBlocked, comp, T);
    passSeat   = fcn_INTERNAL_seatFaces(passSeat,   P, pointFace, F, V, faceArea, faceBlocked, comp, T);
    result.DriverSeat    = fcn_INTERNAL_cleanSeat(driverSeat);
    result.PassengerSeat = fcn_INTERNAL_cleanSeat(passSeat);
end
if options.SteeringWheel
    wheel = wheelSide{driverK};
    wheel = fcn_INTERNAL_wheelFaces(wheel, P, pointFace, F, V, faceArea, faceBlocked, comp, T);
    result.SteeringWheel = wheel;
end
result.DriveSide = driveSideNames{driverK};
result.DriveSideSource = sideSource;

result.Info.Templates = T;
result.Info.NumPoints = size(P,1);
result.Info.PointSpacing = options.PointSpacing;
result.Info.SeatScoresLeftRight = [seatSide{1}.Score, seatSide{2}.Score];
if options.SteeringWheel
    result.Info.WheelScoresLeftRight = [wheelSide{1}.Score, wheelSide{2}.Score];
end
result.Info.Geometry = geo;
result.Info.ElapsedSeconds = toc(timeStart);
say('done in %.1f s; drive side %s (%s)', result.Info.ElapsedSeconds, result.DriveSide, sideSource);

rng(oldRng);

% The objects stored in the mesh (second output): a number per face, and
% the objects' poses
if nargout > 1
    objectFields = {'DriverSeat', 'PassengerSeat', 'SteeringWheel'};
    faceObject = zeros(size(F,1),1);
    for ith_object = 1:numel(objectFields)
        if isfield(result, objectFields{ith_object}) && result.(objectFields{ith_object}).Found
            faceObject(result.(objectFields{ith_object}).Faces) = ith_object;
        end
    end
    vehicleMesh.FaceInteriorObject = faceObject;
    vehicleMesh.InteriorObjectNames = {'driver seat', 'passenger seat', 'steering wheel'};
    vehicleMesh.InteriorObjects = rmfield(result, 'Info');
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
    fcn_INTERNAL_plotResult(vehicleMesh, result, options.FigNum);
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



%% ======================================================================
%  Templates and vehicle geometry
%  ======================================================================

function T = fcn_INTERNAL_defaultTemplates(geo)
% Generic templates. Numbers marked E are engineering estimates (typical
% passenger-car seats and wheels), see REPORT_findInteriorObjects.md.
T.Seat.CushionLength    = 0.50;   % m, E (seat front edge to backrest)
T.Seat.Width            = 0.50;   % m, E (outer bolster to bolster)
T.Seat.CushionThickness = 0.14;   % m, E (the box reaches this far below the cushion top)
T.Seat.BackHeight       = 0.78;   % m, E (cushion top to headrest top, along the backrest)
T.Seat.BackThickness    = 0.16;   % m, E
T.Seat.ScaleRange       = [0.90 1.15];   % the whole seat may be this much smaller/larger
T.Seat.BackAngleRangeDeg    = [10 35];   % backrest from vertical
T.Seat.CushionPitchRangeDeg = [0 18];    % cushion front raised
T.Seat.YawRangeDeg  = [-8 8];
T.Seat.RollRangeDeg = [-5 5];
% Where to look (relative to the front axle / the vehicle size)
T.Seat.XBehindFrontAxle = [0.95 1.85];   % origin this far behind the front axle, m (E: Fit 1.27, Corolla 1.35, F-150/Expedition 1.6; more than ~2 m finds the rear seat)
T.Seat.YFromCenter = [0.20, max(0.30, geo.BodyWidth/2 - 0.25)];   % |y| of the seat center
% Height of the cushion top above the ground: at least ~0.18 m above the
% floor (taken as ground clearance + floor), and ~0.80 m below the roof
T.Seat.ZRange = [max(0.30, geo.GroundClearance + 0.18), max(0.45, geo.Height - 0.80)];
T.Seat.FoundScore = 1.5;    % m^2 of surface needed to say "found" (library run 2026-11-24: real seats 1.83 to 3.16; the 2010 Camry, whose download has no seats, 0.97 to 1.01 from door openings)
% Occupant zone (must be empty), in the seat's own frame
T.Seat.PenaltyOccupant = 3;
T.Seat.PenaltyFlatInside = 3;
T.Seat.SurfaceBonus = 1;     % surface on the cushion top / backrest front counts (1 + this) times
T.Seat.PenaltyBlocked  = 3;
T.Seat.PenaltyOutside  = 10;   % per meter of corner outside the hull

T.SteeringWheel.Diameter = 0.375;          % m, OUTER diameter, E (generic; the Fit's is 0.356-0.368)
T.SteeringWheel.GripRadius = 0.015;        % m, E: half the rim thickness; the ring radius = Diameter/2 - GripRadius
T.SteeringWheel.RadiusTolerance = 0.15;    % +-15 % on the radius
T.SteeringWheel.TubeRadius = 0.030;        % m, points this close to the rim circle count
T.SteeringWheel.TiltRangeDeg = [10 40];    % wheel plane from vertical
T.SteeringWheel.YawRangeDeg  = [-10 10];
T.SteeringWheel.AheadOfSeat  = [0.25 1.00];  % wheel center ahead of the seat origin, m
T.SteeringWheel.AboveSeat    = [0.10 0.65];  % wheel center above the seat origin, m
T.SteeringWheel.SideOfSeat   = [-0.12 0.12]; % lateral offset from the seat center, m
T.SteeringWheel.FoundScore = 0.06;           % m^2 of rim surface needed to say "found" (real wheels scored 0.11-0.16, empty searches 0-0.035)

T.Margin = 0.03;          % tight template margin for counting / face assignment, m
T.Softness = 0.010;       % sigmoid width of the smooth count, m
T.SearchMargin = 0.20;    % how far around the search region points are kept, m
T.SkinThickness = 0.05;   % points this close to the convex hull are "outer skin"
T.PieceInsideFraction = 0.60;  % a mesh piece this much inside the template is taken whole
T.PieceMaxSizeRatio = 1.30;    % ... if it is not much bigger than the template
end

function geo = fcn_INTERNAL_vehicleGeometry(vehicleMesh)
% Overall size and axle positions, from VehicleSpec/AxleX when present.
V = vehicleMesh.Vertices;
geo.XMin = min(V(:,1)); geo.XMax = max(V(:,1));
geo.Length = geo.XMax - geo.XMin;
geo.Height = max(V(:,3));
geo.MeshWidth = max(V(:,2)) - min(V(:,2));
geo.BodyWidth = geo.MeshWidth;
geo.GroundClearance = 0.15;    % E, typical car, used if VehicleSpec has none
if isfield(vehicleMesh,'VehicleSpec') && isstruct(vehicleMesh.VehicleSpec)
    sp = vehicleMesh.VehicleSpec;
    if isfield(sp,'OverallWidth') && ~isempty(sp.OverallWidth) && sp.OverallWidth > 0
        geo.BodyWidth = min(sp.OverallWidth, geo.MeshWidth);
    end
    if isfield(sp,'GroundClearance') && ~isempty(sp.GroundClearance) && sp.GroundClearance > 0
        geo.GroundClearance = sp.GroundClearance;
    end
    if isfield(sp,'OverallHeight') && ~isempty(sp.OverallHeight) && sp.OverallHeight > 0
        geo.Height = min(geo.Height, max(sp.OverallHeight, 0.9*geo.Height));
    end
end
if isfield(vehicleMesh,'AxleX') && numel(vehicleMesh.AxleX) >= 2
    geo.FrontAxleX = max(vehicleMesh.AxleX);
    geo.RearAxleX  = min(vehicleMesh.AxleX);
else
    % rough fallback: typical overhangs
    geo.FrontAxleX = geo.XMax - 0.22*geo.Length;
    geo.RearAxleX  = geo.XMin + 0.18*geo.Length;
end
end

function out = fcn_INTERNAL_mergeStruct(base, over)
% Copy every field of "over" into "base" (recursively for sub-structs).
out = base;
if isempty(over) || ~isstruct(over), return; end
fn = fieldnames(over);
for i = 1:numel(fn)
    if isfield(base, fn{i}) && isstruct(base.(fn{i})) && isstruct(over.(fn{i}))
        out.(fn{i}) = fcn_INTERNAL_mergeStruct(base.(fn{i}), over.(fn{i}));
    else
        out.(fn{i}) = over.(fn{i});
    end
end
end



%% ======================================================================
%  Points, hull, mesh pieces
%  ======================================================================

function [P, pointFace, faceArea, faceNormal] = fcn_INTERNAL_samplePoints(V, F, spacing)
% Random points on every triangle, about one per spacing^2 of area, plus
% each triangle's centroid (so tiny triangles still get one point).
A = V(F(:,1),:); B = V(F(:,2),:); C = V(F(:,3),:);
nrm = cross(B-A, C-A, 2);
faceArea = 0.5*vecnorm(nrm, 2, 2);
faceNormal = nrm./max(2*faceArea, eps);   % unit normal (its sign is not trusted)
nPer = floor(faceArea/spacing^2 + rand(size(faceArea)));
idx = repelem((1:size(F,1))', nPer);
r1 = sqrt(rand(numel(idx),1)); r2 = rand(numel(idx),1);
P1 = (1-r1).*A(idx,:) + r1.*(1-r2).*B(idx,:) + r1.*r2.*C(idx,:);
Pc = (A+B+C)/3;
P = [P1; Pc];
pointFace = [idx; (1:size(F,1))'];
end

function hull = fcn_INTERNAL_bodyHull(V, geo)
% Convex hull of the body (mirrors excluded by the body width), as planes
% n.p <= b. Used for "inside the body" and "outer skin" tests.
keep = abs(V(:,2)) <= geo.BodyWidth/2 + 0.01;
Vh = V(keep,:);
K = convhulln(Vh);
n = cross(Vh(K(:,2),:)-Vh(K(:,1),:), Vh(K(:,3),:)-Vh(K(:,1),:), 2);
len = vecnorm(n,2,2);
good = len > 1e-12;
n = n(good,:)./len(good); K = K(good,:);
b = sum(n.*Vh(K(:,1),:), 2);
cen = mean(Vh,1);
flip = (n*cen' - b) > 0;            % make the normals point outward
n(flip,:) = -n(flip,:); b(flip) = -b(flip);
hull.N = n; hull.B = b;
end

function d = fcn_INTERNAL_hullSignedDist(hull, P)
% Largest plane distance: < 0 inside the hull (exact depth to the nearest
% face plane), > 0 outside (approximate). Done in chunks to save memory.
d = zeros(size(P,1),1);
chunk = 20000;
for i = 1:chunk:size(P,1)
    j = i:min(i+chunk-1, size(P,1));
    d(j) = max(P(j,:)*hull.N' - hull.B', [], 2);
end
end

function comp = fcn_INTERNAL_meshPieces(V, F, faceArea)
% Connected pieces of the mesh (vertices at the same place are joined).
[~,~,w] = unique(round(V*1e5), 'rows');
Fw = w(F);
G = graph([Fw(:,1);Fw(:,2);Fw(:,3)], [Fw(:,2);Fw(:,3);Fw(:,1)], [], max(w));
c = conncomp(G);
comp.FaceComp = c(Fw(:,1))';
nC = max(comp.FaceComp);
comp.Area = accumarray(comp.FaceComp, faceArea, [nC 1]);
% bounding-box diagonal of each piece
Cf = (V(F(:,1),:) + V(F(:,2),:) + V(F(:,3),:))/3;
lo = zeros(nC,3); hi = zeros(nC,3);
for k = 1:3
    lo(:,k) = accumarray(comp.FaceComp, Cf(:,k), [nC 1], @min);
    hi(:,k) = accumarray(comp.FaceComp, Cf(:,k), [nC 1], @max);
end
comp.Diag = vecnorm(hi-lo, 2, 2);
end



%% ======================================================================
%  Oriented boxes
%  ======================================================================

function R = fcn_INTERNAL_rot(axisName, deg)
c = cosd(deg); s = sind(deg);
switch axisName
    case 'x', R = [1 0 0; 0 c -s; 0 s c];
    case 'y', R = [c 0 s; 0 1 0; -s 0 c];
    case 'z', R = [c -s 0; s c 0; 0 0 1];
end
end

function bx = fcn_INTERNAL_box(origin, R, localCenter, halfSize)
% An oriented box: center, axes (columns of R) and half sizes.
bx.Center = origin + (R*localCenter(:))';
bx.Axes = R;
bx.HalfSize = halfSize(:)';
end

function sd = fcn_INTERNAL_boxSignedDist(P, bx)
% Signed distance from points to an oriented box (< 0 inside).
L = (P - bx.Center)*bx.Axes;          % point coordinates in the box frame
q = abs(L) - bx.HalfSize;
outside = sqrt(sum(max(q,0).^2, 2));
inside = min(max(q,[],2), 0);
sd = outside + inside;
end

function C = fcn_INTERNAL_boxCorners(bx)
s = [-1 -1 -1; 1 -1 -1; 1 1 -1; -1 1 -1; -1 -1 1; 1 -1 1; 1 1 1; -1 1 1];
C = bx.Center + (s.*bx.HalfSize)*bx.Axes';
end



%% ======================================================================
%  Seat
%  ======================================================================

function S = fcn_INTERNAL_seatBoxes(p, T)
% Build the seat template from the pose p = [x y z yaw roll cushionPitch
% backAngle scale]. (x,y,z) is the "origin": the center of the rear edge
% of the cushion top, where the backrest meets the cushion.
O = p(1:3); yaw = p(4); roll = p(5); pc = p(6); ba = p(7); sc = p(8);
Lc = T.Seat.CushionLength*sc;  W = T.Seat.Width*sc;  Tc = T.Seat.CushionThickness*sc;
Hb = T.Seat.BackHeight*sc;     Tb = T.Seat.BackThickness*sc;
Rs = fcn_INTERNAL_rot('z',yaw)*fcn_INTERNAL_rot('x',roll);   % seat frame: forward, left, up
Rc = Rs*fcn_INTERNAL_rot('y',-pc);    % cushion frame (front edge raised by pc)
Rb = Rs*fcn_INTERNAL_rot('y',-ba);    % backrest frame (top leaned back by ba)
% Objects that should be FULL of surface
S.Cushion = fcn_INTERNAL_box(O, Rc, [Lc/2, 0, -Tc/2], [Lc/2, W/2, Tc/2]);
S.Back    = fcn_INTERNAL_box(O, Rb, [-Tb/2, 0, (Hb-0.05)/2], [Tb/2, W/2, (Hb+0.05)/2]);
% Occupant zones that should be EMPTY: lap (above the cushion) and torso
% (in front of the backrest)
% (they start 0.10 m off the seat surfaces so that bolsters and a
% sculpted cushion are not punished)
S.Lap   = fcn_INTERNAL_box(O, Rc, [(0.12+0.85*Lc)/2, 0, 0.21], [(0.85*Lc-0.12)/2, 0.35*W, 0.11]);
S.Torso = fcn_INTERNAL_box(O, Rb, [0.22, 0, (0.25+0.65*Hb)/2], [0.12, 0.30*W, (0.65*Hb-0.25)/2]);
% Thin slabs on the cushion top and the backrest front (for the bonus)
S.CushionTopSlab = fcn_INTERNAL_box(O, Rc, [Lc/2, 0, 0], [Lc/2, W/2, 0.035]);
S.BackFrontSlab  = fcn_INTERNAL_box(O, Rb, [0, 0, 0.05 + 0.375*Hb], [0.035, W/2, 0.375*Hb]);
S.CushionInner = fcn_INTERNAL_box(O, Rc, [Lc/2, 0, -(0.05 + Tc - 0.03)/2], [Lc/2, W/2, max(Tc - 0.08, 0.005)/2]);
S.Axes = Rs; S.Origin = O;
S.Dims = struct('CushionLength',Lc,'Width',W,'CushionThickness',Tc,'BackHeight',Hb,'BackThickness',Tb);
end

function [score, areaIn] = fcn_INTERNAL_seatScore(p, P, blocked, N, h2, T, hull, smooth)
% Score of one seat pose (m^2). smooth = true uses sigmoid weights.
S = fcn_INTERNAL_seatBoxes(p, T);
% Bonus: surface lying ON the cushion top (facing up) and ON the backrest
% front (facing forward) counts extra. This puts the template's cushion
% top where the real cushion top is, instead of letting the cushion box
% sink to grab floor area.
sl = S.CushionTopSlab; bk = S.BackFrontSlab;
onTop  = fcn_INTERNAL_boxSignedDist(P, sl) < 0 & abs(N*sl.Axes(:,3)) > 0.7;
onBack = fcn_INTERNAL_boxSignedDist(P, bk) < 0 & abs(N*bk.Axes(:,1)) > 0.7;
bonus = h2*sum((onTop | onBack) & ~blocked);
% Penalty: a second flat (up-facing) surface INSIDE the cushion, between
% 0.05 m under its top and 0.03 m above its bottom. A real cushion has
% only its top there; a template sunk into the footwell has the floor.
inner = S.CushionInner;
flatInside = h2*sum(fcn_INTERNAL_boxSignedDist(P, inner) < 0 & abs(N*inner.Axes(:,3)) > 0.7 & ~blocked);
sdObj = min(fcn_INTERNAL_boxSignedDist(P, S.Cushion), fcn_INTERNAL_boxSignedDist(P, S.Back));
sdOcc = min(fcn_INTERNAL_boxSignedDist(P, S.Lap),     fcn_INTERNAL_boxSignedDist(P, S.Torso));
m = T.Margin; s = T.Softness;
if smooth
    wIn  = 1./(1 + exp(-(m - sdObj)/s));
    wOcc = 1./(1 + exp(sdOcc/s));
else
    wIn  = double(sdObj < m);
    wOcc = double(sdOcc < 0);
end
areaIn = h2*sum(wIn(~blocked));
penBlocked = h2*sum(wIn(blocked));
penOcc = h2*sum(wOcc);
corners = [fcn_INTERNAL_boxCorners(S.Cushion); fcn_INTERNAL_boxCorners(S.Back)];
outside = sum(max(0, fcn_INTERNAL_hullSignedDist(hull, corners) + 0.02));
% Dividing by the scale stops the template from simply growing to
% swallow nearby floor/console: a bigger seat must bring more area.
score = (areaIn + T.Seat.SurfaceBonus*bonus)/p(8) - T.Seat.PenaltyOccupant*penOcc ...
    - T.Seat.PenaltyFlatInside*flatInside - T.Seat.PenaltyBlocked*penBlocked ...
    - T.Seat.PenaltyOutside*outside;
end

function seat = fcn_INTERNAL_searchSeat(P, pointBlocked, pointNormal, h2, geo, T, hull, side, startPose, options)
% Search one seat on one side (+1 left, -1 right).
yr = T.Seat.YFromCenter;
lb = [geo.FrontAxleX - T.Seat.XBehindFrontAxle(2), 0, T.Seat.ZRange(1), T.Seat.YawRangeDeg(1), ...
      T.Seat.RollRangeDeg(1), T.Seat.CushionPitchRangeDeg(1), T.Seat.BackAngleRangeDeg(1), T.Seat.ScaleRange(1)];
ub = [geo.FrontAxleX - T.Seat.XBehindFrontAxle(1), 0, T.Seat.ZRange(2), T.Seat.YawRangeDeg(2), ...
      T.Seat.RollRangeDeg(2), T.Seat.CushionPitchRangeDeg(2), T.Seat.BackAngleRangeDeg(2), T.Seat.ScaleRange(2)];
if side > 0, lb(2) = yr(1); ub(2) = yr(2); else, lb(2) = -yr(2); ub(2) = -yr(1); end

% Keep only points near the search region (the seat can reach about 1 m
% back/up from its origin and its width to the side)
mg = T.SearchMargin; sMax = T.Seat.ScaleRange(2);
reach = sMax*(T.Seat.BackHeight + T.Seat.CushionLength);
roi = P(:,1) > lb(1) - reach - mg & P(:,1) < ub(1) + reach + mg & ...
      P(:,2) > lb(2) - sMax*T.Seat.Width - mg & P(:,2) < ub(2) + sMax*T.Seat.Width + mg & ...
      P(:,3) > lb(3) - sMax*T.Seat.CushionThickness - mg & P(:,3) < ub(3) + reach + mg;
Pr = P(roi,:); Br = pointBlocked(roi); Nr = pointNormal(roi,:);

% the random hypotheses use every 3rd point (3x faster, same ranking)
fFast   = @(p) fcn_INTERNAL_seatScore(p, Pr(1:3:end,:), Br(1:3:end), Nr(1:3:end,:), 3*h2, T, hull, false);
fHard   = @(p) fcn_INTERNAL_seatScore(p, Pr, Br, Nr, h2, T, hull, false);
fSmooth = @(p) fcn_INTERNAL_seatScore(p, Pr, Br, Nr, h2, T, hull, true);
if isempty(startPose)
    nHyp = options.NumHypotheses; nRef = options.NumRefine;
else
    % local search around a given start (mirror of the other seat)
    startPose = min(max(startPose, lb), ub);
    nHyp = 0; nRef = 1;
end
[pBest, sBest] = fcn_INTERNAL_randomStartsAndRefine(fFast, fSmooth, lb, ub, nHyp, nRef, startPose, Pr);
[sHard, areaIn] = fHard(pBest);

S = fcn_INTERNAL_seatBoxes(pBest, T);
seat.Side = side;
seat.Params = pBest;
seat.SmoothScore = sBest;
seat.Score = sHard;
seat.AreaInside = areaIn;
seat.Found = sHard >= T.Seat.FoundScore;
seat.Origin = S.Origin;
seat.HipPointEstimate = S.Origin + (S.Axes*[0.12; 0; 0.09])';   % E: H-point sits ~0.1 m up/forward of the cushion-back corner
seat.Axes = S.Axes;
seat.YawDeg = pBest(4); seat.RollDeg = pBest(5);
seat.CushionPitchDeg = pBest(6); seat.BackAngleDeg = pBest(7); seat.Scale = pBest(8);
seat.Dims = S.Dims;
seat.Boxes.Cushion = S.Cushion; seat.Boxes.Back = S.Back;
seat.Boxes.Cushion.Corners = fcn_INTERNAL_boxCorners(S.Cushion);
seat.Boxes.Back.Corners = fcn_INTERNAL_boxCorners(S.Back);
seat.Template = S;
seat.LowerBound = lb; seat.UpperBound = ub;
end

function seat = fcn_INTERNAL_seatFaces(seat, P, pointFace, F, V, faceArea, faceBlocked, comp, T)
% Faces whose sample points are mostly inside the tight seat template,
% plus whole mesh pieces that lie mostly inside it.
S = seat.Template;
sd = min(fcn_INTERNAL_boxSignedDist(P, S.Cushion), fcn_INTERNAL_boxSignedDist(P, S.Back));
inPt = sd < T.Margin;
diagT = norm([max(S.Cushion.HalfSize(1)*2, 0) + S.Back.HalfSize(1)*2 + S.Back.HalfSize(3)*2*sind(seat.BackAngleDeg), ...
    S.Cushion.HalfSize(2)*2, S.Back.HalfSize(3)*2 + S.Cushion.HalfSize(3)*2]);
seat.Faces = fcn_INTERNAL_facesFromPoints(inPt, pointFace, F, faceArea, faceBlocked, comp, T, diagT);
seat.TemplateDiagonal = diagT;
if ~isempty(seat.Faces)
    Cf = (V(F(seat.Faces,1),:) + V(F(seat.Faces,2),:) + V(F(seat.Faces,3),:))/3;
    seat.Center = sum(Cf.*faceArea(seat.Faces),1)/sum(faceArea(seat.Faces));
else
    seat.Center = S.Cushion.Center;
end
end

function out = fcn_INTERNAL_cleanSeat(seat)
out = rmfield(seat, {'Template','SmoothScore','LowerBound','UpperBound','Params'});
out.Pose = seat.Params;   % [x y z yaw roll cushionPitch backAngle scale]
end



%% ======================================================================
%  Steering wheel
%  ======================================================================

function [score, rimArea] = fcn_INTERNAL_wheelScore(p, P, blocked, h2, T, smooth)
% Score of a steering-wheel ring pose p = [cx cy cz tiltDeg yawDeg R].
c = p(1:3); a = p(4); psi = p(5); R = p(6);
n = (fcn_INTERNAL_rot('z',psi)*[-cosd(a); 0; sind(a)])';  % normal toward the driver
d = P - c;
h = d*n';                                     % height above the wheel plane
rho = vecnorm(d - h.*n, 2, 2);                % distance from the wheel axis
dc = sqrt((rho - R).^2 + h.^2);               % distance from the rim circle
tube = T.SteeringWheel.TubeRadius; s = 0.6*T.Softness;
if smooth
    sig = @(x) 1./(1 + exp(-x/s));
    wRim = sig(tube - dc);
    % must be empty: in front of the wheel (the driver's hands/chest side)
    wClear = sig(h - 0.12).*sig(0.30 - h).*sig(R + 0.02 - rho);
    % must be empty: just outside the rim, in the wheel plane (rejects
    % flat dashboard panels that merely cut through the ring)
    wOut = sig(0.03 - abs(h)).*sig(rho - (R + 0.05)).*sig(R + 0.15 - rho);
else
    wRim = double(dc < tube);
    wClear = double(h > 0.12 & h < 0.30 & rho < R + 0.02);
    wOut = double(abs(h) < 0.03 & rho > R + 0.05 & rho < R + 0.15);
end
rimArea = h2*sum(wRim(~blocked));
score = rimArea - h2*(3*sum(wRim(blocked)) + 3*sum(wClear) + 1*sum(wOut));
end

function wheel = fcn_INTERNAL_searchWheel(P, pointBlocked, h2, T, seat, options)
% Search a steering wheel ahead of and above a seat.
W = T.SteeringWheel;
R0 = W.Diameter/2 - W.GripRadius;    % radius of the rim's center line
fwd = seat.Axes(:,1)';
% center = origin + ahead*fwd + side*left + up*z; parameterize directly in world x,y,z
O = seat.Origin;
lb = [O(1) + W.AheadOfSeat(1)*fwd(1), O(2) + W.SideOfSeat(1), O(3) + W.AboveSeat(1), W.TiltRangeDeg(1), W.YawRangeDeg(1), R0*(1-W.RadiusTolerance)];
ub = [O(1) + W.AheadOfSeat(2)*fwd(1), O(2) + W.SideOfSeat(2), O(3) + W.AboveSeat(2), W.TiltRangeDeg(2), W.YawRangeDeg(2), R0*(1+W.RadiusTolerance)];
mg = R0*(1+W.RadiusTolerance) + 0.35;
roi = P(:,1) > lb(1) - mg & P(:,1) < ub(1) + mg & P(:,2) > lb(2) - mg & P(:,2) < ub(2) + mg & ...
      P(:,3) > lb(3) - mg & P(:,3) < ub(3) + mg;
Pr = P(roi,:); Br = pointBlocked(roi);
fHard   = @(p) fcn_INTERNAL_wheelScore(p, Pr, Br, h2, T, false);
fSmooth = @(p) fcn_INTERNAL_wheelScore(p, Pr, Br, h2, T, true);
[pBest, sBest] = fcn_INTERNAL_randomStartsAndRefine(fHard, fSmooth, lb, ub, options.NumHypotheses, options.NumRefine, [], Pr);
[sHard, rimArea] = fHard(pBest);
wheel.Found = sHard >= W.FoundScore;
wheel.Score = sHard;
wheel.SmoothScore = sBest;
wheel.RimArea = rimArea;
wheel.Center = pBest(1:3);
wheel.Normal = (fcn_INTERNAL_rot('z',pBest(5))*[-cosd(pBest(4)); 0; sind(pBest(4))])';
wheel.Radius = pBest(6);
wheel.OuterDiameter = 2*(pBest(6) + W.GripRadius);
wheel.TiltDeg = pBest(4);
wheel.YawDeg = pBest(5);
wheel.Pose = pBest;
wheel.Faces = [];
end

function wheel = fcn_INTERNAL_wheelFaces(wheel, P, pointFace, F, V, faceArea, faceBlocked, comp, T)
% Faces of the rim, spokes and hub: inside a thin disk slab of the wheel.
d = P - wheel.Center; n = wheel.Normal;
h = d*n'; rho = vecnorm(d - h.*n, 2, 2);
inPt = rho < wheel.Radius + T.SteeringWheel.TubeRadius & h > -0.06 & h < 0.10;
diagT = norm([2*(wheel.Radius + T.SteeringWheel.TubeRadius), 2*(wheel.Radius + T.SteeringWheel.TubeRadius), 0.16]);
wheel.Faces = fcn_INTERNAL_facesFromPoints(inPt, pointFace, F, faceArea, faceBlocked, comp, T, diagT);
wheel = rmfield(wheel, 'SmoothScore');
end



%% ======================================================================
%  Shared helpers
%  ======================================================================

function faces = fcn_INTERNAL_facesFromPoints(inPt, pointFace, F, faceArea, faceBlocked, comp, T, templateDiag)
% A connected mesh piece is taken whole if most of its area is inside
% the template and it is not much bigger than the template (a seat
% modeled as its own piece). From any other piece (e.g. a cabin shell that
% also holds the floor and the doors) a face is taken only if nearly all
% of it (80 %) is inside the template.
nF = size(F,1);
fracIn = accumarray(pointFace, double(inPt), [nF 1]) ./ max(accumarray(pointFace, 1, [nF 1]), 1);
nC = numel(comp.Area);
areaInPiece = accumarray(comp.FaceComp, faceArea.*(fracIn >= 0.5 & ~faceBlocked), [nC 1]);
pieceWhole = areaInPiece./max(comp.Area, eps) >= T.PieceInsideFraction & ...
    comp.Diag <= T.PieceMaxSizeRatio*templateDiag;
faceIn = ~faceBlocked & (pieceWhole(comp.FaceComp) | fracIn >= 0.8);
faces = find(faceIn);
end

function [pBest, sBest] = fcn_INTERNAL_randomStartsAndRefine(fHard, fSmooth, lb, ub, nHyp, nRef, startPose, Pr)
% RANSAC-style search: score many random poses with the fast hard count,
% keep the best few that differ from each other, polish each with
% fminsearch on the smooth score, return the best.
d = numel(lb); span = ub - lb; span(span == 0) = 1;
Q = rand(nHyp, d);
if ~isempty(startPose), Q = [(startPose - lb)./span; Q]; end
if isempty(Pr) || size(Q,1) == 0
    pBest = lb + 0.5*span; sBest = -inf; return
end
s = zeros(size(Q,1),1);
for i = 1:size(Q,1)
    s(i) = fHard(lb + Q(i,:).*span);
end
[~, order] = sort(s, 'descend');
picks = [];
for i = order'
    if isempty(picks) || min(vecnorm(Q(picks,:) - Q(i,:), 2, 2)) > 0.15
        picks(end+1) = i; %#ok<AGROW>
    end
    if numel(picks) >= nRef, break; end
end
opts = optimset('Display','off','MaxFunEvals',250*d/4,'MaxIter',200*d/4,'TolX',1e-3,'TolFun',1e-5);
sBest = -inf; pBest = lb + Q(picks(1),:).*span;
for i = picks
    % optimize u = q + 1 (so that fminsearch's first steps are ~5 % of the range)
    obj = @(u) -fSmooth(lb + min(max(u-1,0),1).*span) + 50*sum((u-1 - min(max(u-1,0),1)).^2);
    u = fminsearch(obj, Q(i,:) + 1, opts);
    q = min(max(u-1,0),1);
    sc = fSmooth(lb + q.*span);
    if sc > sBest
        sBest = sc; pBest = lb + q.*span;
    end
end
end

function fcn_INTERNAL_say(verbose, varargin)
if verbose
    fprintf(1, 'findInteriorObjects: ');
    fprintf(1, varargin{:});
    fprintf(1, '\n');
end
end



%% ======================================================================
%  Plot
%  ======================================================================

function fcn_INTERNAL_plotResult(vehicleMesh, result, figNum)
% Mesh drawn faint, found faces colored, templates drawn as wire boxes /
% a ring. An existing figure is reused WITHOUT making it visible.
if ishghandle(figNum)
    fh = figNum; set(0, 'CurrentFigure', fh); clf(fh);
else
    fh = figure(figNum); %#ok<NASGU>
end
V = vehicleMesh.Vertices; F = vehicleMesh.Faces;
hold on
patch('Vertices',V,'Faces',F,'FaceColor',[0.7 0.7 0.7],'EdgeColor','none','FaceAlpha',0.06);
cols = struct('DriverSeat',[0.85 0.1 0.1],'PassengerSeat',[0.1 0.3 0.9],'SteeringWheel',[0.1 0.7 0.1]);
names = fieldnames(cols);
for i = 1:numel(names)
    if ~isfield(result, names{i}), continue; end
    obj = result.(names{i});
    if ~isempty(obj.Faces)
        patch('Vertices',V,'Faces',F(obj.Faces,:),'FaceColor',cols.(names{i}), ...
            'EdgeColor',cols.(names{i})*0.6,'FaceAlpha',0.9,'LineWidth',0.25);
    end
    if isfield(obj,'Boxes')
        fcn_INTERNAL_plotBox(obj.Boxes.Cushion, cols.(names{i}));
        fcn_INTERNAL_plotBox(obj.Boxes.Back, cols.(names{i}));
        plot3(obj.Origin(1),obj.Origin(2),obj.Origin(3),'k.','MarkerSize',18);
    elseif isfield(obj,'Radius')
        n = obj.Normal(:); e1 = cross(n,[0;0;1]); if norm(e1) < 1e-6, e1 = [0;1;0]; end
        e1 = e1/norm(e1); e2 = cross(n,e1);
        t = linspace(0,2*pi,73);
        ring = obj.Center' + obj.Radius*(e1*cos(t) + e2*sin(t));
        plot3(ring(1,:),ring(2,:),ring(3,:),'-','Color',[0 0.4 0],'LineWidth',2);
        q = obj.Center' + 0.25*n;
        plot3([obj.Center(1) q(1)],[obj.Center(2) q(2)],[obj.Center(3) q(3)],'k-','LineWidth',1.5);
    end
end
axis equal; grid on; xlabel('x (m, forward)'); ylabel('y (m, left)'); zlabel('z (m)');
title(sprintf('%s: drive side %s', strrep(vehicleMesh.Name,'_',' '), result.DriveSide));
view(-35, 25); camlight headlight; lighting gouraud
end

function fcn_INTERNAL_plotBox(bx, col)
C = fcn_INTERNAL_boxCorners(bx);
E = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
for k = 1:size(E,1)
    plot3(C(E(k,:),1), C(E(k,:),2), C(E(k,:),3), '-', 'Color', col*0.7, 'LineWidth', 1.2);
end
end
