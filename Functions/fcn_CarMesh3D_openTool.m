function toolOutput = fcn_CarMesh3D_openTool(nextStep, options)
% fcn_CarMesh3D_openTool
% Opens one of the vehicle tools for a vehicle: the step a user asked for
% in the library browser (its View, Edit labels or Review buttons), as
% returned by fcn_CarMesh3D_browseLibrary in its third output, nextStep.
%
% This is called by the trunk (the demo menu, or the user's own script),
% never by another tool: under the tree rule (Sean, 2026-11-24 01:28),
% "entry in/out of a branch is mediated by the trunk, not via other
% branches". So the browser returns the step, and the trunk opens it:
%
%       [selectedNames, ~, nextStep] = fcn_CarMesh3D_browseLibrary();
%       fcn_CarMesh3D_openTool(nextStep);   % (does nothing if no button was pressed)
%
% FORMAT:
%
%       toolOutput = fcn_CarMesh3D_openTool(nextStep,...
%           (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      nextStep: a structure with Tool ('view', 'edit' or 'review'; ''
%      for none), VehicleID, and Folder (the vehicle's folder, or its demo
%      copy's).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagVisible: false to open the tool hidden (for tests). Default true.
%
%      FigNum: not used (the tools make their own windows). If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      toolOutput: the tool's handles: the viewer's (fcn_CarMesh3D_viewLabels,
%      second output), the painter's (fcn_CarMesh3D_paintLabels, third
%      output) or the reviewer's window (fcn_CarMesh3D_reviewVehicle, second
%      output); [] when nextStep.Tool is empty.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_viewLabels,
%      fcn_CarMesh3D_paintLabels, fcn_CarMesh3D_reviewVehicle
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_openTool.m
%       for a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_openTool
%   % * First write (C2S 13 (A) in the browser's design file): the tools
%   %   % the library browser used to open itself

% TO-DO:
%
% (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    nextStep
    options.FlagVisible = true      % false to open the tool hidden (tests)
    options.FigNum = []         % Not used; -1 for fast mode
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
        % Check the nextStep input
        if ~isstruct(nextStep) || ~all(isfield(nextStep, {'Tool','VehicleID','Folder'}))
            error('nextStep must be a structure with Tool, VehicleID and Folder (from fcn_CarMesh3D_browseLibrary)');
        end
        if ~isempty(nextStep.Tool) && ~any(strcmp(nextStep.Tool, {'view','edit','review'}))
            error('nextStep.Tool must be ''view'', ''edit'', ''review'' or empty, not ''%s''', nextStep.Tool);
        end
    end
end

%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

toolOutput = [];
if isempty(nextStep.Tool)
    return;   % (no button was pressed: nothing to open)
end
files = fcn_CarMesh3D_findVehicleFiles(nextStep.Folder, FigNum=-1);
flagVisible = logical(options.FlagVisible);
switch nextStep.Tool
    case 'view'
        outlineArguments = {};
        if files.HasOutline
            outlineArguments = {'Outline', files.OutlineFile};
        end
        [~, toolOutput] = fcn_CarMesh3D_viewLabels(files.MeshFile, outlineArguments{:}, FlagWait=false, FlagVisible=flagVisible);
    case 'edit'
        [~, ~, toolOutput] = fcn_CarMesh3D_paintLabels(files.Folder, FlagVisible=flagVisible);
    case 'review'
        [~, toolOutput] = fcn_CarMesh3D_reviewVehicle(files.Folder, FlagVisible=flagVisible);
end

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
