function [flagContact, clearance, lowestPoint] = fcn_CarMesh3D_checkGroundContact(vehicleMesh, bodyRoll, bodyPitch, bodyHeave, options)
% fcn_CarMesh3D_checkGroundContact
% Checks, at each time step, whether the body (the sprung mass) has rolled,
% pitched, or dropped so far that part of it reaches the ground: for
% example, a front corner of the bumper pushed down in hard braking while
% turning. Contact means body damage is likely, unless that part of the
% vehicle is protected (for example, by a skid plate).
%
% HOW IT WORKS. The body is moved exactly as fcn_CarMesh3D_plotVehicle
% moves it: rolled and pitched about BodyPivot, then raised by BodyHeave,
% relative to the ground frame (the road plane under the vehicle). For
% every body vertex (every face that is not a wheel), its height above
% the road is then:
%
%       z = heave + pivotZ + [-sin(pitch), cos(pitch)*sin(roll),
%                              cos(pitch)*cos(roll)] * (vertex - pivot)
%
% The lowest vertex at each time is the clearance. When the clearance is
% at or below MinimumClearance (default 0, the road surface), the flag is
% true. The road is treated as flat under the vehicle; bumps and curbs are
% not modeled.
%
% FORMAT:
%
%       [flagContact, clearance, lowestPoint] = ...
%           fcn_CarMesh3D_checkGroundContact(vehicleMesh, bodyRoll,...
%           bodyPitch, bodyHeave, (BodyPivot=[x y z]),...
%           (MinimumClearance=c), (Time=t), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a fitted mesh (fcn_CarMesh3D_fitMeshToSpec), labeled
%      so the wheels are known (FaceWheelIndex).
%
%      bodyRoll, bodyPitch: N x 1 body roll and pitch relative to the
%      ground frame, in radians (ISO 8855: + roll lowers the right side,
%      + pitch lowers the nose). For example motion.BodyRoll and
%      motion.BodyPitch from fcn_CarMesh3D_loadMotionCSV.
%
%      bodyHeave: N x 1 body displacement up from equilibrium, in meters
%      (motion.BodyHeave), or a scalar (used for every time).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      BodyPivot: the point [x y z] the body rolls and pitches about, in
%      the vehicle frame. Default [] uses the same point as
%      fcn_CarMesh3D_plotVehicle: midway between the axles, on the
%      centerline, at wheel-center height.
%
%      MinimumClearance: the lowest allowed height above the road, in
%      meters. Default 0 (touching the road). Use a positive value for a
%      safety margin.
%
%      Time: N x 1 times, used for the warning message and the plot.
%      Default [] (sample numbers are used).
%
%      FigNum: a figure number to plot the clearance over time, and a side
%      and front view of the body at the lowest moment. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped,
%      no plot is made, and no warning is printed (fast mode).
%
% OUTPUTS:
%
%      flagContact: N x 1 logical, true where the body reaches the road.
%
%      clearance: N x 1 height of the lowest body point above the road,
%      in meters (negative means it would be below the road surface).
%
%      lowestPoint: N x 3 position of that lowest point on the body, in
%      the body's own (unmoved) vehicle frame, to tell which part it is
%      (for example, x > front axle and y < 0 is the front right).
%
%      Unless in fast mode, a warning is printed when any flag is true,
%      giving how many samples and the first time.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       motion = fcn_CarMesh3D_loadMotionCSV('myRun.csv');
%       flagContact = fcn_CarMesh3D_checkGroundContact(vehicleMesh, ...
%           motion.BodyRoll, motion.BodyPitch, motion.BodyHeave, Time=motion.Time, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_checkGroundContact.m for a full
%       test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkGroundContact
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkGroundContact
%   % * Optional road profile (bumps, curbs) under the vehicle



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    bodyRoll
    bodyPitch
    bodyHeave
    options.BodyPivot = []          % [x y z]; [] for the plotVehicle default
    options.MinimumClearance = 0    % Lowest allowed height above the road [m]
    options.Time = []               % N x 1 times, for the warning and plot
    options.FigNum = []             % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces') || ~isfield(vehicleMesh,'FaceWheelIndex')
            error('vehicleMesh must be a labeled CarMesh3D mesh (with FaceWheelIndex)');
        end

        % Check the body motion inputs
        Ncheck = numel(bodyRoll);
        if ~isnumeric(bodyRoll) || ~isvector(bodyRoll) || any(~isfinite(bodyRoll))
            error('bodyRoll must be a vector of finite angles, in radians');
        end
        if ~isnumeric(bodyPitch) || numel(bodyPitch)~=Ncheck || any(~isfinite(bodyPitch))
            error('bodyPitch must have the same number of values as bodyRoll');
        end
        if ~isnumeric(bodyHeave) || ~any(numel(bodyHeave)==[1 Ncheck]) || any(~isfinite(bodyHeave))
            error('bodyHeave must be a scalar or have the same number of values as bodyRoll');
        end

        % Check the options
        if ~isempty(options.BodyPivot) && (~isnumeric(options.BodyPivot) || numel(options.BodyPivot)~=3)
            error('BodyPivot must be empty or a point [x y z] in meters');
        end
        if ~isnumeric(options.MinimumClearance) || ~isscalar(options.MinimumClearance)
            error('MinimumClearance must be a number of meters');
        end
        if ~isempty(options.Time) && numel(options.Time)~=Ncheck
            error('Time must have one value per sample');
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

rollValues = bodyRoll(:);
pitchValues = bodyPitch(:);
Nsamples = length(rollValues);
heaveValues = bodyHeave(:);
if isscalar(heaveValues)
    heaveValues = repmat(heaveValues, Nsamples, 1);
end

%%%%
% The body: every vertex used by a face that is not a wheel
bodyFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==0,:);
bodyVertices = vehicleMesh.Vertices(unique(bodyFaces(:)),:);

%%%%
% The pivot (the same default as fcn_CarMesh3D_plotVehicle)
bodyPivot = options.BodyPivot;
if isempty(bodyPivot)
    bodyPivot = fcn_INTERNAL_defaultBodyPivot(vehicleMesh);
end
bodyPivot = bodyPivot(:)';

%%%%
% Height of every body vertex at every time (N x V): the third row of
% Ry(pitch)*Rx(roll), applied to the vertex relative to the pivot
relativeVertices = bodyVertices - bodyPivot;        % V x 3
heightRows = [-sin(pitchValues), cos(pitchValues).*sin(rollValues), cos(pitchValues).*cos(rollValues)]; % N x 3
vertexHeights = heaveValues + bodyPivot(3) + heightRows*relativeVertices';  % N x V
[clearance, lowestIndex] = min(vertexHeights, [], 2);
lowestPoint = bodyVertices(lowestIndex,:);
flagContact = clearance <= options.MinimumClearance;

%%%%
% Warn the user
timeValues = options.Time(:);
if isempty(timeValues)
    timeValues = (1:Nsamples)';
    timeLabel = 'sample';
else
    timeLabel = 'time';
end
if 0==flag_max_speed && any(flagContact)
    firstContact = find(flagContact,1);
    warning('on','backtrace');
    warning(['The body reaches the road (clearance %.3f m or less) in %d of %d samples, first at %s %g. ' ...
        'Body damage is likely there unless that part is protected (for example, by a skid plate).'], ...
        options.MinimumClearance, sum(flagContact), Nsamples, timeLabel, timeValues(firstContact));
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
    tiledlayout(1,2);

    % Clearance over time
    nexttile;
    plot(timeValues, 100*clearance, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(timeValues([1 end]), 100*options.MinimumClearance*[1 1], 'k--');
    plot(timeValues(flagContact), 100*clearance(flagContact), 'r.', 'MarkerSize', 12);
    grid on;
    xlabel(sprintf('%s%s', upper(timeLabel(1)), timeLabel(2:end)));
    ylabel('Lowest body point above the road [cm]');
    title(sprintf('Body clearance: %d of %d samples touch the road', sum(flagContact), Nsamples));

    % The body at its lowest moment, from the front
    [~, worstIndex] = min(clearance);
    nexttile;
    movedVertices = fcn_INTERNAL_moveBody(vehicleMesh.Vertices, bodyPivot, rollValues(worstIndex), pitchValues(worstIndex), heaveValues(worstIndex));
    patch('Faces',bodyFaces,'Vertices',movedVertices,'FaceColor',[0.5 0.6 0.8],'EdgeColor','none','FaceAlpha',0.6);
    hold on;
    wheelFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex>0,:);
    patch('Faces',wheelFaces,'Vertices',vehicleMesh.Vertices,'FaceColor',[0.15 0.15 0.15],'EdgeColor','none');
    lowestMoved = fcn_INTERNAL_moveBody(lowestPoint(worstIndex,:), bodyPivot, rollValues(worstIndex), pitchValues(worstIndex), heaveValues(worstIndex));
    plot3(lowestMoved(1), lowestMoved(2), lowestMoved(3), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
    widthRange = [min(vehicleMesh.Vertices(:,2)) max(vehicleMesh.Vertices(:,2))] + [-0.3 0.3];
    lengthRange = [min(vehicleMesh.Vertices(:,1)) max(vehicleMesh.Vertices(:,1))] + [-0.3 0.3];
    plot3(lengthRange(2)*[1 1], widthRange, [0 0], 'k-', 'LineWidth', 2); % The road surface
    text(lengthRange(2), widthRange(2), 0, ' road', 'VerticalAlignment','bottom', 'HorizontalAlignment','right');
    grid on;
    view(90,0); % Looking back at the front of the vehicle
    set(gca,'DataAspectRatio',[1 1 1]);
    ylim(widthRange);
    zlim([min(-0.2, lowestMoved(3)-0.1), max(movedVertices(:,3))+0.1]);
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(sprintf('Lowest moment (%s %g), from the front', timeLabel, timeValues(worstIndex)));
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

%% fcn_INTERNAL_defaultBodyPivot
function bodyPivot = fcn_INTERNAL_defaultBodyPivot(vehicleMesh)
% Midway between the axles, on the centerline, at wheel-center height
% (as in fcn_CarMesh3D_plotVehicle). Without wheels, the middle of the
% mesh at 40% of its height.
wheelCenters = nan(4,3);
for ith_wheel = 1:4
    theseFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==ith_wheel,:);
    if ~isempty(theseFaces)
        wheelVertices = vehicleMesh.Vertices(unique(theseFaces(:)),:);
        wheelCenters(ith_wheel,:) = (min(wheelVertices,[],1) + max(wheelVertices,[],1))/2;
    end
end
if any(all(isfinite(wheelCenters),2))
    knownCenters = wheelCenters(all(isfinite(wheelCenters),2),:);
    bodyPivot = [(min(knownCenters(:,1)) + max(knownCenters(:,1)))/2, 0, mean(knownCenters(:,3))];
else
    lowCorner = min(vehicleMesh.Vertices,[],1);
    highCorner = max(vehicleMesh.Vertices,[],1);
    bodyPivot = [(lowCorner(1) + highCorner(1))/2, 0, lowCorner(3) + 0.4*(highCorner(3) - lowCorner(3))];
end
end % Ends fcn_INTERNAL_defaultBodyPivot

%% fcn_INTERNAL_moveBody
function movedPoints = fcn_INTERNAL_moveBody(points, bodyPivot, roll, pitch, heave)
% Rolls and pitches points about the pivot, then raises them by heave
% (the same transform as fcn_CarMesh3D_plotVehicle's body transform)
rollMatrix = [1 0 0; 0 cos(roll) -sin(roll); 0 sin(roll) cos(roll)];
pitchMatrix = [cos(pitch) 0 sin(pitch); 0 1 0; -sin(pitch) 0 cos(pitch)];
movedPoints = (pitchMatrix*rollMatrix*(points - bodyPivot)')' + bodyPivot + [0 0 heave];
end % Ends fcn_INTERNAL_moveBody
