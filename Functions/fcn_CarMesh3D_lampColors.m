function lit = fcn_CarMesh3D_lampColors(lampSetup, signals, options)
% fcn_CarMesh3D_lampColors

% How a vehicle's lamps are lit by a set of signals, from its
% lamp-to-function (L2F) matrix (fcn_CarMesh3D_lampSetup): each unit's
% brightness, the color it glows in, and so each lamp face's and each
% cover face's lit color. The one place the lighting rules live:
% fcn_CarMesh3D_plotVehicle and the viewer both use it.
%
% The rules:
%   - A unit's brightness is the largest, over the signals that are on,
%     of its matrix cell times how much the signal is on (the design file,
%     section 4: tail 0.4 and brake 1 together give 1). 0 is off.
%   - Its color follows its kind and the signal that lights it most: a
%     headlamp warm white, white when the high beam lights it most; a
%     turn-signal lamp amber; a tail/brake lamp dark red when dim (the
%     tail), red when bright (the brake), and red when a turn signal
%     lights it (US red rear turns); a backup lamp white; a fog lamp,
%     running lamp and license-plate lamp their own whites; reflectors,
%     marker and warning lamps glow in their own colors, made brighter.
%     A dimmed lamp (the 2009 Fit's running lights, its headlamps at 0.3)
%     is its color, darker.
%   - A unit named in LampFaults answers no signal (a burned-out lamp:
%     the vehicle's matrix is as designed; the fault is the scene's).
%
% FORMAT:
%
%       lit = fcn_CarMesh3D_lampColors(lampSetup, signals,...
%           (LampFaults=unitNames), (FigNum=figNum))
%
% INPUTS:
%
%      lampSetup: from fcn_CarMesh3D_lampSetup.
%
%      signals: the signals, as fcn_CarMesh3D_plotVehicle's
%      Signals (true/false fields): LowBeam, HighBeam (each beam
%      alone; both true for both beams), Running, Parking, TurnLeft,
%      TurnRight, Hazards (both turn signals), Tail, Brake, Backup, Fog,
%      and Reflectors (0 to 1). Missing fields are off.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      LampFaults: names of units that do not light (cell array of text).
%      Default {}.
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      lit: a structure with
%           Amounts: how much each signal is on (1 by signals, 0 to 1)
%           Brightness: each unit's brightness (units by 1, 0 to 1)
%           UnitColor: each unit's glow color (units by 3; NaN when off;
%               for a unit glowing in its own colors, the mean of them)
%           FlagLit, Colors: each face (lamp faces and cover faces) lit or
%               not, and its lit color (faces by 3)
%
% DEPENDENCIES:
%
%      (none: fcn_CarMesh3D_lampSetup does the work once per mesh)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampColors.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampColors
%   % * First write (the lamp-functions plan, item 4): replaces the lamp
%   %   % rules plotVehicle and the viewer each kept

% TO-DO:
%
% (none)



arguments
    lampSetup
    signals
    options.LampFaults = {}     % Units that do not light
    options.FigNum = []         % Not used; -1 for fast mode
end

%% Debugging and Input checks
if ~isequal(options.FigNum, -1)
    if ~(isstruct(lampSetup) && all(isfield(lampSetup, {'Matrix','FaceUnit','FaceCoverUnit','SignalNames'})))
        error('lampSetup must come from fcn_CarMesh3D_lampSetup');
    end
    if ~isempty(signals) && ~isstruct(signals)
        error('signals must be a structure (as fcn_CarMesh3D_plotVehicle''s Signals)');
    end
end
if isempty(signals)
    signals = struct;
end

%% Main code starts here
signalNames = lampSetup.SignalNames;
numUnits = size(lampSetup.Matrix, 1);
numFaces = numel(lampSetup.FaceUnit);

% How much each signal is on
amounts = zeros(1, numel(signalNames));
for ith_signal = 1:numel(signalNames)
    amounts(ith_signal) = fcn_INTERNAL_amount(signals, signalNames{ith_signal});
end

% Each unit's brightness, and the signal that lights it most (a tie goes
% to the later signal: high beams on, with the low beams, light white)
[brightness, strongestFromEnd] = max(fliplr(lampSetup.Matrix .* amounts), [], 2);
strongest = numel(signalNames) + 1 - strongestFromEnd;
if isempty(brightness)
    brightness = zeros(0,1);
    strongest = zeros(0,1);
end
if ~isempty(options.LampFaults) && numUnits > 0
    flagFault = ismember({lampSetup.Units.Name}, cellstr(options.LampFaults));
    brightness(flagFault) = 0;
end

