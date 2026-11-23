function checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleSpec, outputFolder, options)
% fcn_CarMesh3D_runVehicleChecks
% Runs the STANDARD CHECKS on a finished vehicle mesh: the standard test
% motion (fcn_CarMesh3D_fillTestMotion), in the standard scene, seen
% through standard cameras, saved as a standard set of images and
% animated GIFs. Look through them to confirm that every input works for
% this vehicle (lights, steering, wheels, body motion) before using it.
%
% THE FILES WRITTEN to outputFolder (usually the vehicle's checks folder):
%
%   check_01_inputs.png          The test motion's inputs over time,
%                                with the four segments shaded.
%   check_02_dimensions.png/.txt Side, top, and front views, and the table
%                                of target vs. measured dimensions.
%   check_03_labels.png          Four views with each part and light type
%                                in its own color: are the headlights,
%                                signals, tail and backup lights, glass,
%                                and wheels labeled correctly?
%   check_04_lightStates.png     At night, each light switched on alone
%                                (3 x 3 grid of pictures).
%   check_05_lights.gif          At night, the lights segment, front-left
%                                and rear views side by side.
%   check_06_body.gif            The body segment (roll, pitch, heave, each
%                                tire lifted), front-left and rear-right
%                                views, low down.
%   check_07_steering.gif        The steering segment from above, with
%                                lines from the turn center to each wheel.
%   check_08_wheels.gif          The wheels segment from the side
%                                (peel-out, locked wheels, backing up).
%   check_09_drive.gif           The steering and wheels segments from
%                                behind and above (every second frame).
%   check_10_groundContact.png   Body clearance over the whole motion
%                                (fcn_CarMesh3D_checkGroundContact).
%   With SaveFigs=true, each .png also has a .fig of the same name, to open
%   with openfig and zoom, pan, or rotate. check_03_labels.fig is one 3D view of the
%   labels (fcn_CarMesh3D_plotLabels), not the four pictures.
%   check_summary.txt            The list of files, the dimension check,
%                                and the ground-contact result.
%   testMotion.csv               The standard test motion, as a CSV file.
%
% THE STANDARD SCENE is a ground grid with colored cubes, kept at least
% 9 m from the path. Light checks are at night (fcn_CarMesh3D_plotScene
% with TimeOfDay='night', and LightEffects=true); the others by day.
%
% THE STANDARD CAMERAS ride with the vehicle and are scaled to its size:
% positions are fractions of the vehicle's length L and height H, from
% the middle of the vehicle on the ground. So every vehicle is framed the
% same way, whether it is a small car or a van.
%
% FORMAT:
%
%       checkResults = fcn_CarMesh3D_runVehicleChecks(vehicleMesh,...
%           vehicleSpec, outputFolder, (Checks=names), (SaveGifs=flag), (SaveFigs=flag),...
%           (VehicleName=name), (PanelSize=[w h]), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleMesh: a finished mesh (labeled, fitted, simplified).
%
%      vehicleSpec: the vehicle's spec (for the test motion and the
%      dimension check).
%
%      outputFolder: where to write the files. It is made if needed.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Checks: 'all' (default), or a cell array of check names to run:
%      'inputs','dimensions','labels','lightStates','lights','body',
%      'steering','wheels','drive','groundContact'.
%
%      SaveGifs: true (default) to save the GIFs; false to only play the
%      animations (faster, for a first look).
%
%      SaveFigs: true to save a .fig beside each picture (to open with
%      openfig and zoom or rotate); false (default) for the pictures only.
%
%      VehicleName: a name for the captions. Default is vehicleSpec.Name.
%
%      PanelSize: [width height] in pixels of each view. Default [480 300].
%
%      FigNum: the figure number to draw in (all checks reuse it). Default
%      [] uses figure 900. If set to -1, input checking is skipped.
%
% OUTPUTS:
%
%      checkResults: a structure with fields Files (cell array of the
%      files written), ValidationTable, ContactFlags (N x 1), and
%      TestMotion.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillTestMotion, fcn_CarMesh3D_validateMesh,
%      fcn_CarMesh3D_plotScene, fcn_CarMesh3D_plotVehicle,
%      fcn_CarMesh3D_fillCameraSettings, fcn_CarMesh3D_updateCamera,
%      fcn_CarMesh3D_saveGifFrame, fcn_CarMesh3D_checkGroundContact,
%      fcn_CarMesh3D_plotLabels
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
%       load(vehicleFiles.MeshFile, 'vehicleMesh');
%       fcn_CarMesh3D_runVehicleChecks(vehicleMesh, vehicleMesh.VehicleSpec, vehicleFiles.ChecksFolder);
%
%       See the script: script_test_fcn_CarMesh3D_runVehicleChecks.m for a test,
%       and the vehicle scripts (Data\<ID>\script_CarMesh3D_vehicle_<ID>.m).
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runVehicleChecks
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runVehicleChecks
%   % * The labels picture takes its colors from fcn_CarMesh3D_plotLabels
%   %   % (one place for the label colors)
%   % * Pictures of a vehicle on a plain background (the labels and the
%   %   % light states) are captured again, after waiting longer, when the
%   %   % vehicle has not been drawn yet: in a MATLAB started with -batch,
%   %   % most labels pictures of the 2026_11_21 remake were blank
%   % * Each picture is also saved as a .fig file (Sean: PNGs cannot be
%   %   % zoomed or rotated); check_03_labels.fig is one rotatable 3D view
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runVehicleChecks
%   % * SaveFigs (default false): the .fig beside each picture only when
%   %   % asked (Sean: the checks wrote 1.1 GB of .fig and .gif files,
%   %   % unused in review); the labels legend says the body is white
%   %   % (fcn_CarMesh3D_plotLabels)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_runVehicleChecks
%   % * A contact sheet (one image with a frame of every GIF)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    vehicleSpec
    outputFolder
    options.Checks = 'all'          % 'all' or a cell array of check names
    options.SaveGifs = true         % Save the GIFs?
    options.SaveFigs = false        % Save a .fig beside each picture?
    options.VehicleName = ''        % Name for captions; '' for vehicleSpec.Name
    options.PanelSize = [480 300]   % [width height] of each view, in pixels
    options.FigNum = []             % Figure to draw in; [] for 900, -1 for fast mode
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
allCheckNames = {'inputs','dimensions','labels','lightStates','lights','body','steering','wheels','drive','groundContact'};
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the vehicleMesh and vehicleSpec inputs
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'FacePartIndex') || ~isfield(vehicleMesh,'AxleX')
            error('vehicleMesh must be a finished CarMesh3D mesh (labeled and fitted)');
        end
        if ~isstruct(vehicleSpec) || ~isfield(vehicleSpec,'Wheelbase')
            error('vehicleSpec must be a CarMesh3D vehicle spec');
        end

        % Check the outputFolder input
        if ~(ischar(outputFolder) || isstring(outputFolder))
            error('outputFolder must be a folder name');
        end

        % Check the Checks input
        if ~(ischar(options.Checks) && strcmpi(options.Checks,'all'))
            if ~iscellstr(options.Checks) || ~all(ismember(options.Checks, allCheckNames)) %#ok<ISCLSTR>
                error('Checks must be ''all'' or a cell array of: %s', strjoin(allCheckNames,', '));
            end
        end

        % Check the PanelSize input
        if ~isnumeric(options.PanelSize) || numel(options.PanelSize)~=2 || any(options.PanelSize<100)
            error('PanelSize must be [width height] in pixels, each at least 100');
        end
    end
