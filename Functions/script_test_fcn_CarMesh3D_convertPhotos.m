% script_test_fcn_CarMesh3D_convertPhotos
% Tests of fcn_CarMesh3D_convertPhotos, always on copies in a temporary
% folder (never on a vehicle's own photos).
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_convertPhotos
%   % * First write: the Transit Connect's mixed photo pile (Sean, 14:09:
%   %   % JPEG and WebP from very different sources, uneven angles, and two
%   %   % photos at 180 degrees, where the better resolution must win)

%% Set up the workspace
close all;
transitFiles = fcn_CarMesh3D_findVehicleFiles('2014_Ford_TransitConnect_XLTCargoLWB', FigNum=-1);
transitPhotos = fullfile(transitFiles.Folder, 'photos');
flagTransitPile = isfolder(transitPhotos) && ~isempty(dir(fullfile(transitPhotos, 'ViewInDegrees_*.webp')));
testRoot = tempname;
mkdir(testRoot);
cleanupTestRoot = onCleanup(@() rmdir(testRoot, 's'));
transitBefore = dir(transitPhotos);   % (the real folder must not change)

%% DEMO case: the Transit Connect's photo pile, on a copy
fig_num = 10001;
fprintf(1,'Figure %d: DEMO case: the Transit Connect''s mixed photo pile, on a copy\n', fig_num);
if flagTransitPile
    pileFolder = fullfile(testRoot, 'transit');
    copyfile(transitPhotos, pileFolder);
    listingBefore = dir(pileFolder);
    listingBefore = listingBefore(~[listingBefore.isdir]);
    namesBefore = {listingBefore.name};
    viewNames = namesBefore(~cellfun(@isempty, regexpi(namesBefore, '^ViewInDegrees_\d{3}\.\w+$')));
    anglesBefore = unique(cellfun(@(n) str2double(n(15:17)), viewNames));
    otherNames = setdiff(namesBefore, viewNames);

    lastwarn('');
    report = fcn_CarMesh3D_convertPhotos(pileFolder, FigNum=fig_num);
    [warningText, warningID] = lastwarn;
    assert(ishandle(fig_num), 'The contact sheet was drawn');
    if ~isempty(otherNames)
        assert(strcmp(warningID, 'CarMesh3D:photosSkipped') && all(cellfun(@(n) contains(warningText, n), otherNames)), ...
            'The files not named ViewInDegrees_<angle> are skipped, and named in a warning');
    end
    % (one standard JPEG per angle, and nothing else the viewer would list)
    jpegsAfter = dir(fullfile(pileFolder, 'ViewInDegrees_*.jpg'));
    viewerListed = [jpegsAfter; dir(fullfile(pileFolder, 'ViewInDegrees_*.jpeg')); dir(fullfile(pileFolder, 'ViewInDegrees_*.png'))];
    anglesAfter = cellfun(@(n) str2double(n(15:17)), {jpegsAfter.name});
    assert(isequal(sort(anglesAfter), anglesBefore), 'Every angle has its standard .jpg');
    assert(numel(viewerListed) == numel(anglesBefore), 'Each angle is listed once by the viewer');
    for k = 1:numel(jpegsAfter)
        imfinfo(fullfile(pileFolder, jpegsAfter(k).name));   % (each one reads)
    end
    % (nothing deleted: every file is still here or in originals)
    for k = 1:numel(namesBefore)
        assert(isfile(fullfile(pileFolder, namesBefore{k})) || isfile(fullfile(pileFolder, 'originals', namesBefore{k})), ...
            'No file was deleted: %s', namesBefore{k});
    end
    % (the tie at 180 degrees: the photo with the most pixels won)
    rows180 = report(report.Angle == 180, :);
    if height(rows180) > 1
        [~, best] = max(rows180.Width .* rows180.Height);
        assert(startsWith(rows180.Action{best}, {'converted', 'kept'}), 'At 180 degrees the larger photo wins');
        info180 = imfinfo(fullfile(pileFolder, 'ViewInDegrees_180.jpg'));
        assert(info180.Width == rows180.Width(best) && info180.Height == rows180.Height(best), ...
            'The standard 180 degree photo has the winner''s size');
        fprintf(1, '  The tie at 180 degrees: %s won (%dx%d)\n', rows180.File{best}, rows180.Width(best), rows180.Height(best));
    end

    %% TEST case: a second run changes nothing (already made)
    fig_num = 20001;
    fprintf(1,'Figure %d: TEST case: a second run changes nothing\n', fig_num);
    stateBefore = dir(fullfile(pileFolder, '**', '*'));
    report2 = fcn_CarMesh3D_convertPhotos(pileFolder, Verbose=false, FigNum=-1);
    stateAfter = dir(fullfile(pileFolder, '**', '*'));
    assert(isequal({stateBefore.name}, {stateAfter.name}) && isequal([stateBefore.datenum], [stateAfter.datenum]), ...
        'A second run writes and moves nothing');
    assert(~any(startsWith(report2.Action, {'converted', 'replaced'})), 'A second run converts nothing');
else
    fprintf(1, '  (skipped: the Transit Connect''s photo pile is not here)\n');
end

