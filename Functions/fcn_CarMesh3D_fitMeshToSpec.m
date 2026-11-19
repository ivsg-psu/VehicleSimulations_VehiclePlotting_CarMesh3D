function vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, options)
% fcn_CarMesh3D_fitMeshToSpec
% Scales and shifts a normalized mesh so that its size agrees with a
% vehicle specification (from fcn_CarMesh3D_fillVehicleSpec).
%
% Two fitting methods are available:
%
%   'box'    Scales length, width, and height separately so the mesh
%            bounding box matches OverallLength, OverallWidth, and
%            OverallHeight. Simple, and works for any mesh.
%
%   'wheels' Does the 'box' scaling for the body, then also:
%            - stretches the body along X piecewise (rear overhang,
%              wheelbase, front overhang) so the axles land exactly at
%              the specified wheelbase (and front overhang, if given);
%            - if the spec has a GroundClearance and the body faces are
%              labeled, stretches the body along Z piecewise (below and
%              above the body bottom) so both the ground clearance and the
%              overall height match;
%            - moves each wheel as a rigid object (no stretching) to its
%              axle and track position, and scales it to the specified
%              tire diameter so it touches the ground. If the spec has a
%              TireSize (such as '195/65R15'), the wheel width is also
%              scaled to the tire's section width (195 mm).
%            Needs wheel faces numbered by fcn_CarMesh3D_labelParts.
%
% The default, 'auto', uses 'wheels' when wheel faces are found and the
% spec has a Wheelbase, and 'box' otherwise.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec,...
%           (FitMethod=methodString),...
%           (Origin=originString),...
%           (WidthReference=widthString),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure in the vehicle frame
%      (from fcn_CarMesh3D_normalizeMesh), ideally labeled (from
%      fcn_CarMesh3D_labelParts).
%
%      vehicleSpec: a vehicle specification structure. OverallLength,
%      OverallWidth, and OverallHeight are required. Wheelbase,
%      FrontOverhang, TrackFront, TrackRear, and TireDiameter are used
%      when given.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FitMethod: 'auto' (default), 'wheels', or 'box'.
%
%      Origin: where to put the origin after fitting:
%           'rearAxle' (default): on the ground, below the center of the
%               rear axle (the usual vehicle dynamics convention). Needs a
%               Wheelbase in the spec.
%           'center': on the ground, at the center of the length and width.
%
%      WidthReference: what is scaled to OverallWidth:
%           'all' (default): the whole mesh.
%           'body': only the faces labeled 'body'. Use this when the
%               model's side mirrors are labeled trim and the published
%               width excludes them, as most published widths do.
%           'mirrors': the whole mesh is scaled to the spec's
%               WidthWithMirrors. Use this when the mirrors are part of
%               the body mesh and the spec gives the width with mirrors.
%      fcn_CarMesh3D_validateMesh measures the width the same way.
%
%      FigNum: a figure number to plot the fitted mesh. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with Vertices changed, and these
%      fields added or updated:
%           VehicleSpec: a copy of the spec that was used
%           AxleX: [rearAxleX frontAxleX] in the output frame (NaN if
%               unknown)
%           FitInfo: a structure with Method, Origin, BoxScale ([sx sy sz]),
%               and WheelScale (4 x 1, NaN for wheels not found)
%      Any FaceNormals field is cleared, since stretching changes normals;
%      fcn_CarMesh3D_simplifyMesh recomputes them.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_fitMeshToSpec.m for a full test
%       suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fitMeshToSpec
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fitMeshToSpec
%   % * Added piecewise Z stretch to match GroundClearance (found when
%   %   % first testing in MATLAB: box scaling changed the clearance)
%   % * Wheel width is scaled to the tire section width from TireSize
%   %   % (found with a downloaded model whose sport tires were too wide)
%   % * Added WidthReference option ('all', 'body', 'mirrors'), since
%   %   % published widths usually exclude mirrors

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fitMeshToSpec



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    vehicleSpec
    options.FitMethod = 'auto'    % 'auto', 'wheels', or 'box'
    options.Origin = 'rearAxle'   % 'rearAxle' or 'center'
    options.WidthReference = 'all' % 'all', 'body', or 'mirrors'
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
        requiredFields = {'OverallLength','OverallWidth','OverallHeight'};
        for ith_field = 1:length(requiredFields)
            if ~isfield(vehicleSpec,requiredFields{ith_field}) || isempty(vehicleSpec.(requiredFields{ith_field}))
                error('vehicleSpec must contain a value for %s',requiredFields{ith_field});
            end
        end

        % Check the FitMethod input
        if ~any(strcmpi(char(options.FitMethod),{'auto','wheels','box'}))
            error('FitMethod must be ''auto'', ''wheels'', or ''box''');
        end

        % Check the Origin input
        if ~any(strcmpi(char(options.Origin),{'rearAxle','center'}))
            error('Origin must be ''rearAxle'' or ''center''');
        end

        % Check the WidthReference input
        if ~any(strcmpi(char(options.WidthReference),{'all','body','mirrors'}))
            error('WidthReference must be ''all'', ''body'', or ''mirrors''');
        end
        if strcmpi(char(options.WidthReference),'mirrors') && ...
                (~isfield(vehicleSpec,'WidthWithMirrors') || isempty(vehicleSpec.WidthWithMirrors))
            error('WidthReference ''mirrors'' needs WidthWithMirrors in the vehicle spec');
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
L   = vehicleSpec.OverallLength;
W   = vehicleSpec.OverallWidth;
H   = vehicleSpec.OverallHeight;
WB  = fcn_INTERNAL_getField(vehicleSpec,'Wheelbase');
FOH = fcn_INTERNAL_getField(vehicleSpec,'FrontOverhang');
TF  = fcn_INTERNAL_getField(vehicleSpec,'TrackFront');
TR  = fcn_INTERNAL_getField(vehicleSpec,'TrackRear');
D   = fcn_INTERNAL_getField(vehicleSpec,'TireDiameter');
GC  = fcn_INTERNAL_getField(vehicleSpec,'GroundClearance');
tireWidth = fcn_INTERNAL_tireWidthFromSize(fcn_INTERNAL_getField(vehicleSpec,'TireSize'));
if isempty(TR)
    TR = TF;
