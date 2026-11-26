function [viewSettings, viewer] = fcn_CarMesh3D_viewLabels(meshInput, options)
% fcn_CarMesh3D_viewLabels

% A viewer for looking at a vehicle's labels next to its photos: the mesh
% with each label in its own color (or in the vehicle's colors), and the
% photos of the real vehicle with the photo dial (drag its arrow around
% the vehicle; the model turns to the same side, and turning the model
% moves the arrow and the photo). Pick a label to see it alone; untick a
% label's box to hide it and see what is under it.
%
% When the window is closed, the viewer returns its view settings (the
% camera, the label shown, the labels hidden, the colors, the photo).
% Given back as ViewSettings, they open the viewer at exactly that view:
% one person zooms in on a problem, and sends the call ("Copy view call"
% puts it on the clipboard) for another to see the same thing at the same
% angle and magnification.
%
% It works on its own (its own window), or inside another window, which
% gives it a panel to build into. Its own window has the label painter's
% layout: a top bar (the menu, Exit, what is shown now), and one panel at
% a time at the left: Overall Display, Labels To Display and Lamps To
% Display (built by fcn_CarMesh3D_makeDisplayPanels, the same panels as
% the painter's) and GUI settings (the starting view, the ground plane).
% A ground plane is drawn under the vehicle, by day and at night; it
% starts on in every window (Overall Display, Show ground?, turns it off
% for that window only).
%
% FORMAT:
%
%       [viewSettings, viewer] = fcn_CarMesh3D_viewLabels(meshInput,...
%           (ViewSettings=viewSettings), (Colors=colors), (Label=key),...
%           (Hidden=keys), (PhotoFolder=folder), (Outline=outline),...
%           (Parent=container), (LabelListParent=container),...
%           (FlagShowTools=flag), (OnHint=function), (ColorFilter=function),...
%           (HiddenFaces=function), (FlagPhotoOptions=flag), (OnLamps=function),...
%           (OnView=function), (OnNight=function), (QuickBar=grid),...
%           (FlagWait=flag), (FlagVisible=flag), (FlagClipboard=flag),...
%           (FlagCheckStale=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      meshInput: the mesh to view, either way:
%           - a file name: a .mat file holding a labeled CarMesh3D mesh
%             (the variable vehicleMesh, else the first mesh in it), such
%             as a vehicle's mesh file or a timestamped copy from the
%             painter. The viewer shows exactly that file; it does not
%             choose between files.
%           - a vehicle ID ('2009_Honda_Fit_Sport') or its folder: the
%             vehicle's mesh with its saved label fixes, as
%             fcn_CarMesh3D_meshWithLabelEdits gives it (the latest, even
%             when the painter saved fixes after the vehicle's script ran).
%           - a variable: a labeled CarMesh3D mesh (Vertices, Faces,
%             LabelPartNames, LabelFacePart). If it is a vehicle's mesh (its
%             BuildInfo or Name names a vehicle) and its labels differ from the
%             vehicle's latest, a warning says so (a variable loaded
%             before the painter saved is out of date).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      ViewSettings: view settings this viewer returned before: opens at
%      that camera, label, hidden labels, colors and photo. Fields that
%      are missing keep their defaults; Label, Hidden and Colors given
%      here as well win over the ones in ViewSettings.
%
%      Colors: 'labels' (default: each label in its own color) or
%      'vehicle' (the vehicle's own colors).
%
%      Label: the label shown alone ('part_trim', 'light_tailBrakeLamp', ...; as
%      the list's keys), or 'all' (default).
%
%      Hidden: labels whose faces are hidden (a cell array of keys).
%
%      PhotoFolder: a folder of ViewInDegrees_<angle> photos. Default: a
%      folder "photos" beside the mesh file (a file given), else none.
%
%      Outline: the vehicle's 2D outline (fcn_CarMesh3D_makeOutline2D's
%      output, or a .mat file holding vehicleOutline), drawn in the photo
%      dial. Default: none (the dial draws the mesh from above).
%
%      Parent: a panel or grid to build into; [] (default) for a window of
%      its own.
%
%      LabelListParent: a panel or grid to put the older list of labels
%      (and lamps) in, for a host that wants it. Default: none (its own
%      window lists them in Labels To Display and Lamps To Display).
%
%      FlagShowTools: inside a host (Parent), false to leave out the row of
%      tools (colors, reset view, copy view call). Default true. Its own
%      window has the menu's Overall Display instead.
%
%      OnHint: a function called with a hint (HTML text); [] (default) to
%      show hints in the viewer's own hint line.
%
%      ColorFilter: for a window that builds the viewer in and colors
%      faces of its own (the painter: painted faces): a function
%      [faceColors, faceAlpha] = f(faceColors, faceAlpha), called each
%      time the model is colored, before hidden faces are made
%      see-through.
%
%      HiddenFaces: for such a window: a function flagHidden = f(keys)
%      giving the faces hidden for these hidden label keys (one flag per
%      face). Default: the faces with those labels.
%
%      History: the mesh's history (fcn_CarMesh3D_meshHistory's output),
%      shown as fine print at the bottom: the model's license, when the
%      mesh was built, its last change, and whether a person has reviewed
%      it (by whom, when). Default: the history of the mesh file given
%      (none for a mesh variable); false for no fine print.
%
%      FlagPhotoOptions: true to put the photo's options under the photo (its
%      folder, with Browse; whether picking a photo turns the model; its
%      size: small, medium, large). Default false; always shown in its
%      own window. (The painter uses it.)
%
%      OnLamps: a function called with the lamp states (a structure, as
%      in NightLights) whenever they change, for a window with a lamp
%      panel of its own. Default [] (none).
%
%      OnView: a function called (with no input) when the camera has
%      moved, for a window that shows the camera's angles (the shared
%      Overall Display). Default [] (none).
%
%      OnNight: a function called with true or false whenever the view
%      switches between day and night (from the sun/moon button on the
%      model, the panels, or a hook), so a host's own panels can follow.
%      Default [] (none).
%
%      QuickBar: a host's top bar (a grid layout) whose last three columns
%      take the three most-used switches, so every window has them in the
%      same place, the top right in the bar with the Menu (Sean, T86 and
%      10:41, 2026-11-26): Mesh (the faces' edges shown or not), Grid (the
%      ground in 1 m squares shown or not), and the sun/moon (day or
%      night). Default [] (none): in the viewer's own window, its own top
%      bar's right end; inside a host with no bar, only the sun/moon, over
%      the model's top right corner.
%
%      FlagWait: true to wait until the window is closed and return the view
%      settings then. Default false: return at once, so the prompt stays
%      free, as the other GUIs do (Q68 (A), Sean 2026-11-25); the settings
%      when it opened are returned, and the viewer's GetView gives them
%      later.
%
%      FlagCheckStale: true to compare a vehicle's mesh given as a variable
%      with the vehicle's latest labels, and warn if they differ (a second
%      or two); false to skip it. Default [] (true in a window of its own;
%      false built into a host, such as the painter, whose mesh may hold
%      edits not yet saved).
%
%      FlagVisible: false to build the window hidden (for tests). Default true.
%
%      FlagClipboard: true to put Copy view call's text on the clipboard,
%      false to only return and print it. Default []: true for a shown
%      window, false for a hidden one, so a test never replaces what the
%      user copied (Sean, 2026-11-26 15:41: a test's view call was on the
%      clipboard in place of answerQueue's Done text).
%
%      FigNum: not used (a window); [] or -1 (fast mode: no input checks).
%
% OUTPUTS:
%
%      viewSettings: a structure: MeshFile ('' for a mesh variable; the
%      vehicle ID when opened by ID, so the view call opens the latest),
%      Camera (CameraPosition, CameraTarget, CameraUpVector,
%      CameraViewAngle, Projection, XLim, YLim, ZLim), Label, Hidden,
%      Colors, PhotoAngle (the photo shown, in degrees; NaN for none),
%      SeeThrough (how see-through the body is drawn: 0 solid, up to 0.9),
%      FlagShowEdges (true when the faces' edges are drawn), FlagNight
%      (true for the nighttime view), NightLights (the lamps switched on
%      in it: fcn_CarMesh3D_plotVehicle's Signals), PhotoHeight
%      (the photo's height in pixels, set with the handle at its bottom
%      left corner).
%
%      viewer: a structure of the viewer's handles and functions:
%           Figure, Axes, Patch
%           GetView(): the view settings now
%           SetView(viewSettings): go to these view settings
%           ViewCall(): the MATLAB call that opens this view, as text
%           ShowLabel(key), Label(), SetHidden(keys), Hidden(),
%           SetColors(colors), Redraw()
%           SetMesh(mesh, labelColors, labelAlpha): a mesh with the same
%               faces and new labels (the painter, after a save)
%           SetPhotoAngle(angle), PhotoAngle()
%           DialMove(), DialUp(), GripDown(): for a window that handles
%               the mouse itself (each says whether it used the event: the
%               dial's arrow, or the photo's corner, is being dragged; call
%               GripDown first in the window's mouse-down)
%           SetHistory(history): new fine print (after a change)
%           ResetView(), SetSeeThrough(fraction), SeeThrough(): how
%               see-through the body is drawn (0 solid, up to 0.9)
%           LabelColor(name): the color of a label's box ('body',
%               'headlamp', 'hide', ...)
%           SetGround(flag), Ground(): the ground plane shown or not (in
%               this window only; it starts on)
%           SetStartView(dialAngle, downAngle), StartView(): the starting
%               view (and Reset view's), a preference shared with the
%               painter
%           OpenPanel(name), Panel(), Panels(): its own window's panels:
%               open one as the ☰ Menu does (under the one open; an open
%               one closes), the top open one's name, and
%               fcn_CarMesh3D_makeDisplayPanels' functions
%           SetTurnPhotoWithModel(flag), TurnPhotoWithModel(): turning the
%               model moves the photo dial and the photo (true), or not
%           OpenNames(), OpenPanels(names): the open panels (top first),
%               or exactly these open (at most two)
%           Menu(), Settings(): the shared ☰ Menu's functions
%               (fcn_CarMesh3D_makePanelMenu) and Shared GUI settings'
%               (fcn_CarMesh3D_makeSettingsPanel)
%           Stop() (its timer), Close()
%           PhotoCount(): how many photos the dial has (0: no photo side)
%           For tests (fcn_CarMesh3D_guiDriver on this window; inside a
%           host, on the panel it was built into):
%           State(), SetState(tag, value) or SetState(struct),
%               Press(tagOrText), Key(key), CheckLayout(), Controls()
%           MouseDrag(button, fromPoint, toPoint, numSteps): a drag on
%               the model through the mouse's own code ('left' turns,
%               'right' pans; points in the window's pixels, [] from the
%               model's middle)
%           Scroll(count, point): the wheel (negative zooms in)
%           DialDrag(angles, flagRelease): the dial's arrow pressed at
%               the first angle and dragged through the rest, let go at
%               the end (false with no photos, or the dial left out of a
%               small window)
%           Resize([width height]): the window resized, the view checked
%           Tick(): the view timer's check, at once
%           Settle(): waits until the window has laid itself out, then
%               Tick (a hidden window lays out a little after drawnow)
%           FitInfo(): Zoom (1: the whole vehicle just fits; larger is
%               zoomed in), FitTan, AxesSize
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotLabels, fcn_CarMesh3D_meshHistory (a mesh file
%      given)
%
% EXAMPLES:
%
%       % Look, zoom in on a problem, close: the view comes back
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport');
%       viewSettings = fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile);
%
%       % Open the same view (or someone else's, from "Copy view call")
%       fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile, ViewSettings=viewSettings);
%
%       % A vehicle by its ID: its mesh with its latest saved label fixes
%       fcn_CarMesh3D_viewLabels('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_viewLabels.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * First write (Sean, 12:25): the labels and the photos with their
%   %   % dial, as a viewer of its own; view settings out when closed, and
%   %   % in, to open the same view; "Copy view call"
%   % * The mesh to view is given: a file name or a variable, told apart
%   %   % by what it is (Sean, 12:39: no choosing between meshes)
%   % * Opening at a photo (PhotoAngle without a camera) turns the model
%   %   % with view(), so MATLAB fits the vehicle in the window (it came up
%   %   % far too close)
%   % * "See-through body" slider in the tools: the body drawn see-through
%   %   % (0 to 90%), to see and click what is inside; kept in the view
%   %   % settings (SeeThrough) and the view call (Sean, 14:06)
%   % * In label colors, the glass is as see-through as in the vehicle's
%   %   % own colors, as rendered (Sean, 14:08)
%   % * Picking the interior label makes the glass nearly clear and draws
%   %   % the interior in a strong orange, so it can be seen through the
%   %   % windows (Sean, 14:33)
%   % * The dial and the model's turning use the camera's own angles
%   %   % around its target, not view()'s (measured in the plot box, they
%   %   % differed after "Reset view", and the arrow, let go on a photo,
%   %   % moved off it: Sean, 14:37)
%   % * The dial reads the mouse's angle from the window's mouse position
%   %   % and its own place on the screen, not its CurrentPoint, which lags
%   %   % behind after a resize (Sean, 14:02)
%   % * Fine print at the bottom (Sean, 13:07): the license, the build,
%   %   % the last change, and whether (and by whom, when) a person has
%   %   % reviewed the mesh (fcn_CarMesh3D_meshHistory)
%   % * Built into the painter (fcn_CarMesh3D_paintLabels), which colors
%   %   % its paint through ColorFilter and HiddenFaces, so a fix here is a
%   %   % fix there
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)
%   % * Multi-part faces (LabelFaceAlsoParts): a face is in each label it
%   %   % belongs to (a lamp's clear cover is in its light's label and in
%   %   % glass), and stays shown while any of them is shown
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * The list of labels at the left, beside the model it labels (it
%   %   % was by the photo); each label's name in its color, with a swatch
%   %   % of the color beside its Show box (Sean, 00:05)
%   % * "Show mesh boundaries": the faces' edges drawn
%   %   % (FlagShowEdges in the view settings), for every label picked,
%   %   % not only "All labels" (Sean, 02:19)
%   % * "Nighttime view" (Sean, 02:59 and 03:05): the night scene of
%   %   % the animator's lights check (fcn_CarMesh3D_animateChecks): a
%   %   % dark checkered ground and sky, a faint light from above, and
%   %   % the vehicle in its own colors (fcn_CarMesh3D_plotVehicle, matte,
%   %   % LightEffects), each lamp's glow and the light it throws on the
%   %   % ground. A list of the lamps to switch (under the label
%   %   % list): low beams and high beams (each alone: separate lamps,
%   %   % Sean 03:19), running lights, each turn signal, hazards, tail
%   %   % lights (off, on, brake), backup lights;
%   %   % each can be switched even when no faces are labeled as that
%   %   % lamp (marked "no faces"): its light on the ground still shows
%   %   % where it would land (Sean, 03:19). "Show mesh
%   %   % boundaries" works in it too. (NightView and NightLights in the
%   %   % view settings.) Switched off, the label colors return.
%   % * The lamp list is always shown, under the labels (Sean, 03:53):
%   %   % by day, the lamps switched on are drawn lit on the model; at
%   %   % night, with their light. The Show boxes work at night too (take
%   %   % the glass off a lamp to see it). The lamps start off; the first
%   %   % night switches them all on.
%   % * Hidden faces (LabelFaceHiddenSet; Sean, 04:17): out of view, listed as
%   %   % "hidden (not drawn)" with its Show box unticked; tick it to see
%   %   % them (they are measured and drawn nowhere else)
%   % * The photo resized by a handle at its bottom left corner, its
%   %   % shape kept, from the dial's size to the window's height; the dial
%   %   % follows the photo's edge and the model gets the rest (PhotoHeight
%   %   % in the view settings); the photo's name on the photo, top right,
%   %   % on white (it was in a box above the photo)
%   % * Lit more evenly (ambient 0.85, diffuse 0.3), so the near-white
%   %   % body reads as white and the label colors stand out
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * Hooks for the painter's new panels (Sean, 10:24; Documents/
%   %   % Documentation_CarMesh3D_GUIdesign_paintLabels.md): labels drawn
%   %   % plain gray ("Colored? No", SetUncolored), SetBoundaries,
%   %   % SetNightLamp, LabelKinds, LampTypes, CopyViewCall, OnLamps; the
%   %   % photo's options under the photo (PhotoOptions: folder, turn the
%   %   % model with the photo, size). The viewer on its own is unchanged.
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * The lamp list has Fog lamps and Reflectors lit (outside light);
%   %   % Hazards also lights the warning lamps; marker lamps light with
%   %   % the running lights and the license plate lamp with the tail
%   %   % lights (Sean, task 8; Q24 (A), Q25 (A)). The night lamp states
%   %   % have Fog, Hazards and Reflectors

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * Its own window in the painter's layout (Q33 (A), Sean 02:41; the
%   %   % design file's section 5): a top bar (Menu, Exit, the status),
%   %   % one panel at a time at the left (Overall Display, Labels To
%   %   % Display, Lamps To Display: built by
%   %   % fcn_CarMesh3D_makeDisplayPanels, shared with the painter; and GUI
%   %   % settings), the photo options under the photo. The tool row and
%   %   % the old label list are left for hosts that ask for them
%   %   % (ShowTools, LabelListParent)
%   % * A ground plane by day (light squares) as at night, on by
%   %   % default; "Show ground?" in GUI settings, kept as a preference
%   %   % the painter shares (Sean, 02:43)
%   % * The starting view (and Reset view) from GUI settings: 60 degrees
%   %   % on the dial, 20 down by default (V8; the painter's C2S 2)
%   % * New hooks: LabelColor, SetGround, Ground, SetStartView,
%   %   % StartView, OpenPanel, Panel, Panels
%   % * Sean's review T1 to T8 (03:43): Show ground? moved to Overall
%   %   % Display; the ground in squares of exactly 1 m, the same extent
%   %   % (10 m past the vehicle) and squares by day and at night, the view
%   %   % framed on the vehicle; the photo options in Overall Display (not
%   %   % under the photo, in its own window); the camera's angles and
%   %   % distance shown in Overall Display (hook CameraInfo, option OnView;
%   %   % the view timer runs with no photos too)
%   % * Sean's T22 and T23 (2026-11-24 04:53): the camera readout follows
%   %   % a turn by the photo dial too; the vehicle fits the window when it
%   %   % is resized (the view angle refitted to the axes' shape, the
%   %   % user's zoom kept), and Reset view fits it to the window now
%   % * A label whose part the mesh does not have (interior, since the
%   %   % voxel interior labeling was switched off, Q37, 2026-11-24 05:06)
%   %   % has no faces, instead of an error
%   % * Drivable by script for automated tests (Sean, 05:03): every
%   %   % control a user clicks or reads has a Tag (Exit viewerExit, the
%   %   % menu's items menu_<panel>, GUI settings' startViewDial,
%   %   % startViewDown, resetSettings, the photo's photoName and
%   %   % photoGrip, ...); new hooks State, SetState, Press, Key,
%   %   % CheckLayout, Controls (fcn_CarMesh3D_guiDriver), MouseDrag,
%   %   % Scroll, DialDrag (through the mouse's own code), Resize, Tick,
%   %   % Settle, FitInfo, PhotoCount; the menu's list hidden while closed
%   %   % * Bug fixed (found by the tests): in GUI settings, typing the
%   %   % dial angle put the angle down back to its starting value (and
%   %   % the other way round): each field's callback had kept the other's
%   %   % value from when it was made
%   %   % * Bug fixed: a change made through a hook (ShowLabel, SetColors,
%   %   % SetHidden, SetNightView, ...) left its own window's panels and
%   %   % status line showing the old state; they follow every change now
%   %   % * OpenPanel with a name that is not a panel is an error (it
%   %   % opened an empty column)
%   %   % * Bug fixed: a view opened from view settings (a shared view
%   %   % call) could open at a slightly different zoom from the one given:
%   %   % the view timer refitted it while the window was being laid out;
%   %   % the timer now waits until the window is built
%   %   % * Bug fixed: in a small window the photo and dial kept their
%   %   % size: a Large photo was cut off at the bottom of an 800 x 500
%   %   % window, and at 640 x 400 they took all the width, leaving the
%   %   % model none. The photo now shrinks to the room there is (its
%   %   % chosen size kept for when the window grows), and in a window too
%   %   % small for a small photo, the photo and dial are left out
%   %   % * Bug fixed: Reset view at night went to where the camera was
%   %   % when night first fell (after the starting view was changed),
%   %   % not to the starting view: the night view kept that camera as the
%   %   % starting view
%   %   % * Bug fixed: after a turn or pan, resizing the window could cut
%   %   % off a vehicle that was fully in view: the zoom kept was measured
%   %   % against the fit made at the last resize, not from the camera now
%   %   % * Bug fixed: at night, All labels Shown? No (every label out of
%   %   % view) stopped with an error in nightEdges (no vehicle patches)
%   % * Turn photo with model? (Sean, 2026-11-23): Off, turning the model
%   %   % leaves the dial and the photo where they are; the photo options
%   %   % (Turn model with photo?, Turn photo with model?, Photo size?)
%   %   % remembered from Overall Display (preferences TurnWithPhoto,
%   %   % TurnPhotoWithModel, PhotoHeight)
%   % * The shared panels (the shared-panels design file; Sean, 16:09 to
%   %   % 16:23): the ☰ Menu is the shared one (fcn_CarMesh3D_makePanelMenu),
%   %   % with up to two panels open at once; GUI settings is now Shared
%   %   % GUI settings (fcn_CarMesh3D_makeSettingsPanel: View and Demo
%   %   % vehicle used here, the rest greyed); the mesh file's name left
%   %   % out of it (the title bar names the vehicle: sparse displays);
%   %   % new hooks OpenNames, OpenPanels, Menu, Settings

% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * Exit moved from the top bar to the ☰ Menu's last line (Q62 (A),
%   %   % Sean 14:31; same Tag, viewerExit)
%   % * Wait defaults to false: the viewer returns at once and the prompt
%   %   % stays free (Q68 (A), Sean 23:15)

% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * A sun/moon button in the model view's top right corner switches
%   %   % day and night with one click (Q89 (A), Sean 03:52: "I'm using
%   %   % that a lot, and this requires exiting/entering the panels
%   %   % over/over"; the lamp-functions plan, item 9); it shows the sun
%   %   % by day and the moon at night. New option OnNight, so a host (the
%   %   % painter) keeps its own Nighttime view? setting in step
%   % * The day-lit lamps use fcn_CarMesh3D_lampSetup and
%   %   % fcn_CarMesh3D_lampColors (the lamp-to-function matrix), the same
%   %   % rules as fcn_CarMesh3D_plotVehicle (the lamp-functions plan,
%   %   % item 4)
%   % * meshInput may be a vehicle ID: the vehicle's mesh with its saved
%   %   % label fixes (fcn_CarMesh3D_meshWithLabelEdits). A mesh variable
%   %   % whose labels differ from the vehicle's latest gives a warning
%   %   % (Q85 (A), Sean 02:24: the door patch that "survived" was a mesh
%   %   % variable loaded before the painter saved). New option CheckStale
%   % * Hooks for the lamp-functions window: SetLampFunctions (the matrix
%   %   % the lamps light by), SetLampSignals (the lamps lit by any signals,
%   %   % Parking and Brake too), OutlineFaces (cyan outlines)
%   % * The ground starts on in every window, by day and at night; Show
%   %   % ground? Off lasts only for that window (Sean, 10:12: "keep the
%   %   % ground visibility on displays to default on across GUIs"; T79
%   %   % (B)). It had been a kept preference, so one Off stayed Off
%   % * The sun/moon button at the top right, in the bar with the Menu: its
%   %   % own top bar, or a host's (new option QuickBar); over the
%   %   % model's corner only inside a host with no bar (T86 BUG). Beside
%   %   % it, Mesh and Grid buttons that stay pressed while on: the faces'
%   %   % edges and the ground, the three switches most often clicked
%   %   % (Sean, 10:41)
%   % * Day to night quick (Sean, 12:49: "a noticeable delay" one way
%   %   % only): the night scene is put away by day, not deleted, and shown
%   %   % again at the next night unless something it was built from changed
%   %   % (labels, colors, the lamp matrix, the faces shown, the ground);
%   %   % then it is built anew as before

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewLabels
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    meshInput
    options.ViewSettings = []   % View settings returned before: open at that view
    options.Colors = ''         % 'labels' or 'vehicle'; '' for the default (or ViewSettings)
    options.Label = ''          % The label shown alone; '' for the default (or ViewSettings)
    options.Hidden = []         % Labels hidden; [] for none (or ViewSettings)
    options.PhotoFolder = []    % Folder of ViewInDegrees_<angle> photos; [] for the default
    options.Outline = []        % 2D outline (or its file) for the dial; [] for none
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.LabelListParent = [] % Where the list of labels goes; [] for the default
    options.FlagShowTools = true    % The row of tools (colors, reset, copy view call)
    options.OnHint = []         % Called with hint text; [] for the viewer's own hint line
    options.ColorFilter = []    % [colors, alpha] = f(colors, alpha): a host's own colors
    options.HiddenFaces = []    % flagHidden = f(keys): a host's own hidden faces
    options.History = []        % The mesh's history (fcn_CarMesh3D_meshHistory); [] for the file's; false for none
    options.FlagWait = []           % Wait until closed; [] for the default
    options.FlagPhotoOptions = false % Photo options under the photo (folder, turn the model, size)
    options.OnLamps = []        % Called with the lamp states when they change (a host's lamp panel)
    options.OnView = []         % Called when the camera moves (a host's camera readout)
    options.OnNight = []        % Called with true/false when day and night switch (a host's panels)
    options.QuickBar = []       % A host's top bar (a grid) whose last three columns take the Mesh, Grid and sun/moon buttons; [] for the viewer's own
    options.FlagVisible = true      % Build the window hidden (tests)
    options.FlagClipboard = []      % Copy view call to the clipboard; [] for "when shown"
    options.FlagCheckStale = []     % Warn when a vehicle's mesh variable is older than its saved labels
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
    debug_figNum = 999972; %#ok<NASGU>
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
        if ischar(meshInput) || isstring(meshInput)
            if ~isfile(meshInput)
                vehicleFound = false;
                try
                    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(meshInput), FigNum=-1);
                    vehicleFound = vehicleFiles.Found && vehicleFiles.HasMesh;
                catch
                end
                if ~vehicleFound
                    error('%s is not a mesh file, nor the ID of a vehicle with a mesh', char(meshInput));
                end
            end
        elseif ~(isstruct(meshInput) && all(isfield(meshInput, {'Vertices','Faces','LabelPartNames','LabelFacePart'})))
            error('meshInput must be a mesh file name, or a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart)');
        end
        for callbackName = {'OnHint', 'ColorFilter', 'HiddenFaces', 'OnNight'}
            if ~isempty(options.(callbackName{1})) && ~isa(options.(callbackName{1}), 'function_handle')
                error('%s must be a function handle, or empty', callbackName{1});
            end
        end
        if ~isempty(options.ViewSettings) && ~isstruct(options.ViewSettings)
            error('ViewSettings must be view settings this viewer returned (a structure), or empty');
        end
        if ~isempty(options.Colors) && ~any(strcmp(char(options.Colors), {'labels', 'vehicle'}))
            error('Colors must be ''labels'' or ''vehicle''');
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

%%%% The mesh (a file name or a variable, told apart by what it is), its
%%%% label colors, the photos, and the outline
meshFile = '';
viewSource = '';
vehicleName = 'mesh';
photoFolder = '';
if (ischar(meshInput) || isstring(meshInput)) && ~isfile(meshInput)
    % (a vehicle ID: its mesh with its saved label fixes, Q85 (A))
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(meshInput), FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleFiles.Folder, FigNum=-1);
    meshFile = vehicleFiles.MeshFile;
    viewSource = vehicleFiles.ID;   % (the view settings reopen it by ID)
    vehicleName = vehicleFiles.ID;
    if isfolder(fullfile(vehicleFiles.Folder, 'photos'))
        photoFolder = fullfile(vehicleFiles.Folder, 'photos');
    end
elseif ischar(meshInput) || isstring(meshInput)
    meshFile = char(meshInput);
    viewSource = meshFile;
    vehicleMesh = fcn_INTERNAL_loadMesh(meshFile);
    [meshFolder, vehicleName] = fileparts(meshFile);
    if isfolder(fullfile(meshFolder, 'photos'))
        photoFolder = fullfile(meshFolder, 'photos');
    end
else
    vehicleMesh = meshInput;
    flagCheckStale = options.FlagCheckStale;
    if isempty(flagCheckStale)
        flagCheckStale = isempty(options.Parent);
    end
    if flagCheckStale
        fcn_INTERNAL_warnIfStale(vehicleMesh);
    end
end
if isfield(vehicleMesh, 'Name') && ~isempty(vehicleMesh.Name)
    vehicleName = char(vehicleMesh.Name);
end
outline = options.Outline;
if ischar(outline) || isstring(outline)
    loaded = load(char(outline), 'vehicleOutline');
    outline = loaded.vehicleOutline;
end
if ~isempty(options.PhotoFolder)
    photoFolder = char(options.PhotoFolder);
end
numFaces = size(vehicleMesh.Faces,1);
if ~isfield(vehicleMesh, 'FaceAlpha') || numel(vehicleMesh.FaceAlpha) ~= numFaces
    vehicleMesh.FaceAlpha = ones(numFaces,1);
end
if ~isfield(vehicleMesh, 'FaceColors') || size(vehicleMesh.FaceColors,1) ~= numFaces
    vehicleMesh.FaceColors = repmat([0.6 0.6 0.65], numFaces, 1);
end
if ~isfield(vehicleMesh, 'LabelFaceLamp') || numel(vehicleMesh.LabelFaceLamp) ~= numFaces
    vehicleMesh.LabelFaceLamp = zeros(numFaces,1);
end
if ~isfield(vehicleMesh, 'LabelLampNames')
    vehicleMesh.LabelLampNames = {'headlamp';'turnSignalLamp';'runningLamp';'tailBrakeLamp';'backupLamp'};
end
data = struct();
data.Mesh = vehicleMesh;
labelMesh = fcn_CarMesh3D_plotLabels(vehicleMesh, FigNum=-1);
data.LabelColors = labelMesh.FaceColors;
data.LabelAlpha = labelMesh.FaceAlpha(:);
if isscalar(data.LabelAlpha)
    data.LabelAlpha = repmat(data.LabelAlpha, numFaces, 1);
end
data.Geometry = fcn_INTERNAL_geometry(vehicleMesh);
data.OutlineElements = struct('Key',{},'Label',{},'Polygons',{});
if ~isempty(outline)
    data.OutlineElements = fcn_INTERNAL_outlineElements(outline);
end
[labelKeys, labelNames] = fcn_INTERNAL_labelKinds(vehicleMesh, isempty(options.HiddenFaces));
flagHasHint = isempty(options.OnHint);

%%%% The view to open at: the options, else the view settings given, else
%%%% the defaults
given = options.ViewSettings;
if isempty(given)
    given = struct();
end
currentKey = fcn_INTERNAL_pick(char(options.Label), given, 'Label', 'all');
colorsMode = fcn_INTERNAL_pick(char(options.Colors), given, 'Colors', 'labels');
if ~isempty(options.Hidden)
    hiddenKeys = cellstr(options.Hidden);
elseif isfield(given, 'Hidden') && ~isempty(given.Hidden)
    hiddenKeys = cellstr(given.Hidden);
else
    hiddenKeys = {};
    if isempty(options.HiddenFaces) && any(strcmp(labelKeys, 'hidden'))
        hiddenKeys = {'hidden'};   % (hidden faces start out of view: tick "hidden" to see them)
    end
end
hiddenKeys = hiddenKeys(:)';

%%%% State
photoSet = struct('Angle',{},'File',{});
photoFiles = {};
dialAxes = [];
dialArrow = [];
dialDots = [];
photoImage = [];
photoLabel = [];   % (the photo's name, in a white box on the photo's top right corner)
photoPanel = [];
photoColumn = [];
photoGrip = [];    % (the photo's resize handle, at its bottom left corner)
dialGrid = [];
layout = [];
photoAspect = 4/3;
% (the photo options, remembered from Overall Display: Show ground?'s
% neighbors, one place for each setting, the shared-panels design file)
photoHeight = double(fcn_INTERNAL_pref('PhotoHeight', 300));
if ~isscalar(photoHeight) || ~any(photoHeight == [220 300 420])
    photoHeight = 300;
end
dialSize = 220;    % (the dial's ring: the photo is never made shorter than it)
dialWidth = 300;   % (wide enough for the dial's side names)
flagPhotoResizing = false;
flagShowEdges = false;   % (the mesh's face edges drawn)
boundaryBox = [];
flagNight = false;   % (the nighttime view)
nightBox = [];
dayNightButton = [];   % (the sun/moon button over the model)
lampSetupCache = [];   % (the shown mesh's lamp units and matrix: currentLampSetup)
lampSetupKey = {};
nightSignals = struct('LowBeam', false, 'HighBeam', false, 'Running', false, 'TurnLeft', false, 'TurnRight', false, ...
    'Tail',false, 'Brake', false, 'Backup', false, 'Fog', false, 'Hazards', false, 'Reflectors', 0);   % (the lamps switched on: none by day, at first; all, the first time night falls)
flagLampsSet = false;
uncoloredKeys = {};     % (labels drawn plain gray: a host's "Colored? No"; Sean, 10:24)
flagTurnWithPhoto = logical(fcn_INTERNAL_pref('TurnWithPhoto', true));   % (the model turns to a photo picked on the dial)
flagTurnPhotoWithModel = logical(fcn_INTERNAL_pref('TurnPhotoWithModel', true));   % (turning the model moves the dial and the photo: Sean, 2026-11-23)
photoFolderLabel = [];   % (true once the lamps were set: by the list, or by the view settings)
nightHandles = [];      % (fcn_CarMesh3D_plotVehicle's handles in it)
nightControls = struct();   % (the lamp list's controls)
listInner = [];         % (the label list over the lamp list: one shown at a time)
nightObjects = gobjects(0);   % (the night scene's ground, light and vehicle)
nightKey = {};          % (what the night scene was built from: kept by day, and shown again if unchanged)
nightVisible = {};      % (each night object's Visible when it was put away by day)
dayLights = gobjects(0);      % (the viewer's own lights, off at night)
labelSwatches = gobjects(0);
photoIndex = 0;
% (the ground plane, by day and at night: always on when a window opens;
% Show ground? Off lasts only for that window, Sean, 2026-11-26 10:12:
% "keep the ground visibility on displays to default on across GUIs".
% It was a kept preference, and once Off it stayed Off at night too)
flagGround = true;
dayGround = [];
% (the starting view, on the dial and looking down: GUI settings; the
% same for the viewer and the painter: V8, painter C2S 2)
startDial = fcn_INTERNAL_pref('StartViewDial', 60);
startDown = fcn_INTERNAL_pref('StartViewDown', 20);
% (its own window: the painter's layout, Q33 (A): a top bar with the
% menu, one panel at a time at the left)
displayPanels = [];
panelNames = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Shared GUI settings'};
panelHandles = gobjects(0);
panelMenu = [];      % (the shared ☰ Menu, fcn_CarMesh3D_makePanelMenu)
sharedSettings = []; % (the shared settings panel, fcn_CarMesh3D_makeSettingsPanel)
bodyGrid = [];
statusLabel = [];
flagDialDragging = false;
flagSyncingView = false;
lastLabelView = [NaN NaN];
lastAxesSize = [NaN NaN];   % (the model's axes' size when the view was last fitted to it)
fitTanLast = NaN;           % (the fit then: tan of half the view angle that just fits the vehicle)
bodySeeThrough = 0;   % (how see-through the body is drawn: 0 solid, 0.9 nearly clear)
seeThroughSlider = [];
viewTimer = [];
startView = [];
closedSettings = [];
mouseMode = '';
mouseStart = [0 0];
mouseLast = [0 0];
flagBuilt = false;   % (true once the window is built: the view timer refits the view only then)

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
flagWait = options.FlagWait;
if isempty(flagWait)
    flagWait = false;   % (Q68 (A): never wait unless asked)
end
if flagOwnWindow
    visibleText = 'on';
    if ~options.FlagVisible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_viewLabels: %s', vehicleName), 'Position', [60 60 1500 860], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewLabels', Subtitle=vehicleName, FigNum=-1);
    % (the painter's layout, Q33 (A), Sean 2026-11-24 02:41; the design
    % file's section 5: a top bar (the menu, Exit, the status), the open
    % panel at the left beside the model, the model, the photo dial, and
    % the photo with its options at the right)
    rootGrid = uigridlayout(contentPanel, [2 1], 'RowHeight', {36, '1x'}, 'Padding', [6 4 6 4], 'RowSpacing', 3);
    topGrid = uigridlayout(rootGrid, [1 5], 'ColumnWidth', {90, '1x', 70, 70, 44}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);   % (the last three: Mesh, Grid, sun/moon)
    menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'viewerMenu', ...
        'Tooltip', 'Open a panel at the left (up to two at once; pick an open one again to close it)');
    % (Exit is the ☰ Menu's last line: Q62 (A), Sean 2026-11-25 14:31)
    statusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11, 'Tag', 'viewerStatus');
    bodyGrid = uigridlayout(rootGrid, [1 2], 'ColumnWidth', {320, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
    % (the ☰ Menu and the panels it opens, up to two at once: the shared
    % menu, fcn_CarMesh3D_makePanelMenu, as in every CarMesh3D GUI, rule G1)
    menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
    menuColumn.Layout.Row = 1;
    menuColumn.Layout.Column = 1;
    panelMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
        OnChange=@(~) onPanelsChanged(), Exit=@() closeViewer(), ExitTag='viewerExit', FigNum=-1);
    blueBand = [0.93 0.95 1];     % (viewing work, as in the painter)
    grayBand = [0.94 0.94 0.94];  % (settings)
    panelColors = {blueBand, blueBand, blueBand, grayBand};
    panelHandles = gobjects(1, numel(panelNames));
    for ith_panel = 1:numel(panelNames)
        panelHandles(ith_panel) = panelMenu.AddPanel(panelNames{ith_panel}, panelColors{ith_panel});
    end
    menuParts = panelMenu.Parts();
    menuParts.List.Tag = 'viewerMenuList';   % (its name in this window's tests)
    parent = uipanel(bodyGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 2;
else
    parent = options.Parent;
    figureHandle = ancestor(parent, 'figure');
end
toolHeight = 0;
if options.FlagShowTools && ~flagOwnWindow
    toolHeight = 34;   % (inside a host; its own window has the menu's Overall Display instead)
end
hintHeight = 0;
if flagHasHint
    hintHeight = 22;
end
history = options.History;
if isempty(history) && ~isempty(meshFile)
    try
        history = fcn_CarMesh3D_meshHistory(meshFile, Mesh=vehicleMesh, FigNum=-1);
    catch
        history = [];
    end
end
if isequal(history, false)
    history = [];
end
mainGrid = uigridlayout(parent, [4 1], 'RowHeight', {toolHeight, '1x', hintHeight, 0}, 'Padding', [0 0 0 0], 'RowSpacing', 2);

% The tool row: the colors, reset, copy the view call, close
toolGrid = uigridlayout(mainGrid, [1 10], 'ColumnWidth', {60, 210, 100, 130, 175, 120, 130, 150, '1x', 80}, 'Padding', [4 2 4 2], ...
    'ColumnSpacing', 6, 'BackgroundColor', [0.93 0.95 1]);
uilabel(toolGrid, 'Text', 'Colors:', 'HorizontalAlignment', 'right', 'FontWeight', 'bold');
colorsGroup = uibuttongroup(toolGrid, 'BorderType', 'none', 'BackgroundColor', [0.93 0.95 1], 'Tag', 'toolColors', ...
    'SelectionChangedFcn', @(~,event) setColors(event.NewValue.UserData));
labelsRadio = uiradiobutton(colorsGroup, 'Text', 'Labels', 'Position', [4 4 70 22], 'UserData', 'labels');
vehicleRadio = uiradiobutton(colorsGroup, 'Text', 'Vehicle colors', 'Position', [80 4 120 22], 'UserData', 'vehicle');
uibutton(toolGrid, 'Text', 'Reset view', 'ButtonPushedFcn', @(~,~) resetView(), 'Tag', 'toolResetView');
uibutton(toolGrid, 'Text', 'Copy view call', 'ButtonPushedFcn', @(~,~) copyViewCall(), 'Tag', 'toolCopyViewCall', ...
    'Tooltip', 'Put the MATLAB call that opens exactly this view on the clipboard, to send to someone');
boundaryBox = uicheckbox(toolGrid, 'Text', 'Show mesh boundaries', 'Value', flagShowEdges, 'Tag', 'toolBoundaries', ...
    'Tooltip', 'Draw the edge of every face (the mesh''s triangles)', ...
    'ValueChangedFcn', @(source,~) setFlagShowEdges(source.Value));
nightBox = uicheckbox(toolGrid, 'Text', 'Nighttime view', 'Value', flagNight, 'Tag', 'toolNight', ...
    'Tooltip', 'A night scene: the vehicle in its own colors, its lamps lit, and the light they throw on the ground. The lamp list switches the lamps.', ...
    'ValueChangedFcn', @(source,~) setFlagNight(source.Value));
uilabel(toolGrid, 'Text', 'See-through body:', 'HorizontalAlignment', 'right', 'FontWeight', 'bold', ...
    'Tooltip', 'Makes the body see-through, to look at (and click) what is inside it');
seeThroughSlider = uislider(toolGrid, 'Limits', [0 90], 'Value', 100*bodySeeThrough, 'MajorTicks', [0 45 90], 'Tag', 'toolSeeThrough', ...
    'MajorTickLabels', {'0','45','90%'}, 'MinorTicks', [], 'FontSize', 9, ...
    'ValueChangedFcn', @(source,~) setSeeThrough(source.Value/100));
uilabel(toolGrid, 'Text', '');
closeButton = uibutton(toolGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeViewer(), 'Tag', 'toolClose');
if ~flagOwnWindow
    closeButton.Visible = 'off';
end
if ~options.FlagShowTools || flagOwnWindow
    toolGrid.Visible = 'off';
end

% The model, the photo dial, and the photo
if ~isempty(photoFolder) && isfolder(photoFolder)
    listing = [dir(fullfile(photoFolder,'*.jpg')); dir(fullfile(photoFolder,'*.jpeg')); dir(fullfile(photoFolder,'*.png'))];
    photoFiles = fullfile(photoFolder, {listing.name});
end
photoSet = fcn_INTERNAL_photoAngles(photoFiles);
if isempty(photoSet)
    layout = uigridlayout(mainGrid, [1 1], 'Padding', [0 0 0 0]);
else
    % (the model, the dial, and the photo; the photo is resized by the
    % handle at its bottom left corner, its shape kept, and the model gets
    % the rest of the width: Sean, 00:05)
    try
        photoInfo = imfinfo(photoSet(1).File);
        photoAspect = photoInfo(1).Width/photoInfo(1).Height;
    catch
        photoAspect = 4/3;
    end
    layout = uigridlayout(mainGrid, [1 3], 'RowHeight', {'1x'}, 'ColumnWidth', {'1x', dialWidth, photoHeight*photoAspect}, ...
        'Padding', [0 0 0 0], 'ColumnSpacing', 4, 'BackgroundColor', [1 1 1]);
end
layout.Layout.Row = 2;
% (the model in a panel of its own: drawn unclipped, zoomed in it would
% draw over the dial and the photo; a panel cuts it off at its edges)
modelHolder = uipanel(layout, 'BorderType', 'none', 'BackgroundColor', [1 1 1]);
modelHolder.Layout.Row = 1;
modelHolder.Layout.Column = 1;
axesHandle = uiaxes(uigridlayout(modelHolder, [1 1], 'Padding', [0 0 0 0]), 'Tag', 'modelAxes');
% (the sun/moon button: one click switches day and night; Q89 (A), Sean
% 2026-11-26. At the top right, in the bar with the Menu: the viewer's own
% top bar, or the host's (QuickBar); else over the model's top
% right corner. Sean, T86: "all UIs that have mesh visibility testing or
% editing have this option in same corner ... top right in same Menu bar
% area")
dayNightHolder = options.QuickBar;
if flagOwnWindow
    dayNightHolder = topGrid;
end
meshToggle = [];
groundToggle = [];
% (the model panel's layout as before the button moved: its children
% placed by hand, so a resize is handled the same way in every window)
modelHolder.AutoResizeChildren = 'off';
modelHolder.SizeChangedFcn = @(~,~) placeDayNight();
if isempty(dayNightHolder)
    dayNightButton = uibutton(modelHolder, 'Text', char(9728), 'FontSize', 20, 'Tag', 'dayNightButton', ...
        'BackgroundColor', [1 1 1], 'FontColor', [0.85 0.55 0.05], ...
        'Tooltip', 'Day (click for night)', 'ButtonPushedFcn', @(~,~) toggleDayNight());   % (a nested function: an anonymous one would keep flagNight as it was now)
    placeDayNight();
else
    % (Mesh and Grid: buttons that stay pressed while on, Sean 10:41)
    meshToggle = uibutton(dayNightHolder, 'state', 'Text', [char(9651) ' Mesh'], 'FontSize', 13, 'Tag', 'meshToggle', ...
        'Value', flagShowEdges, 'Tooltip', 'Mesh: the edges of the faces drawn (pressed) or not', ...
        'ValueChangedFcn', @(source,~) setFlagShowEdges(source.Value));
    groundToggle = uibutton(dayNightHolder, 'state', 'Text', [char(9638) ' Grid'], 'FontSize', 13, 'Tag', 'groundToggle', ...
        'Value', flagGround, 'Tooltip', 'Grid: the ground in 1 m squares, by day and at night (pressed) or not', ...
        'ValueChangedFcn', @(source,~) setFlagGround(source.Value));
    dayNightButton = uibutton(dayNightHolder, 'Text', char(9728), 'FontSize', 18, 'Tag', 'dayNightButton', ...
        'BackgroundColor', [1 1 1], 'FontColor', [0.85 0.55 0.05], ...
        'Tooltip', 'Day (click for night)', 'ButtonPushedFcn', @(~,~) toggleDayNight());
    if isa(dayNightHolder, 'matlab.ui.container.GridLayout')
        lastColumn = numel(dayNightHolder.ColumnWidth);
        quickButtons = {meshToggle, groundToggle, dayNightButton};
        for ith_button = 1:3
            quickButtons{ith_button}.Layout.Row = 1;
            quickButtons{ith_button}.Layout.Column = lastColumn - 3 + ith_button;
        end
    end
end
hold(axesHandle, 'on');
axis(axesHandle, 'off');
axesHandle.Color = [1 1 1];
axesHandle.Clipping = 'off';
meshPatch = fcn_INTERNAL_drawMesh(axesHandle, vehicleMesh, data.LabelColors, data.LabelAlpha);
dayGround = fcn_INTERNAL_ground(axesHandle, vehicleMesh.Vertices, 'day');
dayGround.Visible = matlab.lang.OnOffSwitchState(flagGround);
view(axesHandle, startDial + 90, startDown);   % (the dial's angle is the camera's azimuth less 90 degrees)
fcn_INTERNAL_frameVehicle(axesHandle, vehicleMesh.Vertices);   % (framed on the vehicle, not the ground; equal axes)
axis(axesHandle, 'vis3d');
camlight(axesHandle, 'headlight');
fcn_INTERNAL_quietAxes(axesHandle);
drawnow;
startView = [];   % (taken when first needed: the window lays itself out first)
if ~isempty(photoSet)
    % The photo, at the top of its column, with its name on it (top
    % right, on white) and its resize handle (bottom left)
    photoColumn = uigridlayout(layout, [2 1], 'RowHeight', {photoHeight, '1x'}, 'Padding', [0 0 0 0], ...
        'RowSpacing', 0, 'BackgroundColor', [1 1 1]);
    photoColumn.Layout.Row = 1;
    photoColumn.Layout.Column = 3;
    photoPanel = uipanel(photoColumn, 'BorderType', 'none', 'BackgroundColor', [1 1 1]);
    photoPanel.Layout.Row = 1;
    photoPanel.AutoResizeChildren = 'off';
    photoImage = uiimage(photoPanel, 'ImageSource', photoSet(1).File, 'ScaleMethod', 'fit', 'Tag', 'photoImage', ...
        'Position', [1 1 photoHeight*photoAspect photoHeight]);
    photoLabel = uilabel(photoPanel, 'Text', '', 'FontSize', 13, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'Tag', 'photoName', ...
        'BackgroundColor', [1 1 1], 'FontColor', [0.15 0.15 0.15]);
    % (a corner mark: pressing on it is found from the mouse's position,
    % in the window's mouse-down, so it works in a host window too)
    photoGrip = uilabel(photoPanel, 'Text', char(9699), 'FontSize', 22, 'FontColor', [0.15 0.15 0.15], ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Position', [2 2 26 26], ...
        'Tooltip', 'Drag this corner to resize the photo', 'Tag', 'photoGrip');
    % (the name and the corner sit on the photo on purpose: marked so the
    % layout check of fcn_CarMesh3D_guiDriver does not call them overlaps)
    setappdata(photoLabel, 'guiDriverOverlay', true);
    setappdata(photoGrip, 'guiDriverOverlay', true);
    photoPanel.SizeChangedFcn = @(~,~) placePhoto();
    % The dial, beside the photo, level with its middle
    dialGrid = uigridlayout(layout, [3 1], 'RowHeight', {max(0,(photoHeight - dialSize)/2), dialSize, '1x'}, ...
        'Padding', [0 0 0 0], 'RowSpacing', 0, 'BackgroundColor', [1 1 1]);
    dialGrid.Layout.Row = 1;
    dialGrid.Layout.Column = 2;
    dialAxes = uiaxes(dialGrid, 'Tag', 'photoDial');
    dialAxes.Layout.Row = 2;
    [dialArrow, dialDots] = fcn_INTERNAL_drawDial(dialAxes, data, [photoSet.Angle]);
    dialAxes.ButtonDownFcn = @onDialDown;
    placePhoto();
    if options.FlagPhotoOptions && ~flagOwnWindow
        makePhotoOptions();   % (a host that asks; its own window has them in Overall Display)
    end
end
hintLabel = [];
if flagHasHint
    hintLabel = uilabel(mainGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35], 'Tag', 'viewerHint');
    hintLabel.Layout.Row = 3;
end
% (the fine print: license, build, last change, review)
finePrintLabel = uilabel(mainGrid, 'Text', '', 'FontSize', 10, 'FontColor', [0.4 0.4 0.4], 'WordWrap', 'on', ...
    'Tag', 'finePrint');
finePrintLabel.Layout.Row = 4;
setHistory(history);

% The list of labels (pick one to see it alone; untick its box to hide
% it): at the side of its own window, or where the host puts it; and, in
% its own window, its own mouse (CAD-style)
labelRadios = gobjects(0);
labelShowBoxes = gobjects(0);
labelGroup = [];
listParent = options.LabelListParent;   % (its own window lists the labels in Labels To Display instead)
if ~isempty(listParent)
    % (in a grid of its own, so it fills the space it is given)
    % (the label list, and under it the lamp list of the nighttime view:
    % one shown at a time)
    listInner = uigridlayout(listParent, [2 1], 'RowHeight', {'1x', 350}, 'Padding', [0 0 0 0], 'RowSpacing', 4);
    labelGroup = uibuttongroup(listInner, ...
        'Title', 'Labels', 'Scrollable', 'on', 'Tag', 'labelList', ...
        'SelectionChangedFcn', @(~,event) showLabel(event.NewValue.UserData));
    labelGroup.AutoResizeChildren = 'off';   % (else its SizeChangedFcn is never called)
    labelGroup.SizeChangedFcn = @(~,~) placeLabelRows();
    makeLabelRows();
    makeLampList();
end
if flagOwnWindow
    set(figureHandle, 'WindowButtonDownFcn', @(~,~) onOwnDown(), 'WindowButtonMotionFcn', @(~,~) onOwnMove(), ...
        'WindowButtonUpFcn', @(~,~) onOwnUp(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'CloseRequestFcn', @(~,~) closeViewer());
end

% The view to open at, and the view timer (rotating the model sends no
% event, so its view is checked four times a second, to move the dial)
setView(given);
% (the label rows and the photo placed again once the window has laid
% itself out: before that, their boxes have no size yet)
drawnow;
placeLabelRows();
placePhoto();
setHint(['Mouse: left-drag rotates, right-drag pans, the wheel zooms. Pick a label at the left to see it alone; ' ...
    'untick it to hide it. Photos: drag the red arrow around the vehicle; drag the photo''s bottom left corner to resize it. ' ...
    '"Copy view call" puts this exact view on the clipboard.']);
% (always: the camera's angles in Overall Display follow the view too)
viewTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.25, ...
    'TimerFcn', @(~,~) onModelViewChanged(), 'BusyMode', 'drop');
start(viewTimer);
meshPatch.DeleteFcn = @(~,~) stopTimer();

viewer = struct('Figure', figureHandle, 'Axes', axesHandle, 'Patch', meshPatch, ...
    'GetView', @getView, 'SetView', @setView, 'ViewCall', @viewCall, ...
    'ShowLabel', @showLabel, 'Label', @getLabel, 'SetHidden', @setHidden, 'Hidden', @getHidden, ...
    'SetColors', @setColors, 'Redraw', @redraw, 'SetMesh', @setMesh, ...
    'SetPhotoAngle', @(angle) setDialAngle(angle, true, true), 'PhotoAngle', @getPhotoAngle, ...
    'DialMove', @dialMove, 'DialUp', @dialUp, 'GripDown', @gripDown, 'SetHistory', @setHistory, ...
    'ResetView', @resetView, 'SetSeeThrough', @setSeeThrough, 'SeeThrough', @getSeeThrough, ...
    'SetFlagNight', @setFlagNight, 'FlagNight', @getFlagNight, ...
    'SetNightLights', @setNightLights, 'NightLights', @getNightLights, ...
    'SetFlagShowEdges', @setFlagShowEdges, 'FlagShowEdges', @getFlagShowEdges, 'Colors', @getColors, ...
    'SetUncolored', @setUncolored, 'Uncolored', @getUncolored, 'LabelKinds', @getLabelKinds, ...
    'LampTypes', @getLampTypes, 'SetNightLamp', @setNightLamp, 'CopyViewCall', @copyViewCall, ...
    'SetTurnWithPhoto', @setTurnWithPhoto, 'TurnWithPhoto', @getTurnWithPhoto, ...
    'SetTurnPhotoWithModel', @setTurnPhotoWithModel, 'TurnPhotoWithModel', @getTurnPhotoWithModel, ...
    'SetPhotoHeight', @setPhotoHeight, 'PhotoHeight', @getPhotoHeight, 'SetPhotoFolder', @setPhotoFolder, ...
    'PhotoFolder', @getPhotoFolder, 'PlacePhoto', @placePhoto, ...
    'LabelColor', @getLabelColor, 'SetFlagGround', @setFlagGround, 'FlagGround', @getFlagGround, 'CameraInfo', @getCameraInfo, ...
    'SetStartView', @setStartView, 'StartView', @getStartView, ...
    'OpenPanel', @pickPanel, 'Panel', @getOpenPanel, 'OpenNames', @getOpenNames, 'OpenPanels', @openPanels, ...
    'Menu', @getMenu, 'Settings', @getSharedSettings, 'Panels', @getPanels, 'PhotoCount', @getPhotoCount, ...
    'Stop', @stopTimer, 'Close', @closeViewer, ...
    'State', @() fcn_CarMesh3D_guiDriver(driverRoot(), 'state'), ...
    'SetState', @(varargin) fcn_CarMesh3D_guiDriver(driverRoot(), 'set', varargin{:}), ...
    'Press', @(varargin) fcn_CarMesh3D_guiDriver(driverRoot(), 'press', varargin{:}), ...
    'Key', @(varargin) fcn_CarMesh3D_guiDriver(driverRoot(), 'key', varargin{:}), ...
    'CheckLayout', @() fcn_CarMesh3D_guiDriver(driverRoot(), 'checkLayout'), ...
    'Controls', @() fcn_CarMesh3D_guiDriver(driverRoot(), 'controls'), ...
    'MouseDrag', @mouseDrag, 'Scroll', @scrollHook, 'DialDrag', @dialDrag, 'Resize', @resizeWindow, ...
    'Tick', @onModelViewChanged, 'Settle', @settle, 'FitInfo', @getFitInfo, ...
    'SetLampFunctions', @setLampFunctions, 'SetLampSignals', @setLampSignals, 'OutlineFaces', @outlineFaces);
if flagOwnWindow
    % (the panels, made once the hooks are: the display panels shared
    % with the painter, fcn_CarMesh3D_makeDisplayPanels, and GUI
    % settings; the window opens at Overall Display)
    displayPanels = fcn_CarMesh3D_makeDisplayPanels(viewer, Overall=panelHandles(1), Labels=panelHandles(2), ...
        Lamps=panelHandles(3), OnChange=@updateStatus, FigNum=-1);
    % (Shared GUI settings: the viewer uses View and Demo vehicle; the
    % other sections are greyed, rule G26)
    sharedSettings = fcn_CarMesh3D_makeSettingsPanel(panelHandles(4), Used={'View', 'Demo vehicle'}, ...
        OnChange=@onSharedSetting, FigNum=-1);
    pickPanel('Overall Display');
    updateStatus();
    figureHandle.UserData = viewer;
end

% (built: a camera given, as in a shared view, measured against "just
% fits" at the window's final layout, so it opens exactly as given; the
% view timer had refitted it at a size the window passed through while
% being built, and the view call opened at a slightly different zoom:
% found by the tests, 2026-11-24)
drawnow;
if fitPhotoToWindow()   % (the photo fitted to the window first, so the model's size is final)
    drawnow;
    placePhoto();
end
flagBuilt = true;
if isfinite(fitTanLast) || isequal(lastAxesSize, [-1 -1])
    noteFit();
end
onModelViewChanged();   % (a view not given: fitted to the window now)
viewSettings = getView();
if flagOwnWindow && flagWait && options.FlagVisible
    uiwait(figureHandle);
    if ~isempty(closedSettings)
        viewSettings = closedSettings;
    end
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the viewer's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% What is shown
    function showLabel(labelKey)
        % One label in its colors and the rest gray (with the mesh's
        % edges, to see each face), or 'all'
        labelKey = char(labelKey);
        if ~strcmp(labelKey, 'all') && ~any(strcmp(labelKeys, labelKey))
            labelKey = 'all';
        end
        currentKey = labelKey;
        if ~isempty(labelGroup) && isvalid(labelGroup)
            selected = find(arrayfun(@(radio) strcmp(radio.UserData, currentKey), labelRadios), 1);
            if ~isempty(selected) && ~isequal(labelGroup.SelectedObject, labelRadios(selected))
                labelGroup.SelectedObject = labelRadios(selected);
            end
        end
        redraw();
        refreshOwn();
    end

    function setHistory(historyIn)
        % The fine print at the bottom: the license, the build, the last
        % change, and the review (the "not reviewed" in dark red)
        if isempty(finePrintLabel) || ~isvalid(finePrintLabel)
            return;
        end
        if isempty(historyIn) || ~isstruct(historyIn) || ~isfield(historyIn, 'FinePrint')
            finePrintLabel.Text = '';
            mainGrid.RowHeight{4} = 0;
            return;
        end
        finePrintLabel.Text = historyIn.FinePrint;
        if strcmp(historyIn.Review.Status, 'not reviewed') || ~historyIn.Review.Current
            finePrintLabel.FontColor = [0.6 0.1 0.1];
        else
            finePrintLabel.FontColor = [0.4 0.4 0.4];
        end
        mainGrid.RowHeight{4} = 28;
    end

    function key = getLabel()
        key = currentKey;
    end

    function keys = getHidden()
        keys = hiddenKeys;
    end

    function setMesh(meshIn, labelColorsIn, labelAlphaIn)
        % A mesh with the same faces and new labels (and their label
        % colors): the list of labels is made again if its labels changed
        data.Mesh = meshIn;
        if ~isfield(data.Mesh, 'FaceColors') || size(data.Mesh.FaceColors,1) ~= numFaces
            data.Mesh.FaceColors = repmat([0.6 0.6 0.65], numFaces, 1);
        end
        if ~isfield(data.Mesh, 'FaceAlpha') || numel(data.Mesh.FaceAlpha) ~= numFaces
            data.Mesh.FaceAlpha = ones(numFaces,1);
        end
        data.LabelColors = labelColorsIn;
        data.LabelAlpha = labelAlphaIn(:);
        [labelKeys, labelNames] = fcn_INTERNAL_labelKinds(data.Mesh, isempty(options.HiddenFaces));
        makeLabelRows();
        colorLabelRows();
        redraw();
        if flagNight
            % (the night scene drawn again, from the new mesh)
            leaveNight();
            enterNight();
        end
    end

    function setSeeThrough(fraction)
        % How see-through the body is drawn: 0 solid, up to 0.9
        bodySeeThrough = min(max(double(fraction), 0), 0.9);
        if ~isempty(seeThroughSlider) && isvalid(seeThroughSlider)
            seeThroughSlider.Value = 100*bodySeeThrough;
        end
        redraw();
        refreshOwn();
    end

    function fraction = getSeeThrough()
        fraction = bodySeeThrough;
    end

    function setHidden(keysToHide)
        hiddenKeys = reshape(cellstr(keysToHide), 1, []);
        for ith_box = 1:numel(labelShowBoxes)
            if isvalid(labelShowBoxes(ith_box))
                labelShowBoxes(ith_box).Value = ~any(strcmp(hiddenKeys, labelShowBoxes(ith_box).UserData));
            end
        end
        redraw();
        if flagNight
            % (the night scene drawn again without the hidden faces)
            buildNight();
        end
        refreshOwn();
    end

    function setColors(colorsIn)
        colorsMode = char(colorsIn);
        if ~any(strcmp(colorsMode, {'labels', 'vehicle'}))
            colorsMode = 'labels';
        end
        if strcmp(colorsMode, 'vehicle')
            colorsGroup.SelectedObject = vehicleRadio;
        else
            colorsGroup.SelectedObject = labelsRadio;
        end
        redraw();
        refreshOwn();
    end

    function redraw()
        if isempty(meshPatch) || ~isvalid(meshPatch)
            return;
        end
        if strcmp(colorsMode, 'vehicle')
            baseColors = data.Mesh.FaceColors;
            baseAlpha = data.Mesh.FaceAlpha(:);
        else
            baseColors = data.LabelColors;
            baseAlpha = data.LabelAlpha;
            % (the glass as see-through as in the vehicle's own colors, as
            % it is rendered: Sean, 14:08)
            flagGlassFaces = fcn_INTERNAL_labelFaces(data.Mesh, 'part_glass');
            baseAlpha(flagGlassFaces) = data.Mesh.FaceAlpha(flagGlassFaces);
            % (a lamp's clear cover, LabelFaceCoverLamp, drawn as glass you can
            % see: in the glass color and see-through enough to show the
            % lamp under it, not nearly clear as in the vehicle's colors;
            % it is glass, so the glass Colored? and Shown? switches act on
            % it; Q29, Sean, 2026_11_24 00:48)
            if isfield(data.Mesh,'LabelFaceCoverLamp') && numel(data.Mesh.LabelFaceCoverLamp)==numFaces
                flagCover = data.Mesh.LabelFaceCoverLamp(:) > 0 & flagGlassFaces(:);
                baseAlpha(flagCover) = max(baseAlpha(flagCover), 0.40);
            end
        end
        % (by day, the lamps switched on in the lamp list drawn lit, in
        % their lit colors, solid; Sean, 03:53)
        % (from the vehicle's lamp-to-function matrix, by the one set of
        % lighting rules, fcn_CarMesh3D_lampColors, as at night in
        % fcn_CarMesh3D_plotVehicle: the viewer's own copy of the rules
        % lit the 2009 Fit's fog lamps with the high beams in the painter,
        % Sean 2026-11-26 00:36)
        lampSetup = currentLampSetup();
        litNow = fcn_CarMesh3D_lampColors(lampSetup, nightSignals, FigNum=-1);
        flagLampLit = litNow.FlagLit & lampSetup.FaceUnit > 0;
        baseColors(flagLampLit,:) = litNow.Colors(flagLampLit,:);
        baseAlpha(flagLampLit) = 1;
        % (a lit lamp's clear cover glows in the lamp's lit color, as at
        % night in fcn_CarMesh3D_plotVehicle; else the glass over it, drawn
        % as glass since Q29, washed the lit color out: a turn signal by
        % day was very dim; Sean, 2026_11_24 01:03)
        flagCoverLit = litNow.FlagLit & lampSetup.FaceCoverUnit > 0;
        baseColors(flagCoverLit,:) = litNow.Colors(flagCoverLit,:);
        baseAlpha(flagCoverLit) = max(baseAlpha(flagCoverLit), 0.55);
        if strcmp(currentKey, 'all')
            faceColors = baseColors;
            faceAlpha = baseAlpha;
            if ~isempty(uncoloredKeys)
                % (labels set "Colored? No": plain light gray, so the
                % colored ones stand out; a face that also has a colored
                % label keeps its color)
                flagPlain = false(numFaces,1);
                for ith_key = 1:numel(uncoloredKeys)
                    flagPlain = flagPlain | fcn_INTERNAL_labelFaces(data.Mesh, uncoloredKeys{ith_key});
                end
                coloredKeys = setdiff(labelKeys, [uncoloredKeys, {'hidden'}]);
                for ith_key = 1:numel(coloredKeys)
                    flagPlain = flagPlain & ~fcn_INTERNAL_labelFaces(data.Mesh, coloredKeys{ith_key});
                end
                faceColors(flagPlain,:) = repmat([0.88 0.88 0.88], nnz(flagPlain), 1);
            end
        else
            flagLabel = fcn_INTERNAL_labelFaces(data.Mesh, currentKey);
            faceColors = repmat([0.88 0.88 0.88], numFaces, 1);
            faceColors(flagLabel,:) = baseColors(flagLabel,:);
            faceAlpha = ones(numFaces,1);
            faceAlpha(flagLabel) = baseAlpha(flagLabel);
            if strcmp(currentKey, 'part_interior')
                % The interior, seen through the windows: the glass nearly
                % clear (as when glass is picked), and the interior in a
                % strong color, so it stands out (Sean, 14:33)
                flagGlass = fcn_INTERNAL_labelFaces(data.Mesh, 'part_glass');
                faceColors(flagGlass,:) = repmat([0.80 0.88 0.96], sum(flagGlass), 1);
                faceAlpha(flagGlass) = 0.12;
                faceColors(flagLabel,:) = repmat([1.00 0.50 0.05], sum(flagLabel), 1);
                faceAlpha(flagLabel) = 1;
            end
        end
        if bodySeeThrough > 0
            % (the body made see-through, to see and click what is inside)
            flagBodyFaces = fcn_INTERNAL_labelFaces(data.Mesh, 'part_body');
            faceAlpha(flagBodyFaces) = faceAlpha(flagBodyFaces)*(1 - bodySeeThrough);
        end
        if ~isempty(options.ColorFilter)
            [faceColors, faceAlpha] = options.ColorFilter(faceColors, faceAlpha);
        end
        flagHidden = hiddenFaceFlags();
        faceAlpha(flagHidden(:)) = 0;
        % The faces' edges: drawn only when "Show mesh boundaries" is on,
        % whichever label is picked (Sean, 02:19); with labels hidden, the
        % edges fade with their faces, so hidden faces leave no edges
        if ~flagShowEdges
            edgeArguments = {'EdgeColor', 'none'};
        elseif any(flagHidden)
            edgeArguments = {'EdgeColor', [0.45 0.45 0.45], 'EdgeAlpha', 'flat', 'LineWidth', 0.25};
        else
            edgeArguments = {'EdgeColor', [0.15 0.15 0.15], 'EdgeAlpha', 0.35, 'LineWidth', 0.25};
        end
        set(meshPatch, 'FaceVertexCData', faceColors, 'FaceVertexAlphaData', faceAlpha, edgeArguments{:});
    end

    function flagHidden = hiddenFaceFlags()
        % The faces hidden by the Show boxes (or the host's hook)
        if isempty(options.HiddenFaces)
            flagHidden = false(numFaces,1);
            labelKeysHidden = setdiff(hiddenKeys, {'hidden'}, 'stable');
            for ith_key = 1:numel(labelKeysHidden)
                flagHidden = flagHidden | fcn_INTERNAL_labelFaces(data.Mesh, labelKeysHidden{ith_key});
            end
            % (a face with several labels, such as a lamp's clear cover,
            % a light that is also glass, stays while any of them is shown)
            if any(flagHidden) && isfield(data.Mesh,'LabelFaceAlsoParts')
                shownKeys = setdiff(fcn_INTERNAL_labelKinds(data.Mesh, false), labelKeysHidden);
                for ith_key = 1:numel(shownKeys)
                    flagHidden = flagHidden & ~fcn_INTERNAL_labelFaces(data.Mesh, shownKeys{ith_key});
                end
            end
            % (hidden faces, LabelFaceHiddenSet: out of view unless "hidden" is
            % ticked; Sean, 04:17)
            if any(strcmp(hiddenKeys, 'hidden'))
                flagHidden = flagHidden | fcn_INTERNAL_labelFaces(data.Mesh, 'hidden');
            end
        else
            flagHidden = options.HiddenFaces(hiddenKeys);
        end
        flagHidden = logical(flagHidden(:));
    end

    %% For a host's panels (the painter's: Sean, 10:24)
    function setUncolored(keysIn)
        % Labels drawn plain gray ("Colored? No"); {} colors every label
        if isempty(keysIn)
            uncoloredKeys = {};
        else
            uncoloredKeys = reshape(cellstr(keysIn), 1, []);
        end
        redraw();
        refreshOwn();
    end

    % (getters as nested functions: an anonymous function would keep the
    % value it was made with)
    function keys = getUncolored()
        keys = uncoloredKeys;
    end

    function flagOn = getFlagShowEdges()
        flagOn = flagShowEdges;
    end

    function modeOut = getColors()
        modeOut = colorsMode;
    end

    function typesOut = getLampTypes()
        typesOut = fcn_INTERNAL_lampTypes(data.Mesh);
    end

    function flagOn = getTurnWithPhoto()
        flagOn = flagTurnWithPhoto;
    end

    function heightOut = getPhotoHeight()
        heightOut = photoHeight;
    end

    function folderOut = getPhotoFolder()
        folderOut = photoFolder;
    end

    function kinds = getLabelKinds()
        % The labels of the mesh: their keys and names, in the list's order
        kinds = struct('Keys', {labelKeys}, 'Names', {labelNames});
    end

    function setTurnWithPhoto(flagOn)
        flagTurnWithPhoto = logical(flagOn);
        markPhotoOptions();
    end

    function setTurnPhotoWithModel(flagOn)
        % Turning the model moves the dial's arrow and the photo (On), or
        % leaves them where they are (Off)
        flagTurnPhotoWithModel = logical(flagOn);
        if flagTurnPhotoWithModel && ~isempty(axesHandle) && isvalid(axesHandle)
            [azimuth, ~] = fcn_INTERNAL_cameraAngles(axesHandle);
            setDialAngle(azimuth - 90, false, false);
        end
        markPhotoOptions();
    end

    function flagOn = getTurnPhotoWithModel()
        flagOn = flagTurnPhotoWithModel;
    end

    function setPhotoFolder(folderIn)
        % Photos from another folder (ViewInDegrees_<angle> files)
        folderIn = char(folderIn);
        if isempty(photoSet) || ~isfolder(folderIn)
            setHint(sprintf('No folder %s', folderIn));
            return;
        end
        listing = [dir(fullfile(folderIn,'*.jpg')); dir(fullfile(folderIn,'*.jpeg')); dir(fullfile(folderIn,'*.png'))];
        newSet = fcn_INTERNAL_photoAngles(fullfile(folderIn, {listing.name}));
        if isempty(newSet)
            setHint(sprintf('No ViewInDegrees_<angle> photos in %s: the photos are not changed.', folderIn));
            return;
        end
        photoFolder = folderIn;
        photoSet = newSet;
        photoIndex = 0;
        cla(dialAxes);
        [dialArrow, dialDots] = fcn_INTERNAL_drawDial(dialAxes, data, [photoSet.Angle]);
        try
            photoInfo = imfinfo(photoSet(1).File);
            photoAspect = photoInfo(1).Width/photoInfo(1).Height;
        catch
        end
        setPhotoHeight(photoHeight);
        [azimuth, ~] = fcn_INTERNAL_cameraAngles(axesHandle);
        setDialAngle(azimuth - 90, false, false);
        markPhotoOptions();
    end

    function makePhotoOptions()
        % Under the photo: its folder, whether the model turns with it,
        % and its size (the photo's working options, at the photo's side)
        blue = [0.93 0.95 1];
        optionsPanel = uipanel(photoColumn, 'Title', 'Photo', 'FontWeight', 'bold', 'BackgroundColor', blue);
        optionsPanel.Layout.Row = 2;
        photoColumn.RowSpacing = 6;
        optionsGrid = uigridlayout(optionsPanel, [4 3], 'RowHeight', {24, 24, 24, '1x'}, 'ColumnWidth', {150, '1x', 80}, ...
            'Padding', [6 6 6 6], 'RowSpacing', 6, 'BackgroundColor', blue, 'Scrollable', 'on');
        uilabel(optionsGrid, 'Text', 'Photo folder', 'Tooltip', 'Where the ViewInDegrees_<angle> photos are');
        photoFolderLabel = uilabel(optionsGrid, 'Text', '', 'FontColor', [0.3 0.3 0.3], 'Tag', 'photoOptionsFolder');
        uibutton(optionsGrid, 'Text', 'Browse...', 'Tooltip', 'Pick another folder of ViewInDegrees_<angle> photos', 'Tag', 'photoOptionsBrowse', ...
            'ButtonPushedFcn', @(~,~) browsePhotoFolder());
        uilabel(optionsGrid, 'Text', 'Turn model with photo', ...
            'Tooltip', 'On: picking a photo on the dial turns the model to the same side');
        turnGroup = uibuttongroup(optionsGrid, 'BorderType', 'none', 'BackgroundColor', blue, 'Tag', 'photoOptionsTurn', ...
            'SelectionChangedFcn', @(~,event) setTurnWithPhoto(strcmp(event.NewValue.Text, 'On')));
        turnGroup.Layout.Column = [2 3];
        uiradiobutton(turnGroup, 'Text', 'Off', 'Position', [2 1 52 22], 'UserData', false);
        uiradiobutton(turnGroup, 'Text', 'On', 'Position', [54 1 52 22], 'UserData', true);
        uilabel(optionsGrid, 'Text', 'Photo size', 'Tooltip', 'The photo''s height (its corner can also be dragged)');
        sizeGroup = uibuttongroup(optionsGrid, 'BorderType', 'none', 'BackgroundColor', blue, 'Tag', 'photoOptionsSize', ...
            'SelectionChangedFcn', @(~,event) setPhotoHeight(event.NewValue.UserData));
        sizeGroup.Layout.Column = [2 3];
        uiradiobutton(sizeGroup, 'Text', 'Small', 'Position', [2 1 64 22], 'UserData', 220);
        uiradiobutton(sizeGroup, 'Text', 'Medium', 'Position', [68 1 74 22], 'UserData', 300);
        uiradiobutton(sizeGroup, 'Text', 'Large', 'Position', [144 1 64 22], 'UserData', 420);
        uiradiobutton(sizeGroup, 'Text', '', 'Position', [210 1 10 22], 'UserData', NaN, 'Visible', 'off');   % (dragged to another size)
        markPhotoOptions();
    end

    function browsePhotoFolder()
        folderOut = uigetdir(photoFolder, 'Folder of ViewInDegrees_<angle> photos');
        if ischar(folderOut)
            setPhotoFolder(folderOut);
        end
    end

    function markPhotoOptions()
        % (the photo options showing the state: Overall Display's, and
        % those under the photo for a host that asked for them)
        if ~isempty(displayPanels)
            displayPanels.MarkOverall();
        end
        if isempty(photoFolderLabel) || ~isvalid(photoFolderLabel)
            return;
        end
        [parentFolder, leaf] = fileparts(photoFolder);
        [~, vehicleLeaf] = fileparts(parentFolder);
        photoFolderLabel.Text = ['...' filesep vehicleLeaf filesep leaf];
        photoFolderLabel.Tooltip = photoFolder;
        turnGroup = findobj(photoColumn, 'Tag', 'photoOptionsTurn');
        onOffText = 'Off';
        if flagTurnWithPhoto
            onOffText = 'On';
        end
        turnGroup.SelectedObject = findobj(turnGroup.Children, 'Text', onOffText);
        sizeGroup = findobj(photoColumn, 'Tag', 'photoOptionsSize');
        radios = sizeGroup.Children;
        match = arrayfun(@(radio) isequal(radio.UserData, photoHeight), radios);
        if ~any(match)
            match = arrayfun(@(radio) isnan(radio.UserData), radios);
        end
        sizeGroup.SelectedObject = radios(find(match, 1));
    end

    %% The view settings
    function settings = getView()
        % The view now: the camera, the label shown, the labels hidden,
        % the colors, and the photo
        settings = struct('MeshFile', viewSource, 'Camera', [], 'Label', currentKey, 'Hidden', {hiddenKeys}, ...
            'Colors', colorsMode, 'PhotoAngle', getPhotoAngle(), 'SeeThrough', bodySeeThrough, ...
            'FlagShowEdges', flagShowEdges, 'FlagNight', flagNight, 'NightLights', nightSignals, ...
            'PhotoHeight', photoHeight);
        if ~isempty(axesHandle) && isvalid(axesHandle)
            settings.Camera = fcn_INTERNAL_getView(axesHandle);
        elseif ~isempty(closedSettings)
            settings = closedSettings;
        end
    end

    function setView(settings)
        % Go to these view settings (fields missing are left as they are;
        % the options given to the call win over them, at the start)
        if isempty(settings)
            settings = struct();
        end
        pendingNight = [];   % (the nighttime view set last, after the camera)
        if isfield(settings, 'Colors') && ~isempty(settings.Colors) && isempty(options.Colors)
            colorsMode = char(settings.Colors);
        end
        if isfield(settings, 'SeeThrough') && ~isempty(settings.SeeThrough)
            bodySeeThrough = min(max(double(settings.SeeThrough), 0), 0.9);
            if ~isempty(seeThroughSlider) && isvalid(seeThroughSlider)
                seeThroughSlider.Value = 100*bodySeeThrough;
            end
        end
        if isfield(settings, 'FlagShowEdges') && ~isempty(settings.FlagShowEdges)
            flagShowEdges = logical(settings.FlagShowEdges);
            if ~isempty(boundaryBox) && isvalid(boundaryBox)
                boundaryBox.Value = flagShowEdges;
            end
        end
        if isfield(settings, 'NightLights') && isstruct(settings.NightLights)
            setNightLights(settings.NightLights);
        end
        if isfield(settings, 'FlagNight') && ~isempty(settings.FlagNight)
            pendingNight = logical(settings.FlagNight);
        end
        if isfield(settings, 'PhotoHeight') && ~isempty(settings.PhotoHeight) && ~isempty(photoColumn)
            setPhotoHeight(max(double(settings.PhotoHeight), dialSize));
        end
        if isfield(settings, 'Hidden') && isempty(options.Hidden)
            hiddenKeys = reshape(cellstr(settings.Hidden), 1, []);
            if isempty(settings.Hidden)
                hiddenKeys = {};
            end
        end
        if isfield(settings, 'Label') && ~isempty(settings.Label) && isempty(options.Label)
            currentKey = char(settings.Label);
        end
        setColors(colorsMode);
        setHidden(hiddenKeys);
        showLabel(currentKey);
        flagCamera = isfield(settings, 'Camera') && isstruct(settings.Camera) && ~isempty(fieldnames(settings.Camera));
        if isfield(settings, 'PhotoAngle') && ~isempty(settings.PhotoAngle) && ~isnan(settings.PhotoAngle)
            % (the photo, without turning the model: the camera below
            % decides the model's view)
            setDialAngle(settings.PhotoAngle, ~flagCamera, true);
        elseif ~isempty(photoSet)
            [azimuth, ~] = fcn_INTERNAL_cameraAngles(axesHandle);
            setDialAngle(azimuth - 90, false, false);
        end
        if flagCamera
            fcn_INTERNAL_setView(axesHandle, settings.Camera);
            drawnow;
            [azimuth, elevation] = fcn_INTERNAL_cameraAngles(axesHandle);
            lastLabelView = [azimuth elevation];
            noteFit();
            notifyView();
        end
        if ~isempty(pendingNight)
            setFlagNight(pendingNight);
        end
    end

    function textOut = viewCall()
        % The MATLAB call that opens exactly this view
        textOut = fcn_INTERNAL_viewCall(getView());
    end

    function textOut = copyViewCall()
        textOut = viewCall();
        flagClipboard = options.FlagClipboard;
        if isempty(flagClipboard)
            flagClipboard = logical(options.FlagVisible);   % (hidden: a test; the user's clipboard is left alone)
        end
        if ~flagClipboard
            setHint('The call that opens this exact view is in the command window.');
            fprintf(1, '%s\n', textOut);
            return;
        end
        try
            clipboard('copy', textOut);
            setHint('The call that opens this exact view is on the clipboard: paste it into MATLAB, or send it.');
        catch
            setHint('The clipboard is not available; the call is in the command window.');
        end
        fprintf(1, '%s\n', textOut);
    end

    function resetView()
        % (the view it opened with: from the front left, the whole vehicle)
        if isempty(startView)
            % (the camera worked out again, from the angles and the vehicle)
            set(axesHandle, 'CameraPositionMode', 'auto', 'CameraTargetMode', 'auto', ...
                'CameraUpVectorMode', 'auto', 'CameraViewAngleMode', 'auto');
            view(axesHandle, startDial + 90, startDown);
            fcn_INTERNAL_frameVehicle(axesHandle, data.Mesh.Vertices);   % (the vehicle, not the ground, fills the view; equal axes)
            axis(axesHandle, 'vis3d');
            drawnow;
            fcn_INTERNAL_freezeCamera(axesHandle);
            startView = fcn_INTERNAL_getView(axesHandle);
        else
            fcn_INTERNAL_setView(axesHandle, startView);
        end
        fitToWindow(false);   % (the whole vehicle, at the window's size now)
        notifyView();
    end

    function fitToWindow(flagKeepZoom)
        % The view angle set so the whole vehicle fits the model's axes at
        % their size now (Sean's T23, 2026-11-24: made narrower, the
        % window cut the vehicle off, since MATLAB's view angle spans the
        % axes' shorter side and was fitted to the first shape). With
        % flagKeepZoom, the user's zoom is kept: the vehicle stays as much
        % larger or smaller than "just fits" as it was.
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        axesSize = axesHandle.InnerPosition(3:4);
        if any(axesSize < 20)
            return;   % (not laid out yet)
        end
        fitTan = fcn_INTERNAL_fitTan(axesHandle, data.Mesh.Vertices, axesSize);
        zoomRatio = 1;
        if flagKeepZoom && all(lastAxesSize >= 20)
            % (the zoom measured from the camera as it is now, at the size
            % the axes had: measured against the fit made at the last
            % resize, a turn or pan since then was counted as zoom, and a
            % vehicle fully in view could be cut off by the next resize;
            % found by the random walks, 2026-11-24)
            fitTanBefore = fcn_INTERNAL_fitTan(axesHandle, data.Mesh.Vertices, lastAxesSize);
            if isfinite(fitTanBefore) && fitTanBefore > 0
                zoomRatio = tand(axesHandle.CameraViewAngle/2)/fitTanBefore;
            end
        elseif flagKeepZoom && isfinite(fitTanLast) && fitTanLast > 0
            zoomRatio = tand(axesHandle.CameraViewAngle/2)/fitTanLast;
        end
        if isfinite(fitTan) && fitTan > 0
            axesHandle.CameraViewAngle = 2*atand(fitTan*zoomRatio);
        end
        fitTanLast = fitTan;
        lastAxesSize = axesSize;
    end

    function noteFit()
        % (a camera set as given, such as a shared view: its zoom kept as
        % is, and measured against "just fits" for later resizing)
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        axesSize = axesHandle.InnerPosition(3:4);
        if any(axesSize < 20)
            lastAxesSize = [-1 -1];   % (not laid out yet: noted at the first size, not refitted)
            return;
        end
        fitTanLast = fcn_INTERNAL_fitTan(axesHandle, data.Mesh.Vertices, axesSize);
        lastAxesSize = axesSize;
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    %% The photo dial
    function onDialDown(~, ~)
        dialDownAt(figureHandle.CurrentPoint);
    end

    function dialDownAt(point)
        % (the mouse pressed on the dial at this point of the window)
        flagDialDragging = true;
        setDialAngle(pointerAngle(point), flagTurnWithPhoto, false);
    end

    function angle = pointerAngle(point)
        % The mouse's angle around the dial's center, from the mouse in the
        % window and the dial's place on the screen (the dial's limits are
        % centered on 0 and its scale is equal, so its center is the
        % middle of its box). Not from the axes' CurrentPoint: after the
        % window is resized, that can lag behind (Sean, 14:02: the arrow
        % moved, but the photo did not change).
        if nargin < 1
            windowHandle = ancestor(dialAxes, 'figure');
            point = windowHandle.CurrentPoint;
        end
        box = getpixelposition(dialAxes, true);
        center = box(1:2) + box(3:4)/2;
        angle = atan2d(point(2) - center(2), point(1) - center(1));
    end

    function setDialAngle(angle, flagTurnModel, flagSnap)
        % Point the arrow at this angle, show the nearest photo, and (if
        % asked) turn the model to the same angle
        if isempty(photoSet) || isempty(dialAxes) || ~isvalid(dialAxes)
            return;
        end
        angle = mod(angle, 360);
        photoAngles = [photoSet.Angle];
        [~, nearestPhoto] = min(abs(mod(photoAngles - angle + 180, 360) - 180));
        if flagSnap
            angle = photoAngles(nearestPhoto);
        end
        fcn_INTERNAL_pointDialArrow(dialArrow, angle);
        if nearestPhoto ~= photoIndex
            photoIndex = nearestPhoto;
            photoImage.ImageSource = photoSet(nearestPhoto).File;
            set(dialDots, 'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerSize', 9);
            set(dialDots(nearestPhoto), 'MarkerFaceColor', [0.85 0 0], 'MarkerSize', 13);
            [~, photoName, photoExtension] = fileparts(photoSet(nearestPhoto).File);
            photoLabel.Text = [photoName photoExtension];
            placePhoto();
        end
        if flagTurnModel && isvalid(axesHandle)
            % (the camera moved around its target to that side, at the same
            % distance; set directly, so it is exact at once: view() leaves
            % the camera to be worked out later)
            flagSyncingView = true;
            target = axesHandle.CameraTarget;
            offset = axesHandle.CameraPosition - target;
            distance = norm(offset);
            elevation = max(5, min(asind(offset(3)/distance), 30));
            azimuth = angle + 90;
            if strcmp(axesHandle.CameraPositionMode, 'auto')
                % (the camera not yet set, as when the viewer opens at a
                % photo: MATLAB works out its distance, to fit the vehicle;
                % the camera's own distance is not right yet then, and the
                % model came up far too close)
                view(axesHandle, azimuth, elevation);
            else
                axesHandle.CameraPosition = target + distance*[sind(azimuth)*cosd(elevation), -cosd(azimuth)*cosd(elevation), sind(elevation)];
                axesHandle.CameraUpVector = [0 0 1];
            end
            drawnow limitrate;
            [azimuth, elevation] = fcn_INTERNAL_cameraAngles(axesHandle);
            lastLabelView = [azimuth elevation];
            flagSyncingView = false;
            notifyView();   % (the readout follows a turn by the dial too: Sean's T22, 2026-11-24)
        end
    end

    function angle = getPhotoAngle()
        angle = NaN;
        if photoIndex > 0
            angle = photoSet(photoIndex).Angle;
        end
    end

    function onModelViewChanged()
        % If the model was rotated, move the arrow (and the photo) with it
        % (and the sun/moon button kept in its corner, which a hidden
        % window's resize does not do by itself)
        if isempty(axesHandle) || ~isvalid(axesHandle) || ~isvalid(figureHandle)
            % (the window is gone: the timer stops itself, so it cannot
            % keep running in the background; one was found running on
            % with no window, 2026-11-23 14:17; it is deleted once stopped)
            if ~isempty(viewTimer) && isvalid(viewTimer)
                viewTimer.StopFcn = @(timerObject,~) delete(timerObject);
                stop(viewTimer);
            end
            viewTimer = [];
            return;
        end
        if flagSyncingView || flagDialDragging || ~flagBuilt
            return;   % (not while the window is still being built: see the end of the build)
        end
        placeDayNight();
        % (the window resized: the photo fitted to the room there is, then
        % the vehicle kept in view, at the same zoom)
        if fitPhotoToWindow()
            drawnow;
            placePhoto();
        end
        axesSize = axesHandle.InnerPosition(3:4);
        if all(axesSize >= 20) && ~isequal(round(axesSize), round(lastAxesSize))
            if isequal(lastAxesSize, [-1 -1])
                noteFit();   % (a given camera, now laid out: its zoom kept)
            else
                fitToWindow(isfinite(fitTanLast));
            end
        end
        [azimuth, elevation] = fcn_INTERNAL_cameraAngles(axesHandle);
        if isequal(round([azimuth elevation],3), round(lastLabelView,3))
            return;
        end
        lastLabelView = [azimuth elevation];
        if flagTurnPhotoWithModel
            setDialAngle(azimuth - 90, false, false);   % (Turn photo with model? On: the dial and the photo follow)
        end
        notifyView();
    end

    function notifyView()
        % (the camera moved: a host's readout, and its own window's)
        if ~isempty(options.OnView)
            options.OnView();
        end
        if ~isempty(displayPanels)
            displayPanels.MarkCamera();
        end
    end

    function camera = getCameraInfo()
        % The camera now: its angle on the photo dial (0 the front, 90 the
        % left side), how far it looks down, and its distance from the
        % point it looks at (Sean's T7, 2026-11-24)
        camera = struct('DialAngle', NaN, 'DownAngle', NaN, 'Distance', NaN);
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        [azimuth, elevation] = fcn_INTERNAL_cameraAngles(axesHandle);
        camera.DialAngle = mod(azimuth - 90, 360);
        camera.DownAngle = elevation;
        camera.Distance = norm(axesHandle.CameraPosition - axesHandle.CameraTarget);
    end

    function stopTimer()
        if ~isempty(viewTimer) && isvalid(viewTimer)
            try
                stop(viewTimer);
                delete(viewTimer);
            catch
                % (deleted meanwhile: a window closed while the timer ran;
                % "Invalid timer object" from a patch's DeleteFcn, 2026-11-26)
            end
        end
        viewTimer = [];
    end

    %% The photo: its size, its name, its resize handle
    function flagUsed = gripDown()
        % (the mouse pressed on the photo's corner mark: the photo is
        % resized while it moves; for a host window's mouse-down too)
        flagUsed = false;
        if isempty(photoGrip) || ~isvalid(photoGrip)
            return;
        end
        point = figureHandle.CurrentPoint;
        box = getpixelposition(photoGrip, true);
        flagUsed = point(1) >= box(1) - 4 && point(1) <= box(1) + box(3) + 4 && ...
            point(2) >= box(2) - 4 && point(2) <= box(2) + box(4) + 4;
        flagPhotoResizing = flagUsed;
    end

    function resizePhoto()
        % The photo's top right corner stays; its bottom left corner
        % follows the mouse, the photo's shape kept, from the dial's size
        % up to the full height (the model keeps at least 220 pixels)
        if isempty(photoColumn) || ~isvalid(photoColumn)
            return;
        end
        point = figureHandle.CurrentPoint;
        columnBox = getpixelposition(photoColumn, true);
        layoutBox = getpixelposition(layout, true);
        rightEdge = columnBox(1) + columnBox(3);
        topEdge = columnBox(2) + columnBox(4);
        newWidth = max(rightEdge - point(1), (topEdge - point(2))*photoAspect);
        newWidth = min(newWidth, min(layoutBox(3) - dialWidth - 220, layoutBox(4)*photoAspect));
        newWidth = max(newWidth, dialSize*photoAspect);
        setPhotoHeight(newWidth/photoAspect);
        drawnow limitrate;
    end

    function setPhotoHeight(newHeight)
        % The photo this tall (and as wide as its shape needs); the dial
        % kept level with its middle
        if isempty(photoColumn) || ~isvalid(photoColumn)
            return;
        end
        photoHeight = newHeight;
        fitPhotoToWindow();
        markPhotoOptions();
    end

    function flagChanged = fitPhotoToWindow()
        % The photo shown at the height asked for (photoHeight), but no
        % taller than the window has room for, and no wider than leaves
        % the model 220 pixels; in a window too small for even a small
        % photo, the photo and the dial are left out until it is larger.
        % (Found by the layout tests, 2026-11-24: a Large photo in an
        % 800 x 500 window was cut off at the bottom, and in a 640 x 400
        % window the photo and dial took all the width, leaving the model
        % none.) The height asked for is kept, for when the window grows.
        flagChanged = false;
        if isempty(photoColumn) || ~isvalid(photoColumn) || isempty(layout) || ~isvalid(layout)
            return;
        end
        layoutBox = layout.Position;
        if layoutBox(3) < 50 || layoutBox(4) < 50
            return;   % (not laid out yet: fitted at the next check)
        end
        shownHeight = min([photoHeight, layoutBox(4), (layoutBox(3) - dialWidth - 2*layout.ColumnSpacing - 220)/photoAspect]);
        if shownHeight < 120
            % (no room: the photo and the dial left out)
            newWidths = {'1x', 0, 0};
            shownHeight = max(0, min(120, layoutBox(4) - 1));
        else
            newWidths = {'1x', dialWidth, shownHeight*photoAspect};
        end
        shownDial = min(dialSize, shownHeight);
        newDialRows = {max(0, (shownHeight - shownDial)/2), shownDial, '1x'};
        flagShown = ~isequal(newWidths{2}, 0);
        if ~isequal(layout.ColumnWidth, newWidths) || ~isequal(photoColumn.RowHeight{1}, shownHeight) || ~isequal(dialGrid.RowHeight, newDialRows)
            layout.ColumnWidth = newWidths;
            photoColumn.RowHeight{1} = shownHeight;
            dialGrid.RowHeight = newDialRows;
            % (left out: hidden too, so nothing of them is drawn squeezed)
            photoColumn.Visible = matlab.lang.OnOffSwitchState(flagShown);
            dialGrid.Visible = matlab.lang.OnOffSwitchState(flagShown);
            flagChanged = true;
        end
    end

    function placePhoto()
        % The photo filling its box, its name at the top right, the
        % handle at the bottom left
        placeDayNight();   % (the sun/moon button too: this runs at every layout change, and a hidden window does not call the model panel's SizeChangedFcn)
        if isempty(photoPanel) || ~isvalid(photoPanel)
            return;
        end
        box = photoPanel.InnerPosition;
        photoImage.Position = [1 1 max(box(3),1) max(box(4),1)];
        nameWidth = min(max(box(3) - 8, 40), 8*numel(photoLabel.Text) + 18);
        photoLabel.Position = [max(box(3) - nameWidth - 4, 1), max(box(4) - 26, 1), nameWidth, 22];
        photoGrip.Position = [2 2 26 26];
    end

    %% The nighttime view
    function setFlagNight(flagOn)
        flagOn = logical(flagOn);
        if ~isempty(nightBox) && isvalid(nightBox)
            nightBox.Value = flagOn;
        end
        if flagOn == flagNight
            return;
        end
        flagNight = flagOn;
        if flagNight
            enterNight();
        else
            leaveNight();
        end
        markDayNight();
        refreshOwn();   % (Colors? and see-through: by day only; the status line)
        if ~isempty(options.OnNight)
            options.OnNight(flagNight);   % (a host's own panels follow)
        end
    end

    %% Hooks for the lamp-functions window (fcn_CarMesh3D_editLampFunctions)
    function setLampFunctions(tableIn)
        % The lamp-to-function matrix the lamps light by (the window's,
        % as it is edited): the lamps drawn again with it
        data.Mesh.LampFunctions = tableIn;
        if flagNight
            buildNight();
        else
            redraw();
        end
    end

    function setLampSignals(signalsIn)
        % The lamps lit by these signals, each 0 to 1 (fields named as
        % fcn_CarMesh3D_lampSignals; missing ones off), Parking and Brake
        % included: every other lamp off
        amountOf = @(name) isfield(signalsIn, name) && double(signalsIn.(name)) > 0;
        statesNew = struct('LowBeam', amountOf('LowBeam'), 'HighBeam', amountOf('HighBeam'), ...
            'Running', amountOf('Running'), 'TurnLeft', amountOf('TurnLeft'), 'TurnRight', amountOf('TurnRight'), ...
            'Tail', amountOf('Tail'), 'Backup', amountOf('Backup'), 'Fog', amountOf('Fog'), 'Hazards', false, ...
            'Reflectors', double(amountOf('Reflectors')), 'Parking', amountOf('Parking'), 'Brake', amountOf('Brake'));
        statesNew.Hazards = statesNew.TurnLeft && statesNew.TurnRight;
        nightSignals = statesNew;
        flagLampsSet = true;
        showNightLights();
    end

    function outlineFaces(faces)
        % These faces outlined in cyan (the lamps the edited signal
        % lights); [] for none
        delete(findobj(axesHandle, 'Tag', 'lampOutline'));
        if isempty(faces) || isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        patch(axesHandle, 'Faces', data.Mesh.Faces(faces(:),:), 'Vertices', data.Mesh.Vertices, ...
            'FaceColor', 'none', 'EdgeColor', [0 1 1], 'LineWidth', 1.5, 'HitTest', 'off', 'Clipping', 'off', ...
            'Tag', 'lampOutline');
    end

    function lampSetup = currentLampSetup()
        % The lamp units and matrix of the mesh shown
        % (fcn_CarMesh3D_lampSetup), made again only when its lamp labels,
        % covers or matrix change (a tenth of a second, not every redraw)
        lampKey = {size(data.Mesh.Faces,1), [], [], []};
        if isfield(data.Mesh, 'LabelFaceLamp')
            lampKey{2} = data.Mesh.LabelFaceLamp(:);
        end
        if isfield(data.Mesh, 'LabelFaceCoverLamp')
            lampKey{3} = data.Mesh.LabelFaceCoverLamp(:);
        end
        if isfield(data.Mesh, 'LampFunctions')
            lampKey{4} = data.Mesh.LampFunctions;
        end
        if isempty(lampSetupCache) || ~isequal(lampKey, lampSetupKey)
            lampSetupCache = fcn_CarMesh3D_lampSetup(data.Mesh, FigNum=-1);
            lampSetupKey = lampKey;
        end
        lampSetup = lampSetupCache;
    end

    function toggleDayNight()
        % The sun/moon button: day to night, or night to day
        setFlagNight(~flagNight);
    end

    function placeDayNight()
        % The sun/moon button in the model's top right corner (when no top
        % bar holds it)
        if isempty(dayNightButton) || ~isvalid(dayNightButton) || dayNightButton.Parent ~= modelHolder
            return;
        end
        holderSize = modelHolder.InnerPosition(3:4);
        buttonSize = 36;
        newPosition = [max(1, holderSize(1) - buttonSize - 8), max(1, holderSize(2) - buttonSize - 8), buttonSize, buttonSize];
        if ~isequal(dayNightButton.Position, newPosition)
            dayNightButton.Position = newPosition;
        end
    end

    function markQuickBar()
        % (the Mesh and Grid buttons show the settings now, however they
        % were changed: the button, Overall Display, or a hook)
        if ~isempty(meshToggle) && isvalid(meshToggle) && meshToggle.Value ~= flagShowEdges
            meshToggle.Value = flagShowEdges;
        end
        if ~isempty(groundToggle) && isvalid(groundToggle) && groundToggle.Value ~= flagGround
            groundToggle.Value = flagGround;
        end
    end

    function markDayNight()
        % The button shows the sun by day, the moon at night
        if isempty(dayNightButton) || ~isvalid(dayNightButton)
            return;
        end
        if flagNight
            set(dayNightButton, 'Text', char(9790), 'BackgroundColor', [0.12 0.14 0.22], 'FontColor', [0.95 0.93 0.75], ...
                'Tooltip', 'Night (click for day)');
        else
            set(dayNightButton, 'Text', char(9728), 'BackgroundColor', [1 1 1], 'FontColor', [0.85 0.55 0.05], ...
                'Tooltip', 'Day (click for night)');
        end
    end

    function enterNight()
        % The night scene of the animator's lights check
        % (fcn_CarMesh3D_animateChecks): a dark checkered ground and sky,
        % a faint light from above, and the vehicle drawn by
        % fcn_CarMesh3D_plotVehicle with its lamps lit as the lamp list
        % says, their glows, and the light on the ground. The camera stays
        % where it is (the ground reaches past the axes' box, unclipped).
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        % (the camera frozen where it is, so the night scene does not move
        % it; NOT kept as the starting view: Reset view at night then went
        % to where the camera was when night fell, not to the starting
        % view; found by a random walk, 2026-11-24)
        fcn_INTERNAL_freezeCamera(axesHandle);
        if ~flagLampsSet
            % (the first night, with no lamps set: every lamp on)
            nightSignals = struct('LowBeam', true, 'HighBeam', true, 'Running', true, 'TurnLeft', true, ...
                'TurnRight', true, 'Tail',true, 'Brake', true, 'Backup', true, 'Fog', true, 'Hazards', true, 'Reflectors', 1);
            flagLampsSet = true;
            showNightLights();
        end
        dayLights = findobj(axesHandle, 'Type', 'light');
        set(dayLights, 'Visible', 'off');
        meshPatch.Visible = 'off';
        if ~isempty(dayGround) && isvalid(dayGround)
            dayGround.Visible = 'off';   % (the night ground instead)
        end
        nightSky = [0.04 0.05 0.09];
        axesHandle.Color = nightSky;
        modelHolder.BackgroundColor = nightSky;
        % (the night scene kept from the last night, shown again if nothing
        % it was built from has changed; else built anew: Sean, 12:49, day
        % to night took about 1 s, rebuilding the whole scene each time)
        if ~isempty(nightObjects) && all(isvalid(nightObjects)) && isequal(nightKey, currentNightKey())
            for ith_object = 1:numel(nightObjects)
                nightObjects(ith_object).Visible = nightVisible{ith_object};
            end
            fcn_CarMesh3D_plotVehicle(data.Mesh, 'PlotHandles', nightHandles, 'Signals', nightSignals);   % (the lamps as switched by day)
            nightEdges();
        else
            buildNight();
        end
        nightHint = ['<b>Nighttime view:</b> switch the lamps in Lamps To Display (' char(9776) ' Menu); set a label''s ' ...
            'Shown? to No to take it away (the glass over a lamp, say).'];
        if ~isempty(options.HiddenFaces)
            nightHint = [nightHint ' Paint by day: turn the nighttime view off.'];   % (inside the painter)
        end
        setHint(nightHint);
    end

    function buildNight()
        % The night scene's objects, made (again): the vehicle without
        % the faces the Show boxes hide
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        cameraNow = fcn_INTERNAL_getView(axesHandle);
        delete(nightObjects(isvalid(nightObjects)));
        before = axesHandle.Children;
        if flagGround
            fcn_INTERNAL_ground(axesHandle, data.Mesh.Vertices, 'night');
        end
        light(axesHandle, 'Style', 'infinite', 'Position', [0.3 -0.5 1], 'Color', [0.22 0.22 0.26]);
        shownMesh = fcn_INTERNAL_keepFaces(data.Mesh, ~hiddenFaceFlags());
        if isfield(shownMesh, 'LabelFaceHiddenSet')
            shownMesh.LabelFaceHiddenSet(:) = 0;   % (the Show boxes decided which faces are drawn)
        end
        nightHandles = fcn_CarMesh3D_plotVehicle(shownMesh, 'Finish', 'matte', 'FlagLightEffects', true, ...
            'SceneLights', 'none', 'Signals', nightSignals, 'AxesHandle', axesHandle);
        nightObjects = setdiff(axesHandle.Children, before);
        nightKey = currentNightKey();
        set(findobj(nightObjects, '-property', 'HitTest'), 'HitTest', 'off');
        set(findobj(nightObjects, '-property', 'Clipping'), 'Clipping', 'off');
        nightEdges();
        fcn_INTERNAL_setView(axesHandle, cameraNow);   % (the camera as it was)
    end

    function leaveNight()
        % (the night scene put away, not deleted: shown again at the next
        % night if nothing it was built from changes; each object's own
        % Visible kept, as the glows and pools are on or off by the lamps)
        nightObjects = nightObjects(isvalid(nightObjects));
        nightVisible = arrayfun(@(object) object.Visible, nightObjects, 'UniformOutput', false);
        set(nightObjects, 'Visible', 'off');
        set(dayLights(isvalid(dayLights)), 'Visible', 'on');
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        meshPatch.Visible = 'on';
        if ~isempty(dayGround) && isvalid(dayGround)
            dayGround.Visible = matlab.lang.OnOffSwitchState(flagGround);
        end
        axesHandle.Color = [1 1 1];
        modelHolder.BackgroundColor = [1 1 1];
        redraw();
    end

    function key = currentNightKey()
        % (what the night scene is built from: the mesh's labels and colors,
        % the lamp matrix, the faces shown, and the ground)
        key = {size(data.Mesh.Faces, 1), flagGround, hiddenFaceFlags()};
        for name = {'LabelFaceLamp', 'LabelFacePart', 'FaceColors', 'FaceAlpha', 'LabelFaceCoverLamp', 'LabelFaceAlsoParts', 'LabelFaceAlsoLamps', 'LampFunctions', 'Vertices'}
            if isfield(data.Mesh, name{1})
                key{end+1} = data.Mesh.(name{1}); %#ok<AGROW>
            else
                key{end+1} = []; %#ok<AGROW>
            end
        end
    end

    function nightEdges()
        % "Show mesh boundaries" in the nighttime view: the vehicle's
        % faces' edges (not the ground's, nor the glows')
        if isempty(nightHandles) || ~isfield(nightHandles, 'Patches')
            return;
        end
        vehiclePatches = [nightHandles.Patches{:}];
        if isempty(vehiclePatches)
            return;   % (every label set Shown? No at night: no vehicle drawn; found by the tests, 2026-11-24)
        end
        vehiclePatches = vehiclePatches(isvalid(vehiclePatches));
        if flagShowEdges
            set(vehiclePatches, 'EdgeColor', [0.6 0.6 0.65], 'EdgeAlpha', 0.35, 'LineWidth', 0.25);
        else
            set(vehiclePatches, 'EdgeColor', 'none');
        end
    end

    function flagOn = getFlagNight()
        flagOn = flagNight;
    end

    function statesOut = getNightLights()
        statesOut = nightSignals;
    end

    function setNightLights(statesIn)
        % The lamps switched on (fields missing are left as they are)
        flagLampsSet = true;
        for name = fieldnames(statesIn)'
            if isfield(nightSignals, name{1})
                nightSignals.(name{1}) = statesIn.(name{1});
            end
        end
        % (hazards on means both turn signals on, as plotVehicle draws them,
        % so the turn boxes show what is lit)
        if logical(nightSignals.Hazards)
            nightSignals.TurnLeft = true;
            nightSignals.TurnRight = true;
        end
        showNightLights();
    end

    function showNightLights()
        % The lamp list set from the states, and the lamps switched
        if isfield(nightControls, 'LowBeam') && isvalid(nightControls.LowBeam)
            nightControls.LowBeam.Value = logical(nightSignals.LowBeam);
            nightControls.HighBeam.Value = logical(nightSignals.HighBeam);
            nightControls.Running.Value = logical(nightSignals.Running);
            nightControls.TurnLeft.Value = logical(nightSignals.TurnLeft);
            nightControls.TurnRight.Value = logical(nightSignals.TurnRight);
            nightControls.Hazards.Value = logical(nightSignals.TurnLeft) && logical(nightSignals.TurnRight);
            nightControls.Fog.Value = logical(nightSignals.Fog);
            nightControls.Reflectors.Value = nightSignals.Reflectors > 0;
            tailChoice = 'off';   % (the three choices map to the true/false Tail and Brake)
            if isfield(nightSignals, 'Brake') && logical(nightSignals.Brake)
                tailChoice = 'brake';
            elseif logical(nightSignals.Tail)
                tailChoice = 'on';
            end
            nightControls.Tail.SelectedObject = findobj(nightControls.Tail.Children, 'UserData', tailChoice);
            nightControls.Backup.Value = logical(nightSignals.Backup);
        end
        if flagNight && ~isempty(nightHandles) && isfield(nightHandles, 'Transform') && isvalid(nightHandles.Transform)
            fcn_CarMesh3D_plotVehicle(data.Mesh, 'PlotHandles', nightHandles, 'Signals', nightSignals);
        elseif ~flagNight
            redraw();   % (by day: the lamps lit on the model)
        end
        if ~isempty(options.OnLamps)
            options.OnLamps(nightSignals);
        end
        if ~isempty(displayPanels)
            displayPanels.MarkLamps(nightSignals);   % (its own window's Lamps To Display)
        end
    end

    function setNightLamp(name, value)
        % One lamp switched from the list
        flagLampsSet = true;
        switch name
            case 'Hazards'
                % (both turn signals, and the warning lamps)
                nightSignals.TurnLeft = logical(value);
                nightSignals.TurnRight = logical(value);
                nightSignals.Hazards = logical(value);
            case 'Reflectors'
                nightSignals.Reflectors = double(logical(value));   % (the list's box: none or full outside light)
            case {'TurnLeft', 'TurnRight'}
                % (one turn signal: the hazards are on only while both
                % are, since plotVehicle lights both turn signals while
                % Hazards is on; without this, unticking one turn signal
                % left it and its glow on the ground lit; Sean, 2026_11_24 00:57)
                nightSignals.(name) = logical(value);
                nightSignals.Hazards = logical(nightSignals.TurnLeft) && logical(nightSignals.TurnRight);
            case 'All'
                if value
                    nightSignals = struct('LowBeam', true, 'HighBeam', true, 'Running', true, 'TurnLeft', true, ...
                        'TurnRight', true, 'Tail',true, 'Brake', true, 'Backup', true, 'Fog', true, 'Hazards', true, 'Reflectors', 1);
                else
                    nightSignals = struct('LowBeam', false, 'HighBeam', false, 'Running', false, 'TurnLeft', false, ...
                        'TurnRight', false, 'Tail',false, 'Brake', false, 'Backup', false, 'Fog', false, 'Hazards', false, 'Reflectors', 0);
                end
            case 'Tail'
                % (the Tail choice: 'off', 'on' or 'brake'; brake lights the
                % tail lamps too)
                nightSignals.Tail = any(strcmp(value, {'on', 'brake'}));
                nightSignals.Brake = strcmp(value, 'brake');
            otherwise
                nightSignals.(name) = value;
        end
        showNightLights();
    end

    function makeLampList()
        % The lamp list of the nighttime view, under the label list (shown
        % in its place): each lamp the animator can switch, even one with
        % no labeled faces (its light on the ground still shows)
        if isempty(listInner) || ~isvalid(listInner)
            return;
        end
        lampTypes = fcn_INTERNAL_lampTypes(data.Mesh);
        lampPanel = uipanel(listInner, 'Title', 'Lamps', 'Scrollable', 'on');
        lampPanel.Layout.Row = 2;
        lampGrid = uigridlayout(lampPanel, [14 1], 'RowHeight', {20, 22, 22, 22, 22, 22, 22, 20, 28, 22, 22, 22, 30, 60}, ...
            'Padding', [8 6 8 6], 'RowSpacing', 4, 'Scrollable', 'on');
        % (the grid scrolls, not the panel: a grid fills its panel and
        % squeezes its rows, so a scrollable panel around it never
        % scrolls and the bottom rows were cut off; rule: every panel
        % scrolls up and down, Sean, 2026_11_24 00:58)
        uilabel(lampGrid, 'Text', 'Headlights', 'FontWeight', 'bold');
        nightControls.LowBeam = uicheckbox(lampGrid, 'Tag', 'nightLamp_LowBeam', 'Text', 'Low beams', ...
            'ValueChangedFcn', @(source,~) setNightLamp('LowBeam', source.Value));
        nightControls.HighBeam = uicheckbox(lampGrid, 'Tag', 'nightLamp_HighBeam', 'Text', 'High beams', ...
            'ValueChangedFcn', @(source,~) setNightLamp('HighBeam', source.Value));
        nightControls.Running = uicheckbox(lampGrid, 'Tag', 'nightLamp_Running', 'Text', 'Running lights', ...
            'ValueChangedFcn', @(source,~) setNightLamp('Running', source.Value));
        nightControls.TurnLeft = uicheckbox(lampGrid, 'Tag', 'nightLamp_TurnLeft', 'Text', 'Left turn signal', ...
            'ValueChangedFcn', @(source,~) setNightLamp('TurnLeft', source.Value));
        nightControls.TurnRight = uicheckbox(lampGrid, 'Tag', 'nightLamp_TurnRight', 'Text', 'Right turn signal', ...
            'ValueChangedFcn', @(source,~) setNightLamp('TurnRight', source.Value));
        nightControls.Hazards = uicheckbox(lampGrid, 'Tag', 'nightLamp_Hazards', 'Text', 'Hazards', 'Tooltip', 'Both turn signals at once', ...
            'ValueChangedFcn', @(source,~) setNightLamp('Hazards', source.Value));
        tailLabel = uilabel(lampGrid, 'Text', 'Tail lights', 'FontWeight', 'bold');
        nightControls.Tail = uibuttongroup(lampGrid, 'BorderType', 'none', 'Tag', 'nightLamp_Tail', ...
            'SelectionChangedFcn', @(~,event) setNightLamp('Tail', event.NewValue.UserData));
        uiradiobutton(nightControls.Tail, 'Text', 'Off', 'Position', [2 3 50 22], 'UserData', 'off');
        uiradiobutton(nightControls.Tail, 'Text', 'On', 'Position', [56 3 50 22], 'UserData', 'on');
        uiradiobutton(nightControls.Tail, 'Text', 'Brake', 'Position', [110 3 70 22], 'UserData', 'brake');
        nightControls.Backup = uicheckbox(lampGrid, 'Tag', 'nightLamp_Backup', 'Text', 'Backup lights', ...
            'ValueChangedFcn', @(source,~) setNightLamp('Backup', source.Value));
        % (fog lamps, and reflectors lit by outside light: Sean, task 8)
        nightControls.Fog = uicheckbox(lampGrid, 'Tag', 'nightLamp_Fog', 'Text', 'Fog lamps', ...
            'ValueChangedFcn', @(source,~) setNightLamp('Fog', source.Value));
        nightControls.Reflectors = uicheckbox(lampGrid, 'Tag', 'nightLamp_Reflectors', 'Text', 'Reflectors lit (outside light)', ...
            'Tooltip', 'The reflectors as another car''s headlights light them', ...
            'ValueChangedFcn', @(source,~) setNightLamp('Reflectors', source.Value));
        buttonGrid = uigridlayout(lampGrid, [1 2], 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
        uibutton(buttonGrid, 'Text', 'All on', 'ButtonPushedFcn', @(~,~) setNightLamp('All', true), 'Tag', 'nightLampsAllOn');
        uibutton(buttonGrid, 'Text', 'All off', 'ButtonPushedFcn', @(~,~) setNightLamp('All', false), 'Tag', 'nightLampsAllOff');
        nightControls.Note = uilabel(lampGrid, 'Text', ['Lit on the model by day; at night, with their light. ' ...
            'Marker lamps light with the running lights, the license plate lamp with the tail lights, ' ...
            'warning lamps with the hazards. "no faces": none labeled; its light still shows.'], ...
            'WordWrap', 'on', 'VerticalAlignment', 'top', 'FontColor', [0.4 0.4 0.4], 'FontSize', 11);
        % (every lamp can be switched; those with no labeled faces say so)
        noFaces = ' (no faces)';
        if ~any(strcmp(lampTypes, 'headlamp'))
            nightControls.LowBeam.Text = [nightControls.LowBeam.Text noFaces];
        end
        if ~any(strcmp(lampTypes, 'highBeamLamp'))
            % (no high beam lamps: the headlights light white for them)
            nightControls.HighBeam.Text = [nightControls.HighBeam.Text ' (in the headlights)'];
            if ~any(strcmp(lampTypes, 'headlamp'))
                nightControls.HighBeam.Text = ['High beams' noFaces];
            end
        end
        if ~any(strcmp(lampTypes, 'runningLamp'))
            nightControls.Running.Text = [nightControls.Running.Text noFaces];
        end
        if ~any(strcmp(lampTypes, 'turnSignalLamp'))
            nightControls.TurnLeft.Text = [nightControls.TurnLeft.Text noFaces];
            nightControls.TurnRight.Text = [nightControls.TurnRight.Text noFaces];
            nightControls.Hazards.Text = [nightControls.Hazards.Text noFaces];
        end
        if ~any(strcmp(lampTypes, 'tailBrakeLamp'))
            tailLabel.Text = ['Tail lights' noFaces];
        end
        if ~any(strcmp(lampTypes, 'backupLamp'))
            nightControls.Backup.Text = [nightControls.Backup.Text noFaces];
        end
        if ~any(strcmp(lampTypes, 'fogLamp'))
            nightControls.Fog.Text = [nightControls.Fog.Text noFaces];
        end
        if ~any(strcmp(lampTypes, 'reflector'))
            nightControls.Reflectors.Text = [nightControls.Reflectors.Text noFaces];
        end
        showNightLights();
    end

    %% The mesh's boundaries
    function setFlagShowEdges(flagOn)
        flagShowEdges = logical(flagOn);
        if ~isempty(boundaryBox) && isvalid(boundaryBox)
            boundaryBox.Value = flagShowEdges;
        end
        markQuickBar();
        redraw();
        nightEdges();
        refreshOwn();
    end

    %% Its own window: the label list, the mouse, and closing
    function makeLabelRows()
        % One row per label (made again when the labels change)
        if isempty(labelGroup) || ~isvalid(labelGroup)
            return;
        end
        allKeys = [{'all'}, labelKeys];
        allNames = [{'All labels'}, labelNames];
        oldKeys = arrayfun(@(radio) radio.UserData, labelRadios, 'UniformOutput', false);
        if isequal(oldKeys, allKeys)
            return;
        end
        delete(labelGroup.Children);
        labelRadios = gobjects(0);
        labelShowBoxes = gobjects(0);
        labelSwatches = gobjects(0);
        for ith_label = 1:numel(allKeys)
            labelRadios(ith_label) = uiradiobutton(labelGroup, 'Text', allNames{ith_label}, ...
                'Position', [8 8 160 22], 'UserData', allKeys{ith_label});
            if ith_label > 1
                labelShowBoxes(end+1) = uicheckbox(labelGroup, 'Text', '', 'Value', ~any(strcmp(hiddenKeys, allKeys{ith_label})), ...
                    'Tag', ['labelShow_' allKeys{ith_label}], ...
                    'UserData', allKeys{ith_label}, 'Position', [180 8 22 22], 'ValueChangedFcn', @(~,~) onShowBox(), ...
                    'Tooltip', 'Show these faces (untick to hide them, to see the faces under them)'); %#ok<AGROW>
                % (the label's color, as on the model, beside its box)
                labelSwatches(end+1) = uipanel(labelGroup, 'Position', [202 11 16 16], 'BorderType', 'line', ...
                    'BackgroundColor', [1 1 1], 'Tooltip', 'This label''s color on the model'); %#ok<AGROW>
            end
        end
        selected = find(strcmp(allKeys, currentKey), 1);
        if ~isempty(selected)
            labelGroup.SelectedObject = labelRadios(selected);
        end
        placeLabelRows();
        colorLabelRows();
    end

    function colorLabelRows()
        % Each label's name and swatch in its color on the model (a name
        % too pale to read on white is drawn dark; its swatch keeps the color)
        for ith_row = 2:numel(labelRadios)
            if ~isvalid(labelRadios(ith_row))
                continue;
            end
            thisColor = fcn_INTERNAL_labelColor(data, labelRadios(ith_row).UserData);
            if ith_row-1 <= numel(labelSwatches) && isvalid(labelSwatches(ith_row-1))
                labelSwatches(ith_row-1).BackgroundColor = thisColor;
            end
            textColor = thisColor;
            if [0.299 0.587 0.114]*thisColor(:) > 0.62
                textColor = 0.45*thisColor;
            end
            labelRadios(ith_row).FontColor = textColor;
            labelRadios(ith_row).FontWeight = 'bold';
        end
    end

    function placeLabelRows()
        if isempty(labelGroup) || ~isvalid(labelGroup)
            return;
        end
        rowTop = max(labelGroup.InnerPosition(4), 24*numel(labelRadios) + 8);
        boxIndex = 0;
        for ith_row = 1:numel(labelRadios)
            rowBottom = rowTop - 24*ith_row;
            labelRadios(ith_row).Position(2) = rowBottom;
            if ith_row > 1
                boxIndex = boxIndex + 1;
                labelShowBoxes(boxIndex).Position(2) = rowBottom;
                if boxIndex <= numel(labelSwatches)
                    labelSwatches(boxIndex).Position(2) = rowBottom + 3;
                end
            end
        end
    end

    function onShowBox()
        hiddenNow = {};
        for ith_box = 1:numel(labelShowBoxes)
            if isvalid(labelShowBoxes(ith_box)) && ~labelShowBoxes(ith_box).Value
                hiddenNow{end+1} = labelShowBoxes(ith_box).UserData; %#ok<AGROW>
            end
        end
        setHidden(hiddenNow);
    end

    function onOwnDown()
        % CAD-style: left-drag rotates, right-drag pans (the model);
        % the dial's arrow is dragged around the dial
        mouseMode = '';
        if gripDown()
            return;
        end
        mouseDownAt(figureHandle.CurrentPoint, figureHandle.CurrentObject, figureHandle.SelectionType);
    end

    function mouseDownAt(point, clicked, selectionType)
        % (the mouse pressed at this point of the window, on this object,
        % with this button: 'alt' is the right button)
        mouseMode = '';
        if isempty(clicked) || ~isvalid(clicked) || ~isequal(ancestor(clicked, 'axes'), axesHandle)
            return;
        end
        if strcmp(selectionType, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseStart = point;
        mouseLast = mouseStart;
    end

    function flagUsed = dialMove()
        % (the dial's arrow dragged: it follows the mouse, and the model
        % turns with it; or the photo's handle dragged: the photo resized)
        flagUsed = dialMoveAt(figureHandle.CurrentPoint);
    end

    function flagUsed = dialMoveAt(point)
        % (the mouse moved to this point of the window)
        if flagPhotoResizing
            resizePhoto();
            flagUsed = true;
            return;
        end
        flagUsed = flagDialDragging && ~isempty(dialAxes) && isvalid(dialAxes);
        if flagUsed
            setDialAngle(pointerAngle(point), flagTurnWithPhoto, false);
        end
    end

    function flagUsed = dialUp()
        % (the arrow let go: to the photo's own angle)
        if flagPhotoResizing
            flagPhotoResizing = false;
            flagUsed = true;
            return;
        end
        flagUsed = flagDialDragging;
        if flagUsed
            flagDialDragging = false;
            setDialAngle(getPhotoAngle(), flagTurnWithPhoto, true);
        end
    end

    function onOwnMove()
        if dialMove()
            return;
        end
        mouseMoveTo(figureHandle.CurrentPoint);
    end

    function mouseMoveTo(point)
        % (the mouse moved to this point of the window: the model turned
        % or panned by the move)
        if isempty(mouseMode)
            return;
        end
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(axesHandle, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(axesHandle, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function onOwnUp()
        dialUp();
        mouseMode = '';
    end

    function onOwnScroll(~, event)
        scrollAt(figureHandle.CurrentPoint, event.VerticalScrollCount);
    end

    function scrollAt(point, scrollCount)
        % (the wheel turned with the mouse at this point: zooms when it is
        % over the model)
        box = getpixelposition(axesHandle, true);
        if point(1) >= box(1) && point(1) <= box(1)+box(3) && point(2) >= box(2) && point(2) <= box(2)+box(4)
            camzoom(axesHandle, 1.15^(-scrollCount));
        end
    end

    %% Its own window: the menu, the panels, GUI settings, the status
    function setMenuWidth(width)
        % (the ☰ Menu's column: its width when something is shown in it,
        % none when nothing is)
        if ~isempty(bodyGrid) && isvalid(bodyGrid)
            bodyGrid.ColumnWidth{1} = width;
        end
    end

    function onPanelsChanged()
        % (the open panels changed: they show the state now, and the photo
        % is placed again in the room left)
        if ~isempty(displayPanels)
            displayPanels.MarkAll();
        end
        markSettings();
        placePhoto();
    end

    function pickPanel(name)
        % Open this panel at the left, under the one open (a third one
        % replaces the lower one); an open panel picked again closes; ''
        % closes them all (the shared menu, fcn_CarMesh3D_makePanelMenu)
        if isempty(panelMenu)
            return;
        end
        panelMenu.Open(char(name));
    end

    function openPanels(names)
        % (exactly these panels open, top first: at most two)
        if ~isempty(panelMenu)
            panelMenu.OpenPanels(names);
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
        names = {};
        if ~isempty(panelMenu)
            names = panelMenu.OpenNames();
        end
    end

    function panelsOut = getPanels()
        panelsOut = displayPanels;
    end

    function menuOut = getMenu()
        menuOut = panelMenu;   % (nested, not anonymous: made after the hooks)
    end

    function settingsOut = getSharedSettings()
        settingsOut = sharedSettings;
    end

    function onSharedSetting(name, value)
        % (a change in Shared GUI settings: this window follows it at once;
        % other windows at their next open, Q46 (A))
        switch name
            case 'StartViewDial'
                startDial = double(value);
                startView = [];
            case 'StartViewDown'
                startDown = double(value);
                startView = [];
        end
    end

    function markSettings()
        % (Shared GUI settings showing the settings now)
        if ~isempty(sharedSettings)
            sharedSettings.Mark();
        end
    end

    function setStartView(dialAngle, downAngle)
        % The starting view (and Reset view's), kept for the viewer and
        % the painter
        startDial = double(dialAngle);
        startDown = double(downAngle);
        fcn_INTERNAL_setPref('StartViewDial', startDial);
        fcn_INTERNAL_setPref('StartViewDown', startDown);
        startView = [];   % (taken again, at the new angles, by the next Reset view)
        markSettings();
    end

    function angles = getStartView()
        angles = [startDial startDown];
    end

    function setFlagGround(flagOn)
        % The ground plane, by day and at night, for this window only (it
        % starts on in every window: Sean, 2026-11-26 10:12)
        flagGround = logical(flagOn);
        markQuickBar();
        if ~isempty(dayGround) && isvalid(dayGround)
            dayGround.Visible = matlab.lang.OnOffSwitchState(flagGround && ~flagNight);
        end
        if flagNight
            buildNight();
        end
        markSettings();
        if ~isempty(displayPanels)
            displayPanels.MarkOverall();
        end
        updateStatus();
    end

    function flagOn = getFlagGround()
        flagOn = flagGround;
    end

    function color = getLabelColor(name)
        % The color of a label's box, by name ('body', 'headlamp',
        % 'hide', ...): the color most of its faces have in the labels
        % view, else a standard one (as the painter's)
        name = char(name);
        defaults = struct('body', [0.75 0.75 0.78], 'glass', [0.55 0.75 0.95], 'trim', [0.18 0.18 0.18], ...
            'interior', [0.85 0.65 0.40], 'wheel', [0.08 0.08 0.08], 'hide', [1 0 1], 'unhide', [0.20 0.75 0.30]);
        for thisType = fcn_CarMesh3D_lampTypes(FigNum=-1)'
            defaults.(thisType.Name) = thisType.LabelColor;
        end
        if startsWith(name, 'hide:')
            name = 'hide';
        end
        color = [0.5 0.5 0.5];
        if isfield(defaults, name)
            color = defaults.(name);
        end
        if any(strcmp(name, {'hide', 'unhide'}))
            return;
        end
        if any(strcmp(name, {'body', 'glass', 'trim', 'interior', 'wheel'}))
            key = ['part_' name];
        else
            key = ['light_' name];
        end
        if any(fcn_INTERNAL_labelFaces(data.Mesh, key))
            color = fcn_INTERNAL_labelColor(data, key);
        end
    end

    function updateStatus()
        % (the top bar's status: what is shown now)
        if isempty(statusLabel) || ~isvalid(statusLabel)
            return;
        end
        colorsText = 'label colors';
        if strcmp(colorsMode, 'vehicle')
            colorsText = 'vehicle colors';
        end
        timeText = 'by day';
        if flagNight
            timeText = 'at night';
        end
        numHidden = numel(setdiff(hiddenKeys, {'hidden'}));
        hiddenText = '';
        if numHidden > 0
            hiddenText = sprintf(' | %d label(s) not shown', numHidden);
        end
        statusLabel.Text = sprintf('<b>%s</b> | %s, %s%s', vehicleName, colorsText, timeText, hiddenText);
    end

    %% Hooks for tests (Sean, 2026-11-24 05:03: "the code could pass in
    %% debugging state requests, and the GUI must go to that state")
    function rootOut = driverRoot()
        % (what fcn_CarMesh3D_guiDriver drives: its own window, or, inside
        % a host, the panel it was built into)
        if flagOwnWindow
            rootOut = figureHandle;
        else
            rootOut = parent;
        end
    end

    function mouseDrag(button, fromPoint, toPoint, numSteps)
        % A drag on the model, through the same code as the mouse's:
        % button 'left' (turn) or 'right' (pan), from and to points in the
        % window's pixels ([] from: the model's middle), in numSteps moves
        if nargin < 4 || isempty(numSteps)
            numSteps = 5;
        end
        box = getpixelposition(axesHandle, true);
        if isempty(fromPoint)
            fromPoint = box(1:2) + box(3:4)/2;
        end
        selectionType = 'normal';
        if strcmp(char(button), 'right')
            selectionType = 'alt';
        end
        mouseDownAt(fromPoint, axesHandle, selectionType);
        for ith_step = 1:numSteps
            mouseMoveTo(fromPoint + ith_step/numSteps*(toPoint - fromPoint));
        end
        onOwnUp();
        drawnow;
    end

    function scrollHook(scrollCount, point)
        % The wheel turned scrollCount clicks (negative zooms in) with the
        % mouse at this point ([] or none: the model's middle)
        if nargin < 2 || isempty(point)
            box = getpixelposition(axesHandle, true);
            point = box(1:2) + box(3:4)/2;
        end
        scrollAt(point, scrollCount);
        drawnow;
    end

    function flagDone = dialDrag(angles, flagRelease)
        % The dial's arrow pressed at the first angle and dragged through
        % the others (degrees, as the dial reads them), through the same
        % code as the mouse's; let go at the end unless flagRelease is
        % false. One angle is a click on the dial (on a photo's dot, say).
        % False when there is no dial (no photos).
        flagDone = false;
        if isempty(dialAxes) || ~isvalid(dialAxes) || strcmp(dialGrid.Visible, 'off')
            return;   % (no dial, or left out of a window too small for it)
        end
        if nargin < 2
            flagRelease = true;
        end
        box = getpixelposition(dialAxes, true);
        center = box(1:2) + box(3:4)/2;
        radius = 0.35*min(box(3:4));
        pointOf = @(angle) center + radius*[cosd(angle) sind(angle)];
        dialDownAt(pointOf(angles(1)));
        for ith_angle = 2:numel(angles)
            dialMoveAt(pointOf(angles(ith_angle)));
        end
        if flagRelease
            dialUp();
        end
        drawnow;
        flagDone = true;
    end

    function resizeWindow(sizeIn)
        % The window made this size ([width height] in pixels), then the
        % view checked at once (as the view timer would, within 0.25 s)
        figureHandle.Position(3:4) = sizeIn;
        settle();
    end

    function settle()
        % Waits (up to 3 s) until the window has laid itself out, then
        % runs the view timer's check at once, twice (the photo fitted to
        % the room, then the view refitted to the model's new size). A
        % hidden window lays itself out a little after drawnow (measured
        % 2026-11-24: its grids reported their old size for up to 0.3 s),
        % so a test reads the layout only once it has settled.
        for ith_pass = 1:2
            fcn_INTERNAL_waitForLayout(figureHandle, modelHolder);
            placePhoto();
            onModelViewChanged();
        end
        drawnow;
    end

    function fit = getFitInfo()
        % The view's zoom against "the whole vehicle just fits": Zoom 1
        % just fits, larger is zoomed in (for tests of the framing)
        fit = struct('Zoom', NaN, 'FitTan', NaN, 'AxesSize', [NaN NaN]);
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        axesSize = axesHandle.InnerPosition(3:4);
        fit.AxesSize = axesSize;
        fit.FitTan = fcn_INTERNAL_fitTan(axesHandle, data.Mesh.Vertices, axesSize);
        fit.Zoom = fit.FitTan/tand(axesHandle.CameraViewAngle/2);
    end

    function countOut = getPhotoCount()
        % (how many photos the dial has: none means no photo side)
        countOut = numel(photoSet);
    end

    function refreshOwn()
        % (its own window's panels and status line showing the state now,
        % after a change made through a hook, not only through the
        % panels: found by the random walks, 2026-11-24)
        if isempty(displayPanels)
            return;
        end
        displayPanels.MarkAll();
        updateStatus();
    end

    function closeViewer()
        % The view settings kept, to be returned; then the window closed
        if ~isempty(axesHandle) && isvalid(axesHandle)
            closedSettings = getView();
        end
        stopTimer();
        if flagOwnWindow && ~isempty(figureHandle) && isvalid(figureHandle)
            delete(figureHandle);
        end
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

%% fcn_INTERNAL_waitForLayout
function fcn_INTERNAL_waitForLayout(figureHandle, probe)
% Waits until a window's layout has settled: at least 0.3 s (a hidden
% window starts laying itself out up to about 0.3 s after drawnow), and
% the probe's place on the screen the same at three checks in a row, 30
% ms apart (at most 3 s)
lastBox = [];
numSame = 0;
startTime = tic;
while toc(startTime) < 3 && isvalid(figureHandle) && isvalid(probe)
    drawnow;
    box = getpixelposition(probe, true);
    if isequal(box, lastBox)
        numSame = numSame + 1;
        if numSame >= 2 && toc(startTime) >= 0.3
            return;
        end
    else
        numSame = 0;
    end
    lastBox = box;
    pause(0.03);
end
end % Ends fcn_INTERNAL_waitForLayout

%% fcn_INTERNAL_warnIfStale
function flagStale = fcn_INTERNAL_warnIfStale(vehicleMesh)
% Warns if a vehicle's mesh, given as a variable, has labels that differ
% from the vehicle's latest (its mesh with its saved label fixes): a
% variable loaded before the painter saved (Q85 (A)). Meshes that are not
% a vehicle's, or whose faces differ (a detail level), are passed over.
flagStale = false;
% (the vehicle's ID: from the script that built the mesh, else its name)
vehicleID = '';
if isfield(vehicleMesh, 'BuildInfo') && isstruct(vehicleMesh.BuildInfo) && isfield(vehicleMesh.BuildInfo, 'Script')
    [~, scriptName] = fileparts(char(vehicleMesh.BuildInfo.Script));
    vehicleID = regexprep(scriptName, '^script_CarMesh3D_vehicle_', '');
    if strcmp(vehicleID, scriptName)
        vehicleID = '';
    end
end
if isempty(vehicleID) && isfield(vehicleMesh, 'Name') && ~isempty(vehicleMesh.Name)
    vehicleID = strrep(strtrim(char(vehicleMesh.Name)), ' ', '_');
end
if isempty(vehicleID)
    return;
end
try
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
    if ~(vehicleFiles.Found && vehicleFiles.HasMesh)
        return;
    end
    latestMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleFiles.Folder, FlagOrientFaces=false, FlagLampFunctions=false, FigNum=-1);
catch
    return;
end
if size(latestMesh.Faces,1) ~= size(vehicleMesh.Faces,1)
    return;
end
labelFields = {'LabelFacePart', 'LabelFaceLamp'};
for ith_field = 1:numel(labelFields)
    thisField = labelFields{ith_field};
    if isfield(vehicleMesh, thisField) && isfield(latestMesh, thisField) ...
            && ~isequal(vehicleMesh.(thisField)(:), latestMesh.(thisField)(:))
        flagStale = true;
    end
end
if flagStale
    warning('CarMesh3D:staleMesh', ['This mesh of %s has labels that differ from the vehicle''s latest (label ' ...
        'fixes saved since it was loaded?). To view the latest: fcn_CarMesh3D_viewLabels(''%s'')'], ...
        vehicleFiles.Name, vehicleFiles.ID);
end
end % Ends fcn_INTERNAL_warnIfStale

%% fcn_INTERNAL_loadMesh
function vehicleMesh = fcn_INTERNAL_loadMesh(meshFile)
% The mesh in a .mat file: the variable vehicleMesh, else the first
% labeled mesh in it
loaded = load(meshFile);
if isfield(loaded, 'vehicleMesh')
    vehicleMesh = loaded.vehicleMesh;
    return;
end
names = fieldnames(loaded);
for ith_name = 1:numel(names)
    candidate = loaded.(names{ith_name});
    if isstruct(candidate) && all(isfield(candidate, {'Vertices','Faces','LabelPartNames','LabelFacePart'}))
        vehicleMesh = candidate;
        return;
    end
end
error('The file %s holds no labeled CarMesh3D mesh', meshFile);
end % Ends fcn_INTERNAL_loadMesh

%% fcn_INTERNAL_pick
function value = fcn_INTERNAL_pick(optionValue, given, fieldName, default)
% An option given to the call, else the view settings' field, else the
% default
if ~isempty(optionValue)
    value = optionValue;
elseif isfield(given, fieldName) && ~isempty(given.(fieldName))
    value = char(given.(fieldName));
else
    value = default;
end
end % Ends fcn_INTERNAL_pick

%% fcn_INTERNAL_getView / fcn_INTERNAL_setView
function viewState = fcn_INTERNAL_getView(axesHandle)
% The camera, exactly (position, target, up, view angle, projection, and
% the axes limits)
drawnow;
viewState = struct('CameraPosition', axesHandle.CameraPosition, 'CameraTarget', axesHandle.CameraTarget, ...
    'CameraUpVector', axesHandle.CameraUpVector, 'CameraViewAngle', axesHandle.CameraViewAngle, ...
    'Projection', axesHandle.Projection, ...
    'XLim', axesHandle.XLim, 'YLim', axesHandle.YLim, 'ZLim', axesHandle.ZLim);
end % Ends fcn_INTERNAL_getView

function fcn_INTERNAL_setView(axesHandle, viewState)
% Back to a camera from fcn_INTERNAL_getView (fields missing are left)
names = {'XLim', 'YLim', 'ZLim', 'Projection', 'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'};
for ith_name = 1:numel(names)
    if isfield(viewState, names{ith_name}) && ~isempty(viewState.(names{ith_name}))
        axesHandle.(names{ith_name}) = viewState.(names{ith_name});
    end
end
end % Ends fcn_INTERNAL_setView

%% fcn_INTERNAL_cameraAngles
function [azimuth, elevation] = fcn_INTERNAL_cameraAngles(axesHandle)
% The camera's azimuth and elevation around its target, in meters (as
% view() gives them, but not stretched by the axes' box: view() measures
% in the plot box, so after "Reset view" its angles differed from the
% camera's, and the dial's arrow moved off its photo when let go: Sean,
% 14:37)
offset = axesHandle.CameraPosition - axesHandle.CameraTarget;
azimuth = atan2d(offset(1), -offset(2));
elevation = atan2d(offset(3), hypot(offset(1), offset(2)));
end % Ends fcn_INTERNAL_cameraAngles

%% fcn_INTERNAL_freezeCamera
function fcn_INTERNAL_freezeCamera(axesHandle)
% The camera and limits set to what they are, so MATLAB no longer works
% them out on its own (and what is read is what is shown)
for name = {'XLim', 'YLim', 'ZLim', 'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'}
    axesHandle.(name{1}) = axesHandle.(name{1});
end
end % Ends fcn_INTERNAL_freezeCamera

%% fcn_INTERNAL_viewCall
function textOut = fcn_INTERNAL_viewCall(settings)
% The MATLAB call that opens these view settings, as one line of text
% (numbers to 8 significant digits)
camera = settings.Camera;
cameraParts = {};
for name = {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle', 'XLim', 'YLim', 'ZLim'}
    cameraParts{end+1} = sprintf('''%s'',%s', name{1}, mat2str(camera.(name{1}), 8)); %#ok<AGROW>
end
cameraParts{end+1} = sprintf('''Projection'',''%s''', camera.Projection);
if isempty(settings.Hidden)
    hiddenText = '{}';
else
    hiddenText = ['{' strjoin(strcat('''', settings.Hidden, ''''), ',') '}'];
end
photoText = 'NaN';
if ~isnan(settings.PhotoAngle)
    photoText = mat2str(settings.PhotoAngle, 8);
end
seeThroughValue = 0;
if isfield(settings, 'SeeThrough') && ~isempty(settings.SeeThrough)
    seeThroughValue = settings.SeeThrough;
end
boundaryValue = false;
if isfield(settings, 'FlagShowEdges') && ~isempty(settings.FlagShowEdges)
    boundaryValue = logical(settings.FlagShowEdges);
end
nightValue = false;
if isfield(settings, 'FlagNight') && ~isempty(settings.FlagNight)
    nightValue = logical(settings.FlagNight);
end
nightLightsText = 'struct()';
if isfield(settings, 'NightLights') && isstruct(settings.NightLights)
    lamps = settings.NightLights;
    nightLightsText = sprintf(['struct(''LowBeam'',%s,''HighBeam'',%s,''Running'',%s,''TurnLeft'',%s,''TurnRight'',%s,' ...
        '''Tail'',%s,''Brake'',%s,''Backup'',%s)'], mat2str(logical(lamps.LowBeam)), mat2str(logical(lamps.HighBeam)), mat2str(logical(lamps.Running)), ...
        mat2str(logical(lamps.TurnLeft)), mat2str(logical(lamps.TurnRight)), mat2str(logical(lamps.Tail)), ...
        mat2str(isfield(lamps, 'Brake') && logical(lamps.Brake)), mat2str(logical(lamps.Backup)));
end
photoHeightText = '[]';
if isfield(settings, 'PhotoHeight') && ~isempty(settings.PhotoHeight)
    photoHeightText = mat2str(round(settings.PhotoHeight));
end
settingsText = sprintf(['struct(''MeshFile'',''%s'',''Camera'',struct(%s),''Label'',''%s'',''Hidden'',{%s},' ...
    '''Colors'',''%s'',''PhotoAngle'',%s,''SeeThrough'',%s,''FlagShowEdges'',%s,''FlagNight'',%s,''NightLights'',%s,''PhotoHeight'',%s)'], settings.MeshFile, strjoin(cameraParts, ','), settings.Label, hiddenText, ...
    settings.Colors, photoText, mat2str(seeThroughValue, 4), mat2str(boundaryValue), mat2str(nightValue), nightLightsText, photoHeightText);
if isempty(settings.MeshFile)
    vehicleText = 'vehicleMesh';   % (a mesh variable was given: the one who opens it gives it again)
else
    vehicleText = sprintf('''%s''', settings.MeshFile);
end
textOut = sprintf('fcn_CarMesh3D_viewLabels(%s, ViewSettings=%s);', vehicleText, settingsText);
end % Ends fcn_INTERNAL_viewCall

%% fcn_INTERNAL_labelColor
function shownMesh = fcn_INTERNAL_keepFaces(vehicleMesh, flagKeep)
% The mesh with only the faces kept (every per-face field cut to match;
% the vertices stay as they are)
numFaces = size(vehicleMesh.Faces,1);
shownMesh = vehicleMesh;
if all(flagKeep)
    return;
end
for name = fieldnames(vehicleMesh)'
    value = vehicleMesh.(name{1});
    if startsWith(name{1}, {'Face','LabelFace'}) && (isnumeric(value) || islogical(value)) && size(value,1) == numFaces
        shownMesh.(name{1}) = value(flagKeep,:);
    end
end
end

function lampTypes = fcn_INTERNAL_lampTypes(vehicleMesh)
% The lamp types this vehicle has (its own type or, for a lamp with
% several functions, any of them)
lampTypes = {};
if ~isfield(vehicleMesh,'LabelFaceLamp') || isempty(vehicleMesh.LabelFaceLamp) || ~isfield(vehicleMesh,'LabelLampNames')
    return;
end
typeNames = cellstr(vehicleMesh.LabelLampNames);
flagHas = false(1, numel(typeNames));
usedTypes = unique(double(vehicleMesh.LabelFaceLamp(vehicleMesh.LabelFaceLamp > 0)));
flagHas(usedTypes) = true;
if isfield(vehicleMesh,'LabelFaceAlsoLamps') && size(vehicleMesh.LabelFaceAlsoLamps,2) == numel(typeNames)
    flagHas = flagHas | any(logical(vehicleMesh.LabelFaceAlsoLamps), 1);
end
lampTypes = typeNames(flagHas);
end

function value = fcn_INTERNAL_pref(name, default)
% A GUI setting kept between sessions (group CarMesh3D, shared with the
% painter), else its default
value = default;
try
    if ispref('CarMesh3D', name)
        value = getpref('CarMesh3D', name);
    end
catch
    value = default;
end
end % Ends fcn_INTERNAL_pref

function fcn_INTERNAL_setPref(name, value)
% (a GUI setting kept for the next session; nothing lost if it cannot be)
try
    setpref('CarMesh3D', name, value);
catch
end
end % Ends fcn_INTERNAL_setPref

function groundPatch = fcn_INTERNAL_ground(axesHandle, vertices, timeOfDay)
% The ground under the vehicle (Sean, 2026-11-24 02:43 and 03:43): squares
% of exactly 1 m on whole-meter lines (a scale to judge the vehicle by), in
% two shades, light by day and dark at night, the same squares and the same
% extent either way (10 m past the vehicle on every side), just under its
% lowest point; unlit, unclipped, and never picked by the mouse
margin = 10;
xEdges = floor(min(vertices(:,1)) - margin):1:ceil(max(vertices(:,1)) + margin) - 1;
yEdges = floor(min(vertices(:,2)) - margin):1:ceil(max(vertices(:,2)) + margin) - 1;
groundZ = min(vertices(:,3)) - 0.01;
[gridX, gridY] = meshgrid(xEdges, yEdges);
numSquares = numel(gridX);
corners = [0 0; 1 0; 1 1; 0 1];
groundVertices = zeros(4*numSquares, 3);
groundVertices(:,3) = groundZ;
groundFaces = reshape(1:4*numSquares, 4, [])';
for ith_corner = 1:4
    groundVertices(ith_corner:4:end, 1:2) = [gridX(:) gridY(:)] + corners(ith_corner,:);
end
flagDark = mod(round(gridX(:)) + round(gridY(:)), 2) == 0;
if strcmp(timeOfDay, 'night')
    shades = [0.11 0.11 0.13; 0.14 0.14 0.16];
    tag = 'nightGround';
else
    shades = [0.94 0.94 0.95; 0.87 0.87 0.89];
    tag = 'dayGround';
end
groundPatch = patch(axesHandle, 'Faces', groundFaces, 'Vertices', groundVertices, ...
    'FaceVertexCData', shades(1 + flagDark, :), 'FaceColor', 'flat', 'EdgeColor', 'none', ...
    'FaceLighting', 'none', 'Clipping', 'off', 'HitTest', 'off', 'PickableParts', 'none', 'Tag', tag);
end % Ends fcn_INTERNAL_ground

function fitTan = fcn_INTERNAL_fitTan(axesHandle, vertices, axesSize)
% The tangent of half the view angle at which the vehicle's box just fits
% axes of this size (in pixels), from the camera as it is, with 8% to
% spare. MATLAB's CameraViewAngle spans the axes' shorter side (measured
% 2026-11-24), so the longer side sees proportionally more.
lowCorner = min(vertices, [], 1);
highCorner = max(vertices, [], 1);
[cornerX, cornerY, cornerZ] = ndgrid([lowCorner(1) highCorner(1)], [lowCorner(2) highCorner(2)], [lowCorner(3) highCorner(3)]);
corners = [cornerX(:) cornerY(:) cornerZ(:)];
cameraPosition = axesHandle.CameraPosition;
forward = axesHandle.CameraTarget - cameraPosition;
distance = norm(forward);
forward = forward/distance;
rightward = cross(forward, axesHandle.CameraUpVector);
rightward = rightward/norm(rightward);
upward = cross(rightward, forward);
offsets = corners - cameraPosition;
across = abs(offsets*rightward(:));
up = abs(offsets*upward(:));
if strcmp(axesHandle.Projection, 'perspective')
    depth = max(offsets*forward(:), 0.1*distance);
else
    depth = distance;
end
tanAcross = max(across./depth);
tanUp = max(up./depth);
width = axesSize(1);
height = axesSize(2);
if height <= width
    fitTan = max(tanUp, tanAcross*height/width);
else
    fitTan = max(tanAcross, tanUp*width/height);
end
fitTan = 1.08*fitTan;
end % Ends fcn_INTERNAL_fitTan

function fcn_INTERNAL_frameVehicle(axesHandle, vertices)
% The axes' limits around the vehicle (5% to spare), so the camera frames
% the vehicle and not the ground drawn around it (which is unclipped), with
% equal axes. (Not axis equal: it sets the limits back to automatic.)
lowCorner = min(vertices, [], 1);
highCorner = max(vertices, [], 1);
pad = 0.05*max(highCorner - lowCorner);
axesHandle.DataAspectRatio = [1 1 1];
axis(axesHandle, [lowCorner(1)-pad highCorner(1)+pad lowCorner(2)-pad highCorner(2)+pad lowCorner(3)-pad highCorner(3)+pad]);
end % Ends fcn_INTERNAL_frameVehicle

function thisColor = fcn_INTERNAL_labelColor(data, labelKey)
% The color most of a label's faces have in the label colors
thisColor = [0.5 0.5 0.5];
flagFaces = fcn_INTERNAL_labelFaces(data.Mesh, labelKey);
% (a face also in another label, such as a lamp's clear cover, is left
% out when the label has faces of its own)
if isfield(data.Mesh,'LabelFacePart') && startsWith(labelKey, 'part_')
    partIndex = find(strcmp(data.Mesh.LabelPartNames, labelKey(6:end)), 1);
    flagOwn = flagFaces(:) & data.Mesh.LabelFacePart(:)==partIndex;
    if any(flagOwn)
        flagFaces = flagOwn;
    end
end
if any(flagFaces) && size(data.LabelColors,1) == numel(flagFaces)
    [uniqueColors, ~, colorIndex] = unique(round(data.LabelColors(flagFaces,:)*50)/50, 'rows');
    thisColor = uniqueColors(mode(colorIndex),:);
end
end % Ends fcn_INTERNAL_labelColor

%% fcn_INTERNAL_labelFaces
function flagFaces = fcn_INTERNAL_labelFaces(vehicleMesh, labelKey)
% The faces with this label
flagFaces = false(size(vehicleMesh.Faces,1),1);
if startsWith(labelKey, 'part_')
    partIndex = find(strcmp(vehicleMesh.LabelPartNames, labelKey(6:end)), 1);
    if isempty(partIndex)
        return;   % (a part the mesh does not have, such as interior since Q37: no faces)
    end
    flagFaces = vehicleMesh.LabelFacePart(:)==partIndex;
    % (and the faces that also belong to it: a lamp's clear cover is a
    % light that is also glass)
    if ~isempty(partIndex) && isfield(vehicleMesh,'LabelFaceAlsoParts') ...
            && size(vehicleMesh.LabelFaceAlsoParts,1)==numel(flagFaces) && partIndex <= size(vehicleMesh.LabelFaceAlsoParts,2)
        flagFaces = flagFaces(:) | vehicleMesh.LabelFaceAlsoParts(:,partIndex);
    end
elseif strcmp(labelKey, 'hidden')
    if isfield(vehicleMesh,'LabelFaceHiddenSet') && numel(vehicleMesh.LabelFaceHiddenSet)==numel(flagFaces)
        flagFaces = vehicleMesh.LabelFaceHiddenSet(:) > 0;
    end
elseif strcmp(labelKey, 'light_none')
    lightPart = find(strcmp(vehicleMesh.LabelPartNames, 'light'), 1);
    if isempty(lightPart)
        return;
    end
    flagFaces = vehicleMesh.LabelFacePart(:)==lightPart & vehicleMesh.LabelFaceLamp(:)==0;
elseif startsWith(labelKey, 'light_')
    typeIndex = find(strcmp(vehicleMesh.LabelLampNames, labelKey(7:end)), 1);
    if isempty(typeIndex)
        return;
    end
    flagFaces = vehicleMesh.LabelFaceLamp(:)==typeIndex;
end
end % Ends fcn_INTERNAL_labelFaces

%% fcn_INTERNAL_labelKinds
function nameOut = fcn_INTERNAL_lightName(typeName)
% A light type's name in the label list: its name for people from
% fcn_CarMesh3D_lampTypes ('headlamp', 'tail/brake lamp', ...), as the
% keys are camelCase (Q92 (A))
lampTypes = fcn_CarMesh3D_lampTypes();
match = find(strcmp({lampTypes.Name}, typeName), 1);
if isempty(match)
    nameOut = char(typeName);
else
    nameOut = regexprep(lampTypes(match).Label, '^(.)', '${lower($1)}');
end
end

function [keys, names] = fcn_INTERNAL_labelKinds(vehicleMesh, flagHiddenRow)
% The labels on this mesh: parts (other than light), each light type,
% "light with no type" if there are any, and (with flagHiddenRow) the
% hidden faces, if there are any
if nargin < 2
    flagHiddenRow = false;
end
keys = {};
names = {};
lightPart = find(strcmp(vehicleMesh.LabelPartNames, 'light'), 1);
for ith_part = 1:numel(vehicleMesh.LabelPartNames)
    if ith_part == lightPart || ~any(fcn_INTERNAL_labelFaces(vehicleMesh, ['part_' vehicleMesh.LabelPartNames{ith_part}]))
        continue;
    end
    keys{end+1} = ['part_' vehicleMesh.LabelPartNames{ith_part}]; %#ok<AGROW>
    names{end+1} = vehicleMesh.LabelPartNames{ith_part}; %#ok<AGROW>
end
if isfield(vehicleMesh, 'LabelLampNames')
    for ith_type = 1:numel(vehicleMesh.LabelLampNames)
        if any(vehicleMesh.LabelFaceLamp==ith_type)
            keys{end+1} = ['light_' vehicleMesh.LabelLampNames{ith_type}]; %#ok<AGROW>
            names{end+1} = fcn_INTERNAL_lightName(vehicleMesh.LabelLampNames{ith_type}); %#ok<AGROW>
        end
    end
end
if ~isempty(lightPart)
    flagUntyped = vehicleMesh.LabelFacePart==lightPart;
    if isfield(vehicleMesh, 'LabelFaceLamp')
        flagUntyped = flagUntyped & vehicleMesh.LabelFaceLamp==0;
    end
    if any(flagUntyped)
        keys{end+1} = 'light_none';
        names{end+1} = 'light with no type';
    end
end
if flagHiddenRow && any(fcn_INTERNAL_labelFaces(vehicleMesh, 'hidden'))
    keys{end+1} = 'hidden';
    names{end+1} = 'hidden (not drawn)';
end
end % Ends fcn_INTERNAL_labelKinds

%% fcn_INTERNAL_drawMesh
function patchHandle = fcn_INTERNAL_drawMesh(axesHandle, vehicleMesh, faceColors, faceAlpha)
% One patch, colored and see-through by face, unclipped
faceAlpha = faceAlpha(:);
if isscalar(faceAlpha)
    faceAlpha = repmat(faceAlpha, size(vehicleMesh.Faces,1), 1);
end
patchHandle = patch(axesHandle, 'Faces', vehicleMesh.Faces, 'Vertices', vehicleMesh.Vertices, ...
    'FaceVertexCData', faceColors, 'FaceColor', 'flat', 'EdgeColor', 'none', ...
    'FaceVertexAlphaData', faceAlpha, 'FaceAlpha', 'flat', 'AlphaDataMapping', 'none', ...
    'FaceLighting', 'flat', 'AmbientStrength', 0.85, 'DiffuseStrength', 0.3, 'SpecularStrength', 0.05, ...
    'BackFaceLighting', 'lit', 'Clipping', 'off');
end % Ends fcn_INTERNAL_drawMesh

%% fcn_INTERNAL_quietAxes
function fcn_INTERNAL_quietAxes(axesHandle)
% No built-in mouse interactions or toolbar: the reviewer's own mouse
% handling (CAD-style) works every view
axesHandle.Interactions = [];
try
    disableDefaultInteractivity(axesHandle);
catch
end
try
    axesHandle.Toolbar.Visible = 'off';
catch
end
axesHandle.PickableParts = 'all';
axesHandle.HitTest = 'on';
end % Ends fcn_INTERNAL_quietAxes

%% fcn_INTERNAL_photoAngles
function photoSet = fcn_INTERNAL_photoAngles(photoFiles)
% The photos named with their angle (ViewInDegrees_<angle>), in order of
% angle, one per angle
photoSet = struct('Angle',{},'File',{});
for ith_file = 1:numel(photoFiles)
    [~, name] = fileparts(photoFiles{ith_file});
    token = regexp(name, '(?i)ViewInDegrees_(\d+(\.\d+)?)', 'tokens', 'once');
    if isempty(token)
        continue;
    end
    angle = mod(str2double(token{1}), 360);
    if any([photoSet.Angle] == angle)
        continue;
    end
    photoSet(end+1) = struct('Angle', angle, 'File', photoFiles{ith_file}); %#ok<AGROW>
end
if ~isempty(photoSet)
    [~, order] = sort([photoSet.Angle]);
    photoSet = photoSet(order);
end
end % Ends fcn_INTERNAL_photoAngles

%% fcn_INTERNAL_drawDial
function [arrowHandles, dotHandles] = fcn_INTERNAL_drawDial(axesHandle, data, photoAngles)
% The photo dial: the vehicle from above (its 2D outline, with the tires
% on top; front to the right), a ring with a dot and its angle for each
% photo, the words for the four sides, and the camera arrow
hold(axesHandle, 'on');
axis(axesHandle, 'equal');
axis(axesHandle, 'off');
set(axesHandle, 'XLim', [-2.25 2.25], 'YLim', [-1.5 1.5], 'PickableParts', 'all', 'HitTest', 'on', 'Color', 'none');
axesHandle.Interactions = [];
try
    disableDefaultInteractivity(axesHandle);
    axesHandle.Toolbar.Visible = 'off';
catch
end
% (the vehicle from above, scaled to fit inside the ring)
vertices = data.Mesh.Vertices(:,1:2);
center = (max(vertices,[],1) + min(vertices,[],1))/2;
scale = 0.66/max(max(abs(vertices - center)));
toDial = @(xy) (xy - center)*scale;
flagDrawn = false;
if ~isempty(data.OutlineElements)
    for ith_element = 1:numel(data.OutlineElements)
        element = data.OutlineElements(ith_element);
        if startsWith(element.Label, 'Body')
            faceColor = [0.82 0.82 0.82]; edgeColor = [0.35 0.35 0.35];
        elseif startsWith(element.Label, 'Wheel')
            faceColor = [0.15 0.15 0.15]; edgeColor = [0 0 0];
        elseif startsWith(element.Label, 'Window')
            faceColor = [0.55 0.7 0.85]; edgeColor = 'none';
        else
            continue;
        end
        for ith_polygon = 1:numel(element.Polygons)
            polygon = toDial(element.Polygons{ith_polygon}(:,1:2));
            patch(axesHandle, polygon(:,1), polygon(:,2), faceColor, 'EdgeColor', edgeColor, 'HitTest', 'off');
            flagDrawn = true;
        end
    end
end
if ~flagDrawn
    % (no 2D outline: the mesh's outline from above, and boxes for the tires)
    hull = convhull(vertices(:,1), vertices(:,2));
    outline = toDial(vertices(hull,:));
    patch(axesHandle, outline(:,1), outline(:,2), [0.82 0.82 0.82], 'EdgeColor', [0.35 0.35 0.35], 'HitTest', 'off');
    wheelCenters = data.Geometry.WheelCenters;
    for ith_wheel = 1:size(wheelCenters,1)
        halfLength = data.Geometry.WheelDiameters(ith_wheel)/2;
        halfWidth = 0.1;
        box = [-halfLength -halfWidth; halfLength -halfWidth; halfLength halfWidth; -halfLength halfWidth] + wheelCenters(ith_wheel,1:2);
        box = toDial(box);
        patch(axesHandle, box(:,1), box(:,2), [0.15 0.15 0.15], 'EdgeColor', 'none', 'HitTest', 'off');
    end
end
patch(axesHandle, [0.5 0.34 0.34], [0 0.07 -0.07], [0.85 0 0], 'EdgeColor', 'none', 'HitTest', 'off');
angles = linspace(0, 360, 181);
plot(axesHandle, cosd(angles), sind(angles), '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 1, 'HitTest', 'off');
% (the four sides, in words, outside the ring)
sideAngles = [0 90 180 270];
sideWords = {'from ahead', 'from the left', 'from behind', 'from the right'};
sideAlignments = {'left', 'center', 'right', 'center'};
for ith_side = 1:4
    angle = sideAngles(ith_side);
    radius = 1.17;
    if any(angle == [90 270])
        radius = 1.3;
    end
    text(axesHandle, radius*cosd(angle), radius*sind(angle), sprintf('%d%c %s', angle, 176, sideWords{ith_side}), ...
        'HorizontalAlignment', sideAlignments{ith_side}, 'FontSize', 10, 'FontWeight', 'bold', ...
        'Color', [0.2 0.2 0.2], 'HitTest', 'off');
end
dotHandles = gobjects(numel(photoAngles),1);
for ith_photo = 1:numel(photoAngles)
    angle = photoAngles(ith_photo);
    dotHandles(ith_photo) = plot(axesHandle, cosd(angle), sind(angle), 'o', 'MarkerSize', 9, ...
        'MarkerFaceColor', [0.6 0.6 0.6], 'MarkerEdgeColor', [0.3 0.3 0.3], 'HitTest', 'off');
    if ~any(abs(mod(angle,360) - sideAngles) < 1e-6)
        text(axesHandle, 1.16*cosd(angle), 1.12*sind(angle), sprintf('%d%c', round(angle), 176), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', [0.35 0.35 0.35], 'HitTest', 'off');
    end
end
arrowHandles = gobjects(2,1);
arrowHandles(1) = plot(axesHandle, [1 0.78], [0 0], '-', 'Color', [0.85 0 0], 'LineWidth', 4, 'HitTest', 'off');
arrowHandles(2) = patch(axesHandle, [0.66 0.8 0.8], [0 0.07 -0.07], [0.85 0 0], 'EdgeColor', 'none', 'HitTest', 'off');
end % Ends fcn_INTERNAL_drawDial

%% fcn_INTERNAL_pointDialArrow
function fcn_INTERNAL_pointDialArrow(arrowHandles, angle)
% The camera arrow: from the ring toward the vehicle, at this angle
if any(~isgraphics(arrowHandles))
    return;
end
set(arrowHandles(1), 'XData', [1 0.78]*cosd(angle), 'YData', [1 0.78]*sind(angle));
headX = [0.66 0.8 0.8];
headY = [0 0.07 -0.07];
set(arrowHandles(2), 'XData', headX*cosd(angle) - headY*sind(angle), 'YData', headX*sind(angle) + headY*cosd(angle));
end % Ends fcn_INTERNAL_pointDialArrow

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

%% fcn_INTERNAL_outlineElements
function elements = fcn_INTERNAL_outlineElements(outline)
% The outline's parts, one item each: the body, each window, each wheel,
% and the lights grouped by type and side
elements = struct('Key',{},'Label',{},'Polygons',{});
if ~isempty(outline.Body)
    elements(end+1) = struct('Key','body','Label','Body outline','Polygons',{{outline.Body}});
end
for ith_window = 1:numel(outline.Windows)
    elements(end+1) = struct('Key', sprintf('window%d', ith_window), ...
        'Label', sprintf('Window: %s', outline.Windows(ith_window).Name), ...
        'Polygons', {{outline.Windows(ith_window).Polygon}}); %#ok<AGROW>
end
for ith_wheel = 1:numel(outline.Wheels)
    elements(end+1) = struct('Key', sprintf('wheel%d', ith_wheel), ...
        'Label', sprintf('Wheel: %s', outline.Wheels(ith_wheel).Name), ...
        'Polygons', {{outline.Wheels(ith_wheel).Rectangle + outline.Wheels(ith_wheel).Center}}); %#ok<AGROW>
    % (a wheel's rectangle is kept about its own center, so it can steer)
end
if ~isempty(outline.Lights)
    types = string({outline.Lights.Type});
    sides = string({outline.Lights.Side});
    groups = unique(types + "|" + sides, 'stable');
    for ith_group = 1:numel(groups)
        parts = split(groups(ith_group), "|");
        flagGroup = types==parts(1) & sides==parts(2);
        elements(end+1) = struct('Key', sprintf('lights_%s_%s', parts(1), parts(2)), ...
            'Label', sprintf('Lights: %s, %s (%d outlines)', parts(1), parts(2), sum(flagGroup)), ...
            'Polygons', {{outline.Lights(flagGroup).Polygon}}); %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_outlineElements
