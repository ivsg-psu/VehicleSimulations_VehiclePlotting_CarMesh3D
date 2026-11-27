function [fixedMesh, faceFlips, window] = fcn_CarMesh3D_fixFaceDirections(vehicleInput, options)
% fcn_CarMesh3D_fixFaceDirections
% A window for fixing the direction faces point (step 1E of the plan of
% 2026-11-27; Q3: a window of its own, using the painter's picking). Many
% downloads have faces turned inside out: they light wrongly, and anything
% that trusts their direction goes wrong. In the agreed import order this
% comes after the coarse labels (glass and lamps) and before the labels
% worked out from geometry (Sean, 2026-11-27 04:03).
%
% The model is colored by which way each face points, as seen from
% outside (fcn_CarMesh3D_outwardSides, which does not trust the faces'
% own directions):
%       green  the face points out
%       red    the face points in: a suggested flip (also outlined)
%       gray   cannot tell from the shape (inside the body, or open to the
%              outside on both sides); the face keeps its direction
% It works as the painter does (T96, Sean 2026-11-27 13:03: click, view
% the selection, apply it, confirm visually, save):
%   1. Select (selected faces are filled yellow and outlined, on both
%      sides of each face):
%       Ctrl+click          the face under the mouse
%       Ctrl+double-click   its region (the connected faces of the same
%                           label and the same color)
%       Ctrl+drag           the faces under the brush
%       Ctrl+Shift          (with any of these) unselects instead
%       Esc                 unselects everything
%       "Select the suggested faces" selects every red face
%   2. Apply (the Apply button): the selected faces are flipped, and the
%      selection is cleared. The colors show the result.
%   3. Undo (Ctrl+Z) takes back the last step (a selection, an Esc, an
%      Apply, a revert), and again to go further back. Revert to start
%      goes back to the flips as they were when the window opened.
%   4. Save (Ctrl+S) writes the flips to the vehicle's faceFlips file, by
%      face position, for its build to replay (step 1F). Undo after a save
%      changes the window, not the file: the status says "not saved"
%      until Save is pressed again.
% left-drag rotates, right-drag pans, the wheel zooms. The light follows
% the camera. After each Ctrl+click the hint line says which face was
% picked and how many other faces lie within 1 cm behind it (T96: some
% faces could not be picked).
%
% FORMAT:
%
%       [fixedMesh, faceFlips, window] = fcn_CarMesh3D_fixFaceDirections(vehicleInput,...
%           (FlipsFile=file), (FlagWait=flag), (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID (its mesh before the painted edits, if
%      cached, else its saved mesh; the flips file is in its folder), or a
%      CarMesh3D mesh structure.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlipsFile: where the flips are saved (and read from, if it exists).
%      Default: faceFlips_<ID>.mat in the vehicle's folder; none for a mesh
%      given directly (Save then only keeps them in the window).
%
%      FlagWait: wait until the window is closed, then return. Default
%      false.
%
%      FlagVisible: false builds the window hidden (tests). Default true.
%
%      FigNum: not used (a window); -1 for fast mode.
%
% OUTPUTS:
%
%      fixedMesh: the mesh with the flipped faces turned around (their
%      corners in the other order; FaceNormals, if present, negated).
%
%      faceFlips: the flips, as saved: a structure with Points (N x 3, the
%      flipped faces' centers), Normals (N x 3, the way each should point),
%      NumFaces (the mesh's faces), Who, SavedOn. Replayed by
%      fcn_CarMesh3D_applyFaceFlips (in the build, and when the mesh is
%      loaded with fcn_CarMesh3D_meshWithLabelEdits).
%
%      window: a structure of functions for scripts and tests (rule G32):
%           Figure, Axes, Patch; State, SetState, Press, Key, CheckLayout
%           (fcn_CarMesh3D_guiDriver); ClickAt(target, modifiers),
%           DoubleClickAt(target, modifiers), DragAt(targets,
%           modifiers), FaceAt(target) (target: a face number or a 3D
%           point); Select(faces), SelectSuggested(), ClearSelection(),
%           Apply(), Revert(), Flip(faces) (flips at once, no selection),
%           FlipSuggested() (selects the suggested faces and applies),
%           Undo(), Save(); Selected(), Flipped(), Suggested(), Status(),
%           LastPick(), FixedMesh(),
%           FaceFlips(), Sides() (fcn_CarMesh3D_outwardSides' answer);
%           SetColorBy('direction' or 'labels'), SetBrush(name);
%           SetSize(width, height); Close().
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_outwardSides,
%      fcn_CarMesh3D_meshPickTools, fcn_CarMesh3D_loadingWindow,
%      fcn_CarMesh3D_addTitleBar, fcn_CarMesh3D_makePanelMenu,
%      fcn_CarMesh3D_guiDriver
%
% EXAMPLES:
%
%       fcn_CarMesh3D_fixFaceDirections('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_fixFaceDirections.m for
%       a full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fixFaceDirections
%   % * First write (step 1E of the plan of 2026-11-27)
%   % * The flips are saved with the way each face should point (Normals),
%   %   % so replaying them is safe to repeat; flips saved before are kept
%   %   % when saving again (step 1F)
%   % * Rebuilt on the painter's flow (T96, Sean 13:03): select (Ctrl+
%   %   % click one face, Ctrl+double-click a region, Ctrl+drag the brush,
%   %   % Ctrl+Shift unselects, Esc unselects all), Apply flips the
%   %   % selection, Undo steps back, Revert to start, Save
%   % * The light follows the camera; more ambient light (T96: the side
%   %   % away from the light was too dark)
%   % * Clicks are taken anywhere over the model's axes, not only where
%   %   % the figure's CurrentObject is in them; the overlays cannot be
%   %   % clicked (T96: clicks on some faces did nothing)
%   % * The hint line names the face each click picked (T96)

% TO-DO:
%
% (none)

arguments
    vehicleInput
    options.FlipsFile = []      % Where the flips are saved; [] for the default
    options.FlagWait = false    % Wait until the window is closed
    options.FlagVisible = true  % Build the window hidden (tests)
    options.FigNum = []         % Not used (a window); -1 for fast mode
end

%% Debugging and Input checks
flag_max_speed = 0;
if isequal(options.FigNum,-1)
    flag_check_inputs = 0;
    flag_max_speed = 1;
else
    flag_check_inputs = 1;
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS)
        flag_check_inputs = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end
if 0==flag_max_speed && flag_check_inputs
    if ~(ischar(vehicleInput) || isstring(vehicleInput) || (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Vertices','Faces'}))))
        error('vehicleInput must be a vehicle ID or a CarMesh3D mesh structure (Vertices, Faces)');
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

%%%% The mesh and the flips file
% (a loading window at once: working out the sides takes a few seconds on
% a vehicle; rule G43)
loading = fcn_CarMesh3D_loadingWindow('Opening the face-direction window', Vehicle=vehicleInput, FlagVisible=options.FlagVisible);
loadingCleanup = onCleanup(@() loading.Close()); %#ok<NASGU>
flipsFile = '';
vehicleName = 'mesh';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    baseMesh = [];
    stage1File = fullfile(vehicleFiles.Folder, 'cache', 'stage1_mesh.mat');
    if isfile(stage1File)
        stage1 = load(stage1File, 'cacheOutputs');
        if isfield(stage1, 'cacheOutputs') && isfield(stage1.cacheOutputs, 'vehicleMesh')
            baseMesh = stage1.cacheOutputs.vehicleMesh;
        end
    end
    if isempty(baseMesh)
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        baseMesh = loaded.vehicleMesh;
    end
    flipsFile = fullfile(vehicleFiles.Folder, sprintf('faceFlips_%s.mat', vehicleFiles.ID));
else
    baseMesh = vehicleInput;
    if isfield(baseMesh, 'Name')
        vehicleName = char(baseMesh.Name);
    end
end
if ~isempty(options.FlipsFile)
    flipsFile = char(options.FlipsFile);
end
numFaces = size(baseMesh.Faces,1);
pick = fcn_CarMesh3D_meshPickTools(FigNum=-1);
centers = pick.FaceCenters(baseMesh.Vertices, baseMesh.Faces);
meshSize = norm(max(baseMesh.Vertices,[],1) - min(baseMesh.Vertices,[],1));
labelCode = ones(numFaces,1);
if isfield(baseMesh, 'LabelFacePart') && numel(baseMesh.LabelFacePart) == numFaces
    labelCode = double(baseMesh.LabelFacePart(:));
    if isfield(baseMesh, 'LabelFaceLamp') && numel(baseMesh.LabelFaceLamp) == numFaces
        flagLamp = baseMesh.LabelFaceLamp(:) > 0;
        labelCode(flagLamp) = 100 + double(baseMesh.LabelFaceLamp(flagLamp));
    end
end
labelColors = repmat([0.75 0.75 0.75], numFaces, 1);
if isfield(baseMesh, 'FaceColors') && size(baseMesh.FaceColors,1) == numFaces
    labelColors = baseMesh.FaceColors;
end

% Which side of each face is seen from outside (+1: its corner order
% points out), worked out once; rule 1 where the shape says
[outwardSign, sidesInfo] = fcn_CarMesh3D_outwardSides(baseMesh, FigNum=-1);
flagKnown = sidesInfo.Rule == 1;

%%%% State
flipped = false(numFaces,1);
savedFlipped = false(numFaces,1);
selected = false(numFaces,1);
% (each Undo step: the faces one action changed, and their flipped and
% selected states before it)
undoStack = struct('Faces', {}, 'Flipped', {}, 'Selected', {}, 'Text', {});
strokeOpen = false;
strokeFaces = zeros(0,1);
strokeEntry = [];
strokeErase = false;
lastPick = struct('Face', [], 'Behind', 0, 'Text', '');
lightHandle = [];
colorBy = 'direction';
brushSizes = struct('Name', {'Fine', 'Medium', 'Large'}, 'Pixels', {5, 14, 36});
brushName = 'Medium';
mouseInjected = [];
mouseMode = '';
mouseStart = [0 0];
mouseLast = [0 0];
mouseMoved = false;
mouseErase = false;
strokeLastPixel = [];
whoName = 'SBB';
try
    if ispref('CarMesh3D', 'Initials')
        whoName = char(getpref('CarMesh3D', 'Initials'));
    end
catch
end
% (the saved flips: each a face's center and the way its normal should
% point. A face that does not point that way in this mesh shows flipped;
% one that already does (its build replayed the flips) is kept in the
% list, so saving again does not drop it)
faceFlips = fcn_INTERNAL_emptyFlips(numFaces);
storedFaces = zeros(0,1);
if ~isempty(flipsFile) && isfile(flipsFile)
    loaded = load(flipsFile, 'faceFlips');
    if isfield(loaded, 'faceFlips') && isfield(loaded.faceFlips, 'Points') && isfield(loaded.faceFlips, 'Normals') ...
            && ~isempty(loaded.faceFlips.Points)
        [nearestFace, nearestDistance] = pick.Nearest(centers, loaded.faceFlips.Points);
        flagMatched = nearestDistance(:) <= 0.005;
        storedFaces = unique(nearestFace(flagMatched));
        baseNormals = fcn_INTERNAL_normals(baseMesh.Vertices, baseMesh.Faces(nearestFace(flagMatched),:));
        flagWrong = sum(baseNormals.*loaded.faceFlips.Normals(flagMatched,:), 2) < 0;
        matched = nearestFace(flagMatched);
        flipped(matched(flagWrong)) = true;
        savedFlipped = flipped;
        faceFlips = loaded.faceFlips;
    end
end
startFlipped = flipped;   % (Revert to start comes back here)

%%%% The window: a title bar; a top bar (the menu, Undo, Save, the
%%%% status); the menu's column at the left with the Face Directions
%%%% panel; the model; a hint line
visibleText = 'on';
if ~options.FlagVisible
    visibleText = 'off';
end
figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_fixFaceDirections: %s', vehicleName), 'Position', [80 80 1300 820], ...
    'Visible', visibleText);
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_fixFaceDirections', Subtitle=vehicleName, FigNum=-1);
rootGrid = uigridlayout(contentPanel, [3 1], 'RowHeight', {36, '1x', 20}, 'Padding', [6 4 6 4], 'RowSpacing', 3);
topGrid = uigridlayout(rootGrid, [1 5], 'ColumnWidth', {90, 80, 110, 80, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'facesMenu', ...
    'Tooltip', 'Open a panel at the left (pick an open one again to close it)');
uibutton(topGrid, 'Text', 'Undo', 'ButtonPushedFcn', @(~,~) undoFlip(), 'Tag', 'facesUndo', ...
    'Tooltip', 'Take back the last step (a selection, Esc, Apply, a revert); press again to go further back. Ctrl+Z.');
uibutton(topGrid, 'Text', 'Revert to start', 'ButtonPushedFcn', @(~,~) revertToStart(true), 'Tag', 'facesRevert', ...
    'Tooltip', 'Go back to the flips as they were when this window opened (asks first; Undo takes it back). The file changes only when you Save.');
uibutton(topGrid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) saveFlips(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], ...
    'Tag', 'facesSave', 'Tooltip', 'Save the flips (by face position) to the vehicle''s faceFlips file, for its build to replay. Ctrl+S.');
statusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11, 'Tag', 'facesStatus');
bodyGrid = uigridlayout(rootGrid, [1 2], 'ColumnWidth', {320, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
panelMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
    Exit=@() closeWindow(), ExitTag='facesExit', FigNum=-1);
yellowBand = [1 0.96 0.85];   % (editing work, rule G8)
facesPanel = panelMenu.AddPanel('Face Directions', yellowBand);
modelPanel = uipanel(bodyGrid, 'BorderType', 'none', 'BackgroundColor', 'w');
hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35], 'Tag', 'facesHint');

% The model
modelAxes = uiaxes(modelPanel, 'Units', 'normalized', 'Position', [0 0 1 1], 'Tag', 'facesAxes');
modelAxes.Toolbar.Visible = 'off';
disableDefaultInteractivity(modelAxes);
axis(modelAxes, 'equal');
axis(modelAxes, 'off');
modelAxes.Projection = 'perspective';
% (back faces lit as front ones, 'reverselit', so a face pointing in is
% as bright as one pointing out: its color says which way it points)
modelPatch = patch(modelAxes, 'Vertices', baseMesh.Vertices, 'Faces', baseMesh.Faces, 'FaceColor', 'flat', ...
    'FaceVertexCData', labelColors, 'EdgeColor', 'none', 'FaceLighting', 'flat', 'BackFaceLighting', 'reverselit', ...
    'AmbientStrength', 0.55, 'DiffuseStrength', 0.55, 'SpecularStrength', 0.05, 'Tag', 'facesModel');
% (the overlays cannot be clicked: clicks go to the model, T96)
suggestedPatch = patch(modelAxes, 'Vertices', zeros(0,3), 'Faces', zeros(0,3), 'FaceColor', 'none', ...
    'EdgeColor', [0.55 0 0], 'LineWidth', 0.75, 'HitTest', 'off', 'PickableParts', 'none', 'Clipping', 'off', 'Tag', 'facesSuggested');
selectionPatch = patch(modelAxes, 'Vertices', zeros(0,3), 'Faces', zeros(0,3), 'FaceColor', [1 0.85 0.1], 'FaceAlpha', 0.55, ...
    'EdgeColor', [1 0.7 0], 'LineWidth', 0.75, 'FaceLighting', 'none', 'HitTest', 'off', 'PickableParts', 'none', ...
    'Clipping', 'off', 'Tag', 'facesSelection');
view(modelAxes, -35, 20);
lightHandle = camlight(modelAxes, 'headlight');
light(modelAxes, 'Position', [0 0 1], 'Style', 'infinite', 'Color', [0.35 0.35 0.35]);   % (from above, faint)
lighting(modelAxes, 'flat');

% The Face Directions panel
panelGrid = uigridlayout(facesPanel, [10 1], 'RowHeight', {170, 22, 26, 22, 26, 30, 34, 26, 60, '1x'}, 'Padding', [8 8 8 8], ...
    'RowSpacing', 4, 'Scrollable', 'on', 'BackgroundColor', yellowBand);
uilabel(panelGrid, 'Interpreter', 'html', 'WordWrap', 'on', 'Tag', 'facesLegend', 'Text', ...
    ['<b>Colors</b> (seen from outside):<br>' ...
    '<font color="#1f9e3a">&#9632;</font> points out<br>' ...
    '<font color="#d42020">&#9632;</font> points in: a suggested flip (outlined)<br>' ...
    '<font color="#8c8c8c">&#9632;</font> cannot tell from the shape (inside the body, or open on both sides): kept as it is<br>' ...
    '<font color="#e6b800">&#9632;</font> selected (Apply flips it)<br>' ...
    '<i>The suggestions are hints, from one line out of each face: a face in a narrow gap can be suggested wrongly. Look before flipping them all.</i>']);
uilabel(panelGrid, 'Text', 'Color the model by?', 'FontWeight', 'bold');
colorGroup = fcn_INTERNAL_radioRow(panelGrid, {'Direction', 'Labels'}, {'direction', 'labels'}, @(value) setColorBy(value), ...
    'facesColorBy', 'Direction: green out, red in, gray cannot tell. Labels: the mesh''s own colors.');
uilabel(panelGrid, 'Text', 'Brush size (Ctrl+drag)?', 'FontWeight', 'bold');
brushGroup = fcn_INTERNAL_radioRow(panelGrid, {brushSizes.Name}, {brushSizes.Name}, @(value) setBrush(value), ...
    'facesBrush', 'How much a Ctrl+drag selects: a circle this size on the screen, at any zoom.');
suggestButton = uibutton(panelGrid, 'Text', 'Select the suggested faces', 'ButtonPushedFcn', @(~,~) selectSuggested(), ...
    'Tag', 'facesSelectSuggested', 'Tooltip', 'Select every red face (seen from outside pointing in); look, then Apply to flip them.');
applyButton = uibutton(panelGrid, 'Text', 'Apply: flip the selected faces', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) applySelection(), ...
    'Tag', 'facesApply', 'Tooltip', 'Flip the selected (yellow) faces and clear the selection; Undo takes it back.');
clearButton = uibutton(panelGrid, 'Text', 'Unselect all (Esc)', 'ButtonPushedFcn', @(~,~) clearSelection(), ...
    'Tag', 'facesClearSelection', 'Tooltip', 'Unselect every selected face; Undo puts them back.');
countsLabel = uilabel(panelGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'Tag', 'facesCounts');
uilabel(panelGrid, 'Interpreter', 'html', 'WordWrap', 'on', 'VerticalAlignment', 'top', 'Text', ...
    ['<b>Selecting</b> (as in the painter)<br>Ctrl+click: one face<br>Ctrl+double-click: its region (same label, same color)<br>' ...
    'Ctrl+drag: the faces under the brush<br>Ctrl+Shift with any of these: unselect; Esc: unselect all<br>' ...
    '<b>Then</b> Apply flips them; look; Save.<br>' ...
    'Left-drag rotates, right-drag pans, the wheel zooms.']);
fcn_INTERNAL_selectRadio(colorGroup, colorBy);
fcn_INTERNAL_selectRadio(brushGroup, brushName);
panelMenu.OpenPanels({'Face Directions'});

set(figureHandle, 'WindowButtonDownFcn', @(~,~) onDown(), 'WindowButtonMotionFcn', @(~,~) onMove(), ...
    'WindowButtonUpFcn', @(~,~) onUp(), 'WindowScrollWheelFcn', @onScroll, 'WindowKeyPressFcn', @onKey, ...
    'CloseRequestFcn', @(~,~) closeWindow());
showFaces();
setHint('Red faces point into the vehicle as seen from outside. Select them (Ctrl+click, Ctrl+double-click, Ctrl+drag, or "Select the suggested faces"), look, then Apply to flip them. Save when done.');

window = struct('Figure', figureHandle, 'Axes', modelAxes, 'Patch', modelPatch, 'FlipsFile', flipsFile, ...
    'State', @() fcn_CarMesh3D_guiDriver(figureHandle, 'state'), ...
    'SetState', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'set', varargin{:}), ...
    'Press', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'press', varargin{:}), ...
    'Key', @(key, varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'key', key, 'Modifier', fcn_INTERNAL_modifiers(varargin)), ...
    'CheckLayout', @() fcn_CarMesh3D_guiDriver(figureHandle, 'checkLayout'), ...
    'ClickAt', @clickAt, 'DoubleClickAt', @doubleClickAt, 'DragAt', @dragAt, 'FaceAt', @faceAt, ...
    'Select', @(faces) selectFaces(faces, true, 'select'), 'SelectSuggested', @selectSuggested, ...
    'ClearSelection', @clearSelection, 'Apply', @applySelection, 'Revert', @() revertToStart(false), ...
    'Flip', @(faces) flipFaces(faces, true), 'FlipSuggested', @flipSuggested, 'Undo', @undoFlip, 'Save', @saveFlips, ...
    'Selected', @getSelected, 'Flipped', @getFlipped, 'Suggested', @getSuggested, 'Status', @getStatus, 'LastPick', @getLastPick, ...
    'FixedMesh', @getFixedMesh, 'FaceFlips', @getFaceFlips, 'Sides', @() struct('OutwardSign', outwardSign, 'Info', sidesInfo), ...
    'SetColorBy', @setColorBy, 'SetBrush', @setBrush, 'SetSize', @setSize, 'Close', @closeWindow);
figureHandle.UserData = window;
loading.Close();   % (built: closed here, since nested functions keep onCleanup from running while the window is open)

if options.FlagWait && options.FlagVisible && isvalid(figureHandle)
    uiwait(figureHandle);
end
fixedMesh = getFixedMesh();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the window's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function flagOut = currentlyOut()
        % (true where the face, as it is now, points out)
        flagOut = (outwardSign.*(1 - 2*double(flipped))) > 0;
    end

    function flagSuggested = suggestedFaces()
        % (the shape says the face points in)
        flagSuggested = flagKnown & ~currentlyOut();
    end

    function faces = currentFaces()
        faces = baseMesh.Faces;
        faces(flipped,:) = faces(flipped, [1 3 2]);
    end

    function showFaces()
        % The model as it is now: its faces turned as flipped, colored by
        % direction or by label; the suggested flips outlined
        if ~isvalid(figureHandle)
            return;
        end
        faces = currentFaces();
        if strcmp(colorBy, 'direction')
            colors = repmat([0.55 0.55 0.55], numFaces, 1);
            flagOut = currentlyOut();
            colors(flagKnown & flagOut,:) = repmat([0.12 0.62 0.23], nnz(flagKnown & flagOut), 1);
            colors(flagKnown & ~flagOut,:) = repmat([0.83 0.13 0.13], nnz(flagKnown & ~flagOut), 1);
        else
            colors = labelColors;
        end
        set(modelPatch, 'Faces', faces, 'FaceVertexCData', colors);
        flagSuggested = suggestedFaces();
        [liftedVertices, liftedFaces] = pick.LiftedFaces(baseMesh.Vertices, faces, find(flagSuggested), 0.002);
        set(suggestedPatch, 'Vertices', liftedVertices, 'Faces', liftedFaces);
        numSuggested = nnz(flagSuggested);
        [selectedVertices, selectedFaces] = pick.LiftedFaces(baseMesh.Vertices, faces, find(selected), 0.0025);
        set(selectionPatch, 'Vertices', selectedVertices, 'Faces', selectedFaces);
        numSelected = nnz(selected);
        suggestButton.Text = sprintf('Select the suggested faces (%d)', numSuggested);
        suggestButton.Enable = matlab.lang.OnOffSwitchState(numSuggested > 0 && any(flagSuggested & ~selected));
        applyButton.Text = sprintf('Apply: flip the selected faces (%d)', numSelected);
        applyButton.Enable = matlab.lang.OnOffSwitchState(numSelected > 0);
        clearButton.Enable = matlab.lang.OnOffSwitchState(numSelected > 0);
        countsLabel.Text = sprintf(['%d faces: %d point out, %d point in, %d cannot tell<br>' ...
            '%d selected; %d flipped (%d by the suggestion)'], numFaces, nnz(flagKnown & currentlyOut()), numSuggested, nnz(~flagKnown), ...
            numSelected, nnz(flipped), nnz(flipped & (outwardSign < 0) & flagKnown));
        updateStatus();
    end

    function updateStatus()
        if ~isvalid(statusLabel)
            return;
        end
        if isUnsaved()
            statusLabel.Text = sprintf('<font color="#b05000">%d faces flipped: not saved</font>', nnz(flipped));
        elseif isempty(flipsFile)
            statusLabel.Text = sprintf('%d faces flipped (no flips file: kept in the window only)', nnz(flipped));
        else
            statusLabel.Text = sprintf('%d faces flipped: saved', nnz(flipped));
        end
    end

    function faces = getFlipped()
        % (nested, not an anonymous function: one would keep the value
        % flipped had when the window was built)
        faces = find(flipped);
    end

    function faces = getSuggested()
        faces = find(suggestedFaces());
    end

    function faces = getSelected()
        faces = find(selected);
    end

    function pickOut = getLastPick()
        pickOut = lastPick;
    end

    function flipsOut = getFaceFlips()
        flipsOut = faceFlips;
    end

    function flag = isUnsaved()
        flag = ~isequal(flipped, savedFlipped);
    end

    function statusOut = getStatus()
        statusOut = struct('NumFlipped', nnz(flipped), 'NumSuggested', nnz(suggestedFaces()), ...
            'NumUnknown', nnz(~flagKnown), 'NumSelected', nnz(selected), 'Unsaved', isUnsaved(), 'UndoSteps', numel(undoStack), ...
            'ColorBy', colorBy, 'Brush', brushName);
    end

    function setHint(textIn)
        if isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    function setMenuWidth(width)
        bodyGrid.ColumnWidth{1} = width;
    end

    %% Flips
    function faces = cleanFaces(faces)
        faces = unique(round(double(faces(:))));
        faces = faces(faces >= 1 & faces <= numFaces);
    end

    function remember(faces, textIn)
        % One Undo step: these faces' states before the change
        undoStack(end+1) = struct('Faces', faces, 'Flipped', flipped(faces), 'Selected', selected(faces), 'Text', textIn);
    end

    function selectFaces(faces, flagOn, textIn)
        % Selects (flagOn) or unselects these faces: one Undo step
        faces = cleanFaces(faces);
        faces = faces(selected(faces) ~= flagOn);
        if isempty(faces)
            return;
        end
        remember(faces, textIn);
        selected(faces) = flagOn;
        showFaces();
    end

    function selectSuggested()
        faces = find(suggestedFaces());
        selectFaces(faces, true, 'select the suggested faces');
        setHint(sprintf('%d suggested face(s) selected (yellow). Look them over, unselect any that are wrong (Ctrl+Shift), then Apply.', numel(faces)));
    end

    function clearSelection()
        % Esc: unselects every selected face; one Undo puts them back
        if strokeOpen
            closeStroke();
        end
        faces = find(selected);
        if isempty(faces)
            return;
        end
        selectFaces(faces, false, 'unselect all');
        setHint(sprintf('%d selected face(s) unselected (Esc). Undo puts them back.', numel(faces)));
    end

    function applySelection()
        % Apply: the selected faces are flipped, and the selection cleared
        faces = find(selected);
        if isempty(faces)
            setHint('Nothing is selected: select faces first (Ctrl+click, Ctrl+double-click, Ctrl+drag), then Apply.');
            return;
        end
        remember(faces, 'apply');
        flipped(faces) = ~flipped(faces);
        selected(faces) = false;
        showFaces();
        setHint(sprintf('%d face(s) flipped. Check the colors; Undo takes it back; Save when done.', numel(faces)));
    end

    function flipFaces(faces, flagRemember)
        % Turns these faces around (each once) without selecting them
        % (scripts and tests); remembered for Undo
        faces = cleanFaces(faces);
        if isempty(faces)
            return;
        end
        if flagRemember
            remember(faces, 'flip');
        end
        flipped(faces) = ~flipped(faces);
        showFaces();
    end

    function flipSuggested()
        % (scripts and tests: select the suggested faces, then Apply)
        selectSuggested();
        applySelection();
    end

    function revertToStart(flagAsk)
        % Back to the flips as they were when the window opened (and
        % nothing selected): one Undo step. The file changes on Save.
        faces = find(flipped ~= startFlipped | selected);
        if isempty(faces)
            setHint('Nothing to revert: the flips are as they were when the window opened.');
            return;
        end
        if flagAsk && strcmp(figureHandle.Visible, 'on')
            choice = uiconfirm(figureHandle, sprintf(['Go back to the flips as they were when this window opened? ' ...
                '%d face(s) change. Undo takes it back; the file changes only when you Save.'], numel(faces)), ...
                'Revert to start', 'Options', {'Revert', 'Cancel'}, 'DefaultOption', 2, 'CancelOption', 2);
            if ~strcmp(choice, 'Revert')
                return;
            end
        end
        remember(faces, 'revert to start');
        flipped = startFlipped;
        selected(:) = false;
        showFaces();
        setHint(sprintf('Reverted to the start (%d face(s) changed). Save to write it to the file; Undo takes it back.', numel(faces)));
    end

    function undoFlip()
        if strokeOpen
            closeStroke();
        end
        if isempty(undoStack)
            setHint('Nothing to undo.');
            return;
        end
        entry = undoStack(end);
        undoStack(end) = [];
        flipped(entry.Faces) = entry.Flipped;
        selected(entry.Faces) = entry.Selected;
        showFaces();
        if isUnsaved()
            setHint(sprintf('Undone: %s. Not saved: Save writes the window''s flips to the file.', entry.Text));
        else
            setHint(sprintf('Undone: %s.', entry.Text));
        end
    end

    function faces = regionOf(face)
        % The connected faces of the same label and the same color as face
        status = ones(numFaces,1);           % (cannot tell)
        flagOut = currentlyOut();
        status(flagKnown & flagOut) = 2;
        status(flagKnown & ~flagOut) = 3;
        pieces = pick.MeshPieces(baseMesh.Faces, labelCode*4 + status);
        faces = find(pieces == pieces(face));
    end

    function saveFlips()
        % The flips, by face position and the way each face now points, to
        % the flips file (if any): the faces flipped here, and those saved
        % before (fcn_CarMesh3D_applyFaceFlips replays them)
        savedFaces = union(storedFaces, find(flipped));
        faces = currentFaces();
        faceFlips = struct('Points', centers(savedFaces,:), ...
            'Normals', fcn_INTERNAL_normals(baseMesh.Vertices, faces(savedFaces,:)), 'NumFaces', numFaces, 'Who', whoName, ...
            'SavedOn', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
        if ~isempty(flipsFile)
            save(flipsFile, 'faceFlips');
        end
        savedFlipped = flipped;
        updateStatus();
    end

    function meshOut = getFixedMesh()
        meshOut = baseMesh;
        meshOut.Faces = currentFaces();
        if isfield(meshOut, 'FaceNormals') && size(meshOut.FaceNormals,1) == numFaces
            meshOut.FaceNormals(flipped,:) = -meshOut.FaceNormals(flipped,:);
        end
    end

    %% Settings
    function setColorBy(value)
        colorBy = char(value);
        if isvalid(colorGroup)
            fcn_INTERNAL_selectRadio(colorGroup, colorBy);
        end
        showFaces();
    end

    function setBrush(value)
        brushName = char(value);
        if isvalid(brushGroup)
            fcn_INTERNAL_selectRadio(brushGroup, brushName);
        end
    end

    function setSize(width, height)
        figureHandle.Position(3:4) = [width height];
        drawnow;
    end

    %% The mouse
    function ray = mouseRay()
        ray = pick.RayAtPixel(modelAxes, figureHandle.CurrentPoint, meshSize);
    end

    function modifiers = mouseModifiers()
        if ~isempty(mouseInjected)
            modifiers = mouseInjected.Modifier;
        else
            modifiers = figureHandle.CurrentModifier;
        end
    end

    function faces = facesUnderMouse(flagSingle)
        brushPixels = brushSizes(strcmp({brushSizes.Name}, brushName)).Pixels;
        faces = pick.FacesOnRay(baseMesh.Vertices, baseMesh.Faces, (1:numFaces)', mouseRay(), modelAxes, brushPixels, flagSingle);
    end

    function onDown()
        % CAD-style, as the painter: left-drag rotates, right-drag pans;
        % selecting only with Ctrl (Ctrl+click one face, Ctrl+drag the
        % brush, Ctrl+double-click a region; Ctrl+Shift unselects). Any
        % click over the model's axes counts: before T96 a click counted
        % only where the figure's CurrentObject was in the axes
        mouseMode = '';
        point = figureHandle.CurrentPoint;
        box = getpixelposition(modelAxes, true);
        if point(1) < box(1) || point(2) < box(2) || point(1) > box(1) + box(3) || point(2) > box(2) + box(4)
            return;
        end
        modifiers = mouseModifiers();
        mouseErase = any(strcmp(modifiers, 'shift'));
        if any(strcmp(modifiers, 'control')) && strcmp(figureHandle.SelectionType, 'open')
            mouseMode = 'region';
        elseif any(strcmp(modifiers, 'control'))
            mouseMode = 'ctrl';
        elseif strcmp(figureHandle.SelectionType, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseStart = figureHandle.CurrentPoint;
        mouseLast = mouseStart;
        mouseMoved = false;
    end

    function onMove()
        if isempty(mouseMode)
            return;
        end
        point = figureHandle.CurrentPoint;
        if ~mouseMoved && norm(point - mouseStart) < 4
            return;   % (a click, so far)
        end
        mouseMoved = true;
        if strcmp(mouseMode, 'region')
            return;
        end
        if strcmp(mouseMode, 'ctrl')
            mouseMode = 'stroke';
            strokeOpen = true;
            strokeFaces = zeros(0,1);
            strokeEntry = struct('Faces', zeros(0,1), 'Flipped', false(0,1), 'Selected', false(0,1), 'Text', 'a brush stroke');
            strokeErase = mouseErase;
            strokeLastPixel = mouseStart;
        end
        if strcmp(mouseMode, 'stroke')
            strokeAlong();
            drawnow limitrate;
            return;
        end
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(modelAxes, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
            moveLight();
        else
            camdolly(modelAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function moveLight()
        % (the light follows the camera, T96: the far side was dark)
        if ~isempty(lightHandle) && isvalid(lightHandle)
            camlight(lightHandle, 'headlight');
        end
    end

    function strokeAlong()
        % The faces under the line from the last point to this one, each
        % selected (or unselected, with Shift) once in the stroke
        pixelNow = figureHandle.CurrentPoint;
        brushPixels = brushSizes(strcmp({brushSizes.Name}, brushName)).Pixels;
        numSteps = min(200, max(1, ceil(norm(pixelNow - strokeLastPixel)/max(1, min(4, brushPixels)))));
        faces = zeros(0,1);
        for ith_step = 1:numSteps
            fraction = ith_step/numSteps;
            stepRay = pick.RayAtPixel(modelAxes, (1 - fraction)*strokeLastPixel + fraction*pixelNow, meshSize);
            faces = [faces; reshape(pick.FacesOnRay(baseMesh.Vertices, baseMesh.Faces, (1:numFaces)', stepRay, ...
                modelAxes, brushPixels, false), [], 1)]; %#ok<AGROW>
        end
        strokeLastPixel = pixelNow;
        newFaces = setdiff(unique(faces), strokeFaces);
        if ~isempty(newFaces)
            strokeFaces = [strokeFaces; newFaces];
            newFaces = newFaces(selected(newFaces) == strokeErase);
            if ~isempty(newFaces)
                strokeEntry.Faces = [strokeEntry.Faces; newFaces];
                strokeEntry.Flipped = [strokeEntry.Flipped; flipped(newFaces)];
                strokeEntry.Selected = [strokeEntry.Selected; selected(newFaces)];
                selected(newFaces) = ~strokeErase;
                showFaces();
            end
        end
    end

    function closeStroke()
        % (one Undo step for the whole stroke)
        if ~isempty(strokeEntry) && ~isempty(strokeEntry.Faces)
            undoStack(end+1) = strokeEntry;
        end
        strokeEntry = [];
        strokeOpen = false;
        strokeFaces = zeros(0,1);
    end

    function notePick(face)
        % What a click picked, in the hint line (T96: some faces could not
        % be picked; this says what the click found)
        if isempty(face)
            lastPick = struct('Face', [], 'Behind', 0, 'Text', 'The click missed the model.');
            setHint(lastPick.Text);
            return;
        end
        ray = mouseRay();
        direction = (ray(2,:) - ray(1,:))/norm(ray(2,:) - ray(1,:));
        hits = pick.RayHits(ray(1,:), direction, baseMesh.Vertices, baseMesh.Faces);
        numBehind = nnz(hits > hits(face) & hits <= hits(face) + 0.01);
        colorNames = {'gray (cannot tell)', 'green (points out)', 'red (points in)'};
        flagOut = currentlyOut();
        status = 1 + double(flagKnown(face))*(1 + double(~flagOut(face)));
        lastPick = struct('Face', face, 'Behind', numBehind, 'Text', sprintf('Picked face %d: %s, label %d; %d other face(s) within 1 cm behind it.', ...
            face, colorNames{status}, labelCode(face), numBehind));
        setHint(lastPick.Text);
    end

    function onUp()
        if strcmp(mouseMode, 'stroke')
            closeStroke();
        elseif ~mouseMoved && strcmp(mouseMode, 'ctrl')
            face = facesUnderMouse(true);
            notePick(face);
            selectFaces(face, ~mouseErase, 'a click');
        elseif strcmp(mouseMode, 'region')
            face = facesUnderMouse(true);
            notePick(face);
            if ~isempty(face)
                % (the first click of the double-click picked one face:
                % the region's step replaces it)
                region = regionOf(face);
                selectFaces(region, ~mouseErase, 'a region');
                actionText = 'selected';
                if mouseErase
                    actionText = 'unselected';
                end
                setHint(sprintf('%s Region: %d face(s) %s.', lastPick.Text, numel(region), actionText));
            end
        end
        mouseMode = '';
    end

    function onScroll(~, event)
        camzoom(modelAxes, 1.15^(-event.VerticalScrollCount));
    end

    function onKey(~, event)
        if strcmp(event.Key, 'escape') && isempty(event.Modifier)
            clearSelection();
            return;
        end
        if any(strcmp(event.Modifier, 'control'))
            if strcmpi(event.Key, 'z')
                undoFlip();
            elseif strcmpi(event.Key, 's')
                saveFlips();
            end
        end
    end

    %% Hooks: the window's own mouse handlers, with the mouse put over a
    %% face or a point of the model (as in the painter)
    function injectMouse(target, modifiers)
        point = targetPoint(target);
        pixel = pick.PixelOf(modelAxes, point);
        mouseInjected = struct('Modifier', {cellstr(modifiers)});
        figureHandle.CurrentPoint = pixel;
    end

    function point = targetPoint(target)
        if isscalar(target) && target == round(target) && target >= 1 && target <= numFaces
            point = centers(target,:);
        else
            point = reshape(double(target), 1, 3);
        end
    end

    function clickAt(target, modifiers)
        if nargin < 2
            modifiers = {};
        end
        injectMouse(target, modifiers);
        figureHandle.SelectionType = 'normal';
        onDown();
        onUp();
        mouseInjected = [];
    end

    function doubleClickAt(target, modifiers)
        % (as a real double-click: a click, then a second one that MATLAB
        % reports as 'open')
        if nargin < 2
            modifiers = {};
        end
        clickAt(target, modifiers);
        injectMouse(target, modifiers);
        figureHandle.SelectionType = 'open';
        onDown();
        onUp();
        figureHandle.SelectionType = 'normal';
        mouseInjected = [];
    end

    function dragAt(targets, modifiers)
        if nargin < 2
            modifiers = {};
        end
        if isvector(targets) && numel(targets) ~= 3
            targets = targets(:);
        end
        injectMouse(targets(1,:), modifiers);
        figureHandle.SelectionType = 'normal';
        onDown();
        mouseStart = mouseStart - [10 10];   % (so the first move counts as a drag)
        for ith_target = 1:size(targets,1)
            injectMouse(targets(ith_target,:), modifiers);
            onMove();
        end
        onUp();
        mouseInjected = [];
    end

    function face = faceAt(target)
        pointBefore = figureHandle.CurrentPoint;
        injectMouse(target, {});
        face = facesUnderMouse(true);
        mouseInjected = [];
        figureHandle.CurrentPoint = pointBefore;
    end

    function closeWindow()
        if ~isvalid(figureHandle)
            return;
        end
        if isUnsaved() && ~isempty(flipsFile) && strcmp(figureHandle.Visible, 'on')
            choice = uiconfirm(figureHandle, 'The face flips have changes that are not saved. Save them?', ...
                'Face flips', 'Options', {'Save', 'Discard', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 3);
            if strcmp(choice, 'Cancel')
                return;
            end
            if strcmp(choice, 'Save')
                saveFlips();
            end
        end
        fixedMesh = getFixedMesh();
        delete(figureHandle);
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

%% fcn_INTERNAL_emptyFlips
function faceFlips = fcn_INTERNAL_emptyFlips(numFaces)
faceFlips = struct('Points', zeros(0,3), 'Normals', zeros(0,3), 'NumFaces', numFaces, 'Who', '', 'SavedOn', '');
end % Ends fcn_INTERNAL_emptyFlips

%% fcn_INTERNAL_normals
function normals = fcn_INTERNAL_normals(vertices, faces)
% (unit normals of the faces, from their corner order)
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
normals = normals./max(vecnorm(normals,2,2), eps);
end % Ends fcn_INTERNAL_normals

%% fcn_INTERNAL_radioRow
function group = fcn_INTERNAL_radioRow(parent, texts, values, callback, tag, tooltip)
% A row of radio buttons (rule G9), one per value; callback(value) on a pick
group = uibuttongroup(parent, 'BorderType', 'none', 'Tag', tag, 'Tooltip', tooltip, ...
    'SelectionChangedFcn', @(source, ~) callback(source.SelectedObject.UserData));
width = 90;
for ith_value = 1:numel(values)
    uiradiobutton(group, 'Text', texts{ith_value}, 'UserData', values{ith_value}, ...
        'Position', [4 + (ith_value-1)*width, 2, width - 4, 20], 'Tag', sprintf('%s_%s', tag, values{ith_value}), ...
        'Tooltip', tooltip);
end
end % Ends fcn_INTERNAL_radioRow

%% fcn_INTERNAL_selectRadio
function fcn_INTERNAL_selectRadio(group, value)
buttons = group.Children;
for ith_button = 1:numel(buttons)
    if isequal(buttons(ith_button).UserData, value)
        group.SelectedObject = buttons(ith_button);
    end
end
end % Ends fcn_INTERNAL_selectRadio

%% fcn_INTERNAL_modifiers
function modifiers = fcn_INTERNAL_modifiers(extraInputs)
modifiers = {};
if ~isempty(extraInputs)
    modifiers = extraInputs{1};
end
end % Ends fcn_INTERNAL_modifiers
