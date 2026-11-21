function [versionString, flagAtLeast, meshVersion] = fcn_CarMesh3D_version(options)
% fcn_CarMesh3D_version

% The version of this copy of CarMesh3D: the date of its release, as
% 'YYYY_MM_DD' (the same name its release folder has, such as
% CarMesh3D_2026_11_20). Programs that use CarMesh3D (such as
% AnimateCar3D) can check that the copy they find is new enough. The
% version is changed in this function when a new release is made.
%
% THE MESH VERSION (third output) changes more often: whenever a change to
% CarMesh3D would make a different finished mesh from the same download
% and settings (a labeling rule, the fit, the reduction, the floor panel).
% Every saved mesh carries the mesh version it was made with (its
% BuildInfo, see fcn_CarMesh3D_makeBuildInfo), so meshes made before a
% change can be found (fcn_CarMesh3D_listVehicles) and made again. The
% changes are listed below, newest first.
%
% MESH VERSIONS:
%   2026_11_21c  Lamp lenses stay lights when see-through (labelParts);
%                the symmetric fit measures length, height, and ground
%                clearance on the region the mirroring keeps; body-style
%                vehicles are not repaired again; BuildInfo and the
%                quality score are saved with each mesh
%   2026_11_21b  .glb texture colors and see-through glass; overlays
%                lifted 2 mm; floor panel follows the body; materials kept
%                per face in the simplification
%   2026_11_21a  Blender reduction; flipped faces fixed; floor panel
%   (meshes without a BuildInfo were made before 2026_11_21c)
%
% FORMAT:
%
%       [versionString, flagAtLeast, meshVersion] = fcn_CarMesh3D_version(...
%           (AtLeast=versionString), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      AtLeast: a version, 'YYYY_MM_DD', to compare with. Default ''
%      (no comparison).
%
%      FigNum: if given (not -1), the version is printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      versionString: this copy's version, such as '2026_11_20'.
%
%      flagAtLeast: true if this copy's version is AtLeast or newer (true
%      when AtLeast is not given).
%
%      meshVersion: the version of the mesh-making steps, such as
%      '2026_11_21c' (the date of the change, and a letter for several
%      in a day; see MESH VERSIONS above). Versions sort as text.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       [~, flagNewEnough] = fcn_CarMesh3D_version(AtLeast='2026_11_20');
%       if ~flagNewEnough, error('Please install a newer CarMesh3D'); end
%
%       See the script: script_test_fcn_CarMesh3D_version.m for a full
%       test suite.
%
% This function was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_version
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_version
%   % * meshVersion (third output): the version of the mesh-making
%   %   % steps, saved with every mesh, so meshes made before a change can
%   %   % be found and made again

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_version
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.AtLeast = ''      % 'YYYY_MM_DD' to compare with; '' for none
    options.FigNum = []       % print the version if given; -1 for fast mode
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


        if ~isempty(options.AtLeast) && ~((ischar(options.AtLeast) || isstring(options.AtLeast)) && ...
                ~isempty(regexp(char(options.AtLeast), '^\d{4}_\d{2}_\d{2}$', 'once')))
            error('AtLeast must be a version written as ''YYYY_MM_DD'', such as ''2026_11_20''');
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% THE VERSION: change this when making a release
versionString = '2026_11_20';
% THE MESH VERSION: change this (and the list above) whenever a change
% would make a different finished mesh
meshVersion = '2026_11_21c';

flagAtLeast = true;
if ~isempty(options.AtLeast)
    % (as numbers, YYYYMMDD: later dates are larger)
    flagAtLeast = str2double(strrep(versionString, '_', '')) >= str2double(strrep(char(options.AtLeast), '_', ''));
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

    fprintf(1, 'CarMesh3D version %s (mesh version %s)\n', versionString, meshVersion);
    if ~isempty(options.AtLeast)
        fprintf(1, '  at least %s: %d\n', char(options.AtLeast), flagAtLeast);
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


