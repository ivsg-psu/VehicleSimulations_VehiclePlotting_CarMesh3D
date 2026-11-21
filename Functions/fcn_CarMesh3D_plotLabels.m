function labelMesh = fcn_CarMesh3D_plotLabels(vehicleMesh, options)
% fcn_CarMesh3D_plotLabels

% Colors a finished mesh by its labels (each part and light type in its
% own color) and plots it in one 3D view that can be rotated and zoomed
% with the mouse: the interactive version of the check_03_labels.png
% picture, for reviewing a vehicle's labels in MATLAB.
%
% The colors are:
%   body light gray, glass light blue (partly see-through), wheels black,
%   trim dark gray, a light with no type magenta; and, by light type,
%   headlight yellow, turn signal orange, running cyan, tail red, backup
%   green.
%
% FORMAT:
%
%       labelMesh = fcn_CarMesh3D_plotLabels(vehicleMesh,...
%           (Title=text), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh (PartNames, FacePartIndex;
%      FaceLightType and LightTypeNames if it has lights).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Title: the figure's title (for example, the vehicle's name).
%      Default: the mesh's Name, if it has one.
%
%      FigNum: a figure to plot into. The figure is cleared, made visible,
%      and left open: drag to rotate the view, scroll to zoom. If empty or omitted, no
%      plot is made. If set to -1, input checking is skipped and no plot
%      is made (fast mode): only labelMesh is returned.
%
% OUTPUTS:
%
%      labelMesh: the mesh with FaceColors set to the label colors and
%      FaceAlpha set to 1 (0.6 for glass), ready for
%      fcn_CarMesh3D_plotVehicle.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle
%
% EXAMPLES:
%
%       vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
%       load(vehicleFiles.MeshFile, 'vehicleMesh');
%       fcn_CarMesh3D_plotLabels(vehicleMesh, Title='2013 Toyota Prius', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_plotLabels.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * First write: the label colors (moved here from
%   %   % fcn_CarMesh3D_runVehicleChecks) and an open, rotatable figure
%   %   % for reviewing labels (PNG pictures are hard to zoom into)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.Title = ''      % The figure's title; '' for the mesh's Name
    options.FigNum = []     % Figure to plot into; [] for no plot, -1 for fast mode
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

        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces','PartNames','FacePartIndex'})))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, PartNames, FacePartIndex)');
        end
        if ~(ischar(options.Title) || isstring(options.Title))
            error('Title must be text');
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

% The label colors: one per part, then one per light type (over the part)
partColors = struct('body',[0.80 0.80 0.80], 'glass',[0.55 0.80 1.00], 'wheel',[0.10 0.10 0.10], ...
    'light',[1.00 0.00 1.00], 'trim',[0.45 0.45 0.45]);
lightColors = struct('headlight',[1.00 0.90 0.10], 'turnsignal',[1.00 0.50 0.00], 'running',[0.00 0.90 0.90], ...
    'tail',[0.90 0.00 0.00], 'backup',[0.10 0.75 0.10]);

Nfaces = size(vehicleMesh.Faces,1);
labelMesh = vehicleMesh;
faceColors = zeros(Nfaces,3);
for ith_part = 1:length(vehicleMesh.PartNames)
    thisName = vehicleMesh.PartNames{ith_part};
    if isfield(partColors, thisName)
        flagPart = vehicleMesh.FacePartIndex==ith_part;
        faceColors(flagPart,:) = repmat(partColors.(thisName), sum(flagPart), 1);
    end
end
if isfield(vehicleMesh,'FaceLightType') && isfield(vehicleMesh,'LightTypeNames')
    for ith_type = 1:length(vehicleMesh.LightTypeNames)
        thisName = vehicleMesh.LightTypeNames{ith_type};
        flagType = vehicleMesh.FaceLightType==ith_type;
        if isfield(lightColors, thisName)
            faceColors(flagType,:) = repmat(lightColors.(thisName), sum(flagType), 1);
        end
    end
end
labelMesh.FaceColors = faceColors;
labelMesh.FaceAlpha = ones(Nfaces,1);
glassIndex = find(strcmp(vehicleMesh.PartNames,'glass'));
labelMesh.FaceAlpha(vehicleMesh.FacePartIndex==glassIndex) = 0.6;

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
    figureHandle = figure(figNum);
    clf(figureHandle);
    set(figureHandle, 'Visible','on', 'Color',[1 1 1]);
    titleText = char(options.Title);
    if isempty(titleText) && isfield(vehicleMesh,'Name')
        titleText = char(vehicleMesh.Name);
    end
    if ~isempty(titleText)
        set(figureHandle, 'Name',sprintf('%s: labels', titleText), 'NumberTitle','off');
    end

    axesHandle = axes('Parent',figureHandle, 'Position',[0.02 0.10 0.96 0.82]);
    fcn_CarMesh3D_plotVehicle(labelMesh, Finish='matte', FigNum=figNum);
    axis(axesHandle,'equal');
    axis(axesHandle,'vis3d');
    axis(axesHandle,'off');
    view(axesHandle, -55, 20);
    title(axesHandle, sprintf('%s: part and light labels', titleText), 'Interpreter','none');
    annotation(figureHandle, 'textbox', [0 0.01 1 0.06], 'EdgeColor','none', 'HorizontalAlignment','center', ...
        'FontSize',9, 'String',['body light gray | glass light blue | wheels black | trim dark gray | light with no type magenta | ' ...
        'headlight yellow | turn signal orange | running cyan | tail red | backup green   (drag to rotate; scroll to zoom)']);
    enableDefaultInteractivity(axesHandle);   % (drag rotates a 3D view; scroll zooms)
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
