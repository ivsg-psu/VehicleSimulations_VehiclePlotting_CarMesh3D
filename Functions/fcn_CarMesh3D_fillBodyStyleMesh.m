function vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh(bodyStyle, vehicleSpec, options)
% fcn_CarMesh3D_fillBodyStyleMesh

% Makes a vehicle's mesh from its body style when no 3D model of the
% vehicle itself is found: one of the style's exemplars (the finished,
% checked vehicles filed in Data\BodyStyles\<Style>; see
% fcn_CarMesh3D_loadBodyStyles) is refit to this
% vehicle's specification: its length, width, height, wheelbase, tracks,
% overhangs, ground clearance, and tire size, the wheels moved and sized
% as rigid parts (fcn_CarMesh3D_fitMeshToSpec). The labels (body, glass,
% wheels, lights, trim), light types, and colors come with it, so the
% result can be simplified, checked, animated, and lit like any finished
% vehicle.
%
% THE EXEMPLAR CLOSEST IN SIZE is used when the style has several: the
% one whose length, width, height, and wheelbase differ least from this
% vehicle's (the root-mean-square of the four relative differences), so
% a compact car is refit from a compact car and a large one from a large
% one. ExemplarID= picks one instead.
%
% The width is fit the way the exemplar's was: an exemplar fit with its
% mirrors (WidthReference 'mirrors') is fit to this vehicle's
% WidthWithMirrors; if the spec gives only the width without mirrors, the
% width with mirrors is estimated from the exemplar's own ratio of the
% two (and noted in the result's BodyStyleInfo).
%
% A style with no exemplar yet: Fallback 'sample' (default) makes the
% built-in sample car at this vehicle's size (fcn_CarMesh3D_fillSampleMesh,
% labeled and fit),
% with a warning (ID 'CarMesh3D:noExemplar'); 'error' stops instead.
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh(bodyStyle, vehicleSpec,...
%           (ExemplarID=id), (BodyColor=rgb), (Fallback=choice), (DataFolder=folder),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      bodyStyle: a style's ID from Data\bodyStyles.csv, such as
%      'liftback' or 'compactCargoVan' (case is ignored). See
%      fcn_CarMesh3D_loadBodyStyles.
%
%      vehicleSpec: the vehicle's specification (fcn_CarMesh3D_fillVehicleSpec
%      or fcn_CarMesh3D_loadVehicleSpec). OverallLength, OverallWidth,
%      OverallHeight, and Wheelbase are needed; the other dimensions are
%      used when given.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      ExemplarID: the exemplar to use, one of the style's finished
%      vehicles, such as '2013_Toyota_Prius_Four'. Default '' picks the
%      one closest in size.
%
%      BodyColor: an RGB color for the body faces. Default [] uses the
%      spec's BodyColor, or keeps the exemplar's.
%
%      Fallback: 'sample' (default) or 'error', for a style with no
%      exemplar.
%
%      DataFolder: the Data folder. Default [] uses the one next to the
%      Functions folder.
%
%      FigNum: a figure to plot the result. If empty or omitted, no plot
%      is made. If set to -1, input checking is skipped and no plot is
%      made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure, fit to the spec (with
%      VehicleSpec, AxleX, and FitInfo as from fcn_CarMesh3D_fitMeshToSpec),
%      with Name from the spec, Source naming the exemplar, the
%      exemplar's License (its attribution carries over), and
%           BodyStyleInfo: BodyStyle, ExemplarID, ExemplarName,
%               WidthReference, and WidthNote (how the width was fit),
%               CandidateIDs (the style's exemplars) and SizeDifference
%               (each one's root-mean-square relative size difference
%               from this vehicle, the same order)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_loadBodyStyles, fcn_CarMesh3D_findVehicleFiles,
%      fcn_CarMesh3D_fitMeshToSpec, fcn_CarMesh3D_fillSampleMesh,
%      fcn_CarMesh3D_labelParts
%      fcn_CarMesh3D_plotVehicle (only if plotting)
%
% EXAMPLES:
%
%       % A 2020 Toyota Corolla hatchback, from the liftback exemplar
%       spec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan');
%       spec.Name = '2020 Toyota Corolla Hatchback';
%       spec.OverallLength = 4.370; spec.OverallWidth = 1.790;
%       spec.OverallHeight = 1.435; spec.Wheelbase = 2.640;
%       vehicleMesh = fcn_CarMesh3D_fillBodyStyleMesh('liftback', spec, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_fillBodyStyleMesh.m for
%       a full test suite.
%
% This function was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillBodyStyleMesh
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillBodyStyleMesh
%   % * A style may have several exemplars (the finished vehicles in its Data\BodyStyles folder): the one closest in size is used, or the one given by the new ExemplarID option
%   % * BodyStyleInfo adds CandidateIDs and SizeDifference

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillBodyStyleMesh
%   % * Blend two exemplars (for example a sedan between a coupe and a wagon); fit the glass line height when a spec gives it



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    bodyStyle
    vehicleSpec
    options.ExemplarID = ''       % The exemplar to use; '' for the one closest in size
    options.BodyColor = []        % RGB for the body; [] for the spec's (or the exemplar's)
    options.Fallback = 'sample'   % 'sample' or 'error', for a style with no exemplar
    options.DataFolder = []       % The Data folder; [] for the one next to Functions
    options.FigNum = []           % Figure to plot into; [] for no plot, -1 for fast mode
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


        if ~((ischar(bodyStyle) || isstring(bodyStyle)) && isscalar(string(bodyStyle)) && strlength(string(bodyStyle)) > 0)
            error('bodyStyle must be a style''s ID, such as ''liftback''');
        end
        if ~(isstruct(vehicleSpec) && isscalar(vehicleSpec) && all(isfield(vehicleSpec, {'OverallLength','OverallWidth','OverallHeight','Wheelbase'})))
            error('vehicleSpec must have OverallLength, OverallWidth, OverallHeight, and Wheelbase');
        end
        if ~(ischar(options.ExemplarID) || isstring(options.ExemplarID))
            error('ExemplarID must be a vehicle ID, such as ''2013_Toyota_Prius_Four'', or empty');
        end
        if ~isempty(options.BodyColor) && ~(isnumeric(options.BodyColor) && numel(options.BodyColor)==3 && all(options.BodyColor >= 0 & options.BodyColor <= 1))
            error('BodyColor must be an RGB color, three values from 0 to 1');
        end
        if ~any(strcmpi(options.Fallback, {'sample','error'}))
            error('Fallback must be ''sample'' or ''error''');
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% The style and its exemplar
bodyStyles = fcn_CarMesh3D_loadBodyStyles(DataFolder=options.DataFolder, FigNum=-1);
styleIndex = find(strcmpi({bodyStyles.BodyStyle}, char(bodyStyle)), 1);
if isempty(styleIndex)
    error('Unknown body style ''%s''. The styles are: %s', char(bodyStyle), strjoin({bodyStyles.BodyStyle}, ', '));
end
thisStyle = bodyStyles(styleIndex);
if ~thisStyle.HasExemplar
    if strcmpi(options.Fallback, 'error')
        error('The body style ''%s'' has no exemplar yet (suggested: %s)', thisStyle.BodyStyle, thisStyle.SuggestedVehicles);
    end
    warning('CarMesh3D:noExemplar', ['The body style ''%s'' has no exemplar yet (suggested: %s); ' ...
        'using the sample car at this vehicle''s size'], thisStyle.BodyStyle, thisStyle.SuggestedVehicles);
    vehicleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
    vehicleMesh.Source = 'Body-style template: no exemplar, the sample car at this vehicle''s size';
    vehicleMesh.BodyStyleInfo = struct('BodyStyle',thisStyle.BodyStyle, 'ExemplarID','', 'ExemplarName','the sample car', ...
        'WidthReference','all', 'WidthNote','no exemplar: the sample car', 'CandidateIDs',{{}}, 'SizeDifference',[]);
else
    %%%% The exemplar: as asked, or the one closest in size
    candidateIDs = thisStyle.ExemplarIDs;
    sizeNames = {'OverallLength','OverallWidth','OverallHeight','Wheelbase'};
    targetSize = cellfun(@(field) double(vehicleSpec.(field)), sizeNames);
    sizeDifference = nan(numel(candidateIDs), 1);
    for ith_candidate = 1:numel(candidateIDs)
        candidateFiles = fcn_CarMesh3D_findVehicleFiles(candidateIDs{ith_candidate}, DataFolder=options.DataFolder, FigNum=-1);
        candidate = load(candidateFiles.MeshFile, 'vehicleSpec');
        if isfield(candidate, 'vehicleSpec') && all(isfield(candidate.vehicleSpec, sizeNames))
            candidateSize = cellfun(@(field) double(candidate.vehicleSpec.(field)), sizeNames);
            sizeDifference(ith_candidate) = sqrt(mean(((candidateSize - targetSize)./targetSize).^2, 'omitnan'));
        end
    end
    if ~isempty(char(options.ExemplarID))
        exemplarIndex = find(strcmp(candidateIDs, char(options.ExemplarID)), 1);
        if isempty(exemplarIndex)
            error('%s is not one of the ''%s'' exemplars: %s', char(options.ExemplarID), thisStyle.BodyStyle, strjoin(candidateIDs, ', '));
        end
    else
        [~, exemplarIndex] = min(sizeDifference);      % (NaN, for a mesh without its spec, is never picked first)
    end
    exemplarID = candidateIDs{exemplarIndex};
    exemplarFiles = fcn_CarMesh3D_findVehicleFiles(exemplarID, DataFolder=options.DataFolder, FigNum=-1);
    loaded = load(exemplarFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
    vehicleMesh = loaded.vehicleMesh;
    exemplarSpec = loaded.vehicleSpec;

    %%%% The width: as the exemplar's was fit
    widthReference = 'all';
    if isfield(vehicleMesh, 'FitInfo') && isfield(vehicleMesh.FitInfo, 'WidthReference')
        widthReference = vehicleMesh.FitInfo.WidthReference;
    end
    fitSpec = vehicleSpec;
    widthNote = sprintf('the whole mesh to the width (%s, as the exemplar)', widthReference);
    if strcmpi(widthReference, 'mirrors')
        if ~isfield(fitSpec, 'WidthWithMirrors') || isempty(fitSpec.WidthWithMirrors) || isnan(fitSpec.WidthWithMirrors)
            mirrorRatio = exemplarSpec.WidthWithMirrors/exemplarSpec.OverallWidth;
            fitSpec.WidthWithMirrors = fitSpec.OverallWidth*mirrorRatio;
            widthNote = sprintf(['the width with mirrors estimated as %.3f m (the width times the exemplar''s ratio, ' ...
                '%.3f), the whole mesh fit to it'], fitSpec.WidthWithMirrors, mirrorRatio);
        else
            widthNote = 'the whole mesh to the width with mirrors (as the exemplar)';
        end
    end
    vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, fitSpec, WidthReference=widthReference, FigNum=-1);

    %%%% Names
    vehicleMesh.Source = sprintf('Body-style template ''%s'': %s, refit to this vehicle''s dimensions', ...
        thisStyle.BodyStyle, exemplarSpec.Name);
    vehicleMesh.BodyStyleInfo = struct('BodyStyle',thisStyle.BodyStyle, 'ExemplarID',exemplarID, ...
        'ExemplarName',exemplarSpec.Name, 'WidthReference',widthReference, 'WidthNote',widthNote, ...
        'CandidateIDs',{candidateIDs}, 'SizeDifference',sizeDifference);
end
if isfield(vehicleSpec, 'Name') && ~isempty(vehicleSpec.Name)
    vehicleMesh.Name = vehicleSpec.Name;
end

%%%% The body's color
bodyColor = options.BodyColor;
if isempty(bodyColor) && isfield(vehicleSpec, 'BodyColor')
    bodyColor = vehicleSpec.BodyColor;
end
if ~isempty(bodyColor) && isfield(vehicleMesh, 'FacePartIndex') && isfield(vehicleMesh, 'FaceColors')
    bodyPart = find(strcmp(vehicleMesh.PartNames, 'body'), 1);
    bodyFaces = vehicleMesh.FacePartIndex==bodyPart;
    vehicleMesh.FaceColors(bodyFaces,:) = repmat(reshape(bodyColor, 1, 3), sum(bodyFaces), 1);
end

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

    figure(figNum);
    clf;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=figNum);
    title({sprintf('%s', vehicleMesh.Name), sprintf('from the ''%s'' exemplar: %s', ...
        vehicleMesh.BodyStyleInfo.BodyStyle, vehicleMesh.BodyStyleInfo.ExemplarName)}, 'Interpreter','none');
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


