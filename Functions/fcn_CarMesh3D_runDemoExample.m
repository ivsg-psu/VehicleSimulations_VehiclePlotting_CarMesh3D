function [examples, echoText] = fcn_CarMesh3D_runDemoExample(exampleName, options)
% fcn_CarMesh3D_runDemoExample
% Runs one of the CarMesh3D demo examples, as chosen in the demo menu of
% script_demo_CarMesh3D. Before running it, the example's commands are
% printed in the command window, so they can be copied and pasted:
%   * the commands the demo runs, on a temporary copy of a vehicle
%     (fcn_CarMesh3D_makeDemoCopy): changes made with them are NOT saved
%     to the vehicle, and
%   * the same commands for the actual vehicle, whose changes ARE saved
%     in the vehicle's folder.
% The commands are run in the base workspace, so the variables they make
% (viewSettings, editedMesh, reviewTable, ...) are there afterwards.
%
% FORMAT:
%
%       [examples, echoText] = fcn_CarMesh3D_runDemoExample(exampleName,...
%           (VehicleID=id), (FlagRun=flag), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      exampleName: which example (see 'list'):
%           'library'     the library browser: pick vehicles from a list
%           'viewer'      the label viewer, beside the vehicle's photos
%           'sharedView'  the viewer opened at a view another user sent
%           'editor'      the mesh (label) editor on its own
%           'reviewer'    the reviewer
%           'animate'     plot a finished vehicle and drive it around
%           'history'     a mesh's change log, license, and review status
%           'list'        (the example) list every vehicle in the library
%           'browse'      the vehicle browser (a menu of its own)
%      or one of these, which run nothing:
%           'examples'    return the list of examples (for building a menu)
%           'last'        print the last example's commands again
%           'warning'     print what the demo copy is, and that changes
%                         made to it are not saved to the vehicle
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      VehicleID: the vehicle the examples use. Default
%      '2009_Honda_Fit_Sport'.
%
%      FlagRun: false to only print the commands. Default true.
%
%      FigNum: if set to -1, input checking is skipped (fast mode) and
%      nothing is printed (the commands are still run, if Run is true).
%      Otherwise not used.
%
% OUTPUTS:
%
%      examples: the examples, one element each: Name, Title (one line,
%      for a menu, starting with the function shown, without its
%      fcn_CarMesh3D_ prefix), Description, DemoCommands and VehicleCommands (cell
%      arrays of lines), and SavesChanges (true when the tool can save
%      changes to a vehicle)
%
%      echoText: the text printed for the example ('' for 'examples')
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_makeDemoCopy, fcn_CarMesh3D_findVehicleFiles, and the
%      tools the examples call; fcn_DebugTools_cprintf (DebugTools) for
%      colored text, when it is on the path
%
% EXAMPLES:
%
%       % Print, then run, the viewer example
%       fcn_CarMesh3D_runDemoExample('viewer');
%
%       % Only print the reviewer example's commands
%       fcn_CarMesh3D_runDemoExample('reviewer', FlagRun=false);
%
%       See the script: script_test_fcn_CarMesh3D_runDemoExample.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runDemoExample
%   % * First write of the code, for the demo menu in script_demo_CarMesh3D
%   %   % (Sean, 14:17): examples for the viewer, the mesh editor and the
%   %   % reviewer, and others; each echoes its commands (on the demo
%   %   % copy, and on the actual vehicle) before it runs

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runDemoExample
%   % * The mesh editor is two examples (Sean, 13:12): on the GUI test
%   %   % vehicle (2026_CarMesh3D_Sample_GUITestVehicle, every feature) and
%   %   % on the demo vehicle; both wait for the window to close, so the
%   %   % outputs come back

% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runDemoExample
%   % * The reviewer example is the V&V GUI now (its title, description
%   %   % and outputs)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_runDemoExample
%   % * The viewer examples pass Wait=true, so they still return the view
%   %   % settings when the window closes (the viewer no longer waits by
%   %   % default: Q68 (A))

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runDemoExample
%   % * (2026_11_22, later) The library browser is the first example
%   % * Each example's title starts with the function it shows (Sean,
%   %   % 14:45), such as "viewLabels: view a mesh's labels ..."

%   % * Add examples for the stand-alone check tools (animateChecks,
%   %   % viewOutline, viewDetailLevels, viewOrientation, viewDimensions)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    exampleName
    options.VehicleID = fcn_CarMesh3D_demoVehicle(FigNum=-1)   % The vehicle the examples use: the demo vehicle (fcn_CarMesh3D_demoVehicle)
    options.FlagRun = true        % false to only print the commands
    options.FigNum = []       % Not used; -1 for fast mode (nothing printed)
