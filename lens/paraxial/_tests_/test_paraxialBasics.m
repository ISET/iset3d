function tests = test_paraxialBasics()
tests = functiontests(localfunctions);
end

function testOptPowerAndMatrices(testCase)
opw = optPower([1 1.5],[1.5 1],[10 -10]);
testCase.verifyEqual(opw,[0.05 0.05],'AbsTol',1e-12);

refMat = refractiveMatrix(opw);
testCase.verifySize(refMat,[2 2 1 2]);
testCase.verifyEqual(squeeze(refMat(2,1,1,:)),-opw(:),'AbsTol',1e-12);

transMat = translationMatrix([2 4],[1 2]);
testCase.verifySize(transMat,[2 2 1 2]);
testCase.verifyEqual(squeeze(transMat(1,2,1,:)),[2; 2],'AbsTol',1e-12);
testCase.verifyEqual(translationMatrix([],1),eye(2));
end

function testThinLensPowerAndFocalLengths(testCase)
wave = [500; 600];
[power,fImage,fObject] = paraxThinLens(10,-10,1.5,1,1,wave);

testCase.verifyEqual(power,[0.1; 0.1],'AbsTol',1e-12);
testCase.verifyEqual(fImage,[10; 10],'AbsTol',1e-12);
testCase.verifyEqual(fObject,[-10; -10],'AbsTol',1e-12);
end

function testParaxCreateSurface(testCase)
wave = [500; 600];
surface = paraxCreateSurface(1,2,'mm',wave,'thinlens',0.1,1,1);

testCase.verifyEqual(surface.type,'thin');
testCase.verifyEqual(surface.z_pos,1);
testCase.verifyEqual(surface.diam,2);
testCase.verifyEqual(surface.wave,wave);
testCase.verifyEqual(surface.optPower,0.1);
testCase.verifyEqual(surface.N,ones(2,2));

diaphragm = paraxCreateSurface(3,4,'mm',wave,'diaphragm');
testCase.verifyEqual(diaphragm.type,'diaphragm');
testCase.verifyEqual(diaphragm.diam,4);
end
