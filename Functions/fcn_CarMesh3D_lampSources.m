function [lampSources, sourcesFile] = fcn_CarMesh3D_lampSources(vehicleInput, options)
% fcn_CarMesh3D_lampSources

% Where a vehicle's lamp-to-function (L2F) cells came from: one row per
% cell that has a source, such as the maker's owner's manual found online
% (Sean, 2026-11-26 19:45: "When possible, we want to rely on manufacturer
% information"). Kept in the vehicle's folder, beside the matrix, as
% lampFunctionsSources_<ID>.csv (rule G40: data about a vehicle lives with
% the vehicle). fcn_CarMesh3D_lampFunctions puts the sourced values into
% the matrix (except in rows a person edited by hand); the lamp-functions
% window draws cells still marked 'auto' in orange, and shows a clicked
% cell's source, with a link, in a strip under the matrix (Q98 (A)).
%
% FORMAT:
%
%       [lampSources, sourcesFile] = fcn_CarMesh3D_lampSources(vehicleInput,...
%           (Sources=lampSources), (FlagSave=flagSave), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or its folder.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Sources: a table as this function returns it, to save (with
%      FlagSave) or to tidy. Default [] (read the vehicle's file).
%
%      FlagSave: true to write Sources to the vehicle's file. Default
%      false.
%
%      FigNum: not used (no plot); -1 for fast mode.
%
% OUTPUTS:
%
%      lampSources: a table, one row per sourced cell, with columns
%           Unit, Signal: the cell (a lamp unit's name, a signal's name)
%           Value: the value the source gives (0 to 1); worked out from
%               the bulb when Bulb is given
%           Bulb, Filament: the bulb type and filament, when known
%               ('W21/5W', 'tail'): the value is then (the filament's
%               lumens / the brightest filament's)^(1/3)
%               (fcn_CarMesh3D_lampBulbs); '' if not
%           Status: 'auto' (found, not yet checked by a person: drawn in
%               orange), 'verified' (checked by a person), or 'default'
%               (no source found: the default is kept, noted only)
%           MakerName: the maker's own name for the signal ('High Beams')
%           Source: a link (or a reference) to where it was found
%           Page: the page or section
%           Accessed: the date the source was read (yyyy-MM-dd)
%           Note: what the source says
%           VerifiedBy, VerifiedOn: who checked it, and when ('' if not)
%      With no file, an empty table with these columns.
%
%      sourcesFile: the file's full name (whether or not it exists).
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_lampBulbs
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_lampSources.m
%       for a full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampSources
%   % * First write (Q98 (A): sourced L2F cells, orange until verified)
%   % * Bulb and Filament: a cell's value from the bulb's lumens, by the
%   %   % cube-root rule (Sean, 21:19)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_lampSources
%   % * (none yet)

arguments
    vehicleInput                 % A vehicle ID or its folder
    options.Sources = []         % A sources table to save or tidy
    options.FlagSave = false     % true to write it to the vehicle's file
    options.FigNum = []          % Not used; -1 for fast mode
end

%% Main code starts here

vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
sourcesFile = fullfile(vehicleFiles.Folder, sprintf('lampFunctionsSources_%s.csv', vehicleFiles.ID));

textColumns = {'Unit', 'Signal', 'Bulb', 'Filament', 'Status', 'MakerName', 'Source', 'Page', 'Accessed', 'Note', 'VerifiedBy', 'VerifiedOn'};
if istable(options.Sources)
    lampSources = options.Sources;
elseif isfile(sourcesFile)
    % (every column read as text: readtable would otherwise make the
    % Accessed dates datetimes and an empty column numbers)
    importOptions = detectImportOptions(sourcesFile, 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    importOptions = setvartype(importOptions, 'char');
    lampSources = readtable(sourcesFile, importOptions);
else
    lampSources = table();
end
lampSources = fcn_INTERNAL_tidy(lampSources, textColumns);

if options.FlagSave
    columnOrder = {'Unit', 'Signal', 'Value', 'Bulb', 'Filament', 'Status', 'MakerName', 'Source', 'Page', 'Accessed', 'Note', 'VerifiedBy', 'VerifiedOn'};
    writetable(lampSources(:, columnOrder), sourcesFile, 'Delimiter', ',', 'QuoteStrings', 'all');
end

end % Ends main function

%% fcn_INTERNAL_tidy
function lampSources = fcn_INTERNAL_tidy(lampSources, textColumns)
% Every column there, text as text (readtable reads an all-empty column as
% numbers), Value as a number from 0 to 1, Status in lower case
numRows = height(lampSources);
for thisColumn = textColumns
    if ~ismember(thisColumn{1}, lampSources.Properties.VariableNames)
        lampSources.(thisColumn{1}) = repmat({''}, numRows, 1);
    else
        values = lampSources.(thisColumn{1});
        if isnumeric(values) || islogical(values)
            texts = repmat({''}, numRows, 1);
            for ith = 1:numRows
                if isfinite(values(ith))
                    texts{ith} = num2str(values(ith));
                end
            end
            lampSources.(thisColumn{1}) = texts;
        elseif isstring(values)
            lampSources.(thisColumn{1}) = cellstr(values);
        end
    end
end
if ~ismember('Value', lampSources.Properties.VariableNames)
    lampSources.Value = zeros(numRows, 1);
end
values = lampSources.Value;
if iscell(values)
    values = str2double(values);
end
values(~isfinite(values)) = 0;
lampSources.Value = min(1, max(0, double(values(:))));
lampSources.Status = lower(strtrim(lampSources.Status));
% (a cell that names its bulb and filament: its value is worked out from
% the bulb's lumens by the cube-root rule, fcn_CarMesh3D_lampBulbs; Sean,
% 2026-11-26 21:19)
for ith = 1:numRows
    if ~isempty(strtrim(lampSources.Bulb{ith}))
        [~, bulbValue] = fcn_CarMesh3D_lampBulbs(Bulb=strtrim(lampSources.Bulb{ith}), ...
            Filament=strtrim(lampSources.Filament{ith}), FigNum=-1);
        if isfinite(bulbValue)
            lampSources.Value(ith) = round(bulbValue, 2);
        else
            warning('CarMesh3D:lampSourcesBulb', 'Unknown bulb or filament for %s, %s: %s %s (the Value given is kept)', ...
                lampSources.Unit{ith}, lampSources.Signal{ith}, lampSources.Bulb{ith}, lampSources.Filament{ith});
        end
    end
end
if numRows == 0
    lampSources = table(cell(0,1), cell(0,1), zeros(0,1), cell(0,1), cell(0,1), cell(0,1), cell(0,1), cell(0,1), cell(0,1), ...
        cell(0,1), cell(0,1), cell(0,1), cell(0,1), 'VariableNames', ...
        {'Unit', 'Signal', 'Value', 'Bulb', 'Filament', 'Status', 'MakerName', 'Source', 'Page', 'Accessed', 'Note', 'VerifiedBy', 'VerifiedOn'});
end
end % Ends fcn_INTERNAL_tidy
