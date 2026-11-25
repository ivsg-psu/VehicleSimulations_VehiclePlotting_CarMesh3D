function checkList = fcn_CarMesh3D_reviewChecks(options)
% fcn_CarMesh3D_reviewChecks
% The list of the V&V GUI's assessments, in ONE place: which assessment
% functions are asked, in what order, and whether each is required or
% optional. The V&V GUI (fcn_CarMesh3D_reviewVehicle) plays this list, and
% the Review section of Shared GUI settings (fcn_CarMesh3D_makeSettingsPanel)
% shows it, so they cannot disagree (rules G27 and G39).
%
% The list holds only the functions and their settings. Each function's
% title, question and tooltip come from the function itself, asked in its
% describe mode (Mode='describe'), so editing a function's wording changes
% every menu (Sean, 2026-11-25 01:22). The order matters: with "Stop at
% the first No?", the first No ends the review, so basic assessments come
% first (Sean, 2026-11-24 23:18: this replaces a dependency matrix).
%
% A REQUIRED assessment is always asked; an OPTIONAL one can be turned off
% in Shared GUI settings (Review), and is then recorded as skipped. Every
% human assessment is optional (Sean, 2026-11-25 00:53: a check whose
% failure would break code is a code check in the build, not a question).
%
% FORMAT:
%
%       checkList = fcn_CarMesh3D_reviewChecks((TurnedOff=keys),...
%           (Assessments=handles), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TurnedOff: the keys of the optional assessments turned off, as a
%      cell array (such as {'realism'}); [] (default) for the user's own
%      setting, the MATLAB preference CarMesh3D/ReviewChecksOff.
%
%      Assessments: a cell array of assessment function handles to use in
%      place of the list below (for a run of one's own, or tests); each is
%      optional. Default {} (the list below).
%
%      FigNum: if given (and not -1), the list is printed. If -1, input
%      checking is skipped (fast mode) and nothing is printed.
%
% OUTPUTS:
%
%      checkList: a table with one row per assessment function, in order:
%           Key: the function's key: its name after fcn_CarMesh3D_assess_
%               (such as "patchyLabels")
%           Title: its title, from its describe mode
%           Required: true for a required assessment
%           On: false for an optional assessment turned off
%           Built: false when its describe mode failed (Shared GUI
%               settings shows the row greyed, with the error)
%           Description: its tooltip, from its describe mode (or the error)
%           Function: the function handle
%           Questions: its questions (describe mode's structure array)
%
% DEPENDENCIES:
%
%      the assessment functions (fcn_CarMesh3D_assess_*)
%
% EXAMPLES:
%
%       checkList = fcn_CarMesh3D_reviewChecks(FigNum=1);
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
%   % * First write (Sean, 16:14: required and optional review checks)

% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewChecks
%   % * The V&V redesign (Documentation_CarMesh3D_GUIdesign_VandV.md): the
%   %   % list is now a list of assessment functions; titles and tooltips
%   %   % come from each function's describe mode; the first round of six
%   %   % (Sean, 2026-11-25 01:22 to 01:36), every one optional; Function
%   %   % and Questions columns; Assessments= for a list of one's own

% TO-DO:
%
% (the "later" assessments in the V&V design file, section 5)

arguments
    options.TurnedOff = []     % Keys turned off; [] for the preference
    options.Assessments = {}   % Function handles in place of the list
    options.FigNum = []        % Prints the list if given; -1 for fast mode
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
        error('CarMesh3D:badInput', 'TurnedOff must be a cell array of keys, or [].');
    end
    if ~isempty(options.Assessments) && ~(iscell(options.Assessments) && all(cellfun(@(f) isa(f, 'function_handle'), options.Assessments)))
        error('CarMesh3D:badInput', 'Assessments must be a cell array of function handles.');
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDIT HERE: the assessments, in the order asked (the first round,
% Sean 2026-11-25; the later ones are in the V&V design file, section 5).
%   Function                                   Required
rows = {
    @fcn_CarMesh3D_assess_overall,             false;
    @fcn_CarMesh3D_assess_labels,              false;
    @fcn_CarMesh3D_assess_patchyLabels,        false;
    @fcn_CarMesh3D_assess_headlights,          false;
    @fcn_CarMesh3D_assess_brakeLights,         false;
    @fcn_CarMesh3D_assess_realism,             false};
% END OF EDIT HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(options.Assessments)
    rows = [reshape(options.Assessments, [], 1), num2cell(false(numel(options.Assessments), 1))];
end

turnedOff = options.TurnedOff;
if isempty(turnedOff) && ~iscell(turnedOff)
    turnedOff = {};
    if ispref('CarMesh3D', 'ReviewChecksOff')
        turnedOff = getpref('CarMesh3D', 'ReviewChecksOff');
    end
end
turnedOff = cellstr(turnedOff);

numRows = size(rows, 1);
keys = strings(numRows, 1);
titles = strings(numRows, 1);
descriptions = strings(numRows, 1);
built = true(numRows, 1);
questions = cell(numRows, 1);
for ith_row = 1:numRows
    functionHandle = rows{ith_row, 1};
    keys(ith_row) = string(regexprep(func2str(functionHandle), '^(@\(\)\s*)?fcn_CarMesh3D_assess_', ''));
    try
        % (describe mode: no vehicle, no file, no figure: the title,
        % questions and tooltip, from the function itself)
        described = functionHandle([], Mode='describe');
        questions{ith_row} = described;
        titles(ith_row) = string(described(1).GroupTitle);
        descriptions(ith_row) = string(described(1).GroupHelp);
    catch describeError
        built(ith_row) = false;
        questions{ith_row} = struct([]);
        titles(ith_row) = keys(ith_row);
        descriptions(ith_row) = string(sprintf('(could not describe: %s)', describeError.message));
    end
end
required = cell2mat(rows(:, 2));
onFlags = required | ~ismember(keys, string(turnedOff));
checkList = table(keys, titles, required, onFlags, built, descriptions, rows(:, 1), questions, ...
    'VariableNames', {'Key', 'Title', 'Required', 'On', 'Built', 'Description', 'Function', 'Questions'});

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
        fprintf(1, '%-16s %-9s %-4s %d question(s)\n', checkList.Title(ith_row), kind, onText, numel(checkList.Questions{ith_row}));
    end
end

end % Ends main function
