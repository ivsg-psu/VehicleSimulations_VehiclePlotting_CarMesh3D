% script_test_fcn_CarMesh3D_fingerprint.m
% Tests fcn_CarMesh3D_fingerprint.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fingerprint
%   % * First write

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% DEMO case: a fingerprint of a small mesh
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case\n', figNum);
vertices = [0 0 0; 1 0 0; 0 1 0];
faces = [1 2 3];
fingerprint = fcn_CarMesh3D_fingerprint(vertices, faces);
assert(ischar(fingerprint) && numel(fingerprint) == 64 && all(ismember(fingerprint, '0123456789abcdef')));

%% TEST case: the same values give the same fingerprint; a change gives another
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: same and different\n', figNum);
assert(strcmp(fingerprint, fcn_CarMesh3D_fingerprint(vertices, faces)), 'The same values');
assert(~strcmp(fingerprint, fcn_CarMesh3D_fingerprint(vertices + [0 0 0.001], faces)), 'A vertex moved 1 mm');
assert(~strcmp(fingerprint, fcn_CarMesh3D_fingerprint(vertices, faces([1 3 2]))), 'A face turned over');
assert(~strcmp(fingerprint, fcn_CarMesh3D_fingerprint(faces, vertices)), 'The order of the inputs counts');
assert(~strcmp(fcn_CarMesh3D_fingerprint([1 2 3]), fcn_CarMesh3D_fingerprint([1; 2; 3])), 'The shape counts');
assert(~strcmp(fcn_CarMesh3D_fingerprint(int32([1 2])), fcn_CarMesh3D_fingerprint([1 2])), 'The kind counts');

%% TEST case: round-off below 1e-6 does not count
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: round-off\n', figNum);
assert(strcmp(fingerprint, fcn_CarMesh3D_fingerprint(vertices + 1e-12, faces)), 'Round-off');
assert(strcmp(fcn_CarMesh3D_fingerprint(0), fcn_CarMesh3D_fingerprint(-0)), '-0 and 0');
assert(strcmp(fcn_CarMesh3D_fingerprint(single(0.5)), fcn_CarMesh3D_fingerprint(single(0.5))));

%% TEST case: text, logicals, cells
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: text, logicals, cells\n', figNum);
assert(~strcmp(fcn_CarMesh3D_fingerprint('body'), fcn_CarMesh3D_fingerprint('glass')));
assert(strcmp(fcn_CarMesh3D_fingerprint("body"), fcn_CarMesh3D_fingerprint("body")));
assert(~strcmp(fcn_CarMesh3D_fingerprint(true(3,1)), fcn_CarMesh3D_fingerprint(false(3,1))));
assert(~strcmp(fcn_CarMesh3D_fingerprint({'a', 'b'}), fcn_CarMesh3D_fingerprint({'b', 'a'})));
assert(~isempty(fcn_CarMesh3D_fingerprint([], {}, '')), 'Empty values');

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode: a large mesh\n', figNum);
bigVertices = rand(200000, 3);
bigFaces = randi(200000, 400000, 3);
tic;
fcn_CarMesh3D_fingerprint(bigVertices, bigFaces);
elapsed = toc;
fprintf(1,'    200k vertices and 400k faces: %.2f s\n', elapsed);
assert(elapsed < 5, 'A large mesh in under 5 s');

%% BUG cases
% (none yet)

%% Fail conditions
try
    fcn_CarMesh3D_fingerprint(struct('a', 1));
    error('test:noError', 'A structure was taken');
catch caughtError
    assert(contains(caughtError.message, 'pass a structure'), caughtError.message);
end

fprintf(1,'All tests of fcn_CarMesh3D_fingerprint passed\n');
