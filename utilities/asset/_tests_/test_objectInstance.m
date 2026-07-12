function tests = test_objectInstance()
% TEST_OBJECTINSTANCE - Unit tests for object instance creation and management
%
% See also:
%   piRead, piObjectInstanceCreate, recipeGet, recipeSet

tests = functiontests(localfunctions);

end

function testObjectInstanceCreation(testCase)
%% Test creating an object instance and verifying it was added to the asset tree.

fileName = fullfile(piRootPath, 'data/scenes/low-poly-taxi/low-poly-taxi.pbrt');
thisR = piRead(fileName);

% Retrieve instances before creation
instances1 = thisR.get('instances');

carName = 'taxi';
rotationMatrix = piRotationMatrix('z', -15);
position       = [-4 0 0];

% Create the instance
thisR = piObjectInstanceCreate(thisR, [carName, '_m_B'], ...
    'rotation', rotationMatrix, 'position', position);
thisR.assets = thisR.assets.uniqueNames;

% Retrieve instances after creation
instances2 = thisR.get('instances');

% Verify that a new instance has been successfully added
testCase.verifyGreaterThan(numel(instances2), numel(instances1));

end

function testObjectInstanceWritesReference(testCase)
%% Test that prepared instances write ObjectInstance records into PBRT.

warningState = warning;
testCase.addTeardown(@() warning(warningState));
warning('off','all');
thisR = piRecipeCreate('sphere');
warning(warningState);

thisR.set('light','all','delete');
distantLight = piLightCreate('distant1','type','distant',...
    'spd','equalEnergy',...
    'specscale float',1,...
    'cameracoordinate',true);
thisR.set('lights',distantLight,'add');

piObjectInstance(thisR);
sphereID = piAssetSearch(thisR,'object name','Sphere');
p2Root = thisR.get('asset',sphereID,'pathtoroot');
referenceID = p2Root(end);
for ii = 1:3
    thisR = piObjectInstanceCreate(thisR,referenceID,...
        'position',ii*[-0.3 0.1 0]);
end
thisR.assets = thisR.assets.uniqueNames;

tempDir = tempname;
mkdir(tempDir);
testCase.addTeardown(@() localRemoveDir(tempDir));

thisR.outputFile = fullfile(tempDir,'instanced_sphere.pbrt');
piWrite(thisR);

geometryFile = fullfile(tempDir,'instanced_sphere_geometry.pbrt');
testCase.assertTrue(isfile(geometryFile));

geometryText = fileread(geometryFile);
testCase.verifyNotEmpty(strfind(geometryText,'ObjectBegin "Sphere"'));
testCase.verifyEqual(numel(strfind(geometryText,'ObjectInstance "Sphere"')),4);

end

function localRemoveDir(folderName)
if isfolder(folderName)
    rmdir(folderName,'s');
end

end
