function result = fcn_CarMesh3D_assess_overall(vehicleInput, options)
% fcn_CarMesh3D_assess_overall
% V&V assessment: "Does this mesh pass a first glance?" (Sean, 2026-11-25
% 01:13). The first question of a review: a few seconds' look at the
% vehicle as it will be drawn, from the front and from the rear. A No
% (wrong vehicle, missing parts, a scrambled or inside-out mesh, far too
% few faces) ends the review when "Stop at the first No?" is on.
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
%       result = fcn_CarMesh3D_assess_overall(vehicleInput,...
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
%      has one ('overall'). Default: the first.
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
%       fcn_CarMesh3D_assess_overall('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_overall.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_overall
%   % * First write (the V&V design file, section 5, order 1)

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
described = struct('Key', 'overall', 'Title', 'Overall', ...
    'Question', 'Does this mesh pass a first glance?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['A few seconds, before anything else: No if something is plainly wrong, such as the wrong vehicle, ' ...
    'missing parts, a scrambled or inside-out mesh, or far too few faces to be usable. No ends the review here ' ...
    'when "Stop at the first No?" is on.'], ...
    'GroupKey', 'overall', 'GroupTitle', 'Overall', ...
    'GroupHelp', 'A first glance at the whole vehicle: worth reviewing further?');
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, fcn_INTERNAL_field(mesh, 'FaceColors'), ...
    fcn_INTERNAL_field(mesh, 'FaceAlpha'));
result.Skip = '';
result.Note = sprintf('%s: %d faces', vehicle.Name, size(mesh.Faces, 1));
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: the vehicle as it will be drawn, front and rear
captions = {sprintf('%s: from the front left', vehicle.Name), ...
    sprintf('from the rear right (%d faces)', size(mesh.Faces, 1))};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 2, FigNum=options.FigNum);
views = [145 20; -35 20];   % (azimuth, elevation: front left, rear right; +x forward, +y left)
for ith_view = 1:2
    fcn_CarMesh3D_plotVehicle(mesh, AxesHandle=axesHandles(ith_view), FigNum=-1);
    view(axesHandles(ith_view), views(ith_view, 1), views(ith_view, 2));
    axis(axesHandles(ith_view), 'equal', 'off');
    % (captions after plotVehicle, which sets its own title)
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
