function plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, options)
% fcn_CarMesh3D_plotVehicle
% Plots a CarMesh3D vehicle mesh as a small number of patch objects:
% one patch for the opaque body, one for each level of transparency
% (typically the glass), one per wheel, and one per group of switchable
% lights. Everything sits under one hgtransform, so the vehicle moves by
% changing a single transform matrix. Each wheel has its own transform
% inside that one, so wheels can spin and the front wheels can steer, and
% each light group can be switched on and off, all without re-sending
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
%           (EdgeColor=[r g b]),...
%           (Finish=finishSetting),...
%           (FaceLighting=lightingString),...
%           (SceneLights=sceneLightsString),...
%           (WheelSpin=spinAngles),...
%           (SteerAngle=steerAngles),...
%           (LightStates=lightStates),...
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
%      EdgeColor: a 1 x 3 RGB color (values from 0 to 1) for the face
%      edges, used when ShowEdges is true. Default is [0.2 0.2 0.2].
%
%      Finish: how shiny the surface looks. One of
%           'matte'    (default) soft, no strong highlights
%           'satin'    some highlight
%           'glossy'   sharp white highlights, like clear-coated paint
%           'metallic' strong highlights tinted by the surface color
%      or a numeric vector [ka kd ks n sc], as for MATLAB's material
%      command: ambient, diffuse, and specular strengths, specular
%      exponent (bigger = smaller, sharper highlights), and specular
%      color reflectance (1 = highlights in the light's color, white;
%      0 = highlights tinted by the surface color).
%
%      FaceLighting: 'auto' (default), 'flat', 'gouraud', or 'none'.
%      'flat' gives a crisp low-poly look, with one shade per face.
%      'gouraud' blends shading smoothly across faces, which glossy
%      highlights need, and hides the facets of a reduced mesh. 'auto'
%      uses 'gouraud' for every finish.
%
%      SceneLights: 'auto' (default) adds two lights to the axes if it has
%      none: a white main light from above, to the front-left of the
%      default view, and a dim gray fill light from the other side.
%      'none' adds no lights, so you can place your own with light() or
%      camlight().
%
%      WheelSpin: how far each wheel has rolled, in radians, as a scalar
%      (all four wheels) or a 1 x 4 vector [FL FR RL RR]. Positive is
%      forward rolling. For rolling without slip, use distance traveled
%      divided by the tire radius (fcn_CarMesh3D_fillTrajectory does
%      this). Default is 0.
%
%      SteerAngle: the steer angle of the front wheels, in radians, as a
%      scalar (both) or 1 x 2 [FL FR]. Positive steers left. Default 0.
%      For different left and right angles in a turn (the inside tire
%      steers more), see fcn_CarMesh3D_calcAckermannSteering.
%
%      WheelLift: how far each wheel is lifted off the ground, in meters,
%      as a scalar (all four) or 1 x 4 [FL FR RL RR]. Default 0. Use it
%      for the rare case of wheel lift; in normal driving the wheels stay
%      on the ground and the body moves on them (BodyHeave, BodyRoll,
%      BodyPitch).
%
%      BodyRoll, BodyPitch, BodyHeave: motion of the body (the sprung
%      mass) relative to the wheels (the unsprung mass), which stay on
%      the ground. Roll and pitch are in radians, heave in meters. These
%      come from your own vehicle dynamics model (this function does not
%      calculate them). Signs follow ISO 8855 (X forward, Y left, Z up):
%           BodyRoll  > 0  rotates about +X: the right side goes down
%                          (as in a left turn)
%           BodyPitch > 0  rotates about +Y: the nose goes down (as in
%                          braking)
%           BodyHeave > 0  the body moves up
%      Default 0 for each. Roll and pitch are applied about BodyPivot.
%
%      BodyPivot: the point [x y z], in the vehicle frame, that the body
%      rolls and pitches about. Default [] puts it midway between the
%      axles, on the centerline, at the height of the wheel centers.
%
%      LightStates: a structure that switches the vehicle's lights. Any
%      field may be left out (it then stays off):
%           Headlights: 'off', 'low', or 'high'
%           TurnLeft, TurnRight: true or false (blink them in your loop)
%           Running: true or false (front running lights)
%           Tail: 'off', 'on', or 'brake' (rear lights)
%           Backup: true or false
%      Lights need light faces with light types, from fcn_CarMesh3D_labelParts
%      or fcn_CarMesh3D_editLabels. Turn signals are split into left and
%      right by position. A light that is on is drawn unshaded, so it
%      appears to glow. Default is [] (lights keep their plain colors).
%      WheelSpin, SteerAngle, WheelLift, BodyRoll, BodyPitch, BodyHeave,
%      and LightStates can all be changed on the fast path (with PlotHandles)
%      for animation.
%
%      LightEffects: true to "fake" light shining from the lamps, for
%      night scenes (see fcn_CarMesh3D_plotScene with TimeOfDay='night').
%      Default is false. Two effects are added, each shown only while its
%      light is on:
%           Glows: a see-through shell, slightly larger than each lamp,
%               in the lamp's color, so lit lamps seem to bloom.
%           Pools of light on the ground: a fading, see-through shape in
%               the light's color, ahead of the headlights (short and wide
%               for low beams; long and narrow added for high beams) and
%               behind the tail lights (dim red when on, brighter red when
%               braking, white when backing up).
%      These are drawn shapes, not MATLAB light objects: MATLAB lights
%      shine in every direction, do not fade with distance, and cast no
%      shadows, so they cannot make a beam. The pools do not light up
%      other objects (such as cubes), and they ride with the vehicle's
%      ground frame, so they stay flat on the ground when the body rolls
%      or pitches.
%
%      FigNum: a figure number to plot into. If empty or omitted, plots
%      into the current figure (creating one if none exists). If set to
%      -1, input checking is skipped and the plot also goes into the
%      current figure.
%
% OUTPUTS:
%
%      plotHandles: a structure with fields
%           Transform: the hgtransform holding the whole vehicle
%               (the ground frame: moved by Pose)
%           BodyTransform: the hgtransform holding the body and lights
%               (the sprung mass: BodyRoll, BodyPitch, BodyHeave). It
%               sits inside Transform, beside the wheel transforms.
%           Patches: a [P x 1] cell array of all patch handles
%           Axes: the axes that were plotted into
%           WheelTransforms: 4 x 1 cell of hgtransforms, one per wheel
%               ([] for wheels not found)
%           WheelCenters: 4 x 3 wheel centers in the vehicle frame
%           BodyPivot: 1 x 3 point the body rolls and pitches about
%           LightPatches: a structure with one patch handle (or []) per
%               light group: headlight, turnLeft, turnRight, running,
%               tail, backup
%           LightOffColors, FaceLighting: used to switch lights back off
%           LightEffects: [] or, with LightEffects=true, a structure with
%               Glow (one patch or [] per light group) and Pools (patches
%               lowBeam, highBeam, tail, brake, backup, each or [])
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_plotVehicle.m for a full test
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
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Added Finish (matte, satin, glossy, metallic, or [ka kd ks n sc])
%   % * Added EdgeColor; FaceLighting now defaults to 'auto'
%   % * A soft fill light is added with the main light
%   % * Normals are now given to MATLAB explicitly. MATLAB's automatic
%   %   % patch normals point opposite to the right-hand rule (inward for
%   %   % CarMesh3D meshes), which hid specular highlights
%   % * Wheels spin (WheelSpin) and front wheels steer (SteerAngle)
%   % * Switchable lights (LightStates); SceneLights option
%   % * Split the vehicle into two rigid frames: the body and lights
%   %   (sprung mass, BodyTransform) and the wheels (unsprung mass). Added
%   %   BodyRoll, BodyPitch, BodyHeave, and BodyPivot options.
%   % * Added LightEffects: glows around lit lamps and pools of light on
%   %   the ground (headlight beams, tail, brake, backup), for night scenes
%   % * Added WheelLift (wheels lifted off the ground, per wheel)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * An axes holding only hidden-handle objects (a scene drawn with
%   %   % HandleVisibility 'off') is not treated as new, and hidden lights
%   %   % count as lights (asked for by AnimateCar3D)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * FaceLighting 'auto' is now always 'gouraud' (smooth), also for the
%   %   % matte finish: flat shading showed every facet of a reduced mesh

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Add a Scale option for plotting many vehicles on large maps
%   % * Add wheel camber/suspension motion if needed



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
    options.EdgeColor = [0.2 0.2 0.2] % Edge color, used when ShowEdges is true
    options.Finish = 'matte'        % 'matte','satin','glossy','metallic', or [ka kd ks n sc]
    options.FaceLighting = 'auto'   % 'auto', 'flat', 'gouraud', or 'none'
    options.SceneLights = 'auto'    % 'auto' (add key and fill lights) or 'none'
    options.WheelSpin = 0           % Wheel rotation angle(s) [rad], scalar or 1 x 4
    options.SteerAngle = 0          % Front wheel steer angle [rad], scalar or 1 x 2
    options.WheelLift = 0           % Wheel height above the ground [m], scalar or 1 x 4 [FL FR RL RR]
    options.BodyRoll = 0            % Body roll relative to the wheels [rad], + right side down
    options.BodyPitch = 0           % Body pitch relative to the wheels [rad], + nose down
    options.BodyHeave = 0           % Body rise relative to the wheels [m], + up
    options.BodyPivot = []          % [x y z] point the body rolls and pitches about
    options.LightStates = []        % Struct of light states (see help)
    options.LightEffects = false    % Glows and ground light pools, for night scenes
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

        % Check the WheelLift input
        if ~isnumeric(options.WheelLift) || ~any(numel(options.WheelLift)==[1 4]) || any(~isfinite(options.WheelLift))
            error('WheelLift must be a finite scalar or a 1 x 4 vector [FL FR RL RR], in meters');
        end

        % Check the body motion inputs
        bodyNames = {'BodyRoll','BodyPitch','BodyHeave'};
        for ith_name = 1:3
            thisValue = options.(bodyNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || ~isfinite(thisValue)
                error('%s must be a finite number', bodyNames{ith_name});
            end
        end
        if ~isempty(options.BodyPivot) && (~isnumeric(options.BodyPivot) || numel(options.BodyPivot)~=3 || any(~isfinite(options.BodyPivot)))
            error('BodyPivot must be empty or a point [x y z] in meters');
        end

        % Check the LightEffects input
        if ~(islogical(options.LightEffects) || isnumeric(options.LightEffects)) || ~isscalar(options.LightEffects)
            error('LightEffects must be true or false');
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

        % Check the EdgeColor input
        if ~isnumeric(options.EdgeColor) || ~isequal(size(options.EdgeColor),[1 3]) || any(options.EdgeColor<0) || any(options.EdgeColor>1)
            error('EdgeColor must be a 1 x 3 RGB vector with values from 0 to 1');
        end

        % Check the Finish input
        if isnumeric(options.Finish)
            if numel(options.Finish)~=5 || any(~isfinite(options.Finish)) || any(options.Finish<0)
                error('A numeric Finish must be [ka kd ks n sc], all non-negative');
            end
        elseif ~any(strcmpi(char(options.Finish),{'matte','satin','glossy','metallic'}))
            error('Finish must be ''matte'', ''satin'', ''glossy'', ''metallic'', or a vector [ka kd ks n sc]');
        end

        % Check the SceneLights input
        if ~any(strcmpi(char(options.SceneLights),{'auto','none'}))
            error('SceneLights must be ''auto'' or ''none''');
        end

        % Check the WheelSpin and SteerAngle inputs
        if ~isnumeric(options.WheelSpin) || ~any(numel(options.WheelSpin)==[1 4]) || any(~isfinite(options.WheelSpin))
            error('WheelSpin must be a finite scalar or a 1 x 4 vector [FL FR RL RR], in radians');
        end
        if ~isnumeric(options.SteerAngle) || ~any(numel(options.SteerAngle)==[1 2]) || any(~isfinite(options.SteerAngle))
            error('SteerAngle must be a finite scalar or a 1 x 2 vector [FL FR], in radians');
        end

        % Check the LightStates input
        if ~isempty(options.LightStates)
            if ~isstruct(options.LightStates)
                error('LightStates must be a structure (see help fcn_CarMesh3D_plotVehicle)');
            end
            allowedFields = {'Headlights','TurnLeft','TurnRight','Running','Tail','Backup'};
            givenFields = fieldnames(options.LightStates);
            unknownFields = setdiff(givenFields, allowedFields);
            if ~isempty(unknownFields)
                error('Unknown LightStates field(s): %s. Allowed: %s', strjoin(unknownFields,', '), strjoin(allowedFields,', '));
            end
        end

        % Check the FaceLighting input
        if ~any(strcmpi(char(options.FaceLighting),{'auto','flat','gouraud','none'}))
            error('FaceLighting must be ''auto'', ''flat'', ''gouraud'', or ''none''');
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

% Fast path: only update the pose (and wheels and lights) of an existing plot
flag_update_only = false;
if ~isempty(options.PlotHandles)
    if isgraphics(options.PlotHandles.Transform)
        flag_update_only = true;
    end
end

if flag_update_only
    plotHandles = options.PlotHandles;
    plotHandles.Transform.Matrix = poseMatrix;
    fcn_INTERNAL_updateBody(plotHandles, options);
    fcn_INTERNAL_updateWheels(plotHandles, options.WheelSpin, options.SteerAngle, options.WheelLift);
    if ~isempty(options.LightStates)
        fcn_INTERNAL_updateLights(plotHandles, options.LightStates);
    end
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
    % (hidden-handle objects count too: a scene drawn with hidden handles,
    % such as AnimateCar3D's, is not a new axes)
    flag_this_is_a_new_axes = isempty(allchild(axesHandle));

    % Get face colors and alphas
    [faceColors, faceAlpha] = fcn_INTERNAL_faceColorsAndAlpha(vehicleMesh);
    Nfaces = size(vehicleMesh.Faces,1);

    % Edge settings
    if options.ShowEdges
        edgeColor = options.EdgeColor;
    else
        edgeColor = 'none';
    end

    % Surface finish: [ambient diffuse specular exponent colorReflectance]
    [finishValues, finishName] = fcn_INTERNAL_finishValues(options.Finish);
    faceLighting = lower(char(options.FaceLighting));
    if strcmp(faceLighting,'auto')
        faceLighting = 'gouraud';      % (smooth: reduced meshes look faceted with 'flat')
    end
    patchStyle = struct('EdgeColor',{edgeColor},'FaceLighting',faceLighting,'Finish',finishValues);

    % Which faces are wheels (each turned by its own transform), and which
    % are switchable lights (each group recolored by its own patch)?
    faceWheel = zeros(Nfaces,1);
    if isfield(vehicleMesh,'FaceWheelIndex') && ~isempty(vehicleMesh.FaceWheelIndex)
        faceWheel = vehicleMesh.FaceWheelIndex(:);
    end
    faceLightGroup = fcn_INTERNAL_faceLightGroups(vehicleMesh);
    lightGroupNames = fcn_INTERNAL_lightGroupNames;

    % Two rigid frames under one transform for the whole vehicle:
    %   transformHandle      ground frame, moved by Pose
    %     bodyTransform      sprung mass: body and lights (roll, pitch, heave)
    %     wheelTransforms    unsprung mass: one per wheel (spin, steer)
    transformHandle = hgtransform('Parent',axesHandle);
    bodyTransform = hgtransform('Parent',transformHandle);
    patchHandles = {};

    % Body (everything that is not a wheel or a switchable light), one
    % patch per alpha level: opaque first, then each transparent level
    flagBody = faceWheel==0 & faceLightGroup==0;
    newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, find(flagBody), faceColors, faceAlpha, patchStyle, bodyTransform);
    patchHandles = [patchHandles; newPatches];

    % Wheels: each under its own transform, which spins and steers it
    wheelTransforms = cell(4,1);
    wheelCenters = nan(4,3);
    for ith_wheel = 1:4
        theseFaces = find(faceWheel==ith_wheel);
        if isempty(theseFaces)
            continue;
        end
        wheelVertices = vehicleMesh.Vertices(unique(vehicleMesh.Faces(theseFaces,:)),:);
        wheelCenters(ith_wheel,:) = (min(wheelVertices,[],1) + max(wheelVertices,[],1))/2;
        wheelTransforms{ith_wheel} = hgtransform('Parent',transformHandle);
        newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces, faceColors, faceAlpha, patchStyle, wheelTransforms{ith_wheel});
        patchHandles = [patchHandles; newPatches]; %#ok<AGROW>
    end

    % Lights: one patch per light group, so each can be switched
    lightPatches = struct;
    lightOffColors = struct;
    for ith_group = 1:length(lightGroupNames)
        thisName = lightGroupNames{ith_group};
        lightPatches.(thisName) = [];
        lightOffColors.(thisName) = [];
        theseFaces = find(faceLightGroup==ith_group);
        if isempty(theseFaces)
            continue;
        end
        newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces, faceColors, faceAlpha, patchStyle, bodyTransform);
        lightPatches.(thisName) = newPatches{1};
        lightOffColors.(thisName) = faceColors(theseFaces,:);
        set(newPatches{1},'DisplayName',sprintf('Light: %s',thisName));
        patchHandles = [patchHandles; newPatches]; %#ok<AGROW>
    end

    % Add lights if asked and the axes has none: a main light from above
    % and to the side, and a dimmer fill light from the other side
    if strcmpi(char(options.SceneLights),'auto') && isempty(findall(axesHandle,'Type','light'))
        light('Parent',axesHandle,'Style','infinite','Position',[-1 -2 3]);
        light('Parent',axesHandle,'Style','infinite','Position',[2 1.5 1],'Color',[0.45 0.45 0.45]);
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

    % Light effects (glows and ground pools), for night scenes
    lightEffects = [];
    if options.LightEffects
        lightEffects = fcn_INTERNAL_makeLightEffects(vehicleMesh, faceLightGroup, lightGroupNames, transformHandle, bodyTransform);
    end

    % The point the body rolls and pitches about
    bodyPivot = options.BodyPivot;
    if isempty(bodyPivot)
        bodyPivot = fcn_INTERNAL_defaultBodyPivot(vehicleMesh, wheelCenters);
    end

    plotHandles = struct;
    plotHandles.Transform = transformHandle;
    plotHandles.BodyTransform = bodyTransform;
    plotHandles.BodyPivot = bodyPivot(:)';
    plotHandles.Patches = patchHandles;
    plotHandles.Axes = axesHandle;
    plotHandles.WheelTransforms = wheelTransforms;
    plotHandles.WheelCenters = wheelCenters;
    plotHandles.LightPatches = lightPatches;
    plotHandles.LightOffColors = lightOffColors;
    plotHandles.FaceLighting = faceLighting;
    plotHandles.LightEffects = lightEffects;

    % Set the pose, wheels, and lights
    transformHandle.Matrix = poseMatrix;
    fcn_INTERNAL_updateBody(plotHandles, options);
    fcn_INTERNAL_updateWheels(plotHandles, options.WheelSpin, options.SteerAngle, options.WheelLift);
    if ~isempty(options.LightStates)
        fcn_INTERNAL_updateLights(plotHandles, options.LightStates);
    end
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

