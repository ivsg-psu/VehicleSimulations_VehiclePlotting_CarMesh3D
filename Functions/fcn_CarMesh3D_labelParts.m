function vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, options)
% fcn_CarMesh3D_labelParts
% Labels every face of a mesh as one of five vehicle parts:
%
%       'body', 'glass', 'wheel', 'light', 'trim'
%
% and assigns each face a display color and transparency (alpha). Labels
% come from matching the face's material name and group (object) name
% against a list of rules. Downloaded models usually name their
% materials and objects in a way these rules recognize (for example
% 'Glass', 'Windshield', 'Tire', 'Wheel_FL', 'HeadLight', 'Chrome').
% Users can add their own rules, which are checked first.
%
% Light faces are also given a light type, used to switch them on and off
% in fcn_CarMesh3D_plotVehicle: 'headlight' (the low beams, or both beams
% when no high beams are found), 'turnsignal', 'running', 'tail',
% 'backup', or 'highbeam'. The type comes from the names (for example
% 'TurnSignal', 'Reverse', 'TailLight', 'HighBeam'); a light with no
% recognized type becomes a headlight if it is in the front half of the
% vehicle, and a tail light if it is in the rear half. Then, with
% AutoHighBeams (default true), each side's headlight is split into a low
% beam and a high beam where its faces fall clearly into two clusters
% (two lamps side by side, or one above the other): the cluster nearer
% the middle of the car is the high beam (or the upper one, for lamps one
% above the other). This is a start: fix any mistakes in the label
% painter (fcn_CarMesh3D_paintLabels) or with fcn_CarMesh3D_editLabels.
%
% Wheel faces are also numbered by corner: 1 = front-left, 2 =
% front-right, 3 = rear-left, 4 = rear-right. This needs the mesh to be
% in the CarMesh3D vehicle frame (run fcn_CarMesh3D_normalizeMesh first).
% Faces named as wheel parts but centered in the middle half of the car's
% width are axles or drive shafts; they are labeled 'trim' instead, so
% they do not distort the wheel positions.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh,...
%           (PartRules=partRules),...
%           (BodyColor=[r g b]),...
%           (GlassAlpha=alpha),...
%           (UseMaterialColors=flag),...
%           (PartColors=partColors),...
%           (SeeThroughGlass=flag),...
%           (TextureColorParts=partList),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure, normalized with
%      fcn_CarMesh3D_normalizeMesh.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      PartRules: an N x 2 cell array of extra rules, checked BEFORE the
%      default rules. Each row is {pattern, partName}, where pattern is a
%      case-insensitive regular expression tested against the text
%      '<materialName> <groupName>' of each face, and partName is one of
%      'body', 'glass', 'wheel', 'light', 'trim'. Example:
%           PartRules = {'Material\.012','glass'; 'Object_7','wheel'}
%      Default is {} (use only the default rules).
%
%      The default rules, in order, are:
%           glass|window|windshield|windscreen|glazing   -> glass
%           tire|tyre|wheel|rim|hub|brake                -> wheel
%               (rim only at the start of a word, so 'trim' is not a wheel)
%           light|lamp|indicator|signal                  -> light
%           chrome|trim|grille|grill|mirror|plastic|rubber -> trim
%           (anything else)                              -> body
%
%      BodyColor: a 1 x 3 RGB color (values from 0 to 1) applied to ALL
%      body faces, replacing material colors. Default is [] (keep the
%      material colors; faces with no material color get a default gray).
%
%      GlassAlpha: the transparency of glass faces, from 0 (invisible) to
%      1 (opaque). Default is 0.35.
%
%      UseMaterialColors: true (default) to color faces from the file's
%      material colors where known. Set false for models colored by
%      texture images, whose material colors are just placeholders (often
%      all the same gray); faces then get one color per part (and
%      BodyColor for the body).
%
%      PartColors: an N x 2 cell array of {partName, [r g b]} pairs that
%      set the color of every face of a part, for example
%           PartColors = {'glass',[0.35 0.35 0.38]; 'trim',[0 0 0]}
%      These are applied last, so they override material colors and
%      BodyColor. Default is {} (none).
%
%      SeeThroughGlass: true (default) to use the see-through marks of a
%      mesh read with fcn_CarMesh3D_readGLB (its FaceTextureAlpha, when
%      SeeThroughReliable): see-through faces not labeled wheel or light
%      become glass (a lamp lens is see-through but stays a light), and faces labeled glass by name that are opaque in a
%      material that is see-through elsewhere (the painted black border of
%      a window) become trim. Meshes without these fields are not changed.
%
%      LampCovers: true (default) to make each separate piece of glass
%      that lies over a lamp part of that lamp: a piece (glass faces
%      joined by shared corners) at least half of whose faces are within
%      2% of the vehicle's length of a light face. Many downloads give
%      the lamp covers the window glass material. Windows that only touch
%      a lamp stay glass. A cover over a lamp with lenses of its own
%      (light faces near the cover with at least a quarter of its area)
%      is the lamp's clear cover: it is both, a light (of its lenses'
%      type) that is also glass (FaceAlsoParts), so that
%      fcn_CarMesh3D_plotVehicle draws it as glass while the lamp is off,
%      the lenses showing through, and lit while the lamp is on.
%      Last, fcn_CarMesh3D_findLampCovers looks behind each piece of
%      glass (and each light that is also glass) for a lamp within
%      LampCoverDistance: a cover that lies over a lamp becomes clear
%      glass (15% opaque, untinted), recorded as a cover of that lamp
%      in FaceCoverLamp, and fcn_CarMesh3D_plotVehicle tints it with the
%      lamp's color while the lamp is lit. With LampCovers false,
%      FaceCoverLamp is all zeros (no covers).
%
%      LampCoverDistance: how far behind a piece of glass to look for a
%      lamp, in meters (fcn_CarMesh3D_findLampCovers Distance). Default
%      is 0.05.
%
%      TextureColorParts: a cell array of part names whose faces take
%      their texture colors (FaceTextureColors, from fcn_CarMesh3D_readGLB
%      or fcn_CarMesh3D_transferTextureColors), for example
%           TextureColorParts = {'light','trim','wheel'}
%      applied after PartColors. Default is {} (none). Kept in the mesh
%      (TextureColorParts) so fcn_CarMesh3D_editLabels does the same for
%      faces it relabels.
%
%      FigNum: a figure number to plot the labeled parts. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with these fields added:
%           PartNames (5 x 1 cell): {'body';'glass';'wheel';'light';'trim'}
%           FacePartIndex (M x 1): index into PartNames for each face
%           FaceWheelIndex (M x 1): 0 for non-wheel faces, else 1 to 4
%               (1 FL, 2 FR, 3 RL, 4 RR)
%           FaceColors (M x 3): RGB display color of each face
%           FaceAlpha (M x 1): transparency of each face
%           LightTypeNames (6 x 1 cell): {'headlight';'turnsignal';
%               'running';'tail';'backup';'highbeam'}
%           FaceLightType (M x 1): index into LightTypeNames for light
%               faces, 0 for all other faces
%           TextureColorParts (cell): the TextureColorParts option
%           FaceAlsoParts (M x numel(PartNames) logical): the other parts
%               each face also belongs to (one column per part). A face is
%               drawn as its own part (FacePartIndex: light always wins);
%               a lamp's clear cover is a light that is also glass
%               (until fcn_CarMesh3D_findLampCovers makes the ones over a
%               lamp clear glass)
%           FaceCoverLamp (M x 1): for each face that is a lamp's clear
%               cover, the light type (index into LightTypeNames) of the
%               lamp it covers; 0 for all other faces
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findLampCovers
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_labelParts.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * Wheel-named faces near the centerline (axles) are now trim. Found
%   %   % when testing a downloaded FBX whose wheel groups included axles.
%   % * Added UseMaterialColors option, for texture-colored models
%   % * Added PartColors option, to set the color of any part
%   % * Light faces get a light type (FaceLightType), for switchable lights
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * SeeThroughGlass: glass from the see-through marks of .glb files
%   %   % (fcn_CarMesh3D_readGLB), and opaque window borders as trim
%   % * TextureColorParts: parts shown in their texture colors
%   % * SeeThroughGlass leaves faces labeled light alone (the Transit
%   %   % Connect's see-through lamp lenses had all become glass)
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * LampCovers: glass pieces lying over a lamp become part of it (the
%   %   % 2020 Supra, 2016 Explorer, 2006 Frontier, 2017 CX-3, and 2014
%   %   % Leaf had their lamp covers in the window glass material)
%   % * LampCovers: a glass cover over a lamp that has lenses of its own
%   %   % (light faces near it with at least a quarter of its area) stays
%   %   % glass, so the lenses show through (Sean, 14:35: the Fit's
%   %   % headlight covers were labeled headlight and hid its lenses)
%   % * FaceAlsoParts: a face can belong to more than one part, light
%   %   % always winning (Sean's multi-part faces, 01:57; Sean, 23:04:
%   %   % option B, drawn as glass while off). A lamp's clear cover is a
%   %   % light of its lenses' type that is also glass
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * High beams as a lamp type of their own, 'highbeam' (Sean, 03:19
%   %   % and 03:27: separate bulbs in separate places, as on the Fit);
%   %   % found by name, or by AutoHighBeams: each side's headlight split
%   %   % in two by position where its faces clearly form two clusters
%   %   % (the inner, or upper, one is the high beam), as a start to fix
%   %   % in the label painter. 'headlight' is the low beam (or both
%   %   % beams, when a vehicle has no high beams)
%
% 2026_11_23 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * Clear lamp covers (Sean, 09:22, option A): at the end of labeling,
%   %   % fcn_CarMesh3D_findLampCovers makes each cover lying over a lamp
%   %   % clear glass, recorded in the new per-face field FaceCoverLamp
%   %   % (the covered lamp's light type), which fcn_CarMesh3D_plotVehicle
%   %   % tints while that lamp is lit. New option LampCoverDistance

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_labelParts
%   % * Add a geometric fallback for STL files with no names: label faces
%   %   % near the four wheel locations as wheels, and steep faces in the
%   %   % cabin band as glass
%   % * Add an interactive labeling tool (click a region, choose a part)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.PartRules = {}    % N x 2 cell of {pattern, partName}, checked first
    options.BodyColor = []    % 1 x 3 RGB for all body faces
    options.GlassAlpha = 0.35 % Transparency of glass faces
    options.UseMaterialColors = true % Use the file's material colors?
    options.PartColors = {}   % N x 2 cell of {partName, [r g b]}
    options.SeeThroughGlass = true  % Use .glb see-through marks for glass?
    options.LampCovers = true       % Glass pieces lying over a lamp become that lamp?
    options.AutoHighBeams = true    % Split each headlight into low and high beams by position?
    options.LampCoverDistance = 0.05 % How far behind glass to look for a lamp it covers [m]
    options.TextureColorParts = {}  % Parts shown in their texture colors
    options.FigNum = []       % Figure to plot into; [] for no plot, -1 for fast mode
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
partNames = {'body';'glass';'wheel';'light';'trim'};

if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the vehicleMesh input
        requiredFields = {'Vertices','Faces','MaterialNames','FaceMaterialIndex','GroupNames','FaceGroupIndex'};
        if ~isstruct(vehicleMesh)
            error('vehicleMesh must be a CarMesh3D mesh structure');
        end
        for ith_field = 1:length(requiredFields)
            if ~isfield(vehicleMesh,requiredFields{ith_field})
                error('vehicleMesh is missing the field %s',requiredFields{ith_field});
            end
        end

        % Check the PartRules input
        if ~isempty(options.PartRules)
            if ~iscell(options.PartRules) || size(options.PartRules,2)~=2
                error('PartRules must be an N x 2 cell array of {pattern, partName}');
            end
            for ith_rule = 1:size(options.PartRules,1)
                if ~any(strcmpi(options.PartRules{ith_rule,2}, partNames))
                    error('PartRules row %d has an unknown part name: %s. Allowed: body, glass, wheel, light, trim.',ith_rule,char(options.PartRules{ith_rule,2}));
                end
            end
        end

        % Check the BodyColor input
        if ~isempty(options.BodyColor)
            if ~isnumeric(options.BodyColor) || ~isequal(size(options.BodyColor),[1 3]) || any(options.BodyColor<0) || any(options.BodyColor>1)
                error('BodyColor must be empty or a 1 x 3 RGB vector with values from 0 to 1');
            end
        end

        % Check the PartColors input
        if ~isempty(options.PartColors)
            if ~iscell(options.PartColors) || size(options.PartColors,2)~=2
                error('PartColors must be an N x 2 cell array of {partName, [r g b]}');
            end
            for ith_row = 1:size(options.PartColors,1)
                if ~any(strcmpi(options.PartColors{ith_row,1}, partNames))
                    error('PartColors row %d has an unknown part name: %s. Allowed: body, glass, wheel, light, trim.',ith_row,char(options.PartColors{ith_row,1}));
                end
                thisColor = options.PartColors{ith_row,2};
                if ~isnumeric(thisColor) || ~isequal(size(thisColor),[1 3]) || any(thisColor<0) || any(thisColor>1)
                    error('PartColors row %d must have a 1 x 3 RGB color with values from 0 to 1',ith_row);
                end
            end
        end

        % Check the UseMaterialColors input
        if ~(islogical(options.UseMaterialColors) || isnumeric(options.UseMaterialColors)) || ~isscalar(options.UseMaterialColors)
            error('UseMaterialColors must be true or false');
        end

        % Check the TextureColorParts input
        if ~iscell(options.TextureColorParts) || ~all(ismember(lower(options.TextureColorParts), partNames))
            error('TextureColorParts must be a cell array of part names: body, glass, wheel, light, trim');
        end

        % Check the GlassAlpha input
        if ~isnumeric(options.GlassAlpha) || ~isscalar(options.GlassAlpha) || options.GlassAlpha<0 || options.GlassAlpha>1
            error('GlassAlpha must be a number from 0 to 1');
        end

        % Check the LampCoverDistance input
        if ~isnumeric(options.LampCoverDistance) || ~isscalar(options.LampCoverDistance) ...
                || ~isfinite(options.LampCoverDistance) || options.LampCoverDistance<=0
            error('LampCoverDistance must be a positive number, in meters');
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

% Default rules, checked after any user rules
defaultRules = {...
    'glass|window|windshield|windscreen|glazing',      'glass';
    'tire|tyre|wheel|(^|[^a-z])rim|hub|brake',          'wheel';
    'light|lamp|indicator|signal',                      'light';
    'chrome|trim|grille|grill|mirror|plastic|rubber',   'trim'};
allRules = [options.PartRules; defaultRules];

% Label each unique (material, group) pair once, then copy to its faces
materialIndex = vehicleMesh.FaceMaterialIndex(:);
groupIndex = vehicleMesh.FaceGroupIndex(:);
[uniquePairs, ~, pairOfFace] = unique([materialIndex groupIndex], 'rows');
pairPart = ones(size(uniquePairs,1),1); % Default is body (1)
for ith_pair = 1:size(uniquePairs,1)
    labelText = [fcn_INTERNAL_nameOrEmpty(vehicleMesh.MaterialNames, uniquePairs(ith_pair,1)), ' ', ...
                 fcn_INTERNAL_nameOrEmpty(vehicleMesh.GroupNames,    uniquePairs(ith_pair,2))];
    for ith_rule = 1:size(allRules,1)
        if ~isempty(regexpi(labelText, allRules{ith_rule,1}, 'once'))
            pairPart(ith_pair) = find(strcmpi(allRules{ith_rule,2}, partNames));
            break;
        end
    end
end
facePartIndex = pairPart(pairOfFace);

% See-through marks of a .glb file: see-through faces are glass, and the
% opaque faces of a see-through material that were named glass (a window's
% painted border) are trim
flagHasTexture = isfield(vehicleMesh,'FaceTextureAlpha') && size(vehicleMesh.FaceTextureAlpha,1)==Nfaces;
if options.SeeThroughGlass && flagHasTexture && (~isfield(vehicleMesh,'SeeThroughReliable') || vehicleMesh.SeeThroughReliable)
    flagSeeThrough = vehicleMesh.FaceTextureAlpha < 0.9;
    % (not the wheels, 3, nor the lights, 4: a see-through lamp lens stays
    % a light, as the 2014 Transit Connect's do)
    facePartIndex(flagSeeThrough & facePartIndex~=3 & facePartIndex~=4) = 2;
    seeThroughMaterials = unique(materialIndex(flagSeeThrough & materialIndex>0));
    flagBorder = facePartIndex==2 & ~flagSeeThrough & ismember(materialIndex, seeThroughMaterials) & vehicleMesh.FaceTextureAlpha >= 0.95;
    facePartIndex(flagBorder) = 5;
end

% Number the wheels by corner, using the face centers
faceWheelIndex = zeros(Nfaces,1);
flagWheelFace = facePartIndex==3;
if any(flagWheelFace)
    if ~isfield(vehicleMesh,'Frame') || ~strcmp(vehicleMesh.Frame,'ISO8855')
        warning('on','backtrace');
        warning('The mesh is not in the CarMesh3D vehicle frame, so wheels cannot be numbered by corner. Run fcn_CarMesh3D_normalizeMesh first.');
    else
        faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
                       vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + ...
                       vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
        % Axles and drive shafts: wheel-named faces whose centers are in
        % the middle half of the width become trim
        halfWidthOfWheels = max(abs(faceCenters(flagWheelFace,2)));
        flagAxleFace = flagWheelFace & abs(faceCenters(:,2)) < 0.5*halfWidthOfWheels;
        facePartIndex(flagAxleFace) = 5;
        flagWheelFace = flagWheelFace & ~flagAxleFace;

        wheelCenters = faceCenters(flagWheelFace,:);
        xSplit = (min(wheelCenters(:,1)) + max(wheelCenters(:,1)))/2;
        flagFront = wheelCenters(:,1) > xSplit;
        flagLeft  = wheelCenters(:,2) > 0;
        cornerIndex = zeros(size(wheelCenters,1),1);
        cornerIndex( flagFront &  flagLeft) = 1; % FL
        cornerIndex( flagFront & ~flagLeft) = 2; % FR
        cornerIndex(~flagFront &  flagLeft) = 3; % RL
        cornerIndex(~flagFront & ~flagLeft) = 4; % RR
        faceWheelIndex(flagWheelFace) = cornerIndex;
    end
end

% Colors: material colors where known, else a default color per part
defaultPartColors = [...
    0.60 0.60 0.65;   % body
    0.15 0.20 0.25;   % glass
    0.10 0.10 0.10;   % wheel
    0.95 0.90 0.80;   % light
    0.20 0.20 0.20];  % trim
faceColors = defaultPartColors(facePartIndex,:);
if options.UseMaterialColors && isfield(vehicleMesh,'MaterialColors') && ~isempty(vehicleMesh.MaterialColors)
    flagHasMaterial = materialIndex>0;
    materialFaceColors = nan(Nfaces,3);
    materialFaceColors(flagHasMaterial,:) = vehicleMesh.MaterialColors(materialIndex(flagHasMaterial),:);
    flagKnownColor = all(~isnan(materialFaceColors),2);
    faceColors(flagKnownColor,:) = materialFaceColors(flagKnownColor,:);
end
if ~isempty(options.BodyColor)
    flagBody = facePartIndex==1;
    faceColors(flagBody,:) = repmat(options.BodyColor, sum(flagBody), 1);
end

% Colors set by part name override everything else
for ith_row = 1:size(options.PartColors,1)
    thisPart = find(strcmpi(options.PartColors{ith_row,1}, partNames));
    flagThisPart = facePartIndex==thisPart;
    faceColors(flagThisPart,:) = repmat(options.PartColors{ith_row,2}, sum(flagThisPart), 1);
end

% Texture colors, for the parts listed
textureColorParts = lower(reshape(options.TextureColorParts,1,[]));
if ~isempty(textureColorParts) && isfield(vehicleMesh,'FaceTextureColors') && size(vehicleMesh.FaceTextureColors,1)==Nfaces
    flagTextured = ismember(facePartIndex, find(ismember(partNames, textureColorParts)));
    faceColors(flagTextured,:) = vehicleMesh.FaceTextureColors(flagTextured,:);
end

% Alpha: glass faces get GlassAlpha, everything else is opaque
faceAlpha = ones(Nfaces,1);
faceAlpha(facePartIndex==2) = options.GlassAlpha;

% Lamp covers: separate glass pieces lying over a lamp become that lamp
flagClearCover = false(Nfaces,1);
if options.LampCovers && any(facePartIndex==2) && any(facePartIndex==4)
    [facePartIndex, flagClearCover] = fcn_INTERNAL_lampCovers(vehicleMesh, facePartIndex);
end

% Light types, for switchable lights
lightTypeNames = {'headlight';'turnsignal';'running';'tail';'backup';'highbeam'};
lightTypeRules = {...
    'high.?beam|hi.?beam|main.?beam',  'highbeam';
    'turn|indicator|blinker|signal',   'turnsignal';
    'reverse|backup|back_up',          'backup';
    'drl|running|daytime',             'running';
    'tail|brake|stop|rear',            'tail';
    'head|front',                      'headlight'};
faceLightType = zeros(Nfaces,1);
flagLightFace = facePartIndex==4;
if any(flagLightFace)
    % By name
    pairLightType = zeros(size(uniquePairs,1),1);
    for ith_pair = 1:size(uniquePairs,1)
        labelText = [fcn_INTERNAL_nameOrEmpty(vehicleMesh.MaterialNames, uniquePairs(ith_pair,1)), ' ', ...
                     fcn_INTERNAL_nameOrEmpty(vehicleMesh.GroupNames,    uniquePairs(ith_pair,2))];
        for ith_rule = 1:size(lightTypeRules,1)
            if ~isempty(regexpi(labelText, lightTypeRules{ith_rule,1}, 'once'))
                pairLightType(ith_pair) = find(strcmp(lightTypeRules{ith_rule,2}, lightTypeNames));
                break;
            end
        end
    end
    faceLightType(flagLightFace) = pairLightType(pairOfFace(flagLightFace));

    % By position, for lights whose names did not say
    flagUntyped = flagLightFace & faceLightType==0;
    if any(flagUntyped) && isfield(vehicleMesh,'Frame') && strcmp(vehicleMesh.Frame,'ISO8855')
        lightCentersX = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),1) + ...
            vehicleMesh.Vertices(vehicleMesh.Faces(:,2),1) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),1))/3;
        middleX = (min(vehicleMesh.Vertices(:,1)) + max(vehicleMesh.Vertices(:,1)))/2;
        faceLightType(flagUntyped & lightCentersX>=middleX) = 1; % headlight
        faceLightType(flagUntyped & lightCentersX<middleX)  = 4; % tail
    end

    % High beams: each side's headlight split in two, where its faces
    % clearly form two clusters (only when no high beams were named)
    if options.AutoHighBeams && ~any(faceLightType==6) && any(faceLightType==1)
        faceLightType = fcn_INTERNAL_splitHighBeams(vehicleMesh, faceLightType, flagClearCover);
    end

    % A clear cover takes the type of the nearest lens under it
    if any(flagClearCover)
        lensFaces = find(flagLightFace & ~flagClearCover & faceLightType>0);
        if ~isempty(lensFaces)
            faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
                vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
            coverFaces = find(flagClearCover);
            nearestLens = fcn_INTERNAL_nearestPoint(faceCenters(lensFaces,:), faceCenters(coverFaces,:));
            faceLightType(coverFaces) = faceLightType(lensFaces(nearestLens));
        end
    end
