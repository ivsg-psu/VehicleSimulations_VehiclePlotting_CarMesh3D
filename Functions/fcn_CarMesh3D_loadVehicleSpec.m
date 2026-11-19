function vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(specSource, options)
% fcn_CarMesh3D_loadVehicleSpec
% Loads one or many vehicle specifications, from a .mat file or from a
% structure already in the workspace, and returns CarMesh3D vehicle
% specification structures (the same structure made by
% fcn_CarMesh3D_fillVehicleSpec). Two kinds of structures are read:
%
%   1. IVSG "vehicleParameters" files, which hold a structure with fields
%      such as DistancesLength, DistancesWheelbase, DistancesFrontTrack,
%      and TireSidewallMarkings, each with matching _Units, _Text,
%      _PrintFormat, and _AllowableRange fields. Example:
%           Data\2013_Toyota_Prius_Four\vehicleParameters_2013_Toyota_Prius_Four.mat
%      Values are converted to meters using the _Units fields.
%
%   2. Files holding a CarMesh3D spec structure that was saved earlier
%      (with fields such as OverallLength). These are passed through
%      fcn_CarMesh3D_fillVehicleSpec again so they are checked.
%
% MANY VEHICLES: give an ARRAY of vehicleParameters structures (all with
% the same fields), either directly or saved in a .mat file, and an array
% of specs comes back, one per vehicle, in the same order:
%
%       allParameters = [prius, camry, f150];   % vehicleParameters structures
%       vehicleSpecs = fcn_CarMesh3D_loadVehicleSpec(allParameters);
%       vehicleSpecs(2).Wheelbase
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
%       vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(specSource,...
%           (BodyColor=[r g b]),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      specSource: the full or relative path to a .mat file, or a
%      structure (or array of structures) of either kind above.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      BodyColor: a 1 x 3 RGB paint color (values from 0 to 1) to add to
%      the spec, since vehicleParameters files do not store a color.
%      Default is [] (none).
%
%      FigNum: a figure number to plot the dimensioned specification
%      (for an array, the first vehicle's). If empty or omitted, no plot
%      is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleSpec: a CarMesh3D vehicle specification structure, with
%      Source set to the file name (or '(structure)'), or an array of
%      them (the same size as the input array). For arrays, Source also
%      gives each vehicle's position, such as 'myFleet.mat(3)'.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillVehicleSpec
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_loadVehicleSpec.m for a full
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
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadVehicleSpec
%   % * Accepts a structure, or an array of vehicleParameters structures
%   %   (many vehicles at once), as well as a .mat file
%   % * The Prius file's DistancesFrontOverhang_Text now says "from the
%   %   center of the front axle" (the old file is kept with an _OLD
%   %   suffix); removed that TO-DO item

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadVehicleSpec
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    specSource
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

        % Check the specSource input: a structure, or a .mat file
        if isstruct(specSource)
            if isempty(specSource)
                error('specSource is an empty structure array');
            end
        else
            if ~(ischar(specSource) || isstring(specSource))
                error('specSource must be a .mat file name or a structure');
            end
            if ~exist(specSource,'file')
                error('File not found: %s',char(specSource));
            end
            [~,~,tempExtension] = fileparts(char(specSource));
            if ~strcmpi(tempExtension,'.mat')
                error('specSource must be a .mat file. Found: %s',tempExtension);
            end
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
if isstruct(specSource)
    loadedStruct = specSource;
    sourceName = '(structure)';
else
    sourceName = char(specSource);
    loadedData = load(sourceName);

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
        error('No structure variable was found in file: %s',sourceName);
    end
end

% Convert each vehicle (one, or every element of an array)
Nvehicles = numel(loadedStruct);
specList = cell(Nvehicles,1);
for ith_vehicle = 1:Nvehicles
    if Nvehicles==1
        thisSource = sourceName;
        thisFigNum = figNum;
    else
        thisSource = sprintf('%s(%d)', sourceName, ith_vehicle);
        thisFigNum = -1;
        if ith_vehicle==1
            thisFigNum = figNum;
        end
    end
    specList{ith_vehicle} = fcn_INTERNAL_convertOne(loadedStruct(ith_vehicle), thisSource, options.BodyColor, thisFigNum, flag_max_speed);
end
vehicleSpec = reshape([specList{:}], size(loadedStruct));

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

%% fcn_INTERNAL_convertOne
function vehicleSpec = fcn_INTERNAL_convertOne(loadedStruct, sourceName, bodyColor, figNum, flag_max_speed)
% Converts one vehicleParameters structure (or saved CarMesh3D spec) into
% a CarMesh3D spec, checked by fcn_CarMesh3D_fillVehicleSpec
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
        parameterName = fieldMap{ith_field,1};
        if isfield(loadedStruct,parameterName) && ~isempty(loadedStruct.(parameterName))
            value = double(loadedStruct.(parameterName));
            unitsName = [parameterName '_Units'];
            if isfield(loadedStruct,unitsName)
                value = value*fcn_INTERNAL_metersPerUnit(loadedStruct.(unitsName), parameterName);
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
        error('The structure in %s is neither a vehicleParameters structure nor a CarMesh3D spec',sourceName);
    end
end

if ~isempty(bodyColor)
    specArguments = [specArguments, {'BodyColor', bodyColor}];
end
specArguments = [specArguments, {'Source', sourceName, 'FigNum', figNum}];

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
end % Ends fcn_INTERNAL_convertOne
