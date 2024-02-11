function thisD = humanEyeDocker()
%HUMANEYEDOCKER Get docker Wrapper for human eye rendering
%
% Brief
%  Currently the human eye rendering is only on CPU.  It can run remotely,
%  however.
%
% Input
%   N/A
%
% Output
%  thisD - Configured for CPU and digitalprodev/pbrt-v4-cpu
%
% TODO:  Add an options.remote so you can run a local version
%
% See also
%
thisD = dockerWrapper;
thisD.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
thisD.gpuRendering = 0;

end
