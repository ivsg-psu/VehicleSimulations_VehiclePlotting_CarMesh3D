% script_test_fcn_CarMesh3D_assessAxes.m
% Tests: fcn_CarMesh3D_assessAxes
%
% The pictures' axes for a V&V assessment: in a figure of its own, and in
% a panel (as the V&V GUI draws it), light and dark, with captions.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assessAxes
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all

%% Basic case: a figure of its own
fprintf(1, 'Basic case: a figure of its own\n');
figNum = 1001;
axesHandles = fcn_CarMesh3D_assessAxes([], 2, Captions={'front', 'rear'}, FigNum=figNum);
assert(numel(axesHandles) == 2 && all(isgraphics(axesHandles, 'axes')));
assert(strcmp(axesHandles(1).Title.String, 'front') && strcmp(axesHandles(2).Title.String, 'rear'));
assert(ishold(axesHandles(1)));
assert(isequal(axesHandles(1).Parent.Parent, figure(figNum)) || isequal(ancestor(axesHandles(1), 'figure'), figure(figNum)));
% (again into the same figure: cleared first)
fcn_CarMesh3D_assessAxes([], 3, FigNum=figNum);
assert(numel(findall(figure(figNum), 'Type', 'axes')) == 3);
close(figure(figNum));

%% In a panel, dark
fprintf(1, 'In a panel, dark\n');
figureHandle = uifigure('Visible', 'off');
panel = uipanel(figureHandle);
uibutton(panel, 'Text', 'left from before');
axesHandles = fcn_CarMesh3D_assessAxes(panel, 3, Captions={'a', 'b', 'c'}, Dark=true);
assert(numel(axesHandles) == 3 && isa(axesHandles(1), 'matlab.ui.control.UIAxes'));
assert(isempty(findall(panel, 'Type', 'uibutton')));   % (the panel cleared)
assert(all(axesHandles(1).Color < 0.3));   % (dark)
assert(strcmp(axesHandles(3).Title.String, 'c'));
% (again: the panel holds only the new axes)
fcn_CarMesh3D_assessAxes(panel, 1);
assert(isscalar(findall(panel, 'Type', 'axes')));
delete(figureHandle);

%% Fast mode
fprintf(1, 'Fast mode\n');
axesHandles = fcn_CarMesh3D_assessAxes([], 1, FigNum=-1);
assert(isgraphics(axesHandles(1), 'axes'));
close(ancestor(axesHandles(1), 'figure'));

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_assessAxes([], 0);
    error('should have failed');
catch inputError
    assert(strcmp(inputError.identifier, 'CarMesh3D:badInput'));
end
try
    fcn_CarMesh3D_assessAxes(5, 1);
    error('should have failed');
catch inputError
    assert(strcmp(inputError.identifier, 'CarMesh3D:badInput'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_assessAxes passed.\n');
