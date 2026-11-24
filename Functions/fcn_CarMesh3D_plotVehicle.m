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
%           (AxesHandle=axesHandle),...
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
%           Headlights: 'off', 'low', or 'high' ('high' is both beams)
%           LowBeam, HighBeam: true or false, to switch each beam on its
%               own (each overrides what Headlights says for it). The
%               high beam lamps are the 'highbeam' faces; a vehicle with
%               none lights its headlights white for the high beams
%           TurnLeft, TurnRight: true or false (blink them in your loop)
%           Hazards: true or false: both turn signals and the warning
%               lamps (blink it in your loop)
%           Running: true or false (front running lights; the marker
%               lamps light with them)
%           Tail: 'off', 'on', or 'brake' (rear lights; the license plate
%               lamp lights whenever the tail lamps are on)
%           Backup: true or false
%           FogLights: true or false (the fog lamps)
%           Reflectors: 0 to 1, how much outside light (another car's
%               headlights) the reflectors send back: 0 none, 1 full
%      (The lamp types are those of fcn_CarMesh3D_lampTypes. Reflectors,
%      marker lamps and warning lamps glow in their own colors, made
%      brighter, since they come in amber, red or white.)
%      Lights need light faces with light types, from fcn_CarMesh3D_labelParts
%      or fcn_CarMesh3D_editLabels. Turn signals are split into left and
%      right by position. A light that is on is drawn unshaded, so it
%      appears to glow. Default is [] (lights keep their plain colors).
%      A lamp's clear cover (glass with a FaceCoverLamp, from
%      fcn_CarMesh3D_findLampCovers) is clear glass while its lamp is off,
%      and tinted with the lamp's lit color, partly see-through, while
%      it is on (by day and at night). A mesh made before FaceCoverLamp
%      existed has its covers found when it is drawn.
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
%               braking, white when backing up), and, while a turn
%               signal is on, a small pool at that side's front corner
%               (amber) and rear corner (red).
%      These are drawn shapes, not MATLAB light objects: MATLAB lights
%      shine in every direction, do not fade with distance, and cast no
%      shadows, so they cannot make a beam. The pools do not light up
%      other objects (such as cubes), and they ride with the vehicle's
%      ground frame, so they stay flat on the ground when the body rolls
%      or pitches.
%
%      ShowHidden: the hidden sets to show (hidden faces: FaceHiddenSet,
%      named in HiddenSetNames, from fcn_CarMesh3D_editLabels's Hide), by
%      name, such as {'hard top'}, or true for all, or false for none.
%      Hidden faces are drawn in patches of their own, switched off, so
%      they cost nothing to draw; a set is switched on by name, also on
%      the fast path (put the hard top up in the rain). Default [] (none
%      at first; on the fast path, as they are). Hidden lamps do not
%      light.
%
%      AxesHandle: an axes to plot into, in any figure (a uifigure's
%      uiaxes too, which FigNum cannot reach). If given, FigNum only
%      chooses fast mode (-1) or not.
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
%           LightPatches: a structure with the patch handles (or []) of
%               each light group: headlight, turnLeft, turnRight, running,
%               tail, backup (usually one; one per opacity when a group's
%               faces differ, such as a clear lens over a lamp)
%           LightGroupNames: the light groups: the six single ones, then
%               one per combination of functions (FaceLightFunctions)
%           LightOffColors, FaceLighting: used to switch lights back off
%               (LightOffColors: for each group, a cell array of each
%               patch's own colors)
%           LightOffAlpha, LightOnAlpha: for each group, a cell array of
%               each patch's transparency while off and while on ([] for
%               no change). A light that is also glass (FaceAlsoParts, a
%               lamp's clear cover) is drawn as the vehicle's glass while
%               off, so the lenses under it show, and opaque while on
%           CoverPatches: a structure with, for each light group, the
%               patch handles (or []) of the clear covers over its lamps
%               (FaceCoverLamp), switched with the group
%           CoverOffColors, CoverOffAlpha: for each group, a cell array
%               of each cover patch's own colors and transparency (clear
%               glass), used while the lamp is off
%           CoverOnAlpha: the transparency of a cover while its lamp is
%               lit (0.35)
%           HiddenSetNames, HiddenPatches: each hidden set's name, and
%               (a cell per set) its patches, switched on by ShowHidden
%           LightEffects: [] or, with LightEffects=true, a structure with
%               Glow (one patch or [] per light group) and Pools (patches
%               lowBeam, highBeam, tail, brake, backup, each or [])
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findLampCovers (only for a labeled mesh with no
%      FaceCoverLamp, made before it existed)
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
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Added AxesHandle: plot into a given axes (the Model Reviewer's
%   %   % uiaxes draws the animation checks live)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Light groups with faces of several opacities (a clear lens over a
%   %   % lamp) keep all their patches, each with its own off colors
%   %   % (LightOffColors is now a cell per group): only the first was kept,
%   %   % and switching the light set the wrong number of colors on it
%   %   % (warnings in the Model Reviewer's animations of the 2009 Fit)
%
% 2026_11_22 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Multi-function lights: a face with several light functions
%   %   % (FaceLightFunctions, from fcn_CarMesh3D_editLabels's
%   %   % AlsoLightTypes) is in a combined group ('turnLeft_tail') that
%   %   % glows when any of them is on; a flashing turn signal wins, in red
%   %   % on a tail light (Sean's design, 01:57)
%   % * Multi-part faces: a light that is also glass (FaceAlsoParts, a
%   %   % lamp's clear cover) is drawn as the vehicle's glass while off,
%   %   % and glows, opaque, while on (Sean, 23:04: option B)
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Turn-signal pools of light (LightEffects): while a turn signal
%   %   % is on, a small pool on the ground at that side's front corner
%   %   % (amber) and rear corner (red) (Sean, 03:19); placed from the
%   %   % lamps, or from the headlights and tail lights, or the mesh's
%   %   % corners, when the vehicle has no turn-signal lamps
%   % * High beams as lamps of their own (Sean, 03:19 and 03:27): the
%   %   % 'highbeam' light type is a light group of its own, 'highBeam';
%   %   % LowBeam and HighBeam in LightStates switch each beam alone
%   %   % ('high' in Headlights is still both). A vehicle with no high
%   %   % beam lamps lights its headlights white for the high beams, as
%   %   % before
%   % * Hidden faces (FaceHiddenSet, in named sets; Sean, 04:07 to 04:21):
%   %   % not drawn; each set in patches of its own, switched off, shown
%   %   % by name with ShowHidden (also on the fast path: a hard top put
%   %   % up in the rain); a hidden lamp does not light

% 2026_11_23 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Clear lamp covers (Sean, 09:22, option A): glass faces that cover
%   %   % a lamp (FaceCoverLamp, from fcn_CarMesh3D_findLampCovers) are
%   %   % drawn as clear glass in patches of their own, one per light
%   %   % group, switched with the lamp under them: tinted with the lamp's
%   %   % lit color, 35% opaque, while it is on (Sean, 15:23, option A:
%   %   % the glass over a lit bulb glows with its color). A turn signal's
%   %   % cover follows its own side. A labeled mesh without FaceCoverLamp
%   %   % (made before it) has its covers found when it is drawn, so its
%   %   % lamps' clear covers no longer glow opaque as lamps
%   % * LightEffects: a lamp under a clear cover glows around its cover
%   %   % (the glow shell around the lamp behind poked through the cover)
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotVehicle
%   % * Five more lamp types (fcn_CarMesh3D_lampTypes; Sean, task 8):
%   %   % fog lamps (new LightStates field FogLights), reflectors (new
%   %   % field Reflectors, 0 to 1: how much outside light they send
%   %   % back), the license plate lamp (lit with the tail lamps), marker
%   %   % lamps (lit with the running lights) and warning lamps (new field
%   %   % Hazards, which also lights both turn signals; Q24 (A), Q25 (A),
%   %   % 23:19). Reflectors, marker and warning lamps glow in their own
%   %   % colors made brighter (they come in amber, red or white)
%   % * What lights those five types is a list, fcn_CarMesh3D_lampTypes'
%   %   % default, which a vehicle can replace with its own mesh field
%   %   % LampSwitching (Sean, 23:23: makers switch fog lamps in 3 to 6
%   %   % ways)

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
    options.ShowHidden = []         % Hidden sets to show: names, true (all), false (none); [] as they are
    options.AxesHandle = []         % Axes to plot into (any figure, a uifigure too); overrides FigNum's figure
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

        % Check the ShowHidden input
        if ~isempty(options.ShowHidden) && ~(iscell(options.ShowHidden) || ischar(options.ShowHidden) ...
                || isstring(options.ShowHidden) || (islogical(options.ShowHidden) && isscalar(options.ShowHidden)))
            error('ShowHidden must be hidden set names (a cell array), true for all, or false for none');
        end

        % Check the LightStates input
        if ~isempty(options.LightStates)
            if ~isstruct(options.LightStates)
                error('LightStates must be a structure (see help fcn_CarMesh3D_plotVehicle)');
            end
            allowedFields = {'Headlights','LowBeam','HighBeam','TurnLeft','TurnRight','Running','Tail','Backup', ...
                'Hazards','FogLights','Reflectors'};
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
    if ~isempty(options.ShowHidden)
        fcn_INTERNAL_showHidden(plotHandles, options.ShowHidden);
    end
else
    % Select the axes (given), or the figure, without clearing it
    if ~isempty(options.AxesHandle)
        axesHandle = options.AxesHandle;
    else
        if isempty(figNum)
            temp_h = gcf;
        else
            temp_h = figure(figNum);
        end
        axesHandle = get(temp_h,'CurrentAxes');
        if isempty(axesHandle)
            axesHandle = axes('Parent',temp_h);
        end
    end
    % (hidden-handle objects count too: a scene drawn with hidden handles,
    % such as AnimateCar3D's, is not a new axes)
    flag_this_is_a_new_axes = isempty(allchild(axesHandle));

    % Lamp covers: a labeled mesh made before FaceCoverLamp existed has
    % its clear covers found now (fast mode), so they are drawn as clear
    % glass over the lamps. (The mesh given is not changed: this is a
    % copy inside this function.)
    if isfield(vehicleMesh,'PartNames') && isfield(vehicleMesh,'FacePartIndex') ...
            && isfield(vehicleMesh,'FaceLightType') && isfield(vehicleMesh,'LightTypeNames') ...
            && (~isfield(vehicleMesh,'FaceCoverLamp') || numel(vehicleMesh.FaceCoverLamp) ~= size(vehicleMesh.Faces,1))
        vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, FigNum=-1);
    end

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
    [faceLightGroup, lightGroupNames] = fcn_INTERNAL_faceLightGroups(vehicleMesh);
    % (hidden faces: in patches of their own, switched off; a hidden lamp
    % does not light)
    faceHiddenSet = zeros(Nfaces,1);
    hiddenSetNames = cell(0,1);
    if isfield(vehicleMesh,'FaceHiddenSet') && numel(vehicleMesh.FaceHiddenSet) == Nfaces
        faceHiddenSet = double(vehicleMesh.FaceHiddenSet(:));
        if isfield(vehicleMesh,'HiddenSetNames')
            hiddenSetNames = reshape(cellstr(vehicleMesh.HiddenSetNames), [], 1);
        end
    end
    flagHidden = faceHiddenSet > 0;
    faceLightGroup(flagHidden) = 0;
    % (lamp covers: the light group of the lamp each one covers, 0 for
    % faces that are not covers)
    faceCoverGroup = fcn_INTERNAL_faceCoverGroups(vehicleMesh, faceLightGroup, lightGroupNames, flagHidden | faceWheel>0);

    % Two rigid frames under one transform for the whole vehicle:
    %   transformHandle      ground frame, moved by Pose
    %     bodyTransform      sprung mass: body and lights (roll, pitch, heave)
    %     wheelTransforms    unsprung mass: one per wheel (spin, steer)
    transformHandle = hgtransform('Parent',axesHandle);
    bodyTransform = hgtransform('Parent',transformHandle);
    patchHandles = {};

    % Body (everything that is not a wheel or a switchable light), one
    % patch per alpha level: opaque first, then each transparent level
    flagBody = faceWheel==0 & faceLightGroup==0 & faceCoverGroup==0 & ~flagHidden;
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
        % (the center from all the wheel's faces, hidden ones too)
        wheelVertices = vehicleMesh.Vertices(unique(vehicleMesh.Faces(theseFaces,:)),:);
        wheelCenters(ith_wheel,:) = (min(wheelVertices,[],1) + max(wheelVertices,[],1))/2;
        wheelTransforms{ith_wheel} = hgtransform('Parent',transformHandle);
        theseFaces = theseFaces(~flagHidden(theseFaces));
        newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces, faceColors, faceAlpha, patchStyle, wheelTransforms{ith_wheel});
        patchHandles = [patchHandles; newPatches]; %#ok<AGROW>
    end

    % Lights: one patch per light group, so each can be switched. A
    % light that is also glass (a lamp's clear cover) has patches of its
    % own: drawn as the vehicle's glass while off, opaque while on
    flagAlsoGlass = fcn_INTERNAL_alsoGlass(vehicleMesh);
    coverColors = faceColors;
    coverAlpha = faceAlpha;
    if any(flagAlsoGlass)
        [glassColor, glassAlpha] = fcn_INTERNAL_glassLook(vehicleMesh, faceColors, faceAlpha);
        coverColors(flagAlsoGlass,:) = repmat(glassColor, sum(flagAlsoGlass), 1);
        coverAlpha(flagAlsoGlass) = glassAlpha;
    end
    lightPatches = struct;
    lightOffColors = struct;
    lightOffAlpha = struct;
    lightOnAlpha = struct;
    for ith_group = 1:length(lightGroupNames)
        thisName = lightGroupNames{ith_group};
        lightPatches.(thisName) = [];
        lightOffColors.(thisName) = [];
        lightOffAlpha.(thisName) = {};
        lightOnAlpha.(thisName) = {};
        theseFaces = find(faceLightGroup==ith_group);
        if isempty(theseFaces)
            continue;
        end
        lampPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces(~flagAlsoGlass(theseFaces)), faceColors, faceAlpha, patchStyle, bodyTransform);
        coverPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces(flagAlsoGlass(theseFaces)), coverColors, coverAlpha, patchStyle, bodyTransform);
        newPatches = [lampPatches(:); coverPatches(:)];
        lightOffAlpha.(thisName) = cellfun(@(h) h.FaceAlpha, newPatches, 'UniformOutput', false);
        lightOnAlpha.(thisName) = [repmat({[]}, numel(lampPatches), 1); repmat({1}, numel(coverPatches), 1)];
        % (a group with faces of several opacities, such as a clear lens
        % over an opaque lamp, is several patches: all are kept, each with
        % its own off colors; keeping only the first set the wrong number
        % of colors on it, the 2009 Honda Fit's lamps)
        lightPatches.(thisName) = vertcat(newPatches{:});
        lightOffColors.(thisName) = cellfun(@(h) h.FaceVertexCData, newPatches, 'UniformOutput', false);
        set(lightPatches.(thisName),'DisplayName',sprintf('Light: %s',thisName));
        patchHandles = [patchHandles; newPatches]; %#ok<AGROW>
    end

    % Lamp covers: clear glass over the lamps, in patches of their own,
    % one per light group (one per opacity, if they differ), switched
    % with the group's lamps: tinted while the lamp is lit
    coverOnAlpha = 0.35;   % How see-through a cover is while its lamp is lit (0 clear, 1 solid)
    coverPatches = struct;
    coverOffColors = struct;
    coverOffAlpha = struct;
    for ith_group = 1:length(lightGroupNames)
        thisName = lightGroupNames{ith_group};
        coverPatches.(thisName) = [];
        coverOffColors.(thisName) = {};
        coverOffAlpha.(thisName) = {};
        theseFaces = find(faceCoverGroup==ith_group);
        if isempty(theseFaces)
            continue;
        end
        newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces, faceColors, faceAlpha, patchStyle, bodyTransform);
        coverPatches.(thisName) = vertcat(newPatches{:});
        coverOffColors.(thisName) = cellfun(@(h) h.FaceVertexCData, newPatches, 'UniformOutput', false);
        coverOffAlpha.(thisName) = cellfun(@(h) h.FaceAlpha, newPatches, 'UniformOutput', false);
        set(coverPatches.(thisName),'DisplayName',sprintf('Lamp cover: %s',thisName));
        patchHandles = [patchHandles; newPatches]; %#ok<AGROW>
    end

    % Hidden sets: patches of their own, switched off (shown by
    % ShowHidden); a hidden wheel's faces ride with its wheel
    hiddenPatches = cell(numel(hiddenSetNames),1);
    for ith_set = 1:numel(hiddenSetNames)
        setPatches = {};
        for ith_wheel = 0:4
            theseFaces = find(faceHiddenSet==ith_set & faceWheel==ith_wheel);
            if isempty(theseFaces)
                continue;
            end
            parentHandle = bodyTransform;
            if ith_wheel > 0 && ~isempty(wheelTransforms{ith_wheel})
                parentHandle = wheelTransforms{ith_wheel};
            end
            newPatches = fcn_INTERNAL_patchesByAlpha(vehicleMesh, theseFaces, faceColors, faceAlpha, patchStyle, parentHandle);
            setPatches = [setPatches; newPatches(:)]; %#ok<AGROW>
        end
        if ~isempty(setPatches)
            hiddenPatches{ith_set} = vertcat(setPatches{:});
            set(hiddenPatches{ith_set}, 'Visible', 'off', 'DisplayName', sprintf('Hidden: %s', hiddenSetNames{ith_set}));
            patchHandles = [patchHandles; setPatches]; %#ok<AGROW>
        end
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
        % (a lamp under a clear cover glows around its cover, the glass
        % it is seen through, so the glow does not poke through the cover)
        faceEffectGroup = fcn_INTERNAL_effectGroups(vehicleMesh, faceLightGroup, faceCoverGroup);
        lightEffects = fcn_INTERNAL_makeLightEffects(vehicleMesh, faceEffectGroup, lightGroupNames, transformHandle, bodyTransform);
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
    plotHandles.LightOffAlpha = lightOffAlpha;
    plotHandles.LightOnAlpha = lightOnAlpha;
    plotHandles.LightGroupNames = lightGroupNames;
    plotHandles.LampSwitching = fcn_INTERNAL_lampSwitching(vehicleMesh);   % (what lights the fog, reflector, plate, marker and warning lamps)
    plotHandles.FaceLighting = faceLighting;
    plotHandles.LightEffects = lightEffects;
    plotHandles.CoverPatches = coverPatches;
    plotHandles.CoverOffColors = coverOffColors;
    plotHandles.CoverOffAlpha = coverOffAlpha;
    plotHandles.CoverOnAlpha = coverOnAlpha;
    plotHandles.HiddenSetNames = hiddenSetNames;
    plotHandles.HiddenPatches = hiddenPatches;

    % Set the pose, wheels, and lights
    transformHandle.Matrix = poseMatrix;
    fcn_INTERNAL_updateBody(plotHandles, options);
    fcn_INTERNAL_updateWheels(plotHandles, options.WheelSpin, options.SteerAngle, options.WheelLift);
    if ~isempty(options.LightStates)
        fcn_INTERNAL_updateLights(plotHandles, options.LightStates);
    end
    if ~isempty(options.ShowHidden)
        fcn_INTERNAL_showHidden(plotHandles, options.ShowHidden);
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
lightGroupNames = {'headlight','turnLeft','turnRight','running','tail','backup','highBeam', ...
    'fog','reflector','licenseplate','marker','warning'};   % (the last five: Sean, task 8)
end % Ends fcn_INTERNAL_lightGroupNames

%% fcn_INTERNAL_faceLightGroups
function [faceLightGroup, lightGroupNames] = fcn_INTERNAL_faceLightGroups(vehicleMesh)
% Returns, for each face, its light group index (0 = not a switchable
% light), and the groups' names. Turn signals are split into left and
% right by position. A face with several light functions
% (FaceLightFunctions: a tail light that is also a turn signal) is in a
% group of its own, named by its functions joined with '_' (such as
% 'turnLeft_tail'), after the single groups.
Nfaces = size(vehicleMesh.Faces,1);
faceLightGroup = zeros(Nfaces,1);
lightGroupNames = fcn_INTERNAL_lightGroupNames;
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
faceLightGroup(strcmp(faceTypeName,'highbeam')) = 7;
for ith_new = 8:numel(lightGroupNames)   % (fog, reflector, licenseplate, marker, warning: named as their types)
    faceLightGroup(strcmp(faceTypeName, lightGroupNames{ith_new})) = ith_new;
end

% Faces with several light functions: a group for each combination
if isfield(vehicleMesh,'FaceLightFunctions') && size(vehicleMesh.FaceLightFunctions,1) == Nfaces ...
        && size(vehicleMesh.FaceLightFunctions,2) == numel(lightTypeNames)
    functions = logical(vehicleMesh.FaceLightFunctions);
    functions(sub2ind(size(functions), find(flagLight), faceLightType(flagLight))) = true;   % (its own type too)
    multiFaces = find(sum(functions,2) > 1);
    baseNames = fcn_INTERNAL_lightGroupNames;
    for ith_face = multiFaces(:)'
        members = {};
        for typeName = lightTypeNames(functions(ith_face,:))'
            switch typeName{1}
                case 'turnsignal'
                    if faceCentersY(ith_face) > 0
                        members{end+1} = 'turnLeft'; %#ok<AGROW>
                    else
                        members{end+1} = 'turnRight'; %#ok<AGROW>
                    end
                case 'highbeam'
                    members{end+1} = 'highBeam'; %#ok<AGROW>
                otherwise
                    members{end+1} = typeName{1}; %#ok<AGROW>
            end
        end
        [~, order] = ismember(members, baseNames);
        members = baseNames(sort(order(order>0)));
        if numel(members) < 2
            continue;
        end
        comboName = strjoin(members, '_');
        comboIndex = find(strcmp(lightGroupNames, comboName), 1);
        if isempty(comboIndex)
            lightGroupNames{end+1} = comboName; %#ok<AGROW>
            comboIndex = numel(lightGroupNames);
        end
        faceLightGroup(ith_face) = comboIndex;
    end
end
end % Ends fcn_INTERNAL_faceLightGroups

%% fcn_INTERNAL_faceCoverGroups
function faceCoverGroup = fcn_INTERNAL_faceCoverGroups(vehicleMesh, faceLightGroup, lightGroupNames, flagSkip)
% Returns, for each face that is a lamp's clear cover (glass with a
% FaceCoverLamp), the light group it is switched with: the group of the
% nearest lamp face of the type it covers (so a turn signal's cover goes
% with the lamp on its own side, and a cover over a lamp with several
% functions goes with that lamp's combined group). If no such lamp is
% drawn, the group of its type (turn signals by side). 0 for all other
% faces, and for the faces skipped (hidden faces, wheels).
Nfaces = size(vehicleMesh.Faces,1);
faceCoverGroup = zeros(Nfaces,1);
if ~isfield(vehicleMesh,'FaceCoverLamp') || numel(vehicleMesh.FaceCoverLamp) ~= Nfaces ...
        || ~isfield(vehicleMesh,'PartNames') || ~isfield(vehicleMesh,'FacePartIndex') || ~isfield(vehicleMesh,'LightTypeNames')
    return;
end
glassIndex = find(strcmp(vehicleMesh.PartNames, 'glass'), 1);
coverType = double(vehicleMesh.FaceCoverLamp(:));
% (a cover is glass: a face painted as something else since is not one)
flagCover = coverType > 0 & coverType <= numel(vehicleMesh.LightTypeNames) & ~flagSkip(:);
if isempty(glassIndex)
    return;
end
flagCover = flagCover & vehicleMesh.FacePartIndex(:)==glassIndex;
if ~any(flagCover)
    return;
end
faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
lampFaces = find(faceLightGroup > 0);
faceLightType = double(vehicleMesh.FaceLightType(:));
baseGroups = struct('headlight',1,'running',4,'tail',5,'backup',6,'highbeam',7, ...
    'fog',8,'reflector',9,'licenseplate',10,'marker',11,'warning',12);
for thisType = unique(coverType(flagCover))'
    theseCovers = find(flagCover & coverType==thisType);
    sameType = lampFaces(faceLightType(lampFaces)==thisType);
    if ~isempty(sameType)
        nearest = fcn_INTERNAL_nearestPoint(faceCenters(sameType,:), faceCenters(theseCovers,:));
        faceCoverGroup(theseCovers) = faceLightGroup(sameType(nearest));
    else
        typeName = vehicleMesh.LightTypeNames{thisType};
        if strcmp(typeName, 'turnsignal')
            faceCoverGroup(theseCovers) = 2 + (faceCenters(theseCovers,2) <= 0);   % (2 left, 3 right)
        elseif isfield(baseGroups, typeName)
            faceCoverGroup(theseCovers) = baseGroups.(typeName);
        end
    end
end
faceCoverGroup(faceCoverGroup > numel(lightGroupNames)) = 0;
end % Ends fcn_INTERNAL_faceCoverGroups

%% fcn_INTERNAL_effectGroups
function faceEffectGroup = fcn_INTERNAL_effectGroups(vehicleMesh, faceLightGroup, faceCoverGroup)
% The light group of each face for the light effects (glows and pools):
% a lamp's clear cover is in its lamp's group, and the lamp faces under
% a cover (within 10 cm of one of its group's cover faces) are left out,
% so the glow is a shell around the cover, not around the lamp behind it
% (which would poke through the cover)
faceEffectGroup = faceLightGroup;
if ~any(faceCoverGroup)
    return;
end
underDistance = 0.10;   % How far behind its cover a lamp face can be [m]
faceCenters = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
for thisGroup = unique(faceCoverGroup(faceCoverGroup>0))'
    coverFaces = find(faceCoverGroup==thisGroup);
    lampFaces = find(faceLightGroup==thisGroup);
    if ~isempty(lampFaces)
        nearest = fcn_INTERNAL_nearestPoint(faceCenters(coverFaces,:), faceCenters(lampFaces,:));
        flagUnder = vecnorm(faceCenters(lampFaces,:) - faceCenters(coverFaces(nearest),:), 2, 2) <= underDistance;
        faceEffectGroup(lampFaces(flagUnder)) = 0;
    end
    faceEffectGroup(coverFaces) = thisGroup;
end
end % Ends fcn_INTERNAL_effectGroups

%% fcn_INTERNAL_nearestPoint
function nearest = fcn_INTERNAL_nearestPoint(fromPoints, toPoints)
% The index of the nearest of fromPoints for each of toPoints (in blocks;
% no toolbox needed)
nearest = zeros(size(toPoints,1),1);
blockSize = 400;
for first = 1:blockSize:size(toPoints,1)
    rows = first:min(size(toPoints,1), first+blockSize-1);
    squaredDistance = sum(toPoints(rows,:).^2,2) + sum(fromPoints.^2,2)' - 2*toPoints(rows,:)*fromPoints';
    [~, nearest(rows)] = min(squaredDistance, [], 2);
end
end % Ends fcn_INTERNAL_nearestPoint

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
if isfield(plotHandles,'LightGroupNames')
    lightGroupNames = plotHandles.LightGroupNames;
else
    lightGroupNames = {'headlight','turnLeft','turnRight','running','tail','backup'};   % (handles made before multi-function lights)
end
% (no high beam lamps: the headlights light white for the high beams)
flagHighFaces = isfield(plotHandles.LightPatches,'highBeam') && ~isempty(plotHandles.LightPatches.highBeam);
% (what lights the lamp types switched from fcn_CarMesh3D_lampTypes)
lampSwitching = struct;
if isfield(plotHandles,'LampSwitching')
    lampSwitching = plotHandles.LampSwitching;
end
for ith_group = 1:length(lightGroupNames)
    thisName = lightGroupNames{ith_group};
    thisPatch = plotHandles.LightPatches.(thisName);
    if isempty(thisPatch)
        continue;
    end
    onColor = fcn_INTERNAL_lightColor(thisName, lightStates, flagHighFaces, lampSwitching);
    offColors = plotHandles.LightOffColors.(thisName);
    if ~iscell(offColors)
        offColors = {offColors};   % (handles made before 2026_11_22: one patch)
    end
    % (each patch's transparency off and on: a lamp's clear cover is
    % see-through glass while off and opaque while on)
    offAlpha = {};
    onAlpha = {};
    if isfield(plotHandles,'LightOffAlpha') && isfield(plotHandles.LightOffAlpha, thisName)
        offAlpha = plotHandles.LightOffAlpha.(thisName);
        onAlpha = plotHandles.LightOnAlpha.(thisName);
    end
    for ith_patch = 1:numel(thisPatch)
        if isempty(onColor)
            set(thisPatch(ith_patch),'FaceVertexCData',offColors{ith_patch},...
                'FaceLighting',plotHandles.FaceLighting);
            if numel(offAlpha) >= ith_patch && ~isempty(onAlpha{ith_patch})
                set(thisPatch(ith_patch),'FaceAlpha',offAlpha{ith_patch});
            end
        else
            set(thisPatch(ith_patch),'FaceVertexCData',fcn_INTERNAL_litColors(onColor, offColors{ith_patch}),...
                'FaceLighting','none');
            if numel(onAlpha) >= ith_patch && ~isempty(onAlpha{ith_patch})
                set(thisPatch(ith_patch),'FaceAlpha',onAlpha{ith_patch});
            end
        end
    end
end

% Lamp covers: clear glass while their lamp is off; tinted with the
% lamp's lit color, partly see-through and unshaded, while it is on
if isfield(plotHandles,'CoverPatches')   % (handles made before 2026_11_23 have no covers)
    for ith_group = 1:length(lightGroupNames)
        thisName = lightGroupNames{ith_group};
        if ~isfield(plotHandles.CoverPatches, thisName) || isempty(plotHandles.CoverPatches.(thisName))
            continue;
        end
        thisCover = plotHandles.CoverPatches.(thisName);
        onColor = fcn_INTERNAL_lightColor(thisName, lightStates, flagHighFaces, lampSwitching);
        offColors = plotHandles.CoverOffColors.(thisName);
        offAlpha = plotHandles.CoverOffAlpha.(thisName);
        for ith_patch = 1:numel(thisCover)
            if isempty(onColor)
                set(thisCover(ith_patch),'FaceVertexCData',offColors{ith_patch},...
                    'FaceAlpha',offAlpha{ith_patch},'FaceLighting',plotHandles.FaceLighting);
            else
                set(thisCover(ith_patch),'FaceVertexCData',fcn_INTERNAL_litColors(onColor, offColors{ith_patch}),...
                    'FaceAlpha',plotHandles.CoverOnAlpha,'FaceLighting','none');
            end
        end
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
    onColor = fcn_INTERNAL_lightColor(thisName, lightStates, flagHighFaces, lampSwitching);
    if isempty(onColor)
        fcn_INTERNAL_setVisible(thisGlow, false);
    else
        if isscalar(onColor)   % (glowing in its own colors: the lamp's colors, brighter, on average)
            lampColors = plotHandles.LightOffColors.(thisName);
            if iscell(lampColors)
                lampColors = vertcat(lampColors{:});
            end
            onColor = mean(fcn_INTERNAL_litColors(onColor, lampColors), 1);
        end
        set(thisGlow,'FaceColor',onColor);
        fcn_INTERNAL_setVisible(thisGlow, true);
    end
end
[flagLowBeam, flagHighBeam] = fcn_INTERNAL_beams(lightStates);
tailState = fcn_INTERNAL_stateValue(lightStates,'Tail','off');
if islogical(tailState) || isnumeric(tailState)
    if tailState
        tailState = 'on';
    else
        tailState = 'off';
    end
end
tailState = lower(char(tailState));
fcn_INTERNAL_setVisible(lightEffects.Pools.lowBeam, flagLowBeam);
fcn_INTERNAL_setVisible(lightEffects.Pools.highBeam, flagHighBeam);
fcn_INTERNAL_setVisible(lightEffects.Pools.tail, strcmp(tailState,'on'));
fcn_INTERNAL_setVisible(lightEffects.Pools.brake, strcmp(tailState,'brake'));
fcn_INTERNAL_setVisible(lightEffects.Pools.backup, fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates,'Backup',false)));
if isfield(lightEffects.Pools, 'turnLeftFront')   % (handles made before 2026_11_23 have no turn pools)
    flagLeft = fcn_INTERNAL_turnOn(lightStates, 'TurnLeft');
    flagRight = fcn_INTERNAL_turnOn(lightStates, 'TurnRight');
    fcn_INTERNAL_setVisible(lightEffects.Pools.turnLeftFront, flagLeft);
    fcn_INTERNAL_setVisible(lightEffects.Pools.turnLeftRear, flagLeft);
    fcn_INTERNAL_setVisible(lightEffects.Pools.turnRightFront, flagRight);
    fcn_INTERNAL_setVisible(lightEffects.Pools.turnRightRear, flagRight);
end
end % Ends fcn_INTERNAL_updateLights

%% fcn_INTERNAL_showHidden
function fcn_INTERNAL_showHidden(plotHandles, showHidden)
% Switches the hidden sets on (those named, or all for true) and the
% others off (all off for false)
if ~isfield(plotHandles,'HiddenPatches')
    return;
end
setNames = plotHandles.HiddenSetNames;
if islogical(showHidden) && isscalar(showHidden)
    flagShow = repmat(showHidden, numel(setNames), 1);
else
    flagShow = ismember(setNames, cellstr(showHidden));
end
for ith_set = 1:numel(setNames)
    if ~isempty(plotHandles.HiddenPatches{ith_set})
        onOff = {'off','on'};
        set(plotHandles.HiddenPatches{ith_set}, 'Visible', onOff{1 + flagShow(ith_set)});
    end
end
end % Ends fcn_INTERNAL_showHidden

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
frontVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, find(fcn_INTERNAL_groupHas(lightGroupNames, {'headlight','highBeam'})));
rearVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, find(fcn_INTERNAL_groupHas(lightGroupNames, {'tail','backup'})));
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

% The turn signals' corners: from their lamps, else the headlights and
% tail lights (or the mesh's corners) found above
turnFrontX = frontX;
turnRearX = rearX;
turnFrontY = max(frontHalfSpacing, 0.35*(meshHigh(2) - meshLow(2)));
turnRearY = max(rearHalfSpacing, 0.35*(meshHigh(2) - meshLow(2)));
turnVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, find(fcn_INTERNAL_groupHas(lightGroupNames, {'turnLeft','turnRight'})));
middleX = 0.5*(meshLow(1) + meshHigh(1));
if any(turnVertices(:,1) > middleX)
    frontTurn = turnVertices(turnVertices(:,1) > middleX,:);
    turnFrontX = max(frontTurn(:,1));
    turnFrontY = mean(abs(frontTurn(:,2)));
end
if any(turnVertices(:,1) <= middleX)
    rearTurn = turnVertices(turnVertices(:,1) <= middleX,:);
    turnRearX = min(rearTurn(:,1));
    turnRearY = mean(abs(rearTurn(:,2)));
end

% The pools: start x, direction (+1 ahead, -1 behind), half spacing [m],
% length [m], spread half angle [deg], peak alpha, height above the
% ground [m], center y [m] (+ left), color. Change these numbers to
% change the look of the beams. Pools that can be on together get
% different heights, so the graphics card does not flicker between them
% ("z-fighting").
poolList = {
    'lowBeam',        frontX,     +1, frontHalfSpacing,     15,  16, 0.50, 0.010, 0,           [1.00 0.95 0.78];
    'highBeam',       frontX,     +1, 0.8*frontHalfSpacing, 40,   6, 0.40, 0.025, 0,           [1.00 1.00 0.95];
    'tail',           rearX,      -1, rearHalfSpacing,      2.0, 45, 0.15, 0.010, 0,           [1.00 0.08 0.05];
    'brake',          rearX,      -1, rearHalfSpacing,      3.0, 45, 0.40, 0.010, 0,           [1.00 0.10 0.06];
    'backup',         rearX,      -1, rearHalfSpacing,      6.0, 30, 0.45, 0.025, 0,           [1.00 1.00 1.00];
    'turnLeftFront',  turnFrontX, +1, 0.05,                 1.6, 50, 0.45, 0.018, +turnFrontY, [1.00 0.55 0.00];
    'turnRightFront', turnFrontX, +1, 0.05,                 1.6, 50, 0.45, 0.018, -turnFrontY, [1.00 0.55 0.00];
    'turnLeftRear',   turnRearX,  -1, 0.05,                 1.6, 50, 0.45, 0.018, +turnRearY,  [1.00 0.10 0.06];
    'turnRightRear',  turnRearX,  -1, 0.05,                 1.6, 50, 0.45, 0.018, -turnRearY,  [1.00 0.10 0.06]};
for ith_pool = 1:size(poolList,1)
    [poolVertices, poolFaces, poolAlpha] = fcn_INTERNAL_poolMesh(poolList{ith_pool,2:9});
    lightEffects.Pools.(poolList{ith_pool,1}) = patch('Parent',groundParent, ...
        'Faces',poolFaces,'Vertices',poolVertices, ...
        'FaceColor',poolList{ith_pool,10},'EdgeColor','none','FaceLighting','none', ...
        'FaceVertexAlphaData',poolAlpha,'FaceAlpha','interp','AlphaDataMapping','none', ...
        'Visible','off','HitTest','off','DisplayName',sprintf('Light pool: %s',poolList{ith_pool,1}));
end
end % Ends fcn_INTERNAL_makeLightEffects

%% fcn_INTERNAL_groupHas
function flagHas = fcn_INTERNAL_groupHas(lightGroupNames, members)
% Which groups have any of these members (a combined group, such as
% 'turnLeft_tail', has each of its parts)
flagHas = cellfun(@(name) any(ismember(split(name, '_'), members)), lightGroupNames);
end % Ends fcn_INTERNAL_groupHas

%% fcn_INTERNAL_groupVertices
function groupVertices = fcn_INTERNAL_groupVertices(vehicleMesh, faceLightGroup, groupIndices)
% The vertices of the faces in the given light groups (empty if none)
theseFaces = vehicleMesh.Faces(ismember(faceLightGroup, groupIndices),:);
groupVertices = vehicleMesh.Vertices(unique(theseFaces(:)),:);
end % Ends fcn_INTERNAL_groupVertices

%% fcn_INTERNAL_poolMesh
function [vertices, faces, vertexAlpha] = fcn_INTERNAL_poolMesh(startX, direction, halfSpacing, poolLength, spreadDegrees, peakAlpha, poolZ, centerY)
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
y = centerY + acrossGrid.*halfWidthGrid;
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
function [flagLowBeam, flagHighBeam] = fcn_INTERNAL_beams(lightStates)
% Which headlight beams are on: Headlights ('low' the low beams, 'high'
% both), each overridden by LowBeam or HighBeam when given
headlightState = lower(char(string(fcn_INTERNAL_stateValue(lightStates,'Headlights','off'))));
flagLowBeam = any(strcmp(headlightState, {'low','high'}));
flagHighBeam = strcmp(headlightState, 'high');
if isfield(lightStates, 'LowBeam') && ~isempty(lightStates.LowBeam)
    flagLowBeam = fcn_INTERNAL_isOn(lightStates.LowBeam);
end
if isfield(lightStates, 'HighBeam') && ~isempty(lightStates.HighBeam)
    flagHighBeam = fcn_INTERNAL_isOn(lightStates.HighBeam);
end
end % Ends fcn_INTERNAL_beams

%% fcn_INTERNAL_lightColor
function onColor = fcn_INTERNAL_lightColor(groupName, lightStates, flagHighFaces, lampSwitching)
% The glowing color of a light group in the given states, or [] if off.
% A combined group ('turnLeft_tail') glows when any of its functions is
% on: a turn signal flashing wins (in red when the lamp is also a tail
% light, as on many US cars), then the warning lamps, the brake and tail,
% the headlights, the fog lamps, the running lights and marker lamps, the
% license plate lamp, backing up, and the reflectors.
% A number (0 to 1) in place of a color means "the lamp's own colors,
% made that much brighter" (reflectors, marker and warning lamps)
onColor = [];
if contains(groupName, '_')
    members = split(groupName, '_');
    priority = {'turnLeft','turnRight','warning','tail','highBeam','headlight','fog','running','marker', ...
        'licenseplate','backup','reflector'};
    for thisMember = priority
        if any(strcmp(members, thisMember{1}))
            onColor = fcn_INTERNAL_lightColor(thisMember{1}, lightStates, flagHighFaces, lampSwitching);
            if ~isempty(onColor)
                if startsWith(thisMember{1}, 'turn') && any(strcmp(members, 'tail'))
                    onColor = [1.00 0.12 0.08];   % (a red turn signal)
                end
                return;
            end
        end
    end
    return;
end
switch groupName
    case 'headlight'
        % (the low beams; with no high beam lamps, the high beams too)
        [flagLowBeam, flagHighBeam] = fcn_INTERNAL_beams(lightStates);
        if flagHighBeam && ~flagHighFaces
            onColor = [1.00 1.00 1.00];
        elseif flagLowBeam
            onColor = [1.00 0.96 0.78];
        end
    case 'highBeam'
        [~, flagHighBeam] = fcn_INTERNAL_beams(lightStates);
        if flagHighBeam
            onColor = [1.00 1.00 1.00];
        end
    case 'turnLeft'
        if fcn_INTERNAL_turnOn(lightStates, 'TurnLeft')
            onColor = [1.00 0.55 0.00];
        end
    case 'turnRight'
        if fcn_INTERNAL_turnOn(lightStates, 'TurnRight')
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
    case {'fog','licenseplate','marker','warning','reflector'}
        % (switched by the states listed for the type: the vehicle's own
        % LampSwitching, else fcn_CarMesh3D_lampTypes' default; any one
        % on lights it. Fog and the plate lamp in fixed colors; the
        % others in their own colors, brighter: Sean, task 8)
        amount = 0;
        if isfield(lampSwitching, groupName)
            for stateName = reshape(cellstr(lampSwitching.(groupName)), 1, [])
                amount = max(amount, fcn_INTERNAL_stateAmount(lightStates, stateName{1}));
            end
        end
        if amount > 0
            switch groupName
                case 'fog'
                    onColor = [1.00 0.97 0.85];
                case 'licenseplate'
                    onColor = [1.00 1.00 0.95];
                otherwise
                    onColor = min(1, amount);
            end
        end
end
end % Ends fcn_INTERNAL_lightColor

%% fcn_INTERNAL_stateAmount
function amount = fcn_INTERNAL_stateAmount(lightStates, stateName)
% How much a LightStates field is on, 0 to 1: Headlights 'low' or 'high',
% LowBeam and HighBeam as the beams are, Tail 'on' or 'brake', Reflectors
% its value, any other field 1 when true
switch stateName
    case 'LowBeam'
        [flagLow, ~] = fcn_INTERNAL_beams(lightStates);
        amount = double(flagLow);
    case 'HighBeam'
        [~, flagHigh] = fcn_INTERNAL_beams(lightStates);
        amount = double(flagHigh);
    case 'Headlights'
        [flagLow, flagHigh] = fcn_INTERNAL_beams(lightStates);
        amount = double(flagLow || flagHigh);
    case 'Tail'
        state = fcn_INTERNAL_stateValue(lightStates,'Tail','off');
        if ischar(state) || isstring(state)
            amount = double(any(strcmpi(char(state), {'on','brake'})));
        else
            amount = double(fcn_INTERNAL_isOn(state));
        end
    case 'Reflectors'
        value = double(fcn_INTERNAL_stateValue(lightStates,'Reflectors',0));
        amount = 0;
        if ~isempty(value)
            amount = min(1, max(0, value(1)));
        end
    otherwise
        amount = double(fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates, stateName, false)));
