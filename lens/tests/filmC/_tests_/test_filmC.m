function tests = test_filmC()
tests = functiontests(localfunctions);
end

function testConstructorInitializesSpectralImage(testCase)
wave = [500 600 700];
film = filmC('position',[1 2 30], ...
    'size',[4 5], ...
    'resolution',[8 9], ...
    'wave',wave);

testCase.verifyEqual(film.position,[1 2 30]);
testCase.verifyEqual(film.size,[4 5]);
testCase.verifyEqual(film.resolution,[8 9]);
testCase.verifyEqual(film.wave,wave);
testCase.verifySize(film.image,[8 9 3]);
testCase.verifyEqual(film.image,zeros(8,9,3));
end

function testClearPreservesShape(testCase)
film = filmC('resolution',[3 4],'wave',[450 550]);
film.image(:) = 7;

film.clear();

testCase.verifySize(film.image,[3 4 2]);
testCase.verifyEqual(film.image,zeros(3,4,2));
end

function testInvalidConstructorInputsThrow(testCase)
testCase.verifyTrue(localThrows(@() filmC('position',[1 2])));
testCase.verifyTrue(localThrows(@() filmC('size',[1 2 3])));
testCase.verifyTrue(localThrows(@() filmC('resolution',[4 5 6])));
end

function testCopyIsIndependent(testCase)
film = filmC('resolution',[2 2],'wave',500);
film.image(1) = 1;

filmCopy = film.copy();
filmCopy.image(1) = 5;

testCase.verifyEqual(film.image(1),1);
testCase.verifyEqual(filmCopy.image(1),5);
end

function tf = localThrows(fcn)
try
    fcn();
    tf = false;
catch
    tf = true;
end
end
