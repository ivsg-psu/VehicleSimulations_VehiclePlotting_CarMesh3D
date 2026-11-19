function vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fileName, options)
% fcn_CarMesh3D_loadVehicleSpec
% Loads a vehicle specification from a .mat file and returns a CarMesh3D
% vehicle specification structure (the same structure made by
% fcn_CarMesh3D_fillVehicleSpec). Two kinds of .mat files are read:
%
%   1. IVSG "vehicleParameters" files, which hold a structure with fields
%      such as DistancesLength, DistancesWheelbase, DistancesFrontTrack,
%      and TireSidewallMarkings, each with matching _Units, _Text,
%      _PrintFormat, and _AllowableRange fields. Example:
%           vehicleParameters_2013ToyotaPriusFour.mat
%      Values are converted to meters using the _Units fields.
%
%   2. Files holding a CarMesh3D spec structure that was saved earlier
%      (with fields such as OverallLength). These are passed through
%      fcn_CarMesh3D_fillVehicleSpec again so they are checked.
%
% The mapping from vehicleParameters fields to CarMesh3D spec fields is:
%
%       DistancesLength            -> OverallLength
%       DistancesWidth             -> OverallWidth
%       DistancesWidthWithMirrors  -> WidthWithMirrors
%       DistancesHeight            -> OverallHeight
%       DistancesWheelbase         -> Wheelbase
%       DistancesFrontTrack        -> TrackFront
%       DistancesRearTrack         -> TrackRear
%       DistancesFrontOverhang     -> FrontOverhang
%       DistancesGroundClearance   -> GroundClearance
%       TireSidewallMarkings       -> TireSize (and so TireDiameter)
%       Year, Make, Model, Trim    -> Name
%
% FORMAT:
%
%       vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(fileName,...
%           (BodyColor=[r g b]),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      fileName: the full or relative path to a .mat file.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      BodyColor: a 1 x 3 RGB paint color (values from 0 to 1) to add to
%      the spec, since vehicleParameters files do not store a color.
%      Default is [] (none).
%
%      FigNum: a figure number to plot the dimensioned specification. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleSpec: a CarMesh3D vehicle specification structure, with
%      Source set to the file name.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillVehicleSpec
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_loadVehicleSpec.m for a full
%       test suite.
%
% This function was written on 2026_11_18 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadVehicleSpec
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadVehicleSpec
%   % * Add CSV input (one row per vehicle) for class-wide data sets
%   % * The _Text descriptions of DistancesFrontOverhang and
%   %   % DistancesRearOverhang in the Prius file say "from the center of
%   %   % the rear axle", but the values (0.924 + 2.700 + 0.856 = 4.480)
%   %   % follow the usual definition: front axle to front bumper, and
%   %   % rear axle to rear bumper. The source files should be corrected.



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    fileName
    options.BodyColor = []   % 1 x 3 RGB paint color to add
    options.FigNum = []      % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the fileName input
        if ~(ischar(fileName) || isstring(fileName))
            error('fileName must be a character string');
        end
        if ~exist(fileName,'file')
            error('File not found: %s',char(fileName));
        end
        [~,~,tempExtension] = fileparts(char(fileName));
        if ~strcmpi(tempExtension,'.mat')
            error('fileName must be a .mat file. Found: %s',tempExtension);
        end
    end
end

% Does user want to show the plots?
if (0==flag_max_speed)
    figNum = options.FigNum;
else
    figNum = -1;
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
fileName = char(fileName);
loadedData = load(fileName);

% Find the first structure in the file
variableNames = fieldnames(loadedData);
loadedStruct = [];
for ith_variable = 1:length(variableNames)
    if isstruct(loadedData.(variableNames{ith_variable}))
        loadedStruct = loadedData.(variableNames{ith_variable});
        break;
    end
end
if isempty(loadedStruct)
    error('No structure variable was found in file: %s',fileName);
end

if isfield(loadedStruct,'DistancesLength')
    % IVSG vehicleParameters format
    fieldMap = {...
        'DistancesLength',           'OverallLength';
        'DistancesWidth',            'OverallWidth';
        'DistancesWidthWithMirrors', 'WidthWithMirrors';
        'DistancesHeight',           'OverallHeight';
        'DistancesWheelbase',        'Wheelbase';
        'DistancesFrontTrack',       'TrackFront';
        'DistancesRearTrack',        'TrackRear';
        'DistancesFrontOverhang',    'FrontOverhang';
        'DistancesGroundClearance',  'GroundClearance'};
    specArguments = {};
    for ith_field = 1:size(fieldMap,1)
        sourceName = fieldMap{ith_field,1};
        if isfield(loadedStruct,sourceName) && ~isempty(loadedStruct.(sourceName))
            value = double(loadedStruct.(sourceName));
            unitsName = [sourceName '_Units'];
            if isfield(loadedStruct,unitsName)
                value = value*fcn_INTERNAL_metersPerUnit(loadedStruct.(unitsName), sourceName);
            end
            specArguments = [specArguments, {fieldMap{ith_field,2}, value}]; %#ok<AGROW>
        end
    end
    if isfield(loadedStruct,'TireSidewallMarkings') && ~isempty(loadedStruct.TireSidewallMarkings)
        specArguments = [specArguments, {'TireSize', char(loadedStruct.TireSidewallMarkings)}];
    end

    % Name from year, make, model, and trim
    nameParts = {};
    nameFields = {'Year','Make','Model','Trim'};
    for ith_field = 1:length(nameFields)
        if isfield(loadedStruct,nameFields{ith_field}) && ~isempty(loadedStruct.(nameFields{ith_field}))
            thisValue = loadedStruct.(nameFields{ith_field});
            if isnumeric(thisValue)
                thisValue = sprintf('%d',thisValue);
            end
            nameParts{end+1} = char(thisValue); %#ok<AGROW>
        end
    end
    if ~isempty(nameParts)
        specArguments = [specArguments, {'Name', strjoin(nameParts,' ')}];
    end
else
    % A saved CarMesh3D spec: copy the fields fillVehicleSpec knows
    knownFields = {'Name','OverallLength','OverallWidth','WidthWithMirrors','OverallHeight',...
        'Wheelbase','TrackFront','TrackRear','TireSize','TireDiameter',...
        'FrontOverhang','GroundClearance','BodyColor'};
    specArguments = {};
    for ith_field = 1:length(knownFields)
        if isfield(loadedStruct,knownFields{ith_field}) && ~isempty(loadedStruct.(knownFields{ith_field}))
            specArguments = [specArguments, {knownFields{ith_field}, loadedStruct.(knownFields{ith_field})}]; %#ok<AGROW>
        end
    end
    if isempty(specArguments)
        error('The structure in %s is neither a vehicleParameters structure nor a CarMesh3D spec',fileName);
    end
end

if ~isempty(options.BodyColor)
    specArguments = [specArguments, {'BodyColor', options.BodyColor}];
end
specArguments = [specArguments, {'Source', fileName, 'FigNum', figNum}];

% Build (and check) the spec
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(specArguments{:});

% Cross-check the rear overhang, if the file gives it
if isfield(loadedStruct,'DistancesRearOverhang') && ~isempty(vehicleSpec.RearOverhang) && 0==flag_max_speed
    fileRearOverhang = double(loadedStruct.DistancesRearOverhang);
    if isfield(loadedStruct,'DistancesRearOverhang_Units')
        fileRearOverhang = fileRearOverhang*fcn_INTERNAL_metersPerUnit(loadedStruct.DistancesRearOverhang_Units,'DistancesRearOverhang');
    end
    if abs(fileRearOverhang - vehicleSpec.RearOverhang) > 0.01
        warning('on','backtrace');
        warning('Rear overhang in the file (%.3f m) does not match Length - Wheelbase - FrontOverhang (%.3f m). Check the file values.',...
            fileRearOverhang, vehicleSpec.RearOverhang);
    end
end

if flag_do_debug
    disp(vehicleSpec);
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
% (Plotting, if requested, is done by fcn_CarMesh3D_fillVehicleSpec)

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

%% fcn_INTERNAL_metersPerUnit
function scaleFactor = fcn_INTERNAL_metersPerUnit(unitsValue, fieldName)
% Converts a units label into meters per unit. An empty label is taken
% as meters.
if isempty(unitsValue)
    scaleFactor = 1;
    return;
end
switch lower(strtrim(char(unitsValue)))
    case {'m','meter','meters'}
        scaleFactor = 1;
    case {'cm'}
        scaleFactor = 0.01;
    case {'mm'}
        scaleFactor = 0.001;
    case {'in','inch','inches'}
        scaleFactor = 0.0254;
    case {'ft','feet','foot'}
        scaleFactor = 0.3048;
    otherwise
        error('Unknown units ''%s'' for field %s',char(unitsValue),fieldName);
end
end % Ends fcn_INTERNAL_metersPerUnit
