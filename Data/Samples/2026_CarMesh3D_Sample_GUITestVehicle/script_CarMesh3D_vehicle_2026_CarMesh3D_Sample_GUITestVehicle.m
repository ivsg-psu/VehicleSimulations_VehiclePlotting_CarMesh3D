% script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GUITestVehicle
% Makes the GUI TEST VEHICLE: a small, made-up vehicle that has every
% feature the label tools show, so their windows and tests can exercise
% all of it (Sean, 2026-11-23 13:12: real downloads such as the 2009 Fit
% lack some lamps and hidden faces). It is NOT a real vehicle and is not
% meant for animation; it lives with the samples, and its files are small
% enough for git.
%
% It starts from the built-in sample sedan (its finished mesh, in
% Data/Samples/2026_CarMesh3D_Sample_GenericSedan) and adds, as small
% boxes, then labels them with fcn_CarMesh3D_editLabels (so labeling is
% tested the way vehicles use it):
%   * all six lamp types, on both sides: low beams (the sample's
%     headlights), high beams (inboard), front and rear turn signals,
%     a running-light strip, tail lights (the sample's, which are also
%     turn signals: a lamp with two functions), and backup lights
%   * a clear glass cover in front of each headlight (a lamp that is
%     also glass)
%   * trim: front and rear bumpers, mirrors
%   * interior objects: two front seats, a steering wheel, a console
%   * two hidden sets: 'hidden' (a muffler under the rear) and 'hard top'
%     (a roof panel)
% and its own photos: pictures of itself, drawn every 30 degrees, saved
% as photos/ViewInDegrees_<angle>.jpg, so the photo dial and photo
% options are exercised too.
%
% Run it again whenever the sample sedan or the label tools change. It
% writes, in this folder: vehicleMesh_<ID>.mat, vehicleOutline_<ID>.mat,
% photos/ViewInDegrees_*.jpg, and model/LICENSE.txt (CC0: made here).
%
% This script was written on 2026_11_23 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GUITestVehicle
%   % * The vehicle and its right-side boxes are exact mirror images (Sean, 16:12: painting
%   %   % could not mirror); photos kept unless flagRedrawPhotos
%   % * First version (Sean, 13:12; design file
%   %   % Documents/Documentation_CarMesh3D_GUIdesign_paintLabels.md, P1)

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GUITestVehicle
%   % * Every lamp type (11, from fcn_CarMesh3D_lampTypes): fog lamps, side
%   %   % markers, rear reflectors, a license plate lamp and a roof beacon
%   %   % (warning) added, so the GUIs' tests see every lamp type

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_vehicle_2026_CarMesh3D_Sample_GUITestVehicle
%   % * Interior sub-labels (seat, steering wheel, console) once they
%   %   % exist (the design file's P5)

%% Settings
vehicleID = '2026_CarMesh3D_Sample_GUITestVehicle';   % Must match this folder's name
sampleID = '2026_CarMesh3D_Sample_GenericSedan';      % The vehicle it starts from
photoAngles = 0:30:330;                               % Photos: degrees around the vehicle (0 ahead, 90 from the left)
photoSize = [640 427];                                % Photos: pixels (3:2)
flagRedrawPhotos = false;                             % Photos: draw again even if they exist (makes hidden figures)

%% Find the folders
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID);
thisFolder = fileparts(mfilename('fullpath'));
if ~isempty(thisFolder) && ~strcmpi(vehicleFiles.Folder, thisFolder)
    error(['vehicleID (%s) does not match this script''s folder (%s). Was the script copied ' ...
        'without changing vehicleID?'], vehicleID, thisFolder);
end
sampleFiles = fcn_CarMesh3D_findVehicleFiles(sampleID);
loaded = load(sampleFiles.MeshFile, 'vehicleMesh');
vehicleMesh = loaded.vehicleMesh;

