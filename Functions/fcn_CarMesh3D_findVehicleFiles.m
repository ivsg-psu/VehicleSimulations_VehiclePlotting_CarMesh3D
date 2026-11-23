function vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, options)
% fcn_CarMesh3D_findVehicleFiles
% Returns the standard file and folder names for a vehicle stored in the
% Data folder, or lists every vehicle stored there. This function is the
% CarMesh3D naming convention, in code.
%
% WHERE VEHICLES ARE KEPT. Each vehicle has its own folder, found
% anywhere below Data (up to three levels down):
%
%       Data\BodyStyles\<Style>\<ID>\   a real vehicle, filed under its body
%                                      style (Sedan, Hatchback, Liftback, ...;
%                                      see fcn_CarMesh3D_loadBodyStyles)
%       Data\Samples\<ID>\              made-up vehicles (the sample car)
%       Data\<ID>\                       (older layout, still found)
%
% THE NAMING CONVENTION. The vehicle's folder is named
%
%       YEAR_Make_Model_Trimline        for example   2013_Toyota_Prius_Four
%                                                     2014_Ford_TransitConnect_XLTCargoLWB
%
% Underscores only separate the four parts. Each part is letters and
% digits only; several words are joined in CamelCase (Transit Connect is
% TransitConnect). The year has four digits. This name is the vehicle ID,
% and it must be used by only one folder. Inside the folder:
%
%       vehicleParameters_<ID>.mat     the IVSG vehicleParameters structure
%       script_CarMesh3D_vehicle_<ID>.m          the vehicle's script: builds the
%                                      mesh and runs the standard checks
%       vehicleMesh_<ID>.mat           the finished mesh (made by the script)
%       vehicleLevels_<ID>.mat         its detail levels, for animation
%                                      (made by the script; see
%                                      fcn_CarMesh3D_makeDetailLevels)
%       vehicleOutline_<ID>.mat        its top-down 2D outlines
%       model\                         the downloaded 3D model, its
%                                      LICENSE.txt, and converted files.
%                                      A download may instead be left
%                                      directly in the vehicle's folder.
%       checks\                        the standard check images and GIFs
%                                      (made by fcn_CarMesh3D_runVehicleChecks)
%
% Other files (for example, notes on where the parameters came from) may
% also be kept in the folder.
%
% FORMAT:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID,...
%           (BodyStyle=style), (DataFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleID: the vehicle ID, such as '2013_Toyota_Prius_Four', or ''
%      (empty) to list every vehicle folder below the Data folder. It may
%      also be the full path of a vehicle's folder kept anywhere (such as
%      a copy made by fcn_CarMesh3D_makeDemoCopy); the folder's name is
%      then the ID.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      BodyStyle: for a NEW vehicle (no folder yet), the body style it
%      will be filed under, such as 'sedan' or 'compactCargoVan': its
%      paths are then in Data\BodyStyles\<Style>\<ID>. Default '' puts a
%      new vehicle's paths in Data\<ID>. Ignored when the folder exists.
%
%      DataFolder: the Data folder. Default [] uses the Data folder next to
%      the Functions folder that holds this function.
%
%      FigNum: if given (and not -1), the vehicles are also printed as a
%      table in the command window. If set to -1, input checking is
%      skipped (fast mode).
%
% OUTPUTS:
%
%      vehicleFiles: a structure (or, when listing, a structure array, one
%      element per vehicle folder) with fields:
%           ID, Year (number), Make, Model, Trim, Name ('2013 Toyota Prius Four')
%           Folder, ParametersFile, ScriptFile, MeshFile, LevelsFile,
%           OutlineFile, ModelFolder, ChecksFolder: full paths, following
%           the convention above (ModelFolder is the vehicle's folder
%           itself when it has no model subfolder)
%           ModelFiles: the 3D model files found (glb, gltf, obj, stl,
%               ply, fbx, blend) in ModelFolder and its source subfolder,
%               as full paths in a cell array
%           BodyStyle: the style ID from the folder it is filed under,
%               such as 'sedan' ('' if not under Data\BodyStyles)
%           BodyStyleFolder: that folder's name, such as 'Sedan'
%           IsSample: true for a vehicle under Data\Samples
%           Found: true if the vehicle's folder exists
%           HasParameters, HasScript, HasMesh, HasLevels, HasOutline: true
%           if those files exist
%      For a new vehicle the paths are returned even if nothing exists yet.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
%       vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(priusFiles.ParametersFile);
%
%       allVehicles = fcn_CarMesh3D_findVehicleFiles('', FigNum=1);   % list them
%       sedans = allVehicles(strcmp({allVehicles.BodyStyle}, 'sedan'));
%
%       See the script: script_test_fcn_CarMesh3D_findVehicleFiles.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * The vehicle script is now script_CarMesh3D_vehicle_<ID>.m
%   %   % (was script_vehicle_<ID>.m), following the naming convention
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * Added LevelsFile and HasLevels (vehicleLevels_<ID>.mat, the
%   %   % detail levels made by fcn_CarMesh3D_makeDetailLevels)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * Added OutlineFile and HasOutline (vehicleOutline_<ID>.mat, the
%   %   % top-down outlines made by fcn_CarMesh3D_makeOutline2D)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * Vehicles are found anywhere below Data (Data\BodyStyles\<Style>\<ID>,
%   %   % Data\Samples\<ID>, or the older Data\<ID>); an ID used by two
%   %   % folders is an error
%   % * Added BodyStyle, BodyStyleFolder, IsSample, Found, and ModelFiles;
%   %   % a download left directly in the vehicle's folder is found
%   % * Added the BodyStyle option, for a new vehicle's paths
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * vehicleID may be the full path of a vehicle's folder kept anywhere
%   %   % (the demo's copy of a vehicle, so the demo saves nothing to the
%   %   % real vehicle)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_findVehicleFiles
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleID
    options.BodyStyle = ''    % A new vehicle's body style, such as 'sedan'; '' for Data\<ID>
    options.DataFolder = []   % The Data folder; [] for the one next to Functions
    options.FigNum = []       % Print a table if given; -1 for fast mode
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

        % Check the vehicleID input
        if ~(ischar(vehicleID) || isstring(vehicleID))
            error("vehicleID must be text, such as '2013_Toyota_Prius_Four', or empty to list all vehicles");
        end
        if ~isempty(char(vehicleID)) && ~fcn_INTERNAL_isValidID(char(vehicleID)) && ~fcn_INTERNAL_isFolderPath(vehicleID)
            error(['vehicleID %s does not follow YEAR_Make_Model_Trimline: four parts separated by ' ...
                'underscores, each made of letters and digits only, with a four-digit year ' ...
                '(for example 2014_Ford_TransitConnect_XLTCargoLWB)'], char(vehicleID));
        end

        % Check the BodyStyle input
        if ~((ischar(options.BodyStyle) || isstring(options.BodyStyle)) && ...
                (isempty(char(options.BodyStyle)) || ~isempty(regexp(char(options.BodyStyle), '^[A-Za-z][A-Za-z0-9]*$', 'once'))))
            error('BodyStyle must be a style ID such as ''sedan'' (letters and digits), or empty');
        end

        % Check the DataFolder input
        if ~isempty(options.DataFolder) && ~isfolder(options.DataFolder)
            error('DataFolder not found: %s', char(options.DataFolder));
        end
    end
