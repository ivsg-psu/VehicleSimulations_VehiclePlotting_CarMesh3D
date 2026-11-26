% script_test_fcn_CarMesh3D_lampTypes.m
% Tests fcn_CarMesh3D_lampTypes, and that the lamp types it lists work in
% the functions that use them (editLabels, plotVehicle)
%
% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampTypes
%   % * First write of the test script (Sean, task 8)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampTypes
%   % * The lamps light by the lamp-to-function matrix's defaults: markers
%   %   % with the running and tail lights, a warning lamp with no signal
%   %   % (drafted with Claude)

%% Set up the workspace
close all;

%% The list: eleven types, the first six in the order older meshes use
lampTypes = fcn_CarMesh3D_lampTypes();
names = {lampTypes.Name};
assert(isequal(names(1:6), {'headlight','turnsignal','running','tail','backup','highbeam'}), ...
    'The first six types keep their order (older meshes store types by number)');
assert(isequal(names(7:11), {'fog','reflector','licenseplate','marker','warning'}), 'The five newer types');
for thisType = lampTypes'
    assert(~isempty(thisType.Label) && isequal(size(thisType.FaceColor), [1 3]) && isequal(size(thisType.LabelColor), [1 3]), ...
        'Each type has a label and colors: %s', thisType.Name);
    assert(~isempty(regexp(thisType.Name, thisType.NameRule, 'once')) || strcmp(thisType.Name, 'headlight') ...
        || strcmp(thisType.Name, 'licenseplate'), 'Each name rule matches its own name: %s', thisType.Name);
end
assert(numel(unique([lampTypes.RuleOrder])) == numel(lampTypes), 'Each name rule has its own place in the order');
assert(isfield(lampTypes, 'Sources') && all(cellfun(@iscell, {lampTypes.Sources})), 'Each type has a Sources list (Sean, 23:24)');
assert(contains(lampTypes(strcmp(names,'licenseplate')).Sources{1}, 'https://'), 'Sources are links');
labelColors = vertcat(lampTypes.LabelColor);
assert(size(unique(labelColors, 'rows'), 1) == numel(lampTypes), 'Each type has its own label color');
switching = struct('fog', {{'FogLights'}}, 'reflector', {{'Reflectors'}}, 'licenseplate', {{'Tail'}}, ...
    'marker', {{'Running'}}, 'warning', {{'Hazards'}});
for typeName = fieldnames(switching)'
    assert(isequal(lampTypes(strcmp(names, typeName{1})).SwitchedByStates, switching.(typeName{1})), ...
        'The default switching of %s (Sean, Q24 (A), Q25 (A))', typeName{1});
end

%% The newer types in a mesh: labeled, and lit by their states
% (the GUI test vehicle, which has every older lamp type: give five of
% its turn-signal faces each a newer type)
testFiles = fcn_CarMesh3D_findVehicleFiles('2026_CarMesh3D_Sample_GUITestVehicle');
loaded = load(testFiles.MeshFile, 'vehicleMesh');
vehicleMesh = loaded.vehicleMesh;
lightFaces = find(vehicleMesh.FaceLightType == find(strcmp(vehicleMesh.LightTypeNames, 'turnsignal'), 1));
assert(numel(lightFaces) >= 5, 'The test vehicle has turn-signal faces to label');
newTypes = {'fog','reflector','licenseplate','marker','warning'};
edits = cell(1, numel(newTypes));
for ith_type = 1:numel(newTypes)
    edits{ith_type} = struct('FaceIndices', lightFaces(ith_type), 'LightType', newTypes{ith_type});
end
labeledMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);
for ith_type = 1:numel(newTypes)
    typeIndex = find(strcmp(labeledMesh.LightTypeNames, newTypes{ith_type}));
    assert(isscalar(typeIndex) && labeledMesh.FaceLightType(lightFaces(ith_type)) == typeIndex, ...
        'editLabels labels a face %s', newTypes{ith_type});
end

figure(20001); clf; set(gcf, 'Visible', 'off');
plotHandles = fcn_CarMesh3D_plotVehicle(labeledMesh, FigNum=20001);
for ith_type = 1:numel(newTypes)
    assert(isfield(plotHandles.LightPatches, newTypes{ith_type}) && ~isempty(plotHandles.LightPatches.(newTypes{ith_type})), ...
        'plotVehicle makes a switchable patch for %s', newTypes{ith_type});
