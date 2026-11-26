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
%       Points:      an N x 3 list of face centers, in meters: the face
%                    whose center is nearest each point is picked, if it
%                    is within PointTolerance (default 0.005 m). Exact
%                    faces of a finished mesh, painted in the Model
%                    Reviewer (fcn_CarMesh3D_reviewVehicle), are given so
% and say what they become with:
%       Part:        'body', 'glass', 'wheel', 'light', 'trim', or
%                    'interior' (added to LabelPartNames if needed). ('delete',
%                    from edits written before 2026_11_23, now hides the
%                    faces, in the set 'hidden': see Hide)
%       Hide:        a hidden set's name (such as 'hard top' or 'rear
%                    wiper'), or true for the set 'hidden': the picked
%                    faces are hidden, not deleted. They keep their part,
%                    light type and colors, and stay in the mesh
%                    (LabelFaceHiddenSet: 0 for shown faces, else the set's
%                    number in LabelHiddenSetNames), so nothing downstream has
%                    a hole; fcn_CarMesh3D_plotVehicle does not draw them
%                    unless its ShowHidden names the set (a hard top put
%                    up in the rain), and the checks and outlines measure
%                    the shown faces (fcn_CarMesh3D_visibleMesh)
%       Unhide:      true to show the picked faces again
%       LightType:   'headlamp' (the low beam), 'highBeamLamp',
%                    'turnSignalLamp', 'runningLamp', 'tailBrakeLamp', 'backupLamp', 'fogLamp',
%                    'reflector', 'licensePlateLamp', 'markerLamp', or 'warningLamp'
%                    (the names of fcn_CarMesh3D_lampTypes; this also
%                    makes Part 'light')
%       AlsoLightTypes: more light types the picked faces also are (a
%                    cell array, such as {'turnSignalLamp'}: a rear lamp that
%                    is a tail light and flashes as a turn signal; a front
%                    running light that is a turn signal too). They are
%                    kept in LabelFaceAlsoLamps (one column per light
%                    type); fcn_CarMesh3D_plotVehicle lights the face for
%                    any of them. Faces that are not lights yet become
%                    lights of the first type given
%       AlsoParts:   other parts the picked faces also belong to (a cell
%                    array, such as {'glass'}: a lamp's clear cover, which
%                    is a light and also glass). They are kept in
%                    LabelFaceAlsoParts (one column per part); the face is
%                    still drawn as its own part (light always wins), and
%                    fcn_CarMesh3D_plotVehicle draws a light that is also
%                    glass as glass while the light is off. 'light' is not
%                    allowed here: give LightType, and the faces' other
%                    parts as AlsoParts. On a mesh that has LabelFaceCoverLamp
%                    (lamp covers, from fcn_CarMesh3D_findLampCovers),
%                    lights made also glass that lie over a lamp then
%                    become that lamp's clear cover (clear glass, tinted
%                    while the lamp is lit), as fcn_CarMesh3D_labelParts
%                    does
%       Color:       optional [r g b] for the picked faces
%       Name:        optional description, printed in the summary
% Example: make both taillight housings into tail lights:
%       edits = {struct('Name','taillights', 'Region',[-0.8 -0.4 0.55 0.8 0.65 1.1], ...
%                       'BothSides',true, 'Material','color_notint', 'LightType','tailBrakeLamp')};
%       vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits);
%
% INTERACTIVE EDITS. With FlagInteractive=true, a window opens showing every
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
%           (FlagInteractive=flagInteractive),...
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
%      FlagInteractive: true to open the click-to-select editor after the
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
%      vehicleMesh: the mesh with LabelFacePart, LabelFaceLamp,
%      FaceWheelIndex, FaceColors, and FaceAlpha updated (and
%      LabelFaceAlsoLamps, an Nfaces x numel(LabelLampNames) logical
%      matrix, when an edit gives AlsoLightTypes: each light face's
%      functions, its LabelFaceLamp among them; and LabelFaceAlsoParts, an
%      Nfaces x numel(LabelPartNames) logical matrix, when an edit gives
%      AlsoParts or the mesh has it: the other parts of each face. A new
%      Part or LightType clears the faces' other parts and functions).
%      LabelFaceCoverLamp (lamp covers), when the mesh has it, is kept one
%      row per face: a face given a new Part or LightType is no longer a
%      lamp's cover (0). A mesh without LabelFaceCoverLamp is left without it,
%      so fcn_CarMesh3D_plotVehicle still finds its covers when drawn.
%
%      appliedEdits: a structure array with one element per edit made
%      (scripted and interactive), with the fields Name, Part,
%      LightType, and FaceIndices (the faces that were changed).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findLampCovers (only after an AlsoParts edit adds
%      glass, on a mesh with LabelFaceCoverLamp)
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
%   %   % LabelTextureColorParts) keep their texture colors, unless the edit
%   %   % gives a color
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Part 'delete': the picked faces are taken out of the mesh (a part
%   %   % of the download not wanted, such as a rear wiper), written by the
%   %   % Model Reviewer for the vehicle's script
%   % * Points (with PointTolerance): faces picked by their centers, for
%   %   % the faces painted in the Model Reviewer on a finished mesh
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Hide and Unhide: faces hidden in named sets, not deleted (Sean,
%   %   % 04:07 to 04:21: a mesh with holes cannot be fixed downstream;
%   %   % a hidden hard top can be put back up by the animator). Part
%   %   % 'delete' (older edits files) now hides, in the set 'hidden'

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Part 'interior' (fcn_CarMesh3D_labelInterior): allowed in edits and
%   %   % in the editor; added to LabelPartNames when a mesh does not have it;
%   %   % its faces keep their own colors. Parts are found by name in the
%   %   % mesh's own LabelPartNames, and colored by name
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * AlsoLightTypes: a light face can have several functions (a tail
%   %   % light that is also a turn signal), kept in LabelFaceAlsoLamps;
%   %   % fcn_CarMesh3D_plotVehicle lights it for any of them (Sean's
%   %   % multi-function lights, 01:57)
%   % * AlsoParts: a face can belong to more than one part, light always
%   %   % winning (a lamp's clear cover: a light that is also glass), kept
%   %   % in LabelFaceAlsoParts (Sean's multi-part faces, 01:57; 23:04, B)

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * 'highBeamLamp' light type (Sean, 03:27); a mesh made before it gets it
%   %   % added to its LabelLampNames (and a column in LabelFaceAlsoLamps)
%   %   % when an edit needs it

% 2026_11_23 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Clear lamp covers (LabelFaceCoverLamp, from fcn_CarMesh3D_findLampCovers;
%   %   % Sean, 09:22, option A): kept one row per face (padded with zeros
%   %   % when faces were added); a face given a new Part or LightType is
%   %   % no longer a cover (also in the click editor, and undone with
%   %   % it); after an AlsoParts edit adds glass, lights now also glass
%   %   % that lie over a lamp become its clear cover
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * The lamp types, their default colors and label colors come from
%   %   % fcn_CarMesh3D_lampTypes, which adds fog, reflector, licenseplate,
%   %   % marker and warning (Sean, task 8)
%   % * Points: the nearest face is looked for among the faces that pass
%   %   % the edit's other fields (Material, Group, CurrentPart, Region,
%   %   % FaceIndices), so layered faces (a lamp lens a few millimeters
%   %   % over the lamp) are told apart; before, the nearest face of any
%   %   % kind was picked and could be the wrong layer (the 2009 Fit)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLabels
%   % * Colors of relabeled faces (Q88 (A), Sean 03:35; "a weird latent
%   %   % bug"): with no Color in the edit, a face whose label does not
%   %   % change keeps its color, and a face given a new part takes that
%   %   % part's usual color on this vehicle (the most common color of the
%   %   % part's other faces), the default only when there is none. Before,
%   %   % every face an edit touched took the part's default color: the
%   %   % 2009 Fit's rebuild turned 724 body faces from its blue to grey,
%   %   % where Sean had painted body over body with the Ctrl brush
%   % * The new lamp keys (Q92 (A)): LightType and AlsoLightTypes matched
%   %   % ignoring case and stored as fcn_CarMesh3D_lampTypes spells them
%   %   % (camelCase, so no longer lowered); the old editor's list from
%   %   % fcn_CarMesh3D_lampTypes

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
    options.FlagInteractive = false % Open the click-to-select editor?
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
labelPartNames = {'body';'glass';'wheel';'light';'trim';'interior'};
labelLampNames = {fcn_CarMesh3D_lampTypes().Name}';   % (one list for every function)

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
        requiredFields = {'Vertices','Faces','LabelFacePart','FaceColors','FaceAlpha'};
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
        allowedFields = {'Name','Region','BothSides','Material','Group','CurrentPart','FaceIndices','Points','PointTolerance','Part','LightType','AlsoLightTypes','AlsoParts','Color','Hide','Unhide'};
        for ith_edit = 1:length(editList)
            thisEdit = editList{ith_edit};
            if ~isstruct(thisEdit) || ~isscalar(thisEdit)
                error('Edit %d must be a single structure',ith_edit);
            end
            unknownFields = setdiff(fieldnames(thisEdit), allowedFields);
            if ~isempty(unknownFields)
                error('Edit %d has unknown field(s): %s. Allowed: %s',ith_edit,strjoin(unknownFields,', '),strjoin(allowedFields,', '));
            end
            if ~fcn_INTERNAL_hasValue(thisEdit,'Part') && ~fcn_INTERNAL_hasValue(thisEdit,'LightType') ...
                    && ~fcn_INTERNAL_hasValue(thisEdit,'AlsoLightTypes') && ~fcn_INTERNAL_hasValue(thisEdit,'AlsoParts') ...
                    && ~fcn_INTERNAL_hasValue(thisEdit,'Hide') && ~fcn_INTERNAL_hasValue(thisEdit,'Unhide')
                error('Edit %d must say what to do with the faces, with Part, LightType, AlsoLightTypes, AlsoParts, Hide or Unhide',ith_edit);
            end
            if fcn_INTERNAL_hasValue(thisEdit,'Hide') && ~(ischar(thisEdit.Hide) || isstring(thisEdit.Hide) || isequal(thisEdit.Hide, true))
                error('Edit %d: Hide must be a hidden set''s name (such as ''hard top''), or true for the set ''hidden''',ith_edit);
            end
            if fcn_INTERNAL_hasValue(thisEdit,'AlsoParts')
                alsoParts = lower(cellstr(thisEdit.AlsoParts));
                if any(strcmp(alsoParts,'light'))
                    error('Edit %d: AlsoParts cannot be ''light'' (light always wins): give LightType, and the other parts as AlsoParts',ith_edit);
                end
                if ~all(ismember(alsoParts, setdiff(labelPartNames, {'light'})))
                    error('Edit %d has an unknown AlsoParts entry. Allowed: %s',ith_edit,strjoin(setdiff(labelPartNames, {'light'}, 'stable')',', '));
                end
            end
            if fcn_INTERNAL_hasValue(thisEdit,'AlsoLightTypes') && ~all(ismember(lower(cellstr(thisEdit.AlsoLightTypes)), lower(labelLampNames)))
                error('Edit %d has an unknown AlsoLightTypes entry. Allowed: %s',ith_edit,strjoin(labelLampNames',', '));
            end
            if fcn_INTERNAL_hasValue(thisEdit,'Part') && ~any(strcmpi(thisEdit.Part, [labelPartNames; {'delete'}]))
                error('Edit %d has an unknown Part: %s. Allowed: %s, delete',ith_edit,char(thisEdit.Part),strjoin(labelPartNames',', '));
            end
            if fcn_INTERNAL_hasValue(thisEdit,'LightType') && ~any(strcmpi(thisEdit.LightType, labelLampNames))
                error('Edit %d has an unknown LightType: %s. Allowed: %s',ith_edit,char(thisEdit.LightType),strjoin(labelLampNames',', '));
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
        if ~(islogical(options.FlagInteractive) || isnumeric(options.FlagInteractive)) || ~isscalar(options.FlagInteractive)
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
if ~isfield(vehicleMesh,'LabelLampNames') || isempty(vehicleMesh.LabelLampNames)
    vehicleMesh.LabelLampNames = labelLampNames;
end
% (a mesh made before a light type was added gets it at the end, so its
% faces' type numbers stay as they are)
missingTypes = setdiff(labelLampNames, vehicleMesh.LabelLampNames, 'stable');
if ~isempty(missingTypes)
    vehicleMesh.LabelLampNames = [reshape(cellstr(vehicleMesh.LabelLampNames), [], 1); missingTypes(:)];
    if isfield(vehicleMesh,'LabelFaceAlsoLamps') && ~isempty(vehicleMesh.LabelFaceAlsoLamps)
        vehicleMesh.LabelFaceAlsoLamps(:, end+1:numel(vehicleMesh.LabelLampNames)) = false;
    end
end
if ~isfield(vehicleMesh,'LabelFaceLamp') || isempty(vehicleMesh.LabelFaceLamp)
    vehicleMesh.LabelFaceLamp = zeros(Nfaces,1);
end
if ~isfield(vehicleMesh,'FaceWheelIndex') || isempty(vehicleMesh.FaceWheelIndex)
    vehicleMesh.FaceWheelIndex = zeros(Nfaces,1);
end
% (lamp covers, LabelFaceCoverLamp: kept one row per face, padded with zeros,
% "not a cover", if faces were added since. Its numbers are light types,
% which stay as they are when a type is added at the end above. A mesh
% without it is left without it: fcn_CarMesh3D_plotVehicle finds its
% covers when it is drawn)
if isfield(vehicleMesh,'LabelFaceCoverLamp') && numel(vehicleMesh.LabelFaceCoverLamp) ~= Nfaces
    oldCovers = double(vehicleMesh.LabelFaceCoverLamp(:));
    vehicleMesh.LabelFaceCoverLamp = zeros(Nfaces,1);
    vehicleMesh.LabelFaceCoverLamp(1:min(Nfaces, numel(oldCovers))) = oldCovers(1:min(Nfaces, numel(oldCovers)));
end
flagFindCovers = false;   % (set when an edit makes lights also glass: they may be lamp covers)

appliedEdits = struct('Name',{},'Part',{},'LightType',{},'FaceIndices',{});

% Scripted edits
for ith_edit = 1:length(editList)
    thisEdit = editList{ith_edit};
    selectedFaces = fcn_INTERNAL_selectFaces(vehicleMesh, thisEdit);
    hideName = fcn_INTERNAL_getValue(thisEdit,'Hide','');
    if strcmpi(fcn_INTERNAL_getValue(thisEdit,'Part',''), 'delete')
        hideName = 'hidden';   % (older edits files: delete now hides)
    end
    if isequal(hideName, true)
        hideName = 'hidden';
    end
    if ~isempty(hideName) || isequal(fcn_INTERNAL_getValue(thisEdit,'Unhide',false), true)
        % (faces hidden in a named set, or shown again: they stay in the
        % mesh, with their labels)
        vehicleMesh = fcn_INTERNAL_hideFaces(vehicleMesh, selectedFaces, char(hideName));
        if isempty(hideName)
            newPart = 'unhide';
        else
            newPart = ['hide: ' char(hideName)];
        end
        newLightType = '';
    else
        newPart = '';
        newLightType = '';
        if fcn_INTERNAL_hasValue(thisEdit,'Part') || fcn_INTERNAL_hasValue(thisEdit,'LightType')
            [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_applyLabel(vehicleMesh, selectedFaces, ...
                fcn_INTERNAL_getValue(thisEdit,'Part',''), fcn_INTERNAL_getValue(thisEdit,'LightType',''), ...
                fcn_INTERNAL_getValue(thisEdit,'Color',[]), options.GlassAlpha);
        end
        if fcn_INTERNAL_hasValue(thisEdit,'AlsoLightTypes')
            [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_addLightFunctions(vehicleMesh, selectedFaces, ...
                fcn_INTERNAL_lampKey(cellstr(thisEdit.AlsoLightTypes)), newPart, newLightType, options.GlassAlpha);
        end
        if fcn_INTERNAL_hasValue(thisEdit,'AlsoParts')
            alsoParts = lower(cellstr(thisEdit.AlsoParts));
            vehicleMesh = fcn_INTERNAL_addAlsoParts(vehicleMesh, selectedFaces, alsoParts);
            % (recorded as 'light+glass': the part, then its other parts)
            newPart = [char(newPart) '+' strjoin(alsoParts, '+')];
            if any(strcmp(alsoParts, 'glass')) && ~isempty(selectedFaces)
                flagFindCovers = true;
            end
        end
    end
    appliedEdits(end+1) = struct('Name', fcn_INTERNAL_getValue(thisEdit,'Name',sprintf('Edit %d',ith_edit)), ...
        'Part', newPart, 'LightType', newLightType, 'FaceIndices', selectedFaces(:)'); %#ok<AGROW>
    if 0==flag_max_speed && isempty(selectedFaces)
        warning('on','backtrace');
        warning('Edit %d (%s) did not pick any faces. Check its Region, Material, Group, and CurrentPart.', ...
            ith_edit, appliedEdits(end).Name);
    end
end

% Interactive edits
if options.FlagInteractive
    [vehicleMesh, interactiveEdits] = fcn_INTERNAL_interactiveEditor(vehicleMesh, options.GlassAlpha);
    appliedEdits = [appliedEdits, interactiveEdits];
end

% Lamp covers: lights made also glass by an edit, lying over a lamp,
% become that lamp's clear cover, as in fcn_CarMesh3D_labelParts (only on
% a mesh that has LabelFaceCoverLamp; one without it has its covers found when
% it is drawn)
if flagFindCovers && isfield(vehicleMesh,'LabelFaceCoverLamp')
    vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, FigNum=-1);
end

if flag_do_debug || (options.FlagInteractive && 0==flag_max_speed)
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
function [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_addLightFunctions(vehicleMesh, selectedFaces, alsoTypes, newPart, newLightType, glassAlpha)
% Gives the selected faces more light functions (LabelFaceAlsoLamps: one
% column per light type, each light face's own type among them). Faces
% that are not lights yet become lights of the first type given.
Nfaces = size(vehicleMesh.Faces,1);
labelLampNames = vehicleMesh.LabelLampNames;
if ~isfield(vehicleMesh,'LabelFaceAlsoLamps') || size(vehicleMesh.LabelFaceAlsoLamps,1) ~= Nfaces ...
        || size(vehicleMesh.LabelFaceAlsoLamps,2) ~= numel(labelLampNames)
    functions = false(Nfaces, numel(labelLampNames));
    flagTyped = vehicleMesh.LabelFaceLamp(:) > 0;
    functions(sub2ind(size(functions), find(flagTyped), vehicleMesh.LabelFaceLamp(flagTyped))) = true;
    vehicleMesh.LabelFaceAlsoLamps = functions;
end
if isempty(selectedFaces)
    return;
end
flagNotLight = vehicleMesh.LabelFaceLamp(selectedFaces) == 0;
if any(flagNotLight)
    [vehicleMesh, ~, ~] = fcn_INTERNAL_applyLabel(vehicleMesh, selectedFaces(flagNotLight), 'light', alsoTypes{1}, [], glassAlpha);
end
typeColumns = find(ismember(labelLampNames, alsoTypes));
vehicleMesh.LabelFaceAlsoLamps(selectedFaces, typeColumns) = true;
if isempty(newPart)
    newPart = 'light';
end
if isempty(newLightType)
    newLightType = ['+' strjoin(alsoTypes, '+')];
else
    newLightType = [newLightType '+' strjoin(alsoTypes, '+')];
end
end % Ends fcn_INTERNAL_addLightFunctions

function vehicleMesh = fcn_INTERNAL_hideFaces(vehicleMesh, selectedFaces, setName)
% Hides faces in a named set (LabelFaceHiddenSet: the set's number in
% LabelHiddenSetNames), or shows them again (setName ''). The faces stay in
% the mesh, with their labels.
Nfaces = size(vehicleMesh.Faces,1);
if ~isfield(vehicleMesh,'LabelFaceHiddenSet') || numel(vehicleMesh.LabelFaceHiddenSet) ~= Nfaces
    vehicleMesh.LabelFaceHiddenSet = zeros(Nfaces,1);
end
if ~isfield(vehicleMesh,'LabelHiddenSetNames')
    vehicleMesh.LabelHiddenSetNames = cell(0,1);
end
if isempty(setName)
    vehicleMesh.LabelFaceHiddenSet(selectedFaces) = 0;
    return;
end
setIndex = find(strcmp(cellstr(vehicleMesh.LabelHiddenSetNames), setName), 1);
if isempty(setIndex)
    vehicleMesh.LabelHiddenSetNames{end+1,1} = setName;
    setIndex = numel(vehicleMesh.LabelHiddenSetNames);
end
vehicleMesh.LabelFaceHiddenSet(selectedFaces) = setIndex;
end % Ends fcn_INTERNAL_hideFaces

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
    partIndex = find(strcmpi(thisEdit.CurrentPart, vehicleMesh.LabelPartNames));
    flagSelected = flagSelected & vehicleMesh.LabelFacePart(:)==partIndex;
end

if fcn_INTERNAL_hasValue(thisEdit,'Points')
    % (the face nearest each point, if close enough, among the faces that
    % pass the other fields: with Material given, a lamp's inner layer and
    % the lens lying a few millimeters over it are told apart; found on
    % the 2009 Honda Fit, 2026_11_24)
    candidates = find(flagSelected);
    centers = fcn_INTERNAL_faceCenters(vehicleMesh);
    centers = centers(candidates,:);
    tolerance = fcn_INTERNAL_getValue(thisEdit, 'PointTolerance', 0.005);
    flagPoint = false(Nfaces,1);
    points = thisEdit.Points;
    if ~isempty(candidates)
        for ith_point = 1:size(points,1)
            [distanceSquared, nearestCandidate] = min(sum((centers - points(ith_point,:)).^2, 2));
            if distanceSquared <= tolerance^2
                flagPoint(candidates(nearestCandidate)) = true;
            end
        end
    end
    flagSelected = flagSelected & flagPoint;
end

selectedFaces = find(flagSelected);
end % Ends fcn_INTERNAL_selectFaces

%% fcn_INTERNAL_addAlsoParts
function vehicleMesh = fcn_INTERNAL_addAlsoParts(vehicleMesh, selectedFaces, alsoParts)
% Marks the selected faces as also belonging to other parts
% (LabelFaceAlsoParts: one column per part in LabelPartNames). A face's own part
% is not marked again
for ith_part = 1:numel(alsoParts)
    if ~any(strcmp(alsoParts{ith_part}, vehicleMesh.LabelPartNames))
        vehicleMesh.LabelPartNames{end+1} = alsoParts{ith_part};
    end
end
vehicleMesh = fcn_INTERNAL_sizeAlsoParts(vehicleMesh);
partColumns = find(ismember(vehicleMesh.LabelPartNames, alsoParts));
for ith_column = partColumns(:)'
    theseFaces = selectedFaces(vehicleMesh.LabelFacePart(selectedFaces) ~= ith_column);
    vehicleMesh.LabelFaceAlsoParts(theseFaces, ith_column) = true;
end
end % Ends fcn_INTERNAL_addAlsoParts

%% fcn_INTERNAL_sizeAlsoParts
function vehicleMesh = fcn_INTERNAL_sizeAlsoParts(vehicleMesh)
% LabelFaceAlsoParts, made (all false) or widened to one column per part
Nfaces = size(vehicleMesh.Faces,1);
Nparts = numel(vehicleMesh.LabelPartNames);
if ~isfield(vehicleMesh,'LabelFaceAlsoParts') || size(vehicleMesh.LabelFaceAlsoParts,1) ~= Nfaces
    vehicleMesh.LabelFaceAlsoParts = false(Nfaces, Nparts);
elseif size(vehicleMesh.LabelFaceAlsoParts,2) < Nparts
    vehicleMesh.LabelFaceAlsoParts(:, end+1:Nparts) = false;
end
end % Ends fcn_INTERNAL_sizeAlsoParts

%% fcn_INTERNAL_applyLabel
function [vehicleMesh, newPart, newLightType] = fcn_INTERNAL_applyLabel(vehicleMesh, selectedFaces, newPart, newLightType, newColor, glassAlpha)
% Gives the selected faces a new part (and light type), with matching
% default colors and transparency
labelPartNames = {'body';'glass';'wheel';'light';'trim';'interior'};
labelLampNames = vehicleMesh.LabelLampNames;
defaultPartColors = [0.60 0.60 0.65; 0.15 0.20 0.25; 0.10 0.10 0.10; 0.95 0.90 0.80; 0.20 0.20 0.20; 0.35 0.33 0.32];
lampTypes = fcn_CarMesh3D_lampTypes();
defaultLightColors = cell2struct({lampTypes.FaceColor}', {lampTypes.Name}', 1);

if ~isempty(newLightType)
    newPart = 'light';
end
newPart = lower(char(newPart));
newLightType = char(fcn_INTERNAL_lampKey(char(newLightType)));   % (the lamp keys are camelCase, Q92 (A): matched ignoring case)
if isempty(selectedFaces)
    return;
end
% (the part's index in this mesh's own LabelPartNames: 'interior' is added
% when a mesh does not have it yet)
partIndex = find(strcmp(newPart, vehicleMesh.LabelPartNames), 1);
if isempty(partIndex)
    vehicleMesh.LabelPartNames{end+1} = newPart;
    partIndex = numel(vehicleMesh.LabelPartNames);
end
% (each face's label before the edit, and this part's usual color on this
% vehicle: the most common color of its faces outside the edit; Q88 (A))
oldPartIndex = vehicleMesh.LabelFacePart(selectedFaces);
oldPartIndex = oldPartIndex(:);
oldLightType = zeros(numel(selectedFaces),1);
if isfield(vehicleMesh,'LabelFaceLamp') && numel(vehicleMesh.LabelFaceLamp) == size(vehicleMesh.Faces,1)
    oldLightType = double(vehicleMesh.LabelFaceLamp(selectedFaces));
    oldLightType = oldLightType(:);
end
otherFaces = true(size(vehicleMesh.Faces,1),1);
otherFaces(selectedFaces) = false;
otherFaces = otherFaces & vehicleMesh.LabelFacePart(:) == partIndex;
usualColor = [];
if any(otherFaces) && isfield(vehicleMesh,'FaceColors') && size(vehicleMesh.FaceColors,1) == size(vehicleMesh.Faces,1)
    [colorRows, ~, colorOf] = unique(round(vehicleMesh.FaceColors(otherFaces,:)*100)/100, 'rows');
    usualColor = colorRows(mode(colorOf),:);
end
vehicleMesh.LabelFacePart(selectedFaces) = partIndex;

% (a new label replaces the faces' other parts)
if isfield(vehicleMesh,'LabelFaceAlsoParts') && size(vehicleMesh.LabelFaceAlsoParts,1) == size(vehicleMesh.Faces,1)
    vehicleMesh.LabelFaceAlsoParts(selectedFaces,:) = false;
end
% (and a face given a new label is no longer a lamp's clear cover)
if isfield(vehicleMesh,'LabelFaceCoverLamp') && numel(vehicleMesh.LabelFaceCoverLamp) == size(vehicleMesh.Faces,1)
    vehicleMesh.LabelFaceCoverLamp(selectedFaces) = 0;
end

% Light type (a new label replaces the faces' light functions)
if isfield(vehicleMesh,'LabelFaceAlsoLamps') && size(vehicleMesh.LabelFaceAlsoLamps,1) == size(vehicleMesh.Faces,1)
    vehicleMesh.LabelFaceAlsoLamps(selectedFaces,:) = false;
end
if strcmp(newPart,'light') && ~isempty(newLightType)
    lightIndex = find(strcmp(newLightType, labelLampNames));
    vehicleMesh.LabelFaceLamp(selectedFaces) = lightIndex;
    if isfield(vehicleMesh,'LabelFaceAlsoLamps') && size(vehicleMesh.LabelFaceAlsoLamps,1) == size(vehicleMesh.Faces,1)
        vehicleMesh.LabelFaceAlsoLamps(selectedFaces, lightIndex) = true;
    end
    defaultColor = [0.90 0.90 0.85];
    if isfield(defaultLightColors, newLightType)
        defaultColor = defaultLightColors.(newLightType);
    end
else
    vehicleMesh.LabelFaceLamp(selectedFaces) = 0;
    defaultColor = defaultPartColors(strcmp(newPart, labelPartNames),:);
    if ~isempty(usualColor)
        defaultColor = usualColor;   % (this vehicle's own color for the part: Q88 (A))
    end
end

% Wheel corner
if strcmp(newPart,'wheel')
    faceCenters = fcn_INTERNAL_faceCenters(vehicleMesh);
    allWheelFaces = find(vehicleMesh.LabelFacePart==3);
    xSplit = (min(faceCenters(allWheelFaces,1)) + max(faceCenters(allWheelFaces,1)))/2;
    theseCenters = faceCenters(selectedFaces,:);
    cornerIndex = 1 + (theseCenters(:,2)<=0) + 2*(theseCenters(:,1)<=xSplit); % 1 FL, 2 FR, 3 RL, 4 RR
    vehicleMesh.FaceWheelIndex(selectedFaces) = cornerIndex;
else
    vehicleMesh.FaceWheelIndex(selectedFaces) = 0;
end

% Color and transparency
flagNoColorGiven = isempty(newColor);
originalColors = vehicleMesh.FaceColors(selectedFaces,:);
if isempty(newColor)
    newColor = defaultColor;
end
vehicleMesh.FaceColors(selectedFaces,:) = repmat(newColor, length(selectedFaces), 1);
% (interior faces keep their own colors, unless the edit gave a color:
% the seats and dash are many colors)
if flagNoColorGiven && strcmp(newPart,'interior')
    vehicleMesh.FaceColors(selectedFaces,:) = originalColors;
end
% (parts shown in texture colors, set by fcn_CarMesh3D_labelParts
% LabelTextureColorParts, keep them, unless the edit gave a color)
if flagNoColorGiven && isfield(vehicleMesh,'LabelTextureColorParts') && any(strcmpi(newPart, vehicleMesh.LabelTextureColorParts)) ...
        && isfield(vehicleMesh,'FaceTextureColors') && size(vehicleMesh.FaceTextureColors,1)==size(vehicleMesh.Faces,1)
    vehicleMesh.FaceColors(selectedFaces,:) = vehicleMesh.FaceTextureColors(selectedFaces,:);
end
% (a face whose label is the same as before keeps its color, unless the
% edit gave a color: painting body over body changes nothing; Q88 (A))
if flagNoColorGiven
    newLightIndex = double(vehicleMesh.LabelFaceLamp(selectedFaces));
    flagUnchanged = oldPartIndex == partIndex & oldLightType == newLightIndex(:);
    vehicleMesh.FaceColors(selectedFaces(flagUnchanged),:) = originalColors(flagUnchanged,:);
end
if strcmp(newPart,'glass')
    vehicleMesh.FaceAlpha(selectedFaces) = glassAlpha;
else
    vehicleMesh.FaceAlpha(selectedFaces) = 1;
end
end % Ends fcn_INTERNAL_applyLabel

%% fcn_INTERNAL_coverValues
function coverValues = fcn_INTERNAL_coverValues(vehicleMesh, theseFaces)
% The faces' LabelFaceCoverLamp values (lamp covers), or [] if the mesh does
% not have them, kept so the click editor can undo a label
coverValues = [];
if isfield(vehicleMesh,'LabelFaceCoverLamp') && numel(vehicleMesh.LabelFaceCoverLamp) == size(vehicleMesh.Faces,1)
    coverValues = vehicleMesh.LabelFaceCoverLamp(theseFaces);
end
end % Ends fcn_INTERNAL_coverValues

%% fcn_INTERNAL_labelColors
function [displayColors, legendNames, legendColors] = fcn_INTERNAL_labelColors(vehicleMesh)
% False colors that show each part and light type clearly
partColors = [0.80 0.80 0.80; 0.45 0.70 1.00; 0.15 0.15 0.15; 1.00 1.00 0.60; 0.80 0.45 0.15; 0.85 0.65 0.40];
lightColors = [1.00 1.00 0.20; 1.00 0.55 0.00; 0.70 1.00 0.70; 0.90 0.05 0.05; 0.60 0.20 1.00; 0.10 0.85 0.85];
lightColors = lightColors(1:min(end, numel(vehicleMesh.LabelLampNames)),:);
lightColors(end+1:numel(vehicleMesh.LabelLampNames),:) = 0.5;   % (any other light type: gray, unless listed)
lampTypes = fcn_CarMesh3D_lampTypes();
for ith_type = 7:numel(vehicleMesh.LabelLampNames)   % (the newer types: their label colors)
    thisType = lampTypes(strcmp({lampTypes.Name}, vehicleMesh.LabelLampNames{ith_type}));
    if ~isempty(thisType)
        lightColors(ith_type,:) = thisType.LabelColor;
    end
end
Nfaces = size(vehicleMesh.Faces,1);
% (by part name, so a mesh whose parts are in another order, or that has
% 'interior', is colored right)
standardNames = {'body';'glass';'wheel';'light';'trim';'interior'};
displayColors = repmat([0.5 0.5 0.5], numel(vehicleMesh.LabelFacePart), 1);
for ith_part = 1:numel(vehicleMesh.LabelPartNames)
    standardIndex = find(strcmp(vehicleMesh.LabelPartNames{ith_part}, standardNames), 1);
    if ~isempty(standardIndex)
        flagPart = vehicleMesh.LabelFacePart(:)==ith_part;
        displayColors(flagPart,:) = repmat(partColors(standardIndex,:), nnz(flagPart), 1);
    end
end
labelFaceLamp = vehicleMesh.LabelFaceLamp(:);
flagTyped = labelFaceLamp>0;
displayColors(flagTyped,:) = lightColors(labelFaceLamp(flagTyped),:);
legendNames = [{'body';'glass';'wheel';'light (no type)';'trim';'interior'}; strcat({'light: '}, vehicleMesh.LabelLampNames(:))];
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
    % (other parts, recorded as 'light+glass': the part, then its others)
    partParts = split(string(thisEdit.Part), '+');
    alsoPartsText = '';
    if numel(partParts) > 1
        alsoPartsText = sprintf(', ''AlsoParts'',{%s}', strjoin(strcat('''', partParts(2:end), ''''), ','));
    end
    thisEdit.Part = char(partParts(1));
    if isempty(thisEdit.LightType) && isempty(thisEdit.Part)
        labelText = alsoPartsText(3:end);
        alsoPartsText = '';
    elseif isempty(thisEdit.LightType)
        labelText = sprintf('''Part'',''%s''', thisEdit.Part);
    elseif contains(thisEdit.LightType, '+')
        % (light functions added: 'tail+turnsignal', or '+turnsignal')
        typeParts = split(string(thisEdit.LightType), '+');
        alsoText = strjoin(strcat('''', typeParts(2:end), ''''), ',');
        if strlength(typeParts(1)) > 0
            labelText = sprintf('''LightType'',''%s'', ''AlsoLightTypes'',{%s}', typeParts(1), alsoText);
        else
            labelText = sprintf('''AlsoLightTypes'',{%s}', alsoText);
        end
    else
        labelText = sprintf('''LightType'',''%s''', thisEdit.LightType);
    end
    fprintf(1,'edits{end+1} = struct(''Name'',''%s'', ''Region'',[%.3f %.3f %.3f %.3f %.3f %.3f]%s, %s%s);\n', ...
        thisEdit.Name, region, materialText, labelText, alsoPartsText);
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
targetNames = [{'body','glass','wheel','trim','interior'}, strcat({'light: '}, {fcn_CarMesh3D_lampTypes().Name})];   % (every lamp type, by its key: Q92 (A))
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
            'Part',vehicleMesh.LabelFacePart(theseFaces), ...
            'LightType',vehicleMesh.LabelFaceLamp(theseFaces), ...
            'Wheel',vehicleMesh.FaceWheelIndex(theseFaces), ...
            'Colors',vehicleMesh.FaceColors(theseFaces,:), ...
            'Alpha',vehicleMesh.FaceAlpha(theseFaces), ...
            'Cover',fcn_INTERNAL_coverValues(vehicleMesh, theseFaces));
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
        vehicleMesh.LabelFacePart(lastChange.Faces) = lastChange.Part;
        vehicleMesh.LabelFaceLamp(lastChange.Faces) = lastChange.LightType;
        vehicleMesh.FaceWheelIndex(lastChange.Faces) = lastChange.Wheel;
        vehicleMesh.FaceColors(lastChange.Faces,:) = lastChange.Colors;
        vehicleMesh.FaceAlpha(lastChange.Faces) = lastChange.Alpha;
        if ~isempty(lastChange.Cover)
            vehicleMesh.LabelFaceCoverLamp(lastChange.Faces) = lastChange.Cover;
        end
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

%% fcn_INTERNAL_lampKey
function keys = fcn_INTERNAL_lampKey(names)
% A lamp type's key as fcn_CarMesh3D_lampTypes spells it (camelCase, such
% as 'tailBrakeLamp'), from a name given in any case; a name that is not
% a lamp type is returned as it was
lampNames = {fcn_CarMesh3D_lampTypes().Name};
keys = names;
flagChar = ischar(names);
if flagChar
    keys = {names};
end
for ith_name = 1:numel(keys)
    match = find(strcmpi(keys{ith_name}, lampNames), 1);
    if ~isempty(match)
        keys{ith_name} = lampNames{match};
    end
end
if flagChar
    keys = keys{1};
end
end % Ends fcn_INTERNAL_lampKey
