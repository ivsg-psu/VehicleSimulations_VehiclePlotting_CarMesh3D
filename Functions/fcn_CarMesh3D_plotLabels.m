function [labelMesh, legendEntries] = fcn_CarMesh3D_plotLabels(vehicleMesh, options)
% fcn_CarMesh3D_plotLabels

% Colors a finished mesh by its labels (each part and light type in its
% own color) and plots it in one 3D view that can be rotated and zoomed
% with the mouse: the interactive version of the check_03_labels.png
% picture, for reviewing a vehicle's labels in MATLAB.
%
% The colors are:
%   body light gray, glass light blue (partly see-through), wheels black,
%   trim dark gray, a light with no type magenta; and, by light type,
%   headlamp yellow, turn signal orange, running cyan, tail red, backup
%   green.
%
% With ColorBy='material', each face is colored by its MATERIAL instead
% (one distinct color per material name, with a legend of the names): the
% view for writing part rules, which match material and group names.
%
% FORMAT:
%
%       [labelMesh, legendEntries] = fcn_CarMesh3D_plotLabels(vehicleMesh,...
%           (Title=text), (ColorBy=mode), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh (LabelPartNames, LabelFacePart;
%      LabelFaceLamp and LabelLampNames if it has lights).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Title: the figure's title (for example, the vehicle's name).
%      Default: the mesh's Name, if it has one.
%
%      ColorBy: 'labels' (default) for the part and light-type colors
%      above, or 'material' for one color per material name (needs
%      MaterialNames and FaceMaterialIndex), with a legend.
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
%      legendEntries: the label colors this mesh uses, for a legend: a
%      structure array with Name (as a person reads it: 'turn signal'),
%      Color and Faces (how many faces show it), parts first, then lamp
%      types; empty with ColorBy='material'. Made in fast mode too.
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
%   % * ColorBy='material': one color per material, with a legend, for
%   %   % writing part rules (Sean, Q6)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * The 'interior' part (fcn_CarMesh3D_labelInterior) has its own
%   %   % color, tan (it was drawn black)

% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * A light that is also glass (LabelFaceAlsoParts, a lamp's clear cover)
%   %   % is drawn see-through, like the glass
%   % * The body's label color is near-white ([0.97 0.97 0.97], was
%   %   % [0.80 0.80 0.80]): the labels stand out against it (Sean, 00:05)

% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * A label color for the 'highBeamLamp' light type (blue) (Sean, 03:27)
%
% 2026_11_23 (task 8) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_plotLabels
%   % * Label colors for the newer lamp types (fog, reflector, licenseplate,
%   %   % marker, warning) from fcn_CarMesh3D_lampTypes (Sean, task 8)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_plotLabels
%   % * A second output, legendEntries: the label colors the mesh uses,
%   %   % for a legend in the V&V GUI's label pictures (Sean, T62)
%   % * The legend's lamp names come from fcn_CarMesh3D_lampTypes: what
%   %   % each lamp is, such as "headlamp" (rule P6, Sean 2026-11-26)

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
    options.ColorBy = 'labels'   % 'labels' (parts and light types) or 'material'
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

        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces','LabelPartNames','LabelFacePart'})))
            error('vehicleMesh must be a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart)');
        end
        if ~(ischar(options.Title) || isstring(options.Title))
            error('Title must be text');
        end
        if ~any(strcmpi(char(options.ColorBy), {'labels','material'}))
            error('ColorBy must be ''labels'' or ''material''');
        end
        if strcmpi(char(options.ColorBy),'material') && ~all(isfield(vehicleMesh, {'MaterialNames','FaceMaterialIndex'}))
            error('ColorBy=''material'' needs a mesh with MaterialNames and FaceMaterialIndex');
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
% (the body near-white, so the labels stand out and the body is not taken
% for the gray seen through the windows; Sean, 00:05)
partColors = struct('body',[0.97 0.97 0.97], 'glass',[0.55 0.80 1.00], 'wheel',[0.10 0.10 0.10], ...
    'light',[1.00 0.00 1.00], 'trim',[0.45 0.45 0.45], 'interior',[0.85 0.65 0.40]);
