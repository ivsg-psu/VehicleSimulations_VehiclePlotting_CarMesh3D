function problems = fcn_CarMesh3D_checkNames(folders, options)
% fcn_CarMesh3D_checkNames

% Checks the code against the naming conventions agreed for the project
% (Documents/Documentation_CarMesh3D_namingTable.md, section 3, C1 to
% C9): that no function uses a name the Q95 sweep retired, and that every
% true/false option is named Flag... . Run by its test, so a retired name
% that comes back (a paste from an old file, an old habit) is caught.
%
% What is checked, in every .m file in the folders:
%   1. Retired names: the old mesh fields (PartNames, FacePartIndex,
%      LightTypeNames, ...), the old signal names (LightStates,
%      Headlights, FogLights) and the old hook names (SetNightView,
%      SetBoundaries, ...), used as a field (.Name) or as a quoted name
%      ('Name'; Headlights only as .Headlights or 'Headlights','low',
%      since the word is also a heading people read). Comments are not
%      checked (history notes keep old names).
%   2. True/false options: an option in an arguments block whose default
%      is true or false must start with Flag (C3), except the options
%      listed in AllowedOptions (Symmetric takes 'auto' too).
%   3. Underscores in flag variables (C1): flag_ names other than those of
%      the IVSG templates (flag_do_debug, flag_max_speed,
%      flag_check_inputs, flag_do_plots, flag_do_plot, flag_varname,
%      flag_this_is_a_new_axes), the DebugTools installer's, and the
%      *_Folders_Initialized globals.
%
% FORMAT:
%
%       problems = fcn_CarMesh3D_checkNames((folders), (AllowedOptions=names), (FigNum=figNum))
%
% INPUTS:
%
%      (OPTIONAL INPUTS)
%
%      folders: a folder, or a cell array of folders, whose .m files are
%      checked (not their subfolders). Default: this function's folder.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      AllowedOptions: names of true/false options that keep a name
%      without Flag (cell array of text). Default {}.
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      problems: a cell array of text, one line per problem found
%      ('file.m, line 12: retired name ''Headlights''', ...); empty when
%      the code follows the conventions.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_checkNames.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkNames
%   % * First write (the naming table, section 8, item 3: a test that no
%   %   % function's options or a mesh's fields use the old names)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_checkNames
%   % * (none yet)



arguments
    folders = ''
    options.AllowedOptions = {}   % True/false options that keep their names
    options.FigNum = []           % Not used; -1 for fast mode
end

%% Main code starts here
if isempty(folders)
    folders = {fileparts(mfilename('fullpath'))};
end
folders = cellstr(folders);
allowedOptions = cellstr(options.AllowedOptions);

% EDIT HERE: the names the Q95 sweep retired (2026-11-26), with no aliases
retiredNames = {'PartNames', 'FacePartIndex', 'FaceAlsoParts', 'LightTypeNames', 'FaceLightType', ...
    'FaceLightFunctions', 'FaceCoverLamp', 'TextureColorParts', 'InteriorObjectNames', 'FaceInteriorObject', ...
    'FaceHiddenSet', 'HiddenSetNames', 'LampSwitching', 'SeeThroughReliable', 'LightPatches', ...
    'LightStates', 'Headlights', 'FogLights', 'MeshBoundaries', ...
    'SetNightView', 'SetBoundaries', 'SetGround', 'SetMirror', 'SetShowHidden'};
templateFlags = {'flag_do_debug', 'flag_max_speed', 'flag_check_inputs', 'flag_do_plots', 'flag_do_plot', ...
    'flag_varname', 'flag_this_is_a_new_axes', 'flag_previousInstallFound', 'flag_previousDebugFound', ...
    'flag_previousAutoinstallFound', 'flag_debugInstallNeeded', 'flag_debugToolsWasInstalled', 'flag_isOnline'};

