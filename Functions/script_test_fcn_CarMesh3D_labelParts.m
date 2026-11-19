% script_test_fcn_CarMesh3D_labelParts.m
% Tests fcn_CarMesh3D_labelParts
% Labels body, glass, wheel, light, and trim faces from material and group names.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_labelParts
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_labelParts
%   % * Renamed from script_CarMesh3D_labelParts: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_labelParts
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

%% DEMO case: Label the parts of the sample mesh
figNum = 10001;
titleString = sprintf('DEMO case: Label the parts of the sample mesh');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(iscell(vehicleMesh.PartNames));

% Check variable sizes
Nfaces = size(vehicleMesh.Faces,1);
assert(isequal(size(vehicleMesh.FacePartIndex),[Nfaces 1]));
assert(isequal(size(vehicleMesh.FaceWheelIndex),[Nfaces 1]));
assert(isequal(size(vehicleMesh.FaceColors),[Nfaces 3]));
assert(isequal(size(vehicleMesh.FaceAlpha),[Nfaces 1]));

% Check variable values. The sample has 8 glass faces (windshield 2, rear
% window 2, side windows 4), 8 light faces, and 4 wheels of 8*16 faces.
assert(8==sum(vehicleMesh.FacePartIndex==2));
assert(512==sum(vehicleMesh.FacePartIndex==3));
assert(8==sum(vehicleMesh.FacePartIndex==4));
assert(0==sum(vehicleMesh.FacePartIndex==5));
for ith_wheel = 1:4
    assert(128==sum(vehicleMesh.FaceWheelIndex==ith_wheel));
end
assert(all(abs(vehicleMesh.FaceAlpha(vehicleMesh.FacePartIndex==2) - 0.35)<1e-12));
assert(all(vehicleMesh.FaceAlpha(vehicleMesh.FacePartIndex~=2)==1));
% Light types from names: 4 headlight faces and 4 tail light faces
assert(4==sum(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,'headlight'))));
assert(4==sum(vehicleMesh.FaceLightType==find(strcmp(vehicleMesh.LightTypeNames,'tail'))));
assert(all(vehicleMesh.FaceLightType(vehicleMesh.FacePartIndex~=4)==0));

% Wheel 1 is front-left: positive X and positive Y
fcn_INTERNAL_checkWheelCorner(vehicleMesh, 1, [ 1  1]);
fcn_INTERNAL_checkWheelCorner(vehicleMesh, 2, [ 1 -1]);
fcn_INTERNAL_checkWheelCorner(vehicleMesh, 3, [-1  1]);
fcn_INTERNAL_checkWheelCorner(vehicleMesh, 4, [-1 -1]);

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

%% TEST case: BodyColor and GlassAlpha options
figNum = 20001;
titleString = sprintf('TEST case: BodyColor and GlassAlpha options');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, BodyColor=[0.9 0.9 0.1], GlassAlpha=0.6, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

bodyColors = vehicleMesh.FaceColors(vehicleMesh.FacePartIndex==1,:);
assert(all(all(abs(bodyColors - [0.9 0.9 0.1])<1e-12)));
assert(all(abs(vehicleMesh.FaceAlpha(vehicleMesh.FacePartIndex==2) - 0.6)<1e-12));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: User rules are checked before the default rules
figNum = 20002;
titleString = sprintf('TEST case: User rules are checked before the default rules');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, PartRules={'CarPaint','trim'});
assert(0==sum(vehicleMesh.FacePartIndex==1)); % No body faces left
assert(sum(vehicleMesh.FacePartIndex==5)>0);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A mesh that is not normalized gets no wheel numbers
figNum = 20003;
titleString = sprintf('TEST case: A mesh that is not normalized gets no wheel numbers');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
lastwarn('');
vehicleMesh = fcn_CarMesh3D_labelParts(messyMesh);
[warningMessage,~] = lastwarn;
assert(contains(warningMessage,'normalizeMesh'));
assert(all(vehicleMesh.FaceWheelIndex==0));
assert(512==sum(vehicleMesh.FacePartIndex==3)); % Parts are still labeled

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: The word trim is not mistaken for a wheel rim
figNum = 20004;
titleString = sprintf('TEST case: The word trim is not mistaken for a wheel rim');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
sampleMesh.MaterialNames{1} = 'Door_trim'; % Rename the paint material
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh);
assert(0==sum(vehicleMesh.FacePartIndex==1));
assert(sum(vehicleMesh.FacePartIndex==5)>0); % Became trim, not wheel
assert(512==sum(vehicleMesh.FacePartIndex==3));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: PartColors sets the color of any part
figNum = 20005;
titleString = sprintf('TEST case: PartColors sets the color of any part');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, BodyColor=[0.9 0.9 0.9], ...
    PartColors={'body',[0.05 0.2 0.6]; 'glass',[0.35 0.35 0.38]; 'wheel',[0 0 0]}, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% PartColors wins over BodyColor
assert(all(all(abs(vehicleMesh.FaceColors(vehicleMesh.FacePartIndex==1,:) - [0.05 0.2 0.6])<1e-12)));
assert(all(all(abs(vehicleMesh.FaceColors(vehicleMesh.FacePartIndex==2,:) - [0.35 0.35 0.38])<1e-12)));
assert(all(all(vehicleMesh.FaceColors(vehicleMesh.FacePartIndex==3,:)==0)));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

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

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=[]);
assert(isfield(vehicleMesh,'FacePartIndex'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=-1);
assert(isfield(vehicleMesh,'FacePartIndex'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

sampleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);

Niterations = 100;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=-1);
end
fast_method = toc;

% Input checks turned off by environment variable. The code reads these
% variables only when both are set. Save the user's settings and restore
% them afterward, even if a call errors.
old_check_inputs = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
old_do_debug     = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS","0");
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG","0");
try
    tic;
    for ith_test = 1:Niterations
        vehicleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=[]);
    end
    env_method = toc;
catch ME
    setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
    setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);
    rethrow(ME);
end
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

barLabels = {'Normal mode','Checks off (environment variable)','Fast mode (FigNum=-1)'};
X = categorical(barLabels);
X = reordercats(X,barLabels); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method env_method fast_method]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')
title('fcn_CarMesh3D_labelParts: time per call','Interpreter','none');
fprintf(1,'Average time per call (ms): normal %.3f, checks off by environment variable %.3f, fast mode %.3f\n',Y(1),Y(2),Y(3));

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

%% FAIL case: Unknown part name in a rule
if 1==0
    vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh, PartRules={'Paint','roof'});
end

%% FAIL case: Glass alpha out of range
if 1==0
    vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh, GlassAlpha=2);
end

%% FAIL case: PartColors with an unknown part
if 1==0
    vehicleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh, PartColors={'roof',[1 0 0]});
end

%% FAIL case: Mesh without materials
if 1==0
    vehicleMesh = fcn_CarMesh3D_labelParts(struct('Vertices',rand(3),'Faces',[1 2 3]));
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

%% fcn_INTERNAL_checkWheelCorner
function fcn_INTERNAL_checkWheelCorner(vehicleMesh, wheelNumber, expectedSigns)
% Checks that the faces of one numbered wheel sit at the expected corner,
% given as the expected signs of [X Y]
wheelFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==wheelNumber,:);
wheelCenter = mean(vehicleMesh.Vertices(unique(wheelFaces(:)),:),1);
assert(isequal(sign(wheelCenter(1:2)), expectedSigns));
end % Ends fcn_INTERNAL_checkWheelCorner
