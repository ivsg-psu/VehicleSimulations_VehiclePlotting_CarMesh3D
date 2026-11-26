% script_test_fcn_CarMesh3D_addCadMouse.m
% Tests fcn_CarMesh3D_addCadMouse
% Gives a 3D axes the CAD-style mouse: left-drag turns, right-drag pans,
% the wheel zooms.
%
% The figures are made hidden and closed by their handles, so the test
% never closes a window it did not make (Sean's answer queue, a viewer).

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addCadMouse
%   % * First write of the code (drafted with Claude)

% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addCadMouse
%   % * A flat view ('mouse2D'): a left-drag pans (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addCadMouse
%   % * (fill in items here)


%% Set up the workspace
% (a small closed box, standing in for a mesh)
boxVertices = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
boxFaces = [1 3 2; 1 4 3; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: a box with the CAD mouse
figNum = 10001;
titleString = sprintf('DEMO case: a box with the CAD mouse');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
axesHandle = axes(figureHandle);
patch(axesHandle, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.7 0.8 0.9]);
view(axesHandle, 30, 20);
fcn_CarMesh3D_addCadMouse(axesHandle);
assert(~isempty(figureHandle.WindowButtonDownFcn) && ~isempty(figureHandle.WindowButtonMotionFcn) ...
    && ~isempty(figureHandle.WindowButtonUpFcn) && ~isempty(figureHandle.WindowScrollWheelFcn));
close(figureHandle);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _______        _
%  |__   __|      | |
%     | | ___  ___| |_ ___
%     | |/ _ \/ __| __/ __|
%     | |  __/\__ \ |_\__ \
%     |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% TEST case: the wheel zooms, left-drag turns, right-drag pans
figNum = 20001;
titleString = sprintf('TEST case: the wheel zooms, left-drag turns, right-drag pans');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
axesHandle = axes(figureHandle);
boxPatch = patch(axesHandle, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.7 0.8 0.9]);
view(axesHandle, 30, 20);
fcn_CarMesh3D_addCadMouse(axesHandle);
drawnow;

% The wheel: one notch toward the user zooms in (a smaller view angle)
angleBefore = axesHandle.CameraViewAngle;
figureHandle.WindowScrollWheelFcn(figureHandle, struct('VerticalScrollCount', -1));
assert(axesHandle.CameraViewAngle < angleBefore, 'The wheel zooms in');
figureHandle.WindowScrollWheelFcn(figureHandle, struct('VerticalScrollCount', 1));
assert(abs(axesHandle.CameraViewAngle - angleBefore) < 1e-6*angleBefore, 'And back out');

% Left-drag on the model turns it (the camera moves, the target stays)
positionBefore = axesHandle.CameraPosition;
targetBefore = axesHandle.CameraTarget;
fcn_INTERNAL_drag(figureHandle, boxPatch, 'normal', [100 100], [140 100]);
assert(norm(axesHandle.CameraPosition - positionBefore) > 1e-6, 'Left-drag turns');
assert(norm(axesHandle.CameraTarget - targetBefore) < 1e-9, 'Turning keeps the target');

% Right-drag on the model pans it (the target moves)
targetBefore = axesHandle.CameraTarget;
fcn_INTERNAL_drag(figureHandle, boxPatch, 'alt', [100 100], [100 130]);
assert(norm(axesHandle.CameraTarget - targetBefore) > 1e-9, 'Right-drag pans');

% A flat view (appdata 'mouse2D', as the outline viewer's view from
% above): a left-drag pans too, never turns
setappdata(axesHandle, 'mouse2D', true);
positionBefore = axesHandle.CameraPosition;
targetBefore = axesHandle.CameraTarget;
fcn_INTERNAL_drag(figureHandle, boxPatch, 'normal', [100 100], [100 130]);
assert(norm(axesHandle.CameraTarget - targetBefore) > 1e-9, 'A flat view: left-drag pans');
assert(abs(norm(axesHandle.CameraPosition - axesHandle.CameraTarget) - norm(positionBefore - targetBefore)) < 1e-9, 'and does not turn');
rmappdata(axesHandle, 'mouse2D');

% After the button is let go, moving the mouse does nothing
positionBefore = axesHandle.CameraPosition;
figureHandle.CurrentPoint = [300 300];
figureHandle.WindowButtonMotionFcn(figureHandle, []);
assert(isequal(axesHandle.CameraPosition, positionBefore), 'No drag without a button');
close(figureHandle);

%% TEST case: a drag that starts off the axes does nothing
figNum = 20002;
titleString = sprintf('TEST case: a drag that starts off the axes does nothing');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
axesHandle = axes(figureHandle, 'Position', [0.5 0.1 0.4 0.8]);
patch(axesHandle, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.7 0.8 0.9]);
otherAxes = axes(figureHandle, 'Position', [0.05 0.1 0.4 0.8]);
otherLine = plot(otherAxes, 1:3, 1:3);
view(axesHandle, 30, 20);
fcn_CarMesh3D_addCadMouse(axesHandle);
positionBefore = axesHandle.CameraPosition;
fcn_INTERNAL_drag(figureHandle, otherLine, 'normal', [100 100], [160 100]);
assert(isequal(axesHandle.CameraPosition, positionBefore), 'A drag on another axes leaves this one alone');
close(figureHandle);