end

originalVertices = vehicleMesh.Vertices;
Nvertices = size(originalVertices,1);

%%%%
% Step 1: bounding-box scaling of everything
minValues = min(originalVertices,[],1);
maxValues = max(originalVertices,[],1);
extents = maxValues - minValues;
centerX = (minValues(1)+maxValues(1))/2;
centerY = (minValues(2)+maxValues(2))/2;
boxScale = [L W H]./extents;

% Width from the body only (leaving out mirrors), if asked
widthReference = lower(char(options.WidthReference));
if strcmp(widthReference,'body')
    if isfield(vehicleMesh,'FacePartIndex') && any(vehicleMesh.FacePartIndex==1)
        bodyVertexIndices = unique(vehicleMesh.Faces(vehicleMesh.FacePartIndex==1,:));
        bodyMinY = min(originalVertices(bodyVertexIndices,2));
        bodyMaxY = max(originalVertices(bodyVertexIndices,2));
        centerY = (bodyMinY + bodyMaxY)/2;
        boxScale(2) = W/(bodyMaxY - bodyMinY);
    else
        warning('on','backtrace');
        warning('WidthReference ''body'' needs labeled body faces (run fcn_CarMesh3D_labelParts). Using the whole mesh.');
        widthReference = 'all';
    end
elseif strcmp(widthReference,'mirrors')
    boxScale(2) = vehicleSpec.WidthWithMirrors/extents(2);
end
fittedVertices = [...
    (originalVertices(:,1) - centerX)*boxScale(1), ...
    (originalVertices(:,2) - centerY)*boxScale(2), ...
    (originalVertices(:,3) - minValues(3))*boxScale(3)];

