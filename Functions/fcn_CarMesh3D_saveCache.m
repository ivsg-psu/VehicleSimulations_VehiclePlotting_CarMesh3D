function fcn_CarMesh3D_saveCache(cacheFile, cacheInputs, cacheOutputs, options)
% fcn_CarMesh3D_saveCache

% Saves the results of a slow step together with everything the step
% depended on, so the next run can reuse them (fcn_CarMesh3D_loadCache)
% when nothing has changed. The folder is made if needed.
%
% FORMAT:
%
%       fcn_CarMesh3D_saveCache(cacheFile, cacheInputs, cacheOutputs, (FigNum=figNum))
%
% INPUTS:
%
%      cacheFile: the cache file's path (a .mat file).
%
%      cacheInputs: a structure of everything the step depends on
%      (settings, the vehicle specification, fcn_CarMesh3D_fileStamps of
%      the files and functions it reads, the mesh version).
%
%      cacheOutputs: a structure of the step's results.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: if given (not -1), what was saved is printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      (none: the file cacheFile, with the variables cacheInputs,
%      cacheOutputs, and cacheDate)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       fcn_CarMesh3D_saveCache(fullfile(cacheFolder,'stage1_mesh.mat'), stageInputs, struct('vehicleMesh',vehicleMesh));
%
%       See the script: script_test_fcn_CarMesh3D_loadCache.m (it tests
%       both functions).
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveCache
%   % * Wrote the code originally (drafted with Claude): the cache for the slow steps of a vehicle run

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveCache
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    cacheFile                    % The cache file (.mat)
    cacheInputs                  % Everything the step depends on (a structure)
    cacheOutputs                 % The step's results (a structure)
    options.FigNum = []          % Print what was saved if given; -1 for fast mode
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
        if ~(ischar(cacheFile) || isstring(cacheFile))
            error('cacheFile must be a file path (text)');
        end
        if ~isstruct(cacheInputs) || ~isstruct(cacheOutputs)
            error('cacheInputs and cacheOutputs must be structures');
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
cacheFolder = fileparts(char(cacheFile));
if ~isempty(cacheFolder) && ~isfolder(cacheFolder)
    mkdir(cacheFolder);
end
cacheDate = char(datetime('now', 'Format','yyyy-MM-dd HH:mm:ss'));
save(char(cacheFile), 'cacheInputs', 'cacheOutputs', 'cacheDate');

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
    fileInfo = dir(char(cacheFile));
    fprintf(1, 'Cached %s (%.1f MB): %s\n', char(cacheFile), fileInfo.bytes/1e6, strjoin(fieldnames(cacheOutputs)', ', '));
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


