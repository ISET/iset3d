function tests = test_bbmCoordinates()
tests = functiontests(localfunctions);
end

function testCartesianPolarRoundTrip(testCase)
x = [1 -2 0];
y = [1 0 -3];
z = [10 20 30];

[rho,theta,zPolar] = coordCart2Polar3D(x,y,z);
[xRound,yRound,zRound] = coordPolar2Cart3D(rho,theta,zPolar);

testCase.verifyEqual(xRound,x,'AbsTol',1e-12);
testCase.verifyEqual(yRound,y,'AbsTol',1e-12);
testCase.verifyEqual(zRound,z,'AbsTol',1e-12);
end

function testCardinalAngles(testCase)
[rho,theta,z] = coordCart2Polar3D(0,1,5);

testCase.verifyEqual(rho,1,'AbsTol',1e-12);
testCase.verifyEqual(theta,pi/2,'AbsTol',1e-12);
testCase.verifyEqual(z,5);
end
