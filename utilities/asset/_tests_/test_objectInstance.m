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
