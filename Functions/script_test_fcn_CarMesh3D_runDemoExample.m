% script_test_fcn_CarMesh3D_runDemoExample.m
% Tests fcn_CarMesh3D_runDemoExample
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_runDemoExample
%   % * First write of the test script
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_runDemoExample
%   % * The mesh editor is two examples (GUI test vehicle, demo vehicle)

%% Set up the workspace
close all;
testVehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle)

%% The list of examples
examples = fcn_CarMesh3D_runDemoExample('examples', VehicleID=testVehicleID);
expectedNames = {'library','viewer','sharedView','editorTest','editor','reviewer','animate','history','list','browse'};
assert(isequal({examples.Name}, expectedNames));
for ith_example = 1:numel(examples)
    assert(~isempty(examples(ith_example).Title) && ~isempty(examples(ith_example).DemoCommands) ...
        && ~isempty(examples(ith_example).VehicleCommands));
end

%% Each example's echo: the demo copy's commands, then the vehicle's
for ith_example = 1:numel(examples)
    [~, echoText] = fcn_CarMesh3D_runDemoExample(examples(ith_example).Name, VehicleID=testVehicleID, FlagRun=false);
    assert(contains(echoText, 'DEMO COPY') && contains(echoText, 'ACTUAL vehicle'));
    demoPart = extractBefore(echoText, 'ACTUAL vehicle');
    for ith_line = 1:numel(examples(ith_example).DemoCommands)
        assert(contains(demoPart, examples(ith_example).DemoCommands{ith_line}));
    end
    if examples(ith_example).SavesChanges
        assert(contains(echoText, 'changes ARE saved'));
    end
    % (every command must at least parse)
    for commandSet = {examples(ith_example).DemoCommands, examples(ith_example).VehicleCommands}
        codeText = strjoin(commandSet{1}, newline);
        tree = mtree(codeText);
        assert(~any(strcmp(tree.kinds, 'ERR')), 'Example %s does not parse:\n%s', examples(ith_example).Name, codeText);
    end
end

%% The last example's commands, again
[~, echoText] = fcn_CarMesh3D_runDemoExample('reviewer', VehicleID=testVehicleID, FlagRun=false);
[~, lastText] = fcn_CarMesh3D_runDemoExample('last');
assert(strcmp(echoText, lastText));

%% The warning
[~, warningText] = fcn_CarMesh3D_runDemoExample('warning', VehicleID=testVehicleID);
assert(contains(warningText, 'NOT in the vehicle'));

%% Running examples that open no window: in the base workspace
evalin('base', 'clear history vehicleList demoFiles');
fcn_CarMesh3D_runDemoExample('list', VehicleID=testVehicleID);
assert(evalin('base', 'exist(''vehicleList'',''var'')') == 1);
fcn_CarMesh3D_runDemoExample('history', VehicleID=testVehicleID);
demoFiles = evalin('base', 'demoFiles');
assert(strcmpi(demoFiles.Folder, fullfile(tempdir, 'CarMesh3D_demo', testVehicleID)));
assert(evalin('base', 'isstruct(history) && isfield(history, ''FinePrint'')'));

%% Fast mode: nothing printed
printed = evalc('fcn_CarMesh3D_runDemoExample(''viewer'', VehicleID=testVehicleID, FlagRun=false, FigNum=-1);');
assert(isempty(strtrim(printed)));

%% Printed in color with DebugTools (headings with % and \ printed as is)
if exist('fcn_DebugTools_cprintf', 'file') == 2
    printed = evalc('fcn_CarMesh3D_runDemoExample(''reviewer'', VehicleID=testVehicleID, FlagRun=false);');
    assert(contains(printed, 'Commands used here') && contains(printed, 'ACTUAL vehicle'));
    assert(contains(printed, 'fcn_CarMesh3D_reviewVehicle(demoFiles.Folder);'));
end

%% Errors
try
    fcn_CarMesh3D_runDemoExample('noSuchExample');
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end

fprintf(1, 'All tests of fcn_CarMesh3D_runDemoExample passed.\n');
