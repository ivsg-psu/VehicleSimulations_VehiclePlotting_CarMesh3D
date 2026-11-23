function validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, options)
% fcn_CarMesh3D_validateMesh
% Measures a fitted mesh and compares it, value by value, against a
% vehicle specification. This is the "did it work?" check at the end of
% the CarMesh3D workflow, and the table it returns is a good thing for
% students to include in a report.
%
% Measured values:
%       OverallLength, OverallWidth, OverallHeight  (bounding box, the height
%       to the roof without an antenna; the
%                        width uses only the body faces if the mesh was
%                        fitted with WidthReference='body')
%       WidthWithMirrors (bounding box width, measured only if the mesh
%                        was fitted with WidthReference='mirrors'; then
%                        OverallWidth is not measured)
%       Wheelbase        (front wheel centers minus rear wheel centers)
%       TrackFront, TrackRear (left minus right wheel centers)
%       TireDiameter     (mean height of the four wheels; for different
%                        front and rear tires (a spec with its own
%                        TireDiameterRear), the front wheels' only, and
%                        a TireDiameterRear row for the rear wheels)
%       TireRoundMin, TireRoundMax (the smallest and largest outer
%                        diameter of the tires seen from the side: twice
%                        the outer radius from each wheel's center, in 36
%                        directions 10 degrees apart, over all four
%                        wheels. Both are compared with the tire diameter,
%                        so a tire reduced to a polygon, or squashed,
%                        fails. For different front and rear tires, the
%                        front wheels' only)
%       FrontOverhang    (front of mesh minus front wheel centers)
%       GroundClearance  (lowest point of the body faces)
% Wheel measurements need wheel faces numbered by fcn_CarMesh3D_labelParts.
%
% FORMAT:
%
%       validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec,...
%           (Tolerance=percentTolerance),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure in the vehicle frame,
%      usually after fcn_CarMesh3D_fitMeshToSpec.
%
%      vehicleSpec: a vehicle specification structure from
%      fcn_CarMesh3D_fillVehicleSpec.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tolerance: the percent error at or below which a value is marked
%      as passing. Default is 2 (percent).
%
%      FigNum: a figure number to plot side, top, and front views of the
%      mesh with the target dimensions drawn as dashed lines. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      validationTable: a MATLAB table with one row per quantity and the
%      columns
%           Quantity (string), Target_m, Measured_m, Error_m,
%           PercentError, Pass (true, false, or missing)
%      Target_m is NaN when the spec has no value, and Measured_m is NaN
%      when the mesh cannot be measured for that quantity. Pass is false
%      only when both are known and the error is above Tolerance.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_validateMesh.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * Width follows the fit's WidthReference ('body' leaves out mirrors,
%   %   % 'mirrors' compares the full width to WidthWithMirrors)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * Different front and rear tires: TireDiameter is the front wheels'
%   %   % and a TireDiameterRear row is added for the rear wheels
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * TireRoundMin and TireRoundMax rows: the smallest and largest outer
%   %   % tire diameter seen from the side, compared with the tire size,
%   %   % so a tire reduced to a polygon fails
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * OverallHeight is measured to the roof, leaving out an antenna or
%   %   % other thin part sticking up (as fcn_CarMesh3D_fitMeshToSpec now
%   %   % fits it): published heights exclude antennas

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_validateMesh
%   % * Add an option to overlay a side-view photo (scaled by the
%   %   % wheelbase) behind the side view, for a visual shape check



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    vehicleSpec
    options.Tolerance = 2   % Percent error that still passes
    options.FigNum = []     % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isfield(vehicleMesh,'Frame') || ~strcmp(vehicleMesh.Frame,'ISO8855')
            error('vehicleMesh must be in the CarMesh3D vehicle frame. Run fcn_CarMesh3D_normalizeMesh first.');
        end

        % Check the vehicleSpec input
        if ~isstruct(vehicleSpec)
            error('vehicleSpec must be a structure from fcn_CarMesh3D_fillVehicleSpec');
        end

        % Check the Tolerance input
        if ~isnumeric(options.Tolerance) || ~isscalar(options.Tolerance) || options.Tolerance<0
            error('Tolerance must be a non-negative number (percent)');
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
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;

