function [vehicleMesh, vehicleInfo] = fcn_CarMesh3D_showVehicle(vehicleID, options)
% fcn_CarMesh3D_showVehicle

% Shows one finished vehicle from the Data folder: its mesh in 3D (as it
% will be plotted and animated), its 2D outlines, or its parts colored by
% label or by material, and prints a short summary (name, body style,
% size, faces, quality score, dimension checks, mesh version). This is
% what the vehicle browser (fcn_CarMesh3D_browseVehicles) calls when a
% vehicle is chosen, and it can be called directly too.
%
% FORMAT:
%
%       [vehicleMesh, vehicleInfo] = fcn_CarMesh3D_showVehicle(vehicleID,...
%           (View=view), (DataFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleID: the vehicle ID, such as '2013_Toyota_Prius_Four' (see
%      fcn_CarMesh3D_findVehicleFiles). The vehicle must have a saved
%      (finished) mesh.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      View: what to show:
%           'both' (default): the 3D mesh in figure FigNum and the 2D
%               outlines in figure FigNum+1
%           '3d': the 3D mesh only
%           '2d': the 2D outlines only (in figure FigNum)
%           'labels': the parts colored by label (fcn_CarMesh3D_plotLabels)
%           'materials': the parts colored by source material
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      FigNum: the figure to show the vehicle in. If empty or omitted,
%      the vehicle is loaded and summarized but not shown. If set to -1,
%      input checking is skipped and nothing is shown or printed (fast
%      mode).
%
% OUTPUTS:
%
%      vehicleMesh: the finished mesh, as saved.
%
%      vehicleInfo: a structure with ID, Name, BodyStyle, Faces,
%      Length_m, Width_m, Height_m, Score (NaN without a BuildInfo),
%      ChecksFailed, MeshVersion, Made, and MeshFile.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_plotVehicle,
%      fcn_CarMesh3D_loadOutline2D, fcn_CarMesh3D_plotLabels
%
% EXAMPLES:
%
%       fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', FigNum=1);
%       fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', View='materials', FigNum=3);
%
%       See the script: script_test_fcn_CarMesh3D_showVehicle.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_showVehicle
%   % * Wrote the code originally (drafted with Claude): one finished
%   %   % vehicle in 3D, 2D, or by label or material, with a summary, for
%   %   % the vehicle browser

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_showVehicle
%   % * Show the detail levels too (fcn_CarMesh3D_loadDetailLevels)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleID                           % The vehicle ID
    options.View = 'both'               % 'both', '3d', '2d', 'labels', or 'materials'
    options.DataFolder = []             % The Data folder; [] for the one next to Functions
    options.FigNum = []                 % The figure to show it in; -1 for fast mode
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
        if ~(ischar(vehicleID) || (isstring(vehicleID) && isscalar(vehicleID))) || strlength(vehicleID)==0
            error('vehicleID must be a vehicle ID, such as ''2013_Toyota_Prius_Four''');
        end
        if ~any(strcmpi(char(options.View), {'both','3d','2d','labels','materials'}))
            error('View must be ''both'', ''3d'', ''2d'', ''labels'', or ''materials''');
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
vehicleID = char(vehicleID);
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, DataFolder=options.DataFolder, FigNum=-1);
if ~vehicleFiles.HasMesh
    error('CarMesh3D:noMesh', 'The vehicle %s has no finished mesh yet (%s). Run its script first.', vehicleID, vehicleFiles.MeshFile);
end
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
vehicleMesh = loaded.vehicleMesh;

% The summary
vehicleInfo = struct();
vehicleInfo.ID = vehicleID;
vehicleInfo.Name = char(vehicleFiles.Name);
vehicleInfo.BodyStyle = char(vehicleFiles.BodyStyle);
if isfield(vehicleMesh, 'BodyStyleInfo') && isfield(vehicleMesh.BodyStyleInfo, 'BodyStyle') && ~isempty(vehicleMesh.BodyStyleInfo.BodyStyle)
    vehicleInfo.BodyStyle = char(vehicleMesh.BodyStyleInfo.BodyStyle);   % (a generic vehicle: its style)
end
vehicleInfo.Faces = size(vehicleMesh.Faces,1);
vehicleInfo.Length_m = NaN; vehicleInfo.Width_m = NaN; vehicleInfo.Height_m = NaN;
if isfield(loaded, 'vehicleSpec')
    vehicleInfo.Length_m = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallLength');
    vehicleInfo.Width_m = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallWidth');
    vehicleInfo.Height_m = fcn_INTERNAL_number(loaded.vehicleSpec, 'OverallHeight');
end
vehicleInfo.Score = NaN; vehicleInfo.ChecksFailed = NaN;
vehicleInfo.MeshVersion = ''; vehicleInfo.Made = '';
if isfield(vehicleMesh, 'BuildInfo') && isstruct(vehicleMesh.BuildInfo)
    vehicleInfo.Score = vehicleMesh.BuildInfo.Quality.Score;
    vehicleInfo.ChecksFailed = vehicleMesh.BuildInfo.Quality.DimensionChecksFailed;
    vehicleInfo.MeshVersion = char(vehicleMesh.BuildInfo.MeshVersion);
    vehicleInfo.Made = char(vehicleMesh.BuildInfo.Date);
end
vehicleInfo.MeshFile = vehicleFiles.MeshFile;

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
if 0==flag_max_speed
    fprintf(1, '%s (%s)\n', vehicleInfo.Name, vehicleInfo.ID);
    fprintf(1, '  Body style: %s   Size: %.2f x %.2f x %.2f m   Faces: %d\n', vehicleInfo.BodyStyle, ...
        vehicleInfo.Length_m, vehicleInfo.Width_m, vehicleInfo.Height_m, vehicleInfo.Faces);
    fprintf(1, '  Quality score: %.1f   Dimension checks failed: %g   Mesh version: %s   Made: %s\n', ...
        vehicleInfo.Score, vehicleInfo.ChecksFailed, vehicleInfo.MeshVersion, vehicleInfo.Made);
end

if flag_do_plots
    titleText = sprintf('%s (score %.0f)', vehicleInfo.Name, vehicleInfo.Score);
    switch lower(char(options.View))
        case {'both','3d'}
            figure(figNum); clf;
            fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
            title(titleText, 'Interpreter', 'none');
            if strcmpi(options.View, 'both')
                fcn_CarMesh3D_loadOutline2D(vehicleID, DataFolder=options.DataFolder, FigNum=figNum+1);
                sgtitle(figure(figNum+1), sprintf('%s: 2D outlines', vehicleInfo.Name), 'Interpreter', 'none');
            end
        case '2d'
            fcn_CarMesh3D_loadOutline2D(vehicleID, DataFolder=options.DataFolder, FigNum=figNum);
            sgtitle(figure(figNum), sprintf('%s: 2D outlines', vehicleInfo.Name), 'Interpreter', 'none');
        case 'labels'
            fcn_CarMesh3D_plotLabels(vehicleMesh, Title=titleText, FigNum=figNum);
        case 'materials'
            fcn_CarMesh3D_plotLabels(vehicleMesh, Title=titleText, ColorBy='material', FigNum=figNum);
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
