function history = fcn_CarMesh3D_meshHistory(vehicleInput, options)
% fcn_CarMesh3D_meshHistory

% A vehicle mesh's history: who changed it and when (its change log), the
% license of the model it was made from, when it was last built, and
% whether it has been reviewed by a person since it was made (and by
% whom, when, and the decision). Meshes are made by the vehicle's script
% (automatically); a person's review is what says they are fit to use.
%
% The change log is a file in the vehicle's folder,
% meshHistory_<ID>.csv: one row per change (Time, Who, Action, Details),
% newest last, plain text so it reads well in a git diff. The painter
% (fcn_CarMesh3D_paintLabels) adds a row each time label edits are saved;
% the Model Reviewer (fcn_CarMesh3D_reviewVehicle) adds one for each
% overall decision. The build comes from the mesh file's BuildInfo, which
% the vehicle's script saves with the mesh.
%
% FORMAT:
%
%       history = fcn_CarMesh3D_meshHistory(vehicleInput,...
%           (Action=action), (Details=details), (Who=name), (Mesh=mesh),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), a mesh file
%      name (vehicleMesh_<ID>.mat, or a timestamped copy of it,
%      vehicleMesh_<ID>_YYYYMMDDHHMMSS.mat), or a vehicle folder. The
%      history and license are looked for in the file's folder, then in
%      the vehicle's own folder.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Action: a change to add to the log, for example 'label edits
%      saved', 'reviewed: approved', 'reviewed: rejected', 'built', or
%      'note'. '' (default): only read.
%
%      Details: more about the change (text). Default ''.
%
%      Who: who made the change. Default: the computer's user name.
%
%      Mesh: the mesh, if already loaded (its BuildInfo gives the build);
%      [] (default) to read it from the mesh file.
%
%      FigNum: not used (no plot); [] or -1 (fast mode: no input checks).
%
% OUTPUTS:
%
%      history: a structure:
%           ID, Folder, HistoryFile
%           Entries: a table (Time, Who, Action, Details), oldest first,
%               with the build (from BuildInfo) put in its place
%           License: Name, Author, Source, Text (from LICENSE.txt; '' if
%               none)
%           Built: Date, Script, MeshVersion ('' if not known)
%           LastChange: Time, Who, Action (the newest entry)
%           Review: Status ('not reviewed', 'approved', 'rejected'), By,
%               Date, Current (false when the mesh changed after it)
%           FinePrint: one line for the bottom of a viewer
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       history = fcn_CarMesh3D_meshHistory('2009_Honda_Fit_Sport');
%       disp(history.FinePrint)
%       fcn_CarMesh3D_meshHistory('2009_Honda_Fit_Sport', Action='note', Details='looked at the mirrors');
%
%       See the script: script_test_fcn_CarMesh3D_meshHistory.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshHistory
%   % * First write (Sean, 13:07): a change log with each mesh (who, when),
%   %   % whether an automatically made mesh has been reviewed (by whom,
%   %   % when), and the license, for the viewer's fine print

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshHistory
%   % * The vehicle script to add a 'built' row itself (the template, once
%   %   % the batch of 2026_11_22 is done); until then the build comes from
%   %   % BuildInfo



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Action = ''     % A change to add to the log; '' to only read
    options.Details = ''    % More about the change
    options.Who = ''        % Who made it; '' for the computer's user name
    options.Mesh = []       % The mesh, if loaded (its BuildInfo); [] to read the mesh file
    options.FigNum = []     % Not used; -1 for fast mode
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
if 0==flag_max_speed
    if flag_check_inputs
        if ~(ischar(vehicleInput) || isstring(vehicleInput)) || strlength(vehicleInput) == 0
            error('vehicleInput must be a vehicle ID, a mesh file name, or a vehicle folder');
        end
        for name = {'Action', 'Details', 'Who'}
            if ~(ischar(options.(name{1})) || isstring(options.(name{1})))
                error('%s must be text', name{1});
            end
        end
    end
end

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

%%%% Where: the vehicle's ID, its folder, its mesh file
[vehicleID, folders, meshFile] = fcn_INTERNAL_where(char(vehicleInput));
historyFolder = folders{1};
for ith_folder = 1:numel(folders)
    if isfile(fullfile(folders{ith_folder}, sprintf('meshHistory_%s.csv', vehicleID)))
        historyFolder = folders{ith_folder};
        break;
    end
end
historyFile = fullfile(historyFolder, sprintf('meshHistory_%s.csv', vehicleID));