%% The standard part and lamp lists (the sample predates interior and high beams)
standardParts = {'body';'glass';'wheel';'light';'trim';'interior'};
% (every lamp type, from the one list: fcn_CarMesh3D_lampTypes; 11 since task 8)
lampTypes = fcn_CarMesh3D_lampTypes(FigNum=-1);
standardLamps = reshape({lampTypes.Name}, [], 1);
assert(isequal(vehicleMesh.PartNames(:), standardParts(1:numel(vehicleMesh.PartNames))), 'Sample part order changed');
assert(isequal(vehicleMesh.LightTypeNames(:), standardLamps(1:numel(vehicleMesh.LightTypeNames))), 'Sample lamp order changed');
vehicleMesh.PartNames = standardParts;
vehicleMesh.LightTypeNames = standardLamps;
vehicleMesh.Name = 'GUI test vehicle (made up, for testing the label tools)';
vehicleMesh.Source = sprintf('Made by %s from %s', mfilename, sampleID);
vehicleMesh.License = 'CC0 1.0: made by a CarMesh3D script; no downloaded model';

%% Make it exactly symmetric (left and right sides mirror images), so the
% painter's "Mirror to the other side" finds a twin for every face
vehicleMesh = fcn_INTERNAL_symmetrize(vehicleMesh);

%% Add the pieces, as boxes (labeled below)
% Boxes: [xmin xmax ymin ymax zmin zmax], meters; the sample's body runs
% from x = -1.03 (rear) to 3.73 (front), y = -0.92 to 0.92, z up to 1.45.
% Left-side boxes are mirrored to the right (y to -y) where marked.
pieces = { ...   name, box, mirrored
    'high beam',      [3.73 3.75  0.30 0.44 0.58 0.68], true
    'front turn',     [3.73 3.75  0.72 0.86 0.58 0.66], true
    'running strip',  [3.73 3.75 -0.25 0.25 0.45 0.49], false
    'headlight cover',[3.765 3.775 0.28 0.70 0.55 0.71], true
    'rear turn',      [-1.05 -1.03 0.72 0.86 0.70 0.78], true
    'backup',         [-1.05 -1.03 0.15 0.30 0.70 0.76], true
    'front bumper',   [3.73 3.80 -0.85 0.85 0.25 0.40], false
    'rear bumper',    [-1.10 -1.03 -0.85 0.85 0.25 0.40], false
    'mirror',         [2.20 2.35  0.92 1.05 1.00 1.10], true
    'seat',           [0.80 1.30  0.15 0.60 0.45 0.95], true
    'steering wheel', [1.75 1.80  0.25 0.55 0.85 1.05], false
    'console',        [1.40 2.00 -0.10 0.10 0.45 0.75], false
    'muffler',        [-0.90 -0.40 -0.50 -0.30 0.15 0.25], false
    'roof panel',     [0.00 2.00 -0.80 0.80 1.46 1.48], false
    'fog lamp',       [3.80 3.82  0.50 0.65 0.30 0.36], true
    'side marker',    [3.30 3.40  0.92 0.94 0.55 0.60], true
    'rear reflector', [-1.05 -1.03 0.45 0.60 0.45 0.50], true
    'plate lamp',     [-1.05 -1.03 -0.10 0.10 0.50 0.53], false
    'roof beacon',    [0.90 1.10 -0.10 0.10 1.50 1.58], false};
for ith_piece = 1:size(pieces,1)
    box = pieces{ith_piece,2};
    if box(3) < 0 && box(4) > 0
        % (a box across the centerline: its left half, and that half's
        % mirror image)
        vehicleMesh = fcn_INTERNAL_addBox(vehicleMesh, [box(1:2) 0 box(4) box(5:6)], false);
        vehicleMesh = fcn_INTERNAL_addBox(vehicleMesh, [box(1:2) 0 -box(3) box(5:6)], true);
        continue;
    end
    vehicleMesh = fcn_INTERNAL_addBox(vehicleMesh, box, false);
    if pieces{ith_piece,3}
        vehicleMesh = fcn_INTERNAL_addBox(vehicleMesh, box, true);   % (its exact mirror image, so painting can mirror)
    end
end

