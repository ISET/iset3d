function resourcePath = piGetResource(resourceType, resourceName)
%PIGETDIR Return full path to a resource of a particular type
% 
%
if isempty(resourceType) || ~ischar(resourceType)
    error("Please pass a valid asset or resource type");
else

    % Set these once, in case we ever need to change them
    ourRoot = piRootPath();
    ourDir = piDirGet(resourceType);
    
    resourcePath = fullfile(ourDir,resourceName);

end

