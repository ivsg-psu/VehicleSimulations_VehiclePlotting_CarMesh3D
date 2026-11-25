function checkList = fcn_CarMesh3D_reviewChecks(options)
% fcn_CarMesh3D_reviewChecks
% The list of the Model Reviewer's checks, in ONE place: each check's key,
% its title, whether it is required or optional, and what it checks. The
% reviewer (fcn_CarMesh3D_reviewVehicle) and the Review section of Shared
% GUI settings (fcn_CarMesh3D_makeSettingsPanel) both build from this list,
% so they cannot disagree (rule G27: one list in one place).
%
% A REQUIRED check must be answered before a vehicle is approved; it
% cannot be turned off. An OPTIONAL check can be turned off in Shared GUI
% settings (Review), for every vehicle, until turned back on (Sean,
% 2026-11-24 16:14: "This will let the user permanently shut off requested
% reviews for large numbers of models that they trust"). A check turned off
% is recorded in the vehicle's review as skipped, not left blank.
%
% FORMAT:
%
%       checkList = fcn_CarMesh3D_reviewChecks((TurnedOff=keys), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TurnedOff: the keys of the optional checks turned off, as a cell
%      array of keys (such as {'levels'}); [] (default) for the user's own
%      setting, the MATLAB preference CarMesh3D/ReviewChecksOff. A
%      required check's key here is ignored (it cannot be turned off).
%
%      FigNum: if given (and not -1), the list is printed. If -1, input
%      checking is skipped (fast mode) and nothing is printed.
%
% OUTPUTS:
%
%      checkList: a table with one row per check, in the reviewer's order:
%           Key: the check's key ('orientation', 'dimensions', ...)
%           Title: its title in the reviewer ('Orientation', ...)
%           Required: true for a required check
%           On: false for an optional check turned off
%           Built: false for a check listed here but not yet in the
%               reviewer (its row in Shared GUI settings says so)
%           Description: what it checks, in a few words (the tooltip)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       checkList = fcn_CarMesh3D_reviewChecks();
%       optionalKeys = checkList.Key(~checkList.Required);
%
%       See the script: script_test_fcn_CarMesh3D_reviewChecks.m for a
%       full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewChecks
%   % * First write (Sean, 16:14: required and optional review checks;
%   %   % the shared-panels design file, section 5): the list proposed
%   %   % there, with the five animation checks (Lights, Body, Steering,
%   %   % Wheels, Drive) as optional. The two new checks (interior objects,
%   %   % photos) are listed as optional and not built, until Sean marks
%   %   % them.

% TO-DO:
%
% (Sean's marks on the required and optional list: the design file
% Documentation_CarMesh3D_GUIdesign_sharedPanels.md, section 5)

arguments
    options.TurnedOff = []   % Keys of optional checks turned off; [] for the preference
    options.FigNum = []      % Prints the list if given; -1 for fast mode
end

%% Debugging and Input checks
flag_max_speed = 0;
if isequal(options.FigNum,-1)
    flag_check_inputs = 0;
    flag_max_speed = 1;
else
    flag_check_inputs = 1;
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS)
        flag_check_inputs = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

if 0==flag_max_speed && flag_check_inputs
    if ~isempty(options.TurnedOff) && ~iscellstr(options.TurnedOff) && ~isstring(options.TurnedOff)
        error('CarMesh3D:badInput', 'TurnedOff must be a cell array of check keys, or [].');
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDIT HERE: the checks, in the reviewer's order.
%   Key          Title                Required  Built  Description
rows = {
    'orientation', 'Orientation',      true,  true,  'The front and up arrows point the right way';
    'dimensions',  'Dimensions',       true,  true,  'The measured sizes match the vehicle''s data';
    'labels',      'Labels',           true,  true,  'Each label is on the right faces (with the painter)';
    'compare',     'Differences',      false, true,  'The places where the mesh differs most from the download';
    'lights',      'Lights',           false, true,  'The lights animation: the right lamps light up';
    'body',        'Body',             false, true,  'The body animation: the body moves, the tires stay on the ground';
    'steering',    'Steering',         false, true,  'The steering animation: the front wheels steer';
    'wheels',      'Wheels',           false, true,  'The wheels animation: the wheels turn with the motion';
    'drive',       'Drive',            false, true,  'The drive animation: steering and wheels together';
    'levels',      'Detail levels',    false, true,  'The detail levels look right at their distances';
    'outline',     '2D outline',       false, true,  'Each 2D outline is one closed line around its part';
    'interior',    'Interior objects', false, false, 'The seats and the steering wheel are found (not built yet)';
    'photos',      'Photos',           false, false, 'A set of photos all around the vehicle (not built yet)';
    'summary',     'Summary',          true,  true,  'Every answer, and the overall decision'};
% END OF EDIT HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

turnedOff = options.TurnedOff;
if isempty(turnedOff) && ~iscell(turnedOff)
    turnedOff = {};
    if ispref('CarMesh3D', 'ReviewChecksOff')
        turnedOff = getpref('CarMesh3D', 'ReviewChecksOff');
    end
end
turnedOff = cellstr(turnedOff);

keys = rows(:,1);
required = cell2mat(rows(:,3));
onFlags = required | ~ismember(keys, turnedOff);
checkList = table(string(keys), string(rows(:,2)), required, onFlags, cell2mat(rows(:,4)), string(rows(:,5)), ...
    'VariableNames', {'Key', 'Title', 'Required', 'On', 'Built', 'Description'});

%% Any debugging?
if 0==flag_max_speed && ~isempty(options.FigNum)
    for ith_row = 1:height(checkList)
        kind = 'optional';
        if checkList.Required(ith_row)
            kind = 'required';
        end
        onText = 'on';
        if ~checkList.On(ith_row)
            onText = 'OFF';
        end
        fprintf(1, '%-18s %-9s %s\n', checkList.Title(ith_row), kind, onText);
    end
end

end % Ends main function
