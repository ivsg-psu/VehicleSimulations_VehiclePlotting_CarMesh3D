function [reviewTable, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleID, options)
% fcn_CarMesh3D_reviewVehicle
% The MODEL REVIEWER: a window for reviewing a finished vehicle, one check
% at a time, and recording an approval, a rejection, or a comment for each
% question. It replaces looking through the checks folder's pictures.
%
% THE WINDOW:
%   Top left: the tools, stacked: Reset view, Show all labels (on the
%           Labels check), Save report, Close; and a hint for the check.
%   Middle: the check's title (in large type: the check, the item, and
%           which check of how many), and the check itself. 3D views can
%           be rotated (drag) and zoomed (scroll) without parts being cut
%           away; "Reset view" puts the view back. Animations have a Play
%           button and a time slider, with the inputs plotted below and a
%           line at the current time.
%   Right:  the checks, as radio buttons (with how many questions are
%           answered); the check's items (one per label, dimension, light
%           state, outline, ...), marked with a check mark, a cross, or a
%           question mark (no answer yet); and, in the bottom-right
%           corner, the question for the selected item, with Approve and
%           Reject buttons, a minor / must-be-fixed choice for a
%           rejection, a likely cause (for differences from the
%           download), and a comment box. Approving goes straight on to
%           the next item with no answer (in this check first). "Next
%           unanswered" does the same; "Approve all unanswered items in
%           this check" approves the rest of the check and goes on.
%
% THE CHECKS (and the questions asked):
%   Orientation     Does the red arrow point to the front?
%   Dimensions      One item per dimension, drawn as on a drawing, in the
%                   side, front (track front, widths), or rear (track
%                   rear) view: the target (blue) and the measured value
%                   (purple), each with arrows at both ends, its value on
%                   top, and thin guide lines across the vehicle to check
%                   the fit. In the table, the selected row is bold; the
%                   error is green (passes) or red (fails).
%   Labels          One item per label: only that label is colored, the
%                   rest is gray. "Show all labels" shows every label,
%                   until it is pressed again or an item is picked.
%                   Photos of the real vehicle (put in the vehicle's
%                   photos folder, as .jpg or .png) are shown beside the
%                   model. Photos named ViewInDegrees_<angle> (the
%                   camera's direction from the vehicle, counterclockwise
%                   from the front seen from above: 0 from ahead, 90 from
%                   the left, 180 from behind, 270 from the right) are
%                   placed on a dial under the model: drag its red arrow
%                   around the vehicle, and the nearest photo is shown and
%                   the model turns to the same angle. Rotating the model
%                   moves the arrow and the photo too.
%   Differences     The download and the reduced mesh, side by side,
%                   turning together. The places where they differ most
%                   (holes, label changes) are boxed in yellow, one item
%                   each: is the difference significant? If so, the likely
%                   cause.
%   Lights, Body, Steering, Wheels, Drive
%                   The check's animation, with one item per step (a
%                   still of that step and its question) and one for the
%                   whole animation.
%   Ground contact  Does the body stay above the ground?
%   Detail levels   The detail levels and the full mesh side by side, each
%                   pair at the distance where that level is used, seen
%                   through a camera like the animations' (40 degrees
%                   across 450 pixels).
%   2D outline      One item per outline: is it one closed outline around
%                   the part, with no lines crossing through it?
%   Summary         Every answer, the questions not yet answered, and the
%                   overall Approve or Reject.
%
% THE ANSWERS are saved in the vehicle's checks folder as
% review_<ID>.mat after every change, and as review_<ID>.md (a readable
% report) when the window is closed or "Save report" is pressed. Opening
% the reviewer again loads the earlier answers.
%
% FORMAT:
%
%       [reviewTable, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleID,...
%           (Reviewer=name), (Visible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleID: a vehicle ID (its folder name), such as
%      '2009_Honda_Fit_Sport', or the full path of a vehicle's folder
%      kept anywhere (such as the demo's copy, from
%      fcn_CarMesh3D_makeDemoCopy: the review is then saved in the copy).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Reviewer: the reviewer's name, saved with each answer. Default: the
%      computer's user name.
%
%      Visible: true (default) to show the window; false to build it
%      without showing it (for tests).
%
%      FigNum: not used for plotting (the reviewer is its own window). If
%      set to -1, input checking is skipped.
%
% OUTPUTS:
%
%      reviewTable: the answers so far (one row per question): Check,
%      Item, Question, Status ('', 'approved', 'rejected'), Severity
%      ('minor', 'must fix'), Cause, Comment, Reviewer, Time.
%
%      figureHandle: the reviewer's window (a uifigure).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_plotLabels,
%      fcn_CarMesh3D_paintLabels, fcn_CarMesh3D_animateChecks,
%      fcn_CarMesh3D_viewOutline, fcn_CarMesh3D_viewDetailLevels,
%      fcn_CarMesh3D_viewOrientation, fcn_CarMesh3D_viewDimensions
%
% EXAMPLES:
%
%       fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_reviewVehicle.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * First write (Sean's design, 2026_11_21): one window for reviewing
%   %   % a vehicle's checks, with an answer for each question
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * Sean's review of the first version: a large title for every
%   %   % check; the tools stacked at the top left; the checks, items,
%   %   % and question all on the right; approving goes on to the next
%   %   % item with no answer; "Approve all" for a check; a question mark
%   %   % for an item with no answer; "Show all labels" ends when an item
%   %   % is picked
%   % * Dimensions drawn as on a drawing (arrows at both ends, values on
%   %   % top, solid guide lines, no dashed lines), in front of the
%   %   % vehicle so it hides nothing; front and rear views for the
%   %   % tracks; front and rear tire diameters when they differ; the
%   %   % table's colors and bold row follow the selected item
%   % * Labels: a photo dial (Sean's design): photos named
%   %   % ViewInDegrees_<angle> are dots around a vehicle icon; the
%   %   % red arrow is dragged around it, the nearest photo is shown,
%   %   % and the model turns to the same angle (and back)
%   % * Sean's second review: the vehicle's name in very large letters;
%   %   % every view grows with the window; Rotate/Pan and Zoom +/-
%   %   % buttons always in view; approving the last item of a check
%   %   % goes on to the next check, with a short notice naming any
%   %   % checks already done; Approve on an approved item goes on (it
%   %   % no longer takes the answer back: "Clear this answer" does)
%   % * Orientation: FRONT (+X) and UP (+Z) arrows; on Reject, lists for
%   %   % where the front and top really are; the report gives the
%   %   % script's new importForwardAxis and importUpAxis
%   % * Dimensions: the vehicle in its own colors, faded; BLUE and
%   %   % PURPLE in color in the hint; the quantity column kept narrow
%   % * Labels: the dial between the model and the photo, with the
%   %   % vehicle's 2D outline and tires, and the four sides in words;
%   %   % the photo's name above it; "Mark wrong faces": clicks on the
%   %   % model make a yellow box, and the report gives the script's
%   %   % labelEditsAfterFit line for what the faces should be
%   % * Differences: large headers; the selected spot's box yellow, the
%   %   % others gray; no "All differences" item
%   % * Lights, Body, Steering, Wheels, Drive: drawn live from the mesh
%   %   % and the test motion (no GIFs): crisp, rotatable while playing,
%   %   % at night for the lights, with the view following the vehicle
%   % * Sean's third review: the mouse works as in CAD programs (left-drag
%   %   % rotates, right-drag pans, the wheel zooms; a click picks), done
%   %   % by the reviewer itself, as MATLAB's own rotating did not work in
%   %   % the linked and animated views; the view buttons beside the
%   %   % question; a "?" button (no answer yet) between Approve and Reject
%   % * Picking faces (Labels and Differences): a click picks the piece of
%   %   % faces under it, Shift-click adds one; the item is rejected, and
%   %   % the report writes the script's labelEditsAfterFit line for what
%   %   % they should be, including "deleted" (a part of the download not
%   %   % wanted, such as a rear wiper)
%   % * Orientation: the axes as arrows from the vehicle's origin, through
%   %   % the see-through body
%   % * Differences: spots ranked by the area affected (holes count
%   %   % double); label changes outlined on their faces; what each kind
%   %   % means when the mouse rests on it; the zoom kept between spots
%   % * Animations: two copies of the vehicle, from ahead-left and from
%   %   % behind-right; matte paint; the lights seen from farther, so the
%   %   % light on the ground shows; the player and input plot only for
%   %   % the whole animation; skid marks under slipping tires (wheels,
%   %   % drive)
%   % * Ground contact taken out (a simulation test: nothing to see)
%   % * Labels: painting (Sean's design, 03:37 to 03:46): pick a label,
%   %   % Ctrl+drag paints faces (Ctrl+Shift+drag erases, click: one face,
%   %   % double-click: a piece), mirrored to the other side; glass is
%   %   % seen through except with the glass tool, so parts behind it
%   %   % (lamps) can be reached; saved in the vehicle's labelEdits file,
%   %   % applied by its script after simplifying; "what is wrong" list
%   %   % (missing, hidden, wrong faces); Show all labels under the items;
%   %   % black mesh edges for one label; Reset view fits the model
%   % * Animations: the views stay put between items (no player or plot);
%   %   % "The whole animation" plays over and over, its step items lit up
%   %   % (bold, the others gray) as each step shows
%   % * "All, in turn" (Dimensions, Labels, Differences, 2D outline): an
%   %   % item that shows the others in turn, over and over, lit up in the
%   %   % list; approving it approves every item not answered yet
%   % * Detail levels: a line-up of the full mesh and every level at one
%   %   % distance (top), and each level where it is used (bottom), all
%   %   % turning slowly; one question for all levels
%   % * Detail levels: the pairs fanned out across the view (none behind
%   %   % another)
%   % * Reject: the comment first (or "No comment"), then Minor or Must
%   %   % fix, under the comment box, which saves and goes on
%   % * 2D outline: "Show the 3D model (see-through)" under the items,
%   %   % with rotating
%   % * Minor and Must fix as two large buttons under Reject
%   % * 2D outline and the photo dial: each wheel's rectangle placed at its
%   %   % center (it is kept about its center, for steering); all four
%   %   % were drawn at the origin
%   % * Summary: where the answers are saved (they are saved as they are
%   %   % made), and a SAVE AND CLOSE button

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * 'interior' (fcn_CarMesh3D_labelInterior): a paint tool, a "should
%   %   % be" choice, and a Labels item when the mesh has interior faces
%   % * "All, in turn" starts at the first item of the check (it skipped
%   %   % to the second; Sean, 05:07)
%   % * Painting (Sean, 05:13): painted faces are filled in their new
%   %   % label's color (only their edges showed), on lifted copies; a
%   %   % second click on a painted face takes the paint off; a "Hide"
%   %   % list (glass; glass and lights; glass and trim) makes those parts
%   %   % see-through and unpaintable, to reach faces under them
%   % * Labels: the model in a panel of its own (zoomed in, it drew over
%   %   % the dial and the photo)
%   % * Undo takes back the last click or stroke, newest first, each
%   %   % press one more (Sean, 05:48); applied ones come back out of the
%   %   % modified mesh too; Revert clears the steps
%   % * The paint tool in use is marked: full color, bold, with a dot
%   %   % (Sean, 05:34)
%   % * Labels: a Show box beside each label in Items (Sean, 05:34);
%   %   % unticked hides its faces, to reach the faces under them
%   % * Label edits in three layers (Sean, 05:32): paint is pending
%   %   % (yellow edges) until Apply, which makes it part of a temporary
%   %   % modified mesh (deleted faces go out of view and reach); Save
%   %   % applies and writes the labelEdits file; Undo, Revert to save,
%   %   % Revert to start; a status line; "Show deleted faces"; closing
%   %   % asks to save
%   % * The animation checks (Lights, Body, Steering, Wheels, Drive) are
%   %   % now fcn_CarMesh3D_animateChecks, built in the display panel
%   %   % (Sean, 06:00: separate tools, so the passing of the mesh is
%   %   % clear). It is given the mesh with the painted label edits (the
%   %   % painter's applied edits; else the saved edits, when newer than
%   %   % the mesh file), so a face painted as a lamp lights up in the
%   %   % Lights check without rerunning the script
%   % * Leaving the Labels check with label edits not saved asks to save
%   %   % them (the painter is rebuilt from the saved edits when shown
%   %   % again)
%   % * The 2D outline check is now fcn_CarMesh3D_viewOutline, built in
%   %   % the display panel; the interior outlines are an item (they were
%   %   % not shown)
%   % * The detail-levels check is now fcn_CarMesh3D_viewDetailLevels,
%   %   % built in the display panel
%   % * The orientation and dimensions checks are now
%   %   % fcn_CarMesh3D_viewOrientation and fcn_CarMesh3D_viewDimensions,
%   %   % built in the display panel
%   % * The overall decision goes in the vehicle's change log
%   %   % (fcn_CarMesh3D_meshHistory: who, when, the decision), so the
%   %   % mesh shows as reviewed, and by whom (Sean, 13:07)
%   % * Differences compares the download with the edited mesh (Sean,
%   %   % 10:51): the mesh with the saved label edits, or the painter's
%   %   % applied edits; its spots are found again when the painter has
%   %   % changed it, and each spot's item is keyed by where it is, so
%   %   % its answer stays with it
%   % * The vehicle may be given as its folder (the demo's copy of a
%   %   % vehicle, so a demo review is saved in the copy, not the vehicle)
%   % * The items panel's title no longer has "(right column: show)"
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * Multi-part faces (FaceAlsoParts): a part that faces only also
%   %   % belong to (glass that is a lamp's clear cover) is reviewed too

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewVehicle
%   % * Light states drawn live (each light on, at night) in a rotatable
%   %   % view, in place of the animation's stills
%   % * A press-and-hold "show all labels" (uifigure buttons have no
%   %   % press and release events: it is a toggle for now)


arguments
    vehicleID
    options.Reviewer = ''
    options.Visible = true
    options.FigNum = []
end

%% Debugging and Input checks
flag_check_inputs = 1;
if isequal(options.FigNum, -1)
    flag_check_inputs = 0;
end
if 0~=flag_check_inputs
    if ~(ischar(vehicleID) || (isstring(vehicleID) && isscalar(vehicleID)))
        error('CarMesh3D:badInput', 'vehicleID must be text, such as ''2009_Honda_Fit_Sport''.');
    end
end
vehicleID = char(vehicleID);
reviewerName = char(options.Reviewer);
if isempty(reviewerName)
    reviewerName = getenv('USERNAME');
    if isempty(reviewerName)
        reviewerName = getenv('USER');
    end
end

%% Main code
% The vehicle's files and data
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID);
vehicleID = vehicleFiles.ID;   % (the input may be the vehicle's folder)
if ~vehicleFiles.HasMesh
    error('CarMesh3D:noMesh', 'The vehicle %s has no finished mesh yet: run its script first.', vehicleID);
end
data = fcn_INTERNAL_loadData(vehicleFiles);
checks = fcn_INTERNAL_defineChecks(data);
reviewFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.mat', vehicleID));
reportFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.md', vehicleID));
reviewTable = fcn_INTERNAL_startAnswers(checks, reviewFile);

% The window's state (shared by the nested callbacks below)
currentCheck = 1;
currentItem = 1;
flagCommentTouched = false;
cycleTimer = [];
cycleIndex = 0;
animator = [];   % (the animation checks: fcn_CarMesh3D_animateChecks's handles and functions)
outlineViewer = [];   % (the 2D outline check: fcn_CarMesh3D_viewOutline's handles and functions)
levelsViewer = [];   % (the detail-levels check: fcn_CarMesh3D_viewDetailLevels's handles and functions)
dimensionViewer = [];   % (the dimensions check: fcn_CarMesh3D_viewDimensions's handles and functions)
orientationViewer = [];   % (the orientation check: fcn_CarMesh3D_viewOrientation's handles and functions)
% (the mouse, CAD-style: left-drag rotates, right-drag pans, the wheel
% zooms; a click with no drag picks faces)
mouseAxes = [];
mouseMode = '';
mouseStart = [0 0];
mouseLast = [0 0];
mouseMoved = false;
mouseExtend = false;
lastAxes = [];
pendingPick = [];
% (the faces picked on Labels or Differences: which mesh, and which faces)
selectionMesh = '';
selectedFaces = false(0,1);
meshPieces = struct('reduced', [], 'original', []);
% (painting labels, on the Labels check: the label painter,
% fcn_CarMesh3D_paintLabels, built in the display panel; the Show boxes
% beside each label in Items, unticked to hide its faces; and the mesh
% with the painter's applied edits, once it has changed them)
painter = [];
hideChecks = struct();
editedMeshNow = [];
compareStale = false;   % (the painter changed the edited mesh since Differences found its spots)
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleID));
axesDefaults = struct('Axes',{},'View',{});
linkHandle = []; %#ok<SETNU> (held, so the two Differences views stay linked)
compareSpots = [];
labelPatch = [];
showAllButton = [];
% (the Labels check's model, from the painter; the timer that turns the
% detail levels)
labelAxes = [];
viewTimer = [];

%% The window
figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_reviewVehicle: %s', vehicleFiles.Name), ...
    'Position', [40 40 1560 940], 'Visible', 'off', 'Color', [1 1 1], ...
    'CloseRequestFcn', @onClose, 'AutoResizeChildren', 'off');
% (the title bar: this function's name and version; the rest under it)
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_reviewVehicle', Subtitle=vehicleFiles.Name, FigNum=-1);
mainGrid = uigridlayout(contentPanel, [1 3], 'ColumnWidth', {150, '1x', 360}, 'Padding', [6 6 6 6]);

% Left: the tools, stacked at the top, and a hint under them. (The mouse
% works the views as in CAD programs: left-drag rotates, right-drag pans,
% the wheel zooms; the view buttons are on the right, by the question.)
toolGrid = uigridlayout(mainGrid, [4 1], 'RowHeight', {34, 34, 12, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 6);
uibutton(toolGrid, 'Text', 'Save report', 'ButtonPushedFcn', @(~,~) fcn_INTERNAL_writeReport(reviewTable, checks, vehicleFiles, reportFile));
uibutton(toolGrid, 'Text', 'Close', 'ButtonPushedFcn', @onClose);
uilabel(toolGrid, 'Text', '');
hintLabel = uilabel(toolGrid, 'Text', '', 'FontColor', [0.35 0.35 0.35], 'WordWrap', 'on', ...
    'VerticalAlignment', 'top', 'Interpreter', 'html');

% Middle: the panel's title, and the display
centerGrid = uigridlayout(mainGrid, [3 1], 'RowHeight', {50, 40, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 2);
uilabel(centerGrid, 'Text', ['  ' fcn_INTERNAL_vehicleTitle(vehicleFiles)], 'FontSize', 32, 'FontWeight', 'bold', ...
    'FontColor', [1 1 1], 'BackgroundColor', [0.15 0.25 0.45], 'HorizontalAlignment', 'left');
titleLabel = uilabel(centerGrid, 'Text', '', 'FontSize', 20, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.86 0.92 1], 'HorizontalAlignment', 'left');
displayPanel = uipanel(centerGrid, 'BorderType', 'none', 'BackgroundColor', [1 1 1]);

% Right: the checks, the items, and the question in the bottom-right corner
rightGrid = uigridlayout(mainGrid, [5 1], 'RowHeight', {210, '1x', 0, 34, 450}, 'Padding', [0 0 0 0], 'RowSpacing', 6);
checkGroup = uibuttongroup(rightGrid, 'Title', 'Checks', 'Scrollable', 'on', ...
    'SelectionChangedFcn', @onCheckChanged, 'FontWeight', 'bold');
checkButtons = gobjects(numel(checks),1);
for ith_check = 1:numel(checks)
    checkButtons(ith_check) = uiradiobutton(checkGroup, 'Text', checks(ith_check).Title, ...
        'Position', [10 10 330 22], 'UserData', ith_check);
end
itemGroup = uibuttongroup(rightGrid, 'Title', 'Items', 'Scrollable', 'on', ...
    'SelectionChangedFcn', @onItemChanged, 'FontWeight', 'bold');
% (under the items, on the Labels check only: show every label at once)
checkButtonGrid = uigridlayout(rightGrid, [1 2], 'ColumnWidth', {'1x', 0}, 'Padding', [0 0 0 0], 'ColumnSpacing', 0);
showAllButton = uibutton(checkButtonGrid, 'state', 'Text', 'Show all labels', 'Enable', 'off', ...
    'ValueChangedFcn', @onShowAll, 'Tooltip', 'Show every label at once; press again (or pick an item) to go back to one label');
% (under the items, on the 2D outline check only: the 3D model, see-through)
model3DButton = uibutton(checkButtonGrid, 'state', 'Text', 'Show the 3D model (see-through)', ...
    'ValueChangedFcn', @onModel3D, 'Tooltip', 'The vehicle in 3D, see-through, over the outlines; left-drag then rotates');
% (the view buttons, by the question, so the mouse need not cross the screen)
viewGrid = uigridlayout(rightGrid, [1 3], 'Padding', [0 0 0 0], 'ColumnSpacing', 4);
uibutton(viewGrid, 'Text', 'Reset view', 'ButtonPushedFcn', @onResetView, ...
    'Tooltip', 'Put the views back as they were. Mouse: left-drag rotates, right-drag pans, the wheel zooms.');
uibutton(viewGrid, 'Text', 'Zoom +', 'ButtonPushedFcn', @(~,~) onZoom(1.25), 'Tooltip', 'Zoom in (or the mouse wheel)');
uibutton(viewGrid, 'Text', 'Zoom -', 'ButtonPushedFcn', @(~,~) onZoom(0.8), 'Tooltip', 'Zoom out (or the mouse wheel)');
answerPanel = uipanel(rightGrid, 'Title', 'Question', 'FontWeight', 'bold');
answerGrid = uigridlayout(answerPanel, [10 2], 'RowHeight', {64, 34, 36, 26, 26, 24, '1x', 34, 30, 30}, 'ColumnWidth', {'1x','1x'}, ...
    'RowSpacing', 4, 'Padding', [8 6 8 6]);
questionLabel = uilabel(answerGrid, 'Text', '', 'WordWrap', 'on', 'FontSize', 13, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
questionLabel.Layout.Column = [1 2];
% (Approve, "?" for no answer yet, and Reject)
voteGrid = uigridlayout(answerGrid, [1 3], 'ColumnWidth', {'1x', 44, '1x'}, ...
    'Padding', [0 0 0 0], 'ColumnSpacing', 6);
voteGrid.Layout.Column = [1 2];
approveButton = uibutton(voteGrid, 'state', 'Text', 'Approve', 'FontSize', 13, ...
    'ValueChangedFcn', @(src,~) onVote(src, 'approved'));
uibutton(voteGrid, 'Text', '?', 'FontSize', 15, 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) onClearAnswer(), ...
    'Tooltip', 'No answer yet: takes back Approve or Reject');
rejectButton = uibutton(voteGrid, 'state', 'Text', 'Reject', 'FontSize', 13, ...
    'ValueChangedFcn', @(src,~) onVote(src, 'rejected'));
% (what to do on the model: shown for checks where faces can be picked)
selectLabel = uilabel(answerGrid, 'Text', '', 'WordWrap', 'on', 'FontColor', [0.55 0.35 0], 'FontWeight', 'bold', ...
    'VerticalAlignment', 'top');
selectLabel.Layout.Column = [1 2];
causeDropDown = uidropdown(answerGrid, 'Items', {'(likely cause)'}, 'ValueChangedFcn', @onCause);
causeDropDown.Layout.Column = [1 2];
% (orientation only: which way is really up)
upDropDown = uidropdown(answerGrid, 'Items', {'(up is really)'}, 'ValueChangedFcn', @onCause, 'Visible', 'off');
upDropDown.Layout.Column = [1 2];
commentGrid = uigridlayout(answerGrid, [1 2], 'ColumnWidth', {64, 90}, 'Padding', [0 0 0 0], 'ColumnSpacing', 4);
uilabel(commentGrid, 'Text', 'Comment:', 'FontWeight', 'bold');
noCommentButton = uibutton(commentGrid, 'Text', 'No comment', 'ButtonPushedFcn', @(~,~) onCommentTouched(), ...
    'Tooltip', 'Go on to the severity with no comment');
statusLabel = uilabel(answerGrid, 'Text', '', 'HorizontalAlignment', 'right', 'FontColor', [0.4 0.4 0.4]);
commentArea = uitextarea(answerGrid, 'ValueChangedFcn', @onComment, 'ValueChangingFcn', @(~,~) onCommentTouched());
commentArea.Layout.Column = [1 2];
% (after a rejection and a comment: how bad; either one saves and goes on)
severityGrid = uigridlayout(answerGrid, [1 2], 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
severityGrid.Layout.Column = [1 2];
minorButton = uibutton(severityGrid, 'state', 'Text', ['Minor  ' char(9654)], 'FontSize', 13, ...
    'ValueChangedFcn', @(src,~) onSeverityButton('minor'), 'Tooltip', 'A minor problem: saves, and goes on to the next question');
mustFixButton = uibutton(severityGrid, 'state', 'Text', ['Must fix  ' char(9654)], 'FontSize', 13, 'FontWeight', 'bold', ...
    'ValueChangedFcn', @(src,~) onSeverityButton('must fix'), 'Tooltip', 'Must be fixed: saves, and goes on to the next question');
uibutton(answerGrid, 'Text', char([9664 ' Previous']), 'ButtonPushedFcn', @(~,~) onStep(-1));
uibutton(answerGrid, 'Text', char(['Next unanswered ' 9654]), 'ButtonPushedFcn', @(~,~) onStep(+1));
approveAllButton = uibutton(answerGrid, 'Text', 'Approve all unanswered items in this check', ...
    'ButtonPushedFcn', @(~,~) onApproveAll(), ...
    'Tooltip', 'Approve every item of this check that has no answer yet, then go to the next check');
approveAllButton.Layout.Column = [1 2];

figureHandle.SizeChangedFcn = @(~,~) fcn_INTERNAL_placeButtons(checkGroup, checkButtons);
figureHandle.WindowButtonDownFcn = @onFigureDown;       % (the mouse in the views)
figureHandle.WindowButtonMotionFcn = @onFigureMotion;   % (and dragging the photo dial)
figureHandle.WindowButtonUpFcn = @onFigureUp;
figureHandle.WindowScrollWheelFcn = @onFigureScroll;
figureHandle.DeleteFcn = @(~,~) stopAllTimers();     % (also when deleted without closing)
fcn_INTERNAL_placeButtons(checkGroup, checkButtons);
showCheck(1);
% (for scripts and tests: show a check or an item, answer, and read the
% answers)
figureHandle.UserData = struct('ShowCheck', @showCheck, 'ShowItem', @showItem, ...
    'Vote', @testVote, 'ApproveAll', @onApproveAll, 'ShowAll', @testShowAll, ...
    'Current', @getCurrent, 'SetPhotoAngle', @testPhotoAngle, 'PhotoAngle', @getPhotoAngle, ...
    'Pick', @testPick, 'Paint', @testPaint, 'EditsFile', editsFile, 'SetCause', @testSetCause, 'ReportFile', reportFile, ...
    'Answers', @getAnswers, 'CheckKeys', {{checks.Key}}, 'Animator', @getAnimator, 'ItemKeys', @getItemKeys);
if options.Visible
    figureHandle.Visible = 'on';
end

%% Nested callbacks (they share the window's state above)

    function onCheckChanged(~, event)
        showCheck(event.NewValue.UserData);
    end

    function onItemChanged(~, event)
        % (picking an item ends "show all labels")
        if showAllButton.Value
            showAllButton.Value = false;
            onShowAll(showAllButton);
        end
        showItem(event.NewValue.UserData);
    end

    function testVote(status)
        % (for tests: press Approve or Reject on the current item)
        if strcmp(status, 'approved')
            approveButton.Value = true;
            onVote(approveButton, 'approved');
        else
            rejectButton.Value = true;
            onVote(rejectButton, 'rejected');
        end
    end

    function current = getCurrent()
        % (for tests: the check and item shown; a nested function, so it
        % sees the values now, not when the window was made)
        current = [currentCheck currentItem];
    end

    function answers = getAnswers()
        answers = reviewTable;
    end

    function setHint(textIn)
        % (the hint under the tools: plain text, or HTML for colors)
        hintLabel.Text = strrep(char(textIn), newline, '<br>');
    end

    function testSetCause(cause, cause2)
        % (for tests: pick from the question's lists)
        causeDropDown.Value = cause;
        if nargin > 1
            upDropDown.Value = cause2;
        end
        onCause();
    end

    function testPhotoAngle(angle)
        % (for tests: turn the photo dial to this angle and let go)
        if painterValid()
            painter.SetPhotoAngle(angle);
        end
    end

    function angle = getPhotoAngle()
        % (for tests: the angle of the photo shown, or NaN)
        angle = NaN;
        if painterValid()
            angle = painter.PhotoAngle();
        end
    end

    function testShowAll(flagOn)
        % (for tests: press "Show all labels")
        showAllButton.Value = flagOn;
        onShowAll(showAllButton);
    end

    function onApproveAll()
        % Approve every item of this check with no answer, then go on
        thisCheck = checks(currentCheck);
        if strcmp(thisCheck.Key, 'summary')
            return;
        end
        for itemIndex = 1:numel(thisCheck.Items)
            row = find(reviewTable.Check==string(thisCheck.Key) & reviewTable.Item==string(thisCheck.Items(itemIndex).Key), 1);
            if strlength(reviewTable.Status(row))==0
                reviewTable.Status(row) = "approved";
                reviewTable.Reviewer(row) = string(reviewerName);
                reviewTable.Time(row) = string(datetime('now','Format','yyyy-MM-dd HH:mm'));
            end
        end
        fcn_INTERNAL_saveAnswers(reviewTable, reviewFile);
        refreshMarks();
        onStep(+1);
    end

    function showCheck(checkIndex)
        leavePainter();   % (asked while the painter is still on screen)
        stopPlaying();
        stopCycle();
        currentCheck = checkIndex;
        if strcmp(checks(checkIndex).Key, 'compare')
            refreshCompare();
        end
        fcn_INTERNAL_placeButtons(checkGroup, checkButtons);
        checkGroup.SelectedObject = checkButtons(checkIndex);
        delete(displayPanel.Children);
        delete(itemGroup.Children);
        linkHandle = [];
        axesDefaults = struct('Axes',{},'View',{});
        animator = [];
        outlineViewer = [];
        levelsViewer = [];
        dimensionViewer = [];
        orientationViewer = [];
        labelPatch = [];
        stopViewTimer();
        stopPainter();
        labelAxes = [];
        showAllButton.Enable = 'off';
        showAllButton.Value = false;
        rightGrid.RowHeight{3} = 0;
        model3DButton.Value = false;
        checkButtonGrid.ColumnWidth = {'1x', 0};
        hideChecks = struct();
        selectionMesh = '';
        selectedFaces = false(0,1);
        mouseAxes = [];
        lastAxes = [];
        showAllButton.Text = 'Show all labels';
        setHint('');
        thisCheck = checks(checkIndex);
        itemGroup.Title = sprintf('Items in %s', thisCheck.Title);
        approveAllButton.Enable = ~strcmp(thisCheck.Key, 'summary');
        itemButtons = gobjects(numel(thisCheck.Items),1);
        for ith_item = 1:numel(thisCheck.Items)
            itemButtons(ith_item) = uiradiobutton(itemGroup, 'Text', thisCheck.Items(ith_item).Label, ...
                'Position', [8 8 330 22], 'UserData', ith_item, 'Tooltip', thisCheck.Items(ith_item).Tooltip);
        end
        fcn_INTERNAL_placeButtons(itemGroup, itemButtons);
        if strcmp(thisCheck.Key, 'labels')
            % (a second column: a Show box beside each label; untick it to
            % hide that label's faces and reach the faces under them)
            itemGroup.Title = sprintf('Items in %s', thisCheck.Title);
            for ith_item = 1:numel(thisCheck.Items)
                itemKey = thisCheck.Items(ith_item).Key;
                if strcmp(itemKey, 'all')
                    continue;
                end
                radioPosition = itemButtons(ith_item).Position;
                itemButtons(ith_item).Position(3) = radioPosition(3) - 30;
                hideChecks.(matlab.lang.makeValidName(itemKey)) = uicheckbox(itemGroup, 'Text', '', 'Value', true, ...
                    'Position', [radioPosition(1) + radioPosition(3) - 24, radioPosition(2), 22, 22], 'UserData', itemKey, ...
                    'ValueChangedFcn', @(~,~) applyShowBoxes(), ...
                    'Tooltip', 'Show these faces (untick to hide them, to see and paint the faces under them)');
            end
        end
        drawCheck(thisCheck);
        showItem(1);
        refreshMarks();
    end

    function radios = itemRadios()
        % The item list's radio buttons, top to bottom (the Show boxes of
        % the Labels check are left out)
        radios = flipud(findobj(itemGroup.Children, 'flat', 'Type', 'uiradiobutton'));
    end

    function showItem(itemIndex)
        currentItem = itemIndex;
        flagCommentTouched = false;
        itemButtons = itemRadios();
        if ~isempty(itemButtons)
            itemGroup.SelectedObject = itemButtons(itemIndex);
        end
        thisItem = checks(currentCheck).Items(itemIndex);
        titleLabel.Text = sprintf('  %s  %c  %s      (check %d of %d)', upper(checks(currentCheck).Title), 8212, ...
            thisItem.Label, currentCheck, numel(checks));
        if numel(checks(currentCheck).Items) == 1
            titleLabel.Text = sprintf('  %s      (check %d of %d)', upper(checks(currentCheck).Title), currentCheck, numel(checks));
        end
        questionLabel.Text = thisItem.Question;
        approveButton.Text = thisItem.ApproveText;
        rejectButton.Text = thisItem.RejectText;
        drawItem(checks(currentCheck), thisItem);
        showAnswer();
    end

    function showAnswer()
        row = answerRow();
        answer = reviewTable(row,:);
        approveButton.Value = strcmp(answer.Status, 'approved');
        rejectButton.Value = strcmp(answer.Status, 'rejected');
        flagRejected = strcmp(answer.Status, 'rejected');
        severityGrid.Visible = flagRejected;
        noCommentButton.Visible = flagRejected;
        % (Minor and Must fix wait for a comment, or "No comment")
        flagCommentTouched = flagCommentTouched || strlength(answer.Comment) > 0;
        minorButton.Enable = flagRejected && flagCommentTouched;
        mustFixButton.Enable = flagRejected && flagCommentTouched;
        minorButton.Value = flagRejected && strcmp(answer.Severity, 'minor') && flagCommentTouched;
        mustFixButton.Value = flagRejected && strcmp(answer.Severity, 'must fix') && flagCommentTouched;
        minorButton.BackgroundColor = [0.96 0.96 0.96] - 0.12*minorButton.Value*[0 0 1];
        mustFixButton.BackgroundColor = [0.96 0.96 0.96] - 0.25*mustFixButton.Value*[0 1 1];
        thisItem = checks(currentCheck).Items(currentItem);
        if strcmp(checks(currentCheck).Key, 'labels')
            Npainted = 0;
            if painterValid()
                Npainted = painter.NumPainted();
            end
            selectLabel.Text = sprintf(['To fix: pick a label above the model, then Ctrl+drag over the wrong faces ' ...
                '(%d faces painted so far, for all labels).'], Npainted);
        elseif strcmp(checks(currentCheck).Key, 'compare')
            if strlength(answer.Region) > 0
                selectLabel.Text = sprintf('Faces picked (%s). Pick what they should be below. Click again to change them.', ...
                    fcn_INTERNAL_orText(answer.SelectionPart, 'box saved'));
            else
                selectLabel.Text = 'To fix: click the wrong faces on the model (Shift-click adds a piece), then pick what they should be.';
            end
        else
            selectLabel.Text = '';
        end
        causeParts = strsplit(char(answer.Cause), ' | ');
        causeDropDown.Visible = flagRejected && ~isempty(thisItem.Causes);
        if ~isempty(thisItem.Causes)
            causeDropDown.Items = [{thisItem.CausePrompt}, thisItem.Causes];
            if any(strcmp(causeDropDown.Items, causeParts{1}))
                causeDropDown.Value = causeParts{1};
            else
                causeDropDown.Value = thisItem.CausePrompt;
            end
        end
        upDropDown.Visible = flagRejected && ~isempty(thisItem.Causes2);
        if ~isempty(thisItem.Causes2)
            upDropDown.Items = [{thisItem.Cause2Prompt}, thisItem.Causes2];
            if numel(causeParts) >= 2 && any(strcmp(upDropDown.Items, causeParts{2}))
                upDropDown.Value = causeParts{2};
            else
                upDropDown.Value = thisItem.Cause2Prompt;
            end
        end
        commentArea.Value = char(answer.Comment);
        if strlength(answer.Status) > 0
            statusLabel.Text = sprintf('%s by %s, %s', answer.Status, answer.Reviewer, answer.Time);
            if flagRejected && ~flagCommentTouched
                statusLabel.Text = 'comment first, then Minor or Must fix';
            end
        else
            statusLabel.Text = 'not answered yet';
        end
    end

    function row = answerRow()
        row = find(reviewTable.Check==string(checks(currentCheck).Key) & ...
            reviewTable.Item==string(checks(currentCheck).Items(currentItem).Key), 1);
    end

    function onVote(source, status)
        % Approve or Reject. Pressing a button that is already down keeps
        % the answer (it does not take it back: "Clear this answer" does).
        % Approving goes straight on to the next item with no answer; a
        % rejection stays, for its severity, cause, and comment.
        row = answerRow();
        source.Value = true;
        if reviewTable.Status(row) ~= string(status)
            reviewTable.Status(row) = status;
            if strcmp(status, 'rejected')
                % (the severity is chosen after the comment)
            else
                reviewTable.Severity(row) = "";
                reviewTable.Cause(row) = "";
            end
            stampAndSave(row);
        end
        showAnswer();
        refreshMarks();
        if strcmp(status, 'approved') && strcmp(checks(currentCheck).Items(currentItem).Key, 'all')
            onApproveAll();   % ("All, in turn" approved: every item not answered yet, then on)
            return;
        end
        if strcmp(status, 'approved') && ~strcmp(checks(currentCheck).Key, 'summary')
            onStep(+1);
        end
    end

    function onClearAnswer()
        row = answerRow();
        reviewTable.Status(row) = "";
        reviewTable.Severity(row) = "";
        reviewTable.Cause(row) = "";
        stampAndSave(row);
        showAnswer();
        refreshMarks();
    end

    %% The mouse, CAD-style
    function onFigureDown(~, ~)
        % Left button: rotate (pan, in the 2D views); right button: pan.
        % A press and release with no drag is a click: it picks faces.
        pendingPick = [];
        clicked = figureHandle.CurrentObject;
        axesHandle = [];
        if ~isempty(clicked) && isvalid(clicked)
            axesHandle = ancestor(clicked, 'axes');
        end
        if isempty(axesHandle) || ~any(arrayfun(@(entry) isequal(entry.Axes, axesHandle), axesDefaults))
            mouseAxes = [];
            return;
        end
        mouseAxes = axesHandle;
        lastAxes = axesHandle;
        selection = figureHandle.SelectionType;
        modifiers = figureHandle.CurrentModifier;
        mouseExtend = strcmp(selection, 'extend');
        if isequal(axesHandle, labelAxes) && any(strcmp(modifiers, 'control'))
            % (MATLAB reports Ctrl+click as 'alt', like a right click: the
            % Ctrl key is what tells painting apart)
            % (Ctrl+drag paints on the Labels model; Ctrl+Shift+drag
            % erases; the painter does it)
            mouseMode = 'stroke';
            painter.StrokeStart(any(strcmp(modifiers, 'shift')));
        elseif strcmp(selection, 'open') && isequal(axesHandle, labelAxes)
            mouseMode = 'piece';   % (a double-click: the whole piece, on release)
        elseif strcmp(selection, 'alt') || isappdata(axesHandle, 'mouse2D')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseStart = figureHandle.CurrentPoint;
        mouseLast = mouseStart;
        mouseMoved = false;
    end

    function onFigureScroll(~, event)
        % The wheel zooms the view under the mouse
        axesHandle = axesUnderMouse();
        if isempty(axesHandle)
            return;
        end
        camzoom(axesHandle, 1.15^(-event.VerticalScrollCount));
    end

    function axesHandle = axesUnderMouse()
        % (the view the mouse is over; else the last one used)
        axesHandle = [];
        point = figureHandle.CurrentPoint;
        for ith_axes = 1:numel(axesDefaults)
            candidate = axesDefaults(ith_axes).Axes;
            if ~isvalid(candidate)
                continue;
            end
            try
                position = getpixelposition(candidate, true);
            catch
                position = [];
            end
            if numel(position)==4 && point(1)>=position(1) && point(1)<=position(1)+position(3) && ...
                    point(2)>=position(2) && point(2)<=position(2)+position(4)
                axesHandle = candidate;
                lastAxes = candidate;
                return;
            end
        end
        if ~isempty(lastAxes) && isvalid(lastAxes)
            axesHandle = lastAxes;
        end
    end

    function onPatchDown(source, event)
        % (a click on a pickable mesh: remembered, and picked on release
        % if the mouse did not drag)
        pendingPick = struct('Mesh', source.UserData, 'Point', event.IntersectionPoint);
    end

    function testPaint(tool, points, flagErase)
        % (for tests: paint the faces nearest these points with a tool, and
        % save, in the painter)
        if painterValid()
            painter.Paint(tool, points, flagErase);
        end
    end

    function testPick(meshKey, point, flagExtend)
        % (for tests: a click on a mesh at this point)
        handlePick(meshKey, point, flagExtend);
    end

    function onZoom(factor)
        allAxes = [axesDefaults.Axes];
        for ith_axes = 1:numel(allAxes)
            if isvalid(allAxes(ith_axes))
                camzoom(allAxes(ith_axes), factor);
            end
        end
    end

    function onSeverityButton(severity)
        % Minor or Must fix: saved with the comment, then on to the next
        % question with no answer
        row = answerRow();
        reviewTable.Severity(row) = string(severity);
        reviewTable.Comment(row) = string(strjoin(cellstr(commentArea.Value), newline));
        stampAndSave(row);
        showAnswer();
        refreshMarks();
        onStep(+1);
    end

    function onCommentTouched()
        % (a comment typed, or "No comment": Minor and Must fix can be used)
        flagCommentTouched = true;
        minorButton.Enable = true;
        mustFixButton.Enable = true;
        if strcmp(statusLabel.Text, 'comment first, then Minor or Must fix')
            statusLabel.Text = 'now Minor or Must fix';
        end
    end

    function onCause(~, ~)
        % The likely cause (and, for the orientation, which way is really
        % up), saved as "cause" or "cause | up"
        row = answerRow();
        thisItem = checks(currentCheck).Items(currentItem);
        cause = causeDropDown.Value;
        if strcmp(cause, thisItem.CausePrompt)
            cause = '';
        end
        if ~isempty(thisItem.Causes2)
            upCause = upDropDown.Value;
            if strcmp(upCause, thisItem.Cause2Prompt)
                upCause = '';
            end
            if ~isempty(cause) || ~isempty(upCause)
                cause = [cause ' | ' upCause];
            end
        end
        reviewTable.Cause(row) = string(cause);
        stampAndSave(row);
    end

    function onComment(source, ~)
        row = answerRow();
        reviewTable.Comment(row) = string(strjoin(cellstr(source.Value), newline));
        stampAndSave(row);
        refreshMarks();
    end

    function stampAndSave(row)
        reviewTable.Reviewer(row) = string(reviewerName);
        reviewTable.Time(row) = string(datetime('now','Format','yyyy-MM-dd HH:mm'));
        fcn_INTERNAL_saveAnswers(reviewTable, reviewFile);
        showAnswerStatusOnly(row);
        if reviewTable.Check(row) == "summary" && strlength(reviewTable.Status(row)) > 0
            % (the overall decision goes in the vehicle's change log: who
            % reviewed it, when, and the decision)
            try
                fcn_CarMesh3D_meshHistory(vehicleFiles.Folder, Action=sprintf('reviewed: %s', reviewTable.Status(row)), ...
                    Who=reviewerName, Details=char(reviewTable.Comment(row)), FigNum=-1);
            catch
            end
        end
    end

    function showAnswerStatusOnly(row)
        if strlength(reviewTable.Status(row)) > 0
            statusLabel.Text = sprintf('%s by %s, %s', reviewTable.Status(row), reviewTable.Reviewer(row), reviewTable.Time(row));
        else
            statusLabel.Text = 'not answered yet (comment saved)';
        end
    end

    function onStep(direction)
        % Previous: the item before. Next: the next item with no answer,
        % in this check, then in the checks after it.
        if direction < 0
            if currentItem > 1
                showItem(currentItem-1);
            elseif currentCheck > 1
                showCheck(currentCheck-1);
            end
            return;
        end
        % (this check first: the items after this one, then those before
        % it; then the checks after this one)
        Nchecks = numel(checks);
        for offset = 0:Nchecks
            checkIndex = mod(currentCheck-1+offset, Nchecks) + 1;
            itemOrder = 1:numel(checks(checkIndex).Items);
            if offset==0
                itemOrder = [currentItem+1:numel(checks(checkIndex).Items), 1:currentItem-1];
            end
            for itemIndex = itemOrder
                row = reviewTable.Check==string(checks(checkIndex).Key) & reviewTable.Item==string(checks(checkIndex).Items(itemIndex).Key);
                if strlength(reviewTable.Status(row))==0
                    if checkIndex ~= currentCheck
                        announceMove(currentCheck, checkIndex);
                        showCheck(checkIndex);
                    end
                    showItem(itemIndex);
                    return;
                end
            end
        end
        % Everything is answered: the summary
        if currentCheck ~= numel(checks)
            announceMove(currentCheck, numel(checks));
            showCheck(numel(checks));
        end
    end

    function announceMove(fromCheck, toCheck)
        % A short notice before moving to another check: this check is
        % done, and any checks skipped were done already
        if ~strcmp(figureHandle.Visible, 'on')
            return;   % (hidden, for tests: no pause)
        end
        skipped = {};
        index = fromCheck;
        while true
            index = mod(index, numel(checks)) + 1;
            if index == toCheck || index == fromCheck
                break;
            end
            skipped{end+1} = checks(index).Title; %#ok<AGROW>
        end
        message = sprintf('%s: every item is answered.', upper(checks(fromCheck).Title));
        if ~isempty(skipped)
            message = sprintf('%s  Already done: %s.', message, strjoin(skipped, ', '));
        end
        message = sprintf('  %s  Moving to %s ...', message, upper(checks(toCheck).Title));
        oldColor = titleLabel.BackgroundColor;
        titleLabel.Text = message;
        titleLabel.BackgroundColor = [1 0.9 0.5];
        drawnow;
        pause(0.9);
        if isvalid(titleLabel)
            titleLabel.BackgroundColor = oldColor;
        end
    end

    function refreshMarks()
        % Marks on the check and item buttons: answered / total, and a
        % check mark, a cross, or a dot for each item
        for checkIndex = 1:numel(checks)
            rows = reviewTable.Check==string(checks(checkIndex).Key);
            Nanswered = sum(strlength(reviewTable.Status(rows))>0);
            Nrejected = sum(reviewTable.Status(rows)=="rejected");
            mark = '';
            if Nrejected > 0
                mark = sprintf('  %c%d', 10007, Nrejected);
            end
            checkButtons(checkIndex).Text = sprintf('%s (%d/%d)%s', checks(checkIndex).Title, Nanswered, sum(rows), mark);
            if Nrejected > 0
                checkButtons(checkIndex).FontColor = [0.75 0 0];
            elseif Nanswered == sum(rows)
                checkButtons(checkIndex).FontColor = [0 0.5 0];
            else
                checkButtons(checkIndex).FontColor = [0 0 0];
            end
        end
        itemButtons = itemRadios();
        for itemIndex = 1:numel(itemButtons)
            row = reviewTable.Check==string(checks(currentCheck).Key) & reviewTable.Item==string(checks(currentCheck).Items(itemIndex).Key);
            switch reviewTable.Status(row)
                case "approved"
                    prefix = char(10003); itemColor = [0 0.5 0];
                case "rejected"
                    prefix = char(10007); itemColor = [0.75 0 0];
                otherwise
                    prefix = '?'; itemColor = [0 0 0];
            end
            itemButtons(itemIndex).Text = sprintf('%s %s', prefix, checks(currentCheck).Items(itemIndex).Label);
            itemButtons(itemIndex).FontColor = itemColor;
        end
        if strcmp(checks(currentCheck).Key, 'summary')
            drawSummary();
        end
    end

    %% Drawing each check
    function drawCheck(thisCheck)
        switch thisCheck.Kind
            case 'orientation'
                % (from its tool, fcn_CarMesh3D_viewOrientation)
                orientationViewer = fcn_CarMesh3D_viewOrientation(data.Mesh, Parent=displayPanel, OnHint=@setHint, FigNum=-1);
                axesDefaults(end+1) = struct('Axes', orientationViewer.Axes, 'View', fcn_INTERNAL_getView(orientationViewer.Axes));
            case 'labels'
                showAllButton.Enable = 'on';
                rightGrid.RowHeight{3} = 34;
                drawLabels();
            case 'dimensions'
                drawDimensions();
            case 'compare'
                drawCompare();
            case 'animation'
                drawAnimation(thisCheck);
            case 'image'
                layout = uigridlayout(displayPanel, [1 1], 'Padding', [0 0 0 0]);
                if isfile(thisCheck.File)
                    uiimage(layout, 'ImageSource', thisCheck.File, 'ScaleMethod', 'fit');
                else
                    uilabel(layout, 'Text', sprintf('Not made yet: %s', thisCheck.File), 'HorizontalAlignment', 'center');
                end
            case 'levels'
                drawLevels();
            case 'outline'
                rightGrid.RowHeight{3} = 34;
                checkButtonGrid.ColumnWidth = {0, '1x'};
                drawOutline();
            case 'summary'
                drawSummary();
        end
    end

    function drawItem(thisCheck, thisItem)
        stopCycle();
        if strcmp(thisItem.Key, 'all')
            startCycle();
            return;
        end
        switch thisCheck.Kind
            case 'labels'
                if ~showAllButton.Value
                    colorLabel(thisItem.Key);
                end
                selectionMesh = '';
                selectedFaces = false(0,1);
                showSelection();
            case 'dimensions'
                drawDimensionItem(thisItem);
            case 'compare'
                drawCompareItem(thisItem);
            case 'animation'
                showAnimationItem(thisItem);
            case 'outline'
                drawOutlineItem(thisItem);
        end
    end

    %% 3D axes: rotate and zoom with nothing cut away; reset
    function axesHandle = newAxes3D(parent)
        if ~isa(parent, 'matlab.ui.container.GridLayout')
            % (in a grid of its own, so it grows with the window)
            parent = uigridlayout(parent, [1 1], 'Padding', [0 0 0 0]);
        end
        axesHandle = uiaxes(parent);
        hold(axesHandle, 'on');
        axis(axesHandle, 'off');
        axesHandle.Color = [1 1 1];
        axesHandle.Clipping = 'off';
    end

    function finishAxes3D(axesHandle)
        axis(axesHandle, 'equal');
        axis(axesHandle, 'vis3d');
        set(findobj(axesHandle, '-property', 'Clipping'), 'Clipping', 'off');
        camlight(axesHandle, 'headlight');
        % Drag rotates, scroll zooms. Every object is drawn unclipped, so
        % zooming in (which narrows the axes limits) cuts nothing away.
        fcn_INTERNAL_quietAxes(axesHandle);
        axesDefaults(end+1) = struct('Axes', axesHandle, 'View', fcn_INTERNAL_getView(axesHandle));
        hintLabel.Text = 'Mouse: left-drag rotates, right-drag pans, the wheel zooms.';
    end

    function onResetView(~, ~)
        % 3D views: fitted again to the whole scene, from the direction
        % they started from; the fixed views (dimensions, levels, outline)
        % and the animations: as they were made
        for ith_axes = 1:numel(axesDefaults)
            axesHandle = axesDefaults(ith_axes).Axes;
            if ~isvalid(axesHandle)
                continue;
            end
            if isappdata(axesHandle, 'mouse2D') || isappdata(axesHandle, 'lastPose')
                fcn_INTERNAL_setView(axesHandle, axesDefaults(ith_axes).View);
            else
                startView = axesDefaults(ith_axes).View;
                direction = startView.CameraPosition - startView.CameraTarget;
                set(axesHandle, 'XLimMode', 'auto', 'YLimMode', 'auto', 'ZLimMode', 'auto', ...
                    'CameraTargetMode', 'auto', 'CameraPositionMode', 'auto', 'CameraViewAngleMode', 'auto', ...
                    'CameraUpVector', [0 0 1]);
                view(axesHandle, atan2d(direction(1), -direction(2)), atan2d(direction(3), norm(direction(1:2))));
            end
        end
    end

    %% Labels
    function drawLabels()
        % The label painter (fcn_CarMesh3D_paintLabels), built in the
        % display panel: the model with its paint tools, and the photo dial
        % and photo. The reviewer passes it the mouse, the item shown, and
        % the Show boxes; it passes back each paint (the item is rejected:
        % it has a fix) and the edited mesh.
        [~, ~, painter] = fcn_CarMesh3D_paintLabels(vehicleFiles.Folder, Parent=displayPanel, Who=reviewerName, ...
            OnPaint=@onPainterPaint, OnChange=@onPainterChange, OnHint=@setHint, FigNum=-1);
        labelAxes = painter.Axes;
        labelPatch = painter.Patch;
        labelPatch.ButtonDownFcn = @onPatchDown;   % (a click paints a face)
        axesDefaults(end+1) = struct('Axes', labelAxes, 'View', fcn_INTERNAL_getView(labelAxes));
        applyShowBoxes();
    end

    function flagValid = painterValid()
        flagValid = isstruct(painter) && isfield(painter, 'Axes') && isvalid(painter.Axes);
    end

    function stopPainter()
        if isstruct(painter)
            try
                painter.Stop();
            catch
            end
        end
        painter = [];
    end

    function leavePainter()
        % Leaving the Labels check: the painter is rebuilt from the saved
        % edits when it is shown again, so changes not saved are asked
        % about (saved, in a hidden window, as in the tests). Discarded:
        % the animations go back to the saved edits too.
        if ~painterValid() || ~painter.IsUnsaved()
            return;
        end
        choice = 'Save';
        if strcmp(figureHandle.Visible, 'on')
            choice = uiconfirm(figureHandle, ['The label edits have changes that are not saved. Save them? ' ...
                '(Discarded, they are gone when Labels is shown again.)'], ...
                'Label edits', 'Options', {'Save', 'Discard'}, 'DefaultOption', 1, 'CancelOption', 2);
        end
        if strcmp(choice, 'Save')
            painter.Save();
        else
            editedMeshNow = [];
            compareStale = true;
        end
    end

    function onPainterPaint()
        % A click or stroke painted: the Labels item is rejected (it has a
        % fix now), and the count of painted faces shown
        if ~strcmp(checks(currentCheck).Key, 'labels')
            return;
        end
        row = answerRow();
        if reviewTable.Status(row) ~= "rejected"
            reviewTable.Status(row) = "rejected";
            reviewTable.Severity(row) = "minor";
            reviewTable.Cause(row) = "some faces have the wrong label (painted)";
            stampAndSave(row);
            refreshMarks();
        end
        showAnswer();
    end

    function onPainterChange(meshNow)
        % The edited mesh, as applied in the painter (for the checks after)
        editedMeshNow = meshNow;
        compareStale = true;   % (Differences finds its spots again)
    end

    function applyShowBoxes()
        % The Show boxes beside the labels in Items: the unticked ones'
        % faces are hidden in the painter
        if ~painterValid()
            return;
        end
        hiddenNow = {};
        boxNames = fieldnames(hideChecks);
        for ith_box = 1:numel(boxNames)
            thisBox = hideChecks.(boxNames{ith_box});
            if isvalid(thisBox) && ~thisBox.Value
                hiddenNow{end+1} = thisBox.UserData; %#ok<AGROW>
            end
        end
        painter.SetHidden(hiddenNow);
    end

    function onFigureMotion(~, ~)
        % (the painter first: dragging its photo dial, or a paint stroke)
        if painterValid() && painter.MouseMove()
            drawnow limitrate;
            return;
        end
        if isempty(mouseAxes) || ~isvalid(mouseAxes)
            return;
        end
        point = figureHandle.CurrentPoint;
        if ~mouseMoved && norm(point - mouseStart) < 4
            return;   % (a click, so far)
        end
        mouseMoved = true;
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'stroke')
            return;
        elseif strcmp(mouseMode, 'rotate')
            camorbit(mouseAxes, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(mouseAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function onFigureUp(~, ~)
        % (the painter first: the dial snaps to a photo, or a stroke ends)
        flagPainterUsed = painterValid() && painter.MouseUp();
        if flagPainterUsed || strcmp(mouseMode, 'stroke')
            % (done)
        elseif ~isempty(mouseAxes) && ~mouseMoved && ~isempty(pendingPick)
            handlePick(pendingPick.Mesh, pendingPick.Point, mouseExtend);
        end
        mouseAxes = [];
        mouseMode = '';
        pendingPick = [];
    end

    function stopAllTimers()
        stopViewTimer();
        stopPlaying();
        stopCycle();
    end

    function stopViewTimer()
        if ~isempty(viewTimer) && isvalid(viewTimer)
            stop(viewTimer);
            delete(viewTimer);
        end
        viewTimer = [];
        if ~isempty(levelsViewer) && isstruct(levelsViewer)
            levelsViewer.Stop();   % (the detail levels' turning)
        end
    end

    function colorLabel(labelKey)
        % One label in its colors, the rest gray (in the painter)
        if painterValid()
            painter.ShowLabel(labelKey);
        end
    end


    function handlePick(meshKey, point, flagExtend)
        % A click on a mesh (Labels or Differences): the connected piece
        % of faces with one label under the click is picked; Shift-click
        % adds or takes away a piece. Picking rejects the item, and the
        % faces' box (and their part) is saved for the script's fix.
        if ~any(strcmp(checks(currentCheck).Key, {'labels', 'compare'}))
            return;
        end
        if strcmp(checks(currentCheck).Key, 'labels')
            % (Labels: a click paints the face under it with the tool; a
            % double-click paints the whole piece; the painter does it)
            if painterValid()
                painter.Click(strcmp(mouseMode, 'piece'));
            end
            return;
        end
        if strcmp(meshKey, 'original')
            pickMesh = data.OriginalMesh;
        else
            pickMesh = data.CompareMesh;
        end
        if isempty(pickMesh)
            return;
        end
        if isempty(meshPieces.(meshKey))
            meshPieces.(meshKey) = fcn_INTERNAL_meshPieces(pickMesh);
        end
        pieces = meshPieces.(meshKey);
        centers = fcn_INTERNAL_faceCenters(pickMesh);
        [~, face] = min(sum((centers - point(:)').^2, 2));
        piece = pieces == pieces(face);
        if ~strcmp(selectionMesh, meshKey) || numel(selectedFaces) ~= numel(piece)
            selectionMesh = meshKey;
            selectedFaces = false(size(piece));
        end
        if flagExtend
            if all(selectedFaces(piece))
                selectedFaces(piece) = false;
            else
                selectedFaces(piece) = true;
            end
        elseif isequal(selectedFaces, piece)
            selectedFaces(:) = false;
        else
            selectedFaces = piece;
        end
        row = answerRow();
        if any(selectedFaces)
            pickedVertices = pickMesh.Vertices(unique(pickMesh.Faces(selectedFaces,:)),:);
            region = [min(pickedVertices,[],1); max(pickedVertices,[],1)];
            region = region(:)' + 0.01*[-1 1 -1 1 -1 1];
            reviewTable.Region(row) = string(mat2str(round(region, 3)));
            reviewTable.SelectionPart(row) = string(fcn_INTERNAL_mainPart(pickMesh, selectedFaces));
            if reviewTable.Status(row) ~= "rejected"
                reviewTable.Status(row) = "rejected";
                reviewTable.Severity(row) = "minor";
            end
        else
            reviewTable.Region(row) = "";
            reviewTable.SelectionPart(row) = "";
        end
        stampAndSave(row);
        showAnswer();
        refreshMarks();
        showSelection();
    end

    function showSelection()
        % The picked faces, outlined in yellow on their mesh; with no
        % faces picked in this session, the item's saved box
        allAxes = [axesDefaults.Axes];
        for ith_axes = 1:numel(allAxes)
            if isvalid(allAxes(ith_axes))
                delete(findobj(allAxes(ith_axes), 'Tag', 'selection'));
            end
        end
        if any(selectedFaces)
            if strcmp(selectionMesh, 'original')
                pickMesh = data.OriginalMesh;
            else
                pickMesh = data.CompareMesh;
            end
            for ith_axes = 1:numel(allAxes)
                meshPatch = findobj(allAxes(ith_axes), 'Type', 'patch', 'UserData', selectionMesh);
                if isvalid(allAxes(ith_axes)) && ~isempty(meshPatch)
                    patch(allAxes(ith_axes), 'Faces', pickMesh.Faces(selectedFaces,:), 'Vertices', pickMesh.Vertices, ...
                        'FaceColor', [1 0.85 0], 'FaceAlpha', 0.35, 'EdgeColor', [1 0.75 0], 'LineWidth', 1.5, ...
                        'Tag', 'selection', 'HitTest', 'off', 'Clipping', 'off');
                end
            end
            return;
        end
        region = str2num(char(reviewTable.Region(answerRow()))); %#ok<ST2NM>
        if numel(region) == 6
            for ith_axes = 1:numel(allAxes)
                if isvalid(allAxes(ith_axes)) && ~isappdata(allAxes(ith_axes), 'mouse2D')
                    fcn_INTERNAL_drawBox(allAxes(ith_axes), reshape(region, 2, 3), [1 0.75 0], 3, 'selection');
                end
            end
        end
    end

    function onShowAll(source, ~)
        if ~painterValid()
            source.Value = false;
        end
        if source.Value
            painter.ShowLabel('all');
            source.Text = 'All labels: ON (stop)';
            source.BackgroundColor = [1 0.85 0.4];
        else
            source.Text = 'Show all labels';
            source.BackgroundColor = [0.96 0.96 0.96];
            colorLabel(checks(currentCheck).Items(currentItem).Key);
        end
    end

    %% Dimensions
    function drawDimensions()
        % The dimensions check, from its tool (fcn_CarMesh3D_viewDimensions),
        % built in the display panel; a click on a row of its table goes to
        % that item
        dimensionViewer = fcn_CarMesh3D_viewDimensions(data.Mesh, DimensionTable=data.DimensionTable, ...
            Parent=displayPanel, OnSelect=@onDimensionRow, OnHint=@setHint, FigNum=-1);
        for axesHandle = dimensionViewer.Axes
            axesDefaults(end+1) = struct('Axes', axesHandle, 'View', fcn_INTERNAL_getView(axesHandle)); %#ok<AGROW>
        end
    end

    function onDimensionRow(quantity)
        % (the table's rows are the dimensions; the items start with "All,
        % in turn")
        itemIndex = find(strcmp({checks(currentCheck).Items.Key}, quantity), 1);
        if ~isempty(itemIndex) && itemIndex ~= currentItem
            showItem(itemIndex);
        end
    end

    function drawDimensionItem(thisItem)
        if ~isempty(dimensionViewer)
            dimensionViewer.ShowDimension(thisItem.Key);
        end
    end

    %% Differences from the download
    function drawCompare()
        if isempty(data.OriginalMesh)
            uilabel(displayPanel, 'Text', 'The download''s mesh is not in the cache (run the vehicle''s script with the comparison on).', ...
                'Position', [20 20 700 30]);
            return;
        end
        layout = uigridlayout(displayPanel, [2 2], 'RowHeight', {44, '1x'}, 'ColumnWidth', {'1x','1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 0);
        uilabel(layout, 'Text', sprintf('THE DOWNLOAD  (%d faces)', size(data.OriginalMesh.Faces,1)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 20, 'BackgroundColor', [0.86 0.92 1]);
        uilabel(layout, 'Text', sprintf('THE REDUCED MESH, WITH THE LABEL EDITS  (%d faces)', size(data.CompareMesh.Faces,1)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 20, 'BackgroundColor', [1 0.93 0.8]);
        leftAxes = newAxes3D(layout);
        leftPatch = fcn_INTERNAL_drawMesh(leftAxes, data.OriginalMesh, data.OriginalMesh.FaceColors, data.OriginalMesh.FaceAlpha);
        set(leftPatch, 'UserData', 'original', 'ButtonDownFcn', @onPatchDown);   % (a click picks faces)
        rightAxes = newAxes3D(layout);
        rightPatch = fcn_INTERNAL_drawMesh(rightAxes, data.CompareMesh, data.CompareMesh.FaceColors, data.CompareMesh.FaceAlpha);
        set(rightPatch, 'UserData', 'reduced', 'ButtonDownFcn', @onPatchDown);
        for axesHandle = [leftAxes rightAxes]
            view(axesHandle, -40, 20);
            finishAxes3D(axesHandle);
            axesHandle.Color = [0.86 0.92 1];   % (sky)
        end
        linkHandle = linkprop([leftAxes rightAxes], {'CameraPosition','CameraTarget','CameraUpVector','CameraViewAngle','XLim','YLim','ZLim'});
        compareSpots = data.Spots;
        for ith_spot = 1:numel(compareSpots)
            for axesHandle = [leftAxes rightAxes]
                fcn_INTERNAL_drawSpot(axesHandle, data.OriginalMesh, compareSpots(ith_spot), ith_spot);
            end
        end
        setHint(['Mouse: left-drag rotates, right-drag pans, the wheel zooms (both views turn together).<br><br>' ...
            'A <b>hole</b> is a box; a <b>label change</b> is outlined on its faces. The selected spot is yellow.<br><br>' ...
            'To fix a spot (such as a part to delete): Reject, then click its faces on either mesh.']);
    end

    function drawCompareItem(thisItem)
        allAxes = findobj(displayPanel, 'Type', 'axes');
        selectionMesh = '';
        selectedFaces = false(0,1);
        showSelection();
        for ith_axes = 1:numel(allAxes)
            set(findobj(allAxes(ith_axes), '-regexp', 'Tag', '^spot', 'Type', 'line'), 'LineWidth', 1, 'Color', [0.6 0.6 0.6]);
            set(findobj(allAxes(ith_axes), '-regexp', 'Tag', '^spot', 'Type', 'patch'), 'EdgeColor', [0.55 0.55 0.55], 'LineWidth', 0.75);
        end
        spotIndex = find(strcmp({compareSpots.Key}, thisItem.Key), 1);
        if isempty(spotIndex) || spotIndex > numel(compareSpots) || isempty(allAxes)
            onResetView();
            return;
        end
        for ith_axes = 1:numel(allAxes)
            set(findobj(allAxes(ith_axes), 'Tag', sprintf('spot%d', spotIndex), 'Type', 'line'), 'LineWidth', 5, 'Color', [1 0.85 0]);
            set(findobj(allAxes(ith_axes), 'Tag', sprintf('spot%d', spotIndex), 'Type', 'patch'), 'EdgeColor', [1 0.8 0], 'LineWidth', 2.5);
        end
        % Look at the spot from outside the vehicle, toward its center,
        % keeping the zoom (the view's distance and angle) as it is
        box = compareSpots(spotIndex).Box;
        spotCenter = mean(reshape(box,2,3),1);
        direction = spotCenter - [mean(data.Mesh.Vertices(:,1:2),1) 0.5];
        direction(3) = max(direction(3), 0.3);
        direction = direction/norm(direction);
        axesHandle = allAxes(1);
        distance = norm(axesHandle.CameraPosition - axesHandle.CameraTarget);
        set(axesHandle, 'CameraTarget', spotCenter, 'CameraPosition', spotCenter + direction*distance, 'CameraUpVector', [0 0 1]);
        drawnow;
    end

    %% Animations (lights, body, steering, wheels, drive)
    function drawAnimation(thisCheck)
        % The check's motion, from the animation tool
        % (fcn_CarMesh3D_animateChecks), built in the display panel. The
        % mesh given is the mesh with the painted label edits (the
        % painter's, as applied there; else as saved), so a face painted as
        % a lamp lights up in the Lights check. Its steps are this check's
        % items after "The whole animation".
        stepRows = [thisCheck.Items.Row];   % (the whole animation has no row)
        animator = fcn_CarMesh3D_animateChecks(animationMesh(), thisCheck.Key, TestMotion=data.TestMotion, ...
            Rows=thisCheck.Rows, StepRows=stepRows, Parent=displayPanel, ...
            OnStep=@lightStepItem, OnHint=@setHint, FigNum=-1);
        for ith_view = 1:numel(animator.Axes)
            if isgraphics(animator.Axes(ith_view))
                axesDefaults(end+1) = struct('Axes', animator.Axes(ith_view), ...
                    'View', fcn_INTERNAL_getView(animator.Axes(ith_view))); %#ok<AGROW>
            end
        end
    end

    function meshOut = animationMesh()
        % The mesh the animations use: the painter's edited mesh (once it
        % has applied edits), else the mesh with the saved edits
        if ~isempty(editedMeshNow)
            meshOut = editedMeshNow;
        else
            meshOut = data.CompareMesh;
        end
    end

    function refreshCompare()
        % Differences compares the download with the edited mesh (Sean,
        % 10:51). When the painter has changed it since the spots were
        % found, find them again, and remake the check's items; answers
        % stay with their spots (keyed by where they are)
        if ~compareStale || isempty(data.OriginalMesh)
            return;
        end
        compareStale = false;
        if isempty(editedMeshNow)
            data.CompareMesh = fcn_INTERNAL_meshWithSavedEdits(vehicleFiles, data.Mesh);
        else
            data.CompareMesh = editedMeshNow;
        end
        meshPieces.reduced = [];
        data.Spots = fcn_INTERNAL_spotsOf(data.OriginalMesh, data.CompareMesh);
        newChecks = fcn_INTERNAL_defineChecks(data);
        compareIndex = find(strcmp({checks.Key}, 'compare'), 1);
        checks(compareIndex).Items = newChecks(strcmp({newChecks.Key}, 'compare')).Items;
        reviewTable = fcn_INTERNAL_carryAnswers(fcn_INTERNAL_startAnswers(checks, ''), reviewTable);
        fcn_INTERNAL_saveAnswers(reviewTable, reviewFile);
        refreshMarks();
    end

    function keys = getItemKeys()
        % (for tests: the current check's item keys)
        keys = {checks(currentCheck).Items.Key};
    end

    function animatorOut = getAnimator()
        % (for tests: the animation tool now shown)
        animatorOut = animator;
    end

    function flag = animatorValid()
        flag = ~isempty(animator) && isstruct(animator) && ~isempty(animator.Axes) && all(isgraphics(animator.Axes));
    end

    function showAnimationItem(thisItem)
        % A step: its scene, in the same views (they are not moved). The
        % whole animation: played over and over, its step items lit up
        % in turn.
        if ~animatorValid()
            return;
        end
        if isempty(thisItem.Row)
            animator.ShowStep(0);
        else
            stepIndex = find([animator.Steps.Row] == thisItem.Row, 1);
            if ~isempty(stepIndex)
                animator.ShowStep(stepIndex);
            end
        end
    end

    function startCycle()
        % "All, in turn": each item of the check shown for 2.5 s, over and
        % over, lit up in the list; the selection stays on "All, in turn".
        % It starts at the first item (showCycleItem steps before it shows,
        % so the count starts at 0; starting at 1 skipped the first item)
        cycleIndex = 0;
        showCycleItem();
        cycleTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 2.5, 'BusyMode', 'drop', ...
            'TimerFcn', @(~,~) showCycleItem());
        start(cycleTimer);
    end

    function showCycleItem()
        thisCheck = checks(currentCheck);
        if numel(thisCheck.Items) < 2 || ~strcmp(thisCheck.Items(currentItem).Key, 'all')
            stopCycle();
            return;
        end
        cycleIndex = mod(cycleIndex, numel(thisCheck.Items)-1) + 1;   % (items 2 to N)
        itemIndex = cycleIndex + 1;
        thisItem = thisCheck.Items(itemIndex);
        switch thisCheck.Kind
            case 'labels'
                if ~showAllButton.Value
                    colorLabel(thisItem.Key);
                end
            case 'dimensions'
                drawDimensionItem(thisItem);
            case 'compare'
                drawCompareItem(thisItem);
            case 'outline'
                drawOutlineItem(thisItem);
        end
        titleLabel.Text = sprintf('  %s  %c  All, in turn: %s      (check %d of %d)', upper(thisCheck.Title), 8212, ...
            thisItem.Label, currentCheck, numel(checks));
        itemButtons = itemRadios();
        for ith_button = 2:numel(itemButtons)
            if ith_button == itemIndex
                set(itemButtons(ith_button), 'FontWeight', 'bold', 'FontColor', [0 0 0]);
            else
                set(itemButtons(ith_button), 'FontWeight', 'normal', 'FontColor', [0.65 0.65 0.65]);
            end
        end
        drawnow limitrate;
    end

    function stopCycle()
        if ~isempty(cycleTimer)
            if isvalid(cycleTimer)
                stop(cycleTimer);
                delete(cycleTimer);
            end
            cycleTimer = [];
            if isvalid(itemGroup)
                set(itemRadios(), 'FontWeight', 'normal');
                refreshMarks();
            end
        end
    end

    function lightStepItem(stepIndex)
        % (as the whole animation plays: the item of the step now showing
        % in bold, the other steps in gray; 0, when it stops: the items
        % back to their usual look). Step k is item k+1.
        if ~isvalid(itemGroup)
            return;
        end
        itemButtons = itemRadios();
        if stepIndex == 0
            set(itemButtons, 'FontWeight', 'normal');
            refreshMarks();
            return;
        end
        for ith_button = 2:numel(itemButtons)
            if ith_button == stepIndex + 1
                set(itemButtons(ith_button), 'FontWeight', 'bold', 'FontColor', [0 0 0]);
            else
                set(itemButtons(ith_button), 'FontWeight', 'normal', 'FontColor', [0.65 0.65 0.65]);
            end
        end
    end

    function stopPlaying()
        % (the animation tool's timer, before its panel is cleared)
        if ~isempty(animator) && isstruct(animator)
            animator.Stop();
        end
    end


    %% Detail levels
    function drawLevels()
        % The detail-levels check, from its tool
        % (fcn_CarMesh3D_viewDetailLevels), built in the display panel:
        % a line-up at one distance, and each level beside the full mesh
        % where it is used; all turning slowly
        levelsViewer = fcn_CarMesh3D_viewDetailLevels(data.Levels, Mesh=data.Mesh, Parent=displayPanel, ...
            OnHint=@setHint, FigNum=-1);
        for axesHandle = [levelsViewer.LineupAxes, levelsViewer.SceneAxes]
            axesDefaults(end+1) = struct('Axes', axesHandle, 'View', fcn_INTERNAL_getView(axesHandle)); %#ok<AGROW>
        end
    end

    %% 2D outline
    function drawOutline()
        % The 2D outline check, from its tool (fcn_CarMesh3D_viewOutline),
        % built in the display panel
        outlineViewer = fcn_CarMesh3D_viewOutline(data.Outline, Mesh=data.Mesh, Parent=displayPanel, ...
            OnHint=@setHint, FigNum=-1);
        if ~isempty(outlineViewer.Axes)
            axesDefaults(end+1) = struct('Axes', outlineViewer.Axes, 'View', fcn_INTERNAL_getView(outlineViewer.Axes));
        end
    end

    function onModel3D(source, ~)
        % The 3D model over the outlines (see-through), with rotating; or
        % back to the flat view from above
        if isempty(outlineViewer) || isempty(outlineViewer.Axes) || ~isvalid(outlineViewer.Axes)
            source.Value = false;
            return;
        end
        outlineViewer.SetModel3D(source.Value);
    end

    function drawOutlineItem(thisItem)
        if ~isempty(outlineViewer)
            outlineViewer.ShowElement(thisItem.Key);
        end
    end

    %% Summary
    function drawSummary()
        delete(displayPanel.Children);
        layout = uigridlayout(displayPanel, [5 3], 'RowHeight', {30, '1x', 70, 30, 56}, 'ColumnWidth', {'1x', 200, 200}, 'Padding', [4 4 4 4]);
        isQuestion = reviewTable.Check ~= "summary";
        Nquestions = sum(isQuestion);
        Napproved = sum(reviewTable.Status(isQuestion)=="approved");
        Nrejected = sum(reviewTable.Status(isQuestion)=="rejected");
        NmustFix = sum(reviewTable.Severity(isQuestion)=="must fix");
        Nopen = Nquestions - Napproved - Nrejected;
        countLabel = uilabel(layout, 'FontSize', 14, 'FontWeight', 'bold', 'Text', ...
            sprintf('%d questions: %d approved, %d rejected (%d must be fixed), %d not answered', ...
            Nquestions, Napproved, Nrejected, NmustFix, Nopen));
        countLabel.Layout.Column = [1 3];
        shown = reviewTable(isQuestion, {'Check','Item','Status','Severity','Cause','Comment'});
        for ith_row = 1:height(shown)
            checkIndex = find(strcmp({checks.Key}, shown.Check(ith_row)), 1);
            itemIndex = find(strcmp({checks(checkIndex).Items.Key}, shown.Item(ith_row)), 1);
            shown.Check(ith_row) = string(checks(checkIndex).Title);
            shown.Item(ith_row) = string(checks(checkIndex).Items(itemIndex).Label);
        end
        tableHandle = uitable(layout, 'Data', shown, 'RowName', {}, 'CellSelectionCallback', @onSummaryCell);
        tableHandle.Layout.Column = [1 3];
        openRows = find(strlength(shown.Status)==0);
        rejectedRows = find(shown.Status=="rejected");
        if ~isempty(openRows)
            addStyle(tableHandle, uistyle('BackgroundColor', [1 0.93 0.75]), 'row', openRows);
        end
        if ~isempty(rejectedRows)
            addStyle(tableHandle, uistyle('FontColor', [0.8 0 0], 'FontWeight', 'bold'), 'row', rejectedRows);
        end
        overallRow = find(reviewTable.Check=="summary", 1);
        overallLabel = uilabel(layout, 'WordWrap', 'on', 'Text', ...
            sprintf('Overall decision: %s. Click a row to go to that question. Unanswered rows are shaded.', ...
            fcn_INTERNAL_orText(reviewTable.Status(overallRow), 'none yet')));
        overallLabel.Layout.Column = 1;
        bigApprove = uibutton(layout, 'Text', 'APPROVE VEHICLE', 'FontSize', 16, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.75 0.92 0.75], 'ButtonPushedFcn', @(~,~) onOverall("approved"));
        bigApprove.Layout.Column = 2;
        bigReject = uibutton(layout, 'Text', 'REJECT VEHICLE', 'FontSize', 16, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.98 0.78 0.78], 'ButtonPushedFcn', @(~,~) onOverall("rejected"));
        bigReject.Layout.Column = 3;
        warnLabel = uilabel(layout, 'Text', '', 'FontColor', [0.7 0.4 0]);
        warnLabel.Layout.Row = 4;
        warnLabel.Layout.Column = [1 3];
        if Nopen > 0
            warnLabel.Text = sprintf('%d questions have no answer yet (shaded).', Nopen);
        end
        % (where the answers are, and that they are saved; and a way out)
        savedLabel = uilabel(layout, 'WordWrap', 'on', 'FontColor', [0 0.45 0], 'Text', sprintf(['Every answer is saved ' ...
            'as it is made, in %s (open the reviewer again to carry on). The readable report, %s, is written when ' ...
            'the window closes, on Save report, and on the overall decision.'], reviewFile, reportFile));
        savedLabel.Layout.Row = 5;
        savedLabel.Layout.Column = [1 2];
        closeButton = uibutton(layout, 'Text', 'SAVE AND CLOSE', 'FontSize', 16, 'FontWeight', 'bold', ...
            'ButtonPushedFcn', @onClose, 'Tooltip', 'Saves the answers and the report, and closes the reviewer');
        closeButton.Layout.Row = 5;
        closeButton.Layout.Column = 3;
        function onSummaryCell(~, event)
            if isempty(event.Indices)
                return;
            end
            questionRows = find(isQuestion);
            row = questionRows(event.Indices(1));
            checkIndex = find(strcmp({checks.Key}, reviewTable.Check(row)), 1);
            itemIndex = find(strcmp({checks(checkIndex).Items.Key}, reviewTable.Item(row)), 1);
            showCheck(checkIndex);
            showItem(itemIndex);
        end
    end

    function onOverall(status)
        row = find(reviewTable.Check=="summary", 1);
        reviewTable.Status(row) = status;
        stampAndSave(row);
        fcn_INTERNAL_writeReport(reviewTable, checks, vehicleFiles, reportFile);
        showCheck(numel(checks));
    end

    function onClose(~, ~)
        stopPlaying();
        stopCycle();
        % (label edits not saved: asked, when the window is on screen; a
        % hidden window, as in the tests, saves them)
        try
            if painterValid() && painter.IsUnsaved()
                choice = 'Save';
                if strcmp(figureHandle.Visible, 'on')
                    choice = uiconfirm(figureHandle, 'The label edits have changes that are not saved. Save them?', ...
                        'Label edits', 'Options', {'Save', 'Discard'}, 'DefaultOption', 1, 'CancelOption', 2);
                end
                if strcmp(choice, 'Save')
                    painter.Save();
                end
            end
        catch
        end
        stopPainter();
        stopViewTimer();
        try
            fcn_INTERNAL_saveAnswers(reviewTable, reviewFile);
            fcn_INTERNAL_writeReport(reviewTable, checks, vehicleFiles, reportFile);
        catch closeError
            warning('CarMesh3D:reviewSave', 'Could not save the review: %s', closeError.message);
        end
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

%% fcn_INTERNAL_loadData
function data = fcn_INTERNAL_loadData(vehicleFiles)
% Everything the reviewer shows: the mesh and its label colors, the
% download's mesh, the test motion and dimension check (from the checks'
% cache), the detail levels, and the 2D outline
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
data.Mesh = loaded.vehicleMesh;
if ~isfield(data.Mesh, 'FaceAlpha') || isempty(data.Mesh.FaceAlpha)
    data.Mesh.FaceAlpha = ones(size(data.Mesh.Faces,1),1);
end
labelMesh = fcn_CarMesh3D_plotLabels(data.Mesh, FigNum=-1);
data.LabelColors = labelMesh.FaceColors;
data.LabelAlpha = labelMesh.FaceAlpha(:);
if isscalar(data.LabelAlpha)
    data.LabelAlpha = repmat(data.LabelAlpha, size(data.Mesh.Faces,1), 1);
end
data.ChecksFolder = vehicleFiles.ChecksFolder;

cacheFolder = fullfile(vehicleFiles.Folder, 'cache');
data.OriginalMesh = [];
stage1File = fullfile(cacheFolder, 'stage1_mesh.mat');
if isfile(stage1File)
    stage1 = load(stage1File, 'cacheOutputs');
    if isfield(stage1.cacheOutputs, 'originalMesh') && ~isempty(stage1.cacheOutputs.originalMesh)
        data.OriginalMesh = stage1.cacheOutputs.originalMesh;
        if ~isfield(data.OriginalMesh, 'FaceAlpha') || isempty(data.OriginalMesh.FaceAlpha)
            data.OriginalMesh.FaceAlpha = ones(size(data.OriginalMesh.Faces,1),1);
        end
    end
end

% (the mesh with the label edits saved: Differences compares the download
% with it, and the animations show it; Sean, 10:51)
data.CompareMesh = fcn_INTERNAL_meshWithSavedEdits(vehicleFiles, data.Mesh);
data.Spots = fcn_INTERNAL_spotsOf(data.OriginalMesh, data.CompareMesh);

data.TestMotion = [];
data.DimensionTable = table(strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), false(0,1));
stage3File = fullfile(cacheFolder, 'stage3_checks.mat');
if isfile(stage3File)
    stage3 = load(stage3File, 'cacheOutputs');
    if isfield(stage3.cacheOutputs, 'checkResults')
        checkResults = stage3.cacheOutputs.checkResults;
        data.TestMotion = checkResults.TestMotion;
        validation = checkResults.ValidationTable;
        data.DimensionTable = table(string(validation.Quantity), round(validation.Target_m,4), ...
            round(validation.Measured_m,4), round(validation.PercentError,2), logical(validation.Pass));
    end
end
data.Geometry = fcn_INTERNAL_geometry(data.Mesh);

data.Levels = [];
if vehicleFiles.HasLevels
    loaded = load(vehicleFiles.LevelsFile, 'detailLevels');
    data.Levels = loaded.detailLevels;
end
data.Outline = [];
data.OutlineElements = struct('Key',{},'Label',{},'Polygons',{});
if vehicleFiles.HasOutline
    loaded = load(vehicleFiles.OutlineFile, 'vehicleOutline');
    data.Outline = loaded.vehicleOutline;
    data.OutlineElements = fcn_INTERNAL_outlineElements(data.Outline);
end
end % Ends fcn_INTERNAL_loadData

%% fcn_INTERNAL_meshWithSavedEdits
function meshOut = fcn_INTERNAL_meshWithSavedEdits(vehicleFiles, vehicleMesh)
% The mesh with the label edits saved: the mesh file, unless the edits
% were saved after it was made (the script not run since); then the
% stage-1 mesh with the saved edits applied, as the painter gives it
meshOut = vehicleMesh;
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
if isfile(editsFile) && isfile(vehicleFiles.MeshFile)
    editsInfo = dir(editsFile);
    meshInfo = dir(vehicleFiles.MeshFile);
    if editsInfo.datenum > meshInfo.datenum
        [meshOut, ~, savedPainter] = fcn_CarMesh3D_paintLabels(vehicleFiles.Folder, Visible=false, FigNum=-1);
        savedPainter.Close();
    end
end
if ~isfield(meshOut, 'FaceAlpha') || numel(meshOut.FaceAlpha) ~= size(meshOut.Faces,1)
    meshOut.FaceAlpha = ones(size(meshOut.Faces,1),1);
end
end % Ends fcn_INTERNAL_meshWithSavedEdits

%% fcn_INTERNAL_spotsOf
function spots = fcn_INTERNAL_spotsOf(originalMesh, reducedMesh)
% The spots where the reduced mesh differs from the download, each with a
% key from where it is (its center, to 10 cm), so an answer stays with
% its spot when edits add or remove other spots
spots = struct('Box',{},'Label',{},'Description',{},'Count',{},'Kind',{},'Faces',{},'Area',{},'Severity',{},'Key',{});
if isempty(originalMesh)
    return;
end
spots = fcn_INTERNAL_findSpots(originalMesh, reducedMesh);
keys = cell(1, numel(spots));
for ith_spot = 1:numel(spots)
    center = mean(reshape(spots(ith_spot).Box, 2, 3), 1);
    key = sprintf('spot_%d_%d_%d', round(10*center));
    while any(strcmp(keys(1:ith_spot-1), key))
        key = [key 'b']; %#ok<AGROW>
    end
    keys{ith_spot} = key;
end
[spots.Key] = keys{:};
end % Ends fcn_INTERNAL_spotsOf

%% fcn_INTERNAL_carryAnswers
function reviewTable = fcn_INTERNAL_carryAnswers(reviewTable, earlier)
% The earlier answers copied into a new table of questions, by check and
% item (by column name: earlier reviews may have fewer columns)
for ith_row = 1:height(earlier)
    match = find(reviewTable.Check==earlier.Check(ith_row) & reviewTable.Item==earlier.Item(ith_row), 1);
    if ~isempty(match)
        for name = intersect(earlier.Properties.VariableNames(4:end), reviewTable.Properties.VariableNames(4:end))
            reviewTable.(name{1})(match) = earlier.(name{1})(ith_row);
        end
    end
end
end % Ends fcn_INTERNAL_carryAnswers

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

%% fcn_INTERNAL_defineChecks
function checks = fcn_INTERNAL_defineChecks(data)
% The checks, their items, and each item's question
checks = struct('Key',{},'Title',{},'Kind',{},'File',{},'Rows',{},'Inputs',{},'Items',{});
folder = data.ChecksFolder;

orientationItem = fcn_INTERNAL_item('orientation', 'Orientation', ...
    ['Does the red FRONT arrow point to the front of the vehicle, and the blue UP arrow to its top? ' ...
    'If not, Reject and pick where they really are: the report gives the script''s new settings.']);
orientationItem.CausePrompt = '(the front is really toward)';
orientationItem.Causes = {'front: +X (as shown)', 'front: -X', 'front: +Y', 'front: -Y', 'front: +Z', 'front: -Z'};
orientationItem.Cause2Prompt = '(the top is really toward)';
orientationItem.Causes2 = {'up: +Z (as shown)', 'up: -Z', 'up: +X', 'up: -X', 'up: +Y', 'up: -Y'};
checks(end+1) = fcn_INTERNAL_check('orientation', 'Orientation', 'orientation', orientationItem);

dimensionItems = fcn_INTERNAL_item('', '', '');
dimensionItems(:) = [];
for ith_row = 1:height(data.DimensionTable)
    quantity = char(data.DimensionTable{ith_row,1});
    target = data.DimensionTable{ith_row,2};
    name = fcn_INTERNAL_dimensionName(quantity, data.DimensionTable);
    switch quantity
        case 'OverallWidth'
            question = sprintf(['Overall width (FRONT VIEW; not measured, because the fitted width includes the mirrors): ' ...
                'does the body, without its mirrors, just fit between the blue guide lines (%.3f m apart)?'], target);
        case 'TrackFront'
            question = sprintf(['Front track (FRONT VIEW, from ahead): do the purple guide lines pass through the middle ' ...
                'of the front tires, and is the purple MEASURED close to the blue TARGET (%.3f m)?'], target);
        case 'TrackRear'
            question = sprintf(['Rear track (REAR VIEW, from behind): do the purple guide lines pass through the middle ' ...
                'of the rear tires, and is the purple MEASURED close to the blue TARGET (%.3f m)?'], target);
        case 'WidthWithMirrors'
            question = sprintf(['Width with mirrors (FRONT VIEW): do the purple guide lines touch the mirror tips, ' ...
                'and is the purple MEASURED close to the blue TARGET (%.3f m)?'], target);
        case {'TireDiameter', 'TireDiameterRear'}
            question = sprintf(['%s (SIDE VIEW): does the purple circle (as measured) match the tire''s outer edge, ' ...
                'and is it close to the blue TARGET circle (%.3f m)?'], name, target);
        case 'TireRoundMin'
            question = sprintf(['Tire roundness, smallest (SIDE VIEW): the tire''s outer edge is measured from the wheel ' ...
                'center in 36 directions; the purple circle is the SMALLEST of those diameters. A tire with too few ' ...
                'sides, or squashed, comes out small here. Is the purple circle close to the blue TARGET (the tire ' ...
                'size, %.3f m)?'], target);
        case 'TireRoundMax'
            question = sprintf(['Tire roundness, largest (SIDE VIEW): the tire''s outer edge is measured from the wheel ' ...
                'center in 36 directions; the purple circle is the LARGEST of those diameters. A tire that bulges, or ' ...
                'has stray parts (such as a mud flap), comes out large here. Is the purple circle close to the blue ' ...
                'TARGET (the tire size, %.3f m)?'], target);
        case 'GroundClearance'
            question = sprintf(['Ground clearance (SIDE VIEW): is the purple guide line at the lowest point of the ' ...
                'body (not the tires), and is the purple MEASURED close to the blue TARGET (%.3f m)?'], target);
        otherwise
            question = sprintf(['%s (SIDE VIEW): do the purple guide lines meet the vehicle where they should, ' ...
                'and is the purple MEASURED close to the blue TARGET (%.3f m)?'], name, target);
    end
    dimensionItems(end+1) = fcn_INTERNAL_item(quantity, name, question); %#ok<AGROW>
end
dimensionItems = fcn_INTERNAL_withAllItem(dimensionItems);   % (an item that shows the others in turn)
checks(end+1) = fcn_INTERNAL_check('dimensions', 'Dimensions', 'dimensions', dimensionItems);

labelItems = fcn_INTERNAL_item('', '', '');
labelItems(:) = [];
[labelKeys, labelNames] = fcn_INTERNAL_labelKinds(data.Mesh);
% (what wrong faces should be: each part, and each type of light)
fixChoices = strcat({'should be: '}, {'body', 'glass', 'trim', 'interior', 'wheel'});
lightTypeNames = {'headlight', 'turnsignal', 'running', 'tail', 'backup'};
if isfield(data.Mesh, 'LightTypeNames')
    lightTypeNames = union(lightTypeNames, data.Mesh.LightTypeNames(:)', 'stable');
end
fixChoices = [fixChoices, strcat({'should be: '}, lightTypeNames, {' light'}), {'should be: deleted'}];
for ith_label = 1:numel(labelKeys)
    labelItem = fcn_INTERNAL_item(labelKeys{ith_label}, labelNames{ith_label}, ...
        sprintf(['Only the %s faces are colored. Are they all %s, and is nothing %s missing ' ...
        '(left gray)? Rotate and zoom to check. To fix faces: paint them (the buttons above the model).'], ...
        labelNames{ith_label}, labelNames{ith_label}, labelNames{ith_label}));
    labelItem.CausePrompt = '(what is wrong)';
    labelItem.Causes = {'some faces have the wrong label (painted)', ...
        'missing: not in the mesh at all', ...
        'hidden: inside or behind another part (such as a lamp under its lens)', ...
        'other (see comment)'};
    labelItems(end+1) = labelItem; %#ok<AGROW>
end
labelItems = fcn_INTERNAL_withAllItem(labelItems);   % (an item that shows the others in turn)
checks(end+1) = fcn_INTERNAL_check('labels', 'Labels', 'labels', labelItems);

compareItems = fcn_INTERNAL_item('overall', 'All differences', ...
    'Turn the two views together. Is the reduced mesh (right) free of differences from the download (left) that would be noticed in an animation?');
compareItems(1).Causes = {'labeling', 'missing surface or face', 'gap between surfaces', ...
    'surfaces colliding or overlapping', 'dark or flipped faces', 'wrong color', 'other (see comment)'};
if ~isempty(data.OriginalMesh)
    spots = data.Spots;
    for ith_spot = 1:numel(spots)
        spotItem = fcn_INTERNAL_item(spots(ith_spot).Key, spots(ith_spot).Label, ...
            sprintf(['Spot %d (yellow; the other spots are gray): %s. Rotate and zoom both views (they turn together). ' ...
            'Is this difference significant?'], ith_spot, spots(ith_spot).Description));
        spotItem.ApproveText = 'Not significant';
        spotItem.RejectText = 'Significant';
        spotItem.Causes = {'labeling', 'missing surface or face', 'gap between surfaces', ...
            'surfaces colliding or overlapping', 'dark or flipped faces', 'wrong color', ...
            'a part of the download to delete (wiper, antenna, ...)', 'other (see comment)'};
        spotItem.Cause2Prompt = '(the picked faces should be)';
        spotItem.Causes2 = fixChoices;
        spotItem.Tooltip = fcn_INTERNAL_spotTooltip(spots(ith_spot).Kind);
        compareItems(end+1) = spotItem; %#ok<AGROW>
    end
    if numel(compareItems) > 1
        compareItems(1) = [];   % (the spots, and "Approve all", take its place)
    end
end
compareItems = fcn_INTERNAL_withAllItem(compareItems);   % (an item that shows the others in turn)
checks(end+1) = fcn_INTERNAL_check('compare', 'Differences', 'compare', compareItems);

% The animations: one item per step, and one for the whole animation
animationList = {
    'lights',   'Lights',   'check_05_lights.gif',   {'Lights'},              1, 'lights', ...
        '%s: do exactly the right lamps light up, and no others?';
    'body',     'Body',     'check_06_body.gif',     {'Body'},                1, 'body', ...
        '%s: does the body move this way, with the tires staying on the ground (except a lifted tire)?';
    'steering', 'Steering', 'check_07_steering.gif', {'Steering'},            1, 'steering', ...
        ['%s: do the front wheels steer this way, with the inner wheel turned more, ' ...
        'and does each dashed line end at the black turn-center dot?'];
    'wheels',   'Wheels',   'check_08_wheels.gif',   {'Wheels'},              1, 'wheels', ...
        '%s: do the wheels turn this way (spinning, locked, or backward), matching the vehicle''s motion and the lights named?';
    'drive',    'Drive',    'check_09_drive.gif',    {'Steering','Wheels'},   2, 'drive', ''};
for ith_animation = 1:size(animationList,1)
    [key, title, fileName, prefixes, ~, inputs, questionFormat] = animationList{ith_animation,:};
    rows = [];
    if ~isempty(data.TestMotion)
        rows = find(startsWith(data.TestMotion.Caption, strcat(prefixes, ':')));   % (every row: drawn live)
    end
    items = fcn_INTERNAL_item('whole', 'The whole animation', ...
        'Play the whole animation. Does everything look right?');
    if strcmp(key, 'drive')
        items.Question = ['Play the whole animation. Does the vehicle drive smoothly: tires on the ground and turning ' ...
            'with the motion, steering into the turns, and no parts lagging behind or coming apart?'];
    end
    if ~isempty(questionFormat) && ~isempty(rows)
        [stepNames, firstIndex] = unique(data.TestMotion.Caption(rows), 'stable');
        for ith_step = 1:numel(stepNames)
            stepRows = rows(strcmp(data.TestMotion.Caption(rows), stepNames{ith_step}));
            row = stepRows(min(2, numel(stepRows)));   % (signals blink: "on" first)
            if ~strcmp(key, 'lights')
                row = stepRows(ceil(end/2));
            end
            shortName = strtrim(regexprep(stepNames{ith_step}, '^[A-Za-z]+:\s*', ''));
            stepItem = fcn_INTERNAL_item(sprintf('step%d', ith_step), shortName, sprintf(questionFormat, shortName));
            stepItem.Row = row;
            items(end+1) = stepItem; %#ok<AGROW>
        end
        firstIndex; %#ok<VUNUS>
    end
    thisCheck = fcn_INTERNAL_check(key, title, 'animation', items);
    thisCheck.File = fullfile(folder, fileName);
    thisCheck.Rows = rows;
    thisCheck.Inputs = inputs;
    checks(end+1) = thisCheck; %#ok<AGROW>
end

% (ground contact is a simulation test, with nothing for a reviewer to
% see: it stays in the checks run, not here)

levelItems = fcn_INTERNAL_item('overall', 'All detail levels', ...
    ['Top: the full mesh and each level, side by side. Bottom: each level where it is used. Do the levels look like ' ...
    'the full mesh where they are used (no missing wheels, no holes, the colors kept)?']);
checks(end+1) = fcn_INTERNAL_check('levels', 'Detail levels', 'levels', levelItems);

outlineItems = fcn_INTERNAL_item('', '', '');
outlineItems(:) = [];
for ith_element = 1:numel(data.OutlineElements)
    element = data.OutlineElements(ith_element);
    outlineItems(end+1) = fcn_INTERNAL_item(element.Key, element.Label, ...
        sprintf(['%s (orange): is each outline one closed loop that encircles the part, ' ...
        'with no lines crossing through it?'], element.Label)); %#ok<AGROW>
end
if isempty(outlineItems)
    outlineItems = fcn_INTERNAL_item('none', 'No outline', 'There is no 2D outline yet. Approve to skip.');
end
outlineItems = fcn_INTERNAL_withAllItem(outlineItems);   % (an item that shows the others in turn)
checks(end+1) = fcn_INTERNAL_check('outline', '2D outline', 'outline', outlineItems);

summaryItem = fcn_INTERNAL_item('overall', 'Overall decision', ...
    'Overall: is the vehicle approved for use? (Use the big buttons, or these.)');
checks(end+1) = fcn_INTERNAL_check('summary', 'Summary', 'summary', summaryItem);
end % Ends fcn_INTERNAL_defineChecks

%% fcn_INTERNAL_withAllItem
function items = fcn_INTERNAL_withAllItem(items)
% An "All, in turn" item first: it shows each of the others in turn, over
% and over; approving it approves every item not answered yet
if numel(items) < 2
    return;
end
allItem = fcn_INTERNAL_item('all', 'All, in turn', ...
    ['Each item is shown in turn (in bold), over and over. If every one is right, Approve: that approves all of ' ...
    'them not answered yet. If one is wrong, click it to stop there, and answer it.']);
items = [allItem, items];
end % Ends fcn_INTERNAL_withAllItem

%% fcn_INTERNAL_check
function thisCheck = fcn_INTERNAL_check(key, title, kind, items)
thisCheck = struct('Key',key,'Title',title,'Kind',kind,'File','','Rows',[],'Inputs','','Items',items);
end % Ends fcn_INTERNAL_check

%% fcn_INTERNAL_item
function item = fcn_INTERNAL_item(key, label, question)
item = struct('Key',key,'Label',label,'Question',question,'ApproveText','Approve', ...
    'RejectText','Reject','Causes',{{}},'CausePrompt','(likely cause)', ...
    'Causes2',{{}},'Cause2Prompt','','Tooltip','','Row',[]);
end % Ends fcn_INTERNAL_item

%% fcn_INTERNAL_words
function words = fcn_INTERNAL_words(name)
% 'WidthWithMirrors' -> 'Width with mirrors'
words = regexprep(char(name), '([a-z])([A-Z])', '$1 $2');
words = [words(1) lower(words(2:end))];
end % Ends fcn_INTERNAL_words

%% fcn_INTERNAL_orText
function textOut = fcn_INTERNAL_orText(textIn, fallback)
textOut = char(textIn);
if isempty(textOut)
    textOut = fallback;
end
end % Ends fcn_INTERNAL_orText

%% fcn_INTERNAL_labelKinds
function [keys, names] = fcn_INTERNAL_labelKinds(vehicleMesh)
% The labels on this mesh: parts (other than light), each light type, and
% "light with no type" if there are any
keys = {};
names = {};
lightPart = find(strcmp(vehicleMesh.PartNames, 'light'), 1);
for ith_part = 1:numel(vehicleMesh.PartNames)
    flagHasPart = any(vehicleMesh.FacePartIndex==ith_part);
    if isfield(vehicleMesh,'FaceAlsoParts') && size(vehicleMesh.FaceAlsoParts,1)==size(vehicleMesh.Faces,1) && ith_part <= size(vehicleMesh.FaceAlsoParts,2)
        flagHasPart = flagHasPart || any(vehicleMesh.FaceAlsoParts(:,ith_part));   % (a part only some faces also belong to)
    end
    if ith_part == lightPart || ~flagHasPart
        continue;
    end
    keys{end+1} = ['part_' vehicleMesh.PartNames{ith_part}]; %#ok<AGROW>
    names{end+1} = vehicleMesh.PartNames{ith_part}; %#ok<AGROW>
end
if isfield(vehicleMesh, 'LightTypeNames')
    for ith_type = 1:numel(vehicleMesh.LightTypeNames)
        if any(vehicleMesh.FaceLightType==ith_type)
            keys{end+1} = ['light_' vehicleMesh.LightTypeNames{ith_type}]; %#ok<AGROW>
            names{end+1} = [vehicleMesh.LightTypeNames{ith_type} ' light']; %#ok<AGROW>
        end
    end
end
if ~isempty(lightPart)
    flagUntyped = vehicleMesh.FacePartIndex==lightPart;
    if isfield(vehicleMesh, 'FaceLightType')
        flagUntyped = flagUntyped & vehicleMesh.FaceLightType==0;
    end
    if any(flagUntyped)
        keys{end+1} = 'light_none';
        names{end+1} = 'light with no type';
    end
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
    'FaceLighting', 'flat', 'AmbientStrength', 0.7, 'DiffuseStrength', 0.45, 'SpecularStrength', 0.05, ...
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

%% fcn_INTERNAL_vehicleTitle
function titleText = fcn_INTERNAL_vehicleTitle(vehicleFiles)
% '2009 Honda Fit Sport' (the trim left out when not known: XXX)
titleText = vehicleFiles.Name;
if isfield(vehicleFiles, 'Trim') && strcmpi(vehicleFiles.Trim, 'XXX')
    titleText = strtrim(strrep(titleText, 'XXX', ''));
end
end % Ends fcn_INTERNAL_vehicleTitle

%% fcn_INTERNAL_getView / fcn_INTERNAL_setView
function viewState = fcn_INTERNAL_getView(axesHandle)
drawnow;
viewState = struct('CameraPosition', axesHandle.CameraPosition, 'CameraTarget', axesHandle.CameraTarget, ...
    'CameraUpVector', axesHandle.CameraUpVector, 'CameraViewAngle', axesHandle.CameraViewAngle, ...
    'XLim', axesHandle.XLim, 'YLim', axesHandle.YLim, 'ZLim', axesHandle.ZLim);
end % Ends fcn_INTERNAL_getView

function fcn_INTERNAL_setView(axesHandle, viewState)
set(axesHandle, 'XLim', viewState.XLim, 'YLim', viewState.YLim, 'ZLim', viewState.ZLim, ...
    'CameraPosition', viewState.CameraPosition, 'CameraTarget', viewState.CameraTarget, ...
    'CameraUpVector', viewState.CameraUpVector, 'CameraViewAngle', viewState.CameraViewAngle);
end % Ends fcn_INTERNAL_setView

%% fcn_INTERNAL_placeButtons
function fcn_INTERNAL_placeButtons(group, buttons)
% Radio buttons stacked from the top of their group
if isempty(buttons) || ~isvalid(group)
    return;
end
drawnow limitrate;
groupHeight = group.InnerPosition(4);
rowHeight = 24;
top = max(groupHeight, rowHeight*numel(buttons) + 8);
width = max(120, group.InnerPosition(3) - 30);   % (room for the scroll bar)
for ith_button = 1:numel(buttons)
    buttons(ith_button).Position = [8, top - rowHeight*ith_button, width, 22];
end
end % Ends fcn_INTERNAL_placeButtons

%% fcn_INTERNAL_dimensionName
function name = fcn_INTERNAL_dimensionName(quantity, dimensionTable)
% A quantity's name in words. With different front and rear tires (a
% TireDiameterRear row), the tire diameter is the front's.
quantity = char(quantity);
flagStaggered = any(dimensionTable{:,1}=="TireDiameterRear");
switch quantity
    case 'OverallWidth',     name = 'Overall width (body)';
    case 'TrackFront',       name = 'Track, front';
    case 'TrackRear',        name = 'Track, rear';
    case 'TireRoundMin',     name = 'Tire roundness, smallest';
    case 'TireRoundMax',     name = 'Tire roundness, largest';
    case 'TireDiameterRear', name = 'Tire diameter, rear';
    case 'TireDiameter'
        name = 'Tire diameter';
        if flagStaggered
            name = 'Tire diameter, front';
        end
    otherwise
        name = fcn_INTERNAL_words(quantity);
end
end % Ends fcn_INTERNAL_dimensionName

%% fcn_INTERNAL_drawSpot
function fcn_INTERNAL_drawSpot(axesHandle, originalMesh, spot, spotIndex)
% A spot, in gray: a hole as a box; a label change outlined on its faces
% (the download's faces, which the reduced mesh labels differently)
tag = sprintf('spot%d', spotIndex);
if strcmp(spot.Kind, 'label change')
    patch(axesHandle, 'Faces', originalMesh.Faces(spot.Faces,:), 'Vertices', originalMesh.Vertices, ...
        'FaceColor', 'none', 'EdgeColor', [0.55 0.55 0.55], 'LineWidth', 0.75, 'Tag', tag, ...
        'HitTest', 'off', 'Clipping', 'off');
else
    fcn_INTERNAL_drawBox(axesHandle, spot.Box, [0.6 0.6 0.6], 1, tag);
end
end % Ends fcn_INTERNAL_drawSpot

%% fcn_INTERNAL_spotTooltip
function tooltip = fcn_INTERNAL_spotTooltip(kind)
% What a kind of spot means (shown when the mouse rests on its item)
switch kind
    case 'hole'
        tooltip = ['Hole: the download has surface here that the reduced mesh does not (no reduced face ' ...
            'within about one edge length). It may be a gap, a missing part, or a small part removed on purpose.'];
    case 'label change'
        tooltip = ['Label change: the reduced mesh is here, but with another label than the download''s faces ' ...
            '(for example glass in the download, trim in the reduced mesh). Colors and lights follow the label.'];
    otherwise
        tooltip = '';
end
end % Ends fcn_INTERNAL_spotTooltip

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

%% fcn_INTERNAL_mainPart
function partName = fcn_INTERNAL_mainPart(vehicleMesh, flagFaces)
% The part most of these faces are labeled as
partName = '';
if ~isfield(vehicleMesh, 'FacePartIndex') || ~isfield(vehicleMesh, 'PartNames')
    return;
end
partIndex = vehicleMesh.FacePartIndex(flagFaces);
partIndex = partIndex(partIndex > 0);
if isempty(partIndex)
    return;
end
partName = vehicleMesh.PartNames{mode(partIndex)};
end % Ends fcn_INTERNAL_mainPart

%% fcn_INTERNAL_findSpots
function spots = fcn_INTERNAL_findSpots(originalMesh, reducedMesh)
% The places where the reduced mesh differs most from the download, in 3D:
% "holes" (download surface far from the reduced mesh) and "label
% changes" (the nearest reduced face has another label). Each place is a
% cluster of the download's face centers, in 10 cm cells, with a box.
spots = struct('Box',{},'Label',{},'Description',{},'Count',{},'Kind',{},'Faces',{},'Area',{},'Severity',{});
originalCenters = fcn_INTERNAL_faceCenters(originalMesh);
reducedPoints = fcn_INTERNAL_samplePoints(reducedMesh);
[nearestIndex, nearestDistance] = fcn_INTERNAL_nearest(reducedPoints.XYZ, originalCenters);
edgeLength = median(vecnorm(reducedMesh.Vertices(reducedMesh.Faces(:,1),:) - reducedMesh.Vertices(reducedMesh.Faces(:,2),:), 2, 2));
holeDistance = max(0.03, 0.75*edgeLength);
flagHole = nearestDistance > holeDistance;
originalLabel = fcn_INTERNAL_labelCode(originalMesh);
reducedLabel = fcn_INTERNAL_labelCode(reducedMesh);
flagChanged = ~flagHole & originalLabel ~= reducedLabel(reducedPoints.Face(nearestIndex));
vertices = originalMesh.Vertices;
faces = originalMesh.Faces;
faceAreas = 0.5*vecnorm(cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2), 2, 2);
kinds = {'hole', flagHole; 'label change', flagChanged};
cellSize = 0.10;
for ith_kind = 1:2
    flagKind = kinds{ith_kind,2};
    if ~any(flagKind)
        continue;
    end
    kindFaces = find(flagKind);
    points = originalCenters(flagKind,:);
    clusterIndex = fcn_INTERNAL_cluster(points, cellSize);
    for ith_cluster = 1:max(clusterIndex)
        inCluster = clusterIndex==ith_cluster;
        clusterPoints = points(inCluster,:);
        if size(clusterPoints,1) < 4
            continue;
        end
        clusterFaces = kindFaces(inCluster);
        area = sum(faceAreas(clusterFaces));
        boxMin = min(clusterPoints,[],1) - 0.02;
        boxMax = max(clusterPoints,[],1) + 0.02;
        % (severity: the area affected; a hole counts double, since it can
        % be seen through)
        severity = area*(1 + strcmp(kinds{ith_kind,1}, 'hole'));
        spots(end+1) = struct('Box', [boxMin; boxMax], 'Label', '', ...
            'Description', sprintf('a %s, %.0f cm%c of the download''s surface (%d faces), at x %.2f, y %.2f, z %.2f m', ...
            kinds{ith_kind,1}, 1e4*area, 178, size(clusterPoints,1), mean(clusterPoints,1)), 'Count', size(clusterPoints,1), ...
            'Kind', kinds{ith_kind,1}, 'Faces', clusterFaces, 'Area', area, 'Severity', severity); %#ok<AGROW>
        spots(end).Label = sprintf('%s, %.0f cm%c', kinds{ith_kind,1}, 1e4*area, 178);
    end
end
if isempty(spots)
    return;
end
[~, order] = sort([spots.Severity], 'descend');
spots = spots(order(1:min(12, numel(order))));
for ith_spot = 1:numel(spots)
    spots(ith_spot).Label = sprintf('Spot %d: %s', ith_spot, spots(ith_spot).Label);
end
end % Ends fcn_INTERNAL_findSpots

function centers = fcn_INTERNAL_faceCenters(vehicleMesh)
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
end

function points = fcn_INTERNAL_samplePoints(vehicleMesh)
% Points spread over each face (corners, edge middles, center, and points
% between), so the distance to them is close to the distance to the surface
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
weights = [1 0 0; 0 1 0; 0 0 1; 0.5 0.5 0; 0 0.5 0.5; 0.5 0 0.5; 1/3 1/3 1/3; ...
    2/3 1/6 1/6; 1/6 2/3 1/6; 1/6 1/6 2/3];
Nweights = size(weights,1);
Nfaces = size(faces,1);
xyz = zeros(Nfaces*Nweights, 3);
for ith_weight = 1:Nweights
    rows = (ith_weight-1)*Nfaces + (1:Nfaces);
    xyz(rows,:) = weights(ith_weight,1)*vertices(faces(:,1),:) + weights(ith_weight,2)*vertices(faces(:,2),:) + ...
        weights(ith_weight,3)*vertices(faces(:,3),:);
end
points.XYZ = xyz;
points.Face = repmat((1:Nfaces)', Nweights, 1);
end

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
end

function code = fcn_INTERNAL_labelCode(vehicleMesh)
% One number per face for its label: part index, or 100 + light type
code = double(vehicleMesh.FacePartIndex(:));
if isfield(vehicleMesh, 'FaceLightType')
    flagLight = vehicleMesh.FaceLightType(:) > 0;
    code(flagLight) = 100 + double(vehicleMesh.FaceLightType(flagLight));
end
end

function clusterIndex = fcn_INTERNAL_cluster(points, cellSize)
% Groups points whose cells touch (26 neighbors)
cells = floor(points/cellSize);
[uniqueCells, ~, cellOfPoint] = unique(cells, 'rows');
Ncells = size(uniqueCells,1);
cellCluster = zeros(Ncells,1);
cellKey = containers.Map('KeyType','char','ValueType','double');
for ith_cell = 1:Ncells
    cellKey(sprintf('%d_%d_%d', uniqueCells(ith_cell,:))) = ith_cell;
end
[dx, dy, dz] = ndgrid(-1:1, -1:1, -1:1);
neighbors = [dx(:) dy(:) dz(:)];
Nclusters = 0;
for ith_cell = 1:Ncells
    if cellCluster(ith_cell) > 0
        continue;
    end
    Nclusters = Nclusters + 1;
    stack = ith_cell;
    cellCluster(ith_cell) = Nclusters;
    while ~isempty(stack)
        current = stack(end);
        stack(end) = [];
        for ith_neighbor = 1:size(neighbors,1)
            key = sprintf('%d_%d_%d', uniqueCells(current,:) + neighbors(ith_neighbor,:));
            if isKey(cellKey, key)
                other = cellKey(key);
                if cellCluster(other) == 0
                    cellCluster(other) = Nclusters;
                    stack(end+1) = other; %#ok<AGROW>
                end
            end
        end
    end
end
clusterIndex = cellCluster(cellOfPoint);
end

%% fcn_INTERNAL_drawBox
function fcn_INTERNAL_drawBox(axesHandle, box, color, lineWidth, tag)
% A wire box (2 x 3: min and max corners)
corners = [box(1,1) box(1,2) box(1,3); box(2,1) box(1,2) box(1,3); box(2,1) box(2,2) box(1,3); box(1,1) box(2,2) box(1,3); ...
    box(1,1) box(1,2) box(2,3); box(2,1) box(1,2) box(2,3); box(2,1) box(2,2) box(2,3); box(1,1) box(2,2) box(2,3)];
edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
xyz = nan(3*size(edges,1), 3);
for ith_edge = 1:size(edges,1)
    xyz(3*ith_edge-2:3*ith_edge-1,:) = corners(edges(ith_edge,:),:);
end
plot3(axesHandle, xyz(:,1), xyz(:,2), xyz(:,3), '-', 'Color', color, 'LineWidth', lineWidth, 'Tag', tag, 'Clipping', 'off');
end % Ends fcn_INTERNAL_drawBox

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
if isfield(outline, 'Interior') && ~isempty(outline.Interior)
    % (as fcn_CarMesh3D_viewOutline's elements: one for all the pieces)
    elements(end+1) = struct('Key', 'interior', ...
        'Label', sprintf('Interior (%d outlines)', numel(outline.Interior)), ...
        'Polygons', {{outline.Interior.Polygon}});
end
end % Ends fcn_INTERNAL_outlineElements

%% fcn_INTERNAL_startAnswers
function reviewTable = fcn_INTERNAL_startAnswers(checks, reviewFile)
% One row per question, with any earlier answers loaded
rows = {};
for ith_check = 1:numel(checks)
    for ith_item = 1:numel(checks(ith_check).Items)
        rows(end+1,:) = {checks(ith_check).Key, checks(ith_check).Items(ith_item).Key, checks(ith_check).Items(ith_item).Question}; %#ok<AGROW>
    end
end
N = size(rows,1);
reviewTable = table(string(rows(:,1)), string(rows(:,2)), string(rows(:,3)), strings(N,1), strings(N,1), ...
    strings(N,1), strings(N,1), strings(N,1), strings(N,1), strings(N,1), strings(N,1), ...
    'VariableNames', {'Check','Item','Question','Status','Severity','Cause','Comment','Reviewer','Time','Region','SelectionPart'});
if isfile(reviewFile)
    loaded = load(reviewFile, 'reviewTable');
    reviewTable = fcn_INTERNAL_carryAnswers(reviewTable, loaded.reviewTable);
end
end % Ends fcn_INTERNAL_startAnswers

%% fcn_INTERNAL_saveAnswers
function fcn_INTERNAL_saveAnswers(reviewTable, reviewFile)
save(reviewFile, 'reviewTable');
end % Ends fcn_INTERNAL_saveAnswers

%% fcn_INTERNAL_writeReport
function fcn_INTERNAL_writeReport(reviewTable, checks, vehicleFiles, reportFile)
% A readable report of the answers (Markdown)
fileID = fopen(reportFile, 'w');
if fileID < 0
    warning('CarMesh3D:reviewReport', 'Could not write %s', reportFile);
    return;
end
cleanup = onCleanup(@() fclose(fileID));
isQuestion = reviewTable.Check ~= "summary";
overall = reviewTable(reviewTable.Check=="summary", :);
fprintf(fileID, '# Review: %s\n\n', vehicleFiles.Name);
fprintf(fileID, 'Overall decision: **%s**', fcn_INTERNAL_orText(overall.Status(1), 'none yet'));
if strlength(overall.Reviewer(1)) > 0
    fprintf(fileID, ' (%s, %s)', overall.Reviewer(1), overall.Time(1));
end
fprintf(fileID, '\n\n%d questions: %d approved, %d rejected (%d must be fixed), %d not answered.\n\n', ...
    sum(isQuestion), sum(reviewTable.Status(isQuestion)=="approved"), sum(reviewTable.Status(isQuestion)=="rejected"), ...
    sum(reviewTable.Severity(isQuestion)=="must fix"), sum(isQuestion & strlength(reviewTable.Status)==0));
if strlength(overall.Comment(1)) > 0
    fprintf(fileID, 'Overall comment: %s\n\n', overall.Comment(1));
end
for ith_check = 1:numel(checks)
    if strcmp(checks(ith_check).Key, 'summary')
        continue;
    end
    fprintf(fileID, '## %s\n\n| Item | Answer | Cause | Comment | By |\n|---|---|---|---|---|\n', checks(ith_check).Title);
    for ith_item = 1:numel(checks(ith_check).Items)
        row = find(reviewTable.Check==string(checks(ith_check).Key) & reviewTable.Item==string(checks(ith_check).Items(ith_item).Key), 1);
        answer = fcn_INTERNAL_orText(reviewTable.Status(row), '(none)');
        if reviewTable.Status(row)=="rejected"
            answer = sprintf('**rejected, %s**', reviewTable.Severity(row));
        end
        fprintf(fileID, '| %s | %s | %s | %s | %s |\n', checks(ith_check).Items(ith_item).Label, answer, ...
            reviewTable.Cause(row), strrep(reviewTable.Comment(row), newline, ' '), ...
            strtrim(reviewTable.Reviewer(row) + " " + reviewTable.Time(row)));
    end
    fprintf(fileID, '\n');
end
% Fixes to make in the vehicle's script
fixLines = {};
orientationRow = find(reviewTable.Check=="orientation", 1);
if ~isempty(orientationRow) && reviewTable.Status(orientationRow)=="rejected" && strlength(reviewTable.Cause(orientationRow))>0
    fixLines = [fixLines, fcn_INTERNAL_axisFix(vehicleFiles.ScriptFile, char(reviewTable.Cause(orientationRow)))];
end
labelRows = find(reviewTable.Check=="compare" & reviewTable.Status=="rejected" & strlength(reviewTable.Region)>0);
% (the painted label fixes, kept in the vehicle's labelEdits file)
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
if isfile(editsFile)
    loaded = load(editsFile, 'labelEditsAfterSimplify');
    if isfield(loaded, 'labelEditsAfterSimplify') && ~isempty(loaded.labelEditsAfterSimplify)
        fprintf(fileID, '## Painted label fixes\n\nIn %s, applied by the vehicle''s script after simplifying:\n\n', editsFile);
        for ith_edit = 1:numel(loaded.labelEditsAfterSimplify)
            fprintf(fileID, '- %s\n', loaded.labelEditsAfterSimplify{ith_edit}.Name);
        end
        fprintf(fileID, '\n');
    end
end
for ith_row = 1:numel(labelRows)
    fixLines = [fixLines, fcn_INTERNAL_labelFix(reviewTable(labelRows(ith_row),:))]; %#ok<AGROW>
end
if ~isempty(fixLines)
    fprintf(fileID, ['## Fixes for the vehicle''s script\n\nPaste into the script (label edits go after ' ...
        'labelEditsAfterFit = {};), then run it again.\n\n```matlab\n%s\n```\n'], strjoin(fixLines, newline));
end
end % Ends fcn_INTERNAL_writeReport

%% fcn_INTERNAL_labelFix
function fixLine = fcn_INTERNAL_labelFix(answer)
% A labelEditsAfterFit line from a rejected item with picked faces (a
% label, or a spot of the differences): the faces of their part, inside
% their box, become what the reviewer picked ('delete' takes them away)
itemKey = char(answer.Item);
currentPart = char(answer.SelectionPart);
if isempty(currentPart)
    if startsWith(itemKey, 'part_')
        currentPart = itemKey(6:end);
    else
        currentPart = 'light';
    end
end
causeText = char(answer.Cause);
target = regexp(causeText, 'should be: (\w+)( light)?', 'tokens', 'once');
if isempty(target)
    fixLine = {sprintf('%% (%s %s: faces were picked, but not what they should be)', char(answer.Check), itemKey)};
    return;
end
region = str2num(char(answer.Region)); %#ok<ST2NM>
if contains(causeText, 'this side only')
    flagBothSides = false;
elseif contains(causeText, 'both sides')
    flagBothSides = true;
else
    flagBothSides = ~(numel(region)==6 && region(3) < 0 && region(4) > 0);   % (a part across the middle is not mirrored)
end
if strcmp(target{1}, 'deleted')
    change = '''Part'',''delete''';
    name = sprintf('review: delete (%s %s)', char(answer.Check), itemKey);
elseif isempty(target{2})
    change = sprintf('''Part'',''%s''', target{1});
    name = sprintf('review: %s -> %s', currentPart, target{1});
else
    change = sprintf('''LightType'',''%s''', target{1});
    name = sprintf('review: %s -> %s light', currentPart, target{1});
end
fixLine = {sprintf('labelEditsAfterFit{end+1} = struct(''Name'',''%s'', ''Region'',%s, ''BothSides'',%s, ''CurrentPart'',''%s'', %s);', ...
    name, char(answer.Region), mat2str(flagBothSides), currentPart, change)};
end % Ends fcn_INTERNAL_labelFix

%% fcn_INTERNAL_axisFix
function fixLines = fcn_INTERNAL_axisFix(scriptFile, causeText)
% The script's new importForwardAxis and importUpAxis, from the reviewer's
% "front: -X | up: +Z" (directions in the vehicle frame as shown) and the
% script's present settings
fixLines = {};
if ~isfile(scriptFile)
    return;
end
scriptText = fileread(scriptFile);
forwardToken = regexp(scriptText, 'importForwardAxis\s*=\s*''([+-]?[xyzXYZ])''', 'tokens', 'once');
upToken = regexp(scriptText, 'importUpAxis\s*=\s*''([+-]?[xyzXYZ])''', 'tokens', 'once');
if isempty(forwardToken) || isempty(upToken)
    fixLines = {'% (the script''s importForwardAxis and importUpAxis were not found)'};
    return;
end
forwardFile = fcn_INTERNAL_axisVector(forwardToken{1});
upFile = fcn_INTERNAL_axisVector(upToken{1});
% (the shown frame's axes, as file directions: X = forward, Z = up)
shownToFile = [forwardFile(:), cross(upFile(:), forwardFile(:)), upFile(:)];
parts = strsplit(causeText, ' | ');
newForward = forwardToken{1};
newUp = upToken{1};
frontWord = regexp(parts{1}, 'front:\s*([+-][XYZ])', 'tokens', 'once');
if ~isempty(frontWord)
    newForward = fcn_INTERNAL_axisText(shownToFile*fcn_INTERNAL_axisVector(frontWord{1})');
end
if numel(parts) >= 2
    upWord = regexp(parts{2}, 'up:\s*([+-][XYZ])', 'tokens', 'once');
    if ~isempty(upWord)
        newUp = fcn_INTERNAL_axisText(shownToFile*fcn_INTERNAL_axisVector(upWord{1})');
    end
end
fixLines = {sprintf('importUpAxis = ''%s'';        %% (was ''%s''; from the review: %s)', newUp, upToken{1}, causeText), ...
    sprintf('importForwardAxis = ''%s'';   %% (was ''%s'')', newForward, forwardToken{1})};
end % Ends fcn_INTERNAL_axisFix

function vector = fcn_INTERNAL_axisVector(axisText)
% '+y' -> [0 1 0], '-X' -> [-1 0 0]
axisText = lower(strtrim(axisText));
sign = 1;
if axisText(1)=='-'
    sign = -1;
end
vector = sign*double(axisText(end)=='xyz');
end

function axisText = fcn_INTERNAL_axisText(vector)
% [0 -1 0] -> '-y'
[~, index] = max(abs(vector));
signs = '+-';
axisText = [signs(1 + (vector(index) < 0)) 'xyz'];
axisText = axisText([1 1+index]);
end
