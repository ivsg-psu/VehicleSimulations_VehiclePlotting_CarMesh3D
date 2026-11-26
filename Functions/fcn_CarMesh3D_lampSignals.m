function signalKinds = fcn_CarMesh3D_lampSignals(options)
% fcn_CarMesh3D_lampSignals

% The signals that light a vehicle's lamps: the columns of the
% lamp-to-function (L2F) matrix (layer 3, function;
% Documentation_CarMesh3D_GUIdesign_lampFunctions.md, section 4). One list
% in one place: the matrix, its file (lampFunctions_<ID>.csv), its window
% and fcn_CarMesh3D_plotVehicle all read it from here.
%
% Each signal is a name (a column of the matrix and of the file), a label
% for people, and what it means. Hazards is not a signal (Q80 (A)): it is
% the two turn signals switched together, and flashing is time, which is
% not part of the mesh.
%
% FORMAT:
%
%       signalKinds = fcn_CarMesh3D_lampSignals((FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      signalKinds: a structure array, one element per signal, in the order of
%      the matrix's columns, with fields
%           Name: the column's name ('LowBeam', 'TurnLeft', ...)
%           Label: its name in words ('Low beam', 'Left turn', ...)
%           Description: what it means, for tooltips
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampSignals.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampSignals
%   % * First write (the lamp-functions plan, item 3)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampSignals
%   % * New signals from the window's menu (Someday, section 8 of the
%   %   % design file: a work light, a beacon, a light bar)



arguments
    options.FigNum = []   % Not used; -1 for fast mode
end

%% Main code starts here

% EDIT HERE: the signals, in the order of the matrix's columns. A new
% signal is one more line; the file of a vehicle made before it reads it
% as 0 (off) for every lamp.
signalList = {
    % Name          Label                        Description
    'LowBeam',      'Low beam',                  'The headlamps on, dipped'
    'HighBeam',     'High beam',                 'The headlamps on, full'
    'Running',      'Running',                   'The daytime running lights'
    'Parking',      'Parking',                   'Parking lights (the vehicle stopped, lights on)'
    'TurnLeft',     'Left turn',                 'The left turn signal (lit; flashing is the driver''s loop)'
    'TurnRight',    'Right turn',                'The right turn signal (lit; flashing is the driver''s loop)'
    'Tail',         'Tail',                      'The tail lamps on (with the headlamps or parking lights)'
    'Brake',        'Brake',                     'The brake pedal pressed'
    'Backup',       'Backup',                    'Reverse gear'
    'Fog',          'Fog',                       'The fog lights switched on'
    'Reflectors',   'Reflectors',                'Outside light reaching the reflectors (another vehicle''s lamps)'
    % (tier 2: every passenger vehicle; tier 3: special vehicles and
    % equipment. Documentation_CarMesh3D_lampSignalsSurvey.md, section 4;
    % Sean, 2026-11-26 17:08: all three tiers now)
    'RearFog',        'Rear fog',                'The rear fog lamps (red, brighter than the tail lamps; UN R48)'
    'EmergencyBrake', 'Emergency brake',         'Hard braking: the stop lamps flash (emergency stop signal; switched by the vehicle)'
    'DoorOpen',       'Door open',               'A door open: the puddle and courtesy lamps'
    'Cargo',          'Cargo',                   'The cargo and bed lamps (for loading)'
    'Automated',      'Automated',               'An automated driving system is driving: the turquoise ADS marker lamps (SAE J3134)'
    'CorneringLeft',  'Cornering left',          'The left cornering lamp (lit steady while turning left at low speed)'
    'CorneringRight', 'Cornering right',         'The right cornering lamp (lit steady while turning right at low speed)'
    'Welcome',        'Welcome',                 'Approach and unlock lighting (puddle lamps, lit logo)'
    'Charging',       'Charging',                'Plugged in and charging: the charge-port status lamps'
    'Beacon',         'Beacon',                  'Amber warning beacons and light bars (tow, utility, maintenance trucks)'
    'Work',           'Work',                    'Work lamps (spot and flood lamps; not for driving on the road)'
    'EmergencyRed',   'Emergency red',           'Red emergency lamps (police, fire, ambulance: by state law)'
    'EmergencyBlue',  'Emergency blue',          'Blue emergency lamps (police: by state law)'
    'EmergencyWhite', 'Emergency white',         'White emergency lamps and flashers'
    'EmergencyAmber', 'Emergency amber',         'Amber emergency lamps (often to the rear)'
    'EmergencyGreen', 'Emergency green',         'Green lamps (volunteer firefighters, command posts: by state law)'
    'SchoolAmber',    'School amber',            'School bus: the amber lamps (about to stop; switched by the driver)'
    'SchoolRed',      'School red',              'School bus: the red lamps and the stop arm (stopped, door open)'
    };

signalKinds = struct('Name', signalList(:,1), 'Label', signalList(:,2), 'Description', signalList(:,3));

end % Ends main function
