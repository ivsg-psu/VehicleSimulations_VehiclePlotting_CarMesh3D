% script_test_fcn_CarMesh3D_fillVehicleSpec.m
% Tests fcn_CarMesh3D_fillVehicleSpec
% Shows how to enter published vehicle data.

% REVISION HISTORY:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillVehicleSpec
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillVehicleSpec
%   % * Renamed from script_CarMesh3D_fillVehicleSpec: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillVehicleSpec
%   % * Tests different front and rear tires, and the engine type

% TO-DO:
%
% 2026_11_18 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillVehicleSpec
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

%% DEMO case: Generic sedan preset, with a dimensioned plot
figNum = 10001;
titleString = sprintf('DEMO case: Generic sedan preset, with a dimensioned plot');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleSpec));

% Check variable sizes
assert(isscalar(vehicleSpec.OverallLength));

% Check variable values
assert(isequal(vehicleSpec.Units,'m'));
assert(abs(vehicleSpec.OverallLength - 4.80)<1e-12);
% 225/45R17: 2*225*0.45 mm + 17 in = 202.5 mm + 431.8 mm = 634.3 mm
assert(abs(vehicleSpec.TireDiameter - 0.6343)<1e-9);
% Rear overhang = 4.80 - 2.80 - 0.95
assert(abs(vehicleSpec.RearOverhang - 1.05)<1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Typing in values for a vehicle, as a student would
figNum = 10002;
titleString = sprintf('DEMO case: Typing in values for a vehicle, as a student would');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% Example values only. For real vehicles, cite the Source.
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(...
    Name='Example compact car',...
    OverallLength=4.55,...
    OverallWidth=1.80,...
    OverallHeight=1.42,...
    Wheelbase=2.70,...
    TrackFront=1.55,...
    TireSize='P205/55R16',...
    FrontOverhang=0.88,...
    BodyColor=[0.8 0.1 0.1],...
    Source='Example values for testing',...
    FigNum=figNum);

sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(vehicleSpec));
assert(ischar(vehicleSpec.Name));

% Check variable values
assert(isequal(vehicleSpec.TrackRear, vehicleSpec.TrackFront)); % Rear defaults to front
% 205/55R16: 2*205*0.55 mm + 16 in = 225.5 mm + 406.4 mm = 631.9 mm
assert(abs(vehicleSpec.TireDiameter - 0.6319)<1e-9);
assert(abs(vehicleSpec.RearOverhang - (4.55-2.70-0.88))<1e-9);

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

%% TEST case: Values given by the user override the preset
figNum = 20001;
titleString = sprintf('TEST case: Values given by the user override the preset');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', OverallLength=5.0, Name='Long sedan');

assert(abs(vehicleSpec.OverallLength - 5.0)<1e-12);
assert(abs(vehicleSpec.Wheelbase - 2.80)<1e-12); % From the preset
assert(isequal(vehicleSpec.Name,'Long sedan'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: TireDiameter given directly takes priority over TireSize
figNum = 20002;
titleString = sprintf('TEST case: TireDiameter given directly takes priority over TireSize');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(TireSize='225/45R17', TireDiameter=0.70);
assert(abs(vehicleSpec.TireDiameter - 0.70)<1e-12);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Tire sizes with spaces and letters are read
figNum = 20003;
titleString = sprintf('TEST case: Tire sizes with spaces and letters are read');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

spec1 = fcn_CarMesh3D_fillVehicleSpec(TireSize='225/45ZR17');
spec2 = fcn_CarMesh3D_fillVehicleSpec(TireSize='225/45 R17');
spec3 = fcn_CarMesh3D_fillVehicleSpec(TireSize="225/45R17"); % string type
assert(abs(spec1.TireDiameter - 0.6343)<1e-9);
assert(abs(spec2.TireDiameter - 0.6343)<1e-9);
assert(abs(spec3.TireDiameter - 0.6343)<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: No inputs gives a structure with empty values
figNum = 20004;
titleString = sprintf('TEST case: No inputs gives a structure with empty values');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec;
assert(isempty(vehicleSpec.OverallLength));
assert(isempty(vehicleSpec.TireDiameter));
assert(isempty(vehicleSpec.RearOverhang));
assert(isequal(vehicleSpec.Units,'m'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: SUV preset
figNum = 20005;
titleString = sprintf('TEST case: SUV preset');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSUV', FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
assert(vehicleSpec.OverallHeight > 1.6);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Different front and rear tires; the engine type
figNum = 20006;
titleString = sprintf('TEST case: Different front and rear tires; the engine type');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (a staggered fitment: wider, larger rear tires, as on many sports cars)
staggered = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', TireSize='245/35R19', TireSizeRear='305/30R20', ...
    EngineType='hybrid', HybridEngineType='sparkIgnition', FigNum=figNum);
assert(strcmp(staggered.TireSize, '245/35R19') && strcmp(staggered.TireSizeRear, '305/30R20'));
assert(abs(staggered.TireDiameter - (2*245*0.35/1000 + 19*0.0254)) < 1e-9);
assert(abs(staggered.TireDiameterRear - (2*305*0.30/1000 + 20*0.0254)) < 1e-9);
assert(strcmp(staggered.EngineType, 'hybrid') && strcmp(staggered.HybridEngineType, 'sparkIgnition'));
% (one size: the rear is the front's, even over a preset's)
same = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', TireSize='205/55R16', EngineType='Diesel');
assert(strcmp(same.TireSizeRear, '205/55R16') && same.TireDiameterRear==same.TireDiameter);
assert(strcmp(same.EngineType, 'diesel'));                                        % (standard spelling)
% (a rear diameter given directly)
direct = fcn_CarMesh3D_fillVehicleSpec(TireDiameter=0.65, TireDiameterRear=0.70);
assert(direct.TireDiameterRear==0.70 && isempty(direct.TireSizeRear));
% (a hybrid's engine only for a hybrid)
flagFailed = false;
try
    fcn_CarMesh3D_fillVehicleSpec(EngineType='diesel', HybridEngineType='wankel');
catch
    flagFailed = true;
end
assert(flagFailed);

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

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=[]);

assert(isstruct(vehicleSpec));
assert(abs(vehicleSpec.TireDiameter - 0.6343)<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);

assert(isstruct(vehicleSpec));
assert(abs(vehicleSpec.TireDiameter - 0.6343)<1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

% (no setup needed)

Niterations = 200;

% Normal mode
tic;
for ith_test = 1:Niterations
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
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
        vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=[]);
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
title('fcn_CarMesh3D_fillVehicleSpec: time per call','Interpreter','none');
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

%% FAIL case: Unknown preset name
if 1==0
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='sportsCar');
end

%% FAIL case: Negative length
if 1==0
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(OverallLength=-4.5);
end

%% FAIL case: Wheelbase longer than the vehicle
if 1==0
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(OverallLength=2.5, Wheelbase=2.8);
end

%% FAIL case: Unreadable tire size
if 1==0
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(TireSize='big tires');
end

%% FAIL case: Body color out of range
if 1==0
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(BodyColor=[255 0 0]);
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
