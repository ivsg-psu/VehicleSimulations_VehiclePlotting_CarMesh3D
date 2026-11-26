function result = fcn_CarMesh3D_assess_brakeLights(vehicleInput, options)
% fcn_CarMesh3D_assess_brakeLights
% V&V assessment: "Do the brake lights come on as expected in these
% pictures?" The rear of the vehicle at night, three times: lamps off, tail
% lamps on, braking. The brake lights are the most important light signal
% (Sean, 2026-11-25 01:28).
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
%       result = fcn_CarMesh3D_assess_brakeLights(vehicleInput,...
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
%      has one ('brakeLights'). Default: the first.
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
%       fcn_CarMesh3D_assess_brakeLights('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_brakeLights.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_brakeLights
%   % * First write (the V&V design file, section 5, order 5)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_assess_brakeLights
%   % * Detail: a second line of guidance under the question (Sean, T62);
%   %   % shorter, without function names: the GUI's "Show the commands"
%   %   % gives them (Sean, T74)

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
described = struct('Key', 'brakeLights', 'Title', 'Brake lights', ...
    'Question', 'Do the brake lights come on as expected in these pictures?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['The rear at night, three times: lamps off, tail lamps on, braking. Tail and brake lamps often ' ...
    'share a housing, so this catches one labeled as the other. No if the brake lamps do not light, ' ...
    'the wrong part lights, or braking looks no brighter than the tail lamps alone.'], ...
    'Detail', 'If unsure, select No and check the night view in the viewer; fix in the painter. Do not select Yes if unsure.', ...
    'GroupKey', 'brakeLights', 'GroupTitle', 'Brake lights', ...
    'GroupHelp', 'The brake lights: the most important light signal');
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
numLamps = fcn_INTERNAL_countLamps(mesh, {'tail'});   % (the tail lamps are the brake lamps, lit bright)
result.Note = sprintf('%s: %d tail and brake lamp faces', vehicle.Name, numLamps);
if numLamps == 0
    result.Note = sprintf('%s: NO faces are labeled as tail or brake lamps', vehicle.Name);
end
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: the rear at night, off, tail lamps, braking
states = {'off', 'on', 'brake'};
captions = {'Lamps off', 'Tail lamps on', 'Braking'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 3, Dark=true, FigNum=options.FigNum);
for ith_view = 1:3
    fcn_CarMesh3D_plotVehicle(mesh, AxesHandle=axesHandles(ith_view), ...
        LightStates=struct('Tail', states{ith_view}), FigNum=-1);
    view(axesHandles(ith_view), -65, 12);   % (the rear, a little from the right)
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
