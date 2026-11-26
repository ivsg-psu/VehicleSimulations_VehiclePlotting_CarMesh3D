function [vehicleTable, selections] = fcn_CarMesh3D_browseVehicles(options)
% fcn_CarMesh3D_browseVehicles

% A menu, in the command window, of the finished vehicles in the Data
% folder: one numbered line per vehicle, with its name, body style,
% quality score (0 to 100, see fcn_CarMesh3D_makeBuildInfo), and whether
% its mesh is up to date. Typing a vehicle's number shows it
% (fcn_CarMesh3D_showVehicle: the mesh in 3D and its 2D outlines) and
% marks it "viewed"; the menu then offers the next vehicle. Other
% choices: (v) change what a vehicle's number shows (3D and 2D, labels,
% or materials), (t) print the full table, (q) quit.
%
% The menu is DebugTools' fcn_DebugTools_menuManageSelections, so
% DebugTools must be installed: run script_demo_CarMesh3D once (its
% installer puts DebugTools in the Utilities folder).
%
% FORMAT:
%
%       [vehicleTable, selections] = fcn_CarMesh3D_browseVehicles(...
%           (SortBy=order), (FlagIncludeUnfinished=flag), (FlagInteractive=flag),...
%           (ViewFigNum=figNum), (DataFolder=folder), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SortBy: the order of the list: 'bodyStyle' (default: by body
%      style, then ID), 'score' (best first), or 'name'.
%
%      FlagIncludeUnfinished: true to list vehicles without a finished mesh
%      too (they are shown grayed out and cannot be chosen). Default
%      false.
%
%      FlagInteractive: true (default) to open the menu. False only builds
%      the menu (selections) and returns, for scripts and tests.
%
%      ViewFigNum: the figure a chosen vehicle is shown in (its 2D
%      outlines go in ViewFigNum+1). Default 1.
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      FigNum: if given (not -1), the vehicle list is also printed before
%      the menu opens. If set to -1, input checking is skipped (fast
%      mode).
%
% OUTPUTS:
%
%      vehicleTable: the vehicles listed, in menu order (the table from
%      fcn_CarMesh3D_listVehicles), with a MenuChar column.
%
%      selections: the menu definition given to
%      fcn_DebugTools_menuManageSelections (one element per menu line).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_listVehicles, fcn_CarMesh3D_showVehicle,
%      fcn_DebugTools_menuManageSelections (DebugTools, when Interactive)
%
% EXAMPLES:
%
%       fcn_CarMesh3D_browseVehicles;                  % the menu
%       fcn_CarMesh3D_browseVehicles(SortBy='score');  % best first
%
%       See the script: script_test_fcn_CarMesh3D_browseVehicles.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseVehicles
%   % * Wrote the code originally (drafted with Claude): a menu of the
%   %   % finished vehicles with their quality scores, built on DebugTools'
%   %   % fcn_DebugTools_menuManageSelections

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseVehicles
%   % * The DebugTools menu changes into the folder of the outermost
%   %   % calling script and keeps its answers in that folder's Data
%   %   % folder; this function runs it from the CarMesh3D root, which works
%   %   % from the command line and from CarMesh3D's own scripts. Calling
%   %   % it from a script in another repository makes the menu ask to
%   %   % change folder.
%   % * Filters (one body style, or only out-of-date meshes)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.SortBy = 'bodyStyle'        % 'bodyStyle', 'score', or 'name'
    options.FlagIncludeUnfinished = false   % List vehicles without a mesh too?
    options.FlagInteractive = true          % Open the menu? (false: only build it)
    options.ViewFigNum = 1              % The figure a chosen vehicle is shown in
    options.DataFolder = []             % The Data folder; [] for the one next to Functions
    options.FigNum = []                 % Print the list if given; -1 for fast mode
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
        if ~any(strcmpi(char(options.SortBy), {'bodyStyle','score','name'}))
            error('SortBy must be ''bodyStyle'', ''score'', or ''name''');
        end
        if ~(islogical(options.FlagIncludeUnfinished) || isnumeric(options.FlagIncludeUnfinished)) || ~isscalar(options.FlagIncludeUnfinished)
            error('IncludeUnfinished must be true or false');
        end
        if ~(islogical(options.FlagInteractive) || isnumeric(options.FlagInteractive)) || ~isscalar(options.FlagInteractive)
            error('Interactive must be true or false');
        end
        if ~isnumeric(options.ViewFigNum) || ~isscalar(options.ViewFigNum) || options.ViewFigNum<1 || options.ViewFigNum~=round(options.ViewFigNum)
            error('ViewFigNum must be a figure number (a positive integer)');
        end
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
vehicleTable = fcn_CarMesh3D_listVehicles(FlagIncludeUnfinished=options.FlagIncludeUnfinished, ...
    DataFolder=options.DataFolder, FigNum=-1);
switch lower(char(options.SortBy))
    case 'score'
        sortScore = vehicleTable.Score;
        sortScore(isnan(sortScore)) = -Inf;          % (unscored last)
        [~, order] = sortrows([-sortScore, (1:height(vehicleTable))']);
        vehicleTable = vehicleTable(order,:);
    case 'name'
        vehicleTable = sortrows(vehicleTable, 'Name');
    otherwise
        % (listVehicles' order: body style, then ID)
end
Nvehicles = height(vehicleTable);
vehicleTable.MenuChar = string((1:Nvehicles)');

% The menu: one line per vehicle (the vehicle lines come first: the
% DebugTools menu treats the leading numbered lines as "questions" and
% offers the first one not yet answered, here not yet viewed), then the
% commands. Commands are run by the menu with sprintf then eval, so
% quotes are doubled and backslashes and percent signs escaped.
dataFolderText = 'DataFolder=[]';
if ~isempty(options.DataFolder)
    dataFolderText = sprintf('DataFolder=''%s''', fcn_INTERNAL_escape(char(options.DataFolder)));
end
viewFigText = sprintf('%d', options.ViewFigNum);

selections = fcn_INTERNAL_emptySelection();
for ith_vehicle = 1:Nvehicles
    thisRow = vehicleTable(ith_vehicle,:);
    scoreText = 'no score';
    if ~isnan(thisRow.Score)
        scoreText = sprintf('score %.0f', thisRow.Score);
    end
    exemplarText = '';
    if thisRow.IsExemplar
        exemplarText = ', exemplar';
    end
    newLine = fcn_INTERNAL_emptySelection();
    newLine.MenuChar = char(thisRow.MenuChar);
    newLine.Name = char(thisRow.ID);
    % (two lines: the menu wraps text at 50 characters; '\n' starts a line)
    newLine.Text = [') ' char(thisRow.Name) '\n' char(thisRow.BodyStyle) exemplarText ' | ' scoreText ' | ' char(thisRow.Status)];
    newLine.AnswerDefault = ' ';
    % (a vehicle that cannot be shown prints why, instead of closing the menu)
    showCommand = sprintf('fcn_CarMesh3D_showVehicle(''%s'', View=getenv(''CARMESH3D_BROWSER_VIEW''), %s, FigNum=%s);', ...
        fcn_INTERNAL_escape(char(thisRow.ID)), dataFolderText, viewFigText);
    newLine.FunctionSubmission = { ...
        ['try, ' showCommand ' answers{' sprintf('%d', ith_vehicle) '} = ''viewed''; ' ...
         'catch showError, fprintf(1,''This vehicle could not be shown: %%s\\n'', showError.message); end'];
        'fprintf(1,''Hit any key to return to the list.\\n''); pause;'};
    newLine.isAllowableMenuOption = thisRow.Status~="no mesh";
    selections(ith_vehicle,1) = newLine;
end

if Nvehicles==0
    selections = selections([]);
end

% (v) what a vehicle's number shows
newLine = fcn_INTERNAL_emptySelection();
newLine.MenuChar = 'v';
newLine.Name = 'View';
newLine.Text = '(V)iew: what a vehicle''s number shows\n(1: 3D and 2D, 2: parts by label, 3: by material)';
newLine.AnswerDefault = ' ';
newLine.FunctionSubmission = { ...
    'viewChoice = input(''Show 1: 3D and 2D, 2: parts by label, or 3: by material? [1]: '',''s'');';
    'viewNames = {''both'',''labels'',''materials''}; viewIndex = str2double(viewChoice);';
    'if isnan(viewIndex) || ~any(viewIndex==1:3), viewIndex = 1; end';
    'setenv(''CARMESH3D_BROWSER_VIEW'', viewNames{viewIndex}); answers{end-2} = viewNames{viewIndex};'};
selections(end+1,1) = newLine;

% (t) the full table
newLine = fcn_INTERNAL_emptySelection();
newLine.MenuChar = 't';
newLine.Name = 'Table';
newLine.Text = '(T)able: print every vehicle, with face counts and mesh versions.';
newLine.AnswerDefault = ' ';
newLine.FunctionSubmission = { ...
    sprintf('fcn_CarMesh3D_listVehicles(FlagIncludeUnfinished=%d, %s, FigNum=0);', logical(options.FlagIncludeUnfinished), dataFolderText);
    'fprintf(1,''Hit any key to return to the list.\\n''); pause;'};
selections(end+1,1) = newLine;

% (q) quit
newLine = fcn_INTERNAL_emptySelection();
newLine.MenuChar = 'q';
newLine.Name = 'Quit';
newLine.Text = '(Q)uit the vehicle browser.';
newLine.AnswerDefault = ' ';
newLine.FunctionSubmission = 'flagExitMain = 1; fprintf(1,''Leaving the vehicle browser.\\n'');';
selections(end+1,1) = newLine;
selections(1).AssignmentString = 'CarMesh3D_vehicleBrowser';   % (names the menu's answers file)

%% Open the menu
if flag_do_plots
    fcn_CarMesh3D_listVehicles(FlagIncludeUnfinished=options.FlagIncludeUnfinished, DataFolder=options.DataFolder, FigNum=0);
end
if logical(options.FlagInteractive)
    if 2~=exist('fcn_DebugTools_menuManageSelections','file')
        error('CarMesh3D:noDebugTools', ['The vehicle browser needs DebugTools (fcn_DebugTools_menuManageSelections). ' ...
            'Run script_demo_CarMesh3D once: its installer puts DebugTools in the Utilities folder and on the path.']);
    end
    if 0==Nvehicles
        fprintf(1, 'No finished vehicles were found in the Data folder.\n');
        return;
    end

    % The menu runs from the CarMesh3D root (it keeps its answers in Data)
    rootFolder = fileparts(fileparts(mfilename('fullpath')));
    previousFolder = pwd;
    previousView = getenv('CARMESH3D_BROWSER_VIEW');
    answersFile = fullfile(rootFolder, 'Data', ['answersSoFar_' selections(1).AssignmentString '.mat']);
    cleanupObject = onCleanup(@() fcn_INTERNAL_cleanUp(previousFolder, previousView, answersFile)); %#ok<NASGU>
    cd(rootFolder);
    setenv('CARMESH3D_BROWSER_VIEW', 'both');
    if isfile(answersFile)
        delete(answersFile);                 % (each browse starts with nothing viewed)
    end
    fcn_DebugTools_menuManageSelections(selections, 1);
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



%% fcn_INTERNAL_emptySelection
function selection = fcn_INTERNAL_emptySelection()
% One menu line, with every field fcn_DebugTools_menuManageSelections uses
selection = struct( ...
    'AssignmentString', '', ...
    'MenuChar', '', ...
    'Name', '', ...
    'Text', '', ...
    'AnswerDefault', ' ', ...
    'AnswerType', '_of_char_strings', ...
    'AnswerConversionFunction', '', ...
    'AnswerTypeOptions', [], ...
    'AnswerPrintFormat', '%s', ...
    'FunctionMore', '', ...
    'FunctionMoreInputs', [], ...
    'FunctionSubmission', '', ...
    'FunctionSubmissionOptions', {{'.'}}, ...
    'isAllowableMenuOption', true);
end % Ends fcn_INTERNAL_emptySelection


%% fcn_INTERNAL_escape
function text = fcn_INTERNAL_escape(text)
% Text to go inside a quoted command that the menu passes through sprintf
text = strrep(text, '\', '\\');
text = strrep(text, '%', '%%');
text = strrep(text, '''', '''''');
end % Ends fcn_INTERNAL_escape


%% fcn_INTERNAL_cleanUp
function fcn_INTERNAL_cleanUp(previousFolder, previousView, answersFile)
% After the menu: back to the starting folder, the view setting restored,
% and the menu's answers file removed
if isfile(answersFile)
    delete(answersFile);
end
setenv('CARMESH3D_BROWSER_VIEW', previousView);
if isfolder(previousFolder)
    cd(previousFolder);
end
end % Ends fcn_INTERNAL_cleanUp
