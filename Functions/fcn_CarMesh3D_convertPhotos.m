function report = fcn_CarMesh3D_convertPhotos(photoFolder, options)
% fcn_CarMesh3D_convertPhotos
% Brings a folder of vehicle photos to the CarMesh3D standard: one JPEG
% per view angle, named ViewInDegrees_<angle>.jpg (angle in degrees, three
% digits, 000 to 359), which is what the viewer, the label painter and the
% reviewer read. Written for students' photo uploads (Sean, 2026-11-24
% 14:09), which come in many formats from many sources.
%
% What it does, angle by angle:
%   * Finds every file named ViewInDegrees_<angle>.<extension>. Any other
%     file (FrontHood.webp, a misspelled name, an angle not 000 to 359) is
%     skipped, and listed in a warning.
%   * Reads the format: JPEG is the standard already; PNG, BMP, TIFF, GIF,
%     HEIC/HEIF are read by MATLAB; WebP and AVIF (which MATLAB cannot
%     read) are decoded by Windows' own image codecs (WIC, through
%     PowerShell). Any other format is skipped with a warning.
%   * TIES: when an angle has more than one photo (ViewInDegrees_180.jpg
%     and ViewInDegrees_180.webp), the one with the most pixels wins. On
%     equal pixels a JPEG wins (no second compression), then the larger
%     file. Losing photos that the viewer would also list (.jpg, .jpeg,
%     .png) are moved to an "originals" subfolder, so each angle is shown
%     once; other losing files (.webp, .avif ...) stay where they are. No
%     file is ever deleted.
%   * ALREADY DONE: a JPEG this function made carries a comment naming its
%     source and that source's size. When that source is still the winner,
%     the angle is skipped, even though the JPEG's file is smaller than its
%     source (JPEG compression): files are compared by pixels and by the
%     comment, never by bytes alone. A JPEG converted earlier by hand (with
%     no comment) and its same-size source: the JPEG wins the tie, so it is
%     kept, not made again.
%
% FORMAT:
%
%       report = fcn_CarMesh3D_convertPhotos(photoFolder, ...
%           (FlagDryRun=flag), (Quality=q), (FlagVerbose=flag), (FigNum=figNum))
%
% INPUTS:
%
%      photoFolder: the folder of photos (a vehicle's "photos" folder), or
%      a vehicle ID (then that vehicle's photos folder is used).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagDryRun: true to only report what would be done (nothing is
%      written or moved). Default false.
%
%      Quality: the JPEG quality, 1 to 100. Default 95.
%
%      FlagVerbose: true (default) to print what was done, angle by angle.
%
%      FigNum: a figure for a contact sheet of the photos after the run,
%      one per angle, labeled. If empty or omitted, no plot is made. If
%      -1, input checking is skipped, nothing is printed and no plot is
%      made (fast mode); the warnings are still given.
%
% OUTPUTS:
%
%      report: a table, one row per file looked at: File, Angle (NaN when
%      not a ViewInDegrees name), Format, Width, Height, Action (what was
%      done, in words), and Output (the standard JPEG for that angle).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles (only when given a vehicle ID).
%      WebP and AVIF need Windows with its WebP and AV1 (AVIF) image
%      extensions, which come with Windows 10 and 11; elsewhere, convert
%      those by hand to .jpg first.
%
% EXAMPLES:
%
%       report = fcn_CarMesh3D_convertPhotos('2014_Ford_TransitConnect_XLTCargoLWB', FlagDryRun=true);
%       report = fcn_CarMesh3D_convertPhotos(photoFolder, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_convertPhotos.m for a
%       full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertPhotos
%   % * First write of the code (Sean, 14:09): the Transit Connect's
%   %   % mixed photo pile (JPEG and WebP, uneven angles, two photos at 180
%   %   % degrees) as the test case

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertPhotos
%   % * EXIF orientation (phone photos taken sideways) is not applied

% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    photoFolder
    options.FlagDryRun = false        % true: report only, change nothing
    options.Quality = 95          % JPEG quality, 1 to 100
    options.FlagVerbose = true        % print what was done
    options.FigNum = []           % Figure to plot into; [] for no plot, -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999976; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
photoFolder = char(photoFolder);
if ~isfolder(photoFolder) && ~isempty(regexp(photoFolder, '^\d{4}_[A-Za-z0-9]+_[A-Za-z0-9]+_[A-Za-z0-9]+$', 'once'))
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(photoFolder, FigNum=-1);
    photoFolder = fullfile(vehicleFiles.Folder, 'photos');
end
if 0==flag_max_speed
    if flag_check_inputs
        if ~isfolder(photoFolder)
            error('CarMesh3D:noFolder', 'The photo folder was not found: %s', photoFolder);
        end
        if ~isscalar(options.Quality) || ~isnumeric(options.Quality) || options.Quality < 1 || options.Quality > 100
            error('CarMesh3D:badInput', 'Quality must be a number from 1 to 100.');
        end
    end
end

% Make the plot?
flag_do_plots = 0; % Default is to NOT plot
if (0==flag_max_speed) && ~isempty(options.FigNum)
    flag_do_plots = 1;
end
flagPrint = logical(options.FlagVerbose) && (0==flag_max_speed);

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
commentTag = 'CarMesh3D convertPhotos';   % (marks a JPEG this function made)
matlabFormats = {'png','bmp','tif','tiff','gif','heic','heif'};
windowsFormats = {'webp','avif'};
viewerFormats = {'jpg','jpeg','png'};   % (what the viewer lists: a loser of these is moved aside)

listing = dir(photoFolder);
listing = listing(~[listing.isdir]);
numFiles = numel(listing);
File = {listing.name}';
Angle = nan(numFiles, 1);
Format = repmat({''}, numFiles, 1);
Width = nan(numFiles, 1);
Height = nan(numFiles, 1);
Action = repmat({''}, numFiles, 1);
Output = repmat({''}, numFiles, 1);
Kind = repmat({''}, numFiles, 1);        % 'jpeg', 'matlab', 'windows'
Bytes = [listing.bytes]';
CopySource = repmat({''}, numFiles, 1);  % (for a JPEG this function made: its source, and size)
CopySourceSize = nan(numFiles, 2);

% Which files are ViewInDegrees photos, in which formats
skippedNames = {};
for ith_file = 1:numFiles
    tokens = regexpi(File{ith_file}, '^ViewInDegrees_(\d+)\.([A-Za-z0-9]+)$', 'tokens', 'once');
    if isempty(tokens)
        Action{ith_file} = 'skipped: not named ViewInDegrees_<angle>.<extension>';
        skippedNames{end+1} = File{ith_file}; %#ok<AGROW>
        continue;
    end
    Format{ith_file} = lower(tokens{2});
    angleValue = str2double(tokens{1});
    if numel(tokens{1}) ~= 3 || angleValue > 359
        Action{ith_file} = 'skipped: the angle must be three digits, 000 to 359';
        skippedNames{end+1} = File{ith_file}; %#ok<AGROW>
        continue;
    end
    if ismember(Format{ith_file}, {'jpg','jpeg'})
        Kind{ith_file} = 'jpeg';
    elseif ismember(Format{ith_file}, matlabFormats)
        Kind{ith_file} = 'matlab';
    elseif ismember(Format{ith_file}, windowsFormats)
        Kind{ith_file} = 'windows';
    else
        Action{ith_file} = sprintf('skipped: the .%s format is not supported', Format{ith_file});
        skippedNames{end+1} = File{ith_file}; %#ok<AGROW>
        continue;
    end
    Angle(ith_file) = angleValue;
end

% WebP and AVIF: decoded by Windows (one PowerShell call for them all)
% into temporary PNG files
windowsFiles = find(strcmp(Kind, 'windows'));
decodedFile = repmat({''}, numFiles, 1);
tempFolder = tempname;
cleanupTemp = onCleanup(@() fcn_INTERNAL_removeFolder(tempFolder)); %#ok<NASGU>
if ~isempty(windowsFiles)
    mkdir(tempFolder);
    for ith = 1:numel(windowsFiles)
        decodedFile{windowsFiles(ith)} = fullfile(tempFolder, sprintf('decoded_%03d.png', ith));
    end
    ok = fcn_INTERNAL_windowsDecode(fullfile(photoFolder, File(windowsFiles)), decodedFile(windowsFiles), tempFolder);
    for ith = 1:numel(windowsFiles)
        if ~ok(ith)
            k = windowsFiles(ith);
            Action{k} = sprintf('skipped: Windows could not decode this .%s (convert it to .jpg by hand)', Format{k});
            skippedNames{end+1} = File{k}; %#ok<AGROW>
            Angle(k) = NaN;
            Kind{k} = '';
        end
    end
end

% Each photo's size, and (for a JPEG) whether this function made it
for ith_file = find(~isnan(Angle))'
    readFile = fullfile(photoFolder, File{ith_file});
    if strcmp(Kind{ith_file}, 'windows')
        readFile = decodedFile{ith_file};
    end
    try
        info = imfinfo(readFile);
        Width(ith_file) = info(1).Width;
        Height(ith_file) = info(1).Height;
        if strcmp(Kind{ith_file}, 'jpeg') && isfield(info, 'Comment') && ~isempty(info(1).Comment)
            commentText = strjoin(cellstr(info(1).Comment), ' ');
            sourceTokens = regexp(commentText, [commentTag ': from (\S+) \((\d+)x(\d+)\)'], 'tokens', 'once');
            if ~isempty(sourceTokens)
                CopySource{ith_file} = sourceTokens{1};
                CopySourceSize(ith_file, :) = [str2double(sourceTokens{2}), str2double(sourceTokens{3})];
            end
        end
    catch readError
        Action{ith_file} = sprintf('skipped: could not be read (%s)', readError.message);
        skippedNames{end+1} = File{ith_file}; %#ok<AGROW>
        Angle(ith_file) = NaN;
    end
end

% Angle by angle: the winner, then what to do
originalsFolder = fullfile(photoFolder, 'originals');
angles = unique(Angle(~isnan(Angle)))';
tieAngles = [];
for thisAngle = angles
    here = find(Angle == thisAngle);
    outputName = sprintf('ViewInDegrees_%03d.jpg', thisAngle);
    Output(here) = {outputName};
    % (a JPEG this function made is not a candidate itself: its source is)
    madeCopy = here(~cellfun(@isempty, CopySource(here)) & strcmpi(File(here), outputName));
    candidates = setdiff(here, madeCopy, 'stable');
    candidates = candidates(:);   % (a column, whatever setdiff returns)
    if isempty(candidates)
        Action(madeCopy) = {'kept: made earlier by this function (its source is gone)'};
        continue;
    end
    if numel(candidates) > 1
        tieAngles(end+1) = thisAngle; %#ok<AGROW>
    end
    % (most pixels; then a JPEG; then the larger file; then by name)
    pixels = Width(candidates).*Height(candidates);
    isJpeg = strcmp(Kind(candidates), 'jpeg');
    [~, order] = sortrows([-pixels, -double(isJpeg), -Bytes(candidates)]);
    winner = candidates(order(1));
    losers = candidates(order(2:end));
    winnerText = sprintf('%s (%dx%d)', File{winner}, Width(winner), Height(winner));

    if ~isempty(madeCopy) && strcmpi(CopySource{madeCopy}, File{winner}) && isequal(CopySourceSize(madeCopy,:), [Width(winner) Height(winner)])
        % Already done earlier: the JPEG made from this same winner
        Action{madeCopy} = sprintf('kept: made earlier from %s', winnerText);
        Action{winner} = sprintf('source of %s (already made earlier)', outputName);
    elseif strcmpi(File{winner}, outputName)
        % The winner is already the standard JPEG, by its own name
        Action{winner} = 'kept: already the standard (.jpg)';
    else
        % Convert (or copy) the winner to the standard name
        if ~isempty(madeCopy)
            Action{madeCopy} = sprintf('replaced: made earlier, now from %s', winnerText);
        end
        existingOriginal = losers(strcmpi(File(losers), outputName));
        if ~isempty(existingOriginal)
            % (a losing JPEG with the standard name: moved aside first, so
            % the new one can take its name)
            if ~options.FlagDryRun
                fcn_INTERNAL_moveAside(photoFolder, File{existingOriginal}, originalsFolder);
            end
            Action{existingOriginal} = sprintf('lost the tie to %s: moved to originals', winnerText);
        end
        if ~options.FlagDryRun
            fcn_INTERNAL_writeStandard(photoFolder, File{winner}, decodedFile{winner}, Kind{winner}, ...
                fullfile(photoFolder, outputName), options.Quality, ...
                sprintf('%s: from %s (%dx%d) on %s', commentTag, File{winner}, Width(winner), Height(winner), ...
                char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'))));
        end
        Action{winner} = sprintf('converted to %s', outputName);
        % (a source the viewer would also list is moved aside, so the angle is shown once)
        if ismember(Format{winner}, viewerFormats)
            if ~options.FlagDryRun
                fcn_INTERNAL_moveAside(photoFolder, File{winner}, originalsFolder);
            end
            Action{winner} = sprintf('converted to %s; this file moved to originals', outputName);
        end
    end
    for loser = reshape(losers, 1, [])
        if strcmp(Action{loser}, '')
            if ismember(Format{loser}, viewerFormats)
                if ~options.FlagDryRun && isfile(fullfile(photoFolder, File{loser}))
                    fcn_INTERNAL_moveAside(photoFolder, File{loser}, originalsFolder);
                end
                Action{loser} = sprintf('lost the tie to %s: moved to originals', winnerText);
            else
                Action{loser} = sprintf('lost the tie to %s: not used (left in place)', winnerText);
            end
        end
    end
end

report = table(File, Angle, Format, Width, Height, Action, Output);
if options.FlagDryRun
    report.Action = strcat({'(dry run) '}, report.Action);
end

% Tell the user what was skipped, and about ties
if ~isempty(skippedNames)
    warning('CarMesh3D:photosSkipped', ['%d file(s) in %s were skipped (not ViewInDegrees_<angle>.<extension> with a ' ...
        'supported format and an angle 000 to 359):\n    %s'], numel(skippedNames), photoFolder, strjoin(skippedNames, '\n    '));
end
if flagPrint
    fprintf(1, '\nfcn_CarMesh3D_convertPhotos: %s%s\n', photoFolder, fcn_INTERNAL_pick(options.FlagDryRun, '   (DRY RUN: nothing changed)', ''));
    fprintf(1, '  %d angles; %d with more than one photo (the most pixels wins)\n', numel(angles), numel(tieAngles));
    shown = report(~isnan(report.Angle), :);
    shown = sortrows(shown, {'Angle', 'File'});
    for k = 1:height(shown)
        fprintf(1, '  %03d  %-28s %5dx%-5d %s\n', shown.Angle(k), shown.File{k}, shown.Width(k), shown.Height(k), shown.Action{k});
    end
end

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    figureHandle = figure(options.FigNum);
    clf(figureHandle);
    jpegFiles = dir(fullfile(photoFolder, 'ViewInDegrees_*.jpg'));
    numPhotos = numel(jpegFiles);
    numColumns = max(1, ceil(sqrt(numPhotos*1.5)));
    numRows = max(1, ceil(numPhotos/numColumns));
    for k = 1:numPhotos
        axesHandle = subplot(numRows, numColumns, k, 'Parent', figureHandle);
        image(axesHandle, imread(fullfile(photoFolder, jpegFiles(k).name)));
        axis(axesHandle, 'image', 'off');
        title(axesHandle, strrep(erase(jpegFiles(k).name, '.jpg'), '_', '\_'), 'FontSize', 8);
    end
    sgtitle(figureHandle, sprintf('fcn\\_CarMesh3D\\_convertPhotos: %d standard photos', numPhotos));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_windowsDecode
function ok = fcn_INTERNAL_windowsDecode(sourceFiles, targetFiles, tempFolder)
% Decodes WebP and AVIF files to PNG with Windows' own image codecs (WIC),
% through one PowerShell call; ok(k) is true where the PNG was written
ok = false(numel(sourceFiles), 1);
if ~ispc
    return;
end
listFile = fullfile(tempFolder, 'decodeList.txt');
fid = fopen(listFile, 'w', 'n', 'UTF-8');
for k = 1:numel(sourceFiles)
    fprintf(fid, '%s|%s\n', sourceFiles{k}, targetFiles{k});
end
fclose(fid);
scriptFile = fullfile(tempFolder, 'decode.ps1');
scriptLines = {
    'param([string]$ListFile)'
    'Add-Type -AssemblyName PresentationCore'
    'foreach ($line in [IO.File]::ReadAllLines($ListFile)) {'
    '  $parts = $line.Split(''|'')'
    '  try {'
    '    $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create([Uri]$parts[0], [System.Windows.Media.Imaging.BitmapCreateOptions]::None, [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)'
    '    $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder'
    '    $encoder.Frames.Add($decoder.Frames[0])'
    '    $stream = [IO.File]::Create($parts[1])'
    '    $encoder.Save($stream)'
    '    $stream.Close()'
    '  } catch { }'
    '}'};
fid = fopen(scriptFile, 'w');
fprintf(fid, '%s\r\n', scriptLines{:});
fclose(fid);
system(sprintf('powershell -NoProfile -ExecutionPolicy Bypass -File "%s" -ListFile "%s"', scriptFile, listFile));
ok = cellfun(@isfile, targetFiles(:));
end % Ends fcn_INTERNAL_windowsDecode

%% fcn_INTERNAL_writeStandard
function fcn_INTERNAL_writeStandard(photoFolder, sourceName, decodedFile, kind, outputFile, quality, commentText)
% Writes one photo as the standard JPEG (RGB, 8 bits), with a comment
% naming its source
readFile = fullfile(photoFolder, sourceName);
if strcmp(kind, 'windows')
    readFile = decodedFile;
end
[imageData, colorMap] = imread(readFile);
if ~isempty(colorMap)
    imageData = ind2rgb(imageData, colorMap);
end
if size(imageData, 3) > 3
    imageData = imageData(:, :, 1:3);   % (CMYK or extra channels: the first three)
end
if ~isa(imageData, 'uint8')
    if islogical(imageData) || isfloat(imageData)
        imageData = uint8(255*double(imageData));
    else
        imageData = uint8(double(imageData)/double(intmax(class(imageData)))*255);
    end
end
if size(imageData, 3) == 1
    imageData = repmat(imageData, 1, 1, 3);
end
imwrite(imageData, outputFile, 'jpg', 'Quality', quality, 'Comment', commentText);
end % Ends fcn_INTERNAL_writeStandard

%% fcn_INTERNAL_moveAside
function fcn_INTERNAL_moveAside(photoFolder, fileName, originalsFolder)
% Moves a file into the originals subfolder (never deletes; a name
% already there gets a number)
if ~isfolder(originalsFolder)
    mkdir(originalsFolder);
end
[~, baseName, extension] = fileparts(fileName);
target = fullfile(originalsFolder, fileName);
counter = 1;
while isfile(target)
    counter = counter + 1;
    target = fullfile(originalsFolder, sprintf('%s_%d%s', baseName, counter, extension));
end
movefile(fullfile(photoFolder, fileName), target);
end % Ends fcn_INTERNAL_moveAside

%% fcn_INTERNAL_removeFolder
function fcn_INTERNAL_removeFolder(folderName)
% Removes the temporary folder of decoded pictures
if isfolder(folderName)
    rmdir(folderName, 's');
end
end % Ends fcn_INTERNAL_removeFolder

%% fcn_INTERNAL_pick
function value = fcn_INTERNAL_pick(flag, valueTrue, valueFalse)
if flag
    value = valueTrue;
else
    value = valueFalse;
end
end % Ends fcn_INTERNAL_pick
