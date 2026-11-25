function iconImage = fcn_CarMesh3D_icons(iconName, options)
% fcn_CarMesh3D_icons
% The small pictures (icons) on CarMesh3D's buttons, drawn in code: one
% place for every icon, so the same action has the same picture in every
% GUI (rule G41, a goal: pictures before words, since many students read
% English as a second language). Each icon comes in two looks: active, and
% greyed for a button that cannot be pressed now.
%
% The icons (EDIT HERE, at fcn_INTERNAL_draw, to add one):
%   'vehicleNext'       a vehicle with a + (the next vehicle in a list)
%   'vehiclePrevious'   a vehicle with a - (the previous vehicle in a list)
%   'questionNext'      an arrow pointing right (the next question)
%   'questionPrevious'  an arrow pointing left (the previous question)
%   'summary'           a list with check marks (go to the Summary)
%   'questions'         a question mark (go back to the questions)
%
% FORMAT:
%
%       iconImage = fcn_CarMesh3D_icons(iconName, (Enabled=flag), (Height=pixels), (FigNum=figNum))
%
% INPUTS:
%
%      iconName: one of the names above; 'list' returns the names.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Enabled: true (default) for the active look; false for the greyed
%      look.
%
%      Height: the icon's height in pixels (default 24); its width follows
%      its shape (the vehicles are wider).
%
%      FigNum: if given, the icon is shown in that figure (all of them,
%      active and greyed, for 'list'); -1 for fast mode.
%
% OUTPUTS:
%
%      iconImage: the picture, as rows x columns x 3 colors (0 to 1), on
%      the light gray of a MATLAB button, ready for a uibutton's Icon; for
%      'list', a cell array of the names.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       uibutton(uifigure, 'Text', '', 'Icon', fcn_CarMesh3D_icons('vehicleNext'));
%       fcn_CarMesh3D_icons('list', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_icons.m for a full test
%       suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_icons
%   % * First write, for the V&V GUI's vehicle and question buttons
%   %   % (Sean, 12:16: "a + literally atop the vehicle image, one with a
%   %   % -, and a 'greyed out' version of the same image if button is not
%   %   % active")

% TO-DO:
%
% (none)

arguments
    iconName                 % One of the names, or 'list'
    options.Enabled = true   % false: the greyed look
    options.Height = 24      % Pixels
    options.FigNum = []      % Show it; -1 for fast mode
end

%% Debugging and Input checks
flag_check_inputs = ~isequal(options.FigNum, -1);
iconNames = {'vehicleNext', 'vehiclePrevious', 'questionNext', 'questionPrevious', 'summary', 'questions'};
if flag_check_inputs
    if ~(ischar(iconName) || isstring(iconName)) || ~any(strcmp([iconNames, {'list'}], char(iconName)))
        error('CarMesh3D:badInput', 'iconName must be one of: %s, or ''list''.', strjoin(iconNames, ', '));
    end
    if ~isscalar(options.Height) || options.Height < 8 || options.Height > 256
        error('CarMesh3D:badInput', 'Height must be a number of pixels from 8 to 256.');
    end
end
flag_do_plots = ~isempty(options.FigNum) && ~isequal(options.FigNum, -1);

%% Main code
if strcmp(char(iconName), 'list')
    iconImage = iconNames;
    if flag_do_plots
        fcn_INTERNAL_showAll(iconNames, options);
    end
    return;
end
iconImage = fcn_INTERNAL_draw(char(iconName), options.Height);
if ~options.Enabled
    iconImage = fcn_INTERNAL_greyed(iconImage);
end

%% Plotting
if flag_do_plots
    figure(options.FigNum);
    clf;
    image(iconImage);
    axis image off;
    title(char(iconName));
end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_draw
function iconImage = fcn_INTERNAL_draw(iconName, height)
% Draws one icon. Shapes are given on a grid 32 units high (48 wide for the
% vehicles), drawn 4 times finer and averaged down, so edges are smooth.
background = [0.96 0.96 0.96];   % (a MATLAB button's face)
bodyBlue = [0.18 0.33 0.58];
glass = [0.80 0.90 1.00];
tire = [0.12 0.12 0.12];
hub = [0.72 0.72 0.72];
plusGreen = [0.10 0.55 0.20];
minusOrange = [0.80 0.40 0.05];
ink = [0.15 0.15 0.15];
checkGreen = [0.10 0.55 0.20];
switch iconName
    case {'vehicleNext', 'vehiclePrevious'}
        unitsWide = 48;
    otherwise
        unitsWide = 32;
end
canvas = fcn_INTERNAL_canvas(unitsWide, 32, height, background);
switch iconName
    case {'vehicleNext', 'vehiclePrevious'}
        % (a hatchback from the side, facing right; then the + or - badge)
        canvas = fcn_INTERNAL_polygon(canvas, [2 24; 2 17; 7 15; 14 8; 31 8; 38 15; 45 16.5; 46 24], bodyBlue);
        canvas = fcn_INTERNAL_polygon(canvas, [15.5 10; 22 10; 22 14.5; 10.5 14.5], glass);
        canvas = fcn_INTERNAL_polygon(canvas, [24 10; 30 10; 34.5 14.5; 24 14.5], glass);
        for wheelX = [12 36]
            canvas = fcn_INTERNAL_circle(canvas, [wheelX 24], 5.5, tire);
            canvas = fcn_INTERNAL_circle(canvas, [wheelX 24], 2.2, hub);
        end
        if strcmp(iconName, 'vehicleNext')
            canvas = fcn_INTERNAL_circle(canvas, [39 8], 7.5, plusGreen);
            canvas = fcn_INTERNAL_stroke(canvas, [34.5 8; 43.5 8], 1.3, [1 1 1]);
            canvas = fcn_INTERNAL_stroke(canvas, [39 3.5; 39 12.5], 1.3, [1 1 1]);
        else
            canvas = fcn_INTERNAL_circle(canvas, [39 8], 7.5, minusOrange);
            canvas = fcn_INTERNAL_stroke(canvas, [34.5 8; 43.5 8], 1.3, [1 1 1]);
        end
    case 'questionNext'
        canvas = fcn_INTERNAL_polygon(canvas, [9 5; 27 16; 9 27], ink);
    case 'questionPrevious'
        canvas = fcn_INTERNAL_polygon(canvas, [23 5; 5 16; 23 27], ink);
    case 'summary'
        % (a sheet with three checked lines)
        canvas = fcn_INTERNAL_polygon(canvas, [5 2; 27 2; 27 30; 5 30], [1 1 1]);
        canvas = fcn_INTERNAL_stroke(canvas, [5 2; 27 2; 27 30; 5 30; 5 2], 0.9, ink);
        for lineY = [9 16 23]
            canvas = fcn_INTERNAL_stroke(canvas, [8 lineY; 10.5 lineY + 2.5; 14.5 lineY - 2.5], 1.1, checkGreen);
            canvas = fcn_INTERNAL_stroke(canvas, [17 lineY; 24 lineY], 1.0, ink);
        end
    case 'questions'
        % (a question mark in a circle)
        canvas = fcn_INTERNAL_circle(canvas, [16 16], 14.5, bodyBlue);
        arcAngles = linspace(pi, -pi/2 + 0.15, 14)';
        arc = [16 + 5.5*cos(arcAngles), 12 - 5.5*sin(arcAngles)];
        canvas = fcn_INTERNAL_stroke(canvas, [arc; 16 21], 1.6, [1 1 1]);
        canvas = fcn_INTERNAL_circle(canvas, [16 25.5], 1.9, [1 1 1]);
end
iconImage = fcn_INTERNAL_shrink(canvas);
end % Ends fcn_INTERNAL_draw

%% fcn_INTERNAL_canvas
function canvas = fcn_INTERNAL_canvas(unitsWide, unitsHigh, height, background)
% A drawing grid 4 times finer than the icon, with the pixel centers in
% shape units
fine = 4;
numRows = round(height)*fine;
numColumns = round(height*unitsWide/unitsHigh)*fine;
scale = unitsHigh/numRows;
[columnIndex, rowIndex] = meshgrid(1:numColumns, 1:numRows);
canvas.X = (columnIndex - 0.5)*scale;
canvas.Y = (rowIndex - 0.5)*scale;
canvas.Image = repmat(reshape(background, 1, 1, 3), numRows, numColumns);
canvas.Fine = fine;
end % Ends fcn_INTERNAL_canvas

%% fcn_INTERNAL_paint
function canvas = fcn_INTERNAL_paint(canvas, inside, color)
% Colors the grid points that are inside
for ith_color = 1:3
    layer = canvas.Image(:, :, ith_color);
    layer(inside) = color(ith_color);
    canvas.Image(:, :, ith_color) = layer;
end
end % Ends fcn_INTERNAL_paint

%% fcn_INTERNAL_polygon
function canvas = fcn_INTERNAL_polygon(canvas, corners, color)
canvas = fcn_INTERNAL_paint(canvas, inpolygon(canvas.X, canvas.Y, corners(:, 1), corners(:, 2)), color);
end % Ends fcn_INTERNAL_polygon

%% fcn_INTERNAL_circle
function canvas = fcn_INTERNAL_circle(canvas, center, radius, color)
canvas = fcn_INTERNAL_paint(canvas, (canvas.X - center(1)).^2 + (canvas.Y - center(2)).^2 <= radius^2, color);
end % Ends fcn_INTERNAL_circle

%% fcn_INTERNAL_stroke
function canvas = fcn_INTERNAL_stroke(canvas, points, halfWidth, color)
% A line through the points, halfWidth on each side, with round ends
inside = false(size(canvas.X));
for ith_segment = 1:size(points, 1) - 1
    startPoint = points(ith_segment, :);
    direction = points(ith_segment + 1, :) - startPoint;
    along = ((canvas.X - startPoint(1))*direction(1) + (canvas.Y - startPoint(2))*direction(2))/max(sum(direction.^2), eps);
    along = min(max(along, 0), 1);
    distance2 = (canvas.X - startPoint(1) - along*direction(1)).^2 + (canvas.Y - startPoint(2) - along*direction(2)).^2;
    inside = inside | distance2 <= halfWidth^2;
end
canvas = fcn_INTERNAL_paint(canvas, inside, color);
end % Ends fcn_INTERNAL_stroke

%% fcn_INTERNAL_shrink
function iconImage = fcn_INTERNAL_shrink(canvas)
% Averages each block of fine points into one pixel (smooth edges)
fine = canvas.Fine;
[numRows, numColumns, ~] = size(canvas.Image);
iconImage = reshape(canvas.Image, fine, numRows/fine, fine, numColumns/fine, 3);
iconImage = squeeze(mean(mean(iconImage, 1), 3));
iconImage = reshape(iconImage, numRows/fine, numColumns/fine, 3);
end % Ends fcn_INTERNAL_shrink

%% fcn_INTERNAL_greyed
function iconImage = fcn_INTERNAL_greyed(iconImage)
% The greyed look: no color, and faded toward the button's face
background = 0.96;
gray = 0.30*iconImage(:, :, 1) + 0.59*iconImage(:, :, 2) + 0.11*iconImage(:, :, 3);
gray = background + 0.35*(gray - background);
iconImage = repmat(gray, 1, 1, 3);
end % Ends fcn_INTERNAL_greyed

%% fcn_INTERNAL_showAll
function fcn_INTERNAL_showAll(iconNames, options)
% Every icon, active above and greyed below
figure(options.FigNum);
clf;
tiledlayout(2, numel(iconNames), 'TileSpacing', 'compact');
for flagEnabled = [true false]
    for ith_icon = 1:numel(iconNames)
        nexttile;
        image(fcn_CarMesh3D_icons(iconNames{ith_icon}, Enabled=flagEnabled, Height=options.Height, FigNum=-1));
        axis image off;
        if flagEnabled
            title(iconNames{ith_icon}, 'FontWeight', 'normal', 'FontSize', 8);
        end
    end
end
end % Ends fcn_INTERNAL_showAll