end

% The figure to draw in
figNum = options.FigNum;
if isempty(figNum) || isequal(figNum,-1)
    figNum = 900;
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

outputFolder = char(outputFolder);
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
if ischar(options.Checks) && strcmpi(options.Checks,'all')
    checkNames = allCheckNames;
else
    checkNames = options.Checks;
end
doCheck = @(name) any(strcmp(checkNames, name));
vehicleName = options.VehicleName;
if isempty(vehicleName)
    vehicleName = vehicleSpec.Name;
end
settings = struct('PanelSize',options.PanelSize(:)', 'SaveGifs',logical(options.SaveGifs), ...
    'FigNum',figNum, 'VehicleName',vehicleName);
% (whether a .fig is saved beside each picture: read by fcn_INTERNAL_saveFig)
setappdata(groot, 'CarMesh3D_runVehicleChecks_SaveFigs', logical(options.SaveFigs));
cleanupSaveFigs = onCleanup(@() fcn_INTERNAL_clearSaveFigs()); %#ok<NASGU>
writtenFiles = {};
validationTable = [];
contactFlags = [];

%%%%
% The standard test motion, written next to the checks
testMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec, CSVFile=fullfile(outputFolder,'testMotion.csv'), ...
    FigNum=fcn_INTERNAL_figNumIf(doCheck('inputs'), figNum));
writtenFiles{end+1} = testMotion.CSVFile;
if doCheck('inputs')
    sgtitle(sprintf('%s: the standard test motion (inputs)', vehicleName), 'Interpreter','none');
    writtenFiles{end+1} = fcn_INTERNAL_savePicture(figNum, fullfile(outputFolder,'check_01_inputs.png'));
end

%%%%
% The standard cameras, scaled to the vehicle (vehicle frame, from the
% middle of the vehicle on the ground)
cameras = fcn_INTERNAL_standardCameras(vehicleMesh);