%% fcn_INTERNAL_patchesByAlpha
function newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, faceIndices, faceColors, faceAlpha, patchStyle, parentHandle)
% Makes one patch for each alpha level among the given faces, with
% outward normals given to MATLAB directly. (MATLAB's own normals point
% the opposite way to the right-hand rule, which puts shiny highlights on
% the inside of the surface.)
newPatches = {};
if isempty(faceIndices)
    return;
end
roundedAlpha = round(faceAlpha(faceIndices)*1000)/1000;
alphaLevels = sort(unique(roundedAlpha),'descend');
newPatches = cell(length(alphaLevels),1);
for ith_level = 1:length(alphaLevels)
    thisAlpha = alphaLevels(ith_level);
    theseFaces = faceIndices(abs(roundedAlpha - thisAlpha) < 1e-9);
    if thisAlpha >= 0.999
        displayName = 'Opaque surfaces';
    else
        displayName = sprintf('Transparent surfaces (alpha %.2f)',thisAlpha);
    end
    [patchFaceNormals, patchVertexNormals] = fcn_INTERNAL_outwardNormals(...
        vehicleMesh.Vertices, vehicleMesh.Faces(theseFaces,:));
    newPatches{ith_level} = patch('Parent',parentHandle,...
        'Faces',vehicleMesh.Faces(theseFaces,:),...
        'Vertices',vehicleMesh.Vertices,...
        'FaceNormals',patchFaceNormals,...
        'VertexNormals',patchVertexNormals,...
        'FaceVertexCData',faceColors(theseFaces,:),...
        'FaceColor','flat',...
        'FaceAlpha',thisAlpha,...
        'EdgeColor',patchStyle.EdgeColor,...
        'FaceLighting',patchStyle.FaceLighting,...
        'BackFaceLighting','lit',...
        'AmbientStrength',patchStyle.Finish(1),...
        'DiffuseStrength',patchStyle.Finish(2),...
        'SpecularStrength',patchStyle.Finish(3),...
        'SpecularExponent',patchStyle.Finish(4),...
        'SpecularColorReflectance',patchStyle.Finish(5),...
        'DisplayName',displayName);
