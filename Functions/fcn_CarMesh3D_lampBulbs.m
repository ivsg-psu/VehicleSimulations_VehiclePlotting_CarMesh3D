function [lampBulbs, brightness] = fcn_CarMesh3D_lampBulbs(options)
% fcn_CarMesh3D_lampBulbs

% The standard bulb types, with the light (lumens) each filament gives
% and where that figure was found, so a lamp-to-function (L2F) cell can be
% worked out from the bulb rather than guessed (Sean, 2026-11-26 21:19:
% "Yes, And yes to the cube root"). A bulb's watts are not its light: the
% 21/5 W stop/tail bulb gives 440 and 35 lumens, not 21:5.
%
% A cell's value is how bright the lamp looks, from 0 to 1, against the
% same lamp at its brightest. The eye sees light roughly as its cube root
% (Stevens' power law for brightness, exponent about 1/3), so
%
%       value = (filament lumens / brightest filament's lumens)^(1/3)
%
% so the tail filament of a 21/5 W bulb is (35/440)^(1/3) = 0.43, and an
% HB2 low beam (980/1590)^(1/3) = 0.85. One list, in one place, as
% fcn_CarMesh3D_lampTypes is for the lamp kinds.
%
% FORMAT:
%
%       [lampBulbs, brightness] = fcn_CarMesh3D_lampBulbs((Bulb=name),...
%           (Filament=name), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Bulb: a bulb type's name ('W21/5W'), to get the brightness of one
%      of its filaments. Default '' (none).
%
%      Filament: that filament's name ('tail'); empty for a one-filament
%      bulb. Default ''.
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      lampBulbs: a structure array, one element per bulb type, with fields
%           Name: the type ('H4', 'HB2', 'W21/5W', ...)
%           OtherNames: US trade numbers of the same bulb ('9003', '7443');
%               only exact equivalents (the US 194 is not a W5W: it is
%               about 3.8 W, and dimmer)
%           Filaments: the filaments' names ({'high','low'}; {'main'}
%               for a one-filament bulb)
%           Lumens: each filament's light, in the same order
%           Watts: each filament's rated power, in the same order
%           Color: 'white', 'amber' or 'red' (the bulb's own glass)
%           Tolerance: the stated tolerance, as text ('±15%')
%           Source: where the lumens were found (a link)
%           Accessed: when it was read (yyyy-MM-dd)
%           Note: anything to know
%
%      brightness: with Bulb given, the filament's value from 0 to 1 by
%      the cube-root rule above; NaN if the bulb or filament is unknown.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       [~, tailValue] = fcn_CarMesh3D_lampBulbs(Bulb='W21/5W', Filament='tail');
%
%       See the script: script_test_fcn_CarMesh3D_lampBulbs.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampBulbs
%   % * First write (the 2009 Fit's bulbs, from Honda's bulb table, and
%   %   % their lumens from the bulb makers' data sheets and ECE R37)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampBulbs
%   % * The US 194-family wedge (the Fit's 3.8 W amber parking/side
%   %   % marker): its lumens not found yet
%   % * LED lamps have no bulb rating: their values stay the defaults, or
%   %   % come from the legal ratios (a stop lamp at least 3 times its tail
%   %   % lamp, 5 times near the center: SAE J586 in FMVSS 108)

arguments
    options.Bulb = ''        % A bulb type, for one filament's brightness
    options.Filament = ''    % That filament ('tail', 'low', ...); '' for a one-filament bulb
    options.FigNum = []      % Not used; -1 for fast mode
end

%% Main code starts here

accessed = '2026-11-26';
urlWikipedia = 'https://en.wikipedia.org/wiki/List_of_automotive_light_bulb_types';
urlStern = 'https://mail.danielsternlighting.com/tech/bulbs/bulb_types/bulb_types.html';
urlOsramWedge = 'https://dtsheet.com/doc/1725828/family-data-sheet';
urlOsram921 = 'https://osram.us/ecat/Lamps%20with%20glass%20wedge%20bases-Signal%20lamps-Car%20lighting-Automotive/us/en/GPS01_1057061/ZMP_60984';
urlPhilipsP215 = 'https://www.documents.philips.com/assets/20230217/3c3414ba4c4f48eabf2fafac00a18059.pdf';
urlPhilipsPY21 = 'https://www.documents.philips.com/assets/20230215/4c2a75aa8bc6463ca554afaa006a0a5a.pdf';
urlECE_R5W = 'https://digitallibrary.un.org/record/470392/files/%5BE_ECE_%5DTRANS_WP.29_GRE_2002_36-EN.pdf';

% EDIT HERE: one row per bulb type. Lumens and Watts in the order of the
% filaments, brightest first.
bulbList = {
    % Name      OtherNames             Filaments             Lumens        Watts      Color    Tolerance  Source          Note
    'H4',       {},                    {'high','low'},       [1650 1000],  [60 55],   'white', '±15%',    urlWikipedia,   'ECE nominal luminous flux (R37)'
    'HB2',      {'9003'},              {'high','low'},       [1590 980],   [60 55],   'white', '',        urlStern,       'the DOT-marked version of the H4 (a lighting maker''s table)'
    'H11',      {},                    {'main'},             1350,         55,        'white', '±10%',    urlWikipedia,   'ECE nominal luminous flux (R37)'
    'W21/5W',   {'7443'},              {'stop','tail'},      [440 35],     [21 5],    'white', '±15/±20%', urlOsramWedge, 'Osram 7515 (W21/5W) data sheet'
    'P21/5W',   {},                    {'stop','tail'},      [440 35],     [21 5],    'white', '',        urlPhilipsP215, 'Philips Vision P21/5W data sheets (440 lm; the LongLife sheet gives the 35 lm filament)'
    'W21W',     {'7440'},              {'main'},             460,          21,        'white', '±15%',    urlOsramWedge,  'Osram 7505 (W21W) data sheet'
    'WY21W',    {'7440NA'},            {'main'},             280,          21,        'amber', '±20%',    urlOsramWedge,  'Osram 7504 (amber 21 W) data sheet; Philips PY21W also 280 lm'
    'PY21W',    {},                    {'main'},             280,          21,        'amber', '',        urlPhilipsPY21, 'Philips PY21W data sheet'
    'W16W',     {'921'},               {'main'},             310,          16,        'white', '±20%',    urlOsram921,    'Osram 921 (W16W) data sheet'
    'W5W',      {},                    {'main'},             50,           5,         'white', '±20%',    urlOsramWedge,  'Osram 2825 (W5W) data sheet'
    'R5W',      {},                    {'main'},             50,           5,         'white', '±20%',    urlECE_R5W,     'ECE R37 sheet R5W (objective luminous flux)'
    'W3W',      {},                    {'main'},             22,           3,         'white', '±30%',    urlOsramWedge,  'Osram 2821 (W3W) data sheet'
    };

lampBulbs = struct('Name', bulbList(:,1), 'OtherNames', bulbList(:,2), 'Filaments', bulbList(:,3), ...
    'Lumens', bulbList(:,4), 'Watts', bulbList(:,5), 'Color', bulbList(:,6), 'Tolerance', bulbList(:,7), ...
    'Source', bulbList(:,8), 'Accessed', accessed, 'Note', bulbList(:,9));

brightness = NaN;
bulbName = char(options.Bulb);
if ~isempty(bulbName)
    index = find(strcmpi({lampBulbs.Name}, bulbName), 1);
    if isempty(index)
        index = find(cellfun(@(names) any(strcmpi(names, bulbName)), {lampBulbs.OtherNames}), 1);
    end
    if ~isempty(index)
        thisBulb = lampBulbs(index);
        filamentName = char(options.Filament);
        if isempty(filamentName) && isscalar(thisBulb.Lumens)
            filamentIndex = 1;
        else
            filamentIndex = find(strcmpi(thisBulb.Filaments, filamentName), 1);
        end
        if ~isempty(filamentIndex)
            brightness = (thisBulb.Lumens(filamentIndex)/max(thisBulb.Lumens))^(1/3);
        end
    end
end

end % Ends main function