%%%%
% Find the wheels, if labeled
wheelVertexIndices = cell(4,1);
wheelSourceCenters = nan(4,3);
wheelSourceDiameters = nan(4,1);
wheelSourceWidths = nan(4,1);
if isfield(vehicleMesh,'FaceWheelIndex') && ~isempty(vehicleMesh.FaceWheelIndex)
    for ith_wheel = 1:4
        theseFaces = vehicleMesh.FaceWheelIndex==ith_wheel;
        if any(theseFaces)
            theseVertices = unique(vehicleMesh.Faces(theseFaces,:));
            wheelVertexIndices{ith_wheel} = theseVertices;
            wheelMin = min(originalVertices(theseVertices,:),[],1);
            wheelMax = max(originalVertices(theseVertices,:),[],1);
            wheelSourceCenters(ith_wheel,:) = (wheelMin + wheelMax)/2;
            wheelSourceDiameters(ith_wheel) = max(wheelMax(1)-wheelMin(1), wheelMax(3)-wheelMin(3));
            wheelSourceWidths(ith_wheel) = wheelMax(2)-wheelMin(2);
        end
    end
end
flagFrontFound = any(~isnan(wheelSourceDiameters(1:2)));
flagRearFound  = any(~isnan(wheelSourceDiameters(3:4)));
flagWheelsFound = flagFrontFound && flagRearFound;

% Choose the method
fitMethod = lower(char(options.FitMethod));
if strcmp(fitMethod,'auto')
    if flagWheelsFound && ~isempty(WB)
        fitMethod = 'wheels';
    else
        fitMethod = 'box';
    end
elseif strcmp(fitMethod,'wheels') && (~flagWheelsFound || isempty(WB))
    warning('on','backtrace');
    warning('FitMethod ''wheels'' needs labeled front and rear wheels and a Wheelbase in the spec. Using ''box'' instead.');
    fitMethod = 'box';
end

%%%%
% Step 2: target axle positions (in the centered, box-scaled frame)
wheelScale = nan(4,1);
xRearAxle = NaN;
xFrontAxle = NaN;
if strcmp(fitMethod,'wheels')
    % Where the box scaling put the axles
    boxWheelX = (wheelSourceCenters(:,1) - centerX)*boxScale(1);
    xFrontBox = mean(boxWheelX(1:2),'omitnan');
    xRearBox  = mean(boxWheelX(3:4),'omitnan');

    % Where the axles should go
    if ~isempty(FOH)
        xFrontAxle = L/2 - FOH;
    else
        xFrontAxle = (xFrontBox + xRearBox)/2 + WB/2; % Keep the mesh's axle midpoint
    end
    xRearAxle = xFrontAxle - WB;

    % Piecewise stretch of the body along X: rear overhang, wheelbase,
    % front overhang each scale separately
    sourceKnots = [-L/2, xRearBox, xFrontBox, L/2];
    targetKnots = [-L/2, xRearAxle, xFrontAxle, L/2];
    if all(diff(sourceKnots)>0) && all(diff(targetKnots)>0)
        fittedVertices(:,1) = interp1(sourceKnots, targetKnots, fittedVertices(:,1), 'linear', 'extrap');
    else
        warning('on','backtrace');
        warning('Axle positions are outside the vehicle length (check Wheelbase and FrontOverhang). Body was not stretched piecewise.');
    end

    % Piecewise stretch of the body along Z, so the lowest body point sits
    % at the ground clearance and the roof stays at the overall height
    if ~isempty(GC) && isfield(vehicleMesh,'FacePartIndex') && any(vehicleMesh.FacePartIndex==1)
        bodyVertices = unique(vehicleMesh.Faces(vehicleMesh.FacePartIndex==1,:));
        bodyBottomBox = min(fittedVertices(bodyVertices,3));
        if bodyBottomBox>0 && bodyBottomBox<H && GC<H
            fittedVertices(:,3) = interp1([0 bodyBottomBox H], [0 GC H], fittedVertices(:,3), 'linear', 'extrap');
        else
            warning('on','backtrace');
            warning('Could not match GroundClearance (body bottom at %.3f m after scaling). Height was scaled uniformly.', bodyBottomBox);
        end
    end

    % Move each wheel rigidly, scaled uniformly to the tire diameter
    for ith_wheel = 1:4
        theseVertices = wheelVertexIndices{ith_wheel};
        if isempty(theseVertices)
            continue;
        end
        if ~isempty(D)
            wheelScale(ith_wheel) = D/wheelSourceDiameters(ith_wheel);
        else
            wheelScale(ith_wheel) = sqrt(boxScale(1)*boxScale(3));
        end
        flagFrontWheel = ith_wheel<=2;
        flagLeftWheel = any(ith_wheel==[1 3]);
        if flagFrontWheel
            targetX = xFrontAxle;
            trackWidth = TF;
        else
            targetX = xRearAxle;
            trackWidth = TR;
        end
        if ~isempty(trackWidth)
            if flagLeftWheel
                targetY = trackWidth/2;
            else
                targetY = -trackWidth/2;
            end
        else
            targetY = (wheelSourceCenters(ith_wheel,2) - centerY)*boxScale(2);
        end
        targetZ = wheelScale(ith_wheel)*wheelSourceDiameters(ith_wheel)/2; % Touches the ground
        % Width (Y) scale: to the tire section width if known
        widthScale = wheelScale(ith_wheel);
        if ~isempty(tireWidth) && wheelSourceWidths(ith_wheel)>0
            widthScale = tireWidth/wheelSourceWidths(ith_wheel);
        end
        fittedVertices(theseVertices,:) = [targetX targetY targetZ] + ...
            (originalVertices(theseVertices,:) - wheelSourceCenters(ith_wheel,:)).*[wheelScale(ith_wheel) widthScale wheelScale(ith_wheel)];
    end