end

persistent lastEchoText

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
examples = fcn_INTERNAL_examples(char(options.VehicleID));
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the exampleName input
        knownNames = [{examples.Name}, {'examples', 'last', 'warning'}];
        if ~(ischar(exampleName) || (isstring(exampleName) && isscalar(exampleName))) || ...
                ~any(strcmpi(char(exampleName), knownNames))
            error('CarMesh3D:badInput', 'exampleName must be one of: %s', strjoin(knownNames, ', '));
        end

        % Check the VehicleID input
        if ~(ischar(options.VehicleID) || (isstring(options.VehicleID) && isscalar(options.VehicleID)))
            error('CarMesh3D:badInput', 'VehicleID must be a vehicle ID, such as ''2009_Honda_Fit_Sport''.');
        end
    end
end

% Print the commands?
flagDoPrint = (0==flag_max_speed);

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

exampleName = char(exampleName);
echoText = '';
switch lower(exampleName)
    case 'examples'
        return;
    case 'last'
        echoText = char(lastEchoText);
        if flagDoPrint && ~isempty(echoText)
            fcn_INTERNAL_printEcho(echoText);
        end
        return;
    case 'warning'
        echoText = fcn_INTERNAL_warningText(char(options.VehicleID));
        if flagDoPrint
            fcn_INTERNAL_printEcho(echoText);
        end
        return;
end

thisExample = examples(strcmpi({examples.Name}, exampleName));

% The text echoed: the demo's commands, then the actual vehicle's
echoText = fcn_INTERNAL_echoText(thisExample);
lastEchoText = echoText;
if flagDoPrint
    fcn_INTERNAL_printEcho(echoText);
end

% Run the demo's commands, in the base workspace
if options.FlagRun
    if flagDoPrint
        fprintf(1, '\nRunning the demo commands...\n');
    end
    evalin('base', strjoin(thisExample.DemoCommands, newline));
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

%% fcn_INTERNAL_examples
function examples = fcn_INTERNAL_examples(vehicleID)
% The examples: each one's commands on the demo copy, and on the vehicle

copyLines = {
    '% A fresh, temporary copy of the vehicle: changes are NOT saved to the vehicle'
    sprintf('demoFiles = fcn_CarMesh3D_makeDemoCopy(''%s'', FigNum=1);', vehicleID)};
vehicleLines = {
    '% The vehicle''s own files'
    sprintf('vehicleFiles = fcn_CarMesh3D_findVehicleFiles(''%s'');', vehicleID)};

examples = struct('Name', {}, 'Title', {}, 'Description', {}, 'DemoCommands', {}, 'VehicleCommands', {}, 'SavesChanges', {});

% The library browser
examples(end+1).Name = 'library';
examples(end).Title = 'browseLibrary: browse the vehicle library and pick vehicles';
examples(end).Description = ['Every finished vehicle, one row each: its labeled 3D mesh, its 2D overhead outline, ' ...
    'its name (a star for the exemplar of its class) and MATLAB name, class, size, license, processing score, ' ...
    'and review. Sort, group and filter the list; tick "Select" on vehicles, and their MATLAB names are ' ...
    'returned when the window is closed. With none selected, a fresh copy of the default test vehicle is returned. ' ...
    'View, Edit labels and Review close the browser and open that tool for the vehicle.'];
examples(end).DemoCommands = {
    '% (Browsing changes nothing; with no vehicle selected, a fresh COPY of the test vehicle is returned)'
    sprintf('[selectedNames, ~, nextStep] = fcn_CarMesh3D_browseLibrary(DefaultVehicle=''%s'')', vehicleID)
    '% (View, Edit labels or Review in the browser: the step it returns is opened here, by the trunk)'
    'fcn_CarMesh3D_openTool(nextStep);'};
examples(end).VehicleCommands = {
    sprintf('[selectedNames, ~, nextStep] = fcn_CarMesh3D_browseLibrary(DefaultVehicle=''%s'')', vehicleID)
    '% (View, Edit labels or Review in the browser: the step it returns is opened here, by the trunk)'
    'fcn_CarMesh3D_openTool(nextStep);'};
examples(end).SavesChanges = false;

