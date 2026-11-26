function detailLevels = fcn_CarMesh3D_loadDetailLevels(vehicleID, options)
% fcn_CarMesh3D_loadDetailLevels

% Loads a vehicle's detail levels (the ladder of lighter versions of its
% mesh, for animation) from its folder in Data: vehicleLevels_<ID>.mat,
% made by the vehicle's script with fcn_CarMesh3D_makeDetailLevels. This
% is how an animation (AnimateCar3D) gets them.
%
% If the vehicle has a finished mesh but no levels file yet (a vehicle
% finished before detail levels existed), the levels are made from its
% mesh, with a warning, so that it still works; they are saved only if
% SaveIfMade is true. A levels file made from an older finished mesh
% (the mesh file is newer) also gives a warning: run the vehicle's script
% again.
%
% FORMAT:
%
%       detailLevels = fcn_CarMesh3D_loadDetailLevels(vehicleID,...
%           (DataFolder=folder), (MakeIfMissing=flag), (SaveIfMade=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleID: the vehicle ID, such as '2013_Toyota_Prius_Four' (see
%      fcn_CarMesh3D_findVehicleFiles).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      MakeIfMissing: make the levels from the finished mesh if there is
%      no levels file. Default true. (False: an error.)
%
%      SaveIfMade: save the levels made that way to the vehicle's folder.
%      Default false.
%
%      FigNum: a figure number to show the levels (as
%      fcn_CarMesh3D_makeDetailLevels does). Empty (default) for no
%      figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      detailLevels: the structure from fcn_CarMesh3D_makeDetailLevels
%      (Levels, SizeDiagonal, BoxCenter, BoxSize, ShadowArea, ...), plus
%      VehicleID and Source ('file'; 'made' when made because the file
%      was missing; 'remade' when the file was older than the finished
%      mesh or the vehicle's saved label fixes, so the levels were made
%      again from the mesh with its fixes). Levels are always made from
%      fcn_CarMesh3D_meshWithLabelEdits, so painted fixes made since the
%      last build show (AnimateCar3D, 2026-11-25: Sean's "flow" of
%      vehicles out of CarMesh3D into the animator).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_makeDetailLevels,
%      fcn_CarMesh3D_meshWithLabelEdits
%
% EXAMPLES:
%
%       detailLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four');
%       topMesh = detailLevels.Levels(1).Mesh;
%
%       See the script: script_test_fcn_CarMesh3D_loadDetailLevels.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadDetailLevels
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_loadDetailLevels
%   % * Levels older than the mesh or its saved label fixes are made
%   %   % again (Source 'remade'), not only warned about; levels are made
%   %   % from the mesh with its fixes (fcn_CarMesh3D_meshWithLabelEdits),
%   %   % so AnimateCar3D shows painted fixes (Sean, Q73 (B))

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadDetailLevels
%   % * (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleID
    options.DataFolder = []           % the Data folder; [] for the one next to Functions
    options.MakeIfMissing = true      % make the levels if there is no levels file
    options.SaveIfMade = false        % save levels made that way
    options.FigNum = []               % figure to show the levels; -1 for fast mode
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


        % Check the vehicleID input
        if ~(ischar(vehicleID) || isstring(vehicleID)) || isempty(char(vehicleID))
            error('vehicleID must be a vehicle ID, such as ''2013_Toyota_Prius_Four''');
        end

        % Check the flags
        if ~isscalar(options.MakeIfMissing) || ~isscalar(options.SaveIfMade)
            error('MakeIfMissing and SaveIfMade must be true or false');
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


vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleID), DataFolder=options.DataFolder, FigNum=-1);
if vehicleFiles.HasLevels
    loaded = load(vehicleFiles.LevelsFile, 'detailLevels');
    if ~isfield(loaded, 'detailLevels')
        error('%s has no variable detailLevels', vehicleFiles.LevelsFile);
    end
    detailLevels = loaded.detailLevels;
    if ~isfield(detailLevels,'FormatVersion') || detailLevels.FormatVersion ~= 1
        error('%s was made in a format this version of CarMesh3D does not read. Run the vehicle''s script again.', ...
            vehicleFiles.LevelsFile);
    end
    detailLevels.Source = 'file';
    if vehicleFiles.HasMesh
        % (older than the finished mesh, or than the saved label fixes: made
        % again from the mesh with its fixes, so what is drawn is current)
        levelsInfo = dir(vehicleFiles.LevelsFile);
        newerFiles = {vehicleFiles.MeshFile, fcn_INTERNAL_editsFile(vehicleFiles)};
        flagStale = false;
        for ith_file = 1:numel(newerFiles)
            fileInfo = dir(newerFiles{ith_file});
            if ~isempty(fileInfo) && fileInfo.datenum > levelsInfo.datenum + 1/86400
                flagStale = true;
            end
        end
        if flagStale
            warning('CarMesh3D:oldDetailLevels', ['The detail levels of %s are older than its finished mesh or ' ...
                'its label fixes; making them again (run %s to save them).'], vehicleFiles.ID, vehicleFiles.ScriptFile);
            detailLevels = fcn_CarMesh3D_makeDetailLevels(fcn_INTERNAL_currentMesh(vehicleFiles), FigNum=-1);
            detailLevels.Source = 'remade';
            if options.SaveIfMade
                save(vehicleFiles.LevelsFile, 'detailLevels');
            end
        end
    end
elseif options.MakeIfMissing && vehicleFiles.HasMesh
    warning('CarMesh3D:detailLevelsMade', ['%s has no detail levels file; making them from its finished mesh ' ...
        '(run its script to make and save them).'], vehicleFiles.ID);
    detailLevels = fcn_CarMesh3D_makeDetailLevels(fcn_INTERNAL_currentMesh(vehicleFiles), FigNum=-1);
    detailLevels.Source = 'made';
    if options.SaveIfMade
        save(vehicleFiles.LevelsFile, 'detailLevels');
    end
elseif ~vehicleFiles.HasMesh
    error('%s has no finished mesh (%s). Run its script first.', vehicleFiles.ID, vehicleFiles.MeshFile);
else
    error('%s has no detail levels file (%s).', vehicleFiles.ID, vehicleFiles.LevelsFile);
end
detailLevels.VehicleID = vehicleFiles.ID;

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

    loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
    figure(figNum);
    clf;
    fcn_CarMesh3D_plotVehicle(loaded.vehicleMesh, FigNum=figNum);
    hold on;
    spacing = 1.25*detailLevels.BoxSize(2);
    for ith_level = 1:numel(detailLevels.Levels)
        thisLevel = detailLevels.Levels(ith_level);
        if ~thisLevel.IsBox
            fcn_CarMesh3D_plotVehicle(thisLevel.Mesh, Pose=[0 -ith_level*spacing 0], FigNum=figNum);
        end
    end
    view(-60, 25);
    title(sprintf('%s: finished mesh and %d detail levels (from %s)', detailLevels.VehicleID, ...
        numel(detailLevels.Levels), detailLevels.Source), 'Interpreter','none');
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

% (none)

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_editsFile
function editsFile = fcn_INTERNAL_editsFile(vehicleFiles)
% The vehicle's saved label fixes (painted in fcn_CarMesh3D_paintLabels)
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
end % Ends fcn_INTERNAL_editsFile

%% fcn_INTERNAL_currentMesh
function vehicleMesh = fcn_INTERNAL_currentMesh(vehicleFiles)
% The finished mesh with its saved label fixes
vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleFiles.Folder, FigNum=-1);
end % Ends fcn_INTERNAL_currentMesh
