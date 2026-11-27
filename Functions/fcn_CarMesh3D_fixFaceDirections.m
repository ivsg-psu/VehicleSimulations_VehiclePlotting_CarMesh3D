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
% The suggested flips can be made all at once, and any face can be
% flipped by hand:
%       Ctrl+click          flip the region under the mouse (the connected
%                           faces of the same label and the same color)
%       Ctrl+Shift+click    flip only the face under the mouse
%       Ctrl+drag           flip the faces under the brush (each once)
%       left-drag rotates, right-drag pans, the wheel zooms
% Undo (Ctrl+Z) takes back the last flip; Save (Ctrl+S) writes the flips
% to the vehicle's faceFlips file, by face position, for its build to
% replay (step 1F).
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
%      flipped faces' centers), NumFaces (the mesh's faces), Who, SavedOn.
%
%      window: a structure of functions for scripts and tests (rule G32):
%           Figure, Axes, Patch; State, SetState, Press, Key, CheckLayout
%           (fcn_CarMesh3D_guiDriver); ClickAt(target, modifiers),
%           DragAt(targets, modifiers), FaceAt(target) (target: a face
%           number or a 3D point); Flip(faces), FlipSuggested(), Undo(),
%           Save(); Flipped(), Suggested(), Status(), FixedMesh(),
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
undoStack = {};          % (each entry: the faces one action flipped)
strokeOpen = false;
strokeFaces = zeros(0,1);
colorBy = 'direction';
brushSizes = struct('Name', {'Fine', 'Medium', 'Large'}, 'Pixels', {5, 14, 36});
brushName = 'Medium';
mouseInjected = [];
mouseMode = '';
mouseStart = [0 0];
mouseLast = [0 0];
mouseMoved = false;
strokeLastPixel = [];
whoName = 'SBB';
try
    if ispref('CarMesh3D', 'Initials')
        whoName = char(getpref('CarMesh3D', 'Initials'));
    end
catch
end
faceFlips = fcn_INTERNAL_emptyFlips(numFaces);
if ~isempty(flipsFile) && isfile(flipsFile)
    loaded = load(flipsFile, 'faceFlips');
    if isfield(loaded, 'faceFlips') && isfield(loaded.faceFlips, 'Points') && ~isempty(loaded.faceFlips.Points)
        [nearestFace, nearestDistance] = pick.Nearest(centers, loaded.faceFlips.Points);
        flipped(nearestFace(nearestDistance < 1e-4)) = true;
        savedFlipped = flipped;
        faceFlips = loaded.faceFlips;
    end
