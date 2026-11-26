function report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, options)
% fcn_CarMesh3D_guiRandomWalk
% Tests a GUI by running long random sequences of user actions (clicks,
% keys, menu picks) and checking, after every step, rules that must
% always hold (invariants: "the readout matches the camera", "the status
% line matches the mode", "no panel is cut off"). When a step errors or a
% rule fails, the exact sequence is saved so the failure can be replayed
% step by step. Random sequences find the bugs that come from an unusual
% ORDER of actions, which hand testing rarely tries (Sean, 2026-11-24
% 05:03: "User testing is a very (very) poor way to catch bugs").
%
% FORMAT:
%
%       report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, ...
%           (Steps=numSteps), (Seed=seed), (Replay=steps), (Name=name),
%           (LogFolder=folder), (FlagStopOnFailure=flag), (FigNum=figNum))
%
% INPUTS:
%
%      actions: a structure array, one element per kind of user action,
%      with fields
%           Name: a short name, such as 'night on'
%           Do: a function handle, called with no input, that does it
%               (usually through fcn_CarMesh3D_guiDriver or a GUI hook)
%           Allowed: (optional) a function handle returning true when the
%               action can be done now (e.g. its panel is open); empty for
%               always
%           Weight: (optional) how often it is picked, relative to the
%               others (default 1)
%
%      invariants: a structure array of rules, with fields
%           Name: a short name
%           Check: a function handle, called with no input, returning ''
%               when the rule holds, or a message saying what is wrong
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Steps: the number of actions in the walk (default 100).
%
%      Seed: the random seed (default 1), so a walk can be repeated.
%
%      Replay: a cell array of action names to do in order, in place of a
%      random walk (as saved from a failure).
%
%      Name: a name for the walk, used in the saved files (default
%      'guiWalk').
%
%      LogFolder: where a failing sequence is saved, as
%      <Name>_failure_seed<Seed>.mat and .txt (default: tempdir).
%
%      FlagStopOnFailure: true (default) to stop at the first failure; false
%      to note it and keep going.
%
%      FigNum: if given (and not -1), each step is printed. If -1, nothing
%      is printed and inputs are not checked.
%
% OUTPUTS:
%
%      report: a structure with
%           Passed: true if no step failed
%           Steps: the action names done, in order
%           Failures: a structure array (Step, Action, Message, Kind:
%               'error' or the failing rule's name)
%           FailureFile: the saved sequence's file name ('' if none)
%           ActionCounts: how many times each action was done
%
% DEPENDENCIES:
%
%      (none; actions usually use fcn_CarMesh3D_guiDriver)
%
% EXAMPLES:
%
%       actions = struct('Name', {'night on','night off'}, ...
%           'Do', {@() viewer.SetFlagNight(true), @() viewer.SetFlagNight(false)});
%       invariants = struct('Name', {'readout'}, 'Check', {@() checkReadout()});
%       report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Steps=200, Seed=3);
%       % Replay a failure:
%       report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Replay=report.Steps);
%
%       See the script: script_test_fcn_CarMesh3D_guiRandomWalk.m for a
%       full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_guiRandomWalk
%   % * First write of the code (Q39, agreed 05:10): random and replayed
%   %   % action sequences with rules checked after each step; failing
%   %   % sequences saved

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_guiRandomWalk
%   % * Shrinking a failing sequence to the fewest steps that still fail


arguments
    actions
    invariants
    options.Steps = 100            % Number of random actions
    options.Seed = 1               % Random seed, so a walk can be repeated
    options.Replay = {}            % Action names to do in order (replay)
    options.Name = 'guiWalk'       % Name used in saved files
    options.LogFolder = ''         % Where failures are saved ('' for tempdir)
    options.FlagStopOnFailure = true   % Stop at the first failure
    options.FigNum = []            % Print each step if given; -1 for fast mode
end

%% Debugging and Input checks
flag_max_speed = isequal(options.FigNum, -1);
flag_do_debug = 0;
if flag_do_debug
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~flag_max_speed
    if ~isstruct(actions) || ~all(isfield(actions, {'Name','Do'})) || isempty(actions)
        error('CarMesh3D:badInput', 'actions must be a structure array with fields Name and Do (and optionally Allowed, Weight).');
    end
    if ~isempty(invariants) && (~isstruct(invariants) || ~all(isfield(invariants, {'Name','Check'})))
        error('CarMesh3D:badInput', 'invariants must be a structure array with fields Name and Check (or empty).');
    end
end
flag_do_plots = ~flag_max_speed && ~isempty(options.FigNum);

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
actionNames = {actions.Name};
weights = ones(1, numel(actions));
if isfield(actions, 'Weight')
    for ith = 1:numel(actions)
        if ~isempty(actions(ith).Weight)
            weights(ith) = actions(ith).Weight;
        end
    end
