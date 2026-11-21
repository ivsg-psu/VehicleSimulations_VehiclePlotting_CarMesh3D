function objFile = fcn_CarMesh3D_convertToOBJ(inputFile, options)
% fcn_CarMesh3D_convertToOBJ
% Converts a 3D model file that MATLAB cannot read (FBX, glTF, GLB, or a
% Blender .blend file) into a Wavefront OBJ file with a matching .mtl
% material file, by running Blender in the background. The OBJ file can
% then be read by fcn_CarMesh3D_importMesh. (importMesh calls this
% function automatically for these file types.)
%
% Blender is free (blender.org). Install it once; this function finds it
% in the usual install locations, or it can be given with BlenderPath.
% Nothing is changed in the input file.
%
% The OBJ is written with Blender's own axes (Z up). Blender's importers
% already convert FBX and glTF to Z up, so after conversion the usual
% normalize call is
%       fcn_CarMesh3D_normalizeMesh(mesh, UpAxis='+z', ForwardAxis=...)
% where the forward axis depends on the model (often '-y' or '+y').
% Faces are triangulated, modifiers are applied, and every mesh object
% is written with its world position.
%
% REDUCTION IN BLENDER (TargetFaces): a dense download can be reduced to
% about TargetFaces faces during the conversion, with Blender's Decimate
% (collapse) tool, which keeps the outlines of flat pieces (badges, lamp
% lenses, panel edges) far better than MATLAB's reducepatch. First,
% corners closer than 0.1 mm are welded (the glTF importer splits
% surfaces along texture and shading seams), and the faces matching
% RemovePattern are deleted. Then each mesh object is reduced by one
% ratio, except the wheel objects (matching WheelPattern), which keep at
% least WheelFaces faces per wheel so the tires stay round. A piece whose
% reduced corners stray more than 1 cm outside its own original box (the
% collapse can throw a corner of a small, oddly shaped piece far away) is
% reduced again more gently (twice the ratio, up to 4 times), or kept
% whole. Patterns are regular expressions (case ignored) matched to
% '<materialName> <objectName>' for each face's material, as the OBJ's
% '<material> <group>' text is matched later in CarMesh3D.
%
% FORMAT:
%
%       objFile = fcn_CarMesh3D_convertToOBJ(inputFile,...
%           (OutputFile=outputFileName),...
%           (BlenderPath=blenderExecutable),...
%           (Overwrite=flagOverwrite),...
%           (TargetFaces=numFaces), (WheelPattern=regexp),...
%           (WheelFaces=numFaces), (RemovePattern=regexp),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      inputFile: the full or relative path to a .fbx, .glb, .gltf,
%      .blend, or .obj file. (An .obj input is re-written by Blender,
%      which can repair files that fcn_CarMesh3D_importMesh cannot read.)
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      OutputFile: the .obj file to write. Default is the input file name
%      with '_converted.obj' added (or '_reduced<TargetFaces>.obj' when
%      reducing), in the same folder.
%
%      BlenderPath: the full path to the Blender program. Default is ''
%      (search for it). The search order is: the environment variable
%      CARMESH3D_BLENDER_PATH; then on Windows, the newest
%      C:\Program Files\Blender Foundation\Blender*\blender.exe; on a
%      Mac, /Applications/Blender.app/Contents/MacOS/Blender; and finally
%      'blender' on the system path.
%
%      Overwrite: false (default) to reuse an existing output file that
%      is newer than the input file (and, when reducing, was made with the
%      same reduction settings), which skips the slow conversion; true to
%      always convert again.
%
%      TargetFaces: about how many faces to reduce the model to, in
%      Blender (see REDUCTION IN BLENDER above). Default [] (no reduction).
%
%      WheelPattern: a regular expression for the wheel objects, which keep
%      at least WheelFaces faces per wheel. Default '' (no wheels known).
%
%      WheelFaces: the fewest faces per wheel (the four wheels together),
%      at most TargetFaces/8 each. Default 2000.
%
%      RemovePattern: a regular expression for faces to delete before the
%      reduction (a hidden interior, stray pieces), so they take none of
%      the face budget. Default ''.
%
%      FigNum: a figure number to plot the converted mesh. If empty or
%      omitted, no plot is made. If set to -1, input checking is skipped
%      and no plot is made (fast mode).
%
% OUTPUTS:
%
%      objFile: the full path of the OBJ file that was written (or
%      reused).
%
% DEPENDENCIES:
%
%      Blender (free, blender.org), version 2.8 or newer; written for 4.x
%      (reduction: tested with Blender 5.3)
%      fcn_CarMesh3D_importMesh and fcn_CarMesh3D_plotVehicle (only if
%      plotting)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_convertToOBJ.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertToOBJ
%   % * Wrote the code originally (drafted with Claude)
%   % * Fixed brace indexing on a function call (found by Code Analyzer)
%   % * Removed extra command quoting on Windows (MATLAB's system already
%   %   % handles it); tested with Blender 5.3
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertToOBJ
%   % * TargetFaces, WheelPattern, WheelFaces, RemovePattern: reduce the
%   %   % model in Blender during the conversion (Decimate, after welding);
%   %   % outlines of badges, lamps, and panel edges are kept far better
%   %   % than by reducepatch (2025 Toyota Camry)
%   % * Protecting the corners near the wheels from the reduction (so the
%   %   % arches keep their curve) is written but switched off: the other
%   %   % pieces then had to be cut too far (2010 Toyota Camry)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertToOBJ
%   % * Old ASCII FBX files (version 6.1 and earlier) are not supported by
%   %   % Blender; convert those with Autodesk's FBX tools first
%   % * Consider a native binary FBX reader so Blender is not needed
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_convertToOBJ
%   % * Wheel-arch protection (protect_wells in the Blender script): protect
%   %   % only the arch lips (a thin shell around each wheel), not every
%   %   % corner within 0.65 of the wheel's size



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    inputFile
    options.OutputFile = ''    % Output .obj; '' for <input>_converted.obj
    options.BlenderPath = ''   % Blender program; '' to search for it
    options.Overwrite = false  % Convert again even if output is up to date?
    options.TargetFaces = []   % Reduce to about this many faces in Blender; [] for none
    options.WheelPattern = ''  % Regular expression for wheel objects (keep WheelFaces each)
    options.WheelFaces = 2000  % Fewest faces per wheel when reducing
    options.RemovePattern = '' % Regular expression for faces to delete before reducing
    options.FigNum = []        % Figure to plot into; [] for no plot, -1 for fast mode
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
supportedExtensions = {'.fbx','.glb','.gltf','.blend','.obj'};

if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the inputFile input
        if ~(ischar(inputFile) || isstring(inputFile))
            error('inputFile must be a character string');
        end
        if ~exist(inputFile,'file')
            error('File not found: %s',char(inputFile));
        end
        [~,~,tempExtension] = fileparts(char(inputFile));
        if ~any(strcmpi(tempExtension,supportedExtensions))
            error('Unsupported file type: %s. Supported types are: %s',tempExtension,strjoin(supportedExtensions,', '));
        end

        % Check the OutputFile input
        if ~isempty(options.OutputFile)
            if ~(ischar(options.OutputFile) || isstring(options.OutputFile))
                error('OutputFile must be a character string');
            end
            [~,~,tempExtension] = fileparts(char(options.OutputFile));
            if ~strcmpi(tempExtension,'.obj')
                error('OutputFile must end in .obj');
            end
        end

        % Check the BlenderPath input
        if ~isempty(options.BlenderPath) && ~(ischar(options.BlenderPath) || isstring(options.BlenderPath))
            error('BlenderPath must be a character string');
        end

        % Check the reduction inputs
        if ~isempty(options.TargetFaces) && ~(isnumeric(options.TargetFaces) && isscalar(options.TargetFaces) && options.TargetFaces >= 100)
            error('TargetFaces must be a number of faces (100 or more), or empty');
        end
        if ~isnumeric(options.WheelFaces) || ~isscalar(options.WheelFaces) || options.WheelFaces < 0
            error('WheelFaces must be a number of 0 or more');
        end
        for fieldName = {'WheelPattern','RemovePattern'}
            if ~(ischar(options.(fieldName{1})) || isstring(options.(fieldName{1})))
                error('%s must be text (a regular expression)', fieldName{1});
            end
        end

        % Check the Overwrite input
        if ~(islogical(options.Overwrite) || isnumeric(options.Overwrite)) || ~isscalar(options.Overwrite)
            error('Overwrite must be true or false');
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

% Full paths (Blender runs in its own working folder)
inputFile = fcn_INTERNAL_fullPath(char(inputFile));
[inputFolder, inputBaseName, inputExtension] = fileparts(inputFile);
flag_reduce = ~isempty(options.TargetFaces);
if isempty(options.OutputFile) && flag_reduce
    objFile = fullfile(inputFolder, sprintf('%s_reduced%d.obj', inputBaseName, round(options.TargetFaces)));
elseif isempty(options.OutputFile)
    objFile = fullfile(inputFolder, [inputBaseName '_converted.obj']);
else
    objFile = fcn_INTERNAL_fullPath(char(options.OutputFile));
end

% Reuse an up-to-date output file, unless told to overwrite
flag_convert = true;
if ~options.Overwrite && exist(objFile,'file')
    inputInfo = dir(inputFile);
    outputInfo = dir(objFile);
    if outputInfo.datenum >= inputInfo.datenum
        flag_convert = false;
    end
    % (a reduced file is reused only if made with the same settings)
    if flag_reduce && (~isfile([objFile '.settings.txt']) || ~strcmp(strtrim(fileread([objFile '.settings.txt'])), fcn_INTERNAL_settingsText(options)))
        flag_convert = true;
    end
    if ~flag_convert
        if flag_do_debug
            fprintf(1,'Reusing existing converted file: %s\n',objFile);
        end
    end
end

if flag_convert
    blenderPath = fcn_INTERNAL_findBlender(char(options.BlenderPath));

    % Write the Blender Python script to a temporary file
    scriptFile = [tempname '_CarMesh3D_convert.py'];
    fid = fopen(scriptFile,'w');
    if fid<0
        error('Unable to write the temporary Blender script: %s',scriptFile);
    end
    scriptLines = fcn_INTERNAL_blenderScriptLines;
    if flag_reduce
        reduceArguments = sprintf(' "%d" "%s" "%d" "%s"', round(options.TargetFaces), ...
            fcn_INTERNAL_quoteArgument(options.WheelPattern), round(options.WheelFaces), fcn_INTERNAL_quoteArgument(options.RemovePattern));
    else
        reduceArguments = '';
    end
    fprintf(fid,'%s\n',scriptLines{:});
    fclose(fid);
    cleanupScript = onCleanup(@() fcn_INTERNAL_deleteIfExists(scriptFile));

    % Build the command. A .blend file is opened by Blender directly.
    if strcmpi(inputExtension,'.blend')
        commandString = sprintf('"%s" --background --factory-startup "%s" --python-exit-code 1 --python "%s" -- "%s" "%s"%s',...
            blenderPath, inputFile, scriptFile, inputFile, objFile, reduceArguments);
    else
        commandString = sprintf('"%s" --background --factory-startup --python-exit-code 1 --python "%s" -- "%s" "%s"%s',...
            blenderPath, scriptFile, inputFile, objFile, reduceArguments);
    end
    if flag_do_debug
        fprintf(1,'Running: %s\n',commandString);
    end


    [commandStatus, commandOutput] = system(commandString);

    if commandStatus~=0 || ~contains(commandOutput,'CARMESH3D_CONVERT_OK') || ~exist(objFile,'file')
        % Show the end of Blender's output, which holds the error
        outputLines = splitlines(strtrim(commandOutput));
        numLinesToShow = min(15, length(outputLines));
        error('Blender could not convert %s.\nCommand:\n  %s\nLast lines of Blender output:\n  %s',...
            inputFile, commandString, strjoin(outputLines(end-numLinesToShow+1:end),'\n  '));
    end
    if flag_reduce
        reportLines = splitlines(commandOutput);
        reportLines = reportLines(startsWith(reportLines,'CARMESH3D_REDUCE'));
        fprintf(1,'%s\n', reportLines{:});
        settingsId = fopen([objFile '.settings.txt'],'w');
        fprintf(settingsId,'%s\n', fcn_INTERNAL_settingsText(options));
        fclose(settingsId);
    end
end

if flag_do_debug
    fprintf(1,'Converted file: %s\n',objFile);
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
if flag_do_plots
    vehicleMesh = fcn_CarMesh3D_importMesh(objFile, FigNum=-1);
    figure(figNum);
    clf;
    fcn_CarMesh3D_plotVehicle(vehicleMesh, ShowEdges=true, FigNum=figNum);
    title(sprintf('Converted: %s%s (%d faces, Blender axes: Z up)',inputBaseName,inputExtension,size(vehicleMesh.Faces,1)),'Interpreter','none');
    xlabel('X (Blender)'); ylabel('Y (Blender)'); zlabel('Z (Blender, up)');
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

%% fcn_INTERNAL_findBlender
function blenderPath = fcn_INTERNAL_findBlender(blenderPath)
% Finds the Blender program, or gives an error that says how to fix it

% 1. Given directly
if ~isempty(blenderPath)
    if ~exist(blenderPath,'file')
        error('Blender was not found at the given BlenderPath: %s',blenderPath);
    end
    return;
end

% 2. Environment variable
blenderPath = getenv('CARMESH3D_BLENDER_PATH');
if ~isempty(blenderPath) && exist(blenderPath,'file')
    return;
end

% 3. Usual install locations
if ispc
    candidates = dir(fullfile('C:','Program Files','Blender Foundation','Blender*','blender.exe'));
    if ~isempty(candidates)
        % Pick the newest version (folder names sort by version number)
        [~, sortOrder] = sort(lower({candidates.folder}));
        newest = candidates(sortOrder(end));
        blenderPath = fullfile(newest.folder, newest.name);
        return;
    end
elseif ismac
    candidate = '/Applications/Blender.app/Contents/MacOS/Blender';
    if exist(candidate,'file')
        blenderPath = candidate;
        return;
    end
end

% 4. On the system path
if ispc
    [status, result] = system('where blender');
else
    [status, result] = system('which blender');
end
if status==0
    resultLines = splitlines(strtrim(result));
    blenderPath = strtrim(resultLines{1});
    return;
end

error(['Blender was not found. Blender is free from https://www.blender.org. ' ...
    'After installing it, either use the BlenderPath option, or set it once per MATLAB session with ' ...
    'setenv(''CARMESH3D_BLENDER_PATH'',''<full path to blender executable>'').']);
end % Ends fcn_INTERNAL_findBlender

%% fcn_INTERNAL_blenderScriptLines
function scriptLines = fcn_INTERNAL_blenderScriptLines
% The Python script that Blender runs. It imports the input file into an
% empty scene and exports every mesh as one triangulated OBJ with an MTL
% file. It tries the Blender 4.x exporter (wm.obj_export) first and falls
% back to the older one (export_scene.obj) for Blender 2.8 to 3.x. On
% failure it prints a line starting with CARMESH3D_CONVERT_FAILED.
scriptLines = {
    'import bpy, sys, os'
    'argv = sys.argv[sys.argv.index("--") + 1:]'
    'input_file, output_file = argv[0], argv[1]'
    'ext = os.path.splitext(input_file)[1].lower()'
    ''
    'def call_first(attempts):'
    '    """Run the first (operator name, keyword arguments) pair that works."""'
    '    last_error = None'
    '    for name, kwargs in attempts:'
    '        module_name, op_name = name.split(".")'
    '        try:'
    '            result = getattr(getattr(bpy.ops, module_name), op_name)(**kwargs)'
    '            if "FINISHED" in result:'
    '                return result'
    '            last_error = name + " returned " + str(result)'
    '        except Exception as error:'
    '            last_error = name + ": " + str(error)'
    '    raise RuntimeError("CARMESH3D_CONVERT_FAILED: " + str(last_error))'
    ''
    'if ext != ".blend":'
    '    bpy.ops.wm.read_factory_settings(use_empty=True)'
    '    if ext == ".fbx":'
    '        call_first([("import_scene.fbx", dict(filepath=input_file))])'
    '    elif ext in (".glb", ".gltf"):'
    '        call_first([("import_scene.gltf", dict(filepath=input_file))])'
    '    elif ext == ".obj":'
    '        # Read OBJ input as Z up, so an OBJ round trip keeps its axes'
    '        call_first([("wm.obj_import", dict(filepath=input_file, forward_axis="Y", up_axis="Z")),'
    '                    ("wm.obj_import", dict(filepath=input_file)),'
    '                    ("import_scene.obj", dict(filepath=input_file, axis_forward="Y", axis_up="Z")),'
    '                    ("import_scene.obj", dict(filepath=input_file))])'
    '    else:'
    '        raise RuntimeError("CARMESH3D_CONVERT_FAILED: unsupported type " + ext)'
    ''
    'mesh_count = sum(1 for obj in bpy.context.scene.objects if obj.type == "MESH")'
    'print("CARMESH3D mesh objects found:", mesh_count)'
    'if mesh_count == 0:'
    '    raise RuntimeError("CARMESH3D_CONVERT_FAILED: no mesh objects in " + input_file)'
    ''
    '# Optional reduction (TargetFaces given): weld, delete, decimate'
    'if len(argv) >= 6:'
    '    import re, bmesh'
    '    target, wheel_faces = int(argv[2]), int(argv[4])'
    '    wheel_re = re.compile(argv[3], re.I) if argv[3] else None'
    '    remove_re = re.compile(argv[5], re.I) if argv[5] else None'
    '    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]'
    '    counts = {}; is_wheel = {}'
    '    for obj in meshes:'
    '        if obj.data.users > 1:'
    '            obj.data = obj.data.copy()'
    '        names = [s.material.name if s.material else "" for s in obj.material_slots] or [""]'
    '        bm = bmesh.new(); bm.from_mesh(obj.data)'
    '        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)'
    '        if remove_re:'
    '            gone = [f for f in bm.faces if remove_re.search(names[min(f.material_index, len(names)-1)] + " " + obj.name)]'
    '            bmesh.ops.delete(bm, geom=gone, context="FACES")'
    '        bmesh.ops.triangulate(bm, faces=bm.faces[:])'
    '        bm.to_mesh(obj.data); bm.free()'
    '        counts[obj.name] = len(obj.data.polygons)'
    '        is_wheel[obj.name] = bool(wheel_re) and any(wheel_re.search(n + " " + obj.name) for n in names)'
    '    total = sum(counts.values())'
    '    wheel_total = sum(n for k, n in counts.items() if is_wheel[k])'
    '    wheel_keep = min(wheel_total, 4 * min(wheel_faces, target / 8.0))'
    '    other_ratio = min(1.0, max(target - wheel_keep, 0.2 * target) / max(total - wheel_total, 1))'
    '    wheel_ratio = min(1.0, max(other_ratio, wheel_keep / max(wheel_total, 1)))'
    '    # Wheel wells: corners near a wheel are protected (a vertex group the'
    '    # decimation leaves alone), so the arches keep their curve. The wheels'
    '    # are the wheel objects split into four by the box of all of them.'
    '    wheel_points = [o.matrix_world @ v.co for o in meshes if is_wheel[o.name] for v in o.data.vertices]'
    '    wells = []'
    '    if wheel_points:'
    '        lo = [min(p[i] for p in wheel_points) for i in range(3)]; hi = [max(p[i] for p in wheel_points) for i in range(3)]'
    '        mid = [(lo[i] + hi[i]) / 2 for i in range(3)]'
    '        quads = {}'
    '        long_axis = max(range(3), key=lambda i: hi[i] - lo[i])'
    '        side_axis = max([i for i in range(3) if i != long_axis], key=lambda i: hi[i] - lo[i])'
    '        for p in wheel_points:'
    '            quads.setdefault((p[long_axis] > mid[long_axis], p[side_axis] > mid[side_axis]), []).append(p)'
    '        for pts in quads.values():'
    '            qlo = [min(p[i] for p in pts) for i in range(3)]; qhi = [max(p[i] for p in pts) for i in range(3)]'
    '            center = [(qlo[i] + qhi[i]) / 2 for i in range(3)]'
    '            size = max(qhi[i] - qlo[i] for i in range(3))'
    '            wells.append((center, 0.65 * size))'
    '    protected = 0'
    '    protect_wells = False   # (off: it kept the arches, but the other pieces had to be cut too far; see the TO-DO list)'
    '    for obj in meshes:'
    '        n = counts[obj.name]'
    '        ratio = wheel_ratio if is_wheel[obj.name] else other_ratio'
    '        if n > 60 and ratio < 1.0:'
    '            dec = obj.modifiers.new("CarMesh3D_reduce", "DECIMATE")'
    '            dec.decimate_type = "COLLAPSE"'
    '            dec.ratio = max(ratio, 60.0 / n)'
    '            dec.use_collapse_triangulate = True'
    '            if protect_wells and wells and not is_wheel[obj.name]:'
    '                mw = obj.matrix_world'
    '                near = [v.index for v in obj.data.vertices if any(sum(((mw @ v.co)[i] - c[i]) ** 2 for i in range(3)) < rad ** 2 for c, rad in wells)]'
    '                if near:'
    '                    group = obj.vertex_groups.new(name="CarMesh3D_wells")'
    '                    group.add(near, 1.0, "REPLACE")'
    '                    dec.vertex_group = group.name'
    '                    dec.invert_vertex_group = True'
    '                    dec.vertex_group_factor = 3.0'
    '                    protected += len(near)'
    '    def strays(obj):'
    '        dg = bpy.context.evaluated_depsgraph_get(); mw = obj.matrix_world'
    '        pts = [mw @ v.co for v in obj.data.vertices]'
    '        lo = [min(p[i] for p in pts) for i in range(3)]; hi = [max(p[i] for p in pts) for i in range(3)]'
    '        red = [mw @ v.co for v in obj.evaluated_get(dg).data.vertices]'
    '        return any(p[i] < lo[i] - 0.01 or p[i] > hi[i] + 0.01 for p in red for i in range(3))'
    '    retried = kept = 0'
    '    for obj in meshes:'
    '        if "CarMesh3D_reduce" not in obj.modifiers:'
    '            continue'
    '        tries = 0'
    '        while strays(obj) and tries < 4:'
    '            obj.modifiers["CarMesh3D_reduce"].ratio = min(1.0, 2 * obj.modifiers["CarMesh3D_reduce"].ratio)'
    '            tries += 1'
    '        if strays(obj):'
    '            obj.modifiers.remove(obj.modifiers["CarMesh3D_reduce"]); kept += 1'
    '        elif tries:'
    '            retried += 1'
    '    dg = bpy.context.evaluated_depsgraph_get()'
    '    after = sum(len(o.evaluated_get(dg).data.polygons) for o in meshes)'
    '    # (the protected wheel wells keep more faces: the other pieces are'
    '    # reduced further until the total is near the target)'
    '    for attempt in range(6):'
    '        if after <= 1.08 * target:'
    '            break'
    '        scale = target / float(after)'
    '        for obj in meshes:'
    '            if "CarMesh3D_reduce" in obj.modifiers and not is_wheel[obj.name]:'
    '                dec = obj.modifiers["CarMesh3D_reduce"]'
    '                dec.ratio = max(dec.ratio * scale, 60.0 / max(counts[obj.name], 1))'
    '        dg = bpy.context.evaluated_depsgraph_get()'
    '        after = sum(len(o.evaluated_get(dg).data.polygons) for o in meshes)'
    '    print("CARMESH3D_REDUCE Blender reduction: %d faces to %d (wheels: %d faces kept of %d; %d corners near the wheels protected; %d pieces reduced more gently, %d kept whole)" % (total, after, int(wheel_keep), wheel_total, protected, retried, kept))'
    ''
    '# Blender 4.x exporter first, then the older exporter (Blender 2.8 to 3.x)'
    'call_first(['
    '    ("wm.obj_export", dict(filepath=output_file, export_selected_objects=False,'
    '        apply_modifiers=True, export_triangulated_mesh=True, export_materials=True,'
    '        export_uv=False, export_normals=False, forward_axis="Y", up_axis="Z")),'
    '    ("wm.obj_export", dict(filepath=output_file, export_triangulated_mesh=True)),'
    '    ("export_scene.obj", dict(filepath=output_file, use_selection=False,'
    '        use_mesh_modifiers=True, use_triangles=True, use_materials=True,'
    '        use_uvs=False, use_normals=False, axis_forward="Y", axis_up="Z")),'
    '    ("export_scene.obj", dict(filepath=output_file))])'
    ''
    'print("CARMESH3D_CONVERT_OK")'
    };
end % Ends fcn_INTERNAL_blenderScriptLines

%% fcn_INTERNAL_settingsText
function settingsText = fcn_INTERNAL_settingsText(options)
% The reduction settings, as one line (to tell when a reduced file can be reused)
% (Reducer names the version of the reduction steps: a change to them
% also makes a new file)
settingsText = sprintf('Reducer=2026_11_21e; TargetFaces=%d; WheelPattern=%s; WheelFaces=%d; RemovePattern=%s', ...
    round(options.TargetFaces), char(options.WheelPattern), round(options.WheelFaces), char(options.RemovePattern));
end % Ends fcn_INTERNAL_settingsText

%% fcn_INTERNAL_quoteArgument
function text = fcn_INTERNAL_quoteArgument(text)
% A regular expression made safe inside a double-quoted command argument
text = char(text);
text = strrep(text, '"', '\x22');
end % Ends fcn_INTERNAL_quoteArgument

%% fcn_INTERNAL_fullPath
function fullPath = fcn_INTERNAL_fullPath(fileName)
% Makes a path absolute, relative to the current folder if needed
flagAbsolute = startsWith(fileName,'/') || startsWith(fileName,'\\') || ...
    ~isempty(regexp(fileName,'^[A-Za-z]:','once'));
if flagAbsolute
    fullPath = fileName;
else
    fullPath = fullfile(pwd, fileName);
end
end % Ends fcn_INTERNAL_fullPath

%% fcn_INTERNAL_deleteIfExists
function fcn_INTERNAL_deleteIfExists(fileName)
% Deletes a temporary file, if it is still there
if exist(fileName,'file')
    delete(fileName);
end
end % Ends fcn_INTERNAL_deleteIfExists
