function [visibleMesh, flagShown] = fcn_CarMesh3D_visibleMesh(vehicleMesh, options)
% fcn_CarMesh3D_visibleMesh

% The vehicle as it is shown: the mesh without its hidden faces. A face
% can be hidden (FaceHiddenSet > 0, in a named set: HiddenSetNames) to
% keep a piece of the download that should not be seen, such as a hard
% top taken off, a rear wiper, or a part of the download not wanted,
% without deleting it: the finished mesh keeps every face, so the
% animator can show a set again by name (fcn_CarMesh3D_plotVehicle's
% ShowHidden), and nothing downstream has a hole. Functions that
% measure the vehicle (dimensions, outlines, detail levels, ground
% contact) use the visible mesh, so hidden faces never count in them.
%
% The visible mesh has only the shown faces, every per-face field cut to
% match, and only the vertices those faces use (renumbered). A mesh
% with no hidden faces comes back as it is.
%
% FORMAT:
%
%       [visibleMesh, flagShown] = fcn_CarMesh3D_visibleMesh(vehicleMesh,...
%           (ShowSets=setNames), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh (Vertices, Faces, and the per-face
%      fields), with or without FaceHiddenSet.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      ShowSets: hidden sets to show anyway, by name (a cell array, such
%      as {'hard top'}), or true for all of them. Default {} (none).
%
%      FigNum: a figure to show the visible mesh (gray) and the hidden
%      faces (red). If empty or omitted, no plot is made. If set to -1,
%      input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      visibleMesh: the mesh with the hidden faces taken out.
%
%      flagShown: one flag per face of vehicleMesh: true for the faces
%      kept.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       visibleMesh = fcn_CarMesh3D_visibleMesh(vehicleMesh);
%       withTop = fcn_CarMesh3D_visibleMesh(vehicleMesh, ShowSets={'hard top'});
%
%       See the script: script_test_fcn_CarMesh3D_visibleMesh.m for a
%       full test suite.
%
% This function was written on 2026_11_23 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_visibleMesh
%   % * Wrote the code originally (drafted with Claude), for hidden faces
%   %   % (Sean, 04:07 to 04:21: hide, not delete)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_visibleMesh
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.ShowSets = {}            % hidden sets to show anyway (names), or true for all
    options.FigNum = []               % figure to show the result; -1 for fast mode
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


        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces')
            error('vehicleMesh must be a CarMesh3D mesh, with Vertices and Faces');
        end
        if ~(iscell(options.ShowSets) || ischar(options.ShowSets) || isstring(options.ShowSets) || islogical(options.ShowSets))
            error('ShowSets must be a cell array of hidden set names, or true for all');
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


numFaces = size(vehicleMesh.Faces,1);
flagShown = true(numFaces,1);
if isfield(vehicleMesh,'FaceHiddenSet') && numel(vehicleMesh.FaceHiddenSet) == numFaces
    hiddenSet = double(vehicleMesh.FaceHiddenSet(:));
    flagShown = hiddenSet == 0;
    if islogical(options.ShowSets) && isscalar(options.ShowSets) && options.ShowSets
        flagShown(:) = true;
    elseif ~islogical(options.ShowSets) && isfield(vehicleMesh,'HiddenSetNames')
        showNames = cellstr(options.ShowSets);
        showIndices = find(ismember(cellstr(vehicleMesh.HiddenSetNames), showNames));
        flagShown = flagShown | ismember(hiddenSet, showIndices);
    end
end
if all(flagShown)
    visibleMesh = vehicleMesh;
else
    visibleMesh = fcn_INTERNAL_keepFaces(vehicleMesh, flagShown);
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
    figure(figNum);
    clf;
    hold on;
    patch('Faces',vehicleMesh.Faces(flagShown,:), 'Vertices',vehicleMesh.Vertices, ...
        'FaceColor',[0.75 0.75 0.78], 'EdgeColor','none', 'DisplayName','shown');
    if any(~flagShown)
        patch('Faces',vehicleMesh.Faces(~flagShown,:), 'Vertices',vehicleMesh.Vertices, ...
            'FaceColor',[0.90 0.10 0.10], 'FaceAlpha',0.5, 'EdgeColor','none', 'DisplayName','hidden');
    end
    axis equal;
    grid on;
    view(-40, 20);
    camlight headlight;
    legend('Location','best');
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(sprintf('%d faces shown, %d hidden', nnz(flagShown), nnz(~flagShown)));
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




%% fcn_INTERNAL_keepFaces
function keptMesh = fcn_INTERNAL_keepFaces(vehicleMesh, flagKeep)
% The mesh with only the kept faces: every per-face field (any field
% with one row per face) cut to match, and only the vertices those
% faces use (renumbered), with any per-vertex field
numFaces = size(vehicleMesh.Faces,1);
numVertices = size(vehicleMesh.Vertices,1);
keptMesh = vehicleMesh;
fieldList = fieldnames(vehicleMesh);
for ith_field = 1:numel(fieldList)
    name = fieldList{ith_field};
    value = vehicleMesh.(name);
    if strcmp(name, 'Vertices') || ~(isnumeric(value) || islogical(value) || iscell(value) || isstring(value))
        continue;
    end
    if size(value,1) == numFaces && numFaces > 1
        keptMesh.(name) = value(flagKeep,:);
    end
end
used = unique(keptMesh.Faces(:));
newNumber = zeros(numVertices,1);
newNumber(used) = 1:numel(used);
for ith_field = 1:numel(fieldList)
    name = fieldList{ith_field};
    value = vehicleMesh.(name);
    if ~strcmp(name, 'Faces') && (isnumeric(value) || islogical(value)) && size(value,1) == numVertices && numVertices > 1
        keptMesh.(name) = value(used,:);   % (per-vertex fields, such as normals)
    end
end
keptMesh.Faces = reshape(newNumber(keptMesh.Faces), [], 3);
end % Ends fcn_INTERNAL_keepFaces
