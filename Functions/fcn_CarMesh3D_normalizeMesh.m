function vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, options)
% fcn_CarMesh3D_normalizeMesh
% Puts a mesh into the CarMesh3D vehicle frame, which follows the ISO 8855
% vehicle convention:
%
%       X forward, Y to the left, Z up, units of meters,
%       origin on the ground, centered in length and width.
%
% Downloaded models use many different conventions (Y-up is common, and
% units may be mm, cm, or inches). The user states which file axis points
% up and which points forward; this function rotates the mesh (a proper
% rotation, never a mirror), converts the units, and moves the origin.
%
% After this step the origin is at the center of the bounding box in X
% and Y and at the lowest point in Z. fcn_CarMesh3D_fitMeshToSpec later
% moves the origin to the rear axle.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh,...
%           (UpAxis=upAxisString),...
%           (ForwardAxis=forwardAxisString),...
%           (Units=unitsSetting),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure, for example from
%      fcn_CarMesh3D_importMesh.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      UpAxis: the file axis that points up, as a string with a sign:
%      '+x', '-x', '+y', '-y', '+z', or '-z'. Default is '+z'. Many
%      downloaded models (glTF, and many OBJ exports) use '+y'.
%
%      ForwardAxis: the file axis that points toward the FRONT of the
%      vehicle, in the same format. Default is '+x'. Must be a different
%      axis than UpAxis. Tip: plot the imported mesh, find the front
%      bumper, and read off which axis points toward it.
%
%      Units: the length units of the file: 'm', 'cm', 'mm', 'in', or
%      'auto' (the default). A positive number may also be given, as
%      the number of meters per file unit. With 'auto', the units are
%      guessed from the vehicle length:
%           longer than 1000       -> mm
%           300 to 1000            -> cm
%           100 to 300             -> in
%           otherwise              -> m
%      (The final size is set by fcn_CarMesh3D_fitMeshToSpec anyway, so a
%      wrong guess here only affects intermediate plots.)
%
%      FigNum: a figure number to plot the result. If empty or omitted, no
%      plot is made. If set to -1, input checking is skipped and no plot
%      is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with Vertices (and FaceNormals, if
%      present) changed, Units set to 'm', Frame set to 'ISO8855', and a
%      new field NormalizeInfo with fields RotationMatrix,
%      MetersPerFileUnit, and OffsetMeters (the shift that was applied
%      after rotating and scaling).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_normalizeMesh.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_normalizeMesh
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_normalizeMesh
%   % * Consider an 'auto' option for the axes (longest axis is forward)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.UpAxis = '+z'        % File axis that points up
    options.ForwardAxis = '+x'   % File axis that points to the vehicle front
    options.Units = 'auto'       % 'm','cm','mm','in','auto', or meters per unit
    options.FigNum = []          % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the vehicleMesh input
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces')
            error('vehicleMesh must be a CarMesh3D mesh structure with Vertices and Faces fields');
        end

        % Check the axis inputs
        upAxisIndex = fcn_INTERNAL_parseAxis(options.UpAxis, 'UpAxis');
        forwardAxisIndex = fcn_INTERNAL_parseAxis(options.ForwardAxis, 'ForwardAxis');
        if upAxisIndex==forwardAxisIndex
            error('UpAxis (%s) and ForwardAxis (%s) must be different axes',char(options.UpAxis),char(options.ForwardAxis));
        end

        % Check the Units input
        if isnumeric(options.Units)
            if ~isscalar(options.Units) || options.Units<=0
                error('A numeric Units value must be a positive scalar (meters per file unit)');
            end
        elseif ~any(strcmpi(char(options.Units),{'m','cm','mm','in','auto'}))
            error('Units must be ''m'', ''cm'', ''mm'', ''in'', ''auto'', or a positive number');
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

% Unit vectors, in file coordinates, of the new forward and up directions
[~, forwardUnitVector] = fcn_INTERNAL_parseAxis(options.ForwardAxis, 'ForwardAxis');
[~, upUnitVector]      = fcn_INTERNAL_parseAxis(options.UpAxis, 'UpAxis');
leftUnitVector = cross(upUnitVector, forwardUnitVector); % Y = Z x X, right-handed