%%%%
% Dimensions
if doCheck('dimensions')
    fcn_INTERNAL_freshFigure(figNum, [1100 700], [1 1 1]);
    validationTable = fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec, FigNum=figNum);
    sgtitle(sprintf('%s: dimensions', vehicleName), 'Interpreter','none');
    writtenFiles{end+1} = fcn_INTERNAL_savePicture(figNum, fullfile(outputFolder,'check_02_dimensions.png'));
    tableFile = fullfile(outputFolder,'check_02_dimensions.txt');
    writetable(validationTable, tableFile, 'Delimiter','\t');
    writtenFiles{end+1} = tableFile;
end

%%%%
% Labels: each part and light type in its own color
if doCheck('labels')
    writtenFiles{end+1} = fcn_INTERNAL_labelPicture(vehicleMesh, cameras, settings, fullfile(outputFolder,'check_03_labels.png'));
end

%%%%
% Light states: each light alone, at night (3 x 3 pictures)
if doCheck('lightStates')
    writtenFiles{end+1} = fcn_INTERNAL_lightStatesPicture(vehicleMesh, testMotion, cameras, settings, ...
        fullfile(outputFolder,'check_04_lightStates.png'));
end

%%%%
% The animations: [segment names], {view names}, time of day, file, frame step
animationList = {
    'lights',   {'frontLeft','rear'},              'night', 'check_05_lights.gif',   1, 'lights';
    'body',     {'frontLeftLow','rearRightLow'},   'day',   'check_06_body.gif',     1, 'body';
    'steering', {'overhead'},                      'day',   'check_07_steering.gif', 1, 'steering';
    'wheels',   {'side'},                          'day',   'check_08_wheels.gif',   1, 'wheels';
    {'steering','wheels'}, {'kite'},               'day',   'check_09_drive.gif',    2, 'drive'};
for ith_animation = 1:size(animationList,1)
    if ~doCheck(animationList{ith_animation,6})
        continue;
    end
    segmentNames = cellstr(animationList{ith_animation,1});
    rows = fcn_INTERNAL_segmentRows(testMotion, segmentNames);
    rows = rows(1:animationList{ith_animation,5}:end);
    gifFile = fullfile(outputFolder, animationList{ith_animation,4});
    fcn_INTERNAL_animate(vehicleMesh, testMotion, rows, cameras, animationList{ith_animation,2}, ...
        animationList{ith_animation,3}, settings, gifFile, strcmp(animationList{ith_animation,1},'steering'));
    if settings.SaveGifs
        writtenFiles{end+1} = gifFile; %#ok<AGROW>
    end
end

%%%%
% Ground contact over the whole test motion
if doCheck('groundContact')
    fcn_INTERNAL_freshFigure(figNum, [1000 380], [1 1 1]);
    [~, contactFlags] = evalc(['fcn_CarMesh3D_checkGroundContact(vehicleMesh, testMotion.BodyRoll, ' ...
        'testMotion.BodyPitch, testMotion.BodyHeave, Time=testMotion.Time, FigNum=figNum)']);
    writtenFiles{end+1} = fcn_INTERNAL_savePicture(figNum, fullfile(outputFolder,'check_10_groundContact.png'));
end

%%%%
% Summary
summaryFile = fullfile(outputFolder,'check_summary.txt');
fileID = fopen(summaryFile,'w');
fprintf(fileID,'Standard checks for %s\n', vehicleName);
fprintf(fileID,'Written %s by fcn_CarMesh3D_runVehicleChecks\n\n', char(datetime('now','Format','yyyy-MM-dd HH:mm')));
fprintf(fileID,'Mesh: %d faces, %d vertices\n', size(vehicleMesh.Faces,1), size(vehicleMesh.Vertices,1));
if ~isempty(validationTable)
    fprintf(fileID,'Dimensions: %d of %d within tolerance\n', sum(validationTable.Pass), height(validationTable));
end
if ~isempty(contactFlags)
    fprintf(fileID,'Ground contact during the test motion: %d of %d samples\n', sum(contactFlags), numel(contactFlags));
end
fprintf(fileID,'\nFiles:\n');
fprintf(fileID,'  %s\n', writtenFiles{:});
fclose(fileID);
writtenFiles{end+1} = summaryFile;

checkResults = struct;
checkResults.Files = writtenFiles(:);
checkResults.ValidationTable = validationTable;
checkResults.ContactFlags = contactFlags;
checkResults.TestMotion = testMotion;

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
% (The checks are the plots; they are saved to files above)

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

%% fcn_INTERNAL_figNumIf
function figNumOut = fcn_INTERNAL_figNumIf(flagPlot, figNum)
% The figure number if a plot is wanted (in a fresh figure), else [] (no plot)
if flagPlot
    figNumOut = figNum;
    fcn_INTERNAL_freshFigure(figNum, [1100 800], [1 1 1]);
