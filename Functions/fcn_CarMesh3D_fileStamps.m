function fileStamps = fcn_CarMesh3D_fileStamps(fileList, options)
% fcn_CarMesh3D_fileStamps

% The name, size, and date of each file in a list: a stamp that changes
% whenever a file is saved again, without reading the file. Used as part
% of a cached step's inputs (fcn_CarMesh3D_loadCache), so the step is done
% again when a file it reads, or a function it runs, has changed.
%
% FORMAT:
%
%       fileStamps = fcn_CarMesh3D_fileStamps(fileList, (FigNum=figNum))
%
% INPUTS:
%
%      fileList: a cell array of file names or paths (or one as text). A
%      name without a folder that MATLAB can find (a function, such as
%      'fcn_CarMesh3D_labelParts.m') is found with WHICH.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: if given (not -1), the stamps are printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      fileStamps: an N x 1 structure array, one per file, in the list's
%      order, with Name (the file's name), Bytes, and Date (its
%      modification time as a datenum); a file that is not found has
%      Bytes -1 and Date 0 (so two "not found" stamps are equal).
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       stamps = fcn_CarMesh3D_fileStamps({'fcn_CarMesh3D_labelParts.m', 'C:\data\model.glb'}, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_fileStamps.m for a full
%       test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fileStamps
%   % * Wrote the code originally (drafted with Claude): file stamps for the cached steps of a vehicle run

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fileStamps
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    fileList                     % The files: a cell array of names or paths, or one as text
    options.FigNum = []          % Print the stamps if given; -1 for fast mode
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
        if ~(iscellstr(fileList) || ischar(fileList) || isstring(fileList))
            error('fileList must be a cell array of file names, or one file name as text');
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
fileList = cellstr(fileList);
fileStamps = repmat(struct('Name','', 'Bytes',-1, 'Date',0), numel(fileList), 1);
for ith_file = 1:numel(fileList)
    thisFile = char(fileList{ith_file});
    [~, fileName, fileExtension] = fileparts(thisFile);
    fileStamps(ith_file).Name = [fileName fileExtension];
    if ~isfile(thisFile)
        foundFile = which(thisFile);
        if ~isempty(foundFile)
            thisFile = foundFile;
        end
    end
    if isfile(thisFile)
        fileInfo = dir(thisFile);
        fileStamps(ith_file).Bytes = fileInfo.bytes;
        fileStamps(ith_file).Date = fileInfo.datenum;
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
    for ith_file = 1:numel(fileStamps)
        if fileStamps(ith_file).Bytes < 0
            fprintf(1, '  %-50s (not found)\n', fileStamps(ith_file).Name);
        else
            fprintf(1, '  %-50s %10d bytes  %s\n', fileStamps(ith_file).Name, fileStamps(ith_file).Bytes, ...
                char(datetime(fileStamps(ith_file).Date, 'ConvertFrom','datenum', 'Format','yyyy-MM-dd HH:mm:ss')));
        end
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


