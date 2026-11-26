% script_test_fcn_CarMesh3D_icons.m
% Tests fcn_CarMesh3D_icons: the pictures on CarMesh3D's buttons.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_icons
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% DEMO case: every icon, active and greyed
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: every icon\n', figNum);
iconNames = fcn_CarMesh3D_icons('list', FigNum=figNum);
assert(iscellstr(iconNames) && all(ismember({'vehicleNext', 'vehiclePrevious', 'questionNext', 'questionPrevious', ...
    'summary', 'questions'}, iconNames)));
assert(~isempty(findobj(figure(figNum), 'Type', 'image')));

%% TEST case: sizes, colors, and the greyed look
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: sizes and looks\n', figNum);
for ith_icon = 1:numel(iconNames)
    active = fcn_CarMesh3D_icons(iconNames{ith_icon});
    greyed = fcn_CarMesh3D_icons(iconNames{ith_icon}, FlagEnabled=false);
    assert(size(active, 1) == 24 && size(active, 3) == 3 && isequal(size(active), size(greyed)), iconNames{ith_icon});
    assert(all(active(:) >= 0 & active(:) <= 1), 'Colors from 0 to 1');
    assert(max(abs(greyed(:, :, 1) - greyed(:, :, 2)), [], 'all') < 1e-12, 'Greyed: no color');
    assert(std(greyed(:)) < std(active(:)), 'Greyed: fainter than active');
    assert(any(abs(active(:) - 0.96) > 0.2), 'Something is drawn');
end
assert(size(fcn_CarMesh3D_icons('vehicleNext'), 2) > size(fcn_CarMesh3D_icons('questionNext'), 2), 'Vehicles are wider');
assert(~isequal(fcn_CarMesh3D_icons('vehicleNext'), fcn_CarMesh3D_icons('vehiclePrevious')), '+ and - differ');
big = fcn_CarMesh3D_icons('summary', Height=64);
assert(size(big, 1) == 64);

%% TEST case: on a button
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: on a button\n', figNum);
figureHandle = uifigure('Visible', 'off');
button = uibutton(figureHandle, 'Text', '', 'Icon', fcn_CarMesh3D_icons('vehicleNext'));
assert(isequal(size(button.Icon), size(fcn_CarMesh3D_icons('vehicleNext'))));
delete(figureHandle);

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode: FigNum=-1, and no figure\n', figNum);
figuresBefore = numel(findall(groot, 'Type', 'figure'));
fcn_CarMesh3D_icons('questions', FigNum=-1);
fcn_CarMesh3D_icons('questions');
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore, 'No figure without FigNum');

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_icons('noSuchIcon');
    error('test:noError', 'An unknown name was taken');
catch caughtError
    assert(strcmp(caughtError.identifier, 'CarMesh3D:badInput'), caughtError.message);
end
try
    fcn_CarMesh3D_icons('summary', Height=2);
    error('test:noError', 'Height=2 was taken');
catch caughtError
    assert(strcmp(caughtError.identifier, 'CarMesh3D:badInput'), caughtError.message);
end

close all;
fprintf(1,'All tests of fcn_CarMesh3D_icons passed\n');
