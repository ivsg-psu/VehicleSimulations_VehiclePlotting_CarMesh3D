% script_test_fcn_CarMesh3D_lampBulbs.m
% Tests fcn_CarMesh3D_lampBulbs

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampBulbs
%   % * First write (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampBulbs
%   % * (none yet)

%% Set up the workspace
close all;

%% TEST case: the list: unique names, every field, lumens per filament, a source each
lampBulbs = fcn_CarMesh3D_lampBulbs(FigNum=-1);
names = {lampBulbs.Name};
assert(numel(unique(names)) == numel(names), 'Each bulb type once');
for thisBulb = lampBulbs'
    assert(numel(thisBulb.Lumens) == numel(thisBulb.Filaments) && numel(thisBulb.Watts) == numel(thisBulb.Filaments), ...
        'Lumens and watts for each filament: %s', thisBulb.Name);
    assert(all(thisBulb.Lumens > 0) && issorted(thisBulb.Lumens, 'descend'), 'Brightest filament first: %s', thisBulb.Name);
    assert(startsWith(thisBulb.Source, 'https://') && ~isempty(thisBulb.Accessed), 'A source and its date: %s', thisBulb.Name);
    assert(ismember(thisBulb.Color, {'white', 'amber', 'red'}), 'A color: %s', thisBulb.Name);
end
otherNames = [lampBulbs.OtherNames];
assert(numel(unique(otherNames)) == numel(otherNames), 'A trade number names one bulb only');
assert(all(ismember({'H4', 'HB2', 'H11', 'W21/5W', 'W16W', 'WY21W'}, names)), 'The 2009 Fit''s bulbs');

%% TEST case: the cube-root rule
[~, tailValue] = fcn_CarMesh3D_lampBulbs(Bulb='W21/5W', Filament='tail', FigNum=-1);
assert(abs(tailValue - (35/440)^(1/3)) < 1e-12 && abs(tailValue - 0.43) < 0.005, 'The tail filament: 0.43');
[~, stopValue] = fcn_CarMesh3D_lampBulbs(Bulb='W21/5W', Filament='stop', FigNum=-1);
assert(stopValue == 1, 'The brightest filament is 1');
[~, lowValue] = fcn_CarMesh3D_lampBulbs(Bulb='9003', Filament='low', FigNum=-1);
assert(abs(lowValue - (980/1590)^(1/3)) < 1e-12, 'By its trade number: 9003 is the HB2');
[~, oneValue] = fcn_CarMesh3D_lampBulbs(Bulb='W16W', FigNum=-1);
assert(oneValue == 1, 'A one-filament bulb, no filament named');
[~, unknownValue] = fcn_CarMesh3D_lampBulbs(Bulb='not a bulb', FigNum=-1);
assert(isnan(unknownValue), 'An unknown bulb: NaN');
[~, unknownValue] = fcn_CarMesh3D_lampBulbs(Bulb='H4', Filament='fog', FigNum=-1);
assert(isnan(unknownValue), 'An unknown filament: NaN');
[~, unknownValue] = fcn_CarMesh3D_lampBulbs(Bulb='H4', FigNum=-1);
assert(isnan(unknownValue), 'A two-filament bulb needs its filament named');

fprintf(1, 'script_test_fcn_CarMesh3D_lampBulbs: all tests passed\n');