end
end % Ends fcn_INTERNAL_patchesByAlpha

%% fcn_INTERNAL_lightGroupNames
function lightGroupNames = fcn_INTERNAL_lightGroupNames
% The switchable light groups, in a fixed order
lightGroupNames = {'headlight','turnLeft','turnRight','running','tail','backup'};
end % Ends fcn_INTERNAL_lightGroupNames

%% fcn_INTERNAL_faceLightGroups
function faceLightGroup = fcn_INTERNAL_faceLightGroups(vehicleMesh)
% Returns, for each face, its light group index (0 = not a switchable
% light). Turn signals are split into left and right by position.
Nfaces = size(vehicleMesh.Faces,1);
faceLightGroup = zeros(Nfaces,1);
if ~isfield(vehicleMesh,'FaceLightType') || isempty(vehicleMesh.FaceLightType) || ~isfield(vehicleMesh,'LightTypeNames')
    return;
end
lightTypeNames = vehicleMesh.LightTypeNames;
faceLightType = vehicleMesh.FaceLightType(:);
flagLight = faceLightType>0;
if ~any(flagLight)
    return;
end
faceTypeName = repmat({''},Nfaces,1);
faceTypeName(flagLight) = lightTypeNames(faceLightType(flagLight));
faceCentersY = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),2) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,2),2) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),2))/3;
faceLightGroup(strcmp(faceTypeName,'headlight')) = 1;
faceLightGroup(strcmp(faceTypeName,'turnsignal') & faceCentersY>0)  = 2;
faceLightGroup(strcmp(faceTypeName,'turnsignal') & faceCentersY<=0) = 3;
faceLightGroup(strcmp(faceTypeName,'running')) = 4;
faceLightGroup(strcmp(faceTypeName,'tail'))    = 5;
faceLightGroup(strcmp(faceTypeName,'backup'))  = 6;
end % Ends fcn_INTERNAL_faceLightGroups