% The viewer
examples(end+1).Name = 'viewer';
examples(end).Title = 'viewLabels: view a mesh''s labels beside the vehicle''s photos';
examples(end).Description = ['The mesh, each label in its own color, beside the photos of the real vehicle. ' ...
    'Drag the red arrow around the dial to turn the model and change the photo. ' ...
    'When the window is closed, its view settings are returned (viewSettings).'];
examples(end).DemoCommands = [copyLines; {
    '% Opens the viewer; it returns the view settings when it is closed'
    'viewSettings = fcn_CarMesh3D_viewLabels(demoFiles.MeshFile, Outline=demoFiles.OutlineFile, FlagWait=true)'}];
examples(end).VehicleCommands = [vehicleLines; {
    'viewSettings = fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile, Outline=vehicleFiles.OutlineFile, FlagWait=true)'}];
examples(end).SavesChanges = false;

% The viewer, at a shared view
examples(end+1).Name = 'sharedView';
examples(end).Title = 'viewLabels: open the viewer at a view another user sent (a shared view)';
examples(end).Description = ['A view is shared by sending its settings: the viewer opens at that label, photo, ' ...
    'and camera. The viewer''s "Copy view call" button copies the whole call, with the exact camera; ' ...
    'here only the label and the photo angle (180: from behind) are given.'];
examples(end).DemoCommands = [copyLines; {
    '% The view sent: the tail lights alone, seen from behind'
    'sharedView = struct(''Label'', ''light_tailBrakeLamp'', ''PhotoAngle'', 180);'
    'viewSettings = fcn_CarMesh3D_viewLabels(demoFiles.MeshFile, Outline=demoFiles.OutlineFile, ViewSettings=sharedView, FlagWait=true)'}];
examples(end).VehicleCommands = [vehicleLines; {
    'sharedView = struct(''Label'', ''light_tailBrakeLamp'', ''PhotoAngle'', 180);'
    'viewSettings = fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile, Outline=vehicleFiles.OutlineFile, ViewSettings=sharedView, FlagWait=true)'}];
examples(end).SavesChanges = false;

% The mesh editor: on the GUI test vehicle (every feature), then on the
% demo vehicle (a real download): the calls of its test script (Sean, 13:12)
testID = '2026_CarMesh3D_Sample_GUITestVehicle';
examples(end+1).Name = 'editorTest';
examples(end).Title = 'paintLabels: fix labels by painting faces, on the GUI TEST VEHICLE (every lamp, cover, hidden set)';
examples(end).Description = ['The mesh editor on a made-up vehicle that has every feature it shows: all six lamp types on ' ...
    'both sides, glass covers over the headlights, interior objects, two hidden sets, and its own photos. Pick a panel ' ...
    'from the menu at the top left; paint in Modify Labels, then Apply and Save. On the demo copy, Save writes only ' ...
    'into the copy. The outputs come back when the window is closed.'];
examples(end).DemoCommands = {
    '% A fresh, temporary copy of the GUI test vehicle: changes are NOT saved to it'
    sprintf('demoFiles = fcn_CarMesh3D_makeDemoCopy(''%s'', FigNum=1);', testID)
    '% Opens the mesh editor; Save writes labelEdits_<ID>.mat in the COPY''s folder'
    '[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(demoFiles.Folder, FlagWait=true);'};
examples(end).VehicleCommands = {
    '% The GUI test vehicle''s own files (it is rebuilt by its script, so saved paint is lost then)'
    sprintf('vehicleFiles = fcn_CarMesh3D_findVehicleFiles(''%s'');', testID)
    '[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleFiles.Folder, FlagWait=true);'};
examples(end).SavesChanges = true;

examples(end+1).Name = 'editor';
examples(end).Title = sprintf('paintLabels: fix labels by painting faces, on the %s', strrep(vehicleID, '_', ' '));
examples(end).Description = ['The mesh editor on a real download. Pick a panel from the menu at the top left; paint in ' ...
    'Modify Labels (a label, or hide and unhide), then Apply and Save. On the demo copy, Save writes only into ' ...
    'the copy. The outputs come back when the window is closed.'];
examples(end).DemoCommands = [copyLines; {
    '% Opens the mesh editor; Save writes labelEdits_<ID>.mat in the COPY''s folder'
    '[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(demoFiles.Folder, FlagWait=true);'}];
examples(end).VehicleCommands = [vehicleLines; {
    '% Save writes labelEdits_<ID>.mat in the VEHICLE''s folder; rerun the'
    '% vehicle''s script afterward to rebuild its mesh with the edits'
    '[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleFiles.Folder, FlagWait=true);'}];
examples(end).SavesChanges = true;

