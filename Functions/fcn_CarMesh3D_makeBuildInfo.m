function buildInfo = fcn_CarMesh3D_makeBuildInfo(options)
% fcn_CarMesh3D_makeBuildInfo

% Makes the BuildInfo saved with a finished mesh (vehicleMesh.BuildInfo):
% the CarMesh3D version and MESH VERSION it was made with (see
% fcn_CarMesh3D_version), when, by which script, with which main
% settings, from which exemplar (for a body-style vehicle), and its
% QUALITY SCORE. With it, meshes made before a change to CarMesh3D can be
% found and made again (fcn_CarMesh3D_listVehicles), and vehicles can be
% compared by quality.
%
% THE QUALITY SCORE, 0 to 100 (higher is better), from the comparison
% with the download (fcn_CarMesh3D_compareToOriginal, percentages of the
% car's pixels over its 14 views) and the dimension checks
% (fcn_CarMesh3D_validateMesh):
%
%     score = 100 - 4*holes - 2*labelChanges - 2*flipped - 4*seeThrough
%                 - 5*(number of dimension checks failed)
%
% clamped to 0 to 100 and rounded to 0.1. Holes and see-through gaps
% count double since they show the background through the car. Typical
% values (2026-11-21): low-poly downloads about 98 to 99; the crumpled
% Civic Type R about 72. A body-style vehicle (no download of its own)
% takes its exemplar's comparison terms, and its own dimension checks.
%
% FORMAT:
%
%       buildInfo = fcn_CarMesh3D_makeBuildInfo(...
%           (Script=fileName), (Settings=struct), (CompareTotals=totals),...
%           (Validation=table), (Exemplar=buildInfo), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Script: the script that made the mesh (a file name or path; only
%      the name is kept). Default ''.
%
%      Settings: a structure of the main settings used (for example
%      TargetFaces, ReduceWithBlender, Symmetric, BodyStyle), kept as
%      given. Default struct().
%
%      CompareTotals: the Totals of fcn_CarMesh3D_compareToOriginal
%      (HolePercent, LabelChangePercent, FlippedPercent,
%      SeeThroughPercent). Default [] (no comparison).
%
%      Validation: the table of fcn_CarMesh3D_validateMesh (its Pass
%      column). Default [] (no dimension checks).
%
%      Exemplar: the exemplar's own BuildInfo, for a body-style vehicle
%      (its ID is taken from its Settings, its comparison terms are used
%      when CompareTotals is empty). Default [].
%
%      FigNum: if given (not -1), the build information is printed. If set
%      to -1, input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      buildInfo: a structure with
%           CarMesh3DVersion, MeshVersion: from fcn_CarMesh3D_version
%           Date: when it was made, 'yyyy-MM-dd HH:mm'
%           Script: the script's file name
%           MATLABRelease: such as '2025b'
%           Settings: as given
%           ExemplarID, ExemplarMeshVersion: for a body-style vehicle
%               ('' otherwise)
%           Quality: Score, HolePercent, LabelChangePercent,
%               FlippedPercent, SeeThroughPercent (NaN if unknown),
%               DimensionChecks and DimensionChecksFailed (counts),
%               Basis ('comparison', 'exemplar', or 'dimensions only'),
%               and Formula (the formula as text)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_version
%
% EXAMPLES:
%
%       buildInfo = fcn_CarMesh3D_makeBuildInfo(Script=mfilename, ...
%           CompareTotals=compareReport.Totals, Validation=validationTable, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_makeBuildInfo.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeBuildInfo
%   % * Wrote the code originally (drafted with Claude), so each mesh
%   %   % records the CarMesh3D version it was made with (Sean: "a field
%   %   % ... that indicates the version of the creation software") and its
%   %   % quality score

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeBuildInfo
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Script = ''              % The script that made the mesh
    options.Settings = struct()      % The main settings used
    options.CompareTotals = []       % Totals from fcn_CarMesh3D_compareToOriginal; [] for none
    options.Validation = []          % Table from fcn_CarMesh3D_validateMesh; [] for none
    options.Exemplar = []            % The exemplar's BuildInfo, for a body-style vehicle
    options.FigNum = []              % Print the result if given; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
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
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above
        if ~(ischar(options.Script) || isstring(options.Script))
            error('Script must be text (a file name or path)');
        end
        if ~isstruct(options.Settings)
            error('Settings must be a structure');
        end
        if ~isempty(options.CompareTotals) && ~(isstruct(options.CompareTotals) && ...
                all(isfield(options.CompareTotals, {'HolePercent','LabelChangePercent','FlippedPercent'})))
            error('CompareTotals must be the Totals structure of fcn_CarMesh3D_compareToOriginal');
        end
        if ~isempty(options.Validation) && ~(istable(options.Validation) && any(strcmp(options.Validation.Properties.VariableNames, 'Pass')))
            error('Validation must be the table of fcn_CarMesh3D_validateMesh');
        end
        if ~isempty(options.Exemplar) && ~(isstruct(options.Exemplar) && isfield(options.Exemplar, 'Quality'))
            error('Exemplar must be a BuildInfo structure (from fcn_CarMesh3D_makeBuildInfo)');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
[versionString, ~, meshVersion] = fcn_CarMesh3D_version(FigNum=-1);
[~, scriptName, scriptExtension] = fileparts(char(options.Script));
releaseText = version('-release');

%%%% The quality terms: from the comparison, or else the exemplar's
qualityTerms = struct('HolePercent',NaN, 'LabelChangePercent',NaN, 'FlippedPercent',NaN, 'SeeThroughPercent',NaN);
basis = 'dimensions only';
if ~isempty(options.CompareTotals)
    for termName = fieldnames(qualityTerms)'
        if isfield(options.CompareTotals, termName{1})
            qualityTerms.(termName{1}) = double(options.CompareTotals.(termName{1}));
        end
    end
    basis = 'comparison';
elseif ~isempty(options.Exemplar) && isfield(options.Exemplar, 'Quality')
    for termName = fieldnames(qualityTerms)'
        if isfield(options.Exemplar.Quality, termName{1})
            qualityTerms.(termName{1}) = double(options.Exemplar.Quality.(termName{1}));
        end
    end
    basis = 'exemplar';
end

%%%% The dimension checks
numChecks = 0;
numFailed = 0;
if ~isempty(options.Validation)
    passValues = options.Validation.Pass;
    numChecks = numel(passValues);
    numFailed = sum(~logical(passValues));
end

%%%% The score
weights = [4 2 2 4];
termValues = [qualityTerms.HolePercent qualityTerms.LabelChangePercent qualityTerms.FlippedPercent qualityTerms.SeeThroughPercent];
termValues(isnan(termValues)) = 0;            % (unknown terms do not lower the score)
score = 100 - sum(weights.*termValues) - 5*numFailed;
score = round(10*min(100, max(0, score)))/10;

quality = qualityTerms;
quality.Score = score;
quality.DimensionChecks = numChecks;
quality.DimensionChecksFailed = numFailed;
quality.Basis = basis;
quality.Formula = '100 - 4*holes - 2*labelChanges - 2*flipped - 4*seeThrough - 5*dimensionChecksFailed (percent; 0 to 100)';

%%%% The exemplar, for a body-style vehicle
exemplarID = '';
exemplarMeshVersion = '';
if ~isempty(options.Exemplar)
    if isfield(options.Exemplar, 'Settings') && isfield(options.Exemplar.Settings, 'VehicleID')
        exemplarID = char(options.Exemplar.Settings.VehicleID);
    end
    if isfield(options.Exemplar, 'MeshVersion')
        exemplarMeshVersion = char(options.Exemplar.MeshVersion);
    end
end
if isfield(options.Settings, 'ExemplarID') && isempty(exemplarID)
    exemplarID = char(options.Settings.ExemplarID);
end

buildInfo = struct(...
    'CarMesh3DVersion', versionString, ...
    'MeshVersion', meshVersion, ...
    'Date', char(datetime('now', 'Format','yyyy-MM-dd HH:mm')), ...
    'Script', [scriptName scriptExtension], ...
    'MATLABRelease', releaseText, ...
    'Settings', options.Settings, ...
    'ExemplarID', exemplarID, ...
    'ExemplarMeshVersion', exemplarMeshVersion, ...
    'Quality', quality);

%% Plot the results (for debugging)?
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
    fprintf(1, 'Made with CarMesh3D %s (mesh version %s) on %s by %s, MATLAB %s\n', buildInfo.CarMesh3DVersion, ...
        buildInfo.MeshVersion, buildInfo.Date, buildInfo.Script, buildInfo.MATLABRelease);
    if ~isempty(buildInfo.ExemplarID)
        fprintf(1, '  from the exemplar %s (mesh version %s)\n', buildInfo.ExemplarID, buildInfo.ExemplarMeshVersion);
    end
    fprintf(1, '  quality score %.1f (%s): holes %.3f%%, label changes %.3f%%, flipped %.3f%%, see-through %.3f%%; %d of %d dimension checks failed\n', ...
        quality.Score, quality.Basis, quality.HolePercent, quality.LabelChangePercent, quality.FlippedPercent, ...
        quality.SeeThroughPercent, quality.DimensionChecksFailed, quality.DimensionChecks);
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