else
    figNumOut = [];
end
end % Ends fcn_INTERNAL_figNumIf

%% fcn_INTERNAL_savePicture
function fileName = fcn_INTERNAL_savePicture(figNum, fileName)
% Saves what the figure shows (getframe draws the 3D scene correctly)
figureHandle = figure(figNum);
set(figureHandle,'Units','pixels');
position = get(figureHandle,'Position');
imwrite(fcn_INTERNAL_capture(figureHandle, position(3:4)), fileName);
fcn_INTERNAL_saveFig(figureHandle, fileName);
end % Ends fcn_INTERNAL_savePicture

%% fcn_INTERNAL_clearSaveFigs
function fcn_INTERNAL_clearSaveFigs()
if isappdata(groot, 'CarMesh3D_runVehicleChecks_SaveFigs')
    rmappdata(groot, 'CarMesh3D_runVehicleChecks_SaveFigs');
end
end % Ends fcn_INTERNAL_clearSaveFigs

%% fcn_INTERNAL_saveFig
function fcn_INTERNAL_saveFig(figureHandle, pictureFile)
% Saves the figure as a .fig file next to its picture (same name), to
% open later with openfig and zoom, pan, or rotate, when SaveFigs is
% true. The saved copy opens visible, even when it was made in a MATLAB
% with no display (-batch).
if ~isappdata(groot, 'CarMesh3D_runVehicleChecks_SaveFigs') || ~getappdata(groot, 'CarMesh3D_runVehicleChecks_SaveFigs')
    return;
end
[folder, name] = fileparts(pictureFile);
oldCreateFcn = get(figureHandle,'CreateFcn');
set(figureHandle,'CreateFcn','set(gcbo,''Visible'',''on'')');
savefig(figureHandle, fullfile(folder,[name '.fig']), 'compact');
set(figureHandle,'CreateFcn',oldCreateFcn);
end % Ends fcn_INTERNAL_saveFig

%% fcn_INTERNAL_standardCameras
function cameras = fcn_INTERNAL_standardCameras(vehicleMesh)
% Camera positions and targets in the vehicle frame, as fractions of the
% vehicle's length L and height H, from the middle of the vehicle
lowCorner = min(vehicleMesh.Vertices,[],1);
highCorner = max(vehicleMesh.Vertices,[],1);
L = highCorner(1) - lowCorner(1);
H = highCorner(3) - lowCorner(3);
xMiddle = (lowCorner(1) + highCorner(1))/2;
c = [xMiddle 0 0];
cameras = struct;
%                      position                       target                      field of view
cameras.frontLeft    = {c + [ 0.95*L  0.80*L 0.75*H], c + [ 0.05*L 0 0.40*H], 40};
cameras.rearLeft     = {c + [-0.95*L  0.80*L 0.75*H], c + [-0.05*L 0 0.40*H], 40};
cameras.rear         = {c + [-1.30*L  0      0.90*H], c + [-0.20*L 0 0.45*H], 35};
cameras.frontLeftLow = {c + [ 0.95*L  0.80*L 0.20*H], c + [ 0.05*L 0 0.25*H], 40};
cameras.rearRightLow = {c + [-0.95*L -0.80*L 0.20*H], c + [-0.05*L 0 0.25*H], 40};
cameras.side         = {c + [ 0      -1.70*L 0.30*H], c + [ 0      0 0.30*H], 35};
cameras.overhead     = {c + [ 0       0      2.40*L], c,                      45};
cameras.kite         = {c + [-1.70*L  0      1.40*L], c + [ 0.90*L 0 0     ], 50};
cameras.Length = L;
end % Ends fcn_INTERNAL_standardCameras

%% fcn_INTERNAL_cameraSettings
function cameraSettings = fcn_INTERNAL_cameraSettings(cameras, viewName)
% A CarMesh3D camera from one of the standard views
thisCamera = cameras.(viewName);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', Position=thisCamera{1}, ...
    PositionFrame='vehicle', Target=thisCamera{2}, TargetFrame='vehicle', FieldOfView=thisCamera{3}, FigNum=-1);
end % Ends fcn_INTERNAL_cameraSettings

%% fcn_INTERNAL_segmentRows
function rows = fcn_INTERNAL_segmentRows(testMotion, segmentNames)
% The time-step rows of the given segments
rows = false(size(testMotion.Time));
for ith_segment = 1:length(testMotion.Segments)
    thisSegment = testMotion.Segments(ith_segment);
    if any(strcmp(segmentNames, thisSegment.Name))
        rows = rows | (testMotion.Time >= thisSegment.StartTime & testMotion.Time <= thisSegment.EndTime);
    end
end
rows = find(rows);
end % Ends fcn_INTERNAL_segmentRows