%% fcn_INTERNAL_updateBody
function fcn_INTERNAL_updateBody(plotHandles, options)
% Rolls, pitches, and heaves the body (sprung mass) relative to the
% ground frame, about the body pivot. The wheels are not moved.
if ~isfield(plotHandles,'BodyTransform') || isempty(plotHandles.BodyTransform)
    return;
end
bodyPivot = plotHandles.BodyPivot;
if ~isempty(options.BodyPivot)
    bodyPivot = options.BodyPivot(:)';
end
plotHandles.BodyTransform.Matrix = makehgtform('translate',[0 0 options.BodyHeave]) * ...
    makehgtform('translate',bodyPivot) * ...
    makehgtform('yrotate',options.BodyPitch) * ...
    makehgtform('xrotate',options.BodyRoll) * ...
    makehgtform('translate',-bodyPivot);
end % Ends fcn_INTERNAL_updateBody

%% fcn_INTERNAL_defaultBodyPivot
function bodyPivot = fcn_INTERNAL_defaultBodyPivot(vehicleMesh, wheelCenters)
% Midway between the axles, on the centerline, at wheel-center height.
% Without wheels, use the middle of the mesh at 40% of its height.
if any(all(isfinite(wheelCenters),2))
    knownCenters = wheelCenters(all(isfinite(wheelCenters),2),:);
    bodyPivot = [(min(knownCenters(:,1)) + max(knownCenters(:,1)))/2, 0, mean(knownCenters(:,3))];
