function vehicleMesh = fcn_CarMesh3D_transferTextureColors(vehicleMesh, textureMesh, options)
% fcn_CarMesh3D_transferTextureColors

% Gives each face of a mesh the texture color and transparency of the
% nearest face of another mesh of the same model, read with
% fcn_CarMesh3D_readGLB. Used when a model is reduced in Blender (whose
% OBJ keeps no texture colors): the reduced faces lie on the download's
% surface, so the nearest download face facing the same way has the
% color painted there. Both meshes must be in the same axes (as they are
% straight from fcn_CarMesh3D_readGLB and fcn_CarMesh3D_importMesh of the
% Blender conversion, before normalizing).
%
% FORMAT:
%
%       vehicleMesh = fcn_CarMesh3D_transferTextureColors(vehicleMesh, textureMesh,...
%           (MaxDistance=meters), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh structure (for example, imported from
%      the Blender-reduced OBJ).
%
%      textureMesh: the download read by fcn_CarMesh3D_readGLB (it has the
%      fields FaceTextureColors, FaceTextureAlpha, SeeThroughReliable).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      MaxDistance: faces whose center is farther than this from every
%      download face center (in the meshes' units) get a neutral gray and
%      alpha 1. Default is Inf (every face takes its nearest).
%
%      FigNum: a figure to plot the mesh in the transferred colors. If
%      empty or omitted, no plot is made. If set to -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the same structure with FaceTextureColors (M x 3),
%      FaceTextureAlpha (M x 1), and SeeThroughReliable added.
%
% DEPENDENCIES:
%
%      knnsearch (Statistics and Machine Learning Toolbox)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_transferTextureColors.m
%       for a full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_transferTextureColors
%   % * First write (texture colors for Blender-reduced meshes)

% TO-DO:
%
% (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleMesh
    textureMesh
    options.MaxDistance = Inf    % Farther faces get gray
    options.FigNum = []          % Figure to plot into; [] for no plot, -1 for fast mode
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
        if ~isstruct(vehicleMesh) || ~isfield(vehicleMesh,'Vertices') || ~isfield(vehicleMesh,'Faces')
            error('vehicleMesh must be a CarMesh3D mesh structure');
        end
        if ~isstruct(textureMesh) || ~isfield(textureMesh,'FaceTextureColors')
            error('textureMesh must come from fcn_CarMesh3D_readGLB (it needs FaceTextureColors)');
        end
        if ~isnumeric(options.MaxDistance) || ~isscalar(options.MaxDistance) || options.MaxDistance<=0
            error('MaxDistance must be a positive number');
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

%% Main code starts here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%See: http://patorjk.com/software/taag/#p=display&f=Big&t=Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[targetCenters, targetNormals] = fcn_INTERNAL_centersAndNormals(vehicleMesh);
[sourceCenters, sourceNormals] = fcn_INTERNAL_centersAndNormals(textureMesh);

% The nearest few download faces; of those, the nearest that faces the
% same way (so a door's outside does not take the color of its inside)
numNeighbors = min(8, size(sourceCenters,1));
[neighbors, distances] = knnsearch(sourceCenters, targetCenters, 'K', numNeighbors);
facing = zeros(size(neighbors));
for ith_neighbor = 1:numNeighbors
    facing(:,ith_neighbor) = sum(sourceNormals(neighbors(:,ith_neighbor),:).*targetNormals, 2);
end
score = distances + 1e6*(facing < 0.5);   % (faces facing away last)
[~, best] = min(score, [], 2);
chosen = neighbors(sub2ind(size(neighbors), (1:size(neighbors,1))', best));
chosenDistance = distances(sub2ind(size(distances), (1:size(distances,1))', best));

faceColors = textureMesh.FaceTextureColors(chosen,:);
faceAlpha = textureMesh.FaceTextureAlpha(chosen);
flagFar = chosenDistance > options.MaxDistance;
faceColors(flagFar,:) = repmat([0.5 0.5 0.5], sum(flagFar), 1);
faceAlpha(flagFar) = 1;

vehicleMesh.FaceTextureColors = faceColors;
vehicleMesh.FaceTextureAlpha = faceAlpha;
if isfield(textureMesh,'SeeThroughReliable')
    vehicleMesh.SeeThroughReliable = textureMesh.SeeThroughReliable;
else
    vehicleMesh.SeeThroughReliable = true;
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
    patch('Vertices',vehicleMesh.Vertices, 'Faces',vehicleMesh.Faces, ...
        'FaceVertexCData',vehicleMesh.FaceTextureColors, 'FaceColor','flat', 'EdgeColor','none');
    axis equal;
    view(-55,20);
    title(sprintf('Texture colors on %d faces (%d too far, gray)', size(vehicleMesh.Faces,1), sum(flagFar)));
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

%% fcn_INTERNAL_centersAndNormals
function [centers, normals] = fcn_INTERNAL_centersAndNormals(thisMesh)
% Each face's center and unit normal
corner1 = thisMesh.Vertices(thisMesh.Faces(:,1),:);
corner2 = thisMesh.Vertices(thisMesh.Faces(:,2),:);
corner3 = thisMesh.Vertices(thisMesh.Faces(:,3),:);
centers = (corner1 + corner2 + corner3)/3;
normals = cross(corner2 - corner1, corner3 - corner1, 2);
normals = normals./max(vecnorm(normals,2,2), eps);
end % Ends fcn_INTERNAL_centersAndNormals