% Only measure vertices that are used by faces
usedVertices = vertices(unique(faces(:)),:);
minValues = min(usedVertices,[],1);
maxValues = max(usedVertices,[],1);

% Wheel centers and diameters
wheelCenters = nan(4,3);
wheelDiameters = nan(4,1);
wheelRoundMin = nan(4,1);
wheelRoundMax = nan(4,1);
if isfield(vehicleMesh,'FaceWheelIndex') && ~isempty(vehicleMesh.FaceWheelIndex)
    for ith_wheel = 1:4
        theseFaces = vehicleMesh.FaceWheelIndex==ith_wheel;
        if any(theseFaces)
            wheelVertices = vertices(unique(faces(theseFaces,:)),:);
            wheelMin = min(wheelVertices,[],1);
            wheelMax = max(wheelVertices,[],1);
            wheelCenters(ith_wheel,:) = (wheelMin + wheelMax)/2;
            wheelDiameters(ith_wheel) = wheelMax(3) - wheelMin(3);
            [wheelRoundMin(ith_wheel), wheelRoundMax(ith_wheel)] = ...
                fcn_INTERNAL_roundness(vertices, faces(theseFaces,:), wheelCenters(ith_wheel,:));
        end
    end
end
xFrontAxle = mean(wheelCenters(1:2,1),'omitnan');
xRearAxle  = mean(wheelCenters(3:4,1),'omitnan');

% Body ground clearance
groundClearance = NaN;
if isfield(vehicleMesh,'FacePartIndex') && ~isempty(vehicleMesh.FacePartIndex)
    bodyFaces = vehicleMesh.FacePartIndex==1;
    if any(bodyFaces)
        groundClearance = min(vertices(unique(faces(bodyFaces,:)),3));
    end
end

% Width: the whole mesh, only the body, or (with mirrors) not measured
widthReference = 'all';
if isfield(vehicleMesh,'FitInfo') && isfield(vehicleMesh.FitInfo,'WidthReference')
    widthReference = vehicleMesh.FitInfo.WidthReference;
end
measuredWidth = maxValues(2) - minValues(2);
measuredWidthWithMirrors = NaN;
switch widthReference
    case 'body'
        if isfield(vehicleMesh,'FacePartIndex') && any(vehicleMesh.FacePartIndex==1)
            bodyY = vertices(unique(faces(vehicleMesh.FacePartIndex==1,:)),2);
            measuredWidth = max(bodyY) - min(bodyY);
        end
    case 'mirrors'
        measuredWidthWithMirrors = measuredWidth;
        measuredWidth = NaN; % The body width without mirrors is not known
end

% Different front and rear tires?
flagStaggered = isfield(vehicleSpec,'TireDiameterRear') && ~isempty(vehicleSpec.TireDiameterRear) && ...
    isfield(vehicleSpec,'TireDiameter') && ~isempty(vehicleSpec.TireDiameter) && ...
    abs(vehicleSpec.TireDiameterRear - vehicleSpec.TireDiameter) > 1e-9;

% Measurements, in the same order as the quantity names
quantityNames = {'OverallLength';'OverallWidth';'WidthWithMirrors';'OverallHeight';'Wheelbase';...
    'TrackFront';'TrackRear';'TireDiameter';'TireRoundMin';'TireRoundMax';'FrontOverhang';'GroundClearance'};
roundWheels = 1:4;
if flagStaggered
    roundWheels = 1:2;                                                    % (the front wheels)
