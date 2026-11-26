% script_test_fcn_CarMesh3D_lampUnits.m
% Tests fcn_CarMesh3D_lampUnits
% Finds a vehicle's lamp units (each lamp, named from where it sits, with
% its cover glass): the rows of the lamp-to-function (L2F) matrix.
%
% Figures are made hidden and closed by their handles.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampUnits
%   % * First write of the code (drafted with Claude)

% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (later; drafted with Claude)
% - In script_test_fcn_CarMesh3D_lampUnits
%   % * BUG case: lamp type names in a row

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampUnits
%   % * (fill in items here)


%% Set up the workspace
% A small made-up mesh: a 4 m by 1.6 m box of a vehicle, front at +x,
% left at +y, with lamps as little squares of two triangles each
lampTypeNames = {'headlamp';'turnSignalLamp';'runningLamp';'tailBrakeLamp';'backupLamp';'highBeamLamp';'fogLamp';'reflector';'licensePlateLamp';'markerLamp';'warningLamp'};
testMesh = fcn_INTERNAL_lampMesh(lampTypeNames);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: the 2009 Fit's lamp units, plotted
figNum = 10001;
titleString = sprintf('DEMO case: the 2009 Fit''s lamp units');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
fitMesh = fcn_CarMesh3D_meshWithLabelEdits('2009_Honda_Fit_Sport', FigNum=-1);
[fitUnits, fitFaceUnit] = fcn_CarMesh3D_lampUnits(fitMesh, FigNum=figNum);
fitNames = {fitUnits.Name};
assert(numel(fitNames) == numel(unique(fitNames)), 'Unit names are unique');
for expectedName = {'front-left headlamp', 'front-right headlamp', 'front-left marker lamp', 'front-right marker lamp', ...
        'rear-left tail/brake lamp', 'rear-right tail/brake lamp', 'rear-center tail/brake lamp', 'front-left fog lamp'}
    assert(any(strcmp(fitNames, expectedName{1})), 'The Fit has a %s', expectedName{1});
end
assert(numel(fitFaceUnit) == size(fitMesh.Faces,1));
close(figureHandle);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _______        _
%  |__   __|      | |
%     | | ___  ___| |_ ___
%     | |/ _ \/ __| __/ __|
%     | |  __/\__ \ |_\__ \
%     |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% TEST case: units, their names and order, from the made-up mesh
figNum = 20001;
titleString = sprintf('TEST case: units, names and order');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
[units, faceUnit] = fcn_CarMesh3D_lampUnits(testMesh);
expectedNames = {'front-left headlamp'; 'front-left marker lamp'; 'front-right headlamp'; ...
    'rear-left tail/brake lamp'; 'rear-center tail/brake lamp'; 'rear-right tail/brake lamp'; 'rear-right tail/brake lamp 2'};
