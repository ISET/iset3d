function report = validatePrefs(obj)
% validatePrefs Validate the current ISETDocker object/preferences.
%
% Synopsis
%   report = obj.validatePrefs()
%
% Description
%   Checks the preference values used by isetdocker without changing Docker
%   contexts or MATLAB preferences.  The returned report has fields:
%   ok, errors, warnings, repairCommands, and prefs.
%
% See also
%   isetdocker.validatePrefStruct, isetdocker.validateDockerContext

prefs = obj.prefStruct();
report = isetdocker.validatePrefStruct(prefs);

end
