function report = fcn_CarMesh3D_checkModels(options)
% fcn_CarMesh3D_checkModels
% Lists, for each vehicle in the library, whether its downloaded model is
% on this computer and whether its imported mesh (rawMesh_<ID>.mat) is.
% The downloads are large, so they are not kept in the git repository:
% they are kept in the IVSG large-file storage area (a OneDrive folder)
% and copied into each vehicle's model\ folder (see README.md, "Large
% files"). A
% vehicle's script runs with either one: from the download, or, without
% it, from its imported mesh, which is in the repository.
%
% FORMAT:
%
%       report = fcn_CarMesh3D_checkModels(...
%           (Vehicles=vehicleIDs), (LargeFileFolder=folder),
%           (DataFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs, in any order. Any
%      option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Vehicles: a cell array of vehicle IDs to check, such as
%      {'2009_Honda_Fit_Sport'}. Default: {} (every vehicle with a
%      script).
%
%      LargeFileFolder: the large-file area's CarMesh3D Data folder, as
%      it is found on this computer (the OneDrive folder is mounted at a
%      different place on each computer). If given, the copy commands for
%      the missing downloads are printed with it, and each missing
%      download is looked for there. Default: '' (the commands are
%      printed with <LargeFileFolder> in its place).
%
%      DataFolder: the repository's Data folder. Default: the Data folder
%      next to this function's Functions folder.
%
%      FigNum: if given (and not -1), the list is printed. If set to -1,
%      input checking is skipped (fast mode) and nothing is printed.
%
% OUTPUTS:
%
%      report: a table, one row per vehicle, with the columns
%           ID: the vehicle ID
%           Folder: the vehicle's folder
%           ModelFile: the script's modelFile ('' for a vehicle made
%               from its body style, or the built-in sample car, which
%               need no download)
%           HasDownload: true if the model file is on this computer
%           HasRawMesh: true if rawMesh_<ID>.mat is in the folder
%           CanBuild: true if the script can run (a download, an
%               imported mesh, or no download needed)
%           InLargeFileFolder: true if the download is in
%               LargeFileFolder (false when no LargeFileFolder is given)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       % Which vehicles are missing their downloads?
%       report = fcn_CarMesh3D_checkModels(FigNum=1);
%
%       % Print the commands that copy them in from the large-file area
%       fcn_CarMesh3D_checkModels(LargeFileFolder='D:\OneDrive\IVSG\CarMesh3D\Data', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_checkModels.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkModels
%   % * First write of the code: the downloads are moved out of git (into
%   %   % each vehicle's model\ folder, copied from the IVSG large-file
%   %   % area with rclone); this lists which ones are here, and prints
%   %   % the rclone commands for the rest (Sean, 19:14)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkModels
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Vehicles = {}       % Vehicle IDs to check; {} for all
    options.LargeFileFolder = ''   % The large-file area's Data folder, on this computer
    options.DataFolder = ''     % The repository's Data folder; '' for the default
    options.FigNum = []         % Print the list if given; -1 for fast mode
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
    debug_figNum = 999978; %#ok<NASGU>
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
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the Vehicles input
        if ischar(options.Vehicles) || isstring(options.Vehicles)
            options.Vehicles = cellstr(options.Vehicles);
        end
        if ~iscell(options.Vehicles) || ~all(cellfun(@(x) ischar(x) || (isstring(x) && isscalar(x)), options.Vehicles))
            error('CarMesh3D:badInput', 'Vehicles must be a cell array of vehicle IDs, such as {''2009_Honda_Fit_Sport''}.');
        end

        % Check the LargeFileFolder and DataFolder inputs
        if ~(ischar(options.LargeFileFolder) || (isstring(options.LargeFileFolder) && isscalar(options.LargeFileFolder)))
            error('CarMesh3D:badInput', 'LargeFileFolder must be a folder name (text).');
        end
        if ~isempty(char(options.LargeFileFolder)) && ~isfolder(char(options.LargeFileFolder))
            error('CarMesh3D:noFolder', 'The large-file folder was not found: %s', char(options.LargeFileFolder));
        end
        if ~(ischar(options.DataFolder) || (isstring(options.DataFolder) && isscalar(options.DataFolder)))
            error('CarMesh3D:badInput', 'DataFolder must be a folder name (text).');
        end
    end
end

% Print the list?
flag_do_plots = 0; % Default is to NOT print
if (0==flag_max_speed)
    if ~isempty(options.FigNum)
        flag_do_plots = 1;
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

% The Data folder
dataFolder = char(options.DataFolder);
if isempty(dataFolder)
    dataFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Data');
end
if ~isfolder(dataFolder)
    error('CarMesh3D:noFolder', 'The Data folder was not found: %s', dataFolder);
end

% Every vehicle script (the template, at the top of Data, is left out)
scripts = dir(fullfile(dataFolder, '**', 'script_CarMesh3D_vehicle_*.m'));
scripts = scripts(~strcmpi({scripts.folder}, dataFolder));
scriptIDs = erase(erase({scripts.name}, 'script_CarMesh3D_vehicle_'), '.m');
if ~isempty(options.Vehicles)
    wanted = cellfun(@char, options.Vehicles, 'UniformOutput', false);
    unknown = setdiff(wanted, scriptIDs, 'stable');
    if ~isempty(unknown)
        error('CarMesh3D:noVehicle', 'No script was found for: %s', strjoin(unknown, ', '));
    end
    [~, order] = ismember(wanted, scriptIDs);
    scripts = scripts(order);
    scriptIDs = scriptIDs(order);
end

% Each vehicle: its model file, and which files are here
numVehicles = numel(scripts);
ID = scriptIDs(:);
Folder = {scripts.folder}';
ModelFile = repmat({''}, numVehicles, 1);
HasDownload = false(numVehicles, 1);
HasRawMesh = false(numVehicles, 1);
for k = 1:numVehicles
    ModelFile{k} = fcn_INTERNAL_modelFile(fullfile(scripts(k).folder, scripts(k).name));
    % (the download in the vehicle's folder, or in its folder in LargeData,
    % beside Data in the same layout: Sean, 2026-11-24)
    repoFolder = fileparts(dataFolder);
    largeDataFolder = fullfile(repoFolder, 'LargeData', erase(Folder{k}, [repoFolder filesep]));
    HasDownload(k) = ~isempty(ModelFile{k}) && (isfile(fullfile(Folder{k}, ModelFile{k})) || isfile(fullfile(largeDataFolder, ModelFile{k})));
    HasRawMesh(k) = isfile(fullfile(Folder{k}, sprintf('rawMesh_%s.mat', ID{k})));
end
CanBuild = HasDownload | HasRawMesh | cellfun(@isempty, ModelFile);

% Each missing download, looked for in the large-file folder (the same
% place under its Data folder as the vehicle's under this one)
largeFolder = regexprep(char(options.LargeFileFolder), '[\\/]+$', '');
InLargeFileFolder = false(numVehicles, 1);
if ~isempty(largeFolder)
    for k = 1:numVehicles
        if ~isempty(ModelFile{k})
            relativeFolder = erase(Folder{k}, [dataFolder filesep]);
            InLargeFileFolder(k) = isfile(fullfile(largeFolder, relativeFolder, ModelFile{k}));
        end
    end
end
report = table(ID, Folder, ModelFile, HasDownload, HasRawMesh, CanBuild, InLargeFileFolder);

%% Any debugging?
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
    needsDownload = ~cellfun(@isempty, ModelFile);
    missing = needsDownload & ~HasDownload;
    fprintf(1, '\nDownloaded models: %d of %d vehicles have theirs here', sum(HasDownload), sum(needsDownload));
    fprintf(1, ' (%d more are made from their body style and need none)\n', sum(~needsDownload));
    if any(missing)
        largeText = '';
        if ~isempty(largeFolder)
            largeText = 'In the large-file area?';
        end
        fprintf(1, '\n%-45s %-9s %-24s %s\n', 'Missing its download', 'Raw mesh', 'Can its script run?', largeText);
        for k = find(missing)'
            canText = 'yes, from its raw mesh';
            if ~HasRawMesh(k)
                canText = 'NO: needs its download';
            end
            largeText = '';
            if ~isempty(largeFolder)
                largeText = fcn_INTERNAL_yesNo(InLargeFileFolder(k));
            end
            fprintf(1, '%-45s %-9s %-24s %s\n', ID{k}, fcn_INTERNAL_yesNo(HasRawMesh(k)), canText, largeText);
        end

        % The copy commands (rclone takes local folders, such as a
        % mounted OneDrive folder, as well as remotes)
        source = largeFolder;
        if isempty(source)
            source = '<LargeFileFolder>';
        end
        fprintf(1, '\nTo copy every download in (the whole Data folder of the large-file area):\n');
        fprintf(1, '    rclone copy "%s" "%s" --progress\n', source, dataFolder);
        fprintf(1, '\nOr one vehicle at a time:\n');
        for k = find(missing)'
            relativeFolder = erase(Folder{k}, [dataFolder filesep]);
            fprintf(1, '    rclone copy "%s" "%s" --progress\n', fullfile(source, relativeFolder, 'model'), fullfile(Folder{k}, 'model'));
        end
        if isempty(largeFolder)
            fprintf(1, '(give LargeFileFolder= the large-file area''s Data folder, as it is found on this computer)\n');
        end
    else
        fprintf(1, 'Every download is here.\n');
    end
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_modelFile
function modelFile = fcn_INTERNAL_modelFile(scriptPath)
% The script's modelFile setting, read from its text (not run): a quoted
% name, or fullfile of quoted names. '' for a vehicle made from its body
% style.
scriptText = fileread(scriptPath);
setting = regexp(scriptText, '(?m)^modelFile\s*=\s*([^;\r\n]*);', 'tokens', 'once');
modelFile = '';
if isempty(setting)
    return
end
parts = regexp(setting{1}, '''((?:[^'']|'''')*)''', 'tokens');
parts = cellfun(@(x) strrep(x{1}, '''''', ''''), parts, 'UniformOutput', false);
parts = parts(~cellfun(@isempty, parts));
if ~isempty(parts)
    modelFile = fullfile(parts{:});
end
% ('sample': the built-in sample car, made by its script, needs no file)
if strcmpi(modelFile, 'sample')
    modelFile = '';
end
end % Ends fcn_INTERNAL_modelFile

%% fcn_INTERNAL_yesNo
function text = fcn_INTERNAL_yesNo(flag)
if flag
    text = 'yes';
else
    text = 'no';
end
end % Ends fcn_INTERNAL_yesNo
