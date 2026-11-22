% script_test_fcn_CarMesh3D_showVehicle.m
% Tests fcn_CarMesh3D_showVehicle
% One finished vehicle in 3D, 2D, or by label or material, with a summary.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_showVehicle
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_showVehicle
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

%% DEMO case: The Prius in 3D, with its 2D outlines
figNum = 10001;
titleString = sprintf('DEMO case: The Prius in 3D, with its 2D outlines');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[vehicleMesh, vehicleInfo] = fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', FigNum=figNum);

% Check variable types
assert(isstruct(vehicleMesh) && isfield(vehicleMesh,'Faces'));
assert(isstruct(vehicleInfo) && ischar(vehicleInfo.Name) && isnumeric(vehicleInfo.Score));

% Check variable sizes
assert(vehicleInfo.Faces==size(vehicleMesh.Faces,1));

% Check variable values: both figures exist; the score is in 0 to 100
assert(isgraphics(figure(figNum)) && isgraphics(figure(figNum+1)));
assert(vehicleInfo.Score>=0 && vehicleInfo.Score<=100);
assert(strcmp(vehicleInfo.ID,'2013_Toyota_Prius_Four') && vehicleInfo.Length_m>4);

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Each view
figNum = 20001;
titleString = sprintf('TEST case: Each view');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

viewList = {'3d','2d','labels','materials'};
for ith_view = 1:numel(viewList)
    thisFig = figNum + 10*(ith_view-1);
    vehicleMesh = fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', View=viewList{ith_view}, FigNum=thisFig);
    assert(isgraphics(figure(thisFig)) && ~isempty(findobj(figure(thisFig),'Type','axes')));
end
assert(isempty(findobj(groot,'Type','figure','Number',figNum+1)));   % ('3d' alone: no outline figure)

%% TEST case: A generic vehicle reports its body style
figNum = 20101;
titleString = sprintf('TEST case: A generic vehicle reports its body style');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[~, vehicleInfo] = fcn_CarMesh3D_showVehicle('2026_CarMesh3D_Generic_StationWagon', FigNum=[]);
assert(strcmpi(vehicleInfo.BodyStyle,'stationWagon'));
assert(isempty(findobj(groot,'Type','figure','Number',figNum)));      % (no figure when FigNum is empty)

%% TEST case: A vehicle with no finished mesh is an error
figNum = 20201;
titleString = sprintf('TEST case: A vehicle with no finished mesh is an error');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

flagErrored = false;
try
    fcn_CarMesh3D_showVehicle('1900_No_Such_Vehicle', FigNum=[]);
catch errorInfo
    flagErrored = true;
    assert(contains(errorInfo.message,'1900_No_Such_Vehicle'));
end
assert(flagErrored);

%% Fast Mode Tests



%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
vehicleMesh = fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', FigNum=[]);
assert(isstruct(vehicleMesh));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleMesh = fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', FigNum=-1);
assert(isstruct(vehicleMesh));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An unknown view
if 1==0
    fcn_CarMesh3D_showVehicle('2013_Toyota_Prius_Four', View='sideways', FigNum=1);
end
