function vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, options)
% fcn_CarMesh3D_findVehicleFiles
% Returns the standard file and folder names for a vehicle stored in the
% Data folder, or lists every vehicle stored there. This function is the
% CarMesh3D naming convention, in code.
%
% THE NAMING CONVENTION. Each vehicle has its own folder in Data, named
%
%       YEAR_Make_Model_Trimline        for example   2013_Toyota_Prius_Four
%                                                     2014_Ford_TransitConnect_XLTCargoLWB
%
% Underscores only separate the four parts. Each part is letters and
% digits only; several words are joined in CamelCase (Transit Connect is
% TransitConnect). The year has four digits. This name is the vehicle ID.
% Inside the folder:
%
%       vehicleParameters_<ID>.mat     the IVSG vehicleParameters structure
%       script_CarMesh3D_vehicle_<ID>.m          the vehicle's script: builds the
%                                      mesh and runs the standard checks
%       vehicleMesh_<ID>.mat           the finished mesh (made by the script)
%       vehicleLevels_<ID>.mat         its detail levels, for animation
%                                      (made by the script; see
%                                      fcn_CarMesh3D_makeDetailLevels)
%       model\                         the downloaded 3D model, its
%                                      LICENSE.txt, and converted files
%       checks\                        the standard check images and GIFs
%                                      (made by fcn_CarMesh3D_runVehicleChecks)
%
% Other files (for example, notes on where the parameters came from) may
% also be kept in the folder.
%
% FORMAT:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID,...
%           (DataFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleID: the vehicle ID, such as '2013_Toyota_Prius_Four', or ''
%      (empty) to list every vehicle folder in the Data folder.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
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
%           ModelFolder, ChecksFolder: full paths, following the
%           convention above
%           HasParameters, HasScript, HasMesh, HasLevels: true if those
%           files exist
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
        if ~isempty(char(vehicleID)) && ~fcn_INTERNAL_isValidID(char(vehicleID))
            error(['vehicleID %s does not follow YEAR_Make_Model_Trimline: four parts separated by ' ...
                'underscores, each made of letters and digits only, with a four-digit year ' ...
                '(for example 2014_Ford_TransitConnect_XLTCargoLWB)'], char(vehicleID));
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

if isempty(vehicleID)
    % List every folder in Data whose name is a valid vehicle ID
    folderList = dir(dataFolder);
    folderList = folderList([folderList.isdir]);
    folderNames = {folderList.name};
    folderNames = folderNames(cellfun(@fcn_INTERNAL_isValidID, folderNames));
    vehicleFiles = repmat(fcn_INTERNAL_filesForID('0000_A_B_C', dataFolder), 0, 1);
    for ith_folder = 1:length(folderNames)
        vehicleFiles(end+1,1) = fcn_INTERNAL_filesForID(folderNames{ith_folder}, dataFolder); %#ok<AGROW>
    end
else
    vehicleFiles = fcn_INTERNAL_filesForID(vehicleID, dataFolder);
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
    fprintf(1,'%-45s %-10s %-7s %-6s %-6s\n', 'ID', 'Parameters', 'Script', 'Mesh', 'Levels');
    yesNo = {'-','yes'};
    for ith_vehicle = 1:length(vehicleFiles)
        fprintf(1,'%-45s %-10s %-7s %-6s %-6s\n', vehicleFiles(ith_vehicle).ID, ...
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

%% fcn_INTERNAL_filesForID
function vehicleFiles = fcn_INTERNAL_filesForID(vehicleID, dataFolder)
% The standard names for one vehicle ID
parts = split(vehicleID, '_');
vehicleFiles = struct;
vehicleFiles.ID = vehicleID;
vehicleFiles.Year = str2double(parts{1});
vehicleFiles.Make = parts{2};
vehicleFiles.Model = parts{3};
vehicleFiles.Trim = parts{4};
vehicleFiles.Name = strjoin(parts', ' ');
vehicleFiles.Folder = fullfile(dataFolder, vehicleID);
vehicleFiles.ParametersFile = fullfile(vehicleFiles.Folder, ['vehicleParameters_' vehicleID '.mat']);
vehicleFiles.ScriptFile = fullfile(vehicleFiles.Folder, ['script_CarMesh3D_vehicle_' vehicleID '.m']);
vehicleFiles.MeshFile = fullfile(vehicleFiles.Folder, ['vehicleMesh_' vehicleID '.mat']);
vehicleFiles.LevelsFile = fullfile(vehicleFiles.Folder, ['vehicleLevels_' vehicleID '.mat']);
vehicleFiles.ModelFolder = fullfile(vehicleFiles.Folder, 'model');
vehicleFiles.ChecksFolder = fullfile(vehicleFiles.Folder, 'checks');
vehicleFiles.HasParameters = isfile(vehicleFiles.ParametersFile);
vehicleFiles.HasScript = isfile(vehicleFiles.ScriptFile);
vehicleFiles.HasMesh = isfile(vehicleFiles.MeshFile);
vehicleFiles.HasLevels = isfile(vehicleFiles.LevelsFile);
end % Ends fcn_INTERNAL_filesForID