end

% Does user want to print the list?
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

dataFolder = options.DataFolder;
if isempty(dataFolder)
    dataFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Data');
end
dataFolder = char(dataFolder);
vehicleID = char(vehicleID);

% Every vehicle folder below Data, with its ID
[folderPaths, folderIDs] = fcn_INTERNAL_findFolders(dataFolder);

if isempty(vehicleID)
    % List every vehicle folder (sorted by ID)
    [~, sortOrder] = sort(folderIDs);
    vehicleFiles = repmat(fcn_INTERNAL_filesForID('0000_A_B_C', fullfile(dataFolder,'0000_A_B_C'), dataFolder), 0, 1);
    for ith_folder = sortOrder(:)'
        vehicleFiles(end+1,1) = fcn_INTERNAL_filesForID(folderIDs{ith_folder}, folderPaths{ith_folder}, dataFolder); %#ok<AGROW>
    end
    repeatedIDs = unique(folderIDs(cellfun(@(id) sum(strcmp(folderIDs, id)) > 1, folderIDs)));
    if ~isempty(repeatedIDs)
        warning('CarMesh3D:repeatedID', 'These vehicle IDs are used by more than one folder: %s', strjoin(repeatedIDs, ', '));
    end
elseif fcn_INTERNAL_isFolderPath(vehicleID)
    % The full path of a vehicle's folder, kept anywhere
    vehicleFolder = char(java.io.File(vehicleID).getCanonicalPath());
    [~, folderID] = fileparts(vehicleFolder);
    if ~fcn_INTERNAL_isValidID(folderID)
        error('The folder %s is not named as a vehicle ID (YEAR_Make_Model_Trimline).', vehicleFolder);
    end
    vehicleFiles = fcn_INTERNAL_filesForID(folderID, vehicleFolder, dataFolder);
