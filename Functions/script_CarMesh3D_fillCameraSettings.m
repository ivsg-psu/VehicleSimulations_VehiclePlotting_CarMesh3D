% script_CarMesh3D_fillCameraSettings.m
% Tests fcn_CarMesh3D_fillCameraSettings
% Makes camera settings: where it sits, what it looks at, and how wide it sees.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_fillCameraSettings
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_fillCameraSettings
%   % * (fill in items here)


%% Set up the workspace
close all

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: The chase camera preset, drawn from above and the side
figNum = 10001;
titleString = sprintf('DEMO case: The chase camera preset, drawn from above and the side');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase', FigNum=figNum);

% Check variable types
assert(isstruct(cameraSettings));

% Check variable values
assert(isequal(cameraSettings.Position,[-7 0 2.5]));
assert(strcmp(cameraSettings.PositionFrame,'vehicle'));
assert(strcmp(cameraSettings.TargetFrame,'vehicle'));
assert(cameraSettings.FieldOfView==50);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: A custom camera - start from kite, fly lower and zoom in
figNum = 10002;
titleString = sprintf('DEMO case: A custom camera - start from kite, fly lower and zoom in');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite', Position=[-10 0 5], FieldOfView=30, FigNum=figNum);
assert(isequal(cameraSettings.Position,[-10 0 5]));
assert(cameraSettings.FieldOfView==30);
assert(isequal(cameraSettings.Target,[6 0 0])); % Kept from the preset

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Every preset has all settings
figNum = 20001;
titleString = sprintf('TEST case: Every preset has all settings');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

modeNames = {'wideFixed','roadside','overhead','chase','driver','roof','side','kite','orbit'};
for ith_mode = 1:length(modeNames)
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode=modeNames{ith_mode});
    assert(numel(cameraSettings.Position)==3 && numel(cameraSettings.Target)==3);
    assert(any(strcmp(cameraSettings.PositionFrame,{'world','vehicle'})));
    assert(any(strcmp(cameraSettings.TargetFrame,{'world','vehicle'})));
    assert(cameraSettings.FieldOfView>0);
end
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='orbit');
assert(cameraSettings.OrbitRate==0.4);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='overhead');
assert(isequal(cameraSettings.UpVector,[0 1 0]));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='side', FigNum=[]);
assert(isstruct(cameraSettings));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='side', FigNum=-1);
assert(isstruct(cameraSettings));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: Unknown mode
if 1==0
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='drone');
end

%% FAIL case: Bad frame name
if 1==0
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(PositionFrame='car');
end

%% FAIL case: Field of view out of range
if 1==0
    cameraSettings = fcn_CarMesh3D_fillCameraSettings(FieldOfView=200);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
