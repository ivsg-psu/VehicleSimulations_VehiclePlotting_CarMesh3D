function [cacheOutputs, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, cacheInputs, options)
% fcn_CarMesh3D_loadCache

% Reuses the saved results of a slow step (fcn_CarMesh3D_saveCache) when
% nothing the step depends on has changed: the saved inputs must equal
% cacheInputs exactly (compared directly, field by field, with NaN equal
% to NaN; no hashing). Otherwise says what changed, so the step is done
% again. The vehicle template uses it for three stages of a full run: the
% finished mesh, the comparison with the download, and the checks.
%
% FORMAT:
%
%       [cacheOutputs, flagReused, reason] = fcn_CarMesh3D_loadCache(...
%           cacheFile, cacheInputs, (FlagEnabled=flag), (FigNum=figNum))
%
% INPUTS:
%
%      cacheFile: the cache file's path (a .mat file).
%
%      cacheInputs: a structure of everything the step depends on, made
%      the same way as when it was saved.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagEnabled: false to never reuse (the step is always done; the
%      reason is 'cache not used'). Default true.
%
%      FigNum: if given (not -1), the decision is printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      cacheOutputs: the saved results (a structure), or [] when not
%      reused.
%
%      flagReused: true when the saved results were reused.
%
%      reason: why, as text: 'nothing changed (cached <date>)', 'no cache
%      file', 'cache not used', 'the cache file could not be read', or
%      'changed: <the top-level inputs that differ>'.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       [stage, flagReused, reason] = fcn_CarMesh3D_loadCache(cacheFile, stageInputs, FigNum=1);
%       if ~flagReused
%           % ... do the step, then:
%           fcn_CarMesh3D_saveCache(cacheFile, stageInputs, struct('vehicleMesh',vehicleMesh));
%       end
%
%       See the script: script_test_fcn_CarMesh3D_loadCache.m for a full
%       test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadCache
%   % * Wrote the code originally (drafted with Claude): reuse a slow step's results when nothing it depends on has changed (Sean: "only load the mat file if the inputs to the process are unchanged")

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadCache
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    cacheFile                    % The cache file (.mat)
    cacheInputs                  % Everything the step depends on (a structure)
    options.FlagEnabled = true       % false to never reuse
    options.FigNum = []          % Print the decision if given; -1 for fast mode
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
        if ~isstruct(cacheInputs)
            error('cacheInputs must be a structure');
        end
        if ~(islogical(options.FlagEnabled) || isnumeric(options.FlagEnabled)) || ~isscalar(options.FlagEnabled)
            error('Enabled must be true or false');
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
cacheOutputs = [];
flagReused = false;
cacheFile = char(cacheFile);
if ~logical(options.FlagEnabled)
    reason = 'cache not used';
elseif ~isfile(cacheFile)
    reason = 'no cache file';
else
    try
        saved = load(cacheFile, 'cacheInputs', 'cacheOutputs', 'cacheDate');
        if isequaln(saved.cacheInputs, cacheInputs)
            cacheOutputs = saved.cacheOutputs;
            flagReused = true;
            reason = sprintf('nothing changed (cached %s)', saved.cacheDate);
        else
            reason = ['changed: ' fcn_INTERNAL_changedFields(saved.cacheInputs, cacheInputs)];
        end
    catch
        reason = 'the cache file could not be read';
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
    [~, cacheName] = fileparts(cacheFile);
    if flagReused
        fprintf(1, 'Cache %s: reused, %s\n', cacheName, reason);
    else
        fprintf(1, 'Cache %s: done again, %s\n', cacheName, reason);
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



%% fcn_INTERNAL_changedFields
function changedText = fcn_INTERNAL_changedFields(savedInputs, newInputs)
% The top-level inputs that differ, as text
savedNames = fieldnames(savedInputs);
newNames = fieldnames(newInputs);
changed = [setdiff(savedNames, newNames); setdiff(newNames, savedNames)];
for fieldName = intersect(savedNames, newNames)'
    if ~isequaln(savedInputs.(fieldName{1}), newInputs.(fieldName{1}))
        changed{end+1,1} = fieldName{1}; %#ok<AGROW>
    end
end
if isempty(changed)
    changedText = 'the inputs (in their order or size)';
else
    changedText = strjoin(unique(changed)', ', ');
end
end % Ends fcn_INTERNAL_changedFields
