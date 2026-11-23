function [editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleInput, options)
% fcn_CarMesh3D_paintLabels

% A window for fixing a vehicle's labels by painting its faces: pick a
% label (body, glass, trim, interior, wheel, a light type, or delete), then
% paint the faces that should have it. It works on its own (its own
% window), or inside another window, such as the Model Reviewer
% (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build into.
%
% It takes a mesh in, and gives the edited mesh and the edits out, so
% what comes next (the lighting checks, an animation) can use the edited
% mesh directly.
%
% PAINTING. Pick a label (the row of buttons; the one in use is shown in
% full color, bold, with a dot), then:
%   * Ctrl+drag over faces paints them; Ctrl+Shift+drag erases paint
%   * a click paints the face under it (a second click takes it off)
%   * a double-click paints the whole connected piece
%   * "Mirror to the other side" (on by default) paints the mirror-image
%     faces too
%   * glass is seen through (skipped) unless the glass tool is in use
% Untick a label's Show box to hide its faces, to reach the faces under
% them (such as a lamp under its lens).
%
% THREE LAYERS. New paint is pending (outlined in yellow) until Apply,
% which makes it part of a temporary modified mesh: applied deletions go
% out of view and out of reach, so a part can be deleted a little at a
% time. Save applies, and writes the edits to the vehicle's labelEdits
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
    baseMesh.LightTypeNames = {'headlight';'turnsignal';'running';'tail';'backup'};
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

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
if flagOwnWindow
    visibleText = 'on';
    if ~options.Visible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_paintLabels: %s', vehicleName), 'Position', [60 60 1500 900], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_paintLabels', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [1 2], 'ColumnWidth', {'1x', 230}, 'Padding', [6 6 6 6], 'ColumnSpacing', 6);
    parent = uipanel(rootGrid, 'BorderType', 'none');
else
    parent = options.Parent;
    figureHandle = ancestor(parent, 'figure');
end
mainGrid = uigridlayout(parent, [3 1], 'RowHeight', {148, '1x', 22}, 'Padding', [0 0 0 0], 'RowSpacing', 2);

% The paint tools (a row of label buttons, the hint and mirror switch,
% the edit buttons and status)
toolsGrid = uigridlayout(mainGrid, [4 1], 'RowHeight', {32, 34, 30, 26}, 'Padding', [4 2 4 2], 'RowSpacing', 4, ...
    'BackgroundColor', [1 0.96 0.85]);
names = fcn_INTERNAL_paintNames();
buttonGrid = uigridlayout(toolsGrid, [1 numel(names)+1], 'Padding', [0 0 0 0], 'ColumnSpacing', 3, ...
    'ColumnWidth', [{90}, repmat({'1x'}, 1, numel(names))], 'BackgroundColor', [1 0.96 0.85]);
uilabel(buttonGrid, 'Text', 'Paint as:', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
paintButtons = gobjects(1, numel(names));
for ith_name = 1:numel(names)
    [color, ~] = fcn_INTERNAL_paintColor(data, names{ith_name});
    paintButtons(ith_name) = uibutton(buttonGrid, 'state', 'Text', strrep(names{ith_name}, 'turnsignal', 'turn signal'), ...
        'BackgroundColor', 0.55*color + 0.45, 'UserData', names{ith_name}, ...
        'ValueChangedFcn', @onPaintTool, 'Tooltip', sprintf('Paint faces as %s (Ctrl+drag over them)', names{ith_name}));
end
hintGrid = uigridlayout(toolsGrid, [1 2], 'ColumnWidth', {'1x', 190}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 6, 'BackgroundColor', [1 0.96 0.85]);
uilabel(hintGrid, 'Text', ['Pick a label, then Ctrl+drag over faces to paint them (Ctrl+Shift+drag erases); a click paints one face ' ...
    '(click again to take it off), a double-click a whole piece. Paint is pending (yellow edges) until Apply; applied deletions ' ...
    'go out of view. Save writes the edits for the script. To reach faces under others, untick their label''s Show box.'], ...
    'FontColor', [0.45 0.3 0], 'WordWrap', 'on', 'FontSize', 11);
mirrorCheckbox = uicheckbox(hintGrid, 'Text', 'Mirror to the other side', 'Value', true, ...
    'Tooltip', 'Paint the mirror-image faces on the other side too. Turn off for one-sided parts (a fuel door).');
editGrid = uigridlayout(toolsGrid, [1 10], 'Padding', [0 0 0 0], 'ColumnSpacing', 4, 'BackgroundColor', [1 0.96 0.85], ...
    'ColumnWidth', {140, 10, 62, 62, 62, 112, 108, 108, 195, '1x'});
showDeletedCheck = uicheckbox(editGrid, 'Text', 'Show deleted faces', 'Value', false, 'ValueChangedFcn', @(~,~) showPaint(), ...
    'Tooltip', 'Show the faces deleted and applied (in magenta); they cannot be painted while hidden');
uilabel(editGrid, 'Text', '');
uibutton(editGrid, 'Text', 'Apply', 'ButtonPushedFcn', @(~,~) applyEdits(), 'FontWeight', 'bold', ...
    'Tooltip', 'Make the pending paint part of the modified mesh (deleted faces go out of view and reach)');
uibutton(editGrid, 'Text', 'Undo', 'ButtonPushedFcn', @(~,~) undoEdit(), ...
    'Tooltip', 'Take back the last click or stroke (press again to go further back, newest first)');
uibutton(editGrid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) saveEdits(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], ...
    'Tooltip', ['Apply the pending paint and save the edits (the vehicle''s labelEdits file, used by its script). ' ...
    'The saved mesh becomes the working mesh: painted faces take their new label''s look.']);
