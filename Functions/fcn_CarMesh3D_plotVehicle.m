function plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, options)
% fcn_CarMesh3D_plotVehicle
% Plots a CarMesh3D vehicle mesh as a small number of patch objects:
% one patch for all opaque faces, and one patch for each level of
% transparency (typically the glass). All patches sit under one
% hgtransform object, so the vehicle can be moved and rotated for
% animation by changing a single transform matrix, without re-sending
% the mesh to the graphics system.
%
% Typical animation use:
%
%       h = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=1);
%       for k = 1:N
%           fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[x(k) y(k) yaw(k)],...
%               PlotHandles=h, FigNum=-1);
%           drawnow limitrate;
%       end
%
% FORMAT:
%
%       plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh,...
%           (Pose=pose),...
%           (PlotHandles=plotHandles),...
%           (ShowEdges=flagShowEdges),...
%           (FaceLighting=lightingString),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure. If it has FaceColors and
%      FaceAlpha fields (from fcn_CarMesh3D_labelParts), those are used.
%      Otherwise the material colors and alphas are used, and faces with
%      no known color are drawn in light gray.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Pose: the vehicle position and orientation, as either
%           [x y yaw] (planar motion, yaw in radians), or
%           [x y z roll pitch yaw] (angles in radians).
%      The rotation order is yaw, then pitch, then roll (Z-Y-X), about the
%      mesh origin. Default is no motion: [0 0 0 0 0 0].
%
%      PlotHandles: the output of a previous call. If given and still
%      valid, the function ONLY updates the pose of that plot (fast path
%      for animation) and does not redraw the mesh.
%
%      ShowEdges: true to draw face edges (useful for checking a mesh),
%      false (default) to hide them.
%
%      FaceLighting: 'flat' (default, crisp low-poly look), 'gouraud'
%      (smooth shading), or 'none'.
%
%      FigNum: a figure number to plot into. If empty or omitted, plots
%      into the current figure (creating one if none exists). If set to
%      -1, input checking is skipped and the plot also goes into the
%      current figure.
%
% OUTPUTS:
%
%      plotHandles: a structure with fields
%           Transform: the hgtransform holding all of the patches
%           Patches: an [P x 1] cell array of patch handles
%           Axes: the axes that were plotted into
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_plotVehicle.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Add a Scale option for plotting many vehicles on large maps
%   % * Consider steering the front wheels (needs per-wheel transforms)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    options.Pose = [0 0 0 0 0 0]    % [x y yaw] or [x y z roll pitch yaw]
    options.PlotHandles = []        % Handles from a prior call, for fast updates
    options.ShowEdges = false       % Draw face edges?
    options.FaceLighting = 'flat'   % 'flat', 'gouraud', or 'none'
    options.FigNum = []             % Figure to plot into; [] for current figure, -1 for fast mode
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
        if size(vehicleMesh.Vertices,2)~=3 || size(vehicleMesh.Faces,2)~=3
            error('vehicleMesh.Vertices must be N x 3 and vehicleMesh.Faces must be M x 3');
        end

        % Check the Pose input
        if ~isnumeric(options.Pose) || ~any(numel(options.Pose)==[3 6]) || any(~isfinite(options.Pose))
            error('Pose must be a finite numeric [x y yaw] or [x y z roll pitch yaw]');
        end

        % Check the PlotHandles input
        if ~isempty(options.PlotHandles)
            if ~isstruct(options.PlotHandles) || ~isfield(options.PlotHandles,'Transform')
                error('PlotHandles must be the structure returned by a prior call to fcn_CarMesh3D_plotVehicle');
            end
        end

        % Check the ShowEdges input
        if ~(islogical(options.ShowEdges) || isnumeric(options.ShowEdges)) || ~isscalar(options.ShowEdges)
            error('ShowEdges must be true or false');
        end

        % Check the FaceLighting input
        if ~any(strcmpi(char(options.FaceLighting),{'flat','gouraud','none'}))
            error('FaceLighting must be ''flat'', ''gouraud'', or ''none''');
        end
    end
end

% Which figure to plot into? Plotting is the purpose of this function, so
% it always plots: into the given figure, or else into the current figure.
figNum = []; % Default is to use the current figure
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
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

% Build the pose transform matrix
poseMatrix = fcn_INTERNAL_poseToMatrix(options.Pose);

% Fast path: only update the pose of an existing plot
flag_update_only = false;
if ~isempty(options.PlotHandles)
    if isgraphics(options.PlotHandles.Transform)
        flag_update_only = true;
    end
end

if flag_update_only
    plotHandles = options.PlotHandles;
    plotHandles.Transform.Matrix = poseMatrix;