%% Label them (fcn_CarMesh3D_editLabels: Region picks faces by their centers)
grow = @(box) box + [-0.005 0.005 -0.005 0.005 -0.005 0.005];   % (a hair larger, so face centers on the edges count)
boxOf = @(name) grow(pieces{strcmp(pieces(:,1), name), 2});
edits = {
    struct('Name','high beams', 'Region',boxOf('high beam'), 'BothSides',true, 'LightType','highbeam', 'Color',[0.88 0.94 1.00])
    struct('Name','front turn signals', 'Region',boxOf('front turn'), 'BothSides',true, 'LightType','turnsignal', 'Color',[1.00 0.60 0.10])
    struct('Name','running lights', 'Region',boxOf('running strip'), 'LightType','running', 'Color',[1.00 1.00 0.90])
    struct('Name','headlight covers', 'Region',boxOf('headlight cover'), 'BothSides',true, 'LightType','headlight', ...
        'AlsoParts',{{'glass'}}, 'Color',[0.85 0.90 0.95])
    struct('Name','rear turn signals', 'Region',boxOf('rear turn'), 'BothSides',true, 'LightType','turnsignal', 'Color',[1.00 0.60 0.10])
    struct('Name','backup lights', 'Region',boxOf('backup'), 'BothSides',true, 'LightType','backup', 'Color',[0.95 0.95 0.95])
    struct('Name','tail lights that are also turn signals', 'Region',[-1.06 -1.00 0.45 0.70 0.55 0.85], 'BothSides',true, ...
        'LightType','tail', 'AlsoLightTypes',{{'turnsignal'}})
    struct('Name','bumpers', 'Region',boxOf('front bumper'), 'Part','trim', 'Color',[0.15 0.15 0.15])
    struct('Name','rear bumper', 'Region',boxOf('rear bumper'), 'Part','trim', 'Color',[0.15 0.15 0.15])
    struct('Name','mirrors', 'Region',boxOf('mirror'), 'BothSides',true, 'Part','trim', 'Color',[0.15 0.15 0.15])
    struct('Name','seats', 'Region',boxOf('seat'), 'BothSides',true, 'Part','interior', 'Color',[0.35 0.30 0.28])
    struct('Name','steering wheel', 'Region',boxOf('steering wheel'), 'Part','interior', 'Color',[0.10 0.10 0.10])
    struct('Name','console', 'Region',boxOf('console'), 'Part','interior', 'Color',[0.45 0.40 0.35])
    struct('Name','muffler (hidden)', 'Region',boxOf('muffler'), 'Part','trim', 'Color',[0.40 0.40 0.40])
    struct('Name','muffler hidden', 'Region',boxOf('muffler'), 'Hide',true)
    struct('Name','hard top (hidden)', 'Region',boxOf('roof panel'), 'Hide','hard top')
    struct('Name','fog lamps', 'Region',boxOf('fog lamp'), 'BothSides',true, 'LightType','fog', 'Color',[0.95 0.95 0.85])
    struct('Name','side markers', 'Region',boxOf('side marker'), 'BothSides',true, 'LightType','marker', 'Color',[0.85 0.45 0.05])
    struct('Name','rear reflectors', 'Region',boxOf('rear reflector'), 'BothSides',true, 'LightType','reflector', 'Color',[0.62 0.06 0.05])
    struct('Name','license plate lamp', 'Region',boxOf('plate lamp'), 'LightType','licenseplate', 'Color',[0.95 0.95 0.90])
    struct('Name','roof beacon (warning lamp)', 'Region',boxOf('roof beacon'), 'LightType','warning', 'Color',[1.00 0.55 0.00])};
vehicleMesh = fcn_CarMesh3D_editLabels(vehicleMesh, Edits=edits, FigNum=-1);

%% Check that every feature is there (the point of this vehicle)
for ith_type = 1:numel(standardLamps)
    assert(any(vehicleMesh.FaceLightType == ith_type), 'No %s faces', standardLamps{ith_type});
end
for ith_part = 1:numel(standardParts)
    assert(any(vehicleMesh.FacePartIndex == ith_part | any(vehicleMesh.FaceAlsoParts(:,ith_part),2)), 'No %s faces', standardParts{ith_part});