end

% The other parts each face also belongs to: a clear cover is also glass
faceAlsoParts = false(Nfaces, numel(partNames));
faceAlsoParts(flagClearCover, 2) = true;

vehicleMesh.PartNames = partNames;
vehicleMesh.LightTypeNames = lightTypeNames;
vehicleMesh.FaceLightType = faceLightType;
vehicleMesh.FacePartIndex = facePartIndex;
vehicleMesh.FaceWheelIndex = faceWheelIndex;
vehicleMesh.FaceColors = faceColors;
vehicleMesh.FaceAlpha = faceAlpha;
vehicleMesh.TextureColorParts = textureColorParts;
vehicleMesh.FaceAlsoParts = faceAlsoParts;

% Clear lamp covers: glass (or a light that is also glass) lying over a
% lamp becomes clear glass, recorded as a cover of that lamp
% (FaceCoverLamp), which fcn_CarMesh3D_plotVehicle tints while the lamp
% is lit. With LampCovers off, no face is a cover.
if options.LampCovers
    vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, Distance=options.LampCoverDistance, FigNum=-1);
    facePartIndex = vehicleMesh.FacePartIndex;
else
    vehicleMesh.FaceCoverLamp = zeros(Nfaces,1);
end

if flag_do_debug
    for ith_part = 1:length(partNames)
        fprintf(1,'\t%s: %d faces\n', partNames{ith_part}, sum(facePartIndex==ith_part));
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

    % Left: the vehicle in its display colors
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    title('Display colors and glass transparency');

    % Right: each part in a distinct false color
    nexttile;
    falseColors = [0.85 0.85 0.85; 0.20 0.60 1.00; 0.20 0.20 0.20; 1.00 0.85 0.10; 0.90 0.40 0.10];
    labelMesh = vehicleMesh;
    labelMesh.FaceColors = falseColors(facePartIndex,:);
    labelMesh.FaceAlpha = ones(Nfaces,1);
    fcn_CarMesh3D_plotVehicle(labelMesh, ShowEdges=true, FigNum=figNum);
    hold on;
    % Invisible lines just to make a legend of the part colors
    for ith_part = 1:length(partNames)
        plot3(NaN,NaN,NaN,'s','MarkerSize',10,'MarkerFaceColor',falseColors(ith_part,:),...
            'MarkerEdgeColor','k','DisplayName',sprintf('%s (%d faces)',partNames{ith_part},sum(facePartIndex==ith_part)));
    end
    legend(findobj(gca,'Type','line'),'Location','southoutside');
    title('Part labels');

    sgtitle(sprintf('Labeled parts: %s',vehicleMesh.Name),'Interpreter','none');
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

