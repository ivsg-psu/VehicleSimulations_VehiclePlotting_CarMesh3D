function vehicleOutline = fcn_CarMesh3D_loadOutline2D(vehicleID, options)
% fcn_CarMesh3D_loadOutline2D

% Loads a vehicle's top-down (2D) outlines from its folder in Data:
% vehicleOutline_<ID>.mat, made by the vehicle's script with
% fcn_CarMesh3D_makeOutline2D. This is how a 2D plotting tool gets them.
%
% If the vehicle has a finished mesh but no outline file yet (a vehicle
% finished before outlines existed), the outlines are made from its mesh,
% with a warning (ID 'CarMesh3D:outlineMade'), so that it still works;
% they are saved only if SaveIfMade is true. An outline file older than
% the finished mesh also gives a warning ('CarMesh3D:oldOutline'): run
% the vehicle's script again.
%
% FORMAT:
%
%       vehicleOutline = fcn_CarMesh3D_loadOutline2D(vehicleID,...
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
%      MakeIfMissing: make the outlines from the finished mesh when there
%      is no outline file. Default true.
%
%      SaveIfMade: save outlines made that way to the vehicle's folder.
%      Default false.
%
%      FigNum: a figure to show the outlines, filled, in 2D. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleOutline: the outlines (see fcn_CarMesh3D_makeOutline2D),
%      with VehicleID and Origin ('file' or 'made') added.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_makeOutline2D
%
% EXAMPLES:
%
%       vehicleOutline = fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_loadOutline2D.m for a
%       full test suite.
%
% This function was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadOutline2D
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadOutline2D
%   % * The 'outline made' warning comes after the outlines are made (a
%   %   % symmetry warning from makeOutline2D had come after it)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadOutline2D
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleID
    options.DataFolder = []           % the Data folder; [] for the one next to Functions
    options.MakeIfMissing = true      % make the outlines if there is no outline file
    options.SaveIfMade = false        % save outlines made that way
    options.FigNum = []               % figure to show the outlines; -1 for fast mode
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


        if ~(ischar(vehicleID) || isstring(vehicleID)) || isempty(char(vehicleID))
            error('vehicleID must be a vehicle ID, such as ''2013_Toyota_Prius_Four''');
        end
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
if vehicleFiles.HasOutline
    loaded = load(vehicleFiles.OutlineFile, 'vehicleOutline');
    if ~isfield(loaded, 'vehicleOutline')
        error('%s has no variable vehicleOutline', vehicleFiles.OutlineFile);
    end
    vehicleOutline = loaded.vehicleOutline;
    vehicleOutline.Origin = 'file';
    if vehicleFiles.HasMesh
        meshInfo = dir(vehicleFiles.MeshFile);
        outlineInfo = dir(vehicleFiles.OutlineFile);
        if meshInfo.datenum > outlineInfo.datenum + 1/86400
            warning('CarMesh3D:oldOutline', ['The outlines of %s are older than its finished mesh. ' ...
                'Run %s again to remake them.'], vehicleFiles.ID, vehicleFiles.ScriptFile);
        end
    end
elseif options.MakeIfMissing && vehicleFiles.HasMesh
    loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
    vehicleOutline = fcn_CarMesh3D_makeOutline2D(loaded.vehicleMesh, FigNum=-1);
    % (warned after the outlines are made, so it is the last word, after
    % any warning of makeOutline2D's own)
    warning('CarMesh3D:outlineMade', ['%s has no outline file; the outlines were made from its finished mesh ' ...
        '(run its script to make and save them).'], vehicleFiles.ID);
    if options.SaveIfMade
        save(vehicleFiles.OutlineFile, 'vehicleOutline');
    end
    vehicleOutline.Origin = 'made';
elseif ~vehicleFiles.HasMesh
    error('%s has no finished mesh (%s). Run its script first.', vehicleFiles.ID, vehicleFiles.MeshFile);
else
    error('%s has no outline file (%s).', vehicleFiles.ID, vehicleFiles.OutlineFile);
end
vehicleOutline.VehicleID = vehicleFiles.ID;

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

    % The outlines alone, filled, as a 2D plot would draw them
    figure(figNum);
    clf;
    hold on;
    fill(vehicleOutline.Body(:,1), vehicleOutline.Body(:,2), [0.05 0.20 0.60], 'EdgeColor','none');
    for ith_window = 1:numel(vehicleOutline.Windows)
        thisPolygon = vehicleOutline.Windows(ith_window).Polygon;
        fill(thisPolygon(:,1), thisPolygon(:,2), [0.30 0.33 0.38], 'EdgeColor','none');
    end
    for ith_wheel = 1:numel(vehicleOutline.Wheels)
        corners = vehicleOutline.Wheels(ith_wheel).Rectangle + vehicleOutline.Wheels(ith_wheel).Center;
        fill(corners(:,1), corners(:,2), [0.05 0.05 0.05], 'EdgeColor','none');
    end
    for ith_light = 1:numel(vehicleOutline.Lights)
        thisLight = vehicleOutline.Lights(ith_light);
        lightColor = [0.85 0.80 0.55];
        if any(strcmp(thisLight.Type, {'tailBrakeLamp'}))
            lightColor = [0.80 0.05 0.05];
        elseif strcmp(thisLight.Type, 'turnSignalLamp')
            lightColor = [0.95 0.55 0.05];
        end
        fill(thisLight.Polygon(:,1), thisLight.Polygon(:,2), lightColor, 'EdgeColor','none');
    end
    axis equal;
    grid on;
    xlabel('X [m] (forward)');
    ylabel('Y [m] (left)');
    title(sprintf('%s (%s)', vehicleOutline.Name, vehicleOutline.Origin), 'Interpreter','none');
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


