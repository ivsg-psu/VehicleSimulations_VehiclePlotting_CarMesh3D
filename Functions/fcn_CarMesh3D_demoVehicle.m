function [vehicleID, info] = fcn_CarMesh3D_demoVehicle(options)
% fcn_CarMesh3D_demoVehicle
% The vehicle that the repo's demos, tools and tests use when no vehicle is
% named: the "demo vehicle". It is set in ONE place, the EDIT HERE block
% below, so switching the whole repo to another vehicle is a one-line
% change. A user may also pick their own demo vehicle (for example with
% the "Use as demo vehicle" button in fcn_CarMesh3D_browseLibrary); that
% choice is saved on their computer only, and is used by the demos and
% tools. Tests always use the repo's own choice, so they give the same
% results on every computer.
%
% It also gives the GUI test vehicle: a made-up vehicle with every feature
% the GUIs show (every lamp type, two hidden sets, photos), used by the GUI
% tests.
%
% FORMAT:
%
%       [vehicleID, info] = fcn_CarMesh3D_demoVehicle(...
%           (Which=which), (FlagUsePreference=flag), (Set=newID),
%           (FlagReset=flag), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs, in any order. Any
%      option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Which: 'demo' (default) for the demo vehicle, or 'guiTest' for the
%      GUI test vehicle.
%
%      FlagUsePreference: true (default) to use the user's own choice of demo
%      vehicle when there is one; false for the repo's choice (tests use
%      false). Not used for the GUI test vehicle.
%
%      Set: a vehicle ID to save as this user's own demo vehicle (on this
%      computer only). It must be a finished vehicle: a folder with its
%      script, its finished mesh and its photos (ViewInDegrees_<angle>
%      pictures); if not, an error says what is missing and nothing is
%      saved. Default '' (nothing set).
%
%      FlagReset: true to remove this user's own choice, so the repo's choice
%      is used again. Default false.
%
%      FigNum: if given (and not -1), the demo vehicle and where its choice
%      comes from are printed. If -1, input checking is skipped (fast mode)
%      and nothing is printed.
%
% OUTPUTS:
%
%      vehicleID: the vehicle ID, such as '2009_Honda_Fit_Sport'.
%
%      info: a structure with
%           ID: the vehicle ID (as vehicleID)
%           Source: 'repo' (the repo's choice, below), 'preference' (this
%               user's own choice) or 'guiTest' (the GUI test vehicle)
%           RepoDemoID: the repo's choice of demo vehicle
%           GUITestID: the GUI test vehicle's ID
%           Files: the vehicle's files, as fcn_CarMesh3D_findVehicleFiles
%               gives them (Folder, MeshFile, ...)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       % The demo vehicle, and a temporary copy of it to try the tools on
%       vehicleID = fcn_CarMesh3D_demoVehicle();
%       demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID);
%
%       % In a test: always the repo's choice
%       vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false);
%
%       % Pick your own demo vehicle, then go back to the repo's
%       fcn_CarMesh3D_demoVehicle(Set='2009_Toyota_Corolla_LE');
%       fcn_CarMesh3D_demoVehicle(FlagReset=true);
%
%       See the script: script_test_fcn_CarMesh3D_demoVehicle.m for a full
%       test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_demoVehicle
%   % * First write of the code (Q35 A, Q36 A, Sean 04:19): the repo's
%   %   % demo vehicle in one place; a user's own choice saved as a
%   %   % MATLAB preference (CarMesh3D, DemoVehicle) on their computer,
%   %   % for demos and tools only; tests use the repo's choice; the GUI
%   %   % test vehicle's ID

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_demoVehicle
%   % * (none)


% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Which = 'demo'          % 'demo' or 'guiTest'
    options.FlagUsePreference = true    % Use this user's own choice, if any (tests: false)
    options.Set = ''                % A vehicle ID to save as this user's own choice
    options.FlagReset = false           % Remove this user's own choice
    options.FigNum = []             % Print the choice if given; -1 for fast mode
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDIT HERE: the repo's demo vehicle and the GUI test vehicle. To switch
% every demo, tool and test in the repo to another vehicle, change
% repoDemoID (to a finished vehicle with photos) and commit.
repoDemoID = '2009_Honda_Fit_Sport';
guiTestID = '2026_CarMesh3D_Sample_GUITestVehicle';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        % The option names are checked by the arguments block above
        if ~any(strcmp(char(options.Which), {'demo', 'guiTest'}))
            error('CarMesh3D:badInput', 'Which must be ''demo'' or ''guiTest''.');
        end
        if ~(ischar(options.Set) || (isstring(options.Set) && isscalar(options.Set)))
            error('CarMesh3D:badInput', 'Set must be a vehicle ID (text), such as ''2009_Toyota_Corolla_LE''.');
        end
        if ~isscalar(options.FlagUsePreference) || ~isscalar(options.FlagReset)
            error('CarMesh3D:badInput', 'UsePreference and Reset must be true or false.');
        end
    end