else
    lowCorner = min(vehicleMesh.Vertices,[],1);
    highCorner = max(vehicleMesh.Vertices,[],1);
    bodyPivot = [(lowCorner(1) + highCorner(1))/2, 0, lowCorner(3) + 0.4*(highCorner(3) - lowCorner(3))];
end
end % Ends fcn_INTERNAL_defaultBodyPivot

%% fcn_INTERNAL_updateWheels
function fcn_INTERNAL_updateWheels(plotHandles, wheelSpin, steerAngle, wheelLift)
% Spins each wheel about its axle, steers the front wheels about a
% vertical line through their centers, and lifts wheels off the ground
if ~isfield(plotHandles,'WheelTransforms')
    return;
end
wheelSpin = wheelSpin(:)';
if isscalar(wheelSpin)
    wheelSpin = repmat(wheelSpin,1,4);
end
steerAngle = steerAngle(:)';
if isscalar(steerAngle)
    steerAngle = [steerAngle steerAngle];
end
steerAngles = [steerAngle 0 0];
wheelLift = wheelLift(:)';
if isscalar(wheelLift)
    wheelLift = repmat(wheelLift,1,4);
end
for ith_wheel = 1:4
    thisTransform = plotHandles.WheelTransforms{ith_wheel};
    if isempty(thisTransform)
        continue;
    end
    center = plotHandles.WheelCenters(ith_wheel,:);
    thisTransform.Matrix = makehgtform('translate',center + [0 0 wheelLift(ith_wheel)]) * ...
        makehgtform('zrotate',steerAngles(ith_wheel)) * ...
        makehgtform('yrotate',wheelSpin(ith_wheel)) * ...
        makehgtform('translate',-center);