%% TEST case: a made-up folder: PNG, ties, bad names, unsupported formats
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: PNG, ties, bad names, unsupported formats\n', fig_num);
madeFolder = fullfile(testRoot, 'made');
mkdir(madeFolder);
small = uint8(repmat(reshape([200 50 50], 1, 1, 3), 40, 60));
large = uint8(repmat(reshape([50 200 50], 1, 1, 3), 80, 120));
imwrite(small, fullfile(madeFolder, 'ViewInDegrees_010.jpg'));    % (a smaller JPEG ...)
imwrite(large, fullfile(madeFolder, 'ViewInDegrees_010.png'));    % (... loses to a larger PNG)
imwrite(large, fullfile(madeFolder, 'ViewInDegrees_030.png'));    % (a PNG alone)
imwrite(large, fullfile(madeFolder, 'ViewInDegrees_040.jpg'));    % (already the standard)
imwrite(small, fullfile(madeFolder, 'ViewInDegrees_45.jpg'));     % (two digits: skipped)
imwrite(small, fullfile(madeFolder, 'ViewInDegrees_400.jpg'));    % (over 359: skipped)
fid = fopen(fullfile(madeFolder, 'ViewInDegrees_020.xyz'), 'w'); fwrite(fid, 1); fclose(fid);   % (unsupported)
imwrite(small, fullfile(madeFolder, 'RearBumper.jpg'));           % (another name: skipped)

% (a dry run first: nothing changes)
stateBefore = dir(fullfile(madeFolder, '**', '*'));
reportDry = fcn_CarMesh3D_convertPhotos(madeFolder, DryRun=true, Verbose=false, FigNum=[]);
stateAfter = dir(fullfile(madeFolder, '**', '*'));
assert(isequal({stateBefore.name}, {stateAfter.name}) && isequal([stateBefore.datenum], [stateAfter.datenum]), 'A dry run changes nothing');
assert(all(startsWith(reportDry.Action, '(dry run)')), 'A dry run says so');

lastwarn('');
reportMade = fcn_CarMesh3D_convertPhotos(madeFolder, Verbose=false, FigNum=[]);
[warningText, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:photosSkipped') && contains(warningText, 'ViewInDegrees_45.jpg') && ...
    contains(warningText, 'ViewInDegrees_400.jpg') && contains(warningText, 'ViewInDegrees_020.xyz') && contains(warningText, 'RearBumper.jpg'), ...
    'The bad names and the unsupported format are named in the warning');
info010 = imfinfo(fullfile(madeFolder, 'ViewInDegrees_010.jpg'));
assert(info010.Width == 120 && contains(strjoin(cellstr(info010.Comment)), 'from ViewInDegrees_010.png'), ...
    'At 010 the larger PNG won, and the JPEG names its source');
assert(isfile(fullfile(madeFolder, 'originals', 'ViewInDegrees_010.jpg')) && isfile(fullfile(madeFolder, 'originals', 'ViewInDegrees_010.png')), ...
    'The losing JPEG and the converted PNG were moved to originals, not deleted');
assert(isfile(fullfile(madeFolder, 'ViewInDegrees_030.jpg')) && ~isfile(fullfile(madeFolder, 'ViewInDegrees_030.png')) && ...
    isfile(fullfile(madeFolder, 'originals', 'ViewInDegrees_030.png')), 'A PNG alone is converted, and moved aside');
assert(startsWith(reportMade.Action{strcmp(reportMade.File, 'ViewInDegrees_040.jpg')}, 'kept'), 'A standard JPEG is kept as it is');

% (a second run: the JPEGs made from the PNGs, now in originals, are kept)
stateBefore = dir(fullfile(madeFolder, '**', '*'));
fcn_CarMesh3D_convertPhotos(madeFolder, Verbose=false, FigNum=-1);
stateAfter = dir(fullfile(madeFolder, '**', '*'));
assert(isequal([stateBefore.datenum], [stateAfter.datenum]), 'The second run changes nothing here either');

%% TEST case: a vehicle ID instead of a folder (dry run on the real folder)
fig_num = 20003;
fprintf(1,'Figure %d: TEST case: a vehicle ID, dry run\n', fig_num);
if flagTransitPile
    reportID = fcn_CarMesh3D_convertPhotos('2014_Ford_TransitConnect_XLTCargoLWB', DryRun=true, Verbose=false, FigNum=-1);
    assert(height(reportID) == numel(transitBefore(~[transitBefore.isdir])), 'The vehicle''s own photos folder is used');
end

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases\n', fig_num);
tic; fcn_CarMesh3D_convertPhotos(madeFolder, Verbose=false, FigNum=[]); slowTime = toc;
tic; fcn_CarMesh3D_convertPhotos(madeFolder, FigNum=-1); fastTime = toc;
fprintf(1, '  normal %.3f s, fast mode %.3f s\n', slowTime, fastTime);
assert(isempty(findall(0, 'Type', 'figure', 'Number', fig_num)), 'Fast mode makes no plot');

% (the real Transit folder was never changed)
transitAfter = dir(transitPhotos);
assert(isequal({transitBefore.name}, {transitAfter.name}) && isequal([transitBefore.datenum], [transitAfter.datenum]), ...
    'The vehicle''s own photos were not changed');
close all;
clear cleanupTestRoot
fprintf(1, 'All tests of fcn_CarMesh3D_convertPhotos passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: no such folder
    fcn_CarMesh3D_convertPhotos('C:\no\such\folder');
end
