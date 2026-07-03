% This script executes when exiting Matlab
%
% I had some issues restarting Matlab because this routine did not return
% in a timely fashion.  We should probably debug some more. (BW).
%
% I did a try/catch.  But ...
%
%%
try
    if ispref('ISETDocker','PBRTContainer')
        fprintf("Removing remote docker containers used by PBRT V4\n")
        localEnsureISETCam();
        thisDocker = isetdocker('verbosity',0);
        thisDocker.reset();
        disp("Docker reset completed.")
    end
catch err
    fprintf('Could not reset docker: %s\n',err.message);
end

%%

function localEnsureISETCam()
% Ensure shared ISETCam helpers are available during MATLAB shutdown.

if ~isempty(which('ieParamFormat')), return; end
if isempty(which('iset3dRootPath')), return; end

repoRoot = iset3dRootPath;
dependencyRoot = fullfile(fileparts(repoRoot),'isetcam');
if isfolder(dependencyRoot)
    addpath(genpath(dependencyRoot));
end

end