% The reviewer
examples(end+1).Name = 'reviewer';
examples(end).Title = 'reviewVehicle: the V&V GUI: is the mesh right? One question at a time';
examples(end).Description = ['Each assessment (a first glance, labels, patchy labels, headlights, brake lights, realism) ' ...
    'draws its pictures and asks one question; then the Summary, Approve or Reject. On the demo copy, the answers ' ...
    'are saved only in the copy.'];
examples(end).DemoCommands = [copyLines; {
    '% Opens the V&V GUI; answers are saved in the COPY''s checks folder'
    '[answers, reviewWindow] = fcn_CarMesh3D_reviewVehicle(demoFiles.Folder);'}];
examples(end).VehicleCommands = [vehicleLines; {
    '% Answers are saved in the VEHICLE''s checks folder, with your initials'
    '[answers, reviewWindow] = fcn_CarMesh3D_reviewVehicle(vehicleFiles.Folder, Reviewer=''ABC'');'}];
examples(end).SavesChanges = true;

% Plot and animate
driveLines = {
    'loaded = load(%s.MeshFile, ''vehicleMesh''); vehicleMesh = loaded.vehicleMesh;'
    'figure(1); clf;'
    'plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=1);'
    'axis([-25 25 -25 25 0 4]); title(''A figure eight'');'
    '% Move the vehicle by updating only its pose (much faster than redrawing)'
    'timeValues = linspace(0, 2*pi, 300);'
    'xValues = 20*sin(timeValues); yValues = 10*sin(2*timeValues);'
    'yawValues = atan2(gradient(yValues), gradient(xValues));'
    'for ith_frame = 1:numel(timeValues)'
    '    plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[xValues(ith_frame) yValues(ith_frame) yawValues(ith_frame)], PlotHandles=plotHandles, FigNum=-1);'
    '    drawnow limitrate; pause(0.02);'
    'end'};
examples(end+1).Name = 'animate';
examples(end).Title = 'plotVehicle: plot a finished vehicle and drive it around';
examples(end).Description = 'The finished mesh plotted once, then moved along a figure eight by updating only its pose.';
examples(end).DemoCommands = [copyLines; strrep(driveLines, '%s', 'demoFiles')];
examples(end).VehicleCommands = [vehicleLines; strrep(driveLines, '%s', 'vehicleFiles')];
examples(end).SavesChanges = false;

% The change log
examples(end+1).Name = 'history';
examples(end).Title = 'meshHistory: show a mesh''s change log, license, and review status';
examples(end).Description = ['Who changed the mesh and when, the downloaded model''s license, when the mesh was built, ' ...
    'and whether a person has reviewed it (the fine print at the bottom of the viewer).'];
examples(end).DemoCommands = [copyLines; {
    'history = fcn_CarMesh3D_meshHistory(demoFiles.Folder);'
    'disp(history.FinePrint); disp(history.Entries);'}];
examples(end).VehicleCommands = [vehicleLines; {
    'history = fcn_CarMesh3D_meshHistory(vehicleFiles.Folder);'
    'disp(history.FinePrint); disp(history.Entries);'}];
examples(end).SavesChanges = false;

% List the vehicles
examples(end+1).Name = 'list';
examples(end).Title = 'findVehicleFiles: list every vehicle in the library';
examples(end).Description = 'Every vehicle folder below Data, with which of its files exist (model, parameters, script, mesh, levels).';
examples(end).DemoCommands = {
    '% (Listing changes nothing, so no copy is needed)'
    'vehicleList = fcn_CarMesh3D_findVehicleFiles('''', FigNum=1);'};
examples(end).VehicleCommands = {
    'vehicleList = fcn_CarMesh3D_findVehicleFiles('''', FigNum=1);'};
examples(end).SavesChanges = false;

% Browse the vehicles
examples(end+1).Name = 'browse';
examples(end).Title = 'browseVehicles: browse the finished vehicles (a menu of its own)';
examples(end).Description = 'A menu of every finished vehicle with its quality score: type a vehicle''s number to see it in 3D and 2D.';
examples(end).DemoCommands = {
    '% (Browsing changes nothing, so no copy is needed)'
    'vehicleTable = fcn_CarMesh3D_browseVehicles(FlagInteractive=true, ViewFigNum=1);'};
examples(end).VehicleCommands = {
    'vehicleTable = fcn_CarMesh3D_browseVehicles(FlagInteractive=true, ViewFigNum=1);'};
examples(end).SavesChanges = false;
end % Ends fcn_INTERNAL_examples

