function lampTypes = fcn_CarMesh3D_lampTypes(options) %#ok<INUSD>
%% fcn_CarMesh3D_lampTypes
% The list of lamp types a CarMesh3D mesh can have, in one place: each
% type's name (as stored in a mesh's LabelLampNames), its name for people,
% its colors, and what switches it on. Every function that needs to know
% the lamp types reads them from here, so a new type is added once.
%
% The order matters: a mesh stores its light types by number (LabelFaceLamp
% is an index into LabelLampNames), and older meshes have the first five
% or six types in this order. New types are only ever added at the end.
%
% FORMAT:
%
%       lampTypes = fcn_CarMesh3D_lampTypes((FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used (nothing is plotted). If set to -1, input checking
%      is skipped (fast mode). Default [].
%
% OUTPUTS:
%
%      lampTypes: a structure array, one element per lamp type, in the
%      fixed order, with fields:
%           Name: the type's name in a mesh's LabelLampNames, such as
%               'headlamp' or 'fogLamp'
%           Label: its name for people: what the part IS, never what
%               switches it (rule P6), such as 'Fog lamp'
%           FaceColor: 1 x 3, the plain (unlit) color a face gets when it
%               is labeled as this type and no color is given
%           LabelColor: 1 x 3, its color in the label views (the false
%               colors that show each label clearly)
%           LitColor: 1 x 3, its color when lit; empty for a type that
%               glows in its own face colors made brighter (reflectors,
%               marker lamps, warning lamps: these come in amber, red or
%               white)
%           SwitchedBy: the light state (of fcn_CarMesh3D_plotVehicle's
%               Signals) that lights it, in words
%           SwitchedByStates: the same, as the Signals field names
%               that light it (any one of them on lights it), for the
%               types that fcn_CarMesh3D_plotVehicle switches from this
%               list: fog, reflector, licenseplate, marker and warning.
%               (The first six types have their own rules: the beams, and
%               the tail lamps' brake.) How a lamp is switched differs
%               from vehicle to vehicle (fog lamps are switched in 3 to 6
%               ways among makers: Sean, 23:23), so a vehicle can give its
%               own: a mesh field SignalLampSwitching, a structure with a field
%               per lamp type, such as
%                   vehicleMesh.SignalLampSwitching.fog = {'Fog','HighBeam'};
%               replaces this default for that vehicle
%           Sources: a cell array of the key sources for the type's
%               switching (what turns it on), each as text with a link;
%               empty where none is recorded yet (Sean, 23:24)
%           NameRule: a regular expression; a light whose material or
%               group name matches it is given this type by
%               fcn_CarMesh3D_labelParts (the rules are tried in the
%               order of the RuleOrder field, smallest first)
%           RuleOrder: the order its NameRule is tried in
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       lampTypes = fcn_CarMesh3D_lampTypes();
%       names = {lampTypes.Name};
%
%       See the script: script_test_fcn_CarMesh3D_lampTypes.m for a full
%       test suite.
%
% This function was written on 2026_11_23 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampTypes
%   % * First write of the code: the six lamp types the meshes already
%   %   % have (headlight, turn signal, running, tail, backup, high beam),
%   %   % and five new ones (Sean, task 8; Q24 (A), Q25 (A), 23:19): fog
%   %   % lamps (switched by their own Fog state), reflectors (glow
%   %   % by the outside light, Reflectors, 0 to 1), the license plate
%   %   % lamp (lit with the tail lamps), marker lamps (lit with the
%   %   % running lights) and warning lamps (flashing with the hazards)
%   % * Sources: the key source for each type's switching, as a link
%   %   % (Sean, 23:24); FMVSS No. 108 for the US
%   % * SwitchedByStates, and a vehicle's own SignalLampSwitching: how a lamp is
%   %   % switched differs by maker (Sean, 23:23), so it is easy to edit
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_lampTypes
%   % * Labels name the part, not the function that switches it (Sean,
%   %   % 00:35 to 00:46; rule P6, README "Position, meaning, and function"):
%   %   % 'Headlamp bulb' in place of 'Low beams (headlights)', and so on;
%   %   % then 'Headlamp', 'Fog lamp' ... (Sean's style guide, 01:47: a lamp
%   %   % is the whole device that lights; a bulb is only its light source;
%   %   % Q83 (A))
%   %   % The Names (the keys saved in meshes) are unchanged
%   % * The lamp keys renamed to lamp names (Q92 (A), Sean 09:47; no
%   %   % aliases, Sean 10:36): headlamp, turnSignalLamp, runningLamp,
%   %   % tailBrakeLamp, backupLamp, highBeamLamp, fogLamp, reflector,
%   %   % licensePlateLamp, markerLamp, warningLamp. Saved data migrated once
%   %   % (Claude's tools\zzQ92_migrate.m)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampTypes
%   % * (Someday, Sean 23:23) A simple window that shows a novice each
%   %   % lamp of a vehicle and lets them pick what switches it, filling
%   %   % the vehicle's SignalLampSwitching quickly
%   % * The first six types' rules (beams, brake) could move here too

% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call.
arguments
    options.FigNum = []               % Not used; -1 for fast mode
end

%% Debugging and Input checks
% (this function has no inputs to check)

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

%                Name           Label                        FaceColor           LabelColor          LitColor            SwitchedBy                                  NameRule                                           RuleOrder
lampTable = {...
    'headlamp',   'Headlamp',                     [0.90 0.90 0.85],   [1.00 0.90 0.10],   [1.00 0.96 0.78],   'LowBeam (or HighBeam)',                      'head|front',                                      11;
    'turnSignalLamp',  'Turn-signal lamp',             [0.85 0.55 0.15],   [1.00 0.50 0.00],   [1.00 0.55 0.00],   'TurnLeft, TurnRight, or Hazards',          'turn|indicator|blinker|signal',                   4;
    'runningLamp',     'Running lamp (DRL)',           [0.90 0.90 0.85],   [0.00 0.90 0.90],   [1.00 0.98 0.90],   'Running',                                  'drl|running|daytime',                             8;
    'tailBrakeLamp',        'Tail/brake lamp',              [0.55 0.05 0.05],   [0.90 0.00 0.00],   [0.70 0.04 0.04],   'Tail, or Brake for bright',                 'tail|brake|stop|rear',                            10;
    'backupLamp',      'Backup (reverse) lamp',        [0.85 0.85 0.85],   [0.10 0.75 0.10],   [1.00 1.00 1.00],   'Backup',                                   'reverse|backup|back_up',                          7;
    'highBeamLamp',    'High-beam lamp (separate)',    [0.92 0.92 0.90],   [0.30 0.55 1.00],   [1.00 1.00 1.00],   'HighBeam',                                 'high.?beam|hi.?beam|main.?beam',                  1;
    'fogLamp',         'Fog lamp',                     [0.92 0.92 0.88],   [0.55 1.00 0.55],   [1.00 0.97 0.85],   'Fog',                                'fog',                                                 2;
    'reflector',   'Reflector (no lamp)',          [0.60 0.08 0.05],   [1.00 0.60 0.80],   [],                 'Reflectors (the outside light, 0 to 1)',   'reflector|reflex|retro',                          3;
    'licensePlateLamp','License-plate lamp',           [0.90 0.90 0.85],   [0.75 0.55 1.00],   [1.00 1.00 0.95],   'Tail (lit whenever the tail lamps are)',   'licen[cs]e|number.?plate|plate.?l',               5;
    'markerLamp',      'Marker lamp',                  [0.85 0.55 0.15],   [1.00 0.78 0.35],   [],                 'Running (lit with the running lights)',    'marker|side.?light|clearance',                    6;
    'warningLamp',     'Warning lamp (beacon)',        [0.85 0.55 0.15],   [0.60 0.00 0.30],   [],                 'Hazards (flash them in your loop)',        'warning|beacon|strobe|hazard|emergency',          9};

lampTypes = cell2struct(lampTable, {'Name','Label','FaceColor','LabelColor','LitColor','SwitchedBy','NameRule','RuleOrder'}, 2);
lampTypes = lampTypes(:);

% The Signals that light each type switched from this list (any one
% on lights it). EDIT HERE to change a default for every vehicle; give a
% vehicle its own with the mesh field SignalLampSwitching (see above)
switchedByStates = struct( ...
    'fogLamp',          {{'Fog'}}, ...
    'reflector',    {{'Reflectors'}}, ...
    'licensePlateLamp', {{'Tail'}}, ...
    'markerLamp',       {{'Running'}}, ...
    'warningLamp',      {{'Hazards'}});
% The key sources for each type's switching (EDIT HERE as sources are
% found; Sean, 23:24). US rules: FMVSS No. 108, 49 CFR 571.108
fmvss108 = 'https://www.ecfr.gov/current/title-49/subtitle-B/chapter-V/part-571/subpart-B/section-571.108';
sources = struct( ...
    'turnSignalLamp',   {{['FMVSS No. 108, S7.1 Turn signal lamps; S6.1.5.1 Hazard warning signal (both turn signals flash): ' fmvss108]}}, ...
    'tailBrakeLamp',         {{['FMVSS No. 108, S7.8 Taillamps and S7.3 Stop lamps: ' fmvss108]}}, ...
    'backupLamp',       {{['FMVSS No. 108, S7.5 Backup lamps (lit in reverse gear): ' fmvss108]}}, ...
    'runningLamp',      {{['FMVSS No. 108, S7.10 Daytime running lamps: ' fmvss108]}}, ...
    'reflector',    {{['FMVSS No. 108, S7.11 Reflex reflectors (no power: lit by outside light): ' fmvss108]}}, ...
    'licensePlateLamp', {{['FMVSS No. 108, S7.7 License plate lamps (activated with the taillamps): ' fmvss108]}}, ...
    'markerLamp',       {{['FMVSS No. 108, S7.4 Side marker lamps (activated with the taillamps and parking lamps): ' fmvss108]}}, ...
    'warningLamp',      {{['FMVSS No. 108, S6.1.5.1 Hazard warning signal: ' fmvss108]}}, ...
    'fogLamp',          {{'(none yet) Front fog lamps are optional in FMVSS No. 108; makers switch them in several ways (Sean, 23:23)'}});
for ith_type = 1:numel(lampTypes)
    lampTypes(ith_type).Sources = {};
    if isfield(sources, lampTypes(ith_type).Name)
        lampTypes(ith_type).Sources = sources.(lampTypes(ith_type).Name);
    end
    lampTypes(ith_type).SwitchedByStates = {};
    if isfield(switchedByStates, lampTypes(ith_type).Name)
        lampTypes(ith_type).SwitchedByStates = switchedByStates.(lampTypes(ith_type).Name);
    end
end

%% Any debugging?
% (nothing to plot)

end % Ends main function