end
end % Ends fcn_INTERNAL_updateWheels

%% fcn_INTERNAL_updateLights
function fcn_INTERNAL_updateLights(plotHandles, lightStates)
% Switches each light group on (glowing, unshaded color) or off (its
% plain colors, shaded like the rest of the vehicle)
if ~isfield(plotHandles,'LightPatches')
    return;
end
lightGroupNames = fcn_INTERNAL_lightGroupNames;
for ith_group = 1:length(lightGroupNames)
    thisName = lightGroupNames{ith_group};
    thisPatch = plotHandles.LightPatches.(thisName);
    if isempty(thisPatch)
        continue;
    end
    onColor = fcn_INTERNAL_lightColor(thisName, lightStates);
    if isempty(onColor)
        set(thisPatch,'FaceVertexCData',plotHandles.LightOffColors.(thisName),...
            'FaceLighting',plotHandles.FaceLighting);
    else
        set(thisPatch,'FaceVertexCData',repmat(onColor,size(plotHandles.LightOffColors.(thisName),1),1),...
            'FaceLighting','none');
    end
end

% Light effects: glows follow their lamps; ground pools follow the states
if ~isfield(plotHandles,'LightEffects') || isempty(plotHandles.LightEffects)
    return;
end
lightEffects = plotHandles.LightEffects;
for ith_group = 1:length(lightGroupNames)
    thisName = lightGroupNames{ith_group};
    thisGlow = lightEffects.Glow.(thisName);
    if isempty(thisGlow)
        continue;
    end
    onColor = fcn_INTERNAL_lightColor(thisName, lightStates);
    if isempty(onColor)
        fcn_INTERNAL_setVisible(thisGlow, false);
    else
        set(thisGlow,'FaceColor',onColor);
        fcn_INTERNAL_setVisible(thisGlow, true);
    end
end
headlightState = lower(char(string(fcn_INTERNAL_stateValue(lightStates,'Headlights','off'))));
tailState = fcn_INTERNAL_stateValue(lightStates,'Tail','off');
if islogical(tailState) || isnumeric(tailState)
    if tailState
        tailState = 'on';
    else
        tailState = 'off';
    end
end
tailState = lower(char(tailState));
fcn_INTERNAL_setVisible(lightEffects.Pools.lowBeam, any(strcmp(headlightState,{'low','high'})));
fcn_INTERNAL_setVisible(lightEffects.Pools.highBeam, strcmp(headlightState,'high'));
fcn_INTERNAL_setVisible(lightEffects.Pools.tail, strcmp(tailState,'on'));
fcn_INTERNAL_setVisible(lightEffects.Pools.brake, strcmp(tailState,'brake'));
fcn_INTERNAL_setVisible(lightEffects.Pools.backup, fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'Backup',false)));
end % Ends fcn_INTERNAL_updateLights

%% fcn_INTERNAL_setVisible
function fcn_INTERNAL_setVisible(graphicsHandle, flagVisible)
% Shows or hides a graphics object, if it exists (only when it changes)
if isempty(graphicsHandle)
    return;
end
if flagVisible
    newValue = 'on';
else
    newValue = 'off';
end
if ~strcmp(graphicsHandle.Visible, newValue)
    graphicsHandle.Visible = newValue;
end
end % Ends fcn_INTERNAL_setVisible

%% fcn_INTERNAL_makeLightEffects
function lightEffects = fcn_INTERNAL_makeLightEffects(vehicleMesh, faceLightGroup, lightGroupNames, groundParent, bodyParent)
% Makes the (hidden) light effects: a glow shell around each light group,
% riding with the body, and pools of light on the ground, riding with
% the ground frame. fcn_INTERNAL_updateLights shows and hides them.
glowOffset = 0.025; % How far each glow shell sits outside its lamp [m]
glowAlpha = 0.35;   % How see-through the glow is (0 clear, 1 solid)