%% fcn_INTERNAL_warningText
function warningText = fcn_INTERNAL_warningText(vehicleID)
% What the demo copy is
lines = {
    '% ===== WARNING: the examples use a DEMO COPY of a vehicle ====='
    sprintf('Each example starts from a fresh copy of the %s''s folder,', strrep(vehicleID, '_', ' '))
    sprintf('made in %s', fullfile(tempdir, 'CarMesh3D_demo', vehicleID))
    'by fcn_CarMesh3D_makeDemoCopy. Anything changed in an example (labels'
    'painted and saved in the mesh editor, answers given in the reviewer, the'
    'change log) is saved only in that copy, NOT in the vehicle, and the copy'
    'is replaced the next time an example starts.'
    ''
    'Each example also prints the same commands for the ACTUAL vehicle: run'
    'those to change the vehicle itself.'
    'Press any key to return to the menu.'};
warningText = strjoin(lines, newline);
end % Ends fcn_INTERNAL_warningText

%% fcn_INTERNAL_echoText
function echoText = fcn_INTERNAL_echoText(thisExample)
% The text printed for an example
rule = repmat('-', 1, 78);
lines = {rule; sprintf('EXAMPLE: %s', thisExample.Title); rule};
lines = [lines; fcn_INTERNAL_wrap(thisExample.Description, 78); {''}];
lines = [lines; {'% ===== Commands used here (on a temporary DEMO COPY: changes are NOT saved) ====='}];
lines = [lines; thisExample.DemoCommands(:); {''}];
if thisExample.SavesChanges
    lines = [lines; {'% ===== The same, for the ACTUAL vehicle (changes ARE saved to the vehicle) ====='}];
else
    lines = [lines; {'% ===== The same, for the ACTUAL vehicle ====='}];
end
lines = [lines; thisExample.VehicleCommands(:); {rule}];
echoText = strjoin(lines, newline);
end % Ends fcn_INTERNAL_echoText

%% fcn_INTERNAL_printEcho
function fcn_INTERNAL_printEcho(echoText)
% Prints the text; the headings in color when DebugTools' cprintf is there
% (fcn_DebugTools_cprintf takes a style and a format only, so each line is
% escaped and given as the format)
flagColor = exist('fcn_DebugTools_cprintf', 'file') == 2;
lines = split(string(echoText), newline);
for ith_line = 1:numel(lines)
    thisLine = char(lines(ith_line));
    if flagColor && startsWith(thisLine, '% ===== WARNING')
        fcn_DebugTools_cprintf('*Red', [fcn_INTERNAL_escape(thisLine) '\n']);
    elseif flagColor && startsWith(thisLine, '% =====') && contains(thisLine, 'DEMO COPY')
        fcn_DebugTools_cprintf('*Blue', [fcn_INTERNAL_escape(thisLine) '\n']);
    elseif flagColor && startsWith(thisLine, '% =====') && contains(thisLine, 'ARE saved')
        fcn_DebugTools_cprintf('*Red', [fcn_INTERNAL_escape(thisLine) '\n']);
    elseif flagColor && startsWith(thisLine, '% =====')
        fcn_DebugTools_cprintf('*Black', [fcn_INTERNAL_escape(thisLine) '\n']);
    elseif flagColor && startsWith(thisLine, 'EXAMPLE:')
        fcn_DebugTools_cprintf('*Black', [fcn_INTERNAL_escape(thisLine) '\n']);
    else
        fprintf(1, '%s\n', thisLine);
    end
end
end % Ends fcn_INTERNAL_printEcho

%% fcn_INTERNAL_escape
function text = fcn_INTERNAL_escape(text)
% Text made safe to use as a format (cprintf takes a format only)
text = strrep(strrep(text, '\', '\\'), '%', '%%');
end % Ends fcn_INTERNAL_escape

%% fcn_INTERNAL_wrap
function lines = fcn_INTERNAL_wrap(text, width)
% Wraps text into lines of at most width characters
words = split(string(text));
lines = {};
thisLine = '';
for ith_word = 1:numel(words)
    word = char(words(ith_word));
    if isempty(thisLine)
        thisLine = word;
    elseif numel(thisLine) + 1 + numel(word) <= width
        thisLine = [thisLine ' ' word]; %#ok<AGROW>
    else
        lines{end+1,1} = thisLine; %#ok<AGROW>
        thisLine = word;
    end
end
if ~isempty(thisLine)
    lines{end+1,1} = thisLine;
end
end % Ends fcn_INTERNAL_wrap
