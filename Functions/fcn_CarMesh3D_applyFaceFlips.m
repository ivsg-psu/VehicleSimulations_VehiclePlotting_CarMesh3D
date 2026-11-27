function [vehicleMesh, info] = fcn_CarMesh3D_applyFaceFlips(vehicleMesh, flipsInput, options)
% fcn_CarMesh3D_applyFaceFlips
% Turns faces to the directions saved for them by the face-direction
% window (fcn_CarMesh3D_fixFaceDirections), matching them by position
% (step 1F of the plan of 2026-11-27). Each saved entry is a face's center
% and the direction its normal should point; the mesh's face nearest that
% center (within Tolerance) is turned to point that way, if it does not
% already. Applying the same flips twice changes nothing, so they can be
% replayed in a vehicle's build and again when its mesh is loaded (after
% fcn_CarMesh3D_orientFaces, which could turn them back).
%
% FORMAT:
%
%       [vehicleMesh, info] = fcn_CarMesh3D_applyFaceFlips(vehicleMesh, flipsInput,...
%           (Tolerance=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure (Vertices, Faces), in
%      meters.
%
%      flipsInput: the flips: a faceFlips structure (Points, N x 3;
%      Normals, N x 3), or the name of a faceFlips_<ID>.mat file (a file
%      that does not exist means no flips).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Tolerance: how far (meters) a face's center may be from a saved
%      point and still match it. Default 0.005 (the overlay lifting moves
%      faces 2 mm).
%
%      FigNum: a figure to plot the mesh with the turned faces in red. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with the matched faces pointing as saved (their
%      corners in the other order; FaceNormals, if present, negated).
%
%      info: a structure with NumSaved (entries), NumMatched (entries that
%      matched a face), NumTurned (faces turned now), NumMissing (entries
%      with no face within Tolerance) and Turned (the faces turned).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_meshPickTools
%
% EXAMPLES:
%
%       vehicleMesh = fcn_CarMesh3D_applyFaceFlips(vehicleMesh, 'faceFlips_2009_Honda_Fit_Sport.mat');
%
%       See the script: script_test_fcn_CarMesh3D_applyFaceFlips.m for a
%       full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_applyFaceFlips
%   % * First write (step 1F of the plan of 2026-11-27)

% TO-DO:
%
% (none)

arguments
    vehicleMesh
    flipsInput
    options.Tolerance = 0.005   % Meters: how near a face's center must be to a saved point
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
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
    if ~isstruct(vehicleMesh) || ~all(isfield(vehicleMesh, {'Vertices','Faces'}))
        error('vehicleMesh must be a CarMesh3D mesh structure (Vertices, Faces)');
    end
    if ~(ischar(flipsInput) || isstring(flipsInput) || isstruct(flipsInput))
        error('flipsInput must be a faceFlips structure or the name of a faceFlips file');
    end
    if ~(isnumeric(options.Tolerance) && isscalar(options.Tolerance) && options.Tolerance > 0)
        error('Tolerance must be a positive number of meters');
    end
end
flag_do_plots = 0;
if 0==flag_max_speed && ~isempty(options.FigNum)
    figNum = options.FigNum;
    flag_do_plots = 1;
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
faceFlips = struct('Points', zeros(0,3), 'Normals', zeros(0,3));
if ischar(flipsInput) || isstring(flipsInput)
    if isfile(flipsInput)
        loaded = load(char(flipsInput), 'faceFlips');
        if isfield(loaded, 'faceFlips')
            faceFlips = loaded.faceFlips;
        end
    end
else
    faceFlips = flipsInput;
end
points = zeros(0,3);
normals = zeros(0,3);
if isfield(faceFlips, 'Points') && isfield(faceFlips, 'Normals') && size(faceFlips.Points,1) == size(faceFlips.Normals,1)
    points = faceFlips.Points;
    normals = faceFlips.Normals;
end
numSaved = size(points,1);
info = struct('NumSaved', numSaved, 'NumMatched', 0, 'NumTurned', 0, 'NumMissing', 0, 'Turned', zeros(0,1));
numFaces = size(vehicleMesh.Faces,1);
if numSaved > 0 && numFaces > 0
    pick = fcn_CarMesh3D_meshPickTools(FigNum=-1);
    vertices = vehicleMesh.Vertices;
    faces = vehicleMesh.Faces;
    centers = pick.FaceCenters(vertices, faces);
    [nearestFace, nearestDistance] = pick.Nearest(centers, points);
    flagMatched = nearestDistance(:) <= options.Tolerance;
    matchedFaces = nearestFace(flagMatched);
    faceNormals = cross(vertices(faces(matchedFaces,2),:) - vertices(faces(matchedFaces,1),:), ...
        vertices(faces(matchedFaces,3),:) - vertices(faces(matchedFaces,1),:), 2);
    flagWrong = sum(faceNormals.*normals(flagMatched,:), 2) < 0;
    turned = unique(matchedFaces(flagWrong));
    vehicleMesh.Faces(turned,:) = vehicleMesh.Faces(turned, [1 3 2]);
    if isfield(vehicleMesh, 'FaceNormals') && size(vehicleMesh.FaceNormals,1) == numFaces
        vehicleMesh.FaceNormals(turned,:) = -vehicleMesh.FaceNormals(turned,:);
    end
    info.NumMatched = nnz(flagMatched);
    info.NumMissing = numSaved - info.NumMatched;
    info.NumTurned = numel(turned);
    info.Turned = turned(:);
end

%% Plot the results (for debugging)?
if flag_do_plots
    figure(figNum);
    clf;
    faceColors = repmat([0.8 0.8 0.8], numFaces, 1);
    faceColors(info.Turned,:) = repmat([0.9 0.1 0.1], info.NumTurned, 1);
    patch('Vertices', vehicleMesh.Vertices, 'Faces', vehicleMesh.Faces, 'FaceVertexCData', faceColors, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'flat');
    axis equal off;
    view(-35, 20);
    camlight headlight;
    title(sprintf('%d of %d saved flips matched; %d faces turned (red)', info.NumMatched, numSaved, info.NumTurned));
end

end % Ends main function