% Rows of the rotation matrix are the new axes written in file coordinates
rotationMatrix = [forwardUnitVector; leftUnitVector; upUnitVector];

% Rotate (row vectors: v_new = v_old * R')
rotatedVertices = vehicleMesh.Vertices * rotationMatrix';

% Determine the units
if isnumeric(options.Units)
    metersPerFileUnit = options.Units;
else
    switch lower(char(options.Units))
        case 'm'
            metersPerFileUnit = 1;
        case 'cm'
            metersPerFileUnit = 0.01;
        case 'mm'
            metersPerFileUnit = 0.001;
        case 'in'
            metersPerFileUnit = 0.0254;
        otherwise % 'auto'
            vehicleLengthInFileUnits = max(rotatedVertices(:,1)) - min(rotatedVertices(:,1));
            if vehicleLengthInFileUnits > 1000
                metersPerFileUnit = 0.001;
            elseif vehicleLengthInFileUnits > 300
                metersPerFileUnit = 0.01;
            elseif vehicleLengthInFileUnits > 100
                metersPerFileUnit = 0.0254;
            else
                metersPerFileUnit = 1;
            end
    end
end
scaledVertices = rotatedVertices * metersPerFileUnit;

% Move the origin: centered in X and Y, lowest point at Z = 0
minValues = min(scaledVertices,[],1);
maxValues = max(scaledVertices,[],1);
offsetMeters = -[(minValues(1)+maxValues(1))/2, (minValues(2)+maxValues(2))/2, minValues(3)];
vehicleMesh.Vertices = scaledVertices + offsetMeters;

% Rotate any stored normals too (normals are not scaled or shifted)
if isfield(vehicleMesh,'FaceNormals') && ~isempty(vehicleMesh.FaceNormals)
    vehicleMesh.FaceNormals = vehicleMesh.FaceNormals * rotationMatrix';
end

vehicleMesh.Units = 'm';
vehicleMesh.Frame = 'ISO8855';
vehicleMesh.NormalizeInfo = struct(...
    'RotationMatrix', rotationMatrix,...
    'MetersPerFileUnit', metersPerFileUnit,...
    'OffsetMeters', offsetMeters);

if flag_do_debug
    fprintf(1,'Normalized mesh: %.3f m long, %.3f m wide, %.3f m high (%.4g m per file unit)\n',...
        maxValues(1)-minValues(1), maxValues(2)-minValues(2), maxValues(3)-minValues(3), metersPerFileUnit);
end

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
    figure(figNum);
    clf;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
    hold on;
    % Draw the frame axes: red = X forward, green = Y left, blue = Z up
    arrowLength = 1.0;
    quiver3(0,0,0,arrowLength,0,0,0,'r','LineWidth',2,'DisplayName','X forward');
    quiver3(0,0,0,0,arrowLength,0,0,'g','LineWidth',2,'DisplayName','Y left');
    quiver3(0,0,0,0,0,arrowLength,0,'b','LineWidth',2,'DisplayName','Z up');
    title(sprintf('Normalized: %s (red X should point to the front)',vehicleMesh.Name),'Interpreter','none');
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

%% fcn_INTERNAL_parseAxis
function [axisIndex, unitVector] = fcn_INTERNAL_parseAxis(axisString, optionName)
% Converts '+x', '-y', 'z', etc. into an axis index (1, 2, or 3) and a
% signed 1 x 3 unit vector
tokens = regexp(lower(strtrim(char(axisString))), '^([+-]?)([xyz])$', 'tokens', 'once');
if isempty(tokens)
    error('%s must be one of ''+x'', ''-x'', ''+y'', ''-y'', ''+z'', ''-z''. Found: %s', optionName, char(axisString));
end
axisIndex = find(strcmp(tokens{2},{'x','y','z'}));
signValue = 1;
if strcmp(tokens{1},'-')
    signValue = -1;
end
unitVector = zeros(1,3);
unitVector(axisIndex) = signValue;
end % Ends fcn_INTERNAL_parseAxis
