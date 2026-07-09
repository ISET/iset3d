function tests = test_surfaceC()
tests = functiontests(localfunctions);
end

function testConstructorAndZPosition(testCase)
surface = surfaceC('s radius',5,'z position',2, ...
    'aperture diameter',3,'n',ones(7,1)*1.5);

testCase.verifyEqual(surface.get('s radius'),5);
testCase.verifyEqual(surface.sCenter,[0 0 7]);
testCase.verifyEqual(surface.get('z position'),2,'AbsTol',1e-12);
testCase.verifyEqual(surface.apertureD,3);
testCase.verifyEqual(surface.get('n'),ones(7,1)*1.5);
end

function testWaveSetInterpolatesRefractiveIndex(testCase)
surface = surfaceC;
surface.set('wave',[500 600 700]);
surface.set('n',[1.5 1.6 1.7]');

surface.set('wave',[550 650]);

testCase.verifyEqual(surface.get('wave'),[550 650]);
testCase.verifyEqual(surface.get('n'),[1.55 1.65]','AbsTol',1e-12);
end

function testConicAndAsphericAccessors(testCase)
surface = surfaceC('conic constant',-0.5,'aspheric coeff',[1e-3 2e-4]);

testCase.verifyEqual(surface.get('conic constant'),-0.5);
testCase.verifyEqual(surface.get('aspheric coeff'),[1e-3 2e-4]);

surface.set('aspheric coeff',[3e-5 4e-6]);
testCase.verifyEqual(surface.get('aspheric coeff'),[3e-5 4e-6]);
end

function testInvalidIndexLengthThrows(testCase)
testCase.verifyTrue(localThrows(@() surfaceC('n',[1 1])));

surface = surfaceC;
testCase.verifyTrue(localThrows(@() surface.set('n',[1 1])));
end

function tf = localThrows(fcn)
try
    fcn();
    tf = false;
catch
    tf = true;
end
end
