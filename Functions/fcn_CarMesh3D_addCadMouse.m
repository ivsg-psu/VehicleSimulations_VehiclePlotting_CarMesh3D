function fcn_CarMesh3D_addCadMouse(axesHandle, options)
% fcn_CarMesh3D_addCadMouse

% Gives a 3D axes the CAD-style mouse the CarMesh3D viewers use, in place
% of MATLAB's own rotate and zoom: left-drag turns the model (about the
% vertical axis and the screen's horizontal axis), right-drag pans, and
% the mouse wheel zooms. For any plain figure of a mesh (a diagnostic
% plot, a test picture) that a person will turn and zoom.
%
% It sets the figure's WindowButtonDownFcn, WindowButtonMotionFcn,
% WindowButtonUpFcn and WindowScrollWheelFcn, and turns off MATLAB's own
% rotate, pan and zoom modes. Several axes in one figure are given in one
% call: a drag moves the axes it starts on, and the wheel zooms the axes
% under the pointer (or the last one dragged). Drags that start outside
% the given axes are ignored. Axes whose cameras are linked (linkprop)
% follow along.
%
% FORMAT:
%
%       fcn_CarMesh3D_addCadMouse(axesHandle, (FigNum=figNum))
%
% INPUTS:
%
%      axesHandle: the 3D axes to control (one, or several in one figure).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used (no plot is made); -1 for fast mode (no input
%      checks).
%
% OUTPUTS:
%
%      (none)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_addCadMouse.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addCadMouse
%   % * First write (Sean, 02:45: "The native zoom function in MATLAB is
%   %   % honestly horrible in 3D"): the mouse handling of
%   %   % fcn_CarMesh3D_viewOrientation, as one function any figure can use
%   %   % Several axes in one figure (Sean, 03:01: a 2x2 view)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addCadMouse
%   % * The viewers (viewLabels, paintLabels, viewOrientation,
%   %   % viewDimensions, viewOutline, viewDetailLevels, animateChecks)
%   %   % each have their own copy of this mouse handling; they could call
%   %   % this one instead (one list in one place)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    axesHandle
    options.FigNum = []         % Not used; -1 for fast mode
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
        % Check the axesHandle input
        if isempty(axesHandle) || ~all(isgraphics(axesHandle)) || ~all(ismember({axesHandle.Type}, {'axes', 'uiaxes'}))
            error('axesHandle must be one or more axes');
        end
        if numel(unique(arrayfun(@(oneAxes) double(ancestor(oneAxes, 'figure')), axesHandle))) > 1
            error('axesHandle: the axes must all be in one figure');
        end
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

allAxes = axesHandle(:)';
figureHandle = ancestor(allAxes(1), 'figure');
% (MATLAB's own modes would fight the mouse handlers below)
rotate3d(figureHandle, 'off');
pan(figureHandle, 'off');
zoom(figureHandle, 'off');
for oneAxes = allAxes
    axis(oneAxes, 'vis3d');   % (no stretching while turning)
    oneAxes.Interactions = [];
    if isprop(oneAxes, 'Toolbar') && ~isempty(oneAxes.Toolbar)
        oneAxes.Toolbar.Visible = 'off';
    end
end

mouseMode = '';
mouseLast = [0 0];
activeAxes = allAxes(1);   % (the axes being dragged, or last dragged)
set(figureHandle, 'WindowButtonDownFcn', @(~,~) onDown(), 'WindowButtonMotionFcn', @(~,~) onMove(), ...
    'WindowButtonUpFcn', @(~,~) onUp(), 'WindowScrollWheelFcn', @onScroll);

    function onDown()
        % Left button turns; right button pans; only on this axes
        mouseMode = '';
        clicked = figureHandle.CurrentObject;
        if isempty(clicked) || ~isvalid(clicked)
            return;
        end
        clickedAxes = ancestor(clicked, {'axes', 'uiaxes'});
        if isempty(clickedAxes) || ~any(allAxes == clickedAxes)
            return;
        end
        activeAxes = clickedAxes;
        if strcmp(figureHandle.SelectionType, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseLast = figureHandle.CurrentPoint;
    end

    function onMove()
        if isempty(mouseMode) || ~isvalid(activeAxes)
            return;
        end
        point = figureHandle.CurrentPoint;
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(activeAxes, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(activeAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function onUp()
        mouseMode = '';
    end

    function onScroll(~, event)
        % (the axes under the pointer, else the last one dragged)
        zoomAxes = activeAxes;
        hovered = hittest(figureHandle);
        if ~isempty(hovered) && isvalid(hovered)
            hoveredAxes = ancestor(hovered, {'axes', 'uiaxes'});
            if ~isempty(hoveredAxes) && any(allAxes == hoveredAxes)
                zoomAxes = hoveredAxes;
            end
        end
        if isvalid(zoomAxes)
            camzoom(zoomAxes, 1.15^(-event.VerticalScrollCount));
        end
    end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function
