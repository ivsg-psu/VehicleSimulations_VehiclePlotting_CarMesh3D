function report = fcn_CarMesh3D_compareToOriginal(reducedMesh, originalMesh, options)
% fcn_CarMesh3D_compareToOriginal

% Compares a reduced (finished) mesh with the original download it came
% from, both in the vehicle frame, and flags the spots where the
% reduction went wrong, so a review starts from a short list instead of
% a search. Both meshes are drawn from the same cameras (14 views: the
% four sides, top, bottom, four corners, and the four sides from 12
% degrees below), each face in its own unique color, so each pixel tells
% which face is seen there. Pixel by pixel, four problems are found:
%
%   Holes: the original shows a surface, the reduced mesh shows the
%       background (gaps between panels, missing faces, see-through
%       spots). Marked blue.
%   Label changes: the face seen in the reduced mesh has a different
%       label (part or light type) than the one seen in the original
%       (glass showing where trim was, a thinned pillar, a lamp lost).
%       Marked orange.
%   Flipped faces: the face seen in the reduced mesh points away from
%       the camera (a dark, inside-out panel) where the download's face
%       does not (the back of a one-sided surface that the download shows
%       too, such as the inside of a wheel's spokes, is not a flip made
%       by the reduction). Marked red.
%   See-through gaps: the background shows through the reduced mesh
%       where it is closed all around by the car (a slit between the
%       floor panel and the sills or bumpers, a gap between panels),
%       away from the wheels (whose spokes and arches may show through).
%       Found in the reduced mesh alone, so gaps that the download has
%       too (it often has no underside) are found. Marked magenta.
%
% Only pixels inside a region are counted (their 3 x 3 neighbors agree),
% so outlines that shift by a pixel are not flagged. Pixels where the
% reduced mesh shows its floor panel (fcn_CarMesh3D_addFloorPanel) are
% not counted: the original has no floor. The spots with the most
% flagged pixels are cut out of the same pictures, original next to
% reduced, so they line up exactly.
%
% FORMAT:
%
%       report = fcn_CarMesh3D_compareToOriginal(reducedMesh, originalMesh,...
%           (Title=text), (ImageWidth=pixels), (NumSpots=count),...
%           (OutputFile=pngPrefix), (OriginalCache=matFile), (FigNum=figNum))
%
% INPUTS:
%
%      reducedMesh: the finished (reduced) CarMesh3D mesh, labeled and fit
%      to its spec.
%
%      originalMesh: the same download, labeled and fit the same way, not
%      reduced.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Title: text for the sheets' titles (for example, the vehicle's
%      name). Default ''.
%
%      ImageWidth: pixels across each view. Default 900.
%
%      NumSpots: how many flagged spots get close-ups. Default 9.
%
%      OutputFile: a file name prefix: the two sheets are saved as
%      <prefix>_views.png and <prefix>_spots.png. Default '' (not saved).
%
%      OriginalCache: a .mat file in which the download's renders (face
%      numbers and shaded pictures, 28 of the 56 renders) are kept. They
%      are reused while the download, its label colors, the views, and
%      the frame are unchanged (fcn_CarMesh3D_loadCache), which halves
%      the time of a comparison after the reduced mesh changes. Default
%      '' (always rendered).
%
%      FigNum: a figure for the views sheet (the spots sheet goes in a
%      figure of its own, named '<Title>: flagged spots'); both are left
%      open. If empty or omitted, no sheets are
%      drawn (the report is still made). If set to -1, input checking is
%      skipped and no sheets are drawn (fast mode).
%
% OUTPUTS:
%
%      report: a structure with
%           Views: a table, one row per view: View, CarPixels, and
%               HolePercent, LabelChangePercent, FlippedPercent,
%               SeeThroughPercent (of the car's pixels in that view)
%           Totals: the same four percentages over all views
%           Spots: a structure array, worst first: View, Box ([row1 row2
%               col1 col2] in that view's pictures), Holes,
%               LabelChanges, Flipped, SeeThrough (pixel counts)
%           Images: per view, the shaded pictures (Original, Reduced)
%               and the flagged masks (Holes, LabelChanges, Flipped,
%               SeeThrough)
%           Parts: a table, one row per label (part, or light type):
%               Label, OriginalFaces, ReducedFaces, OriginalArea and
%               ReducedArea (m^2), AreaChangePercent, and Missing (true
%               when a label with at least 0.01 m^2 in the download kept
%               less than half of its area: faces lost in the reduction)
%           MissingLabels: the labels flagged Missing
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_plotLabels (the label colors); fcn_CarMesh3D_loadCache
%      and fcn_CarMesh3D_saveCache (OriginalCache); figure, patch, print
%      (MATLAB base)
%
% EXAMPLES:
%
%       % (in a vehicle script, after the reduction)
%       report = fcn_CarMesh3D_compareToOriginal(vehicleMesh, originalMesh, ...
%           Title='2010 Toyota Camry XV40', FigNum=20);
%       disp(report.Views);
%
%       See the script: script_test_fcn_CarMesh3D_compareToOriginal.m for a
%       full test suite.
%
% This function was written on 2026_11_21 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_compareToOriginal
%   % * First write: automated review of a reduced mesh against its
%   %   % download (holes, label changes, flipped faces; flagged-spot
%   %   % close-ups)
%   % * See-through gaps (background closed all around by the reduced
%   %   % mesh, away from the wheels), and four low views (12 degrees
%   %   % below the sides, front, and rear): the slits between the floor
%   %   % panel and the sills, which the download (no underside) has too
%   % * OriginalCache: the download's renders kept in a .mat file and
%   %   % reused while unchanged (half of a comparison's time)
%   % * The two pictures are also saved as .fig files, to zoom into (Sean)
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_compareToOriginal
%   % * Flipped faces only where the download's face does not face away
%   %   % too: the backs of one-sided surfaces the download shows as well
%   %   % (the inside of the wheels' spokes, seen from low down) were the
%   %   % Fit's worst spots, and are not flips made by the reduction
%   % * Parts: faces and area per label in the download and the reduced
%   %   % mesh; MissingLabels: labels that lost more than half their area

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_compareToOriginal
%   % * A depth comparison (surface moved more than 2 cm), for flattened
%   %   % wheel arches seen straight on



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments

    reducedMesh
    originalMesh
    options.Title = ''          % Text for the sheets' titles
    options.ImageWidth = 900    % Pixels across each view
    options.NumSpots = 9        % How many flagged spots get close-ups
    options.OutputFile = ''     % Prefix for <prefix>_views.png and <prefix>_spots.png
    options.OriginalCache = ''  % A .mat file to keep the download's renders in; '' for none
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

        for thisMesh = {reducedMesh, originalMesh}
            if ~(isstruct(thisMesh{1}) && all(isfield(thisMesh{1}, {'Vertices','Faces','PartNames','FacePartIndex'})))
                error('reducedMesh and originalMesh must be labeled CarMesh3D meshes (Vertices, Faces, PartNames, FacePartIndex)');
            end
        end
        if ~(isnumeric(options.ImageWidth) && isscalar(options.ImageWidth) && options.ImageWidth >= 100)
            error('ImageWidth must be a number of pixels, 100 or more');
        end
        if ~(isnumeric(options.NumSpots) && isscalar(options.NumSpots) && options.NumSpots >= 0)
            error('NumSpots must be a count, 0 or more');
        end
        if ~(ischar(options.Title) || isstring(options.Title)) || ~(ischar(options.OutputFile) || isstring(options.OutputFile))
            error('Title and OutputFile must be text');
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

% The views: [azimuth elevation] (vehicle frame: X forward, Y left)
viewNames = {'right side','left side','front','rear','top','bottom', ...
    'front right','front left','rear left','rear right', ...
    'right side, low','left side, low','front, low','rear, low'};
viewAngles = [0 5; 180 5; 90 5; -90 5; -90 90; -90 -90; 45 20; 135 20; -135 20; -45 20; ...
    0 -12; 180 -12; 90 -12; -90 -12];
numViews = numel(viewNames);

% One frame for both meshes: the original's box, padded
allPoints = [originalMesh.Vertices; reducedMesh.Vertices];
limitsLow = min(allPoints,[],1) - 0.05;
limitsHigh = max(allPoints,[],1) + 0.05;

% Label colors (for the shaded pictures) and label keys (for comparing)
originalLabels = fcn_CarMesh3D_plotLabels(originalMesh, FigNum=-1);
reducedLabels = fcn_CarMesh3D_plotLabels(reducedMesh, FigNum=-1);
originalKey = round(originalLabels.FaceColors*255)*[65536; 256; 1];
reducedKey = round(reducedLabels.FaceColors*255)*[65536; 256; 1];

% Face normals of both meshes (for flipped faces: the reduced mesh's face
% faces away where the download's does not)
reducedNormals = fcn_INTERNAL_normals(reducedMesh);
originalNormals = fcn_INTERNAL_normals(originalMesh);

% Floor-panel faces are not counted
flagFloor = false(size(reducedMesh.Faces,1),1);
if isfield(reducedMesh,'FloorPanel') && isfield(reducedMesh.FloorPanel,'Faces')
    flagFloor(reducedMesh.FloorPanel.Faces) = true;
end

% Wheel faces of the reduced mesh (see-through gaps near them are not
% counted: spokes and wheel arches)
flagWheel = false(size(reducedMesh.Faces,1),1);
wheelPart = find(strcmp(reducedMesh.PartNames,'wheel'), 1);
if ~isempty(wheelPart)
    flagWheel = reducedMesh.FacePartIndex(:)==wheelPart;
end

renderSettings = struct('Low',limitsLow, 'High',limitsHigh, 'Width',round(options.ImageWidth));
flagShaded = flag_do_plots || ~isempty(options.OutputFile);

% The download's renders: reused from OriginalCache while the download,
% its label colors, the views, and the frame are unchanged
originalRenders = struct('Ids',{cell(numViews,1)}, 'Shaded',{cell(numViews,1)});
flagOriginalCached = false;
if ~isempty(options.OriginalCache)
    originalCacheInputs = struct('Vertices',originalMesh.Vertices, 'Faces',originalMesh.Faces, ...
        'Colors',originalLabels.FaceColors, 'Views',viewAngles, 'Render',renderSettings, 'Shaded',flagShaded);
    [cachedRenders, flagOriginalCached] = fcn_CarMesh3D_loadCache(options.OriginalCache, originalCacheInputs, FigNum=-1);
    if flagOriginalCached
        originalRenders = cachedRenders.originalRenders;
    end
end
viewRows = cell(numViews,1);
images = struct('View',viewNames, 'Original',[], 'Reduced',[], 'Holes',[], 'LabelChanges',[], 'Flipped',[], 'SeeThrough',[]);
allSpots = struct('View',{}, 'Box',{}, 'Holes',{}, 'LabelChanges',{}, 'Flipped',{}, 'SeeThrough',{}, 'Score',{});
for ith_view = 1:numViews
    thisAngle = viewAngles(ith_view,:);
    % (which face is seen at each pixel, 0 for the background)
    if flagOriginalCached
        originalId = double(originalRenders.Ids{ith_view});
    else
        originalId = fcn_INTERNAL_faceIds(originalMesh, thisAngle, renderSettings);
        originalRenders.Ids{ith_view} = uint32(originalId);
    end
    reducedId = fcn_INTERNAL_faceIds(reducedMesh, thisAngle, renderSettings);

    originalPixelKey = zeros(size(originalId));
    originalPixelKey(originalId>0) = originalKey(originalId(originalId>0));
    reducedPixelKey = zeros(size(reducedId));
    reducedPixelKey(reducedId>0) = reducedKey(reducedId(reducedId>0));
    flagFloorPixel = false(size(reducedId));
    flagFloorPixel(reducedId>0) = flagFloor(reducedId(reducedId>0));

    % (the direction toward the camera)
    towardCamera = [cosd(thisAngle(2))*sind(thisAngle(1)), -cosd(thisAngle(2))*cosd(thisAngle(1)), sind(thisAngle(2))];
    facingAway = zeros(size(reducedId));
    facingAway(reducedId>0) = reducedNormals(reducedId(reducedId>0),:)*towardCamera(:) < -0.05;
    originalFacingAway = false(size(originalId));
    originalFacingAway(originalId>0) = originalNormals(originalId(originalId>0),:)*towardCamera(:) < -0.05;
    facingAway(originalFacingAway) = 0;   % (the download shows the back of that surface too)

    % Holes, label changes, flipped faces (only inside regions)
    flagOriginalInside = fcn_INTERNAL_allNeighbors(originalId>0);
    holes = flagOriginalInside & reducedId==0;
    sameOriginal = fcn_INTERNAL_sameNeighbors(originalPixelKey);
    sameReduced = fcn_INTERNAL_sameNeighbors(reducedPixelKey);
    labelChanges = originalId>0 & reducedId>0 & ~flagFloorPixel & sameOriginal & sameReduced & originalPixelKey~=reducedPixelKey;
    flipped = fcn_INTERNAL_allNeighbors(facingAway>0) & ~flagFloorPixel;

    % See-through gaps: background closed all around by the reduced mesh,
    % more than 8 pixels from any wheel pixel
    flagWheelPixel = false(size(reducedId));
    flagWheelPixel(reducedId>0) = flagWheel(reducedId(reducedId>0));
    nearWheel = conv2(double(flagWheelPixel), ones(17), 'same') > 0;
    enclosed = fcn_INTERNAL_enclosed(reducedId==0);
    seeThrough = fcn_INTERNAL_allNeighbors(enclosed) & ~nearWheel;

    carPixels = sum(originalId(:)>0);
    viewRows{ith_view} = {viewNames{ith_view}, carPixels, ...
        100*sum(holes(:))/max(carPixels,1), 100*sum(labelChanges(:))/max(carPixels,1), 100*sum(flipped(:))/max(carPixels,1), ...
        100*sum(seeThrough(:))/max(carPixels,1)};
    images(ith_view).SeeThrough = seeThrough;
    images(ith_view).Holes = holes;
    images(ith_view).LabelChanges = labelChanges;
    images(ith_view).Flipped = flipped;
    if flagShaded
        if flagOriginalCached
            images(ith_view).Original = originalRenders.Shaded{ith_view};
        else
            images(ith_view).Original = fcn_INTERNAL_shaded(originalMesh, originalLabels.FaceColors, thisAngle, renderSettings);
            originalRenders.Shaded{ith_view} = images(ith_view).Original;
        end
        images(ith_view).Reduced = fcn_INTERNAL_shaded(reducedMesh, reducedLabels.FaceColors, thisAngle, renderSettings);
    end

    % Spots: 32-pixel cells with the most flagged pixels
    cellSize = 32;
    flagged = holes | labelChanges | flipped | seeThrough;
    [numRows, numCols] = size(flagged);
    for row1 = 1:cellSize:numRows
        for col1 = 1:cellSize:numCols
            rows = row1:min(row1+cellSize-1,numRows);
            cols = col1:min(col1+cellSize-1,numCols);
            score = nnz(flagged(rows,cols));
            if score >= 30
                allSpots(end+1) = struct('View',ith_view, 'Box',[row1 rows(end) col1 cols(end)], ...
                    'Holes',sum(holes(rows,cols),'all'), 'LabelChanges',sum(labelChanges(rows,cols),'all'), ...
                    'Flipped',sum(flipped(rows,cols),'all'), 'SeeThrough',sum(seeThrough(rows,cols),'all'), 'Score',score); %#ok<AGROW>
            end
        end
    end
end
if ~isempty(options.OriginalCache) && ~flagOriginalCached
    fcn_CarMesh3D_saveCache(options.OriginalCache, originalCacheInputs, struct('originalRenders',originalRenders), FigNum=-1);
end

% The worst spots, one per neighborhood (no two within 3 cells in a view)
[~, scoreOrder] = sort([allSpots.Score], 'descend');
allSpots = allSpots(scoreOrder);
spots = allSpots([]);
for ith_spot = 1:numel(allSpots)
    if numel(spots) >= options.NumSpots
        break;
    end
    thisSpot = allSpots(ith_spot);
    flagNear = false;
    for ith_kept = 1:numel(spots)
        if spots(ith_kept).View==thisSpot.View && ...
                abs(spots(ith_kept).Box(1)-thisSpot.Box(1)) <= 96 && abs(spots(ith_kept).Box(3)-thisSpot.Box(3)) <= 96
            flagNear = true;
            break;
        end
    end
    if ~flagNear
        spots(end+1) = thisSpot; %#ok<AGROW>
    end
end

viewTable = cell2table(vertcat(viewRows{:}), 'VariableNames', {'View','CarPixels','HolePercent','LabelChangePercent','FlippedPercent','SeeThroughPercent'});
totalPixels = sum(viewTable.CarPixels);
report = struct();
report.Views = viewTable;
report.Totals = struct( ...
    'HolePercent', sum(viewTable.HolePercent.*viewTable.CarPixels)/max(totalPixels,1), ...
    'LabelChangePercent', sum(viewTable.LabelChangePercent.*viewTable.CarPixels)/max(totalPixels,1), ...
    'FlippedPercent', sum(viewTable.FlippedPercent.*viewTable.CarPixels)/max(totalPixels,1), ...
    'SeeThroughPercent', sum(viewTable.SeeThroughPercent.*viewTable.CarPixels)/max(totalPixels,1));
report.Spots = rmfield(spots, 'Score');
report.Images = images;
report.Parts = fcn_INTERNAL_partTable(originalMesh, reducedMesh);
report.MissingLabels = report.Parts.Label(report.Parts.Missing)';

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
if flag_do_plots || ~isempty(options.OutputFile)
    titleText = char(options.Title);
    if flag_do_plots
        viewsFigure = figure(figNum);
        % (the spots sheet: a figure of its own, found again by its name)
        spotsFigure = findobj(groot, 'Type','figure', 'Name',sprintf('%s: flagged spots', titleText));
        if isempty(spotsFigure)
            spotsFigure = figure('Visible','on');
        end
        spotsFigure = spotsFigure(1);
    else
        viewsFigure = figure('Visible','off');
        spotsFigure = figure('Visible','off');
    end

    % The views sheet: the reduced mesh, flagged pixels marked
    clf(viewsFigure);
    set(viewsFigure, 'Color',[1 1 1], 'Name',sprintf('%s: compared with the download', titleText), 'NumberTitle','off');
    layout = tiledlayout(viewsFigure, 4, 4, 'TileSpacing','compact', 'Padding','compact');
    for ith_view = 1:numViews
        axesHandle = nexttile(layout);
        image(axesHandle, fcn_INTERNAL_overlay(images(ith_view)));
        axis(axesHandle,'image','off');
        thisRow = viewTable(ith_view,:);
        title(axesHandle, sprintf('%s: holes %.2f%%, labels %.2f%%, flipped %.2f%%, see-through %.2f%%', viewNames{ith_view}, ...
            thisRow.HolePercent, thisRow.LabelChangePercent, thisRow.FlippedPercent, thisRow.SeeThroughPercent), 'FontSize',7, 'FontWeight','normal');
    end
    title(layout, {sprintf('%s: reduced mesh compared with the download', titleText), ...
        'blue = hole (the download has a surface there)   orange = label changed   red = flipped face   magenta = see-through gap'}, ...
        'Interpreter','none', 'FontSize',11);

    % The spots sheet: original | reduced | reduced with marks
    clf(spotsFigure);
    set(spotsFigure, 'Color',[1 1 1], 'Name',sprintf('%s: flagged spots', titleText), 'NumberTitle','off');
    numSpots = numel(spots);
    if numSpots > 0
        spotLayout = tiledlayout(spotsFigure, numSpots, 3, 'TileSpacing','tight', 'Padding','compact');
        for ith_spot = 1:numSpots
            thisSpot = spots(ith_spot);
            thisImages = images(thisSpot.View);
            [numRows, numCols, ~] = size(thisImages.Reduced);
            rows = max(1, thisSpot.Box(1)-48):min(numRows, thisSpot.Box(2)+48);
            cols = max(1, thisSpot.Box(3)-48):min(numCols, thisSpot.Box(4)+48);
            marked = fcn_INTERNAL_overlay(thisImages);
            panels = {thisImages.Original(rows,cols,:), thisImages.Reduced(rows,cols,:), marked(rows,cols,:)};
            panelNames = {'download','reduced','marked'};
            for ith_panel = 1:3
                axesHandle = nexttile(spotLayout);
                image(axesHandle, panels{ith_panel});
                axis(axesHandle,'image','off');
                if ith_panel==1
                    title(axesHandle, sprintf('%d. %s (holes %d, labels %d, flipped %d, see-through %d px)', ith_spot, viewNames{thisSpot.View}, ...
                        thisSpot.Holes, thisSpot.LabelChanges, thisSpot.Flipped, thisSpot.SeeThrough), 'FontSize',8, 'FontWeight','normal');
                else
                    title(axesHandle, panelNames{ith_panel}, 'FontSize',8, 'FontWeight','normal');
                end
            end
        end
        title(spotLayout, sprintf('%s: the %d worst spots', titleText, numSpots), 'Interpreter','none', 'FontSize',11);
    else
        annotation(spotsFigure, 'textbox', [0 0.4 1 0.2], 'String','No flagged spots', 'EdgeColor','none', ...
            'HorizontalAlignment','center', 'FontSize',14);
    end

    if ~isempty(options.OutputFile)
        set([viewsFigure spotsFigure], 'Position', [20 20 1600 1100]);
        exportgraphics(viewsFigure, [char(options.OutputFile) '_views.png'], 'Resolution',110);
        exportgraphics(spotsFigure, [char(options.OutputFile) '_spots.png'], 'Resolution',110);
        fcn_INTERNAL_saveFig(viewsFigure, [char(options.OutputFile) '_views.png']);
        fcn_INTERNAL_saveFig(spotsFigure, [char(options.OutputFile) '_spots.png']);
    end
    if ~flag_do_plots
        close([viewsFigure spotsFigure]);
    else
        set([viewsFigure spotsFigure], 'Visible','on');
    end
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

%% fcn_INTERNAL_faceIds
function faceIds = fcn_INTERNAL_faceIds(vehicleMesh, viewAngle, settings)
% Which face is seen at each pixel (0 for the background): each face is
% drawn unlit in its own color, the face number in 24 bits
numFaces = size(vehicleMesh.Faces,1);
faceNumbers = (1:numFaces)';
idColors = [floor(faceNumbers/65536), floor(mod(faceNumbers,65536)/256), mod(faceNumbers,256)]/255;
picture = fcn_INTERNAL_render(vehicleMesh, idColors, viewAngle, settings, [0 0 0], false);
faceIds = double(picture(:,:,1))*65536 + double(picture(:,:,2))*256 + double(picture(:,:,3));
faceIds(faceIds > numFaces) = 0;
end % Ends fcn_INTERNAL_faceIds

%% fcn_INTERNAL_shaded
function picture = fcn_INTERNAL_shaded(vehicleMesh, faceColors, viewAngle, settings)
% A lit picture in the label colors, on pink (holes show pink)
picture = fcn_INTERNAL_render(vehicleMesh, faceColors, viewAngle, settings, [1 0.8 0.8], true);
end % Ends fcn_INTERNAL_shaded

%% fcn_INTERNAL_render
function picture = fcn_INTERNAL_render(vehicleMesh, faceColors, viewAngle, settings, background, flagLit)
% Draws the mesh off screen with an orthographic camera fixed by the
% shared box, and returns the picture
spanX = settings.High - settings.Low;
height = round(settings.Width*0.75);
figureHandle = figure('Visible','off', 'Color',background, 'Units','pixels', ...
    'Position',[0 0 settings.Width height], 'InvertHardcopy','off');
set(figureHandle, 'GraphicsSmoothing','off');   % (exact face colors in the face-number pictures)
axesHandle = axes('Parent',figureHandle, 'Position',[0 0 1 1], 'Color',background);
patchHandle = patch(axesHandle, 'Vertices',vehicleMesh.Vertices, 'Faces',vehicleMesh.Faces, ...
    'FaceVertexCData',faceColors, 'FaceColor','flat', 'EdgeColor','none');
axis(axesHandle,'off');
set(axesHandle, 'XLim',[settings.Low(1) settings.High(1)], 'YLim',[settings.Low(2) settings.High(2)], ...
    'ZLim',[settings.Low(3) settings.High(3)], 'DataAspectRatio',[1 1 1], 'Projection','orthographic');
% (the same camera for every mesh, fit to the shared box as seen from
% this view: the box's corners projected on the picture's axes)
towardCamera = [cosd(viewAngle(2))*sind(viewAngle(1)), -cosd(viewAngle(2))*cosd(viewAngle(1)), sind(viewAngle(2))];
if abs(viewAngle(2)) > 80
    upGuess = [1 0 0];
else
    upGuess = [0 0 1];
end
pictureRight = cross(upGuess, towardCamera);
pictureRight = pictureRight/norm(pictureRight);
pictureUp = cross(towardCamera, pictureRight);
[cornerX, cornerY, cornerZ] = ndgrid([settings.Low(1) settings.High(1)], [settings.Low(2) settings.High(2)], [settings.Low(3) settings.High(3)]);
boxCorners = [cornerX(:) cornerY(:) cornerZ(:)];
extentAcross = range(boxCorners*pictureRight(:));
extentUp = range(boxCorners*pictureUp(:));
neededHeight = 1.04*max(extentUp, extentAcross*height/settings.Width);
cameraDistance = 10*norm(spanX);
set(axesHandle, 'CameraTarget',(settings.Low + settings.High)/2, ...
    'CameraPosition',(settings.Low + settings.High)/2 + cameraDistance*towardCamera, ...
    'CameraUpVector',pictureUp, 'CameraViewAngle',2*atand(neededHeight/2/cameraDistance));
if flagLit
    set(patchHandle, 'FaceLighting','flat', 'BackFaceLighting','unlit', 'AmbientStrength',0.7, 'DiffuseStrength',0.45, 'SpecularStrength',0.05);
    camlight(axesHandle, 'headlight');
else
    set(patchHandle, 'FaceLighting','none');
end
picture = print(figureHandle, '-RGBImage', '-r96', '-image');
close(figureHandle);
end % Ends fcn_INTERNAL_render

%% fcn_INTERNAL_allNeighbors
function flagInside = fcn_INTERNAL_allNeighbors(flagMask)
% True where a pixel and its 8 neighbors are all true
flagInside = flagMask;
for shiftRow = -1:1
    for shiftCol = -1:1
        flagInside = flagInside & circshift(flagMask, [shiftRow shiftCol]);
    end
end
end % Ends fcn_INTERNAL_allNeighbors

%% fcn_INTERNAL_sameNeighbors
function flagSame = fcn_INTERNAL_sameNeighbors(keys)
% True where a pixel's 8 neighbors all have its key
flagSame = true(size(keys));
for shiftRow = -1:1
    for shiftCol = -1:1
        flagSame = flagSame & circshift(keys, [shiftRow shiftCol])==keys;
    end
end
end % Ends fcn_INTERNAL_sameNeighbors

%% fcn_INTERNAL_enclosed
function flagEnclosed = fcn_INTERNAL_enclosed(flagBackground)
% True for background pixels not connected (4-connected) to the
% picture's border: closed all around by the car
if exist('imfill','file')   % (Image Processing Toolbox: faster)
    flagEnclosed = imfill(~flagBackground, 4, 'holes') & flagBackground;
    return;
end
flagOutside = false(size(flagBackground));
flagOutside([1 end],:) = flagBackground([1 end],:);
flagOutside(:,[1 end]) = flagBackground(:,[1 end]);
while true
    grown = flagOutside | ([false(1,size(flagOutside,2)); flagOutside(1:end-1,:)] | [flagOutside(2:end,:); false(1,size(flagOutside,2))] | ...
        [false(size(flagOutside,1),1), flagOutside(:,1:end-1)] | [flagOutside(:,2:end), false(size(flagOutside,1),1)]);
    grown = grown & flagBackground;
    if isequal(grown, flagOutside)
        break;
    end
    flagOutside = grown;
end
flagEnclosed = flagBackground & ~flagOutside;
end % Ends fcn_INTERNAL_enclosed

%% fcn_INTERNAL_overlay
function marked = fcn_INTERNAL_overlay(viewImages)
% The reduced picture with the flagged pixels colored
marked = viewImages.Reduced;
if isempty(marked)
    marked = uint8(255*ones([size(viewImages.Holes) 3]));
end
markColors = {viewImages.Holes, [0 90 255]; viewImages.LabelChanges, [255 140 0]; viewImages.Flipped, [230 0 0]; viewImages.SeeThrough, [220 0 220]};
for ith_mark = 1:size(markColors,1)
    flagMark = markColors{ith_mark,1};
    if ~isequal(size(flagMark), [size(marked,1) size(marked,2)])
        continue;
    end
    for ith_channel = 1:3
        channel = marked(:,:,ith_channel);
        channel(flagMark) = markColors{ith_mark,2}(ith_channel);
        marked(:,:,ith_channel) = channel;
    end
end
end % Ends fcn_INTERNAL_overlay

%% fcn_INTERNAL_saveFig
function fcn_INTERNAL_saveFig(figureHandle, pictureFile)
% Saves the figure as a .fig file next to its picture (same name), to
% open later with openfig and zoom, pan, or rotate. The saved copy opens
% visible, even when it was made in a MATLAB with no display (-batch).
[folder, name] = fileparts(pictureFile);
oldCreateFcn = get(figureHandle,'CreateFcn');
set(figureHandle,'CreateFcn','set(gcbo,''Visible'',''on'')');
savefig(figureHandle, fullfile(folder,[name '.fig']), 'compact');
set(figureHandle,'CreateFcn',oldCreateFcn);
end % Ends fcn_INTERNAL_saveFig

%% fcn_INTERNAL_normals
function normals = fcn_INTERNAL_normals(vehicleMesh)
% Unit face normals
corner1 = vehicleMesh.Vertices(vehicleMesh.Faces(:,1),:);
normals = cross(vehicleMesh.Vertices(vehicleMesh.Faces(:,2),:) - corner1, ...
    vehicleMesh.Vertices(vehicleMesh.Faces(:,3),:) - corner1, 2);
normals = normals./max(vecnorm(normals,2,2), eps);
end % Ends fcn_INTERNAL_normals

%% fcn_INTERNAL_partTable
function partTable = fcn_INTERNAL_partTable(originalMesh, reducedMesh)
% Faces and area per label in the download and in the reduced mesh; a
% label that kept less than half of its area (and had at least 0.01 m^2)
% is flagged Missing
[originalKeys, originalAreas] = fcn_INTERNAL_labelAreas(originalMesh);
[reducedKeys, reducedAreas] = fcn_INTERNAL_labelAreas(reducedMesh);
labels = unique([originalKeys; reducedKeys], 'stable');
numLabels = numel(labels);
OriginalFaces = zeros(numLabels,1); ReducedFaces = zeros(numLabels,1);
OriginalArea = zeros(numLabels,1); ReducedArea = zeros(numLabels,1);
for ith_label = 1:numLabels
    flagOriginal = strcmp(originalKeys, labels{ith_label});
    flagReduced = strcmp(reducedKeys, labels{ith_label});
    OriginalFaces(ith_label) = sum(flagOriginal);
    ReducedFaces(ith_label) = sum(flagReduced);
    OriginalArea(ith_label) = sum(originalAreas(flagOriginal));
    ReducedArea(ith_label) = sum(reducedAreas(flagReduced));
end
AreaChangePercent = 100*(ReducedArea - OriginalArea)./max(OriginalArea, eps);
Missing = OriginalArea >= 0.01 & ReducedArea < 0.5*OriginalArea;
Label = labels(:);
partTable = table(Label, OriginalFaces, ReducedFaces, OriginalArea, ReducedArea, AreaChangePercent, Missing);
end % Ends fcn_INTERNAL_partTable

%% fcn_INTERNAL_labelAreas
function [keys, areas] = fcn_INTERNAL_labelAreas(vehicleMesh)
% Each face's label (the part's name; a light's type, as 'light: tail')
% and area
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
areas = 0.5*vecnorm(cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), ...
    vertices(faces(:,3),:) - vertices(faces(:,1),:), 2), 2, 2);
keys = repmat({'(none)'}, size(faces,1), 1);
if isfield(vehicleMesh, 'PartNames') && isfield(vehicleMesh, 'FacePartIndex')
    flagPart = vehicleMesh.FacePartIndex(:) > 0;
    keys(flagPart) = vehicleMesh.PartNames(vehicleMesh.FacePartIndex(flagPart));
end
if isfield(vehicleMesh, 'FaceLightType') && isfield(vehicleMesh, 'LightTypeNames')
    flagLight = vehicleMesh.FaceLightType(:) > 0;
    keys(flagLight) = strcat('light: ', vehicleMesh.LightTypeNames(vehicleMesh.FaceLightType(flagLight)));
end
keys = keys(:);
end % Ends fcn_INTERNAL_labelAreas