end
measuredTireDiameter = mean(wheelDiameters,'omitnan');
if flagStaggered
    measuredTireDiameter = mean(wheelDiameters(1:2),'omitnan');          % (the front wheels)
end
measuredValues = [...
    maxValues(1) - minValues(1);
    measuredWidth;
    measuredWidthWithMirrors;
    fcn_INTERNAL_roofTop(vertices) - minValues(3);           % (to the roof: an antenna is left out)
    xFrontAxle - xRearAxle;
    wheelCenters(1,2) - wheelCenters(2,2);
    wheelCenters(3,2) - wheelCenters(4,2);
    measuredTireDiameter;
    min(wheelRoundMin(roundWheels));
    max(wheelRoundMax(roundWheels));
    maxValues(1) - xFrontAxle;
    groundClearance];
if flagStaggered
    % (a row for the rear wheels, after the front's)
    quantityNames = [quantityNames(1:8); {'TireDiameterRear'}; quantityNames(9:end)];
    measuredValues = [measuredValues(1:8); mean(wheelDiameters(3:4),'omitnan'); measuredValues(9:end)];
end

% Targets from the spec (NaN where not given); the roundness rows are
% compared with the tire diameter
targetValues = nan(length(quantityNames),1);
for ith_quantity = 1:length(quantityNames)
    specName = quantityNames{ith_quantity};
    if any(strcmp(specName, {'TireRoundMin','TireRoundMax'}))
        specName = 'TireDiameter';
    end
    if isfield(vehicleSpec, specName) && ~isempty(vehicleSpec.(specName))
        targetValues(ith_quantity) = vehicleSpec.(specName);
    end
end

errorValues = measuredValues - targetValues;
percentErrors = 100*errorValues./targetValues;
passValues = abs(percentErrors) <= options.Tolerance;
passValues(isnan(percentErrors)) = true; % Nothing to compare: not a failure

validationTable = table(string(quantityNames), targetValues, measuredValues, errorValues, percentErrors, passValues,...
    'VariableNames', {'Quantity','Target_m','Measured_m','Error_m','PercentError','Pass'});

if flag_do_debug
    disp(validationTable);
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
    tiledlayout(2,2);

    % Target envelope: centered on the mesh in X and Y, from the ground up
    centerX = (minValues(1) + maxValues(1))/2;
    targetL = fcn_INTERNAL_targetOrMeasured(targetValues(1), measuredValues(1));
    if strcmp(widthReference,'mirrors')
        targetW = fcn_INTERNAL_targetOrMeasured(targetValues(3), measuredValues(3));
    else
        targetW = fcn_INTERNAL_targetOrMeasured(targetValues(2), measuredValues(2));
    end
    targetH = fcn_INTERNAL_targetOrMeasured(targetValues(4), measuredValues(4));
    envelopeX = centerX + targetL/2*[-1 1 1 -1 -1];

    % Side view (X-Z)
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    hold on;
    view(0,0);
    plot3(envelopeX, zeros(1,5), targetH*[0 0 1 1 0], 'k--', 'LineWidth',1.5, 'DisplayName','Target length x height');
    if ~isnan(xRearAxle) && ~isnan(targetValues(5))
        plot3((xRearAxle + targetValues(5))*[1 1], [0 0], [0 targetH], 'r--', 'LineWidth',1.5, 'DisplayName','Target front axle');
        plot3(xRearAxle*[1 1], [0 0], [0 targetH], 'r:', 'LineWidth',1.5, 'DisplayName','Measured rear axle');
    end
    title('Side view');

    % Top view (X-Y)
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    hold on;
    view(0,90);
    plot3(envelopeX, targetW/2*[-1 -1 1 1 -1], targetH*ones(1,5), 'k--', 'LineWidth',1.5, 'DisplayName','Target length x width');
    title('Top view');

    % Front view (Y-Z)
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    hold on;
    view(90,0);
    plot3(maxValues(1)*ones(1,5), targetW/2*[-1 1 1 -1 -1], targetH*[0 0 1 1 0], 'k--', 'LineWidth',1.5, 'DisplayName','Target width x height');
    title('Front view');

    % Table of results as text
    nexttile;
    axis off;
    tableLines = cell(length(quantityNames)+1,1);
    tableLines{1} = sprintf('%-16s %8s %9s %8s', 'Quantity', 'Target', 'Measured', 'Error%');
    for ith_quantity = 1:length(quantityNames)
        tableLines{ith_quantity+1} = sprintf('%-16s %8.3f %9.3f %8.2f', quantityNames{ith_quantity}, ...
            targetValues(ith_quantity), measuredValues(ith_quantity), percentErrors(ith_quantity));
    end
    text(0, 1, tableLines, 'FontName','FixedWidth', 'VerticalAlignment','top', 'Interpreter','none');
    title(sprintf('All within %.1f%%: %s', options.Tolerance, string(all(passValues))));

    sgtitle(sprintf('Validation: %s',vehicleMesh.Name),'Interpreter','none');
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

%% fcn_INTERNAL_targetOrMeasured
function value = fcn_INTERNAL_targetOrMeasured(targetValue, measuredValue)
% Uses the target if known, otherwise the measured value (for plotting)
if isnan(targetValue)
    value = measuredValue;
else
    value = targetValue;
end
end % Ends fcn_INTERNAL_targetOrMeasured

%% fcn_INTERNAL_roundness
function [roundMin, roundMax] = fcn_INTERNAL_roundness(vertices, wheelFaces, wheelCenter)
% The smallest and largest outer diameter of a wheel seen from the side
% (the X-Z plane): twice the largest distance from the center, in each of
% 36 directions 10 degrees apart. The faces' edges are sampled (5 points
% per edge), so a long flat face between two far-apart corners shows up
% as a dip in the radius.
edgeStarts = vertices(wheelFaces(:),[1 3]);
edgeEnds = vertices(wheelFaces(:,[2 3 1]),[1 3]);
samples = [];
for fraction = 0:0.2:0.8
    samples = [samples; edgeStarts + fraction*(edgeEnds - edgeStarts)]; %#ok<AGROW>