%% fcn_INTERNAL_nameOrEmpty
function nameString = fcn_INTERNAL_nameOrEmpty(nameList, index)
% Returns nameList{index}, or '' if the index is 0 or out of range
if index>=1 && index<=length(nameList)
    nameString = char(nameList{index});
else
    nameString = '';
end
end % Ends fcn_INTERNAL_nameOrEmpty

%% fcn_INTERNAL_lampCovers
function [facePartIndex, flagClearCover] = fcn_INTERNAL_lampCovers(vehicleMesh, facePartIndex)
% Each separate piece of glass (glass faces joined by shared corners)
% that lies mostly over a lamp becomes part of the lamp: a piece at least
% half of whose faces are within 2% of the vehicle's length of a light
% face's center. A piece over a lamp with lenses of its own is the lamp's
% clear cover (flagClearCover): a light that is also glass
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
vehicleLength = max(max(vertices,[],1) - min(vertices,[],1));
nearDistance = 0.02*vehicleLength;
glassFaces = find(facePartIndex==2);
lightCenters = centers(facePartIndex==4,:);

% The glass pieces: faces joined by shared corners (union-find on corners)
Ncorners = size(vertices,1);
parent = 1:Ncorners;
glassCorners = faces(glassFaces,:);
for ith_face = 1:size(glassCorners,1)
    rootA = fcn_INTERNAL_findRoot(parent, glassCorners(ith_face,1));
    for ith_corner = 2:3
        rootB = fcn_INTERNAL_findRoot(parent, glassCorners(ith_face,ith_corner));
        if rootA ~= rootB
            parent(rootB) = rootA;
        end
    end
