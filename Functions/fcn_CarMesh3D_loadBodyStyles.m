function bodyStyles = fcn_CarMesh3D_loadBodyStyles(options)
% fcn_CarMesh3D_loadBodyStyles

% Lists the vehicle body styles (sedan, hatchback, minivan, pickup, and
% so on) and the finished vehicles filed under each. Vehicles are kept in
% Data\BodyStyles\<Style>\<ID> (see fcn_CarMesh3D_findVehicleFiles). An
% EXEMPLAR of a style is a finished vehicle used as a starting shape that
% can be refit to any vehicle of that style when no model of the vehicle
% itself is found (fcn_CarMesh3D_fillBodyStyleMesh picks the exemplar
% closest in size). The exemplars are the vehicles named in the list's
% Exemplars column (approved after review; IDs separated by semicolons)
% that have a finished mesh; a style with none named has no exemplar. A
% list without that column makes every finished vehicle in the style's
% folder an exemplar (the rule before 2026_11_21). The styles' names and
% descriptions are in the text file Data\bodyStyles.csv, one row per
% style; a style's folder is its ID with a capital first letter
% (compactCargoVan is in Data\BodyStyles\CompactCargoVan).
%
% FORMAT:
%
%       bodyStyles = fcn_CarMesh3D_loadBodyStyles(...
%           (DataFolder=folder), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      FigNum: a figure to show every exemplar, one row per style, each
%      labeled (styles without one are listed in the title). If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      bodyStyles: a structure array, one element per style, with
%           BodyStyle: the style's ID, such as 'sedan' or 'minivan'
%           Name: a readable name, such as 'Full-size pickup (crew cab)'
%           Description: what sets the style apart
%           Core: true for the 13 core light-vehicle styles, false for the
%               optional ones
%           Folder: the style's folder, Data\BodyStyles\<Style>
%           VehicleIDs: every vehicle filed there (a cell array of IDs)
%           ExemplarIDs: the approved exemplars (named in the Exemplars
%               column) with a finished mesh; without that column, every
%               vehicle in the folder with a finished mesh
%           HasExemplar: true if there is at least one exemplar
%           SuggestedVehicles: vehicles that would make good exemplars
%      A folder under Data\BodyStyles that is not in the list is added at
%      the end (its name as its Name), with a warning
%      ('CarMesh3D:unlistedStyle').
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       bodyStyles = fcn_CarMesh3D_loadBodyStyles(FigNum=1);
%       {bodyStyles([bodyStyles.HasExemplar]).BodyStyle}
%       sedan = bodyStyles(strcmp({bodyStyles.BodyStyle}, 'sedan'));
%       sedan.VehicleIDs
%
%       See the script: script_test_fcn_CarMesh3D_loadBodyStyles.m for a
%       full test suite.
%
% This function was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadBodyStyles
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadBodyStyles
%   % * Styles are the folders of Data\BodyStyles: each lists every vehicle filed there (VehicleIDs) and those with a finished mesh (ExemplarIDs); the ExemplarID column is gone
%   % * Added Core and Folder; the list has all 22 styles
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadBodyStyles
%   % * Exemplars column in bodyStyles.csv: only approved vehicles are
%   %   % exemplars (every finished vehicle had been, including crumpled
%   %   % dense downloads awaiting replacement)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadBodyStyles
%   % * Exemplars for the styles still without one (see the SuggestedVehicles column)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.DataFolder = []   % The Data folder; [] for the one next to Functions
    options.FigNum = []       % Figure to show the exemplars; [] for no plot, -1 for fast mode
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


        if ~isempty(options.DataFolder) && ~isfolder(options.DataFolder)
            error('DataFolder is not a folder: %s', char(options.DataFolder));
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


dataFolder = options.DataFolder;
if isempty(dataFolder)
    dataFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Data');
end
dataFolder = char(dataFolder);
listFile = fullfile(dataFolder, 'bodyStyles.csv');
if ~isfile(listFile)
    error('The body-style list is missing: %s', listFile);
end
listTable = readtable(listFile, 'TextType','char', 'Delimiter',',', 'VariableNamingRule','preserve');
coreColumn = listTable.Core;
flagApprovedList = any(strcmp(listTable.Properties.VariableNames, 'Exemplars'));
if flagApprovedList
    approvedColumn = listTable.Exemplars;
    if ~iscell(approvedColumn)
        approvedColumn = num2cell(approvedColumn);              % (an all-empty column is read as NaN)
    end
end
listTable = convertvars(listTable, @(column) ~iscell(column), @(column) cellstr(string(column)));

%%%% Every vehicle below Data, by the style folder it is filed under
allVehicles = fcn_CarMesh3D_findVehicleFiles('', DataFolder=dataFolder, FigNum=-1);
vehicleStyles = {allVehicles.BodyStyle};

%%%% The listed styles, then any style folder not in the list
styleIDs = cellfun(@strtrim, listTable.BodyStyle, 'UniformOutput', false);
styleNames = cellfun(@strtrim, listTable.Name, 'UniformOutput', false);
styleDescriptions = cellfun(@strtrim, listTable.Description, 'UniformOutput', false);
styleSuggested = cellfun(@(value) strtrim(fcn_INTERNAL_text(value)), listTable.SuggestedVehicles, 'UniformOutput', false);
styleCore = num2cell(fcn_INTERNAL_logical(coreColumn));
styleApproved = repmat({{}}, numel(styleIDs), 1);
if flagApprovedList
    for ith_style = 1:numel(styleIDs)
        approvedText = fcn_INTERNAL_text(approvedColumn{ith_style});
        if ~isempty(approvedText)
            styleApproved{ith_style} = reshape(strtrim(strsplit(approvedText, ';')), [], 1);
        end
    end
end
stylesFolder = fullfile(dataFolder, 'BodyStyles');
if isfolder(stylesFolder)
    folderListing = dir(stylesFolder);
    folderListing = folderListing([folderListing.isdir] & ~startsWith({folderListing.name}, '.'));
    for ith_folder = 1:numel(folderListing)
        folderName = folderListing(ith_folder).name;
        folderStyle = [lower(folderName(1)) folderName(2:end)];
        if ~any(strcmp(styleIDs, folderStyle))
            warning('CarMesh3D:unlistedStyle', 'The style folder %s is not in %s; it is listed without a description', ...
                folderName, listFile);
            styleIDs{end+1,1} = folderStyle; %#ok<AGROW>
            styleNames{end+1,1} = folderName; %#ok<AGROW>
            styleDescriptions{end+1,1} = ''; %#ok<AGROW>
            styleSuggested{end+1,1} = ''; %#ok<AGROW>
            styleCore{end+1,1} = false; %#ok<AGROW>
            styleApproved{end+1,1} = {}; %#ok<AGROW>
        end
    end
end

Nstyles = numel(styleIDs);
bodyStyles = struct('BodyStyle',{}, 'Name',{}, 'Description',{}, 'Core',{}, 'Folder',{}, ...
    'VehicleIDs',{}, 'ExemplarIDs',{}, 'HasExemplar',{}, 'SuggestedVehicles',{});
for ith_style = 1:Nstyles
    thisStyle = styleIDs{ith_style};
    styleFolder = [upper(thisStyle(1)) thisStyle(2:end)];
    inStyle = strcmp(vehicleStyles, thisStyle);
    vehicleIDs = reshape({allVehicles(inStyle).ID}, [], 1);
    exemplarIDs = reshape({allVehicles(inStyle & [allVehicles.HasMesh]).ID}, [], 1);
    if flagApprovedList
        % (only the approved vehicles, in the list's order; one named but
        % not finished, or not filed under this style, is left out with a
        % warning)
        approvedIDs = styleApproved{ith_style};
        unfinished = approvedIDs(~ismember(approvedIDs, exemplarIDs));
        if ~isempty(unfinished)
            warning('CarMesh3D:exemplarNotFinished', ['Exemplars named for the ''%s'' style in %s with no finished ' ...
                'mesh in its folder (left out): %s'], thisStyle, listFile, strjoin(unfinished, ', '));
        end
        exemplarIDs = reshape(approvedIDs(ismember(approvedIDs, exemplarIDs)), [], 1);
    end
    bodyStyles(ith_style) = struct('BodyStyle',thisStyle, 'Name',styleNames{ith_style}, ...
        'Description',styleDescriptions{ith_style}, 'Core',styleCore{ith_style}, ...
        'Folder',fullfile(stylesFolder, styleFolder), 'VehicleIDs',{vehicleIDs}, 'ExemplarIDs',{exemplarIDs}, ...
        'HasExemplar',~isempty(exemplarIDs), 'SuggestedVehicles',styleSuggested{ith_style});
end

%% Plot the results (for debugging)?
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

    % Every exemplar, one row per style, each labeled
    figure(figNum);
    clf;
    hold on;
    withExemplar = find([bodyStyles.HasExemplar]);
    yOffset = 0;
    for ith_style = withExemplar
        xOffset = 0;
        rowWidth = 0;
        for ith_exemplar = 1:numel(bodyStyles(ith_style).ExemplarIDs)
            exemplarFiles = fcn_CarMesh3D_findVehicleFiles(bodyStyles(ith_style).ExemplarIDs{ith_exemplar}, DataFolder=dataFolder, FigNum=-1);
            loaded = load(exemplarFiles.MeshFile, 'vehicleMesh');
            vertices = loaded.vehicleMesh.Vertices;
            vehicleLength = max(vertices(:,1)) - min(vertices(:,1));
            rowWidth = max(rowWidth, max(vertices(:,2)) - min(vertices(:,2)));
            xPlace = xOffset - min(vertices(:,1));
            fcn_CarMesh3D_plotVehicle(loaded.vehicleMesh, Pose=[xPlace yOffset 0], FigNum=figNum);
            labelText = strrep(exemplarFiles.ID, '_', ' ');
            if 1==ith_exemplar
                labelText = sprintf('%s:\n%s', bodyStyles(ith_style).Name, labelText);
            end
            text(xOffset + vehicleLength/2, yOffset, max(vertices(:,3)) + 0.6, labelText, ...
                'HorizontalAlignment','center', 'FontSize',9);
            xOffset = xOffset + vehicleLength + 2.5;
        end
        yOffset = yOffset - rowWidth - 3;
    end
    axis equal;
    axis off;
    view(28, 12);
    camproj('orthographic');
    % (the title: the count, then the styles still needing an exemplar,
    % four to a line)
    withoutExemplar = {bodyStyles(~[bodyStyles.HasExemplar]).Name};
    titleLines = {sprintf('Body styles with exemplars: %d of %d (%d vehicles). Still needed:', numel(withExemplar), ...
        numel(bodyStyles), numel(vertcat(bodyStyles.ExemplarIDs)))};
    for ith_line = 1:4:numel(withoutExemplar)
        titleLines{end+1} = strjoin(withoutExemplar(ith_line:min(ith_line+3, end)), ', '); %#ok<AGROW>
    end
    title(titleLines, 'FontSize', 9, 'FontWeight', 'normal');
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

%% fcn_INTERNAL_text
function textValue = fcn_INTERNAL_text(value)
% A cell from the list as text ('' for an empty or missing value)
if isempty(value) || (isnumeric(value) && all(isnan(value))) || (isstring(value) && all(ismissing(value)))
    textValue = '';
else
    textValue = char(string(value));
    if strcmpi(textValue, 'NaN')
        textValue = '';
    end
end
end % Ends fcn_INTERNAL_text

%% fcn_INTERNAL_logical
function flags = fcn_INTERNAL_logical(column)
% The Core column as true/false (1/0, true/false, or yes/no)
if isnumeric(column) || islogical(column)
    flags = column ~= 0 & ~isnan(double(column));
else
    flags = ismember(lower(strtrim(string(column))), ["1","true","yes"]);
end
flags = reshape(logical(flags), [], 1);
end % Ends fcn_INTERNAL_logical