saveVersionButton = uibutton(editGrid, 'Text', 'Save as version', 'ButtonPushedFcn', @(~,~) saveVersion(), ...
    'Tooltip', 'Save, and also keep a timestamped copy (<mesh name>_YYYYMMDDHHMMSS.mat: the edits and the edited mesh, in the folder below)');
uibutton(editGrid, 'Text', 'Revert to save', 'ButtonPushedFcn', @(~,~) revertToSaved(), ...
    'Tooltip', 'Go back to the last save (pending and applied paint since then are taken off)');
uibutton(editGrid, 'Text', 'Revert to start', 'ButtonPushedFcn', @(~,~) revertToStart(), ...
    'Tooltip', 'Go back to the mesh before any edits (Save to make it stick)');
versionsCheck = uicheckbox(editGrid, 'Text', 'Timestamped copy at each save', 'Value', options.Versions && ~isempty(editsFile), ...
    'Tooltip', ['Each save also keeps a timestamped copy, in the folder below: ' ...
    '<mesh name>_YYYYMMDDHHMMSS.mat (two saves in the same second: the newer one is kept)']);
% (where the timestamped copies go: typed in, or picked with Browse; the choice
% is remembered for next time)
folderGrid = uigridlayout(toolsGrid, [1 3], 'ColumnWidth', {170, '1x', 80}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4, ...
    'BackgroundColor', [1 0.96 0.85]);
uilabel(folderGrid, 'Text', 'Timestamped copies go in:', 'HorizontalAlignment', 'right');
versionFolderField = uieditfield(folderGrid, 'text', 'Value', versionFolder, ...
    'ValueChangedFcn', @(source,~) setVersionFolder(source.Value), ...
    'Tooltip', 'The folder for the timestamped copies (made if it does not exist); remembered for next time');
versionBrowseButton = uibutton(folderGrid, 'Text', 'Browse...', 'ButtonPushedFcn', @(~,~) browseVersionFolder());
if isempty(editsFile)
    saveVersionButton.Enable = 'off';
    versionsCheck.Enable = 'off';
    versionFolderField.Enable = 'off';
    versionBrowseButton.Enable = 'off';
end
editStatusLabel = uilabel(editGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11);

% The model, the photos and their dial, and (in its own window) the list
% of labels: the viewer (fcn_CarMesh3D_viewLabels), built in, so a fix
% to the viewer is a fix here
viewerHolder = uipanel(mainGrid, 'BorderType', 'none');
viewerHolder.Layout.Row = 2;
hintLabel = uilabel(mainGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35]);
hintLabel.Layout.Row = 3;
listParent = [];
if flagOwnWindow
    sideGrid = uigridlayout(rootGrid, [2 1], 'RowHeight', {'1x', 40}, 'Padding', [0 0 0 0]);
    listParent = uipanel(sideGrid, 'BorderType', 'none');
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closePainter());
end
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
[~, labelViewer] = fcn_CarMesh3D_viewLabels(baseMesh, Parent=viewerHolder, LabelListParent=listParent, ...
    PhotoFolder=photoFolder, Outline=outline, OnHint=@setHint, ColorFilter=@paintedColors, ...
    HiddenFaces=@hiddenFaces, History=meshHistory, FigNum=-1);
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
        'CloseRequestFcn', @(~,~) closePainter());
    labelPatch.ButtonDownFcn = [];
end

% Saved edits
loadEdits();
showPaint();
setHint(['Mouse: left-drag rotates, right-drag pans, the wheel zooms. Pick a label above, then Ctrl+drag to paint. ' ...
    'Photos: drag the red arrow around the vehicle (or click on the dial).']);

