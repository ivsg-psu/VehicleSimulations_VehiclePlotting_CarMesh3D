function result = fcn_CarMesh3D_assess_lampsAndGlass(vehicleInput, options)
% fcn_CarMesh3D_assess_lampsAndGlass
% V&V assessment, and the human question of the main window's first gate,
% Validate Import (T99 and Q116 (B), Sean 2026-11-27): "Is every window
% glass, and every lamp a lamp: nothing missed, nothing extra?" The
% vehicle with only its glass (light blue) and its lamps (in their lamp
% colors; a lamp with no kind yet in magenta) colored, everything else
% gray, from the front left and the rear right. Everything after this
% gate rests on these two labels: the face directions use the glass (it is
% seen through), and the build finds the lamp covers from both.
%
% Every V&V assessment function works the same way (the V&V design file,
% Documentation_CarMesh3D_GUIdesign_VandV.md, section 3):
%   Mode='describe'     no vehicle, no file, no figure: its title,
%                       question, answers and tooltip, for the menus
%   Mode='fingerprint'  the fingerprint of the data it would show, without
%                       drawing (so an old answer is known to be out of
%                       date)
%   Mode='draw'         (default) draws its pictures into Parent (or a
%                       figure of its own), then returns
%   Mode='check'        the automatic half of the gate, with no person
%                       needed: Pass (true or false) and CheckText (Q116,
%                       Sean 2026-11-27 21:48: each gate is one assessment
%                       function, the main window only routes)
%
% FORMAT:
%
%       result = fcn_CarMesh3D_assess_lampsAndGlass(vehicleInput,...
%           (Mode=mode), (Key=key), (Parent=panel), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID or folder, or the structure
%      fcn_CarMesh3D_reviewInput makes ([] in describe mode).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mode: 'draw' (default), 'describe', 'fingerprint' or 'check'.
%
%      Key: which question; this one has one ('lampsAndGlass').
%
%      Parent: the panel to draw in; [] (default) for a figure of its own.
%
%      FigNum: the figure to use with no Parent; -1 for fast mode.
%
% OUTPUTS:
%
%      result: a structure with Key, Title, Question, Detail, Answers,
%      ProblemAnswers, Help, GroupKey, GroupTitle, GroupHelp; and, in the
%      other modes, Fingerprint, Skip ('' or why it cannot be asked) and
%      Note (how many glass and lamp faces); in check mode also Pass and
%      CheckText. The automatic check: there are glass faces and lamp
%      faces, and no face is both (the import report's gate,
%      fcn_CarMesh3D_importReport).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_reviewInput, fcn_CarMesh3D_assessAxes, fcn_CarMesh3D_importReport,
%      fcn_CarMesh3D_plotLabels, fcn_CarMesh3D_plotVehicle,
%      fcn_CarMesh3D_fingerprint
%
% EXAMPLES:
%
%       fcn_CarMesh3D_assess_lampsAndGlass('2009_Honda_Fit_Sport', FigNum=1);
%
%       % Asked as a question, alone (as the main window's Validate Import):
%       fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport', Assessments={@fcn_CarMesh3D_assess_lampsAndGlass});
%
%       See the script: script_test_fcn_CarMesh3D_assess_lampsAndGlass.m
%       for a full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_lampsAndGlass
%   % * First write: the human question of the main window's first gate
%   %   % (Validate Import)
%   % * Mode='check': the gate's automatic half (Q116, Sean 21:48)

% TO-DO:
%
% (none)

arguments
    vehicleInput            % Vehicle ID, folder or reviewInput structure ([] to describe)
    options.Mode = 'draw'   % 'draw', 'describe', 'fingerprint' or 'check'
    options.Key = ''        % Which question ('' for the first)
    options.Parent = []     % The panel to draw in
    options.FigNum = []     % A figure of its own; -1 fast mode
end

%% Main code
described = struct('Key', 'lampsAndGlass', 'Title', 'Lamps and glass', ...
    'Question', 'Is every window glass, and every lamp a lamp: nothing missed, nothing extra?', ...
    'Answers', {{'Yes', 'No'}}, 'ProblemAnswers', {{'No'}}, ...
    'Help', ['Only the glass (light blue) and the lamps (in their lamp colors; magenta for a lamp with no ' ...
    'kind yet) are colored; everything else is gray. No if a window is gray (missed), a lamp is gray ' ...
    '(missed), or something that is neither is colored (extra), such as a grille in lamp colors or ' ...
    'a body panel in glass blue. Which lamp is which is checked later (Full Labels).'], ...
    'Detail', 'If No: fix it with First Labels (the painter), then Validate Import again. Do not select Yes if unsure.', ...
    'GroupKey', 'lampsAndGlass', 'GroupTitle', 'Lamps and glass', ...
    'GroupHelp', 'Lamps and glass told apart from the body (the first gate, Validate Import)');
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Skip = '';
partNames = cellstr(fcn_INTERNAL_field(mesh, 'LabelPartNames'));
facePart = fcn_INTERNAL_field(mesh, 'LabelFacePart');
glassIndex = find(strcmp(partNames, 'glass'));
lightIndex = find(strcmp(partNames, 'light'));
flagGlass = ismember(facePart(:), glassIndex);
flagLamp = ismember(facePart(:), lightIndex);
lampKind = fcn_INTERNAL_field(mesh, 'LabelFaceLamp');
if numel(lampKind) == numel(flagLamp)
    flagLamp = flagLamp | lampKind(:) > 0;
end
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces, double(flagGlass), double(flagLamp));
result.Note = sprintf('%s: %d glass faces, %d lamp faces', vehicle.Name, nnz(flagGlass), nnz(flagLamp));
if isempty(facePart)
    result.Skip = 'The mesh has no labels yet.';
end
if strcmpi(options.Mode, 'fingerprint')
    return;
end
if strcmpi(options.Mode, 'check')
    % (the automatic half: the import report's gate)
    result.Pass = false;
    result.CheckText = 'The mesh has no labels yet.';
    if isempty(result.Skip)
        report = fcn_CarMesh3D_importReport(mesh, FigNum=-1);
        result.Pass = logical(report.Gate);
        result.CheckText = report.GateText;
    end
    return;
end

% The pictures: glass and lamps in their label colors, the rest gray
[labelMesh, legendEntries] = fcn_CarMesh3D_plotLabels(mesh, FigNum=-1);
if isfield(labelMesh, 'FaceColors') && size(labelMesh.FaceColors, 1) == numel(flagGlass)
    labelMesh.FaceColors(~(flagGlass | flagLamp), :) = repmat([0.78 0.78 0.78], nnz(~(flagGlass | flagLamp)), 1);
end
keepLegend = arrayfun(@(entry) ~any(strcmpi(entry.Name, {'body', 'trim', 'wheel', 'wheels', 'interior'})), legendEntries);
legendEntries = legendEntries(keepLegend);
captions = {'Glass and lamps, from the front left', 'Glass and lamps, from the rear right'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 2, Legend=legendEntries, FigNum=options.FigNum);
views = [145 20; -35 20];   % (azimuth, elevation: front left, rear right; +x forward, +y left)
for ith_view = 1:2
    fcn_CarMesh3D_plotVehicle(labelMesh, AxesHandle=axesHandles(ith_view), FigNum=-1);
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
