% script_test_fcn_CarMesh3D_normalizeMesh.m
% Tests fcn_CarMesh3D_normalizeMesh
% Puts meshes into the CarMesh3D vehicle frame (X forward, Y left, Z up, meters).

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_normalizeMesh
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_normalizeMesh
%   % * Renamed from script_CarMesh3D_normalizeMesh: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_normalizeMesh
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

%% DEMO case: Normalize a messy mesh (mm, Y up, Z forward)
figNum = 10001;
titleString = sprintf('DEMO case: Normalize a messy mesh (mm, Y up, Z forward)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleMesh));
assert(isstruct(vehicleMesh.NormalizeInfo));

% Check variable sizes
assert(isequal(size(vehicleMesh.Vertices), size(messyMesh.Vertices)));

% Check variable values: it matches the clean sample, re-centered
cleanMesh = fcn_CarMesh3D_fillSampleMesh(Style='clean', FigNum=-1);
cleanVertices = fcn_INTERNAL_recenter(cleanMesh.Vertices);
assert(max(abs(vehicleMesh.Vertices(:) - cleanVertices(:)))<1e-6);
assert(isequal(vehicleMesh.Units,'m'));
assert(isequal(vehicleMesh.Frame,'ISO8855'));
assert(abs(vehicleMesh.NormalizeInfo.MetersPerFileUnit - 0.001)<1e-15);
assert(abs(det(vehicleMesh.NormalizeInfo.RotationMatrix) - 1)<1e-12); % A rotation, not a mirror

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

%% TEST case: Numeric units give the same result as auto
figNum = 20001;
titleString = sprintf('TEST case: Numeric units give the same result as auto');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
autoMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z');
numericMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', Units=0.001);
mmMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', Units='mm');
assert(max(abs(autoMesh.Vertices(:) - numericMesh.Vertices(:)))<1e-12);
assert(max(abs(autoMesh.Vertices(:) - mmMesh.Vertices(:)))<1e-12);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Wrong forward sign turns the car around (X and Y flip)
figNum = 20002;
titleString = sprintf('TEST case: Wrong forward sign turns the car around (X and Y flip)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
rightMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z');
wrongMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='-z', FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

assert(max(abs(wrongMesh.Vertices(:,1) + rightMesh.Vertices(:,1)))<1e-9);
assert(max(abs(wrongMesh.Vertices(:,2) + rightMesh.Vertices(:,2)))<1e-9);
assert(max(abs(wrongMesh.Vertices(:,3) - rightMesh.Vertices(:,3)))<1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: A model in inches is detected by auto units
figNum = 20003;
titleString = sprintf('TEST case: A model in inches is detected by auto units');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

cleanMesh = fcn_CarMesh3D_fillSampleMesh(Style='clean', FigNum=-1);
inchMesh = cleanMesh;
inchMesh.Vertices = cleanMesh.Vertices/0.0254;
vehicleMesh = fcn_CarMesh3D_normalizeMesh(inchMesh);
assert(abs(vehicleMesh.NormalizeInfo.MetersPerFileUnit - 0.0254)<1e-15);
cleanVertices = fcn_INTERNAL_recenter(cleanMesh.Vertices);
assert(max(abs(vehicleMesh.Vertices(:) - cleanVertices(:)))<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: An already-normalized mesh is unchanged except for centering
figNum = 20004;
titleString = sprintf('TEST case: An already-normalized mesh is unchanged except for centering');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

cleanMesh = fcn_CarMesh3D_fillSampleMesh(Style='clean', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(cleanMesh);
assert(isequal(vehicleMesh.NormalizeInfo.RotationMatrix, eye(3)));
assert(vehicleMesh.NormalizeInfo.MetersPerFileUnit==1);
cleanVertices = fcn_INTERNAL_recenter(cleanMesh.Vertices);
assert(max(abs(vehicleMesh.Vertices(:) - cleanVertices(:)))<1e-12);

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

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=[]);
assert(isequal(vehicleMesh.Frame,'ISO8855'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=-1);
assert(isequal(vehicleMesh.Frame,'ISO8855'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

messyMesh = fcn_CarMesh3D_fillSampleMesh(Style='messy', FigNum=-1);

Niterations = 200;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=-1);
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
        vehicleMesh = fcn_CarMesh3D_normalizeMesh(messyMesh, UpAxis='+y', ForwardAxis='+z', FigNum=[]);
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
title('fcn_CarMesh3D_normalizeMesh: time per call','Interpreter','none');
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

%% FAIL case: Up and forward on the same axis
if 1==0
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh, UpAxis='+y', ForwardAxis='-y');
end

%% FAIL case: Unreadable axis string
if 1==0
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh, UpAxis='up');
end

%% FAIL case: Unknown units
if 1==0
    vehicleMesh = fcn_CarMesh3D_normalizeMesh(fcn_CarMesh3D_fillSampleMesh, Units='ft');
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

%% fcn_INTERNAL_recenter
function vertices = fcn_INTERNAL_recenter(vertices)
% Centers vertices in X and Y and puts the lowest point at Z = 0, the
% same way fcn_CarMesh3D_normalizeMesh does
minValues = min(vertices,[],1);
maxValues = max(vertices,[],1);
vertices = vertices - [(minValues(1)+maxValues(1))/2, (minValues(2)+maxValues(2))/2, minValues(3)];
end % Ends fcn_INTERNAL_recenter