lightEffects = struct;
lightEffects.Glow = struct;
lightEffects.Pools = struct;

% Glows: push each lamp's vertices outward along their normals
for ith_group = 1:length(lightGroupNames)
    thisName = lightGroupNames{ith_group};
    lightEffects.Glow.(thisName) = [];
    theseFaces = vehicleMesh.Faces(faceLightGroup==ith_group,:);
    if isempty(theseFaces)
        continue;
    end
    [~, vertexNormals] = fcn_INTERNAL_outwardNormals(vehicleMesh.Vertices, theseFaces);
    lightEffects.Glow.(thisName) = patch('Parent',bodyParent, ...
        'Faces',theseFaces,'Vertices',vehicleMesh.Vertices + glowOffset*vertexNormals, ...
        'FaceColor',[1 1 1],'FaceAlpha',glowAlpha,'EdgeColor','none','FaceLighting','none', ...
        'Visible','off','HitTest','off','DisplayName',sprintf('Glow: %s',thisName));
end

% Where the lamps are: the front of the headlights and the back of the
% rear lights, and how far apart the left and right lamps are. Without
% labeled lamps, use the front and back of the mesh.
meshLow = min(vehicleMesh.Vertices,[],1);
meshHigh = max(vehicleMesh.Vertices,[],1);
frontVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, find(strcmp(lightGroupNames,'headlight')));
rearVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, find(ismember(lightGroupNames,{'tail','backup'})));
if isempty(frontVertices)
    frontX = meshHigh(1);
    frontHalfSpacing = 0.3*(meshHigh(2) - meshLow(2));
else
    frontX = max(frontVertices(:,1));
    frontHalfSpacing = mean(abs(frontVertices(:,2)));
end
if isempty(rearVertices)
    rearX = meshLow(1);
    rearHalfSpacing = 0.3*(meshHigh(2) - meshLow(2));
else
    rearX = min(rearVertices(:,1));
    rearHalfSpacing = mean(abs(rearVertices(:,2)));
end

% The pools: start x, direction (+1 ahead, -1 behind), half spacing [m],
% length [m], spread half angle [deg], peak alpha, height above the
% ground [m], color. Change these numbers to change the look of the
% beams. Pools that can be on together get different heights, so the
% graphics card does not flicker between them ("z-fighting").
poolList = {
    'lowBeam',  frontX, +1, frontHalfSpacing,     15,  16, 0.50, 0.010, [1.00 0.95 0.78];
    'highBeam', frontX, +1, 0.8*frontHalfSpacing, 40,   6, 0.40, 0.025, [1.00 1.00 0.95];
    'tail',     rearX,  -1, rearHalfSpacing,      2.0, 45, 0.15, 0.010, [1.00 0.08 0.05];
    'brake',    rearX,  -1, rearHalfSpacing,      3.0, 45, 0.40, 0.010, [1.00 0.10 0.06];
    'backup',   rearX,  -1, rearHalfSpacing,      6.0, 30, 0.45, 0.025, [1.00 1.00 1.00]};
for ith_pool = 1:size(poolList,1)
    [poolVertices, poolFaces, poolAlpha] = fcn_INTERNAL_poolMesh(poolList{ith_pool,2:8});
    lightEffects.Pools.(poolList{ith_pool,1}) = patch('Parent',groundParent, ...
        'Faces',poolFaces,'Vertices',poolVertices, ...
        'FaceColor',poolList{ith_pool,9},'EdgeColor','none','FaceLighting','none', ...
        'FaceVertexAlphaData',poolAlpha,'FaceAlpha','interp','AlphaDataMapping','none', ...
        'Visible','off','HitTest','off','DisplayName',sprintf('Light pool: %s',poolList{ith_pool,1}));
end
end % Ends fcn_INTERNAL_makeLightEffects

%% fcn_INTERNAL_groupVertices
function groupVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, groupIndices)
% The vertices of the faces in the given light groups (empty if none)
theseFaces = vehicleMesh.Faces(ismember(faceLightGroup, groupIndices),:);
groupVertices = vehicleMesh.Vertices(unique(theseFaces(:)),:);
end % Ends fcn_INTERNAL_groupVertices

