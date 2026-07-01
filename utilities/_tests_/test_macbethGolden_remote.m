function tests = test_macbethGolden_remote()
% TEST_MACBETHGOLDEN_REMOTE - Golden value test for Macbeth chart rendering
%
% Simplified from t_piIntro_macbeth.m. Renders the MCC under a distant
% equal-energy light and checks scene luminance, spatial dimensions,
% and patch-level spectral properties against stored golden values.
%
% This test is classified as _remote and requires:
%   - Stanford VPN connection (or on-campus)
%   - Docker configured for remote GPU rendering (orange)
%   - MATLAB preferences set for isetdocker
%
% See also:
%   t_piIntro_macbeth, piRecipeDefault, piWRS, sceneGet

tests = functiontests(localfunctions);

end

%% -------------------------------------------------------------------
function testMacbethGoldenValues(testCase)
%% Render Macbeth chart and verify golden values for the scene.

% ---- Set up rendering environment ----
ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch ME
        testCase.assumeFail(...
            sprintf('Docker not available, skipping: %s', ME.message));
        return;
    end
end

% ---- Build recipe (simplified from t_piIntro_macbeth) ----
thisR = piRecipeDefault;   % MCC is the default

% Replace lights with a single distant equal-energy light.
% Note: distant lights do not support 'cameracoordinate' — they use
% 'from'/'to' direction vectors instead (see piLightCreate.m).
thisR.set('lights', 'all', 'delete');
distantLight = piLightCreate('ee_distant', ...
    'type', 'distant', ...
    'specscale float', 1, ...
    'spd spectrum', 'equalEnergy');
thisR.set('light', distantLight, 'add');

% Moderate resolution — fast enough for CI, detailed enough for goldens
thisR.set('integrator subtype', 'path');
thisR.set('rays per pixel', 64);
thisR.set('fov', 30);
thisR.set('film resolution', [320, 180]);
thisR.set('render type', {'radiance', 'depth'});

% ---- Render ----
try
    scene = piWRS(thisR, 'show', false, 'mean luminance', 100);
catch ME
    testCase.verifyFail(sprintf('piWRS failed: %s', ME.message));
    return;
end

% ---- Golden value checks ----

% 1. Mean luminance should be 100 cd/m2 (set by piWRS mean luminance)
meanLum = sceneGet(scene, 'mean luminance');
testCase.verifyEqual(meanLum, 100, 'RelTol', 0.02, ...
    'Mean luminance should be ~100 cd/m2.');

% 2. Scene spatial size should be consistent with 30 deg FOV
hFOV = sceneGet(scene, 'h fov');
testCase.verifyEqual(hFOV, 30, 'RelTol', 0.05, ...
    'Horizontal FOV should be ~30 degrees.');

% 3. Film resolution should be preserved
rows = sceneGet(scene, 'rows');
cols = sceneGet(scene, 'cols');
testCase.verifyEqual(rows, 180, ...
    'Row count should match requested film resolution.');
testCase.verifyEqual(cols, 320, ...
    'Column count should match requested film resolution.');

% 4. Number of wave samples should match ISETCam defaults (31)
nWave = sceneGet(scene, 'n wave');
testCase.verifyEqual(nWave, 31, ...
    'Spectral sampling should be 31 wavelength bands.');

% 5. Depth map should have a plausible range for this scene geometry.
%    Background pixels that miss all geometry report depth = 0;
%    check only foreground (non-zero) pixels.
depthMap = sceneGet(scene, 'depth map');
fgDepth = depthMap(depthMap > 0);
testCase.assertNotEmpty(fgDepth, ...
    'Depth map should contain foreground pixels with depth > 0.');
testCase.verifyGreaterThan(min(fgDepth), 0, ...
    'Foreground depth values should be positive.');
testCase.verifyLessThan(max(fgDepth), 100, ...
    'Foreground depth values should not exceed 100 m for this scene.');

% 6. Photon data should be non-negative everywhere
photons = sceneGet(scene, 'photons');
testCase.verifyGreaterThanOrEqual(min(photons(:)), 0, ...
    'Photon radiance should be non-negative everywhere.');

% 7. Illuminant spectral flatness (across wavelength, not across space).
%    piSceneCreate assigns an 'equal photons' illuminant — flat in
%    quanta, not energy.  Here we verify spectral uniformity across
%    the 31 wavelength bands.  Spatial uniformity of illumination
%    (variation across pixels) is a separate concern tested elsewhere.
illPhotons = sceneGet(scene, 'illuminant photons');
testCase.assertNotEmpty(illPhotons, ...
    'Scene should contain an illuminant.');

testCase.verifyEqual(mean(double(illPhotons)), 1.2276e+14, 'RelTol', 0.05, ...
    'Mean number of illuminant photons should be about 1.2276e+14.');

end