else
    % Select the figure, without clearing it
    if isempty(figNum)
        temp_h = gcf;
    else
        temp_h = figure(figNum);
    end
    axesHandle = get(temp_h,'CurrentAxes');
    if isempty(axesHandle)
        axesHandle = axes('Parent',temp_h);
    end
    flag_this_is_a_new_axes = isempty(get(axesHandle,'Children'));

    % Get face colors and alphas
    [faceColors, faceAlpha] = fcn_INTERNAL_faceColorsAndAlpha(vehicleMesh);

    % Edge settings
    if options.ShowEdges
        edgeColor = [0.2 0.2 0.2];
    else
        edgeColor = 'none';
    end

    % One transform for the whole vehicle
    transformHandle = hgtransform('Parent',axesHandle);

    % Group the faces by alpha: opaque first, then each transparent level
    alphaLevels = unique(round(faceAlpha*1000)/1000);
    alphaLevels = sort(alphaLevels,'descend');
    numPatches = length(alphaLevels);
    patchHandles = cell(numPatches,1);
    for ith_level = 1:numPatches
        thisAlpha = alphaLevels(ith_level);
        theseFaces = abs(round(faceAlpha*1000)/1000 - thisAlpha) < 1e-9;
        if thisAlpha >= 0.999
            displayName = 'Opaque surfaces';
        else
            displayName = sprintf('Transparent surfaces (alpha %.2f)',thisAlpha);
        end
        patchHandles{ith_level} = patch('Parent',transformHandle,...
            'Faces',vehicleMesh.Faces(theseFaces,:),...
            'Vertices',vehicleMesh.Vertices,...
            'FaceVertexCData',faceColors(theseFaces,:),...
            'FaceColor','flat',...
            'FaceAlpha',thisAlpha,...
            'EdgeColor',edgeColor,...
            'FaceLighting',lower(char(options.FaceLighting)),...
            'BackFaceLighting','lit',...
            'AmbientStrength',0.55,...
            'DiffuseStrength',0.65,...
            'SpecularStrength',0.25,...
            'DisplayName',displayName);
    end

    % Set the pose
    transformHandle.Matrix = poseMatrix;

    % Add a light if the axes has none
    if isempty(findobj(axesHandle,'Type','light'))
        light('Parent',axesHandle,'Style','infinite','Position',[-1 -2 3]);
    end

    % Format a new axes
    if flag_this_is_a_new_axes
        axis(axesHandle,'equal');
        grid(axesHandle,'on');
        view(axesHandle,-35,20);
        xlabel(axesHandle,'X [m] (forward)');
        ylabel(axesHandle,'Y [m] (left)');
        zlabel(axesHandle,'Z [m] (up)');
        if isfield(vehicleMesh,'Name')
            title(axesHandle,vehicleMesh.Name,'Interpreter','none');
        end
    end

    plotHandles = struct;
    plotHandles.Transform = transformHandle;
    plotHandles.Patches = patchHandles;
    plotHandles.Axes = axesHandle;
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

%% fcn_INTERNAL_poseToMatrix
function poseMatrix = fcn_INTERNAL_poseToMatrix(pose)
% Converts [x y yaw] or [x y z roll pitch yaw] into a 4 x 4 transform
pose = pose(:)';
if numel(pose)==3
    pose = [pose(1) pose(2) 0 0 0 pose(3)];
end
poseMatrix = makehgtform('translate',pose(1:3)) * ...
    makehgtform('zrotate',pose(6)) * ...
    makehgtform('yrotate',pose(5)) * ...
    makehgtform('xrotate',pose(4));
end % Ends fcn_INTERNAL_poseToMatrix

%% fcn_INTERNAL_faceColorsAndAlpha
function [faceColors, faceAlpha] = fcn_INTERNAL_faceColorsAndAlpha(vehicleMesh)
% Returns an M x 3 color and M x 1 alpha for every face. Labeled meshes
% carry these directly; otherwise they come from the materials.
Nfaces = size(vehicleMesh.Faces,1);
defaultColor = [0.75 0.75 0.75];

if isfield(vehicleMesh,'FaceColors') && ~isempty(vehicleMesh.FaceColors)
    faceColors = vehicleMesh.FaceColors;
    if isfield(vehicleMesh,'FaceAlpha') && ~isempty(vehicleMesh.FaceAlpha)
        faceAlpha = vehicleMesh.FaceAlpha;
    else
        faceAlpha = ones(Nfaces,1);
    end
else
    faceColors = repmat(defaultColor, Nfaces, 1);
    faceAlpha = ones(Nfaces,1);
    if isfield(vehicleMesh,'FaceMaterialIndex') && isfield(vehicleMesh,'MaterialColors') ...
            && ~isempty(vehicleMesh.MaterialColors)
        materialIndex = vehicleMesh.FaceMaterialIndex;
        flagHasMaterial = materialIndex>0;
        faceColors(flagHasMaterial,:) = vehicleMesh.MaterialColors(materialIndex(flagHasMaterial),:);
        if isfield(vehicleMesh,'MaterialAlpha') && ~isempty(vehicleMesh.MaterialAlpha)
            faceAlpha(flagHasMaterial) = vehicleMesh.MaterialAlpha(materialIndex(flagHasMaterial));
        end
    end
    % Any unknown (NaN) colors become the default gray
    flagUnknown = any(isnan(faceColors),2);
    faceColors(flagUnknown,:) = repmat(defaultColor, sum(flagUnknown), 1);
    faceAlpha(isnan(faceAlpha)) = 1;
end

% Keep the values in range
faceColors = min(max(faceColors,0),1);
faceAlpha = min(max(faceAlpha,0),1);
end % Ends fcn_INTERNAL_faceColorsAndAlpha
