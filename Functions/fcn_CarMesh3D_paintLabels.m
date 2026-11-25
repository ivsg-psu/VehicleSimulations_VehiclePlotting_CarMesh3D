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
%      Versions: true to keep a timestamped copy of the edits and the
%      edited mesh at each save, in the VersionFolder, as
%      <mesh name>_YYYYMMDDHHMMSS.mat (a second save in the same
%      second overwrites the first); false not to. Default []: Shared GUI
%      settings' "Timestamped copy at each save?" (On unless changed).
%      "Save as version" always keeps a copy.
%
%      VersionFolder: where the timestamped copies go. Default: the folder
%      last chosen ("Folder for timestamped copies" in Shared GUI settings, kept as the
%      MATLAB preference CarMesh3D/VersionFolder); else the project's
%      scratch folder, Project_CarMesh3D\scratch\meshVersions (for now);
%      else a folder "versions" beside the edits file.
%
%      Who: who is painting, for the vehicle's change log
%      (meshHistory_<ID>.csv; fcn_CarMesh3D_meshHistory): each save adds a
%      row. Default: your initials in Shared GUI settings (SBB unless
%      changed). (With a vehicle ID only.)
%
%      Menu: a host window's ☰ Menu (the functions fcn_CarMesh3D_makePanelMenu
%      returns). When given, the painter puts its panels (Overall Display,
%      Labels To Display, Lamps To Display, Modify Labels) in the host's
%      menu and has no ☰ Menu of its own: only the top window owns the
%      menu (Q45 (A), Sean 2026-11-24 16:25). The host takes them away
%      again when it closes the painter (Parts().PanelNames). Default [].
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
%           (for automated tests, 2026-11-24; its own window)
%           State(), SetState(stateOrTag, value), Press(tagOrText),
%               Key(key, modifiers), CheckLayout(): the window driven by
%               fcn_CarMesh3D_guiDriver (controls named by their Tags)
%           MouseDownAt(target, modifiers, selectionType),
%               MouseMoveAt(target), MouseUpAt(target): the window's OWN
%               mouse handlers run with the mouse over target (a face
%               number, or a 3D point on the model; NaN for off the
%               model); modifiers such as {'control'} or
%               {'control','shift'}; selectionType 'normal', 'open'
%               (double-click) or 'alt'
%           ClickAt(target), DoubleClickAt(target), DragAt(targets,
%               modifiers): a click, a double-click, a drag over several
%               targets (rows), made of the three above
%           FaceAt(target): the face a click there would pick ([] if none)
%           Layers(): the paint layers (Paint, Applied, Saved, Working: a
%               label per face, "" for none) and the faces drawn as pending
%               and as applied paint
%           ToggleMenu(), MenuOpen(): the menu's list of panels
%           OpenPanel(name), Panel(), OpenNames(), OpenPanels(names): the
%               panels, as the ☰ Menu opens them (up to two at once, top
%               first)
%           Menu(), Settings(): the ☰ Menu's functions
%               (fcn_CarMesh3D_makePanelMenu; the host's, when given) and
%               Shared GUI settings' (fcn_CarMesh3D_makeSettingsPanel; []
%               inside a host)
%           MarkPanels(): its panels showing the state now (for a host
%               whose ☰ Menu opened one of them)
%           Parts(): the painter's own parts (TopBar, MenuList, Panels,
%               PanelNames), for tests of its controls
%           SetSize(width, height): the window's size, in pixels
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

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Overall Display, Labels To Display and Lamps To Display built by
%   %   % fcn_CarMesh3D_makeDisplayPanels, the same code as the viewer's
%   %   % own window (Q33 (A), Sean 02:41); the labels now in groups (main
%   %   % body panels, objects within interior, lights, visibility) and
%   %   % every lamp type
%   % * Settings: "Show ground?" (Sean, 02:43): the ground plane under the
%   %   % vehicle, by day and at night, on by default; shared with the
%   %   % viewer
%   % * Fixed: a second double-click on a part painted by double-click
%   %   % now unpaints it (the single click before it is taken back
%   %   % first; Sean, 02:24 and 02:49)
%   % * Esc unselects every face selected and not applied, as one Undo
%   %   % step (Sean, 02:26); hook ClearPending
%   % * Fixed: paint applied but not saved now goes into the working mesh
%   %   % and the viewer's, as saved paint does, so an applied lamp (a tail
%   %   % light painted) lights with the lamps (Sean, 02:47)
%   % * Sean's viewLabels review (2026-11-24 03:43): Show ground? moved
%   %   % from Settings to Overall Display; the photo options there too
%   %   % (PhotoOptions false); the camera's angles in Overall Display
%   %   % (the viewer's OnView); the ground in 1 m squares (the viewer's)
%   % * A label whose part the mesh does not have (interior, since the
%   %   % voxel interior labeling was switched off, Q37, 2026-11-24 05:06)
%   %   % has no faces, instead of an error