else
    matches = find(strcmp(folderIDs, vehicleID));
    if numel(matches) > 1
        error('The vehicle ID %s is used by more than one folder:\n%s', vehicleID, strjoin(folderPaths(matches), newline));
    elseif isscalar(matches)
        vehicleFolder = folderPaths{matches};
    elseif ~isempty(char(options.BodyStyle))
        styleFolder = char(options.BodyStyle);
        styleFolder(1) = upper(styleFolder(1));
        vehicleFolder = fullfile(dataFolder, 'BodyStyles', styleFolder, vehicleID);
    else
        vehicleFolder = fullfile(dataFolder, vehicleID);
    end
    vehicleFiles = fcn_INTERNAL_filesForID(vehicleID, vehicleFolder, dataFolder);
end

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
    fprintf(1,'\nVehicles in %s:\n', dataFolder);
    fprintf(1,'%-45s %-17s %-6s %-10s %-7s %-6s %-6s\n', 'ID', 'Style', 'Model', 'Parameters', 'Script', 'Mesh', 'Levels');
    yesNo = {'-','yes'};
    for ith_vehicle = 1:length(vehicleFiles)
        styleText = vehicleFiles(ith_vehicle).BodyStyle;
        if vehicleFiles(ith_vehicle).IsSample
            styleText = '(sample)';
        end
        fprintf(1,'%-45s %-17s %-6s %-10s %-7s %-6s %-6s\n', vehicleFiles(ith_vehicle).ID, styleText, ...
            yesNo{~isempty(vehicleFiles(ith_vehicle).ModelFiles)+1}, ...
            yesNo{vehicleFiles(ith_vehicle).HasParameters+1}, yesNo{vehicleFiles(ith_vehicle).HasScript+1}, ...
            yesNo{vehicleFiles(ith_vehicle).HasMesh+1}, yesNo{vehicleFiles(ith_vehicle).HasLevels+1});
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

%% fcn_INTERNAL_isValidID
function flagValid = fcn_INTERNAL_isValidID(vehicleID)
% YEAR_Make_Model_Trimline: a four-digit year, then three parts of
% letters and digits, separated by single underscores
flagValid = ~isempty(regexp(char(vehicleID), '^\d{4}_[A-Za-z0-9]+_[A-Za-z0-9]+_[A-Za-z0-9]+$', 'once'));
end % Ends fcn_INTERNAL_isValidID

