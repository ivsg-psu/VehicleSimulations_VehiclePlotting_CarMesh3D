function [lampFunctions, units, info] = fcn_CarMesh3D_lampFunctions(vehicleInput, options)
% fcn_CarMesh3D_lampFunctions

% A vehicle's lamp-to-function (L2F) matrix: for each lamp unit (layer 2,
% fcn_CarMesh3D_lampUnits), how brightly each signal (layer 3,
% fcn_CarMesh3D_lampSignals) lights it, from 0 (off) to 1 (full)
% (Documentation_CarMesh3D_GUIdesign_lampFunctions.md, sections 4 and 5).
%
% Where the numbers come from:
%   - The vehicle's file, lampFunctions_<ID>.csv in its folder (rule G40:
%     data about a vehicle lives with the vehicle): every unit and every
%     cell, with a Default column ('yes', or 'edited') and a Source column
%     (Q79 (A)). Rows marked 'edited' are kept as they are; rows marked
%     'yes' are made again from the defaults, so a change to the defaults
%     reaches every vehicle that has not changed that lamp.
%   - The defaults, from each unit's kind and side (section 4): a headlamp
%     is lit by the low and high beams (the low beams only, when the
%     vehicle has high-beam lamps of its own on that side); a left turn-signal lamp by the left
%     turn; a tail/brake lamp by the tail and parking lights (0.4) and the
%     brake (1), and by the turn signal on its side when the vehicle has no
%     rear turn-signal lamp of its own (US red rear turns); and so on.
%   - With no file yet, a one-time migration from what the mesh held
%     before the matrix: the per-face functions (LabelFaceAlsoLamps: the
%     2009 Fit's headlamps are also its high beams) and the vehicle's own
%     SignalLampSwitching (which signals light its fog, reflector, license-plate,
%     marker and warning lamps). A migrated row that differs from the
%     default is marked 'edited', with its source, so it is kept.
%
% A unit named in the file that the mesh no longer has is left out, and
% said so (rule G40, part 3); a unit the file does not name gets its
% default row.
%
% FORMAT:
%
%       [lampFunctions, units, info] = fcn_CarMesh3D_lampFunctions(vehicleInput,...
%           (Mesh=vehicleMesh), (Table=lampFunctions), (FlagSave=flagSave),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or its folder;
%      or a labeled mesh (no file is read or written then: the defaults,
%      and the migration from the mesh).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mesh: the vehicle's mesh, when already loaded (else it is loaded
%      with fcn_CarMesh3D_meshWithLabelEdits). Default [].
%
%      Table: a matrix as this function returns it, with rows changed
%      (such as by the lamp-functions window): its rows marked 'edited'
%      are taken, as a file's are, over the file's and the defaults.
%      Default [] (none).
%
%      FlagSave: true to write the matrix to the vehicle's file (made if
%      missing). Default false.
%
%      FigNum: a figure to show the matrix in (a shaded grid of units by
%      signals). If empty or omitted, no plot is made. If set to -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      lampFunctions: a table, one row per unit (in fcn_CarMesh3D_lampUnits'
%      order), with columns Unit, Kind, Position, one column per signal
%      (0 to 1), Default ('yes' or 'edited') and Source.
%
%      units: the units (fcn_CarMesh3D_lampUnits), in the table's order.
%
%      info: a structure with Sources (the sourced cells, from
%      fcn_CarMesh3D_lampSources, with a column Applied: whether the value
%      went into the matrix; [] for a mesh given as a variable),
%      SourcesFile, File (the vehicle's file, or ''), FromFile
%      (true when the file was read), NumEdited, Dropped (names in the file
%      no longer among the units), Added (units the file did not name).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_lampUnits, fcn_CarMesh3D_lampSignals,
%      fcn_CarMesh3D_lampTypes, fcn_CarMesh3D_findVehicleFiles,
%      fcn_CarMesh3D_meshWithLabelEdits, fcn_CarMesh3D_lampSources
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampFunctions.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampFunctions
%   % * First write (the lamp-functions plan, item 3; Q76 (A), Q79 (A),
%   %   % Q80 (A))
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (later; drafted with Claude)
% - In fcn_CarMesh3D_lampFunctions
%   % * Table=: a matrix with edited rows (the lamp-functions window's),
%   %   % taken over the file's; a headlamp's default leaves out the high
%   %   % beam when the vehicle has high-beam lamps of its own on that side
%   % * Sourced cells (fcn_CarMesh3D_lampSources: the maker's information,
%   %   % Q98 (A)) go into the rows not edited by hand; info.Sources

% TO-DO:
%
% (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Mesh = []           % The vehicle's mesh, if already loaded
    options.Table = []          % A matrix with edited rows, taken over the file's
    options.FlagSave = false        % Write the matrix to the vehicle's file
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
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
        % Check the vehicleInput input
        if ~(ischar(vehicleInput) || (isstring(vehicleInput) && isscalar(vehicleInput)) || isstruct(vehicleInput))
            error('vehicleInput must be a vehicle ID or folder (text), or a labeled mesh');
        end
        if isstruct(vehicleInput) && options.FlagSave
            error('Save needs a vehicle ID or folder (a mesh alone has no file to save to)');
        end
        if ~isempty(options.Mesh) && ~isstruct(options.Mesh)
            error('Mesh must be a labeled CarMesh3D mesh, or empty');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed) && ~isempty(options.FigNum)
    figNum = options.FigNum;
    flag_do_plots = 1;
end

%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The mesh, and the vehicle's file
functionsFile = '';
if isstruct(vehicleInput)
    vehicleMesh = vehicleInput;
else
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    functionsFile = fullfile(vehicleFiles.Folder, sprintf('lampFunctions_%s.csv', vehicleFiles.ID));
    if isempty(options.Mesh)
        vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleFiles.Folder, FigNum=-1);
    else
        vehicleMesh = options.Mesh;
    end
end

units = fcn_CarMesh3D_lampUnits(vehicleMesh, FigNum=-1);
signalKinds = fcn_CarMesh3D_lampSignals();
signalNames = {signalKinds.Name};
numUnits = numel(units);
numSignals = numel(signalNames);

% The defaults, and the migration from what the mesh held before
[defaultValues, defaultSources] = fcn_INTERNAL_defaults(units, signalNames);
[migratedValues, migratedSources] = fcn_INTERNAL_migrate(vehicleMesh, units, signalNames, defaultValues);

values = defaultValues;
flagEdited = false(numUnits,1);
sources = defaultSources;
info = struct('File', functionsFile, 'FromFile', false, 'NumEdited', 0, 'Dropped', {{}}, 'Added', {{}}, ...
    'Sources', [], 'SourcesFile', '');

if ~isempty(functionsFile) && isfile(functionsFile)
    % The file: rows marked 'edited' are kept; the rest are the defaults
    saved = readtable(functionsFile, 'TextType', 'char', 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    info.FromFile = true;
    savedNames = fcn_INTERNAL_texts(saved.Unit);
    savedDefault = fcn_INTERNAL_texts(saved.Default);
    savedSource = fcn_INTERNAL_texts(saved.Source);
    unitNames = {units.Name};
    info.Dropped = setdiff(savedNames, unitNames, 'stable');
    info.Added = setdiff(unitNames, savedNames, 'stable');
    if ~isempty(info.Dropped)
        warning('CarMesh3D:lampFunctionsDropped', ['%s names lamp unit(s) the mesh no longer has, left out: %s. ' ...
            '(Units are found from the lamp labels; repainting a lamp can rename or remove one.)'], ...
            functionsFile, strjoin(info.Dropped, ', '));
    end
    for ith_row = 1:height(saved)
        unitIndex = find(strcmp(unitNames, savedNames{ith_row}), 1);
        if isempty(unitIndex) || ~strcmpi(strtrim(savedDefault{ith_row}), 'edited')
            continue;
        end
        for ith_signal = 1:numSignals
            if ismember(signalNames{ith_signal}, saved.Properties.VariableNames)
                cellValue = saved.(signalNames{ith_signal})(ith_row);
                if isnumeric(cellValue) && isfinite(cellValue)
                    values(unitIndex, ith_signal) = min(1, max(0, cellValue));
                else
                    values(unitIndex, ith_signal) = 0;
                end
            else
                values(unitIndex, ith_signal) = 0;   % (a signal added since the file was saved: off)
            end
        end
        flagEdited(unitIndex) = true;
        sources{unitIndex} = savedSource{ith_row};
    end
else
    % No file yet: the migration's rows that differ from the default
    flagMigrated = any(abs(migratedValues - defaultValues) > 1e-9, 2);
    values(flagMigrated,:) = migratedValues(flagMigrated,:);
    flagEdited = flagMigrated;
    sources(flagMigrated) = migratedSources(flagMigrated);
end
if istable(options.Table) && height(options.Table) > 0
    % (a matrix given, such as the window's: its edited rows win)
    unitNames = {units.Name};
    givenNames = fcn_INTERNAL_texts(options.Table.Unit);
    givenDefault = fcn_INTERNAL_texts(options.Table.Default);
    givenSource = fcn_INTERNAL_texts(options.Table.Source);
    for ith_row = 1:height(options.Table)
        unitIndex = find(strcmp(unitNames, givenNames{ith_row}), 1);
        if isempty(unitIndex) || ~strcmpi(strtrim(givenDefault{ith_row}), 'edited')
            continue;
        end
        for ith_signal = 1:numSignals
            if ismember(signalNames{ith_signal}, options.Table.Properties.VariableNames)
                values(unitIndex, ith_signal) = min(1, max(0, options.Table.(signalNames{ith_signal})(ith_row)));
            end
        end
        flagEdited(unitIndex) = true;
        sources{unitIndex} = givenSource{ith_row};
    end
end
info.NumEdited = nnz(flagEdited);

% The sourced cells (lampFunctionsSources_<ID>.csv: the maker's own
% information, found online; Sean, 2026-11-26 19:45, Q98 (A)): their values
% go into the rows a person has not edited by hand (a person's edit wins);
% Applied says which went in
if ~isempty(functionsFile)
    [lampSources, info.SourcesFile] = fcn_CarMesh3D_lampSources(vehicleFiles.Folder, FigNum=-1);
    lampSources.Applied = false(height(lampSources), 1);
    unitNames = {units.Name};
    for ith_source = 1:height(lampSources)
        unitIndex = find(strcmp(unitNames, lampSources.Unit{ith_source}), 1);
        signalIndex = find(strcmp(signalNames, lampSources.Signal{ith_source}), 1);
        if isempty(unitIndex) || isempty(signalIndex) || ~ismember(lampSources.Status{ith_source}, {'auto', 'verified'}) ...
                || flagEdited(unitIndex)
            continue;
        end
        values(unitIndex, signalIndex) = lampSources.Value(ith_source);
        lampSources.Applied(ith_source) = true;
    end
    info.Sources = lampSources;
end

% The table
defaultWord = repmat({'yes'}, numUnits, 1);
defaultWord(flagEdited) = {'edited'};
lampFunctions = table({units.Name}', {units.Kind}', {units.Position}', 'VariableNames', {'Unit', 'Kind', 'Position'});
for ith_signal = 1:numSignals
    lampFunctions.(signalNames{ith_signal}) = values(:, ith_signal);
end
lampFunctions.Default = defaultWord;
lampFunctions.Source = sources(:);

if options.FlagSave
    writetable(lampFunctions, functionsFile, 'Delimiter', ',', 'QuoteStrings', 'all');
end

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    figure(figNum);
    clf;
    axesHandle = gca;
    imagesc(axesHandle, values, [0 1]);
    colormap(axesHandle, [linspace(1, 0.95, 64)', linspace(1, 0.55, 64)', linspace(1, 0.1, 64)']);
    colorbar(axesHandle);
    set(axesHandle, 'XTick', 1:numSignals, 'XTickLabel', {signalKinds.Label}, 'XTickLabelRotation', 45, ...
        'YTick', 1:numUnits, 'YTickLabel', {units.Name}, 'TickLabelInterpreter', 'none');
    hold(axesHandle, 'on');
    for ith_unit = find(flagEdited)'
        rectangle(axesHandle, 'Position', [0.5, ith_unit-0.5, numSignals, 1], 'EdgeColor', [0 0.4 0.9], 'LineWidth', 1.5);
    end
    title(axesHandle, sprintf('Lamp-to-function matrix: %d units (%d edited, outlined)', numUnits, nnz(flagEdited)));
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

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

%% fcn_INTERNAL_defaults
function [values, sources] = fcn_INTERNAL_defaults(units, signalNames)
% Each unit's default row, from its kind and side (the design file,
% section 4)
numUnits = numel(units);
values = zeros(numUnits, numel(signalNames));
sources = repmat({'(default)'}, numUnits, 1);
column = @(name) find(strcmp(signalNames, name), 1);
% (whether the vehicle has rear turn-signal lamps of its own, per side)
flagRearTurn = struct('left', false, 'right', false, 'center', false);
for ith_unit = 1:numUnits
    if strcmp(units(ith_unit).Kind, 'turnSignalLamp') && startsWith(units(ith_unit).Position, 'rear')
        flagRearTurn.(fcn_INTERNAL_side(units(ith_unit).Position)) = true;
    end
end
% (and high-beam lamps of its own, per side)
flagHighBeam = struct('left', false, 'right', false, 'center', false);
for ith_unit = 1:numUnits
    if strcmp(units(ith_unit).Kind, 'highBeamLamp')
        flagHighBeam.(fcn_INTERNAL_side(units(ith_unit).Position)) = true;
    end
end
for ith_unit = 1:numUnits
    side = fcn_INTERNAL_side(units(ith_unit).Position);
    switch units(ith_unit).Kind
        case 'headlamp'
            % (a headlamp is the high beam too, unless the vehicle has
            % high-beam lamps of its own on that side)
            values(ith_unit, column('LowBeam')) = 1;
            if ~flagHighBeam.(side)
                values(ith_unit, column('HighBeam')) = 1;
            end
        case 'highBeamLamp'
            values(ith_unit, column('HighBeam')) = 1;
        case 'turnSignalLamp'
            values(ith_unit, fcn_INTERNAL_turnColumns(side, column)) = 1;
            if strcmp(side, 'center')
                sources{ith_unit} = '(default: a turn-signal lamp in the middle lights with both turn signals)';
            end
        case 'runningLamp'
            values(ith_unit, column('Running')) = 1;
        case 'markerLamp'
            values(ith_unit, [column('Running') column('Parking') column('Tail')]) = 1;
        case 'tailBrakeLamp'
            values(ith_unit, [column('Parking') column('Tail')]) = 0.4;
            values(ith_unit, [column('Brake') column('EmergencyBrake')]) = 1;
            if ~strcmp(side, 'center') && ~flagRearTurn.(side)
                values(ith_unit, fcn_INTERNAL_turnColumns(side, column)) = 1;
                sources{ith_unit} = '(default: also the rear turn signal, as the vehicle has no rear turn-signal lamp on this side)';
            end
        case 'backupLamp'
            values(ith_unit, column('Backup')) = 1;
        case 'fogLamp'
            values(ith_unit, column('Fog')) = 1;
        case 'licensePlateLamp'
            values(ith_unit, [column('Parking') column('Tail')]) = 1;
        case 'reflector'
            values(ith_unit, column('Reflectors')) = 1;
        case 'warningLamp'
            sources{ith_unit} = '(default: none; a warning lamp (beacon) is switched by your own loop)';
        otherwise
            % (the kinds of tiers 2 and 3: Documentation_CarMesh3D_lampSignalsSurvey.md)
            kindColumns = fcn_INTERNAL_kindColumns(units(ith_unit).Kind, side, column);
            if ~isempty(kindColumns)
                values(ith_unit, kindColumns) = 1;
                continue;
            end
            sources{ith_unit} = '(default: none; a lamp kind the defaults do not know)';
    end
end
end % Ends fcn_INTERNAL_defaults

%% fcn_INTERNAL_migrate
function [values, sources] = fcn_INTERNAL_migrate(vehicleMesh, units, signalNames, defaultValues)
% The rows as the mesh held them before the matrix: the per-face functions
% (LabelFaceAlsoLamps, one column per lamp kind: a face of one kind that
% also lights as another) and the vehicle's own SignalLampSwitching (the signals
% that light a kind)
values = defaultValues;
sources = repmat({''}, numel(units), 1);
column = @(name) find(strcmp(signalNames, name), 1);
typeNames = cellstr(vehicleMesh.LabelLampNames);
numFaces = size(vehicleMesh.Faces, 1);
flagFunctions = isfield(vehicleMesh, 'LabelFaceAlsoLamps') && isequal(size(vehicleMesh.LabelFaceAlsoLamps), [numFaces numel(typeNames)]);
for ith_unit = 1:numel(units)
    notes = {};
    side = fcn_INTERNAL_side(units(ith_unit).Position);
    % (the other kinds most of the unit's faces also light as)
    if flagFunctions
        unitFunctions = logical(vehicleMesh.LabelFaceAlsoLamps(units(ith_unit).Faces, :));
        alsoKinds = typeNames(mean(unitFunctions, 1) >= 0.5);
        alsoKinds = setdiff(alsoKinds, {units(ith_unit).Kind}, 'stable');
        for ith_kind = 1:numel(alsoKinds)
            alsoColumns = fcn_INTERNAL_kindColumns(alsoKinds{ith_kind}, side, column);
            if ~isempty(alsoColumns)
                values(ith_unit, alsoColumns) = max(values(ith_unit, alsoColumns), 1);
                notes{end+1} = alsoKinds{ith_kind}; %#ok<AGROW>
            end
        end
    end
    % (the vehicle's own switching for this kind replaces the default's)
    if isfield(vehicleMesh, 'SignalLampSwitching') && isstruct(vehicleMesh.SignalLampSwitching) && isfield(vehicleMesh.SignalLampSwitching, units(ith_unit).Kind)
        switchedBy = cellstr(vehicleMesh.SignalLampSwitching.(units(ith_unit).Kind));
        values(ith_unit, :) = 0;
        for ith_state = 1:numel(switchedBy)
            stateColumns = fcn_INTERNAL_stateColumns(switchedBy{ith_state}, column);
            values(ith_unit, stateColumns) = 1;
        end
        notes{end+1} = sprintf('SignalLampSwitching %s', strjoin(switchedBy, ' or ')); %#ok<AGROW>
    end
    if ~isempty(notes)
        sources{ith_unit} = sprintf('migrated from the mesh: also %s', strjoin(notes, ', '));
    end
end
end % Ends fcn_INTERNAL_migrate

%% fcn_INTERNAL_kindColumns
function columns = fcn_INTERNAL_kindColumns(kind, side, column)
% The signals a lamp kind answers, for a face that also lights as that kind
switch kind
    case {'headlamp', 'highBeamLamp'}
        if strcmp(kind, 'headlamp')
            columns = [column('LowBeam') column('HighBeam')];
        else
            columns = column('HighBeam');
        end
    case 'turnSignalLamp'
        columns = fcn_INTERNAL_turnColumns(side, column);
    case 'runningLamp'
        columns = column('Running');
    case 'markerLamp'
        columns = [column('Running') column('Parking') column('Tail')];
    case 'tailBrakeLamp'
        columns = [column('Tail') column('Brake')];
    case 'backupLamp'
        columns = column('Backup');
    case 'fogLamp'
        columns = column('Fog');
    case 'licensePlateLamp'
        columns = [column('Parking') column('Tail')];
    case 'reflector'
        columns = column('Reflectors');
    case 'highMountStopLamp'
        columns = [column('Brake') column('EmergencyBrake')];
    case 'rearFogLamp'
        columns = column('RearFog');
    case 'puddleLamp'
        columns = [column('DoorOpen') column('Welcome')];
    case 'cargoLamp'
        columns = column('Cargo');
    case 'adsMarkerLamp'
        columns = column('Automated');
    case 'logoLamp'
        columns = [column('Running') column('Parking') column('Welcome')];
    case {'clearanceLamp', 'identificationLamp'}
        columns = [column('Parking') column('Tail')];
    case 'corneringLamp'
        switch side
            case 'left'
                columns = column('CorneringLeft');
            case 'right'
                columns = column('CorneringRight');
            otherwise
                columns = [column('CorneringLeft') column('CorneringRight')];
        end
    case 'chargePortLamp'
        columns = column('Charging');
    case 'beaconLamp'
        columns = column('Beacon');
    case 'workLamp'
        columns = column('Work');
    case 'emergencyRedLamp'
        columns = column('EmergencyRed');
    case 'emergencyBlueLamp'
        columns = column('EmergencyBlue');
    case 'emergencyWhiteLamp'
        columns = column('EmergencyWhite');
    case 'emergencyAmberLamp'
        columns = column('EmergencyAmber');
    case 'emergencyGreenLamp'
        columns = column('EmergencyGreen');
    case 'schoolBusAmberLamp'
        columns = column('SchoolAmber');
    case {'schoolBusRedLamp', 'stopArmLamp'}
        columns = column('SchoolRed');
    otherwise
        columns = [];
end
end % Ends fcn_INTERNAL_kindColumns

%% fcn_INTERNAL_stateColumns
function columns = fcn_INTERNAL_stateColumns(stateName, column)
% plotVehicle's light state names (SignalLampSwitching's words) as signals;
% Hazards is the two turn signals
switch stateName
    case 'Hazards'
        columns = [column('TurnLeft') column('TurnRight')];
    otherwise
        columns = column(stateName);
end
end % Ends fcn_INTERNAL_stateColumns

%% fcn_INTERNAL_turnColumns
function columns = fcn_INTERNAL_turnColumns(side, column)
% The turn signal of a side; both for a lamp in the middle
switch side
    case 'left'
        columns = column('TurnLeft');
    case 'right'
        columns = column('TurnRight');
    otherwise
        columns = [column('TurnLeft') column('TurnRight')];
end
end % Ends fcn_INTERNAL_turnColumns

%% fcn_INTERNAL_texts
function texts = fcn_INTERNAL_texts(columnIn)
% A table column read from the file as text, one per row ('' for an
% empty cell, which readtable may read as a number)
numRows = size(columnIn, 1);
texts = repmat({''}, numRows, 1);
for ith_row = 1:numRows
    if iscell(columnIn)
        value = columnIn{ith_row};
    else
        value = columnIn(ith_row,:);
    end
    if ischar(value) || isstring(value)
        texts{ith_row} = char(value);
    end
end
end % Ends fcn_INTERNAL_texts

%% fcn_INTERNAL_side
function side = fcn_INTERNAL_side(position)
% 'front-left' gives 'left'
parts = strsplit(position, '-');
side = parts{end};
end % Ends fcn_INTERNAL_side
