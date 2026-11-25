function fingerprint = fcn_CarMesh3D_fingerprint(varargin)
% fcn_CarMesh3D_fingerprint
% A short fingerprint (a SHA-256 hash, as 64 hexadecimal characters) of
% the VALUES given, not of any file: the same values give the same
% fingerprint on any computer, after copies, git, or saving again; any
% change gives a different one. The V&V GUI keeps one with each answer, of
% the data the question was about, so an answer is known to be out of date
% once that data changes (the V&V design file, section 4).
%
% Floating-point values are rounded to 1e-6 before hashing, so a rebuild
% that changes only round-off (the last few bits) gives the same
% fingerprint. The shape of each value counts too ([1 2 3] and [1;2;3]
% differ), and so does its order among the inputs.
%
% Uses Java's java.security.MessageDigest, which comes with MATLAB (no
% toolbox).
%
% FORMAT:
%
%       fingerprint = fcn_CarMesh3D_fingerprint(value1, value2, ...)
%
% INPUTS:
%
%      value1, value2, ...: numeric, logical, char or string arrays, or
%      cell arrays of these (nested cells are taken in order). Structures
%      are not taken: pass their fields.
%
% OUTPUTS:
%
%      fingerprint: a 1 x 64 char array, such as '3f1a...'.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       fingerprint = fcn_CarMesh3D_fingerprint(vehicleMesh.Vertices, vehicleMesh.Faces);
%
%       See the script: script_test_fcn_CarMesh3D_fingerprint.m for a
%       full test suite.
%
% This function was written on 2026_11_25 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fingerprint
%   % * First write (Sean, 2026-11-24 23:28: hash the data, not the file;
%   %   % the rounding, 23:41)

% TO-DO:
%
% (none)

%% Main code
% (no FigNum: every input is a value to hash)
digest = java.security.MessageDigest.getInstance('SHA-256');
for ith_input = 1:nargin
    fcn_INTERNAL_add(digest, varargin{ith_input});
end
fingerprint = lower(reshape(dec2hex(typecast(digest.digest(), 'uint8'), 2).', 1, []));

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_add
function fcn_INTERNAL_add(digest, value)
% Adds one value's kind, shape and contents to the hash
if iscell(value)
    digest.update(uint8(['cell' sprintf('%d,', size(value))]));
    for ith_item = 1:numel(value)
        fcn_INTERNAL_add(digest, value{ith_item});
    end
    return;
end
if isstring(value)
    value = char(strjoin(value(:), char(0)));
end
if isstruct(value) || istable(value) || isobject(value)
    error('CarMesh3D:badInput', 'fcn_CarMesh3D_fingerprint takes numbers, logicals, text and cells; pass a structure''s fields.');
end
digest.update(uint8([class(value) sprintf('%d,', size(value))]));
if isempty(value)
    return;
end
if ischar(value)
    bytes = typecast(uint16(value(:)), 'uint8');
elseif islogical(value)
    bytes = uint8(value(:));
elseif isfloat(value)
    rounded = round(double(value(:))*1e6);   % (round-off below 1e-6 does not count)
    rounded(rounded == 0) = 0;               % (-0 and 0 the same)
    rounded(isnan(rounded)) = NaN;           % (one NaN)
    bytes = typecast(rounded, 'uint8');
else
    bytes = typecast(value(:), 'uint8');
end
digest.update(bytes);
end % Ends fcn_INTERNAL_add
