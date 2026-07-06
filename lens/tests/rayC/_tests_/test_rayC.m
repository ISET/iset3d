function tests = test_rayC()
tests = functiontests(localfunctions);
end

function testConstructorAndGetters(testCase)
rays = localRays();

testCase.verifyEqual(rays.get('n rays'),3);
testCase.verifyEqual(rays.get('wave'),[500 600]);
testCase.verifyEqual(rays.get('wave index'),[1; NaN; 2]);
testCase.verifyEqual(rays.get('live indices'),[true; false; true]);
testCase.verifyEqual(rays.get('wavelength'),[500 NaN 600]);
end

function testNormalizeEndpointAndDistance(testCase)
rays = rayC('origin',[0 0 0; 1 1 1], ...
    'direction',[0 0 2; 3 0 4], ...
    'waveindex',[1; 1], ...
    'wave',550);

rays.normalizeDir();
testCase.verifyEqual(vecnorm(rays.direction,2,2),ones(2,1),'AbsTol',1e-12);

endPoint = rays.endPoint([2; 5]);
testCase.verifyEqual(endPoint(1,:),[0 0 2],'AbsTol',1e-12);
testCase.verifyEqual(endPoint(2,:),[4 1 5],'AbsTol',1e-12);

rays.addDistance([1; 2]);
testCase.verifyEqual(rays.distance,[1; 2]);
end

function testExpandWavelengthsAndWaveIndex(testCase)
rays = rayC('origin',[0 0 0; 1 0 0], ...
    'direction',[0 0 1; 0 0 1], ...
    'waveindex',[1; 1], ...
    'wave',550);

rays.expandWavelengths([500 600 700],[1 3]);

testCase.verifyEqual(rays.get('n rays'),6);
testCase.verifyEqual(rays.get('wave'),[500 600 700]);
testCase.verifyEqual(rays.wave2index(700),3);
testCase.verifyEqual(rays.waveIndex,[1; 1; 3; 3]);
end

function testProjectOnPlaneAndSphereIntersect(testCase)
rays = rayC('origin',[0 0 0; 1 0 0], ...
    'direction',[0 0 1; 0 0 1], ...
    'waveindex',[1; NaN], ...
    'wave',550);

rays.projectOnPlane(5);
testCase.verifyEqual(rays.origin(1,:),[0 0 5],'AbsTol',1e-12);
testCase.verifyEqual(rays.origin(2,:),[1 0 0],'AbsTol',1e-12);

sphereRays = rayC('origin',[0 0 0], ...
    'direction',[0 0 1], ...
    'waveindex',1, ...
    'wave',550);
hit = sphereRays.sphereIntersect([0 0 5],2);
testCase.verifyEqual(hit,[0 0 3],'AbsTol',1e-12);
end

function testLiveRaysCopy(testCase)
rays = localRays();

liveRays = rays.get('live rays');

testCase.verifyEqual(liveRays.get('n rays'),2);
testCase.verifyEqual(liveRays.waveIndex,[1; 2]);
testCase.verifyEqual(liveRays.origin,[0 0 0; 2 0 0]);
end

function rays = localRays()
rays = rayC('origin',[0 0 0; 1 0 0; 2 0 0], ...
    'direction',[0 0 1; 0 1 0; 1 0 0], ...
    'waveindex',[1; NaN; 2], ...
    'wave',[500 600]);
end