end

% Print the choice?
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

% A user's own choice to remove, or to save (checked first: only a
% finished vehicle with photos can be the demo vehicle)
if logical(options.FlagReset)
    fcn_INTERNAL_setPref('');
end
newID = char(options.Set);
if ~isempty(newID)
    [flagUsable, whatIsMissing] = fcn_INTERNAL_usable(newID);
    if ~flagUsable
        error('CarMesh3D:demoVehicle', 'The vehicle %s cannot be the demo vehicle: %s.', newID, whatIsMissing);
    end
    fcn_INTERNAL_setPref(newID);
end

% The vehicle asked for
if strcmp(char(options.Which), 'guiTest')
    vehicleID = guiTestID;
    source = 'guiTest';
else
    vehicleID = repoDemoID;
    source = 'repo';
    if logical(options.FlagUsePreference)
        preferredID = fcn_INTERNAL_getPref();
        if ~isempty(preferredID)
            if fcn_INTERNAL_usable(preferredID)
                vehicleID = preferredID;
                source = 'preference';
            else
                % (a saved choice that is no longer usable, such as a
                % vehicle since removed: the repo's choice, with a warning)
                warning('CarMesh3D:demoVehicle', ['Your demo vehicle %s is no longer usable, so the repo''s demo ' ...
                    'vehicle %s is used. To clear your choice: fcn_CarMesh3D_demoVehicle(FlagReset=true)'], preferredID, repoDemoID);
            end
        end
    end
end

info = struct('ID', vehicleID, 'Source', source, 'RepoDemoID', repoDemoID, 'GUITestID', guiTestID, ...
    'Files', fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1));

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
    switch source
        case 'preference'
            fprintf(1, 'Demo vehicle: %s (your own choice, on this computer; the repo''s is %s)\n', vehicleID, repoDemoID);
        case 'guiTest'
            fprintf(1, 'GUI test vehicle: %s\n', vehicleID);
        otherwise
            fprintf(1, 'Demo vehicle: %s (the repo''s choice)\n', vehicleID);
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

%% fcn_INTERNAL_usable
function [flagUsable, whatIsMissing] = fcn_INTERNAL_usable(vehicleID)
% Whether a vehicle can be the demo vehicle: its folder, script, finished
% mesh and photos (ViewInDegrees_<angle> pictures) are all there
flagUsable = false;
whatIsMissing = '';
try
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
catch
    whatIsMissing = 'no vehicle with that ID was found';
    return;
end
missing = {};
if ~vehicleFiles.Found
    missing{end+1} = 'no folder';
else
    if ~vehicleFiles.HasScript
        missing{end+1} = 'no script';
    end
    if ~vehicleFiles.HasMesh
        missing{end+1} = 'no finished mesh (run its script)';
    end
    photos = [dir(fullfile(vehicleFiles.Folder, 'photos', 'ViewInDegrees_*.jpg')); ...
        dir(fullfile(vehicleFiles.Folder, 'photos', 'ViewInDegrees_*.jpeg')); ...
        dir(fullfile(vehicleFiles.Folder, 'photos', 'ViewInDegrees_*.png'))];
    if isempty(photos)
        missing{end+1} = 'no photos (photos\ViewInDegrees_<angle>.jpg)';
    end
end
flagUsable = isempty(missing);
whatIsMissing = strjoin(missing, ', ');
end % Ends fcn_INTERNAL_usable

%% fcn_INTERNAL_getPref
function preferredID = fcn_INTERNAL_getPref()
% This user's own demo vehicle, or '' for none
preferredID = '';
try
    if ispref('CarMesh3D', 'DemoVehicle')
        preferredID = char(getpref('CarMesh3D', 'DemoVehicle'));
    end
catch
end
end % Ends fcn_INTERNAL_getPref

%% fcn_INTERNAL_setPref
function fcn_INTERNAL_setPref(vehicleID)
% Saves this user's own demo vehicle ('' removes it)
try
    if isempty(vehicleID)
        if ispref('CarMesh3D', 'DemoVehicle')
            rmpref('CarMesh3D', 'DemoVehicle');
        end
    else
        setpref('CarMesh3D', 'DemoVehicle', vehicleID);
    end
catch
end
end % Ends fcn_INTERNAL_setPref
