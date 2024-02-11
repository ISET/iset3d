function dockerImage = localImage()
%LOCALIMAGE Find the right Docker image for our CPU type
%
% Returns a string with information about the local Docker image
% that is right for our CPU -- it does not look for GPUs.
%
% Currently pbrt is architecture specific, so we need to launch the
% correct Docker Image.  We will add to this list as the number of
% sites and users increase. 
%
% See also
%

% Which CPU type are we running on locally?
thisCPU = cpuinfo; 

switch thisCPU.CPUName
    % should include other ARM processors
    case 'Apple M1 Pro'
        % Created by Zhenyi.
        dockerImage = '--platform linux/arm64 camerasimulation/pbrt-v4-cpu-arm:latest';

    otherwise
        % Older Apple computers, on Linux boxes such as gray/black
        dockerImage = '--platform linux/amd64 digitalprodev/pbrt-v4-cpu:latest';
end

