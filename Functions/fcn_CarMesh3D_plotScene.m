function sceneHandles = fcn_CarMesh3D_plotScene(options)
% fcn_CarMesh3D_plotScene
% Draws a simple scene for a vehicle to drive in: a flat ground plane
% with grid lines, optional colored cubes (things for a driver-view or
% roof camera to "see" go by), and an optional path line. The scene is
% drawn in the current axes (or the given figure), so plot the scene
% first, then the vehicle.
%
% TimeOfDay='night' makes a dark scene: a dark sky and ground, and dim
% bluish "moonlight", so a vehicle's lights stand out. Plot the vehicle
% with fcn_CarMesh3D_plotVehicle(..., LightEffects=true) to add glows
% around lit lamps and pools of light on the ground (headlight beams).
%
% FORMAT:
%
%       sceneHandles = fcn_CarMesh3D_plotScene(...
%           (GroundExtent=[xmin xmax ymin ymax]),...
%           (GridSpacing=meters), (GroundColor=[r g b]),...
%           (Cubes=cubeList), (PathXY=xy), (TimeOfDay=timeOfDay),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      GroundExtent: [xmin xmax ymin ymax] of the ground, in meters.
%      Default is [-40 40 -40 40].
%
%      GridSpacing: the spacing of the grid lines, in meters. Default 5.
%      Set to 0 for no grid lines.
%
%      GroundColor: [r g b] of the ground. Default is [] (automatic):
%      [0.55 0.60 0.55] by day, [0.22 0.22 0.25] (dark asphalt) at night.
%
%      Cubes: an N x 4 list of cubes, [x y size colorIndex], each sitting
%      on the ground. colorIndex picks a color from a fixed palette
%      (1 red, 2 orange, 3 yellow, 4 green, 5 blue, 6 purple). Default
%      is [] (no cubes).
%
%      PathXY: an N x 2 list of [x y] points to draw as a dashed line on
%      the ground. Default is [] (no path line).
%
%      TimeOfDay: 'day' (default) or 'night'. At night, this function
%      also sets the figure and axes background to a dark sky, dims the
%      axes ambient light (AmbientLightColor), and adds two dim, bluish
%      scene lights ("moonlight") if the axes has no lights yet. Because
%      the axes then has lights, fcn_CarMesh3D_plotVehicle does not add
%      its bright daytime lights, so plot the scene first.
%
%      FigNum: a figure number to draw into. If empty or omitted, draws
%      into the current figure. If set to -1, input checking is skipped
%      and the scene also goes into the current figure.
%
% OUTPUTS:
%
%      sceneHandles: a structure with fields Ground (patch), GridLines
%      (line), Cubes (patch, or []), Path (line, or []), Lights (the
%      lights added at night, or []), TimeOfDay, and Axes.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_plotScene.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotScene
%   % * Wrote the code originally (drafted with Claude)
%   % * Added TimeOfDay ('day' or 'night'); GroundColor default is now
%   %   automatic

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotScene
%   % * Add road strips and lane markings



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.GroundExtent = [-40 40 -40 40] % [xmin xmax ymin ymax], meters
    options.GridSpacing = 5                % meters; 0 for no grid
    options.GroundColor = []               % [r g b]; [] for automatic (day or night)
    options.Cubes = []                     % N x 4 [x y size colorIndex]
    options.PathXY = []                    % N x 2 [x y] path to draw
    options.TimeOfDay = 'day'              % 'day' or 'night'
    options.FigNum = []                    % Figure to draw into; [] for current figure, -1 for fast mode
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

        % Check the GroundExtent input
        if ~isnumeric(options.GroundExtent) || numel(options.GroundExtent)~=4 || ...
                options.GroundExtent(2)<=options.GroundExtent(1) || options.GroundExtent(4)<=options.GroundExtent(3)
            error('GroundExtent must be [xmin xmax ymin ymax] with xmax > xmin and ymax > ymin');
        end

        % Check the GridSpacing input
        if ~isnumeric(options.GridSpacing) || ~isscalar(options.GridSpacing) || options.GridSpacing<0
            error('GridSpacing must be a non-negative number of meters');
        end

        % Check the GroundColor input
        if ~isempty(options.GroundColor) && (~isnumeric(options.GroundColor) || ~isequal(size(options.GroundColor),[1 3]) || any(options.GroundColor<0) || any(options.GroundColor>1))
            error('GroundColor must be empty or a 1 x 3 RGB vector with values from 0 to 1');
        end

        % Check the TimeOfDay input
        if ~(ischar(options.TimeOfDay) || isstring(options.TimeOfDay)) || ~any(strcmpi(char(options.TimeOfDay),{'day','night'}))
            error('TimeOfDay must be ''day'' or ''night''');
        end

        % Check the Cubes input
        if ~isempty(options.Cubes) && (~isnumeric(options.Cubes) || size(options.Cubes,2)~=4)
            error('Cubes must be an N x 4 list of [x y size colorIndex]');
        end

        % Check the PathXY input
        if ~isempty(options.PathXY) && (~isnumeric(options.PathXY) || size(options.PathXY,2)<2)
            error('PathXY must be an N x 2 list of [x y] points');
        end
    end
end

% Which figure to draw into? Drawing is the purpose of this function, so
% it always draws: into the given figure, or else into the current figure.
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

% Select the figure and axes, without clearing them
if isempty(figNum)
    figureHandle = gcf;
else
    figureHandle = figure(figNum);
end
axesHandle = get(figureHandle,'CurrentAxes');
if isempty(axesHandle)
    axesHandle = axes('Parent',figureHandle);
end
hold(axesHandle,'on');

extent = options.GroundExtent;
groundZ = -0.01; % Just below the tires, so they are not hidden

% Day or night colors
flagNight = strcmpi(char(options.TimeOfDay),'night');
groundColor = options.GroundColor;
if isempty(groundColor)
    if flagNight
        groundColor = [0.22 0.22 0.25]; % Dark asphalt
    else
        groundColor = [0.55 0.60 0.55];
    end
end
if flagNight
    gridColor = min(1.5*groundColor, 1);   % Grid lines a little lighter than the ground
    pathColor = [0.55 0.55 0.60];
else
    gridColor = 0.85*groundColor;          % Grid lines a little darker than the ground
    pathColor = [1 1 1];
end

% Ground
sceneHandles = struct;
sceneHandles.Ground = patch(axesHandle, ...
    'XData',[extent(1) extent(2) extent(2) extent(1)], ...
    'YData',[extent(3) extent(3) extent(4) extent(4)], ...
    'ZData',groundZ*[1 1 1 1], ...
    'FaceColor',groundColor,'EdgeColor','none', ...
    'FaceLighting','flat','AmbientStrength',0.7,'DiffuseStrength',0.5,'SpecularStrength',0, ...
    'HandleVisibility','off');

% Grid lines (one line object, with NaN breaks, for speed)
sceneHandles.GridLines = [];
if options.GridSpacing>0
    xLines = (ceil(extent(1)/options.GridSpacing):floor(extent(2)/options.GridSpacing))*options.GridSpacing;
    yLines = (ceil(extent(3)/options.GridSpacing):floor(extent(4)/options.GridSpacing))*options.GridSpacing;
    lineX = [reshape([xLines; xLines; nan(size(xLines))],[],1); reshape([extent(1)*ones(size(yLines)); extent(2)*ones(size(yLines)); nan(size(yLines))],[],1)];
    lineY = [reshape([extent(3)*ones(size(xLines)); extent(4)*ones(size(xLines)); nan(size(xLines))],[],1); reshape([yLines; yLines; nan(size(yLines))],[],1)];
    sceneHandles.GridLines = plot3(axesHandle, lineX, lineY, (groundZ+0.005)*ones(size(lineX)), '-', ...
        'Color',gridColor,'LineWidth',0.5,'HandleVisibility','off');
end

% Cubes (all in one patch)
sceneHandles.Cubes = [];
if ~isempty(options.Cubes)
    palette = [0.85 0.15 0.15; 0.95 0.55 0.10; 0.95 0.85 0.15; 0.25 0.70 0.30; 0.20 0.45 0.85; 0.55 0.30 0.75];
    [cubeVertices, cubeFaces, cubeColors] = fcn_INTERNAL_cubes(options.Cubes, palette);
    sceneHandles.Cubes = patch(axesHandle,'Faces',cubeFaces,'Vertices',cubeVertices, ...
        'FaceVertexCData',cubeColors,'FaceColor','flat','EdgeColor',[0.2 0.2 0.2], ...
        'FaceLighting','flat','HandleVisibility','off');
end

% Path line
sceneHandles.Path = [];
if ~isempty(options.PathXY)
    sceneHandles.Path = plot3(axesHandle, options.PathXY(:,1), options.PathXY(:,2), (groundZ+0.01)*ones(size(options.PathXY,1),1), ...
        '--','Color',pathColor,'LineWidth',1.5,'HandleVisibility','off');
end

% Night: dark sky, dim ambient light, and dim bluish "moonlight"
sceneHandles.Lights = [];
if flagNight
    skyColor = [0.03 0.04 0.08];
    set(figureHandle,'Color',skyColor);
    set(axesHandle,'Color',skyColor,'AmbientLightColor',[0.35 0.38 0.55]);
    if isempty(findobj(axesHandle,'Type','light'))
        sceneHandles.Lights = [ ...
            light('Parent',axesHandle,'Style','infinite','Position',[-1 -2 3],'Color',[0.30 0.33 0.45]); ...
            light('Parent',axesHandle,'Style','infinite','Position',[2 1.5 1],'Color',[0.08 0.08 0.11])];
    end
end
sceneHandles.TimeOfDay = lower(char(options.TimeOfDay));

axis(axesHandle,'equal');
sceneHandles.Axes = axesHandle;

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
% (Drawing is the purpose of this function, so there is no extra plot)

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

%% fcn_INTERNAL_cubes
function [vertices, faces, faceColors] = fcn_INTERNAL_cubes(cubeList, palette)
% Vertices and quad faces for a list of cubes sitting on the ground
unitVertices = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1] - [0.5 0.5 0];
unitFaces = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
Ncubes = size(cubeList,1);
vertices = zeros(8*Ncubes,3);
faces = zeros(6*Ncubes,4);
faceColors = zeros(6*Ncubes,3);
for ith_cube = 1:Ncubes
    center = [cubeList(ith_cube,1:2) 0];
    cubeSize = cubeList(ith_cube,3);
    colorIndex = mod(round(cubeList(ith_cube,4))-1, size(palette,1)) + 1;
    vertices((ith_cube-1)*8+(1:8),:) = unitVertices*cubeSize + center;
    faces((ith_cube-1)*6+(1:6),:) = unitFaces + (ith_cube-1)*8;
    faceColors((ith_cube-1)*6+(1:6),:) = repmat(palette(colorIndex,:),6,1);
end
end % Ends fcn_INTERNAL_cubes
