function [vehicleMesh, numFlipped, numRemoved] = fcn_CarMesh3D_fixFlippedFaces(vehicleMesh, options)
% fcn_CarMesh3D_fixFlippedFaces

% Finds the faces of a mesh that are seen only from behind (inside-out
% panels, which look dark), and flips them, quickly: the mesh is drawn
% from 14 directions (the six sides and eight corners) with each face in
% its own color, so each pixel tells which face is seen. A face seen
% mostly from behind (more than twice as many pixels from behind as from
% the front, over all views) is flipped. A second set
% of pictures leaves out the see-through faces (glass), so the inside of
% the car seen through the windows is checked too.
%
% A mesh that is its own mirror image (Y to -Y, as fcn_CarMesh3D_simplifyMesh
% makes with Symmetric=true) gets the same decision on both sides: each
% face is paired with its mirror twin, their pixel counts are pooled, and
% both are set from the one decision.
%
% Double layers can also be removed (RemoveDoubleLayers, off by default,
% experimental): some downloads
% model a panel as two skins a few millimeters apart, back to back (one
% facing out, one facing in, triangulated differently). Faces that close
% flicker in MATLAB (whichever is drawn first wins), so the inner skin
% shows in patches. Of each back-to-back pair (one face's center within
% 3 mm of the other face, inside it, normals opposite), the face seen
% less from the front is deleted (on a tie, the one facing the car's
% center).
%
% This does the job of the visibility check in fcn_CarMesh3D_simplifyMesh
% (VisibilityCheck=true, which casts two rays from every face) in a few
% seconds instead of about a minute, so fast first looks can use it.
%
% FORMAT:
%
%       [vehicleMesh, numFlipped, numRemoved] = fcn_CarMesh3D_fixFlippedFaces(vehicleMesh,...
%           (ImageWidth=pixels), (Symmetric=flag), (FlagRemoveDoubleLayers=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a CarMesh3D mesh (Vertices, Faces; FaceAlpha if it has
%      see-through faces; FaceNormals is updated if present).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      ImageWidth: pixels across each picture. Default 700.
%
%      FlagRemoveDoubleLayers: true to delete the inner skin of back-to-back
%      double layers; false (default) keeps every face. EXPERIMENTAL: on
%      the 2021 Subaru Outback it removed few of the cladding's inner
%      faces and deleted the front of the grille's thin bars.
%
%      Symmetric: 'auto' (default) pairs faces with their mirror twins
%      when at least 90% of the faces have one; true always pairs the
%      faces that have one; false never pairs.
%
%      FigNum: a figure to plot the mesh with the flipped faces marked in
%      red. If empty or omitted, no plot is made. If set to -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      vehicleMesh: the mesh with those faces flipped (their corner order
%      reversed) and FaceNormals updated.
%
%      numFlipped: how many faces were flipped.
%
%      numRemoved: how many inner-skin faces of double layers were deleted
%      (every per-face field is cut the same way).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotVehicle (only if plotting); figure, patch, print
%      (MATLAB base)
%
% EXAMPLES:
%
%       [vehicleMesh, numFlipped] = fcn_CarMesh3D_fixFlippedFaces(vehicleMesh, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_fixFlippedFaces.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fixFlippedFaces
%   % * First write: a fast flipped-face fix from face-number pictures
%   %   % (found while building fcn_CarMesh3D_compareToOriginal; the front
%   %   % bumper of the 2010 Toyota Camry was inside out in a first look)
%   % * Symmetric: mirror twins get one decision
%   % * RemoveDoubleLayers (off by default): the inner skin of back-to-back
%   %   % double layers is deleted (the 2021 Subaru Outback's lower cladding has two skins
%   %   % a few millimeters apart; the inner one showed in patches below
%   %   % one sill, found by fcn_CarMesh3D_compareToOriginal's low views)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fixFlippedFaces
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    vehicleMesh
    options.ImageWidth = 700    % Pixels across each picture
    options.Symmetric = 'auto'  % Pair faces with their mirror twins: 'auto', true, false
    options.FlagRemoveDoubleLayers = false % Delete the inner skin of back-to-back double layers (experimental)
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
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

        if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces'})))
            error('vehicleMesh must be a mesh structure with Vertices and Faces');
        end
        if ~(isnumeric(options.ImageWidth) && isscalar(options.ImageWidth) && options.ImageWidth >= 100)
            error('ImageWidth must be a number of pixels, 100 or more');
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

vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
numFaces = size(faces,1);
corner1 = vertices(faces(:,1),:);
faceNormals = cross(vertices(faces(:,2),:) - corner1, vertices(faces(:,3),:) - corner1, 2);
faceNormals = faceNormals./max(vecnorm(faceNormals,2,2), eps);

% The directions: six sides and eight corners
directions = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];
[cornerX, cornerY, cornerZ] = ndgrid([-1 1], [-1 1], [-1 1]);
directions = [directions; [cornerX(:) cornerY(:) cornerZ(:)]/sqrt(3)];

% The see-through faces, left out of the second set of pictures
flagSeeThrough = false(numFaces,1);
if isfield(vehicleMesh,'FaceAlpha') && numel(vehicleMesh.FaceAlpha)==numFaces
    flagSeeThrough = vehicleMesh.FaceAlpha(:) < 0.999;
end
faceSets = {(1:numFaces)'};
if any(flagSeeThrough)
    faceSets{end+1} = find(~flagSeeThrough);
end

boxLow = min(vertices,[],1) - 0.05;
boxHigh = max(vertices,[],1) + 0.05;
seenFront = zeros(numFaces,1);   % (pixels, over all views)
seenBack = zeros(numFaces,1);
for ith_set = 1:numel(faceSets)
    theseFaces = faceSets{ith_set};
    for ith_direction = 1:size(directions,1)
        towardCamera = directions(ith_direction,:);
        faceIds = fcn_INTERNAL_faceIds(vertices, faces(theseFaces,:), towardCamera, boxLow, boxHigh, round(options.ImageWidth));
        % (pixels of each face seen, from the front or from behind)
        pixelCounts = accumarray(faceIds(faceIds>0), 1, [numel(theseFaces) 1]);
        visible = find(pixelCounts>0);
        facing = faceNormals(theseFaces(visible),:)*towardCamera(:);
        seenFront(theseFaces(visible)) = seenFront(theseFaces(visible)) + pixelCounts(visible).*(facing > 0.05);
        seenBack(theseFaces(visible)) = seenBack(theseFaces(visible)) + pixelCounts(visible).*(facing < -0.05);
    end
end

% Mirror twins: the face whose center is this face's center with Y
% negated (within 0.1 mm). A twin whose normal is the mirror of this
% face's normal has its front on the same side; one whose normal is the
% opposite has its front where this face has its back.
faceCenters = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
[twin, twinDistance] = knnsearch(faceCenters, faceCenters.*[1 -1 1]);
flagTwin = twinDistance < 1e-4 & twin ~= (1:numFaces)';
flagPair = false;
if islogical(options.Symmetric) || isnumeric(options.Symmetric)
    flagPair = logical(options.Symmetric);
elseif strcmpi(options.Symmetric,'auto')
    flagPair = mean(flagTwin) >= 0.9;
end
pooledFront = seenFront;
pooledBack = seenBack;
if flagPair
    mirroredNormals = faceNormals(twin,:).*[1 -1 1];
    flagSameWay = sum(mirroredNormals.*faceNormals, 2) > 0;
    flagSame = flagTwin & flagSameWay;
    flagOpposite = flagTwin & ~flagSameWay;
    pooledFront(flagSame) = seenFront(flagSame) + seenFront(twin(flagSame));
    pooledBack(flagSame) = seenBack(flagSame) + seenBack(twin(flagSame));
    pooledFront(flagOpposite) = seenFront(flagOpposite) + seenBack(twin(flagOpposite));
    pooledBack(flagOpposite) = seenBack(flagOpposite) + seenFront(twin(flagOpposite));
end

flagFlip = pooledBack > 2*pooledFront;   % (seen mostly from behind, by pixels)
if flagPair
    % (twins that point opposite ways: one of them is surely wrong, so a
    % simple majority decides, and exactly one of the two flips)
    flagFlip(flagOpposite) = pooledBack(flagOpposite) > pooledFront(flagOpposite) | ...
        (pooledBack(flagOpposite) == pooledFront(flagOpposite) & twin(flagOpposite) < find(flagOpposite));   % (a tie: the later face flips)
end
numFlipped = sum(flagFlip);
vehicleMesh.Faces(flagFlip,:) = faces(flagFlip,[1 3 2]);
if isfield(vehicleMesh,'FaceNormals') && size(vehicleMesh.FaceNormals,1)==numFaces
    vehicleMesh.FaceNormals(flagFlip,:) = -faceNormals(flagFlip,:);
end

% Double layers: the inner skin of back-to-back pairs is deleted
numRemoved = 0;
flagRemove = false(numFaces,1);
if options.FlagRemoveDoubleLayers && numFaces > 1
    newNormals = faceNormals;
    newNormals(flagFlip,:) = -faceNormals(flagFlip,:);
    % (pixels seen from the front, after the flips; pooled with the twin)
    frontPixels = seenFront;
    frontPixels(flagFlip) = seenBack(flagFlip);
    if flagPair
        twinFront = frontPixels(twin);
        frontPixels(flagTwin) = frontPixels(flagTwin) + twinFront(flagTwin);
    end
    flagRemove = fcn_INTERNAL_doubleLayers(vertices, faces, faceCenters, newNormals, frontPixels);
    if flagPair
        % (a twin of a removed face is removed too)
        flagRemove(twin(flagRemove & flagTwin)) = true;
    end
    numRemoved = sum(flagRemove);
    if numRemoved > 0
        keepFaces = ~flagRemove;
        for fieldName = reshape(fieldnames(vehicleMesh),1,[])
            thisValue = vehicleMesh.(fieldName{1});
            if ~strcmp(fieldName{1},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==numFaces
                vehicleMesh.(fieldName{1}) = thisValue(keepFaces,:);
            end
        end
    end
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
    faceColors = repmat([0.8 0.8 0.8], numFaces, 1);
    faceColors(flagFlip,:) = repmat([0.9 0 0], numFlipped, 1);
    faceColors = faceColors(~flagRemove,:);   % (the double layers' removed faces)
    patch('Vertices',vertices, 'Faces',vehicleMesh.Faces, 'FaceVertexCData',faceColors, ...
        'FaceColor','flat', 'EdgeColor','none', 'FaceLighting','flat');
    axis equal off;
    view(-55,20);
    camlight headlight;
    title(sprintf('%d faces flipped (red): seen only from behind; %d inner-skin faces removed', numFlipped, numRemoved));
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

%% fcn_INTERNAL_doubleLayers
function flagRemove = fcn_INTERNAL_doubleLayers(vertices, faces, faceCenters, faceNormals, frontPixels)
% The inner face of each back-to-back pair: a face whose center lies
% within 3 mm of a nearby face's plane, inside that face, with the two
% normals opposite
numFaces = size(faces,1);
flagRemove = false(numFaces,1);
numNeighbors = min(16, numFaces);
neighbors = knnsearch(faceCenters, faceCenters, 'K', numNeighbors);
carCenter = (min(vertices,[],1) + max(vertices,[],1))/2;
for ith_neighbor = 2:numNeighbors
    other = neighbors(:,ith_neighbor);
    flagOpposite = sum(faceNormals.*faceNormals(other,:), 2) < -0.9;
    % (this face's center, in the other face's plane and triangle)
    corner1 = vertices(faces(other,1),:);
    edge1 = vertices(faces(other,2),:) - corner1;
    edge2 = vertices(faces(other,3),:) - corner1;
    offset = faceCenters - corner1;
    flagClose = abs(sum(offset.*faceNormals(other,:), 2)) < 0.003;
    dot11 = sum(edge1.*edge1,2); dot12 = sum(edge1.*edge2,2); dot22 = sum(edge2.*edge2,2);
    dotP1 = sum(offset.*edge1,2); dotP2 = sum(offset.*edge2,2);
    denominator = max(dot11.*dot22 - dot12.^2, eps);
    weight1 = (dot22.*dotP1 - dot12.*dotP2)./denominator;
    weight2 = (dot11.*dotP2 - dot12.*dotP1)./denominator;
    flagInside = weight1 >= -0.01 & weight2 >= -0.01 & weight1 + weight2 <= 1.01;
    flagPairFound = flagOpposite & flagClose & flagInside;
    % (of the two, the one seen less from the front; on a tie, the one
    % facing the car's center)
    thisFaces = find(flagPairFound);
    otherFaces = other(flagPairFound);
    flagThisInner = frontPixels(thisFaces) < frontPixels(otherFaces);
    flagTie = frontPixels(thisFaces) == frontPixels(otherFaces);
    facingCenter = sum(faceNormals(thisFaces,:).*(carCenter - faceCenters(thisFaces,:)), 2) > 0;
    flagThisInner(flagTie) = facingCenter(flagTie);
    flagRemove(thisFaces(flagThisInner)) = true;
    flagRemove(otherFaces(~flagThisInner)) = true;
end
end % Ends fcn_INTERNAL_doubleLayers

%% fcn_INTERNAL_faceIds
function faceIds = fcn_INTERNAL_faceIds(vertices, faces, towardCamera, boxLow, boxHigh, imageWidth)
% Which face (row of faces) is seen at each pixel, 0 for the background:
% each face drawn unlit in its own color (its number in 24 bits), with an
% orthographic camera looking along -towardCamera at the box
numFaces = size(faces,1);
faceNumbers = (1:numFaces)';
idColors = [floor(faceNumbers/65536), floor(mod(faceNumbers,65536)/256), mod(faceNumbers,256)]/255;
imageHeight = round(imageWidth*0.75);
figureHandle = figure('Visible','off', 'Color',[0 0 0], 'Units','pixels', ...
    'Position',[0 0 imageWidth imageHeight], 'InvertHardcopy','off');
set(figureHandle, 'GraphicsSmoothing','off');   % (exact face colors)
axesHandle = axes('Parent',figureHandle, 'Position',[0 0 1 1], 'Color',[0 0 0]);
patch(axesHandle, 'Vertices',vertices, 'Faces',faces, 'FaceVertexCData',idColors, ...
    'FaceColor','flat', 'EdgeColor','none', 'FaceLighting','none');
axis(axesHandle,'off');
set(axesHandle, 'XLim',[boxLow(1) boxHigh(1)], 'YLim',[boxLow(2) boxHigh(2)], 'ZLim',[boxLow(3) boxHigh(3)], ...
    'DataAspectRatio',[1 1 1], 'Projection','orthographic');
if abs(towardCamera(3)) > 0.9
    upGuess = [1 0 0];
else
    upGuess = [0 0 1];
end
pictureRight = cross(upGuess, towardCamera);
pictureRight = pictureRight/norm(pictureRight);
pictureUp = cross(towardCamera, pictureRight);
[cornerX, cornerY, cornerZ] = ndgrid([boxLow(1) boxHigh(1)], [boxLow(2) boxHigh(2)], [boxLow(3) boxHigh(3)]);
boxCorners = [cornerX(:) cornerY(:) cornerZ(:)];
neededHeight = 1.04*max(range(boxCorners*pictureUp(:)), range(boxCorners*pictureRight(:))*imageHeight/imageWidth);
cameraDistance = 10*norm(boxHigh - boxLow);
set(axesHandle, 'CameraTarget',(boxLow + boxHigh)/2, 'CameraPosition',(boxLow + boxHigh)/2 + cameraDistance*towardCamera, ...
    'CameraUpVector',pictureUp, 'CameraViewAngle',2*atand(neededHeight/2/cameraDistance));
picture = print(figureHandle, '-RGBImage', '-r96', '-image');
close(figureHandle);
faceIds = double(picture(:,:,1))*65536 + double(picture(:,:,2))*256 + double(picture(:,:,3));
faceIds(faceIds > numFaces) = 0;
end % Ends fcn_INTERNAL_faceIds
