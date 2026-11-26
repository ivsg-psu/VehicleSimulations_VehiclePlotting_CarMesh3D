function vehicleTable = fcn_CarMesh3D_listVehicles(options)
% fcn_CarMesh3D_listVehicles

% Lists the finished vehicles (those with a saved mesh) in the Data
% folder, one row each, with what a user needs to choose among them and
% to know which must be made again: body style, size, face count, the
% quality score, and whether the mesh is up to date. A mesh is up to date
% when the MESH VERSION it was made with (its BuildInfo, see
% fcn_CarMesh3D_makeBuildInfo) is the current one (fcn_CarMesh3D_version),
% and, for a vehicle made from a body style, its exemplar has not been
% made again since.
%
% FORMAT:
%
%       vehicleTable = fcn_CarMesh3D_listVehicles(...
%           (FlagIncludeUnfinished=flag), (DataFolder=folder), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagIncludeUnfinished: true to list vehicles without a saved mesh too
%      (Status 'no mesh'). Default false.
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      FigNum: if given (not -1), the table is printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      vehicleTable: a table, one row per vehicle, sorted by body style
%      and then ID, with
%           ID, Name, BodyStyle (the style ID; for a sample, the style it
%               was made from, or 'sample')
%           IsExemplar: an approved exemplar of its style
%           FromBodyStyle: made from a body style's exemplar (no download)
%           Faces: the finished mesh's face count
%           Length_m, Width_m, Height_m: from the saved specification
%           Score: the quality score, 0 to 100 (NaN without a BuildInfo)
%           ChecksFailed: dimension checks failed (NaN without a BuildInfo)
%           MeshVersion: the mesh version it was made with ('' if none)
%           Made: when it was made ('' if not recorded)
%           Status: 'up to date', 'out of date' (an older mesh version),
%               'exemplar changed' (its exemplar was made again since),
%               'no stamp' (made before BuildInfo existed), or 'no mesh'
%           MeshFile: the saved mesh's path
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_loadBodyStyles,
%      fcn_CarMesh3D_version
%
% EXAMPLES:
%
%       vehicleTable = fcn_CarMesh3D_listVehicles(FigNum=1);
%       toRemake = vehicleTable.ID(vehicleTable.Status ~= "up to date");
%
%       See the script: script_test_fcn_CarMesh3D_listVehicles.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_listVehicles
%   % * Wrote the code originally (drafted with Claude): the finished
%   %   % vehicles with their quality scores and mesh versions, for finding
%   %   % meshes to make again and for the vehicle browser

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_listVehicles
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.FlagIncludeUnfinished = false   % List vehicles without a mesh too?
    options.DataFolder = []             % The Data folder; [] for the one next to Functions
    options.FigNum = []                 % Print the table if given; -1 for fast mode
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
        if ~(islogical(options.FlagIncludeUnfinished) || isnumeric(options.FlagIncludeUnfinished)) || ~isscalar(options.FlagIncludeUnfinished)
            error('IncludeUnfinished must be true or false');
        end
        if ~isempty(options.DataFolder) && ~isfolder(options.DataFolder)
            error('DataFolder is not a folder: %s', char(options.DataFolder));
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
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
[~, ~, currentMeshVersion] = fcn_CarMesh3D_version(FigNum=-1);
allVehicles = fcn_CarMesh3D_findVehicleFiles('', DataFolder=options.DataFolder, FigNum=-1);
if ~logical(options.FlagIncludeUnfinished)
    allVehicles = allVehicles([allVehicles.HasMesh]);
end
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=options.DataFolder, FigNum=-1);
exemplarIDs = vertcat(bodyStyles.ExemplarIDs);
if isempty(exemplarIDs)
    exemplarIDs = {};
end

