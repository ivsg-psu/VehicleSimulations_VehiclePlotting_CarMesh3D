function user = fcn_CarMesh3D_userInfo(options)
% fcn_CarMesh3D_userInfo
% Who is using the CarMesh3D tools on this computer: their initials and
% name, kept as MATLAB preferences (group CarMesh3D: Initials, UserName),
% shared by every GUI (Shared GUI settings, You). The V&V GUI records them
% with every answer; the painter writes the initials in its change log.
%
% With Ask=true and no initials saved yet, it asks once (a small dialog)
% and saves the answer, so a student opening the V&V GUI for the first
% time is asked who they are (Sean, 2026-11-25 01:53: "We'll need a small
% helper function to get the user information, or even just a textbox").
%
% FORMAT:
%
%       user = fcn_CarMesh3D_userInfo((Ask=flag), (Set={initials, name}),
%           (Answer={initials, name}), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Ask: true to ask (a dialog) when no initials are saved; false
%      (default) to return the default instead, without asking.
%
%      Set: {initials, name} to save (name may be ''); default {} (nothing
%      saved).
%
%      Answer: {initials, name} to use in place of the dialog's answer
%      (for tests; nothing is shown). Default {} (the dialog is shown).
%
%      FigNum: not used (nothing is plotted); -1 for fast mode.
%
% OUTPUTS:
%
%      user: a structure with
%           Initials: upper case, such as 'SBB'
%           Name: the full name, or ''
%           Source: 'preference' (saved earlier), 'asked' (just asked and
%               saved), 'set' (Set given), or 'default' (nothing saved,
%               not asked: the repo's default initials, SBB)
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       user = fcn_CarMesh3D_userInfo(Ask=true);
%
%       See the script: script_test_fcn_CarMesh3D_userInfo.m for a full
%       test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_userInfo
%   % * First write (the V&V design file, Q47): initials and name as
%   %   % preferences; asks once when nothing is saved

% TO-DO:
%
% (none)

arguments
    options.Ask = false     % Ask when no initials are saved
    options.Set = {}        % {initials, name} to save
    options.Answer = {}     % {initials, name} in place of the dialog (tests)
    options.FigNum = []     % Not used; -1 for fast mode
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
    for optionName = {'Set', 'Answer'}
        value = options.(optionName{1});
        if ~isempty(value) && (~iscell(value) || numel(value) ~= 2)
            error('CarMesh3D:badInput', '%s must be {initials, name}.', optionName{1});
        end
    end
end

%% Main code
defaultInitials = 'SBB';   % (the repo's default, Sean 2026-11-24 11:20)

if ~isempty(options.Set)
    user = fcn_INTERNAL_save(options.Set);
    user.Source = 'set';
    return;
end

if ispref('CarMesh3D', 'Initials') && ~isempty(strtrim(char(getpref('CarMesh3D', 'Initials'))))
    user.Initials = upper(strtrim(char(getpref('CarMesh3D', 'Initials'))));
    user.Name = '';
    if ispref('CarMesh3D', 'UserName')
        user.Name = strtrim(char(getpref('CarMesh3D', 'UserName')));
    end
    user.Source = 'preference';
    return;
end

if options.Ask
    answer = options.Answer;
    if isempty(answer)
        answer = inputdlg({'Your initials (saved with your answers):', 'Your name (optional):'}, ...
            'CarMesh3D: who is reviewing?', [1 40; 1 40], {'', ''});
    end
    if ~isempty(answer) && ~isempty(strtrim(char(answer{1})))
        user = fcn_INTERNAL_save(answer);
        user.Source = 'asked';
        return;
    end
end

user = struct('Initials', defaultInitials, 'Name', '', 'Source', 'default');

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_save
function user = fcn_INTERNAL_save(pair)
% Saves {initials, name} as the preferences, and returns them
initials = upper(strtrim(char(pair{1})));
name = strtrim(char(pair{2}));
if isempty(initials)
    error('CarMesh3D:badInput', 'The initials cannot be empty.');
end
setpref('CarMesh3D', 'Initials', initials);
setpref('CarMesh3D', 'UserName', name);
user = struct('Initials', initials, 'Name', name, 'Source', '');
end % Ends fcn_INTERNAL_save