lightColors = struct('headlamp',[1.00 0.90 0.10], 'turnSignalLamp',[1.00 0.50 0.00], 'runningLamp',[0.00 0.90 0.90], ...
    'tailBrakeLamp',[0.90 0.00 0.00], 'backupLamp',[0.10 0.75 0.10], 'highBeamLamp',[0.30 0.55 1.00]);
% (the newer lamp types: their label colors from fcn_CarMesh3D_lampTypes)
lampNames = struct();   % (each lamp type's name for people: what the part is, rule P6)
for thisType = fcn_CarMesh3D_lampTypes()'
    if ~isfield(lightColors, thisType.Name)
        lightColors.(thisType.Name) = thisType.LabelColor;
    end
    lampNames.(thisType.Name) = regexprep(thisType.Label, '^(.)', '${lower($1)}');
end

Nfaces = size(vehicleMesh.Faces,1);
labelMesh = vehicleMesh;
faceColors = zeros(Nfaces,3);
for ith_part = 1:length(vehicleMesh.LabelPartNames)
    thisName = vehicleMesh.LabelPartNames{ith_part};
    if isfield(partColors, thisName)
        flagPart = vehicleMesh.LabelFacePart==ith_part;
        faceColors(flagPart,:) = repmat(partColors.(thisName), sum(flagPart), 1);
    end
end
if isfield(vehicleMesh,'LabelFaceLamp') && isfield(vehicleMesh,'LabelLampNames')
    for ith_type = 1:length(vehicleMesh.LabelLampNames)
        thisName = vehicleMesh.LabelLampNames{ith_type};
        flagType = vehicleMesh.LabelFaceLamp==ith_type;
        if isfield(lightColors, thisName)
            faceColors(flagType,:) = repmat(lightColors.(thisName), sum(flagType), 1);
        end
    end
end
flagByMaterial = strcmpi(char(options.ColorBy),'material');
usedMaterials = [];
materialPalette = [];
if flagByMaterial
    % (one distinct color per material used, in the order of the names)
    materialIndex = vehicleMesh.FaceMaterialIndex(:);
    usedMaterials = unique(materialIndex(materialIndex>0))';
    materialPalette = fcn_INTERNAL_distinctColors(numel(usedMaterials));
    faceColors = repmat([0.5 0.5 0.5], Nfaces, 1);
    for ith_used = 1:numel(usedMaterials)
        flagMaterial = materialIndex==usedMaterials(ith_used);
        faceColors(flagMaterial,:) = repmat(materialPalette(ith_used,:), sum(flagMaterial), 1);
    end
end
labelMesh.FaceColors = faceColors;
labelMesh.FaceAlpha = ones(Nfaces,1);

% The legend: each label color the mesh shows, with its face count (a
% part's faces that show a lamp type's color are counted for the lamp)
legendEntries = struct('Name', {}, 'Color', {}, 'Faces', {});
if ~flagByMaterial
    flagLampColor = false(Nfaces,1);
    typeEntries = legendEntries;
    if isfield(vehicleMesh,'LabelFaceLamp') && isfield(vehicleMesh,'LabelLampNames')
        for ith_type = 1:length(vehicleMesh.LabelLampNames)
            thisName = vehicleMesh.LabelLampNames{ith_type};
            flagType = vehicleMesh.LabelFaceLamp(:)==ith_type;
            if isfield(lightColors, thisName) && any(flagType)
                flagLampColor = flagLampColor | flagType;
                readable = fcn_INTERNAL_readableName(thisName);
                if isfield(lampNames, thisName)
                    readable = lampNames.(thisName);   % ("headlamp", not "headlight")
                end
                typeEntries(end+1) = struct('Name', readable, ...
                    'Color', lightColors.(thisName), 'Faces', sum(flagType)); %#ok<AGROW>
            end
        end
    end
    for ith_part = 1:length(vehicleMesh.LabelPartNames)
        thisName = vehicleMesh.LabelPartNames{ith_part};
        numFaces = sum(vehicleMesh.LabelFacePart(:)==ith_part & ~flagLampColor);
        if isfield(partColors, thisName) && numFaces > 0
            if strcmp(thisName, 'light')
                readable = 'lamp, no type';
            else
                readable = fcn_INTERNAL_readableName(thisName);
            end
            legendEntries(end+1) = struct('Name', readable, 'Color', partColors.(thisName), 'Faces', numFaces); %#ok<AGROW>
        end
    end
    legendEntries = [legendEntries, typeEntries];
end
glassIndex = find(strcmp(vehicleMesh.LabelPartNames,'glass'));
labelMesh.FaceAlpha(vehicleMesh.LabelFacePart==glassIndex) = 0.6;
% (a light that is also glass, a lamp's clear cover, is see-through too,
% so the lenses under it show)
if ~isempty(glassIndex) && isfield(vehicleMesh,'LabelFaceAlsoParts') && size(vehicleMesh.LabelFaceAlsoParts,1)==Nfaces ...
        && glassIndex <= size(vehicleMesh.LabelFaceAlsoParts,2)
    labelMesh.FaceAlpha(vehicleMesh.LabelFaceAlsoParts(:,glassIndex)) = 0.6;
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
    if flagByMaterial
        title(axesHandle, sprintf('%s: materials', titleText), 'Interpreter','none');
        % (the legend: one swatch per material, with its face count)
        hold(axesHandle, 'on');
        swatches = gobjects(numel(usedMaterials),1);
        swatchNames = cell(numel(usedMaterials),1);
        for ith_used = 1:numel(usedMaterials)
            swatches(ith_used) = plot3(axesHandle, NaN, NaN, NaN, 's', 'MarkerSize',10, ...
                'MarkerFaceColor',materialPalette(ith_used,:), 'MarkerEdgeColor',[0.3 0.3 0.3]);
            swatchNames{ith_used} = sprintf('%s (%d)', vehicleMesh.MaterialNames{usedMaterials(ith_used)}, ...
                sum(vehicleMesh.FaceMaterialIndex==usedMaterials(ith_used)));
        end
        legend(axesHandle, swatches, swatchNames, 'Interpreter','none', 'Location','eastoutside', 'FontSize',8);
        annotation(figureHandle, 'textbox', [0 0.01 1 0.06], 'EdgeColor','none', 'HorizontalAlignment','center', ...
            'FontSize',9, 'String','one color per material (face counts in the legend)   (drag to rotate; scroll to zoom)');
    else
        title(axesHandle, sprintf('%s: part and light labels', titleText), 'Interpreter','none');
        annotation(figureHandle, 'textbox', [0 0.01 1 0.06], 'EdgeColor','none', 'HorizontalAlignment','center', ...
            'FontSize',9, 'String',['body light gray | glass light blue | wheels black | trim dark gray | interior tan | light with no type magenta | ' ...
            'headlamp yellow | turn signal orange | running cyan | tail red | backup green   (drag to rotate; scroll to zoom)']);
    end
    enableDefaultInteractivity(axesHandle);   % (drag rotates a 3D view; scroll zooms)
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function


%% fcn_INTERNAL_readableName
function readable = fcn_INTERNAL_readableName(name)
% A label's name as a person reads it: 'turnSignalLamp' to 'turn signal'
lampTypes = fcn_CarMesh3D_lampTypes();
match = find(strcmp({lampTypes.Name}, name), 1);
if ~isempty(match)
    % (a lamp by its name for people, rule P6; the keys are camelCase, Q92 (A))
    readable = lower(strtrim(regexprep(lampTypes(match).Label, '\s*\([^)]*\)', '')));
else
    readable = regexprep(char(name), '([a-z])([A-Z])', '$1 ${lower($2)}');
end
end % Ends fcn_INTERNAL_readableName

%% fcn_INTERNAL_distinctColors
function colors = fcn_INTERNAL_distinctColors(numColors)
% numColors colors that are easy to tell apart: hues spread around the
% color wheel, alternating in brightness
hues = mod((0:numColors-1)'*0.618034, 1);
brightness = 0.95 - 0.30*mod((0:numColors-1)', 2);
colors = hsv2rgb([hues, 0.75*ones(numColors,1), brightness]);
end % Ends fcn_INTERNAL_distinctColors
