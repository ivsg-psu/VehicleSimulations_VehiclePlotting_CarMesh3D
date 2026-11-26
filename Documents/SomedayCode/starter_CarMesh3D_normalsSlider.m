function figureHandle = starter_CarMesh3D_normalsSlider(vehicleID, figNum)
% starter_CarMesh3D_normalsSlider
%
% SOMEDAY STARTER CODE: kept so the idea is not lost (Sean, 2026_11_26
% 03:14). It works as it is, but it is not part of the toolbox: it lives
% in Documents/SomedayCode, off the MATLAB path, has no test script, and
% does not follow the function template. To use it, add the folder to the
% path for the session:
%
%   addpath(fullfile(pwd, 'Documents', 'SomedayCode')); starter_CarMesh3D_normalsSlider('2009_Honda_Fit_Sport');
%
% WHAT IT IS
%
% A 2x2 window for judging, by eye, which faces of a mesh point the wrong
% way (Sean, 2026_11_26 03:01). Sean used it to choose the rules in
% fcn_CarMesh3D_orientFaces (03:12).
%   1,1  the mesh, each face colored by its unit normal, RGB = (n+1)/2:
%        a face pointing the wrong way shows in the opposite color to its
%        neighbors ("the errors stand out dramatically", Sean, 02:35)
%   1,2  the mesh, gray by the mean dot product of each face's normal with
%        its edge neighbors': above 0 (or no neighbor) near-white 0.95;
%        -1..0 mapped to gray 0..0.5, so backward faces show dark
%   2,1  the faces whose mean dot product is below the cutoff flipped,
%        colored by unit normal
%   2,2  that flipped mesh, gray by its own mean dot products
% Below the views: a labeled slider for the cutoff (-1 to 1, value shown),
% "Start from" (the original mesh, or the mesh after
% fcn_CarMesh3D_orientFaces), and "Sweeps" (repeat the flip: each sweep
% finds the dot products again, so a backward patch erodes from its border
% inward; "until nothing changes" stops at 50 and says if faces kept
% flipping back and forth). A readout gives the counts. All four views are
% linked and use the CAD mouse (fcn_CarMesh3D_addCadMouse).
%
% WHAT IT COULD BECOME (the Someday item in
% Documents/Documentation_CarMesh3D_GUIdesign_VandV.md)
%
% "Pre-flight unit-normal tests" as another panel of the V&V: the reviewer
% sets the cutoff and sweeps for a vehicle, sees the result, and the
% choice is saved with the vehicle (or the vehicle is flagged for its
% normals to be checked). Before that it would need the function template,
% a test script, its own design notes, and the GUI rules (uifigure
% controls, panels that scroll, the progress bar).
%
% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In starter_CarMesh3D_normalsSlider
%   % * Written as Claude's tool zzN_normalsSlider during the 2009 Fit's
%   %   % review (02:51 to 03:12); kept in the repo as starter code (03:14)
%
% Questions or comments? sbrennan@psu.edu

if nargin < 2 || isempty(figNum)
    figNum = 7720;   % (an unused figure number)
end

vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=-1);
vertices = double(vehicleMesh.Vertices);
originalFaces = double(vehicleMesh.Faces);
orientedMesh = fcn_CarMesh3D_orientFaces(vehicleMesh, FigNum=-1);
orientedFaces = double(orientedMesh.Faces);
numFaces = size(originalFaces, 1);

