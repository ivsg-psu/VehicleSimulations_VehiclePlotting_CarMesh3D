function vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(options)
% fcn_CarMesh3D_fillVehicleSpec
% Creates a vehicle specification structure that holds the published
% geometric data for one vehicle: overall length, width, height,
% wheelbase, track widths, tire size, and similar values. This structure
% is the "ground truth" that every mesh in the CarMesh3D library is scaled
% to agree with. All lengths are stored in meters.
%
% Students typically find these values on manufacturer specification
% pages. Any value not given is left empty ([]) and is simply not used
% by later fitting and validation steps.
%
% FORMAT:
%
%       vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(...
%           (Preset=presetName),...
%           (Name=nameString),...
%           (OverallLength=L), (OverallWidth=W), (OverallHeight=H),
%           (WidthWithMirrors=WM),...
%           (Wheelbase=WB), (TrackFront=TF), (TrackRear=TR),...
%           (TireSize=tireSizeString), (TireDiameter=D),...
%           (TireSizeRear=tireSizeString), (TireDiameterRear=D),...
%           (FrontOverhang=FOH), (GroundClearance=GC),...
%           (EngineType=engineString), (HybridEngineType=engineString),...
%           (BodyColor=[r g b]), (Source=sourceString),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Preset: a character string naming a set of default values to start
%      from. Allowed values are '' (the default, no preset), 'genericSedan',
%      and 'genericSUV'. Values given by other options always override the
%      preset values. Presets are representative round numbers, not data
%      for any specific vehicle.
%
%      Name: a character string naming the vehicle, for example
%      '2024 Example Sedan'. Default is '' or the preset name.
%
%      OverallLength: bumper-to-bumper length, in meters.
%
%      OverallWidth: body width, in meters. Note: most published widths
%      EXCLUDE the side mirrors. If a mesh includes mirrors, the fitted
%      body will be slightly narrow; see TO-DO in fcn_CarMesh3D_fitMeshToSpec.
%
%      WidthWithMirrors: width including the side mirrors, in meters.
%      Stored for reference (and for future mirror-aware fitting).
%
%      OverallHeight: ground to top of roof, in meters.
%
%      Wheelbase: front axle to rear axle distance, in meters.
%
%      TrackFront: center-to-center distance between the front tires, in
%      meters.
%
%      TrackRear: center-to-center distance between the rear tires, in
%      meters. If empty and TrackFront is given, TrackRear = TrackFront.
%
%      TireSize: a standard tire size string, for example '225/45R17' or
%      'P225/45ZR17': the FRONT tires' size, and the rear tires' too
%      unless TireSizeRear is given. Used to compute TireDiameter when
%      TireDiameter is not given directly.
%
%      TireDiameter: overall tire diameter, in meters: the front tires'
%      (and the rear's, unless TireDiameterRear or TireSizeRear is given).
%      If given, this takes priority over the value computed from
%      TireSize.
%
%      TireSizeRear: the rear tires' size, for vehicles with different
%      front and rear tires (a staggered fitment). Default: TireSize.
%
%      TireDiameterRear: the rear tires' overall diameter, in meters. If
%      given, this takes priority over the value computed from
%      TireSizeRear. Default: from TireSizeRear, else TireDiameter.
%
%      EngineType: what powers the vehicle: 'sparkIgnition' (gasoline),
%      'diesel', 'wankel' (rotary), 'hybrid', or 'electric' (battery
%      electric, no engine). Default '' (not given). Not used for the
%      shape; carried with the spec.
%
%      HybridEngineType: for EngineType 'hybrid', the hybrid's engine:
%      'sparkIgnition', 'diesel', or 'wankel'. Default ''.
%
%      FrontOverhang: front bumper to front axle distance, in meters. If
%      empty, later steps keep the axle placement of the mesh (or assume
%      equal front and rear overhangs).
%
%      GroundClearance: ground to lowest point of the body, in meters.
%      Used only for validation.
%
%      BodyColor: a 1 x 3 RGB color, each value from 0 to 1, for the body
%      paint. Used by fcn_CarMesh3D_labelParts if given.
%
%      Source: a character string noting where the data came from (a URL
%      or citation). Strongly recommended for student work.
%
%      FigNum: a figure number to plot a dimensioned side and top view of
%      the specification. If empty or omitted, no plot is made. If set to
%      -1, input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleSpec: a structure with the fields
%           Name, Units ('m'), OverallLength, OverallWidth,
%           WidthWithMirrors, OverallHeight,
%           Wheelbase, TrackFront, TrackRear, TireSize, TireDiameter,
%           TireSizeRear, TireDiameterRear, FrontOverhang, RearOverhang,
%           GroundClearance, EngineType, HybridEngineType, BodyColor,
%           Source
%      TireSize and TireDiameter are the front tires'; TireSizeRear and
%      TireDiameterRear the rear's (the same as the front's unless given).
%      RearOverhang is computed as OverallLength - Wheelbase -
%      FrontOverhang when all three are known, and is empty otherwise.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_fillVehicleSpec.m for a full
%       test suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillVehicleSpec
%   % * Wrote the code originally (drafted with Claude)
%   % * Added WidthWithMirrors, to match the IVSG vehicleParameters files
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillVehicleSpec
%   % * Front and rear tires can differ: TireSizeRear and
%   %   % TireDiameterRear (TireSize and TireDiameter are the front's)
%   % * Added EngineType ('sparkIgnition', 'diesel', 'wankel', 'hybrid',
%   %   % 'electric') and HybridEngineType

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillVehicleSpec
%   % * Consider a Units option to accept inches/mm directly
%   % * Consider loading specs from a CSV table of many vehicles



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Preset = ''          % '', 'genericSedan', or 'genericSUV'
    options.Name = []            % Vehicle name string
    options.OverallLength = []   % Bumper-to-bumper length [m]
    options.OverallWidth = []    % Body width without mirrors [m]
    options.OverallHeight = []   % Ground to roof [m]
    options.WidthWithMirrors = [] % Width including mirrors [m]
    options.Wheelbase = []       % Axle-to-axle distance [m]
    options.TrackFront = []      % Front tire center spacing [m]
    options.TrackRear = []       % Rear tire center spacing [m]
    options.TireSize = []        % e.g. '225/45R17'
    options.TireDiameter = []    % Overall tire diameter [m] (front; rear too unless given)
    options.TireSizeRear = []    % Rear tire size; [] for TireSize
    options.TireDiameterRear = [] % Rear tire diameter [m]; [] from TireSizeRear or TireDiameter
    options.EngineType = []      % 'sparkIgnition','diesel','wankel','hybrid','electric'
    options.HybridEngineType = [] % For a hybrid: 'sparkIgnition','diesel','wankel'
    options.FrontOverhang = []   % Front bumper to front axle [m]
    options.GroundClearance = [] % Ground to lowest body point [m]
    options.BodyColor = []       % 1 x 3 RGB in [0,1]
    options.Source = []          % Where the data came from
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
numericFieldNames = {'OverallLength','OverallWidth','WidthWithMirrors','OverallHeight',...
    'Wheelbase','TrackFront','TrackRear','TireDiameter','TireDiameterRear',...
    'FrontOverhang','GroundClearance'};
engineTypeNames = {'sparkIgnition','diesel','wankel','hybrid','electric'};
hybridEngineTypeNames = {'sparkIgnition','diesel','wankel'};

if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the Preset input
        if ~(ischar(options.Preset) || isstring(options.Preset))
            error('Preset must be a character string');
        end
        if ~any(strcmpi(char(options.Preset),{'','genericSedan','genericSUV'}))
            error('Preset must be one of: '''', ''genericSedan'', ''genericSUV''. Found: %s',char(options.Preset));
        end

        % Check the numeric inputs: each is empty or a positive scalar
        for ith_field = 1:length(numericFieldNames)
            thisValue = options.(numericFieldNames{ith_field});
            if ~isempty(thisValue)
                if ~isnumeric(thisValue) || ~isscalar(thisValue) || ~isfinite(thisValue) || thisValue<=0
                    error('%s must be empty or a positive, finite, numeric scalar (in meters)',numericFieldNames{ith_field});
                end
            end
        end

        % Check the string inputs
        stringFieldNames = {'Name','TireSize','TireSizeRear','Source','EngineType','HybridEngineType'};
        for ith_field = 1:length(stringFieldNames)
            thisValue = options.(stringFieldNames{ith_field});
            if ~isempty(thisValue) && ~(ischar(thisValue) || isstring(thisValue))
                error('%s must be empty or a character string',stringFieldNames{ith_field});
            end
        end

        % Check the engine types
        if ~isempty(options.EngineType) && ~any(strcmpi(char(options.EngineType), engineTypeNames))
            error('EngineType must be one of: %s. Found: %s', strjoin(engineTypeNames, ', '), char(options.EngineType));
        end
        if ~isempty(options.HybridEngineType)
            if ~any(strcmpi(char(options.HybridEngineType), hybridEngineTypeNames))
                error('HybridEngineType must be one of: %s. Found: %s', strjoin(hybridEngineTypeNames, ', '), char(options.HybridEngineType));
            end
            if ~strcmpi(char(options.EngineType), 'hybrid')
                error('HybridEngineType is given only for EngineType ''hybrid''');
            end
        end

        % Check the BodyColor input
        if ~isempty(options.BodyColor)
            if ~isnumeric(options.BodyColor) || ~isequal(size(options.BodyColor),[1 3]) || any(options.BodyColor<0) || any(options.BodyColor>1)
                error('BodyColor must be empty or a 1 x 3 RGB vector with values from 0 to 1');
            end
        end

        % Check that the length is longer than the wheelbase
        if ~isempty(options.OverallLength) && ~isempty(options.Wheelbase)
            if options.Wheelbase >= options.OverallLength
                error('Wheelbase (%.3f m) must be shorter than OverallLength (%.3f m)',options.Wheelbase,options.OverallLength);
            end
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

% Start from the preset values (or all empty)
vehicleSpec = fcn_INTERNAL_presetSpec(char(options.Preset));

% Any value given by the user overrides the preset
fieldsToCopy = [numericFieldNames, {'Name','TireSize','TireSizeRear','BodyColor','Source','EngineType','HybridEngineType'}];
for ith_field = 1:length(fieldsToCopy)
    thisField = fieldsToCopy{ith_field};
    if ~isempty(options.(thisField))
        thisValue = options.(thisField);
        if isstring(thisValue)
            thisValue = char(thisValue);
        end
        vehicleSpec.(thisField) = thisValue;
    end
end

% Rear track defaults to the front track
if isempty(vehicleSpec.TrackRear) && ~isempty(vehicleSpec.TrackFront)
    vehicleSpec.TrackRear = vehicleSpec.TrackFront;
end

% Tire diameter from the tire size string, if not given directly
if isempty(options.TireDiameter) && ~isempty(vehicleSpec.TireSize)
    vehicleSpec.TireDiameter = fcn_INTERNAL_tireDiameterFromSize(vehicleSpec.TireSize);
end

% The rear tires: their own size or diameter if given, else the front's
% (presets have the same tires front and rear)
if isempty(options.TireSizeRear)
    vehicleSpec.TireSizeRear = vehicleSpec.TireSize;
    if ~isempty(options.TireDiameterRear)
        vehicleSpec.TireSizeRear = '';                  % (a rear diameter without a rear size)
    end
end
if ~isempty(options.TireDiameterRear)
    vehicleSpec.TireDiameterRear = options.TireDiameterRear;
elseif ~isempty(options.TireSizeRear)
    vehicleSpec.TireDiameterRear = fcn_INTERNAL_tireDiameterFromSize(vehicleSpec.TireSizeRear);
else
    vehicleSpec.TireDiameterRear = vehicleSpec.TireDiameter;
end

% Engine type names in their standard spelling
if ~isempty(vehicleSpec.EngineType)
    vehicleSpec.EngineType = engineTypeNames{strcmpi(vehicleSpec.EngineType, engineTypeNames)};
end
if ~isempty(vehicleSpec.HybridEngineType)
    vehicleSpec.HybridEngineType = hybridEngineTypeNames{strcmpi(vehicleSpec.HybridEngineType, hybridEngineTypeNames)};
end

% Rear overhang, if it can be computed
vehicleSpec.RearOverhang = [];
if ~isempty(vehicleSpec.OverallLength) && ~isempty(vehicleSpec.Wheelbase) && ~isempty(vehicleSpec.FrontOverhang)
    vehicleSpec.RearOverhang = vehicleSpec.OverallLength - vehicleSpec.Wheelbase - vehicleSpec.FrontOverhang;
    if vehicleSpec.RearOverhang<=0 && 0==flag_max_speed
        warning('on','backtrace');
        warning('The computed rear overhang (%.3f m) is not positive. Check OverallLength, Wheelbase, and FrontOverhang.',vehicleSpec.RearOverhang);
    end
end

% Keep a consistent field order for easy display
vehicleSpec = orderfields(vehicleSpec, {'Name','Units','OverallLength','OverallWidth',...
    'WidthWithMirrors','OverallHeight','Wheelbase','TrackFront','TrackRear','TireSize','TireDiameter',...
    'TireSizeRear','TireDiameterRear','FrontOverhang','RearOverhang','GroundClearance','EngineType','HybridEngineType',...
    'BodyColor','Source'});

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
    fcn_INTERNAL_plotSpec(vehicleSpec, figNum);
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

%% fcn_INTERNAL_presetSpec
function vehicleSpec = fcn_INTERNAL_presetSpec(presetName)
% Returns a structure with every field, filled from the named preset or
% left empty. Presets are representative round numbers only.
vehicleSpec = struct(...
    'Name','',...
    'Units','m',...
    'OverallLength',[],...
    'OverallWidth',[],...
    'WidthWithMirrors',[],...
    'OverallHeight',[],...
    'Wheelbase',[],...
    'TrackFront',[],...
    'TrackRear',[],...
    'TireSize','',...
    'TireDiameter',[],...
    'TireSizeRear','',...
    'TireDiameterRear',[],...
    'FrontOverhang',[],...
    'RearOverhang',[],...
    'GroundClearance',[],...
    'EngineType','',...
    'HybridEngineType','',...
    'BodyColor',[],...
    'Source','');

switch lower(presetName)
    case lower('genericSedan')
        vehicleSpec.Name = 'Generic sedan';
        vehicleSpec.OverallLength = 4.80;
        vehicleSpec.OverallWidth = 1.85;
        vehicleSpec.OverallHeight = 1.45;
        vehicleSpec.Wheelbase = 2.80;
        vehicleSpec.TrackFront = 1.60;
        vehicleSpec.TrackRear = 1.60;
        vehicleSpec.TireSize = '225/45R17';
        vehicleSpec.FrontOverhang = 0.95;
        vehicleSpec.GroundClearance = 0.14;
        vehicleSpec.BodyColor = [0.10 0.25 0.60];
        vehicleSpec.Source = 'CarMesh3D preset (representative values only)';
    case lower('genericSUV')
        vehicleSpec.Name = 'Generic SUV';
        vehicleSpec.OverallLength = 4.70;
        vehicleSpec.OverallWidth = 1.90;
        vehicleSpec.OverallHeight = 1.75;
        vehicleSpec.Wheelbase = 2.80;
        vehicleSpec.TrackFront = 1.62;
        vehicleSpec.TrackRear = 1.62;
        vehicleSpec.TireSize = '235/60R18';
        vehicleSpec.FrontOverhang = 0.90;
        vehicleSpec.GroundClearance = 0.20;
        vehicleSpec.BodyColor = [0.55 0.10 0.10];
        vehicleSpec.Source = 'CarMesh3D preset (representative values only)';
    otherwise
        % No preset: leave fields empty
end

% Compute tire diameter for presets
if ~isempty(vehicleSpec.TireSize)
    vehicleSpec.TireDiameter = fcn_INTERNAL_tireDiameterFromSize(vehicleSpec.TireSize);
end
vehicleSpec.TireSizeRear = vehicleSpec.TireSize;
vehicleSpec.TireDiameterRear = vehicleSpec.TireDiameter;
end % Ends fcn_INTERNAL_presetSpec

%% fcn_INTERNAL_tireDiameterFromSize
function tireDiameter = fcn_INTERNAL_tireDiameterFromSize(tireSize)
% Parses a tire size string such as '225/45R17', 'P225/45ZR17', or
% '235/60 R18' and returns the overall diameter in meters:
%   diameter = 2 * sectionWidth * aspectRatio/100 + rimDiameter
% where sectionWidth is in mm and rimDiameter is in inches.
tokens = regexp(upper(char(tireSize)), '(\d{3})\s*/\s*(\d{2,3})\s*[A-Z]*\s*R\s*(\d{2})', 'tokens', 'once');
if isempty(tokens)
    error('Unable to read tire size string: %s. Expected a form like 225/45R17.',char(tireSize));
end
sectionWidthMM = str2double(tokens{1});
aspectRatio = str2double(tokens{2});
rimDiameterInches = str2double(tokens{3});
tireDiameter = (2*sectionWidthMM*aspectRatio/100)/1000 + rimDiameterInches*0.0254;
end % Ends fcn_INTERNAL_tireDiameterFromSize

%% fcn_INTERNAL_plotSpec
function fcn_INTERNAL_plotSpec(vehicleSpec, figNum)
% Plots a simple dimensioned side view (X-Z) and top view (X-Y) of the
% specification, with the origin on the ground below the rear axle.
figure(figNum);
clf;
tiledlayout(2,1);

L  = vehicleSpec.OverallLength;
W  = vehicleSpec.OverallWidth;
H  = vehicleSpec.OverallHeight;
WB = vehicleSpec.Wheelbase;
D  = vehicleSpec.TireDiameter;
if isempty(L) || isempty(W) || isempty(H) || isempty(WB)
    warning('on','backtrace');
    warning('Plotting the specification needs OverallLength, OverallWidth, OverallHeight, and Wheelbase. Skipping plot.');
    return;
end
if isempty(D)
    D = 0.65; % Placeholder only, for plotting
end
FOH = vehicleSpec.FrontOverhang;
if isempty(FOH)
    FOH = (L-WB)/2; % Assume equal overhangs, for plotting only
end
TF = vehicleSpec.TrackFront;
TR = vehicleSpec.TrackRear;
if isempty(TF)
    TF = 0.85*W; % Placeholder only, for plotting
end
if isempty(TR)
    TR = TF;
end

xFrontBumper = WB + FOH;
xRearBumper  = xFrontBumper - L;
theta = linspace(0,2*pi,49)';

% Side view
nexttile;
hold on; axis equal; grid on;
plot([xRearBumper xFrontBumper xFrontBumper xRearBumper xRearBumper],...
    [0 0 H H 0],'k--','DisplayName','Length x height envelope');
DR = D;
if isfield(vehicleSpec,'TireDiameterRear') && ~isempty(vehicleSpec.TireDiameterRear)
    DR = vehicleSpec.TireDiameterRear;
end
plot(0 + DR/2*cos(theta), DR/2 + DR/2*sin(theta),'k-','LineWidth',1.5,'DisplayName','Rear tire');
plot(WB + D/2*cos(theta), D/2 + D/2*sin(theta),'k-','LineWidth',1.5,'DisplayName','Front tire');
plot([0 WB],[D/2 D/2],'b-o','DisplayName',sprintf('Wheelbase %.3f m',WB));
xlabel('X [m] (forward)'); ylabel('Z [m] (up)');
title(sprintf('Side view: L = %.3f m, H = %.3f m',L,H),'Interpreter','none');
legend('Location','eastoutside');

% Top view
nexttile;
hold on; axis equal; grid on;
plot([xRearBumper xFrontBumper xFrontBumper xRearBumper xRearBumper],...
    [-W/2 -W/2 W/2 W/2 -W/2],'k--','DisplayName','Length x width envelope');
plot([0 0],[-TR/2 TR/2],'r-o','DisplayName',sprintf('Rear track %.3f m',TR));
plot([WB WB],[-TF/2 TF/2],'m-o','DisplayName',sprintf('Front track %.3f m',TF));
xlabel('X [m] (forward)'); ylabel('Y [m] (left)');
title(sprintf('Top view: W = %.3f m',W),'Interpreter','none');
legend('Location','eastoutside');

sgtitle(sprintf('Vehicle specification: %s',vehicleSpec.Name),'Interpreter','none');
end % Ends fcn_INTERNAL_plotSpec