end
pieceOfFace = zeros(numel(glassFaces),1);
for ith_face = 1:numel(glassFaces)
    pieceOfFace(ith_face) = fcn_INTERNAL_findRoot(parent, glassCorners(ith_face,1));
end

% Distance from each glass face to the nearest light face (in blocks)
nearestDistance = inf(numel(glassFaces),1);
blockSize = 400;
for first = 1:blockSize:numel(glassFaces)
    rows = first:min(numel(glassFaces), first+blockSize-1);
    glassCenters = centers(glassFaces(rows),:);
    squaredDistance = sum(glassCenters.^2,2) + sum(lightCenters.^2,2)' - 2*glassCenters*lightCenters';
    nearestDistance(rows) = sqrt(max(min(squaredDistance,[],2),0));
end
flagNear = nearestDistance <= nearDistance;

% Pieces mostly over a lamp become light. When the lamp has lenses of its
% own under the piece (light faces near it with at least a quarter of its
% area), the piece is the lamp's clear cover: a light that is also glass,
% drawn as glass while the lamp is off so the lenses show through it
% (Sean, 14:35: the Fit's headlight covers hid its lenses; Sean, 23:04:
% lit while the lamp is on)
[pieces, ~, pieceIndex] = unique(pieceOfFace);
nearShare = accumarray(pieceIndex, double(flagNear))./accumarray(pieceIndex, 1);
candidatePieces = find(nearShare >= 0.5);
faceAreas = 0.5*vecnorm(cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2), 2, 2);
lightFaces = find(facePartIndex==4);
coverPieces = [];
clearPieces = [];
for ith_candidate = candidatePieces(:)'
    pieceFaces = glassFaces(pieceIndex==ith_candidate);
    pieceArea = sum(faceAreas(pieceFaces));
    pieceCenters = centers(pieceFaces,:);
    flagLens = false(numel(lightFaces),1);
    for first = 1:blockSize:numel(lightFaces)
        rows = first:min(numel(lightFaces), first+blockSize-1);
        squaredDistance = sum(lightCenters(rows,:).^2,2) + sum(pieceCenters.^2,2)' - 2*lightCenters(rows,:)*pieceCenters';
        flagLens(rows) = sqrt(max(min(squaredDistance,[],2),0)) <= nearDistance;
    end
    lensArea = sum(faceAreas(lightFaces(flagLens)));
    if lensArea < 0.25*pieceArea
        coverPieces(end+1) = pieces(ith_candidate); %#ok<AGROW>
    else
        clearPieces(end+1) = pieces(ith_candidate); %#ok<AGROW>
    end
