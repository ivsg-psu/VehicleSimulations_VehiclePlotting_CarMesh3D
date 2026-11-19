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
% Wheel faces are also numbered by corner: 1 = front-left, 2 =
% front-right, 3 = rear-left, 4 = rear-right. This needs the mesh to be
% in the CarMesh3D vehicle frame (run fcn_CarMesh3D_normalizeMesh first).
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh,...
%           (PartRules=partRules),...
%           (BodyColor=[r g b]),...
%           (GlassAlpha=alpha),...
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
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_labelParts.m for a full test
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

        % Check the GlassAlpha input
        if ~isnumeric(options.GlassAlpha) || ~isscalar(options.GlassAlpha) || options.GlassAlpha<0 || options.GlassAlpha>1
            error('GlassAlpha must be a number from 0 to 1');
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
if isfield(vehicleMesh,'MaterialColors') && ~isempty(vehicleMesh.MaterialColors)
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

% Alpha: glass faces get GlassAlpha, everything else is opaque
faceAlpha = ones(Nfaces,1);
faceAlpha(facePartIndex==2) = options.GlassAlpha;

vehicleMesh.PartNames = partNames;
vehicleMesh.FacePartIndex = facePartIndex;
vehicleMesh.FaceWheelIndex = faceWheelIndex;
vehicleMesh.FaceColors = faceColors;
vehicleMesh.FaceAlpha = faceAlpha;

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