% (a field, .Name, or a whole quoted name, 'Name'; the text 'Headlights' is
% also a word people read, a heading or a title, so it counts only as
% .Headlights or with an old value after it, 'Headlights','low')
quotedNames = setdiff(retiredNames, {'Headlights'}, 'stable');
retiredPattern = ['(\.)(' strjoin(retiredNames, '|') ')(?![A-Za-z0-9_])|(\'')(' strjoin(quotedNames, '|') ')\''' ...
    '|(\'')(Headlights)\''\s*,\s*\''(?:off|low|high)\'''];
problems = {};
for ith_folder = 1:numel(folders)
    files = dir(fullfile(folders{ith_folder}, '*.m'));
    for ith_file = 1:numel(files)
        fileName = files(ith_file).name;
        if startsWith(fileName, 'fcn_DebugTools_') || strcmp(fileName, [mfilename '.m']) ...
                || strcmp(fileName, ['script_test_' mfilename '.m'])
            continue;   % (the installer is IVSG's; this checker and its test name the retired names)
        end
        lines = splitlines(fileread(fullfile(files(ith_file).folder, fileName)));
        flagInArguments = false;
        for ith_line = 1:numel(lines)
            code = fcn_INTERNAL_codePart(lines{ith_line});
            if isempty(strtrim(code))
                continue;
            end
            where = sprintf('%s, line %d', fileName, ith_line);
            % 1. Retired names
            found = regexp(code, retiredPattern, 'tokens');
            for ith_found = 1:numel(found)
                tokens = found{ith_found}(~cellfun(@isempty, found{ith_found}));
                problems{end+1, 1} = sprintf('%s: retired name ''%s''', where, tokens{end}); %#ok<AGROW>
            end
            % 2. True/false options without Flag
            if ~isempty(regexp(code, '^\s*arguments(?![A-Za-z0-9_])', 'once'))
                flagInArguments = true;
            elseif flagInArguments && ~isempty(regexp(code, '^\s*end(?![A-Za-z0-9_])', 'once'))
                flagInArguments = false;
            elseif flagInArguments
                option = regexp(code, '^\s*options\.([A-Za-z0-9]+)\s*(\([^)]*\))?\s*(\w+)?\s*(\{[^}]*\})?\s*=\s*(true|false)(?![A-Za-z0-9_])', 'tokens', 'once');
                if ~isempty(option) && ~startsWith(option{1}, 'Flag') && ~any(strcmp(option{1}, allowedOptions))
                    problems{end+1, 1} = sprintf('%s: true/false option ''%s'' is not named Flag%s', where, option{1}, option{1}); %#ok<AGROW>
                end
            end
            % 3. flag_ names outside the templates
            flagNames = regexp(code, '\<flag_[A-Za-z0-9_]+', 'match');
            for ith_flag = 1:numel(flagNames)
                if ~any(strcmp(flagNames{ith_flag}, templateFlags)) && ~endsWith(flagNames{ith_flag}, '_Folders_Initialized')
                    problems{end+1, 1} = sprintf('%s: underscore in ''%s'' (C1: camelCase, %s)', where, ...
                        flagNames{ith_flag}, fcn_INTERNAL_camel(flagNames{ith_flag})); %#ok<AGROW>
                end
            end
        end
    end
end
problems = unique(problems, 'stable');

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_codePart
function code = fcn_INTERNAL_codePart(line)
% A line without its comment; text in quotes kept (a quoted name is a
% name: 'Headlights' in a struct() call), a % inside quotes not a comment
code = line;
inQuote = '';
for ith_char = 1:numel(line)
    thisChar = line(ith_char);
    if isempty(inQuote)
        if thisChar == '%'
            code = line(1:ith_char-1);
            return;
        elseif thisChar == '"' || (thisChar == '''' && (ith_char == 1 || isempty(regexp(line(ith_char-1), '[A-Za-z0-9_\)\]\}\.''', 'once'))))
            inQuote = thisChar;
        end
    elseif thisChar == inQuote
        inQuote = '';
    end
end
end % Ends fcn_INTERNAL_codePart

%% fcn_INTERNAL_camel
function name = fcn_INTERNAL_camel(name)
% flag_find_covers -> flagFindCovers
parts = strsplit(name, '_');
for ith_part = 2:numel(parts)
    if ~isempty(parts{ith_part})
        parts{ith_part}(1) = upper(parts{ith_part}(1));
    end
end
name = strjoin(parts, '');
end % Ends fcn_INTERNAL_camel
