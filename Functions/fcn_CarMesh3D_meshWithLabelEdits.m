function [vehicleMesh, info] = fcn_CarMesh3D_meshWithLabelEdits(vehicleInput, options)
% fcn_CarMesh3D_meshWithLabelEdits
% Returns a vehicle's mesh with the label fixes saved in its labelEdits
% file, with no window. It is the mesh the vehicle's script would save if
% it ran now:
%
%   - If the mesh file is newer than the labelEdits file (the script has
%     run since the last save of label fixes), the mesh file is returned
%     as it is: it already has them.
%   - Otherwise (label fixes saved since, as the painter does), the
%     stage-1 mesh (the cached mesh before any label fixes,
%     cache\stage1_mesh.mat) is taken, the saved fixes are applied with
%     fcn_CarMesh3D_editLabels, and the lamps' clear covers are found
%     again with fcn_CarMesh3D_findLampCovers: the same steps, in the same
%     order, as the vehicle script's step 5.
%
% Tools that need "the mesh with its saved label fixes" (the animation
% checks, the model reviewer) call this function instead of building a
% hidden painter to get it (the tree rule, Sean, 2026-11-24 01:28: a tool
% never builds a hidden copy of another GUI to compute something).
%
% FORMAT:
%
%       [vehicleMesh, info] = fcn_CarMesh3D_meshWithLabelEdits(vehicleInput,...
%           (FlagAlways=flagAlways), (FlagOrientFaces=flagOrient),...
%           (FlagLampFunctions=flagLamps), (FlagFaceFlips=flagFlips),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or its folder,
%      as fcn_CarMesh3D_findVehicleFiles takes.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FlagAlways: true to apply the saved fixes to the stage-1 mesh even when
%      the mesh file is newer (for checking that the two agree). Default
%      false.
%
%      FlagOrientFaces: true (default) to turn each face to point the same way
%      as its neighbors (fcn_CarMesh3D_orientFaces), so faces pointing the
%      wrong way do not show as bright or dark slivers; false for the faces
%      as saved. Only the faces' direction changes, so saved label edits
%      (matched by face position) are not affected (Q87 (A), Sean
%      2026_11_26 03:16).
%
%      FlagLampFunctions: true (default) to add the vehicle's lamp-to-function
%      matrix to the mesh, as the field LampFunctions (a table, from
%      fcn_CarMesh3D_lampFunctions: the vehicle's file
%      lampFunctions_<ID>.csv, else the defaults), so whatever draws the
%      mesh lights its lamps as the vehicle's file says
%      (fcn_CarMesh3D_plotVehicle, through fcn_CarMesh3D_lampSetup);
%      false for none.
%
%      FlagFaceFlips: true (default) to turn the faces saved in the
%      vehicle's faceFlips_<ID>.mat file (the face-direction window,
%      fcn_CarMesh3D_fixFaceDirections) to the way they were saved, after
%      the faces are turned to agree with their neighbors (which could
%      turn them back); false to leave them. Safe to repeat: a face already
%      pointing as saved is not turned (fcn_CarMesh3D_applyFaceFlips).
%
%      FigNum: a figure to plot the returned mesh in. If empty or omitted,
%      no plot is made. If set to -1, input checking is skipped and no plot
%      is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with the saved label fixes (FaceAlpha always
%      present, one value per face).
%
%      info: a structure with
%           Source: 'mesh file' (returned as saved), 'stage-1 mesh with
%               the saved edits', or 'mesh file (no stage-1 cache)' (edits
%               newer than the mesh file, but no cache to apply them to:
%               the mesh file is returned and a warning is given)
%           NumEdits: the number of label fixes in the labelEdits file (0
%               when there is none)
%           EditsFile, MeshFile: the files used
%           NumFacesTurned: the faces fcn_CarMesh3D_orientFaces turned (0
%               with FlagOrientFaces=false)
%           NumFlipsTurned: the faces turned to their saved directions
%               (0 with FlagFaceFlips=false or no faceFlips file)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_editLabels,
%      fcn_CarMesh3D_findLampCovers, fcn_CarMesh3D_orientFaces,
%      fcn_CarMesh3D_lampFunctions, fcn_CarMesh3D_applyFaceFlips,
%      fcn_CarMesh3D_plotVehicle (plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_meshWithLabelEdits.m
%       for a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshWithLabelEdits
%   % * First write (Q32 (A), Sean 01:55): replaces the hidden painters
%   %   % that fcn_CarMesh3D_animateChecks and fcn_CarMesh3D_reviewVehicle
%   %   % built to get the mesh with its saved label fixes
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshWithLabelEdits
%   % * OrientFaces (default true; Q87 (A), Sean 03:16): the faces turned to
%   %   % agree with their neighbors (fcn_CarMesh3D_orientFaces), so every
%   %   % viewer, the painter, the V&V and the Animator's detail levels get
%   %   % it for every vehicle, with no files rebuilt (the Fit's white
%   %   % slivers at the driver door handle, Q86 (A))
%   % * LampFunctions (default true): the vehicle's lamp-to-function
%   %   % matrix added to the mesh (the lamp-functions plan, item 4)
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshWithLabelEdits
%   % * FlagFaceFlips (default true): the faces saved in the vehicle's
%   %   % faceFlips file are turned to their saved directions, after
%   %   % orientFaces (step 1F of the plan of 2026-11-27)

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
    options.FlagAlways = false      % Apply the fixes to the stage-1 mesh even when the mesh file is newer
    options.FlagOrientFaces = true  % Turn faces to agree with their neighbors (fcn_CarMesh3D_orientFaces)
    options.FlagLampFunctions = true % Add the vehicle's lamp-to-function matrix (field LampFunctions)
    options.FlagFaceFlips = true    % Turn the faces saved in the vehicle's faceFlips file to their saved directions
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
        if ~(ischar(vehicleInput) || (isstring(vehicleInput) && isscalar(vehicleInput)))
            error('vehicleInput must be a vehicle ID or folder (text)');
        end
        % Check the Always input
        if ~(islogical(options.FlagAlways) || isnumeric(options.FlagAlways)) || ~isscalar(options.FlagAlways)
            error('Always must be true or false');
        end
        % Check the OrientFaces input
        if ~(islogical(options.FlagOrientFaces) || isnumeric(options.FlagOrientFaces)) || ~isscalar(options.FlagOrientFaces)
            error('OrientFaces must be true or false');
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

vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
stage1File = fullfile(vehicleFiles.Folder, 'cache', 'stage1_mesh.mat');

info = struct('Source', 'mesh file', 'NumEdits', 0, 'EditsFile', '', 'MeshFile', vehicleFiles.MeshFile, ...
    'NumFacesTurned', 0, 'NumFlipsTurned', 0);

% The saved label fixes, if any
edits = {};
if isfile(editsFile)
    loaded = load(editsFile, 'labelEditsAfterSimplify');
    if isfield(loaded, 'labelEditsAfterSimplify')
        edits = loaded.labelEditsAfterSimplify;
    end
    info.EditsFile = editsFile;
    info.NumEdits = numel(edits);
end

% Are the fixes newer than the mesh file?
flagEditsNewer = false;
if ~isempty(edits) && isfile(vehicleFiles.MeshFile)
    editsDate = dir(editsFile);
    meshDate = dir(vehicleFiles.MeshFile);
    flagEditsNewer = editsDate.datenum > meshDate.datenum;
end

vehicleMesh = [];
if ~isempty(edits) && (flagEditsNewer || options.FlagAlways)
    if isfile(stage1File)
        stage1 = load(stage1File, 'cacheOutputs');
        if isfield(stage1, 'cacheOutputs') && isfield(stage1.cacheOutputs, 'vehicleMesh')
            % (the script's step 5: the saved fixes, then the clear covers)
            vehicleMesh = fcn_CarMesh3D_editLabels(stage1.cacheOutputs.vehicleMesh, Edits=edits, FigNum=-1);
            vehicleMesh = fcn_CarMesh3D_findLampCovers(vehicleMesh, FigNum=-1);
            info.Source = 'stage-1 mesh with the saved edits';
        end
    end
    if isempty(vehicleMesh)
        info.Source = 'mesh file (no stage-1 cache)';
        warning('CarMesh3D:noStage1Cache', ['%s: label fixes were saved after the mesh file was made, but there is ' ...
            'no stage-1 cache to apply them to. The mesh file is used; run the vehicle''s script to include the fixes.'], ...
            vehicleFiles.Name);
    end
end
if isempty(vehicleMesh)
    loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
    vehicleMesh = loaded.vehicleMesh;
end
if ~isfield(vehicleMesh, 'FaceAlpha') || numel(vehicleMesh.FaceAlpha) ~= size(vehicleMesh.Faces,1)
    vehicleMesh.FaceAlpha = ones(size(vehicleMesh.Faces,1),1);
end

% Faces turned to point the same way as their neighbors (a few
% hundredths of a second)
if options.FlagOrientFaces
    [vehicleMesh, orientInfo] = fcn_CarMesh3D_orientFaces(vehicleMesh, FigNum=-1);
    info.NumFacesTurned = orientInfo.NumFlipped;
end

% The faces turned by hand in the face-direction window, to the way they
% were saved (after orientFaces, which could turn them back; step 1F)
flipsFile = fullfile(vehicleFiles.Folder, sprintf('faceFlips_%s.mat', vehicleFiles.ID));
if options.FlagFaceFlips && isfile(flipsFile)
    [vehicleMesh, flipsInfo] = fcn_CarMesh3D_applyFaceFlips(vehicleMesh, flipsFile, FigNum=-1);
    info.NumFlipsTurned = flipsInfo.NumTurned;
end

% The vehicle's lamp-to-function matrix, on the mesh (its file, else the
% defaults; a few hundredths of a second)
if options.FlagLampFunctions && isfield(vehicleMesh, 'LabelFaceLamp') && isfield(vehicleMesh, 'LabelLampNames')
    vehicleMesh.LampFunctions = fcn_CarMesh3D_lampFunctions(vehicleFiles.Folder, Mesh=vehicleMesh, FigNum=-1);
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
    fcn_CarMesh3D_plotVehicle(vehicleMesh, AxesHandle=gca);
    axis equal; view(-40, 20);
    title(sprintf('%s: %s, %d label fixes', vehicleFiles.Name, info.Source, info.NumEdits), 'Interpreter', 'none');
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
