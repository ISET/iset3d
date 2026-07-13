function tests = test_lensMTF()
% Unit tests for lens MTF utilities.

tests = functiontests(localfunctions);

end

function testSlantedEdgeMTFAnalysisFromOI(testCase)
%% Analyze a synthetic ISETCam slanted-bar OI without PBRT rendering.

ieInit;

scene = sceneCreate('slantedBar',256,7/3);
scene = sceneAdjustLuminance(scene,100);
scene = sceneSet(scene,'distance',1);
scene = sceneSet(scene,'fov',5);

oi = oiCreate;
oi = oiCompute(oi,scene);

mtfData = piCalculateSlantedEdgeMTF('oi',oi,'plot',false,'roifraction',0.6);

testCase.verifyFalse(isempty(mtfData.freq));
testCase.verifyFalse(isempty(mtfData.mtf));
testCase.verifyTrue(all(isfinite(mtfData.freq(:))));
testCase.verifyTrue(all(isfinite(mtfData.mtf(:))));
testCase.verifyGreaterThan(mtfData.nyquistf,0);
testCase.verifyFalse(isempty(mtfData.esf));
testCase.verifyFalse(isempty(mtfData.lsf));
testCase.verifyEqual(mtfData.mtf(1),1,'AbsTol',1e-6);

end
