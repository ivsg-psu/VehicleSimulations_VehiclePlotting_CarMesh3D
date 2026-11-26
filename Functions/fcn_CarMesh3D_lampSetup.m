function lampSetup = fcn_CarMesh3D_lampSetup(vehicleMesh, options)
% fcn_CarMesh3D_lampSetup

% Everything needed to light a vehicle's lamps from its lamp-to-function
% (L2F) matrix, worked out once per mesh: the lamp units
% (fcn_CarMesh3D_lampUnits), which unit each lamp face and each cover face
% belongs to, and the matrix (fcn_CarMesh3D_lampFunctions), as numbers.
% fcn_CarMesh3D_lampColors then says, for any set of signals, how each
% unit is lit. fcn_CarMesh3D_plotVehicle and the viewer both light lamps
% this way, so there is one set of lighting rules (the design file,
% section 5: their own copies of the rules lit the 2009 Fit's fog lamps
% with the high beams in the painter).
%
% Where the matrix comes from, first found:
%   1. LampFunctions given here (a table, fcn_CarMesh3D_lampFunctions');
%   2. the mesh's own LampFunctions field (fcn_CarMesh3D_meshWithLabelEdits
%      adds the vehicle's file to the mesh it loads);
%   3. fcn_CarMesh3D_lampFunctions on the mesh (the defaults, and the
%      migration from the mesh).
% A table row whose unit the mesh does not have is left out; a unit the
% table does not name lights as its default.
%
% FORMAT:
%
%       lampSetup = fcn_CarMesh3D_lampSetup(vehicleMesh,...
%           (LampFunctions=table), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleMesh: a labeled CarMesh3D mesh.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      LampFunctions: the matrix, as fcn_CarMesh3D_lampFunctions gives it.
%      Default [] (from the mesh, else the defaults).
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      lampSetup: a structure with
%           Units: the units (fcn_CarMesh3D_lampUnits)
%           Kinds, Sides: each unit's kind ('headlamp', ...) and side
%               ('left', 'right', 'center')
%           FaceUnit: each face's unit, if it is a lamp face (else 0)
%           FaceCoverUnit: each face's unit, if it is a cover (else 0)
%           SignalNames: the matrix's columns (fcn_CarMesh3D_lampSignals)
%           Matrix: units by signals, 0 to 1
%           FaceOwnColors, FaceBrightColors: each face's own color, and the
%               same made as bright as it goes (for lamps that glow in their
%               own colors: reflectors, marker and warning lamps)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_lampUnits, fcn_CarMesh3D_lampFunctions,
%      fcn_CarMesh3D_lampSignals
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampColors.m
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampSetup
%   % * First write (the lamp-functions plan, item 4)

% TO-DO:
%
% (none)



arguments
    vehicleMesh
    options.LampFunctions = []  % The matrix (a table); [] for the mesh's own, else the defaults
    options.FigNum = []         % Not used; -1 for fast mode
end

%% Debugging and Input checks
flag_check_inputs = ~isequal(options.FigNum, -1);
if flag_check_inputs
    if ~(isstruct(vehicleMesh) && all(isfield(vehicleMesh, {'Vertices','Faces'})))
        error('vehicleMesh must be a CarMesh3D mesh (Vertices, Faces)');
    end
    if ~isempty(options.LampFunctions) && ~istable(options.LampFunctions)
        error('LampFunctions must be a table (as fcn_CarMesh3D_lampFunctions gives it), or empty');
    end
end

%% Main code starts here
numFaces = size(vehicleMesh.Faces, 1);
signals = fcn_CarMesh3D_lampSignals();
signalNames = {signals.Name};

lampSetup = struct('Units', [], 'Kinds', {{}}, 'Sides', {{}}, 'FaceUnit', zeros(numFaces,1), ...
    'FaceCoverUnit', zeros(numFaces,1), 'SignalNames', {signalNames}, 'Matrix', zeros(0, numel(signalNames)), ...
    'FaceOwnColors', [], 'FaceBrightColors', []);
if ~isfield(vehicleMesh, 'FaceLightType') || ~isfield(vehicleMesh, 'LightTypeNames') || numel(vehicleMesh.FaceLightType) ~= numFaces
    return;
end

[units, faceUnit] = fcn_CarMesh3D_lampUnits(vehicleMesh, FigNum=-1);
numUnits = numel(units);
flagLampFace = double(vehicleMesh.FaceLightType(:)) > 0;
lampSetup.Units = units;
lampSetup.Kinds = reshape({units.Kind}, [], 1);
lampSetup.Sides = reshape(cellfun(@(position) fcn_INTERNAL_side(position), {units.Position}, 'UniformOutput', false), [], 1);
lampSetup.FaceUnit = faceUnit .* flagLampFace;
lampSetup.FaceCoverUnit = faceUnit .* ~flagLampFace;

% The matrix: given, the mesh's own, or the defaults
lampTable = options.LampFunctions;
if isempty(lampTable) && isfield(vehicleMesh, 'LampFunctions') && istable(vehicleMesh.LampFunctions)
    lampTable = vehicleMesh.LampFunctions;
end
if isempty(lampTable)
    lampTable = fcn_CarMesh3D_lampFunctions(vehicleMesh, FigNum=-1);
end
matrix = zeros(numUnits, numel(signalNames));
defaultTable = [];
for ith_unit = 1:numUnits
    tableRow = find(strcmp(lampTable.Unit, units(ith_unit).Name), 1);
    if isempty(tableRow)
        if isempty(defaultTable)
            defaultTable = fcn_CarMesh3D_lampFunctions(vehicleMesh, FigNum=-1);
        end
        tableRow = find(strcmp(defaultTable.Unit, units(ith_unit).Name), 1);
        sourceTable = defaultTable;
    else
        sourceTable = lampTable;
    end
    for ith_signal = 1:numel(signalNames)
        if ismember(signalNames{ith_signal}, sourceTable.Properties.VariableNames)
            matrix(ith_unit, ith_signal) = min(1, max(0, double(sourceTable.(signalNames{ith_signal})(tableRow))));
        end
    end
end
lampSetup.Matrix = matrix;

% Each face's own color, and the same as bright as it goes
ownColors = 0.5*ones(numFaces, 3);
if isfield(vehicleMesh, 'FaceColors') && size(vehicleMesh.FaceColors, 1) == numFaces
    ownColors = double(vehicleMesh.FaceColors);
end
lampSetup.FaceOwnColors = ownColors;
lampSetup.FaceBrightColors = ownColors ./ max(max(ownColors, [], 2), eps);

end % Ends main function

%% Functions follow

%% fcn_INTERNAL_side
function side = fcn_INTERNAL_side(position)
% 'front-left' gives 'left'
parts = strsplit(position, '-');
side = parts{end};
end % Ends fcn_INTERNAL_side