% The pairs of faces that share an edge (corners within 0.01 mm are one);
% an edge with three or more faces gives its consecutive pairs
[~, ~, placeID] = unique(round(vertices/1e-5), 'rows');
welded = placeID(originalFaces);
edges = sort([welded(:,[1 2]); welded(:,[2 3]); welded(:,[3 1])], 2);
[~, ~, edgeID] = unique(edges, 'rows');
edgeFace = repmat((1:numFaces)', 3, 1);
[sortedID, order] = sort(edgeID);
sortedFace = edgeFace(order);
flagSame = sortedID(1:end-1) == sortedID(2:end);
pairA = sortedFace([flagSame; false]);
pairB = sortedFace([false; flagSame]);
flagSelf = pairA == pairB;
pairA = pairA(~flagSelf);
pairB = pairB(~flagSelf);
numNeighbors = accumarray([pairA; pairB], 1, [numFaces 1]);

% The window
figureHandle = figure(figNum);
clf(figureHandle);
figureHandle.Visible = 'on';
figureHandle.Color = 'w';
figureHandle.Name = sprintf('%s: faces pointing the wrong way', vehicleID);
titles = {'Original: colored by unit normal', 'Original: gray by mean dot with neighbors', ...
    'Below the cutoff flipped: colored by unit normal', 'Below the cutoff flipped: gray by mean dot'};
axesList = gobjects(1, 4);
patchList = gobjects(1, 4);
positions = [0.01 0.53 0.48 0.42; 0.51 0.53 0.48 0.42; 0.01 0.09 0.48 0.42; 0.51 0.09 0.48 0.42];
for ith_view = 1:4
    axesList(ith_view) = axes(figureHandle, 'Position', positions(ith_view,:));
    patchList(ith_view) = patch(axesList(ith_view), 'Faces', originalFaces, 'Vertices', vertices, ...
        'FaceVertexCData', ones(numFaces,3), 'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'none');
    axis(axesList(ith_view), 'equal', 'off');
    view(axesList(ith_view), 150, 20);
    title(axesList(ith_view), titles{ith_view});
end
fcn_CarMesh3D_addCadMouse(axesList);
cameraLink = linkprop(axesList, {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'});
setappdata(figureHandle, 'CameraLink', cameraLink);

uicontrol(figureHandle, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01 0.035 0.12 0.03], ...
    'String', 'Flip if mean dot <', 'BackgroundColor', 'w', 'HorizontalAlignment', 'right', 'FontSize', 11);
slider = uicontrol(figureHandle, 'Style', 'slider', 'Units', 'normalized', 'Position', [0.14 0.045 0.30 0.025], ...
    'Min', -1, 'Max', 1, 'Value', -0.5, 'SliderStep', [0.025 0.1], 'Callback', @(~,~) redraw());
% (the slider's scale: -1, -0.5, 0, 0.5, 1 under it, and its value beside it)
for tickValue = -1:0.5:1
    tickX = 0.14 + 0.30*(tickValue + 1)/2;
    uicontrol(figureHandle, 'Style', 'text', 'Units', 'normalized', 'Position', [tickX-0.02 0.028 0.04 0.017], ...
        'String', sprintf('%g', tickValue), 'BackgroundColor', 'w', 'FontSize', 8);
end
valueLabel = uicontrol(figureHandle, 'Style', 'text', 'Units', 'normalized', 'Position', [0.445 0.04 0.07 0.03], ...
    'String', '', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left', 'FontSize', 11, 'FontWeight', 'bold');
addlistener(slider, 'ContinuousValueChange', @(~,~) redraw());
startMenu = uicontrol(figureHandle, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.53 0.035 0.20 0.035], ...
    'String', {'Start from: original', 'Start from: after orientFaces (patch rule)'}, 'FontSize', 11, ...
    'Callback', @(~,~) redraw());
sweepChoices = [1 2 3 5 10 20 50];
sweepMenu = uicontrol(figureHandle, 'Style', 'popupmenu', 'Units', 'normalized', 'Position', [0.75 0.035 0.20 0.035], ...
    'String', {'Sweeps: 1', 'Sweeps: 2', 'Sweeps: 3', 'Sweeps: 5', 'Sweeps: 10', 'Sweeps: 20', 'Sweeps: until nothing changes (max 50)'}, ...
    'FontSize', 11, 'Callback', @(~,~) redraw());
readout = uicontrol(figureHandle, 'Style', 'text', 'Units', 'normalized', 'Position', [0.01 0.0 0.98 0.03], ...
    'String', '', 'BackgroundColor', 'w', 'HorizontalAlignment', 'left', 'FontSize', 11);

redraw();

    function redraw()
        if ~isvalid(figureHandle)
            return;
        end
        cutoff = slider.Value;
        valueLabel.String = sprintf('%.3f', cutoff);
        if startMenu.Value == 1
            startFaces = originalFaces;
            startName = 'the original';
        else
            startFaces = orientedFaces;
            startName = 'the mesh after orientFaces';
        end
        [originalNormals, originalDot] = fcn_INTERNAL_meanDot(originalFaces);
        numSweeps = sweepChoices(sweepMenu.Value);
        flagUntilDone = sweepMenu.Value == numel(sweepChoices);
        flippedFaces = startFaces;
        flagEverFlipped = false(numFaces, 1);
        flipCounts = zeros(numFaces, 1);
        sweepsRun = 0;
        for ith_sweep = 1:numSweeps
            [~, sweepDot] = fcn_INTERNAL_meanDot(flippedFaces);
            flagFlip = numNeighbors > 0 & sweepDot < cutoff;
            if ~any(flagFlip)
                break;
            end
            flippedFaces(flagFlip,:) = flippedFaces(flagFlip,[1 3 2]);
            flagEverFlipped = flagEverFlipped | flagFlip;
            flipCounts = flipCounts + flagFlip;
            sweepsRun = ith_sweep;
        end
        flagFlip = any(flippedFaces ~= startFaces, 2);   % (net: flipped an odd number of times)
        if flagUntilDone
            if sweepsRun < numSweeps
                sweepText = sprintf('%d sweep(s), then nothing changed', sweepsRun);
            else
                sweepText = sprintf('%d sweeps, still changing: %d faces flipped 3+ times (back and forth)', sweepsRun, nnz(flipCounts >= 3));
            end
        else
            sweepText = sprintf('%d sweep(s)', sweepsRun);
        end
        [flippedNormals, flippedDot] = fcn_INTERNAL_meanDot(flippedFaces);
        set(patchList(1), 'FaceVertexCData', (originalNormals + 1)/2);
        set(patchList(2), 'FaceVertexCData', repmat(fcn_INTERNAL_gray(originalDot), 1, 3));
        set(patchList(3), 'Faces', flippedFaces, 'FaceVertexCData', (flippedNormals + 1)/2);
        set(patchList(4), 'Faces', flippedFaces, 'FaceVertexCData', repmat(fcn_INTERNAL_gray(flippedDot), 1, 3));
        readout.String = sprintf(['Cutoff %.2f, %s: %d faces of %s flipped.   ' ...
            'Faces at or below 0: original %d, now %d.   %d faces with no edge neighbor (white).'], ...
            cutoff, sweepText, nnz(flagFlip), startName, nnz(numNeighbors > 0 & originalDot <= 0), ...
            nnz(numNeighbors > 0 & flippedDot <= 0), nnz(numNeighbors == 0));
        drawnow limitrate;
    end

    function [normals, meanDot] = fcn_INTERNAL_meanDot(faces)
        % Each face's unit normal, and the mean dot product with its
        % edge neighbors' (0 when it has none)
        normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
        normals = normals./max(vecnorm(normals, 2, 2), eps);
        dots = sum(normals(pairA,:).*normals(pairB,:), 2);
        meanDot = accumarray([pairA; pairB], [dots; dots], [numFaces 1])./max(numNeighbors, 1);
    end

    function grayValue = fcn_INTERNAL_gray(meanDot)
        % Above 0 (or no neighbor): near-white 0.95; -1..0: gray 0..0.5
        grayValue = 0.95*ones(numFaces, 1);
        flagLow = numNeighbors > 0 & meanDot <= 0;
        grayValue(flagLow) = (meanDot(flagLow) + 1)/2;
    end

end
