% script_test_fcn_CarMesh3D_turnSteeringWheel
% Tests of fcn_CarMesh3D_turnSteeringWheel on a made-up steering wheel (a
% ring of points, tilted like the 2009 Fit's: its axis pointing rearward
% and up, 28 degrees from horizontal) inside a few other vertices that
% must not move.
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_turnSteeringWheel
%   % * First write of the tests

%% Set up the workspace
close all;

% (a ring of 36 points, radius 0.17 m, around the Fit's wheel center, its
% axis toward the driver: rearward and up; plus 4 vertices elsewhere)
center = [1.666 0.329 0.925];
axisUnit = [-0.883 0 0.470]/norm([-0.883 0 0.470]);
upInPlane = cross(cross(axisUnit, [0 0 1]), axisUnit);
upInPlane = upInPlane/norm(upInPlane);              % (the wheel's "12 o'clock")
leftInPlane = cross(axisUnit, upInPlane);           % (toward +y)
ringAngles = (0:10:350)';
ring = center + 0.17*(cosd(ringAngles)*upInPlane + sind(ringAngles)*leftInPlane);
others = [0 0 0; 1 1 1; 2 -0.5 0.3; 1.666 0.329 0.4];
vertices = [ring; others];
wheel = struct('Center', center, 'Normal', axisUnit, 'VertexIndices', (1:36)');

%% DEMO case: a 10 degree left steer, ratio 15: the wheel turns 150 degrees
fig_num = 10001;
fprintf(1,'Figure %d: DEMO case: a 10 degree left steer\n', fig_num);
[turned, handwheel] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 10, SteeringRatio=15, FigNum=fig_num);
assert(abs(handwheel - 150) < 1e-12, 'The handwheel turns by the ratio times the road wheel angle');
assert(ishandle(fig_num), 'The plot was made');

%% TEST case: only the wheel moves; it turns rigidly about its own axis
fig_num = 20001;
fprintf(1,'Figure %d: TEST case: a rigid turn about the axis\n', fig_num);
assert(isequal(turned(37:end,:), others), 'The other vertices do not move');
assert(max(abs(vecnorm(turned(1:36,:) - center, 2, 2) - 0.17)) < 1e-12, 'Every rim point stays 0.17 m from the center');
assert(max(abs((turned(1:36,:) - center)*axisUnit')) < 1e-12, 'The rim stays in its plane');
% (each rim point moved by exactly 150 degrees around the axis)
movedAngles = atan2d((turned(1:36,:) - center)*leftInPlane', (turned(1:36,:) - center)*upInPlane');
assert(max(abs(mod(movedAngles - ringAngles - 150 + 180, 360) - 180)) < 1e-9, 'A 150 degree turn');

%% TEST case: the direction: steering left turns the wheel's top to the left
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: the direction of the turn\n', fig_num);
[leftTurn, ~] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 2, SteeringRatio=15, FigNum=-1);    % (30 degrees)
[rightTurn, ~] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, -2, SteeringRatio=15, FigNum=-1);
assert(leftTurn(1,2) > vertices(1,2) + 0.05 && rightTurn(1,2) < vertices(1,2) - 0.05, ...
    'Steering left (positive) moves the 12 o''clock point to the left (+y), as the driver turns counterclockwise');
[straight, straightHandwheel] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 0, FigNum=-1);
assert(straightHandwheel == 0 && max(abs(straight(:) - vertices(:))) < 1e-12, 'Straight ahead: nothing moves');

%% TEST case: held at the lock; the default ratio; the wheel given by its faces
fig_num = 20003;
fprintf(1,'Figure %d: TEST case: the lock, the default ratio, faces\n', fig_num);
[~, locked] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 40, SteeringRatio=15, MaxTurns=1.2, FigNum=-1);
assert(abs(locked - 432) < 1e-12, 'Held at 1.2 turns (432 degrees) instead of 600');
[~, lockedRight] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, -40, SteeringRatio=15, MaxTurns=1.2, FigNum=-1);
assert(abs(lockedRight + 432) < 1e-12, 'Held at the other lock too');
[~, defaultHandwheel] = fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 1, FigNum=-1);
assert(defaultHandwheel == 15, 'The default ratio is 15');
wheelByFaces = struct('Center', center, 'Normal', axisUnit, 'Faces', (1:35)');
facesOfMesh = [(1:35)' (2:36)' [3:36 1]'];   % (35 faces whose corners are the 36 rim points)
turnedByFaces = fcn_CarMesh3D_turnSteeringWheel(vertices, wheelByFaces, 10, SteeringRatio=15, FacesOfMesh=facesOfMesh, FigNum=-1);
assert(max(abs(turnedByFaces(:) - turned(:))) < 1e-12, 'Faces give the same turn as vertex indices');

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases\n', fig_num);
Niterations = 200;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 5, FigNum=[]);
end
slowTime = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 5, FigNum=-1);
end
fastTime = toc;
fprintf(1, 'Average time per call: normal %.5f s, fast mode %.5f s\n', slowTime/Niterations, fastTime/Niterations);
assert(isempty(findall(0, 'Type', 'figure', 'Number', fig_num)), 'Fast mode makes no plot');
close all;
fprintf(1, 'All tests of fcn_CarMesh3D_turnSteeringWheel passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: vertices not N x 3
    fcn_CarMesh3D_turnSteeringWheel([1 2], wheel, 10);

    %% FAIL case: faces given without the mesh's faces
    fcn_CarMesh3D_turnSteeringWheel(vertices, wheelByFaces, 10);

    %% FAIL case: a negative ratio
    fcn_CarMesh3D_turnSteeringWheel(vertices, wheel, 10, SteeringRatio=-15);
end