%%%% The change log, and a new row
entries = fcn_INTERNAL_readLog(historyFile);
if strlength(string(options.Action)) > 0
    who = char(options.Who);
    if isempty(who)
        who = fcn_INTERNAL_userName();
    end
    newRow = table(string(char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'))), string(who), ...
        string(options.Action), string(options.Details), 'VariableNames', {'Time', 'Who', 'Action', 'Details'});
    entries = [entries; newRow];
    if ~isfolder(historyFolder)
        mkdir(historyFolder);
    end
    writetable(entries, historyFile, 'QuoteStrings', 'all');
end

%%%% The license
license = struct('Name', '', 'Author', '', 'Source', '', 'Text', '');
for ith_folder = 1:numel(folders)
    for candidate = {fullfile(folders{ith_folder}, 'LICENSE.txt'), fullfile(folders{ith_folder}, 'model', 'LICENSE.txt')}
        if isfile(candidate{1}) && isempty(license.Text)
            license = fcn_INTERNAL_readLicense(candidate{1});
        end
    end
end

%%%% The build (from the mesh's BuildInfo)
built = struct('Date', '', 'Script', '', 'MeshVersion', '');
vehicleMesh = options.Mesh;
if isempty(vehicleMesh) && ~isempty(meshFile) && isfile(meshFile)
    try
        loaded = load(meshFile, 'vehicleMesh');
        vehicleMesh = loaded.vehicleMesh;
    catch
    end
end
if isstruct(vehicleMesh) && isfield(vehicleMesh, 'BuildInfo') && isstruct(vehicleMesh.BuildInfo)
    buildInfo = vehicleMesh.BuildInfo;
    built.Date = fcn_INTERNAL_field(buildInfo, 'Date');
    built.Script = fcn_INTERNAL_field(buildInfo, 'Script');
    built.MeshVersion = fcn_INTERNAL_field(buildInfo, 'MeshVersion');
end

%%%% All the changes, oldest first: the log, and the build in its place
allEntries = entries;
if ~isempty(built.Date) && ~any(allEntries.Action == "built" & startsWith(allEntries.Time, built.Date))
    buildRow = table(string(built.Date), "script", "built", ...
        string(sprintf('by %s (mesh version %s)', built.Script, built.MeshVersion)), ...
        'VariableNames', {'Time', 'Who', 'Action', 'Details'});
    allEntries = [allEntries; buildRow];
end
[~, order] = sort(fcn_INTERNAL_times(allEntries.Time));
allEntries = allEntries(order,:);

%%%% The review: the newest decision, and whether the mesh changed after it
review = struct('Status', 'not reviewed', 'By', '', 'Date', '', 'Current', false);
flagReview = startsWith(allEntries.Action, "reviewed");
if any(flagReview)
    lastReview = find(flagReview, 1, 'last');
    review.Status = char(strtrim(extractAfter(allEntries.Action(lastReview), "reviewed:")));
    if isempty(review.Status)
        review.Status = 'reviewed';
    end
    review.By = char(allEntries.Who(lastReview));
    review.Date = char(allEntries.Time(lastReview));
    flagChange = ~startsWith(allEntries.Action, "reviewed") & allEntries.Action ~= "note";
    review.Current = ~any(flagChange((lastReview+1):end));
end

lastChange = struct('Time', '', 'Who', '', 'Action', '');
flagChange = ~startsWith(allEntries.Action, "reviewed") & allEntries.Action ~= "note";
if any(flagChange)
    newest = find(flagChange, 1, 'last');
    lastChange = struct('Time', char(allEntries.Time(newest)), 'Who', char(allEntries.Who(newest)), ...
        'Action', char(allEntries.Action(newest)));
end

history = struct('ID', vehicleID, 'Folder', historyFolder, 'HistoryFile', historyFile, 'Entries', allEntries, ...
    'License', license, 'Built', built, 'LastChange', lastChange, 'Review', review, 'FinePrint', '');
history.FinePrint = fcn_INTERNAL_finePrint(history);

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_where
function [vehicleID, folders, meshFile] = fcn_INTERNAL_where(inputText)
% The vehicle's ID, the folders to look in (the given one first, then the
% vehicle's own), and its mesh file
meshFile = '';
folders = {};
if isfolder(inputText)
    [~, vehicleID] = fileparts(inputText);
    folders = {inputText};
    candidate = fullfile(inputText, sprintf('vehicleMesh_%s.mat', vehicleID));
    if isfile(candidate)
        meshFile = candidate;
    end
elseif endsWith(inputText, '.mat', 'IgnoreCase', true)
    meshFile = inputText;
    [folder, name] = fileparts(inputText);
    vehicleID = regexprep(regexprep(name, '^vehicleMesh_', ''), '_\d{14}$', '');   % (a timestamped copy: the vehicle's ID)
    folders = {folder};
else
    vehicleID = inputText;
end
try
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
    if vehicleFiles.Found && ~any(strcmpi(folders, vehicleFiles.Folder))
        folders{end+1} = vehicleFiles.Folder;
    end
    if isempty(meshFile)
        meshFile = vehicleFiles.MeshFile;
    end
catch
end
if isempty(folders)
    folders = {pwd};
end
end % Ends fcn_INTERNAL_where

%% fcn_INTERNAL_readLog
function entries = fcn_INTERNAL_readLog(historyFile)
% The change log as a table of strings (empty when there is none yet)
entries = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), 'VariableNames', {'Time', 'Who', 'Action', 'Details'});
if ~isfile(historyFile)
    return;
end
importOptions = delimitedTextImportOptions('NumVariables', 4, 'VariableNames', {'Time', 'Who', 'Action', 'Details'}, ...
    'VariableTypes', repmat({'string'}, 1, 4), 'DataLines', [2 Inf], 'Delimiter', ',');
importOptions = setvaropts(importOptions, {'Time', 'Who', 'Action', 'Details'}, 'QuoteRule', 'remove', 'FillValue', "");
loaded = readtable(historyFile, importOptions);
loaded.Details(ismissing(loaded.Details)) = "";
entries = [entries; loaded];
end % Ends fcn_INTERNAL_readLog

%% fcn_INTERNAL_readLicense
function license = fcn_INTERNAL_readLicense(licenseFile)
% The license name, author and source from a LICENSE.txt ("License: ...",
% "Author: ...", "Source website: ..." lines)
text = fileread(licenseFile);
license = struct('Name', fcn_INTERNAL_line(text, 'License'), 'Author', fcn_INTERNAL_line(text, 'Author'), ...
    'Source', fcn_INTERNAL_line(text, 'Source website'), 'Text', text);
if isempty(license.Name)
    firstLine = strtrim(extractBefore(string(text) + newline, newline));
    license.Name = char(firstLine);
end
end % Ends fcn_INTERNAL_readLicense

function value = fcn_INTERNAL_line(text, name)
token = regexp(text, ['(?im)^\s*' regexptranslate('escape', name) '\s*:\s*(.*?)\s*$'], 'tokens', 'once');
value = '';
if ~isempty(token)
    value = token{1};
end
end % Ends fcn_INTERNAL_line

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(thisStruct, name)
value = '';
if isfield(thisStruct, name) && ~isempty(thisStruct.(name))
    value = char(string(thisStruct.(name)));
end
end % Ends fcn_INTERNAL_field

%% fcn_INTERNAL_times
function numbers = fcn_INTERNAL_times(times)
% Times as numbers, for sorting ('yyyy-MM-dd HH:mm' or with seconds)
numbers = zeros(numel(times),1);
for ith_time = 1:numel(times)
    try
        numbers(ith_time) = datenum(char(times(ith_time)), 'yyyy-mm-dd HH:MM:SS'); %#ok<DATNM>
    catch
        try
            numbers(ith_time) = datenum(char(times(ith_time)), 'yyyy-mm-dd HH:MM'); %#ok<DATNM>
        catch
            numbers(ith_time) = 0;
        end
    end
end
end % Ends fcn_INTERNAL_times

%% fcn_INTERNAL_userName
function name = fcn_INTERNAL_userName()
name = getenv('USERNAME');
if isempty(name)
    name = getenv('USER');
end
if isempty(name)
    name = 'unknown';
end
end % Ends fcn_INTERNAL_userName

%% fcn_INTERNAL_finePrint
function textOut = fcn_INTERNAL_finePrint(history)
% One line: the license, the build, the last change, and the review
parts = {};
if ~isempty(history.License.Name)
    licenseText = sprintf('License: %s', history.License.Name);
    if ~isempty(history.License.Author)
        licenseText = sprintf('%s, model by %s', licenseText, history.License.Author);
    end
    if ~isempty(history.License.Source)
        licenseText = sprintf('%s (%s)', licenseText, history.License.Source);
    end
    parts{end+1} = licenseText;
else
    parts{end+1} = 'License: not recorded';
end
if ~isempty(history.Built.Date)
    parts{end+1} = sprintf('Built automatically %s (mesh %s)', history.Built.Date, history.Built.MeshVersion);
end
if ~isempty(history.LastChange.Time) && ~strcmp(history.LastChange.Action, 'built')
    parts{end+1} = sprintf('Last change: %s by %s, %s', history.LastChange.Action, history.LastChange.Who, history.LastChange.Time);
end
switch history.Review.Status
    case 'not reviewed'
        parts{end+1} = 'NOT REVIEWED by a person';
    otherwise
        reviewText = sprintf('Reviewed (%s) by %s, %s', history.Review.Status, history.Review.By, history.Review.Date);
        if ~history.Review.Current
            reviewText = [reviewText ', CHANGED SINCE'];
        end
        parts{end+1} = reviewText;
end
textOut = strjoin(parts, '   |   ');
end % Ends fcn_INTERNAL_finePrint