painter = struct('Figure', figureHandle, 'Axes', labelAxes, 'Patch', labelPatch, 'EditsFile', editsFile, ...
    'ShowLabel', @showLabel, 'SetHidden', @setHidden, ...
    'EditedMesh', @getEditedMesh, 'Edits', @getEdits, 'NumPainted', @numPainted, 'IsUnsaved', @isUnsaved, 'Status', @getStatus, ...
    'Apply', @applyEdits, 'Undo', @undoEdit, 'Save', @() saveEdits(), 'SaveVersion', @saveVersion, ...
    'LastVersionFile', @getLastVersionFile, 'VersionFolder', @getVersionFolder, 'SetVersionFolder', @setVersionFolder, 'WorkingMesh', @getWorkingMesh, 'RevertToSaved', @revertToSaved, 'RevertToStart', @revertToStart, ...
    'SetTool', @setTool, 'Paint', @testPaint, 'SetPhotoAngle', labelViewer.SetPhotoAngle, 'PhotoAngle', labelViewer.PhotoAngle, 'Viewer', labelViewer, ...
    'StrokeStart', @strokeStart, 'MouseMove', @mouseMove, 'MouseUp', @mouseUp, 'Click', @click, ...
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
    end

    function setHidden(keysToHide)
        % Hide the faces of these labels ({} shows all) (the viewer)
        labelViewer.SetHidden(keysToHide);
        showPaint();
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
        % faces deleted and applied unless "Show deleted faces" is ticked
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
        if ~(isvalid(showDeletedCheck) && showDeletedCheck.Value)
            flagHidden = flagHidden | appliedTarget == "delete";
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

    %% The tools
    function onPaintTool(source, ~)
        % One paint tool at a time; pressing it again puts it down
        if source.Value
            paintTool = source.UserData;
        else
            paintTool = '';
        end
        markPaintButtons();
    end

    function setTool(name)
        paintTool = char(name);
        markPaintButtons();
    end

    function markPaintButtons()
        % The tool in use: its button in full color, bold, with a dot; the
        % others pale
        for ith_button = 1:numel(paintButtons)
            if ~isvalid(paintButtons(ith_button))
                continue;
            end
            name = paintButtons(ith_button).UserData;
            [color, ~] = fcn_INTERNAL_paintColor(data, name);
            label = strrep(name, 'turnsignal', 'turn signal');
            if strcmp(name, paintTool)
                set(paintButtons(ith_button), 'Value', true, 'BackgroundColor', color, 'FontWeight', 'bold', ...
                    'Text', [char(9679) ' ' label], 'FontColor', fcn_INTERNAL_textColor(color));
            else
                set(paintButtons(ith_button), 'Value', false, 'BackgroundColor', 0.55*color + 0.45, 'FontWeight', 'normal', ...
                    'Text', label, 'FontColor', [0 0 0]);
            end
        end
    end

    %% Painting
    function paintFaces(faces, flagErase)
        % Paints these faces (and their mirror images) with the tool's
        % label, or erases their paint; remembered for Undo
        faces = faces(:);
        if isempty(faces) || (~flagErase && isempty(paintTool))
            return;
        end
        if isvalid(mirrorCheckbox) && mirrorCheckbox.Value
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
            paintTarget(faces) = string(paintTool);
        end
        showPaint();
    end

    function faces = facesUnderMouse(flagSingle, flagErase)
        % The faces under the mouse, nearest the camera: within a small
        % brush, or the one face nearest the line (flagSingle). Hidden
        % faces are skipped, and so is glass unless the glass tool is in
        % use or paint is being erased.
        faces = [];
        if ~isvalid(labelAxes)
            return;
        end
        ray = labelAxes.CurrentPoint;   % (2 x 3: the front and back of the line under the mouse)
        direction = ray(2,:) - ray(1,:);
        direction = direction/norm(direction);
        centers = fcn_INTERNAL_faceCenters(data.Mesh);
        offsets = centers - ray(1,:);
        depth = offsets*direction';
        distance = vecnorm(offsets - depth.*direction, 2, 2);
        vehicleLength = data.Geometry.Max(1) - data.Geometry.Min(1);
        brush = 0.012*vehicleLength;
        eligible = ~hiddenFaces();
        if ~flagErase && ~strcmp(paintTool, 'glass')
            eligible = eligible & ~currentlyGlass();
        end
        near = find(distance < brush & eligible);
        if isempty(near)
            return;
        end
        front = min(depth(near));
        near = near(depth(near) < front + 0.12);
        if flagSingle
            [~, nearest] = min(distance(near));
            near = near(nearest);
        end
        faces = near;
    end

    function strokeStart(flagErase)
        % A Ctrl+drag stroke begins (one Undo entry for the whole stroke)
        strokeOpen = true;
        strokeErase = logical(flagErase);
        strokeFaces = zeros(0,1);
        strokeBefore = strings(0,1);
        if ~strokeErase && isempty(paintTool)
            setHint('<b>Pick a label first</b> (the row of buttons above the model), then Ctrl+drag to paint.');
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
            setHint('<b>Pick a label first</b> (the row of buttons above the model), then click or Ctrl+drag to paint.');
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
        flagAlreadyPainted = all(paintTarget(face) == string(paintTool));
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
        % (deleted faces go out of view, and out of reach)
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
            flagVersion = isvalid(versionsCheck) && versionsCheck.Value;
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
                    Details=sprintf('%d faces changed from the download (%d deleted)', nnz(strlength(savedTarget) > 0), ...
                    nnz(savedTarget == "delete")), FigNum=-1);
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
        % and label color are the edited mesh's (deleted faces keep their
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
            for fieldName = {'FaceColors', 'FaceAlpha'}
                if isfield(editedNow, fieldName{1}) && size(editedNow.(fieldName{1}),1) == size(editedNow.Faces,1) && ...
                        isfield(workingMesh, fieldName{1}) && size(workingMesh.(fieldName{1}),1) == numFaces
                    workingMesh.(fieldName{1})(baseIndex,:) = editedNow.(fieldName{1})(flagMatch,:);
                end
            end
            data.Mesh = workingMesh;
            data.LabelColors(baseIndex,:) = editedLabels.FaceColors(flagMatch,:);
            data.LabelAlpha(baseIndex) = editedAlpha(flagMatch);
        end
        if ~isempty(labelViewer)
            labelViewer.SetMesh(data.Mesh, data.LabelColors, data.LabelAlpha);   % (its list too, if the labels changed)
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
            'Deleted', nnz(appliedTarget == "delete"), 'Saved', isequal(appliedTarget, savedTarget) && isequal(paintTarget, savedTarget), ...
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
        editStatusLabel.Text = sprintf('%d faces painted, not applied  |  %d changed (%d deleted) in the modified mesh  |  %s  |  %d undo steps', ...
            statusNow.Pending, statusNow.Applied, statusNow.Deleted, savedText, statusNow.UndoSteps);
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
% The labels faces can be painted as (parts, light types, and delete)
names = {'body', 'glass', 'trim', 'interior', 'wheel', 'headlight', 'tail', 'running', 'turnsignal', 'backup', 'delete'};
end % Ends fcn_INTERNAL_paintNames

