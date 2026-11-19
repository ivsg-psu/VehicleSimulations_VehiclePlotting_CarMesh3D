% script_test_fcn_CarMesh3D_fillSampleMesh.m
% Tests fcn_CarMesh3D_fillSampleMesh
% Builds a sample car mesh for testing the workflow without downloads.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillSampleMesh
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillSampleMesh
%   % * Renamed from script_CarMesh3D_fillSampleMesh: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillSampleMesh
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

%% DEMO case: Clean sample mesh from the sedan preset
figNum = 10001;
titleString = sprintf('DEMO case: Clean sample mesh from the sedan preset');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleMesh));
assert(iscell(vehicleMesh.MaterialNames));

% Check variable sizes
Nfaces = size(vehicleMesh.Faces,1);
assert(size(vehicleMesh.Vertices,2)==3);
assert(size(vehicleMesh.Faces,2)==3);
assert(isequal(size(vehicleMesh.FaceMaterialIndex),[Nfaces 1]));
assert(isequal(size(vehicleMesh.FaceGroupIndex),[Nfaces 1]));
assert(length(vehicleMesh.MaterialNames)==6);
assert(length(vehicleMesh.GroupNames)==7);

% Check variable values
assert(all(vehicleMesh.Faces(:)>=1) && all(vehicleMesh.Faces(:)<=size(vehicleMesh.Vertices,1)));
assert(isequal(vehicleMesh.Frame,'ISO8855'));
assert(abs(min(vehicleMesh.Vertices(:,3)))<1e-9); % Tires touch the ground
vehicleLength = max(vehicleMesh.Vertices(:,1)) - min(vehicleMesh.Vertices(:,1));
assert(abs(vehicleLength - 4.80)<0.02);
% Every wheel group has faces
for ith_wheel = 4:7
    assert(any(vehicleMesh.FaceGroupIndex==ith_wheel));
end

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Messy sample mesh, like a downloaded file (mm, Y up, Z forward)
figNum = 10002;
titleString = sprintf('DEMO case: Messy sample mesh, like a downloaded file (mm, Y up, Z forward)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(isequal(vehicleMesh.Units,'mm'));
assert(isequal(vehicleMesh.Frame,'source'));
% The length is now along the third axis, in mm
vehicleLength = max(vehicleMesh.Vertices(:,3)) - min(vehicleMesh.Vertices(:,3));
assert(abs(vehicleLength - 4800)<20);

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

%% TEST case: SUV spec builds a taller sample
figNum = 20001;
titleString = sprintf('TEST case: SUV spec builds a taller sample');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSUV', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');
vehicleHeight = max(vehicleMesh.Vertices(:,3)) - min(vehicleMesh.Vertices(:,3));
assert(abs(vehicleHeight - vehicleSpec.OverallHeight)<0.02);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Fewer wheel segments gives fewer faces
figNum = 20002;
titleString = sprintf('TEST case: Fewer wheel segments gives fewer faces');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

mesh16 = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
mesh8 = fcn_CarMesh3D_fillSampleMesh(NumWheelSegments=8, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Each wheel has 8 faces per segment (2 tread, 4 side rings, 2 rim)
assert(size(mesh16.Faces,1) - size(mesh8.Faces,1) == 4*8*(16-8));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Clean and messy samples have the same shape
figNum = 20003;
titleString = sprintf('TEST case: Clean and messy samples have the same shape');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

cleanMesh = fcn_CarMesh3D_fillSampleMesh(Style='clean');
messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy');
assert(isequal(cleanMesh.Faces, messyMesh.Faces));
% Undo the messy conversion: [x y z]_clean = [z x y]_messy/1000 (after removing the offset)
undoneVertices = (messyMesh.Vertices - [120 -35 2500])/1000;
undoneVertices = undoneVertices(:,[3 1 2]);
assert(max(abs(undoneVertices(:) - cleanMesh.Vertices(:)))<1e-9);

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

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=[]);
assert(isstruct(vehicleMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
assert(isstruct(vehicleMesh));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

% (no setup needed)

Niterations = 20;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
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
        vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=[]);
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
title('fcn_CarMesh3D_fillSampleMesh: time per call','Interpreter','none');
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

%% FAIL case: Unknown style
if 1==0
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(Style='tidy');
end

%% FAIL case: Spec missing the wheelbase
if 1==0
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=fcn_CarMesh3D_fillVehicleSpec(OverallLength=4.5, OverallWidth=1.8, OverallHeight=1.4));
end

%% FAIL case: Too few wheel segments
if 1==0
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(NumWheelSegments=3);
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
