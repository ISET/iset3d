function tests = test_psfCameraC()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
localAddDependencies();
testCase.TestData.lensFile = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
end

function testConstructorGetSetAndClearFilm(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);
film = filmC('position',[0 0 2.2], ...
    'size',[2 2], ...
    'resolution',[11 11], ...
    'wave',lens.get('wave'));
film.image(:) = 1;
point = {[0 0 -1000]};

camera = psfCameraC('lens',lens,'film',film,'point source',point);

testCase.verifyEqual(camera.get('lens'),lens);
testCase.verifyEqual(camera.get('film'),film);
testCase.verifyEqual(camera.get('point source'),point);
testCase.verifyEqual(camera.get('spacing'),2/11,'AbsTol',1e-12);
testCase.verifyEqual(sum(camera.film.image(:)),0);

newPoint = {[0.1 0 -1000]};
camera.set('point source',newPoint);
testCase.verifyEqual(camera.get('point source'),newPoint);
end

function testClearFilmFalsePreservesImage(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);
film = filmC('resolution',[3 3],'wave',lens.get('wave'));
film.image(:) = 2;

camera = psfCameraC('lens',lens,'film',film, ...
    'point source',{[0 0 -1000]}, ...
    'clear film',false);

testCase.verifyEqual(sum(camera.film.image(:)),2*numel(camera.film.image));
end

function testSyntheticImageCentroid(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);
film = filmC('size',[2 2],'resolution',[5 5],'wave',lens.get('wave'));
camera = psfCameraC('lens',lens,'film',film,'point source',{[0 0 -1000]});
camera.film.image(3,4,:) = 1;

centroid = camera.get('image centroid');

testCase.verifyEqual(centroid.X,0.5,'AbsTol',1e-12);
testCase.verifyEqual(centroid.Y,0,'AbsTol',1e-12);
end

function testAutofocusMovesFilmToGoldenDistance(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[5 5]);
film = filmC('wave',lens.get('wave'));
camera = psfCameraC('lens',lens,'film',film,'point source',{[0 0 -1000]});

dist0 = camera.autofocus(550,'nm',1,1);

testCase.verifyEqual(dist0,2.17551665624,'RelTol',1e-9);
testCase.verifyEqual(camera.get('film distance'),dist0,'RelTol',1e-12);
end

function testDeterministicDgaussPsfGolden(testCase)
lens = lensC('filename',testCase.TestData.lensFile,'aperture sample',[9 9]);
pointSource = [10 0 -1000];
imagePoint = lens.findImagePoint(pointSource,1,1);
film = filmC('position',[0 0 imagePoint(4,3)], ...
    'size',[0.2 0.2], ...
    'resolution',[41 41], ...
    'wave',lens.get('wave'));
camera = psfCameraC('lens',lens,'film',film,'point source',{pointSource});

camera.estimatePSF('jitter flag',false,'n lines',0);

img = camera.film.image;
centroid = camera.get('image centroid');
testCase.verifyEqual(imagePoint(4,:), ...
    [-0.030322540960535261 0 2.1755166562350148], ...
    'AbsTol',1e-15);
testCase.verifyEqual(sum(img(:)),322);
testCase.verifyEqual(nnz(img),14);
testCase.verifyEqual(max(img(:)),45);
testCase.verifyEqual(centroid.X,-0.030108695652173913,'AbsTol',1e-15);
testCase.verifyEqual(centroid.Y,0,'AbsTol',1e-15);
testCase.verifyLessThan(abs(centroid.X-imagePoint(4,1)),0.05*film.size(1)/(film.resolution(1)-1));
testCase.verifyLessThan(abs(centroid.Y-imagePoint(4,2)),eps);

sumPerWave = squeeze(sum(sum(img,1),2));
testCase.verifyEqual(sumPerWave,ones(size(sumPerWave))*46);

[xGrid,yGrid] = meshgrid(linspace(-film.size(1)/2,film.size(1)/2,film.resolution(1)), ...
    linspace(-film.size(2)/2,film.size(2)/2,film.resolution(2)));
r2 = reshape((xGrid-centroid.X).^2 + (yGrid-centroid.Y).^2,[41 41 1]);
secondMoment = squeeze(sum(sum(times(img,r2),1),2))./sumPerWave;
testCase.verifyEqual(secondMoment, ...
    ones(size(secondMoment))*5.3166351606805384e-07, ...
    'AbsTol',1e-18);

[~,maxIndex550] = max(img(:,:,4),[],'all');
[maxRow550,maxCol550] = ind2sub([41 41],maxIndex550);
testCase.verifyEqual([maxRow550 maxCol550],[21 15]);
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
