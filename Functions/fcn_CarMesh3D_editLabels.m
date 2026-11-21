function [vehicleMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh, options)
% fcn_CarMesh3D_editLabels
% Corrects part labels (and light types) that fcn_CarMesh3D_labelParts
% got wrong, for example headlights that a downloaded model put in the
% same material as its black trim. Edits can be given in a script, so
% they are repeatable, or made by clicking on the vehicle.
%
% SCRIPTED EDITS. Each edit is a structure that says which faces to pick
% and what to label them. Pick faces with any combination of these fields
% (a face must pass all of the ones given):
%       Region:      [xmin xmax ymin ymax zmin zmax], in meters, in the
%                    mesh's current frame; a face is picked if its center
%                    is inside
%       BothSides:   true to also pick the mirror image of Region across
%                    the centerline (y to -y), for left/right pairs
%       Material:    a regular expression matched to the material name
%       Group:       a regular expression matched to the group name
%       CurrentPart: only faces now labeled as this part
%       FaceIndices: a list of face numbers
% and say what they become with:
%       Part:        'body', 'glass', 'wheel', 'light', or 'trim'
%       LightType:   'headlight', 'turnsignal', 'running', 'tail', or
%                    'backup' (this also makes Part 'light')
%       Color:       optional [r g b] for the picked faces
%       Name:        optional description, printed in the summary
% Example: make both taillight housings into tail lights:
%       edits = {struct('Name','taillights', 'Region',[-0.8 -0.4 0.55 0.8 0.65 1.1], ...
%                       'BothSides',true, 'Material','color_notint', 'LightType','tail')};
%       vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits);
%
% INTERACTIVE EDITS. With Interactive=true, a window opens showing every
% part in its own color. Click on the vehicle to select faces (a whole
% connected piece, a single face, a whole material, or a whole group),
% choose a label from the menu, and press "Apply label". Press "Done"
% when finished. The edits are returned, and also printed as script
% lines (by region) that can be pasted into a script so the same
% corrections are made every time.
%
% Recommended place in the workflow: after fcn_CarMesh3D_fitMeshToSpec
% (so regions are in meters, with the origin below the rear axle), and
% before fcn_CarMesh3D_simplifyMesh.
%
% FORMAT:
%
%       [vehicleMesh, appliedEdits] = fcn_CarMesh3D_editLabels(vehicleMesh,...
%           (Edits=edits),...
%           (Interactive=flagInteractive),...
%           (GlassAlpha=alpha),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh structure (from
%      fcn_CarMesh3D_labelParts).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Edits: a cell array of edit structures (or a structure array), as
%      described above. They are applied in order. Default is {}.
%
%      Interactive: true to open the click-to-select editor after the
%      scripted edits are applied. Default is false.
%
%      GlassAlpha: the transparency given to faces that are changed to
%      glass. Default is 0.35.
%
%      FigNum: a figure number to plot the labels after editing. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with FacePartIndex, FaceLightType,
%      FaceWheelIndex, FaceColors, and FaceAlpha updated.
%
%      appliedEdits: a structure array with one element per edit made
%      (scripted and interactive), with the fields Name, Part,
%      LightType, and FaceIndices (the faces that were changed).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_editLabels.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Faces relabeled to a part shown in texture colors (labelParts
%   %   % TextureColorParts) keep their texture colors, unless the edit
%   %   % gives a color

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Add box (drag) selection in the interactive editor
%   % * Save and load edit lists to .mat files next to each model



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.Edits = {}          % Cell array (or struct array) of edits
    options.Interactive = false % Open the click-to-select editor?
    options.GlassAlpha = 0.35   % Transparency of faces changed to glass
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
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
lightTypeNames = {'headlight';'turnsignal';'running';'tail';'backup'};

% Edits may be a struct array or a cell array; use a cell array inside
editList = options.Edits;
if isstruct(editList)
    editList = num2cell(editList);
end

if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the vehicleMesh input
        requiredFields = {'Vertices','Faces','FacePartIndex','FaceColors','FaceAlpha'};
        if ~isstruct(vehicleMesh)
            error('vehicleMesh must be a CarMesh3D mesh structure');
        end
        for ith_field = 1:length(requiredFields)
            if ~isfield(vehicleMesh,requiredFields{ith_field})
                error('vehicleMesh is missing the field %s. Run fcn_CarMesh3D_labelParts first.',requiredFields{ith_field});
            end
        end

        % Check the Edits input
        if ~iscell(editList)
            error('Edits must be a cell array of structures (or a structure array)');
        end
        allowedFields = {'Name','Region','BothSides','Material','Group','CurrentPart','FaceIndices','Part','LightType','Color'};
        for ith_edit = 1:length(editList)
            thisEdit = editList{ith_edit};
            if ~isstruct(thisEdit) || ~isscalar(thisEdit)
                error('Edit %d must be a single structure',ith_edit);
            end
            unknownFields = setdiff(fieldnames(thisEdit), allowedFields);
            if ~isempty(unknownFields)
                error('Edit %d has unknown field(s): %s. Allowed: %s',ith_edit,strjoin(unknownFields,', '),strjoin(allowedFields,', '));
            end
            if ~fcn_INTERNAL_hasValue(thisEdit,'Part') && ~fcn_INTERNAL_hasValue(thisEdit,'LightType')
                error('Edit %d must say what to label the faces, with Part or LightType',ith_edit);
            end
            if fcn_INTERNAL_hasValue(thisEdit,'Part') && ~any(strcmpi(thisEdit.Part, partNames))
                error('Edit %d has an unknown Part: %s. Allowed: %s',ith_edit,char(thisEdit.Part),strjoin(partNames',', '));
            end
            if fcn_INTERNAL_hasValue(thisEdit,'LightType') && ~any(strcmpi(thisEdit.LightType, lightTypeNames))
                error('Edit %d has an unknown LightType: %s. Allowed: %s',ith_edit,char(thisEdit.LightType),strjoin(lightTypeNames',', '));
            end
            if fcn_INTERNAL_hasValue(thisEdit,'Region') && (~isnumeric(thisEdit.Region) || numel(thisEdit.Region)~=6)
                error('Edit %d: Region must be [xmin xmax ymin ymax zmin zmax]',ith_edit);
            end
            if fcn_INTERNAL_hasValue(thisEdit,'Color')
                if ~isnumeric(thisEdit.Color) || ~isequal(size(thisEdit.Color),[1 3]) || any(thisEdit.Color<0) || any(thisEdit.Color>1)
                    error('Edit %d: Color must be a 1 x 3 RGB vector with values from 0 to 1',ith_edit);
                end
            end
        end

        % Check the Interactive input
        if ~(islogical(options.Interactive) || isnumeric(options.Interactive)) || ~isscalar(options.Interactive)
            error('Interactive must be true or false');
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

% Make sure the light and wheel fields exist
if ~isfield(vehicleMesh,'LightTypeNames') || isempty(vehicleMesh.LightTypeNames)
    vehicleMesh.LightTypeNames = lightTypeNames;
end
if ~isfield(vehicleMesh,'FaceLightType') || isempty(vehicleMesh.FaceLightType)
    vehicleMesh.FaceLightType = zeros(Nfaces,1);
end
if ~isfield(vehicleMesh,'FaceWheelIndex') || isempty(vehicleMesh.FaceWheelIndex)
    vehicleMesh.FaceWheelIndex = zeros(Nfaces,1);
end

appliedEdits = struct('Name',{},'Part',{},'LightType',{},'FaceIndices',{});

% Scripted edits
for ith_edit = 1:length(editList)
    thisEdit = editList{ith_edit};
    selectedFaces = fcn_INTERNAL_selectFaces(vehicleMesh, thisEdit);
    [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_applyLabel(vehicleMesh, selectedFaces, ...
        fcn_INTERNAL_getValue(thisEdit,'Part',''), fcn_INTERNAL_getValue(thisEdit,'LightType',''), ...
        fcn_INTERNAL_getValue(thisEdit,'Color',[]), options.GlassAlpha);
    appliedEdits(end+1) = struct('Name', fcn_INTERNAL_getValue(thisEdit,'Name',sprintf('Edit %d',ith_edit)), ...
        'Part', newPart, 'LightType', newLightType, 'FaceIndices', selectedFaces(:)'); %#ok<AGROW>
    if 0==flag_max_speed && isempty(selectedFaces)
        warning('on','backtrace');
        warning('Edit %d (%s) did not pick any faces. Check its Region, Material, Group, and CurrentPart.', ...
            ith_edit, appliedEdits(end).Name);
    end
end

% Interactive edits
if options.Interactive
    [vehicleMesh, interactiveEdits] = fcn_INTERNAL_interactiveEditor(vehicleMesh, options.GlassAlpha);
    appliedEdits = [appliedEdits, interactiveEdits];
end

if flag_do_debug || (options.Interactive && 0==flag_max_speed)
    fcn_INTERNAL_printSummary(vehicleMesh, appliedEdits);
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
    axesHandle = axes;
    fcn_INTERNAL_drawLabels(axesHandle, vehicleMesh, false(Nfaces,1));
    view(axesHandle,-35,20);
    title(axesHandle,'Labels after editing (see legend)','Interpreter','none');
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

%% fcn_INTERNAL_hasValue
function flag = fcn_INTERNAL_hasValue(thisStruct, fieldName)
flag = isfield(thisStruct, fieldName) && ~isempty(thisStruct.(fieldName));
end % Ends fcn_INTERNAL_hasValue

%% fcn_INTERNAL_getValue
function value = fcn_INTERNAL_getValue(thisStruct, fieldName, defaultValue)
if fcn_INTERNAL_hasValue(thisStruct, fieldName)
    value = thisStruct.(fieldName);
else
    value = defaultValue;
end
end % Ends fcn_INTERNAL_getValue

%% fcn_INTERNAL_faceCenters
function faceCenters = fcn_INTERNAL_faceCenters(vehicleMesh)
faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
end % Ends fcn_INTERNAL_faceCenters

%% fcn_INTERNAL_selectFaces
function selectedFaces = fcn_INTERNAL_selectFaces(vehicleMesh, thisEdit)
% Returns the indices of the faces that pass every selection field given
Nfaces = size(vehicleMesh.Faces,1);
flagSelected = true(Nfaces,1);

if fcn_INTERNAL_hasValue(thisEdit,'FaceIndices')
    flagIndex = false(Nfaces,1);
    flagIndex(thisEdit.FaceIndices(thisEdit.FaceIndices>=1 & thisEdit.FaceIndices<=Nfaces)) = true;
    flagSelected = flagSelected & flagIndex;
end

if fcn_INTERNAL_hasValue(thisEdit,'Region')
    region = thisEdit.Region(:)';
    faceCenters = fcn_INTERNAL_faceCenters(vehicleMesh);
    flagInX = faceCenters(:,1)>=region(1) & faceCenters(:,1)<=region(2);
    flagInZ = faceCenters(:,3)>=region(5) & faceCenters(:,3)<=region(6);
    flagInY = faceCenters(:,2)>=region(3) & faceCenters(:,2)<=region(4);
    if fcn_INTERNAL_getValue(thisEdit,'BothSides',false)
        flagInY = flagInY | (-faceCenters(:,2)>=region(3) & -faceCenters(:,2)<=region(4));
    end
    flagSelected = flagSelected & flagInX & flagInY & flagInZ;
end

if fcn_INTERNAL_hasValue(thisEdit,'Material')
    if isfield(vehicleMesh,'MaterialNames') && isfield(vehicleMesh,'FaceMaterialIndex')
        flagMaterial = ~cellfun(@isempty, regexpi(vehicleMesh.MaterialNames, thisEdit.Material, 'once'));
        faceMaterial = vehicleMesh.FaceMaterialIndex(:);
        flagFace = false(Nfaces,1);
        flagFace(faceMaterial>0) = flagMaterial(faceMaterial(faceMaterial>0));
        flagSelected = flagSelected & flagFace;
    else
        flagSelected(:) = false;
    end
end

if fcn_INTERNAL_hasValue(thisEdit,'Group')
    if isfield(vehicleMesh,'GroupNames') && isfield(vehicleMesh,'FaceGroupIndex')
        flagGroup = ~cellfun(@isempty, regexpi(vehicleMesh.GroupNames, thisEdit.Group, 'once'));
        faceGroup = vehicleMesh.FaceGroupIndex(:);
        flagFace = false(Nfaces,1);
        flagFace(faceGroup>0) = flagGroup(faceGroup(faceGroup>0));
        flagSelected = flagSelected & flagFace;
    else
        flagSelected(:) = false;
    end
end

if fcn_INTERNAL_hasValue(thisEdit,'CurrentPart')
    partIndex = find(strcmpi(thisEdit.CurrentPart, vehicleMesh.PartNames));
    flagSelected = flagSelected & vehicleMesh.FacePartIndex(:)==partIndex;
end

selectedFaces = find(flagSelected);
end % Ends fcn_INTERNAL_selectFaces

%% fcn_INTERNAL_applyLabel
function [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_applyLabel(vehicleMesh, selectedFaces, newPart, newLightType, newColor, glassAlpha)
% Gives the selected faces a new part (and light type), with matching
% default colors and transparency
partNames = {'body';'glass';'wheel';'light';'trim'};
lightTypeNames = vehicleMesh.LightTypeNames;
defaultPartColors = [0.60 0.60 0.65; 0.15 0.20 0.25; 0.10 0.10 0.10; 0.95 0.90 0.80; 0.20 0.20 0.20];
defaultLightColors = [0.90 0.90 0.85; 0.85 0.55 0.15; 0.90 0.90 0.85; 0.55 0.05 0.05; 0.85 0.85 0.85];

if ~isempty(newLightType)
    newPart = 'light';
end
newPart = lower(char(newPart));
newLightType = lower(char(newLightType));
if isempty(selectedFaces)
    return;
end
partIndex = find(strcmp(newPart, partNames));
vehicleMesh.FacePartIndex(selectedFaces) = partIndex;

% Light type
if strcmp(newPart,'light') && ~isempty(newLightType)
    lightIndex = find(strcmp(newLightType, lightTypeNames));
    vehicleMesh.FaceLightType(selectedFaces) = lightIndex;
    defaultColor = defaultLightColors(lightIndex,:);
else
    vehicleMesh.FaceLightType(selectedFaces) = 0;
    defaultColor = defaultPartColors(partIndex,:);
end

% Wheel corner
if strcmp(newPart,'wheel')
    faceCenters = fcn_INTERNAL_faceCenters(vehicleMesh);
    allWheelFaces = find(vehicleMesh.FacePartIndex==3);
    xSplit = (min(faceCenters(allWheelFaces,1)) + max(faceCenters(allWheelFaces,1)))/2;
    theseCenters = faceCenters(selectedFaces,:);
    cornerIndex = 1 + (theseCenters(:,2)<=0) + 2*(theseCenters(:,1)<=xSplit); % 1 FL, 2 FR, 3 RL, 4 RR
    vehicleMesh.FaceWheelIndex(selectedFaces) = cornerIndex;
else
    vehicleMesh.FaceWheelIndex(selectedFaces) = 0;
end

% Color and transparency
flagNoColorGiven = isempty(newColor);
if isempty(newColor)
    newColor = defaultColor;
end
vehicleMesh.FaceColors(selectedFaces,:) = repmat(newColor, length(selectedFaces), 1);
% (parts shown in texture colors, set by fcn_CarMesh3D_labelParts
% TextureColorParts, keep them, unless the edit gave a color)
if flagNoColorGiven && isfield(vehicleMesh,'TextureColorParts') && any(strcmpi(newPart, vehicleMesh.TextureColorParts)) ...
        && isfield(vehicleMesh,'FaceTextureColors') && size(vehicleMesh.FaceTextureColors,1)==size(vehicleMesh.Faces,1)
    vehicleMesh.FaceColors(selectedFaces,:) = vehicleMesh.FaceTextureColors(selectedFaces,:);
end
if strcmp(newPart,'glass')
    vehicleMesh.FaceAlpha(selectedFaces) = glassAlpha;
else
    vehicleMesh.FaceAlpha(selectedFaces) = 1;
end
end % Ends fcn_INTERNAL_applyLabel

%% fcn_INTERNAL_labelColors
function [displayColors, legendNames, legendColors] = fcn_INTERNAL_labelColors(vehicleMesh)
% False colors that show each part and light type clearly
partColors = [0.80 0.80 0.80; 0.45 0.70 1.00; 0.15 0.15 0.15; 1.00 1.00 0.60; 0.80 0.45 0.15];
lightColors = [1.00 1.00 0.20; 1.00 0.55 0.00; 0.70 1.00 0.70; 0.90 0.05 0.05; 0.60 0.20 1.00];
Nfaces = size(vehicleMesh.Faces,1);
displayColors = partColors(vehicleMesh.FacePartIndex,:);
faceLightType = vehicleMesh.FaceLightType(:);
flagTyped = faceLightType>0;
displayColors(flagTyped,:) = lightColors(faceLightType(flagTyped),:);
legendNames = [{'body';'glass';'wheel';'light (no type)';'trim'}; strcat({'light: '}, vehicleMesh.LightTypeNames(:))];
legendColors = [partColors; lightColors];
if Nfaces==0
    displayColors = zeros(0,3);
end
end % Ends fcn_INTERNAL_labelColors

%% fcn_INTERNAL_drawLabels
function patchHandle = fcn_INTERNAL_drawLabels(axesHandle, vehicleMesh, flagSelected)
% Draws the mesh in label colors (selected faces in magenta), with a
% legend of the colors
[displayColors, legendNames, legendColors] = fcn_INTERNAL_labelColors(vehicleMesh);
displayColors(flagSelected,:) = repmat([1 0 1], sum(flagSelected), 1);
cla(axesHandle);
hold(axesHandle,'on');
patchHandle = patch(axesHandle,'Faces',vehicleMesh.Faces,'Vertices',vehicleMesh.Vertices,...
    'FaceVertexCData',displayColors,'FaceColor','flat','EdgeColor',[0.3 0.3 0.3],'EdgeAlpha',0.25,...
    'FaceLighting','flat','BackFaceLighting','lit','HandleVisibility','off');
for ith_entry = 1:length(legendNames)
    plot3(axesHandle,NaN,NaN,NaN,'s','MarkerSize',9,'MarkerFaceColor',legendColors(ith_entry,:),...
        'MarkerEdgeColor','k','DisplayName',legendNames{ith_entry});
end
plot3(axesHandle,NaN,NaN,NaN,'s','MarkerSize',9,'MarkerFaceColor',[1 0 1],'MarkerEdgeColor','k','DisplayName','selected');
legend(axesHandle,'Location','eastoutside');
axis(axesHandle,'equal');
grid(axesHandle,'on');
xlabel(axesHandle,'X [m]'); ylabel(axesHandle,'Y [m]'); zlabel(axesHandle,'Z [m]');
if isempty(findobj(axesHandle,'Type','light'))
    light('Parent',axesHandle,'Style','infinite','Position',[-1 -2 3]);
    light('Parent',axesHandle,'Style','infinite','Position',[2 1.5 1],'Color',[0.5 0.5 0.5]);
end
end % Ends fcn_INTERNAL_drawLabels

%% fcn_INTERNAL_connectedPieces
function pieceOfFace = fcn_INTERNAL_connectedPieces(vehicleMesh)
% Numbers the connected pieces of the mesh: faces that touch (share a
% corner position) and have the same material are in the same piece
Nfaces = size(vehicleMesh.Faces,1);
[~,~,mapIndex] = uniquetol(vehicleMesh.Vertices, 1e-6, 'ByRows', true);
mergedFaces = reshape(mapIndex(vehicleMesh.Faces), size(vehicleMesh.Faces));
if isfield(vehicleMesh,'FaceMaterialIndex') && ~isempty(vehicleMesh.FaceMaterialIndex)
    faceMaterial = vehicleMesh.FaceMaterialIndex(:);
else
    faceMaterial = ones(Nfaces,1);
end
rows = sortrows([mergedFaces(:), repmat(faceMaterial,3,1), repmat((1:Nfaces)',3,1)]);
flagSameAsNext = rows(1:end-1,1)==rows(2:end,1) & rows(1:end-1,2)==rows(2:end,2);
faceGraph = graph(rows([flagSameAsNext; false],3), rows([false; flagSameAsNext],3), [], Nfaces);
pieceOfFace = conncomp(faceGraph)';
end % Ends fcn_INTERNAL_connectedPieces

%% fcn_INTERNAL_pickFace
function faceIndex = fcn_INTERNAL_pickFace(vehicleMesh, clickPoint)
% Finds the face under a clicked 3D point: the face whose plane is
% closest to the point among faces that contain it, or else the face
% with the nearest center
V1 = vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:);
V2 = vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:);
V3 = vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:);
edge1 = V2 - V1;
edge2 = V3 - V1;
normals = cross(edge1, edge2, 2);
normals = normals ./ max(vecnorm(normals,2,2), eps);
toPoint = clickPoint(:)' - V1;
planeDistance = abs(sum(toPoint.*normals,2));
% Barycentric coordinates of the point projected onto each plane
d00 = sum(edge1.*edge1,2); d01 = sum(edge1.*edge2,2); d11 = sum(edge2.*edge2,2);
d20 = sum(toPoint.*edge1,2); d21 = sum(toPoint.*edge2,2);
denominator = max(d00.*d11 - d01.*d01, eps);
baryV = (d11.*d20 - d01.*d21)./denominator;
baryW = (d00.*d21 - d01.*d20)./denominator;
tolerance = 1e-3;
flagInside = baryV>=-tolerance & baryW>=-tolerance & (baryV+baryW)<=1+tolerance;
if any(flagInside)
    candidates = find(flagInside);
    [~, best] = min(planeDistance(candidates));
    faceIndex = candidates(best);
else
    faceCenters = (V1 + V2 + V3)/3;
    [~, faceIndex] = min(vecnorm(faceCenters - clickPoint(:)',2,2));
end
end % Ends fcn_INTERNAL_pickFace

%% fcn_INTERNAL_printSummary
function fcn_INTERNAL_printSummary(vehicleMesh, appliedEdits)
% Prints each edit, and script lines (by region) that repeat it
fprintf(1,'\nLabel edits made (%d):\n', length(appliedEdits));
faceCenters = fcn_INTERNAL_faceCenters(vehicleMesh);
for ith_edit = 1:length(appliedEdits)
    thisEdit = appliedEdits(ith_edit);
    fprintf(1,'  %d. %s: %d faces -> %s %s\n', ith_edit, thisEdit.Name, length(thisEdit.FaceIndices), thisEdit.Part, thisEdit.LightType);
end
if isempty(appliedEdits)
    return;
end
fprintf(1,'\nTo repeat these edits in a script, paste these lines before the call\n');
fprintf(1,'to fcn_CarMesh3D_editLabels and pass Edits=edits. Check that each\n');
fprintf(1,'region does not also pick faces you did not mean to change.\n\n');
fprintf(1,'edits = {};\n');
for ith_edit = 1:length(appliedEdits)
    thisEdit = appliedEdits(ith_edit);
    if isempty(thisEdit.FaceIndices)
        continue;
    end
    centers = faceCenters(thisEdit.FaceIndices,:);
    pad = 0.005;
    region = [min(centers(:,1))-pad max(centers(:,1))+pad min(centers(:,2))-pad max(centers(:,2))+pad min(centers(:,3))-pad max(centers(:,3))+pad];
    materialText = '';
    if isfield(vehicleMesh,'FaceMaterialIndex') && isfield(vehicleMesh,'MaterialNames')
        materials = unique(vehicleMesh.FaceMaterialIndex(thisEdit.FaceIndices));
        if isscalar(materials) && materials>0
            materialText = sprintf(', ''Material'',''^%s$''', regexptranslate('escape', vehicleMesh.MaterialNames{materials}));
        end
    end
    if isempty(thisEdit.LightType)
        labelText = sprintf('''Part'',''%s''', thisEdit.Part);
    else
        labelText = sprintf('''LightType'',''%s''', thisEdit.LightType);
    end
    fprintf(1,'edits{end+1} = struct(''Name'',''%s'', ''Region'',[%.3f %.3f %.3f %.3f %.3f %.3f]%s, %s);\n', ...
        thisEdit.Name, region, materialText, labelText);
end
fprintf(1,'\n');
end % Ends fcn_INTERNAL_printSummary

%% fcn_INTERNAL_interactiveEditor
function [vehicleMesh, interactiveEdits] = fcn_INTERNAL_interactiveEditor(vehicleMesh, glassAlpha)
% A window for selecting faces by clicking and giving them new labels.
% The window's UserData holds function handles (select, setTarget,
% apply, undo, clear, done) so that the editor can also be driven from
% code, for example in tests.

Nfaces = size(vehicleMesh.Faces,1);
pieceOfFace = fcn_INTERNAL_connectedPieces(vehicleMesh);
flagSelected = false(Nfaces,1);
interactiveEdits = struct('Name',{},'Part',{},'LightType',{},'FaceIndices',{});
undoStack = {};
targetNames = {'body','glass','wheel','trim','light: headlight','light: turnsignal', ...
    'light: running','light: tail','light: backup'};
selectModes = {'Connected piece','Single face','Same material','Same group'};

editorFigure = figure('Name','CarMesh3D label editor','NumberTitle','off', ...
    'Position',[80 80 1300 720],'CloseRequestFcn',@onClose);
axesHandle = axes('Parent',editorFigure,'Position',[0.24 0.06 0.62 0.86]);
patchHandle = fcn_INTERNAL_drawLabels(axesHandle, vehicleMesh, flagSelected);
set(patchHandle,'ButtonDownFcn',@onClick);
view(axesHandle,-35,20);
title(axesHandle,'Click to select (click again to unselect). Use "Rotate view" to turn the vehicle.','Interpreter','none');

controlX = 0.015; controlW = 0.20;
uicontrol(editorFigure,'Style','text','Units','normalized','Position',[controlX 0.90 controlW 0.04], ...
    'String','Select by:','HorizontalAlignment','left','FontWeight','bold');
modeMenu = uicontrol(editorFigure,'Style','popupmenu','Units','normalized','Position',[controlX 0.86 controlW 0.04], ...
    'String',selectModes,'Value',1);
uicontrol(editorFigure,'Style','text','Units','normalized','Position',[controlX 0.79 controlW 0.04], ...
    'String','Label as:','HorizontalAlignment','left','FontWeight','bold');
targetMenu = uicontrol(editorFigure,'Style','popupmenu','Units','normalized','Position',[controlX 0.75 controlW 0.04], ...
    'String',targetNames,'Value',1);
uicontrol(editorFigure,'Style','pushbutton','Units','normalized','Position',[controlX 0.66 controlW 0.06], ...
    'String','Apply label to selection','Callback',@(~,~) applyLabel());
uicontrol(editorFigure,'Style','pushbutton','Units','normalized','Position',[controlX 0.58 controlW 0.06], ...
    'String','Clear selection','Callback',@(~,~) clearSelection());
uicontrol(editorFigure,'Style','pushbutton','Units','normalized','Position',[controlX 0.50 controlW 0.06], ...
    'String','Undo last label','Callback',@(~,~) undoLast());
rotateButton = uicontrol(editorFigure,'Style','togglebutton','Units','normalized','Position',[controlX 0.42 controlW 0.06], ...
    'String','Rotate view (off)','Callback',@(src,~) toggleRotate(src));
uicontrol(editorFigure,'Style','pushbutton','Units','normalized','Position',[controlX 0.30 controlW 0.08], ...
    'String','Done','FontWeight','bold','Callback',@(~,~) finish());
statusText = uicontrol(editorFigure,'Style','text','Units','normalized','Position',[controlX 0.06 controlW 0.20], ...
    'String','No faces selected.','HorizontalAlignment','left');

% Handles for driving the editor from code
editorFigure.UserData = struct( ...
    'select', @(faceIndices) selectFaces(faceIndices), ...
    'setTarget', @(targetName) setTarget(targetName), ...
    'apply', @() applyLabel(), ...
    'undo', @() undoLast(), ...
    'clear', @() clearSelection(), ...
    'done', @() finish());

uiwait(editorFigure);
if isgraphics(editorFigure)
    delete(editorFigure);
end

    % --- Nested callbacks (they share the variables above) ---
    function onClick(~, eventData)
        faceIndex = fcn_INTERNAL_pickFace(vehicleMesh, eventData.IntersectionPoint);
        switch modeMenu.Value
            case 1 % Connected piece
                theseFaces = find(pieceOfFace==pieceOfFace(faceIndex));
            case 2 % Single face
                theseFaces = faceIndex;
            case 3 % Same material
                theseFaces = find(vehicleMesh.FaceMaterialIndex==vehicleMesh.FaceMaterialIndex(faceIndex));
            otherwise % Same group
                theseFaces = find(vehicleMesh.FaceGroupIndex==vehicleMesh.FaceGroupIndex(faceIndex));
        end
        if all(flagSelected(theseFaces))
            flagSelected(theseFaces) = false; % Click again to unselect
        else
            flagSelected(theseFaces) = true;
        end
        refresh();
    end

    function selectFaces(faceIndices)
        flagSelected(faceIndices) = true;
        refresh();
    end

    function setTarget(targetName)
        targetMenu.Value = find(strcmp(targetNames, targetName));
    end

    function applyLabel()
        theseFaces = find(flagSelected);
        if isempty(theseFaces)
            statusText.String = 'Nothing selected: click on the vehicle first.';
            return;
        end
        targetName = targetNames{targetMenu.Value};
        if startsWith(targetName,'light: ')
            newPart = 'light';
            newLightType = extractAfter(targetName,'light: ');
        else
            newPart = targetName;
            newLightType = '';
        end
        % Remember the old values, for undo
        undoStack{end+1} = struct('Faces',theseFaces, ...
            'Part',vehicleMesh.FacePartIndex(theseFaces), ...
            'LightType',vehicleMesh.FaceLightType(theseFaces), ...
            'Wheel',vehicleMesh.FaceWheelIndex(theseFaces), ...
            'Colors',vehicleMesh.FaceColors(theseFaces,:), ...
            'Alpha',vehicleMesh.FaceAlpha(theseFaces));
        [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_applyLabel(vehicleMesh, theseFaces, newPart, newLightType, [], glassAlpha);
        interactiveEdits(end+1) = struct('Name',sprintf('Clicked edit %d',length(interactiveEdits)+1), ...
            'Part',newPart,'LightType',newLightType,'FaceIndices',theseFaces(:)');
        flagSelected(:) = false;
        refresh();
        statusText.String = sprintf('Labeled %d faces as %s.', length(theseFaces), targetName);
    end

    function undoLast()
        if isempty(undoStack)
            statusText.String = 'Nothing to undo.';
            return;
        end
        lastChange = undoStack{end};
        undoStack(end) = [];
        vehicleMesh.FacePartIndex(lastChange.Faces) = lastChange.Part;
        vehicleMesh.FaceLightType(lastChange.Faces) = lastChange.LightType;
        vehicleMesh.FaceWheelIndex(lastChange.Faces) = lastChange.Wheel;
        vehicleMesh.FaceColors(lastChange.Faces,:) = lastChange.Colors;
        vehicleMesh.FaceAlpha(lastChange.Faces) = lastChange.Alpha;
        interactiveEdits(end) = [];
        refresh();
        statusText.String = 'Undid the last label.';
    end

    function clearSelection()
        flagSelected(:) = false;
        refresh();
    end

    function toggleRotate(sourceButton)
        if sourceButton.Value
            rotate3d(axesHandle,'on');
            sourceButton.String = 'Rotate view (on)';
        else
            rotate3d(axesHandle,'off');
            sourceButton.String = 'Rotate view (off)';
        end
    end

    function refresh()
        displayColors = fcn_INTERNAL_labelColors(vehicleMesh);
        displayColors(flagSelected,:) = repmat([1 0 1], sum(flagSelected), 1);
        patchHandle.FaceVertexCData = displayColors;
        statusText.String = sprintf('%d faces selected.', sum(flagSelected));
    end

    function finish()
        rotate3d(axesHandle,'off');
        uiresume(editorFigure);
    end

    function onClose(~,~)
        uiresume(editorFigure);
        delete(editorFigure);
    end
end % Ends fcn_INTERNAL_interactiveEditor
