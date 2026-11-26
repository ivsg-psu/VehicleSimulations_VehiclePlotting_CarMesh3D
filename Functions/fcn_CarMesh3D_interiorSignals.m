function interiorKinds = fcn_CarMesh3D_interiorSignals(options)
% fcn_CarMesh3D_interiorSignals

% The interior lights a vehicle can switch: the fields of plotVehicle's
% InteriorSignals, a structure of its own beside Signals, so the exterior
% lamp-to-function matrix stays as it is (Sean, 2026-11-26 17:08; the
% survey: Documentation_CarMesh3D_lampSignalsSurvey.md, section 2). One
% list in one place, as fcn_CarMesh3D_lampSignals is for the exterior.
%
% Interior lights are not signals to other road users; they show only at
% night through the glass. Nothing is lit by them yet: no interior faces
% are labeled as interior lamps.
%
% FORMAT:
%
%       interiorKinds = fcn_CarMesh3D_interiorSignals((FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      interiorKinds: a structure array, one element per interior signal,
%      with fields
%           Name: the field's name in InteriorSignals ('Dome', ...)
%           Label: its name in words
%           Values: 'on/off' (true or false) or '0 to 1' (dimming)
%           Lamps: the interior lamp kinds it would light
%           Description: what it means, for tooltips
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_interiorSignals.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_interiorSignals
%   % * First write (the lamp-signals survey, tier 1 to 3 and interior)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_interiorSignals
%   % * Interior lamp kinds labeled on the meshes, and lit by these



arguments
    options.FigNum = []   % Not used; -1 for fast mode
end

%% Main code starts here

% EDIT HERE: the interior signals. DoorOpen is the same signal as the
% exterior one of that name (one door switch lights both the puddle lamps
% outside and the courtesy lamps inside).
interiorList = {
    % Name          Label                  Values      Lamps                               Description
    'Dome',         'Dome light',          'on/off',   'domeLamp',                         'The main ceiling light (on with a door open, or by its switch)'
    'MapLeft',      'Map light, left',     'on/off',   'mapLamp',                          'The left front reading light'
    'MapRight',     'Map light, right',    'on/off',   'mapLamp',                          'The right front reading light'
    'ReadingRear',  'Rear reading lights', 'on/off',   'readingLamp',                      'The rear reading lights'
    'DoorOpen',     'Door open',           'on/off',   'courtesyLamp',                     'A door open: the courtesy lamps in the doors and sills (and the puddle lamps outside)'
    'Footwell',     'Footwell lights',     '0 to 1',   'footwellLamp',                     'The footwell lights (often part of the ambient lighting)'
    'Ambient',      'Ambient lighting',    '0 to 1',   'ambientLamp',                      'Accent strips in the dash, doors and console (the color is the vehicle''s setting)'
    'Instruments',  'Instruments',         '0 to 1',   'instrumentLamp, displayLamp',      'The instrument cluster and screens (dimmed at night)'
    'TrunkOpen',    'Trunk open',          'on/off',   'trunkLamp',                        'The trunk or cargo-area light, on while it is open'
    'GloveBoxOpen', 'Glove box open',      'on/off',   'gloveBoxLamp',                     'The glove box light'
    };

interiorKinds = struct('Name', interiorList(:,1), 'Label', interiorList(:,2), 'Values', interiorList(:,3), ...
    'Lamps', interiorList(:,4), 'Description', interiorList(:,5));

end % Ends main function