% 2026_11_24 (Agent B: script-driven tests) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Every control a user clicks or reads has a Tag, and the window can
%   %   % be driven by script (Sean, 05:03: "hooks ... the GUI must go to
%   %   % that state"): new hooks State, SetState, Press, Key, CheckLayout
%   %   % (fcn_CarMesh3D_guiDriver), and mouse hooks MouseDownAt,
%   %   % MouseMoveAt, MouseUpAt, ClickAt, DoubleClickAt, DragAt, FaceAt
%   %   % that run the window's OWN mouse handlers with the mouse put over
%   %   % a given face or point; Layers, ToggleMenu, MenuOpen, SetSize
%   %   % * Saved label fixes the painter cannot draw (made by a script,
%   %   % with Material, Color, AlsoLightTypes, ...: the Fit's 13 lamp
%   %   % fixes) are kept exactly as they are when it saves; before, a save
%   %   % rewrote them as plain paint by position, which lost their Material
%   %   % (a lamp's inner layer), colors and second lamp types
%   %   % * "Revert to save" in the top bar (asks first)
%   %   % * A second click on ANOTHER piece soon after a click is a click
%   %   % there, not a double-click (it painted the whole piece)
%   %   % * Closing the window while it is still being built no longer
%   %   % errors (it closes once built)
%   %   % * Fixed: clicks, double-clicks and Ctrl+drags picked faces far
%   %   % from the mouse, or none (Sean's T2: "only sometimes", "only the
%   %   % first face", "glass does nothing", "nothing after Apply"): the
%   %   % UIAxes' CurrentPoint is shifted in this window; the line under
%   %   % the mouse is now worked out from the window's CurrentPoint and
%   %   % the camera (fcn_INTERNAL_rayAtPixel), checked against 221 real
%   %   % clicks
%   %   % * Ctrl+drag: each move paints the faces between the last point
%   %   % and this one, so a fast drag leaves no gaps
%   %   % * Fixed: the status line said "saved" while paint was pending
%   %   % * Fixed: Ctrl+Shift+drag over a stroke painted through a window
%   %   % did not erase it (erasing stopped at the glass)

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * "Revert to a save..." (T36, Sean 15:14: it only went back to the
%   %   % last save): a list of the saves to go back to, the last save and
%   %   % each timestamped copy (newest first); a copy comes back as applied
%   %   % paint, not saved. Hooks SavedCopies, RevertToCopy, PickRevert
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_paintLabels
%   % * Selection is a highlighter, apart from labels (T35, Sean 15:19 to
%   %   % 15:24): clicks, Ctrl+drag and double-clicks select faces whatever
%   %   % their labels (Ctrl+Shift+drag unselects); the label picked is only
%   %   % previewed on them; Apply puts it on and clears the selection (Save
%   %   % applies first); Undo takes back a selection step, or an Apply
%   %   % (with the selection steps that led to it).
%   %   % Before, a selected face took the label at once, so Ctrl+drag over
%   %   % faces that already had it did nothing
%   % * New label "original" (Q44 (A)): back to the label as downloaded
%   % * The shared panels (the shared-panels design file; Sean, 16:09 to
%   %   % 16:25): the ☰ Menu is the shared one (fcn_CarMesh3D_makePanelMenu),
%   %   % up to two panels open at once, Labels To Display over Modify
%   %   % Labels at first; the panels open are remembered (preference
%   %   % PainterPanels); Settings is now Shared GUI settings
%   %   % (fcn_CarMesh3D_makeSettingsPanel: You, View, Demo vehicle and
%   %   % Editing used, Review greyed), with "Timestamped copy at each
%   %   % save?" and its folder; Save as version, Revert to start and the
%   %   % edits file moved to the foot of Modify Labels; Who defaults to your
%   %   % initials (SBB); Menu=, a host's menu, so a host such as the
%   %   % reviewer holds the painter's panels (Q45 (A))
%
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
    options.Versions = []       % Keep a timestamped copy at each save; [] for Shared GUI settings' choice (default true)
    options.VersionFolder = []  % Where timestamped copies go; [] for the remembered folder, else the default
    options.Who = ''            % Who is painting (for the change log); '' for your initials in Shared GUI settings
    options.Menu = []           % A host window's ☰ Menu (fcn_CarMesh3D_makePanelMenu); [] for a menu of its own
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
% (saved label fixes the painter cannot draw as paint, such as a script's
% fixes with a Material, Color or AlsoLightTypes (the Fit's lamp fixes),
% are kept exactly as they are: they are applied to the mesh first, and
% saved again, unchanged, in front of the paint. Before 2026-11-24 a save
% rewrote them as plain paint by position, which lost those fields.)
keptEdits = {};
if ~isempty(editsFile) && isfile(editsFile)
    keptEdits = fcn_INTERNAL_keptEdits(editsFile);
    if ~isempty(keptEdits)
        keptMesh = fcn_CarMesh3D_editLabels(baseMesh, Edits=keptEdits, FigNum=-1);
        if size(keptMesh.Faces,1) == size(baseMesh.Faces,1)
            baseMesh = keptMesh;
        else
            warning('CarMesh3D:paintLabels', 'The saved fixes changed the number of faces: they are kept, but not shown.');
        end
    end
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
% (workingTarget: the paint taken into the working mesh, data.Mesh, and
% the viewer's: the saved paint, and since 2026-11-24 the applied paint
% too, so applied lamps light like any other: Sean, 02:47)
workingTarget = strings(numFaces,1);
% (the click just before a double-click: taken back by it, 2026-11-24)
lastClickTime = [];
lastClickUndo = 0;
% (the selection: a highlighter on the faces, apart from their labels;
% the label picked is only previewed on it, and Apply puts it on: Sean,
% 2026-11-24 15:19 to 15:24, T35 and Q44 (A). paintTarget is the applied
% paint with the preview on the selected faces)
selectedFaces = false(numFaces,1);
% (Undo: 'select' entries (Before: the faces' selection before) and
% 'apply' entries (Before: their labels before; Applied true))
undoStack = struct('Faces', {}, 'Before', {}, 'Applied', {}, 'BeforeSelected', {});
strokeOpen = false;
strokeErase = false;
strokeFaces = zeros(0,1);
strokeBefore = false(0,1);
paintTool = '';
mirrorFace = [];
meshPieces = [];
% (the model, the photos and their dial, and the list of labels: the
% viewer, fcn_CarMesh3D_viewLabels, built in; the painter colors its
% paint through the viewer's ColorFilter and HiddenFaces)
labelViewer = [];
% (the mouse, in its own window; mouseInjected: a test's mouse, the line
% under it and the keys held, in place of the real mouse's; [] for the
% real mouse)
mouseInjected = [];
strokeLastPixel = [];   % (where the mouse was at the stroke's last point, in pixels)
lastClickFace = [];   % (the face of the last single click, for double-clicks)
flagBuilding = true;  % (the window is being built: a close waits until it is)
flagCloseAsked = false;
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
hostMenu = options.Menu;
flagOwnMenu = isempty(hostMenu);
% (the panels: in its own menu, with Shared GUI settings; or in the host
% window's menu, which has its own Shared GUI settings: Q45 (A))
panelNames = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Modify Labels', 'Shared GUI settings'};
blueBand = [0.93 0.95 1];     % (viewing work)
yellowBand = [1 0.96 0.85];   % (paint work)
grayBand = [0.94 0.94 0.94];  % (settings)
panelColors = {blueBand, blueBand, blueBand, yellowBand, grayBand};
if ~flagOwnMenu
    panelNames = panelNames(1:4);
    panelColors = panelColors(1:4);
end
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

% The top bar: the menu (when it has its own), then only Undo, Save, and
% Exit; the status
menuWidth = 90;
if ~flagOwnMenu
    menuWidth = 0;
end
topGrid = uigridlayout(mainGrid, [1 6], 'ColumnWidth', {menuWidth, 80, 80, 120, 80, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'painterMenu', ...
    'Tooltip', 'Open a panel at the left (up to two at once; pick an open one again to close it)');
if ~flagOwnMenu
    menuButton.Visible = 'off';   % (the host window's ☰ Menu holds the panels)
end
uibutton(topGrid, 'Text', 'Undo', 'ButtonPushedFcn', @(~,~) undoEdit(), 'Tag', 'painterUndo', ...
    'Tooltip', 'Take back the last selection step (click or stroke) or the last Apply (press again to go further back, newest first). Ctrl+Z.');
uibutton(topGrid, 'Text', 'Save', 'ButtonPushedFcn', @(~,~) saveEdits(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], 'Tag', 'painterSave', ...
    'Tooltip', ['Save the applied labels (the vehicle''s labelEdits file, used by its script); faces still selected take the label picked first. ' ...
    'The saved mesh becomes the working mesh: relabeled faces take their new label''s look. Ctrl+S.']);
% (Revert to prior save, in the top bar: agreed in section 9 of the design
% file, P2; it asks first)
uibutton(topGrid, 'Text', 'Revert to a save...', 'ButtonPushedFcn', @(~,~) askRevert('save'), 'Tag', 'painterRevert', ...
    'Tooltip', 'Go back to an earlier save: pick the last save or one of the timestamped copies from a list (paint since then is taken off)');
exitButton = uibutton(topGrid, 'Text', 'Exit', 'ButtonPushedFcn', @(~,~) closePainter(), 'Tag', 'painterExit', ...
    'Tooltip', 'Close the painter (it asks first when there are changes not saved)');
if ~flagOwnWindow
    exitButton.Visible = 'off';   % (the host window closes it)
end
editStatusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11, 'Tag', 'painterStatus');

% The body: the left column (the ☰ Menu's list, then up to two open
% panels: the shared menu, fcn_CarMesh3D_makePanelMenu), and the viewer
% (the model, the photo dial, the photo and its options)
bodyGrid = uigridlayout(mainGrid, [1 2], 'ColumnWidth', {320, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
menuColumn.Layout.Row = 1;
menuColumn.Layout.Column = 1;
if flagOwnMenu
    panelMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
        OnChange=@(names) onPanelsChanged(names), FigNum=-1);
    menuParts = panelMenu.Parts();
    menuParts.List.Tag = 'painterMenuList';   % (its name in the painter's tests)
else
    panelMenu = hostMenu;
    bodyGrid.ColumnWidth{1} = 0;   % (the host's column holds the panels)
end
panelHandles = gobjects(1, numel(panelNames));
for ith_panel = 1:numel(panelNames)
    panelHandles(ith_panel) = panelMenu.AddPanel(panelNames{ith_panel}, panelColors{ith_panel});
end
sharedSettings = [];   % (Shared GUI settings, fcn_CarMesh3D_makeSettingsPanel: in its own menu only)
flagVersions = options.Versions;   % (a timestamped copy at each save)
if isempty(flagVersions)
    flagVersions = true;
    if ispref('CarMesh3D', 'VersionsAtSave')
        flagVersions = logical(getpref('CarMesh3D', 'VersionsAtSave'));
    end
end
flagVersions = logical(flagVersions);
whoName = char(options.Who);
if isempty(whoName)
    whoName = 'SBB';   % (your initials, Shared GUI settings; SBB by default: Sean, 2026-11-24 11:20)
    if ispref('CarMesh3D', 'Initials')
        whoName = char(getpref('CarMesh3D', 'Initials'));
    end
end
viewerHolder = uipanel(bodyGrid, 'BorderType', 'none');
viewerHolder.Layout.Row = 1;
viewerHolder.Layout.Column = 2;
hintLabel = uilabel(mainGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35], 'Tag', 'painterHint');
hintLabel.Layout.Row = 3;
% (the panels' controls, made once the viewer is built)
paintGroup = [];
mirrorGroup = [];
showHiddenGroup = [];
hideNameField = [];
saveVersionButton = [];
displayPanels = [];   % (Overall Display, Labels To Display, Lamps To Display: fcn_CarMesh3D_makeDisplayPanels, shared with the viewer's own window; Q33 (A))
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
    HiddenFaces=@hiddenFaces, History=meshHistory, PhotoOptions=false, OnLamps=@markLamps, OnView=@markCamera, FigNum=-1);
% (the photo options are in Overall Display now: Sean's viewLabels T8, 2026-11-24)
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
        'WindowKeyPressFcn', @onOwnKey, 'CloseRequestFcn', @(~,~) askCloseWhileBuilding());
    labelPatch.ButtonDownFcn = [];
end

% The panels (Sean, 10:24): built once the viewer is, since they list
% its labels and lamps; the one open last time opens again
displayPanels = fcn_CarMesh3D_makeDisplayPanels(labelViewer, ...
    Overall=panelHandles(strcmp(panelNames, 'Overall Display')), Labels=panelHandles(strcmp(panelNames, 'Labels To Display')), ...
    Lamps=panelHandles(strcmp(panelNames, 'Lamps To Display')), Band=blueBand, ...
    LabelColor=@(name) fcn_INTERNAL_paintColor(data, name), OnChange=@showPaint, ...
    ShowHidden=@showHiddenOn, SetShowHidden=@setShowHidden, FigNum=-1);
buildModifyPanel();
if flagOwnMenu
    % (Shared GUI settings: the painter uses You, View, Demo vehicle and
    % Editing; Review is greyed, rule G26)
    sharedSettings = fcn_CarMesh3D_makeSettingsPanel(panelHandles(strcmp(panelNames, 'Shared GUI settings')), ...
        Used={'You', 'View', 'Demo vehicle', 'Editing'}, OnChange=@onSharedSetting, FigNum=-1);
end
% (the panels open last time open again: Labels To Display over Modify
% Labels the first time, viewing and labeling together, told apart by
% color (the shared-panels design file, section 3))
startPanels = {'Labels To Display', 'Modify Labels'};
try
    if ispref('CarMesh3D', 'PainterPanels')
        remembered = cellstr(getpref('CarMesh3D', 'PainterPanels'));
        if numel(remembered) <= 2 && all(ismember(remembered, panelNames))
            startPanels = remembered;
        end
    end
catch
end
if ~flagOwnWindow
    % (inside another window, such as the Model Reviewer, the space is
    % narrow: the panels start closed, so the model shows; the menu opens
    % them)
    startPanels = {};
end
if flagOwnMenu
    panelMenu.OpenPanels(startPanels);
end
drawnow;
labelViewer.PlacePhoto();   % (the photo filling its box, now the layout is settled)

% Saved edits
loadEdits();
showPaint();
setHint(['Mouse: left-drag rotates, right-drag pans, the wheel zooms. To relabel: select faces (Ctrl+drag, or click), pick a label in Modify Labels (' char(9776) ' Menu), then Apply. ' ...
    'Photos: drag the red arrow around the vehicle (or click on the dial).']);

painter = struct('Figure', figureHandle, 'Axes', labelAxes, 'Patch', labelPatch, 'EditsFile', editsFile, ...
    'State', @() fcn_CarMesh3D_guiDriver(figureHandle, 'state'), 'SetState', @driverSet, ...
    'Press', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'press', varargin{:}), 'Key', @driverKey, ...
    'CheckLayout', @() fcn_CarMesh3D_guiDriver(figureHandle, 'checkLayout'), ...
    'MouseDownAt', @mouseDownAt, 'MouseMoveAt', @mouseMoveAt, 'MouseUpAt', @mouseUpAt, ...
    'ClickAt', @clickAt, 'DoubleClickAt', @doubleClickAt, 'DragAt', @dragAt, 'FaceAt', @faceAt, ...
    'Layers', @getLayers, 'ToggleMenu', @toggleMenu, 'MenuOpen', @menuOpen, 'SetSize', @setSize, ...
    'Parts', @getParts, 'Menu', @() panelMenu, 'Settings', @() sharedSettings, 'MarkPanels', @() onPanelsChanged(panelMenu.OpenNames()), ...
    'ShowLabel', @showLabel, 'SetHidden', @setHidden, ...
    'EditedMesh', @getEditedMesh, 'Edits', @getEdits, 'NumPainted', @numPainted, 'IsUnsaved', @isUnsaved, 'Status', @getStatus, ...
    'Apply', @applyEdits, 'Undo', @undoEdit, 'Save', @() saveEdits(), 'SaveVersion', @saveVersion, ...
    'LastVersionFile', @getLastVersionFile, 'VersionFolder', @getVersionFolder, 'SetVersionFolder', @setVersionFolder, 'WorkingMesh', @getWorkingMesh, 'RevertToSaved', @revertToSaved, 'RevertToStart', @revertToStart, 'SavedCopies', @listSavedCopies, 'RevertToCopy', @revertToCopy, 'PickRevert', @pickRevert, ...
    'SetTool', @setTool, 'Paint', @testPaint, 'SetPhotoAngle', labelViewer.SetPhotoAngle, 'PhotoAngle', labelViewer.PhotoAngle, 'Viewer', labelViewer, ...
    'StrokeStart', @strokeStart, 'MouseMove', @mouseMove, 'MouseUp', @mouseUp, 'Click', @click, ...
    'OpenPanel', @pickPanel, 'Panel', @getOpenPanel, 'OpenNames', @getOpenNames, 'OpenPanels', @openPanels, ...
    'SetMirror', @setMirror, 'Mirror', @mirrorOn, ...
    'SetVersions', @setVersions, 'Versions', @versionsOn, 'SetShowHidden', @setShowHidden, 'ShowHidden', @showHiddenOn, ...
    'ClearPending', @clearPending, 'Stop', @stopTimer, 'Close', @closePainter);
flagBuilding = false;
if flagOwnWindow && isvalid(figureHandle)
    figureHandle.UserData = painter;
    figureHandle.CloseRequestFcn = @(~,~) closePainter();
    if flagCloseAsked
        closePainter();   % (closed while it was being built)
    end
end

if flagOwnWindow && options.Wait && options.Visible && isvalid(figureHandle)
    uiwait(figureHandle);
    if ~isvalid(figureHandle)
        return;   % (closePainter set the outputs as the window closed)
    end
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
        pending = find(selectedFaces & flagShown);   % (the selection, outlined)
        applied = find(appliedTarget ~= workingTarget & paintTarget == appliedTarget & flagShown);   % (in the working mesh: drawn as it)
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
        flagChanged = paintTarget ~= workingTarget;
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
        changed = appliedTarget ~= workingTarget;   % (paint in the working mesh is in its labels)
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
        changed = paintTarget ~= workingTarget;
        baseGlass = find(strcmp(data.BaseMesh.PartNames, 'glass'), 1);
        flagBaseGlass = false(numFaces,1);
        if ~isempty(baseGlass)
            flagBaseGlass = data.BaseMesh.FacePartIndex(:) == baseGlass;
        end
        flagGlass(changed) = paintTarget(changed) == "glass" | (strlength(paintTarget(changed)) == 0 & flagBaseGlass(changed));
    end

    %% The menu and the panels (the shared menu, fcn_CarMesh3D_makePanelMenu)
    function setMenuWidth(width)
        % (the ☰ Menu's column: its width when something is shown in it,
        % none when nothing is)
        if ~isempty(bodyGrid) && isvalid(bodyGrid)
            bodyGrid.ColumnWidth{1} = width;
        end
    end

    function onPanelsChanged(names)
        % (the open panels changed: remembered for next time, in its own
        % window; they show the state now)
        if flagOwnWindow && ~flagBuilding
            try
                setpref('CarMesh3D', 'PainterPanels', names);
            catch
            end
        end
        if ~isempty(displayPanels)
            displayPanels.MarkAll();
        end
        markPaintButtons();
    end

    function toggleMenu()
        panelMenu.ToggleList();
    end

    function flagOpen = menuOpen()
        flagOpen = panelMenu.ListShown();
    end

    function pickPanel(name)
        % Open this panel, under the one open (a third one replaces the
        % lower one); an open panel picked again closes; '' closes every
        % panel of the painter
        name = char(name);
        if isempty(name)
            for ith_name = 1:numel(panelNames)
                panelMenu.Close(panelNames{ith_name});
            end
            return;
        end
        panelMenu.Open(name);
        if ~flagOwnMenu
            onPanelsChanged(panelMenu.OpenNames());
        end
    end

    function openPanels(names)
        % (exactly these panels open, top first: at most two)
        panelMenu.OpenPanels(names);
        if ~flagOwnMenu
            onPanelsChanged(panelMenu.OpenNames());
        end
    end

    function name = getOpenPanel()
        % (the top open panel's name; '' when none is open)
        name = '';
        names = getOpenNames();
        if ~isempty(names)
            name = names{1};
        end
    end

    function names = getOpenNames()
        names = panelMenu.OpenNames();
    end

    function parts = getParts()
        menuPartsNow = panelMenu.Parts();
        parts = struct('TopBar', topGrid, 'MenuList', menuPartsNow.List, 'Panels', panelHandles, 'PanelNames', {panelNames});
    end

    function onSharedSetting(name, value)
        % (a change in Shared GUI settings: this window follows it at once;
        % other windows at their next open, Q46 (A))
        switch name
            case 'VersionsAtSave'
                flagVersions = logical(value);
            case 'VersionFolder'
                % (Shared GUI settings keeps the preference; '' for the default)
                versionFolder = strtrim(char(value));
                if isempty(versionFolder)
                    versionFolder = fcn_INTERNAL_versionFolder([], editsFile, true);
                end
            case 'Initials'
                whoName = char(value);
            case {'StartViewDial', 'StartViewDown'}
                startNow = labelViewer.StartView();
                if strcmp(name, 'StartViewDial')
                    startNow(1) = value;
                else
                    startNow(2) = value;
                end
                labelViewer.SetStartView(startNow(1), startNow(2));
        end
    end

    %% The display panels (fcn_CarMesh3D_makeDisplayPanels): their marks
    function markLabels()
        if ~isempty(displayPanels)
            displayPanels.MarkLabels();
        end
    end

    function markLamps(states)
        % (the viewer calls this with the lamp states, as its OnLamps)
        if ~isempty(displayPanels)
            displayPanels.MarkLamps(states);
        end
    end

    function buildModifyPanel()
        % Modify Labels: the label to paint (one at a time, or none), the
        % hidden set's name, mirror and show-hidden switches, Apply, and
        % how to paint
        panelHandle = panelHandles(strcmp(panelNames, 'Modify Labels'));
        groups = {'Main labeling:', {'body', 'glass', 'trim', 'interior', 'wheel', 'original'}; ...
            'Bulb labeling:', {'headlight', 'highbeam', 'tail', 'running', 'turnsignal', 'backup', ...
                'fog', 'reflector', 'licenseplate', 'marker', 'warning'}; ...   % (the last five: Sean, task 8)
            'Visibility labeling:', {'hide', 'unhide', ''}};
        rowHeight = 24;
        numRows = 1 + sum(cellfun(@(names) numel(names) + 1, groups(:,2)));
        groupHeight = numRows*rowHeight + 8;
        outer = uigridlayout(panelHandle, [10 1], 'RowHeight', {groupHeight, 22, 24, 24, 30, 100, 22, 28, 28, 'fit'}, 'Padding', [8 8 8 8], ...
            'RowSpacing', 6, 'BackgroundColor', yellowBand, 'Scrollable', 'on');
        paintGroup = uibuttongroup(outer, 'BorderType', 'none', 'BackgroundColor', yellowBand, 'Tag', 'paintAs', ...
            'SelectionChangedFcn', @(~,event) pickTool(event.NewValue.UserData));
        y = groupHeight - rowHeight;
        uilabel(paintGroup, 'Text', 'Label for the selection   (pick one)', 'FontWeight', 'bold', 'Position', [2 y 260 22]);
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
                    hideNameField = uieditfield(paintGroup, 'text', 'Value', 'hidden', 'Position', [206 y 80 22], 'Tag', 'hideAs', ...
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
        uibutton(outer, 'Text', 'Apply', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) applyEdits(), 'Tag', 'paintApply', ...
            'Tooltip', 'Put the label picked on the selected faces, in the working mesh (hidden faces go out of view and reach)');
        uilabel(outer, 'Text', ['How to label: select faces (Ctrl+drag; Ctrl+Shift+drag unselects; a click selects one face, ' ...
            'click again to unselect; a double-click a whole piece), pick a label, then Apply (or Save). The selection (yellow edges) ' ...
            'shows the label picked, but the faces keep their own until Apply. "original" puts back the label as downloaded. ' ...
            'Hiding takes faces out of view, never out of the mesh. To reach faces under others, set their label to ' ...
            'Shown? No (Labels To Display).'], 'WordWrap', 'on', 'FontSize', 11, 'FontColor', [0.45 0.3 0], 'Tag', 'paintHowTo', ...
            'VerticalAlignment', 'top');
        % (saving: a timestamped copy now, going back to the start, and the
        % edits file; moved here from the painter's old Settings panel, now
        % Shared GUI settings: the shared-panels design file, section 4)
        heading = uilabel(outer, 'Text', 'Saving', 'FontWeight', 'bold', 'FontColor', [0.45 0.3 0]);
        heading.Layout.Row = 7;
        saveVersionButton = uibutton(outer, 'Text', 'Save as version', 'ButtonPushedFcn', @(~,~) saveVersion(), 'Tag', 'saveVersion', ...
            'Tooltip', ['Save, and also keep a timestamped copy (<mesh name>_YYYYMMDDHHMMSS.mat: the edits and the edited mesh, ' ...
            'in the folder set in Shared GUI settings)']);
        uibutton(outer, 'Text', 'Revert to start', 'ButtonPushedFcn', @(~,~) askRevert('start'), 'Tag', 'revertToStart', ...
            'Tooltip', 'Go back to the mesh before any edits (Save to make it stick)');
        editsText = editsFile;
        if isempty(editsText)
            editsText = '(none: the mesh was given as a variable, so the edits are returned, not saved)';
            saveVersionButton.Enable = 'off';
        end
        uilabel(outer, 'Text', ['Edits file: ' editsText], 'WordWrap', 'on', 'FontSize', 11, 'FontColor', [0.3 0.3 0.3], ...
            'VerticalAlignment', 'top', 'Tag', 'editsFileText', 'Tooltip', editsText);
        markPaintButtons();
    end

    function pickTool(name)
        paintTool = char(name);
        refreshPreview();
        if isempty(paintTool)
            setHint('No label picked: the selected faces keep their labels; pick one, then Apply.');
        else
            setHint(sprintf('Label <b>%s</b>: shown on the selected faces; Apply puts it on them. Ctrl+drag selects, Ctrl+Shift+drag unselects, a click selects one face, a double-click a piece.', ...
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

    function markCamera()
        % (the viewer's camera moved: the readout in Overall Display;
        % Show ground? is there too now, Sean's viewLabels T3, 2026-11-24)
        if ~isempty(displayPanels)
            displayPanels.MarkCamera();
        end
    end

    function flagOn = versionsOn()
        flagOn = flagVersions && ~isempty(editsFile);
    end

    function setVersions(flagOn)
        flagVersions = logical(flagOn);   % (this window only; Shared GUI settings keeps the choice for next time)
    end

    function askRevert(which)
        % (asks first, when on screen: a revert takes paint off)
        if strcmp(figureHandle.Visible, 'on')
            if strcmp(which, 'save')
                pickRevert();   % (the list of saves to go back to: T36)
                return;
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
        % Ctrl+Z undoes, Ctrl+S saves (as the buttons at the top); Esc
        % unselects every face selected and not applied
        if strcmp(event.Key, 'escape') && isempty(event.Modifier)
            clearPending();
            return;
        end
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
        refreshPreview();
    end

    function refreshPreview()
        % The preview: the applied paint, with the label picked drawn on
        % the selected faces (they do not take it until Apply)
        paintTarget = appliedTarget;
        if ~isempty(paintTool) && any(selectedFaces)
            paintTarget(selectedFaces) = previewValue();
        end
        showPaint();
    end

    function value = previewValue()
        % What Apply puts on the selected faces: the label picked;
        % "original" takes the paint off (the label as downloaded)
        value = paintValue();
        if strcmp(paintTool, 'original')
            value = "";
        end
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
        % Selects these faces (and their mirror images), or unselects them
        % (flagErase), whatever their labels; remembered for Undo
        faces = faces(:);
        if isempty(faces)
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
            strokeBefore = [strokeBefore; selectedFaces(newFaces)];
        else
            undoStack(end+1) = struct('Faces', faces, 'Before', strings(0,1), 'Applied', false, 'BeforeSelected', selectedFaces(faces));
        end
        selectedFaces(faces) = ~flagErase;
        refreshPreview();
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
        ray = mouseRay();   % (2 x 3: the front and back of the line under the mouse)
        faces = facesOnRay(ray, flagSingle, flagErase);
    end

    function faces = facesOnRay(ray, flagSingle, flagErase, candidates)
        % (the faces facesUnderMouse finds, for a given line; candidates:
        % the faces that can be picked, if already known)
        faces = [];
        direction = ray(2,:) - ray(1,:);
        direction = direction/norm(direction);
        if nargin < 4
            candidates = pickableFaces(flagErase);
        end
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

    function candidates = pickableFaces(flagErase)
        % The faces the mouse can pick: not hidden; not glass unless the
        % glass tool is in use (or the glass has paint to erase)
        eligible = ~hiddenFaces();
        if ~strcmp(paintTool, 'glass')
            if flagErase
                % (erasing: glass with paint on it can be erased; glass
                % with none is seen through, as when painting, so a
                % Ctrl+Shift+drag over a stroke painted through a window
                % erases it; found by the script tests, 2026-11-24)
                eligible = eligible & (~currentlyGlass() | selectedFaces);   % (unselecting: selected glass can be unselected)
            else
                eligible = eligible & ~currentlyGlass();
            end
        end
        candidates = find(eligible);
    end

    function strokeStart(flagErase)
        % A Ctrl+drag stroke begins (one Undo entry for the whole stroke)
        strokeOpen = true;
        strokeErase = logical(flagErase);
        strokeFaces = zeros(0,1);
        strokeBefore = false(0,1);
        strokeLastPixel = figureHandle.CurrentPoint;
        paintFaces(facesUnderMouse(false, strokeErase), strokeErase);
    end

    function paintAlongStroke()
        % A move during a stroke: the faces under the line from the last
        % point to this one are painted, not only those under this point
        % (the mouse jumps several faces between two moves when the drag is
        % fast or the window is busy)
        pixelNow = figureHandle.CurrentPoint;
        faces = zeros(0,1);
        numSteps = 1;
        candidates = pickableFaces(strokeErase);
        if ~isempty(strokeLastPixel)
            numSteps = min(60, max(1, ceil(norm(pixelNow - strokeLastPixel)/4)));   % (a point every 4 pixels)
        end
        for ith_step = 1:numSteps
            if isempty(strokeLastPixel)
                stepPixel = pixelNow;
            else
                fraction = ith_step/numSteps;
                stepPixel = (1 - fraction)*strokeLastPixel + fraction*pixelNow;
            end
            stepRay = fcn_INTERNAL_rayAtPixel(labelAxes, stepPixel, data.Geometry);
            faces = [faces; reshape(facesOnRay(stepRay, false, strokeErase, candidates), [], 1)]; %#ok<AGROW>
        end
        strokeLastPixel = pixelNow;
        paintFaces(unique(faces), strokeErase);
    end

    function closeStroke()
        % A stroke is finished: its faces become one Undo entry
        if strokeOpen && ~isempty(strokeFaces)
            undoStack(end+1) = struct('Faces', strokeFaces, 'Before', strings(0,1), 'Applied', false, 'BeforeSelected', strokeBefore);
            notifyPaint();
        end
        strokeOpen = false;
        strokeFaces = zeros(0,1);
        strokeBefore = false(0,1);
        updateStatus();
    end

    function click(flagPiece)
        % A click (no drag) on the model: paints the face under it with the
        % tool (a double-click, the whole piece); a click on faces already
        % painted with this tool takes the paint off
        face = facesUnderMouse(true, false);
        if isempty(face)
            return;
        end
        if flagPiece && ~fcn_INTERNAL_samePiece(face, lastClickFace, lastClickTime)
            % (a second click soon after a click on ANOTHER piece: the
            % system calls it a double-click, but it is a click on a new
            % spot; before, it painted the whole piece, which made single
            % clicks seem unreliable)
            flagPiece = false;
        end
        if flagPiece && ~isempty(lastClickTime) && toc(lastClickTime) < 1 && lastClickUndo > 0 && lastClickUndo == numel(undoStack)
            % (a double-click comes after a single click on the same spot:
            % that click is taken back first, so the double-click acts on
            % the part as it was; else a second double-click took the one
            % face's paint off, then painted the whole part again: Sean,
            % 2026-11-24 02:24 and 02:49)
            clickEntry = undoStack(end);
            undoStack(end) = [];
            selectedFaces(clickEntry.Faces) = clickEntry.BeforeSelected;
        end
        lastClickTime = [];
        if flagPiece
            if isempty(meshPieces)
                meshPieces = fcn_INTERNAL_meshPieces(data.Mesh);
            end
            face = find(meshPieces == meshPieces(face));
        end
        flagAlreadySelected = all(selectedFaces(face));
        paintFaces(face, flagAlreadySelected);   % (a click on selected faces unselects them)
        if ~flagPiece
            lastClickTime = tic;
            lastClickUndo = numel(undoStack);
            lastClickFace = face;
        end
        notifyPaint();
    end

    function flagSame = fcn_INTERNAL_samePiece(face, otherFace, clickTime)
        % (a double-click: the click before it was less than a second ago,
        % on the same piece)
        flagSame = false;
        if isempty(otherFace) || isempty(clickTime) || toc(clickTime) > 1 || otherFace > numFaces
            return;
        end
        if isempty(meshPieces)
            meshPieces = fcn_INTERNAL_meshPieces(data.Mesh);
        end
        flagSame = meshPieces(face) == meshPieces(otherFace);
    end

    function clearPending()
        % Esc: every face selected and not applied (pending paint) is
        % unselected; one Undo puts them back (Sean, 2026-11-24 02:26)
        if strokeOpen
            closeStroke();
        end
        faces = find(selectedFaces);
        if isempty(faces)
            return;
        end
        undoStack(end+1) = struct('Faces', faces, 'Before', strings(0,1), 'Applied', false, 'BeforeSelected', true(numel(faces),1));
        selectedFaces(faces) = false;
        lastClickTime = [];
        refreshPreview();
        setHint(sprintf('%d selected face(s) unselected (Esc). Undo puts them back.', numel(faces)));
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
        % The label picked goes on the selected faces, in the temporary
        % modified mesh, and the selection is cleared (hidden faces go out
        % of view, and out of reach); one Undo entry
        if strokeOpen
            closeStroke();
        end
        faces = find(selectedFaces);
        if isempty(faces)
            setHint('Nothing selected: Ctrl+drag, or click, to select faces, then Apply.');
            return;
        end
        if isempty(paintTool)
            setHint('<b>Pick a label first</b> (Modify Labels, in the menu at the top left): Apply puts it on the selected faces.');
            return;
        end
        % (the selection steps that led here become this one Undo step)
        if ~isempty(undoStack)
            undoStack(~[undoStack.Applied]) = [];
        end
        undoStack(end+1) = struct('Faces', faces, 'Before', appliedTarget(faces), 'Applied', true, 'BeforeSelected', true(numel(faces),1));
        appliedTarget(faces) = previewValue();
        selectedFaces(:) = false;
        absorbTarget(appliedTarget);   % (applied paint in the working mesh: a lamp painted lights with the lamps)
        refreshPreview();
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
        if lastEntry.Applied
            % (an Apply taken back, with the selection that led to it: the
            % labels before it)
            appliedTarget(lastEntry.Faces) = lastEntry.Before;
            absorbTarget(appliedTarget);
        else
            selectedFaces(lastEntry.Faces) = lastEntry.BeforeSelected;
        end
        refreshPreview();
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
        if any(selectedFaces) && ~isempty(paintTool)
            applyEdits();   % (the selected faces take the label picked first)
        end
        labelEditsAfterSimplify = getEdits();   % (the kept fixes, then the paint)
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
                meshHistory = fcn_CarMesh3D_meshHistory(historyID, Action='label edits saved', Who=whoName, ...
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
        setpref('CarMesh3D', 'VersionFolder', versionFolder);
        if ~isempty(sharedSettings)
            sharedSettings.Mark();   % (Shared GUI settings shows it)
        end
        setHint(sprintf('Timestamped copies now go in %s', versionFolder));
    end

    function folderOut = getVersionFolder()
        folderOut = versionFolder;
    end

    function absorbSaved()
        % (the saved paint into the working mesh)
        absorbTarget(savedTarget);
    end

    function absorbTarget(target)
        % The saved edits taken into the working mesh: each face's label
        % and label color are the edited mesh's (hidden faces keep their
        % place, hidden). Same faces as the base, so the paint layers and
        % Undo carry on.
        workingTarget = target;
        data.Mesh = data.BaseMesh;
        data.LabelColors = data.BaseLabelColors;
        data.LabelAlpha = data.BaseLabelAlpha;
        meshPieces = [];
        edits = fcn_INTERNAL_paintEdits(data.BaseMesh, target);
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
            displayPanels.RebuildLabels();   % (labels with faces now, or none)
        end
    end

    function revertToSaved()
        % Back to the last save
        selectedFaces(:) = false;
        paintTarget = savedTarget;
        appliedTarget = savedTarget;
        undoStack(:) = [];
        absorbTarget(savedTarget);
        showPaint();
        notifyChange();
    end

    function revertToStart()
        % Back to the mesh before any edits (Save to make it stick)
        selectedFaces(:) = false;
        paintTarget = strings(numFaces,1);
        appliedTarget = paintTarget;
        undoStack(:) = [];
        absorbTarget(appliedTarget);
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
        paintTarget = targetFromEdits(loaded.labelEditsAfterSimplify, paintTarget);
        appliedTarget = paintTarget;   % (what was saved is applied, and saved)
        savedTarget = paintTarget;
        absorbSaved();   % (and taken into the working mesh)
    end

    function targetOut = targetFromEdits(editsIn, targetOut)
        % The paint a list of saved edits puts on the faces (each paint
        % edit's points matched to the nearest face centers; kept fixes are
        % already in the base mesh)
        centers = baseCenters;
        for ith_edit = 1:numel(editsIn)
            thisEdit = editsIn{ith_edit};
            if ~fcn_INTERNAL_isPaintEdit(thisEdit)
                continue;   % (a kept fix: already in the base mesh)
            end
            target = fcn_INTERNAL_editTarget(thisEdit);
            [nearestFace, nearestDistance] = fcn_INTERNAL_nearest(centers, thisEdit.Points);
            targetOut(nearestFace(nearestDistance <= 0.005)) = string(target);
        end
    end

    function copies = listSavedCopies()
        % The timestamped copies of this mesh's saves, newest first: a
        % table of File (full name) and Saved (the time in its name)
        copies = table(cell(0,1), NaT(0,1), 'VariableNames', {'File', 'Saved'});
        if isempty(versionName) || ~isfolder(versionFolder)
            return;
        end
        listing = dir(fullfile(versionFolder, [versionName '_*.mat']));
        for ith_file = 1:numel(listing)
            stamp = regexp(listing(ith_file).name, ['^' regexptranslate('escape', versionName) '_(\d{14})\.mat$'], 'tokens', 'once');
            if ~isempty(stamp)
                copies(end+1, :) = {{fullfile(listing(ith_file).folder, listing(ith_file).name)}, ...
                    datetime(stamp{1}, 'InputFormat', 'yyyyMMddHHmmss')}; %#ok<AGROW>
            end
        end
        copies = sortrows(copies, 'Saved', 'descend');
    end

    function revertToCopy(copyFile)
        % Back to one of the timestamped copies: its paint becomes the
        % applied paint, not yet saved (Save to make it stick)
        loaded = load(copyFile, 'labelEditsAfterSimplify');
        if ~isfield(loaded, 'labelEditsAfterSimplify')
            setHint(sprintf('<font color="#b03000"><b>Not reverted:</b> %s holds no label edits.</font>', copyFile));
            return;
        end
        target = targetFromEdits(loaded.labelEditsAfterSimplify, strings(numFaces,1));
        selectedFaces(:) = false;
        paintTarget = target;
        appliedTarget = target;
        undoStack(:) = [];
        absorbTarget(appliedTarget);
        showPaint();
        notifyChange();
        [~, fileName, extension] = fileparts(copyFile);
        setHint(sprintf('Reverted to the copy saved as %s%s. <b>Not saved yet:</b> Save to make it the vehicle''s edits.', fileName, extension));
    end

    function pickRevert()
        % "Revert to a save...": a list of the saves to go back to (the
        % last save, then each timestamped copy, newest first), as Sean
        % expected (2026-11-24 15:14, T36): pick one, then Revert
        copies = listSavedCopies();
        items = {'The last save (the edits file)'};
        if ~isempty(editsFile) && isfile(editsFile)
            info = dir(editsFile);
            items{1} = sprintf('The last save (the edits file, %s)', char(datetime(info.datenum, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm:ss')));
        end
        for ith_copy = 1:height(copies)
            [~, fileName] = fileparts(copies.File{ith_copy});
            items{end+1} = sprintf('%s   (%s.mat)', char(copies.Saved(ith_copy), 'yyyy-MM-dd HH:mm:ss'), fileName); %#ok<AGROW>
        end
        windowPosition = figureHandle.Position;
        dialogSize = [560 360];
        dialog = uifigure('Name', 'Revert to a save', 'WindowStyle', 'modal', 'Tag', 'revertDialog', ...
            'Position', [windowPosition(1:2) + (windowPosition(3:4) - dialogSize)/2, dialogSize]);
        dialogGrid = uigridlayout(dialog, [4 1], 'RowHeight', {'fit', '1x', 'fit', 30});
        uilabel(dialogGrid, 'Text', {'Go back to which save? Paint since then is taken off.', ...
            sprintf('Timestamped copies are in %s', versionFolder)}, 'WordWrap', 'on');
        list = uilistbox(dialogGrid, 'Items', items, 'ItemsData', 0:height(copies), 'Value', 0, 'Tag', 'revertList');
        uilabel(dialogGrid, 'Text', 'A copy is put back as applied paint, not saved: Save afterward to make it stick.', ...
            'FontColor', [0.35 0.35 0.35], 'WordWrap', 'on');
        buttonGrid = uigridlayout(dialogGrid, [1 3], 'ColumnWidth', {'1x', 100, 100}, 'Padding', [0 0 0 0]);
        uilabel(buttonGrid, 'Text', '');
        uibutton(buttonGrid, 'Text', 'Revert', 'FontWeight', 'bold', 'Tag', 'revertGo', 'ButtonPushedFcn', @(~,~) choose(list.Value));
        uibutton(buttonGrid, 'Text', 'Cancel', 'Tag', 'revertCancel', 'ButtonPushedFcn', @(~,~) delete(dialog));
        list.DoubleClickedFcn = @(~,~) choose(list.Value);
        function choose(index)
            delete(dialog);
            if index == 0
                revertToSaved();
            else
                revertToCopy(copies.File{index});
            end
        end
    end

    %% What the painter gives out
    function meshOut = getEditedMesh()
        % The mesh with the applied edits (the kept fixes are already in
        % the base mesh)
        meshOut = data.BaseMesh;
        edits = fcn_INTERNAL_paintEdits(data.BaseMesh, appliedTarget);
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
        % (the kept fixes, unchanged, then the paint)
        edits = [keptEdits(:)', fcn_INTERNAL_paintEdits(data.BaseMesh, appliedTarget)];
    end

    function count = numPainted()
        count = nnz(strlength(paintTarget) > 0);
    end

    function flag = isUnsaved()
        flag = ~isequal(paintTarget, savedTarget) || ~isequal(appliedTarget, savedTarget);
    end

    function statusOut = getStatus()
        statusOut = struct('Pending', nnz(selectedFaces), 'Applied', nnz(strlength(appliedTarget) > 0), ...
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
        elseif ~isUnsaved()
            % (pending paint is not saved either: before 2026-11-24 the
            % line said "saved" while faces were painted and not applied;
            % found by the random-walk rule "status line matches")
            savedText = '<font color="#2a7a2a">saved</font>';
        else
            savedText = '<font color="#b03000"><b>not saved</b></font>';
        end
        editStatusLabel.Text = sprintf('%d faces selected, not applied  |  %d changed (%d hidden) in the modified mesh  |  %s  |  %d undo steps', ...
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
            paintAlongStroke();
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

    %% The mouse as the handlers read it: the real mouse, or a test's
    function ray = mouseRay()
        % The line under the mouse (2 x 3: its front and back), worked out
        % from where the mouse is in the window (its CurrentPoint, in
        % pixels) and the camera. NOT the axes' own CurrentPoint: in this
        % window (a UIAxes inside panels and grids) that line is shifted,
        % by hundreds of pixels, from where the mouse is, so clicks and
        % strokes picked faces far from the mouse, or none (2026-11-24,
        % found with real mouse clicks: 221 of 221 clicks agree with this
        % line, against 181 of 221 for the axes' CurrentPoint, which put
        % none of its 24 hits where the vehicle was clicked)
        ray = fcn_INTERNAL_rayAtPixel(labelAxes, figureHandle.CurrentPoint, data.Geometry);
    end

    function modifiers = mouseModifiers()
        % The keys held (Ctrl, Shift) as the mouse button went down
        if ~isempty(mouseInjected)
            modifiers = mouseInjected.Modifier;
        else
            modifiers = figureHandle.CurrentModifier;
        end
    end

    %% Hooks for automated tests: the window's own mouse handlers, run
    %% with the mouse put over a face or a point of the model
    function injectMouse(target, modifiers)
        % The mouse over target: the window's pointer (CurrentPoint) put at
        % the pixel where target is drawn, so the handlers work out the
        % line under the mouse just as for the real mouse; and the keys
        % held (the window's CurrentModifier cannot be set)
        point = targetPoint(target);
        if any(isnan(point))
            % (off the model: a corner of the model's box)
            box = getpixelposition(labelAxes, true);
            pixel = box(1:2) + 2;
        else
            pixel = fcn_INTERNAL_pixelOf(labelAxes, point);
        end
        mouseInjected = struct('Modifier', {cellstr(modifiers)});
        figureHandle.CurrentPoint = pixel;
    end

    function point = targetPoint(target)
        % A face number (its center), or a 3D point
        if isscalar(target) && ~isnan(target) && target == round(target) && target >= 1 && target <= numFaces
            corners = data.Mesh.Vertices(data.Mesh.Faces(target,:),:);
            point = mean(corners, 1);
        elseif isscalar(target) && isnan(target)
            point = [NaN NaN NaN];
        else
            point = reshape(double(target), 1, 3);
        end
    end

    function mouseDownAt(target, modifiers, selection)
        % The mouse button pressed over target (see injectMouse)
        if nargin < 2
            modifiers = {};
        end
        if nargin < 3 || isempty(selection)
            selection = 'normal';
            if any(strcmp(cellstr(modifiers), 'control'))
                selection = 'alt';   % (on Windows, MATLAB calls a Ctrl+click 'alt')
            end
        end
        injectMouse(target, modifiers);
        figureHandle.SelectionType = selection;
        if any(isnan(targetPoint(target)))
            figureHandle.CurrentObject = labelAxes;
        else
            figureHandle.CurrentObject = labelPatch;
        end
        onOwnDown(figureHandle, []);
    end

    function mouseMoveAt(target)
        modifiers = {};
        if ~isempty(mouseInjected)
            modifiers = mouseInjected.Modifier;
        end
        injectMouse(target, modifiers);
        MouseMoveOwn();
    end

    function mouseUpAt(target)
        if nargin < 1 || isempty(target)
            target = NaN;
        end
        modifiers = {};
        if ~isempty(mouseInjected)
            modifiers = mouseInjected.Modifier;
        end
        injectMouse(target, modifiers);
        try
            MouseUpOwn();
        catch caughtError
            mouseInjected = [];
            rethrow(caughtError);
        end
        mouseInjected = [];
    end

    function clickAt(target, modifiers)
        if nargin < 2
            modifiers = {};
        end
        mouseDownAt(target, modifiers);
        mouseUpAt(target);
    end

    function doubleClickAt(target)
        % (as the system sends it: a click, then a press called 'open')
        mouseDownAt(target, {}, 'normal');
        mouseUpAt(target);
        mouseDownAt(target, {}, 'open');
        mouseUpAt(target);
    end

    function dragAt(targets, modifiers)
        % A drag from the first target (row) through the others
        if nargin < 2
            modifiers = {};
        end
        if isvector(targets) && numel(targets) ~= 3
            targets = targets(:);
        end
        mouseDownAt(targets(1,:), modifiers);
        for ith_target = 2:size(targets,1)
            mouseMoveAt(targets(ith_target,:));
        end
        mouseUpAt(targets(end,:));
    end

    function face = faceAt(target)
        % The face a click over target would pick (the window unchanged)
        mouseBefore = mouseInjected;
        pointBefore = figureHandle.CurrentPoint;
        injectMouse(target, {});
        face = facesUnderMouse(true, false);
        mouseInjected = mouseBefore;
        figureHandle.CurrentPoint = pointBefore;
    end

    function layers = getLayers()
        % The paint layers, and what is drawn (for tests' checks)
        flagShown = ~hiddenFaces();
        layers = struct('Paint', paintTarget, 'Applied', appliedTarget, 'Saved', savedTarget, 'Working', workingTarget, ...
            'PendingFaces', find(selectedFaces & flagShown), 'Selected', find(selectedFaces), ...
            'AppliedFaces', find(appliedTarget ~= workingTarget & paintTarget == appliedTarget & flagShown), ...
            'PendingDrawn', size(paintEdges.Faces,1), 'AppliedDrawn', size(appliedPatch.Faces,1), ...
            'StatusText', editStatusLabel.Text, 'KeptEdits', numel(keptEdits));
    end

    function setSize(width, height)
        figureHandle.Position(3:4) = [width height];
        drawnow;
    end

    function stateOut = driverSet(varargin)
        stateOut = fcn_CarMesh3D_guiDriver(figureHandle, 'set', varargin{:});
    end

    function stateOut = driverKey(key, modifiers)
        if nargin < 2
            modifiers = {};
        end
        stateOut = fcn_CarMesh3D_guiDriver(figureHandle, 'key', key, 'Modifier', modifiers);
    end

    function askCloseWhileBuilding()
        % (closed while being built: closes once built, else at once)
        if flagBuilding
            flagCloseAsked = true;
        else
            closePainter();
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
        modifiers = mouseModifiers();
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
    'fog', 'reflector', 'licenseplate', 'marker', 'warning', 'hide', 'unhide', 'original'};
% ('original': back to the label as downloaded, Q44 (A), 2026-11-24)
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
    'turnsignal', [1 0.55 0], 'backup', [0.95 0.95 0.95], 'hide', [1 0 1], 'unhide', [0.20 0.75 0.30], 'original', [0.60 0.60 0.60]);
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
if any(strcmp(name, {'hide', 'unhide', 'original'}))
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
    if isempty(partIndex)
        return;   % (a part the mesh does not have, such as interior since Q37: no faces)
    end
    flagFaces = vehicleMesh.FacePartIndex(:)==partIndex;
    % (and the faces that also belong to it: a lamp's clear cover is a
    % light that is also glass)
    if ~isempty(partIndex) && isfield(vehicleMesh,'FaceAlsoParts') ...
            && size(vehicleMesh.FaceAlsoParts,1)==numel(flagFaces) && partIndex <= size(vehicleMesh.FaceAlsoParts,2)
        flagFaces = flagFaces(:) | vehicleMesh.FaceAlsoParts(:,partIndex);
    end
elseif strcmp(labelKey, 'light_none')
    lightPart = find(strcmp(vehicleMesh.PartNames, 'light'), 1);
    if isempty(lightPart)
        return;
    end
    flagFaces = vehicleMesh.FacePartIndex(:)==lightPart & vehicleMesh.FaceLightType(:)==0;
elseif startsWith(labelKey, 'light_')
    typeIndex = find(strcmp(vehicleMesh.LightTypeNames, labelKey(7:end)), 1);
    if isempty(typeIndex)
        return;
    end
    flagFaces = vehicleMesh.FaceLightType(:)==typeIndex;
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
names = setdiff(fcn_INTERNAL_paintNames(), {'hide', 'unhide', 'original'}, 'stable');
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
        textOut = 'Show hidden faces again, on Apply (tick "Show hidden faces" to see them, then select them)';
    case 'original'
        textOut = 'Put back the label each selected face had in the download (the paint taken off), on Apply';
    otherwise
        textOut = sprintf('Label the selected faces %s, on Apply (select them with Ctrl+drag or clicks)', fcn_INTERNAL_paintText(name));
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

%% fcn_INTERNAL_isPaintEdit
function flagPaint = fcn_INTERNAL_isPaintEdit(thisEdit)
% An edit the painter can draw as paint: faces by their centers (Points),
% with only a part, a light type, Hide or Unhide (as the painter saves
% them). Any other field (Material, Color, AlsoLightTypes, Region, ...)
% makes it a fix the painter keeps exactly as it is.
paintFields = {'Name', 'Points', 'PointTolerance', 'Part', 'LightType', 'Hide', 'Unhide'};
flagPaint = isstruct(thisEdit) && isfield(thisEdit, 'Points') && all(ismember(fieldnames(thisEdit), paintFields));
if flagPaint && isfield(thisEdit, 'Part') && isfield(thisEdit, 'LightType') && ~isempty(thisEdit.Part) && ~isempty(thisEdit.LightType)
    flagPaint = false;   % (both a part and a light type: not one paint label)
end
end % Ends fcn_INTERNAL_isPaintEdit

%% fcn_INTERNAL_keptEdits
function keptEdits = fcn_INTERNAL_keptEdits(editsFile)
% The saved fixes the painter cannot draw as paint (kept as they are)
keptEdits = {};
loaded = load(editsFile);
if ~isfield(loaded, 'labelEditsAfterSimplify')
    return;
end
for ith_edit = 1:numel(loaded.labelEditsAfterSimplify)
    thisEdit = loaded.labelEditsAfterSimplify{ith_edit};
    if ~fcn_INTERNAL_isPaintEdit(thisEdit)
        keptEdits{end+1} = thisEdit; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_keptEdits

%% fcn_INTERNAL_pixelOf
function pixel = fcn_INTERNAL_pixelOf(axesHandle, point)
% Where a 3D point is drawn in the window, in pixels (as the window's
% CurrentPoint gives the mouse); for an orthographic camera
box = getpixelposition(axesHandle, true);
viewDirection = axesHandle.CameraTarget - axesHandle.CameraPosition;
distance = norm(viewDirection);
viewDirection = viewDirection/distance;
rightward = cross(viewDirection, axesHandle.CameraUpVector);
rightward = rightward/norm(rightward);
upward = cross(rightward, viewDirection);
halfSpan = distance*tand(axesHandle.CameraViewAngle/2);
pixelsPerMeter = min(box(3), box(4))/(2*max(halfSpan, eps));
offset = point - axesHandle.CameraTarget;
pixel = box(1:2) + box(3:4)/2 + pixelsPerMeter*[dot(offset, rightward), dot(offset, upward)];
end % Ends fcn_INTERNAL_pixelOf

%% fcn_INTERNAL_rayAtPixel
function ray = fcn_INTERNAL_rayAtPixel(axesHandle, pixel, geometry)
% The line under a pixel of the window (as its CurrentPoint gives the
% mouse), through the model's axes: 2 x 3, its front (nearest the camera)
% and back. The camera's view angle spans the shorter side of the axes'
% box (checked against real clicks, 2026-11-24).
box = getpixelposition(axesHandle, true);
viewDirection = axesHandle.CameraTarget - axesHandle.CameraPosition;
distance = norm(viewDirection);
viewDirection = viewDirection/distance;
rightward = cross(viewDirection, axesHandle.CameraUpVector);
rightward = rightward/norm(rightward);
upward = cross(rightward, viewDirection);
halfSpan = distance*tand(axesHandle.CameraViewAngle/2);
pixelsPerMeter = min(box(3), box(4))/(2*max(halfSpan, eps));
offset = (pixel(:)' - (box(1:2) + box(3:4)/2))/pixelsPerMeter;
pointOnTarget = axesHandle.CameraTarget + offset(1)*rightward + offset(2)*upward;
reach = 10*max(norm(geometry.Max - geometry.Min), 1) + distance;
if strcmp(axesHandle.Projection, 'perspective')
    direction = pointOnTarget - axesHandle.CameraPosition;
    direction = direction/norm(direction);
    ray = [axesHandle.CameraPosition; axesHandle.CameraPosition + reach*direction];
else
    ray = [pointOnTarget - reach*viewDirection; pointOnTarget + reach*viewDirection];
end
end % Ends fcn_INTERNAL_rayAtPixel
