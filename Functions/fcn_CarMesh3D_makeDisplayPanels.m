function panels = fcn_CarMesh3D_makeDisplayPanels(viewer, options)
% fcn_CarMesh3D_makeDisplayPanels
% Builds the display panels that the label viewer and the label painter
% share, into panels a host window gives it, with no window of its own:
%
%   Overall Display    colors (labels or vehicle), mesh boundaries, the
%                      nighttime view, the ground, Reset view, Copy view
%                      call, the camera's angles and distance, the
%                      see-through body, and the photos (folder, turning
%                      the model with them and them with the model, their
%                      size; remembered for the next window)
%   Labels To Display  every label, in groups (main body panels, objects
%                      within interior, lights, visibility), each with a
%                      colored box and Colored? and Shown? (Yes / No), and
%                      an "All labels" row
%   Lamps To Display   each lamp On (a checkbox: one click; the tail
%                      lights Off, On or Brake), Hazards, and "All lamps"
%
% The panels drive the viewer (fcn_CarMesh3D_viewLabels) only through its
% hooks (SetColors, SetBoundaries, SetNightView, SetSeeThrough,
% SetUncolored, SetHidden, SetNightLamp, ...), and show its state. So the
% viewer's own window and the painter (which holds a viewer) show the
% same panels, built by the same code (Q33 (A), Sean, 2026-11-24 02:41:
% one copy, so the two windows cannot drift apart).
%
% FORMAT:
%
%       panels = fcn_CarMesh3D_makeDisplayPanels(viewer,...
%           (Overall=container), (Labels=container), (Lamps=container),...
%           (Band=[r g b]), (LabelColor=function), (OnChange=function),...
%           (FlagShowHidden=function), (SetFlagShowHidden=function),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      viewer: the viewer's handles and hooks, the second output of
%      fcn_CarMesh3D_viewLabels.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Overall, Labels, Lamps: the panels (uipanel) to build each display
%      panel into; [] leaves that one out. Default [].
%
%      Band: the panels' background color. Default [0.93 0.95 1] (pale
%      blue: viewing work, as in the painter).
%
%      LabelColor: color = f(name), the color of a label's box, by name
%      ('body', 'glass', 'headlamp', 'hide', ...). Default: the viewer's
%      own (its LabelColor hook).
%
%      OnChange: f(), called after any change made in the panels (the
%      painter redraws its paint). Default: none.
%
%      ShowHidden, SetFlagShowHidden: flag = f() and f(flag): whether the
%      hidden faces are shown, for a host that keeps that itself (the
%      painter). Default: the viewer's own (the label key 'hidden' in its
%      hidden labels).
%
%      FigNum: not used (nothing is plotted). If set to -1, input checking
%      is skipped (fast mode). Default [].
%
% OUTPUTS:
%
%      panels: a structure of functions:
%           MarkAll(): every panel showing the viewer's state now
%           MarkOverall(), MarkLabels(), MarkLamps(states): one panel
%               (MarkLamps takes the lamp states; give it to the viewer as
%               its OnLamps, so the lamps panel follows the viewer)
%           MarkCamera(): the camera readout (give it to the viewer as
%               its OnView, so it follows the view)
%           RebuildLabels(): build Labels To Display again (after the
%               mesh's labels change)
%           Controls(): the panels' controls, for tests
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_viewLabels (the viewer), fcn_CarMesh3D_lampTypes
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_makeDisplayPanels.m
%       for a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_makeDisplayPanels
%   % * First write (Q33 (A)): the painter's Overall Display, Labels To
%   %   % Display and Lamps To Display, moved here so the viewer's own
%   %   % window shows the same panels; the labels in groups (main body
%   %   % panels, objects within interior, lights, visibility), as agreed
%   %   % for both windows; every lamp type from fcn_CarMesh3D_lampTypes
%   % * Overall Display (Sean's T3, T7, T8 of the viewer, 03:43): Show
%   %   % ground? (moved here from the settings); the camera's angles and
%   %   % distance under Copy view call (MarkCamera); the photos' folder,
%   %   % Turn model with photo? and Photo size? (moved here from under the
%   %   % photo); Colors? and the see-through body grayed out at night
%   % * The camera readout larger and in four lines (Sean, 2026-11-24
%   %   % 04:37): yaw angle with the side it looks from, altitude angle
%   %   % (negative looking down), distance from the center
%   % * Drivable by script for automated tests (Sean, 05:03): Tags on
%   %   % Reset view (overallResetView), Copy view call
%   %   % (overallCopyViewCall), Browse... (overallPhotoBrowse) and the
%   %   % photo folder's text (overallPhotoFolder); the photo options are
%   %   % grayed when the folder has no ViewInDegrees_<angle> photos
%   %   % (the viewer's PhotoCount), not only when there is no folder
%   %   % (and the groups themselves grayed, not only their buttons)
%   % * Bug fixed: Colors? Vehicle stuck out past its button group (radio
%   %   % buttons sized at 8 px a letter; worse when the panel shows its
%   %   % scroll bar, in a short window); now 6 px a letter
%   % * Text cut off in a short window (seen by the layout check in a
%   %   % visible window, 800 x 500): long label names in Labels To Display
%   %   % (the Colored? and Shown? columns are 62 px now, 70 before), and the
%   %   % Lamps header "Off On 3rd state" (now "Off On Brake")
%   % * Turn photo with model? (Sean, 2026-11-23; the shared-panels design
%   %   % file, section 6), under Turn model with photo?; the three photo
%   %   % options remembered when picked here (preferences TurnWithPhoto,
%   %   % TurnPhotoWithModel, PhotoHeight)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In fcn_CarMesh3D_makeDisplayPanels
%   % * Labels To Display: the lamp group is "Lamps", its rows named for
%   %   % what each lamp is ("headlamp", "fog lamp"; Q83 (A)), from
%   %   % fcn_CarMesh3D_lampTypes' new labels (rule P6, Sean 00:46)
%   % * Lamps To Display: a checkbox per lamp, one click on or off, in
%   %   % place of Off/On radio pairs (Sean's Fit feedback: "MUCH faster";
%   %   % the tail lights keep Off/On/Brake)
%   % * The column headings of Labels To Display and Lamps To Display stay
%   %   % at the top: only the rows scroll (Sean: the headings were cut off
%   %   % when scrolled, even full screen)

% TO-DO:
%
% (none)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    viewer
    options.Overall = []           % Panel for Overall Display; [] to leave it out
    options.Labels = []            % Panel for Labels To Display; [] to leave it out
    options.Lamps = []             % Panel for Lamps To Display; [] to leave it out
    options.Band = [0.93 0.95 1]   % Background color (pale blue: viewing work)
    options.LabelColor = []        % color = f(name); [] for the viewer's own
    options.OnChange = []          % f() after any change; [] for none
    options.FlagShowHidden = []        % flag = f(); [] for the viewer's own
    options.SetFlagShowHidden = []     % f(flag); [] for the viewer's own
    options.FigNum = []            % Not used; -1 for fast mode
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
        % Check the viewer input
        neededHooks = {'SetColors','Colors','SetFlagShowEdges','FlagShowEdges','SetFlagNight','FlagNight', ...
            'SetSeeThrough','SeeThrough','ResetView','CopyViewCall','SetUncolored','Uncolored', ...
            'SetHidden','Hidden','LabelKinds','LampTypes','SetNightLamp','NightLights','ShowLabel','Label', ...
            'SetFlagGround','FlagGround','CameraInfo','PhotoFolder','SetPhotoFolder','TurnWithPhoto','SetTurnWithPhoto', ...
            'PhotoHeight','SetPhotoHeight'};
        if ~isstruct(viewer) || ~all(isfield(viewer, neededHooks))
            error('viewer must be the second output of fcn_CarMesh3D_viewLabels (its hooks)');
        end
        % Check the panel inputs
        for panelOption = {'Overall', 'Labels', 'Lamps'}
            if ~isempty(options.(panelOption{1})) && ~isgraphics(options.(panelOption{1}))
                error('%s must be a panel (uipanel) or empty', panelOption{1});
            end
        end
        % Check the function inputs
        for functionOption = {'LabelColor', 'OnChange', 'FlagShowHidden', 'SetFlagShowHidden'}
            if ~isempty(options.(functionOption{1})) && ~isa(options.(functionOption{1}), 'function_handle')
                error('%s must be a function handle or empty', functionOption{1});
            end
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

band = options.Band;
overallControls = struct();
labelRows = struct('Key', {}, 'Colored', {}, 'Shown', {});
lampGroups = struct();

if ~isempty(options.Overall)
    buildOverallPanel();
end
if ~isempty(options.Labels)
    buildLabelsPanel();
end
if ~isempty(options.Lamps)
    buildLampsPanel();
end

panels = struct('MarkAll', @markAll, 'MarkOverall', @markOverall, 'MarkLabels', @markLabels, ...
    'MarkLamps', @markLamps, 'MarkCamera', @markCamera, 'RebuildLabels', @buildLabelsPanel, 'Controls', @getControls);

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the panels' state above (nested, not
% anonymous, so each reads the values of now: how_we_work)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function notifyChange()
        if ~isempty(options.OnChange)
            options.OnChange();
        end
    end

    function color = labelColor(name)
        if ~isempty(options.LabelColor)
            color = options.LabelColor(name);
        else
            color = viewer.LabelColor(name);
        end
    end

    function flagOn = showHiddenOn()
        if ~isempty(options.FlagShowHidden)
            flagOn = logical(options.FlagShowHidden());
        else
            flagOn = ~any(strcmp(viewer.Hidden(), 'hidden'));
        end
    end

    function setFlagShowHidden(flagOn)
        if isnumeric(flagOn) && isnan(flagOn)
            return;
        end
        if ~isempty(options.SetFlagShowHidden)
            options.SetFlagShowHidden(logical(flagOn));
        else
            hidden = viewer.Hidden();
            if flagOn
                hidden = setdiff(hidden, {'hidden'}, 'stable');
            else
                hidden = union(hidden, {'hidden'}, 'stable');
            end
            viewer.SetHidden(hidden);
        end
        notifyChange();
        markLabels();
    end

    function markAll()
        markOverall();
        markLabels();
        markLamps(viewer.NightLights());
    end

    function controls = getControls()
        controls = struct('Overall', overallControls, 'LabelRows', labelRows, 'LampGroups', lampGroups);
    end

    %% Overall Display
    function buildOverallPanel()
        % Colors, mesh boundaries, nighttime view, the ground, the view
        % (with the camera's angles and distance), the see-through body,
        % and the photos (their folder, turning the model with them, their
        % size: moved here from under the photo, Sean 2026-11-24 03:43)
        rowHeights = {22, 24, 24, 24, 24, 28, 28, 'fit', 22, 50, 22, 28, 30, 24, 24, 22, 24};   % (row 8, the camera readout: four lines)
        grid = uigridlayout(options.Overall, [numel(rowHeights) 2], 'RowHeight', rowHeights, 'ColumnWidth', {150, '1x'}, ...
            'Padding', [8 8 8 8], 'RowSpacing', 6, 'BackgroundColor', band, 'Scrollable', 'on');
        fcn_INTERNAL_heading(grid, 1, 'Mesh display', '');
        fcn_INTERNAL_gridText(grid, 2, 1, 'Colors?', 'normal', ...
            'Labels: each face in its label''s color. Vehicle: the colors the animator draws.');
        overallControls.Colors = fcn_INTERNAL_radioRow(grid, {'Labels', 'Vehicle'}, {'labels', 'vehicle'}, 56, ...
            @(value) setOverallColors(value), 'overallColors');
        fcn_INTERNAL_place(overallControls.Colors, 2, 2);
        fcn_INTERNAL_gridText(grid, 3, 1, 'Show mesh boundaries?', 'normal', 'Draw the edge of every face (the mesh''s triangles)');
        overallControls.Boundaries = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setOverallFlagShowEdges(value), 'overallBoundaries');
        fcn_INTERNAL_place(overallControls.Boundaries, 3, 2);
        fcn_INTERNAL_gridText(grid, 4, 1, 'Nighttime view?', 'normal', ['A night scene: the vehicle in its own colors, its lamps lit, ' ...
            'and the light they throw on the ground (switch the lamps in Lamps To Display)']);
        overallControls.Night = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setOverallNight(value), 'overallNight');
        fcn_INTERNAL_place(overallControls.Night, 4, 2);
        fcn_INTERNAL_gridText(grid, 5, 1, 'Show ground?', 'normal', ...
            'A ground plane under the vehicle in 1 m squares, by day and at night (a preference: the viewer and the painter)');
        overallControls.Ground = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setOverallGround(value), 'showGround');
        fcn_INTERNAL_place(overallControls.Ground, 5, 2);
        fcn_INTERNAL_gridText(grid, 6, 1, 'View', 'normal', '');
        resetButton = uibutton(grid, 'Text', 'Reset view', 'ButtonPushedFcn', @(~,~) onResetView(), 'Tag', 'overallResetView', ...
            'Tooltip', 'Back to the starting view (set in GUI settings)');
        fcn_INTERNAL_place(resetButton, 6, 2);
        copyButton = uibutton(grid, 'Text', 'Copy view call', 'ButtonPushedFcn', @(~,~) onCopyViewCall(), 'Tag', 'overallCopyViewCall', ...
            'Tooltip', 'Put the MATLAB call that opens exactly this view (in fcn_CarMesh3D_viewLabels) on the clipboard');
        fcn_INTERNAL_place(copyButton, 7, 2);
        overallControls.Camera = fcn_INTERNAL_gridText(grid, 8, 1, '', 'normal', ...
            ['The camera now: its angle on the photo dial (0 is the front, 90 the left side), how far it looks down, ' ...
            'and its distance from the center of the view']);
        overallControls.Camera.Layout.Column = [1 2];
        set(overallControls.Camera, 'FontColor', [0.15 0.15 0.15], 'FontSize', 13, 'WordWrap', 'off', 'Tag', 'cameraReadout');
        fcn_INTERNAL_heading(grid, 9, 'See-through body', 'Makes the body see-through, to look at what is inside it (by day)');
        overallControls.SeeThrough = uislider(grid, 'Limits', [0 90], 'Value', 0, 'Tag', 'overallSeeThrough', 'MajorTicks', [0 45 90], ...
            'MajorTickLabels', {'0', '45', '90%'}, 'MinorTicks', [], 'FontSize', 9, ...
            'ValueChangedFcn', @(source,~) setOverallSeeThrough(source.Value/100));
        fcn_INTERNAL_place(overallControls.SeeThrough, 10, [1 2]);
        fcn_INTERNAL_heading(grid, 11, 'Photos', '');
        fcn_INTERNAL_gridText(grid, 12, 1, 'Photo folder', 'normal', 'Where the ViewInDegrees_<angle> photos are');
        overallControls.PhotoBrowse = uibutton(grid, 'Text', 'Browse...', 'ButtonPushedFcn', @(~,~) browsePhotoFolder(), 'Tag', 'overallPhotoBrowse', ...
            'Tooltip', 'Pick another folder of ViewInDegrees_<angle> photos');
        fcn_INTERNAL_place(overallControls.PhotoBrowse, 12, 2);
        overallControls.PhotoFolder = fcn_INTERNAL_gridText(grid, 13, 1, '', 'normal', '');
        overallControls.PhotoFolder.Layout.Column = [1 2];
        set(overallControls.PhotoFolder, 'FontColor', [0.3 0.3 0.3], 'FontSize', 11, 'WordWrap', 'on', 'Tag', 'overallPhotoFolder');
        fcn_INTERNAL_gridText(grid, 14, 1, 'Turn model with photo?', 'normal', ...
            'On: picking a photo on the dial turns the model to the same side');
        overallControls.TurnWithPhoto = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setTurnWithPhoto(value), 'turnWithPhoto');
        fcn_INTERNAL_place(overallControls.TurnWithPhoto, 14, 2);
        fcn_INTERNAL_gridText(grid, 15, 1, 'Turn photo with model?', 'normal', ...
            'On: turning the model moves the dial''s arrow and the photo to the same side');
        overallControls.TurnPhotoWithModel = fcn_INTERNAL_radioRow(grid, {'Off', 'On'}, {false, true}, 52, ...
            @(value) setTurnPhotoWithModel(value), 'turnPhotoWithModel');
        fcn_INTERNAL_place(overallControls.TurnPhotoWithModel, 15, 2);
        fcn_INTERNAL_gridText(grid, 16, 1, 'Photo size?', 'normal', 'The photo''s height (its corner can also be dragged)');
        overallControls.PhotoSize = fcn_INTERNAL_radioRow(grid, {'Small', 'Medium', 'Large'}, {220, 300, 420}, 60, ...
            @(value) setPhotoSize(value), 'photoSize', true);
        fcn_INTERNAL_place(overallControls.PhotoSize, 17, [1 2]);
        markOverall();
    end

    function setOverallColors(value)
        viewer.SetColors(value);
        notifyChange();
    end

    function setOverallFlagShowEdges(value)
        viewer.SetFlagShowEdges(value);
        notifyChange();
    end

    function setOverallNight(value)
        viewer.SetFlagNight(value);
        markLamps(viewer.NightLights());
        markOverall();
        notifyChange();
    end

    function setOverallGround(value)
        if isnumeric(value) && isnan(value)
            return;
        end
        viewer.SetFlagGround(logical(value));
        notifyChange();
    end

    function setOverallSeeThrough(fraction)
        viewer.SetSeeThrough(fraction);
        notifyChange();
    end

    function onResetView()
        viewer.ResetView();
        markCamera();
        notifyChange();
    end

    function onCopyViewCall()
        viewer.CopyViewCall();
        notifyChange();
    end

    function browsePhotoFolder()
        folderOut = uigetdir(viewer.PhotoFolder(), 'Folder of ViewInDegrees_<angle> photos');
        if ischar(folderOut)
            viewer.SetPhotoFolder(folderOut);
            markOverall();
            notifyChange();
        end
    end

    function setTurnWithPhoto(value)
        if isnumeric(value) && isnan(value)
            return;
        end
        viewer.SetTurnWithPhoto(logical(value));
        fcn_INTERNAL_remember('TurnWithPhoto', logical(value));
        notifyChange();
    end

    function setTurnPhotoWithModel(value)
        if (isnumeric(value) && isnan(value)) || ~isfield(viewer, 'SetTurnPhotoWithModel')
            return;
        end
        viewer.SetTurnPhotoWithModel(logical(value));
        fcn_INTERNAL_remember('TurnPhotoWithModel', logical(value));
        notifyChange();
    end

    function setPhotoSize(value)
        if isnumeric(value) && isnan(value)
            return;
        end
        viewer.SetPhotoHeight(value);
        fcn_INTERNAL_remember('PhotoHeight', value);
        notifyChange();
    end

    function markOverall()
        % (the overall display's buttons showing the viewer's state)
        if ~isfield(overallControls, 'Colors') || ~isvalid(overallControls.Colors)
            return;
        end
        fcn_INTERNAL_selectRadio(overallControls.Colors, viewer.Colors());
        fcn_INTERNAL_selectRadio(overallControls.Boundaries, logical(viewer.FlagShowEdges()));
        flagNightNow = logical(viewer.FlagNight());
        fcn_INTERNAL_selectRadio(overallControls.Night, flagNightNow);
        fcn_INTERNAL_selectRadio(overallControls.Ground, logical(viewer.FlagGround()));
        overallControls.SeeThrough.Value = 100*viewer.SeeThrough();
        % (at night the vehicle is drawn in its own colors, solid: Colors?
        % and the see-through body act by day only, and say so; Sean's T3,
        % 2026-11-24, found them doing nothing at night)
        dayOnly = matlab.lang.OnOffSwitchState(~flagNightNow);
        set(overallControls.Colors.Children, 'Enable', dayOnly);
        overallControls.Colors.Enable = dayOnly;   % (the group too, so a test's click on it is refused, as a person's is)
        overallControls.SeeThrough.Enable = dayOnly;
        nightTip = '';
        if flagNightNow
            nightTip = ' (by day only: at night the vehicle is drawn in its own colors, solid)';
        end
        overallControls.Colors.Tooltip = ['Labels or vehicle colors' nightTip];
        overallControls.SeeThrough.Tooltip = ['How see-through the body is drawn' nightTip];
        % (the photos: their folder, and whether there are any)
        photoFolderNow = viewer.PhotoFolder();
        flagPhotos = ~isempty(photoFolderNow) && isfolder(photoFolderNow);
        if isfield(viewer, 'PhotoCount')
            % (a folder with no ViewInDegrees_<angle> photos in it: no
            % photos either, so the options are grayed)
            flagPhotos = flagPhotos && viewer.PhotoCount() > 0;
        end
        if flagPhotos
            overallControls.PhotoFolder.Text = photoFolderNow;
            overallControls.PhotoFolder.Tooltip = photoFolderNow;
        else
            overallControls.PhotoFolder.Text = '(no photos: Browse to a folder of ViewInDegrees_<angle> photos)';
        end
        photoState = matlab.lang.OnOffSwitchState(flagPhotos);
        set([overallControls.TurnWithPhoto.Children; overallControls.TurnPhotoWithModel.Children; overallControls.PhotoSize.Children], ...
            'Enable', photoState);
        set([overallControls.TurnWithPhoto, overallControls.TurnPhotoWithModel, overallControls.PhotoSize], 'Enable', photoState);
        fcn_INTERNAL_selectRadio(overallControls.TurnWithPhoto, logical(viewer.TurnWithPhoto()));
        if isfield(viewer, 'TurnPhotoWithModel')
            fcn_INTERNAL_selectRadio(overallControls.TurnPhotoWithModel, logical(viewer.TurnPhotoWithModel()));
        end
        photoHeightNow = viewer.PhotoHeight();
        if ~any(photoHeightNow == [220 300 420])
            photoHeightNow = [];   % (dragged to another size: none of the three)
        end
        fcn_INTERNAL_selectRadio(overallControls.PhotoSize, photoHeightNow);
        markCamera();
    end

    function markCamera()
        % (the camera's angles and distance, under Copy view call; the
        % viewer calls this as the view changes, through its OnView)
        if ~isfield(overallControls, 'Camera') || ~isvalid(overallControls.Camera)
            return;
        end
        camera = viewer.CameraInfo();
        % (in four lines, larger, Sean 04:37: the yaw angle is the photo
        % dial's angle, with the side it looks from; the altitude angle is
        % negative when the camera looks down)
        altitude = -camera.DownAngle;
        if altitude < -0.5
            upDown = 'down';
        elseif altitude > 0.5
            upDown = 'up';
        else
            upDown = 'level';
        end
        if camera.Distance < 10
            distanceText = sprintf('%.1f m', camera.Distance);
        else
            distanceText = sprintf('%.0f m', camera.Distance);
        end
        overallControls.Camera.Text = { ...
            'Camera view:', ...
            sprintf('   yaw angle: %.0f%s (%s)', camera.DialAngle, char(176), fcn_INTERNAL_sideWords(camera.DialAngle)), ...
            sprintf('   altitude angle: %.0f%s (%s)', altitude, char(176), upDown), ...
            sprintf('   distance from center: %s', distanceText)};
    end

    %% Labels To Display
    function buildLabelsPanel()
        % Each label (its color, its name), Colored? (Yes: in its label
        % color; No: plain gray) and Shown? (No: out of view, to reach the
        % faces under it), in groups. Labels with no faces are listed too,
        % in gray italics.
        if isempty(options.Labels) || ~isvalid(options.Labels)
            return;
        end
        delete(options.Labels.Children);
        kinds = viewer.LabelKinds();
        lampTypes = fcn_CarMesh3D_lampTypes(FigNum=-1);
        % (the groups agreed for both windows: main body panels, objects
        % within interior, lights, visibility)
        groups = {'Main body panels', {'part_body', 'part_glass', 'part_wheel', 'part_trim'}, {'body', 'glass', 'wheel', 'trim'};
            'Objects within interior', {'part_interior'}, {'interior'};
            'Lamps', strcat('light_', {lampTypes.Name}), ...
            regexprep({lampTypes.Label}, '^(.)', '${lower($1)}')};   % (what each part is, never what switches it: rule P6)
        listedKeys = [groups{:,2}];
        extra = setdiff(kinds.Keys, [listedKeys, {'hidden'}], 'stable');   % (any other label of the mesh)
        if ~isempty(extra)
            extraNames = cellfun(@(key) kinds.Names{strcmp(kinds.Keys, key)}, extra, 'UniformOutput', false);
            groups(end+1,:) = {'Other labels', extra, extraNames};
        end
        numLabelRows = numel([groups{:,2}]);
        numRows = 1 + size(groups,1) + numLabelRows + 2 + 1;   % (All, groups, labels, visibility and hidden, note)
        % (the column headings in a grid of their own above the rows, so
        % they stay in view when the rows scroll)
        outer = uigridlayout(options.Labels, [2 1], 'RowHeight', {50, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 0, ...
            'BackgroundColor', band);
        header = uigridlayout(outer, [2 4], 'RowHeight', {22, 22}, 'ColumnWidth', {16, '1x', 62, 62}, ...
            'Padding', [8 4 8 0], 'RowSpacing', 2, 'ColumnSpacing', 4, 'BackgroundColor', band, 'Tag', 'labelsHeadings');
        fcn_INTERNAL_gridText(header, 1, 3, 'Colored?', 'bold', 'Yes: drawn in its label color. No: plain gray, so the others stand out.');
        fcn_INTERNAL_gridText(header, 1, 4, 'Shown?', 'bold', 'No: taken out of view (not out of the mesh), to reach the faces under it');
        fcn_INTERNAL_gridText(header, 2, 3, 'Yes  No', 'normal', '');
        fcn_INTERNAL_gridText(header, 2, 4, 'Yes  No', 'normal', '');
        grid = uigridlayout(outer, [numRows 4], 'RowHeight', [repmat({22}, 1, numRows-1), {36}], ...
            'ColumnWidth', {16, '1x', 62, 62}, 'Padding', [8 4 8 8], 'RowSpacing', 6, 'ColumnSpacing', 4, ...
            'BackgroundColor', band, 'Scrollable', 'on');
        labelRows = struct('Key', {}, 'Colored', {}, 'Shown', {});
        % (All labels: sets every row)
        fcn_INTERNAL_gridText(grid, 1, 2, 'All labels', 'bold', 'Sets every label''s row at once');
        allColored = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 30, @(value) setColoredKey('all', value), 'allColored', true);
        fcn_INTERNAL_place(allColored, 1, 3);
        allShown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 30, @(value) setShownKey('all', value), 'allShown', true);
        fcn_INTERNAL_place(allShown, 1, 4);
        labelRows(1) = struct('Key', 'all', 'Colored', allColored, 'Shown', allShown);
        row = 1;
        for ith_group = 1:size(groups,1)
            row = row + 1;
            heading = fcn_INTERNAL_gridText(grid, row, 1, groups{ith_group,1}, 'bold', '');
            set(heading, 'FontColor', [0.25 0.25 0.25]);
            heading.Layout.Column = [1 4];
            keys = groups{ith_group,2};
            names = groups{ith_group,3};
            for ith_key = 1:numel(keys)
                row = row + 1;
                key = keys{ith_key};
                flagPresent = any(strcmp(kinds.Keys, key));
                box = uipanel(grid, 'BackgroundColor', labelColor(regexprep(key, '^(part|light)_', '')), 'BorderType', 'line');
                fcn_INTERNAL_place(box, row, 1);
                nameLabel = fcn_INTERNAL_gridText(grid, row, 2, names{ith_key}, 'normal', '');
                if ~flagPresent
                    set(nameLabel, 'FontColor', [0.55 0.55 0.55], 'FontAngle', 'italic', 'Tooltip', 'No faces have this label yet');
                end
                colored = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 30, @(value) setColoredKey(key, value), ['colored_' key]);
                fcn_INTERNAL_place(colored, row, 3);
                shown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 30, @(value) setShownKey(key, value), ['shown_' key]);
                fcn_INTERNAL_place(shown, row, 4);
                labelRows(end+1) = struct('Key', key, 'Colored', colored, 'Shown', shown); %#ok<AGROW>
            end
        end
        % (visibility: the hidden faces, shown or not)
        row = row + 1;
        heading = fcn_INTERNAL_gridText(grid, row, 1, 'Visibility', 'bold', '');
        set(heading, 'FontColor', [0.25 0.25 0.25]);
        heading.Layout.Column = [1 4];
        row = row + 1;
        box = uipanel(grid, 'BackgroundColor', labelColor('hide'), 'BorderType', 'line');
        fcn_INTERNAL_place(box, row, 1);
        fcn_INTERNAL_gridText(grid, row, 2, 'hidden (not drawn)', 'normal', 'Faces hidden in the mesh (hide, never delete)');
        shown = fcn_INTERNAL_radioRow(grid, {'', ''}, {true, false}, 30, @(value) setFlagShowHidden(value), 'shown_hidden');
        fcn_INTERNAL_place(shown, row, 4);
        labelRows(end+1) = struct('Key', 'hidden', 'Colored', [], 'Shown', shown);
        note = fcn_INTERNAL_gridText(grid, numRows, 1, 'Gray names: no faces have this label yet.', 'normal', '');
        set(note, 'FontColor', [0.4 0.4 0.4], 'FontSize', 11, 'WordWrap', 'on');
        note.Layout.Column = [1 4];
        markLabels();
    end

    function keys = rowKeys()
        keys = setdiff({labelRows.Key}, {'all', 'hidden'}, 'stable');
    end

    function uncolored = currentUncolored()
        % (the labels drawn plain gray now; one label shown alone, as the
        % viewer's Label= or ShowLabel(key) does, is that label colored and
        % every other one gray: V4 in the viewer's design file)
        shownAlone = viewer.Label();
        if ~strcmp(shownAlone, 'all')
            uncolored = setdiff(rowKeys(), {shownAlone}, 'stable');
        else
            uncolored = viewer.Uncolored();
        end
    end

    function setColoredKey(key, flagColored)
        if isnumeric(flagColored) && isnan(flagColored)
            return;
        end
        uncolored = currentUncolored();
        if ~strcmp(viewer.Label(), 'all')
            viewer.ShowLabel('all');   % (from one label alone to the Colored? settings)
        end
        if strcmp(key, 'all')
            if flagColored
                uncolored = {};
            else
                uncolored = rowKeys();
            end
        elseif flagColored
            uncolored = setdiff(uncolored, {key}, 'stable');
        else
            uncolored = union(uncolored, {key}, 'stable');
        end
        viewer.SetUncolored(uncolored);
        notifyChange();
        markLabels();
    end

    function setShownKey(key, flagShown)
        if isnumeric(flagShown) && isnan(flagShown)
            return;
        end
        hidden = viewer.Hidden();
        flagHiddenKey = any(strcmp(hidden, 'hidden'));
        hidden = setdiff(hidden, {'hidden'}, 'stable');
        if strcmp(key, 'all')
            if flagShown
                hidden = {};
            else
                hidden = rowKeys();
            end
        elseif flagShown
            hidden = setdiff(hidden, {key}, 'stable');
        else
            hidden = union(hidden, {key}, 'stable');
        end
        if flagHiddenKey
            hidden{end+1} = 'hidden';   % (the hidden faces keep their own setting)
        end
        viewer.SetHidden(hidden);
        if strcmp(key, 'all')
            setFlagShowHidden(flagShown);   % (All sets the hidden faces' row too; it marks and notifies)
            return;
        end
        notifyChange();
        markLabels();
    end

    function markLabels()
        % (each label's buttons showing the viewer's state; All shows the
        % common setting, or none when they differ)
        if isempty(labelRows) || ~isvalid(labelRows(1).Colored)
            return;
        end
        uncolored = currentUncolored();
        hidden = viewer.Hidden();
        coloredStates = [];
        shownStates = [];
        for ith_row = 2:numel(labelRows)
            key = labelRows(ith_row).Key;
            if strcmp(key, 'hidden')
                fcn_INTERNAL_selectRadio(labelRows(ith_row).Shown, showHiddenOn());
                continue;
            end
            flagColored = ~any(strcmp(uncolored, key));
            flagShown = ~any(strcmp(hidden, key));
            fcn_INTERNAL_selectRadio(labelRows(ith_row).Colored, flagColored);
            fcn_INTERNAL_selectRadio(labelRows(ith_row).Shown, flagShown);
            coloredStates(end+1) = flagColored; %#ok<AGROW>
            shownStates(end+1) = flagShown; %#ok<AGROW>
        end
        fcn_INTERNAL_selectRadio(labelRows(1).Colored, fcn_INTERNAL_common(coloredStates));
        fcn_INTERNAL_selectRadio(labelRows(1).Shown, fcn_INTERNAL_common(shownStates));
    end

    %% Lamps To Display
    function buildLampsPanel()
        % Each lamp Off or On (the tail lights also Brake), lit on the
        % model by day, and with their light at night
        lampTypes = viewer.LampTypes();
        rows = {'LowBeam', 'Low beams', 'headlamp', 'headlamp'; 'HighBeam', 'High beams', 'highBeamLamp', 'highBeamLamp'; ...
            'Running', 'Running lights', 'runningLamp', 'runningLamp'; 'TurnLeft', 'Left turn signal', 'turnSignalLamp', 'turnSignalLamp'; ...
            'TurnRight', 'Right turn signal', 'turnSignalLamp', 'turnSignalLamp'; 'Hazards', 'Hazards', 'turnSignalLamp', 'turnSignalLamp'; ...
            'Tail', 'Tail lights', 'tailBrakeLamp', 'tailBrakeLamp'; 'Backup', 'Backup lights', 'backupLamp', 'backupLamp'; ...
            'Fog', 'Fog lamps', 'fogLamp', 'fogLamp'; 'Reflectors', 'Reflectors lit', 'reflector', 'reflector'; ...
            ... % (tiers 2 and 3, Sean 2026-11-26 17:08: every signal now, to see whether the panel gets crowded;
            ... %  column 3 lists the lamp kinds a signal lights, column 4 the kind whose color the box shows)
            'RearFog', 'Rear fog lamps', {'rearFogLamp'}, 'rearFogLamp'; ...
            'EmergencyBrake', 'Emergency brake', {'tailBrakeLamp', 'highMountStopLamp'}, 'highMountStopLamp'; ...
            'DoorOpen', 'Door open', {'puddleLamp'}, 'puddleLamp'; 'Cargo', 'Cargo lamps', {'cargoLamp'}, 'cargoLamp'; ...
            'Automated', 'Automated (ADS)', {'adsMarkerLamp'}, 'adsMarkerLamp'; ...
            'CorneringLeft', 'Cornering left', {'corneringLamp'}, 'corneringLamp'; ...
            'CorneringRight', 'Cornering right', {'corneringLamp'}, 'corneringLamp'; ...
            'Welcome', 'Welcome', {'puddleLamp', 'logoLamp'}, 'logoLamp'; ...
            'Charging', 'Charging', {'chargePortLamp'}, 'chargePortLamp'; 'Beacon', 'Beacons', {'beaconLamp'}, 'beaconLamp'; ...
            'Work', 'Work lamps', {'workLamp'}, 'workLamp'; ...
            'EmergencyRed', 'Emergency red', {'emergencyRedLamp'}, 'emergencyRedLamp'; ...
            'EmergencyBlue', 'Emergency blue', {'emergencyBlueLamp'}, 'emergencyBlueLamp'; ...
            'EmergencyWhite', 'Emergency white', {'emergencyWhiteLamp'}, 'emergencyWhiteLamp'; ...
            'EmergencyAmber', 'Emergency amber', {'emergencyAmberLamp'}, 'emergencyAmberLamp'; ...
            'EmergencyGreen', 'Emergency green', {'emergencyGreenLamp'}, 'emergencyGreenLamp'; ...
            'SchoolAmber', 'School bus amber', {'schoolBusAmberLamp'}, 'schoolBusAmberLamp'; ...
            'SchoolRed', 'School bus red', {'schoolBusRedLamp', 'stopArmLamp'}, 'schoolBusRedLamp'};
        numRows = size(rows,1) + 2;
        % (the heading in a grid of its own above the rows, so it stays in
        % view when the rows scroll)
        outer = uigridlayout(options.Lamps, [2 1], 'RowHeight', {28, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 0, ...
            'BackgroundColor', band);
        header = uigridlayout(outer, [1 3], 'RowHeight', {22}, 'ColumnWidth', {16, 120, '1x'}, ...
            'Padding', [8 4 8 0], 'ColumnSpacing', 4, 'BackgroundColor', band, 'Tag', 'lampsHeadings');
        fcn_INTERNAL_gridText(header, 1, 3, 'On?  (one click)', 'bold', 'Which lamps are switched on: tick to switch on, untick to switch off');
        grid = uigridlayout(outer, [numRows 3], 'RowHeight', [repmat({22}, 1, numRows-1), {64}], ...
            'ColumnWidth', {16, 120, '1x'}, 'Padding', [8 4 8 8], 'RowSpacing', 6, 'ColumnSpacing', 4, ...
            'BackgroundColor', band, 'Scrollable', 'on');
        lampGroups = struct();
        signalList = fcn_CarMesh3D_lampSignals();
        for ith_row = 1:size(rows,1)
            row = ith_row;
            lampName = rows{ith_row,1};
            box = uipanel(grid, 'BackgroundColor', labelColor(rows{ith_row,4}), 'BorderType', 'line');
            fcn_INTERNAL_place(box, row, 1);
            nameLabel = fcn_INTERNAL_gridText(grid, row, 2, rows{ith_row,2}, 'normal', '');
            signalRow = strcmp({signalList.Name}, lampName);
            if any(signalRow)
                nameLabel.Tooltip = signalList(signalRow).Description;
            end
            if strcmp(lampName, 'Hazards')
                nameLabel.Tooltip = 'Both turn signals at once';
            elseif strcmp(lampName, 'Reflectors')
                nameLabel.Tooltip = 'The reflectors as another car''s headlights light them (outside light)';
            end
            if ~any(ismember(cellstr(rows{ith_row,3}), lampTypes))
                set(nameLabel, 'FontColor', [0.55 0.55 0.55], 'FontAngle', 'italic', ...
                    'Tooltip', 'No faces have this lamp yet; its light still shows at night');
            end
            if strcmp(lampName, 'Tail')
                group = fcn_INTERNAL_radioRow(grid, {'Off', 'On', 'Brake'}, {'off', 'on', 'brake'}, 36, ...
                    @(value) setLamp('Tail', value), 'lamp_Tail');
            else
                group = uicheckbox(grid, 'Text', '', 'Value', false, 'Tag', ['lamp_' lampName], ...
                    'ValueChangedFcn', @(source,~) setLamp(lampName, source.Value));
            end
            fcn_INTERNAL_place(group, row, 3);
            lampGroups.(lampName) = group;
        end
        row = size(rows,1) + 1;
        fcn_INTERNAL_gridText(grid, row, 2, 'All lamps', 'bold', 'Every lamp on (ticked when all are on), or off');
        lampGroups.All = uicheckbox(grid, 'Text', '', 'Value', false, 'Tag', 'lamp_All', ...
            'ValueChangedFcn', @(source,~) setLamp('All', source.Value));
        fcn_INTERNAL_place(lampGroups.All, row, 3);
        note = fcn_INTERNAL_gridText(grid, numRows, 1, ['Lit on the model by day; at night, with their light too. ' ...
            'Which lamps each switch lights is the vehicle''s lamp-to-function matrix: by default, marker lamps light with ' ...
            'the running and tail lights, the license plate lamp with the tail lights. Gray names: no faces have this lamp yet.'], 'normal', '');
        set(note, 'FontColor', [0.4 0.4 0.4], 'FontSize', 11, 'WordWrap', 'on', 'VerticalAlignment', 'top');
        note.Layout.Column = [1 3];
        markLamps(viewer.NightLights());
    end

    function setLamp(name, value)
        if isnumeric(value) && isnan(value)
            return;
        end
        viewer.SetNightLamp(name, value);   % (the viewer calls MarkLamps back, through its OnLamps)
        markLamps(viewer.NightLights());
        notifyChange();
    end

    function markLamps(states)
        % (the lamps' buttons showing the lamp states)
        if ~isfield(lampGroups, 'LowBeam') || ~isvalid(lampGroups.LowBeam)
            return;
        end
        steadyFields = setdiff(fieldnames(lampGroups)', {'Tail', 'Hazards', 'Reflectors', 'All'}, 'stable');
        for lampField = steadyFields
            if isfield(states, lampField{1})
                lampGroups.(lampField{1}).Value = logical(states.(lampField{1}));
            end
        end
        reflectorsOn = isfield(states, 'Reflectors') && states.Reflectors > 0;
        fogOn = isfield(states, 'Fog') && logical(states.Fog);
        lampGroups.Reflectors.Value = reflectorsOn;
        lampGroups.Hazards.Value = logical(states.TurnLeft) && logical(states.TurnRight);
        % (the Tail choice from the true/false Tail and Brake)
        tailChoice = 'off';
        if isfield(states, 'Brake') && logical(states.Brake)
            tailChoice = 'brake';
        elseif logical(states.Tail)
            tailChoice = 'on';
        end
        fcn_INTERNAL_selectRadio(lampGroups.Tail, tailChoice);
        flagsOn = [logical(states.Tail), fogOn, reflectorsOn];
        for lampField = steadyFields
            flagsOn(end+1) = isfield(states, lampField{1}) && logical(states.(lampField{1})); %#ok<AGROW>
        end
        lampGroups.All.Value = all(logical(flagsOn));   % (ticked only when every lamp is on)
    end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_remember
function fcn_INTERNAL_remember(name, value)
% A photo option picked in Overall Display, remembered for the next window
% (a preference in the group CarMesh3D, shared by the viewer and the
% painter: one place for each setting)
try
    setpref('CarMesh3D', name, value);
catch
end
end % Ends fcn_INTERNAL_remember

%% fcn_INTERNAL_radioRow
function group = fcn_INTERNAL_radioRow(parent, texts, values, width, callback, tag, flagMixed)
% One row of side-by-side radio buttons (a button group): an on/off
% choice is always a pair, Off first (a lone radio button cannot be
% clicked off). The callback gets the picked button's value. With
% flagMixed, an unseen extra button is selected when no value applies
% (an "All" row whose rows differ: a group always has one selected).
if nargin < 7
    flagMixed = false;
end
group = uibuttongroup(parent, 'BorderType', 'none', 'BackgroundColor', parent.BackgroundColor, 'Tag', tag, ...
    'SelectionChangedFcn', @(~,event) callback(event.NewValue.UserData));
x = 2;
for ith_button = 1:numel(texts)
    buttonWidth = width;
    if numel(texts{ith_button}) > 3
        % (wide enough for its words; 6 px a letter keeps Colors? Labels /
        % Vehicle inside its column even when the panel shows its scroll
        % bar (about 130 px): at 8 px a letter, Vehicle stuck out past its
        % group, found by the layout check, 2026-11-24)
        buttonWidth = max(width, 6*numel(texts{ith_button}) + 22);
    end
    uiradiobutton(group, 'Text', texts{ith_button}, 'Position', [x 1 buttonWidth 22], 'UserData', values{ith_button});
    x = x + buttonWidth;
end
if flagMixed
    uiradiobutton(group, 'Text', '', 'Position', [x+200 1 10 22], 'UserData', NaN, 'Visible', 'off');
end
end % Ends fcn_INTERNAL_radioRow

%% fcn_INTERNAL_selectRadio
function fcn_INTERNAL_selectRadio(group, value)
% Select the button of this value (the unseen mixed one for NaN or [])
if isempty(group) || ~isvalid(group)
    return;
end
radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton');
for ith_radio = 1:numel(radios)
    radioValue = radios(ith_radio).UserData;
    flagMixedValue = isnumeric(value) && isempty(value);
    if (flagMixedValue && isnumeric(radioValue) && isscalar(radioValue) && isnan(radioValue)) || ...
            (~flagMixedValue && isequal(class(radioValue), class(value)) && isequal(radioValue, value))
        if ~isequal(group.SelectedObject, radios(ith_radio))
            group.SelectedObject = radios(ith_radio);
        end
        return;
    end
end
end % Ends fcn_INTERNAL_selectRadio

%% fcn_INTERNAL_common
function value = fcn_INTERNAL_common(flags)
% The common value of these flags, or [] when they differ
flags = logical(flags);
if isempty(flags) || all(flags)
    value = true;
elseif ~any(flags)
    value = false;
else
    value = [];
end
end % Ends fcn_INTERNAL_common

%% fcn_INTERNAL_gridText
function label = fcn_INTERNAL_gridText(grid, row, column, textIn, weight, tip)
% A text in a grid's cell
label = uilabel(grid, 'Text', textIn, 'FontWeight', weight, 'Tooltip', tip);
label.Layout.Row = row;
label.Layout.Column = column;
end % Ends fcn_INTERNAL_gridText

%% fcn_INTERNAL_heading
function label = fcn_INTERNAL_heading(grid, row, textIn, tip)
% A bold gray heading across a grid's two columns
label = uilabel(grid, 'Text', textIn, 'FontWeight', 'bold', 'FontColor', [0.25 0.25 0.25], 'Tooltip', tip);
label.Layout.Row = row;
label.Layout.Column = [1 2];
end % Ends fcn_INTERNAL_heading

%% fcn_INTERNAL_place
function fcn_INTERNAL_place(component, row, column)
component.Layout.Row = row;
component.Layout.Column = column;
end % Ends fcn_INTERNAL_place

%% fcn_INTERNAL_sideWords
function words = fcn_INTERNAL_sideWords(dialAngle)
% Where the camera looks from, in words, for a photo-dial angle (0 the
% front, 90 the left side, 180 behind, 270 the right side), in eight
% 45-degree sectors
names = {'from the front', 'from the front, left', 'from the left side', 'from behind, left', ...
    'from behind', 'from behind, right', 'from the right side', 'from the front, right'};
if ~isfinite(dialAngle)
    words = 'unknown';
    return;
end
words = names{mod(round(mod(dialAngle, 360)/45), 8) + 1};
end % Ends fcn_INTERNAL_sideWords