%% fcn_INTERNAL_standardScene
function [figureHandle, axesList, plotHandlesList] = fcn_INTERNAL_standardScene(vehicleMesh, testMotion, viewNames, timeOfDay, settings, vehicleOptions)
% A figure with one panel per view, each with the standard scene and the
% vehicle. vehicleOptions are extra options for fcn_CarMesh3D_plotVehicle.
Nviews = length(viewNames);
figureSize = [settings.PanelSize(1)*Nviews settings.PanelSize(2)];
figureHandle = fcn_INTERNAL_freshFigure(settings.FigNum, figureSize, [0.78 0.86 0.95]);
pathXY = testMotion.Pose(:,1:2);
groundExtent = [min(pathXY(:,1))-35 max(pathXY(:,1))+35 min(pathXY(:,2))-35 max(pathXY(:,2))+35];
cubes = fcn_INTERNAL_standardCubes(groundExtent, pathXY, 9);
flagNight = strcmpi(timeOfDay,'night');
axesList = gobjects(Nviews,1);
plotHandlesList = cell(Nviews,1);
for ith_view = 1:Nviews
    % Each view sits in its own panel, because a panel clips its axes (an
    % axes alone can draw outside its Position and cover its neighbor)
    panelHandle = uipanel('Parent',figureHandle,'Units','normalized', ...
        'Position',[(ith_view-1)/Nviews 0 1/Nviews 1],'BorderType','none','BackgroundColor',get(figureHandle,'Color'));
    axesList(ith_view) = axes('Parent',panelHandle,'Position',[0 0 1 1]);
    figureHandle.CurrentAxes = axesList(ith_view);
    fcn_CarMesh3D_plotScene(GroundExtent=groundExtent, GridSpacing=2, Cubes=cubes, TimeOfDay=timeOfDay, FigNum=settings.FigNum);
    set(panelHandle,'BackgroundColor',get(figureHandle,'Color'));   % Sky color (dark at night)
    figureHandle.CurrentAxes = axesList(ith_view);
    % (Options from a cell array, so the quoted 'Name',value form is used)
    plotHandlesList{ith_view} = fcn_CarMesh3D_plotVehicle(vehicleMesh, 'Finish','glossy', 'LightEffects',flagNight, ...
        vehicleOptions{:}, 'FigNum',settings.FigNum);
    axis(axesList(ith_view),'off');
    axis(axesList(ith_view),[groundExtent -1 25]);
end
end % Ends fcn_INTERNAL_standardScene

%% fcn_INTERNAL_standardCubes
function cubes = fcn_INTERNAL_standardCubes(groundExtent, pathXY, clearance)
% Cubes on a 10 m grid (with a fixed pattern of sizes and colors), kept
% at least "clearance" meters from the path
[gridX, gridY] = meshgrid(groundExtent(1)+5:10:groundExtent(2)-5, groundExtent(3)+5:10:groundExtent(4)-5);
centers = [gridX(:) gridY(:)];
keep = true(size(centers,1),1);
for ith_cube = 1:size(centers,1)
    keep(ith_cube) = min(sum((pathXY - centers(ith_cube,:)).^2, 2)) > clearance^2;
