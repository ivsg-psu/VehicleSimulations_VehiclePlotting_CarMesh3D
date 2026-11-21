function fcn_CarMesh3D_saveGifFrame(figureHandle, fileName, frameNumber, options)
% fcn_CarMesh3D_saveGifFrame
% Adds the current picture of a figure to an animated GIF file, for
% sharing animations (for example in a README). Call it once per frame
% inside an animation loop, after drawnow:
%
%       for k = 1:N
%           ... move the vehicle and camera ...
%           drawnow;
%           fcn_CarMesh3D_saveGifFrame(gcf, 'myAnimation.gif', k, DelayTime=0.05);
%       end
%
% Frame 1 starts a new file (replacing any old one); later frames are
% added to the end. Colors are reduced to 256 (a GIF limit), which suits
% the flat colors of CarMesh3D plots. By default each frame gets its own
% 256 colors; ColorMap='fixed' (or 'firstFrame', or a map of your own)
% keeps one map for every frame, so small colored details (thin lines,
% tinted vehicles) do not flicker or turn gray from frame to frame.
%
% FORMAT:
%
%       fcn_CarMesh3D_saveGifFrame(figureHandle, fileName, frameNumber,...
%           (DelayTime=seconds), (LoopCount=count), (Scale=scale),...
%           (ColorMap=mapChoice),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      figureHandle: the figure to capture.
%
%      fileName: the .gif file to write.
%
%      frameNumber: 1 for the first frame (starts the file), then 2, 3, ...
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      DelayTime: seconds each frame is shown. Default is 0.05 (20 frames
%      per second).
%
%      LoopCount: how many times the GIF repeats; Inf (default) repeats
%      forever.
%
%      Scale: shrink factor for the image, from 0 to 1, to make smaller
%      files. Default is 1 (full size).
%
%      ColorMap: the 256 colors each frame is reduced to:
%           'perFrame' (default): chosen for each frame from its own
%               colors (best for each frame alone; colors may shift from
%               frame to frame)
%           'fixed': one standard map for every frame: a 6 x 7 x 6 cube of
%               colors (252) and 4 grays. The same in every frame and every
%               file.
%           'firstFrame': the map chosen for frame 1 of this file, reused
%               for every later frame of the file
%           an N x 3 map (N up to 256, values 0 to 1): your own
%
%      FigNum: if set to -1, input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      (none; the frame is written to the file)
%
% DEPENDENCIES:
%
%      getframe, rgb2ind, imwrite, imresize (Image Processing Toolbox,
%      only if Scale < 1)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_saveGifFrame.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveGifFrame
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveGifFrame
%   % * ColorMap option: 'perFrame' (as before), 'fixed', 'firstFrame', or
%   %   % a given map (asked for by AnimateCar3D)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveGifFrame
%   % * Consider video (MP4) output with VideoWriter for long animations



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    figureHandle
    fileName
    frameNumber
    options.DelayTime = 0.05   % seconds per frame
    options.LoopCount = Inf    % repeats; Inf for forever
    options.Scale = 1          % image shrink factor, 0 to 1
    options.ColorMap = 'perFrame' % 'perFrame', 'fixed', 'firstFrame', or an N x 3 map
    options.FigNum = []        % -1 for fast mode (no input checks)
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

        % Check the figureHandle input
        if ~isgraphics(figureHandle,'figure')
            error('figureHandle must be a valid figure');
        end

        % Check the fileName input
        if ~(ischar(fileName) || isstring(fileName))
            error('fileName must be a character string');
        end
        [~,~,tempExtension] = fileparts(char(fileName));
        if ~strcmpi(tempExtension,'.gif')
            error('fileName must end in .gif');
        end

        % Check the frameNumber input
        if ~isnumeric(frameNumber) || ~isscalar(frameNumber) || frameNumber<1 || frameNumber~=round(frameNumber)
            error('frameNumber must be a whole number, 1 or more');
        end

        % Check the ColorMap input
        colorChoice = options.ColorMap;
        if isnumeric(colorChoice)
            if ~(ismatrix(colorChoice) && size(colorChoice,2)==3 && size(colorChoice,1)>=2 && size(colorChoice,1)<=256 ...
                    && all(colorChoice(:)>=0 & colorChoice(:)<=1))
                error('A ColorMap given as numbers must be N x 3 (N from 2 to 256), with values from 0 to 1');
            end
        elseif ~((ischar(colorChoice) || isstring(colorChoice)) && any(strcmpi(colorChoice, {'perFrame','fixed','firstFrame'})))
            error('ColorMap must be ''perFrame'', ''fixed'', ''firstFrame'', or an N x 3 map');
        end

        % Check the DelayTime and Scale inputs
        if ~isnumeric(options.DelayTime) || ~isscalar(options.DelayTime) || options.DelayTime<0
            error('DelayTime must be a non-negative number of seconds');
        end
        if ~isnumeric(options.Scale) || ~isscalar(options.Scale) || options.Scale<=0 || options.Scale>1
            error('Scale must be a number greater than 0, up to 1');
        end
    end
end

% (This function writes a file; it makes no plot of its own)

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

% Capture the figure
frame = getframe(figureHandle);
image = frame.cdata;
if options.Scale<1
    image = imresize(image, options.Scale);
end
% (the color map: per frame, fixed, the first frame's, or given)
persistent firstFrameMaps
if isempty(firstFrameMaps)
    firstFrameMaps = containers.Map('KeyType','char', 'ValueType','any');
end
mapChoice = options.ColorMap;
if isnumeric(mapChoice)
    colorMap = mapChoice;
    indexedImage = rgb2ind(image, colorMap, 'nodither');
elseif strcmpi(mapChoice, 'fixed')
    colorMap = fcn_INTERNAL_fixedMap;
    indexedImage = rgb2ind(image, colorMap, 'nodither');
elseif strcmpi(mapChoice, 'firstFrame') && frameNumber > 1 && isKey(firstFrameMaps, char(fileName))
    colorMap = firstFrameMaps(char(fileName));
    indexedImage = rgb2ind(image, colorMap, 'nodither');
else
    [indexedImage, colorMap] = rgb2ind(image, 256, 'nodither');
    if strcmpi(mapChoice, 'firstFrame')
        firstFrameMaps(char(fileName)) = colorMap;
    end
end

% Write: start a new file on frame 1, otherwise add to it
if frameNumber==1
    imwrite(indexedImage, colorMap, char(fileName), 'gif', ...
        'LoopCount', options.LoopCount, 'DelayTime', options.DelayTime);
else
    imwrite(indexedImage, colorMap, char(fileName), 'gif', ...
        'WriteMode', 'append', 'DelayTime', options.DelayTime);
end

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
% (No plot)

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

%% fcn_INTERNAL_fixedMap
function colorMap = fcn_INTERNAL_fixedMap
% A standard 256-color map: a 6 x 7 x 6 cube of colors (252: more steps of
% green, which the eye sees best) and 4 grays between the cube's levels
[red, green, blue] = ndgrid(linspace(0,1,6), linspace(0,1,7), linspace(0,1,6));
colorMap = [red(:) green(:) blue(:); [0.1 0.3 0.7 0.9]'*[1 1 1]];
end % Ends fcn_INTERNAL_fixedMap