assert(isequal({units.Name}', expectedNames), 'Names and order:\n%s', strjoin({units.Name}, newline));
assert(strcmp(units(1).Kind, 'headlamp') && strcmp(units(1).KindLabel, 'headlamp') && strcmp(units(1).Position, 'front-left'));
% (each face belongs to the unit that lists it)
for ith_unit = 1:numel(units)
    assert(all(faceUnit(units(ith_unit).Faces) == ith_unit));
end
assert(all(faceUnit(testMesh.FaceLightType == 0 & testMesh.FaceCoverLamp == 0) == 0), 'Faces not lamps or covers: no unit');

%% TEST case: a scrap of a few faces next to a lamp joins it; a lamp far away is its own unit
figNum = 20002;
titleString = sprintf('TEST case: scraps join, far lamps do not');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
% (the front-left headlamp is two squares 1 cm apart: one unit; the rear
% right tail lamps are two squares 30 cm apart: two units, numbered)
headlampUnit = units(strcmp({units.Name}, 'front-left headlamp'));
assert(numel(headlampUnit.Faces) == 4, 'The headlamp and its scrap 1 cm away are one unit');
[unitsWideGap] = fcn_CarMesh3D_lampUnits(testMesh, Gap=0.5);
assert(~any(strcmp({unitsWideGap.Name}, 'rear-right tail/brake lamp 2')), 'With a 50 cm gap the two rear-right tail lamps join');
[unitsTightGap] = fcn_CarMesh3D_lampUnits(testMesh, Gap=0.001);
assert(any(strcmp({unitsTightGap.Name}, 'front-left headlamp 2')), 'With a 1 mm gap the scrap is a unit of its own');

%% TEST case: covers go to the nearest unit of their kind; a kind with no unit, to the nearest unit
figNum = 20003;
titleString = sprintf('TEST case: covers');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
headlampIndex = find(strcmp({units.Name}, 'front-left headlamp'));
markerIndex = find(strcmp({units.Name}, 'front-left marker lamp'));
coverOverHeadlamp = find(testMesh.FaceCoverLamp == find(strcmp(lampTypeNames, 'headlamp')));
coverOverHighBeam = find(testMesh.FaceCoverLamp == find(strcmp(lampTypeNames, 'highBeamLamp')));
assert(all(ismember(coverOverHeadlamp, units(headlampIndex).CoverFaces)), 'A headlamp cover belongs to the headlamp');
assert(all(ismember(coverOverHighBeam, [units(headlampIndex).CoverFaces; units(markerIndex).CoverFaces])), ...
    'A high-beam cover (no high-beam unit) belongs to the nearest unit');
[unitsNoCover] = fcn_CarMesh3D_lampUnits(testMesh, MaxCoverDistance=1e-4);
assert(all(cellfun(@isempty, {unitsNoCover.CoverFaces})), 'Covers farther than MaxCoverDistance belong to none');

%% TEST case: a mesh with no lamps
figNum = 20004;
titleString = sprintf('TEST case: no lamps');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
noLamps = testMesh;
noLamps.FaceLightType(:) = 0;
noLamps.FaceCoverLamp(:) = 0;
[noUnits, noFaceUnit] = fcn_CarMesh3D_lampUnits(noLamps);
assert(isempty(noUnits) && all(noFaceUnit == 0));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ______        _     __  __           _        _______        _
%  |  ____|      | |   |  \/  |         | |      |__   __|      | |
%  | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
%  |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
%  | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
%  |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty fig_num\n',figNum);
figuresBefore = findall(groot, 'Type', 'figure');
fastUnits = fcn_CarMesh3D_lampUnits(testMesh, FigNum=[]);
assert(isequal({fastUnits.Name}, {units.Name}));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, fig_num=-1\n',figNum);
fastUnits = fcn_CarMesh3D_lampUnits(testMesh, FigNum=-1);
assert(isequal({fastUnits.Name}, {units.Name}));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 10;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_lampUnits(fitMesh, FigNum=[]);
end
slowMethod = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_lampUnits(fitMesh, FigNum=-1);
end
fastMethod = toc;
fprintf(1,'The Fit, %.0f calls: normal %.3f s, fast %.3f s\n', Niterations, slowMethod, fastMethod);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

%% BUG case: lamp type names in a row (as in plotLabels' test mesh) failed with "Array dimensions ... must match"
figNum = 90001;
fprintf(1,'Figure %.0f: BUG case: lamp type names in a row\n', figNum);
rowNames = testMesh;
rowNames.LightTypeNames = reshape(cellstr(rowNames.LightTypeNames), 1, []);
rowUnits = fcn_CarMesh3D_lampUnits(rowNames, FigNum=-1);
columnUnits = fcn_CarMesh3D_lampUnits(testMesh, FigNum=-1);
assert(isequal({rowUnits.Name}, {columnUnits.Name}) && isequal({rowUnits.Kind}, {columnUnits.Kind}));

%% Fail conditions
if 1==0
    %% Not a labeled mesh
    fcn_CarMesh3D_lampUnits(struct('Vertices', rand(3,3), 'Faces', [1 2 3]));
    %% A gap that is not positive
    fcn_CarMesh3D_lampUnits(testMesh, Gap=0);
end


%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_lampMesh
function testMesh = fcn_INTERNAL_lampMesh(lampTypeNames)
% A box-shaped stand-in for a vehicle (its body two triangles on the floor
% and roof) with lamps: small squares, 4 cm across, of two triangles each.
%   front-left:  a headlamp, a scrap of it 1 cm away, a marker lamp, a
%                cover over the headlamp, a high-beam cover over it too
%   front-right: a headlamp
%   rear:        tail/brake lamps left and right, a high brake lamp in the
%                middle, and a second rear-right tail lamp 30 cm away
vertices = [0 -0.8 0; 4 -0.8 0; 4 0.8 0; 0 0.8 0; 0 -0.8 1.4; 4 -0.8 1.4; 4 0.8 1.4; 0 0.8 1.4];
faces = [1 2 3; 1 3 4; 5 7 6; 5 8 7];
faceType = [0; 0; 0; 0];
faceCover = [0; 0; 0; 0];
% (each square: its center, the lamp kind it is, the kind it covers; and
% its half-size across, in y)
squares = { ...
    [4 0.60 0.70], 'headlamp', '', 0.02; ...
    [4 0.65 0.70], 'headlamp', '', 0.02; ...      % (the scrap: 1 cm from the headlamp's edge)
    [4 0.75 0.85], 'markerLamp', '', 0.02; ...
    [4.005 0.60 0.70], '', 'headlamp', 0.02; ...  % (a cover 5 mm in front of the headlamp)
    [4.005 0.62 0.74], '', 'highBeamLamp', 0.02; ...   % (a cover over a kind with no unit)
    [4 -0.60 0.70], 'headlamp', '', 0.02; ...
    [0 0.60 0.80], 'tailBrakeLamp', '', 0.02; ...
    [0 -0.60 0.80], 'tailBrakeLamp', '', 0.02; ...
    [0 -0.60 0.40], 'tailBrakeLamp', '', 0.02; ...          % (30 cm below: a second rear-right tail lamp)
    [0 0 1.32], 'tailBrakeLamp', '', 0.10};                 % (the high brake lamp, across the middle)
for ith_square = 1:size(squares,1)
    center = squares{ith_square,1};
    halfY = squares{ith_square,4};
    corners = center + [0 -halfY -0.02; 0 halfY -0.02; 0 halfY 0.02; 0 -halfY 0.02];
    first = size(vertices,1);
    vertices = [vertices; corners]; %#ok<AGROW>
    faces = [faces; first + [1 2 3]; first + [1 3 4]]; %#ok<AGROW>
    typeIndex = 0;
    coverIndex = 0;
    if ~isempty(squares{ith_square,2})
        typeIndex = find(strcmp(lampTypeNames, squares{ith_square,2}));
    end
    if ~isempty(squares{ith_square,3})
        coverIndex = find(strcmp(lampTypeNames, squares{ith_square,3}));
    end
    faceType = [faceType; typeIndex; typeIndex]; %#ok<AGROW>
    faceCover = [faceCover; coverIndex; coverIndex]; %#ok<AGROW>
end
testMesh = struct('Vertices', vertices, 'Faces', faces, 'FaceLightType', faceType, ...
    'LightTypeNames', {lampTypeNames}, 'FaceCoverLamp', faceCover);
end % Ends fcn_INTERNAL_lampMesh
