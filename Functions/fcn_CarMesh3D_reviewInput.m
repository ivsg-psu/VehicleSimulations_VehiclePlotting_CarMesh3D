function vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, options)
% fcn_CarMesh3D_reviewInput
% Everything a V&V assessment needs about one vehicle, gathered once: its
% files, its finished mesh with the saved label fixes, its name and body
% style. The V&V GUI (fcn_CarMesh3D_reviewVehicle) makes it once per
% vehicle and passes the same structure to every assessment function, so
% each assessment draws from the same data without loading it again. An
% assessment run by itself at the prompt, with a vehicle ID, makes it
% too.
%
% FORMAT:
%
%       vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or a vehicle's
%      folder (such as a demo copy's), as fcn_CarMesh3D_findVehicleFiles
%      takes; or a structure this function made (returned as it is).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used (nothing is plotted); -1 for fast mode.
%
% OUTPUTS:
%
%      vehicle: a structure with
%           ID, Name: the vehicle's ID and its readable name
%           Files: fcn_CarMesh3D_findVehicleFiles's structure
%           Mesh: the finished mesh with the saved label fixes
%               (fcn_CarMesh3D_meshWithLabelEdits)
%           MeshSource: where the mesh came from (that function's Source)
%           BodyStyle: the body style ID, such as 'hatchback'; for a copy
%               kept outside the repo, the style of the repo's vehicle with
%               the same ID ('' if none)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_meshWithLabelEdits
%
% EXAMPLES:
%
%       vehicle = fcn_CarMesh3D_reviewInput('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_reviewInput.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_reviewInput
%   % * First write (the V&V design file, section 2: the same inputs for
%   %   % every assessment)

% TO-DO:
%
% (none)

arguments
    vehicleInput            % A vehicle ID or folder, or this function's structure
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
    if ~(ischar(vehicleInput) || isstring(vehicleInput) || isstruct(vehicleInput))
        error('CarMesh3D:badInput', 'vehicleInput must be a vehicle ID, a vehicle folder, or a structure from fcn_CarMesh3D_reviewInput.');
    end
end

%% Main code
if isstruct(vehicleInput)
    if ~all(isfield(vehicleInput, {'ID', 'Files', 'Mesh'}))
        error('CarMesh3D:badInput', 'A structure given must come from fcn_CarMesh3D_reviewInput (fields ID, Files, Mesh).');
    end
    vehicle = vehicleInput;
    return;
end

files = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
if ~files.Found || ~files.HasMesh
    error('CarMesh3D:noMesh', 'No finished mesh for %s (looked for %s).', char(vehicleInput), files.MeshFile);
end
[mesh, meshInfo] = fcn_CarMesh3D_meshWithLabelEdits(files.Folder, FigNum=-1);

bodyStyle = files.BodyStyle;
if isempty(bodyStyle)
    % (a copy kept outside the repo: the style of the repo's vehicle with
    % the same ID, rule G40 part 3)
    try
        repoFiles = fcn_CarMesh3D_findVehicleFiles(files.ID, FigNum=-1);
        if repoFiles.Found
            bodyStyle = repoFiles.BodyStyle;
        end
    catch
    end
end

vehicle = struct('ID', files.ID, 'Name', files.Name, 'Files', files, 'Mesh', mesh, ...
    'MeshSource', meshInfo.Source, 'BodyStyle', bodyStyle);

end % Ends main function