end
flagClearCover = false(size(facePartIndex));
flagClearCover(glassFaces(ismember(pieceOfFace, clearPieces))) = true;
facePartIndex(glassFaces(ismember(pieceOfFace, [coverPieces clearPieces]))) = 4;
end % Ends fcn_INTERNAL_lampCovers

%% fcn_INTERNAL_nearestPoint
function faceLightType = fcn_INTERNAL_splitHighBeams(vehicleMesh, faceLightType, flagClearCover)
% Each side's headlight faces (lenses, not clear covers) split into two
% clusters by position (2-means on the face centers): kept as a low beam
% and a high beam only when the split is clear: each cluster has at
% least 15% of the side's faces, and the clusters' centers are apart by
% more than four times the larger cluster's spread (standard deviation)
% along the direction that separates them, and by at least 3 cm. Lamps side by side: the inner one is the high beam; one
% above the other: the upper one.
faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
for sideSign = [1 -1]
    sideFaces = find(faceLightType==1 & ~flagClearCover & sign(faceCenters(:,2))==sideSign);
    if numel(sideFaces) < 8
        continue;
    end
    points = [faceCenters(sideFaces,1), abs(faceCenters(sideFaces,2)), faceCenters(sideFaces,3)];
    % (start from the two ends of the widest direction: across or up)
    [~, axisIndex] = max([max(points(:,2)) - min(points(:,2)), max(points(:,3)) - min(points(:,3))]);
    axisIndex = axisIndex + 1;
    [~, lowEnd] = min(points(:,axisIndex));
    [~, highEnd] = max(points(:,axisIndex));
    centers = points([lowEnd highEnd],:);
    for iteration = 1:20
        distances = [sum((points - centers(1,:)).^2, 2), sum((points - centers(2,:)).^2, 2)];
        [~, cluster] = min(distances, [], 2);
        if any(cluster==1) && any(cluster==2)
            newCenters = [mean(points(cluster==1,:),1); mean(points(cluster==2,:),1)];
        else
            break;
        end
        if max(abs(newCenters(:) - centers(:))) < 1e-6
            break;
        end
        centers = newCenters;
    end
    shares = [mean(cluster==1), mean(cluster==2)];
    if min(shares) < 0.15
        continue;
    end
    direction = centers(2,:) - centers(1,:);
    gap = norm(direction);
    direction = direction/max(gap, eps);
    along = points*direction';
    spread = max(std(along(cluster==1)), std(along(cluster==2)));
    if gap < 0.03 || gap < 4*spread
        continue;
    end
    % (side by side, the inner one is the high beam; one above the other,
    % the upper one)
    if abs(centers(1,2) - centers(2,2)) >= abs(centers(1,3) - centers(2,3))
        [~, highCluster] = min(centers(:,2));
    else
        [~, highCluster] = max(centers(:,3));
    end
    faceLightType(sideFaces(cluster==highCluster)) = 6;
end
end

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

%% fcn_INTERNAL_findRoot
function root = fcn_INTERNAL_findRoot(parent, index)
% The root of a union-find tree (no path compression: the trees are small)
root = index;
while parent(root) ~= root
    root = parent(root);
end
end % Ends fcn_INTERNAL_findRoot