end
% (each state lights its lamps, and only those, as the lamp-to-function
% matrix's defaults say: the marker lamps light with the running lights
% and the tail lights; a warning lamp (beacon) answers no signal by
% default, it is switched by the user's own loop)
checks = {struct('FogLights', true), {'fog'};
          struct('Reflectors', 1), {'reflector'};
          struct('Tail', 'on'), {'licenseplate','marker'};
          struct('Running', true), {'marker'};
          struct('Hazards', true), {}};
for ith_check = 1:size(checks,1)
    fcn_CarMesh3D_plotVehicle(labeledMesh, PlotHandles=plotHandles, LightStates=checks{ith_check,1});
    for ith_type = 1:numel(newTypes)
        thisPatch = plotHandles.LightPatches.(newTypes{ith_type});
        flagLit = strcmp(thisPatch(1).FaceLighting, 'none');
        assert(flagLit == any(strcmp(newTypes{ith_type}, checks{ith_check,2})), ...
            'With %s, the %s lamp is %s', strjoin(fieldnames(checks{ith_check,1})', ','), newTypes{ith_type}, ...
            char(string(flagLit)));
    end
end
% (Hazards also lights both turn signals)
fcn_CarMesh3D_plotVehicle(labeledMesh, PlotHandles=plotHandles, LightStates=struct('Hazards', true));
for turnName = {'turnLeft','turnRight'}
    if ~isempty(plotHandles.LightPatches.(turnName{1}))
        assert(strcmp(plotHandles.LightPatches.(turnName{1})(1).FaceLighting, 'none'), 'Hazards lights %s', turnName{1});
    end
end
% (the reflector glows in its own color, as bright as the outside light)
reflectorPatch = plotHandles.LightPatches.reflector(1);
reflectorUnit = plotHandles.LightGroupNames{find(strcmp(plotHandles.GroupKindNames, 'reflector'), 1)};   % (lamps are drawn by unit)
offColor = plotHandles.LightOffColors.(reflectorUnit){1}(1,:);
fcn_CarMesh3D_plotVehicle(labeledMesh, PlotHandles=plotHandles, LightStates=struct('Reflectors', 0.5));
halfColor = reflectorPatch.FaceVertexCData(1,:);
fcn_CarMesh3D_plotVehicle(labeledMesh, PlotHandles=plotHandles, LightStates=struct('Reflectors', 1));
fullColor = reflectorPatch.FaceVertexCData(1,:);
assert(all(halfColor >= offColor - 1e-9) && all(fullColor >= halfColor - 1e-9) && max(fullColor) > max(offColor), ...
    'The reflector brightens with the outside light');
[~, hueOff] = max(offColor);
[~, hueFull] = max(fullColor);
assert(hueOff == hueFull, 'The reflector keeps its own hue');

%% A vehicle's own switching replaces the default (Sean, 23:23)
ownMesh = labeledMesh;
ownMesh.LampSwitching = struct('fog', {{'HighBeam'}});
plotHandles2 = fcn_CarMesh3D_plotVehicle(ownMesh, FigNum=20001);
fcn_CarMesh3D_plotVehicle(ownMesh, PlotHandles=plotHandles2, LightStates=struct('FogLights', true));
assert(strcmp(plotHandles2.LightPatches.fog(1).FaceLighting, 'gouraud') || ~strcmp(plotHandles2.LightPatches.fog(1).FaceLighting, 'none'), ...
    'This vehicle''s fog lamps do not follow FogLights');
fcn_CarMesh3D_plotVehicle(ownMesh, PlotHandles=plotHandles2, LightStates=struct('Headlights', 'high'));
assert(strcmp(plotHandles2.LightPatches.fog(1).FaceLighting, 'none'), 'This vehicle''s fog lamps light with the high beams');
close(20001);

%% Name rules: a light named for a newer type gets it (labelParts)
assert(~isempty(regexpi('Fog_Lamp_L', lampTypes(strcmp(names,'fog')).NameRule, 'once')));
assert(~isempty(regexpi('rear_reflector', lampTypes(strcmp(names,'reflector')).NameRule, 'once')));
assert(~isempty(regexpi('LicensePlateLight', lampTypes(strcmp(names,'licenseplate')).NameRule, 'once')));
assert(~isempty(regexpi('side_marker', lampTypes(strcmp(names,'marker')).NameRule, 'once')));

%% Fast mode
lampTypesFast = fcn_CarMesh3D_lampTypes(FigNum=-1);
assert(isequal(lampTypesFast, lampTypes));

assert(isempty(timerfindall), 'No timers are left running');
fprintf(1, 'All tests of fcn_CarMesh3D_lampTypes passed.\n');