%% fcn_INTERNAL_poolMesh
function [vertices, faces, vertexAlpha] = fcn_INTERNAL_poolMesh(startX, direction, halfSpacing, poolLength, spreadDegrees, peakAlpha, poolZ)
% A fan-shaped grid on the ground, starting at the lamps and widening
% with distance. Its alpha (see-through-ness) rises quickly near the
% lamps, fades to zero at the far end, and fades to zero at the sides.
Nalong = 24;
Nacross = 11;
along = poolLength*((0:Nalong-1)'/(Nalong-1)).^1.3;  % Closer rows near the lamps
across = linspace(-1,1,Nacross);
halfWidth = halfSpacing + 0.3 + along*tand(spreadDegrees);
[acrossGrid, alongGrid] = meshgrid(across, along);
halfWidthGrid = repmat(halfWidth, 1, Nacross);
x = startX + direction*alongGrid;
y = acrossGrid.*halfWidthGrid;
rise = min(1, (alongGrid + 0.3)/(0.15*poolLength + 0.3));
fade = (1 - alongGrid/poolLength).^1.5;
edge = 1 - acrossGrid.^2;
vertexAlpha = peakAlpha*rise.*fade.*edge;
vertices = [x(:) y(:) poolZ*ones(numel(x),1)];
vertexAlpha = vertexAlpha(:);

% Quad faces of the grid (column-major vertex numbering)
[rowIndex, columnIndex] = meshgrid(1:Nalong-1, 1:Nacross-1);
first = sub2ind([Nalong Nacross], rowIndex(:), columnIndex(:));
faces = [first, first+1, first+1+Nalong, first+Nalong];
end % Ends fcn_INTERNAL_poolMesh

%% fcn_INTERNAL_lightColor
function onColor = fcn_INTERNAL_lightColor(groupName, lightStates)
% The glowing color of a light group in the given states, or [] if off
onColor = [];
switch groupName
    case 'headlight'
        state = fcn_INTERNAL_stateValue(lightStates,'Headlights','off');
        switch lower(char(state))
            case 'low'
                onColor = [1.00 0.96 0.78];
            case 'high'
                onColor = [1.00 1.00 1.00];
        end
    case 'turnLeft'
        if fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'TurnLeft',false))
            onColor = [1.00 0.55 0.00];
        end
    case 'turnRight'
        if fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'TurnRight',false))
            onColor = [1.00 0.55 0.00];
        end
    case 'running'
        if fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'Running',false))
            onColor = [1.00 0.98 0.90];
        end
    case 'tail'
        state = fcn_INTERNAL_stateValue(lightStates,'Tail','off');
        if islogical(state) || isnumeric(state)
            if state
                state = 'on';
            else
                state = 'off';
            end
        end
        switch lower(char(state))
            case 'on'
                onColor = [0.70 0.04 0.04];
            case 'brake'
                onColor = [1.00 0.12 0.08];
        end
    case 'backup'
        if fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'Backup',false))
            onColor = [1.00 1.00 1.00];
        end
end
end % Ends fcn_INTERNAL_lightColor

%% fcn_INTERNAL_stateValue
function value = fcn_INTERNAL_stateValue(lightStates, fieldName, defaultValue)
% A field of the light states, or the default if it is missing
if isfield(lightStates, fieldName) && ~isempty(lightStates.(fieldName))
    value = lightStates.(fieldName);
else
    value = defaultValue;
end
end % Ends fcn_INTERNAL_stateValue

%% fcn_INTERNAL_isOn
function flagOn = fcn_INTERNAL_isOn(value)
% True for true, nonzero numbers, and the strings 'on'
if ischar(value) || isstring(value)
    flagOn = strcmpi(char(value),'on');
else
    flagOn = logical(value);
end
end % Ends fcn_INTERNAL_isOn

%% fcn_INTERNAL_outwardNormals
function [faceNormals, vertexNormals] = fcn_INTERNAL_outwardNormals(vertices, faces)
% Face normals by the right-hand rule (outward for meshes from
% fcn_CarMesh3D_simplifyMesh), and vertex normals as the area-weighted
% average of the normals of the faces around each vertex
Nvertices = size(vertices,1);
crossProducts = cross(...
    vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2); % Length is twice the area
faceNormals = crossProducts ./ max(vecnorm(crossProducts,2,2), eps);

vertexNormals = zeros(Nvertices,3);
for ith_dim = 1:3
    vertexNormals(:,ith_dim) = accumarray(faces(:), repmat(crossProducts(:,ith_dim),3,1), [Nvertices 1]);
end
vertexLengths = vecnorm(vertexNormals,2,2);
flagUnused = vertexLengths < eps;
vertexNormals(flagUnused,:) = repmat([0 0 1], sum(flagUnused), 1);
vertexNormals = vertexNormals ./ max(vecnorm(vertexNormals,2,2), eps);
end % Ends fcn_INTERNAL_outwardNormals

%% fcn_INTERNAL_finishValues
function [finishValues, finishName] = fcn_INTERNAL_finishValues(finishSetting)
% Returns [ambient diffuse specular exponent colorReflectance] for a
% named finish, or passes a numeric vector through
if isnumeric(finishSetting)
    finishValues = finishSetting(:)';
    finishName = 'custom';
    return;
end
finishName = lower(char(finishSetting));
switch finishName
    case 'satin'
        finishValues = [0.45 0.70 0.50 15 0.70];
    case 'glossy'
        finishValues = [0.30 0.65 1.00 20 1.00];
    case 'metallic'
        finishValues = [0.30 0.55 1.00 20 0.30];
    otherwise % 'matte'
        finishValues = [0.55 0.65 0.25 10 1.00];
end
end % Ends fcn_INTERNAL_finishValues

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