end
if isempty(invariants)
    invariants = struct('Name', {}, 'Check', {});
end

flagReplay = ~isempty(options.Replay);
if flagReplay
    numSteps = numel(options.Replay);
else
    numSteps = options.Steps;
    randomStream = RandStream('mt19937ar', 'Seed', options.Seed);
end

doneSteps = {};
failures = struct('Step', {}, 'Action', {}, 'Message', {}, 'Kind', {});
actionCounts = zeros(1, numel(actions));
for ith_step = 1:numSteps
    % (the action: the next of the replay, or a random allowed one)
    if flagReplay
        index = find(strcmp(actionNames, options.Replay{ith_step}), 1);
        if isempty(index)
            error('CarMesh3D:badInput', 'Replay step %d names an unknown action ''%s''.', ith_step, options.Replay{ith_step});
        end
    else
        allowed = true(1, numel(actions));
        if isfield(actions, 'Allowed')
            for ith = 1:numel(actions)
                if ~isempty(actions(ith).Allowed)
                    try
                        allowed(ith) = logical(actions(ith).Allowed());
                    catch
                        allowed(ith) = false;
                    end
                end
            end
        end
        if ~any(allowed)
            failures(end+1) = struct('Step', ith_step, 'Action', '', 'Message', 'no action is allowed', 'Kind', 'stuck'); %#ok<AGROW>
            break;
        end
        cumulative = cumsum(weights .* allowed);
        index = find(cumulative >= rand(randomStream)*cumulative(end), 1);
    end
    name = actionNames{index};
    doneSteps{end+1} = name; %#ok<AGROW>
    actionCounts(index) = actionCounts(index) + 1;
    if flag_do_plots
        fprintf(1, '  step %d: %s\n', ith_step, name);
    end

    % (do it; then every rule must hold)
    failedNow = false;
    try
        actions(index).Do();
        drawnow;
    catch actionError
        failures(end+1) = struct('Step', ith_step, 'Action', name, 'Message', ...
            sprintf('%s (in %s)', actionError.message, fcn_INTERNAL_where(actionError)), 'Kind', 'error'); %#ok<AGROW>
        failedNow = true;
    end
    if ~failedNow
        for ith_rule = 1:numel(invariants)
            try
                message = invariants(ith_rule).Check();
            catch ruleError
                message = sprintf('the check itself errored: %s', ruleError.message);
            end
            if ~isempty(message)
                failures(end+1) = struct('Step', ith_step, 'Action', name, 'Message', message, 'Kind', invariants(ith_rule).Name); %#ok<AGROW>
                failedNow = true;
            end
        end
    end
    if failedNow && options.FlagStopOnFailure
        break;
    end
end

% (a failing sequence saved, to replay)
failureFile = '';
if ~isempty(failures)
    logFolder = char(options.LogFolder);
    if isempty(logFolder)
        logFolder = tempdir;
    end
    if ~isfolder(logFolder)
        mkdir(logFolder);
    end
    baseName = fullfile(logFolder, sprintf('%s_failure_seed%d', char(options.Name), options.Seed));
    steps = doneSteps; %#ok<NASGU>
    savedFailures = failures; %#ok<NASGU>
    save([baseName '.mat'], 'steps', 'savedFailures');
    fileID = fopen([baseName '.txt'], 'w');
    if fileID > 0
        fprintf(fileID, '%s, seed %d: %d step(s) done; first failure at step %d (%s): %s\r\n', char(options.Name), options.Seed, ...
            numel(doneSteps), failures(1).Step, failures(1).Kind, failures(1).Message);
        fprintf(fileID, 'Steps:\r\n');
        fprintf(fileID, '  %s\r\n', doneSteps{:});
        fclose(fileID);
    end
    failureFile = [baseName '.mat'];
end

report = struct('Passed', isempty(failures), 'Steps', {doneSteps}, 'Failures', failures, ...
    'FailureFile', failureFile, 'ActionCounts', {[actionNames; num2cell(actionCounts)]});

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    if report.Passed
        fprintf(1, '%s: %d steps, every rule held\n', char(options.Name), numel(doneSteps));
    else
        fprintf(1, '%s: failure at step %d (%s, action ''%s''): %s\n    saved: %s\n', char(options.Name), failures(1).Step, ...
            failures(1).Kind, failures(1).Action, failures(1).Message, failureFile);
    end
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_where
function whereText = fcn_INTERNAL_where(caughtError)
% Where an error happened: the first function and line in its stack
whereText = 'unknown place';
if ~isempty(caughtError.stack)
    whereText = sprintf('%s line %d', caughtError.stack(1).name, caughtError.stack(1).line);
end
end % Ends fcn_INTERNAL_where