end
end % Ends fcn_INTERNAL_stateAmount

%% fcn_INTERNAL_lampSwitching
function lampSwitching = fcn_INTERNAL_lampSwitching(vehicleMesh)
% What lights each lamp type switched from a list: fcn_CarMesh3D_lampTypes'
% defaults, replaced type by type by the vehicle's own LampSwitching
% (makers switch fog lamps, for one, in several ways: Sean, 23:23)
lampSwitching = struct;
for thisType = fcn_CarMesh3D_lampTypes()'
    if ~isempty(thisType.SwitchedByStates)
        lampSwitching.(thisType.Name) = thisType.SwitchedByStates;
    end
end
if isfield(vehicleMesh,'LampSwitching') && isstruct(vehicleMesh.LampSwitching)
    for typeName = fieldnames(vehicleMesh.LampSwitching)'
        lampSwitching.(typeName{1}) = cellstr(vehicleMesh.LampSwitching.(typeName{1}));
    end
end
end % Ends fcn_INTERNAL_lampSwitching

%% fcn_INTERNAL_turnOn
function flagOn = fcn_INTERNAL_turnOn(lightStates, fieldName)
% Is a turn signal on: its own state (TurnLeft or TurnRight), or the
% hazards (both)
flagOn = fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates, fieldName, false)) ...
    || fcn_INTERNAL_isOn(fcn_INTERNAL_stateValue(lightStates, 'Hazards', false));
