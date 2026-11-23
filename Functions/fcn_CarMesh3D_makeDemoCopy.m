function demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, options)
% fcn_CarMesh3D_makeDemoCopy
% Makes a fresh, temporary copy of a finished vehicle's folder, for demos
% and for trying the tools. The viewer, the mesh editor and the reviewer
% can be given the copy's folder or files in place of the vehicle's: any
% change made with them (painted labels, review answers, the change log)
% is saved in the copy only, never in the vehicle. Each call replaces the
% copy with a new one, so changes made to the copy are thrown away.
%
% FORMAT:
%
%       demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID,...
%           (DemoFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleID: the vehicle ID of a finished vehicle, such as
%      '2009_Honda_Fit_Sport'.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      DemoFolder: where the copy is put (as <DemoFolder>\<ID>). Default:
%      a folder CarMesh3D_demo in the computer's temporary folder
%      (tempdir).
%
%      FigNum: if given (and not -1), a line saying where the copy is, and
%      that changes there are not saved to the vehicle, is printed. If set
%      to -1, input checking is skipped (fast mode) and nothing is
%      printed.
%
% OUTPUTS:
%
%      demoFiles: the copy's file names, as fcn_CarMesh3D_findVehicleFiles
%      gives them for a vehicle (Folder, MeshFile, OutlineFile, ...: all in
%      the copy), with one more field:
%           SourceFolder: the vehicle's own folder, which was copied
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       % View the Fit's labels from a copy (nothing is saved to the Fit)
%       demoFiles = fcn_CarMesh3D_makeDemoCopy('2009_Honda_Fit_Sport');
%       viewSettings = fcn_CarMesh3D_viewLabels(demoFiles.MeshFile, Outline=demoFiles.OutlineFile)
%
%       % Edit the copy's labels, or review the copy
%       fcn_CarMesh3D_paintLabels(demoFiles.Folder);
%       fcn_CarMesh3D_reviewVehicle(demoFiles.Folder);
%
%       See the script: script_test_fcn_CarMesh3D_makeDemoCopy.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDemoCopy
%   % * First write of the code: a fresh copy of a vehicle's folder in
%   %   % the temporary folder, for the demo menu in script_demo_CarMesh3D
%   %   % (Sean, 14:17: the demo's tools get a default mesh whose changes
%   %   % are not saved)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDemoCopy
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleID
    options.DemoFolder = ''   % Where the copy goes; '' for tempdir\CarMesh3D_demo
    options.FigNum = []       % Print where the copy is if given; -1 for fast mode
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
        if ~(ischar(vehicleID) || (isstring(vehicleID) && isscalar(vehicleID))) || isempty(char(vehicleID))
            error('CarMesh3D:badInput', 'vehicleID must be a vehicle ID, such as ''2009_Honda_Fit_Sport''.');
        end

        % Check the DemoFolder input
        if ~(ischar(options.DemoFolder) || (isstring(options.DemoFolder) && isscalar(options.DemoFolder)))
            error('CarMesh3D:badInput', 'DemoFolder must be a folder name (text).');
        end
    end
end

% Print where the copy is?
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

% The vehicle's own folder
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleID), FigNum=-1);
if ~vehicleFiles.Found
    error('CarMesh3D:noVehicle', 'No folder was found for the vehicle %s.', vehicleFiles.ID);
end
if ~vehicleFiles.HasMesh
    error('CarMesh3D:noMesh', 'The vehicle %s has no finished mesh yet: run its script first.', vehicleFiles.ID);
end

% Where the copy goes
demoRoot = char(options.DemoFolder);
if isempty(demoRoot)
    demoRoot = fullfile(tempdir, 'CarMesh3D_demo');
end
copyFolder = fullfile(demoRoot, vehicleFiles.ID);
if strcmpi(fcn_INTERNAL_fullPath(copyFolder), fcn_INTERNAL_fullPath(vehicleFiles.Folder))
    error('CarMesh3D:badInput', 'The copy would replace the vehicle''s own folder: choose another DemoFolder.');
end

% A fresh copy: the old copy, and any changes made to it, are removed
if isfolder(copyFolder)
    [flagRemoved, removeMessage] = rmdir(copyFolder, 's');
    if ~flagRemoved
        error('CarMesh3D:demoCopy', 'The old demo copy could not be removed (is it open in a tool?):\n%s\n%s', copyFolder, removeMessage);
    end
end
if ~isfolder(demoRoot)
    mkdir(demoRoot);
end
[flagCopied, copyMessage] = copyfile(vehicleFiles.Folder, copyFolder);
if ~flagCopied
    error('CarMesh3D:demoCopy', 'The vehicle''s folder could not be copied to %s:\n%s', copyFolder, copyMessage);
end

% The copy's file names
demoFiles = fcn_CarMesh3D_findVehicleFiles(copyFolder, FigNum=-1);
demoFiles.SourceFolder = vehicleFiles.Folder;

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
    fprintf(1, 'Demo copy of %s:\n    %s\n', vehicleFiles.Name, demoFiles.Folder);
    fprintf(1, '    (changes made to this copy are NOT saved to the vehicle, and are\n');
    fprintf(1, '    thrown away the next time a copy is made)\n');
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

%% fcn_INTERNAL_fullPath
function fullPath = fcn_INTERNAL_fullPath(folderName)
% The folder's full path, with no trailing separator and no . or ..
fullPath = char(java.io.File(char(folderName)).getAbsoluteFile().toPath().normalize().toString());
end % Ends fcn_INTERNAL_fullPath
