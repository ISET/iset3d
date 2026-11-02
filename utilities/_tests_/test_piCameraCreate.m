function tests = test_piCameraCreate()
% TEST_PICAMERACREATE - Unit tests for creating lens cameras
%
% The deprecated realistic camera type must return a camera PBRT can use,
% which means an omni camera with a json lens file.
%
% See also:
%   piCameraCreate

tests = functiontests(localfunctions);

end

function testRealisticUsesOmniWithJsonLens(testCase)
%% Test realistic with a json lens file.

camera = testCase.verifyWarning( ...
    @() piCameraCreate('realistic','lens file','dgauss.22deg.6.0mm.json'), ...
    'piCameraCreate:RealisticDeprecated');

localVerifyJsonLens(testCase, camera, 'dgauss.22deg.6.0mm.json');

end

function testRealisticReplacesDatLens(testCase)
%% Test realistic with a dat lens file uses the json version.

camera = testCase.verifyWarning( ...
    @() piCameraCreate('realistic','lens file','dgauss.22deg.6.0mm.dat'), ...
    'piCameraCreate:RealisticDeprecated');

localVerifyJsonLens(testCase, camera, 'dgauss.22deg.6.0mm.json');

end

function testRealisticDefaultLens(testCase)
%% Test realistic with no lens file gets the omni default lens.

camera = testCase.verifyWarning(@() piCameraCreate('realistic'), ...
    'piCameraCreate:RealisticDeprecated');

localVerifyJsonLens(testCase, camera, 'dgauss.22deg.12.5mm.json');

end

function testRealisticWithoutJsonVersionErrors(testCase)
%% Test realistic stops at creation when a lens has no json version.

warnState = warning('off','piCameraCreate:RealisticDeprecated');
testCase.addTeardown(@() warning(warnState));

testCase.verifyError( ...
    @() piCameraCreate('realistic','lens file','pinhole.dat'), ?MException);

end

function testOmniRejectsDatLens(testCase)
%% Test omni still requires a json lens file.

testCase.verifyError( ...
    @() piCameraCreate('omni','lens file','dgauss.22deg.6.0mm.dat'), ?MException);

end

function localVerifyJsonLens(testCase, camera, lensName)
%% The camera is omni, and its lens file is the named file in ISETCam.

testCase.verifyEqual(camera.subtype, 'omni');
testCase.verifyEqual(camera.lensfile.value, ...
    fullfile(isetRootPath,'data','lens',lensName));
testCase.verifyTrue(isfile(camera.lensfile.value));

end
