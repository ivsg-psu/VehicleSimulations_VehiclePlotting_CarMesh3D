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
% the flat colors of CarMesh3D plots.
%
% FORMAT:
%
%       fcn_CarMesh3D_saveGifFrame(figureHandle, fileName, frameNumber,...
%           (DelayTime=seconds), (LoopCount=count), (Scale=scale),...
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
%       See the script: script_CarMesh3D_saveGifFrame.m for a full test
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
[indexedImage, colorMap] = rgb2ind(image, 256, 'nodither');

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


