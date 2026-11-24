function vehicleMesh = fcn_CarMesh3D_mirrorMesh(vehicleMesh, options)
% fcn_CarMesh3D_mirrorMesh
% Mirrors a vehicle mesh left to right (y to -y), for a download of a
% right-hand-drive vehicle, so that every CarMesh3D mesh is left-hand
% drive (Sean, 2026-11-24 10:38: "it would be good for us to have all the
% meshes be natively left hand drive style"). Called in a vehicle's
% script right after fcn_CarMesh3D_normalizeMesh, before labeling and
% fitting, with importMirror = true.
%
% A mirror image turns every face inside out, so the corner order of each
% face is reversed as well: the faces still point outward. Stored normals
% are mirrored too. Everything else (labels, colors, materials, groups)
% stays with its face. Writing in textures (badges, plates) reads
% backward after a mirror; CarMesh3D draws face colors, so this shows
% only as a reversed badge shape.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_mirrorMesh(vehicleMesh, (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure (Vertices, Faces, ...) in
%      the vehicle frame (x forward, y left, z up), for example from
%      fcn_CarMesh3D_normalizeMesh.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: a figure to show the mesh before (gray) and after (blue),
%      seen from above. If empty or omitted, no plot is made. If -1,
%      input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mirrored mesh: y negated, each face's corner order
%      reversed, every N x 3 field whose name ends in "Normals" mirrored,
%      and MirrorInfo added (Mirrored = true, the date).
%
% DEPENDENCIES:
%
%      (none: base MATLAB only)
%
% EXAMPLES:
%
%       vehicleMesh = fcn_CarMesh3D_importMesh(modelPath);
%       vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+z', ForwardAxis='+y');
%       vehicleMesh = fcn_CarMesh3D_mirrorMesh(vehicleMesh);   % (a right-hand-drive download)
%
%       See the script: script_test_fcn_CarMesh3D_mirrorMesh.m for a
%       full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_mirrorMesh
%   % * First write of the code (Sean, 10:38): right-hand-drive downloads
%   %   % (the 2006 Frontier) mirrored to left-hand drive at import

% TO-DO:
%
% (none)


% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.FigNum = []           % Figure to plot into; [] for no plot, -1 for fast mode
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
    debug_figNum = 999977; %#ok<NASGU>
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
        if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces'}))
            error('CarMesh3D:badInput', 'vehicleMesh must be a mesh structure with Vertices and Faces.');
        end
        if size(vehicleMesh.Vertices,2) ~= 3 || size(vehicleMesh.Faces,2) ~= 3
            error('CarMesh3D:badInput', 'vehicleMesh.Vertices and vehicleMesh.Faces must be N x 3 and M x 3.');
        end
    end
end

% Make the plot?
flag_do_plots = 0; % Default is to NOT plot
if (0==flag_max_speed) && ~isempty(options.FigNum)
    flag_do_plots = 1;
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

originalVertices = vehicleMesh.Vertices;

% The mirror: y to -y
vehicleMesh.Vertices(:,2) = -vehicleMesh.Vertices(:,2);

% Each face's corners in the reverse order, so the face still points
% outward (a mirror turns the corner order from counterclockwise to
% clockwise, seen from outside)
vehicleMesh.Faces = vehicleMesh.Faces(:,[1 3 2]);

% Stored normals (face or vertex) mirrored the same way
fieldNames = fieldnames(vehicleMesh);
for ith_field = 1:numel(fieldNames)
    fieldName = fieldNames{ith_field};
    fieldValue = vehicleMesh.(fieldName);
    if endsWith(fieldName, 'Normals') && isnumeric(fieldValue) && size(fieldValue,2) == 3
        fieldValue(:,2) = -fieldValue(:,2);
        vehicleMesh.(fieldName) = fieldValue;
    end
end

vehicleMesh.MirrorInfo = struct('Mirrored', true, 'Date', char(datetime('now','Format','yyyy-MM-dd HH:mm')), ...
    'Note', 'mirrored left to right (y to -y) at import: a right-hand-drive download made left-hand drive');

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
    if ishandle(options.FigNum)
        figureHandle = figure(options.FigNum);
        clf(figureHandle);
    else
        figureHandle = figure(options.FigNum);
    end
    axesHandle = axes(figureHandle);
    hold(axesHandle, 'on');
    patch(axesHandle, 'Faces', vehicleMesh.Faces(:,[1 3 2]), 'Vertices', originalVertices, ...
        'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', 'before');
    patch(axesHandle, 'Faces', vehicleMesh.Faces, 'Vertices', vehicleMesh.Vertices, ...
        'FaceColor', [0.05 0.2 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'DisplayName', 'after (mirrored)');
    axis(axesHandle, 'equal');
    grid(axesHandle, 'on');
    view(axesHandle, 0, 90);
    xlabel(axesHandle, 'x (m, forward)'); ylabel(axesHandle, 'y (m, left)');
    legend(axesHandle, 'Location', 'best');
    title(axesHandle, 'fcn\_CarMesh3D\_mirrorMesh: before (gray) and after (blue), seen from above');
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