%% fcn_INTERNAL_paintColor
function [color, alpha] = fcn_INTERNAL_paintColor(data, name)
% The color a label is shown in: the color most of the mesh's faces with
% that label have (in the labels view), else a standard one
defaults = struct('body', [0.75 0.75 0.78], 'glass', [0.55 0.75 0.95], 'trim', [0.18 0.18 0.18], 'interior', [0.85 0.65 0.40], ...
    'wheel', [0.08 0.08 0.08], 'headlight', [1 1 0.75], 'tail', [0.85 0.05 0.05], 'running', [1 0.6 0.2], ...
    'turnsignal', [1 0.55 0], 'backup', [0.95 0.95 0.95], 'delete', [1 0 1]);
color = defaults.(name);
alpha = 1;
if strcmp(name, 'glass')
    alpha = 0.45;
end
if strcmp(name, 'delete')
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

%% fcn_INTERNAL_textColor
function textColor = fcn_INTERNAL_textColor(backgroundColor)
% Black or white text, whichever reads better on this background
if [0.299 0.587 0.114]*backgroundColor(:) > 0.5
    textColor = [0 0 0];
else
    textColor = [1 1 1];
end
end % Ends fcn_INTERNAL_textColor

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
% faces given by their centers (Points); deletions last
edits = {};
centers = fcn_INTERNAL_faceCenters(vehicleMesh);
names = fcn_INTERNAL_paintNames();
names = [setdiff(names, {'delete'}, 'stable'), {'delete'}];
for ith_name = 1:numel(names)
    name = names{ith_name};
    flagPainted = paintTarget == string(name);
    if ~any(flagPainted)
        continue;
    end
    thisEdit = struct('Name', sprintf('review: painted %s (%d faces)', name, sum(flagPainted)), ...
        'Points', round(centers(flagPainted,:), 5), 'PointTolerance', 0.005);
    if any(strcmp(name, {'body', 'glass', 'trim', 'interior', 'wheel'}))
        thisEdit.Part = name;
    elseif strcmp(name, 'delete')
        thisEdit.Part = 'delete';
    else
        thisEdit.LightType = name;
    end
    edits{end+1} = thisEdit; %#ok<AGROW>
end
end % Ends fcn_INTERNAL_paintEdits

%% fcn_INTERNAL_editTarget
function target = fcn_INTERNAL_editTarget(thisEdit)
% The paint name of an edit (its light type, else its part)
if isfield(thisEdit, 'LightType') && ~isempty(thisEdit.LightType)
    target = char(thisEdit.LightType);
else
    target = char(thisEdit.Part);
end
end % Ends fcn_INTERNAL_editTarget

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
