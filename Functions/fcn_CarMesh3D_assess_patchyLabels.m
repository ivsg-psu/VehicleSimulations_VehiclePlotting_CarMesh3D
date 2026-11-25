function result = fcn_CarMesh3D_assess_patchyLabels(vehicleInput, options)
% fcn_CarMesh3D_assess_patchyLabels
% V&V assessment: "Are the labels clean, with no blotchy or patchy
% areas?" (Sean, 2026-11-25 01:32). The vehicle in its label colors, with
% flat lighting and faces seen from behind left unlit, so both kinds of
% patches show: mixed-up labels (stray colors) and faces pointing the
% wrong way (nearly black). "A perfect example of something a human
% catches in fractions of a second whereas code takes tons of
% computations" (Sean).
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
%       result = fcn_CarMesh3D_assess_patchyLabels(vehicleInput,...
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
%      has one ('patchyLabels'). Default: the first.
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
%      fcn_CarMesh3D_plotLabels, fcn_CarMesh3D_plotVehicle, fcn_CarMesh3D_fingerprint
%
% EXAMPLES:
%
%       fcn_CarMesh3D_assess_patchyLabels('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_patchyLabels.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_patchyLabels
%   % * First write (the V&V design file, section 5, order 3)

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
described = struct('Key', 'patchyLabels', 'Title', 'Patchy labels', ...
    'Question', 'Are the labels clean, with no blotchy or patchy areas?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['Patches often mean faces pointing the wrong way, or mixed-up labels (Sean). Faces are lit only ' ...
    'from the front here, so a face pointing the wrong way is nearly black; a stray patch of another ' ...
    'label''s color is a mix-up. No if any outside surface is blotchy or patchy.'], ...
    'GroupKey', 'patchyLabels', 'GroupTitle', 'Patchy labels', ...
    'GroupHelp', 'Blotchy or patchy labels: faces pointing the wrong way, or mixed-up labels');
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Skip = '';
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, fcn_INTERNAL_field(mesh, 'FacePartIndex'), ...
    fcn_INTERNAL_field(mesh, 'FaceLightType'));
result.Note = sprintf('%s: %d faces', vehicle.Name, size(mesh.Faces, 1));
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: the label colors, flat lighting, back faces unlit, front
% and rear
labelMesh = fcn_CarMesh3D_plotLabels(mesh, FigNum=-1);
captions = {'Labels, lit from the front only: from the front left', 'from the rear right'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 2, FigNum=options.FigNum);
views = [145 20; -35 20];   % (azimuth, elevation: front left, rear right; +x forward, +y left)
for ith_view = 1:2
    fcn_CarMesh3D_plotVehicle(labelMesh, AxesHandle=axesHandles(ith_view), FaceLighting='flat', FigNum=-1);
    % (a face seen from behind is left unlit, so it shows dark)
    % (and little ambient light, so it shows nearly black: tried with half
    % the faces flipped, 2026-11-25)
    set(findobj(axesHandles(ith_view), 'Type', 'patch'), 'BackFaceLighting', 'unlit', ...
        'AmbientStrength', 0.12, 'DiffuseStrength', 0.95, 'SpecularStrength', 0);
    view(axesHandles(ith_view), views(ith_view, 1), views(ith_view, 2));
    axis(axesHandles(ith_view), 'equal', 'off');
    title(axesHandles(ith_view), captions{ith_view}, 'FontWeight', 'normal', 'FontSize', 11);
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
