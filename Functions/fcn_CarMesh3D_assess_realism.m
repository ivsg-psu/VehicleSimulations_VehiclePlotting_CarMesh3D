function result = fcn_CarMesh3D_assess_realism(vehicleInput, options)
% fcn_CarMesh3D_assess_realism
% V&V assessment: "Is the realism of this mesh (Fig 1) higher than, equal
% to, or lower than this approved mesh (Fig 2)?" This mesh beside
% the approved exemplar of its body style (fcn_CarMesh3D_loadBodyStyles),
% the standard a mesh should meet. Lower is the problem answer. Skipped,
% with a note, when the body style has no approved exemplar, or when this
% vehicle is the only one (Q58 (A)).
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
%       result = fcn_CarMesh3D_assess_realism(vehicleInput,...
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
%      has one ('realism'). Default: the first.
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
%      fcn_CarMesh3D_loadBodyStyles, fcn_CarMesh3D_plotVehicle, fcn_CarMesh3D_fingerprint
%
% EXAMPLES:
%
%       fcn_CarMesh3D_assess_realism('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_realism.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_realism
%   % * First write (the V&V design file, section 5, order 6)

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
described = struct('Key', 'realism', 'Title', 'Realism', ...
    'Question', 'Is the realism of this mesh (Fig 1) higher than, equal to, or lower than this approved mesh (Fig 2)?', ...
    'Answers', {{'Higher', 'Equal', 'Lower'}}, 'ProblemAnswers', {{'Lower'}}, ...
    'Help', ['Fig 1 (left): this mesh. Fig 2 (right): the approved exemplar of its body style, the standard a ' ...
    'mesh should meet. Lower if this mesh looks clearly worse (blockier, missing details, wrong ' ...
    'colors); Higher if it is good enough to be an exemplar itself.'], ...
    'GroupKey', 'realism', 'GroupTitle', 'Realism', ...
    'GroupHelp', 'This mesh beside its body style''s approved exemplar');
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Skip = '';
% (the body style's approved exemplar, other than this vehicle)
exemplarID = '';
bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=-1);
style = bodyStyles(strcmp({bodyStyles.BodyStyle}, char(vehicle.BodyStyle)));
if isempty(char(vehicle.BodyStyle))
    result.Skip = 'this vehicle has no body style (it is not filed under Data\BodyStyles), so no exemplar to compare with';
elseif isempty(style) || ~style(1).HasExemplar
    result.Skip = sprintf('the body style ''%s'' has no approved exemplar to compare with', char(vehicle.BodyStyle));
else
    others = setdiff(cellstr(style(1).ExemplarIDs), {vehicle.ID}, 'stable');
    if isempty(others)
        result.Skip = sprintf('this vehicle is the only approved exemplar of the body style ''%s''', char(vehicle.BodyStyle));
    else
        exemplarID = others{1};
    end
end
if ~isempty(result.Skip)
    result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, result.Skip);
    result.Note = result.Skip;
    return;
end
exemplar = fcn_CarMesh3D_reviewInput(exemplarID, FigNum=-1);
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, fcn_INTERNAL_field(mesh, 'FaceColors'), ...
    exemplar.ID, exemplar.Mesh.Vertices, exemplar.Mesh.Faces, fcn_INTERNAL_field(exemplar.Mesh, 'FaceColors'));
result.Note = sprintf('%s (%d faces) beside the exemplar %s (%d faces)', vehicle.Name, size(mesh.Faces, 1), ...
    exemplar.Name, size(exemplar.Mesh.Faces, 1));
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: this mesh, and the exemplar, from the same angle
meshes = {mesh, exemplar.Mesh};
captions = {sprintf('Fig 1, this mesh: %s', vehicle.Name), sprintf('Fig 2, the approved mesh: %s', exemplar.Name)};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 2, FigNum=options.FigNum);
for ith_view = 1:2
    fcn_CarMesh3D_plotVehicle(meshes{ith_view}, AxesHandle=axesHandles(ith_view), FigNum=-1);
    view(axesHandles(ith_view), 145, 20);   % (the front left)
    axis(axesHandles(ith_view), 'equal', 'off');
    title(axesHandles(ith_view), captions{ith_view}, 'FontWeight', 'normal', 'FontSize', 11, 'Interpreter', 'none');
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
