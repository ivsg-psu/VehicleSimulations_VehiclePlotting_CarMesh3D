function [editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleInput, options)
% fcn_CarMesh3D_paintLabels

% A window for fixing a vehicle's labels by painting its faces: pick a
% label (body, glass, trim, interior, wheel, a light type), or hide or
% unhide, then
% paint the faces that should have it. It works on its own (its own
% window), or inside another window, such as the Model Reviewer
% (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build into.
%
% It takes a mesh in, and gives the edited mesh and the edits out, so
% what comes next (the lighting checks, an animation) can use the edited
% mesh directly.
%
% THE WINDOW (Documents/Documentation_CarMesh3D_GUIdesign_paintLabels.md,
% where its design is kept): along the top, the menu and only Undo, Save
% and Exit, with the status; at the left, beside the model, one panel at
% a time, picked from the menu: Overall Display (colors, mesh
% boundaries, nighttime view, the view, see-through body), Labels To
% Display (each label Colored? and Shown?), Lamps To Display (each lamp
% Off, On, or a third state), Modify Labels (the label to paint, and how
% painting behaves), and Settings (versions, reverting, the edits file).
% Then the model, the photo dial, and the photo with its options (its
% folder, turning the model with it, its size). Every on/off choice is a
% pair of radio buttons. Ctrl+Z undoes, Ctrl+S saves.
%
% PAINTING. Pick a label (Modify Labels, "Paint as"), then:
%   * Ctrl+drag over faces paints them; Ctrl+Shift+drag erases paint
%   * a click paints the face under it (a second click takes it off)
%   * a double-click paints the whole connected piece
%   * "Mirror to the other side" (on by default) paints the mirror-image
%     faces too
%   * glass is seen through (skipped) unless the glass tool is in use
% Set a label to Shown? No (Labels To Display) to hide its faces, to reach
% the faces under them (such as a lamp under its lens).
%
% THREE LAYERS. New paint is pending (outlined in yellow) until Apply,
% which makes it part of a temporary modified mesh: applied hiding takes
% faces out of view and out of reach, so a part can be hidden a little at
% a time. Hiding never deletes: hidden faces stay in the mesh, with their
% labels, in a named set ("Hide as", default 'hidden': a hard top taken
% off, say), which the animator can show again by name; "Show hidden
% faces" brings them back into view to unhide them. Save applies, and writes the edits to the vehicle's labelEdits
% file, which the vehicle's script applies after simplifying. Undo takes
% back the last click or stroke (press again to go further back). Revert
% to save goes back to the last save; Revert to start, to the mesh as it
% was before any edits.
%
% PHOTOS. With photos of the real vehicle (photos\ViewInDegrees_<angle>
% .jpg in the vehicle's folder), a photo dial sits between the model and
% the photo: drag its arrow to pick a photo, and the model turns to the
% same angle (and turning the model moves the arrow).
%
% FORMAT:
%
%       [editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleInput,...
%           (Parent=container), (EditsFile=file), (PhotoFolder=folder),...
%           (Wait=flag), (Visible=flag), (OnPaint=function),...
%           (OnChange=function), (OnHint=function), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or a vehicle's
%      folder (as fcn_CarMesh3D_findVehicleFiles takes), or a labeled
%      CarMesh3D mesh. With an ID, the mesh painted is the vehicle's
%      finished mesh before any painted edits (from its cache, stage 1;
%      else its mesh file), its edits are loaded from and saved to its
%      labelEdits_<ID>.mat, and its photos are shown.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Parent: a panel or grid to build into; [] (default) for a window
%      of its own.
%
%      EditsFile: where the edits are saved ('' for not saved: with a mesh
%      given, the default). With an ID, the default is the vehicle's
%      labelEdits_<ID>.mat.
%
%      PhotoFolder: a folder of ViewInDegrees_<angle> photos. Default: the
%      vehicle's photos folder (with an ID), else none.
%
%      Wait: true to wait until the window is closed, and return the edited
%      mesh then (its own window only). Default false: return at once.
%
%      Visible: false to build the window hidden (for tests). Default true.
%
%      OnPaint: a function called with no inputs after each click or
%      stroke that paints (the reviewer marks its Labels item rejected).
%
%      OnChange: a function called with the edited mesh after Apply,
%      Save, Undo of applied paint, or a Revert.
%
%      OnHint: a function called with a hint (HTML text) to show; [] to
%      show hints in the painter's own hint line.
%
%      Versions: true (default) to keep a timestamped copy of the edits and the
%      edited mesh at each save, in the VersionFolder, as
%      <mesh name>_YYYYMMDDHHMMSS.mat (a second save in the same
%      second overwrites the first). The window's "Timestamped copy at each
%      save" box starts with this value; "Save as version" always keeps a
%      copy.
%
%      VersionFolder: where the timestamped copies go. Default: the folder
%      last chosen in the window ("Timestamped copies go in", remembered as the
%      MATLAB preference CarMesh3D/VersionFolder); else the project's
%      scratch folder, Project_CarMesh3D\scratch\meshVersions (for now);
%      else a folder "versions" beside the edits file.
%
%      Who: who is painting, for the vehicle's change log
%      (meshHistory_<ID>.csv; fcn_CarMesh3D_meshHistory): each save adds a
%      row. Default: the computer's user name. (With a vehicle ID only.)
%
%      FigNum: not used (the painter is a window); [] or -1 (fast mode:
%      no input checks).
%
% OUTPUTS:
%
%      editedMesh: the mesh with the applied edits (from the edits file,
%      when the painter returns at once; or as left, with Wait=true).
%
%      labelEdits: the applied edits, as fcn_CarMesh3D_editLabels edits
%      (one per label, faces by their centers).
%
%      painter: a structure of the painter's handles and functions:
%           Figure, Axes, Patch (the model), EditsFile
%           ShowLabel(key): one label colored ('part_body', 'light_tail',
%               ...; as fcn_CarMesh3D_reviewVehicle's label keys), the rest
%               gray, or 'all' for every label in its color
%           SetHidden(keys): hide the faces of these labels (a cell array
%               of keys; {} shows all)
%           EditedMesh(), Edits(), NumPainted(), IsUnsaved(), Status()
%           Apply(), Undo(), Save(), RevertToSaved(), RevertToStart()
%           SaveVersion(): Save, and keep a timestamped copy (returns its file);
%               LastVersionFile(); VersionFolder(); SetVersionFolder(folder)
%               (remembered for next time; '' for the default)
%           WorkingMesh(): the working mesh (the mesh before any edits,
%               with the saved edits taken in; same faces), with the
%               LabelColors the view shows
%           SetTool(name), Paint(tool, points, flagErase): paint the faces
%               nearest these points (for scripts and tests; then Save)
%           SetPhotoAngle(angle), PhotoAngle()
%           StrokeStart(flagErase), MouseMove(), MouseUp(), Click(flagPiece):
%               for a window that holds the painter and handles the mouse
%               itself (MouseMove and MouseUp say whether they used the
%               event)
%           Stop(): stop the painter's timer (before the parent is cleared)
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_viewLabels, fcn_CarMesh3D_meshHistory, fcn_CarMesh3D_plotLabels,
%      fcn_CarMesh3D_editLabels
%
% EXAMPLES:
%
%       % Paint the Fit's labels; wait for the window to close
%       [editedMesh, labelEdits] = fcn_CarMesh3D_paintLabels('2009_Honda_Fit_Sport', Wait=true);
%       fcn_CarMesh3D_plotVehicle(editedMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_paintLabels.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * First write: the Model Reviewer's label painting, taken out into a
%   %   % function of its own (Sean, 06:00: separate panels, so the passing
%   %   % of the mesh is clear and each is easier to debug); a mesh in, the
%   %   % edited mesh and the edits out
%   % * Saved paint becomes the working mesh (Sean, 11:53): its faces take
%   %   % their new label's look (labels and label colors of the edited
%   %   % mesh), not the flat paint color, and are no longer drawn over;
%   %   % Undo still reaches back past a save
%   % * Each save adds a row to the vehicle's change log (who, when, how
%   %   % many faces), and the viewer's fine print shows the license, the
%   %   % build, the last change and the review (Sean, 13:07)
%   % * The model, the photos and their dial, and the list of labels are
%   %   % now the viewer, fcn_CarMesh3D_viewLabels, built in (Sean, 12:39:
%   %   % a fix to the viewer is a fix to the painter); the painter colors
%   %   % its paint through the viewer's ColorFilter and HiddenFaces; the
%   %   % viewer's tools (colors, reset view, copy view call) come with it
%   % * Timestamped copies: "Save as version", and "Timestamped copy at each save"
%   %   % (<mesh name>_YYYYMMDDHHMMSS.mat: the edits and the edited mesh),
%   %   % in a folder typed or picked in the window, remembered; by
%   %   % default the project's scratch folder (Sean, 12:09)
%   % * The labels list's rows placed again when it changes size (its
%   %   % AutoResizeChildren is off: on, MATLAB never called the
%   %   % SizeChangedFcn, and warned)
%   % * The vehicle may be given as its folder (the demo's copy of a
%   %   % vehicle); its change log is kept in that folder
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Multi-part faces (FaceAlsoParts): a face is in each label it
%   %   % belongs to (a lamp's clear cover: its light's label and glass)
%   % * The photo's corner handle (fcn_CarMesh3D_viewLabels GripDown)
%   %   % works here too

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Paint as "high beam" (the 'highbeam' light type; Sean, 03:27);
%   %   % the headlight button is named "low beam"

% 2026_11_23 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Hide and unhide in place of delete (Sean, 04:07 to 04:21): hidden
%   %   % faces stay in the mesh, with their labels, in a named set ("Hide
%   %   % as"); "Show hidden faces" brings them into view to unhide them.
%   %   % Saved as Hide and Unhide edits; an older edits file's deletions
%   %   % come in as hidden

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * The new layout (Sean, 10:05 to 10:48; Documents/
%   %   % Documentation_CarMesh3D_GUIdesign_paintLabels.md): a menu of
%   %   % five panels at the left beside the model (Overall Display,
%   %   % Labels To Display, Lamps To Display, Modify Labels, Settings);
%   %   % only Undo, Save and Exit along the top (Exit asks to save);
%   %   % every on/off choice a pair of radio buttons; the label list with
%   %   % Colored? and Shown?; the lamp list with Status?; Paint as in
%   %   % groups (main, bulb, visibility); the photo's options beside the
%   %   % photo; Ctrl+Z and Ctrl+S; the open panel remembered. New hooks:
%   %   % OpenPanel, Panel, SetMirror, Mirror, SetVersions, Versions,
%   %   % SetShowHidden, ShowHidden.
%   % * Picking faces with the mouse tests the line under the mouse against
%   %   % each triangle (Sean, 16:12: clicks and strokes often found nothing:
%   %   % faces were picked by their centers, which missed large faces)
%   % * A save carries each face's lamp cover (FaceCoverLamp, from
%   %   % fcn_CarMesh3D_findLampCovers), more parts and lamp functions into
%   %   % the working mesh, not only its part, lamp type and colors
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Paint as: fog, reflector, license plate, marker and warning lamps;
%   %   % Lamps To Display: Fog lamps and Reflectors lit; Hazards also
%   %   % lights the warning lamps (fcn_CarMesh3D_lampTypes; Sean, task 8)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Interior types (steering wheel, seats, dash) as paint tools



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.EditsFile = []      % Where the edits are saved; [] for the default
    options.PhotoFolder = []    % Folder of ViewInDegrees_<angle> photos; [] for the default
    options.Wait = false        % Wait until the window is closed
    options.Versions = true     % Keep a timestamped copy of the edits and the edited mesh at each save
    options.VersionFolder = []  % Where timestamped copies go; [] for the remembered folder, else the default
    options.Who = ''            % Who is painting (for the change log); '' for the computer's user name
    options.Visible = true      % Build the window hidden (tests)
    options.OnPaint = []        % Called after each click or stroke that paints
    options.OnChange = []       % Called with the edited mesh when the applied edits change
    options.OnHint = []         % Called with hint text; [] for the painter's own hint line
    options.FigNum = []         % Not used (a window); -1 for fast mode
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
        if ~(ischar(vehicleInput) || isstring(vehicleInput) || ...
                (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Vertices','Faces','PartNames','FacePartIndex'}))))
            error('vehicleInput must be a vehicle ID or a labeled CarMesh3D mesh (Vertices, Faces, PartNames, FacePartIndex)');
        end
        for callbackName = {'OnPaint','OnChange','OnHint'}
            if ~isempty(options.(callbackName{1})) && ~isa(options.(callbackName{1}), 'function_handle')
                error('%s must be a function handle, or empty', callbackName{1});
            end
        end
        if ~isempty(options.Parent) && ~isgraphics(options.Parent)
            error('Parent must be a panel or grid, or empty');
        end
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

%%%% The mesh, its label colors, the edits file, and the photos
editsFile = '';
versionName = '';   % (timestamped copies are named <versionName>_YYYYMMDDHHMMSS.mat)
photoFolder = '';
outline = [];
vehicleName = 'mesh';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    baseMesh = [];
    stage1File = fullfile(vehicleFiles.Folder, 'cache', 'stage1_mesh.mat');
    if isfile(stage1File)
        stage1 = load(stage1File, 'cacheOutputs');
        if isfield(stage1, 'cacheOutputs') && isfield(stage1.cacheOutputs, 'vehicleMesh')
            baseMesh = stage1.cacheOutputs.vehicleMesh;   % (before the painted edits)
        end
    end
    if isempty(baseMesh)
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        baseMesh = loaded.vehicleMesh;
    end
    editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
    [~, versionName] = fileparts(vehicleFiles.MeshFile);
    photoFolder = fullfile(vehicleFiles.Folder, 'photos');
    if vehicleFiles.HasOutline
        loaded = load(vehicleFiles.OutlineFile, 'vehicleOutline');
        outline = loaded.vehicleOutline;
    end
else
    baseMesh = vehicleInput;
    if isfield(baseMesh, 'Name')
        vehicleName = baseMesh.Name;
    end
end
if ~isempty(options.EditsFile)
    editsFile = char(options.EditsFile);
end
if isempty(versionName) && ~isempty(editsFile)
    [~, versionName] = fileparts(editsFile);
end
versionFolder = fcn_INTERNAL_versionFolder(options.VersionFolder, editsFile);
if ~isempty(options.PhotoFolder)
    photoFolder = char(options.PhotoFolder);
end
if ~isfield(baseMesh, 'FaceAlpha') || isempty(baseMesh.FaceAlpha)
    baseMesh.FaceAlpha = ones(size(baseMesh.Faces,1),1);
end
if ~isfield(baseMesh, 'FaceLightType') || isempty(baseMesh.FaceLightType)
    baseMesh.FaceLightType = zeros(size(baseMesh.Faces,1),1);
end
if ~isfield(baseMesh, 'LightTypeNames')
    baseMesh.LightTypeNames = {fcn_CarMesh3D_lampTypes().Name}';   % (one list for every function)
end
% (two meshes with the same faces: BaseMesh, before any edits, which the
% edits are made from and written for; and Mesh, the working mesh, the
% base with the saved edits taken in: its labels and label colors are the
% edited mesh's, so painted faces look like the rest of their label once
% saved. Deleted faces stay in it, hidden.)
data = struct();
data.BaseMesh = baseMesh;
data.Mesh = baseMesh;
labelMesh = fcn_CarMesh3D_plotLabels(baseMesh, FigNum=-1);
data.BaseLabelColors = labelMesh.FaceColors;
data.BaseLabelAlpha = labelMesh.FaceAlpha(:);
if isscalar(data.BaseLabelAlpha)
    data.BaseLabelAlpha = repmat(data.BaseLabelAlpha, size(baseMesh.Faces,1), 1);
end
data.LabelColors = data.BaseLabelColors;
data.LabelAlpha = data.BaseLabelAlpha;
baseCenters = fcn_INTERNAL_faceCenters(baseMesh);
lastVersionFile = '';
data.Geometry = fcn_INTERNAL_geometry(baseMesh);
numFaces = size(baseMesh.Faces,1);

%%%% State
% (painting in three layers: paintTarget, everything painted (pending and
% applied); appliedTarget, the temporary modified mesh (Apply); and
% savedTarget, what is in the edits file (Save); "" = not painted)
paintTarget = strings(numFaces,1);
appliedTarget = strings(numFaces,1);
savedTarget = strings(numFaces,1);
undoStack = struct('Faces', {}, 'Before', {}, 'Applied', {});
strokeOpen = false;
strokeErase = false;
strokeFaces = zeros(0,1);
strokeBefore = strings(0,1);
paintTool = '';
mirrorFace = [];
meshPieces = [];
% (the model, the photos and their dial, and the list of labels: the
% viewer, fcn_CarMesh3D_viewLabels, built in; the painter colors its
% paint through the viewer's ColorFilter and HiddenFaces)
labelViewer = [];
% (the mouse, in its own window)
mouseMode = '';
mouseStart = [0 0];
mouseLast = [0 0];
mouseMoved = false;

%%%% The window (or the parent given): the layout of
% Documents/Documentation_CarMesh3D_GUIdesign_paintLabels.md (Sean,
% 10:24): a top bar (the menu, Undo, Save, Exit, the status), the open
% panel at the left beside the model, the model, the photo dial, and the
% photo with its options at the right
flagOwnWindow = isempty(options.Parent);
panelNames = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Modify Labels', 'Settings'};
blueBand = [0.93 0.95 1];     % (viewing work)
yellowBand = [1 0.96 0.85];   % (paint work)
grayBand = [0.94 0.94 0.94];  % (settings)
panelColors = {blueBand, blueBand, blueBand, yellowBand, grayBand};
if flagOwnWindow
    visibleText = 'on';
    if ~options.Visible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_paintLabels: %s', vehicleName), 'Position', [60 60 1500 900], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_paintLabels', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [1 1], 'Padding', [6 4 6 4]);
    parent = uipanel(rootGrid, 'BorderType', 'none');
else
    parent = options.Parent;
    figureHandle = ancestor(parent, 'figure');
end
mainGrid = uigridlayout(parent, [3 1], 'RowHeight', {36, '1x', 20}, 'Padding', [0 0 0 0], 'RowSpacing', 3);

% The top bar: the menu, then only Undo, Save, and Exit; the status
topGrid = uigridlayout(mainGrid, [1 5], 'ColumnWidth', {90, 80, 80, 80, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'painterMenu', ...
    'Tooltip', 'Pick the panel to show at the left (pick the open one again to close it)', ...
    'ButtonPushedFcn', @(~,~) toggleMenu());
uibutton(topGrid, 'Text', 'Undo', 'ButtonPushedFcn', @(~,~) undoEdit(), ...
    'Tooltip', 'Take back the last click or stroke (press again to go further back, newest first). Ctrl+Z.');
uibutton(topGrid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) saveEdits(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], ...
    'Tooltip', ['Apply the pending paint and save the edits (the vehicle''s labelEdits file, used by its script). ' ...
    'The saved mesh becomes the working mesh: painted faces take their new label''s look. Ctrl+S.']);
exitButton = uibutton(topGrid, 'Text', 'Exit', 'ButtonPushedFcn', @(~,~) closePainter(), ...
    'Tooltip', 'Close the painter (it asks first when there are changes not saved)');
if ~flagOwnWindow
    exitButton.Visible = 'off';   % (the host window closes it)
end
editStatusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11);

% The body: the left column (the menu's list, then the open panel), and
% the viewer (the model, the photo dial, the photo and its options)
bodyGrid = uigridlayout(mainGrid, [1 2], 'ColumnWidth', {320, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
leftGrid = uigridlayout(bodyGrid, [2 1], 'RowHeight', {0, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 4);
menuPanel = uipanel(leftGrid, 'BorderType', 'line', 'BackgroundColor', [1 1 1]);
menuGrid = uigridlayout(menuPanel, [numel(panelNames) 1], 'RowHeight', repmat({28}, 1, numel(panelNames)), ...
    'Padding', [4 4 4 4], 'RowSpacing', 2, 'BackgroundColor', [1 1 1]);
menuItems = gobjects(1, numel(panelNames));
for ith_panel = 1:numel(panelNames)
    menuItems(ith_panel) = uibutton(menuGrid, 'Text', panelNames{ith_panel}, 'HorizontalAlignment', 'left', ...
        'BackgroundColor', panelColors{ith_panel}, 'UserData', panelNames{ith_panel}, ...
        'ButtonPushedFcn', @(source,~) pickPanel(source.UserData));
end
holderGrid = uigridlayout(leftGrid, [1 1], 'Padding', [0 0 0 0]);
holderGrid.Layout.Row = 2;
panelHandles = gobjects(1, numel(panelNames));
for ith_panel = 1:numel(panelNames)
    panelHandles(ith_panel) = uipanel(holderGrid, 'Title', panelNames{ith_panel}, 'FontWeight', 'bold', 'FontSize', 13, ...
        'BackgroundColor', panelColors{ith_panel}, 'Scrollable', 'on', 'Visible', 'off', 'Tag', panelNames{ith_panel});
    panelHandles(ith_panel).Layout.Row = 1;
    panelHandles(ith_panel).Layout.Column = 1;
end
openPanelName = '';
viewerHolder = uipanel(bodyGrid, 'BorderType', 'none');
hintLabel = uilabel(mainGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35]);
hintLabel.Layout.Row = 3;
% (the panels' controls, made once the viewer is built)
paintGroup = [];
mirrorGroup = [];
showHiddenGroup = [];
versionsGroup = [];
hideNameField = [];
saveVersionButton = [];
versionFolderField = [];
versionBrowseButton = [];
labelRows = struct('Key', {}, 'Colored', {}, 'Shown', {});
lampGroups = struct();
overallControls = struct();
% (the vehicle's history, for the fine print: with a vehicle ID only)
historyID = '';
meshHistory = false;
if ischar(vehicleInput) || isstring(vehicleInput)
    historyID = vehicleFiles.Folder;   % (its folder: the vehicle may be a copy kept elsewhere)
    try
        meshHistory = fcn_CarMesh3D_meshHistory(historyID, FigNum=-1);
    catch
        meshHistory = false;
    end
end
[~, labelViewer] = fcn_CarMesh3D_viewLabels(baseMesh, Parent=viewerHolder, ShowTools=false, ...
    PhotoFolder=photoFolder, Outline=outline, OnHint=@setHint, ColorFilter=@paintedColors, ...
    HiddenFaces=@hiddenFaces, History=meshHistory, PhotoOptions=true, OnLamps=@markLamps, FigNum=-1);
labelAxes = labelViewer.Axes;
labelPatch = labelViewer.Patch;
labelPatch.UserData = 'reduced';
% (the painted faces: pending ones filled and outlined in yellow, applied
% ones filled; each a copy lifted a hair off the surface, so it shows)
paintEdges = patch(labelAxes, 'Faces', zeros(0,3), 'Vertices', zeros(0,3), 'FaceColor', 'flat', ...
    'FaceVertexCData', zeros(0,3), 'FaceAlpha', 'flat', 'FaceVertexAlphaData', zeros(0,1), 'AlphaDataMapping', 'none', ...
    'FaceLighting', 'none', 'EdgeColor', [1 0.75 0], 'EdgeAlpha', 0.8, 'LineWidth', 0.5, 'HitTest', 'off', 'Clipping', 'off', 'Tag', 'paintEdges');
appliedPatch = patch(labelAxes, 'Faces', zeros(0,3), 'Vertices', zeros(0,3), 'FaceColor', 'flat', ...
    'FaceVertexCData', zeros(0,3), 'FaceAlpha', 'flat', 'FaceVertexAlphaData', zeros(0,1), 'AlphaDataMapping', 'none', ...
    'FaceLighting', 'none', 'EdgeColor', 'none', 'HitTest', 'off', 'Clipping', 'off', 'Tag', 'appliedPaint');
if flagOwnWindow
    set(figureHandle, 'WindowButtonDownFcn', @onOwnDown, 'WindowButtonMotionFcn', @(~,~) MouseMoveOwn(), ...
        'WindowButtonUpFcn', @(~,~) MouseUpOwn(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'WindowKeyPressFcn', @onOwnKey, 'CloseRequestFcn', @(~,~) closePainter());
    labelPatch.ButtonDownFcn = [];
end

% The panels (Sean, 10:24): built once the viewer is, since they list
% its labels and lamps; the one open last time opens again
buildOverallPanel();
buildLabelsPanel();
buildLampsPanel();
buildModifyPanel();
buildSettingsPanel();
startPanel = 'Modify Labels';
try
    if ispref('CarMesh3D', 'PainterPanel') && any(strcmp(panelNames, getpref('CarMesh3D', 'PainterPanel')))
        startPanel = getpref('CarMesh3D', 'PainterPanel');
    end
catch
end
if ~flagOwnWindow
    % (inside another window, such as the Model Reviewer, the space is
    % narrow: the panels start closed, so the model shows; the menu opens
    % them)
    startPanel = '';
end
pickPanel(startPanel);
drawnow;
labelViewer.PlacePhoto();   % (the photo filling its box, now the layout is settled)

% Saved edits
loadEdits();
showPaint();
setHint(['Mouse: left-drag rotates, right-drag pans, the wheel zooms. Pick a label in Modify Labels (' char(9776) ' Menu), then Ctrl+drag to paint. ' ...
    'Photos: drag the red arrow around the vehicle (or click on the dial).']);

painter = struct('Figure', figureHandle, 'Axes', labelAxes, 'Patch', labelPatch, 'EditsFile', editsFile, ...
    'ShowLabel', @showLabel, 'SetHidden', @setHidden, ...
    'EditedMesh', @getEditedMesh, 'Edits', @getEdits, 'NumPainted', @numPainted, 'IsUnsaved', @isUnsaved, 'Status', @getStatus, ...
    'Apply', @applyEdits, 'Undo', @undoEdit, 'Save', @() saveEdits(), 'SaveVersion', @saveVersion, ...
    'LastVersionFile', @getLastVersionFile, 'VersionFolder', @getVersionFolder, 'SetVersionFolder', @setVersionFolder, 'WorkingMesh', @getWorkingMesh, 'RevertToSaved', @revertToSaved, 'RevertToStart', @revertToStart, ...
    'SetTool', @setTool, 'Paint', @testPaint, 'SetPhotoAngle', labelViewer.SetPhotoAngle, 'PhotoAngle', labelViewer.PhotoAngle, 'Viewer', labelViewer, ...
    'StrokeStart', @strokeStart, 'MouseMove', @mouseMove, 'MouseUp', @mouseUp, 'Click', @click, ...
    'OpenPanel', @pickPanel, 'Panel', @getOpenPanel, 'SetMirror', @setMirror, 'Mirror', @mirrorOn, ...
    'SetVersions', @setVersions, 'Versions', @versionsOn, 'SetShowHidden', @setShowHidden, 'ShowHidden', @showHiddenOn, ...
    'Stop', @stopTimer, 'Close', @closePainter);
if flagOwnWindow
    figureHandle.UserData = painter;
end

if flagOwnWindow && options.Wait && options.Visible
    uiwait(figureHandle);
end
editedMesh = getEditedMesh();
labelEdits = getEdits();

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the painter's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% The view: one label, or all; hidden labels
    function showLabel(labelKey)
        % One label in its colors and the rest gray (the mesh's edges in
        % black, to see each face), or 'all' for every label (the viewer)
        labelViewer.ShowLabel(labelKey);
        showPaint();
        markLabels();
    end

    function setHidden(keysToHide)
        % Hide the faces of these labels ({} shows all) (the viewer)
        labelViewer.SetHidden(keysToHide);
        showPaint();
        markLabels();
    end

    function showPaint()
        % The model's colors with the paint (the viewer colors it, through
        % paintedColors and hiddenFaces), and the painted faces drawn
        if isempty(labelViewer) || isempty(labelPatch) || ~isvalid(labelPatch)
            return;
        end
        labelViewer.Redraw();
        % (pending paint: outlined in yellow; applied paint: filled, no
        % outline; a face whose paint was taken off but not yet applied
        % shows its own label's color, outlined)
        flagShown = ~hiddenFaces(labelViewer.Hidden());
        pending = find(paintTarget ~= appliedTarget & flagShown);
        applied = find(appliedTarget ~= savedTarget & paintTarget == appliedTarget & flagShown);   % (saved: in the working mesh)
        setOverlay(paintEdges, pending, paintTarget(pending));
        setOverlay(appliedPatch, applied, appliedTarget(applied));
        updateStatus();
    end

    function [faceColors, faceAlpha] = paintedColors(faceColors, faceAlpha)
        % Faces painted since the save in the color of the label they are
        % painted (paint taken off a saved face: its look before any
        % edits). Saved paint is in the working mesh's own colors. (The
        % viewer calls this as its ColorFilter, then makes hidden faces
        % see-through.)
        flagChanged = paintTarget ~= savedTarget;
        flagCleared = flagChanged & strlength(paintTarget) == 0;
        faceColors(flagCleared,:) = data.BaseLabelColors(flagCleared,:);
        faceAlpha(flagCleared) = data.BaseLabelAlpha(flagCleared);
        targets = unique(paintTarget(flagChanged & strlength(paintTarget) > 0));
        for ith_target = 1:numel(targets)
            flagPainted = flagChanged & paintTarget == targets(ith_target);
            [color, alpha] = fcn_INTERNAL_paintColor(data, char(targets(ith_target)));
            faceColors(flagPainted,:) = repmat(color, sum(flagPainted), 1);
            faceAlpha(flagPainted) = alpha;
        end
    end

    function setOverlay(patchHandle, faceList, targets)
        if isempty(patchHandle) || ~isvalid(patchHandle)
            return;
        end
        [overlayVertices, overlayFaces] = fcn_INTERNAL_liftedFaces(data.Mesh, faceList, 0.0015);
        overlayColors = zeros(numel(faceList),3);
        overlayAlpha = ones(numel(faceList),1);
        for thisTarget = reshape(unique(targets),1,[])
            flagTarget = targets == thisTarget;
            if strlength(thisTarget) == 0
                overlayColors(flagTarget,:) = data.BaseLabelColors(faceList(flagTarget),:);
            else
                [color, alpha] = fcn_INTERNAL_paintColor(data, char(thisTarget));
                overlayColors(flagTarget,:) = repmat(color, nnz(flagTarget), 1);
                overlayAlpha(flagTarget) = alpha;
            end
        end
        set(patchHandle, 'Faces', overlayFaces, 'Vertices', overlayVertices, 'FaceVertexCData', overlayColors, ...
            'FaceVertexAlphaData', max(overlayAlpha, 0.6));
    end

    function flagHidden = hiddenFaces(hiddenKeys)
        % The faces of hidden labels (by their applied labels), and the
        % hidden faces (hidden in the mesh, or hidden and applied, and not
        % unhidden) unless "Show hidden faces" is ticked
        % (the viewer calls this with its hidden label keys)
        if nargin < 1
            hiddenKeys = {};
            if ~isempty(labelViewer)
                hiddenKeys = labelViewer.Hidden();
            end
        end
        flagHidden = false(numFaces,1);
        changed = appliedTarget ~= savedTarget;   % (saved paint is in the working mesh's labels)
        for ith_key = 1:numel(hiddenKeys)
            flagLabel = fcn_INTERNAL_labelFaces(data.Mesh, hiddenKeys{ith_key});
            flagBase = fcn_INTERNAL_labelFaces(data.BaseMesh, hiddenKeys{ith_key});
            labelName = regexprep(hiddenKeys{ith_key}, '^(part|light)_', '');
            flagLabel(changed) = appliedTarget(changed) == string(labelName) | ...
                (strlength(appliedTarget(changed)) == 0 & flagBase(changed));
            flagHidden = flagHidden | flagLabel(:);
        end
        if ~showHiddenOn()
            flagHidden = flagHidden | startsWith(appliedTarget, "hide:") | ...
                (fcn_INTERNAL_meshHidden(data.BaseMesh) & strlength(appliedTarget) == 0);
        end
    end

    function flagGlass = currentlyGlass()
        % Faces that are glass now: labeled glass and not painted as
        % something else, or painted glass
        glassIndex = find(strcmp(data.Mesh.PartNames, 'glass'), 1);
        flagGlass = false(numFaces,1);
        if ~isempty(glassIndex)
            flagGlass = data.Mesh.FacePartIndex(:) == glassIndex;
        end
        changed = paintTarget ~= savedTarget;
        baseGlass = find(strcmp(data.BaseMesh.PartNames, 'glass'), 1);
        flagBaseGlass = false(numFaces,1);
        if ~isempty(baseGlass)
            flagBaseGlass = data.BaseMesh.FacePartIndex(:) == baseGlass;
        end
        flagGlass(changed) = paintTarget(changed) == "glass" | (strlength(paintTarget(changed)) == 0 & flagBaseGlass(changed));
    end

    %% The menu and the panels (Documentation_CarMesh3D_GUIdesign_paintLabels.md)
    function toggleMenu()
        % The menu's list of panels, opened under the menu button (or
        % closed)
        if leftGrid.RowHeight{1} == 0
            leftGrid.RowHeight{1} = numel(panelNames)*30 + 10;
            bodyGrid.ColumnWidth{1} = 320;
        else
            leftGrid.RowHeight{1} = 0;
            if isempty(openPanelName)
                bodyGrid.ColumnWidth{1} = 0;
            end
        end
    end

    function pickPanel(name)
        % Open this panel at the left (the open one closes); the open
        % panel picked again closes it, and the model takes its width
        name = char(name);
        if strcmp(name, openPanelName) && leftGrid.RowHeight{1} > 0
            name = '';
        end
        openPanelName = name;
        for ith_item = 1:numel(panelHandles)
            flagOpen = strcmp(panelNames{ith_item}, openPanelName);
            panelHandles(ith_item).Visible = matlab.lang.OnOffSwitchState(flagOpen);
            mark = '    ';
            if flagOpen
                mark = [char(10003) ' '];
            end
            menuItems(ith_item).Text = [mark panelNames{ith_item}];
        end
        leftGrid.RowHeight{1} = 0;
        if isempty(openPanelName)
            bodyGrid.ColumnWidth{1} = 0;
        else
            bodyGrid.ColumnWidth{1} = 320;
            try
                setpref('CarMesh3D', 'PainterPanel', openPanelName);
            catch
            end
        end
        markOverall();
        markLabels();
        markLamps(labelViewer.NightLights());
        markPaintButtons();
    end

    function name = getOpenPanel()
        name = openPanelName;
    end

    function buildOverallPanel()
        % The overall display: colors, mesh boundaries, nighttime view, the
        % view, and the see-through body
        panelHandle = panelHandles(strcmp(panelNames, 'Overall Display'));
        grid = uigridlayout(panelHandle, [8 2], 'RowHeight', {22, 24, 24, 24, 28, 28, 22, 50}, 'ColumnWidth', {128, '1x'}, ...
            'Padding', [8 8 8 8], 'RowSpacing', 8, 'BackgroundColor', blueBand, 'Scrollable', 'on');
        heading = uilabel(grid, 'Text', 'Mesh display', 'FontWeight', 'bold', 'FontColor', [0.25 0.25 0.25]);
        heading.Layout.Column = [1 2];
        uilabel(grid, 'Text', 'Colors', 'Tooltip', 'Labels: each face in its label''s color. Vehicle colors: as the animator draws it.');
        overallControls.Colors = fcn_INTERNAL_radioRow(grid, {'Labels', 'Vehicle'}, {'labels', 'vehicle'}, 66, ...
            @(value) setOverallColors(value), 'overallColors');
        uilabel(grid, 'Text', 'Show mesh boundaries', 'Tooltip', 'Draw the edge of every face (the mesh''s triangles)');
        overallControls.Boundaries = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setOverallBoundaries(value), 'overallBoundaries');
        uilabel(grid, 'Text', 'Nighttime view', 'Tooltip', ['A night scene: the vehicle in its own colors, its lamps lit, ' ...
            'and the light they throw on the ground (switch the lamps in Lamps To Display)']);
        overallControls.Night = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setOverallNight(value), 'overallNight');
        uilabel(grid, 'Text', 'View');
        uibutton(grid, 'Text', 'Reset view', 'ButtonPushedFcn', @(~,~) labelViewer.ResetView(), ...
            'Tooltip', 'Put the camera back to the starting view');
        uilabel(grid, 'Text', '');
        uibutton(grid, 'Text', 'Copy view call', 'ButtonPushedFcn', @(~,~) labelViewer.CopyViewCall(), ...
            'Tooltip', 'Put the MATLAB call that opens exactly this view (in fcn_CarMesh3D_viewLabels) on the clipboard');
        heading = uilabel(grid, 'Text', 'See-through body', 'FontWeight', 'bold', 'FontColor', [0.25 0.25 0.25], ...
            'Tooltip', 'Makes the body see-through, to look at (and paint) what is inside it');
        heading.Layout.Column = [1 2];
        overallControls.SeeThrough = uislider(grid, 'Limits', [0 90], 'Value', 0, 'MajorTicks', [0 45 90], ...
            'MajorTickLabels', {'0', '45', '90%'}, 'MinorTicks', [], 'FontSize', 9, ...
            'ValueChangedFcn', @(source,~) setOverallSeeThrough(source.Value/100));
        overallControls.SeeThrough.Layout.Row = 8;
        overallControls.SeeThrough.Layout.Column = [1 2];
    end

    function setOverallColors(value)
        labelViewer.SetColors(value);
        showPaint();
    end

    function setOverallBoundaries(value)
        labelViewer.SetBoundaries(value);
        showPaint();
    end

    function setOverallNight(value)
        labelViewer.SetNightView(value);
        markLamps(labelViewer.NightLights());
        showPaint();
    end

    function setOverallSeeThrough(fraction)
        labelViewer.SetSeeThrough(fraction);
        showPaint();
    end

    function markOverall()
        % (the overall display's buttons showing the viewer's state)
        if ~isfield(overallControls, 'Colors') || ~isvalid(overallControls.Colors)
            return;
        end
        fcn_INTERNAL_selectRadio(overallControls.Colors, labelViewer.Colors());
        fcn_INTERNAL_selectRadio(overallControls.Boundaries, logical(labelViewer.Boundaries()));
        fcn_INTERNAL_selectRadio(overallControls.Night, logical(labelViewer.NightView()));
        overallControls.SeeThrough.Value = 100*labelViewer.SeeThrough();
    end

    function buildLabelsPanel()
        % The labels to display: each label (its color, its name), Colored?
        % (Yes: in its label color; No: plain gray) and Shown? (No: out of
        % view, to reach the faces under it). Labels with no faces are
        % listed too, in gray italics.
        panelHandle = panelHandles(strcmp(panelNames, 'Labels To Display'));
        delete(panelHandle.Children);
        kinds = labelViewer.LabelKinds();
        rowKeys = {'part_body', 'part_glass', 'part_wheel', 'part_trim', 'part_interior', 'light_headlight', ...
            'light_highbeam', 'light_running', 'light_turnsignal', 'light_tail', 'light_backup'};
        rowNames = {'body', 'glass', 'wheel', 'trim', 'interior', 'low beam', 'high beam', 'running light', ...
            'turn signal', 'tail light', 'backup light'};
        % (any other label of the mesh, after these)
        extra = setdiff(kinds.Keys, [rowKeys, {'hidden'}], 'stable');
        for ith_extra = 1:numel(extra)
            rowKeys{end+1} = extra{ith_extra}; %#ok<AGROW>
            rowNames{end+1} = kinds.Names{strcmp(kinds.Keys, extra{ith_extra})}; %#ok<AGROW>
        end
        numRows = numel(rowKeys) + 5;
        grid = uigridlayout(panelHandle, [numRows 4], 'RowHeight', [repmat({22}, 1, numRows-1), {36}], ...
            'ColumnWidth', {16, '1x', 70, 70}, 'Padding', [8 8 8 8], 'RowSpacing', 6, 'ColumnSpacing', 4, ...
            'BackgroundColor', blueBand, 'Scrollable', 'on');
        fcn_INTERNAL_gridText(grid, 1, 3, 'Colored?', 'bold', 'Yes: drawn in its label color. No: plain gray, so the others stand out.');
        fcn_INTERNAL_gridText(grid, 1, 4, 'Shown?', 'bold', 'No: taken out of view (not out of the mesh), to reach the faces under it');
        fcn_INTERNAL_gridText(grid, 2, 3, 'Yes   No', 'normal', '');
        fcn_INTERNAL_gridText(grid, 2, 4, 'Yes   No', 'normal', '');
        labelRows = struct('Key', {}, 'Colored', {}, 'Shown', {});
        % (All labels: sets every row)
        fcn_INTERNAL_gridText(grid, 3, 2, 'All labels', 'bold', 'Sets every label''s row at once');
        allColored = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 34, @(value) setColoredKey('all', value), 'allColored', true);
        fcn_INTERNAL_place(allColored, 3, 3);
        allShown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 34, @(value) setShownKey('all', value), 'allShown', true);
        fcn_INTERNAL_place(allShown, 3, 4);
        labelRows(1) = struct('Key', 'all', 'Colored', allColored, 'Shown', allShown);
        for ith_row = 1:numel(rowKeys)
            row = ith_row + 3;
            key = rowKeys{ith_row};
            flagPresent = any(strcmp(kinds.Keys, key));
            color = fcn_INTERNAL_paintColor(data, regexprep(key, '^(part|light)_', ''));
            box = uipanel(grid, 'BackgroundColor', color, 'BorderType', 'line');
            fcn_INTERNAL_place(box, row, 1);
            nameLabel = fcn_INTERNAL_gridText(grid, row, 2, rowNames{ith_row}, 'normal', '');
            if ~flagPresent
                set(nameLabel, 'FontColor', [0.55 0.55 0.55], 'FontAngle', 'italic', 'Tooltip', 'No faces have this label yet');
            end
            colored = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 34, @(value) setColoredKey(key, value), ['colored_' key]);
            fcn_INTERNAL_place(colored, row, 3);
            shown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 34, @(value) setShownKey(key, value), ['shown_' key]);
            fcn_INTERNAL_place(shown, row, 4);
            labelRows(end+1) = struct('Key', key, 'Colored', colored, 'Shown', shown); %#ok<AGROW>
        end
        % (the hidden faces: shown or not, as "Show hidden faces" in
        % Modify Labels)
        row = numel(rowKeys) + 4;
        box = uipanel(grid, 'BackgroundColor', fcn_INTERNAL_paintColor(data, 'hide'), 'BorderType', 'line');
        fcn_INTERNAL_place(box, row, 1);
        fcn_INTERNAL_gridText(grid, row, 2, 'hidden (not drawn)', 'normal', 'Faces hidden in the mesh (hide, never delete)');
        shown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 34, @(value) setShowHidden(value), 'shown_hidden');
        fcn_INTERNAL_place(shown, row, 4);
        labelRows(end+1) = struct('Key', 'hidden', 'Colored', [], 'Shown', shown);
        note = fcn_INTERNAL_gridText(grid, numRows, 1, 'Gray names: no faces have this label yet.', 'normal', '');
        set(note, 'FontColor', [0.4 0.4 0.4], 'FontSize', 11, 'WordWrap', 'on');
        note.Layout.Column = [1 4];
        markLabels();
    end

    function setColoredKey(key, flagColored)
        if isnan(flagColored)
            return;
        end
        keys = {labelRows(~cellfun(@isempty, {labelRows.Colored})).Key};
        keys = setdiff(keys, {'all'}, 'stable');
        uncolored = labelViewer.Uncolored();
        if strcmp(key, 'all')
            if flagColored
                uncolored = {};
            else
                uncolored = keys;
            end
        elseif flagColored
            uncolored = setdiff(uncolored, {key}, 'stable');
        else
            uncolored = union(uncolored, {key}, 'stable');
        end
        labelViewer.SetUncolored(uncolored);
        showPaint();
        markLabels();
    end

    function setShownKey(key, flagShown)
        if isnan(flagShown)
            return;
        end
        keys = setdiff({labelRows.Key}, {'all', 'hidden'}, 'stable');
        hidden = labelViewer.Hidden();
        if strcmp(key, 'all')
            if flagShown
                hidden = {};
            else
                hidden = keys;
            end
            setShowHidden(flagShown);
        elseif flagShown
            hidden = setdiff(hidden, {key}, 'stable');
        else
            hidden = union(hidden, {key}, 'stable');
        end
        setHidden(hidden);
    end

    function markLabels()
        % (each label's buttons showing the viewer's state; All shows the
        % common setting, or none when they differ)
        if isempty(labelRows) || ~isvalid(labelRows(1).Colored)
            return;
        end
        uncolored = labelViewer.Uncolored();
        hidden = labelViewer.Hidden();
        coloredStates = [];
        shownStates = [];
        for ith_row = 2:numel(labelRows)
            key = labelRows(ith_row).Key;
            if strcmp(key, 'hidden')
                fcn_INTERNAL_selectRadio(labelRows(ith_row).Shown, showHiddenOn());
                continue;
            end
            flagColored = ~any(strcmp(uncolored, key));
            flagShown = ~any(strcmp(hidden, key));
            fcn_INTERNAL_selectRadio(labelRows(ith_row).Colored, flagColored);
            fcn_INTERNAL_selectRadio(labelRows(ith_row).Shown, flagShown);
            coloredStates(end+1) = flagColored; %#ok<AGROW>
            shownStates(end+1) = flagShown; %#ok<AGROW>
        end
        fcn_INTERNAL_selectRadio(labelRows(1).Colored, fcn_INTERNAL_common(coloredStates));
        fcn_INTERNAL_selectRadio(labelRows(1).Shown, fcn_INTERNAL_common(shownStates));
    end

    function buildLampsPanel()
        % The lamps to display: each lamp Off or On (the tail lights also
        % Brake), lit on the model by day, and with their light at night
        panelHandle = panelHandles(strcmp(panelNames, 'Lamps To Display'));
        lampTypes = labelViewer.LampTypes();
        rows = {'LowBeam', 'Low beams', 'headlight', 'headlight'; 'HighBeam', 'High beams', 'highbeam', 'highbeam'; ...
            'Running', 'Running lights', 'running', 'running'; 'TurnLeft', 'Left turn signal', 'turnsignal', 'turnsignal'; ...
            'TurnRight', 'Right turn signal', 'turnsignal', 'turnsignal'; 'Hazards', 'Hazards', 'turnsignal', 'turnsignal'; ...
            'Tail', 'Tail lights', 'tail', 'tail'; 'Backup', 'Backup lights', 'backup', 'backup'; ...
            'FogLights', 'Fog lamps', 'fog', 'fog'; 'Reflectors', 'Reflectors lit', 'reflector', 'reflector'};   % (the last two: Sean, task 8)
        numRows = size(rows,1) + 4;
        grid = uigridlayout(panelHandle, [numRows 3], 'RowHeight', [repmat({22}, 1, numRows-1), {48}], ...
            'ColumnWidth', {16, 120, '1x'}, 'Padding', [8 8 8 8], 'RowSpacing', 6, 'ColumnSpacing', 4, ...
            'BackgroundColor', blueBand, 'Scrollable', 'on');
        fcn_INTERNAL_gridText(grid, 1, 3, 'Status?', 'bold', 'Which lamps are switched on');
        fcn_INTERNAL_gridText(grid, 2, 3, 'Off     On      3rd state', 'normal', '');
        lampGroups = struct();
        for ith_row = 1:size(rows,1)
            row = ith_row + 2;
            name = rows{ith_row,1};
            box = uipanel(grid, 'BackgroundColor', fcn_INTERNAL_paintColor(data, rows{ith_row,4}), 'BorderType', 'line');
            fcn_INTERNAL_place(box, row, 1);
            nameLabel = fcn_INTERNAL_gridText(grid, row, 2, rows{ith_row,2}, 'normal', '');
            if strcmp(name, 'Hazards')
                nameLabel.Tooltip = 'Both turn signals at once, and the warning lamps';
            elseif strcmp(name, 'Reflectors')
                nameLabel.Tooltip = 'The reflectors as another car''s headlights light them (outside light)';
            end
            if ~any(strcmp(lampTypes, rows{ith_row,3}))
                set(nameLabel, 'FontColor', [0.55 0.55 0.55], 'FontAngle', 'italic', ...
                    'Tooltip', 'No faces have this lamp yet; its light still shows at night');
            end
            if strcmp(name, 'Tail')
                group = fcn_INTERNAL_radioRow(grid, {'', '', 'Brake'}, {'off', 'on', 'brake'}, 36, ...
                    @(value) setLamp('Tail', value), 'lamp_Tail');
            else
                group = fcn_INTERNAL_radioRow(grid, {'', ''}, {false, true}, 36, @(value) setLamp(name, value), ['lamp_' name]);
            end
            fcn_INTERNAL_place(group, row, 3);
            lampGroups.(name) = group;
        end
        row = size(rows,1) + 3;
        fcn_INTERNAL_gridText(grid, row, 2, 'All lamps', 'bold', 'Every lamp off, or on');
        lampGroups.All = fcn_INTERNAL_radioRow(grid, {'', ''}, {false, true}, 36, @(value) setLamp('All', value), 'lamp_All', true);
        fcn_INTERNAL_place(lampGroups.All, row, 3);
        note = fcn_INTERNAL_gridText(grid, numRows, 1, ['Lit on the model by day; at night, with their light too. ' ...
            'Gray names: no faces have this lamp yet; its light still shows.'], 'normal', '');
        set(note, 'FontColor', [0.4 0.4 0.4], 'FontSize', 11, 'WordWrap', 'on', 'VerticalAlignment', 'top');
        note.Layout.Column = [1 3];
        markLamps(labelViewer.NightLights());
    end

    function setLamp(name, value)
        if isnumeric(value) && isnan(value)
            return;
        end
        labelViewer.SetNightLamp(name, value);   % (the viewer calls markLamps back)
        showPaint();
    end

    function markLamps(states)
        % (the lamps' buttons showing the lamp states; called by the
        % viewer whenever they change)
        if ~isfield(lampGroups, 'LowBeam') || ~isvalid(lampGroups.LowBeam)
            return;
        end
        for name = {'LowBeam', 'HighBeam', 'Running', 'TurnLeft', 'TurnRight', 'Backup', 'FogLights'}
            if isfield(states, name{1})
                fcn_INTERNAL_selectRadio(lampGroups.(name{1}), logical(states.(name{1})));
            end
        end
        reflectorsOn = isfield(states, 'Reflectors') && states.Reflectors > 0;
        fogOn = isfield(states, 'FogLights') && logical(states.FogLights);
        fcn_INTERNAL_selectRadio(lampGroups.Reflectors, reflectorsOn);
        fcn_INTERNAL_selectRadio(lampGroups.Hazards, logical(states.TurnLeft) && logical(states.TurnRight));
        fcn_INTERNAL_selectRadio(lampGroups.Tail, lower(char(states.Tail)));
        flagsOn = [states.LowBeam, states.HighBeam, states.Running, states.TurnLeft, states.TurnRight, ...
            ~strcmpi(states.Tail, 'off'), states.Backup, fogOn, reflectorsOn];
        fcn_INTERNAL_selectRadio(lampGroups.All, fcn_INTERNAL_common(logical(flagsOn)));
    end

    function buildModifyPanel()
        % Modify Labels: the label to paint (one at a time, or none), the
        % hidden set's name, mirror and show-hidden switches, Apply, and
        % how to paint
        panelHandle = panelHandles(strcmp(panelNames, 'Modify Labels'));
        groups = {'Main labeling:', {'body', 'glass', 'trim', 'interior', 'wheel'}; ...
            'Bulb labeling:', {'headlight', 'highbeam', 'tail', 'running', 'turnsignal', 'backup', ...
                'fog', 'reflector', 'licenseplate', 'marker', 'warning'}; ...   % (the last five: Sean, task 8)
            'Visibility labeling:', {'hide', 'unhide', ''}};
        rowHeight = 24;
        numRows = 1 + sum(cellfun(@(names) numel(names) + 1, groups(:,2)));
        groupHeight = numRows*rowHeight + 8;
        outer = uigridlayout(panelHandle, [6 1], 'RowHeight', {groupHeight, 22, 24, 24, 30, 100}, 'Padding', [8 8 8 8], ...
            'RowSpacing', 6, 'BackgroundColor', yellowBand, 'Scrollable', 'on');
        paintGroup = uibuttongroup(outer, 'BorderType', 'none', 'BackgroundColor', yellowBand, 'Tag', 'paintAs', ...
            'SelectionChangedFcn', @(~,event) pickTool(event.NewValue.UserData));
        y = groupHeight - rowHeight;
        uilabel(paintGroup, 'Text', 'Paint as   (pick one)', 'FontWeight', 'bold', 'Position', [2 y 260 22]);
        for ith_group = 1:size(groups,1)
            y = y - rowHeight;
            uilabel(paintGroup, 'Text', groups{ith_group,1}, 'FontWeight', 'bold', 'FontColor', [0.45 0.3 0], ...
                'Position', [2 y 200 22]);
            names = groups{ith_group,2};
            for ith_name = 1:numel(names)
                y = y - rowHeight;
                name = names{ith_name};
                if isempty(name)
                    uiradiobutton(paintGroup, 'Text', 'none (rotate only)', 'Position', [34 y 160 22], 'UserData', '', ...
                        'Tooltip', 'No label picked: the mouse only turns, pans and zooms the view');
                    continue;
                end
                [color, ~] = fcn_INTERNAL_paintColor(data, name);
                uipanel(paintGroup, 'BackgroundColor', color, 'BorderType', 'line', 'Position', [14 y+4 14 14]);
                uiradiobutton(paintGroup, 'Text', fcn_INTERNAL_paintText(name), 'Position', [34 y 112 22], ...
                    'UserData', name, 'Tooltip', fcn_INTERNAL_paintTooltip(name));
                if strcmp(name, 'hide')
                    uilabel(paintGroup, 'Text', 'Hide as:', 'Position', [150 y 52 22], 'HorizontalAlignment', 'right');
                    hideNameField = uieditfield(paintGroup, 'text', 'Value', 'hidden', 'Position', [206 y 80 22], ...
                        'Tooltip', ['The hidden set the "hide" tool puts faces in (such as ''hard top''): the animator can show a set ' ...
                        'again by name']);
                end
            end
        end
        heading = uilabel(outer, 'Text', 'Labeling behavior?', 'FontWeight', 'bold', 'FontColor', [0.45 0.3 0]);
        heading.Layout.Row = 2;
        rowGrid = uigridlayout(outer, [1 2], 'ColumnWidth', {150, '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', yellowBand);
        uilabel(rowGrid, 'Text', 'Mirror to the other side', ...
            'Tooltip', 'Paint the mirror-image faces on the other side too. Off for one-sided parts (a fuel door).');
        mirrorGroup = fcn_INTERNAL_radioRow(rowGrid, {'Off', 'On'}, {false, true}, 52, @(~) [], 'mirror');
        fcn_INTERNAL_selectRadio(mirrorGroup, true);
        rowGrid = uigridlayout(outer, [1 2], 'ColumnWidth', {150, '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', yellowBand);
        uilabel(rowGrid, 'Text', 'Show hidden faces', ...
            'Tooltip', 'Show the hidden faces (magenta), to unhide them; they cannot be painted while out of view');
        showHiddenGroup = fcn_INTERNAL_radioRow(rowGrid, {'Off', 'On'}, {false, true}, 52, @(value) setShowHidden(value), 'showHidden');
        uibutton(outer, 'Text', 'Apply', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) applyEdits(), ...
            'Tooltip', 'Make the pending paint part of the working mesh (hidden faces go out of view and reach)');
        uilabel(outer, 'Text', ['How to paint: Ctrl+drag paints; Ctrl+Shift+drag erases; a click paints one face (click again ' ...
            'to take it off); a double-click paints a whole piece. Paint is pending (yellow edges) until Apply or Save. ' ...
            'Hiding takes faces out of view, never out of the mesh. To reach faces under others, set their label to ' ...
            'Shown? No (Labels To Display).'], 'WordWrap', 'on', 'FontSize', 11, 'FontColor', [0.45 0.3 0], ...
            'VerticalAlignment', 'top');
        markPaintButtons();
    end

    function pickTool(name)
        paintTool = char(name);
        if isempty(paintTool)
            setHint('No label picked: the mouse only turns, pans and zooms the view.');
        else
            setHint(sprintf('Painting as <b>%s</b>: Ctrl+drag paints, Ctrl+Shift+drag erases, a click paints one face, a double-click a piece.', ...
                fcn_INTERNAL_paintText(paintTool)));
        end
    end

    function setShowHidden(flagOn)
        if isnan(flagOn)
            return;
        end
        fcn_INTERNAL_selectRadio(showHiddenGroup, logical(flagOn));
        showPaint();
        markLabels();
    end

    function flagOn = showHiddenOn()
        flagOn = ~isempty(showHiddenGroup) && isvalid(showHiddenGroup) && isequal(showHiddenGroup.SelectedObject.UserData, true);
    end

    function flagOn = mirrorOn()
        flagOn = isempty(mirrorGroup) || ~isvalid(mirrorGroup) || isequal(mirrorGroup.SelectedObject.UserData, true);
    end

    function setMirror(flagOn)
        fcn_INTERNAL_selectRadio(mirrorGroup, logical(flagOn));
    end

    function buildSettingsPanel()
        % Settings: saving a version, timestamped copies and where they
        % go, reverting, and the edits file
        panelHandle = panelHandles(strcmp(panelNames, 'Settings'));
        grid = uigridlayout(panelHandle, [8 2], 'RowHeight', {28, 24, 18, 26, 28, 28, 18, 60}, 'ColumnWidth', {165, '1x'}, ...
            'Padding', [8 8 8 8], 'RowSpacing', 8, 'BackgroundColor', grayBand, 'Scrollable', 'on');
        uilabel(grid, 'Text', 'Save as version');
        saveVersionButton = uibutton(grid, 'Text', 'Save as version', 'ButtonPushedFcn', @(~,~) saveVersion(), ...
            'Tooltip', 'Save, and also keep a timestamped copy (<mesh name>_YYYYMMDDHHMMSS.mat: the edits and the edited mesh, in the folder below)');
        uilabel(grid, 'Text', 'Timestamped copy each save', ...
            'Tooltip', ['Each save also keeps a timestamped copy, in the folder below: ' ...
            '<mesh name>_YYYYMMDDHHMMSS.mat (two saves in the same second: the newer one is kept)']);
        versionsGroup = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, @(~) [], 'versions');
        fcn_INTERNAL_selectRadio(versionsGroup, options.Versions && ~isempty(editsFile));
        label = uilabel(grid, 'Text', 'Timestamped copies go in:');
        label.Layout.Column = [1 2];
        folderGrid = uigridlayout(grid, [1 2], 'ColumnWidth', {'1x', 70}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4, ...
            'BackgroundColor', grayBand);
        folderGrid.Layout.Column = [1 2];
        versionFolderField = uieditfield(folderGrid, 'text', 'Value', versionFolder, ...
            'ValueChangedFcn', @(source,~) setVersionFolder(source.Value), ...
            'Tooltip', 'The folder for the timestamped copies (made if it does not exist); remembered for next time');
        versionBrowseButton = uibutton(folderGrid, 'Text', 'Browse...', 'ButtonPushedFcn', @(~,~) browseVersionFolder());
        uilabel(grid, 'Text', 'Revert');
        uibutton(grid, 'Text', 'Revert to save', 'ButtonPushedFcn', @(~,~) askRevert('save'), ...
            'Tooltip', 'Go back to the last save (pending and applied paint since then are taken off)');
        uilabel(grid, 'Text', '');
        uibutton(grid, 'Text', 'Revert to start', 'ButtonPushedFcn', @(~,~) askRevert('start'), ...
            'Tooltip', 'Go back to the mesh before any edits (Save to make it stick)');
        label = uilabel(grid, 'Text', 'Edits file:');
        label.Layout.Column = [1 2];
        editsText = editsFile;
        if isempty(editsText)
            editsText = '(none: the mesh was given as a variable, so the edits are returned, not saved)';
        end
        label = uilabel(grid, 'Text', editsText, 'WordWrap', 'on', 'FontColor', [0.3 0.3 0.3], 'VerticalAlignment', 'top');
        label.Layout.Column = [1 2];
        if isempty(editsFile)
            saveVersionButton.Enable = 'off';
            set(versionsGroup.Children, 'Enable', 'off');
            versionFolderField.Enable = 'off';
            versionBrowseButton.Enable = 'off';
        end
    end

    function flagOn = versionsOn()
        flagOn = ~isempty(versionsGroup) && isvalid(versionsGroup) && isequal(versionsGroup.SelectedObject.UserData, true);
    end

    function setVersions(flagOn)
        fcn_INTERNAL_selectRadio(versionsGroup, logical(flagOn));
    end

    function askRevert(which)
        % (asks first, when on screen: a revert takes paint off)
        if strcmp(figureHandle.Visible, 'on')
            if strcmp(which, 'save')
                question = 'Go back to the last save? Paint since then is taken off.';
            else
                question = 'Go back to the mesh before any edits? (Save afterward to make it stick.)';
            end
            choice = uiconfirm(figureHandle, question, 'Revert', 'Options', {'Revert', 'Cancel'}, ...
                'DefaultOption', 2, 'CancelOption', 2);
            if ~strcmp(choice, 'Revert')
                return;
            end
        end
        if strcmp(which, 'save')
            revertToSaved();
        else
            revertToStart();
        end
    end

    function onOwnKey(~, event)
        % Ctrl+Z undoes, Ctrl+S saves (as the buttons at the top)
        if any(strcmp(event.Modifier, 'control'))
            switch lower(event.Key)
                case 'z'
                    undoEdit();
                case 's'
                    saveEdits();
            end
        end
    end

    %% The tools
    function setTool(name)
        paintTool = char(name);
        markPaintButtons();
    end

    function markPaintButtons()
        % (the label picked in Modify Labels' list: its radio button;
        % none picked: "none (rotate only)")
        if isempty(paintGroup) || ~isvalid(paintGroup)
            return;
        end
        fcn_INTERNAL_selectRadio(paintGroup, paintTool);
    end

    function value = paintValue()
        % What the tool paints: its label, or "hide:<set>" (the "Hide as"
        % set)
        value = string(paintTool);
        if strcmp(paintTool, 'hide')
            setName = strtrim(char(hideNameField.Value));
            if isempty(setName)
                setName = 'hidden';
            end
            value = "hide:" + string(setName);
        end
    end

    function paintFaces(faces, flagErase)
        % Paints these faces (and their mirror images) with the tool's
        % label, or erases their paint; remembered for Undo
        faces = faces(:);
        if isempty(faces) || (~flagErase && isempty(paintTool))
            return;
        end
        if mirrorOn()
            if isempty(mirrorFace)
                mirrorFace = fcn_INTERNAL_mirrorFaces(data.Mesh);
            end
            mirrored = mirrorFace(faces);
            faces = unique([faces; mirrored(mirrored > 0)]);
        end
        if strokeOpen
            newFaces = setdiff(faces, strokeFaces);
            strokeFaces = [strokeFaces; newFaces];
            strokeBefore = [strokeBefore; paintTarget(newFaces)];
        else
            undoStack(end+1) = struct('Faces', faces, 'Before', paintTarget(faces), 'Applied', false);
        end
        if flagErase
            paintTarget(faces) = "";
        else
            paintTarget(faces) = paintValue();
        end
        showPaint();
    end

    function faces = facesUnderMouse(flagSingle, flagErase)
        % The faces under the mouse, nearest the camera: the face the line
        % under the mouse hits first (flagSingle), or that face and the
        % faces around it, within a small brush. Hidden faces are skipped,
        % and so is glass unless the glass tool is in use or paint is being
        % erased. (The line is tested against each triangle, so a large
        % face is found wherever it is clicked: picking by the nearest face
        % center missed large faces; Sean, 16:12.)
        faces = [];
        if ~isvalid(labelAxes)
            return;
        end
        ray = labelAxes.CurrentPoint;   % (2 x 3: the front and back of the line under the mouse)
        direction = ray(2,:) - ray(1,:);
        direction = direction/norm(direction);
        eligible = ~hiddenFaces();
        if ~flagErase && ~strcmp(paintTool, 'glass')
            eligible = eligible & ~currentlyGlass();
        end
        candidates = find(eligible);
        if isempty(candidates)
            return;
        end
        hitDistance = fcn_INTERNAL_rayHits(ray(1,:), direction, data.Mesh.Vertices, data.Mesh.Faces(candidates,:));
        [firstHit, hitIndex] = min(hitDistance);
        if isinf(firstHit)
            return;   % (the line misses the vehicle)
        end
        hitFace = candidates(hitIndex);
        if flagSingle
            faces = hitFace;
            return;
        end
        % (the brush: faces whose centers lie near the point hit, on the
        % near side of the vehicle)
        hitPoint = ray(1,:) + firstHit*direction;
        centers = fcn_INTERNAL_faceCenters(data.Mesh);
        vehicleLength = data.Geometry.Max(1) - data.Geometry.Min(1);
        brush = 0.012*vehicleLength;
        nearHit = candidates(vecnorm(centers(candidates,:) - hitPoint, 2, 2) < brush & ...
            (centers(candidates,:) - ray(1,:))*direction' < firstHit + 0.05);
        faces = unique([hitFace; nearHit(:)]);
    end

    function strokeStart(flagErase)
        % A Ctrl+drag stroke begins (one Undo entry for the whole stroke)
        strokeOpen = true;
        strokeErase = logical(flagErase);
        strokeFaces = zeros(0,1);
        strokeBefore = strings(0,1);
        if ~strokeErase && isempty(paintTool)
            setHint('<b>Pick a label first</b> (Modify Labels, in the menu at the top left), then Ctrl+drag to paint.');
        end
        paintFaces(facesUnderMouse(false, strokeErase), strokeErase);
    end

    function closeStroke()
        % A stroke is finished: its faces become one Undo entry
        if strokeOpen && ~isempty(strokeFaces)
            undoStack(end+1) = struct('Faces', strokeFaces, 'Before', strokeBefore, 'Applied', false);
            notifyPaint();
        end
        strokeOpen = false;
        strokeFaces = zeros(0,1);
        strokeBefore = strings(0,1);
        updateStatus();
    end

    function click(flagPiece)
        % A click (no drag) on the model: paints the face under it with the
        % tool (a double-click, the whole piece); a click on faces already
        % painted with this tool takes the paint off
        if isempty(paintTool)
            setHint('<b>Pick a label first</b> (Modify Labels, in the menu at the top left), then click or Ctrl+drag to paint.');
            return;
        end
        face = facesUnderMouse(true, false);
        if isempty(face)
            return;
        end
        if flagPiece
            if isempty(meshPieces)
                meshPieces = fcn_INTERNAL_meshPieces(data.Mesh);
            end
            face = find(meshPieces == meshPieces(face));
        end
        flagAlreadyPainted = all(paintTarget(face) == paintValue());
        paintFaces(face, flagAlreadyPainted);
        notifyPaint();
    end

    function testPaint(tool, points, flagErase)
        % (for scripts and tests: paint the faces nearest these points with
        % a tool, then Save)
        setTool(tool);
        centers = fcn_INTERNAL_faceCenters(data.Mesh);
        faces = zeros(size(points,1),1);
        for ith_point = 1:size(points,1)
            [~, faces(ith_point)] = min(sum((centers - points(ith_point,:)).^2, 2));
        end
        paintFaces(faces, flagErase);
        notifyPaint();
        saveEdits();
    end

    function notifyPaint()
        if ~isempty(options.OnPaint)
            options.OnPaint();
        end
    end

    %% Apply, Undo, Save, Revert
    function applyEdits()
        % The pending paint becomes part of the temporary modified mesh
        % (hidden faces go out of view, and out of reach)
        appliedTarget = paintTarget;
        for ith_entry = 1:numel(undoStack)
            undoStack(ith_entry).Applied = true;
        end
        showPaint();
        notifyChange();
    end

    function undoEdit()
        % The last click or stroke is taken back (press again to go
        % further back, newest first); if it was applied, it is taken
        % back from the modified mesh too
        if isempty(undoStack)
            setHint('Nothing to undo since the last Revert.');
            return;
        end
        lastEntry = undoStack(end);
        undoStack(end) = [];
        paintTarget(lastEntry.Faces) = lastEntry.Before;
        if lastEntry.Applied
            appliedTarget(lastEntry.Faces) = lastEntry.Before;
        end
        showPaint();
        if lastEntry.Applied
            notifyChange();
        end
    end

    function saveEdits(flagVersion)
        % Applies the pending paint, then saves the modified mesh's edits;
        % the saved mesh becomes the working mesh (painted faces take
        % their label's look). With "Timestamped copy at each save" ticked (or
        % Save as version), a timestamped copy is kept too.
        if nargin < 1
            flagVersion = versionsOn();
        end
        appliedTarget = paintTarget;
        for ith_entry = 1:numel(undoStack)
            undoStack(ith_entry).Applied = true;
        end
        labelEditsAfterSimplify = fcn_INTERNAL_paintEdits(data.BaseMesh, appliedTarget);
        if ~isempty(editsFile)
            if isempty(labelEditsAfterSimplify)
                if isfile(editsFile)
                    delete(editsFile);
                end
            else
                save(editsFile, 'labelEditsAfterSimplify');
            end
        end
        flagChanged = ~isequal(savedTarget, appliedTarget);
        savedTarget = appliedTarget;
        absorbSaved();
        showPaint();
        notifyChange();
        if flagChanged && ~isempty(historyID) && ~isempty(editsFile)
            % (the change log: who, when, and how many faces; and the
            % viewer's fine print again)
            try
                meshHistory = fcn_CarMesh3D_meshHistory(historyID, Action='label edits saved', Who=options.Who, ...
                    Details=sprintf('%d faces changed from the download (%d hidden)', nnz(strlength(savedTarget) > 0), ...
                    nnz(startsWith(savedTarget, "hide:"))), FigNum=-1);
                labelViewer.SetHistory(meshHistory);
            catch
            end
        end
        if flagVersion && ~isempty(editsFile)
            writeVersion(labelEditsAfterSimplify);
        end
    end

    function versionFile = saveVersion()
        % Save, and keep a timestamped copy whatever the box says
        saveEdits(true);
        versionFile = lastVersionFile;
    end

    function writeVersion(labelEditsAfterSimplify)
        % A timestamped copy of the edits and the edited mesh, in the folder for
        % timestamped copies: <mesh name>_YYYYMMDDHHMMSS.mat (a second save in
        % the same second overwrites the first)
        if ~isfolder(versionFolder)
            [flagMade, message] = mkdir(versionFolder);
            if ~flagMade
                setHint(sprintf('<font color="#b03000"><b>Saved, but no timestamped copy:</b> the folder %s cannot be made (%s).</font>', ...
                    versionFolder, message));
                return;
            end
        end
        stamp = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
        lastVersionFile = fullfile(versionFolder, sprintf('%s_%s.mat', versionName, stamp));
        vehicleMesh = getEditedMesh(); %#ok<NASGU>
        savedAt = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')); %#ok<NASGU>
        save(lastVersionFile, 'vehicleMesh', 'labelEditsAfterSimplify', 'savedAt');
        [~, fileName, extension] = fileparts(lastVersionFile);
        setHint(sprintf('Saved, with a timestamped copy: %s%s (in %s)', fileName, extension, versionFolder));
    end

    function setVersionFolder(folderIn)
        % A new folder for the timestamped copies, remembered for next time
        folderIn = strtrim(char(folderIn));
        if isempty(folderIn)
            folderIn = fcn_INTERNAL_versionFolder([], editsFile, true);
        end
        versionFolder = folderIn;
        if isvalid(versionFolderField)
            versionFolderField.Value = versionFolder;
        end
        setpref('CarMesh3D', 'VersionFolder', versionFolder);
        setHint(sprintf('Timestamped copies now go in %s', versionFolder));
    end

    function browseVersionFolder()
        startFolder = versionFolder;
        while ~isempty(startFolder) && ~isfolder(startFolder)
            startFolder = fileparts(startFolder);
        end
        picked = uigetdir(startFolder, 'Folder for the timestamped copies');
        if ~isequal(picked, 0)
            setVersionFolder(picked);
        end
    end

    function folderOut = getVersionFolder()
        folderOut = versionFolder;
    end

    function absorbSaved()
        % The saved edits taken into the working mesh: each face's label
        % and label color are the edited mesh's (hidden faces keep their
        % place, hidden). Same faces as the base, so the paint layers and
        % Undo carry on.
        data.Mesh = data.BaseMesh;
        data.LabelColors = data.BaseLabelColors;
        data.LabelAlpha = data.BaseLabelAlpha;
        meshPieces = [];
        edits = fcn_INTERNAL_paintEdits(data.BaseMesh, savedTarget);
        if ~isempty(edits)
            editedNow = fcn_CarMesh3D_editLabels(data.BaseMesh, Edits=edits, FigNum=-1);
            editedLabels = fcn_CarMesh3D_plotLabels(editedNow, FigNum=-1);
            editedAlpha = editedLabels.FaceAlpha(:);
            if isscalar(editedAlpha)
                editedAlpha = repmat(editedAlpha, size(editedNow.Faces,1), 1);
            end
            % (each edited face is a base face: the same corners)
            [baseIndex, distance] = fcn_INTERNAL_nearest(baseCenters, fcn_INTERNAL_faceCenters(editedNow));
            flagMatch = distance < 1e-6;
            baseIndex = baseIndex(flagMatch);
            workingMesh = data.BaseMesh;
            workingMesh.PartNames = editedNow.PartNames;
            [~, partMap] = ismember(data.BaseMesh.PartNames, editedNow.PartNames);
            flagPart = workingMesh.FacePartIndex > 0;
            workingMesh.FacePartIndex(flagPart) = partMap(workingMesh.FacePartIndex(flagPart));
            workingMesh.LightTypeNames = editedNow.LightTypeNames;
            [~, lightMap] = ismember(data.BaseMesh.LightTypeNames, editedNow.LightTypeNames);
            flagLight = workingMesh.FaceLightType > 0;
            workingMesh.FaceLightType(flagLight) = lightMap(workingMesh.FaceLightType(flagLight));
            workingMesh.FacePartIndex(baseIndex) = editedNow.FacePartIndex(flagMatch);
            workingMesh.FaceLightType(baseIndex) = editedNow.FaceLightType(flagMatch);
            % (the other per-face label fields too: colors, see-through, a
            % lamp's cover (FaceCoverLamp), more parts or lamp functions;
            % a field the edits made, or made wider, is made to match)
            for fieldName = {'FaceColors', 'FaceAlpha', 'FaceCoverLamp', 'FaceAlsoParts', 'FaceLightFunctions'}
                name = fieldName{1};
                if ~isfield(editedNow, name) || size(editedNow.(name),1) ~= size(editedNow.Faces,1)
                    continue;
                end
                width = size(editedNow.(name),2);
                if ~isfield(workingMesh, name) || size(workingMesh.(name),1) ~= numFaces
                    workingMesh.(name) = zeros(numFaces, width, 'like', editedNow.(name));
                elseif size(workingMesh.(name),2) < width
                    workingMesh.(name)(:, end+1:width) = 0;
                end
                workingMesh.(name)(baseIndex,1:width) = editedNow.(name)(flagMatch,:);
            end
            data.Mesh = workingMesh;
            data.LabelColors(baseIndex,:) = editedLabels.FaceColors(flagMatch,:);
            data.LabelAlpha(baseIndex) = editedAlpha(flagMatch);
        end
        if ~isempty(labelViewer)
            labelViewer.SetMesh(data.Mesh, data.LabelColors, data.LabelAlpha);   % (its list too, if the labels changed)
            buildLabelsPanel();   % (labels with faces now, or none)
        end
    end

    function revertToSaved()
        % Back to the last save
        paintTarget = savedTarget;
        appliedTarget = savedTarget;
        undoStack(:) = [];
        showPaint();
        notifyChange();
    end

    function revertToStart()
        % Back to the mesh before any edits (Save to make it stick)
        paintTarget = strings(numFaces,1);
        appliedTarget = paintTarget;
        undoStack(:) = [];
        showPaint();
        notifyChange();
    end

    function notifyChange()
        if ~isempty(options.OnChange)
            options.OnChange(getEditedMesh());
        end
    end

    function loadEdits()
        % Paint saved earlier (the edits file), put back on the faces
        if isempty(editsFile) || ~isfile(editsFile)
            return;
        end
        loaded = load(editsFile, 'labelEditsAfterSimplify');
        if ~isfield(loaded, 'labelEditsAfterSimplify')
            return;
        end
        centers = baseCenters;
        for ith_edit = 1:numel(loaded.labelEditsAfterSimplify)
            thisEdit = loaded.labelEditsAfterSimplify{ith_edit};
            if ~isfield(thisEdit, 'Points')
                continue;
            end
            target = fcn_INTERNAL_editTarget(thisEdit);
            [nearestFace, nearestDistance] = fcn_INTERNAL_nearest(centers, thisEdit.Points);
            paintTarget(nearestFace(nearestDistance <= 0.005)) = string(target);
        end
        appliedTarget = paintTarget;   % (what was saved is applied, and saved)
        savedTarget = paintTarget;
        absorbSaved();   % (and taken into the working mesh)
    end

    %% What the painter gives out
    function meshOut = getEditedMesh()
        % The mesh with the applied edits
        meshOut = data.BaseMesh;
        edits = getEdits();
        if ~isempty(edits)
            meshOut = fcn_CarMesh3D_editLabels(data.BaseMesh, Edits=edits, FigNum=-1);
        end
    end

    function fileOut = getLastVersionFile()
        fileOut = lastVersionFile;
    end

    function meshOut = getWorkingMesh()
        % (the working mesh, the base with the saved edits taken in, and its
        % label colors: what the view shows)
        meshOut = data.Mesh;
        meshOut.LabelColors = data.LabelColors;
    end

    function edits = getEdits()
        edits = fcn_INTERNAL_paintEdits(data.BaseMesh, appliedTarget);
    end

    function count = numPainted()
        count = nnz(strlength(paintTarget) > 0);
    end

    function flag = isUnsaved()
        flag = ~isequal(paintTarget, savedTarget) || ~isequal(appliedTarget, savedTarget);
    end

    function statusOut = getStatus()
        statusOut = struct('Pending', nnz(paintTarget ~= appliedTarget), 'Applied', nnz(strlength(appliedTarget) > 0), ...
            'Hidden', nnz(startsWith(appliedTarget, "hide:")), 'Deleted', 0, 'Saved', isequal(appliedTarget, savedTarget) && isequal(paintTarget, savedTarget), ...
            'UndoSteps', numel(undoStack), 'Tool', paintTool);
    end

    function updateStatus()
        % How many faces are pending, applied, and whether it is saved
        if ~isvalid(editStatusLabel)
            return;
        end
        statusNow = getStatus();
        if isempty(editsFile)
            savedText = '<font color="#606060">no edits file</font>';
        elseif isequal(appliedTarget, savedTarget)
            savedText = '<font color="#2a7a2a">saved</font>';
        else
            savedText = '<font color="#b03000"><b>not saved</b></font>';
        end
        editStatusLabel.Text = sprintf('%d faces painted, not applied  |  %d changed (%d hidden) in the modified mesh  |  %s  |  %d undo steps', ...
            statusNow.Pending, statusNow.Applied, statusNow.Hidden, savedText, statusNow.UndoSteps);
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    function stopTimer()
        % (the viewer's timer, which moves the dial as the model turns)
        if ~isempty(labelViewer)
            labelViewer.Stop();
        end
    end

    %% The mouse (shared by both kinds of window)
    function flagUsed = mouseMove()
        % A move of the mouse: drags the dial's arrow, or paints along a
        % stroke; says whether it used the move
        flagUsed = labelViewer.DialMove();
        if flagUsed
            return;
        elseif strokeOpen
            paintFaces(facesUnderMouse(false, strokeErase), strokeErase);
            flagUsed = true;
        end
    end

    function flagUsed = mouseUp()
        % The button is let go: the dial snaps to a photo, or the stroke
        % is finished; says whether it used the event
        flagUsed = labelViewer.DialUp();
        if strokeOpen
            closeStroke();
            flagUsed = true;
        end
    end

    %% Its own window: the label list, the mouse, closing
    function onOwnDown(~, ~)
        % CAD-style: left-drag rotates, right-drag pans; Ctrl+drag paints
        % (Ctrl+Shift+drag erases); a click with no drag paints a face, a
        % double-click a piece
        mouseMode = '';
        % (the photo's corner pressed: the viewer resizes the photo)
        if isfield(labelViewer, 'GripDown') && labelViewer.GripDown()
            return;
        end
        clicked = figureHandle.CurrentObject;
        if isempty(clicked) || ~isvalid(clicked) || ~isequal(ancestor(clicked, 'axes'), labelAxes)
            return;
        end
        selection = figureHandle.SelectionType;
        modifiers = figureHandle.CurrentModifier;
        if any(strcmp(modifiers, 'control'))
            mouseMode = 'stroke';
            strokeStart(any(strcmp(modifiers, 'shift')));
        elseif strcmp(selection, 'open')
            mouseMode = 'piece';
        elseif strcmp(selection, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseStart = figureHandle.CurrentPoint;
        mouseLast = mouseStart;
        mouseMoved = false;
    end

    function MouseMoveOwn()
        if mouseMove()
            drawnow limitrate;
            return;
        end
        if isempty(mouseMode) || any(strcmp(mouseMode, {'stroke', 'piece'}))
            return;
        end
        point = figureHandle.CurrentPoint;
        if ~mouseMoved && norm(point - mouseStart) < 4
            return;   % (a click, so far)
        end
        mouseMoved = true;
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(labelAxes, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(labelAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function MouseUpOwn()
        flagUsed = mouseUp();
        if ~flagUsed && ~mouseMoved && any(strcmp(mouseMode, {'rotate', 'piece'}))
            click(strcmp(mouseMode, 'piece'));
        end
        mouseMode = '';
    end

    function onOwnScroll(~, event)
        camzoom(labelAxes, 1.15^(-event.VerticalScrollCount));
    end

    function closePainter()
        % Its own window: asks to save edits not saved (when on screen)
        if ~flagOwnWindow
            stopTimer();
            return;
        end
        if ~isvalid(figureHandle)
            return;
        end
        if isUnsaved() && ~isempty(editsFile) && strcmp(figureHandle.Visible, 'on')
            choice = uiconfirm(figureHandle, 'The label edits have changes that are not saved. Save them?', ...
                'Label edits', 'Options', {'Save', 'Discard', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 3);
            if strcmp(choice, 'Cancel')
                return;
            end
            if strcmp(choice, 'Save')
                saveEdits();
            end
        end
        if options.Wait
            % (the outputs are read when uiwait returns: keep the state,
            % and the figure, until then)
            editedMesh = getEditedMesh();
            labelEdits = getEdits();
        end
        stopTimer();
        delete(figureHandle);
    end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_geometry
function geometry = fcn_INTERNAL_geometry(vehicleMesh)
% Extents, and each wheel's center and diameter (from its faces)
vertices = vehicleMesh.Vertices;
geometry.Min = min(vertices,[],1);
geometry.Max = max(vertices,[],1);
geometry.WheelCenters = nan(0,3);
geometry.WheelDiameters = nan(0,1);
if isfield(vehicleMesh, 'FaceWheelIndex')
    wheelNumbers = unique(vehicleMesh.FaceWheelIndex(vehicleMesh.FaceWheelIndex>0));
    for ith_wheel = 1:numel(wheelNumbers)
        wheelVertices = vertices(unique(vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==wheelNumbers(ith_wheel),:)),:);
        boxMin = min(wheelVertices,[],1);
        boxMax = max(wheelVertices,[],1);
        geometry.WheelCenters(end+1,:) = (boxMin+boxMax)/2;
        geometry.WheelDiameters(end+1,1) = boxMax(3) - boxMin(3);
    end
end
geometry.AxleX = [];
if isfield(vehicleMesh, 'AxleX')
    geometry.AxleX = sort(vehicleMesh.AxleX(:), 'descend');   % front first
elseif ~isempty(geometry.WheelCenters)
    geometry.AxleX = sort(uniquetol(geometry.WheelCenters(:,1), 0.05), 'descend');
end
end % Ends fcn_INTERNAL_geometry

%% fcn_INTERNAL_paintNames
function names = fcn_INTERNAL_paintNames()
% The labels faces can be painted as (parts, light types), and hide and
% unhide (never delete: Sean, 04:07)
names = {'body', 'glass', 'trim', 'interior', 'wheel', 'headlight', 'highbeam', 'tail', 'running', 'turnsignal', 'backup', ...
    'fog', 'reflector', 'licenseplate', 'marker', 'warning', 'hide', 'unhide'};
end % Ends fcn_INTERNAL_paintNames

%% fcn_INTERNAL_paintText
function textOut = fcn_INTERNAL_paintText(name)
% A paint label's button text: the headlight is the low beam
textOut = strrep(strrep(strrep(strrep(name, 'turnsignal', 'turn signal'), 'highbeam', 'high beam'), 'headlight', 'low beam'), ...
    'licenseplate', 'license plate');
end % Ends fcn_INTERNAL_paintText

%% fcn_INTERNAL_paintColor
function [color, alpha] = fcn_INTERNAL_paintColor(data, name)
% The color a label is shown in: the color most of the mesh's faces with
% that label have (in the labels view), else a standard one
defaults = struct('body', [0.75 0.75 0.78], 'glass', [0.55 0.75 0.95], 'trim', [0.18 0.18 0.18], 'interior', [0.85 0.65 0.40], ...
    'wheel', [0.08 0.08 0.08], 'headlight', [1 1 0.75], 'highbeam', [0.80 0.90 1.00], 'tail', [0.85 0.05 0.05], 'running', [1 0.6 0.2], ...
    'turnsignal', [1 0.55 0], 'backup', [0.95 0.95 0.95], 'hide', [1 0 1], 'unhide', [0.20 0.75 0.30]);
for thisType = fcn_CarMesh3D_lampTypes()'   % (the newer lamp types: their label colors; Sean, task 8)
    if ~isfield(defaults, thisType.Name)
        defaults.(thisType.Name) = thisType.LabelColor;
    end
end
if startsWith(name, 'hide:')
    name = 'hide';   % (a hidden set: "hide:<set>")
end
color = defaults.(name);
alpha = 1;
if strcmp(name, 'glass')
    alpha = 0.45;
end
if any(strcmp(name, {'hide', 'unhide'}))
    return;
end
if any(strcmp(name, {'body', 'glass', 'trim', 'interior', 'wheel'}))
    flagFaces = fcn_INTERNAL_labelFaces(data.Mesh, ['part_' name]);
else
    flagFaces = false(size(data.Mesh.Faces,1),1);
    if isfield(data.Mesh, 'LightTypeNames') && any(strcmp(data.Mesh.LightTypeNames, name))
        flagFaces = fcn_INTERNAL_labelFaces(data.Mesh, ['light_' name]);
    end
end
if any(flagFaces)
    [uniqueColors, ~, colorIndex] = unique(round(data.LabelColors(flagFaces,:)*50)/50, 'rows');
    color = uniqueColors(mode(colorIndex),:);
end
end % Ends fcn_INTERNAL_paintColor

%% fcn_INTERNAL_labelFaces
function flagFaces = fcn_INTERNAL_labelFaces(vehicleMesh, labelKey)
% The faces with this label
flagFaces = false(size(vehicleMesh.Faces,1),1);
if startsWith(labelKey, 'part_')
    partIndex = find(strcmp(vehicleMesh.PartNames, labelKey(6:end)), 1);
    flagFaces = vehicleMesh.FacePartIndex==partIndex;
    % (and the faces that also belong to it: a lamp's clear cover is a
    % light that is also glass)
    if ~isempty(partIndex) && isfield(vehicleMesh,'FaceAlsoParts') ...
            && size(vehicleMesh.FaceAlsoParts,1)==numel(flagFaces) && partIndex <= size(vehicleMesh.FaceAlsoParts,2)
        flagFaces = flagFaces(:) | vehicleMesh.FaceAlsoParts(:,partIndex);
    end
elseif strcmp(labelKey, 'light_none')
    lightPart = find(strcmp(vehicleMesh.PartNames, 'light'), 1);
    flagFaces = vehicleMesh.FacePartIndex==lightPart & vehicleMesh.FaceLightType==0;
elseif startsWith(labelKey, 'light_')
    typeIndex = find(strcmp(vehicleMesh.LightTypeNames, labelKey(7:end)), 1);
    flagFaces = vehicleMesh.FaceLightType==typeIndex;
end
end % Ends fcn_INTERNAL_labelFaces

%% fcn_INTERNAL_liftedFaces
function [liftedVertices, liftedFaces] = fcn_INTERNAL_liftedFaces(vehicleMesh, faceList, lift)
% Copies of the listed faces, each with its own three corners moved lift
% meters along the face's outward normal (so they draw on top of the mesh)
liftedVertices = zeros(0,3);
liftedFaces = zeros(0,3);
if isempty(faceList)
    return;
end
faceList = faceList(:);
corners = vehicleMesh.Faces(faceList,:);
corner1 = vehicleMesh.Vertices(corners(:,1),:);
corner2 = vehicleMesh.Vertices(corners(:,2),:);
corner3 = vehicleMesh.Vertices(corners(:,3),:);
if isfield(vehicleMesh,'FaceNormals') && size(vehicleMesh.FaceNormals,1)==size(vehicleMesh.Faces,1)
    normals = vehicleMesh.FaceNormals(faceList,:);
else
    normals = cross(corner2 - corner1, corner3 - corner1, 2);
end
normals = normals./max(vecnorm(normals,2,2), eps);
numFaces = numel(faceList);
liftedVertices = zeros(3*numFaces,3);
liftedVertices(1:3:end,:) = corner1 + lift*normals;
liftedVertices(2:3:end,:) = corner2 + lift*normals;
liftedVertices(3:3:end,:) = corner3 + lift*normals;
liftedFaces = reshape(1:3*numFaces, 3, [])';
end % Ends fcn_INTERNAL_liftedFaces

%% fcn_INTERNAL_rayHits
function hitDistance = fcn_INTERNAL_rayHits(origin, direction, vertices, faces)
% How far along the line (origin + t*direction) it hits each triangle; Inf
% where it misses (the Moller-Trumbore test, for all triangles at once)
numFaces = size(faces,1);
corner1 = vertices(faces(:,1),:);
edge1 = vertices(faces(:,2),:) - corner1;
edge2 = vertices(faces(:,3),:) - corner1;
directions = repmat(direction, numFaces, 1);
pVector = cross(directions, edge2, 2);
determinant = sum(edge1.*pVector, 2);
flagValid = abs(determinant) > 1e-12;
inverse = 1./determinant;
tVector = origin - corner1;
u = sum(tVector.*pVector, 2).*inverse;
qVector = cross(tVector, edge1, 2);
v = sum(directions.*qVector, 2).*inverse;
hitDistance = sum(edge2.*qVector, 2).*inverse;
flagHit = flagValid & u >= -1e-9 & v >= -1e-9 & u + v <= 1 + 1e-9 & hitDistance > 0;
hitDistance(~flagHit) = Inf;
end % Ends fcn_INTERNAL_rayHits

%% fcn_INTERNAL_mirrorFaces
function mirrorFace = fcn_INTERNAL_mirrorFaces(vehicleMesh)
% Each face's mirror image across the centerline (y to -y): the face whose
% center is nearest the mirrored center, within 2 cm (0 if none)
centers = fcn_INTERNAL_faceCenters(vehicleMesh);
mirrored = centers.*[1 -1 1];
[mirrorFace, distance] = fcn_INTERNAL_nearest(centers, mirrored);
mirrorFace(distance > 0.02) = 0;
end % Ends fcn_INTERNAL_mirrorFaces

%% fcn_INTERNAL_paintEdits
function edits = fcn_INTERNAL_paintEdits(vehicleMesh, paintTarget)
% The painted faces as fcn_CarMesh3D_editLabels edits: one per label, the
% faces given by their centers (Points); then unhide, then each hidden
% set (Hide)
edits = {};
centers = fcn_INTERNAL_faceCenters(vehicleMesh);
names = setdiff(fcn_INTERNAL_paintNames(), {'hide', 'unhide'}, 'stable');
hideTargets = unique(paintTarget(startsWith(paintTarget, "hide:")));
targets = [string(names(:)); "unhide"; hideTargets(:)];
for ith_target = 1:numel(targets)
    target = targets(ith_target);
    flagPainted = paintTarget == target;
    if ~any(flagPainted)
        continue;
    end
    thisEdit = struct('Name', sprintf('review: painted %s (%d faces)', target, sum(flagPainted)), ...
        'Points', round(centers(flagPainted,:), 5), 'PointTolerance', 0.005);
    if any(strcmp(target, {'body', 'glass', 'trim', 'interior', 'wheel'}))
        thisEdit.Part = char(target);
    elseif target == "unhide"
        thisEdit.Unhide = true;
    elseif startsWith(target, "hide:")
        thisEdit.Hide = char(extractAfter(target, "hide:"));
    else
        thisEdit.LightType = char(target);
    end
    edits{end+1} = thisEdit; %#ok<AGROW>
end
end % Ends fcn_INTERNAL_paintEdits

%% fcn_INTERNAL_editTarget
function target = fcn_INTERNAL_editTarget(thisEdit)
% The paint name of an edit: its light type, else its part; "hide:<set>"
% for a hidden set (and an older edits file's 'delete'), "unhide"
if isfield(thisEdit, 'Hide') && ~isempty(thisEdit.Hide)
    setName = thisEdit.Hide;
    if isequal(setName, true)
        setName = 'hidden';
    end
    target = ['hide:' char(setName)];
elseif isfield(thisEdit, 'Unhide') && isequal(thisEdit.Unhide, true)
    target = 'unhide';
elseif isfield(thisEdit, 'LightType') && ~isempty(thisEdit.LightType)
    target = char(thisEdit.LightType);
elseif isfield(thisEdit, 'Part') && strcmpi(thisEdit.Part, 'delete')
    target = 'hide:hidden';
else
    target = char(thisEdit.Part);
end
end % Ends fcn_INTERNAL_editTarget

%% fcn_INTERNAL_meshHidden
function flagHidden = fcn_INTERNAL_meshHidden(vehicleMesh)
% The faces hidden in the mesh itself (FaceHiddenSet)
flagHidden = false(size(vehicleMesh.Faces,1),1);
if isfield(vehicleMesh,'FaceHiddenSet') && numel(vehicleMesh.FaceHiddenSet)==numel(flagHidden)
    flagHidden = vehicleMesh.FaceHiddenSet(:) > 0;
end
end % Ends fcn_INTERNAL_meshHidden

%% fcn_INTERNAL_paintTooltip
function textOut = fcn_INTERNAL_paintTooltip(name)
% A paint button's tooltip
switch name
    case 'hide'
        textOut = ['Hide faces (Ctrl+drag over them): they stay in the mesh, with their labels, in the set named in ' ...
            '"Hide as", and are not drawn or measured. Never deleted: the animator can show the set again.'];
    case 'unhide'
        textOut = 'Show hidden faces again (tick "Show hidden faces" to see them, then Ctrl+drag over them)';
    otherwise
        textOut = sprintf('Paint faces as %s (Ctrl+drag over them)', fcn_INTERNAL_paintText(name));
end
end % Ends fcn_INTERNAL_paintTooltip

%% fcn_INTERNAL_meshPieces
function pieceIndex = fcn_INTERNAL_meshPieces(vehicleMesh)
% Each face's piece: faces with the same label that share a corner are in
% one piece (a lamp, a window, a wiper arm)
faces = vehicleMesh.Faces;
Nfaces = size(faces,1);
labelCode = fcn_INTERNAL_labelCode(vehicleMesh);
parent = 1:Nfaces;
    function root = findRoot(index)
        root = index;
        while parent(root) ~= root
            parent(root) = parent(parent(root));
            root = parent(root);
        end
    end
% (faces meeting at each vertex, joined when their labels match)
faceList = repmat((1:Nfaces)', 3, 1);
vertexList = faces(:);
[vertexList, order] = sort(vertexList);
faceList = faceList(order);
for ith_entry = 2:numel(vertexList)
    if vertexList(ith_entry) == vertexList(ith_entry-1)
        faceA = faceList(ith_entry);
        faceB = faceList(ith_entry-1);
        if labelCode(faceA) == labelCode(faceB)
            rootA = findRoot(faceA);
            rootB = findRoot(faceB);
            if rootA ~= rootB
                parent(rootA) = rootB;
            end
        end
    end
end
pieceIndex = zeros(Nfaces,1);
for ith_face = 1:Nfaces
    pieceIndex(ith_face) = findRoot(ith_face);
end
end % Ends fcn_INTERNAL_meshPieces

%% fcn_INTERNAL_labelCode
function code = fcn_INTERNAL_labelCode(vehicleMesh)
% One number per face for its label: part index, or 100 + light type
code = double(vehicleMesh.FacePartIndex(:));
if isfield(vehicleMesh, 'FaceLightType')
    flagLight = vehicleMesh.FaceLightType(:) > 0;
    code(flagLight) = 100 + double(vehicleMesh.FaceLightType(flagLight));
end
end % Ends fcn_INTERNAL_labelCode

%% fcn_INTERNAL_faceCenters
function centers = fcn_INTERNAL_faceCenters(vehicleMesh)
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
end % Ends fcn_INTERNAL_faceCenters

%% fcn_INTERNAL_nearest
function [nearestIndex, nearestDistance] = fcn_INTERNAL_nearest(points, queries)
% The nearest of points to each query (knnsearch if there, else in blocks)
if exist('knnsearch', 'file') == 2
    [nearestIndex, nearestDistance] = knnsearch(points, queries);
    return;
end
Nqueries = size(queries,1);
nearestIndex = zeros(Nqueries,1);
nearestDistance = zeros(Nqueries,1);
blockSize = 500;
for first = 1:blockSize:Nqueries
    rows = first:min(Nqueries, first+blockSize-1);
    squaredDistance = sum(queries(rows,:).^2,2) + sum(points.^2,2)' - 2*queries(rows,:)*points';
    [minimum, index] = min(squaredDistance, [], 2);
    nearestIndex(rows) = index;
    nearestDistance(rows) = sqrt(max(minimum,0));
end
end % Ends fcn_INTERNAL_nearest

%% fcn_INTERNAL_versionFolder
function folder = fcn_INTERNAL_versionFolder(given, editsFile, flagDefaultOnly)
% Where the timestamped copies go: the folder given; else the one last chosen
% (the MATLAB preference CarMesh3D/VersionFolder); else the project's
% scratch folder (for now); else "versions" beside the edits file
if nargin < 3
    flagDefaultOnly = false;
end
if ~isempty(given)
    folder = char(given);
    return;
end
folder = '';
if ~flagDefaultOnly && ispref('CarMesh3D', 'VersionFolder')
    folder = char(getpref('CarMesh3D', 'VersionFolder'));
end
if isempty(folder)
    projectScratch = fullfile(getenv('USERPROFILE'), 'Desktop', 'Claude', 'Project_CarMesh3D', 'scratch');
    if isfolder(projectScratch)
        folder = fullfile(projectScratch, 'meshVersions');
    elseif ~isempty(editsFile)
        folder = fullfile(fileparts(editsFile), 'versions');
    end
end
end % Ends fcn_INTERNAL_versionFolder

%% fcn_INTERNAL_radioRow
function group = fcn_INTERNAL_radioRow(parent, texts, values, width, callback, tag, flagMixed)
% One row of side-by-side radio buttons (a button group): an on/off
% choice is always a pair, Off first (a lone radio button cannot be
% clicked off). The callback gets the picked button's value. With
% flagMixed, an unseen extra button is selected when no value applies
% (an "All" row whose rows differ: a group always has one selected).
if nargin < 7
    flagMixed = false;
end
group = uibuttongroup(parent, 'BorderType', 'none', 'BackgroundColor', parent.BackgroundColor, 'Tag', tag, ...
    'SelectionChangedFcn', @(~,event) callback(event.NewValue.UserData));
x = 2;
for ith_button = 1:numel(texts)
    buttonWidth = width;
    if numel(texts{ith_button}) > 3
        buttonWidth = max(width, 8*numel(texts{ith_button}) + 26);
    end
    uiradiobutton(group, 'Text', texts{ith_button}, 'Position', [x 1 buttonWidth 22], 'UserData', values{ith_button});
    x = x + buttonWidth;
end
if flagMixed
    uiradiobutton(group, 'Text', '', 'Position', [x+200 1 10 22], 'UserData', NaN, 'Visible', 'off');
end
end % Ends fcn_INTERNAL_radioRow

%% fcn_INTERNAL_selectRadio
function fcn_INTERNAL_selectRadio(group, value)
% Select the button of this value (the unseen mixed one for NaN or [])
if isempty(group) || ~isvalid(group)
    return;
end
radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton');
for ith_radio = 1:numel(radios)
    radioValue = radios(ith_radio).UserData;
    flagMixedValue = isnumeric(value) && isempty(value);
    if (flagMixedValue && isnumeric(radioValue) && isscalar(radioValue) && isnan(radioValue)) || ...
            (~flagMixedValue && isequal(class(radioValue), class(value)) && isequal(radioValue, value))
        if ~isequal(group.SelectedObject, radios(ith_radio))
            group.SelectedObject = radios(ith_radio);
        end
        return;
    end
end
end % Ends fcn_INTERNAL_selectRadio

%% fcn_INTERNAL_common
function value = fcn_INTERNAL_common(flags)
% The common value of these flags, or [] when they differ
flags = logical(flags);
if isempty(flags) || all(flags)
    value = true;
elseif ~any(flags)
    value = false;
else
    value = [];
end
end % Ends fcn_INTERNAL_common

%% fcn_INTERNAL_gridText
function label = fcn_INTERNAL_gridText(grid, row, column, textIn, weight, tip)
% A text in a grid's cell
label = uilabel(grid, 'Text', textIn, 'FontWeight', weight, 'Tooltip', tip);
label.Layout.Row = row;
label.Layout.Column = column;
end % Ends fcn_INTERNAL_gridText

%% fcn_INTERNAL_place
function fcn_INTERNAL_place(component, row, column)
component.Layout.Row = row;
component.Layout.Column = column;
end % Ends fcn_INTERNAL_place