%% TEST case: linked axes follow
figNum = 20003;
titleString = sprintf('TEST case: linked axes follow');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureOne = figure(figNum); clf(figureOne); figureOne.Visible = 'off';
axesOne = axes(figureOne);
patchOne = patch(axesOne, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.7 0.8 0.9]);
figureTwo = figure(figNum + 1); clf(figureTwo); figureTwo.Visible = 'off';
axesTwo = axes(figureTwo);
patch(axesTwo, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.9 0.8 0.7]);
view(axesOne, 30, 20); view(axesTwo, 30, 20);
fcn_CarMesh3D_addCadMouse(axesOne);
fcn_CarMesh3D_addCadMouse(axesTwo);
cameraLink = linkprop([axesOne axesTwo], {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'});
fcn_INTERNAL_drag(figureOne, patchOne, 'normal', [100 100], [150 120]);
drawnow;
assert(norm(axesOne.CameraPosition - axesTwo.CameraPosition) < 1e-9, 'The linked axes turned too');
clear cameraLink
close(figureOne); close(figureTwo);

%% TEST case: several axes in one figure (Sean, 03:01: a 2x2 view)
figNum = 20005;
titleString = sprintf('TEST case: several axes in one figure');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
axesLeft = subplot(1, 2, 1, 'Parent', figureHandle);
patchLeft = patch(axesLeft, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.7 0.8 0.9]);
axesRight = subplot(1, 2, 2, 'Parent', figureHandle);
patchRight = patch(axesRight, 'Faces', boxFaces, 'Vertices', boxVertices, 'FaceColor', [0.9 0.8 0.7]);
view(axesLeft, 30, 20); view(axesRight, 30, 20);
fcn_CarMesh3D_addCadMouse([axesLeft axesRight]);
leftBefore = axesLeft.CameraPosition;
rightBefore = axesRight.CameraPosition;
fcn_INTERNAL_drag(figureHandle, patchRight, 'normal', [100 100], [150 100]);
assert(norm(axesRight.CameraPosition - rightBefore) > 1e-6, 'A drag on the right axes turns it');
assert(isequal(axesLeft.CameraPosition, leftBefore), '... and leaves the left one alone');
leftBefore = axesLeft.CameraPosition;
fcn_INTERNAL_drag(figureHandle, patchLeft, 'normal', [100 100], [150 100]);
assert(norm(axesLeft.CameraPosition - leftBefore) > 1e-6, 'A drag on the left axes turns it');
close(figureHandle);

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ______        _     __  __           _        _______        _
%  |  ____|      | |   |  \/  |         | |      |__   __|      | |
%  | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
%  |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
%  | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
%  |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic example - NO FIGURE (FigNum=-1: no input checks)
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, FigNum=-1\n',figNum);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
axesHandle = axes(figureHandle);
patch(axesHandle, 'Faces', boxFaces, 'Vertices', boxVertices);
fcn_CarMesh3D_addCadMouse(axesHandle, FigNum=-1);
assert(~isempty(figureHandle.WindowScrollWheelFcn));
close(figureHandle);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% (none yet)

%% Fail conditions
if 1==0
    %% Not an axes
    fcn_CarMesh3D_addCadMouse(42);
    %% Axes in two figures
    fcn_CarMesh3D_addCadMouse([axes(figure) axes(figure)]);
end


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_drag
function fcn_INTERNAL_drag(figureHandle, clickedObject, selectionType, fromPoint, toPoint)
% A mouse drag, as the figure's own callbacks see it: the button goes
% down on clickedObject at fromPoint, moves to toPoint, and comes up
figureHandle.CurrentObject = clickedObject;
fcn_INTERNAL_setSelectionType(figureHandle, selectionType);
figureHandle.CurrentPoint = fromPoint;
figureHandle.WindowButtonDownFcn(figureHandle, []);
figureHandle.CurrentPoint = toPoint;
figureHandle.WindowButtonMotionFcn(figureHandle, []);
figureHandle.WindowButtonUpFcn(figureHandle, []);
end % Ends fcn_INTERNAL_drag

%% fcn_INTERNAL_setSelectionType
function fcn_INTERNAL_setSelectionType(figureHandle, selectionType)
% SelectionType is read-only; a left or right press is stood in for by
% the figure's UserData, which this test's callbacks do not use. So the
% test sets it the only way MATLAB allows: by the hidden property.
try
    set(figureHandle, 'SelectionType', selectionType);
catch
    figureHandle.UserData = selectionType;   % (not reached on recent MATLAB)
end
end % Ends fcn_INTERNAL_setSelectionType