end
relative = samples - wheelCenter([1 3]);
radius = sqrt(sum(relative.^2, 2));
angleBin = floor(mod(atan2(relative(:,2), relative(:,1)), 2*pi)/(pi/18)) + 1;
binRadius = accumarray(min(angleBin,36), radius, [36 1], @max, NaN);
roundMin = 2*min(binRadius);
roundMax = 2*max(binRadius);
end % Ends fcn_INTERNAL_roundness

%% fcn_INTERNAL_roofTop
function roofTop = fcn_INTERNAL_roofTop(vertices)
% The top of the roof, leaving out thin parts that stick up above it (a
% mast or whip antenna, a single stray point). Scanning down from the
% highest point in steps of 0.5% of the height, the roof is the first
% height whose band (the 2% of the height below it) is at least 15% of
% the vehicle's length and width across. Published heights exclude
% antennas; the 2011 Fusion's antenna made its body 12% too short.
zValues = vertices(:,3);
zMin = min(zValues);
zMax = max(zValues);
heightRange = zMax - zMin;
roofTop = zMax;
if heightRange <= 0
    return;
end
minimumSpan = 0.15*(max(vertices(:,1:2),[],1) - min(vertices(:,1:2),[],1));
for zTop = zMax:-0.005*heightRange:zMin + 0.5*heightRange
    inBand = zValues <= zTop & zValues >= zTop - 0.02*heightRange;
    if any(inBand)
        bandSpan = max(vertices(inBand,1:2),[],1) - min(vertices(inBand,1:2),[],1);
        if all(bandSpan >= minimumSpan)
            roofTop = max(zValues(inBand));
            return;
        end
    end
end
end % Ends fcn_INTERNAL_roofTop
