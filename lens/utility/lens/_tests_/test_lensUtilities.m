function tests = test_lensUtilities()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
localAddDependencies();
testCase.TestData.lensFile = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
end

function testLensFocusAcceptsNameAndObject(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);

fromObject = lensFocus(lens,[1e3 1e6]);
fromName = lensFocus(testCase.TestData.lensFile,[1e3 1e6]);

testCase.verifyEqual(fromObject,fromName,'RelTol',1e-12);
testCase.verifyEqual(fromObject(1),2.17551665624,'RelTol',1e-9);
testCase.verifyEqual(fromObject(2),2.16636385915,'RelTol',1e-9);
testCase.verifyGreaterThan(fromObject(1),fromObject(2));
end

function testLensMatrixAndListCompatibility(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);
d = lensMatrix(lens);

testCase.verifySize(d,[11 4]);
testCase.verifyEqual(d(1,1),lens.get('s radius',1),'AbsTol',1e-12);
testCase.verifyEqual(d(:,4),arrayfun(@(ii) lens.get('s diameter',ii),(1:11)'),'AbsTol',1e-12);

files = lensList('quiet',true);
testCase.verifyTrue(isstruct(files));
testCase.verifyTrue(any(strcmp({files.name},'dgauss.22deg.3.0mm.json')));
end

function testLensPinholeCreatesFlatApertureLens(testCase)
pinhole = lensPinhole(3);

testCase.verifyEqual(pinhole.get('n surfaces'),3);
testCase.verifyEqual(pinhole.get('aperture index'),2);
testCase.verifyEqual(pinhole.get('middle aperture diameter'),3);
testCase.verifyEqual(pinhole.surfaceArray(1).n,ones(size(pinhole.surfaceArray(1).n)));
testCase.verifyGreaterThan(abs(pinhole.get('s radius',1)),1000);
testCase.verifyGreaterThan(abs(pinhole.get('s radius',3)),1000);
end

function localAddDependencies()
rootPath = ilensRootPath();
repoParent = fileparts(rootPath);
addpath(genpath(rootPath));
for name = {'isetcam','iset3d'}
    dependencyRoot = fullfile(repoParent,name{1});
    if isfolder(dependencyRoot), addpath(genpath(dependencyRoot)); end
end
end
