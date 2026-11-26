function report = fcn_CarMesh3D_checkHiddenFaces(vehicleMesh, vehicleSpec, options)
% fcn_CarMesh3D_checkHiddenFaces

% Warns about hidden faces (LabelFaceHiddenSet, in named sets: see
% fcn_CarMesh3D_editLabels's Hide) that could mislead. The checks and
% outlines measure the vehicle as it is shown (fcn_CarMesh3D_visibleMesh),
% which is right for a vehicle shown that way (a coupe with its hard top
% off), but hidden faces are still in the mesh, so three things are
% worth knowing:
%
%   1. Many hidden faces: more than ManyFraction of the faces (default
%      10%) are hidden.
%   2. Hidden faces change a dimension: a dimension measured with the
%      hidden faces differs from the one measured on the shown faces by
%      more than Tolerance (default 1 cm). Both are given, for example a
%      hidden muffler that hangs lower than the body: the ground
%      clearance with it is smaller.
%   3. Hidden faces outside the shown vehicle's bounding box, by more
%      than Tolerance: each set, the side (front, rear, left, right, top,
%      bottom), and how far. Collision checks use a vehicle's bounding
%      box: if the box were taken from all the mesh's vertices, a hidden
%      piece (a hard top taken off, say) would make collisions with
%      something nobody can see, which is very hard to debug. Take the
%      box from the shown faces (fcn_CarMesh3D_visibleMesh), or keep
%      hidden pieces inside the shown vehicle.
%
% Each finding is printed as a warning (IDs CarMesh3D:hiddenMany,
% CarMesh3D:hiddenChangesDimension, CarMesh3D:hiddenOutsideBox) unless
% FlagVerbose is false, and is returned in the report.
%
% FORMAT:
%
%       report = fcn_CarMesh3D_checkHiddenFaces(vehicleMesh, vehicleSpec,...
%           (Tolerance=meters), (ManyFraction=fraction), (FlagVerbose=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh, with or without hidden faces.
%
%      vehicleSpec: the vehicle's parameters (fcn_CarMesh3D_loadVehicleSpec),
%      for the dimensions (fcn_CarMesh3D_validateMesh); [] to skip the
%      dimensions.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tolerance: how much a dimension may change, or a hidden face reach
%      past the shown vehicle, before it is reported [m]. Default 0.01.
%
%      ManyFraction: the share of faces hidden above which it is
%      reported. Default 0.10.
%
%      FlagVerbose: false to return the report without printing warnings.
%      Default true.
%
%      FigNum: a figure to show the shown faces (gray), the hidden faces
%      (red), and the shown vehicle's bounding box (blue). If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      report: a structure with
%           NumHidden, NumFaces, HiddenFraction
%           Sets: a table (Name, Faces) of the hidden sets
%           Dimensions: a table (Quantity, Shown_m, WithHidden_m,
%               Difference_m) of the dimensions the hidden faces change
%           OutsideBox: a table (Set, Side, Distance_m) of the hidden
%               sets reaching past the shown vehicle's bounding box
%           ShownBox, FullBox: [xmin ymin zmin; xmax ymax zmax] of the
%               shown faces, and of every face
%           Messages: the findings, as text (a cell array)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_visibleMesh, fcn_CarMesh3D_validateMesh
%
% EXAMPLES:
%
%       report = fcn_CarMesh3D_checkHiddenFaces(vehicleMesh, vehicleSpec);
%
%       See the script: script_test_fcn_CarMesh3D_checkHiddenFaces.m for a
%       full test suite.
%
% This function was written on 2026_11_23 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkHiddenFaces
%   % * Wrote the code originally (drafted with Claude): the warnings
%   %   % Sean asked for (04:17) about hidden faces

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkHiddenFaces
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    vehicleSpec
    options.Tolerance = 0.01          % [m] how much a dimension may change, or a hidden face reach out
    options.ManyFraction = 0.10       % share of faces hidden above which it is reported
    options.FlagVerbose = true              % false: no warnings printed (the report only)
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
        if ~isempty(vehicleSpec) && ~isstruct(vehicleSpec)
            error('vehicleSpec must be the vehicle''s parameters (a structure), or []');
        end
        if ~isnumeric(options.Tolerance) || ~isscalar(options.Tolerance) || options.Tolerance < 0
            error('Tolerance must be a distance in meters, 0 or more');
        end
        if ~isnumeric(options.ManyFraction) || ~isscalar(options.ManyFraction) || options.ManyFraction < 0 || options.ManyFraction > 1
            error('ManyFraction must be between 0 and 1');
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


[shownMesh, flagShown] = fcn_CarMesh3D_visibleMesh(vehicleMesh, FigNum=-1);
numFaces = size(vehicleMesh.Faces,1);
report = struct;
report.NumFaces = numFaces;
report.NumHidden = nnz(~flagShown);
report.HiddenFraction = report.NumHidden/max(numFaces,1);
report.Sets = table(strings(0,1), zeros(0,1), 'VariableNames', {'Name','Faces'});
report.Dimensions = table(strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    'VariableNames', {'Quantity','Shown_m','WithHidden_m','Difference_m'});
report.OutsideBox = table(strings(0,1), strings(0,1), zeros(0,1), 'VariableNames', {'Set','Side','Distance_m'});
report.ShownBox = [min(shownMesh.Vertices,[],1); max(shownMesh.Vertices,[],1)];
usedVertices = vehicleMesh.Vertices(unique(vehicleMesh.Faces(:)),:);
report.FullBox = [min(usedVertices,[],1); max(usedVertices,[],1)];
report.Messages = {};

if report.NumHidden > 0
    faceSet = double(vehicleMesh.LabelFaceHiddenSet(:));
    setNames = reshape(cellstr(vehicleMesh.LabelHiddenSetNames), [], 1);
    for ith_set = 1:numel(setNames)
        report.Sets(end+1,:) = {string(setNames{ith_set}), nnz(faceSet==ith_set)};
    end

    % 1. Many hidden faces
    if report.HiddenFraction > options.ManyFraction
        report.Messages{end+1} = sprintf(['%d of %d faces (%.0f%%) are hidden (sets: %s). Hidden faces stay in the ' ...
            'mesh: check they are meant to be there.'], report.NumHidden, numFaces, 100*report.HiddenFraction, ...
            fcn_INTERNAL_setList(report.Sets));
        fcn_INTERNAL_warn(~options.FlagVerbose, 'CarMesh3D:hiddenMany', report.Messages{end});
    end

    % 2. Dimensions the hidden faces change
    if ~isempty(vehicleSpec)
        warningState = warning('off', 'all');
        shownTable = fcn_CarMesh3D_validateMesh(shownMesh, vehicleSpec, FigNum=-1);
        fullMesh = vehicleMesh;
        fullMesh.LabelFaceHiddenSet(:) = 0;   % (every face, as if none were hidden)
        fullTable = fcn_CarMesh3D_validateMesh(fullMesh, vehicleSpec, FigNum=-1);
        warning(warningState);
        difference = fullTable.Measured_m - shownTable.Measured_m;
        changed = find(abs(difference) > options.Tolerance);
        for ith_row = changed(:)'
            report.Dimensions(end+1,:) = {shownTable.Quantity(ith_row), shownTable.Measured_m(ith_row), ...
                fullTable.Measured_m(ith_row), difference(ith_row)};
        end
        if ~isempty(changed)
            lines = arrayfun(@(k) sprintf('  %s: %.3f m shown; %.3f m with the hidden faces', ...
                shownTable.Quantity(k), shownTable.Measured_m(k), fullTable.Measured_m(k)), changed(:)', 'UniformOutput', false);
            report.Messages{end+1} = sprintf(['The hidden faces change %d dimension(s). The checks measure the vehicle as ' ...
                'shown; with the hidden faces (sets: %s), they would be:\n%s'], numel(changed), ...
                fcn_INTERNAL_setList(report.Sets), strjoin(lines, '\n'));
            fcn_INTERNAL_warn(~options.FlagVerbose, 'CarMesh3D:hiddenChangesDimension', report.Messages{end});
        end
    end

    % 3. Hidden faces outside the shown vehicle's bounding box
    sideNames = {'rear','right','bottom'; 'front','left','top'};
    outsideLines = {};
    for ith_set = 1:numel(setNames)
        setFaces = vehicleMesh.Faces(faceSet==ith_set,:);
        if isempty(setFaces)
            continue;
        end
        setVertices = vehicleMesh.Vertices(unique(setFaces(:)),:);
        reachLow = report.ShownBox(1,:) - min(setVertices,[],1);    % (past the low side: + is outside)
        reachHigh = max(setVertices,[],1) - report.ShownBox(2,:);   % (past the high side)
        for ith_axis = 1:3
            reaches = [reachLow(ith_axis), reachHigh(ith_axis)];
            for ith_side = 1:2
                if reaches(ith_side) > options.Tolerance
                    report.OutsideBox(end+1,:) = {string(setNames{ith_set}), string(sideNames{ith_side,ith_axis}), reaches(ith_side)};
                    outsideLines{end+1} = sprintf('  ''%s'': %.3f m past the %s', setNames{ith_set}, ...
                        reaches(ith_side), sideNames{ith_side,ith_axis}); %#ok<AGROW>
                end
            end
        end
    end
    if ~isempty(outsideLines)
        report.Messages{end+1} = sprintf(['Hidden faces reach outside the shown vehicle''s bounding box:\n%s\n' ...
            'Collision checks use a vehicle''s bounding box. If it were taken from all the mesh''s vertices, these ' ...
            'hidden faces would make collisions with something nobody can see, which is very hard to debug. ' ...
            'Take the box from the shown faces (fcn_CarMesh3D_visibleMesh), or keep hidden pieces inside the ' ...
            'shown vehicle.'], strjoin(outsideLines, '\n'));
        fcn_INTERNAL_warn(~options.FlagVerbose, 'CarMesh3D:hiddenOutsideBox', report.Messages{end});
    end
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
            'FaceColor',[0.90 0.10 0.10], 'FaceAlpha',0.6, 'EdgeColor','none', 'DisplayName','hidden');
    end
    % (the shown vehicle's bounding box)
    boxLow = report.ShownBox(1,:);
    boxHigh = report.ShownBox(2,:);
    corners = [boxLow; boxHigh(1) boxLow(2:3); boxHigh(1:2) boxLow(3); boxLow(1) boxHigh(2) boxLow(3)];
    corners = [corners; corners(:,1:2) repmat(boxHigh(3),4,1)];
    edges = [1 2; 2 3; 3 4; 4 1; 5 6; 6 7; 7 8; 8 5; 1 5; 2 6; 3 7; 4 8];
    for ith_edge = 1:size(edges,1)
        plot3(corners(edges(ith_edge,:),1), corners(edges(ith_edge,:),2), corners(edges(ith_edge,:),3), ...
            'b-', 'LineWidth', 1, 'HandleVisibility', 'off');
    end
    axis equal;
    grid on;
    view(-40, 20);
    camlight headlight;
    legend('Location','best');
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title(sprintf('%d of %d faces hidden; blue: the shown vehicle''s bounding box', report.NumHidden, numFaces));
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




%% fcn_INTERNAL_setList
function textOut = fcn_INTERNAL_setList(setTable)
% The hidden sets, as text: 'hard top' (120 faces), ...
parts = arrayfun(@(k) sprintf('''%s'' (%d faces)', setTable.Name(k), setTable.Faces(k)), 1:height(setTable), ...
    'UniformOutput', false);
textOut = strjoin(parts, ', ');
end % Ends fcn_INTERNAL_setList

%% fcn_INTERNAL_warn
function fcn_INTERNAL_warn(flagQuiet, warningID, message)
if ~flagQuiet
    warning(warningID, '%s', message);
end
end % Ends fcn_INTERNAL_warn