end % Ends fcn_INTERNAL_turnOn

%% fcn_INTERNAL_litColors
function litColors = fcn_INTERNAL_litColors(onColor, offColors)
% The colors of a lit patch: one color for every face (onColor, 1 x 3),
% or, when onColor is a number from 0 to 1, the faces' own colors made
% that much brighter (each toward its own hue at full brightness)
if numel(onColor) == 3
    litColors = repmat(reshape(onColor, 1, 3), size(offColors,1), 1);
else
    brightest = offColors ./ max(max(offColors, [], 2), eps);
    litColors = offColors + onColor * (brightest - offColors);
end
end % Ends fcn_INTERNAL_litColors

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

%% fcn_INTERNAL_alsoGlass
function flagAlsoGlass = fcn_INTERNAL_alsoGlass(vehicleMesh)
% The light faces that are also glass (FaceAlsoParts): lamps' clear covers
Nfaces = size(vehicleMesh.Faces,1);
flagAlsoGlass = false(Nfaces,1);
if ~isfield(vehicleMesh,'FaceAlsoParts') || size(vehicleMesh.FaceAlsoParts,1) ~= Nfaces ...
        || ~isfield(vehicleMesh,'PartNames') || ~isfield(vehicleMesh,'FacePartIndex')
    return;
end
glassIndex = find(strcmp(vehicleMesh.PartNames, 'glass'), 1);
lightIndex = find(strcmp(vehicleMesh.PartNames, 'light'), 1);
if isempty(glassIndex) || isempty(lightIndex) || glassIndex > size(vehicleMesh.FaceAlsoParts,2)
    return;
end
flagAlsoGlass = vehicleMesh.FaceAlsoParts(:,glassIndex) & vehicleMesh.FacePartIndex(:)==lightIndex;
end % Ends fcn_INTERNAL_alsoGlass

%% fcn_INTERNAL_glassLook
function [glassColor, glassAlpha] = fcn_INTERNAL_glassLook(vehicleMesh, faceColors, faceAlpha)
% The vehicle's glass color and transparency: the median of its glass
% faces (else a dark see-through gray)
glassColor = [0.15 0.20 0.25];
glassAlpha = 0.35;
glassIndex = find(strcmp(vehicleMesh.PartNames, 'glass'), 1);
flagGlass = vehicleMesh.FacePartIndex(:)==glassIndex;
if ~isempty(glassIndex) && any(flagGlass)
    glassColor = median(faceColors(flagGlass,:), 1);
    glassAlpha = median(faceAlpha(flagGlass));
end
end % Ends fcn_INTERNAL_glassLook

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
