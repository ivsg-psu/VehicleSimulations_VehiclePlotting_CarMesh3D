function report = fcn_CarMesh3D_importReport(vehicleMesh, options)
% fcn_CarMesh3D_importReport
% The report on a downloaded mesh after its first, coarse labels (step 1B
% of the plan of 2026-11-27): can the build go on, and where is the glass?
%
% The import order agreed with Sean (2026-11-27 04:03): import; coarse
% labels (glass and lamps, from the download's names or painted); face
% direction fixes; labels worked out from geometry (lamp covers, overlay
% lifting); fine painting; the lamp functions. This report comes after the
% coarse labels. It does not use the direction faces point.
%
% It answers three things:
%   1. The gate (Q4 (A)): are lamps and glass told apart? The build needs
%      lamp faces (light faces with a lamp type), and no face that is both
%      lamp and glass (a light face also marked glass). If not, the lamps
%      must be painted before going on.
%   2. Where the glass is, by connected piece of glass:
%        - over a lamp: a lamp cover (as fcn_CarMesh3D_findLampCovers
%          finds them);
%        - a window: not over a lamp, and centered above WindowHeight of
%          the vehicle's height (the windows sit above the belt line);
%        - elsewhere: anything else, glass low on the vehicle and not over
%          a lamp, which is most often a mislabel (Sean, 04:06: glass in
%          odd places makes lens detection go wrong) and should be fixed
%          before going on.
%   3. Which lamps are under glass. This is only reported: most downloads
%      are zero-thickness skins with lamps only in the texture, so a lamp
%      with no glass over it is common (Sean, 02:42).
%
% FORMAT:
%
%       report = fcn_CarMesh3D_importReport(vehicleMesh,...
%           (WindowHeight=fraction), (Distance=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh with coarse labels (LabelPartNames,
%      LabelFacePart, LabelLampNames, LabelFaceLamp), in meters, +Z up.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      WindowHeight: the fraction of the vehicle's height (from its lowest
%      point) above which a glass piece's center makes it a window.
%      Default 0.55.
%
%      Distance: how far from a glass face to look for the lamp it covers,
%      in meters (as in fcn_CarMesh3D_findLampCovers). Default 0.05.
%
%      FigNum: a figure to plot the glass by where it is (windows blue,
%      lamp covers cyan, elsewhere red) and the lamps (yellow). The report's
%      text is printed with the plot. If empty or omitted, no plot is made
%      and nothing is printed. If set to -1, input checking is skipped and
%      no plot is made (fast mode).
%
% OUTPUTS:
%
%      report: a structure with
%           Gate (true when lamps and glass are told apart), GateText,
%           NumGlassFaces, NumLampFaces, NumLampAlsoGlass,
%           GlassWhere (M x 1: 0 not glass, 1 window, 2 over a lamp,
%               3 elsewhere),
%           NumWindowFaces, NumCoverFaces, NumElsewhereFaces,
%           ElsewherePieces (a table: Faces, CenterX, CenterY, CenterZ, one
%               row per piece of glass found elsewhere, largest first),
%           LampsUnderGlass and LampsNotUnderGlass (lamp kind names),
%           Text (cell array of the report's lines).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findLampCovers
%
% EXAMPLES:
%
%       report = fcn_CarMesh3D_importReport(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_importReport.m for a
%       full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_importReport
%   % * First write (step 1B of the plan of 2026-11-27; the gate is Q4 (A))

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_importReport
%   % * Someday: find lamps that are not labeled, mainly from texture
%   %   % colors (Q4: "fairly easy to do")



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.WindowHeight = 0.55   % Fraction of the height above which glass is a window
    options.Distance = 0.05       % Meters: how far from glass to look for its lamp
    options.FigNum = []           % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces','LabelPartNames','LabelFacePart','LabelLampNames','LabelFaceLamp'}))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart, LabelLampNames, LabelFaceLamp)');
        end
        if ~(isnumeric(options.WindowHeight) && isscalar(options.WindowHeight) && options.WindowHeight >= 0 && options.WindowHeight <= 1)
            error('WindowHeight must be a fraction from 0 to 1');
        end
        if ~(isnumeric(options.Distance) && isscalar(options.Distance) && options.Distance > 0)
            error('Distance must be a positive number of meters');
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
numFaces = size(faces,1);
facePart = vehicleMesh.LabelFacePart(:);
faceLamp = double(vehicleMesh.LabelFaceLamp(:));
lampNames = vehicleMesh.LabelLampNames(:);
glassIndex = find(strcmp(vehicleMesh.LabelPartNames, 'glass'), 1);
lightIndex = find(strcmp(vehicleMesh.LabelPartNames, 'light'), 1);

flagGlass = false(numFaces,1);
if ~isempty(glassIndex)
    flagGlass = facePart == glassIndex;
end
flagLightAlsoGlass = false(numFaces,1);
if ~isempty(glassIndex) && ~isempty(lightIndex) && isfield(vehicleMesh,'LabelFaceAlsoParts') ...
        && size(vehicleMesh.LabelFaceAlsoParts,1)==numFaces && glassIndex <= size(vehicleMesh.LabelFaceAlsoParts,2)
    flagLightAlsoGlass = facePart == lightIndex & vehicleMesh.LabelFaceAlsoParts(:,glassIndex);
end
flagLamp = false(numFaces,1);
if ~isempty(lightIndex)
    flagLamp = facePart == lightIndex & faceLamp > 0 & ~flagLightAlsoGlass;
end

% 1. The gate: lamps and glass told apart
gateReasons = {};
if ~any(flagLamp)
    gateReasons{end+1} = 'no lamp faces (light faces with a lamp kind): paint the lamps';
end
if any(flagLightAlsoGlass)
    gateReasons{end+1} = sprintf('%d faces are both lamp and glass: paint which are lamp and which are glass', nnz(flagLightAlsoGlass));
end
gate = isempty(gateReasons);
if gate
    gateText = 'PASS: lamps and glass are told apart';
else
    gateText = ['STOP: ' strjoin(gateReasons, '; ')];
end

% 2. Where the glass is
glassWhere = zeros(numFaces,1);
flagCover = false(numFaces,1);
coverLamp = zeros(numFaces,1);
if any(flagGlass) && any(flagLamp)
    coveredMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, Distance=options.Distance, FigNum=-1);
    coverLamp = coveredMesh.LabelFaceCoverLamp(:);
    flagCover = flagGlass & coverLamp > 0;
end
faceCenters = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
lowest = min(vertices(:,3));
vehicleHeight = max(vertices(:,3)) - lowest;
elsewherePieces = table('Size',[0 4], 'VariableTypes',{'double','double','double','double'}, ...
    'VariableNames',{'Faces','CenterX','CenterY','CenterZ'});
glassFaces = find(flagGlass);
if ~isempty(glassFaces)
    pieceOfFace = fcn_INTERNAL_pieces(vertices, faces(glassFaces,:));
    for thisPiece = 1:max(pieceOfFace)
        theseFaces = glassFaces(pieceOfFace == thisPiece);
        pieceCenter = mean(faceCenters(theseFaces,:), 1);
        if mean(flagCover(theseFaces)) >= 0.5
            glassWhere(theseFaces) = 2;
        elseif pieceCenter(3) >= lowest + options.WindowHeight*vehicleHeight
            glassWhere(theseFaces) = 1;
        else
            glassWhere(theseFaces) = 3;
            elsewherePieces(end+1,:) = {numel(theseFaces), pieceCenter(1), pieceCenter(2), pieceCenter(3)}; %#ok<AGROW>
        end
    end
    elsewherePieces = sortrows(elsewherePieces, 'Faces', 'descend');
end

% 3. Lamps under glass
lampKinds = unique(faceLamp(flagLamp));
coveredKinds = unique(coverLamp(glassWhere == 2));
coveredKinds = coveredKinds(coveredKinds > 0);
lampsUnderGlass = lampNames(intersect(lampKinds, coveredKinds));
lampsNotUnderGlass = lampNames(setdiff(lampKinds, coveredKinds));

% The report
lines = {sprintf('Import report: %d faces', numFaces)};
lines{end+1} = sprintf('1. %s', gateText);
lines{end+1} = sprintf('   lamp faces %d, glass faces %d, faces both lamp and glass %d', nnz(flagLamp), nnz(flagGlass), nnz(flagLightAlsoGlass));
lines{end+1} = sprintf('2. Glass: %d faces in windows, %d over lamps, %d elsewhere', nnz(glassWhere==1), nnz(glassWhere==2), nnz(glassWhere==3));
if height(elsewherePieces) > 0
    lines{end+1} = sprintf('   CHECK: %d pieces of glass are low and not over a lamp (often a mislabel):', height(elsewherePieces));
    for ith_piece = 1:min(height(elsewherePieces), 10)
        lines{end+1} = sprintf('     %d faces at x %.2f, y %.2f, z %.2f', elsewherePieces.Faces(ith_piece), ...
            elsewherePieces.CenterX(ith_piece), elsewherePieces.CenterY(ith_piece), elsewherePieces.CenterZ(ith_piece)); %#ok<AGROW>
    end
end
lines{end+1} = sprintf('3. Lamps under glass: %s', fcn_INTERNAL_list(lampsUnderGlass));
lines{end+1} = sprintf('   Lamps with no glass over them (common; only reported): %s', fcn_INTERNAL_list(lampsNotUnderGlass));

report = struct('Gate', gate, 'GateText', gateText, 'NumGlassFaces', nnz(flagGlass), 'NumLampFaces', nnz(flagLamp), ...
    'NumLampAlsoGlass', nnz(flagLightAlsoGlass), 'GlassWhere', glassWhere, 'NumWindowFaces', nnz(glassWhere==1), ...
    'NumCoverFaces', nnz(glassWhere==2), 'NumElsewhereFaces', nnz(glassWhere==3), 'ElsewherePieces', elsewherePieces, ...
    'LampsUnderGlass', {lampsUnderGlass}, 'LampsNotUnderGlass', {lampsNotUnderGlass}, 'Text', {lines(:)});

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
    fprintf(1, '%s\n', lines{:});
    figure(figNum);
    clf;
    axesHandle = gca;
    hold(axesHandle,'on');
    groups = {~flagGlass & ~flagLamp & ~flagLightAlsoGlass, [0.80 0.80 0.80], 0.25, 'other faces';
        flagLamp, [1.00 0.85 0.10], 1, 'lamps';
        flagLightAlsoGlass, [1.00 0.45 0.00], 1, 'both lamp and glass';
        glassWhere==1, [0.20 0.40 0.90], 0.6, 'glass: windows';
        glassWhere==2, [0.10 0.85 0.95], 0.6, 'glass: over lamps';
        glassWhere==3, [0.90 0.10 0.10], 1, 'glass: elsewhere (check)'};
    for ith_group = 1:size(groups,1)
        if any(groups{ith_group,1})
            patch(axesHandle, 'Faces',faces(groups{ith_group,1},:), 'Vertices',vertices, 'FaceColor',groups{ith_group,2}, ...
                'FaceAlpha',groups{ith_group,3}, 'EdgeColor','none', ...
                'DisplayName',sprintf('%s (%d faces)', groups{ith_group,4}, nnz(groups{ith_group,1})));
        end
    end
    axis(axesHandle,'equal');
    axis(axesHandle,'off');
    view(axesHandle,-35,20);
    legend(axesHandle,'Location','southoutside');
    title(axesHandle, gateText, 'Interpreter','none');
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

%% fcn_INTERNAL_pieces
function pieceOfFace = fcn_INTERNAL_pieces(vertices, theseFaces)
% Numbers the connected pieces of the given faces: faces that share a
% corner (at the same position, to a micrometer) are in the same piece
numThese = size(theseFaces,1);
[~, ~, cornerId] = unique(round(vertices(theseFaces(:),:)*1e6), 'rows');
rows = sortrows([cornerId(:), repmat((1:numThese)',3,1)]);
flagSameAsNext = rows(1:end-1,1)==rows(2:end,1);
faceGraph = graph(rows([flagSameAsNext; false],2), rows([false; flagSameAsNext],2), [], numThese);
pieceOfFace = conncomp(faceGraph)';
end % Ends fcn_INTERNAL_pieces

%% fcn_INTERNAL_list
function textOut = fcn_INTERNAL_list(names)
% (names joined with commas, or "none")
if isempty(names)
    textOut = 'none';
else
    textOut = strjoin(names(:)', ', ');
end
end % Ends fcn_INTERNAL_list
