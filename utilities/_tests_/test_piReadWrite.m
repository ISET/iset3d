function tests = test_piReadWrite()
% TEST_PIREADWRITE - Unit tests for PBRT file reading (piRead) and writing (piWrite)
%
% This test builds a self-contained mock PBRT file structure, parses it into
% a recipe, modifies it, writes it back, and verifies the parsed round-trip properties.
%
% See also:
%   piRead, piWrite, recipe

tests = functiontests(localfunctions);

end

function testReadWriteRoundTrip(testCase)
%% Test reading a minimal PBRT file and writing it back with updates.

% 1. Create a minimal valid PBRT structure
mockContent = { ...
    'LookAt 0 0 0  0 0 -1  0 1 0', ...
    'Camera "pinhole" "float fov" [45]', ...
    'Film "rgb" "integer xresolution" [200] "integer yresolution" [150]', ...
    'Sampler "halton" "integer pixelsamples" [32]', ...
    'Integrator "path"', ...
    'WorldBegin', ...
    'LightSource "distant" "point3 from" [0 10 0]', ...
    'Material "diffuse"', ...
    'Shape "sphere" "float radius" [1]', ...
    'WorldEnd' ...
};

tempDir = fullfile(piRootPath, 'local', 'test_temp');
if ~isfolder(tempDir), mkdir(tempDir); end
cleanupFolder = onCleanup(@() rmdir(tempDir, 's'));

inputFile = fullfile(tempDir, 'mock_scene.pbrt');
outputFile = fullfile(tempDir, 'mock_scene_out.pbrt');

fid = fopen(inputFile, 'w');
testCase.assertGreaterThan(fid, 0);
for ii = 1:numel(mockContent)
    fprintf(fid, '%s\n', mockContent{ii});
end
fclose(fid);

% 2. Read the mock PBRT file
[thisR, ~] = piRead(inputFile);

% Verify parsed camera and film options
testCase.verifyEqual(thisR.get('camera subtype'), 'pinhole');
testCase.verifyEqual(thisR.get('fov'), 45);
testCase.verifyEqual(thisR.get('film resolution'), [200, 150]);

% 3. Modify options
thisR.set('film resolution', [400, 300]);
thisR.set('fov', 60);
thisR.outputFile = outputFile;

% 4. Write out the modified PBRT file
piWrite(thisR);

% Verify output file exists
testCase.verifyTrue(isfile(outputFile));

% 5. Read the output file back and verify updates
[roundTripR, ~] = piRead(outputFile);

testCase.verifyEqual(roundTripR.get('film resolution'), [400, 300]);
testCase.verifyEqual(roundTripR.get('fov'), 60);

end