Nvehicles = numel(allVehicles);
ID = cell(Nvehicles,1); Name = cell(Nvehicles,1); BodyStyle = cell(Nvehicles,1);
IsExemplar = false(Nvehicles,1); FromBodyStyle = false(Nvehicles,1);
Faces = nan(Nvehicles,1); Length_m = nan(Nvehicles,1); Width_m = nan(Nvehicles,1); Height_m = nan(Nvehicles,1);
Score = nan(Nvehicles,1); ChecksFailed = nan(Nvehicles,1);
MeshVersion = repmat({''}, Nvehicles,1); Made = repmat({''}, Nvehicles,1);
Status = repmat({'no mesh'}, Nvehicles,1); MeshFile = cell(Nvehicles,1);
exemplarVersions = containers.Map('KeyType','char','ValueType','char');   % (each exemplar's own mesh version)
recordedExemplar = repmat({''}, Nvehicles,1); recordedExemplarVersion = repmat({''}, Nvehicles,1);
for ith_vehicle = 1:Nvehicles
    thisVehicle = allVehicles(ith_vehicle);
    ID{ith_vehicle} = thisVehicle.ID;
    Name{ith_vehicle} = thisVehicle.Name;
    BodyStyle{ith_vehicle} = thisVehicle.BodyStyle;
    if thisVehicle.IsSample || isempty(thisVehicle.BodyStyle)
        BodyStyle{ith_vehicle} = 'sample';
    end
    IsExemplar(ith_vehicle) = any(strcmp(exemplarIDs, thisVehicle.ID));
    MeshFile{ith_vehicle} = thisVehicle.MeshFile;
    if ~thisVehicle.HasMesh
        continue;
    end
    loaded = load(thisVehicle.MeshFile, 'vehicleMesh', 'vehicleSpec');
    vehicleMesh = loaded.vehicleMesh;
    Faces(ith_vehicle) = size(vehicleMesh.Faces,1);
    if isfield(loaded, 'vehicleSpec')
        Length_m(ith_vehicle) = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallLength');
        Width_m(ith_vehicle) = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallWidth');
        Height_m(ith_vehicle) = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallHeight');
    end
    FromBodyStyle(ith_vehicle) = isfield(vehicleMesh, 'BodyStyleInfo') && ~isempty(vehicleMesh.BodyStyleInfo.ExemplarID);
    if FromBodyStyle(ith_vehicle) && strcmp(BodyStyle{ith_vehicle}, 'sample') && isfield(vehicleMesh.BodyStyleInfo, 'BodyStyle')
        BodyStyle{ith_vehicle} = char(vehicleMesh.BodyStyleInfo.BodyStyle);     % (a generic vehicle: its style)
    end
    if isfield(vehicleMesh, 'BuildInfo') && isstruct(vehicleMesh.BuildInfo)
        buildInfo = vehicleMesh.BuildInfo;
        MeshVersion{ith_vehicle} = char(buildInfo.MeshVersion);
        Made{ith_vehicle} = char(buildInfo.Date);
        Score(ith_vehicle) = buildInfo.Quality.Score;
        ChecksFailed(ith_vehicle) = buildInfo.Quality.DimensionChecksFailed;
        recordedExemplar{ith_vehicle} = char(buildInfo.ExemplarID);
        recordedExemplarVersion{ith_vehicle} = char(buildInfo.ExemplarMeshVersion);
        exemplarVersions(thisVehicle.ID) = [char(buildInfo.MeshVersion) '|' char(buildInfo.Date)];
        if strcmp(MeshVersion{ith_vehicle}, currentMeshVersion)
            Status{ith_vehicle} = 'up to date';
        else
            Status{ith_vehicle} = 'out of date';
        end
    else
        Status{ith_vehicle} = 'no stamp';
    end
end

% (a vehicle made from an exemplar that has been made again since)
for ith_vehicle = 1:Nvehicles
    exemplarID = recordedExemplar{ith_vehicle};
    if strcmp(Status{ith_vehicle}, 'up to date') && ~isempty(exemplarID)
        if ~isKey(exemplarVersions, exemplarID)
            Status{ith_vehicle} = 'exemplar changed';            % (the exemplar has no stamp now)
        else
            exemplarStamp = strsplit(exemplarVersions(exemplarID), '|');
            if ~strcmp(exemplarStamp{1}, recordedExemplarVersion{ith_vehicle}) || string(exemplarStamp{2}) > string(Made{ith_vehicle})
                Status{ith_vehicle} = 'exemplar changed';
            end
        end
    end
end

vehicleTable = table(string(ID), string(Name), string(BodyStyle), IsExemplar, FromBodyStyle, Faces, ...
    Length_m, Width_m, Height_m, Score, ChecksFailed, string(MeshVersion), string(Made), string(Status), string(MeshFile), ...
    'VariableNames', {'ID','Name','BodyStyle','IsExemplar','FromBodyStyle','Faces','Length_m','Width_m','Height_m', ...
    'Score','ChecksFailed','MeshVersion','Made','Status','MeshFile'});
vehicleTable = sortrows(vehicleTable, {'BodyStyle','ID'});

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
    fprintf(1, 'Finished vehicles (current mesh version %s):\n', currentMeshVersion);
    fprintf(1, '  %-44s %-17s %7s %6s %-12s %-16s\n', 'ID', 'Body style', 'Faces', 'Score', 'Mesh ver.', 'Status');
    for ith_row = 1:height(vehicleTable)
        exemplarMark = '';
        if vehicleTable.IsExemplar(ith_row)
            exemplarMark = ' (exemplar)';
        end
        fprintf(1, '  %-44s %-17s %7.0f %6.1f %-12s %-16s%s\n', vehicleTable.ID(ith_row), vehicleTable.BodyStyle(ith_row), ...
            vehicleTable.Faces(ith_row), vehicleTable.Score(ith_row), vehicleTable.MeshVersion(ith_row), ...
            vehicleTable.Status(ith_row), exemplarMark);
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



%% fcn_INTERNAL_number
function value = fcn_INTERNAL_number(structure, fieldName)
% A numeric field as a number (NaN if missing or empty)
value = NaN;
if isfield(structure, fieldName) && isnumeric(structure.(fieldName)) && isscalar(structure.(fieldName))
    value = double(structure.(fieldName));
end
end % Ends fcn_INTERNAL_number
