function result = fcn_CarMesh3D_assess_headlights(vehicleInput, options)
% fcn_CarMesh3D_assess_headlights
% V&V assessment: "Do the headlights go off, low, high as expected in
% these pictures?" The front of the vehicle at night, three times: headlights off,
% on low beam, on high beam (Sean, 2026-11-24 22:54); far views on top,
% close-ups of the left (driver's side) headlight below (Sean, T76 (B)).
%
% Every V&V assessment function works the same way (the V&V design file,
% Documentation_CarMesh3D_GUIdesign_VandV.md, section 3):
%   Mode='describe'     no vehicle, no file, no figure: its title,
%                       question, answers and tooltip, for the menus
%   Mode='fingerprint'  the fingerprint of the data it would show, without
%                       drawing (so the V&V GUI can tell an old answer is
%                       out of date)
%   Mode='draw'         (default) draws its pictures into Parent (or a
%                       figure of its own), then returns; it never returns
%                       drawing for the caller to do later
%
% FORMAT:
%
%       result = fcn_CarMesh3D_assess_headlights(vehicleInput,...
%           (Mode=mode), (Key=key), (Parent=panel), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID or folder, or the structure
%      fcn_CarMesh3D_reviewInput makes ([] in describe mode).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mode: 'draw' (default), 'describe' or 'fingerprint'.
%
%      Key: which question, for an assessment with more than one; this one
%      has one ('headlights'). Default: the first.
%
%      Parent: the panel to draw in; [] (default) for a figure of its own.
%
%      FigNum: the figure to use with no Parent; -1 for fast mode.
%
% OUTPUTS:
%
%      result: a structure (one element per question in describe mode)
%      with Key, Title, Question, Detail (a second line of guidance under
%      the question), Answers, ProblemAnswers, Help, GroupKey,
%      GroupTitle, GroupHelp; and, in the other modes, Fingerprint, Skip
%      ('' or why it cannot be asked for this vehicle) and Note.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_reviewInput, fcn_CarMesh3D_assessAxes,
%      fcn_CarMesh3D_plotVehicle, fcn_CarMesh3D_fingerprint
%
% EXAMPLES:
%
%       fcn_CarMesh3D_assess_headlights('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_headlights.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_headlights
%   % * First write (the V&V design file, section 5, order 4)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_assess_headlights
%   % * Detail: a second line of guidance under the question (Sean, T62);
%   %   % shorter, without function names: the GUI's "Show the commands"
%   %   % gives them (Sean, T74)
%   % * The beams on a ground plane ahead, so the light cones show (Sean,
%   %   % T63): plotVehicle's LightEffects, on a dark ground
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_headlights
%   % * Two rows (Sean, T76 (B)): the far views on top ("Far view"), and
%   %   % close-ups of the left (driver's side) headlight below
%   %   % (drafted with Claude)
%   % * The new lamp keys (Q92 (A)); type names compared as spelled

% TO-DO:
%
% (none)

arguments
    vehicleInput            % Vehicle ID, folder or reviewInput structure ([] to describe)
    options.Mode = 'draw'   % 'draw', 'describe' or 'fingerprint'
    options.Key = ''        % Which question ('' for the first)
    options.Parent = []     % The panel to draw in
    options.FigNum = []     % A figure of its own; -1 fast mode
end

%% Main code
described = struct('Key', 'headlights', 'Title', 'Headlights', ...
    'Question', 'Do the headlights go off, low, high as expected in these pictures?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['The front at night, three times: headlights off, on low beam, on high beam, with the beams on ' ...
    'the ground ahead (short and wide for low; long and narrow added for high); below, the same close up on ' ...
    'the left (driver''s side) headlamp. No if a headlamp ' ...
    'does not light, the wrong part lights (such as the grille), or a lamp lights when it should be ' ...
    'off.'], ...
    'Detail', 'If unsure, select No and check the night view in the viewer; fix in the painter. Do not select Yes if unsure.', ...
    'GroupKey', 'headlights', 'GroupTitle', 'Headlights', ...
    'GroupHelp', 'The headlights: off, low beam, high beam');
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Skip = '';
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, fcn_INTERNAL_field(mesh, 'LabelFaceLamp'), ...
    fcn_INTERNAL_field(mesh, 'FaceColors'));
numLamps = fcn_INTERNAL_countLamps(mesh, {'headlamp', 'highBeamLamp'});
result.Note = sprintf('%s: %d headlight faces', vehicle.Name, numLamps);
if numLamps == 0
    result.Note = sprintf('%s: NO faces are labeled as headlights', vehicle.Name);
end
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: the front at night, off, low and high
states = struct('LowBeam', {false, true, true}, 'HighBeam', {false, false, true});   % (off, low, high: high lights both beams)
captions = {'Headlights off', 'Low beam', 'High beam'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 6, Rows=2, FlagDark=true, ...
    RowLabels={'Far view', 'Close-up of left headlamp'}, FigNum=options.FigNum);
% (the beams: plotVehicle's light pools, on a dark ground that reaches
% groundAhead meters in front of the vehicle, seen from above the front
% left so the cones show; Sean, T63)
groundAhead = 5;    % [m] ground shown ahead of the front
groundSide = 2.2;   % [m] ground shown to each side of the center line
meshLow = min(mesh.Vertices, [], 1);
meshHigh = max(mesh.Vertices, [], 1);
groundX = [meshLow(1) - 0.5, meshHigh(1) + groundAhead];
for ith_view = 1:3
    fcn_CarMesh3D_plotVehicle(mesh, AxesHandle=axesHandles(ith_view), ...
        Signals=states(ith_view), FlagLightEffects=true, FigNum=-1);
    patch(axesHandles(ith_view), 'XData', groundX([1 2 2 1]), 'YData', groundSide*[-1 -1 1 1], ...
        'ZData', -0.003*[1 1 1 1], 'FaceColor', [0.16 0.16 0.19], 'EdgeColor', 'none', 'FaceLighting', 'none', ...
        'HitTest', 'off', 'Tag', 'assessGround');
    view(axesHandles(ith_view), 128, 20);   % (the front, from the left and above: the beams ahead show)
    axis(axesHandles(ith_view), 'equal', 'off');
    xlim(axesHandles(ith_view), groundX);
    ylim(axesHandles(ith_view), groundSide*[-1 1]);
    zlim(axesHandles(ith_view), [-0.01, meshHigh(3) + 0.1]);
    camzoom(axesHandles(ith_view), 1.35);   % (the vehicle as large as the beams allow)
    title(axesHandles(ith_view), captions{ith_view}, 'FontWeight', 'normal', 'FontSize', 11, 'Color', [0.9 0.9 0.9]);
    axesHandles(ith_view).Title.Visible = 'on';
    % (below it: the same lamps, close up on the left headlight)
    closeAxes = axesHandles(3 + ith_view);
    fcn_CarMesh3D_plotVehicle(mesh, AxesHandle=closeAxes, Signals=states(ith_view), FigNum=-1);
    axis(closeAxes, 'equal', 'off');
    fcn_INTERNAL_closeUp(closeAxes, mesh, {'headlamp', 'highBeamLamp'}, true, 135, 12);
    title(closeAxes, captions{ith_view}, 'FontWeight', 'normal', 'FontSize', 11, 'Color', [0.9 0.9 0.9]);
    closeAxes.Title.Visible = 'on';
end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(structure, name)
% A field's value, or [] when the structure has no such field
value = [];
if isfield(structure, name)
    value = structure.(name);
end
end % Ends fcn_INTERNAL_field

%% fcn_INTERNAL_countLamps
function count = fcn_INTERNAL_countLamps(mesh, typeNames)
% How many faces are lamps of these types
count = 0;
if ~isfield(mesh, 'LabelFaceLamp') || ~isfield(mesh, 'LabelLampNames')
    return;
end
typeIndex = find(ismember(cellstr(mesh.LabelLampNames), typeNames));
count = sum(ismember(mesh.LabelFaceLamp, typeIndex));
end % Ends fcn_INTERNAL_countLamps

%% fcn_INTERNAL_closeUp
function fcn_INTERNAL_closeUp(axesHandle, mesh, typeNames, flagFront, azimuth, elevation)
% The view close up on the left (+y, the driver's side) lamps of these
% types, at the front or the rear, from this direction: the axes' limits
% cut down to a box around them, so everything outside is clipped (a
% zoomed camera alone draws past the picture's edge, over its
% neighbors); the whole vehicle when it has none
view(axesHandle, azimuth, elevation);
flagFaces = false(size(mesh.Faces, 1), 1);
if isfield(mesh, 'LabelFaceLamp') && isfield(mesh, 'LabelLampNames')
    flagFaces = ismember(mesh.LabelFaceLamp, find(ismember(cellstr(mesh.LabelLampNames), typeNames)));
end
centers = (mesh.Vertices(mesh.Faces(:,1),:) + mesh.Vertices(mesh.Faces(:,2),:) + mesh.Vertices(mesh.Faces(:,3),:))/3;
middleX = (min(mesh.Vertices(:,1)) + max(mesh.Vertices(:,1)))/2;
sideY = 0.3*max(mesh.Vertices(:,2));   % (the left lamps: clear of a lamp in the middle, such as a high brake lamp)
if flagFront
    flagFaces = flagFaces & centers(:,1) > middleX & centers(:,2) > sideY;
else
    flagFaces = flagFaces & centers(:,1) < middleX & centers(:,2) > sideY;
end
if ~any(flagFaces)
    return;
end
corners = mesh.Vertices(unique(mesh.Faces(flagFaces,:)),:);
low = min(corners, [], 1);
high = max(corners, [], 1);
center = (low + high)/2;
halfSize = max(0.25, 0.75*max(high - low));   % [m] (a cube around the lamp, at least 50 cm across)
xlim(axesHandle, center(1) + halfSize*[-1 1]);
ylim(axesHandle, center(2) + halfSize*[-1 1]);
zlim(axesHandle, center(3) + halfSize*[-1 1]);
set(findall(axesHandle, 'Type', 'patch'), 'Clipping', 'on');
set(findall(axesHandle, 'Type', 'line'), 'Clipping', 'on');
end % Ends fcn_INTERNAL_closeUp