elseif ~isempty(WB)
    % Box method: axles are only estimated
    if ~isempty(FOH)
        xFrontAxle = L/2 - FOH;
    else
        xFrontAxle = WB/2; % Assumes equal front and rear overhangs
    end
    xRearAxle = xFrontAxle - WB;
end

%%%%
% Step 3: place the origin
originShiftX = 0;
originString = char(options.Origin);
if strcmpi(originString,'rearAxle')
    if isnan(xRearAxle)
        warning('on','backtrace');
        warning('Origin ''rearAxle'' needs a Wheelbase in the spec. Leaving the origin at the center.');
        originString = 'center';
    else
        originShiftX = -xRearAxle;
    end
end
fittedVertices(:,1) = fittedVertices(:,1) + originShiftX;

vehicleMesh.Vertices = fittedVertices;
if isfield(vehicleMesh,'FaceNormals')
    vehicleMesh.FaceNormals = [];
end
vehicleMesh.VehicleSpec = vehicleSpec;
vehicleMesh.AxleX = [xRearAxle xFrontAxle] + originShiftX;
vehicleMesh.FitInfo = struct(...
    'Method', fitMethod,...
    'Origin', originString,...
    'BoxScale', boxScale,...
    'WidthReference', widthReference,...
    'WheelScale', wheelScale);

if flag_do_debug
    fprintf(1,'Fit method: %s, box scale [%.4f %.4f %.4f], %d vertices\n', fitMethod, boxScale, Nvertices);
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
    tiledlayout(2,1);

    % Side view with the axle lines
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    hold on;
    view(0,0);
    for ith_axle = 1:2
        if ~isnan(vehicleMesh.AxleX(ith_axle))
            plot3(vehicleMesh.AxleX(ith_axle)*[1 1],[0 0],[0 H],'k--','LineWidth',1.5,'HandleVisibility','off');
        end
    end
    title(sprintf('Side view (method ''%s'', origin ''%s''); dashed lines are the axles',fitMethod,originString),'Interpreter','none');

    % 3D view
    nexttile;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
    title('3D view');

    sgtitle(sprintf('Fitted to spec: %s',vehicleMesh.Name),'Interpreter','none');
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

%% fcn_INTERNAL_getField
function value = fcn_INTERNAL_getField(thisStruct, fieldName)
% Returns thisStruct.(fieldName), or [] if the field does not exist
if isfield(thisStruct, fieldName)
    value = thisStruct.(fieldName);
else
    value = [];
end
end % Ends fcn_INTERNAL_getField

%% fcn_INTERNAL_tireWidthFromSize
function tireWidth = fcn_INTERNAL_tireWidthFromSize(tireSize)
% Returns the tire section width in meters from a size string such as
% '195/65R15' (195 mm), or [] if there is no readable size
tireWidth = [];
if ~isempty(tireSize)
    tokens = regexp(char(tireSize),'(\d{3})\s*/','tokens','once');
    if ~isempty(tokens)
        tireWidth = str2double(tokens{1})/1000;
    end
end
end % Ends fcn_INTERNAL_tireWidthFromSize
