function [units, faceUnit] = fcn_CarMesh3D_lampUnits(vehicleMesh, options)
% fcn_CarMesh3D_lampUnits

% Finds a vehicle's lamp units: each lamp the mesh has, as a set of faces
% with one lamp label (layer 2, meaning), named from where it sits
% ("front-left headlamp", "rear-center tail/brake lamp"), with the cover
% glass over it. The units are the rows of the lamp-to-function (L2F)
% matrix (Documentation_CarMesh3D_GUIdesign_lampFunctions.md, sections 3
% and 4): the matrix names units, never faces.
%
% How:
%   - Faces with one lamp label form a unit when they are within Gap of
%     each other (corner to corner). Pieces that touch are joined, and so
%     are the small scraps a painted label leaves around a lamp (the 2009
%     Fit's labels have 77 reflector pieces, most of them single faces,
%     around 8 real reflectors). Lamps on the two sides of a vehicle are
%     far apart, so they stay apart.
%   - Named from position (layer 1) and kind (layer 2): front or rear (x
%     against the middle of the vehicle's length), left or right (y; the
%     vehicle's left is +y), or center when the unit crosses the middle
%     (such as a high-mounted brake lamp); then the kind, from
%     fcn_CarMesh3D_lampTypes' labels ("Headlamp" gives "headlamp";
%     words in brackets are dropped: "Backup (reverse) lamp" gives "backup
%     lamp"). Two units with one name are numbered: "front-left marker
%     lamp 2".
%   - Cover glass: a face whose FaceCoverLamp names a kind belongs to the
%     nearest unit of that kind (within MaxCoverDistance); when the mesh
%     has no unit of that kind (the 2009 Fit's covers over its high beams,
%     which are its headlamps lit by the high-beam signal), to the nearest
%     unit of any kind.
%   - Labels only: what lights a unit (layer 3) is the L2F matrix's job,
%     so FaceLightFunctions is not read here.
%
% FORMAT:
%
%       [units, faceUnit] = fcn_CarMesh3D_lampUnits(vehicleMesh,...
%           (Gap=distance), (MaxCoverDistance=distance), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh (Vertices, Faces,
%      FaceLightType, LightTypeNames; FaceCoverLamp if it has covers).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Gap: faces of one kind closer than this (corner to corner, in the
%      mesh's units) are one unit. Default 0.03 (3 cm, in meters).
%
%      MaxCoverDistance: a cover face farther than this from every unit of
%      its kind belongs to none. Default 0.10.
%
%      FigNum: a figure to plot the units in (the mesh in gray, each unit
%      in its own color, with its name), turned with the CAD mouse. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      units: a structure array, one element per unit, ordered front to
%      rear, left to right, then by kind (fcn_CarMesh3D_lampTypes' order):
%           Name: "front-left headlamp" (unique)
%           Kind: the lamp kind's key ('headlight', 'marker', ...)
%           KindLabel: its name in words ('headlamp', 'marker lamp', ...)
%           Position: 'front-left', 'front-center', 'rear-right', ...
%           Faces: the unit's lamp faces (indices into vehicleMesh.Faces)
%           CoverFaces: its cover glass faces
%           Center: the middle of its lamp faces, [x y z]
%
%      faceUnit: one number per face: the unit its lamp face or cover face
%      belongs to (an index into units), or 0.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_lampTypes, fcn_CarMesh3D_addCadMouse (plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampUnits.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampUnits
%   % * First write (the lamp-functions plan, item 2; Q76 (A))
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (later; drafted with Claude)
% - In fcn_CarMesh3D_lampUnits
%   % * BUG fixed: a mesh whose lamp type names are a row (plotLabels'
%   %   % test mesh) failed ("Array dimensions ... must match")

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
    options.Gap = 0.03              % Faces of one kind closer than this are one unit
    options.MaxCoverDistance = 0.10 % A cover farther than this from every unit of its kind belongs to none
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
        % Check the vehicleMesh input
        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces','FaceLightType','LightTypeNames'})))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, FaceLightType, LightTypeNames)');
        end
        if numel(vehicleMesh.FaceLightType) ~= size(vehicleMesh.Faces,1)
            error('vehicleMesh.FaceLightType must have one value per face');
        end
        % Check the distances
        for optionName = {'Gap', 'MaxCoverDistance'}
            value = options.(optionName{1});
            if ~isnumeric(value) || ~isscalar(value) || value <= 0
                error('%s must be a positive number', optionName{1});
            end
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed) && ~isempty(options.FigNum)
    figNum = options.FigNum;
    flag_do_plots = 1;
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

vertices = double(vehicleMesh.Vertices);
faces = double(vehicleMesh.Faces);
numFaces = size(faces,1);
faceType = double(vehicleMesh.FaceLightType(:));
typeNames = cellstr(vehicleMesh.LightTypeNames);
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
middleX = (min(vertices(:,1)) + max(vertices(:,1)))/2;
halfWidth = max(abs(vertices(:,2)));

% The kinds' names in words and their order, from the one list
lampTypes = fcn_CarMesh3D_lampTypes();
kindOrder = zeros(numel(typeNames),1);
kindLabels = typeNames;
for ith_type = 1:numel(typeNames)
    listIndex = find(strcmp({lampTypes.Name}, typeNames{ith_type}), 1);
    if isempty(listIndex)
        kindOrder(ith_type) = numel(lampTypes) + ith_type;   % (a kind the list lacks: last, by its key)
    else
        kindOrder(ith_type) = listIndex;
        kindLabels{ith_type} = lower(strtrim(regexprep(lampTypes(listIndex).Label, '\s*\([^)]*\)', '')));
    end
end

% Each kind's faces, grouped: faces sharing a corner, or with corners
% within Gap, are one unit
unitKind = zeros(0,1);
unitFaces = cell(0,1);
for ith_type = 1:numel(typeNames)
    kindFaces = find(faceType == ith_type);
    if isempty(kindFaces)
        continue;
    end
    cornerIndex = faces(kindFaces,:);
    [cornerIDs, ~, cornerOfFace] = unique(cornerIndex(:));
    cornerOfFace = reshape(cornerOfFace, [], 3);
    cornerPoints = vertices(cornerIDs,:);
    numCorners = numel(cornerIDs);
    % (corners within Gap of each other, and the three corners of a face)
    nearPairs = fcn_INTERNAL_pairsWithin(cornerPoints, options.Gap);
    facePairs = [cornerOfFace(:,[1 2]); cornerOfFace(:,[2 3])];
    allPairs = [nearPairs; facePairs];
    cornerGroup = conncomp(graph(allPairs(:,1), allPairs(:,2), [], numCorners))';
    faceGroup = cornerGroup(cornerOfFace(:,1));
    for ith_group = unique(faceGroup)'
        unitKind(end+1,1) = ith_type; %#ok<AGROW>
        unitFaces{end+1,1} = kindFaces(faceGroup == ith_group); %#ok<AGROW>
    end
end
numUnits = numel(unitKind);

% Position and order: front to rear, left to right, then kind
unitCenter = zeros(numUnits,3);
unitFront = false(numUnits,1);
unitSide = zeros(numUnits,1);   % (1 left, 2 center, 3 right)
for ith_unit = 1:numUnits
    theseCenters = centers(unitFaces{ith_unit},:);
    unitCenter(ith_unit,:) = mean(theseCenters, 1);
    unitFront(ith_unit) = unitCenter(ith_unit,1) > middleX;
    lowY = min(theseCenters(:,2));
    highY = max(theseCenters(:,2));
    if (lowY < 0 && highY > 0) || abs(unitCenter(ith_unit,2)) < 0.05*halfWidth
        unitSide(ith_unit) = 2;
    elseif unitCenter(ith_unit,2) > 0
        unitSide(ith_unit) = 1;
    else
        unitSide(ith_unit) = 3;
    end
end
[~, order] = sortrows([~unitFront, unitSide, kindOrder(unitKind), -unitCenter(:,3), -unitCenter(:,1)]);
unitKind = unitKind(order);
unitFaces = unitFaces(order);
unitCenter = unitCenter(order,:);
unitFront = unitFront(order);
unitSide = unitSide(order);

% Names, numbered when two would be the same
sideWords = {'left', 'center', 'right'};
positions = cell(numUnits,1);
names = cell(numUnits,1);
for ith_unit = 1:numUnits
    if unitFront(ith_unit)
        positions{ith_unit} = ['front-' sideWords{unitSide(ith_unit)}];
    else
        positions{ith_unit} = ['rear-' sideWords{unitSide(ith_unit)}];
    end
    names{ith_unit} = [positions{ith_unit} ' ' kindLabels{unitKind(ith_unit)}];
end
for ith_unit = 1:numUnits
    sameName = find(strcmp(names, names{ith_unit}));
    if numel(sameName) > 1 && sameName(1) == ith_unit
        baseName = names{ith_unit};
        for ith_same = 2:numel(sameName)
            names{sameName(ith_same)} = sprintf('%s %d', baseName, ith_same);
        end
    end
end

% Covers: each cover face to the nearest unit of the kind it covers
faceUnit = zeros(numFaces,1);
for ith_unit = 1:numUnits
    faceUnit(unitFaces{ith_unit}) = ith_unit;
end
unitCovers = repmat({zeros(0,1)}, numUnits, 1);
if isfield(vehicleMesh, 'FaceCoverLamp') && numel(vehicleMesh.FaceCoverLamp) == numFaces
    coverKind = double(vehicleMesh.FaceCoverLamp(:));
    for ith_type = unique(coverKind(coverKind > 0))'
        kindUnits = find(unitKind == ith_type);
        coverFaces = find(coverKind == ith_type);
        if isempty(kindUnits)
            % (no unit of that kind: a cover over a kind that is only a
            % function of another lamp, such as the 2009 Fit's high-beam
            % covers over its headlamps; it goes to the nearest unit of
            % any kind)
            kindUnits = (1:numUnits)';
        end
        if isempty(kindUnits)
            continue;
        end
        unitFaceList = vertcat(unitFaces{kindUnits});
        unitOfList = repelem(kindUnits, cellfun(@numel, unitFaces(kindUnits)));
        [nearest, distance] = fcn_INTERNAL_nearest(centers(unitFaceList,:), centers(coverFaces,:));
        flagNear = distance <= options.MaxCoverDistance;
        coverUnit = unitOfList(nearest);
        for ith_cover = find(flagNear)'
            unitCovers{coverUnit(ith_cover)}(end+1,1) = coverFaces(ith_cover);
            if faceUnit(coverFaces(ith_cover)) == 0
                faceUnit(coverFaces(ith_cover)) = coverUnit(ith_cover);
            end
        end
    end
end

% (every list a column: with the lamp type names in a row, the kinds came
% out a row; found by plotLabels' test)
units = struct('Name', names, 'Kind', reshape(typeNames(unitKind), [], 1), ...
    'KindLabel', reshape(kindLabels(unitKind), [], 1), ...
    'Position', positions, 'Faces', unitFaces, 'CoverFaces', unitCovers, ...
    'Center', num2cell(unitCenter, 2));
units = units(:);

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    figure(figNum);
    clf;
    axesHandle = gca;
    faceColors = repmat([0.85 0.85 0.85], numFaces, 1);
    unitColors = lines(max(numUnits,1));
    for ith_unit = 1:numUnits
        faceColors(units(ith_unit).Faces,:) = repmat(unitColors(ith_unit,:), numel(units(ith_unit).Faces), 1);
        faceColors(units(ith_unit).CoverFaces,:) = repmat(0.5 + 0.5*unitColors(ith_unit,:), numel(units(ith_unit).CoverFaces), 1);
    end
    patch(axesHandle, 'Faces', faces, 'Vertices', vertices, 'FaceVertexCData', faceColors, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'none');
    hold(axesHandle, 'on');
    for ith_unit = 1:numUnits
        text(axesHandle, units(ith_unit).Center(1), units(ith_unit).Center(2), units(ith_unit).Center(3) + 0.08, ...
            units(ith_unit).Name, 'FontSize', 8, 'HorizontalAlignment', 'center', 'Interpreter', 'none');
    end
    axis(axesHandle, 'equal', 'off');
    view(axesHandle, 150, 20);
    fcn_CarMesh3D_addCadMouse(axesHandle);
    title(axesHandle, sprintf('%d lamp units (covers in a lighter shade)', numUnits));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_pairsWithin
function pairs = fcn_INTERNAL_pairsWithin(points, gap)
% The pairs of points closer than gap (each pair once), by sorting along x
% and comparing each point with the ones after it, up to gap away in x
% (no toolbox needed; a lamp kind has at most a few thousand corners)
numPoints = size(points,1);
[sortedX, order] = sort(points(:,1));
sortedPoints = points(order,:);
pairs = zeros(0,2);
for ith_point = 1:numPoints-1
    lastIndex = ith_point;
    while lastIndex < numPoints && sortedX(lastIndex+1) - sortedX(ith_point) < gap
        lastIndex = lastIndex + 1;
    end
    if lastIndex > ith_point
        candidates = (ith_point+1:lastIndex)';
        distances = vecnorm(sortedPoints(candidates,:) - sortedPoints(ith_point,:), 2, 2);
        near = candidates(distances < gap);
        pairs = [pairs; repmat(order(ith_point), numel(near), 1), order(near)]; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_pairsWithin

%% fcn_INTERNAL_nearest
function [nearestIndex, distance] = fcn_INTERNAL_nearest(fromPoints, toPoints)
% For each of toPoints, the nearest of fromPoints and its distance (in
% blocks, so the distance table stays small)
numTo = size(toPoints,1);
nearestIndex = zeros(numTo,1);
distance = zeros(numTo,1);
blockSize = 500;
for blockStart = 1:blockSize:numTo
    blockRows = blockStart:min(numTo, blockStart + blockSize - 1);
    squared = sum(toPoints(blockRows,:).^2, 2) + sum(fromPoints.^2, 2)' - 2*toPoints(blockRows,:)*fromPoints';
    [smallest, nearestIndex(blockRows)] = min(squared, [], 2);
    distance(blockRows) = sqrt(max(smallest, 0));
end
end % Ends fcn_INTERNAL_nearest