end
assert(all(ismember({'hidden','hard top'}, vehicleMesh.HiddenSetNames)), 'Hidden sets missing');
assert(isfield(vehicleMesh,'FaceLightFunctions') && any(sum(vehicleMesh.FaceLightFunctions,2) > 1), 'No lamp with two functions');
fprintf(1,'%s: %d faces; lamps per type: %s; hidden sets: %s\n', vehicleID, size(vehicleMesh.Faces,1), ...
    mat2str(accumarray(vehicleMesh.FaceLightType(vehicleMesh.FaceLightType>0), 1, [numel(standardLamps) 1])'), ...
    strjoin(vehicleMesh.HiddenSetNames, ', '));

%% Save the mesh, its outline, and the license
vehicleSpec = vehicleMesh.VehicleSpec;
vehicleSpec.Name = '2026 CarMesh3D Sample GUITestVehicle';
vehicleMesh.VehicleSpec = vehicleSpec;
vehicleMesh.BuildInfo = fcn_CarMesh3D_makeBuildInfo(Script=mfilename, FigNum=-1);
save(vehicleFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
vehicleOutline = fcn_CarMesh3D_makeOutline2D(vehicleMesh, FigNum=-1);
save(vehicleFiles.OutlineFile, 'vehicleOutline');
if ~isfolder(vehicleFiles.ModelFolder)
    mkdir(vehicleFiles.ModelFolder);
end
fid = fopen(fullfile(vehicleFiles.ModelFolder, 'LICENSE.txt'), 'w');
fprintf(fid, ['License: CC0 1.0 (public domain)\nThis vehicle is made up: it was made by %s from the CarMesh3D sample ' ...
    'sedan (itself made by fcn_CarMesh3D_fillSampleMesh). No downloaded model is used.\n'], mfilename);
fclose(fid);

%% Its photos: itself, drawn every 30 degrees (hidden figures)
photoFolder = fullfile(vehicleFiles.Folder, 'photos');
if ~isfolder(photoFolder)
    mkdir(photoFolder);
end
if ~flagRedrawPhotos && numel(dir(fullfile(photoFolder, 'ViewInDegrees_*.jpg'))) == numel(photoAngles)
    fprintf(1,'Saved %s (mesh, outline; its photos were kept: set flagRedrawPhotos to draw them again)\n', vehicleID);
    return;
end
photoFigure = figure('Visible', 'off', 'Color', [0.82 0.86 0.90], 'Position', [100 100 photoSize], ...
    'InvertHardcopy', 'off', 'PaperPositionMode', 'auto');
photoAxes = axes(photoFigure, 'Position', [0 0 1 1], 'Color', [0.82 0.86 0.90]);
fcn_CarMesh3D_plotVehicle(vehicleMesh, 'AxesHandle', photoAxes);
title(photoAxes, '');   % (a photo has no title)
axis(photoAxes, 'equal');
axis(photoAxes, 'off');
for ith_angle = 1:numel(photoAngles)
    angle = photoAngles(ith_angle);
    view(photoAxes, angle + 90, 12);   % (the dial's angle: 0 from ahead, 90 from the left)
    axis(photoAxes, 'tight');
    camva(photoAxes, 'auto');
    drawnow;
    % (print keeps the figure's full size; exportgraphics would crop it)
    print(photoFigure, fullfile(photoFolder, sprintf('ViewInDegrees_%03d.jpg', angle)), '-djpeg', '-r96');
end
delete(photoFigure);
fprintf(1,'Saved %s (mesh, outline, %d photos)\n', vehicleID, numel(photoAngles));

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_symmetrize
function vehicleMesh = fcn_INTERNAL_symmetrize(vehicleMesh)
% Keeps the left side's faces (and the faces on the centerline) and
% replaces the right side's faces with the left side's mirror images
% (y to -y): every per-face field is copied with them, normals mirrored,
% and wheels swapped left for right (1 FL <-> 2 FR, 3 RL <-> 4 RR)
centers = (vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:) + vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) + ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:))/3;
flagLeft = centers(:,2) > 1e-4;
flagMiddle = abs(centers(:,2)) <= 1e-4;
keep = find(flagLeft | flagMiddle);
mirrorOf = find(flagLeft);
numVertices = size(vehicleMesh.Vertices,1);
numFaces = size(vehicleMesh.Faces,1);
vehicleMesh.Vertices = [vehicleMesh.Vertices; vehicleMesh.Vertices.*[1 -1 1]];
mirroredFaces = vehicleMesh.Faces(mirrorOf,[1 3 2]) + numVertices;   % (reversed: a mirror turns triangles over)
names = fieldnames(vehicleMesh);
for ith_name = 1:numel(names)
    name = names{ith_name};
    value = vehicleMesh.(name);
    if ~startsWith(name, 'Face') || size(value,1) ~= numFaces
        continue;
    end
    if strcmp(name, 'Faces')
        vehicleMesh.Faces = [value(keep,:); mirroredFaces];
        continue;
    end
    extra = value(mirrorOf,:);
    if strcmp(name, 'FaceNormals')
        extra(:,2) = -extra(:,2);
    elseif strcmp(name, 'FaceWheelIndex')
        swap = [2 1 4 3];
        extra(extra > 0) = swap(extra(extra > 0));
    end
    vehicleMesh.(name) = [value(keep,:); extra];
end
% (vertices no face uses are left out)
used = unique(vehicleMesh.Faces(:));
newIndex = zeros(size(vehicleMesh.Vertices,1),1);
newIndex(used) = 1:numel(used);
vehicleMesh.Vertices = vehicleMesh.Vertices(used,:);
vehicleMesh.Faces = newIndex(vehicleMesh.Faces);
end % Ends fcn_INTERNAL_symmetrize

%% fcn_INTERNAL_addBox
function vehicleMesh = fcn_INTERNAL_addBox(vehicleMesh, box, flagMirror)
% Adds a box [xmin xmax ymin ymax zmin zmax] as 12 triangles, normals
% outward, labeled body for now; every per-face field gets a row for each
% new face (body color, solid). With flagMirror, the box's exact mirror
% image across the centerline (y to -y): the same triangles, mirrored, so
% each face has a twin on the other side (the painter's "Mirror to the
% other side" finds faces by their mirrored centers)
x = box([1 2]); y = sort(box([3 4])); z = box([5 6]);
corners = [x(1) y(1) z(1); x(2) y(1) z(1); x(2) y(2) z(1); x(1) y(2) z(1); ...
    x(1) y(1) z(2); x(2) y(1) z(2); x(2) y(2) z(2); x(1) y(2) z(2)];
quads = [1 4 3 2; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];   % (bottom, top, sides; counterclockwise from outside)
localFaces = [quads(:,[1 2 3]); quads(:,[1 3 4])];
if flagMirror
    corners(:,2) = -corners(:,2);
    localFaces = localFaces(:,[1 3 2]);   % (a mirror turns the triangles over: reverse them, so normals stay outward)
end
newFaces = localFaces + size(vehicleMesh.Vertices,1);
numOld = size(vehicleMesh.Faces,1);
numNew = size(newFaces,1);
vehicleMesh.Vertices = [vehicleMesh.Vertices; corners];
vehicleMesh.Faces = [vehicleMesh.Faces; newFaces];
bodyIndex = find(strcmp(vehicleMesh.PartNames, 'body'));
bodyColor = vehicleMesh.FaceColors(find(vehicleMesh.FacePartIndex == bodyIndex, 1), :);
names = fieldnames(vehicleMesh);
for ith_name = 1:numel(names)
    name = names{ith_name};
    value = vehicleMesh.(name);
    if ~startsWith(name, 'Face') || strcmp(name, 'Faces') || size(value,1) ~= numOld
        continue;
    end
    switch name
        case 'FacePartIndex'
            extra = repmat(bodyIndex, numNew, 1);
        case 'FaceColors'
            extra = repmat(bodyColor, numNew, 1);
        case 'FaceAlpha'
            extra = ones(numNew, 1);
        case 'FaceNormals'
            edge1 = corners(localFaces(:,2),:) - corners(localFaces(:,1),:);
            edge2 = corners(localFaces(:,3),:) - corners(localFaces(:,1),:);
            extra = cross(edge1, edge2, 2);
            extra = extra ./ vecnorm(extra, 2, 2);
        otherwise
            extra = zeros(numNew, size(value,2), 'like', value);
    end
    vehicleMesh.(name) = [value; extra];
end
end % Ends fcn_INTERNAL_addBox
