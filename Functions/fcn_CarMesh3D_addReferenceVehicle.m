function referenceList = fcn_CarMesh3D_addReferenceVehicle(vehicleID, vehicleMesh, referenceGif, options)
% fcn_CarMesh3D_addReferenceVehicle
% Adds a finished, checked vehicle to the REFERENCE VEHICLE LIST: the
% list of vehicles that are ready to use. Three things are updated:
%
%   1. The vehicle's reference GIF is copied to Images\vehicles\<ID>.gif
%      (usually check_09_drive.gif from fcn_CarMesh3D_runVehicleChecks:
%      the standard test motion in the standard scene).
%   2. The list file, Data\referenceVehicles.csv, gets a row for the
%      vehicle (or its row is updated): ID, name, size, wheelbase, face
%      count, model license, GIF, and the date. Read this file to see the
%      reference vehicles without searching the Data folder.
%   3. The table of reference vehicles in the README (between the lines
%      <!-- REFERENCE VEHICLES START --> and <!-- REFERENCE VEHICLES END -->)
%      is rewritten from the list file, with each vehicle's GIF.
%
% FORMAT:
%
%       referenceList = fcn_CarMesh3D_addReferenceVehicle(vehicleID,...
%           vehicleMesh, referenceGif, (ListFile=file),...
%           (ImagesFolder=folder), (ReadmeFile=file), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleID: the vehicle ID (YEAR_Make_Model_Trimline, see
%      fcn_CarMesh3D_findVehicleFiles).
%
%      vehicleMesh: the finished mesh (for its size and face count).
%
%      referenceGif: the GIF to show for this vehicle.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      ListFile: the list file. Default [] is Data\referenceVehicles.csv.
%
%      ImagesFolder: where reference GIFs are kept. Default [] is
%      Images\vehicles.
%
%      ReadmeFile: the README to update. Default [] is the README.md in
%      the CarMesh3D folder. Use '' to not update a README.
%
%      FigNum: if set to -1, input checking is skipped (fast mode). The
%      function makes no plot.
%
% OUTPUTS:
%
%      referenceList: the list, as a table (one row per vehicle).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       % At the end of a vehicle script, after the checks:
%       fcn_CarMesh3D_addReferenceVehicle(vehicleID, vehicleMesh, ...
%           fullfile(vehicleFiles.ChecksFolder,'check_09_drive.gif'));
%
%       See the script: script_test_fcn_CarMesh3D_addReferenceVehicle.m for a full
%       test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addReferenceVehicle
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addReferenceVehicle
%   % * The README table shows each vehicle's folder as it is filed
%   %   % (Data/BodyStyles/<Style>/<ID>), found by fcn_CarMesh3D_findVehicleFiles
%   % * Reads LICENSE.txt in the standard format (License:, License
%   %   % meaning:, Credits:, Source website:, Author:): the license column
%   %   % shows the credits, or the license when no credits are required

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_addReferenceVehicle
%   % * A way to remove a vehicle from the list



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleID
    vehicleMesh
    referenceGif
    options.ListFile = []       % [] for Data\referenceVehicles.csv
    options.ImagesFolder = []   % [] for Images\vehicles
    options.ReadmeFile = []     % [] for the CarMesh3D README.md; '' for none
    options.FigNum = []         % -1 for fast mode (no input checks)
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

        % Check the vehicleID input (findVehicleFiles checks the convention)
        fcn_CarMesh3D_findVehicleFiles(vehicleID);

        % Check the vehicleMesh input
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces')
            error('vehicleMesh must be a CarMesh3D mesh');
        end

        % Check the referenceGif input
        if ~(ischar(referenceGif) || isstring(referenceGif)) || ~isfile(referenceGif)
            error('referenceGif not found: %s', char(string(referenceGif)));
        end
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

rootFolder = fileparts(fileparts(mfilename('fullpath')));
vehicleID = char(vehicleID);
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
listFile = options.ListFile;
if isempty(listFile)
    listFile = fullfile(rootFolder,'Data','referenceVehicles.csv');
end
imagesFolder = options.ImagesFolder;
if isempty(imagesFolder)
    imagesFolder = fullfile(rootFolder,'Images','vehicles');
end
readmeFile = options.ReadmeFile;
if isnumeric(readmeFile) && isempty(readmeFile)
    readmeFile = fullfile(rootFolder,'README.md');
end

%%%%
% 1. Copy the reference GIF
if ~isfolder(imagesFolder)
    mkdir(imagesFolder);
end
gifFile = fullfile(imagesFolder, [vehicleID '.gif']);
if ~strcmp(char(referenceGif), gifFile)
    copyfile(char(referenceGif), gifFile);
end

%%%%
% 2. Add (or update) the vehicle's row in the list file
lowCorner = min(vehicleMesh.Vertices,[],1);
highCorner = max(vehicleMesh.Vertices,[],1);
modelLicense = fcn_INTERNAL_readLicense(vehicleFiles.ModelFolder);
newRow = table({vehicleID}, {vehicleFiles.Name}, round(highCorner(1)-lowCorner(1),3), ...
    round(highCorner(2)-lowCorner(2),3), round(highCorner(3)-lowCorner(3),3), ...
    fcn_INTERNAL_wheelbase(vehicleMesh), size(vehicleMesh.Faces,1), {modelLicense}, ...
    {fcn_INTERNAL_relativePath(gifFile, rootFolder)}, {char(datetime('now','Format','yyyy-MM-dd'))}, ...
    'VariableNames', {'ID','Name','Length_m','Width_m','Height_m','Wheelbase_m','Faces','ModelLicense','GIF','Added'});
if isfile(listFile)
    referenceList = readtable(listFile, 'TextType','char', 'Delimiter',',');
    referenceList(strcmp(referenceList.ID, vehicleID),:) = [];
    referenceList = [referenceList; newRow];
else
    referenceList = newRow;
end
referenceList = sortrows(referenceList, 'ID');
writetable(referenceList, listFile);

%%%%
% 3. Rewrite the README's table of reference vehicles
if ~isempty(readmeFile)
    fcn_INTERNAL_updateReadme(readmeFile, referenceList);
end

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
% (No plot)

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

%% fcn_INTERNAL_readLicense
function licenseText = fcn_INTERNAL_readLicense(modelFolder)
% From the model's LICENSE.txt (the standard format: License:, License
% meaning:, Credits:, Source website:, Author: lines): the Credits line if
% it has one, otherwise the License line. An older file without these
% labels gives its first line. 'unknown' if there is no file.
licenseText = 'unknown';
licenseFile = fullfile(modelFolder, 'LICENSE.txt');
if isfile(licenseFile)
    lines = strtrim(splitlines(strtrim(fileread(licenseFile))));
    lines = lines(~cellfun(@isempty, lines));
    creditsLine = lines(startsWith(lines, 'Credits:', 'IgnoreCase', true));
    licenseLine = lines(startsWith(lines, 'License:', 'IgnoreCase', true));
    if ~isempty(creditsLine) && strlength(strtrim(extractAfter(creditsLine{1}, 8))) > 0
        licenseText = char(strtrim(extractAfter(creditsLine{1}, 8)));
    elseif ~isempty(licenseLine)
        licenseText = char(strtrim(extractAfter(licenseLine{1}, 8)));
    elseif ~isempty(lines)
        licenseText = lines{1};
    end