end

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
topGrid = uigridlayout(rootGrid, [1 4], 'ColumnWidth', {90, 80, 80, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'facesMenu', ...
    'Tooltip', 'Open a panel at the left (pick an open one again to close it)');
uibutton(topGrid, 'Text', 'Undo', 'ButtonPushedFcn', @(~,~) undoFlip(), 'Tag', 'facesUndo', ...
    'Tooltip', 'Take back the last flip (a click, a stroke, or the suggested flips); press again to go further back. Ctrl+Z.');
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
modelPatch = patch(modelAxes, 'Vertices', baseMesh.Vertices, 'Faces', baseMesh.Faces, 'FaceColor', 'flat', ...
    'FaceVertexCData', labelColors, 'EdgeColor', 'none', 'FaceLighting', 'flat', 'Tag', 'facesModel');
suggestedPatch = patch(modelAxes, 'Vertices', zeros(0,3), 'Faces', zeros(0,3), 'FaceColor', 'none', ...
    'EdgeColor', [0.55 0 0], 'LineWidth', 0.75, 'HitTest', 'off', 'Clipping', 'off', 'Tag', 'facesSuggested');
view(modelAxes, -35, 20);
camlight(modelAxes, 'headlight');
lighting(modelAxes, 'flat');

% The Face Directions panel
panelGrid = uigridlayout(facesPanel, [8 1], 'RowHeight', {170, 22, 26, 22, 26, 34, 60, '1x'}, 'Padding', [8 8 8 8], ...
    'RowSpacing', 4, 'Scrollable', 'on', 'BackgroundColor', yellowBand);
uilabel(panelGrid, 'Interpreter', 'html', 'WordWrap', 'on', 'Tag', 'facesLegend', 'Text', ...
    ['<b>Colors</b> (seen from outside):<br>' ...
    '<font color="#1f9e3a">&#9632;</font> points out<br>' ...
    '<font color="#d42020">&#9632;</font> points in: a suggested flip (outlined)<br>' ...
    '<font color="#8c8c8c">&#9632;</font> cannot tell from the shape (inside the body, or open on both sides): kept as it is<br>' ...
    '<i>The suggestions are hints, from one line out of each face: a face in a narrow gap can be suggested wrongly. Look before flipping them all.</i>']);
uilabel(panelGrid, 'Text', 'Color the model by?', 'FontWeight', 'bold');
colorGroup = fcn_INTERNAL_radioRow(panelGrid, {'Direction', 'Labels'}, {'direction', 'labels'}, @(value) setColorBy(value), ...
    'facesColorBy', 'Direction: green out, red in, gray cannot tell. Labels: the mesh''s own colors.');
uilabel(panelGrid, 'Text', 'Brush size (Ctrl+drag)?', 'FontWeight', 'bold');
brushGroup = fcn_INTERNAL_radioRow(panelGrid, {brushSizes.Name}, {brushSizes.Name}, @(value) setBrush(value), ...
    'facesBrush', 'How much a Ctrl+drag flips: a circle this size on the screen, at any zoom.');
suggestButton = uibutton(panelGrid, 'Text', 'Flip the suggested faces', 'ButtonPushedFcn', @(~,~) flipSuggested(), ...
    'Tag', 'facesFlipSuggested', 'Tooltip', 'Flip every red face (seen from outside pointing in) at once; Undo takes it back.');
countsLabel = uilabel(panelGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'Tag', 'facesCounts');
uilabel(panelGrid, 'Interpreter', 'html', 'WordWrap', 'on', 'VerticalAlignment', 'top', 'Text', ...
    ['<b>Flipping by hand</b><br>Ctrl+click: the region under the mouse (same label, same color)<br>' ...
    'Ctrl+Shift+click: one face<br>Ctrl+drag: the faces under the brush<br>' ...
    'Left-drag rotates, right-drag pans, the wheel zooms.']);
fcn_INTERNAL_selectRadio(colorGroup, colorBy);
fcn_INTERNAL_selectRadio(brushGroup, brushName);
panelMenu.OpenPanels({'Face Directions'});

set(figureHandle, 'WindowButtonDownFcn', @(~,~) onDown(), 'WindowButtonMotionFcn', @(~,~) onMove(), ...
    'WindowButtonUpFcn', @(~,~) onUp(), 'WindowScrollWheelFcn', @onScroll, 'WindowKeyPressFcn', @onKey, ...
    'CloseRequestFcn', @(~,~) closeWindow());
showFaces();
setHint('Red faces point into the vehicle as seen from outside. Flip them all (Face Directions panel), or Ctrl+click a region to flip it. Save when done.');

window = struct('Figure', figureHandle, 'Axes', modelAxes, 'Patch', modelPatch, 'FlipsFile', flipsFile, ...
    'State', @() fcn_CarMesh3D_guiDriver(figureHandle, 'state'), ...
    'SetState', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'set', varargin{:}), ...
    'Press', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'press', varargin{:}), ...
    'Key', @(key, varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'key', key, 'Modifier', fcn_INTERNAL_modifiers(varargin)), ...
    'CheckLayout', @() fcn_CarMesh3D_guiDriver(figureHandle, 'checkLayout'), ...
    'ClickAt', @clickAt, 'DragAt', @dragAt, 'FaceAt', @faceAt, ...
    'Flip', @(faces) flipFaces(faces, true), 'FlipSuggested', @flipSuggested, 'Undo', @undoFlip, 'Save', @saveFlips, ...
    'Flipped', @getFlipped, 'Suggested', @getSuggested, 'Status', @getStatus, ...
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
        suggestButton.Text = sprintf('Flip the suggested faces (%d)', numSuggested);
        suggestButton.Enable = matlab.lang.OnOffSwitchState(numSuggested > 0);
        countsLabel.Text = sprintf(['%d faces: %d point out, %d point in, %d cannot tell<br>' ...
            '%d flipped (%d by the suggestion)'], numFaces, nnz(flagKnown & currentlyOut()), numSuggested, nnz(~flagKnown), ...
            nnz(flipped), nnz(flipped & (outwardSign < 0) & flagKnown));
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

    function flipsOut = getFaceFlips()
        flipsOut = faceFlips;
    end

    function flag = isUnsaved()
        flag = ~isequal(flipped, savedFlipped);
    end

    function statusOut = getStatus()
        statusOut = struct('NumFlipped', nnz(flipped), 'NumSuggested', nnz(suggestedFaces()), ...
            'NumUnknown', nnz(~flagKnown), 'Unsaved', isUnsaved(), 'UndoSteps', numel(undoStack), ...
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
    function flipFaces(faces, flagRemember)
        % Turns these faces around (each once); remembered for Undo
        faces = unique(faces(:));
        faces = faces(faces >= 1 & faces <= numFaces);
        if isempty(faces)
            return;
        end
        flipped(faces) = ~flipped(faces);
        if flagRemember
            undoStack{end+1} = faces;
        end
        showFaces();
    end

    function flipSuggested()
        flipFaces(find(suggestedFaces()), true); %#ok<FNDSB>
    end

    function undoFlip()
        if isempty(undoStack)
            return;
        end
        faces = undoStack{end};
        undoStack(end) = [];
        flipped(faces) = ~flipped(faces);
        showFaces();
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
        % The flips, by face position, to the flips file (if any)
        points = centers(flipped,:);
        faceFlips = struct('Points', points, 'NumFaces', numFaces, 'Who', whoName, ...
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
        mouseMode = '';
        clicked = figureHandle.CurrentObject;
        if isempty(clicked) || ~isvalid(clicked) || ~isequal(ancestor(clicked, 'axes'), modelAxes)
            return;
        end
        modifiers = mouseModifiers();
        if any(strcmp(modifiers, 'control'))
            mouseMode = 'ctrl';
            if any(strcmp(modifiers, 'shift'))
                mouseMode = 'ctrlShift';
            end
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
        if any(strcmp(mouseMode, {'ctrl', 'ctrlShift'}))
            mouseMode = 'stroke';
            strokeOpen = true;
            strokeFaces = zeros(0,1);
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
        else
            camdolly(modelAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function strokeAlong()
        % The faces under the line from the last point to this one, each
        % flipped once in the stroke
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
            flipped(newFaces) = ~flipped(newFaces);
            showFaces();
        end
    end

    function onUp()
        if strcmp(mouseMode, 'stroke')
            if ~isempty(strokeFaces)
                undoStack{end+1} = strokeFaces;
            end
            strokeOpen = false;
            strokeFaces = zeros(0,1);
        elseif ~mouseMoved && strcmp(mouseMode, 'ctrl')
            face = facesUnderMouse(true);
            if ~isempty(face)
                flipFaces(regionOf(face), true);
            end
        elseif ~mouseMoved && strcmp(mouseMode, 'ctrlShift')
            flipFaces(facesUnderMouse(true), true);
        end
        mouseMode = '';
    end

    function onScroll(~, event)
        camzoom(modelAxes, 1.15^(-event.VerticalScrollCount));
    end

    function onKey(~, event)
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
        figureHandle.CurrentObject = modelPatch;
        onDown();
        onUp();
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
        figureHandle.CurrentObject = modelPatch;
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
faceFlips = struct('Points', zeros(0,3), 'NumFaces', numFaces, 'Who', '', 'SavedOn', '');
end % Ends fcn_INTERNAL_emptyFlips

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