% Each unit's color, and each face's
unitColor = nan(numUnits, 3);
flagLit = false(numFaces, 1);
colors = zeros(numFaces, 3);
for ith_unit = find(brightness(:)' > 0)
    level = brightness(ith_unit);
    strongestSignal = signalNames{strongest(ith_unit)};
    lampFaces = find(lampSetup.FaceUnit == ith_unit | lampSetup.FaceCoverUnit == ith_unit);
    [baseColor, flagOwnColors] = fcn_INTERNAL_kindColor(lampSetup.Kinds{ith_unit}, strongestSignal, level);
    if flagOwnColors
        % (its own colors, made brighter with the level)
        theseColors = lampSetup.FaceOwnColors(lampFaces,:) + level*(lampSetup.FaceBrightColors(lampFaces,:) - lampSetup.FaceOwnColors(lampFaces,:));
        colors(lampFaces,:) = theseColors;
        if ~isempty(theseColors)
            unitColor(ith_unit,:) = mean(theseColors, 1);
        end
    else
        colors(lampFaces,:) = repmat(baseColor, numel(lampFaces), 1);
        unitColor(ith_unit,:) = baseColor;
    end
    flagLit(lampFaces) = true;
end

lit = struct('Amounts', amounts, 'Brightness', brightness(:), 'UnitColor', unitColor, 'FlagLit', flagLit, 'Colors', colors);

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_kindColor
function [color, flagOwnColors] = fcn_INTERNAL_kindColor(kind, strongestSignal, level)
% The color a unit of this kind glows in, lit most by this signal at this
% level (0 to 1); or its own colors (reflectors, marker and warning lamps)
flagOwnColors = false;
dimming = 0.45 + 0.55*level;   % (a dimmed lamp: its color, darker; full at 1)
switch kind
    case 'headlamp'
        if strcmp(strongestSignal, 'HighBeam')
            color = [1.00 1.00 1.00];
        else
            color = [1.00 0.96 0.78];
        end
        color = color*dimming;
    case 'highBeamLamp'
        color = [1.00 1.00 1.00]*dimming;
    case 'turnSignalLamp'
        color = [1.00 0.55 0.00]*dimming;
    case 'tailBrakeLamp'
        if startsWith(strongestSignal, 'Turn')
            color = [1.00 0.12 0.08];   % (a red turn signal, as on many US cars)
        else
            % (dark red when dim, the tail; red when bright, the brake)
            mix = min(1, max(0, (level - 0.4)/0.6));
            color = (1 - mix)*[0.70 0.04 0.04] + mix*[1.00 0.12 0.08];
        end
    case 'backupLamp'
        color = [1.00 1.00 1.00]*dimming;
    case 'runningLamp'
        color = [1.00 0.98 0.90]*dimming;
    case 'fogLamp'
        color = [1.00 0.97 0.85]*dimming;
    case 'licensePlateLamp'
        color = [1.00 1.00 0.95]*dimming;
    otherwise   % (reflector, marker, warning, and kinds the list lacks)
        color = [1 1 1];
        flagOwnColors = true;
end
end % Ends fcn_INTERNAL_kindColor

%% fcn_INTERNAL_amount
function amount = fcn_INTERNAL_amount(signals, signalName)
% How much a signal is on, 0 to 1, from fcn_CarMesh3D_plotVehicle's
% Signals (true/false fields; Reflectors 0 to 1). LowBeam and HighBeam
% each switch one beam (both beams on: both true); Hazards lights both
% turn signals. (The text-valued Headlights and Tail of before 2026-11-26
% are gone: one meaning per name, convention C7)
amount = 0;
switch signalName
    case 'LowBeam'
        amount = double(fcn_INTERNAL_isOn(fcn_INTERNAL_field(signals, 'LowBeam')));   % (each beam alone: both beams on is LowBeam and HighBeam both true)
    case {'TurnLeft', 'TurnRight'}
        amount = double(fcn_INTERNAL_isOn(fcn_INTERNAL_field(signals, signalName)) ...
            || fcn_INTERNAL_isOn(fcn_INTERNAL_field(signals, 'Hazards')));
    case 'Reflectors'
        value = fcn_INTERNAL_field(signals, 'Reflectors');
        if (isnumeric(value) || islogical(value)) && ~isempty(value)
            amount = min(1, max(0, double(value(1))));
        end
    otherwise
        amount = double(fcn_INTERNAL_isOn(fcn_INTERNAL_field(signals, signalName)));
end
end % Ends fcn_INTERNAL_amount

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(signals, fieldName)
% A Signals field, or [] when it is missing
value = [];
if isfield(signals, fieldName)
    value = signals.(fieldName);
end
end % Ends fcn_INTERNAL_field


%% fcn_INTERNAL_isOn
function flagOn = fcn_INTERNAL_isOn(value)
% True for true or a number above 0
flagOn = (islogical(value) || isnumeric(value)) && ~isempty(value) && any(value(:) > 0);
end % Ends fcn_INTERNAL_isOn