end
licenseText = strrep(licenseText, ',', ';'); % Keep the CSV simple
end % Ends fcn_INTERNAL_readLicense

%% fcn_INTERNAL_wheelbase
function wheelbase = fcn_INTERNAL_wheelbase(vehicleMesh)
% The wheelbase from the fitted axle positions (NaN if not fitted)
wheelbase = NaN;
if isfield(vehicleMesh,'AxleX') && numel(vehicleMesh.AxleX)==2
    wheelbase = round(abs(diff(vehicleMesh.AxleX)),3);
end
end % Ends fcn_INTERNAL_wheelbase

%% fcn_INTERNAL_relativePath
function relativePath = fcn_INTERNAL_relativePath(fileName, rootFolder)
% The path relative to the CarMesh3D folder, with forward slashes (for
% links in the README)
relativePath = char(fileName);
if startsWith(relativePath, [rootFolder filesep])
    relativePath = relativePath(length(rootFolder)+2:end);
end
relativePath = strrep(relativePath, '\', '/');
end % Ends fcn_INTERNAL_relativePath

%% fcn_INTERNAL_updateReadme
function fcn_INTERNAL_updateReadme(readmeFile, referenceList)
% Replaces the text between the start and end markers with a table made
% from the list
startMarker = '<!-- REFERENCE VEHICLES START -->';
endMarker = '<!-- REFERENCE VEHICLES END -->';
readmeText = fileread(readmeFile);
startIndex = strfind(readmeText, startMarker);
endIndex = strfind(readmeText, endMarker);
if isscalar(startIndex) && isscalar(endIndex) && endIndex > startIndex
    tableLines = {startMarker, '', ...
        '| Vehicle | Animation | Size L x W x H (m) | Wheelbase (m) | Faces | Model license |', ...
        '|---|---|---|---|---|---|'};
    for ith_vehicle = 1:height(referenceList)
        thisRow = referenceList(ith_vehicle,:);
        % (the vehicle's folder, wherever it is filed under Data)
        thisFiles = fcn_CarMesh3D_findVehicleFiles(thisRow.ID{1}, FigNum=-1);
        thisFolder = fcn_INTERNAL_relativePath(thisFiles.Folder, fileparts(fileparts(mfilename('fullpath'))));
        tableLines{end+1} = sprintf('| **%s**<br>`%s` | ![%s](%s) | %.2f x %.2f x %.2f | %.3f | %d | %s |', ...
            thisRow.Name{1}, thisFolder, thisRow.ID{1}, thisRow.GIF{1}, thisRow.Length_m, thisRow.Width_m, ...
            thisRow.Height_m, thisRow.Wheelbase_m, thisRow.Faces, thisRow.ModelLicense{1}); %#ok<AGROW>
    end
    tableLines = [tableLines, {'', sprintf('(This table is written by fcn_CarMesh3D_addReferenceVehicle from Data/referenceVehicles.csv; %d vehicles.)', height(referenceList)), '', endMarker}];
    newText = [readmeText(1:startIndex-1), strjoin(tableLines, newline), readmeText(endIndex+length(endMarker):end)];
    fileID = fopen(readmeFile,'w');
    fwrite(fileID, newText);
    fclose(fileID);
else
    warning('on','backtrace');
    warning('The README (%s) has no reference-vehicle markers, so its table was not updated. Add the lines %s and %s where the table should go.', ...
        readmeFile, startMarker, endMarker);
end
end % Ends fcn_INTERNAL_updateReadme