%% fcn_INTERNAL_isFolderPath
function flagFolder = fcn_INTERNAL_isFolderPath(vehicleInput)
% A path (it has a folder separator) to a folder that exists
vehicleInput = char(vehicleInput);
flagFolder = any(vehicleInput == '\' | vehicleInput == '/') && isfolder(vehicleInput);
end % Ends fcn_INTERNAL_isFolderPath

%% fcn_INTERNAL_findFolders
function [folderPaths, folderIDs] = fcn_INTERNAL_findFolders(dataFolder)
% Every folder up to three levels below Data whose name is a vehicle ID.
% A vehicle's own folder is not searched further.
folderPaths = {};
folderIDs = {};
searchList = {dataFolder};
for ith_level = 1:3
    nextList = {};
    for ith_search = 1:numel(searchList)
        listing = dir(searchList{ith_search});
        listing = listing([listing.isdir] & ~ismember({listing.name}, {'.','..','model','checks','source','textures'}));
        for ith_entry = 1:numel(listing)
            thisPath = fullfile(searchList{ith_search}, listing(ith_entry).name);
            if fcn_INTERNAL_isValidID(listing(ith_entry).name)
                folderPaths{end+1} = thisPath; %#ok<AGROW>
                folderIDs{end+1} = listing(ith_entry).name; %#ok<AGROW>
            else
                nextList{end+1} = thisPath; %#ok<AGROW>
            end
        end
    end
    searchList = nextList;
end
end % Ends fcn_INTERNAL_findFolders

%% fcn_INTERNAL_filesForID
function vehicleFiles = fcn_INTERNAL_filesForID(vehicleID, vehicleFolder, dataFolder)
% The standard names for one vehicle ID, in its folder
parts = split(vehicleID, '_');
vehicleFiles = struct;
vehicleFiles.ID = vehicleID;
vehicleFiles.Year = str2double(parts{1});
vehicleFiles.Make = parts{2};
vehicleFiles.Model = parts{3};
vehicleFiles.Trim = parts{4};
vehicleFiles.Name = strjoin(parts', ' ');
vehicleFiles.Folder = vehicleFolder;
vehicleFiles.ParametersFile = fullfile(vehicleFiles.Folder, ['vehicleParameters_' vehicleID '.mat']);
vehicleFiles.ScriptFile = fullfile(vehicleFiles.Folder, ['script_CarMesh3D_vehicle_' vehicleID '.m']);
vehicleFiles.MeshFile = fullfile(vehicleFiles.Folder, ['vehicleMesh_' vehicleID '.mat']);
vehicleFiles.LevelsFile = fullfile(vehicleFiles.Folder, ['vehicleLevels_' vehicleID '.mat']);
vehicleFiles.OutlineFile = fullfile(vehicleFiles.Folder, ['vehicleOutline_' vehicleID '.mat']);
vehicleFiles.ModelFolder = fullfile(vehicleFiles.Folder, 'model');
if isfolder(vehicleFiles.Folder) && ~isfolder(vehicleFiles.ModelFolder)
    vehicleFiles.ModelFolder = vehicleFiles.Folder;     % (a download left in the vehicle's folder)
end
vehicleFiles.ChecksFolder = fullfile(vehicleFiles.Folder, 'checks');
vehicleFiles.ModelFiles = fcn_INTERNAL_modelFiles(vehicleFiles.ModelFolder);

% The body style, from the folder the vehicle is filed under
[parentFolder, ~] = fileparts(vehicleFolder);
[grandFolder, parentName] = fileparts(parentFolder);
[~, grandName] = fileparts(grandFolder);
vehicleFiles.BodyStyle = '';
vehicleFiles.BodyStyleFolder = '';
if strcmpi(grandName, 'BodyStyles') && strcmpi(fileparts(grandFolder), fileparts(fullfile(dataFolder, 'x')))
    vehicleFiles.BodyStyleFolder = parentName;
    vehicleFiles.BodyStyle = [lower(parentName(1)) parentName(2:end)];
end
vehicleFiles.IsSample = strcmpi(parentName, 'Samples') && strcmpi(grandFolder, fileparts(fullfile(dataFolder, 'x')));

vehicleFiles.Found = isfolder(vehicleFiles.Folder);
vehicleFiles.HasParameters = isfile(vehicleFiles.ParametersFile);
vehicleFiles.HasScript = isfile(vehicleFiles.ScriptFile);
vehicleFiles.HasMesh = isfile(vehicleFiles.MeshFile);
vehicleFiles.HasLevels = isfile(vehicleFiles.LevelsFile);
vehicleFiles.HasOutline = isfile(vehicleFiles.OutlineFile);
end % Ends fcn_INTERNAL_filesForID

%% fcn_INTERNAL_modelFiles
function modelFiles = fcn_INTERNAL_modelFiles(modelFolder)
% The 3D model files in the model folder and its source subfolder
modelFiles = {};
extensions = {'.glb','.gltf','.obj','.stl','.ply','.fbx','.blend'};
searchFolders = {modelFolder, fullfile(modelFolder, 'source')};
for ith_folder = 1:numel(searchFolders)
    if ~isfolder(searchFolders{ith_folder})
        continue;
    end
    listing = dir(searchFolders{ith_folder});
    listing = listing(~[listing.isdir]);
    for ith_file = 1:numel(listing)
        [~, ~, extension] = fileparts(listing(ith_file).name);
        if any(strcmpi(extension, extensions))
            modelFiles{end+1,1} = fullfile(searchFolders{ith_folder}, listing(ith_file).name); %#ok<AGROW>
        end
    end
end
end % Ends fcn_INTERNAL_modelFiles
