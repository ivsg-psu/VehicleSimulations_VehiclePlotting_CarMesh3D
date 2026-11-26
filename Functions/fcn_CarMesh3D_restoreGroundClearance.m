function [vehicleMesh, shiftDistance] = fcn_CarMesh3D_restoreGroundClearance(vehicleMesh, groundClearance, options)
% fcn_CarMesh3D_restoreGroundClearance

% Puts the lowest point of the body back at the ground clearance after a
% reduction raised it. A reduction (Blender's, especially of a dense
% download) can collapse the thin bottom edge of the rocker panels, so
% the lowest body point ends up a few millimeters above where the fit put
% it (the 2025 Camry: 5 mm, failing its dimension check). Every vertex
% that is not part of a wheel is stretched up and down, piecewise
% linearly: the ground and the roof stay where they are, and the lowest
% body point moves to the ground clearance, exactly as
% fcn_CarMesh3D_fitMeshToSpec does. The wheels are not moved. A mesh
% whose lowest body point is already within Tolerance of the ground
% clearance is not changed.
%
% FORMAT:
%
%       [vehicleMesh, shiftDistance] = fcn_CarMesh3D_restoreGroundClearance(...
%           vehicleMesh, groundClearance, (Tolerance=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a fitted, labeled vehicle mesh (LabelFacePart, with
%      the body as part 1 and the wheels as part 3), in meters with the
%      ground at Z = 0.
%
%      groundClearance: the ground clearance, in meters (the fit's
%      target: vehicleSpec.GroundClearance).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tolerance: how far (m) the lowest body point may be from the ground
%      clearance before it is moved. Default 0.0005 (half a millimeter).
%
%      FigNum: if given (not -1), the change is printed. If set to -1,
%      input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh, with its non-wheel vertices stretched. Its
%      face normals are kept: the stretch moves the lowest points by
%      millimeters, which does not change which way the faces point.
%
%      shiftDistance: how far (m) the lowest body point was moved
%      (negative: down); 0 when not moved.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       vehicleMesh = fcn_CarMesh3D_restoreGroundClearance(vehicleMesh, vehicleSpec.GroundClearance, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_restoreGroundClearance.m
%       for a full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_restoreGroundClearance
%   % * Wrote the code originally (drafted with Claude), after Blender's
%   %   % reduction left the 2025 Camry's ground clearance 5 mm high

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_restoreGroundClearance
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh                  % A fitted, labeled vehicle mesh
    groundClearance              % The ground clearance (m)
    options.Tolerance = 0.0005   % How far (m) the lowest body point may be off before it is moved
    options.FigNum = []          % Print the change if given; -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces','LabelFacePart'}))
            error('vehicleMesh must be a labeled vehicle mesh (Vertices, Faces, LabelFacePart)');
        end
        if ~isnumeric(groundClearance) || ~isscalar(groundClearance) || groundClearance < 0
            error('groundClearance must be a nonnegative number (m)');
        end
        if ~isnumeric(options.Tolerance) || ~isscalar(options.Tolerance) || options.Tolerance < 0
            error('Tolerance must be a nonnegative number (m)');
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
shiftDistance = 0;
bodyVertices = unique(vehicleMesh.Faces(vehicleMesh.LabelFacePart==1,:));
oldBottom = NaN;
if ~isempty(bodyVertices)
    oldBottom = min(vehicleMesh.Vertices(bodyVertices,3));
    roofHeight = max(vehicleMesh.Vertices(:,3));
    if abs(oldBottom - groundClearance) > options.Tolerance && oldBottom > 0 && groundClearance < roofHeight && oldBottom < roofHeight
        % (every vertex not used by a wheel face is stretched; a vertex
        % shared with a wheel stays put)
        wheelVertices = unique(vehicleMesh.Faces(vehicleMesh.LabelFacePart==3,:));
        moved = true(size(vehicleMesh.Vertices,1),1);
        moved(wheelVertices) = false;
        oldHeights = vehicleMesh.Vertices(moved,3);
        vehicleMesh.Vertices(moved,3) = interp1([0 oldBottom roofHeight], [0 groundClearance roofHeight], oldHeights, 'linear', 'extrap');
        shiftDistance = groundClearance - oldBottom;
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
    if shiftDistance==0
        fprintf(1, 'Ground clearance: the lowest body point is at %.4f m (target %.4f m): not moved\n', oldBottom, groundClearance);
    else
        fprintf(1, 'Ground clearance: the lowest body point moved from %.4f m to %.4f m (%+.1f mm); wheels not moved\n', ...
            oldBottom, groundClearance, 1000*shiftDistance);
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


