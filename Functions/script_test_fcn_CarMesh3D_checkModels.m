% script_test_fcn_CarMesh3D_checkModels.m
% Tests fcn_CarMesh3D_checkModels
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_checkModels
%   % * First write of the test script

%% Set up the workspace: a small made-up Data folder
close all;
testData = tempname;    % (a folder of its own, so the tests touch nothing else)
cleanupTestData = onCleanup(@() rmdir(testData, 's')); %#ok<NASGU>
madeUp = {
    % ID,                       style,      modelFile line,                                     download?, raw mesh?
    '2001_Test_HasBoth',        'Sedan',    'modelFile = fullfile(''model'',''car.glb'');',      true,  true
    '2002_Test_RawOnly',        'Sedan',    'modelFile = fullfile(''model'',''car.glb'');',      false, true
    '2003_Test_Neither',        'Coupe',    'modelFile = ''car one.glb'';   % (a comment)',      false, false
    '2004_Test_BodyStyle',      'Coupe',    'modelFile = '''';   % (no model: the body style)',  false, false
    };
for k = 1:size(madeUp,1)
    folder = fullfile(testData, 'BodyStyles', madeUp{k,2}, madeUp{k,1});
    mkdir(folder);
    writelines({'% a made-up vehicle script'; ''; madeUp{k,3}; 'bodyStyle = '''';'}, ...
        fullfile(folder, sprintf('script_CarMesh3D_vehicle_%s.m', madeUp{k,1})));
    if madeUp{k,4}
        mkdir(fullfile(folder, 'model'));
        writelines("not a real model", fullfile(folder, 'model', 'car.glb'));
    end
    if madeUp{k,5}
        rawMesh = struct('Vertices', zeros(3), 'Faces', [1 2 3]); %#ok<NASGU>
        save(fullfile(folder, sprintf('rawMesh_%s.mat', madeUp{k,1})), 'rawMesh');
    end
end
writelines("% the template", fullfile(testData, 'script_CarMesh3D_vehicle_TEMPLATE.m'));

%% Basic case: one row per vehicle, the template left out
fig_num = 10001;
report = fcn_CarMesh3D_checkModels(DataFolder=testData, FigNum=fig_num);
assert(istable(report));
assert(height(report) == 4);
assert(~any(strcmp(report.ID, 'TEMPLATE')));
row = @(id) report(strcmp(report.ID, id), :);
assert(row('2001_Test_HasBoth').HasDownload && row('2001_Test_HasBoth').HasRawMesh && row('2001_Test_HasBoth').CanBuild);
assert(~row('2002_Test_RawOnly').HasDownload && row('2002_Test_RawOnly').HasRawMesh && row('2002_Test_RawOnly').CanBuild);
assert(~row('2003_Test_Neither').CanBuild);
assert(strcmp(row('2003_Test_Neither').ModelFile{1}, 'car one.glb'));
assert(strcmp(row('2002_Test_RawOnly').ModelFile{1}, fullfile('model','car.glb')));
assert(isempty(row('2004_Test_BodyStyle').ModelFile{1}) && row('2004_Test_BodyStyle').CanBuild);

%% Some vehicles only, in the order given; and the copy commands printed
% (a made-up large-file area holding the 2003's download, not the 2002's)
fig_num = 10002;
largeData = fullfile(testData, 'largeFileArea', 'Data');
mkdir(fullfile(largeData, 'BodyStyles', 'Coupe', '2003_Test_Neither'));
writelines("not a real model", fullfile(largeData, 'BodyStyles', 'Coupe', '2003_Test_Neither', 'car one.glb'));
someIDs = {'2003_Test_Neither', '2002_Test_RawOnly', '2001_Test_HasBoth'};
printed = evalc('report = fcn_CarMesh3D_checkModels(Vehicles=someIDs, LargeFileFolder=[largeData filesep], DataFolder=testData, FigNum=fig_num);');
assert(isequal(report.ID', someIDs));
assert(isequal(report.InLargeFileFolder', [true false false]));
assert(contains(printed, sprintf('rclone copy "%s" "%s"', largeData, testData)));
assert(contains(printed, fullfile(largeData, 'BodyStyles', 'Coupe', '2003_Test_Neither', 'model')));
assert(~contains(printed, fullfile('2001_Test_HasBoth', 'model')));
assert(contains(printed, 'NO: needs its download'));
assert(contains(printed, 'In the large-file area?'));

%% The library itself: every vehicle's script can run
fig_num = 10003;
libraryReport = fcn_CarMesh3D_checkModels(FigNum=fig_num);
assert(height(libraryReport) > 0);
assert(any(strcmp(libraryReport.ID, fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1))));   % (the repo's demo vehicle is in the library)
sampleRow = libraryReport(strcmp(libraryReport.ID, '2026_CarMesh3D_Sample_GenericSedan'), :);
assert(isempty(sampleRow) || (isempty(sampleRow.ModelFile{1}) && sampleRow.CanBuild));   % (the built-in sample car)

%% Fast mode: nothing printed
fig_num = -1;
printed = evalc('report = fcn_CarMesh3D_checkModels(DataFolder=testData, FigNum=fig_num);');
assert(isempty(printed));
assert(height(report) == 4);

%% Errors
% A vehicle with no script
try
    fcn_CarMesh3D_checkModels(Vehicles={'1900_No_Such_Car'}, DataFolder=testData);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:noVehicle'), ME.message);
end
% A large-file folder that is not there
try
    fcn_CarMesh3D_checkModels(LargeFileFolder=fullfile(testData, 'none'), DataFolder=testData);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:noFolder'), ME.message);
end
% A Data folder that is not there
try
    fcn_CarMesh3D_checkModels(DataFolder=fullfile(testData, 'none'));
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:noFolder'), ME.message);
end
% Vehicles not a cell array of IDs
try
    fcn_CarMesh3D_checkModels(Vehicles={3});
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end

fprintf(1, 'All tests of fcn_CarMesh3D_checkModels passed.\n');
