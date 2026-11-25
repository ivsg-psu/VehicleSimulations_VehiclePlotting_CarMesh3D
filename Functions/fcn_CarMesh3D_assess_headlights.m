function result = fcn_CarMesh3D_assess_headlights(vehicleInput, options)
% fcn_CarMesh3D_assess_headlights
% V&V assessment: "Do the headlights go off, low, high as expected in
% these three pictures?" The front of the vehicle at night, three times: headlights off,
% on low beam, on high beam (Sean, 2026-11-24 22:54).
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
%      with Key, Title, Question, Answers, ProblemAnswers, Help, GroupKey,
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
    'Question', 'Do the headlights go off, low, high as expected in these three pictures?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['The front at night, three times: headlights off, on low beam, on high beam. No if a headlight ' ...
    'does not light, the wrong part lights (such as the grille), or a lamp lights when it should be ' ...
    'off.'], ...
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
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, fcn_INTERNAL_field(mesh, 'FaceLightType'), ...
    fcn_INTERNAL_field(mesh, 'FaceColors'));
numLamps = fcn_INTERNAL_countLamps(mesh, {'headlight', 'highbeam'});
result.Note = sprintf('%s: %d headlight faces', vehicle.Name, numLamps);
if numLamps == 0
    result.Note = sprintf('%s: NO faces are labeled as headlights', vehicle.Name);
end
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: the front at night, off, low and high
states = {'off', 'low', 'high'};
captions = {'Headlights off', 'Low beam', 'High beam'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 3, Dark=true, FigNum=options.FigNum);
for ith_view = 1:3
    fcn_CarMesh3D_plotVehicle(mesh, AxesHandle=axesHandles(ith_view), ...
        LightStates=struct('Headlights', states{ith_view}), FigNum=-1);
    view(axesHandles(ith_view), 115, 12);   % (the front, a little from the left)
    axis(axesHandles(ith_view), 'equal', 'off');
    title(axesHandles(ith_view), captions{ith_view}, 'FontWeight', 'normal', 'FontSize', 11, 'Color', [0.9 0.9 0.9]);
    axesHandles(ith_view).Title.Visible = 'on';
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
if ~isfield(mesh, 'FaceLightType') || ~isfield(mesh, 'LightTypeNames')
    return;
end
typeIndex = find(ismember(lower(cellstr(mesh.LightTypeNames)), typeNames));
count = sum(ismember(mesh.FaceLightType, typeIndex));
end % Ends fcn_INTERNAL_countLamps