end
centers = centers(keep,:);
Ncubes = size(centers,1);
cubeSizes = 1.5 + mod((1:Ncubes)', 3)*0.75;
colorIndex = mod((1:Ncubes)'*3, 8) + 1;
cubes = [centers cubeSizes colorIndex];
end % Ends fcn_INTERNAL_standardCubes

%% fcn_INTERNAL_caption
function captionHandle = fcn_INTERNAL_caption(figureHandle, captionText)
% A caption across the top of the figure. A uicontrol is used (not an
% annotation) because it stays on top of the view panels.
figurePosition = get(figureHandle,'Position');
captionHandle = uicontrol('Parent',figureHandle,'Style','text','Units','pixels', ...
    'Position',[1 figurePosition(4)-20 figurePosition(3) 20],'String',captionText, ...
    'FontWeight','bold','FontSize',9,'HorizontalAlignment','left', ...
    'BackgroundColor',[0.92 0.92 0.92],'ForegroundColor',[0 0 0]);
end % Ends fcn_INTERNAL_caption

%% fcn_INTERNAL_moveVehicle
function fcn_INTERNAL_moveVehicle(vehicleMesh, testMotion, row, plotHandles, extraOptions)
% Puts the vehicle at one time step of the test motion
% (Options from a cell array, so the quoted 'Name',value form is used)
fcn_CarMesh3D_plotVehicle(vehicleMesh, 'Pose',testMotion.Pose(row,:), ...
    'WheelSpin',testMotion.WheelSpin(row,:), 'SteerAngle',testMotion.SteerAngle(row,:), ...
    'WheelLift',testMotion.WheelLift(row,:), 'BodyRoll',testMotion.BodyRoll(row), ...
    'BodyPitch',testMotion.BodyPitch(row), 'BodyHeave',testMotion.BodyHeave(row), ...
    'LightStates',testMotion.LightStates(row), extraOptions{:}, 'PlotHandles',plotHandles, 'FigNum',-1);
end % Ends fcn_INTERNAL_moveVehicle

%% fcn_INTERNAL_animate
function fcn_INTERNAL_animate(vehicleMesh, testMotion, rows, cameras, viewNames, timeOfDay, settings, gifFile, flagTurnLines)
% Plays (and saves) one check animation
[figureHandle, axesList, plotHandlesList] = fcn_INTERNAL_standardScene(vehicleMesh, testMotion, viewNames, timeOfDay, settings, {});
captionHandle = fcn_INTERNAL_caption(figureHandle, '');
Nviews = length(viewNames);
cameraList = cell(Nviews,1);
for ith_view = 1:Nviews
    cameraList{ith_view} = fcn_INTERNAL_cameraSettings(cameras, viewNames{ith_view});
end

% Steering: dashed lines from the turn center to each wheel
turnLines = gobjects(0);
if flagTurnLines
    hold(axesList(1),'on');
    lineColors = [0 0 1; 1 0 0; 0.2 0.2 0.2; 0.2 0.2 0.2]; % FL blue, FR red, rear gray
    for ith_wheel = 1:4
        turnLines(ith_wheel) = plot3(axesList(1), nan(1,2), nan(1,2), [0.05 0.05], '--', ...
            'Color', lineColors(ith_wheel,:), 'LineWidth', 1.5);
    end
    turnLines(5) = plot3(axesList(1), nan, nan, 0.05, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 6);
end

fcn_INTERNAL_capture(figureHandle, [settings.PanelSize(1)*Nviews settings.PanelSize(2)]); % Settle the window size
for ith_frame = 1:length(rows)
    row = rows(ith_frame);
    pose = testMotion.Pose(row,:);
    yaw = pose(end);
    for ith_view = 1:Nviews
        fcn_INTERNAL_moveVehicle(vehicleMesh, testMotion, row, plotHandlesList{ith_view}, {});
        thisCamera = cameraList{ith_view};
        if strcmp(viewNames{ith_view},'overhead')
            thisCamera.UpVector = [cos(yaw) sin(yaw) 0];   % The vehicle's front is up
        end
        fcn_CarMesh3D_updateCamera(thisCamera, pose, AxesHandle=axesList(ith_view), FigNum=-1);
    end
    captionText = sprintf('%s | %s', settings.VehicleName, testMotion.Caption{row});
    if flagTurnLines
        captionText = sprintf('%s | steer FL %.1f%s, FR %.1f%s', captionText, ...
            rad2deg(testMotion.SteerAngle(row,1)), char(176), rad2deg(testMotion.SteerAngle(row,2)), char(176));
        fcn_INTERNAL_updateTurnLines(turnLines, testMotion, row, plotHandlesList{1});
    end
    set(captionHandle,'String',captionText);
    drawnow;
    if settings.SaveGifs
        fcn_CarMesh3D_saveGifFrame(figureHandle, gifFile, ith_frame, ...
            DelayTime=median(diff(testMotion.Time)), FigNum=-1);
    end
end
end % Ends fcn_INTERNAL_animate

%% fcn_INTERNAL_updateTurnLines
function fcn_INTERNAL_updateTurnLines(turnLines, testMotion, row, plotHandles)
% Lines from the turn center (from yaw rate / speed) to each wheel center
pose = testMotion.Pose(row,:);
yaw = pose(end);
rotation = [cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];
wheelXY = (rotation*plotHandles.WheelCenters(:,1:2)')' + pose(1:2);
curvature = 0;
if abs(testMotion.Speed(row)) > 0.1 && isfield(testMotion.Data,'yaw_rate')
    curvature = testMotion.Data.yaw_rate(row)/testMotion.Speed(row);
end
if abs(curvature) < 1e-3
    set(turnLines(1:4), 'XData', nan(1,2), 'YData', nan(1,2));
    set(turnLines(5), 'XData', nan, 'YData', nan);
    return;
end
turnCenter = pose(1:2) + [-sin(yaw) cos(yaw)]/curvature;
for ith_wheel = 1:4
    set(turnLines(ith_wheel), 'XData', [turnCenter(1) wheelXY(ith_wheel,1)], 'YData', [turnCenter(2) wheelXY(ith_wheel,2)]);
end
set(turnLines(5), 'XData', turnCenter(1), 'YData', turnCenter(2));
end % Ends fcn_INTERNAL_updateTurnLines

%% fcn_INTERNAL_labelPicture
function fileName = fcn_INTERNAL_labelPicture(vehicleMesh, cameras, settings, fileName)
% Four views with each part and light type in its own color
labelMesh = fcn_CarMesh3D_plotLabels(vehicleMesh, FigNum=-1);   % (the label colors)

viewNames = {'frontLeft','rearRightLow','side','overhead'};
viewTitles = {'front left','rear right (low)','right side','top'};
pictures = cell(1,4);
for ith_view = 1:4
    figureHandle = fcn_INTERNAL_freshFigure(settings.FigNum, settings.PanelSize, [1 1 1]);
    axesHandle = axes('Parent',figureHandle,'Position',[0 0 1 1]);
    fcn_CarMesh3D_plotVehicle(labelMesh, Finish='matte', FigNum=settings.FigNum);
    axis(axesHandle,'off');
    thisCamera = fcn_INTERNAL_cameraSettings(cameras, viewNames{ith_view});
    if strcmp(viewNames{ith_view},'overhead')
        thisCamera.UpVector = [1 0 0];
    end
    axis(axesHandle,'vis3d');
    fcn_CarMesh3D_updateCamera(thisCamera, [0 0 0], AxesHandle=axesHandle, FigNum=-1);
    title(axesHandle,'');
    fcn_INTERNAL_caption(figureHandle, viewTitles{ith_view});
    pictures{ith_view} = fcn_INTERNAL_capture(figureHandle, settings.PanelSize, true);
end
legendText = 'Labels:  body white | glass light blue | wheels black | trim dark gray | light with no type magenta | headlight yellow | turn signal orange | running cyan | tail red | backup green';
fileName = fcn_INTERNAL_montage(pictures, 2, 2, sprintf('%s: part and light labels', settings.VehicleName), legendText, settings, fileName);

% The .fig is one 3D view that can be rotated and zoomed (in place of the
% montage's .fig, which is only a picture)
figureHandle = fcn_INTERNAL_freshFigure(settings.FigNum, [1000 700], [1 1 1]);
fcn_CarMesh3D_plotLabels(vehicleMesh, Title=settings.VehicleName, FigNum=settings.FigNum);
fcn_INTERNAL_saveFig(figureHandle, fileName);
end % Ends fcn_INTERNAL_labelPicture

%% fcn_INTERNAL_lightStatesPicture
function fileName = fcn_INTERNAL_lightStatesPicture(vehicleMesh, testMotion, cameras, settings, fileName)
% At night, each light alone: the middle frame of each step of the
% lights segment, from the front (first four) or the rear (the rest)
rows = fcn_INTERNAL_segmentRows(testMotion, {'lights'});
captions = testMotion.Caption(rows);
[stepNames, firstIndex] = unique(captions, 'stable');
pictures = cell(1, length(stepNames));
[figureHandle, axesList, plotHandlesList] = fcn_INTERNAL_standardScene(vehicleMesh, testMotion, {'frontLeft'}, 'night', settings, {});
captionHandle = fcn_INTERNAL_caption(figureHandle, '');
for ith_step = 1:length(stepNames)
    stepRows = rows(strcmp(captions, stepNames{ith_step}));
    % A frame where the turn signals are lit (blinking starts "on")
    row = stepRows(min(2, numel(stepRows)));
    if ith_step <= 4
        viewName = 'frontLeft';
    else
        viewName = 'rear';      % Straight behind: both sides' lamps show
    end
    fcn_INTERNAL_moveVehicle(vehicleMesh, testMotion, row, plotHandlesList{1}, {});
    fcn_CarMesh3D_updateCamera(fcn_INTERNAL_cameraSettings(cameras, viewName), testMotion.Pose(row,:), ...
        AxesHandle=axesList(1), FigNum=-1);
    set(captionHandle,'String',strrep(stepNames{ith_step},'Lights: ',''));
    pictures{ith_step} = fcn_INTERNAL_capture(figureHandle, settings.PanelSize, true);
end
fileName = fcn_INTERNAL_montage(pictures, 3, 3, sprintf('%s: each light alone, at night', settings.VehicleName), ...
    'Check that each picture shows only the light named in it. Signals blink, so one frame is shown with them on.', settings, fileName);
end % Ends fcn_INTERNAL_lightStatesPicture

%% fcn_INTERNAL_montage
function fileName = fcn_INTERNAL_montage(pictures, Nrows, Ncolumns, titleText, footerText, settings, fileName)
% Puts pictures in a grid, adds a title above and a note below, and saves
% it. The grid is shown as an image in a figure with text boxes, so the
% text wraps and the layout does not depend on the screen.
tileHeight = size(pictures{1},1);
tileWidth = size(pictures{1},2);
grid = uint8(255*ones(Nrows*tileHeight, Ncolumns*tileWidth, 3));
for ith_picture = 1:min(numel(pictures), Nrows*Ncolumns)
    thisPicture = imresize_nearest(pictures{ith_picture}, [tileHeight tileWidth]);
    rowIndex = floor((ith_picture-1)/Ncolumns);
    columnIndex = mod(ith_picture-1, Ncolumns);
    grid(rowIndex*tileHeight+(1:tileHeight), columnIndex*tileWidth+(1:tileWidth), :) = thisPicture;
end
titleHeight = 36;
footerHeight = 44;
figureSize = [size(grid,2), size(grid,1) + titleHeight + footerHeight];
figureHandle = fcn_INTERNAL_freshFigure(settings.FigNum, figureSize, [1 1 1]);
axesHandle = axes('Parent',figureHandle,'Units','pixels','Position',[1 footerHeight+1 size(grid,2) size(grid,1)]);
image(axesHandle, grid);
axis(axesHandle,'off');
set(axesHandle,'DataAspectRatio',[1 1 1]);
annotation(figureHandle,'textbox','Units','pixels','Position',[1 figureSize(2)-titleHeight figureSize(1) titleHeight], ...
    'String',titleText,'EdgeColor','none','FontWeight','bold','FontSize',12, ...
    'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','none');
annotation(figureHandle,'textbox','Units','pixels','Position',[1 1 figureSize(1) footerHeight], ...
    'String',footerText,'EdgeColor','none','FontSize',9, ...
    'HorizontalAlignment','center','VerticalAlignment','middle','Interpreter','none');
montageImage = fcn_INTERNAL_capture(figureHandle, figureSize);
imwrite(montageImage, fileName);
fcn_INTERNAL_saveFig(figureHandle, fileName);
end % Ends fcn_INTERNAL_montage

%% fcn_INTERNAL_freshFigure
function figureHandle = fcn_INTERNAL_freshFigure(figNum, figureSize, backgroundColor)
% A new, empty figure of exactly the given size. The old figure is closed
% (not just cleared), because a window that is resized after it is drawn
% can be captured at its old size, which spoils GIFs and pictures.
if ishandle(figNum)
    close(figNum);
end
figureHandle = figure(figNum);
set(figureHandle,'Units','pixels','Position',[40 40 figureSize],'Color',backgroundColor);
drawnow;
end % Ends fcn_INTERNAL_freshFigure

%% fcn_INTERNAL_capture
function picture = fcn_INTERNAL_capture(figureHandle, figureSize, flagExpectVehicle)
% Captures the figure at the given size. The size is set again first, and
% the capture is repeated if the window had not finished resizing.
% flagExpectVehicle (default false): the picture shows a vehicle on a
% plain background; if the capture is still blank below the caption (the
% vehicle not drawn yet, as happens in a MATLAB started with -batch), it
% waits longer and captures again (up to about 6 s in all).
if nargin<3
    flagExpectVehicle = false;
end
waitTimes = 0.05;
if flagExpectVehicle
    waitTimes = [0.05 0.2 0.5 1 2 2.5];
end
for ith_wait = 1:numel(waitTimes)
    for ith_try = 1:3
        set(figureHandle,'Units','pixels');
        position = get(figureHandle,'Position');
        if ~isequal(position(3:4), figureSize(:)')
            set(figureHandle,'Position',[position(1:2) figureSize(:)']);
        end
        drawnow;
        pause(waitTimes(ith_wait));
        frame = getframe(figureHandle);
        picture = frame.cdata;
        % (On high-resolution screens the capture is larger by a fixed factor)
        scale = size(picture,2)/figureSize(1);
        if abs(size(picture,1) - scale*figureSize(2)) <= 2
            break;
        end
    end
    if ~flagExpectVehicle || fcn_INTERNAL_hasContent(picture)
        break;
    end
end
end % Ends fcn_INTERNAL_capture

%% fcn_INTERNAL_hasContent
function flagContent = fcn_INTERNAL_hasContent(picture)
% True if the picture, below a caption band at the top (the upper 15%),
% has more than 0.5% of its pixels different from its bottom-left corner
% (the background)
startRow = max(1, round(0.15*size(picture,1)));
lowerPart = double(picture(startRow:end,:,:));
background = double(picture(end,1,:));
differs = any(abs(lowerPart - background) > 8, 3);
flagContent = mean(differs(:)) > 0.005;
end % Ends fcn_INTERNAL_hasContent

%% imresize_nearest
function resized = imresize_nearest(picture, newSize)
% Nearest-neighbor resize (no Image Processing Toolbox needed); used only
% to even out a pixel or two between captured frames
rowIndex = min(size(picture,1), max(1, round((1:newSize(1))*size(picture,1)/newSize(1))));
columnIndex = min(size(picture,2), max(1, round((1:newSize(2))*size(picture,2)/newSize(2))));
resized = picture(rowIndex, columnIndex, :);
end % Ends imresize_nearest
